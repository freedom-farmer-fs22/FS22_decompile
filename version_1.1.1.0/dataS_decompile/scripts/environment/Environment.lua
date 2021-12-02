Environment = {}
local Environment_mt = Class(Environment)
Environment.SEASONS_IN_YEAR = 4
Environment.PERIODS_IN_YEAR = 12
Environment.JULIAN_DAYS_NORTH = {
	[0] = 60,
	152,
	244,
	335
}
Environment.JULIAN_DAYS_SOUTH = {
	[0] = 244,
	335,
	60,
	152
}
Environment.DAYTIME_TO_HOURS_MULT = 1.1574074074074074e-08
Environment.INITIAL_DAY = 6
Environment.MAX_DAYS_PER_PERIOD = 28
Environment.SEASON = {
	WINTER = 3,
	SUMMER = 1,
	SPRING = 0,
	AUTUMN = 2
}
Environment.PERIOD = {
	MID_SPRING = 2,
	LATE_SUMMER = 6,
	MID_SUMMER = 5,
	EARLY_SPRING = 1,
	EARLY_AUTUMN = 7,
	EARLY_SUMMER = 4,
	LATE_AUTUMN = 9,
	EARLY_WINTER = 10,
	MID_WINTER = 11,
	LATE_WINTER = 12,
	MID_AUTUMN = 8,
	LATE_SPRING = 3
}
Environment.PERIOD_DAY_MAPPING = {
	[Environment.PERIOD.EARLY_SPRING] = 80,
	[Environment.PERIOD.MID_SPRING] = 110,
	[Environment.PERIOD.LATE_SPRING] = 140,
	[Environment.PERIOD.EARLY_SUMMER] = 170,
	[Environment.PERIOD.MID_SUMMER] = 200,
	[Environment.PERIOD.LATE_SUMMER] = 230,
	[Environment.PERIOD.EARLY_AUTUMN] = 260,
	[Environment.PERIOD.MID_AUTUMN] = 290,
	[Environment.PERIOD.LATE_AUTUMN] = 320,
	[Environment.PERIOD.EARLY_WINTER] = 350,
	[Environment.PERIOD.MID_WINTER] = 20,
	[Environment.PERIOD.LATE_WINTER] = 50
}

function Environment:onCreateSunLight(node)
	if g_currentMission.environment.baseLighting.sunLightId == nil then
		g_currentMission.environment.baseLighting.sunLightId = node
		g_currentMission.environment.baseLighting.sunColor = {
			getLightColor(node)
		}
	else
		local sunPath = I3DUtil.getNodePath(g_currentMission.environment.lighting.sunLightId)
		local sunChildIndex = getChildIndex(g_currentMission.environment.lighting.sunLightId)
		local secondSunPath = I3DUtil.getNodePath(node)
		local secondSunChildIndex = getChildIndex(node)

		Logging.error("Environment:onCreateSunLight(): Sun light source was already registered '%s'(child %d). Please remove '%s' (child %d)", sunPath, sunChildIndex, secondSunPath, secondSunChildIndex)
	end
end

function Environment:onCreateWater(id)
	if Utils.getNoNil(getUserAttribute(id, "isMainWater"), false) then
		if g_currentMission.environment.water == nil then
			g_currentMission.environment.water = id
		else
			Logging.error("Main water plane already set. Delete user-attribute 'isMainWater' for '%s'!", getName(id))
		end
	end

	if not Utils.getNoNil(getUserAttribute(id, "useShapeObjectMask"), false) then
		setObjectMask(id, bitAND(getObjectMask(id), 4294967167.0))
	end

	local profileId = Utils.getPerformanceClassId()

	if profileId <= GS_PROFILE_MEDIUM or GS_IS_CONSOLE_VERSION or GS_PLATFORM_GGP then
		setReflectionMapScaling(id, 0, true)
	elseif profileId <= GS_PROFILE_HIGH then
		setReflectionMapObjectMasks(id, 512, 33554432, true)
	else
		setReflectionMapObjectMasks(id, 256, 16777216, true)
	end
end

