InputDisplayManager = {}
local InputDisplayManager_mt = Class(InputDisplayManager)

source("dataS/scripts/input/DisplayActionBinding.lua")
source("dataS/scripts/input/InputHelpElement.lua")

InputDisplayManager.CONTROLLER_SYMBOLS_PATH = "dataS/controllerSymbols.xml"
InputDisplayManager.AXIS_ICON_DEFINITIONS_PATH = "dataS/axisIcons.xml"
InputDisplayManager.RESOLUTION_ATLAS_PATHS = {
	{
		MIN_HEIGHT = 0,
		PATH = "dataS/menu/controllerSymbols1024.png"
	},
	{
		MIN_HEIGHT = 1080,
		PATH = "dataS/menu/controllerSymbols2048.png"
	}
}
InputDisplayManager.AXIS_ICON_BASE_SIZE = 40
InputDisplayManager.SYMBOL_PREFIX_XBOX = "xbox_"
InputDisplayManager.SYMBOL_PREFIX_PS4 = "ps4_"
InputDisplayManager.SYMBOL_PREFIX_PS5 = "ps5_"
InputDisplayManager.SYMBOL_PREFIX_MOUSE = "mouse_"
InputDisplayManager.SYMBOL_PREFIX_SWITCH = "switch_"
InputDisplayManager.SYMBOL_PREFIX_MOBILE = "mobile_"
InputDisplayManager.SYMBOL_PREFIX_STADIA = "stadia_"
InputDisplayManager.AXIS_NAME_X = "X"
InputDisplayManager.AXIS_NAME_Y = "Y"
InputDisplayManager.AXIS_NAME_MOUSE_X = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_X]
InputDisplayManager.AXIS_NAME_MOUSE_Y = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_Y]
InputDisplayManager.AXIS_AFFIX_POSITIVE = "(+)"
InputDisplayManager.AXIS_AFFIX_NEGATIVE = "(-)"
InputDisplayManager.MODIFIER_BUTTON_CONCAT = " + "
InputDisplayManager.PLUS_OVERLAY_NAME = "PLUS"
InputDisplayManager.OR_OVERLAY_NAME = "OR"
InputDisplayManager.NO_HELP_ELEMENT = InputHelpElement.new()

function InputDisplayManager.new(messageCenter, inputManager, modManager, isConsoleVersion)
	local self = setmetatable({}, InputDisplayManager_mt)
	self.messageCenter = messageCenter
	self.inputManager = inputManager
	self.modManager = modManager
	self.isConsoleVersion = isConsoleVersion
	self.isMobileVersion = GS_IS_MOBILE_VERSION

	messageCenter:subscribe(MessageType.INPUT_BINDINGS_CHANGED, self.onActionBindingsChanged, self)

	local function eventsCallback(displayActionEvents)
		self:onActionEventsChanged(displayActionEvents)
	end

	inputManager:setEventChangeCallback(eventsCallback)

	self.actionList = inputManager:getActionList()
	self.actionBindings = inputManager:getActionBindings()
	self.eventHelpElements = {
		[GS_INPUT_HELP_MODE_GAMEPAD] = {},
		[GS_INPUT_HELP_MODE_KEYBOARD] = {},
		[GS_INPUT_HELP_MODE_TOUCH] = {}
	}
	self.eventComboButtons = {
		[GS_INPUT_HELP_MODE_GAMEPAD] = {},
		[GS_INPUT_HELP_MODE_KEYBOARD] = {},
		[GS_INPUT_HELP_MODE_TOUCH] = {}
	}
	self.controllerSymbols = {}
	self.plusOverlay = nil
	self.orOverlay = nil
	self.keyboardKeyOverlay = nil
	self.axisIconOverlays = {}
	self.buttonIconSize = 45
	self.uiScale = 1

	return self
end

function InputDisplayManager:load()
	self.uiScale = g_gameSettings:getValue("uiScale")

	self:setDevGamepadLabelMapping()
	self:loadControllerSymbolsAndOverlays()

	local axisIconsXmlFile = loadXMLFile("AxisIcons", InputDisplayManager.AXIS_ICON_DEFINITIONS_PATH)

	self:loadAxisIcons(axisIconsXmlFile)
	delete(axisIconsXmlFile)
	self:loadModAxisIcons()
