FruitType = nil
FruitTypeCategory = nil
FruitTypeConverter = nil
FruitTypeManager = {
	SEND_NUM_BITS = 6
}

g_xmlManager:addCreateSchemaFunction(function ()
	FruitTypeManager.xmlSchema = XMLSchema.new("fruitTypes")
end)
g_xmlManager:addInitSchemaFunction(function ()
	local schema = FruitTypeManager.xmlSchema
	local fruitTypeKey = "map.fruitTypes.fruitType(?)"

	schema:register(XMLValueType.STRING, fruitTypeKey .. "#name", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. "#shownOnMap", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. "#useForFieldJob", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".general#startStateChannel", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".general#numStateChannels", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. ".cultivation#needsSeeding", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. ".cultivation#allowsSeeding", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".cultivation#directionSnapAngle", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. ".cultivation#alignsToSun", "")
	schema:register(XMLValueType.FLOAT, fruitTypeKey .. ".cultivation#seedUsagePerSqm", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. ".cultivation#plantsWeed", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. ".cultivation#needsRolling", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".cultivation.state(?)#state", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".harvest#weedState", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".harvest#minHarvestingGrowthState", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".harvest#maxHarvestingGrowthState", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".harvest#cutState", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".harvest#minForageGrowthState", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. ".harvest#allowsPartialGrowthState", "")
	schema:register(XMLValueType.FLOAT, fruitTypeKey .. ".harvest#literPerSqm", "")
	schema:register(XMLValueType.FLOAT, fruitTypeKey .. ".harvest#cutHeight", "")
	schema:register(XMLValueType.FLOAT, fruitTypeKey .. ".harvest#forageCutHeight", "")
	schema:register(XMLValueType.FLOAT, fruitTypeKey .. ".harvest#beeYieldBonusPercentage", "")
	schema:register(XMLValueType.STRING, fruitTypeKey .. ".harvest#chopperTypeName", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".harvest.transition(?)#srcState", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".harvest.transition(?)#targetState", "")
	schema:register(XMLValueType.STRING, fruitTypeKey .. ".harvestGroundTypeChange#groundType", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".growth#witheredState", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".growth#numGrowthStates", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".growth#growthStateTime", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. ".growth#resetsSpray", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. ".growth#growthRequiresLime", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. ".growth#regrows", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".growth#firstRegrowthState", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".growth#minWitheredState", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".growth#maxWitheredState", "")
	schema:register(XMLValueType.STRING, fruitTypeKey .. ".preparing#outputName", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".preparing#minGrowthState", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".preparing#maxGrowthState", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".preparing#preparedGrowthState", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".growthGroundTypeChange#state", "")
	schema:register(XMLValueType.STRING, fruitTypeKey .. ".growthGroundTypeChange#groundType", "")
	schema:register(XMLValueType.STRING, fruitTypeKey .. ".growthGroundTypeChange#groundTypeMask", "")
	schema:register(XMLValueType.STRING, fruitTypeKey .. ".windrow#name", "")
	schema:register(XMLValueType.FLOAT, fruitTypeKey .. ".windrow#litersPerSqm", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".cropCare#maxWeederState", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".cropCare#maxWeederHoeState", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. ".options#lowSoilDensityRequired", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. ".options#increasesSoilDensity", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. ".options#consumesLime", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".options#startSprayState", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. ".destruction#canBeDestroyed", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".destruction#filterStart", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".destruction#filterEnd", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".destruction#state", "")
	schema:register(XMLValueType.INT, fruitTypeKey .. ".mulcher#state", "")
	schema:register(XMLValueType.BOOL, fruitTypeKey .. ".mulcher#hasChopperGroundLayer", "")
	schema:register(XMLValueType.STRING, fruitTypeKey .. ".mulcher#chopperTypeName", "")
	schema:register(XMLValueType.VECTOR_4, fruitTypeKey .. ".mapColors#default", "")
	schema:register(XMLValueType.VECTOR_4, fruitTypeKey .. ".mapColors#colorBlind", "")

	local fruitTypeCategoriesKey = "map.fruitTypeCategories.fruitTypeCategory(?)"

	schema:register(XMLValueType.STRING, fruitTypeCategoriesKey .. "#name", "")
	schema:register(XMLValueType.STRING, fruitTypeCategoriesKey, "")

	local fruitTypeConverterssKey = "map.fruitTypeConverters.fruitTypeConverter(?)"

	schema:register(XMLValueType.STRING, fruitTypeConverterssKey .. "#name", "")
	schema:register(XMLValueType.STRING, fruitTypeConverterssKey .. ".converter(?)#from", "")
	schema:register(XMLValueType.STRING, fruitTypeConverterssKey .. ".converter(?)#to", "")
	schema:register(XMLValueType.FLOAT, fruitTypeConverterssKey .. ".converter(?)#factor", "")
	schema:register(XMLValueType.FLOAT, fruitTypeConverterssKey .. ".converter(?)#windrowFactor", "")
end)

