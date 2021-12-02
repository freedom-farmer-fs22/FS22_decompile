FillType = nil
FillTypeCategory = nil
FillTypeManager = {
	FILLTYPE_START_TOTAL_AMOUNT = 50000,
	SEND_NUM_BITS = 8,
	MASS_SCALE = 1
}

g_xmlManager:addCreateSchemaFunction(function ()
	FillTypeManager.xmlSchema = XMLSchema.new("fillTypes")
end)
g_xmlManager:addInitSchemaFunction(function ()
	local schema = FillTypeManager.xmlSchema
	local fillTypeKey = "map.fillTypes.fillType(?)"

	schema:register(XMLValueType.STRING, fillTypeKey .. "#name", "Name of fill type")
	schema:register(XMLValueType.STRING, fillTypeKey .. "#title", "Display name of fill type")
	schema:register(XMLValueType.STRING, fillTypeKey .. "#achievementName", "Name of linked archivement")
	schema:register(XMLValueType.BOOL, fillTypeKey .. "#showOnPriceTable", "Show fill type in pricing menu")
	schema:register(XMLValueType.VECTOR_3, fillTypeKey .. "#fillPlaneColors", "Color of fill plane used in animal husbandry", "1 1 1")
	schema:register(XMLValueType.STRING, fillTypeKey .. "#unitShort", "Unit short localization key")
	schema:register(XMLValueType.FLOAT, fillTypeKey .. ".physics#massPerLiter", "Mass per liter/unit in kilograms")
	schema:register(XMLValueType.FLOAT, fillTypeKey .. ".physics#maxPhysicalSurfaceAngle", "Max physical surface angle used on fill volumes")
	schema:register(XMLValueType.STRING, fillTypeKey .. ".image#hud", "Path to hud image")
	schema:register(XMLValueType.STRING, fillTypeKey .. ".pallet#filename", "Pallet xml filename which is spawned on unloading")
	schema:register(XMLValueType.FLOAT, fillTypeKey .. ".economy#pricePerLiter", "Price per liter")
	schema:register(XMLValueType.INT, fillTypeKey .. ".economy.factors.factor(?)#period", "Period index")
	schema:register(XMLValueType.FLOAT, fillTypeKey .. ".economy.factors.factor(?)#value", "Price factor to apply in this period")
	schema:register(XMLValueType.STRING, fillTypeKey .. ".textures#diffuse", "Path to fill plane diffuse map")
	schema:register(XMLValueType.STRING, fillTypeKey .. ".textures#normal", "Path to fill plane normal map")
	schema:register(XMLValueType.STRING, fillTypeKey .. ".textures#specular", "Path to fill plane specular map")
	schema:register(XMLValueType.STRING, fillTypeKey .. ".textures#distance", "Path to fill plane distance diffuse map")
	schema:register(XMLValueType.STRING, fillTypeKey .. ".effects#prioritizedEffectType", "Defines which effect type is priorized in e.g. unloading effects", "ShaderPlaneEffect")
	schema:register(XMLValueType.VECTOR_4, fillTypeKey .. ".effects#fillSmokeColor", "Color of smoke effects")
	schema:register(XMLValueType.VECTOR_4, fillTypeKey .. ".effects#fruitSmokeColor", "Color of fruit smoke effects")

	local fillTypeCategoryKey = "map.fillTypeCategories.fillTypeCategory(?)"

	schema:register(XMLValueType.STRING, fillTypeCategoryKey .. "#name", "Name of category")
	schema:register(XMLValueType.STRING, fillTypeCategoryKey, "list of fillTypes, space separated")

	local fillTypeConverterKey = "map.fillTypeConverters.fillTypeConverter(?)"

	schema:register(XMLValueType.STRING, fillTypeConverterKey .. "#name", "Converter name")
	schema:register(XMLValueType.STRING, fillTypeConverterKey .. ".converter(?)#from", "From fill type")
	schema:register(XMLValueType.STRING, fillTypeConverterKey .. ".converter(?)#to", "To fill type")
	schema:register(XMLValueType.FLOAT, fillTypeConverterKey .. ".converter(?)#factor", "Multiplied by factor")

	local fillTypeSoundKey = "map.fillTypeSounds.fillTypeSound(?)"

	SoundManager.registerSampleXMLPaths(schema, fillTypeSoundKey, "sound")
	schema:register(XMLValueType.STRING, fillTypeSoundKey .. "#fillTypes", "list of fillTypes, space separated")
	schema:register(XMLValueType.BOOL, fillTypeSoundKey .. "#isDefault", "Is default sound", false)
end)

