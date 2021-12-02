ScrollingLayoutElement = {}
local ScrollingLayoutElement_mt = Class(ScrollingLayoutElement, BoxLayoutElement)

function ScrollingLayoutElement.new(target, custom_mt)
	local self = BoxLayoutElement.new(target, custom_mt or ScrollingLayoutElement_mt)
	self.alignmentX = BoxLayoutElement.ALIGN_LEFT
	self.alignmentY = BoxLayoutElement.ALIGN_TOP
	self.clipping = true
	self.wrapAround = true
	self.sliderElement = nil
	self.firstVisibleY = 0
	self.targetFirstVisibleY = 0
	self.contentSize = 1

	return self
end

function ScrollingLayoutElement:loadFromXML(xmlFile, key)
	ScrollingLayoutElement:superClass().loadFromXML(self, xmlFile, key)

	self.topClipperElementName = getXMLString(xmlFile, key .. "#topClipperElementName")
	self.bottomClipperElementName = getXMLString(xmlFile, key .. "#bottomClipperElementName")
end

function ScrollingLayoutElement:copyAttributes(src)
	ScrollingLayoutElement:superClass().copyAttributes(self, src)

	self.topClipperElementName = src.topClipperElementName
	self.bottomClipperElementName = src.bottomClipperElementName
end

function ScrollingLayoutElement:onGuiSetupFinished()
	ScrollingLayoutElement:superClass().onGuiSetupFinished(self)

	if self.topClipperElementName ~= nil then
		self.topClipperElement = self.parent:getDescendantByName(self.topClipperElementName)
	end

	if self.bottomClipperElementName ~= nil then
		self.bottomClipperElement = self.parent:getDescendantByName(self.bottomClipperElementName)
	end

	for _, e in pairs(self.elements) do
		self:addFocusListener(e)
	end
end

function ScrollingLayoutElement:invalidateLayout(ignoreVisibility)
	local cells = self:getLayoutCells(ignoreVisibility)
	local lateralFlowSizes, totalLateralSize, flowSize = self:getLayoutSizes(cells)
	local offsetStartX, offsetStartY, xDir, yDir = self:getAlignmentOffset(flowSize, totalLateralSize)
	offsetStartY = offsetStartY + self.firstVisibleY

	self:applyCellPositions(cells, offsetStartX, offsetStartY, xDir, yDir, lateralFlowSizes)

	if self.handleFocus and self.focusDirection ~= BoxLayoutElement.FLOW_NONE then
		self:focusLinkCells(cells)
	end

	self:updateContentSize()
	self:updateScrollClippers()

	for _, e in pairs(self.elements) do
		self:addFocusListener(e)
	end

	return flowSize
end

function ScrollingLayoutElement:updateScrollClippers(initial)
	if self.topClipperElement ~= nil then
		local visible = self.firstVisibleY > 0.01

		self.topClipperElement:setVisible(visible)
	end

	if self.bottomClipperElement ~= nil then
		local visible = self.firstVisibleY - (self.contentSize - self.absSize[2]) < -0.01

		self.bottomClipperElement:setVisible(visible)
	end
end

function ScrollingLayoutElement:onSliderValueChanged(slider, newValue)
	local newStartY = (self.contentSize - self.absSize[2]) / (slider.maxValue - slider.minValue) * (newValue - slider.minValue)

	self:scrollTo(newStartY, false)
end

function ScrollingLayoutElement:scrollTo(startY, updateSlider, noUpdateTarget)
	self.firstVisibleY = startY

	if not noUpdateTarget then
		self.targetFirstVisibleY = startY
		self.isMovingToTarget = false
	end

	self:invalidateLayout()

	if (updateSlider == nil or updateSlider) and self.sliderElement ~= nil then
		local newValue = startY / ((self.contentSize - self.absSize[2]) / self.sliderElement.maxValue)

		self.sliderElement:setValue(newValue, true)
	end

	self:raiseCallback("onScrollCallback")
end

function ScrollingLayoutElement:smoothScrollTo(offset)
	offset = math.max(math.min(offset, self.contentSize - self.absSize[2]), 0)
	self.targetFirstVisibleY = offset
	self.isMovingToTarget = true
end

