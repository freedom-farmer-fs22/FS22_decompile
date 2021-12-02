ConnectionHoses = {
	DEFAULT_MAX_UPDATE_DISTANCE = 50,
	prerequisitesPresent = function (specializations)
		return true
	end
}

function ConnectionHoses.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("ConnectionHoses")
	schema:register(XMLValueType.FLOAT, "vehicle.connectionHoses#maxUpdateDistance", "Max. distance to vehicle root to update connection hoses", ConnectionHoses.DEFAULT_MAX_UPDATE_DISTANCE)
	ConnectionHoses.registerConnectionHoseXMLPaths(schema, "vehicle.connectionHoses")
	ConnectionHoses.registerConnectionHoseXMLPaths(schema, "vehicle.connectionHoses.connectionHoseConfigurations.connectionHoseConfiguration(?)")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.connectionHoses.connectionHoseConfigurations.connectionHoseConfiguration(?)")
	schema:register(XMLValueType.VECTOR_N, Cylindered.MOVING_TOOL_XML_KEY .. ".connectionHoses#customHoseIndices", "Custom hoses to update")
	schema:register(XMLValueType.VECTOR_N, Cylindered.MOVING_TOOL_XML_KEY .. ".connectionHoses#customTargetIndices", "Custom hose targets to update")
	schema:register(XMLValueType.VECTOR_N, Cylindered.MOVING_PART_XML_KEY .. ".connectionHoses#customHoseIndices", "Custom hoses to update")
	schema:register(XMLValueType.VECTOR_N, Cylindered.MOVING_PART_XML_KEY .. ".connectionHoses#customTargetIndices", "Custom hose targets to update")
	schema:setXMLSpecializationType()
end

function ConnectionHoses.registerConnectionHoseXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".skipNode(?)#node", "Skip node")
	schema:register(XMLValueType.INT, basePath .. ".skipNode(?)#inputAttacherJointIndex", "Input attacher joint index", 1)
	schema:register(XMLValueType.INT, basePath .. ".skipNode(?)#attacherJointIndex", "Attacher joint index", 1)
	schema:register(XMLValueType.STRING, basePath .. ".skipNode(?)#type", "Connection hose type")
	schema:register(XMLValueType.STRING, basePath .. ".skipNode(?)#specType", "Connection hose specialization type (if defined it needs to match the type of the other tool)")
	schema:register(XMLValueType.FLOAT, basePath .. ".skipNode(?)#length", "Hose length")
	schema:register(XMLValueType.BOOL, basePath .. ".skipNode(?)#isTwoPointHose", "Is two point hose without sagging", false)
	ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath .. ".target(?)")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".toolConnectorHose(?)#mountingNode", "Mounting node to toggle visibility")
	schema:register(XMLValueType.BOOL, basePath .. ".toolConnectorHose(?)#moveNodes", "Defines if the start and end nodes are moved up depending on hose diameter", true)
	schema:register(XMLValueType.BOOL, basePath .. ".toolConnectorHose(?)#additionalHose", "Defines if between start and end node a additional hose is created", true)
	ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath .. ".toolConnectorHose(?).startTarget(?)")
	ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath .. ".toolConnectorHose(?).endTarget(?)")
	ConnectionHoses.registerHoseNodesXMLPaths(schema, basePath .. ".hose(?)")
	ConnectionHoses.registerHoseNodesXMLPaths(schema, basePath .. ".localHose(?).hose")
	ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath .. ".localHose(?).target")
	ConnectionHoses.registerCustomHoseNodesXMLPaths(schema, basePath .. ".customHose(?)")
	ConnectionHoses.registerCustomHoseNodesXMLPaths(schema, basePath .. ".customTarget(?)")
end

function ConnectionHoses.registerHoseTargetNodesXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Target node")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#attacherJointIndices", "Attacher joint indices")
	schema:register(XMLValueType.STRING, basePath .. "#type", "Hose type")
	schema:register(XMLValueType.STRING, basePath .. "#specType", "Connection hose specialization type (if defined it needs to match the type of the other tool)")
	schema:register(XMLValueType.FLOAT, basePath .. "#straighteningFactor", "Straightening Factor", 1)
	schema:register(XMLValueType.VECTOR_3, basePath .. "#straighteningDirection", "Straightening direction", "0 0 1")
	schema:register(XMLValueType.STRING, basePath .. "#socket", "Socket name to load")
	schema:register(XMLValueType.COLOR, basePath .. "#socketColor", "Socket custom color")
	schema:register(XMLValueType.STRING, basePath .. "#adapterType", "Adapter type to use", "DEFAULT")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end

function ConnectionHoses.registerHoseNodesXMLPaths(schema, basePath)
	schema:register(XMLValueType.VECTOR_N, basePath .. "#inputAttacherJointIndices", "Input attacher joint indices")
	schema:register(XMLValueType.STRING, basePath .. "#type", "Hose type")
	schema:register(XMLValueType.STRING, basePath .. "#specType", "Connection hose specialization type (if defined it needs to match the type of the other tool)")
	schema:register(XMLValueType.STRING, basePath .. "#hoseType", "Hose material type", "DEFAULT")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Hose output node")
	schema:register(XMLValueType.BOOL, basePath .. "#isTwoPointHose", "Is two point hose without sagging", false)
	schema:register(XMLValueType.BOOL, basePath .. "#isWorldSpaceHose", "Sagging is calculated in world space or local space of hose node", true)
	schema:register(XMLValueType.STRING, basePath .. "#dampingRange", "Damping range in meters", 0.05)
	schema:register(XMLValueType.FLOAT, basePath .. "#dampingFactor", "Damping factor", 50)
	schema:register(XMLValueType.FLOAT, basePath .. "#length", "Hose length", 3)
	schema:register(XMLValueType.FLOAT, basePath .. "#diameter", "Hose diameter", 0.02)
	schema:register(XMLValueType.FLOAT, basePath .. "#straighteningFactor", "Straightening Factor", 1)
	schema:register(XMLValueType.ANGLE, basePath .. "#minCenterPointAngle", "Min. angle of sagged curve", "Defined on connectionHose xml, default 90 degree")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#minCenterPointOffset", "Min. center point offset from hose node", "unlimited")
	schema:register(XMLValueType.VECTOR_TRANS, basePath .. "#maxCenterPointOffset", "Max. center point offset from hose node", "unlimited")
	schema:register(XMLValueType.FLOAT, basePath .. "#minDeltaY", "Min. delta Y from center point")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#minDeltaYComponent", "Min. delta Y reference node")
	schema:register(XMLValueType.COLOR, basePath .. "#color", "Hose color")
	schema:register(XMLValueType.STRING, basePath .. "#adapterType", "Adapter type name")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#adapterNode", "Link node for detached adapter")
	schema:register(XMLValueType.STRING, basePath .. "#outgoingAdapter", "Adapter type that is used for outgoing connection hose")
	schema:register(XMLValueType.STRING, basePath .. "#socket", "Outgoing socket name to load")
	schema:register(XMLValueType.COLOR, basePath .. "#socketColor", "Socket custom color")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end

function ConnectionHoses.registerCustomHoseNodesXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Target or source node")
	schema:register(XMLValueType.STRING, basePath .. "#type", "Hose type which can be any string that needs to match between hose and target node")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#attacherJointIndices", "Attacher joint indices")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#inputAttacherJointIndices", "Input attacher joint indices")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, basePath)
end

