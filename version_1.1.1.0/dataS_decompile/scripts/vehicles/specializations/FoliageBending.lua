FoliageBending = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("FoliageBending")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.foliageBending.bendingNode(?)#node", "Bending node")
		schema:register(XMLValueType.FLOAT, "vehicle.foliageBending.bendingNode(?)#minX", "Min. width")
		schema:register(XMLValueType.FLOAT, "vehicle.foliageBending.bendingNode(?)#maxX", "Max. width")
		schema:register(XMLValueType.FLOAT, "vehicle.foliageBending.bendingNode(?)#minZ", "Min. length")
		schema:register(XMLValueType.FLOAT, "vehicle.foliageBending.bendingNode(?)#maxZ", "Max. length")
		schema:register(XMLValueType.FLOAT, "vehicle.foliageBending.bendingNode(?)#yOffset", "Y translation offset")
		schema:setXMLSpecializationType()
	end,
	postInitSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("FoliageBending")

		for name, _ in pairs(g_configurationManager:getConfigurations()) do
			local specializationKey = g_configurationManager:getConfigurationAttribute(name, "xmlKey")

			if specializationKey ~= nil then
				specializationKey = "." .. specializationKey
			else
				specializationKey = ""
			end

			local basePath = string.format("vehicle%s.%sConfigurations.%sConfiguration(?)", specializationKey, name, name)

			schema:setXMLSharedRegistration("foliageBendingModifier", basePath)
			schema:register(XMLValueType.INT, basePath .. ".foliageBendingModifier(?)#index", "Bending node index")
			schema:register(XMLValueType.VECTOR_N, basePath .. ".foliageBendingModifier(?)#indices", "Bending node indices")
			schema:register(XMLValueType.FLOAT, basePath .. ".foliageBendingModifier(?)#minX", "Min. width")
			schema:register(XMLValueType.FLOAT, basePath .. ".foliageBendingModifier(?)#maxX", "Max. width")
			schema:register(XMLValueType.FLOAT, basePath .. ".foliageBendingModifier(?)#minZ", "Min. length")
			schema:register(XMLValueType.FLOAT, basePath .. ".foliageBendingModifier(?)#maxZ", "Max. length")
			schema:register(XMLValueType.FLOAT, basePath .. ".foliageBendingModifier(?)#yOffset", "Y translation offset")
			schema:register(XMLValueType.BOOL, basePath .. ".foliageBendingModifier(?)#isActive", "Bending node is active", true)
			schema:register(XMLValueType.BOOL, basePath .. ".foliageBendingModifier(?)#overwrite", "Overwrite the bending node values and do not use the max values", true)
			schema:setXMLSharedRegistration()
		end

		schema:setXMLSpecializationType()
	end
}

function FoliageBending.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadBendingNodeFromXML", FoliageBending.loadBendingNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadBendingNodeModifierFromXML", FoliageBending.loadBendingNodeModifierFromXML)
	SpecializationUtil.registerFunction(vehicleType, "activateBendingNodes", FoliageBending.activateBendingNodes)
	SpecializationUtil.registerFunction(vehicleType, "deactivateBendingNodes", FoliageBending.deactivateBendingNodes)
	SpecializationUtil.registerFunction(vehicleType, "getFoliageBendingNodeByIndex", FoliageBending.getFoliageBendingNodeByIndex)
	SpecializationUtil.registerFunction(vehicleType, "updateFoliageBendingAttributes", FoliageBending.updateFoliageBendingAttributes)
end

function FoliageBending.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FoliageBending)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", FoliageBending)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", FoliageBending)
	SpecializationUtil.registerEventListener(vehicleType, "onActivate", FoliageBending)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", FoliageBending)
end

