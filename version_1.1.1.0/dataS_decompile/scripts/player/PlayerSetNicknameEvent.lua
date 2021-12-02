PlayerSetNicknameEvent = {}
local PlayerSetNicknameEvent_mt = Class(PlayerSetNicknameEvent, Event)

InitStaticEventClass(PlayerSetNicknameEvent, "PlayerSetNicknameEvent", EventIds.EVENT_PLAYER_SET_NICKNAME)

function PlayerSetNicknameEvent.emptyNew()
	local self = Event.new(PlayerSetNicknameEvent_mt)

	return self
end

function PlayerSetNicknameEvent.new(player, nickname, userId)
	local self = PlayerSetNicknameEvent.emptyNew()
	self.player = player
	self.nickname = nickname
	self.userId = userId

	return self
end

function PlayerSetNicknameEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteString(streamId, self.nickname)
	NetworkUtil.writeNodeObjectId(streamId, self.userId)
end

function PlayerSetNicknameEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.nickname = streamReadString(streamId)
	self.userId = NetworkUtil.readNodeObjectId(streamId)

	self:run(connection)
end

function PlayerSetNicknameEvent:run(connection)
	if not connection:getIsServer() then
		g_currentMission:setPlayerNickname(self.player, self.nickname, self.userId)
	else
		g_currentMission:setPlayerNickname(self.player, self.nickname, self.userId, true)
	end
end