function ConnectionHoses.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getConnectionHoseConfigIndex", ConnectionHoses.getConnectionHoseConfigIndex)
	SpecializationUtil.registerFunction(vehicleType, "updateAttachedConnectionHoses", ConnectionHoses.updateAttachedConnectionHoses)
	SpecializationUtil.registerFunction(vehicleType, "updateConnectionHose", ConnectionHoses.updateConnectionHose)
	SpecializationUtil.registerFunction(vehicleType, "getCenterPointAngle", ConnectionHoses.getCenterPointAngle)
	SpecializationUtil.registerFunction(vehicleType, "getCenterPointAngleRegulation", ConnectionHoses.getCenterPointAngleRegulation)
	SpecializationUtil.registerFunction(vehicleType, "loadConnectionHosesFromXML", ConnectionHoses.loadConnectionHosesFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadHoseSkipNode", ConnectionHoses.loadHoseSkipNode)
	SpecializationUtil.registerFunction(vehicleType, "loadToolConnectorHoseNode", ConnectionHoses.loadToolConnectorHoseNode)
	SpecializationUtil.registerFunction(vehicleType, "addHoseTargetNodes", ConnectionHoses.addHoseTargetNodes)
	SpecializationUtil.registerFunction(vehicleType, "loadCustomHosesFromXML", ConnectionHoses.loadCustomHosesFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadHoseTargetNode", ConnectionHoses.loadHoseTargetNode)
	SpecializationUtil.registerFunction(vehicleType, "loadHoseNode", ConnectionHoses.loadHoseNode)
	SpecializationUtil.registerFunction(vehicleType, "getClonedSkipHoseNode", ConnectionHoses.getClonedSkipHoseNode)
	SpecializationUtil.registerFunction(vehicleType, "getConnectionTarget", ConnectionHoses.getConnectionTarget)
	SpecializationUtil.registerFunction(vehicleType, "iterateConnectionTargets", ConnectionHoses.iterateConnectionTargets)
	SpecializationUtil.registerFunction(vehicleType, "getIsConnectionTargetUsed", ConnectionHoses.getIsConnectionTargetUsed)
	SpecializationUtil.registerFunction(vehicleType, "getIsConnectionHoseUsed", ConnectionHoses.getIsConnectionHoseUsed)
	SpecializationUtil.registerFunction(vehicleType, "getIsSkipNodeAvailable", ConnectionHoses.getIsSkipNodeAvailable)
	SpecializationUtil.registerFunction(vehicleType, "getConnectionHosesByInputAttacherJoint", ConnectionHoses.getConnectionHosesByInputAttacherJoint)
	SpecializationUtil.registerFunction(vehicleType, "connectHose", ConnectionHoses.connectHose)
	SpecializationUtil.registerFunction(vehicleType, "disconnectHose", ConnectionHoses.disconnectHose)
	SpecializationUtil.registerFunction(vehicleType, "updateToolConnectionHose", ConnectionHoses.updateToolConnectionHose)
	SpecializationUtil.registerFunction(vehicleType, "addHoseToDelayedMountings", ConnectionHoses.addHoseToDelayedMountings)
	SpecializationUtil.registerFunction(vehicleType, "connectHoseToSkipNode", ConnectionHoses.connectHoseToSkipNode)
	SpecializationUtil.registerFunction(vehicleType, "connectHosesToAttacherVehicle", ConnectionHoses.connectHosesToAttacherVehicle)
	SpecializationUtil.registerFunction(vehicleType, "retryHoseSkipNodeConnections", ConnectionHoses.retryHoseSkipNodeConnections)
	SpecializationUtil.registerFunction(vehicleType, "connectCustomHosesToAttacherVehicle", ConnectionHoses.connectCustomHosesToAttacherVehicle)
	SpecializationUtil.registerFunction(vehicleType, "connectCustomHoseNode", ConnectionHoses.connectCustomHoseNode)
	SpecializationUtil.registerFunction(vehicleType, "updateCustomHoseNode", ConnectionHoses.updateCustomHoseNode)
	SpecializationUtil.registerFunction(vehicleType, "disconnectCustomHoseNode", ConnectionHoses.disconnectCustomHoseNode)
end

function ConnectionHoses.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadExtraDependentParts", ConnectionHoses.loadExtraDependentParts)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateExtraDependentParts", ConnectionHoses.updateExtraDependentParts)
end

function ConnectionHoses.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", ConnectionHoses)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", ConnectionHoses)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", ConnectionHoses)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", ConnectionHoses)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", ConnectionHoses)
end

function ConnectionHoses:onPreLoad(savegame)
	local spec = self.spec_connectionHoses
	spec.configIndex = self:getConnectionHoseConfigIndex()
end

