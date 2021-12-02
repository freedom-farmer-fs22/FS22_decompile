WheelsUtil = {
	GROUND_ROAD = 1,
	GROUND_HARD_TERRAIN = 2,
	GROUND_SOFT_TERRAIN = 3,
	GROUND_FIELD = 4,
	NUM_GROUNDS = 4,
	STEERING_ANGLE_THRESHOLD = 0.00034,
	SUSPENSION_THRESHOLD = 0.001,
	tireTypes = {}
}

function WheelsUtil.registerTireType(name, frictionCoeffs, frictionCoeffsWet, frictionCoeffsSnow)
	name = name:upper()

	if WheelsUtil.getTireType(name) ~= nil then
		print("Warning: Tire type '" .. name .. "' already registered, ignoring this definition")

		return
	end

	local function getNoNilCoeffs(frictionCoeffs)
		local localCoeffs = {}

		if frictionCoeffs[1] == nil then
			localCoeffs[1] = 1.15

			for i = 2, WheelsUtil.NUM_GROUNDS do
				if frictionCoeffs[i] ~= nil then
					localCoeffs[1] = frictionCoeffs[i]

					break
				end
			end
		else
			localCoeffs[1] = frictionCoeffs[1]
		end

		for i = 2, WheelsUtil.NUM_GROUNDS do
			localCoeffs[i] = frictionCoeffs[i] or frictionCoeffs[i - 1]
		end

		return localCoeffs
	end

	local tireType = {
		name = name,
		frictionCoeffs = getNoNilCoeffs(frictionCoeffs),
		frictionCoeffsWet = getNoNilCoeffs(frictionCoeffsWet or frictionCoeffs)
	}
	tireType.frictionCoeffsSnow = getNoNilCoeffs(frictionCoeffsSnow or tireType.frictionCoeffsWet)

	table.insert(WheelsUtil.tireTypes, tireType)
end

function WheelsUtil.unregisterTireType(name)
	name = name:upper()

	for i, tireType in ipairs(WheelsUtil.tireTypes) do
		if tireType.name == name then
			table.remove(WheelsUtil.tireTypes, i)

			break
		end
	end
end

function WheelsUtil.getTireType(name)
	name = name:upper()

	for i, t in pairs(WheelsUtil.tireTypes) do
		if t.name == name then
			return i
		end
	end

	return nil
end

function WheelsUtil.getTireTypeName(index)
	if WheelsUtil.tireTypes[index] ~= nil then
		return WheelsUtil.tireTypes[index].name
	end

	return "unknown"
end

local mudTireCoeffs = {
	[WheelsUtil.GROUND_ROAD] = 1.15,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.1,
	[WheelsUtil.GROUND_FIELD] = 0.95
}
local mudTireCoeffsWet = {
	[WheelsUtil.GROUND_ROAD] = 1.05,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1,
	[WheelsUtil.GROUND_FIELD] = 0.7
}
local mudTireCoeffsSnow = {
	[WheelsUtil.GROUND_ROAD] = 0.45,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 0.45,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.4,
	[WheelsUtil.GROUND_FIELD] = 0.35
}

WheelsUtil.registerTireType("mud", mudTireCoeffs, mudTireCoeffsWet, mudTireCoeffsSnow)

local offRoadTireCoeffs = {
	[WheelsUtil.GROUND_ROAD] = 1.2,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_FIELD] = 1
}
local offRoadTireCoeffsWet = {
	[WheelsUtil.GROUND_ROAD] = 1.05,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.95,
	[WheelsUtil.GROUND_FIELD] = 0.6
}
local offRoadTireCoeffsSnow = {
	[WheelsUtil.GROUND_ROAD] = 0.45,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 0.4,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.35,
	[WheelsUtil.GROUND_FIELD] = 0.3
}

WheelsUtil.registerTireType("offRoad", offRoadTireCoeffs, offRoadTireCoeffsWet, offRoadTireCoeffsSnow)

