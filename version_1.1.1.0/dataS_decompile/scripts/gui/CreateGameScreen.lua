CreateGameScreen = {
	CONTROLS = {
		SETTINGS_BOX = "settingsBox",
		BANDWIDTH_ELEMENT = "bandwidthElement",
		PASSWORD_ELEMENT = "passwordElement",
		MULTIPLAYER_ELEMENT = "multiplayerLanguageElement",
		ALLOW_ONLY_FRIENDS_ELEMENT = "allowOnlyFriendsElement",
		AUTO_ACCEPT_ELEMENT = "autoAcceptElement",
		BUTTON_BOX = "buttonBox",
		CHANGE_BUTTON = "changeButton",
		USE_UPNP_ELEMENT = "useUpnpElement",
		ALLOW_CROSS_PLAY_ELEMENT = "allowCrossPlayElement",
		SERVER_NAME_ELEMENT = "serverNameElement",
		PORT_ELEMENT = "portElement",
		CAPACITY_ELEMENT = "capacityElement"
	}
}
local CreateGameScreen_mt = Class(CreateGameScreen, ScreenElement)

function CreateGameScreen.new(target, custom_mt, startMissionInfo)
	local self = ScreenElement.new(target, custom_mt or CreateGameScreen_mt)

	self:registerControls(CreateGameScreen.CONTROLS)

	if not GS_IS_CONSOLE_VERSION then
		self.capacityTable = {
			"2"
		}
		self.capacityNumberTable = {
			2
		}
	else
		self.capacityTable = {
			"2",
			"3",
			"4",
			"5",
			"6"
		}
		self.capacityNumberTable = {
			2,
			3,
			4,
			5,
			6
		}
	end

	self.startMissionInfo = startMissionInfo
	self.lastCheckedPort = nil
	self.isPortTesting = false
	self.mappedPortUDP = 0
	self.mappedPortTCP = 0
	self.connectionsTable = {}
	self.connectionsInfos = {}

	if GS_PLATFORM_GGP then
		table.insert(self.connectionsTable, "LAN (100/100 Mbit/s)")
		table.insert(self.connectionsInfos, {
			maxCapacity = 16,
			uploadRate = 1000
		})

		self.dedicatedServerConnectionIndex = 1
	elseif not GS_IS_CONSOLE_VERSION then
		table.insert(self.connectionsTable, "DSL 6000 (6/0.5 Mbit/s)")
		table.insert(self.connectionsInfos, {
			maxCapacity = 4,
			uploadRate = 50
		})
		table.insert(self.connectionsTable, "DSL 16000 (16/1 Mbit/s)")
		table.insert(self.connectionsInfos, {
			maxCapacity = 8,
			uploadRate = 80
		})
		table.insert(self.connectionsTable, "DSL 25 (25/5 Mbit/s)")
		table.insert(self.connectionsInfos, {
			maxCapacity = 10,
			uploadRate = 150
		})
		table.insert(self.connectionsTable, "DSL 50 (50/10 Mbit/s)")
		table.insert(self.connectionsInfos, {
			maxCapacity = 12,
			uploadRate = 250
		})
		table.insert(self.connectionsTable, "DSL 100 (100/20 Mbit/s)")
		table.insert(self.connectionsInfos, {
			maxCapacity = 16,
			uploadRate = 500
		})
		table.insert(self.connectionsTable, "LAN (100/100 Mbit/s)")
		table.insert(self.connectionsInfos, {
			maxCapacity = 16,
			uploadRate = 1000
		})

		self.dedicatedServerConnectionIndex = #self.connectionsTable - 1
	else
		table.insert(self.connectionsTable, "16Mbps/1Mbps")
		table.insert(self.connectionsInfos, {
			uploadRate = 80,
			maxCapacity = g_serverMaxCapacity
		})

		self.dedicatedServerConnectionIndex = 1
	end

	self.defaultServerName = ""
	self.lastUserName = ""
	self.useUpnp = false
	self.allowOnlyFriends = false
	self.allowCrossPlay = false
	self.autoAccept = false
	self.usePendingInvites = false
	self.mpLanguage = g_gameSettings:getValue(GameSettings.SETTING.MP_LANGUAGE)
	self.returnScreenName = "CareerScreen"
	self.blockTime = 0

	return self
