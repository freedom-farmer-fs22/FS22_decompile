ServerSettingsDialog = {}
local ServerSettingsDialog_mt = Class(ServerSettingsDialog, DialogElement)
ServerSettingsDialog.CONTROLS = {
	PASSWORD = "passwordElement",
	SERVER_NAME = "serverNameElement",
	CHANGE_BUTTON = "changeButton",
	LAYOUT = "boxLayout",
	ALLOW_ONLY_FRIENDS = "allowOnlyFriendsElement",
	AUTO_ACCEPT = "autoAcceptElement",
	SAVE_BUTTON = "saveButton"
}

local function NO_CALLBACK()
end

function ServerSettingsDialog.new(target, customMt, l10n)
	local self = ColorPickerDialog.new(target, customMt or ServerSettingsDialog_mt)
	self.l10n = l10n

	self:registerControls(ServerSettingsDialog.CONTROLS)

	self.inputDelay = 250
	self.capacityTable = {}
	self.capacityNumberTable = {}

	for i = g_serverMinCapacity, g_serverMaxCapacity do
		table.insert(self.capacityTable, tostring(i))
		table.insert(self.capacityNumberTable, i)
	end

	return self
end

function ServerSettingsDialog:onCreateNumPlayer(element)
	self.capacityElement = element

	element:setTexts(self.capacityTable)
	element:setState(table.getn(self.capacityTable))
end

function ServerSettingsDialog:onOpen()
	ServerSettingsDialog:superClass().onOpen(self)
	self.allowOnlyFriendsElement:setVisible(Platform.hasFriendFilter)

	local dynInfo = g_currentMission.missionDynamicInfo
	local numPlayers = dynInfo.capacity
	local capacityState = g_serverMinCapacity

	for i = 1, table.getn(self.capacityNumberTable) do
		if numPlayers == self.capacityNumberTable[i] then
			capacityState = i

			break
		end
	end

	self.capacityElement:setState(capacityState)
	self.serverNameElement:setVisible(not g_currentMission.connectedToDedicatedServer)
	self.autoAcceptElement:setVisible(not g_currentMission.connectedToDedicatedServer)
	self.capacityElement:setVisible(not g_currentMission.connectedToDedicatedServer)
	self.serverNameElement:setText(dynInfo.serverName)
	self.passwordElement:setText(dynInfo.password)
	self.autoAcceptElement:setIsChecked(dynInfo.autoAccept)
	self.allowOnlyFriendsElement:setIsChecked(dynInfo.allowOnlyFriends)
	self.boxLayout:invalidateLayout()
end

function ServerSettingsDialog:setCallback(onFinished, target, callbackArgs)
	self.onFinished = onFinished or NO_CALLBACK
	self.target = target
	self.callbackArgs = callbackArgs
end

function ServerSettingsDialog:onClickOk()
	if self.time <= self.inputDelay then
		return true
	end

	local serverName = self.serverNameElement:getText()
	local filteredServerName = filterText(serverName, false, true)

	if serverName == "" or serverName ~= filteredServerName then
		if serverName == "" then
			self.serverNameElement:setText(g_currentMission:getDefaultServerName())
		else
			self.serverNameElement:setText(filteredServerName)
			print("Warning: Gamename not allowed. Profanity text filter. Gamename adjusted")
		end

		return true
	end

	local password = self.passwordElement:getText()
	local capacity = self.capacityNumberTable[self.capacityElement:getState()]
	local autoAccept = self.autoAcceptElement:getIsChecked()
	local allowOnlyFriends = self.allowOnlyFriendsElement:getIsChecked()

	g_currentMission:updateMissionDynamicInfo(serverName, capacity, password, autoAccept, allowOnlyFriends, g_currentMission.missionDynamicInfo.allowCrossPlay)

	if g_currentMission:getIsServer() then
		g_currentMission:updateMasterServerInfo()
	else
		g_client:getServerConnection():sendEvent(MissionDynamicInfoEvent.new())
	end

	self:close()

	return false
end

function ServerSettingsDialog:onClickActivate()
	if self.currentInputElement ~= nil then
		self.currentInputElement:onFocusActivate()
	end
end

function ServerSettingsDialog:onEnter()
	self.isTyping = true
end

function ServerSettingsDialog:onFocus(element)
	self.currentInputElement = element

	self:showChangeButton(true)
end

function ServerSettingsDialog:onLeave()
	self.currentInputElement = nil

	self:showChangeButton(false)
end

function ServerSettingsDialog:showChangeButton(show)
	self.changeButton:setVisible(show)
	self.changeButton.parent:invalidateLayout()
end

function ServerSettingsDialog:onEscPressed()
	FocusManager:setFocus(element)

	self.isTyping = false
	self.blockTime = self.time + 250

	FocusManager:unsetFocus(element)
	FocusManager:setFocus(element)
end

function ServerSettingsDialog:onEnterPressed()
	self.blockTime = self.time + 250
	self.isTyping = false

	FocusManager:unsetFocus(element)
	FocusManager:setFocus(element)
end
