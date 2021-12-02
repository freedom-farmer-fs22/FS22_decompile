ModHubController = {}
local ModHubController_mt = Class(ModHubController)
ModHubController.CATEGORY_ID_CONTEST = 7
ModHubController.CATEGORY_ID_DOWNLOAD = 1
ModHubController.CATEGORY_ID_UPDATE = 2

function ModHubController.new(messageCenter, l10n, gameSettings)
	local self = setmetatable({}, ModHubController_mt)
	self.l10n = l10n
	self.messageCenter = messageCenter
	self.gameSettings = gameSettings
	self.categories = {}
	self.localCategories = {}
	self.modIdToInfo = {}
	self.categoryNameMapping = {}
	self.hasChanges = false
	self.hasTriggedUUIDInEngine = false
	self.priceMapping = {
		no = "DLCPriceEUR",
		hu = "DLCPriceEUR",
		fi = "DLCPriceEUR",
		tr = "DLCPriceUSD",
		nl = "DLCPriceEUR",
		en = "DLCPriceEUR",
		fc = "DLCPriceUSD",
		pl = "DLCPriceEUR",
		it = "DLCPriceEUR",
		cs = "DLCPriceUSD",
		ct = "DLCPriceUSD",
		da = "DLCPriceEUR",
		ea = "DLCPriceUSD",
		es = "DLCPriceEUR",
		cz = "DLCPriceEUR",
		de = "DLCPriceEUR",
		kr = "DLCPriceUSD",
		sv = "DLCPriceEUR",
		fr = "DLCPriceEUR",
		ru = "DLCPriceUSD",
		jp = "DLCPriceUSD",
		br = "DLCPriceUSD",
		ro = "DLCPriceUSD",
		pt = "DLCPriceEUR"
	}
	local numLanguages = getNumOfLanguages()

	for i = 0, numLanguages - 1 do
		local code = getLanguageCode(i)

		if self.priceMapping[code] == nil then
			Logging.devError("ModHubController: Missing price mapping for '%s'", code)

			self.priceMapping[g_languageShort] = "DLCPriceUSD"
		end
	end

	self.messageCenter:subscribe(MessageType.USER_PROFILE_CHANGED, self.userProfileChanged, self)

	return self
end

function ModHubController:reset()
	self.isInitialized = false
	self.categories = {}
	self.categoryImageMapping = {}
	self.modIdToInfo = {}
	self.categoryNameMapping = {}
	self.categoryIsHidden = {}
	self.localCategories = {}
end

function ModHubController:startModification()
	self.hasChanges = false
end

function ModHubController:endModification()
	if self.hasChanges then
		if not GS_IS_CONSOLE_VERSION and not GS_PLATFORM_GGP then
			RestartManager:setStartScreen(RestartManager.START_SCREEN_MAIN)
			doRestart(false, "")

			return
		else
			reloadDlcsAndMods()
		end
	end

	self.hasChanges = false
end

function ModHubController:load()
	if not self.isInitialized then
		if not self.isReloading then
			self:loadCategoriesFromXML()
		end

		local numCategories = getNumModCategories()

		for i = 0, numCategories - 1 do
			if i ~= ModHubController.CATEGORY_ID_CONTEST or not GS_IS_CONSOLE_VERSION and getNumOfMods(i) > 0 then
				local categoryName = getModCategoryName(i)
				local localCategory = self.localCategories[categoryName]

				if localCategory ~= nil then
					local iconFilename = localCategory.imageFilename
					local isHidden = localCategory.isTab or localCategory.isHidden
					local title = nil

					if localCategory.title ~= nil then
						title = self.l10n:convertText(localCategory.title)
					end

					if title == nil then
						title = self.l10n:getText("modHub_" .. categoryName)
					end

					local numNewItems, numAvailableUpdates, numConflictedItems = self:getCategoryData(i + 1)
					local categoryInfo = ModCategoryInfo.new(i + 1, title, iconFilename, categoryName, isHidden)

					categoryInfo:setNumAvailableUpdates(numAvailableUpdates)
					categoryInfo:setNumNewItems(numNewItems)
					categoryInfo:setNumConflictedItems(numConflictedItems)

					self.categoryNameMapping[categoryName] = categoryInfo
				else
					Logging.warning("Could not find modhub category %s in modHub.xml", categoryName)
				end
			end
		end

		for _, categoryName in ipairs(self.localCategoriesSorted) do
			local categoryInfo = self.categoryNameMapping[categoryName]

			if categoryInfo ~= nil then
				table.insert(self.categories, categoryInfo)
			end
		end

		self.isInitialized = true
	end
