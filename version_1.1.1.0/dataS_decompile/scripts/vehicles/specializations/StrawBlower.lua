StrawBlower = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(Trailer, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("StrawBlower")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.strawBlower.baleTrigger#node", "Bale trigger node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.strawBlower.balePickupTrigger#node", "Bale pickup trigger node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.strawBlower.balePickupTrigger#spawnNode", "Bale pickup trigger spawn node")
		schema:register(XMLValueType.INT, "vehicle.strawBlower.balePickupTrigger#maxBales", "Max. number of pickup bales")
		schema:register(XMLValueType.INT, "vehicle.strawBlower#fillUnitIndex", "Fill unit index", 1)
		AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.strawBlower.animationNodes")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.strawBlower.sounds", "start")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.strawBlower.sounds", "stop")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.strawBlower.sounds", "work")
		schema:setXMLSpecializationType()
	end
}

function StrawBlower.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "strawBlowerBaleTriggerCallback", StrawBlower.strawBlowerBaleTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "onDeleteStrawBlowerObject", StrawBlower.onDeleteStrawBlowerObject)
	SpecializationUtil.registerFunction(vehicleType, "strawBlowerBalePickupTriggerCallback", StrawBlower.strawBlowerBalePickupTriggerCallback)
end

function StrawBlower.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", StrawBlower.getDrawFirstFillText)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", StrawBlower.getAllowDynamicMountFillLevelInfo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", StrawBlower.addFillUnitFillLevel)
end

function StrawBlower.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", StrawBlower)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", StrawBlower)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", StrawBlower)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", StrawBlower)
	SpecializationUtil.registerEventListener(vehicleType, "onDischargeStateChanged", StrawBlower)
end

function StrawBlower:onLoad(savegame)
	local spec = self.spec_strawBlower

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.strawBlower.baleTrigger#index", "vehicle.strawBlower.baleTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.strawBlower.doorAnimation#name", "vehicle.foldable.foldingParts.foldingPart.animationName")

	spec.triggeredBales = {}

	if self.isServer then
		spec.triggerId = self.xmlFile:getValue("vehicle.strawBlower.baleTrigger#node", nil, self.components, self.i3dMappings)

		if spec.triggerId ~= nil then
			addTrigger(spec.triggerId, "strawBlowerBaleTriggerCallback", self)
		end

		spec.pickupTriggerId = self.xmlFile:getValue("vehicle.strawBlower.balePickupTrigger#node", nil, self.components, self.i3dMappings)

		if spec.pickupTriggerId ~= nil then
			addTrigger(spec.pickupTriggerId, "strawBlowerBalePickupTriggerCallback", self)
		end

		spec.pickupTriggerSpawnNode = self.xmlFile:getValue("vehicle.strawBlower.balePickupTrigger#spawnNode", nil, self.components, self.i3dMappings)
		spec.pickupTriggerMaxBales = self.xmlFile:getValue("vehicle.strawBlower.balePickupTrigger#maxBales", 2)
	end

	if self.isClient then
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.strawBlower.animationNodes", self.components, self, self.i3dMappings)
		spec.samples = {
			start = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.strawBlower.sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			stop = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.strawBlower.sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.strawBlower.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end

	spec.fillUnitIndex = self.xmlFile:getValue("vehicle.strawBlower#fillUnitIndex", 1)
	local fillUnit = self:getFillUnitByIndex(spec.fillUnitIndex)
	fillUnit.synchronizeFullFillLevel = true
	fillUnit.needsSaving = false

	if savegame ~= nil and not savegame.resetVehicles then
		self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, FillType.UNKNOWN, ToolType.UNDEFINED)
	end

	if not self.isServer then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", StrawBlower)
	end
end

function StrawBlower:onDelete()
	local spec = self.spec_strawBlower

	if spec.triggerId ~= nil then
		removeTrigger(spec.triggerId)
	end

	if spec.pickupTriggerId ~= nil then
		removeTrigger(spec.pickupTriggerId)
	end

	if spec.triggeredBales ~= nil then
		for bale, _ in pairs(spec.triggeredBales) do
			if entityExists(bale.nodeId) then
				I3DUtil.wakeUpObject(bale.nodeId)

				bale.allowPickup = true
			end
		end
	end

	g_soundManager:deleteSamples(spec.samples)
	g_animationManager:deleteAnimations(spec.animationNodes)
end

function StrawBlower:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_strawBlower

	if spec.currentBale == nil and self:getFillUnitSupportsToolType(spec.fillUnitIndex, ToolType.BALE) then
		local bale = next(spec.triggeredBales)

		if bale ~= nil then
			self:setFillUnitCapacity(spec.fillUnitIndex, bale:getFillLevel())
			self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, FillType.UNKNOWN, ToolType.UNDEFINED)
			self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, bale:getFillLevel(), bale:getFillType(), ToolType.BALE)

			spec.currentBale = bale
		end
	end
end

function StrawBlower:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
	local spec = self.spec_strawBlower

	if fillUnitIndex == spec.fillUnitIndex then
		self:setFillUnitCapacity(fillUnitIndex, math.max(self:getFillUnitCapacity(fillUnitIndex), self:getFillUnitFillLevel(fillUnitIndex) + fillLevelDelta))
	end

	return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData)
end