function ConnectionHoses:onLoad(savegame)
	local spec = self.spec_connectionHoses
	local configKey = string.format("vehicle.connectionHoses.connectionHoseConfigurations.connectionHoseConfiguration(%d)", spec.configIndex - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.connectionHoses.connectionHoseConfigurations.connectionHoseConfiguration", spec.configIndex, self.components, self)

	spec.numHosesByType = {}
	spec.numToolConnectionsByType = {}
	spec.hoseSkipNodes = {}
	spec.hoseSkipNodeByType = {}
	spec.targetNodes = {}
	spec.targetNodesByType = {}
	spec.toolConnectorHoses = {}
	spec.targetNodeToToolConnection = {}
	spec.hoseNodes = {}
	spec.hoseNodesByInputAttacher = {}
	spec.localHoseNodes = {}
	spec.customHoses = {}
	spec.customHosesByAttacher = {}
	spec.customHosesByInputAttacher = {}
	spec.customHoseTargets = {}
	spec.customHoseTargetsByAttacher = {}
	spec.customHoseTargetsByInputAttacher = {}

	self:loadConnectionHosesFromXML(self.xmlFile, "vehicle.connectionHoses")

	if self.xmlFile:hasProperty(configKey) then
		self:loadConnectionHosesFromXML(self.xmlFile, configKey)
	end

	spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.connectionHoses#maxUpdateDistance", ConnectionHoses.DEFAULT_MAX_UPDATE_DISTANCE)
	spec.targetNodesAvailable = #spec.targetNodes > 0
	spec.hoseNodesAvailable = #spec.hoseNodes > 0
	spec.localHosesAvailable = #spec.localHoseNodes > 0
	spec.skipNodesAvailable = #spec.hoseSkipNodes > 0
	spec.updateableHoses = {}

	for _, localHoseNode in ipairs(spec.localHoseNodes) do
		self:connectHose(localHoseNode.hose, self, localHoseNode.target, false)
	end

	if not self.isClient or not spec.targetNodesAvailable and not spec.hoseNodesAvailable and not spec.localHosesAvailable and not spec.skipNodesAvailable then
		SpecializationUtil.removeEventListener(self, "onPostUpdate", ConnectionHoses)
	end
end

function ConnectionHoses:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_connectionHoses

	if self.currentUpdateDistance < spec.maxUpdateDistance then
		for i = 1, #spec.updateableHoses do
			local hose = spec.updateableHoses[i]

			if self.updateLoopIndex == hose.connectedObject.updateLoopIndex then
				self:updateConnectionHose(hose, i)
			end
		end

		if self.getAttachedImplements ~= nil then
			local impements = self:getAttachedImplements()

			for i = 1, #impements do
				local object = impements[i].object

				if object.updateAttachedConnectionHoses ~= nil then
					object:updateAttachedConnectionHoses(self)
				end
			end
		end
	end
end

function ConnectionHoses:getConnectionHoseConfigIndex()
	return 1
end

function ConnectionHoses:updateAttachedConnectionHoses(attacherVehicle)
	local spec = self.spec_connectionHoses

	for i = 1, #spec.updateableHoses do
		local hose = spec.updateableHoses[i]

		if hose.connectedObject == attacherVehicle and self.updateLoopIndex == hose.connectedObject.updateLoopIndex then
			self:updateConnectionHose(hose, i)
		end
	end
end

function ConnectionHoses:updateConnectionHose(hose, index)
	local p0x = 0
	local p0y = 0
	local p0z = -hose.startStraightening
	local p3x, p3y, p3z = localToLocal(hose.targetNode, hose.hoseNode, 0, 0, 0)
	local p4x, p4y, p4z = localToLocal(hose.targetNode, hose.hoseNode, hose.endStraighteningDirection[1] * hose.endStraightening, hose.endStraighteningDirection[2] * hose.endStraightening, hose.endStraighteningDirection[3] * hose.endStraightening)
	local p2x, p2y, p2z = nil

	if hose.isWorldSpaceHose then
		local w1x, w1y, w1z = getWorldTranslation(hose.hoseNode)
		local w2x, w2y, w2z = getWorldTranslation(hose.targetNode)
		p2x = (w1x + w2x) / 2
		p2y = (w1y + w2y) / 2
		p2z = (w1z + w2z) / 2
	else
		p2x = p3x / 2
		p2y = p3y / 2
		p2z = p3z / 2
	end

	local d = MathUtil.vector3Length(p3x, p3y, p3z)
	local lengthDifference = math.max(hose.length - d, 0)
	local p2yStart = p2y

	if not hose.isWorldSpaceHose then
		local _ = nil
		_, p2yStart, _ = localToWorld(hose.hoseNode, p2x, p2y, p2z)
	end

	p2y = p2y - math.max(lengthDifference, 0.04 * d)

	if hose.isWorldSpaceHose then
		if hose.minDeltaY ~= math.huge then
			local x, y, z = worldToLocal(hose.minDeltaYComponent, p2x, p2y, p2z)
			local _, yTarget, _ = localToLocal(hose.hoseNode, hose.minDeltaYComponent, 0, 0, 0)
			p2x, p2y, p2z = localToWorld(hose.minDeltaYComponent, x, math.max(y, yTarget + hose.minDeltaY), z)
		end

		p2x, p2y, p2z = worldToLocal(hose.hoseNode, p2x, p2y, p2z)
	end

	local angle1, angle2 = self:getCenterPointAngle(hose.hoseNode, p2x, p2y, p2z, p3x, p3y, p3z, hose.isWorldSpaceHose)
	local centerPointAngle = angle1 + angle2

	if centerPointAngle < hose.minCenterPointAngle then
		p2x, p2y, p2z = self:getCenterPointAngleRegulation(hose.hoseNode, p2x, p2y, p2z, p3x, p3y, p3z, angle1, angle2, hose.minCenterPointAngle, hose.isWorldSpaceHose)
	end

	if hose.minCenterPointOffset ~= nil and hose.maxCenterPointOffset ~= nil then
		p2x = MathUtil.clamp(p2x, hose.minCenterPointOffset[1], hose.maxCenterPointOffset[1])
		p2y = MathUtil.clamp(p2y, hose.minCenterPointOffset[2], hose.maxCenterPointOffset[2])
		p2z = MathUtil.clamp(p2z, hose.minCenterPointOffset[3], hose.maxCenterPointOffset[3])
	end

	local newX, newY, newZ = getWorldTranslation(hose.component)

	if hose.lastComponentPosition == nil or hose.lastComponentVelocity == nil then
		hose.lastComponentPosition = {
			newX,
			newY,
			newZ
		}
		hose.lastComponentVelocity = {
			newX,
			newY,
			newZ
		}
	end

	local newVelX = newX - hose.lastComponentPosition[1]
	local newVelY = newY - hose.lastComponentPosition[2]
	local newVelZ = newZ - hose.lastComponentPosition[3]
	hose.lastComponentPosition[3] = newZ
	hose.lastComponentPosition[2] = newY
	hose.lastComponentPosition[1] = newX
	local velX = newVelX - hose.lastComponentVelocity[1]
	local velY = newVelY - hose.lastComponentVelocity[2]
	local velZ = newVelZ - hose.lastComponentVelocity[3]
	hose.lastComponentVelocity[3] = newVelZ
	hose.lastComponentVelocity[2] = newVelY
	hose.lastComponentVelocity[1] = newVelX
	local worldX, worldY, worldZ = getWorldTranslation(hose.hoseNode)
	local _ = nil
	_, velY, velZ = worldToLocal(hose.hoseNode, worldX + velX, worldY + velY, worldZ + velZ)
	local _, wp2y, _ = localToWorld(hose.hoseNode, p2x, p2y, p2z)
	local realLengthDifference = p2yStart - wp2y
	velY = MathUtil.clamp(velY * -hose.dampingFactor, -hose.dampingRange, hose.dampingRange) * realLengthDifference
	velZ = MathUtil.clamp(velZ * -hose.dampingFactor, -hose.dampingRange, hose.dampingRange) * realLengthDifference
	velY = velY * 0.1 + hose.lastVelY * 0.9
	velZ = velZ * 0.1 + hose.lastVelZ * 0.9
	hose.lastVelY = velY
	hose.lastVelZ = velZ
	p2z = p2z + velZ
	p2y = p2y + velY
	p2x = p2x

	if hose.isTwoPointHose then
		p2z = 0
		p2y = 0
		p2x = 0
	end

	setShaderParameter(hose.hoseNode, "cv2", p2x, p2y, p2z, 0, false)
	setShaderParameter(hose.hoseNode, "cv3", p3x, p3y, p3z, 0, false)
	setShaderParameter(hose.hoseNode, "cv4", p4x, p4y, p4z, 1, false)

	if VehicleDebug.state == VehicleDebug.DEBUG_ATTACHER_JOINTS and self:getIsActiveForInput() then
		local realLength = MathUtil.vector3Length(p2x, p2y, p2z)
		realLength = realLength + MathUtil.vector3Length(p2x - p3x, p2y - p3y, p2z - p3z)

		renderText(0.5, 0.9 - index * 0.02, 0.0175, string.format("hose %s:", getName(hose.node)))
		renderText(0.62, 0.9 - index * 0.02, 0.0175, string.format("directLength: %.2f configLength: %.2f realLength: %.2f angle: %.2f minAngle: %.2f", d, hose.length, realLength, math.deg(centerPointAngle), math.deg(hose.minCenterPointAngle)))

		local x1, y1, z1 = localToWorld(hose.hoseNode, p0x, p0y, p0z)
		local x2, y2, z2 = localToWorld(hose.hoseNode, 0, 0, 0)

		drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 0, 1, 0)

		x1, y1, z1 = localToWorld(hose.hoseNode, 0, 0, 0)
		x2, y2, z2 = localToWorld(hose.hoseNode, p2x, p2y, p2z)

		drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 0, 1, 0)

		x1, y1, z1 = localToWorld(hose.hoseNode, p2x, p2y, p2z)
		x2, y2, z2 = localToWorld(hose.hoseNode, p3x, p3y, p3z)

		drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 0, 1, 0)

		x1, y1, z1 = localToWorld(hose.hoseNode, p3x, p3y, p3z)
		x2, y2, z2 = localToWorld(hose.hoseNode, p4x, p4y, p4z)

		drawDebugLine(x1, y1, z1, 1, 0, 0, x2, y2, z2, 0, 1, 0)

		local x0, y0, z0 = localToWorld(hose.hoseNode, p0x, p0y, p0z)
		x1, y1, z1 = localToWorld(hose.hoseNode, 0, 0, 0)
		x2, y2, z2 = localToWorld(hose.hoseNode, p2x, p2y, p2z)
		local x3, y3, z3 = localToWorld(hose.hoseNode, p3x, p3y, p3z)
		local x4, y4, z4 = localToWorld(hose.hoseNode, p4x, p4y, p4z)

		drawDebugPoint(x0, y0, z0, 1, 0, 0, 1)
		drawDebugPoint(x1, y1, z1, 1, 0, 0, 1)
		drawDebugPoint(x2, y2, z2, 1, 0, 0, 1)
		drawDebugPoint(x3, y3, z3, 1, 0, 0, 1)
		drawDebugPoint(x4, y4, z4, 1, 0, 0, 1)
		DebugUtil.drawDebugNode(hose.hoseNode)
		DebugUtil.drawDebugNode(hose.targetNode)
	end
end

function ConnectionHoses:getCenterPointAngle(node, cX, cY, cZ, eX, eY, eZ, useWorldSpace)
	local lengthStartToCenter = MathUtil.vector3Length(cX, cY, cZ)
	local lengthCenterToEnd = math.abs(MathUtil.vector3Length(cX - eX, cY - eY, cZ - eZ))
	local _, sY, _ = getWorldTranslation(node)

	if useWorldSpace then
		_, cY, _ = localToWorld(node, cX, cY, cZ)
		_, eY, _ = localToWorld(node, eX, eY, eZ)
	else
		sY = 0
	end

	local lengthStartToCenter2 = sY - cY
	local lengthCenterToEnd2 = eY - cY
	local angle1 = math.acos(lengthStartToCenter2 / lengthStartToCenter)
	local angle2 = math.acos(lengthCenterToEnd2 / lengthCenterToEnd)

	return angle1, angle2
end

function ConnectionHoses:getCenterPointAngleRegulation(node, cX, cY, cZ, eX, eY, eZ, angle1, angle2, targetAngle, useWorldSpace)
	local sX, sY, sZ = getWorldTranslation(node)

	if useWorldSpace then
		local _ = nil
		cX, _, cZ = localToWorld(node, cX, cY, cZ)
		eX, _, eZ = localToWorld(node, eX, eY, eZ)
	else
		sZ = 0
		sY = 0
		sX = 0
	end

	local startCenterLength = MathUtil.vector2Length(sX - cX, sZ - cZ)
	local centerEndLength = MathUtil.vector2Length(eX - cX, eZ - cZ)
	local pct = angle1 / (angle1 + angle2)
	local alpha = math.pi * 0.5 - pct * targetAngle
	local newY1 = math.tan(alpha) * startCenterLength
	local newY2 = math.tan(alpha) * centerEndLength
	local newY = (newY1 + newY2) / 2

	if useWorldSpace then
		return worldToLocal(node, cX, sY - newY, cZ)
	else
		return cX, sY - newY, cZ
	end
end

