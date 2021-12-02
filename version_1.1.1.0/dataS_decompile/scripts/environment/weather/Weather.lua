Weather = {
	DEBUG_ENABLED = false,
	TEMPERATURE_STABLE_CHANGE = 2,
	SEND_BITS_NUM_OBJECTS = 8,
	SEND_BITS_OBJECT_INDEX = 5,
	SEND_BITS_OBJECT_VARIATION_INDEX = 4,
	SEND_BITS_WIND_INDEX = 4,
	SEND_BITS_TEMPERATURE = 6,
	SEND_BITS_DURATION = 6,
	SEND_BITS_STARTTIME = 11,
	CHANGE_DURATION = 1800000,
	MIN_WEATHER_DURATION = 1
}
local Weather_mt = Class(Weather)

function Weather.new(owner, customMt)
	local self = setmetatable({}, customMt or Weather_mt)
	self.owner = owner
	self.isRainAllowed = false
	self.typeToWeatherObject = {}
	self.weatherObjects = {}
	self.weightedWeatherObjects = {}
	self.forecastItems = {}
	self.cloudUpdater = CloudUpdater.new()
	self.temperatureUpdater = TemperatureUpdater.new()
	self.fogUpdater = FogUpdater.new()

	if getCloudQuality() == 0 then
		self.skyBoxUpdater = SkyBoxUpdater.new()
	end

	self.windUpdater = WindUpdater.new()

	self.windUpdater:addWindChangedListener(self.cloudUpdater)

	self.forecast = WeatherForecast.new(self)
	self.timeSinceLastRain = 9999999
	self.snowHeight = 0
	self.fog = {
		height = 200,
		minMieScale = 1,
		maxMieScale = 100,
		rainMieScale = 100,
		startHour = 4,
		endHour = 10,
		fadeOut = 4,
		fadeIn = 2,
		nightFactor = 0,
		dayFactor = 0
	}
	self.temperatureDebugGraph = Graph.new(24, 0.58, 0.5, 0.4, 0.4, 0, 40, true, "°", Graph.STYLE_LINES)

	self.temperatureDebugGraph:setColor(1, 0, 0, 1)
	self.temperatureDebugGraph:setBackgroundColor(0, 0, 0, 0.6)
	self.temperatureDebugGraph:setHorizontalLine(5, true, 1, 1, 1, 0.4)
	self.temperatureDebugGraph:setVerticalLine(6, true, 1, 1, 1, 0.3)

	self.temperatureDebugOverlayCurrent = createImageOverlay("dataS/scripts/shared/graph_pixel.png")

	setOverlayColor(self.temperatureDebugOverlayCurrent, 0, 1, 0, 1)
	addConsoleCommand("gsWeatherDebug", "Toggles weather debug", "consoleCommandWeatherToggleDebug", self)

	if not g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission:getIsServer() then
		addConsoleCommand("gsWeatherReload", "Reloads weather data", "consoleCommandWeatherReloadData", self)
		addConsoleCommand("gsWeatherSet", "Sets a weather object by type", "consoleCommandWeatherSet", self)
		addConsoleCommand("gsWeatherAdd", "Adds a weather object by type", "consoleCommandWeatherAdd", self)
		addConsoleCommand("gsWeatherSetFog", "Sets fog height, mieScale and duration", "consoleCommandWeatherSetFog", self)
		addConsoleCommand("gsWeatherSetDebugWind", "Sets wind data", "consoleCommandWeatherSetDebugWind", self)
		addConsoleCommand("gsWeatherSetClouds", "Sets cloud data", "consoleCommandWeatherSetClouds", self)
		addConsoleCommand("gsWeatherToggleRandomWindWaving", "Toggles waving of random wind", "consoleCommandWeatherToggleRandomWindWaving", self)
	end

	return self
end

function Weather:load(xmlFile, key)
	self.forecastItems = {}
	self.weatherObjects = {}
	self.weightedWeatherObjects = {}
	local cloudPresets = {}

	self:loadCloudPresets(xmlFile, key .. ".weather.cloudPresets", cloudPresets)

	self.envMapCloudProbes = {}

	xmlFile:iterate(key .. ".weather.envMap.cloudProbe", function (_, cloudProbeKey)
		local presetId = xmlFile:getString(cloudProbeKey .. "#presetId")

		if presetId == nil then
			Logging.xmlWarning(xmlFile, "Missing clouds presetId for '%s'", cloudProbeKey)

			return false
		end

		presetId = string.upper(presetId)

		if cloudPresets[presetId] == nil then
			Logging.xmlWarning(xmlFile, "Clouds presetId '%s' is not defined for '%s'", presetId, cloudProbeKey)

			return false
		end

		if #self.envMapCloudProbes == 3 then
			Logging.xmlWarning(xmlFile, "Only 3 different envmap types are supported for '%s'", presetId, cloudProbeKey)

			return false
		end

		local cloudCopy = table.copy(cloudPresets[presetId], math.huge)

		table.insert(self.envMapCloudProbes, cloudCopy)
	end)

	if #self.envMapCloudProbes == 0 then
		Logging.xmlWarning(xmlFile, "No env map cloud probes defined. Adding first cloud preset")

		local _, preset = next(cloudPresets)
		local cloudCopy = table.copy(preset, math.huge)

		table.insert(self.envMapCloudProbes, cloudCopy)
	end

	for _, preset in pairs(cloudPresets) do
		if self.envMapCloudProbes[preset.envMapCloudProbeIndex] == nil then
			Logging.xmlWarning(xmlFile, "Invalid envMapCloudProbeIndex for cloud preset '%s'. Using 1 instead", preset.id)

			preset.envMapCloudProbeIndex = 1
		end
	end

	local maxObjects = 2^Weather.SEND_BITS_OBJECT_INDEX - 1

	for season = 0, 3 do
		self.weatherObjects[season] = {}
		self.weightedWeatherObjects[season] = {}
		self.typeToWeatherObject[season] = {}
		local numAdded = self:loadWeatherObjects(xmlFile, string.format("%s.weather.season(%d)", key, season), maxObjects, cloudPresets)
		maxObjects = maxObjects - numAdded
	end

	self.firstWeatherType = self.firstWeatherType or WeatherType.SUN or WeatherType.CLOUDY or WeatherType.RAIN
	self.fog.height = xmlFile:getFloat(key .. ".weather.fog#height", self.fog.height)

	if self.fog.height < 200 then
		self.fog.height = 200

		Logging.xmlWarning(xmlFile, "Fog height may not be smaller than 200 for '%s'!", key .. ".weather.fog#height")
	end

	self.fog.minMieScale = xmlFile:getFloat(key .. ".weather.fog#minMieScale", self.fog.minMieScale)

	if self.fog.minMieScale < 1 then
		self.fog.minMieScale = 1

		Logging.xmlWarning(xmlFile, "Fog minMieScale may not be smaller than 1 for '%s'!", key .. ".weather.fog#minMieScale")
	end

	self.fog.maxMieScale = xmlFile:getFloat(key .. ".weather.fog#maxMieScale", self.fog.maxMieScale)

	if self.fog.maxMieScale < 1 then
		self.fog.maxMieScale = 1

		Logging.xmlWarning(xmlFile, "Fog maxMieScale may not be smaller than 1 for '%s'!", key .. ".weather.fog#maxMieScale")
	end

	if self.fog.maxMieScale < self.fog.minMieScale then
		local oldMin = self.fog.minMieScale
		self.fog.minMieScale = self.fog.maxMieScale
		self.fog.maxMieScale = oldMin

		Logging.xmlWarning(xmlFile, "Fog maxMieScale has to be greater than minMieScale for '%s'!", key .. ".weather.fog#maxMieScale")
	end

	self.fog.startHour = xmlFile:getFloat(key .. ".weather.fog#startHour", self.fog.startHour)
	self.fog.endHour = xmlFile:getFloat(key .. ".weather.fog#endHour", self.fog.endHour)
	self.fog.fadeIn = xmlFile:getFloat(key .. ".weather.fog#fadeIn", self.fog.fadeIn)
	self.fog.fadeOut = xmlFile:getFloat(key .. ".weather.fog#fadeOut", self.fog.fadeOut)
	self.fog.rainMieScale = xmlFile:getFloat(key .. ".weather.fog#rainMieScale", self.fog.rainMieScale)

	self.fogUpdater:setHeight(self.fog.height)
	self.fogUpdater:setTargetValues(self.fog.minMieScale, 0)

	if self.skyBoxUpdater ~= nil then
		self.skyBoxUpdater:load(xmlFile, key .. ".skyBox")
	end

	if g_server ~= nil then
		self:addStartWeather()
		self:fillWeatherForecast()
		self:init()
	end

	self.forecast:load()
	self.temperatureUpdater:setDayLength(self.owner.dayLength)
	g_messageCenter:unsubscribeAll(self)
	g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)
	g_messageCenter:subscribe(MessageType.TIMESCALE_CHANGED, self.onTimeScaleChanged, self)
	g_messageCenter:subscribe(MessageType.PERIOD_LENGTH_CHANGED, self.onPeriodLengthChanged, self)
