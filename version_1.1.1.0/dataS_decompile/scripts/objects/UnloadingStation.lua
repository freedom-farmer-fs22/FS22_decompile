UnloadingStation = {
	FX_DURATION = 5000
}
local UnloadingStation_mt = Class(UnloadingStation, Object)

InitStaticObjectClass(UnloadingStation, "UnloadingStation", ObjectIds.OBJECT_UNLOADING_STATION)

function UnloadingStation.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or UnloadingStation_mt)

	return self
end

function UnloadingStation:load(components, xmlFile, key, customEnv, i3dMappings, rootNode)
	self.rootNode = rootNode or xmlFile:getValue(key .. "#node", rootNode, components, i3dMappings)

	if self.rootNode == nil then
		Logging.xmlError(xmlFile, "Missing node defined in '%s'", key)

		return false
	end

	self.rootNodeName = getName(self.rootNode)
	local stationName = xmlFile:getValue(key .. "#stationName", nil)
	self.stationName = stationName and g_i18n:convertText(stationName)
	self.storageRadius = xmlFile:getValue(key .. "#storageRadius", 50)
	self.hideFromPricesMenu = xmlFile:getValue(key .. "#hideFromPricesMenu", false)
	self.supportsExtension = xmlFile:getValue(key .. "#supportsExtension", false)
	self.owningPlaceable = nil
	self.hasStoragePerFarm = false
	self.targetStorages = {}
	self.unloadTriggers = {}
	self.supportedFillTypes = {}
	self.aiSupportedFillTypes = {}

	xmlFile:iterate(key .. ".unloadTrigger", function (index, unloadTriggerKey)
		local unloadTrigger = UnloadTrigger.new(self.isServer, self.isClient)

		if unloadTrigger:load(components, xmlFile, unloadTriggerKey, self, nil, i3dMappings) then
			unloadTrigger:setTarget(self)
			unloadTrigger:register(true)
			table.insert(self.unloadTriggers, unloadTrigger)
		else
			unloadTrigger:delete()
		end
	end)

	if self.isClient then
		self.samples = {
			idle = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "idle", self.baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil),
			active = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "active", self.baseDirectory, components, 1, AudioGroup.ENVIRONMENT, i3dMappings, nil)
		}
		self.animations = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", components, self, i3dMappings)
		self.effects = g_effectManager:loadEffect(xmlFile, key .. ".effectNodes", components, self, i3dMappings)
		self.hasFx = self.samples.active ~= nil or #self.animations > 0 or #self.effects > 0
		self.fxTimer = nil
		self.fxActive = false

		g_soundManager:playSample(self.samples.idle)
	end

	self:updateSupportedFillTypes()

	return true
end

function UnloadingStation:delete()
	if self.unloadTriggers ~= nil then
		for _, unloadTrigger in pairs(self.unloadTriggers) do
			unloadTrigger:delete()
		end
	end

	if self.isClient then
		g_soundManager:stopSamples(self.samples)
		g_soundManager:deleteSamples(self.samples)
		g_animationManager:deleteAnimations(self.animations)
		g_effectManager:deleteEffects(self.effects)
	end

	if self.fxTimer ~= nil then
		self.fxTimer:delete()

		self.fxTimer = nil
	end

	UnloadingStation:superClass().delete(self)
end

function UnloadingStation:readStream(streamId, connection)
	UnloadingStation:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		for _, unloadTrigger in ipairs(self.unloadTriggers) do
			local unloadTriggerId = NetworkUtil.readNodeObjectId(streamId)

			unloadTrigger:readStream(streamId, connection)
			g_client:finishRegisterObject(unloadTrigger, unloadTriggerId)
		end
	end
end

function UnloadingStation:writeStream(streamId, connection)
	UnloadingStation:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		for _, unloadTrigger in ipairs(self.unloadTriggers) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(unloadTrigger))
			unloadTrigger:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, unloadTrigger)
		end
	end
end

function UnloadingStation:loadFromXMLFile(xmlFile, key)
	return true
end

function UnloadingStation:saveToXMLFile(xmlFile, key, usedModNames)
end

function UnloadingStation:getName()
	return self.stationName or self.owningPlaceable and self.owningPlaceable:getName() or "Unloading Station"
end

function UnloadingStation:updateSupportedFillTypes()
	self.supportedFillTypes = {}
	self.aiSupportedFillTypes = {}

	for _, unloadTrigger in pairs(self.unloadTriggers) do
		local supportsAI = unloadTrigger:getSupportAIUnloading()

		for fillType, _ in pairs(unloadTrigger.fillTypes) do
			self.supportedFillTypes[fillType] = true

			if supportsAI then
				self.aiSupportedFillTypes[fillType] = true
			end
		end
	end
end

function UnloadingStation:addTargetStorage(storage)
	if storage ~= nil then
		assert(storage.getFreeCapacity)
		assert(storage.getIsFillTypeSupported ~= nil)
		assert(storage.setFillLevel ~= nil)
		assert(storage.getFillLevel ~= nil)

		local hasMatchingFillType = false

		for fillType, _ in pairs(storage.fillTypes) do
			if self.supportedFillTypes[fillType] ~= nil then
				hasMatchingFillType = true
			end
		end

		if not hasMatchingFillType then
			return false
		end

		self.targetStorages[storage] = storage

		storage:addUnloadingStation(self)

		return true
	end

	return false
end

function UnloadingStation:removeTargetStorage(storage)
	if storage ~= nil then
		storage:removeUnloadingStation(self)

		self.targetStorages[storage] = nil
	end
end

function UnloadingStation:getIsFillTypeSupported(fillTypeIndex)
	return self.supportedFillTypes[fillTypeIndex] ~= nil
