AIMessageErrorOutOfFill = {}
local AIMessageErrorOutOfFill_mt = Class(AIMessageErrorOutOfFill, AIMessage)

function AIMessageErrorOutOfFill.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorOutOfFill_mt)

	return self
end

function AIMessageErrorOutOfFill:getMessage()
	return g_i18n:getText("ai_messageErrorOutOfFill")
end
