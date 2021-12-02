AIMessageErrorVehicleDeleted = {}
local AIMessageErrorVehicleDeleted_mt = Class(AIMessageErrorVehicleDeleted, AIMessage)

function AIMessageErrorVehicleDeleted.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorVehicleDeleted_mt)

	return self
end

function AIMessageErrorVehicleDeleted:getMessage()
	return g_i18n:getText("ai_messageErrorVehicleDeleted")
end
