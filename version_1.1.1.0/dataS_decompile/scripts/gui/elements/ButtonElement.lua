ButtonElement = {}
local ButtonElement_mt = Class(ButtonElement, TextElement)

function ButtonElement.new(target, custom_mt)
	local self = TextElement.new(target, custom_mt or ButtonElement_mt)

	self:include(PlaySampleMixin)

	self.mouseDown = false
	self.forceFocus = false
	self.forceHighlight = false
	self.overlay = {}
	self.icon = {}
	self.touchIcon = {}
	self.iconSize = {
		0,
		0
	}
	self.touchIconSize = {
		0,
		0
	}
	self.iconTextOffset = {
		0,
		0
	}
	self.focusedTextOffset = {
		0,
		0
	}
	self.hotspot = {
		0,
		0,
		0,
		0
	}
	self.needExternalClick = false
	self.clickSoundName = GuiSoundPlayer.SOUND_SAMPLES.CLICK
	self.fitToContent = false
	self.fitExtraWidth = {
		0
	}
	self.hideKeyboardGlyph = false
	self.isTouchButton = false
	self.addTouchArea = true
	self.inputActionName = nil
	self.hasLoadedInputGlyph = false
	self.isKeyboardMode = false
	self.keyDisplayText = nil
	self.keyOverlay = nil
	self.keyGlyphOffsetX = 0
	self.keyGlyphSize = {
		0,
		0
	}
	self.iconColors = {
		color = {
			1,
			1,
			1,
			1
		}
	}
	self.iconImageSize = {
		1024,
		1024
	}

	return self
end

function ButtonElement:delete()
	GuiOverlay.deleteOverlay(self.touchIcon)
	GuiOverlay.deleteOverlay(self.overlay)
	GuiOverlay.deleteOverlay(self.icon)
	ButtonElement:superClass().delete(self)
end

function ButtonElement:loadFromXML(xmlFile, key)
	ButtonElement:superClass().loadFromXML(self, xmlFile, key)
	self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")
	self:addCallback(xmlFile, key .. "#onFocus", "onFocusCallback")
	self:addCallback(xmlFile, key .. "#onLeave", "onLeaveCallback")
	self:addCallback(xmlFile, key .. "#onHighlight", "onHighlightCallback")
	self:addCallback(xmlFile, key .. "#onHighlightRemove", "onHighlightRemoveCallback")
	GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, nil, xmlFile, key)

	self.iconSize = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#iconSize"), self.outputSize, self.iconSize)
	self.touchIconSize = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#touchIconSize"), self.outputSize, self.touchIconSize)
	self.iconTextOffset = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#iconTextOffset"), self.outputSize, self.iconTextOffset)
	self.hotspot = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#hotspot"), self.outputSize, self.hotspot)
	self.forceFocus = Utils.getNoNil(getXMLBool(xmlFile, key .. "#forceFocus"), self.forceFocus)
	self.forceHighlight = Utils.getNoNil(getXMLBool(xmlFile, key .. "#forceHighlight"), self.forceHighlight)
	self.needExternalClick = Utils.getNoNil(getXMLBool(xmlFile, key .. "#needExternalClick"), self.needExternalClick)
	self.fitToContent = Utils.getNoNil(getXMLBool(xmlFile, key .. "#fitToContent"), self.fitToContent)
	self.fitExtraWidth = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#fitExtraWidth"), self.outputSize, self.fitExtraWidth)
	self.hideKeyboardGlyph = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hideKeyboardGlyph"), self.hideKeyboardGlyph)
	self.isTouchButton = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isTouchButton"), self.isTouchButton)
	self.addTouchArea = Utils.getNoNil(getXMLBool(xmlFile, key .. "#addTouchArea"), self.addTouchArea)
	local inputActionName = getXMLString(xmlFile, key .. "#inputAction")

	if inputActionName ~= nil and InputAction[inputActionName] ~= nil then
		self.inputActionName = inputActionName

		self:loadInputGlyphColors(nil, xmlFile, key)
	else
		self.iconImageSize = GuiUtils.get2DArray(getXMLString(xmlFile, key .. "#iconImageSize"), self.iconImageSize)

		GuiOverlay.loadOverlay(self, self.icon, "icon", self.iconImageSize, nil, xmlFile, key)
		GuiOverlay.createOverlay(self.icon)
	end

	if self.isTouchButton and GS_IS_MOBILE_VERSION then
		GuiOverlay.loadOverlay(self, self.touchIcon, "touchIcon", self.imageSize, nil, xmlFile, key)
		GuiOverlay.createOverlay(self.touchIcon)
	end

	local sampleName = getXMLString(xmlFile, key .. "#clickSound") or self.clickSoundName
	local resolvedSampleName = GuiSoundPlayer.SOUND_SAMPLES[sampleName]

	if resolvedSampleName ~= nil then
		self.clickSoundName = resolvedSampleName
	end

	GuiOverlay.createOverlay(self.overlay)
	self:updateSize()
