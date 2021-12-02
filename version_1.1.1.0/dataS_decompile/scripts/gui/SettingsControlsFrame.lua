SettingsControlsFrame = {}
local SettingsControlsFrame_mt = Class(SettingsControlsFrame, TabbedMenuFrameElement)
SettingsControlsFrame.CONTROLS = {
	GAMEPAD_TABLE = "gamepadTable",
	GAMEPAD_HEADER_TEXT = "gamepadHeaderText",
	KB_MOUSE_TABLE = "keyboardMouseTable",
	KB_MOUSE_PAGE = "keyboardMousePage",
	PAGING = "pagingElement",
	KEYBOARD_HIDDEN_BUTTON = "keyboardHiddenButton",
	KEYBOARD_HEADER_TEXT = "keyboardHeaderText",
	CONTROLS_MESSAGE = "controlsMessage",
	CONTROLS_MESSAGE_WARNING_ICON = "controlsMessageWarningIcon",
	GAMEPAD_HIDDEN_BUTTON = "gamepadHiddenButton",
	DISCLAIMER = "disclaimerLabel",
	GAMEPAD_PAGE = "gamepadPage"
}

local function NO_CALLBACK()
end

function SettingsControlsFrame.new(subclass_mt, l10n)
	local self = TabbedMenuFrameElement.new(nil, subclass_mt or SettingsControlsFrame_mt)

	self:registerControls(SettingsControlsFrame.CONTROLS)

	self.l10n = l10n
	self.controlsController = nil
	self.deviceCategoryDataBindings = {}
	self.deviceCategoryTables = {}
	self.controlsPageMappingTables = {}
	self.activeControlsTable = self.keyboardMouseTable
	self.previousSelectedCell = nil
	self.previousFirstRowIndex = 1
	self.userChangedInput = false
	self.hasCustomMenuButtons = true
	self.backButtonInfo = {}
	self.saveButtonInfo = {}
	self.resetButtonInfo = {}
	self.switchButtonInfo = {}
	self.dataForList = {}
	self.keyboardData = {}
	self.gamepadData = {}

	return self
end

function SettingsControlsFrame:copyAttributes(src)
	SettingsControlsFrame:superClass().copyAttributes(self, src)

	self.l10n = src.l10n
end

function SettingsControlsFrame:initialize(controlsController, inGame)
	self.controlsController = controlsController

	local function messageCallback(messageId, additionalText, addLine)
		self:setControlsMessage(messageId, additionalText, addLine)
	end

	local function inputDoneCallback(madeChange)
		self:notifyInputGatheringFinished(madeChange)
	end

	self.controlsController:setMessageCallback(messageCallback)
	self.controlsController:setInputDoneCallback(inputDoneCallback)
	self:setupControlsView()

	local function buttonSaveChangesFunction()
		self:saveChanges()
	end

	local function buttonDefaultsFunction()
		self:onClickDefaults()
	end

	local function buttonSwitchDeviceFunction()
		self:switchDevice()
	end

	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.saveButtonInfo = {
		showWhenPaused = true,
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.l10n:getText(SettingsControlsFrame.L10N_SYMBOL.BUTTON_SAVE),
		callback = buttonSaveChangesFunction
	}
	self.resetButtonInfo = {
		showWhenPaused = true,
		inputAction = InputAction.MENU_CANCEL,
		text = self.l10n:getText(SettingsControlsFrame.L10N_SYMBOL.BUTTON_DEFAULTS),
		callback = buttonDefaultsFunction
	}
	self.switchButtonInfo = {
		showWhenPaused = true,
		inputAction = InputAction.MENU_EXTRA_1,
		text = self.l10n:getText(SettingsControlsFrame.L10N_SYMBOL.BUTTON_GAMEPAD),
		callback = buttonSwitchDeviceFunction,
		clickSound = GuiSoundPlayer.SOUND_SAMPLES.NONE
	}
end

function SettingsControlsFrame:onGuiSetupFinished()
	SettingsControlsFrame:superClass().onGuiSetupFinished(self)
	self.keyboardMouseTable:setDataSource(self)
	self.gamepadTable:setDataSource(self)
end

function SettingsControlsFrame:onFrameOpen()
	SettingsControlsFrame:superClass().onFrameOpen(self)
	self:updateDisplay()
	self:setDevicePage(true)
	self.controlsMessage:setText("")
	self.controlsMessageWarningIcon:setVisible(false)
	self:updateHeader()
	self:updateMenuButtons()
	self.disclaimerLabel:setVisible(GS_PLATFORM_GGP)
	g_messageCenter:subscribe(MessageType.INPUT_MODE_CHANGED, self.onControllerChanged, self)
