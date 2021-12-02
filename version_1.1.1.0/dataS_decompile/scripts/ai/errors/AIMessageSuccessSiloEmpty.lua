AIMessageSuccessSiloEmpty = {}
local AIMessageSuccessSiloEmpty_mt = Class(AIMessageSuccessSiloEmpty, AIMessage)

function AIMessageSuccessSiloEmpty.new(customMt)
	local self = AIMessage.new(customMt or AIMessageSuccessSiloEmpty_mt)

	return self
end

function AIMessageSuccessSiloEmpty:getMessage()
	return g_i18n:getText("ai_messageSuccessSiloEmpty")
end

function AIMessageSuccessSiloEmpty:getType()
	return AIMessageType.OK
end