local streetTireCoeffs = {
	[WheelsUtil.GROUND_ROAD] = 1.25,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1,
	[WheelsUtil.GROUND_FIELD] = 0.9
}
local streetTireCoeffsWet = {
	[WheelsUtil.GROUND_ROAD] = 1.15,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.85,
	[WheelsUtil.GROUND_FIELD] = 0.45
}
local streetTireCoeffsSnow = {
	[WheelsUtil.GROUND_ROAD] = 0.55,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 0.4,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.3,
	[WheelsUtil.GROUND_FIELD] = 0.35
}

WheelsUtil.registerTireType("street", streetTireCoeffs, streetTireCoeffsWet, streetTireCoeffsSnow)

local crawlerCoeffs = {
	[WheelsUtil.GROUND_ROAD] = 1.15,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_FIELD] = 1.15
}
local crawlerCoeffsWet = {
	[WheelsUtil.GROUND_ROAD] = 1.05,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_FIELD] = 0.85
}
local crawlerCoeffsSnow = {
	[WheelsUtil.GROUND_ROAD] = 0.65,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 0.65,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 0.65,
	[WheelsUtil.GROUND_FIELD] = 0.65
}

WheelsUtil.registerTireType("crawler", crawlerCoeffs, crawlerCoeffsWet, crawlerCoeffsSnow)

local chainsCoeffs = {
	[WheelsUtil.GROUND_ROAD] = 1.15,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_FIELD] = 1.15
}
local chainsCoeffsWet = {
	[WheelsUtil.GROUND_ROAD] = 1.05,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_FIELD] = 0.95
}
local chainsCoeffsSnow = {
	[WheelsUtil.GROUND_ROAD] = 1.05,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.05,
	[WheelsUtil.GROUND_FIELD] = 1.05
}

WheelsUtil.registerTireType("chains", chainsCoeffs, chainsCoeffsWet, chainsCoeffsSnow)

local metalCoeffs = {
	[WheelsUtil.GROUND_ROAD] = 1.15,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_FIELD] = 1.15
}
local metalCoeffsWet = {
	[WheelsUtil.GROUND_ROAD] = 1.15,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_FIELD] = 1.15
}
local metalCoeffsSnow = {
	[WheelsUtil.GROUND_ROAD] = 1.15,
	[WheelsUtil.GROUND_HARD_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_SOFT_TERRAIN] = 1.15,
	[WheelsUtil.GROUND_FIELD] = 1.15
}

WheelsUtil.registerTireType("metalSpikes", metalCoeffs, metalCoeffsWet, metalCoeffsSnow)

local SMOOTHING_SPEED_SCALE = 0.002

