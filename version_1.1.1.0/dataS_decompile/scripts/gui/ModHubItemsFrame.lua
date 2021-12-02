ModHubItemsFrame = {}
local ShopItemsFrame_mt = Class(ModHubItemsFrame, TabbedMenuFrameElement)
ModHubItemsFrame.CONTROLS = {
	"headerText",
	"spaceUsageLabel",
	MOD_ATTRIBUTE_SIZE_SPACE = "modAttributeInfoSizeSpace",
	MOD_ATTRIBUTE_NAME = "modAttributeName",
	NO_MODS = "noModsElement",
	MOD_ATTRIBUTE_VERSION = "modAttributeInfoVersion",
	MOD_ATTRIBUTE_BOX = "modAttributeBox",
	MOD_ATTRIBUTE_AUTHOR = "modAttributeInfoAuthor",
	MOD_ATTRIBUTE_PRICE = "modAttributePrice",
	MOD_ATTRIBUTE_RATING_BOX = "modAttributeRatingBox",
	ITEMS_LIST = "itemsList",
	MOD_ATTRIBUTE_PRICE_SPACE = "modAttributeInfoPriceSpace",
	MOD_INFO_BOX = "modInfoBox",
	CATEGORY_LABEL = "categoryLabel",
	NAVIGATION_HEADER = "breadcrumbs",
	MOD_ATTRIBUTE_RATING_SPACE = "modAttributeInfoRatingSpace",
	DISCLAIMER = "disclaimerLabel",
	MOD_ATTRIBUTE_RATING_STAR = "modAttributeRatingStar",
	BASE_CATEGORY_LABEL = "baseCategoryLabel",
	MOD_ATTRIBUTE_FILESIZE = "modAttributeInfoSize"
}
ModHubItemsFrame.NUM_ATTRIBUTES_PER_ROW = ModHubController.MAX_ATTRIBUTES_PER_ROW

local function NO_CALLBACK()
end

function ModHubItemsFrame.new(subclass_mt, modHubController, l10n, isConsoleVersion)
	local self = TabbedMenuFrameElement.new(nil, subclass_mt or ShopItemsFrame_mt)

	self:registerControls(ModHubItemsFrame.CONTROLS)

	self.modHubController = modHubController
	self.l10n = l10n
	self.isConsoleVersion = isConsoleVersion
	self.categoryName = ""
	self.updateModInterval = 1000
	self.updateModTimer = self.updateModInterval
	self.notifyActivatedModItemCallback = NO_CALLBACK
	self.notifySelectedModItemCallback = NO_CALLBACK
	self.notifySearchCallback = NO_CALLBACK
	self.notifyToggleBetaCallback = NO_CALLBACK
	self.setModItems = nil
	self.mods = {}

	return self
end

function ModHubItemsFrame:copyAttributes(src)
	ModHubItemsFrame:superClass().copyAttributes(self, src)

	self.modHubController = src.modHubController
	self.l10n = src.l10n
	self.isConsoleVersion = src.isConsoleVersion
end

function ModHubItemsFrame:onGuiSetupFinished()
	ModHubItemsFrame:superClass().onGuiSetupFinished(self)
	self.itemsList:setDataSource(self)
	self.itemsList:setDelegate(self)
end

function ModHubItemsFrame:initialize()
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.detailsButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(ModHubItemsFrame.L10N_SYMBOL.BUTTON_DETAILS),
		callback = function ()
			self:onButtonDetails()
		end
	}
	self.searchButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = g_i18n:getText(ModHubItemsFrame.L10N_SYMBOL.BUTTON_SEARCH),
		callback = function ()
			self:onButtonSearch()
		end
	}
	self.toggleTopButtonInfo = {
		text = "",
		inputAction = InputAction.MENU_EXTRA_1,
		callback = function ()
			self:onButtonShowToggle()
		end
	}

	if self.l10n:hasText("modHub_authorDisclaimer") then
		self.disclaimerLabel:setText(self.l10n:getText("modHub_abuse") .. " " .. self.l10n:getText("modHub_authorDisclaimer"))
	end
end

function ModHubItemsFrame:onFrameOpen()
	ModHubItemsFrame:superClass().onFrameOpen(self)
	self:updateList()
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.itemsList)
	self:setSoundSuppressed(false)
end

function ModHubItemsFrame:update(dt)
	ModHubItemsFrame:superClass().update(self, dt)

	self.updateModTimer = self.updateModTimer - dt

	if self.updateModTimer <= 0 then
		self:updateDownloadStates()
	end
end

