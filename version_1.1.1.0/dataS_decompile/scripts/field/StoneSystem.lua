StoneSystem = {}
local StoneSystem_mt = Class(StoneSystem)

g_xmlManager:addCreateSchemaFunction(function ()
	StoneSystem.xmlSchema = XMLSchema.new("stones")
end)
g_xmlManager:addInitSchemaFunction(function ()
	local schema = StoneSystem.xmlSchema

	schema:register(XMLValueType.STRING, "map.stones#name", "Stone layer name")
	schema:register(XMLValueType.STRING, "map.stones#title", "Stone title")
	schema:register(XMLValueType.INT, "map.stones.general#firstChannel", "Stone first channel")
	schema:register(XMLValueType.INT, "map.stones.general#numChannels", "Stone num channels")
	schema:register(XMLValueType.INT, "map.stones.picking#maskValue", "Stone mask value")
	schema:register(XMLValueType.INT, "map.stones.picking#minValue", "Stone min value")
	schema:register(XMLValueType.INT, "map.stones.picking#maxValue", "Stone max value")
	schema:register(XMLValueType.INT, "map.stones.picking#pickedValue", "Stone picked value")
	schema:register(XMLValueType.FLOAT, "map.stones.picking#litersPerSqm", "Stone liters per sqm")
	schema:register(XMLValueType.INT, "map.stones.growth.update(?)#period", "Stone update period")
	schema:register(XMLValueType.INT, "map.stones.growth.update(?)#sourceState", "Stone update source state")
	schema:register(XMLValueType.INT, "map.stones.growth.update(?)#targetState", "Stone update target state")
	schema:register(XMLValueType.STRING, "map.stones.wear.type(?)#name", "Vehicle type name")
	schema:register(XMLValueType.FLOAT, "map.stones.wear.type(?)#multiplier1", "Multiplier in stone state 1")
	schema:register(XMLValueType.FLOAT, "map.stones.wear.type(?)#multiplier2", "Multiplier in stone state 2")
	schema:register(XMLValueType.FLOAT, "map.stones.wear.type(?)#multiplier3", "Multiplier in stone state 3")
end)

function StoneSystem.new(customMt)
	local self = setmetatable({}, customMt or StoneSystem_mt)
	self.baseDirectory = ""
	self.densityMap = nil
	self.growthMapping = {}
	self.wearByType = {}

	return self
end

function StoneSystem:delete()
	removeConsoleCommand("gsStoneSystemAddDelta")
	removeConsoleCommand("gsStoneSystemSetState")

	self.densityMap = nil
end

function StoneSystem:loadStones(filename)
	local xmlFile = XMLFile.load("stones", filename, StoneSystem.xmlSchema)
	self.name = xmlFile:getValue("map.stones#name") or self.name
	self.title = g_i18n:convertText(xmlFile:getValue("map.stones#title")) or self.title
	self.firstChannel = xmlFile:getValue("map.stones.general#firstChannel") or self.firstChannel or 0
	self.numChannels = xmlFile:getValue("map.stones.general#numChannels") or self.numChannels or 3
	self.maskValue = xmlFile:getValue("map.stones.picking#maskValue") or self.maskValue or 1
	self.minValue = xmlFile:getValue("map.stones.picking#minValue") or self.minValue or 2
	self.maxValue = xmlFile:getValue("map.stones.picking#maxValue") or self.maxValue or 4
	self.litersPerSqm = xmlFile:getValue("map.stones.picking#litersPerSqm") or self.litersPerSqm or 5
	self.pickedValue = xmlFile:getValue("map.stones.picking#pickedValue") or self.pickedValue or 5

	xmlFile:iterate("map.stones.growth.update", function (_, key)
		local period = xmlFile:getValue(key .. "#period")
		local sourceState = xmlFile:getValue(key .. "#sourceState")
		local targetState = xmlFile:getValue(key .. "#targetState")

		if period ~= nil and sourceState ~= nil and targetState ~= nil then
			table.insert(self.growthMapping, {
				from = sourceState,
				to = targetState,
				period = period
			})
		end
	end)

	self.wearByType = {}

	xmlFile:iterate("map.stones.wear.type", function (_, key)
		local name = xmlFile:getValue(key .. "#name")
		local multiplier1 = xmlFile:getValue(key .. "#multiplier1")
		local multiplier2 = xmlFile:getValue(key .. "#multiplier2")
		local multiplier3 = xmlFile:getValue(key .. "#multiplier3")

		if name ~= nil and multiplier1 ~= nil and multiplier2 ~= nil and multiplier3 ~= nil then
			local stateToMultiplier = {
				multiplier1,
				multiplier2,
				multiplier3
			}
			self.wearByType[name:upper()] = stateToMultiplier
		end
	end)
	xmlFile:delete()
