DynamicMountAttacher = {
	DYNAMIC_MOUNT_GRAB_XML_PATH = "vehicle.dynamicMountAttacher.grab",
	prerequisitesPresent = function (specializations)
		return true
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("DynamicMountAttacher")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher#node", "Attacher node")
		schema:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher#forceLimitScale", "Force limit", 1)
		schema:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher#timeToMount", "No movement time until mounting", 1000)
		schema:register(XMLValueType.INT, "vehicle.dynamicMountAttacher#numObjectBits", "Number of object bits to sync", 5)
		schema:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.grab#openMountType", "Open mount type", "TYPE_FORK")
		schema:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.grab#closedMountType", "Closed mount type", "TYPE_AUTO_ATTACH_XYZ")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher.mountCollisionMask(?)#node", "Collision node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher.mountCollisionMask(?)#triggerNode", "Trigger node")
		schema:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.mountCollisionMask(?)#mountType", "Mount type name", "FORK")
		schema:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher.mountCollisionMask(?)#forceLimitScale", "Force limit", 1)
		schema:register(XMLValueType.INT, "vehicle.dynamicMountAttacher.mountCollisionMask(?)#collisionMask", "Collision mask while object mounted")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher#triggerNode", "Trigger node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher#rootNode", "Root node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher#jointNode", "Joint node")
		schema:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher#forceAcceleration", "Force acceleration", 30)
		schema:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher#mountType", "Mount type", "TYPE_AUTO_ATTACH_XZ")
		schema:register(XMLValueType.BOOL, "vehicle.dynamicMountAttacher#transferMass", "If this is set to 'true' the mass of the object to mount is tranfered to our own component. This improves phyiscs stability", false)
		schema:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.lockPosition(?)#xmlFilename", "XML filename of vehicle to lock (needs to match only the end of the filename)")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.dynamicMountAttacher.lockPosition(?)#jointNode", "Joint node (Representens the position of the other vehicles root node)")
		ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.dynamicMountAttacher.lockPosition(?)")
		schema:register(XMLValueType.STRING, "vehicle.dynamicMountAttacher.animation#name", "Animation name")
		schema:register(XMLValueType.FLOAT, "vehicle.dynamicMountAttacher.animation#speed", "Animation speed", 1)
		schema:register(XMLValueType.BOOL, Cylindered.MOVING_TOOL_XML_KEY .. ".dynamicMountAttacher#value", "Update dynamic mount attacher joints")
		schema:register(XMLValueType.BOOL, Cylindered.MOVING_PART_XML_KEY .. ".dynamicMountAttacher#value", "Update dynamic mount attacher joints")
		schema:setXMLSpecializationType()
	end
}

