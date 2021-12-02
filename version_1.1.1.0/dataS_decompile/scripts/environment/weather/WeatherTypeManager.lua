WeatherType = nil
WeatherTypeManager = {}
local WeatherTypeManager_mt = Class(WeatherTypeManager, AbstractManager)

function WeatherTypeManager.new(customMt)
	return AbstractManager.new(customMt or WeatherTypeManager_mt)
end

function WeatherTypeManager:initDataStructures()
	self.weatherTypes = {}
	self.nameToIndex = {}
	self.indexToName = {}

	self:loadDefaultTypes()

	WeatherType = self.nameToIndex
end

function WeatherTypeManager:loadDefaultTypes()
	self:addWeatherType("SUN")
	self:addWeatherType("CLOUDY")
	self:addWeatherType("RAIN")
	self:addWeatherType("SNOW")
end

function WeatherTypeManager:addWeatherType(name)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a weather type. Ignoring it!")

		return nil
	end

	name = name:upper()
	local weatherType = {
		index = #self.weatherTypes + 1,
		name = name
	}

	table.insert(self.weatherTypes, weatherType)

	self.nameToIndex[name] = weatherType.index
	self.indexToName[weatherType.index] = name

	return weatherType
end

function WeatherTypeManager:getWeatherTypes()
	return self.weatherTypes
end

function WeatherTypeManager:getWeatherTypeIndexByName(name)
	if name ~= nil and ClassUtil.getIsValidIndexName(name) then
		name = name:upper()

		return self.nameToIndex[name]
	end

	return nil
end

function WeatherTypeManager:getWeatherTypeByName(name)
	if name ~= nil and ClassUtil.getIsValidIndexName(name) then
		name = name:upper()
		local index = self.nameToIndex[name]

		if index ~= nil then
			return self.weatherTypes[index]
		end
	end

	return nil
end

function WeatherTypeManager:getWeatherTypeByIndex(index)
	if index ~= nil then
		return self.weatherTypes[index]
	end

	return nil
end

function WeatherTypeManager:getWeatherTypeNameByIndex(index)
	if index ~= nil then
		return self.indexToName[index]
	end

	return nil
end

g_weatherTypeManager = WeatherTypeManager.new()
