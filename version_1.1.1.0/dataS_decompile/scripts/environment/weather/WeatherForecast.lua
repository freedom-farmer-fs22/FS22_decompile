WeatherForecast = {
	TYPE = {
		MIXED = 3,
		HAIL = 7,
		SNOW = 6,
		THUNDER = 9,
		RAIN = 5,
		FOG = 8,
		CLEAR = 1,
		WINDY = 4,
		CLOUDY = 2
	},
	DAY_LENGTH = 86400000,
	CURVE_TOP_TIME = 0.64788735773,
	CURVE_BOTTOM_TIME = 0.14788735773,
	CLOUD_THRESHOLD = 0.5
}
local WeatherForecast_mt = Class(WeatherForecast)

function WeatherForecast.new(owner, customMt)
	local self = setmetatable({}, customMt or WeatherForecast_mt)
	self.owner = owner

	return self
end

function WeatherForecast:load()
	self.weatherTypeToForecastType = {
		[WeatherType.SUN] = WeatherForecast.TYPE.CLEAR,
		[WeatherType.RAIN] = WeatherForecast.TYPE.RAIN,
		[WeatherType.CLOUDY] = WeatherForecast.TYPE.CLOUDY,
		[WeatherType.SNOW] = WeatherForecast.TYPE.SNOW
	}
end

function WeatherForecast:delete()
	self.owner = nil
end

function WeatherForecast:getCurrentWeather()
	local weatherType = self.owner:getWeatherTypeAtTime(self.owner.owner.currentMonotonicDay, self.owner.owner.dayTime)
	local forecastType = self.weatherTypeToForecastType[weatherType]
	local windX, windZ, windSpeed = self.owner.windUpdater:getCurrentValues()
	local windAngle = math.deg(MathUtil.getYRotationFromDirection(windX, windZ))
	windAngle = MathUtil.round(windAngle / 45) * 45

	return {
		temperature = self.owner:getCurrentTemperature(),
		windDirection = windAngle,
		windSpeed = windSpeed,
		forecastType = forecastType
	}
end

function WeatherForecast:dataForTime(day, time)
	for _, item in ipairs(self.owner.forecastItems) do
		if item.startDay == day and item.startDayTime <= time and time <= item.startDayTime + item.duration or item.startDay < day and time <= item.startDayTime + item.duration - WeatherForecast.DAY_LENGTH then
			return self.owner:getForecastInstanceVariation(item), item
		end
	end

	return nil
end

function WeatherForecast:getHourlyForecast(hoursFromNow)
	local time = self.owner.owner.dayTime + hoursFromNow * 60 * 60 * 1000
	local day = self.owner.owner.currentMonotonicDay

	if WeatherForecast.DAY_LENGTH < time then
		time = time - WeatherForecast.DAY_LENGTH
		day = day + 1
	end

	local instance, forecastItem = self:dataForTime(day, time)

	if instance == nil then
		return nil
	end

	local startDayTime = time / WeatherForecast.DAY_LENGTH
	local finishDayTime = (time + 3600000) / WeatherForecast.DAY_LENGTH
	local maxTemp = -math.huge

	if startDayTime <= WeatherForecast.CURVE_BOTTOM_TIME and WeatherForecast.CURVE_BOTTOM_TIME <= finishDayTime then
		maxTemp = math.max(maxTemp, self:getTemperatureAtTimeForCurve(WeatherForecast.CURVE_BOTTOM_TIME, instance.minTemperature, instance.maxTemperature))
	elseif startDayTime <= WeatherForecast.CURVE_TOP_TIME and WeatherForecast.CURVE_TOP_TIME <= finishDayTime then
		maxTemp = math.max(maxTemp, self:getTemperatureAtTimeForCurve(WeatherForecast.CURVE_TOP_TIME, instance.minTemperature, instance.maxTemperature))
	end

	maxTemp = math.max(maxTemp, self:getTemperatureAtTimeForCurve(startDayTime, instance.minTemperature, instance.maxTemperature))
	maxTemp = math.max(maxTemp, self:getTemperatureAtTimeForCurve(finishDayTime, instance.minTemperature, instance.maxTemperature))
	local object = self.owner:getWeatherObjectByIndex(forecastItem.season, forecastItem.objectIndex)
	local forecastType = self.weatherTypeToForecastType[object.weatherType.index]
	local windSpeed = 0
	local windDirection = 0
	local variation = object:getVariationByIndex(forecastItem.variationIndex)

	if variation.wind ~= nil then
		windSpeed = variation.wind.windVelocity
		windDirection = variation.wind.windAngle
	end

	return {
		time = time,
		day = day,
		temperature = maxTemp,
		windSpeed = windSpeed,
		windDirection = windDirection,
		forecastType = forecastType
	}