function DynamicMountAttacher.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "writeDynamicMountObjectsToStream", DynamicMountAttacher.writeDynamicMountObjectsToStream)
	SpecializationUtil.registerFunction(vehicleType, "readDynamicMountObjectsFromStream", DynamicMountAttacher.readDynamicMountObjectsFromStream)
	SpecializationUtil.registerFunction(vehicleType, "getAllowDynamicMountObjects", DynamicMountAttacher.getAllowDynamicMountObjects)
	SpecializationUtil.registerFunction(vehicleType, "dynamicMountTriggerCallback", DynamicMountAttacher.dynamicMountTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "addDynamicMountedObject", DynamicMountAttacher.addDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "removeDynamicMountedObject", DynamicMountAttacher.removeDynamicMountedObject)
	SpecializationUtil.registerFunction(vehicleType, "setDynamicMountAnimationState", DynamicMountAttacher.setDynamicMountAnimationState)
	SpecializationUtil.registerFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", DynamicMountAttacher.getAllowDynamicMountFillLevelInfo)
	SpecializationUtil.registerFunction(vehicleType, "loadDynamicMountGrabFromXML", DynamicMountAttacher.loadDynamicMountGrabFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsDynamicMountGrabOpened", DynamicMountAttacher.getIsDynamicMountGrabOpened)
	SpecializationUtil.registerFunction(vehicleType, "getDynamicMountTimeToMount", DynamicMountAttacher.getDynamicMountTimeToMount)
	SpecializationUtil.registerFunction(vehicleType, "getHasDynamicMountedObjects", DynamicMountAttacher.getHasDynamicMountedObjects)
	SpecializationUtil.registerFunction(vehicleType, "forceDynamicMountPendingObjects", DynamicMountAttacher.forceDynamicMountPendingObjects)
	SpecializationUtil.registerFunction(vehicleType, "forceUnmountDynamicMountedObjects", DynamicMountAttacher.forceUnmountDynamicMountedObjects)
	SpecializationUtil.registerFunction(vehicleType, "getDynamicMountAttacherSettingsByNode", DynamicMountAttacher.getDynamicMountAttacherSettingsByNode)
end

function DynamicMountAttacher.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", DynamicMountAttacher.getFillLevelInformation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addNodeObjectMapping", DynamicMountAttacher.addNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeNodeObjectMapping", DynamicMountAttacher.removeNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", DynamicMountAttacher.loadExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", DynamicMountAttacher.updateExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttachedTo", DynamicMountAttacher.getIsAttachedTo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", DynamicMountAttacher.getAdditionalComponentMass)
end

function DynamicMountAttacher.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", DynamicMountAttacher)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", DynamicMountAttacher)
end

