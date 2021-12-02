ConveyorBelt = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Dischargeable, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("ConveyorBelt")
		AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.conveyorBelt.animationNodes")
		EffectManager.registerEffectXMLPaths(schema, "vehicle.conveyorBelt.effects")
		schema:register(XMLValueType.INT, "vehicle.conveyorBelt#dischargeNodeIndex", "Discharge node index", 1)
		schema:register(XMLValueType.FLOAT, "vehicle.conveyorBelt#startPercentage", "Start unloading percentage", 0.9)
		schema:register(XMLValueType.NODE_INDEX, "vehicle.conveyorBelt.offset(?)#movingToolNode", "Moving tool node")
		schema:register(XMLValueType.INT, "vehicle.conveyorBelt.offset(?).effect(?)#index", "Index of effect", 0)
		schema:register(XMLValueType.FLOAT, "vehicle.conveyorBelt.offset(?).effect(?)#minOffset", "Min. offset", 0)
		schema:register(XMLValueType.FLOAT, "vehicle.conveyorBelt.offset(?).effect(?)#maxOffset", "Max. offset", 1)
		schema:register(XMLValueType.BOOL, "vehicle.conveyorBelt.offset(?).effect(?)#inverted", "Is inverted", false)
		SoundManager.registerSampleXMLPaths(schema, "vehicle.conveyorBelt.sounds", "belt")
		schema:setXMLSpecializationType()
	end
}

function ConveyorBelt.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getConveyorBeltFillLevel", ConveyorBelt.getConveyorBeltFillLevel)
	SpecializationUtil.registerFunction(vehicleType, "getConveyorBeltTargetObject", ConveyorBelt.getConveyorBeltTargetObject)
	SpecializationUtil.registerFunction(vehicleType, "getLoadTriggerMaxFillSpeed", ConveyorBelt.getLoadTriggerMaxFillSpeed)
end

function ConveyorBelt.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", ConveyorBelt.getDischargeNodeEmptyFactor)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischargeOnEmpty", ConveyorBelt.handleDischargeOnEmpty)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleDischarge", ConveyorBelt.handleDischarge)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsEnterable", ConveyorBelt.getIsEnterable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitAllowsFillType", ConveyorBelt.getFillUnitAllowsFillType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitFreeCapacity", ConveyorBelt.getFillUnitFreeCapacity)
end

function ConveyorBelt.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", ConveyorBelt)
	SpecializationUtil.registerEventListener(vehicleType, "onMovingToolChanged", ConveyorBelt)
end