function FoliageBending:onLoad(savegame)
	local spec = self.spec_foliageBending
	spec.bendingNodes = {}
	local i = 0

	while true do
		local key = string.format("vehicle.foliageBending.bendingNode(%d)", i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local bendingNode = {}

		if self:loadBendingNodeFromXML(self.xmlFile, key, bendingNode) then
			table.insert(spec.bendingNodes, bendingNode)

			bendingNode.index = #spec.bendingNodes
		end

		i = i + 1
	end
end

function FoliageBending:onPostLoad(savegame)
	local spec = self.spec_foliageBending

	for name, _ in pairs(g_configurationManager:getConfigurations()) do
		local specializationKey = g_configurationManager:getConfigurationAttribute(name, "xmlKey")

		if specializationKey ~= nil then
			specializationKey = "." .. specializationKey
		else
			specializationKey = ""
		end

		local i = 0

		while true do
			local configrationKey = string.format("vehicle%s.%sConfigurations.%sConfiguration(%d)", specializationKey, name, name, i)

			if not self.xmlFile:hasProperty(configrationKey) then
				break
			end

			if self.configurations[name] ~= nil and self.configurations[name] == i + 1 then
				local j = 0

				while true do
					local modifierKey = string.format("%s.foliageBendingModifier(%d)", configrationKey, j)

					if not self.xmlFile:hasProperty(modifierKey) then
						break
					end

					self:loadBendingNodeModifierFromXML(self.xmlFile, modifierKey)

					j = j + 1
				end
			end

			i = i + 1
		end
	end

	if spec.bendingModifiers ~= nil then
		for _, modifier in ipairs(spec.bendingModifiers) do
			for i = 1, #modifier.indices do
				local index = modifier.indices[i]
				local bendingNode = spec.bendingNodes[index]

				if bendingNode ~= nil then
					if modifier.overwrite then
						bendingNode.minX = modifier.minX or bendingNode.minX
						bendingNode.maxX = modifier.maxX or bendingNode.maxX
						bendingNode.minZ = modifier.minZ or bendingNode.minZ
						bendingNode.maxZ = modifier.maxZ or bendingNode.maxZ
						bendingNode.yOffset = modifier.yOffset or bendingNode.yOffset
					else
						bendingNode.minX = math.min(bendingNode.minX, modifier.minX or bendingNode.minX)
						bendingNode.maxX = math.max(bendingNode.maxX, modifier.maxX or bendingNode.maxX)
						bendingNode.minZ = math.min(bendingNode.minZ, modifier.minZ or bendingNode.minZ)
						bendingNode.maxZ = math.max(bendingNode.maxZ, modifier.maxZ or bendingNode.maxZ)
						bendingNode.yOffset = math.max(bendingNode.yOffset, modifier.yOffset or bendingNode.yOffset)
					end

					if not modifier.isActive then
						bendingNode.isActive = false
					end
				else
					Logging.xmlWarning(self.xmlFile, "Undefined bendingNode index '%d' for bending modifier '%s'!", index, modifier.key)
				end
			end
		end

		spec.bendingModifiers = nil
	end
end

function FoliageBending:onDelete()
	self:deactivateBendingNodes()
end

function FoliageBending:loadBendingNodeFromXML(xmlFile, key, bendingNode)
	local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if node == nil then
		node = self.rootNode
	end

	bendingNode.node = node
	bendingNode.key = key
	bendingNode.minX = xmlFile:getValue(key .. "#minX", -1)
	bendingNode.maxX = xmlFile:getValue(key .. "#maxX", 1)
	bendingNode.minZ = xmlFile:getValue(key .. "#minZ", -1)
	bendingNode.maxZ = xmlFile:getValue(key .. "#maxZ", 1)
	bendingNode.yOffset = xmlFile:getValue(key .. "#yOffset", 0)
	bendingNode.isActive = true

	return true
end

function FoliageBending:loadBendingNodeModifierFromXML(xmlFile, key)
	local modifier = {
		index = xmlFile:getValue(key .. "#index"),
		indices = xmlFile:getValue(key .. "#indices", nil, true)
	}

	if modifier.index == nil and modifier.indices == nil then
		Logging.xmlWarning(self.xmlFile, "Missing bending node index for bending modifier '%s'", key)

		return
	end

	if modifier.index ~= nil then
		table.insert(modifier.indices, modifier.index)
	end

	modifier.minX = xmlFile:getValue(key .. "#minX")
	modifier.maxX = xmlFile:getValue(key .. "#maxX")
	modifier.minZ = xmlFile:getValue(key .. "#minZ")
	modifier.maxZ = xmlFile:getValue(key .. "#maxZ")
	modifier.yOffset = xmlFile:getValue(key .. "#yOffset")
	modifier.isActive = xmlFile:getValue(key .. "#isActive", true)
	modifier.overwrite = xmlFile:getValue(key .. "#overwrite", true)
	local spec = self.spec_foliageBending

	if spec.bendingModifiers == nil then
		spec.bendingModifiers = {}
	end

	table.insert(spec.bendingModifiers, modifier)
end

function FoliageBending:activateBendingNodes()
	local spec = self.spec_foliageBending

	for _, bendingNode in ipairs(spec.bendingNodes) do
		if bendingNode.isActive and bendingNode.id == nil and g_currentMission.foliageBendingSystem then
			bendingNode.id = g_currentMission.foliageBendingSystem:createRectangle(bendingNode.minX, bendingNode.maxX, bendingNode.minZ, bendingNode.maxZ, bendingNode.yOffset, bendingNode.node)
		end
	end
end

function FoliageBending:deactivateBendingNodes()
	local spec = self.spec_foliageBending

	if spec.bendingNodes ~= nil then
		for _, bendingNode in ipairs(spec.bendingNodes) do
			if bendingNode.id ~= nil then
				g_currentMission.foliageBendingSystem:destroyObject(bendingNode.id)

				bendingNode.id = nil
			end
		end
	end
end

function FoliageBending:getFoliageBendingNodeByIndex(index)
	return self.spec_foliageBending.bendingNodes[index]
end

function FoliageBending:updateFoliageBendingAttributes(index)
	local bendingNode = self:getFoliageBendingNodeByIndex(index)

	if bendingNode ~= nil and bendingNode.id ~= nil then
		g_currentMission.foliageBendingSystem:setRectangleAttributes(bendingNode.id, bendingNode.minX, bendingNode.maxX, bendingNode.minZ, bendingNode.maxZ, bendingNode.yOffset)
	end
end

function FoliageBending:onActivate()
	self:activateBendingNodes()
end

function FoliageBending:onDeactivate()
	self:deactivateBendingNodes()
end