function DynamicMountAttacher:onLoad(savegame)
	local spec = self.spec_dynamicMountAttacher

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.dynamicMountAttacher#index", "vehicle.dynamicMountAttacher#node")

	spec.dynamicMountAttacherNode = self.xmlFile:getValue("vehicle.dynamicMountAttacher#node", nil, self.components, self.i3dMappings)
	spec.dynamicMountAttacherForceLimitScale = self.xmlFile:getValue("vehicle.dynamicMountAttacher#forceLimitScale", 1)
	spec.dynamicMountAttacherTimeToMount = self.xmlFile:getValue("vehicle.dynamicMountAttacher#timeToMount", 1000)
	spec.numObjectBits = self.xmlFile:getValue("vehicle.dynamicMountAttacher#numObjectBits", 5)
	spec.maxNumObjectsToSend = 2^spec.numObjectBits - 1
	local grabKey = "vehicle.dynamicMountAttacher.grab"

	if self.xmlFile:hasProperty(grabKey) then
		spec.dynamicMountAttacherGrab = {}

		self:loadDynamicMountGrabFromXML(self.xmlFile, grabKey, spec.dynamicMountAttacherGrab)
	end

	spec.pendingDynamicMountObjects = {}
	spec.dynamicMountCollisionMasks = {}
	spec.lockPositions = {}

	if self.isServer then
		self.xmlFile:iterate("vehicle.dynamicMountAttacher.mountCollisionMask", function (index, key)
			local mountCollision = {
				node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings),
				triggerNode = self.xmlFile:getValue(key .. "#triggerNode", nil, self.components, self.i3dMappings),
				mountedCollisionMask = self.xmlFile:getValue(key .. "#collisionMask")
			}

			if mountCollision.node ~= nil and mountCollision.mountedCollisionMask ~= nil then
				local mountTypeStr = self.xmlFile:getValue(key .. "#mountType", "FORK")
				mountCollision.mountType = DynamicMountUtil["TYPE_" .. mountTypeStr] or DynamicMountUtil.TYPE_FORK
				mountCollision.forceLimitScale = self.xmlFile:getValue(key .. "#forceLimitScale", spec.dynamicMountAttacherForceLimitScale)
				mountCollision.unmountedCollisionMask = getCollisionMask(mountCollision.node)

				table.insert(spec.dynamicMountCollisionMasks, mountCollision)
			else
				Logging.xmlWarning(self.xmlFile, "Missing node or collisionMask in '%s'", key)
			end
		end)

		local dynamicMountTrigger = {
			triggerNode = self.xmlFile:getValue("vehicle.dynamicMountAttacher#triggerNode", nil, self.components, self.i3dMappings),
			rootNode = self.xmlFile:getValue("vehicle.dynamicMountAttacher#rootNode", nil, self.components, self.i3dMappings),
			jointNode = self.xmlFile:getValue("vehicle.dynamicMountAttacher#jointNode", nil, self.components, self.i3dMappings)
		}

		if dynamicMountTrigger.triggerNode ~= nil and dynamicMountTrigger.rootNode ~= nil and dynamicMountTrigger.jointNode ~= nil then
			local collisionMask = getCollisionMask(dynamicMountTrigger.triggerNode)

			if collisionMask == CollisionMask.TRIGGER_DYNAMIC_MOUNT then
				addTrigger(dynamicMountTrigger.triggerNode, "dynamicMountTriggerCallback", self)

				dynamicMountTrigger.forceAcceleration = self.xmlFile:getValue("vehicle.dynamicMountAttacher#forceAcceleration", 30)
				local mountTypeString = self.xmlFile:getValue("vehicle.dynamicMountAttacher#mountType", "TYPE_AUTO_ATTACH_XZ")
				dynamicMountTrigger.mountType = Utils.getNoNil(DynamicMountUtil[mountTypeString], DynamicMountUtil.TYPE_AUTO_ATTACH_XZ)
				dynamicMountTrigger.currentMountType = dynamicMountTrigger.mountType
				dynamicMountTrigger.component = self:getParentComponent(dynamicMountTrigger.triggerNode)
				spec.dynamicMountAttacherTrigger = dynamicMountTrigger
			else
				Logging.xmlWarning(self.xmlFile, "Dynamic Mount trigger has invalid collision mask (should be %d)!", CollisionMask.TRIGGER_DYNAMIC_MOUNT)
			end
		end

		spec.transferMass = self.xmlFile:getValue("vehicle.dynamicMountAttacher#transferMass", false)

		self.xmlFile:iterate("vehicle.dynamicMountAttacher.lockPosition", function (index, key)
			local entry = {
				xmlFilename = self.xmlFile:getValue(key .. "#xmlFilename"),
				jointNode = self.xmlFile:getValue(key .. "#jointNode", nil, self.components, self.i3dMappings)
			}

			if entry.xmlFilename ~= nil and entry.jointNode ~= nil then
				entry.xmlFilename = entry.xmlFilename:gsub("$data", "data")
				entry.objectChanges = {}

				ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, key, entry.objectChanges, self.components, self)
				table.insert(spec.lockPositions, entry)
			else
				Logging.xmlWarning(self.xmlFile, "Invalid lock position '%s'. Missing xmlFilename or jointNode!", key)
			end
		end)
	end

	spec.animationName = self.xmlFile:getValue("vehicle.dynamicMountAttacher.animation#name")
	spec.animationSpeed = self.xmlFile:getValue("vehicle.dynamicMountAttacher.animation#speed", 1)

	if spec.animationName ~= nil then
		self:playAnimation(spec.animationName, spec.animationSpeed, self:getAnimationTime(spec.animationName), true)
	end

	spec.dynamicMountedObjects = {}
	spec.dynamicMountedObjectsDirtyFlag = self:getNextDirtyFlag()
end

function DynamicMountAttacher:onDelete()
	local spec = self.spec_dynamicMountAttacher

	if self.isServer and spec.dynamicMountedObjects ~= nil then
		for object, _ in pairs(spec.dynamicMountedObjects) do
			object:unmountDynamic()
		end
	end

	if spec.dynamicMountAttacherTrigger ~= nil then
		removeTrigger(spec.dynamicMountAttacherTrigger.triggerNode)
	end
end

function DynamicMountAttacher:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_dynamicMountAttacher

		if streamReadBool(streamId) then
			local sum = self:readDynamicMountObjectsFromStream(streamId, spec.dynamicMountedObjects)

			self:setDynamicMountAnimationState(sum > 0)
			self:readDynamicMountObjectsFromStream(streamId, spec.pendingDynamicMountObjects)
		end
	end
