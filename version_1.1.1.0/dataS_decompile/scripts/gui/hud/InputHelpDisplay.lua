InputHelpDisplay = {}
local InputHelpDisplay_mt = Class(InputHelpDisplay, HUDDisplayElement)
InputHelpDisplay.ENTRY_COUNT_PC = 8
InputHelpDisplay.ENTRY_COUNT_CONSOLE = 8
InputHelpDisplay.ENTRY_COUNT_PRIO_PC = 16
InputHelpDisplay.ENTRY_COUNT_PRIO_CONSOLE = 16
InputHelpDisplay.L10N_CONTROLS_LABEL = "ui_controls"

function InputHelpDisplay.new(hudAtlasPath, messageCenter, inputManager, inputDisplayManager, ingameMap, communicationDisplay, ingameMessage, isConsoleVersion)
	local backgroundOverlay = InputHelpDisplay.createBackground()
	local self = InputHelpDisplay:superClass().new(backgroundOverlay, nil, InputHelpDisplay_mt)
	self.messageCenter = messageCenter
	self.inputManager = inputManager
	self.inputDisplayManager = inputDisplayManager
	self.ingameMap = ingameMap
	self.communicationDisplay = communicationDisplay
	self.ingameMessage = ingameMessage
	self.isConsoleVersion = isConsoleVersion
	self.isOverlayMenuVisible = false
	self.controlsLabelText = utf8ToUpper(g_i18n:getText(InputHelpDisplay.L10N_CONTROLS_LABEL))
	self.vehicle = nil
	self.vehicleHudExtensions = {}
	self.extraHelpTexts = {}
	self.currentAvailableHeight = 0
	self.comboInputGlyphs = {}
	self.entries = {}
	self.entryGlyphWidths = {}
	self.inputGlyphs = {}
	self.horizontalSeparators = {}
	self.frame = nil
	self.entriesFrame = nil
	self.mouseComboHeader = nil
	self.gamepadComboHeader = nil
	self.customHelpElements = {}
	self.headerHeight = 0
	self.entryHeight = 0
	self.entryWidth = 0
	self.controlsLabelTextSize = 0
	self.controlsLabelOffsetY = 0
	self.controlsLabelOffsetX = 0
	self.helpTextSize = 0
	self.helpTextOffsetY = 0
	self.helpTextOffsetX = 0
	self.extraTextOffsetY = 0
	self.extraTextOffsetX = 0
	self.axisIconOffsetX = 0
	self.axisIconHeight = 0
	self.axisIconWidth = 0
	self.frameOffsetY = 0
	self.frameOffsetX = 0
	self.frameBarOffsetY = 0
	self.hasComboCommands = false
	self.visibleHelpElements = {}
	self.currentHelpElementCount = 0
	self.requireHudExtensionsRefresh = false
	self.numUsedEntries = 0
	self.extensionsHeight = 0
	self.extensionsStartY = 0
	self.comboIterator = {}
	self.animationEntryCount = 0
	self.animationAvailableHeight = math.huge
	self.animationOffsetX = 0
	self.animationOffsetY = 0
	self.extensionBg = Overlay.new(g_baseUIFilename, 0, 0, 1, 1)

	self.extensionBg:setUVs(g_colorBgUVs)
	self.extensionBg:setColor(0, 0, 0, 0.56)
	self:createComponents(hudAtlasPath)
	self:subscribeMessages()

	return self
end

function InputHelpDisplay:subscribeMessages()
	self.messageCenter:subscribe(MessageType.INPUT_DEVICES_CHANGED, self.onInputDevicesChanged, self)
end

function InputHelpDisplay:delete()
	self.messageCenter:unsubscribeAll(self)

	if self.frame ~= nil then
		self.frame:delete()
	end

	if self.extensionBg ~= nil then
		self.extensionBg:delete()
	end

	for k, hudExtension in pairs(self.vehicleHudExtensions) do
		hudExtension:delete()

		self.vehicleHudExtensions[k] = nil
	end

	InputHelpDisplay:superClass().delete(self)
end

function InputHelpDisplay:addHelpText(text)
	table.insert(self.extraHelpTexts, text)
end

function InputHelpDisplay:getHidingTranslation()
	return -0.5, 0
end

function InputHelpDisplay:addCustomEntry(actionName1, actionName2, displayText, ignoreComboButtons)
	local entry = self.inputDisplayManager:getControllerSymbolOverlays(actionName1, actionName2, displayText, ignoreComboButtons)
	local contextName = self.inputManager:getContextName()
	local contextElements = self.customHelpElements[contextName]

	if contextElements == nil then
		contextElements = {}
		self.customHelpElements[contextName] = contextElements
	end

	table.insert(contextElements, entry)
end

function InputHelpDisplay:clearCustomEntries()
	local contextElements = self.customHelpElements[self.inputManager:getContextName()]

	if contextElements ~= nil then
		for k in pairs(self.customHelpElements) do
			self.customHelpElements[k] = nil
		end
	end
end

local function clearTable(table)
	for k in pairs(table) do
		table[k] = nil
	end
