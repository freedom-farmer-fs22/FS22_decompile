LoadingStation = {}
local LoadingStation_mt = Class(LoadingStation, Object)

InitStaticObjectClass(LoadingStation, "LoadingStation", ObjectIds.OBJECT_LOADING_STATION)

function LoadingStation.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or LoadingStation_mt)
	self.sourceStorages = {}
	self.loadTriggers = {}

	return self
end

function LoadingStation:load(components, xmlFile, key, customEnv, i3dMappings, rootNode)
	self.rootNode = rootNode or xmlFile:getValue(key .. "#node", rootNode, components, i3dMappings)

	if self.rootNode == nil then
		Logging.xmlError(xmlFile, "Missing node defined in '%s'", key)

		return false
	end

	self.supportedFillTypes = {}
	self.aiSupportedFillTypes = {}
	self.rootNodeName = getName(self.rootNode)
	local stationName = xmlFile:getValue(key .. "#stationName", nil)
	self.stationName = stationName and g_i18n:convertText(stationName)
	self.storageRadius = xmlFile:getValue(key .. "#storageRadius", 50)
	self.supportsExtension = xmlFile:getValue(key .. "#supportsExtension", false)
	self.owningPlaceable = nil
	self.hasStoragePerFarm = false

	xmlFile:iterate(key .. ".loadTrigger", function (_, loadTriggerKey)
		local loadTrigger = LoadTrigger.new(self.isServer, self.isClient)

		if loadTrigger:load(components, xmlFile, loadTriggerKey, i3dMappings, self.rootNode) then
			loadTrigger:setSource(self)
			loadTrigger:register(true)
			table.insert(self.loadTriggers, loadTrigger)
		else
			loadTrigger:delete()
		end
	end)

	self.basicFillTypes = {}
	local fillTypeCategories = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, key, "fillTypeCategories", self.rootNode)

	if fillTypeCategories ~= nil then
		local fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: LoadingStation has invalid fillTypeCategory '%s'.")

		for _, fillType in pairs(fillTypes) do
			self.basicFillTypes[fillType] = true
		end
	end

	local fillTypeNames = XMLUtil.getValueFromXMLFileOrUserAttribute(xmlFile, key, "fillTypes", self.rootNode)

	if fillTypeNames ~= nil then
		local fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: LoadingStation has invalid fillType '%s'.")

		for _, fillType in pairs(fillTypes) do
			self.basicFillTypes[fillType] = true
		end
	end

	self:updateSupportedFillTypes()

	return true
end

function LoadingStation:delete()
	if self.loadTriggers ~= nil then
		for _, loadTrigger in ipairs(self.loadTriggers) do
			loadTrigger:delete()
		end
	end

	LoadingStation:superClass().delete(self)
end

function LoadingStation:readStream(streamId, connection)
	LoadingStation:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		for _, loadTrigger in ipairs(self.loadTriggers) do
			local loadTriggerId = NetworkUtil.readNodeObjectId(streamId)

			loadTrigger:readStream(streamId, connection)
			g_client:finishRegisterObject(loadTrigger, loadTriggerId)
		end
	end
end

function LoadingStation:writeStream(streamId, connection)
	LoadingStation:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		for _, loadTrigger in ipairs(self.loadTriggers) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(loadTrigger))
			loadTrigger:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, loadTrigger)
		end
	end
end

function LoadingStation:loadFromXMLFile(xmlFile, key)
	return true
end

function LoadingStation:saveToXMLFile(xmlFile, key, usedModNames)
end

function LoadingStation:getName()
	return self.stationName or self.owningPlaceable and self.owningPlaceable:getName() or "Loading Station"
end

function LoadingStation:addSourceStorage(storage)
	if storage ~= nil then
		assert(storage.getIsFillTypeSupported ~= nil, "LoadingStation:addSourceStorage: invalid storage given, missing function getIsFillTypeSupported")
		assert(storage.setFillLevel ~= nil)
		assert(storage.getFillLevel ~= nil)
		assert(storage.getFillLevels ~= nil)
		assert(storage.getSupportedFillTypes ~= nil)

		local hasMatchingFillType = false

		for fillType, _ in pairs(storage.fillTypes) do
			if self.supportedFillTypes[fillType] ~= nil then
				hasMatchingFillType = true
			end
		end

		if not hasMatchingFillType then
			return false
		end

		self.sourceStorages[storage] = storage

		storage:addLoadingStation(self)

		return true
	end

	return false
end

function LoadingStation:removeSourceStorage(storage)
	if storage ~= nil then
		storage:removeLoadingStation(self)

		self.sourceStorages[storage] = nil
	end
end

function LoadingStation:updateSupportedFillTypes()
	self.supportedFillTypes = {}
	self.aiSupportedFillTypes = {}

	for _, loadTrigger in pairs(self.loadTriggers) do
		local supportsAI = loadTrigger:getSupportAILoading()

		for fillType, _ in pairs(loadTrigger.fillTypes) do
			self.supportedFillTypes[fillType] = true

			if supportsAI then
				self.aiSupportedFillTypes[fillType] = true
			end
		end
	end

	for fillTypeIndex, _ in pairs(self.basicFillTypes) do
		self.supportedFillTypes[fillTypeIndex] = true
	end
end

function LoadingStation:getSupportedFillTypes()
	return self.supportedFillTypes
end

function LoadingStation:getIsFillTypeSupported(fillTypeIndex)
	return self.supportedFillTypes[fillTypeIndex] ~= nil
end

