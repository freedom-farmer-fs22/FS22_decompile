AIJobSkipTaskEvent = {}
local AIJobSkipTaskEvent_mt = Class(AIJobSkipTaskEvent, Event)

InitStaticEventClass(AIJobSkipTaskEvent, "AIJobSkipTaskEvent", EventIds.EVENT_AI_JOB_SKIP_TASK)

function AIJobSkipTaskEvent.emptyNew()
	local self = Event.new(AIJobSkipTaskEvent_mt)

	return self
end

function AIJobSkipTaskEvent.new(job)
	local self = AIJobSkipTaskEvent.emptyNew()
	self.job = job

	return self
end

function AIJobSkipTaskEvent:readStream(streamId, connection)
	local jobId = streamReadInt32(streamId)
	self.job = g_currentMission.aiSystem:getJobById(jobId)

	self:run(connection)
end

function AIJobSkipTaskEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.job.jobId)
end

function AIJobSkipTaskEvent:run(connection)
	assert(not connection:getIsServer(), "AIJobSkipTaskEvent is client to server only")
	g_currentMission.aiSystem:skipCurrentTaskInternal(self.job)
end
