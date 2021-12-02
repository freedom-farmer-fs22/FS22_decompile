HUDPopupMessage = {}
local HUDPopupMessage_mt = Class(HUDPopupMessage, HUDDisplayElement)
HUDPopupMessage.INPUT_CONTEXT_NAME = "POPUP_MESSAGE"
HUDPopupMessage.MAX_PENDING_MESSAGE_COUNT = 8
HUDPopupMessage.MAX_INPUT_ROW_COUNT = 8
HUDPopupMessage.MIN_DURATION = 1000
HUDPopupMessage.DURATION_PER_CHARACTER = 80
HUDPopupMessage.MAX_DURATION = 300000

function HUDPopupMessage.new(hudAtlasPath, l10n, inputManager, inputDisplayManager, ingameMap, guiSoundPlayer)
	local backgroundOverlay = HUDPopupMessage.createBackground(hudAtlasPath)
	local self = HUDPopupMessage:superClass().new(backgroundOverlay, nil, HUDPopupMessage_mt)
	self.l10n = l10n
	self.inputManager = inputManager
	self.inputDisplayManager = inputDisplayManager
	self.ingameMap = ingameMap
	self.guiSoundPlayer = guiSoundPlayer
	self.pendingMessages = {}
	self.isCustomInputActive = false
	self.lastInputMode = self.inputManager:getInputHelpMode()
	self.inputRows = {}
	self.inputGlyphs = {}
	self.skipGlyph = nil
	self.isMenuVisible = false
	self.time = 0
	self.isGamePaused = false

	self:storeScaledValues()
	self:createComponents(hudAtlasPath)

	return self
end

function HUDPopupMessage:delete()
	if self.blurAreaActive then
		g_depthOfFieldManager:popArea()

		self.blurAreaActive = false
	end

	HUDPopupMessage:superClass().delete(self)
end

function HUDPopupMessage:showMessage(title, text, duration, controls, callback, target)
	if duration == 0 then
		duration = HUDPopupMessage.MIN_DURATION + string.len(text) * HUDPopupMessage.DURATION_PER_CHARACTER
	elseif duration < 0 then
		duration = HUDPopupMessage.MAX_DURATION
	end

	while HUDPopupMessage.MAX_PENDING_MESSAGE_COUNT < #self.pendingMessages do
		table.remove(self.pendingMessages, 1)
	end

	local message = {
		isDialog = false,
		title = title,
		message = text,
		duration = duration,
		controls = Utils.getNoNil(controls, {}),
		callback = callback,
		target = target
	}

	if HUDPopupMessage.MAX_INPUT_ROW_COUNT < #message.controls then
		for i = #message.controls, HUDPopupMessage.MAX_INPUT_ROW_COUNT + 1, -1 do
			table.remove(message.controls, i)
		end
	end

	table.insert(self.pendingMessages, message)
end

function HUDPopupMessage:setPaused(isPaused)
	self.isGamePaused = isPaused
end

function HUDPopupMessage:getVisible()
	return HUDPopupMessage:superClass().getVisible(self) and self.currentMessage ~= nil
end

function HUDDisplayElement:getHidingTranslation()
	return 0, -self:getHeight() - g_safeFrameOffsetY - 0.01
end

function HUDPopupMessage:onMenuVisibilityChange(isMenuVisible)
	self.isMenuVisible = isMenuVisible
end

function HUDPopupMessage:assignCurrentMessage(message)
	self.time = 0
	self.currentMessage = message
	local reqHeight = self:getTitleHeight() + self:getTextHeight() + self:getInputRowsHeight()
	reqHeight = reqHeight + self.borderPaddingY * 2 + self.textOffsetY + self.titleTextSize + self.textSize

	if #message.controls > 0 then
		reqHeight = reqHeight + self.inputRowsOffsetY
	end

	if not g_isServerStreamingVersion then
		reqHeight = reqHeight + self.skipButtonHeight
	end

	self:setDimension(self:getWidth(), math.max(self.minHeight, reqHeight))
	self:updateButtonGlyphs()
