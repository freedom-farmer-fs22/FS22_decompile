AIMessage = {}
local AIMessage_mt = Class(AIMessage)

function AIMessage.new(customMt)
	local self = setmetatable({}, customMt or AIMessage_mt)

	return self
end

function AIMessage:getMessage()
	return ""
end

function AIMessage:getMessageArguments()
end

function AIMessage:getType()
	return AIMessageType.ERROR
end

function AIMessage:readStream(streamId, connection)
end

function AIMessage:writeStream(streamId, connection)
end
