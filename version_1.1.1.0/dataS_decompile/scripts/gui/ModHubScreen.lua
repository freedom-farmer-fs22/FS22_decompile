ModHubScreen = {}
local ModHubScreen_mt = Class(ModHubScreen, TabbedMenuWithDetails)
ModHubScreen.SPECIAL_LIST_LIMIT = 42
ModHubScreen.CONTROLS = {
	PAGE_DOWNLOADS = "pageDownloads",
	PAGE_LOADING = "pageLoading",
	PAGE_INSTALLED = "pageInstalled",
	PAGE_CONTEST = "pageContest",
	PAGE_DLCS = "pageDLCs",
	PAGE_SEARCH = "pageSearch",
	PAGE_EXTRA_CONTENT = "pageExtraContent",
	PAGE_DETAILS = "pageDetails",
	PAGE_ITEMS = "pageItems",
	PAGE_UPDATES = "pageUpdates",
	PAGE_CATEGORIES = "pageCategories",
	PAGE_RECOMMENDED = "pageRecommended",
	PAGE_LATEST = "pageLatest",
	PAGE_MOST_DOWNLOADED = "pageMostDownloaded",
	PAGE_BEST = "pageBest",
	LOADING = "loadingElement"
}

function ModHubScreen.new(target, customMt, messageCenter, l10n, inputManager, modHubController, isConsoleVersion)
	local self = TabbedMenuWithDetails.new(target, customMt or ModHubScreen_mt, messageCenter, l10n, inputManager)

	self:registerControls(ModHubScreen.CONTROLS)

	self.modHubController = modHubController
	self.isConsoleVersion = isConsoleVersion
	self.checkForLoaded = true
	self.isLoading = true
	self.showingAllMods = false

	return self
end

function ModHubScreen:onGuiSetupFinished()
	ModHubScreen:superClass().onGuiSetupFinished(self)

	self.showingAllMods = g_gameSettings:getValue(GameSettings.SETTING.SHOW_ALL_MODS)

	self.modHubController:setShowAllMods(self.showingAllMods)
	self:setupPages()
	self:setupMenuButtonInfo()
end

function ModHubScreen:setupPages()
	local pagePredicate = self:makeIsModHubEnabledPredicate()
	local contestPredicate = self:makeIsContestEnabledPredicate()
	local detailsPredicate = self:makeIsModHubItemsEnabledPredicate()
	local orderedPages = {
		{
			self.pageLoading,
			self:makeIsLoadingEnabledPredicate(),
			ModHubScreen.TAB_UV.CATEGORIES
		},
		{
			self.pageCategories,
			pagePredicate,
			ModHubScreen.TAB_UV.CATEGORIES
		},
		{
			self.pageInstalled,
			pagePredicate,
			ModHubScreen.TAB_UV.INSTALLED
		},
		{
			self.pageUpdates,
			pagePredicate,
			ModHubScreen.TAB_UV.UPDATES
		},
		{
			self.pageDownloads,
			pagePredicate,
			ModHubScreen.TAB_UV.DOWNLOADS
		},
		{
			self.pageDLCs,
			pagePredicate,
			ModHubScreen.TAB_UV.DLCS
		},
		{
			self.pageExtraContent,
			pagePredicate,
			ModHubScreen.TAB_UV.EXTRA_CONTENT
		},
		{
			self.pageBest,
			pagePredicate,
			ModHubScreen.TAB_UV.BEST
		},
		{
			self.pageMostDownloaded,
			pagePredicate,
			ModHubScreen.TAB_UV.MOST_DOWNLOADED
		},
		{
			self.pageLatest,
			pagePredicate,
			ModHubScreen.TAB_UV.LATEST
		},
		{
			self.pageContest,
			contestPredicate,
			ModHubScreen.TAB_UV.CONTEST
		},
		{
			self.pageRecommended,
			pagePredicate,
			ModHubScreen.TAB_UV.RECOMMENDED
		},
		{
			self.pageItems,
			detailsPredicate,
			ModHubScreen.TAB_UV.BEST
		},
		{
			self.pageDetails,
			detailsPredicate,
			ModHubScreen.TAB_UV.BEST
		},
		{
			self.pageSearch,
			detailsPredicate,
			ModHubScreen.TAB_UV.BEST
		}
	}

	for i, pageDef in ipairs(orderedPages) do
		local page, predicate, iconUVs = unpack(pageDef)

		self:registerPage(page, i, predicate)

		local normalizedUVs = GuiUtils.getUVs(iconUVs)

		self:addPageTab(page, g_iconsUIFilename, normalizedUVs)
	end
