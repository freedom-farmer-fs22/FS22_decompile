EnvironmentTimeEvent = {}
local EnvironmentTimeEvent_mt = Class(EnvironmentTimeEvent, Event)

InitStaticEventClass(EnvironmentTimeEvent, "EnvironmentTimeEvent", EventIds.EVENT_ENVIRONMENT_TIME)

function EnvironmentTimeEvent.emptyNew()
	return Event.new(EnvironmentTimeEvent_mt, NetworkNode.CHANNEL_SECONDARY)
end

function EnvironmentTimeEvent.new(newMonotonicDay, currentDay, dayTime, daysPerPeriod)
	local self = EnvironmentTimeEvent.emptyNew()
	self.newMonotonicDay = newMonotonicDay
	self.currentDay = currentDay
	self.dayTime = dayTime
	self.daysPerPeriod = daysPerPeriod

	return self
end

function EnvironmentTimeEvent:readStream(streamId, connection)
	self.currentDay = streamReadInt32(streamId, 9)
	self.daysPerPeriod = streamReadUIntN(streamId, 5)
	self.newMonotonicDay = streamReadInt32(streamId)
	self.dayTime = streamReadFloat32(streamId)

	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		g_currentMission.environment:setEnvironmentTime(self.newMonotonicDay, self.currentDay, self.dayTime, self.daysPerPeriod, false)
	end
end

function EnvironmentTimeEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.currentDay, 9)
	streamWriteUIntN(streamId, self.daysPerPeriod, 5)
	streamWriteInt32(streamId, self.newMonotonicDay)
	streamWriteFloat32(streamId, self.dayTime)
end

function EnvironmentTimeEvent:run(connection)
	print("The server should not receive a dayTime update")
end

function EnvironmentTimeEvent.broadcastEvent()
	local env = g_currentMission.environment
	local event = EnvironmentTimeEvent.new(env.currentMonotonicDay, env.currentDay, env.dayTime, env.daysPerPeriod)

	g_server:broadcastEvent(event)
end