function ConveyorBelt:onLoad(savegame)
	local spec = self.spec_conveyorBelt

	if self.isClient then
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.conveyorBelt.animationNodes", self.components, self, self.i3dMappings)
		spec.samples = {
			belt = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.conveyorBelt.sounds", "belt", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end

	spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.conveyorBelt.effects", self.components, self, self.i3dMappings)
	spec.currentDelay = 0

	table.sort(spec.effects, function (effect1, effect2)
		return effect1.startDelay < effect2.startDelay
	end)

	for _, effect in pairs(spec.effects) do
		if effect.planeFadeTime ~= nil then
			spec.currentDelay = spec.currentDelay + effect.planeFadeTime
		end

		if effect.setScrollUpdate ~= nil then
			effect:setScrollUpdate(false)
		end
	end

	spec.maxDelay = spec.currentDelay
	spec.morphStartPos = 0
	spec.morphEndPos = 0
	spec.isEffectDirty = true
	spec.emptyFactor = 1
	spec.scrollUpdateTime = 0
	spec.lastScrollUpdate = false
	spec.dischargeNodeIndex = self.xmlFile:getValue("vehicle.conveyorBelt#dischargeNodeIndex", 1)

	self:setCurrentDischargeNodeIndex(spec.dischargeNodeIndex)

	local dischargeNode = self:getDischargeNodeByIndex(spec.dischargeNodeIndex)
	local capacity = self:getFillUnitCapacity(dischargeNode.fillUnitIndex)
	spec.fillUnitIndex = dischargeNode.fillUnitIndex
	spec.startFillLevel = capacity * self.xmlFile:getValue("vehicle.conveyorBelt#startPercentage", 0.9)
	local i = 0

	while true do
		local key = string.format("vehicle.conveyorBelt.offset(%d)", i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local movingToolNode = self.xmlFile:getValue(key .. "#movingToolNode", nil, self.components, self.i3dMappings)

		if movingToolNode ~= nil then
			if spec.offsets == nil then
				spec.offsets = {}
			end

			local offset = {
				lastState = 0,
				movingToolNode = movingToolNode,
				effects = {}
			}
			local j = 0

			while true do
				local effectKey = string.format(key .. ".effect(%d)", j)

				if not self.xmlFile:hasProperty(effectKey) then
					break
				end

				local effectIndex = self.xmlFile:getValue(effectKey .. "#index", 0)
				local effect = spec.effects[effectIndex]

				if effect ~= nil and effect.setOffset ~= nil then
					local entry = {
						effect = effect,
						minValue = self.xmlFile:getValue(effectKey .. "#minOffset", 0) * 1000,
						maxValue = self.xmlFile:getValue(effectKey .. "#maxOffset", 1) * 1000,
						inverted = self.xmlFile:getValue(effectKey .. "#inverted", false)
					}

					table.insert(offset.effects, entry)
				else
					Logging.xmlWarning(self.xmlFile, "Effect index '%d' not found at '%s'!", effectIndex, effectKey)
				end

				j = j + 1
			end

			table.insert(spec.offsets, offset)
		else
			Logging.xmlWarning(self.xmlFile, "Missing movingToolNode for conveyor offset '%s'!", key)
		end

		i = i + 1
	end
end

function ConveyorBelt:onPostLoad(savegame)
	local spec = self.spec_conveyorBelt

	if spec.offsets ~= nil then
		if self.getMovingToolByNode ~= nil then
			spec.movingToolToOffset = {}

			for i = #spec.offsets, 1, -1 do
				local offset = spec.offsets[i]
				local movingTool = self:getMovingToolByNode(offset.movingToolNode)

				if movingTool ~= nil then
					offset.movingTool = movingTool
					spec.movingToolToOffset[movingTool] = offset

					ConveyorBelt.onMovingToolChanged(self, movingTool, 0, 0)
				else
					Logging.xmlWarning(self.xmlFile, "No movingTool node '%s' defined for conveyor offset '%d'!", getName(offset.movingToolNode), i)
					table.remove(spec.offsets, i)
				end
			end

			if #spec.offsets == 0 then
				spec.offsets = nil
				spec.movingToolToOffset = nil
			end
		else
			Logging.xmlError(self.xmlFile, "'Cylindered' specialization is required to use conveyorBelt offsets!")

			spec.offsets = nil
		end
	end
end

function ConveyorBelt:onDelete()
	local spec = self.spec_conveyorBelt

	g_effectManager:deleteEffects(spec.effects)
	g_animationManager:deleteAnimations(spec.animationNodes)
	g_soundManager:deleteSamples(spec.samples)
end

function ConveyorBelt:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_conveyorBelt
	local doScrollUpdate = spec.scrollUpdateTime > 0

	if doScrollUpdate ~= spec.lastScrollUpdate then
		if self.isClient then
			if doScrollUpdate then
				g_animationManager:startAnimations(spec.animationNodes)
				g_soundManager:playSample(spec.samples.belt)
			else
				g_animationManager:stopAnimations(spec.animationNodes)
				g_soundManager:stopSample(spec.samples.belt)
			end

			for _, effect in pairs(spec.effects) do
				if effect.setScrollUpdate ~= nil then
					effect:setScrollUpdate(doScrollUpdate)
				end
			end
		end

		spec.lastScrollUpdate = doScrollUpdate
	end

	spec.scrollUpdateTime = math.max(spec.scrollUpdateTime - dt, 0)
	local isBeltActive = self:getDischargeState() ~= Dischargeable.DISCHARGE_STATE_OFF

	if isBeltActive then
		local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)

		if fillLevel > 0.0001 then
			local movedFactor = dt / spec.currentDelay
			spec.morphStartPos = MathUtil.clamp(spec.morphStartPos + movedFactor, 0, 1)
			spec.morphEndPos = MathUtil.clamp(spec.morphEndPos + movedFactor, 0, 1)
			local fillFactor = fillLevel / self:getFillUnitCapacity(spec.fillUnitIndex)
			local visualFactor = spec.morphEndPos - spec.morphStartPos
			spec.emptyFactor = 1

			if fillFactor < visualFactor then
				spec.emptyFactor = MathUtil.clamp(fillFactor / visualFactor, 0, 1)
			else
				local offset = fillFactor - visualFactor
				spec.offset = offset
				spec.morphStartPos = MathUtil.clamp(spec.morphStartPos - offset / ((1 - spec.morphStartPos) * spec.currentDelay) * dt, 0, 1)
			end

			spec.isEffectDirty = true
			spec.scrollUpdateTime = dt * 3
		end
	end

	if doScrollUpdate then
		self:raiseActive()
	end

	if self.isClient and spec.isEffectDirty then
		for _, effect in pairs(spec.effects) do
			if effect.setMorphPosition ~= nil then
				local effectStart = effect.startDelay / spec.currentDelay
				local effectEnd = (effect.startDelay + effect.planeFadeTime - effect.offset) / spec.currentDelay
				local offsetFactor = effect.offset / effect.planeFadeTime
				local startMorphFactor = (spec.morphStartPos - effectStart) / (effectEnd - effectStart)
				local startMorph = MathUtil.clamp(offsetFactor + startMorphFactor * (1 - offsetFactor), offsetFactor, 1)
				local endMorphFactor = (spec.morphEndPos - effectStart) / (effectEnd - effectStart)
				local endMorph = MathUtil.clamp(offsetFactor + endMorphFactor * (1 - offsetFactor), offsetFactor, 1)

				effect:setMorphPosition(startMorph, endMorph)
			end
		end

		spec.isEffectDirty = false
	end
end

function ConveyorBelt:getConveyorBeltFillLevel()
	local spec = self.spec_conveyorBelt
	local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)

	if self.getCurrentDischargeNode ~= nil then
		local currentDischargeNode = self:getCurrentDischargeNode()
		local object = currentDischargeNode.dischargeHitObject

		if object ~= nil and object.getConveyorBeltFillLevel ~= nil then
			fillLevel = fillLevel + object:getConveyorBeltFillLevel()
		end
	end

	return fillLevel
