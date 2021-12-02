PlaceableHusbandry = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerEvents = function (placeableType)
		SpecializationUtil.registerEvent(placeableType, "onHusbandryFillLevelChanged")
	end
}

function PlaceableHusbandry.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onAddedStorageToLoadingStation", PlaceableHusbandry.onAddedStorageToLoadingStation)
	SpecializationUtil.registerFunction(placeableType, "onRemovedStorageFromLoadingStation", PlaceableHusbandry.onRemovedStorageFromLoadingStation)
	SpecializationUtil.registerFunction(placeableType, "onAddedStorageToUnloadingStation", PlaceableHusbandry.onAddedStorageToUnloadingStation)
	SpecializationUtil.registerFunction(placeableType, "onRemovedStorageFromUnloadingStation", PlaceableHusbandry.onRemovedStorageFromUnloadingStation)
	SpecializationUtil.registerFunction(placeableType, "updateFeeding", PlaceableHusbandry.updateFeeding)
	SpecializationUtil.registerFunction(placeableType, "updateProduction", PlaceableHusbandry.updateProduction)
	SpecializationUtil.registerFunction(placeableType, "updateOutput", PlaceableHusbandry.updateOutput)
	SpecializationUtil.registerFunction(placeableType, "getGlobalProductionFactor", PlaceableHusbandry.getGlobalProductionFactor)
	SpecializationUtil.registerFunction(placeableType, "getConditionInfos", PlaceableHusbandry.getConditionInfos)
	SpecializationUtil.registerFunction(placeableType, "getFoodInfos", PlaceableHusbandry.getFoodInfos)
	SpecializationUtil.registerFunction(placeableType, "getAnimalInfos", PlaceableHusbandry.getAnimalInfos)
	SpecializationUtil.registerFunction(placeableType, "getHusbandryCapacity", PlaceableHusbandry.getHusbandryCapacity)
	SpecializationUtil.registerFunction(placeableType, "getHusbandryFreeCapacity", PlaceableHusbandry.getHusbandryFreeCapacity)
	SpecializationUtil.registerFunction(placeableType, "addHusbandryFillLevelFromTool", PlaceableHusbandry.addHusbandryFillLevelFromTool)
	SpecializationUtil.registerFunction(placeableType, "removeHusbandryFillLevel", PlaceableHusbandry.removeHusbandryFillLevel)
	SpecializationUtil.registerFunction(placeableType, "getHusbandryFillLevel", PlaceableHusbandry.getHusbandryFillLevel)
	SpecializationUtil.registerFunction(placeableType, "getHusbandryIsFillTypeSupported", PlaceableHusbandry.getHusbandryIsFillTypeSupported)
end

function PlaceableHusbandry.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableHusbandry.setOwnerFarmId)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableHusbandry.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableHusbandry.getCanBePlacedAt)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBuy", PlaceableHusbandry.canBuy)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedHourChanged", PlaceableHusbandry.getNeedHourChanged)
end

function PlaceableHusbandry.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableHusbandry)
	SpecializationUtil.registerEventListener(placeableType, "onHourChanged", PlaceableHusbandry)
end

