Lighting = {}
local Lighting_mt = Class(Lighting)

function Lighting.new(environment, customMt)
	local self = setmetatable({}, customMt or Lighting_mt)
	self.environment = environment
	self.updateInterval = 10000
	self.lastUpdateDayTime = 0
	self.cloudEnvMapIndex1 = 1
	self.cloudEnvMapIndex2 = 1
	self.cloudEnvMapBlendAlpha = 0

	return self
end

function Lighting:delete()
	self.environment = nil
end

function Lighting:load(xmlFile, baseKey)
	self.heightAngleLimitRotation = math.rad(xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotation", 60))
	self.heightAngleLimitRotationStart = math.rad(xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotationStart", 56))
	self.heightAngleLimitRotationEnd = math.rad(xmlFile:getFloat(baseKey .. ".sunRotation#heightAngleLimitRotationEnd", 80))
	self.sunRotationCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".sunRotation", true)
	self.moonBrightnessScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".moonBrightnessScale")
	self.moonSizeScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".moonSizeScale")
	self.sunIsPrimaryCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".sunIsPrimary")
	self.sunBrightnessScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".sunBrightnessScale")
	self.sunSizeScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".sunSizeScale")
	self.asymmetryFactorCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".asymmetryFactor")
	self.primaryExtraterrestrialColorCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".primaryExtraterrestrialColor")
	self.secondaryExtraterrestrialColorCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".secondaryExtraterrestrialColor")
	self.primaryDynamicLightingScaleCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".primaryDynamicLightingScale")
	self.lightScatteringRotationCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".lightScatteringRotation", true)
	self.autoExposureCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".autoExposure")

	if Platform.usesFixedExposure then
		self.fixedExposureCurveData = self:loadCurveDataFromXML(xmlFile, baseKey .. ".fixedExposure")
	end

	local day = xmlFile:getString(baseKey .. ".colorGrading.day#filename")

	if day ~= nil then
		self.colorGradingDay = Utils.getFilename(day, g_currentMission.baseDirectory)
	end

	local night = xmlFile:getString(baseKey .. ".colorGrading.night#filename")

	if night ~= nil then
		self.colorGradingNight = Utils.getFilename(night, g_currentMission.baseDirectory)
	else
		self.colorGradingNight = self.colorGradingDay
	end

	if g_currentMission.xmlFile ~= nil then
		self.envMapBasePath = xmlFile:getString(baseKey .. ".envMap#basePath")

		if self.envMapBasePath ~= nil then
			self.envMapBasePath = Utils.getFilename(self.envMapBasePath, g_currentMission.baseDirectory)
		end

		self.envMapTimes = {}

		xmlFile:iterate(baseKey .. ".envMap.timeProbe", function (_, timeProbeKey)
			local timeHours = xmlFile:getFloat(timeProbeKey .. "#timeHours")

			if timeHours ~= nil then
				table.insert(self.envMapTimes, timeHours)
			end
		end)
		table.sort(self.envMapTimes)

		self.envMapRenderingMode = false
	end

	self.albedoGroundColors = {
		[Environment.SEASON.SPRING] = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.spring#value", {
			0,
			0,
			0
		}, 3),
		[Environment.SEASON.SUMMER] = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.summer#value", {
			0,
			0,
			0
		}, 3),
		[Environment.SEASON.AUTUMN] = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.autumn#value", {
			0,
			0,
			0
		}, 3),
		[Environment.SEASON.WINTER] = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.winter#value", {
			0,
			0,
			0
		}, 3),
		snow = xmlFile:getVector(baseKey .. ".envAlbedoGroundColors.snow#value", {
			0,
			0,
			0
		}, 3)
	}
	self.lastUpdateDayTime = 0

	return true
end

function Lighting:loadCurveDataFromXML(xmlFile, baseKey, convertRadians)
	local data = {}

	xmlFile:iterate(baseKey .. ".key", function (_, timeKey)
		local time = xmlFile:getFloat(timeKey .. "#time")
		local values = string.split(xmlFile:getString(timeKey .. "#value"), " ")

		for j, value in ipairs(values) do
			local number = tonumber(value)

			if convertRadians then
				number = math.rad(number)
			end

			values[j] = number
		end

		table.insert(data, {
			time,
			values
		})
	end)

	return data
