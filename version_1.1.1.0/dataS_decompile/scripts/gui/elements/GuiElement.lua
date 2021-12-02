GuiElement = {}
local GuiElement_mt = Class(GuiElement)
GuiElement.SCREEN_ALIGN_LEFT = 1
GuiElement.SCREEN_ALIGN_CENTER = 2
GuiElement.SCREEN_ALIGN_RIGHT = 4
GuiElement.SCREEN_ALIGN_BOTTOM = 8
GuiElement.SCREEN_ALIGN_MIDDLE = 16
GuiElement.SCREEN_ALIGN_TOP = 32
GuiElement.SCREEN_ALIGN_XNONE = 64
GuiElement.SCREEN_ALIGN_YNONE = 128
GuiElement.ORIGIN_LEFT = 1
GuiElement.ORIGIN_CENTER = 2
GuiElement.ORIGIN_RIGHT = 4
GuiElement.ORIGIN_BOTTOM = 8
GuiElement.ORIGIN_MIDDLE = 16
GuiElement.ORIGIN_TOP = 32
GuiElement.MARGIN_LEFT = 1
GuiElement.MARGIN_TOP = 2
GuiElement.MARGIN_RIGHT = 3
GuiElement.MARGIN_BOTTOM = 4
GuiElement.FRAME_LEFT = 1
GuiElement.FRAME_TOP = 2
GuiElement.FRAME_RIGHT = 3
GuiElement.FRAME_BOTTOM = 4
GuiElement.debugOverlay = createImageOverlay("dataS/scripts/shared/graph_pixel.png")

function GuiElement.new(target, custom_mt)
	local self = setmetatable({}, custom_mt or GuiElement_mt)

	self:include(GuiMixin)

	self.elements = {}
	self.target = target

	if target ~= nil then
		self.targetName = target.name
	end

	self.profile = ""
	self.name = nil
	self.screenAlign = 0
	self.screenAlignStr = nil
	self.positionOrigin = 0
	self.positionOriginStr = nil
	self.debugEnabled = false
	self.position = {
		0,
		0
	}
	self.absPosition = {
		0,
		0
	}
	self.absSize = {
		1,
		1
	}
	self.size = {
		1 * g_aspectScaleX,
		1 * g_aspectScaleY
	}
	self.margin = {
		0,
		0,
		0,
		0
	}
	self.anchors = {
		0,
		1,
		0,
		1
	}
	self.outputSize = {
		g_referenceScreenWidth,
		g_referenceScreenHeight
	}
	self.imageSize = {
		1024,
		1024
	}
	self.visible = true
	self.disabled = false
	self.thinLineProtection = true
	self.disallowFlowCut = false
	self.alpha = 1
	self.fadeInTime = 0
	self.fadeOutTime = 0
	self.fadeDirection = 0
	self.newLayer = false
	self.toolTipText = nil
	self.toolTipElementId = nil
	self.toolTipElement = nil
	self.layoutIgnore = false
	self.focusFallthrough = false
	self.clipping = false
	self.hasFrame = false
	self.frameThickness = {
		0,
		0,
		0,
		0
	}
	self.frameColors = {
		[GuiElement.FRAME_LEFT] = {
			1,
			1,
			1,
			1
		},
		[GuiElement.FRAME_TOP] = {
			1,
			1,
			1,
			1
		},
		[GuiElement.FRAME_RIGHT] = {
			1,
			1,
			1,
			1
		},
		[GuiElement.FRAME_BOTTOM] = {
			1,
			1,
			1,
			1
		}
	}
	self.frameOverlayVisible = {
		true,
		true,
		true,
		true
	}
	self.updateChildrenOverlayState = true
	self.overlayState = GuiOverlay.STATE_NORMAL
	self.previousOverlayState = nil
	self.isSoundSuppressed = false
	self.soundDisabled = false
	self.handleFocus = true
	self.focusChangeData = {}
	self.focusId = nil
	self.focusActive = false

	return self
end

