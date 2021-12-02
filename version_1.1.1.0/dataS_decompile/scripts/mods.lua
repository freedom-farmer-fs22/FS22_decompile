g_uniqueDlcNamePrefix = "pdlc_"
g_modEventListeners = {}
g_dlcsDirectories = {}
g_forceNeedsDlcsAndModsReload = false
g_lastCheckDlcPaths = {}
g_modIsLoaded = {}
g_modNameToDirectory = {}
local isReloadingDlcs = false
g_dlcModNameHasPrefix = {}
modOnCreate = {}

function loadDlcs()
	storeHaveDlcsChanged()

	if g_isPresentationVersion and not g_isPresentationVersionDlcEnabled then
		return
	end

	local loadedDlcs = {}

	for i = 1, table.getn(g_dlcsDirectories) do
		local dir = g_dlcsDirectories[i]

		if dir.isLoaded then
			loadDlcsFromDirectory(dir.path, loadedDlcs)
		end
	end
end

function loadDlcsFromDirectory(dlcsDir, loadedDlcs)
	local appBasePath = getAppBasePath()

	if isAbsolutPath(dlcsDir) and (appBasePath:len() == 0 or not string.startsWith(dlcsDir, appBasePath)) then
		createFolder(dlcsDir)
	end

	local files = Files.new(dlcsDir)

	for _, v in pairs(files.files) do
		local addDLCPrefix = false
		local dlcFileHash, dlcName, xmlFilename = nil

		if v.isDirectory then
			if g_isDevelopmentVersion or not GS_PLATFORM_PC then
				dlcName = v.filename
				xmlFilename = "dlcDesc.xml"
				addDLCPrefix = true

				if not GS_PLATFORM_PC then
					dlcFileHash = getFileMD5(dlcsDir .. v.filename, dlcName)
				end

				if dlcFileHash == nil and g_isDevelopmentVersion then
					dlcFileHash = getMD5("Dev_" .. v.filename)
				end
			end
		else
			local len = v.filename:len()

			if len > 4 then
				local ext = v.filename:sub(len - 3)

				if ext == ".dlc" then
					dlcName = v.filename:sub(1, len - 4)
					dlcFileHash = getFileMD5(dlcsDir .. v.filename, dlcName)
					xmlFilename = "dlcDesc.xml"
					addDLCPrefix = true
				elseif ext == ".zip" or ext == ".gar" then
					dlcName = v.filename:sub(1, len - 4)
					dlcFileHash = getFileMD5(dlcsDir .. v.filename, dlcName)
					xmlFilename = "modDesc.xml"
					addDLCPrefix = false
				end
			end
		end

		if dlcName ~= nil and xmlFilename ~= nil and g_dlcModNameHasPrefix[dlcName] == nil then
			local dlcDir = dlcsDir .. dlcName .. "/"
			local dlcFile = dlcDir .. xmlFilename
			g_dlcModNameHasPrefix[dlcName] = addDLCPrefix

			loadModDesc(dlcName, dlcDir, dlcFile, dlcFileHash, dlcsDir .. v.filename, v.isDirectory, addDLCPrefix)
		end
	end
end

function loadMods()
	haveModsChanged()

	local loadedMods = {}
	local modsDir = g_modsDirectory

	if g_isPresentationVersion then
		return
	end

	g_showIllegalActivityInfo = false
	local files = Files.new(modsDir)

	for _, v in pairs(files.files) do
		local modFileHash, modName = nil

		if v.isDirectory then
			modName = v.filename

			if g_isDevelopmentVersion then
				modFileHash = getMD5("DevMod_" .. v.filename)
			end
		else
			local len = v.filename:len()

			if len > 4 then
				local ext = v.filename:sub(len - 3)

				if ext == ".zip" or ext == ".gar" then
					modName = v.filename:sub(1, len - 4)
					modFileHash = getFileMD5(modsDir .. v.filename, modName)
				end
			end
		end

		if modName ~= nil then
			local modDir = modsDir .. modName .. "/"
			local modFile = modDir .. "modDesc.xml"

			if loadedMods[modFile] == nil then
				loadModDesc(modName, modDir, modFile, modFileHash, modsDir .. v.filename, v.isDirectory, false)

				loadedMods[modFile] = true
			end
		end
	end

	if g_showIllegalActivityInfo then
		print("Info: This game protects you from illegal activity")
	end

	g_showIllegalActivityInfo = nil
