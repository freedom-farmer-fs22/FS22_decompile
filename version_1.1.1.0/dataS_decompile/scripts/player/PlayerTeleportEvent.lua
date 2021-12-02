PlayerTeleportEvent = {}
local PlayerTeleportEvent_mt = Class(PlayerTeleportEvent, Event)

InitStaticEventClass(PlayerTeleportEvent, "PlayerTeleportEvent", EventIds.EVENT_PLAYER_TELEPORT)

function PlayerTeleportEvent.emptyNew()
	local self = Event.new(PlayerTeleportEvent_mt)

	return self
end

function PlayerTeleportEvent.new(x, y, z, isAbsolute, isRootNode)
	local self = PlayerTeleportEvent.emptyNew()
	self.x = x
	self.y = y
	self.z = z
	self.isAbsolute = isAbsolute
	self.isRootNode = isRootNode

	return self
end

function PlayerTeleportEvent.newExitVehicle(exitVehicle)
	local self = PlayerTeleportEvent.emptyNew()
	self.exitVehicle = exitVehicle

	return self
end

function PlayerTeleportEvent:readStream(streamId, connection)
	if streamReadBool(streamId) then
		self.exitVehicle = NetworkUtil.readNodeObject(streamId)
	else
		self.x = streamReadFloat32(streamId)
		self.y = streamReadFloat32(streamId)
		self.z = streamReadFloat32(streamId)
		self.isAbsolute = streamReadBool(streamId)
		self.isRootNode = streamReadBool(streamId)
	end

	self:run(connection)
end

function PlayerTeleportEvent:writeStream(streamId, connection)
	if streamWriteBool(streamId, self.exitVehicle ~= nil) then
		NetworkUtil.writeNodeObject(streamId, self.exitVehicle)
	else
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
		streamWriteBool(streamId, self.isAbsolute)
		streamWriteBool(streamId, self.isRootNode)
	end
end

function PlayerTeleportEvent:run(connection)
	if not connection:getIsServer() then
		local player = g_currentMission.connectionsToPlayer[connection]

		if player ~= nil then
			if self.exitVehicle ~= nil then
				player:moveToExitPoint(self.exitVehicle)
			elseif self.x ~= nil then
				player:moveTo(self.x, self.y, self.z, self.isAbsolute, self.isRootNode)
			end
		end
	end
end
