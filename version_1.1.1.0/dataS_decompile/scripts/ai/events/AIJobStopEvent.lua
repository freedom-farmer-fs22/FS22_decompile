AIJobStopEvent = {}
local AIJobStopEvent_mt = Class(AIJobStopEvent, Event)

InitStaticEventClass(AIJobStopEvent, "AIJobStopEvent", EventIds.EVENT_AI_JOB_STOP)

function AIJobStopEvent.emptyNew()
	local self = Event.new(AIJobStopEvent_mt)

	return self
end

function AIJobStopEvent.new(job, aiMessage)
	local self = AIJobStopEvent.emptyNew()
	self.aiMessage = aiMessage
	self.job = job

	return self
end

function AIJobStopEvent:readStream(streamId, connection)
	local jobId = streamReadInt32(streamId)
	self.job = g_currentMission.aiSystem:getJobById(jobId)

	if streamReadBool(streamId) then
		local messageIndex = streamReadInt32(streamId)
		self.aiMessage = g_currentMission.aiMessageManager:createMessage(messageIndex)

		self.aiMessage:readStream(streamId, connection)
	end

	self:run(connection)
end

function AIJobStopEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.job.jobId)

	if streamWriteBool(streamId, self.aiMessage ~= nil) then
		local messageIndex = g_currentMission.aiMessageManager:getMessageIndex(self.aiMessage)

		streamWriteInt32(streamId, messageIndex)
		self.aiMessage:writeStream(streamId, connection)
	end
end

function AIJobStopEvent:run(connection)
	if connection:getIsServer() then
		g_currentMission.aiSystem:stopJobInternal(self.job, self.aiMessage)
	else
		g_currentMission.aiSystem:stopJob(self.job, self.aiMessage)
	end
end
