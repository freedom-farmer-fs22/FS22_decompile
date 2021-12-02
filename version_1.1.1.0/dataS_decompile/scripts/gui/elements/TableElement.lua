TableElement = {
	ROW_REFOCUS_COOLDOWN = 5000,
	NAVIGATION_DELAY = 100,
	NAV_MODE_ROWS = "rows",
	NAV_MODE_CELLS = "cells",
	DataCell = setmetatable({}, Class({
		text = "",
		overrideProfileName = "",
		profileName = "",
		isVisible = true
	})),
	DataRow = setmetatable({
		new = function (id, columnNames)
			local self = {
				id = id,
				columnCells = {}
			}

			for _, colName in pairs(columnNames) do
				self.columnCells[colName] = TableElement.DataCell.new()
			end

			return self
		end
	}, Class({})),
	SortCell = setmetatable({}, Class({
		text = "",
		dataRowIndex = 1
	})),
	TableRow = setmetatable({
		new = function (dataRowIndex, rowElement)
			local self = {
				dataRowIndex = dataRowIndex,
				rowElement = rowElement,
				columnElements = {}
			}

			local function onlyNamed(element)
				return element.name and element.name ~= ""
			end

			local children = rowElement:getDescendants(onlyNamed)

			for _, child in ipairs(children) do
				self.columnElements[child.name] = child
			end

			return self
		end
	}, Class({
		dataRowIndex = 1
	}))
}
local NAV_MODES = {
	[TableElement.NAV_MODE_ROWS] = TableElement.NAV_MODE_ROWS,
	[TableElement.NAV_MODE_CELLS] = TableElement.NAV_MODE_CELLS
}
local TableElement_mt = Class(TableElement, ListElement)

function TableElement.new(target, custom_mt)
	if custom_mt == nil then
		custom_mt = TableElement_mt
	end

	local self = ListElement.new(target, custom_mt)
	self.doesFocusScrollList = true
	self.isHorizontalList = false
	self.useSelectionOnLeave = false
	self.updateSelectionOnOpen = true
	self.periodicUpdate = false
	self.updateInterval = 5000
	self.timeSinceLastUpdate = 0
	self.timeSinceLastInput = 0
	self.columnNames = {}
	self.rowTemplateName = ""
	self.markRows = true
	self.headersList = {}
	self.headersHash = {}
	self.sortingOrder = TableHeaderElement.SORTING_OFF
	self.sortingColumn = nil
	self.sortingAscending = false
	self.numActiveRows = 0
	self.customSortFunction = nil
	self.customSortBeforeData = false
	self.customSortIsFilter = false
	self.data = {}
	self.tableRows = {}
	self.dataView = {}
	self.selectedId = ""
	self.navigationMode = TableElement.NAV_MODE_ROWS
	self.lateInitialization = false
	self.isInitialized = false

	return self
end

function TableElement:loadFromXML(xmlFile, key)
	TableElement:superClass().loadFromXML(self, xmlFile, key)

	local colNames = Utils.getNoNil(getXMLString(xmlFile, key .. "#columnNames"), "")

	for i, name in ipairs(colNames:split(" ")) do
		self.columnNames[name] = name
	end

	self.rowTemplateName = Utils.getNoNil(getXMLString(xmlFile, key .. "#rowTemplateName"), self.rowTemplateName)
	local navMode = getXMLString(xmlFile, key .. "#navigationMode") or self.navigationMode
	self.navigationMode = NAV_MODES[navMode] or self.navigationMode
	self.periodicUpdate = Utils.getNoNil(getXMLBool(xmlFile, key .. "#periodicUpdate"), self.periodicUpdate)
	local updateSeconds = Utils.getNoNil(getXMLFloat(xmlFile, key .. "#updateInterval"), self.updateInterval / 1000)
	self.updateInterval = updateSeconds * 1000
	self.markRows = Utils.getNoNil(getXMLBool(xmlFile, key .. "#markRows"), self.markRows)
	self.lateInitialization = Utils.getNoNil(getXMLBool(xmlFile, key .. "#lateInitialization"), self.lateInitialization)

	self:addCallback(xmlFile, key .. "#onUpdate", "onUpdateCallback")
