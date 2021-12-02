PlaceableSilo = {
	PRICE_SELL_FACTOR = 0.7,
	REFILL_PRICE_FACTOR = 1.1,
	INFO_TRIGGER_NUM_DISPLAYED_FILLTYPES = 6,
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableSilo.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableSilo.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableSilo.setOwnerFarmId)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableSilo.canBeSold)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableSilo.updateInfo)
end

function PlaceableSilo.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "setAmount", PlaceableSilo.setAmount)
	SpecializationUtil.registerFunction(placeableType, "refillAmount", PlaceableSilo.refillAmount)
	SpecializationUtil.registerFunction(placeableType, "getFillLevels", PlaceableSilo.getFillLevels)
	SpecializationUtil.registerFunction(placeableType, "onPlayerActionTriggerCallback", PlaceableSilo.onPlayerActionTriggerCallback)
end

function PlaceableSilo.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableSilo)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableSilo)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableSilo)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableSilo)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableSilo)
	SpecializationUtil.registerEventListener(placeableType, "onSell", PlaceableSilo)
end

function PlaceableSilo.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Silo")
	schema:register(XMLValueType.STRING, basePath .. ".silo#sellWarningText", "Sell warning text")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".silo#playerActionTrigger", "Trigger for player interaction")
	schema:register(XMLValueType.BOOL, basePath .. ".silo.storages#perFarm", "Silo is per farm", false)
	schema:register(XMLValueType.BOOL, basePath .. ".silo.storages#foreignSilo", "Shows as foreign silo in the menu", false)
	UnloadingStation.registerXMLPaths(schema, basePath .. ".silo.unloadingStation")
	LoadingStation.registerXMLPaths(schema, basePath .. ".silo.loadingStation")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".silo.storages.storage(?)#node", "Storage node")
	Storage.registerXMLPaths(schema, basePath .. ".silo.storages.storage(?)")
	schema:setXMLSpecializationType()
end

function PlaceableSilo.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Silo")
	schema:register(XMLValueType.INT, basePath .. ".storage(?)#index", "Storage index")
	Storage.registerSavegameXMLPaths(schema, basePath .. ".storage(?)")
	schema:setXMLSpecializationType()
end

function PlaceableSilo.initSpecialization()
	g_storeManager:addSpecType("siloVolume", "shopListAttributeIconCapacity", PlaceableSilo.loadSpecValueVolume, PlaceableSilo.getSpecValueVolume, "placeable")
end

function PlaceableSilo:onLoad(savegame)
	local spec = self.spec_silo
	local xmlFile = self.xmlFile
	spec.playerActionTrigger = xmlFile:getValue("placeable.silo#playerActionTrigger", nil, self.components, self.i3dMappings)

	if spec.playerActionTrigger ~= nil then
		spec.activatable = PlaceableSiloActivatable.new(self)
	end

	spec.storagePerFarm = xmlFile:getValue("placeable.silo.storages#perFarm", false)
	spec.foreignSilo = xmlFile:getValue("placeable.silo.storages#foreignSilo", spec.storagePerFarm)
	spec.unloadingStation = UnloadingStation.new(self.isServer, self.isClient)

	spec.unloadingStation:load(self.components, xmlFile, "placeable.silo.unloadingStation", self.customEnvironment, self.i3dMappings, self.components[1].node)

	spec.unloadingStation.owningPlaceable = self
	spec.unloadingStation.hasStoragePerFarm = spec.storagePerFarm
	spec.loadingStation = LoadingStation.new(self.isServer, self.isClient)

	spec.loadingStation:load(self.components, xmlFile, "placeable.silo.loadingStation", self.customEnvironment, self.i3dMappings, self.components[1].node)

	spec.loadingStation.owningPlaceable = self
	spec.loadingStation.hasStoragePerFarm = spec.storagePerFarm
	spec.infoTriggerDataDirty = true
	spec.infoTriggerFillTypesAndLevels = {}
	local numStorageSets = spec.storagePerFarm and FarmManager.MAX_NUM_FARMS or 1

	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		numStorageSets = 1
	end

	spec.storages = {}
	local i = 0

	while true do
		local storageKey = string.format("placeable.silo.storages.storage(%d)", i)

		if not xmlFile:hasProperty(storageKey) then
			break
		end

		for j = 1, numStorageSets do
			local storage = Storage.new(self.isServer, self.isClient)

			if storage:load(self.components, xmlFile, storageKey, self.i3dMappings) then
				storage.ownerFarmId = j
				storage.foreignSilo = spec.foreignSilo

				table.insert(spec.storages, storage)
			end
		end

		i = i + 1
	end

	spec.sellWarningText = g_i18n:convertText(xmlFile:getValue("placeable.silo#sellWarningText", "$l10n_info_siloExtensionNotEmpty"))
