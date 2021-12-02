TransportMission = {}
local TransportMission_mt = Class(TransportMission, AbstractMission)

InitStaticObjectClass(TransportMission, "TransportMission", ObjectIds.MISSION_TRANSPORT)

TransportMission.CONTRACT_DURATION = 115200000
TransportMission.CONTRACT_DURATION_VAR = 57600000
TransportMission.REWARD_PER_METER = 0.5
TransportMission.REWARD_PER_OBJECT = 350
TransportMission.NUM_OBJECTS_PER_DRIVE = 5
TransportMission.TEST_HEIGHT = 50

function TransportMission.new(isServer, isClient, customMt)
	local self = AbstractMission.new(isServer, isClient, customMt or TransportMission_mt)
	self.objects = {}
	self.objectsAtTrigger = {}
	self.numFinished = 0

	return self
end

function TransportMission:delete()
	if self.pickup ~= nil then
		local trigger = g_missionManager.transportTriggers[self.pickup]

		if trigger ~= nil then
			trigger:setMission(nil)
		end
	end

	if self.dropoff ~= nil then
		local trigger = g_missionManager.transportTriggers[self.dropoff]

		if trigger ~= nil then
			trigger:setMission(nil)
		end
	end

	for _, object in pairs(self.objects) do
		object:delete()
	end

	self:destroyHotspots()
	TransportMission:superClass().delete(self)
end

function TransportMission:saveToXMLFile(xmlFile, key)
	TransportMission:superClass().saveToXMLFile(self, xmlFile, key)
	setXMLInt(xmlFile, key .. "#timeLeft", self.timeLeft)
	setXMLString(xmlFile, key .. "#config", self.missionConfig.name)
	setXMLString(xmlFile, key .. "#pickupTrigger", self.pickup)
	setXMLString(xmlFile, key .. "#dropoffTrigger", self.dropoff)
	setXMLString(xmlFile, key .. "#objectFilename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.objectFilename)))
	setXMLInt(xmlFile, key .. "#numObjects", self.numObjects)

	local index = 0

	for _, object in pairs(self.objects) do
		local x, y, z = getWorldTranslation(object.nodeId)
		local rx, ry, rz = getWorldRotation(object.nodeId)
		local objectKey = string.format("%s.object(%d)", key, index)

		setXMLString(xmlFile, objectKey .. "#translation", string.format("%f %f %f", x, y, z))
		setXMLString(xmlFile, objectKey .. "#rotation", string.format("%f %f %f", math.deg(rx), math.deg(ry), math.deg(rz)))

		index = index + 1
	end
end

function TransportMission:loadFromXMLFile(xmlFile, key)
	if not TransportMission:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end

	self.timeLeft = getXMLInt(xmlFile, key .. "#timeLeft")
	local name = getXMLString(xmlFile, key .. "#config")
	self.missionConfig = g_missionManager:getTransportMissionConfig(name)

	if self.missionConfig == nil then
		return false
	end

	self.pickup = getXMLString(xmlFile, key .. "#pickupTrigger")
	self.dropoff = getXMLString(xmlFile, key .. "#dropoffTrigger")
	self.objectFilename = NetworkUtil.convertFromNetworkFilename(getXMLString(xmlFile, key .. "#objectFilename"))
	self.numObjects = getXMLInt(xmlFile, key .. "#numObjects")

	if self.status == AbstractMission.STATUS_RUNNING then
		local i = 0

		while true do
			local objectKey = string.format("%s.object(%d)", key, i)

			if not hasXMLProperty(xmlFile, objectKey) then
				break
			end

			local x, y, z = unpack(string.getVectorN(getXMLString(xmlFile, objectKey .. "#translation"), 3))
			local rx, ry, rz = unpack(string.getVectorN(getXMLString(xmlFile, objectKey .. "#rotation"), 3))
			local object = self:createObject(x, y, z, rx, ry, rz)
			self.objects[object.nodeId] = object
			i = i + 1
		end
	end

	local pickupTrigger = self:getPickupTrigger()
	local dropoffTrigger = self:getDropoffTrigger()

	if pickupTrigger == nil or dropoffTrigger == nil then
		return false
	end

	pickupTrigger:setMission(self)
	dropoffTrigger:setMission(self)

	return true
end

function TransportMission:writeStream(streamId, connection)
	TransportMission:superClass().writeStream(self, streamId, connection)
	streamWriteString(streamId, self.pickup)
	streamWriteString(streamId, self.dropoff)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.objectFilename))
	streamWriteUInt8(streamId, self.numObjects)
	streamWriteUInt8(streamId, self.missionConfig.id)
end

function TransportMission:readStream(streamId, connection)
	TransportMission:superClass().readStream(self, streamId, connection)

	self.pickup = streamReadString(streamId)
	self.dropoff = streamReadString(streamId)
	self.objectFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	self.numObjects = streamReadUInt8(streamId)
	self.missionConfig = g_missionManager:getTransportMissionConfigById(streamReadUInt8(streamId))
	local trigger = g_missionManager.transportTriggers[self.pickup]

	trigger:setMission(self)

	trigger = g_missionManager.transportTriggers[self.dropoff]

	trigger:setMission(self)