end

function InputDisplayManager:delete()
	for _, symbol in pairs(self.controllerSymbols) do
		symbol.overlay:delete()
	end

	for _, overlay in pairs(self.axisIconOverlays) do
		overlay:delete()
	end

	self.keyboardKeyOverlay:delete()
end

function InputDisplayManager:setDevGamepadLabelMapping()
	if GS_PLATFORM_PLAYSTATION and g_isDevelopmentVersion then
		local PS_BUTTON_MAPPING = {
			LS = "L3",
			Start = "Touch",
			Y = "Triangle",
			RB = "R1",
			X = "Square",
			LB = "L1",
			A = "Cross",
			Back = "Options",
			RS = "R3",
			B = "Circle"
		}
		local PS_AXIS_MAPPING = {
			RT = "R2",
			LT = "L2"
		}
		local oldGetGamepadButtonLabel = getGamepadButtonLabel

		function getGamepadButtonLabel(buttonId, internalId)
			local label = oldGetGamepadButtonLabel(buttonId, internalId)

			return Utils.getNoNil(PS_BUTTON_MAPPING[label], label)
		end

		local oldGetGamepadAxisLabel = getGamepadAxisLabel

		function getGamepadAxisLabel(axisId, internalId)
			local label = oldGetGamepadAxisLabel(axisId, internalId)

			return Utils.getNoNil(PS_AXIS_MAPPING[label], label)
		end
	end
end

function InputDisplayManager:loadControllerSymbolsAndOverlays()
	local atlasPath = InputDisplayManager.RESOLUTION_ATLAS_PATHS[1].PATH

	for _, resPath in ipairs(InputDisplayManager.RESOLUTION_ATLAS_PATHS) do
		if resPath.MIN_HEIGHT <= g_screenHeight then
			atlasPath = resPath.PATH
		end
	end

	local xmlFile = loadXMLFile("ControllerSymbolsBinding", InputDisplayManager.CONTROLLER_SYMBOLS_PATH)
	local i = 0

	while true do
		local baseName = string.format("controllerSymbols.controllerSymbol(%d)", i)

		if not hasXMLProperty(xmlFile, baseName) then
			break
		end

		local prefix = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#prefix"), "")
		local axisName = getXMLString(xmlFile, baseName .. "#name")
		local isComboButton = Utils.getNoNil(getXMLBool(xmlFile, baseName .. "#isComboButton"), false)
		local imageSize = string.getVectorN(Utils.getNoNil(getXMLString(xmlFile, baseName .. "#imageSize"), "1024, 1024"), 2)
		local imageUVs = Utils.getNoNil(getXMLString(xmlFile, baseName .. "#imageUVs"), "0 0 1 1")

		if axisName ~= nil then
			local parts = axisName:trim():split(" ")
			local axisSymbolName = ""

			for _, part in pairs(parts) do
				if part ~= "" then
					axisSymbolName = axisSymbolName .. prefix .. part
				end
			end

			if not self.controllerSymbols[axisSymbolName] then
				self:createButtonOverlay(axisSymbolName, atlasPath, imageUVs, imageSize, isComboButton)
			else
				print("Warning: controller symbol name '" .. axisSymbolName .. "' already exists!")
			end
		end

		i = i + 1
	end

	self.keyboardKeyOverlay = ButtonOverlay.new()

	delete(xmlFile)
end