end

function DynamicMountAttacher:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_dynamicMountAttacher

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dynamicMountedObjectsDirtyFlag) ~= 0) then
			self:writeDynamicMountObjectsToStream(streamId, spec.dynamicMountedObjects)
			self:writeDynamicMountObjectsToStream(streamId, spec.pendingDynamicMountObjects)
		end
	end
end

function DynamicMountAttacher:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local spec = self.spec_dynamicMountAttacher

		if self:getAllowDynamicMountObjects() then
			for object, _ in pairs(spec.pendingDynamicMountObjects) do
				self:raiseActive()

				if spec.dynamicMountedObjects[object] == nil and object.lastMoveTime + self:getDynamicMountTimeToMount() < g_currentMission.time then
					local doAttach = false
					local objectRoot = nil

					if object.components ~= nil then
						if object.getCanByMounted ~= nil then
							doAttach = object:getCanByMounted()
						elseif entityExists(object.components[1].node) then
							doAttach = true
						end

						objectRoot = object.components[1].node
					end

					if object.nodeId ~= nil then
						if object.getCanByMounted ~= nil then
							doAttach = object:getCanByMounted()
						elseif entityExists(object.nodeId) then
							doAttach = true
						end

						objectRoot = object.nodeId
					end

					if doAttach then
						local trigger = spec.dynamicMountAttacherTrigger
						local objectJoint = createTransformGroup("dynamicMountObjectJoint")

						link(trigger.jointNode, objectJoint)
						setWorldTranslation(objectJoint, getWorldTranslation(objectRoot))

						local couldMount = object:mountDynamic(self, trigger.rootNode, objectJoint, trigger.mountType, trigger.forceAcceleration)

						if couldMount then
							object.additionalDynamicMountJointNode = objectJoint

							self:addDynamicMountedObject(object)
						else
							delete(objectJoint)
						end
					else
						spec.pendingDynamicMountObjects[object] = nil

						self:raiseDirtyFlags(spec.dynamicMountedObjectsDirtyFlag)
					end
				end
			end
		else
			for object, _ in pairs(spec.dynamicMountedObjects) do
				self:removeDynamicMountedObject(object, false)
				object:unmountDynamic()

				if object.additionalDynamicMountJointNode ~= nil then
					delete(object.additionalDynamicMountJointNode)

					object.additionalDynamicMountJointNode = nil
				end
			end
		end

		if spec.dynamicMountAttacherGrab ~= nil then
			for object, _ in pairs(spec.dynamicMountedObjects) do
				local usedMountType = spec.dynamicMountAttacherGrab.closedMountType

				if self:getIsDynamicMountGrabOpened(spec.dynamicMountAttacherGrab) then
					usedMountType = spec.dynamicMountAttacherGrab.openMountType
				end

				if spec.dynamicMountAttacherGrab.currentMountType ~= usedMountType then
					spec.dynamicMountAttacherGrab.currentMountType = usedMountType
					local x, y, z = getWorldTranslation(spec.dynamicMountAttacherNode)

					setJointPosition(object.dynamicMountJointIndex, 1, x, y, z)

					if usedMountType == DynamicMountUtil.TYPE_FORK then
						setJointRotationLimit(object.dynamicMountJointIndex, 0, true, 0, 0)
						setJointRotationLimit(object.dynamicMountJointIndex, 1, true, 0, 0)
						setJointRotationLimit(object.dynamicMountJointIndex, 2, true, 0, 0)

						if object.dynamicMountSingleAxisFreeX then
							setJointTranslationLimit(object.dynamicMountJointIndex, 0, false, 0, 0)
						else
							setJointTranslationLimit(object.dynamicMountJointIndex, 0, true, -0.01, 0.01)
						end

						if object.dynamicMountSingleAxisFreeY then
							setJointTranslationLimit(object.dynamicMountJointIndex, 1, false, 0, 0)
						else
							setJointTranslationLimit(object.dynamicMountJointIndex, 1, true, -0.01, 0.01)
						end

						setJointTranslationLimit(object.dynamicMountJointIndex, 2, false, 0, 0)
					else
						setJointRotationLimit(object.dynamicMountJointIndex, 0, true, 0, 0)
						setJointRotationLimit(object.dynamicMountJointIndex, 1, true, 0, 0)
						setJointRotationLimit(object.dynamicMountJointIndex, 2, true, 0, 0)

						if usedMountType == DynamicMountUtil.TYPE_AUTO_ATTACH_XYZ or usedMountType == DynamicMountUtil.TYPE_FIX_ATTACH then
							setJointTranslationLimit(object.dynamicMountJointIndex, 0, true, -0.01, 0.01)
							setJointTranslationLimit(object.dynamicMountJointIndex, 1, true, -0.01, 0.01)
							setJointTranslationLimit(object.dynamicMountJointIndex, 2, true, -0.01, 0.01)
						elseif usedMountType == DynamicMountUtil.TYPE_AUTO_ATTACH_XZ then
							setJointTranslationLimit(object.dynamicMountJointIndex, 0, true, -0.01, 0.01)
							setJointTranslationLimit(object.dynamicMountJointIndex, 1, false, 0, 0)
							setJointTranslationLimit(object.dynamicMountJointIndex, 2, true, -0.01, 0.01)
						elseif usedMountType == DynamicMountUtil.TYPE_AUTO_ATTACH_Y then
							setJointTranslationLimit(object.dynamicMountJointIndex, 0, false, 0, 0)
							setJointTranslationLimit(object.dynamicMountJointIndex, 1, true, -0.01, 0.01)
							setJointTranslationLimit(object.dynamicMountJointIndex, 2, false, 0, 0)
						end
					end
				end
			end
		end
	end