end

function ButtonElement:loadProfile(profile, applyProfile)
	ButtonElement:superClass().loadProfile(self, profile, applyProfile)
	GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, profile, nil, )

	self.iconSize = GuiUtils.getNormalizedValues(profile:getValue("iconSize"), self.outputSize, self.iconSize)
	self.touchIconSize = GuiUtils.getNormalizedValues(profile:getValue("touchIconSize"), self.outputSize, self.touchIconSize)
	self.iconTextOffset = GuiUtils.getNormalizedValues(profile:getValue("iconTextOffset"), self.outputSize, self.iconTextOffset)
	self.hotspot = GuiUtils.getNormalizedValues(profile:getValue("hotspot"), self.outputSize, self.hotspot)
	self.forceFocus = profile:getBool("forceFocus", self.forceFocus)
	self.forceHighlight = profile:getBool("forceHighlight", self.forceHighlight)
	self.needExternalClick = profile:getBool("needExternalClick", self.needExternalClick)
	self.fitToContent = profile:getBool("fitToContent", self.fitToContent)
	self.fitExtraWidth = GuiUtils.getNormalizedValues(profile:getValue("fitExtraWidth"), self.outputSize, self.fitExtraWidth)
	self.hideKeyboardGlyph = profile:getBool("hideKeyboardGlyph", self.hideKeyboardGlyph)
	self.isTouchButton = profile:getBool("isTouchButton", self.isTouchButton)
	self.addTouchArea = profile:getBool("addTouchArea", self.addTouchArea)
	local inputActionName = profile:getValue("inputAction", self.inputActionName)

	if inputActionName ~= nil and InputAction[inputActionName] ~= nil then
		self.inputActionName = inputActionName

		self:loadInputGlyphColors(profile, nil, )
	else
		local imageSize = profile:getValue("iconImageSize")

		if imageSize ~= nil then
			local x, y = imageSize:getVector()

			if x ~= nil and y ~= nil then
				self.iconImageSize = {
					x,
					y
				}
			end
		end

		GuiOverlay.loadOverlay(self, self.icon, "icon", self.iconImageSize, profile, nil, )
		GuiOverlay.createOverlay(self.icon)
	end

	if self.isTouchButton and GS_IS_MOBILE_VERSION then
		GuiOverlay.loadOverlay(self, self.touchIcon, "touchIcon", self.imageSize, profile, nil, )
		GuiOverlay.createOverlay(self.touchIcon)
	end

	local sampleName = profile:getValue("clickSound", self.clickSoundName)
	local resolvedSampleName = GuiSoundPlayer.SOUND_SAMPLES[sampleName]

	if resolvedSampleName ~= nil then
		self.clickSoundName = resolvedSampleName
	end

	if applyProfile then
		self:applyButtonAspectScale()
		self:updateSize()
	end
end