end

function ModHubScreen:setupMenuButtonInfo()
	local onButtonBackFunction = self.clickBackCallback
	self.defaultMenuButtonInfo = {
		{
			inputAction = InputAction.MENU_BACK,
			text = self.l10n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_BACK),
			callback = onButtonBackFunction
		}
	}
	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
	self.defaultButtonActionCallbacks = {
		[InputAction.MENU_BACK] = onButtonBackFunction
	}

	self:assignMenuButtonInfo(self.defaultMenuButtonInfo)
end

function ModHubScreen:initializePages()
	self.modHubController:setShowAllMods(self.showingAllMods)
	self.modHubController:load()
	self.modHubController:setDiscSpaceChangedCallback(self.updateDiscSpace, self)

	local onSearchButtonCallback = self:makeSelfCallback(self.onSearchButton)
	local onToggleCallback = self:makeSelfCallback(self.onToggleBeta)
	local getBetaToggleTextCallback = self:makeSelfCallback(self.getBetaToggleText)

	self.pageCategories:initialize(self.modHubController:getVisibleCategories(), self:makeSelfCallback(self.onClickCategory), self.l10n:getText(ModHubScreen.L10N_SYMBOL.HEADER_MOD_HUB), ModHubScreen.CATEGORY_IMAGE_HEIGHT_WIDTH_RATIO)
	self.pageCategories:setSearchCallback(onSearchButtonCallback)
	self.pageCategories:setBreadcrumbs(self:getBreadcrumbs(self.pageCategories))
	self.pageCategories:setToggleBetaCallback(onToggleCallback)
	self.pageCategories:setBetaToggleTextCallback(getBetaToggleTextCallback)
	self.pageExtraContent:initialize(self.l10n:getText(ModHubScreen.L10N_SYMBOL.HEADER_EXTRA_CONTENT))
	self.pageExtraContent:setBreadcrumbs(self:getBreadcrumbs(self.pageExtraContent, true))

	local clickItemCallback = self:makeClickItemCallback()
	local onSelectItemCallback = self:makeSelfCallback(self.onSelectItem)

	local function initCategoryPage(page, categoryName, limit, isDLC)
		local category = self.modHubController:getCategory(categoryName)

		if category ~= nil then
			page:initialize()
			page:setCategoryId(category.id)
			page:setCategory(categoryName)
			page:setBreadcrumbs(self:getBreadcrumbs(page, isDLC))
			page:setItemClickCallback(clickItemCallback)
			page:setItemSelectCallback(onSelectItemCallback)
			page:setSearchCallback(onSearchButtonCallback)
			page:setToggleBetaCallback(onToggleCallback)
			page:setBetaToggleTextCallback(getBetaToggleTextCallback)

			if limit ~= nil then
				page:setListSizeLimit(limit)
			end
		end
	end

	initCategoryPage(self.pageInstalled, "installed")
	initCategoryPage(self.pageLatest, "latest", ModHubScreen.SPECIAL_LIST_LIMIT)
	initCategoryPage(self.pageUpdates, "update")
	initCategoryPage(self.pageDLCs, "dlc", nil, true)
	initCategoryPage(self.pageDownloads, "download")
	initCategoryPage(self.pageBest, "best", ModHubScreen.SPECIAL_LIST_LIMIT)
	initCategoryPage(self.pageMostDownloaded, "most_downloaded", ModHubScreen.SPECIAL_LIST_LIMIT)
	initCategoryPage(self.pageContest, "contest")
	initCategoryPage(self.pageRecommended, "recommended")
	self.pageSearch:initialize()
	self.pageSearch:setItemClickCallback(clickItemCallback)
	self.pageSearch:setItemSelectCallback(onSelectItemCallback)
	self.pageItems:initialize()
	self.pageItems:setItemClickCallback(clickItemCallback)
	self.pageItems:setItemSelectCallback(onSelectItemCallback)
	self.pageItems:setSearchCallback(onSearchButtonCallback)
	self.pageItems:setToggleBetaCallback(onToggleCallback)
	self.pageItems:setBetaToggleTextCallback(getBetaToggleTextCallback)
	self.pageDetails:initialize()
