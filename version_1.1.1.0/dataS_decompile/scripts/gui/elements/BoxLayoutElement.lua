BoxLayoutElement = {}
local BoxLayoutElement_mt = Class(BoxLayoutElement, BitmapElement)
BoxLayoutElement.ALIGN_LEFT = 0
BoxLayoutElement.ALIGN_CENTER = 1
BoxLayoutElement.ALIGN_RIGHT = 2
BoxLayoutElement.ALIGN_TOP = 0
BoxLayoutElement.ALIGN_MIDDLE = 1
BoxLayoutElement.ALIGN_BOTTOM = 2
BoxLayoutElement.FLOW_VERTICAL = "vertical"
BoxLayoutElement.FLOW_HORIZONTAL = "horizontal"
BoxLayoutElement.FLOW_NONE = "none"
BoxLayoutElement.FLOW_DIRECTION_POSITIVE = 1
BoxLayoutElement.FLOW_DIRECTION_NEGATIVE = -1
BoxLayoutElement.LAYOUT_TOLERANCE = 0.1
BoxLayoutElement.FLOW_INDICES = {
	[BoxLayoutElement.FLOW_VERTICAL] = {
		ELEMENT_SIZE = 2,
		LAYOUT_FLOW_SIZE = 2,
		FLOW_MARGIN_LOWER = GuiElement.MARGIN_LEFT,
		FLOW_MARGIN_UPPER = GuiElement.MARGIN_RIGHT,
		ELEMENT_MARGIN_LOWER = GuiElement.MARGIN_TOP,
		ELEMENT_MARGIN_UPPER = GuiElement.MARGIN_BOTTOM
	},
	[BoxLayoutElement.FLOW_HORIZONTAL] = {
		ELEMENT_SIZE = 1,
		LAYOUT_FLOW_SIZE = 1,
		FLOW_MARGIN_LOWER = GuiElement.MARGIN_TOP,
		FLOW_MARGIN_UPPER = GuiElement.MARGIN_BOTTOM,
		ELEMENT_MARGIN_LOWER = GuiElement.MARGIN_LEFT,
		ELEMENT_MARGIN_UPPER = GuiElement.MARGIN_RIGHT
	}
}
BoxLayoutElement.FLOW_LATERAL_TABLE = {
	[BoxLayoutElement.FLOW_VERTICAL] = BoxLayoutElement.FLOW_HORIZONTAL,
	[BoxLayoutElement.FLOW_HORIZONTAL] = BoxLayoutElement.FLOW_VERTICAL
}

function BoxLayoutElement.new(target, custom_mt)
	if custom_mt == nil then
		custom_mt = BoxLayoutElement_mt
	end

	local self = BitmapElement.new(target, custom_mt)
	self.alignmentX = BoxLayoutElement.ALIGN_LEFT
	self.alignmentY = BoxLayoutElement.ALIGN_TOP
	self.autoValidateLayout = false
	self.useFullVisibility = true
	self.wrapAround = false
	self.flowDirection = BoxLayoutElement.FLOW_VERTICAL
	self.numFlows = 1
	self.lateralFlowSize = 0.5
	self.fitFlowToElements = false
	self.flowMargin = {
		0,
		0,
		0,
		0
	}
	self.layoutToleranceY = 0
	self.layoutToleranceX = 0
	self.rememberLastFocus = false
	self.lastFocusElement = nil
	self.incomingFocusTargets = {}
	self.defaultFocusTarget = nil

	return self
end

