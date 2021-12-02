PlayerRequestStyleEvent = {}
local PlayerRequestStyleEvent_mt = Class(PlayerRequestStyleEvent, Event)

InitStaticEventClass(PlayerRequestStyleEvent, "PlayerRequestStyleEvent", EventIds.EVENT_PLAYER_REQUEST_STYLE)

function PlayerRequestStyleEvent.emptyNew()
	local self = Event.new(PlayerRequestStyleEvent_mt)

	return self
end

function PlayerRequestStyleEvent.new(playerObjectId)
	local self = PlayerRequestStyleEvent.emptyNew()
	self.playerObjectId = playerObjectId

	return self
end

function PlayerRequestStyleEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObjectId(streamId, self.playerObjectId)
end

function PlayerRequestStyleEvent:readStream(streamId, connection)
	self.playerObjectId = NetworkUtil.readNodeObjectId(streamId)
	self.player = NetworkUtil.getObject(self.playerObjectId)

	self:run(connection)
end

function PlayerRequestStyleEvent:run(connection)
	if not connection:getIsServer() then
		local style = g_currentMission.playerInfoStorage:getPlayerStyle(self.player.userId)

		connection:sendEvent(PlayerSetStyleEvent.new(self.player, style))
	end
end