function Environment.new(mission)
	local self = setmetatable({}, Environment_mt)
	self.skyNode = g_i3DManager:loadI3DFile("data/sky/sky.i3d", true, false)

	if self.skyNode ~= nil then
		link(getRootNode(), self.skyNode)
	end

	self.mission = mission
	self.daylight = Daylight.new(self)
	self.lighting = Lighting.new(self)
	self.baseLighting = self.lighting
	self.weather = Weather.new(self)
	self.environmentMaskSystem = EnvironmentMaskSystem.new(self.mission)
	self.timeUpdateInterval = 60000
	self.timeUpdateTime = 0
	self.isSunOn = true
	self.debugSeasonalShaderParameter = false

	if self.mission:getIsServer() then
		addConsoleCommand("gsTimeSet", "Sets the day time in hours", "consoleCommandSetDayTime", self)
		addConsoleCommand("gsEnvironmentReload", "Reloads environment", "consoleCommandReloadEnvironment", self)

		if g_addCheatCommands then
			addConsoleCommand("gsTakeEnvProbes", "Takes env. probes from current camera position", "consoleCommandTakeEnvProbes", self)
		end
	end

	addConsoleCommand("gsSetFixedExposureSettings", "Sets fixed exposure settings", "consoleCommandSetFixedExposureSettings", self)
	addConsoleCommand("gsEnvironmentSeasonalShaderSet", "Sets the seasonal shader to a forced value", "consoleCommandSetSeasonalShader", self)
	addConsoleCommand("gsEnvironmentSeasonalShaderDebug", "Shows the current seasonal shader parameter", "consoleCommandSeasonalShaderDebug", self)
	addConsoleCommand("gsEnvironmentFixedVisualsSet", "Sets the visual seasons to a fixed period", "consoleCommandSetFixedVisuals", self)

	local ambientSoundSystem = self.mission.ambientSoundSystem
	local ambientSoundModifiers = {
		setIsNight = ambientSoundSystem:registerModifier("night", nil),
		setIsPreSunrise = ambientSoundSystem:registerModifier("preSunrise", nil),
		setIsSunrise = ambientSoundSystem:registerModifier("sunrise", nil),
		setIsPostSunrise = ambientSoundSystem:registerModifier("postSunrise", nil),
		setIsMorning = ambientSoundSystem:registerModifier("morning", nil),
		setIsPreNoon = ambientSoundSystem:registerModifier("preNoon", nil),
		setIsNoon = ambientSoundSystem:registerModifier("noon", nil),
		setIsPostNoon = ambientSoundSystem:registerModifier("postNoon", nil),
		setIsAfternoon = ambientSoundSystem:registerModifier("afternoon", nil),
		setIsPreSunset = ambientSoundSystem:registerModifier("preSunset", nil),
		setIsSunset = ambientSoundSystem:registerModifier("sunset", nil),
		setIsPostSunset = ambientSoundSystem:registerModifier("postSunset", nil),
		setIsSpring = ambientSoundSystem:registerModifier("spring", nil),
		setIsSummer = ambientSoundSystem:registerModifier("summer", nil),
		setIsAutumn = ambientSoundSystem:registerModifier("autumn", nil),
		setIsWinter = ambientSoundSystem:registerModifier("winter", nil),
		setIsSun = ambientSoundSystem:registerModifier("sun", nil),
		setIsRain = ambientSoundSystem:registerModifier("rain", nil),
		setIsCloudy = ambientSoundSystem:registerModifier("cloudy", nil),
		setIsSnow = ambientSoundSystem:registerModifier("snow", nil),
		setInVehicle = ambientSoundSystem:registerModifier("inVehicle", nil),
		setOutVehicle = ambientSoundSystem:registerModifier("outVehicle", nil)
	}
	self.ambientSoundModifiers = ambientSoundModifiers

	return self
end

function Environment:load(filename)
	self.xmlFilename = filename
	local xmlFile = XMLFile.load("Environment", filename)

	if xmlFile == nil then
		Logging.fatal("Could not load environment '%s'", filename)
	end

	local baseKey = "environment"
	self.currentDay = 1
	self.currentMonotonicDay = 1
	self.currentDayInPeriod = 1
	self.currentYear = 1
	self.currentDayInSeason = 1
	self.currentSeason = Environment.SEASON.SPRING
	self.currentPeriod = Environment.PERIOD.EARLY_SPRING
	self.daysPerPeriod = 1
	self.timeAdjustment = 1 / self.daysPerPeriod
	self.plannedDaysPerPeriod = 1
	self.currentVisualSeason = Environment.SEASON.SPRING
	self.currentVisualPeriod = Environment.PERIOD.EARLY_SPRING
	self.visualPeriodLocked = false
	self.dayLength = 86400000
	self.realHourLength = 3600000
	self.realHourTimer = self.realHourLength
	local ambientSoundModifiers = self.ambientSoundModifiers
	self.timeRanges = {
		night = self:loadTimeRange(xmlFile, "night", 20, 5, ambientSoundModifiers.setIsNight),
		preSunrise = self:loadTimeRange(xmlFile, "preSunrise", 5, 6, ambientSoundModifiers.setIsPreSunrise),
		sunrise = self:loadTimeRange(xmlFile, "sunrise", 6, 7, ambientSoundModifiers.setIsSunrise),
		postSunrise = self:loadTimeRange(xmlFile, "postSunrise", 7, 8, ambientSoundModifiers.setIsPostSunrise),
		morning = self:loadTimeRange(xmlFile, "morning", 8, 11, ambientSoundModifiers.setIsMorning),
		preNoon = self:loadTimeRange(xmlFile, "preNoon", 11, 12, ambientSoundModifiers.setIsPreNoon),
		noon = self:loadTimeRange(xmlFile, "noon", 12, 13, ambientSoundModifiers.setIsNoon),
		postNoon = self:loadTimeRange(xmlFile, "postNoon", 13, 14, ambientSoundModifiers.setIsPostNoon),
		afternoon = self:loadTimeRange(xmlFile, "afternoon", 14, 17, ambientSoundModifiers.setIsAfternoon),
		preSunset = self:loadTimeRange(xmlFile, "preSunset", 17, 18, ambientSoundModifiers.setIsPreSunset),
		sunset = self:loadTimeRange(xmlFile, "sunset", 18, 19, ambientSoundModifiers.setIsSunset),
		postSunset = self:loadTimeRange(xmlFile, "postSunset", 19, 20, ambientSoundModifiers.setIsPostSunset)
	}

	self.daylight:load(xmlFile, baseKey)
	self:updateJulianDay()

	local startHour = xmlFile:getFloat(baseKey .. "startHour", 8)
	local dayTime = 0

	if startHour ~= nil then
		dayTime = startHour * 60 * 60 * 1000
	end

	self:setEnvironmentTime(Environment.INITIAL_DAY, Environment.INITIAL_DAY, dayTime, self.daysPerPeriod, false)

	self.dayNightCycle = xmlFile:getBool(baseKey .. "#dayNightCycle", true)

	if g_isPresentationVersion and g_isPresentationVersionAlwaysDay then
		self.dayNightCycle = false
	end

	self.lighting:load(xmlFile, baseKey .. ".lighting")
	self.weather:setIsRainAllowed(true)
	self.weather:load(xmlFile, baseKey)
	ambientSoundModifiers.setIsSpring(self.currentVisualSeason == Environment.SEASON.SPRING)
	ambientSoundModifiers.setIsSummer(self.currentVisualSeason == Environment.SEASON.SUMMER)
	ambientSoundModifiers.setIsAutumn(self.currentVisualSeason == Environment.SEASON.AUTUMN)
	ambientSoundModifiers.setIsWinter(self.currentVisualSeason == Environment.SEASON.WINTER)
	self.environmentMaskSystem:setDayOfYear(Environment.PERIOD_DAY_MAPPING[self.currentVisualPeriod], self.currentVisualSeason)
	self.environmentMaskSystem:setIsSunOn(self.isSunOn)

	self.dayTimeScale = xmlFile:getFloat(baseKey .. "#dayTimeScale", 60)
	self.nightTimeScale = xmlFile:getFloat(baseKey .. "#nightTimeScale", 30)
	self.dirtColorDefault = xmlFile:getVector(baseKey .. ".dirtColors#default", {
		0.2,
		0.14,
		0.08
	}, 3)
	self.dirtColorSnow = xmlFile:getVector(baseKey .. ".dirtColors#snow", {
		0.95,
		0.95,
		0.95
	}, 3)
	self.depthOfField = xmlFile:getBool(baseKey .. "#depthOfField", true)

	g_depthOfFieldManager:setEnvironmentDoFEnabled(self.depthOfField)
	self:updateAmbientSoundModifiers()
	xmlFile:delete()
	g_messageCenter:unsubscribeAll(self)
	g_messageCenter:subscribe(MessageType.OWN_PLAYER_ENTERED, self.onPlayerEntered, self)
	g_messageCenter:subscribe(MessageType.OWN_PLAYER_LEFT, self.onPlayerLeft, self)

	return self