function ModHubItemsFrame:getMenuButtonInfo()
	local buttons = {}

	if #self.mods > 0 then
		table.insert(buttons, self.detailsButtonInfo)
	end

	table.insert(buttons, self.backButtonInfo)

	if self.notifySearchCallback ~= NO_CALLBACK then
		table.insert(buttons, self.searchButtonInfo)
	end

	if self.notifyToggleBetaCallback ~= NO_CALLBACK and self.forcedModItems == nil then
		self.toggleTopButtonInfo.text = self.getBetaToggleText()

		table.insert(buttons, self.toggleTopButtonInfo)
	end

	return buttons
end

function ModHubItemsFrame:setItemClickCallback(itemClickedCallback)
	self.notifyActivatedModItemCallback = itemClickedCallback or NO_CALLBACK
end

function ModHubItemsFrame:setItemSelectCallback(itemSelectedCallback)
	self.notifySelectedModItemCallback = itemSelectedCallback or NO_CALLBACK
end

function ModHubItemsFrame:setSearchCallback(searchCallback)
	self.notifySearchCallback = searchCallback
end

function ModHubItemsFrame:setToggleBetaCallback(callback)
	self.notifyToggleBetaCallback = callback
end

function ModHubItemsFrame:setBetaToggleTextCallback(callback)
	self.getBetaToggleText = callback
end

function ModHubItemsFrame:setCategory(categoryName)
	self.categoryName = categoryName
	self.title = self.modHubController:getCategory(categoryName).label
end

function ModHubItemsFrame:setCategoryId(categoryId)
	self.categoryId = categoryId
end

function ModHubItemsFrame:setModItems(modItems)
	self.forcedModItems = modItems
end

function ModHubItemsFrame:setListSizeLimit(limit)
	self.listSizeLimit = limit
end