end

function Lighting:setEnvironment(environment)
	self.environment = environment
end

function Lighting:reset()
	resetAutoExposure()
end

function Lighting:setCloudEnvMapInfo(cloudEnvMapIndex1, cloudEnvMapIndex2, alpha)
	self.cloudEnvMapIndex1 = cloudEnvMapIndex1
	self.cloudEnvMapIndex2 = cloudEnvMapIndex2
	self.cloudEnvMapBlendAlpha = alpha
end

function Lighting:update(dt, force)
	local dayTime = self.environment.dayTime

	if force or g_sleepManager.isSleeping or self.updateInterval < math.abs(dayTime - self.lastUpdateDayTime) then
		local dayMinutes = dayTime / 60000

		self:updateSunLocation(dayTime, dayMinutes)
		self:updateEnvMap(self:getHardcodedFromTime(dayMinutes / 60) * 60, force)
		self:updateEnvAlbedo()
		self:updateAtmosphere(dayMinutes)

		local gradingFile1, gradingFile2, gradingAlpha = self.colorGradingFileCurve:get(dayMinutes)

		setColorGradingSettings(gradingFile1, gradingFile2, gradingAlpha)
		self:updateExposureSettings()

		self.lastUpdateDayTime = dayTime
	end
end

function Lighting:updateSunHeight()
	local _ = nil
	self.sunHeightAngle = self.environment.daylight:getSunHeightAngle()
	_, self.sunHeightLimit, _ = mathEulerRotateVector(self.sunHeightAngle, 0, self.heightAngleLimitRotation, 0, 0, 1)
	_, self.sunHeightLimitStart, _ = mathEulerRotateVector(self.sunHeightAngle, 0, self.heightAngleLimitRotationStart, 0, 0, 1)
	_, self.sunHeightLimitEnd, _ = mathEulerRotateVector(self.sunHeightAngle, 0, self.heightAngleLimitRotationEnd, 0, 0, 1)
end

function Lighting:updateSunLocation(dayTime, dayMinutes)
	local sunRotation = self.sunRotCurve:get(dayMinutes)
	local dx, dy, dz = mathEulerRotateVector(self.sunHeightAngle, 0, sunRotation, 0, 0, 1)

	if dy < self.sunHeightLimitStart then
		if dy <= self.sunHeightLimitEnd then
			dy = self.sunHeightLimit
		else
			local limitAlpha = (dy - self.sunHeightLimitEnd) / (self.sunHeightLimitStart - self.sunHeightLimitEnd)
			dy = self.sunHeightLimit + limitAlpha * (self.sunHeightLimitStart - self.sunHeightLimit)
		end

		local scale = math.sqrt((1 - dy * dy) / (dx * dx + dz * dz))
		dx = dx * scale
		dz = dz * scale
	end

	setDirection(self.sunLightId, dx, dy, dz, 0, 1, 0)

	local x = 0
	local y = nil

	if dayMinutes < 360 then
		y = 4.713 + 1.571 * dayMinutes / 360
	elseif dayMinutes < 1080 then
		y = 3.142 + 3.142 * (1 - (dayMinutes - 360) / 720)
	else
		y = 3.142 + 1.571 * (dayMinutes - 1080) / 360
	end

	if dayMinutes < 480 then
		x = x + 1.571 * (1 - dayMinutes / 480)
	elseif dayMinutes > 960 then
		x = x + 1.571 * (dayMinutes - 960) / 480
	end

	for _, fruitType in ipairs(g_fruitTypeManager:getFruitTypes()) do
		if fruitType.alignsToSun and fruitType.terrainDataPlaneId ~= nil then
			setFoliageShaderParameter(fruitType.terrainDataPlaneId, "plantRotate", x, y, 0, 0)
		end
	end
end

