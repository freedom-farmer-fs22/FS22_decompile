MultiplayerScreen = {
	CONTROLS = {
		"onlinePresenceNameElement",
		"changeNameButton",
		NAT_WARNING = "natWarning",
		LIST = "list"
	}
}
local MultiplayerScreen_mt = Class(MultiplayerScreen, ScreenElement)

function MultiplayerScreen.new(target, custom_mt, startMissionInfo)
	local self = ScreenElement.new(target, custom_mt or MultiplayerScreen_mt)

	self:registerControls(MultiplayerScreen.CONTROLS)

	self.startMissionInfo = startMissionInfo
	self.returnScreenClass = MainScreen

	return self
end

function MultiplayerScreen:onOpen()
	MultiplayerScreen:superClass().onOpen(self)
	self:initJoinGameScreen()

	self.startMissionInfo.createGame = false
	self.startMissionInfo.isMultiplayer = true

	if self.startMissionInfo.canStart then
		self.startMissionInfo.canStart = false

		self:changeScreen(ConnectToMasterServerScreen)
		g_connectToMasterServerScreen:connectToFront()
	end

	self:updateOnlinePresenceName()
	self.list:reloadData()
end

function MultiplayerScreen:updateOnlinePresenceName()
	self.onlinePresenceNameElement:setText(g_i18n:getText("ui_onlinePresenceName") .. ": " .. g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME))

	if Platform.canChangeGamerTag then
		self.changeNameButton:setVisible(true)
	else
		self.changeNameButton:setVisible(false)
	end
end

function MultiplayerScreen:initJoinGameScreen()
	g_connectionManager:startupWithWorkingPort(g_gameSettings:getValue("defaultServerPort"))
	g_connectToMasterServerScreen:setNextScreenName("JoinGameScreen")
	g_connectToMasterServerScreen:setPrevScreenName("MultiplayerScreen")
end

function MultiplayerScreen:onContinue()
	local index = self.list.selectedIndex

	if index == 1 then
		self.startMissionInfo.canStart = false

		self:changeScreen(ConnectToMasterServerScreen)
		g_connectToMasterServerScreen:connectToFront()
	elseif index == 2 then
		self.startMissionInfo.canStart = false
		g_createGameScreen.usePendingInvites = false

		self:changeScreen(CareerScreen, MainScreen)
	elseif index == 3 then
		if not GS_IS_STEAM_VERSION then
			openWebFile("fs22-rent-a-dedicated-server.php", "")
		else
			openWebFile("fs22-rent-a-dedicated-server-from-steam.php", "")
		end
	end
end

function MultiplayerScreen:onClickCreateGame()
	self.list:setSelectedIndex(2)
	self:onContinue()
end

function MultiplayerScreen:onClickJoinGame()
	self.list:setSelectedIndex(1)
	self:onContinue()
end

function MultiplayerScreen:update(dt)
	MultiplayerScreen:superClass().update(self, dt)
	Platform.verifyMultiplayerAvailabilityInMenu()
	self.natWarning:setVisible(getNATType() == NATType.NAT_STRICT)
end

function MultiplayerScreen:onClickChangeName()
	g_gui:showTextInputDialog({
		text = g_i18n:getText("ui_enterName"),
		callback = function (newName)
			if newName ~= g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) then
				g_gameSettings:setValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME, newName, true)
				self:updateOnlinePresenceName()
			end
		end,
		defaultText = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME),
		confirmText = g_i18n:getText("button_change")
	})
end

function MultiplayerScreen:onClickOpenBlocklist()
	g_gui:showUnblockDialog({
		useLocal = true
	})
end

function MultiplayerScreen:getNumberOfItemsInSection(list, section)
	return Platform.showRentServerWebButton and 3 or 2
end

function MultiplayerScreen:populateCellForItemInSection(list, section, index, cell)
	if index == 1 then
		cell:getAttribute("title"):setLocaKey("button_joinGame")
		cell:getAttribute("icon"):applyProfile("multiplayerButtonIconJoin")
	elseif index == 2 then
		cell:getAttribute("title"):setLocaKey("button_createGame")
		cell:getAttribute("icon"):applyProfile("multiplayerButtonIconCreate")
	elseif index == 3 then
		cell:getAttribute("title"):setLocaKey("button_rentAServer")
		cell:getAttribute("icon"):applyProfile("multiplayerButtonIconRent")
	end
end
