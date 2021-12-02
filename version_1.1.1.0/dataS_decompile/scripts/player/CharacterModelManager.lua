CharacterModelManager = {
	SEND_NUM_BITS = 2
}
local CharacterModelManager_mt = Class(CharacterModelManager)

function CharacterModelManager.new(customMt)
	local self = setmetatable({}, customMt or CharacterModelManager_mt)

	self:initDataStructures()

	return self
end

function CharacterModelManager:initDataStructures()
	self.playerModels = {}
	self.nameToPlayerModel = {}
	self.nameToIndex = {}
end

function CharacterModelManager:load(xmlFilename)
	local xmlFile = XMLFile.load("playerModels", xmlFilename)

	if xmlFile == nil then
		Logging.fatal("Could not load player model list at %s", xmlFilename)
	end

	xmlFile:iterate("playerModels.playerModel", function (index, key)
		local filename = xmlFile:getString(key .. "#filename")
		local name = xmlFile:getString(key .. "#name")
		local isMale = xmlFile:getBool(key .. "#isMale") or false

		if filename == nil or name == nil then
			return
		end

		self:addPlayerModel(name, filename, isMale)
	end)
	xmlFile:delete()
end

function CharacterModelManager:loadMapData(xmlFile)
	return true
end

function CharacterModelManager:unloadMapData()
end

function CharacterModelManager:addPlayerModel(name, xmlFilename, isMale)
	if not ClassUtil.getIsValidIndexName(name) then
		Logging.devWarning("Warning: '%s' is not a valid name for a player. Ignoring it!", tostring(name))

		return nil
	end

	if xmlFilename == nil or xmlFilename == "" then
		Logging.devWarning("Warning: Config xmlFilename is missing for player '%s'. Ignoring it!", tostring(name))

		return nil
	end

	name = name:upper()

	if self.nameToPlayerModel[name] == nil then
		local numPlayerModels = #self.playerModels + 1
		local model = {
			name = name,
			index = numPlayerModels,
			xmlFilename = Utils.getFilename(xmlFilename, nil),
			isMale = isMale
		}

		table.insert(self.playerModels, model)

		self.nameToPlayerModel[name] = model
		self.nameToIndex[name] = numPlayerModels

		return model
	else
		Logging.devWarning("Warning: Player '%s' already exists. Ignoring it!", tostring(name))
	end

	return nil
end

function CharacterModelManager:getPlayerModelByIndex(index)
	if index ~= nil then
		return self.playerModels[index]
	end

	return nil
end

function CharacterModelManager:getPlayerByName(name)
	if name ~= nil then
		name = name:upper()

		return self.nameToPlayerModel[name]
	end

	return nil
end

function CharacterModelManager:getNumOfPlayerModels()
	return #self.playerModels
end

function CharacterModelManager:getIsPlayerModelMaleForFilename(xmlFilename)
	for _, model in ipairs(self.playerModels) do
		if model.xmlFilename == xmlFilename then
			return model.isMale
		end
	end

	return true
end

g_characterModelManager = CharacterModelManager.new()