function WheelsUtil:getSmoothedAcceleratorAndBrakePedals(acceleratorPedal, brakePedal, dt)
	if self.wheelsUtilSmoothedAcceleratorPedal == nil then
		self.wheelsUtilSmoothedAcceleratorPedal = 0
	end

	local appliedAcc = 0

	if acceleratorPedal > 0 then
		if self.wheelsUtilSmoothedAcceleratorPedal < acceleratorPedal then
			appliedAcc = math.min(math.max(self.wheelsUtilSmoothedAcceleratorPedal + SMOOTHING_SPEED_SCALE * dt, SMOOTHING_SPEED_SCALE), acceleratorPedal)
		else
			appliedAcc = acceleratorPedal
		end

		self.wheelsUtilSmoothedAcceleratorPedal = appliedAcc
	elseif acceleratorPedal < 0 then
		if acceleratorPedal < self.wheelsUtilSmoothedAcceleratorPedal then
			appliedAcc = math.max(math.min(self.wheelsUtilSmoothedAcceleratorPedal - SMOOTHING_SPEED_SCALE * dt, -SMOOTHING_SPEED_SCALE), acceleratorPedal)
		else
			appliedAcc = acceleratorPedal
		end

		self.wheelsUtilSmoothedAcceleratorPedal = appliedAcc
	else
		local decSpeed = 0.0005 + 0.001 * brakePedal

		if self.wheelsUtilSmoothedAcceleratorPedal > 0 then
			self.wheelsUtilSmoothedAcceleratorPedal = math.max(self.wheelsUtilSmoothedAcceleratorPedal - decSpeed * dt, 0)
		else
			self.wheelsUtilSmoothedAcceleratorPedal = math.min(self.wheelsUtilSmoothedAcceleratorPedal + decSpeed * dt, 0)
		end
	end

	if self.wheelsUtilSmoothedBrakePedal == nil then
		self.wheelsUtilSmoothedBrakePedal = 0
	end

	local appliedBrake = 0

	if brakePedal > 0 then
		if self.wheelsUtilSmoothedBrakePedal < brakePedal then
			appliedBrake = math.min(self.wheelsUtilSmoothedBrakePedal + 0.0025 * dt, brakePedal)
		else
			appliedBrake = brakePedal
		end

		self.wheelsUtilSmoothedBrakePedal = appliedBrake
	else
		local decSpeed = 0.0005 + 0.001 * acceleratorPedal
		self.wheelsUtilSmoothedBrakePedal = math.max(self.wheelsUtilSmoothedBrakePedal - decSpeed * dt, 0)
	end

	return appliedAcc, appliedBrake
end