function BoxLayoutElement:loadFromXML(xmlFile, key)
	BoxLayoutElement:superClass().loadFromXML(self, xmlFile, key)

	local alignmentX = getXMLString(xmlFile, key .. "#alignmentX")

	if alignmentX ~= nil then
		alignmentX = alignmentX:lower()

		if alignmentX == "right" then
			self.alignmentX = BoxLayoutElement.ALIGN_RIGHT
		elseif alignmentX == "center" then
			self.alignmentX = BoxLayoutElement.ALIGN_CENTER
		else
			self.alignmentX = BoxLayoutElement.ALIGN_LEFT
		end
	end

	local alignmentY = getXMLString(xmlFile, key .. "#alignmentY")

	if alignmentY ~= nil then
		alignmentY = alignmentY:lower()

		if alignmentY == "bottom" then
			self.alignmentY = BoxLayoutElement.ALIGN_BOTTOM
		elseif alignmentY == "middle" then
			self.alignmentY = BoxLayoutElement.ALIGN_MIDDLE
		else
			self.alignmentY = BoxLayoutElement.ALIGN_TOP
		end
	end

	self.flowDirection = Utils.getNoNil(getXMLString(xmlFile, key .. "#flowDirection"), self.flowDirection)
	self.focusDirection = getXMLString(xmlFile, key .. "#focusDirection") or self.flowDirection
	self.numFlows = Utils.getNoNil(tonumber(getXMLString(xmlFile, key .. "#numFlows")), self.numFlows)
	self.lateralFlowSize = Utils.getNoNil(GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#lateralFlowSize"), self.outputSize, {
		self.lateralFlowSize
	})[1], self.lateralFlowSize)
	self.flowMargin = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#flowMargin"), self.outputSize, self.flowMargin)
	self.fitFlowToElements = Utils.getNoNil(getXMLBool(xmlFile, key .. "#fitFlowToElements"), self.fitFlowToElements)
	self.autoValidateLayout = Utils.getNoNil(getXMLBool(xmlFile, key .. "#autoValidateLayout"), self.autoValidateLayout)
	self.useFullVisibility = Utils.getNoNil(getXMLBool(xmlFile, key .. "#useFullVisibility"), self.useFullVisibility)
	self.wrapAround = Utils.getNoNil(getXMLBool(xmlFile, key .. "#wrapAround"), self.wrapAround)
	self.rememberLastFocus = Utils.getNoNil(getXMLBool(xmlFile, key .. "#rememberLastFocus"), self.rememberLastFocus)
end

function BoxLayoutElement:loadProfile(profile, applyProfile)
	BoxLayoutElement:superClass().loadProfile(self, profile, applyProfile)

	local alignmentX = profile:getValue("alignmentX")

	if alignmentX ~= nil then
		alignmentX = alignmentX:lower()

		if alignmentX == "right" then
			self.alignmentX = BoxLayoutElement.ALIGN_RIGHT
		elseif alignmentX == "center" then
			self.alignmentX = BoxLayoutElement.ALIGN_CENTER
		else
			self.alignmentX = BoxLayoutElement.ALIGN_LEFT
		end
	end

	local alignmentY = profile:getValue("alignmentY")

	if alignmentY ~= nil then
		alignmentY = alignmentY:lower()

		if alignmentY == "bottom" then
			self.alignmentY = BoxLayoutElement.ALIGN_BOTTOM
		elseif alignmentY == "middle" then
			self.alignmentY = BoxLayoutElement.ALIGN_MIDDLE
		else
			self.alignmentY = BoxLayoutElement.ALIGN_TOP
		end
	end

	local autoValidateLayout = profile:getBool("autoValidateLayout")

	if autoValidateLayout ~= nil then
		self.autoValidateLayout = autoValidateLayout
	end

	local useFullVisibility = profile:getBool("useFullVisibility")

	if useFullVisibility ~= nil then
		self.useFullVisibility = useFullVisibility
	end

	self.flowDirection = Utils.getNoNil(profile:getValue("flowDirection"), self.flowDirection)
	self.focusDirection = profile:getValue("focusDirection") or self.flowDirection
	self.numFlows = profile:getNumber("numFlows", self.numFlows)
	self.lateralFlowSize = GuiUtils.getNormalizedValues(profile:getValue("lateralFlowSize", "0px"), self.outputSize, {
		self.lateralFlowSize
	})[1]
	self.flowMargin = GuiUtils.getNormalizedValues(profile:getValue("flowMargin", "0px 0px 0px 0px"), self.outputSize, self.flowMargin)
	self.fitFlowToElements = profile:getBool("fitFlowToElements", self.fitFlowToElements)
	self.wrapAround = profile:getBool("wrapAround", self.wrapAround)
	self.rememberLastFocus = profile:getBool("rememberLastFocus", self.rememberLastFocus)
