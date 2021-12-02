InGameMenuMultiplayerUsersFrame = {}
local InGameMenuMultiplayerUsersFrame_mt = Class(InGameMenuMultiplayerUsersFrame, TabbedMenuFrameElement)
InGameMenuMultiplayerUsersFrame.CONTROLS = {
	"currentBalanceLabel",
	"currentBalanceText",
	"container",
	"actionsBox",
	"permissionsBox",
	"userList",
	"permissionRow",
	"transferButton",
	"removeButton",
	"promoteButton",
	"contractorButton",
	"kickButton",
	"blockButton",
	"blockFromServerButton",
	"reportButton",
	"muteButton",
	"showProfileButton",
	"buyVehiclePermissionCheckbox",
	"sellVehiclePermissionCheckbox",
	"resetVehiclePermissionCheckbox",
	"buyPlaceablePermissionCheckbox",
	"sellPlaceablePermissionCheckbox",
	"hireAssistantPermissionCheckbox",
	"manageMissionsPermissionCheckbox",
	"tradeAnimalsPermissionCheckbox",
	"createFieldsPermissionCheckbox",
	"landscapingPermissionCheckbox"
}
InGameMenuMultiplayerUsersFrame.ELEMENT_NAME = {
	ROW_FARM_COLOR = "farmColor",
	ROW_PLAYER_NAME = "playerName",
	ROW_FARM_NAME = "farmName"
}
InGameMenuMultiplayerUsersFrame.TRANSFER_AMOUNT = {
	SMALL = 5000,
	MEDIUM = 50000,
	LARGE = 250000
}

function InGameMenuMultiplayerUsersFrame.new(subclass_mt, messageCenter, l10n, farmManager)
	local self = InGameMenuMultiplayerUsersFrame:superClass().new(nil, subclass_mt or InGameMenuMultiplayerUsersFrame_mt)

	self:registerControls(InGameMenuMultiplayerUsersFrame.CONTROLS)

	self.messageCenter = messageCenter
	self.l10n = l10n
	self.farmManager = farmManager
	self.currentUser = User.new()
	self.playerFarm = nil
	self.selectedUserId = nil
	self.selectedUserFarm = nil
	self.isNavigatingUsers = false
	self.users = {}
	self.listRowUser = {}
	self.permissionCheckboxes = {}
	self.checkboxPermissions = {}
	self.hasCustomMenuButtons = true
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.menuButtonInfo = {
		self.backButtonInfo
	}
	self.adminButtonInfo = {}
	self.inviteFriendsInfo = {}
	self.timeSinceLastRefresh = 0

	return self
end

function InGameMenuMultiplayerUsersFrame:copyAttributes(src)
	InGameMenuMultiplayerUsersFrame:superClass().copyAttributes(self, src)

	self.messageCenter = src.messageCenter
	self.l10n = src.l10n
	self.farmManager = src.farmManager
end

function InGameMenuMultiplayerUsersFrame:initialize()
	self:setupUserListFocusContext()

	self.unblockButtonInfo = {
		inputAction = InputAction.MENU_EXTRA_1,
		text = self.l10n:getText("button_blocklist"),
		callback = function ()
			self:onButtonUnBan()
		end
	}
	self.unblockRemoteButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = self.l10n:getText("button_blocklist"),
		callback = function ()
			self:onButtonUnBanRemote()
		end
	}
	self.adminButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.l10n:getText("button_adminLogin"),
		callback = function ()
			self:onButtonAdminLogin()
		end
	}
	self.inviteFriendsInfo = {
		inputAction = InputAction.MENU_EXTRA_2,
		text = self.l10n:getText("ui_inviteScreen"),
		callback = function ()
			self:onButtonInviteFriends()
		end
	}
	self.permissionCheckboxes = {
		[Farm.PERMISSION.BUY_VEHICLE] = self.buyVehiclePermissionCheckbox,
		[Farm.PERMISSION.SELL_VEHICLE] = self.sellVehiclePermissionCheckbox,
		[Farm.PERMISSION.RESET_VEHICLE] = self.resetVehiclePermissionCheckbox,
		[Farm.PERMISSION.BUY_PLACEABLE] = self.buyPlaceablePermissionCheckbox,
		[Farm.PERMISSION.SELL_PLACEABLE] = self.sellPlaceablePermissionCheckbox,
		[Farm.PERMISSION.HIRE_ASSISTANT] = self.hireAssistantPermissionCheckbox,
		[Farm.PERMISSION.MANAGE_CONTRACTS] = self.manageMissionsPermissionCheckbox,
		[Farm.PERMISSION.TRADE_ANIMALS] = self.tradeAnimalsPermissionCheckbox,
		[Farm.PERMISSION.CREATE_FIELDS] = self.createFieldsPermissionCheckbox,
		[Farm.PERMISSION.LANDSCAPING] = self.landscapingPermissionCheckbox
	}
	self.reportReasons = {
		[ReportUserReason.PLAYER_NAME + 1] = g_i18n:getText("ui_reportPlayer_reason_name"),
		[ReportUserReason.VOICE_CHAT + 1] = g_i18n:getText("ui_reportPlayer_reason_voice"),
		[ReportUserReason.TEXT_CHAT + 1] = g_i18n:getText("ui_reportPlayer_reason_text"),
		[ReportUserReason.BEHAVIOR + 1] = g_i18n:getText("ui_reportPlayer_reason_behavior"),
		[ReportUserReason.CHEATING + 1] = g_i18n:getText("ui_reportPlayer_reason_cheating")
	}
	self.checkboxPermissions = {}

	for k, v in pairs(self.permissionCheckboxes) do
		self.checkboxPermissions[v] = k
	end