function WheelsUtil:updateWheelsPhysics(dt, currentSpeed, acceleration, doHandbrake, stopAndGoBraking)
	local acceleratorPedal = 0
	local brakePedal = 0
	local reverserDirection = 1

	if self.spec_drivable ~= nil then
		reverserDirection = self.spec_drivable.reverserDirection
	end

	local motor = self.spec_motorized.motor
	local isManualTransmission = motor.backwardGears ~= nil or motor.forwardGears ~= nil
	local useManualDirectionChange = isManualTransmission and motor.gearShiftMode ~= VehicleMotor.SHIFT_MODE_AUTOMATIC or motor.directionChangeMode == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL
	useManualDirectionChange = useManualDirectionChange and not self:getIsAIActive()

	if useManualDirectionChange then
		acceleration = acceleration * motor.currentDirection * reverserDirection
	else
		acceleration = acceleration * reverserDirection
	end

	local absCurrentSpeed = math.abs(currentSpeed)
	local accSign = MathUtil.sign(acceleration)
	self.nextMovingDirection = self.nextMovingDirection or 0
	self.nextMovingDirectionTimer = self.nextMovingDirectionTimer or 0
	local automaticBrake = false

	if math.abs(acceleration) < 0.001 then
		automaticBrake = true

		if stopAndGoBraking or currentSpeed * self.nextMovingDirection < 0.0003 then
			self.nextMovingDirection = 0
		end
	else
		if self.nextMovingDirection * currentSpeed < -0.0014 then
			self.nextMovingDirection = 0
		end

		if accSign == self.nextMovingDirection or currentSpeed * accSign > -0.0003 and (stopAndGoBraking or self.nextMovingDirection == 0) then
			self.nextMovingDirectionTimer = math.max(self.nextMovingDirectionTimer - dt, 0)

			if self.nextMovingDirectionTimer == 0 then
				acceleratorPedal = acceleration
				brakePedal = 0
				self.nextMovingDirection = accSign
			else
				acceleratorPedal = 0
				brakePedal = math.abs(acceleration)
			end
		else
			acceleratorPedal = 0
			brakePedal = math.abs(acceleration)

			if stopAndGoBraking then
				self.nextMovingDirectionTimer = 100
			end
		end
	end

	if useManualDirectionChange and acceleratorPedal ~= 0 and MathUtil.sign(acceleratorPedal) ~= motor.currentDirection * reverserDirection then
		brakePedal = math.abs(acceleratorPedal)
		acceleratorPedal = 0
	end

	if automaticBrake then
		acceleratorPedal = 0
	end

	acceleratorPedal, brakePedal = motor:updateGear(acceleratorPedal, brakePedal, dt)

	if motor.gear == 0 and motor.targetGear ~= 0 and currentSpeed * MathUtil.sign(motor.targetGear) < 0 then
		automaticBrake = true
	end

	if automaticBrake then
		local isSlow = absCurrentSpeed < motor.lowBrakeForceSpeedLimit
		local isArticulatedSteering = self.spec_articulatedAxis ~= nil and self.spec_articulatedAxis.componentJoint ~= nil and math.abs(self.rotatedTime) > 0.01

		if (isSlow or doHandbrake) and not isArticulatedSteering then
			brakePedal = 1
		else
			local factor = math.min(absCurrentSpeed / 0.001, 1)
			brakePedal = MathUtil.lerp(1, motor.lowBrakeForceScale, factor)
		end
	end

	SpecializationUtil.raiseEvent(self, "onVehiclePhysicsUpdate", acceleratorPedal, brakePedal, automaticBrake, currentSpeed)

	acceleratorPedal, brakePedal = WheelsUtil.getSmoothedAcceleratorAndBrakePedals(self, acceleratorPedal, brakePedal, dt)
	local maxSpeed = motor:getMaximumForwardSpeed() * 3.6

	if self.movingDirection < 0 then
		maxSpeed = motor:getMaximumBackwardSpeed() * 3.6
	end

	local overSpeedLimit = self:getLastSpeed() - math.min(motor:getSpeedLimit(), maxSpeed)

	if overSpeedLimit > 0 then
		if overSpeedLimit > 0.3 then
			motor.overSpeedTimer = math.min(motor.overSpeedTimer + dt, 2000)
		else
			motor.overSpeedTimer = math.max(motor.overSpeedTimer - dt, 0)
		end

		local factor = 0.5 + motor.overSpeedTimer / 2000 * 1
		brakePedal = math.max(math.min(math.pow(overSpeedLimit * factor, 2), 1), brakePedal)
		acceleratorPedal = 0.2 * math.max(1 - overSpeedLimit / 0.2, 0) * acceleratorPedal
	else
		acceleratorPedal = acceleratorPedal * math.min(math.abs(overSpeedLimit) / 0.3 + 0.2, 1)
		motor.overSpeedTimer = 0
	end

	if next(self.spec_motorized.differentials) ~= nil and self.spec_motorized.motorizedNode ~= nil then
		local absAcceleratorPedal = math.abs(acceleratorPedal)
		local minGearRatio, maxGearRatio = motor:getMinMaxGearRatio()
		local maxSpeed = nil

		if maxGearRatio >= 0 then
			maxSpeed = motor:getMaximumForwardSpeed()
		else
			maxSpeed = motor:getMaximumBackwardSpeed()
		end

		local acceleratorPedalControlsSpeed = false

		if acceleratorPedalControlsSpeed then
			maxSpeed = maxSpeed * absAcceleratorPedal

			if absAcceleratorPedal > 0.001 then
				absAcceleratorPedal = 1
			end
		end

		maxSpeed = math.min(maxSpeed, motor:getSpeedLimit() / 3.6)
		local maxAcceleration = motor:getAccelerationLimit()
		local maxMotorRotAcceleration = motor:getMotorRotationAccelerationLimit()
		local minMotorRpm, maxMotorRpm = motor:getRequiredMotorRpmRange()
		local neededPtoTorque, ptoTorqueVirtualMultiplicator = PowerConsumer.getTotalConsumedPtoTorque(self)
		neededPtoTorque = neededPtoTorque / motor:getPtoMotorRpmRatio()
		local neutralActive = minGearRatio == 0 and maxGearRatio == 0 or motor:getManualClutchPedal() == 1

		motor:setExternalTorqueVirtualMultiplicator(ptoTorqueVirtualMultiplicator)

		if not neutralActive then
			self:controlVehicle(absAcceleratorPedal, maxSpeed, maxAcceleration, minMotorRpm * math.pi / 30, maxMotorRpm * math.pi / 30, maxMotorRotAcceleration, minGearRatio, maxGearRatio, motor:getMaxClutchTorque(), neededPtoTorque)
		else
			self:controlVehicle(0, 0, 0, 0, math.huge, 0, 0, 0, 0, 0)

			brakePedal = math.max(brakePedal, 0.1)
		end
	end

	self:brake(brakePedal)
