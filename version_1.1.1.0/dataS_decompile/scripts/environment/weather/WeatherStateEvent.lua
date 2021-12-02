WeatherStateEvent = {}
local WeatherInitEvent_mt = Class(WeatherStateEvent, Event)

InitStaticEventClass(WeatherStateEvent, "WeatherStateEvent", EventIds.EVENT_WEATHER_STATE)

function WeatherStateEvent.emptyNew()
	return Event.new(WeatherInitEvent_mt, NetworkNode.CHANNEL_SECONDARY)
end

function WeatherStateEvent.new(snowHeight, timeSinceLastRain)
	local self = WeatherStateEvent.emptyNew()
	self.snowHeight = snowHeight
	self.timeSinceLastRain = timeSinceLastRain

	return self
end

function WeatherStateEvent:readStream(streamId, connection)
	self.snowHeight = streamReadFloat32(streamId)
	self.timeSinceLastRain = streamReadFloat32(streamId)

	self:run(connection)
end

function WeatherStateEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.snowHeight)
	streamWriteFloat32(streamId, self.timeSinceLastRain)
end

function WeatherStateEvent:run(connection)
	g_currentMission.environment.weather:setInitialState(self.snowHeight, self.timeSinceLastRain)
end
