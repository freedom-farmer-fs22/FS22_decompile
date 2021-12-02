InGameMenuMultiplayerFarmsFrame = {}
local InGameMenuMultiplayerFarmsFrame_mt = Class(InGameMenuMultiplayerFarmsFrame, TabbedMenuFrameElement)
InGameMenuMultiplayerFarmsFrame.CONTROLS = {
	"playerNameTemplate",
	NEW_FARM_ITEM = "newFarmItem",
	FARM_LIST = "farmList",
	NO_FARMS_BOX = "noFarmsBox"
}

function InGameMenuMultiplayerFarmsFrame.new(subclass_mt, messageCenter, l10n, farmManager)
	local self = InGameMenuMultiplayerFarmsFrame:superClass().new(nil, subclass_mt or InGameMenuMultiplayerFarmsFrame_mt)

	self:registerControls(InGameMenuMultiplayerFarmsFrame.CONTROLS)

	self.messageCenter = messageCenter
	self.l10n = l10n
	self.farmManager = farmManager
	self.currentUser = User.new()
	self.users = {}
	self.player = nil
	self.playerFarm = nil
	self.hasAskedForPassword = false
	self.timeSinceLastMoneyUpdate = 0
	self.elementFarmIdMap = {}
	self.farmIdBalanceMap = {}
	self.farmIdPlayerCountMap = {}
	self.farmIdPlayerNameLayoutMap = {}
	self.farmIdPlayerNameTemplateMap = {}
	self.newFarmListIndex = 0
	self.hasCustomMenuButtons = true
	self.menuButtonInfo = {}

	return self
end

function InGameMenuMultiplayerFarmsFrame:copyAttributes(src)
	InGameMenuMultiplayerFarmsFrame:superClass().copyAttributes(self, src)

	self.messageCenter = src.messageCenter
	self.l10n = src.l10n
	self.farmManager = src.farmManager
end

function InGameMenuMultiplayerFarmsFrame:initialize()
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.joinMenuButton = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL.BUTTON_JOIN_FARM),
		callback = function ()
			self:joinFarm(self.selectedFarmId)
		end
	}
	self.leaveMenuButton = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL.BUTTON_LEAVE_FARM),
		callback = function ()
			self:leaveFarm()
		end
	}
	self.editMenuButton = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.l10n:getText(InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL.BUTTON_EDIT_FARM),
		callback = function ()
			self:editFarm(self.selectedFarmId)
		end
	}
	self.createMenuButton = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL.BUTTON_CREATE_FARM),
		callback = function ()
			self:createFarm()
		end
	}
	self.deleteMenuButton = {
		inputAction = InputAction.MENU_CANCEL,
		text = self.l10n:getText(InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL.BUTTON_DELETE_FARM),
		callback = function ()
			self:deleteFarm(self.selectedFarmId)
		end
	}

	self.playerNameTemplate:unlinkElement()
end

function InGameMenuMultiplayerFarmsFrame:delete()
	for _, template in pairs(self.farmIdPlayerNameTemplateMap) do
		template:delete()
	end

	self.playerNameTemplate:delete()
	InGameMenuMultiplayerFarmsFrame:superClass().delete(self)
end

function InGameMenuMultiplayerFarmsFrame:onGuiSetupFinished()
	InGameMenuMultiplayerFarmsFrame:superClass().onGuiSetupFinished(self)
	self.farmList:setDataSource(self)
	self.farmList:setDelegate(self)
end

function InGameMenuMultiplayerFarmsFrame:onFrameOpen()
	InGameMenuMultiplayerFarmsFrame:superClass().onFrameOpen(self)
	self.messageCenter:subscribe(MessageType.FARM_CREATED, self.onFarmCreated, self)
	self.messageCenter:subscribe(MessageType.FARM_PROPERTY_CHANGED, self.onFarmsChanged, self)
	self.messageCenter:subscribe(MessageType.FARM_DELETED, self.onFarmsChanged, self)
	self.messageCenter:subscribe(MessageType.PLAYER_NICKNAME_CHANGED, self.onFarmsChanged, self)
	self.messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.onPlayerFarmChanged, self)
	self.messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onFarmMoneyChanged, self)
	self.messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
	self.messageCenter:subscribe(PlayerSetFarmAnswerEvent, self.onPlayerSetFarmAnswer, self)
	self.messageCenter:subscribe(PlayerPermissionsEvent, self.onPermissionChanged, self)

	self.selectedFarmId = nil

	self.farmList:reloadData()

	local listIndex = 1

	if self.playerFarm ~= nil then
		listIndex = self:getListFarmIndex(self.playerFarm.farmId)
	end

	self.farmList:setSelectedIndex(listIndex, true)
	FocusManager:setFocus(self.farmList)
	self:updateMenuButtons()