end

function PlaceableSilo:onDelete()
	local spec = self.spec_silo
	local storageSystem = g_currentMission.storageSystem

	if spec.storages ~= nil then
		for _, storage in ipairs(spec.storages) do
			if spec.unloadingStation ~= nil then
				storageSystem:removeStorageFromUnloadingStations(storage, {
					spec.unloadingStation
				})
			end

			if spec.loadingStation ~= nil then
				storageSystem:removeStorageFromLoadingStations(storage, {
					spec.loadingStation
				})
			end

			storage:removeFillLevelChangedListeners(spec.storageFilLLevelChangedCallback)
			storageSystem:removeStorage(storage)
		end

		for _, storage in ipairs(spec.storages) do
			storage:delete()
		end
	end

	if spec.unloadingStation ~= nil then
		storageSystem:removeUnloadingStation(spec.unloadingStation, self)
		spec.unloadingStation:delete()
	end

	if spec.loadingStation ~= nil then
		storageSystem:removeLoadingStation(spec.loadingStation, self)
		spec.loadingStation:delete()
	end

	g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)

	if spec.playerActionTrigger ~= nil then
		removeTrigger(spec.playerActionTrigger)
	end
end

function PlaceableSilo:onFinalizePlacement()
	local spec = self.spec_silo
	local storageSystem = g_currentMission.storageSystem

	spec.unloadingStation:register(true)
	storageSystem:addUnloadingStation(spec.unloadingStation, self)
	spec.loadingStation:register(true)
	storageSystem:addLoadingStation(spec.loadingStation, self)

	function spec.storageFilLLevelChangedCallback()
		spec.infoTriggerDataDirty = true
	end

	for _, storage in ipairs(spec.storages) do
		if not spec.storagePerFarm then
			storage:setOwnerFarmId(self:getOwnerFarmId(), true)
		end

		storageSystem:addStorage(storage)
		storage:register(true)
		storageSystem:addStorageToUnloadingStation(storage, spec.unloadingStation)
		storageSystem:addStorageToLoadingStation(storage, spec.loadingStation)
		storage:addFillLevelChangedListeners(spec.storageFilLLevelChangedCallback)
	end

	local storagesInRange = storageSystem:getStorageExtensionsInRange(spec.unloadingStation, self:getOwnerFarmId())

	if storagesInRange ~= nil then
		for _, storage in ipairs(storagesInRange) do
			if spec.unloadingStation.targetStorages[storage] == nil then
				storageSystem:addStorageToUnloadingStation(storage, spec.unloadingStation)
			end
		end
	end

	storagesInRange = storageSystem:getStorageExtensionsInRange(spec.loadingStation, self:getOwnerFarmId())

	if storagesInRange ~= nil then
		for _, storage in ipairs(storagesInRange) do
			if spec.loadingStation.sourceStorages[storage] == nil then
				storageSystem:addStorageToLoadingStation(storage, spec.loadingStation)
			end
		end
	end

	if not spec.storagePerFarm then
		local num = 0

		for _, placeable in pairs(g_currentMission.placeables) do
			if placeable:getOwnerFarmId() == self:getOwnerFarmId() and placeable.spec_silo ~= nil then
				num = num + 1
			end
		end

		if num == 1 and g_currentMission.missionInfo.difficulty == 1 and g_currentMission.missionInfo.startSiloAmounts ~= nil and not g_currentMission.missionInfo:getIsLoadedFromSavegame() and not g_currentMission.missionInfo.hasLoadedFirstFilledSilo then
			g_currentMission.missionInfo.hasLoadedFirstFilledSilo = true

			for fillTypeName, amount in pairs(g_currentMission.missionInfo.startSiloAmounts) do
				local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

				self:setAmount(fillTypeIndex, amount)
			end
		end
	end

	if spec.playerActionTrigger ~= nil then
		addTrigger(spec.playerActionTrigger, "onPlayerActionTriggerCallback", self)
	end