end

function CreateGameScreen:onCreate()
	self.portElement.parent:setVisible(Platform.hasNetworkSettings)
	self.useUpnpElement:setVisible(Platform.hasNetworkSettings)
	self.bandwidthElement:setVisible(Platform.hasNetworkSettings)
	self.allowOnlyFriendsElement:setVisible(Platform.hasFriendFilter)
	self.settingsBox:invalidateLayout()

	if GS_IS_CONSOLE_VERSION then
		self.changeButton:setVisible(true)
		self.buttonBox:invalidateLayout()
	end
end

function CreateGameScreen:getDefaultServerName()
	local name = nil
	local nickname = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)

	if g_languageShort == "pl" then
		name = nickname .. " - " .. g_i18n:getText("ui_serverNameGame")
	elseif nickname:endsWith("s") then
		name = nickname .. "' " .. g_i18n:getText("ui_serverNameGame")
	elseif nickname:endsWith("'") then
		name = nickname .. "s " .. g_i18n:getText("ui_serverNameGame")
	else
		name = nickname .. "'s " .. g_i18n:getText("ui_serverNameGame")
	end

	return name
end

function CreateGameScreen:onCreateNumPlayer(element)
	self.capacityElement = element

	element:setTexts(self.capacityTable)
	element:setState(table.getn(self.capacityTable))
end

function CreateGameScreen:onCreateBandwidth(element)
	self.bandwidthElement = element

	element:setTexts(self.connectionsTable)
end

function CreateGameScreen:onCreateMultiplayerLanguage(element)
	self.multiplayerLanguageElement = element
	local languageTable = {}
	local numL = getNumOfLanguages()

	for i = 0, numL - 1 do
		table.insert(languageTable, getLanguageName(i))
	end

	element:setTexts(languageTable)
end

function CreateGameScreen:onOpen()
	CreateGameScreen:superClass().onOpen(self)
	self.allowCrossPlayElement:setVisible(getAllowCrossPlay())
	self.settingsBox:invalidateLayout()

	local reloadSettings = not self.settingsLoaded

	if GS_IS_CONSOLE_VERSION then
		if self.lastUserName ~= g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) then
			self.lastUserName = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
			reloadSettings = true
		end

		FocusManager:setFocus(self.serverNameElement)
	end

	if reloadSettings then
		local bandwidth = g_gameSettings:getTableValue("createGame", "bandwidth")

		self.bandwidthElement:setState(MathUtil.clamp(Utils.getNoNil(bandwidth, 2), 1, table.getn(self.connectionsTable)))
	end

	self:fillCapacity()

	local capacityState = table.getn(self.capacityNumberTable)

	if reloadSettings then
		self.settingsLoaded = true
		self.defaultServerName = self:getDefaultServerName()

		self.serverNameElement:setText(Utils.getNoNil(g_gameSettings:getTableValue("createGame", "serverName"), self.defaultServerName))
		self.passwordElement:setText(Utils.getNoNil(g_gameSettings:getTableValue("createGame", "password"), ""))
		self.portElement:setText(tostring(Utils.getNoNil(g_gameSettings:getTableValue("createGame", "port"), g_gameSettings:getValue("defaultServerPort"))))

		self.useUpnp = Utils.getNoNil(g_gameSettings:getTableValue("createGame", "useUpnp"), false)

		self.useUpnpElement:setIsChecked(self.useUpnp)

		self.autoAccept = Utils.getNoNil(g_gameSettings:getTableValue("createGame", "autoAccept"), false)

		self.autoAcceptElement:setIsChecked(self.autoAccept)

		self.allowOnlyFriends = Utils.getNoNil(g_gameSettings:getTableValue("createGame", "allowOnlyFriends"), false)

		self.allowOnlyFriendsElement:setIsChecked(self.allowOnlyFriends)

		self.allowCrossPlay = Utils.getNoNil(g_gameSettings:getTableValue("createGame", "allowCrossPlay"), false) and getAllowCrossPlay()

		self.allowCrossPlayElement:setIsChecked(self.allowCrossPlay)

		self.mpLanguage = Utils.getNoNil(g_gameSettings:getValue(GameSettings.SETTING.MP_LANGUAGE), g_language)

		self.multiplayerLanguageElement:setState(self.mpLanguage + 1)

		local numPlayers = g_gameSettings:getTableValue("createGame", "capacity")

		if numPlayers ~= nil then
			for i = 1, table.getn(self.capacityNumberTable) do
				if numPlayers == self.capacityNumberTable[i] then
					capacityState = i

					break
				end
			end
		end
	end

	self.capacityElement:setState(capacityState)

	self.isTyping = false
	self.isPortTesting = false