end

function Environment:delete()
	delete(self.skyNode)
	self:resetSceneParameters()
	self.environmentMaskSystem:delete()

	self.environmentMaskSystem = nil

	self.weather:delete()

	self.weather = nil

	self.baseLighting:delete()

	self.baseLighting = nil

	self.daylight:delete()

	self.daylight = nil

	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsTimeSet")
	removeConsoleCommand("gsEnvironmentReload")
	removeConsoleCommand("gsSetFixedExposureSettings")
	removeConsoleCommand("gsEnvironmentSeasonalShaderSet")
	removeConsoleCommand("gsEnvironmentSeasonalShaderDebug")
	removeConsoleCommand("gsEnvironmentFixedVisualsSet")
	removeConsoleCommand("gsTakeEnvProbes")
end

function Environment:saveToXMLFile(xmlFile, key)
	setXMLFloat(xmlFile, key .. ".dayTime", self.dayTime / 60000)
	setXMLInt(xmlFile, key .. ".currentDay", self.currentDay)
	setXMLInt(xmlFile, key .. ".currentMonotonicDay", self.currentMonotonicDay)
	setXMLInt(xmlFile, key .. ".realHourTimer", self.realHourTimer)
	setXMLInt(xmlFile, key .. ".daysPerPeriod", self.daysPerPeriod)
	self.daylight:saveToXMLFile(xmlFile, key .. ".daylight")
	self.weather:saveToXMLFile(xmlFile, key .. ".weather")
end

function Environment:loadFromXMLFile(xmlFile, key)
	local dayTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".dayTime"), 400)
	local currentDay = Utils.getNoNil(getXMLInt(xmlFile, key .. ".currentDay"), self.currentDay)
	local currentMonotonicDay = Utils.getNoNil(getXMLInt(xmlFile, key .. ".currentMonotonicDay"), currentDay)
	self.daysPerPeriod = Utils.getNoNil(getXMLInt(xmlFile, key .. ".daysPerPeriod"), self.daysPerPeriod)
	self.timeAdjustment = 1 / self.daysPerPeriod
	self.plannedDaysPerPeriod = self.mission.missionInfo.plannedDaysPerPeriod
	local fixedPeriod = self.mission.missionInfo.fixedSeasonalVisuals

	if fixedPeriod ~= nil then
		self.currentVisualPeriod = fixedPeriod
		self.currentVisualSeason = math.floor((fixedPeriod - 1) / 3)
		self.visualPeriodLocked = true
	end

	self:setEnvironmentTime(currentMonotonicDay, currentDay, dayTime * 1000 * 60, self.daysPerPeriod, false)

	self.realHourTimer = Utils.getNoNil(getXMLInt(xmlFile, key .. ".realHourTimer"), 3600000)

	self.daylight:loadFromXMLFile(xmlFile, key .. ".daylight")
	self.weather:loadFromXMLFile(xmlFile, key .. ".weather")
end

