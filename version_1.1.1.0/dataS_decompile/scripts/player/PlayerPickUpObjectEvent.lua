PlayerPickUpObjectEvent = {}
local PlayerPickUpObjectEvent_mt = Class(PlayerPickUpObjectEvent, Event)

InitStaticEventClass(PlayerPickUpObjectEvent, "PlayerPickUpObjectEvent", EventIds.EVENT_PLAYER_PICKUP_OBJECT)

function PlayerPickUpObjectEvent.emptyNew()
	local self = Event.new(PlayerPickUpObjectEvent_mt)

	return self
end

function PlayerPickUpObjectEvent.new(player, state)
	local self = PlayerPickUpObjectEvent.emptyNew()
	self.player = player
	self.state = state

	return self
end

function PlayerPickUpObjectEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)

	self:run(connection)
end

function PlayerPickUpObjectEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteBool(streamId, self.state)
end

function PlayerPickUpObjectEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.player)
	end

	self.player:pickUpObject(self.state, true)
end

function PlayerPickUpObjectEvent.sendEvent(player, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlayerPickUpObjectEvent.new(player, state), nil, , player)
		else
			g_client:getServerConnection():sendEvent(PlayerPickUpObjectEvent.new(player, state))
		end
	end
end
