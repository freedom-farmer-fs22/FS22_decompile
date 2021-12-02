StonePicker = {
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("stonePicker", true)

		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("StonePicker")
		schema:register(XMLValueType.INT, "vehicle.stonePicker#fillUnitIndex", "Index of fillunit to be used for picked stones")
		schema:register(XMLValueType.INT, "vehicle.stonePicker#loadInfoIndex", "Index of load info to use")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.stonePicker.directionNode#node", "Direction node")
		schema:register(XMLValueType.BOOL, "vehicle.stonePicker.onlyActiveWhenLowered#value", "Only active when lowered", true)
		schema:register(XMLValueType.BOOL, "vehicle.stonePicker.needsActivation#value", "Needs activation", true)
		EffectManager.registerEffectXMLPaths(schema, "vehicle.stonePicker.effects")
		EffectManager.registerEffectXMLPaths(schema, "vehicle.stonePicker.soilEffects")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.stonePicker.sounds", "work")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.stonePicker.sounds", "stone")
		schema:setXMLSpecializationType()
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations)
	end
}

function StonePicker.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processStonePickerArea", StonePicker.processStonePickerArea)
	SpecializationUtil.registerFunction(vehicleType, "setStonePickerEffectsState", StonePicker.setStonePickerEffectsState)
end

function StonePicker.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", StonePicker.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoGroundManipulation", StonePicker.getDoGroundManipulation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", StonePicker.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", StonePicker.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", StonePicker.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", StonePicker.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", StonePicker.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", StonePicker.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", StonePicker.getCanToggleTurnedOn)
end

function StonePicker.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", StonePicker)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", StonePicker)
end

function StonePicker:onLoad(savegame)
	if self:getGroundReferenceNodeFromIndex(1) == nil then
		print("Warning: No ground reference nodes in  " .. self.configFileName)
	end

	local spec = self.spec_stonePicker

	if self.isClient then
		spec.samples = {
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.stonePicker.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			stone = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.stonePicker.sounds", "stone", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.isWorkSamplePlaying = false
		spec.isStoneSamplePlaying = false
		spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.stonePicker.effects", self.components, self, self.i3dMappings)
		spec.soilEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.stonePicker.soilEffects", self.components, self, self.i3dMappings)
	end

	spec.fillUnitIndex = self.xmlFile:getValue("vehicle.stonePicker#fillUnitIndex", 1)
	spec.loadInfoIndex = self.xmlFile:getValue("vehicle.stonePicker#loadInfoIndex", 1)
	spec.directionNode = self.xmlFile:getValue("vehicle.stonePicker.directionNode#node", self.components[1].node, self.components, self.i3dMappings)
	spec.onlyActiveWhenLowered = self.xmlFile:getValue("vehicle.stonePicker.onlyActiveWhenLowered#value", true)
	spec.needsActivation = self.xmlFile:getValue("vehicle.stonePicker.needsActivation#value", true)
	spec.startActivationTimeout = 2000
	spec.startActivationTime = 0
	spec.hasGroundContact = false
	spec.isWorking = false
	spec.isEffectActive = false
	spec.effectGrowthState = 1
	spec.isSoilEffectActive = false
	spec.texts = {
		warningToolIsFull = g_i18n:getText("warning_toolIsFull")
	}
	spec.workAreaParameters = {
		angle = 0,
		pickedLiters = 0,
		lastChangedArea = 0,
		lastChangedAreaTime = -math.huge,
		lastGrowthState = 1,
		lastStatsArea = 0,
		lastTotalArea = 0
	}

	if self.isServer then
		local firstSowableValue, lastSowableValue = g_currentMission.fieldGroundSystem:getSowableRange()

		self:addAITerrainDetailRequiredRange(firstSowableValue, lastSowableValue)
	end

	spec.dirtyFlag = self:getNextDirtyFlag()
end

function StonePicker:onDelete()
	local spec = self.spec_stonePicker

	g_soundManager:deleteSamples(spec.samples)
	g_effectManager:deleteEffects(spec.effects)
	g_effectManager:deleteEffects(spec.soilEffects)
end

function StonePicker:onReadStream(streamId, connection)
	local state = streamReadBool(streamId)
	local growthState = streamReadUIntN(streamId, 2)
	local stateSoil = streamReadBool(streamId)

	self:setStonePickerEffectsState(state, growthState, stateSoil)
end

function StonePicker:onWriteStream(streamId, connection)
	local spec = self.spec_stonePicker

	streamWriteBool(streamId, spec.isEffectActive)
	streamWriteUIntN(streamId, spec.effectGrowthState, 2)
	streamWriteBool(streamId, spec.isSoilEffectActive)
end

function StonePicker:onReadUpdateStream(streamId, timestamp, connection)
	if connection.isServer and streamReadBool(streamId) then
		local state = streamReadBool(streamId)
		local growthState = streamReadUIntN(streamId, 2)
		local stateSoil = streamReadBool(streamId)

		self:setStonePickerEffectsState(state, growthState, stateSoil)
	end
end

function StonePicker:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer then
		local spec = self.spec_stonePicker

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteBool(streamId, spec.isEffectActive)
			streamWriteUIntN(streamId, spec.effectGrowthState, 2)
			streamWriteBool(streamId, spec.isSoilEffectActive)
		end
	end
end

function StonePicker:processStonePickerArea(workArea, dt)
	local spec = self.spec_stonePicker

	if not spec.workAreaParameters.isActive then
		return 0, 0
	end

	local xs, _, zs = getWorldTranslation(workArea.start)
	local xw, _, zw = getWorldTranslation(workArea.width)
	local xh, _, zh = getWorldTranslation(workArea.height)
	local params = spec.workAreaParameters
	local stoneFactor, touchedArea, totalArea = FSDensityMapUtil.updateStonePickerArea(xs, zs, xw, zw, xh, zh, params.angle)
	local litersPerSqm = g_currentMission.stoneSystem:getLitersPerSqm()
	local sqm = g_currentMission:getFruitPixelsToSqm() * touchedArea
	local liters = sqm * litersPerSqm * stoneFactor
	params.pickedLiters = params.pickedLiters + liters
	params.lastChangedArea = params.lastChangedArea + touchedArea
	params.lastStatsArea = params.lastStatsArea + touchedArea
	params.lastTotalArea = params.lastTotalArea + totalArea

	if touchedArea > 0 then
		params.lastChangedAreaTime = g_time
		params.lastGrowthState = MathUtil.clamp(math.floor(stoneFactor + 0.49), 1, 3)
	end

	FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)

	spec.isWorking = self:getLastSpeed() > 0.5

	return touchedArea, totalArea
