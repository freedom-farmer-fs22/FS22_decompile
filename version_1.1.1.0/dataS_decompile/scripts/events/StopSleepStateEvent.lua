StopSleepStateEvent = {}
local StopSleepStateEvent_mt = Class(StopSleepStateEvent, Event)

InitStaticEventClass(StopSleepStateEvent, "StopSleepStateEvent", EventIds.EVENT_SLEEP_STOP)

function StopSleepStateEvent.emptyNew()
	local self = Event.new(StopSleepStateEvent_mt)

	return self
end

function StopSleepStateEvent.new()
	local self = StopSleepStateEvent.emptyNew()

	return self
end

function StopSleepStateEvent:readStream(streamId, connection)
	self:run(connection)
end

function StopSleepStateEvent:writeStream(streamId, connection)
end

function StopSleepStateEvent:run(connection)
	if g_sleepManager ~= nil then
		g_sleepManager:stopSleep(true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(StopSleepStateEvent.new(), false)
	end
end

function StopSleepStateEvent.sendEvent(noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_currentMission:getIsServer() then
			g_server:broadcastEvent(StopSleepStateEvent.new(), false)
		else
			g_client:getServerConnection():sendEvent(StopSleepStateEvent.new())
		end
	end
end