end

function DynamicMountAttacher:addDynamicMountedObject(object)
	local spec = self.spec_dynamicMountAttacher

	if spec.dynamicMountedObjects[object] == nil then
		spec.dynamicMountedObjects[object] = object

		for i = 1, #spec.lockPositions do
			local position = spec.lockPositions[i]

			if string.endsWith(object.configFileName, position.xmlFilename) then
				DynamicMountUtil.unmountDynamic(object, false)

				local x, y, z = getWorldTranslation(position.jointNode)
				local rx, ry, rz = getWorldRotation(position.jointNode)

				object:removeFromPhysics()

				spec.pendingDynamicMountObjects[object] = nil

				object:setWorldPosition(x, y, z, rx, ry, rz, 1, true)
				object:addToPhysics()

				local trigger = spec.dynamicMountAttacherTrigger
				local couldMount = object:mountDynamic(self, trigger.rootNode, trigger.jointNode, trigger.mountType, trigger.forceAcceleration)

				if not couldMount then
					self:removeDynamicMountedObject(object, false)
				end

				ObjectChangeUtil.setObjectChanges(position.objectChanges, true, self, self.setMovingToolDirty)
			end
		end

		for _, info in pairs(spec.dynamicMountCollisionMasks) do
			setCollisionMask(info.node, info.mountedCollisionMask)
		end

		if spec.transferMass and object.setReducedComponentMass ~= nil then
			object:setReducedComponentMass(true)
			self:setMassDirty()
		end

		self:setDynamicMountAnimationState(true)
		self:raiseDirtyFlags(spec.dynamicMountedObjectsDirtyFlag)
	end
end

