Washable = {
	SEND_NUM_BITS = 6
}
Washable.SEND_MAX_VALUE = 2^Washable.SEND_NUM_BITS - 1
Washable.SEND_THRESHOLD = 1 / Washable.SEND_MAX_VALUE
Washable.WASHTYPE_HIGH_PRESSURE_WASHER = 1
Washable.WASHTYPE_RAIN = 2
Washable.WASHTYPE_TRIGGER = 3

function Washable.prerequisitesPresent(specializations)
	return true
end

function Washable.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Washable")
	schema:register(XMLValueType.FLOAT, "vehicle.washable#dirtDuration", "Duration until fully dirty (minutes)", 90)
	schema:register(XMLValueType.FLOAT, "vehicle.washable#washDuration", "Duration until fully clean (minutes)", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.washable#workMultiplier", "Multiplier while working", 4)
	schema:register(XMLValueType.FLOAT, "vehicle.washable#fieldMultiplier", "Multiplier while on field", 2)
	schema:register(XMLValueType.STRING, "vehicle.washable#blockedWashTypes", "Block specific ways to clean vehicle (HIGH_PRESSURE_WASHER, RAIN, TRIGGER)")
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame

	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).washable.dirtNode(?)#amount", "Dirt amount")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).washable.dirtNode(?)#snowScale", "Snow scale")
end

function Washable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "updateDirtAmount", Washable.updateDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "addDirtAmount", Washable.addDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "getDirtAmount", Washable.getDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "setNodeDirtAmount", Washable.setNodeDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "getNodeDirtAmount", Washable.getNodeDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "setNodeDirtColor", Washable.setNodeDirtColor)
	SpecializationUtil.registerFunction(vehicleType, "addAllSubWashableNodes", Washable.addAllSubWashableNodes)
	SpecializationUtil.registerFunction(vehicleType, "addWashableNodes", Washable.addWashableNodes)
	SpecializationUtil.registerFunction(vehicleType, "validateWashableNode", Washable.validateWashableNode)
	SpecializationUtil.registerFunction(vehicleType, "addToGlobalWashableNode", Washable.addToGlobalWashableNode)
	SpecializationUtil.registerFunction(vehicleType, "getWashableNodeByCustomIndex", Washable.getWashableNodeByCustomIndex)
	SpecializationUtil.registerFunction(vehicleType, "addToLocalWashableNode", Washable.addToLocalWashableNode)
	SpecializationUtil.registerFunction(vehicleType, "removeAllSubWashableNodes", Washable.removeAllSubWashableNodes)
	SpecializationUtil.registerFunction(vehicleType, "removeWashableNode", Washable.removeWashableNode)
	SpecializationUtil.registerFunction(vehicleType, "getDirtMultiplier", Washable.getDirtMultiplier)
	SpecializationUtil.registerFunction(vehicleType, "getWorkDirtMultiplier", Washable.getWorkDirtMultiplier)
	SpecializationUtil.registerFunction(vehicleType, "getWashDuration", Washable.getWashDuration)
	SpecializationUtil.registerFunction(vehicleType, "getAllowsWashingByType", Washable.getAllowsWashingByType)
end

function Washable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Washable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Washable)
end

