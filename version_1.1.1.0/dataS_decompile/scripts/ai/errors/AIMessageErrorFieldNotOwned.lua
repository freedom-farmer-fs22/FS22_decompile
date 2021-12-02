AIMessageErrorFieldNotOwned = {}
local AIMessageErrorFieldNotOwned_mt = Class(AIMessageErrorFieldNotOwned, AIMessage)

function AIMessageErrorFieldNotOwned.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorFieldNotOwned_mt)

	return self
end

function AIMessageErrorFieldNotOwned:getMessage()
	return g_i18n:getText("ai_messageErrorFieldNotOwned")
end