end

function PlaceableSilo:onReadStream(streamId, connection)
	local spec = self.spec_silo
	local unloadingStationId = NetworkUtil.readNodeObjectId(streamId)

	spec.unloadingStation:readStream(streamId, connection)
	g_client:finishRegisterObject(spec.unloadingStation, unloadingStationId)

	local loadingStationId = NetworkUtil.readNodeObjectId(streamId)

	spec.loadingStation:readStream(streamId, connection)
	g_client:finishRegisterObject(spec.loadingStation, loadingStationId)

	for _, storage in ipairs(spec.storages) do
		local storageId = NetworkUtil.readNodeObjectId(streamId)

		storage:readStream(streamId, connection)
		g_client:finishRegisterObject(storage, storageId)
	end
end

function PlaceableSilo:onWriteStream(streamId, connection)
	local spec = self.spec_silo

	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.unloadingStation))
	spec.unloadingStation:writeStream(streamId, connection)
	g_server:registerObjectInStream(connection, spec.unloadingStation)
	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.loadingStation))
	spec.loadingStation:writeStream(streamId, connection)
	g_server:registerObjectInStream(connection, spec.loadingStation)

	for _, storage in ipairs(spec.storages) do
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(storage))
		storage:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, storage)
	end
end

function PlaceableSilo:collectPickObjects(superFunc, node)
	local spec = self.spec_silo
	local foundNode = false

	for _, unloadTrigger in ipairs(spec.unloadingStation.unloadTriggers) do
		if node == unloadTrigger.exactFillRootNode then
			foundNode = true

			break
		end
	end

	if not foundNode then
		for _, loadTrigger in ipairs(spec.loadingStation.loadTriggers) do
			if node == loadTrigger.triggerNode then
				foundNode = true

				break
			end
		end
	end

	if not foundNode then
		superFunc(self, node)
	end
end

function PlaceableSilo:canBeSold(superFunc)
	local spec = self.spec_silo

	if spec.storagePerFarm then
		return false, nil
	end

	local warning = spec.sellWarningText .. "\n"
	local totalFillLevel = 0
	spec.totalFillTypeSellPrice = 0

	for fillTypeIndex, fillLevel in pairs(spec.storages[1].fillLevels) do
		totalFillLevel = totalFillLevel + fillLevel

		if fillLevel > 0 then
			local lowestSellPrice = math.huge

			for _, unloadingStation in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
				if unloadingStation.owningPlaceable ~= nil and unloadingStation.isSellingPoint and unloadingStation.acceptedFillTypes[fillTypeIndex] then
					local price = unloadingStation:getEffectiveFillTypePrice(fillTypeIndex)

					if price > 0 then
						lowestSellPrice = math.min(lowestSellPrice, price)
					end
				end
			end

			if lowestSellPrice == math.huge then
				lowestSellPrice = 0.5
			end

			local price = fillLevel * lowestSellPrice * PlaceableSilo.PRICE_SELL_FACTOR
			local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			warning = string.format("%s%s (%s) - %s: %s\n", warning, fillType.title, g_i18n:formatVolume(fillLevel), g_i18n:getText("ui_sellValue"), g_i18n:formatMoney(price, 0, true, true))
			spec.totalFillTypeSellPrice = spec.totalFillTypeSellPrice + price
		end
	end

	if totalFillLevel > 0 then
		return true, warning
	end

	return true, nil
