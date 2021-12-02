FogStateEvent = {
	SEND_BITS_FOG_STATE = 6,
	SEND_BITS_FOG_FACTOR = 3,
	SEND_BITS_FOG_DURATION = 4
}
local FogStateEvent_mt = Class(FogStateEvent, Event)

InitStaticEventClass(FogStateEvent, "FogStateEvent", EventIds.EVENT_FOG_STATE_EVENT)

function FogStateEvent.emptyNew()
	return Event.new(FogStateEvent_mt)
end

function FogStateEvent.new(targetValue, lastMieScale, alpha, duration, nightFactor, dayFactor)
	local self = FogStateEvent.emptyNew()
	self.targetValue = targetValue
	self.lastMieScale = lastMieScale
	self.alpha = alpha
	self.duration = duration
	self.nightFactor = nightFactor
	self.dayFactor = dayFactor

	return self
end

function FogStateEvent:readStream(streamId, connection)
	self.targetValue = streamReadUIntN(streamId, FogStateEvent.SEND_BITS_FOG_STATE) * 1 / (math.pow(2, FogStateEvent.SEND_BITS_FOG_STATE) - 1) * 200
	self.lastMieScale = streamReadUIntN(streamId, FogStateEvent.SEND_BITS_FOG_STATE) * 1 / (math.pow(2, FogStateEvent.SEND_BITS_FOG_STATE) - 1) * 200
	self.alpha = streamReadUIntN(streamId, FogStateEvent.SEND_BITS_FOG_STATE) * 1 / (math.pow(2, FogStateEvent.SEND_BITS_FOG_STATE) - 1)
	self.duration = streamReadUIntN(streamId, FogStateEvent.SEND_BITS_FOG_DURATION)
	self.nightFactor = streamReadUIntN(streamId, FogStateEvent.SEND_BITS_FOG_FACTOR) * 0.25
	self.dayFactor = streamReadUIntN(streamId, FogStateEvent.SEND_BITS_FOG_FACTOR) * 0.25

	self:run(connection)
end

function FogStateEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.targetValue / 200 / (1 / (math.pow(2, FogStateEvent.SEND_BITS_FOG_STATE) - 1)), FogStateEvent.SEND_BITS_FOG_STATE)
	streamWriteUIntN(streamId, self.lastMieScale / 200 / (1 / (math.pow(2, FogStateEvent.SEND_BITS_FOG_STATE) - 1)), FogStateEvent.SEND_BITS_FOG_STATE)
	streamWriteUIntN(streamId, self.alpha / (1 / (math.pow(2, FogStateEvent.SEND_BITS_FOG_STATE) - 1)), FogStateEvent.SEND_BITS_FOG_STATE)
	streamWriteUIntN(streamId, MathUtil.msToHours(self.duration), FogStateEvent.SEND_BITS_FOG_DURATION)
	streamWriteUIntN(streamId, self.nightFactor / 0.25, FogStateEvent.SEND_BITS_FOG_FACTOR)
	streamWriteUIntN(streamId, self.dayFactor / 0.25, FogStateEvent.SEND_BITS_FOG_FACTOR)
end

function FogStateEvent:run(connection)
	g_currentMission.environment.weather.fogUpdater:setTargetValues(self.targetValue, MathUtil.hoursToMs(self.duration))

	g_currentMission.environment.weather.fogUpdater.lastMieScale = self.lastMieScale
	g_currentMission.environment.weather.fogUpdater.alpha = self.alpha - 0.001
	g_currentMission.environment.weather.nightFactor = self.nightFactor
	g_currentMission.environment.weather.dayFactor = self.dayFactor
end
