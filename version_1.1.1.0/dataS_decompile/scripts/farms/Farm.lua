Farm = {
	MIN_LOAN = 500000,
	MAX_LOAN = 3000000,
	EQUITY_LOAN_RATIO = 0.8,
	LOAN_INTEREST_RATE = 100,
	PERMISSION = {
		MANAGE_CONTRACTS = "manageContracts",
		SELL_PLACEABLE = "sellPlaceable",
		CREATE_FIELDS = "createFields",
		BUY_VEHICLE = "buyVehicle",
		BUY_PLACEABLE = "buyPlaceable",
		SELL_VEHICLE = "sellVehicle",
		HIRE_ASSISTANT = "hireAssistant",
		RESET_VEHICLE = "resetVehicle",
		TRANSFER_MONEY = "transferMoney",
		MANAGE_CONTRACTING = "manageContracting",
		TRADE_ANIMALS = "tradeAnimals",
		LANDSCAPING = "landscaping",
		UPDATE_FARM = "updateFarm",
		MANAGE_RIGHTS = "manageRights"
	}
}
Farm.PERMISSIONS = {
	Farm.PERMISSION.BUY_VEHICLE,
	Farm.PERMISSION.SELL_VEHICLE,
	Farm.PERMISSION.BUY_PLACEABLE,
	Farm.PERMISSION.SELL_PLACEABLE,
	Farm.PERMISSION.MANAGE_CONTRACTS,
	Farm.PERMISSION.TRADE_ANIMALS,
	Farm.PERMISSION.CREATE_FIELDS,
	Farm.PERMISSION.LANDSCAPING,
	Farm.PERMISSION.HIRE_ASSISTANT,
	Farm.PERMISSION.RESET_VEHICLE,
	Farm.PERMISSION.MANAGE_RIGHTS,
	Farm.PERMISSION.TRANSFER_MONEY,
	Farm.PERMISSION.MANAGE_CONTRACTS,
	Farm.PERMISSION.UPDATE_FARM,
	Farm.PERMISSION.MANAGE_CONTRACTING
}
Farm.NO_PERMISSIONS = {}
Farm.DEFAULT_PERMISSIONS = {}
Farm.COLORS = {
	{
		1,
		0.4287,
		0,
		1
	},
	{
		1,
		0.1221,
		0.0003,
		1
	},
	{
		0.7084,
		0.0203,
		0.2086,
		1
	},
	{
		0.2541,
		0.0065,
		0.5089,
		1
	},
	{
		0.1921,
		0.0976,
		0.8632,
		1
	},
	{
		0.1248,
		0.2541,
		1,
		1
	},
	{
		0.1248,
		0.9216,
		1,
		1
	},
	{
		0.2307,
		1,
		0.2232,
		1
	}
}
Farm.COLOR_SEND_NUM_BITS = 4
Farm.ICON_UVS = {
	{
		330,
		0,
		256,
		256
	},
	{
		660,
		0,
		256,
		256
	},
	{
		330,
		310,
		256,
		256
	},
	{
		0,
		310,
		256,
		256
	},
	{
		660,
		310,
		256,
		256
	},
	{
		0,
		620,
		256,
		256
	},
	{
		330,
		620,
		256,
		256
	},
	{
		660,
		620,
		256,
		256
	}
}
Farm.COLOR_SPECTATOR = {
	0,
	0,
	0,
	0
}
Farm.COLOR_SINGLEPLAYER = {
	0.0227,
	0.5346,
	0.8519,
	1
}
local Farm_mt = Class(Farm, Object)

InitStaticObjectClass(Farm, "Farm", ObjectIds.FARM)

function Farm.new(isServer, isClient, customMt, spectator)
	local self = Object.new(isServer, isClient, customMt or Farm_mt)
	self.farmId = nil
	self.name = ""
	self.color = 0
	self.isSpectator = spectator or false

	self:setInitialEconomy()

	self.players = {}
	self.uniqueUserIdToPlayer = {}
	self.userIdToPlayer = {}
	self.activeUsers = {}
	self.contractingFor = {}
	self.handTools = {}
	self.stats = FarmStats.new()

	g_messageCenter:subscribe(MessageType.FARM_PROPERTY_CHANGED, self.farmPropertyChanged, self)

	if self.isServer then
		g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)
	end

	self.farmMoneyDirtyFlag = self:getNextDirtyFlag()
	self.lastMoneySent = self.money

	return self
