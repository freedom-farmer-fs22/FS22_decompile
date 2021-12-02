LicensePlateDialog = {}
local LicensePlateDialog_mt = Class(LicensePlateDialog, InfoDialog)
LicensePlateDialog.CONTROLS = {
	"sceneRender",
	"backButton",
	"changeColorButton",
	"changeColorButtonImage",
	"okButton",
	"buttonCursorLeft",
	"buttonCursorRight",
	"keyboardButtonTemplate",
	"keyboardAlpha",
	"keyboardNumeric",
	"keyboardSpecial",
	"cursorElement",
	"placementOption",
	"typeOption"
}

function LicensePlateDialog.new(target, custom_mt)
	local self = InfoDialog.new(target, custom_mt or LicensePlateDialog_mt)
	self.currentVariation = 1
	self.currentColorIndex = 1

	self:registerControls(LicensePlateDialog.CONTROLS)

	return self
end

function LicensePlateDialog:delete()
	if self.keyboardButtonTemplate ~= nil then
		self.keyboardButtonTemplate:delete()
	end

	LicensePlateDialog:superClass().delete(self)
end

function LicensePlateDialog:onCreate()
	LicensePlateDialog:superClass().onCreate(self)
	self.keyboardButtonTemplate:unlinkElement()
	FocusManager:removeElement(self.keyboardButtonTemplate)
end

