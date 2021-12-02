IndexStateElement = {}
local IndexStateElement_mt = Class(IndexStateElement, BoxLayoutElement)

function IndexStateElement.new(target, custom_mt)
	if custom_mt == nil then
		custom_mt = IndexStateElement_mt
	end

	local self = BoxLayoutElement.new(target, custom_mt)
	self.pageElements = {}
	self.currentPageIndex = 1
	self.indexableElementId = nil
	self.indexableElement = nil
	self.stateElementTemplateId = nil
	self.stateElementTemplate = nil
	self.reverseElements = false
	self.indexMinimizeWidth = false

	return self
end

function IndexStateElement:delete()
	if self.stateElementTemplate ~= nil then
		self.stateElementTemplate:delete()
	end

	IndexStateElement:superClass().delete(self)
end

function IndexStateElement:loadFromXML(xmlFile, key)
	IndexStateElement:superClass().loadFromXML(self, xmlFile, key)

	self.stateElementTemplateId = getXMLString(xmlFile, key .. "#stateElementTemplateId")
	self.indexableElementId = getXMLString(xmlFile, key .. "#indexableElementId")
	self.reverseElements = getXMLBool(xmlFile, key .. "#reverseElements") or self.reverseElements
	self.indexMinimizeWidth = Utils.getNoNil(getXMLBool(xmlFile, key .. "#indexMinimizeWidth"), self.indexMinimizeWidth)
end

function IndexStateElement:loadProfile(profile, applyProfile)
	IndexStateElement:superClass().loadProfile(self, profile, applyProfile)

	self.reverseElements = profile:getBool("reverseElements", self.reverseElements)
	self.indexMinimizeWidth = profile:getBool("indexMinimizeWidth", self.indexMinimizeWidth)
end

function IndexStateElement:copyAttributes(src)
	IndexStateElement:superClass().copyAttributes(self, src)

	self.stateElementTemplate = src.stateElementTemplate
	self.indexableElement = src.indexableElement
	self.reverseElements = src.reverseElements
	self.indexMinimizeWidth = src.indexMinimizeWidth
end

function IndexStateElement:onGuiSetupFinished()
	IndexStateElement:superClass().onGuiSetupFinished(self)

	if not self.stateElementTemplate then
		self:locateStateElementTemplate()
	end

	if not self.indexableElement and self.indexableElementId ~= nil then
		self:locateIndexableElement()
	end
end

function IndexStateElement:locateStateElementTemplate()
	self.stateElementTemplate = self.parent:getDescendantById(self.stateElementTemplateId)

	if self.stateElementTemplate then
		self.stateElementTemplate:setVisible(false)
		self.stateElementTemplate:setHandleFocus(false)
		self.stateElementTemplate:unlinkElement()
	else
		print("Warning: IndexStateElement " .. tostring(self) .. " could not find state element template with ID [" .. tostring(self.stateElementTemplateId) .. "]. Check configuration.")
	end
end

function IndexStateElement:locateIndexableElement()
	if self.indexableElementId then
		local root = self.parent
		local levels = 20

		while root.parent and levels > 0 do
			root = root.parent
			levels = levels - 1
		end

		self.indexableElement = root:getDescendantById(self.indexableElementId)

		if self.indexableElement then
			if self.indexableElement:hasIncluded(IndexChangeSubjectMixin) then
				self.indexableElement:addIndexChangeObserver(self, self.onIndexChange)
			else
				print("Warning: Element " .. tostring(self.indexableElement) .. " does not support index change observers and is not valid to be targeted by IndexStateElement " .. tostring(self) .. ". Check configuration.")
			end
		else
			print("Warning: IndexStateElement " .. tostring(self) .. " could not find valid indexable element with ID [" .. tostring(self.indexableElementId) .. "]. Check configuration.")
		end
	end
end

function IndexStateElement:onIndexChange(index, count)
	if count ~= #self.pageElements then
		self:setPageCount(count, index)
	end

	self:setPageIndex(index)
end

function IndexStateElement:setPageCount(count, initialIndex)
	if not self.stateElementTemplate then
		self:locateStateElementTemplate()
	end

	if count ~= #self.pageElements then
		for _, element in pairs(self.pageElements) do
			self:removeElement(element)
			element:delete()
		end

		self.pageElements = {}

		for _ = 1, count do
			local stateElement = self.stateElementTemplate:clone(self)

			stateElement:setVisible(true)
			table.insert(self.pageElements, stateElement)
		end

		self:invalidateLayout()

		if initialIndex then
			self:setPageIndex(initialIndex)
		end

		self:updateSize()
	end
end

function IndexStateElement:updateSize()
	if not self.indexMinimizeWidth then
		return
	end

	local cells = self:getLayoutCells()
	local _, _, flowSize = self:getLayoutSizes(cells)

	self:setSize(flowSize, nil)

	if self.parent ~= nil and self.parent.invalidateLayout ~= nil then
		self.parent:invalidateLayout()
	end
end

function IndexStateElement:setPageIndex(index)
	if self.reverseElements then
		index = #self.pageElements - index + 1
	end

	self.currentPageIndex = MathUtil.clamp(index, 1, #self.pageElements)

	for i, element in ipairs(self.pageElements) do
		local displayState = GuiOverlay.STATE_NORMAL

		if i == self.currentPageIndex then
			displayState = GuiOverlay.STATE_SELECTED
		end

		element:setOverlayState(displayState)
	end
end
