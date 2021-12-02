FieldGroundSystem = {}
FieldDensityMap = {
	GROUND_TYPE = 1,
	GROUND_ANGLE = 2,
	SPRAY_TYPE = 3,
	SPRAY_LEVEL = 4,
	LIME_LEVEL = 5,
	PLOW_LEVEL = 6,
	STUBBLE_SHRED = 7,
	ROLLER_LEVEL = 8
}
FieldChopperType = {
	CHOPPER_STRAW = 1,
	CHOPPER_MAIZE = 2
}
local FieldGroundSystem_mt = Class(FieldGroundSystem)

function FieldGroundSystem.new(customMt)
	local self = setmetatable({}, customMt or FieldGroundSystem_mt)
	self.baseDirectory = ""

	self:initDataStructures()

	return self
end

function FieldGroundSystem:initDataStructures()
	self.fieldGroundTypeValue = {}
	self.fieldGroundTypeTyreTrackColor = {}
	self.fieldSprayTypeValue = {}
	self.fieldSprayTypeTyreTrackColor = {}
	self.fieldChopperTypeValue = {}
	self.densityMaps = {}
end

function FieldGroundSystem:loadGroundTypes(filename)
	local xmlFile = XMLFile.load("fieldGround", filename)

	self:loadDensityMapFromXML(FieldDensityMap.GROUND_TYPE, xmlFile, "fieldGround.densityMaps.groundTypes")
	self:loadDensityMapFromXML(FieldDensityMap.GROUND_ANGLE, xmlFile, "fieldGround.densityMaps.groundAngle")
	self:loadDensityMapFromXML(FieldDensityMap.SPRAY_TYPE, xmlFile, "fieldGround.densityMaps.sprayTypes")
	self:loadDensityMapFromXML(FieldDensityMap.SPRAY_LEVEL, xmlFile, "fieldGround.densityMaps.sprayLevel", 3)
	self:loadDensityMapFromXML(FieldDensityMap.LIME_LEVEL, xmlFile, "fieldGround.densityMaps.limeLevel")
	self:loadDensityMapFromXML(FieldDensityMap.PLOW_LEVEL, xmlFile, "fieldGround.densityMaps.plowLevel")
	self:loadDensityMapFromXML(FieldDensityMap.STUBBLE_SHRED, xmlFile, "fieldGround.densityMaps.stubbleShredLevel")
	self:loadDensityMapFromXML(FieldDensityMap.ROLLER_LEVEL, xmlFile, "fieldGround.densityMaps.rollerLevel")

	local _ = nil
	_, self.groundTypesFirstChannel, self.groundTypesNumChannels = self:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	self.groundTypesMaxValue = self:getMaxValue(FieldDensityMap.GROUND_TYPE)
	_, self.angleFirstChannel, self.angleNumChannels = self:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
	self.angleMaxValue = self:getMaxValue(FieldDensityMap.GROUND_ANGLE)
	_, self.sprayTypesFirstChannel, self.sprayTypesNumChannels = self:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
	self.sprayTypesMaxValue = self:getMaxValue(FieldDensityMap.SPRAY_TYPE)

	self:loadGroundIdFromXML(FieldGroundType.STUBBLE_TILLAGE, xmlFile, "fieldGround.densityMaps.groundTypes.stubbleTillage", FieldGroundType.STUBBLE_TILLAGE, {
		1,
		1,
		1,
		1
	})
	self:loadGroundIdFromXML(FieldGroundType.CULTIVATED, xmlFile, "fieldGround.densityMaps.groundTypes.cultivated", FieldGroundType.CULTIVATED, {
		1,
		1,
		1,
		1
	})
	self:loadGroundIdFromXML(FieldGroundType.SEEDBED, xmlFile, "fieldGround.densityMaps.groundTypes.seedbed", FieldGroundType.SEEDBED, {
		1,
		1,
		1,
		1
	})
	self:loadGroundIdFromXML(FieldGroundType.ROLLED_SEEDBED, xmlFile, "fieldGround.densityMaps.groundTypes.rolledSeedbed", FieldGroundType.ROLLED_SEEDBED, {
		1,
		1,
		1,
		1
	})
	self:loadGroundIdFromXML(FieldGroundType.PLOWED, xmlFile, "fieldGround.densityMaps.groundTypes.plowed", FieldGroundType.PLOWED, {
		1,
		1,
		1,
		1
	})
	self:loadGroundIdFromXML(FieldGroundType.SOWN, xmlFile, "fieldGround.densityMaps.groundTypes.sown", FieldGroundType.SOWN, {
		1,
		1,
		1,
		1
	})
	self:loadGroundIdFromXML(FieldGroundType.DIRECT_SOWN, xmlFile, "fieldGround.densityMaps.groundTypes.directSown", FieldGroundType.DIRECT_SOWN, {
		1,
		1,
		1,
		1
	})
	self:loadGroundIdFromXML(FieldGroundType.PLANTED, xmlFile, "fieldGround.densityMaps.groundTypes.planted", FieldGroundType.PLANTED, {
		1,
		1,
		1,
		1
	})
	self:loadGroundIdFromXML(FieldGroundType.RIDGE, xmlFile, "fieldGround.densityMaps.groundTypes.ridge", FieldGroundType.RIDGE, {
		1,
		1,
		1,
		1
	})
	self:loadGroundIdFromXML(FieldGroundType.ROLLER_LINES, xmlFile, "fieldGround.densityMaps.groundTypes.rollerLines", FieldGroundType.ROLLER_LINES, {
		1,
		1,
		1,
		1
	})
	self:loadGroundIdFromXML(FieldGroundType.HARVEST_READY, xmlFile, "fieldGround.densityMaps.groundTypes.harvestReady", FieldGroundType.HARVEST_READY, {
		1,
		1,
		1,
		1
	})
	self:loadGroundIdFromXML(FieldGroundType.HARVEST_READY_OTHER, xmlFile, "fieldGround.densityMaps.groundTypes.harvestReadyOther", FieldGroundType.HARVEST_READY_OTHER, {
		1,
		1,
		1,
		1
	})
	self:loadGroundIdFromXML(FieldGroundType.GRASS, xmlFile, "fieldGround.densityMaps.groundTypes.grass", FieldGroundType.GRASS, {
		1,
		1,
		1,
		1
	})
	self:loadGroundIdFromXML(FieldGroundType.GRASS_CUT, xmlFile, "fieldGround.densityMaps.groundTypes.grassCut", FieldGroundType.GRASS_CUT, {
		1,
		1,
		1,
		1
	})
	self:loadSprayIdFromXML(FieldSprayType.FERTILIZER, xmlFile, "fieldGround.densityMaps.sprayTypes.fertilizer", FieldSprayType.FERTILIZER, {
		1,
		1,
		1,
		1
	})
	self:loadSprayIdFromXML(FieldSprayType.LIME, xmlFile, "fieldGround.densityMaps.sprayTypes.lime", FieldSprayType.LIME, {
		1,
		1,
		1,
		1
	})
	self:loadSprayIdFromXML(FieldSprayType.MANURE, xmlFile, "fieldGround.densityMaps.sprayTypes.manure", FieldSprayType.MANURE, {
		1,
		1,
		1,
		1
	})
	self:loadSprayIdFromXML(FieldSprayType.LIQUID_MANURE, xmlFile, "fieldGround.densityMaps.sprayTypes.liquidManure", FieldSprayType.LIQUID_MANURE, {
		1,
		1,
		1,
		1
	})

	self.firstSowableValue = xmlFile:getInt("fieldGround.densityMaps.groundTypes.ranges.sowable#firstValue", self.firstSowableValue or self.fieldGroundTypeValue[FieldGroundType.STUBBLE_TILLAGE])
	self.lastSowableValue = xmlFile:getInt("fieldGround.densityMaps.groundTypes.ranges.sowable#lastValue", self.lastSowableValue or self.fieldGroundTypeValue[FieldGroundType.PLOWED])
	self.firstSowingValue = xmlFile:getInt("fieldGround.densityMaps.groundTypes.ranges.sowing#firstValue", self.firstSowingValue or self.fieldGroundTypeValue[FieldGroundType.SOWN])
	self.lastSowingValue = xmlFile:getInt("fieldGround.densityMaps.groundTypes.ranges.sowing#lastValue", self.lastSowingValue or self.fieldGroundTypeValue[FieldGroundType.RIDGE])
	self.fieldChopperTypeValue[FieldChopperType.CHOPPER_STRAW] = 5
	self.fieldChopperTypeValue[FieldChopperType.CHOPPER_MAIZE] = 6

	xmlFile:delete()