end

function ModHubScreen:reset()
	ModHubScreen:superClass().reset(self)
	self.modHubController:reset()

	self.showingAllMods = false
end

function ModHubScreen:onOpen(element)
	self.modHubController:startModification()

	if modDownloadManagerLoaded() then
		self:setIsLoading(false)

		self.checkForLoaded = false
	else
		self:setIsLoading(true)
	end

	ModHubScreen:superClass().onOpen(self)
end

function ModHubScreen:onClose(element)
	self.modHubController:endModification()
	ModHubScreen:superClass().onClose(self)
end

function ModHubScreen:update(dt)
	ModHubScreen:superClass().update(self, dt)

	if getModDownloadAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
		self:changeScreen(MainScreen)

		return
	end

	if getNetworkError() then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")

		return
	end

	if self.checkForLoaded and modDownloadManagerLoaded() then
		self.checkForLoaded = false

		self:setIsLoading(false)
	end
end

function ModHubScreen:setIsLoading(loading)
	self.isLoading = loading

	if not loading and not self.initialized then
		self:initializePages()

		self.initialized = true
	end
end

function ModHubScreen:exitMenu()
	self:changeScreen(MainScreen)
end

function ModHubScreen:getBreadcrumbs(page, isDLC)
	local list = ModHubScreen:superClass().getBreadcrumbs(self, page)
	local firstPage = self:getStack(page)[1].page

	if firstPage ~= self.pageCategories then
		if isDLC then
			table.insert(list, 1, self.l10n:getText("button_downloadableContent"))
		else
			table.insert(list, 1, self.l10n:getText("modHub_title"))
		end
	end

	return list
end

function ModHubScreen:onClickCategory(categoryId, categoryName)
	self.pageItems:setCategoryId(categoryId)
	self.pageItems:setCategory(categoryName)
	self:pushDetail(self.pageItems)
	self.pageItems:setBreadcrumbs(self:getBreadcrumbs())
end

function ModHubScreen:onSelectItem(page, modId)
	local modInfo = self.modHubController:getModInfo(modId)

	page:setModInfo(modInfo)
end

function ModHubScreen:updateDiscSpace(freeSpaceKb, usedSpaceKb)
	local topFrame = self:getTopFrame()

	if topFrame ~= self.pageLoading and topFrame ~= self.pageExtraContent then
		if Platform.hasLimitedModSpace then
			local total = (freeSpaceKb + usedSpaceKb) / 1024
			local used = usedSpaceKb / 1024

			topFrame.spaceUsageLabel.parent:setVisible(true)
			topFrame.spaceUsageLabel:setText(string.format("%s / %s Mb (%0.f%%)", g_i18n:formatNumber(used, 2, true), g_i18n:formatNumber(total, 2, true), used / total * 100))
		else
			topFrame.spaceUsageLabel.parent:setVisible(false)
		end
	end
end

function ModHubScreen:onSearchButton(categoryId)
	g_gui:showTextInputDialog({
		disableFilter = true,
		maxCharacters = 40,
		callback = self.onSearchFinished,
		target = self,
		dialogPrompt = self.l10n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH),
		imePrompt = self.l10n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH),
		confirmText = self.l10n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH),
		args = categoryId
	})
end

function ModHubScreen:onSearchFinished(text, ok, categoryId)
	if ok and text:len() > 0 then
		local result = self.modHubController:searchMods(categoryId, text)

		self.pageSearch:setModItems(result)

		local breadcrumb = self.l10n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SEARCH) .. " '" .. text:lower() .. "'"
		self.pageSearch.title = breadcrumb

		self:pushDetail(self.pageSearch)
		self.pageSearch:setBreadcrumbs(self:getBreadcrumbs())
	end
end

