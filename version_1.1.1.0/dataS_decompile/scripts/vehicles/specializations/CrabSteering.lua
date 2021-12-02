source("dataS/scripts/vehicles/specializations/events/SetCrabSteeringEvent.lua")

CrabSteering = {
	STEERING_SEND_NUM_BITS = 3,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Drivable, specializations) and SpecializationUtil.hasSpecialization(Wheels, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("CrabSteering")
		schema:register(XMLValueType.FLOAT, "vehicle.crabSteering#distFromCompJointToCenterOfBackWheels", "Distance from component joint to center of back wheels")
		schema:register(XMLValueType.FLOAT, "vehicle.crabSteering#aiSteeringModeIndex", "AI steering mode index", 1)
		schema:register(XMLValueType.FLOAT, "vehicle.crabSteering#toggleSpeedFactor", "Toggle speed factor", 1)
		schema:register(XMLValueType.L10N_STRING, "vehicle.crabSteering.steeringMode(?)#name", "Steering mode name")
		schema:register(XMLValueType.STRING, "vehicle.crabSteering.steeringMode(?)#inputBindingName", "Input action name")
		schema:register(XMLValueType.INT, "vehicle.crabSteering.steeringMode(?).wheel(?)#index", "Wheel Index")
		schema:register(XMLValueType.ANGLE, "vehicle.crabSteering.steeringMode(?).wheel(?)#offset", "Rotation offset", 0)
		schema:register(XMLValueType.BOOL, "vehicle.crabSteering.steeringMode(?).wheel(?)#locked", "Steering is locked", false)
		schema:register(XMLValueType.ANGLE, "vehicle.crabSteering.steeringMode(?).articulatedAxis#offset", "Articulated axis offset angle", 0)
		schema:register(XMLValueType.BOOL, "vehicle.crabSteering.steeringMode(?).articulatedAxis#locked", "Articulated axis is locked", false)
		schema:register(XMLValueType.VECTOR_N, "vehicle.crabSteering.steeringMode(?).articulatedAxis#wheelIndices", "Wheel indices")
		schema:register(XMLValueType.STRING, "vehicle.crabSteering.steeringMode(?).animation(?)#name", "Change animation name")
		schema:register(XMLValueType.FLOAT, "vehicle.crabSteering.steeringMode(?).animation(?)#speed", "Animation speed", 1)
		schema:register(XMLValueType.FLOAT, "vehicle.crabSteering.steeringMode(?).animation(?)#stopTime", "Animation stop time")
		schema:setXMLSpecializationType()

		local schemaSavegame = Vehicle.xmlSchemaSavegame

		schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).crabSteering#state", "Current steering mode", 1)
	end
}

function CrabSteering.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleCrabSteering", CrabSteering.getCanToggleCrabSteering)
	SpecializationUtil.registerFunction(vehicleType, "setCrabSteering", CrabSteering.setCrabSteering)
	SpecializationUtil.registerFunction(vehicleType, "updateSteeringAngle", CrabSteering.updateSteeringAngle)
	SpecializationUtil.registerFunction(vehicleType, "updateArticulatedAxisRotation", CrabSteering.updateArticulatedAxisRotation)
end

function CrabSteering.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", CrabSteering.getCanBeSelected)
end

function CrabSteering.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", CrabSteering)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", CrabSteering)
end