function LoadingStation:getIsFillTypeAISupported(fillTypeIndex)
	return self.aiSupportedFillTypes[fillTypeIndex] ~= nil
end

function LoadingStation:getAISupportedFillTypes()
	return self.aiSupportedFillTypes
end

function LoadingStation:getFillLevel(fillType, farmId)
	local fillLevel = 0

	for _, sourceStorage in pairs(self.sourceStorages) do
		if self:hasFarmAccessToStorage(farmId, sourceStorage) then
			fillLevel = fillLevel + sourceStorage:getFillLevel(fillType)
		end
	end

	return fillLevel
end

function LoadingStation:getAllFillLevels(farmId)
	local fillLevels = {}

	for _, sourceStorage in pairs(self.sourceStorages) do
		if self:hasFarmAccessToStorage(farmId, sourceStorage) then
			for fillType, fillLevel in pairs(sourceStorage:getFillLevels()) do
				fillLevels[fillType] = Utils.getNoNil(fillLevels[fillType], 0) + fillLevel
			end
		end
	end

	return fillLevels
end

function LoadingStation:addFillLevelToFillableObject(fillableObject, fillUnitIndex, fillTypeIndex, fillDelta, fillInfo, toolType)
	if fillableObject == nil or fillTypeIndex == FillType.UNKNOWN or fillDelta == 0 or toolType == nil then
		return 0
	end

	local farmId = fillableObject:getOwnerFarmId()

	if fillableObject:isa(Vehicle) then
		farmId = fillableObject:getActiveFarm()
	end

	local availableFillLevel = 0

	for _, sourceStorage in pairs(self.sourceStorages) do
		if self:hasFarmAccessToStorage(farmId, sourceStorage) then
			availableFillLevel = availableFillLevel + Utils.getNoNil(sourceStorage:getFillLevel(fillTypeIndex), 0)
		end
	end

	fillDelta = math.min(fillDelta, availableFillLevel)

	if fillDelta == 0 then
		return 0
	end

	local freeCapacity = fillableObject:getFillUnitFreeCapacity(fillUnitIndex)

	if fillableObject.getConveyorBeltTargetObject ~= nil then
		local object, objectFillUnitIndex = fillableObject:getConveyorBeltTargetObject()

		if object ~= nil then
			freeCapacity = object:getFillUnitFreeCapacity(objectFillUnitIndex)
		end
	end

	if fillableObject.getConveyorBeltFillLevel ~= nil then
		freeCapacity = freeCapacity - fillableObject:getConveyorBeltFillLevel()
	end

	fillDelta = math.min(freeCapacity, fillDelta)
	local usedFillLevel = fillableObject:addFillUnitFillLevel(farmId, fillUnitIndex, fillDelta, fillTypeIndex, toolType, fillInfo)
	local appliedFillLevel = usedFillLevel
	local remainingFillLevel = self:removeFillLevel(fillTypeIndex, usedFillLevel, farmId)
	fillDelta = appliedFillLevel - remainingFillLevel

	return fillDelta
end

function LoadingStation:removeFillLevel(fillTypeIndex, fillDelta, farmId)
	local remainingDelta = fillDelta

	for _, sourceStorage in pairs(self.sourceStorages) do
		if self:hasFarmAccessToStorage(farmId, sourceStorage) then
			local oldFillLevel = sourceStorage:getFillLevel(fillTypeIndex)

			if oldFillLevel > 0 then
				sourceStorage:setFillLevel(oldFillLevel - fillDelta, fillTypeIndex)
			end

			local newFillLevel = sourceStorage:getFillLevel(fillTypeIndex)
			remainingDelta = remainingDelta - (oldFillLevel - newFillLevel)

			if remainingDelta < 0.0001 then
				remainingDelta = 0

				break
			end
		end
	end

	return remainingDelta
end

function LoadingStation:getSourceStorages()
	return self.sourceStorages
end

function LoadingStation:getIsFillAllowedToFarm(farmId)
	for _, sourceStorage in pairs(self.sourceStorages) do
		if self:hasFarmAccessToStorage(farmId, sourceStorage) then
			return true
		end
	end

	return false
end

function LoadingStation:hasFarmAccessToStorage(farmId, storage)
	if self.hasStoragePerFarm then
		return farmId == storage:getOwnerFarmId()
	else
		return g_currentMission.accessHandler:canFarmAccess(farmId, storage)
	end
end

function LoadingStation:getAITargetPositionAndDirection(fillType)
	local loadTrigger = nil

	for _, trigger in ipairs(self.loadTriggers) do
		if trigger:getSupportAILoading() and (fillType == FillType.UNKNOWN or trigger:getIsFillTypeSupported(fillType)) then
			loadTrigger = trigger

			break
		end
	end

	if loadTrigger ~= nil then
		local x, z, xDir, zDir = loadTrigger:getAITargetPositionAndDirection()

		return x, z, xDir, zDir, loadTrigger
	end

	return nil
end

function LoadingStation.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Loading station node")
	schema:register(XMLValueType.STRING, basePath .. "#stationName", "Station name", "LoadingStation")
	schema:register(XMLValueType.FLOAT, basePath .. "#storageRadius", "Inside of this radius storages can be placed", 50)
	schema:register(XMLValueType.BOOL, basePath .. "#supportsExtension", "Supports extensions", false)
	schema:register(XMLValueType.STRING, basePath .. "#fillTypes", "Basic supported filltypes")
	schema:register(XMLValueType.STRING, basePath .. "#fillTypeCategories", "Basic supported filltype categories")
	LoadTrigger.registerXMLPaths(schema, basePath .. ".loadTrigger(?)")
end
