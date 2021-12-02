SprayType = nil
SprayTypeManager = {}
local SprayTypeManager_mt = Class(SprayTypeManager, AbstractManager)

function SprayTypeManager.new(customMt)
	local self = AbstractManager.new(customMt or SprayTypeManager_mt)

	return self
end

function SprayTypeManager:initDataStructures()
	self.numSprayTypes = 0
	self.sprayTypes = {}
	self.nameToSprayType = {}
	self.nameToIndex = {}
	self.indexToName = {}
	self.fillTypeIndexToSprayType = {}
	SprayType = self.nameToIndex
end

function SprayTypeManager:loadDefaultTypes()
	local xmlFile = loadXMLFile("sprayTypes", "data/maps/maps_sprayTypes.xml")

	self:loadSprayTypes(xmlFile, nil, true)
	delete(xmlFile)
end

function SprayTypeManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	SprayTypeManager:superClass().loadMapData(self)
	self:loadDefaultTypes()

	return XMLUtil.loadDataFromMapXML(xmlFile, "sprayTypes", baseDirectory, self, self.loadSprayTypes, missionInfo)
end

function SprayTypeManager:loadSprayTypes(xmlFile, missionInfo, isBaseType)
	local i = 0

	while true do
		local key = string.format("map.sprayTypes.sprayType(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local litersPerSecond = getXMLFloat(xmlFile, key .. "#litersPerSecond")
		local typeName = getXMLString(xmlFile, key .. "#type")
		local sprayGroundType = g_currentMission.fieldGroundSystem:getFieldSprayValueByName(getXMLString(xmlFile, key .. "#sprayGroundType"))

		self:addSprayType(name, litersPerSecond, typeName, sprayGroundType, isBaseType)

		i = i + 1
	end

	return true
end

function SprayTypeManager:addSprayType(name, litersPerSecond, typeName, sprayGroundType, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a sprayType. Ignoring sprayType!")

		return nil
	end

	name = name:upper()
	local fillType = g_fillTypeManager:getFillTypeByName(name)

	if fillType == nil then
		print("Warning: Missing fillType '" .. tostring(name) .. "' for sprayType definition. Ignoring sprayType!")

		return
	end

	if isBaseType and self.nameToSprayType[name] ~= nil then
		print("Warning: SprayType '" .. tostring(name) .. "' already exists. Ignoring sprayType!")

		return nil
	end

	local sprayType = self.nameToSprayType[name]

	if sprayType == nil then
		self.numSprayTypes = self.numSprayTypes + 1
		sprayType = {
			name = name,
			index = self.numSprayTypes,
			fillType = fillType,
			litersPerSecond = Utils.getNoNil(litersPerSecond, 0)
		}
		typeName = typeName:upper()
		sprayType.isFertilizer = typeName == "FERTILIZER"
		sprayType.isLime = typeName == "LIME"
		sprayType.isHerbicide = typeName == "HERBICIDE"

		if not sprayType.isFertilizer and not sprayType.isLime and not sprayType.isHerbicide then
			print("Warning: SprayType '" .. tostring(name) .. "' type '" .. tostring(typeName) .. "' is invalid. Possible values are 'FERTILIZER', 'HERBICIDE' or 'LIME'. Ignoring sprayType!")

			return nil
		end

		table.insert(self.sprayTypes, sprayType)

		self.nameToSprayType[name] = sprayType
		self.nameToIndex[name] = self.numSprayTypes
		self.indexToName[self.numSprayTypes] = name
		self.fillTypeIndexToSprayType[fillType.index] = sprayType
	end

	sprayType.litersPerSecond = litersPerSecond or sprayType.litersPerSecond or 0
	sprayType.sprayGroundType = sprayGroundType or sprayType.sprayGroundType or 1

	return sprayType
end

function SprayTypeManager:getSprayTypeByIndex(index)
	if index ~= nil then
		return self.sprayTypes[index]
	end

	return nil
end

function SprayTypeManager:getSprayTypeByName(name)
	if name ~= nil then
		name = name:upper()

		return self.nameToSprayType[name]
	end

	return nil
end

function SprayTypeManager:getFillTypeNameByIndex(index)
	if index ~= nil then
		return self.indexToName[index]
	end

	return nil
end

function SprayTypeManager:getFillTypeIndexByName(name)
	if name ~= nil then
		name = name:upper()

		return self.nameToIndex[name]
	end

	return nil
end

function SprayTypeManager:getFillTypeByName(name)
	if name ~= nil then
		name = name:upper()

		return self.nameToSprayType[name]
	end

	return nil
end

function SprayTypeManager:getSprayTypeByFillTypeIndex(index)
	if index ~= nil then
		return self.fillTypeIndexToSprayType[index]
	end

	return nil
end

function SprayTypeManager:getSprayTypeIndexByFillTypeIndex(index)
	if index ~= nil then
		local sprayType = self.fillTypeIndexToSprayType[index]

		if sprayType ~= nil then
			return sprayType.index
		end
	end

	return nil
end

function SprayTypeManager:getSprayTypes()
	return self.sprayTypes
end

g_sprayTypeManager = SprayTypeManager.new()
