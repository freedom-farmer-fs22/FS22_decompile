BigBag = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("BigBag")
		schema:register(XMLValueType.INT, "vehicle.bigBag#fillUnitIndex", "Fill unit index")
		schema:register(XMLValueType.STRING, "vehicle.bigBag.sizeAnimation#name", "Name of size animation")
		schema:register(XMLValueType.FLOAT, "vehicle.bigBag.sizeAnimation#minTime", "Min. animation that is used while it's empty", 0)
		schema:register(XMLValueType.FLOAT, "vehicle.bigBag.sizeAnimation#maxTime", "Max. animation that is used while it's full", 1)
		schema:register(XMLValueType.FLOAT, "vehicle.bigBag.sizeAnimation#liftShrinkTime", "Time of animation that is reduced while the big bag is lifted", 0.2)
		schema:register(XMLValueType.INT, "vehicle.bigBag.componentJoint#index", "Component Joint Index", 1)
		schema:register(XMLValueType.VECTOR_ROT, "vehicle.bigBag.componentJoint#minRotLimit", "Rot Limit if trans limit is at min")
		schema:register(XMLValueType.VECTOR_ROT, "vehicle.bigBag.componentJoint#maxRotLimit", "Rot Limit if trans limit is at max")
		schema:register(XMLValueType.VECTOR_TRANS, "vehicle.bigBag.componentJoint#minTransLimit", "Trans Limit if big bag is empty")
		schema:register(XMLValueType.VECTOR_TRANS, "vehicle.bigBag.componentJoint#maxTransLimit", "Trans Limit if big bag is full")
		schema:register(XMLValueType.FLOAT, "vehicle.bigBag.componentJoint#angularDamping", "Angular damping of components", 0.01)
		schema:setXMLSpecializationType()
	end,
	registerFunctions = function (vehicleType)
	end,
	registerOverwrittenFunctions = function (vehicleType)
	end,
	registerEventListeners = function (vehicleType)
		SpecializationUtil.registerEventListener(vehicleType, "onLoad", BigBag)
		SpecializationUtil.registerEventListener(vehicleType, "onUpdate", BigBag)
		SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", BigBag)
	end,
	onLoad = function (self, savegame)
		local spec = self.spec_bigBag
		spec.fillUnitIndex = self.xmlFile:getValue("vehicle.bigBag#fillUnitIndex", 1)
		spec.sizeAnimationName = self.xmlFile:getValue("vehicle.bigBag.sizeAnimation#name")
		spec.sizeAnimationMinTime = self.xmlFile:getValue("vehicle.bigBag.sizeAnimation#minTime", 0)
		spec.sizeAnimationMaxTime = self.xmlFile:getValue("vehicle.bigBag.sizeAnimation#maxTime", 1)
		spec.sizeAnimationLiftShrinkTime = self.xmlFile:getValue("vehicle.bigBag.sizeAnimation#liftShrinkTime", 0.2)
		spec.componentJointIndex = self.xmlFile:getValue("vehicle.bigBag.componentJoint#index", 1)
		local jointDesc = self.componentJoints[spec.componentJointIndex]

		if jointDesc ~= nil then
			spec.minRotLimit = self.xmlFile:getValue("vehicle.bigBag.componentJoint#minRotLimit", nil, true)
			spec.maxRotLimit = self.xmlFile:getValue("vehicle.bigBag.componentJoint#maxRotLimit", nil, true)

			if #spec.minRotLimit ~= 3 or #spec.maxRotLimit ~= 3 then
				spec.minRotLimit = nil
				spec.maxRotLimit = nil
			end

			spec.minTransLimit = self.xmlFile:getValue("vehicle.bigBag.componentJoint#minTransLimit", nil, true)
			spec.maxTransLimit = self.xmlFile:getValue("vehicle.bigBag.componentJoint#maxTransLimit", nil, true)

			if #spec.minTransLimit ~= 3 or #spec.maxTransLimit ~= 3 then
				spec.minTransLimit = nil
				spec.maxTransLimit = nil
			end

			spec.componentJoint = jointDesc
			spec.jointNode = jointDesc.jointNode
			spec.jointNodeReferenceNode = createTransformGroup("jointNodeReference")

			link(self.components[jointDesc.componentIndices[2]].node, spec.jointNodeReferenceNode)
			setWorldTranslation(spec.jointNodeReferenceNode, getWorldTranslation(spec.jointNode))
			setWorldRotation(spec.jointNodeReferenceNode, getWorldRotation(spec.jointNode))

			spec.component1 = self.components[spec.componentJoint.componentIndices[1]]
			spec.component2 = self.components[spec.componentJoint.componentIndices[2]]
			spec.angularDamping = self.xmlFile:getValue("vehicle.bigBag.componentJoint#angularDamping", 0.01)

			setAngularDamping(spec.component1.node, spec.angularDamping)
			setAngularDamping(spec.component2.node, spec.angularDamping)

			spec.lastJointLimitAlpha = -1
		end

		spec.currentShrinkTime = 0
		spec.currentSizeTime = 1
		spec.currentAnimationTime = 1
	end,
	onUpdate = function (self, dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
		local spec = self.spec_bigBag

		if spec.jointNode ~= nil then
			local xLimit, _, _ = MathUtil.lerp(spec.minTransLimit[1], spec.maxTransLimit[1], self:getFillUnitFillLevelPercentage(spec.fillUnitIndex))
			local xOffset, _, _ = localToLocal(spec.jointNode, spec.jointNodeReferenceNode, 0, 0, 0)
			local alpha = 1 - MathUtil.clamp((xOffset / xLimit + 1) / 2, 0, 1)
			spec.currentShrinkTime = alpha * spec.sizeAnimationLiftShrinkTime

			if self.isServer and math.abs(spec.lastJointLimitAlpha - alpha) > 0.05 then
				if spec.minRotLimit ~= nil and spec.maxRotLimit ~= nil then
					local rx, ry, rz = MathUtil.lerp3(spec.minRotLimit[1], spec.minRotLimit[2], spec.minRotLimit[3], spec.maxRotLimit[1], spec.maxRotLimit[2], spec.maxRotLimit[3], alpha)

					self:setComponentJointRotLimit(spec.componentJoint, 1, -rx, rx)
					self:setComponentJointRotLimit(spec.componentJoint, 2, -ry, ry)
					self:setComponentJointRotLimit(spec.componentJoint, 3, -rz, rz)
				end

				spec.lastJointLimitAlpha = alpha
			end

			local newAnimationTime = spec.currentSizeTime * (1 - spec.currentShrinkTime)

			if math.abs(newAnimationTime - spec.currentAnimationTime) > 0.01 then
				self:setAnimationTime(spec.sizeAnimationName, newAnimationTime)

				spec.currentAnimationTime = newAnimationTime
			end
		end
	end,
	onFillUnitFillLevelChanged = function (self, fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
		local spec = self.spec_bigBag

		if spec.fillUnitIndex == fillUnitIndex then
			local fillLevelPct = self:getFillUnitFillLevelPercentage(fillUnitIndex)
			spec.currentSizeTime = fillLevelPct * (spec.sizeAnimationMaxTime - spec.sizeAnimationMinTime) + spec.sizeAnimationMinTime
			spec.currentAnimationTime = spec.currentSizeTime * (1 - spec.currentShrinkTime)

			self:setAnimationTime(spec.sizeAnimationName, spec.currentAnimationTime)

			if self.isServer and spec.minTransLimit ~= nil and spec.maxTransLimit ~= nil then
				local x, y, z = MathUtil.lerp3(spec.minTransLimit[1], spec.minTransLimit[2], spec.minTransLimit[3], spec.maxTransLimit[1], spec.maxTransLimit[2], spec.maxTransLimit[3], fillLevelPct)

				self:setComponentJointTransLimit(spec.componentJoint, 1, -x, x)
				self:setComponentJointTransLimit(spec.componentJoint, 2, -y, y)
				self:setComponentJointTransLimit(spec.componentJoint, 3, -z, z)
			end
		end
	end
}
