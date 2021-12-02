LogGrab = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("LogGrab")
		schema:register(XMLValueType.INT, "vehicle.logGrab.grab(?)#componentJoint", "Component joint index")
		schema:register(XMLValueType.FLOAT, "vehicle.logGrab.grab(?)#dampingFactor", "Damping factor", 20)
		schema:register(XMLValueType.INT, "vehicle.logGrab.grab(?)#axis", "Grab axis", 1)
		schema:register(XMLValueType.ANGLE, "vehicle.logGrab.grab(?)#rotationOffsetThreshold", "Rotation offset threshold", 10)
		schema:register(XMLValueType.FLOAT, "vehicle.logGrab.grab(?)#rotationOffsetTime", "Rotation offset time until mount", 1000)
		schema:register(XMLValueType.NODE_INDEX, "vehicle.logGrab#jointNode", "Joint node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.logGrab#jointRoot", "Joint root node")
		schema:register(XMLValueType.BOOL, "vehicle.logGrab#lockAllAxis", "Lock all axis", false)
		schema:register(XMLValueType.NODE_INDEX, "vehicle.logGrab.trigger#node", "Trigger node")
		schema:setXMLSpecializationType()
	end
}

function LogGrab.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "logGrabTriggerCallback", LogGrab.logGrabTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "updateLogGrabState", LogGrab.updateLogGrabState)
	SpecializationUtil.registerFunction(vehicleType, "mountSplitShape", LogGrab.mountSplitShape)
	SpecializationUtil.registerFunction(vehicleType, "unmountSplitShape", LogGrab.unmountSplitShape)
end

function LogGrab.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addNodeObjectMapping", LogGrab.addNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeNodeObjectMapping", LogGrab.removeNodeObjectMapping)
end

function LogGrab.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", LogGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", LogGrab)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", LogGrab)
end

function LogGrab:onLoad(savegame)
	local spec = self.spec_logGrab

	if self.isServer then
		spec.grabs = {}
		local i = 0

		while true do
			local baseKey = string.format("vehicle.logGrab.grab(%d)", i)

			if not self.xmlFile:hasProperty(baseKey) then
				break
			end

			local entry = {
				componentJoint = self.xmlFile:getValue(baseKey .. "#componentJoint"),
				dampingFactor = self.xmlFile:getValue(baseKey .. "#dampingFactor", 20),
				axis = self.xmlFile:getValue(baseKey .. "#axis", 1),
				direction = {
					0,
					0,
					0
				}
			}
			entry.direction[entry.axis] = 1
			local componentJoint = self.componentJoints[entry.componentJoint]

			if componentJoint ~= nil then
				entry.startRotDifference = {
					localDirectionToLocal(self.components[componentJoint.componentIndices[2]].node, componentJoint.jointNode, unpack(entry.direction))
				}
			end

			entry.rotationOffsetThreshold = self.xmlFile:getValue(baseKey .. "#rotationOffsetThreshold", 10)
			entry.rotationOffsetTime = self.xmlFile:getValue(baseKey .. "#rotationOffsetTime", 1000)
			entry.rotationOffsetTimer = 0
			entry.rotationChangedTimer = 0
			entry.currentOffset = 0

			table.insert(spec.grabs, entry)

			i = i + 1
		end

		spec.jointNode = self.xmlFile:getValue("vehicle.logGrab#jointNode", nil, self.components, self.i3dMappings)
		spec.jointRoot = self.xmlFile:getValue("vehicle.logGrab#jointRoot", nil, self.components, self.i3dMappings)
		spec.lockAllAxis = self.xmlFile:getValue("vehicle.logGrab#lockAllAxis", false)
		spec.triggerNode = self.xmlFile:getValue("vehicle.logGrab.trigger#node", nil, self.components, self.i3dMappings)

		if spec.triggerNode ~= nil then
			addTrigger(spec.triggerNode, "logGrabTriggerCallback", self)
		end

		spec.pendingDynamicMountShapes = {}
		spec.dynamicMountedShapes = {}
		spec.jointLimitsOpen = false
	end

	if not self.isServer then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", LogGrab)
	end
