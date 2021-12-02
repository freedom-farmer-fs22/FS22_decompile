TabbedMenu = {}
local TabbedMenu_mt = Class(TabbedMenu, ScreenElement)
TabbedMenu.PAGE_TAB_TEMPLATE_BUTTON_NAME = "tabButton"
TabbedMenu.CONTROLS = {
	"pagingTabPrevious",
	"pagingTabNext",
	MENU_BUTTONS = "menuButton",
	PAGING_BUTTON_RIGHT = "pagingButtonRight",
	PAGING_BUTTON_LEFT = "pagingButtonLeft",
	PAGING_TAB_TEMPLATE = "pagingTabTemplate",
	HEADER = "header",
	PAGING_ELEMENT = "pagingElement",
	BUTTONS_PANEL = "buttonsPanel",
	PAGING_TAB_LIST = "pagingTabList"
}
TabbedMenu.NO_BUTTON_INFO = {}
TabbedMenu.DEFAULT_BUTTON_ACTIONS = {
	[InputAction.MENU_ACCEPT] = true,
	[InputAction.MENU_ACTIVATE] = true,
	[InputAction.MENU_CANCEL] = true,
	[InputAction.MENU_BACK] = true,
	[InputAction.MENU_EXTRA_1] = true,
	[InputAction.MENU_EXTRA_2] = true
}
TabbedMenu.MONEY_UPDATE_INTERVAL = 300

local function NO_CALLBACK()
end

function TabbedMenu.new(target, customMt, messageCenter, l10n, inputManager)
	local self = ScreenElement.new(target, customMt or TabbedMenu_mt)

	self:registerControls(TabbedMenu.CONTROLS)

	self.messageCenter = messageCenter
	self.l10n = l10n
	self.inputManager = inputManager
	self.pageFrames = {}
	self.pageTabs = {}
	self.pageTypeControllers = {}
	self.pageRoots = {}
	self.pageEnablingPredicates = {}
	self.disabledPages = {}
	self.pageToTabIndex = {}
	self.currentPageId = 1
	self.currentPageName = ""
	self.currentPage = nil
	self.restorePageIndex = 1
	self.restorePageScrollIndex = 1
	self.buttonActionCallbacks = {}
	self.defaultButtonActionCallbacks = {}
	self.defaultMenuButtonInfoByActions = {}
	self.customButtonEvents = {}
	self.clickBackCallback = NO_CALLBACK
	self.frameClosePageNextCallback = self:makeSelfCallback(self.onPageNext)
	self.frameClosePagePreviousCallback = self:makeSelfCallback(self.onPagePrevious)
	self.performBackgroundBlur = false

	return self
end

function TabbedMenu:delete()
	self.messageCenter:unsubscribeAll(self)
	self.pagingTabTemplate:delete()

	for _, tab in pairs(self.pageTabs) do
		tab:delete()
	end

	TabbedMenu:superClass().delete(self)
end

function TabbedMenu:onGuiSetupFinished()
	TabbedMenu:superClass().onGuiSetupFinished(self)

	self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)

	self.pagingTabTemplate:unlinkElement()
	self:setupMenuButtonInfo()
	self.header.parent:addElement(self.header)

	if self.pagingElement.profile == "uiInGameMenuPaging" then
		self.pagingElement:setSize(1 - self.header.absSize[1])
	end
end

function TabbedMenu:exitMenu()
	self:changeScreen(nil)
end

function TabbedMenu:reset()
	TabbedMenu:superClass().reset(self)

	self.currentPageId = 1
	self.currentPageName = ""
	self.currentPage = nil
	self.restorePageIndex = 1
	self.restorePageScrollIndex = 1
end

function TabbedMenu:onOpen(element)
	TabbedMenu:superClass().onOpen(self)

	if self.performBackgroundBlur then
		g_depthOfFieldManager:pushArea(0, 0, 1, 1)
	end

	if not self.muteSound then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.PAGING)
	end

	if self.gameState ~= nil then
		g_gameStateManager:setGameState(self.gameState)
	end

	self:setSoundSuppressed(true)
	self:updatePages()

	if self.restorePageIndex ~= nil then
		self.pageSelector:setState(self.restorePageIndex, true)
		self.pagingTabList:scrollTo(self.restorePageScrollIndex)
	end

	self:setSoundSuppressed(false)
	self:onMenuOpened()
