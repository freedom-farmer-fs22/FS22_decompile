SettingsGeneralFrame = {}
local SettingsGeneralFrame_mt = Class(SettingsGeneralFrame, TabbedMenuFrameElement)
SettingsGeneralFrame.CONTROLS = {
	"languageElement",
	"mpLanguageElement",
	"inputHelpModeElement",
	"masterVolumeElement",
	"musicVolumeElement",
	"volumeVehicleElement",
	"volumeEnvironmentElement",
	"volumeRadioElement",
	"volumeGUIElement",
	"isHeadTrackingEnabledElement",
	"isGamepadEnabledElement",
	"settingsContainer",
	"invertYLookElement",
	"boxLayout",
	"forceFeedbackElement"
}

function SettingsGeneralFrame.new(target, custom_mt, settingsModel, l10n)
	local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsGeneralFrame_mt)

	self:registerControls(SettingsGeneralFrame.CONTROLS)

	self.settingsModel = settingsModel
	self.l10n = l10n
	self.hasCustomMenuButtons = true

	return self
end

function SettingsGeneralFrame:copyAttributes(src)
	SettingsGeneralFrame:superClass().copyAttributes(self, src)

	self.settingsModel = src.settingsModel
	self.l10n = src.l10n
	self.hasCustomMenuButtons = src.hasCustomMenuButtons
end

function SettingsGeneralFrame:applyDefaultSettingsValues()
	self.inputHelpModeElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.INPUT_HELP_MODE))
	self.isGamepadEnabledElement:setIsChecked(self.settingsModel:getValue(SettingsModel.SETTING.GAMEPAD_ENABLED))
	self.isHeadTrackingEnabledElement:setIsChecked(self.settingsModel:getValue(SettingsModel.SETTING.HEAD_TRACKING_ENABLED))
	self.forceFeedbackElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.FORCE_FEEDBACK))
	self.languageElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.LANGUAGE))
	self.mpLanguageElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.MP_LANGUAGE))
	self.masterVolumeElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.VOLUME_MASTER))
	self.musicVolumeElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.VOLUME_MUSIC))
	self.volumeVehicleElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.VOLUME_VEHICLE))
	self.volumeEnvironmentElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT))
	self.volumeRadioElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.VOLUME_RADIO))
	self.volumeGUIElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.VOLUME_GUI))
	self.invertYLookElement:setIsChecked(self.settingsModel:getValue(SettingsModel.SETTING.INVERT_Y_LOOK))
end

function SettingsGeneralFrame:initialize()
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.applyButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(SettingsAdvancedFrame.L10N_SYMBOL.BUTTON_APPLY),
		callback = function ()
			self:onApplySettings()
		end
	}
end

function SettingsGeneralFrame:onApplySettings()
	local needsRestart = self.settingsModel:needsRestartToApplyChanges() and not GS_PLATFORM_GGP

	self.settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)

	if needsRestart then
		RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS)
		doRestart(false, "")
	else
		self:setMenuButtonInfoDirty()
	end
end

function SettingsGeneralFrame:getMenuButtonInfo()
	local buttons = {}

	if self.settingsModel:hasChanges() then
		table.insert(buttons, self.applyButtonInfo)
	end

	table.insert(buttons, self.backButtonInfo)

	return buttons
end

function SettingsGeneralFrame:onFrameOpen()
	self.isHeadTrackingEnabledElement:setVisible(not GS_PLATFORM_GGP)
	self.languageElement:setVisible(not GS_PLATFORM_GGP)
	self.isGamepadEnabledElement:setVisible(not GS_PLATFORM_GGP)
	self.inputHelpModeElement:setVisible(not GS_PLATFORM_GGP)
	self.forceFeedbackElement:setVisible(not GS_PLATFORM_GGP)
	self.boxLayout:invalidateLayout()
	self:applyDefaultSettingsValues()
end

function SettingsGeneralFrame:onCreateLanguage(element)
	element:setTexts(self.settingsModel:getLanguageTexts())
	element:setDisabled(self.settingsModel:getIsLanguageDisabled())
end

function SettingsGeneralFrame:onCreateMPLanguage(element)
	element:setTexts(self.settingsModel:getMPLanguageTexts())
end