function ButtonElement:copyAttributes(src)
	ButtonElement:superClass().copyAttributes(self, src)
	GuiOverlay.copyOverlay(self.overlay, src.overlay)
	GuiOverlay.copyOverlay(self.icon, src.icon)

	if src.isTouchButton and GS_IS_MOBILE_VERSION then
		GuiOverlay.copyOverlay(self.touchIcon, src.touchIcon)

		self.touchIconSize = table.copy(src.touchIconSize)
	end

	self.iconSize = table.copy(src.iconSize)
	self.iconTextOffset = table.copy(src.iconTextOffset)
	self.hotspot = table.copy(src.hotspot)
	self.forceFocus = src.forceFocus
	self.forceHighlight = src.forceHighlight
	self.needExternalClick = src.needExternalClick
	self.inputActionName = src.inputActionName
	self.clickSoundName = src.clickSoundName
	self.hideKeyboardGlyph = src.hideKeyboardGlyph
	self.fitExtraWidth = src.fitExtraWidth
	self.fitToContent = src.fitToContent
	self.isTouchButton = src.isTouchButton
	self.addTouchArea = src.addTouchArea
	self.iconColors = src.iconColors
	self.onClickCallback = src.onClickCallback
	self.onLeaveCallback = src.onLeaveCallback
	self.onFocusCallback = src.onFocusCallback
	self.onHighlightCallback = src.onHighlightCallback
	self.onHighlightRemoveCallback = src.onHighlightRemoveCallback

	GuiMixin.cloneMixin(PlaySampleMixin, src, self)
end

function ButtonElement:loadInputGlyphColors(profile, xmlFile, key)
	if xmlFile ~= nil then
		GuiOverlay.loadXMLColors(xmlFile, key, self.iconColors, "icon")
		GuiOverlay.loadXMLColors(xmlFile, key, self.icon, "icon")
	elseif profile ~= nil then
		GuiOverlay.loadProfileColors(profile, self.iconColors, "icon")
		GuiOverlay.loadProfileColors(profile, self.icon, "icon")
	end
end

function ButtonElement:loadInputGlyph(force)
	if not self.icon.filename or force then
		local overlay = g_inputDisplayManager:getGamepadInputActionOverlay(self.inputActionName, Binding.AXIS_COMPONENT.POSITIVE)

		if overlay ~= nil then
			GuiOverlay.deleteOverlay(self.icon)

			self.icon = overlay

			GuiOverlay.copyColors(self.icon, self.iconColors)

			self.hasLoadedInputGlyph = true
		end
	end

	if not GS_IS_CONSOLE_VERSION and not GS_IS_MOBILE_VERSION then
		local keyText = g_inputDisplayManager:getKeyboardInputActionKey(self.inputActionName, Binding.AXIS_COMPONENT.POSITIVE)

		if keyText ~= nil then
			self.keyDisplayText = keyText
			self.keyOverlay = g_inputDisplayManager:getKeyboardKeyOverlay()
			local refWidth = self.iconSize[1]
			local newWidth = self.keyOverlay:getButtonWidth(keyText, self.iconSize[2])
			self.keyGlyphSize = {
				newWidth,
				self.iconSize[2]
			}
			local dynOffset = newWidth - refWidth
			self.keyGlyphOffsetX = dynOffset
		end
	end
end

function ButtonElement:applyButtonAspectScale()
	local xScale, yScale = self:getAspectScale()
	self.iconSize[1] = self.iconSize[1] * xScale
	self.iconTextOffset[1] = self.iconTextOffset[1] * xScale
	self.hotspot[1] = self.hotspot[1] * xScale
	self.hotspot[3] = self.hotspot[3] * xScale
	self.fitExtraWidth[1] = self.fitExtraWidth[1] * xScale
	self.touchIconSize[1] = self.touchIconSize[1] * xScale
	self.iconSize[2] = self.iconSize[2] * yScale
	self.iconTextOffset[2] = self.iconTextOffset[2] * yScale
	self.hotspot[2] = self.hotspot[2] * yScale
	self.hotspot[4] = self.hotspot[4] * yScale
	self.touchIconSize[2] = self.touchIconSize[2] * yScale
end

function ButtonElement:applyScreenAlignment()
	self:applyButtonAspectScale()
	ButtonElement:superClass().applyScreenAlignment(self)
end

function ButtonElement:setInputMode(isKeyboardMode, isTouchMode, isGamepadMode)
	local didChange = false

	if self.isKeyboardMode ~= isKeyboardMode then
		self.isKeyboardMode = isKeyboardMode
		didChange = true

		if not self.hasLoadedInputGlyph then
			self:loadInputGlyph()
		end
	end

	if self.isGamepadMode ~= isGamepadMode then
		self.isGamepadMode = isGamepadMode
		didChange = true

		if not self.hasLoadedInputGlyph then
			self:loadInputGlyph()
		end
	end

	if self.isTouchMode ~= isTouchMode and self.isTouchButton then
		self.isTouchMode = isTouchMode
		didChange = true
	end

	if didChange then
		self:updateSize()
	end