end

function Weather:loadCloudPresets(xmlFile, key, cloudPresets)
	xmlFile:iterate(key .. ".cloudPreset", function (_, presetKey)
		local id = xmlFile:getString(presetKey .. "#id")

		if id == nil then
			Logging.xmlWarning(xmlFile, "Missing cloud preset id for '%s'", presetKey)

			return
		end

		id = string.upper(id)

		if cloudPresets[id] ~= nil then
			Logging.xmlWarning(xmlFile, "Cloud preset id '%s' already exists for '%s'", id, presetKey)

			return
		end

		local cloudPreset = {
			id = id,
			type = xmlFile:getInt(presetKey .. ".cloudType#type"),
			cloudBaseShapeTiling = xmlFile:getInt(presetKey .. ".cloudType#cloudBaseShapeTiling", 2500),
			cloudErosionTiling = xmlFile:getInt(presetKey .. ".cloudType#cloudErosionTiling", 2500),
			precipitation = xmlFile:getFloat(presetKey .. ".cloudType#precipitation"),
			lightDamping = xmlFile:getFloat(presetKey .. ".scatteringLightSourceDamping#damping"),
			combinedNoiseEdge0 = xmlFile:getFloat(presetKey .. ".globalCoverage.combinedNoise#edge0"),
			combinedNoiseEdge1 = xmlFile:getFloat(presetKey .. ".globalCoverage.combinedNoise#edge1"),
			noise0Weight = xmlFile:getFloat(presetKey .. ".globalCoverage.noise0#weight"),
			noise0Edge0 = xmlFile:getFloat(presetKey .. ".globalCoverage.noise0#edge0"),
			noise0Edge1 = xmlFile:getFloat(presetKey .. ".globalCoverage.noise0#edge1"),
			noise1Weight = xmlFile:getFloat(presetKey .. ".globalCoverage.noise1#weight"),
			noise1Edge0 = xmlFile:getFloat(presetKey .. ".globalCoverage.noise1#edge0"),
			noise1Edge1 = xmlFile:getFloat(presetKey .. ".globalCoverage.noise1#edge1"),
			noise2Weight = xmlFile:getFloat(presetKey .. ".globalCoverage.noise2#weight"),
			noise2Edge0 = xmlFile:getFloat(presetKey .. ".globalCoverage.noise2#edge0"),
			noise2Edge1 = xmlFile:getFloat(presetKey .. ".globalCoverage.noise2#edge1"),
			erosionWeight = xmlFile:getFloat(presetKey .. ".globalCoverage.erosionWeight#weight"),
			cirrusCoverage = xmlFile:getFloat(presetKey .. ".cirrusCoverage#weight"),
			envMapCloudProbeIndex = xmlFile:getInt(presetKey .. "#envMapCloudProbeIndex") or 1
		}
		cloudPresets[id] = cloudPreset
	end)
end

