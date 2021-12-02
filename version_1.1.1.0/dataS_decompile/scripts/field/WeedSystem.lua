WeedSystem = {}
local WeedSystem_mt = Class(WeedSystem)

g_xmlManager:addCreateSchemaFunction(function ()
	WeedSystem.xmlSchema = XMLSchema.new("weed")
end)
g_xmlManager:addInitSchemaFunction(function ()
	local schema = WeedSystem.xmlSchema

	schema:register(XMLValueType.STRING, "map.weed#name", "Weed layer name")
	schema:register(XMLValueType.STRING, "map.weed#title", "Weed title")
	schema:register(XMLValueType.INT, "map.weed.general#firstChannel", "Weed first channel")
	schema:register(XMLValueType.INT, "map.weed.general#numChannels", "Weed num channels")
	schema:register(XMLValueType.VECTOR_4, "map.weed.mapColors#default", "Default map colors")
	schema:register(XMLValueType.VECTOR_4, "map.weed.mapColors#colorBlind", "Color blind map colors")
	schema:register(XMLValueType.INT, "map.weed.states.sparseStart#value", "Weed sparse state")
	schema:register(XMLValueType.INT, "map.weed.states.denseStart#value", "Weed sparse state")
	schema:register(XMLValueType.INT, "map.weed.growth.update(?)#sourceState", "Weed update source state")
	schema:register(XMLValueType.INT, "map.weed.growth.update(?)#targetState", "Weed update target state")
	schema:register(XMLValueType.INT, "map.weed.factors.factor(?)#state", "Weed factor state")
	schema:register(XMLValueType.FLOAT, "map.weed.factors.factor(?)#value", "Weed factor")
	schema:register(XMLValueType.INT, "map.weed.infoLayer#firstChannel", "Weed info layer first channel")
	schema:register(XMLValueType.INT, "map.weed.infoLayer#numChannels", "Weed info layer num channels")
	schema:register(XMLValueType.STRING, "map.weed.infoLayer#filename", "Weed info layer filename")
	schema:register(XMLValueType.INT, "map.weed.infoLayer.blockingState#value", "Weed info layer blocking value")
	schema:register(XMLValueType.INT, "map.weed.infoLayer.blockingState#firstChannel", "Weed info layer blocking first channel")
	schema:register(XMLValueType.INT, "map.weed.infoLayer.blockingState#numChannels", "Weed info layer blocking num channels")
	schema:register(XMLValueType.STRING, "map.replacements.herbicide.replacements(?)#fruitType", "Replacement fruittype. If undefined weed is used")
	schema:register(XMLValueType.INT, "map.replacements.herbicide.replacements(?).replacement(?)#sourceState", "Herbicide replacement source state")
	schema:register(XMLValueType.INT, "map.replacements.herbicide.replacements(?).replacement(?)#targetState", "Herbicide replacement target state")
	schema:register(XMLValueType.STRING, "map.replacements.weeder.replacements(?)#fruitType", "Replacement fruittype. If undefined weed is used")
	schema:register(XMLValueType.INT, "map.replacements.weeder.replacements(?).replacement(?)#sourceState", "Weeder replacement source state")
	schema:register(XMLValueType.INT, "map.replacements.weeder.replacements(?).replacement(?)#targetState", "Weeder replacement target state")
	schema:register(XMLValueType.STRING, "map.replacements.weederHoe.replacements(?)#fruitType", "Replacement fruittype. If undefined weed is used")
	schema:register(XMLValueType.INT, "map.replacements.weederHoe.replacements(?).replacement(?)#sourceState", "Weeder hoe replacement source state")
	schema:register(XMLValueType.INT, "map.replacements.weederHoe.replacements(?).replacement(?)#targetState", "Weeder hoe replacement target state")
	schema:register(XMLValueType.STRING, "map.replacements.mulcher.replacements(?)#fruitType", "Replacement fruittype. If undefined weed is used")
	schema:register(XMLValueType.INT, "map.replacements.mulcher.replacements(?).replacement(?)#sourceState", "Mulcher replacement source state")
	schema:register(XMLValueType.INT, "map.replacements.mulcher.replacements(?).replacement(?)#targetState", "Mulcher replacement target state")
end)

function WeedSystem.new(customMt)
	local self = setmetatable({}, customMt or WeedSystem_mt)
	self.baseDirectory = ""
	self.densityMap = nil
	self.herbicideReplacements = {}
	self.weederReplacements = {}
	self.weederHoeReplacements = {}
	self.mulcherReplacements = {}
	self.growthMapping = {}
	self.factors = {}
	self.infoLayer = nil
	self.mapColor = {
		0,
		0,
		0,
		0
	}
	self.mapColorBlind = {
		0,
		0,
		0,
		0
	}

	return self
end

function WeedSystem:delete()
	removeConsoleCommand("gsWeedSystemAddDelta")
	removeConsoleCommand("gsWeedSystemSetState")

	self.densityMap = nil

	if self.infoLayer ~= nil and self.infoLayer.map ~= nil then
		delete(self.infoLayer.map)
	end

	self.infoLayer = nil
