MotionPathEffectManager = {
	MOTION_PATH_SHADER_PARAMS = {
		"scrollPosition",
		"fadeProgress",
		"visibilityCut",
		"density",
		"verticalOffset",
		"subUVspeed",
		"subUVelements",
		"sizeScale"
	}
}
local MotionPathEffectManager_mt = Class(MotionPathEffectManager, AbstractManager)

function MotionPathEffectManager.new(customMt)
	local self = AbstractManager.new(customMt or MotionPathEffectManager_mt)
	self.shaderParamCopyBuffer = {}

	for i = 1, #MotionPathEffectManager.MOTION_PATH_SHADER_PARAMS do
		table.insert(self.shaderParamCopyBuffer, {
			0,
			0,
			0,
			0
		})
	end

	return self
end

function MotionPathEffectManager:initDataStructures()
	self.xmlFiles = {}
	self.sharedLoadRequestIds = {}
	self.effectsByType = {}
	self.effects = {}
end

function MotionPathEffectManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	MotionPathEffectManager:superClass().loadMapData(self, xmlFile, missionInfo, baseDirectory)

	self.baseDirectory = baseDirectory
	local customEnvironment, _ = Utils.getModNameAndBaseDirectory(baseDirectory)

	MotionPathEffectManager.createMotionPathEffectXMLSchema()
	self:loadMotionPathEffects(xmlFile, "map.motionPathEffects.motionPathEffect", baseDirectory, customEnvironment)

	local externalXMLFilename = getXMLString(xmlFile, "map.motionPathEffects#filename")

	if externalXMLFilename ~= nil then
		externalXMLFilename = Utils.getFilename(externalXMLFilename, baseDirectory)
		local externalXMLFile = XMLFile.load("motionPathXML", externalXMLFilename)

		if externalXMLFile ~= nil then
			self:loadMotionPathEffects(externalXMLFile.handle, "motionPathEffects.motionPathEffect", baseDirectory, customEnvironment)
			externalXMLFile:delete()
		end
	end

	return true
end

function MotionPathEffectManager:loadMotionPathEffects(xmlFileHandle, key, baseDirectory, customEnvironment)
	local i = 0

	while true do
		local motionPathEffectKey = string.format("%s(%d)", key, i)

		if not hasXMLProperty(xmlFileHandle, motionPathEffectKey) then
			break
		end

		local filename = getXMLString(xmlFileHandle, motionPathEffectKey .. "#filename")

		if filename ~= nil then
			self:loadMotionPathEffectsXML(filename, baseDirectory, customEnvironment)
		end

		i = i + 1
	end
end

function MotionPathEffectManager:loadMotionPathEffectsXML(filename, baseDirectory, customEnvironment)
	local xmlFilename = Utils.getFilename(filename, baseDirectory)
	local xmlFile = XMLFile.load("mapMotionPathEffects", xmlFilename, MotionPathEffectManager.xmlSchema)

	if xmlFile ~= nil then
		self.xmlFiles[xmlFile] = true
		xmlFile.xmlReferences = 0
		local i = 0

		while true do
			local motionPathEffectKey = string.format("motionPathEffects.motionPathEffect(%d)", i)

			if not xmlFile:hasProperty(motionPathEffectKey) then
				break
			end

			local motionPathEffect = {}
			local effectClassName = xmlFile:getValue(motionPathEffectKey .. "#effectClass", "MotionPathEffect")

			if effectClassName ~= nil then
				local effectClass = g_effectManager:getEffectClass(effectClassName)

				if effectClass == nil then
					if customEnvironment ~= nil and customEnvironment ~= "" then
						effectClass = g_effectManager:getEffectClass(customEnvironment .. "." .. effectClassName)
					end

					if effectClass == nil then
						effectClass = ClassUtil.getClassObject(effectClassName)
					end
				end

				if effectClass ~= nil then
					effectClass.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, motionPathEffectKey .. ".typeDefinition")

					motionPathEffect.effectClass = effectClass
					motionPathEffect.effectClassName = effectClassName
					motionPathEffect.effectTypes = {}
					motionPathEffect.effectTypeStr = xmlFile:getValue(motionPathEffectKey .. "#effectType", "DEFAULT")
					local effectTypes = motionPathEffect.effectTypeStr:split(" ")

					for j = 1, #effectTypes do
						table.insert(motionPathEffect.effectTypes, effectTypes[j]:upper())
					end

					motionPathEffect.filename = xmlFile:getValue(motionPathEffectKey .. "#filename")

					if motionPathEffect.filename ~= nil then
						xmlFile.xmlReferences = xmlFile.xmlReferences + 1
						motionPathEffect.filename = Utils.getFilename(motionPathEffect.filename, baseDirectory)
						local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(motionPathEffect.filename, false, false, self.motionPathEffectI3DFileLoaded, self, {
							motionPathEffect,
							xmlFile,
							motionPathEffectKey,
							baseDirectory
						})

						table.insert(self.sharedLoadRequestIds, sharedLoadRequestId)
					else
						Logging.xmlError(xmlFile, "Missing filename for motion path effect '%s'", motionPathEffectKey)
					end
				else
					Logging.xmlError(xmlFile, "Unknown motion path effect class '%s' in '%s'", effectClassName, motionPathEffectKey)
				end
			end

			i = i + 1
		end

		if xmlFile.xmlReferences == 0 then
			self.xmlFiles[xmlFile] = nil

			xmlFile:delete()
		end
	end