end

function WheelsUtil:updateWheelPhysics(wheel, brakePedal, dt)
	WheelsUtil.updateWheelSteeringAngle(self, wheel, dt)

	if self.isServer and self.isAddedToPhysics then
		local brakeForce = self:getBrakeForce() * brakePedal

		setWheelShapeProps(wheel.node, wheel.wheelShape, wheel.torque, brakeForce * wheel.brakeFactor, wheel.steeringAngle, wheel.rotationDamping)
	end
end

function WheelsUtil:updateWheelSteeringAngle(wheel, dt)
	local steeringAngle = wheel.steeringAngle
	local rotatedTime = self.rotatedTime

	if wheel.steeringAxleScale ~= nil and wheel.steeringAxleScale ~= 0 then
		local steeringAxleAngle = 0

		if self.spec_attachable ~= nil then
			steeringAxleAngle = self.spec_attachable.steeringAxleAngle
		end

		steeringAngle = MathUtil.clamp(steeringAxleAngle * wheel.steeringAxleScale, wheel.steeringAxleRotMin, wheel.steeringAxleRotMax)
	elseif wheel.versatileYRot and self:getIsVersatileYRotActive(wheel) then
		if self.isServer and (wheel.forceVersatility or wheel.hasGroundContact) then
			steeringAngle = Utils.getVersatileRotation(wheel.repr, wheel.node, dt, wheel.positionX, wheel.positionY, wheel.positionZ, wheel.steeringAngle, wheel.rotMin, wheel.rotMax)
		end
	elseif wheel.rotSpeed ~= 0 and wheel.rotMax ~= nil and wheel.rotMin ~= nil or wheel.forceSteeringAngleUpdate then
		if rotatedTime > 0 or wheel.rotSpeedNeg == nil then
			steeringAngle = rotatedTime * wheel.rotSpeed
		else
			steeringAngle = rotatedTime * wheel.rotSpeedNeg
		end

		if wheel.rotMax < steeringAngle then
			steeringAngle = wheel.rotMax
		elseif steeringAngle < wheel.rotMin then
			steeringAngle = wheel.rotMin
		end

		if self.updateSteeringAngle ~= nil then
			steeringAngle = self:updateSteeringAngle(wheel, dt, steeringAngle)
		end
	end

	wheel.steeringAngle = steeringAngle
end

function WheelsUtil:computeDifferentialRotSpeedNonMotor()
	if self.isServer and self.spec_wheels ~= nil and #self.spec_wheels.wheels ~= 0 then
		local wheelSpeed = 0
		local numWheels = 0

		for _, wheel in pairs(self.spec_wheels.wheels) do
			local axleSpeed = getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape)

			if wheel.hasGroundContact then
				wheelSpeed = wheelSpeed + axleSpeed * wheel.radius
				numWheels = numWheels + 1
			end
		end

		if numWheels > 0 then
			return wheelSpeed / numWheels
		end

		return 0
	else
		return self.lastSpeedReal * 1000
	end
end

