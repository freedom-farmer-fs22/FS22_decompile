WeatherAddObjectEvent = {}
local WeatherInitEvent_mt = Class(WeatherAddObjectEvent, Event)

InitStaticEventClass(WeatherAddObjectEvent, "WeatherAddObjectEvent", EventIds.EVENT_WEATHER_ADD_OBJECT)

function WeatherAddObjectEvent.emptyNew()
	return Event.new(WeatherInitEvent_mt, NetworkNode.CHANNEL_SECONDARY)
end

function WeatherAddObjectEvent.new(instances, isInitialSync)
	local self = WeatherAddObjectEvent.emptyNew()
	self.instances = instances
	self.isInitialSync = isInitialSync

	return self
end

function WeatherAddObjectEvent:readStream(streamId, connection)
	self.instances = {}
	self.isInitialSync = streamReadBool(streamId)
	local numStates = streamReadUIntN(streamId, Weather.SEND_BITS_NUM_OBJECTS)

	for _ = 1, numStates do
		local objectIndex = streamReadUIntN(streamId, Weather.SEND_BITS_OBJECT_INDEX) + 1
		local variationIndex = streamReadUIntN(streamId, Weather.SEND_BITS_OBJECT_VARIATION_INDEX) + 1
		local startDay = streamReadInt32(streamId)
		local startDayTime = streamReadUIntN(streamId, Weather.SEND_BITS_STARTTIME) * 60 * 1000
		local duration = (streamReadUIntN(streamId, Weather.SEND_BITS_DURATION) + 1) * 60 * 60 * 1000
		local season = streamReadUIntN(streamId, 2)
		local instance = WeatherInstance.createInstance(objectIndex, variationIndex, startDay, startDayTime, duration, season)

		table.insert(self.instances, instance)
	end

	self:run(connection)
end

function WeatherAddObjectEvent:writeStream(streamId, connection)
	streamWriteBool(streamId, self.isInitialSync)
	streamWriteUIntN(streamId, #self.instances, Weather.SEND_BITS_NUM_OBJECTS)

	for _, instance in ipairs(self.instances) do
		streamWriteUIntN(streamId, instance.objectIndex - 1, Weather.SEND_BITS_OBJECT_INDEX)
		streamWriteUIntN(streamId, instance.variationIndex - 1, Weather.SEND_BITS_OBJECT_VARIATION_INDEX)
		streamWriteInt32(streamId, instance.startDay)
		streamWriteUIntN(streamId, instance.startDayTime / 60000, Weather.SEND_BITS_STARTTIME)
		streamWriteUIntN(streamId, instance.duration / 3600000 - 1, Weather.SEND_BITS_DURATION)
		streamWriteUIntN(streamId, instance.season, 2)
	end
end

function WeatherAddObjectEvent:run(connection)
	if self.isInitialSync then
		g_currentMission.environment.weather.forecastItems = {}
	end

	for _, instance in ipairs(self.instances) do
		g_currentMission.environment.weather:addWeatherForecast(instance)
	end

	if self.isInitialSync then
		g_currentMission.environment.weather:init()
	end
end
