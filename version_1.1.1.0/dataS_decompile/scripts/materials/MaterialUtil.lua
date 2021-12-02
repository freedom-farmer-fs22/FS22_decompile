MaterialUtil = {
	onCreateBaseMaterial = function (_, id)
		local materialNameStr = getUserAttribute(id, "materialName")

		if materialNameStr == nil then
			print("Warning: No material name given in '" .. getName(id) .. "' for MaterialUtil.onCreateBaseMaterial")

			return
		end

		g_materialManager:addBaseMaterial(materialNameStr, getMaterial(id, 0))
	end,
	validateMaterialAttributes = function (id, sourceFunc)
		local fillTypeStr = getUserAttribute(id, "fillType")

		if fillTypeStr == nil then
			print("Warning: No fillType given in '" .. getName(id) .. "' for " .. sourceFunc)

			return false
		end

		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)

		if fillTypeIndex == nil then
			print("Warning: Unknown fillType '" .. tostring(fillTypeStr) .. "' for " .. sourceFunc)

			return false
		end

		local materialTypeName = getUserAttribute(id, "materialType")

		if materialTypeName == nil then
			print("Warning: No materialType given for '" .. getName(id) .. "' for " .. sourceFunc)

			return false
		end

		local materialType = g_materialManager:getMaterialTypeByName(materialTypeName)

		if materialType == nil then
			print("Warning: Unknown materialType '" .. materialTypeName .. "' given for '" .. getName(id) .. "' for " .. sourceFunc)

			return false
		end

		local matIdStr = Utils.getNoNil(getUserAttribute(id, "materialIndex"), 1)
		local materialIndex = tonumber(matIdStr)

		if materialIndex == nil then
			print("Warning: Invalid materialIndex '" .. matIdStr .. "' for " .. getName(id) .. "-" .. materialTypeName .. "!")

			return false
		end

		return true, fillTypeIndex, materialType, materialIndex
	end
}

function MaterialUtil.onCreateMaterial(_, id)
	local isValid, fillTypeIndex, materialType, materialIndex = MaterialUtil.validateMaterialAttributes(id, "MaterialUtil.onCreateMaterial")

	if isValid then
		g_materialManager:addMaterial(fillTypeIndex, materialType, materialIndex, getMaterial(id, 0))
	end
end

function MaterialUtil.onCreateParticleMaterial(_, id)
	local isValid, fillTypeIndex, materialType, materialIndex = MaterialUtil.validateMaterialAttributes(id, "MaterialUtil.onCreateParticleMaterial")

	if isValid then
		g_materialManager:addParticleMaterial(fillTypeIndex, materialType, materialIndex, getMaterial(id, 0))
	end
end

function MaterialUtil.onCreateParticleSystem(_, id)
	local particleTypeName = getUserAttribute(id, "particleType")

	if particleTypeName == nil then
		Logging.warning("No particleType given for node '%s' in MaterialUtil.onCreateParticleSystem", getName(id))

		return
	end

	local particleType = g_particleSystemManager:getParticleSystemTypeByName(particleTypeName)

	if particleType == nil then
		Logging.warning("Unknown particleType '%s' given for node '%s' in MaterialUtil.onCreateParticleSystem\nAvailable types: %s", particleTypeName, getName(id), table.concat(g_particleSystemManager.particleTypes, " "))

		return
	end

	local defaultEmittingState = Utils.getNoNil(getUserAttribute(id, "defaultEmittingState"), false)
	local worldSpace = Utils.getNoNil(getUserAttribute(id, "worldSpace"), true)
	local forceFullLifespan = Utils.getNoNil(getUserAttribute(id, "forceFullLifespan"), false)
	local particleSystem = {}

	ParticleUtil.loadParticleSystemFromNode(id, particleSystem, defaultEmittingState, worldSpace, forceFullLifespan)
	g_particleSystemManager:addParticleSystem(particleType, particleSystem)
end

function MaterialUtil.loadBaseMaterialsFromXML(targetTable, xmlFile, baseKey, components, i3dMappings)
	xmlFile:iterate(baseKey, function (i, key)
		local baseMaterial = {}

		if MaterialUtil.loadBaseMaterialFromXML(xmlFile, key, baseMaterial, components, i3dMappings) then
			table.insert(targetTable, baseMaterial)
		end
	end)
