SmoothListElement = {}
local SmoothListElement_mt = Class(SmoothListElement, GuiElement)

function SmoothListElement.new(target, custom_mt)
	local self = SmoothListElement:superClass().new(target, custom_mt or SmoothListElement_mt)

	self:include(IndexChangeSubjectMixin)
	self:include(PlaySampleMixin)

	self.dataSource = nil
	self.delegate = nil
	self.cellCache = {}
	self.sections = {}
	self.isLoaded = false
	self.clipping = true
	self.sectionHeaderCellName = nil
	self.isHorizontalList = false
	self.numLateralItems = 1
	self.listItemSpacing = 0
	self.listItemLateralSpacing = 0
	self.lengthAxis = 2
	self.widthAxis = 1
	self.viewOffset = 0
	self.targetViewOffset = 0
	self.contentSize = 0
	self.totalItemCount = 0
	self.scrollViewOffsetDelta = 0
	self.selectedIndex = 1
	self.selectedSectionIndex = 1
	self.supportsMouseScrolling = true
	self.doubleClickInterval = 400
	self.selectOnClick = false
	self.ignoreMouse = false
	self.showHighlights = false
	self.selectOnScroll = false
	self.itemizedScrollDelta = false
	self.listSmoothingDisabled = false
	self.selectedWithoutFocus = true

	return self
end

function SmoothListElement:loadFromXML(xmlFile, key)
	SmoothListElement:superClass().loadFromXML(self, xmlFile, key)
	self:addCallback(xmlFile, key .. "#onScroll", "onScrollCallback")
	self:addCallback(xmlFile, key .. "#onDoubleClick", "onDoubleClickCallback")
	self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")

	self.isHorizontalList = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isHorizontalList"), self.isHorizontalList)
	self.lengthAxis = self.isHorizontalList and 1 or 2
	self.widthAxis = self.isHorizontalList and 2 or 1
	self.numLateralItems = Utils.getNoNil(getXMLInt(xmlFile, key .. "#numLateralItems"), self.numLateralItems)
	self.listItemSpacing = unpack(GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#listItemSpacing"), {
		self.outputSize[self.lengthAxis]
	}, {
		self.listItemSpacing
	}))
	self.listItemLateralSpacing = unpack(GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#listItemLateralSpacing"), {
		self.outputSize[self.widthAxis]
	}, {
		self.listItemLateralSpacing
	}))
	self.supportsMouseScrolling = Utils.getNoNil(getXMLBool(xmlFile, key .. "#supportsMouseScrolling"), self.supportsMouseScrolling)
	self.doubleClickInterval = Utils.getNoNil(getXMLInt(xmlFile, key .. "#doubleClickInterval"), self.doubleClickInterval)
	self.selectOnClick = Utils.getNoNil(getXMLBool(xmlFile, key .. "#selectOnClick"), self.selectOnClick)
	self.ignoreMouse = Utils.getNoNil(getXMLBool(xmlFile, key .. "#ignoreMouse"), self.ignoreMouse)
	self.showHighlights = Utils.getNoNil(getXMLBool(xmlFile, key .. "#showHighlights"), self.showHighlights)
	self.selectOnScroll = Utils.getNoNil(getXMLBool(xmlFile, key .. "#selectOnScroll"), self.selectOnScroll)
	self.itemizedScrollDelta = Utils.getNoNil(getXMLBool(xmlFile, key .. "#itemizedScrollDelta"), self.itemizedScrollDelta)
	self.listSmoothingDisabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#listSmoothingDisabled"), self.listSmoothingDisabled)
	self.selectedWithoutFocus = Utils.getNoNil(getXMLBool(xmlFile, key .. "#selectedWithoutFocus"), self.selectedWithoutFocus)
	local delegateName = getXMLString(xmlFile, key .. "#listDelegate")

	if delegateName == "self" then
		self.delegate = self.target
	elseif delegateName ~= "nil" then
		self.delegate = self.target[delegateName]
	end

	local dataSourceName = getXMLString(xmlFile, key .. "#listDataSource")

	if dataSourceName == "self" then
		self.dataSource = self.target
	elseif delegateName ~= "nil" then
		self.dataSource = self.target[dataSourceName]
	end

	self.sectionHeaderCellName = getXMLString(xmlFile, key .. "#listSectionHeader")
	self.startClipperElementName = getXMLString(xmlFile, key .. "#startClipperElementName")
	self.endClipperElementName = getXMLString(xmlFile, key .. "#endClipperElementName")
	self.updateChildrenOverlayState = false
end

