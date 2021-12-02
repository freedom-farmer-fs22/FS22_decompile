TransferMoneyEvent = {}
local TransferMoneyEvent_mt = Class(TransferMoneyEvent, Event)

InitStaticEventClass(TransferMoneyEvent, "TransferMoneyEvent", EventIds.EVENT_TRANSFER_MONEY)

function TransferMoneyEvent.emptyNew()
	local self = Event.new(TransferMoneyEvent_mt)

	return self
end

function TransferMoneyEvent.new(amount, destinationFarmId)
	local self = TransferMoneyEvent.emptyNew()
	self.amount = amount
	self.destinationFarmId = destinationFarmId

	return self
end

function TransferMoneyEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.amount)
	streamWriteUIntN(streamId, self.destinationFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function TransferMoneyEvent:readStream(streamId, connection)
	self.amount = streamReadFloat32(streamId)
	self.destinationFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	self:run(connection)
end

function TransferMoneyEvent:run(connection)
	if not connection:getIsServer() then
		local senderUserId = g_currentMission.userManager:getUserIdByConnection(connection)
		local senderFarm = g_farmManager:getFarmByUserId(senderUserId)

		if g_currentMission:getHasPlayerPermission("transferMoney", connection, senderFarm.farmId) and self.amount <= senderFarm.money then
			g_currentMission:addMoney(-self.amount, senderFarm.farmId, MoneyType.TRANSFER, true, true)
			g_currentMission:addMoney(self.amount, self.destinationFarmId, MoneyType.TRANSFER, true, true)
		end
	else
		print("Error: TransferMoneyEvent is a client to server only event")
	end
end