function DynamicMountAttacher:removeDynamicMountedObject(object, isDeleting)
	local spec = self.spec_dynamicMountAttacher
	spec.dynamicMountedObjects[object] = nil

	if isDeleting then
		spec.pendingDynamicMountObjects[object] = nil
	end

	for i = 1, #spec.lockPositions do
		ObjectChangeUtil.setObjectChanges(spec.lockPositions[i].objectChanges, false, self, self.setMovingToolDirty)
	end

	if next(spec.dynamicMountedObjects) == nil and next(spec.pendingDynamicMountObjects) == nil then
		for _, info in pairs(spec.dynamicMountCollisionMasks) do
			setCollisionMask(info.node, info.unmountedCollisionMask)
		end
	end

	if spec.transferMass then
		self:setMassDirty()
	end

	self:setDynamicMountAnimationState(false)
	self:raiseDirtyFlags(spec.dynamicMountedObjectsDirtyFlag)
end

function DynamicMountAttacher:setDynamicMountAnimationState(state)
	local spec = self.spec_dynamicMountAttacher

	if state then
		self:playAnimation(spec.animationName, spec.animationSpeed, self:getAnimationTime(spec.animationName), true)
	else
		self:playAnimation(spec.animationName, -spec.animationSpeed, self:getAnimationTime(spec.animationName), true)
	end
end

function DynamicMountAttacher:writeDynamicMountObjectsToStream(streamId, objects)
	local spec = self.spec_dynamicMountAttacher
	local num = math.min(table.size(objects), spec.maxNumObjectsToSend)

	streamWriteUIntN(streamId, num, spec.numObjectBits)

	local objectIndex = 0

	for object, _ in pairs(objects) do
		objectIndex = objectIndex + 1

		if num >= objectIndex then
			NetworkUtil.writeNodeObject(streamId, object)
		else
			Logging.xmlWarning(self.xmlFile, "Not enough bits to send all mounted objects. Please increase '%s'", "vehicle.dynamicMountAttacher#numObjectBits")
		end
	end
end

function DynamicMountAttacher:readDynamicMountObjectsFromStream(streamId, objects)
	local spec = self.spec_dynamicMountAttacher
	local sum = streamReadUIntN(streamId, spec.numObjectBits)

	for k, _ in pairs(objects) do
		objects[k] = nil
	end

	for _ = 1, sum do
		local object = NetworkUtil.readNodeObject(streamId)

		if object ~= nil then
			objects[object] = object
		end
	end

	return sum
end

function DynamicMountAttacher:getAllowDynamicMountObjects()
	return true
end

function DynamicMountAttacher:dynamicMountTriggerCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_dynamicMountAttacher

	if getRigidBodyType(otherActorId) == RigidBodyType.DYNAMIC and not getHasTrigger(otherActorId) then
		if onEnter then
			local object = g_currentMission:getNodeObject(otherActorId)

			if object == nil then
				object = g_currentMission.nodeToObject[otherActorId]
			end

			if object == self.rootVehicle or self.spec_attachable ~= nil and self.spec_attachable.attacherVehicle == object then
				object = nil
			end

			if object ~= nil and object ~= self then
				local isObject = object.getSupportsMountDynamic ~= nil and object:getSupportsMountDynamic() and object.lastMoveTime ~= nil
				local isVehicle = object.getSupportsTensionBelts ~= nil and object:getSupportsTensionBelts() and object.lastMoveTime ~= nil

				if isObject or isVehicle then
					spec.pendingDynamicMountObjects[object] = Utils.getNoNil(spec.pendingDynamicMountObjects[object], 0) + 1

					if spec.pendingDynamicMountObjects[object] == 1 then
						self:raiseDirtyFlags(spec.dynamicMountedObjectsDirtyFlag)
					end
				end
			end
		elseif onLeave then
			local object = g_currentMission:getNodeObject(otherActorId)

			if object == nil then
				object = g_currentMission.nodeToObject[otherActorId]
			end

			if object ~= nil and spec.pendingDynamicMountObjects[object] ~= nil then
				local count = spec.pendingDynamicMountObjects[object] - 1

				if count == 0 then
					spec.pendingDynamicMountObjects[object] = nil

					if spec.dynamicMountedObjects[object] ~= nil then
						self:removeDynamicMountedObject(object, false)
						object:unmountDynamic()

						if object.additionalDynamicMountJointNode ~= nil then
							delete(object.additionalDynamicMountJointNode)

							object.additionalDynamicMountJointNode = nil
						end
					end

					self:raiseDirtyFlags(spec.dynamicMountedObjectsDirtyFlag)
				else
					spec.pendingDynamicMountObjects[object] = count
				end
			end
		end
	end