end

function InGameMenuMultiplayerUsersFrame:onGuiSetupFinished()
	InGameMenuMultiplayerUsersFrame:superClass().onGuiSetupFinished(self)
	self.userList:setDataSource(self)
end

function InGameMenuMultiplayerUsersFrame:delete()
	InGameMenuMultiplayerUsersFrame:superClass().delete(self)
end

function InGameMenuMultiplayerUsersFrame:onFrameOpen()
	InGameMenuMultiplayerUsersFrame:superClass().onFrameOpen(self)
	self.messageCenter:subscribe(GetAdminAnswerEvent, self.onAdminLoginSuccess, self)
	self.messageCenter:subscribe(PlayerPermissionsEvent, self.onPermissionChanged, self)
	self.messageCenter:subscribe(ContractingStateEvent, self.onContractingStateChanged, self)
	self.messageCenter:subscribe(MessageType.FARM_PROPERTY_CHANGED, self.onFarmsChanged, self)
	self.messageCenter:subscribe(MessageType.FARM_DELETED, self.onFarmsChanged, self)
	self.messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.onPlayerFarmChanged, self)
	self.messageCenter:subscribe(MessageType.USER_ADDED, self.onUserAdded, self)
	self.messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
	self.messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
	self.messageCenter:subscribe(MessageType.PLAYER_NICKNAME_CHANGED, self.onFarmsChanged, self)
	self.messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onFarmsChanged, self)
	self:setCurrentUserId(g_currentMission.playerUserId)
	self:updateDisplay()
	FocusManager:setFocus(self.userList)
end

function InGameMenuMultiplayerUsersFrame:onFrameClose()
	InGameMenuMultiplayerUsersFrame:superClass().onFrameClose(self)
	self.messageCenter:unsubscribeAll(self)
end

function InGameMenuMultiplayerUsersFrame:setupUserListFocusContext()
	function self.userList.onFocusEnter()
		self.isNavigatingUsers = true

		self:updateMenuButtons()
	end

	function self.userList.onFocusLeave()
		self.isNavigatingUsers = false

		self:updateMenuButtons()
	end
end

function InGameMenuMultiplayerUsersFrame:setPlayerFarm(farm)
	self.playerFarm = farm
end

function InGameMenuMultiplayerUsersFrame:setCurrentUserId(userId)
	self.currentUserId = userId
	self.currentUser = g_currentMission.userManager:getUserByUserId(userId) or self.currentUser

	self:updateMenuButtons()
end

function InGameMenuMultiplayerUsersFrame:setUsers(users)
	local sortedUsers = self:getSortedUsers(users)
	self.users = sortedUsers
	self.shouldRebuildUserList = true

	self:updateMenuButtons()
end

local function alphabetSortUsers(user1, user2)
	return user1:getNickname() < user2:getNickname()
end

