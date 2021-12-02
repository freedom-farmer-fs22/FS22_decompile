PlayerPermissionsEvent = {}
local PlayerPermissionsEvent_mt = Class(PlayerPermissionsEvent, Event)

InitStaticEventClass(PlayerPermissionsEvent, "PlayerPermissionsEvent", EventIds.EVENT_PLAYER_PERMISSIONS)

function PlayerPermissionsEvent.emptyNew()
	local self = Event.new(PlayerPermissionsEvent_mt)

	return self
end

function PlayerPermissionsEvent.new(userId, permissions, isFarmManager)
	local self = PlayerPermissionsEvent.emptyNew()
	self.userId = userId
	self.permissions = permissions
	self.isFarmManager = isFarmManager

	return self
end

function PlayerPermissionsEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObjectId(streamId, self.userId)

	for _, permission in ipairs(Farm.PERMISSIONS) do
		streamWriteBool(streamId, self.permissions[permission])
	end

	if streamWriteBool(streamId, self.isFarmManager ~= nil) then
		streamWriteBool(streamId, self.isFarmManager)
	end
end

function PlayerPermissionsEvent:readStream(streamId, connection)
	self.userId = NetworkUtil.readNodeObjectId(streamId)
	self.permissions = {}

	for _, permission in ipairs(Farm.PERMISSIONS) do
		self.permissions[permission] = streamReadBool(streamId)
	end

	if streamReadBool(streamId) then
		self.isFarmManager = streamReadBool(streamId)
	end

	self:run(connection)
end

function PlayerPermissionsEvent:run(connection)
	if not connection:getIsServer() then
		local farm = g_farmManager:getFarmByUserId(self.userId)

		if g_currentMission:getHasPlayerPermission("manageRights", connection, farm.farmId) then
			local player = farm.userIdToPlayer[self.userId]
			player.permissions = self.permissions

			if self.isFarmManager ~= nil then
				player.isFarmManager = self.isFarmManager
			end

			g_server:broadcastEvent(self)
			g_messageCenter:publish(PlayerPermissionsEvent, self.userId)
		end
	else
		local farm = g_farmManager:getFarmByUserId(self.userId)
		local player = farm.userIdToPlayer[self.userId]
		player.permissions = self.permissions

		if self.isFarmManager ~= nil then
			player.isFarmManager = self.isFarmManager
		end

		g_messageCenter:publish(PlayerPermissionsEvent, self.userId)
	end
end

function PlayerPermissionsEvent.sendEvent(userId, permissions, isFarmManager, noEventSend)
	if noEventSend == nil or noEventSend == false then
		local event = PlayerPermissionsEvent.new(userId, permissions, isFarmManager)

		if g_server ~= nil then
			local farm = g_farmManager:getFarmByUserId(userId)
			local player = farm.userIdToPlayer[userId]

			g_server:broadcastEvent(event, nil, , player)
		else
			g_client:getServerConnection():sendEvent(event)
		end
	end
end
