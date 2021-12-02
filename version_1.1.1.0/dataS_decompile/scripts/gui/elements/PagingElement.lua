PagingElement = {}
local PagingElement_mt = Class(PagingElement, GuiElement)

function PagingElement.new(target, custom_mt)
	if custom_mt == nil then
		custom_mt = PagingElement_mt
	end

	local self = GuiElement.new(target, custom_mt)

	self:include(IndexChangeSubjectMixin)

	self.pageIdCount = 1
	self.pages = {}
	self.idPageHash = {}
	self.pageMapping = {}
	self.currentPageIndex = 1
	self.currentPageMappingIndex = 1

	return self
end

function PagingElement:loadFromXML(xmlFile, key)
	PagingElement:superClass().loadFromXML(self, xmlFile, key)
	self:addCallback(xmlFile, key .. "#onPageChange", "onPageChangeCallback")
	self:addCallback(xmlFile, key .. "#onPageUpdate", "onPageUpdateCallback")
end

function PagingElement:copyAttributes(src)
	PagingElement:superClass().copyAttributes(self, src)

	self.onPageChangeCallback = src.onPageChangeCallback
	self.onPageUpdateCallback = src.onPageUpdateCallback

	GuiMixin.cloneMixin(IndexChangeSubjectMixin, src, self)
end

function PagingElement:onGuiSetupFinished()
	PagingElement:superClass().onGuiSetupFinished(self)
	self:updatePageMapping()
end

function PagingElement:setPage(pageMappingIndex)
	for _, page in pairs(self.pages) do
		page.element:setVisible(false)
	end

	pageMappingIndex = MathUtil.clamp(pageMappingIndex, 1, #self.pageMapping)
	self.currentPageMappingIndex = pageMappingIndex
	local prevIndex = self.currentPageIndex
	self.currentPageIndex = self.pageMapping[pageMappingIndex]
	local hasChange = prevIndex ~= self.currentPageIndex

	self.pages[self.currentPageIndex].element:setVisible(true)
	self:raiseCallback("onPageChangeCallback", self.currentPageIndex, self.currentPageMappingIndex, self)
	self:notifyIndexChange(self.currentPageMappingIndex, #self.pageMapping)

	return hasChange
end

function PagingElement:addElement(element)
	PagingElement:superClass().addElement(self, element)

	if element.name ~= nil and g_i18n:hasText("ui_" .. element.name) then
		self:addPage(string.upper(element.name), element, g_i18n:getText("ui_" .. element.name))
	else
		self:addPage(tostring(element), element, "")
	end
end

function PagingElement:getNextID()
	local id = self.pageIdCount
	self.pageIdCount = self.pageIdCount + 1

	return id
end

function PagingElement:addPage(id, element, title, index)
	local newIndex = self:getNextID()

	if self.currentPageIndex == nil then
		self.currentPageIndex = newIndex
		self.currentPageMappingIndex = self.currentPageIndex
	end

	local page = {
		disabled = false,
		mappingIndex = 0,
		id = newIndex,
		idName = id,
		element = element,
		title = title
	}
	local insertIndex = index or #self.pages + 1

	table.insert(self.pages, insertIndex, page)

	self.idPageHash[page.id] = page

	element:setVisible(false)
	self:updatePageMapping()

	return page
end

function PagingElement:getVisiblePagesCount()
	return #self.pageMapping
end

function PagingElement:getPageIdByElement(element)
	for _, page in pairs(self.pages) do
		if page.element == element then
			return page.id
		end
	end
end

function PagingElement:getPageElementByIndex(pageIndex)
	local element = nil
	local page = self.pages[pageIndex]

	if page then
		element = page.element
	end

	return element
end

function PagingElement:getPageIndexByElement(element)
	for i, page in ipairs(self.pages) do
		if page.element == element then
			return i
		end
	end
end

function PagingElement:getPageMappingIndexByElement(element)
	for _, page in ipairs(self.pages) do
		if page.element == element then
			return page.mappingIndex
		end
	end

	return nil
end

function PagingElement:removePageByElement(pageElement)
	local removeIndex = -1
	local removeId = -1

	for i, page in ipairs(self.pages) do
		if page.element == pageElement then
			removeIndex = i
			removeId = page.id

			break
		end
	end

	local removedElement = table.remove(self.pages, removeIndex)

	if removedElement then
		self.currentPageIndex = 1
		self.idPageHash[removeId] = nil

		self:updatePageMapping()
	end
end

function PagingElement:removeElement(element)
	PagingElement:superClass().removeElement(self, element)
	self:removePageByElement(element)
end

function PagingElement:getCurrentPageId()
	return self.pages[self.currentPageIndex].id
end

function PagingElement:getPageMappingIndex(pageId)
	return self.idPageHash[pageId].mappingIndex
end

function PagingElement:getIsPageDisabled(pageId)
	return self.idPageHash[pageId].disabled
end

function PagingElement:getPageById(pageId)
	return self.idPageHash[pageId]
end

function PagingElement:setPageDisabled(page, disabled)
	if page ~= nil then
		page.disabled = disabled

		self:updatePageMapping()
		self:raiseCallback("onPageUpdateCallback", page, self)
	end
end

function PagingElement:setPageIdDisabled(pageId, disabled)
	if self.idPageHash[pageId] ~= nil then
		self:setPageDisabled(self.idPageHash[pageId], disabled)
	end
end

function PagingElement:updatePageMapping()
	self.pageMapping = {}
	self.pageTitles = {}
	local currentPage = self.pages[self.currentPageIndex]

	for i, page in ipairs(self.pages) do
		if not page.disabled then
			table.insert(self.pageMapping, i)
			table.insert(self.pageTitles, page.title)

			page.mappingIndex = #self.pageMapping
		else
			if page == currentPage then
				currentPage = nil
			end

			page.mappingIndex = 1
		end
	end

	if currentPage == nil then
		if not self.neuterPageUpdates then
			self.currentPageMappingIndex = MathUtil.clamp(self.currentPageMappingIndex, 1, #self.pageMapping)

			if self.currentPageMappingIndex > 0 then
				self:setPage(self.currentPageMappingIndex)
			end
		end
	else
		self:notifyIndexChange(self.currentPageMappingIndex, #self.pageMapping)
	end
end

function PagingElement:getPageTitles()
	return self.pageTitles
end

function PagingElement:onOpen()
	self:raiseCallback("onOpenCallback", self)

	local child = self.pages[self.currentPageIndex].element

	child:onOpen()
end

function PagingElement:onClose()
	self:raiseCallback("onCloseCallback", self)

	local child = self.pages[self.currentPageIndex].element

	child:onClose()
end
