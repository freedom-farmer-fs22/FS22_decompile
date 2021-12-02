AIJobStartEvent = {}
local AIJobStartEvent_mt = Class(AIJobStartEvent, Event)

InitStaticEventClass(AIJobStartEvent, "AIJobStartEvent", EventIds.EVENT_AI_JOB_START)

function AIJobStartEvent.emptyNew()
	local self = Event.new(AIJobStartEvent_mt)

	return self
end

function AIJobStartEvent.new(job, startFarmId)
	local self = AIJobStartEvent.emptyNew()
	self.job = job
	self.startFarmId = startFarmId

	return self
end

function AIJobStartEvent:readStream(streamId, connection)
	assert(connection:getIsServer(), "AIJobStartEvent is a server to client only event")

	self.startFarmId = streamReadUInt8(streamId)
	local jobTypeIndex = streamReadInt32(streamId)
	self.job = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)

	self.job:readStream(streamId, connection)
	self:run(connection)
end

function AIJobStartEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.startFarmId)

	local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)

	streamWriteInt32(streamId, jobTypeIndex)
	self.job:writeStream(streamId, connection)
end

function AIJobStartEvent:run(connection)
	g_currentMission.aiSystem:startJobInternal(self.job, self.startFarmId)
end