local FruitTypeManager_mt = Class(FruitTypeManager, AbstractManager)

function FruitTypeManager.new(customMt)
	local self = AbstractManager.new(customMt or FruitTypeManager_mt)

	return self
end

function FruitTypeManager:initDataStructures()
	self.fruitTypes = {}
	self.indexToFruitType = {}
	self.nameToIndex = {}
	self.nameToFruitType = {}
	self.fruitTypeIndexToFillType = {}
	self.fillTypeIndexToFruitTypeIndex = {}
	self.fruitTypeConverters = {}
	self.converterNameToIndex = {}
	self.nameToConverter = {}
	self.windrowFillTypes = {}
	self.fruitTypeIndexToWindrowFillTypeIndex = {}
	self.numCategories = 0
	self.categories = {}
	self.indexToCategory = {}
	self.categoryToFruitTypes = {}
	FruitType = self.nameToIndex
	FruitType.UNKNOWN = 0
	FruitTypeCategory = self.categories
	FruitTypeConverter = self.converterNameToIndex
end

function FruitTypeManager:loadDefaultTypes()
	local xmlFile = loadXMLFile("fuitTypes", "data/maps/maps_fruitTypes.xml")

	self:loadFruitTypes(xmlFile, nil, true)
	delete(xmlFile)
end

function FruitTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	FruitTypeManager:superClass().loadMapData(self)
	self:loadDefaultTypes()

	return XMLUtil.loadDataFromMapXML(xmlFile, "fruitTypes", baseDirectory, self, self.loadFruitTypes, missionInfo)
end