function PlaceableHusbandry.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	schema:register(XMLValueType.STRING, basePath .. ".husbandry#saveId", "Save id")
	schema:register(XMLValueType.BOOL, basePath .. ".husbandry#hasStatistics", "Has statistics", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".husbandry.production#threshold", "Threshold for production increase", 0.6)
	schema:register(XMLValueType.FLOAT, basePath .. ".husbandry.production#increasePerHour", "Production increase if production factor bigger then threshold", 0.1)
	schema:register(XMLValueType.FLOAT, basePath .. ".husbandry.production#decreasePerHour", "Production increase if production factor less then threshold", 0.2)
	UnloadingStation.registerXMLPaths(schema, basePath .. ".husbandry.unloadingStation")
	Storage.registerXMLPaths(schema, basePath .. ".husbandry.storage")
	LoadingStation.registerXMLPaths(schema, basePath .. ".husbandry.loadingStation")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandry.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	schema:register(XMLValueType.STRING, basePath .. ".module(?)#name", "Name of module")
	schema:register(XMLValueType.FLOAT, basePath .. "#globalProductionFactor", "Global production factor")
	Storage.registerSavegameXMLPaths(schema, basePath .. ".storage")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandry:onLoad(savegame)
	local spec = self.spec_husbandry
	local xmlFile = self.xmlFile
	spec.fillLevelChangedListener = {}
	spec.targetStorages = {}
	spec.hideFromPricesMenu = true
	spec.globalProductionFactor = 0
	spec.husbandryDirtyFlag = self:getNextDirtyFlag()

	if xmlFile:hasProperty("placeable.husbandry.unloadingStation") then
		spec.unloadingStation = UnloadingStation.new(self.isServer, self.isClient)

		if spec.unloadingStation:load(self.components, xmlFile, "placeable.husbandry.unloadingStation", self.customEnvironment, self.i3dMappings, self.components[1].node) then
			spec.unloadingStation.owningPlaceable = self
			spec.unloadingStation.hasStoragePerFarm = false
		else
			spec.unloadingStation:delete()
			Logging.xmlError(xmlFile, "Failed to load unloading station")
			self:setLoadingState(Placeable.LOADING_STATE_ERROR)

			return
		end
	end

	if xmlFile:hasProperty("placeable.husbandry.storage") then
		spec.storage = Storage.new(self.isServer, self.isClient)

		if not spec.storage:load(self.components, xmlFile, "placeable.husbandry.storage", self.i3dMappings) then
			spec.storage:delete()
			Logging.xmlError(xmlFile, "Failed to load storage")
			self:setLoadingState(Placeable.LOADING_STATE_ERROR)

			return
		end
	end

	if xmlFile:hasProperty("placeable.husbandry.loadingStation") then
		spec.loadingStation = LoadingStation.new(self.isServer, self.isClient)

		if spec.loadingStation:load(self.components, xmlFile, "placeable.husbandry.loadingStation", self.customEnvironment, self.i3dMappings, self.components[1].node) then
			spec.loadingStation.owningPlaceable = self
			spec.loadingStation.hasStoragePerFarm = false
		else
			spec.loadingStation:delete()
			Logging.xmlError(xmlFile, "Failed to load loading station")
			self:setLoadingState(Placeable.LOADING_STATE_ERROR)

			return
		end
	end

	function spec.fillLevelChangedCallback(fillType, delta)
		SpecializationUtil.raiseEvent(self, "onHusbandryFillLevelChanged", fillType, delta)
	end

	spec.productionThreshold = MathUtil.clamp(math.abs(xmlFile:getValue("placeable.husbandry.production#threshold", 0.6)), 0.01, 0.99)
	spec.productionChangePerHourIncrease = math.abs(xmlFile:getValue("placeable.husbandry.production#increasePerHour", 0.1))
	spec.productionChangePerHourDecrease = math.abs(xmlFile:getValue("placeable.husbandry.production#decreasePerHour", 0.2))
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function PlaceableHusbandry:onDelete()
	local spec = self.spec_husbandry
	local storageSystem = g_currentMission.storageSystem

	if spec.unloadingStation ~= nil then
		storageSystem:removeStorageFromUnloadingStations(spec.storage, {
			spec.unloadingStation
		})
		storageSystem:removeUnloadingStation(spec.unloadingStation, self)
		spec.unloadingStation:delete()

		spec.unloadingStation = nil
	end

	if spec.loadingStation ~= nil then
		if spec.loadingStation:getIsFillTypeSupported(FillType.LIQUIDMANURE) then
			g_currentMission:removeLiquidManureLoadingStation(spec.loadingStation)
		end

		storageSystem:removeStorageFromLoadingStations(spec.storage, {
			spec.loadingStation
		})
		storageSystem:removeLoadingStation(spec.loadingStation, self)
		spec.loadingStation:delete()

		spec.loadingStation = nil
	end

	if spec.storage ~= nil then
		storageSystem:removeStorage(spec.storage)
		spec.storage:delete()

		spec.storage = nil
	end

	g_messageCenter:unsubscribe(MessageType.STORAGE_ADDED_TO_LOADING_STATION, self)
	g_messageCenter:unsubscribe(MessageType.STORAGE_REMVOED_FROM_LOADING_STATION, self)
	g_messageCenter:unsubscribe(MessageType.STORAGE_ADDED_TO_UNLOADING_STATION, self)
	g_messageCenter:unsubscribe(MessageType.STORAGE_REMVOED_FROM_UNLOADING_STATION, self)
	g_currentMission.husbandrySystem:removePlaceable(self)
