PlaceableSiloExtension = {
	PRICE_SELL_FACTOR = 0.6,
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableSiloExtension.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableSiloExtension.setOwnerFarmId)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getCanBePlacedAt", PlaceableSiloExtension.getCanBePlacedAt)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableSiloExtension.canBeSold)
end

function PlaceableSiloExtension.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableSiloExtension)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableSiloExtension)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableSiloExtension)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableSiloExtension)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableSiloExtension)
	SpecializationUtil.registerEventListener(placeableType, "onSell", PlaceableSiloExtension)
end

function PlaceableSiloExtension.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("SiloExtension")
	schema:register(XMLValueType.BOOL, basePath .. ".siloExtension.storage#foreignSilo", "Shows as foreign silo in the menu", false)
	schema:register(XMLValueType.L10N_STRING, basePath .. ".siloExtension#nearSiloWarning", "Warning that is shown if extension is not placed near another silo")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".siloExtension.storage#node", "Storage node")
	Storage.registerXMLPaths(schema, basePath .. ".siloExtension.storage")
	schema:setXMLSpecializationType()
end

function PlaceableSiloExtension.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("SiloExtension")
	Storage.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end

function PlaceableSiloExtension.initSpecialization()
	g_storeManager:addSpecType("siloExtensionVolume", "shopListAttributeIconCapacity", PlaceableSiloExtension.loadSpecValueVolume, PlaceableSiloExtension.getSpecValueVolume, "placeable")
end

function PlaceableSiloExtension:onLoad(savegame)
	local spec = self.spec_siloExtension
	local xmlFile = self.xmlFile
	local storageKey = "placeable.siloExtension.storage"
	spec.foreignSilo = xmlFile:getValue(storageKey .. "#foreignSilo", false)

	if xmlFile:hasProperty(storageKey) then
		spec.storage = Storage.new(self.isServer, self.isClient)

		spec.storage:load(self.components, xmlFile, storageKey, self.i3dMappings)

		spec.storage.foreignSilo = spec.foreignSilo
	else
		Logging.xmlWarning(xmlFile, "Missing 'storage' for siloExtension!")
	end

	spec.nearSiloWarning = xmlFile:getValue("placeable.siloExtension#nearSiloWarning", "warning_siloExtensionNotNearSilo", self.customEnvironment)
end

function PlaceableSiloExtension:onDelete()
	local spec = self.spec_siloExtension

	if spec.storage ~= nil then
		local storageSystem = g_currentMission.storageSystem

		if storageSystem:hasStorage(spec.storage) then
			storageSystem:removeStorageFromUnloadingStations(spec.storage, spec.storage.unloadingStations)
			storageSystem:removeStorageFromLoadingStations(spec.storage, spec.storage.loadingStations)
			storageSystem:removeStorage(spec.storage)
		end

		spec.storage:delete()
	end
end

function PlaceableSiloExtension:onFinalizePlacement()
	local spec = self.spec_siloExtension

	if spec.storage ~= nil then
		local storageSystem = g_currentMission.storageSystem
		local ownerFarmId = self:getOwnerFarmId()
		local lastFoundUnloadingStations = storageSystem:getExtendableUnloadingStationsInRange(spec.storage, ownerFarmId)
		local lastFoundLoadingStations = storageSystem:getExtendableLoadingStationsInRange(spec.storage, ownerFarmId)

		spec.storage:setOwnerFarmId(self:getOwnerFarmId(), true)
		storageSystem:addStorage(spec.storage)
		spec.storage:register(true)
		storageSystem:addStorageToUnloadingStations(spec.storage, lastFoundUnloadingStations)
		storageSystem:addStorageToLoadingStations(spec.storage, lastFoundLoadingStations)
	end
end

function PlaceableSiloExtension:onReadStream(streamId, connection)
	local spec = self.spec_siloExtension

	if spec.storage ~= nil then
		local storageId = NetworkUtil.readNodeObjectId(streamId)

		spec.storage:readStream(streamId, connection)
		g_client:finishRegisterObject(spec.storage, storageId)
	end
end

function PlaceableSiloExtension:onWriteStream(streamId, connection)
	local spec = self.spec_siloExtension

	if spec.storage ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.storage))
		spec.storage:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, spec.storage)
	end
end

function PlaceableSiloExtension:getCanBePlacedAt(superFunc, x, y, z, farmId)
	local canBePlaced, errorMessage = superFunc(self, x, y, z, farmId)

	if not canBePlaced then
		return false, errorMessage
	end

	local spec = self.spec_siloExtension

	if spec.storage == nil then
		return false
	end

	spec.lastFoundUnloadingStations = nil
	spec.lastFoundLoadingStations = nil
	local storageSystem = g_currentMission.storageSystem
	spec.lastFoundUnloadingStations = storageSystem:getExtendableUnloadingStationsInRange(spec.storage, farmId, x, y, z)
	spec.lastFoundLoadingStations = storageSystem:getExtendableLoadingStationsInRange(spec.storage, farmId, x, y, z)

	if table.getn(spec.lastFoundUnloadingStations) == 0 and table.getn(spec.lastFoundLoadingStations) == 0 then
		return false, spec.nearSiloWarning
	end

	return true
end

function PlaceableSiloExtension:canBeSold(superFunc)
	local spec = self.spec_siloExtension

	if spec.storage == nil then
		return true, nil
	end

	local warning = g_i18n:getText("info_siloExtensionNotEmpty")
	local totalFillLevel = 0
	spec.totalFillTypeSellPrice = 0

	for fillTypeIndex, fillLevel in pairs(spec.storage.fillLevels) do
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

			local price = fillLevel * lowestSellPrice * PlaceableSiloExtension.PRICE_SELL_FACTOR
			local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			warning = string.format("%s%s (%d %s) - %s: %s\n", warning, fillType.nameI18N, g_i18n:getFluid(fillLevel), g_i18n:getText("unit_literShort"), g_i18n:getText("ui_sellValue"), g_i18n:formatMoney(price, 0, true, true))
			spec.totalFillTypeSellPrice = spec.totalFillTypeSellPrice + price
		end
	end

	if totalFillLevel > 0 then
		return true, warning
	end

	return true, nil
end

function PlaceableSiloExtension:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_siloExtension

	if spec.storage ~= nil then
		spec.storage:loadFromXMLFile(xmlFile, key)
	end
end

function PlaceableSiloExtension:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_siloExtension

	if spec.storage ~= nil then
		spec.storage:saveToXMLFile(xmlFile, key, usedModNames)
	end
end

function PlaceableSiloExtension:setOwnerFarmId(superFunc, farmId, noEventSend)
	local spec = self.spec_siloExtension

	superFunc(self, farmId, noEventSend)

	if self.isServer and spec.storage ~= nil then
		spec.storage:setOwnerFarmId(farmId, true)
	end
end

function PlaceableSiloExtension:onSell()
	local spec = self.spec_siloExtension

	if self.isServer and spec.totalFillTypeSellPrice > 0 then
		g_currentMission:addMoney(spec.totalFillTypeSellPrice, self:getOwnerFarmId(), MoneyType.HARVEST_INCOME, true, true)
	end
end

function PlaceableSiloExtension.loadSpecValueVolume(xmlFile, customEnvironment)
	return xmlFile:getValue("placeable.siloExtension.storage#capacity")
end

function PlaceableSiloExtension.getSpecValueVolume(storeItem, realItem)
	if storeItem.specs.siloExtensionVolume == nil then
		return nil
	end

	return g_i18n:formatVolume(storeItem.specs.siloExtensionVolume)
end
