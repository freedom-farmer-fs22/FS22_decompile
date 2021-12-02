SettingsDisplayFrame = {}
local SettingsDisplayFrame_mt = Class(SettingsDisplayFrame, TabbedMenuFrameElement)

local function NO_CALLBACK()
end

SettingsDisplayFrame.CONTROLS = {
	FOV_Y = "fovYElement",
	HDR_CALIBRATION_BUTTON = "hdrCalibrationButton",
	V_SYNC = "vSyncElement",
	UI_SCALE = "uiScaleElement",
	BOX_LAYOUT = "boxLayout",
	CAMERA_BOBBING = "cameraBobbingElement",
	ELEMENT_PERFORMANCE_CLASS = "performanceClassElement",
	BRIGHTNESS = "brightnessElement",
	FULLSCREEN_MODE = "fullscreenModeElement",
	RESOLUTION = "resolutionElement",
	RESOLUTION_SCALE = "resolutionScaleElement",
	MAIN_CONTAINER = "settingsContainer"
}

function SettingsDisplayFrame.new(target, custom_mt, settingsModel, l10n)
	local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsDisplayFrame_mt)

	self:registerControls(SettingsDisplayFrame.CONTROLS)

	self.settingsModel = settingsModel
	self.l10n = l10n
	self.hasCustomMenuButtons = true
	self.lastHDRActive = true

	return self
end

function SettingsDisplayFrame:copyAttributes(src)
	SettingsDisplayFrame:superClass().copyAttributes(self, src)

	self.settingsModel = src.settingsModel
	self.l10n = src.l10n
	self.hasCustomMenuButtons = src.hasCustomMenuButtons
end

function SettingsDisplayFrame:initialize()
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.applyButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(SettingsDisplayFrame.L10N_SYMBOL.BUTTON_APPLY),
		callback = function ()
			self:onApplySettings()
		end
	}

	if not GS_PLATFORM_GGP then
		self.advancedButtonInfo = {
			inputAction = InputAction.MENU_ACTIVATE,
			text = self.l10n:getText(SettingsDisplayFrame.L10N_SYMBOL.BUTTON_ADVANCED),
			callback = function ()
				self:onClickAdvancedButton()
			end
		}
	end
end

function SettingsDisplayFrame:setOpenAdvancedSettingsCallback(itemSelectedCallback)
	self.notifyAdvancedSettingsButton = itemSelectedCallback or NO_CALLBACK
end

function SettingsDisplayFrame:onApplySettings()
	local needsRestart = self.settingsModel:needsRestartToApplyChanges() and not GS_PLATFORM_GGP

	self.settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)

	if needsRestart then
		RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS_ADVANCED)
		doRestart(true, "")
	else
		self:setMenuButtonInfoDirty()
	end
end

function SettingsDisplayFrame:getMenuButtonInfo()
	local buttons = {}

	if self.settingsModel:hasChanges() then
		table.insert(buttons, self.applyButtonInfo)
	end

	table.insert(buttons, self.backButtonInfo)
	table.insert(buttons, self.advancedButtonInfo)

	return buttons
end

function SettingsDisplayFrame:updateValues()
	self:updatePerformanceClass()
	self.performanceClassElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.PERFORMANCE_CLASS))
	self.fullscreenModeElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.FULLSCREEN_MODE) + 1)
	self.resolutionElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.RESOLUTION) + 1)
	self.vSyncElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.V_SYNC))
	self.brightnessElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.BRIGHTNESS))
	self.fovYElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.FOV_Y))
	self.uiScaleElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.UI_SCALE))
	self.resolutionScaleElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.RESOLUTION_SCALE))
	self.cameraBobbingElement:setIsChecked(self.settingsModel:getValue(SettingsModel.SETTING.CAMERA_BOBBING))
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onFrameOpen()
	self.hdrCalibrationButton:setVisible(self.lastHDRActive)
	self.resolutionScaleElement:setVisible(not GS_PLATFORM_GGP)
	self.performanceClassElement:setVisible(not GS_PLATFORM_GGP)
	self.resolutionElement:setVisible(not GS_PLATFORM_GGP)
	self.fullscreenModeElement:setVisible(not GS_PLATFORM_GGP)
	self.vSyncElement:setVisible(not GS_PLATFORM_GGP)
	self:updateHDRFocus()
	self:updateValues()
