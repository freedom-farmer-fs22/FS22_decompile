DynamicMountUtil = {
	TYPE_FORK = 1,
	TYPE_AUTO_ATTACH_XZ = 2,
	TYPE_AUTO_ATTACH_XYZ = 3,
	TYPE_AUTO_ATTACH_Y = 4,
	TYPE_FIX_ATTACH = 5
}

function DynamicMountUtil.mountDynamic(mountable, nodeId, object, objectActorId, jointNode, mountType, forceAcceleration, jointNode2)
	if mountable.dynamicMountObject ~= nil or nodeId == nil or nodeId == 0 then
		return false
	end

	local constr = JointConstructor.new()

	constr:setActors(objectActorId, nodeId)
	constr:setJointTransforms(jointNode, jointNode2 or jointNode)

	local isBreakable = false
	local forceLimit = nil

	if mountable.getTotalMass ~= nil then
		forceLimit = forceAcceleration * mountable:getTotalMass()
	else
		forceLimit = forceAcceleration * getMass(nodeId)
	end

	if mountType == DynamicMountUtil.TYPE_FORK then
		constr:setRotationLimit(0, 0, 0)
		constr:setRotationLimit(1, 0, 0)
		constr:setRotationLimit(2, 0, 0)

		if mountable.dynamicMountSingleAxisFreeX then
			constr:setTranslationLimit(0, false, 0, 0)
		else
			constr:setTranslationLimit(0, true, -0.01, 0.01)
		end

		if mountable.dynamicMountSingleAxisFreeY then
			constr:setTranslationLimit(1, false, 0, 0)
		else
			constr:setTranslationLimit(1, true, -0.01, 0.01)
		end

		constr:setTranslationLimit(2, false, 0, 0)
		constr:setLinearDrive(2, false, true, 0, 0, forceLimit, 0, 0)
		constr:setEnableCollision(true)
	elseif mountType == DynamicMountUtil.TYPE_AUTO_ATTACH_XZ or mountType == DynamicMountUtil.TYPE_AUTO_ATTACH_XYZ or mountType == DynamicMountUtil.TYPE_AUTO_ATTACH_Y then
		local x, y, z = getWorldTranslation(nodeId)

		constr:setJointWorldPositions(x, y, z, x, y, z)
		constr:setBreakable(forceLimit, forceLimit)

		isBreakable = true

		if mountType == DynamicMountUtil.TYPE_AUTO_ATTACH_XZ then
			constr:setTranslationLimit(1, false, 0, 0)
			constr:setRotationLimit(0, 0, 0)
			constr:setRotationLimit(1, 0, 0)
			constr:setRotationLimit(2, 0, 0)
		elseif mountType == DynamicMountUtil.TYPE_AUTO_ATTACH_Y then
			constr:setTranslationLimit(0, false, 0, 0)
			constr:setTranslationLimit(2, false, 0, 0)
		else
			constr:setRotationLimit(0, 0, 0)
			constr:setRotationLimit(1, 0, 0)
			constr:setRotationLimit(2, 0, 0)

			local spring = 1000
			local damping = 10

			constr:setRotationLimitSpring(spring, damping, spring, damping, spring, damping)
			constr:setTranslationLimitSpring(spring, damping, spring, damping, spring, damping)
		end

		constr:setEnableCollision(true)
	elseif mountType == DynamicMountUtil.TYPE_FIX_ATTACH then
		constr:setRotationLimit(0, 0, 0)
		constr:setRotationLimit(1, 0, 0)
		constr:setRotationLimit(2, 0, 0)
	else
		print("Warning: DynamicMountUtil.mountDynamic invalid mountType '" .. tostring(mountType) .. "'")
		printCallstack()

		return false
	end

	mountable.dynamicMountJointIndex = constr:finalize()

	if isBreakable then
		assert(mountable.onDynamicMountJointBreak ~= nil)
		addJointBreakReport(mountable.dynamicMountJointIndex, "onDynamicMountJointBreak", mountable)
	end

	mountable.dynamicMountObjectActorId = objectActorId
	mountable.dynamicMountObject = object
	mountable.dynamicMountJointNode = jointNode2 or jointNode

	mountable.dynamicMountObject:addDynamicMountedObject(mountable)

	return true
end

function DynamicMountUtil.unmountDynamic(mountable, remove)
	if mountable.dynamicMountJointIndex ~= nil then
		removeJoint(mountable.dynamicMountJointIndex)

		mountable.dynamicMountJointIndex = nil
		mountable.dynamicMountObjectActorId = nil

		if remove == nil or remove then
			mountable.dynamicMountObject:removeDynamicMountedObject(mountable, false)
		end

		mountable.dynamicMountObject = nil
	end
end
