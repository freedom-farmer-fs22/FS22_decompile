PlaceableSolarPanels = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(PlaceableIncomePerHour, specializations)
	end
}

function PlaceableSolarPanels.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getIncomePerHourFactor", PlaceableSolarPanels.getIncomePerHourFactor)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedHourChanged", PlaceableSolarPanels.getNeedHourChanged)
end

function PlaceableSolarPanels.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "updateHeadRotation", PlaceableSolarPanels.updateHeadRotation)
end

function PlaceableSolarPanels.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableSolarPanels)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableSolarPanels)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableSolarPanels)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableSolarPanels)
	SpecializationUtil.registerEventListener(placeableType, "onHourChanged", PlaceableSolarPanels)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableSolarPanels)
end

function PlaceableSolarPanels.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("SolarPanels")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".solarPanels#headNode", "Head Node")
	schema:register(XMLValueType.ANGLE, basePath .. ".solarPanels#randomHeadOffsetRange", "Range of random offset", 15)
	schema:register(XMLValueType.ANGLE, basePath .. ".solarPanels#rotationSpeed", "Rotation Speed (deg/sec)", 5)
	schema:setXMLSpecializationType()
end

function PlaceableSolarPanels.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("SolarPanels")
	schema:register(XMLValueType.FLOAT, basePath .. "#headRotationRandom", "Head random rotation")
	schema:setXMLSpecializationType()
end

function PlaceableSolarPanels:onLoad(savegame)
	local spec = self.spec_solarPanels
	local xmlFile = self.xmlFile
	spec.headNode = xmlFile:getValue("placeable.solarPanels#headNode", nil, self.components, self.i3dMappings)
	spec.randomHeadOffsetRange = xmlFile:getValue("placeable.solarPanels#randomHeadOffsetRange", 15)
	spec.rotationSpeed = xmlFile:getValue("placeable.solarPanels#rotationSpeed", 5) / 1000

	if spec.headNode ~= nil then
		local rotVariation = spec.randomHeadOffsetRange * 0.5
		spec.headRotationRandom = math.random(-1, 1) * rotVariation
		spec.currentRotation = spec.headRotationRandom
		spec.targetRotation = spec.headRotationRandom
	end
end

function PlaceableSolarPanels:onFinalizePlacement()
	self:updateHeadRotation()
end

function PlaceableSolarPanels:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_solarPanels
	local headRotationRandom = xmlFile:getValue(key .. "#headRotationRandom")

	if headRotationRandom == nil then
		spec.headRotationRandom = headRotationRandom
	end
end

function PlaceableSolarPanels:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_solarPanels

	if spec.headNode ~= nil then
		xmlFile:setValue(key .. "#headRotationRandom", spec.headRotationRandom)
	end
end

function PlaceableSolarPanels:onReadStream(streamId, connection)
	local spec = self.spec_solarPanels

	if spec.headNode ~= nil then
		spec.headRotationRandom = NetworkUtil.readCompressedAngle(streamId)
	end
end

function PlaceableSolarPanels:onWriteStream(streamId, connection)
	local spec = self.spec_solarPanels

	if spec.headNode ~= nil then
		NetworkUtil.writeCompressedAngle(streamId, spec.headRotationRandom)
	end
end

function PlaceableSolarPanels:onUpdate(dt)
	local spec = self.spec_solarPanels

	if spec.targetRotation ~= spec.currentRotation then
		local limitFunc = math.min
		local direction = 1

		if spec.targetRotation < spec.currentRotation then
			limitFunc = math.max
			direction = -1
		end

		spec.currentRotation = limitFunc(spec.currentRotation + spec.rotationSpeed * dt * direction, spec.targetRotation)
		local dx, _, dz = worldDirectionToLocal(getParent(spec.headNode), math.sin(spec.currentRotation), 0, math.cos(spec.currentRotation))

		setDirection(spec.headNode, dx, 0, dz, 0, 1, 0)

		if spec.targetRotation ~= spec.currentRotation then
			self:raiseActive()
		end
	end
end

function PlaceableSolarPanels:onHourChanged()
	self:updateHeadRotation()
end

function PlaceableSolarPanels:updateHeadRotation()
	local spec = self.spec_solarPanels

	if spec.headNode ~= nil and g_currentMission ~= nil and g_currentMission.environment ~= nil then
		local sunLight = g_currentMission.environment.lighting.sunLightId

		if sunLight ~= nil then
			local dx, _, dz = localDirectionToWorld(sunLight, 0, 0, 1)
			local headRotation = math.atan2(dx, dz)

			if math.abs(dx) > 0.3 then
				headRotation = headRotation + spec.headRotationRandom
				spec.targetRotation = headRotation

				self:raiseActive()
			end
		end
	end
end

function PlaceableSolarPanels:getIncomePerHourFactor(superFunc)
	local environment = g_currentMission.environment

	if not environment.isSunOn then
		return 0
	end

	local factor = superFunc(self)

	if environment.currentSeason == Environment.SEASON.WINTER then
		factor = factor * 0.75
	end

	if environment.weather:getIsRaining() then
		factor = factor * 0.1
	end

	return factor
end

function PlaceableSolarPanels:getNeedHourChanged(superFunc)
	return true
end