end

function MotionPathEffectManager:motionPathEffectI3DFileLoaded(i3dNode, failedReason, args)
	local motionPathEffect, xmlFile, motionPathEffectKey, baseDirectory = unpack(args)

	if i3dNode ~= nil and i3dNode ~= 0 then
		local loadedMeshes = {}
		motionPathEffect.effectMeshes = {}

		xmlFile:iterate(motionPathEffectKey .. ".effectMeshes.effectMesh", function (index, key)
			local node = xmlFile:getValue(key .. "#node", nil, i3dNode)

			if node ~= nil and loadedMeshes[node] == nil then
				local effectMesh = {
					node = node,
					rowLength = xmlFile:getValue(key .. "#rowLength", 30),
					numRows = xmlFile:getValue(key .. "#numRows", 12),
					skipPositions = xmlFile:getValue(key .. "#skipPositions", 0),
					numVariations = xmlFile:getValue(key .. "#numVariations", 1)
				}

				if effectMesh.numVariations > 1 then
					effectMesh.usedVariations = {}

					for i = 1, effectMesh.numVariations do
						effectMesh.usedVariations[i] = false
					end
				end

				effectMesh.parent = motionPathEffect

				self:loadCustomShaderSettingsFromXML(effectMesh, xmlFile, key)
				motionPathEffect.effectClass.loadEffectMeshFromXML(effectMesh, xmlFile, key)

				effectMesh.growthStates = motionPathEffect.growthStates

				table.insert(motionPathEffect.effectMeshes, effectMesh)

				loadedMeshes[node] = true
			elseif node == nil then
				Logging.xmlError(xmlFile, "Failed to load effect mesh node from xml (%s)", key)
			else
				Logging.xmlError(xmlFile, "Failed to load effect mesh node from xml. Node already used. (%s)", key)
			end
		end)

		motionPathEffect.effectMaterials = {}

		xmlFile:iterate(motionPathEffectKey .. ".effectMaterials.effectMaterial", function (index, key)
			local node = xmlFile:getValue(key .. "#node", nil, i3dNode)

			if node ~= nil then
				local effectMaterial = {
					node = node,
					materialId = getMaterial(node, 0),
					parent = motionPathEffect,
					lod = {}
				}

				xmlFile:iterate(key .. ".lod", function (_, lodKey)
					local lodNode = xmlFile:getValue(lodKey .. "#node", nil, i3dNode)

					if lodNode ~= nil then
						table.insert(effectMaterial.lod, getMaterial(lodNode, 0))
					end
				end)

				effectMaterial.customDiffuse = xmlFile:getValue(key .. ".textures#diffuse")

				if effectMaterial.customDiffuse ~= nil then
					effectMaterial.customDiffuse = Utils.getFilename(effectMaterial.customDiffuse, baseDirectory)
					effectMaterial.materialId = setMaterialDiffuseMapFromFile(effectMaterial.materialId, effectMaterial.customDiffuse, true, true, false)
				end

				effectMaterial.customNormal = xmlFile:getValue(key .. ".textures#normal")

				if effectMaterial.customNormal ~= nil then
					effectMaterial.customNormal = Utils.getFilename(effectMaterial.customNormal, baseDirectory)
					effectMaterial.materialId = setMaterialNormalMapFromFile(effectMaterial.materialId, effectMaterial.customDiffuse, true, false, false)
				end

				effectMaterial.customSpecular = xmlFile:getValue(key .. ".textures#specular")

				if effectMaterial.customSpecular ~= nil then
					effectMaterial.customSpecular = Utils.getFilename(effectMaterial.customSpecular, baseDirectory)
					effectMaterial.materialId = setMaterialGlossMapFromFile(effectMaterial.materialId, effectMaterial.customSpecular, true, true, false)
				end

				setMaterial(node, effectMaterial.materialId, 0)
				self:loadCustomShaderSettingsFromXML(effectMaterial, xmlFile, key)
				motionPathEffect.effectClass.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
				table.insert(motionPathEffect.effectMaterials, effectMaterial)

				return
			end

			Logging.xmlError(xmlFile, "Failed to load effect material from xml (%s)", key)
		end)
		self:loadCustomShaderSettingsFromXML(motionPathEffect, xmlFile, motionPathEffectKey .. ".customShaderDefaults")

		for j = 1, #motionPathEffect.effectMeshes do
			unlink(motionPathEffect.effectMeshes[j].node)
		end

		for j = 1, #motionPathEffect.effectMaterials do
			unlink(motionPathEffect.effectMaterials[j].node)
		end

		for i = 1, #motionPathEffect.effectTypes do
			local effectType = motionPathEffect.effectTypes[i]

			if self.effectsByType[effectType] == nil then
				self.effectsByType[effectType] = {}
			end

			table.insert(self.effectsByType[effectType], motionPathEffect)
		end

		table.insert(self.effects, motionPathEffect)
		delete(i3dNode)
	end

	xmlFile.xmlReferences = xmlFile.xmlReferences - 1

	if xmlFile.xmlReferences == 0 then
		self.xmlFiles[xmlFile] = nil

		xmlFile:delete()
	end