end

function TabbedMenu:onClose(element)
	if self.currentPage ~= nil then
		self.currentPage:onFrameClose()
	end

	TabbedMenu:superClass().onClose(self)

	if self.performBackgroundBlur then
		g_depthOfFieldManager:popArea()
	end

	self.inputManager:storeEventBindings()
	self:clearMenuButtonActions()

	self.restorePageIndex = self.pageSelector:getState()
	self.restorePageScrollIndex = self.pagingTabList.firstVisibleItem

	if self.gameState ~= nil then
		g_currentMission:resetGameState()
	end
end

function TabbedMenu:update(dt)
	TabbedMenu:superClass().update(self, dt)

	if FocusManager.currentGui ~= self.currentPageName and not g_gui:getIsDialogVisible() then
		FocusManager:setGui(self.currentPageName)
	end

	if self.currentPage ~= nil then
		if self.currentPage:isMenuButtonInfoDirty() then
			self:assignMenuButtonInfo(self.currentPage:getMenuButtonInfo())
			self.currentPage:clearMenuButtonInfoDirty()
		end

		if self.currentPage:isTabbingMenuVisibleDirty() then
			self:updatePagingVisibility(self.currentPage:getTabbingMenuVisible())
		end
	end
end

function TabbedMenu:setupMenuButtonInfo()
end

function TabbedMenu:addPageTab(frameController, iconFilename, iconUVs)
	local tab = self.pagingTabTemplate:clone()

	tab:fadeIn()
	self.pagingTabList:addElement(tab)

	self.pageTabs[frameController] = tab
	local tabButton = tab:getDescendantByName(TabbedMenu.PAGE_TAB_TEMPLATE_BUTTON_NAME)

	tabButton:setImageFilename(nil, iconFilename)
	tabButton:setImageUVs(nil, iconUVs)

	function tabButton.onClickCallback()
		self:onPageClicked(self.activeDetailPage)

		local pageId = self.pagingElement:getPageIdByElement(frameController)
		local pageMappingIndex = self.pagingElement:getPageMappingIndex(pageId)

		self.pageSelector:setState(pageMappingIndex, true)
	end
end

function TabbedMenu:onPageClicked(oldPage)
end

function TabbedMenu:setPageTabEnabled(pageController, isEnabled)
	local tab = self.pageTabs[pageController]

	tab:setDisabled(not isEnabled)
	tab:setVisible(isEnabled)
end

function TabbedMenu:rebuildTabList()
	self.pageToTabIndex = {}

	for i = #self.pagingTabList.listItems, 1, -1 do
		local tab = self.pagingTabList.listItems[i]

		self.pagingTabList:removeElement(tab)
	end

	for i, page in ipairs(self.pageFrames) do
		local tab = self.pageTabs[page]
		local pageId = self.pagingElement:getPageIdByElement(page)
		local enabled = not self.pagingElement:getIsPageDisabled(pageId)

		if enabled then
			self.pagingTabList:addElement(tab)

			self.pageToTabIndex[i] = #self.pagingTabList.listItems
		end
	end

	self.pagingTabList.firstVisibleItem = 1
	local listIndex = self.pageToTabIndex[self.currentPageId]

	if listIndex ~= nil then
		local direction = 0

		self.pagingTabList:setSelectedIndex(listIndex, true, direction)
	end
end

function TabbedMenu:updatePages()
	for pageElement, predicate in pairs(self.pageEnablingPredicates) do
		local pageId = self.pagingElement:getPageIdByElement(pageElement)
		local enable = self.disabledPages[pageElement] == nil and predicate()

		self.pagingElement:setPageIdDisabled(pageId, not enable)
		self:setPageTabEnabled(pageElement, enable)
	end

	self:rebuildTabList()
	self:updatePageTabDisplay()
	self:setPageSelectorTitles()
	self:updatePageControlVisibility()
end

function TabbedMenu:updatePageTabDisplay()
end

function TabbedMenu:updatePageControlVisibility()
	local showButtons = #self.pagingTabList.listItems ~= 1

	self.pagingButtonLeft:setVisible(showButtons)
	self.pagingButtonRight:setVisible(showButtons)
end

function TabbedMenu:clearMenuButtonActions()
	for k in pairs(self.buttonActionCallbacks) do
		self.buttonActionCallbacks[k] = nil
	end

	for i in ipairs(self.customButtonEvents) do
		self.inputManager:removeActionEvent(self.customButtonEvents[i])

		self.customButtonEvents[i] = nil
	end