function Washable:onLoad(savegame)
	local spec = self.spec_washable
	spec.washableNodes = {}
	spec.washableNodesByIndex = {}

	self:addToLocalWashableNode(nil, Washable.updateDirtAmount, nil, )

	spec.globalWashableNode = spec.washableNodes[1]
	spec.dirtDuration = self.xmlFile:getValue("vehicle.washable#dirtDuration", 90) * 60 * 1000

	if spec.dirtDuration ~= 0 then
		spec.dirtDuration = 1 / spec.dirtDuration
	end

	spec.washDuration = math.max(self.xmlFile:getValue("vehicle.washable#washDuration", 1) * 60 * 1000, 1e-05)
	spec.workMultiplier = self.xmlFile:getValue("vehicle.washable#workMultiplier", 4)
	spec.fieldMultiplier = self.xmlFile:getValue("vehicle.washable#fieldMultiplier", 2)
	spec.blockedWashTypes = {}
	local blockedWashTypesStr = self.xmlFile:getValue("vehicle.washable#blockedWashTypes")

	if blockedWashTypesStr ~= nil then
		local blockedWashTypes = blockedWashTypesStr:split(" ")

		for _, typeStr in pairs(blockedWashTypes) do
			typeStr = "WASHTYPE_" .. typeStr

			if Washable[typeStr] ~= nil then
				spec.blockedWashTypes[Washable[typeStr]] = true
			else
				Logging.xmlWarning(self.xmlFile, "Unknown wash type '%s' in '%s'", typeStr, "vehicle.washable#blockedWashTypes")
			end
		end
	end

	spec.lastDirtMultiplier = 0
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function Washable:onLoadFinished(savegame)
	local spec = self.spec_washable

	for _, component in pairs(self.components) do
		self:addAllSubWashableNodes(component.node)
	end

	if savegame ~= nil and Washable.getIntervalMultiplier() ~= 0 then
		for i = 1, #spec.washableNodes do
			local nodeData = spec.washableNodes[i]
			local nodeKey = string.format("%s.washable.dirtNode(%d)", savegame.key, i - 1)
			local amount = savegame.xmlFile:getValue(nodeKey .. "#amount", 0)

			self:setNodeDirtAmount(nodeData, amount, true)

			if nodeData.loadFromSavegameFunc ~= nil then
				nodeData.loadFromSavegameFunc(savegame.xmlFile, nodeKey)
			end
		end
	else
		for i = 1, #spec.washableNodes do
			local nodeData = spec.washableNodes[i]

			self:setNodeDirtAmount(nodeData, 0, true)
		end
	end
end

function Washable:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_washable

	for i = 1, #spec.washableNodes do
		local nodeData = spec.washableNodes[i]
		local nodeKey = string.format("%s.dirtNode(%d)", key, i - 1)

		xmlFile:setValue(nodeKey .. "#amount", nodeData.dirtAmount)

		if nodeData.saveToSavegameFunc ~= nil then
			nodeData.saveToSavegameFunc(xmlFile, nodeKey)
		end
	end
end

function Washable:onReadStream(streamId, connection)
	Washable.readWashableNodeData(self, streamId, connection)
end

function Washable:onWriteStream(streamId, connection)
	Washable.writeWashableNodeData(self, streamId, connection)
end

function Washable:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_washable

		if spec.washableNodes ~= nil and streamReadBool(streamId) then
			Washable.readWashableNodeData(self, streamId, connection)
		end
	end
end

function Washable:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_washable

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			Washable.writeWashableNodeData(self, streamId, connection)
		end
	end
end

function Washable:readWashableNodeData(streamId, connection)
	local spec = self.spec_washable

	for i = 1, #spec.washableNodes do
		local nodeData = spec.washableNodes[i]
		local dirtAmount = streamReadUIntN(streamId, Washable.SEND_NUM_BITS) / Washable.SEND_MAX_VALUE

		self:setNodeDirtAmount(nodeData, dirtAmount, true)

		if streamReadBool(streamId) then
			local r = streamReadUIntN(streamId, Washable.SEND_NUM_BITS) / Washable.SEND_MAX_VALUE
			local g = streamReadUIntN(streamId, Washable.SEND_NUM_BITS) / Washable.SEND_MAX_VALUE
			local b = streamReadUIntN(streamId, Washable.SEND_NUM_BITS) / Washable.SEND_MAX_VALUE

			self:setNodeDirtColor(nodeData, r, g, b, true)
		end
	end
end

function Washable:writeWashableNodeData(streamId, connection)
	local spec = self.spec_washable

	for i = 1, #spec.washableNodes do
		local nodeData = spec.washableNodes[i]

		streamWriteUIntN(streamId, math.floor(nodeData.dirtAmount * Washable.SEND_MAX_VALUE + 0.5), Washable.SEND_NUM_BITS)
		streamWriteBool(streamId, nodeData.colorChanged)

		if nodeData.colorChanged then
			streamWriteUIntN(streamId, math.floor(nodeData.color[1] * Washable.SEND_MAX_VALUE + 0.5), Washable.SEND_NUM_BITS)
			streamWriteUIntN(streamId, math.floor(nodeData.color[2] * Washable.SEND_MAX_VALUE + 0.5), Washable.SEND_NUM_BITS)
			streamWriteUIntN(streamId, math.floor(nodeData.color[3] * Washable.SEND_MAX_VALUE + 0.5), Washable.SEND_NUM_BITS)

			nodeData.colorChanged = false
		end
	end