end

function MotionPathEffectManager:loadCustomShaderSettingsFromXML(target, xmlFile, key)
	target.customShaderVariation = xmlFile:getValue(key .. ".customShaderVariation#name")
	target.customShaderMaps = {}

	xmlFile:iterate(key .. ".customShaderMap", function (index, parameterKey)
		local customShaderMap = {
			name = xmlFile:getValue(parameterKey .. "#name"),
			filename = xmlFile:getValue(parameterKey .. "#filename")
		}
		customShaderMap.filename = Utils.getFilename(customShaderMap.filename, self.baseDirectory)

		if customShaderMap.name ~= nil and customShaderMap.filename ~= nil then
			customShaderMap.texture = createMaterialTextureFromFile(customShaderMap.filename, true, false)

			if customShaderMap.texture ~= nil then
				table.insert(target.customShaderMaps, customShaderMap)
			end
		else
			Logging.xmlError(xmlFile, "Failed to load custom shader map from '%s'", parameterKey)
		end
	end)

	target.customShaderParameters = {}

	xmlFile:iterate(key .. ".customShaderParameter", function (index, parameterKey)
		local customShaderParameter = {
			name = xmlFile:getValue(parameterKey .. "#name"),
			value = xmlFile:getValue(parameterKey .. "#value", "0 0 0 0", true)
		}

		if customShaderParameter.name ~= nil and customShaderParameter.value ~= nil then
			table.insert(target.customShaderParameters, customShaderParameter)
		else
			Logging.xmlError(xmlFile, "Failed to load custom shader parameter from '%s'", parameterKey)
		end
	end)
end