end

function StoneSystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.baseDirectory = baseDirectory

	self:loadStones("data/maps/maps_stones.xml")

	local filename = getXMLString(xmlFile, "map.stones#filename")

	if filename ~= nil then
		filename = Utils.getFilename(filename, baseDirectory)

		self:loadStones(filename)
	end

	if g_currentMission:getIsServer() and g_addCheatCommands then
		addConsoleCommand("gsStoneSystemAddDelta", "Add stone delta to field", "consoleCommandAddDelta", self)
		addConsoleCommand("gsStoneSystemSetState", "Set stone state to field", "consoleCommandSetState", self)
	end

	return true
end

function StoneSystem:addDensityMapSyncer(densityMapSyncer)
	if self.densityMap ~= nil then
		densityMapSyncer:addDensityMap(self.densityMap)
	end
end

function StoneSystem:getDensityMapData()
	return self.densityMap, self.firstChannel, self.numChannels
end

function StoneSystem:getMapHasStones()
	return self.densityMap ~= nil
end

function StoneSystem:getMinMaxValues()
	return self.minValue, self.maxValue
end

function StoneSystem:getPickedValue()
	return self.pickedValue
end

function StoneSystem:getMaskValue()
	return self.maskValue
end

function StoneSystem:getLitersPerSqm()
	return self.litersPerSqm
end

function StoneSystem:getWearMultiplierByType(name)
	if name ~= nil then
		return self.wearByType[name:upper()]
	end
end

function StoneSystem:initTerrain(mission, terrainNode, terrainDetailId)
	local id = getTerrainDataPlaneByName(terrainNode, self.name)

	if id ~= nil and id ~= 0 then
		self.densityMap = id
		self.stoneModifier = DensityMapModifier.new(self.densityMap, self.firstChannel, self.numChannels, g_currentMission.terrainNode)
		self.stoneFilter = DensityMapFilter.new(self.stoneModifier)
	end
end

function StoneSystem:getGrowthMapping()
	return self.growthMapping
end

function StoneSystem:consoleCommandAddDelta(fieldIndex, delta)
	fieldIndex = tonumber(fieldIndex)
	delta = tonumber(delta) or 1

	if fieldIndex == nil then
		return "Missing field index. gsStoneSystemAddDelta <fieldIndex> [<delta>]"
	end

	if self.stoneModifier == nil then
		return "No stones defined for current map"
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

		self.stoneModifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
		self.stoneFilter:setValueCompareParams(DensityValueCompareType.GREATER, math.max(-delta, 0))
		self.stoneModifier:executeAdd(delta, self.stoneFilter)
		self.stoneFilter:setValueCompareParams(DensityValueCompareType.GREATER, self.maxValue)
		self.stoneModifier:executeSet(self.maxValue, self.stoneFilter)
	end

	return "Added delta " .. delta
end

function StoneSystem:consoleCommandSetState(fieldIndex, state)
	fieldIndex = tonumber(fieldIndex)
	state = tonumber(state) or 1

	if fieldIndex == nil then
		return "Missing field index. gsStoneSystemSetState <fieldIndex> [<state>]"
	end

	if self.stoneModifier == nil then
		return "No stones defined for current map"
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

		self.stoneModifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
		self.stoneFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		self.stoneModifier:executeSet(state, self.stoneFilter)
	end

	return "Added state " .. state
end
