SmartAttach = {
	DISTANCE_THRESHOLD = 3.5,
	ABS_ANGLE_THRESHOLD = math.rad(20),
	prerequisitesPresent = function (specializations)
		return true
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("SmartAttach")
		schema:register(XMLValueType.STRING, "vehicle.smartAttach#jointType", "Joint type name")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.smartAttach#trigger", "Trigger node")
		schema:setXMLSpecializationType()
	end
}

function SmartAttach.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "smartAttachCallback", SmartAttach.smartAttachCallback)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeSmartAttached", SmartAttach.getCanBeSmartAttached)
	SpecializationUtil.registerFunction(vehicleType, "doSmartAttach", SmartAttach.doSmartAttach)
end

function SmartAttach.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SmartAttach)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", SmartAttach)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", SmartAttach)
end

function SmartAttach:onLoad(savegame)
	local spec = self.spec_smartAttach
	spec.inputJointDescIndex = nil
	local jointTypeStr = self.xmlFile:getValue("vehicle.smartAttach#jointType")

	if jointTypeStr ~= nil then
		local jointType = AttacherJoints.jointTypeNameToInt[jointTypeStr]

		if jointType ~= nil then
			for inputJointDescIndex, inputAttacherJoint in pairs(self:getInputAttacherJoints()) do
				if inputAttacherJoint.jointType == jointType then
					spec.inputJointDescIndex = inputJointDescIndex

					break
				end
			end

			spec.jointType = jointType

			if spec.inputJointDescIndex == nil then
				print("Warning: SmartAttach jointType not defined in '" .. self.configFileName .. "'!")
			end
		else
			print("Warning: invalid jointType " .. jointTypeStr)
		end
	end

	local triggerNode = self.xmlFile:getValue("vehicle.smartAttach#trigger", nil, self.components, self.i3dMappings)

	if triggerNode ~= nil then
		spec.trigger = triggerNode

		addTrigger(spec.trigger, "smartAttachCallback", self)
	end

	spec.targetVehicle = nil
	spec.targetVehicleCount = 0
	spec.jointDescIndex = nil
	spec.activatable = SmartAttachActivatable.new(self)
end

function SmartAttach:onDelete()
	local spec = self.spec_smartAttach

	if spec.activatable ~= nil then
		g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)

		spec.activatable = nil
	end

	if spec.trigger ~= nil then
		removeTrigger(spec.trigger)

		spec.trigger = nil
	end
end

function SmartAttach:doSmartAttach(targetVehicle, inputJointDescIndex, jointDescIndex, noEventSend)
	SmartAttachEvent.sendEvent(self, targetVehicle, inputJointDescIndex, jointDescIndex, noEventSend)

	if self.isServer then
		local attacherVehicle = self:getAttacherVehicle()

		if attacherVehicle ~= nil then
			attacherVehicle:detachImplementByObject(self)
		end

		targetVehicle:attachImplement(self, inputJointDescIndex, jointDescIndex, false)
	end
end

function SmartAttach:getCanBeSmartAttached()
	local spec = self.spec_smartAttach
	local targetVehicle = spec.targetVehicle

	if targetVehicle == nil then
		return false
	end

	local activeForInput = self:getIsActiveForInput(true) or spec.targetVehicle:getIsActiveForInput(true)

	if not activeForInput then
		return false
	end

	local attacherJoint = targetVehicle:getAttacherJoints()[spec.jointDescIndex].jointTransform
	local inputAttacherJoint = self:getInputAttacherJoints()[spec.inputJointDescIndex].node
	local x1, _, z1 = getWorldTranslation(attacherJoint)
	local x2, _, z2 = getWorldTranslation(inputAttacherJoint)
	local distance = MathUtil.vector2Length(x1 - x2, z1 - z2)
	local yRot = Utils.getYRotationBetweenNodes(attacherJoint, inputAttacherJoint)

	return distance < SmartAttach.DISTANCE_THRESHOLD and math.abs(yRot) < SmartAttach.ABS_ANGLE_THRESHOLD
end

function SmartAttach:onPreAttach()
	local spec = self.spec_smartAttach
	spec.targetVehicle = nil
	spec.targetVehicleCount = 0
end