end

function ButtonElement:setAlpha(alpha)
	ButtonElement:superClass().setAlpha(self, alpha)

	if self.overlay ~= nil then
		self.overlay.alpha = self.alpha
	end

	if self.icon ~= nil then
		self.icon.alpha = self.alpha
	end
end

function ButtonElement:setDisabled(disabled)
	ButtonElement:superClass().setDisabled(self, disabled)

	if disabled then
		FocusManager:unsetFocus(self)

		self.mouseEntered = false

		self:raiseCallback("onLeaveCallback", self)

		self.mouseDown = false

		self:setOverlayState(GuiOverlay.STATE_DISABLED)
	else
		self:setOverlayState(GuiOverlay.STATE_NORMAL)
	end
end

function ButtonElement:setInputAction(inputActionName)
	if inputActionName ~= nil and InputAction[inputActionName] ~= nil then
		self.inputActionName = inputActionName

		self:loadInputGlyph(true)
	end
end

function ButtonElement:onOpen()
	ButtonElement:superClass().onOpen(self)

	if self.disabled then
		self:setOverlayState(GuiOverlay.STATE_DISABLED)
	end

	if self.inputActionName ~= nil then
		self.hasLoadedInputGlyph = false

		self:loadInputGlyph(true)
	end
end

function ButtonElement:onClose()
	ButtonElement:superClass().onClose(self)
	self:reset()
end

function ButtonElement:reset()
	ButtonElement:superClass().reset(self)
	self:setOverlayState(GuiOverlay.STATE_NORMAL)

	self.mouseDown = false
end

function ButtonElement:setImageFilename(filename, iconFilename)
	if filename ~= nil then
		self.overlay = GuiOverlay.createOverlay(self.overlay, filename)
	end

	if iconFilename ~= nil then
		self.icon = GuiOverlay.createOverlay(self.icon, iconFilename)
	end
end

function ButtonElement:setImageUVs(backgroundUVs, iconUVs)
	if backgroundUVs ~= nil then
		self.overlay.uvs = backgroundUVs
	end

	if iconUVs ~= nil then
		self.icon.uvs = iconUVs
	end
end

function ButtonElement:getIsActive()
	local baseActive = ButtonElement:superClass().getIsActive(self)

	return baseActive and self.onClickCallback ~= nil
end

function ButtonElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		eventUsed = eventUsed or ButtonElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
		local cursorInElement = GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], self.hotspot)

		if cursorInElement then
			if not self.mouseEntered then
				if not self.forceHighlight then
					FocusManager:setHighlight(self)
				end

				self.mouseEntered = true
			end
		else
			self:restoreOverlayState()

			self.mouseDown = false
			self.mouseEntered = false

			if not self.forceHighlight then
				FocusManager:unsetHighlight(self)
			end
		end

		if not eventUsed and cursorInElement and not FocusManager:isLocked() then
			if isDown and button == Input.MOUSE_BUTTON_LEFT then
				if self.handleFocus and not self.forceFocus then
					FocusManager:setFocus(self)

					eventUsed = true
				end

				self.mouseDown = true
			end

			if self.mouseDown and self:getOverlayState() ~= GuiOverlay.STATE_PRESSED then
				self:storeOverlayState()
				self:setOverlayState(GuiOverlay.STATE_PRESSED)
			end

			if isUp and button == Input.MOUSE_BUTTON_LEFT and self.mouseDown then
				self:restoreOverlayState()

				self.mouseDown = false

				self:sendAction()

				eventUsed = true
			end
		end
	end

	return eventUsed
end

function ButtonElement:keyEvent(unicode, sym, modifier, isDown, eventUsed)
	if self:getIsActive() then
		return ButtonElement:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed)
	end

	return false
end