end

function Farm:setInitialEconomy()
	local difficulty = g_currentMission.missionInfo.difficulty
	self.loanMax = 0

	self:updateMaxLoan()

	self.loanAnnualInterestRate = 100 + 100 * (difficulty - 1)

	if self.isSpectator then
		self.money = 0
		self.loan = 0
	else
		self.money = g_currentMission.missionInfo.initialMoney
		self.loan = g_currentMission.missionInfo.initialLoan

		if g_isPresentationVersion then
			self.money = 1000000
		end

		if difficulty == 1 and g_addTestCommands then
			self.money = 100000000

			Logging.warning("Money Cheat active")
		end
	end
end

function Farm:delete()
	g_messageCenter:unsubscribeAll(self)
	Farm:superClass().delete(self)
end

function Farm:loadFromXMLFile(xmlFile, key)
	self.farmId = xmlFile:getInt(key .. "#farmId")
	self.name = xmlFile:getString(key .. "#name")
	self.color = xmlFile:getInt(key .. "#color")
	self.password = xmlFile:getString(key .. "#password")
	self.loan = xmlFile:getFloat(key .. "#loan")
	self.money = xmlFile:getFloat(key .. "#money")
	self.loanAnnualInterestRate = xmlFile:getFloat(key .. "#loanAnnualInterestRate", 100)

	xmlFile:iterate(key .. ".players.player", function (_, playerKey)
		local player = {
			uniqueUserId = xmlFile:getString(playerKey .. "#uniqueUserId"),
			isFarmManager = xmlFile:getBool(playerKey .. "#farmManager", false),
			lastNickname = xmlFile:getString(playerKey .. "#lastNickname", ""),
			permissions = {}
		}

		for _, permission in ipairs(Farm.PERMISSIONS) do
			player.permissions[permission] = xmlFile:getBool(playerKey .. "#" .. permission, false) or player.isFarmManager
		end

		table.insert(self.players, player)

		self.uniqueUserIdToPlayer[player.uniqueUserId] = player
	end)
	xmlFile:iterate(key .. ".handTools.handTool", function (_, toolKey)
		local filename = HTMLUtil.decodeFromHTML(NetworkUtil.convertFromNetworkFilename(xmlFile:getString(toolKey .. "#filename")))

		table.insert(self.handTools, filename)
	end)
	xmlFile:iterate(key .. ".contracting.farm", function (_, contractKey)
		local farmId = xmlFile:getInt(contractKey .. "#farmId")
		self.contractingFor[farmId] = true
	end)
	self.stats:loadFromXMLFile(xmlFile, key)

	return true
end

function Farm:saveToXMLFile(xmlFile, key)
	xmlFile:setInt(key .. "#farmId", self.farmId)
	xmlFile:setString(key .. "#name", self.name)
	xmlFile:setInt(key .. "#color", self.color)

	if self.password ~= nil then
		xmlFile:setString(key .. "#password", self.password)
	end

	xmlFile:setFloat(key .. "#loan", self.loan)
	xmlFile:setFloat(key .. "#money", self.money)
	xmlFile:setFloat(key .. "#loanAnnualInterestRate", self.loanAnnualInterestRate)
	xmlFile:setSortedTable(key .. ".players.player", self.players, function (playerKey, player)
		xmlFile:setString(playerKey .. "#uniqueUserId", player.uniqueUserId)
		xmlFile:setBool(playerKey .. "#farmManager", player.isFarmManager)
		xmlFile:setString(playerKey .. "#lastNickname", player.lastNickname or "")

		for _, permission in ipairs(Farm.PERMISSIONS) do
			local value = Utils.getNoNil(player.permissions[permission], false)

			xmlFile:setBool(playerKey .. "#" .. permission, value)
		end
	end)
	xmlFile:setSortedTable(key .. ".handTools.handTool", self.handTools, function (toolKey, filename)
		xmlFile:setString(toolKey .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(filename)))
	end)
	xmlFile:setTable(key .. ".contracting.farm", self.contractingFor, function (contractKey, _, farmId)
		xmlFile:setInt(contractKey .. "#farmId", farmId)
	end)
	self.stats:saveToXMLFile(xmlFile, key)