function Environment:update(dt)
	if self.envMapGeneration ~= nil then
		local task = self.envMapGeneration.tasks[1]

		if task ~= nil then
			if task.dayTime ~= nil then
				local newDayTime = math.floor(task.dayTime * 1000 * 60 * 60)
				local newDay = self.currentDay

				self:setEnvironmentTime(newDay, newDay, newDayTime, self.daysPerPeriod, false)
				self.lighting:update(0, true)
			end

			if task.cloudData ~= nil then
				self.weather.cloudUpdater:setTargetClouds(task.cloudData, 0)
				self.weather.cloudUpdater:setWindValues(task.windDirX, task.windDirZ, task.windVelocity, task.cirrusCloudSpeedFactor)
				self.weather.cloudUpdater:update(10000)
			end

			if task.setDefaultValues then
				setSharedShaderParameter(Shader.PARAM_SHARED_SEASON, 0)
				self.baseLighting:setDaylightTimes(7, 19, 6, 20)

				self.baseLighting.envMapRenderingMode = true

				self.baseLighting:update(0, true)

				self.baseLighting.envMapRenderingMode = false
			end

			local filename = task.filename

			if filename ~= nil then
				local renderResolution = task.renderResolution
				local outputResolution = task.outputResolution
				local numIterations = task.numIterations

				renderEnvProbe(renderResolution, outputResolution, 15, 4, numIterations, filename)
			end

			table.remove(self.envMapGeneration.tasks, 1)

			return
		else
			local currentData = self.envMapGeneration.currentData
			local cloudUpdater = self.weather.cloudUpdater
			cloudUpdater.lastClouds = currentData.lastClouds
			cloudUpdater.targetClouds = currentData.targetClouds
			cloudUpdater.alpha = currentData.alpha
			cloudUpdater.duration = currentData.duration
			cloudUpdater.windDirX = currentData.windDirX
			cloudUpdater.windDirZ = currentData.windDirZ
			cloudUpdater.windVelocity = currentData.windVelocity
			cloudUpdater.cirrusCloudSpeedFactor = currentData.cirrusCloudSpeedFactor
			cloudUpdater.isDirty = true

			g_currentMission.growthSystem:setGrowthMode(currentData.growthMode, true)
			self:setEnvironmentTime(currentData.currentMonotonicDay + 12 * self.daysPerPeriod, currentData.currentDay + 12 * self.daysPerPeriod, currentData.dayTime, self.daysPerPeriod, false)

			self.envMapGeneration = nil

			print("Finished environment map generation")
		end
	end

	self.weather:update(dt)
	self.environmentMaskSystem:update(dt)

	self.dayTime = self.dayTime + dt * self.mission:getEffectiveTimeScale()

	self:updateTimeValues(false)

	self.realHourTimer = self.realHourTimer - dt

	if self.realHourTimer <= 0 then
		g_messageCenter:publish(MessageType.REALHOUR_CHANGED)

		self.realHourTimer = self.realHourLength
	end

	if self.lighting ~= nil then
		local cloudEnvMapIndex1, cloudEnvMapIndex2, alpha = self.weather:getCloudEnvMapInfo()

		self.lighting:setCloudEnvMapInfo(cloudEnvMapIndex1, cloudEnvMapIndex2, alpha)
		self.lighting:setDaylightTimes(self.daylight:getDaylightTimes())
		self.lighting:update(dt)
	end

	self:updateSceneParameters()

	if self.debugSeasonalShaderParameter then
		renderText(0.2, 0.05, 0.015, string.format("Season Shader Parameter (cShared3): %s", self:getSeasonShaderValue()))
	end

	if g_server ~= nil then
		self.timeUpdateTime = self.timeUpdateTime + dt

		if self.timeUpdateInterval < self.timeUpdateTime then
			EnvironmentTimeEvent.broadcastEvent()

			self.timeUpdateTime = 0
		end

		if Platform.gameplay.hasShortNights then
			local dayMinutes = self.dayTime / 60000
			local isNight = self.daylight.logicalNightStartMinutes <= dayMinutes or dayMinutes < self.daylight.logicalNightEndMinutes

			if isNight ~= self.lastNightState then
				self.mission:setTimeScale(isNight and self.nightTimeScale or self.dayTimeScale)
			end

			self.lastNightState = isNight
		end
	end
end