function ButtonElement:getIconOffset(textWidth, textHeight)
	local iconSizeX, iconSizeY = self:getIconSize()
	local xOffset = self.iconTextOffset[1]
	local yOffset = self.iconTextOffset[2]

	if self.textAlignment == RenderText.ALIGN_LEFT then
		xOffset = xOffset - iconSizeX
	elseif self.textAlignment == RenderText.ALIGN_CENTER then
		xOffset = xOffset - textWidth * 0.5 - iconSizeX
	elseif self.textAlignment == RenderText.ALIGN_RIGHT then
		xOffset = xOffset + textWidth - iconSizeX
	end

	if self.textVerticalAlignment == TextElement.VERTICAL_ALIGNMENT.TOP then
		yOffset = yOffset - textHeight
	elseif self.textVerticalAlignment == TextElement.VERTICAL_ALIGNMENT.MIDDLE then
		yOffset = yOffset + (textHeight - iconSizeY) * 0.5
	end

	return xOffset, yOffset
end

function ButtonElement:draw(clipX1, clipY1, clipX2, clipY2)
	self:setInputMode(self.keyDisplayText ~= nil and g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_KEYBOARD, self.isTouchButton and g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_TOUCH, g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD)
	GuiOverlay.renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2], self:getOverlayState(), clipX1, clipY1, clipX2, clipY2)

	local xPos, yPos = self:getTextPosition(self.text)
	local textOffsetX, textOffsetY = self:getTextOffset()
	local xOffset, yOffset = self:getIconOffset(self:getTextWidth(), getTextHeight(self.textSize, self.text))
	local iconXPos = xPos + textOffsetX + xOffset
	local iconYPos = yPos + textOffsetY + yOffset
	local iconSizeX, iconSizeY = self:getIconSize()
	local overlayState = self:getOverlayState()

	if self.keyDisplayText ~= nil and self.isKeyboardMode then
		if not self.hideKeyboardGlyph then
			local color = GuiOverlay.getOverlayColor(self.iconColors, overlayState)

			self.keyOverlay:setColor(unpack(color))
			self.keyOverlay:renderButton(self.keyDisplayText, iconXPos, iconYPos, iconSizeY, self.textAlignment, true)
		end
	elseif self.isTouchMode then
		if self.addTouchArea then
			drawTouchButton(self.absPosition[1], self.absPosition[2] + self.absSize[2] / 2, self.absSize[1], overlayState == GuiOverlay.STATE_PRESSED)
		end

		if self.touchIcon ~= nil then
			local touchIconYPos = self.absPosition[2] + self.absSize[2] / 2 - self.touchIconSize[2] / 2

			GuiOverlay.renderOverlay(self.touchIcon, iconXPos, touchIconYPos, self.touchIconSize[1], self.touchIconSize[2], overlayState, clipX1, clipY1, clipX2, clipY2)
		end
	else
		GuiOverlay.renderOverlay(self.icon, iconXPos, iconYPos, iconSizeX, iconSizeY, overlayState, clipX1, clipY1, clipX2, clipY2)
	end

	if self.debugEnabled or g_uiDebugEnabled then
		local xPixel = 1 / g_screenWidth
		local yPixel = 1 / g_screenHeight
		local posX1 = self.absPosition[1] + self.hotspot[1]
		local posX2 = self.absPosition[1] + self.size[1] + self.hotspot[3] - xPixel
		local posY1 = self.absPosition[2] + self.hotspot[2]
		local posY2 = self.absPosition[2] + self.size[2] + self.hotspot[4] - yPixel

		drawFilledRect(posX1, posY1, posX2 - posX1, yPixel, 0, 1, 0, 0.7)
		drawFilledRect(posX1, posY2, posX2 - posX1, yPixel, 0, 1, 0, 0.7)
		drawFilledRect(posX1, posY1, xPixel, posY2 - posY1, 0, 1, 0, 0.7)
		drawFilledRect(posX1 + posX2 - posX1, posY1, xPixel, posY2 - posY1, 0, 1, 0, 0.7)
	end

	ButtonElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end

function ButtonElement:setSelected(isSelected)
	if isSelected then
		self:setOverlayState(GuiOverlay.STATE_SELECTED)
	else
		self:setOverlayState(GuiOverlay.STATE_NORMAL)
	end
end