end

function StonePicker:setStonePickerEffectsState(state, growthState, stateSoil)
	local spec = self.spec_stonePicker

	if state ~= spec.isEffectActive or growthState ~= spec.effectGrowthState or stateSoil ~= spec.isSoilEffectActive then
		spec.isEffectActive = state
		spec.effectGrowthState = growthState
		spec.isSoilEffectActive = stateSoil

		if self.isClient then
			if state then
				g_effectManager:setFillType(spec.effects, FillType.STONE, growthState)
				g_effectManager:startEffects(spec.effects)

				if not spec.isStoneSamplePlaying then
					g_soundManager:playSample(spec.samples.stone)

					spec.isStoneSamplePlaying = true
				end
			else
				g_effectManager:stopEffects(spec.effects)

				if spec.isStoneSamplePlaying then
					g_soundManager:stopSample(spec.samples.stone)

					spec.isStoneSamplePlaying = false
				end
			end

			if stateSoil then
				g_effectManager:startEffects(spec.soilEffects)

				if not spec.isWorkSamplePlaying then
					g_soundManager:playSample(spec.samples.work)

					spec.isWorkSamplePlaying = true
				end
			else
				g_effectManager:stopEffects(spec.soilEffects)

				if spec.isWorkSamplePlaying then
					g_soundManager:stopSample(spec.samples.work)

					spec.isWorkSamplePlaying = false
				end
			end
		end
	end
end

function StonePicker:doCheckSpeedLimit(superFunc)
	local spec = self.spec_stonePicker

	return superFunc(self) or self:getIsImplementChainLowered() and (not spec.needsActivation or self:getIsTurnedOn())
end

function StonePicker:getDoGroundManipulation(superFunc)
	local spec = self.spec_stonePicker

	if not spec.isWorking then
		return false
	end

	return superFunc(self)
end

function StonePicker:getDirtMultiplier(superFunc)
	local spec = self.spec_stonePicker
	local multiplier = superFunc(self)

	if self.movingDirection > 0 and spec.isWorking and (not spec.needsActivation or self:getIsTurnedOn()) then
		multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / spec.speedLimit
	end

	return multiplier
