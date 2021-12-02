HelperManager = {}
local HelperManager_mt = Class(HelperManager, AbstractManager)

function HelperManager.new(customMt)
	local self = AbstractManager.new(customMt or HelperManager_mt)

	return self
end

function HelperManager:initDataStructures()
	self.numHelpers = 0
	self.helpers = {}
	self.nameToIndex = {}
	self.indexToHelper = {}
	self.availableHelpers = {}
end

function HelperManager:loadDefaultTypes(missionInfo, baseDirectory)
	local xmlFile = loadXMLFile("helpers", "data/maps/maps_helpers.xml")

	self:loadHelpers(xmlFile, missionInfo, baseDirectory, true)
	delete(xmlFile)
end

function HelperManager:loadMapData(xmlFile, missionInfo, baseDirectory)
	HelperManager:superClass().loadMapData(self)
	self:loadDefaultTypes()

	return XMLUtil.loadDataFromMapXML(xmlFile, "helpers", baseDirectory, self, self.loadHelpers, missionInfo, baseDirectory)
end

function HelperManager:loadHelpers(xmlFile, missionInfo, baseDirectory, isBaseType)
	local i = 0

	while true do
		local key = string.format("map.helpers.helper(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local title = getXMLString(xmlFile, key .. "#title")
		local modelFilename = getXMLString(xmlFile, key .. "#modelFilename")
		local color = string.getVectorN(getXMLString(xmlFile, key .. "#color"), 3) or {
			1,
			1,
			1
		}

		self:addHelper(name, title, color, modelFilename, baseDirectory, isBaseType)

		i = i + 1
	end

	return true
end

function HelperManager:addHelper(name, title, color, modelFilename, baseDir, isBaseType)
	if not ClassUtil.getIsValidIndexName(name) then
		print("Warning: '" .. tostring(name) .. "' is not a valid name for a helper. Ignoring helper!")

		return nil
	end

	name = name:upper()

	if isBaseType and self.nameToIndex[name] ~= nil then
		print("Warning: Helper '" .. tostring(name) .. "' already exists. Ignoring helper!")

		return nil
	end

	local helper = self.helpers[name]

	if helper == nil then
		if modelFilename == nil or modelFilename == "" then
			print("Warning: Missing helper config file for helper '" .. tostring(name) .. "'. Ignoring helper!")

			return nil
		end

		self.numHelpers = self.numHelpers + 1
		helper = {
			name = name,
			index = self.numHelpers,
			color = color,
			title = name
		}

		if title ~= nil then
			helper.title = g_i18n:convertText(title)
		end

		helper.modelFilename = Utils.getFilename(modelFilename, baseDir)
		self.helpers[name] = helper
		self.nameToIndex[name] = self.numHelpers
		self.indexToHelper[self.numHelpers] = helper

		table.insert(self.availableHelpers, helper)
	else
		if title ~= nil then
			helper.title = g_i18n:convertText(title)
		end

		if modelFilename ~= nil then
			helper.modelFilename = Utils.getFilename(modelFilename, baseDir)
		end
	end

	return helper
end

function HelperManager:getRandomHelper()
	return self.availableHelpers[math.random(1, #self.availableHelpers)]
end

function HelperManager:getRandomHelperModel()
	return self.indexToHelper[math.random(1, self.numHelpers)].modelFilename
end

function HelperManager:getRandomIndex()
	return math.random(1, self.numHelpers)
end

function HelperManager:getHelperByIndex(index)
	if index ~= nil then
		return self.indexToHelper[index]
	end

	return nil
end

function HelperManager:getHelperByName(name)
	if name ~= nil then
		name = name:upper()

		return self.helpers[name]
	end

	return nil
end

function HelperManager:useHelper(helper)
	for k, h in pairs(self.availableHelpers) do
		if h == helper then
			table.remove(self.availableHelpers, k)

			return true
		end
	end

	return false
end

function HelperManager:releaseHelper(helper)
	table.insert(self.availableHelpers, helper)
end

function HelperManager:getNumOfHelpers()
	return self.numHelpers
end

g_helperManager = HelperManager.new()