function InputDisplayManager:createButtonOverlay(axisName, filename, imageUVs, imageSize, isComboButton)
	local iconSizeX, iconSizeY = getNormalizedScreenValues(self.buttonIconSize * self.uiScale, self.buttonIconSize * self.uiScale)
	imageUVs = GuiUtils.getUVs(imageUVs, imageSize, nil)
	local overlay = Overlay.new(filename, 0, 0, iconSizeX, iconSizeY)

	overlay:setUVs(imageUVs)
	overlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_LEFT)

	local symbol = {
		name = axisName,
		filename = filename,
		overlay = overlay
	}
	self.controllerSymbols[axisName] = symbol

	if axisName == InputDisplayManager.PLUS_OVERLAY_NAME then
		self.plusOverlay = overlay
		overlay.width = iconSizeX * 0.5
		overlay.defaultWidth = iconSizeX * 0.5
		overlay.height = iconSizeY * 0.5
		overlay.defaultHeight = iconSizeY * 0.5
	elseif axisName == InputDisplayManager.OR_OVERLAY_NAME then
		self.orOverlay = overlay
		overlay.width = iconSizeX * 0.5
		overlay.defaultWidth = iconSizeX * 0.5
		overlay.height = iconSizeY * 0.5
		overlay.defaultHeight = iconSizeY * 0.5
	end
end

function InputDisplayManager:loadAxisIcons(xmlFile, modPath)
	local rootPath = "axisIcons"
	local baseDirectory = ""
	local prefix = ""

	if modPath then
		rootPath = "modDesc.axisIcons"
		local modName, dir = Utils.getModNameAndBaseDirectory(modPath)
		baseDirectory = dir
		prefix = modName
	end

	local i = 0

	while true do
		local baseName = string.format("%s.icon(%d)", rootPath, i)

		if not hasXMLProperty(xmlFile, baseName) then
			break
		end

		local iconName = prefix .. getXMLString(xmlFile, baseName .. "#name") or ""
		local iconPath = getXMLString(xmlFile, baseName .. "#filename")

		if iconName and iconPath then
			local iconFilename = Utils.getFilename(iconPath, baseDirectory)
			local size = InputDisplayManager.AXIS_ICON_BASE_SIZE * self.uiScale
			local iconWidth, iconHeight = getNormalizedScreenValues(size, size)
			local iconOverlay = Overlay.new(iconFilename, 0, 0, iconWidth, iconHeight)

			iconOverlay:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_LEFT)

			self.axisIconOverlays[iconName] = iconOverlay
		end

		i = i + 1
	end
end

function InputDisplayManager:loadModAxisIcons()
	for _, modDesc in ipairs(self.modManager:getMods()) do
		local xmlFile = loadXMLFile("ModFile", modDesc.modFile)

		self:loadAxisIcons(xmlFile, modDesc.modFile)
		delete(xmlFile)
	end
end

function InputDisplayManager:addContextBindings(contextBindings, action, isContextGamepad, isComboAction)
	local bindings = self.actionBindings[action]
	local addedGamepadBinding = nil
	local addedGamepadBindingIndex = -1

	for _, binding in pairs(bindings) do
		if binding.isActive then
			local axisRepresented = false

			if not isComboAction then
				for _, contextBinding in pairs(contextBindings) do
					if binding.internalDeviceId == contextBinding.internalDeviceId and binding.unmodifiedAxis == contextBinding.unmodifiedAxis then
						axisRepresented = true

						break
					end
				end
			end

			if not axisRepresented then
				local isMouse = not isContextGamepad and binding.isMouse
				local isGamepad = isContextGamepad and binding.isGamepad
				local shouldSwapGamepadBinding = isGamepad and addedGamepadBinding ~= nil and binding.index < addedGamepadBinding.index
				local bindingIsActualGamepad = self.inputManager:getDeviceByInternalId(binding.internalDeviceId).category == InputDevice.CATEGORY.GAMEPAD
				local isActualGamepadCombo = bindingIsActualGamepad and isComboAction

				if shouldSwapGamepadBinding or isActualGamepadCombo then
					table.remove(contextBindings, addedGamepadBindingIndex)

					addedGamepadBinding = nil
				end

				if isMouse or isGamepad and addedGamepadBinding == nil then
					table.insert(contextBindings, binding)

					if isGamepad then
						addedGamepadBinding = binding
						addedGamepadBindingIndex = #contextBindings
					end
				end
			end
		end
	end
end

function InputDisplayManager:getActionBindingsForContext(action1, action2, isContextGamepad, isComboAction)
	local contextBindings = {}

	self:addContextBindings(contextBindings, action1, isContextGamepad, isComboAction)

	if action2 then
		self:addContextBindings(contextBindings, action2, isContextGamepad)
	end

	return contextBindings