end

function TableElement:loadProfile(profile, applyProfile)
	TableElement:superClass().loadProfile(self, profile, applyProfile)

	local navMode = profile:getValue("navigationMode", self.navigationMode)
	self.navigationMode = NAV_MODES[navMode] or self.navigationMode
	self.periodicUpdate = profile:getBool("periodicUpdate", self.periodicUpdate)
	local updateSeconds = profile:getNumber("updateInterval", self.updateInterval / 1000)
	self.updateInterval = updateSeconds * 1000
	self.markRows = profile:getBool("markRows", self.markRows)
	self.lateInitialization = profile:getBool("lateInitialization", self.lateInitialization)
end

function TableElement:copyAttributes(src)
	TableElement:superClass().copyAttributes(self, src)

	self.columnNames = src.columnNames
	self.rowTemplateName = src.rowTemplateName
	self.navigationMode = src.navigationMode
	self.periodicUpdate = src.periodicUpdate
	self.updateInterval = src.updateInterval
	self.markRows = src.markRows
	self.onUpdateCallback = src.onUpdateCallback
	self.lateInitialization = src.lateInitialization
	self.isInitialized = src.isInitialized
end

function TableElement:onGuiSetupFinished()
	TableElement:superClass().onGuiSetupFinished(self)

	if not self.lateInitialization then
		self:initialize()
	end
end

function TableElement:initialize()
	if not self.isInitialized then
		local function onlyMyHeaders(element)
			return element.targetTableId and element.targetTableId == self.id
		end

		self.headersList = self.parent:getDescendants(onlyMyHeaders)

		for i, header in ipairs(self.headersList) do
			self.headersHash[header] = i
		end

		self:buildTableRows()
		self:applyAlternatingBackgroundsToRows()
		self:invalidateLayout()
	end

	self.isInitialized = true
end

function TableElement:buildTableRows()
	local function findTemplate(element)
		return element.name == self.rowTemplateName
	end

	local rowTemplate = self:getFirstDescendant(findTemplate)

	if not rowTemplate then
		print("Error: Row template could not be found. Check spelling in configuration. Was looking for name '" .. tostring(self.rowTemplateName) .. "'")
	end

	local moveOutFocusFunction = FocusManager:getFocusOverrideFunction({
		FocusManager.TOP,
		FocusManager.BOTTOM,
		FocusManager.LEFT,
		FocusManager.RIGHT
	}, self, true)

	FocusManager:removeElement(rowTemplate)

	self.tableRows = {}

	for i = 1, self.visibleItems do
		local newRow = rowTemplate:clone(self)

		FocusManager:loadElementFromCustomValues(newRow)
		newRow:setVisible(false)

		newRow.name = ""
		local tableRow = TableElement.TableRow.new(i, newRow)

		table.insert(self.tableRows, tableRow)

		if i == 1 then
			function tableRow.rowElement.focusChangeOverride(target, direction)
				if direction == FocusManager.TOP then
					if self.selectedIndex == 1 then
						return moveOutFocusFunction(target, direction)
					else
						self:scrollTo(self.selectedIndex - 1)

						return true, self
					end
				else
					return nil, 
				end
			end
		elseif i == self.visibleItems then
			function tableRow.rowElement.focusChangeOverride(target, direction)
				if direction == FocusManager.BOTTOM then
					if self.selectedIndex == #self.dataView then
						return moveOutFocusFunction(target, direction)
					else
						self:scrollTo(self.selectedIndex + 1)

						return true, self
					end
				else
					return nil, 
				end
			end
		end
	end

	if self.navigationMode == TableElement.NAV_MODE_CELLS then
		self:processCellElements()
	end

	rowTemplate:delete()
end