function ModHubScreen:onToggleBeta(page)
	self.showingAllMods = not self.showingAllMods

	self.modHubController:setShowAllMods(self.showingAllMods)
	self.modHubController:reload()
	g_gameSettings:setValue(GameSettings.SETTING.SHOW_ALL_MODS, self.showingAllMods, true)
	page:reload()
	self.pageCategories:setCategories(self.modHubController:getVisibleCategories())
end

function ModHubScreen:getBetaToggleText()
	if self.showingAllMods then
		return self.l10n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SHOW_CROSSPLAY)
	else
		return self.l10n:getText(ModHubScreen.L10N_SYMBOL.BUTTON_SHOW_ALL)
	end
end

function ModHubScreen:inputEvent(action, value, eventUsed)
	eventUsed = ModHubScreen:superClass().inputEvent(self, action, value, eventUsed)

	if not eventUsed and self.currentPage == self.pageDetails then
		eventUsed = self.pageDetails:inputEvent(action, value, eventUsed)
	end

	return eventUsed
end

function ModHubScreen:onDetailOpened(...)
	ModHubScreen:superClass().onDetailOpened(self, ...)
	self:updateDiscSpace(self.modHubController:getFreeModSpaceKb(), self.modHubController:getUsedModSpaceKb())
end

function ModHubScreen:onPageChange(...)
	ModHubScreen:superClass().onPageChange(self, ...)
	self:updateDiscSpace(self.modHubController:getFreeModSpaceKb(), self.modHubController:getUsedModSpaceKb())
end

function ModHubScreen:makeClickItemCallback()
	return function (page, modId, categoryName)
		local modInfo = self.modHubController:getModInfo(modId)

		self.pageDetails:setModInfo(modInfo)
		self:pushDetail(self.pageDetails)
		self.pageDetails:setBreadcrumbs(self:getBreadcrumbs())
	end
end

function ModHubScreen:makeIsLoadingEnabledPredicate()
	return function ()
		return self.isLoading
	end
end

function ModHubScreen:makeIsModHubEnabledPredicate()
	return function ()
		return not self.isLoading and not self:getIsDetailMode()
	end
end

function ModHubScreen:makeIsModHubItemsEnabledPredicate()
	return function ()
		return false
	end
end

function ModHubScreen:makeIsContestEnabledPredicate()
	return function ()
		return not self.isLoading and not self:getIsDetailMode() and self.modHubController:isContestEnabled()
	end
end

function ModHubScreen:openWithModId(modId)
	local modInfo = self.modHubController:getModInfo(modId)

	if modInfo ~= nil then
		g_gui:showGui("ModHubScreen")
		self.pageDetails:setModInfo(modInfo)
		self:pushDetail(self.pageDetails)
		self.pageDetails:setBreadcrumbs(self:getBreadcrumbs())
	end
end

function ModHubScreen:openDownloads()
	g_gui:showGui("ModHubScreen")
	self:goToPage(self.pageDownloads, true)
end

ModHubScreen.L10N_SYMBOL = {
	HEADER_EXTRA_CONTENT = "modHub_extraContent",
	BUTTON_SHOW_ALL = "button_modHubShowAll",
	BUTTON_SEARCH = "modHub_search",
	HEADER_MOD_HUB = "modHub_title",
	BUTTON_SHOW_CROSSPLAY = "button_modHubShowCrossplay",
	BUTTON_BACK = "button_back"
}
ModHubScreen.TAB_UV = {
	CATEGORIES = {
		0,
		195,
		65,
		65
	},
	DLCS = {
		65,
		195,
		65,
		65
	},
	BEST = {
		130,
		195,
		65,
		65
	},
	MOST_DOWNLOADED = {
		195,
		195,
		65,
		65
	},
	LATEST = {
		260,
		195,
		65,
		65
	},
	CONTEST = {
		325,
		195,
		65,
		65
	},
	RECOMMENDED = {
		390,
		195,
		65,
		65
	},
	DOWNLOADS = {
		455,
		195,
		65,
		65
	},
	UPDATES = {
		520,
		195,
		65,
		65
	},
	INSTALLED = {
		585,
		195,
		65,
		65
	},
	EXTRA_CONTENT = {
		650,
		195,
		65,
		65
	}
}
ModHubScreen.CATEGORY_IMAGE_HEIGHT_WIDTH_RATIO = 1