function Environment:updateTimeValues(initialState)
	local timeHoursF = self.dayTime / 3600000 + 0.0001
	local timeHours = math.floor(timeHoursF)
	local timeMinutes = math.floor((timeHoursF - timeHours) * 60)

	self.environmentMaskSystem:setDayTime(self.dayTime)

	local hourChanged = false
	local dayChanged = false
	local periodChanged = false
	local seasonChanged = false
	local yearChanged = false
	local periodLengthChanged = false

	if timeMinutes ~= self.currentMinute then
		while timeMinutes ~= self.currentMinute do
			self.currentMinute = self.currentMinute + 1

			if self.currentMinute >= 60 then
				self.currentMinute = 0
			end

			if not initialState then
				self:updateAmbientSoundModifiers()
				g_messageCenter:publish(MessageType.MINUTE_CHANGED, self.currentMinute)
				self.mission:onMinuteChanged(self.currentMinute)
			end
		end
	end

	if timeHours ~= self.currentHour then
		self.currentHour = timeHours

		if self.currentHour == 24 then
			self.currentHour = 0
		end

		hourChanged = true
	end

	if self.dayTime > 86400000 then
		self.dayTime = self.dayTime - 86400000
		self.currentDay = self.currentDay + 1
		self.currentMonotonicDay = self.currentMonotonicDay + 1
		dayChanged = true
	end

	if dayChanged or initialState then
		self.currentDayInPeriod = (self.currentDay - 1) % self.daysPerPeriod + 1
		local period = math.ceil(((self.currentDay - 1) % (self.daysPerPeriod * Environment.PERIODS_IN_YEAR) + 1) / self.daysPerPeriod)

		if period ~= self.currentPeriod then
			self.currentPeriod = period

			if not self.visualPeriodLocked then
				self.currentVisualPeriod = self.currentPeriod
			end

			periodChanged = true
		end

		local season = math.fmod(math.floor((self.currentDay - 1) / (self.daysPerPeriod * 3)), Environment.SEASONS_IN_YEAR)

		if season ~= self.currentSeason then
			self.currentSeason = season

			if not self.visualPeriodLocked then
				self.currentVisualSeason = season
			end

			seasonChanged = true

			if self.daysPerPeriod ~= self.plannedDaysPerPeriod then
				local oldDaysPerPeriod = self.daysPerPeriod
				self.daysPerPeriod = self.plannedDaysPerPeriod
				self.timeAdjustment = 1 / self.daysPerPeriod
				self.currentDay = math.floor((self.currentDay - 1) / oldDaysPerPeriod * self.daysPerPeriod) + 1
				self.currentDayInPeriod = (self.currentDay - 1) % self.daysPerPeriod + 1
				periodLengthChanged = true
			end
		end

		if self.visualPeriodLocked then
			self.currentDayInSeason = (self.currentVisualPeriod - 1) % 3 + 1
		else
			self.currentDayInSeason = math.fmod(self.currentDay - 1, self.daysPerPeriod * 3) + 1
		end

		local year = math.floor((self.currentDay - 1) / (self.daysPerPeriod * Environment.PERIODS_IN_YEAR)) + 1

		if year ~= self.currentYear then
			self.currentYear = year
			yearChanged = true
		end
	end

	if dayChanged or initialState then
		self:updateJulianDay()
	end

	if hourChanged and not initialState then
		g_messageCenter:publish(MessageType.HOUR_CHANGED, self.currentHour)
		self.mission:onHourChanged()
	end

	if dayChanged and not initialState then
		g_messageCenter:publish(MessageType.DAY_CHANGED, self.currentDay)
		self.mission:onDayChanged()

		if periodLengthChanged then
			g_messageCenter:publish(MessageType.PERIOD_LENGTH_CHANGED, self.daysPerPeriod, self.timeAdjustment)
		end

		if periodChanged then
			g_messageCenter:publish(MessageType.PERIOD_CHANGED, self.currentPeriod)

			local ambientSounds = self.ambientSoundModifiers
			local period = Environment.PERIOD
			local currentVisualPeriod = self.currentVisualPeriod

			ambientSounds.setIsSpring(currentVisualPeriod == period.EARLY_SPRING or currentVisualPeriod == period.MID_SPRING or currentVisualPeriod == period.LATE_SPRING)
			ambientSounds.setIsSummer(currentVisualPeriod == period.EARLY_SUMMER or currentVisualPeriod == period.MID_SUMMER or currentVisualPeriod == period.LATE_SUMMER)
			ambientSounds.setIsAutumn(currentVisualPeriod == period.EARLY_AUTUMN or currentVisualPeriod == period.MID_AUTUMN or currentVisualPeriod == period.LATE_AUTUMN)
			ambientSounds.setIsWinter(currentVisualPeriod == period.EARLY_WINTER or currentVisualPeriod == period.LATE_WINTER or currentVisualPeriod == period.LATE_WINTER)
			self.environmentMaskSystem:setDayOfYear(Environment.PERIOD_DAY_MAPPING[currentVisualPeriod], self.currentVisualSeason)
		end

		if seasonChanged then
			g_messageCenter:publish(MessageType.SEASON_CHANGED, self.currentSeason)
		end

		if yearChanged then
			g_messageCenter:publish(MessageType.YEAR_CHANGED, self.currentYear)
		end
	end
end

function Environment:loadTimeRange(xmlFile, name, fromDefault, toDefault, ambientSoundModifierFunc)
	local data = {
		from = xmlFile:getFloat(string.format("environment.dayTime.%s#from", name), fromDefault),
		to = xmlFile:getFloat(string.format("environment.dayTime.%s#to", name), toDefault),
		func = ambientSoundModifierFunc
	}

	return data
end

function Environment:updateAmbientSoundModifiers()
	local currentHour = self.dayTime / 3600000

	for _, data in pairs(self.timeRanges) do
		if data.from < data.to then
			data.func(data.from <= currentHour and currentHour < data.to)
		else
			data.func(data.from <= currentHour or currentHour < data.to)
		end
	end
end

function Environment:updateSceneParameters()
	if self.dayNightCycle and self.lighting.sunLightId ~= nil then
		local dayMinutes = self.dayTime / 60000
		local newIsSunOn = self.daylight.logicalNightStartMinutes > dayMinutes and dayMinutes >= self.daylight.logicalNightEndMinutes

		if self.isSunOn ~= newIsSunOn then
			self.isSunOn = newIsSunOn

			self.environmentMaskSystem:setIsSunOn(newIsSunOn)
			g_messageCenter:publish(MessageType.WEATHER_CHANGED)
		end
	end

	if self.forcedSeasonShaderValue == nil then
		setSharedShaderParameter(Shader.PARAM_SHARED_SEASON, self:getSeasonShaderValue())
	end