function InGameMenuMultiplayerUsersFrame:getSortedUsers(users)
	local sortedUsers = {}

	for _, user in pairs(users) do
		if not g_currentMission.connectedToDedicatedServer or user:getId() ~= g_currentMission:getServerUserId() then
			table.insert(sortedUsers, user)
		end
	end

	local function groupUsers(user1, user2)
		local farm1 = self.farmManager:getFarmByUserId(user1:getId())
		local farm2 = self.farmManager:getFarmByUserId(user2:getId())
		local farm1Id = farm1.farmId
		local farm2Id = farm2.farmId

		if self.playerFarm ~= nil and farm1Id == self.playerFarm.farmId then
			farm1Id = -math.huge
		end

		if self.playerFarm ~= nil and farm2Id == self.playerFarm.farmId then
			farm2Id = -math.huge
		end

		if farm1Id == FarmManager.SPECTATOR_FARM_ID then
			farm1Id = math.huge
		end

		if farm2Id == FarmManager.SPECTATOR_FARM_ID then
			farm2Id = math.huge
		end

		return farm1Id < farm2Id or alphabetSortUsers(user1, user2)
	end

	return sortedUsers
end

function InGameMenuMultiplayerUsersFrame:getSortedFarmList()
	local list = {}
	local farms = g_farmManager:getFarms()
	local mapping = g_farmManager.farmIdToFarm
	local spectatorFarm = nil

	table.insert(list, self.playerFarm)

	for _, farm in pairs(farms) do
		if not farm.isSpectator and farm ~= self.playerFarm then
			table.insert(list, farm)
		end

		if farm.isSpectator then
			spectatorFarm = farm
		end
	end

	if spectatorFarm:getNumActivePlayers() > 0 and spectatorFarm ~= self.playerFarm then
		table.insert(list, spectatorFarm)
	end

	return list
end

function InGameMenuMultiplayerUsersFrame:updateElements()
	local isFarmManager = self.playerFarm:isUserFarmManager(self.currentUserId)
	local hasHighPrivilege = isFarmManager or self.currentUser:getIsMasterUser()
	local isOwnFarmSelected = self.selectedUserFarm == self.playerFarm
	local isSpectatorSelected = self.selectedUserFarm.isSpectator
	local isSelfSelected = self.selectedUserId == self.currentUserId
	local isSelectedUserFarmManager = self.selectedUserId ~= nil and self.selectedUserFarm:isUserFarmManager(self.selectedUserId)
	local canManageSelectedFarm = isFarmManager and isOwnFarmSelected or self.currentUser:getIsMasterUser()
	local isOtherAdminSelected = false
	local selectionIsUser = self.selectedUserId ~= nil
	local user = nil

	if selectionIsUser then
		user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
		isOtherAdminSelected = self.selectedUserId ~= self.currentUserId and user:getIsMasterUser()
	end

	self.transferButton:setVisible(not selectionIsUser and not isOwnFarmSelected and isFarmManager and not isSpectatorSelected)
	self.removeButton:setVisible(selectionIsUser and canManageSelectedFarm and not isSelfSelected and not isSpectatorSelected and (not user:getIsMasterUser() or not not self.currentUser:getIsMasterUser()))
	self.promoteButton:setVisible(selectionIsUser and canManageSelectedFarm and not isSpectatorSelected and not isOtherAdminSelected)
	self.promoteButton:setText(self.l10n:getText(isSelectedUserFarmManager and "button_mp_dimiss" or "button_mp_promote"))

	local isContracting = self.selectedUserFarm:getIsContractingFor(self.playerFarm.farmId)

	self.contractorButton:setVisible(not selectionIsUser and hasHighPrivilege and not isOwnFarmSelected and not isSpectatorSelected and not self.playerFarm.isSpectator)
	self.contractorButton:setText(self.l10n:getText(isContracting and "button_mp_ungrant" or "button_mp_grant"))
	self.kickButton:setVisible(selectionIsUser and not isSelfSelected and self.currentUser:getIsMasterUser())
	self.blockFromServerButton:setVisible(selectionIsUser and not isSelfSelected and self.currentUser:getIsMasterUser() and not g_currentMission:getIsServer() and self.selectedUserId ~= g_currentMission:getServerUserId())
	self.blockButton:setVisible(selectionIsUser and not isSelfSelected)

	if selectionIsUser then
		self.blockButton:setText(self.l10n:getText(user:getIsBlocked() and "button_unblock" or "button_block"))
	end

	self.muteButton:setVisible(selectionIsUser and (not isSelfSelected or VoiceChatUtil.getHasRecordingDevice()) and not VoiceChatUtil.getIsVoiceRestricted())

	if selectionIsUser then
		self.muteButton:setText(self.l10n:getText(user:getVoiceMuted() and "button_unmute" or "button_mute"))
	end

	if selectionIsUser then
		self.showProfileButton:setVisible(Platform.hasNativeProfiles and getPlatformIdsAreCompatible(user:getPlatformId(), getPlatformId()))
		self.reportButton:setVisible(not isSelfSelected and (not Platform.hasNativeProfiles or not getPlatformIdsAreCompatible(user:getPlatformId(), getPlatformId())))
	else
		self.showProfileButton:setVisible(false)
		self.reportButton:setVisible(false)
	end

	if selectionIsUser then
		local canChangePermissions = not isSpectatorSelected and canManageSelectedFarm and not isSelectedUserFarmManager and not user:getIsMasterUser()
		local permissions = self.selectedUserFarm:getUserPermissions(self.selectedUserId)

		for permissionKey, checkbox in pairs(self.permissionCheckboxes) do
			checkbox:setIsChecked(permissions[permissionKey] or user:getIsMasterUser())
			checkbox:setDisabled(not canChangePermissions)
		end

		self.permissionsBox:setVisible(true)
	else
		self.permissionsBox:setVisible(false)
	end

	self.actionsBox:invalidateLayout()
	self.permissionsBox:invalidateLayout()
