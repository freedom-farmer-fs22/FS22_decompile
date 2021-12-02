UserBlockEvent = {}
local UserBlockEvent_mt = Class(UserBlockEvent, Event)

InitStaticEventClass(UserBlockEvent, "UserBlockEvent", EventIds.EVENT_USER_BLOCK)

function UserBlockEvent.emptyNew()
	local self = Event.new(UserBlockEvent_mt)

	return self
end

function UserBlockEvent.new(userId, isBlocked)
	local self = UserBlockEvent.emptyNew()
	self.userId = userId
	self.isBlocked = isBlocked

	return self
end

function UserBlockEvent:readStream(streamId, connection)
	self.userId = NetworkUtil.readNodeObjectId(streamId)
	self.isBlocked = streamReadBool(streamId)

	self:run(connection)
end

function UserBlockEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObjectId(streamId, self.userId)
	streamWriteBool(streamId, self.isBlocked)
end

function UserBlockEvent:run(connection)
	if not connection:getIsServer() then
		local fromUser = g_currentMission.userManager:getUserByConnection(connection)
		local toUser = g_currentMission.userManager:getUserByUserId(self.userId)

		toUser:setIsBlockedBy(fromUser, self.isBlocked)
	end
end

function UserBlockEvent.sendEvent(userId, isBlocked, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server == nil then
			g_client:getServerConnection():sendEvent(UserBlockEvent.new(userId, isBlocked))
		end
	end
end
