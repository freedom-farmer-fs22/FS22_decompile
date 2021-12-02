MountableObject = {
	MOUNT_TYPE_NONE = 1,
	MOUNT_TYPE_DEFAULT = 2,
	MOUNT_TYPE_KINEMATIC = 3,
	MOUNT_TYPE_DYNAMIC = 4
}
local MountableObject_mt = Class(MountableObject, PhysicsObject)

InitStaticObjectClass(MountableObject, "MountableObject", ObjectIds.OBJECT_MOUNTABLE_OBJECT)

function MountableObject.new(isServer, isClient, customMt)
	local self = PhysicsObject.new(isServer, isClient, customMt or MountableObject_mt)
	self.dynamicMountSingleAxisFreeX = false
	self.dynamicMountSingleAxisFreeY = false
	self.dynamicMountType = MountableObject.MOUNT_TYPE_NONE
	self.lastMoveTime = -100000

	return self
end

function MountableObject:delete()
	if self.dynamicMountTriggerId ~= nil then
		removeTrigger(self.dynamicMountTriggerId)
	end

	if self.dynamicMountJointIndex ~= nil then
		removeJointBreakReport(self.dynamicMountJointIndex)
		removeJoint(self.dynamicMountJointIndex)
	end

	if self.dynamicMountObject ~= nil then
		self.dynamicMountObject:removeDynamicMountedObject(self, true)
	end

	if self.mountObject ~= nil and self.mountObject.removeMountedObject ~= nil then
		self.mountObject:removeMountedObject(self, true)
	end

	MountableObject:superClass().delete(self)
end

function MountableObject:getAllowsAutoDelete()
	return self.mountObject == nil and MountableObject:superClass().getAllowsAutoDelete(self)
end

function MountableObject:testScope(x, y, z, coeff)
	if self.mountObject ~= nil then
		return self.mountObject:testScope(x, y, z, coeff)
	end

	if self.dynamicMountObject ~= nil then
		return self.dynamicMountObject:testScope(x, y, z, coeff)
	end

	return MountableObject:superClass().testScope(self, x, y, z, coeff)
end

function MountableObject:getUpdatePriority(skipCount, x, y, z, coeff, connection)
	if self.mountObject ~= nil then
		return self.mountObject:getUpdatePriority(skipCount, x, y, z, coeff, connection)
	end

	if self.dynamicMountObject ~= nil then
		return self.dynamicMountObject:getUpdatePriority(skipCount, x, y, z, coeff, connection)
	end

	return MountableObject:superClass().getUpdatePriority(self, skipCount, x, y, z, coeff, connection)
end

function MountableObject:updateTick(dt)
	if self.isServer and self:updateMove() then
		self.lastMoveTime = g_currentMission.time
	end
end

function MountableObject:mount(object, node, x, y, z, rx, ry, rz)
	if self.dynamicMountType == MountableObject.MOUNT_TYPE_DYNAMIC then
		self:unmountDynamic()
	elseif self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
		self:unmountKinematic()
	end

	self:unmountDynamic(true)

	if self.mountObject == nil then
		removeFromPhysics(self.nodeId)
	end

	link(node, self.nodeId)

	local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(rx, ry, rz)

	self:setLocalPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)

	self.mountObject = object
	self.dynamicMountType = MountableObject.MOUNT_TYPE_DEFAULT
end

function MountableObject:unmount()
	self.dynamicMountType = MountableObject.MOUNT_TYPE_NONE

	if self.mountObject ~= nil then
		self.mountObject = nil
		local x, y, z = getWorldTranslation(self.nodeId)
		local quatX, quatY, quatZ, quatW = getWorldQuaternion(self.nodeId)

		link(getRootNode(), self.nodeId)
		self:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)
		addToPhysics(self.nodeId)

		return true
	end

	return false
end