local FillTypeManager_mt = Class(FillTypeManager, AbstractManager)

function FillTypeManager.new(customMt)
	local self = AbstractManager.new(customMt or FillTypeManager_mt)

	return self
end

function FillTypeManager:initDataStructures()
	self.fillTypes = {}
	self.nameToFillType = {}
	self.indexToFillType = {}
	self.nameToIndex = {}
	self.indexToName = {}
	self.fillTypeConverters = {}
	self.converterNameToIndex = {}
	self.nameToConverter = {}
	self.categories = {}
	self.nameToCategoryIndex = {}
	self.categoryIndexToFillTypes = {}
	self.categoryNameToFillTypes = {}
	self.fillTypeIndexToCategories = {}
	self.fillTypeSamples = {}
	self.fillTypeToSample = {}
	self.fillTypeTextureDiffuseMap = nil
	self.fillTypeTextureNormalMap = nil
	self.fillTypeTextureSpecularMap = nil
	FillType = self.nameToIndex
	FillTypeCategory = self.categories
end

function FillTypeManager:loadDefaultTypes()
	local xmlFile = loadXMLFile("fillTypes", "data/maps/maps_fillTypes.xml")

	self:loadFillTypes(xmlFile, nil, , true)
	delete(xmlFile)
end

function FillTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	FillTypeManager:superClass().loadMapData(self)
	self:loadDefaultTypes()

	if XMLUtil.loadDataFromMapXML(xmlFile, "fillTypes", baseDirectory, self, self.loadFillTypes, missionInfo, baseDirectory) then
		self:constructFillTypeTextureArrays()

		return true
	end

	return false
end

function FillTypeManager:unloadMapData()
	for _, sample in pairs(self.fillTypeSamples) do
		g_soundManager:deleteSample(sample.sample)
	end

	self:deleteFillTypeTextureArrays()
	self:deleteDensityMapHeightTextureArrays()
	FillTypeManager:superClass().unloadMapData(self)
end