function GuiElement:loadFromXML(xmlFile, key)
	local profile = getXMLString(xmlFile, key .. "#profile")

	if profile ~= nil then
		self.profile = profile
		local pro = g_gui:getProfile(profile)

		self:loadProfile(pro)
	end

	self:setId(xmlFile, key)

	self.onCreateArgs = getXMLString(xmlFile, key .. "#onCreateArgs")

	self:addCallback(xmlFile, key .. "#onCreate", "onCreateCallback")
	self:addCallback(xmlFile, key .. "#onOpen", "onOpenCallback")
	self:addCallback(xmlFile, key .. "#onClose", "onCloseCallback")
	self:addCallback(xmlFile, key .. "#onDraw", "onDrawCallback")

	self.name = Utils.getNoNil(getXMLString(xmlFile, key .. "#name"), self.name)
	self.imageSize = GuiUtils.get2DArray(getXMLString(xmlFile, key .. "#imageSize"), self.imageSize)
	self.outputSize = GuiUtils.get2DArray(getXMLString(xmlFile, key .. "#outputSize"), self.outputSize)
	self.position = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#position"), self.outputSize, self.position)
	self.size = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#size"), self.outputSize, self.size)
	self.margin = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#margin"), self.outputSize, self.margin)
	self.pivot = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#pivot"), self.outputSize, self.pivot)
	self.anchors = GuiUtils.get4DArray(getXMLString(xmlFile, key .. "#anchors"), self.anchors)
	self.thinLineProtection = Utils.getNoNil(getXMLBool(xmlFile, key .. "#thinLineProtection"), self.thinLineProtection)
	self.positionOriginStr = Utils.getNoNil(getXMLString(xmlFile, key .. "#positionOrigin"), self.positionOriginStr)
	self.screenAlignStr = Utils.getNoNil(getXMLString(xmlFile, key .. "#screenAlign"), self.screenAlignStr)
	self.visible = Utils.getNoNil(getXMLBool(xmlFile, key .. "#visible"), self.visible)
	self.disabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#disabled"), self.disabled)
	self.newLayer = Utils.getNoNil(getXMLBool(xmlFile, key .. "#newLayer"), self.newLayer)
	self.debugEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#debugEnabled"), self.debugEnabled)
	self.updateChildrenOverlayState = Utils.getNoNil(getXMLBool(xmlFile, key .. "#updateChildrenOverlayState"), self.updateChildrenOverlayState)
	self.toolTipText = getXMLString(xmlFile, key .. "#toolTipText")
	self.toolTipElementId = getXMLString(xmlFile, key .. "#toolTipElementId")
	self.layoutIgnore = Utils.getNoNil(getXMLBool(xmlFile, key .. "#layoutIgnore"), self.layoutIgnore)
	self.clipping = Utils.getNoNil(getXMLBool(xmlFile, key .. "#clipping"), self.clipping)
	self.handleFocus = Utils.getNoNil(getXMLBool(xmlFile, key .. "#handleFocus"), self.handleFocus)
	self.soundDisabled = Utils.getNoNil(getXMLBool(xmlFile, key .. "#soundDisabled"), self.soundDisabled)
	self.focusFallthrough = Utils.getNoNil(getXMLBool(xmlFile, key .. "#focusFallthrough"), self.focusFallthrough)
	self.disallowFlowCut = Utils.getNoNil(getXMLBool(xmlFile, key .. "#disallowFlowCut"), self.disallowFlowCut)
	self.hasFrame = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hasFrame"), self.hasFrame)

	if self.hasFrame then
		local thickness = getXMLString(xmlFile, key .. "#frameThickness")
		self.frameThickness = GuiUtils.getNormalizedValues(thickness, self.outputSize) or self.frameThickness
		local color = getXMLString(xmlFile, key .. "#frameLeftColor")
		self.frameColors[GuiElement.FRAME_LEFT] = GuiUtils.getColorArray(color) or self.frameColors[GuiElement.FRAME_LEFT]
		color = getXMLString(xmlFile, key .. "#frameTopColor")
		self.frameColors[GuiElement.FRAME_TOP] = GuiUtils.getColorArray(color) or self.frameColors[GuiElement.FRAME_TOP]
		color = getXMLString(xmlFile, key .. "#frameRightColor")
		self.frameColors[GuiElement.FRAME_RIGHT] = GuiUtils.getColorArray(color) or self.frameColors[GuiElement.FRAME_RIGHT]
		color = getXMLString(xmlFile, key .. "#frameBottomColor")
		self.frameColors[GuiElement.FRAME_BOTTOM] = GuiUtils.getColorArray(color) or self.frameColors[GuiElement.FRAME_BOTTOM]
	end

	local fadeInTime = getXMLFloat(xmlFile, key .. "#fadeInTime")

	if fadeInTime ~= nil then
		self.fadeInTime = fadeInTime * 1000
	end

	local fadeOutTime = getXMLFloat(xmlFile, key .. "#fadeOutTime")

	if fadeOutTime ~= nil then
		self.fadeOutTime = fadeOutTime * 1000
	end

	if self.toolTipText ~= nil and self.toolTipText:sub(1, 6) == "$l10n_" then
		self.toolTipText = g_i18n:getText(self.toolTipText:sub(7))
	end

	FocusManager:loadElementFromXML(xmlFile, key, self)
	self:verifyConfiguration()
end

