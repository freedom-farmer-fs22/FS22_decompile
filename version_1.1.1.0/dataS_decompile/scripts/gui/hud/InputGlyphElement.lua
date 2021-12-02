InputGlyphElement = {}
local InputGlyphElement_mt = Class(InputGlyphElement, HUDElement)
InputGlyphElement.GLYPH_OFFSET_X = 2
InputGlyphElement.TEXT_OFFSET_X = 4
InputGlyphElement.DEFAULT_TEXT_SIZE = 12

function InputGlyphElement.new(inputDisplayManager, baseWidth, baseHeight)
	local backgroundOverlay = Overlay.new(nil, 0, 0, baseWidth, baseHeight)
	local self = InputGlyphElement:superClass().new(backgroundOverlay, nil, InputGlyphElement_mt)
	self.inputDisplayManager = inputDisplayManager
	self.plusOverlay = inputDisplayManager:getPlusOverlay()
	self.orOverlay = inputDisplayManager:getOrOverlay()
	self.keyboardOverlay = ButtonOverlay.new()
	self.actionNames = {}
	self.actionText = nil
	self.displayText = nil
	self.actionTextSize = InputGlyphElement.DEFAULT_TEXT_SIZE
	self.inputHelpElement = nil
	self.buttonOverlays = {}
	self.hasButtonOverlays = false
	self.separators = {}
	self.keyNames = {}
	self.hasKeyNames = false
	self.color = {
		1,
		1,
		1,
		1
	}
	self.buttonColor = {
		1,
		1,
		1,
		1
	}
	self.overlayCopies = {}
	self.baseHeight = baseHeight
	self.baseWidth = baseWidth
	self.glyphOffsetX = 0
	self.textOffsetX = 0
	self.iconSizeY = baseHeight
	self.iconSizeX = baseWidth
	self.plusIconSizeY = baseHeight * 0.5
	self.plusIconSizeX = baseWidth * 0.5
	self.orIconSizeY = baseHeight * 0.5
	self.orIconSizeX = baseWidth * 0.5
	self.alignY = 1
	self.alignX = 1
	self.alignmentOffsetY = 0
	self.alignmentOffsetX = 0
	self.lowerCase = false
	self.upperCase = false
	self.bold = false

	return self
end

function InputGlyphElement:delete()
	InputGlyphElement:superClass().delete(self)
	self.keyboardOverlay:delete()
	self:deleteOverlayCopies()
end

local function clearTable(t)
	for k in pairs(t) do
		t[k] = nil
	end
end

function InputGlyphElement:deleteOverlayCopies()
	for k, v in pairs(self.overlayCopies) do
		v:delete()

		self.overlayCopies[k] = nil
	end
end

function InputGlyphElement:setScale(widthScale, heightScale)
	InputGlyphElement:superClass().setScale(self, widthScale, heightScale)

	self.glyphOffsetX = self:scalePixelToScreenWidth(InputGlyphElement.GLYPH_OFFSET_X)
	self.textOffsetX = self:scalePixelToScreenWidth(InputGlyphElement.TEXT_OFFSET_X)
	self.iconSizeY = self.baseHeight * heightScale
	self.iconSizeX = self.baseWidth * widthScale
	self.plusIconSizeY = self.iconSizeY * 0.5
	self.plusIconSizeX = self.iconSizeX * 0.5
	self.orIconSizeY = self.iconSizeY * 0.5
	self.orIconSizeX = self.iconSizeX * 0.5
end

function InputGlyphElement:setUpperCase(enableUpperCase)
	self.upperCase = enableUpperCase
	self.lowerCase = self.lowerCase and not enableUpperCase

	self:updateDisplayText()
end

function InputGlyphElement:setLowerCase(enableLowerCase)
	self.lowerCase = enableLowerCase
	self.upperCase = self.upperCase and not enableLowerCase

	self:updateDisplayText()
end

function InputGlyphElement:setBold(isBold)
	self.bold = isBold
end

function InputGlyphElement:setKeyboardGlyphColor(color)
	self.color = color

	self.keyboardOverlay:setColor(unpack(color))
end