function FillTypeManager:loadFillTypes(xmlFile, missionInfo, baseDirectory, isBaseType)
	if type(xmlFile) ~= "table" then
		xmlFile = XMLFile.wrap(xmlFile, FillTypeManager.xmlSchema)
	end

	self:addFillType("UNKNOWN", "Unknown", false, 0, 0, 0, "", baseDirectory, nil, , , , {}, nil, , , , , , , , isBaseType or false)
	xmlFile:iterate("map.fillTypes.fillType", function (_, key)
		local name = xmlFile:getValue(key .. "#name")
		local title = xmlFile:getValue(key .. "#title")
		local achievementName = xmlFile:getValue(key .. "#achievementName")
		local showOnPriceTable = xmlFile:getValue(key .. "#showOnPriceTable")
		local fillPlaneColors = xmlFile:getValue(key .. "#fillPlaneColors", "1.0 1.0 1.0", true)
		local unitShort = xmlFile:getValue(key .. "#unitShort", "")
		local kgPerLiter = xmlFile:getValue(key .. ".physics#massPerLiter")
		local massPerLiter = kgPerLiter and kgPerLiter / 1000
		local maxPhysicalSurfaceAngle = xmlFile:getValue(key .. ".physics#maxPhysicalSurfaceAngle")
		local hudFilename = xmlFile:getValue(key .. ".image#hud")
		local palletFilename = xmlFile:getValue(key .. ".pallet#filename")
		local pricePerLiter = xmlFile:getValue(key .. ".economy#pricePerLiter")
		local economicCurve = {}

		xmlFile:iterate(key .. ".economy.factors.factor", function (_, factorKey)
			local period = xmlFile:getValue(factorKey .. "#period")
			local factor = xmlFile:getValue(factorKey .. "#value")

			if period ~= nil and factor ~= nil then
				economicCurve[period] = factor
			end
		end)

		local diffuseMapFilename = xmlFile:getValue(key .. ".textures#diffuse")
		local normalMapFilename = xmlFile:getValue(key .. ".textures#normal")
		local specularMapFilename = xmlFile:getValue(key .. ".textures#specular")
		local distanceFilename = xmlFile:getValue(key .. ".textures#distance")
		local customEnv = nil

		if missionInfo ~= nil then
			customEnv = missionInfo.customEnvironment
		end

		local prioritizedEffectType = xmlFile:getValue(key .. ".effects#prioritizedEffectType") or "ShaderPlaneEffect"
		local fillSmokeColor = xmlFile:getValue(key .. ".effects#fillSmokeColor", nil, true)
		local fruitSmokeColor = xmlFile:getValue(key .. ".effects#fruitSmokeColor", nil, true)

		self:addFillType(name, title, showOnPriceTable, pricePerLiter, massPerLiter, maxPhysicalSurfaceAngle, hudFilename, baseDirectory, customEnv, fillPlaneColors, unitShort, palletFilename, economicCurve, diffuseMapFilename, normalMapFilename, specularMapFilename, distanceFilename, prioritizedEffectType, fillSmokeColor, fruitSmokeColor, achievementName, isBaseType or false)
	end)
	xmlFile:iterate("map.fillTypeCategories.fillTypeCategory", function (_, key)
		local name = xmlFile:getValue(key .. "#name")
		local fillTypesStr = xmlFile:getValue(key) or ""
		local fillTypeCategoryIndex = self:addFillTypeCategory(name, isBaseType)

		if fillTypeCategoryIndex ~= nil then
			local fillTypeNames = fillTypesStr:split(" ")

			for _, fillTypeName in ipairs(fillTypeNames) do
				local fillType = self:getFillTypeByName(fillTypeName)

				if fillType ~= nil then
					if not self:addFillTypeToCategory(fillType.index, fillTypeCategoryIndex) then
						Logging.warning("Could not add fillType '" .. tostring(fillTypeName) .. "' to fillTypeCategory '" .. tostring(name) .. "'!")
					end
				else
					Logging.warning("Unknown FillType '" .. tostring(fillTypeName) .. "' in fillTypeCategory '" .. tostring(name) .. "'!")
				end
			end
		end
	end)
	xmlFile:iterate("map.fillTypeConverters.fillTypeConverter", function (_, key)
		local name = xmlFile:getValue(key .. "#name")
		local converter = self:addFillTypeConverter(name, isBaseType)

		if converter ~= nil then
			xmlFile:iterate(key .. ".converter", function (_, converterKey)
				local from = xmlFile:getValue(converterKey .. "#from")
				local to = xmlFile:getValue(converterKey .. "#to")
				local factor = xmlFile:getValue(converterKey .. "#factor")
				local sourceFillType = g_fillTypeManager:getFillTypeByName(from)
				local targetFillType = g_fillTypeManager:getFillTypeByName(to)

				if sourceFillType ~= nil and targetFillType ~= nil and factor ~= nil then
					self:addFillTypeConversion(converter, sourceFillType.index, targetFillType.index, factor)
				end
			end)
		end
	end)
	xmlFile:iterate("map.fillTypeSounds.fillTypeSound", function (_, key)
		local sample = g_soundManager:loadSampleFromXML(xmlFile, key, "sound", baseDirectory, getRootNode(), 0, AudioGroup.VEHICLE, nil, )

		if sample ~= nil then
			local entry = {
				sample = sample,
				fillTypes = {}
			}
			local fillTypesStr = xmlFile:getValue(key .. "#fillTypes") or ""

			if fillTypesStr ~= nil then
				local fillTypeNames = fillTypesStr:split(" ")

				for _, fillTypeName in ipairs(fillTypeNames) do
					local fillType = self:getFillTypeIndexByName(fillTypeName)

					if fillType ~= nil then
						table.insert(entry.fillTypes, fillType)

						self.fillTypeToSample[fillType] = sample
					else
						Logging.warning("Unable to load fill type '%s' for fillTypeSound '%s'", fillTypeName, key)
					end
				end
			end

			if xmlFile:getValue(key .. "#isDefault") then
				for fillType, _ in ipairs(self.fillTypes) do
					if self.fillTypeToSample[fillType] == nil then
						self.fillTypeToSample[fillType] = sample
					end
				end
			end

			table.insert(self.fillTypeSamples, entry)
		end
	end)

	return true