function TableElement:processCellElements()
	local cellElements = {}

	for i, row in ipairs(self.tableRows) do
		local rowElements = {}
		cellElements[i] = rowElements

		for _, rowChild in ipairs(row.rowElement.elements) do
			if rowChild:getHandleFocus() and not rowChild.disabled then
				table.insert(rowElements, rowChild)
			end
		end
	end

	local moveOutFromTableOverride = FocusManager:getFocusOverrideFunction({
		FocusManager.TOP,
		FocusManager.BOTTOM,
		FocusManager.LEFT,
		FocusManager.RIGHT
	}, self, true)

	for rowIndex, row in ipairs(cellElements) do
		for colIndex, element in ipairs(row) do
			local prevRow = cellElements[rowIndex - 1]
			local nextRow = cellElements[rowIndex + 1]
			local prevElement = row[colIndex - 1]
			local nextElement = row[colIndex + 1]
			local originalFocusEnter = element.onFocusEnter

			local function rowSelectionWrapper(elementSelf, ...)
				self:setSelectedIndex(self.firstVisibleItem + rowIndex - 1)
				originalFocusEnter(elementSelf, ...)
			end

			element.onFocusEnter = rowSelectionWrapper

			local function focusMoveOverride(elementSelf, direction)
				local moveOut = false
				moveOut = moveOut or not prevElement and direction == FocusManager.LEFT
				moveOut = moveOut or not nextElement and direction == FocusManager.RIGHT
				local topUp = not prevRow and direction == FocusManager.TOP
				local bottomDown = not nextRow and direction == FocusManager.BOTTOM
				moveOut = moveOut or topUp and self.selectedIndex <= 1
				moveOut = moveOut or bottomDown and self.selectedIndex >= #self.dataView
				local stayPut = not moveOut and (topUp or bottomDown)

				if moveOut then
					return moveOutFromTableOverride(elementSelf, direction)
				elseif stayPut then
					return true, elementSelf
				else
					return false, nil
				end
			end

			element.focusChangeOverride = focusMoveOverride

			if prevRow then
				FocusManager:linkElements(element, FocusManager.TOP, prevRow[colIndex])
			end

			if nextRow then
				FocusManager:linkElements(element, FocusManager.BOTTOM, nextRow[colIndex])
			end

			if prevElement then
				FocusManager:linkElements(element, FocusManager.LEFT, prevElement)
			end

			if nextElement then
				FocusManager:linkElements(element, FocusManager.RIGHT, nextElement)
			end
		end
	end
end

function TableElement:updateAlternatingBackground()
end

function TableElement:applyAlternatingBackgroundsToRows()
	if not self.rowBackgroundProfile or self.rowBackgroundProfile == "" or not self.rowBackgroundProfileAlternate or self.rowBackgroundProfileAlternate == "" then
		return
	end

	local function isRowBackground(element)
		return element.profile == self.rowBackgroundProfile or element.profile == self.rowBackgroundProfileAlternate
	end

	local offset = 1
	local rowBackgrounds = self:getDescendants(isRowBackground)

	for i, rowBg in ipairs(rowBackgrounds) do
		if (i + offset) % 2 == 0 then
			rowBg:applyProfile(self.rowBackgroundProfile)
		else
			rowBg:applyProfile(self.rowBackgroundProfileAlternate)
		end
	end
end

function TableElement:addRow(dataRow, refreshView)
	table.insert(self.data, dataRow)
	table.insert(self.dataView, dataRow)

	self.numActiveRows = self.numActiveRows + 1

	if refreshView then
		self:updateView(true)
	end
end

function TableElement:setNumActiveRows(num)
	self.numActiveRows = num
end

function TableElement:removeRow(index, refreshView)
	self.data[index] = nil
	self.numActiveRows = self.numActiveRows - 1

	if refreshView then
		self:updateView(true)
	end
end

function TableElement:clearData(refreshView)
	self.data = {}
	self.dataView = {}
	self.numActiveRows = 0

	if refreshView then
		self:updateView(false)
	end
end

function TableElement:getViewDataCell(rowIndex, colName)
	local row = self.dataView[rowIndex]

	if not row then
		print("Warning: Tried accessing a missing row in view by index '" .. tostring(rowIndex) .. "'.")

		return nil
	end

	local cell = row.columnCells[colName]

	if not cell then
		print("Warning: Tried accessing a missing column in view by name '" .. tostring(colName) .. "'.")

		return nil
	end

	return cell