function GuiElement:loadProfile(profile, applyProfile)
	local imageSize = profile:getValue("imageSize")

	if imageSize ~= nil then
		local x, y = imageSize:getVector()

		if x ~= nil and y ~= nil then
			self.imageSize = {
				x,
				y
			}
		end
	end

	local outputSize = profile:getValue("outputSize")

	if outputSize ~= nil then
		local x, y = outputSize:getVector()

		if x ~= nil and y ~= nil then
			self.outputSize = {
				x,
				y
			}
		end
	end

	local positionValue = profile:getValue("position")
	self.position = GuiUtils.getNormalizedValues(positionValue, self.outputSize, self.position)
	self.size = GuiUtils.getNormalizedValues(profile:getValue("size"), self.outputSize, self.size)
	self.pivot = GuiUtils.getNormalizedValues(profile:getValue("pivot"), self.outputSize, self.pivot)
	self.margin = GuiUtils.getNormalizedValues(profile:getValue("margin"), self.outputSize, self.margin)
	local anchors = profile:getValue("anchors")

	if anchors ~= nil then
		self.anchors = GuiUtils.get4DArray(anchors, self.anchors)
	end

	self.name = profile:getValue("name", self.name)
	self.positionOriginStr = profile:getValue("positionOrigin", self.positionOriginStr)
	self.screenAlignStr = profile:getValue("screenAlign", self.screenAlignStr)
	self.visible = profile:getBool("visible", self.visible)
	self.disabled = profile:getBool("disabled", self.disabled)
	self.newLayer = profile:getBool("newLayer", self.newLayer)
	self.debugEnabled = profile:getBool("debugEnabled", self.debugEnabled)
	self.updateChildrenOverlayState = profile:getBool("updateChildrenOverlayState", self.updateChildrenOverlayState)
	self.toolTipText = profile:getValue("toolTipText", self.toolTipText)
	self.layoutIgnore = profile:getBool("layoutIgnore", self.layoutIgnore)
	self.thinLineProtection = profile:getBool("thinLineProtection", self.thinLineProtection)
	self.clipping = profile:getBool("clipping", self.clipping)
	self.focusFallthrough = profile:getBool("focusFallthrough", self.focusFallthrough)
	self.disallowFlowCut = profile:getBool("disallowFlowCut", self.disallowFlowCut)
	self.hasFrame = profile:getBool("hasFrame", self.hasFrame)

	if self.hasFrame then
		self.frameThickness = GuiUtils.getNormalizedValues(profile:getValue("frameThickness"), self.outputSize) or self.frameThickness
		self.frameColors[GuiElement.FRAME_LEFT] = GuiUtils.getColorArray(profile:getValue("frameLeftColor"), self.frameColors[GuiElement.FRAME_LEFT])
		self.frameColors[GuiElement.FRAME_TOP] = GuiUtils.getColorArray(profile:getValue("frameTopColor"), self.frameColors[GuiElement.FRAME_TOP])
		self.frameColors[GuiElement.FRAME_RIGHT] = GuiUtils.getColorArray(profile:getValue("frameRightColor"), self.frameColors[GuiElement.FRAME_RIGHT])
		self.frameColors[GuiElement.FRAME_BOTTOM] = GuiUtils.getColorArray(profile:getValue("frameBottomColor"), self.frameColors[GuiElement.FRAME_BOTTOM])
	end

	self.handleFocus = profile:getBool("handleFocus", self.handleFocus)
	self.soundDisabled = profile:getBool("soundDisabled", self.soundDisabled)
	local fadeInTime = profile:getValue("fadeInTime")

	if fadeInTime ~= nil then
		self.fadeInTime = tonumber(fadeInTime) * 1000
	end

	local fadeOutTime = profile:getValue("fadeOutTime")

	if fadeOutTime ~= nil then
		self.fadeOutTime = tonumber(fadeOutTime) * 1000
	end

	if applyProfile then
		self:applyElementAspectScale(positionValue == nil)
		self:fixThinLines()
		self:updateAbsolutePosition()
	end
end

function GuiElement:applyProfile(profileName, force)
	if profileName then
		local pro = g_gui:getProfile(profileName)

		if pro ~= nil then
			self.profile = profileName

			self:loadProfile(pro, not force)
		end
	end
end

function GuiElement:delete()
	for i = #self.elements, 1, -1 do
		self.elements[i].parent = nil

		self.elements[i]:delete()
	end

	if self.parent ~= nil then
		self.parent:removeElement(self)
	end

	FocusManager:removeElement(self)
end

function GuiElement:clone(parent, includeId, suppressOnCreate)
	local ret = self.new()

	ret:copyAttributes(self)

	if parent ~= nil then
		parent:addElement(ret)
	end

	for i = 1, #self.elements do
		local clonedChild = self.elements[i]:clone(ret, includeId, suppressOnCreate)

		if includeId then
			clonedChild.id = self.elements[i].id
		end
	end

	if not suppressOnCreate then
		ret:raiseCallback("onCreateCallback", ret, ret.onCreateArgs)
	end

	return ret
end

