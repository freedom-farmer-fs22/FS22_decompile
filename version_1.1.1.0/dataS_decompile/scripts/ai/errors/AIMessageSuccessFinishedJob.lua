AIMessageSuccessFinishedJob = {}
local AIMessageSuccessFinishedJob_mt = Class(AIMessageSuccessFinishedJob, AIMessage)

function AIMessageSuccessFinishedJob.new(customMt)
	local self = AIMessage.new(customMt or AIMessageSuccessFinishedJob_mt)

	return self
end

function AIMessageSuccessFinishedJob:getMessage()
	return g_i18n:getText("ai_messageSuccessFinishedJob")
end

function AIMessageSuccessFinishedJob:getType()
	return AIMessageType.OK
end
