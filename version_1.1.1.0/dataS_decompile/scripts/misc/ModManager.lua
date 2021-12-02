ModManager = {}
local ModManager_mt = Class(ModManager, AbstractManager)

function ModManager.new(customMt)
	local self = AbstractManager.new(customMt or ModManager_mt)

	return self
end

function ModManager:initDataStructures()
	self.hashToMod = {}
	self.nameToMod = {}
	self.validMods = {}
	self.multiplayerMods = {}
	self.mods = {}
	self.numMods = 0
end

function ModManager:addMod(title, description, version, modDescVersion, author, iconFilename, modName, modDir, modFile, isMultiplayerSupported, fileHash, absBaseFilename, isDirectory, isDLC, hasScripts, dependencies, multiplayerOnly, isSelectable, uniqueType)
	if fileHash ~= nil and self.hashToMod[fileHash] ~= nil then
		print("Error: Adding mod with same file hash twice. Title is " .. title .. " filehash: " .. fileHash)

		return nil
	end

	self.numMods = self.numMods + 1
	local mod = {
		id = self.numMods,
		title = title,
		description = description,
		version = version,
		modDescVersion = modDescVersion,
		author = author,
		iconFilename = iconFilename,
		isDLC = isDLC,
		fileHash = fileHash,
		modName = modName,
		modDir = modDir,
		modFile = modFile,
		absBaseFilename = absBaseFilename,
		isDirectory = isDirectory,
		isMultiplayerSupported = isMultiplayerSupported,
		isSelectable = isSelectable,
		hasScripts = hasScripts,
		dependencies = dependencies,
		multiplayerOnly = multiplayerOnly,
		uniqueType = uniqueType
	}

	table.insert(self.mods, mod)

	self.nameToMod[modName] = mod

	if fileHash ~= nil then
		table.insert(self.validMods, mod)

		self.hashToMod[fileHash] = mod

		if isMultiplayerSupported then
			table.insert(self.multiplayerMods, mod)
		end
	end

	return mod
end

function ModManager:removeMod(mod)
	if mod ~= nil then
		self.nameToMod[mod.modName] = nil

		if mod.fileHash ~= nil then
			self.hashToMod[mod.fileHash] = nil
		end

		for index, modItem in ipairs(self.mods) do
			if modItem == mod then
				table.remove(self.mods, index)

				break
			end
		end

		for index, modItem in ipairs(self.validMods) do
			if modItem == mod then
				table.remove(self.validMods, index)

				break
			end
		end

		for index, modItem in ipairs(self.multiplayerMods) do
			if modItem == mod then
				table.remove(self.multiplayerMods, index)

				break
			end
		end

		return true
	end

	return false
end

function ModManager:getModByFileHash(fileHash)
	return self.hashToMod[fileHash]
end

function ModManager:getModByName(modName)
	return self.nameToMod[modName]
end

function ModManager:getModByIndex(index)
	return self.mods[index]
end

function ModManager:getMods()
	return self.mods
end

function ModManager:getMultiplayerMods()
	return self.multiplayerMods
end

function ModManager:getActiveMods()
	local mods = {}

	for _, mod in ipairs(self.mods) do
		if g_modIsLoaded[mod.modName] then
			table.insert(mods, mod)
		end
	end

	return mods
end

function ModManager:getNumOfMods()
	return #self.mods
end

function ModManager:getNumOfValidMods()
	return #self.validMods
end

function ModManager:getAreAllModsAvailable(modHashes)
	for _, modHash in pairs(modHashes) do
		if not self:getIsModAvailable(modHash) then
			return false
		end
	end

	return true
end

function ModManager:getIsModAvailable(modHash)
	local modItem = self.hashToMod[modHash]

	if modItem == nil or not modItem.isMultiplayerSupported then
		return false
	end

	return true
end

function ModManager:isModMap(modName)
	for mapId, _ in pairs(g_mapManager.idToMap) do
		local mapModName = g_mapManager:getModNameFromMapId(mapId)

		if mapModName == modName then
			return true
		end
	end

	return false
end

g_modManager = ModManager.new()
