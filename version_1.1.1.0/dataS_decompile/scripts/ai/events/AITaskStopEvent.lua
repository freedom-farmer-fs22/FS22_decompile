AITaskStopEvent = {}
local AITaskStopEvent_mt = Class(AITaskStopEvent, Event)

InitStaticEventClass(AITaskStopEvent, "AITaskStopEvent", EventIds.EVENT_AI_TASK_STOP)

function AITaskStopEvent.emptyNew()
	local self = Event.new(AITaskStopEvent_mt)

	return self
end

function AITaskStopEvent.new(job, task)
	local self = AITaskStopEvent.emptyNew()
	self.job = job
	self.task = task

	return self
end

function AITaskStopEvent:readStream(streamId, connection)
	local jobId = streamReadInt32(streamId)
	self.job = g_currentMission.aiSystem:getJobById(jobId)
	self.task = self.job:getTaskByIndex(streamReadUInt8(streamId))

	self:run(connection)
end

function AITaskStopEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.job.jobId)
	streamWriteUInt8(streamId, self.task.taskIndex)
end

function AITaskStopEvent:run(connection)
	self.job:stopTask(self.task)
end