function Lighting:updateEnvMap(dayMinutes, force)
	if self.envMapBasePath == nil or #self.envMapTimes == 0 then
		return
	end

	local suffix = GS_IS_MOBILE_VERSION and "_uncompressed" or ""
	local envMapTime0Cloud0 = self.envMapBasePath .. "/" .. Lighting.getEnvMapBaseFilename(self.envMapTimes[1], 1) .. suffix .. ".png"
	local envMapTime0Cloud1 = envMapTime0Cloud0
	local envMapTime1Cloud0 = envMapTime0Cloud0
	local envMapTime1Cloud1 = envMapTime0Cloud0
	local blendTime = 0
	local blendCloud = 0

	if #self.envMapTimes > 1 then
		local dayHours = dayMinutes / 60
		local timeSecondIndex = 1

		for i, time in ipairs(self.envMapTimes) do
			if dayHours < time then
				timeSecondIndex = i

				break
			end
		end

		local timeFirstIndex = timeSecondIndex - 1

		if timeFirstIndex <= 0 then
			timeFirstIndex = #self.envMapTimes
		end

		local startTime = self.envMapTimes[timeFirstIndex]
		local endTime = self.envMapTimes[timeSecondIndex]
		blendTime = MathUtil.timeLerp(startTime, endTime, dayHours)
		local cloudFirstIndex = self.cloudEnvMapIndex1
		local cloudSecondIndex = self.cloudEnvMapIndex2
		blendCloud = self.cloudEnvMapBlendAlpha
		envMapTime0Cloud0 = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[timeFirstIndex], cloudFirstIndex) .. suffix .. ".png"
		envMapTime0Cloud1 = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[timeFirstIndex], cloudSecondIndex) .. suffix .. ".png"
		envMapTime1Cloud0 = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[timeSecondIndex], cloudFirstIndex) .. suffix .. ".png"
		envMapTime1Cloud1 = self.envMapBasePath .. Lighting.getEnvMapBaseFilename(self.envMapTimes[timeSecondIndex], cloudSecondIndex) .. suffix .. ".png"
	end

	local blendWeight0 = (1 - blendTime) * (1 - blendCloud)
	local blendWeight1 = (1 - blendTime) * blendCloud
	local blendWeight2 = blendTime * (1 - blendCloud)
	local blendWeight3 = blendTime * blendCloud

	if self.envMapRenderingMode then
		setEnvMap(envMapTime0Cloud0, envMapTime0Cloud1, envMapTime1Cloud0, envMapTime1Cloud1, 0, 0, 0, 0, true, false)
	else
		setEnvMap(envMapTime0Cloud0, envMapTime0Cloud1, envMapTime1Cloud0, envMapTime1Cloud1, blendWeight0, blendWeight1, blendWeight2, blendWeight3, force or false, false)
	end
end

function Lighting:updateEnvAlbedo()
	if SnowSystem.MIN_LAYER_HEIGHT <= self.environment.weather.snowHeight then
		local r, g, b = unpack(self.albedoGroundColors.snow)

		setEnvAlbedoGroundColor(r, g, b)
	else
		local r, g, b = unpack(self.albedoGroundColors[self.environment.currentVisualSeason])

		setEnvAlbedoGroundColor(r, g, b)
	end
end

function Lighting:updateAtmosphere(dayMinutes)
	local primaryScatteringRotation, secondaryScatteringRotation = self.lightScatteringRotCurve:get(dayMinutes)
	local pLscX, pLscY, pLscZ = mathEulerRotateVector(self.sunHeightAngle, 0, primaryScatteringRotation, 0, 0, 1)

	setLightScatteringDirection(self.sunLightId, pLscX, pLscY, pLscZ)

	local sLscX, sLscY, sLscZ = mathEulerRotateVector(self.sunHeightAngle, 0, secondaryScatteringRotation, 0, 0, 1)
	local sdr, sdg, sdb = self.secondaryExtraterrestrialColor:get(dayMinutes)

	setAtmosphereSecondaryLightSource(sLscX, sLscY, sLscZ, sdr, sdg, sdb)

	local asymmetryFactor = self.asymmetryFactorCurve:get(dayMinutes)

	setAtmosphereCornettAsymetryFactor(asymmetryFactor)

	local sunSizeScale = self.sunSizeScaleCurve:get(dayMinutes)

	setSunSizeScale(sunSizeScale)

	local moonSizeScale = self.moonSizeScaleCurve:get(dayMinutes)

	setMoonSizeScale(moonSizeScale)

	local sunIsPrimary = self.sunIsPrimaryCurve:get(dayMinutes) > 0.5

	setSunIsPrimary(sunIsPrimary)

	local moonBrightnessScale = self.moonBrightnessScaleCurve:get(dayMinutes)
	local sunBrightnessScale = self.sunBrightnessScaleCurve:get(dayMinutes)

	if self.envMapRenderingMode then
		if sunIsPrimary then
			sunBrightnessScale = sunBrightnessScale * 0.001
		else
			moonBrightnessScale = moonBrightnessScale * 0.001
		end
	end

	setSunBrightnessScale(sunBrightnessScale)
	setMoonBrightnessScale(moonBrightnessScale)

	local dr, dg, db = self.primaryExtraterrestrialColor:get(dayMinutes)
	local dynamicLightingScale = self.primaryDynamicLightingScale:get(dayMinutes)

	setLightColor(self.sunLightId, dr * dynamicLightingScale, dg * dynamicLightingScale, db * dynamicLightingScale)
	setLightScatteringColor(self.sunLightId, dr, dg, db)