function ScrollingLayoutElement:updateContentSize()
	local cells = self:getLayoutCells()
	local _, _, flowSize = self:getLayoutSizes(cells)
	self.contentSize = flowSize
	self.firstVisibleY = math.max(math.min(self.firstVisibleY, self.contentSize), 0)
	self.targetFirstVisibleY = math.max(math.min(self.targetFirstVisibleY, self.contentSize), 0)

	self:raiseSliderUpdateEvent()
end

function ScrollingLayoutElement:getNeedsScrolling()
	return self.absSize[2] < self.contentSize
end

function ScrollingLayoutElement:raiseSliderUpdateEvent()
	if self.sliderElement ~= nil then
		self.sliderElement:onBindUpdate(self)
	end
end

function ScrollingLayoutElement:addElement(element)
	ScrollingLayoutElement:superClass().addElement(self, element)

	if self.autoValidateLayout then
		self:invalidateLayout()
	end
end

function ScrollingLayoutElement:addFocusListener(element)
	element = element:findFirstFocusable(true)

	if element.scrollingFocusEnter_orig == nil then
		element.scrollingFocusEnter_orig = element.onFocusEnter
	end

	function element.onFocusEnter(e)
		e:scrollingFocusEnter_orig()
		self:scrollToMakeElementVisible(e)
	end
end

function ScrollingLayoutElement:removeElement(element)
	ScrollingLayoutElement:superClass().removeElement(self, element)

	if element.scrollingFocusEnter_orig == nil then
		element.onFocusEnter = element.scrollingFocusEnter_orig
	end

	if self.autoValidateLayout then
		self:invalidateLayout()
	end
end

function ScrollingLayoutElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		if ScrollingLayoutElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
			eventUsed = true
		end

		if not GS_IS_CONSOLE_VERSION then
			self.useMouse = true
		end

		if not eventUsed and GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2]) then
			local deltaIndex = 0

			if Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_UP) then
				deltaIndex = -1
			elseif Input.isMouseButtonPressed(Input.MOUSE_BUTTON_WHEEL_DOWN) then
				deltaIndex = 1
			end

			if deltaIndex ~= 0 then
				self:smoothScrollTo(self.targetFirstVisibleY + deltaIndex * self.contentSize * 0.05)
			end

			eventUsed = true
		end
	end

	return eventUsed
end

function ScrollingLayoutElement:scrollToMakeElementVisible(element)
	local min = self.absPosition[2]
	local max = self.absPosition[2] + self.absSize[2] - element.absSize[2]
	local alreadyInView = min <= element.absPosition[2] and element.absPosition[2] <= max

	if not alreadyInView then
		local diffPlus = min - element.absPosition[2]
		local diffMin = max - element.absPosition[2]
		local newY = nil

		if element.absPosition[2] < self.absPosition[2] + self.absSize[2] / 2 then
			newY = self.firstVisibleY + diffPlus + 0.01
		else
			newY = self.firstVisibleY + diffMin - 0.01
		end

		newY = MathUtil.clamp(newY, 0, self.contentSize - self.absSize[2])

		self:smoothScrollTo(newY, true)
	end
end

function ScrollingLayoutElement:registerActionEvents()
	g_inputBinding:registerActionEvent(InputAction.MENU_AXIS_UP_DOWN_SECONDARY, self, self.onVerticalCursorInput, false, false, true, true)
end

function ScrollingLayoutElement:removeActionEvents()
	g_inputBinding:removeActionEventsByTarget(self)
end

function ScrollingLayoutElement:onVerticalCursorInput(_, inputValue)
	if not self.useMouse then
		self.sliderElement:setValue(self.sliderElement.currentValue + self.sliderElement.stepSize * inputValue)
	end

	self.useMouse = false
end

function ScrollingLayoutElement:update(dt)
	ScrollingLayoutElement:superClass().update(self, dt)

	if self.isMovingToTarget then
		local offset = nil

		if self:getIsVisible() then
			offset = self.firstVisibleY + (self.targetFirstVisibleY - self.firstVisibleY) * 0.01 * dt

			if math.abs(self.targetFirstVisibleY - offset) < 0.0005 then
				self.isMovingToTarget = false
			end
		else
			offset = self.targetFirstVisibleY
			self.isMovingToTarget = false
		end

		self:scrollTo(offset, nil, true)
	end
end