function GuiElement:copyAttributes(src)
	self.visible = src.visible
	self.name = src.name
	self.typeName = src.typeName
	self.disabled = src.disabled
	self.positionOrigin = src.positionOrigin
	self.screenAlign = src.screenAlign
	self.newLayer = src.newLayer
	self.debugEnabled = src.debugEnabled
	self.size = table.copy(src.size)
	self.margin = table.copy(src.margin)
	self.onCreateCallback = src.onCreateCallback
	self.onCreateArgs = src.onCreateArgs
	self.onCloseCallback = src.onCloseCallback
	self.onOpenCallback = src.onOpenCallback
	self.onDrawCallback = src.onDrawCallback
	self.target = src.target
	self.targetName = src.targetName
	self.profile = src.profile
	self.outputSize = table.copy(src.outputSize)
	self.imageSize = table.copy(src.imageSize)
	self.fadeInTime = src.fadeInTime
	self.fadeOutTime = src.fadeOutTime
	self.alpha = src.alpha
	self.fadeDirection = src.fadeDirection
	self.updateChildrenOverlayState = src.updateChildrenOverlayState
	self.toolTipElementId = src.toolTipElementId
	self.toolTipText = src.toolTipText
	self.handleFocus = src.handleFocus
	self.clipping = src.clipping
	self.focusFallthrough = src.focusFallthrough
	self.disallowFlowCut = src.disallowFlowCut
	self.ignoreLayout = src.ignoreLayout
	self.soundDisabled = src.soundDisabled
	self.hasFrame = src.hasFrame
	self.frameThickness = src.frameThickness
	self.frameColors = table.copy(src.frameColors, math.huge)
	self.frameOverlayVisible = table.copy(src.frameOverlayVisible)
	self.focusId = src.focusId
	self.focusChangeData = table.copy(src.focusChangeData)
	self.focusActive = src.focusActive
	self.isAlwaysFocusedOnOpen = src.isAlwaysFocusedOnOpen
	self.position = table.copy(src.position)
	self.absPosition = table.copy(src.absPosition)
	self.absSize = table.copy(src.absSize)
	self.anchors = table.copy(src.anchors)
	self.pivot = table.copy(src.pivot)
end

function GuiElement:onGuiSetupFinished()
	for _, elem in ipairs(self.elements) do
		elem:onGuiSetupFinished()
	end

	if self.toolTipElementId ~= nil then
		local toolTipElement = self.target:getDescendantById(self.toolTipElementId)

		if toolTipElement ~= nil then
			self.toolTipElement = toolTipElement
		else
			Logging.warning("toolTipElementId '%s' not found for '%s'!", self.toolTipElementId, self.target.name)
		end
	end
end

function GuiElement:toggleFrameSide(sideIndex, isVisible)
	if self.hasFrame then
		self.frameOverlayVisible[sideIndex] = isVisible
	end
end

function GuiElement:updateFramePosition()
	local x, y = unpack(self.absPosition)
	local width, height = unpack(self.absSize)
	local left = 1
	local top = 2
	local right = 3
	local bottom = 4
	self.frameBounds = {
		[left] = {
			x = x,
			y = y,
			width = self.frameThickness[left],
			height = height
		},
		[top] = {
			x = x,
			y = y + height - self.frameThickness[top],
			width = width,
			height = self.frameThickness[top]
		},
		[right] = {
			x = x + width - self.frameThickness[right],
			y = y,
			width = self.frameThickness[right],
			height = height
		},
		[bottom] = {
			x = x,
			y = y,
			width = width,
			height = self.frameThickness[bottom]
		}
	}

	self:cutFrameBordersHorizontal(self.frameBounds[left], self.frameBounds[top], true)
	self:cutFrameBordersHorizontal(self.frameBounds[left], self.frameBounds[bottom], true)
	self:cutFrameBordersHorizontal(self.frameBounds[right], self.frameBounds[top], false)
	self:cutFrameBordersHorizontal(self.frameBounds[right], self.frameBounds[bottom], false)
	self:cutFrameBordersVertical(self.frameBounds[bottom], self.frameBounds[left], true)
	self:cutFrameBordersVertical(self.frameBounds[bottom], self.frameBounds[right], true)
	self:cutFrameBordersVertical(self.frameBounds[top], self.frameBounds[left], false)
	self:cutFrameBordersVertical(self.frameBounds[top], self.frameBounds[right], false)
end

function GuiElement:cutFrameBordersHorizontal(verticalPart, horizontalPart, isLeft)
	if horizontalPart.height < verticalPart.width then
		if isLeft then
			horizontalPart.x = horizontalPart.x + verticalPart.width
		end

		horizontalPart.width = horizontalPart.width - verticalPart.width
	end
end

function GuiElement:cutFrameBordersVertical(horizontalPart, verticalPart, isBottom)
	if verticalPart.height <= horizontalPart.width then
		if isBottom then
			verticalPart.y = verticalPart.y + horizontalPart.height
		end

		verticalPart.height = verticalPart.height - horizontalPart.height
	end
end

function GuiElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if eventUsed == nil then
		eventUsed = false
	end

	if self.visible then
		for i = #self.elements, 1, -1 do
			local v = self.elements[i]

			if v:mouseEvent(posX, posY, isDown, isUp, button, eventUsed) then
				eventUsed = true
			end
		end
	end

	return eventUsed
end

function GuiElement:inputEvent(action, value, eventUsed)
	if not eventUsed then
		eventUsed = self.parent and self.parent:inputEvent(action, value, eventUsed)

		if eventUsed == nil then
			eventUsed = false
		end
	end

	return eventUsed
end

function GuiElement:inputReleaseEvent(action, eventUsed)
	if not eventUsed then
		eventUsed = self.parent and self.parent:inputReleaseEvent(action, eventUsed)

		if eventUsed == nil then
			eventUsed = false
		end
	end

	return eventUsed
end

function GuiElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
	if eventUsed == nil then
		eventUsed = false
	end

	if self.visible then
		for i = #self.elements, 1, -1 do
			local v = self.elements[i]

			if v:keyEvent(unicode, sym, modifier, isDown, eventUsed) then
				eventUsed = true
			end
		end
	end

	return eventUsed
end

function GuiElement:update(dt)
	if self.fadeDirection ~= 0 then
		if self.fadeDirection > 0 then
			self:setAlpha(self.alpha + self.fadeDirection * dt / self.fadeInTime)
		else
			self:setAlpha(self.alpha + self.fadeDirection * dt / self.fadeOutTime)
		end
	end

	for i = 1, #self.elements do
		local child = self.elements[i]

		if child:getIsActiveNonRec() then
			child:update(dt)
		end
	end
end

function GuiElement:draw(clipX1, clipY1, clipX2, clipY2)
	if self.newLayer then
		new2DLayer()
	end

	clipX1, clipY1, clipX2, clipY2 = self:getClipArea(clipX1, clipY1, clipX2, clipY2)

	self:raiseCallback("onDrawCallback", self)

	if self.debugEnabled or g_uiDebugEnabled then
		local xPixel = 1 / g_screenWidth
		local yPixel = 1 / g_screenHeight

		drawFilledRect(self.absPosition[1] - xPixel, self.absPosition[2] - yPixel, self.absSize[1] + 2 * xPixel, yPixel, 1, 0, 0, 1)
		drawFilledRect(self.absPosition[1] - xPixel, self.absPosition[2] + self.absSize[2], self.absSize[1] + 2 * xPixel, yPixel, 1, 0, 0, 1)
		drawFilledRect(self.absPosition[1] - xPixel, self.absPosition[2], xPixel, self.absSize[2], 1, 0, 0, 1)
		drawFilledRect(self.absPosition[1] + self.absSize[1], self.absPosition[2], xPixel, self.absSize[2], 1, 0, 0, 1)
	end

	for i = 1, #self.elements do
		local child = self.elements[i]

		if child:getIsVisibleNonRec() then
			child:draw(child:getClipArea(clipX1, clipY1, clipX2, clipY2))
		end
	end

	if self.hasFrame then
		for i = 1, 4 do
			if self.frameOverlayVisible[i] then
				local frame = self.frameBounds[i]
				local color = self.frameColors[i]

				drawFilledRect(frame.x, frame.y, frame.width, frame.height, color[1], color[2], color[3], color[4], clipX1, clipY1, clipX2, clipY2)
			end
		end
	end
end

function GuiElement:onOpen()
	self:raiseCallback("onOpenCallback", self)

	for i = 1, #self.elements do
		local child = self.elements[i]

		child:onOpen()
	end
end

function GuiElement:onClose()
	self:raiseCallback("onCloseCallback", self)

	for i = 1, #self.elements do
		local child = self.elements[i]

		child:onClose()
	end
end

function GuiElement:shouldFocusChange(direction)
	for _, v in ipairs(self.elements) do
		if not v:shouldFocusChange(direction) then
			return false
		end
	end

	return true
end

function GuiElement:canReceiveFocus()
	return false
end

function GuiElement:onFocusLeave()
	for i = 1, #self.elements do
		local child = self.elements[i]

		child:onFocusLeave()
	end

	if self.toolTipElement ~= nil and self.toolTipText ~= nil then
		self.toolTipElement:setText("")
	end
end

function GuiElement:onFocusEnter()
	for i = 1, #self.elements do
		local child = self.elements[i]

		child:onFocusEnter()
	end

	if self.toolTipElement ~= nil and self.toolTipText ~= nil then
		self.toolTipElement:setText(self.toolTipText)
	end
end

function GuiElement:onFocusActivate()
	for i = 1, #self.elements do
		local child = self.elements[i]

		if child.handleFocus then
			child:onFocusActivate()
		end
	end
end

function GuiElement:onHighlight()
	for i = 1, #self.elements do
		local child = self.elements[i]

		child:onHighlight()
	end

	if self.toolTipElement ~= nil and self.toolTipText ~= nil then
		self.toolTipElement:setText(self.toolTipText)
	end
end

function GuiElement:onHighlightRemove()
	for i = 1, #self.elements do
		local child = self.elements[i]

		child:onHighlightRemove()
	end

	if self.toolTipElement ~= nil and self.toolTipText ~= nil then
		self.toolTipElement:setText("")
	end
end

function GuiElement:storeOverlayState()
	self.previousOverlayState = self:getOverlayState()
end

function GuiElement:restoreOverlayState()
	if self.previousOverlayState then
		self:setOverlayState(self.previousOverlayState)

		self.previousOverlayState = nil
	end
end

function GuiElement:getHandleFocus()
	return self.handleFocus
end

function GuiElement:setHandleFocus(handleFocus)
	self.handleFocus = handleFocus
end

function GuiElement:addElement(element)
	if element.parent ~= nil then
		element.parent:removeElement(element)
	end

	table.insert(self.elements, element)

	element.parent = self
end