end

function Lighting:updateExposureSettings()
	local dayMinutes = self.environment.dayTime / 60000
	local minExposure, maxExposure, keyValue = nil

	if Platform.usesFixedExposure then
		if self.fixedKeyValue == nil or self.fixedMinExposure == nil then
			minExposure = self.fixedExposureCurve:get(dayMinutes)
			maxExposure = minExposure
			keyValue = 0.18
		else
			keyValue = self.fixedKeyValue
			minExposure = self.fixedMinExposure
			maxExposure = self.fixedMaxExposure
		end
	elseif self.fixedKeyValue == nil then
		keyValue, minExposure, maxExposure = self.autoExposureCurve:get(dayMinutes)
	elseif self.fixedMinExposure == nil then
		local _ = nil
		_, minExposure, maxExposure = self.autoExposureCurve:get(dayMinutes)
		keyValue = self.fixedKeyValue
	else
		keyValue = self.fixedKeyValue
		minExposure = self.fixedMinExposure
		maxExposure = self.fixedMaxExposure
	end

	setExposureRange(keyValue, minExposure, maxExposure)
end

function Lighting:updateCurves()
	self.lightScatteringRotCurve = self:createCurve(linearInterpolator2, self.lightScatteringRotationCurveData)
	self.asymmetryFactorCurve = self:createCurve(linearInterpolator1, self.asymmetryFactorCurveData)
	self.sunBrightnessScaleCurve = self:createCurve(linearInterpolator1, self.sunBrightnessScaleCurveData)
	self.sunSizeScaleCurve = self:createCurve(linearInterpolator1, self.sunSizeScaleCurveData)
	self.moonBrightnessScaleCurve = self:createCurve(linearInterpolator1, self.moonBrightnessScaleCurveData)
	self.moonSizeScaleCurve = self:createCurve(linearInterpolator1, self.moonSizeScaleCurveData)
	self.sunIsPrimaryCurve = self:createCurve(linearInterpolator1, self.sunIsPrimaryCurveData)
	self.primaryDynamicLightingScale = self:createCurve(linearInterpolator1, self.primaryDynamicLightingScaleCurveData)
	self.primaryExtraterrestrialColor = self:createCurve(linearInterpolator3, self.primaryExtraterrestrialColorCurveData)
	self.secondaryExtraterrestrialColor = self:createCurve(linearInterpolator3, self.secondaryExtraterrestrialColorCurveData)
	self.autoExposureCurve = self:createCurve(linearInterpolator3, self.autoExposureCurveData)

	if Platform.usesFixedExposure then
		self.fixedExposureCurve = self:createCurve(linearInterpolator3, self.fixedExposureCurveData)
	end

	self.colorGradingFileCurve = self:getColorGradingFileCurve()

	self:updateSunHeight()

	self.sunRotCurve = self:createCurve(linearInterpolator1, self.sunRotationCurveData)
end

