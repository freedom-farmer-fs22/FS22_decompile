StartSleepStateEvent = {}
local StartSleepStateEvent_mt = Class(StartSleepStateEvent, Event)

InitStaticEventClass(StartSleepStateEvent, "StartSleepStateEvent", EventIds.EVENT_SLEEP_START)

function StartSleepStateEvent.emptyNew()
	local self = Event.new(StartSleepStateEvent_mt)

	return self
end

function StartSleepStateEvent.new(targetTime)
	local self = StartSleepStateEvent.emptyNew()
	self.targetTime = targetTime

	return self
end

function StartSleepStateEvent:readStream(streamId, connection)
	self.targetTime = streamReadInt32(streamId)

	self:run(connection)
end

function StartSleepStateEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.targetTime)
end

function StartSleepStateEvent:run(connection)
	if g_sleepManager ~= nil then
		g_sleepManager:startSleep(self.targetTime, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(StartSleepStateEvent.new(self.targetTime), false, connection)
	end
end

function StartSleepStateEvent.sendEvent(targetTime, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_currentMission:getIsServer() then
			g_server:broadcastEvent(StartSleepStateEvent.new(targetTime), false)
		else
			g_client:getServerConnection():sendEvent(StartSleepStateEvent.new(targetTime))
		end
	end
end