function ConnectionHoses:loadConnectionHosesFromXML(xmlFile, key)
	local spec = self.spec_connectionHoses

	xmlFile:iterate(key .. ".skipNode", function (_, hoseKey)
		local entry = {}

		if self:loadHoseSkipNode(xmlFile, hoseKey, entry) then
			table.insert(spec.hoseSkipNodes, entry)

			if spec.hoseSkipNodeByType[entry.type] == nil then
				spec.hoseSkipNodeByType[entry.type] = {}
			end

			table.insert(spec.hoseSkipNodeByType[entry.type], entry)
		end
	end)
	self:addHoseTargetNodes(xmlFile, key .. ".target")
	xmlFile:iterate(key .. ".toolConnectorHose", function (_, hoseKey)
		local entry = {}

		if self:loadToolConnectorHoseNode(xmlFile, hoseKey, entry) then
			table.insert(spec.toolConnectorHoses, entry)

			spec.targetNodeToToolConnection[entry.startTargetNodeIndex] = entry
			spec.targetNodeToToolConnection[entry.endTargetNodeIndex] = entry
		end
	end)
	xmlFile:iterate(key .. ".hose", function (_, hoseKey)
		local entry = {}

		if self:loadHoseNode(xmlFile, hoseKey, entry, true) then
			table.insert(spec.hoseNodes, entry)

			entry.index = #spec.hoseNodes

			for _, index in pairs(entry.inputAttacherJointIndices) do
				if spec.hoseNodesByInputAttacher[index] == nil then
					spec.hoseNodesByInputAttacher[index] = {}
				end

				table.insert(spec.hoseNodesByInputAttacher[index], entry)
			end
		end
	end)
	xmlFile:iterate(key .. ".localHose", function (_, hoseKey)
		local hose = {}

		if self:loadHoseNode(xmlFile, hoseKey .. ".hose", hose, false) then
			local target = {}

			if self:loadHoseTargetNode(xmlFile, hoseKey .. ".target", target) then
				table.insert(spec.localHoseNodes, {
					hose = hose,
					target = target
				})
			end
		end
	end)
	self:loadCustomHosesFromXML(spec.customHoses, spec.customHosesByAttacher, spec.customHosesByInputAttacher, xmlFile, key .. ".customHose")
	self:loadCustomHosesFromXML(spec.customHoseTargets, spec.customHoseTargetsByAttacher, spec.customHoseTargetsByInputAttacher, xmlFile, key .. ".customTarget")
end

function ConnectionHoses:loadHoseSkipNode(xmlFile, targetKey, entry)
	entry.node = xmlFile:getValue(targetKey .. "#node", nil, self.components, self.i3dMappings)

	if entry.node == nil then
		Logging.xmlWarning(xmlFile, "Missing node for hose skip node '%s'", targetKey)

		return false
	end

	entry.inputAttacherJointIndex = xmlFile:getValue(targetKey .. "#inputAttacherJointIndex", 1)
	entry.attacherJointIndex = xmlFile:getValue(targetKey .. "#attacherJointIndex", 1)
	entry.type = xmlFile:getValue(targetKey .. "#type")
	entry.specType = xmlFile:getValue(targetKey .. "#specType")

	if entry.type == nil then
		Logging.xmlWarning(xmlFile, "Missing type for hose skip node '%s'", targetKey)

		return false
	end

	entry.length = xmlFile:getValue(targetKey .. "#length")
	entry.isTwoPointHose = xmlFile:getValue(targetKey .. "#isTwoPointHose", false)
	entry.isSkipNode = true

	return true
end

function ConnectionHoses:loadToolConnectorHoseNode(xmlFile, targetKey, entry)
	local spec = self.spec_connectionHoses
	local key = string.format("%s.startTarget", targetKey)
	entry.startTargetNodeIndex = self:addHoseTargetNodes(xmlFile, key)

	if entry.startTargetNodeIndex == nil then
		Logging.xmlWarning(xmlFile, "startTarget is missing for tool connection hose '%s'", targetKey)

		return false
	end

	key = string.format("%s.endTarget", targetKey)
	entry.endTargetNodeIndex = self:addHoseTargetNodes(xmlFile, key)

	if entry.endTargetNodeIndex == nil then
		Logging.xmlWarning(xmlFile, "endTarget is missing for tool connection hose '%s'", targetKey)

		return false
	end

	local startTarget = spec.targetNodes[entry.startTargetNodeIndex]
	local endTarget = spec.targetNodes[entry.endTargetNodeIndex]

	for index, _ in pairs(startTarget.attacherJointIndices) do
		if endTarget.attacherJointIndices[index] ~= nil then
			Logging.xmlWarning(xmlFile, "Double usage of attacher joint index '%d' in '%s'", index, targetKey)
		end
	end

	entry.moveNodes = xmlFile:getValue(targetKey .. "#moveNodes", true)
	entry.additionalHose = xmlFile:getValue(targetKey .. "#additionalHose", true)

	if entry.moveNodes then
		local x1, y1, z1 = getTranslation(startTarget.node)
		local x2, y2, z2 = getTranslation(endTarget.node)
		local dirX, dirY, dirZ = MathUtil.vector3Normalize(x1 - x2, y1 - y2, z1 - z2)
		local upX, upY, upZ = localDirectionToLocal(endTarget.node, getParent(endTarget.node), 0, 1, 0)

		if (dirX ~= 0 or dirY ~= 0 or dirZ ~= 0) and not MathUtil.isNan(dirX) and not MathUtil.isNan(dirY) and not MathUtil.isNan(dirZ) then
			setDirection(startTarget.node, -dirX, -dirY, -dirZ, upX, upY, upZ)
			setDirection(endTarget.node, dirX, dirY, dirZ, upX, upY, upZ)
		end
	end

	entry.mountingNode = xmlFile:getValue(targetKey .. "#mountingNode", nil, self.components, self.i3dMappings)

	if entry.mountingNode ~= nil then
		setVisibility(entry.mountingNode, false)
	end

	local type = spec.targetNodes[entry.startTargetNodeIndex].type .. (spec.targetNodes[entry.startTargetNodeIndex].specType or "")

	if spec.numToolConnectionsByType[type] == nil then
		spec.numToolConnectionsByType[type] = 0
	end

	spec.numToolConnectionsByType[type] = spec.numToolConnectionsByType[type] + 1
	entry.typedIndex = spec.numToolConnectionsByType[type]
	entry.connected = false

	return true
end

function ConnectionHoses:addHoseTargetNodes(xmlFile, key)
	local spec = self.spec_connectionHoses
	local addedTarget = false

	xmlFile:iterate(key, function (_, targetKey)
		local entry = {}

		if self:loadHoseTargetNode(xmlFile, targetKey, entry) then
			table.insert(spec.targetNodes, entry)

			entry.index = #spec.targetNodes

			if spec.targetNodesByType[entry.type] == nil then
				spec.targetNodesByType[entry.type] = {}
			end

			table.insert(spec.targetNodesByType[entry.type], entry)

			addedTarget = true
		end
	end)

	if addedTarget then
		return #spec.targetNodes
	end
end

function ConnectionHoses:loadCustomHosesFromXML(targetTable, attacherJointMapping, inputAttacherJointMapping, xmlFile, key)
	xmlFile:iterate(key, function (_, customKey)
		local entry = {
			node = xmlFile:getValue(customKey .. "#node", nil, self.components, self.i3dMappings)
		}

		if entry.node ~= nil then
			entry.type = xmlFile:getValue(customKey .. "#type")

			if entry.type ~= nil then
				entry.type = entry.type:upper()
				local attacherJointIndices = xmlFile:getValue(customKey .. "#attacherJointIndices", nil, true)
				entry.attacherJointIndices = {}

				for _, v in ipairs(attacherJointIndices) do
					entry.attacherJointIndices[v] = v

					if attacherJointMapping[v] == nil then
						attacherJointMapping[v] = {}
					end

					table.insert(attacherJointMapping[v], entry)
				end

				local inputAttacherJointIndices = xmlFile:getValue(customKey .. "#inputAttacherJointIndices", nil, true)
				entry.inputAttacherJointIndices = {}

				for _, v in ipairs(inputAttacherJointIndices) do
					entry.inputAttacherJointIndices[v] = v

					if inputAttacherJointMapping[v] == nil then
						inputAttacherJointMapping[v] = {}
					end

					table.insert(inputAttacherJointMapping[v], entry)
				end

				entry.objectChanges = {}

				ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, customKey, entry.objectChanges, self.components, self)
				ObjectChangeUtil.setObjectChanges(entry.objectChanges, false)

				entry.startTranslation = {
					getTranslation(entry.node)
				}
				entry.startRotation = {
					getRotation(entry.node)
				}
				entry.isActive = false

				table.insert(targetTable, entry)
			else
				Logging.xmlWarning(xmlFile, "Missing type for custom hose '%s'", customKey)
			end
		else
			Logging.xmlWarning(xmlFile, "Missing node for custom hose '%s'", customKey)
		end
	end)