function FruitTypeManager:loadFruitTypes(xmlFile, missionInfo, isBaseType)
	local i = 0

	while true do
		local key = string.format("map.fruitTypes.fruitType(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local shownOnMap = getXMLBool(xmlFile, key .. "#shownOnMap")
		local useForFieldJob = getXMLBool(xmlFile, key .. "#useForFieldJob")
		local missionMultiplier = getXMLFloat(xmlFile, key .. "#missionMultiplier")
		local fruitType = self:addFruitType(name, shownOnMap, useForFieldJob, missionMultiplier, isBaseType)

		if fruitType ~= nil then
			local success = true
			success = success and self:loadFruitTypeGeneral(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeWindrow(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeGrowth(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeHarvest(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeCultivation(fruitType, xmlFile, key)
			success = success and self:loadFruitTypePreparing(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeCropCare(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeOptions(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeMapColors(fruitType, xmlFile, key)
			success = success and self:loadFruitTypeDestruction(fruitType, xmlFile, key)

			if success and self.indexToFruitType[fruitType.index] == nil then
				local maxNumFruitTypes = 2^FruitTypeManager.SEND_NUM_BITS - 1

				if maxNumFruitTypes <= #self.fruitTypes then
					Logging.error("FruitTypeManager.loadFruitTypes too many fruit types. Only %d fruit types are supported", maxNumFruitTypes)

					return
				end

				table.insert(self.fruitTypes, fruitType)

				self.nameToFruitType[fruitType.name] = fruitType
				self.nameToIndex[fruitType.name] = fruitType.index
				self.indexToFruitType[fruitType.index] = fruitType
				self.fillTypeIndexToFruitTypeIndex[fruitType.fillType.index] = fruitType.index
				self.fruitTypeIndexToFillType[fruitType.index] = fruitType.fillType
			end
		end

		i = i + 1
	end

	i = 0

	while true do
		local key = string.format("map.fruitTypeCategories.fruitTypeCategory(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local fruitTypesStr = getXMLString(xmlFile, key)
		local fruitTypeCategoryIndex = self:addFruitTypeCategory(name, isBaseType)

		if fruitTypeCategoryIndex ~= nil then
			local fruitTypeNames = string.split(fruitTypesStr, " ")

			for _, fruitTypeName in ipairs(fruitTypeNames) do
				local fruitType = self:getFruitTypeByName(fruitTypeName)

				if fruitType ~= nil then
					if not self:addFruitTypeToCategory(fruitType.index, fruitTypeCategoryIndex) then
						print("Warning: Could not add fruitType '" .. tostring(fruitTypeName) .. "' to fruitTypeCategory '" .. tostring(name) .. "'!")
					end
				else
					print("Warning: FruitType '" .. tostring(fruitTypeName) .. "' referenced in fruitTypeCategory '" .. tostring(name) .. "' is not defined!")
				end
			end
		end

		i = i + 1
	end

	i = 0

	while true do
		local key = string.format("map.fruitTypeConverters.fruitTypeConverter(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local converter = self:addFruitTypeConverter(name, isBaseType)

		if converter ~= nil then
			local j = 0

			while true do
				local converterKey = string.format("%s.converter(%d)", key, j)

				if not hasXMLProperty(xmlFile, converterKey) then
					break
				end

				local from = getXMLString(xmlFile, converterKey .. "#from")
				local to = getXMLString(xmlFile, converterKey .. "#to")
				local factor = getXMLFloat(xmlFile, converterKey .. "#factor")
				local windrowFactor = getXMLFloat(xmlFile, converterKey .. "#windrowFactor")
				local fruitType = self:getFruitTypeByName(from)
				local fillType = g_fillTypeManager:getFillTypeByName(to)

				if fruitType ~= nil and fillType ~= nil and factor ~= nil then
					self:addFruitTypeConversion(converter, fruitType.index, fillType.index, factor, windrowFactor)
				end

				j = j + 1
			end
		end

		i = i + 1
	end

	return true
end

function FruitTypeManager:addFruitType(name, shownOnMap, useForFieldJob, missionMultiplier, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a fruitType. Ignoring fruitType!")

		return nil
	end

	local upperName = name:upper()
	local fillType = g_fillTypeManager:getFillTypeByName(upperName)

	if fillType == nil then
		print("Warning: Missing fillType '" .. tostring(name) .. "' for fruitType definition. Ignoring fruitType!")

		return nil
	end

	if isBaseType and self.nameToFruitType[upperName] ~= nil then
		print("Warning: FillType '" .. tostring(name) .. "' already exists. Ignoring fillType!")

		return nil
	end

	local fruitType = self.nameToFruitType[upperName]

	if fruitType == nil then
		fruitType = {
			layerName = name,
			name = upperName,
			index = #self.fruitTypes + 1,
			fillType = fillType,
			defaultMapColor = {
				1,
				1,
				1,
				1
			},
			colorBlindMapColor = {
				1,
				1,
				1,
				1
			}
		}
	end

	fruitType.shownOnMap = Utils.getNoNil(shownOnMap, Utils.getNoNil(fruitType.shownOnMap, true))
	fruitType.useForFieldJob = Utils.getNoNil(useForFieldJob, Utils.getNoNil(fruitType.useForFieldJob, true))
	fruitType.missionMultiplier = Utils.getNoNil(missionMultiplier, Utils.getNoNil(fruitType.missionMultiplier, 1))

	return fruitType
end

function FruitTypeManager:loadFruitTypeGeneral(fruitType, xmlFile, key)
	if fruitType ~= nil then
		fruitType.startStateChannel = Utils.getNoNil(getXMLInt(xmlFile, key .. ".general#startStateChannel"), Utils.getNoNil(fruitType.startStateChannel, 0))
		fruitType.numStateChannels = Utils.getNoNil(getXMLInt(xmlFile, key .. ".general#numStateChannels"), Utils.getNoNil(fruitType.numStateChannels, 4))
	end

	return true
end

function FruitTypeManager:loadFruitTypeWindrow(fruitType, xmlFile, key)
	if fruitType ~= nil then
		local windrowName = getXMLString(xmlFile, key .. ".windrow#name")
		local windrowLitersPerSqm = getXMLFloat(xmlFile, key .. ".windrow#litersPerSqm")

		if windrowName == nil or windrowLitersPerSqm == nil then
			return true
		end

		local windrowFillType = g_fillTypeManager:getFillTypeByName(windrowName)

		if windrowFillType == nil then
			print("Warning: Mission fillType '" .. tostring(windrowName) .. "' for windrow definition. Ignoring windrow!")

			return false
		end

		fruitType.hasWindrow = true
		fruitType.windrowName = windrowFillType.name
		fruitType.windrowLiterPerSqm = windrowLitersPerSqm
		self.windrowFillTypes[windrowFillType.index] = true
		self.fruitTypeIndexToWindrowFillTypeIndex[fruitType.index] = windrowFillType.index
		self.fillTypeIndexToFruitTypeIndex[windrowFillType.index] = fruitType.index
	end

	return true
end

function FruitTypeManager:loadFruitTypeGrowth(fruitType, xmlFile, key)
	if fruitType ~= nil then
		fruitType.isGrowing = Utils.getNoNil(getXMLBool(xmlFile, key .. ".growth#isGrowing"), Utils.getNoNil(fruitType.isGrowing, true))

		if fruitType.isGrowing then
			fruitType.numGrowthStates = Utils.getNoNil(getXMLInt(xmlFile, key .. ".growth#numGrowthStates"), Utils.getNoNil(fruitType.numGrowthStates, 0))
			fruitType.resetsSpray = Utils.getNoNil(getXMLBool(xmlFile, key .. ".growth#resetsSpray"), Utils.getNoNil(fruitType.resetsSpray, true))
			fruitType.growthRequiresLime = Utils.getNoNil(getXMLInt(xmlFile, key .. ".growth#requiresLime"), Utils.getNoNil(fruitType.growthRequiresLime, true))
			fruitType.witheredState = getXMLInt(xmlFile, key .. ".growth#witheredState") or fruitType.witheredState
			fruitType.groundTypeChangeGrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".growthGroundTypeChange#state"), Utils.getNoNil(fruitType.groundTypeChangeGrowthState, -1))
			local groundTypeStr = getXMLString(xmlFile, key .. ".growthGroundTypeChange#groundType")

			if groundTypeStr ~= nil then
				local groundType = FieldGroundType.getByName(groundTypeStr)

				if groundType == nil then
					Logging.warning("Invalid groundTypeChanged name '%s'. Ignoring growth data!", groundTypeStr)

					return false
				end

				fruitType.groundTypeChangeType = groundType
			end

			fruitType.groundTypeChangeMaskTypes = {}
			local groundTypeChangeMaskString = getXMLString(xmlFile, key .. ".growthGroundTypeChange#groundTypeMask")

			if groundTypeChangeMaskString ~= nil then
				local groundTypeChangeMaskList = groundTypeChangeMaskString:split(" ")

				for _, v in ipairs(groundTypeChangeMaskList) do
					local groundType = FieldGroundType.getByName(v)

					if groundType ~= nil then
						table.insert(fruitType.groundTypeChangeMaskTypes, groundType)
					else
						Logging.warning("Invalid groundTypeChangeMask name '%s'. Ignoring growth data!", v)

						return false
					end
				end
			end

			fruitType.regrows = Utils.getNoNil(getXMLBool(xmlFile, key .. ".growth#regrows"), Utils.getNoNil(fruitType.regrows, false))

			if fruitType.regrows then
				fruitType.firstRegrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".growth#firstRegrowthState"), Utils.getNoNil(fruitType.firstRegrowthState, 1))
			end
		end

		return true
	end

	return false
end

function FruitTypeManager:loadFruitTypeHarvest(fruitType, xmlFile, key)
	if fruitType ~= nil then
		fruitType.minHarvestingGrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".harvest#minHarvestingGrowthState"), Utils.getNoNil(fruitType.minHarvestingGrowthState, 0))
		fruitType.maxHarvestingGrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".harvest#maxHarvestingGrowthState"), Utils.getNoNil(fruitType.maxHarvestingGrowthState, 0))
		fruitType.minForageGrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".harvest#minForageGrowthState"), Utils.getNoNil(fruitType.minForageGrowthState, fruitType.minHarvestingGrowthState))
		fruitType.cutState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".harvest#cutState"), Utils.getNoNil(fruitType.cutState, 0))
		fruitType.allowsPartialGrowthState = Utils.getNoNil(getXMLBool(xmlFile, key .. ".harvest#allowsPartialGrowthState"), Utils.getNoNil(fruitType.allowsPartialGrowthState, false))
		fruitType.literPerSqm = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".harvest#literPerSqm"), Utils.getNoNil(fruitType.literPerSqm, 0))
		fruitType.cutHeight = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".harvest#cutHeight"), fruitType.cutHeight)
		fruitType.forageCutHeight = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".harvest#forageCutHeight"), fruitType.forageCutHeight or fruitType.cutHeight)
		fruitType.beeYieldBonusPercentage = getXMLFloat(xmlFile, key .. ".harvest#beeYieldBonusPercentage") or 0
		local harvestGroundTypeChange = getXMLString(xmlFile, key .. ".harvestGroundTypeChange#groundType")

		if harvestGroundTypeChange ~= nil then
			local groundType = FieldGroundType.getByName(harvestGroundTypeChange)

			if groundType ~= nil then
				fruitType.harvestGroundTypeChange = groundType
			end
		end

		local chopperTypeName = getXMLString(xmlFile, key .. ".harvest#chopperTypeName") or nil

		if chopperTypeName ~= nil then
			fruitType.chopperTypeIndex = g_currentMission.fieldGroundSystem:getChopperTypeIndexByName(chopperTypeName)

			if fruitType.chopperTypeIndex == nil then
				Logging.warning("Invalid chopperTypeName name '%s' for '%s'.", chopperTypeName, key .. ".harvest")
			end
		end

		local transitions = nil
		local i = 0

		while true do
			local transitionKey = string.format("%s.harvest.transition(%d)", key, i)

			if not hasXMLProperty(xmlFile, transitionKey) then
				break
			end

			local srcState = getXMLInt(xmlFile, transitionKey .. "#srcState")
			local targetState = getXMLInt(xmlFile, transitionKey .. "#targetState")

			if srcState ~= nil and targetState ~= nil then
				if transitions == nil then
					transitions = {}
				end

				transitions[srcState] = targetState
			end

			i = i + 1
		end

		fruitType.harvestTransitions = transitions
		fruitType.harvestWeedState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".harvest#weedState"), Utils.getNoNil(fruitType.harvestWeedState, nil))

		return true
	end

	return false
