ColorPickerDialog = {}
local ColorPickerDialog_mt = Class(ColorPickerDialog, MessageDialog)
ColorPickerDialog.MAX_COLUMNS = 8
ColorPickerDialog.CONTROLS = {
	"okButton",
	"backButton",
	BUTTON_LAYOUT = "colorButtonLayout",
	BUTTON_TEMPLATE = "buttonTemplate",
	COLOR_NAME = "colorName"
}

function ColorPickerDialog.new(target, custom_mt)
	local self = ColorPickerDialog:superClass().new(target, custom_mt or ColorPickerDialog_mt)
	self.currentColorItemList = {}
	self.colorsToAdd = {}
	self.selectedIndex = 1
	self.colorElements = {}

	self:registerControls(ColorPickerDialog.CONTROLS)

	return self
end

function ColorPickerDialog:delete()
	if self.buttonTemplate ~= nil then
		self.buttonTemplate:delete()
	end

	ColorPickerDialog:superClass().delete(self)
end

function ColorPickerDialog:onOpen()
	ColorPickerDialog:superClass().onOpen(self)
	self:setInitialFocus()
end

function ColorPickerDialog:setColors(colors, defaultColor, defaultColorMaterial)
	for i = #self.colorElements, 1, -1 do
		self.colorElements[i]:delete()
	end

	if #colors == 0 then
		return
	end

	if type(colors[1].color) ~= "table" then
		local newColors = {}

		for i, color in ipairs(colors) do
			newColors[i] = {
				color = color
			}

			if table.equals(defaultColor, color) then
				defaultColor = newColors[i]
			end
		end

		colors = newColors
	end

	self.colors = colors
	self.colorElements = {}
	self.colorMapping = {}
	self.buttonMapping = {}

	for _, color in ipairs(colors) do
		if color.uiColor ~= nil then
			if table.equals(defaultColor, color.uiColor) and (defaultColorMaterial == nil or color.material == defaultColorMaterial) then
				self.defaultColor = color

				break
			end
		elseif table.equals(defaultColor, color.color) and (defaultColorMaterial == nil or color.material == defaultColorMaterial) then
			self.defaultColor = color

			break
		end
	end

	local buttonWidth = self.buttonTemplate.size[1] + self.buttonTemplate.margin[1] + self.buttonTemplate.margin[3]
	local numRows = math.ceil(#colors * buttonWidth / self.colorButtonLayout.size[1])
	local buttonHeight = self.buttonTemplate.size[2] + self.buttonTemplate.margin[2] + self.buttonTemplate.margin[4]
	local layoutHeight = numRows * buttonHeight
	self.colorButtonLayout.numFlows = numRows

	self.colorButtonLayout:setSize(nil, layoutHeight)

	for i, color in ipairs(colors) do
		if color.isSelectable ~= false then
			local newColorButton = self.buttonTemplate:clone(self.colorButtonLayout)

			newColorButton:setVisible(true)

			newColorButton.focusId = nil

			FocusManager:loadElementFromCustomValues(newColorButton)

			self.colorMapping[newColorButton] = i
			self.buttonMapping[color] = newColorButton

			table.insert(self.colorElements, newColorButton)

			local uiColor = color.color
			local material = uiColor[4] or 1

			if color.material ~= nil then
				material = color.material
			end

			if color.uiColor ~= nil then
				uiColor = color.uiColor
			end

			newColorButton:setMaterial(material)
			newColorButton:setColor(uiColor[1] or 1, uiColor[2] or 1, uiColor[3] or 1)
		end
	end

	self.colorButtonLayout:invalidateLayout()
	self:resizeDialog(layoutHeight)

	local numCols = math.floor(self.colorButtonLayout.size[1] / buttonWidth)

	self:focusLinkColorButtons(numCols)
	self:setInitialFocus()
end

function ColorPickerDialog:focusLinkColorButtons(numCols)
	for i = 1, #self.colorButtonLayout.elements do
		local button = self.colorButtonLayout.elements[i]
		local leftButton = self.colorButtonLayout.elements[i - 1]
		local rightButton = self.colorButtonLayout.elements[i + 1]
		local topButton = self.colorButtonLayout.elements[i - numCols]
		local bottomButton = self.colorButtonLayout.elements[i + numCols]

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
		else
			FocusManager:linkElements(button, FocusManager.TOP, button)
		end

		if bottomButton ~= nil then
			FocusManager:linkElements(button, FocusManager.BOTTOM, bottomButton)
		else
			FocusManager:linkElements(button, FocusManager.BOTTOM, button)
		end
	end
end

function ColorPickerDialog:setInitialFocus()
	local elem = nil

	if self.buttonMapping ~= nil then
		elem = self.buttonMapping[self.defaultColor]
	end

	if elem == nil and #self.colorElements > 0 then
		elem = self.colorElements[1]
	end

	if elem ~= nil then
		self.currentSelectedElement = elem

		FocusManager:setFocus(elem)
	end
end

function ColorPickerDialog:setCallback(callbackFunction, target, args)
	self.callbackFunction = callbackFunction
	self.target = target
	self.args = args
end

function ColorPickerDialog:onCreate()
	ColorPickerDialog:superClass().onCreate(self)

	self.defaultOkText = self.okButton.text
	self.defaultBackText = self.backButton.text

	self.buttonTemplate:unlinkElement()
	self.buttonTemplate:setVisible(false)
end

function ColorPickerDialog:onClickOk()
	if self.currentSelectedElement ~= nil then
		self:onClickColorButton(self.currentSelectedElement)

		return false
	end

	return true
end

function ColorPickerDialog:onClickColorButton(element)
	local colorIndex = self.colorMapping[element]

	self:sendCallback(colorIndex)
end

function ColorPickerDialog:onClickBack(forceBack, usedMenuButton)
	self:sendCallback(nil)

	return false
end

function ColorPickerDialog:sendCallback(colorIndex)
	self:close()

	if self.callbackFunction ~= nil then
		if self.target ~= nil then
			self.callbackFunction(self.target, colorIndex, self.args)
		else
			self.callbackFunction(colorIndex, self.args)
		end
	end
end

function ColorPickerDialog:onFocusColorButton(element)
	local colorIndex = self.colorMapping[element]
	local color = self.colors[colorIndex]
	self.currentSelectedElement = element

	if self.colorName ~= nil then
		self.colorName:setText(Utils.getNoNil(color.name, ""))
	end
end

function ColorPickerDialog:onLeaveColorButton(element)
	if self.colorName ~= nil then
		if self.currentSelectedElement ~= nil then
			local colorIndex = self.colorMapping[self.currentSelectedElement]
			local color = self.colors[colorIndex]

			self.colorName:setText(Utils.getNoNil(color.name, ""))
		else
			self.colorName:setText("")
		end
	end
end

function ColorPickerDialog:setButtonTexts(okText, backText)
	self.okButton:setText(Utils.getNoNil(okText, self.defaultOkText))
	self.backButton:setText(Utils.getNoNil(backText, self.defaultBackText))
end
