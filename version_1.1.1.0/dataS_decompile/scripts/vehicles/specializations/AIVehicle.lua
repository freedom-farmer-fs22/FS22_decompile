AIVehicle = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function AIVehicle.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("AIVehicle")
	AIVehicle.registerAgentAttachmentPaths(schema, "vehicle.ai", true)
	schema:setXMLSpecializationType()
end

function AIVehicle.registerAgentAttachmentPaths(schema, basePath, includeSubAttachments)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".agentAttachment(?)#jointNode", "Custom joint node (if not defined the current attacher joint is used)")
	schema:register(XMLValueType.VECTOR_N, basePath .. ".agentAttachment(?)#rotCenterWheelIndices", "The center of these wheel indices define the steering center")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".agentAttachment(?)#rotCenterNode", "Custom node to define the steering center")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".agentAttachment(?)#rotCenterPosition", "Offset from root component that defines the steering center")
	schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#width", "Agent attachable width", 3)
	schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#height", "Agent attachable height", 3)
	schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#heightOffset", "Agent attachable height offset (only for visual debug)", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#length", "Agent attachable length", 3)
	schema:register(XMLValueType.FLOAT, basePath .. ".agentAttachment(?)#lengthOffset", "Agent attachable length offset from rot center", 0)
	schema:register(XMLValueType.BOOL, basePath .. ".agentAttachment(?)#hasCollision", "Agent attachable is doing collision checks", true)

	if includeSubAttachments then
		AIVehicle.registerAgentAttachmentPaths(schema, basePath .. ".agentAttachment(?)", false)
	end
end

function AIVehicle.registerEvents(vehicleType)
end

function AIVehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "collectAIAgentAttachments", AIVehicle.collectAIAgentAttachments)
	SpecializationUtil.registerFunction(vehicleType, "registerAIAgentAttachment", AIVehicle.registerAIAgentAttachment)
	SpecializationUtil.registerFunction(vehicleType, "loadAIAgentAttachmentsFromXML", AIVehicle.loadAIAgentAttachmentsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "validateAIAgentAttachments", AIVehicle.validateAIAgentAttachments)
	SpecializationUtil.registerFunction(vehicleType, "drawAIAgentAttachments", AIVehicle.drawAIAgentAttachments)
	SpecializationUtil.registerFunction(vehicleType, "raiseAIEvent", AIVehicle.raiseAIEvent)
	SpecializationUtil.registerFunction(vehicleType, "safeRaiseAIEvent", AIVehicle.safeRaiseAIEvent)
	SpecializationUtil.registerFunction(vehicleType, "getIsAIReadyToDrive", AIVehicle.getIsAIReadyToDrive)
	SpecializationUtil.registerFunction(vehicleType, "getIsAIPreparingToDrive", AIVehicle.getIsAIPreparingToDrive)
end

function AIVehicle.registerOverwrittenFunctions(vehicleType)
end

function AIVehicle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIVehicle)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIVehicle)
end

function AIVehicle:onLoad(savegame)
	local spec = self.spec_aiVehicle
	local baseName = "vehicle.ai"
	spec.agentAttachments = {}

	if self.getInputAttacherJoints ~= nil then
		self:loadAIAgentAttachmentsFromXML(self.xmlFile, baseName .. ".agentAttachment", spec.agentAttachments)
	end

	spec.debugSizeBox = DebugCube.new()

	spec.debugSizeBox:setColor(0, 1, 1)
end

function AIVehicle:onPostLoad(savegame)
	local spec = self.spec_aiVehicle

	if #spec.agentAttachments > 0 then
		local inputAttacherJoints = self:getInputAttacherJoints()

		self:validateAIAgentAttachments(spec.agentAttachments, inputAttacherJoints)
	end
end