function ModHubItemsFrame:setBreadcrumbs(list)
	self.headerText:setText(list[#list])
	self.breadcrumbs:setBreadcrumbs(list)
end

function ModHubItemsFrame:reload()
	self:updateList()
end

function ModHubItemsFrame:updateList()
	if self.forcedModItems ~= nil then
		self.mods = self.forcedModItems
	else
		self.mods = self.modHubController:getModsByCategory(self.categoryId, true)
	end

	self.itemsList:reloadData()
	self.modInfoBox:setVisible(#self.mods > 0)
	self.noModsElement:setVisible(#self.mods == 0)
	self:updateDownloadStates()
	self:setMenuButtonInfoDirty()
end

function ModHubItemsFrame:getMainElementSize()
	return self.modInfoBox.size
end

function ModHubItemsFrame:getMainElementPosition()
	return self.modInfoBox.absPosition
end

function ModHubItemsFrame:updateDownloadStates()
	if #self.itemsList.elements > 0 then
		for i = self.itemsList.elements[1].indexInSection, self.itemsList.elements[#self.itemsList.elements].indexInSection do
			self:updateModDownloadState(i)
		end
	end

	self.updateModTimer = self.updateModInterval
end

function ModHubItemsFrame:updateModDownloadState(index)
	local cell = self.itemsList:getElementAtSectionIndex(1, index)

	if cell == nil then
		return
	end

	local modInfo = self.mods[index]
	local isDownloading = modInfo:getIsDownloading()
	local isInstalled = modInfo:getIsInstalled()
	local isDownload = modInfo:getIsDownload()
	local isFailed = modInfo:getIsFailed()
	local isUpdate = modInfo:getIsUpdate()

	cell:getAttribute("statusBox"):setVisible(isDownloading or isInstalled or isDownload or isFailed or isUpdate)

	local percent = 0

	if isDownloading or isDownload then
		local downloaded = modInfo:getDownloadedBytes()
		local fileSize = modInfo:getFilesize()
		percent = MathUtil.clamp(downloaded / fileSize, 0, 1)
	elseif isInstalled then
		percent = 1
	end

	local statusBar = cell:getAttribute("statusBar")

	statusBar:setSize(statusBar.parent.absSize[1] * percent, nil)

	local text = ""

	if isDownloading or isDownload and percent == 1 then
		text = string.format("%.0f %%", percent * 100)
	elseif isDownload then
		text = self.l10n:getText(ModHubItemsFrame.L10N_SYMBOL.STATUS_PENDING)
	elseif isUpdate then
		text = self.l10n:getText(ModHubItemsFrame.L10N_SYMBOL.STATUS_UPDATE)
	elseif isInstalled then
		text = self.l10n:getText(ModHubItemsFrame.L10N_SYMBOL.STATUS_INSTALLED)
	elseif isFailed then
		text = self.l10n:getText(ModHubItemsFrame.L10N_SYMBOL.STATUS_FAILED)
	end

	cell:getAttribute("statusLabel"):setText(text)
end

function ModHubItemsFrame:onActivateItem(_, clickedElement)
	local modInfo = self.mods[self.itemsList.selectedIndex]

	self:notifyActivatedModItemCallback(modInfo.modId, self.categoryName)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
end

function ModHubItemsFrame:onButtonDetails()
	self:onActivateItem()
end

function ModHubItemsFrame:onClickLeft()
	self.itemsList:scrollTo(self.itemsList.firstVisibleItem - self.itemsList.itemsPerCol)
end

function ModHubItemsFrame:onClickRight()
	self.itemsList:scrollTo(self.itemsList.firstVisibleItem + self.itemsList.itemsPerCol)
end

function ModHubItemsFrame:onListSelectionChanged(list, section, index)
	local modItem = self.mods[index]

	if modItem ~= nil then
		self:notifySelectedModItemCallback(modItem.modId)
	end

	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end

function ModHubItemsFrame:setModInfo(modInfo)
	self.modAttributeName:setText(modInfo:getName(), true)
	self.modAttributeInfoAuthor:setText(modInfo:getAuthor(), true)
	self.modAttributeInfoVersion:setText(modInfo:getVersionString(), true)

	local isDLC = modInfo:getIsDLC()
	local isTop = modInfo:getIsTop()
	local priceVisible = nil

	if not isDLC then
		local size = modInfo:getFilesize() / 1024 / 1024

		self.modAttributeInfoSize:setText(string.format("%.02f MB", size), true)

		local ratingScore = modInfo:getRatingScore() / 100

		for i = 1, 5 do
			self.modAttributeRatingStar[i].elements[1]:setVisible(ratingScore >= i - 0.75 and ratingScore < i - 0.25)

			if ratingScore >= i - 0.25 then
				self.modAttributeRatingStar[i]:applyProfile(ModHubItemsFrame.PROFILE.RATING_STAR_ACTIVE)
			else
				self.modAttributeRatingStar[i]:applyProfile(ModHubItemsFrame.PROFILE.RATING_STAR)
			end
		end

		self.modAttributePrice:setText(self.l10n:getText("modHub_flag_highEnd"), true)

		priceVisible = isTop
	else
		local priceString = modInfo:getPriceString()

		self.modAttributePrice:setText(priceString, true)

		priceVisible = priceString:len() > 1
	end

	self.modAttributeInfoSize:setVisible(not isDLC)
	self.modAttributeInfoSizeSpace:setVisible(not isDLC)
	self.modAttributeRatingBox:setVisible(not isDLC)
	self.modAttributeInfoRatingSpace:setVisible(not isDLC)
	self.modAttributePrice:setVisible(priceVisible)
	self.modAttributeInfoPriceSpace:setVisible(priceVisible)
	self.modAttributeBox:invalidateLayout()
end

function ModHubItemsFrame:onButtonSearch()
	self.notifySearchCallback(self.categoryId)
end

function ModHubItemsFrame:onButtonShowToggle()
	self:notifyToggleBetaCallback()
end

function ModHubItemsFrame:getNumberOfItemsInSection(list, section)
	local total = #self.mods

	if self.listSizeLimit ~= nil then
		return math.min(total, self.listSizeLimit)
	end

	return total
end

function ModHubItemsFrame:populateCellForItemInSection(list, section, index, cell)
	local modInfo = self.mods[index]
	local numUpdates = modInfo:getNumUpdates()
	local numNew = modInfo:getNumNew()
	local numConflicts = modInfo:getNumConflicts()
	local markerElement = cell:getAttribute("marker")

	markerElement:setVisible(numUpdates > 0 or numNew > 0 or numConflicts > 0)

	if numConflicts > 0 then
		markerElement:applyProfile("modHubMarkerConflict")
	elseif numUpdates > 0 then
		markerElement:applyProfile("modHubMarkerUpdate")
	elseif numNew > 0 then
		markerElement:applyProfile("modHubMarkerNew")
	end

	local iconElement = cell:getAttribute("icon")

	iconElement:setIsWebOverlay(not modInfo:getIsIconLocal())
	iconElement:setImageFilename(modInfo:getIconFilename())
	cell:getAttribute("nameLabel"):setText(modInfo:getName())
end

ModHubItemsFrame.PROFILE = {
	LIST_ITEM_SELECTED = "modHubItemsListItemSelected",
	LIST_ITEM_NEUTRAL = "modHubItemsListItem",
	RATING_STAR_ACTIVE = "modHubAttributeRatingStarActive",
	RATING_STAR = "modHubAttributeRatingStar"
}
ModHubItemsFrame.L10N_SYMBOL = {
	STATUS_PENDING = "modHub_pending",
	BUTTON_DETAILS = "button_detail",
	STATUS_UPDATE = "modHub_update",
	BUTTON_SEARCH = "modHub_search",
	STATUS_INSTALLED = "modHub_installed",
	BUTTON_SHOW_ALL = "button_modHubShowAll",
	BUTTON_SHOW_TOP = "button_modHubShowTop",
	STATUS_FAILED = "modHub_failed"
}
