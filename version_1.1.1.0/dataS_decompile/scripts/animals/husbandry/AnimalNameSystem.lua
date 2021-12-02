AnimalNameSystem = {}
local AnimalNameSystem_mt = Class(AnimalNameSystem)

function AnimalNameSystem.new(mission, customMt)
	local self = setmetatable({}, customMt or AnimalNameSystem_mt)
	self.mission = mission
	self.names = {}

	return self
end

function AnimalNameSystem:delete()
end

function AnimalNameSystem:loadMapData(xmlFile, missionInfo)
	local filename = Utils.getFilename(getXMLString(xmlFile, "map.animals.names#filename"), self.mission.baseDirectory)

	if filename == nil then
		Logging.xmlError(xmlFile, "Missing animal name configuration file")

		return false
	end

	local xmlFileNames = XMLFile.load("animalNames", filename)

	if xmlFileNames ~= nil then
		xmlFileNames:iterate("animalNames.name", function (_, key)
			local name = xmlFileNames:getString(key .. "#value")

			if name == nil then
				Logging.xmlError(xmlFileNames, "Missing name for '%s'", key)

				return false
			end

			name = g_i18n:convertText(name, missionInfo.customEnvironment)

			table.insert(self.names, name)
		end)
		xmlFileNames:delete()

		return #self.names > 0
	end

	return false
end

function AnimalNameSystem:getRandomName()
	local numNames = #self.names

	if numNames == 0 then
		return ""
	end

	local index = math.random(1, numNames)

	return self.names[index]
end