end

function TableElement:getDataCell(rowIndex, colName)
	local row = self.data[rowIndex]

	if not row then
		print("Warning: Tried accessing a missing row in table by index '" .. tostring(rowIndex) .. "'.")

		return nil
	end

	local cell = row.columnCells[colName]

	if not cell then
		print("Warning: Tried accessing a missing column in table by name '" .. tostring(colName) .. "'.")

		return nil
	end

	return cell
end

function TableElement:setCellText(rowIndex, colName, text, refreshView)
	local cell = self:getDataCell(rowIndex, colName)

	if cell then
		cell.text = text

		if refreshView then
			self:updateView(true)
		end
	end
end

function TableElement:setCellVisibility(rowIndex, colName, isVisible)
	local cell = self:getDataCell(rowIndex, colName)

	if cell then
		cell.isVisible = isVisible
	end
end

function TableElement:setCellOverrideGuiProfile(rowIndex, colName, profileName)
	local cell = self:getDataCell(rowIndex, colName)

	if cell then
		cell.overrideProfileName = profileName
	end
end

function TableElement:disableSorting()
	self.sortingOrder = TableHeaderElement.SORTING_OFF

	for header, _ in pairs(self.headersHash) do
		header:disableSorting()
	end
end

function TableElement:deleteListItems()
	self:clearData(true)
end

function TableElement:onClickHeader(headerElement)
	self.timeSinceLastInput = 0

	for header, _ in pairs(self.headersHash) do
		if headerElement == header then
			local sortingOrder = headerElement:toggleSorting()

			if sortingOrder ~= self.sortingOrder or headerElement.columnName ~= self.sortingColumn then
				self.sortingColumn = headerElement.columnName
				self.sortingOrder = sortingOrder
			end
		else
			header:disableSorting()
		end
	end
end

function TableElement:getSortableColumn(columnName)
	local sortColumn = {}

	for rowKey, row in pairs(self.data) do
		for colName, cell in pairs(row.columnCells) do
			if self.columnNames[colName] and colName == columnName then
				local sortCell = TableElement.SortCell.new()
				sortCell.text = cell.text
				sortCell.value = cell.value
				sortCell.dataRowIndex = rowKey

				table.insert(sortColumn, sortCell)
			end
		end
	end

	return sortColumn
end

function TableElement:setCustomSortFunction(sortFunction, useBeforeData, useAsFilter)
	self.customSortFunction = sortFunction
	self.customSortBeforeData = useBeforeData
	self.customSortIsFilter = useAsFilter
end

function TableElement:setProfileOverrideFilterFunction(filterFunction)
	self.profileOverrideFilterFunction = filterFunction
end

local function makeSortFunc(threeValueSortFunction)
	return function (e1, e2)
		local eval = threeValueSortFunction(e1, e2)

		return eval > 0
	end
end

function TableElement:getSortFunction(isAscending)
	local ascendingSign = isAscending and -1 or 1

	local function sortColumnCellsByData(cell1, cell2)
		local text1 = cell1.text or ""
		local text2 = cell2.text or ""
		local number1 = tonumber(text1)
		local number2 = tonumber(text2)

		if number1 and number2 then
			return (number1 - number2) * ascendingSign
		else
			text1 = text1:lower()
			text2 = text2:lower()
			local eval = 0

			if text1 < text2 then
				eval = -1
			elseif text2 < text1 then
				eval = 1
			end

			return eval * ascendingSign
		end
	end

	if self.customSortFunction then
		local customAscendingSign = ascendingSign

		if self.customSortIsFilter then
			customAscendingSign = 1
		end

		local combinedFunction = nil

		if self.customSortBeforeData then
			function combinedFunction(cell1, cell2)
				local eval = self.customSortFunction(cell1, cell2) * customAscendingSign

				if eval == 0 then
					return sortColumnCellsByData(cell1, cell2)
				else
					return eval
				end
			end
		else
			function combinedFunction(cell1, cell2)
				local eval = sortColumnCellsByData(cell1, cell2)

				if eval == 0 then
					return self.customSortFunction(cell1, cell2) * customAscendingSign
				else
					return eval
				end
			end
		end

		return makeSortFunc(combinedFunction)
	else
		return makeSortFunc(sortColumnCellsByData)
	end