end

function FieldGroundSystem:loadMapData(xmlFile, missionInfo, baseDirectory)
	self.baseDirectory = baseDirectory

	self:loadGroundTypes("data/maps/maps_fieldGround.xml")

	local filename = getXMLString(xmlFile, "map.fieldGround#filename")

	if filename ~= nil then
		filename = Utils.getFilename(filename, baseDirectory)

		self:loadGroundTypes(filename)
	end

	return true
end

function FieldGroundSystem:delete()
	for _, data in pairs(self.densityMaps) do
		if data.map ~= nil and data.canBeDeleted then
			delete(data.map)
		end
	end

	self.densityMaps = {}
end

function FieldGroundSystem:initTerrain(mission, terrainNode, terrainDetailId)
	for identifier, data in pairs(self.densityMaps) do
		if data.useTerrainDetailId then
			data.map = terrainDetailId
			local size = getDensityMapSize(terrainDetailId)
			data.height = size
			data.width = size
			data.filename = getDensityMapFilename(terrainDetailId)
			data.isBitVector = false
			data.canBeDeleted = false
		else
			data.map = createBitVectorMap("densityMap")
			local path = data.path
			local missionInfo = mission.missionInfo
			local loadFromSave = false

			if missionInfo.isValid then
				path = missionInfo.savegameDirectory .. "/" .. data.filename
				loadFromSave = true
			end

			if loadFromSave and not loadBitVectorMapFromFile(data.map, path, data.numChannels) then
				Logging.warning("Loading density map file '" .. tostring(path) .. "' failed! Loading default density map.")

				loadFromSave = false
			end

			if not loadFromSave and not loadBitVectorMapFromFile(data.map, data.path, data.numChannels) then
				Logging.warning("Loading default density map file '" .. tostring(data.path) .. "' failed!")
			end

			data.width, data.height = getBitVectorMapSize(data.map)
			data.isBitVector = true
			data.canBeDeleted = true
		end
	end
