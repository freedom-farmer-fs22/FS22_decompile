VehicleDebug = {
	WORKAREA_COLORS = {
		{
			1,
			0,
			0,
			1
		},
		{
			0,
			1,
			0,
			1
		},
		{
			0,
			0,
			1,
			1
		},
		{
			1,
			1,
			0,
			1
		},
		{
			1,
			0,
			1,
			1
		},
		{
			0,
			1,
			1,
			1
		},
		{
			1,
			1,
			1,
			1
		}
	},
	COLOR = {}
}
VehicleDebug.COLOR.ACTIVE = {
	0.5,
	1,
	0.5,
	1
}
VehicleDebug.COLOR.INACTIVE = {
	1,
	0.1,
	0.1,
	1
}
VehicleDebug.NONE = 0
VehicleDebug.DEBUG = 1
VehicleDebug.DEBUG_PHYSICS = 2
VehicleDebug.DEBUG_TUNING = 3
VehicleDebug.DEBUG_TRANSMISSION = 4
VehicleDebug.DEBUG_ATTRIBUTES = 5
VehicleDebug.DEBUG_ATTACHER_JOINTS = 6
VehicleDebug.DEBUG_AI = 7
VehicleDebug.DEBUG_SOUNDS = 8
VehicleDebug.DEBUG_ANIMATIONS = 9
VehicleDebug.DEBUG_REVERB = 10
VehicleDebug.STATE_NAMES = {
	[VehicleDebug.NONE] = "None",
	[VehicleDebug.DEBUG] = "Values",
	[VehicleDebug.DEBUG_PHYSICS] = "Physics",
	[VehicleDebug.DEBUG_TUNING] = "Tuning",
	[VehicleDebug.DEBUG_TRANSMISSION] = "Transmission",
	[VehicleDebug.DEBUG_ATTRIBUTES] = "Attributes",
	[VehicleDebug.DEBUG_ATTACHER_JOINTS] = "Attacher Joints",
	[VehicleDebug.DEBUG_AI] = "AI",
	[VehicleDebug.DEBUG_SOUNDS] = "Sounds",
	[VehicleDebug.DEBUG_ANIMATIONS] = "Animations"
}
VehicleDebug.NUM_STATES = 9
VehicleDebug.state = 0
VehicleDebug.selectedAnimation = 0

if g_isDevelopmentVersion then
	VehicleDebug.state = 0
end

function VehicleDebug.consoleCommandVehicleDebug(unusedSelf, stateStr)
	local newState = VehicleDebug.DEBUG

	if stateStr ~= nil then
		local n = tonumber(stateStr)

		if n == nil then
			for stateIndex, stateName in pairs(VehicleDebug.STATE_NAMES) do
				if string.startsWith(stateName:lower(), stateStr:lower()) then
					newState = stateIndex
				end
			end
		else
			newState = n
		end
	end

	VehicleDebug.setState(newState)

	return string.format("VehicleDebug set to '%s'", VehicleDebug.STATE_NAMES[VehicleDebug.state])
end

function VehicleDebug.consoleCommandVehicleDebugReverb(unusedSelf)
	return "VehicleDebug - Reverb: " .. tostring(VehicleDebug.setState(VehicleDebug.DEBUG_REVERB))
end

function VehicleDebug.setState(state)
	if VehicleDebug.state == 0 then
		VehicleDebug.debugActionEvents = {}

		for i = 1, VehicleDebug.NUM_STATES do
			local _, actionEventId = g_inputBinding:registerActionEvent(InputAction["DEBUG_VEHICLE_" .. i], VehicleDebug, VehicleDebug.debugActionCallback, false, true, false, true, i)

			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			table.insert(VehicleDebug.debugActionEvents, actionEventId)
		end
	elseif state == 0 then
		for i = 1, #VehicleDebug.debugActionEvents do
			g_inputBinding:removeActionEvent(VehicleDebug.debugActionEvents[i])
		end
	end

	if state == VehicleDebug.DEBUG_ATTACHER_JOINTS then
		if VehicleDebug.attacherJointUpperEventId == nil and VehicleDebug.attacherJointLowerEventId == nil then
			local _, upperEventId = g_inputBinding:registerActionEvent(InputAction.AXIS_FRONTLOADER_ARM, VehicleDebug, VehicleDebug.moveUpperRotation, false, false, true, true)

			g_inputBinding:setActionEventTextVisibility(upperEventId, false)

			VehicleDebug.attacherJointUpperEventId = upperEventId
			local _, lowerEventId = g_inputBinding:registerActionEvent(InputAction.AXIS_FRONTLOADER_TOOL, VehicleDebug, VehicleDebug.moveLowerRotation, false, false, true, true)

			g_inputBinding:setActionEventTextVisibility(lowerEventId, false)

			VehicleDebug.attacherJointLowerEventId = lowerEventId
		end
	else
		g_inputBinding:removeActionEvent(VehicleDebug.attacherJointUpperEventId)
		g_inputBinding:removeActionEvent(VehicleDebug.attacherJointLowerEventId)

		VehicleDebug.attacherJointUpperEventId = nil
		VehicleDebug.attacherJointLowerEventId = nil
	end

	if state == VehicleDebug.DEBUG_REVERB then
		if VehicleDebug.reverbToggleEventId == nil then
			local _, reverbToggleEventId = g_inputBinding:registerActionEvent(InputAction.TOGGLE_PIPE, VehicleDebug, VehicleDebug.toggleReverb, false, true, false, true)

			g_inputBinding:setActionEventTextVisibility(reverbToggleEventId, false)

			VehicleDebug.reverbToggleEventId = reverbToggleEventId
		end
	else
		g_inputBinding:removeActionEvent(VehicleDebug.reverbToggleEventId)

		VehicleDebug.reverbToggleEventId = nil
	end

	local ret = false

	if VehicleDebug.state == state then
		VehicleDebug.state = 0
	else
		VehicleDebug.state = state
		ret = true
	end

	if g_currentMission ~= nil then
		for _, vehicle in pairs(g_currentMission.vehicles) do
			vehicle:updateSelectableObjects()
			vehicle:updateActionEvents()
			vehicle:setSelectedVehicle(vehicle)
		end
	end

	return ret
end

function VehicleDebug:delete()
	if self.isServer then
		local specWheels = self.spec_wheels

		if specWheels ~= nil and specWheels.wheels ~= nil and table.getn(specWheels.wheels) > 0 then
			for i, wheel in ipairs(specWheels.wheels) do
				if wheel.debugLateralFrictionGraph ~= nil then
					wheel.debugLateralFrictionGraph:delete()
				end

				if wheel.debugLongitudalFrictionGraph ~= nil then
					wheel.debugLongitudalFrictionGraph:delete()
				end

				if wheel.debugLongitudalFrictionSlipOverlay ~= nil then
					delete(wheel.debugLongitudalFrictionSlipOverlay)
				end

				if wheel.debugLateralFrictionSlipOverlay ~= nil then
					delete(wheel.debugLateralFrictionSlipOverlay)
				end
			end
		end

		local motorSpec = self.spec_motorized

		if motorSpec ~= nil then
			local motor = motorSpec.motor

			if motor ~= nil then
				if motor.debugCurveOverlay ~= nil then
					delete(motor.debugCurveOverlay)
				end

				if motor.debugTorqueGraph ~= nil then
					motor.debugTorqueGraph:delete()
				end

				if motor.debugPowerGraph ~= nil then
					motor.debugPowerGraph:delete()
				end

				if motor.debugGraphs ~= nil then
					for _, graph in ipairs(motor.debugGraphs) do
						graph:delete()
					end
				end

				if motor.debugLoadGraphSmooth ~= nil then
					motor.debugLoadGraphSmooth:delete()
				end

				if motor.debugLoadGraph ~= nil then
					motor.debugLoadGraph:delete()
				end

				if motor.debugRPMGraphSmooth ~= nil then
					motor.debugRPMGraphSmooth:delete()
				end

				if motor.debugRPMGraph ~= nil then
					motor.debugRPMGraph:delete()
				end

				if motor.debugAccelerationGraph ~= nil then
					motor.debugAccelerationGraph:delete()
				end
			end
		end
	end
end

function VehicleDebug:debugActionCallback(actionName, inputValue, callbackState, isAnalog)
	if VehicleDebug.state ~= callbackState then
		VehicleDebug.setState(callbackState)
		log(string.format("VehicleDebug set to '%s'", VehicleDebug.STATE_NAMES[VehicleDebug.state]))
	end
end

function VehicleDebug.updateDebug(vehicle, dt)
	if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
		VehicleDebug.drawDebugAttributeRendering(vehicle)
	elseif VehicleDebug.state == VehicleDebug.DEBUG_ATTACHER_JOINTS then
		VehicleDebug.drawDebugAttacherJoints(vehicle)
	elseif VehicleDebug.state == VehicleDebug.DEBUG_AI then
		VehicleDebug.drawDebugAIRendering(vehicle)
	elseif VehicleDebug.state == VehicleDebug.DEBUG_REVERB then
		VehicleDebug.updateReverbDebugRendering(vehicle, dt)
	elseif VehicleDebug.state == VehicleDebug.DEBUG_TUNING then
		VehicleDebug.updateTuningDebugRendering(vehicle, dt)
	end

	if VehicleDebug.state == VehicleDebug.DEBUG then
		VehicleDebug.drawDebugValues(vehicle)
	end
end

function VehicleDebug.drawDebug(vehicle)
	if vehicle.getIsEntered ~= nil and vehicle:getIsEntered() then
		local v = vehicle:getSelectedVehicle()

		if v == nil then
			v = vehicle
		end

		if VehicleDebug.state == VehicleDebug.DEBUG_PHYSICS then
			VehicleDebug.drawDebugRendering(v)
		elseif VehicleDebug.state == VehicleDebug.DEBUG_SOUNDS then
			VehicleDebug.drawSoundDebugValues(v)
		elseif VehicleDebug.state == VehicleDebug.DEBUG_ANIMATIONS then
			VehicleDebug.drawAnimationDebug(v)
		elseif VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
			VehicleDebug.drawTransmissionDebug(v)
		elseif VehicleDebug.state == VehicleDebug.DEBUG_TUNING then
			VehicleDebug.drawTuningDebug(v)
		elseif VehicleDebug.state == VehicleDebug.DEBUG_REVERB then
			VehicleDebug.drawReverbDebugRendering(v)
		end

		if VehicleDebug.state > 0 then
			setTextAlignment(RenderText.ALIGN_CENTER)

			for i = 1, VehicleDebug.NUM_STATES do
				local partSize = 1 / (VehicleDebug.NUM_STATES + 1)
				local x = partSize * i

				if VehicleDebug.state == i then
					setTextColor(0, 1, 0, 1)
					renderText(x, 0.01, 0.03, string.format("%s", VehicleDebug.STATE_NAMES[i]))
				else
					setTextColor(1, 1, 0, 1)
					renderText(x, 0.01, 0.015, string.format("SHIFT + %d: '%s'", i, VehicleDebug.STATE_NAMES[i]))
				end
			end

			setTextAlignment(RenderText.ALIGN_LEFT)
		end
	end
end

function VehicleDebug.registerActionEvents(vehicle)
	if vehicle.getIsEntered ~= nil and vehicle:getIsEntered() and VehicleDebug.state == VehicleDebug.DEBUG_ANIMATIONS then
		vehicle:addActionEvent(vehicle.actionEvents, InputAction.DEBUG_PLAYER_ENABLE, vehicle, function ()
			VehicleDebug.selectedAnimation = VehicleDebug.selectedAnimation + 1
		end, false, true, false, true, nil)
	end

	if VehicleDebug.state > 0 then
		if VehicleDebug.debugActionEvents ~= nil then
			for i = 1, #VehicleDebug.debugActionEvents do
				g_inputBinding:removeActionEvent(VehicleDebug.debugActionEvents[i])
			end
		end

		VehicleDebug.debugActionEvents = {}

		for i = 1, 9 do
			local _, actionEventId = g_inputBinding:registerActionEvent(InputAction["DEBUG_VEHICLE_" .. i], VehicleDebug, VehicleDebug.debugActionCallback, false, true, false, true, i)

			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			table.insert(VehicleDebug.debugActionEvents, actionEventId)
		end
	end
end

