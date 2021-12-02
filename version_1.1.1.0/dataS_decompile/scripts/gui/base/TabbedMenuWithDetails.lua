TabbedMenuWithDetails = {}
local TabbedMenuWithDetails_mt = Class(TabbedMenuWithDetails, TabbedMenu)

function TabbedMenuWithDetails.new(target, customMt, messageCenter, l10n, inputManager)
	local self = TabbedMenu.new(target, customMt or TabbedMenuWithDetails_mt, messageCenter, l10n, inputManager)
	self.stacks = {}

	return self
end

function TabbedMenuWithDetails:reset()
	TabbedMenuWithDetails:superClass().reset(self)

	self.stacks = {}
end

function TabbedMenuWithDetails:getIsDetailMode()
	return not self:isAtRoot()
end

function TabbedMenuWithDetails:exitMenu()
	self:popToRoot()
	TabbedMenuWithDetails:superClass().exitMenu(self)
end

function TabbedMenuWithDetails:onOpen(element)
	TabbedMenu:superClass().onOpen(self)

	if self.performBackgroundBlur then
		g_depthOfFieldManager:pushArea(0, 0, 1, 1)
	end

	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.PAGING)

	if self.gameState ~= nil then
		g_gameStateManager:setGameState(self.gameState)
	end

	self:setSoundSuppressed(true)

	local top = self:getTopFrame()

	if self:isAtRoot() then
		self:updatePages()
		self.pageSelector:setState(self.restorePageIndex, true)
	else
		top:onFrameOpen()
		self:updateButtonsPanel(top)
	end

	self:setSoundSuppressed(false)
	self:onMenuOpened()
end

function TabbedMenuWithDetails:onPageClicked(oldPage)
	self:popToRoot()
end

function TabbedMenuWithDetails:onDetailClosed(detailPage)
end

function TabbedMenuWithDetails:onDetailOpened(detailPage)
end

function TabbedMenuWithDetails:onButtonBack()
	if self:isAtRoot() then
		self:exitMenu()
	else
		self:popDetail()
	end
end

function TabbedMenuWithDetails:onPageChange(pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
	if self.isChangingDetail then
		skipTabVisualUpdate = true
	else
		self:popToRoot()
	end

	TabbedMenuWithDetails:superClass().onPageChange(self, pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
end

function TabbedMenuWithDetails:getStack(page)
	local pageId = self.currentPageId

	if page ~= nil then
		pageId = self.pagingElement:getPageIndexByElement(page)
	else
		page = self.pagingElement:getPageElementByIndex(pageId)
	end

	if self.stacks[pageId] == nil then
		self.stacks[pageId] = {}
		local root = {
			isRoot = true,
			page = page,
			pageId = pageId
		}

		table.insert(self.stacks[pageId], root)
	end

	return self.stacks[pageId]
end

function TabbedMenuWithDetails:isAtRoot()
	return #self:getStack() == 1
end

function TabbedMenuWithDetails:getTopFrame()
	local stack = self:getStack()

	return stack[#stack].page
end

function TabbedMenuWithDetails:setPageDisabled(page, disabled)
	local pageId = self.pagingElement:getPageIdByElement(page)

	self.pagingElement:setPageIdDisabled(pageId, disabled)
end

function TabbedMenuWithDetails:pushDetail(detailPage)
	local stack = self:getStack()
	self.isChangingDetail = true

	if not self:isAtRoot() then
		local closingPage = stack[#stack].page

		detailPage:setVisible(false)
		detailPage:onFrameClose()
		self:setPageDisabled(detailPage, true)
		self:onDetailClosed(closingPage)
	end

	local context = {
		page = detailPage
	}

	table.insert(stack, context)
	self:setPageDisabled(detailPage, false)
	detailPage:setSoundSuppressed(true)
	self.pagingElement:setPage(self.pagingElement:getPageMappingIndexByElement(detailPage))
	detailPage:setSoundSuppressed(false)
	self:onDetailOpened(detailPage)

	self.isChangingDetail = false
end

function TabbedMenuWithDetails:popDetail()
	local stack = self:getStack()
	self.isChangingDetail = true

	if #stack == 1 then
		Logging.error("Cannot pop from view stack at root")

		return
	end

	local closingPage = stack[#stack].page

	table.remove(stack)
	closingPage:setVisible(false)
	closingPage:onFrameClose()

	self.pagingElement.neuterPageUpdates = true

	self:setPageDisabled(closingPage, true)
	self:onDetailClosed(closingPage)

	self.pagingElement.neuterPageUpdates = false

	if #stack ~= 1 then
		local detailPage = stack[#stack].page

		detailPage:onFrameOpen()
		self:setPageDisabled(detailPage, false)
		detailPage:setSoundSuppressed(true)
		self.pagingElement:setPage(self.pagingElement:getPageMappingIndexByElement(detailPage))
		detailPage:setSoundSuppressed(false)
		self:onDetailOpened(detailPage)
	else
		self.pagingElement:setPage(self.pagingElement:getPageMappingIndexByElement(stack[1].page))
	end

	self.isChangingDetail = false
end

function TabbedMenuWithDetails:popToRoot()
	local stack = self:getStack()

	if #stack > 1 then
		for _ = #stack, 2, -1 do
			self:popDetail()
		end
	end
end

function TabbedMenuWithDetails:replaceDetail(detailPage)
	self:popDetail()
	self:pushDetail(detailPage)
end

function TabbedMenuWithDetails:getBreadcrumbs(page)
	local list = {}

	for _, item in ipairs(self:getStack(page)) do
		table.insert(list, item.page.title or "")
	end

	return list
end
