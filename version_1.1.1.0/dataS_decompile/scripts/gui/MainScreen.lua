MainScreen = {}
local MainScreen_mt = Class(MainScreen, ScreenElement)
MainScreen.CONTROLS = {
	NOTIFICATION_INDEX_STATE = "indexState",
	TUTORIALSBUTTON = "tutorialsButton",
	CHANGEUSERBUTTON = "changeUserButton",
	DOWNLOADMODSBUTTON = "downloadModsButton",
	NOTIFICATION_DATE = "notificationDate",
	MULTIPLAYERBUTTON = "multiplayerButton",
	BACKGROUND_BLURRY = "backgroundBlurImage",
	NOTIFICATION_TITLE = "notificationTitle",
	CAREERBUTTON = "careerButton",
	ACHIEVEMENTSBUTTON = "achievementsButton",
	LOGO = "logo",
	SETTINGSBUTTON = "settingsButton",
	GAMER_TAG_ELEMENT = "gamerTagElement",
	NOTIFICATION_BOX = "notificationElement",
	NOTIFICATION_IMAGE = "notificationImage",
	BUTTON_NOTIFICATION_RIGHT = "notificationButtonRight",
	QUITBUTTON = "quitButton",
	CREDITSBUTTON = "creditsButton",
	BUTTON_BOX = "buttonBox",
	BUTTON_NOTIFICATION_OPEN = "notificationButtonOpen",
	BUTTON_NOTIFICATION_LEFT = "notificationButtonLeft",
	BACKGROUND_GLASSEDGE = "glassEdgeOverlay",
	BACKGROUND_IMAGE = "backgroundImage",
	NOTIFICATION_MESSAGE = "notificationMessage",
	STOREBUTTON = "storeButton"
}
MainScreen.NOTIFICATION_ANIMATION_DURATION = 500
MainScreen.NOTIFICATION_CHECK_DELAY = 500
MainScreen.NOTIFICATION_ANIM_DELAY = 2000

function MainScreen.new(target, custom_mt, startMissionInfo)
	local self = ScreenElement.new(target, custom_mt or MainScreen_mt)
	self.startMissionInfo = startMissionInfo
	self.firstTimeOpened = true
	self.lastActiveButton = nil
	self.blendDir = 0
	self.blendingAlpha = 1
	self.disableMultiplayer = false
	self.showGamepadModeDialog = true
	self.showHeadTrackingDialog = true
	self.notificationShowAnimation = TweenSequence.NO_SEQUENCE
	self.notificationsHidePosition = {
		2,
		0
	}

	self:registerControls(MainScreen.CONTROLS)

	return self
end

function MainScreen:onCreate()
	self.lastButtonPressed = nil
	self.isBackAllowed = false

	self:setupNotifications()
	self:setupButtons()
	self:updateTheme()
end

function MainScreen:onClickBack(forceBack, usedMenuButton)
	if GS_PLATFORM_ID == PlatformId.ANDROID then
		g_gui:showYesNoDialog({
			text = g_i18n:getText("ui_youWantToQuitGame"),
			callback = self.onYesNoQuitGame,
			target = self
		})

		return false
	else
		return MainScreen:superClass().onClickBack(self)
	end
end

function MainScreen:onYesNoQuitGame(yes)
	if yes then
		requestExit()
	end
end