end

function TableElement:updateSortedView(columnName, sortingOrder)
	self.dataView = {}

	if sortingOrder ~= TableHeaderElement.SORTING_OFF then
		local sortFunc = self:getSortFunction(sortingOrder == TableHeaderElement.SORTING_ASC)
		local sortColumn = self:getSortableColumn(columnName)

		if not sortColumn then
			sortColumn = {}

			print("Warning: Could not find column name [" .. tostring(columnName) .. "] for sorting. Check screen configuration for header / data mismatches.")
		end

		table.sort(sortColumn, sortFunc)

		for i, sortCell in ipairs(sortColumn) do
			local rowData = self.data[sortCell.dataRowIndex]

			table.insert(self.dataView, rowData)
		end
	else
		for i, rowData in ipairs(self.data) do
			table.insert(self.dataView, self.data[i])
		end
	end
end

function TableElement:invalidateLayout()
	local topPos = self.size[2] - self.listItemStartYOffset - self.listItemHeight
	local leftPos = self.listItemStartXOffset

	for i, tableRow in ipairs(self.tableRows) do
		local elem = tableRow.rowElement
		local y = topPos - (i - 1) * (self.listItemHeight + self.listItemSpacing)

		elem:setVisible(true)
		elem:fadeOut()
		elem:setPosition(leftPos, y)
		elem:reset()
	end

	self:updateRowSelection()
end

function TableElement:updateSelectedIndex()
	if self.selectedIndex == 0 then
		self:setSelectedIndex(1)
	end

	for i, dataRow in ipairs(self.dataView) do
		if dataRow.id == self.selectedId then
			self.selectedIndex = i

			break
		end
	end
end

