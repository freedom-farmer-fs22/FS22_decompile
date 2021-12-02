PlaceableWindTurbine = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(PlaceableIncomePerHour, specializations)
	end
}

function PlaceableWindTurbine.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateHeadRotation", PlaceableWindTurbine.updateHeadRotation)
	SpecializationUtil.registerFunction(placeableType, "updateRotorRotSpeed", PlaceableWindTurbine.updateRotorRotSpeed)
	SpecializationUtil.registerFunction(placeableType, "setWindValues", PlaceableWindTurbine.setWindValues)
	SpecializationUtil.registerFunction(placeableType, "getWindTurbineLoad", PlaceableWindTurbine.getWindTurbineLoad)
end

function PlaceableWindTurbine.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getIncomePerHourFactor", PlaceableWindTurbine.getIncomePerHourFactor)
end

function PlaceableWindTurbine.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableWindTurbine)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableWindTurbine)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableWindTurbine)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableWindTurbine)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableWindTurbine)
end

function PlaceableWindTurbine.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("WindTurbine")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".windTurbine#headNode", "Head node")
	schema:register(XMLValueType.BOOL, basePath .. ".windTurbine#headAdjustToWind", "Adjust head node to current wind direction")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".windTurbine#rotationNode", "Rotor rotation node, rotated on z-axis")
	schema:register(XMLValueType.FLOAT, basePath .. ".windTurbine#optimalWindSpeed", "Wind speed in m/s at which rotor reaches max rpm")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".windTurbine.sounds", "idle")
	AnimationManager.registerAnimationNodesXMLPaths(schema, basePath .. ".windTurbine.animationNodes")
	schema:setXMLSpecializationType()
end

function PlaceableWindTurbine.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("WindTurbine")
	schema:register(XMLValueType.ANGLE, basePath .. "#headRotation", "Current head rotation")
	schema:setXMLSpecializationType()
end

function PlaceableWindTurbine:onLoad(savegame)
	local spec = self.spec_windTurbine
	local headNode = self.xmlFile:getValue("placeable.windTurbine#headNode", nil, self.components, self.i3dMappings)

	if headNode ~= nil then
		spec.headNode = headNode
		spec.headAdjustToWind = self.xmlFile:getValue("placeable.windTurbine#headAdjustToWind", false)
		spec.headRotation = 0
	end

	spec.rotorOptimalWindSpeed = self.xmlFile:getValue("placeable.windTurbine#optimalWindSpeed", 15)
	spec.rotSpeedFactor = 1

	if self.isClient then
		spec.samples = {
			idle = g_soundManager:loadSampleFromXML(self.xmlFile, "placeable.windTurbine.sounds", "idle", self.baseDirectory, self.components, 1, AudioGroup.ENVIRONMENT, self.i3dMappings, self)
		}
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "placeable.windTurbine.animationNodes", self.components, self, self.i3dMappings)

		for _, anim in ipairs(spec.animationNodes) do
			function anim.speedFunc()
				return spec.rotSpeedFactor
			end
		end
	end
end

function PlaceableWindTurbine:onDelete()
	g_currentMission.environment.weather.windUpdater:removeWindChangedListener(self)

	local spec = self.spec_windTurbine

	g_soundManager:deleteSamples(spec.samples)
	g_animationManager:deleteAnimations(spec.animationNodes)
end

function PlaceableWindTurbine:onFinalizePlacement()
	local spec = self.spec_windTurbine
	local windUpdater = g_currentMission.environment.weather.windUpdater

	windUpdater:addWindChangedListener(self)

	local windDirX, windDirZ, windVelocity = windUpdater:getCurrentValues()

	if spec.headNode ~= nil then
		spec.headRotation = MathUtil.getYRotationFromDirection(windDirX, windDirZ)

		if not spec.headAdjustToWind then
			local rotVariation = 0.2
			spec.headRotation = 0.7 + math.random() * 2 * rotVariation - rotVariation
		end

		self:updateHeadRotation()
	end

	self:updateRotorRotSpeed(windVelocity)
	g_animationManager:startAnimations(spec.animationNodes)
end

function PlaceableWindTurbine:onReadStream(streamId, connection)
	local spec = self.spec_windTurbine

	if spec.headNode ~= nil then
		spec.headRotation = NetworkUtil.readCompressedAngle(streamId)
	end
end

function PlaceableWindTurbine:onWriteStream(streamId, connection)
	local spec = self.spec_windTurbine

	if spec.headNode ~= nil then
		NetworkUtil.writeCompressedAngle(streamId, spec.headRotation)
	end
end

function PlaceableWindTurbine:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_windTurbine

	if spec.headNode ~= nil then
		spec.headRotation = xmlFile:getValue(key .. "#headRotation")

		self:updateHeadRotation()
	end
end

function PlaceableWindTurbine:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_windTurbine

	if spec.headNode ~= nil then
		xmlFile:setValue(key .. "#headRotation", spec.headRotation)
	end
end

function PlaceableWindTurbine:updateHeadRotation()
	local spec = self.spec_windTurbine

	if spec.headNode ~= nil then
		setWorldRotation(spec.headNode, 0, spec.headRotation, 0)
	end
end

function PlaceableWindTurbine:updateRotorRotSpeed(windVelocity)
	local spec = self.spec_windTurbine
	spec.rotSpeedFactor = MathUtil.clamp(windVelocity / spec.rotorOptimalWindSpeed, 0, 1)

	if self.isClient then
		if spec.rotSpeedFactor > 0 then
			if not g_soundManager:getIsSamplePlaying(spec.samples.idle) then
				g_soundManager:playSample(spec.samples.idle, 0)
			end
		elseif g_soundManager:getIsSamplePlaying(spec.samples.idle) then
			g_soundManager:stopSample(spec.samples.idle)
		end
	end
end

function PlaceableWindTurbine:setWindValues(windDirX, windDirZ, windVelocity, cirrusCloudSpeedFactor)
	local spec = self.spec_windTurbine

	if spec.headAdjustToWind and spec.headNode ~= nil then
		spec.headRotation = MathUtil.getYRotationFromDirection(windDirX, windDirZ)

		self:updateHeadRotation()
	end

	self:updateRotorRotSpeed(windVelocity)
end

function PlaceableWindTurbine:getWindTurbineLoad()
	local spec = self.spec_windTurbine

	return spec.rotSpeedFactor
end

g_soundManager:registerModifierType("WIND_TURBINE_LOAD", PlaceableWindTurbine.getWindTurbineLoad)

function PlaceableWindTurbine:getIncomePerHourFactor(superFunc)
	local factor = superFunc(self)

	return factor * self.spec_windTurbine.rotSpeedFactor
end