end

function SettingsControlsFrame:requestClose(callback)
	local canClose = not self.userChangedInput

	if self.userChangedInput then
		SettingsControlsFrame:superClass().requestClose(self, callback)
		g_gui:showYesNoDialog({
			text = self.l10n:getText(SettingsControlsFrame.L10N_SYMBOL.SAVE_CHANGES_PROMPT),
			callback = self.onYesNoSaveControls,
			target = self
		})
	end

	return canClose
end

function SettingsControlsFrame:onFrameClose()
	SettingsControlsFrame:superClass().onFrameClose(self)
	g_messageCenter:unsubscribe(MessageType.INPUT_MODE_CHANGED, self)
end

function SettingsControlsFrame:onYesNoSaveControls(yes)
	if yes then
		self:saveChanges()
	else
		self:revertChanges()
		self.requestCloseCallback()

		self.requestCloseCallback = NO_CALLBACK
	end
end

function SettingsControlsFrame:revertChanges()
	self.controlsController:discardChanges()

	self.userChangedInput = false

	self:updateMenuButtons()
end

function SettingsControlsFrame:saveChanges()
	if self.userChangedInput then
		self.controlsController:saveChanges()

		self.userChangedInput = false

		self:updateMenuButtons()
		g_gui:showInfoDialog({
			text = self.l10n:getText(SettingsControlsFrame.L10N_SYMBOL.SAVED_CHANGES_INFO),
			callback = self.requestCloseCallback
		})

		self.requestCloseCallback = NO_CALLBACK
	end
end

function SettingsControlsFrame:updateMenuButtons()
	if self.userChangedInput then
		self.gamepadPresentMenuButtonInfo = {
			self.backButtonInfo,
			self.saveButtonInfo,
			self.resetButtonInfo,
			self.switchButtonInfo
		}
		self.keyboardOnlyMenuButtonInfo = {
			self.backButtonInfo,
			self.saveButtonInfo,
			self.resetButtonInfo
		}
	else
		self.gamepadPresentMenuButtonInfo = {
			self.backButtonInfo,
			self.resetButtonInfo,
			self.switchButtonInfo
		}
		self.keyboardOnlyMenuButtonInfo = {
			self.backButtonInfo,
			self.resetButtonInfo
		}
	end

	if getNumOfGamepads() > 0 then
		self.menuButtonInfo = self.gamepadPresentMenuButtonInfo
	else
		self.menuButtonInfo = self.keyboardOnlyMenuButtonInfo
	end

	self:setMenuButtonInfoDirty()
end

function SettingsControlsFrame:updateHeader()
	local hasGamepads = getNumOfGamepads() > 0

	self.gamepadHeaderText:setVisible(hasGamepads)
	self.keyboardHiddenButton:setOverlayState(GuiOverlay.STATE_NORMAL)
	self.keyboardHeaderText:setDisabled(false)
	self.gamepadHiddenButton:setOverlayState(GuiOverlay.STATE_DISABLED)
	self.gamepadHeaderText:setDisabled(true)
end

function SettingsControlsFrame:setDevicePage(toKeyboard)
	local pageIndex = toKeyboard and 1 or 2

	self.pagingElement:setPage(pageIndex)

	self.activeControlsTable = toKeyboard and self.keyboardMouseTable or self.gamepadTable
	local keyboardOverlayState = toKeyboard and GuiOverlay.STATE_NORMAL or GuiOverlay.STATE_DISABLED
	local gamepadOverlayState = toKeyboard and GuiOverlay.STATE_DISABLED or GuiOverlay.STATE_NORMAL

	self.keyboardHiddenButton:setOverlayState(keyboardOverlayState)
	self.keyboardHeaderText:setDisabled(not toKeyboard)
	self.gamepadHiddenButton:setOverlayState(gamepadOverlayState)
	self.gamepadHeaderText:setDisabled(toKeyboard)

	local buttonTextSymbol = SettingsControlsFrame.L10N_SYMBOL.BUTTON_GAMEPAD

	if not toKeyboard then
		buttonTextSymbol = SettingsControlsFrame.L10N_SYMBOL.BUTTON_KEYBOARD
	end

	local buttonText = self.l10n:getText(buttonTextSymbol)
	self.switchButtonInfo.text = buttonText

	self.requestButtonUpdateCallback(buttonText)
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.activeControlsTable)
	self:setSoundSuppressed(false)
end