end

function CreateGameScreen:onClickUseUpnp(element)
	self.useUpnp = self.useUpnpElement:getIsChecked()
end

function CreateGameScreen:onClickAutoAccept(element)
	self.autoAccept = self.autoAcceptElement:getIsChecked()
end

function CreateGameScreen:onClickAllowOnlyFriends(element)
	self.allowOnlyFriends = self.allowOnlyFriendsElement:getIsChecked()
end

function CreateGameScreen:onClickAllowCrossPlay(element)
	self.allowCrossPlay = self.allowCrossPlayElement:getIsChecked()
end

function CreateGameScreen:onClickNumPlayer(state)
	self.capacity = state
end

function CreateGameScreen:onClickMultiplayerLanguage(state)
	self.mpLanguage = state - 1
	self.mpLanguage = MathUtil.clamp(self.mpLanguage, 0, getNumOfLanguages() - 1)
end

function CreateGameScreen:onClickBandwidth(state)
	self:fillCapacity()
end

function CreateGameScreen:onFocus(element)
	self.currentInputElement = element

	self:showChangeButton(true)
end

function CreateGameScreen:onLeave(element)
	self.currentInputElement = nil

	self:showChangeButton(false)
end

function CreateGameScreen:onEscPressed(element)
	FocusManager:setFocus(element)

	self.isTyping = false
	self.blockTime = self.time + 250

	FocusManager:unsetFocus(element)
	FocusManager:setFocus(element)
end

function CreateGameScreen:onEnterPressed(element)
	self.blockTime = self.time + 250
	self.isTyping = false

	FocusManager:unsetFocus(element)
	FocusManager:setFocus(element)
end

function CreateGameScreen:onEnter(element)
	self.isTyping = true
end

function CreateGameScreen:onClickActivate()
	if self.currentInputElement ~= nil then
		self.currentInputElement:onFocusActivate()
	end
end

function CreateGameScreen:onClickBack()
	if not self.isTyping and self.blockTime <= self.time then
		self.startMissionInfo.canStart = false

		CreateGameScreen:superClass().onClickBack(self)
	end
end