function VehicleDebug:drawBaseDebugRendering(x, y)
	local vx, _, vz = getWorldTranslation(self.components[1].node)
	local fieldOwned = g_farmlandManager:getIsOwnedByFarmAtWorldPosition(g_currentMission:getFarmId(), vx, vz)
	local str1 = ""
	local str2 = ""
	local str3 = ""
	local str4 = ""
	local motorSpec = self.spec_motorized
	local diffSpeed = nil

	if motorSpec ~= nil then
		local motor = motorSpec.motor
		local torque = motor:getMotorAvailableTorque()
		local neededPtoTorque = motor:getMotorExternalTorque()
		local motorPower = motor:getMotorRotSpeed() * (torque - neededPtoTorque) * 1000
		str1 = str1 .. "motor:\n"
		str2 = str2 .. string.format("%1.2frpm\n", motor:getNonClampedMotorRpm())
		str1 = str1 .. "clutch:\n"
		str2 = str2 .. string.format("%1.2frpm\n", motor:getClutchRotSpeed() * 30 / math.pi)
		str1 = str1 .. "available power:\n"
		str2 = str2 .. string.format("%1.2fhp %1.2fkW\n", motorPower / 735.49875, motorPower / 1000)
		str1 = str1 .. "gear:\n"
		str2 = str2 .. string.format("%d %d (%d, %1.2f)\n", motor.gear, motor.targetGear * motor.currentDirection, motor.activeGearGroupIndex or 0, motor:getGearRatio())
		str1 = str1 .. "motor load:\n"
		str2 = str2 .. string.format("%1.2fkN %1.2fkN\n", torque, motor:getMotorAppliedTorque())
		local ptoPower = motor:getNonClampedMotorRpm() * math.pi / 30 * neededPtoTorque
		local ptoLoad = neededPtoTorque / motor:getPeakTorque()
		str3 = str3 .. "pto load:\n"
		str4 = str4 .. string.format("%.2f%% %.2fhp %.2fkW %1.2fkN\n", ptoLoad * 100, ptoPower * 1.359621, ptoPower, neededPtoTorque)
		str3 = str3 .. "motor load:\n"
		str4 = str4 .. string.format("%.2f%%\n", motorSpec.smoothedLoadPercentage * 100)
		str3 = str3 .. "motor rpm for sounds:\n"
		str4 = str4 .. string.format("%drpm\n", motor:getLastMotorRpm())
		str3 = str3 .. "brakeForce:\n"
		str4 = str4 .. string.format("%.2f\n", (self.spec_wheels or {
			brakePedal = 0
		}).brakePedal)
		local fuelFillUnitIndex = self:getConsumerFillUnitIndex(FillType.DIESEL) or self:getConsumerFillUnitIndex(FillType.ELECTRICCHARGE) or self:getConsumerFillUnitIndex(FillType.METHANE)

		if fuelFillUnitIndex ~= nil then
			local fillLevel = self:getFillUnitFillLevel(fuelFillUnitIndex)
			local fillType = self:getFillUnitFillType(fuelFillUnitIndex)
			local unit = fillType == FillType.ELECTRICCHARGE and "kw" or fillType == FillType.METHANE and "kg" or "l"
			str3 = str3 .. string.format("%s:\n", g_fillTypeManager:getFillTypeNameByIndex(fillType))
			str4 = str4 .. string.format("%.2f%s/h (%.2f%s)\n", motorSpec.lastFuelUsage, unit, fillLevel, unit)
		end

		local defFillUnitIndex = self:getConsumerFillUnitIndex(FillType.DEF)

		if defFillUnitIndex ~= nil then
			local fillLevel = self:getFillUnitFillLevel(defFillUnitIndex)
			str3 = str3 .. "DEF:\n"
			str4 = str4 .. string.format("%.2fl/h (%.2fl)\n", motorSpec.lastDefUsage, fillLevel)
		end

		local airFillUnitIndex = self:getConsumerFillUnitIndex(FillType.AIR)

		if airFillUnitIndex ~= nil then
			local fillLevel = self:getFillUnitFillLevel(airFillUnitIndex)
			str3 = str3 .. "AIR:\n"
			str4 = str4 .. string.format("%.2fl/sec (%.2fl)\n", motorSpec.lastAirUsage, fillLevel)
		end

		diffSpeed = motor.differentialRotSpeed * 3.6
	end

	str1 = str1 .. "vel acc[m/s2]:\n"
	str2 = str2 .. string.format("%1.4f\n", self.lastSpeedAcceleration * 1000 * 1000)

	if diffSpeed ~= nil then
		str1 = str1 .. "vel[km/h]:\n"
		str2 = str2 .. string.format("%1.3f\n", self:getLastSpeed())
		local lastSpeedReal = self.lastSpeedReal * 3600
		local slip = 0

		if diffSpeed > 0.01 and lastSpeedReal > 0.01 then
			slip = (diffSpeed / lastSpeedReal - 1) * 100
		end

		str1 = str1 .. "differential[km/h]:\n"
		str2 = str2 .. string.format("%1.3f (slip: %d%%)\n", diffSpeed, slip)
	else
		str1 = str1 .. "vel[km/h]:\n"
		str2 = str2 .. string.format("%1.3f\n", self:getLastSpeed())
	end

	str1 = str1 .. "field owned:\n"
	str2 = str2 .. tostring(fieldOwned) .. "\n"
	str1 = str1 .. "mass:\n"
	str2 = str2 .. string.format("%1.1fkg\n", self:getTotalMass(true) * 1000)
	str1 = str1 .. "mass incl. attach:\n"
	str2 = str2 .. string.format("%1.1fkg\n", self:getTotalMass() * 1000)

	if self.spec_attachable ~= nil then
		local brakePedal = 0

		if self.spec_wheels ~= nil then
			brakePedal = self.spec_wheels.brakePedal
		end

		local force = self:getBrakeForce() / 10
		str1 = str1 .. "brakeForce:\n"
		str2 = str2 .. string.format("%1.2f / %1.2f\n", force * brakePedal, force)
	end

	local textSize = getCorrectTextSize(0.02)

	Utils.renderMultiColumnText(x, y, textSize, {
		str1,
		str2
	}, 0.008, {
		RenderText.ALIGN_RIGHT,
		RenderText.ALIGN_LEFT
	})
	Utils.renderMultiColumnText(x + 0.22, y, textSize, {
		str3,
		str4
	}, 0.008, {
		RenderText.ALIGN_RIGHT,
		RenderText.ALIGN_LEFT
	})

	return getTextHeight(textSize, str1), getTextHeight(textSize, str3)
end

function VehicleDebug:drawWheelInfoRendering(x, y)
	if self.isServer then
		local specWheels = self.spec_wheels

		if specWheels ~= nil and table.getn(specWheels.wheels) > 0 then
			local wheelsStrs = {
				"\n",
				"loSlip\n",
				"laSlip\n",
				"load\n",
				"frict.\n",
				"comp.\n",
				"rpm\n",
				"steer.\n",
				"radius\n",
				"loStiff\n",
				"laStiff\n"
			}

			for i, wheel in ipairs(specWheels.wheels) do
				if wheel.wheelShapeCreated then
					local susp = 100 * (wheel.netInfo.y - (wheel.positionY + wheel.deltaY - 1.2 * wheel.suspTravel)) / wheel.suspTravel - 20
					local rpm = getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape) * 30 / math.pi
					local longSlip, latSlip = getWheelShapeSlip(wheel.node, wheel.wheelShape)
					local gravity = 9.81
					local tireLoad = getWheelShapeContactForce(wheel.node, wheel.wheelShape)

					if tireLoad ~= nil then
						local nx, ny, nz = getWheelShapeContactNormal(wheel.node, wheel.wheelShape)
						local dx, dy, dz = localDirectionToWorld(wheel.node, 0, -1, 0)
						tireLoad = -tireLoad * MathUtil.dotProduct(dx, dy, dz, nx, ny, nz)
						tireLoad = tireLoad + math.max(ny * gravity, 0) * wheel.mass
					else
						tireLoad = 0
					end

					wheelsStrs[1] = wheelsStrs[1] .. string.format("%d:\n", i)
					wheelsStrs[2] = wheelsStrs[2] .. string.format("%2.2f\n", longSlip)
					wheelsStrs[3] = wheelsStrs[3] .. string.format("%2.2f\n", latSlip)
					wheelsStrs[4] = wheelsStrs[4] .. string.format("%2.2f\n", tireLoad / gravity)
					wheelsStrs[5] = wheelsStrs[5] .. string.format("%2.2f\n", wheel.sinkFrictionScaleFactor * wheel.frictionScale * wheel.tireGroundFrictionCoeff)
					wheelsStrs[6] = wheelsStrs[6] .. string.format("%1.0f%%\n", susp)
					wheelsStrs[7] = wheelsStrs[7] .. string.format("%3.1f\n", rpm)
					wheelsStrs[8] = wheelsStrs[8] .. string.format("%6.3f\n", math.deg(wheel.steeringAngle))
					wheelsStrs[9] = wheelsStrs[9] .. string.format("%.2f\n", wheel.radius)
					wheelsStrs[10] = wheelsStrs[10] .. string.format("%.2f\n", wheel.sinkFrictionScaleFactor * wheel.maxLongStiffness)
					wheelsStrs[11] = wheelsStrs[11] .. string.format("%.2f\n", wheel.sinkLatStiffnessFactor * wheel.maxLatStiffness)
				end
			end

			local textSize = getCorrectTextSize(0.02)

			Utils.renderMultiColumnText(x, y, textSize, wheelsStrs, 0.008, {
				RenderText.ALIGN_RIGHT,
				RenderText.ALIGN_LEFT
			})

			return getTextHeight(textSize, wheelsStrs[1])
		end
	end

	return 0
end

function VehicleDebug:drawWheelSlipGraphs()
	if self.isServer then
		local specWheels = self.spec_wheels

		if specWheels ~= nil and table.getn(specWheels.wheels) > 0 then
			for i, wheel in ipairs(specWheels.wheels) do
				if wheel.wheelShapeCreated then
					local longSlip, latSlip = getWheelShapeSlip(wheel.node, wheel.wheelShape)
					local gravity = 9.81
					local tireLoad = getWheelShapeContactForce(wheel.node, wheel.wheelShape)

					if tireLoad ~= nil then
						local nx, ny, nz = getWheelShapeContactNormal(wheel.node, wheel.wheelShape)
						local dx, dy, dz = localDirectionToWorld(wheel.node, 0, -1, 0)
						tireLoad = -tireLoad * MathUtil.dotProduct(dx, dy, dz, nx, ny, nz)
						tireLoad = tireLoad + math.max(ny * gravity, 0) * wheel.mass
					else
						tireLoad = 0
					end

					local longMaxSlip = 1
					local latMaxSlip = 0.9
					local sizeX = 0.11
					local sizeY = 0.15
					local spacingX = 0.028
					local spacingY = 0.013
					local x = 0.028 + (sizeX + spacingX) * (i - 1)
					local longY = 1 - spacingY - sizeY
					local latY = longY - spacingY - sizeY
					local numGraphValues = 20
					local longGraph = wheel.debugLongitudalFrictionGraph

					if longGraph == nil then
						longGraph = Graph.new(numGraphValues, x, longY, sizeX, sizeY, 0, 0.0001, true, "", Graph.STYLE_LINES)

						longGraph:setColor(1, 1, 1, 1)

						wheel.debugLongitudalFrictionGraph = longGraph
					else
						longGraph.height = sizeY
						longGraph.width = sizeX
						longGraph.bottom = longY
						longGraph.left = x
					end

					longGraph.maxValue = 0.01

					for s = 1, numGraphValues do
						local longForce, _ = computeWheelShapeTireForces(wheel.node, wheel.wheelShape, (s - 1) / (numGraphValues - 1) * longMaxSlip, latSlip, tireLoad)

						longGraph:setValue(s, longForce)

						longGraph.maxValue = math.max(longGraph.maxValue, longForce)
					end

					local latGraph = wheel.debugLateralFrictionGraph

					if latGraph == nil then
						latGraph = Graph.new(numGraphValues, x, latY, sizeX, sizeY, 0, 0.0001, true, "", Graph.STYLE_LINES)

						latGraph:setColor(1, 1, 1, 1)

						wheel.debugLateralFrictionGraph = latGraph
					else
						latGraph.height = sizeY
						latGraph.width = sizeX
						latGraph.bottom = longY
						latGraph.left = x
					end

					latGraph.maxValue = 0.01

					for s = 1, numGraphValues do
						local _, latForce = computeWheelShapeTireForces(wheel.node, wheel.wheelShape, longSlip, (s - 1) / (numGraphValues - 1) * latMaxSlip, tireLoad)
						latForce = math.abs(latForce)

						latGraph:setValue(s, latForce)

						latGraph.maxValue = math.max(latGraph.maxValue, latForce)
					end

					local longSlipOverlay = wheel.debugLongitudalFrictionSlipOverlay

					if longSlipOverlay == nil then
						longSlipOverlay = createImageOverlay("dataS/scripts/shared/graph_pixel.png")

						setOverlayColor(longSlipOverlay, 0, 1, 0, 0.2)

						wheel.debugLongitudalFrictionSlipOverlay = longSlipOverlay
					end

					local latSlipOverlay = wheel.debugLateralFrictionSlipOverlay

					if latSlipOverlay == nil then
						latSlipOverlay = createImageOverlay("dataS/scripts/shared/graph_pixel.png")

						setOverlayColor(latSlipOverlay, 0, 1, 0, 0.2)

						wheel.debugLateralFrictionSlipOverlay = latSlipOverlay
					end

					longGraph:draw()
					latGraph:draw()

					local longForce, latForce = computeWheelShapeTireForces(wheel.node, wheel.wheelShape, longSlip, latSlip, tireLoad)

					renderOverlay(longSlipOverlay, x, longY, sizeX * math.min(math.abs(longSlip) / longMaxSlip, 1), sizeY * math.min(math.abs(longForce) / longGraph.maxValue, 1))
					renderOverlay(latSlipOverlay, x, latY, sizeX * math.min(math.abs(latSlip) / latMaxSlip, 1), sizeY * math.min(math.abs(latForce) / latGraph.maxValue, 1))
				end
			end
		end
	end
end