end

function TransportMission:init(args)
	if not TransportMission:superClass().init(self) then
		return false
	end

	local tMission = table.getRandomElement(g_missionManager.transportMissions)
	local pickup, dropoff = nil

	for i = 1, table.getn(tMission.pickupTriggers) + 1 do
		local item = table.getRandomElement(tMission.pickupTriggers)
		local trigger = g_missionManager.transportTriggers[item.index]

		if trigger ~= nil and trigger.mission == nil then
			pickup = item

			trigger:setMission(self)

			break
		end
	end

	if pickup == nil then
		return false
	end

	for i = 1, table.getn(tMission.dropoffTriggers) + 1 do
		local item = table.getRandomElement(tMission.dropoffTriggers)
		local trigger = g_missionManager.transportTriggers[item.index]

		if trigger ~= nil and trigger.mission == nil then
			dropoff = item

			trigger:setMission(self)

			break
		end
	end

	if dropoff == nil or pickup.index == dropoff.index then
		return false
	end

	local object = table.getRandomElement(tMission.objects)
	self.numObjects = math.random(object.min, object.max)
	self.pickup = pickup.index
	self.dropoff = dropoff.index
	self.objectFilename = object.filename
	self.missionConfig = tMission
	self.timeLeft = TransportMission.CONTRACT_DURATION + (2 * math.random() - 1) * TransportMission.CONTRACT_DURATION_VAR
	local multiplier = pickup.rewardScale * dropoff.rewardScale * object.rewardScale
	self.reward = self:calculateReward(multiplier)

	return true
end

function TransportMission:calculateReward(multiplier)
	local triggerA = g_missionManager.transportTriggers[self.pickup]
	local triggerB = g_missionManager.transportTriggers[self.dropoff]
	local distance = calcDistanceFrom(triggerA.triggerId, triggerB.triggerId)
	local driveReward = math.ceil(self.numObjects / TransportMission.NUM_OBJECTS_PER_DRIVE) * TransportMission.REWARD_PER_METER * distance
	local handleReward = self.numObjects * TransportMission.REWARD_PER_OBJECT

	return (driveReward + handleReward) * multiplier
end

function TransportMission:getReward()
	local difficultyMultiplier = 0.8

	if self.mission.missionInfo.economicDifficulty == 2 then
		difficultyMultiplier = 1
	elseif self.mission.missionInfo.economicDifficulty == 1 then
		difficultyMultiplier = 1.2
	end

	return self.reward * difficultyMultiplier
end

function TransportMission:start()
	if not TransportMission:superClass().start(self) then
		return false
	end

	if not self:loadObjects() then
		return false
	end

	return true
end

function TransportMission:finish(success)
	TransportMission:superClass().finish(self, success)

	if self.mission:getIsServer() then
		self:destroyHotspots()

		if success then
			g_farmManager:getFarmById(self.farmId).stats:updateTransportJobsDone()
		end
	end

	if success then
		self.mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("fieldJob_transportFinished"))
	else
		self.mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("fieldJob_transportFailed"))
	end
end

function TransportMission:dismiss()
	TransportMission:superClass().dismiss(self)

	for _, object in pairs(self.objects) do
		object:delete()
	end

	self.objects = {}
end

function TransportMission:update(dt)
	TransportMission:superClass().update(self, dt)

	if not self:hasHotspots() and self.status == AbstractMission.STATUS_RUNNING then
		self:createHotspots()
		self:updateTriggerVisibility()
	end
end

function TransportMission:hasHotspots()
	return self.pickupHotspot ~= nil and self.dropoffHotspot ~= nil
end

function TransportMission:createHotspots()
	self.pickupHotspot = self:createHotspot(self:getPickupTrigger())
	self.dropoffHotspot = self:createHotspot(self:getDropoffTrigger())
end

function TransportMission:destroyHotspots()
	if self.pickupHotspot ~= nil then
		self.mission:removeMapHotspot(self.pickupHotspot)
		self.pickupHotspot:delete()

		self.pickupHotspot = nil
	end

	if self.dropoffHotspot ~= nil then
		self.mission:removeMapHotspot(self.dropoffHotspot)
		self.dropoffHotspot:delete()

		self.dropoffHotspot = nil
	end
end

function TransportMission:getPickupTrigger()
	return g_missionManager.transportTriggers[self.pickup]
end

function TransportMission:getDropoffTrigger()
	return g_missionManager.transportTriggers[self.dropoff]
end

function TransportMission:createHotspot(trigger)
	local x, _, z = getWorldTranslation(trigger.triggerId)
	local mapHotspot = MissionHotspot.new()

	mapHotspot:setWorldPosition(x, z)
	self.mission:addMapHotspot(mapHotspot)

	return mapHotspot
end