end

function StonePicker:getWearMultiplier(superFunc)
	local spec = self.spec_stonePicker
	local multiplier = superFunc(self)

	if self.movingDirection > 0 and spec.isWorking and (not spec.needsActivation or self:getIsTurnedOn()) then
		multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return multiplier
end

function StonePicker:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)

	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.STONEPICKER
	end

	return retValue
end

function StonePicker:getIsWorkAreaActive(superFunc, workArea)
	if workArea.type == WorkAreaType.STONEPICKER then
		local spec = self.spec_stonePicker

		if g_currentMission.time < spec.startActivationTime then
			return false
		end

		if spec.onlyActiveWhenLowered and self.getIsLowered ~= nil and not self:getIsLowered(false) then
			return false
		end

		local freeCapacity = self:getFillUnitFreeCapacity(spec.fillUnitIndex)

		if freeCapacity <= 0 and not self:getIsAIActive() then
			return false
		end
	end

	return superFunc(self, workArea)
end

function StonePicker:getCanBeTurnedOn(superFunc)
	local spec = self.spec_stonePicker
	local freeCapacity = self:getFillUnitFreeCapacity(spec.fillUnitIndex)

	if freeCapacity <= 0 and not self:getIsAIActive() then
		return false
	end

	return superFunc(self)
end

function StonePicker:getTurnedOnNotAllowedWarning(superFunc)
	local spec = self.spec_stonePicker
	local freeCapacity = self:getFillUnitFreeCapacity(spec.fillUnitIndex)

	if freeCapacity <= 0 and not self:getIsAIActive() then
		return spec.texts.warningToolIsFull
	end

	return superFunc(self)
end

function StonePicker:getCanToggleTurnedOn(superFunc)
	local spec = self.spec_stonePicker

	if not spec.needsActivation then
		return false
	end

	return superFunc(self)
end

function StonePicker:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_stonePicker

	if self.isServer and spec.fillUnitIndex == fillUnitIndex then
		local freeCapacity = self:getFillUnitFreeCapacity(spec.fillUnitIndex)

		if freeCapacity <= 0 and self:getIsTurnedOn() and not self:getIsAIActive() then
			self:setIsTurnedOn(false, false)
		end
	end
end

function StonePicker:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_stonePicker
	spec.startActivationTime = g_currentMission.time + spec.startActivationTimeout
end

function StonePicker:onDeactivate()
	if self.isClient then
		local spec = self.spec_stonePicker

		g_soundManager:stopSamples(spec.samples)

		spec.isWorkSamplePlaying = false
	end
end

function StonePicker:onStartWorkAreaProcessing(dt)
	local spec = self.spec_stonePicker
	spec.isWorking = false
	local dx, _, dz = localDirectionToWorld(spec.directionNode, 0, 0, 1)
	local angle = FSDensityMapUtil.convertToDensityMapAngle(MathUtil.getYRotationFromDirection(dx, dz), g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
	spec.workAreaParameters.isActive = not spec.needsActivation or self:getIsTurnedOn()
	spec.workAreaParameters.angle = angle
	spec.workAreaParameters.pickedLiters = 0
	spec.workAreaParameters.lastChangedArea = 0
	spec.workAreaParameters.lastStatsArea = 0
	spec.workAreaParameters.lastTotalArea = 0
end

function StonePicker:onEndWorkAreaProcessing(dt)
	local spec = self.spec_stonePicker
	local params = spec.workAreaParameters

	if self.isServer then
		local lastStatsArea = spec.workAreaParameters.lastStatsArea

		if lastStatsArea > 0 then
			self:updateLastWorkedArea(lastStatsArea)
		end

		local state = g_time - spec.workAreaParameters.lastChangedAreaTime < 500
		local soilState = spec.isWorking and self:getIsOnField()

		if spec.isEffectActive ~= state or spec.effectGrowthState ~= spec.workAreaParameters.lastGrowthState or soilState ~= spec.isSoilEffectActive then
			self:setStonePickerEffectsState(state, spec.workAreaParameters.lastGrowthState, soilState)
			self:raiseDirtyFlags(spec.dirtyFlag)
		end
	end

	local loadInfo = self:getFillVolumeLoadInfo(spec.loadInfoIndex)

	self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, params.pickedLiters, FillType.STONE, ToolType.UNDEFINED, loadInfo)
end

function StonePicker.getDefaultSpeedLimit()
	return 10
end