function Weather:loadWeatherObjects(xmlFile, key, maxObjects, cloudPresets)
	local seasonName = xmlFile:getString(key .. "#name")

	if seasonName == nil then
		Logging.warning("No season name given in '%s'", key)
	end

	local season = Environment.getSeasonFromString(seasonName)
	local weatherObjects = self.weatherObjects[season]
	local weightedWeatherObjects = self.weightedWeatherObjects[season]
	local typeToWeatherObject = self.typeToWeatherObject[season]
	local numAdded = 0

	xmlFile:iterate(key .. ".object", function (_, objectKey)
		if maxObjects < #weatherObjects then
			Logging.warning("Weather object limit (%d) reached at '%s'", maxObjects, objectKey)

			return false
		end

		local typeName = xmlFile:getString(objectKey .. "#typeName")
		local weatherType = g_weatherTypeManager:getWeatherTypeByName(typeName)

		if weatherType ~= nil then
			if self.isRainAllowed or weatherType.index ~= WeatherType.RAIN and weatherType.index ~= WeatherType.SNOW then
				if typeToWeatherObject[weatherType.index] == nil then
					local className = xmlFile:getString(objectKey .. "#class")
					local classObject = ClassUtil.getClassObject(className)

					if classObject ~= nil then
						if classObject:isa(WeatherObject) then
							local instance = classObject.new(weatherType, self.cloudUpdater, self.temperatureUpdater, self.windUpdater)

							if instance:load(xmlFile, objectKey, cloudPresets) then
								if xmlFile:getBool(objectKey .. "#isFirstWeather") then
									self.firstWeatherType = weatherType
								end

								table.insert(weatherObjects, instance)

								instance.index = #weatherObjects
								instance.season = season
								typeToWeatherObject[weatherType.index] = instance

								for _ = 1, instance.weight do
									table.insert(weightedWeatherObjects, instance.index)
								end

								numAdded = numAdded + 1
							end
						else
							Logging.xmlWarning(xmlFile, "Given class '%s' is not a WeatherObject in '%s'", tostring(className), objectKey)
						end
					else
						Logging.xmlWarning(xmlFile, "Class '%s' not found in '%s'", tostring(className), objectKey)
					end
				else
					Logging.xmlWarning(xmlFile, "WeatherObject for type '%s' already defined in '%s'", typeName, objectKey)
				end
			end
		else
			Logging.xmlWarning(xmlFile, "Invalid weather type '%s' in '%s'", typeName, objectKey)
		end

		return true
	end)

	return numAdded
end

function Weather:delete()
	removeConsoleCommand("gsWeatherSet")
	removeConsoleCommand("gsWeatherAdd")
	removeConsoleCommand("gsWeatherDebug")
	removeConsoleCommand("gsWeatherSetWindState")
	removeConsoleCommand("gsWeatherSetFog")
	removeConsoleCommand("gsWeatherReload")
	removeConsoleCommand("gsWeatherSetDebugWind")
	removeConsoleCommand("gsWeatherSetClouds")
	removeConsoleCommand("gsWeatherToggleRandomWindWaving")
	delete(self.temperatureDebugOverlayCurrent)
	self.temperatureDebugGraph:delete()
	self.windUpdater:removeWindChangedListener(self.cloudUpdater)

	for season = 0, 3 do
		local objs = self.weatherObjects[season]

		for i = 1, #objs do
			objs[i]:delete()
		end
	end

	self.weatherObjects = {}

	if self.skyBoxUpdater ~= nil then
		self.skyBoxUpdater:delete()
	end

	self.forecast:delete()
	g_messageCenter:unsubscribeAll(self)
end

function Weather:saveToXMLFile(xmlFile, key)
	for k, instance in ipairs(self.forecastItems) do
		local instanceKey = string.format("%s.forecast.instance(%d)", key, k - 1)

		if k == 1 then
			local durationLeft = nil
			local nextInstance = instance

			if self.forecastItems[2] ~= nil then
				nextInstance = self.forecastItems[2]
			end

			local currentDay = self.owner.currentMonotonicDay

			if currentDay < nextInstance.startDay then
				currentDay = currentDay + 1
				durationLeft = 86400000 - self.owner.dayTime
				durationLeft = durationLeft + math.max(0, nextInstance.startDay - currentDay - 1) * 24 * 60 * 60 * 1000
				durationLeft = durationLeft + nextInstance.startDayTime
			else
				durationLeft = nextInstance.startDayTime - self.owner.dayTime
			end

			setXMLFloat(xmlFile, instanceKey .. "#durationLeft", durationLeft / 3600000)
		end

		local weatherObject = self:getWeatherObjectByIndex(instance.season, instance.objectIndex)

		setXMLString(xmlFile, instanceKey .. "#typeName", weatherObject.weatherType.name)
		setXMLInt(xmlFile, instanceKey .. "#variationIndex", instance.variationIndex)
		setXMLFloat(xmlFile, instanceKey .. "#duration", instance.duration / 3600000)
		setXMLInt(xmlFile, instanceKey .. "#season", instance.season)
	end

	self.fogUpdater:saveToXMLFile(xmlFile, key .. ".fog")
	setXMLFloat(xmlFile, key .. ".fog#nightFactor", self.fog.nightFactor)
	setXMLFloat(xmlFile, key .. ".fog#dayFactor", self.fog.dayFactor)
	setXMLFloat(xmlFile, key .. ".snow#height", self.snowHeight)
	setXMLInt(xmlFile, key .. "#timeSinceLastRain", MathUtil.msToMinutes(self.timeSinceLastRain))
end

function Weather:loadFromXMLFile(xmlFile, key)
	local currentInstance = self.forecastItems[1]
	local currentWeatherObject = self:getWeatherObjectByIndex(currentInstance.season, currentInstance.objectIndex)

	currentWeatherObject:deactivate(1)

	self.forecastItems = {}
	local i = 0
	local startDay = self.owner.currentMonotonicDay
	local startDayTime = self.owner.dayTime

	while true do
		local instanceKey = string.format("%s.forecast.instance(%d)", key, i)

		if not hasXMLProperty(xmlFile, instanceKey) then
			break
		end

		local typeName = getXMLString(xmlFile, instanceKey .. "#typeName")
		local season = Utils.getNoNil(getXMLInt(xmlFile, instanceKey .. "#season"), Environment.SEASON.SUMMER)
		local weatherType = g_weatherTypeManager:getWeatherTypeByName(typeName)

		if weatherType ~= nil and self.typeToWeatherObject[season][weatherType.index] ~= nil then
			local weatherObject = self.typeToWeatherObject[season][weatherType.index]
			local weatherObjectIndex = weatherObject.index
			local weatherObjectVariationIndex = getXMLInt(xmlFile, instanceKey .. "#variationIndex")
			local variation = weatherObject:getVariationByIndex(weatherObjectVariationIndex)

			if variation ~= nil then
				local duration = math.max(variation.minHours, getXMLFloat(xmlFile, instanceKey .. "#duration") or 1) * 3600000
				local durationLeft = getXMLFloat(xmlFile, instanceKey .. "#durationLeft")

				if durationLeft ~= nil then
					startDayTime = startDayTime - (duration - durationLeft * 60 * 60 * 1000)

					if startDayTime < 0 then
						startDay = startDay - 1
						startDayTime = startDayTime + 86400000
					end
				end

				local instance = WeatherInstance.createInstance(weatherObjectIndex, weatherObjectVariationIndex, startDay, startDayTime, duration, season)

				self:addWeatherForecast(instance)

				startDay, startDayTime = self.owner:getDayAndDayTime(startDayTime + duration, startDay)
			else
				Logging.warning("Failed to load forecast instance. WeatherObject variationIndex '%s' not defined!", tostring(weatherObjectVariationIndex))
			end
		else
			Logging.warning("Failed to load forecast instance. WeatherObject '%s' not defined!", tostring(typeName))
		end

		i = i + 1
	end

	self.fogUpdater:loadFromXMLFile(xmlFile, key .. ".fog")

	self.fog.nightFactor = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".fog#nightFactor"), 0)
	self.fog.dayFactor = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".fog#dayFactor"), 0)
	self.timeSinceLastRain = MathUtil.minutesToMs(Utils.getNoNil(getXMLInt(xmlFile, key .. "#timeSinceLastRain"), 0)) or self.timeSinceLastRain
	self.snowHeight = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".snow#height"), self.snowHeight)

	self:fillWeatherForecast()
	self.cloudUpdater:setTimeScale(g_currentMission:getEffectiveTimeScale())
	self:init()