function SettingsControlsFrame:switchDevice()
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.PAGING)

	local hasGamepads = getNumOfGamepads() > 0
	local isShowingKeyboard = self.activeControlsTable == self.keyboardMouseTable
	local switchToKeyboard = not hasGamepads or hasGamepads and not isShowingKeyboard

	self:setDevicePage(switchToKeyboard)
end

function SettingsControlsFrame:setupControlsView()
	self.deviceCategoryTables[InputDevice.CATEGORY.KEYBOARD_MOUSE] = self.keyboardMouseTable

	self:bindControls(SettingsControlsFrame.KB_MOUSE_BOUND_CONTROLS, InputDevice.CATEGORY.KEYBOARD_MOUSE)

	local gpPageId = self.pagingElement:getPageIdByElement(self.gamepadPage)
	local hasGamepads = getNumOfGamepads() > 0

	if hasGamepads then
		self:bindControls(SettingsControlsFrame.GAMEPAD_BOUND_CONTROLS, InputDevice.CATEGORY.GAMEPAD)

		self.deviceCategoryTables[InputDevice.CATEGORY.GAMEPAD] = self.gamepadTable
	else
		self.deviceCategoryTables[InputDevice.CATEGORY.GAMEPAD] = nil
		self.deviceCategoryDataBindings[InputDevice.CATEGORY.GAMEPAD] = nil
	end

	self.pagingElement:setPageIdDisabled(gpPageId, not hasGamepads)
end

function SettingsControlsFrame:assignDeviceTableData()
	self.controlsController:loadBindings()

	self.keyboardData = self.controlsController:getDeviceCategoryActionBindings(InputDevice.CATEGORY.KEYBOARD_MOUSE)
	self.gamepadData = self.controlsController:getDeviceCategoryActionBindings(InputDevice.CATEGORY.GAMEPAD)

	self.keyboardMouseTable:reloadData()
	self.gamepadTable:reloadData()
end

function SettingsControlsFrame:setRequestButtonUpdateCallback(callback)
	self.requestButtonUpdateCallback = callback or NO_CALLBACK
end

function SettingsControlsFrame:setControlsMessage(messageId, additionalText, addLine)
	if not messageId or messageId == ControlsController.MESSAGE_CLEAR then
		self.controlsMessage:setText("")
		self.controlsMessageWarningIcon:setVisible(false)
	else
		local text = ""

		if addLine then
			text = self.controlsMessage:getText() .. "\n"
		end

		local uiSymbol = SettingsControlsFrame.CONTROLS_UI_STRINGS[messageId]

		if uiSymbol then
			text = text .. self.l10n:getText(uiSymbol)

			if additionalText and #additionalText > 0 then
				text = text .. additionalText[1]
			end
		else
			uiSymbol = SettingsControlsFrame.L10N_TEMPLATE_SYMBOL[messageId]
			local formatString = self.l10n:getText(uiSymbol)

			if additionalText and #additionalText > 0 then
				text = text .. string.format(formatString, unpack(additionalText))
			else
				text = text .. formatString
			end
		end

		self.controlsMessage:setText(text)
		self.controlsMessageWarningIcon:setVisible(true)
	end
end

function SettingsControlsFrame:notifyInputGatheringFinished(madeChange)
	self:setSoundSuppressed(true)
	g_gui:closeAllDialogs()
	FocusManager:setGui(self.name)
	self:setSoundSuppressed(false)

	if madeChange then
		self:assignDeviceTableData()

		self.userChangedInput = true

		self:updateMenuButtons()
	end

	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

	if self.previousSelectedCell ~= nil then
		FocusManager:setFocus(self.activeControlsTable)
		FocusManager:setHighlight(self.previousSelectedCell)
	end
end

function SettingsControlsFrame:showInputPrompt(deviceCategory, bindingId, actionData)
	local promptStringSymbol = nil

	if deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE then
		if bindingId == ControlsController.BINDING_PRIMARY or bindingId == ControlsController.BINDING_SECONDARY then
			promptStringSymbol = SettingsControlsFrame.L10N_SYMBOL.KEY_PROMPT
		else
			promptStringSymbol = SettingsControlsFrame.L10N_SYMBOL.MOUSE_PROMPT
		end
	else
		promptStringSymbol = SettingsControlsFrame.L10N_SYMBOL.BUTTON_PROMPT
	end

	local promptTemplate = self.l10n:getText(promptStringSymbol)
	local text = string.format(promptTemplate, actionData.displayName)

	if not GS_PLATFORM_GGP then
		text = text .. "\n" .. self.l10n:getText(SettingsControlsFrame.CONTROLS_UI_STRINGS[ControlsController.MESSAGE_PROMPT_CANCEL_DELETE])
		local ensureInNeutral = self.l10n:getText(SettingsControlsFrame.CONTROLS_UI_STRINGS[ControlsController.MESSAGE_ENSURE_IN_NEUTRAL])

		if ensureInNeutral:len() > 1 then
			text = text .. "\n\n" .. ensureInNeutral
		end
	end

	g_gui:showMessageDialog({
		visible = true,
		text = text,
		dialogType = DialogElement.TYPE_KEY
	})