end

function HUDPopupMessage:getTitleHeight()
	local height = 0

	if self.currentMessage ~= nil then
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(false)
		setTextWrapWidth(self:getWidth() - 2 * self.borderPaddingX)

		local title = utf8ToUpper(self.currentMessage.title)
		local lineHeight, numTitleRows = getTextHeight(self.titleTextSize, title)
		height = numTitleRows * lineHeight

		setTextWrapWidth(0)
	end

	return height
end

function HUDPopupMessage:getTextHeight()
	local height = 0

	if self.currentMessage ~= nil then
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
		setTextWrapWidth(self:getWidth() - 2 * self.borderPaddingX)
		setTextLineHeightScale(HUDPopupMessage.TEXT_LINE_HEIGHT_SCALE)

		height = getTextHeight(self.textSize, self.currentMessage.message)

		setTextWrapWidth(0)
		setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
	end

	return height
end

function HUDPopupMessage:getInputRowsHeight()
	local height = 0

	if self.currentMessage ~= nil then
		height = (#self.currentMessage.controls + 1) * self.inputRowHeight
	end

	return height
end

function HUDPopupMessage:animateHide()
	HUDPopupMessage:superClass().animateHide(self)
	g_depthOfFieldManager:popArea()

	self.blurAreaActive = false

	self.animation:addCallback(self.finishMessage)
end

function HUDPopupMessage:startMessage()
	self.ingameMap:setAllowToggle(false)
	self.ingameMap:turnSmall()
	self:assignCurrentMessage(self.pendingMessages[1])
	table.remove(self.pendingMessages, 1)
	self:setInputActive(true)
end

function HUDPopupMessage:finishMessage()
	self:setInputActive(false)
	self.ingameMap:setAllowToggle(true)

	if self.currentMessage ~= nil and self.currentMessage.callback ~= nil then
		if self.currentMessage.target ~= nil then
			self.currentMessage.callback(self.currentMessage.target)
		else
			self.currentMessage.callback(self)
		end
	end

	self.currentMessage = nil
end

function HUDPopupMessage:update(dt)
	if not self.isMenuVisible then
		HUDPopupMessage:superClass().update(self, dt)

		if not self.isGamePaused then
			self.time = self.time + dt

			self:updateCurrentMessage()
		end

		if self:getVisible() then
			local inputMode = self.inputManager:getInputHelpMode()

			if inputMode ~= self.lastInputMode then
				self.lastInputMode = inputMode

				self:updateButtonGlyphs()
			end
		end
	end
end

function HUDPopupMessage:updateCurrentMessage()
	if self.currentMessage ~= nil then
		if self.currentMessage.duration < self.time then
			self.time = -math.huge

			self:setVisible(false, true)
		end
	elseif #self.pendingMessages > 0 then
		self:startMessage()
		self:setVisible(true, true)
		self.animation:addCallback(function ()
			local x, y = self:getPosition()

			g_depthOfFieldManager:pushArea(x, y, self:getWidth(), self:getHeight())

			self.blurAreaActive = true
		end)
	end
end

function HUDPopupMessage:updateButtonGlyphs()
	if self.skipGlyph ~= nil then
		self.skipGlyph:setAction(InputAction.SKIP_MESSAGE_BOX, self.l10n:getText(HUDPopupMessage.L10N_SYMBOL.BUTTON_OK), self.skipTextSize, true, false)
	end

	if self.currentMessage ~= nil then
		local controlIndex = 1

		for i = 1, HUDPopupMessage.MAX_INPUT_ROW_COUNT do
			local rowIndex = HUDPopupMessage.MAX_INPUT_ROW_COUNT - i + 1
			local inputRowVisible = rowIndex <= #self.currentMessage.controls

			self.inputRows[i]:setVisible(inputRowVisible)

			if inputRowVisible then
				local control = self.currentMessage.controls[controlIndex]

				self.inputGlyphs[i]:setActions(control:getActionNames(), "", self.textSize, false, false)
				self.inputGlyphs[i]:setKeyboardGlyphColor(HUDPopupMessage.COLOR.INPUT_GLYPH)

				controlIndex = controlIndex + 1
			end
		end
	end
end

function HUDPopupMessage:setInputActive(isActive)
	if not self.isCustomInputActive and isActive then
		self.inputManager:setContext(HUDPopupMessage.INPUT_CONTEXT_NAME, true, false)

		local _, eventId = self.inputManager:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onConfirmMessage, false, true, false, true)

		self.inputManager:setActionEventTextVisibility(eventId, false)

		_, eventId = self.inputManager:registerActionEvent(InputAction.SKIP_MESSAGE_BOX, self, self.onConfirmMessage, false, true, false, true)

		self.inputManager:setActionEventTextVisibility(eventId, false)

		self.isCustomInputActive = true
	elseif self.isCustomInputActive and not isActive then
		self.inputManager:removeActionEventsByTarget(self)
		self.inputManager:revertContext(true)

		self.isCustomInputActive = false
	end