end

function InGameMenuMultiplayerFarmsFrame:onFrameClose()
	self.messageCenter:unsubscribeAll(self)
	InGameMenuMultiplayerFarmsFrame:superClass().onFrameClose(self)
end

function InGameMenuMultiplayerFarmsFrame:reset()
	InGameMenuMultiplayerFarmsFrame:superClass().reset(self)

	self.currentUser = User.new()
	self.users = {}
	self.player = nil
	self.playerFarm = nil
	self.hasAskedForPassword = false
	self.elementFarmIdMap = {}
	self.farmIdBalanceMap = {}
	self.farmIdPlayerCountMap = {}
	self.farmIdPlayerNameLayoutMap = {}
	self.farmIdPlayerNameTemplateMap = {}
	self.newFarmListIndex = 0
end

function InGameMenuMultiplayerFarmsFrame:setCurrentUserId(currentUserId)
	self.currentUser = g_currentMission.userManager:getUserByUserId(currentUserId) or self.currentUser
	self.currentUserId = currentUserId
end

function InGameMenuMultiplayerFarmsFrame:setUsers(users)
	self.users = users
end

function InGameMenuMultiplayerFarmsFrame:setPlayer(player)
	self.player = player
end

function InGameMenuMultiplayerFarmsFrame:setPlayerFarm(farm)
	self.playerFarm = farm
end

function InGameMenuMultiplayerFarmsFrame:getListFarmIndex(farmId)
	local index = 1

	if farmId ~= FarmManager.SPECTATOR_FARM_ID then
		local farms = self.farmManager:getFarms()

		for i, farm in ipairs(farms) do
			if farm.farmId == farmId then
				return i - 1
			end
		end
	end

	return index
end

function InGameMenuMultiplayerFarmsFrame:setFarmBalance(farmId, balance)
	if balance == nil then
		local farm = self.farmManager:getFarmById(farmId)
		balance = farm:getBalance()
	end

	if self.farmIdBalanceMap[farmId] ~= nil then
		self.farmIdBalanceMap[farmId]:setValue(balance)
	end
end

function InGameMenuMultiplayerFarmsFrame:updateFarmPlayers(farmId)
	local playerNameLayout = self.farmIdPlayerNameLayoutMap[farmId]

	for _, element in pairs(playerNameLayout.elements) do
		element:delete()
	end

	local farm = self.farmManager:getFarmById(farmId)
	local farmPlayers = farm:getActiveUsers()
	local playerLabel = self.l10n:getText(InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL.PLAYER_COUNT)
	local playerCountText = string.format("%s: %d", playerLabel, #farmPlayers)
	local playerCountElement = self.farmIdPlayerCountMap[farmId]

	playerCountElement:setText(playerCountText)

	local nameTemplate = self.farmIdPlayerNameTemplateMap[farmId]
	local usedHeight = 0

	for _, farmPlayer in ipairs(farmPlayers) do
		local playerName = ""

		for _, user in pairs(self.users) do
			if farmPlayer.userId == user:getId() then
				playerName = user:getNickname()

				break
			end
		end

		local playerTextElement = nameTemplate:clone(playerNameLayout)

		playerTextElement:setText(playerName)

		usedHeight = usedHeight + playerTextElement.size[2]
	end

	playerNameLayout.numFlows = usedHeight <= playerNameLayout.size[2] and 1 or 2

	playerNameLayout:invalidateLayout(true)
end

function InGameMenuMultiplayerFarmsFrame:updateMenuButtons()
	self.menuButtonInfo = {}

	if self.selectedFarmId ~= nil then
		if self.selectedFarmId == self.playerFarm.farmId then
			table.insert(self.menuButtonInfo, self.leaveMenuButton)
		else
			table.insert(self.menuButtonInfo, self.joinMenuButton)
		end

		table.insert(self.menuButtonInfo, self.backButtonInfo)

		if self.currentUser:getIsMasterUser() then
			table.insert(self.menuButtonInfo, self.editMenuButton)
			table.insert(self.menuButtonInfo, self.deleteMenuButton)
		end
	elseif self.currentUser:getIsMasterUser() then
		table.insert(self.menuButtonInfo, self.createMenuButton)
		table.insert(self.menuButtonInfo, self.backButtonInfo)
	else
		table.insert(self.menuButtonInfo, self.backButtonInfo)
	end

	self:setMenuButtonInfoDirty()
end

function InGameMenuMultiplayerFarmsFrame:joinFarm(farmId)
	local currentFarmId = self.playerFarm.farmId

	if self.playerFarm ~= nil and farmId ~= currentFarmId then
		if currentFarmId ~= FarmManager.SPECTATOR_FARM_ID then
			g_gui:showYesNoDialog({
				text = string.format(self.l10n:getText(InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL.LEAVE_FARM_CONFIRM), self.playerFarm.name),
				title = self.l10n:getText(InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL.BUTTON_LEAVE_FARM),
				callback = self.doJoinFarm,
				target = self
			})
		else
			self:doJoinFarm(true, farmId)
		end
	end
end

function InGameMenuMultiplayerFarmsFrame:doJoinFarm(yesNo)
	if yesNo then
		local farm = self.farmManager:getFarmById(self.selectedFarmId)

		g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(self.player, self.selectedFarmId, farm.password))
	end