end

function Weather:update(dt)
	local scaledDt = dt * g_currentMission:getEffectiveTimeScale()

	if #self.forecastItems >= 2 then
		local nextInstance = self.forecastItems[2]
		local currentInstance = self.forecastItems[1]
		local currentWeatherObject = self:getWeatherObjectByIndex(currentInstance.season, currentInstance.objectIndex)

		if nextInstance.startDay < self.owner.currentMonotonicDay or self.owner.currentMonotonicDay == nextInstance.startDay and nextInstance.startDayTime < self.owner.dayTime then
			local duration = Weather.CHANGE_DURATION

			currentWeatherObject:deactivate(duration)

			local nextWeatherObject = self:getWeatherObjectByIndex(nextInstance.season, nextInstance.objectIndex)

			nextWeatherObject:activate(nextInstance.variationIndex, duration)

			if nextWeatherObject.setWindValues ~= nil then
				local windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor = self.windUpdater:getCurrentValues()

				nextWeatherObject:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
			end

			if nextWeatherObject.weatherType.index == WeatherType.RAIN or nextWeatherObject.weatherType.index == WeatherType.SNOW then
				self:toggleFog(true, MathUtil.hoursToMs(0.5), self.fog.rainMieScale)
			elseif nextWeatherObject.weatherType.index == WeatherType.SUN then
				self:toggleFog(false, MathUtil.hoursToMs(0.5))
			end

			self.owner:onWeatherChanged(nextWeatherObject)
			table.remove(self.forecastItems, 1)

			if g_server ~= nil then
				self:fillWeatherForecast()
			end
		end

		if currentWeatherObject.weatherType.index ~= WeatherType.RAIN and currentWeatherObject.weatherType.index ~= WeatherType.SNOW then
			self.timeSinceLastRain = self.timeSinceLastRain + dt * g_currentMission:getEffectiveTimeScale()
		else
			self.timeSinceLastRain = 0
		end
	elseif g_server ~= nil then
		self:fillWeatherForecast()
	end

	for season = 0, 3 do
		local objs = self.weatherObjects[season]

		for i = 1, #objs do
			objs[i]:update(scaledDt)
		end
	end

	self.cloudUpdater:update(scaledDt)
	self.temperatureUpdater:update(scaledDt)
	self.windUpdater:update(scaledDt)
	self.fogUpdater:update(scaledDt)

	if self.skyBoxUpdater ~= nil then
		self.skyBoxUpdater:update(scaledDt, self.owner.dayTime, self:getRainFallScale(), self:getTimeUntilRain())
	end

	local currentTemperature = self.temperatureUpdater:getTemperatureAtTime(self.owner.dayTime)
	local oldHeight = self.snowHeight
	local timeScale = g_currentMission.missionInfo.timeScale

	if not g_currentMission.missionInfo.isSnowEnabled then
		self.snowHeight = math.max(self.snowHeight - 0.005 * dt / 1000 * timeScale / 100, 0)
	elseif self:getIsRaining() and currentTemperature < 0 then
		self.snowHeight = MathUtil.clamp(self.snowHeight + 0.0003 * dt / 1000 * timeScale / 100 * self:getRainFallScale(), 0, 0.5)
	elseif currentTemperature >= 5 then
		self.snowHeight = 0
	elseif currentTemperature > 0 and self.snowHeight > 0 then
		local rainFactor = self:getIsRaining() and 3 or 1
		self.snowHeight = MathUtil.clamp(self.snowHeight - currentTemperature * 0.0005 * dt / 1000 * timeScale / 100 * rainFactor, 0, 0.5)
	end

	if oldHeight ~= self.snowHeight then
		if self.snowHeight == 0 then
			g_currentMission.snowSystem:removeAll()
		else
			g_currentMission.snowSystem:setSnowHeight(self.snowHeight)
		end
	end
end