end

function ConnectionHoses:loadHoseTargetNode(xmlFile, targetKey, entry)
	entry.node = xmlFile:getValue(targetKey .. "#node", nil, self.components, self.i3dMappings)

	if entry.node == nil then
		Logging.xmlWarning(xmlFile, "Missing node for connection hose target '%s'", targetKey)

		return false
	end

	local attacherJointIndices = xmlFile:getValue(targetKey .. "#attacherJointIndices", nil, true)
	entry.attacherJointIndices = {}

	for _, v in ipairs(attacherJointIndices) do
		entry.attacherJointIndices[v] = v
	end

	entry.type = xmlFile:getValue(targetKey .. "#type")
	entry.specType = xmlFile:getValue(targetKey .. "#specType")
	entry.straighteningFactor = xmlFile:getValue(targetKey .. "#straighteningFactor", 1)
	entry.straighteningDirection = xmlFile:getValue(targetKey .. "#straighteningDirection", nil, true)
	local socketName = xmlFile:getValue(targetKey .. "#socket")

	if socketName ~= nil then
		local socketColor = xmlFile:getValue(targetKey .. "#socketColor", nil, true)
		entry.socket = g_connectionHoseManager:linkSocketToNode(socketName, entry.node, self.customEnvironment, socketColor)
	end

	if entry.type ~= nil then
		entry.adapterName = xmlFile:getValue(targetKey .. "#adapterType", "DEFAULT")

		if entry.adapter == nil then
			entry.adapter = {
				node = entry.node,
				refNode = entry.node
			}
		end

		entry.objectChanges = {}

		ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, targetKey, entry.objectChanges, self.components, self)
		ObjectChangeUtil.setObjectChanges(entry.objectChanges, false)
	else
		Logging.xmlWarning(xmlFile, "Missing type for '%s'", targetKey)

		return false
	end

	return true
end

function ConnectionHoses:loadHoseNode(xmlFile, hoseKey, entry, isBaseHose)
	local inputAttacherJointIndices = xmlFile:getValue(hoseKey .. "#inputAttacherJointIndices", nil, true)
	entry.inputAttacherJointIndices = {}

	for _, v in ipairs(inputAttacherJointIndices) do
		entry.inputAttacherJointIndices[v] = v
	end

	entry.type = xmlFile:getValue(hoseKey .. "#type")
	entry.specType = xmlFile:getValue(hoseKey .. "#specType")

	if entry.type == nil then
		Logging.xmlWarning(xmlFile, "Missing type attribute in '%s'", hoseKey)

		return false
	end

	entry.hoseType = xmlFile:getValue(hoseKey .. "#hoseType", "DEFAULT")
	entry.node = xmlFile:getValue(hoseKey .. "#node", nil, self.components, self.i3dMappings)

	if entry.node == nil then
		Logging.xmlWarning(xmlFile, "Missing node for connection hose '%s'", hoseKey)

		return false
	end

	if isBaseHose then
		local spec = self.spec_connectionHoses
		local type = entry.type .. (entry.specType or "")

		if spec.numHosesByType[type] == nil then
			spec.numHosesByType[type] = 0
		end

		spec.numHosesByType[type] = spec.numHosesByType[type] + 1
		entry.typedIndex = spec.numHosesByType[type]
	end

	entry.isTwoPointHose = xmlFile:getValue(hoseKey .. "#isTwoPointHose", false)
	entry.isWorldSpaceHose = xmlFile:getValue(hoseKey .. "#isWorldSpaceHose", true)
	entry.component = self:getParentComponent(entry.node)
	entry.lastVelY = 0
	entry.lastVelZ = 0
	entry.dampingRange = xmlFile:getValue(hoseKey .. "#dampingRange", 0.05)
	entry.dampingFactor = xmlFile:getValue(hoseKey .. "#dampingFactor", 50)
	entry.length = xmlFile:getValue(hoseKey .. "#length", 3)
	entry.diameter = xmlFile:getValue(hoseKey .. "#diameter", 0.02)
	entry.straighteningFactor = xmlFile:getValue(hoseKey .. "#straighteningFactor", 1)
	entry.minCenterPointAngle = xmlFile:getValue(hoseKey .. "#minCenterPointAngle")
	entry.minCenterPointOffset = xmlFile:getValue(hoseKey .. "#minCenterPointOffset", nil, true)
	entry.maxCenterPointOffset = xmlFile:getValue(hoseKey .. "#maxCenterPointOffset", nil, true)

	if entry.minCenterPointOffset ~= nil and entry.maxCenterPointOffset ~= nil then
		for i = 1, 3 do
			if entry.minCenterPointOffset[i] == 0 then
				entry.minCenterPointOffset[i] = -math.huge
			end

			if entry.maxCenterPointOffset[i] == 0 then
				entry.maxCenterPointOffset[i] = math.huge
			end
		end
	end

	entry.minDeltaY = xmlFile:getValue(hoseKey .. "#minDeltaY", math.huge)
	entry.minDeltaYComponent = xmlFile:getValue(hoseKey .. "#minDeltaYComponent", entry.component, self.components, self.i3dMappings)
	entry.color = xmlFile:getValue(hoseKey .. "#color", nil, true)
	entry.adapterName = xmlFile:getValue(hoseKey .. "#adapterType")
	entry.outgoingAdapter = xmlFile:getValue(hoseKey .. "#outgoingAdapter")
	entry.adapterNode = xmlFile:getValue(hoseKey .. "#adapterNode", nil, self.components, self.i3dMappings)

	if entry.adapterNode ~= nil then
		local node = g_connectionHoseManager:getClonedAdapterNode(entry.type, entry.adapterName or "DEFAULT", self.customEnvironment, true)

		if node ~= nil then
			link(entry.adapterNode, node)
		else
			Logging.xmlWarning(xmlFile, "Unable to find detached adapter for type '%s' in '%s'", entry.adapterName or "DEFAULT", hoseKey)
		end
	end

	local socketName = xmlFile:getValue(hoseKey .. "#socket")

	if socketName ~= nil then
		local socketColor = xmlFile:getValue(hoseKey .. "#socketColor", nil, true)
		entry.socket = g_connectionHoseManager:linkSocketToNode(socketName, entry.node, self.customEnvironment, socketColor)

		if entry.socket ~= nil then
			setRotation(entry.socket.node, 0, math.pi, 0)
		end
	end

	local hose, startStraightening, endStraightening, minCenterPointAngle = g_connectionHoseManager:getClonedHoseNode(entry.type, entry.hoseType, entry.length, entry.diameter, entry.color, self.customEnvironment)

	if hose ~= nil then
		local outgoingNode = g_connectionHoseManager:getSocketTarget(entry.socket, entry.node)
		local visibilityNode = hose
		local rx = 0
		local ry = 0
		local rz = 0

		if entry.outgoingAdapter ~= nil then
			local node, referenceNode = g_connectionHoseManager:getClonedAdapterNode(entry.type, entry.outgoingAdapter, self.customEnvironment)

			if node ~= nil then
				link(outgoingNode, node)

				outgoingNode = referenceNode
				visibilityNode = node
				ry = math.pi

				if entry.socket == nil then
					setRotation(node, 0, ry, 0)
				end
			else
				Logging.xmlWarning(xmlFile, "Unable to find adapter type '%s' in '%s'", entry.outgoingAdapter, hoseKey)
			end
		end

		link(outgoingNode, hose)
		setTranslation(hose, 0, 0, 0)
		setRotation(hose, rx, ry, rz)

		entry.hoseNode = hose
		entry.visibilityNode = visibilityNode
		entry.startStraightening = startStraightening * entry.straighteningFactor
		entry.endStraightening = endStraightening
		entry.endStraighteningBase = endStraightening
		entry.endStraighteningDirectionBase = {
			0,
			0,
			1
		}
		entry.endStraighteningDirection = entry.endStraighteningDirectionBase
		entry.minCenterPointAngle = entry.minCenterPointAngle or minCenterPointAngle

		setVisibility(entry.visibilityNode, false)
	else
		Logging.xmlWarning(xmlFile, "Unable to find connection hose with length '%.2f' and diameter '%.2f' in '%s'", entry.length, entry.diameter, hoseKey)

		return false
	end

	entry.objectChanges = {}

	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, hoseKey, entry.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(entry.objectChanges, false)

	return true
end