end

function FruitTypeManager:loadFruitTypeCultivation(fruitType, xmlFile, key)
	if fruitType ~= nil then
		fruitType.needsSeeding = Utils.getNoNil(getXMLBool(xmlFile, key .. ".cultivation#needsSeeding"), Utils.getNoNil(fruitType.needsSeeding, true))
		fruitType.allowsSeeding = Utils.getNoNil(getXMLBool(xmlFile, key .. ".cultivation#allowsSeeding"), Utils.getNoNil(fruitType.allowsSeeding, true))
		fruitType.directionSnapAngle = Utils.getNoNilRad(getXMLFloat(xmlFile, key .. ".cultivation#directionSnapAngle"), Utils.getNoNil(fruitType.directionSnapAngle, 0))
		fruitType.alignsToSun = Utils.getNoNil(getXMLBool(xmlFile, key .. ".cultivation#alignsToSun"), Utils.getNoNil(fruitType.alignsToSun, false))
		fruitType.seedUsagePerSqm = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".cultivation#seedUsagePerSqm"), Utils.getNoNil(fruitType.seedUsagePerSqm, 0.1))
		fruitType.plantsWeed = Utils.getNoNil(getXMLBool(xmlFile, key .. ".cultivation#plantsWeed"), Utils.getNoNil(fruitType.plantsWeed, true))
		fruitType.needsRolling = Utils.getNoNil(getXMLBool(xmlFile, key .. ".cultivation#needsRolling"), Utils.getNoNil(fruitType.needsRolling, true))
		local cultivationStates = nil
		local i = 0

		while true do
			local cultivationKey = string.format("%s.cultivation.state(%d)", key, i)

			if not hasXMLProperty(xmlFile, cultivationKey) then
				break
			end

			local state = getXMLInt(xmlFile, cultivationKey .. "#state")

			if state ~= nil then
				if cultivationStates == nil then
					cultivationStates = {}
				end

				table.insert(cultivationStates, state)
			end

			i = i + 1
		end

		fruitType.cultivationStates = cultivationStates

		return true
	end

	return false