end

function PlaceableSilo:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_silo

	xmlFile:iterate(key .. ".storage", function (_, storageKey)
		local index = xmlFile:getValue(storageKey .. "#index")

		if index ~= nil and spec.storages[index] ~= nil and not spec.storages[index]:loadFromXMLFile(xmlFile, storageKey) then
			return false
		end
	end)
end

function PlaceableSilo:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_silo

	for k, storage in ipairs(spec.storages) do
		local storageKey = string.format("%s.storage(%d)", key, k - 1)

		xmlFile:setValue(storageKey .. "#index", k)
		storage:saveToXMLFile(xmlFile, storageKey, usedModNames)
	end
end

function PlaceableSilo:setOwnerFarmId(superFunc, farmId, noEventSend)
	local spec = self.spec_silo

	superFunc(self, farmId, noEventSend)

	if self.isServer and not spec.storagePerFarm and spec.storages ~= nil then
		for _, storage in ipairs(spec.storages) do
			storage:setOwnerFarmId(farmId, true)
		end
	end
end

function PlaceableSilo:setAmount(fillType, amount)
	local spec = self.spec_silo

	for _, storage in ipairs(spec.storages) do
		local capacity = storage:getFreeCapacity(fillType)

		if capacity > 0 then
			local moved = math.min(amount, capacity)

			storage:setFillLevel(moved, fillType)

			amount = amount - moved
		end

		if amount <= 0.001 then
			break
		end
	end
end

function PlaceableSilo:refillAmount(fillTypeIndex, amount, price)
	if fillTypeIndex == nil or amount == nil or price == nil then
		return
	end

	if not self.isServer then
		g_client:getServerConnection():sendEvent(PlaceableSiloRefillEvent.new(self, fillTypeIndex, amount, price))

		return
	end

	local spec = self.spec_silo

	for _, storage in ipairs(spec.storages) do
		local freeCapacity = storage:getFreeCapacity(fillTypeIndex)

		if freeCapacity > 0 then
			local moved = math.min(amount, freeCapacity)
			local fillLevel = storage:getFillLevel(fillTypeIndex)

			storage:setFillLevel(fillLevel + moved, fillTypeIndex)

			amount = amount - moved
		end

		if amount <= 0.001 then
			break
		end
	end

	if self.isServer then
		g_currentMission:addMoney(-price, self:getOwnerFarmId(), MoneyType.BOUGHT_MATERIALS, true)
	end

	g_currentMission:showMoneyChange(MoneyType.BOUGHT_MATERIALS)
end

function PlaceableSilo:getFillLevels()
	local spec = self.spec_silo
	local validFillLevels = {}

	for _, storage in ipairs(spec.storages) do
		for fillTypeIndex, fillLevel in pairs(storage:getFillLevels()) do
			if self.fillTypes == nil or self.fillTypes[fillTypeIndex] then
				validFillLevels[fillTypeIndex] = fillLevel
			end
		end
	end

	return validFillLevels
end

function PlaceableSilo:onSell()
	local spec = self.spec_silo

	if self.isServer and spec.totalFillTypeSellPrice > 0 then
		g_currentMission:addMoney(spec.totalFillTypeSellPrice, self:getOwnerFarmId(), MoneyType.HARVEST_INCOME, true, true)
	end
end

function PlaceableSilo:onPlayerActionTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local spec = self.spec_silo

	if self:getOwnerFarmId() == g_currentMission:getFarmId() and g_currentMission.player ~= nil and otherId == g_currentMission.player.rootNode then
		if onEnter then
			g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
		else
			g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
		end
	end
end

