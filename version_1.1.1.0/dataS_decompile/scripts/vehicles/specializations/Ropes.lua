Ropes = {
	prerequisitesPresent = function (specializations)
		return true
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("Ropes")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.ropes.rope(?)#baseNode", "Base node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.ropes.rope(?)#targetNode", "Target node")
		schema:register(XMLValueType.VECTOR_4, "vehicle.ropes.rope(?)#baseParameters", "Base parameters")
		schema:register(XMLValueType.VECTOR_4, "vehicle.ropes.rope(?)#targetParameters", "Target parameters")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.ropes.rope(?).baseParameterAdjuster(?)#node", "Adjuster node")
		schema:register(XMLValueType.INT, "vehicle.ropes.rope(?).baseParameterAdjuster(?)#rotationAxis", "Rotation axis")
		schema:register(XMLValueType.VECTOR_ROT_2, "vehicle.ropes.rope(?).baseParameterAdjuster(?)#rotationRange", "Rotation range")
		schema:register(XMLValueType.INT, "vehicle.ropes.rope(?).baseParameterAdjuster(?)#translationAxis", "Translation axis")
		schema:register(XMLValueType.VECTOR_2, "vehicle.ropes.rope(?).baseParameterAdjuster(?)#translationRange", "Translation range")
		schema:register(XMLValueType.VECTOR_4, "vehicle.ropes.rope(?).baseParameterAdjuster(?)#minTargetParameters", "Min. target parameters")
		schema:register(XMLValueType.VECTOR_4, "vehicle.ropes.rope(?).baseParameterAdjuster(?)#maxTargetParameters", "Max. target parameters")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.ropes.rope(?).targetParameterAdjuster(?)#node", "Adjuster node")
		schema:register(XMLValueType.INT, "vehicle.ropes.rope(?).targetParameterAdjuster(?)#rotationAxis", "Rotation axis")
		schema:register(XMLValueType.VECTOR_ROT_2, "vehicle.ropes.rope(?).targetParameterAdjuster(?)#rotationRange", "Rotation range")
		schema:register(XMLValueType.INT, "vehicle.ropes.rope(?).targetParameterAdjuster(?)#translationAxis", "Translation axis")
		schema:register(XMLValueType.VECTOR_2, "vehicle.ropes.rope(?).targetParameterAdjuster(?)#translationRange", "Translation range")
		schema:register(XMLValueType.VECTOR_4, "vehicle.ropes.rope(?).targetParameterAdjuster(?)#minTargetParameters", "Min. target parameters")
		schema:register(XMLValueType.VECTOR_4, "vehicle.ropes.rope(?).targetParameterAdjuster(?)#maxTargetParameters", "Max. target parameters")
		schema:setXMLSpecializationType()
	end
}

function Ropes.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadAdjusterNode", Ropes.loadAdjusterNode)
	SpecializationUtil.registerFunction(vehicleType, "updateRopes", Ropes.updateRopes)
	SpecializationUtil.registerFunction(vehicleType, "updateAdjusterNodes", Ropes.updateAdjusterNodes)
end

function Ropes.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Ropes)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Ropes)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Ropes)
end

function Ropes:onLoad(savegame)
	local spec = self.spec_ropes

	if self.isClient then
		spec.ropes = {}
		local i = 0

		while true do
			local key = string.format("vehicle.ropes.rope(%d)", i)

			if not self.xmlFile:hasProperty(key) then
				break
			end

			local entry = {
				baseNode = self.xmlFile:getValue(key .. "#baseNode", nil, self.components, self.i3dMappings),
				targetNode = self.xmlFile:getValue(key .. "#targetNode", nil, self.components, self.i3dMappings),
				baseParameters = self.xmlFile:getValue(key .. "#baseParameters", nil, true),
				targetParameters = self.xmlFile:getValue(key .. "#targetParameters", nil, true)
			}

			setShaderParameter(entry.baseNode, "cv0", entry.baseParameters[1], entry.baseParameters[2], entry.baseParameters[3], entry.baseParameters[4], false)
			setShaderParameter(entry.baseNode, "cv1", 0, 0, 0, 0, false)

			local x, y, z = localToLocal(entry.targetNode, entry.baseNode, entry.targetParameters[1], entry.targetParameters[2], entry.targetParameters[3])

			setShaderParameter(entry.baseNode, "cv3", x, y, z, 0, false)

			entry.baseParameterAdjusters = {}
			local j = 0

			while true do
				local adjusterKey = string.format("%s.baseParameterAdjuster(%d)", key, j)

				if not self.xmlFile:hasProperty(adjusterKey) then
					break
				end

				local adjusterNode = {}

				if self:loadAdjusterNode(adjusterNode, self.xmlFile, adjusterKey) then
					table.insert(entry.baseParameterAdjusters, adjusterNode)
				end

				j = j + 1
			end

			entry.targetParameterAdjusters = {}
			j = 0

			while true do
				local adjusterKey = string.format("%s.targetParameterAdjuster(%d)", key, j)

				if not self.xmlFile:hasProperty(adjusterKey) then
					break
				end

				local adjusterNode = {}

				if self:loadAdjusterNode(adjusterNode, self.xmlFile, adjusterKey) then
					table.insert(entry.targetParameterAdjusters, adjusterNode)
				end

				j = j + 1
			end

			table.insert(spec.ropes, entry)

			i = i + 1
		end
	end

	if not self.isClient or #spec.ropes == 0 then
		SpecializationUtil.removeEventListener(self, "onLoadFinished", Ropes)
		SpecializationUtil.removeEventListener(self, "onUpdate", Ropes)
	end
