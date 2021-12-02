AIMessageErrorGraintankIsFull = {}
local AIMessageErrorGraintankIsFull_mt = Class(AIMessageErrorGraintankIsFull, AIMessage)

function AIMessageErrorGraintankIsFull.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorGraintankIsFull_mt)

	return self
end

function AIMessageErrorGraintankIsFull:getMessage()
	return g_i18n:getText("ai_messageErrorGrainTankIsFull")
end
