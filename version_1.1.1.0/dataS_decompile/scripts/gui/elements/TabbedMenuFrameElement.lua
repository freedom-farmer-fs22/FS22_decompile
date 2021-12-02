TabbedMenuFrameElement = {}
local TabbedMenuFrameElement_mt = Class(TabbedMenuFrameElement, FrameElement)

local function NO_CALLBACK()
end

TabbedMenuFrameElement.CONTROLS = {
	PAGING_TITLE = "pagingTitle",
	SUB_PAGING_BUTTON_RIGHT = "subPagingButtonRight",
	SUB_PAGE_SELECTOR = "subPageSelector",
	SUB_PAGING_BUTTON_LEFT = "subPagingButtonLeft",
	PAGE_HEADER = "pageHeader",
	PAGING_INDEX_STATE = "pagingIndexState"
}

function TabbedMenuFrameElement.new(target, customMt)
	local self = FrameElement.new(target, customMt or TabbedMenuFrameElement_mt)

	self:registerControls(TabbedMenuFrameElement.CONTROLS)

	self.hasCustomMenuButtons = false
	self.menuButtonInfo = {}
	self.menuButtonsDirty = false
	self.title = nil
	self.tabbingMenuVisibleDirty = false
	self.tabbingMenuVisible = true
	self.currentPage = 1

	self:setNumberOfPages(1)

	self.requestCloseCallback = NO_CALLBACK

	return self
end

function TabbedMenuFrameElement:initialize(...)
end

function TabbedMenuFrameElement:getHasCustomMenuButtons()
	return self.hasCustomMenuButtons
end

function TabbedMenuFrameElement:getMenuButtonInfo()
	return self.menuButtonInfo
end

function TabbedMenuFrameElement:setMenuButtonInfo(menuButtonInfo)
	self.menuButtonInfo = menuButtonInfo
	self.hasCustomMenuButtons = menuButtonInfo ~= nil
end

function TabbedMenuFrameElement:setMenuButtonInfoDirty()
	self.menuButtonsDirty = true
end

function TabbedMenuFrameElement:isMenuButtonInfoDirty()
	return self.menuButtonsDirty
end

function TabbedMenuFrameElement:clearMenuButtonInfoDirty()
	self.menuButtonsDirty = false
end

function TabbedMenuFrameElement:getMainElementSize()
	return {
		1,
		1
	}
end

function TabbedMenuFrameElement:getMainElementPosition()
	return {
		0,
		0
	}
end

function TabbedMenuFrameElement:requestClose(callback)
	self.requestCloseCallback = callback or NO_CALLBACK

	return true
end

function TabbedMenuFrameElement:onFrameOpen()
	self:updatePagingButtons()

	if GS_IS_MOBILE_VERSION and self.subPageSelector ~= nil and self.numberOfPages > 1 then
		self:onPageChanged(self.currentPage, self.currentPage)
	end
end

function TabbedMenuFrameElement:onFrameClose()
end

function TabbedMenuFrameElement:setTitle(title)
	self.title = title

	if self.pagingTitle ~= nil then
		self.pagingTitle:setText(title)
	end
end

function TabbedMenuFrameElement:getTitle()
	return self.title
end

function TabbedMenuFrameElement:setTabbingMenuVisible(visible)
	self.tabbingMenuVisible = visible
	self.tabbingMenuVisibleDirty = true
end

function TabbedMenuFrameElement:getTabbingMenuVisible()
	return self.tabbingMenuVisible and not GS_IS_MOBILE_VERSION
end

function TabbedMenuFrameElement:isTabbingMenuVisibleDirty()
	return self.tabbingMenuVisibleDirty
end

function TabbedMenuFrameElement:onNextPage()
	if self.currentPage < self.numberOfPages then
		self.currentPage = self.currentPage + 1

		self:onPageChanged(self.currentPage, self.currentPage - 1)
	end
end

function TabbedMenuFrameElement:onPreviousPage()
	if self.currentPage > 1 then
		self.currentPage = self.currentPage - 1

		self:onPageChanged(self.currentPage, self.currentPage + 1)
	end
end

function TabbedMenuFrameElement:getHasNextPage()
	return self.currentPage < self.numberOfPages
end

function TabbedMenuFrameElement:getHasPreviousPage()
	return self.currentPage > 1
end

function TabbedMenuFrameElement:onClickSubPageSelection(element)
	local oldPage = self.currentPage

	if element == self.subPagingButtonLeft then
		self.currentPage = self.currentPage - 1
	elseif element == self.subPagingButtonRight then
		self.currentPage = self.currentPage + 1
	end

	self.currentPage = math.max(math.min(self.currentPage, self.numberOfPages), 1)

	if oldPage ~= self.currentPage then
		self:onPageChanged(self.currentPage, oldPage)
	end
end

function TabbedMenuFrameElement:setNumberOfPages(num)
	self.numberOfPages = math.max(num, 1)
	local oldPage = self.currentPage
	self.currentPage = math.max(math.min(self.currentPage, num), 1)

	if self.pagingIndexState ~= nil then
		self.pagingIndexState:setPageCount(self.numberOfPages, self.currentPage)
	end

	if oldPage ~= self.currentPage then
		self:onPageChanged(self.currentPage, self.currentPage)
	else
		self:updatePagingButtons()
	end
end

function TabbedMenuFrameElement:onPageChanged(page, pageFrom)
	if self.pagingIndexState ~= nil then
		self.pagingIndexState:setPageIndex(page)
	end

	self:updatePagingButtons()
end

function TabbedMenuFrameElement:updatePagingButtons()
	if self.subPagingButtonLeft ~= nil then
		local showButtons = self.numberOfPages ~= 1 and not self.pagingButtonsDisabled

		self.subPagingButtonLeft:setDisabled(not showButtons or self.currentPage == 1)
		self.subPagingButtonRight:setDisabled(not showButtons or self.currentPage == self.numberOfPages)
	end
end

function TabbedMenuFrameElement:setPagingButtonsDisabled(disabled)
	self.pagingButtonsDisabled = disabled

	self:updatePagingButtons()
end

function TabbedMenuFrameElement:setPagingButtonsDirty()
	self:updatePagingButtons()
end

function TabbedMenuFrameElement:getCurrentPage()
	return self.currentPage
end
