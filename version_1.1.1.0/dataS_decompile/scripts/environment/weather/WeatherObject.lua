WeatherObject = {}
local WeatherObject_mt = Class(WeatherObject)

function WeatherObject.new(weatherType, cloudUpdater, temperatureUpdater, windUpdater, customMt)
	local self = setmetatable({}, customMt or WeatherObject_mt)
	self.weatherType = weatherType
	self.temperatureUpdater = temperatureUpdater
	self.cloudUpdater = cloudUpdater
	self.windUpdater = windUpdater
	self.variations = {}
	self.weightedVariations = {}

	return self
end

function WeatherObject:load(xmlFile, key, cloudPresets)
	self.weight = xmlFile:getInt(key .. "#weight", 1)
	local maxVariations = 2^Weather.SEND_BITS_OBJECT_VARIATION_INDEX - 1

	xmlFile:iterate(key .. ".variation", function (_, variationKey)
		if maxVariations < #self.variations then
			Logging.xmlWarning(xmlFile, "Weather object variation limit (%d) readed at '%s'", maxVariations, variationKey)

			return false
		end

		local variation = {}

		if self:loadVariation(xmlFile, variationKey, variation, cloudPresets) then
			table.insert(self.variations, variation)

			variation.index = #self.variations

			for _ = 1, variation.weight do
				table.insert(self.weightedVariations, variation.index)
			end
		end

		return true
	end)

	return true
end

function WeatherObject:loadVariation(xmlFile, key, variation, cloudPresets)
	variation.weight = xmlFile:getInt(key .. "#weight", 1)
	variation.minHours = MathUtil.clamp(xmlFile:getInt(key .. "#minHours", 5), 1, 2^Weather.SEND_BITS_DURATION - 1)

	if variation.minHours < Weather.MIN_WEATHER_DURATION then
		Logging.xmlWarning(xmlFile, "MinHours needs to be greater than %.1f hours for variation '%s'!", Weather.MIN_WEATHER_DURATION, key)

		variation.minHours = Weather.MIN_WEATHER_DURATION
	end

	variation.maxHours = MathUtil.clamp(xmlFile:getInt(key .. "#maxHours", 10), 3, 2^Weather.SEND_BITS_DURATION - 1)

	if variation.maxHours < variation.minHours then
		Logging.xmlWarning(xmlFile, "MaxHours needs to be greater than minHours! for variation '%s'", key)

		variation.maxHours = variation.minHours
	end

	local minTemperature = xmlFile:getInt(key .. "#minTemperature", 15)
	local maxTemperature = xmlFile:getInt(key .. "#maxTemperature", 25)
	local maxSendTemp = 2^Weather.SEND_BITS_TEMPERATURE

	if minTemperature > maxSendTemp then
		minTemperature = maxSendTemp

		Logging.xmlWarning(xmlFile, "Min temperature is too high. Maximum is %d for variation '%s'", maxSendTemp, key)
	elseif maxSendTemp < maxTemperature then
		maxTemperature = maxSendTemp

		Logging.xmlWarning(xmlFile, "Max temperature is too high. Maximum is %d for variation '%s'", maxSendTemp, key)
	end

	if maxTemperature < minTemperature then
		local minCopy = minTemperature
		minTemperature = maxTemperature
		maxTemperature = minCopy
	end

	variation.minTemperature = minTemperature
	variation.maxTemperature = maxTemperature
	local cloudKey = key .. ".clouds"
	local presetId = xmlFile:getString(cloudKey .. "#presetId")

	if presetId == nil then
		Logging.xmlWarning(xmlFile, "Missing clouds presetId for '%s'", cloudKey)

		return false
	end

	presetId = string.upper(presetId)

	if cloudPresets == nil then
		printCallstack()
	end

	if cloudPresets[presetId] == nil then
		Logging.xmlWarning(xmlFile, "Clouds presetId '%s' is not defined for '%s'", presetId, cloudKey)

		return false
	end

	variation.clouds = table.copy(cloudPresets[presetId], math.huge)
	local windObject = WindObject.new()

	if windObject:load(xmlFile, key .. ".wind") then
		variation.wind = windObject
	else
		windObject:delete()
	end

	return true
end

function WeatherObject:getRandomVariationIndex()
	return self.weightedVariations[math.random(1, #self.weightedVariations)]
end

function WeatherObject:getVariationByIndex(index)
	if index == nil then
		return nil
	end

	return self.variations[index]
end

function WeatherObject:delete()
end

function WeatherObject:update(dt)
end

function WeatherObject:activate(variationIndex, duration)
	local variation = self.variations[variationIndex]
	local clouds = self.variations[variationIndex].clouds
	local wind = self.variations[variationIndex].wind

	self.cloudUpdater:setTargetClouds(clouds, duration)
	self.temperatureUpdater:setTargetValues(variation.minTemperature, variation.maxTemperature, duration == 0)

	if wind ~= nil then
		self.windUpdater:setTargetValues(wind.windDirectionX, wind.windDirectionZ, wind.windVelocity, wind.cirrusSpeedFactor, duration)
	end
end

function WeatherObject:deactivate(duration)
end