end

function InGameMenuMultiplayerUsersFrame:update(dt)
	InGameMenuMultiplayerUsersFrame:superClass().update(self, dt)

	if self.timeSinceLastRefresh > 1000 then
		self.shouldRebuildUserList = true
	end

	self.timeSinceLastRefresh = self.timeSinceLastRefresh + dt

	if self.shouldRebuildUserList then
		self.shouldRebuildUserList = false
		self.timeSinceLastRefresh = 0
		self.sortedFarms = self:getSortedFarmList()

		self.userList:reloadData()
	end
end

function InGameMenuMultiplayerUsersFrame:updateMenuButtons()
	self.menuButtonInfo = {
		self.backButtonInfo
	}

	if getNumOfBlockedUsers() > 0 then
		table.insert(self.menuButtonInfo, self.unblockButtonInfo)
	end

	if g_currentMission ~= nil then
		if self.currentUser:getIsMasterUser() then
			if g_currentMission.connectedToDedicatedServer then
				table.insert(self.menuButtonInfo, self.unblockRemoteButtonInfo)
			end
		elseif g_currentMission ~= nil and g_currentMission.connectedToDedicatedServer and not self.currentUser:getIsMasterUser() then
			table.insert(self.menuButtonInfo, self.adminButtonInfo)
		end

		if Platform.hasFriendInvitation and PlatformPrivilegeUtil.getCanInvitePlayer(g_currentMission) then
			table.insert(self.menuButtonInfo, self.inviteFriendsInfo)
		end
	end

	self:setMenuButtonInfoDirty()
end

function InGameMenuMultiplayerUsersFrame:updateBalance()
	local balance = self.playerFarm:getBalance()
	local balanceMoneyText = self.l10n:formatMoney(balance, 0, false) .. " " .. self.l10n:getCurrencySymbol(true)

	self:setCurrentBalance(balance, balanceMoneyText)
end

function InGameMenuMultiplayerUsersFrame:setCurrentBalance(balance, balanceString)
	local balanceProfile = InGameMenuMultiplayerUsersFrame.PROFILE.BALANCE_POSITIVE

	if math.floor(balance) <= -1 then
		balanceProfile = InGameMenuMultiplayerUsersFrame.PROFILE.BALANCE_NEGATIVE
	end

	if self.currentBalanceText.profile ~= balanceProfile then
		self.currentBalanceText:applyProfile(balanceProfile)
	end

	self.currentBalanceText:setText(balanceString)
end

function InGameMenuMultiplayerUsersFrame:updateDisplay()
	self.sortedFarms = self:getSortedFarmList()

	self.userList:reloadData()

	if self.selectedUserId ~= nil and self.selectedUserFarm ~= nil then
		self:updateElements()
		self:updateMenuButtons()
	end

	self:updateBalance()
end