function SettingsGeneralFrame:onCreateInputHelpMode(element)
	element:setTexts(self.settingsModel:getInputHelpModeTexts())
end

function SettingsGeneralFrame:onCreateMasterVolume(element)
	element:setTexts(self.settingsModel:getAudioVolumeTexts())
end

function SettingsGeneralFrame:onCreateMusicVolume(element)
	element:setTexts(self.settingsModel:getAudioVolumeTexts())
end

function SettingsGeneralFrame:onCreateVolumeVehicle(element)
	element:setTexts(self.settingsModel:getAudioVolumeTexts())
end

function SettingsGeneralFrame:onCreateVolumeEnvironment(element)
	element:setTexts(self.settingsModel:getAudioVolumeTexts())
end

function SettingsGeneralFrame:onCreateVolumeRadio(element)
	element:setTexts(self.settingsModel:getAudioVolumeTexts())
end

function SettingsGeneralFrame:onCreateVolumeGUI(element)
	element:setTexts(self.settingsModel:getAudioVolumeTexts())
end

function SettingsGeneralFrame:onCreateForceFeedback(element)
	element:setTexts(self.settingsModel:getForceFeedbackTexts())
end

function SettingsGeneralFrame:onClickLanguage(state)
	self.settingsModel:setValue(SettingsModel.SETTING.LANGUAGE, state)
	self:setMenuButtonInfoDirty()
end

function SettingsGeneralFrame:onClickMPLanguage(state)
	self.settingsModel:setValue(SettingsModel.SETTING.MP_LANGUAGE, state)
	self:setMenuButtonInfoDirty()
end

function SettingsGeneralFrame:onClickIsHeadTrackingEnabled(state)
	self.settingsModel:setValue(SettingsModel.SETTING.HEAD_TRACKING_ENABLED, self.isHeadTrackingEnabledElement:getIsChecked())
	self:setMenuButtonInfoDirty()
end

function SettingsGeneralFrame:onClickForceFeedback(state)
	self.settingsModel:setValue(SettingsModel.SETTING.FORCE_FEEDBACK, state)
	self:setMenuButtonInfoDirty()
end

function SettingsGeneralFrame:onClickIsGamepadEnabled(state)
	self.settingsModel:setValue(SettingsModel.SETTING.GAMEPAD_ENABLED, self.isGamepadEnabledElement:getIsChecked())
	self:setMenuButtonInfoDirty()
end

function SettingsGeneralFrame:onClickInputHelpMode(state)
	self.settingsModel:setValue(SettingsModel.SETTING.INPUT_HELP_MODE, self.inputHelpModeElement:getState())
	self:setMenuButtonInfoDirty()
end

function SettingsGeneralFrame:onClickMasterVolume(state)
	self.settingsModel:setValue(SettingsModel.SETTING.VOLUME_MASTER, state)
	self:setMenuButtonInfoDirty()
end

function SettingsGeneralFrame:onClickMusicVolume(state)
	self.settingsModel:setValue(SettingsModel.SETTING.VOLUME_MUSIC, state)
	self:setMenuButtonInfoDirty()
end

function SettingsGeneralFrame:onClickVolumeVehicle(state)
	self.settingsModel:setValue(SettingsModel.SETTING.VOLUME_VEHICLE, state)
	self:setMenuButtonInfoDirty()
end

function SettingsGeneralFrame:onClickVolumeEnvironment(state)
	self.settingsModel:setValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT, state)
	self:setMenuButtonInfoDirty()
end

function SettingsGeneralFrame:onClickVolumeRadio(state)
	self.settingsModel:setValue(SettingsModel.SETTING.VOLUME_RADIO, state)
	self:setMenuButtonInfoDirty()
end

function SettingsGeneralFrame:onClickVolumeGUI(state)
	self.settingsModel:setValue(SettingsModel.SETTING.VOLUME_GUI, state)
	self:setMenuButtonInfoDirty()
end

function SettingsGeneralFrame:onClickInvertYLook(state)
	self.settingsModel:setValue(SettingsModel.SETTING.INVERT_Y_LOOK, self.invertYLookElement:getIsChecked())
	self:setMenuButtonInfoDirty()
end

SettingsGeneralFrame.L10N_SYMBOL = {
	BUTTON_APPLY = "button_apply"
}