function VehicleDebug:drawDifferentialInfoRendering(x, y)
	local motorSpec = self.spec_motorized

	if motorSpec ~= nil and motorSpec.differentials ~= nil then
		local getSpeedsOfDifferential = nil

		function getSpeedsOfDifferential(diff)
			local specWheels = self.spec_wheels
			local speed1, speed2 = nil

			if diff.diffIndex1IsWheel then
				local wheel = specWheels.wheels[diff.diffIndex1]
				speed1 = 0

				if wheel.wheelShapeCreated then
					speed1 = getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape) * wheel.radius
				end
			else
				local s1, s2 = getSpeedsOfDifferential(motorSpec.differentials[diff.diffIndex1 + 1])
				speed1 = (s1 + s2) / 2
			end

			if diff.diffIndex2IsWheel then
				local wheel = specWheels.wheels[diff.diffIndex2]
				speed2 = 0

				if wheel.wheelShapeCreated then
					speed2 = getWheelShapeAxleSpeed(wheel.node, wheel.wheelShape) * wheel.radius
				end
			else
				local s1, s2 = getSpeedsOfDifferential(motorSpec.differentials[diff.diffIndex2 + 1])
				speed2 = (s1 + s2) / 2
			end

			return speed1, speed2
		end

		local function getRatioOfDifferential(speed1, speed2)
			local ratio = math.abs(math.max(speed1, speed2)) / math.max(math.abs(math.min(speed1, speed2)), 0.001)

			return ratio
		end

		local diffStrs = {
			"\n",
			"torqueRatio\n",
			"maxSpeedRatio\n",
			"actualSpeedRatio\n"
		}

		for i, diff in pairs(motorSpec.differentials) do
			diffStrs[1] = diffStrs[1] .. string.format("%d:\n", i)
			diffStrs[2] = diffStrs[2] .. string.format("%2.2f\n", diff.torqueRatio)
			diffStrs[3] = diffStrs[3] .. string.format("%2.2f\n", diff.maxSpeedRatio)
			local speed1, speed2 = getSpeedsOfDifferential(diff)
			local ratio = getRatioOfDifferential(speed1, speed2)
			diffStrs[4] = diffStrs[4] .. string.format("%2.2f\n", ratio)
		end

		Utils.renderMultiColumnText(x, y, getCorrectTextSize(0.02), diffStrs, 0.008, {
			RenderText.ALIGN_RIGHT,
			RenderText.ALIGN_LEFT
		})
	end
end

function VehicleDebug:drawMotorGraphs(x, y, sizeX, sizeY, horizontal)
	if self.isServer then
		local motorSpec = self.spec_motorized

		if motorSpec ~= nil then
			local motor = motorSpec.motor
			local curveOverlay = motor.debugCurveOverlay

			if curveOverlay == nil then
				curveOverlay = createImageOverlay("dataS/scripts/shared/graph_pixel.png")

				setOverlayColor(curveOverlay, 0, 1, 0, 0.2)

				motor.debugCurveOverlay = curveOverlay
			end

			local torqueCurve = motor:getTorqueCurve()
			local numTorqueValues = #torqueCurve.keyframes
			local minRpm = math.min(motor:getMinRpm(), torqueCurve.keyframes[1].time)
			local maxRpm = math.max(motor:getMaxRpm(), torqueCurve.keyframes[numTorqueValues].time)
			local torqueGraph = motor.debugTorqueGraph
			local powerGraph = motor.debugPowerGraph

			if torqueGraph == nil then
				local numValues = numTorqueValues * 32
				torqueGraph = Graph.new(numValues, x, y, sizeX, sizeY, 0, 0.0001, true, "kN", Graph.STYLE_LINES)

				torqueGraph:setColor(1, 1, 1, 1)

				motor.debugTorqueGraph = torqueGraph
				powerGraph = Graph.new(numValues, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)

				powerGraph:setColor(1, 0, 0, 1)

				motor.debugPowerGraph = powerGraph
				torqueGraph.maxValue = 0.01
				powerGraph.maxValue = 0.01

				for s = 1, numValues do
					local rpm = (s - 1) / (numValues - 1) * (torqueCurve.keyframes[numTorqueValues].time - torqueCurve.keyframes[1].time) + torqueCurve.keyframes[1].time
					local torque = motor:getTorqueCurveValue(rpm)
					local power = torque * 1000 * rpm * math.pi / 30
					local hpPower = power / 735.49875
					local posX = (rpm - minRpm) / (maxRpm - minRpm)

					torqueGraph:setValue(s, torque)

					torqueGraph.maxValue = math.max(torqueGraph.maxValue, torque)

					torqueGraph:setXPosition(s, posX)
					powerGraph:setValue(s, hpPower)

					powerGraph.maxValue = math.max(powerGraph.maxValue, hpPower)

					powerGraph:setXPosition(s, posX)
				end
			else
				torqueGraph.height = sizeY
				torqueGraph.width = sizeX
				torqueGraph.bottom = y
				torqueGraph.left = x
				powerGraph.height = sizeY
				powerGraph.width = sizeX
				powerGraph.bottom = y
				powerGraph.left = x
			end

			torqueGraph:draw()
			powerGraph:draw()
			renderOverlay(curveOverlay, x, y, sizeX * MathUtil.clamp((motor:getNonClampedMotorRpm() - minRpm) / (maxRpm - minRpm), 0, 1), sizeY)

			if horizontal then
				x = x + sizeX + 0.013
			else
				y = y - sizeY - 0.013
			end

			local maxSpeed = motor:getMaximumForwardSpeed()
			local debugGraphs = motor.debugGraphs

			if debugGraphs == nil then
				local numVelocityValues = 20
				local numGears = 1
				local gears = motor.forwardGears

				if motor.currentDirection < 0 then
					gears = motor.backwardGears or gears
				end

				if motor.minForwardGearRatio == nil and gears ~= nil then
					numGears = #gears
				end

				debugGraphs = {}
				motor.debugGraphs = debugGraphs

				for gear = 1, numGears do
					local effTorqueGraph = Graph.new(numVelocityValues, x, y, sizeX, sizeY, 0, 0.0001, true, "kN", Graph.STYLE_LINES)

					effTorqueGraph:setColor(1, 1, 1, 1)
					table.insert(debugGraphs, effTorqueGraph)

					local effPowerGraph = Graph.new(numVelocityValues, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)

					effPowerGraph:setColor(1, 0, 0, 1)
					table.insert(debugGraphs, effPowerGraph)

					local effGearRatioGraph = Graph.new(numVelocityValues, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)

					effGearRatioGraph:setColor(0.35, 1, 0.85, 1)
					table.insert(debugGraphs, effGearRatioGraph)

					local effRpmGraph = Graph.new(numVelocityValues, x, y, sizeX, sizeY, 0, 0.0001, false, "", Graph.STYLE_LINES)

					effRpmGraph:setColor(0.18, 0.18, 1, 1)
					table.insert(debugGraphs, effRpmGraph)

					effTorqueGraph.maxValue = 0.01
					effPowerGraph.maxValue = 0.01
					effGearRatioGraph.maxValue = 0.01
					effRpmGraph.maxValue = 0.01

					for s = 1, numVelocityValues do
						local speed = (s - 1) / (numVelocityValues - 1) * maxSpeed
						local _, gearRatio = nil

						if numGears == 1 then
							_, gearRatio = motor:getBestGear(1, speed * 30 / math.pi, 0, math.huge, 0)
						else
							gearRatio = gears[gear].ratio
						end

						local gearRpm = speed * 30 / math.pi * gearRatio
						local torque = torqueCurve:get(gearRpm)
						local power = torque * 1000 * gearRpm * math.pi / 30
						local hpPower = power / 735.49875

						if minRpm <= gearRpm and gearRpm <= maxRpm then
							effTorqueGraph:setValue(s, torque)

							effTorqueGraph.maxValue = math.max(effTorqueGraph.maxValue, torque)

							effPowerGraph:setValue(s, hpPower)

							effPowerGraph.maxValue = math.max(effPowerGraph.maxValue, hpPower)

							effGearRatioGraph:setValue(s, gearRatio)

							effGearRatioGraph.maxValue = math.max(effGearRatioGraph.maxValue, gearRatio)

							effRpmGraph:setValue(s, gearRpm)

							effRpmGraph.maxValue = math.max(effRpmGraph.maxValue, gearRpm)
						end
					end
				end
			else
				for i = 1, #debugGraphs do
					local graph = debugGraphs[i]
					graph.height = sizeY
					graph.width = sizeX
					graph.bottom = y
					graph.left = x
				end
			end

			for _, graph in pairs(debugGraphs) do
				graph:draw()
			end

			renderOverlay(curveOverlay, x, y, sizeX * MathUtil.clamp(self.lastSpeedReal * 1000 / maxSpeed, 0, 1), sizeY)

			if horizontal then
				x = x + sizeX + 0.013
			else
				y = y - sizeY - 0.013
			end

			VehicleDebug.drawMotorLoadGraph(self, x, y, sizeX, sizeY)
		end
	end
end

function VehicleDebug:drawMotorLoadGraph(x, y, sizeX, sizeY)
	if self.isServer then
		local motorSpec = self.spec_motorized

		if motorSpec ~= nil then
			local motor = motorSpec.motor
			local numValues = 500
			local loadGraph = motor.debugLoadGraph
			local loadGraphSmooth = motor.debugLoadGraphSmooth

			if loadGraph == nil then
				loadGraph = Graph.new(numValues, x, y, sizeX, sizeY, 0, 100, true, "%", Graph.STYLE_LINES, 0.1, "time")

				loadGraph:setColor(1, 1, 1, 0.3)

				motor.debugLoadGraph = loadGraph
				loadGraphSmooth = Graph.new(numValues, x, y, sizeX, sizeY, 0, 100, false, "", Graph.STYLE_LINES)

				loadGraphSmooth:setColor(0, 1, 0, 1)

				motor.debugLoadGraphSmooth = loadGraphSmooth
			else
				loadGraph.height = sizeY
				loadGraph.width = sizeX
				loadGraph.bottom = y
				loadGraph.left = x
				loadGraphSmooth.height = sizeY
				loadGraphSmooth.width = sizeX
				loadGraphSmooth.bottom = y
				loadGraphSmooth.left = x
			end

			if loadGraph ~= nil and loadGraphSmooth ~= nil then
				local rawLoad = motor:getMotorAppliedTorque() / math.max(motor:getMotorAvailableTorque(), 0.0001)

				loadGraph:addValue(rawLoad * 100, nil, true)
				loadGraphSmooth:addValue(motorSpec.smoothedLoadPercentage * 100, nil, true)
			end

			loadGraph:draw()
			loadGraphSmooth:draw()
		end
	end
end

function VehicleDebug:drawMotorRPMGraph(x, y, sizeX, sizeY)
	if self.isServer then
		local motorSpec = self.spec_motorized

		if motorSpec ~= nil then
			local motor = motorSpec.motor
			local numValues = 500
			local rpmGraph = motor.debugRPMGraph
			local rpmGraphSmooth = motor.debugRPMGraphSmooth

			if rpmGraph == nil then
				rpmGraph = Graph.new(numValues, x, y, sizeX, sizeY, motor:getMinRpm(), motor:getMaxRpm(), true, " RPM", Graph.STYLE_LINES, 0.1, "")

				rpmGraph:setColor(1, 1, 1, 0.3)

				motor.debugRPMGraph = rpmGraph
				rpmGraphSmooth = Graph.new(numValues, x, y, sizeX, sizeY, motor:getMinRpm(), motor:getMaxRpm(), false, "", Graph.STYLE_LINES)

				rpmGraphSmooth:setColor(0, 1, 0, 1)

				motor.debugRPMGraphSmooth = rpmGraphSmooth
			else
				rpmGraph.height = sizeY
				rpmGraph.width = sizeX
				rpmGraph.bottom = y
				rpmGraph.left = x
				rpmGraphSmooth.height = sizeY
				rpmGraphSmooth.width = sizeX
				rpmGraphSmooth.bottom = y
				rpmGraphSmooth.left = x
			end

			if rpmGraph ~= nil and rpmGraphSmooth ~= nil then
				rpmGraph:addValue(motor:getLastRealMotorRpm(), nil, true)
				rpmGraphSmooth:addValue(motor:getLastModulatedMotorRpm(), nil, true)
			end

			rpmGraph:draw()
			rpmGraphSmooth:draw()
		end
	end
end

function VehicleDebug:drawMotorAccelerationGraph(x, y, sizeX, sizeY)
	if self.isServer then
		local motorSpec = self.spec_motorized

		if motorSpec ~= nil then
			local motor = motorSpec.motor
			local numValues = 250
			local accGraph = motor.debugAccelerationGraph

			if accGraph == nil then
				accGraph = Graph.new(numValues, x, y, sizeX, sizeY, 0, 1, true, " Load Factor", Graph.STYLE_LINES, 0.1, "")

				accGraph:setColor(1, 1, 1, 0.3)

				motor.debugAccelerationGraph = accGraph
				motor.debugAccelerationGraphAddValue = true
			else
				accGraph.height = sizeY
				accGraph.width = sizeX
				accGraph.bottom = y
				accGraph.left = x
			end

			if accGraph ~= nil then
				if motor.debugAccelerationGraphAddValue then
					accGraph:addValue(motor.constantAccelerationCharge, nil, true)
				end

				motor.debugAccelerationGraphAddValue = not motor.debugAccelerationGraphAddValue
			end

			accGraph:draw()
		end
	end
end

function VehicleDebug:drawDebugRendering()
	local textHeight1, _ = VehicleDebug.drawBaseDebugRendering(self, 0.015, 0.65)
	local x = 0.015
	local y = 0.64 - textHeight1 - 0.005
	local height = VehicleDebug.drawWheelInfoRendering(self, x, y)

	VehicleDebug.drawDifferentialInfoRendering(self, x, y - (height + getCorrectTextSize(0.02)))
	VehicleDebug.drawWheelSlipGraphs(self)
	VehicleDebug.drawMotorGraphs(self, 0.65, 0.44, 0.25, 0.2, false)
end

function VehicleDebug:drawTuningDebug()
	local textHeight1, _ = VehicleDebug.drawBaseDebugRendering(self, 0.015, 0.9)
	local x = 0.015
	local y = 0.89 - textHeight1 - 0.005
	local height = VehicleDebug.drawWheelInfoRendering(self, x, y)

	VehicleDebug.drawDifferentialInfoRendering(self, x, y - (height + getCorrectTextSize(0.02)))
end