end

function MaterialUtil.loadBaseMaterialFromXML(xmlFile, key, material, components, i3dMappings)
	local name = xmlFile:getValue(key .. "#name")

	if name == nil then
		Logging.xmlWarning(xmlFile, "Missing material name for base material '%s'", key)

		return false
	end

	if not ClassUtil.getIsValidIndexName(name) then
		Logging.xmlWarning(xmlFile, "Given material name '%s' is not valid for material '%s'", name, key)

		return false
	end

	local baseNode = xmlFile:getValue(key .. "#baseNode", nil, components, i3dMappings)

	if baseNode == nil then
		Logging.xmlWarning(xmlFile, "Missing baseNode for base material '%s'", key)

		return false
	elseif not getHasClassId(baseNode, ClassIds.SHAPE) then
		Logging.xmlWarning(xmlFile, "Material baseNode '%s' is not a shape '%s'", getName(baseNode), key)

		return false
	end

	material.name = name
	material.baseNode = baseNode
	material.materialId = getMaterial(baseNode, 0)
	material.nameToShaderParameter = {}
	material.shaderParameters = {}
	local i = 0

	while true do
		local parameterKey = string.format("%s.shaderParameter(%d)", key, i)

		if not xmlFile:hasProperty(parameterKey) then
			break
		end

		local shaderParameter = {}

		if MaterialUtil.loadBaseMaterialParameterFromXML(xmlFile, parameterKey, shaderParameter, material.baseNode) then
			if material.nameToShaderParameter[shaderParameter.name] == nil then
				material.nameToShaderParameter[shaderParameter.name] = shaderParameter

				table.insert(material.shaderParameters, shaderParameter)
			else
				Logging.xmlWarning(xmlFile, "shaderParameter '%s' already defined for material '%s'!", shaderParameter.name, key)
			end
		end

		i = i + 1
	end

	if #material.shaderParameters == 0 then
		Logging.xmlWarning(xmlFile, "Missing shaderParameters for base material '%s'", key)

		return false
	end

	return true
end

function MaterialUtil.loadBaseMaterialParameterFromXML(xmlFile, key, shaderParameter, node)
	local name = xmlFile:getValue(key .. "#name")

	if name == nil then
		Logging.xmlWarning(xmlFile, "Missing shader parameter name for base material '%s'", key)

		return false
	end

	if not ClassUtil.getIsValidIndexName(name) then
		Logging.xmlWarning(xmlFile, "Given shader parameter name '%s' is not valid for base material '%s'", name, key)

		return false
	end

	local value = g_brandColorManager:loadColorAndMaterialFromXML(xmlFile, node, name, key)

	if value == nil then
		Logging.xmlWarning(xmlFile, "Failed to load shader parameter value or material for base material '%s'", key)

		return false
	end

	shaderParameter.name = name
	shaderParameter.value = value

	return true
end

function MaterialUtil.applyBaseMaterial(node, material)
	if getHasClassId(node, ClassIds.SHAPE) then
		local nodeMaterialId = getMaterial(node, 0)

		if material.materialId == nodeMaterialId then
			for i = #material.shaderParameters, 1, -1 do
				local parameter = material.shaderParameters[i]

				if getHasShaderParameter(node, parameter.name) then
					setShaderParameter(node, parameter.name, parameter.value[1], parameter.value[2], parameter.value[3], parameter.value[4], false)
				else
					Logging.warning("ShaderParameter '%s' not found for material '%s'!", parameter.name, material.name)
					table.remove(material.shaderParameters, i)
				end
			end
		end
	end

	local numChildren = getNumOfChildren(node)

	if numChildren > 0 then
		for i = 0, numChildren - 1 do
			MaterialUtil.applyBaseMaterial(getChildAt(node, i), material)
		end
	end
end

function MaterialUtil.registerBaseMaterialXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "(?)#name", "Material name")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "(?)#baseNode", "Material base node")
	schema:register(XMLValueType.STRING, basePath .. "(?).shaderParameter(?)#name", "Shader parameter name")
	schema:register(XMLValueType.COLOR, basePath .. "(?).shaderParameter(?)#value", "Color value")
	schema:register(XMLValueType.INT, basePath .. "(?).shaderParameter(?)#material", "Material value")
end