function SmoothListElement:loadProfile(profile, applyProfile)
	SmoothListElement:superClass().loadProfile(self, profile, applyProfile)

	self.isHorizontalList = profile:getBool("isHorizontalList", self.isHorizontalList)
	self.lengthAxis = self.isHorizontalList and 1 or 2
	self.widthAxis = self.isHorizontalList and 2 or 1
	self.numLateralItems = profile:getNumber("numLateralItems", self.numLateralItems)
	self.listItemSpacing = unpack(GuiUtils.getNormalizedValues(profile:getValue("listItemSpacing"), {
		self.outputSize[self.lengthAxis]
	}, {
		self.listItemSpacing
	}))
	self.listItemLateralSpacing = unpack(GuiUtils.getNormalizedValues(profile:getValue("listItemLateralSpacing"), {
		self.outputSize[self.widthAxis]
	}, {
		self.listItemLateralSpacing
	}))
	self.supportsMouseScrolling = profile:getBool("supportsMouseScrolling", self.supportsMouseScrolling)
	self.doubleClickInterval = profile:getNumber("doubleClickInterval", self.doubleClickInterval)
	self.selectOnClick = profile:getBool("selectOnClick", self.selectOnClick)
	self.ignoreMouse = profile:getBool("ignoreMouse", self.ignoreMouse)
	self.showHighlights = profile:getBool("showHighlights", self.showHighlights)
	self.selectOnScroll = profile:getBool("selectOnScroll", self.selectOnScroll)
	self.itemizedScrollDelta = profile:getBool("itemizedScrollDelta", self.itemizedScrollDelta)
	self.listSmoothingDisabled = profile:getBool("listSmoothingDisabled", self.listSmoothingDisabled)
	self.selectedWithoutFocus = profile:getBool("selectedWithoutFocus", self.selectedWithoutFocus)
end

function SmoothListElement:clone(parent, includeId, suppressOnCreate)
	local cloned = SmoothListElement:superClass().clone(self, parent, includeId, suppressOnCreate)
	cloned.cellDatabase = {}

	for name, cell in pairs(self.cellDatabase) do
		cloned.cellDatabase[name] = cell:clone(nil, , true)
	end

	for name, _ in pairs(self.cellCache) do
		cloned.cellCache[name] = {}
	end

	return cloned
end

function SmoothListElement:applyScreenAlignment()
	SmoothListElement:superClass().applyScreenAlignment(self)
	self:iterateOverDatabase(function (e)
		e:applyScreenAlignment()
	end)

	local xScale, yScale = self:getAspectScale()

	if self.lengthAxis == 1 then
		self.listItemSpacing = self.listItemSpacing * xScale
		self.listItemLateralSpacing = self.listItemLateralSpacing * yScale
	else
		self.listItemSpacing = self.listItemSpacing * yScale
		self.listItemLateralSpacing = self.listItemLateralSpacing * xScale
	end
end

function SmoothListElement:copyAttributes(src)
	SmoothListElement:superClass().copyAttributes(self, src)

	self.dataSource = src.dataSource
	self.delegate = src.delegate
	self.singularCellName = src.singularCellName
	self.sectionHeaderCellName = src.sectionHeaderCellName
	self.startClipperElementName = src.startClipperElementName
	self.endClipperElementName = src.endClipperElementName
	self.isHorizontalList = src.isHorizontalList
	self.numLateralItems = src.numLateralItems
	self.listItemSpacing = src.listItemSpacing
	self.listItemLateralSpacing = src.listItemLateralSpacing
	self.supportsMouseScrolling = src.supportsMouseScrolling
	self.doubleClickInterval = src.doubleClickInterval
	self.selectOnClick = src.selectOnClick
	self.ignoreMouse = src.ignoreMouse
	self.showHighlights = src.showHighlights
	self.itemizedScrollDelta = src.itemizedScrollDelta
	self.selectOnScroll = src.selectOnScroll
	self.listSmoothingDisabled = src.listSmoothingDisabled
	self.selectedWithoutFocus = src.selectedWithoutFocus
	self.lengthAxis = src.lengthAxis
	self.widthAxis = src.widthAxis
	self.onScrollCallback = src.onScrollCallback
	self.onDoubleClickCallback = src.onDoubleClickCallback
	self.onClickCallback = src.onClickCallback
	self.isLoaded = src.isLoaded

	GuiMixin.cloneMixin(PlaySampleMixin, src, self)
end

function SmoothListElement:onGuiSetupFinished()
	SmoothListElement:superClass().onGuiSetupFinished(self)

	if self.startClipperElementName ~= nil then
		self.startClipperElement = self.parent:getDescendantByName(self.startClipperElementName)
	end

	if self.endClipperElementName ~= nil then
		self.endClipperElement = self.parent:getDescendantByName(self.endClipperElementName)
	end

	if not self.isLoaded then
		self:buildCellDatabase()

		self.isLoaded = true
	end
end