function VehicleDebug:drawTransmissionDebug()
	local textHeight1, _ = VehicleDebug.drawBaseDebugRendering(self, 0.015, 0.65)

	VehicleDebug.drawMotorGraphs(self, 0.01, 0.73, 0.25, 0.2, true)

	local str1 = ""
	local str2 = ""
	local motorSpec = self.spec_motorized

	if motorSpec ~= nil then
		local motor = motorSpec.motor
		str1 = str1 .. "\ngear start values:\n"
		str2 = str2 .. "\n\n"
		str1 = str1 .. "peakPower:\n"
		str2 = str2 .. string.format("%d/%dkW\n", motor.startGearValues.availablePower, motor.peakMotorPower)
		str1 = str1 .. "maxForce:\n"
		str2 = str2 .. string.format("%.2fkN\n", motor.startGearValues.maxForce)
		str1 = str1 .. "mass:\n"
		str2 = str2 .. string.format("%.2fto\n", motor.startGearValues.mass)
		str1 = str1 .. "slope angle:\n"
		str2 = str2 .. string.format("%.2f°\n", math.deg(motor.startGearValues.slope))
		str1 = str1 .. "slope percentage:\n"
		str2 = str2 .. string.format("%.2f%%\n", math.atan(motor.startGearValues.slope) * 100)
		str1 = str1 .. "dirDiffXZ:\n"
		str2 = str2 .. string.format("%.2f\n", motor.startGearValues.massDirectionDifferenceXZ)
		str1 = str1 .. "dirDiffY:\n"
		str2 = str2 .. string.format("%.2f\n", motor.startGearValues.massDirectionDifferenceY)
		str1 = str1 .. "dirFac:\n"
		str2 = str2 .. string.format("%.2f\n", motor.startGearValues.massDirectionFactor)
		str1 = str1 .. "massFac:\n"
		str2 = str2 .. string.format("%.2f\n", motor.startGearValues.massFactor)
		str1 = str1 .. "speedLimit:\n"
		str2 = str2 .. string.format("%.1f / %.1f \n", motor.speedLimit, self:getSpeedLimit(true))
		str1 = str1 .. "auto shift allowed:\n"
		str2 = str2 .. string.format("%s\n", self:getIsAutomaticShiftingAllowed())
		str1 = str1 .. "gear/group change allowed:\n"
		str2 = str2 .. string.format("%s/%s\n", motor:getIsGearChangeAllowed(), motor:getIsGearGroupChangeAllowed())
		str1 = str1 .. "gear group shift timer:\n"
		str2 = str2 .. string.format("%.1f/%.1f sec\n", motor.gearGroupUpShiftTimer / 1000, motor.gearGroupUpShiftTime / 1000)
		str1 = str1 .. "clutch slipping simer:\n"
		str2 = str2 .. string.format("%d ms\n", motor.clutchSlippingTimer)
		str1 = str1 .. "motor can run:\n"
		str2 = str2 .. string.format("%s\n", motor:getCanMotorRun())
		str1 = str1 .. "stall timer:\n"
		str2 = str2 .. string.format("%.2f\n", motor.stallTimer)
		str1 = str1 .. "turbo scale:\n"
		str2 = str2 .. string.format("%d%%\n", motor.lastTurboScale * 100)
		str1 = str1 .. "blowOffValveState:\n"
		str2 = str2 .. string.format("%d%%\n", motor.blowOffValveState * 100)

		Utils.renderMultiColumnText(0.015, 0.65 - textHeight1, getCorrectTextSize(0.018), {
			str1,
			str2
		}, 0.008, {
			RenderText.ALIGN_RIGHT,
			RenderText.ALIGN_LEFT
		})

		if motor.forwardGears or motor.backwardGears then
			local x = 0.222
			local y = 0.15
			local infoWidth = 0.05
			local minWidthPerGear = 0.035
			local gears = motor.forwardGears

			if motor.currentDirection < 0 then
				gears = motor.backwardGears or gears
			end

			local width = #gears * minWidthPerGear + infoWidth
			local height = 0.35
			local pixelWidth = 1 / g_screenWidth
			local pixelHeight = 1 / g_screenHeight

			drawOutlineRect(x, y, width, height, pixelWidth, pixelHeight, 0, 0, 0, 1)
			drawFilledRect(x, y, width, height, 0, 0, 0, 0.4)

			local gearAreaWidth = width - infoWidth

			drawFilledRect(x + infoWidth, y, pixelWidth, height, 0, 0, 0, 1)
			drawFilledRect(x + infoWidth, y + height * 0.9, gearAreaWidth, pixelHeight, 0, 0, 0, 1)
			drawFilledRect(x + infoWidth, y + height * 0.3, gearAreaWidth, pixelHeight, 0, 0, 0, 1)

			local groupRatioReal = motor:getGearRatioMultiplier()
			local groupRatio = math.abs(motor:getGearRatioMultiplier())
			local numGears = #gears
			local gearWidth = gearAreaWidth / numGears
			local gearMaxHeight = height * 0.6
			local textOffset = 0.0075
			local maxDiffSpeed = 1

			for i = 1, numGears do
				maxDiffSpeed = math.max(maxDiffSpeed, motor.maxRpm * math.pi / (30 * gears[i].ratio * groupRatio) * 3.6)
			end

			local numGearValues = 5
			local offsetPerValue = height * 0.3 / numGearValues
			local lastDiffSpeedAfterChange, lastMaxPower = nil

			for i = 1, numGears do
				local gear = gears[i]
				lastDiffSpeedAfterChange = lastDiffSpeedAfterChange or gear.lastDiffSpeedAfterChange
				lastMaxPower = lastMaxPower or gear.lastMaxPower
				local minGearSpeed = motor.minRpm * math.pi / (30 * gear.ratio * groupRatio) * 3.6
				local maxGearSpeed = motor.maxRpm * math.pi / (30 * gear.ratio * groupRatio) * 3.6
				local pos = minGearSpeed / maxDiffSpeed * gearMaxHeight
				local h = (maxGearSpeed - minGearSpeed) / maxDiffSpeed * gearMaxHeight
				local gearX = x + infoWidth + gearWidth * (i - 1)
				local posY = y + height * 0.3 + pixelHeight + pos

				drawFilledRect(gearX, posY, gearWidth, h, motor.gear ~= i and gear.lastHasPower and 1 or 0.05, (motor.gear == i or gear.lastHasPower) and 1 or 0.05, 0.05, 0.85)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(gearX + gearWidth * 0.5, posY + textOffset * 0.5, 0.015, string.format("%.2f", gear.ratio * groupRatio))

				local factor = motor:getStartInGearFactor(gear.ratio * groupRatio)

				if factor < motor.startGearThreshold then
					setTextColor(0, 1, 0, 1)
				else
					setTextColor(1, 0, 0, 1)
				end

				renderText(gearX + gearWidth * 0.5, y + height * 0.3 + pixelHeight + gearMaxHeight - textOffset * 2, 0.015, string.format("%.2f", factor))

				if groupRatioReal ~= groupRatio then
					factor = motor:getStartInGearFactor(gear.ratio * groupRatioReal)

					if factor < motor.startGearThreshold then
						setTextColor(0, 1, 0, 1)
					else
						setTextColor(1, 0, 0, 1)
					end

					renderText(gearX + gearWidth * 0.5, y + height * 0.3 + pixelHeight + gearMaxHeight - textOffset * 4, 0.012, string.format("%.2f", factor))
				end

				setTextColor(1, 1, 1, 1)
				renderText(gearX + gearWidth * 0.5, y + textOffset, 0.0125, string.format("%.2f %.2f", gear.lastPowerFactor or 0, gear.lastRpmFactor or 0))
				renderText(gearX + gearWidth * 0.5, y + textOffset + offsetPerValue * 1, 0.0125, string.format("%.2f %.2f", gear.lastGearChangeFactor or 0, gear.lastRpmPreferenceFactor or 0))

				if gear.nextPowerValid then
					setTextColor(0, 1, 0, 1)
				else
					setTextColor(1, 0, 0, 1)
				end

				renderText(gearX + gearWidth * 0.5, y + textOffset + offsetPerValue * 2, 0.015, string.format("%d", gear.lastNextPower or -1))

				if gear.nextRpmValid then
					setTextColor(0, 1, 0, 1)
				else
					setTextColor(1, 0, 0, 1)
				end

				renderText(gearX + gearWidth * 0.5, y + textOffset + offsetPerValue * 3, 0.015, string.format("%d", gear.lastNextRpm or -1))
				setTextColor(1, 1, 1, 1)
				renderText(gearX + gearWidth * 0.5, y + textOffset + offsetPerValue * 4, 0.015, string.format("%.2f", gear.lastTradeoff or 0))
			end

			setTextAlignment(RenderText.ALIGN_CENTER)
			renderText(x + infoWidth * 0.5, y + height * 0.3 + pixelHeight + gearMaxHeight - textOffset * 2, 0.015, "startFactor")

			local bestGear, maxFactorGroup = motor:getBestStartGear(motor.currentGears)

			renderText(x + infoWidth * 0.5, y + height * 0.3 + pixelHeight + gearMaxHeight - textOffset * 4, 0.015, string.format("best %d>%d", maxFactorGroup, bestGear))
			renderText(x + infoWidth * 0.5, y + textOffset, 0.01, "pwr/rpm")
			renderText(x + infoWidth * 0.5, y + textOffset + offsetPerValue * 1, 0.01, "gearC/rpmPref")
			renderText(x + infoWidth * 0.5, y + textOffset + offsetPerValue * 2, 0.01, string.format("nextPwr (%d)", lastMaxPower or -1))
			renderText(x + infoWidth * 0.5, y + textOffset + offsetPerValue * 3, 0.01, "nextRpm")
			renderText(x + infoWidth * 0.5, y + textOffset + offsetPerValue * 4, 0.01, "tradeoff")

			local diffSpeed = math.abs(motor.differentialRotSpeed * 3.6)
			local speedHeight = y + height * 0.3 + diffSpeed / maxDiffSpeed * (gearMaxHeight - pixelHeight) + pixelHeight

			setTextBold(true)
			setTextAlignment(RenderText.ALIGN_CENTER)
			renderText(x + infoWidth * 0.5, speedHeight - 0.005, 0.015, string.format("%.2f", diffSpeed))
			setTextBold(false)

			if lastDiffSpeedAfterChange ~= nil then
				setTextAlignment(RenderText.ALIGN_LEFT)
				renderText(x + infoWidth * 1.1, y + height * 0.95 - 0.005, 0.01, string.format("Speed after change: %.2fkm/h (%.1f sec)", lastDiffSpeedAfterChange * 3.6, motor.gearChangeTime / 1000))
			end

			drawFilledRect(x + infoWidth, speedHeight, gearAreaWidth, pixelHeight, 0, 1, 0, 0.5)
		end
	end
end

