AIMessageErrorThreshingNotAllowed = {}
local AIMessageErrorThreshingNotAllowed_mt = Class(AIMessageErrorThreshingNotAllowed, AIMessage)

function AIMessageErrorThreshingNotAllowed.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorThreshingNotAllowed_mt)

	return self
end

function AIMessageErrorThreshingNotAllowed:getMessage()
	return g_i18n:getText("ai_messageErrorThreshingNotAllowed")
end
