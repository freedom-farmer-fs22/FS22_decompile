SettingsConsoleFrame = {}
local SettingsConsoleFrame_mt = Class(SettingsConsoleFrame, TabbedMenuFrameElement)
SettingsConsoleFrame.CONTROLS = {
	"hdrCalibrationButton",
	"brightnessElement",
	"realBeaconLightsElement",
	VOLUME_VEHICLE = "volumeVehicleElement",
	ELEMENT_DISPLAY_RESOLUTION = "resolutionElement",
	VOLUME_MASTER = "masterVolumeElement",
	VOLUME_MUSIC = "musicVolumeElement",
	MAIN_BOX = "boxLayout",
	VOLUME_RADIO = "volumeRadioElement",
	ELEMENT_RENDER_QUALITY = "renderQualityElement",
	MAIN_CONTAINER = "settingsContainer",
	ELEMENT_INVERT_Y = "invertYLookElement",
	ELEMENT_UI_SCALE = "uiScaleElement",
	VOLUME_GUI = "volumeGUIElement",
	VOLUME_ENVIRONMENT = "volumeEnvironmentElement",
	ELEMENT_FOVY = "fovyElement"
}

function SettingsConsoleFrame.new(target, custom_mt, settingsModel, l10n)
	local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsConsoleFrame_mt)

	self:registerControls(SettingsConsoleFrame.CONTROLS)

	self.settingsModel = settingsModel
	self.l10n = l10n
	self.hasCustomMenuButtons = true

	g_messageCenter:subscribe(MessageType.USER_PROFILE_CHANGED, self.onUserProfileChanged, self)

	return self
end

function SettingsConsoleFrame:copyAttributes(src)
	SettingsConsoleFrame:superClass().copyAttributes(self, src)

	self.settingsModel = src.settingsModel
	self.l10n = src.l10n
	self.hasCustomMenuButtons = src.hasCustomMenuButtons
end

function SettingsConsoleFrame:initialize()
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.applyButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(SettingsConsoleFrame.L10N_SYMBOL.BUTTON_APPLY),
		callback = function ()
			self:onApplySettings()
		end
	}
end

function SettingsConsoleFrame:onApplySettings()
	self.settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
	g_gui:showInfoDialog({
		text = self.l10n:getText(SettingsConsoleFrame.L10N_SYMBOL.SAVING_FINISHED),
		dialogType = DialogElement.TYPE_INFO
	})
	self:setMenuButtonInfoDirty()
end

function SettingsConsoleFrame:getMenuButtonInfo()
	local buttons = {}

	if self.settingsModel:hasChanges() then
		table.insert(buttons, self.applyButtonInfo)
	end

	table.insert(buttons, self.backButtonInfo)

	return buttons
end

function SettingsConsoleFrame:updateValues()
	self.resolutionElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.CONSOLE_RESOLUTION))
	self.renderQualityElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.CONSOLE_RENDER_QUALITY))
	self.fovyElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.FOV_Y))
	self.uiScaleElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.UI_SCALE))
	self.invertYLookElement:setIsChecked(self.settingsModel:getValue(SettingsModel.SETTING.INVERT_Y_LOOK))
	self.masterVolumeElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.VOLUME_MASTER))
	self.musicVolumeElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.VOLUME_MUSIC))
	self.volumeVehicleElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.VOLUME_VEHICLE))
	self.volumeEnvironmentElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT))
	self.volumeRadioElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.VOLUME_RADIO))
	self.volumeGUIElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.VOLUME_GUI))
	self.brightnessElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.BRIGHTNESS))
	self.realBeaconLightsElement:setIsChecked(self.settingsModel:getValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS))

	local platformId = getPlatformId()

	self.realBeaconLightsElement:setVisible(platformId == PlatformId.XBOX_SERIES or platformId == PlatformId.PS5)
	self.boxLayout:invalidateLayout()
end

function SettingsConsoleFrame:onFrameOpen()
	self:updateValues()
	self.resolutionElement:setLabel(self.l10n:getText(SettingsConsoleFrame.L10N_SYMBOL.DOWNSAMPLED))
	self.resolutionElement:setVisible(self.settingsModel:getConsoleIsResolutionVisible())
	self.renderQualityElement:setDisabled(self.settingsModel:getConsoleIsRenderQualityDisabled())
	self.renderQualityElement:setVisible(self.settingsModel:getConsoleIsRenderQualityVisible())
	self.boxLayout:invalidateLayout()
	self:updateHDRFocus()
end

function SettingsConsoleFrame:updateHDRFocus()
	self.boxLayout:invalidateLayout()

	if self.hdrCalibrationButton.parent.visible then
		FocusManager:linkElements(self.brightnessElement, FocusManager.BOTTOM, self.hdrCalibrationButton)
		FocusManager:linkElements(self.masterVolumeElement, FocusManager.TOP, self.hdrCalibrationButton)
	end
end

function SettingsConsoleFrame:onUserProfileChanged()
	self.settingsModel:setSettingsFileHandle(g_savegameXML)
	self.settingsModel:refresh()
	self:updateValues()
end

function SettingsConsoleFrame:getMainElementSize()
	return self.settingsContainer.size
end

function SettingsConsoleFrame:getMainElementPosition()
	return self.settingsContainer.absPosition
end

function SettingsConsoleFrame:setOpenHDRSettingsCallback(itemSelectedCallback)
	self.notifyHDRSettingsButton = itemSelectedCallback or NO_CALLBACK
end