end

local function getVehicleTypeHash(vehicles)
	local hash = ""

	for _, vehicleType in pairs(vehicles) do
		hash = hash .. vehicleType
	end

	return hash
end

function InputHelpDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
	self.lastVehicleSpecHash = nil
end

function InputHelpDisplay:update(dt)
	InputHelpDisplay:superClass().update(self, dt)

	if self:getVisible() then
		self:updateInputContext()
		self:updateHUDExtensions()

		if self.sizeAndPositionDirty then
			self:updateSizeAndPositions()

			self.sizeAndPositionDirty = false
		end

		clearTable(self.extraHelpTexts)
	end

	if not self.animation:getFinished() then
		self:storeScaledValues()

		self.sizeAndPositionDirty = true
	end
end

function InputHelpDisplay:updateSizeAndPositions()
	local totalSize = 0
	local baseX, baseTopY = self:getTopLeftPosition()
	local frameX = baseX + self.frameOffsetX
	local frameTopY = baseTopY + self.frameOffsetY
	local entriesHeight = self.entriesFrame:getHeight()
	local entriesPosY = frameTopY - entriesHeight

	if self.hasComboCommands then
		totalSize = totalSize + self.headerHeight
		entriesPosY = entriesPosY - self.headerHeight
	end

	totalSize = totalSize + self.numUsedEntries * self.entryHeight
	self.extensionsStartY = frameTopY - totalSize
	totalSize = totalSize + self.extensionsHeight

	self:setDimension(self:getWidth(), totalSize)
	self:setPosition(baseX, baseTopY - totalSize)

	if self:getVisible() and not self.animation:getFinished() then
		self:storeOriginalPosition()
	end

	self.mouseComboHeader:setPosition(frameX, frameTopY - self.headerHeight)
	self.gamepadComboHeader:setPosition(frameX, frameTopY - self.headerHeight)
	self.entriesFrame:setPosition(frameX, entriesPosY)

	local frameHeight = self:getHeight() + self.frameOffsetY + self.frameBarOffsetY

	self.frame:setPosition(frameX, frameTopY - frameHeight)
end

function InputHelpDisplay:refreshHUDExtensions()
	for k, hudExtension in pairs(self.vehicleHudExtensions) do
		hudExtension:delete()

		self.vehicleHudExtensions[k] = nil
	end

	local uiScale = self:getScale()

	if self.vehicle ~= nil then
		local vehicles = self.vehicle.rootVehicle.childVehicles

		for i = 1, #vehicles do
			for j = 1, #vehicles[i].specializations do
				local spec = vehicles[i].specializations[j]
				local hudExtension = self.vehicleHudExtensions[spec]

				if hudExtension == nil and VehicleHUDExtension.hasHUDExtensionForSpecialization(spec) then
					hudExtension = VehicleHUDExtension.createHUDExtensionForSpecialization(spec, vehicles[i], uiScale, InputHelpDisplay.COLOR.HELP_TEXT, self.helpTextSize)

					table.insert(self.vehicleHudExtensions, hudExtension)
				end
			end
		end
	end
end

function InputHelpDisplay:updateHUDExtensions()
	if self.vehicle ~= nil then
		local currentHash = self:getCurrentVehicleTypeHash(self.vehicle)

		if currentHash ~= self.lastVehicleSpecHash then
			self.requireHudExtensionsRefresh = true
			self.lastVehicleSpecHash = currentHash
		end
	else
		self.lastVehicleSpecHash = nil
	end

	if self.requireHudExtensionsRefresh then
		self:refreshHUDExtensions()

		self.requireHudExtensionsRefresh = false
	end

	local extensionsHeight = 0

	for _, hudExtension in pairs(self.vehicleHudExtensions) do
		local height = hudExtension:getDisplayHeight()

		if hudExtension:canDraw() and extensionsHeight + height <= self.currentAvailableHeight then
			extensionsHeight = extensionsHeight + height
		end
	end

	self.sizeAndPositionDirty = self.sizeAndPositionDirty or self.extensionsHeight ~= extensionsHeight
	self.extensionsHeight = extensionsHeight
end

function InputHelpDisplay:getCurrentVehicleTypeHash(vehicle)
	local vehicles = vehicle.rootVehicle.childVehicles
	local hash = ""

	for i = 1, #vehicles do
		hash = hash .. vehicle.typeName
	end

	return hash
end

function InputHelpDisplay:getAvailableHeight()
	local mapTop = self.ingameMap:getRequiredHeight()
	local commTop = 0

	if self.communicationDisplay:getVisible() then
		local _, commPosY = self.communicationDisplay:getPosition()
		commTop = commPosY + self.communicationDisplay:getHeight()
	end

	local otherElementsTop = math.max(mapTop, commTop)

	return 1 - g_safeFrameOffsetY * 2 - otherElementsTop - self.minimumMapSpacingY
end

