AIMessageErrorNotReachable = {}
local AIMessageErrorNotReachable_mt = Class(AIMessageErrorNotReachable, AIMessage)

function AIMessageErrorNotReachable.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorNotReachable_mt)

	return self
end

function AIMessageErrorNotReachable:getMessage()
	return g_i18n:getText("ai_messageErrorNotReachable")
end