end

function HUDPopupMessage:onConfirmMessage(actionName, inputValue)
	if self.animation:getFinished() then
		self:setVisible(false, true)
	end
end

function HUDPopupMessage:draw()
	if not self.isMenuVisible and self:getVisible() and self.currentMessage ~= nil then
		HUDPopupMessage:superClass().draw(self)

		local baseX, baseY = self:getPosition()
		local width = self:getWidth()
		local height = self:getHeight()

		setTextColor(unpack(HUDPopupMessage.COLOR.TITLE))
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextWrapWidth(width - 2 * self.borderPaddingX)

		local textPosY = baseY + height - self.borderPaddingY

		if self.currentMessage.title ~= "" then
			local title = utf8ToUpper(self.currentMessage.title)
			textPosY = textPosY - self.titleTextSize

			renderText(baseX + width * 0.5, textPosY, self.titleTextSize, title)
		end

		setTextBold(false)
		setTextColor(unpack(HUDPopupMessage.COLOR.TEXT))
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextLineHeightScale(HUDPopupMessage.TEXT_LINE_HEIGHT_SCALE)

		textPosY = textPosY - self.textSize + self.textOffsetY

		renderText(baseX + self.borderPaddingX, textPosY, self.textSize, self.currentMessage.message)

		textPosY = textPosY - getTextHeight(self.textSize, self.currentMessage.message)

		setTextColor(unpack(HUDPopupMessage.COLOR.SKIP_TEXT))
		setTextAlignment(RenderText.ALIGN_RIGHT)

		local posX = baseX + width - self.borderPaddingX
		local posY = textPosY + self.inputRowsOffsetY - self.inputRowHeight - self.textSize

		for i = 1, #self.currentMessage.controls do
			local inputText = self.currentMessage.controls[i].textRight

			renderText(posX + self.inputRowTextX, posY + self.inputRowTextY, self.textSize, inputText)

			posY = posY - self.inputRowHeight
		end

		setTextWrapWidth(0)
		setTextLineHeightScale(RenderText.DEFAULT_LINE_HEIGHT_SCALE)
	end
end

function HUDPopupMessage.getBackgroundPosition(uiScale)
	local offX, offY = getNormalizedScreenValues(unpack(HUDPopupMessage.POSITION.SELF))

	return 0.5 + offX * uiScale, g_safeFrameOffsetY + offY * uiScale
end

function HUDPopupMessage:setScale(uiScale)
	HUDPopupMessage:superClass().setScale(self, uiScale)
	self:storeScaledValues()

	local posX, posY = HUDPopupMessage.getBackgroundPosition(uiScale)
	local width = self:getWidth()

	self:setPosition(posX - width * 0.5, posY)
end

function HUDPopupMessage:setDimension(width, height)
	HUDPopupMessage:superClass().setDimension(self, width, height)