end

SettingsControlsFrame.KB_MOUSE_BOUND_CONTROLS = {
	MOUSE_BUTTON = "mouseButton",
	KEY_2 = "key2",
	ACTION = "action",
	KEY_1 = "key1"
}
SettingsControlsFrame.GAMEPAD_BOUND_CONTROLS = {
	ACTION = "gamepadAction",
	BUTTON_2 = "gamepadButton2",
	BUTTON_1 = "gamepadButton1"
}

function SettingsControlsFrame:bindControls(bindings, deviceCategory)
	for bindingName, columnName in pairs(bindings) do
		if not self.deviceCategoryDataBindings[deviceCategory] then
			self.deviceCategoryDataBindings[deviceCategory] = {}
		end

		self.deviceCategoryDataBindings[deviceCategory][bindingName] = columnName
	end
end

function SettingsControlsFrame:updateDisplay()
	self:setupControlsView()
	self:assignDeviceTableData()
end

function SettingsControlsFrame:getNumberOfSections(list)
	if list == self.keyboardMouseTable then
		return #self.keyboardData
	else
		return #self.gamepadData
	end
end

function SettingsControlsFrame:getTitleForSectionHeader(list, section)
	local key = nil

	if list == self.keyboardMouseTable then
		key = self.keyboardData[section].name
	else
		key = self.gamepadData[section].name
	end

	return self.l10n:convertText(key)
end

function SettingsControlsFrame:getNumberOfItemsInSection(list, section)
	if list == self.keyboardMouseTable then
		return #self.keyboardData[section]
	else
		return #self.gamepadData[section]
	end
end

function SettingsControlsFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.keyboardMouseTable then
		local actionBinding = self.keyboardData[section][index]

		cell:getAttribute("action"):setText(actionBinding.displayName)
		cell:getAttribute("key1"):setText(actionBinding.columnTexts[ControlsController.BINDING_PRIMARY])
		cell:getAttribute("key2"):setText(actionBinding.columnTexts[ControlsController.BINDING_SECONDARY])
		cell:getAttribute("mouseButton"):setText(actionBinding.columnTexts[ControlsController.BINDING_TERTIARY])

		cell.actionBinding = actionBinding
	else
		local actionBinding = self.gamepadData[section][index]

		cell:getAttribute("gamepadAction"):setText(actionBinding.displayName)
		cell:getAttribute("gamepadButton1"):setText(actionBinding.columnTexts[ControlsController.BINDING_PRIMARY])
		cell:getAttribute("gamepadButton2"):setText(actionBinding.columnTexts[ControlsController.BINDING_SECONDARY])

		cell.actionBinding = actionBinding
	end
end

function SettingsControlsFrame:inputEvent(action, value, eventUsed)
	if action == InputAction.MENU_ACCEPT and self.activeControlsTable == self.gamepadTable then
		local row = self.activeControlsTable:getSelectedElement()

		self:onInputClicked(InputDevice.CATEGORY.GAMEPAD, ControlsController.BINDING_PRIMARY, row.actionBinding, self.activeControlsTable)

		return true
	end
end

function SettingsControlsFrame:onInputClicked(deviceCategory, bindingId, actionData, element)
	self.previousFirstRowIndex = self.activeControlsTable.firstVisibleItem
	self.previousSelectedCell = element

	if self.controlsController:onClickInput(deviceCategory, bindingId, actionData) then
		self:showInputPrompt(deviceCategory, bindingId, actionData)
	end
end

function SettingsControlsFrame:onClickKey1(element)
	self:onInputClicked(InputDevice.CATEGORY.KEYBOARD_MOUSE, ControlsController.BINDING_PRIMARY, element.parent.actionBinding, element)
end

function SettingsControlsFrame:onClickKey2(element)
	self:onInputClicked(InputDevice.CATEGORY.KEYBOARD_MOUSE, ControlsController.BINDING_SECONDARY, element.parent.actionBinding, element)
end