end

function PlaceableHusbandry:onFinalizePlacement()
	local spec = self.spec_husbandry

	g_messageCenter:subscribe(MessageType.STORAGE_ADDED_TO_LOADING_STATION, self.onAddedStorageToLoadingStation, self)
	g_messageCenter:subscribe(MessageType.STORAGE_REMOVED_FROM_LOADING_STATION, self.onRemovedStorageFromLoadingStation, self)
	g_messageCenter:subscribe(MessageType.STORAGE_ADDED_TO_UNLOADING_STATION, self.onAddedStorageToUnloadingStation, self)
	g_messageCenter:subscribe(MessageType.STORAGE_REMOVED_FROM_UNLOADING_STATION, self.onRemovedStorageFromUnloadingStation, self)

	local storage = spec.storage
	local unloadingStation = spec.unloadingStation
	local storageSystem = g_currentMission.storageSystem
	local loadingStation = spec.loadingStation
	local farmId = self:getOwnerFarmId()

	if loadingStation ~= nil then
		loadingStation:setOwnerFarmId(farmId, true)
		loadingStation:register(true)
		storageSystem:addLoadingStation(loadingStation, self)

		if loadingStation:getIsFillTypeSupported(FillType.LIQUIDMANURE) then
			g_currentMission:addLiquidManureLoadingStation(loadingStation)
		end
	end

	if unloadingStation ~= nil then
		unloadingStation:setOwnerFarmId(farmId, true)
		unloadingStation:register(true)
		storageSystem:addUnloadingStation(unloadingStation, self)
	end

	if storage ~= nil then
		storage:setOwnerFarmId(farmId, true)
		storage:register(true)
		storageSystem:addStorage(storage)

		if unloadingStation ~= nil then
			storageSystem:addStorageToUnloadingStation(storage, unloadingStation)
		end

		if loadingStation ~= nil then
			storageSystem:addStorageToLoadingStation(storage, loadingStation)
		end
	end

	if unloadingStation ~= nil then
		local storagesInRange = storageSystem:getStorageExtensionsInRange(unloadingStation, farmId)

		for _, storageInRange in ipairs(storagesInRange) do
			if unloadingStation.targetStorages[storageInRange] == nil then
				storageSystem:addStorageToUnloadingStation(storageInRange, unloadingStation)
			end

			if loadingStation ~= nil and loadingStation.sourceStorages[storageInRange] == nil then
				storageSystem:addStorageToLoadingStation(storageInRange, loadingStation)
			end
		end
	end

	g_currentMission.husbandrySystem:addPlaceable(self)
end

function PlaceableHusbandry:onReadStream(streamId, connection)
	local spec = self.spec_husbandry

	if spec.unloadingStation ~= nil then
		local unloadingStationId = NetworkUtil.readNodeObjectId(streamId)

		spec.unloadingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(spec.unloadingStation, unloadingStationId)
	end

	if spec.loadingStation ~= nil then
		local loadingStationId = NetworkUtil.readNodeObjectId(streamId)

		spec.loadingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(spec.loadingStation, loadingStationId)
	end

	if spec.storage ~= nil then
		local storageId = NetworkUtil.readNodeObjectId(streamId)

		spec.storage:readStream(streamId, connection)
		g_client:finishRegisterObject(spec.storage, storageId)
	end

	spec.globalProductionFactor = streamReadUInt8(streamId) / 255