end

function HUDPopupMessage:storeScaledValues()
	self.minWidth, self.minHeight = self:scalePixelToScreenVector(HUDPopupMessage.SIZE.SELF)
	self.textOffsetX, self.textOffsetY = self:scalePixelToScreenVector(HUDPopupMessage.POSITION.MESSAGE_TEXT)
	self.inputRowsOffsetX, self.inputRowsOffsetY = self:scalePixelToScreenVector(HUDPopupMessage.POSITION.INPUT_ROWS)
	self.skipButtonOffsetX, self.skipButtonOffsetY = self:scalePixelToScreenVector(HUDPopupMessage.POSITION.SKIP_BUTTON)
	self.skipButtonWidth, self.skipButtonHeight = self:scalePixelToScreenVector(HUDPopupMessage.SIZE.SKIP_BUTTON)
	self.inputRowWidth, self.inputRowHeight = self:scalePixelToScreenVector(HUDPopupMessage.SIZE.INPUT_ROW)
	self.borderPaddingX, self.borderPaddingY = self:scalePixelToScreenVector(HUDPopupMessage.SIZE.BORDER_PADDING)
	self.inputRowTextX, self.inputRowTextY = self:scalePixelToScreenVector(HUDPopupMessage.POSITION.INPUT_TEXT)
	self.titleTextSize = self:scalePixelToScreenHeight(HUDPopupMessage.TEXT_SIZE.TITLE)
	self.textSize = self:scalePixelToScreenHeight(HUDPopupMessage.TEXT_SIZE.TEXT)
	self.skipTextSize = self:scalePixelToScreenHeight(HUDPopupMessage.TEXT_SIZE.SKIP_TEXT)
end

function HUDPopupMessage.createBackground(hudAtlasPath)
	local posX, posY = HUDPopupMessage.getBackgroundPosition(1)
	local width, height = getNormalizedScreenValues(unpack(HUDPopupMessage.SIZE.SELF))
	local overlay = Overlay.new(hudAtlasPath, posX - width * 0.5, posY, width, height)

	overlay:setUVs(GuiUtils.getUVs(HUDPopupMessage.UV.BACKGROUND))
	overlay:setColor(unpack(HUDPopupMessage.COLOR.BACKGROUND))

	return overlay
end

function HUDPopupMessage:createComponents(hudAtlasPath)
	local basePosX, basePosY = self:getPosition()
	local baseWidth = self:getWidth()
	local _, inputRowHeight = self:scalePixelToScreenVector(HUDPopupMessage.SIZE.INPUT_ROW)
	local posY = basePosY + inputRowHeight

	for i = 1, HUDPopupMessage.MAX_INPUT_ROW_COUNT do
		local buttonRow, inputGlyph = nil
		buttonRow, inputGlyph, posY = self:createInputRow(hudAtlasPath, basePosX, posY)
		local rowIndex = HUDPopupMessage.MAX_INPUT_ROW_COUNT - i + 1
		self.inputRows[rowIndex] = buttonRow
		self.inputGlyphs[rowIndex] = inputGlyph

		self:addChild(buttonRow)
	end

	if not g_isServerStreamingVersion then
		local offX, offY = self:scalePixelToScreenVector(HUDPopupMessage.POSITION.SKIP_BUTTON)
		local glyphWidth, glyphHeight = self:scalePixelToScreenVector(HUDPopupMessage.SIZE.INPUT_GLYPH)
		local skipGlyph = InputGlyphElement.new(self.inputDisplayManager, glyphWidth, glyphHeight)

		skipGlyph:setPosition(basePosX + (baseWidth - glyphWidth) * 0.5 + offX, basePosY - offY)
		skipGlyph:setAction(InputAction.SKIP_MESSAGE_BOX, self.l10n:getText(HUDPopupMessage.L10N_SYMBOL.BUTTON_OK), self.skipTextSize, true, false)

		self.skipGlyph = skipGlyph

		self:addChild(skipGlyph)
	end