end

function FruitTypeManager:loadFruitTypePreparing(fruitType, xmlFile, key)
	if fruitType ~= nil then
		fruitType.preparingOutputName = Utils.getNoNil(getXMLString(xmlFile, key .. ".preparing#outputName"), fruitType.preparingOutputName)
		fruitType.minPreparingGrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".preparing#minGrowthState"), Utils.getNoNil(fruitType.minPreparingGrowthState, -1))
		fruitType.maxPreparingGrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".preparing#maxGrowthState"), Utils.getNoNil(fruitType.maxPreparingGrowthState, -1))
		fruitType.preparedGrowthState = Utils.getNoNil(getXMLInt(xmlFile, key .. ".preparing#preparedGrowthState"), Utils.getNoNil(fruitType.preparedGrowthState, -1))

		return true
	end

	return false
end

function FruitTypeManager:loadFruitTypeCropCare(fruitType, xmlFile, key)
	if fruitType ~= nil then
		fruitType.maxWeederState = getXMLInt(xmlFile, key .. ".cropCare#maxWeederState") or fruitType.maxWeederState or 2
		fruitType.maxWeederHoeState = getXMLInt(xmlFile, key .. ".cropCare#maxWeederHoeState") or fruitType.maxWeederHoeState or fruitType.maxWeederState

		return true
	end

	return false