function InputGlyphElement:setButtonGlyphColor(color)
	self.buttonColor = color

	for _, actionName in ipairs(self.actionNames) do
		local buttonOverlays = self.buttonOverlays[actionName]

		if buttonOverlays ~= nil then
			for _, overlay in pairs(buttonOverlays) do
				overlay:setColor(unpack(color))
			end
		end
	end
end

function InputGlyphElement:setAction(actionName, actionText, actionTextSize, noModifiers, copyOverlays)
	clearTable(self.actionNames)
	table.insert(self.actionNames, actionName)
	self:setActions(self.actionNames, actionText, actionTextSize, noModifiers, copyOverlays)
end

function InputGlyphElement:setActions(actionNames, actionText, actionTextSize, noModifiers, copyOverlays)
	self.actionNames = actionNames
	self.actionText = actionText
	self.actionTextSize = actionTextSize or InputGlyphElement.DEFAULT_TEXT_SIZE

	self:updateDisplayText()

	local height = self:getHeight()
	local width = 0

	self:deleteOverlayCopies()

	local isDoubleAction = #actionNames == 2

	for i, actionName in ipairs(actionNames) do
		local actionName2 = nil

		if isDoubleAction then
			actionName2 = actionNames[i + 1]
		end

		local helpElement = self.inputDisplayManager:getControllerSymbolOverlays(actionName, actionName2, "", noModifiers)
		local buttonOverlays = helpElement.buttons
		self.separators = helpElement.separators

		if copyOverlays then
			local originals = buttonOverlays
			buttonOverlays = {}

			for _, overlay in ipairs(originals) do
				local overlayCopy = Overlay.new(overlay.filename, overlay.x, overlay.y, overlay.defaultWidth, overlay.defaultHeight)

				overlayCopy:setUVs(overlay.uvs)
				overlayCopy:setAlignment(overlay.alignmentVertical, overlay.alignmentHorizontal)
				table.insert(self.overlayCopies, overlayCopy)
				table.insert(buttonOverlays, overlayCopy)
			end
		end

		if self.buttonOverlays[actionName] == nil then
			self.buttonOverlays[actionName] = {}
		else
			for j = 1, #self.buttonOverlays[actionName] do
				self.buttonOverlays[actionName][j] = nil
			end
		end

		self.hasButtonOverlays = false

		if #buttonOverlays > 0 then
			for _, overlay in ipairs(buttonOverlays) do
				table.insert(self.buttonOverlays[actionName], overlay)

				self.hasButtonOverlays = true
			end
		end

		if self.keyNames[actionName] == nil then
			self.keyNames[actionName] = {}
		else
			for j = 1, #self.keyNames[actionName] do
				self.keyNames[actionName][j] = nil
			end
		end

		self.hasKeyNames = false

		if #helpElement.keys > 0 then
			for _, key in ipairs(helpElement.keys) do
				table.insert(self.keyNames[actionName], key)

				self.hasKeyNames = true
			end
		end

		if isDoubleAction then
			table.remove(self.actionNames, 2)

			break
		end
	end

	if self.hasButtonOverlays then
		for _, buttonOverlays in pairs(self.buttonOverlays) do
			for i, _ in ipairs(buttonOverlays) do
				if i > 1 then
					width = width + self.plusIconSizeX + self.glyphOffsetX
				end

				width = width + self.iconSizeX + (i < #buttonOverlays and self.glyphOffsetX or 0)
			end
		end
	elseif self.hasKeyNames then
		for _, keyNames in pairs(self.keyNames) do
			for _, key in ipairs(keyNames) do
				width = width + self.keyboardOverlay:getButtonWidth(key, height)
			end
		end
	end

	self:setDimension(width, height)
end

function InputGlyphElement:updateDisplayText()
	if self.actionText ~= nil then
		self.displayText = self.actionText

		if self.upperCase then
			self.displayText = utf8ToUpper(self.actionText)
		elseif self.lowerCase then
			self.displayText = utf8ToLower(self.actionText)
		end
	end
end

function InputGlyphElement:getGlyphWidth()
	local width = 0

	if self.hasButtonOverlays then
		for _, actionName in ipairs(self.actionNames) do
			for i, _ in ipairs(self.buttonOverlays[actionName]) do
				if i > 1 then
					local separatorType = self.separators[i - 1]
					local separatorWidth = 0

					if separatorType == InputHelpElement.SEPARATOR.COMBO_INPUT then
						separatorWidth = self.plusIconSizeX
					elseif separatorType == InputHelpElement.SEPARATOR.ANY_INPUT then
						separatorWidth = self.orIconSizeX
					end

					width = width + separatorWidth + self.glyphOffsetX
				end

				local padding = i < #self.buttonOverlays[actionName] and self.glyphOffsetX or 0
				width = width + self.iconSizeX + padding
			end
		end
	elseif self.hasKeyNames then
		for _, actionName in ipairs(self.actionNames) do
			for i, key in ipairs(self.keyNames[actionName]) do
				local padding = i < #self.keyNames[actionName] and self.glyphOffsetX or 0
				width = width + self.keyboardOverlay:getButtonWidth(key, self.iconSizeY) + padding
			end
		end
	end

	return width
end

function InputGlyphElement:draw()
	if #self.actionNames == 0 or not self.overlay.visible then
		return
	end

	local posX, posY = self:getPosition()

	if self.hasButtonOverlays then
		for _, actionName in ipairs(self.actionNames) do
			posX = self:drawControllerButtons(self.buttonOverlays[actionName], posX, posY)
		end
	elseif self.hasKeyNames then
		for _, actionName in ipairs(self.actionNames) do
			posX = self:drawKeyboardKeys(self.keyNames[actionName], posX, posY)
		end
	end

	if self.actionText ~= nil then
		self:drawActionText(posX, posY)
	end
end

function InputGlyphElement:drawControllerButtons(buttonOverlays, posX, posY)
	for i, overlay in ipairs(buttonOverlays) do
		if i > 1 then
			local separatorType = self.separators[i - 1]
			local separatorOverlay = self.orOverlay
			local separatorWidth = 0
			local separatorHeight = 0

			if separatorType == InputHelpElement.SEPARATOR.COMBO_INPUT then
				separatorOverlay = self.plusOverlay
				separatorHeight = self.plusIconSizeY
				separatorWidth = self.plusIconSizeX
			elseif separatorType == InputHelpElement.SEPARATOR.ANY_INPUT then
				separatorHeight = self.orIconSizeY
				separatorWidth = self.orIconSizeX
			end

			separatorOverlay:setColor(nil, , , self.buttonColor[4])
			separatorOverlay:setPosition(posX, posY + separatorHeight)
			separatorOverlay:setDimension(separatorWidth, separatorHeight)
			separatorOverlay:render()
			separatorOverlay:setColor(nil, , , 1)
			separatorOverlay:resetDimensions()

			posX = posX + separatorWidth + self.glyphOffsetX
		end

		overlay:setPosition(posX, posY + self.iconSizeY * 0.5)
		overlay:setDimension(self.iconSizeX, self.iconSizeY)
		overlay:setColor(unpack(self.buttonColor))
		overlay:render()
		overlay:resetDimensions()

		local padding = i < #buttonOverlays and self.glyphOffsetX or 0
		posX = posX + self.iconSizeX + padding
	end

	return posX
end

function InputGlyphElement:drawKeyboardKeys(keyNames, posX, posY)
	for i, key in ipairs(keyNames) do
		local padding = i < #keyNames and self.glyphOffsetX or 0
		posX = posX + self.keyboardOverlay:renderButton(key, posX, posY, self.iconSizeY, nil, true) + padding
	end

	return posX
end

function InputGlyphElement:drawActionText(posX, posY)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextBold(self.bold)
	setTextColor(unpack(self.color))
	renderText(posX + self.textOffsetX, posY + self.actionTextSize * 0.5, self.actionTextSize, self.displayText)
end

function InputGlyphElement:setBaseSize(baseWidth, baseHeight)
	self.baseHeight = baseHeight
	self.baseWidth = baseWidth
	self.iconSizeY = baseHeight
	self.iconSizeX = baseWidth
	self.plusIconSizeY = baseHeight * 0.5
	self.plusIconSizeX = baseWidth * 0.5
	self.orIconSizeY = baseHeight * 0.5
	self.orIconSizeX = baseWidth * 0.5
end