end

function Washable:onUpdateTick(dt, isActive, isActiveForInput, isSelected)
	if self.isServer then
		local spec = self.spec_washable
		spec.lastDirtMultiplier = self:getDirtMultiplier() * Washable.getIntervalMultiplier() * Platform.gameplay.dirtDurationScale
		local allowsWashingByRain = self:getAllowsWashingByType(Washable.WASHTYPE_RAIN)
		local rainScale = 0
		local timeSinceLastRain = 0
		local temperature = 0

		if allowsWashingByRain then
			local weather = g_currentMission.environment.weather
			rainScale = weather:getRainFallScale()
			timeSinceLastRain = weather:getTimeSinceLastRain()
			temperature = weather:getCurrentTemperature()
		end

		for i = 1, #spec.washableNodes do
			local nodeData = spec.washableNodes[i]
			local changedAmount = nodeData.updateFunc(self, nodeData, dt, allowsWashingByRain, rainScale, timeSinceLastRain, temperature)

			if changedAmount ~= 0 then
				self:setNodeDirtAmount(nodeData, nodeData.dirtAmount + changedAmount)
			end
		end
	end
end

function Washable:updateDirtAmount(nodeData, dt, allowsWashingByRain, rainScale, timeSinceLastRain, temperature)
	local spec = self.spec_washable
	local change = 0

	if allowsWashingByRain and rainScale > 0.1 and timeSinceLastRain < 30 and temperature > 0 and nodeData.dirtAmount > 0.5 then
		change = -(dt / spec.washDuration)
	end

	local dirtMultiplier = spec.lastDirtMultiplier

	if dirtMultiplier ~= 0 then
		change = dt * spec.dirtDuration * dirtMultiplier
	end

	return change
end

function Washable:addDirtAmount(dirtAmount, force)
	local spec = self.spec_washable

	for i = 1, #spec.washableNodes do
		local nodeData = spec.washableNodes[i]

		self:setNodeDirtAmount(nodeData, nodeData.dirtAmount + dirtAmount, force)
	end
end

function Washable:getDirtAmount()
	local spec = self.spec_washable
	local dirtAmount = 0

	for i = 1, #spec.washableNodes do
		dirtAmount = dirtAmount + spec.washableNodes[i].dirtAmount
	end

	dirtAmount = dirtAmount / #spec.washableNodes

	return dirtAmount
end

function Washable:setNodeDirtAmount(nodeData, dirtAmount, force)
	local spec = self.spec_washable
	nodeData.dirtAmount = MathUtil.clamp(dirtAmount, 0, 1)
	local diff = nodeData.dirtAmountSent - nodeData.dirtAmount

	if Washable.SEND_THRESHOLD < math.abs(diff) or force then
		for i = 1, #nodeData.nodes do
			local node = nodeData.nodes[i]
			local x, _, z, w = getShaderParameter(node, "RDT")

			setShaderParameter(node, "RDT", x, nodeData.dirtAmount, z, w, false)
		end

		if self.isServer then
			self:raiseDirtyFlags(spec.dirtyFlag)

			nodeData.dirtAmountSent = nodeData.dirtAmount
		end
	end
end

function Washable:getNodeDirtAmount(nodeData)
	return nodeData.dirtAmount
end

function Washable:setNodeDirtColor(nodeData, r, g, b, force)
	local spec = self.spec_washable
	local cr = nodeData.color[1]
	local cg = nodeData.color[2]
	local cb = nodeData.color[3]

	if Washable.SEND_THRESHOLD < math.abs(r - cr) or Washable.SEND_THRESHOLD < math.abs(g - cg) or Washable.SEND_THRESHOLD < math.abs(b - cb) or force then
		for _, node in pairs(nodeData.nodes) do
			local _, _, _, w = getShaderParameter(node, "dirtColor")

			setShaderParameter(node, "dirtColor", r, g, b, w, false)
		end

		nodeData.color[3] = b
		nodeData.color[2] = g
		nodeData.color[1] = r

		if self.isServer then
			self:raiseDirtyFlags(spec.dirtyFlag)

			nodeData.colorChanged = true
		end
	end
end

function Washable:addAllSubWashableNodes(rootNode)
	if rootNode ~= nil then
		local nodes = {}

		I3DUtil.getNodesByShaderParam(rootNode, "RDT", nodes, true)
		self:addWashableNodes(nodes)
	end

	self:addDirtAmount(0, true)