end

function ConveyorBelt:getConveyorBeltTargetObject()
	if self.getCurrentDischargeNode ~= nil then
		local currentDischargeNode = self:getCurrentDischargeNode()
		local object = currentDischargeNode.dischargeHitObject
		local targetFillUnitIndex = currentDischargeNode.dischargeHitObjectUnitIndex

		if object ~= nil then
			if object.getConveyorBeltTargetObject ~= nil then
				return object:getConveyorBeltTargetObject()
			else
				return object, targetFillUnitIndex
			end
		end
	end

	return nil
end

function ConveyorBelt:getLoadTriggerMaxFillSpeed()
	local maxSpeed = math.huge

	if self.getCurrentDischargeNode ~= nil then
		local currentDischargeNode = self:getCurrentDischargeNode()
		maxSpeed = currentDischargeNode.emptySpeed
		local object = currentDischargeNode.dischargeHitObject

		if object ~= nil and object.getLoadTriggerMaxFillSpeed ~= nil then
			maxSpeed = math.min(object:getLoadTriggerMaxFillSpeed(), maxSpeed)
		end
	end

	return maxSpeed
end

function ConveyorBelt:getDischargeNodeEmptyFactor(superFunc, dischargeNode)
	local spec = self.spec_conveyorBelt
	local parentFactor = superFunc(self, dischargeNode)

	if spec.dischargeNodeIndex == dischargeNode.index then
		if spec.morphEndPos == 1 then
			return spec.emptyFactor
		else
			return 0
		end
	end

	return parentFactor
end

function ConveyorBelt:handleDischargeOnEmpty(superFunc, dischargeNode)
	local spec = self.spec_conveyorBelt

	if dischargeNode.index ~= spec.dischargeNodeIndex then
		superFunc(self, dischargeNode)
	end
