AIMessageErrorOutOfFuel = {}
local AIMessageErrorOutOfFuel_mt = Class(AIMessageErrorOutOfFuel, AIMessage)

function AIMessageErrorOutOfFuel.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorOutOfFuel_mt)

	return self
end

function AIMessageErrorOutOfFuel:getMessage()
	return g_i18n:getText("ai_messageErrorOutOfFuel")
end