function InputHelpDisplay:updateInputContext()
	local availableHeight = self:getAvailableHeight()

	if not self.animation:getFinished() then
		availableHeight = math.min(availableHeight, self.animationAvailableHeight)
	end

	local pressedComboMaskGamepad, pressedComboMaskMouse = self.inputManager:getComboCommandPressedMask()
	local useGamepadButtons = self.isConsoleVersion or self.inputManager:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD

	self:updateComboHeaders(useGamepadButtons, pressedComboMaskMouse, pressedComboMaskGamepad)

	if self.hasComboCommands then
		availableHeight = availableHeight - self.headerHeight
	end

	local helpElements, usedHeight = self:getInputHelpElements(availableHeight, pressedComboMaskGamepad, pressedComboMaskMouse, useGamepadButtons)
	self.visibleHelpElements = helpElements
	availableHeight = availableHeight - usedHeight

	for _, text in pairs(self.extraHelpTexts) do
		if availableHeight - self.entryHeight >= 0 then
			local extraTextHelpElement = InputHelpElement.new(nil, , , , , text)

			table.insert(helpElements, extraTextHelpElement)

			availableHeight = availableHeight - self.entryHeight
		else
			break
		end
	end

	self:updateEntries(helpElements)

	self.currentAvailableHeight = availableHeight
end