function InGameMenuMultiplayerUsersFrame:onButtonKick()
	if self.selectedUserId ~= nil and self.selectedUserId ~= g_currentMission:getServerUserId() then
		local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
		local text = string.format(self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_KICK_CONFIRM), user:getNickname())

		g_gui:showYesNoDialog({
			text = text,
			title = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_KICK_TITLE),
			callback = self.onYesNoKick,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.INFO_CANNOT_KICK_SERVER)
		})
	end
end

function InGameMenuMultiplayerUsersFrame:onYesNoKick(yes)
	if yes then
		g_client:getServerConnection():sendEvent(KickBanEvent.new(true, self.selectedUserId))
	end
end

function InGameMenuMultiplayerUsersFrame:onButtonUnBan()
	g_gui:showUnblockDialog({
		useLocal = true,
		callback = self.updateMenuButtons,
		target = self
	})
end

function InGameMenuMultiplayerUsersFrame:onButtonUnBanRemote()
	g_gui:showUnblockDialog({
		useLocal = false,
		callback = self.updateMenuButtons,
		target = self
	})
end

function InGameMenuMultiplayerUsersFrame:onButtonShowProfile()
	if self.selectedUserId ~= nil then
		local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
		local nickname = user:getPlatformUserId()

		if nickname == "" then
			nickname = user:getNickname()
		end

		showUserProfile(nickname)
	end
end

function InGameMenuMultiplayerUsersFrame:onButtonInviteFriends()
	if Platform.hasFriendInvitation then
		if g_currentMission ~= nil then
			openMpFriendInvitation(#g_currentMission.userManager:getUsers(), g_currentMission.missionDynamicInfo.capacity)
		else
			openMpFriendInvitation(1, 6)
		end
	end
end

function InGameMenuMultiplayerUsersFrame:onButtonAdminLogin()
	g_gui:showPasswordDialog({
		defaultPassword = "",
		text = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.PROMPT_ADMIN_PASSWORD),
		callback = self.onAdminPassword,
		target = self
	})
end

function InGameMenuMultiplayerUsersFrame:onClickPermission(checkboxElement, isActive)
	local permission = self.checkboxPermissions[checkboxElement]

	self.selectedUserFarm:setUserPermission(self.selectedUserId, permission, isActive)
end

function InGameMenuMultiplayerUsersFrame:onClickTransferButton()
	g_gui:showTransferMoneyDialog({
		farm = self.selectedUserFarm,
		callback = self.transferMoney,
		target = self
	})
end

function InGameMenuMultiplayerUsersFrame:transferMoney(amount)
	if amount > 0 then
		self.farmManager:transferMoney(self.selectedUserFarm, amount)
		self:updateBalance()
	end
end

function InGameMenuMultiplayerUsersFrame:onClickRemoveFromFarm()
	local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
	local text = string.format(self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_REMOVE_CONFIRM), user:getNickname())

	g_gui:showYesNoDialog({
		text = text,
		title = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_REMOVE_TITLE),
		callback = self.onYesNoRemoveFromFarm,
		target = self
	})
end

function InGameMenuMultiplayerUsersFrame:onYesNoRemoveFromFarm(yes)
	if yes then
		self.farmManager:removeUserFromFarm(self.selectedUserId)
	end
end

function InGameMenuMultiplayerUsersFrame:onClickPromote()
	if not self.selectedUserFarm:isUserFarmManager(self.selectedUserId) then
		local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
		local text = string.format(self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_PROMOTE_CONFIRM), user:getNickname())

		g_gui:showYesNoDialog({
			text = text,
			title = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_PROMOTE_TITLE),
			callback = self.onYesNoPromoteToFarmManager,
			target = self
		})
	else
		self.selectedUserFarm:demoteUser(self.selectedUserId)
	end
end

function InGameMenuMultiplayerUsersFrame:onYesNoPromoteToFarmManager(yes)
	if yes then
		self.selectedUserFarm:promoteUser(self.selectedUserId)
	end
end