end

function FruitTypeManager:loadFruitTypeOptions(fruitType, xmlFile, key)
	if fruitType ~= nil then
		fruitType.increasesSoilDensity = Utils.getNoNil(getXMLBool(xmlFile, key .. ".options#increasesSoilDensity"), Utils.getNoNil(fruitType.increasesSoilDensity, false))
		fruitType.lowSoilDensityRequired = Utils.getNoNil(getXMLBool(xmlFile, key .. ".options#lowSoilDensityRequired"), Utils.getNoNil(fruitType.lowSoilDensityRequired, true))
		fruitType.consumesLime = Utils.getNoNil(getXMLBool(xmlFile, key .. ".options#consumesLime"), Utils.getNoNil(fruitType.consumesLime, true))
		fruitType.startSprayState = math.max(Utils.getNoNil(getXMLInt(xmlFile, key .. ".options#startSprayState"), Utils.getNoNil(fruitType.startSprayState, 0)), 0)

		return true
	end

	return false
end

function FruitTypeManager:loadFruitTypeMapColors(fruitType, xmlFile, key)
	if fruitType ~= nil then
		local defaultColorString = getXMLString(xmlFile, key .. ".mapColors#default") or "1 1 1 1"
		local defaultColorBlindString = getXMLString(xmlFile, key .. ".mapColors#colorBlind") or "1 1 1 1"
		fruitType.defaultMapColor = GuiUtils.getColorArray(defaultColorString) or fruitType.defaultMapColor
		fruitType.colorBlindMapColor = GuiUtils.getColorArray(defaultColorBlindString) or fruitType.colorBlindMapColor

		return true
	end

	return false
end

function FruitTypeManager:loadFruitTypeDestruction(fruitType, xmlFile, key)
	if fruitType ~= nil then
		fruitType.destruction = fruitType.destruction or {}

		if hasXMLProperty(xmlFile, key .. ".destruction") then
			local destruction = fruitType.destruction
			destruction.onlyOnField = Utils.getNoNil(getXMLBool(xmlFile, key .. ".destruction#onlyOnField"), Utils.getNoNil(destruction.onlyOnField, true))
			destruction.filterStart = getXMLInt(xmlFile, key .. ".destruction#filterStart", destruction.filterStart)
			destruction.filterEnd = getXMLInt(xmlFile, key .. ".destruction#filterEnd", destruction.filterEnd)
			destruction.state = getXMLInt(xmlFile, key .. ".destruction#state") or destruction.state or fruitType.cutState
			destruction.canBeDestroyed = Utils.getNoNil(getXMLBool(xmlFile, key .. ".destruction#canBeDestroyed"), Utils.getNoNil(destruction.canBeDestroyed, true))
		end

		fruitType.mulcher = fruitType.mulcher or {}
		fruitType.mulcher.state = Utils.getNoNil(getXMLInt(xmlFile, key .. ".mulcher#state"), fruitType.mulcher.state or 2^fruitType.numStateChannels - 1)
		fruitType.mulcher.hasChopperGroundLayer = Utils.getNoNil(getXMLBool(xmlFile, key .. ".mulcher#hasChopperGroundLayer"), Utils.getNoNil(fruitType.mulcher.hasChopperGroundLayer, true))
		local chopperTypeName = getXMLString(xmlFile, key .. ".harvest#chopperTypeName") or "CHOPPER_STRAW"

		if chopperTypeName ~= nil then
			fruitType.mulcher.chopperTypeIndex = g_currentMission.fieldGroundSystem:getChopperTypeIndexByName(chopperTypeName)
		end

		local defaultColorString = getXMLString(xmlFile, key .. ".mapColors#default") or "1 1 1 1"
		local defaultColorBlindString = getXMLString(xmlFile, key .. ".mapColors#colorBlind") or "1 1 1 1"
		fruitType.defaultMapColor = GuiUtils.getColorArray(defaultColorString) or fruitType.defaultMapColor
		fruitType.colorBlindMapColor = GuiUtils.getColorArray(defaultColorBlindString) or fruitType.colorBlindMapColor

		return true
	end

	return false
