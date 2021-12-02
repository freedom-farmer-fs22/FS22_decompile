SettingsDeviceFrame = {}
local SettingsDeviceFrame_mt = Class(SettingsDeviceFrame, TabbedMenuFrameElement)
SettingsDeviceFrame.CONTROLS = {
	ELEMENT_DEADZONE_2 = "deadzoneElement2",
	ELEMENT_DEADZONE_1 = "deadzoneElement1",
	ELEMENT_DEADZONE_4 = "deadzoneElement4",
	ELEMENT_DEADZONE_10 = "deadzoneElement10",
	ELEMENT_SENSITIVITY_6 = "sensitivityElement6",
	ELEMENT_SENSITIVITY_11 = "sensitivityElement11",
	ELEMENT_SENSITIVITY_7 = "sensitivityElement7",
	ELEMENT_SENSITIVITY_14 = "sensitivityElement14",
	ELEMENT_SENSITIVITY_EYE_TRACKING = "sensitivityHeadTrackingElement",
	ELEMENT_DEADZONE_14 = "deadzoneElement14",
	ELEMENT_SENSITIVITY_9 = "sensitivityElement9",
	ELEMENT_SENSITIVITY_12 = "sensitivityElement12",
	DISCLAIMER = "disclaimerLabel",
	MAIN_CONTAINER = "settingsContainer",
	ELEMENT_DEADZONE_13 = "deadzoneElement13",
	ELEMENT_DEADZONE_9 = "deadzoneElement9",
	ELEMENT_SENSITIVITY_8 = "sensitivityElement8",
	ELEMENT_DEADZONE_11 = "deadzoneElement11",
	ELEMENT_SENSITIVITY_3 = "sensitivityElement3",
	ELEMENT_SENSITIVITY_10 = "sensitivityElement10",
	ELEMENT_SENSITIVITY_5 = "sensitivityElement5",
	MAIN_BOX = "boxLayout",
	ELEMENT_DEADZONE_7 = "deadzoneElement7",
	ELEMENT_SENSITIVITY_2 = "sensitivityElement2",
	ELEMENT_DEADZONE_5 = "deadzoneElement5",
	ELEMENT_SENSITIVITY_4 = "sensitivityElement4",
	ELEMENT_SENSITIVITY_MOUSE = "sensitivityMouseElement",
	ELEMENT_TITLE = "titleElement",
	ELEMENT_SENSITIVITY_13 = "sensitivityElement13",
	ELEMENT_DEADZONE_12 = "deadzoneElement12",
	ELEMENT_DEADZONE_8 = "deadzoneElement8",
	ELEMENT_DEADZONE_6 = "deadzoneElement6",
	ELEMENT_SENSITIVITY_1 = "sensitivityElement1",
	ELEMENT_DEADZONE_3 = "deadzoneElement3"
}

function SettingsDeviceFrame.new(target, custom_mt, settingsModel, l10n)
	local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsDeviceFrame_mt)

	self:registerControls(SettingsDeviceFrame.CONTROLS)

	self.settingsModel = settingsModel
	self.l10n = l10n
	self.hasCustomMenuButtons = true
	self.deadzoneElementMapping = {}
	self.sensitivityElementMapping = {}

	return self
end

function SettingsDeviceFrame:copyAttributes(src)
	SettingsDeviceFrame:superClass().copyAttributes(self, src)

	self.settingsModel = src.settingsModel
	self.l10n = src.l10n
	self.hasCustomMenuButtons = src.hasCustomMenuButtons
end