end

function SettingsDisplayFrame:updateHDRFocus()
	self.boxLayout:invalidateLayout()

	if self.hdrCalibrationButton.parent.visible then
		self.cameraBobbingElement.parent.wrapAround = false

		FocusManager:linkElements(self.cameraBobbingElement, FocusManager.BOTTOM, self.hdrCalibrationButton)
		FocusManager:linkElements(self.performanceClassElement, FocusManager.TOP, self.hdrCalibrationButton)
	end
end

function SettingsDisplayFrame:updatePerformanceClass()
	local texts, _, _ = self.settingsModel:getPerformanceClassTexts()

	self.performanceClassElement:setTexts(texts)
end

function SettingsDisplayFrame:setOpenHDRSettingsCallback(itemSelectedCallback)
	self.notifyHDRSettingsButton = itemSelectedCallback or NO_CALLBACK
end

function SettingsDisplayFrame:update(dt)
	local isHDRActive = getHdrAvailable() and not GS_PLATFORM_GGP

	if self.lastHDRActive ~= isHDRActive then
		self.hdrCalibrationButton.parent:setVisible(isHDRActive)
		self:updateHDRFocus()

		self.lastHDRActive = isHDRActive
	end
end

function SettingsDisplayFrame:onCreatePerformanceClass(element)
	local texts, _, _ = self.settingsModel:getPerformanceClassTexts()

	element:setTexts(texts)
end

function SettingsDisplayFrame:onCreateResolution(element)
	element:setTexts(self.settingsModel:getResolutionTexts())
end

function SettingsDisplayFrame:onCreateFullscreenMode(element)
	element:setTexts(self.settingsModel:getFullscreenModeTexts())
end

function SettingsDisplayFrame:onCreateBrightness(element)
	element:setTexts(self.settingsModel:getBrightnessTexts())
end

function SettingsDisplayFrame:onCreateFovY(element)
	element:setTexts(self.settingsModel:getFovYTexts())
end

function SettingsDisplayFrame:onCreateUIScale(element)
	element:setTexts(self.settingsModel:getUiScaleTexts())
end

function SettingsDisplayFrame:onCreateResolutionScale(element)
	element:setTexts(self.settingsModel:getResolutionScaleTexts())
end

function SettingsDisplayFrame:onClickPerformanceClass(state)
	self.settingsModel:applyPerformanceClass(state)
	self:updateValues()
end

function SettingsDisplayFrame:onClickResolution(state)
	self.settingsModel:setValue(SettingsModel.SETTING.RESOLUTION, state - 1)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickFovY(state)
	self.settingsModel:setValue(SettingsModel.SETTING.FOV_Y, state)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickBrightness(state)
	self.settingsModel:setValue(SettingsModel.SETTING.BRIGHTNESS, state)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickFullscreenMode(state)
	self.settingsModel:setValue(SettingsModel.SETTING.FULLSCREEN_MODE, state - 1)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickVSync(state)
	self.settingsModel:setValue(SettingsModel.SETTING.V_SYNC, state)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickUIScale(state)
	self.settingsModel:setValue(SettingsModel.SETTING.UI_SCALE, state)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickAdvancedButton()
	self.notifyAdvancedSettingsButton()
end

function SettingsDisplayFrame:onClickResolutionScale(state)
	self.settingsModel:setValue(SettingsModel.SETTING.RESOLUTION_SCALE, state)
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onClickCameraBobbing(state)
	self.settingsModel:setValue(SettingsModel.SETTING.CAMERA_BOBBING, self.cameraBobbingElement:getIsChecked())
	self:setMenuButtonInfoDirty()
end

function SettingsDisplayFrame:onHDRCalibration()
	self.notifyHDRSettingsButton()
end

SettingsDisplayFrame.L10N_SYMBOL = {
	BUTTON_APPLY = "button_apply",
	BUTTON_ADVANCED = "setting_advanced"
}