end

function InGameMenuMultiplayerFarmsFrame:leaveFarm()
	g_gui:showYesNoDialog({
		text = string.format(self.l10n:getText(InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL.LEAVE_FARM_CONFIRM), self.playerFarm.name),
		title = self.l10n:getText(InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL.BUTTON_LEAVE_FARM),
		callback = self.doLeaveFarm,
		target = self
	})
end

function InGameMenuMultiplayerFarmsFrame:doLeaveFarm(yesNo)
	if yesNo then
		g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(self.player, FarmManager.SPECTATOR_FARM_ID))
	end
end

function InGameMenuMultiplayerFarmsFrame:deleteFarm(farmId)
	local farm = self.farmManager:getFarmById(farmId)
	local canDestroy, messageCannotDestroy = farm:canBeDestroyed()

	if canDestroy then
		g_gui:showYesNoDialog({
			text = self.l10n:getText(InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL.DELETE_FARM_CONFIRM),
			title = self.l10n:getText(InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL.BUTTON_DELETE_FARM),
			callback = self.onDeleteFarmYesNo,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = self.l10n:getText(messageCannotDestroy)
		})
	end
end

function InGameMenuMultiplayerFarmsFrame:editFarm(farmId)
	g_gui:showEditFarmDialog({
		farmId = farmId
	})
end

function InGameMenuMultiplayerFarmsFrame:createFarm()
	g_gui:showEditFarmDialog({})
end

function InGameMenuMultiplayerFarmsFrame:onPlayerSetFarmAnswer(answerState, farmId, password)
	if answerState == PlayerSetFarmAnswerEvent.STATE.OK then
		local joinedFarm = self.farmManager:getFarmById(farmId)
		joinedFarm.password = password
		self.hasAskedForPassword = false

		self.farmList:setSelectedIndex(self:getListFarmIndex(farmId))
	elseif answerState == PlayerSetFarmAnswerEvent.STATE.PASSWORD_REQUIRED then
		if not self.hasAskedForPassword then
			self.hasAskedForPassword = true

			g_gui:showPasswordDialog({
				defaultPassword = "",
				callback = self.onFarmPasswordEntered,
				target = self,
				startText = self.l10n:getText(InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL.BUTTON_JOIN_FARM),
				args = farmId
			})
		else
			g_gui:showInfoDialog({
				text = self.l10n:getText(InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL.WRONG_PASSWORD)
			})

			self.hasAskedForPassword = false
		end
	end
end

function InGameMenuMultiplayerFarmsFrame:onFarmPasswordEntered(password, hasConfirmed, farmId)
	if hasConfirmed then
		g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(self.player, farmId, password))
	else
		self.hasAskedForPassword = false
	end
end

function InGameMenuMultiplayerFarmsFrame:onPermissionChanged(userId)
	if userId == self.currentUserId then
		self:updateMenuButtons()
	end
end

function InGameMenuMultiplayerFarmsFrame:onFarmCreated(newFarmId)
	self.farmList:reloadData()

	if self.currentUser:getIsMasterUser() then
		local newIndex = self:getListFarmIndex(newFarmId)

		self.farmList:setSelectedIndex(newIndex, true)
	end
end

function InGameMenuMultiplayerFarmsFrame:onFarmsChanged(farmId)
	self.farmList:reloadData()
end