function InGameMenuMultiplayerUsersFrame:onClickContractor()
	local isContracting = self.selectedUserFarm:getIsContractingFor(self.playerFarm.farmId)
	local confirmTextTemplateSymbol = nil

	if isContracting then
		confirmTextTemplateSymbol = InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_DENY_CONTRACTOR_CONFIRM
	else
		confirmTextTemplateSymbol = InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_GRANT_CONTRACTOR_CONFIRM
	end

	local text = string.format(self.l10n:getText(confirmTextTemplateSymbol), self.selectedUserFarm.name)

	g_gui:showYesNoDialog({
		text = text,
		title = self.l10n:getText(InGameMenuMultiplayerUsersFrame.L10N_SYMBOL.DIALOG_CONTRACTOR_STATE_TITLE),
		callback = self.onYesNoToggleContractorState,
		target = self
	})
end

function InGameMenuMultiplayerUsersFrame:onYesNoToggleContractorState(yes)
	if yes then
		local isContracting = self.selectedUserFarm:getIsContractingFor(self.playerFarm.farmId)

		self.selectedUserFarm:setIsContractingFor(self.playerFarm.farmId, not isContracting, false)
	end
end

function InGameMenuMultiplayerUsersFrame:onFarmsChanged(farmId)
	self:updateDisplay()
end

function InGameMenuMultiplayerUsersFrame:onPlayerFarmChanged(player)
	self:updateDisplay()
end

function InGameMenuMultiplayerUsersFrame:onPermissionChanged()
	self:updateDisplay()
end

function InGameMenuMultiplayerUsersFrame:onMasterUserAdded()
	self:updateDisplay()
end

function InGameMenuMultiplayerUsersFrame:onUserAdded()
	self:updateDisplay()
end

function InGameMenuMultiplayerUsersFrame:onUserRemoved()
	self:updateDisplay()
end

function InGameMenuMultiplayerUsersFrame:onContractingStateChanged()
	self:updateElements()
end

function InGameMenuMultiplayerUsersFrame:onAdminPassword(password, yes)
	if yes then
		g_client:getServerConnection():sendEvent(GetAdminEvent.new(password))
	end
end

function InGameMenuMultiplayerUsersFrame:onAdminLoginSuccess()
	self:updateDisplay()

	if self.playerFarm ~= nil and self.playerFarm.farmId ~= FarmManager.SPECTATOR_FARM_ID then
		self.playerFarm:promoteUser(self.currentUserId)
	end
end

function InGameMenuMultiplayerUsersFrame:onButtonBlock()
	local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)

	if user:getIsBlocked() then
		user:unblock()
		self:updateDisplay()
	elseif Platform.hasNativeProfiles and getPlatformIdsAreCompatible(user:getPlatformId(), getPlatformId()) then
		user:block()
	else
		g_gui:showYesNoDialog({
			title = g_i18n:getText("ui_doYouWantToBlockThisServer_title"),
			text = string.format(g_i18n:getText("ui_blockPlayerConfirm"), user:getNickname()),
			callback = function (yes)
				if yes then
					g_currentMission:banUser(user)
					self:updateDisplay()
				end
			end
		})
	end
end

function InGameMenuMultiplayerUsersFrame:onButtonBlockFromServer()
	local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)
	local text = string.format(self.l10n:getText("ui_banConfirm"), user:getNickname())

	g_gui:showYesNoDialog({
		text = text,
		title = self.l10n:getText("ui_banTitle"),
		callback = function (yes)
			g_client:getServerConnection():sendEvent(KickBanEvent.new(false, self.selectedUserId))
		end
	})
end

function InGameMenuMultiplayerUsersFrame:onButtonReport()
	local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)

	g_gui:showOptionDialog({
		title = g_i18n:getText("ui_reportPlayer_title"),
		text = string.format(g_i18n:getText("ui_reportPlayer_confirm"), user:getNickname()),
		options = self.reportReasons,
		callback = function (item)
			if item > 0 then
				user:report(item - 1)
			end
		end
	})
end

function InGameMenuMultiplayerUsersFrame:onButtonMute()
	local user = g_currentMission.userManager:getUserByUserId(self.selectedUserId)

	if user:getVoiceMuted() then
		user:setVoiceMuted(false)
	else
		user:setVoiceMuted(true)
	end

	self:updateDisplay()
end

function InGameMenuMultiplayerUsersFrame:getNumberOfSections()
	return #self.sortedFarms
end

function InGameMenuMultiplayerUsersFrame:getCellTypeForItemInSection(list, section, index)
	if index == 1 then
		return "farm"
	else
		return "user"
	end
end