function SettingsControlsFrame:onClickMouse(element)
	self:onInputClicked(InputDevice.CATEGORY.KEYBOARD_MOUSE, ControlsController.BINDING_TERTIARY, element.parent.actionBinding, element)
end

function SettingsControlsFrame:onClickGamepadButton1(element)
	self:onInputClicked(InputDevice.CATEGORY.GAMEPAD, ControlsController.BINDING_PRIMARY, element.parent.actionBinding, element)
end

function SettingsControlsFrame:onClickGamepadButton2(element)
	self:onInputClicked(InputDevice.CATEGORY.GAMEPAD, ControlsController.BINDING_SECONDARY, element.parent.actionBinding, element)
end

function SettingsControlsFrame:onClickDefaults()
	local function wrappedCallback(dialogAccepted)
		if dialogAccepted then
			self.controlsController:loadDefaultSettings()

			self.userChangedInput = false

			self:assignDeviceTableData()
			self:updateMenuButtons()
			g_gui:showInfoDialog({
				text = self.l10n:getText(SettingsControlsFrame.L10N_SYMBOL.DEFAULTS_LOADED),
				dialogType = DialogElement.TYPE_INFO
			})
		end
	end

	g_gui:showYesNoDialog({
		text = self.l10n:getText(SettingsControlsFrame.L10N_SYMBOL.LOAD_DEFAULTS),
		title = self.l10n:getText(SettingsControlsFrame.L10N_SYMBOL.BUTTON_RESET),
		callback = wrappedCallback
	})
end

function SettingsControlsFrame:onClickKeyboardHeader()
	self:setDevicePage(true)
end

function SettingsControlsFrame:onClickGamepadHeader()
	self:setDevicePage(false)
end

function SettingsControlsFrame:onControllerChanged()
	self:assignDeviceTableData()
end

SettingsControlsFrame.CONTROLS_UI_STRINGS = {
	[ControlsController.MESSAGE_CANNOT_MAP_KEY] = "ui_cannotMapKeyHere",
	[ControlsController.MESSAGE_CANNOT_MAP_MOUSE] = "ui_cannotMapMouseHere",
	[ControlsController.MESSAGE_CANNOT_MAP_CONTROLLER] = "ui_cannotMapGamepadHere",
	[ControlsController.MESSAGE_PROMPT_KEY] = "ui_pressKeyToMap",
	[ControlsController.MESSAGE_PROMPT_MOUSE] = "ui_pressMouseButtonToMap",
	[ControlsController.MESSAGE_PROMPT_CONTROLLER] = "ui_pressGamepadButtonToMap",
	[ControlsController.MESSAGE_PROMPT_CANCEL_DELETE] = "ui_pressESCToCancel",
	[ControlsController.MESSAGE_ENSURE_IN_NEUTRAL] = "ui_ensureAxisToMapInNeutral",
	[ControlsController.MESSAGE_SELECT_ACTION] = "ui_selectActionToRemap",
	[ControlsController.MESSAGE_CONFLICT_KEY] = "ui_keyAlreadyMapped",
	[ControlsController.MESSAGE_CONFLICT_MOUSE] = "ui_buttonAlreadyMapped",
	[ControlsController.MESSAGE_CONFLICT_BUTTON] = "ui_buttonAlreadyMapped",
	[ControlsController.MESSAGE_CONFLICT_AXIS] = "ui_axisAlreadyMapped",
	[ControlsController.MESSAGE_CONFLICT_BLOCKED_KEY] = "ui_blockedKeyCombination"
}
SettingsControlsFrame.L10N_TEMPLATE_SYMBOL = {
	[ControlsController.MESSAGE_REMAPPED] = "ui_actionRemapped"
}
SettingsControlsFrame.L10N_SYMBOL = {
	LOAD_DEFAULTS = "ui_loadDefaultSettings",
	BUTTON_DEFAULTS = "button_defaults",
	SAVED_CHANGES_INFO = "ui_savingFinished",
	SAVE_CHANGES_PROMPT = "ui_saveChanges",
	KEY_PROMPT = "ui_pressKeyToMap",
	BUTTON_SAVE = "button_saveControls",
	BUTTON_KEYBOARD = "ui_keyboard",
	MOUSE_PROMPT = "ui_pressMouseButtonToMap",
	BUTTON_RESET = "button_reset",
	BUTTON_PROMPT = "ui_pressGamepadButtonToMap",
	BUTTON_GAMEPAD = "ui_gamepad",
	DEFAULTS_LOADED = "ui_loadedDefaultSettings"
}