function MotionPathEffectManager:unloadMapData()
	for i = 1, #self.effects do
		local effect = self.effects[i]

		self:deleteCustomShaderMaps(effect)

		for j = 1, #effect.effectMeshes do
			local effectMesh = effect.effectMeshes[j]

			delete(effectMesh.node)
			self:deleteCustomShaderMaps(effectMesh)
		end

		for j = 1, #effect.effectMaterials do
			local material = effect.effectMaterials[j]

			delete(material.node)
			self:deleteCustomShaderMaps(material)
		end
	end

	for i = 1, #self.sharedLoadRequestIds do
		local sharedLoadRequestId = self.sharedLoadRequestIds[i]

		g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
	end

	for xmlFile, _ in pairs(self.xmlFiles) do
		self.xmlFiles[xmlFile] = nil

		xmlFile:delete()
	end

	MotionPathEffectManager:superClass().unloadMapData(self)
end

function MotionPathEffectManager:deleteCustomShaderMaps(entity)
	for _, customMap in ipairs(entity.customShaderMaps) do
		if customMap.texture ~= nil then
			delete(customMap.texture)

			customMap.texture = nil
		end
	end
end

function MotionPathEffectManager:getSharedMotionPathEffect(motionPathEffectObject)
	for i = 1, #self.effects do
		local effect = self.effects[i]

		if motionPathEffectObject:getIsSharedEffectMatching(effect, false) then
			return effect
		end
	end

	for i = 1, #self.effects do
		local effect = self.effects[i]

		if motionPathEffectObject:getIsSharedEffectMatching(effect, true) then
			return effect
		end
	end
end

function MotionPathEffectManager:getMotionPathEffectMesh(sharedEffect, motionPathEffectObject)
	for j = 1, #sharedEffect.effectMeshes do
		local effectMesh = sharedEffect.effectMeshes[j]

		if motionPathEffectObject:getIsEffectMeshMatching(effectMesh, false) then
			return effectMesh
		end
	end

	for j = 1, #sharedEffect.effectMeshes do
		local effectMesh = sharedEffect.effectMeshes[j]

		if motionPathEffectObject:getIsEffectMeshMatching(effectMesh, true) then
			return effectMesh
		end
	end
end

function MotionPathEffectManager:getMotionPathEffectMaterial(sharedEffect, motionPathEffectObject)
	for i = 1, #sharedEffect.effectMaterials do
		local effectMaterial = sharedEffect.effectMaterials[i]

		if motionPathEffectObject:getIsEffectMaterialMatching(effectMaterial, false) then
			return effectMaterial
		end
	end

	for i = 1, #sharedEffect.effectMaterials do
		local effectMaterial = sharedEffect.effectMaterials[i]

		if motionPathEffectObject:getIsEffectMaterialMatching(effectMaterial, true) then
			return effectMaterial
		end
	end
end

function MotionPathEffectManager:applyEffectConfiguration(sharedEffect, effectMesh, effectMaterial, clonedNode, textureEntityId, overwrittenSpeedScale)
	if sharedEffect ~= nil and clonedNode ~= nil then
		self:applyShaderSettingsParameters(clonedNode, sharedEffect)

		if effectMesh ~= nil then
			self:applyShaderSettingsParameters(clonedNode, effectMesh)
		end

		if effectMaterial ~= nil then
			self:applyShaderSettingsParameters(clonedNode, effectMaterial)
		end

		self:setEffectCustomMap(clonedNode, "shapeArray", textureEntityId)

		local speedScale = sharedEffect.speedScale or 0.5
		speedScale = effectMesh.speedScale or speedScale

		if effectMaterial ~= nil then
			speedScale = effectMaterial.speedScale or speedScale
		end

		speedScale = overwrittenSpeedScale or speedScale

		return speedScale
	end

	return overwrittenSpeedScale or 1
end

function MotionPathEffectManager:applyShaderSettingsParameters(node, target)
	for i = 1, #target.customShaderMaps do
		local customShaderMap = target.customShaderMaps[i]

		self:setEffectCustomMap(node, customShaderMap.name, customShaderMap.texture)
	end

	if target.customShaderVariation ~= nil then
		self:setEffectCustomShaderVariation(node, target.customShaderVariation)
	end

	for i = 1, #target.customShaderParameters do
		local customShaderParameter = target.customShaderParameters[i]

		self:setEffectShaderParameter(node, customShaderParameter.name, customShaderParameter.value[1], customShaderParameter.value[2], customShaderParameter.value[3], customShaderParameter.value[4], false)
	end
end

