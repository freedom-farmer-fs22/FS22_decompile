AIMessageErrorNoValidFillTypeLoaded = {}
local AIMessageErrorNoValidFillTypeLoaded_mt = Class(AIMessageErrorNoValidFillTypeLoaded, AIMessage)

function AIMessageErrorNoValidFillTypeLoaded.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorNoValidFillTypeLoaded_mt)

	return self
end

function AIMessageErrorNoValidFillTypeLoaded:getMessage()
	return g_i18n:getText("ai_messageErrorNoValidFillTypeLoaded")
end