end

local actionBindingsBuffer = {}

function InputDisplayManager:getKeyboardBindings(action1, action2)
	for k in pairs(actionBindingsBuffer) do
		actionBindingsBuffer[k] = nil
	end

	local bindings1 = self.actionBindings[action1]
	local bindings2 = action2 and self.actionBindings[action2]

	table.insert(actionBindingsBuffer, bindings1)

	if bindings2 ~= nil then
		table.insert(actionBindingsBuffer, bindings2)
	end

	local kbBindings = {}

	for _, bindings in ipairs(actionBindingsBuffer) do
		for _, binding in ipairs(bindings) do
			if binding.isKeyboard then
				table.insert(kbBindings, binding)
			end
		end
	end

	return kbBindings
end

function InputDisplayManager:resolveModifierSymbols(overlays, separators, firstContextBinding)
	for i = 1, #firstContextBinding.axisNames - 1 do
		local comboAxis = firstContextBinding.axisNames[i]
		local symbolName = self:getGamepadInputSymbolName(firstContextBinding.internalDeviceId, comboAxis, false)
		local symbol = self.controllerSymbols[symbolName]

		if symbol ~= nil then
			table.insert(overlays, symbol.overlay)
			table.insert(separators, InputHelpElement.SEPARATOR.COMBO_INPUT)
		end
	end
end

function InputDisplayManager:resolveAccumulatedSymbolPermutations(overlays, symbolNames, permLength)
	if permLength == 0 then
		local accumSymbolName = ""

		for _, name in ipairs(symbolNames) do
			accumSymbolName = accumSymbolName .. name
		end

		local symbol = self.controllerSymbols[accumSymbolName]

		if symbol ~= nil then
			table.insert(overlays, symbol.overlay)
		end
	else
		for i = 1, permLength do
			symbolNames[i] = symbolNames[permLength]
			symbolNames[permLength] = symbolNames[i]

			self:resolveAccumulatedSymbolPermutations(overlays, symbolNames, permLength - 1)

			symbolNames[i] = symbolNames[permLength]
			symbolNames[permLength] = symbolNames[i]
		end
	end
end