function MotionPathEffectManager:setEffectShaderParameter(node, name, x, y, z, w, shared)
	if getHasClassId(node, ClassIds.SHAPE) then
		local _x, _y, _z, _w = getShaderParameter(node, name)

		setShaderParameter(node, name, x or _x, y or _y, z or _z, w or _w, shared)
	end

	local numChildren = getNumOfChildren(node)

	if numChildren > 0 then
		for i = 1, numChildren do
			local child = getChildAt(node, i - 1)

			if getHasClassId(child, ClassIds.SHAPE) then
				local _x, _y, _z, _w = getShaderParameter(child, name)

				setShaderParameter(child, name, x or _x, y or _y, z or _z, w or _w, shared)
			end
		end
	end
end

function MotionPathEffectManager:getEffectShaderParameter(node, name)
	if getHasClassId(node, ClassIds.SHAPE) then
		return getShaderParameter(node, name)
	end

	local numChildren = getNumOfChildren(node)

	if numChildren > 0 then
		for i = 1, numChildren do
			local child = getChildAt(node, i - 1)

			if getHasClassId(child, ClassIds.SHAPE) then
				return getShaderParameter(child, name)
			end
		end
	end

	return 0, 0, 0, 0
end

function MotionPathEffectManager:setEffectCustomShaderVariation(node, variation)
	if getHasClassId(node, ClassIds.SHAPE) then
		local material = getMaterial(node, 0)
		local newMaterial = setMaterialCustomShaderVariation(material, variation, false)

		if newMaterial ~= material then
			setMaterial(node, newMaterial, 0)
		end
	end

	local numChildren = getNumOfChildren(node)

	if numChildren > 0 then
		for i = 1, numChildren do
			local child = getChildAt(node, i - 1)

			if getHasClassId(child, ClassIds.SHAPE) then
				local material = getMaterial(child, 0)
				local newMaterial = setMaterialCustomShaderVariation(material, variation, false)

				if newMaterial ~= material then
					setMaterial(child, newMaterial, 0)
				end
			end
		end
	end
end

function MotionPathEffectManager:setEffectCustomMapOnNode(node, name, textureEntityId)
	local material = getMaterial(node, 0)

	if textureEntityId ~= nil then
		local newMaterial = setMaterialCustomMap(material, name, textureEntityId, false)

		if newMaterial ~= material then
			for i = 1, #MotionPathEffectManager.MOTION_PATH_SHADER_PARAMS do
				local x, y, z, w = getShaderParameter(node, MotionPathEffectManager.MOTION_PATH_SHADER_PARAMS[i])
				self.shaderParamCopyBuffer[i][1] = x
				self.shaderParamCopyBuffer[i][2] = y
				self.shaderParamCopyBuffer[i][3] = z
				self.shaderParamCopyBuffer[i][4] = w
			end

			setMaterial(node, newMaterial, 0)

			for i = 1, #MotionPathEffectManager.MOTION_PATH_SHADER_PARAMS do
				local x = self.shaderParamCopyBuffer[i][1]
				local y = self.shaderParamCopyBuffer[i][2]
				local z = self.shaderParamCopyBuffer[i][3]
				local w = self.shaderParamCopyBuffer[i][4]

				setShaderParameter(node, MotionPathEffectManager.MOTION_PATH_SHADER_PARAMS[i], x, y, z, w)
			end
		end
	end
end

function MotionPathEffectManager:setEffectCustomMap(node, name, textureEntityId)
	if getHasClassId(node, ClassIds.SHAPE) then
		self:setEffectCustomMapOnNode(node, name, textureEntityId)
	end

	local numChildren = getNumOfChildren(node)

	if numChildren > 0 then
		for i = 1, numChildren do
			local child = getChildAt(node, i - 1)

			if getHasClassId(child, ClassIds.SHAPE) then
				self:setEffectCustomMapOnNode(child, name, textureEntityId)
			end
		end
	end
end

function MotionPathEffectManager:setEffectMaterial(node, material)
	if getHasClassId(node, ClassIds.SHAPE) then
		setMaterial(node, material.materialId, 0)
	end

	local numChildren = getNumOfChildren(node)

	if numChildren > 0 then
		for i = 1, numChildren do
			local child = getChildAt(node, i - 1)

			if getHasClassId(child, ClassIds.SHAPE) then
				local materialId = material.materialId

				if i > 1 and material.lod[i] ~= nil then
					materialId = material.lod[i]
				end

				setMaterial(child, materialId, 0)
			end
		end
	end