end

local function getIsValidModDir(modDir)
	if modDir:len() == 0 then
		return false
	end

	if string.startsWith(modDir, g_uniqueDlcNamePrefix) then
		return false
	end

	if modDir:find("%d") == 1 then
		return false
	end

	if modDir:find("[^%w_]") ~= nil then
		return false
	end

	return true
end

function loadModDesc(modName, modDir, modFile, modFileHash, absBaseFilename, isDirectory, addDLCPrefix)
	if not getIsValidModDir(modName) then
		print("Error: Invalid mod name '" .. modName .. "'! Characters allowed: (_, A-Z, a-z, 0-9). The first character must not be a digit")

		return
	end

	local origModName = modName

	if addDLCPrefix then
		modName = g_uniqueDlcNamePrefix .. modName
	end

	if g_modNameToDirectory[modName] ~= nil then
		return
	end

	g_modNameToDirectory[modName] = modDir
	local isDLCFile = false

	if string.endsWith(modFile, "dlcDesc.xml") then
		isDLCFile = true

		if not fileExists(modFile) then
			if GS_IS_EPIC_VERSION and StringUtil.startsWith(modDir, getAppBasePath() .. "pdlc/") then
				print("Info: No license for dlc " .. modName .. ".")
			else
				print("Error: No license for dlc " .. modName .. ". Please reinstall.")
			end

			return
		end
	end

	setModInstalled(absBaseFilename, addDLCPrefix)

	local xmlFile = XMLFile.load("ModFile", modFile)

	if xmlFile == nil then
		return
	end

	local modVersion = xmlFile:getString("modDesc.version")
	local versionStr = ""

	if modVersion ~= nil and modVersion ~= "" then
		versionStr = " (Version: " .. modVersion .. ")"
	end

	local hashStr = ""

	if modFileHash ~= nil then
		hashStr = "(Hash: " .. modFileHash .. ")"
	end

	if isDLCFile then
		print("Available dlc: " .. hashStr .. versionStr .. " " .. modName)
	else
		print("Available mod: " .. hashStr .. versionStr .. " " .. modName)
	end

	local modDescVersion = xmlFile:getInt("modDesc#descVersion")

	if modDescVersion == nil then
		print("Error: Missing descVersion attribute in mod " .. modName)
		xmlFile:delete()

		return
	end

	if modDescVersion < g_minModDescVersion or g_maxModDescVersion < modDescVersion then
		print("Error: Unsupported mod description version in mod " .. modName)
		xmlFile:delete()

		return
	end

	if _G[modName] ~= nil and not isReloadingDlcs then
		print("Error: Invalid mod name '" .. modName .. "'")
		xmlFile:delete()

		return
	end

	if isDLCFile then
		local requiredModName = xmlFile:getString("modDesc.multiplayer#requiredModName")

		if requiredModName ~= nil and requiredModName ~= origModName then
			print("Error: Do not rename dlcs. Name: '" .. origModName .. "'. Expect: '" .. requiredModName .. "'")
			xmlFile:delete()

			return
		end
	end

	local isSelectable = xmlFile:getBool("modDesc.isSelectable", true)
	local modEnv = {}

	if GS_IS_CONSOLE_VERSION then
		modEnv = Utils.getNoNil(_G[modName], modEnv)
	end

	g_globalsNameCheckDisabled = true
	_G[modName] = modEnv
	g_globalsNameCheckDisabled = false
	local modEnv_mt = {
		__index = _G
	}

	setmetatable(modEnv, modEnv_mt)

	if not isDLCFile then
		modEnv._G = modEnv
	end

	local gEnv = _G
	local orgGetfenv = getfenv

	function modEnv.getfenv(obj)
		local ret = orgGetfenv(obj)

		if ret == gEnv then
			return modEnv
		end

		return ret
	end

	modEnv.g_i18n = g_i18n:addModI18N(modName)

	function modEnv.loadstring(str, chunkname)
		str = "setfenv(1," .. modName .. "); " .. str

		return loadstring(str, chunkname)
	end

	function modEnv.source(filename, env)
		if isAbsolutPath(filename) then
			if not g_isDevelopmentConsoleScriptModTesting and GS_IS_CONSOLE_VERSION and filename:sub(1, modDir:len()) == modDir then
				filename = "dataS/scripts/internalMods/" .. modName .. "/" .. filename:sub(modDir:len() + 1)
			end

			source(filename, modName)
		else
			source(filename)
		end
	end

	function modEnv.InitEventClass(classObject, className)
		InitEventClass(classObject, modName .. "." .. className)
	end

	function modEnv.InitObjectClass(classObject, className)
		InitObjectClass(classObject, modName .. "." .. className)
	end

	function modEnv.registerObjectClassName(object, className)
		registerObjectClassName(object, modName .. "." .. className)
	end

	modEnv.g_constructionBrushTypeManager = {
		addBrushType = function (self, typeName, className, filename, customEnvironment)
			if isAbsolutPath(filename) and (customEnvironment == nil or customEnvironment == "") then
				customEnvironment = modName
				typeName = modName .. "." .. typeName
				className = modName .. "." .. className
			end

			g_constructionBrushTypeManager:addBrushType(typeName, className, filename, customEnvironment)
		end,
		getClassObjectByTypeName = function (self, typeName)
			local classObj = g_constructionBrushTypeManager:getClassObjectByTypeName(typeName)

			if classObj == nil then
				classObj = g_constructionBrushTypeManager:getClassObjectByTypeName(modName .. "." .. typeName)
			end

			return classObj
		end
	}

	setmetatable(modEnv.g_constructionBrushTypeManager, {
		__index = g_constructionBrushTypeManager
	})

	modEnv.g_specializationManager = {
		addSpecialization = function (self, name, className, filename, customEnvironment)
			if isAbsolutPath(filename) and (customEnvironment == nil or customEnvironment == "") then
				if not g_isDevelopmentConsoleScriptModTesting and GS_IS_CONSOLE_VERSION and filename:sub(1, modDir:len()) == modDir then
					filename = "dataS/scripts/internalMods/" .. modName .. "/" .. filename:sub(modDir:len() + 1)
				end

				customEnvironment = modName
				name = modName .. "." .. name
				className = modName .. "." .. className
			end

			g_specializationManager:addSpecialization(name, className, filename, customEnvironment)
		end,
		getSpecializationByName = function (self, name)
			local spec = g_specializationManager:getSpecializationByName(name)

			if spec == nil then
				spec = g_specializationManager:getSpecializationByName(modName .. "." .. name)
			end

			return spec
		end
	}

	setmetatable(modEnv.g_specializationManager, {
		__index = g_specializationManager
	})

	modEnv.g_placeableSpecializationManager = {
		addSpecialization = function (self, name, className, filename, customEnvironment)
			if isAbsolutPath(filename) and (customEnvironment == nil or customEnvironment == "") then
				if not g_isDevelopmentConsoleScriptModTesting and GS_IS_CONSOLE_VERSION and filename:sub(1, modDir:len()) == modDir then
					filename = "dataS/scripts/internalMods/" .. modName .. "/" .. filename:sub(modDir:len() + 1)
				end

				customEnvironment = modName
				name = modName .. "." .. name
				className = modName .. "." .. className
			end

			g_placeableSpecializationManager:addSpecialization(name, className, filename, customEnvironment)
		end,
		getSpecializationByName = function (self, name)
			local spec = g_placeableSpecializationManager:getSpecializationByName(name)

			if spec == nil then
				spec = g_placeableSpecializationManager:getSpecializationByName(modName .. "." .. name)
			end

			return spec
		end
	}

	setmetatable(modEnv.g_placeableSpecializationManager, {
		__index = g_placeableSpecializationManager
	})

	modEnv.g_vehicleTypeManager = {
		addType = function (self, typeName, className, filename, customEnvironment)
			if isAbsolutPath(filename) and (customEnvironment == nil or customEnvironment == "") then
				if GS_IS_CONSOLE_VERSION and filename:sub(1, modDir:len()) == modDir then
					filename = "dataS/scripts/internalMods/" .. modName .. "/" .. filename:sub(modDir:len() + 1)
				end

				customEnvironment = modName
				typeName = modName .. "." .. typeName
				className = modName .. "." .. className
			end

			g_vehicleTypeManager:addType(typeName, className, filename, customEnvironment)
		end
	}

	setmetatable(modEnv.g_vehicleTypeManager, {
		__index = g_vehicleTypeManager
	})

	modEnv.g_placeableTypeManager = {
		addType = function (self, typeName, className, filename, customEnvironment)
			if isAbsolutPath(filename) and (customEnvironment == nil or customEnvironment == "") then
				customEnvironment = modName
				typeName = modName .. "." .. typeName
				className = modName .. "." .. className
			end

			g_placeableTypeManager:addType(typeName, className, filename, customEnvironment)
		end,
		getClassObjectByTypeName = function (self, typeName)
			local classObj = g_placeableTypeManager:getClassObjectByTypeName(typeName)

			if classObj == nil then
				classObj = g_placeableTypeManager:getClassObjectByTypeName(modName .. "." .. typeName)
			end

			return classObj
		end
	}

	setmetatable(modEnv.g_placeableTypeManager, {
		__index = g_placeableTypeManager
	})

	modEnv.g_effectManager = {
		registerEffectClass = function (self, className, effectClass)
			if not ClassUtil.getIsValidClassName(className) then
				print("Error: Invalid effect class name: " .. className)

				return
			end

			_G.g_effectManager:registerEffectClass(modName .. "." .. className, effectClass)
		end,
		getEffectClass = function (self, className)
			local effectClass = _G.g_effectManager:getEffectClass(className)

			if effectClass == nil then
				effectClass = _G.g_effectManager:getEffectClass(modName .. "." .. className)
			end

			return effectClass
		end
	}

	setmetatable(modEnv.g_effectManager, {
		__index = _G.g_effectManager
	})

	local userProfilePath = getUserProfileAppPath()
	local sub = string.sub
	local len = string.len

	local function protectedDelete(func)
		return function (filename)
			local modSettingsDirectory = userProfilePath .. "modSettings/" .. modName

			if sub(filename, 1, len(modSettingsDirectory)) == modSettingsDirectory then
				func(filename)
			else
				print(string.format("Error: No access to folder '%s'", filename))
				print(string.format("Info: Mod has full access in '%s'", modSettingsDirectory))
				printCallstack()
			end
		end
	end

	modEnv.InitStaticEventClass = ""
	modEnv.InitStaticObjectClass = ""
	modEnv.loadMod = ""
	modEnv.loadModDesc = ""
	modEnv.loadDlcs = ""
	modEnv.loadDlcsFromDirectory = ""
	modEnv.loadMods = ""
	modEnv.reloadDlcsAndMods = ""
	modEnv.verifyDlcs = ""
	modEnv.deleteFile = protectedDelete(deleteFile)
	modEnv.deleteFolder = protectedDelete(deleteFolder)
	modEnv.isAbsolutPath = isAbsolutPath
	modEnv.g_isDevelopmentVersion = g_isDevelopmentVersion
	modEnv.GS_IS_CONSOLE_VERSION = GS_IS_CONSOLE_VERSION

	if not isDLCFile then
		modEnv.ClassUtil = {
			getClassModName = function (self, className)
				local classModName = _G.ClassUtil.getClassModName(className)

				if classModName == nil then
					classModName = _G.ClassUtil.getClassModName(modName .. "." .. className)
				end

				return classModName
			end
		}
	end

	local onCreateUtil = {
		onCreateFunctions = {}
	}
	modEnv.g_onCreateUtil = onCreateUtil

	function onCreateUtil.addOnCreateFunction(name, func)
		onCreateUtil.onCreateFunctions[name] = func
	end

	function onCreateUtil.activateOnCreateFunctions()
		for name, func in pairs(onCreateUtil.onCreateFunctions) do
			modOnCreate[name] = function (self, id)
				func(id)
			end
		end
	end

	function onCreateUtil.deactivateOnCreateFunctions()
		for name, _ in pairs(onCreateUtil.onCreateFunctions) do
			modOnCreate[name] = nil
		end
	end

	xmlFile:iterate("modDesc.l10n.text", function (_, baseName)
		local name = xmlFile:getString(baseName .. "#name")
		local text = xmlFile:getString(baseName .. "." .. g_languageShort)

		if text == nil then
			text = xmlFile:getString(baseName .. ".en")

			if text == nil then
				text = xmlFile:getString(baseName .. ".de")
			end
		end

		if text == nil or name == nil then
			print("Warning: No l10n text found for entry '" .. name .. "' in mod '" .. modName .. "'")
		elseif modEnv.g_i18n:hasModText(name) then
			print("Warning: Duplicate l10n entry '" .. name .. "' in mod '" .. modName .. "'. Ignoring this definition.")
		else
			modEnv.g_i18n:setText(name, text)
		end
	end)

	local l10nFilenamePrefix = xmlFile:getString("modDesc.l10n#filenamePrefix")

	if l10nFilenamePrefix ~= nil then
		local l10nFilenamePrefixFull = Utils.getFilename(l10nFilenamePrefix, modDir)
		local l10nXmlFile, l10nFilename = nil
		local langs = {
			g_languageShort,
			"en",
			"de"
		}

		for _, lang in ipairs(langs) do
			l10nFilename = l10nFilenamePrefixFull .. "_" .. lang .. ".xml"

			if fileExists(l10nFilename) then
				l10nXmlFile = loadXMLFile("modL10n", l10nFilename)

				break
			end
		end

		if l10nXmlFile ~= nil then
			local textI = 0

			while true do
				local key = string.format("l10n.texts.text(%d)", textI)

				if not hasXMLProperty(l10nXmlFile, key) then
					break
				end

				local name = getXMLString(l10nXmlFile, key .. "#name")
				local text = getXMLString(l10nXmlFile, key .. "#text")

				if name ~= nil and text ~= nil then
					if modEnv.g_i18n:hasModText(name) then
						print("Warning: Duplicate l10n entry '" .. name .. "' in '" .. l10nFilename .. "'. Ignoring this definition.")
					else
						modEnv.g_i18n:setText(name, text:gsub("\r\n", "\n"))
					end
				end

				textI = textI + 1
			end

			delete(l10nXmlFile)
		else
			print("Warning: No l10n file found for '" .. l10nFilenamePrefix .. "' in mod '" .. modName .. "'")
		end
	end

	local title = xmlFile:getI18NValue("modDesc.title", "", modName, true)
	local desc = xmlFile:getI18NValue("modDesc.description", "", modName, true)
	local iconFilename = xmlFile:getI18NValue("modDesc.iconFilename", "", modName, true)

	if title == "" then
		print("Error: Missing title in mod " .. modName)
		xmlFile:delete()

		return
	end

	if desc == "" then
		print("Error: Missing description in mod " .. modName)
		xmlFile:delete()

		return
	end

	local isMultiplayerSupported = xmlFile:getBool("modDesc.multiplayer#supported", false)
	local isOnlyMultiplayerSupported = xmlFile:getBool("modDesc.multiplayer#only", false)

	if modFileHash == nil then
		if isMultiplayerSupported then
			print("Warning: Only zip mods are supported in multiplayer. You need to zip the mod " .. modName .. " to use it in multiplayer.")
		end

		isMultiplayerSupported = false
	end

	if not isMultiplayerSupported and isOnlyMultiplayerSupported then
		print("Error: Both multiplayer and singleplayer are unsupported in mod " .. modName)
		xmlFile:delete()

		return
	end

	if isMultiplayerSupported and iconFilename == "" then
		print("Error: Missing icon filename in mod " .. modName)
		xmlFile:delete()

		return
	end

	xmlFile:iterate("modDesc.maps.map", function (_, baseName)
		g_mapManager:loadMapFromXML(xmlFile, baseName, modDir, modName, isMultiplayerSupported, isDLCFile)
	end)

	local author = xmlFile:getI18NValue("modDesc.author", "", modName, true)

	if isDLCFile then
		local dlcProductId = xmlFile:getString("modDesc.productId")

		if dlcProductId == nil or modVersion == nil then
			print("Error: invalid product id or version in DLC " .. modName)
		else
			addNotificationFilter(dlcProductId, modVersion)
		end
	end

	local hasScripts = xmlFile:hasProperty("modDesc.extraSourceFiles.sourceFile(0)") or xmlFile:hasProperty("modDesc.specializations.specialization(0)")
	local dependencies = nil

	if xmlFile:hasProperty("modDesc.dependencies.dependency(0)") then
		dependencies = {}

		xmlFile:iterate("modDesc.dependencies.dependency", function (index, key)
			local name = xmlFile:getString(key)

			if name ~= nil and name:len() > 0 then
				dependencies[#dependencies + 1] = name
			end
		end)
	end

	local uniqueType = xmlFile:getString("modDesc.uniqueType")

	xmlFile:iterate("modDesc.extraContent.key", function (_, xmlKey)
		local key = xmlFile:getString(xmlKey)

		if key ~= nil then
			local item, errorCode = g_extraContentSystem:unlockItem(key, true)

			if item ~= nil and errorCode == ExtraContentSystem.UNLOCKED then
				print("ExtraContent: Unlocked '" .. g_i18n:convertText(item.title) .. "'")
				g_extraContentSystem:saveToProfile()
			end
		end
	end)

	iconFilename = Utils.getFilename(iconFilename, modDir)

	g_modManager:addMod(title, desc, modVersion, modDescVersion, author, iconFilename, modName, modDir, modFile, isMultiplayerSupported, modFileHash, absBaseFilename, isDirectory, isDLCFile, hasScripts, dependencies, isOnlyMultiplayerSupported, isSelectable, uniqueType)
	xmlFile:delete()
end

function resetModOnCreateFunctions()
	modOnCreate = {}
end

function loadMod(modName, modDir, modFile, modTitle)
	if g_modIsLoaded[modName] then
		return
	end

	g_modIsLoaded[modName] = true
	g_modNameToDirectory[modName] = modDir
	local modEnv = _G[modName]

	if modEnv == nil then
		return
	end

	local xmlFile = XMLFile.load("ModFile", modFile)
	local isDLCFile = false

	if string.endsWith(modFile, "dlcDesc.xml") then
		isDLCFile = true
	end

	if isDLCFile then
		print("  Load dlc: " .. modName)
	else
		print("  Load mod: " .. modName)
	end

	g_currentModDirectory = modDir
	g_currentModName = modName

	if g_modSettingsDirectory ~= nil then
		g_currentModSettingsDirectory = g_modSettingsDirectory .. modName .. "/"
	end

	if not GS_IS_CONSOLE_VERSION or isDLCFile or g_isDevelopmentConsoleScriptModTesting then
		xmlFile:iterate("modDesc.extraSourceFiles.sourceFile", function (_, key)
			local filename = xmlFile:getString(key .. "#filename")

			if filename ~= nil then
				source(modDir .. filename, modName)
			end
		end)
	end

	xmlFile:iterate("modDesc.brands.brand", function (_, key)
		local name = xmlFile:getString(key .. "#name")
		local title = xmlFile:getString(key .. "#title")
		local image = xmlFile:getString(key .. "#image")
		local offset = xmlFile:getFloat(key .. "#imageOffset")

		g_brandManager:addBrand(name, title, image, modDir, true, nil, offset)
	end)

	if isDLCFile then
		xmlFile:iterate("modDesc.storeCategories.storeCategory", function (_, key)
			g_storeManager:loadCategoryFromXML(xmlFile, key, modDir)
		end)
	end

	xmlFile:iterate("modDesc.specializations.specialization", function (_, key)
		local specName = xmlFile:getString(key .. "#name")
		local className = xmlFile:getString(key .. "#className")
		local filename = xmlFile:getString(key .. "#filename")

		if specName ~= nil and className ~= nil and filename ~= nil then
			filename = modDir .. filename
			className = modName .. "." .. className
			specName = modName .. "." .. specName

			if not GS_IS_CONSOLE_VERSION or isDLCFile then
				g_specializationManager:addSpecialization(specName, className, filename, modName)
			else
				print("Error: Can't register specialization " .. specName .. " with scripts on consoles.")
			end
		end
	end)
	xmlFile:iterate("modDesc.vehicleTypes.type", function (_, key)
		g_vehicleTypeManager:loadTypeFromXML(xmlFile.handle, key, isDLCFile, modDir, modName)
	end)
	xmlFile:iterate("modDesc.placeableSpecializations.specialization", function (_, key)
		local specName = xmlFile:getString(key .. "#name")
		local className = xmlFile:getString(key .. "#className")
		local filename = xmlFile:getString(key .. "#filename")

		if specName ~= nil and className ~= nil and filename ~= nil then
			filename = modDir .. filename
			className = modName .. "." .. className
			specName = modName .. "." .. specName

			if not GS_IS_CONSOLE_VERSION or isDLCFile then
				g_placeableSpecializationManager:addSpecialization(specName, className, filename, modName)
			else
				print("Error: Can't register placeable specialization " .. specName .. " with scripts on consoles.")
			end
		end
	end)
	xmlFile:iterate("modDesc.placeableTypes.type", function (_, key)
		g_placeableTypeManager:loadTypeFromXML(xmlFile.handle, key, isDLCFile, modDir, modName)
	end)
	xmlFile:iterate("modDesc.bales.bale", function (_, key)
		g_baleManager:loadModBaleFromXML(xmlFile, key, modDir, modName)
	end)
	xmlFile:iterate("modDesc.jointTypes.jointType", function (_, key)
		local name = xmlFile:getString(key .. "#name")

		if name ~= nil then
			AttacherJoints.registerJointType(name)
		end
	end)
	xmlFile:iterate("modDesc.materialHolders.materialHolder", function (_, key)
		local filename = xmlFile:getString(key .. "#filename")

		if filename ~= nil then
			filename = Utils.getFilename(filename, g_currentModDirectory)

			g_materialManager:addModMaterialHolder(filename)
		end
	end)
	xmlFile:iterate("modDesc.brandColors.color", function (_, key)
		g_brandColorManager:loadBrandColorFromXML(xmlFile.handle, key)
	end)
	xmlFile:iterate("modDesc.connectionHoses.connectionHose", function (_, key)
		local xmlFilename = xmlFile:getString(key .. "#xmlFilename")

		if xmlFilename ~= nil then
			xmlFilename = Utils.getFilename(xmlFilename, g_currentModDirectory)

			g_connectionHoseManager:addModConnectionHoses(xmlFilename, modName, g_currentModDirectory)
		end
	end)
	xmlFile:iterate("modDesc.storeItems.storeItem", function (_, key)
		local storeItemXMLFilename = xmlFile:getString(key .. "#xmlFilename")

		if storeItemXMLFilename ~= nil then
			g_storeManager:addModStoreItem(storeItemXMLFilename, modDir, modName, not isDLCFile, false, modTitle)
		end
	end)
	xmlFile:iterate("modDesc.storePacks.storePack", function (_, key)
		local name = xmlFile:getString(key .. "#name")
		local title = xmlFile:getString(key .. "#title")
		local imageFilename = xmlFile:getString(key .. "#image")

		if title ~= nil and title:sub(1, 6) == "$l10n_" then
			title = g_i18n:getText(title:sub(7))
		end

		g_storeManager:addModStorePack(name, title, imageFilename, modDir)
	end)
	xmlFile:delete()

	g_currentModDirectory = nil
	g_currentModName = nil
end

function reloadDlcsAndMods()
	if g_currentMission ~= nil then
		print("Dlc reloading is not supported during gameplay")

		return
	end

	for i = g_mapManager:getNumOfMaps(), 1, -1 do
		local map = g_mapManager:getMapDataByIndex(i)

		if map.isModMap then
			g_mapManager:removeMapItem(i)
		end
	end

	while g_modManager:getNumOfMods() > 0 do
		g_modManager:removeMod(g_modManager:getModByIndex(1))
	end

	g_modIsLoaded = {}
	g_modNameToDirectory = {}
	g_dlcModNameHasPrefix = {}
	isReloadingDlcs = true

	startUpdatePendingMods()
	loadDlcsDirectories()
	loadDlcs()

	if isModUpdateRunning() then
		local startedRepeat = startFrameRepeatMode()

		while isModUpdateRunning() do
			usleep(16000)
		end

		if startedRepeat then
			endFrameRepeatMode()
		end
	end

	if Platform.supportsMods then
		loadMods()
	end

	isReloadingDlcs = false
end

function verifyDlcs()
	local missingMods = {}

	for _, mod in ipairs(g_modManager:getMods()) do
		if not fileExists(mod.modFile) then
			table.insert(missingMods, mod)
		end
	end

	return table.getn(missingMods) == 0, missingMods
end

function checkForNewDlcs()
	if Platform.isXbox then
		local hasNewPaths = false
		local newDlcPaths = {}
		local numDlcPaths = getNumDlcPaths()

		for i = 0, numDlcPaths - 1 do
			local path = getDlcPath(i)

			if path ~= nil then
				newDlcPaths[path] = true

				if g_lastCheckDlcPaths[path] == nil then
					hasNewPaths = true
				end
			end
		end

		g_lastCheckDlcPaths = newDlcPaths

		return hasNewPaths
	else
		return true
	end
end

checkForNewDlcs()

function loadDlcsDirectories()
	g_dlcsDirectories = {}
	local numDlcPaths = getNumDlcPaths()

	for i = 0, numDlcPaths - 1 do
		local path = getDlcPath(i)

		if path ~= nil then
			table.insert(g_dlcsDirectories, {
				isLoaded = true,
				path = path
			})

			if path == getAppBasePath() .. "pdlc/" then
				table.insert(g_dlcsDirectories, {
					isLoaded = false,
					path = "pdlc/"
				})
			end
		end
	end
end

loadDlcsDirectories()

function addModEventListener(listener)
	table.insert(g_modEventListeners, listener)
end

function removeModEventListener(listener)
	for i, listenerI in ipairs(g_modEventListeners) do
		if listenerI == listener then
			table.remove(g_modEventListeners, i)

			break
		end
	end
end
