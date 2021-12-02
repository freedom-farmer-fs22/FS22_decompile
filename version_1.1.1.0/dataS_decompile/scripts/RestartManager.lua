RestartManager = {
	START_SCREEN_MAIN = 1,
	START_SCREEN_JOIN_GAME = 2,
	START_SCREEN_MULTIPLAYER = 3,
	START_SCREEN_SETTINGS = 5,
	START_SCREEN_SETTINGS_ADVANCED = 6,
	init = function (self, args)
		self.restarting = string.find(args, "-restart") ~= nil
	end
}

function RestartManager:handleRestart()
	local startScreen = getStartMode()

	if startScreen == RestartManager.START_SCREEN_MAIN then
		g_gui:showGui("MainScreen")
	elseif startScreen == RestartManager.START_SCREEN_JOIN_GAME then
		g_multiplayerScreen:onJoinGameClick()
	elseif startScreen == RestartManager.START_SCREEN_MULTIPLAYER then
		g_gui:showGui("MainScreen")
		g_mainScreen:onMultiplayerClickPerform()
	elseif startScreen == RestartManager.START_SCREEN_SETTINGS then
		g_gui:showGui("SettingsScreen")
		g_settingsScreen:showGeneralSettings()
	elseif startScreen == RestartManager.START_SCREEN_SETTINGS_ADVANCED then
		g_gui:showGui("SettingsScreen")
		g_settingsScreen:showDisplaySettings()
	end

	if promptUserConfirmScreenMode() then
		self.restartDisplayTime = 15000

		g_gui:showYesNoDialog({
			text = g_i18n:getText("dialog_keepDisplayProperties") .. "\n" .. tostring(self.restartDisplayTime / 1000),
			callback = self.restartDisplayOk,
			target = self
		})

		self.restartDisplayTimerId = addTimer(1000, "restartDisplayTimeUpdate", self)
	end
end

function RestartManager:setStartScreen(screen)
	setStartMode(screen)
end

function RestartManager:restartDisplayTimeUpdate()
	self.restartDisplayTime = self.restartDisplayTime - 1000

	if self.restartDisplayTime > 0 then
		g_yesNoDialog:setText(g_i18n:getText("dialog_keepDisplayProperties") .. "\n" .. tostring(self.restartDisplayTime / 1000))
		setTimerTime(self.restartDisplayTimerId, 1000)

		return true
	else
		self.restartDisplayTime = nil
		self.restartDisplayTimerId = nil

		self:restartDisplayNotOk()

		return false
	end
end

function RestartManager:restartDisplayOk(yes)
	removeTimer(self.restartDisplayTimerId)

	self.restartDisplayTime = nil
	self.restartDisplayTimerId = nil

	if yes then
		setUserConfirmScreenMode(true)
	else
		self:restartDisplayNotOk()
	end
end

function RestartManager:restartDisplayNotOk()
	setUserConfirmScreenMode(false)
	doRestart(true, "")
end
