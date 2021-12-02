RemovePlayerFromFarmEvent = {}
local RemovePlayerFromFarmEvent_mt = Class(RemovePlayerFromFarmEvent, Event)

InitStaticEventClass(RemovePlayerFromFarmEvent, "RemovePlayerFromFarmEvent", EventIds.EVENT_REMOVE_PLAYER_FROM_FARM)

function RemovePlayerFromFarmEvent.emptyNew()
	local self = Event.new(RemovePlayerFromFarmEvent_mt)

	return self
end

function RemovePlayerFromFarmEvent.new(userId)
	local self = RemovePlayerFromFarmEvent.emptyNew()
	self.userId = userId

	return self
end

function RemovePlayerFromFarmEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObjectId(streamId, self.userId)
end

function RemovePlayerFromFarmEvent:readStream(streamId, connection)
	self.userId = NetworkUtil.readNodeObjectId(streamId)

	self:run(connection)
end

function RemovePlayerFromFarmEvent:run(connection)
	local farmId = g_currentMission:getFarmId(connection)

	if g_currentMission:getHasPlayerPermission(Farm.PERMISSION.MANAGE_RIGHTS, connection, farmId) then
		local player = nil

		for _, p in pairs(g_currentMission.players) do
			if p.userId == self.userId then
				player = p

				break
			end
		end

		if player ~= nil then
			g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(player, FarmManager.SPECTATOR_FARM_ID, nil))
		end
	end
end
