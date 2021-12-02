RequestMoneyChangeEvent = {}
local RequestMoneyChangeEvent_mt = Class(RequestMoneyChangeEvent, Event)

InitStaticEventClass(RequestMoneyChangeEvent, "RequestMoneyChangeEvent", EventIds.EVENT_MONEY_CHANGE)

function RequestMoneyChangeEvent.emptyNew()
	local self = Event.new(RequestMoneyChangeEvent_mt)

	return self
end

function RequestMoneyChangeEvent.new(moneyType)
	local self = RequestMoneyChangeEvent.emptyNew()
	self.moneyTypeId = moneyType.id

	return self
end

function RequestMoneyChangeEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.moneyTypeId)
end

function RequestMoneyChangeEvent:readStream(streamId, connection)
	self.moneyTypeId = streamReadUInt8(streamId)

	self:run(connection)
end

function RequestMoneyChangeEvent:run(connection)
	local farmId = nil
	local moneyType = MoneyType.getMoneyTypeById(self.moneyTypeId)

	if moneyType == nil then
		Logging.devError("RequestMoneyChangeEvent - MoneyType with id '%s' not found!", tostring(self.moneyTypeId))
	end

	local player = g_currentMission:getPlayerByConnection(connection)

	if player ~= nil then
		farmId = player.farmId
	end

	if farmId == nil then
		Logging.devError("RequestMoneyChangeEvent - Missing farmId for player!")
	end

	if moneyType ~= nil and farmId ~= nil then
		g_currentMission:broadcastNotifications(moneyType, farmId)
	end
end
