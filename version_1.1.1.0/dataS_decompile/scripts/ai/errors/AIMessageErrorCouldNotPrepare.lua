AIMessageErrorCouldNotPrepare = {}
local AIMessageErrorCouldNotPrepare_mt = Class(AIMessageErrorCouldNotPrepare, AIMessage)

function AIMessageErrorCouldNotPrepare.new(vehicle, customMt)
	local self = AIMessage.new(customMt or AIMessageErrorCouldNotPrepare_mt)
	self.vehicle = vehicle

	return self
end

function AIMessageErrorCouldNotPrepare:getMessage()
	return g_i18n:getText("ai_messageErrorCouldNotPrepare")
end

function AIMessage:getMessageArguments()
	if self.vehicle ~= nil then
		return self.vehicle:getName()
	end

	return nil
end

function AIMessageErrorCouldNotPrepare:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
end

function AIMessageErrorCouldNotPrepare:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
end