function GuiElement:removeElement(element)
	for i = 1, #self.elements do
		local child = self.elements[i]

		if child == element then
			table.remove(self.elements, i)

			element.parent = nil

			break
		end
	end
end

function GuiElement:unlinkElement()
	if self.parent ~= nil then
		self.parent:removeElement(self)
	end
end

function GuiElement:updateAbsolutePosition()
	local borders = self:getParentBorders()
	local ax1 = borders[1] + (borders[3] - borders[1]) * self.anchors[1]
	local ax2 = borders[1] + (borders[3] - borders[1]) * self.anchors[2]
	local ay1 = borders[2] + (borders[4] - borders[2]) * self.anchors[3]
	local ay2 = borders[2] + (borders[4] - borders[2]) * self.anchors[4]
	local tlX = ax1 + self.position[1]
	local tlY = ay1 + self.position[2]
	local trX = ax2 + self.position[1]
	local blY = ay2 + self.position[2]
	local isStretchingX = self.anchors[1] < self.anchors[2]
	local isStretchingY = self.anchors[3] < self.anchors[4]
	local width = self.size[1]
	local height = self.size[2]

	if not isStretchingX then
		if self.pivot ~= nil then
			tlX = tlX - width * self.pivot[1]
			trX = trX + width - width * self.pivot[1]
		else
			tlX = tlX - width * self.anchors[1]
			trX = trX + width - width * self.anchors[2]
		end
	end

	if not isStretchingY then
		if self.pivot ~= nil then
			tlY = tlY - height * self.pivot[2]
			blY = blY + height - height * self.pivot[2]
		else
			tlY = tlY - height * self.anchors[3]
			blY = blY + height - height * self.anchors[4]
		end
	end

	self.absPosition[1] = tlX
	self.absPosition[2] = tlY
	self.absSize[1] = trX - tlX
	self.absSize[2] = blY - tlY

	for i = 1, #self.elements do
		self.elements[i]:updateAbsolutePosition()
	end

	if self.hasFrame then
		self:updateFramePosition()
	end
end

function GuiElement:reset()
	for i = 1, #self.elements do
		self.elements[i]:reset()
	end
end

function GuiElement:isChildOf(element)
	if element == self then
		return false
	end

	local p = self.parent

	while p do
		if p == self then
			return false
		end

		if p == element then
			return true
		end

		p = p.parent
	end

	return false
end

function GuiElement:getFocusTarget(incomingDirection, moveDirection)
	return self
end

function GuiElement:setPosition(x, y)
	self.position[1] = Utils.getNoNil(x, self.position[1])
	self.position[2] = Utils.getNoNil(y, self.position[2])

	self:updateAbsolutePosition()
end

function GuiElement:move(dx, dy)
	self.position[1] = self.position[1] + dx
	self.position[2] = self.position[2] + dy

	self:updateAbsolutePosition()
end

function GuiElement:setAbsolutePosition(x, y)
	local xDif = x - self.absPosition[1]
	local yDif = y - self.absPosition[2]
	self.absPosition[1] = x
	self.absPosition[2] = y

	for i = 1, #self.elements do
		local child = self.elements[i]

		child:setAbsolutePosition(child.absPosition[1] + xDif, child.absPosition[2] + yDif)
	end

	if self.hasFrame then
		self:updateFramePosition()
	end
end

function GuiElement:setSize(x, y)
	x = Utils.getNoNil(x, self.size[1])
	y = Utils.getNoNil(y, self.size[2])

	if self.thinLineProtection then
		if x ~= 0 then
			x = math.max(x, 1 / g_screenWidth)
		end

		if y ~= 0 then
			y = math.max(y, 1 / g_screenHeight)
		end
	end

	self.size[1] = x
	self.size[2] = y

	self:updateAbsolutePosition()
end

function GuiElement:setVisible(visible)
	self.visible = visible
end

function GuiElement:getIsVisible()
	if not self.visible or self.alpha == 0 then
		return false
	end

	if self.parent ~= nil then
		return self.parent:getIsVisible()
	end

	return true
end

function GuiElement:getIsVisibleNonRec()
	return self.visible and self.alpha > 0
end

function GuiElement:setDisabled(disabled, doNotUpdateChildren)
	self.disabled = disabled

	if doNotUpdateChildren == nil or not doNotUpdateChildren then
		for i = 1, #self.elements do
			self.elements[i]:setDisabled(disabled)
		end
	end
end

function GuiElement:getIsDisabled()
	return self.disabled
end

function GuiElement:getIsSelected()
	if self.parent ~= nil then
		return self.parent:getIsSelected()
	end

	return false
end

function GuiElement:getIsHighlighted()
	if self.parent ~= nil then
		return self.parent:getIsHighlighted()
	end

	return false
end

function GuiElement:fadeIn(factor)
	if self.fadeInTime > 0 then
		self.fadeDirection = 1 * Utils.getNoNil(factor, 1)

		self:setAlpha(math.max(self.alpha, 0.0001))
	else
		self.fadeDirection = 0

		self:setAlpha(1)
	end
end