end

function FieldGroundSystem:addDensityMapSyncer(densityMapSyncer)
	local added = {}

	for identifier, data in pairs(self.densityMaps) do
		if added[data.map] == nil then
			densityMapSyncer:addDensityMap(data.map)

			added[data.map] = true
		end
	end
end

function FieldGroundSystem:getDensityMaps()
	return self.densityMaps
end

function FieldGroundSystem:loadDensityMapFromXML(identifier, xmlFile, key, forcedMaxValue)
	local data = self.densityMaps[identifier] or {}
	data.firstChannel = xmlFile:getInt(key .. "#firstChannel") or data.firstChannel or 0
	data.numChannels = xmlFile:getInt(key .. "#numChannels") or data.numChannels or 1
	data.canBeDeleted = Utils.getNoNil(data.canBeDeleted, Utils.getNoNil(data.canBeDeleted, false))
	data.useTerrainDetailId = Utils.getNoNil(xmlFile:getBool(key .. "#useDefaultTerrainDetail"), Utils.getNoNil(data.useTerrainDetailId, false))

	if not data.useTerrainDetailId then
		local filename = xmlFile:getString(key .. "#filename")

		if filename ~= nil then
			data.path = Utils.getFilename(filename, self.baseDirectory)
			data.filename = Utils.getFilenameFromPath(data.path)
		end
	end

	local maxChannelValue = 2^data.numChannels - 1
	local maxValue = math.max(data.maxValue or maxChannelValue, maxChannelValue)
	local newValue = xmlFile:getInt(key .. "#maxValue")

	if newValue ~= nil then
		maxValue = math.min(newValue, maxChannelValue)
	end

	if forcedMaxValue ~= nil then
		maxValue = math.min(maxValue, forcedMaxValue)
	end

	data.maxValue = maxValue
	self.densityMaps[identifier] = data

	return true
end

function FieldGroundSystem:loadGroundIdFromXML(identifier, xmlFile, key, defaultValue, defaultColor)
	local id = xmlFile:getInt(key .. "#value") or self.fieldGroundTypeValue[identifier] or defaultValue

	if id == nil then
		id = defaultValue

		Logging.xmlWarning(xmlFile, "Missing xml element '%s'! Using default value '%d'", key, defaultValue)
	end

	if self.groundTypesMaxValue < id then
		id = 0

		Logging.xmlError(xmlFile, "Invalid value for xml element '%s'! Using value '0'", key)
	end

	self.fieldGroundTypeValue[identifier] = id
	local colorStr = xmlFile:getString(key .. "#tireTrackColor")
	local color = nil

	if colorStr ~= nil then
		color = {
			colorStr:getVector()
		}

		if #color ~= 4 then
			Logging.xmlError(xmlFile, "Invalid number of values (should be 4) for xml element '%s'!", key)

			color = nil
		end
	end

	self.fieldGroundTypeTyreTrackColor[identifier] = color or self.fieldGroundTypeTyreTrackColor[identifier] or defaultColor