function InGameMenuMultiplayerFarmsFrame:onPlayerFarmChanged(player)
	self.farmList:reloadData()
	self:updateMenuButtons()
end

function InGameMenuMultiplayerFarmsFrame:onFarmMoneyChanged(farmId, balance)
	if self.farmIdBalanceMap[farmId] ~= nil then
		self.farmIdBalanceMap[farmId]:setValue(balance)
	end
end

function InGameMenuMultiplayerFarmsFrame:onMasterUserAdded(user)
	self.farmList:reloadData()
	self:updateMenuButtons()
end

function InGameMenuMultiplayerFarmsFrame:onClickLeft()
	self.farmList:scrollTo(self.farmList.firstVisibleItem - 1)
end

function InGameMenuMultiplayerFarmsFrame:onClickRight()
	self.farmList:scrollTo(self.farmList.firstVisibleItem + 1)
end

function InGameMenuMultiplayerFarmsFrame:onDoubleClickFarm(list, section, index)
	if index == self.newFarmListIndex then
		self:createFarm()
	else
		local farm = self.farmManager:getFarms()[index + 1]
		self.selectedFarmId = farm.farmId

		self:joinFarm(self.selectedFarmId)
	end
end

function InGameMenuMultiplayerFarmsFrame:onListSelectionChanged(list, section, index)
	if index == self.newFarmListIndex then
		self.selectedFarmId = nil
	else
		local farm = self.farmManager:getFarms()[index + 1]
		self.selectedFarmId = farm.farmId
	end

	self:updateMenuButtons()
end

function InGameMenuMultiplayerFarmsFrame:onDeleteFarmYesNo(yes)
	if yes then
		local farm = self.farmManager:getFarmById(self.selectedFarmId)

		if farm:canBeDestroyed() then
			g_client:getServerConnection():sendEvent(FarmDestroyEvent.new(self.selectedFarmId))
		end
	end
end

function InGameMenuMultiplayerFarmsFrame:getNumberOfItemsInSection(list, section)
	local numFarms = #self.farmManager:getFarms()

	if numFarms < FarmManager.MAX_NUM_FARMS + 1 and self.currentUser:getIsMasterUser() then
		self.newFarmListIndex = numFarms

		return numFarms
	else
		self.newFarmListIndex = nil

		return numFarms - 1
	end
end

function InGameMenuMultiplayerFarmsFrame:populateCellForItemInSection(list, section, index, cell)
	local farms = self.farmManager:getFarms()
	index = index + 1
	local farm = farms[index]

	cell:getAttribute("existingFarm"):setVisible(farm ~= nil)
	cell:getAttribute("newFarm"):setVisible(farm == nil)

	if farm ~= nil then
		local farmId = self.elementFarmIdMap[cell]

		if farmId ~= nil then
			self.farmIdBalanceMap[farmId] = nil
		end

		cell:getAttribute("farmName"):setText(farm.name)
		cell:getAttribute("farmIcon"):setImageUVs(nil, unpack(GuiUtils.getUVs(farm:getIconUVs())))

		self.farmIdBalanceMap[farm.farmId] = cell:getAttribute("farmBalance")

		cell:getAttribute("farmBalance"):setValue(farm:getBalance())

		local list = cell:getAttribute("playerNameLayout")

		for i = 1, #list.elements do
			list.elements[1]:delete()
		end

		for _, player in ipairs(farm:getActiveUsers()) do
			local userId = player.userId
			local user = g_currentMission.userManager:getUserByUserId(userId)

			if user ~= nil then
				local nickname = user:getNickname()
				local item = self.playerNameTemplate:clone(list)

				item:setText(nickname)
			end
		end

		self.elementFarmIdMap[cell] = farm.farmId
	end
end

InGameMenuMultiplayerFarmsFrame.L10N_SYMBOL = {
	PLAYER_COUNT = "ui_players",
	LEAVE_FARM_CONFIRM = "ui_farmLeaveConfirmation",
	BUTTON_DELETE_FARM = "button_mp_deleteFarm",
	DELETE_FARM_CONFIRM = "ui_farmDeleteConfirmation",
	BUTTON_JOIN_FARM = "button_mp_joinFarm",
	BUTTON_CREATE_FARM = "button_mp_createFarm",
	BUTTON_LEAVE_FARM = "button_mp_leaveFarm",
	BUTTON_EDIT_FARM = "button_mp_editFarm",
	WRONG_PASSWORD = "ui_wrongPassword"
}