function VehicleDebug.drawDebugAttributeRendering(vehicle)
	local tempNode = createTransformGroup("tempVehicleSizeCenter")

	link(vehicle.rootNode, tempNode)
	setTranslation(tempNode, vehicle.size.widthOffset, vehicle.size.heightOffset + vehicle.size.height / 2, vehicle.size.lengthOffset)
	DebugUtil.drawDebugCube(tempNode, vehicle.size.width, vehicle.size.height, vehicle.size.length, 0, 0, 1)
	delete(tempNode)

	if vehicle.spec_attacherJoints ~= nil then
		for _, implement in pairs(vehicle.spec_attacherJoints.attachedImplements) do
			if implement.object ~= nil then
				local jointDesc = vehicle.spec_attacherJoints.attacherJoints[implement.jointDescIndex]
				local x, y, z = getWorldTranslation(jointDesc.jointTransform)

				drawDebugPoint(x, y, z, 1, 0, 0, 1)

				local groundRaycastResult = {
					raycastCallback = function (self, transformId, x, y, z, distance)
						if vehicle.vehicleNodes[transformId] == nil and implement.object.vehicleNodes[transformId] == nil then
							self.groundDistance = distance

							return false
						end

						return true
					end,
					vehicle = vehicle,
					object = implement.object,
					groundDistance = 0
				}

				raycastAll(x, y, z, 0, -1, 0, "raycastCallback", 4, groundRaycastResult)
				drawDebugLine(x, y, z, 0, 1, 0, x, y - groundRaycastResult.groundDistance, z, 0, 1, 0)
				drawDebugPoint(x, y - groundRaycastResult.groundDistance, z, 1, 0, 0, 1)
				Utils.renderTextAtWorldPosition(x, y + 0.1, z, string.format("%.4f", groundRaycastResult.groundDistance), getCorrectTextSize(0.02), 0)

				local attacherJoint = implement.object:getActiveInputAttacherJoint()

				if #attacherJoint.heightNodes > 0 then
					for i = 1, #attacherJoint.heightNodes do
						local heightNode = attacherJoint.heightNodes[i]
						local x, y, z = getWorldTranslation(heightNode.node)
						local h = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)

						DebugUtil.drawDebugNode(heightNode.node, string.format("HeightNode: %.3f", y - h))
					end
				end
			end
		end

		for _, attacherJoint in pairs(vehicle:getAttacherJoints()) do
			DebugUtil.drawDebugNode(attacherJoint.jointTransform, getName(attacherJoint.jointTransform))

			if attacherJoint.bottomArm ~= nil and attacherJoint.bottomArm.referenceDistance ~= nil then
				local x1, y1, z1 = localToWorld(attacherJoint.bottomArm.translationNode, 0.435, 0, attacherJoint.bottomArm.referenceDistance * attacherJoint.bottomArm.zScale)
				local x2, y2, z2 = localToWorld(attacherJoint.bottomArm.translationNode, -0.435, 0, attacherJoint.bottomArm.referenceDistance * attacherJoint.bottomArm.zScale)

				drawDebugLine(x1, y1 - 0.1, z1, 0, 1, 0, x1, y1 + 0.1, z1, 0, 1, 0, true)
				drawDebugLine(x2, y2 - 0.1, z2, 0, 1, 0, x2, y2 + 0.1, z2, 0, 1, 0, true)
			end
		end
	end

	if vehicle.spec_attachable ~= nil then
		for _, inputAttacherJoint in pairs(vehicle:getInputAttacherJoints()) do
			if inputAttacherJoint.jointType == AttacherJoints.JOINTTYPE_IMPLEMENT then
				local x1, y1, z1 = localToWorld(inputAttacherJoint.node, 0, 0, 0.435)
				local x2, y2, z2 = localToWorld(inputAttacherJoint.node, 0, 0, -0.435)

				drawDebugLine(x1, y1 - 0.1, z1, 0, 1, 0, x1, y1 + 0.1, z1, 0, 1, 0, true)
				drawDebugLine(x2, y2 - 0.1, z2, 0, 1, 0, x2, y2 + 0.1, z2, 0, 1, 0, true)
			end
		end
	end

	if vehicle.spec_wheels ~= nil then
		local wheels = vehicle:getWheels()

		for i = 1, #wheels do
			local wheel = wheels[i]

			if not wheel.isCareWheel then
				local x0, y0, z0 = getWorldTranslation(wheel.destructionStartNode)
				local x1, _, z1 = getWorldTranslation(wheel.destructionWidthNode)
				local x2, _, z2 = getWorldTranslation(wheel.destructionHeightNode)
				local x, z, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(x0, z0, x1, z1, x2, z2)

				DebugUtil.drawDebugParallelogram(x, z, widthX, widthZ, heightX, heightZ, y0, 1, 1, 0, 0.05, true)

				if wheel.additionalWheels ~= nil then
					for _, additionalWheel in pairs(wheel.additionalWheels) do
						if additionalWheel.wheelShapeCreated then
							local width = 0.5 * additionalWheel.width
							local length = math.min(0.5, 0.5 * additionalWheel.width)
							local refNode = wheel.node

							if wheel.repr ~= wheel.driveNode then
								refNode = wheel.repr
							end

							local xShift, yShift, zShift = localToLocal(additionalWheel.wheelTire, refNode, 0, 0, 0)
							x0, y0, z0 = localToWorld(refNode, xShift + width, yShift, zShift - length)
							x1, _, z1 = localToWorld(refNode, xShift - width, yShift, zShift - length)
							x2, _, z2 = localToWorld(refNode, xShift + width, yShift, zShift + length)
							x, z, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(x0, z0, x1, z1, x2, z2)

							DebugUtil.drawDebugParallelogram(x, z, widthX, widthZ, heightX, heightZ, y0, 1, 1, 0, 0.05, true)
						end
					end
				end
			end
		end
	end

	if vehicle.spec_workArea ~= nil then
		local typedColor = {}
		local numTypes = 0

		for _, workArea in pairs(vehicle.spec_workArea.workAreas) do
			local color = typedColor[workArea.type]

			if color == nil then
				numTypes = numTypes + 1
				color = VehicleDebug.WORKAREA_COLORS[numTypes]
				typedColor[workArea.type] = color
			end

			local r, g, b, _ = unpack(color)

			DebugUtil.drawDebugArea(workArea.start, workArea.width, workArea.height, r, g, b, true)

			local x1, _, z1 = getWorldTranslation(workArea.width)
			local x2, _, z2 = getWorldTranslation(workArea.height)
			local x = x2 + (x1 - x2) * 0.5
			local z = z2 + (z1 - z2) * 0.5
			local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
			local isActive = vehicle:getIsWorkAreaActive(workArea)
			local textColor = isActive and VehicleDebug.COLOR.ACTIVE or VehicleDebug.COLOR.INACTIVE

			Utils.renderTextAtWorldPosition(x, y + 0.1, z, tostring(g_workAreaTypeManager:getWorkAreaTypeNameByIndex(workArea.type)), getCorrectTextSize(0.015), -getCorrectTextSize(0.015) * 0.5, textColor)
		end
	end

	if vehicle.getTipOcclusionAreas ~= nil then
		for _, occlusionArea in pairs(vehicle:getTipOcclusionAreas()) do
			DebugUtil.drawDebugArea(occlusionArea.start, occlusionArea.width, occlusionArea.height, 1, 1, 0, true, false, false)
		end
	end

	if vehicle.spec_foliageBending ~= nil then
		local offset = 0.25

		for _, bendingNode in ipairs(vehicle.spec_foliageBending.bendingNodes) do
			if bendingNode.id ~= nil then
				DebugUtil.drawDebugRectangle(bendingNode.node, bendingNode.minX, bendingNode.maxX, bendingNode.minZ, bendingNode.maxZ, bendingNode.yOffset, 1, 0, 0)
				DebugUtil.drawDebugRectangle(bendingNode.node, bendingNode.minX - offset, bendingNode.maxX + offset, bendingNode.minZ - offset, bendingNode.maxZ + offset, bendingNode.yOffset, 0, 1, 0)
			end
		end
	end

	if vehicle.spec_licensePlates ~= nil then
		local function drawLine(licensePlate, d1, d2, d3, leftRight)
			if math.abs(d1) ~= math.huge then
				local r1 = 1
				local g1 = 0
				local b1 = 0
				local maxY = d2

				if d2 == math.huge then
					b1 = 0
					g1 = 1
					r1 = 0
					maxY = 0.25
				end

				local r2 = 1
				local g2 = 0
				local b2 = 0
				local minY = d3

				if d3 == math.huge then
					b2 = 0
					g2 = 1
					r2 = 0
					minY = 0.25
				end

				local x1, y1, z1, x2, y2, z2 = nil

				if leftRight then
					x1, y1, z1 = localToWorld(licensePlate.node, d1, maxY, 0)
					x2, y2, z2 = localToWorld(licensePlate.node, d1, -minY, 0)
				else
					x1, y1, z1 = localToWorld(licensePlate.node, maxY, d1, 0)
					x2, y2, z2 = localToWorld(licensePlate.node, -minY, d1, 0)
				end

				drawDebugLine(x1, y1, z1, r1, g1, b1, x2, y2, z2, r2, g2, b2)
			end
		end

		for _, licensePlate in ipairs(vehicle.spec_licensePlates.licensePlates) do
			DebugUtil.drawDebugNode(licensePlate.node, "")

			local top = licensePlate.placementArea[1]
			local right = licensePlate.placementArea[2]
			local bottom = licensePlate.placementArea[3]
			local left = licensePlate.placementArea[4]

			drawLine(licensePlate, right, top, bottom, true)
			drawLine(licensePlate, -left, top, bottom, true)
			drawLine(licensePlate, top, right, left, false)
			drawLine(licensePlate, -bottom, right, left, false)
		end
	end

	if vehicle.spec_fillUnit ~= nil then
		local fillUnits = vehicle:getFillUnits()

		for i = 1, #fillUnits do
			local fillUnit = fillUnits[i]
			local autoAimTarget = fillUnit.autoAimTarget

			if autoAimTarget.node ~= nil and autoAimTarget.startZ ~= nil and autoAimTarget.endZ ~= nil then
				local startFillLevel = fillUnit.capacity * autoAimTarget.startPercentage
				local percent = MathUtil.clamp((fillUnit.fillLevel - startFillLevel) / (fillUnit.capacity - startFillLevel), 0, 1)

				if autoAimTarget.invert then
					percent = 1 - percent
				end

				local curZ = (autoAimTarget.endZ - autoAimTarget.startZ) * percent + autoAimTarget.startZ
				local x1, y1, z1 = localToWorld(getParent(autoAimTarget.node), autoAimTarget.baseTrans[1], autoAimTarget.baseTrans[2], autoAimTarget.startZ)
				local x2, y2, z2 = localToWorld(getParent(autoAimTarget.node), autoAimTarget.baseTrans[1], autoAimTarget.baseTrans[2], autoAimTarget.endZ)

				drawDebugLine(x1, y1, z1, 0, 1, 0, x2, y2, z2, 0, 1, 0, true)
				drawDebugLine(x1, y1, z1, 1, 0, 0, x1, y1 + 0.2, z1, 1, 0, 0, true)
				drawDebugLine(x2, y2, z2, 1, 0, 0, x2, y2 + 0.2, z2, 1, 0, 0, true)

				local x3, y3, z3 = localToWorld(getParent(autoAimTarget.node), autoAimTarget.baseTrans[1], autoAimTarget.baseTrans[2], curZ)

				drawDebugLine(x3, y3, z3, 0, 0, 1, x3, y3 - 0.5, z3, 0, 0, 1, true)

				local x4, y4, z4 = localToWorld(getParent(autoAimTarget.node), autoAimTarget.baseTrans[1] - 0.5, autoAimTarget.baseTrans[2], autoAimTarget.startZ + 0.75)
				local x5, y5, z5 = localToWorld(getParent(autoAimTarget.node), autoAimTarget.baseTrans[1] + 0.5, autoAimTarget.baseTrans[2], autoAimTarget.startZ + 0.75)

				drawDebugLine(x4, y4, z4, 0, 1, 1, x5, y5, z5, 0, 1, 1, true)

				x4, y4, z4 = localToWorld(getParent(autoAimTarget.node), autoAimTarget.baseTrans[1] - 0.5, autoAimTarget.baseTrans[2], autoAimTarget.endZ - 0.75)
				x5, y5, z5 = localToWorld(getParent(autoAimTarget.node), autoAimTarget.baseTrans[1] + 0.5, autoAimTarget.baseTrans[2], autoAimTarget.endZ - 0.75)

				drawDebugLine(x4, y4, z4, 0, 1, 1, x5, y5, z5, 0, 1, 1, true)
			end
		end
	end

	if vehicle.spec_dischargeable ~= nil then
		local dischargeNodes = vehicle.spec_dischargeable.dischargeNodes

		for i = 1, #dischargeNodes do
			local dischargeNode = dischargeNodes[i]
			local info = dischargeNode.info
			local sx, sy, sz = localToWorld(info.node, -info.width, 0, info.zOffset)
			local ex, ey, ez = localToWorld(info.node, info.width, 0, info.zOffset)

			drawDebugLine(sx, sy, sz, 1, 0, 1, ex, ey, ez, 1, 0, 1)
		end
	end

	if vehicle:getIsActiveForInput() and vehicle.spec_enterable ~= nil then
		local spec = vehicle.spec_enterable
		local camera = spec.cameras[spec.camIndex]

		if camera ~= nil then
			local name = getName(camera.cameraPositionNode)
			local x, y, z = getTranslation(camera.cameraPositionNode)
			local rotationNode = camera.cameraPositionNode

			if camera.rotateNode ~= nil then
				rotationNode = camera.rotateNode
			end

			local rx, ry, rz = getRotation(rotationNode)

			if camera.hasExtraRotationNode then
				rx = -((math.pi - rx) % (2 * math.pi))
				ry = (ry + math.pi) % (2 * math.pi)
				rz = (rz - math.pi) % (2 * math.pi)
			end

			local text = string.format("camera '%s': translation: %.2f %.2f %.2f  rotation: %.2f %.2f %.2f", name, x, y, z, math.deg(rx), math.deg(ry), math.deg(rz))

			setTextAlignment(RenderText.ALIGN_CENTER)
			setTextColor(0, 0, 0, 1)
			renderText(0.5 + 1 / g_screenWidth, 0.95 - 1 / g_screenHeight, 0.02, text)
			renderText(0.5 + 1 / g_screenWidth, 0.98 - 1 / g_screenHeight, 0.05, "______________________________________________________________________")
			setTextColor(1, 1, 1, 1)
			renderText(0.5, 0.95, 0.02, text)
			renderText(0.5, 0.98, 0.05, "______________________________________________________________________")
			setTextAlignment(RenderText.ALIGN_LEFT)
		end
	end

	for i, component in pairs(vehicle.components) do
		local x, y, z = getCenterOfMass(component.node)
		x, y, z = localToWorld(component.node, x, y, z)
		local dirX, dirY, dirZ = localDirectionToWorld(component.node, 0, 0, 1)
		local upX, upY, upZ = localDirectionToWorld(component.node, 0, 1, 0)

		DebugUtil.drawDebugGizmoAtWorldPos(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, "CoM comp" .. i, false)
	end

	if vehicle.spec_ikChains ~= nil then
		IKUtil.debugDrawChains(vehicle.spec_ikChains.chains, true)
	end
end

function VehicleDebug.drawDebugAIRendering(vehicle)
	if vehicle.getAIMarkers ~= nil then
		if vehicle:getIsAIActive() and vehicle:getCanImplementBeUsedForAI() then
			local leftMarker, rightMarker, backMarker = vehicle:getAIMarkers()

			DebugUtil.drawDebugNode(leftMarker, "aiMarkerLeft", true)
			DebugUtil.drawDebugNode(rightMarker, "aiMarkerRight", true)
			DebugUtil.drawDebugNode(backMarker, "aiMarkerBack", true)

			local reverserNode = vehicle:getAIToolReverserDirectionNode()

			if reverserNode ~= nil and reverserNode ~= backMarker then
				DebugUtil.drawDebugNode(reverserNode, getName(reverserNode), true)
			end
		end

		if not vehicle:getIsAIActive() then
			local collisionTrigger = vehicle:getAIImplementCollisionTrigger()

			if collisionTrigger ~= nil and collisionTrigger.node ~= nil then
				local x, y, z = getWorldTranslation(collisionTrigger.node)
				local t = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

				if y < 0 then
					t = -100
				end

				local offsetY = y - t - collisionTrigger.height * 0.5

				DebugUtil.drawDebugCube(collisionTrigger.node, collisionTrigger.width, collisionTrigger.height, collisionTrigger.length, 0, 0, 1, 0, -offsetY, collisionTrigger.length * 0.5)
			end
		end

		local IsOnlyAIImplement = true

		for _, vehicle2 in ipairs(vehicle.rootVehicle.childVehicles) do
			if vehicle2 ~= vehicle and vehicle2.getCanImplementBeUsedForAI ~= nil and vehicle2:getCanImplementBeUsedForAI() then
				IsOnlyAIImplement = false

				break
			end
		end

		if (IsOnlyAIImplement or vehicle:getIsSelected()) and vehicle.spec_aiImplement ~= nil and vehicle.spec_aiImplement.debugArea ~= nil then
			vehicle.spec_aiImplement.debugArea:update(g_currentDt)
			g_debugManager:addFrameElement(vehicle.spec_aiImplement.debugArea)
		end
	end

	if vehicle.drawDebugAIAgent ~= nil then
		vehicle:drawDebugAIAgent()
	end

	if vehicle.drawAIAgentAttachments ~= nil then
		vehicle:drawAIAgentAttachments()
	end

	if Platform.gameplay.automaticVehicleControl then
		local root = vehicle.rootVehicle

		if root.getIsControlled ~= nil and root:getIsControlled() and root.actionController ~= nil then
			root.actionController:drawDebugRendering()
		end
	end