function AIVehicle:collectAIAgentAttachments(aiDrivableVehicle)
	local spec = self.spec_aiVehicle

	if #spec.agentAttachments > 0 then
		local inputAttacherJointDesc = self:getActiveInputAttacherJoint()

		if inputAttacherJointDesc ~= nil then
			local jointDesc = self:getAttacherVehicle():getAttacherJointDescFromObject(self)
			local usedExplicitAttachment = false

			for i = 1, #spec.agentAttachments do
				local agentAttachment = spec.agentAttachments[i]

				if agentAttachment.jointNode == inputAttacherJointDesc.node then
					agentAttachment.attacherVehicleJointNode = jointDesc.jointTransform

					self:registerAIAgentAttachment(aiDrivableVehicle, agentAttachment)

					usedExplicitAttachment = true
				end
			end

			if not usedExplicitAttachment then
				for i = 1, #spec.agentAttachments do
					local agentAttachment = spec.agentAttachments[i]

					if agentAttachment.isDirectAttachment then
						agentAttachment.attacherVehicleJointNode = jointDesc.jointTransform
						agentAttachment.jointNodeDynamic = inputAttacherJointDesc.node

						self:registerAIAgentAttachment(aiDrivableVehicle, agentAttachment)

						break
					end
				end
			end

			for i = 1, #spec.agentAttachments do
				local agentAttachment = spec.agentAttachments[i]

				if not agentAttachment.isDirectAttachment then
					self:registerAIAgentAttachment(aiDrivableVehicle, agentAttachment)
				end
			end
		end
	end
end

function AIVehicle:registerAIAgentAttachment(aiDrivableVehicle, agentAttachment)
	aiDrivableVehicle:addAIAgentAttachment(agentAttachment)

	for i = 1, #agentAttachment.agentAttachments do
		local subAgentAttachment = agentAttachment.agentAttachments[i]

		aiDrivableVehicle:addAIAgentAttachment(subAgentAttachment)
	end
end

function AIVehicle:loadAIAgentAttachmentsFromXML(xmlFile, baseKey, agentAttachments, loadSubAttachments, requiresJointNode)
	xmlFile:iterate(baseKey, function (index, key)
		local agentAttachment = {
			jointNode = xmlFile:getValue(key .. "#jointNode", nil, self.components, self.i3dMappings),
			jointNodeDynamic = nil,
			rotCenterNode = xmlFile:getValue(key .. "#rotCenterNode", nil, self.components, self.i3dMappings),
			rotCenterWheelIndices = xmlFile:getValue(key .. "#rotCenterWheelIndices", nil, true),
			rotCenterPosition = xmlFile:getValue(key .. "#rotCenterPosition", nil, true),
			width = xmlFile:getValue(key .. "#width", 3),
			height = xmlFile:getValue(key .. "#height", 3),
			heightOffset = xmlFile:getValue(key .. "#heightOffset", 0),
			length = xmlFile:getValue(key .. "#length", 3),
			lengthOffset = xmlFile:getValue(key .. "#lengthOffset", 0),
			hasCollision = xmlFile:getValue(key .. "#hasCollision", true),
			isDirectAttachment = false,
			agentAttachments = {}
		}

		if loadSubAttachments ~= false then
			self:loadAIAgentAttachmentsFromXML(xmlFile, key .. ".agentAttachment", agentAttachment.agentAttachments, false, true)
		end

		if requiresJointNode == true and agentAttachment.jointNode == nil then
			Logging.xmlWarning(xmlFile, "No joint node defined for ai agent sub attachable '%s'!", key)

			return
		end

		table.insert(agentAttachments, agentAttachment)
	end)

	if loadSubAttachments == nil and #agentAttachments == 0 then
		Logging.xmlDevWarning(xmlFile, "Missing ai agent attachment definition for attachable vehicle")
	end
end