end

function TabbedMenu:assignMenuButtonInfo(menuButtonInfo)
	self:clearMenuButtonActions()

	for i, button in ipairs(self.menuButton) do
		local info = menuButtonInfo[i]
		local hasInfo = info ~= nil

		button:setVisible(hasInfo)

		if hasInfo and info.inputAction ~= nil and InputAction[info.inputAction] ~= nil then
			button:setInputAction(info.inputAction)

			local buttonText = info.text

			if buttonText == nil and self.defaultMenuButtonInfoByActions[info.inputAction] ~= nil then
				buttonText = self.defaultMenuButtonInfoByActions[info.inputAction].text
			end

			button:setText(buttonText)

			local buttonClickCallback = info.callback or self.defaultButtonActionCallbacks[info.inputAction] or NO_CALLBACK
			local sound = GuiSoundPlayer.SOUND_SAMPLES.CLICK

			if info.inputAction == InputAction.MENU_BACK then
				sound = GuiSoundPlayer.SOUND_SAMPLES.BACK
			end

			if info.clickSound ~= nil and info.clickSound ~= sound then
				sound = info.clickSound
				local oldButtonClickCallback = buttonClickCallback

				function buttonClickCallback(...)
					self:playSample(sound)
					self:setNextScreenClickSoundMuted()

					return oldButtonClickCallback(...)
				end

				button:setClickSound(GuiSoundPlayer.SOUND_SAMPLES.NONE)
			else
				button:setClickSound(sound)
			end

			local showForGameState = GS_IS_MOBILE_VERSION or not self.paused or info.showWhenPaused
			local showForCurrentState = showForGameState or info.inputAction == InputAction.MENU_BACK
			local disabled = info.disabled or not showForCurrentState

			if not disabled then
				if not TabbedMenu.DEFAULT_BUTTON_ACTIONS[info.inputAction] then
					local _, eventId = self.inputManager:registerActionEvent(info.inputAction, InputBinding.NO_EVENT_TARGET, buttonClickCallback, false, true, false, true)

					table.insert(self.customButtonEvents, eventId)
				else
					self.buttonActionCallbacks[info.inputAction] = buttonClickCallback
				end
			end

			button.onClickCallback = buttonClickCallback

			button:setDisabled(disabled)
		end
	end

	if self.buttonActionCallbacks[InputAction.MENU_BACK] == nil then
		self.buttonActionCallbacks[InputAction.MENU_BACK] = self.clickBackCallback
	end

	self.buttonsPanel:invalidateLayout()
end

function TabbedMenu:setPageSelectorTitles()
	local texts = self.pagingElement:getPageTitles()

	self.pageSelector:setTexts(texts)
	self.pageSelector:setDisabled(#texts == 1)

	local id = self.pagingElement:getCurrentPageId()
	self.pageSelector.state = self.pagingElement:getPageMappingIndex(id)
end

function TabbedMenu:goToPage(page, muteSound)
	local oldMute = self.muteSound
	self.muteSound = muteSound
	local index = self.pagingElement:getPageMappingIndexByElement(page)

	if index ~= nil then
		self.pageSelector:setState(index, true)
	end

	self.muteSound = oldMute
end

function TabbedMenu:updatePagingVisibility(visible)
	self.header:setVisible(visible)
end

function TabbedMenu:onMenuActionClick(menuActionName)
	local buttonCallback = self.buttonActionCallbacks[menuActionName]

	if buttonCallback ~= nil and buttonCallback ~= NO_CALLBACK then
		return buttonCallback() or false
	end

	return true
end

function TabbedMenu:onClickOk()
	local eventUnused = self:onMenuActionClick(InputAction.MENU_ACCEPT)

	return eventUnused
end

function TabbedMenu:onClickBack()
	local eventUnused = true

	if self.currentPage:requestClose(self.clickBackCallback) then
		eventUnused = TabbedMenu:superClass().onClickBack(self)
		eventUnused = eventUnused and self:onMenuActionClick(InputAction.MENU_BACK)
	end

	return eventUnused
end

function TabbedMenu:onClickCancel()
	local eventUnused = TabbedMenu:superClass().onClickCancel(self)
	eventUnused = eventUnused and self:onMenuActionClick(InputAction.MENU_CANCEL)

	return eventUnused
end

function TabbedMenu:onClickActivate()
	local eventUnused = TabbedMenu:superClass().onClickActivate(self)
	eventUnused = eventUnused and self:onMenuActionClick(InputAction.MENU_ACTIVATE)

	return eventUnused
end

function TabbedMenu:onClickMenuExtra1()
	local eventUnused = TabbedMenu:superClass().onClickMenuExtra1(self)
	eventUnused = eventUnused and self:onMenuActionClick(InputAction.MENU_EXTRA_1)

	return eventUnused
end

function TabbedMenu:onClickMenuExtra2()
	local eventUnused = TabbedMenu:superClass().onClickMenuExtra2(self)
	eventUnused = eventUnused and self:onMenuActionClick(InputAction.MENU_EXTRA_2)

	return eventUnused
end

function TabbedMenu:onClickPageSelection(state)
	if self.pagingElement:setPage(state) and not self.muteSound then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.PAGING)
	end