function SettingsDeviceFrame:initialize()
	self.deadzoneElementMapping = {}
	self.sensitivityElementMapping = {}

	for i = 1, Input.MAX_NUM_AXES do
		local deadzoneElement = self[string.format("deadzoneElement%d", i)]
		self.deadzoneElementMapping[deadzoneElement] = i - 1

		deadzoneElement:setLabel(string.format(self.l10n:getText(SettingsDeviceFrame.L10N_SYMBOL.GAMEPAD_AXIS), i) .. " " .. self.l10n:getText(SettingsDeviceFrame.L10N_SYMBOL.GAMEPAD_DEADZONE))
		deadzoneElement:setTexts(self.settingsModel:getDeadzoneTexts())

		local sensitivityElement = self[string.format("sensitivityElement%d", i)]
		self.sensitivityElementMapping[sensitivityElement] = i - 1

		sensitivityElement:setLabel(string.format(self.l10n:getText(SettingsDeviceFrame.L10N_SYMBOL.GAMEPAD_AXIS), i) .. " " .. self.l10n:getText(SettingsDeviceFrame.L10N_SYMBOL.GAMEPAD_SENSITIVITY))
		sensitivityElement:setTexts(self.settingsModel:getSensitivityTexts())
	end

	self.sensitivityMouseElement:setLabel(string.format("%s %s", self.l10n:getText("ui_mouse"), self.l10n:getText(SettingsDeviceFrame.L10N_SYMBOL.GAMEPAD_SENSITIVITY)))
	self.sensitivityMouseElement:setTexts(self.settingsModel:getSensitivityTexts())
	self.sensitivityHeadTrackingElement:setLabel(string.format("%s %s", self.l10n:getText("setting_headTracking"), self.l10n:getText(SettingsDeviceFrame.L10N_SYMBOL.GAMEPAD_SENSITIVITY)))
	self.sensitivityHeadTrackingElement:setTexts(self.settingsModel:getHeadTrackingSensitivityTexts())

	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.switchButtonInfo = {
		inputAction = InputAction.MENU_EXTRA_1,
		text = self.l10n:getText(SettingsDeviceFrame.L10N_SYMBOL.SWITCH_DEVICE),
		callback = function ()
			self:onSwitchDevice()
		end
	}
	self.applyButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(SettingsDeviceFrame.L10N_SYMBOL.BUTTON_APPLY),
		callback = function ()
			self:onApplySettings()
		end
	}

	self:updateController()
end

function SettingsDeviceFrame:onApplySettings()
	self.settingsModel:saveChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
	g_gui:showInfoDialog({
		text = self.l10n:getText(SettingsDeviceFrame.L10N_SYMBOL.SAVING_FINISHED),
		dialogType = DialogElement.TYPE_INFO
	})
end

function SettingsDeviceFrame:onSwitchDevice()
	self.settingsModel:nextDevice()
	self:updateView()
end

function SettingsDeviceFrame:onFrameOpen()
	self.settingsModel:initDeviceSettings()
	self.settingsModel:refresh()
	self:updateView()
	self.disclaimerLabel:setVisible(GS_PLATFORM_GGP)
end

function SettingsDeviceFrame:getMenuButtonInfo()
	local buttons = {}

	if self.settingsModel:hasChanges() then
		table.insert(buttons, self.applyButtonInfo)
	end

	table.insert(buttons, self.backButtonInfo)

	if self.settingsModel:getNumDevices() > 1 then
		table.insert(buttons, self.switchButtonInfo)
	end

	return buttons
end

function SettingsDeviceFrame:getMainElementSize()
	return self.settingsContainer.size
end

function SettingsDeviceFrame:getMainElementPosition()
	return self.settingsContainer.absPosition
end

function SettingsDeviceFrame:update(dt)
	SettingsDeviceFrame:superClass().update(self, dt)

	local numOfGamepads = getNumOfGamepads()

	if numOfGamepads ~= self.numOfGamepads then
		self:updateController()
	end
end

function SettingsDeviceFrame:updateController()
	self.numOfGamepads = getNumOfGamepads()

	self.settingsModel:initDeviceSettings()
	self:updateView()
	self:setMenuButtonInfoDirty()
end