function MainScreen:setupButtons()
	local buttonSetup = {
		self.careerButton
	}

	if Platform.supportsMultiplayer then
		table.insert(buttonSetup, self.multiplayerButton)
	end

	if Platform.supportsMods then
		table.insert(buttonSetup, self.downloadModsButton)
	end

	table.insert(buttonSetup, self.achievementsButton)

	if Platform.hasNativeStore then
		table.insert(buttonSetup, self.storeButton)
	end

	if not Platform.isMobile then
		table.insert(buttonSetup, self.settingsButton)
	end

	table.insert(buttonSetup, self.creditsButton)

	if Platform.canQuitApplication then
		table.insert(buttonSetup, self.quitButton)
	end

	if Platform.needsSignIn then
		table.insert(buttonSetup, self.changeUserButton)
	end

	if g_isPresentationVersion and g_isPresentationVersionHideMenuButtons then
		self.multiplayerButton:setDisabled(true)
		self.downloadModsButton:setDisabled(true)
		self.achievementsButton:setDisabled(true)

		if not Platform.isConsole then
			self.settingsButton:setDisabled(true)
		end

		self.quitButton:setDisabled(true)
		self.storeButton:setDisabled(true)
	end

	for _, button in pairs(buttonSetup) do
		button:setVisible(true)
	end

	self.buttonBox:invalidateLayout()
end

function MainScreen:onCreateGameVersion(element)
	local gameVersionTxt = g_gameVersionDisplay .. g_gameVersionDisplayExtra .. " (" .. getEngineRevision() .. "/" .. g_gameRevision .. ")"

	element:setText(gameVersionTxt)
end

function MainScreen:onHighlight(element)
	if not Platform.isConsole then
		FocusManager:setFocus(element)
	end
end

function MainScreen:onClose()
	MainScreen:superClass().onClose(self)
	g_inputBinding:removeActionEventsByTarget(self)
	GuiOverlay.deleteOverlay(self.notificationImage.overlay)
end

function MainScreen:onOpen()
	MainScreen:superClass().onOpen(self)
	setPresenceMode(PresenceModes.PRESENCE_IDLE)
	flushWebCache()
	self:resetNotifications()

	if self.firstTimeOpened then
		self.firstTimeOpened = false

		if isGameFullyInstalled() then
			FocusManager:setFocus(self.careerButton)
		else
			error("Fatal error: the game was not fully installed but the game code expects it to be.")
		end
	end

	if not g_menuMusicIsPlayingStarted then
		g_menuMusicIsPlayingStarted = true

		playStreamedSample(g_menuMusic, 0)
	end

	if g_isServerStreamingVersion then
		self.notificationElement.visible = false
		self.notificationElement.disabled = true
	end

	FocusManager:lockFocusInput(InputAction.MENU_ACCEPT, 150)
	self:setSoundSuppressed(true)

	if self.lastActiveButton ~= nil then
		FocusManager:unsetFocus(self.lastActiveButton)
		FocusManager:setFocus(self.lastActiveButton)
	end

	self:setSoundSuppressed(false)
	g_gameStateManager:setGameState(GameState.MENU_MAIN)
	g_messageCenter:publish(MessageType.GUI_MAIN_SCREEN_OPEN)
end

function MainScreen:setupNotifications()
	local showPosition = {
		self.notificationElement.position[1],
		self.notificationElement.position[2]
	}
	self.notificationsHidePosition = {
		-self.notificationElement.position[1] + self.notificationElement.size[1],
		self.notificationElement.position[2]
	}
	local anim = TweenSequence.new(self)

	anim:addInterval(MainScreen.NOTIFICATION_ANIM_DELAY)

	local moveIn = MultiValueTween.new(self.notificationElement.setPosition, self.notificationsHidePosition, showPosition, MainScreen.NOTIFICATION_ANIMATION_DURATION)

	anim:addTween(moveIn)
	moveIn:setTarget(self.notificationElement)
	anim:addCallback(self.setNotificationButtonsDisabled, false)

	self.notificationShowAnimation = anim

	self:resetNotifications()
end

function MainScreen:setNotificationButtonsDisabled(isDisabled)
	local leftRightDisabled = isDisabled or #self.notifications < 2

	self.notificationButtonLeft:setDisabled(leftRightDisabled)
	self.notificationButtonRight:setDisabled(leftRightDisabled)
	self.notificationButtonOpen:setDisabled(isDisabled)
end

function MainScreen:resetNotifications()
	self.notificationsReady = false
	self.notificationsCheckTimer = 0
	self.notifications = {}
	self.activeNotification = 0

	self.notificationShowAnimation:reset()
	self:setNotificationButtonsDisabled(true)
	self.indexState:setVisible(false)
	self.notificationElement:setPosition(unpack(self.notificationsHidePosition))
