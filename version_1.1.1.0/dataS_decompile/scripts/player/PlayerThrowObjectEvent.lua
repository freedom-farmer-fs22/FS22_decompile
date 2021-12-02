PlayerThrowObjectEvent = {}
local PlayerThrowObjectEvent_mt = Class(PlayerThrowObjectEvent, Event)

InitStaticEventClass(PlayerThrowObjectEvent, "PlayerThrowObjectEvent", EventIds.EVENT_PLAYER_THROW_OBJECT)

function PlayerThrowObjectEvent.emptyNew()
	local self = Event.new(PlayerThrowObjectEvent_mt)

	return self
end

function PlayerThrowObjectEvent.new(player)
	local self = PlayerThrowObjectEvent.emptyNew()
	self.player = player

	return self
end

function PlayerThrowObjectEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function PlayerThrowObjectEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
end

function PlayerThrowObjectEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.player)
	end

	self.player:throwObject(true)
end

function PlayerThrowObjectEvent.sendEvent(player, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlayerThrowObjectEvent.new(player), nil, , player)
		else
			g_client:getServerConnection():sendEvent(PlayerThrowObjectEvent.new(player))
		end
	end
end