function CrabSteering:onLoad(savegame)
	local spec = self.spec_crabSteering
	spec.state = 1
	spec.stateMax = -1
	spec.distFromCompJointToCenterOfBackWheels = self.xmlFile:getValue("vehicle.crabSteering#distFromCompJointToCenterOfBackWheels")
	spec.aiSteeringModeIndex = self.xmlFile:getValue("vehicle.crabSteering#aiSteeringModeIndex", 1)
	spec.toggleSpeedFactor = self.xmlFile:getValue("vehicle.crabSteering#toggleSpeedFactor", 1)
	spec.currentArticulatedAxisOffset = 0
	spec.articulatedAxisOffsetChanged = false
	spec.articulatedAxisLastAngle = 0
	spec.articulatedAxisChangingTime = 0
	local baseKey = "vehicle.crabSteering"
	spec.steeringModes = {}
	local i = 0

	while true do
		local key = string.format("%s.steeringMode(%d)", baseKey, i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local entry = {
			name = self.xmlFile:getValue(key .. "#name", "", self.customEnvironment, false)
		}
		local inputBindingName = self.xmlFile:getValue(key .. "#inputBindingName")

		if inputBindingName ~= nil then
			if InputAction[inputBindingName] ~= nil then
				entry.inputAction = InputAction[inputBindingName]
			else
				Logging.xmlWarning(self.xmlFile, "Invalid inputBindingname '%s' for '%s'", tostring(inputBindingName), key)
			end
		end

		entry.wheels = {}
		local j = 0

		while true do
			local wheelKey = string.format("%s.wheel(%d)", key, j)

			if not self.xmlFile:hasProperty(wheelKey) then
				break
			end

			local wheelEntry = {
				wheelIndex = self.xmlFile:getValue(wheelKey .. "#index"),
				offset = self.xmlFile:getValue(wheelKey .. "#offset", 0),
				locked = self.xmlFile:getValue(wheelKey .. "#locked", false)
			}
			local wheels = self:getWheels()

			if wheels[wheelEntry.wheelIndex] ~= nil then
				wheels[wheelEntry.wheelIndex].steeringOffset = 0
				wheels[wheelEntry.wheelIndex].forceSteeringAngleUpdate = true
				wheels[wheelEntry.wheelIndex].rotSpeedBackUp = wheels[wheelEntry.wheelIndex].rotSpeed
			else
				Logging.xmlError(self.xmlFile, "Invalid wheelIndex '%s' for '%s'", tostring(wheelEntry.wheelIndex), wheelKey)
			end

			table.insert(entry.wheels, wheelEntry)

			j = j + 1
		end

		local specArticulatedAxis = self.spec_articulatedAxis

		if specArticulatedAxis ~= nil and specArticulatedAxis.componentJoint ~= nil then
			entry.articulatedAxis = {
				rotSpeedBackUp = specArticulatedAxis.rotSpeed,
				offset = self.xmlFile:getValue(key .. ".articulatedAxis#offset", 0),
				locked = self.xmlFile:getValue(key .. ".articulatedAxis#locked", false),
				wheelIndices = self.xmlFile:getValue(key .. ".articulatedAxis#wheelIndices", nil, true)
			}
		end

		entry.animations = {}
		j = 0

		while true do
			local animKey = string.format("%s.animation(%d)", key, j)

			if not self.xmlFile:hasProperty(animKey) then
				break
			end

			local animName = self.xmlFile:getValue(animKey .. "#name")
			local animSpeed = self.xmlFile:getValue(animKey .. "#speed", 1)
			local stopTime = self.xmlFile:getValue(animKey .. "#stopTime")

			if animName ~= nil and self:getAnimationExists(animName) then
				table.insert(entry.animations, {
					animName = animName,
					animSpeed = animSpeed,
					stopTime = stopTime
				})
			else
				Logging.xmlWarning(self.xmlFile, "Invalid animation '%s' for '%s'", tostring(animName), animKey)
			end

			j = j + 1
		end

		table.insert(spec.steeringModes, entry)

		i = i + 1
	end

	spec.stateMax = #spec.steeringModes

	if spec.stateMax > 2^CrabSteering.STEERING_SEND_NUM_BITS - 1 then
		Logging.xmlError(self.xmlFile, "CrabSteering only supports %d steering modes!", 2^CrabSteering.STEERING_SEND_NUM_BITS - 1)
	end

	spec.hasSteeringModes = spec.stateMax > 0

	if spec.hasSteeringModes then
		self:setCrabSteering(1, true)
	else
		SpecializationUtil.removeEventListener(self, "onReadStream", CrabSteering)
		SpecializationUtil.removeEventListener(self, "onWriteStream", CrabSteering)
		SpecializationUtil.removeEventListener(self, "onReadUpdateStream", CrabSteering)
		SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", CrabSteering)
		SpecializationUtil.removeEventListener(self, "onDraw", CrabSteering)
		SpecializationUtil.removeEventListener(self, "onAIImplementStart", CrabSteering)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", CrabSteering)
	end
end

function CrabSteering:onPostLoad(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		local spec = self.spec_crabSteering

		if spec.hasSteeringModes and savegame.xmlFile:hasProperty(savegame.key .. ".crabSteering") then
			local state = savegame.xmlFile:getValue(savegame.key .. ".crabSteering#state", 1)
			state = MathUtil.clamp(state, 1, spec.stateMax)

			self:setCrabSteering(state, true)
			AnimatedVehicle.updateAnimations(self, 99999999, true)
			self:forceUpdateWheelPhysics(99999999)
		end
	end
end

function CrabSteering:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_crabSteering

	if spec.hasSteeringModes then
		xmlFile:setValue(key .. "#state", spec.state)
	end
end

function CrabSteering:onReadStream(streamId, connection)
	local state = streamReadUIntN(streamId, CrabSteering.STEERING_SEND_NUM_BITS)

	self:setCrabSteering(state, true)
	AnimatedVehicle.updateAnimations(self, 99999999, true)
	self:forceUpdateWheelPhysics(99999999)
end

function CrabSteering:onWriteStream(streamId, connection)
	local spec = self.spec_crabSteering

	streamWriteUIntN(streamId, spec.state, CrabSteering.STEERING_SEND_NUM_BITS)
end

function CrabSteering:onReadUpdateStream(streamId, timestamp, connection)
	local specArticulatedAxis = self.spec_articulatedAxis

	if specArticulatedAxis ~= nil and specArticulatedAxis.componentJoint ~= nil then
		specArticulatedAxis.curRot = streamReadFloat32(streamId)
	end
end

function CrabSteering:onWriteUpdateStream(streamId, connection, dirtyMask)
	local specArticulatedAxis = self.spec_articulatedAxis

	if specArticulatedAxis ~= nil and specArticulatedAxis.componentJoint ~= nil then
		streamWriteFloat32(streamId, specArticulatedAxis.curRot)
	end
end

function CrabSteering:getCanToggleCrabSteering()
	return true, nil
end

function CrabSteering:setCrabSteering(state, noEventSend)
	local spec = self.spec_crabSteering

	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetCrabSteeringEvent.new(self, state), nil, , self)
		else
			g_client:getServerConnection():sendEvent(SetCrabSteeringEvent.new(self, state))
		end
	end

	if state ~= spec.state then
		local currentMode = spec.steeringModes[spec.state]

		if currentMode.animations ~= nil then
			for _, anim in pairs(currentMode.animations) do
				local curTime = self:getAnimationTime(anim.animName)

				if anim.stopTime == nil then
					self:playAnimation(anim.animName, -anim.animSpeed, curTime, noEventSend)
				end
			end
		end

		local newMode = spec.steeringModes[state]

		if newMode.animations ~= nil then
			for _, anim in pairs(newMode.animations) do
				local curTime = self:getAnimationTime(anim.animName)

				if anim.stopTime ~= nil then
					self:setAnimationStopTime(anim.animName, anim.stopTime)

					local speed = 1

					if anim.stopTime < curTime then
						speed = -1
					end

					self:playAnimation(anim.animName, speed, curTime, noEventSend)
				else
					self:playAnimation(anim.animName, anim.animSpeed, curTime, noEventSend)
				end
			end
		end
	end

	spec.state = state
	local actionEvent = spec.actionEvents[InputAction.TOGGLE_CRABSTEERING]

	if actionEvent ~= nil then
		g_inputBinding:setActionEventText(actionEvent.actionEventId, string.format(g_i18n:getText("action_steeringModeToggle"), spec.steeringModes[spec.state].name))
	end
end

function CrabSteering:updateSteeringAngle(wheel, dt, steeringAngle)
	local spec = self.spec_crabSteering
	local specDriveable = self.spec_drivable

	if spec.stateMax == 0 then
		return steeringAngle
	end

	local currentMode = spec.steeringModes[spec.state]

	for i = 1, #currentMode.wheels do
		local wheelProperties = currentMode.wheels[i]

		if wheelProperties.wheelIndex == wheel.xmlIndex + 1 then
			local rotScale = math.min(1 / (self.lastSpeed * specDriveable.speedRotScale + specDriveable.speedRotScaleOffset), 1)
			local delta = dt * 0.001 * self.autoRotateBackSpeed * rotScale * spec.toggleSpeedFactor

			if wheel.steeringOffset < wheelProperties.offset then
				wheel.steeringOffset = math.min(wheelProperties.offset, wheel.steeringOffset + delta)
			elseif wheelProperties.offset < wheel.steeringOffset then
				wheel.steeringOffset = math.max(wheelProperties.offset, wheel.steeringOffset - delta)
			end

			if not wheelProperties.locked then
				local rotSpeed = nil

				if self.rotatedTime > 0 then
					rotSpeed = (wheel.rotMax - wheel.steeringOffset) / self.wheelSteeringDuration

					if wheel.rotSpeedBackUp < 0 then
						rotSpeed = (wheel.rotMin - wheel.steeringOffset) / self.wheelSteeringDuration
					end
				else
					rotSpeed = -(wheel.rotMin - wheel.steeringOffset) / self.wheelSteeringDuration

					if wheel.rotSpeedBackUp < 0 then
						rotSpeed = -(wheel.rotMax - wheel.steeringOffset) / self.wheelSteeringDuration
					end
				end

				if wheel.rotSpeed < wheel.rotSpeedBackUp then
					wheel.rotSpeed = math.min(wheel.rotSpeedBackUp, wheel.rotSpeed + delta)
				elseif wheel.rotSpeedBackUp < wheel.rotSpeed then
					wheel.rotSpeed = math.max(wheel.rotSpeedBackUp, wheel.rotSpeed - delta)
				end

				local f = wheel.rotSpeed / wheel.rotSpeedBackUp
				steeringAngle = wheel.steeringOffset + self.rotatedTime * f * rotSpeed
			else
				if wheel.steeringOffset < wheel.steeringAngle or wheel.steeringOffset < steeringAngle then
					steeringAngle = math.max(wheel.steeringOffset, math.min(wheel.steeringAngle, steeringAngle) - delta)
				elseif wheel.steeringAngle < wheel.steeringOffset or steeringAngle < wheel.steeringOffset then
					steeringAngle = math.min(wheel.steeringOffset, math.max(wheel.steeringAngle, steeringAngle) + delta)
				end

				if steeringAngle == wheel.steeringOffset then
					wheel.rotSpeed = 0
				elseif wheel.rotSpeed < 0 then
					wheel.rotSpeed = math.min(0, wheel.rotSpeed + delta)
				elseif wheel.rotSpeed > 0 then
					wheel.rotSpeed = math.max(0, wheel.rotSpeed - delta)
				end
			end

			steeringAngle = MathUtil.clamp(steeringAngle, wheel.rotMin, wheel.rotMax)

			break
		end
	end

	return steeringAngle
end

function CrabSteering:updateArticulatedAxisRotation(steeringAngle, dt)
	local spec = self.spec_crabSteering
	local specArticulatedAxis = self.spec_articulatedAxis
	local specDriveable = self.spec_drivable

	if spec.stateMax == 0 then
		return steeringAngle
	end

	if not self.isServer then
		return specArticulatedAxis.curRot
	end

	local currentMode = spec.steeringModes[spec.state]

	if currentMode.articulatedAxis == nil then
		return steeringAngle
	end

	local rotScale = math.min(1 / (self.lastSpeed * specDriveable.speedRotScale + specDriveable.speedRotScaleOffset), 1)
	local delta = dt * 0.001 * self.autoRotateBackSpeed * rotScale * spec.toggleSpeedFactor

	if spec.currentArticulatedAxisOffset < currentMode.articulatedAxis.offset then
		spec.currentArticulatedAxisOffset = math.min(currentMode.articulatedAxis.offset, spec.currentArticulatedAxisOffset + delta)
	elseif currentMode.articulatedAxis.offset < spec.currentArticulatedAxisOffset then
		spec.currentArticulatedAxisOffset = math.max(currentMode.articulatedAxis.offset, spec.currentArticulatedAxisOffset - delta)
	end

	if currentMode.articulatedAxis.locked then
		if specArticulatedAxis.rotSpeed > 0 then
			specArticulatedAxis.rotSpeed = math.max(0, specArticulatedAxis.rotSpeed - delta)
		elseif specArticulatedAxis.rotSpeed < 0 then
			specArticulatedAxis.rotSpeed = math.min(0, specArticulatedAxis.rotSpeed + delta)
		end
	elseif currentMode.articulatedAxis.rotSpeedBackUp < specArticulatedAxis.rotSpeed then
		specArticulatedAxis.rotSpeed = math.max(currentMode.articulatedAxis.rotSpeedBackUp, specArticulatedAxis.rotSpeed - delta)
	elseif specArticulatedAxis.rotSpeed < currentMode.articulatedAxis.rotSpeedBackUp then
		specArticulatedAxis.rotSpeed = math.min(currentMode.articulatedAxis.rotSpeedBackUp, specArticulatedAxis.rotSpeed + delta)
	end

	local rotSpeed = nil

	if self.rotatedTime * currentMode.articulatedAxis.rotSpeedBackUp > 0 then
		rotSpeed = (specArticulatedAxis.rotMax - spec.currentArticulatedAxisOffset) / self.wheelSteeringDuration
	else
		rotSpeed = (specArticulatedAxis.rotMin - spec.currentArticulatedAxisOffset) / self.wheelSteeringDuration
	end

	local f = math.abs(specArticulatedAxis.rotSpeed) / math.abs(currentMode.articulatedAxis.rotSpeedBackUp)
	rotSpeed = rotSpeed * f
	steeringAngle = spec.currentArticulatedAxisOffset + math.abs(self.rotatedTime) * rotSpeed

	if table.getn(currentMode.articulatedAxis.wheelIndices) > 0 and spec.distFromCompJointToCenterOfBackWheels ~= nil and self.movingDirection >= 0 then
		local wheels = self:getWheels()
		local curRot = MathUtil.sign(currentMode.articulatedAxis.rotSpeedBackUp) * specArticulatedAxis.curRot
		local alpha = 0
		local count = 0

		for _, wheelIndex in pairs(currentMode.articulatedAxis.wheelIndices) do
			alpha = alpha + wheels[wheelIndex].steeringAngle
			count = count + 1
		end

		alpha = alpha / count
		alpha = alpha - curRot
		local v = 0
		count = 0

		for _, wheelIndex in pairs(currentMode.articulatedAxis.wheelIndices) do
			local wheel = wheels[wheelIndex]
			local axleSpeed = getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape)

			if wheel.hasGroundContact then
				local longSlip, _ = getWheelShapeSlip(wheel.node, wheel.wheelShape)
				local fac = 1 - math.min(1, longSlip)
				v = v + fac * axleSpeed * wheel.radius
				count = count + 1
			end
		end

		v = v / count
		local h = v * 0.001 * dt
		local g = math.sin(alpha) * h
		local a = math.cos(alpha) * h
		local ls = spec.distFromCompJointToCenterOfBackWheels
		local beta = math.atan2(g, ls - a)
		steeringAngle = MathUtil.sign(currentMode.articulatedAxis.rotSpeedBackUp) * (curRot + beta)
		spec.articulatedAxisOffsetChanged = true
		spec.articulatedAxisLastAngle = steeringAngle
	else
		local changingTime = spec.articulatedAxisChangingTime

		if spec.articulatedAxisOffsetChanged then
			changingTime = 2500
			spec.articulatedAxisOffsetChanged = false
		end

		if changingTime > 0 then
			local pos = changingTime / 2500
			steeringAngle = steeringAngle * (1 - pos) + spec.articulatedAxisLastAngle * pos
			spec.articulatedAxisChangingTime = changingTime - dt
		end
	end

	steeringAngle = math.max(specArticulatedAxis.rotMin, math.min(specArticulatedAxis.rotMax, steeringAngle))

	return steeringAngle