end

function DynamicMountAttacher:getAllowDynamicMountFillLevelInfo()
	return true
end

function DynamicMountAttacher:loadDynamicMountGrabFromXML(xmlFile, key, entry)
	local openMountType = self.xmlFile:getValue(key .. "#openMountType")
	entry.openMountType = Utils.getNoNil(DynamicMountUtil[openMountType], DynamicMountUtil.TYPE_FORK)
	local closedMountType = self.xmlFile:getValue(key .. "#closedMountType")
	entry.closedMountType = Utils.getNoNil(DynamicMountUtil[closedMountType], DynamicMountUtil.TYPE_AUTO_ATTACH_XYZ)
	entry.currentMountType = entry.openMountType

	return true
end

function DynamicMountAttacher:getIsDynamicMountGrabOpened(grab)
	return true
end

function DynamicMountAttacher:getDynamicMountTimeToMount()
	return self.spec_dynamicMountAttacher.dynamicMountAttacherTimeToMount
end

function DynamicMountAttacher:getHasDynamicMountedObjects()
	return next(self.spec_dynamicMountAttacher.dynamicMountedObjects) ~= nil
end

function DynamicMountAttacher:forceDynamicMountPendingObjects(onlyBales)
	if self:getAllowDynamicMountObjects() then
		local spec = self.spec_dynamicMountAttacher

		for object, _ in pairs(spec.pendingDynamicMountObjects) do
			if spec.dynamicMountedObjects[object] == nil and (not onlyBales or object:isa(Bale)) then
				local trigger = spec.dynamicMountAttacherTrigger
				local couldMount = object:mountDynamic(self, trigger.rootNode, trigger.jointNode, trigger.mountType, trigger.forceAcceleration)

				if couldMount then
					self:addDynamicMountedObject(object)
				end
			end
		end
	end
end

function DynamicMountAttacher:forceUnmountDynamicMountedObjects()
	local spec = self.spec_dynamicMountAttacher

	for object, _ in pairs(spec.dynamicMountedObjects) do
		self:removeDynamicMountedObject(object, false)
		object:unmountDynamic()

		if object.additionalDynamicMountJointNode ~= nil then
			delete(object.additionalDynamicMountJointNode)

			object.additionalDynamicMountJointNode = nil
		end
	end
end

function DynamicMountAttacher:getDynamicMountAttacherSettingsByNode(node)
	local spec = self.spec_dynamicMountAttacher

	for i = 1, #spec.dynamicMountCollisionMasks do
		local mountCollision = spec.dynamicMountCollisionMasks[i]

		if mountCollision.triggerNode == node then
			return mountCollision.mountType, mountCollision.forceLimitScale
		end
	end

	return DynamicMountUtil.TYPE_FORK, 1
end

function DynamicMountAttacher:getFillLevelInformation(superFunc, display)
	superFunc(self, display)

	if self:getAllowDynamicMountFillLevelInfo() then
		local spec = self.spec_dynamicMountAttacher

		for object, _ in pairs(spec.dynamicMountedObjects) do
			if object.getFillLevelInformation ~= nil then
				object:getFillLevelInformation(display)
			elseif object.getFillLevel ~= nil and object.getFillType ~= nil then
				local fillType = object:getFillType()
				local fillLevel = object:getFillLevel()
				local capacity = fillLevel

				if object.getCapacity ~= nil then
					capacity = object:getCapacity()
				end

				display:addFillLevel(fillType, fillLevel, capacity)
			end
		end
	end
end

function DynamicMountAttacher:addNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_dynamicMountAttacher

	if spec.dynamicMountAttacherTrigger ~= nil and spec.dynamicMountAttacherTrigger.triggerNode ~= nil then
		list[spec.dynamicMountAttacherTrigger.triggerNode] = self
	end
