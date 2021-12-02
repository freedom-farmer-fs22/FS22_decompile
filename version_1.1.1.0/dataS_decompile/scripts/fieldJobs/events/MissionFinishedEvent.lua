MissionFinishedEvent = {}
local MissionFinishedEvent_mt = Class(MissionFinishedEvent, Event)

InitStaticEventClass(MissionFinishedEvent, "MissionFinishedEvent", EventIds.EVENT_MISSION_FINISHED)

function MissionFinishedEvent.emptyNew()
	local self = Event.new(MissionFinishedEvent_mt)

	return self
end

function MissionFinishedEvent.new(mission, success, stealingCost)
	local self = MissionFinishedEvent.emptyNew()
	self.mission = mission
	self.success = success
	self.stealingCost = stealingCost

	return self
end

function MissionFinishedEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.mission)
	streamWriteBool(streamId, self.success)
	streamWriteFloat32(streamId, self.stealingCost)
end

function MissionFinishedEvent:readStream(streamId, connection)
	self.mission = NetworkUtil.readNodeObject(streamId)
	self.success = streamReadBool(streamId)
	self.stealingCost = streamReadFloat32(streamId)

	self:run(connection)
end

function MissionFinishedEvent:run(connection)
	if connection:getIsServer() then
		self.mission.stealingCost = self.stealingCost

		self.mission:finish(self.success)
	end
end
