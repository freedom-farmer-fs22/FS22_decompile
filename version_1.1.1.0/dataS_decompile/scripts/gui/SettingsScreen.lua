SettingsScreen = {}
local SettingsScreen_mt = Class(SettingsScreen, TabbedMenuWithDetails)
SettingsScreen.CONTROLS = {
	PAGING_SETTINGS_GENERAL = "pageSettingsGeneral",
	PAGING_SETTINGS_CONSOLE = "pageSettingsConsole",
	PAGING_SETTINGS_ADVANCED = "pageSettingsAdvanced",
	PAGING_SETTINGS_DEVICE = "pageSettingsDevice",
	PAGING_SETTINGS_HDR = "pageSettingsHDR",
	PAGING_SETTINGS_CONTROLS = "pageSettingsControls",
	PAGING_SETTINGS_DISPLAY = "pageSettingsDisplay"
}

function SettingsScreen.new(target, customMt, messageCenter, l10n, inputManager, settingsModel, isConsoleVersion)
	local self = TabbedMenuWithDetails.new(target, customMt or SettingsScreen_mt, messageCenter, l10n, inputManager)

	self:registerControls(SettingsScreen.CONTROLS)

	self.settingsModel = settingsModel
	self.isConsoleVersion = isConsoleVersion

	return self
end

function SettingsScreen:onGuiSetupFinished()
	SettingsScreen:superClass().onGuiSetupFinished(self)

	self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)

	self.pageSettingsGeneral:initialize()
	self.pageSettingsDisplay:initialize()
	self.pageSettingsDisplay:setOpenAdvancedSettingsCallback(function ()
		self:onClickAdvancedSettings()
	end)
	self.pageSettingsDisplay:setOpenHDRSettingsCallback(function ()
		self:onClickHDRSettings()
	end)
	self.pageSettingsAdvanced:initialize()
	self.pageSettingsHDR:initialize()
	self.pageSettingsConsole:initialize()
	self.pageSettingsConsole:setOpenHDRSettingsCallback(function ()
		self:onClickHDRSettings()
	end)
	self.pageSettingsDevice:initialize()

	local function updateSettingsControlsButtonsCallback()
		self:assignMenuButtonInfo(self.pageSettingsControls:getMenuButtonInfo())
	end

	local controlsController = ControlsController.new()

	self.pageSettingsControls:initialize(controlsController)
	self.pageSettingsControls:setRequestButtonUpdateCallback(updateSettingsControlsButtonsCallback)
	self:setupPages()
	self:setupMenuButtonInfo()
end

function SettingsScreen:setupPages()
	local orderedPages = {
		{
			self.pageSettingsGeneral,
			self:makeIsVisibleOnPCOnlyPredicate(),
			SettingsScreen.TAB_UV.GENERAL_SETTINGS
		},
		{
			self.pageSettingsDisplay,
			self:makeIsVisibleOnPCandGGPPredicate(),
			SettingsScreen.TAB_UV.DISPLAY_SETTINGS
		},
		{
			self.pageSettingsControls,
			self:makeIsVisibleOnPCOnlyPredicate(),
			SettingsScreen.TAB_UV.CONTROLS_SETTINGS
		},
		{
			self.pageSettingsDevice,
			self:makeIsVisibleOnPCOnlyPredicate(),
			SettingsScreen.TAB_UV.DEVICE_SETTINGS
		},
		{
			self.pageSettingsConsole,
			self:makeIsVisibleOnConsoleOnlyPredicate(),
			SettingsScreen.TAB_UV.CONSOLE_SETTINGS
		},
		{
			self.pageSettingsAdvanced,
			function ()
				return false
			end,
			SettingsScreen.TAB_UV.DISPLAY_SETTINGS
		},
		{
			self.pageSettingsHDR,
			function ()
				return false
			end,
			SettingsScreen.TAB_UV.DISPLAY_SETTINGS
		}
	}

	for i, pageDef in ipairs(orderedPages) do
		local page, predicate, iconUVs = unpack(pageDef)

		self:registerPage(page, i, predicate)

		local normalizedUVs = GuiUtils.getUVs(iconUVs)

		self:addPageTab(page, g_iconsUIFilename, normalizedUVs)
	end
end

function SettingsScreen:setupMenuButtonInfo()
	local onButtonBackFunction = self.clickBackCallback
	local onButtonQuitFunction = self:makeSelfCallback(self.onButtonQuit)
	local onButtonSaveGameFunction = self:makeSelfCallback(self.onButtonSaveGame)
	self.defaultMenuButtonInfo = {
		{
			inputAction = InputAction.MENU_BACK,
			text = self.l10n:getText(InGameMenu.L10N_SYMBOL.BUTTON_BACK),
			callback = onButtonBackFunction
		}
	}
	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_ACTIVATE] = self.defaultMenuButtonInfo[2]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_CANCEL] = self.defaultMenuButtonInfo[3]
	self.defaultButtonActionCallbacks = {
		[InputAction.MENU_BACK] = onButtonBackFunction,
		[InputAction.MENU_CANCEL] = onButtonQuitFunction,
		[InputAction.MENU_ACTIVATE] = onButtonSaveGameFunction
	}
end

function SettingsScreen:onSaveChangesBackCallback(yes)
	if yes then
		self.settingsModel:applyChanges(SettingsModel.SETTING_CLASS.SAVE_ALL)

		if not GS_IS_CONSOLE_VERSION and not GS_PLATFORM_GGP then
			RestartManager:setStartScreen(RestartManager.START_SCREEN_SETTINGS_ADVANCED)
			doRestart(false, "")
		else
			self:changeScreen(MainScreen)
		end
	else
		self.settingsModel:reset()
		self:changeScreen(MainScreen)
	end
end

function SettingsScreen:exitMenu()
	if self.settingsModel:hasChanges() then
		g_gui:showYesNoDialog({
			text = self.l10n:getText("ui_saveChanges"),
			title = self.l10n:getText("ui_saveSettings"),
			callback = self.onSaveChangesBackCallback,
			target = self
		})
	elseif self.currentPage:requestClose(self.clickBackCallback) then
		self:changeScreen(MainScreen)
	end
end

function SettingsScreen:showDisplaySettings()
	self:goToPage(self.pageSettingsDisplay)
end

function SettingsScreen:showGeneralSettings()
	self:goToPage(self.pageSettingsGeneral)
end

function SettingsScreen:onClickAdvancedSettings()
	self:pushDetail(self.pageSettingsAdvanced)
end

function SettingsScreen:onClickHDRSettings()
	self:pushDetail(self.pageSettingsHDR)
end

function SettingsScreen:makeIsAlwaysVisiblePredicate()
	return function ()
		return self:getIsDetailMode()
	end
end

function SettingsScreen:makeIsVisibleOnConsoleOnlyPredicate()
	return function ()
		return self.isConsoleVersion
	end
end

function SettingsScreen:makeIsVisibleOnPCOnlyPredicate()
	return function ()
		return not self.isConsoleVersion
	end
end

function SettingsScreen:makeIsVisibleOnPCandGGPPredicate()
	return function ()
		return not self.isConsoleVersion or GS_PLATFORM_GGP
	end
end

SettingsScreen.TAB_UV = {
	GENERAL_SETTINGS = {
		715,
		0,
		65,
		65
	},
	DISPLAY_SETTINGS = {
		780,
		0,
		65,
		65
	},
	CONSOLE_SETTINGS = {
		715,
		0,
		65,
		65
	},
	CONTROLS_SETTINGS = {
		845,
		0,
		65,
		65
	},
	DEVICE_SETTINGS = {
		780,
		65,
		65,
		65
	}
}
