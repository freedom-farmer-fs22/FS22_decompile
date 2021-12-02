MissionStartedEvent = {}
local MissionStartedEvent_mt = Class(MissionStartedEvent, Event)

InitStaticEventClass(MissionStartedEvent, "MissionStartedEvent", EventIds.EVENT_MISSION_STARTED)

function MissionStartedEvent.emptyNew()
	local self = Event.new(MissionStartedEvent_mt)

	return self
end

function MissionStartedEvent.new(mission)
	local self = MissionStartedEvent.emptyNew()
	self.mission = mission

	return self
end

function MissionStartedEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.mission)
		streamWriteUInt8(streamId, self.mission.status)
		streamWriteUIntN(streamId, self.mission.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		streamWriteInt32(streamId, self.mission.activeMissionId)
	end
end

function MissionStartedEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		self.mission = NetworkUtil.readNodeObject(streamId)
		self.mission.status = streamReadUInt8(streamId)
		self.mission.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.mission.activeMissionId = streamReadInt32(streamId)
	end

	self:run(connection)
end

function MissionStartedEvent:run(connection)
	if connection:getIsServer() then
		self.mission:started()
		g_messageCenter:publish(MissionStartedEvent, self.mission)
	end
end