function SmoothListElement:buildCellDatabase()
	self.cellDatabase = {}
	local numCellsInDatabase = 0

	for i = #self.elements, 1, -1 do
		local element = self.elements[i]
		local name = element.name

		if element:isa(ListItemElement) then
			if name == nil then
				element.name = "autoCell" .. i
				name = element.name
			end

			if element.anchors[1] == 0 and element.anchors[2] == 1 and element.anchors[3] == 0 and element.anchors[4] == 1 then
				element:setSize(1, 1)
			end

			element.anchors[1] = 0
			element.anchors[2] = 0
			element.anchors[3] = 1
			element.anchors[4] = 1
			self.cellDatabase[name] = element
			self.cellCache[name] = {}
			numCellsInDatabase = numCellsInDatabase + 1
		end

		element:unlinkElement()
		FocusManager:removeElement(element)
	end

	if self.sectionHeaderCellName ~= nil and self.cellDatabase[self.sectionHeaderCellName] == nil then
		Logging.warning("List section header with name '%s' does not exist on '%s'", self.sectionHeaderCellName, self.profile)

		self.sectionHeaderCellName = nil
	end

	if self.sectionHeaderCellName ~= nil then
		numCellsInDatabase = numCellsInDatabase - 1
	end

	if numCellsInDatabase == 1 then
		for name, cell in pairs(self.cellDatabase) do
			if name ~= self.sectionHeaderCellName then
				self.singularCellName = name

				break
			end
		end
	end
end

function SmoothListElement:iterateOverDatabase(lambda)
	if self.cellDatabase ~= nil then
		for _, cell in pairs(self.cellDatabase) do
			lambda(cell)
		end
	end

	if self.cellCache ~= nil then
		for _, elements in pairs(self.cellCache) do
			for i = 1, #elements do
				lambda(elements[i])
			end
		end
	end
end

function SmoothListElement:delete()
	for name, elements in pairs(self.cellCache) do
		for _, element in ipairs(elements) do
			element:delete()
		end
	end

	for name, element in pairs(self.cellDatabase) do
		element:delete()
	end

	SmoothListElement:superClass().delete(self)
end

function SmoothListElement:onOpen()
	if self.setNextOpenIndex ~= nil then
		self:setSoundSuppressed(true)
		self:setSelectedItem(self.setNextOpenSectionIndex, self.setNextOpenIndex, true, 0)

		self.setNextOpenIndex = nil
		self.setNextOpenSectionIndex = nil

		self:setSoundSuppressed(false)
	end
end

function SmoothListElement:setDataSource(dataSource)
	self.dataSource = dataSource

	if self.delegate == nil then
		self.delegate = dataSource
	end
end

function SmoothListElement:setDelegate(delegate)
	self.delegate = delegate

	if self.dataSource == nil then
		self.dataSource = delegate
	end
end

