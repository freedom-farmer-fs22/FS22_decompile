SettingsHDRFrame = {}
local SettingsHDRFrame_mt = Class(SettingsHDRFrame, TabbedMenuFrameElement)
SettingsHDRFrame.CONTROLS = {
	ELEMENT_IMAGE = "hdrImage",
	MAIN_CONTAINER = "settingsContainer",
	ELEMENT_BRIGHTNESS = "HDRPeakBrightnessElement"
}

function SettingsHDRFrame.new(target, custom_mt, settingsModel, l10n)
	local self = TabbedMenuFrameElement.new(target, custom_mt or SettingsHDRFrame_mt)

	self:registerControls(SettingsHDRFrame.CONTROLS)

	self.settingsModel = settingsModel
	self.l10n = l10n
	self.lastHDRActive = false
	self.hasCustomMenuButtons = true

	return self
end

function SettingsHDRFrame:copyAttributes(src)
	SettingsHDRFrame:superClass().copyAttributes(self, src)

	self.settingsModel = src.settingsModel
	self.l10n = src.l10n
	self.hasCustomMenuButtons = src.hasCustomMenuButtons
end

function SettingsHDRFrame:initialize()
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.applyButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(SettingsHDRFrame.L10N_SYMBOL.BUTTON_APPLY),
		callback = function ()
			self:onApplySettings()
		end
	}
end

function SettingsHDRFrame:onApplySettings()
	local needsRestart = self.settingsModel:needsRestartToApplyChanges() and not GS_PLATFORM_GGP

	self.settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)

	if needsRestart then
		RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS_ADVANCED)
		doRestart(false, "")
	else
		self:setMenuButtonInfoDirty()
	end
end

function SettingsHDRFrame:getMenuButtonInfo()
	local buttons = {}

	if self.settingsModel:hasChanges() then
		table.insert(buttons, self.applyButtonInfo)
	end

	table.insert(buttons, self.backButtonInfo)

	return buttons
end

function SettingsHDRFrame:updateValues()
	self.HDRPeakBrightnessElement:setState(self.settingsModel:getValue(SettingsModel.SETTING.HDR_PEAK_BRIGHTNESS))
	self:setMenuButtonInfoDirty()
end

function SettingsHDRFrame:update(dt)
	local isHDRActive = getHdrAvailable() and not GS_PLATFORM_GGP

	if self.lastHDRActive ~= isHDRActive then
		self.HDRPeakBrightnessElement:setDisabled(not isHDRActive)

		self.lastHDRActive = isHDRActive
	end
end

function SettingsHDRFrame:onFrameOpen()
	self.lastHDRActive = getHdrAvailable() and not GS_PLATFORM_GGP

	g_i3DManager:loadI3DFileAsync("dataS/menu/hdrPlane/hdrPlane.i3d", true, true, SettingsHDRFrame.hdrPlaneLoaded, self, nil)
	self:updateValues()
end

function SettingsHDRFrame:hdrPlaneLoaded(i3dNode, failedReason, args)
	self.hdrPlaneNode = i3dNode

	link(getRootNode(), self.hdrPlaneNode)

	local cameraId = getChild(self.hdrPlaneNode, "hdrPlaneCamera")
	local left = self.hdrImage.absPosition[1]
	local top = self.hdrImage.absPosition[2]
	local nX = self.hdrImage.size[1] / 2 + left
	local nY = self.hdrImage.size[2] / 2 + top

	setTranslation(cameraId, (-nX + 0.5) * g_screenAspectRatio, 1, nY - 0.5)
	setCamera(cameraId)
	setEnablePostFx(false)
end

function SettingsHDRFrame:onFrameClose()
	delete(self.hdrPlaneNode)
	setEnablePostFx(true)
	setCamera(0)
end

function SettingsHDRFrame:getMainElementSize()
	return self.settingsContainer.size
end

function SettingsHDRFrame:getMainElementPosition()
	return self.settingsContainer.absPosition
end

function SettingsHDRFrame:onCreateHDRPeakBrightness(element)
	local texts, _, _ = self.settingsModel:getHDRPeakBrightnessTexts()

	element:setTexts(texts)
end

function SettingsHDRFrame:onClickHDRPeakBrightness(state)
	self.settingsModel:applyHDRPeakBrightness(state)
	self:updateValues()
	self:setMenuButtonInfoDirty()
end

SettingsHDRFrame.L10N_SYMBOL = {
	BUTTON_APPLY = "button_apply"
}
