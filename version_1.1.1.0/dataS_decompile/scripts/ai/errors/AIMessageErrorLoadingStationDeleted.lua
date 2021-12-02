AIMessageErrorLoadingStationDeleted = {}
local AIMessageErrorLoadingStationDeleted_mt = Class(AIMessageErrorLoadingStationDeleted, AIMessage)

function AIMessageErrorLoadingStationDeleted.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorLoadingStationDeleted_mt)

	return self
end

function AIMessageErrorLoadingStationDeleted:getMessage()
	return g_i18n:getText("ai_messageErrorLoadingStationDeleted")
end