end

function BoxLayoutElement:copyAttributes(src)
	BoxLayoutElement:superClass().copyAttributes(self, src)

	self.alignmentX = src.alignmentX
	self.alignmentY = src.alignmentY
	self.autoValidateLayout = src.autoValidateLayout
	self.useFullVisibility = src.useFullVisibility
	self.layoutToleranceY = src.layoutToleranceY
	self.layoutToleranceX = src.layoutToleranceX
	self.flowDirection = src.flowDirection
	self.focusDirection = src.focusDirection
	self.numFlows = src.numFlows
	self.lateralFlowSize = src.lateralFlowSize
	self.flowMargin = src.flowMargin
	self.fitFlowToElements = src.fitFlowToElements
	self.wrapAround = src.wrapAround
	self.rememberLastFocus = src.rememberLastFocus
end

function BoxLayoutElement:onGuiSetupFinished()
	BoxLayoutElement:superClass().onGuiSetupFinished(self)

	self.layoutToleranceX = BoxLayoutElement.LAYOUT_TOLERANCE / g_screenWidth
	self.layoutToleranceY = BoxLayoutElement.LAYOUT_TOLERANCE / g_screenHeight

	self:invalidateLayout(false)
end

function BoxLayoutElement:addElement(element)
	BoxLayoutElement:superClass().addElement(self, element)

	if self.autoValidateLayout then
		self:invalidateLayout()
	end
end

function BoxLayoutElement:removeElement(element)
	BoxLayoutElement:superClass().removeElement(self, element)

	if self.autoValidateLayout then
		self:invalidateLayout()
	end
end

function BoxLayoutElement:getIsElementIncluded(element, ignoreVisibility)
	return not element.ignoreLayout and ignoreVisibility or element:getIsVisibleNonRec() and self.useFullVisibility or element.visible and not self.useFullVisibility
end

function BoxLayoutElement:getLayoutCells(ignoreVisibility)
	local indices = BoxLayoutElement.FLOW_INDICES[self.flowDirection]
	local lateralIndices = BoxLayoutElement.FLOW_INDICES[BoxLayoutElement.FLOW_LATERAL_TABLE[self.flowDirection]]
	local cells = {
		{}
	}
	local lateralFlowSize = 0
	local totalLateralSize = 0
	local lateralFlowSizes = {}
	local flowTolerance = self.layoutToleranceX
	local lateralTolerance = self.layoutToleranceY

	if self.flowDirection == BoxLayoutElement.FLOW_VERTICAL then
		lateralTolerance = flowTolerance
		flowTolerance = lateralTolerance
	end

	if not self.fitFlowToElements then
		lateralFlowSize = self.lateralFlowSize + self.flowMargin[indices.FLOW_MARGIN_LOWER] + self.flowMargin[indices.FLOW_MARGIN_UPPER]
		totalLateralSize = self.numFlows * lateralFlowSize
	end

	for i = 1, self.numFlows do
		table.insert(lateralFlowSizes, lateralFlowSize)
	end

	local flowSize = 0
	local currentFlowSize = 0
	local currentFlow = 1
	local count = 1

	for i, element in ipairs(self.elements) do
		if self:getIsElementIncluded(element, ignoreVisibility) then
			local elementFlowSize = element.absSize[indices.ELEMENT_SIZE] + element.margin[indices.ELEMENT_MARGIN_LOWER] + element.margin[indices.ELEMENT_MARGIN_UPPER]
			local elementLateralSize = element.absSize[lateralIndices.ELEMENT_SIZE] + element.margin[lateralIndices.ELEMENT_MARGIN_LOWER] + element.margin[lateralIndices.ELEMENT_MARGIN_UPPER]

			if self.absSize[indices.LAYOUT_FLOW_SIZE] < currentFlowSize + elementFlowSize - flowTolerance and currentFlow < self.numFlows then
				if self.fitFlowToElements then
					lateralFlowSizes[currentFlow] = lateralFlowSize
					totalLateralSize = totalLateralSize + lateralFlowSize
					lateralFlowSize = 0
				end

				currentFlow = currentFlow + 1
				currentFlowSize = 0
				count = 1

				table.insert(cells, {})
			end

			cells[currentFlow][count] = {
				element = element,
				flowSize = elementFlowSize,
				lateralSize = elementLateralSize
			}
			currentFlowSize = currentFlowSize + elementFlowSize
			flowSize = math.max(flowSize, currentFlowSize)

			if self.fitFlowToElements then
				lateralFlowSize = math.max(lateralFlowSize, elementLateralSize)
			end

			count = count + 1
		end
	end

	return cells