function WheelsUtil:updateWheelNetInfo(wheel)
	if wheel.updateWheel then
		local x, y, z, xDrive, suspensionLength = getWheelShapePosition(wheel.node, wheel.wheelShape)
		xDrive = xDrive + wheel.xDriveOffset

		if wheel.dirtyFlag ~= nil and (wheel.netInfo.x ~= x or wheel.netInfo.z ~= z) then
			self:raiseDirtyFlags(wheel.dirtyFlag)
		end

		wheel.netInfo.x = x
		wheel.netInfo.y = y
		wheel.netInfo.z = z
		wheel.netInfo.xDrive = xDrive
		wheel.netInfo.suspensionLength = suspensionLength
	else
		wheel.updateWheel = true
	end
end

function WheelsUtil:updateWheelGraphics(wheel, dt)
	local x = wheel.netInfo.x
	local y = wheel.netInfo.y
	local z = wheel.netInfo.z
	local xDrive = wheel.netInfo.xDrive
	local suspensionLength = wheel.netInfo.suspensionLength

	if x ~= nil then
		if wheel.netInfo.xDriveBefore == nil then
			wheel.netInfo.xDriveBefore = xDrive
		end

		local xDriveDiff = xDrive - wheel.netInfo.xDriveBefore

		if math.pi < xDriveDiff then
			wheel.netInfo.xDriveBefore = wheel.netInfo.xDriveBefore + 2 * math.pi
		elseif xDriveDiff < -math.pi then
			wheel.netInfo.xDriveBefore = wheel.netInfo.xDriveBefore - 2 * math.pi
		end

		wheel.netInfo.xDriveDiff = xDrive - wheel.netInfo.xDriveBefore
		wheel.netInfo.xDriveSpeed = wheel.netInfo.xDriveDiff / (0.001 * dt)
		wheel.netInfo.xDriveBefore = xDrive

		return WheelsUtil.updateVisualWheel(self, wheel, x, y, z, xDrive, suspensionLength)
	end

	return false
end

local STEERING_ANGLE_THRESHOLD = WheelsUtil.STEERING_ANGLE_THRESHOLD
local SUSPENSION_THRESHOLD = WheelsUtil.SUSPENSION_THRESHOLD