end

function LogGrab:onDelete()
	local spec = self.spec_logGrab

	if spec.triggerNode ~= nil then
		removeTrigger(spec.triggerNode)
	end
end

function LogGrab:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_logGrab
	local isGrabClosed = true

	for _, grab in ipairs(spec.grabs) do
		if not self:updateLogGrabState(grab, dt) then
			isGrabClosed = false
		end
	end

	for shape, _ in pairs(spec.pendingDynamicMountShapes) do
		if not entityExists(shape) then
			spec.pendingDynamicMountShapes[shape] = nil
		end
	end

	if isGrabClosed then
		for shape, _ in pairs(spec.pendingDynamicMountShapes) do
			if spec.dynamicMountedShapes[shape] == nil then
				local jointIndex, jointTransform = self:mountSplitShape(shape)

				if jointIndex ~= nil then
					spec.dynamicMountedShapes[shape] = {
						jointIndex = jointIndex,
						jointTransform = jointTransform
					}
					spec.pendingDynamicMountShapes[shape] = nil
				end
			end
		end

		if not spec.jointLimitsOpen and next(spec.dynamicMountedShapes) ~= nil then
			spec.jointLimitsOpen = true

			for _, grab in ipairs(spec.grabs) do
				local componentJoint = self.componentJoints[grab.componentJoint]

				if componentJoint ~= nil then
					for i = 1, 3 do
						setJointRotationLimitSpring(componentJoint.jointIndex, i - 1, componentJoint.rotLimitSpring[i], componentJoint.rotLimitDamping[i] * grab.dampingFactor)
					end
				end
			end
		end
	else
		for shapeId, shapeData in pairs(spec.dynamicMountedShapes) do
			self:unmountSplitShape(shapeId, shapeData.jointIndex, shapeData.jointTransform, false)
		end

		if spec.jointLimitsOpen then
			spec.jointLimitsOpen = false

			for _, grab in ipairs(spec.grabs) do
				local componentJoint = self.componentJoints[grab.componentJoint]

				if componentJoint ~= nil then
					for i = 1, 3 do
						setJointRotationLimitSpring(componentJoint.jointIndex, i - 1, componentJoint.rotLimitSpring[i], componentJoint.rotLimitDamping[i])
					end
				end
			end
		end
	end
end

function LogGrab:updateLogGrabState(grab, dt)
	local componentJoint = self.componentJoints[grab.componentJoint]

	if componentJoint ~= nil then
		local start = grab.startRotDifference
		local dirX, dirY, dirZ = localDirectionToLocal(self.components[componentJoint.componentIndices[2]].node, componentJoint.jointNode, unpack(grab.direction))
		local currentOffset = 0

		if grab.axis == 1 then
			currentOffset = start[1] - dirX
		elseif grab.axis == 2 then
			currentOffset = start[2] - dirY
		elseif grab.axis == 3 then
			currentOffset = start[3] - dirZ
		end

		if grab.rotationOffsetThreshold < math.abs(currentOffset) then
			if grab.rotationOffsetTime < grab.rotationOffsetTimer then
				return true
			else
				grab.rotationOffsetTimer = grab.rotationOffsetTimer + dt
			end
		elseif grab.rotationOffsetTimer > 0 then
			local x, y, z = getRotation(componentJoint.jointNode)
			local rotSum = x + y + z

			if grab.lastRotation ~= nil and rotSum ~= grab.lastRotation then
				grab.rotationOffsetTimer = 0
				grab.rotationChangedTimer = 750
				grab.lastRotation = nil
			else
				grab.rotationChangedTimer = math.max(grab.rotationChangedTimer - dt)

				if grab.rotationChangedTimer <= 0 then
					grab.lastRotation = rotSum

					return true
				else
					grab.rotationOffsetTimer = 0
					grab.lastRotation = nil
				end
			end
		end

		grab.currentOffset = currentOffset
	end

	return false