end

function MainScreen:onYesNoUseGamepadMode(yes)
	g_gameSettings:setValue("gamepadEnabledSetByUser", true)
	g_gameSettings:setValue("isGamepadEnabled", yes)
	g_gameSettings:saveToXMLFile(g_savegameXML)
end

function MainScreen:onYesNoUseHeadTracking(yes)
	g_gameSettings:setValue("headTrackingEnabledSetByUser", true)
	g_gameSettings:setValue("isHeadTrackingEnabled", yes)
	g_gameSettings:saveToXMLFile(g_savegameXML)
end

function MainScreen:onMultiplayerClick(element)
	self.lastActiveButton = element

	resetMultiplayerChecks()
	self:onMultiplayerClickPerform()
end

function MainScreen:onMultiplayerClickPerform()
	if not isGameFullyInstalled() then
		showGameInstallProgress()

		return
	end

	if masterServerConnectFront == nil then
		RestartManager:setStartScreen(RestartManager.START_SCREEN_MULTIPLAYER)
		doRestart(false, "")
	else
		if not PlatformPrivilegeUtil.checkMultiplayer(self.onMultiplayerClickPerform, self) then
			return
		end

		self.startMissionInfo:reset()

		self.startMissionInfo.isMultiplayer = true

		g_gui:setIsMultiplayer(true)
		g_gui:showGui("MultiplayerScreen")
	end
end

function MainScreen:onCareerClick(element)
	self.lastActiveButton = element

	if not isGameFullyInstalled() then
		showGameInstallProgress()

		return
	end

	self.startMissionInfo:reset()

	self.startMissionInfo.isMultiplayer = false

	g_gui:setIsMultiplayer(false)
	self:changeScreen(CareerScreen)
end

function MainScreen:onDownloadModsClick(element)
	self.lastActiveButton = element

	resetMultiplayerChecks()
	self:onDownloadModsClickPerform()
end

function MainScreen:onDownloadModsClickPerform()
	if getNetworkError() then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
	else
		if not PlatformPrivilegeUtil.checkModDownload(self.onDownloadModsClickPerform, self) then
			return
		end

		modDownloadManagerUpdateSync(true)
		g_gui:showGui("ModHubScreen")
	end
end

function MainScreen:onAchievementsClick(element)
	self.lastActiveButton = element

	g_gui:showGui("AchievementsScreen")
end

function MainScreen:onStoreClick(element)
	self.lastActiveButton = element

	if storeHasNativeGUI() and (getNetworkError() ~= nil or not storeShow("")) then
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_dlcStoreNotConnected"),
			callback = MainScreen.onStoreFailedOk,
			target = self
		})
	end
end

function MainScreen:onStoreFailedOk()
	g_gui:showGui("MainScreen")
end

function MainScreen:onSettingsClick(element)
	self.lastActiveButton = element

	g_gui:showGui("SettingsScreen")
end

function MainScreen:onCreditsClick(element)
	self.lastActiveButton = element

	g_gui:showGui("CreditsScreen")
end

function MainScreen:onChangeUserClick()
	g_gamepadSigninScreen.forceShowSigninGui = true

	g_gui:showGui("GamepadSigninScreen")
end

function MainScreen:onQuitClick()
	doExit()
end

function MainScreen:cycleNotification(signedDelta)
	self.activeNotification = self.activeNotification + signedDelta

	if self.activeNotification > #self.notifications then
		self.activeNotification = 1
	elseif self.activeNotification < 1 then
		self.activeNotification = #self.notifications
	end

	self:assignNotificationData()
end

function MainScreen:onClickNextNotification(element)
	self:cycleNotification(1)
end

function MainScreen:onClickPreviousNotification(element)
	self:cycleNotification(-1)
end

