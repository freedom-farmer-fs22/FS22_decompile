PlayerSetStyleEvent = {}
local PlayerSetStyleEvent_mt = Class(PlayerSetStyleEvent, Event)

InitStaticEventClass(PlayerSetStyleEvent, "PlayerSetStyleEvent", EventIds.EVENT_PLAYER_SET_STYLE)

function PlayerSetStyleEvent.emptyNew()
	local self = Event.new(PlayerSetStyleEvent_mt)

	return self
end

function PlayerSetStyleEvent.new(player, style)
	local self = PlayerSetStyleEvent.emptyNew()
	self.player = player
	self.style = style

	return self
end

function PlayerSetStyleEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	self.style:writeStream(streamId, connection)
end

function PlayerSetStyleEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.style = PlayerStyle.new()

	self.style:readStream(streamId, connection)
	self:run(connection)
end

function PlayerSetStyleEvent:run(connection)
	if not connection:getIsServer() then
		self.player:setStyleAsync(self.style, nil, false)
	else
		self.player:setStyleAsync(self.style, nil, true)
	end
end

function PlayerSetStyleEvent.sendEvent(player, style, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlayerSetStyleEvent.new(player, style), nil, , player)
		else
			g_client:getServerConnection():sendEvent(PlayerSetStyleEvent.new(player, style))
		end
	end
end