function WheelsUtil:updateVisualWheel(wheel, x, y, z, xDrive, suspensionLength)
	local changed = false
	local steeringAngle = wheel.steeringAngle

	if not wheel.showSteeringAngle then
		steeringAngle = 0
	end

	if STEERING_ANGLE_THRESHOLD < math.abs(steeringAngle - wheel.lastSteeringAngle) then
		setRotation(wheel.repr, 0, steeringAngle, 0)

		wheel.lastSteeringAngle = steeringAngle
		changed = true
	end

	if STEERING_ANGLE_THRESHOLD < math.abs(xDrive - wheel.lastXDrive) then
		setRotation(wheel.driveNode, xDrive, 0, 0)

		wheel.lastXDrive = xDrive
		changed = true
	end

	if wheel.wheelTire ~= nil and self.spec_wheels.wheelVisualPressureActive then
		local deformation = MathUtil.clamp(wheel.deltaY + wheel.initialDeformation - suspensionLength, 0, wheel.maxDeformation)
		local prevDeformation, curDeformation = nil

		if math.abs(deformation - wheel.deformation) > 0.003 then
			prevDeformation = wheel.deformation
			curDeformation = deformation
			wheel.deformation = deformation
			wheel.derformationPrevDirty = true
			changed = true
		end

		if wheel.derformationPrevDirty then
			prevDeformation = wheel.deformation
			curDeformation = wheel.deformation
			wheel.derformationPrevDirty = false
		end

		if curDeformation ~= nil then
			local mx, my, mz, _ = I3DUtil.getShaderParameterRec(wheel.wheelTire, "morphPosition")

			I3DUtil.setShaderParameterRec(wheel.wheelTire, "morphPosition", mx, my, mz, curDeformation, false)
			I3DUtil.setShaderParameterRec(wheel.wheelTire, "prevMorphPosition", mx, my, mz, prevDeformation, false)

			if wheel.additionalWheels ~= nil then
				for _, additionalWheel in pairs(wheel.additionalWheels) do
					mx, my, mz, _ = I3DUtil.getShaderParameterRec(additionalWheel.wheelTire, "morphPosition")

					I3DUtil.setShaderParameterRec(additionalWheel.wheelTire, "morphPosition", mx, my, mz, curDeformation, false)
					I3DUtil.setShaderParameterRec(additionalWheel.wheelTire, "prevMorphPosition", mx, my, mz, prevDeformation, false)
				end
			end
		end

		local sideOffset = 0
		suspensionLength = suspensionLength + deformation + sideOffset
	end

	suspensionLength = suspensionLength - wheel.deltaY

	if SUSPENSION_THRESHOLD < math.abs(wheel.lastMovement - suspensionLength) then
		local dirX, dirY, dirZ = localDirectionToLocal(wheel.repr, getParent(wheel.repr), 0, -1, 0)
		local transRatio = wheel.transRatio
		local movement = suspensionLength * transRatio

		setTranslation(wheel.repr, wheel.startPositionX + dirX * movement, wheel.startPositionY + dirY * movement, wheel.startPositionZ + dirZ * movement)

		changed = true

		if transRatio < 1 then
			movement = suspensionLength * (1 - transRatio)

			setTranslation(wheel.driveNode, wheel.driveNodeStartPosX + dirX * movement, wheel.driveNodeStartPosY + dirY * movement, wheel.driveNodeStartPosZ + dirZ * movement)
		end

		wheel.lastMovement = suspensionLength
	end

	if wheel.steeringNode ~= nil then
		local refAngle = wheel.steeringNodeMaxRot
		local refTrans = wheel.steeringNodeMaxTransX
		local refRot = wheel.steeringNodeMaxRotY

		if steeringAngle < 0 then
			refAngle = wheel.steeringNodeMinRot
			refTrans = wheel.steeringNodeMinTransX
			refRot = wheel.steeringNodeMinRotY
		end

		local steering = 0

		if refAngle ~= 0 then
			steering = steeringAngle / refAngle
		end

		if wheel.steeringNodeMinTransX ~= nil then
			local x, y, z = getTranslation(wheel.steeringNode)
			x = refTrans * steering

			setTranslation(wheel.steeringNode, x, y, z)
		end

		if wheel.steeringNodeMinRotY ~= nil then
			local rotX, rotY, rotZ = getRotation(wheel.steeringRotNode or wheel.steeringNode)
			rotY = refRot * steering

			setRotation(wheel.steeringRotNode or wheel.steeringNode, rotX, rotY, rotZ)
		end
	end

	for i = 1, #wheel.fenders do
		local fender = wheel.fenders[i]
		local angleDif = 0

		if fender.rotMax < steeringAngle then
			angleDif = fender.rotMax - steeringAngle
		elseif steeringAngle < fender.rotMin then
			angleDif = fender.rotMin - steeringAngle
		end

		setRotation(fender.node, 0, angleDif, 0)
	end

	return changed
end

function WheelsUtil.getTireFriction(tireType, groundType, wetScale, snowScale)
	if wetScale == nil then
		wetScale = 0
	end

	local coeff = WheelsUtil.tireTypes[tireType].frictionCoeffs[groundType]
	local coeffWet = WheelsUtil.tireTypes[tireType].frictionCoeffsWet[groundType]
	local coeffSnow = WheelsUtil.tireTypes[tireType].frictionCoeffsSnow[groundType]

	return coeff + (coeffWet - coeff) * wetScale + (coeffSnow - coeff) * snowScale
end

function WheelsUtil.getGroundType(isField, isRoad, depth)
	if isField then
		return WheelsUtil.GROUND_FIELD
	elseif isRoad or depth < 0.1 then
		return WheelsUtil.GROUND_ROAD
	elseif depth > 0.8 then
		return WheelsUtil.GROUND_SOFT_TERRAIN
	else
		return WheelsUtil.GROUND_HARD_TERRAIN
	end
end