end

function WeedSystem:loadWeed(filename)
	local xmlFile = XMLFile.load("weed", filename, WeedSystem.xmlSchema)
	self.name = xmlFile:getValue("map.weed#name") or self.name
	local title = xmlFile:getValue("map.weed#title")

	if title ~= nil then
		self.title = g_i18n:convertText(title) or self.title
	end

	self.firstChannel = xmlFile:getValue("map.weed.general#firstChannel") or self.firstChannel or 0
	self.numChannels = xmlFile:getValue("map.weed.general#numChannels") or self.numChannels or 3
	self.minValue = 1
	self.maxValue = 5
	self.mapColor = xmlFile:getValue("map.weed.mapColors#default", self.mapColor, 4)
	self.mapColorBlind = xmlFile:getValue("map.weed.mapColors#colorBlind", self.mapColorBlind, 4)

	self:loadInfoLayer(xmlFile, "map.weed.infoLayer")

	self.sparseStartState = xmlFile:getValue("map.weed.states.sparseStart#value") or 1
	self.denseStartState = xmlFile:getValue("map.weed.states.denseStart#value") or 2

	xmlFile:iterate("map.weed.growth.update", function (_, key)
		local sourceState = xmlFile:getValue(key .. "#sourceState")
		local targetState = xmlFile:getValue(key .. "#targetState")

		if sourceState ~= nil then
			self.growthMapping[sourceState] = targetState
		end
	end)
	xmlFile:iterate("map.weed.factors.factor", function (_, key)
		local state = xmlFile:getValue(key .. "#state")
		local value = xmlFile:getValue(key .. "#value")

		if state ~= nil and value ~= nil then
			self.factors[state] = value
		end
	end)
	self:loadReplacements(xmlFile, "map.replacements.herbicide", self.herbicideReplacements)
	self:loadReplacements(xmlFile, "map.replacements.weeder", self.weederReplacements)
	self:loadReplacements(xmlFile, "map.replacements.weederHoe", self.weederHoeReplacements)
	self:loadReplacements(xmlFile, "map.replacements.mulcher", self.mulcherReplacements)
	xmlFile:delete()
end

function WeedSystem:loadReplacements(xmlFile, key, replacements)
	xmlFile:iterate(key .. ".replacements", function (_, replacementsKey)
		local fruitType = nil
		local fruitTypeName = xmlFile:getValue(replacementsKey .. "#fruitType")

		if fruitTypeName ~= nil then
			fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)

			if fruitType == nil then
				Logging.xmlWarning(xmlFile, "FruitType '%s' not defined for '%s'", fruitTypeName, replacementsKey)

				return
			end
		end

		local data = {
			fruitType = fruitType,
			replacements = {}
		}
		local found = false

		xmlFile:iterate(replacementsKey .. ".replacement", function (_, replacementKey)
			local sourceState = xmlFile:getValue(replacementKey .. "#sourceState")
			local targetState = xmlFile:getValue(replacementKey .. "#targetState")

			if sourceState ~= nil then
				data.replacements[sourceState] = targetState
				found = true
			end
		end)

		if not found then
			Logging.xmlWarning(xmlFile, "No replacements defined for '%s'", replacementsKey)

			return
		end

		if data.fruitType == nil then
			replacements.weed = data
		else
			if replacements.custom == nil then
				replacements.custom = {}
			end

			table.insert(replacements.custom, data)
		end
	end)
end

function WeedSystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.baseDirectory = baseDirectory

	self:loadWeed("data/maps/maps_weed.xml")

	local filename = getXMLString(xmlFile, "map.weed#filename")

	if filename ~= nil then
		filename = Utils.getFilename(filename, baseDirectory)

		self:loadWeed(filename)
	end

	if g_currentMission:getIsServer() and g_addCheatCommands then
		addConsoleCommand("gsWeedSystemAddDelta", "Add weed delta to field", "consoleCommandAddDelta", self)
		addConsoleCommand("gsWeedSystemSetState", "Set weed state to field", "consoleCommandSetState", self)
	end

	return true
end

function WeedSystem:addDensityMapSyncer(densityMapSyncer)
	if self.densityMap ~= nil then
		densityMapSyncer:addDensityMap(self.densityMap)
	end
end

function WeedSystem:getMapHasWeed()
	return self.densityMap ~= nil
end

function WeedSystem:getDensityMapData()
	return self.densityMap, self.firstChannel, self.numChannels, self.minValue, self.maxValue
end

function WeedSystem:getHerbicideReplacements()
	return self.herbicideReplacements
end

function WeedSystem:getWeederReplacements(isHoeWeeder)
	if isHoeWeeder then
		return self.weederHoeReplacements
	end

	return self.weederReplacements
end

function WeedSystem:getMulcherReplacements()
	return self.mulcherReplacements
end

function WeedSystem:getGrowthMapping()
	return self.growthMapping
end

function WeedSystem:getColors()
	return self.mapColor, self.mapColorBlind
end

function WeedSystem:getTitle()
	return self.title