end

function FillTypeManager:addFillType(name, title, showOnPriceTable, pricePerLiter, massPerLiter, maxPhysicalSurfaceAngle, hudOverlayFilename, baseDirectory, customEnv, fillPlaneColors, unitShort, palletFilename, economicCurve, diffuseMapFilename, normalMapFilename, specularMapFilename, distanceFilename, prioritizedEffectType, fillSmokeColor, fruitSmokeColor, achievementName, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		Logging.warning("'%s' is not a valid name for a fillType. Ignoring fillType!", tostring(name))

		return nil
	end

	name = name:upper()

	if isBaseType and self.nameToFillType[name] ~= nil then
		Logging.warning("FillType '%s' already exists. Ignoring fillType!", name)

		return nil
	end

	local fillType = self.nameToFillType[name]

	if fillType == nil then
		local maxNumFillTypes = 2^FillTypeManager.SEND_NUM_BITS - 1

		if maxNumFillTypes <= #self.fillTypes then
			Logging.error("FillTypeManager.addFillType too many fill types. Only %d fill types are supported", maxNumFillTypes)

			return
		end

		fillType = {
			name = name,
			index = #self.fillTypes + 1,
			title = g_i18n:convertText(title, customEnv)
		}

		if unitShort ~= nil then
			unitShort = g_i18n:convertText(unitShort, customEnv)
		end

		fillType.unitShort = unitShort
		self.nameToFillType[name] = fillType
		self.nameToIndex[name] = fillType.index
		self.indexToName[fillType.index] = name
		self.indexToFillType[fillType.index] = fillType

		table.insert(self.fillTypes, fillType)
	end

	fillType.achievementName = achievementName
	fillType.showOnPriceTable = Utils.getNoNil(showOnPriceTable, Utils.getNoNil(fillType.showOnPriceTable, false))
	fillType.pricePerLiter = Utils.getNoNil(pricePerLiter, Utils.getNoNil(fillType.pricePerLiter, 0))
	fillType.massPerLiter = Utils.getNoNil(massPerLiter, Utils.getNoNil(fillType.massPerLiter, 0.0001)) * FillTypeManager.MASS_SCALE
	fillType.maxPhysicalSurfaceAngle = Utils.getNoNilRad(maxPhysicalSurfaceAngle, Utils.getNoNil(fillType.maxPhysicalSurfaceAngle, math.rad(30)))
	fillType.hudOverlayFilename = hudOverlayFilename and Utils.getFilename(hudOverlayFilename, baseDirectory) or fillType.hudOverlayFilename

	if diffuseMapFilename ~= nil then
		fillType.diffuseMapFilename = Utils.getFilename(diffuseMapFilename, baseDirectory) or fillType.diffuseMapFilename
	end

	if normalMapFilename ~= nil then
		fillType.normalMapFilename = Utils.getFilename(normalMapFilename, baseDirectory) or fillType.normalMapFilename
	end

	if specularMapFilename ~= nil then
		fillType.specularMapFilename = Utils.getFilename(specularMapFilename, baseDirectory) or fillType.specularMapFilename
	end

	if distanceFilename ~= nil then
		fillType.distanceFilename = Utils.getFilename(distanceFilename, baseDirectory) or fillType.distanceFilename
	end

	if fillType.index ~= FillType.UNKNOWN and (fillType.hudOverlayFilename == nil or fillType.hudOverlayFilename == "") then
		Logging.warning("FillType '%s' has no valid image assigned!", name)
	end

	if palletFilename ~= nil then
		palletFilename = Utils.getFilename(palletFilename, baseDirectory) or fillType.palletFilename

		if fileExists(palletFilename) then
			fillType.palletFilename = palletFilename
		else
			Logging.error("Pallet xml '%s' in fillType '%s' does not exist", palletFilename, fillType.name)
		end
	end

	fillType.previousHourPrice = fillType.pricePerLiter
	fillType.startPricePerLiter = fillType.pricePerLiter
	fillType.totalAmount = 0
	fillType.fillPlaneColors = {}

	if fillPlaneColors ~= nil then
		fillType.fillPlaneColors[1] = fillPlaneColors[1] or fillType.fillPlaneColors[1]
		fillType.fillPlaneColors[2] = fillPlaneColors[2] or fillType.fillPlaneColors[2]
		fillType.fillPlaneColors[3] = fillPlaneColors[3] or fillType.fillPlaneColors[3]
	else
		fillType.fillPlaneColors[1] = fillType.fillPlaneColors[1] or 1
		fillType.fillPlaneColors[2] = fillType.fillPlaneColors[2] or 1
		fillType.fillPlaneColors[3] = fillType.fillPlaneColors[3] or 1
	end

	fillType.economy = {
		factors = {}
	}

	for period = Environment.PERIOD.EARLY_SPRING, Environment.PERIOD.LATE_WINTER do
		fillType.economy.factors[period] = economicCurve[period] or 1
	end

	fillType.prioritizedEffectType = prioritizedEffectType

	if fillSmokeColor ~= nil and #fillSmokeColor == 4 then
		fillType.fillSmokeColor = fillSmokeColor
	end

	if fruitSmokeColor ~= nil and #fruitSmokeColor == 4 then
		fillType.fruitSmokeColor = fruitSmokeColor
	end

	return fillType
end

function FillTypeManager:constructFillTypeTextureArrays()
	self:deleteFillTypeTextureArrays()

	local diffuseMapConstr = TextureArrayConstructor.new()
	local normalMapConstr = TextureArrayConstructor.new()
	local specularMapConstr = TextureArrayConstructor.new()
	self.fillTypeTextureArraySize = 0

	for i = 1, #self.fillTypes do
		local fillType = self.fillTypes[i]

		if fillType.diffuseMapFilename ~= nil and fillType.normalMapFilename ~= nil and fillType.specularMapFilename ~= nil then
			diffuseMapConstr:addLayerFilename(fillType.diffuseMapFilename)
			normalMapConstr:addLayerFilename(fillType.normalMapFilename)
			specularMapConstr:addLayerFilename(fillType.specularMapFilename)

			self.fillTypeTextureArraySize = self.fillTypeTextureArraySize + 1
			fillType.textureArrayIndex = self.fillTypeTextureArraySize
		end
	end

	self.fillTypeTextureDiffuseMap = diffuseMapConstr:finalize(true, true, true)
	self.fillTypeTextureNormalMap = normalMapConstr:finalize(true, false, true)
	self.fillTypeTextureSpecularMap = specularMapConstr:finalize(true, false, true)
end

function FillTypeManager:getFillTypeTextureArrays()
	return self.fillTypeTextureDiffuseMap, self.fillTypeTextureNormalMap, self.fillTypeTextureSpecularMap, self.fillTypeTextureArraySize
end

function FillTypeManager:getFillTypeTextureArraySize()
	return self.fillTypeTextureArraySize
end

function FillTypeManager:assignFillTypeTextureArrays(nodeId, diffuse, normal, specular)
	local material = getMaterial(nodeId, 0)

	if self.fillTypeTextureDiffuseMap ~= nil and self.fillTypeTextureDiffuseMap ~= 0 and diffuse ~= false then
		material = setMaterialDiffuseMap(material, self.fillTypeTextureDiffuseMap, false)
	end

	if self.fillTypeTextureNormalMap ~= nil and self.fillTypeTextureNormalMap ~= 0 and normal ~= false then
		material = setMaterialNormalMap(material, self.fillTypeTextureNormalMap, false)
	end

	if self.fillTypeTextureSpecularMap ~= nil and self.fillTypeTextureSpecularMap ~= 0 and specular ~= false then
		material = setMaterialGlossMap(material, self.fillTypeTextureSpecularMap, false)
	end

	setMaterial(nodeId, material, 0)
end

function FillTypeManager:constructDensityMapHeightTextureArrays(heightTypes)
	self:deleteDensityMapHeightTextureArrays()

	local diffuseMapConstr = TextureArrayConstructor.new()
	local normalMapConstr = TextureArrayConstructor.new()
	local specularMapConstr = TextureArrayConstructor.new()

	for i = 1, #heightTypes do
		local heightType = heightTypes[i]
		local fillType = self.fillTypes[heightType.fillTypeIndex]

		if fillType ~= nil then
			if fillType.diffuseMapFilename ~= nil and fillType.normalMapFilename ~= nil and fillType.specularMapFilename ~= nil then
				diffuseMapConstr:addLayerFilename(fillType.diffuseMapFilename)
				normalMapConstr:addLayerFilename(fillType.normalMapFilename)
				specularMapConstr:addLayerFilename(fillType.specularMapFilename)
			else
				Logging.error("Failed to create density height map texture array. Fill type '%s' does not have textures defined!", heightType.fillTypeName)

				return false
			end
		end
	end

	self.densityMapHeightDiffuseMap = diffuseMapConstr:finalize(true, true, true)
	self.densityMapHeightNormalMap = normalMapConstr:finalize(true, false, true)
	self.densityMapHeightSpecularMap = specularMapConstr:finalize(true, false, true)
end

function FillTypeManager:deleteDensityMapHeightTextureArrays()
	if self.densityMapHeightDiffuseMap ~= nil then
		delete(self.densityMapHeightDiffuseMap)

		self.densityMapHeightDiffuseMap = nil
	end

	if self.densityMapHeightNormalMap ~= nil then
		delete(self.densityMapHeightNormalMap)

		self.densityMapHeightNormalMap = nil
	end

	if self.densityMapHeightSpecularMap ~= nil then
		delete(self.densityMapHeightSpecularMap)

		self.densityMapHeightSpecularMap = nil
	end
end

function FillTypeManager:assignDensityMapHeightTextureArrays(nodeId)
	if self.densityMapHeightDiffuseMap ~= nil and self.densityMapHeightNormalMap ~= nil and self.densityMapHeightSpecularMap ~= nil then
		local material = getMaterial(nodeId, 0)
		material = setMaterialDiffuseMap(material, self.densityMapHeightDiffuseMap, false)
		material = setMaterialNormalMap(material, self.densityMapHeightNormalMap, false)
		material = setMaterialGlossMap(material, self.densityMapHeightSpecularMap, false)

		setMaterial(nodeId, material, 0)
	end
end

function FillTypeManager:deleteFillTypeTextureArrays()
	if self.fillTypeTextureDiffuseMap ~= nil then
		delete(self.fillTypeTextureDiffuseMap)

		self.fillTypeTextureDiffuseMap = nil
	end

	if self.fillTypeTextureNormalMap ~= nil then
		delete(self.fillTypeTextureNormalMap)

		self.fillTypeTextureNormalMap = nil
	end

	if self.fillTypeTextureSpecularMap ~= nil then
		delete(self.fillTypeTextureSpecularMap)

		self.fillTypeTextureSpecularMap = nil
	end
end

function FillTypeManager:constructFillTypeDistanceTextureArray(terrainDetailHeightId, typeFirstChannel, typeNumChannels, heightTypes)
	local distanceConstr = TerrainDetailDistanceConstructor.new(typeFirstChannel, typeNumChannels)

	for i = 1, #heightTypes do
		local heightType = heightTypes[i]
		local fillType = self.fillTypes[heightType.fillTypeIndex]

		if fillType ~= nil then
			if fillType.distanceFilename ~= nil and fillType.distanceFilename:len() > 0 then
				distanceConstr:addTexture(i - 1, fillType.distanceFilename, 3)
			else
				Logging.error("Failed to create density height map distance texture array. Fill type '%s' does not have distance texture defined!", heightType.fillTypeName)

				return false
			end
		end
	end

	distanceConstr:finalize(terrainDetailHeightId)
end

function FillTypeManager:getTextureArrayIndexByFillTypeIndex(index)
	local fillType = self.fillTypes[index]

	return fillType and fillType.textureArrayIndex
end

function FillTypeManager:getPrioritizedEffectTypeByFillTypeIndex(index)
	local fillType = self.fillTypes[index]

	return fillType and fillType.prioritizedEffectType
end

function FillTypeManager:getSmokeColorByFillTypeIndex(index, fruitColor)
	local fillType = self.fillTypes[index]

	if fillType ~= nil then
		if not fruitColor then
			return fillType.fillSmokeColor
		else
			return fillType.fruitSmokeColor or fillType.fillSmokeColor
		end
	end

	return nil
end

function FillTypeManager:getFillTypeByIndex(index)
	return self.fillTypes[index]
end

function FillTypeManager:getFillTypeNameByIndex(index)
	return self.indexToName[index]
end

function FillTypeManager:getFillTypeNamesByIndices(indices)
	local names = {}

	for fillTypeIndex in pairs(indices) do
		table.insert(names, self.indexToName[fillTypeIndex])
	end

	return names
end

function FillTypeManager:getFillTypeIndexByName(name)
	return self.nameToIndex[name and name:upper()]
end

function FillTypeManager:getFillTypeByName(name)
	if ClassUtil.getIsValidIndexName(name) then
		return self.nameToFillType[name:upper()]
	end

	return nil
end

function FillTypeManager:getFillTypes()
	return self.fillTypes
end

function FillTypeManager:addFillTypeCategory(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a fillTypeCategory. Ignoring fillTypeCategory!")

		return nil
	end

	name = name:upper()

	if isBaseType and self.nameToCategoryIndex[name] ~= nil then
		print("Warning: FillTypeCategory '" .. tostring(name) .. "' already exists. Ignoring fillTypeCategory!")

		return nil
	end

	local index = self.nameToCategoryIndex[name]

	if index == nil then
		local categoryFillTypes = {}
		index = #self.categories + 1

		table.insert(self.categories, name)

		self.categoryNameToFillTypes[name] = categoryFillTypes
		self.categoryIndexToFillTypes[index] = categoryFillTypes
		self.nameToCategoryIndex[name] = index
	end

	return index
end

function FillTypeManager:addFillTypeToCategory(fillTypeIndex, categoryIndex)
	if categoryIndex ~= nil and fillTypeIndex ~= nil and self.categoryIndexToFillTypes[categoryIndex] ~= nil then
		self.categoryIndexToFillTypes[categoryIndex][fillTypeIndex] = true

		if self.fillTypeIndexToCategories[fillTypeIndex] == nil then
			self.fillTypeIndexToCategories[fillTypeIndex] = {}
		end

		self.fillTypeIndexToCategories[fillTypeIndex][categoryIndex] = true

		return true
	end

	return false
end

function FillTypeManager:getFillTypesByCategoryNames(names, warning, fillTypes)
	fillTypes = fillTypes or {}
	local alreadyAdded = {}
	local categories = string.split(names, " ")

	for _, categoryName in pairs(categories) do
		categoryName = categoryName:upper()
		local categoryFillTypes = self.categoryNameToFillTypes[categoryName]

		if categoryFillTypes ~= nil then
			for fillType, _ in pairs(categoryFillTypes) do
				if alreadyAdded[fillType] == nil then
					table.insert(fillTypes, fillType)

					alreadyAdded[fillType] = true
				end
			end
		elseif warning ~= nil then
			print(string.format(warning, categoryName))
		end
	end

	return fillTypes
end

function FillTypeManager:getIsFillTypeInCategory(fillTypeIndex, categoryName)
	local catgegoy = self.nameToCategoryIndex[categoryName]

	if catgegoy ~= nil and self.fillTypeIndexToCategories[fillTypeIndex] then
		return self.fillTypeIndexToCategories[fillTypeIndex][catgegoy] ~= nil
	end

	return false
end

function FillTypeManager:getFillTypesByNames(names, warning, fillTypes)
	fillTypes = fillTypes or {}
	local alreadyAdded = {}
	local fillTypeNames = string.split(names, " ")

	for _, name in pairs(fillTypeNames) do
		name = name:upper()
		local fillTypeIndex = self.nameToIndex[name]

		if fillTypeIndex ~= nil then
			if fillTypeIndex ~= FillType.UNKNOWN and alreadyAdded[fillTypeIndex] == nil then
				table.insert(fillTypes, fillTypeIndex)

				alreadyAdded[fillTypeIndex] = true
			end
		elseif warning ~= nil then
			print(string.format(warning, name))
		end
	end

	return fillTypes
end

function FillTypeManager:getFillTypesFromXML(xmlFile, categoryKey, namesKey, requiresFillTypes)
	local fillTypes = {}
	local fillTypeCategories = xmlFile:getValue(categoryKey)
	local fillTypeNames = xmlFile:getValue(namesKey)

	if fillTypeCategories ~= nil and fillTypeNames == nil then
		fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: '" .. xmlFile:getFilename() .. "' has invalid fillTypeCategory '%s'.")
	elseif fillTypeCategories == nil and fillTypeNames ~= nil then
		fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: '" .. xmlFile:getFilename() .. "' has invalid fillType '%s'.")
	elseif fillTypeCategories ~= nil and fillTypeNames ~= nil then
		Logging.xmlWarning(xmlFile, "fillTypeCategories and fillTypeNames are both set, only one of the two allowed")
	elseif requiresFillTypes ~= nil and requiresFillTypes then
		Logging.xmlWarning(xmlFile, "either the '%s' or '%s' attribute has to be set", categoryKey, namesKey)
	end

	return fillTypes
end

function FillTypeManager:addFillTypeConverter(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a fillTypeConverter. Ignoring fillTypeConverter!")

		return nil
	end

	name = name:upper()

	if isBaseType and self.nameToConverter[name] ~= nil then
		print("Warning: FillTypeConverter '" .. tostring(name) .. "' already exists. Ignoring FillTypeConverter!")

		return nil
	end

	local index = self.converterNameToIndex[name]

	if index == nil then
		local converter = {}

		table.insert(self.fillTypeConverters, converter)

		self.converterNameToIndex[name] = #self.fillTypeConverters
		self.nameToConverter[name] = converter
		index = #self.fillTypeConverters
	end

	return index
end

function FillTypeManager:addFillTypeConversion(converter, sourceFillTypeIndex, targetFillTypeIndex, conversionFactor)
	if converter ~= nil and self.fillTypeConverters[converter] ~= nil and sourceFillTypeIndex ~= nil and targetFillTypeIndex ~= nil then
		self.fillTypeConverters[converter][sourceFillTypeIndex] = {
			targetFillTypeIndex = targetFillTypeIndex,
			conversionFactor = conversionFactor
		}
	end
end

function FillTypeManager:getConverterDataByName(converterName)
	return self.nameToConverter[converterName and converterName:upper()]
end

function FillTypeManager:getSampleByFillType(fillType)
	return self.fillTypeToSample[fillType]
end

g_fillTypeManager = FillTypeManager.new()
