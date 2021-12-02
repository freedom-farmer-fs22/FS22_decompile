EnvironmentMaskSystem = {
	VISIBILITY_CONDITION_FLAGS_XML_PATH = "shared/visibilityConditionFlags.xml"
}
local EnvironmentMaskSystem_mt = Class(EnvironmentMaskSystem)

function EnvironmentMaskSystem.new(mission, customMt)
	local self = setmetatable({}, customMt or EnvironmentMaskSystem_mt)
	self.mission = mission
	self.weatherMaskModifiers = {}
	self.weatherFlagNameToModifier = {}
	self.viewerSpatialityMaskModifiers = {}
	self.viewerSpatialityFlagNameToModifier = {}
	self.isDebugViewActive = false
	self.minuteOfDay = 0
	self.dayOfYear = 1
	self.weatherMask = 0
	self.viewerSpatialityMask = 0
	local xmlFile = XMLFile.load("visibilityConditionFlagsXml", EnvironmentMaskSystem.VISIBILITY_CONDITION_FLAGS_XML_PATH)

	xmlFile:iterate("visibilityConditionFlags.weatherFlags.flag", function (_, weatherFlagKey)
		self:registerWeatherMaskModifier(xmlFile:getString(weatherFlagKey .. "#name"), xmlFile:getInt(weatherFlagKey .. "#bit"))
	end)

	self.setWeatherSun = self:getWeatherModifierUpdateFuncFromFlagName("SUN")
	self.setWeatherRain = self:getWeatherModifierUpdateFuncFromFlagName("RAIN")
	self.setWeatherHail = self:getWeatherModifierUpdateFuncFromFlagName("HAIL")
	self.setWeatherSnow = self:getWeatherModifierUpdateFuncFromFlagName("SNOW")
	self.setWeatherCloudy = self:getWeatherModifierUpdateFuncFromFlagName("CLOUDY")
	self.setIsDay = self:getWeatherModifierUpdateFuncFromFlagName("DAY")
	self.setIsNight = self:getWeatherModifierUpdateFuncFromFlagName("NIGHT")
	self.setIsSpring = self:getWeatherModifierUpdateFuncFromFlagName("SPRING")
	self.setIsSummer = self:getWeatherModifierUpdateFuncFromFlagName("SUMMER")
	self.setIsAutumn = self:getWeatherModifierUpdateFuncFromFlagName("AUTUMN")
	self.setIsWinter = self:getWeatherModifierUpdateFuncFromFlagName("WINTER")

	xmlFile:iterate("visibilityConditionFlags.viewerSpatialityFlags.flag", function (_, weatherFlagKey)
		self:registerViewerSpatialityMaskModifier(xmlFile:getString(weatherFlagKey .. "#name"), xmlFile:getInt(weatherFlagKey .. "#bit"))
	end)

	self.setIsInterior = self:getViewerSpatialityModifierUpdateFuncFromFlagName("INTERIOR")
	self.setIsExterior = self:getViewerSpatialityModifierUpdateFuncFromFlagName("EXTERIOR")
	self.setInVehicle = self:getViewerSpatialityModifierUpdateFuncFromFlagName("IN_VEHICLE")
	self.setOutVehicle = self:getViewerSpatialityModifierUpdateFuncFromFlagName("OUT_VEHICLE")

	xmlFile:delete()
	addConsoleCommand("gsEnvironmentMaskSystemToggleDebugView", "Toggles the environment mask system debug view", "consoleCommandToggleDebugView", self)

	return self
end

function EnvironmentMaskSystem:delete()
	removeConsoleCommand("gsEnvironmentMaskSystemToggleDebugView")
end

function EnvironmentMaskSystem:update(dt)
	setEnvironmentSettings(self.minuteOfDay + 1, self.dayOfYear, self.weatherMask, self.viewerSpatialityMask)
end

function EnvironmentMaskSystem:draw()
	if self.isDebugViewActive then
		setTextColor(1, 1, 1, 1)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(0.4, 0.82, getCorrectTextSize(0.014), "Environment State")
		renderText(0.6, 0.82, getCorrectTextSize(0.014), "Weather Mask:")
		renderText(0.7, 0.82, getCorrectTextSize(0.014), "Viewer Spatiality Mask:")
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)

		local posY = 0.8
		local textSize = getCorrectTextSize(0.012)
		local textOffset = getCorrectTextSize(0.001)

		for _, modifier in ipairs(self.weatherMaskModifiers) do
			local isActive = bitAND(self.weatherMask, modifier.bitflag) ~= 0

			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(0.6, posY, textSize, modifier.name .. ":  ")
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(0.6, posY, textSize, tostring(isActive))

			posY = posY - textSize - textOffset
		end

		posY = 0.8

		for _, modifier in ipairs(self.viewerSpatialityMaskModifiers) do
			local isActive = bitAND(self.viewerSpatialityMask, modifier.bitflag) ~= 0

			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(0.7, posY, textSize, modifier.name .. ":  ")
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(0.7, posY, textSize, tostring(isActive))

			posY = posY - textSize - textOffset
		end

		posY = 0.8

		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(0.4, posY - (textSize + textOffset) * 0, textSize, "MinuteOfDay:  ")
		renderText(0.4, posY - (textSize + textOffset) * 1, textSize, "DayOfYear:  ")
		renderText(0.4, posY - (textSize + textOffset) * 2, textSize, "WeatherMask:  ")
		renderText(0.4, posY - (textSize + textOffset) * 3, textSize, "ViewerSpatialityMask:  ")

		posY = 0.8

		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(0.4, posY - (textSize + textOffset) * 0, textSize, tostring(self.minuteOfDay))
		renderText(0.4, posY - (textSize + textOffset) * 1, textSize, tostring(self.dayOfYear))
		renderText(0.4, posY - (textSize + textOffset) * 2, textSize, tostring(self.weatherMask))
		renderText(0.4, posY - (textSize + textOffset) * 3, textSize, tostring(self.viewerSpatialityMask))
	end