function PlaceableSilo:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)

	local spec = self.spec_silo

	if spec.infoTriggerDataDirty then
		local fillLevels = {}

		for _, storage in pairs(self.spec_silo.storages) do
			for fillType, fillLevel in pairs(storage:getFillLevels()) do
				fillLevels[fillType] = (fillLevels[fillType] or 0) + fillLevel
			end
		end

		table.clear(spec.infoTriggerFillTypesAndLevels)

		for fillType, fillLevel in pairs(fillLevels) do
			if fillLevel > 0.1 then
				table.insert(spec.infoTriggerFillTypesAndLevels, {
					fillType = fillType,
					fillLevel = fillLevel
				})
			end
		end

		table.sort(spec.infoTriggerFillTypesAndLevels, function (a, b)
			return b.fillLevel < a.fillLevel
		end)

		spec.infoTriggerDataDirty = false
	end

	local numEntries = math.min(#spec.infoTriggerFillTypesAndLevels, PlaceableSilo.INFO_TRIGGER_NUM_DISPLAYED_FILLTYPES)

	if numEntries > 0 then
		for i = 1, numEntries do
			local fillTypeAndLevel = spec.infoTriggerFillTypesAndLevels[i]

			table.insert(infoTable, {
				title = g_fillTypeManager:getFillTypeByIndex(fillTypeAndLevel.fillType).title,
				text = g_i18n:formatVolume(fillTypeAndLevel.fillLevel, 0)
			})
		end
	else
		table.insert(infoTable, {
			text = "",
			title = g_i18n:getText("infohud_siloEmpty")
		})
	end
end

function PlaceableSilo.loadSpecValueVolume(xmlFile, customEnvironment)
	return xmlFile:getValue("placeable.silo.storages.storage(0)#capacity")
end

function PlaceableSilo.getSpecValueVolume(storeItem, realItem)
	if storeItem.specs.siloVolume == nil then
		return nil
	end

	return g_i18n:formatVolume(storeItem.specs.siloVolume)
end

PlaceableSiloActivatable = {}
local PlaceableSiloActivatable_mt = Class(PlaceableSiloActivatable)

function PlaceableSiloActivatable.new(placeable)
	local self = setmetatable({}, PlaceableSiloActivatable_mt)
	self.placeable = placeable
	self.activateText = g_i18n:getText("action_refillSilo")

	return self
end

function PlaceableSiloActivatable:run()
	local data = {}

	for _, storage in pairs(self.placeable.spec_silo.storages) do
		for fillType, fillLevel in pairs(storage:getFillLevels()) do
			if data[fillType] == nil then
				data[fillType] = 0
			end

			data[fillType] = data[fillType] + storage:getFreeCapacity(fillType)
		end
	end

	g_gui:showRefillDialog({
		data = data,
		priceFactor = PlaceableSilo.REFILL_PRICE_FACTOR,
		callback = self.placeable.refillAmount,
		target = self.placeable
	})
end

PlaceableSiloRefillEvent = {}
local PlaceableSiloRefillEvent_mt = Class(PlaceableSiloRefillEvent, Event)

InitStaticEventClass(PlaceableSiloRefillEvent, "PlaceableSiloRefillEvent", EventIds.EVENT_SILO_REFILL)

function PlaceableSiloRefillEvent.emptyNew()
	local self = Event.new(PlaceableSiloRefillEvent_mt)

	return self
end

function PlaceableSiloRefillEvent.new(placeable, fillTypeIndex, amount, price)
	local self = PlaceableSiloRefillEvent.emptyNew()
	self.placeable = placeable
	self.fillTypeIndex = fillTypeIndex
	self.amount = amount
	self.price = price

	return self
end

function PlaceableSiloRefillEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
	streamWriteInt32(streamId, self.amount)
	streamWriteInt32(streamId, self.price)
	streamWriteUIntN(streamId, self.fillTypeIndex, FillTypeManager.SEND_NUM_BITS)
end

function PlaceableSiloRefillEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	self.amount = streamReadInt32(streamId)
	self.price = streamReadInt32(streamId)
	self.fillTypeIndex = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

	self:run(connection)
end

function PlaceableSiloRefillEvent:run(connection)
	if not connection:getIsServer() then
		self.placeable:refillAmount(self.fillTypeIndex, self.amount, self.price)
	end
end