function InGameMenuMultiplayerUsersFrame:getNumberOfItemsInSection(list, section)
	local farm = self.sortedFarms[section]

	return #farm:getActiveUsers() + 1
end

function InGameMenuMultiplayerUsersFrame:populateCellForItemInSection(list, section, index, cell)
	local farm = self.sortedFarms[section]

	if index == 1 then
		if farm.farmId == FarmManager.SPECTATOR_FARM_ID then
			cell:getAttribute("title"):setText(self.l10n:getText("ui_noFarm"))
			cell:getAttribute("farmBalance"):setVisible(false)
		else
			cell:getAttribute("title"):setText(farm.name)
			cell:getAttribute("farmBalance"):setVisible(true)
			cell:getAttribute("farmBalance"):setValue(farm:getBalance())
		end

		cell:getAttribute("dot"):setImageColor(nil, unpack(farm:getColor()))
	else
		local userInfos = farm:getActiveUsers()
		local userInfo = userInfos[index - 1]
		local user = g_currentMission.userManager:getUserByUserId(userInfo.userId)

		if user == nil then
			return
		end

		cell:getAttribute("playerName"):setText(user:getNickname())
		cell:getAttribute("platform"):setPlatformId(user:getPlatformId())

		if not g_currentMission.connectedToDedicatedServer or user:getId() ~= g_currentMission:getServerUserId() then
			local isFarmManager = farm:isUserFarmManager(user:getId())
			local noMic = voiceChatGetConnectionStatus(user:getUniqueUserId()) == VoiceChatConnectionStatus.UNAVAILABLE

			cell:getAttribute("noMicrophone"):setVisible(noMic)
			cell:getAttribute("muted"):setVisible(not noMic and user:getVoiceMuted())
			cell:getAttribute("farmManager"):setVisible(farm:isUserFarmManager(user:getId()))
			cell:getAttribute("admin"):setVisible(user:getIsMasterUser())
			cell:getAttribute("admin").parent:invalidateLayout()
		end
	end
end

function InGameMenuMultiplayerUsersFrame:onListSelectionChanged(list, section, index)
	local farm = self.sortedFarms[section]

	if index == 1 then
		self.selectedUserId = nil
		self.selectedUserFarm = farm
	else
		local user = farm:getActiveUsers()[index - 1]

		if user ~= nil then
			self.selectedUserId = user.userId
			self.selectedUserFarm = farm
		end
	end

	self:updateMenuButtons()
	self:updateElements()
end

InGameMenuMultiplayerUsersFrame.L10N_SYMBOL = {
	DIALOG_KICK_TITLE = "ui_kickTitle",
	DIALOG_KICK_CONFIRM = "ui_kickConfirm",
	PROMPT_ADMIN_PASSWORD = "ui_enterAdminPassword",
	DIALOG_DENY_CONTRACTOR_CONFIRM = "ui_contractorUngrantConfirm",
	DIALOG_REMOVE_TITLE = "ui_removeFromFarmTitle",
	INFO_CANNOT_BAN_SERVER = "ui_serverCannotBeBanned",
	DIALOG_PROMOTE_TITLE = "ui_promoteToFarmManagerTitle",
	DIALOG_CONTRACTOR_STATE_TITLE = "ui_contractorStateChangeTitle",
	BUTTON_CONTRACT = "button_mp_grant",
	DIALOG_PROMOTE_CONFIRM = "ui_promoteToFarmManagerConfirm",
	BUTTON_UNCONTRACT = "button_mp_ungrant",
	BUTTON_UNBAN = "button_unban",
	BUTTON_ADMIN = "button_adminLogin",
	BUTTON_INVITE_FRIENDS = "ui_inviteScreen",
	DIALOG_REMOVE_CONFIRM = "ui_removeFromFarmConfirm",
	MONEY_BUTTON_TEMPLATE = "button_mp_transferMoney",
	INFO_CANNOT_KICK_SERVER = "ui_serverCannotBeKicked",
	DIALOG_GRANT_CONTRACTOR_CONFIRM = "ui_contractorGrantConfirm"
}
InGameMenuMultiplayerUsersFrame.PROFILE = {
	BALANCE_NEGATIVE = "shopMoneyNeg",
	BALANCE_POSITIVE = "shopMoney",
	CURRENT_PLAYER_TEXT = "ingameMenuMPUsersListRowTextCurrentPlayer"
}
