AIMessageErrorBlockedByObject = {}
local AIMessageErrorBlockedByObject_mt = Class(AIMessageErrorBlockedByObject, AIMessage)

function AIMessageErrorBlockedByObject.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorBlockedByObject_mt)

	return self
end

function AIMessageErrorBlockedByObject:getMessage()
	return g_i18n:getText("ai_messageErrorBlockedByObject")
end