function MainScreen:onClickOpenNotification()
	if #self.notifications > 0 then
		if self.notifications[self.activeNotification].url == "openOptionsGraphics" then
			g_gui:showGui("SettingsScreen")
			g_settingsScreen:showDisplaySettings()
		elseif storeHasNativeGUI() then
			if not storeShow(self.notifications[self.activeNotification].url) then
				g_gui:showInfoDialog({
					text = g_i18n:getText("ui_dlcStoreNotConnected"),
					callback = MainScreen.onStoreFailedOk,
					target = self
				})
			end
		else
			openWebFile(self.notifications[self.activeNotification].url, "")
		end
	end
end

function MainScreen:onDlcCorruptClick()
	g_gui:showGui("MainScreen")
end

function MainScreen:updateNotifications(dt)
	if self.notificationsReady and #self.notifications > 0 and not self.notificationShowAnimation:getFinished() then
		self.notificationShowAnimation:update(dt)
	end

	if not self.notificationsReady then
		self.notificationsCheckTimer = self.notificationsCheckTimer + dt

		if MainScreen.NOTIFICATION_CHECK_DELAY < self.notificationsCheckTimer then
			self.notificationsCheckTimer = 0
			self.notificationsReady = notificationsLoaded()

			if self.notificationsReady then
				local notificationCount = getNumOfNotifications()

				for i = 0, notificationCount - 1 do
					local notification = {
						url = "",
						message = "",
						image = "",
						date = "",
						title = ""
					}
					notification.title, notification.message, notification.url, notification.image, notification.date = getNotification(i)

					if notification.title ~= "" and notification.message ~= "" then
						table.insert(self.notifications, notification)
					end
				end

				if #self.notifications > 0 then
					self.activeNotification = 1

					self.indexState:setPageCount(#self.notifications, self.activeNotification)
					self.indexState:setVisible(#self.notifications > 1)
					self:assignNotificationData()
					self.notificationShowAnimation:start()
				else
					self.indexState:setPageCount(0)
				end
			end
		end
	end
end

function MainScreen:updateFading(dt)
	if self.blendDir ~= 0 then
		self.blendingAlpha = MathUtil.clamp(self.blendingAlpha + self.blendDir * dt / 500, 0, 1)
		local state = 0.1 + 0.9 * self.blendingAlpha

		self.backgroundImage:setImageColor(nil, state, state, state, 1)
		self.backgroundBlurImage:setImageColor(nil, state, state, state, 1)
		self.glassEdgeOverlay:setImageColor(nil, state, state, state, nil)

		if self.blendingAlpha == 1 or self.blendingAlpha == 0 then
			self.blendDir = 0

			if self.blendingAlpha == 1 then
				FocusManager:setFocus(self.lastActiveButton)
			end
		end
	end
end

function MainScreen:update(dt)
	MainScreen:superClass().update(self, dt)
	modDownloadManagerUpdateSync(false)

	if self.showGamepadModeDialog and not GS_IS_CONSOLE_VERSION and not GS_PLATFORM_GGP and not g_gameSettings:getValue("gamepadEnabledSetByUser") and getNumOfGamepads() > 0 then
		g_gui:showYesNoDialog({
			title = g_i18n:getText("ui_activateGamepadsTitle"),
			text = g_i18n:getText("ui_activateGamepads"),
			callback = self.onYesNoUseGamepadMode,
			target = self
		})

		self.showGamepadModeDialog = false
	end

	if self.showHeadTrackingDialog and not GS_IS_CONSOLE_VERSION and not g_gameSettings:getValue("headTrackingEnabledSetByUser") and isHeadTrackingAvailable() then
		g_gui:showYesNoDialog({
			title = g_i18n:getText("ui_activateHeadTrackingTitle"),
			text = g_i18n:getText("ui_activateHeadTracking"),
			callback = self.onYesNoUseHeadTracking,
			target = self
		})

		self.showHeadTrackingDialog = false
	end

	if Platform.showGamerTagInMainScreen then
		self.gamerTagElement:setText(g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME))
	end

	if GS_IS_CONSOLE_VERSION and not g_isPresentationVersion then
		if getNetworkError() then
			if self.storeButton:getIsActive() then
				self.storeButton:setDisabled(true)
			end
		elseif not self.storeButton:getIsActive() then
			self.storeButton:setDisabled(false)
		end
	end

	if self.isFirstOpen == nil then
		if isGameFullyInstalled() then
			FocusManager:setFocus(self.careerButton)
		else
			error("Not fully installed. This state is currently not supported")
		end

		self.isFirstOpen = true
	end

	if not g_isServerStreamingVersion and not g_isPresentationVersion then
		self:updateNotifications(dt)
	end

	if GS_IS_CONSOLE_VERSION or GS_PLATFORM_GGP then
		if storeHaveDlcsChanged() or haveModsChanged() or g_forceNeedsDlcsAndModsReload then
			g_forceNeedsDlcsAndModsReload = false

			reloadDlcsAndMods()
			self:resetNotifications()
			self:updateTheme()
		end
	elseif haveModsChanged() and not self.restartModDialogShown then
		self.restartModDialogShown = true

		g_gui:showYesNoDialog({
			title = g_i18n:getText("ui_modsChangedTitle"),
			text = g_i18n:getText("ui_modsChangedText") .. "\n\n" .. g_i18n:getText("ui_modsChangedRestartQuestion"),
			callback = self.onRestartModDialog,
			target = self
		})
	end

	if storeAreDlcsCorrupted() then
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_dlcsCorruptRedownload"),
			callback = self.onDlcCorruptClick,
			target = self
		})
	end

	self:updateFading(dt)