function TableElement:updateRows()
	for i, tableRow in ipairs(self.tableRows) do
		local dataIndex = self.firstVisibleItem + i - 1

		if dataIndex <= math.min(#self.dataView, self.numActiveRows) then
			tableRow.rowElement:fadeIn()

			local dataRow = self.dataView[dataIndex]
			tableRow.dataRowIndex = dataIndex
			local overrideProfile = self.profileOverrideFilterFunction and self.profileOverrideFilterFunction(dataRow)

			for colName, dataCell in pairs(dataRow.columnCells) do
				local element = tableRow.columnElements[colName]

				element:setVisible(dataCell.isVisible)

				if overrideProfile and dataCell.overrideProfileName ~= "" and element.profile ~= dataCell.overrideProfileName then
					element:applyProfile(dataCell.overrideProfileName)
				elseif not overrideProfile and dataCell.profileName ~= "" and element.profile ~= dataCell.profileName then
					element:applyProfile(dataCell.profileName)
				end

				if dataCell.text ~= element.text and element.setText then
					element:setText(dataCell.text)
				end
			end
		else
			tableRow.rowElement:fadeOut()

			tableRow.dataRowIndex = -1
		end
	end

	self:applyAlternatingBackgroundsToRows()
end

function TableElement:scrollToItemInView(index)
	local indexDiff = index - self.firstVisibleItem
	local belowView = self.visibleItems <= indexDiff
	local selectionOutOfView = indexDiff < 0 or belowView

	if selectionOutOfView then
		if belowView then
			indexDiff = indexDiff - self.visibleItems + 1
		end

		self:scrollTo(self.firstVisibleItem + indexDiff)
	end
end

function TableElement:updateView(refocus)
	if #self.dataView > 0 then
		self:updateSortedView(self.sortingColumn, self.sortingOrder)
		self:updateSelectedIndex()
	end

	self:updateRows()

	if self.sliderElement then
		self.sliderElement:onBindUpdate(self)
	end

	if #self.dataView > 0 then
		if refocus then
			self:scrollToItemInView(self.selectedIndex)
		end

		self:updateRowSelection()
	end
end

function TableElement:getItemIndexByRealRowColumn(realRow, _)
	return MathUtil.clamp(realRow - self.firstVisibleItem + 1, 0, #self.tableRows)
end

function TableElement:setSelectionByRealRowAndColumn(realRow, _)
	local index = self:getItemIndexByRealRowColumn(realRow)

	if index > 0 then
		local tableRow = self.tableRows[index]

		if tableRow.dataRowIndex ~= -1 then
			self:setSelectedIndex(tableRow.dataRowIndex)
		end
	end
end

function TableElement:updateRowSelection()
	local selectedTableRowIndex = 0

	if self.selectedIndex ~= 0 and #self.dataView > 0 then
		for i, tableRow in ipairs(self.tableRows) do
			local selected = self.selectedIndex == tableRow.dataRowIndex and self.markRows

			if tableRow.rowElement.setSelected then
				tableRow.rowElement:setSelected(selected)
			end

			if selected then
				selectedTableRowIndex = i
			end
		end
	end

	return selectedTableRowIndex
end

function TableElement:getItemFactor()
	return 1
end

function TableElement:scrollList(delta)
	if delta ~= 0 then
		self:scrollTo(self.firstVisibleItem + delta)
	end
end

function TableElement:scrollTo(index, updateSlider)
	self.timeSinceLastInput = 0

	if not self.isPaginated then
		index = MathUtil.clamp(index, 1, math.max(1, #self.dataView - self.visibleItems + 1))
	else
		index = MathUtil.clamp(index, 1, math.max(1, #self.dataView))
	end

	if index ~= self.firstVisibleItem then
		self.firstVisibleItem = index

		self:updateRows()

		if self.keepSelectedInView and (self.selectedIndex < self.firstVisibleItem or self.selectedIndex > self.firstVisibleItem + self.visibleItems - 1) then
			if self.selectedIndex < self.firstVisibleItem then
				self:setSelectedIndex(self.firstVisibleItem)
			else
				self:setSelectedIndex(self.firstVisibleItem + self.visibleItems - 1)
			end
		end

		if (updateSlider == nil or updateSlider) and self.sliderElement ~= nil then
			self.sliderElement:setValue(index, true)
		end

		self:updateRowSelection()
	end
end

function TableElement:setSelectedIndex(index, force)
	local numItems = #self.dataView
	local newIndex = MathUtil.clamp(index, 0, numItems)

	if newIndex ~= self.selectedIndex then
		self.lastClickTime = nil
		self.timeSinceLastInput = 0
	end

	local hasChanged = self.selectedIndex ~= newIndex
	self.selectedIndex = newIndex

	if self.selectedIndex ~= 0 then
		self.selectedId = self.dataView[self.selectedIndex].id
	end

	self:scrollToItemInView(self.selectedIndex)

	if hasChanged or force then
		self:raiseCallback("onSelectionChangedCallback", newIndex)
	end

	self:updateRowSelection()
end

function TableElement:getSelectedElement()
	return self.dataView[self.selectedIndex], self.selectedIndex
end

function TableElement:getSelectedTableRow()
	local rowIndex = self.selectedIndex - self.firstVisibleItem + 1

	return self.tableRows[rowIndex]
end

function TableElement:getDataRowForElement(element)
	local posX = element.absPosition[1] + element.size[1] * 0.5
	local posY = element.absPosition[2] + element.size[2] * 0.5
	local tableRow, tableCol = self:getRowColumnForScreenPosition(posX, posY)
	local dataRow, dataCol = self:convertVisualRowColumToReal(tableRow, tableCol)
	local index = self:getItemIndexByRealRowColumn(dataRow)
	local tableRow = self.tableRows[index]

	return self.dataView[tableRow.dataRowIndex]
end

function TableElement:getItemCount()
	return #self.dataView
end

function TableElement:updateItemPositions()
	if self.ignoreUpdate == nil or not self.ignoreUpdate then
		if #self.data > 0 and self.selectedIndex == 0 then
			self.selectedIndex = 1
		end

		self.lastFirstVisibleItem = self.firstVisibleItem
	end
end

function TableElement:shouldFocusChange(direction)
	return direction == FocusManager.LEFT or direction == FocusManager.RIGHT or self.selectedIndex <= 1 or self.selectedIndex >= #self.dataView
end

function TableElement:onFocusEnter()
	if not self.mouseDown then
		self:setSelectedIndex(self.selectedIndex)
	end

	self.timeSinceLastInput = 0

	self:delayNavigationInput()
end

function TableElement:onFocusLeave()
	if self.useSelectionOnLeave and self.selectedIndex ~= nil and self.selectedIndex ~= 0 and self.selectedIndex < self:getItemCount() then
		self:updateRowSelection()
	else
		self:clearElementSelection()
	end

	TableElement:superClass().onFocusLeave(self)
end

function TableElement:getFocusTarget(incomingDirection, moveDirection)
	if self.navigationMode == TableElement.NAV_MODE_CELLS then
		local rowElement = self:getSelectedTableRow().rowElement

		return rowElement
	else
		return self
	end
end

function TableElement:onMouseUp()
	TableElement:superClass().onMouseUp(self)
	self:updateRowSelection()
end

function TableElement:inputEvent(action, value, eventUsed)
	local eventUsed = TableElement:superClass().inputEvent(self, action, value, eventUsed)
	local navModeCells = self.navigationMode == TableElement.NAV_MODE_CELLS
	local pressedUp = action == InputAction.MENU_AXIS_UP_DOWN and g_analogStickVTolerance < value
	local pressedDown = action == InputAction.MENU_AXIS_UP_DOWN and value < -g_analogStickVTolerance
	local locked = pressedUp and FocusManager:isDirectionLocked(FocusManager.TOP) or pressedDown and FocusManager:isDirectionLocked(FocusManager.BOTTOM)

	if not eventUsed and not locked then
		local indexChange = 0

		if self.focusActive then
			if pressedUp and self.selectedIndex > 1 then
				indexChange = -1
			elseif pressedDown and self.selectedIndex < #self.dataView then
				indexChange = 1
			end
		elseif navModeCells then
			local tableRowIndex = self.selectedIndex - self.firstVisibleItem + 1

			if pressedUp and tableRowIndex == 1 and self.selectedIndex > 1 then
				indexChange = -1
			elseif pressedDown and tableRowIndex == self.visibleItems and self.selectedIndex < #self.dataView then
				indexChange = 1
			end
		end

		if not self.doesFocusScrollList and indexChange ~= 0 then
			if self.selectedIndex + indexChange < self.firstVisibleItem then
				indexChange = 0
			elseif self.selectedIndex + indexChange > self.firstVisibleItem + self.visibleItems - 1 then
				indexChange = 0
			end
		end

		if indexChange ~= 0 and not locked then
			self:setSelectedIndex(self.selectedIndex + indexChange)
			self:delayNavigationInput()

			eventUsed = true
		end
	end

	return eventUsed
end

function TableElement:delayNavigationInput()
	FocusManager:lockFocusInput(InputAction.MENU_AXIS_UP_DOWN, TableElement.NAVIGATION_DELAY, 1)
	FocusManager:lockFocusInput(InputAction.MENU_AXIS_UP_DOWN, TableElement.NAVIGATION_DELAY, -1)
end

function TableElement:onSliderValueChanged(slider, newValue)
	self:scrollTo(newValue, false)
end

function TableElement:update(dt)
	TableElement:superClass().update(self, dt)

	self.timeSinceLastInput = self.timeSinceLastInput + dt

	if self.periodicUpdate then
		self.timeSinceLastUpdate = self.timeSinceLastUpdate + dt

		if self.updateInterval <= self.timeSinceLastUpdate then
			self:raiseCallback("onUpdateCallback", self)

			self.timeSinceLastUpdate = 0
		end
	end
end

function TableElement:verifyListItemConfiguration()
end