end

function Ropes:onLoadFinished(savegame)
	self:updateRopes(9999)
end

function Ropes:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	self:updateRopes(dt)
end

function Ropes:loadAdjusterNode(adjusterNode, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")

	local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if node ~= nil then
		adjusterNode.node = node
		adjusterNode.rotationAxis = xmlFile:getValue(key .. "#rotationAxis", 1)
		adjusterNode.rotationRange = xmlFile:getValue(key .. "#rotationRange", nil, true)
		adjusterNode.translationAxis = xmlFile:getValue(key .. "#translationAxis", 1)
		adjusterNode.translationRange = xmlFile:getValue(key .. "#translationRange", nil, true)
		adjusterNode.minTargetParameters = xmlFile:getValue(key .. "#minTargetParameters", nil, true)

		if adjusterNode.minTargetParameters == nil then
			Logging.xmlWarning(self.xmlFile, "Missing minTargetParameters attribute in '%s'", key)

			return false
		end

		adjusterNode.maxTargetParameters = xmlFile:getValue(key .. "#maxTargetParameters", nil, true)

		if adjusterNode.maxTargetParameters == nil then
			Logging.xmlWarning(self.xmlFile, "Missing maxTargetParameters attribute in '%s'", key)

			return false
		end

		return true
	else
		Logging.xmlWarning(self.xmlFile, "Missing node attribute in '%s'", key)
	end

	return false
end

function Ropes:updateRopes(dt)
	local spec = self.spec_ropes

	for _, rope in pairs(spec.ropes) do
		local x, y, z = self:updateAdjusterNodes(rope.baseParameterAdjusters)

		setShaderParameter(rope.baseNode, "cv0", rope.baseParameters[1] + x, rope.baseParameters[2] + y, rope.baseParameters[3] + z, 0, false)

		x, y, z = localToLocal(rope.targetNode, rope.baseNode, 0, 0, 0)

		setShaderParameter(rope.baseNode, "cv2", 0, 0, 0, 0, false)
		setShaderParameter(rope.baseNode, "cv3", x, y, z, 0, false)

		x, y, z = self:updateAdjusterNodes(rope.targetParameterAdjusters)
		x, y, z = localToLocal(rope.targetNode, rope.baseNode, rope.targetParameters[1] + x, rope.targetParameters[2] + y, rope.targetParameters[3] + z)

		setShaderParameter(rope.baseNode, "cv4", x, y, z, 0, false)
	end
end

function Ropes:updateAdjusterNodes(adjusterNodes)
	local xRet = 0
	local yRet = 0
	local zRet = 0

	for _, adjusterNode in pairs(adjusterNodes) do
		if adjusterNode.rotationAxis ~= nil and adjusterNode.rotationRange ~= nil then
			local rotations = {
				getRotation(adjusterNode.node)
			}
			local rot = rotations[adjusterNode.rotationAxis]
			local alpha = math.max(0, math.min(1, (rot - adjusterNode.rotationRange[1]) / (adjusterNode.rotationRange[2] - adjusterNode.rotationRange[1])))
			local x, y, z = MathUtil.vector3ArrayLerp(adjusterNode.minTargetParameters, adjusterNode.maxTargetParameters, alpha)
			zRet = zRet + z
			yRet = yRet + y
			xRet = xRet + x
		elseif adjusterNode.translationAxis ~= nil and adjusterNode.translationRange ~= nil then
			local translations = {
				getTranslation(adjusterNode.node)
			}
			local trans = translations[adjusterNode.translationAxis]
			local alpha = math.max(0, math.min(1, (trans - adjusterNode.translationRange[1]) / (adjusterNode.translationRange[2] - adjusterNode.translationRange[1])))
			local x, y, z = MathUtil.vector3ArrayLerp(adjusterNode.minTargetParameters, adjusterNode.maxTargetParameters, alpha)
			zRet = zRet + z
			yRet = yRet + y
			xRet = xRet + x
		end
	end

	return xRet, yRet, zRet
end
