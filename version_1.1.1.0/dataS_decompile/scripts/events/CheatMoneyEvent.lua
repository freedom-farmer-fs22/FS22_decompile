CheatMoneyEvent = {}
local CheatMoneyEvent_mt = Class(CheatMoneyEvent, Event)

InitStaticEventClass(CheatMoneyEvent, "CheatMoneyEvent", EventIds.EVENT_CHEAT_MONEY)

function CheatMoneyEvent.emptyNew()
	local self = Event.new(CheatMoneyEvent_mt)

	return self
end

function CheatMoneyEvent.new(amount)
	local self = CheatMoneyEvent.emptyNew()
	self.amount = amount

	return self
end

function CheatMoneyEvent:readStream(streamId, connection)
	assert(g_currentMission:getIsServer())

	self.amount = streamReadInt32(streamId)

	if g_currentMission:getIsServer() and not connection:getIsServer() and g_currentMission.userManager:getIsConnectionMasterUser(connection) then
		local farmId = g_currentMission:getPlayerByConnection(connection).farmId

		if farmId ~= FarmManager.SPECTATOR_FARM_ID then
			g_currentMission:addMoney(self.amount, farmId, MoneyType.OTHER)
		end
	end
end

function CheatMoneyEvent:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.amount)
end

function CheatMoneyEvent:run(connection)
	print("Error: CheatMoneyEvent is a client to server only event")
end