end

function FruitTypeManager:getFruitTypeByIndex(index)
	return self.indexToFruitType[index]
end

function FruitTypeManager:getFruitTypeNameByIndex(index)
	if self.indexToFruitType[index] ~= nil then
		return self.indexToFruitType[index].name
	end

	return nil
end

function FruitTypeManager:getFruitTypeByName(name)
	return self.nameToFruitType[name and name:upper()]
end

function FruitTypeManager:getFruitTypes()
	return self.fruitTypes
end

function FruitTypeManager:getFruitTypeIndexByFillTypeIndex(index)
	return self.fillTypeIndexToFruitTypeIndex[index]
end

function FruitTypeManager:getFruitTypeByFillTypeIndex(index)
	return self.fruitTypes[self.fillTypeIndexToFruitTypeIndex[index]]
end

function FruitTypeManager:getFillTypeIndexByFruitTypeIndex(index)
	local fillType = self.fruitTypeIndexToFillType[index]

	if fillType ~= nil then
		return fillType.index
	end

	return nil
end

function FruitTypeManager:getFillTypeByFruitTypeIndex(index)
	return self.fruitTypeIndexToFillType[index]
end

function FruitTypeManager:getCutHeightByFruitTypeIndex(index, isForageCutter)
	local fruitType = self.indexToFruitType[index]

	if isForageCutter then
		return fruitType and (fruitType.forageCutHeight or fruitType.cutHeight) or 0.15
	end

	return fruitType and fruitType.cutHeight or 0.15
end

