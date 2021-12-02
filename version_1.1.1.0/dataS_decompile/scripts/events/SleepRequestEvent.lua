SleepRequestEvent = {}
local SleepRequestEvent_mt = Class(SleepRequestEvent, Event)

InitStaticEventClass(SleepRequestEvent, "SleepRequestEvent", EventIds.EVENT_SLEEP_REQUEST)

function SleepRequestEvent.emptyNew()
	local self = Event.new(SleepRequestEvent_mt)

	return self
end

function SleepRequestEvent.new(userId)
	local self = SleepRequestEvent.emptyNew()
	self.userId = userId

	return self
end

function SleepRequestEvent:readStream(streamId, connection)
	self.userId = streamReadInt8(streamId)

	self:run(connection)
end

function SleepRequestEvent:writeStream(streamId, connection)
	streamWriteInt8(streamId, self.userId)
end

function SleepRequestEvent:run(connection)
	if g_sleepManager ~= nil then
		g_sleepManager:showSleepRequest(self.userId)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(SleepRequestEvent.new(self.userId), false)
	end
end

function SleepRequestEvent.sendEvent(userId, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_currentMission:getIsServer() then
			g_server:broadcastEvent(SleepRequestEvent.new(userId), false)
		else
			g_client:getServerConnection():sendEvent(SleepRequestEvent.new(userId))
		end
	end
end