end

function WeatherForecast:getDailyForecast(daysFromToday)
	local day = self.owner.owner.currentMonotonicDay + daysFromToday
	local instances = {}
	local minTemp = math.huge
	local maxTemp = -math.huge
	local forecastType = WeatherForecast.TYPE.CLEAR
	local hasSunInForecast = false
	local windSpeed = 0
	local windDirection = 0
	local uncertaintyFactor = math.pow(1.025, daysFromToday - 1)
	local uncertaintySign = 1

	for _, item in ipairs(self.owner.forecastItems) do
		if item.startDay == day or item.startDay == day - 1 and WeatherForecast.DAY_LENGTH < item.startDayTime + item.duration then
			local instance = self.owner:getForecastInstanceVariation(item)

			table.insert(instances, instance)

			local uFactor = uncertaintyFactor

			if uncertaintySign == -1 then
				uFactor = 1 / uFactor
			end

			local start, finish = nil

			if item.startDay == day then
				start = 0
			else
				start = (WeatherForecast.DAY_LENGTH - item.startDayTime) / item.duration
			end

			local endDayTime = item.startDayTime + item.duration

			if WeatherForecast.DAY_LENGTH < item.startDayTime + item.duration and item.startDay == day - 1 then
				finish = 1
			elseif endDayTime <= WeatherForecast.DAY_LENGTH then
				finish = 1
			else
				finish = 1 - (endDayTime - WeatherForecast.DAY_LENGTH) / item.duration
			end

			local startDayTime = (item.startDayTime + item.duration * start) / WeatherForecast.DAY_LENGTH % 1
			local finishDayTime = (item.startDayTime + item.duration * finish) / WeatherForecast.DAY_LENGTH

			if startDayTime <= WeatherForecast.CURVE_BOTTOM_TIME and WeatherForecast.CURVE_BOTTOM_TIME <= finishDayTime then
				minTemp = math.min(minTemp, self:getTemperatureAtTimeForCurve(WeatherForecast.CURVE_BOTTOM_TIME, instance.minTemperature, instance.maxTemperature) / uFactor)
			end

			if startDayTime <= WeatherForecast.CURVE_TOP_TIME and WeatherForecast.CURVE_TOP_TIME <= finishDayTime then
				maxTemp = math.max(maxTemp, self:getTemperatureAtTimeForCurve(WeatherForecast.CURVE_TOP_TIME, instance.minTemperature, instance.maxTemperature) * uFactor)
			end

			local object = self.owner:getWeatherObjectByIndex(item.season, item.objectIndex)
			local weatherType = object.weatherType.index

			if weatherType == WeatherType.SUN then
				hasSunInForecast = true

				if forecastType == WeatherForecast.TYPE.CLOUDY then
					forecastType = WeatherForecast.TYPE.MIXED
				end
			elseif false and forecastType < WeatherForecast.TYPE.WINDY then
				forecastType = WeatherForecast.TYPE.WINDY
			elseif forecastType < WeatherForecast.TYPE.CLOUDY and weatherType == WeatherType.CLOUDY then
				if hasSunInForecast then
					forecastType = WeatherForecast.TYPE.MIXED
				else
					forecastType = WeatherForecast.TYPE.CLOUDY
				end
			elseif weatherType == WeatherType.RAIN then
				forecastType = WeatherForecast.TYPE.RAIN
			elseif weatherType == WeatherType.SNOW then
				forecastType = WeatherForecast.TYPE.SNOW
			end

			local variation = object:getVariationByIndex(item.variationIndex)

			if variation.wind ~= nil then
				windSpeed = math.max(windSpeed, variation.wind.windVelocity * uFactor)
				windDirection = (windDirection * (#instances - 1) + variation.wind.windAngle) / #instances
			end

			uncertaintySign = -1 * uncertaintySign
		end
	end

	windDirection = MathUtil.round(windDirection / 45) * 45

	return {
		day = day,
		highTemperature = maxTemp,
		lowTemperature = minTemp,
		windSpeed = windSpeed,
		windDirection = windDirection,
		forecastType = forecastType
	}
end

function WeatherForecast:getTemperatureAtTimeForCurve(t, curveMin, curveMax)
	local T = 2 * math.pi * t
	local d = curveMax - curveMin
	local dh = 0.5 * d

	return dh * math.sin(T - 2.5) + curveMin + dh
end