end

function WeedSystem:getSparseStartState()
	return self.sparseStartState
end

function WeedSystem:getDenseStartState()
	return self.denseStartState
end

function WeedSystem:getFactors()
	return self.factors
end

function WeedSystem:initTerrain(mission, terrainNode, terrainDetailId)
	local id = getTerrainDataPlaneByName(terrainNode, self.name)

	if id ~= nil and id ~= 0 then
		self.densityMap = id
		self.weedModifier = DensityMapModifier.new(self.densityMap, self.firstChannel, self.numChannels, g_currentMission.terrainNode)
		self.weedFilter = DensityMapFilter.new(self.densityMap, self.firstChannel, self.numChannels, g_currentMission.terrainNode)

		self.weedFilter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxValue)
	end

	local data = self.infoLayer

	if data ~= nil and data.filename ~= nil then
		data.map = createBitVectorMap("weedInfoLayer")
		local path = data.path
		local missionInfo = mission.missionInfo
		local loadFromSave = false

		if missionInfo.isValid then
			path = missionInfo.savegameDirectory .. "/" .. data.filename
			loadFromSave = true
		end

		if loadFromSave and not loadBitVectorMapFromFile(data.map, path, data.numChannels) then
			Logging.warning("Loading weed info layer file '" .. tostring(path) .. "' failed! Loading default.")

			loadFromSave = false
		end

		if not loadFromSave and not loadBitVectorMapFromFile(data.map, data.path, data.numChannels) then
			Logging.warning("Loading weed info layer file '" .. tostring(data.path) .. "' failed!")
		end

		data.width, data.height = getBitVectorMapSize(data.map)
		data.isBitVector = true
		data.canBeDeleted = true
	else
		self.infoLayer = nil
	end
end

function WeedSystem:loadInfoLayer(xmlFile, key)
	local data = self.infoLayer or {}
	data.firstChannel = xmlFile:getValue(key .. "#firstChannel") or data.firstChannel or 0
	data.numChannels = xmlFile:getValue(key .. "#numChannels") or data.numChannels or 1
	local filename = xmlFile:getValue(key .. "#filename")

	if filename ~= nil then
		data.path = Utils.getFilename(filename, self.baseDirectory)
		data.filename = Utils.getFilenameFromPath(data.path)
	end

	data.maxValue = 2^data.numChannels - 1
	data.blockingState = data.blockingState or {}
	data.blockingState.value = xmlFile:getValue(key .. ".blockingState#value") or data.blockingState.value or 1
	data.blockingState.firstChannel = xmlFile:getValue(key .. ".blockingState#firstChannel") or data.blockingState.firstChannel or 0
	data.blockingState.numChannels = xmlFile:getValue(key .. ".blockingState#numChannels") or data.blockingState.numChannels or 1
	self.infoLayer = data

	return true
end

function WeedSystem:getBlockingStateData()
	local data = self.infoLayer

	if data == nil then
		return nil
	end

	local blockingState = data.blockingState

	return blockingState.value, blockingState.firstChannel, blockingState.numChannels
end

function WeedSystem:getInfoLayerData()
	local data = self.infoLayer

	if data == nil then
		return nil
	end

	return data.map, data.firstChannel, data.numChannels
end

function WeedSystem:getInfoLayer()
	return self.infoLayer
end

function WeedSystem:consoleCommandAddDelta(fieldIndex, delta)
	fieldIndex = tonumber(fieldIndex)
	delta = tonumber(delta) or 1

	if fieldIndex == nil then
		return "Missing field index. gsWeedSystemAddDelta <fieldIndex> [<delta>]"
	end

	if self.weedModifier == nil then
		return "No weed defined for current map"
	end

	local field = g_fieldManager:getFieldByIndex(fieldIndex)
	local numDimensions = getNumOfChildren(field.fieldDimensions)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(field.fieldDimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x, _, z = getWorldTranslation(dimStart)
		local x1, _, z1 = getWorldTranslation(dimWidth)
		local x2, _, z2 = getWorldTranslation(dimHeight)

		self.weedModifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
		self.weedModifier:executeAdd(delta)
		self.weedModifier:executeSet(self.maxValue, self.weedFilter)
	end

	return "Added delta " .. delta
end

function WeedSystem:consoleCommandSetState(fieldIndex, state)
	fieldIndex = tonumber(fieldIndex)
	state = tonumber(state) or 1

	if fieldIndex == nil then
		return "Missing field index. gsWeedSystemSetState <fieldIndex> [<state>]"
	end

	if self.weedModifier == nil then
		return "No weed defined for current map"
	end

	local field = g_fieldManager:getFieldByIndex(fieldIndex)
	local numDimensions = getNumOfChildren(field.fieldDimensions)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(field.fieldDimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x, _, z = getWorldTranslation(dimStart)
		local x1, _, z1 = getWorldTranslation(dimWidth)
		local x2, _, z2 = getWorldTranslation(dimHeight)

		self.weedModifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
		self.weedModifier:executeSet(state)
	end

	return "Added state " .. state
end