end

function VehicleDebug.drawDebugValues(vehicle)
	local information = {}

	for k, v in ipairs(vehicle.specializations) do
		if v.updateDebugValues ~= nil then
			local values = {}

			v.updateDebugValues(vehicle, values)

			if #values > 0 then
				local info = {
					title = vehicle.specializationNames[k],
					content = values
				}

				table.insert(information, info)
			end
		end
	end

	local d = DebugInfoTable.new()

	d:createWithNodeToCamera(vehicle.rootNode, 4, information, 0.05)
	g_debugManager:addFrameElement(d)
end

function VehicleDebug.drawSoundDebugValues(vehicle)
	local x = 0.15
	local y = 0.1
	local width = 0.7
	local height = 0.8
	local textSize = 0.015
	local pixelWidth = 1 / g_screenWidth
	local pixelHeight = 1 / g_screenHeight
	local xSectionWidth = 0.1 + pixelWidth
	local lineHeight = 0.06

	local function drawBar(x, y, w, h, value, fixedValue, text, r, g, b, a, textSizeFactor)
		drawOutlineRect(x, y, w, h, pixelWidth, pixelHeight, 0, 0, 0, 1)
		drawFilledRect(x + pixelWidth, y + pixelHeight, w - pixelWidth * 2, h - pixelHeight * 2, 0, 0, 0, 0.4)
		drawFilledRect(x + pixelWidth, y + pixelHeight, w * value - pixelWidth * 2, h - pixelHeight * 2, r, g, b, a)

		if fixedValue ~= -1 then
			drawFilledRect(x + w * fixedValue, y, pixelWidth, h, 1, 0, 0, 1)
		end

		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(x + w * 0.5, y + h - textSize * 0.5 - pixelHeight * 4, textSize * 0.8 * (textSizeFactor or 1), text)
	end

	local function drawModifiers(x, y, w, h, sample, attribute)
		local modifiers = {}

		for typeIndex, type in pairs(g_soundManager.modifierTypeIndexToDesc) do
			local changeValue, t, available = g_soundManager:getSampleModifierValue(sample, attribute, typeIndex)

			if available then
				table.insert(modifiers, {
					changeValue = changeValue,
					t = t,
					name = type.name
				})
			end
		end

		if sample.maxValuePerModifier == nil then
			sample.maxValuePerModifier = {}

			for typeIndex, type in pairs(g_soundManager.modifierTypeIndexToDesc) do
				sample.maxValuePerModifier[type.name] = 0
			end
		end

		local widthPerModifier = w / #modifiers

		for i = 1, #modifiers do
			local modifier = modifiers[i]
			sample.maxValuePerModifier[modifier.name] = math.max(sample.maxValuePerModifier[modifier.name], modifier.changeValue, 1)

			drawBar(x + widthPerModifier * (i - 1), y, widthPerModifier * (i < #modifiers and 0.95 or 1), h, modifier.changeValue / sample.maxValuePerModifier[modifier.name], -1, string.format("%s raw:%.2f mod:%.2f", modifier.name, modifier.t, modifier.changeValue), 0, 0.5, 0, 0.3, 0.7)
		end
	end

	setTextColor(1, 1, 1, 1)

	local i = 1
	local lineY = y + height

	for _, sample in pairs(g_soundManager.orderedSamples) do
		local isSurfaceSound = false

		for _, surfaceSound in pairs(g_currentMission.surfaceSounds) do
			if surfaceSound.name == sample.sampleName then
				isSurfaceSound = true
			end
		end

		if sample.modifierTargetObject == vehicle and not isSurfaceSound then
			local showSample = sample.isGlsFile

			if not showSample then
				for typeIndex, type in pairs(g_soundManager.modifierTypeIndexToDesc) do
					for _, attribute in pairs({
						"volume",
						"pitch",
						"lowpassGain"
					}) do
						local _, _, available = g_soundManager:getSampleModifierValue(sample, attribute, typeIndex)
						showSample = showSample or available

						if showSample then
							break
						end
					end
				end
			end

			if showSample then
				lineY = lineY - lineHeight

				drawOutlineRect(x, lineY, xSectionWidth, lineHeight + pixelHeight, pixelWidth, pixelHeight, 0, 0, 0, 1)
				drawOutlineRect(x, lineY, width, lineHeight + pixelHeight, pixelWidth, pixelHeight, 0, 0, 0, 1)
				drawFilledRect(x, lineY, xSectionWidth, lineHeight, 0, g_soundManager:getIsSamplePlaying(sample) and 1 or 0, 0, 0.4)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(x + xSectionWidth * 0.5, lineY + lineHeight - lineHeight * 0.2 * 1 - textSize * 0.5, textSize * 1.2, sample.sampleName)

				if sample.isGlsFile then
					renderText(x + xSectionWidth * 0.5, lineY + lineHeight - lineHeight * 0.2 * 2 - textSize * 0.5, textSize * 0.8, string.format("loopSyn: rpm=%d load=%d%%", getSampleLoopSynthesisRPM(sample.soundSample, false), getSampleLoopSynthesisLoadFactor(sample.soundSample) * 100))
				end

				setTextAlignment(RenderText.ALIGN_RIGHT)
				renderText(x + xSectionWidth + xSectionWidth * 0.6, lineY + lineHeight - lineHeight * 0.25 * 1 - textSize * 0.5, textSize, "volume:")
				renderText(x + xSectionWidth + xSectionWidth * 0.6, lineY + lineHeight - lineHeight * 0.25 * 2 - textSize * 0.5, textSize, "pitch:")
				renderText(x + xSectionWidth + xSectionWidth * 0.6, lineY + lineHeight - lineHeight * 0.25 * 3 - textSize * 0.5, textSize, "lowpassGain:")

				local modVolume = g_soundManager:getModifierFactor(sample, "volume")
				sample.debugMaxVolume = math.max(sample.debugMaxVolume or 1, sample.current.volume * modVolume, sample.current.volume)
				local barX = x + xSectionWidth + xSectionWidth * 0.7
				local barY = lineY + lineHeight - lineHeight * 0.25 * 1 - textSize * 0.5
				local barW = xSectionWidth
				local barH = textSize

				drawBar(barX, barY, barW, barH, sample.current.volume * modVolume / sample.debugMaxVolume, sample.current.volume / sample.debugMaxVolume, string.format("%.2f", sample.current.volume * modVolume), 0, 0.5, 0, 0.4)

				local startX = barX + barW + xSectionWidth * 0.1

				drawModifiers(startX, barY, 1 - startX - x - xSectionWidth * 0.1, barH, sample, "volume")

				local modPitch = g_soundManager:getModifierFactor(sample, "pitch")
				sample.debugMaxPitch = math.max(sample.debugMaxPitch or 1, sample.current.pitch * modPitch, sample.current.pitch)
				barH = textSize
				barW = xSectionWidth
				barY = lineY + lineHeight - lineHeight * 0.25 * 2 - textSize * 0.5
				barX = x + xSectionWidth + xSectionWidth * 0.7

				drawBar(barX, barY, barW, barH, sample.current.pitch * modPitch / sample.debugMaxPitch, sample.current.pitch / sample.debugMaxPitch, string.format("%.2f", sample.current.pitch * modPitch), 0.5, 0.5, 0, 0.4)

				startX = barX + barW + xSectionWidth * 0.1

				drawModifiers(startX, barY, 1 - startX - x, barH, sample, "pitch")

				local modLowPassGain = g_soundManager:getModifierFactor(sample, "lowpassGain")
				sample.debugMaxLowPass = math.max(sample.debugMaxLowPass or 1, sample.current.lowpassGain * modLowPassGain, sample.current.lowpassGain)
				barH = textSize
				barW = xSectionWidth
				barY = lineY + lineHeight - lineHeight * 0.25 * 3 - textSize * 0.5
				barX = x + xSectionWidth + xSectionWidth * 0.7

				drawBar(barX, barY, barW, barH, sample.current.lowpassGain * modLowPassGain / sample.debugMaxLowPass, sample.current.lowpassGain / sample.debugMaxLowPass, string.format("%.2f", sample.current.lowpassGain * modLowPassGain), 0, 0.5, 0.5, 0.4)

				startX = barX + barW + xSectionWidth * 0.1

				drawModifiers(startX, barY, 1 - startX - x, barH, sample, "lowpassGain")
			end

			i = i + 1
		end
	end

	setTextAlignment(RenderText.ALIGN_LEFT)
	VehicleDebug.drawMotorLoadGraph(vehicle, 0.2, 0.05, 0.25, 0.2)
	VehicleDebug.drawMotorRPMGraph(vehicle, 0.55, 0.05, 0.25, 0.2)
	VehicleDebug.drawMotorAccelerationGraph(vehicle, 0.2, 0.28, 0.25, 0.1)
end

function VehicleDebug.drawAnimationDebug(vehicle)
	if vehicle.playAnimation ~= nil then
		local x = 0.15
		local y = 0.1
		local width = 0.7
		local height = 0.8
		local textSize = 0.015
		local textSize2 = 0.01
		local pixelWidth = 1 / g_screenWidth
		local pixelHeight = 1 / g_screenHeight
		local timeLineOffset = 0.1 + pixelWidth
		local timeLineWidth = width - timeLineOffset - pixelWidth * 2
		local lineHeight = 0.05
		local lineHeightPart = lineHeight * 0.25
		local numAnims = 0
		local spec = vehicle.spec_animatedVehicle

		for _, animation in pairs(spec.animations) do
			if #animation.parts > 0 then
				numAnims = numAnims + 1
			end
		end

		local selected = VehicleDebug.selectedAnimation % numAnims + 1

		setTextColor(1, 1, 1, 1)

		local i = 1
		local lineY = y + height

		for name, animation in pairs(spec.animations) do
			if #animation.parts > 0 then
				lineY = lineY - lineHeight

				drawOutlineRect(x, lineY, width, lineHeight + pixelHeight, pixelWidth, pixelHeight, 0, 0, 0, 1)
				drawFilledRect(x, lineY, width, lineHeight, 0, 0, 0, 0.4)
				drawFilledRect(x + timeLineOffset - pixelWidth, lineY, pixelWidth, lineHeight, 0, 0, 0, 1)

				local widthPerMs = timeLineWidth / animation.duration
				local divider = 1000

				if animation.duration < 2000 then
					divider = 500
				end

				if animation.duration < 1000 then
					divider = 100
				end

				for j = 1, math.floor(animation.duration / divider) do
					if j * divider ~= animation.duration then
						setTextAlignment(RenderText.ALIGN_CENTER)
						renderText(x + timeLineOffset + widthPerMs * j * divider, lineY + lineHeight * 0.5 - textSize2 * 0.5, textSize2, string.format("%.1f", j * divider / 1000))
						drawFilledRect(x + timeLineOffset + widthPerMs * j * divider, lineY, pixelWidth, lineHeight * 0.3, 0, 0, 0, 1)
					end
				end

				setTextBold(selected == i)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(x + timeLineOffset * 0.5, lineY + lineHeight * 0.5 - textSize * 0.5, textSize, name)
				setTextBold(false)

				local startLineY = lineY

				if selected == i then
					if animation.lineHeightByPart == nil then
						animation.lineHeightByPart = {}
					else
						for k, _ in pairs(animation.lineHeightByPart) do
							animation.lineHeightByPart[k] = nil
						end
					end

					for i = 1, #animation.parts do
						local part = animation.parts[i]
						local animValue = part.animationValues[1]
						local index = animValue.node or animValue.componentJoint

						if index ~= nil and animation.lineHeightByPart[index] == nil then
							lineY = lineY - lineHeightPart

							drawOutlineRect(x, lineY, width, lineHeightPart + pixelHeight, pixelWidth, pixelHeight, 0, 0, 0, 1)
							drawFilledRect(x, lineY, width, lineHeightPart, 0, 0, 0, 0.2)
							drawFilledRect(x + timeLineOffset - pixelWidth, lineY, pixelWidth, lineHeightPart, 0, 0, 0, 1)

							local partName = "unknown"

							if animValue.node ~= nil then
								partName = string.format("node '%s'", getName(animValue.node))
							elseif animValue.componentJoint ~= nil then
								partName = string.format("compJoint '%d'", animValue.componentJoint.index)
							end

							setTextAlignment(RenderText.ALIGN_CENTER)
							renderText(x + timeLineOffset * 0.5, lineY + lineHeightPart * 0.5 - textSize2 * 0.5 + pixelHeight * 2, textSize2, partName)

							animation.lineHeightByPart[index] = lineY
						end
					end

					if #animation.samples > 0 then
						local headTextSize = textSize2 * 1.5
						local headLineHeight = lineHeightPart * 1.5
						lineY = lineY - headLineHeight

						drawOutlineRect(x, lineY, width, headLineHeight + pixelHeight, pixelWidth, pixelHeight, 0, 0, 0, 1)
						drawFilledRect(x, lineY, width, headLineHeight, 0, 0, 0, 0.2)
						setTextAlignment(RenderText.ALIGN_CENTER)
						renderText(x + width / 2, lineY + headLineHeight * 0.5 - headTextSize * 0.5 + pixelHeight * 2, headTextSize, "Sounds:")
					end

					local sampleTimesPerSample = {}

					for j = 1, #animation.samples do
						local sample = animation.samples[j]

						if sampleTimesPerSample[sample.filename] == nil then
							sampleTimesPerSample[sample.filename] = {}
						end

						table.insert(sampleTimesPerSample[sample.filename], {
							sample = sample,
							startTime = sample.startTime,
							endTime = sample.endTime,
							loops = sample.loops,
							direction = sample.direction
						})
					end

					for filename, times in pairs(sampleTimesPerSample) do
						lineY = lineY - lineHeightPart

						drawOutlineRect(x, lineY, width, lineHeightPart + pixelHeight, pixelWidth, pixelHeight, 0, 0, 0, 1)
						drawFilledRect(x, lineY, width, lineHeightPart, 0, 0, 0, 0.2)
						drawFilledRect(x + timeLineOffset - pixelWidth, lineY, pixelWidth, lineHeightPart, 0, 0, 0, 1)

						local sampleName = "unknown"

						for i = 1, #times do
							local timeData = times[i]
							sampleName = timeData.sample.templateName or timeData.sample.sampleName
							local r = 0
							local g = 0
							local b = 0
							local a = 0.9

							if g_soundManager:getIsSamplePlaying(timeData.sample) then
								g = 1

								if timeData.loops == 1 then
									r = 1
								end
							end

							local minX = x + timeLineOffset
							local maxX = x + width
							local rx = 0
							local ry = lineY + lineHeightPart * 0.1 + pixelHeight
							local rwidth = 0
							local rheight = lineHeightPart * 0.8 - pixelHeight

							if timeData.startTime ~= nil and timeData.endTime == nil then
								rx = math.max(minX, x + timeLineOffset + widthPerMs * timeData.startTime - widthPerMs * 25)
								rwidth = widthPerMs * 50
								rwidth = rwidth + math.min(maxX - (rx + rwidth), 0)
							elseif timeData.startTime ~= nil and timeData.endTime ~= nil and timeData.loops == 0 then
								rx = x + timeLineOffset + widthPerMs * timeData.startTime + widthPerMs * 5
								rwidth = widthPerMs * (timeData.endTime - timeData.startTime) - widthPerMs * 10
							elseif timeData.startTime ~= nil and timeData.endTime ~= nil and timeData.loops == 1 then
								rx = math.max(minX, x + timeLineOffset + widthPerMs * timeData.startTime - widthPerMs * 25)
								rwidth = widthPerMs * 50
								rwidth = rwidth + math.min(maxX - (rx + rwidth), 0)

								drawFilledRect(rx, ry, rwidth, rheight, r, g, b, a)

								rx = math.max(minX, x + timeLineOffset + widthPerMs * timeData.endTime - widthPerMs * 25)
								rwidth = widthPerMs * 50
								rwidth = rwidth + math.min(maxX - (rx + rwidth), 0)
							end

							drawFilledRect(rx, ry, rwidth, rheight, r, g, b, a)
						end

						setTextAlignment(RenderText.ALIGN_CENTER)
						renderText(x + timeLineOffset * 0.5, lineY + lineHeightPart * 0.5 - textSize2 * 0.5 + pixelHeight * 2, textSize2, sampleName)
					end

					for i = 1, #animation.parts do
						local part = animation.parts[i]
						local animValue = part.animationValues[1]
						local index = animValue.node or animValue.componentJoint

						if index ~= nil then
							drawFilledRect(x + timeLineOffset + widthPerMs * part.startTime, animation.lineHeightByPart[index] + lineHeightPart * 0.1 + pixelHeight, widthPerMs * part.duration, lineHeightPart * 0.8 - pixelHeight, 0, 0, 0, 0.9)
						end
					end
				end

				drawFilledRect(x + timeLineOffset + widthPerMs * animation.currentTime, lineY, pixelWidth, startLineY - lineY + lineHeight * 0.7, 0, 1, 0, 1)
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(x + timeLineOffset + widthPerMs * animation.currentTime, lineY + startLineY - lineY + lineHeight * 0.9 - textSize2 * 0.5, textSize2, string.format("%.2f", animation.currentTime / 1000))

				i = i + 1
			end
		end

		setTextAlignment(RenderText.ALIGN_LEFT)
	end
end

function VehicleDebug.drawReverbDebugRendering(vehicle)
	local firstRun = false

	if VehicleDebug.reverbSettings == nil then
		local settings = {
			{
				value = 0,
				name = "GAIN (dB)",
				valueBackup = 0.5,
				range = {
					-60,
					12
				}
			},
			{
				value = 1,
				name = "GAIN_HF (dB)",
				range = {
					-60,
					12
				}
			},
			{
				value = 1,
				name = "GAIN_LF (dB)",
				range = {
					-60,
					12
				}
			},
			{
				value = 1,
				name = "DECAY_TIME",
				range = {
					0,
					5
				}
			},
			{
				value = 1,
				name = "DECAY_HF_RATIO",
				range = {
					0,
					5
				}
			},
			{
				value = 0.1,
				name = "REFLECTIONS_GAIN (dB)",
				range = {
					-60,
					12
				}
			},
			{
				value = 0.005,
				name = "REFLECTIONS_DELAY",
				range = {
					0,
					0.5
				}
			},
			{
				value = 1,
				name = "LATE_REVERB_GAIN (dB)",
				range = {
					-60,
					12
				}
			},
			{
				value = 0.01,
				name = "LATE_REVERB_DELAY",
				range = {
					0,
					0.5
				}
			},
			{
				value = 5000,
				name = "HF_REFERENCE",
				range = {
					0,
					10000
				}
			},
			{
				value = 250,
				name = "LF_REFERENCE",
				range = {
					0,
					1000
				}
			}
		}
		VehicleDebug.reverbSettings = settings
		firstRun = true
		local xmlFile = loadXMLFile("reverbSettings", getUserProfileAppPath() .. "reverbSettings.xml")

		if xmlFile ~= 0 then
			local i = 0

			while true do
				local key = string.format("settings.setting(%d)", i)

				if not hasXMLProperty(xmlFile, key) then
					break
				end

				local id = getXMLInt(xmlFile, key .. "#id")
				local value = getXMLFloat(xmlFile, key .. "#value")

				if settings[id].valueBackup ~= nil then
					settings[id].valueBackup = value
				else
					settings[id].value = value
				end

				i = i + 1
			end

			delete(xmlFile)
		else
			xmlFile = createXMLFile("reverbSettings", getUserProfileAppPath() .. "reverbSettings.xml", "settings")

			if xmlFile ~= 0 then
				for i, setting in ipairs(settings) do
					local settingKey = string.format("settings.setting(%d)", i - 1)

					setXMLInt(xmlFile, settingKey .. "#id", i)

					if setting.valueBackup ~= nil then
						setXMLFloat(xmlFile, settingKey .. "#value", setting.valueBackup)
					else
						setXMLFloat(xmlFile, settingKey .. "#value", setting.value)
					end
				end

				saveXMLFile(xmlFile)
				delete(xmlFile)
			end
		end
	end

	for i = 1, #VehicleDebug.reverbSettings do
		local setting = VehicleDebug.reverbSettings[i]
		local x = 0.12
		local lineHeight = 0.022
		local y = 0.58 - (i - 1) * lineHeight

		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(x, y, lineHeight * 0.8, setting.name .. ":")
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(x + 0.01, y, lineHeight * 0.8, string.format("%.4f", setting.valueBackup or setting.value))
		setTextAlignment(RenderText.ALIGN_CENTER)

		local width = 0.02

		drawFilledRect(x + 0.1, y, width, lineHeight * 0.8, 0.1, 0.1, 0.1, 1)
		renderText(x + 0.1 + width * 0.5, y + 0.0025, lineHeight * 0.8, "--")
		drawFilledRect(x + 0.125, y, width, lineHeight * 0.8, 0.1, 0.1, 0.1, 1)
		renderText(x + 0.125 + width * 0.5, y + 0.0025, lineHeight * 0.8, "-")
		drawFilledRect(x + 0.16, y, width, lineHeight * 0.8, 0.1, 0.1, 0.1, 1)
		renderText(x + 0.16 + width * 0.5, y + 0.0025, lineHeight * 0.8, "+")
		drawFilledRect(x + 0.185, y, width, lineHeight * 0.8, 0.1, 0.1, 0.1, 1)
		renderText(x + 0.185 + width * 0.5, y + 0.0025, lineHeight * 0.8, "++")

		if firstRun then
			setting.buttons = {}

			table.insert(setting.buttons, {
				-1.8,
				x + 0.1,
				y,
				0.03,
				lineHeight * 0.8
			})
			table.insert(setting.buttons, {
				-0.25,
				x + 0.125,
				y,
				0.03,
				lineHeight * 0.8
			})
			table.insert(setting.buttons, {
				0.25,
				x + 0.16,
				y,
				0.03,
				lineHeight * 0.8
			})
			table.insert(setting.buttons, {
				1.8,
				x + 0.185,
				y,
				0.03,
				lineHeight * 0.8
			})
		end
	end

	setTextAlignment(RenderText.ALIGN_CENTER)

	local width = 0.08
	local turnedOn = VehicleDebug.reverbSettings[1].valueBackup == nil

	drawFilledRect(0.1, 0.6, width, 0.022, turnedOn and 0 or 0.3, turnedOn and 0.3 or 0, 0, 1)
	renderText(0.1 + width * 0.5, 0.6024999999999999, 0.018, "TurnOff/On")

	if firstRun then
		VehicleDebug.reverbTurnOnButton = {
			0.1,
			0.6,
			width,
			0.022
		}
	end
end

function VehicleDebug.updateReverbDebugRendering(vehicle, dt)
	local button, buttonState = g_inputBinding:getMouseButtonState()

	if buttonState and button == Input.MOUSE_BUTTON_LEFT then
		local hasChanged = false

		for i = 1, #VehicleDebug.reverbSettings do
			local setting = VehicleDebug.reverbSettings[i]

			if setting.buttons ~= nil then
				for j = 1, #setting.buttons do
					local b = setting.buttons[j]

					if b[2] < g_lastMousePosX and g_lastMousePosX < b[2] + b[4] and b[3] < g_lastMousePosY and g_lastMousePosY < b[3] + b[5] then
						local change = dt * (setting.range[2] - setting.range[1]) * 0.0001 * b[1]

						if setting.valueBackup ~= nil then
							setting.valueBackup = MathUtil.clamp(setting.valueBackup + change, setting.range[1], setting.range[2])
						else
							setting.value = MathUtil.clamp(setting.value + change, setting.range[1], setting.range[2])
						end

						VehicleDebug.saveReverbSettingsTime = g_time + 1000
						hasChanged = true
					end
				end
			end
		end

		if VehicleDebug.reverbTurnOnButton ~= nil then
			local b = VehicleDebug.reverbTurnOnButton

			if b[1] < g_lastMousePosX and g_lastMousePosX < b[1] + b[3] and b[2] < g_lastMousePosY and g_lastMousePosY < b[2] + b[4] and not VehicleDebug.reverbSettings[1].turnHasEvent then
				VehicleDebug.reverbSettings[1].turnHasEvent = true

				if VehicleDebug.reverbSettings[1].value > -60 then
					VehicleDebug.reverbSettings[1].valueBackup = VehicleDebug.reverbSettings[1].value
					VehicleDebug.reverbSettings[1].value = -60
				else
					VehicleDebug.reverbSettings[1].value = VehicleDebug.reverbSettings[1].valueBackup
					VehicleDebug.reverbSettings[1].valueBackup = nil
				end

				hasChanged = true
			end
		end

		if hasChanged then
			local gainValue = math.pow(10, VehicleDebug.reverbSettings[1].value / 20)
			local gainLFValue = math.pow(10, VehicleDebug.reverbSettings[2].value / 20)
			local gainHFValue = math.pow(10, VehicleDebug.reverbSettings[3].value / 20)
			local reflectionsGainValue = math.pow(10, VehicleDebug.reverbSettings[6].value / 20)
			local lateReverbGainValue = math.pow(10, VehicleDebug.reverbSettings[8].value / 20)

			setReverbEffectCustom(0, gainValue, gainLFValue, gainHFValue, VehicleDebug.reverbSettings[4].value, VehicleDebug.reverbSettings[5].value, reflectionsGainValue, VehicleDebug.reverbSettings[7].value, lateReverbGainValue, VehicleDebug.reverbSettings[9].value, VehicleDebug.reverbSettings[10].value, VehicleDebug.reverbSettings[11].value)
		end
	elseif VehicleDebug.reverbSettings ~= nil then
		VehicleDebug.reverbSettings[1].turnHasEvent = false
	end

	if VehicleDebug.saveReverbSettingsTime ~= nil and VehicleDebug.saveReverbSettingsTime < g_time then
		local xmlFile = createXMLFile("reverbSettings", getUserProfileAppPath() .. "reverbSettings.xml", "settings")

		if xmlFile ~= 0 then
			for i, setting in ipairs(VehicleDebug.reverbSettings) do
				local settingKey = string.format("settings.setting(%d)", i - 1)

				setXMLInt(xmlFile, settingKey .. "#id", i)

				if setting.valueBackup ~= nil then
					setXMLFloat(xmlFile, settingKey .. "#value", setting.valueBackup)
				else
					setXMLFloat(xmlFile, settingKey .. "#value", setting.value)
				end
			end

			saveXMLFile(xmlFile)
			delete(xmlFile)
		end

		VehicleDebug.saveReverbSettingsTime = nil
	end

	if not g_gui:getIsGuiVisible() then
		local show = Utils.getNoNil(Input.isKeyPressed(Input.KEY_lctrl), false)

		g_inputBinding:setShowMouseCursor(show, false)
	end
end

function VehicleDebug.updateTuningDebugRendering(vehicle, dt)
	if vehicle.getWheels ~= nil and g_gui.currentGuiName == "ShopConfigScreen" then
		local wheels = vehicle:getWheels()

		for i = 1, #wheels do
			local wheel = wheels[i]
			local x, y, z = getWorldTranslation(wheels[i].driveNodeDirectionNode)
			local offset = nil

			if y < 50 then
				offset = y + 100
			else
				offset = y - getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
			end

			Utils.renderTextAtWorldPosition(x, y, z, string.format("%.3f", offset), getCorrectTextSize(0.012), 0)

			local wx, _, _ = localToLocal(wheel.driveNode, wheel.node, 0, 0, 0)
			local xOffset = wheel.wheelShapeWidth * 0.5 * (wheel.isLeft and 1 or -1) + wheel.widthOffset
			x, _, z = localToWorld(wheel.driveNode, xOffset, 0, 0)

			Utils.renderTextAtWorldPosition(x, y - wheel.radius, z, string.format("%.3f", (math.abs(wx) + math.abs(xOffset)) * 2), getCorrectTextSize(0.012), 0)
		end
	end
end

function VehicleDebug:toggleReverb(actionName, inputValue, callbackState, isAnalog)
	if VehicleDebug.reverbSettings[1].value > 0 then
		VehicleDebug.reverbSettings[1].valueBackup = VehicleDebug.reverbSettings[1].value
		VehicleDebug.reverbSettings[1].value = 0
	else
		VehicleDebug.reverbSettings[1].value = VehicleDebug.reverbSettings[1].valueBackup
		VehicleDebug.reverbSettings[1].valueBackup = nil
	end

	setReverbEffectCustom(0, VehicleDebug.reverbSettings[1].value, VehicleDebug.reverbSettings[2].value, VehicleDebug.reverbSettings[3].value, VehicleDebug.reverbSettings[4].value, VehicleDebug.reverbSettings[5].value, VehicleDebug.reverbSettings[6].value, VehicleDebug.reverbSettings[7].value, VehicleDebug.reverbSettings[8].value, VehicleDebug.reverbSettings[9].value, VehicleDebug.reverbSettings[10].value, VehicleDebug.reverbSettings[11].value)
end

function VehicleDebug.consoleCommandAnalyze(unusedSelf)
	if g_currentMission ~= nil and g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.isServer then
		local self = g_currentMission.controlledVehicle:getSelectedVehicle()

		if self == nil then
			self = g_currentMission.controlledVehicle
		end

		print("Analyzing vehicle '" .. self.configFileName .. "'. Make sure vehicle is standing on a flat plane parallel to xz-plane")

		local groundRaycastResult = {
			raycastCallback = function (self, transformId, x, y, z, distance)
				if self.vehicle.vehicleNodes[transformId] ~= nil then
					return true
				end

				if self.vehicle.aiTrafficCollisionTrigger == transformId then
					return true
				end

				if transformId ~= g_currentMission.terrainRootNode then
					print("Warning: Vehicle is not standing on ground! " .. getName(transformId))
				end

				self.groundDistance = distance

				return false
			end
		}

		if self.spec_attacherJoints ~= nil then
			for i, attacherJoint in ipairs(self.spec_attacherJoints.attacherJoints) do
				local trx, try, trz = getRotation(attacherJoint.jointTransform)

				setRotation(attacherJoint.jointTransform, unpack(attacherJoint.jointOrigRot))

				if attacherJoint.rotationNode ~= nil or attacherJoint.rotationNode2 ~= nil then
					local rx, ry, rz = nil

					if attacherJoint.rotationNode ~= nil then
						rx, ry, rz = getRotation(attacherJoint.rotationNode)
					end

					local rx2, ry2, rz2 = nil

					if attacherJoint.rotationNode2 ~= nil then
						rx2, ry2, rz2 = getRotation(attacherJoint.rotationNode2)
					end

					if attacherJoint.rotationNode ~= nil then
						setRotation(attacherJoint.rotationNode, unpack(attacherJoint.upperRotation))
					end

					if attacherJoint.rotationNode2 ~= nil then
						setRotation(attacherJoint.rotationNode2, unpack(attacherJoint.upperRotation2))
					end

					local x, y, z = getWorldTranslation(attacherJoint.jointTransform)
					groundRaycastResult.groundDistance = 0
					groundRaycastResult.vehicle = self

					raycastAll(x, y, z, 0, -1, 0, "raycastCallback", 4, groundRaycastResult)

					if math.abs(groundRaycastResult.groundDistance - attacherJoint.upperDistanceToGround) > 0.01 then
						print(" Issue found: Attacher joint " .. i .. " has invalid upperDistanceToGround. True value is: " .. groundRaycastResult.groundDistance .. ". Value in XML: " .. attacherJoint.upperDistanceToGround)
					end

					if attacherJoint.rotationNode ~= nil and attacherJoint.rotationNode2 ~= nil then
						local _, dy, _ = localDirectionToWorld(attacherJoint.jointTransform, 0, 1, 0)
						local angle = math.deg(math.acos(MathUtil.clamp(dy, -1, 1)))
						local _, dxy, _ = localDirectionToWorld(attacherJoint.jointTransform, 1, 0, 0)

						if dxy < 0 then
							angle = -angle
						end

						if math.abs(angle - math.deg(attacherJoint.upperRotationOffset)) > 1 then
							print(" Issue found: Attacher joint " .. i .. " has invalid upperRotationOffset. True value is: " .. angle .. ". Value in XML: " .. math.deg(attacherJoint.upperRotationOffset))
						end
					end

					if attacherJoint.rotationNode ~= nil then
						setRotation(attacherJoint.rotationNode, unpack(attacherJoint.lowerRotation))
					end

					if attacherJoint.rotationNode2 ~= nil then
						setRotation(attacherJoint.rotationNode2, unpack(attacherJoint.lowerRotation2))
					end

					local x, y, z = getWorldTranslation(attacherJoint.jointTransform)
					groundRaycastResult.groundDistance = 0

					raycastAll(x, y, z, 0, -1, 0, "raycastCallback", 4, groundRaycastResult)

					if math.abs(groundRaycastResult.groundDistance - attacherJoint.lowerDistanceToGround) > 0.01 then
						print(" Issue found: Attacher joint " .. i .. " has invalid lowerDistanceToGround. True value: " .. groundRaycastResult.groundDistance .. ". Value in XML: " .. attacherJoint.lowerDistanceToGround)
					end

					if attacherJoint.rotationNode ~= nil and attacherJoint.rotationNode2 ~= nil then
						local _, dy, _ = localDirectionToWorld(attacherJoint.jointTransform, 0, 1, 0)
						local angle = math.deg(math.acos(MathUtil.clamp(dy, -1, 1)))
						local _, dxy, _ = localDirectionToWorld(attacherJoint.jointTransform, 1, 0, 0)

						if dxy < 0 then
							angle = -angle
						end

						if math.abs(angle - math.deg(attacherJoint.lowerRotationOffset)) > 1 then
							print(" Issue found: Attacher joint " .. i .. " has invalid lowerRotationOffset. True value is: " .. angle .. ". Value in XML: " .. math.deg(attacherJoint.lowerRotationOffset))
						end
					end

					if attacherJoint.rotationNode ~= nil then
						setRotation(attacherJoint.rotationNode, rx, ry, rz)
					end

					if attacherJoint.rotationNode2 ~= nil then
						setRotation(attacherJoint.rotationNode2, rx2, ry2, rz2)
					end
				end

				setRotation(attacherJoint.jointTransform, trx, try, trz)

				if attacherJoint.transNode ~= nil then
					local sx, sy, sz = getTranslation(attacherJoint.transNode)
					local _, y, _ = localToLocal(self.rootNode, getParent(attacherJoint.transNode), 0, attacherJoint.transNodeMaxY, 0)

					setTranslation(attacherJoint.transNode, sx, y, sz)

					groundRaycastResult.groundDistance = 0
					groundRaycastResult.vehicle = self
					local wx, wy, wz = getWorldTranslation(attacherJoint.transNode)

					raycastAll(wx, wy, wz, 0, -1, 0, "raycastCallback", 4, groundRaycastResult)

					if math.abs(groundRaycastResult.groundDistance - attacherJoint.upperDistanceToGround) > 0.02 then
						print(" Issue found: Attacher joint " .. i .. " has invalid upperDistanceToGround. True value is: " .. groundRaycastResult.groundDistance .. ". Value in XML: " .. attacherJoint.upperDistanceToGround)
					end

					_, y, _ = localToLocal(self.rootNode, getParent(attacherJoint.transNode), 0, attacherJoint.transNodeMinY, 0)

					setTranslation(attacherJoint.transNode, sx, y, sz)

					groundRaycastResult.groundDistance = 0
					groundRaycastResult.vehicle = self
					local wx, wy, wz = getWorldTranslation(attacherJoint.transNode)

					raycastAll(wx, wy, wz, 0, -1, 0, "raycastCallback", 4, groundRaycastResult)

					if math.abs(groundRaycastResult.groundDistance - attacherJoint.lowerDistanceToGround) > 0.02 then
						print(" Issue found: Attacher joint " .. i .. " has invalid lowerDistanceToGround. True value is: " .. groundRaycastResult.groundDistance .. ". Value in XML: " .. attacherJoint.lowerDistanceToGround)
					end

					setTranslation(attacherJoint.transNode, sx, sy, sz)
				end
			end
		end

		if self.spec_wheels ~= nil then
			for i, wheel in ipairs(self.spec_wheels.wheels) do
				if wheel.wheelShapeCreated then
					local _, comY, _ = getCenterOfMass(wheel.node)
					local forcePointY = wheel.positionY + wheel.deltaY - wheel.radius * wheel.forcePointRatio

					if comY < forcePointY then
						print(string.format(" Issue found: Wheel %d has force point higher than center of mass. %.2f > %.2f. This can lead to undesired driving behavior (inward-leaning).", i, forcePointY, comY))
					end

					local tireLoad = getWheelShapeContactForce(wheel.node, wheel.wheelShape)

					if tireLoad ~= nil then
						local nx, ny, nz = getWheelShapeContactNormal(wheel.node, wheel.wheelShape)
						local dx, dy, dz = localDirectionToWorld(wheel.node, 0, -1, 0)
						tireLoad = -tireLoad * MathUtil.dotProduct(dx, dy, dz, nx, ny, nz)
						local gravity = 9.81
						tireLoad = tireLoad + math.max(ny * gravity, 0) * wheel.mass
						tireLoad = tireLoad / gravity

						if math.abs(tireLoad - wheel.restLoad) > 0.2 then
							print(string.format(" Issue found: Wheel %d has wrong restLoad. %.2f vs. %.2f in XML. Verify that this leads to the desired behavior.", i, tireLoad, wheel.restLoad))
						end
					end
				end
			end
		end

		return "Analyzed vehicle"
	end

	return "Failed to analyze vehicle. Invalid controlled vehicle"
end

function VehicleDebug:moveUpperRotation(actionName, inputValue, callbackState, isAnalog)
	if VehicleDebug.currentAttacherJointVehicle ~= nil and inputValue ~= 0 then
		local vehicle = VehicleDebug.currentAttacherJointVehicle

		if vehicle.getAttacherVehicle ~= nil then
			local attacherVehicle = vehicle:getAttacherVehicle()

			if attacherVehicle ~= nil then
				local implement = attacherVehicle:getImplementByObject(vehicle)

				if implement ~= nil then
					local jointDescIndex = implement.jointDescIndex
					local jointDesc = attacherVehicle.spec_attacherJoints.attacherJoints[jointDescIndex]

					if jointDesc.rotationNode ~= nil then
						jointDesc.upperRotation[1] = jointDesc.upperRotation[1] + math.rad(inputValue * 0.002 * 16)
						jointDesc.moveAlpha = jointDesc.moveAlpha - 0.001

						print("upperRotation: " .. math.deg(jointDesc.upperRotation[1]))
					end
				end
			end
		end
	end
end

function VehicleDebug:moveLowerRotation(actionName, inputValue, callbackState, isAnalog)
	if VehicleDebug.currentAttacherJointVehicle ~= nil and inputValue ~= 0 then
		local vehicle = VehicleDebug.currentAttacherJointVehicle

		if vehicle.getAttacherVehicle ~= nil then
			local attacherVehicle = vehicle:getAttacherVehicle()

			if attacherVehicle ~= nil then
				local implement = attacherVehicle:getImplementByObject(vehicle)

				if implement ~= nil then
					local jointDescIndex = implement.jointDescIndex
					local jointDesc = attacherVehicle.spec_attacherJoints.attacherJoints[jointDescIndex]

					if jointDesc.rotationNode ~= nil then
						jointDesc.lowerRotation[1] = jointDesc.lowerRotation[1] + math.rad(inputValue * 0.002 * 16)
						jointDesc.moveAlpha = jointDesc.moveAlpha - 0.001

						print("lowerRotation: " .. math.deg(jointDesc.lowerRotation[1]))
					end
				end
			end
		end
	end
end

function VehicleDebug.drawDebugAttacherJoints(vehicle)
	VehicleDebug.currentAttacherJointVehicle = vehicle
end

addConsoleCommand("gsVehicleAnalyze", "Analyze vehicle", "VehicleDebug.consoleCommandAnalyze", nil)
addConsoleCommand("gsVehicleDebug", "Toggles the vehicle debug values rendering", "VehicleDebug.consoleCommandVehicleDebug", nil)
addConsoleCommand("gsVehicleDebugReverb", "Toggles the reverb debug rendering", "VehicleDebug.consoleCommandVehicleDebugReverb", nil)

if StartParams.getIsSet("vehicleDebugMode") then
	VehicleDebug.consoleCommandVehicleDebug(nil, StartParams.getValue("vehicleDebugMode"))
end
