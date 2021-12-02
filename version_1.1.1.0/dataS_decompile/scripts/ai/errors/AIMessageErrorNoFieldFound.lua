AIMessageErrorNoFieldFound = {}
local AIMessageErrorNoFieldFound_mt = Class(AIMessageErrorNoFieldFound, AIMessage)

function AIMessageErrorNoFieldFound.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorNoFieldFound_mt)

	return self
end

function AIMessageErrorNoFieldFound:getMessage()
	return g_i18n:getText("ai_messageErrorNoFieldFound")
end