function ConnectionHoses:getClonedSkipHoseNode(sourceHose, skipNode)
	local clonedHose = {
		isClonedSkipNodeHose = true,
		type = sourceHose.type,
		specType = sourceHose.specType,
		hoseType = sourceHose.hoseType,
		node = skipNode.node,
		component = self:getParentComponent(skipNode.node),
		lastVelY = 0,
		lastVelZ = 0,
		dampingRange = 0.05,
		dampingFactor = 50,
		minDeltaYComponent = self:getParentComponent(skipNode.node),
		minDeltaY = math.huge,
		length = skipNode.length or sourceHose.length,
		diameter = sourceHose.diameter,
		isTwoPointHose = skipNode.isTwoPointHose,
		color = sourceHose.color
	}
	local hose, startStraightening, endStraightening, minCenterPointAngle = g_connectionHoseManager:getClonedHoseNode(clonedHose.type, clonedHose.hoseType, clonedHose.length, clonedHose.diameter, clonedHose.color, self.customEnvironment)

	if hose ~= nil then
		link(clonedHose.node, hose)
		setTranslation(hose, 0, 0, 0)
		setRotation(hose, 0, 0, 0)

		clonedHose.hoseNode = hose
		clonedHose.visibilityNode = hose
		clonedHose.startStraightening = startStraightening
		clonedHose.endStraightening = endStraightening
		clonedHose.endStraighteningBase = endStraightening
		clonedHose.endStraighteningDirectionBase = {
			0,
			0,
			1
		}
		clonedHose.endStraighteningDirection = clonedHose.endStraighteningDirectionBase
		clonedHose.minCenterPointAngle = minCenterPointAngle

		setVisibility(clonedHose.visibilityNode, false)
	else
		Logging.xmlWarning(self.xmlFile, "Unable to find connection hose with length '%.2f' and diameter '%.2f' in '%s'", clonedHose.length, clonedHose.diameter, "skipHoseClone")

		return false
	end

	clonedHose.objectChanges = {}

	return clonedHose
end

function ConnectionHoses:getConnectionTarget(attacherJointIndex, type, specType, excludeToolConnections)
	local spec = self.spec_connectionHoses

	if #spec.targetNodes == 0 and #spec.hoseSkipNodes == 0 then
		return nil
	end

	local nodes = spec.targetNodesByType[type]

	if nodes ~= nil then
		for _, node in ipairs(nodes) do
			if node.attacherJointIndices[attacherJointIndex] ~= nil and node.specType == specType and not self:getIsConnectionTargetUsed(node) then
				local toolConnectionHose = spec.targetNodeToToolConnection[node.index]

				if toolConnectionHose ~= nil and excludeToolConnections ~= nil and excludeToolConnections and toolConnectionHose.delayedMounting == nil then
					return nil
				end

				return node, false
			end
		end
	end

	nodes = spec.hoseSkipNodeByType[type]

	if nodes ~= nil then
		for _, node in ipairs(nodes) do
			if node.specType == specType and self:getIsSkipNodeAvailable(node) then
				return node, true
			end
		end
	end

	return nil
end

function ConnectionHoses:iterateConnectionTargets(func, attacherJointIndex, type, specType, excludeToolConnections)
	local spec = self.spec_connectionHoses

	if #spec.targetNodes == 0 and #spec.hoseSkipNodes == 0 then
		return nil
	end

	local nodes = spec.targetNodesByType[type]

	if nodes ~= nil then
		for _, node in ipairs(nodes) do
			if node.attacherJointIndices[attacherJointIndex] ~= nil and node.specType == specType and not self:getIsConnectionTargetUsed(node) then
				local toolConnectionHose = spec.targetNodeToToolConnection[node.index]

				if toolConnectionHose ~= nil and excludeToolConnections ~= nil and excludeToolConnections and toolConnectionHose.delayedMounting == nil then
					return nil
				end

				if not func(node, false) then
					break
				end
			end
		end
	end

	nodes = spec.hoseSkipNodeByType[type]

	if nodes ~= nil then
		for _, node in ipairs(nodes) do
			if node.specType == specType and self:getIsSkipNodeAvailable(node) and not func(node, true) then
				break
			end
		end
	end

	return nil
end

function ConnectionHoses:getIsConnectionTargetUsed(desc)
	return desc.connectedObject ~= nil
end

function ConnectionHoses:getIsConnectionHoseUsed(desc)
	return desc.connectedObject ~= nil
end

function ConnectionHoses:getIsSkipNodeAvailable(skipNode)
	if self.getAttacherVehicle == nil then
		return false
	end

	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		local attacherJointIndex = attacherVehicle:getAttacherJointIndexFromObject(self)
		local implement = attacherVehicle:getImplementFromAttacherJointIndex(attacherJointIndex)

		if implement.inputJointDescIndex == skipNode.inputAttacherJointIndex then
			return attacherVehicle:getConnectionTarget(attacherJointIndex, skipNode.type, skipNode.specType, true) ~= nil and skipNode.parentHose == nil
		end
	end

	return false
end

function ConnectionHoses:getConnectionHosesByInputAttacherJoint(inputJointDescIndex)
	local spec = self.spec_connectionHoses

	if spec.hoseNodesByInputAttacher[inputJointDescIndex] ~= nil then
		return spec.hoseNodesByInputAttacher[inputJointDescIndex]
	end

	return {}
end

function ConnectionHoses:connectHose(sourceHose, targetObject, targetHose, updateToolConnections)
	local spec = self.spec_connectionHoses
	local doConnect = false

	if updateToolConnections ~= nil and not updateToolConnections then
		doConnect = true
	elseif targetObject:updateToolConnectionHose(self, sourceHose, targetObject, targetHose, true) then
		doConnect = true
	else
		targetObject:addHoseToDelayedMountings(self, sourceHose, targetObject, targetHose)
	end

	if doConnect then
		targetHose.connectedObject = self
		sourceHose.connectedObject = targetObject
		sourceHose.targetHose = targetHose
		local node, referenceNode = nil

		if sourceHose.adapterName ~= nil then
			if sourceHose.adapterName ~= "NONE" then
				node, referenceNode = g_connectionHoseManager:getClonedAdapterNode(targetHose.type, sourceHose.adapterName, self.customEnvironment)
			end
		elseif targetHose.adapterName ~= "NONE" then
			node, referenceNode = g_connectionHoseManager:getClonedAdapterNode(targetHose.type, targetHose.adapterName, self.customEnvironment)
		end

		if node ~= nil then
			link(g_connectionHoseManager:getSocketTarget(targetHose.socket, targetHose.node), node)
			setTranslation(node, 0, 0, 0)
			setRotation(node, 0, 0, 0)
			targetObject:addAllSubWashableNodes(node)

			targetHose.adapter.node = node
			targetHose.adapter.refNode = referenceNode
			targetHose.adapter.isLinked = true
		end

		sourceHose.targetNode = targetHose.adapter.refNode

		setVisibility(sourceHose.visibilityNode, true)
		setShaderParameter(sourceHose.hoseNode, "cv0", 0, 0, -sourceHose.startStraightening, 1, false)

		sourceHose.endStraightening = sourceHose.endStraighteningBase * targetHose.straighteningFactor
		sourceHose.endStraighteningDirection = targetHose.straighteningDirection or sourceHose.endStraighteningDirectionBase

		ObjectChangeUtil.setObjectChanges(targetHose.objectChanges, true)
		ObjectChangeUtil.setObjectChanges(sourceHose.objectChanges, true)
		g_connectionHoseManager:openSocket(sourceHose.socket)
		g_connectionHoseManager:openSocket(targetHose.socket)
		self:updateConnectionHose(sourceHose, 0)
		table.insert(spec.updateableHoses, sourceHose)

		return true
	end

	return false
end

function ConnectionHoses:disconnectHose(hose)
	local spec = self.spec_connectionHoses
	local target = hose.targetHose

	if target ~= nil then
		hose.connectedObject:updateToolConnectionHose(self, hose, hose.connectedObject, target, false)

		local hoseHasSkipNodeTarget = target.isSkipNode ~= nil and target.isSkipNode
		local hoseIsFromSkipNodeTarget = hose.isClonedSkipNodeHose ~= nil and hose.isClonedSkipNodeHose

		if hoseHasSkipNodeTarget or hoseIsFromSkipNodeTarget then
			if hose.parentVehicle ~= nil and hose.parentHose ~= nil then
				hose.parentHose.childVehicle = nil
				hose.parentHose.childHose = nil

				hose.parentVehicle:disconnectHose(hose.parentHose)
			end

			if hose.childVehicle ~= nil and hose.childHose ~= nil then
				hose.childHose.parentVehicle = nil
				hose.childHose.parentHose = nil

				hose.childVehicle:disconnectHose(hose.childHose)
			end

			target.parentHose = nil
		end

		if target.adapter ~= nil and target.adapter.isLinked ~= nil and target.adapter.isLinked then
			hose.connectedObject:removeAllSubWashableNodes(target.adapter.node)
			delete(target.adapter.node)

			target.adapter.node = target.node
			target.adapter.refNode = target.node
			target.adapter.isLinked = false
		end

		setVisibility(hose.visibilityNode, false)
		ObjectChangeUtil.setObjectChanges(target.objectChanges, false)
		ObjectChangeUtil.setObjectChanges(hose.objectChanges, false)
		g_connectionHoseManager:closeSocket(hose.socket)
		g_connectionHoseManager:closeSocket(target.socket)

		target.connectedObject = nil
		hose.connectedObject = nil
		hose.targetHose = nil

		table.removeElement(spec.updateableHoses, hose)
	end
