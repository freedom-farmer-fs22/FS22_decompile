RandomlyMovingParts = {
	DEFAULT_MAX_UPDATE_DISTANCE = 100,
	RANDOMLY_MOVING_PART_XML_KEY = "vehicle.randomlyMovingParts.randomlyMovingPart(?)",
	prerequisitesPresent = function (specializations)
		return true
	end
}

function RandomlyMovingParts.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("RandomlyMovingParts")
	schema:register(XMLValueType.FLOAT, "vehicle.randomlyMovingParts#maxUpdateDistance", RandomlyMovingParts.DEFAULT_MAX_UPDATE_DISTANCE)
	schema:register(XMLValueType.NODE_INDEX, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#node", "Node")
	schema:register(XMLValueType.INT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#refNodeIndex", "Ground reference node index")
	schema:register(XMLValueType.VECTOR_ROT_2, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#rotMean", "Rotation mean")
	schema:register(XMLValueType.INT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#rotAxis", "Rotation axis")
	schema:register(XMLValueType.VECTOR_ROT_2, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#rotVariance", "Rotation variance")
	schema:register(XMLValueType.VECTOR_2, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#rotTimeMean", "Rotation time mean")
	schema:register(XMLValueType.VECTOR_2, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#rotTimeVariance", "Rotation time variance")
	schema:register(XMLValueType.VECTOR_2, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#pauseMean", "Pause time variance")
	schema:register(XMLValueType.VECTOR_2, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#pauseVariance", "Pause time variance")
	schema:register(XMLValueType.BOOL, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#isSpeedDependent", "Is speed dependent")
	schema:register(XMLValueType.NODE_INDEX, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#node", "Node to apply the same random angle")
	schema:register(XMLValueType.INT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#rotAxis", "Rotation axis")
	schema:register(XMLValueType.FLOAT, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. ".node(?)#scale", "Rotation Scale")
	schema:setXMLSpecializationType()
end

function RandomlyMovingParts.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadRandomlyMovingPartFromXML", RandomlyMovingParts.loadRandomlyMovingPartFromXML)
	SpecializationUtil.registerFunction(vehicleType, "updateRandomlyMovingPart", RandomlyMovingParts.updateRandomlyMovingPart)
	SpecializationUtil.registerFunction(vehicleType, "updateRotationTargetValues", RandomlyMovingParts.updateRotationTargetValues)
	SpecializationUtil.registerFunction(vehicleType, "getIsRandomlyMovingPartActive", RandomlyMovingParts.getIsRandomlyMovingPartActive)
end

function RandomlyMovingParts.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", RandomlyMovingParts)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", RandomlyMovingParts)
end

function RandomlyMovingParts:onLoad(savegame)
	local spec = self.spec_randomlyMovingParts
	spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.randomlyMovingParts#maxUpdateDistance", RandomlyMovingParts.DEFAULT_MAX_UPDATE_DISTANCE)
	spec.nodes = {}
	local i = 0

	while true do
		local baseName = string.format("vehicle.randomlyMovingParts.randomlyMovingPart(%d)", i)

		if not self.xmlFile:hasProperty(baseName) then
			break
		end

		local randomlyMovingPart = {}

		if self:loadRandomlyMovingPartFromXML(randomlyMovingPart, self.xmlFile, baseName) then
			table.insert(spec.nodes, randomlyMovingPart)
		end

		i = i + 1
	end

	if not self.isClient or #spec.nodes == 0 then
		SpecializationUtil.removeEventListener(self, "onUpdate", RandomlyMovingParts)
	end
end

function RandomlyMovingParts:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_randomlyMovingParts

	if self.currentUpdateDistance < spec.maxUpdateDistance then
		for _, part in pairs(spec.nodes) do
			self:updateRandomlyMovingPart(part, dt)
		end
	end
end

function RandomlyMovingParts:loadRandomlyMovingPartFromXML(part, xmlFile, key)
	if not self.xmlFile:hasProperty(key) then
		return false
	end

	local function isRotAxisValid(value)
		return value ~= nil and value >= 1 and value <= 3
	end

	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")

	local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if node == nil then
		Logging.xmlWarning(self.xmlFile, "Unknown node for randomlyMovingPart in '%s'", key)

		return false
	end

	part.node = node

	if self.getGroundReferenceNodeFromIndex ~= nil then
		local refNodeIndex = xmlFile:getValue(key .. "#refNodeIndex")

		if refNodeIndex ~= nil then
			if refNodeIndex ~= 0 then
				local groundReferenceNode = self:getGroundReferenceNodeFromIndex(refNodeIndex)

				if groundReferenceNode ~= nil then
					part.groundReferenceNode = groundReferenceNode
				end
			else
				Logging.xmlWarning(self.xmlFile, "Unknown ground reference node in '%s'! Indices start with '0'", key .. "#refNodeIndex")
			end
		end
	end

	local rx, ry, rz = getRotation(part.node)
	local rotMean = xmlFile:getValue(key .. "#rotMean", nil, true)

	if rotMean then
		part.rotOrig = {
			rx,
			ry,
			rz
		}
		part.rotCur = {
			rx,
			ry,
			rz
		}
		part.rotAxis = xmlFile:getValue(key .. "#rotAxis")

		if not isRotAxisValid(part.rotAxis) then
			Logging.xmlWarning(xmlFile, "Invalid rot axis '%s' given for node '%s'. Only '1', '2' or '3' are allowed!", part.rotAxis, key)

			return false
		end

		part.rotMean = rotMean
		part.rotVar = xmlFile:getValue(key .. "#rotVariance", nil, true)
		part.rotTimeMean = xmlFile:getValue(key .. "#rotTimeMean", nil, true)
		part.rotTimeVar = xmlFile:getValue(key .. "#rotTimeVariance", nil, true)
		part.pauseMean = xmlFile:getValue(key .. "#pauseMean", nil, true)
		part.pauseVar = xmlFile:getValue(key .. "#pauseVariance", nil, true)

		for i = 1, 2 do
			part.rotTimeMean[i] = part.rotTimeMean[i] * 1000
			part.rotTimeVar[i] = part.rotTimeVar[i] * 1000
			part.pauseMean[i] = part.pauseMean[i] * 1000
			part.pauseVar[i] = part.pauseVar[i] * 1000
		end

		part.rotTarget = {}
		part.rotSpeed = {}
		part.pause = {}
		part.isSpeedDependent = xmlFile:getValue(key .. "#isSpeedDependent", false)

		self:updateRotationTargetValues(part)
	end

	part.nodes = {}

	xmlFile:iterate(key .. ".node", function (index, nodeKey)
		local entry = {
			node = xmlFile:getValue(nodeKey .. "#node", nil, self.components, self.i3dMappings)
		}

		if entry.node ~= nil then
			entry.rotAxis = xmlFile:getValue(nodeKey .. "#rotAxis")

			if entry.rotAxis ~= nil then
				if not isRotAxisValid(entry.rotAxis) then
					Logging.xmlWarning(xmlFile, "Invalid rot axis '%s' given for node '%s'. Only '1', '2' or '3' are allowed!", entry.rotAxis, nodeKey)

					return
				else
					entry.currentRot = {
						getRotation(entry.node)
					}
				end
			end

			entry.scale = xmlFile:getValue(nodeKey .. "#scale", 1)

			table.insert(part.nodes, entry)
		end
	end)

	part.nextMoveTime = g_currentMission.time + part.pause[2]
	part.curMoveDirection = 1
	part.isActive = true

	return true
end

function RandomlyMovingParts:updateRandomlyMovingPart(part, dt)
	if part.nextMoveTime < g_currentMission.time then
		local speed = dt

		if part.isSpeedDependent then
			speed = speed * math.min(self:getLastSpeed() / self:getRawSpeedLimit(), 1)
		end

		part.isActive = self:getIsRandomlyMovingPartActive(part)

		if part.curMoveDirection > 0 then
			if part.isActive then
				part.rotCur[part.rotAxis] = math.min(part.rotTarget[1], part.rotCur[part.rotAxis] + part.rotSpeed[1] * speed)

				if part.rotCur[part.rotAxis] == part.rotTarget[1] then
					part.curMoveDirection = -1
					part.nextMoveTime = g_currentMission.time + part.pause[1]
				end
			end
		else
			part.rotCur[part.rotAxis] = math.max(part.rotTarget[2], part.rotCur[part.rotAxis] + part.rotSpeed[2] * speed)

			if part.rotCur[part.rotAxis] == part.rotTarget[2] and part.isActive then
				part.curMoveDirection = 1
				part.nextMoveTime = g_currentMission.time + part.pause[2]

				self:updateRotationTargetValues(part)
			end
		end

		setRotation(part.node, part.rotCur[1], part.rotCur[2], part.rotCur[3])

		for i = 1, #part.nodes do
			local nodeData = part.nodes[i]

			if nodeData.rotAxis ~= nil then
				nodeData.currentRot[nodeData.rotAxis] = part.rotCur[part.rotAxis] * nodeData.scale

				setRotation(nodeData.node, nodeData.currentRot[1], nodeData.currentRot[2], nodeData.currentRot[3])
			else
				setRotation(nodeData.node, part.rotCur[1] * nodeData.scale, part.rotCur[2] * nodeData.scale, part.rotCur[3] * nodeData.scale)
			end
		end

		if self.setMovingToolDirty ~= nil then
			self:setMovingToolDirty(part.node)
		end

		return true
	else
		return false
	end
end

function RandomlyMovingParts:updateRotationTargetValues(part)
	for i = 1, 2 do
		part.rotTarget[i] = part.rotMean[i] + part.rotVar[i] * (-0.5 + math.random())
	end

	for i = 1, 2 do
		local rotTime = part.rotTimeMean[i] + part.rotTimeVar[i] * (-0.5 + math.random())

		if i == 1 then
			part.rotSpeed[i] = (part.rotTarget[1] - part.rotTarget[2]) / rotTime
		else
			part.rotSpeed[i] = (part.rotTarget[2] - part.rotTarget[1]) / rotTime
		end
	end

	for i = 1, 2 do
		part.pause[i] = part.pauseMean[i] + part.pauseVar[i] * (-0.5 + math.random())
	end
end

function RandomlyMovingParts:getIsRandomlyMovingPartActive(part)
	local retValue = true

	if part.groundReferenceNode ~= nil then
		retValue = self:getIsGroundReferenceNodeActive(part.groundReferenceNode)
	end

	return retValue
end