end

function ConveyorBelt:handleDischarge(superFunc, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	local spec = self.spec_conveyorBelt

	if dischargeNode.index ~= spec.dischargeNodeIndex then
		superFunc(self, dischargeNode, dischargedLiters, minDropReached, hasMinDropFillLevel)
	end
end

function ConveyorBelt:getIsEnterable(superFunc)
	return (self.getAttacherVehicle == nil or self:getAttacherVehicle() == nil) and superFunc(self)
end

function ConveyorBelt:getFillUnitAllowsFillType(superFunc, fillUnitIndex, fillType)
	if not superFunc(self, fillUnitIndex, fillType) then
		return false
	end

	if self.getCurrentDischargeNode ~= nil then
		local currentDischargeNode = self:getCurrentDischargeNode()
		local object = currentDischargeNode.dischargeHitObject
		local targetFillUnitIndex = currentDischargeNode.dischargeHitObjectUnitIndex

		if object ~= nil and object.getFillUnitAllowsFillType ~= nil and targetFillUnitIndex ~= nil then
			return object:getFillUnitAllowsFillType(targetFillUnitIndex, fillType)
		end
	end

	return true
end

function ConveyorBelt:getFillUnitFreeCapacity(superFunc, fillUnitIndex, fillTypeIndex, farmId)
	local freeCapacity = superFunc(self, fillUnitIndex, fillTypeIndex, farmId)

	if self.getCurrentDischargeNode ~= nil then
		local currentDischargeNode = self:getCurrentDischargeNode()
		local object = currentDischargeNode.dischargeHitObject
		local targetFillUnitIndex = currentDischargeNode.dischargeHitObjectUnitIndex

		if object ~= nil and object.getFillUnitFreeCapacity ~= nil and targetFillUnitIndex ~= nil then
			return freeCapacity + object:getFillUnitFreeCapacity(targetFillUnitIndex, fillTypeIndex, farmId)
		end
	end

	return freeCapacity
end

function ConveyorBelt:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_conveyorBelt

	if spec.fillUnitIndex == fillUnitIndex then
		local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)

		if fillLevelDelta > 0 then
			spec.morphStartPos = 0
			spec.morphEndPos = math.max(spec.morphEndPos, fillLevel / self:getFillUnitCapacity(fillUnitIndex))
			spec.isEffectDirty = true
		end

		if fillLevelDelta ~= 0 then
			spec.scrollUpdateTime = 100
		end

		if fillLevel == 0 then
			g_effectManager:stopEffects(spec.effects)

			spec.morphStartPos = 0
			spec.morphEndPos = 0
			spec.isEffectDirty = true
		else
			g_effectManager:setFillType(spec.effects, fillType)
			g_effectManager:startEffects(spec.effects)
		end
	end
end

function ConveyorBelt:onMovingToolChanged(movingTool, speed, dt)
	local spec = self.spec_conveyorBelt

	if spec.offsets ~= nil then
		local offset = spec.movingToolToOffset[movingTool]

		if offset ~= nil then
			local state = Cylindered.getMovingToolState(self, movingTool)

			if state ~= offset.lastState then
				local updateDelay = false

				for _, entry in pairs(offset.effects) do
					local effectState = state

					if entry.inverted then
						effectState = 1 - effectState
					end

					entry.effect:setOffset(MathUtil.lerp(entry.minValue, entry.maxValue, effectState))

					updateDelay = true
					spec.isEffectDirty = true
				end

				if updateDelay then
					spec.currentDelay = 0

					for _, effect in pairs(spec.effects) do
						if effect.planeFadeTime ~= nil then
							spec.currentDelay = spec.currentDelay + effect.planeFadeTime - effect.offset
						end
					end
				end

				offset.lastState = state
			end
		end
	end
end

function ConveyorBelt:updateDebugValues(values)
	local spec = self.spec_conveyorBelt

	table.insert(values, {
		name = "offset",
		value = spec.offset
	})
	table.insert(values, {
		name = "morphStartPos",
		value = spec.morphStartPos
	})
	table.insert(values, {
		name = "morphEndPos",
		value = spec.morphEndPos
	})
end