end

function BoxLayoutElement:getLayoutSizes(flowCells)
	local indices = BoxLayoutElement.FLOW_INDICES[self.flowDirection]
	local lateralFlowSizes = {}
	local lateralFlowSize = 0
	local totalLateralSize = 0
	local maxFlowSize = 0

	if not self.fitFlowToElements then
		lateralFlowSize = self.lateralFlowSize + self.flowMargin[indices.FLOW_MARGIN_LOWER] + self.flowMargin[indices.FLOW_MARGIN_UPPER]
		totalLateralSize = self.numFlows * lateralFlowSize
	end

	for i = 1, self.numFlows do
		table.insert(lateralFlowSizes, lateralFlowSize)
	end

	for flowIndex, flow in pairs(flowCells) do
		local flowSize = 0
		local lateralSize = 0

		for i, cell in ipairs(flow) do
			flowSize = flowSize + cell.flowSize

			if self.fitFlowToElements then
				lateralFlowSizes[flowIndex] = math.max(lateralFlowSizes[flowIndex], cell.lateralSize + self.flowMargin[indices.FLOW_MARGIN_LOWER] + self.flowMargin[indices.FLOW_MARGIN_UPPER])
			end

			if i == #flow then
				flowSize = flowSize - cell.element.margin[BoxLayoutElement.FLOW_INDICES[self.flowDirection].ELEMENT_MARGIN_UPPER]
			end
		end

		maxFlowSize = math.max(maxFlowSize, flowSize)
	end

	if self.fitFlowToElements then
		for _, v in pairs(lateralFlowSizes) do
			totalLateralSize = totalLateralSize + v
		end
	end

	return lateralFlowSizes, totalLateralSize, maxFlowSize
end

function BoxLayoutElement:getAlignmentOffset(flowSize, totalFlowLateralSize)
	local offsetStartX = 0
	local offsetStartY = 0
	local xDir = BoxLayoutElement.FLOW_DIRECTION_POSITIVE
	local yDir = BoxLayoutElement.FLOW_DIRECTION_POSITIVE
	local w = 0
	local h = 0

	if self.flowDirection == BoxLayoutElement.FLOW_VERTICAL then
		h = flowSize
		w = totalFlowLateralSize
	else
		h = totalFlowLateralSize
		w = flowSize
	end

	if self.alignmentX == BoxLayoutElement.ALIGN_CENTER then
		offsetStartX = self.size[1] * 0.5 - w * 0.5
	elseif self.alignmentX == BoxLayoutElement.ALIGN_RIGHT then
		offsetStartX = self.size[1]
		xDir = BoxLayoutElement.FLOW_DIRECTION_NEGATIVE
	end

	if self.alignmentY == BoxLayoutElement.ALIGN_MIDDLE then
		offsetStartY = self.size[2] * 0.5 + h * 0.5
		yDir = BoxLayoutElement.FLOW_DIRECTION_NEGATIVE
	elseif self.alignmentY == BoxLayoutElement.ALIGN_TOP then
		offsetStartY = self.size[2]
		yDir = BoxLayoutElement.FLOW_DIRECTION_NEGATIVE
	end

	return offsetStartX, offsetStartY, xDir, yDir
end