function GuiElement:fadeOut(factor)
	if self.fadeOutTime > 0 then
		self.fadeDirection = -1 * Utils.getNoNil(factor, 1)
	else
		self.fadeDirection = 0

		self:setAlpha(0)
	end
end

function GuiElement:setAlpha(alpha)
	if alpha ~= self.alpha then
		self.alpha = MathUtil.clamp(alpha, 0, 1)

		for _, childElem in pairs(self.elements) do
			childElem:setAlpha(self.alpha)
		end

		if self.alpha == 1 or self.alpha == 0 then
			self.fadeDirection = 0
		end
	end
end

function GuiElement:getIsActive()
	return not self.disabled and self:getIsVisible()
end

function GuiElement:getIsActiveNonRec()
	return not self.disabled and self:getIsVisibleNonRec()
end

function GuiElement:getClipArea(clipX1, clipY1, clipX2, clipY2)
	if self.clipping then
		clipX1 = math.max(clipX1 or 0, self.absPosition[1])
		clipY1 = math.max(clipY1 or 0, self.absPosition[2])
		clipX2 = math.min(clipX2 or 1, self.absPosition[1] + self.absSize[1])
		clipY2 = math.min(clipY2 or 1, self.absPosition[2] + self.absSize[2])
	end

	return clipX1, clipY1, clipX2, clipY2
end

function GuiElement:setSoundSuppressed(doSuppress)
	self.isSoundSuppressed = doSuppress

	for _, child in pairs(self.elements) do
		child:setSoundSuppressed(doSuppress)
	end
end

function GuiElement:getSoundSuppressed()
	return self.isSoundSuppressed
end

function GuiElement:findDescendantsRec(accumulator, rootElement, predicateFunction)
	if not rootElement then
		return
	end

	for _, element in ipairs(rootElement.elements) do
		self:findDescendantsRec(accumulator, element, predicateFunction)

		if not predicateFunction or predicateFunction(element) then
			table.insert(accumulator, element)
		end
	end
end

function GuiElement:getDescendants(predicateFunction)
	local descendants = {}

	self:findDescendantsRec(descendants, self, predicateFunction)

	return descendants
end

function GuiElement:setTarget(target, originalTarget, callOnCreate)
	for i = 1, #self.elements do
		self.elements[i]:setTarget(target, originalTarget, callOnCreate)
	end

	if self.target == originalTarget then
		self.target = target
		self.targetName = target.name

		if callOnCreate then
			self:raiseCallback("onCreateCallback", self, self.onCreateArgs)
		end
	end
end

function GuiElement:getFirstDescendant(predicateFunction)
	local element = nil
	local res = self:getDescendants(predicateFunction)

	if #res > 0 then
		element = res[1]
	end

	return element
end

function GuiElement:getDescendantById(id)
	local element = nil

	if id then
		local function findId(e)
			return e.id and e.id == id
		end

		element = self:getFirstDescendant(findId)
	end

	return element
end

function GuiElement:getDescendantByName(name)
	local element = nil

	if name then
		local function findId(e)
			return e.name and e.name == name
		end

		element = self:getFirstDescendant(findId)
	end

	return element
end

function GuiElement:updatePositionForOrigin(origin)
	if origin == "topLeft" then
		self.pivot = {
			0,
			0
		}
	elseif origin == "topCenter" then
		self.pivot = {
			0.5,
			0
		}
	elseif origin == "topRight" then
		self.pivot = {
			1,
			0
		}
	elseif origin == "middleLeft" then
		self.pivot = {
			0,
			0.5
		}
	elseif origin == "middleCenter" then
		self.pivot = {
			0.5,
			0.5
		}
	elseif origin == "middleRight" then
		self.pivot = {
			1,
			0.5
		}
	elseif origin == "bottomCenter" then
		self.pivot = {
			0,
			1
		}
	elseif origin == "bottomRight" then
		self.pivot = {
			0.5,
			1
		}
	else
		self.pivot = {
			1,
			1
		}
	end
end

function GuiElement:updateScreenAlign(align)
	if align == "topLeft" then
		self:setAnchor(0, 1)
	elseif align == "topCenter" then
		self:setAnchor(0.5, 1)
	elseif align == "topRight" then
		self:setAnchor(1, 1)
	elseif align == "middleLeft" then
		self:setAnchor(0, 0.5)
	elseif align == "middleCenter" then
		self:setAnchor(0.5, 0.5)
	elseif align == "middleRight" then
		self:setAnchor(1, 0.5)
	elseif align == "bottomLeft" then
		self:setAnchor(0, 0)
	elseif align == "bottomCenter" then
		self:setAnchor(0.5, 0)
	elseif align == "bottomRight" then
		self:setAnchor(1, 0)
	else
		self:setAnchors(0, 1, 0, 1)
	end
end

function GuiElement:setAnchor(x, y)
	return self:setAnchors(x, x, y, y)
end

function GuiElement:setAnchors(minX, maxX, minY, maxY)
	self.anchors = {
		minX,
		maxX,
		minY,
		maxY
	}
end