end

function Environment:onWeatherChanged(weatherObject)
	self.environmentMaskSystem:setWeather(weatherObject.weatherType)

	local typeIndex = weatherObject.weatherType.index
	local ambientSoundModifiers = self.ambientSoundModifiers

	ambientSoundModifiers.setIsSun(typeIndex == WeatherType.SUN)
	ambientSoundModifiers.setIsRain(typeIndex == WeatherType.RAIN)
	ambientSoundModifiers.setIsCloudy(typeIndex == WeatherType.CLOUDY)
	ambientSoundModifiers.setIsSnow(typeIndex == WeatherType.SNOW)
end

function Environment:resetSceneParameters()
	setSharedShaderParameter(Shader.PARAM_SHARED_SEASON, 0)
end

function Environment:getSeasonShaderValue()
	if self.visualPeriodLocked then
		return (self.currentVisualSeason - 1) % 4
	end

	local pInDay = self.dayTime * Environment.DAYTIME_TO_HOURS_MULT + 0.0001
	local shaderSeason = (self.currentSeason - 1) % 4
	local day = self.currentDay
	local daysPerSeason = 3 * self.daysPerPeriod
	local pInSeason = (day - 1) % daysPerSeason / daysPerSeason
	local alpha = pInSeason + pInDay / daysPerSeason

	return shaderSeason + alpha
end

function Environment:setCustomLighting(lighting)
	if self.lighting ~= nil then
		self.lighting:reset()
	end

	self.lighting = lighting or self.baseLighting
	self.lighting.sunLightId = self.baseLighting.sunLightId

	self.lighting:setDaylightTimes(self.daylight:getDaylightTimes())
	self.lighting:update(1, true)
end

function Environment:setSunVisibility(isVisible)
	if isVisible then
		local r, g, b = unpack(self.baseLighting.sunColor)

		setLightColor(self.baseLighting.sunLightId, r, g, b)
	else
		setLightColor(self.baseLighting.sunLightId, 0, 0, 0)
	end
end

function Environment:getPercentageIntoYear()
	local inDay = self.dayTime * Environment.DAYTIME_TO_HOURS_MULT + 0.0001

	return (day - 1) % (3 * self.daysPerPeriod) / (3 * self.daysPerPeriod) / 4 + self.currentSeason / 4 + inDay / (12 * self.daysPerPeriod)
end

function Environment:getDayAndDayTime(dayTime, dayOffset)
	local newDayOffset, newDayTime = math.modf(dayTime / self.dayLength)

	return dayOffset + newDayOffset, newDayTime * self.dayLength
end

function Environment:getDaysPerSeason()
	return self.daysPerPeriod * 3
end

function Environment:getSeasonAtDay(day)
	local diff = day - self.currentMonotonicDay
	local seasonalDay = self.currentDay + diff

	return math.fmod(math.floor((seasonalDay - 1) / (self.daysPerPeriod * 3)), Environment.SEASONS_IN_YEAR)
end

function Environment:getVisualSeasonAtDay(day)
	if self.visualPeriodLocked then
		return self.currentVisualSeason
	else
		return self:getSeasonAtDay(day)
	end
end

function Environment:setEnvironmentTime(currentMonotonicDay, currentDay, dayTime, daysPerPeriod, isDelta)
	self.currentDay = currentDay
	self.currentMonotonicDay = currentMonotonicDay
	self.dayTime = dayTime
	self.daysPerPeriod = daysPerPeriod

	if not isDelta then
		while self.dayTime > 86400000 do
			self.dayTime = self.dayTime - 86400000
			self.currentDay = self.currentDay + 1
			self.currentMonotonicDay = self.currentMonotonicDay + 1
		end

		local timeHoursF = self.dayTime / 3600000 + 0.0001
		self.currentHour = math.floor(timeHoursF)
		self.currentMinute = math.floor((timeHoursF - self.currentHour) * 60)
	end

	self:updateTimeValues(true)
end

function Environment:getEnvironmentTime()
	return self.currentHour + self.currentMinute / 100
end

function Environment:onPlayerEntered()
	self.environmentMaskSystem:setIsInVehicle(false)
	self.ambientSoundModifiers.setInVehicle(false)
	self.ambientSoundModifiers.setOutVehicle(true)
end

function Environment:onPlayerLeft()
	self.environmentMaskSystem:setIsInVehicle(true)
	self.ambientSoundModifiers.setInVehicle(true)
	self.ambientSoundModifiers.setOutVehicle(false)
end

function Environment:getJulianDay()
	local startDays = Environment.JULIAN_DAYS_NORTH

	if self.daylight.latitude < 0 then
		startDays = Environment.JULIAN_DAYS_SOUTH
	end

	local partInSeason = self.currentDayInSeason / (3 * self.daysPerPeriod)

	return math.fmod(math.floor(startDays[self.currentVisualSeason] + partInSeason * 91), 365)
end