function CreateGameScreen:onClickOk()
	if not self.isTyping and self.blockTime <= self.time then
		CreateGameScreen:superClass().onClickOk(self)

		if not self:verifyServerName() then
			return true
		end

		g_gameSettings:setValue(GameSettings.SETTING.MP_LANGUAGE, self.mpLanguage)

		local port = self:getPort()
		local capacity = self.capacityNumberTable[self.capacityElement.state]

		g_gameSettings:setTableValue("createGame", "password", self.passwordElement.text)
		g_gameSettings:setTableValue("createGame", "serverName", self.serverNameElement.text)
		g_gameSettings:setTableValue("createGame", "port", port)
		g_gameSettings:setTableValue("createGame", "bandwidth", self.bandwidthElement.state)
		g_gameSettings:setTableValue("createGame", "capacity", capacity)
		g_gameSettings:setTableValue("createGame", "useUpnp", self.useUpnp)
		g_gameSettings:setTableValue("createGame", "allowOnlyFriends", self.allowOnlyFriends)
		g_gameSettings:setTableValue("createGame", "allowCrossPlay", self.allowCrossPlay)
		g_gameSettings:setTableValue("createGame", "autoAccept", self.autoAccept)
		g_gameSettings:saveToXMLFile(g_savegameXML)

		if not GS_IS_CONSOLE_VERSION then
			self.missionDynamicInfo.serverPort = port
		else
			self.missionDynamicInfo.serverPort = g_gameSettings:getValue("defaultServerPort")
		end

		self.missionDynamicInfo.isMultiplayer = true
		self.missionDynamicInfo.isClient = false
		self.missionDynamicInfo.password = self.passwordElement.text
		self.missionDynamicInfo.allowOnlyFriends = self.allowOnlyFriends
		self.missionDynamicInfo.allowCrossPlay = self.allowCrossPlay
		self.missionDynamicInfo.serverName = self.serverNameElement.text
		self.missionDynamicInfo.capacity = capacity
		self.missionDynamicInfo.autoAccept = self.autoAccept or g_dedicatedServer ~= nil
		local uploadRate = self.connectionsInfos[self.bandwidthElement.state].uploadRate
		g_maxUploadRate = uploadRate * 1024 / 1000

		if GS_IS_CONSOLE_VERSION and capacity < 5 then
			g_maxUploadRate = g_maxUploadRate * 0.9
		end

		if GS_PLATFORM_PLAYSTATION then
			local ok, _, up, measured = netGetBandwidthEstimate()

			if ok and measured then
				up = up / 10
				up = up * 0.8
				g_maxUploadRate = up / 1000
				g_maxUploadRate = MathUtil.clamp(g_maxUploadRate, 20, 200)
			end
		end

		g_mpLoadingScreen:setMissionInfo(self.missionInfo, self.missionDynamicInfo)
		g_mpLoadingScreen:showPortTesting()
		self:preparePortAndStartGame()

		return false
	elseif self.currentInputElement ~= nil then
		self.currentInputElement:setForcePressed(false)
	end

	return true
end

function CreateGameScreen:verifyServerName()
	local serverName = self.serverNameElement.text:trim()
	local filteredServerName = filterText(serverName, false, true)

	if serverName == "" or serverName ~= filteredServerName then
		if serverName == "" then
			self.serverNameElement:setText(self.defaultServerName)
		else
			self.serverNameElement:setText(filteredServerName)
			print("Warning: Gamename not allowed. Profanity text filter. Gamename adjusted")
		end

		return false
	end

	return true
end

function CreateGameScreen:getPort()
	if not GS_IS_CONSOLE_VERSION then
		local port = tonumber(self.portElement.text)

		if port == nil then
			port = g_gameSettings:getValue("defaultServerPort")
		end

		self.portElement:setText(tostring(port))

		return port
	else
		return g_gameSettings:getValue("defaultServerPort")
	end
end

function CreateGameScreen:startGameAfterPortCheck()
	g_mpLoadingScreen:loadSavegameAndStart()
end

function CreateGameScreen:removePortMapping()
	if self.mappedPortUDP ~= 0 then
		upnpRemovePortMapping(self.mappedPortUDP, "UDP")

		self.mappedPortUDP = 0
	end

	if self.mappedPortTCP ~= 0 then
		upnpRemovePortMapping(self.mappedPortTCP, "TCP")

		self.mappedPortTCP = 0
	end

	self.lastCheckedPort = nil
end

