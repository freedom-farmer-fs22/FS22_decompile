InGameMenuMobileSettingsFrame = {}
local InGameMenuMobileSettingsFrame_mt = Class(InGameMenuMobileSettingsFrame, TabbedMenuFrameElement)
InGameMenuMobileSettingsFrame.CONTROLS = {
	OPTION_GRAPHICS = "multiGraphics",
	OPTION_TIME_SCALE = "multiTimeScale",
	OPTION_STEERING_SENSITIVITY = "multiSteeringSensitivity",
	CHECKBOX_HELPER_REFILL = "checkHelperRefill",
	CHECK_TILT = "checkTilt",
	OPTION_MUSIC_VOLUME = "multiMusicVolume",
	OPTION_SFX_VOLUME = "multiSfxVolume",
	CHECK_GYROSCOPE = "checkGyroscope",
	SETTINGS_CONTAINER = "settingsContainer",
	BOX_LAYOUT = "boxLayout",
	CHECKBOX_TRAFFIC = "checkTraffic"
}
InGameMenuMobileSettingsFrame.L10N_SYMBOL = {
	BUY = "ui_buy",
	OFF = "ui_off"
}

function InGameMenuMobileSettingsFrame.new(subclass_mt, settingsModel, messageCenter)
	local self = InGameMenuMobileSettingsFrame:superClass().new(nil, subclass_mt or InGameMenuMobileSettingsFrame_mt)

	self:registerControls(InGameMenuMobileSettingsFrame.CONTROLS)

	self.settingsModel = settingsModel
	self.messageCenter = messageCenter
	self.missionInfo = nil
	self.checkboxMapping = {}
	self.optionMapping = {}

	return self
end

function InGameMenuMobileSettingsFrame:setMissionInfo(missionInfo)
	self.missionInfo = missionInfo
end

function InGameMenuMobileSettingsFrame:setHasMasterRights(hasMasterRights)
	self.hasMasterRights = hasMasterRights
end

function InGameMenuMobileSettingsFrame:copyAttributes(src)
	InGameMenuMobileSettingsFrame:superClass().copyAttributes(self, src)

	self.settingsModel = src.settingsModel
	self.messageCenter = src.messageCenter
end

function InGameMenuMobileSettingsFrame:initialize()
	self.checkboxMapping[self.checkGyroscope] = SettingsModel.SETTING.GYROSCOPE_STEERING
	self.checkboxMapping[self.checkTilt] = SettingsModel.SETTING.CAMERA_TILTING
	self.optionMapping[self.multiGraphics] = SettingsModel.SETTING.PERFORMANCE_CLASS
	self.optionMapping[self.multiSteeringSensitivity] = SettingsModel.SETTING.STEERING_SENSITIVITY
	self.optionMapping[self.multiMusicVolume] = {
		SettingsModel.SETTING.VOLUME_RADIO,
		SettingsModel.SETTING.VOLUME_MUSIC
	}
	self.optionMapping[self.multiSfxVolume] = {
		SettingsModel.SETTING.VOLUME_GUI,
		SettingsModel.SETTING.VOLUME_VEHICLE,
		SettingsModel.SETTING.VOLUME_ENVIRONMENT
	}

	self.multiGraphics:setTexts(self.settingsModel:getPerformanceClassTexts())
	self.multiSteeringSensitivity:setTexts(self.settingsModel:getSteeringSensitivityTexts())
	self.multiMusicVolume:setTexts(self.settingsModel:getAudioVolumeTexts())
	self.multiSfxVolume:setTexts(self.settingsModel:getAudioVolumeTexts())
	self:assignTimeScaleTexts()

	local helperTexts = {
		g_i18n:getText(InGameMenuMobileSettingsFrame.L10N_SYMBOL.OFF),
		g_i18n:getText(InGameMenuMobileSettingsFrame.L10N_SYMBOL.BUY)
	}

	self.checkHelperRefill:setTexts(helperTexts)
	self.multiGraphics:setVisible(GS_PLATFORM_PHONE)
	self.boxLayout:invalidateLayout()