function SmoothListElement:dequeueReusableCell(name)
	if self.cellDatabase[name] == nil then
		return nil
	end

	local cell = nil
	local cache = self.cellCache[name]

	if #cache > 0 then
		cell = cache[#cache]
		cache[#cache] = nil

		self:addElement(cell)
	else
		cell = self.cellDatabase[name]:clone(self)
		cell.reusableName = name
	end

	FocusManager:loadElementFromCustomValues(cell)

	return cell
end

function SmoothListElement:setTarget(target, originalTarget, callOnCreate)
	SmoothListElement:superClass().setTarget(self, target, originalTarget, callOnCreate)

	if self.delegate == originalTarget then
		self.delegate = target
	end

	if self.dataSource == originalTarget then
		self.dataSource = target
	end

	self:iterateOverDatabase(function (e)
		e:setTarget(target, originalTarget, callOnCreate)
	end)
end

function SmoothListElement:queueReusableCell(cell)
	if self.sections[cell.sectionIndex] ~= nil then
		self.sections[cell.sectionIndex].cells[cell.indexInSection] = nil
	end

	cell.sectionIndex = nil
	cell.indexInSection = nil
	local cache = self.cellCache[cell.reusableName]
	cache[#cache + 1] = cell

	cell:unlinkElement()
	FocusManager:removeElement(cell)
end

function SmoothListElement:reloadData()
	if self.dataSource == nil then
		return
	end

	local selectedSection = self.selectedSectionIndex
	local selectedIndex = self.selectedIndex

	self:setSoundSuppressed(true)
	self:buildSectionInfo()
	self:updateView(nil, true)

	selectedSection = MathUtil.clamp(selectedSection, 1, #self.sections)

	if selectedSection ~= 0 then
		selectedIndex = MathUtil.clamp(selectedIndex, 1, self.sections[selectedSection].numItems)

		if selectedIndex == 0 then
			for sectionIndex, section in ipairs(self.sections) do
				selectedIndex = MathUtil.clamp(selectedIndex, 1, section.numItems)

				if selectedIndex > 0 then
					selectedSection = sectionIndex

					break
				end
			end
		end

		if selectedIndex ~= 0 then
			if not self:getIsVisible() then
				self.setNextOpenIndex = selectedIndex
				self.setNextOpenSectionIndex = selectedSection
			else
				self:setSelectedItem(selectedSection, selectedIndex, true, 0)
			end
		else
			self.selectedSectionIndex = 0
			self.selectedIndex = 0
		end
	end

	self:setSoundSuppressed(false)
end

function SmoothListElement:forceSelectionUpdate()
	self:setSoundSuppressed(true)

	if self.setNextOpenIndex ~= nil then
		self:setSelectedItem(self.setNextOpenSectionIndex, self.setNextOpenIndex, true, 0)

		self.setNextOpenIndex = nil
		self.setNextOpenSectionIndex = nil
	else
		self:setSelectedItem(self.selectedSectionIndex, self.selectedIndex, true, 0)
	end

	self:setSoundSuppressed(false)
end

function SmoothListElement:reloadSection(section)
	self:reloadData()
end

function SmoothListElement:buildSectionInfo()
	local total = 0
	local numberOfSections = self.dataSource.getNumberOfSections == nil and 1 or self.dataSource:getNumberOfSections(self)
	local itemWidth = (self.absSize[self.widthAxis] - (self.numLateralItems - 1) * self.listItemLateralSpacing) / self.numLateralItems + self.listItemLateralSpacing
	local currentLengthOffset = 0
	local totalRows = 0

	for s = 1, numberOfSections do
		if self.sections[s] == nil then
			self.sections[s] = {
				cells = {}
			}
		end

		local section = self.sections[s]
		section.startOffset = currentLengthOffset
		section.itemOffsets = {}
		section.itemLateralOffsets = {}
		local hasHeader = self.sectionHeaderCellName ~= nil

		if self.dataSource.getTitleForSectionHeader ~= nil and self.dataSource:getTitleForSectionHeader(self, s) == nil then
			hasHeader = false
		end

		if hasHeader then
			currentLengthOffset = currentLengthOffset + self.cellDatabase[self.sectionHeaderCellName].size[self.lengthAxis] + self.listItemSpacing
			section.itemOffsets[0] = section.startOffset
		end

		section.numItems = self.dataSource:getNumberOfItemsInSection(self, s)
		local lastRow = 1
		local rowMaxLength = 0

		for i = 1, section.numItems do
			local itemLength = self:getLengthOfItemFast(s, i)
			local row = math.floor((i - 1) / self.numLateralItems) + 1
			local column = (i - 1) % self.numLateralItems + 1
			local needsAnotherRow = row < section.numItems / self.numLateralItems

			if needsAnotherRow or s < numberOfSections then
				itemLength = itemLength + self.listItemSpacing
			end

			if row ~= lastRow then
				lastRow = row
				currentLengthOffset = currentLengthOffset + rowMaxLength
				totalRows = totalRows + 1
				rowMaxLength = itemLength
			else
				rowMaxLength = math.max(rowMaxLength, itemLength)
			end

			section.itemOffsets[i] = currentLengthOffset
			section.itemLateralOffsets[i] = itemWidth * (column - 1)
		end

		currentLengthOffset = currentLengthOffset + rowMaxLength
		totalRows = totalRows + 1
		section.endOffset = currentLengthOffset
		total = total + section.numItems
		self.sections[s] = section
	end

	for s = #self.sections, numberOfSections + 1, -1 do
		self.sections[s] = nil
	end

	if totalRows > 0 then
		if self.itemizedScrollDelta and #self.sections == 1 and self.singularCellName ~= nil then
			self.scrollViewOffsetDelta = (currentLengthOffset + self.listItemSpacing) / totalRows
		else
			self.scrollViewOffsetDelta = math.max(currentLengthOffset / totalRows * 0.4, self.absSize[self.lengthAxis] / 5)
		end
	else
		self.scrollViewOffsetDelta = 0
	end

	self.contentSize = currentLengthOffset
	self.totalItemCount = total
	self.viewOffset = math.max(math.min(self.viewOffset, self.contentSize - self.absSize[self.lengthAxis]), 0)
	self.targetViewOffset = math.max(math.min(self.targetViewOffset, self.contentSize - self.absSize[self.lengthAxis]), 0)

	self:updateScrollClippers()
end

function SmoothListElement:getLengthOfItemFast(section, index)
	local itemHeight = 0
	local cellName = self.singularCellName or self.dataSource:getCellTypeForItemInSection(self, section, index)
	local cell = self.cellDatabase[cellName]

	if self.dataSource.getHeightForCell == nil then
		itemHeight = cell.size[self.lengthAxis]
	else
		itemHeight = self.dataSource:getHeightForCell(self, section, index, cell)
	end

	return itemHeight
end

function SmoothListElement:updateView(updateSlider, repopulate)
	local viewEndOffset = self.viewOffset + self.absSize[self.lengthAxis]
	local firstSection = 0
	local firstIndex = 0

	for s = 1, #self.sections do
		local section = self.sections[s]

		if self.viewOffset < section.endOffset then
			firstSection = s

			for i = 0, section.numItems do
				local offset = section.itemOffsets[i]
				local endIndex = i + self.numLateralItems
				local endOffset = section.endOffset

				if endIndex <= section.numItems then
					endOffset = section.itemOffsets[endIndex]
				end

				if offset ~= nil and endOffset ~= nil and self.viewOffset < endOffset then
					firstIndex = i

					break
				end
			end

			if firstIndex == nil then
				firstIndex = section.numItems
			end

			break
		end
	end

	local lastSection = 0
	local lastIndex = 0

	for s = #self.sections, math.max(firstSection, 1), -1 do
		local section = self.sections[s]

		if section.startOffset < viewEndOffset then
			lastSection = s

			for i = section.numItems - 1, 0, -1 do
				local offset = section.itemOffsets[i + 1]

				if offset ~= nil and offset < viewEndOffset then
					lastIndex = i + 1

					break
				end
			end

			if lastIndex == nil then
				lastIndex = section.numItems
			end

			break
		end
	end

	for e = #self.elements, 1, -1 do
		local element = self.elements[e]

		if element.sectionIndex < firstSection or lastSection < element.sectionIndex or element.sectionIndex == firstSection and element.indexInSection < firstIndex or element.sectionIndex == lastSection and lastIndex < element.indexInSection or self.sections[element.sectionIndex].numItems < element.indexInSection then
			self:queueReusableCell(element)
		end
	end

	if firstSection == 0 or lastSection == 0 then
		return
	end

	local s = firstSection
	local i = firstIndex
	local currentOffset = self.sections[s].itemOffsets[firstIndex]

	while currentOffset - self.viewOffset < self.absSize[self.lengthAxis] do
		local section = self.sections[s]

		if section.cells[i] == nil then
			local element = nil

			if i == 0 then
				if self.sectionHeaderCellName ~= nil then
					element = self:dequeueReusableCell(self.sectionHeaderCellName)
					element.isHeader = true
					local titleAttribute = element:getAttribute("title")

					if titleAttribute ~= nil and self.dataSource.getTitleForSectionHeader ~= nil then
						titleAttribute:setText(self.dataSource:getTitleForSectionHeader(self, s))
					elseif self.dataSource.populateSectionHeader ~= nil then
						self.dataSource:populateSectionHeader(self, s, element)
					end
				end
			else
				local cellName = self.singularCellName or self.dataSource:getCellTypeForItemInSection(self, s, i)
				element = self:dequeueReusableCell(cellName)

				self.dataSource:populateCellForItemInSection(self, s, i, element)
				element:setAlternating(i % 2 == 0)
			end

			element.sectionIndex = s
			element.indexInSection = i
			section.cells[i] = element

			if element.setSelected ~= nil then
				element:setSelected(s == self.selectedSectionIndex and i == self.selectedIndex and (self.selectedWithoutFocus or FocusManager:getFocusedElement() == self))
			end
		elseif repopulate then
			local element = section.cells[i]

			if i == 0 then
				local titleAttribute = element:getAttribute("title")

				if titleAttribute ~= nil and self.dataSource.getTitleForSectionHeader ~= nil then
					titleAttribute:setText(self.dataSource:getTitleForSectionHeader(self, s))
				elseif self.dataSource.populateSectionHeader ~= nil then
					self.dataSource:populateSectionHeader(self, s, element)
				end
			else
				self.dataSource:populateCellForItemInSection(self, s, i, element)
				element:setAlternating(i % 2 == 0)

				if element.setSelected ~= nil then
					element:setSelected(s == self.selectedSectionIndex and i == self.selectedIndex and (self.selectedWithoutFocus or FocusManager:getFocusedElement() == self))
				end
			end
		end

		i = i + 1

		if s == lastSection and lastIndex < i then
			break
		elseif section.numItems < i then
			i = 0
			s = s + 1

			if lastSection < s then
				break
			end

			if self.sections[s].itemOffsets[i] == nil then
				i = 1
			end

			currentOffset = self.sections[s].startOffset
		else
			currentOffset = section.itemOffsets[i]
		end
	end

	for e = 1, #self.elements do
		local element = self.elements[e]

		self:updateCellPosition(element)
	end

	if updateSlider ~= false then
		self:raiseSliderUpdateEvent()
	end

	self:updateScrollClippers()
end

function SmoothListElement:updateCellPosition(element)
	local section = self.sections[element.sectionIndex]
	local offset, lateralOffset = nil

	if element.indexInSection == 0 then
		offset = section.startOffset
		lateralOffset = 0
	else
		offset = section.itemOffsets[element.indexInSection]
		lateralOffset = section.itemLateralOffsets[element.indexInSection]
	end

	if self.lengthAxis == 1 then
		element:setPosition(offset - self.viewOffset, -lateralOffset)

		if element.indexInSection == 0 then
			element:setSize(nil, self.absSize[2])
		else
			element:setSize(nil, self.absSize[2] / self.numLateralItems - self.listItemLateralSpacing)
		end
	else
		element:setPosition(lateralOffset, self.viewOffset - offset)

		if element.indexInSection == 0 then
			element:setSize(self.absSize[1], nil)
		else
			local w = (self.absSize[1] - (self.numLateralItems - 1) * self.listItemLateralSpacing) / self.numLateralItems

			element:setSize(w, nil)
		end
	end
end

function SmoothListElement:scrollTo(offset, updateSlider)
	offset = math.max(math.min(offset, self.contentSize - self.absSize[self.lengthAxis]), 0)

	if offset ~= self.viewOffset then
		self.viewOffset = offset
		self.targetViewOffset = offset
		self.isMovingToTarget = false

		self:updateView(updateSlider)
	end
end

function SmoothListElement:smoothScrollTo(offset)
	if self.listSmoothingDisabled then
		return self:scrollTo(offset)
	end

	if self.itemizedScrollDelta then
		-- Nothing
	end

	offset = math.max(math.min(offset, self.contentSize - self.absSize[self.lengthAxis]), 0)
	self.targetViewOffset = offset
	self.isMovingToTarget = true
end

function SmoothListElement:setSelectedIndex(index)
	self:setSelectedItem(1, index)
end

function SmoothListElement:setSelectedItem(section, index, forceChangeEvent, direction)
	if index == nil or section == nil then
		return
	end

	if section > #self.sections or section < 1 then
		return
	end

	if self.sections[section].numItems < index then
		return
	end

	local hasChanged = self.selectedIndex ~= index or self.selectedSectionIndex ~= section
	self.selectedSectionIndex = section
	self.selectedIndex = index

	if hasChanged then
		self:makeCellVisible(self.selectedSectionIndex, self.selectedIndex)
	end

	if hasChanged then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	end

	if (hasChanged or forceChangeEvent) and self.isLoaded then
		self:notifyIndexChange(index, self.sections[1].numItems)

		if self.delegate.onListSelectionChanged ~= nil then
			self.delegate:onListSelectionChanged(self, section, index)
		end
	end

	self:applyElementSelection()
end

function SmoothListElement:setHighlightedItem(element)
	if not self.showHighlights then
		return
	end

	local hasChanged = self.highlightedElement ~= element

	if hasChanged then
		if self.highlightedElement ~= nil then
			local prevState = self.highlightedElement:getOverlayState()

			if prevState == GuiOverlay.STATE_HIGHLIGHTED then
				self.highlightedElement:setOverlayState(GuiOverlay.STATE_NORMAL)
				self.highlightedElement:restoreOverlayState()
			end

			self.highlightedElement:onHighlightRemove()
		end

		self.highlightedElement = element

		if element ~= nil then
			if element:getOverlayState() ~= GuiOverlay.STATE_SELECTED then
				element:storeOverlayState()
				element:setOverlayState(GuiOverlay.STATE_HIGHLIGHTED)
			end

			element:onHighlight()
		end

		if self.delegate.onListHighlightChanged ~= nil then
			local section, index = nil

			if element ~= nil then
				index = element.indexInSection
				section = element.sectionIndex
			end

			self.delegate:onListHighlightChanged(self, section, index)
		end
	end
end

function SmoothListElement:applyElementSelection()
	local focusAllowed = self.selectedWithoutFocus or FocusManager:getFocusedElement() == self

	for i = 1, #self.elements do
		local element = self.elements[i]

		if element.setSelected ~= nil then
			element:setSelected(focusAllowed and element.sectionIndex == self.selectedSectionIndex and element.indexInSection == self.selectedIndex)
		end
	end
end

function SmoothListElement:clearElementSelection()
	for i = 1, #self.elements do
		local element = self.elements[i]

		if element.setSelected ~= nil then
			element:setSelected(false)
		end
	end
end

function SmoothListElement:makeCellVisible(section, index, fast)
	local oldViewOffset = self.viewOffset
	local sectionInfo = self.sections[section]

	if sectionInfo == nil then
		return
	end

	local cellStartOffset = sectionInfo.itemOffsets[index]

	if cellStartOffset == nil then
		return
	end

	local row = math.floor((index - 1) / self.numLateralItems) + 1
	local firstOfNextRow = row * self.numLateralItems + 1
	local cellEndOffset = sectionInfo.itemOffsets[firstOfNextRow]

	if cellEndOffset == nil then
		cellEndOffset = sectionInfo.endOffset
	elseif section < #self.sections or index < sectionInfo.numItems then
		cellEndOffset = cellEndOffset - self.listItemSpacing
	end

	local newOffset = self.viewOffset
	local viewSize = self.absSize[self.lengthAxis]

	if cellStartOffset < self.viewOffset then
		newOffset = cellStartOffset
	elseif cellEndOffset > self.viewOffset + viewSize then
		newOffset = cellEndOffset - viewSize
	else
		return
	end

	if not self.isMovingToTarget or self.targetViewOffset ~= newOffset then
		if fast then
			self:scrollTo(newOffset)
		else
			self:smoothScrollTo(newOffset)
		end
	end
end

function SmoothListElement:makeSelectedCellVisible()
	self:makeCellVisible(self.selectedSectionIndex, self.selectedIndex)
end

function SmoothListElement:updateScrollClippers(initial)
	if self.startClipperElement ~= nil then
		local visible = self.contentSize > 0 and self.viewOffset > 0.01

		self.startClipperElement:setVisible(visible)
	end

	if self.endClipperElement ~= nil then
		local visible = self.contentSize > 0 and self.viewOffset - (self.contentSize - self.absSize[self.lengthAxis]) < -0.01

		self.endClipperElement:setVisible(visible)
	end
end

function SmoothListElement:update(dt)
	SmoothListElement:superClass().update(self, dt)

	if self.isMovingToTarget then
		if self:getIsVisible() then
			self.viewOffset = self.viewOffset + (self.targetViewOffset - self.viewOffset) * 0.01 * dt
		else
			self.viewOffset = self.targetViewOffset
		end

		if math.abs(self.targetViewOffset - self.viewOffset) < 0.0005 then
			self.isMovingToTarget = false
		end

		self:updateView(true)
	end
end

function SmoothListElement:getSelectedElement()
	return self:getElementAtSectionIndex(self.selectedSectionIndex, self.selectedIndex)
end

function SmoothListElement:getItemCount()
	return self.totalItemCount
end

function SmoothListElement:getSelectedIndexInSection()
	return self.selectedIndex
end

function SmoothListElement:getSelectedSection()
	return self.selectedSectionIndex
end

function SmoothListElement:getSelectedPath()
	return self.selectedSectionIndex, self.selectedIndex
end

function SmoothListElement:getElementAtSectionIndex(section, index)
	for i = 1, #self.elements do
		local e = self.elements[i]

		if e.sectionIndex == section and e.indexInSection == index then
			return e
		end
	end

	return nil
end

function SmoothListElement:raiseSliderUpdateEvent()
	if self.sliderElement ~= nil then
		self.sliderElement:onBindUpdate(self)
	end
end

function SmoothListElement:onSliderValueChanged(slider, newValue, immediateMode)
	if self.sections == nil then
		return
	end

	local newOffset = (self.contentSize - self.absSize[self.lengthAxis]) / (slider.maxValue - slider.minValue) * (newValue - slider.minValue)

	if immediateMode then
		self:scrollTo(newOffset, false)
	else
		self:smoothScrollTo(newOffset)
	end
end

function SmoothListElement:getViewOffsetPercentage()
	return self.viewOffset / (self.contentSize - self.absSize[self.lengthAxis])
end

function SmoothListElement:onMouseDown()
	self.mouseDown = true

	FocusManager:setFocus(self)
end

function SmoothListElement:onMouseUp()
	if self.mouseOverElement ~= nil then
		local previousSection = self.selectedSectionIndex
		local previousIndex = self.selectedIndex
		local clickedSection = self.mouseOverElement.sectionIndex
		local clickedIndex = self.mouseOverElement.indexInSection
		local notified = false

		self:setSelectedItem(clickedSection, clickedIndex, nil, 0)

		if self.lastClickTime ~= nil and self.lastClickTime > self.target.time - self.doubleClickInterval then
			if clickedSection == previousSection and clickedIndex == previousIndex then
				self:notifyDoubleClick(clickedSection, clickedIndex, self.mouseOverElement)

				notified = true
			end

			self.lastClickTime = nil
		else
			self.lastClickTime = self.target.time
		end

		if not self.selectOnClick and not notified then
			self:notifyClick(clickedSection, clickedIndex, self.mouseOverElement)
		end
	else
		self.lastClickTime = nil
	end

	self.mouseDown = false
end

function SmoothListElement:notifyDoubleClick(section, index, element)
	self:raiseCallback("onDoubleClickCallback", self, section, index, element)
end

function SmoothListElement:notifyClick(section, index, element)
	self:raiseCallback("onClickCallback", self, section, index, element)
end

function SmoothListElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() and not self.ignoreMouse then
		if SmoothListElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
			eventUsed = true
		end

		if not eventUsed and GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2]) then
			local mouseOverElement = self:getElementAtScreenPosition(posX, posY)

			if mouseOverElement ~= nil and mouseOverElement.indexInSection == 0 then
				mouseOverElement = nil
			end

			if self.mouseOverElement ~= mouseOverElement then
				self:setHighlightedItem(mouseOverElement)

				self.mouseOverElement = mouseOverElement
			end

			if isDown then
				if button == Input.MOUSE_BUTTON_LEFT then
					self:onMouseDown()

					eventUsed = true
				end

				if self.supportsMouseScrolling then
					local deltaIndex = 0

					if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
						deltaIndex = -1
					elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
						deltaIndex = 1
					end

					if deltaIndex ~= 0 then
						if self.selectOnScroll then
							if #self.sections == 1 then
								local newIndex = math.max(1, math.min(self.sections[1].numItems, self.selectedIndex + deltaIndex))

								self:setSelectedItem(1, newIndex)
							end
						else
							self:smoothScrollTo(self.targetViewOffset + deltaIndex * self.scrollViewOffsetDelta)
						end

						eventUsed = true
					end
				end
			end

			if isUp and button == Input.MOUSE_BUTTON_LEFT and self.mouseDown then
				self:onMouseUp()

				eventUsed = true
			end
		elseif self.mouseOverElement ~= nil then
			self.mouseOverElement = nil

			self:setHighlightedItem(self.mouseOverElement)
		end
	end

	return eventUsed
end

function SmoothListElement:getElementAtScreenPosition(x, y)
	for i = #self.elements, 1, -1 do
		local v = self.elements[i]

		if GuiUtils.checkOverlayOverlap(x, y, v.absPosition[1], v.absPosition[2], v.absSize[1], v.absSize[2]) then
			return v, v.sectionIndex, v.indexInSection
		end
	end

	return nil
end

function SmoothListElement:shouldFocusChange(direction)
	if self.totalItemCount == 0 then
		return true
	end

	local sectionIndex = self.selectedSectionIndex
	local section = self.sections[sectionIndex]
	local index = self.selectedIndex
	local row = math.floor((index - 1) / self.numLateralItems) + 1
	local column = (index - 1) % self.numLateralItems + 1
	local selectionDirection = 0
	local targetSection = sectionIndex
	local targetIndex = index

	if self.isHorizontalList then
		if direction == FocusManager.TOP then
			direction = FocusManager.LEFT
		elseif direction == FocusManager.BOTTOM then
			direction = FocusManager.RIGHT
		elseif direction == FocusManager.LEFT then
			direction = FocusManager.TOP
		elseif direction == FocusManager.RIGHT then
			direction = FocusManager.BOTTOM
		end
	end

	if direction == FocusManager.TOP then
		targetIndex = index - self.numLateralItems

		if targetIndex < 1 then
			if sectionIndex > 1 then
				targetSection = sectionIndex

				repeat
					targetSection = targetSection - 1

					if targetSection == 0 then
						return true
					end

					local s = self.sections[targetSection]
					local nRows = math.floor((s.numItems - 1) / self.numLateralItems)
					local lastColumn = s.numItems % self.numLateralItems

					if lastColumn == 0 then
						lastColumn = math.min(s.numItems, self.numLateralItems)
					end

					targetIndex = nRows * self.numLateralItems + math.min(lastColumn, column)
				until targetIndex > 0
			else
				targetIndex = index

				if index == 1 and self.sections[targetSection].itemOffsets[1] > 0 then
					targetIndex = 0
				end
			end
		end

		selectionDirection = -1
	elseif direction == FocusManager.BOTTOM then
		targetIndex = index + self.numLateralItems

		if section.numItems < targetIndex then
			local numRows = math.floor((section.numItems - 1) / self.numLateralItems) + 1

			if section.numItems % self.numLateralItems ~= 0 and row < numRows then
				targetIndex = section.numItems
			elseif sectionIndex < #self.sections then
				targetSection = sectionIndex

				repeat
					targetSection = targetSection + 1

					if targetSection > #self.sections then
						return true
					end

					targetIndex = math.min(self.sections[targetSection].numItems, column)
				until targetIndex ~= 0
			else
				targetIndex = index
			end
		end

		selectionDirection = 1
	elseif direction == FocusManager.LEFT then
		if column > 1 then
			targetIndex = index - 1
		end

		selectionDirection = -1
	elseif direction == FocusManager.RIGHT then
		local itemsInRow = self.numLateralItems
		local numRows = math.floor(section.numItems / self.numLateralItems)
		local lastColumnLength = section.numItems % self.numLateralItems

		if lastColumnLength > 0 then
			numRows = numRows + 1
		else
			lastColumnLength = self.numLateralItems
		end

		if row == numRows then
			itemsInRow = lastColumnLength
		end

		if column < itemsInRow then
			targetIndex = index + 1
		end

		selectionDirection = 1
	end

	if targetSection ~= sectionIndex or targetIndex ~= index then
		if targetIndex == 0 then
			self:makeCellVisible(targetSection, 0)
		else
			self:setSelectedItem(targetSection, targetIndex, nil, selectionDirection)
		end

		return false
	else
		return true
	end
end

function SmoothListElement:canReceiveFocus()
	return self:getIsVisible() and self.handleFocus and not self.disabled and self.totalItemCount > 0
end

function SmoothListElement:onFocusActivate()
	if self.totalItemCount == 0 then
		return
	end

	if self.onClickCallback ~= nil then
		self:notifyClick(self.selectedSectionIndex, self.selectedIndex, nil)

		return
	end

	if self.onDoubleClickCallback ~= nil then
		self:notifyDoubleClick(self.selectedSectionIndex, self.selectedIndex, nil)

		return
	end
end

function SmoothListElement:onFocusEnter()
	if not self.selectedWithoutFocus then
		self:applyElementSelection()

		if self.delegate.onListSelectionChanged ~= nil then
			self.delegate:onListSelectionChanged(self, self.selectedSectionIndex, self.selectedIndex)
		end
	end
end

function SmoothListElement:onFocusLeave()
	if not self.selectedWithoutFocus then
		self:clearElementSelection()
	end

	SmoothListElement:superClass().onFocusLeave(self)
end