end

function Washable:addWashableNodes(nodes)
	for _, node in ipairs(nodes) do
		local isGlobal, updateFunc, customIndex, extraParams = self:validateWashableNode(node)

		if isGlobal then
			self:addToGlobalWashableNode(node)
		elseif updateFunc ~= nil then
			self:addToLocalWashableNode(node, updateFunc, customIndex, extraParams)
		end
	end
end

function Washable:validateWashableNode(node)
	return true, nil
end

function Washable:addToGlobalWashableNode(node)
	local spec = self.spec_washable

	if spec.washableNodes[1] ~= nil then
		table.insert(spec.washableNodes[1].nodes, node)
	end
end

function Washable:getWashableNodeByCustomIndex(customIndex)
	return self.spec_washable.washableNodesByIndex[customIndex]
end

function Washable:addToLocalWashableNode(node, updateFunc, customIndex, extraParams)
	local spec = self.spec_washable
	local nodeData = {}

	if customIndex ~= nil then
		if spec.washableNodesByIndex[customIndex] ~= nil then
			table.insert(spec.washableNodesByIndex[customIndex].nodes, node)

			return
		else
			spec.washableNodesByIndex[customIndex] = nodeData
		end
	end

	nodeData.nodes = {
		node
	}
	nodeData.updateFunc = updateFunc
	nodeData.dirtAmount = 0
	nodeData.dirtAmountSent = 0
	nodeData.colorChanged = false
	local defaultColor, _ = g_currentMission.environment:getDirtColors()
	nodeData.color = {
		defaultColor[1],
		defaultColor[2],
		defaultColor[3]
	}
	nodeData.defaultColor = {
		defaultColor[1],
		defaultColor[2],
		defaultColor[3]
	}

	if extraParams ~= nil then
		for i, v in pairs(extraParams) do
			nodeData[i] = v
		end
	end

	table.insert(spec.washableNodes, nodeData)
end

function Washable:removeAllSubWashableNodes(rootNode)
	if rootNode ~= nil then
		local nodes = {}

		I3DUtil.getNodesByShaderParam(rootNode, "RDT", nodes)

		for _, node in pairs(nodes) do
			self:removeWashableNode(node)
		end
	end
end

function Washable:removeWashableNode(node)
	local spec = self.spec_washable

	if node ~= nil then
		for i = 1, #spec.washableNodes do
			local nodeData = spec.washableNodes[i]

			table.removeElement(nodeData.nodes, node)
		end
	end
end

function Washable:getDirtMultiplier()
	local spec = self.spec_washable
	local multiplier = 1

	if self:getLastSpeed() < 1 then
		multiplier = 0
	end

	if self:getIsOnField() then
		multiplier = multiplier * spec.fieldMultiplier
		local wetness = g_currentMission.environment.weather:getGroundWetness()

		if wetness > 0 then
			multiplier = multiplier * (1 + wetness)
		end
	end

	return multiplier
end

function Washable:getWorkDirtMultiplier()
	local spec = self.spec_washable

	return spec.workMultiplier
end

function Washable:getWashDuration()
	local spec = self.spec_washable

	return spec.washDuration
end

function Washable.getIntervalMultiplier()
	if g_currentMission.missionInfo.dirtInterval == 1 then
		return 0
	elseif g_currentMission.missionInfo.dirtInterval == 2 then
		return 0.25
	elseif g_currentMission.missionInfo.dirtInterval == 3 then
		return 0.5
	elseif g_currentMission.missionInfo.dirtInterval == 4 then
		return 1
	end
end

function Washable:getAllowsWashingByType(type)
	local spec = self.spec_washable

	return spec.blockedWashTypes[type] == nil
end

function Washable:updateDebugValues(values)
	local spec = self.spec_washable

	if spec.washableNodes ~= nil then
		for i, nodeData in ipairs(spec.washableNodes) do
			local changedAmount = nodeData.updateFunc(self, nodeData, 3600000)

			table.insert(values, {
				name = "WashableNode" .. i,
				value = string.format("%.4f a/h (%.2f) (color %.2f %.2f %.2f)", changedAmount, spec.washableNodes[i].dirtAmount, nodeData.color[1], nodeData.color[2], nodeData.color[3])
			})
		end
	end
end
