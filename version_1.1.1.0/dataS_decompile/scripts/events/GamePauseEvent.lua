GamePauseEvent = {}
local GamePauseEvent_mt = Class(GamePauseEvent, Event)

InitStaticEventClass(GamePauseEvent, "GamePauseEvent", EventIds.EVENT_GAME_PAUSE)

function GamePauseEvent.emptyNew()
	local self = Event.new(GamePauseEvent_mt)

	return self
end

function GamePauseEvent.new(pause, manualPaused, isSynchronizing)
	local self = GamePauseEvent.emptyNew()
	self.pause = pause
	self.manualPaused = manualPaused
	self.isSynchronizing = isSynchronizing

	return self
end

function GamePauseEvent:readStream(streamId, connection)
	self.pause = streamReadBool(streamId)
	self.manualPaused = streamReadBool(streamId)
	self.isSynchronizing = streamReadBool(streamId)

	self:run(connection)
end

function GamePauseEvent:writeStream(streamId, connection)
	streamWriteBool(streamId, self.pause)
	streamWriteBool(streamId, self.manualPaused)
	streamWriteBool(streamId, self.isSynchronizing)
end

function GamePauseEvent:run(connection)
	g_currentMission.manualPaused = self.manualPaused
	g_currentMission.isSynchronizingWithPlayers = self.isSynchronizing

	if self.pause then
		g_currentMission:pauseGame()
	else
		g_currentMission:doUnpauseGame()
	end
end

function GamePauseEvent.sendEvent()
	if g_currentMission:getIsServer() then
		g_server:broadcastEvent(GamePauseEvent.new(g_currentMission.paused, g_currentMission.manualPaused, g_currentMission.isSynchronizingWithPlayers), false)
	end
end
