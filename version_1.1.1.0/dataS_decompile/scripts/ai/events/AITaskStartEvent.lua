AITaskStartEvent = {}
local AITaskStartEvent_mt = Class(AITaskStartEvent, Event)

InitStaticEventClass(AITaskStartEvent, "AITaskStartEvent", EventIds.EVENT_AI_TASK_START)

function AITaskStartEvent.emptyNew()
	local self = Event.new(AITaskStartEvent_mt)

	return self
end

function AITaskStartEvent.new(job, task)
	local self = AITaskStartEvent.emptyNew()
	self.job = job
	self.task = task

	return self
end

function AITaskStartEvent:readStream(streamId, connection)
	local jobId = streamReadInt32(streamId)
	self.job = g_currentMission.aiSystem:getJobById(jobId)
	self.task = self.job:getTaskByIndex(streamReadUInt8(streamId))

	self:run(connection)
end

function AITaskStartEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.job.jobId)
	streamWriteUInt8(streamId, self.task.taskIndex)
end

function AITaskStartEvent:run(connection)
	self.job:startTask(self.task)
end
