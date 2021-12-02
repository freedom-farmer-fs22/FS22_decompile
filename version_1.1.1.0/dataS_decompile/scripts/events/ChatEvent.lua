ChatEvent = {}
local ChatEvent_mt = Class(ChatEvent, Event)

InitStaticEventClass(ChatEvent, "ChatEvent", EventIds.EVENT_CHAT)

function ChatEvent.emptyNew()
	local self = Event.new(ChatEvent_mt, NetworkNode.CHANNEL_CHAT)

	return self
end

function ChatEvent.new(msg, sender, farmId, userId)
	local self = ChatEvent.emptyNew()

	assert(msg ~= nil and sender ~= nil, "ChatEvent msg and sender not valid")

	self.msg = filterText(msg, false, false)
	self.sender = sender
	self.farmId = farmId
	self.userId = userId

	return self
end

function ChatEvent:readStream(streamId, connection)
	self.msg = streamReadString(streamId)
	self.sender = streamReadString(streamId)
	self.userId = NetworkUtil.readNodeObjectId(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	self:run(connection)
end

function ChatEvent:writeStream(streamId, connection)
	streamWriteString(streamId, self.msg)
	streamWriteString(streamId, self.sender)
	NetworkUtil.writeNodeObjectId(streamId, self.userId)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function ChatEvent:run(connection)
	g_currentMission:addChatMessage(self.sender, self.msg, self.farmId, self.userId)

	if not connection:getIsServer() then
		local fromUser = g_currentMission.userManager:getUserByUserId(self.userId)

		for _, toUser in ipairs(g_currentMission.userManager:getUsers()) do
			if connection ~= toUser:getConnection() and not toUser:getIsBlockedBy(fromUser) and not toUser:getConnection():getIsLocal() then
				toUser:getConnection():sendEvent(self, false, force)
			end
		end
	end
end
