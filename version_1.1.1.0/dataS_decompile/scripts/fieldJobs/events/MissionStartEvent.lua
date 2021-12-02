MissionStartEvent = {}
local MissionStartEvent_mt = Class(MissionStartEvent, Event)

InitStaticEventClass(MissionStartEvent, "MissionStartEvent", EventIds.EVENT_MISSION_START)

function MissionStartEvent.emptyNew()
	local self = Event.new(MissionStartEvent_mt)

	return self
end

function MissionStartEvent.new(mission, farmId, spawnVehicles)
	local self = MissionStartEvent.emptyNew()
	self.mission = mission
	self.farmId = farmId
	self.spawnVehicles = spawnVehicles

	return self
end

function MissionStartEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.mission)
		streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		streamWriteBool(streamId, self.spawnVehicles or false)
	end
end

function MissionStartEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.mission = NetworkUtil.readNodeObject(streamId)
		self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.spawnVehicles = streamReadBool(streamId)
	end

	self:run(connection)
end

function MissionStartEvent:run(connection)
	if not connection:getIsServer() then
		local senderUserId = g_currentMission.userManager:getUserIdByConnection(connection)
		local senderFarm = g_farmManager:getFarmByUserId(senderUserId)

		if g_currentMission:getHasPlayerPermission("manageContracts", connection, senderFarm.farmId) then
			g_missionManager:startMission(self.mission, self.farmId, self.spawnVehicles)
		end
	end
end