function InputDisplayManager:resolveUnmodifiedSymbols(overlays, contextBindings, isContextGamepad, accumulateSymbols)
	local accumSymbols = nil

	for _, binding in pairs(contextBindings) do
		local symbolName = nil

		if isContextGamepad then
			local isAxisInput = binding.isAnalog
			symbolName = self:getGamepadInputSymbolName(binding.internalDeviceId, binding.unmodifiedAxis, isAxisInput)
		else
			symbolName = self:getMouseInputSymbolName(binding.axisNames)
		end

		if accumulateSymbols and symbolName ~= nil then
			if accumSymbols == nil then
				accumSymbols = {
					symbolName
				}
			else
				local isDuplicateName = false

				for _, knownName in ipairs(accumSymbols) do
					if knownName == symbolName then
						isDuplicateName = true

						break
					end
				end

				if not isDuplicateName then
					table.insert(accumSymbols, symbolName)
				end
			end
		else
			local symbol = self.controllerSymbols[symbolName]

			if symbol ~= nil then
				table.insert(overlays, symbol.overlay)
			end
		end
	end

	if accumulateSymbols and accumSymbols ~= nil then
		self:resolveAccumulatedSymbolPermutations(overlays, accumSymbols, #accumSymbols)
	end
end

function InputDisplayManager:addRegularSymbols(overlays, separators, accumulateSymbols, contextBindings, isContextGamepad, ignoreComboButtons)
	if #contextBindings > 0 then
		if not ignoreComboButtons and isContextGamepad then
			self:resolveModifierSymbols(overlays, separators, contextBindings[1])
		end

		local prevCount = #overlays

		self:resolveUnmodifiedSymbols(overlays, contextBindings, isContextGamepad, accumulateSymbols)

		local afterCount = #overlays

		if prevCount ~= afterCount then
			for _ = 1, afterCount - prevCount - 1 do
				table.insert(separators, InputHelpElement.SEPARATOR.ANY_INPUT)
			end
		end
	end
end

function InputDisplayManager:addComboSymbols(overlays, separators, contextBindings, isContextGamepad)
	assert(#contextBindings == 1, "Number of bindings for a combo action must always be 1, check code and configuration!")

	local binding = contextBindings[1]

	if isContextGamepad then
		for _, inputAxisName in ipairs(binding.axisNames) do
			local symbolName = self:getGamepadInputSymbolName(binding.internalDeviceId, inputAxisName, false)
			local symbol = self.controllerSymbols[symbolName]

			if symbol ~= nil then
				table.insert(overlays, symbol.overlay)
			end
		end
	else
		local symbolName = self:getMouseInputSymbolName(binding.axisNames, false)

		table.insert(overlays, self.controllerSymbols[symbolName].overlay)
	end

	for _ = 1, #overlays - 1 do
		table.insert(separators, InputHelpElement.SEPARATOR.COMBO_INPUT)
	end
end

function InputDisplayManager:getControllerSymbolOverlays(actionName1, actionName2, text, ignoreComboButtons)
	local action1 = self.inputManager:getActionByName(actionName1)
	local action2 = self.inputManager:getActionByName(actionName2)
	local isGamepadComboAction = InputBinding.GAMEPAD_COMBOS[actionName1] ~= nil
	local isMouseComboAction = InputBinding.MOUSE_COMBOS[actionName1] ~= nil
	local isComboAction = isGamepadComboAction or isMouseComboAction
	local isContextGamepad = self.isConsoleVersion or self.isMobileVersion or self.inputManager:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD or isGamepadComboAction

	return self:makeHelpElement(action1, action2, text, isComboAction, isContextGamepad and not isMouseComboAction, ignoreComboButtons)
end

function InputDisplayManager.requireSymbolAccumulation(action1, action2, contextBindings)
	local accumulateSymbols = action1:isFullAxis() and not action2 or action2 and action2:isFullAxis()

	if not accumulateSymbols then
		local allDpad = true

		for _, binding in pairs(contextBindings) do
			allDpad = allDpad and InputBinding.getIsDPadInput(binding.axisNames)
		end

		accumulateSymbols = accumulateSymbols or allDpad
	end

	if not accumulateSymbols then
		local allMouseWheel = true

		for _, binding in pairs(contextBindings) do
			allMouseWheel = allMouseWheel and InputBinding.getIsMouseWheelInput(binding.axisNames)
		end

		accumulateSymbols = accumulateSymbols or allMouseWheel
	end

	return accumulateSymbols
end

function InputDisplayManager:makeHelpElement(action1, action2, text, isComboAction, isContextGamepad, ignoreComboButtons, customAxisIcon, priority)
	local contextBindings = self:getActionBindingsForContext(action1, action2, isContextGamepad, isComboAction)
	local separators = {}
	local overlays = {}

	if #contextBindings > 0 then
		if isComboAction then
			self:addComboSymbols(overlays, separators, contextBindings, isContextGamepad)
		else
			local accumulateSymbols = InputDisplayManager.requireSymbolAccumulation(action1, action2, contextBindings)

			self:addRegularSymbols(overlays, separators, accumulateSymbols, contextBindings, isContextGamepad, ignoreComboButtons)
		end
	end

	local keys = {}

	if #overlays < 1 and not isContextGamepad then
		local kbBindings = self:getKeyboardBindings(action1, action2)
		local modifierHash = {}

		for _, binding in ipairs(kbBindings) do
			for _, key in ipairs(binding.axisNames) do
				local isModifierKey = binding.modifierAxisSet[key] ~= nil

				if not isModifierKey or not modifierHash[key] then
					table.insert(keys, KeyboardHelper.getDisplayKeyName(Input[key]))

					if isModifierKey then
						modifierHash[key] = true
					end
				end
			end
		end
	end

	local helpElement = InputDisplayManager.NO_HELP_ELEMENT

	if #overlays > 0 or #keys > 0 then
		local action2Name = action2 ~= nil and action2.name or ""
		helpElement = InputHelpElement.new(action1.name, action2Name, overlays, keys, separators, "", text, not ignoreComboButtons, customAxisIcon, priority)
	end

	return helpElement
end

function InputDisplayManager:onActionEventsChanged(displayActionEvents)
	self:storeEventHelpElements(displayActionEvents)
	self:storeComboHelpElements(displayActionEvents)
end

function InputDisplayManager.sortEventHelpElements(helpElem1, helpElem2)
	if helpElem1.priority ~= helpElem2.priority then
		return helpElem1.priority < helpElem2.priority
	end

	if helpElem1.actionName ~= "" and helpElem2.actionName ~= "" then
		local action1 = g_inputBinding:getActionByName(helpElem1.actionName)
		local action2 = g_inputBinding:getActionByName(helpElem2.actionName)

		if action1.primaryKeyboardInput ~= nil then
			if action2.primaryKeyboardInput ~= nil then
				return action1.primaryKeyboardInput < action2.primaryKeyboardInput
			else
				return false
			end
		end

		return helpElem1.textRight < helpElem2.textRight
	elseif helpElem2.actionName ~= "" then
		return false
	end

	return true
end

function InputDisplayManager.sortEventHelpElementsGamepad(helpElem1, helpElem2)
	if #helpElem1.buttons > 0 and #helpElem2.buttons > 0 then
		for k, button in pairs(helpElem1.buttons) do
			if helpElem2.buttons[k] ~= nil then
				if helpElem2.buttons[k].overlayId ~= button.overlayId then
					return button.overlayId < helpElem2.buttons[k].overlayId
				end
			else
				return true
			end
		end
	elseif #helpElem1.buttons > 0 then
		return true
	else
		return false
	end
end

function InputDisplayManager:storeEventHelpElements(displayActionEvents)
	self.eventHelpElements = {
		[GS_INPUT_HELP_MODE_GAMEPAD] = {},
		[GS_INPUT_HELP_MODE_KEYBOARD] = {},
		[GS_INPUT_HELP_MODE_TOUCH] = {}
	}

	for helpMode, modeHelpElements in pairs(self.eventHelpElements) do
		local isContextGamepad = helpMode == GS_INPUT_HELP_MODE_GAMEPAD

		for _, actionEvent in ipairs(displayActionEvents) do
			local action = actionEvent.action
			local event = actionEvent.event
			local inlineModifierButtons = actionEvent.inlineModifierButtons or helpMode == GS_INPUT_HELP_MODE_KEYBOARD
			local actionComboMask = 0

			if isContextGamepad then
				if not inlineModifierButtons then
					actionComboMask = action.comboMaskGamepad
				end
			else
				actionComboMask = action.comboMaskMouse
			end

			local maskHelpElements = modeHelpElements[actionComboMask]

			if not maskHelpElements then
				maskHelpElements = {}
				modeHelpElements[actionComboMask] = maskHelpElements
			end

			local axisIcon = nil

			if event.contextDisplayIconName then
				axisIcon = self.axisIconOverlays[event.contextDisplayIconName]

				if not axisIcon then
					print("Warning: Could not resolve axis icon name '" .. event.contextDisplayIconName .. "'. Check vehicle and axis icon configurations.")
				end
			end

			local helpElement = self:makeHelpElement(action, nil, event.contextDisplayText, false, isContextGamepad, inlineModifierButtons, axisIcon, event.displayPriority)

			if helpElement ~= InputDisplayManager.NO_HELP_ELEMENT then
				table.insert(maskHelpElements, helpElement)
			end
		end

		local sortFunc = InputDisplayManager.sortEventHelpElements

		if isContextGamepad then
			sortFunc = InputDisplayManager.sortEventHelpElementsGamepad
		end

		for _, maskHelpElements in pairs(modeHelpElements) do
			table.sort(maskHelpElements, sortFunc)
		end
	end
end

function InputDisplayManager:storeComboHelpElements(displayActionEvents)
	self.eventComboButtons = {
		[GS_INPUT_HELP_MODE_GAMEPAD] = {},
		[GS_INPUT_HELP_MODE_KEYBOARD] = {},
		[GS_INPUT_HELP_MODE_TOUCH] = {}
	}

	for helpMode, _ in pairs(self.eventHelpElements) do
		local isContextGamepad = helpMode == GS_INPUT_HELP_MODE_GAMEPAD

		for _, actionEvent in ipairs(displayActionEvents) do
			local action = actionEvent.action

			for _, binding in pairs(self.actionBindings[action]) do
				local isPrimaryGamepad = isContextGamepad and binding.isActive and binding.isGamepad
				local isMouse = not isContextGamepad and binding.isMouse

				if isPrimaryGamepad and not actionEvent.inlineModifierButtons or isMouse then
					local comboActionName = self.inputManager:getComboActionNameForAxisSet(binding.modifierAxisSet)

					if comboActionName then
						self.eventComboButtons[helpMode][comboActionName] = true
					end
				end
			end
		end
	end
end

function InputDisplayManager:getEventHelpElementForAction(inputActionName)
	local helpMode = self.inputManager:getInputHelpMode()
	local comboHelpElements = self.eventHelpElements[helpMode]
	local eventHelpElement = nil

	for _, helpElements in pairs(comboHelpElements) do
		for _, element in pairs(helpElements) do
			if element.actionName == inputActionName then
				eventHelpElement = element

				break
			end
		end
	end

	return eventHelpElement
end

function InputDisplayManager:getEventHelpElements(pressedComboMask, isContextGamepad)
	local helpMode = isContextGamepad and GS_INPUT_HELP_MODE_GAMEPAD or GS_INPUT_HELP_MODE_KEYBOARD
	local elements = self.eventHelpElements[helpMode][pressedComboMask]

	if elements == nil then
		return {}
	end

	return elements
end

function InputDisplayManager:getComboHelpElements(isContextGamepad)
	local helpMode = isContextGamepad and GS_INPUT_HELP_MODE_GAMEPAD or GS_INPUT_HELP_MODE_KEYBOARD

	return self.eventComboButtons[helpMode]
end

function InputDisplayManager:getPrefix(internalDeviceId)
	local prefix = ""

	if GS_PLATFORM_XBOX then
		prefix = InputDisplayManager.SYMBOL_PREFIX_XBOX
	elseif GS_PLATFORM_SWITCH then
		prefix = InputDisplayManager.SYMBOL_PREFIX_SWITCH
	elseif GS_PLATFORM_PLAYSTATION then
		if internalDeviceId == 0 then
			if GS_PLATFORM_ID == PlatformId.PS5 then
				prefix = InputDisplayManager.SYMBOL_PREFIX_PS5
			else
				prefix = InputDisplayManager.SYMBOL_PREFIX_PS4
			end
		end
	else
		if GS_IS_MOBILE_VERSION then
			prefix = InputDisplayManager.SYMBOL_PREFIX_MOBILE
		end

		if internalDeviceId ~= nil then
			local gamepadName = getGamepadName(internalDeviceId)

			if gamepadName == InputDevice.NAMES.XBOX_GAMEPAD or gamepadName == InputDevice.NAMES.XINPUT_GAMEPAD then
				prefix = InputDisplayManager.SYMBOL_PREFIX_XBOX
			elseif gamepadName == InputDevice.NAMES.PS_GAMEPAD then
				prefix = InputDisplayManager.SYMBOL_PREFIX_PS4
			elseif gamepadName == InputDevice.NAMES.STADIA_GAMEPAD then
				prefix = InputDisplayManager.SYMBOL_PREFIX_STADIA
			elseif gamepadName == InputDevice.NAMES.SWITCH_GAMEPAD then
				prefix = InputDisplayManager.SYMBOL_PREFIX_SWITCH
			end
		end
	end

	return prefix
end

function InputDisplayManager:getPlusOverlay()
	return self.plusOverlay
end

function InputDisplayManager:getOrOverlay()
	return self.orOverlay
end

function InputDisplayManager:getKeyboardKeyOverlay()
	return self.keyboardKeyOverlay
end

function InputDisplayManager:getFirstBindingAxisAndDeviceForActionName(inputActionName, axisComponent, isGamepad)
	axisComponent = axisComponent or Binding.AXIS_COMPONENT.POSITIVE
	local action = self.inputManager:getActionByName(inputActionName)
	local contextBinding, internalDeviceId = nil
	local bindings = self.actionBindings[action]
	local lowestIndex = math.huge

	if bindings == nil then
		return "", -1
	end

	for _, binding in ipairs(bindings) do
		local fitsContext = binding.isGamepad and isGamepad or binding.isKeyboard and not isGamepad

		if binding.isActive and binding.index < lowestIndex and fitsContext and binding.axisComponent == axisComponent then
			contextBinding = binding
			internalDeviceId = binding.internalDeviceId
			lowestIndex = binding.index
		end
	end

	if contextBinding then
		return contextBinding.axisNames[1], internalDeviceId
	else
		return "", -1
	end
end

function InputDisplayManager:getGamepadInputActionOverlay(inputActionName, axisComponent)
	local axisName, internalDeviceId = self:getFirstBindingAxisAndDeviceForActionName(inputActionName, axisComponent, true)
	local symbolName = self:getGamepadInputSymbolName(internalDeviceId, axisName, false)

	if symbolName ~= nil and symbolName ~= "" then
		if self.controllerSymbols[symbolName] == nil then
			Logging.devWarning("Controller symbol name '%s' is not defined in controllerSymbols.xml", symbolName)

			return nil
		end

		local overlay = self.controllerSymbols[symbolName].overlay
		local guiOverlay = {
			uvs = overlay.uvs,
			color = {
				overlay.r,
				overlay.g,
				overlay.b,
				overlay.a
			},
			filename = overlay.filename
		}
		guiOverlay = GuiOverlay.createOverlay(guiOverlay)

		return guiOverlay
	else
		return nil
	end
end

function InputDisplayManager:getKeyboardInputActionKey(inputActionName, axisComponent)
	local axisName = self:getFirstBindingAxisAndDeviceForActionName(inputActionName, axisComponent, false)

	if axisName ~= "" then
		local keyId = Input[axisName]
		local keyName = KeyboardHelper.getDisplayKeyName(keyId)

		return keyName
	else
		return nil
	end
end

function InputDisplayManager:getGamepadInputSymbolName(internalDeviceId, axisName, isAxisInput)
	local symbolName = ""

	if internalDeviceId ~= nil and internalDeviceId >= 0 then
		local prefix = InputDisplayManager:getPrefix(internalDeviceId)

		if isAxisInput then
			local axisId = Input.axisIdNameToId[axisName]

			if axisId ~= nil then
				local axisLabel = string.gsub(getGamepadAxisLabel(axisId, internalDeviceId), " ", "")
				symbolName = prefix .. axisLabel
			end
		else
			local buttonId = Input.buttonIdNameToId[axisName]

			if buttonId ~= nil then
				local buttonLabel = getGamepadButtonLabel(buttonId, internalDeviceId)
				symbolName = prefix .. string.gsub(buttonLabel, " ", "")
			end
		end
	end

	return symbolName
end

function InputDisplayManager:getMouseInputSymbolName(axisNames)
	local symbolName = ""

	for _, axisName in pairs(axisNames) do
		if InputBinding.MOUSE_BUTTONS[axisName] then
			symbolName = symbolName .. InputDisplayManager.SYMBOL_PREFIX_MOUSE .. axisName
		elseif axisName:sub(1, #InputDisplayManager.AXIS_NAME_MOUSE_X) == InputDisplayManager.AXIS_NAME_MOUSE_X then
			symbolName = symbolName .. InputDisplayManager.SYMBOL_PREFIX_MOUSE .. "AxisX"
		elseif axisName:sub(1, #InputDisplayManager.AXIS_NAME_MOUSE_Y) == InputDisplayManager.AXIS_NAME_MOUSE_Y then
			symbolName = symbolName .. InputDisplayManager.SYMBOL_PREFIX_MOUSE .. "AxisY"
		end
	end

	return symbolName
end

function InputDisplayManager:onActionBindingsChanged(actionBindings)
	self.actionBindings = actionBindings
end