function Weather:draw()
	if Weather.DEBUG_ENABLED then
		local data = {}
		local currentMin, currentMax = self.temperatureUpdater:getCurrentValues(self.owner.dayTime)
		local current = self.temperatureUpdater:getTemperatureAtTime(self.owner.dayTime)

		table.insert(data, {
			value = "",
			name = "TEMPERATURE"
		})
		table.insert(data, {
			name = "current",
			value = string.format("%.2f°", current)
		})
		table.insert(data, {
			name = "currentMin",
			value = string.format("%.2f°", currentMin)
		})
		table.insert(data, {
			name = "currentMax",
			value = string.format("%.2f°", currentMax)
		})
		table.insert(data, {
			value = "",
			name = ""
		})
		table.insert(data, {
			value = "",
			name = "SNOW"
		})
		table.insert(data, {
			name = "height",
			value = string.format("%.5f", self.snowHeight)
		})
		table.insert(data, {
			value = "",
			name = ""
		})

		local windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor = self.windUpdater:getCurrentValues()

		table.insert(data, {
			value = "",
			name = "WIND"
		})
		table.insert(data, {
			name = "dirX",
			value = string.format("%.3f", windDirX)
		})
		table.insert(data, {
			name = "dirZ",
			value = string.format("%.3f", windDirZ)
		})
		table.insert(data, {
			name = "velocity",
			value = MathUtil.mpsToKmh(windVelocity)
		})
		table.insert(data, {
			name = "cirrusSpeedFactor",
			value = cirrusCloudSpeedFactor
		})
		table.insert(data, {
			value = "",
			name = ""
		})
		table.insert(data, {
			value = "",
			name = "RAIN"
		})
		table.insert(data, {
			name = "timeSince",
			value = string.format("%.2f", self:getTimeSinceLastRain())
		})
		table.insert(data, {
			name = "rainFallScale",
			value = string.format("%.2f", self:getRainFallScale())
		})
		table.insert(data, {
			value = "",
			name = "",
			columnOffset = 0.12
		})

		local mieScale = self.fogUpdater:getCurrentValues()
		local height = self.fogUpdater:getHeight()

		table.insert(data, {
			value = "",
			name = "FOG"
		})
		table.insert(data, {
			name = "height",
			value = string.format("%.1f", height)
		})
		table.insert(data, {
			name = "mieScale",
			value = string.format("%.3f", mieScale)
		})
		table.insert(data, {
			name = "nightFactor",
			value = string.format("%.2f", self.fog.nightFactor)
		})
		table.insert(data, {
			name = "dayFactor",
			value = string.format("%.2f", self.fog.dayFactor)
		})
		table.insert(data, {
			value = "",
			name = ""
		})

		local cloudData = self.cloudUpdater:getCurrentValues()

		table.insert(data, {
			value = "",
			name = "Clouds"
		})
		table.insert(data, {
			name = "Type",
			value = string.format("%.2f", cloudData.type)
		})
		table.insert(data, {
			name = "Precipitation",
			value = string.format("%.3f", cloudData.precipitation)
		})
		table.insert(data, {
			name = "CloudBaseShapeTiling",
			value = string.format("%.3f", cloudData.cloudBaseShapeTiling)
		})
		table.insert(data, {
			name = "CloudErosionTiling",
			value = string.format("%.3f", cloudData.cloudErosionTiling)
		})
		table.insert(data, {
			name = "CombinedNoiseEdge0",
			value = string.format("%.3f", cloudData.combinedNoiseEdge0)
		})
		table.insert(data, {
			name = "CombinedNoiseEdge1",
			value = string.format("%.3f", cloudData.combinedNoiseEdge1)
		})
		table.insert(data, {
			name = "Noise0Weight",
			value = string.format("%.3f", cloudData.noise0Weight)
		})
		table.insert(data, {
			name = "Noise0Edge0",
			value = string.format("%.3f", cloudData.noise0Edge0)
		})
		table.insert(data, {
			name = "Noise0Edge1",
			value = string.format("%.3f", cloudData.noise0Edge1)
		})
		table.insert(data, {
			name = "Noise1Weight",
			value = string.format("%.3f", cloudData.noise1Weight)
		})
		table.insert(data, {
			name = "Noise1Edge0",
			value = string.format("%.3f", cloudData.noise1Edge0)
		})
		table.insert(data, {
			name = "Noise1Edge1",
			value = string.format("%.3f", cloudData.noise1Edge1)
		})
		table.insert(data, {
			name = "Noise2Weight",
			value = string.format("%.3f", cloudData.noise2Weight)
		})
		table.insert(data, {
			name = "Noise2Edge0",
			value = string.format("%.3f", cloudData.noise2Edge0)
		})
		table.insert(data, {
			name = "Noise2Edge1",
			value = string.format("%.3f", cloudData.noise2Edge1)
		})
		table.insert(data, {
			name = "ErosionWeight",
			value = string.format("%.3f", cloudData.erosionWeight)
		})
		table.insert(data, {
			name = "CirrusCoverage",
			value = string.format("%.3f", cloudData.cirrusCoverage)
		})
		table.insert(data, {
			name = "LightDamping",
			value = string.format("%.3f", cloudData.lightDamping)
		})
		table.insert(data, {
			name = "EnvMapIndex",
			value = string.format("%d", cloudData.envMapCloudProbeIndex)
		})
		table.insert(data, {
			value = "",
			name = ""
		})

		if self.skyBoxUpdater ~= nil then
			self.skyBoxUpdater:addDebugValues(data)
		end

		table.insert(data, {
			value = "",
			name = "",
			columnOffset = 0.12
		})

		for k, instance in ipairs(self.forecastItems) do
			local dayDif = instance.startDay - self.owner.currentMonotonicDay
			local text = string.format("Var %d | Active | Duration %d | Season %d", instance.variationIndex, instance.duration / 3600000, instance.season)

			if k > 1 then
				if dayDif == 0 then
					text = string.format("Var %d | In %d minutes | Duration %d | Season %d", instance.variationIndex, (instance.startDayTime - self.owner.dayTime) / 60000, instance.duration / 3600000, instance.season)
				else
					text = string.format("Var %d | In %d days | Duration %d | Season %d", instance.variationIndex, dayDif, instance.duration / 3600000, instance.season)
				end
			end

			local weatherObject = self:getWeatherObjectByIndex(instance.season, instance.objectIndex)

			table.insert(data, {
				name = weatherObject.weatherType.name,
				value = text
			})
		end

		DebugUtil.renderTable(0.61, 0.46, 0.011, data)

		local graph = self.temperatureDebugGraph

		for h = 1, 24 do
			local temperature = self.temperatureUpdater:getTemperatureAtTime(h * 60 * 60 * 1000)

			graph:setValue(h, temperature)
		end

		graph:draw()

		local factor = self.owner.dayTime / self.owner.dayLength

		renderOverlay(self.temperatureDebugOverlayCurrent, graph.left + factor * graph.width, graph.bottom, 1 / g_screenWidth, graph.height)
	end
end

function Weather:sendInitialState(connection)
	connection:sendEvent(WeatherStateEvent.new(self.snowHeight, self.timeSinceLastRain))
end

function Weather:setInitialState(snowHeight, timeSinceLastRain)
	self.snowHeight = snowHeight
	self.timeSinceLastRain = timeSinceLastRain

	g_currentMission.snowSystem:setSnowHeight(self.snowHeight)
end

function Weather:setIsRainAllowed(isRainAllowed)
	self.isRainAllowed = isRainAllowed
end

function Weather:init()
	local currentInstance = self.forecastItems[1]
	local weatherObject = self:getWeatherObjectByIndex(currentInstance.season, currentInstance.objectIndex)

	weatherObject:activate(currentInstance.variationIndex, 0)

	if weatherObject.setWindValues ~= nil then
		local windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor = self.windUpdater:getCurrentValues()

		weatherObject:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
	end

	self.owner:onWeatherChanged(weatherObject)
	g_currentMission.snowSystem:setSnowHeight(self.snowHeight)