end

function MainScreen:onRestartModDialog(yes)
	if yes then
		RestartManager:setStartScreen(RestartManager.START_SCREEN_MAIN)
		doRestart(false, "")
	end
end

function MainScreen:assignNotificationData()
	if self.activeNotification > 0 and self.activeNotification <= #self.notifications then
		if not GS_IS_CONSOLE_VERSION then
			self.notificationMessage:setText(self.notifications[self.activeNotification].message)
		else
			self.notificationMessage:setText(g_i18n:getText("notification_nowAvailable"))
		end

		self.notificationTitle:setText(self.notifications[self.activeNotification].title)

		local imageFile = self.notifications[self.activeNotification].image

		if imageFile == "graphicsOptionsImage" then
			imageFile = "dataS/menu/notification_dummy.png"
		end

		self.notificationImage:setImageFilename(imageFile)

		local dateStr = self.notifications[self.activeNotification].date

		if g_languageShort ~= "en" and dateStr ~= "" then
			local dateParts = self.notifications[self.activeNotification].date:split("-")

			if g_languageShort == "de" then
				dateStr = string.format("%s.%s.%s", dateParts[3], dateParts[2], dateParts[1])
			else
				dateStr = string.format("%s/%s/%s", dateParts[3], dateParts[2], dateParts[1])
			end
		end

		self.notificationDate:setText(dateStr)

		if self.notifications[self.activeNotification].url == "openOptionsGraphics" then
			self.notificationButtonOpen:setText(g_i18n:getText("button_settings"))
		elseif storeHasNativeGUI() then
			self.notificationButtonOpen:setText(g_i18n:getText("button_dlcStore"))
		else
			self.notificationButtonOpen:setText(g_i18n:getText("button_visitWebsite"))
		end

		self.indexState:setPageIndex(self.activeNotification)
	end
end

function MainScreen:hasAllDLCs(list)
	for _, name in ipairs(list) do
		if GS_PLATFORM_GGP or GS_IS_EPIC_VERSION then
			if g_modManager:getModByName(g_uniqueDlcNamePrefix .. name) == nil then
				return false
			end
		elseif g_modNameToDirectory[g_uniqueDlcNamePrefix .. name] == nil then
			return false
		end
	end

	return true
end

function MainScreen:updateTheme()
	self.logo:setImageFilename("dataS/menu/main_logo_en.png")
end
