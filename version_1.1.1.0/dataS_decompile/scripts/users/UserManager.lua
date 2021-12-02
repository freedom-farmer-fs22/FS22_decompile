UserManager = {}
local UserManager_mt = Class(UserManager)

function UserManager.new(isServer, customMt)
	local self = setmetatable({}, customMt or UserManager_mt)
	self.isServer = isServer
	self.users = {}
	self.masterUsers = {}
	self.masterUserIdToConnection = {}
	self.idCounter = 0
	self.blockedUserUpdateTimer = 0

	return self
end

function UserManager:delete()
	for _, user in ipairs(self.users) do
		self:stoppedPlayWithUser(user)
	end
end

function UserManager:getNextUserId()
	self.idCounter = self.idCounter + 1

	return self.idCounter
end

function UserManager:addUser(user)
	table.insert(self.users, user)
	g_messageCenter:publish(MessageType.USER_ADDED, user)
	self:startPlayWithUser(user)
end

function UserManager:removeUserByConnection(connection)
	for k, user in ipairs(self.users) do
		if user:getConnection() == connection then
			self:stoppedPlayWithUser(user)
			self:removeMasterUser(user)
			table.remove(self.users, k)
			g_messageCenter:publish(MessageType.USER_REMOVED, user)

			break
		end
	end
end

function UserManager:removeUser(user)
	for k, u in ipairs(self.users) do
		if user == u then
			self:stoppedPlayWithUser(user)
			self:removeMasterUser(user)
			table.remove(self.users, k)
			g_messageCenter:publish(MessageType.USER_REMOVED, user)

			break
		end
	end
end

function UserManager:removeUserById(userId)
	for k, user in ipairs(self.users) do
		if userId == user:getId() then
			self:stoppedPlayWithUser(user)
			self:removeMasterUser(user)
			table.remove(self.users, k)
			g_messageCenter:publish(MessageType.USER_REMOVED, user)

			break
		end
	end
end

function UserManager:startPlayWithUser(user)
	if GS_PLATFORM_GGP then
		local platformUserId = user:getPlatformUserId()
		local platformId = user:getPlatformId()

		if getUserId() ~= platformUserId and getPlatformIdsAreCompatible(platformId, GS_PLATFORM_ID) then
			startedPlayWithPlatformUserId(platformUserId)
		end
	end
end

function UserManager:stoppedPlayWithUser(user)
	if GS_PLATFORM_GGP then
		local platformUserId = user:getPlatformUserId()
		local platformId = user:getPlatformId()

		if getUserId() ~= platformUserId and getPlatformIdsAreCompatible(platformId, GS_PLATFORM_ID) then
			stoppedPlayWithPlatformUserId(platformUserId)
		end
	end
end

function UserManager:getUsers()
	return self.users
end

function UserManager:getNumberOfUsers()
	return #self.users
end

function UserManager:getUserByNickname(nickname, useLowercase)
	if useLowercase then
		nickname = nickname:lower()
	end

	for _, user in ipairs(self.users) do
		local userNickname = user:getNickname()

		if useLowercase then
			userNickname = userNickname:lower()
		end

		if userNickname == nickname then
			return user
		end
	end

	return nil
end

function UserManager:getUserByConnection(connection)
	for _, user in ipairs(self.users) do
		if user:getConnection() == connection then
			return user
		end
	end

	return nil
end

function UserManager:getUserByUniqueId(uniqueUserId)
	for _, user in ipairs(self.users) do
		if user:getUniqueUserId() == uniqueUserId then
			return user
		end
	end

	return nil
end

function UserManager:getUserIdByConnection(connection)
	local user = self:getUserByConnection(connection)

	if user ~= nil then
		return user:getId()
	end

	return -1
end

function UserManager:getUserByUserId(userId)
	if userId == nil then
		return nil
	end

	for _, user in ipairs(self.users) do
		if user:getId() == userId then
			return user
		end
	end

	return nil
end

function UserManager:getUniqueUserIdByUserId(userId)
	if userId == nil then
		return nil
	end

	for _, user in ipairs(self.users) do
		if user:getId() == userId then
			return user:getUniqueUserId()
		end
	end

	return nil
end

function UserManager:getUniqueUserIdByConnection(connection)
	if connection == nil then
		return nil
	end

	local user = self:getUserByConnection(connection)

	if user == nil then
		return nil
	end

	return user:getUniqueUserId()
end

function UserManager:getNumberOfMasterUsers()
	return #self.masterUsers
end

function UserManager:addMasterUserByConnection(connection)
	assert(self.isServer, "UserManager:addMasterUserByConnection call is only allowed on Server")

	local user = self:getUserByConnection(connection)

	if user ~= nil then
		self:addMasterUser(user)
	end
end

function UserManager:addMasterUser(user)
	table.addElement(self.masterUsers, user)

	if self.isServer then
		self.masterUserIdToConnection[user:getId()] = user:getConnection()

		g_currentMission:broadcastMissionDynamicInfo()
	end

	user:setIsMasterUser(true)
	g_messageCenter:publish(MessageType.MASTERUSER_ADDED, user)
end

function UserManager:removeMasterUser(user)
	user:setIsMasterUser(false)
	table.removeElement(self.masterUsers, user)

	if self.isServer then
		self.masterUserIdToConnection[user:getId()] = nil
	end
end

function UserManager:getMasterUsers()
	return self.masterUsers
end

function UserManager:getIsUserIdMasterUser(userId)
	assert(self.isServer, "UserManager:getIsUserIdMasterUser call is only allowed on Server")

	return self.masterUserIdToConnection[userId] ~= nil
end

function UserManager:getIsConnectionMasterUser(connection)
	assert(self.isServer, "UserManager:getIsUserIdMasterUser call is only allowed on Server")

	local user = self:getUserByConnection(connection)

	return user:getIsMasterUser()
end

function UserManager:getAllPlatformSessionIds()
	assert(self.isServer, "UserManager:getAllPlatformSessionIds() call is only allowed on Server")

	local list = {}

	for _, user in ipairs(self.users) do
		local platformSessionId = user:getPlatformSessionId()

		if platformSessionId ~= "" then
			table.insert(list, platformSessionId)
		end
	end

	return list
end

function UserManager:setUserBlockDataDirty()
	self.blockedUserUpdateTimer = 0
end

function UserManager:update(dt)
	self.blockedUserUpdateTimer = self.blockedUserUpdateTimer - dt

	if self.blockedUserUpdateTimer <= 0 then
		for _, user in ipairs(self.users) do
			if not self.isServer then
				user:updateSentUserBlockedState()
			end

			local blockState = user:getIsBlocked()

			if user.lastKnownBlockState ~= blockState then
				user.lastKnownBlockState = blockState

				if self.isServer and blockState then
					local connection = user:getConnection()

					connection:sendEvent(KickBanNotificationEvent.new(false))
					g_server:closeConnection(connection)
				end
			end
		end

		self.blockedUserUpdateTimer = 5000
	end
end