function SmartAttach:smartAttachCallback(triggerId, otherActorId, onEnter, onLeave, onStay, otherShapeId)
	local spec = self.spec_smartAttach

	if onEnter then
		local vehicle = g_currentMission.nodeToObject[otherActorId]

		if vehicle ~= nil then
			if spec.targetVehicle == nil and vehicle ~= nil and vehicle ~= self and vehicle.getAttacherJoints ~= nil then
				for i, jointDesc in ipairs(vehicle:getAttacherJoints()) do
					if jointDesc.jointIndex == 0 and jointDesc.jointType == spec.jointType then
						spec.targetVehicle = vehicle
						spec.jointDescIndex = i
						spec.targetVehicleCount = 0
						local name = Utils.getNoNil(self.typeDesc, "")
						local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName:lower())

						if storeItem ~= nil then
							name = storeItem.name
						end

						if self:getAttacherVehicle() == nil then
							spec.activatable.activateText = string.format(g_i18n:getText("action_doSmartAttachGround", self.customEnvironment), name)
						else
							spec.activatable.activateText = string.format(g_i18n:getText("action_doSmartAttachTransform", self.customEnvironment), name)
						end

						g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)

						break
					end
				end
			end

			if vehicle == spec.targetVehicle then
				spec.targetVehicleCount = spec.targetVehicleCount + 1
			end
		end
	elseif onLeave and spec.targetVehicle ~= nil then
		local object = g_currentMission.nodeToObject[otherActorId]

		if object ~= nil and object == spec.targetVehicle then
			spec.targetVehicleCount = spec.targetVehicleCount - 1

			if spec.targetVehicleCount <= 0 then
				spec.targetVehicle = nil

				g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)

				spec.targetVehicleCount = 0
			end
		end
	end
end

SmartAttachActivatable = {}
local SmartAttachActivatable_mt = Class(SmartAttachActivatable)

function SmartAttachActivatable.new(smartAttachVehicle)
	local self = {}

	setmetatable(self, SmartAttachActivatable_mt)

	self.smartAttachVehicle = smartAttachVehicle
	self.activateText = ""

	return self
end

function SmartAttachActivatable:getIsActivatable()
	return self.smartAttachVehicle:getCanBeSmartAttached()
end

function SmartAttachActivatable:run()
	local vehicle = self.smartAttachVehicle
	local spec = vehicle.spec_smartAttach

	vehicle:doSmartAttach(spec.targetVehicle, spec.inputJointDescIndex, spec.jointDescIndex)
end

SmartAttachEvent = {}
local SmartAttachEvent_mt = Class(SmartAttachEvent, Event)

InitEventClass(SmartAttachEvent, "SmartAttachEvent")

function SmartAttachEvent.emptyNew()
	local self = Event.new(SmartAttachEvent_mt)

	return self
end

function SmartAttachEvent.new(vehicle, targetVehicle, inputJointDescIndex, jointDescIndex)
	local self = SmartAttachEvent.emptyNew()
	self.vehicle = vehicle
	self.targetVehicle = targetVehicle
	self.inputJointDescIndex = inputJointDescIndex
	self.jointDescIndex = jointDescIndex

	return self
end

function SmartAttachEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.targetVehicle = NetworkUtil.readNodeObject(streamId)
	self.inputJointDescIndex = streamReadUIntN(streamId, 7)
	self.jointDescIndex = streamReadUIntN(streamId, 7)

	self:run(connection)
end

function SmartAttachEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	NetworkUtil.writeNodeObject(streamId, self.targetVehicle)
	streamWriteUIntN(streamId, self.inputJointDescIndex, 7)
	streamWriteUIntN(streamId, self.jointDescIndex, 7)
end

function SmartAttachEvent:run(connection)
	self.vehicle:doSmartAttach(self.targetVehicle, self.inputJointDescIndex, self.jointDescIndex, true)

	if not connection:getIsServer() then
		g_server:broadcastEvent(SmartAttachEvent.new(self.vehicle, self.targetVehicle, self.inputJointDescIndex, self.jointDescIndex), nil, connection, self.vehicle)
	end
end

function SmartAttachEvent.sendEvent(vehicle, targetVehicle, inputJointDescIndex, jointDescIndex, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SmartAttachEvent.new(vehicle, targetVehicle, inputJointDescIndex, jointDescIndex), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(SmartAttachEvent.new(vehicle, targetVehicle, inputJointDescIndex, jointDescIndex))
		end
	end
end