function AIVehicle:validateAIAgentAttachments(agentAttachments, inputAttacherJoints)
	for i = 1, #agentAttachments do
		local agentAttachment = agentAttachments[i]

		for j = 1, #inputAttacherJoints do
			if agentAttachment.jointNode == nil or agentAttachment.jointNode == inputAttacherJoints[j].node then
				agentAttachment.isDirectAttachment = true
			end
		end

		if agentAttachment.rotCenterNode == nil then
			if agentAttachment.rotCenterPosition ~= nil and #agentAttachment.rotCenterPosition == 2 then
				local rotCenterNode = createTransformGroup("aiAgentAttachmentRotCenter" .. i)

				link(self.components[1].node, rotCenterNode)
				setTranslation(rotCenterNode, agentAttachment.rotCenterPosition[1], 0, agentAttachment.rotCenterPosition[2])

				agentAttachment.rotCenterNode = rotCenterNode
			elseif agentAttachment.rotCenterWheelIndices ~= nil and #agentAttachment.rotCenterWheelIndices > 0 and self.getWheels ~= nil then
				local wheels = self:getWheels()
				local x = 0
				local y = 0
				local z = 0
				local dirX = 0
				local dirY = 0
				local dirZ = 0
				local numWheels = 0
				local component = nil

				for j = 1, #agentAttachment.rotCenterWheelIndices do
					local wheelIndex = agentAttachment.rotCenterWheelIndices[j]
					local wheel = wheels[wheelIndex]

					if wheel ~= nil then
						component = component or wheel.node
						local wx, wy, wz = localToLocal(wheel.repr, component, 0, -wheel.radius, 0)
						local dx, dy, dz = localDirectionToLocal(wheel.driveNode, component, 0, 0, 1)
						z = z + wz
						y = y + wy
						x = x + wx
						dirZ = dirZ + dz
						dirY = dirY + dy
						dirX = dirX + dx
						numWheels = numWheels + 1
					else
						Logging.xmlWarning(self.xmlFile, "Unknown wheel index '%d' ground in ai agent attachment entry 'vehicle.ai.agentAttachment(%d)'!", wheelIndex, i - 1)
					end
				end

				if numWheels > 0 then
					z = z / numWheels
					y = y / numWheels
					x = x / numWheels
					dirZ = dirZ / numWheels
					dirY = dirY / numWheels
					dirX = dirX / numWheels
				end

				local rotCenterNode = createTransformGroup("aiAgentAttachmentRotCenter" .. i)

				link(component, rotCenterNode)
				setTranslation(rotCenterNode, x, y, z)

				agentAttachment.rotCenterNode = rotCenterNode

				if numWheels > 0 and MathUtil.vector3Length(dirX, dirY, dirZ) > 0 then
					setDirection(rotCenterNode, dirX, dirY, dirZ, 0, 1, 0)
				end
			end
		end

		if agentAttachment.rotCenterNode == nil then
			agentAttachment.rootNode = self.rootNode
		end

		self:validateAIAgentAttachments(agentAttachment.agentAttachments, inputAttacherJoints)
	end
end

function AIVehicle:drawAIAgentAttachments(agentAttachments)
	local spec = self.spec_aiVehicle
	agentAttachments = agentAttachments or spec.agentAttachments

	for i = 1, #agentAttachments do
		local agentAttachment = agentAttachments[i]

		if agentAttachment.rotCenterNode ~= nil then
			spec.debugSizeBox:setColor(0, 1, 0.25)
			spec.debugSizeBox:createWithNode(agentAttachment.rotCenterNode, agentAttachment.width * 0.5, agentAttachment.height * 0.5, agentAttachment.length * 0.5, 0, agentAttachment.height * 0.5 + agentAttachment.heightOffset, agentAttachment.lengthOffset)
			spec.debugSizeBox:draw()
		else
			spec.debugSizeBox:setColor(0, 0.15, 1)
			spec.debugSizeBox:createWithNode(agentAttachment.rootNode, agentAttachment.width * 0.5, agentAttachment.height * 0.5, agentAttachment.length * 0.5, 0, agentAttachment.height * 0.5 + agentAttachment.heightOffset, agentAttachment.lengthOffset)
			spec.debugSizeBox:draw()
		end

		self:drawAIAgentAttachments(agentAttachment.agentAttachments)
	end
end

function AIVehicle:raiseAIEvent(eventName, implementName, ...)
	local actionController = self.rootVehicle.actionController

	for _, vehicle in ipairs(self.rootVehicle.childVehicles) do
		if vehicle ~= self then
			self:safeRaiseAIEvent(vehicle, implementName, ...)

			if actionController ~= nil then
				actionController:onAIEvent(vehicle, implementName)
			end
		end
	end

	self:safeRaiseAIEvent(self, implementName, ...)

	if actionController ~= nil then
		actionController:onAIEvent(self, implementName)
	end

	self:safeRaiseAIEvent(self, eventName, ...)

	if actionController ~= nil then
		actionController:onAIEvent(self, eventName)
	end
end

function AIVehicle:safeRaiseAIEvent(vehicle, eventName, ...)
	if vehicle.eventListeners[eventName] ~= nil then
		SpecializationUtil.raiseEvent(vehicle, eventName, ...)
	end
end

function AIVehicle:getIsAIReadyToDrive()
	return true
end

function AIVehicle:getIsAIPreparingToDrive()
	return false
end