function MountableObject:mountKinematic(object, node, x, y, z, rx, ry, rz)
	if self.dynamicMountType == MountableObject.MOUNT_TYPE_DEFAULT then
		self:unmount()
	elseif self.dynamicMountType == MountableObject.MOUNT_TYPE_DYNAMIC then
		self:unmountDynamic()
	end

	self:unmountDynamic(true)
	removeFromPhysics(self.nodeId)
	link(node, self.nodeId)

	local quatX, quatY, quatZ, quatW = mathEulerToQuaternion(rx, ry, rz)

	self:setLocalPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)
	addToPhysics(self.nodeId)

	if self.isServer then
		setRigidBodyType(self.nodeId, RigidBodyType.KINEMATIC)
	end

	if object.components ~= nil then
		for i = 1, #object.components do
			if getRigidBodyType(object.components[i].node) == RigidBodyType.DYNAMIC then
				setPairCollision(object.components[i].node, self.nodeId, false)
			end
		end
	end

	self.mountObject = object
	self.mountJointNode = node
	self.dynamicMountType = MountableObject.MOUNT_TYPE_KINEMATIC
end

function MountableObject:unmountKinematic()
	self.dynamicMountType = MountableObject.MOUNT_TYPE_NONE

	if self.mountObject ~= nil then
		local components = self.mountObject.components
		self.mountObject = nil
		self.mountJointNode = nil
		local x, y, z = getWorldTranslation(self.nodeId)
		local quatX, quatY, quatZ, quatW = getWorldQuaternion(self.nodeId)

		removeFromPhysics(self.nodeId)
		link(getRootNode(), self.nodeId)
		self:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)
		addToPhysics(self.nodeId)

		if self.isServer then
			setRigidBodyType(self.nodeId, RigidBodyType.DYNAMIC)
		end

		if components ~= nil then
			for i = 1, #components do
				if getRigidBodyType(components[i].node) == RigidBodyType.DYNAMIC then
					setPairCollision(components[i].node, self.nodeId, true)
				end
			end
		end

		return true
	end

	return false
end

function MountableObject:mountDynamic(object, objectActorId, jointNode, mountType, forceAcceleration)
	assert(self.isServer)

	if self.dynamicMountType == MountableObject.MOUNT_TYPE_DEFAULT then
		self:unmount()
	elseif self.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
		self:unmountKinematic()
	end

	if not self:getSupportsMountDynamic() or self.mountObject ~= nil then
		return false
	end

	if object:getOwnerFarmId() ~= nil and not g_currentMission.accessHandler:canFarmAccess(object:getOwnerFarmId(), self) then
		return false
	end

	if self.dynamicMountTriggerId ~= nil then
		local x, y, z = nil

		if mountType == DynamicMountUtil.TYPE_FORK then
			local _, _, zOffset = worldToLocal(jointNode, localToWorld(self.nodeId, getCenterOfMass(self.nodeId)))
			x, y, z = localToLocal(jointNode, getParent(self.dynamicMountJointNodeDynamic), 0, 0, zOffset)
		else
			x, y, z = localToLocal(jointNode, getParent(self.dynamicMountJointNodeDynamic), 0, 0, 0)
		end

		setTranslation(self.dynamicMountJointNodeDynamic, x, y, z)
		setRotation(self.dynamicMountJointNodeDynamic, localRotationToLocal(jointNode, getParent(self.dynamicMountJointNodeDynamic), 0, 0, 0))
	end

	if DynamicMountUtil.mountDynamic(self, self.nodeId, object, objectActorId, jointNode, mountType, forceAcceleration * self.dynamicMountForceLimitScale, self.dynamicMountJointNodeDynamic) then
		self.dynamicMountType = MountableObject.MOUNT_TYPE_DYNAMIC

		return true
	end

	return false
end

function MountableObject:unmountDynamic(isDelete)
	DynamicMountUtil.unmountDynamic(self, isDelete)

	self.dynamicMountType = MountableObject.MOUNT_TYPE_NONE

	if self.isServer then
		self.lastMoveTime = g_currentMission.time
	end
end

function MountableObject:getSupportsMountDynamic()
	return true
end