end

function Weather:rebuild()
	if g_currentMission:getIsServer() then
		self.forecastItems = {}

		self:addStartWeather()
		self:fillWeatherForecast()
		g_server:broadcastEvent(WeatherAddObjectEvent.new(self.forecastItems, true))
		g_server:broadcastEvent(FogStateEvent.new(self.fogUpdater.targetMieScale, self.fogUpdater.lastMieScale, self.fogUpdater.alpha, self.fogUpdater.duration, self.fog.nightFactor, self.fog.dayFactor))
	end
end

function Weather:getRandomWeatherObjectVariation(season, firstWeather)
	local weatherObject = self.typeToWeatherObject[season][self.firstWeatherType]

	if weatherObject == nil or not firstWeather then
		local weatherObjectIndex = self.weightedWeatherObjects[season][math.random(1, #self.weightedWeatherObjects[season])]
		weatherObject = self.weatherObjects[season][weatherObjectIndex]
	end

	local weatherObjectVariationIndex = weatherObject:getRandomVariationIndex()

	return weatherObject.index, weatherObjectVariationIndex
end

function Weather:getWeatherObjectByIndex(season, index)
	return self.weatherObjects[season][index]
end

function Weather:getForecastInstanceVariation(instance)
	return self.weatherObjects[instance.season][instance.objectIndex]:getVariationByIndex(instance.variationIndex)
end

function Weather:addStartWeather()
	local startDay = self.owner.currentMonotonicDay
	local startDayTime = self.owner.dayTime
	local endDay, endDayTime = self.owner:getDayAndDayTime(startDayTime, startDay)
	local season = self.owner:getVisualSeasonAtDay(startDay)
	local weatherInstance = self:createRandomWeatherInstance(season, endDay, endDayTime, true)

	self:addWeatherForecast(weatherInstance)
end

function Weather:fillWeatherForecast()
	local newObjects = {}
	local lastItem = self.forecastItems[#self.forecastItems]
	local maxNumOfforecastItemsItems = 2^Weather.SEND_BITS_NUM_OBJECTS - 1

	while (lastItem == nil or lastItem.startDay < self.owner.currentMonotonicDay + 8) and maxNumOfforecastItemsItems > #self.forecastItems do
		local startDay = self.owner.currentMonotonicDay
		local startDayTime = self.owner.dayTime

		if lastItem ~= nil then
			startDay = lastItem.startDay
			startDayTime = lastItem.startDayTime + lastItem.duration
		end

		local endDay, endDayTime = self.owner:getDayAndDayTime(startDayTime, startDay)
		local season = self.owner:getVisualSeasonAtDay(endDay)
		local weatherInstance = self:createRandomWeatherInstance(season, endDay, endDayTime, false)

		self:addWeatherForecast(weatherInstance)
		table.insert(newObjects, weatherInstance)

		lastItem = self.forecastItems[#self.forecastItems]
	end

	if #newObjects > 0 then
		g_server:broadcastEvent(WeatherAddObjectEvent.new(newObjects, false))
	end
end

function Weather:createRandomWeatherInstance(season, startDay, startDayTime, firstWeather)
	local weatherObjectIndex, weatherObjectVariationIndex = self:getRandomWeatherObjectVariation(season, firstWeather)
	local weatherObject = self:getWeatherObjectByIndex(season, weatherObjectIndex)
	local variation = weatherObject:getVariationByIndex(weatherObjectVariationIndex)
	local duration = MathUtil.hoursToMs(math.max(math.random(variation.minHours, variation.maxHours), 1))
	local isSeasonBoundary = startDay % 3 == 0

	if isSeasonBoundary then
		local wholeDay = 86400000

		if wholeDay < startDayTime + duration then
			duration = wholeDay - startDayTime
		end

		local timeBeforeMidnight = wholeDay - startDayTime - duration

		if timeBeforeMidnight > 0 and timeBeforeMidnight < 3600000 then
			duration = wholeDay - startDayTime
		end
	end

	return WeatherInstance.createInstance(weatherObjectIndex, weatherObjectVariationIndex, startDay, startDayTime, duration, season)
end

function Weather:addWeatherForecast(weatherInstance)
	table.insert(self.forecastItems, weatherInstance)
end

function Weather:getIsReady()
	return #self.forecastItems > 0
end

function Weather:onTimeScaleChanged()
	self.cloudUpdater:setTimeScale(g_currentMission:getEffectiveTimeScale())
end

function Weather:toggleFog(active, duration, mieScale)
	if active then
		local scale = MathUtil.clamp((self.fog.nightFactor + self.fog.dayFactor) / 2, 0, 1)
		mieScale = mieScale or MathUtil.lerp(self.fog.minMieScale, self.fog.maxMieScale, scale)

		self.fogUpdater:setTargetValues(mieScale, duration)
	else
		self.fogUpdater:setTargetValues(self.fog.minMieScale, duration)
	end
end

function Weather:getForecast()
	return self.forecast
end

function Weather:getRainFallScale()
	local maxScale = 0

	for season = 0, 3 do
		local objs = self.weatherObjects[season]

		for i = 1, #objs do
			if objs[i].getRainFallScale ~= nil then
				maxScale = math.max(maxScale, objs[i]:getRainFallScale())
			end
		end
	end

	return maxScale
end

function Weather:getCloudEnvMapInfo()
	local cloudUpdater = self.cloudUpdater
	local cloudEnvMapIndex1 = cloudUpdater.lastClouds.envMapCloudProbeIndex
	local cloudEnvMapIndex2 = cloudUpdater.targetClouds.envMapCloudProbeIndex
	local alpha = cloudUpdater.alpha

	return cloudEnvMapIndex1, cloudEnvMapIndex2, alpha
end

function Weather:getTimeUntilRain()
	for k = 1, #self.forecastItems do
		local instance = self.forecastItems[k]
		local object = self:getWeatherObjectByIndex(instance.season, instance.objectIndex)

		if instance.startDay == self.owner.currentMonotonicDay and (object.weatherType.index == WeatherType.RAIN or object.weatherType.index == WeatherType.SNOW) and self.owner.dayTime < instance.startDayTime then
			return instance.startDayTime - self.owner.dayTime
		end
	end

	return math.huge
end

function Weather:getTimeSinceLastRain()
	return MathUtil.msToMinutes(self.timeSinceLastRain)
end

function Weather:getGroundWetness()
	local timeSinceLastRain = self:getTimeSinceLastRain()

	if timeSinceLastRain >= 30 then
		return 0
	end

	if self:getIsRaining() then
		return self:getRainFallScale()
	end

	return (30 - timeSinceLastRain) / 30 * 0.6
end

function Weather:getIsRaining()
	return self:getRainFallScale() > 0.05
end

function Weather:getWeatherTypeAtTime(day, dayTime)
	if g_client ~= nil and #self.forecastItems == 0 then
		return WeatherType.SUN
	end

	local instance = self.forecastItems[1]

	for _, object in ipairs(self.forecastItems) do
		if object.startDay < day or object.startDay == day and object.startDayTime < dayTime then
			instance = object
		else
			break
		end
	end

	local object = self:getWeatherObjectByIndex(instance.season, instance.objectIndex)

	return object.weatherType.index
end

function Weather:getCurrentMinMaxTemperatures()
	return self.temperatureUpdater:getCurrentValues()
end

function Weather:getCurrentTemperature()
	return self.temperatureUpdater:getTemperatureAtTime(self.owner.dayTime)
end

function Weather:getCurrentTemperatureTrend()
	local currentVariation = self:getForecastInstanceVariation(self.forecastItems[1])
	local nextVariation = self:getForecastInstanceVariation(self.forecastItems[2])
	local avgCurrent = (currentVariation.minTemperature + currentVariation.maxTemperature) * 0.5
	local avgNext = (nextVariation.minTemperature + nextVariation.maxTemperature) * 0.5
	local change = avgCurrent - avgNext
	local trend = 0

	if Weather.TEMPERATURE_STABLE_CHANGE < math.abs(change) then
		trend = MathUtil.sign(change)
	end

	return trend
end

function Weather:getCurrentWeatherType()
	local instance = self.forecastItems[1]
	local object = self:getWeatherObjectByIndex(instance.season, instance.objectIndex)

	return object.weatherType.index
end

function Weather:getNextWeatherType(beforeDay, beforeTime)
	local instance = self.forecastItems[2]

	if beforeDay < instance.startDay or instance.startDay == beforeDay and beforeTime < instance.startDayTime then
		instance = self.forecastItems[1]
	end

	local object = self:getWeatherObjectByIndex(instance.season, instance.objectIndex)

	return object.weatherType.index
end

function Weather:onHourChanged()
	local currentHour = self.owner.currentHour
	local fog = self.fog

	if self.timeSinceLastRain ~= 0 then
		if currentHour == fog.startHour then
			self:toggleFog(true, MathUtil.hoursToMs(self.fog.fadeIn))
		elseif currentHour == fog.endHour then
			self:toggleFog(false, MathUtil.hoursToMs(self.fog.fadeOut))
		end
	end

	if #self.forecastItems > 0 then
		local season = self.forecastItems[1].season
		local currentWeatherObject = self:getWeatherObjectByIndex(season, self.forecastItems[1].objectIndex)
		local scaleFactor = 0

		if currentWeatherObject.weatherType.index == WeatherType.SUN then
			scaleFactor = 1
		elseif currentWeatherObject.weatherType.index == WeatherType.CLOUDY then
			scaleFactor = 0.25
		elseif currentWeatherObject.weatherType.index == WeatherType.RAIN then
			scaleFactor = -0.5
		end

		if currentHour == 0 then
			fog.nightFactor = scaleFactor
		elseif currentHour == 15 then
			fog.dayFactor = scaleFactor
		end
	end
end

function Weather:onPeriodLengthChanged()
	self:rebuild()
end

function Weather:consoleCommandWeatherSet(typeName, variationIndex)
	local env = g_currentMission.environment
	variationIndex = tonumber(variationIndex)
	local currentWeatherInstance = self.forecastItems[1]
	local currentWeatherObject = nil

	if currentWeatherInstance ~= nil then
		currentWeatherObject = self:getWeatherObjectByIndex(currentWeatherInstance.season, currentWeatherInstance.objectIndex)
	end

	self.forecastItems = {}
	local weatherType = g_weatherTypeManager:getWeatherTypeByName(typeName)

	if weatherType ~= nil then
		local weatherObject = self.typeToWeatherObject[env.currentSeason][weatherType.index]

		if weatherObject ~= nil then
			local variation = weatherObject:getVariationByIndex(variationIndex or weatherObject:getRandomVariationIndex())

			if variation == nil then
				variation = weatherObject:getVariationByIndex(weatherObject:getRandomVariationIndex())
			end

			local duration = MathUtil.hoursToMs(math.random(variation.minHours, variation.maxHours))
			local index = 3
			local currentInstance = self.forecastItems[2]

			if currentInstance == nil then
				currentInstance = self.forecastItems[1]
				index = 2

				if currentInstance == nil then
					index = 1
				end
			end

			local startDay = self.owner.currentMonotonicDay
			local startDayTime = self.owner.dayTime

			if currentInstance ~= nil then
				startDayTime = currentInstance.startDayTime
				startDay = currentInstance.startDay
			end

			startDay, startDayTime = self.owner:getDayAndDayTime(startDayTime + duration, startDay)
			local instance = WeatherInstance.createInstance(weatherObject.index, variation.index, startDay, startDayTime, duration, env.currentSeason)

			table.insert(self.forecastItems, index, instance)
			self:fillWeatherForecast()

			if currentWeatherObject ~= nil then
				currentWeatherObject:deactivate(1)
				currentWeatherObject:update(9999999)
			end

			self:init()

			return string.format("Set weather to '%s'", typeName:upper())
		end
	end

	local typeNames = {}

	for weatherTypeIndex, _ in pairs(self.typeToWeatherObject[env.currentSeason]) do
		table.insert(typeNames, g_weatherTypeManager:getWeatherTypeByIndex(weatherTypeIndex).name)
	end

	return string.format("Invalid typeName '%s': gsWeatherSet <typeName> <variation> | Available typeNames for current season: %s", typeName, table.concat(typeNames, ", "))
end

function Weather:consoleCommandWeatherAdd(typeName)
	local env = g_currentMission.environment
	local weatherType = g_weatherTypeManager:getWeatherTypeByName(typeName)

	if weatherType ~= nil then
		local weatherObject = self.typeToWeatherObject[env.currentSeason][weatherType.index]

		if weatherObject ~= nil then
			local variation = weatherObject:getVariationByIndex(weatherObject:getRandomVariationIndex())
			local duration = MathUtil.hoursToMs(math.random(variation.minHours, variation.maxHours))
			local index = 3
			local currentInstance = self.forecastItems[2]

			if currentInstance == nil then
				currentInstance = self.forecastItems[1]
				index = 2

				if currentInstance == nil then
					index = 1
				end
			end

			local startDay = self.owner.currentMonotonicDay
			local startDayTime = self.owner.dayTime

			if currentInstance ~= nil then
				startDayTime = currentInstance.startDayTime
				startDay = currentInstance.startDay
			end

			startDay, startDayTime = self.owner:getDayAndDayTime(startDayTime + duration, startDay)
			local instance = WeatherInstance.createInstance(weatherObject.index, variation.index, startDay, startDayTime, duration, env.currentSeason)
			local timeDif = (instance.startDayTime - self.owner.dayTime) / 60000 + (startDay - self.owner.currentMonotonicDay) * 24 * 60

			table.insert(self.forecastItems, index, instance)

			local lastDuration = duration
			local lastStartDayTime = startDayTime
			local lastStartDay = startDay

			for i = index + 1, #self.forecastItems do
				local forecastItem = self.forecastItems[i]
				forecastItem.startDay, forecastItem.startDayTime = self.owner:getDayAndDayTime(lastStartDayTime + lastDuration, lastStartDay)
				lastDuration = forecastItem.duration
				lastStartDayTime = forecastItem.startDayTime
				lastStartDay = forecastItem.startDay
			end

			return string.format("Added state %s. Starts in %d minutes...", typeName, timeDif)
		end
	end

	local typeNames = {}

	for weatherTypeIndex, _ in pairs(self.typeToWeatherObject[env.currentSeason]) do
		table.insert(typeNames, g_weatherTypeManager:getWeatherTypeByIndex(weatherTypeIndex).name)
	end

	return string.format("Invalid typeName '%s': gsWeatherAdd <typeName> | Available typeNames for current season: %s", typeName, table.concat(typeNames, ", "))
end

function Weather:consoleCommandWeatherSetFog(height, mieScale, transitionDurationMinutes)
	local usage = "Usage: 'gsWeatherSetFog fogPlaneHeight mieScale transitionDurationMinutes'. Use 'gsWeatherSetFog' without any arguments to reset."
	height = tonumber(height)
	mieScale = tonumber(mieScale)
	transitionDurationMinutes = tonumber(transitionDurationMinutes) or 5
	local durationMs = transitionDurationMinutes * 60 * 60 * 1000

	if height ~= nil then
		if self.backupFogHeight == nil then
			self.backupFogHeight = self.fogUpdater:getHeight()
		end

		self.fogUpdater:setHeight(height)
	elseif self.backupFogHeight ~= nil then
		self.fogUpdater:setHeight(self.backupFogHeight)

		self.backupFogHeight = nil
	end

	self.fogUpdater:setForcedTargetValues(mieScale, durationMs)

	if mieScale ~= nil then
		return string.format("Updated fog mieScale=%d duration=%dmin\n%s", mieScale, transitionDurationMinutes, usage)
	else
		return string.format("Reset fog")
	end
end

function Weather:consoleCommandWeatherToggleDebug()
	Weather.DEBUG_ENABLED = not Weather.DEBUG_ENABLED

	if Weather.DEBUG_ENABLED then
		g_currentMission:addDrawable(self)
	else
		g_currentMission:removeDrawable(self)
	end

	return "Weather Debug Enabled: " .. tostring(Weather.DEBUG_ENABLED)
end

function Weather:consoleCommandWeatherReloadData()
	local xmlFile = loadXMLFile(self.xmlFilename, self.xmlFilename)
	local currentWeatherObject = self:getWeatherObjectByIndex(self.forecastItems[1].season, self.forecastItems[1].objectIndex)

	currentWeatherObject:deactivate(1)
	currentWeatherObject:update(9999999)

	for _, object in ipairs(self.weatherObjects) do
		object:delete()
	end

	self.weatherObjects = {}

	self:load(xmlFile, "environment")
	delete(xmlFile)

	return "Reloaded weather data"
end

function Weather:consoleCommandWeatherSetDebugWind(xDir, zDir, speed, cirrusSpeedFactor, duration)
	if g_client ~= nil then
		speed = tonumber(speed) or 1
		xDir = tonumber(xDir) or 1
		zDir = tonumber(zDir) or 1
		cirrusSpeedFactor = tonumber(cirrusSpeedFactor) or 1
		duration = tonumber(duration) or 1

		if speed > 0 then
			self.windUpdater:setTargetValues(xDir, zDir, speed, cirrusSpeedFactor, duration)
		end

		return "Set debug wind speed " .. speed .. ". Command: gsWeatherSetDebugWind <xDir> <zDir> <speed> <cirrusSpeedFactor> <duration>"
	end
end

function Weather:consoleCommandWeatherSetClouds(typeFrom, typeTo, cloudDensityScale, cirrusCloudDensityScale)
	typeFrom = tonumber(typeFrom)
	typeTo = tonumber(typeTo)
	cloudDensityScale = tonumber(cloudDensityScale)
	cirrusCloudDensityScale = tonumber(cirrusCloudDensityScale)

	if typeFrom ~= nil and typeTo ~= nil then
		local currentInstance = self.forecastItems[1]
		local currentWeatherObject = self:getWeatherObjectByIndex(currentInstance.season, currentInstance.objectIndex)
		local varIndex = currentInstance.variationIndex
		local variation = currentWeatherObject.variations[varIndex]
		variation.clouds.cloudTypeFrom = typeFrom
		variation.clouds.cloudTypeTo = typeTo
		variation.clouds.cloudCoverage = cloudDensityScale or variation.clouds.cloudCoverage
		variation.clouds.cirrusCloudDensityScale = cirrusCloudDensityScale or variation.clouds.cirrusCloudDensityScale

		currentWeatherObject:activate(varIndex, 0.0001)

		if currentWeatherObject.setWindValues ~= nil then
			local windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor = self.windUpdater:getCurrentValues()

			currentWeatherObject:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
		end

		return "Set cloud settings..."
	end

	return "Invalid usage. Command: gsWeatherSetClouds <typeFrom> <typeTo> <cloudDensityScale> <cirrusCloudDensityScale>"
end

function Weather:consoleCommandWeatherToggleRandomWindWaving()
	self.windUpdater.randomWindWaving = not self.windUpdater.randomWindWaving

	return "Random wind waving is now " .. (self.windUpdater.randomWindWaving and "enabled" or "disabled")
end
