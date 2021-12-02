LightingStatic = {}
local LightingStatic_mt = Class(LightingStatic, Lighting)

function LightingStatic.new(environment, customMt)
	local self = Lighting.new(environment, customMt or LightingStatic_mt)

	return self
end

function LightingStatic:load(xmlFile, baseKey)
	self.sunHeightAngle = math.rad(-50)
	self.heightAngleLimitRotation = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. ".sunRotation#heightAngleLimitRotation"), 60))
	self.heightAngleLimitRotationStart = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. ".sunRotation#heightAngleLimitRotationStart"), 56))
	self.heightAngleLimitRotationEnd = math.rad(Utils.getNoNil(getXMLFloat(xmlFile, baseKey .. ".sunRotation#heightAngleLimitRotationEnd"), 80))
	self.sunRotation = self:loadValueFromXML(xmlFile, baseKey .. ".sunRotation", true)
	self.moonBrightnessScale = self:loadValueFromXML(xmlFile, baseKey .. ".moonBrightnessScale")
	self.moonSizeScale = self:loadValueFromXML(xmlFile, baseKey .. ".moonSizeScale")
	self.sunIsPrimary = self:loadValueFromXML(xmlFile, baseKey .. ".sunIsPrimary")
	self.sunBrightnessScale = self:loadValueFromXML(xmlFile, baseKey .. ".sunBrightnessScale")
	self.sunSizeScale = self:loadValueFromXML(xmlFile, baseKey .. ".sunSizeScale")
	self.asymmetryFactor = self:loadValueFromXML(xmlFile, baseKey .. ".asymmetryFactor")
	self.primaryExtraterrestrialColor = self:loadValueFromXML(xmlFile, baseKey .. ".primaryExtraterrestrialColor")
	self.secondaryExtraterrestrialColor = self:loadValueFromXML(xmlFile, baseKey .. ".secondaryExtraterrestrialColor")
	self.primaryDynamicLightingScale = self:loadValueFromXML(xmlFile, baseKey .. ".primaryDynamicLightingScale")
	self.lightScatteringRotation = self:loadValueFromXML(xmlFile, baseKey .. ".lightScatteringRotation", true)
	self.autoExposure = self:loadValueFromXML(xmlFile, baseKey .. ".autoExposure")

	if Platform.usesFixedExposure then
		self.fixedExposure = self:loadValueFromXML(xmlFile, baseKey .. ".fixedExposure")
	end

	self.colorGrading = Utils.getFilename(getXMLString(xmlFile, baseKey .. ".colorGrading#filename"), g_currentMission.baseDirectory)
	local basePath = Utils.getFilename(getXMLString(xmlFile, baseKey .. ".envMap#basePath"), g_currentMission.baseDirectory)
	local suffix = GS_IS_MOBILE_VERSION and "_uncompressed" or ""
	self.envMap = basePath .. "/" .. Lighting.getEnvMapBaseFilename(0, 1) .. suffix .. ".png"
	self.albedoGroundColor = string.getVectorN(Utils.getNoNil(getXMLString(xmlFile, baseKey .. ".envAlbedoGroundColor#value"), "0 0 0"), 3)

	return true
end

function LightingStatic:loadValueFromXML(xmlFile, key, convertRadians)
	local values = string.split(getXMLString(xmlFile, key .. "#value"), " ")

	for i, value in ipairs(values) do
		local number = tonumber(value)

		if convertRadians then
			number = math.rad(number)
		end

		values[i] = number
	end

	return values
end

function LightingStatic:update(dt, force)
	if force then
		setEnvMap(self.envMap, self.envMap, self.envMap, self.envMap, 1, 0, 0, 0, force, true)
		setColorGradingSettings(self.colorGrading, self.colorGrading, 0)
		setEnvAlbedoGroundColor(unpack(self.albedoGroundColor))
		self:updateAtmosphere()
		self:updateExposureSettings()
	end
end

function LightingStatic:updateAtmosphere()
	local pLscX, pLscY, pLscZ = mathEulerRotateVector(self.sunHeightAngle, 0, self.lightScatteringRotation[1], 0, 0, 1)

	setLightScatteringDirection(self.sunLightId, pLscX, pLscY, pLscZ)

	local sLscX, sLscY, sLscZ = mathEulerRotateVector(self.sunHeightAngle, 0, self.lightScatteringRotation[2], 0, 0, 1)
	local sdr = self.secondaryExtraterrestrialColor[1]
	local sdg = self.secondaryExtraterrestrialColor[2]
	local sdb = self.secondaryExtraterrestrialColor[3]

	setAtmosphereSecondaryLightSource(sLscX, sLscY, sLscZ, sdr, sdg, sdb)
	setAtmosphereCornettAsymetryFactor(self.asymmetryFactor[1])
	setSunSizeScale(self.sunSizeScale[1])
	setMoonSizeScale(self.moonSizeScale[1])
	setSunIsPrimary(self.sunIsPrimary[1] == 1)

	local moonBrightnessScale = self.moonBrightnessScale[1]
	local sunBrightnessScale = self.sunBrightnessScale[1]

	if self.envMapRenderingMode then
		if self.sunIsPrimary[1] then
			sunBrightnessScale = sunBrightnessScale * 0.001
		else
			moonBrightnessScale = moonBrightnessScale * 0.001
		end
	end

	setSunBrightnessScale(sunBrightnessScale)
	setMoonBrightnessScale(moonBrightnessScale)

	local dr = self.primaryExtraterrestrialColor[1]
	local dg = self.primaryExtraterrestrialColor[2]
	local db = self.primaryExtraterrestrialColor[3]
	local dynamicLightingScale = self.primaryDynamicLightingScale[1]

	setLightColor(self.sunLightId, dr * dynamicLightingScale, dg * dynamicLightingScale, db * dynamicLightingScale)
	setLightScatteringColor(self.sunLightId, dr, dg, db)
end

function LightingStatic:updateExposureSettings()
	local minExposure, maxExposure, keyValue = nil

	if Platform.usesFixedExposure then
		if self.fixedKeyValue == nil or self.fixedMinExposure == nil then
			minExposure = self.fixedExposure[1]
			maxExposure = minExposure
			keyValue = 0.18
		else
			keyValue = self.fixedKeyValue
			minExposure = self.fixedMinExposure
			maxExposure = self.fixedMaxExposure
		end
	elseif self.fixedKeyValue == nil then
		maxExposure = self.autoExposure[3]
		minExposure = self.autoExposure[2]
		keyValue = self.autoExposure[1]
	elseif self.fixedMinExposure == nil then
		maxExposure = self.autoExposure[3]
		minExposure = self.autoExposure[2]
		keyValue = self.fixedKeyValue
	else
		keyValue = self.fixedKeyValue
		minExposure = self.fixedMinExposure
		maxExposure = self.fixedMaxExposure
	end

	setExposureRange(keyValue, minExposure, maxExposure)
end

function LightingStatic:updateCurves()
end

function LightingStatic:setFixedExposureSettings(keyValue, minExposure, maxExposure)
	LightingStatic:superClass().setFixedExposureSettings(self, keyValue, minExposure, maxExposure)
	self:update(1, true)
end