function SettingsConsoleFrame:update(dt)
	SettingsConsoleFrame:superClass().update(self, dt)

	local isHDRActive = getHdrAvailable() and not getHdrMaxNitsAvailable() and not GS_PLATFORM_GGP

	if self.lastHDRActive ~= isHDRActive then
		self.hdrCalibrationButton.parent:setVisible(isHDRActive)
		self:updateHDRFocus()

		self.lastHDRActive = isHDRActive
	end
end

function SettingsConsoleFrame:onHDRCalibration()
	self.notifyHDRSettingsButton()
end

function SettingsConsoleFrame:onCreateDisplayResolution(element)
	element:setTexts(self.settingsModel:getConsoleResolutionTexts())
end

function SettingsConsoleFrame:onCreateRenderQuality(element)
	element:setTexts(self.settingsModel:getConsoleRenderQualityTexts())
end

function SettingsConsoleFrame:onCreateFovy(element)
	element:setTexts(self.settingsModel:getFovYTexts())
end

function SettingsConsoleFrame:onCreateUIScale(element)
	element:setTexts(self.settingsModel:getUiScaleTexts())
end

function SettingsConsoleFrame:onCreateMasterVolume(element)
	element:setTexts(self.settingsModel:getAudioVolumeTexts())
end

function SettingsConsoleFrame:onCreateMusicVolume(element)
	element:setTexts(self.settingsModel:getAudioVolumeTexts())
end

function SettingsConsoleFrame:onCreateVolumeVehicle(element)
	element:setTexts(self.settingsModel:getAudioVolumeTexts())
end

function SettingsConsoleFrame:onCreateVolumeEnvironment(element)
	element:setTexts(self.settingsModel:getAudioVolumeTexts())
end

function SettingsConsoleFrame:onCreateVolumeRadio(element)
	element:setTexts(self.settingsModel:getAudioVolumeTexts())
end

function SettingsConsoleFrame:onCreateVolumeGUI(element)
	element:setTexts(self.settingsModel:getAudioVolumeTexts())
end

function SettingsConsoleFrame:onCreateBrightness(element)
	element:setTexts(self.settingsModel:getBrightnessTexts())
end

function SettingsConsoleFrame:onClickFovy(state)
	self.settingsModel:setValue(SettingsModel.SETTING.FOV_Y, state)
	self:setMenuButtonInfoDirty()
end

function SettingsConsoleFrame:onClickDisplayResolution(state)
	self.settingsModel:setConsoleResolution(state)
	self.renderQualityElement:setDisabled(self.settingsModel:getConsoleIsRenderQualityDisabled())
	self.renderQualityElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.CONSOLE_RENDER_QUALITY))
	self:setMenuButtonInfoDirty()
end

function SettingsConsoleFrame:onClickRenderQuality(state)
	self.settingsModel:setValue(SettingsModel.SETTING.CONSOLE_RENDER_QUALITY, state)
	self:setMenuButtonInfoDirty()
end

function SettingsConsoleFrame:onClickVSync(state)
	self.settingsModel:setValue(SettingsModel.SETTING.V_SYNC, state)
	self:setMenuButtonInfoDirty()
end

function SettingsConsoleFrame:onClickUIScale(state)
	self.settingsModel:setValue(SettingsModel.SETTING.UI_SCALE, state)
	self:setMenuButtonInfoDirty()
end

function SettingsConsoleFrame:onClickInvertYLook(state)
	self.settingsModel:setValue(SettingsModel.SETTING.INVERT_Y_LOOK, self.invertYLookElement:getIsChecked())
	self:setMenuButtonInfoDirty()
end

function SettingsConsoleFrame:onClickMasterVolume(state)
	self.settingsModel:setValue(SettingsModel.SETTING.VOLUME_MASTER, state)
	self:setMenuButtonInfoDirty()
end

function SettingsConsoleFrame:onClickMusicVolume(state)
	self.settingsModel:setValue(SettingsModel.SETTING.VOLUME_MUSIC, state)
	self:setMenuButtonInfoDirty()
end

function SettingsConsoleFrame:onClickVolumeVehicle(state)
	self.settingsModel:setValue(SettingsModel.SETTING.VOLUME_VEHICLE, state)
	self:setMenuButtonInfoDirty()
end

function SettingsConsoleFrame:onClickVolumeEnvironment(state)
	self.settingsModel:setValue(SettingsModel.SETTING.VOLUME_ENVIRONMENT, state)
	self:setMenuButtonInfoDirty()
end

function SettingsConsoleFrame:onClickVolumeRadio(state)
	self.settingsModel:setValue(SettingsModel.SETTING.VOLUME_RADIO, state)
	self:setMenuButtonInfoDirty()
end

function SettingsConsoleFrame:onClickVolumeGUI(state)
	self.settingsModel:setValue(SettingsModel.SETTING.VOLUME_GUI, state)
	self:setMenuButtonInfoDirty()
end

function SettingsConsoleFrame:onClickBrightness(state)
	self.settingsModel:setValue(SettingsModel.SETTING.BRIGHTNESS, state)
	self:setMenuButtonInfoDirty()
end

function SettingsConsoleFrame:onClickRealBeaconLights(state)
	self.settingsModel:setValue(SettingsModel.SETTING.REAL_BEACON_LIGHTS, self.realBeaconLightsElement:getIsChecked())
	self:setMenuButtonInfoDirty()
end

SettingsConsoleFrame.L10N_SYMBOL = {
	DOWNSAMPLED = "setting_resolutionDownsampled",
	BUTTON_APPLY = "button_apply",
	SAVING_FINISHED = "ui_savingFinished"
}
