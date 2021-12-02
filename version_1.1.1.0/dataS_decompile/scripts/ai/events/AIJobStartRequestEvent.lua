AIJobStartRequestEvent = {}
local AIJobStartRequestEvent_mt = Class(AIJobStartRequestEvent, Event)

InitStaticEventClass(AIJobStartRequestEvent, "AIJobStartRequestEvent", EventIds.EVENT_AI_JOB_START_REQUEST)

function AIJobStartRequestEvent.emptyNew()
	local self = Event.new(AIJobStartRequestEvent_mt)

	return self
end

function AIJobStartRequestEvent.new(job, startFarmId)
	local self = AIJobStartRequestEvent.emptyNew()
	self.job = job
	self.startFarmId = startFarmId

	return self
end

function AIJobStartRequestEvent.newServerToClient(state, jobTypeIndex)
	local self = AIJobStartRequestEvent.emptyNew()
	self.state = state
	self.jobTypeIndex = jobTypeIndex

	return self
end

function AIJobStartRequestEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.startFarmId = streamReadUInt8(streamId)
		local jobTypeIndex = streamReadUInt16(streamId)
		self.job = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)

		self.job:readStream(streamId, connection)
	else
		self.state = streamReadUInt8(streamId)
		self.jobTypeIndex = streamReadUInt16(streamId)
	end

	self:run(connection)
end

function AIJobStartRequestEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		streamWriteUInt8(streamId, self.startFarmId)

		local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)

		streamWriteUInt16(streamId, jobTypeIndex)
		self.job:writeStream(streamId, connection)
	else
		streamWriteUInt8(streamId, self.state)
		streamWriteUInt16(streamId, self.jobTypeIndex)
	end
end

function AIJobStartRequestEvent:run(connection)
	if not connection:getIsServer() then
		local jobTypeIndex = g_currentMission.aiJobTypeManager:getJobTypeIndex(self.job)
		local startable, state = self.job:getIsStartable(connection)

		if not startable then
			connection:sendEvent(AIJobStartRequestEvent.newServerToClient(state, jobTypeIndex))

			return
		end

		connection:sendEvent(AIJobStartRequestEvent.newServerToClient(0, jobTypeIndex))
		g_currentMission.aiSystem:startJob(self.job, self.startFarmId)
	else
		g_messageCenter:publish(AIJobStartRequestEvent, self.state, self.jobTypeIndex)
	end
end