function CreateGameScreen:preparePortAndStartGame()
	local port = self:getPort()

	if self.useUpnp and (self.lastCheckedPort == nil or self.lastCheckedPort ~= port) then
		self:removePortMapping()

		self.lastCheckedPort = port
		local hasUPNPDevice = upnpDiscover(2000, "")

		if hasUPNPDevice then
			local ip = netGetDefaultLocalIp()

			upnpRemovePortMapping(port, "UDP")
			upnpRemovePortMapping(port, "TCP")

			local mappingUDPError = upnpAddPortMapping(port, port, "Farming Simulator UDP (" .. ip .. ")", "UDP")
			local mappingTCPError = upnpAddPortMapping(port, port, "Farming Simulator TCP (" .. ip .. ")", "TCP")

			if mappingUDPError ~= Upnp.ADD_PORT_CONFLICT then
				self.mappedPortUDP = port
			end

			if mappingTCPError ~= Upnp.ADD_PORT_CONFLICT then
				self.mappedPortTCP = port
			end

			if mappingUDPError ~= Upnp.ADD_PORT_SUCCESS then
				print("Warning: Failed to add UDP port mapping (" .. port .. "), error code: " .. mappingUDPError)
			end

			if mappingTCPError ~= Upnp.ADD_PORT_SUCCESS then
				print("Warning: Failed to add TCP port mapping (" .. port .. "), error code: " .. mappingTCPError)
			end
		else
			print("Warning: No UPnP device found")
		end

		self:startGameAfterPortCheck()
	else
		self:startGameAfterPortCheck()
	end
end

function CreateGameScreen:unusedPacketReceived()
end

function CreateGameScreen:onMasterServerConnectionFailed(reason)
	if self.isPortTesting then
		self.isPortTesting = false

		netShutdown(500, 0)
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, "CreateGameScreen")
	end
end

function CreateGameScreen:fillCapacity()
	local bandwidth = self.bandwidthElement.state

	if g_dedicatedServer ~= nil then
		bandwidth = self.dedicatedServerConnectionIndex
	end

	local info = self.connectionsInfos[bandwidth]
	self.capacityTable = {}
	self.capacityNumberTable = {}

	for i = 2, info.maxCapacity do
		table.insert(self.capacityTable, tostring(i))
		table.insert(self.capacityNumberTable, i)
	end

	local state = self.capacityElement.state

	self.capacityElement:setTexts(self.capacityTable)
	self.capacityElement:setState(math.min(state, table.getn(self.capacityTable)))
end

function CreateGameScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	self.missionInfo = missionInfo
	self.missionDynamicInfo = missionDynamicInfo
end

function CreateGameScreen:onIsUnicodeAllowed(unicode)
	return string.byte("0", 1) <= unicode and unicode <= string.byte("9", 1)
end

function CreateGameScreen:showChangeButton(show)
	if show ~= self.changeButton:getIsVisible() then
		self.changeButton:setVisible(show)
		self.buttonBox:invalidateLayout()
	end
end

function CreateGameScreen:update(dt)
	CreateGameScreen:superClass().update(self, dt)

	if g_dedicatedServer ~= nil then
		local dediData = g_dedicatedServer

		self.serverNameElement:setText(tostring(dediData.name))
		self.passwordElement:setText(tostring(dediData.password))
		self.portElement:setText(tostring(dediData.port))
		self.useUpnpElement:setIsChecked(dediData.useUpnp)
		self.allowCrossPlayElement:setIsChecked(dediData.crossplayAllowed)

		self.missionDynamicInfo.serverAddress = dediData.ip

		self.bandwidthElement:setState(self.dedicatedServerConnectionIndex)

		local capacityState = dediData.maxPlayer - g_serverMinCapacity + 1

		self.capacityElement:setState(capacityState)

		self.allowCrossPlay = dediData.crossplayAllowed
		self.useUpnp = dediData.useUpnp
		local hasError = self:onClickOk()

		if hasError then
			self:onClickOk()
		end

		return
	end

	self:showChangeButton(self.currentInputElement ~= nil)

	if GS_PLATFORM_PLAYSTATION then
		if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
			g_masterServerConnection:disconnectFromMasterServer()
			g_gui:showGui("MainScreen")
		end

		if getNetworkError() then
			g_masterServerConnection:disconnectFromMasterServer()
			ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
		end
	end
end