end

function DynamicMountAttacher:removeNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_dynamicMountAttacher

	if spec.dynamicMountAttacherTrigger ~= nil and spec.dynamicMountAttacherTrigger.triggerNode ~= nil then
		list[spec.dynamicMountAttacherTrigger.triggerNode] = nil
	end
end

function DynamicMountAttacher:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
	if not superFunc(self, xmlFile, baseName, entry) then
		return false
	end

	entry.updateDynamicMountAttacher = xmlFile:getValue(baseName .. ".dynamicMountAttacher#value")

	return true
end

function DynamicMountAttacher:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)

	if self.isServer and part.updateDynamicMountAttacher ~= nil and part.updateDynamicMountAttacher then
		local spec = self.spec_dynamicMountAttacher

		for object, _ in pairs(spec.dynamicMountedObjects) do
			setJointFrame(object.dynamicMountJointIndex, 0, object.dynamicMountJointNode)
		end
	end
end

function DynamicMountAttacher:getIsAttachedTo(superFunc, vehicle)
	if superFunc(self, vehicle) then
		return true
	end

	local spec = self.spec_dynamicMountAttacher

	for object, _ in pairs(spec.dynamicMountedObjects) do
		if object == vehicle then
			return true
		end
	end

	for object, _ in pairs(spec.pendingDynamicMountObjects) do
		if object == vehicle then
			return true
		end
	end

	return false
end

function DynamicMountAttacher:getAdditionalComponentMass(superFunc, component)
	local additionalMass = superFunc(self, component)
	local spec = self.spec_dynamicMountAttacher

	if spec.transferMass and spec.dynamicMountAttacherTrigger.component == component.node then
		for object, _ in pairs(spec.dynamicMountedObjects) do
			if object.getAllowComponentMassReduction ~= nil and object:getAllowComponentMassReduction() then
				additionalMass = additionalMass + object:getDefaultMass() - 0.1
			end
		end
	end

	return additionalMass
end

function DynamicMountAttacher:onPreAttachImplement(object, inputJointDescIndex, jointDescIndex)
	local objSpec = object.spec_dynamicMountAttacher

	if objSpec ~= nil and self.isServer then
		objSpec.pendingDynamicMountObjects[self] = nil

		if objSpec.dynamicMountedObjects[self] ~= nil then
			object:removeDynamicMountedObject(self, false)
			self:unmountDynamic()

			if object.additionalDynamicMountJointNode ~= nil then
				delete(object.additionalDynamicMountJointNode)

				object.additionalDynamicMountJointNode = nil
			end
		end
	end
end

function DynamicMountAttacher:updateDebugValues(values)
	local spec = self.spec_dynamicMountAttacher

	if self.isServer then
		local timeToMount = self.lastMoveTime + spec.dynamicMountAttacherTimeToMount - g_currentMission.time

		table.insert(values, {
			name = "timeToMount:",
			value = string.format("%d", timeToMount)
		})

		for object, _ in pairs(spec.pendingDynamicMountObjects) do
			table.insert(values, {
				name = "pendingDynamicMountObject:",
				value = string.format("%s timeToMount: %d", object.configFileName or object, math.max(object.lastMoveTime + spec.dynamicMountAttacherTimeToMount - g_currentMission.time, 0))
			})
		end

		for object, _ in pairs(spec.dynamicMountedObjects) do
			table.insert(values, {
				name = "dynamicMountedObjects:",
				value = string.format("%s", object.configFileName or object)
			})
		end
	end

	table.insert(values, {
		name = "allowMountObjects:",
		value = string.format("%s", self:getAllowDynamicMountObjects())
	})

	if spec.dynamicMountAttacherGrab ~= nil then
		table.insert(values, {
			name = "grabOpened:",
			value = string.format("%s", self:getIsDynamicMountGrabOpened(spec.dynamicMountAttacherGrab))
		})
	end
end