end

function PlaceableHusbandry:onWriteStream(streamId, connection)
	local spec = self.spec_husbandry

	if spec.unloadingStation ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.unloadingStation))
		spec.unloadingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, spec.unloadingStation)
	end

	if spec.loadingStation ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.loadingStation))
		spec.loadingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, spec.loadingStation)
	end

	if spec.storage ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.storage))
		spec.storage:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, spec.storage)
	end

	streamWriteUInt8(streamId, MathUtil.round(spec.globalProductionFactor * 255))
end

function PlaceableHusbandry:onReadUpdateStream(streamId, connection)
	local spec = self.spec_husbandry
	spec.globalProductionFactor = streamReadUInt8(streamId) / 100
end

function PlaceableHusbandry:onWriteUpdateStream(streamId, connection)
	local spec = self.spec_husbandry

	streamWriteUInt8(streamId, MathUtil.round(spec.globalProductionFactor * 100))
end

function PlaceableHusbandry:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_husbandry

	if spec.storage ~= nil then
		spec.storage:saveToXMLFile(xmlFile, key .. ".storage", usedModNames)
	end

	xmlFile:setValue(key .. "#globalProductionFactor", spec.globalProductionFactor)
end

function PlaceableHusbandry:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_husbandry

	if spec.storage ~= nil then
		spec.storage:loadFromXMLFile(xmlFile, key .. ".storage")
	end

	spec.globalProductionFactor = xmlFile:getValue(key .. "#globalProductionFactor", spec.globalProductionFactor)
end

function PlaceableHusbandry:setOwnerFarmId(superFunc, farmId, noEventSend)
	local spec = self.spec_husbandry

	superFunc(self, farmId, noEventSend)

	if spec.storage ~= nil then
		spec.storage:setOwnerFarmId(farmId, true)
	end

	if spec.loadingStation ~= nil then
		spec.loadingStation:setOwnerFarmId(farmId, true)
	end

	if spec.unloadingStation ~= nil then
		spec.unloadingStation:setOwnerFarmId(farmId, true)
	end
end

function PlaceableHusbandry:collectPickObjects(superFunc, node, target)
	local spec = self.spec_husbandry

	if spec.unloadingStation ~= nil then
		for _, unloadTrigger in ipairs(spec.unloadingStation.unloadTriggers) do
			if node == unloadTrigger.exactFillRootNode then
				return
			end
		end
	end

	if spec.loadingStation ~= nil then
		for _, loadTrigger in ipairs(spec.loadingStation.loadTriggers) do
			if node == loadTrigger.triggerNode then
				return
			end
		end
	end

	superFunc(self, node, target)
end

function PlaceableHusbandry:getCanBePlacedAt(superFunc, x, y, z, farmId)
	if g_currentMission.husbandrySystem:getLimitReached() then
		return false, g_i18n:getText("warning_tooManyHusbandries")
	end

	return superFunc(self, x, y, z)
end

function PlaceableHusbandry:canBuy(superFunc)
	if g_currentMission.husbandrySystem:getLimitReached() then
		return false, g_i18n:getText("warning_tooManyHusbandries")
	end

	return superFunc(self)
end

function PlaceableHusbandry:onHourChanged(currentHour)
	if self.isServer then
		local spec = self.spec_husbandry
		local foodFactor = self:updateFeeding()
		local productionFactor = self:updateProduction(foodFactor)
		local factor, changePerHour = nil

		if spec.productionThreshold < productionFactor then
			factor = (productionFactor - spec.productionThreshold) / (1 - spec.productionThreshold)
			changePerHour = spec.productionChangePerHourIncrease
		else
			factor = productionFactor / spec.productionThreshold - 1
			changePerHour = spec.productionChangePerHourDecrease
		end

		local delta = changePerHour * factor
		spec.globalProductionFactor = MathUtil.clamp(spec.globalProductionFactor + delta, 0, 1)

		self:updateOutput(foodFactor, productionFactor, spec.globalProductionFactor)
		self:raiseDirtyFlags(spec.dirtyFlag)
	end
