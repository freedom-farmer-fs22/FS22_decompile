GamePauseRequestEvent = {}
local GamePauseRequestEvent_mt = Class(GamePauseRequestEvent, Event)

InitStaticEventClass(GamePauseRequestEvent, "GamePauseRequestEvent", EventIds.EVENT_GAME_PAUSE_REQUEST)

function GamePauseRequestEvent.emptyNew()
	local self = Event.new(GamePauseRequestEvent_mt)

	return self
end

function GamePauseRequestEvent.new(pause)
	local self = GamePauseRequestEvent.emptyNew()
	self.pause = pause

	return self
end

function GamePauseRequestEvent:readStream(streamId, connection)
	self.pause = streamReadBool(streamId)

	self:run(connection)
end

function GamePauseRequestEvent:writeStream(streamId, connection)
	streamWriteBool(streamId, self.pause)
end

function GamePauseRequestEvent:run(connection)
	g_currentMission:setManualPause(self.pause)
end