end

function EnvironmentMaskSystem:setDayTime(dayTime)
	self.minuteOfDay = math.floor(dayTime / 1000 / 60)
end

function EnvironmentMaskSystem:setDayOfYear(dayOfYear, season)
	self.dayOfYear = MathUtil.clamp(dayOfYear, 0, 365)

	self.setIsSpring(season == Environment.SEASON.SPRING)
	self.setIsSummer(season == Environment.SEASON.SUMMER)
	self.setIsAutumn(season == Environment.SEASON.AUTUMN)
	self.setIsWinter(season == Environment.SEASON.WINTER)
end

function EnvironmentMaskSystem:setWeather(weatherType)
	self.setWeatherSun(weatherType.index == WeatherType.SUN)
	self.setWeatherRain(weatherType.index == WeatherType.RAIN)
	self.setWeatherHail(weatherType.index == WeatherType.HAIL)
	self.setWeatherSnow(weatherType.index == WeatherType.SNOW)
	self.setWeatherCloudy(weatherType.index == WeatherType.CLOUDY)
end

function EnvironmentMaskSystem:setIsSunOn(isSunOn)
	self.setIsDay(isSunOn)
	self.setIsNight(not isSunOn)
end

function EnvironmentMaskSystem:setIsInVehicle(isInVehicle)
	self.setInVehicle(isInVehicle)
	self.setOutVehicle(not isInVehicle)
end

function EnvironmentMaskSystem:registerWeatherMaskModifier(modifierName, bit)
	local name = string.upper(modifierName)
	local bitflag = 2^bit

	for _, modifier in ipairs(self.weatherMaskModifiers) do
		if modifier.name == name then
			Logging.error("Weather mask modifier name '%s' already used", modifierName)

			return false
		end

		if modifier.bitflag == bitflag then
			Logging.error("Weather mask modifier '%s' bit '%d' already used for modifier '%s'", modifierName, bit, modifier.name)

			return false
		end
	end

	local modifier = {
		name = name,
		bitflag = bitflag
	}

	function modifier.updateFunc(isActive)
		if isActive then
			self.weatherMask = bitOR(self.weatherMask, modifier.bitflag)
		else
			self.weatherMask = bitAND(self.weatherMask, bitNOT(modifier.bitflag))
		end
	end

	table.insert(self.weatherMaskModifiers, modifier)

	self.weatherFlagNameToModifier[modifier.name] = modifier

	return modifier.updateFunc
end

function EnvironmentMaskSystem:registerViewerSpatialityMaskModifier(modifierName, bit)
	local name = string.upper(modifierName)
	local bitflag = 2^bit

	for _, modifier in ipairs(self.viewerSpatialityMaskModifiers) do
		if modifier.name == name then
			Logging.error("Given viewer spatiality mask modifier name '%s' already used", modifierName)

			return false
		end

		if modifier.bitflag == bitflag then
			Logging.error("Viewer spatiality mask modifier '%s' bit '%d' already used for modifier '%s'", modifierName, bit, modifier.name)

			return false
		end
	end

	local modifier = {
		name = name,
		bitflag = bitflag
	}

	function modifier.updateFunc(isActive)
		if isActive then
			self.viewerSpatialityMask = bitOR(self.viewerSpatialityMask, modifier.bitflag)
		else
			self.viewerSpatialityMask = bitAND(self.viewerSpatialityMask, bitNOT(modifier.bitflag))
		end
	end

	table.insert(self.viewerSpatialityMaskModifiers, modifier)

	self.viewerSpatialityFlagNameToModifier[modifier.name] = modifier

	return modifier.updateFunc
end

function EnvironmentMaskSystem:getWeatherModifierUpdateFuncFromFlagName(flagName)
	local modifier = self.weatherFlagNameToModifier[flagName]

	if modifier == nil or modifier.updateFunc == nil then
		Logging.error("No weather modifier registered for '%s'. Using empty update function", flagName)

		return function ()
		end
	end

	return modifier.updateFunc
end

function EnvironmentMaskSystem:getViewerSpatialityModifierUpdateFuncFromFlagName(flagName)
	local modifier = self.viewerSpatialityFlagNameToModifier[flagName]

	if modifier == nil or modifier.updateFunc == nil then
		Logging.error("No viewer spatiality modifier registered for '%s'. Using empty update function", flagName)

		return function ()
		end
	end

	return modifier.updateFunc
end

function EnvironmentMaskSystem:getWeatherMaskFromFlagNames(flagNames)
	if flagNames ~= nil and flagNames ~= "" then
		local mask = 0

		for _, flagName in pairs(string.split(flagNames:upper(), " ")) do
			local modifier = self.weatherFlagNameToModifier[flagName]

			if modifier ~= nil then
				mask = bitOR(mask, modifier.bitflag)
			else
				Logging.error("Unknown weather flag '%s'. Available flags: %s", flagName, table.concatKeys(self.weatherFlagNameToModifier, " "))
			end
		end

		return mask
	end

	return nil
end

function EnvironmentMaskSystem:consoleCommandToggleDebugView()
	self.isDebugViewActive = not self.isDebugViewActive

	if self.isDebugViewActive then
		self.mission:addDrawable(self)
	else
		self.mission:removeDrawable(self)
	end
end