end

function FieldGroundSystem:loadSprayIdFromXML(identifier, xmlFile, key, defaultValue, defaultColor)
	local id = xmlFile:getInt(key .. "#value") or self.fieldSprayTypeValue[identifier] or defaultValue

	if id == nil then
		id = defaultValue

		Logging.xmlWarning(xmlFile, "Missing xml element '%s'! Using default value '%d'", key, defaultValue)
	end

	if id == self.sprayTypesMaxValue then
		id = 0

		Logging.xmlError(xmlFile, "Value '%d' is reserved and cannot be used in xml element '%s'! Using value '0'", self.sprayTypesMaxValue, key)
	end

	if self.sprayTypesMaxValue < id then
		id = 0

		Logging.xmlError(xmlFile, "Invalid value for xml element '%s'! Using value '0'", key)
	end

	self.fieldSprayTypeValue[identifier] = id
	local colorStr = xmlFile:getString(key .. "#tireTrackColor")
	local color = nil

	if colorStr ~= nil then
		color = {
			colorStr:getVector()
		}

		if #color ~= 4 then
			Logging.xmlError(xmlFile, "Invalid number of values (should be 4) for xml element '%s'!", key)

			color = nil
		end
	end

	self.fieldSprayTypeTyreTrackColor[identifier] = color or self.fieldSprayTypeTyreTrackColor[identifier] or defaultColor
end

function FieldGroundSystem:getFieldGroundValueByName(groundTypeName)
	local groundType = FieldGroundType.getByName(groundTypeName)

	if groundType == nil then
		return nil
	end

	return self.fieldGroundTypeValue[groundType]
end

function FieldGroundSystem:getFieldGroundValue(groundType)
	local value = self.fieldGroundTypeValue[groundType]

	return value or 0
end

function FieldGroundSystem:getFieldGroundTyreTrackColor(densityBits)
	local sprayMask = bitShiftLeft(2^self.sprayTypesNumChannels - 1, self.sprayTypesFirstChannel)
	local groundMask = bitShiftLeft(2^self.groundTypesNumChannels - 1, self.groundTypesFirstChannel)
	local groundType = bitShiftRight(bitAND(densityBits, groundMask), self.groundTypesFirstChannel)
	local sprayType = bitShiftRight(bitAND(densityBits, sprayMask), self.sprayTypesFirstChannel)
	local color = self.fieldGroundTypeTyreTrackColor[groundType]

	if sprayType > 0 then
		color = self.fieldSprayTypeTyreTrackColor[groundType]
	end

	if color ~= nil then
		return color[1], color[2], color[3], color[4]
	end

	return 0, 0, 0, 0
end

function FieldGroundSystem:getFieldSprayValueByName(sprayTypeName)
	if sprayTypeName == nil then
		return 0
	end

	sprayTypeName = string.upper(sprayTypeName)
	local sprayType = FieldSprayType[sprayTypeName]

	if sprayType == nil then
		return 0
	end

	return self.fieldSprayTypeValue[sprayType] or 0
end

function FieldGroundSystem:getFieldSprayValue(sprayType)
	local value = self.fieldSprayTypeValue[sprayType]

	return value or 0
end

function FieldGroundSystem:getSowableRange()
	return self.firstSowableValue, self.lastSowableValue
end

function FieldGroundSystem:getSowingRange()
	return self.firstSowingValue, self.lastSowingValue
end

function FieldGroundSystem:getGroundAngleMaxValue()
	return self.angleMaxValue
end

function FieldGroundSystem:getChopperTypeIndexByName(chopperTypeName)
	if chopperTypeName == nil then
		return 0
	end

	chopperTypeName = string.upper(chopperTypeName)

	return FieldChopperType[chopperTypeName]
end

function FieldGroundSystem:getChopperTypeValue(chopperType)
	return self.fieldChopperTypeValue[chopperType]
end

function FieldGroundSystem:getDensityMapData(levelType)
	local data = self.densityMaps[levelType]

	if data == nil then
		return nil
	end

	return data.map, data.firstChannel, data.numChannels
end

function FieldGroundSystem:getMaxValue(levelType)
	local data = self.densityMaps[levelType]

	if data == nil then
		return nil
	end

	return data.maxValue
end

function FieldGroundSystem:getSize(levelType)
	local data = self.densityMaps[levelType]

	if data == nil then
		return nil, 
	end

	return data.width, data.height
end
