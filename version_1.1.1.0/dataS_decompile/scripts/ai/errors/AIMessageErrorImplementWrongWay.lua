AIMessageErrorImplementWrongWay = {}
local AIMessageErrorImplementWrongWay_mt = Class(AIMessageErrorImplementWrongWay, AIMessage)

function AIMessageErrorImplementWrongWay.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorImplementWrongWay_mt)

	return self
end

function AIMessageErrorImplementWrongWay:getMessage()
	return g_i18n:getText("ai_messageErrorImplementWrongWay")
end