end

function ModHubController:reload()
	self.categoryNameMapping = {}
	self.categories = {}
	self.isInitialized = false
	self.isReloading = true

	self:load()
end

function ModHubController:loadCategoriesFromXML()
	self.localCategories = {}
	self.localCategoriesSorted = {}
	local xmlFile = loadXMLFile("configFile", "dataS/modHub.xml")
	local i = 0

	while true do
		local key = string.format("modHub.categories.category(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local imageFilename = getXMLString(xmlFile, key .. "#imageFilename")

		if name ~= nil and imageFilename ~= nil then
			local localCategory = {
				name = name,
				imageFilename = imageFilename,
				isTab = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isTab"), false),
				isHidden = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isHidden"), false),
				title = getXMLString(xmlFile, key .. "#title")
			}
			self.localCategories[name] = localCategory

			table.insert(self.localCategoriesSorted, name)
		end

		i = i + 1
	end

	delete(xmlFile)
end

function ModHubController:getCategories()
	return self.categories
end

function ModHubController:getVisibleCategories()
	local list = {}

	for i = 1, #self.categories do
		local category = self.categories[i]

		if not category.isHidden and category:getNumMods() > 0 then
			list[#list + 1] = category
		end
	end

	return list
end

function ModHubController:getCategoryData(categoryId)
	local numOfMods = 0

	if categoryId > 0 then
		numOfMods = getNumOfMods(categoryId - 1)
	end

	local numNewItems = 0
	local numUpdates = 0
	local numConflicts = 0

	if categoryId == ModHubController.CATEGORY_ID_DOWNLOAD then
		numNewItems = numOfMods
	elseif categoryId == ModHubController.CATEGORY_ID_UPDATE then
		numUpdates = numOfMods
	else
		local mods = self:getModsByCategory(categoryId)

		for _, modInfo in ipairs(mods) do
			numUpdates = numUpdates + modInfo:getNumUpdates()
			numConflicts = numConflicts + modInfo:getNumConflicts()
			numNewItems = numNewItems + modInfo:getNumNew()
		end
	end

	return numNewItems, numUpdates, numConflicts
end

function ModHubController:getModsByCategory(categoryId, visibleOnly)
	local mods = {}
	local numOfMods = getNumOfMods(categoryId - 1)

	if numOfMods > 0 then
		for i = 0, numOfMods - 1 do
			local modId = getModId(categoryId - 1, i)
			local modInfo = self:getModInfo(modId)

			if not visibleOnly or not modInfo:getIsDLC() or modInfo:getPriceString():len() > 1 or modInfo:getIsInstalled() then
				table.insert(mods, modInfo)
			end
		end
	end

	return mods
end

function ModHubController:getCategory(name)
	return self.categoryNameMapping[name]
end

function ModHubController:getModInfo(modId)
	local modInfo = self.modIdToInfo[modId]

	if modInfo == nil then
		if type(modId) ~= "number" then
			return nil
		end

		modInfo = ModInfo.new(modId, self:getPostFix(), self.priceMapping[g_languageShort])
		self.modIdToInfo[modId] = modInfo
	end

	return modInfo
end

function ModHubController:getDependendMods(modId)
	local dependendMods = {}

	for i = 0, getModNumDependencies(modId) - 1 do
		local dependendModId = getModDependency(modId, i)
		local modInfo = self:getModInfo(dependendModId)

		table.insert(dependendMods, modInfo)
	end

	return dependendMods
end

function ModHubController:getPostFix()
	if g_languageShort == "de" or g_languageShort == "fr" then
		return g_languageShort
	end

	return "en"
end

function ModHubController:getTotalFilesizeKb(modId)
	local modInfo = self:getModInfo(modId)
	local dependendMods = self:getDependendMods(modId)
	local totalFilesizeKb = math.floor((modInfo:getFilesize() + 1023) / 1024)

	for _, dependendMod in ipairs(dependendMods) do
		if not dependendMod.isInstalled then
			totalFilesizeKb = totalFilesizeKb + math.floor((dependendMod:getFilesize() + 1023) / 1024)
		end
	end

	return totalFilesizeKb
end

function ModHubController:getFreeModSpaceKb()
	return getModFreeSpaceKb()
end

function ModHubController:getUsedModSpaceKb()
	return getModUsedSpaceKb()
end

function ModHubController:getTotalModSpaceKb()
	return getModFreeSpaceKb() + getModUsedSpaceKb()
end

function ModHubController:isContestEnabled()
	if not self.isInitialized then
		return false
	end

	if self.isContestEnabledStored == nil then
		self.isContestEnabledStored = getNumOfMods(ModHubController.CATEGORY_ID_CONTEST) > 0
	end

	return self.isContestEnabledStored
end

function ModHubController:install(modId)
	local success = installMod(modId)

	if success then
		local dependendMods = self:getDependendMods(modId)
		local numFailed = 0
		local failedDependendMods = {}

		for _, dependendMod in ipairs(dependendMods) do
			if not dependendMod.isInstalled then
				local dependendSuccess = installMod(dependendMod.modId)

				if not dependendSuccess then
					table.insert(failedDependendMods, dependendMod)
				end
			end
		end

		if numFailed == 0 then
			self.addedToDownloadCallback()
		else
			self.dependendModInstallFailedCallback(failedDependendMods)
		end
	else
		self.modInstallFailedCallback()
	end

	if self.discSpaceChangedCallback ~= nil then
		self.discSpaceChangedCallback()
	end
end

function ModHubController:setModInstallFailedCallback(callback, target)
	function self.modInstallFailedCallback()
		callback(target)
	end
end

function ModHubController:setDependendModIstallFailedCallback(callback, target)
	function self.dependendModInstallFailedCallback(failedDependendMods)
		callback(target, failedDependendMods)
	end
end

function ModHubController:setAddedToDownloadCallback(callback, target)
	function self.addedToDownloadCallback()
		callback(target)
	end
end

function ModHubController:update(modId)
	local success = updateMod(modId)

	if success then
		local numFailed = 0
		local failedDependendMods = {}
		local dependendMods = self:getDependendMods(modId)

		for _, dependendMod in ipairs(dependendMods) do
			if dependendMod.isUpdate then
				local dependendSuccess = updateMod(modId)

				if not dependendSuccess then
					table.insert(failedDependendMods, dependendMod)
				end
			end
		end

		if numFailed == 0 then
			self.addedToDownloadCallback()
		else
			self.dependendModInstallFailedCallback(failedDependendMods)
		end
	else
		self.modInstallFailedCallback()
	end

	self.discSpaceChangedCallback()
end

function ModHubController:uninstall(modId)
	local mod = self:getModInfo(modId)
	local hash = mod.hash
	local success = uninstallMod(modId)

	if success then
		self.hasChanges = true
		mod = g_modManager:getModByFileHash(hash)

		if mod ~= nil then
			g_modManager:removeMod(mod)
		end

		self.uninstalledCallback()
	else
		self.uninstallFailedCallback()
	end

	self.discSpaceChangedCallback()
end

function ModHubController:setUninstallFailedCallback(callback, target)
	function self.uninstallFailedCallback()
		callback(target)
	end
end

function ModHubController:setUninstalledCallback(callback, target)
	function self.uninstalledCallback()
		callback(target)
	end
end

function ModHubController:setDiscSpaceChangedCallback(callback, target)
	function self.discSpaceChangedCallback()
		local freeSpaceKb = getModFreeSpaceKb()
		local usedSpaceKb = getModUsedSpaceKb()

		callback(target, freeSpaceKb, usedSpaceKb)
	end
end

function ModHubController:vote(modId, value)
	if not self.hasTriggedUUIDInEngine then
		getUniqueUserId()

		self.hasTriggedUUIDInEngine = true
	end

	setModHubRating(modId, value)

	if self.votedCallback ~= nil then
		self.votedCallback()
	end
end

function ModHubController:setVotedCallback(callback, target)
	function self.votedCallback()
		callback(target)
	end
end

function ModHubController:getVote(modId)
	if not self.hasTriggedUUIDInEngine then
		getUniqueUserId()

		self.hasTriggedUUIDInEngine = true
	end

	local ratingValue, httpReturnCode = getModHubRating(modId)

	if httpReturnCode == 0 then
		return 0
	else
		return ratingValue
	end
end

function ModHubController:setShowAllMods(showAll)
	setEnableBetaMods(showAll)
end

function ModHubController:searchMods(categoryId, text)
	text = text:lower()
	local hits = {}

	if categoryId ~= nil then
		self:searchInCategory(hits, categoryId, text)
	else
		for _, category in ipairs(self.categories) do
			if self:isCategorySearchable(category) then
				hits = self:searchInCategory(hits, category.id, text)
			end
		end
	end

	local list = {}

	for _, info in pairs(hits) do
		table.insert(list, info)
	end

	table.sort(list, function (a, b)
		return b[2] < a[2]
	end)

	for i, info in ipairs(list) do
		list[i] = info[1]
	end

	return list
end

function ModHubController:isCategorySearchable(category)
	return not category.isHidden or category.name == "contest" or category.name == "dlc"
end

function ModHubController:searchInCategory(list, categoryId, text)
	local numOfMods = getNumOfMods(categoryId - 1)
	local postFix = self:getPostFix()

	if numOfMods > 0 then
		for i = 0, numOfMods - 1 do
			local modId = getModId(categoryId - 1, i)

			if list[modId] == nil then
				local hit = false
				local score = 0
				local title = getModMetaAttributeString(modId, "title_" .. postFix)
				local sStart, sEnd = title:lower():find(text)

				if sStart ~= nil then
					score = self:generateSearchScore(text, title, sStart, sEnd)
					hit = true
				else
					local author = getModMetaAttributeString(modId, "author")
					sStart, sEnd = author:lower():find(text)

					if sStart ~= nil then
						score = self:generateSearchScore(text, author, sStart, sEnd)
						hit = true
					end
				end

				if hit then
					list[modId] = {
						self:getModInfo(modId),
						score
					}
				end
			end
		end
	end

	return list
end

function ModHubController:generateSearchScore(input, result, start, finish)
	local resultLength = result:len()

	return 0.8 * input:len() / resultLength + 0.2 * (1 - start / resultLength)
end

function ModHubController:userProfileChanged()
	self.hasTriggedUUIDInEngine = false

	self:updateRecommendationSystem()
end

function ModHubController:updateRecommendationSystem()
	local numTutorialsPlayed = 0
	local isLastUsedCharacterMale = self.gameSettings:getValue(GameSettings.SETTING.LAST_PLAYER_STYLE_MALE)
	local usesHelpWindow = self.gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU)
	local playedMP = self.gameSettings.joinGame.hasNoPassword ~= nil or self.gameSettings.createGame.useUpnp ~= nil
	local totalPlayedHours = 0

	if g_careerScreen.totalPlayedHours ~= nil then
		totalPlayedHours = g_careerScreen.totalPlayedHours
	end

	setModDownloadManagerRecommenderParams(usesHelpWindow, playedMP, isLastUsedCharacterMale, totalPlayedHours, numTutorialsPlayed)
end