function Lighting:createCurve(interpolator, data)
	local curve = AnimCurve.new(interpolator)

	for i = 1, #data do
		local values = data[i]

		curve:addKeyframe({
			time = self:getTimeFromHardcoded(values[1]) * 60,
			unpack(values[2])
		})
	end

	return curve
end

function Lighting:getTimeFromHardcoded(hardcoded)
	local dayStart = self.dayStart
	local dayEnd = self.dayEnd
	local nightStart = self.nightStart
	local nightEnd = self.nightEnd

	if hardcoded < 6 then
		local alpha = hardcoded / 6

		return nightEnd * alpha
	elseif hardcoded >= 6 and hardcoded < 7 then
		local alpha = hardcoded - 6

		return (dayStart - nightEnd) * alpha + nightEnd
	elseif hardcoded >= 7 and hardcoded < 19 then
		local alpha = (hardcoded - 7) / 12

		return (dayEnd - dayStart) * alpha + dayStart
	elseif hardcoded >= 19 and hardcoded < 20 then
		local alpha = hardcoded - 19

		return (nightStart - dayEnd) * alpha + dayEnd
	elseif hardcoded >= 20 and hardcoded <= 24 then
		local alpha = (hardcoded - 20) / 4

		return (24 - nightStart) * alpha + nightStart
	end
end

function Lighting:getHardcodedFromTime(time)
	local dayStart = self.dayStart
	local dayEnd = self.dayEnd
	local nightStart = self.nightStart
	local nightEnd = self.nightEnd

	if time < nightEnd then
		local alpha = time / nightEnd

		return 6 * alpha
	elseif nightEnd <= time and time < dayStart then
		local alpha = (time - nightEnd) / (dayStart - nightEnd)

		return 1 * alpha + 6
	elseif dayStart <= time and time < dayEnd then
		local alpha = (time - dayStart) / (dayEnd - dayStart)

		return 12 * alpha + 7
	elseif dayEnd <= time and time < nightStart then
		local alpha = (time - dayEnd) / (nightStart - dayEnd)

		return 1 * alpha + 19
	else
		local alpha = (time - nightStart) / (24 - nightStart)

		return 4 * alpha + 20
	end
end

function Lighting:getColorGradingFileCurve()
	local curve = AnimCurve.new(Lighting.fileInterpolator)

	curve:addKeyframe({
		time = self:getTimeFromHardcoded(0) * 60,
		file = self.colorGradingNight
	})
	curve:addKeyframe({
		time = self:getTimeFromHardcoded(5) * 60,
		file = self.colorGradingNight
	})
	curve:addKeyframe({
		time = self:getTimeFromHardcoded(6) * 60,
		file = self.colorGradingDay
	})
	curve:addKeyframe({
		time = self:getTimeFromHardcoded(20) * 60,
		file = self.colorGradingDay
	})
	curve:addKeyframe({
		time = self:getTimeFromHardcoded(22) * 60,
		file = self.colorGradingNight
	})
	curve:addKeyframe({
		time = self:getTimeFromHardcoded(24) * 60,
		file = self.colorGradingNight
	})

	return curve
end

function Lighting:setDaylightTimes(dayStart, dayEnd, nightEnd, nightStart)
	if self.dayStart ~= dayStart and self.dayEnd ~= dayEnd and self.nightEnd ~= nightEnd and self.nightStart ~= nightStart then
		self.dayStart = dayStart
		self.dayEnd = dayEnd
		self.nightEnd = nightEnd
		self.nightStart = nightStart

		self:updateCurves()
	end
end

function Lighting:setFixedExposureSettings(keyValue, minExposure, maxExposure)
	if maxExposure == nil then
		maxExposure = minExposure
	end

	self.fixedKeyValue = keyValue
	self.fixedMinExposure = minExposure
	self.fixedMaxExposure = maxExposure
end

function Lighting.getEnvMapBaseFilename(dayTimeHours, cloudSetup)
	local hours, minutesPerc = math.modf(dayTimeHours)
	local minutes, seconds = math.modf(minutesPerc * 60)
	seconds = math.floor(seconds * 60)

	return string.format("%d_%d_%d_C%d", hours, minutes, seconds, cloudSetup)
end

function Lighting.fileInterpolator(first, second, alpha)
	return first.file, second.file, alpha
end