function TransportMission:updateTriggerVisibility()
	local trigger = g_missionManager.transportTriggers[self.pickup]

	trigger:onMissionUpdated()

	trigger = g_missionManager.transportTriggers[self.dropoff]

	trigger:onMissionUpdated()
end

function TransportMission:loadObjects()
	local trigger = self:getPickupTrigger()
	local objectConfig = nil

	for _, object in pairs(self.missionConfig.objects) do
		if object.filename == self.objectFilename then
			objectConfig = object

			break
		end
	end

	if objectConfig == nil then
		return false
	end

	local sizeX, _, sizeZ = unpack(objectConfig.size)
	local rx, ry, rz = getWorldRotation(trigger.triggerId)
	local tx, ty, tz = getWorldTranslation(trigger.triggerId)
	local rowOffset = sizeZ / 2 + 0.3
	local xCellOffset = sizeX + 0.1
	local dirX, dirZ = MathUtil.getDirectionFromYRotation(ry)
	local theta = math.atan2(dirZ, dirX)
	local rcos = math.cos(theta)
	local rsin = math.sin(theta)

	if not self:isTriggerEmpty(trigger, sizeX, sizeZ) then
		return false
	end

	for i = 1, self.numObjects do
		local dx = 0

		if i >= 5 then
			dx = -xCellOffset
		elseif i >= 3 then
			dx = xCellOffset
		end

		local dz = rowOffset

		if i % 2 == 0 then
			dz = -rowOffset
		end

		dz = rsin * dx + rcos * dz
		dx = rcos * dx - rsin * dz
		local object = self:createObject(tx + dx, ty, tz + dz, rx, ry, rz)
		self.objects[object.nodeId] = object
	end

	return true
end

function TransportMission:isTriggerEmpty(trigger, objectSizeX, objectSizeZ)
	local rx, ry, rz = getWorldRotation(trigger.triggerId)
	local tx, ty, tz = getWorldTranslation(trigger.triggerId)
	self.tempHasCollision = false

	overlapBox(tx, ty, tz, rx, ry, rz, 3 * (objectSizeX + 0.1), TransportMission.TEST_HEIGHT * 0.5, 2 * (objectSizeZ + 0.1), "collisionTestCallback", self, 537087)

	return not self.tempHasCollision
end

function TransportMission:collisionTestCallback(transformId)
	if self.mission.nodeToObject[transformId] ~= nil or self.mission.players[transformId] ~= nil or self.mission:getNodeObject(transformId) ~= nil then
		self.tempHasCollision = true
	end
end

function TransportMission:createObject(x, y, z, rx, ry, rz)
	local transportObject = MissionPhysicsObject.new(self.mission:getIsServer(), self.mission:getIsClient())

	if transportObject:load(self.objectFilename, x, y, z, rx, ry, rz) then
		transportObject:register()

		transportObject.mission = self

		return transportObject
	else
		transportObject:delete()
	end

	return nil
end

function TransportMission:objectEnteredTrigger(trigger, objectId)
	if self.objects[objectId] ~= nil and trigger == self:getDropoffTrigger() and self.objectsAtTrigger[objectId] ~= true then
		self.objectsAtTrigger[objectId] = true
		self.numFinished = self.numFinished + 1
	end
end

function TransportMission:objectLeftTrigger(trigger, objectId)
	if self.objects[objectId] ~= nil and trigger == self:getDropoffTrigger() and self.objectsAtTrigger[objectId] == true then
		self.objectsAtTrigger[objectId] = false
		self.numFinished = self.numFinished - 1
	end
end

function TransportMission:getTriggerInfo(index, isPickup)
	local list = self.missionConfig.dropoffTriggers

	if isPickup then
		list = self.missionConfig.pickupTriggers
	end

	for _, info in ipairs(list) do
		if info.index == index then
			return info
		end
	end

	return {}
end

function TransportMission:getTriggerTitle(index, isPickup)
	local info = self:getTriggerInfo(index, isPickup)

	if info ~= nil then
		return g_i18n:convertText(Utils.getNoNil(info.title, ""))
	end

	return ""
end

function TransportMission:getData()
	local pickup = self:getTriggerTitle(self.pickup, true)
	local dropoff = self:getTriggerTitle(self.dropoff, false)
	slot3.description = self.missionConfig.description or string.format(g_i18n:getText("fieldJob_desc_transporting_generic"), pickup, dropoff)

	return {
		action = "",
		location = pickup,
		jobType = g_i18n:getText("fieldJob_jobType_transporting")
	}
end

function TransportMission:getNPC()
	return g_npcManager:getNPCByIndex(self.missionConfig.npcIndex)
end

function TransportMission:getCompletion()
	return self.numFinished / self.numObjects
end

function TransportMission.canRun()
	if g_missionManager.numTransportTriggers < 2 then
		return false
	end

	if table.getn(g_missionManager.transportMissions) == 0 then
		return false
	end

	return true
end

g_missionManager:registerMissionType(TransportMission, "transport", MissionManager.CATEGORY_TRANSPORT, 1)