function GuiElement:fixThinLines()
	if self.thinLineProtection then
		if self.size[1] ~= 0 then
			self.size[1] = math.max(self.size[1], 1 / g_screenWidth)
		end

		if self.size[2] ~= 0 then
			self.size[2] = math.max(self.size[2], 1 / g_screenHeight)
		end

		self:updateAbsolutePosition()
	end
end

function GuiElement:getParentBorders()
	if self.parent ~= nil then
		return self.parent:getBorders()
	end

	return {
		0,
		0,
		1,
		1
	}
end

function GuiElement:getBorders()
	return {
		self.absPosition[1],
		self.absPosition[2],
		self.absPosition[1] + self.absSize[1],
		self.absPosition[2] + self.absSize[2]
	}
end

function GuiElement:getCenter()
	return {
		self.absPosition[1] + self.absSize[1] * 0.5,
		self.absPosition[2] + self.absSize[2] * 0.5
	}
end

function GuiElement:getAspectScale()
	return g_aspectScaleX, g_aspectScaleY
end

function GuiElement:applyElementAspectScale(ignorePosition)
	local scaleX, scaleY = self:getAspectScale()
	self.size[1] = self.size[1] * scaleX
	self.margin[1] = self.margin[1] * scaleX
	self.margin[3] = self.margin[3] * scaleX
	self.size[2] = self.size[2] * scaleY
	self.margin[2] = self.margin[2] * scaleY
	self.margin[4] = self.margin[4] * scaleY

	if not ignorePosition then
		self.position[1] = self.position[1] * scaleX
		self.position[2] = self.position[2] * scaleY
	end
end

function GuiElement:applyScreenAlignment()
	self:applyElementAspectScale()

	for _, child in ipairs(self.elements) do
		child:applyScreenAlignment()
	end
end

function GuiElement:setOverlayState(overlayState)
	self.overlayState = overlayState

	if self.updateChildrenOverlayState then
		for _, child in pairs(self.elements) do
			child:setOverlayState(overlayState)
		end
	end
end

function GuiElement:getOverlayState()
	return self.overlayState
end

function GuiElement:addCallback(xmlFile, key, funcName)
	local callbackName = getXMLString(xmlFile, key)

	if callbackName ~= nil then
		if self.target ~= nil then
			self[funcName] = self.target[callbackName]
		else
			self[funcName] = ClassUtil.getFunction(callbackName)
		end
	end
end

function GuiElement:setCallback(funcName, callbackName)
	if self.target ~= nil then
		self[funcName] = self.target[callbackName]
	else
		self[funcName] = ClassUtil.getFunction(callbackName)
	end
end

function GuiElement:raiseCallback(name, ...)
	if self[name] ~= nil then
		if self.target ~= nil then
			return self[name](self.target, ...)
		else
			return self[name](...)
		end
	end

	return nil
end

function GuiElement.extractIndexAndNameFromID(elementId)
	local len = elementId:len()
	local varName = elementId
	local index = nil

	if len >= 4 and elementId:sub(len, len) == "]" then
		local startI = elementId:find("[", 1, true)

		if startI ~= nil and startI > 1 and startI < len - 1 then
			index = Utils.evaluateFormula(elementId:sub(startI + 1, len - 1))

			if index ~= nil then
				varName = elementId:sub(1, startI - 1)
			end
		end
	end

	return index, varName
end

function GuiElement:setId(xmlFile, key)
	local id = getXMLString(xmlFile, key .. "#id")

	if id ~= nil then
		local valid = true
		local _, varName = GuiElement.extractIndexAndNameFromID(id)

		if varName:find("[^%w_]") ~= nil then
			print("Error: Invalid gui element id " .. id)

			valid = false
		end

		if valid then
			self.id = id
		end
	end
end

function GuiElement:include(guiMixinType)
	guiMixinType.new():addTo(self)
end

function GuiElement:verifyConfiguration()
end

function GuiElement:reloadFocusHandling(reloadIds)
	if reloadIds then
		local function trash(e)
			e.focusId = nil

			for i = 1, #e.elements do
				trash(e.elements[i])
			end
		end

		trash(self)
	end

	FocusManager:loadElementFromCustomValues(self)
end

local function findFirstFocusableSearch(element, checkReceiveFocus)
	if not element.focusFallthrough and element:getIsVisibleNonRec() and (not checkReceiveFocus or element:canReceiveFocus()) then
		return element
	end

	for i = 1, #element.elements do
		if element.elements[i]:getIsVisibleNonRec() then
			local result = findFirstFocusableSearch(element.elements[i], checkReceiveFocus)

			if result ~= nil then
				return result
			end
		end
	end

	return nil
end

function GuiElement:findFirstFocusable(checkReceiveFocus)
	local element = findFirstFocusableSearch(self, checkReceiveFocus)

	if element == nil then
		element = self
	end

	return element
end

function GuiElement:toString()
	return string.format("[ID: %s, FocusID: %s, GuiProfile: %s, Position: %g, %g]", tostring(self.id), tostring(self.focusId), tostring(self.profile), self.absPosition[1], self.absPosition[2])
end