function FruitTypeManager:addFruitTypeCategory(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a fruitTypeCategory. Ignoring fruitTypeCategory!")

		return nil
	end

	name = name:upper()

	if isBaseType and self.categories[name] ~= nil then
		print("Warning: FruitTypeCategory '" .. tostring(name) .. "' already exists. Ignoring fruitTypeCategory!")

		return nil
	end

	local index = self.categories[name]

	if index == nil then
		self.numCategories = self.numCategories + 1
		self.categories[name] = self.numCategories
		self.indexToCategory[self.numCategories] = name
		self.categoryToFruitTypes[self.numCategories] = {}
		index = self.numCategories
	end

	return index
end

function FruitTypeManager:addFruitTypeToCategory(fruitTypeIndex, categoryIndex)
	if categoryIndex ~= nil and fruitTypeIndex ~= nil then
		table.insert(self.categoryToFruitTypes[categoryIndex], fruitTypeIndex)

		return true
	end

	return false
end

function FruitTypeManager:getFruitTypesByCategoryNames(names, warning)
	local fruitTypes = {}
	local alreadyAdded = {}
	local categories = string.split(names, " ")

	for _, categoryName in pairs(categories) do
		categoryName = categoryName:upper()
		local categoryIndex = self.categories[categoryName]
		local categoryFruitTypes = self.categoryToFruitTypes[categoryIndex]

		if categoryFruitTypes ~= nil then
			for _, fruitType in ipairs(categoryFruitTypes) do
				if alreadyAdded[fruitType] == nil then
					table.insert(fruitTypes, fruitType)

					alreadyAdded[fruitType] = true
				end
			end
		elseif warning ~= nil then
			print(string.format(warning, categoryName))
		end
	end

	return fruitTypes
end

function FruitTypeManager:getFruitTypesByNames(names, warning)
	local fruitTypes = {}
	local alreadyAdded = {}
	local fruitTypeNames = string.split(names, " ")

	for _, name in pairs(fruitTypeNames) do
		name = name:upper()
		local fruitTypeIndex = self.nameToIndex[name]

		if fruitTypeIndex ~= nil then
			if alreadyAdded[fruitTypeIndex] == nil then
				table.insert(fruitTypes, fruitTypeIndex)

				alreadyAdded[fruitTypeIndex] = true
			end
		elseif warning ~= nil then
			print(string.format(warning, name))
		end
	end

	return fruitTypes
end

function FruitTypeManager:getFillTypesByFruitTypeNames(names, warning)
	local fillTypes = {}
	local alreadyAdded = {}
	local fruitTypeNames = string.split(names, " ")

	for _, name in pairs(fruitTypeNames) do
		local fillType = nil
		local fruitType = self:getFruitTypeByName(name)

		if fruitType ~= nil then
			fillType = self:getFillTypeByFruitTypeIndex(fruitType.index)
		end

		if fillType ~= nil then
			if alreadyAdded[fillType.index] == nil then
				table.insert(fillTypes, fillType.index)

				alreadyAdded[fillType.index] = true
			end
		elseif warning ~= nil then
			print(string.format(warning, name))
		end
	end

	return fillTypes
end

function FruitTypeManager:getFillTypesByFruitTypeCategoryName(fruitTypeCategories, warning)
	local fillTypes = {}
	local alreadyAdded = {}
	local categories = string.split(fruitTypeCategories, " ")

	for _, categoryName in pairs(categories) do
		categoryName = categoryName:upper()
		local category = self.categories[categoryName]

		if category ~= nil then
			for _, fruitTypeIndex in ipairs(self.categoryToFruitTypes[category]) do
				local fillType = self:getFillTypeByFruitTypeIndex(fruitTypeIndex)

				if fillType ~= nil and alreadyAdded[fillType.index] == nil then
					table.insert(fillTypes, fillType.index)

					alreadyAdded[fillType.index] = true
				end
			end
		elseif warning ~= nil then
			print(string.format(warning, categoryName))
		end
	end

	return fillTypes
end

function FruitTypeManager:isFillTypeWindrow(index)
	if index ~= nil then
		return self.windrowFillTypes[index] == true
	end

	return false
end

function FruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(index)
	return self.fruitTypeIndexToWindrowFillTypeIndex[index]
end

function FruitTypeManager:getFillTypeLiterPerSqm(fillType, defaultValue)
	local fruitType = self.fruitTypes[self:getFruitTypeIndexByFillTypeIndex(fillType)]

	if fruitType ~= nil then
		if fruitType.hasWindrow then
			return fruitType.windrowLiterPerSqm
		else
			return fruitType.literPerSqm
		end
	end

	return defaultValue
end

function FruitTypeManager:addFruitTypeConverter(name, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a fruitTypeConverter. Ignoring fruitTypeConverter!")

		return nil
	end

	name = name:upper()

	if isBaseType and self.converterNameToIndex[name] ~= nil then
		print("Warning: FruitTypeConverter '" .. tostring(name) .. "' already exists. Ignoring fruitTypeConverter!")

		return nil
	end

	local index = self.converterNameToIndex[name]

	if index == nil then
		local converter = {}

		table.insert(self.fruitTypeConverters, converter)

		self.converterNameToIndex[name] = #self.fruitTypeConverters
		self.nameToConverter[name] = converter
		index = #self.fruitTypeConverters
	end

	return index
end

function FruitTypeManager:addFruitTypeConversion(converter, fruitTypeIndex, fillTypeIndex, conversionFactor, windrowConversionFactor)
	if converter ~= nil and self.fruitTypeConverters[converter] ~= nil and fruitTypeIndex ~= nil and fillTypeIndex ~= nil then
		self.fruitTypeConverters[converter][fruitTypeIndex] = {
			fillTypeIndex = fillTypeIndex,
			conversionFactor = conversionFactor,
			windrowConversionFactor = windrowConversionFactor
		}
	end
end

function FruitTypeManager:getConverterDataByName(converterName)
	return self.nameToConverter[converterName and converterName:upper()]
end

g_fruitTypeManager = FruitTypeManager.new()
