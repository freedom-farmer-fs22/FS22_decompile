GamepadSigninScreen = {
	CONTROLS = {
		TRACTOR = "backgroundTractor",
		LOGO = "logo",
		START_TEXT = "startText"
	}
}
local GamepadSigninScreen_mt = Class(GamepadSigninScreen, ScreenElement)

function GamepadSigninScreen.new(inGameMenu, shopMenu, achievementManager, settingsModel)
	local self = GamepadSigninScreen:superClass().new(nil, GamepadSigninScreen_mt)

	self:registerControls(GamepadSigninScreen.CONTROLS)

	self.inGameMenu = inGameMenu
	self.shopMenu = shopMenu
	self.achievementManager = achievementManager
	self.settingsModel = settingsModel
	self.textSpeed = 600
	self.textTime = 0
	self.textDir = 1
	self.textColor1 = {
		1,
		1,
		1,
		1
	}
	self.textColor2 = {
		1,
		1,
		1,
		0
	}
	self.textColor = {
		1,
		1,
		0.25,
		1
	}
	self.forceShowSigninGui = false
	self.requestCounter = -1

	return self
end

function GamepadSigninScreen:onCreate()
end

function GamepadSigninScreen:onOpen()
	g_isSignedIn = false

	if not g_menuMusicIsPlayingStarted then
		g_menuMusicIsPlayingStarted = true

		playStreamedSample(g_menuMusic, 0)
	end

	if g_currentMission ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer then
		g_currentMission:cancelPlayersSynchronizing()
	end

	if g_modNameToDirectory[g_uniqueDlcNamePrefix .. "claasPack"] ~= nil then
		self.logo:setImageFilename("dataS/menu/main_platinum_logo_en.png")
	else
		self.logo:setImageFilename("dataS/menu/main_logo_en.png")
	end

	self.requestCounter = 2
end

function GamepadSigninScreen:onClose()
end

function GamepadSigninScreen:update(dt)
	GamepadSigninScreen:superClass().update(self, dt)

	if not isGamepadSigninPending() then
		self.startText:setText(g_i18n:getText("ui_consolePressStart"))
	else
		self.startText:setText("...")
	end

	self.textTime = self.textTime + self.textDir * dt

	if self.textSpeed < self.textTime then
		self.textTime = self.textSpeed
		self.textDir = -self.textDir
	end

	if self.textTime < 0 then
		self.textTime = 0
		self.textDir = -self.textDir
	end

	local colorAlpha = self.textTime / self.textSpeed

	for i = 1, 4 do
		self.textColor[i] = (1 - colorAlpha) * self.textColor1[i] + self.textColor2[i] * colorAlpha
	end

	if self.requestCounter >= 0 then
		self.requestCounter = self.requestCounter - 1

		if self.requestCounter < 0 then
			requestGamepadSignin(Input.BUTTON_2, self.forceShowSigninGui, true)
		end
	end

	self.startText:setTextColor(unpack(self.textColor))
	self.startText:setText2Color(self.startText.text2Color[1], self.startText.text2Color[2], self.startText.text2Color[3], self.startText.textColor[4])
end

function GamepadSigninScreen:onYesNoSigninAccept(yes)
	if yes then
		self.forceShowSigninGui = true

		self:changeScreen(GamepadSigninScreen)
	else
		g_tempDeepLinkingInfo = nil

		self:changeScreen(MainScreen)
	end
end

function GamepadSigninScreen:inputEvent(action, value, eventUsed)
	if action == InputAction.MENU_ACCEPT and self.requestCounter < 0 then
		self:signIn()

		eventUsed = true
	end

	return eventUsed
end

function GamepadSigninScreen:signIn()
	self.achievementManager:resetAchievementsState()

	self.forceShowSigninGui = false
	g_isSignedIn = true
	local resumeGame = g_currentMission ~= nil

	if GS_PLATFORM_XBOX then
		local newUserName = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)

		if newUserName ~= g_currentPlayingUserName then
			resumeGame = false
		end

		g_currentPlayingUserName = newUserName
	end

	if g_tempDeepLinkingInfo ~= nil then
		local requestUserName = g_tempDeepLinkingInfo.requestUserName

		if GS_PLATFORM_XBOX and requestUserName ~= "" and g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) ~= requestUserName then
			g_gui:showYesNoDialog({
				text = string.format(g_i18n:getText("ui_signinWithUserToAcceptInviteRetry"), requestUserName),
				callback = self.onYesNoSigninAccept,
				target = self
			})
		else
			local info = g_tempDeepLinkingInfo
			g_tempDeepLinkingInfo = nil

			if PlatformPrivilegeUtil.checkMultiplayer(acceptedGameInvitePerformConnect, nil, info.platformServerId, 30000) then
				acceptedGameInvitePerformConnect(info.platformServerId)
			end
		end
	elseif resumeGame then
		if g_currentMission.missionDynamicInfo.isMultiplayer then
			g_currentMission:cancelPlayersSynchronizing()
			self:changeScreen(InGameMenu)
			self.inGameMenu:setMasterServerConnectionFailed(MasterServerConnection.FAILED_CONNECTION_LOST)
		else
			g_currentMission.userSigninPaused = false

			g_currentMission:tryUnpauseGame()
			self:changeScreen(nil)
		end
	else
		if g_currentMission ~= nil then
			OnInGameMenuMenu()
		end

		self:changeScreen(MainScreen)
	end
end