end

function ConnectionHoses:updateToolConnectionHose(sourceObject, sourceHose, targetObject, targetHose, visibility)
	local spec = self.spec_connectionHoses

	local function setTargetNodeTranslation(hose)
		if hose.originalNodeTranslation == nil then
			hose.originalNodeTranslation = {
				getTranslation(hose.node)
			}
		else
			setTranslation(hose.node, unpack(hose.originalNodeTranslation))
		end

		local wx, wy, wz = localToWorld(hose.node, 0, sourceHose.diameter * 0.5, 0)
		local lx, ly, lz = worldToLocal(getParent(hose.node), wx, wy, wz)

		setTranslation(hose.node, lx, ly, lz)
	end

	local toolConnectionHose = spec.targetNodeToToolConnection[targetHose.index]

	if toolConnectionHose ~= nil then
		local opositTargetIndex = toolConnectionHose.startTargetNodeIndex

		if opositTargetIndex == targetHose.index then
			opositTargetIndex = toolConnectionHose.endTargetNodeIndex
		end

		local opositTarget = spec.targetNodes[opositTargetIndex]

		if opositTarget ~= nil then
			if visibility and toolConnectionHose.delayedMounting ~= nil and toolConnectionHose.delayedMounting.sourceHose.connectedObject == nil then
				local differentSource = toolConnectionHose.delayedMounting.sourceObject ~= sourceObject
				local sameType = toolConnectionHose.delayedMounting.sourceHose.type == sourceHose.type and toolConnectionHose.delayedMounting.sourceHose.specType == sourceHose.specType

				if differentSource and sameType then
					local x, y, z = localToLocal(targetHose.node, opositTarget.node, 0, 0, 0)
					local length = MathUtil.vector3Length(x, y, z)

					if toolConnectionHose.additionalHose then
						local hose, _, _, _ = g_connectionHoseManager:getClonedHoseNode(sourceHose.type, sourceHose.hoseType, length, sourceHose.diameter, sourceHose.color, self.customEnvironment)

						if hose ~= nil then
							link(targetHose.node, hose)
							setTranslation(hose, 0, 0, 0)

							local dirX, dirY, dirZ = localToLocal(hose, opositTarget.node, 0, 0, 0)

							if dirX ~= 0 or dirY ~= nil or dirZ ~= nil then
								setDirection(hose, dirX, dirY, dirZ, 0, 0, 1)
								setShaderParameter(hose, "cv0", 0, 0, -dirZ * 0.5, 0, false)
								setShaderParameter(hose, "cv2", dirX * 0.5 + 0.003, dirY * 0.5, dirZ * 0.5, 0, false)
								setShaderParameter(hose, "cv3", dirX - 0.003, dirY, dirZ, 0, false)
								setShaderParameter(hose, "cv4", dirX - 0.003, dirY, dirZ + dirZ * 0.5, 0, false)
							end

							if toolConnectionHose.moveNodes then
								setTargetNodeTranslation(targetHose)
								setTargetNodeTranslation(opositTarget)
							end

							sourceObject:addAllSubWashableNodes(hose)

							toolConnectionHose.hoseNode = hose
							toolConnectionHose.hoseNodeObject = sourceObject
						else
							return false
						end
					end

					toolConnectionHose.connected = true

					if toolConnectionHose.mountingNode ~= nil then
						setVisibility(toolConnectionHose.mountingNode, true)
					end

					if toolConnectionHose.delayedMounting ~= nil then
						toolConnectionHose.delayedUnmounting = {}

						table.insert(toolConnectionHose.delayedUnmounting, toolConnectionHose.delayedMounting)
						table.insert(toolConnectionHose.delayedUnmounting, {
							sourceObject = sourceObject,
							sourceHose = sourceHose,
							targetObject = targetObject,
							targetHose = targetHose
						})

						local delayedHose = toolConnectionHose.delayedMounting
						toolConnectionHose.delayedMounting = nil

						delayedHose.sourceObject:connectHose(delayedHose.sourceHose, delayedHose.targetObject, delayedHose.targetHose, false)
						delayedHose.sourceObject:retryHoseSkipNodeConnections(false)
					end

					return true
				end
			elseif toolConnectionHose.connected then
				toolConnectionHose.connected = false

				if toolConnectionHose.hoseNode ~= nil then
					toolConnectionHose.hoseNodeObject:removeAllSubWashableNodes(toolConnectionHose.hoseNode)
					delete(toolConnectionHose.hoseNode)

					toolConnectionHose.hoseNode = nil
					toolConnectionHose.hoseNodeObject = nil
				end

				if toolConnectionHose.mountingNode ~= nil then
					setVisibility(toolConnectionHose.mountingNode, false)
				end

				if toolConnectionHose.delayedUnmounting ~= nil then
					for _, hose in ipairs(toolConnectionHose.delayedUnmounting) do
						if sourceHose ~= hose.sourceHose then
							hose.sourceObject:disconnectHose(hose.sourceHose)

							if hose.sourceHose.isClonedSkipNodeHose == nil or not hose.sourceHose.isClonedSkipNodeHose then
								toolConnectionHose.delayedMounting = hose
							end
						end
					end

					toolConnectionHose.delayedUnmounting = nil
				end
			end
		end
	else
		return true
	end

	return false
end

function ConnectionHoses:addHoseToDelayedMountings(sourceObject, sourceHose, targetObject, targetHose)
	local spec = self.spec_connectionHoses
	local toolConnectionHose = spec.targetNodeToToolConnection[targetHose.index]

	if toolConnectionHose ~= nil and (toolConnectionHose.delayedMounting == nil or sourceHose.typedIndex == toolConnectionHose.typedIndex) then
		local retry = toolConnectionHose.delayedMounting == nil
		toolConnectionHose.delayedMounting = {
			sourceObject = sourceObject,
			sourceHose = sourceHose,
			targetObject = targetObject,
			targetHose = targetHose
		}

		if retry then
			self.rootVehicle:retryHoseSkipNodeConnections(true, sourceObject)
		end
	end
end

function ConnectionHoses:connectHoseToSkipNode(sourceHose, targetObject, skipNode, childHose, childVehicle)
	local spec = self.spec_connectionHoses
	skipNode.connectedObject = self
	sourceHose.connectedObject = targetObject
	sourceHose.targetHose = skipNode
	sourceHose.targetNode = skipNode.node

	setVisibility(sourceHose.visibilityNode, true)
	setShaderParameter(sourceHose.hoseNode, "cv0", 0, 0, -sourceHose.startStraightening, 1, false)
	ObjectChangeUtil.setObjectChanges(sourceHose.objectChanges, true)
	self:addAllSubWashableNodes(sourceHose.hoseNode)

	sourceHose.childVehicle = childVehicle
	sourceHose.childHose = childHose

	if self.getAttacherVehicle ~= nil then
		local attacherVehicle1 = self:getAttacherVehicle()

		if attacherVehicle1.getAttacherVehicle ~= nil then
			local attacherVehicle2 = attacherVehicle1:getAttacherVehicle()

			if attacherVehicle2 ~= nil then
				local attacherJointIndex = attacherVehicle2:getAttacherJointIndexFromObject(attacherVehicle1)
				local implement = attacherVehicle2:getImplementFromAttacherJointIndex(attacherJointIndex)

				if implement.inputJointDescIndex == skipNode.inputAttacherJointIndex then
					local firstValidTarget, isSkipNode = attacherVehicle2:getConnectionTarget(attacherJointIndex, skipNode.type, skipNode.specType)

					if firstValidTarget ~= nil then
						local hose = attacherVehicle1:getClonedSkipHoseNode(sourceHose, skipNode)

						if not isSkipNode then
							attacherVehicle1:connectHose(hose, attacherVehicle2, firstValidTarget)
						else
							attacherVehicle1:connectHoseToSkipNode(hose, attacherVehicle2, firstValidTarget, sourceHose, attacherVehicle1)
						end

						if skipNode.parentHose ~= nil then
							skipNode.parentVehicle:removeWashableNode(skipNode.parentHose.hoseNode)
							delete(skipNode.parentHose.hoseNode)
							table.removeElement(spec.updateableHoses, skipNode.parentHose.childHose)
						end

						skipNode.parentVehicle = attacherVehicle1
						skipNode.parentHose = hose
						sourceHose.parentVehicle = attacherVehicle1
						sourceHose.parentHose = hose
						hose.childVehicle = self
						hose.childHose = sourceHose

						attacherVehicle1:addAllSubWashableNodes(hose.hoseNode)
					elseif skipNode.parentHose ~= nil then
						sourceHose.parentVehicle = skipNode.parentVehicle
						sourceHose.parentHose = skipNode.parentHose
						sourceHose.parentHose.childVehicle = self
						sourceHose.parentHose.childHose = sourceHose
					end
				end
			end
		end
	end

	table.insert(spec.updateableHoses, sourceHose)

	return true
