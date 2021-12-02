PlayerSetHandToolEvent = {}
local PlayerSetHandToolEvent_mt = Class(PlayerSetHandToolEvent, Event)

InitStaticEventClass(PlayerSetHandToolEvent, "PlayerSetHandToolEvent", EventIds.EVENT_PLAYER_SET_HANDTOOL)

function PlayerSetHandToolEvent.emptyNew()
	local self = Event.new(PlayerSetHandToolEvent_mt)

	return self
end

function PlayerSetHandToolEvent.new(player, handtoolFileName, force)
	local self = PlayerSetHandToolEvent.emptyNew()
	self.player = player
	self.handtoolFileName = handtoolFileName
	self.force = force

	return self
end

function PlayerSetHandToolEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.handtoolFileName = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	self.force = streamReadBool(streamId)

	self:run(connection)
end

function PlayerSetHandToolEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.handtoolFileName))
	streamWriteBool(streamId, self.force)
end

function PlayerSetHandToolEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.player)
	end

	self.player:equipHandtool(self.handtoolFileName, self.force, true)
end

function PlayerSetHandToolEvent.sendEvent(player, handtoolFileName, force, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlayerSetHandToolEvent.new(player, handtoolFileName, force), nil, , player)
		else
			g_client:getServerConnection():sendEvent(PlayerSetHandToolEvent.new(player, handtoolFileName, force))
		end
	end
end