end

function Farm:writeStream(streamId, connection)
	Farm:superClass().writeStream(self, streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteString(streamId, self.name)
	streamWriteUIntN(streamId, self.color, Farm.COLOR_SEND_NUM_BITS)
	streamWriteFloat32(streamId, self.money)
	streamWriteFloat32(streamId, self.loan)
	streamWriteBool(streamId, self.isSpectator)

	local numPlayers = table.getn(self.activeUsers)

	streamWriteUInt8(streamId, numPlayers)

	for _, player in ipairs(self.activeUsers) do
		NetworkUtil.writeNodeObjectId(streamId, player.userId)
		streamWriteBool(streamId, player.isFarmManager)

		for _, permission in ipairs(Farm.PERMISSIONS) do
			streamWriteBool(streamId, player.permissions[permission] or player.isFarmManager)
		end
	end

	streamWriteUInt8(streamId, table.size(self.contractingFor))

	for farmId, _ in pairs(self.contractingFor) do
		streamWriteUIntN(streamId, farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	end

	streamWriteUInt8(streamId, table.getn(self.handTools))

	for _, filename in ipairs(self.handTools) do
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(filename))
	end
end

function Farm:readStream(streamId, connection)
	Farm:superClass().readStream(self, streamId, connection)

	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.name = streamReadString(streamId)
	self.color = streamReadUIntN(streamId, Farm.COLOR_SEND_NUM_BITS)
	self.money = streamReadFloat32(streamId)
	self.loan = streamReadFloat32(streamId)
	self.isSpectator = streamReadBool(streamId)

	if self.farmId == FarmManager.SPECTATOR_FARM_ID then
		self.isSpectator = true
	end

	local numPlayers = streamReadUInt8(streamId)
	self.players = {}
	self.activeUsers = {}

	for _ = 1, numPlayers do
		local player = {
			userId = NetworkUtil.readNodeObjectId(streamId),
			isFarmManager = streamReadBool(streamId),
			permissions = {}
		}

		for _, permission in ipairs(Farm.PERMISSIONS) do
			player.permissions[permission] = streamReadBool(streamId)
		end

		self.userIdToPlayer[player.userId] = player

		table.insert(self.players, player)
		table.insert(self.activeUsers, player)
	end

	local numContracting = streamReadUInt8(streamId)

	for _ = 1, numContracting do
		local farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.contractingFor[farmId] = true
	end

	local num = streamReadUInt8(streamId)

	for _ = 1, num do
		local filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

		table.insert(self.handTools, filename)
	end
end

function Farm:writeUpdateStream(streamId, connection, dirtyMask)
	Farm:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if streamWriteBool(streamId, bitAND(dirtyMask, self.farmMoneyDirtyFlag) ~= 0) then
		streamWriteFloat32(streamId, self.money)

		self.lastMoneySent = self.money
	end
end

function Farm:readUpdateStream(streamId, timestamp, connection)
	Farm:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if streamReadBool(streamId) then
		self.money = streamReadFloat32(streamId)

		g_messageCenter:publish(MessageType.MONEY_CHANGED, self.farmId, self.money)
	end
end

function Farm:merge(other)
	self.money = self.money + other.money
	self.loan = self.loan + other.loan
	self.loanAnnualInterestRate = math.min(self.loanAnnualInterestRate, other.loanAnnualInterestRate)

	self.stats:merge(other.stats)
end

function Farm:resetToSingleplayer()
	local player = {
		uniqueUserId = FarmManager.SINGLEPLAYER_UUID,
		isFarmManager = true,
		permissions = {}
	}

	for _, permission in ipairs(Farm.PERMISSIONS) do
		player.permissions[permission] = true
	end

	self.players = {
		player
	}
	self.color = 1
	self.uniqueUserIdToPlayer[player.uniqueUserId] = player
end

function Farm:getFarmhouse()
	return g_currentMission.placeableSystem:getFarmhouse(self.farmId)
end

function Farm:getSpawnPoint()
	if not self.isSpectator then
		local farmhouse = self:getFarmhouse()

		if farmhouse ~= nil then
			return farmhouse:getSpawnPoint()
		end
	end

	return g_mission00StartPoint
end

function Farm:getSleepCamera()
	if not self.isSpectator then
		local farmhouse = self:getFarmhouse()

		if farmhouse ~= nil then
			return farmhouse:getSleepCamera()
		end
	end

	return nil
end

function Farm:getNumActivePlayers()
	return table.getn(self.activeUsers)
end

function Farm:getNumPlayers()
	return table.getn(self.players)
end

function Farm:getActiveUsers()
	return self.activeUsers
end

function Farm:isUserFarmManager(userId)
	local player = self.userIdToPlayer[userId]

	return player ~= nil and player.isFarmManager
end

function Farm:getUserPermissions(userId)
	local player = self.userIdToPlayer[userId]

	return player ~= nil and player.permissions or Farm.NO_PERMISSIONS
end

function Farm:setUserPermission(userId, permission, hasPermission)
	local player = self.userIdToPlayer[userId]

	if player ~= nil then
		player.permissions[permission] = hasPermission

		g_client:getServerConnection():sendEvent(PlayerPermissionsEvent.new(userId, player.permissions, player.isFarmManager))
	end
end

function Farm:promoteUser(userId)
	local player = self.userIdToPlayer[userId]

	if player ~= nil then
		local fullPermissions = {}

		for _, permissionKey in ipairs(Farm.PERMISSIONS) do
			fullPermissions[permissionKey] = true
		end

		g_client:getServerConnection():sendEvent(PlayerPermissionsEvent.new(userId, fullPermissions, true))
	end
end

function Farm:demoteUser(userId)
	local player = self.userIdToPlayer[userId]

	if player ~= nil then
		local fullPermissions = {}

		for _, permissionKey in ipairs(Farm.PERMISSIONS) do
			fullPermissions[permissionKey] = false
		end

		g_client:getServerConnection():sendEvent(PlayerPermissionsEvent.new(userId, fullPermissions, false))
	end
end

function Farm:canBeDestroyed()
	if #self.activeUsers > 0 then
		return false, "ui_farmDeleteHasPlayers"
	end

	return true
end

function Farm:getColor()
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		if self.isSpectator then
			return Farm.COLOR_SPECTATOR
		else
			return Farm.COLORS[self.color]
		end
	else
		return Farm.COLOR_SINGLEPLAYER
	end
end

function Farm:getIconUVs()
	return Farm.ICON_UVS[self.color]
end

function Farm:getIsContractingFor(farmId)
	return self.contractingFor[farmId] or false
end

function Farm:setIsContractingFor(farmId, isContracting, noSendEvent)
	if self.isServer or noSendEvent then
		if isContracting then
			self.contractingFor[farmId] = true
		else
			self.contractingFor[farmId] = nil
		end

		if self.isServer and not noSendEvent then
			g_server:broadcastEvent(ContractingStateEvent.new(self.farmId, farmId, isContracting))
		end

		g_messageCenter:publish(ContractingStateEvent, self.farmId, farmId, isContracting)
	elseif not noSendEvent then
		g_client:getServerConnection():sendEvent(ContractingStateEvent.new(self.farmId, farmId, isContracting))
	end
end

function Farm:farmPropertyChanged(farmId)
	if farmId == self.farmId and not self.isSpectator then
		self:updateMaxLoan()
	end
end

function Farm:getEquity()
	local equity = 0
	local farmlands = g_farmlandManager:getOwnedFarmlandIdsByFarmId(self.farmId)

	for _, farmlandId in pairs(farmlands) do
		local farmland = g_farmlandManager:getFarmlandById(farmlandId)
		equity = equity + farmland.price
	end

	for _, placeable in pairs(g_currentMission.placeables) do
		if placeable:getOwnerFarmId() == self.farmId then
			equity = equity + placeable:getSellPrice()
		end
	end

	return equity
end

function Farm:updateMaxLoan()
	local roundedTo5000 = math.floor(Farm.EQUITY_LOAN_RATIO * self:getEquity() / 5000) * 5000
	self.loanMax = MathUtil.clamp(roundedTo5000, Farm.MIN_LOAN, Farm.MAX_LOAN)
end

function Farm:calculateDailyLoanInterest()
	local annualInterest = self.loanAnnualInterestRate / 100 * self.loan

	return math.floor(annualInterest / 356) * g_currentMission.environment.timeAdjustment
end

function Farm:changeBalance(amount, moneyType)
	self.money = self.money + amount
	local statistic = moneyType ~= nil and moneyType.statistic or nil

	self.stats:changeFinanceStats(amount, statistic)

	if amount > 0 then
		self.stats:addHeroStat("moneyEarned", amount)
	end

	if math.abs(self.lastMoneySent - self.money) >= 1 then
		self:raiseDirtyFlags(self.farmMoneyDirtyFlag)
		g_messageCenter:publish(MessageType.MONEY_CHANGED, self.farmId, self.money)
	end
end

function Farm:addPurchasedCoins(amount)
	self.money = self.money + amount

	g_messageCenter:publish(MessageType.MONEY_CHANGED, self.farmId, self.money)
end

function Farm:getBalance()
	return self.money
end

function Farm:getLoan()
	return self.loan
end

function Farm:periodChanged()
	self.stats:archiveFinances()
end

function Farm:getHandTools()
	return self.handTools
end

function Farm:hasHandtool(xmlFilename)
	return table.hasElement(self.handTools, xmlFilename)
end

function Farm:addHandTool(xmlFilename)
	table.addElement(self.handTools, xmlFilename)
end

function Farm:removeHandTool(xmlFilename)
	table.removeElement(self.handTools, xmlFilename)
end

function Farm:addUser(userId, uniqueUserId, isFarmManager, user)
	if g_currentMission.connectedToDedicatedServer and userId == g_currentMission:getServerUserId() then
		return
	end

	local player = self.userIdToPlayer[userId]

	if player ~= nil then
		return
	end

	player = {}
	isFarmManager = isFarmManager or false
	player.isFarmManager = isFarmManager
	player.userId = userId

	self:updateLastNickname(player, userId, user)

	player.permissions = {}

	for _, permission in ipairs(Farm.PERMISSIONS) do
		player.permissions[permission] = isFarmManager
	end

	if not isFarmManager then
		for _, permission in pairs(Farm.DEFAULT_PERMISSIONS) do
			player.permissions[permission] = true
		end
	end

	if self.isServer then
		player.uniqueUserId = uniqueUserId
		self.uniqueUserIdToPlayer[uniqueUserId] = player
	end

	table.insert(self.players, player)
	table.insert(self.activeUsers, player)

	self.userIdToPlayer[userId] = player
end

function Farm:removeUser(userId)
	local player = self.userIdToPlayer[userId]

	if player ~= nil then
		table.removeElement(self.players, player)
		table.removeElement(self.activeUsers, player)

		self.userIdToPlayer[userId] = nil

		if self.isServer then
			self.uniqueUserIdToPlayer[player.uniqueUserId] = nil
		end
	end
end

function Farm:onUserJoinGame(uniqueUserId, userId, user)
	local player = self.uniqueUserIdToPlayer[uniqueUserId]

	if self.isSpectator and player == nil then
		self:addUser(userId, uniqueUserId, nil, user)

		return true
	elseif self.userIdToPlayer[userId] == nil then
		player.userId = userId
		self.userIdToPlayer[userId] = player

		self:updateLastNickname(player, userId, user)
		table.insert(self.activeUsers, player)

		return true
	end

	return false
end

function Farm:onUserQuitGame(userId)
	local player = self.userIdToPlayer[userId]

	if player ~= nil then
		player.userId = nil
		self.userIdToPlayer[userId] = nil

		table.removeElement(self.activeUsers, player)
	end
end

function Farm:updateLastNickname(player, userId, user)
	if user == nil then
		user = g_currentMission.userManager:getUserByUserId(userId)
	end

	if user ~= nil then
		player.lastNickname = user:getNickname()
	end
end