function MountableObject:setNodeId(nodeId)
	MountableObject:superClass().setNodeId(self, nodeId)

	if self.isServer then
		local triggerId = I3DUtil.indexToObject(nodeId, getUserAttribute(nodeId, "dynamicMountTriggerIndex"))

		if triggerId ~= nil then
			local forceAcceleration = tonumber(getUserAttribute(nodeId, "dynamicMountTriggerForceAcceleration"))
			local forceLimitScale = tonumber(getUserAttribute(nodeId, "dynamicMountForceLimitScale"))
			local axisFreeY = getUserAttribute(nodeId, "dynamicMountSingleAxisFreeY") == true
			local axisFreeX = getUserAttribute(nodeId, "dynamicMountSingleAxisFreeX") == true

			self:setMountableObjectAttributes(triggerId, forceAcceleration, forceLimitScale, axisFreeY, axisFreeX)
		end

		if self.dynamicMountJointNodeDynamic == nil then
			self.dynamicMountJointNodeDynamic = createTransformGroup("dynamicMountJointNodeDynamic")

			link(self.nodeId, self.dynamicMountJointNodeDynamic)
		end
	end
end

function MountableObject:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	if not self.isServer then
		if self.dynamicMountType ~= MountableObject.MOUNT_TYPE_KINEMATIC and self.dynamicMountType ~= MountableObject.MOUNT_TYPE_DEFAULT then
			MountableObject:superClass().setWorldPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
		end
	else
		MountableObject:superClass().setWorldPositionQuaternion(self, x, y, z, quatX, quatY, quatZ, quatW, changeInterp)
	end
end

function MountableObject:setMountableObjectAttributes(triggerId, forceAcceleration, forceLimitScale, axisFreeY, axisFreeX)
	if self.isServer then
		self.dynamicMountTriggerId = triggerId

		if self.dynamicMountTriggerId ~= nil then
			addTrigger(self.dynamicMountTriggerId, "dynamicMountTriggerCallback", self)
		end

		self.dynamicMountTriggerForceAcceleration = forceAcceleration or 4
		self.dynamicMountForceLimitScale = forceLimitScale or 1
		self.dynamicMountSingleAxisFreeY = axisFreeY
		self.dynamicMountSingleAxisFreeX = axisFreeX
	end
end

function MountableObject:dynamicMountTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local vehicle = g_currentMission.nodeToObject[otherActorId]

	if vehicle ~= nil and vehicle:isa(Vehicle) then
		otherActorId = vehicle.components[1].node
	end

	if onEnter then
		if self.mountObject == nil then
			local dynamicMountAttacher = nil
			local dynamicMountType = DynamicMountUtil.TYPE_FORK
			local forceLimit = 1

			if vehicle ~= nil and vehicle.spec_dynamicMountAttacher ~= nil then
				dynamicMountAttacher = vehicle.spec_dynamicMountAttacher
				dynamicMountType, forceLimit = vehicle:getDynamicMountAttacherSettingsByNode(otherShapeId)
			end

			if dynamicMountAttacher ~= nil then
				if self.dynamicMountObjectActorId == nil then
					self:mountDynamic(vehicle, otherActorId, dynamicMountAttacher.dynamicMountAttacherNode, dynamicMountType, self.dynamicMountTriggerForceAcceleration * forceLimit)

					self.dynamicMountObjectTriggerCount = 1
				elseif otherActorId ~= self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount == nil then
					self:unmountDynamic()
					self:mountDynamic(vehicle, otherActorId, dynamicMountAttacher.dynamicMountAttacherNode, dynamicMountType, self.dynamicMountTriggerForceAcceleration * forceLimit)

					self.dynamicMountObjectTriggerCount = 1
				elseif otherActorId == self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount ~= nil then
					self.dynamicMountObjectTriggerCount = self.dynamicMountObjectTriggerCount + 1
				end
			end
		end
	elseif onLeave and otherActorId == self.dynamicMountObjectActorId and self.dynamicMountObjectTriggerCount ~= nil then
		self.dynamicMountObjectTriggerCount = self.dynamicMountObjectTriggerCount - 1

		if self.dynamicMountObjectTriggerCount == 0 then
			self:unmountDynamic()

			self.dynamicMountObjectTriggerCount = nil
		end
	end
end

function MountableObject:onDynamicMountJointBreak(jointIndex, breakingImpulse)
	if jointIndex == self.dynamicMountJointIndex then
		self:unmountDynamic()
	end

	return false
end

function MountableObject:getMeshNodes()
	return nil
end