end

function ConnectionHoses:connectHosesToAttacherVehicle(attacherVehicle, inputJointDescIndex, jointDescIndex, updateToolConnections, excludeVehicle)
	if attacherVehicle.getConnectionTarget ~= nil then
		local hoses = self:getConnectionHosesByInputAttacherJoint(inputJointDescIndex)

		for _, hose in ipairs(hoses) do
			attacherVehicle:iterateConnectionTargets(function (target, isSkipNode)
				if not self:getIsConnectionHoseUsed(hose) then
					if not isSkipNode then
						if self:connectHose(hose, attacherVehicle, target, updateToolConnections) then
							return false
						end
					elseif self:connectHoseToSkipNode(hose, attacherVehicle, target) then
						return false
					end

					return true
				end

				return false
			end, jointDescIndex, hose.type, hose.specType)
		end

		self:retryHoseSkipNodeConnections(updateToolConnections, excludeVehicle)
	end
end

function ConnectionHoses:retryHoseSkipNodeConnections(updateToolConnections, excludeVehicle)
	if self.getAttachedImplements ~= nil then
		local attachedImplements = self:getAttachedImplements()

		for _, implement in ipairs(attachedImplements) do
			local object = implement.object

			if object ~= excludeVehicle and object.connectHosesToAttacherVehicle ~= nil then
				object:connectHosesToAttacherVehicle(self, implement.inputJointDescIndex, implement.jointDescIndex, updateToolConnections, excludeVehicle)
			end
		end
	end
end

function ConnectionHoses:connectCustomHosesToAttacherVehicle(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_connectionHoses
	local customHoses = spec.customHosesByInputAttacher[inputJointDescIndex]

	if customHoses ~= nil then
		for i = 1, #customHoses do
			local customHose = customHoses[i]

			if not customHose.isActive and attacherVehicle.spec_connectionHoses ~= nil then
				local customTargets = attacherVehicle.spec_connectionHoses.customHoseTargetsByAttacher[jointDescIndex]

				if customTargets ~= nil then
					for j = 1, #customTargets do
						local customTarget = customTargets[j]

						if not customTarget.isActive and customHose.type == customTarget.type and customHose.specType == customTarget.specType then
							self:connectCustomHoseNode(customHose, customTarget)
						end
					end
				end
			end
		end
	end

	local customTargets = spec.customHoseTargetsByInputAttacher[inputJointDescIndex]

	if customTargets ~= nil then
		for i = 1, #customTargets do
			local customTarget = customTargets[i]

			if not customTarget.isActive and attacherVehicle.spec_connectionHoses ~= nil then
				customHoses = attacherVehicle.spec_connectionHoses.customHosesByAttacher[jointDescIndex]

				if customHoses ~= nil then
					for j = 1, #customHoses do
						local customHose = customHoses[j]

						if not customHose.isActive and customHose.type == customTarget.type and customHose.specType == customTarget.specType then
							self:connectCustomHoseNode(customHose, customTarget)
						end
					end
				end
			end
		end
	end
end

function ConnectionHoses:connectCustomHoseNode(customHose, customTarget)
	self:updateCustomHoseNode(customHose, customTarget)

	customHose.isActive = true
	customTarget.isActive = true
	customHose.connectedTarget = customTarget
	customTarget.connectedHose = customHose

	ObjectChangeUtil.setObjectChanges(customHose.objectChanges, true)
	ObjectChangeUtil.setObjectChanges(customTarget.objectChanges, true)
end

function ConnectionHoses:updateCustomHoseNode(customHose, customTarget)
	setTranslation(customHose.node, localToLocal(customTarget.node, getParent(customHose.node), 0, 0, 0))
	setRotation(customHose.node, localRotationToLocal(customTarget.node, getParent(customHose.node), 0, 0, 0))
end

function ConnectionHoses:disconnectCustomHoseNode(customHose, customTarget)
	setTranslation(customHose.node, unpack(customHose.startTranslation))
	setRotation(customHose.node, unpack(customHose.startRotation))

	customHose.isActive = false
	customTarget.isActive = false
	customHose.connectedTarget = nil
	customTarget.connectedHose = nil

	ObjectChangeUtil.setObjectChanges(customHose.objectChanges, false)
	ObjectChangeUtil.setObjectChanges(customTarget.objectChanges, false)
end

function ConnectionHoses:loadExtraDependentParts(superFunc, xmlFile, baseName, entry)
	if not superFunc(self, xmlFile, baseName, entry) then
		return false
	end

	local customHoseIndices = xmlFile:getValue(baseName .. ".connectionHoses#customHoseIndices", nil, true)

	if #customHoseIndices > 0 then
		entry.customHoseIndices = customHoseIndices
	end

	local customTargetIndices = xmlFile:getValue(baseName .. ".connectionHoses#customTargetIndices", nil, true)

	if #customTargetIndices > 0 then
		entry.customTargetIndices = customTargetIndices
	end

	return true
end

function ConnectionHoses:updateExtraDependentParts(superFunc, part, dt)
	superFunc(self, part, dt)

	if part.customHoseIndices ~= nil then
		local spec = self.spec_connectionHoses

		for i = 1, #part.customHoseIndices do
			local customHoseIndex = part.customHoseIndices[i]
			local customHose = spec.customHoses[customHoseIndex]

			if customHose ~= nil and customHose.isActive then
				self:updateCustomHoseNode(customHose, customHose.connectedTarget)
			end
		end
	end

	if part.customTargetIndices ~= nil then
		local spec = self.spec_connectionHoses

		for i = 1, #part.customTargetIndices do
			local customTargetIndex = part.customTargetIndices[i]
			local customTarget = spec.customHoseTargets[customTargetIndex]

			if customTarget ~= nil and customTarget.isActive then
				self:updateCustomHoseNode(customTarget.connectedHose, customTarget)
			end
		end
	end
end

function ConnectionHoses:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	self:connectHosesToAttacherVehicle(attacherVehicle, inputJointDescIndex, jointDescIndex)
	self:connectCustomHosesToAttacherVehicle(attacherVehicle, inputJointDescIndex, jointDescIndex)
end

function ConnectionHoses:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_connectionHoses
	local inputJointDescIndex = self:getActiveInputAttacherJointDescIndex()
	local hoses = self:getConnectionHosesByInputAttacherJoint(inputJointDescIndex)

	for _, hose in ipairs(hoses) do
		self:disconnectHose(hose)
	end

	for i = #spec.updateableHoses, 1, -1 do
		local hose = spec.updateableHoses[i]

		if hose.connectedObject == attacherVehicle then
			self:disconnectHose(hose)
		end
	end

	local attacherVehicleSpec = attacherVehicle.spec_connectionHoses

	if attacherVehicleSpec ~= nil then
		for _, toolConnector in pairs(attacherVehicleSpec.toolConnectorHoses) do
			if toolConnector.delayedMounting ~= nil and toolConnector.delayedMounting.sourceObject == self then
				toolConnector.delayedMounting = nil
			end
		end
	end

	local customHoses = spec.customHosesByInputAttacher[inputJointDescIndex]

	if customHoses ~= nil then
		for i = 1, #customHoses do
			local customHose = customHoses[i]

			if customHose.isActive then
				self:disconnectCustomHoseNode(customHose, customHose.connectedTarget)
			end
		end
	end

	local customTargets = spec.customHoseTargetsByInputAttacher[inputJointDescIndex]

	if customTargets ~= nil then
		for i = 1, #customTargets do
			local customTarget = customTargets[i]

			if customTarget.isActive then
				self:disconnectCustomHoseNode(customTarget.connectedHose, customTarget)
			end
		end
	end
end