end

function InGameMenuMobileSettingsFrame:onFrameOpen(element)
	InGameMenuMobileSettingsFrame:superClass().onFrameOpen(self)
	self:updateGeneralSettings()

	if g_isPresentationVersion then
		self.multiGraphics:setDisabled(true)
		self.checkGyroscope:setDisabled(true)
		self.checkTilt:setDisabled(true)
	end

	FocusManager:setFocus(self.boxLayout)
end

function InGameMenuMobileSettingsFrame:onFrameClose()
	InGameMenuMobileSettingsFrame:superClass().onFrameClose(self)
	self.settingsModel:saveChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)
end

function InGameMenuMobileSettingsFrame:updateGeneralSettings()
	self.settingsModel:refresh()

	for element, settingsKey in pairs(self.checkboxMapping) do
		element:setIsChecked(self.settingsModel:getValue(settingsKey))
	end

	for element, settingsKey in pairs(self.optionMapping) do
		if type(settingsKey) == "table" then
			element:setState(self.settingsModel:getValue(settingsKey[1]))
		else
			element:setState(self.settingsModel:getValue(settingsKey))
		end
	end

	self.multiTimeScale:setState(Utils.getTimeScaleIndex(self.missionInfo.timeScale))
	self.checkTraffic:setIsChecked(self.missionInfo.trafficEnabled)
	self.checkHelperRefill:setIsChecked(self.missionInfo.helperBuySeeds and self.missionInfo.helperBuyFertilizer and self.missionInfo.helperSlurrySource == 2 and self.missionInfo.helperManureSource == 2)
end

function InGameMenuMobileSettingsFrame:getMainElementSize()
	return self.settingsContainer.size
end

function InGameMenuMobileSettingsFrame:getMainElementPosition()
	return self.settingsContainer.absPosition
end

function InGameMenuMobileSettingsFrame:assignTimeScaleTexts()
	local timeScaleTable = {}
	local numTimeScales = Utils.getNumTimeScales()

	for i = 1, numTimeScales do
		table.insert(timeScaleTable, Utils.getTimeScaleString(i))
	end

	self.multiTimeScale:setTexts(timeScaleTable)
end

function InGameMenuMobileSettingsFrame:onClickCheckbox(state, checkboxElement)
	local settingsKey = self.checkboxMapping[checkboxElement]

	if settingsKey ~= nil then
		self.settingsModel:setValue(settingsKey, state == CheckedOptionElement.STATE_CHECKED)
		self.settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_NONE)

		self.dirty = true
	else
		print("Warning: Invalid settings checkbox event or key configuration for element " .. checkboxElement:toString())
	end
end

function InGameMenuMobileSettingsFrame:onClickMultiOption(state, optionElement)
	local settingsKey = self.optionMapping[optionElement]

	if settingsKey ~= nil then
		if type(settingsKey) == "table" then
			for _, v in ipairs(settingsKey) do
				self.settingsModel:setValue(v, state)
			end
		else
			self.settingsModel:setValue(settingsKey, state)
		end

		self.settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_NONE)

		self.dirty = true
	else
		print("Warning: Invalid settings multi option event or key configuration for element " .. optionElement:toString())
	end
end

function InGameMenuMobileSettingsFrame:onClickTimeScale(state)
	if self.hasMasterRights then
		g_currentMission:setTimeScale(Utils.getTimeScaleFromIndex(state))
	end
end

function InGameMenuMobileSettingsFrame:onClickTraffic(state)
	if self.hasMasterRights then
		g_currentMission:setTrafficEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuMobileSettingsFrame:onClickHelperRefill(state)
	if self.hasMasterRights then
		g_currentMission:setHelperBuySeeds(state == CheckedOptionElement.STATE_CHECKED)
		g_currentMission:setHelperBuyFertilizer(state == CheckedOptionElement.STATE_CHECKED)

		local source = state == CheckedOptionElement.STATE_CHECKED and 2 or 1

		g_currentMission:setHelperSlurrySource(source)
		g_currentMission:setHelperManureSource(source)
	end
end