function Environment:updateJulianDay()
	if self.daylight ~= nil then
		self.daylight:setJulianDay(self:getJulianDay())

		local sunRiseStart = self.daylight.nightEnd
		local sunRiseEnd = self.daylight.dayStart
		local sunRisePart = (sunRiseEnd - sunRiseStart) / 3
		self.timeRanges.night.to = sunRiseStart
		self.timeRanges.preSunrise.from = sunRiseStart
		self.timeRanges.preSunrise.to = self.timeRanges.preSunrise.from + sunRisePart
		self.timeRanges.sunrise.from = self.timeRanges.preSunrise.to
		self.timeRanges.sunrise.to = self.timeRanges.sunrise.from + sunRisePart
		self.timeRanges.postSunrise.from = self.timeRanges.sunrise.to
		self.timeRanges.postSunrise.to = sunRiseEnd
		self.timeRanges.morning.from = sunRiseEnd
		local sunSetStart = self.daylight.dayEnd
		local sunSetEnd = self.daylight.nightStart
		local sunSetPart = (sunSetEnd - sunSetStart) / 3
		self.timeRanges.afternoon.to = sunSetStart
		self.timeRanges.preSunset.from = sunSetStart
		self.timeRanges.preSunset.to = self.timeRanges.preSunset.from + sunSetPart
		self.timeRanges.sunset.from = self.timeRanges.preSunset.to
		self.timeRanges.sunset.to = self.timeRanges.sunset.from + sunSetPart
		self.timeRanges.postSunset.from = self.timeRanges.sunset.to
		self.timeRanges.postSunset.to = sunSetEnd
		self.timeRanges.night.from = sunSetEnd
	end
end

function Environment.getSeasonFromString(seasonName)
	seasonName = seasonName:lower()

	if seasonName == "spring" then
		return Environment.SEASON.SPRING
	elseif seasonName == "autumn" then
		return Environment.SEASON.AUTUMN
	elseif seasonName == "winter" then
		return Environment.SEASON.WINTER
	else
		return Environment.SEASON.SUMMER
	end
end

function Environment:getPeriodAndAlphaIntoPeriod()
	local inDay = self.dayTime * Environment.DAYTIME_TO_HOURS_MULT + 0.0001
	local dayTimeAlpha = inDay / 3 + (self.currentDayInPeriod - 1) / self.daysPerPeriod

	return self.currentPeriod, dayTimeAlpha
end

function Environment:getDirtColors()
	return self.dirtColorDefault, self.dirtColorSnow
end

function Environment:getPeriodFromDay(day)
	local diff = day - self.currentMonotonicDay
	local seasonalDay = self.currentDay + diff

	return math.ceil(((seasonalDay - 1) % (self.daysPerPeriod * Environment.PERIODS_IN_YEAR) + 1) / self.daysPerPeriod)
end

function Environment:getDayInPeriodFromDay(day)
	local diff = day - self.currentMonotonicDay
	local seasonalDay = self.currentDay + diff

	return (seasonalDay - 1) % self.daysPerPeriod + 1
end

function Environment:setFixedPeriod(period)
	if period == nil and self.visualPeriodLocked == true then
		self.visualPeriodLocked = false
		self.currentVisualPeriod = self.currentPeriod
		self.currentVisualSeason = self.currentSeason
		self.currentDayInSeason = math.fmod(self.currentDay - 1, self.daysPerPeriod * 3) + 1
		self.mission.missionInfo.fixedSeasonalVisuals = nil

		self:updateJulianDay()
		self.weather:rebuild()
	elseif period ~= nil and (self.visualPeriodLocked == false or self.currentVisualPeriod ~= period) then
		period = MathUtil.clamp(period, 1, 12)
		self.visualPeriodLocked = true
		self.currentVisualPeriod = period
		self.currentVisualSeason = math.floor((period - 1) / 3)
		self.currentDayInSeason = (self.currentVisualPeriod - 1) % 3 + 1
		self.mission.missionInfo.fixedSeasonalVisuals = period

		self:updateJulianDay()
		self.weather:rebuild()
	end
end

function Environment:setPlannedDaysPerPeriod(numDays)
	self.plannedDaysPerPeriod = MathUtil.clamp(numDays, 1, Environment.MAX_DAYS_PER_PERIOD)
	self.mission.missionInfo.plannedDaysPerPeriod = self.plannedDaysPerPeriod
end

function Environment:consoleCommandSetDayTime(dayTime, skipDayOnly)
	if self.mission:getIsServer() then
		dayTime = tonumber(dayTime)

		if dayTime ~= nil then
			local newDayTime = math.floor(dayTime * 1000 * 60 * 60)
			local newDay = self.currentDay
			local newMonotonicDay = self.currentMonotonicDay

			if newDayTime < self.dayTime then
				if skipDayOnly then
					newDay = newDay + 1
					newMonotonicDay = newMonotonicDay + 1
				else
					newDay = newDay + 12
					newMonotonicDay = newMonotonicDay + 12
				end
			end

			self:setEnvironmentTime(newMonotonicDay, newDay, newDayTime, self.daysPerPeriod, false)
			self.lighting:update(1, true)
			EnvironmentTimeEvent.broadcastEvent()

			return "DayTime = " .. dayTime .. ", Day = " .. newDay .. "[" .. newMonotonicDay .. "]"
		else
			return "Invalid arguments. Arguments: dayTime[h] skipDayOnly[true|false]"
		end
	end
end

function Environment:consoleCommandSetFixedVisuals(period)
	if period == nil then
		self:setFixedPeriod(nil)
	else
		self:setFixedPeriod(tonumber(period))
	end
end