function LicensePlateDialog:onOpen()
	LicensePlateDialog:superClass().onOpen(self)

	self.needsFirstFocusUpdate = true
	local colors, _ = g_licensePlateManager:getAvailableColors()

	self.changeColorButton.parent:setVisible(#colors > 1)

	self.currentCursorPosition = 1
	self.cursorPositions = {}

	self.sceneRender:createScene()
	self:createKeyboards()
end

function LicensePlateDialog:onClose()
	LicensePlateDialog:superClass().onClose(self)
	self.sceneRender:destroyScene()
end

function LicensePlateDialog:setLicensePlateData(licensePlateData)
	self.currentVariation = licensePlateData.variation or self.currentVariation
	self.currentCharacters = table.copy(licensePlateData.characters, math.huge)
	local _, defaultColorIndex = g_licensePlateManager:getAvailableColors()
	self.currentColorIndex = licensePlateData.colorIndex or defaultColorIndex or self.currentColorIndex

	self:updateColorButton()

	self.currentPlacementIndex = licensePlateData.placementIndex or g_licensePlateManager:getDefaultPlacementIndex()

	for i = 1, #self.textToPlacementIndex do
		if self.textToPlacementIndex[i] == self.currentPlacementIndex then
			self.placementOption:setState(i)
		end
	end
end

function LicensePlateDialog:setCallback(callbackFunction, target, args)
	self.callbackFunction = callbackFunction
	self.target = target
	self.args = args
end

function LicensePlateDialog:sendCallback(variation, characters, colorIndex, placementIndex)
	local licensePlateData = nil

	if variation ~= nil and characters ~= nil and colorIndex ~= nil and placementIndex ~= nil then
		licensePlateData = {
			variation = variation,
			characters = characters,
			colorIndex = colorIndex,
			placementIndex = placementIndex
		}
	end

	if self.callbackFunction ~= nil then
		if self.target ~= nil then
			self.callbackFunction(self.target, licensePlateData, self.args)
		else
			self.callbackFunction(licensePlateData, self.args)
		end
	end
end

function LicensePlateDialog:createKeyboards()
	local font = g_licensePlateManager:getFont()

	local function updateButtons(characterType, list)
		for i = #list.elements, 1, -1 do
			list:removeElement(list.elements[i])
		end

		local characters = font.charactersByType[characterType]

		for i = 1, #characters do
			local button = self.keyboardButtonTemplate:clone(list)
			button.focusId = nil

			FocusManager:loadElementFromCustomValues(button)

			local character = characters[i]
			button.keyboardValue = character.value

			button:setText(character.value)
		end

		list:invalidateLayout()
	end

	updateButtons(MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL, self.keyboardAlpha)
	updateButtons(MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL, self.keyboardNumeric)
	updateButtons(MaterialManager.FONT_CHARACTER_TYPE.SPECIAL, self.keyboardSpecial)

	local firstAvailableButton = self:updateFocusLinking(false, false, false)

	FocusManager:setFocus(firstAvailableButton)
end

function LicensePlateDialog:updateFocusLinking(alphabetical, numerical, special)
	local firstAvailableButton, above = nil
	local below = self.typeOption

	FocusManager:linkElements(self.buttonCursorLeft, FocusManager.RIGHT, self.buttonCursorRight)
	FocusManager:linkElements(self.buttonCursorLeft, FocusManager.LEFT, self.buttonCursorLeft)
	FocusManager:linkElements(self.buttonCursorRight, FocusManager.RIGHT, self.buttonCursorRight)
	FocusManager:linkElements(self.buttonCursorRight, FocusManager.LEFT, self.buttonCursorLeft)

	if alphabetical then
		firstAvailableButton = firstAvailableButton or self.keyboardAlpha.elements[1]
		local numCols = 10

		for i = 1, #self.keyboardAlpha.elements do
			local button = self.keyboardAlpha.elements[i]
			local leftButton = self.keyboardAlpha.elements[i - 1]
			local rightButton = self.keyboardAlpha.elements[i + 1]
			local topButton = self.keyboardAlpha.elements[i - numCols]
			local bottomButton = self.keyboardAlpha.elements[i + numCols]

			if leftButton ~= nil then
				FocusManager:linkElements(button, FocusManager.LEFT, leftButton)
			else
				FocusManager:linkElements(button, FocusManager.LEFT, button)
			end

			if rightButton ~= nil then
				FocusManager:linkElements(button, FocusManager.RIGHT, rightButton)
			else
				FocusManager:linkElements(button, FocusManager.RIGHT, button)
			end

			if topButton ~= nil then
				FocusManager:linkElements(button, FocusManager.TOP, topButton)
			elseif above ~= nil then
				FocusManager:linkElements(button, FocusManager.TOP, above)
			elseif i <= 5 then
				FocusManager:linkElements(button, FocusManager.TOP, self.buttonCursorLeft)
			else
				FocusManager:linkElements(button, FocusManager.TOP, self.buttonCursorRight)
			end

			if bottomButton ~= nil then
				FocusManager:linkElements(button, FocusManager.BOTTOM, bottomButton)
			else
				FocusManager:linkElements(button, FocusManager.BOTTOM, below)
			end
		end
	end

	if numerical then
		firstAvailableButton = firstAvailableButton or self.keyboardNumeric.elements[1]
	end

	if special then
		firstAvailableButton = firstAvailableButton or self.keyboardSpecial.elements[1]
	end

	if firstAvailableButton ~= nil then
		FocusManager:linkElements(self.typeOption, FocusManager.TOP, firstAvailableButton)
		FocusManager:linkElements(self.buttonCursorLeft, FocusManager.BOTTOM, firstAvailableButton)
		FocusManager:linkElements(self.buttonCursorRight, FocusManager.BOTTOM, firstAvailableButton)

		if self.needsFirstFocusUpdate or FocusManager:getFocusedElement() ~= nil and FocusManager:getFocusedElement():getIsDisabled() then
			FocusManager:setFocus(firstAvailableButton)

			self.needsFirstFocusUpdate = false
		end
	end
end

function LicensePlateDialog:updateCursor()
	local positionInfo = self.cursorPositions[self.currentCursorPosition]

	self.cursorElement:setSize(positionInfo.width, positionInfo.height)
	self.cursorElement:setAbsolutePosition(positionInfo.x, positionInfo.y)

	local values = self.licensePlate.variations[self.currentVariation].values
	local value = values[1]
	local realIndex = 1

	for i = 1, #values do
		if not values[i].isStatic and not values[i].locked then
			if realIndex == self.currentCursorPosition then
				value = values[i]

				break
			end

			realIndex = realIndex + 1
		end
	end

	for _, element in ipairs(self.keyboardAlpha.elements) do
		local isDisabled = element.overlayState == GuiOverlay.STATE_DISABLED
		local shouldBeDisabled = not value.alphabetical

		if isDisabled ~= shouldBeDisabled then
			element:setDisabled(shouldBeDisabled)
		end
	end

	for _, element in ipairs(self.keyboardNumeric.elements) do
		local isDisabled = element.overlayState == GuiOverlay.STATE_DISABLED
		local shouldBeDisabled = not value.numerical

		if isDisabled ~= shouldBeDisabled then
			element:setDisabled(shouldBeDisabled)
		end
	end

	for _, element in ipairs(self.keyboardSpecial.elements) do
		local isDisabled = element.overlayState == GuiOverlay.STATE_DISABLED
		local shouldBeDisabled = not value.special

		if isDisabled ~= shouldBeDisabled then
			element:setDisabled(shouldBeDisabled)
		end
	end

	self:updateFocusLinking(value.alphabetical, value.numerical, value.special)
end

function LicensePlateDialog:updateVariations()
	local texts = {}
	local typeText = g_i18n:getText("ui_licensePlateTypeItem")

	for i = 1, #self.licensePlate.variations do
		table.insert(texts, string.format(typeText, i))
	end

	self.typeOption:setTexts(texts)
	self.typeOption:setState(self.currentVariation)
end

function LicensePlateDialog:updateColorButton()
	if self.licensePlate ~= nil then
		local r, g, b = unpack(self.licensePlate:getColor(self.currentColorIndex))

		self.changeColorButtonImage:setImageColor(nil, r, g, b, 1)
	end
end

function LicensePlateDialog:updateLicensePlateGraphics()
	self.licensePlate:updateData(self.currentVariation, LicensePlateManager.PLATE_POSITION.BACK, table.concat(self.currentCharacters, ""))
	self.licensePlate:setColorIndex(self.currentColorIndex)
	self:updateColorButton()
	self.sceneRender:setRenderDirty()

	local values = g_licensePlateManager:getLicensePlateValues(self.licensePlate, self.currentVariation)
	self.cursorPositions = {}
	local camera = I3DUtil.indexToObject(self.sceneRender.scene, self.sceneRender.cameraPath)
	local offsetX = 2 / g_screenWidth
	local offsetY = 8 / g_screenHeight
	local lx, ly, lz = localToWorld(self.licensePlate.node, self.licensePlate.width * 0.5, self.licensePlate.height * 0.5, 0)
	local plateEdgeX, plateEdgeY, _ = projectToCamera(camera, 3, lx, ly, lz)
	local _, fontHeight = self.licensePlate:getFontSize()
	local fontHeightScreen = (plateEdgeY - 0.5) * 2 * fontHeight / self.licensePlate.height * self.sceneRender.size[2] + offsetY

	if values ~= nil then
		for _, value in ipairs(values) do
			if not value.isStatic and not value.locked then
				local valueWidth = (plateEdgeX - 0.5) * 2 * value.maxWidthRatio * fontHeight / self.licensePlate.width * self.sceneRender.size[1] + offsetX
				local x, y, z = getWorldTranslation(I3DUtil.indexToObject(self.licensePlate.node, value.nodePath))
				local cursorX, cursorY, _ = projectToCamera(camera, 3, x, y, z)
				cursorX = cursorX * self.sceneRender.size[1] + self.sceneRender.absPosition[1] - valueWidth * 0.5
				cursorY = cursorY * self.sceneRender.size[2] + self.sceneRender.absPosition[2] - fontHeightScreen * 0.5

				table.insert(self.cursorPositions, {
					x = cursorX,
					y = cursorY,
					width = valueWidth,
					height = fontHeightScreen,
					valueIndex = value.index
				})
			end
		end
	end

	self.currentCursorPosition = math.min(self.currentCursorPosition, #self.cursorPositions)

	self:updateCursor()
end

function LicensePlateDialog:onCreatePlacementOption(element)
	self.textToPlacementIndex = {}
	local texts = {}

	for _, index in pairs(LicensePlateManager.PLACEMENT_OPTION) do
		table.insert(texts, g_i18n:getText(LicensePlateManager.PLACEMENT_OPTION_TEXT[index]))

		self.textToPlacementIndex[#texts] = index
	end

	element:setTexts(texts)
	element:setState(1)
end

function LicensePlateDialog:onClickBack()
	self:sendCallback(nil)
	LicensePlateDialog:superClass().onClickBack(self)
end

function LicensePlateDialog:onClickChangeColor()
	local colors, defaultColorIndex = g_licensePlateManager:getAvailableColors()
	colors = table.copy(colors, math.huge)

	if #colors > 1 then
		g_gui:showColorPickerDialog({
			colors = colors,
			defaultColor = colors[defaultColorIndex] or colors[1],
			callback = self.onPickedColor,
			target = self
		})
	end

	return true
end

function LicensePlateDialog:onPickedColor(colorIndex)
	if colorIndex ~= nil then
		self.currentColorIndex = colorIndex

		self:updateLicensePlateGraphics()
	end
end

function LicensePlateDialog:onClickOk()
	self.currentCharacters = self.licensePlate:validateLicensePlateCharacters(self.currentCharacters)

	self:sendCallback(self.currentVariation, self.currentCharacters, self.currentColorIndex, self.currentPlacementIndex)
	LicensePlateDialog:superClass().onClickOk(self)
end

function LicensePlateDialog:onRenderLoad(scene, overlay)
	local licensePlate = g_licensePlateManager:getLicensePlate(LicensePlateManager.PLATE_TYPE.ELONGATED)

	if licensePlate ~= nil then
		setTranslation(scene, 0, -1, 0)

		local linkNode = I3DUtil.indexToObject(scene, "0|0")

		link(linkNode, licensePlate.node)
		setTranslation(licensePlate.node, 0, 0, 0)
		setRotation(licensePlate.node, 0, 0, 0)

		self.licensePlate = licensePlate

		if self.currentCharacters == nil then
			self.currentCharacters = self.licensePlate:getRandomCharacters(self.currentVariation)
		end

		local cameraNode = I3DUtil.indexToObject(self.sceneRender.scene, self.sceneRender.cameraPath)

		if cameraNode ~= nil then
			local fovY = getFovY(cameraNode)
			local tolerance = 0.005
			local distanceWidth = (self.licensePlate.width / 2 + tolerance) / math.tan(fovY / 2) / (self.sceneRender.size[1] / self.sceneRender.size[2] * g_screenWidth / g_screenHeight)
			local distanceHeight = (self.licensePlate.height / 2 + tolerance) / math.tan(fovY / 2)
			local distance = math.max(distanceWidth, distanceHeight)

			setTranslation(cameraNode, 0, 0, distance)
		end

		self:updateLicensePlateGraphics()
		self:updateVariations()
	end
end

function LicensePlateDialog:onClickKeyboardButton(element)
	self.currentCharacters[self.cursorPositions[self.currentCursorPosition].valueIndex] = element.keyboardValue

	self:updateLicensePlateGraphics()
	self:onClickCursorRight()
end

function LicensePlateDialog:onClickCursorLeft()
	self.currentCursorPosition = self.currentCursorPosition - 1

	if self.currentCursorPosition < 1 then
		self.currentCursorPosition = #self.cursorPositions
	end

	self:updateCursor()
end

function LicensePlateDialog:onClickCursorRight()
	self.currentCursorPosition = self.currentCursorPosition + 1

	if self.currentCursorPosition > #self.cursorPositions then
		self.currentCursorPosition = 1
	end

	self:updateCursor()
end

function LicensePlateDialog:onClickPlacementOptionChanged(selection)
	self.currentPlacementIndex = self.textToPlacementIndex[selection]
end

function LicensePlateDialog:onClickTypeOptionChanged(selection)
	self.currentVariation = selection
	self.currentCharacters = self.licensePlate:getRandomCharacters(self.currentVariation)

	self:updateLicensePlateGraphics()
end

function LicensePlateDialog:setButtonTexts(okText)
end

function LicensePlateDialog:setButtonAction(buttonAction)
end

function LicensePlateDialog:keyEvent(unicode, sym, modifier, isDown, eventUsed)
	if LicensePlateDialog:superClass().keyEvent(self, unicode, sym, modifier, isDown, eventUsed) then
		return true
	end

	if isDown then
		if sym == Input.KEY_backspace then
			if self.currentCursorPosition > 1 then
				self:onClickCursorLeft()

				return true
			end
		else
			local value = self.licensePlate.variations[self.currentVariation].values[self.currentCursorPosition]
			local charValue = self:getUnicodeToKeyboardValue(unicode, value)

			if charValue ~= nil then
				self.currentCharacters[self.cursorPositions[self.currentCursorPosition].valueIndex] = charValue

				self:updateLicensePlateGraphics()
				self:onClickCursorRight()
			end

			return true
		end
	end

	return false
end

function LicensePlateDialog:getUnicodeToKeyboardValue(unicode, value)
	local text = utf8ToUpper(unicodeToUtf8(unicode))
	local font = g_licensePlateManager:getFont()

	local function check(characterType)
		local characters = font.charactersByType[characterType]

		for i = 1, #characters do
			if text == utf8ToUpper(characters[i].value) then
				return characters[i].value
			end
		end

		return nil
	end

	if value.alphabetical then
		local result = check(MaterialManager.FONT_CHARACTER_TYPE.ALPHABETICAL)

		if result ~= nil then
			return result
		end
	end

	if value.numerical then
		local result = check(MaterialManager.FONT_CHARACTER_TYPE.NUMERICAL)

		if result ~= nil then
			return result
		end
	end

	if value.special then
		local result = check(MaterialManager.FONT_CHARACTER_TYPE.SPECIAL)

		if result ~= nil then
			return result
		end
	end

	return nil
end