end

function LogGrab:mountSplitShape(shapeId)
	local spec = self.spec_logGrab
	local constr = JointConstructor.new()

	constr:setActors(spec.jointRoot, shapeId)

	local jointTransform = createTransformGroup("dynamicMountJoint")

	link(spec.jointNode, jointTransform)
	constr:setJointTransforms(jointTransform, jointTransform)
	constr:setRotationLimit(0, 0, 0)
	constr:setRotationLimit(1, 0, 0)
	constr:setRotationLimit(2, 0, 0)

	if not spec.lockAllAxis then
		constr:setTranslationLimit(1, false, 0, 0)
		constr:setTranslationLimit(2, false, 0, 0)
		constr:setEnableCollision(true)
	end

	local springForce = 7500
	local springDamping = 1500

	constr:setRotationLimitSpring(springForce, springDamping, springForce, springDamping, springForce, springDamping)
	constr:setTranslationLimitSpring(springForce, springDamping, springForce, springDamping, springForce, springDamping)

	return constr:finalize(), jointTransform
end

function LogGrab:unmountSplitShape(shapeId, jointIndex, jointTransform, isDeleting)
	removeJoint(jointIndex)
	delete(jointTransform)

	local spec = self.spec_logGrab
	spec.dynamicMountedShapes[shapeId] = nil

	if isDeleting ~= nil and isDeleting then
		spec.pendingDynamicMountShapes[shapeId] = nil
	else
		spec.pendingDynamicMountShapes[shapeId] = true
	end
end

function LogGrab:logGrabTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_logGrab

	if onEnter then
		if getSplitType(otherActorId) ~= 0 then
			local rigidBodyType = getRigidBodyType(otherActorId)

			if (rigidBodyType == RigidBodyType.DYNAMIC or rigidBodyType == RigidBodyType.KINEMATIC) and spec.pendingDynamicMountShapes[otherActorId] == nil then
				spec.pendingDynamicMountShapes[otherActorId] = true
			end
		end
	elseif onLeave and getSplitType(otherActorId) ~= 0 then
		if spec.pendingDynamicMountShapes[otherActorId] ~= nil then
			spec.pendingDynamicMountShapes[otherActorId] = nil
		elseif spec.dynamicMountedShapes[otherActorId] ~= nil then
			self:unmountSplitShape(otherActorId, spec.dynamicMountedShapes[otherActorId].jointIndex, spec.dynamicMountedShapes[otherActorId].jointTransform, true)
		end
	end
end

function LogGrab:addNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_logGrab

	if spec.logGrabTrigger ~= nil and spec.logGrabTrigger.triggerNode ~= nil then
		list[spec.logGrabTrigger.triggerNode] = self
	end
end

function LogGrab:removeNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_logGrab

	if spec.logGrabTrigger ~= nil and spec.logGrabTrigger.triggerNode ~= nil then
		list[spec.logGrabTrigger.triggerNode] = nil
	end
end

function LogGrab:updateDebugValues(values)
	local spec = self.spec_logGrab

	if self.isServer then
		for i, grab in ipairs(spec.grabs) do
			table.insert(values, {
				name = string.format("grab (%d):", i),
				value = string.format("current: %.2fdeg / threshold: %.2fdeg  (timer: %d)", math.deg(math.abs(grab.currentOffset)), math.deg(grab.rotationOffsetThreshold), grab.rotationOffsetTimer)
			})
		end

		for shapeId, _ in pairs(spec.dynamicMountedShapes) do
			if entityExists(shapeId) then
				table.insert(values, {
					name = "mounted: ",
					value = tostring(getName(shapeId))
				})
			end
		end

		for shapeId, _ in pairs(spec.pendingDynamicMountShapes) do
			if entityExists(shapeId) then
				table.insert(values, {
					name = "pending: ",
					value = tostring(getName(shapeId))
				})
			end
		end
	end
end