function BoxLayoutElement:getElementAlignmentOffset(cell, lateralFlowSize, directionX, directionY)
	local element = cell.element
	local cellWidth = 0
	local cellHeight = 0
	local elementWidth = 0
	local elementHeight = 0

	if self.flowDirection == BoxLayoutElement.FLOW_HORIZONTAL then
		cellWidth = cell.flowSize
		cellHeight = lateralFlowSize
		elementWidth = element.absSize[1]
		elementHeight = cell.lateralSize
	else
		cellWidth = lateralFlowSize
		cellHeight = cell.flowSize
		elementWidth = cell.lateralSize
		elementHeight = element.absSize[2]
	end

	local yOrigin = element.anchors[3]
	local xOrigin = element.anchors[1]

	if cell.element.pivot ~= nil then
		yOrigin = element.pivot[2]
		xOrigin = element.pivot[1]
	end

	local offX = 0
	local offY = 0

	if yOrigin > 0.5 then
		if directionY == BoxLayoutElement.FLOW_DIRECTION_POSITIVE then
			offY = cellHeight - element.margin[GuiElement.MARGIN_TOP]
		else
			offY = -element.margin[GuiElement.MARGIN_TOP]
		end
	elseif yOrigin == 0.5 then
		offY = directionY * (cellHeight + element.margin[GuiElement.MARGIN_BOTTOM] - element.margin[GuiElement.MARGIN_TOP]) * 0.5
	elseif directionY == BoxLayoutElement.FLOW_DIRECTION_POSITIVE then
		offY = element.margin[GuiElement.MARGIN_BOTTOM]
	else
		offY = -cellHeight + element.margin[GuiElement.MARGIN_BOTTOM]
	end

	if xOrigin > 0.5 then
		if directionX == BoxLayoutElement.FLOW_DIRECTION_POSITIVE then
			offX = cellWidth - element.margin[GuiElement.MARGIN_RIGHT]
		else
			offX = -element.margin[GuiElement.MARGIN_RIGHT]
		end
	elseif xOrigin == 0.5 then
		offX = directionX * (cellWidth + element.margin[GuiElement.MARGIN_LEFT] - element.margin[GuiElement.MARGIN_RIGHT]) * 0.5
	elseif directionX == BoxLayoutElement.FLOW_DIRECTION_POSITIVE then
		offX = element.margin[GuiElement.MARGIN_LEFT]
	else
		offX = cellWidth - element.margin[GuiElement.MARGIN_RIGHT]
	end

	return offX, offY
end

function BoxLayoutElement:applyCellPositions(flowCells, offsetStartX, offsetStartY, directionX, directionY, lateralFlowSizes)
	local currentOffsetX = offsetStartX
	local currentOffsetY = offsetStartY
	local xLowerMargin = self.flowMargin[GuiElement.MARGIN_LEFT]
	local xUpperMargin = self.flowMargin[GuiElement.MARGIN_RIGHT]
	local yLowerMargin = self.flowMargin[GuiElement.MARGIN_TOP]
	local yUpperMargin = self.flowMargin[GuiElement.MARGIN_BOTTOM]

	if directionX == BoxLayoutElement.FLOW_DIRECTION_NEGATIVE then
		xUpperMargin = xLowerMargin
		xLowerMargin = xUpperMargin
	end

	if directionY == BoxLayoutElement.FLOW_DIRECTION_NEGATIVE then
		yUpperMargin = yLowerMargin
		yLowerMargin = yUpperMargin
	end

	for flowIndex, flow in pairs(flowCells) do
		for i, cell in ipairs(flow) do
			cell.element:setAnchor(0, 0)

			local eOffX, eOffY = self:getElementAlignmentOffset(cell, lateralFlowSizes[flowIndex], directionX, directionY)

			cell.element:setPosition(xLowerMargin + currentOffsetX + eOffX, -yLowerMargin + currentOffsetY + eOffY)

			if self.flowDirection == BoxLayoutElement.FLOW_HORIZONTAL then
				currentOffsetX = currentOffsetX + directionX * cell.flowSize
			else
				currentOffsetY = currentOffsetY + directionY * cell.flowSize
			end
		end

		if self.flowDirection == BoxLayoutElement.FLOW_HORIZONTAL then
			currentOffsetX = offsetStartX
			currentOffsetY = currentOffsetY + directionY * lateralFlowSizes[flowIndex]
		else
			currentOffsetX = currentOffsetX + directionX * lateralFlowSizes[flowIndex]
			currentOffsetY = offsetStartY
		end
	end
