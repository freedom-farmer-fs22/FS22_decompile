PlayerSwitchedFarmEvent = {}
local PlayerSwitchedFarmEvent_mt = Class(PlayerSwitchedFarmEvent, Event)

InitStaticEventClass(PlayerSwitchedFarmEvent, "PlayerSwitchedFarmEvent", EventIds.EVENT_PLAYER_SWITCHED_FARM)

PlayerSwitchedFarmEvent.NO_FARM = 126

function PlayerSwitchedFarmEvent.emptyNew()
	local self = Event.new(PlayerSwitchedFarmEvent_mt)

	return self
end

function PlayerSwitchedFarmEvent.new(oldFarmId, farmId, userId)
	local self = PlayerSwitchedFarmEvent.emptyNew()
	self.farmId = farmId
	self.oldFarmId = oldFarmId
	self.userId = userId

	return self
end

function PlayerSwitchedFarmEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteUIntN(streamId, self.oldFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	NetworkUtil.writeNodeObjectId(streamId, self.userId)
end

function PlayerSwitchedFarmEvent:readStream(streamId, connection)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.oldFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.userId = NetworkUtil.readNodeObjectId(streamId)

	self:run(connection)
end

function PlayerSwitchedFarmEvent:run(connection)
	if connection:getIsServer() then
		if self.oldFarmId ~= FarmManager.INVALID_FARM_ID then
			g_farmManager:getFarmById(self.oldFarmId):removeUser(self.userId)
		end

		if self.farmId ~= FarmManager.INVALID_FARM_ID then
			g_farmManager:getFarmById(self.farmId):addUser(self.userId)
		end

		g_messageCenter:publish(MessageType.PLAYER_FARM_CHANGED, self.player)
	else
		g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(self.oldFarmId, self.farmId, self.userId), true)
	end
end