function StrawBlower:strawBlowerBaleTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_strawBlower

	if onEnter then
		if otherActorId ~= 0 then
			local object = g_currentMission:getNodeObject(otherActorId)

			if object ~= nil and object:isa(Bale) and g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), object) and object:getAllowPickup() and self:getFillUnitSupportsFillType(spec.fillUnitIndex, object:getFillType()) then
				spec.triggeredBales[object] = Utils.getNoNil(spec.triggeredBales[object], 0) + 1
				object.allowPickup = false

				if spec.triggeredBales[object] == 1 and object.addDeleteListener ~= nil then
					object:addDeleteListener(self, "onDeleteStrawBlowerObject")
				end
			end
		end
	elseif onLeave and otherActorId ~= 0 then
		local object = g_currentMission:getNodeObject(otherActorId)

		if object ~= nil then
			local triggerCount = spec.triggeredBales[object]

			if triggerCount ~= nil then
				if triggerCount == 1 then
					spec.triggeredBales[object] = nil
					object.allowPickup = true

					if object == spec.currentBale then
						spec.currentBale = nil

						self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, self:getFillUnitFillType(spec.fillUnitIndex), ToolType.UNDEFINED)
					end

					if object.removeDeleteListener ~= nil then
						object:removeDeleteListener(self)
					end
				else
					spec.triggeredBales[object] = triggerCount - 1
				end
			end
		end
	end
end

function StrawBlower:onDeleteStrawBlowerObject(object)
	local spec = self.spec_strawBlower

	if spec.triggeredBales[object] ~= nil then
		spec.triggeredBales[object] = nil

		if object == spec.currentBale then
			spec.currentBale = nil

			self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, self:getFillUnitFillType(spec.fillUnitIndex), ToolType.UNDEFINED)
		end
	end
end

function StrawBlower:strawBlowerBalePickupTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_strawBlower

	if onEnter and otherActorId ~= 0 then
		local object = g_currentMission:getNodeObject(otherActorId)

		if object ~= nil and object:isa(Bale) and g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), object) and object:getAllowPickup() and self:getFillUnitSupportsFillType(spec.fillUnitIndex, object:getFillType()) and spec.triggeredBales[object] == nil then
			local maxHeight = 0
			local count = 0

			for bale, _ in pairs(spec.triggeredBales) do
				local _, y, _ = getWorldTranslation(bale.nodeId)
				y = y + (bale.baleDiameter or bale.baleHeight) / 2

				if maxHeight < y then
					maxHeight = y
				end

				count = count + 1
			end

			if count < spec.pickupTriggerMaxBales then
				local x, y, z = getWorldTranslation(spec.pickupTriggerSpawnNode)
				local baleHeight = (object.baleDiameter or object.baleHeight) / 2
				y = math.max(y, maxHeight) + baleHeight

				removeFromPhysics(object.nodeId)
				setTranslation(object.nodeId, x, y, z)
				setWorldRotation(object.nodeId, getWorldRotation(spec.pickupTriggerSpawnNode))
				addToPhysics(object.nodeId)

				local vx, vy, vz = getLinearVelocity(self:getParentComponent(spec.pickupTriggerSpawnNode))

				setLinearVelocity(object.nodeId, vx, vy, vz)
			end
		end
	end
end

function StrawBlower:getDrawFirstFillText(superFunc)
	local spec = self.spec_strawBlower

	return superFunc(self) or self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0
end

function StrawBlower:getAllowDynamicMountFillLevelInfo(superFunc)
	return false
end

function StrawBlower:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_strawBlower

	if fillUnitIndex == spec.fillUnitIndex then
		local newFillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)

		if self.isServer then
			local bale = spec.currentBale

			if bale ~= nil then
				if newFillLevel <= 0.01 then
					if self.removeDynamicMountedObject ~= nil then
						self:removeDynamicMountedObject(bale)
					end

					local baleOwner = bale:getOwnerFarmId()

					bale:delete()

					spec.currentBale = nil
					spec.triggeredBales[bale] = nil

					self:setFillUnitCapacity(spec.fillUnitIndex, 1)
					self:addFillUnitFillLevel(baleOwner, spec.fillUnitIndex, -math.huge, FillType.UNKNOWN, ToolType.UNDEFINED)
				elseif newFillLevel < bale:getFillLevel() and fillTypeIndex == bale:getFillType() then
					bale:setFillLevel(newFillLevel)
				end
			end
		elseif newFillLevel <= 0 then
			self:setFillUnitCapacity(spec.fillUnitIndex, 1)
		end
	end
end

function StrawBlower:onDischargeStateChanged(state)
	local spec = self.spec_strawBlower
	local samples = spec.samples

	if self.isClient then
		if state ~= Dischargeable.DISCHARGE_STATE_OFF then
			g_soundManager:stopSample(samples.work)
			g_soundManager:stopSample(samples.stop)
			g_soundManager:playSample(samples.start)
			g_soundManager:playSample(samples.work, 0, samples.start)
			g_animationManager:startAnimations(spec.animationNodes)
		else
			g_soundManager:stopSample(samples.start)
			g_soundManager:stopSample(samples.work)
			g_soundManager:playSample(samples.stop)
			g_animationManager:stopAnimations(spec.animationNodes)
		end
	end
end