end

function TabbedMenu:onPagePrevious()
	if GS_IS_MOBILE_VERSION then
		if self.currentPage:getHasPreviousPage() then
			self.currentPage:onPreviousPage()
		end
	elseif self.currentPage:requestClose(self.frameClosePagePreviousCallback) then
		TabbedMenu:superClass().onPagePrevious(self)
	end
end

function TabbedMenu:onPageNext()
	if GS_IS_MOBILE_VERSION then
		if self.currentPage:getHasNextPage() then
			self.currentPage:onNextPage()
		end
	elseif self.currentPage:requestClose(self.frameClosePageNextCallback) then
		TabbedMenu:superClass().onPageNext(self)
	end
end

function TabbedMenu:onPageChange(pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
	local prevPage = self.pagingElement:getPageElementByIndex(self.currentPageId)

	prevPage:onFrameClose()
	prevPage:setVisible(false)
	self.inputManager:storeEventBindings()

	local page = self.pagingElement:getPageElementByIndex(pageIndex)
	self.currentPage = page
	self.currentPageName = page.name

	if not skipTabVisualUpdate then
		local oldIndex = self.pageToTabIndex[self.currentPageId]
		self.currentPageId = pageIndex
		local listIndex = self.pageToTabIndex[pageIndex]

		if listIndex ~= nil then
			local direction = MathUtil.sign(listIndex - oldIndex)

			self.pagingTabList:setSelectedIndex(listIndex, true, direction)
		end
	end

	page:setVisible(true)
	page:setSoundSuppressed(true)
	FocusManager:setGui(page.name)
	page:setSoundSuppressed(false)
	page:onFrameOpen()
	self:updateButtonsPanel(page)
	self:updateTabDisplay()
end

function TabbedMenu:onTabMenuSelectionChanged()
end

function TabbedMenu:onTabMenuScroll()
	self:updateTabDisplay()
end

function TabbedMenu:updateButtonsPanel(page)
	local buttonInfo = self:getPageButtonInfo(page)

	self:assignMenuButtonInfo(buttonInfo)
end

function TabbedMenu:updateTabDisplay()
	if self.pagingTabPrevious ~= nil then
		local isFirstItemVisible = self.pagingTabList.firstVisibleItem == 1

		self.pagingTabPrevious:setVisible(not isFirstItemVisible)

		if not isFirstItemVisible then
			local itemToShow = self.pagingTabList.firstVisibleItem - 1
			local prevElement = self.pagingTabList.listItems[itemToShow].elements[1]

			self.pagingTabPrevious.elements[1]:setImageUVs(GuiOverlay.STATE_NORMAL, unpack(prevElement.icon.uvs))
		end
	end

	if self.pagingTabPrevious ~= nil then
		local isLastItemVisible = self.pagingTabList.firstVisibleItem + self.pagingTabList.visibleItems - 1 >= #self.pagingTabList.listItems

		self.pagingTabNext:setVisible(not isLastItemVisible)

		if not isLastItemVisible then
			local itemToShow = self.pagingTabList.firstVisibleItem + self.pagingTabList.visibleItems
			local nextElement = self.pagingTabList.listItems[itemToShow].elements[1]

			self.pagingTabNext.elements[1]:setImageUVs(GuiOverlay.STATE_NORMAL, unpack(nextElement.icon.uvs))
		end
	end
end

function TabbedMenu:getPageButtonInfo(page)
	local buttonInfo = nil

	if page:getHasCustomMenuButtons() then
		buttonInfo = page:getMenuButtonInfo()
	else
		buttonInfo = self.defaultMenuButtonInfo
	end

	return buttonInfo
end

function TabbedMenu:onPageUpdate()
end

function TabbedMenu:onButtonBack()
	self:exitMenu()
end

function TabbedMenu:onMenuOpened()
end

function TabbedMenu:onTabPagingPrevious()
	local index = self.pagingTabList.firstVisibleItem - 1

	self.pageSelector:setState(index, true)
end

function TabbedMenu:onTabPagingNext()
	local index = self.pagingTabList.firstVisibleItem + self.pagingTabList.visibleItems

	self.pageSelector:setState(index, true)
end

function TabbedMenu:registerPage(pageFrameElement, position, enablingPredicateFunction)
	if position == nil then
		position = #self.pageFrames + 1
	else
		position = math.max(1, math.min(#self.pageFrames + 1, position))
	end

	table.insert(self.pageFrames, position, pageFrameElement)

	self.pageTypeControllers[pageFrameElement:class()] = pageFrameElement
	local pageRoot = pageFrameElement:getFirstDescendant()
	self.pageRoots[pageFrameElement] = pageRoot
	self.pageEnablingPredicates[pageFrameElement] = enablingPredicateFunction

	pageFrameElement:setVisible(false)

	return pageRoot, position
end

function TabbedMenu:unregisterPage(pageFrameClass)
	local pageController = self.pageTypeControllers[pageFrameClass]
	local pageTab, pageRoot = nil

	if pageController ~= nil then
		local pageRemoveIndex = -1

		for i, page in ipairs(self.pageFrames) do
			if page == pageController then
				pageRemoveIndex = i

				break
			end
		end

		table.remove(self.pageFrames, pageRemoveIndex)

		pageRoot = self.pageRoots[pageController]
		self.pageRoots[pageController] = nil
		self.pageTypeControllers[pageFrameClass] = nil
		self.pageEnablingPredicates[pageController] = nil
		self.pageTabs[pageController] = nil
	end

	return pageController ~= nil, pageController, pageRoot, pageTab
end

function TabbedMenu:addPage(pageFrameElement, position, tabIconFilename, tabIconUVs, enablingPredicateFunction)
	local pageRoot, actualPosition = self:registerPage(pageFrameElement, position, enablingPredicateFunction)

	self:addPageTab(pageFrameElement, tabIconFilename, GuiUtils.getUVs(tabIconUVs))

	local name = pageRoot.title

	if name == nil then
		name = self.l10n:getText("ui_" .. pageRoot.name)
	end

	self.pagingElement:addPage(string.upper(pageRoot.name), pageRoot, name, actualPosition)
end

function TabbedMenu:removePage(pageFrameClass)
	local defaultPage = self.pageTypeControllers[pageFrameClass]

	if self.defaultPageElementIDs[defaultPage] ~= nil then
		self:setPageEnabled(pageFrameClass, false)
	else
		local needDelete, pageController, pageRoot, pageTab = self:unregisterPage(pageFrameClass)

		if needDelete then
			self.pagingElement:removeElement(pageRoot)
			pageRoot:delete()
			pageController:delete()
			self.pagingTabList:removeElement(pageTab)
			pageTab:delete()
		end
	end
end

function TabbedMenu:setPageEnabled(pageFrameClass, isEnabled)
	local pageController = self.pageTypeControllers[pageFrameClass]

	if pageController ~= nil then
		local pageId = self.pagingElement:getPageIdByElement(pageController)

		self.pagingElement:setPageIdDisabled(pageId, not isEnabled)
		pageController:setDisabled(not isEnabled)

		if not isEnabled then
			self.disabledPages[pageController] = pageController
		else
			self.disabledPages[pageController] = nil
		end

		self:setPageTabEnabled(pageController, isEnabled)
		self.pagingTabList:updateItemPositions()
	end
end

function TabbedMenu:makeSelfCallback(func)
	return function (...)
		return func(self, ...)
	end
end

TabbedMenu.PROFILE = {
	PAGE_TAB_ACTIVE = "uiTabbedMenuPageTabActive",
	PAGE_TAB = "uiTabbedMenuPageTab"
}
