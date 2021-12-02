SleepResponseEvent = {}
local SleepResponseEvent_mt = Class(SleepResponseEvent, Event)

InitStaticEventClass(SleepResponseEvent, "SleepResponseEvent", EventIds.EVENT_SLEEP_RESPONSE)

function SleepResponseEvent.emptyNew()
	local self = Event.new(SleepResponseEvent_mt)

	return self
end

function SleepResponseEvent.new(userId, answer)
	local self = SleepResponseEvent.emptyNew()
	self.userId = userId
	self.answer = answer

	return self
end

function SleepResponseEvent:readStream(streamId, connection)
	self.userId = streamReadInt8(streamId)
	self.answer = streamReadBool(streamId)

	self:run(connection)
end

function SleepResponseEvent:writeStream(streamId, connection)
	streamWriteInt8(streamId, self.userId)
	streamWriteBool(streamId, self.answer)
end

function SleepResponseEvent:run(connection)
	if g_sleepManager ~= nil then
		g_sleepManager:sleepResponse(self.userId, self.answer)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(SleepResponseEvent.new(self.userId, self.answer), false)
	end
end

function SleepResponseEvent.sendEvent(userId, answer, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_currentMission:getIsServer() then
			g_server:broadcastEvent(SleepResponseEvent.new(userId, answer), false)
		else
			g_client:getServerConnection():sendEvent(SleepResponseEvent.new(userId, answer))
		end
	end
end