end

function CrabSteering:getCanBeSelected(superFunc)
	return self.spec_crabSteering.hasSteeringModes or superFunc(self)
end

function CrabSteering:onAIImplementStart()
	local spec = self.spec_crabSteering

	self:setCrabSteering(spec.aiSteeringModeIndex)
end

function CrabSteering:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_crabSteering

		if spec.hasSteeringModes then
			self:clearActionEventsTable(spec.actionEvents)

			if isActiveForInputIgnoreSelection then
				local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_CRABSTEERING, self, CrabSteering.actionEventToggleCrabSteeringModes, false, true, false, true, 1)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
				g_inputBinding:setActionEventText(actionEventId, string.format(g_i18n:getText("action_steeringModeToggle"), spec.steeringModes[spec.state].name))

				for _, mode in pairs(spec.steeringModes) do
					if mode.inputAction ~= nil then
						_, actionEventId = self:addPoweredActionEvent(spec.actionEvents, mode.inputAction, self, CrabSteering.actionEventSetCrabSteeringMode, false, true, false, true, nil)

						g_inputBinding:setActionEventTextVisibility(actionEventId, false)
						g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
					end
				end

				_, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_CRABSTEERING_BACK, self, CrabSteering.actionEventToggleCrabSteeringModes, false, true, false, true, -1)

				g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			end
		end
	end
end

function CrabSteering:actionEventToggleCrabSteeringModes(actionName, inputValue, callbackState, isAnalog)
	local isAllowed, warning = self:getCanToggleCrabSteering()

	if isAllowed then
		local spec = self.spec_crabSteering
		local state = spec.state
		state = state + callbackState

		if spec.stateMax < state then
			state = 1
		elseif state < 1 then
			state = spec.stateMax
		end

		if state ~= spec.state then
			self:setCrabSteering(state)
		end
	elseif warning ~= nil then
		g_currentMission:showBlinkingWarning(warning, 2000)
	end
end

function CrabSteering:actionEventSetCrabSteeringMode(actionName, inputValue, callbackState, isAnalog)
	local isAllowed, warning = self:getCanToggleCrabSteering()

	if isAllowed then
		local spec = self.spec_crabSteering
		local state = spec.state

		for i, mode in pairs(spec.steeringModes) do
			if mode.inputAction == InputAction[actionName] then
				state = i

				break
			end
		end

		if state ~= spec.state then
			self:setCrabSteering(state)
		end
	elseif warning ~= nil then
		g_currentMission:showBlinkingWarning(warning, 2000)
	end
end