end

function PlaceableHusbandry:getNeedHourChanged(superFunc)
	return true
end

function PlaceableHusbandry:updateFeeding()
	return 1
end

function PlaceableHusbandry:updateProduction(foodFactor)
	return foodFactor
end

function PlaceableHusbandry:updateOutput(foodFactor, productionFactor, globalProductionFactor)
end

function PlaceableHusbandry:getGlobalProductionFactor()
	local spec = self.spec_husbandry

	return spec.globalProductionFactor
end

function PlaceableHusbandry:getConditionInfos()
	return {}
end

function PlaceableHusbandry:getFoodInfos()
	return {}
end

function PlaceableHusbandry:getAnimalInfos()
	return {}
end

function PlaceableHusbandry:getHusbandryCapacity(fillTypeIndex, farmId)
	local spec = self.spec_husbandry

	if spec.unloadingStation == nil then
		return 0
	end

	return spec.unloadingStation:getCapacity(fillTypeIndex, farmId or self:getOwnerFarmId())
end

function PlaceableHusbandry:getHusbandryFreeCapacity(fillTypeIndex, farmId)
	local spec = self.spec_husbandry

	if spec.unloadingStation == nil then
		return 0
	end

	return spec.unloadingStation:getFreeCapacity(fillTypeIndex, farmId or self:getOwnerFarmId())
end

function PlaceableHusbandry:addHusbandryFillLevelFromTool(farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
	local spec = self.spec_husbandry

	if spec.unloadingStation == nil then
		return 0
	end

	return spec.unloadingStation:addFillLevelFromTool(farmId or self:getOwnerFarmId(), deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
end

function PlaceableHusbandry:removeHusbandryFillLevel(farmId, deltaFillLevel, fillTypeIndex)
	local spec = self.spec_husbandry

	if spec.loadingStation == nil then
		return 0
	end

	return spec.loadingStation:removeFillLevel(fillTypeIndex, deltaFillLevel, farmId or self:getOwnerFarmId())
end

function PlaceableHusbandry:getHusbandryFillLevel(fillTypeIndex, farmId)
	local spec = self.spec_husbandry

	if spec.unloadingStation == nil then
		return 0
	end

	return spec.unloadingStation:getFillLevel(fillTypeIndex, farmId or self:getOwnerFarmId())
end

function PlaceableHusbandry:getHusbandryIsFillTypeSupported(fillTypeIndex)
	local spec = self.spec_husbandry

	if spec.unloadingStation == nil then
		return false
	end

	return spec.unloadingStation:getIsFillTypeSupported(fillTypeIndex)
end

function PlaceableHusbandry:onAddedStorageToLoadingStation(storage, loadingStation)
	local spec = self.spec_husbandry

	if spec.loadingStation ~= nil and spec.loadingStation == loadingStation then
		storage:addFillLevelChangedListeners(spec.fillLevelChangedCallback)
	end
end

function PlaceableHusbandry:onRemovedStorageFromLoadingStation(storage, loadingStation)
	local spec = self.spec_husbandry

	if spec.loadingStation ~= nil and spec.loadingStation == loadingStation then
		storage:removeFillLevelChangedListeners(spec.fillLevelChangedCallback)
	end
end

function PlaceableHusbandry:onAddedStorageToUnloadingStation(storage, unloadingStation)
	local spec = self.spec_husbandry

	if spec.unloadingStation ~= nil and spec.unloadingStation == unloadingStation then
		storage:addFillLevelChangedListeners(spec.fillLevelChangedCallback)
	end
end

function PlaceableHusbandry:onRemovedStorageFromUnloadingStation(storage, unloadingStation)
	local spec = self.spec_husbandry

	if spec.unloadingStation ~= nil and spec.unloadingStation == unloadingStation then
		storage:removeFillLevelChangedListeners(spec.fillLevelChangedCallback)
	end
end
