SpeedRotatingParts = {
	DEFAULT_MAX_UPDATE_DISTANCE = 50,
	SPEED_ROTATING_PART_XML_KEY = "vehicle.speedRotatingParts.speedRotatingPart(?)",
	prerequisitesPresent = function (specializations)
		return true
	end
}

function SpeedRotatingParts.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("SpeedRotatingParts")
	schema:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#node", "Speed rotating part node")
	schema:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#shaderNode", "Speed rotating part shader node")
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#useRotation", "Use shader rotation", true)
	schema:register(XMLValueType.STRING, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#vtxPositionArrayFilename", "Path to vertex position filename (If this is set the shader variation 'vtxRotate_colorMask' is forced)")
	schema:register(XMLValueType.VECTOR_2, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#scrollScale", "Shader scroll speed")
	schema:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#shaderComponent", "Shader parameter component to control", "Default based on available shader attributes")
	schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#scrollLength", "Shader scroll length")
	schema:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#driveNode", "Drive node to apply x drive", "speedRotatingPart#node")
	schema:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#refComponentIndex", "Reference component index")
	schema:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#wheelIndex", "Reference wheel index")
	schema:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#dirRefNode", "Direction reference node")
	schema:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#dirFrameNode", "Direction reference frame")
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#alignDirection", "Align direction", false)
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#applySteeringAngle", "Apply steering angle", false)
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#useWheelReprTranslation", "Apply wheel repr translation", true)
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#updateXDrive", "Update X drive", true)
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#versatileYRot", "Versatile Y rot", false)
	schema:register(XMLValueType.ANGLE, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#minYRot", "Min. Y rotation")
	schema:register(XMLValueType.ANGLE, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#maxYRot", "Max. Y rotation")
	schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#wheelScale", "Wheel scale")
	schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#radius", "Radius", 1)
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#onlyActiveWhenLowered", "Only active if lowered", false)
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#stopIfNotActive", "Stop if not active", false)
	schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#fadeOutTime", "Fade out time", 3)
	schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#activationSpeed", "Min. speed for activation", 1)
	schema:register(XMLValueType.NODE_INDEX, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#speedReferenceNode", "Speed reference node")
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#hasTireTracks", "Has Tire Tracks", false)
	schema:register(XMLValueType.INT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#tireTrackAtlasIndex", "Index on tire track atlas", 0)
	schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#tireTrackWidth", "Width of tire tracks", 0.5)
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#tireTrackInverted", "Tire track texture inverted", false)
	schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#maxUpdateDistance", "Max. distance from current camera to vehicle to update part", SpeedRotatingParts.DEFAULT_MAX_UPDATE_DISTANCE)
	schema:setXMLSpecializationType()
end

function SpeedRotatingParts.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadSpeedRotatingPartFromXML", SpeedRotatingParts.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsSpeedRotatingPartActive", SpeedRotatingParts.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerFunction(vehicleType, "getSpeedRotatingPartDirection", SpeedRotatingParts.getSpeedRotatingPartDirection)
	SpecializationUtil.registerFunction(vehicleType, "updateSpeedRotatingPart", SpeedRotatingParts.updateSpeedRotatingPart)
end

function SpeedRotatingParts.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "validateWashableNode", SpeedRotatingParts.validateWashableNode)
end

function SpeedRotatingParts.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SpeedRotatingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", SpeedRotatingParts)
end

function SpeedRotatingParts:onLoad(savegame)
	local spec = self.spec_speedRotatingParts

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.speedRotatingParts.speedRotatingPart(0)#index", "vehicle.speedRotatingParts.speedRotatingPart(0)#node")

	local maxUpdateDistance = nil
	spec.individualUpdateDistance = false
	spec.speedRotatingParts = {}
	local i = 0

	while true do
		local baseName = string.format("vehicle.speedRotatingParts.speedRotatingPart(%d)", i)

		if not self.xmlFile:hasProperty(baseName) then
			break
		end

		local speedRotatingPart = {}

		if self:loadSpeedRotatingPartFromXML(speedRotatingPart, self.xmlFile, baseName) then
			table.insert(spec.speedRotatingParts, speedRotatingPart)

			if maxUpdateDistance ~= nil and maxUpdateDistance ~= speedRotatingPart.maxUpdateDistance then
				spec.individualUpdateDistance = true
			end

			maxUpdateDistance = speedRotatingPart.maxUpdateDistance
		end

		i = i + 1
	end

	spec.maxUpdateDistance = maxUpdateDistance or SpeedRotatingParts.DEFAULT_MAX_UPDATE_DISTANCE
	spec.dirtyFlag = self:getNextDirtyFlag()

	if #spec.speedRotatingParts == 0 then
		SpecializationUtil.removeEventListener(self, "onReadStream", SpeedRotatingParts)
		SpecializationUtil.removeEventListener(self, "onWriteStream", SpeedRotatingParts)
		SpecializationUtil.removeEventListener(self, "onReadUpdateStream", SpeedRotatingParts)
		SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", SpeedRotatingParts)
		SpecializationUtil.removeEventListener(self, "onUpdate", SpeedRotatingParts)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", SpeedRotatingParts)
	end
end

function SpeedRotatingParts:onReadStream(streamId, connection)
	local spec = self.spec_speedRotatingParts

	for i = 1, #spec.speedRotatingParts do
		local speedRotatingPart = spec.speedRotatingParts[i]

		if speedRotatingPart.versatileYRot then
			local yRot = streamReadUIntN(streamId, 9)
			speedRotatingPart.steeringAngle = yRot / 511 * math.pi * 2
		end
	end
end

function SpeedRotatingParts:onWriteStream(streamId, connection)
	local spec = self.spec_speedRotatingParts

	for i = 1, #spec.speedRotatingParts do
		local speedRotatingPart = spec.speedRotatingParts[i]

		if speedRotatingPart.versatileYRot then
			streamWriteUIntN(streamId, MathUtil.clamp(math.floor(speedRotatingPart.steeringAngle / (math.pi * 2) * 511), 0, 511), 9)
		end
	end
end

function SpeedRotatingParts:onReadUpdateStream(streamId, timestamp, connection)
	if connection.isServer then
		local hasUpdate = streamReadBool(streamId)

		if hasUpdate then
			local spec = self.spec_speedRotatingParts

			for i = 1, #spec.speedRotatingParts do
				local speedRotatingPart = spec.speedRotatingParts[i]

				if speedRotatingPart.versatileYRot then
					local yRot = streamReadUIntN(streamId, 9)
					speedRotatingPart.steeringAngle = yRot / 511 * math.pi * 2
				end
			end
		end
	end
end

function SpeedRotatingParts:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer then
		local spec = self.spec_speedRotatingParts

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			for i = 1, #spec.speedRotatingParts do
				local speedRotatingPart = spec.speedRotatingParts[i]

				if speedRotatingPart.versatileYRot then
					local yRot = speedRotatingPart.steeringAngle % (math.pi * 2)

					streamWriteUIntN(streamId, MathUtil.clamp(math.floor(yRot / (math.pi * 2) * 511), 0, 511), 9)
				end
			end
		end
	end
end

function SpeedRotatingParts:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_speedRotatingParts

	if spec.individualUpdateDistance or self.currentUpdateDistance < spec.maxUpdateDistance then
		for i = 1, #spec.speedRotatingParts do
			local speedRotatingPart = spec.speedRotatingParts[i]

			if (not spec.individualUpdateDistance or self.currentUpdateDistance < speedRotatingPart.maxUpdateDistance) and (speedRotatingPart.isActive or speedRotatingPart.lastSpeed ~= 0 and not speedRotatingPart.stopIfNotActive) then
				self:updateSpeedRotatingPart(speedRotatingPart, dt, speedRotatingPart.isActive)
			end
		end
	end
end

function SpeedRotatingParts:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_speedRotatingParts

	if spec.individualUpdateDistance or self.currentUpdateDistance < spec.maxUpdateDistance then
		for i = 1, #spec.speedRotatingParts do
			local speedRotatingPart = spec.speedRotatingParts[i]

			if not spec.individualUpdateDistance or self.currentUpdateDistance < speedRotatingPart.maxUpdateDistance then
				speedRotatingPart.isActive = self:getIsSpeedRotatingPartActive(speedRotatingPart)
			end
		end
	end
end

function SpeedRotatingParts:loadSpeedRotatingPartFromXML(speedRotatingPart, xmlFile, key)
	speedRotatingPart.repr = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	speedRotatingPart.shaderNode = xmlFile:getValue(key .. "#shaderNode", nil, self.components, self.i3dMappings)
	speedRotatingPart.shaderParameterName = "offsetUV"
	speedRotatingPart.shaderParameterPrevName = nil
	speedRotatingPart.shaderParameterComponent = 3
	speedRotatingPart.shaderParameterSpeedScale = 1
	speedRotatingPart.shaderParameterValues = {
		0,
		0,
		0,
		0
	}

	if speedRotatingPart.shaderNode ~= nil then
		speedRotatingPart.useShaderRotation = xmlFile:getValue(key .. "#useRotation", true)
		speedRotatingPart.scrollScale = xmlFile:getValue(key .. "#scrollScale", "1 0", true)
		speedRotatingPart.scrollLength = xmlFile:getValue(key .. "#scrollLength")
		local vtxPositionArrayFilename = xmlFile:getValue(key .. "#vtxPositionArrayFilename")

		if vtxPositionArrayFilename ~= nil then
			vtxPositionArrayFilename = Utils.getFilename(vtxPositionArrayFilename, self.baseDirectory)
			local materialId = getMaterial(speedRotatingPart.shaderNode, 0)
			local curVariation = getMaterialCustomShaderVariation(materialId)

			if curVariation ~= "vtxRotate_colorMask" then
				materialId = setMaterialCustomShaderVariation(materialId, "vtxRotate_colorMask", false)
				materialId = setMaterialCustomMapFromFile(materialId, "mTrackArray", vtxPositionArrayFilename, true, false, true)
			else
				materialId = setMaterialCustomMapFromFile(materialId, "mTrackArray", vtxPositionArrayFilename, true, false, false)
			end

			setMaterial(speedRotatingPart.shaderNode, materialId, 0)
		end

		if getHasShaderParameter(speedRotatingPart.shaderNode, "rotationAngle") then
			speedRotatingPart.shaderParameterName = "rotationAngle"
			speedRotatingPart.shaderParameterPrevName = "prevRotationAngle"
			speedRotatingPart.shaderParameterComponent = 1
			speedRotatingPart.shaderParameterSpeedScale = -1
		end

		if getHasShaderParameter(speedRotatingPart.shaderNode, "scrollPosition") then
			speedRotatingPart.shaderParameterName = "scrollPosition"
			speedRotatingPart.shaderParameterPrevName = "prevScrollPosition"
			speedRotatingPart.shaderParameterComponent = 1
			speedRotatingPart.shaderParameterSpeedScale = 1
		end

		speedRotatingPart.shaderParameterComponent = xmlFile:getValue(key .. "#shaderComponent", speedRotatingPart.shaderParameterComponent)
	end

	if speedRotatingPart.repr == nil and speedRotatingPart.shaderNode == nil then
		Logging.xmlWarning(self.xmlFile, "Invalid speedRotationPart node '%s' in '%s'", tostring(getXMLString(xmlFile.handle, key .. "#node") or getXMLString(xmlFile.handle, key .. "#shaderNode")), key)

		return false
	end

	speedRotatingPart.driveNode = xmlFile:getValue(key .. "#driveNode", speedRotatingPart.repr, self.components, self.i3dMappings)
	local componentIndex = xmlFile:getValue(key .. "#refComponentIndex")

	if componentIndex ~= nil and self.components[componentIndex] ~= nil then
		speedRotatingPart.componentNode = self.components[componentIndex].node
	else
		local node = Utils.getNoNil(speedRotatingPart.driveNode, speedRotatingPart.shaderNode)
		speedRotatingPart.componentNode = self:getParentComponent(node)
	end

	speedRotatingPart.xDrive = 0
	local wheelIndex = xmlFile:getValue(key .. "#wheelIndex")

	if wheelIndex ~= nil then
		if self.getWheels == nil then
			Logging.xmlWarning(self.xmlFile, "wheelIndex for speedRotatingPart '%s' given, but no wheels loaded/defined", key)
		else
			local wheels = self:getWheels()
			local wheel = wheels[wheelIndex]

			if wheel == nil then
				Logging.xmlWarning(self.xmlFile, "Invalid wheel index '%s' for speedRotatingPart '%s'", tostring(wheelIndex), key)

				return false
			end

			if not wheel.isSynchronized then
				Logging.xmlWarning(self.xmlFile, "Referenced wheel with index '%s' for speedRotatingPart '%s' is not synchronized in multiplayer", tostring(wheelIndex), key)
			end

			speedRotatingPart.wheel = wheel
			speedRotatingPart.lastWheelXRot = nil
			speedRotatingPart.hasTireTracks = xmlFile:getValue(key .. "#hasTireTracks", false)
			speedRotatingPart.tireTrackAtlasIndex = xmlFile:getValue(key .. "#tireTrackAtlasIndex", 0)
			speedRotatingPart.tireTrackWidth = xmlFile:getValue(key .. "#tireTrackWidth", 0.5)
			speedRotatingPart.tireTrackInverted = xmlFile:getValue(key .. "#tireTrackInverted", false)

			if speedRotatingPart.hasTireTracks then
				local function activeFunc()
					return self:getIsSpeedRotatingPartActive(speedRotatingPart)
				end

				speedRotatingPart.tireTrackNodeIndex = self:addTireTrackNode(wheel, true, speedRotatingPart.componentNode, speedRotatingPart.repr, speedRotatingPart.tireTrackAtlasIndex, speedRotatingPart.tireTrackWidth, wheel.radius, 0, speedRotatingPart.tireTrackInverted, activeFunc)
			end
		end
	end

	speedRotatingPart.dirRefNode = xmlFile:getValue(key .. "#dirRefNode", nil, self.components, self.i3dMappings)
	speedRotatingPart.dirFrameNode = xmlFile:getValue(key .. "#dirFrameNode", nil, self.components, self.i3dMappings)
	speedRotatingPart.alignDirection = xmlFile:getValue(key .. "#alignDirection", false)
	speedRotatingPart.applySteeringAngle = xmlFile:getValue(key .. "#applySteeringAngle", false)
	speedRotatingPart.useWheelReprTranslation = xmlFile:getValue(key .. "#useWheelReprTranslation", true)
	speedRotatingPart.updateXDrive = xmlFile:getValue(key .. "#updateXDrive", true)
	speedRotatingPart.versatileYRot = xmlFile:getValue(key .. "#versatileYRot", false)

	if speedRotatingPart.versatileYRot and speedRotatingPart.repr == nil then
		Logging.xmlWarning(self.xmlFile, "Versatile speedRotationPart '%s' does not support shaderNodes", key)

		return false
	end

	speedRotatingPart.minYRot = xmlFile:getValue(key .. "#minYRot")
	speedRotatingPart.maxYRot = xmlFile:getValue(key .. "#maxYRot")
	speedRotatingPart.steeringAngle = 0
	speedRotatingPart.steeringAngleSent = 0
	speedRotatingPart.wheelScale = xmlFile:getValue(key .. "#wheelScale")

	if speedRotatingPart.wheelScale == nil then
		local baseRadius = 1
		local radius = 1

		if speedRotatingPart.wheel ~= nil then
			baseRadius = speedRotatingPart.wheel.radius
			radius = speedRotatingPart.wheel.radius
		end

		speedRotatingPart.wheelScale = baseRadius / xmlFile:getValue(key .. "#radius", radius)
	end

	speedRotatingPart.wheelScaleBackup = speedRotatingPart.wheelScale
	speedRotatingPart.onlyActiveWhenLowered = xmlFile:getValue(key .. "#onlyActiveWhenLowered", false)
	speedRotatingPart.stopIfNotActive = xmlFile:getValue(key .. "#stopIfNotActive", false)
	speedRotatingPart.fadeOutTime = xmlFile:getValue(key .. "#fadeOutTime", 3) * 1000
	speedRotatingPart.activationSpeed = xmlFile:getValue(key .. "#activationSpeed", 1)
	speedRotatingPart.speedReferenceNode = xmlFile:getValue(key .. "#speedReferenceNode", nil, self.components, self.i3dMappings)

	if speedRotatingPart.speedReferenceNode ~= nil and speedRotatingPart.speedReferenceNode == speedRotatingPart.driveNode then
		Logging.xmlWarning(self.xmlFile, "Ignoring speedRotationPart '%s' because speedReferenceNode is identical with driveNode. Need to be different!", key)

		return false
	end

	speedRotatingPart.lastSpeed = 0
	speedRotatingPart.lastDir = 1
	speedRotatingPart.maxUpdateDistance = xmlFile:getValue(key .. "#maxUpdateDistance", SpeedRotatingParts.DEFAULT_MAX_UPDATE_DISTANCE)

	return true
end

function SpeedRotatingParts:getIsSpeedRotatingPartActive(speedRotatingPart)
	if speedRotatingPart.onlyActiveWhenLowered then
		if self.getIsLowered ~= nil and not self:getIsLowered() then
			return false
		else
			return true
		end
	end

	return true
end

function SpeedRotatingParts:getSpeedRotatingPartDirection(speedRotatingPart)
	return 1
end

function SpeedRotatingParts:updateSpeedRotatingPart(speedRotatingPart, dt, isPartActive)
	local spec = self.spec_speedRotatingParts
	local speed = speedRotatingPart.lastSpeed
	local dir = speedRotatingPart.lastDir

	if speedRotatingPart.repr ~= nil then
		local _ = nil
		_, speedRotatingPart.steeringAngle, _ = getRotation(speedRotatingPart.repr)
	end

	if isPartActive then
		if speedRotatingPart.wheel ~= nil then
			if speedRotatingPart.lastWheelXRot == nil then
				speedRotatingPart.lastWheelXRot = speedRotatingPart.wheel.netInfo.xDrive
			end

			local rotDiff = speedRotatingPart.wheel.netInfo.xDrive - speedRotatingPart.lastWheelXRot

			if math.pi < rotDiff then
				rotDiff = rotDiff - 2 * math.pi
			elseif rotDiff < -math.pi then
				rotDiff = rotDiff + 2 * math.pi
			end

			speed = math.abs(rotDiff)
			dir = MathUtil.sign(rotDiff)
			speedRotatingPart.lastWheelXRot = speedRotatingPart.wheel.netInfo.xDrive
			local _ = nil
			_, speedRotatingPart.steeringAngle, _ = getRotation(speedRotatingPart.wheel.repr)
		elseif speedRotatingPart.speedReferenceNode ~= nil then
			local newX, newY, newZ = getWorldTranslation(speedRotatingPart.speedReferenceNode)

			if speedRotatingPart.lastPosition == nil then
				speedRotatingPart.lastPosition = {
					newX,
					newY,
					newZ
				}
			end

			local dx, dy, dz = worldDirectionToLocal(speedRotatingPart.speedReferenceNode, newX - speedRotatingPart.lastPosition[1], newY - speedRotatingPart.lastPosition[2], newZ - speedRotatingPart.lastPosition[3])
			speed = MathUtil.vector3Length(dx, dy, dz)

			if dz > 0.001 then
				dir = 1
			elseif dz < -0.001 then
				dir = -1
			else
				dir = 0
			end

			speedRotatingPart.lastPosition[3] = newZ
			speedRotatingPart.lastPosition[2] = newY
			speedRotatingPart.lastPosition[1] = newX
		else
			speed = self.lastSpeedReal * dt
			dir = self.movingDirection
		end

		speedRotatingPart.brakeForce = speed * dt / speedRotatingPart.fadeOutTime
	else
		speed = math.max(speed - speedRotatingPart.brakeForce, 0)
		speedRotatingPart.lastWheelXRot = nil
	end

	speedRotatingPart.lastSpeed = speed
	speedRotatingPart.lastDir = dir

	if speedRotatingPart.updateXDrive then
		speedRotatingPart.xDrive = (speedRotatingPart.xDrive + speed * dir * self:getSpeedRotatingPartDirection(speedRotatingPart) * speedRotatingPart.wheelScale) % (2 * math.pi)
	end

	if speedRotatingPart.versatileYRot then
		if speed > 0.0017 and self.isServer and speedRotatingPart.activationSpeed < self:getLastSpeed(true) then
			local posX, posY, posZ = localToLocal(speedRotatingPart.repr, speedRotatingPart.componentNode, 0, 0, 0)
			speedRotatingPart.steeringAngle = Utils.getVersatileRotation(speedRotatingPart.repr, speedRotatingPart.componentNode, dt, posX, posY, posZ, speedRotatingPart.steeringAngle, speedRotatingPart.minYRot, speedRotatingPart.maxYRot)

			if math.abs(speedRotatingPart.steeringAngleSent - speedRotatingPart.steeringAngle) > 0.1 then
				speedRotatingPart.steeringAngleSent = speedRotatingPart.steeringAngle

				self:raiseDirtyFlags(spec.dirtyFlag)
			end
		end
	else
		if speedRotatingPart.componentNode ~= nil and speedRotatingPart.dirRefNode ~= nil and not speedRotatingPart.alignDirection then
			speedRotatingPart.steeringAngle = Utils.getYRotationBetweenNodes(speedRotatingPart.componentNode, speedRotatingPart.dirRefNode)
			local _, yTrans, _ = localToLocal(speedRotatingPart.driveNode, speedRotatingPart.wheel.driveNode, 0, 0, 0)

			setTranslation(speedRotatingPart.driveNode, 0, yTrans, 0)
		end

		if speedRotatingPart.dirRefNode ~= nil and speedRotatingPart.alignDirection then
			local upX, upY, upZ = localDirectionToWorld(speedRotatingPart.dirFrameNode, 0, 1, 0)
			local dirX, dirY, dirZ = localDirectionToWorld(speedRotatingPart.dirRefNode, 0, 0, 1)

			I3DUtil.setWorldDirection(speedRotatingPart.repr, dirX, dirY, dirZ, upX, upY, upZ, 2)

			if speedRotatingPart.wheel ~= nil and speedRotatingPart.useWheelReprTranslation then
				local _, yTrans, _ = localToLocal(speedRotatingPart.wheel.driveNode, getParent(speedRotatingPart.repr), 0, 0, 0)

				setTranslation(speedRotatingPart.repr, 0, yTrans, 0)
			end
		end
	end

	if speedRotatingPart.driveNode ~= nil then
		if speedRotatingPart.repr == speedRotatingPart.driveNode then
			local steeringAngle = speedRotatingPart.steeringAngle

			if not speedRotatingPart.applySteeringAngle then
				steeringAngle = 0
			end

			setRotation(speedRotatingPart.repr, speedRotatingPart.xDrive, steeringAngle, 0)
		else
			if not speedRotatingPart.alignDirection and (speedRotatingPart.versatileYRot or speedRotatingPart.applySteeringAngle) then
				setRotation(speedRotatingPart.repr, 0, speedRotatingPart.steeringAngle, 0)
			end

			setRotation(speedRotatingPart.driveNode, speedRotatingPart.xDrive, 0, 0)
		end
	end

	if speedRotatingPart.shaderNode ~= nil then
		if speedRotatingPart.useShaderRotation then
			local values = speedRotatingPart.shaderParameterValues

			if speedRotatingPart.scrollLength ~= nil then
				values[speedRotatingPart.shaderParameterComponent] = speedRotatingPart.xDrive * speedRotatingPart.shaderParameterSpeedScale % speedRotatingPart.scrollLength
			else
				values[speedRotatingPart.shaderParameterComponent] = speedRotatingPart.xDrive * speedRotatingPart.shaderParameterSpeedScale
			end

			if speedRotatingPart.shaderParameterPrevName ~= nil then
				g_animationManager:setPrevShaderParameter(speedRotatingPart.shaderNode, speedRotatingPart.shaderParameterName, values[1], values[2], values[3], values[4], false, speedRotatingPart.shaderParameterPrevName)
			else
				setShaderParameter(speedRotatingPart.shaderNode, speedRotatingPart.shaderParameterName, values[1], values[2], values[3], values[4], false)
			end
		else
			local pos = speedRotatingPart.xDrive % math.pi / (2 * math.pi)

			setShaderParameter(speedRotatingPart.shaderNode, "offsetUV", pos * speedRotatingPart.scrollScale[1], pos * speedRotatingPart.scrollScale[2], 0, 0, false)
		end
	end
end

function SpeedRotatingParts:validateWashableNode(superFunc, node)
	local spec = self.spec_speedRotatingParts

	for _, speedRotatingPart in pairs(spec.speedRotatingParts) do
		if speedRotatingPart.wheel ~= nil then
			local speedRotatingPartsNodes = {}

			if speedRotatingPart.repr ~= nil then
				I3DUtil.getNodesByShaderParam(speedRotatingPart.repr, "RDT", speedRotatingPartsNodes)
			end

			if speedRotatingPart.shaderNode ~= nil then
				I3DUtil.getNodesByShaderParam(speedRotatingPart.shaderNode, "RDT", speedRotatingPartsNodes)
			end

			if speedRotatingPart.driveNode ~= nil then
				I3DUtil.getNodesByShaderParam(speedRotatingPart.driveNode, "RDT", speedRotatingPartsNodes)
			end

			if speedRotatingPartsNodes[node] ~= nil then
				local nodeData = {
					wheel = speedRotatingPart.wheel,
					fieldDirtMultiplier = speedRotatingPart.wheel.fieldDirtMultiplier,
					streetDirtMultiplier = speedRotatingPart.wheel.streetDirtMultiplier,
					minDirtPercentage = speedRotatingPart.wheel.minDirtPercentage,
					maxDirtOffset = speedRotatingPart.wheel.maxDirtOffset,
					dirtColorChangeSpeed = speedRotatingPart.wheel.dirtColorChangeSpeed,
					isSnowNode = true
				}

				return false, self.updateWheelDirtAmount, speedRotatingPart.wheel, nodeData
			end
		end
	end

	return superFunc(self, node)
end