function ButtonElement:getIsSelected()
	local isSelected = ButtonElement:superClass().getIsSelected(self)
	local state = self:getOverlayState()

	return isSelected or state == GuiOverlay.STATE_FOCUSED or state == GuiOverlay.STATE_PRESSED or state == GuiOverlay.STATE_SELECTED
end

function ButtonElement:getIsHighlighted()
	local superSelected = ButtonElement:superClass().getIsHighlighted(self)

	return superSelected or self:getOverlayState() == GuiOverlay.STATE_HIGHLIGHTED
end

function ButtonElement:getIconModifiedTextOffset(textOffsetX, textOffsetY)
	local xOffset = textOffsetX
	local yOffset = textOffsetY
	local iconWidth, _ = self:getIconSize()

	if self.textAlignment == RenderText.ALIGN_LEFT then
		xOffset = xOffset - self.iconTextOffset[1] + iconWidth
	elseif self.textAlignment == RenderText.ALIGN_CENTER then
		xOffset = xOffset + (-self.iconTextOffset[1] + iconWidth) * 0.5
	end

	return xOffset, yOffset
end

function ButtonElement:getTextOffset()
	local xOffset, yOffset = ButtonElement:superClass().getTextOffset(self)

	if self.isTouchMode and self.addTouchArea then
		xOffset = xOffset + 0.020833333333333332
	end

	return self:getIconModifiedTextOffset(xOffset, yOffset)
end

function ButtonElement:getText2Offset()
	local xOffset, yOffset = ButtonElement:superClass().getText2Offset(self)

	return self:getIconModifiedTextOffset(xOffset, yOffset)
end

function ButtonElement:getIconSize()
	if self.isKeyboardMode then
		return self.keyGlyphSize[1], self.keyGlyphSize[2]
	else
		return self.iconSize[1], self.iconSize[2]
	end
end

function ButtonElement:setIconSize(x, y)
	self.iconSize[1] = Utils.getNoNil(x, self.iconSize[1])
	self.iconSize[2] = Utils.getNoNil(y, self.iconSize[2])

	self:updateSize()
end

function ButtonElement:canReceiveFocus()
	return not self.disabled and not not self:getIsVisible() and self:getHandleFocus()
end

function ButtonElement:onFocusLeave()
	self:raiseCallback("onLeaveCallback", self)
end

function ButtonElement:onFocusEnter()
	self:raiseCallback("onFocusCallback", self)
end

function ButtonElement:onHighlight()
	self:raiseCallback("onHighlightCallback", self)
end

function ButtonElement:onHighlightRemove()
	self:raiseCallback("onHighlightRemoveCallback", self)
end

function ButtonElement:onFocusActivate()
	if self:getIsActive() then
		self:sendAction()
	end
end

function ButtonElement:isFocused()
	return self:getIsActive() and self:getOverlayState() == GuiOverlay.STATE_FOCUSED
end

function ButtonElement:updateSize(forceTextSize)
	if (not self.fitToContent or not self.textAutoWidth or self.textMaxNumLines ~= 1) and not forceTextSize then
		return
	end

	local xOffset, _ = self:getTextOffset()

	setTextBold(self.textBold)

	local textWidth = getTextWidth(self.textSize, self.sourceText) + 0.001

	setTextBold(false)

	local width = xOffset + textWidth + self.fitExtraWidth[1]
	local height = nil

	if self.isTouchButton and self.isTouchMode and self.addTouchArea then
		width = width + 0.030208333333333334
		height = 0.09375

		if self.originalHeight ~= nil then
			self.originalHeight = self.size[2]
		end
	else
		height = self.originalHeight
		self.originalHeight = nil
	end

	self:setSize(width, height)

	if self.parent ~= nil and self.parent.invalidateLayout ~= nil then
		self.parent:invalidateLayout()
	end
end

function ButtonElement:setText(text, forceTextSize)
	ButtonElement:superClass().setText(self, text, forceTextSize)
	self:updateSize()
end

function ButtonElement:setTextSize(size)
	ButtonElement:superClass().setTextSize(self, size)
	self:updateSize()
end

function ButtonElement:setClickSound(soundName)
	self.clickSoundName = soundName
end

function ButtonElement:sendAction()
	self:playSample(self.clickSoundName)
	self:raiseCallback("onClickCallback", self)
end
