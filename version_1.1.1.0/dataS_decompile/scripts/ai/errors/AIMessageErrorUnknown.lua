AIMessageErrorUnknown = {}
local AIMessageErrorUnknown_mt = Class(AIMessageErrorUnknown, AIMessage)

function AIMessageErrorUnknown.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorUnknown_mt)

	return self
end

function AIMessageErrorUnknown:getMessage()
	return g_i18n:getText("ai_messageErrorUnkown")
end