end

function HUDPopupMessage:createInputRow(hudAtlasPath, posX, posY)
	local overlay = Overlay.new(hudAtlasPath, posX, posY, self.inputRowWidth, self.inputRowHeight)

	overlay:setUVs(GuiUtils.getUVs(HUDPopupMessage.UV.BACKGROUND))
	overlay:setColor(unpack(HUDPopupMessage.COLOR.INPUT_ROW))

	local buttonPanel = HUDElement.new(overlay)
	local rowHeight = buttonPanel:getHeight()
	local glyphWidth, glyphHeight = self:scalePixelToScreenVector(HUDPopupMessage.SIZE.INPUT_GLYPH)
	local inputGlyph = InputGlyphElement.new(self.inputDisplayManager, glyphWidth, glyphHeight)
	local offX, offY = self:scalePixelToScreenVector(HUDPopupMessage.POSITION.INPUT_GLYPH)
	local glyphX = posX + self.borderPaddingX + offX
	local glyphY = posY + (rowHeight - glyphHeight) * 0.5 + offY

	inputGlyph:setPosition(glyphX, glyphY)
	buttonPanel:addChild(inputGlyph)

	local width, height = self:scalePixelToScreenVector(HUDPopupMessage.SIZE.SEPARATOR)
	height = math.max(height, HUDPopupMessage.SIZE.SEPARATOR[2] / g_screenHeight)
	offX, offY = self:scalePixelToScreenVector(HUDPopupMessage.POSITION.SEPARATOR)
	overlay = Overlay.new(hudAtlasPath, posX + offX, posY + offY, width, height)

	overlay:setUVs(GuiUtils.getUVs(GameInfoDisplay.UV.SEPARATOR))
	overlay:setColor(unpack(GameInfoDisplay.COLOR.SEPARATOR))

	local separator = HUDElement.new(overlay)

	buttonPanel:addChild(separator)

	return buttonPanel, inputGlyph, posY + rowHeight
end

HUDPopupMessage.UV = {
	BACKGROUND = {
		8,
		8,
		2,
		2
	}
}
HUDPopupMessage.SIZE = {
	SELF = {
		750,
		165
	},
	INPUT_ROW = {
		750,
		54
	},
	SKIP_BUTTON = {
		48,
		48
	},
	BORDER_PADDING = {
		45,
		30
	},
	INPUT_GLYPH = {
		32,
		32
	},
	SEPARATOR = {
		750,
		1
	}
}
HUDPopupMessage.POSITION = {
	SELF = {
		0,
		0
	},
	MESSAGE_TEXT = {
		0,
		-16
	},
	INPUT_ROWS = {
		0,
		-16
	},
	SKIP_BUTTON = {
		0,
		-12
	},
	INPUT_GLYPH = {
		0,
		0
	},
	INPUT_TEXT = {
		0,
		3
	},
	SEPARATOR = {
		0,
		0
	}
}
HUDPopupMessage.TEXT_LINE_HEIGHT_SCALE = 1.5
HUDPopupMessage.TEXT_SIZE = {
	TEXT = 16,
	TITLE = 20,
	SKIP_TEXT = 18
}
HUDPopupMessage.COLOR = {
	BACKGROUND = {
		0,
		0,
		0,
		0.54
	},
	INPUT_ROW = {
		0.0075,
		0.0075,
		0.0075,
		0
	},
	SEPARATOR = {
		0.0382,
		0.0382,
		0.0382,
		1
	},
	TITLE = {
		1,
		1,
		1,
		1
	},
	TEXT = {
		0.9,
		0.9,
		0.9,
		1
	},
	SKIP_TEXT = {
		1,
		1,
		1,
		1
	},
	INPUT_GLYPH = {
		1,
		1,
		1,
		1
	}
}
HUDPopupMessage.L10N_SYMBOL = {
	BUTTON_OK = "button_ok"
}
