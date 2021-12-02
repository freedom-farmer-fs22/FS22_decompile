AIMessageErrorVehicleBroken = {}
local AIMessageErrorVehicleBroken_mt = Class(AIMessageErrorVehicleBroken, AIMessage)

function AIMessageErrorVehicleBroken.new(customMt)
	local self = AIMessage.new(customMt or AIMessageErrorVehicleBroken_mt)

	return self
end

function AIMessageErrorVehicleBroken:getMessage()
	return g_i18n:getText("ai_messageErrorVehicleBroken")
end