function SettingsDeviceFrame:updateView()
	self.boxLayout:scrollTo(0)

	local name = self.settingsModel:getCurrentDeviceName()

	if name == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT then
		name = self.l10n:getText(SettingsDeviceFrame.L10N_SYMBOL.DEVICE_MOUSE)
	elseif self.l10n:hasText(name) then
		name = self.l10n:getText(name)
	end

	self.titleElement:setText(string.format("%s: %s", self.l10n:getText(SettingsDeviceFrame.L10N_SYMBOL.DEVICE_CONFIGURATION), name))

	local firstVisible = nil
	local isMouse = self.settingsModel:getIsDeviceMouse()

	for deadzoneElement, axisIndex in pairs(self.deadzoneElementMapping) do
		local hasDeadzone = self.settingsModel:getDeviceHasAxisDeadzone(axisIndex) and not isMouse

		deadzoneElement:setVisible(hasDeadzone)

		if hasDeadzone then
			if firstVisible == nil then
				firstVisible = deadzoneElement
			end

			deadzoneElement:setState(self.settingsModel:getDeviceAxisDeadzoneValue(axisIndex))
		end
	end

	for sensitivityElement, axisIndex in pairs(self.sensitivityElementMapping) do
		local hasSensitiviy = self.settingsModel:getDeviceHasAxisSensitivity(axisIndex) and not isMouse

		sensitivityElement:setVisible(hasSensitiviy)

		if hasSensitiviy then
			if firstVisible == nil then
				firstVisible = sensitivityElement
			end

			sensitivityElement:setState(self.settingsModel:getDeviceAxisSensitivityValue(axisIndex))
		end
	end

	self.sensitivityMouseElement:setVisible(isMouse)

	if isMouse then
		if firstVisible == nil then
			firstVisible = self.sensitivityMouseElement
		end

		self.sensitivityMouseElement:setState(self.settingsModel:getMouseSensitivityValue())
	end

	local hasHeadTracking = g_gameSettings:getValue("isHeadTrackingEnabled") and isHeadTrackingAvailable()

	self.sensitivityHeadTrackingElement:setVisible(hasHeadTracking)

	if hasHeadTracking then
		if firstVisible == nil then
			firstVisible = self.sensitivityHeadTrackingElement
		end

		self.sensitivityHeadTrackingElement:setState(self.settingsModel:getHeadTrackingSensitivityValue())
	end

	self.boxLayout:invalidateLayout()
	self.boxLayout:scrollTo(0)

	if firstVisible then
		FocusManager:setFocus(firstVisible)
	end
end

function SettingsDeviceFrame:onCreateDeadzone(element)
	element:setTexts(self.settingsModel:getDeadzoneTexts())
end

function SettingsDeviceFrame:onCreateSensitivity(element)
	element:setTexts(self.settingsModel:getSensitivityTexts())
end

function SettingsDeviceFrame:onCreateHeadTrackingSensitivity(element)
	element:setTexts(self.settingsModel:getHeadTrackingSensitivityTexts())
end

function SettingsDeviceFrame:onClickDeadzone(state, element)
	local gamepadIndex = self.deadzoneElementMapping[element]

	self.settingsModel:setDeviceDeadzoneValue(gamepadIndex, state)
	self:setMenuButtonInfoDirty()
end

function SettingsDeviceFrame:onClickSensitivity(state, element)
	local gamepadIndex = self.sensitivityElementMapping[element]

	self.settingsModel:setDeviceSensitivityValue(gamepadIndex, state)
	self:setMenuButtonInfoDirty()
end

function SettingsDeviceFrame:onClickMouseSensitivity(state, element)
	self.settingsModel:setMouseSensitivity(state)
	self:setMenuButtonInfoDirty()
end

function SettingsDeviceFrame:onClickHeadTrackingSensitivity(state, element)
	self.settingsModel:setHeadTrackingSensitivity(state)
	self:setMenuButtonInfoDirty()
end

SettingsDeviceFrame.L10N_SYMBOL = {
	BUTTON_APPLY = "button_apply",
	GAMEPAD_AXIS = "setting_gamepadAxis",
	SWITCH_DEVICE = "ui_switchDevice",
	GAMEPAD_SENSITIVITY = "setting_gamepadSensitivity",
	GAMEPAD_DEADZONE = "setting_gamepadDeadzone",
	DEVICE_MOUSE = "ui_mouse",
	SAVING_FINISHED = "ui_savingFinished",
	DEVICE_CONFIGURATION = "ui_deviceConfiguration"
}
