WeatherInstance = {}
local WeatherInstance_mt = Class(WeatherInstance)
WeatherInstance.HOURTIME = 3600000
WeatherInstance.MINUTETIME = 60000

function WeatherInstance.new(customMt)
	local self = setmetatable({}, customMt or WeatherInstance_mt)
	self.objectIndex = nil
	self.variationIndex = nil
	self.startDay = 0
	self.startDayTime = 0
	self.duration = 0
	self.season = 0

	return self
end

function WeatherInstance.createInstance(objectIndex, variationIndex, startDay, startDayTime, duration, season)
	startDayTime = math.floor(startDayTime / WeatherInstance.MINUTETIME) * WeatherInstance.MINUTETIME
	local weatherInstance = WeatherInstance.new()
	weatherInstance.objectIndex = objectIndex
	weatherInstance.variationIndex = variationIndex
	weatherInstance.startDay = startDay
	weatherInstance.startDayTime = startDayTime
	weatherInstance.duration = duration
	weatherInstance.season = season

	return weatherInstance
end