end

function MotionPathEffectManager.createMotionPathEffectXMLSchema()
	if MotionPathEffectManager.xmlSchema == nil then
		local schema = XMLSchema.new("mapMotionPathEffects")
		local effectKey = "motionPathEffects.motionPathEffect(?)"

		schema:register(XMLValueType.STRING, effectKey .. "#effectClass", "Effect class name")
		schema:register(XMLValueType.STRING, effectKey .. "#effectType", "Effect type name (can be multiple)")
		schema:register(XMLValueType.STRING, effectKey .. "#filename", "Path to effects i3d file")
		schema:register(XMLValueType.NODE_INDEX, effectKey .. ".effectGeneration#rootNode", "(Only for automatic mesh generation) Mesh root node in maya file which has sub shapes")
		schema:register(XMLValueType.VECTOR_ROT, effectKey .. ".effectGeneration#minRot", "(Only for automatic mesh generation) Min. random rotation")
		schema:register(XMLValueType.VECTOR_ROT, effectKey .. ".effectGeneration#maxRot", "(Only for automatic mesh generation) Max. random rotation")
		schema:register(XMLValueType.VECTOR_SCALE, effectKey .. ".effectGeneration#minScale", "(Only for automatic mesh generation) Min. random scale")
		schema:register(XMLValueType.VECTOR_SCALE, effectKey .. ".effectGeneration#maxScale", "(Only for automatic mesh generation) Max. random scale")
		schema:register(XMLValueType.STRING, effectKey .. ".effectGeneration#useFoliage", "(Only for automatic mesh generation) Name of foliage")
		schema:register(XMLValueType.INT, effectKey .. ".effectGeneration#useFoliageStage", "(Only for automatic mesh generation) Foliage growth state")
		schema:register(XMLValueType.INT, effectKey .. ".effectGeneration#useFoliageLOD", "(Only for automatic mesh generation) LOD to use")
		MotionPathEffect.registerEffectDefinitionXMLPaths(schema, effectKey .. ".typeDefinition")
		TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, effectKey .. ".typeDefinition")
		CutterMotionPathEffect.registerEffectDefinitionXMLPaths(schema, effectKey .. ".typeDefinition")
		CultivatorMotionPathEffect.registerEffectDefinitionXMLPaths(schema, effectKey .. ".typeDefinition")
		PlowMotionPathEffect.registerEffectDefinitionXMLPaths(schema, effectKey .. ".typeDefinition")
		WindrowerMotionPathEffect.registerEffectDefinitionXMLPaths(schema, effectKey .. ".typeDefinition")
		schema:register(XMLValueType.NODE_INDEX, effectKey .. ".effectMeshes.effectMesh(?)#node", "Index path in effect i3d")
		schema:register(XMLValueType.NODE_INDEX, effectKey .. ".effectMeshes.effectMesh(?)#sourceNode", "(Only for automatic mesh generation) Index path to source object in maya file")
		schema:register(XMLValueType.INT, effectKey .. ".effectMeshes.effectMesh(?)#rowLength", "Number of meshes on X axis (on effect texture)", 30)
		schema:register(XMLValueType.INT, effectKey .. ".effectMeshes.effectMesh(?)#numRows", "Number of meshes on Y axis (on effect texture)", 12)
		schema:register(XMLValueType.INT, effectKey .. ".effectMeshes.effectMesh(?)#skipPositions", "Number of skipped meshes on X axis", 0)
		schema:register(XMLValueType.INT, effectKey .. ".effectMeshes.effectMesh(?)#numVariations", "Number of sub random variations", 1)
		schema:register(XMLValueType.VECTOR_SCALE, effectKey .. ".effectMeshes.effectMesh(?)#boundingBox", "(Only for automatic mesh generation) Size of bounding box")
		schema:register(XMLValueType.VECTOR_TRANS, effectKey .. ".effectMeshes.effectMesh(?)#boundingBoxCenter", "(Only for automatic mesh generation) Center of bounding box")
		schema:register(XMLValueType.NODE_INDEX, effectKey .. ".effectMeshes.effectMesh(?).lod(?)#sourceNode", "(Only for automatic mesh generation) Custom node for LOD")
		schema:register(XMLValueType.FLOAT, effectKey .. ".effectMeshes.effectMesh(?).lod(?)#distance", "(Only for automatic mesh generation) Distance of LOD")
		schema:register(XMLValueType.INT, effectKey .. ".effectMeshes.effectMesh(?).lod(?)#skipPositions", "(Only for automatic mesh generation) Custom skip positions")
		MotionPathEffectManager.registerCustomShaderSettingXMLPaths(schema, effectKey .. ".effectMeshes.effectMesh(?)")
		MotionPathEffect.registerEffectMeshXMLPaths(schema, effectKey .. ".effectMeshes.effectMesh(?)")
		TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, effectKey .. ".effectMeshes.effectMesh(?)")
		CutterMotionPathEffect.registerEffectMeshXMLPaths(schema, effectKey .. ".effectMeshes.effectMesh(?)")
		CultivatorMotionPathEffect.registerEffectMeshXMLPaths(schema, effectKey .. ".effectMeshes.effectMesh(?)")
		PlowMotionPathEffect.registerEffectMeshXMLPaths(schema, effectKey .. ".effectMeshes.effectMesh(?)")
		WindrowerMotionPathEffect.registerEffectMeshXMLPaths(schema, effectKey .. ".effectMeshes.effectMesh(?)")
		schema:register(XMLValueType.NODE_INDEX, effectKey .. ".effectMaterials#rootNode", "(Only for automatic mesh generation) Node which will be copied over the effect i3d file (position index in i3d is then '0|1')")
		schema:register(XMLValueType.NODE_INDEX, effectKey .. ".effectMaterials.effectMaterial(?)#node", "Material node")
		schema:register(XMLValueType.NODE_INDEX, effectKey .. ".effectMaterials.effectMaterial(?).lod(?)#node", "LOD node")
		schema:register(XMLValueType.STRING, effectKey .. ".effectMaterials.effectMaterial(?).textures#diffuse", "Path to custom diffuse map to apply")
		schema:register(XMLValueType.STRING, effectKey .. ".effectMaterials.effectMaterial(?).textures#normal", "Path to custom normal map to apply")
		schema:register(XMLValueType.STRING, effectKey .. ".effectMaterials.effectMaterial(?).textures#specular", "Path to custom specular map to apply")
		MotionPathEffectManager.registerCustomShaderSettingXMLPaths(schema, effectKey .. ".effectMaterials.effectMaterial(?)")
		MotionPathEffect.registerEffectMaterialXMLPaths(schema, effectKey .. ".effectMaterials.effectMaterial(?)")
		TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, effectKey .. ".effectMaterials.effectMaterial(?)")
		CutterMotionPathEffect.registerEffectMaterialXMLPaths(schema, effectKey .. ".effectMaterials.effectMaterial(?)")
		CultivatorMotionPathEffect.registerEffectMaterialXMLPaths(schema, effectKey .. ".effectMaterials.effectMaterial(?)")
		PlowMotionPathEffect.registerEffectMaterialXMLPaths(schema, effectKey .. ".effectMaterials.effectMaterial(?)")
		WindrowerMotionPathEffect.registerEffectMaterialXMLPaths(schema, effectKey .. ".effectMaterials.effectMaterial(?)")
		MotionPathEffectManager.registerCustomShaderSettingXMLPaths(schema, effectKey .. ".customShaderDefaults")

		MotionPathEffectManager.xmlSchema = schema
	end
end

function MotionPathEffectManager.registerCustomShaderSettingXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".customShaderVariation#name", "Shader variation to apply")
	schema:register(XMLValueType.STRING, basePath .. ".customShaderParameter(?)#name", "Name of shader parameter")
	schema:register(XMLValueType.VECTOR_4, basePath .. ".customShaderParameter(?)#value", "Value of shader parameter")
	schema:register(XMLValueType.STRING, basePath .. ".customShaderMap(?)#name", "Name of custom shader map")
	schema:register(XMLValueType.STRING, basePath .. ".customShaderMap(?)#filename", "Path to texture file")
end

g_motionPathEffectManager = MotionPathEffectManager.new()