end

function UnloadingStation:getSupportedFillTypes()
	return self.supportedFillTypes
end

function UnloadingStation:getIsFillTypeAISupported(fillTypeIndex)
	return self.aiSupportedFillTypes[fillTypeIndex] ~= nil
end

function UnloadingStation:getAISupportedFillTypes()
	return self.aiSupportedFillTypes
end

function UnloadingStation:getIsFillTypeAllowed(fillTypeIndex, extraAttributes)
	for _, targetStorage in pairs(self.targetStorages) do
		if targetStorage:getFreeCapacity(fillTypeIndex, true) > 0.1 then
			return true
		end
	end

	return false
end

function UnloadingStation:getFreeCapacity(fillTypeIndex, farmId)
	local freeCapacity = 0

	for _, targetStorage in pairs(self.targetStorages) do
		if farmId == nil or self:hasFarmAccessToStorage(farmId, targetStorage) then
			freeCapacity = freeCapacity + targetStorage:getFreeCapacity(fillTypeIndex)
		end
	end

	return freeCapacity
end

function UnloadingStation:getCapacity(fillTypeIndex, farmId)
	local capacity = 0

	for _, targetStorage in pairs(self.targetStorages) do
		if self:hasFarmAccessToStorage(farmId, targetStorage) and targetStorage:getIsFillTypeSupported(fillTypeIndex) then
			local storageCapacity = targetStorage:getCapacity(fillTypeIndex)

			if storageCapacity ~= nil then
				capacity = capacity + storageCapacity
			end
		end
	end

	return capacity
end

function UnloadingStation:getFillLevel(fillTypeIndex, farmId)
	local fillLevel = 0

	for _, targetStorage in pairs(self.targetStorages) do
		if self:hasFarmAccessToStorage(farmId, targetStorage) then
			fillLevel = fillLevel + targetStorage:getFillLevel(fillTypeIndex)
		end
	end

	return fillLevel
end

function UnloadingStation:getIsToolTypeAllowed(toolType)
	return true
end

function UnloadingStation:addFillLevelFromTool(farmId, deltaFillLevel, fillType, fillInfo, toolType, extraAttributes)
	assert(deltaFillLevel >= 0)

	local movedFillLevel = 0

	if self:getIsFillTypeAllowed(fillType) and self:getIsToolTypeAllowed(toolType) then
		for _, targetStorage in pairs(self.targetStorages) do
			if self:hasFarmAccessToStorage(farmId, targetStorage) then
				if targetStorage:getFreeCapacity(fillType) > 0 then
					local oldFillLevel = targetStorage:getFillLevel(fillType)

					targetStorage:setFillLevel(oldFillLevel + deltaFillLevel, fillType, fillInfo)

					local newFillLevel = targetStorage:getFillLevel(fillType)
					movedFillLevel = movedFillLevel + newFillLevel - oldFillLevel
				end

				if movedFillLevel >= deltaFillLevel - 0.001 then
					movedFillLevel = deltaFillLevel

					self:startFx(fillType)

					break
				end
			end
		end
	end

	return movedFillLevel
end

function UnloadingStation:startFx(fillType)
	if self.isClient and self.hasFx then
		if self.fxTimer == nil then
			self.fxTimer = Timer.new(UnloadingStation.FX_DURATION):setFinishCallback(function ()
				if self.isClient then
					g_soundManager:stopSample(self.samples.active)
					g_animationManager:stopAnimations(self.animations)
					g_effectManager:stopEffects(self.effects)

					self.fxActive = false
				end
			end)
		end

		self.fxTimer:start()

		if not self.fxActive then
			g_soundManager:playSample(self.samples.active)
			g_animationManager:startAnimations(self.animations)
			g_effectManager:setFillType(self.effects, fillType)
			g_effectManager:startEffects(self.effects)

			self.fxActive = true
		end
	end
end

function UnloadingStation:getIsFillAllowedFromFarm(farmId)
	for _, targetStorage in pairs(self.targetStorages) do
		if self:hasFarmAccessToStorage(farmId, targetStorage) then
			return true
		end
	end

	return false
end

function UnloadingStation:hasFarmAccessToStorage(farmId, storage)
	if self.hasStoragePerFarm then
		return farmId == storage:getOwnerFarmId()
	else
		return g_currentMission.accessHandler:canFarmAccess(farmId, storage)
	end
end

function UnloadingStation:getAITargetPositionAndDirection(fillType)
	local unloadTrigger = nil

	for _, trigger in ipairs(self.unloadTriggers) do
		if trigger:getSupportAIUnloading() and (fillType == FillType.UNKNOWN or trigger:getIsFillTypeAllowed(fillType)) then
			unloadTrigger = trigger

			break
		end
	end

	if unloadTrigger ~= nil then
		local x, z, xDir, zDir = unloadTrigger:getAITargetPositionAndDirection()

		return x, z, xDir, zDir, unloadTrigger
	end

	return nil
end

function UnloadingStation.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Unloading station node")
	schema:register(XMLValueType.STRING, basePath .. "#stationName", "Station name", "LoadingStation")
	schema:register(XMLValueType.FLOAT, basePath .. "#storageRadius", "Inside of this radius storages can be placed", 50)
	schema:register(XMLValueType.BOOL, basePath .. "#hideFromPricesMenu", "Hide station from prices menu", false)
	schema:register(XMLValueType.BOOL, basePath .. "#supportsExtension", "Supports extensions", false)
	UnloadTrigger.registerXMLPaths(schema, basePath .. ".unloadTrigger(?)")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "active")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "idle")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".animationNodes")
	EffectManager.registerEffectXMLPaths(schema, basePath .. ".effectNodes")
end