function Environment:consoleCommandReloadEnvironment()
	local a = self.lighting.colorGradingFileCurve
	local b = self.lighting.envMapBasePath
	local c = self.lighting.envMapTimes

	g_messageCenter:unsubscribeAll(self)
	self:load(self.xmlFilename)

	self.lighting.envMapTimes = c
	self.lighting.envMapBasePath = b
	self.lighting.colorGradingFileCurve = a
	local filename = "data/maps/default_colorGrading.xml"

	setColorGradingSettings(filename, filename, 1)
	self.lighting:update(1, true)

	return "reloaded environment"
end

function Environment:consoleCommandSetFixedExposureSettings(keyValue, minExposure, maxExposure)
	keyValue = tonumber(keyValue)
	minExposure = tonumber(minExposure)
	maxExposure = tonumber(maxExposure)
	local ret = nil

	if keyValue ~= nil then
		if minExposure ~= nil then
			if maxExposure == nil then
				maxExposure = minExposure
			end

			local minLuminance = keyValue / math.pow(2, maxExposure)
			local maxLuminance = keyValue / math.pow(2, minExposure)
			ret = string.format("Enabled fixed exposure settings (key %.2f exposure [%.2f %.2f] [%.4f %.4f])", keyValue, minExposure, maxExposure, minLuminance, maxLuminance)
		else
			maxExposure = nil
			ret = string.format("Enabled fixed exposure key %.2f", keyValue)
		end
	else
		minExposure, maxExposure = nil
		ret = "Disabled fixed exposure settings"
	end

	self.baseLighting:setFixedExposureSettings(keyValue, minExposure, maxExposure)

	if self.lighting == self.baseLighting then
		self.baseLighting:updateExposureSettings()
	end

	return ret
end

function Environment:consoleCommandSetSeasonalShader(val)
	if val == nil or tonumber(val) == nil then
		self.forcedSeasonShaderValue = nil

		self:updateSceneParameters()

		return "Reset the value to match the environment"
	end

	val = tonumber(val)
	val = math.min(math.max(val, 0), 4)
	self.forcedSeasonShaderValue = val

	setSharedShaderParameter(Shader.PARAM_SHARED_SEASON, val)

	return "Set shader parameter to " .. tostring(val)
end

function Environment:consoleCommandSeasonalShaderDebug()
	self.debugSeasonalShaderParameter = not self.debugSeasonalShaderParameter
end

function Environment:consoleCommandTakeEnvProbes(numIterations, mobile, outputDirectory)
	numIterations = tonumber(numIterations)

	if numIterations == nil then
		return "Arguments: numIterations (required), mobile(optional, default: false), outputDirectory (optional, default: [map xml-path])"
	end

	if mobile == nil then
		mobile = false
	end

	local renderResolution = 512
	local outputResolution = 256

	if mobile then
		outputResolution = 128
	end

	local envMapTimes, baseDirectory = nil

	if self.baseLighting.envMapBasePath ~= nil then
		envMapTimes = self.baseLighting.envMapTimes
		baseDirectory = self.baseLighting.envMapBasePath
	else
		envMapTimes = {
			0
		}
		baseDirectory = g_screenshotsDirectory .. "envProbes/"
	end

	if outputDirectory ~= nil then
		baseDirectory = outputDirectory
	end

	if baseDirectory:sub(baseDirectory:len()) ~= "/" then
		baseDirectory = baseDirectory .. "/"
	end

	createFolder(baseDirectory)
	print("Writing env maps to " .. baseDirectory)

	if #envMapTimes > 0 then
		self.envMapGeneration = {
			tasks = {}
		}

		for k, cloudData in ipairs(self.weather.envMapCloudProbes) do
			local data = {
				cloudData = cloudData,
				setDefaultValues = true,
				cirrusCloudSpeedFactor = 0,
				windVelocity = 0,
				windDirZ = 1,
				windDirX = 0
			}

			table.insert(self.envMapGeneration.tasks, data)
			table.insert(self.envMapGeneration.tasks, {})
			table.insert(self.envMapGeneration.tasks, {})
			table.insert(self.envMapGeneration.tasks, {})
			table.insert(self.envMapGeneration.tasks, {})
			table.insert(self.envMapGeneration.tasks, {})
			table.insert(self.envMapGeneration.tasks, {})

			for _, dayTime in ipairs(envMapTimes) do
				local renderData = {
					dayTime = dayTime,
					renderResolution = renderResolution,
					outputResolution = outputResolution,
					numIterations = numIterations,
					filename = baseDirectory .. Lighting.getEnvMapBaseFilename(dayTime, k)
				}

				table.insert(self.envMapGeneration.tasks, renderData)
			end
		end

		local cloudUpdater = self.weather.cloudUpdater
		local currentData = {
			lastClouds = table.copy(cloudUpdater.lastClouds, math.huge),
			targetClouds = table.copy(cloudUpdater.targetClouds, math.huge),
			alpha = cloudUpdater.alpha,
			duration = cloudUpdater.duration,
			windDirX = cloudUpdater.windDirX,
			windDirZ = cloudUpdater.windDirZ,
			windVelocity = cloudUpdater.windVelocity,
			cirrusCloudSpeedFactor = cloudUpdater.cirrusCloudSpeedFactor,
			growthMode = g_currentMission.growthSystem:getGrowthMode(),
			dayTime = self.dayTime,
			currentDay = self.currentDay
		}
		self.envMapGeneration.currentData = currentData

		g_currentMission.growthSystem:setGrowthMode(GrowthSystem.MODE.DISABLED, true)
	end
end