end

function BoxLayoutElement:focusLinkCells(flowCells)
	local prevElement, firstElement, lastElement = nil

	for _, flow in pairs(flowCells) do
		for _, cell in pairs(flow) do
			if not firstElement then
				firstElement = cell.element:findFirstFocusable()
				self.defaultFocusTarget = firstElement
			else
				lastElement = cell.element:findFirstFocusable()
			end
		end
	end

	for _, flow in pairs(flowCells) do
		for _, cell in pairs(flow) do
			local element = cell.element:findFirstFocusable()

			self:focusLinkChildElement(element, prevElement, firstElement, lastElement)

			prevElement = element
		end
	end
end

function BoxLayoutElement:focusLinkChildElement(element, previousElement, firstElement, lastElement)
	local previousDirection = FocusManager.TOP
	local nextDirection = FocusManager.BOTTOM

	if self.focusDirection == BoxLayoutElement.FLOW_HORIZONTAL then
		previousDirection = FocusManager.LEFT
		nextDirection = FocusManager.RIGHT
	end

	if previousElement then
		FocusManager:linkElements(previousElement, nextDirection, element)
		FocusManager:linkElements(element, previousDirection, previousElement)
	end

	if element == firstElement then
		self.incomingFocusTargets[previousDirection] = element

		if not self.wrapAround then
			element.focusChangeOverride = FocusManager:getFocusOverrideFunction({
				previousDirection
			}, self, true)
		end
	end

	if element == lastElement then
		self.incomingFocusTargets[nextDirection] = element

		if self.wrapAround then
			FocusManager:linkElements(element, nextDirection, firstElement)
			FocusManager:linkElements(firstElement, previousDirection, element)
		else
			element.focusChangeOverride = FocusManager:getFocusOverrideFunction({
				nextDirection
			}, self, true)
		end
	else
		element.focusChangeOverride = nil
	end
end

function BoxLayoutElement:invalidateLayout(ignoreVisibility)
	local cells = self:getLayoutCells(ignoreVisibility)
	local lateralFlowSizes, totalLateralSize, flowSize = self:getLayoutSizes(cells)
	local offsetStartX, offsetStartY, xDir, yDir = self:getAlignmentOffset(flowSize, totalLateralSize)

	self:applyCellPositions(cells, offsetStartX, offsetStartY, xDir, yDir, lateralFlowSizes)

	if self.handleFocus and self.focusDirection ~= BoxLayoutElement.FLOW_NONE then
		self:focusLinkCells(cells)
	end

	return flowSize
end

function BoxLayoutElement:canReceiveFocus()
	if self.handleFocus then
		for _, v in ipairs(self.elements) do
			if v:canReceiveFocus() then
				return true
			end
		end
	end

	return false
end

function BoxLayoutElement:getFocusTarget(incomingDirection, moveDirection)
	local focus = self.firstDefaultFocusTarget

	if not focus or not focus:canReceiveFocus() then
		for _, element in ipairs(self.elements) do
			if element:canReceiveFocus() then
				focus = element

				break
			end
		end
	end

	if not focus or not focus:canReceiveFocus() then
		focus = self
	end

	if self.rememberLastFocus and self.lastFocusElement ~= nil and self.lastFocusElement:canReceiveFocus() then
		focus = self.lastFocusElement
	else
		local focusTarget = self.incomingFocusTargets[incomingDirection]
		local checkCount = 0

		while focusTarget ~= nil and not focusTarget:canReceiveFocus() and checkCount < #self.elements do
			local next = FocusManager:getElementById(focusTarget.focusChangeData[moveDirection])
			focusTarget = next
			checkCount = checkCount + 1
		end

		focus = focusTarget or focus
	end

	return focus
end

function BoxLayoutElement:onFocusLeave()
	BoxLayoutElement:superClass().onFocusLeave(self)

	if self.rememberLastFocus then
		local lastFocus = FocusManager:getFocusedElement()

		if lastFocus:isChildOf(self) then
			self.lastFocusElement = lastFocus
		end
	end
end