function InputHelpDisplay:updateEntries(helpElements)
	local usedCount = 0
	local entryCount = #self.entries
	local separatorCount = math.min(#helpElements - 1, entryCount - 1)

	if self.extensionsHeight > 0 and not self.ingameMap:getIsLarge() then
		separatorCount = separatorCount + 1
	end

	for i = 1, entryCount do
		local entry = self.entries[i]

		if i <= #helpElements then
			usedCount = usedCount + 1
			local helpElement = helpElements[i]
			local showInput = #helpElement.buttons > 0 or #helpElement.keys > 0
			local showText = helpElement.textLeft ~= ""

			entry:setVisible(showInput or showText)
			self.inputGlyphs[i]:setVisible(not showText)
			self.inputGlyphs[i].background:setVisible(not showText)

			if helpElement.actionName ~= "" then
				if helpElement.actionName2 ~= "" then
					self.inputGlyphs[i]:setActions({
						helpElement.actionName,
						helpElement.actionName2
					}, nil, , helpElement.inlineModifierButtons)
				else
					self.inputGlyphs[i]:setAction(helpElement.actionName, nil, , helpElement.inlineModifierButtons)
				end

				self.entryGlyphWidths[i] = self.inputGlyphs[i]:getGlyphWidth()

				self.inputGlyphs[i].background:setDimension(self.entryGlyphWidths[i] + 2 * self.inputGlyphs[i].spacing)
			else
				self.entryGlyphWidths[i] = 0
			end
		else
			entry:setVisible(false)
		end
	end

	for i = 1, #self.horizontalSeparators do
		local separator = self.horizontalSeparators[i]

		separator:setVisible(i <= separatorCount)
	end

	self.sizeAndPositionDirty = self.sizeAndPositionDirty or self.numUsedEntries ~= usedCount
	self.numUsedEntries = usedCount
end

function InputHelpDisplay:updateComboHeaders(useGamepadButtons, pressedComboMaskMouse, pressedComboMaskGamepad)
	local comboActionStatus = self.inputDisplayManager:getComboHelpElements(useGamepadButtons)
	local hasComboCommands = next(comboActionStatus) ~= nil
	self.sizeAndPositionDirty = self.sizeAndPositionDirty or self.hasComboCommands ~= hasComboCommands
	self.hasComboCommands = hasComboCommands

	if self.hasComboCommands then
		self:updateComboInputGlyphs(comboActionStatus, pressedComboMaskMouse, pressedComboMaskGamepad)
	end

	self.mouseComboHeader:setVisible(self.hasComboCommands and not useGamepadButtons)
	self.gamepadComboHeader:setVisible(self.hasComboCommands and useGamepadButtons)
end

function InputHelpDisplay:updateComboInputGlyphs(comboActionStatus, pressedComboMaskMouse, pressedComboMaskGamepad)
	self.comboIterator[InputBinding.MOUSE_COMBOS] = pressedComboMaskMouse
	self.comboIterator[InputBinding.GAMEPAD_COMBOS] = pressedComboMaskGamepad

	for actionCombos, pressedComboMask in pairs(self.comboIterator) do
		for actionName, comboData in pairs(actionCombos) do
			local comboGlyph = self.comboInputGlyphs[actionName]

			if comboActionStatus[actionName] then
				comboGlyph:setVisible(true)

				local isPressed = bitAND(pressedComboMask, comboData.mask) ~= 0

				if isPressed then
					comboGlyph:setButtonGlyphColor(InputHelpDisplay.COLOR.COMBO_GLYPH_PRESSED)
				else
					comboGlyph:setButtonGlyphColor(InputHelpDisplay.COLOR.COMBO_GLYPH)
				end
			else
				comboGlyph:setVisible(false)
			end
		end
	end
end

function InputHelpDisplay:getInputHelpElements(availableHeight, pressedComboMaskGamepad, pressedComboMaskMouse, useGamepadButtons)
	local currentPressedMask = useGamepadButtons and pressedComboMaskGamepad or pressedComboMaskMouse
	local isCombo = currentPressedMask ~= 0
	local isFillUp = false
	local eventHelpElements = self.inputDisplayManager:getEventHelpElements(currentPressedMask, useGamepadButtons)

	if #eventHelpElements == 0 and not self.hasComboCommands and isCombo then
		eventHelpElements = self.inputDisplayManager:getEventHelpElements(0, useGamepadButtons)
		isFillUp = true
	end

	self.currentHelpElementCount = #eventHelpElements
	local helpElements = {}
	local usedHeight = 0
	local i = 1

	while availableHeight >= usedHeight + self.entryHeight and i <= #eventHelpElements do
		if not self:getIsHelpElementAllowed(helpElements, eventHelpElements[i]) then
			break
		end

		table.insert(helpElements, eventHelpElements[i])

		usedHeight = usedHeight + self.entryHeight
		i = i + 1
	end

	local contextCustomElements = self.customHelpElements[self.inputManager:getContextName()]

	if contextCustomElements ~= nil then
		self.currentHelpElementCount = self.currentHelpElementCount + #contextCustomElements
		i = 1

		while availableHeight >= usedHeight + self.entryHeight and i <= #contextCustomElements do
			local customHelpElement = contextCustomElements[i]

			if customHelpElement ~= InputDisplayManager.NO_HELP_ELEMENT then
				local action = self.inputManager:getActionByName(customHelpElement.actionName)

				if action ~= nil then
					local fitsComboMask = action.comboMaskGamepad == pressedComboMaskGamepad and action.comboMaskMouse == pressedComboMaskMouse
					local noComboFillUp = action.comboMaskGamepad == 0 and action.comboMaskMouse == 0 and isFillUp

					if fitsComboMask or noComboFillUp then
						table.insert(helpElements, customHelpElement)

						usedHeight = usedHeight + self.entryHeight
					end
				end
			end

			i = i + 1
		end
	end

	return helpElements, usedHeight
end

function InputHelpDisplay:setAnimationAvailableHeight(value)
	self.animationAvailableHeight = math.min(value, self:getAvailableHeight())
end

function InputHelpDisplay:setAnimationOffset(offX, offY)
	self.animationOffsetY = offY
	self.animationOffsetX = offX
end

function InputHelpDisplay:animateHide()
	local transX, transY = self:getHidingTranslation()
	local sequence = TweenSequence.new(self)
	local foldEntries = Tween.new(self.setAnimationAvailableHeight, self:getAvailableHeight(), 0, HUDDisplayElement.MOVE_ANIMATION_DURATION)
	local moveOut = MultiValueTween.new(self.setAnimationOffset, {
		0,
		0
	}, {
		transX,
		transY
	}, HUDDisplayElement.MOVE_ANIMATION_DURATION)

	sequence:addTween(foldEntries)
	sequence:addTween(moveOut)
	sequence:addCallback(self.onAnimateVisibilityFinished, false)
	sequence:start()

	self.animation = sequence
end

function InputHelpDisplay:animateShow()
	InputHelpDisplay:superClass().setVisible(self, true)

	local transX, transY = self:getHidingTranslation()
	local sequence = TweenSequence.new(self)
	local moveIn = MultiValueTween.new(self.setAnimationOffset, {
		transX,
		transY
	}, {
		0,
		0
	}, HUDDisplayElement.MOVE_ANIMATION_DURATION)
	local unfoldEntries = Tween.new(self.setAnimationAvailableHeight, 0, self:getAvailableHeight(), HUDDisplayElement.MOVE_ANIMATION_DURATION)

	sequence:addTween(moveIn)
	sequence:addTween(unfoldEntries)
	sequence:addCallback(self.onAnimateVisibilityFinished, true)
	sequence:start()

	self.animation = sequence
end

function InputHelpDisplay:onAnimateVisibilityFinished(isVisible)
	InputHelpDisplay:superClass().onAnimateVisibilityFinished(self, isVisible)

	self.animationEntryCount = 0
end

function InputHelpDisplay:onInputDevicesChanged()
	for _, combos in pairs({
		InputBinding.ORDERED_MOUSE_COMBOS,
		InputBinding.ORDERED_GAMEPAD_COMBOS
	}) do
		for i, combo in ipairs(combos) do
			local actionName = combo.controls
			local glyphElement = self.comboInputGlyphs[actionName]
			local prevWidth = glyphElement:getGlyphWidth()

			glyphElement:setAction(actionName, nil, , false, true)

			local glyphWidth = glyphElement:getGlyphWidth()

			if prevWidth ~= glyphWidth and i > 1 then
				local posX, posY = glyphElement:getPosition()

				if i == #combos then
					posX = posX + prevWidth - glyphWidth
				else
					posX = posX + (prevWidth - glyphWidth) * 0.5
				end

				glyphElement:setPosition(posX, posY)
			end
		end
	end
end

function InputHelpDisplay:onMenuVisibilityChange(isMenuVisible, isOverlayMenu)
	self.isOverlayMenuVisible = isMenuVisible and isOverlayMenu
end

function InputHelpDisplay:draw()
	local needInfos = self:getVisible() and #self.visibleHelpElements > 0 or self.hasComboCommands
	local needBackground = needInfos or not self.animation:getFinished() and self.currentHelpElementCount > 0

	if needBackground then
		InputHelpDisplay:superClass().draw(self)
	end

	if needInfos then
		self:drawHelpInfos()
		self:drawVehicleHUDExtensions()
		self:drawControlsLabel()
	end
end

function InputHelpDisplay:drawControlsLabel()
	setTextBold(true)
	setTextColor(unpack(InputHelpDisplay.COLOR.CONTROLS_LABEL))
	setTextAlignment(RenderText.ALIGN_LEFT)

	local baseX, baseY = self:getPosition()
	local baseTopY = baseY + self:getHeight()
	local frameX = baseX + self.frameOffsetX
	local frameTopY = baseTopY + self.frameOffsetY
	local posX = frameX + self.controlsLabelOffsetX
	local posY = frameTopY + self.controlsLabelOffsetY

	renderText(posX, posY, self.controlsLabelTextSize, self.controlsLabelText)
end

function InputHelpDisplay:drawHelpInfos()
	local framePosX, framePosY = self.entriesFrame:getPosition()
	local entriesHeight = self.entriesFrame:getHeight()

	for i, helpElement in ipairs(self.visibleHelpElements) do
		local entryPosY = framePosY + entriesHeight - i * self.entryHeight

		if helpElement.iconOverlay ~= nil then
			local posX = framePosX + self.entryWidth - self.axisIconWidth + self.axisIconOffsetX
			local posY = entryPosY + self.entryHeight * 0.5

			helpElement.iconOverlay:setPosition(posX, posY)
			helpElement.iconOverlay:setDimension(self.axisIconWidth, self.axisIconHeight)
			helpElement.iconOverlay:render()
		else
			setTextBold(false)
			setTextColor(unpack(InputHelpDisplay.COLOR.HELP_TEXT))

			local text = ""
			local posX = framePosX
			local posY = entryPosY
			local textLeftX = 1

			if helpElement.textRight ~= "" then
				setTextAlignment(RenderText.ALIGN_RIGHT)

				text = helpElement.textRight
				local textWidth = getTextWidth(self.helpTextSize, text)
				posX = posX + self.entryWidth + self.helpTextOffsetX
				posY = posY + (self.entryHeight - self.helpTextSize) * 0.5 + self.helpTextOffsetY
				textLeftX = posX - textWidth
			elseif helpElement.textLeft ~= "" then
				setTextAlignment(RenderText.ALIGN_LEFT)

				text = helpElement.textLeft
				posX = posX + self.extraTextOffsetX
				posY = posY + (self.entryHeight - self.helpTextSize) * 0.5 + self.extraTextOffsetY
				textLeftX = posX
			end

			local glyphWidth = self.entryGlyphWidths[i] or 0
			local glyphLeftX = glyphWidth ~= 0 and self.inputGlyphs[i]:getPosition() or 0
			local glyphRightX = glyphLeftX + glyphWidth

			if textLeftX > glyphRightX then
				renderText(posX, posY, self.helpTextSize, text)
			else
				local availableTextWidth = posX - glyphRightX - math.abs(self.helpTextOffsetX)

				setTextWrapWidth(availableTextWidth)
				setTextLineBounds(0, 2)

				posY = entryPosY + self.entryHeight * 0.5 + self.helpTextOffsetY

				renderText(posX, posY, self.helpTextSize, text)
				setTextWrapWidth(0)
				setTextLineBounds(0, 0)
			end
		end
	end
end

function InputHelpDisplay:drawVehicleHUDExtensions()
	if self.extensionsHeight > 0 then
		local leftPosX = self:getPosition()
		local width = self:getWidth()
		local posY = self.extensionsStartY
		local usedHeight = 0

		for _, extension in pairs(self.vehicleHudExtensions) do
			local extHeight = extension:getDisplayHeight()

			if extension:canDraw() and usedHeight + extHeight <= self.extensionsHeight then
				posY = posY - extHeight - self.entryOffsetY

				self.extensionBg:setPosition(leftPosX, posY)
				self.extensionBg:setDimension(width, extHeight)
				self.extensionBg:render()
				extension:draw(leftPosX + self.extraTextOffsetX, leftPosX + width + self.helpTextOffsetX, posY)

				usedHeight = usedHeight + extHeight
			end
		end
	end
end

function InputHelpDisplay:setScale(uiScale)
	InputHelpDisplay:superClass().setScale(self, uiScale, uiScale)
	self:storeScaledValues()
end

function InputHelpDisplay:storeScaledValues()
	self.headerHeight = self:scalePixelToScreenHeight(InputHelpDisplay.SIZE.HEADER[2])
	self.entryWidth, self.entryHeight = self:scalePixelToScreenVector(InputHelpDisplay.SIZE.HELP_ENTRY)
	self.controlsLabelTextSize = self:scalePixelToScreenHeight(HUDElement.TEXT_SIZE.DEFAULT_TITLE)
	self.controlsLabelOffsetX, self.controlsLabelOffsetY = self:scalePixelToScreenVector(InputHelpDisplay.POSITION.CONTROLS_LABEL)
	self.helpTextSize = self:scalePixelToScreenHeight(HUDElement.TEXT_SIZE.DEFAULT_TEXT)
	self.helpTextOffsetX, self.helpTextOffsetY = self:scalePixelToScreenVector(InputHelpDisplay.POSITION.HELP_TEXT)
	self.extraTextOffsetX, self.extraTextOffsetY = self:scalePixelToScreenVector(InputHelpDisplay.POSITION.EXTRA_TEXT)
	self.axisIconOffsetX = self:scalePixelToScreenWidth(InputHelpDisplay.POSITION.AXIS_ICON[1])
	self.axisIconWidth, self.axisIconHeight = self:scalePixelToScreenVector(InputHelpDisplay.SIZE.AXIS_ICON)
	self.frameOffsetX, self.frameOffsetY = self:scalePixelToScreenVector(InputHelpDisplay.POSITION.FRAME)
	self.frameBarOffsetY = self:scalePixelToScreenHeight(HUDFrameElement.THICKNESS.BAR)
	self.minimumMapSpacingY = self:scalePixelToScreenHeight(InputHelpDisplay.MIN_MAP_SPACING)
	self.entryOffsetX, self.entryOffsetY = self:scalePixelToScreenVector(InputHelpDisplay.SIZE.HELP_ENTRY_OFFSET)

	for _, element in ipairs(self.inputGlyphs) do
		element.spacing = self:scalePixelToScreenWidth(InputHelpDisplay.POSITION.INPUT_GLYPH[1])
	end
end

function InputHelpDisplay.getBackgroundPosition()
	return g_safeFrameOffsetX, 1 - g_safeFrameOffsetY
end

function InputHelpDisplay:getTopLeftPosition()
	local posX, posY = InputHelpDisplay.getBackgroundPosition()

	if not self.animation:getFinished() then
		posX = posX + self.animationOffsetX
		posY = posY + self.animationOffsetY
	end

	return posX, posY
end

function InputHelpDisplay:getMaxEntryCount(prio, ignoreLive)
	prio = Utils.getNoNil(prio, false)
	local count = prio and InputHelpDisplay.ENTRY_COUNT_PC or InputHelpDisplay.ENTRY_COUNT_PRIO_PC

	if self.isConsoleVersion then
		count = prio and InputHelpDisplay.ENTRY_COUNT_CONSOLE or InputHelpDisplay.ENTRY_COUNT_PRIO_CONSOLE
	end

	if not ignoreLive then
		if self.hasComboCommands then
			count = count - 1
		end

		count = count - #self.extraHelpTexts
	end

	return count
end

function InputHelpDisplay:getIsHelpElementAllowed(helpElements, helpElement)
	if self:getMaxEntryCount(true) <= #helpElements then
		if GS_PRIO_NORMAL < helpElement.priority and not self.isOverlayMenuVisible then
			return false
		elseif self:getMaxEntryCount(false) <= #helpElements then
			return false
		end
	end

	return true
end

function InputHelpDisplay:setDimension(width, height)
	InputHelpDisplay:superClass().setDimension(self, width, height)
	self.frame:setDimension(width, height + self.frameOffsetY + self.frameBarOffsetY)
end

function InputHelpDisplay.createBackground()
	local posX, posY = InputHelpDisplay.getBackgroundPosition()
	local width, height = getNormalizedScreenValues(unpack(InputHelpDisplay.SIZE.HELP_ENTRY))
	local overlay = Overlay.new(nil, posX, posY, width, height)

	return overlay
end

function InputHelpDisplay:createComponents(hudAtlasPath)
	local baseWidth, baseHeight = getNormalizedScreenValues(unpack(InputHelpDisplay.SIZE.HELP_ENTRY))
	local baseX, baseY = self:getPosition()
	local frame = self:createFrame(hudAtlasPath, baseX, baseY, baseWidth, baseHeight)
	local maxEntries = self:getMaxEntryCount(nil, true)
	local frameX, frameY = frame:getPosition()

	self:createEntries(hudAtlasPath, frameX, frameY, maxEntries)
	self:createMouseComboHeader(hudAtlasPath, frameX, frameY)
	self:createControllerComboHeader(hudAtlasPath, frameX, frameY)
end

function InputHelpDisplay:createFrame(hudAtlasPath, baseX, baseY, width, height)
	local frame = HUDFrameElement.new(hudAtlasPath, baseX, baseY, width, height)

	frame:setColor(unpack(HUD.COLOR.FRAME_BACKGROUND))

	self.frame = frame

	return frame
end

function InputHelpDisplay:createVerticalSeparator(hudAtlasPath, leftPosX, centerPosY)
	local width, height = self:scalePixelToScreenVector(InputHelpDisplay.SIZE.VERTICAL_SEPARATOR)
	width = math.max(width, 1 / g_screenWidth)
	local overlay = Overlay.new(hudAtlasPath, leftPosX + width * 0.5, centerPosY - height * 0.5, width, height)

	overlay:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
	overlay:setColor(unpack(InputHelpDisplay.COLOR.SEPARATOR))

	return HUDElement.new(overlay)
end

function InputHelpDisplay:createHorizontalSeparator(hudAtlasPath, leftPosX, posY)
	local width, height = self:scalePixelToScreenVector(InputHelpDisplay.SIZE.HORIZONTAL_SEPARATOR)
	height = math.max(height, 1 / g_screenHeight)
	local overlay = Overlay.new(hudAtlasPath, leftPosX, posY - height * 0.5, width, height)

	overlay:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
	overlay:setColor(unpack(InputHelpDisplay.COLOR.SEPARATOR))

	return HUDElement.new(overlay)
end

function InputHelpDisplay:createComboInputGlyph(posX, posY, width, height, actionName)
	local element = InputGlyphElement.new(self.inputDisplayManager, width, height)

	element:setPosition(posX, posY)
	element:setKeyboardGlyphColor(InputHelpDisplay.COLOR.COMBO_GLYPH)
	element:setButtonGlyphColor(InputHelpDisplay.COLOR.COMBO_GLYPH)
	element:setAction(actionName, nil, , false, true)

	return element
end

function InputHelpDisplay:createComboHeader(hudAtlasPath, frameX, frameY, combos, boxSize, separatorPositions)
	local width, height = self:scalePixelToScreenVector(InputHelpDisplay.SIZE.HEADER)
	local posY = frameY - height
	local bgOverlay = Overlay.new(nil, frameX, posY, width, height)
	local headerElement = HUDElement.new(bgOverlay)
	local entryOffset, _ = self:scalePixelToScreenVector(InputHelpDisplay.SIZE.HELP_ENTRY_OFFSET)
	local headerItemWidth = (width - entryOffset * (#combos - 1)) / #combos
	local glyphWidth, glyphHeight = self:scalePixelToScreenVector(InputHelpDisplay.SIZE.COMBO_GLYPH)
	local boxWidth, boxHeight = self:scalePixelToScreenVector(boxSize)
	local count = 0

	for i, combo in ipairs(combos) do
		local overlay = Overlay.new(g_baseUIFilename, frameX + headerItemWidth * (i - 1) + entryOffset * (i - 1), posY, headerItemWidth, height)

		overlay:setUVs(g_colorBgUVs)
		overlay:setColor(0, 0, 0, 0.56)
		headerElement:addChild(HUDElement.new(overlay))

		local actionName = combo.controls
		local glyphElement = self:createComboInputGlyph(0, 0, glyphWidth, glyphHeight, actionName)
		local glyphModifiedWidth = glyphElement:getGlyphWidth()
		local glyphPosX = frameX + boxWidth * count + (boxWidth - glyphModifiedWidth) * 0.5
		local glyphPosY = posY + (boxHeight - glyphHeight) * 0.5

		if i == 1 then
			local offX = self:scalePixelToScreenWidth(InputHelpDisplay.POSITION.INPUT_GLYPH[1])
			glyphPosX = frameX + offX
		elseif i == #combos then
			local offX = self:scalePixelToScreenWidth(InputHelpDisplay.POSITION.AXIS_ICON[1]) - glyphModifiedWidth
			glyphPosX = frameX + boxWidth * i + offX
		end

		glyphElement:setPosition(glyphPosX, glyphPosY)
		headerElement:addChild(glyphElement)

		self.comboInputGlyphs[actionName] = glyphElement
		count = count + 1
	end

	return headerElement
end

function InputHelpDisplay:createMouseComboHeader(hudAtlasPath, frameX, frameY)
	local header = self:createComboHeader(hudAtlasPath, frameX, frameY, InputBinding.ORDERED_MOUSE_COMBOS, InputHelpDisplay.SIZE.MOUSE_COMBO_BOX, InputHelpDisplay.POSITION.MOUSE_COMBO_SEPARATOR)
	self.mouseComboHeader = header

	self:addChild(header)
end

function InputHelpDisplay:createControllerComboHeader(hudAtlasPath, frameX, frameY)
	local header = self:createComboHeader(hudAtlasPath, frameX, frameY, InputBinding.ORDERED_GAMEPAD_COMBOS, InputHelpDisplay.SIZE.GAMEPAD_COMBO_BOX, InputHelpDisplay.POSITION.GAMEPAD_COMBO_SEPARATOR)
	self.gamepadComboHeader = header

	self:addChild(header)
end

function InputHelpDisplay:createEntry(hudAtlasPath, posX, posY, width, height)
	local overlay = Overlay.new(g_baseUIFilename, posX, posY, width, height)

	overlay:setUVs(g_colorBgUVs)
	overlay:setColor(0, 0, 0, 0.56)

	local entryElement = HUDElement.new(overlay)
	local glyphWidth, glyphHeight = self:scalePixelToScreenVector(InputHelpDisplay.SIZE.INPUT_GLYPH)
	local offX = self:scalePixelToScreenWidth(InputHelpDisplay.POSITION.INPUT_GLYPH[1])
	local offY = (height - glyphHeight) * 0.5
	overlay = Overlay.new(g_baseUIFilename, posX, posY, glyphWidth + 2 * offX, height)

	overlay:setUVs(g_colorBgUVs)
	overlay:setColor(0, 0, 0, 0.6)

	local glyphBackground = HUDElement.new(overlay)

	entryElement:addChild(glyphBackground)

	local glyphElement = InputGlyphElement.new(self.inputDisplayManager, glyphWidth, glyphHeight)

	glyphElement:setPosition(posX + offX, posY + offY)
	glyphElement:setKeyboardGlyphColor(InputHelpDisplay.COLOR.INPUT_GLYPH)

	glyphElement.background = glyphBackground
	glyphElement.spacing = offX

	entryElement:addChild(glyphElement)
	table.insert(self.inputGlyphs, glyphElement)

	return entryElement
end

function InputHelpDisplay:createEntries(hudAtlasPath, frameX, frameY, count)
	local posX = frameX
	local posY = frameY
	local entryWidth, entryHeight = self:scalePixelToScreenVector(InputHelpDisplay.SIZE.HELP_ENTRY)
	local _, entryOffset = self:scalePixelToScreenVector(InputHelpDisplay.SIZE.HELP_ENTRY_OFFSET)
	local overlay = Overlay.new(nil, posX, posY, entryWidth, entryHeight * count)
	local entriesFrame = HUDElement.new(overlay)
	self.entriesFrame = entriesFrame

	self:addChild(entriesFrame)

	local totalHeight = count * entryHeight

	for i = 1, count do
		posY = frameY + totalHeight - entryHeight * i
		local entry = self:createEntry(hudAtlasPath, posX, posY, entryWidth, entryHeight - entryOffset)

		table.insert(self.entries, entry)
		table.insert(self.entryGlyphWidths, 0)
		entriesFrame:addChild(entry)
	end
end

InputHelpDisplay.WIDTH = 465
InputHelpDisplay.HEADER_HEIGHT = 72
InputHelpDisplay.MIN_MAP_SPACING = 40
InputHelpDisplay.SIZE = {
	HEADER = {
		InputHelpDisplay.WIDTH,
		InputHelpDisplay.HEADER_HEIGHT
	},
	MOUSE_COMBO_BOX = {
		InputHelpDisplay.WIDTH / 4,
		InputHelpDisplay.HEADER_HEIGHT
	},
	GAMEPAD_COMBO_BOX = {
		InputHelpDisplay.WIDTH / 3,
		InputHelpDisplay.HEADER_HEIGHT
	},
	VERTICAL_SEPARATOR = {
		1,
		36
	},
	COMBO_GLYPH = {
		36,
		36
	},
	INPUT_GLYPH = {
		36,
		36
	},
	AXIS_ICON = {
		36,
		36
	},
	HORIZONTAL_SEPARATOR = {
		InputHelpDisplay.WIDTH,
		1
	},
	HELP_ENTRY = {
		InputHelpDisplay.WIDTH,
		54
	},
	HELP_ENTRY_OFFSET = {
		2,
		2
	}
}
InputHelpDisplay.POSITION = {
	FRAME = {
		0,
		-36
	},
	VEHICE_SCHEMA = {
		0,
		0
	},
	MOUSE_COMBO_SEPARATOR = {
		{
			InputHelpDisplay.SIZE.MOUSE_COMBO_BOX[1],
			0
		},
		{
			InputHelpDisplay.SIZE.MOUSE_COMBO_BOX[1] * 2,
			0
		},
		{
			InputHelpDisplay.SIZE.MOUSE_COMBO_BOX[1] * 3,
			0
		}
	},
	GAMEPAD_COMBO_SEPARATOR = {
		{
			InputHelpDisplay.SIZE.GAMEPAD_COMBO_BOX[1],
			0
		},
		{
			InputHelpDisplay.SIZE.GAMEPAD_COMBO_BOX[1] * 2,
			0
		}
	},
	INPUT_GLYPH = {
		8,
		0
	},
	AXIS_ICON = {
		-16,
		0
	},
	HELP_TEXT = {
		-16,
		3
	},
	EXTRA_TEXT = {
		16,
		0
	},
	CONTROLS_LABEL = {
		0,
		4
	}
}
InputHelpDisplay.COLOR = {
	COMBO_GLYPH = {
		1,
		1,
		1,
		0.4
	},
	COMBO_GLYPH_PRESSED = {
		1,
		1,
		1,
		1
	},
	INPUT_GLYPH = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	CONTROLS_LABEL = {
		1,
		1,
		1,
		1
	},
	HELP_TEXT = {
		1,
		1,
		1,
		1
	},
	SEPARATOR = {
		1,
		1,
		1,
		0.3
	}
}
