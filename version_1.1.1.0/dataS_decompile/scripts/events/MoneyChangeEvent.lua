MoneyChangeEvent = {}
local MoneyChangeEvent_mt = Class(MoneyChangeEvent, Event)

InitStaticEventClass(MoneyChangeEvent, "MoneyChangeEvent", EventIds.EVENT_REQUEST_MONEY_CHANGE)

function MoneyChangeEvent.emptyNew()
	local self = Event.new(MoneyChangeEvent_mt)

	return self
end

function MoneyChangeEvent.new(amount, moneyType, farmId, text)
	local self = MoneyChangeEvent.emptyNew()
	self.amount = amount
	self.moneyType = moneyType
	self.farmId = farmId
	self.text = text

	return self
end

function MoneyChangeEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.amount)
	streamWriteUInt8(streamId, self.moneyType.id)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)

	if self.text ~= nil then
		streamWriteBool(streamId, true)
		streamWriteString(streamId, self.text)
	else
		streamWriteBool(streamId, false)
	end
end

function MoneyChangeEvent:readStream(streamId, connection)
	self.amount = streamReadFloat32(streamId)
	self.moneyType = MoneyType.getMoneyTypeById(streamReadUInt8(streamId))
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	if streamReadBool(streamId) then
		self.text = streamReadString(streamId)
	end

	self:run(connection)
end

function MoneyChangeEvent:run(connection)
	if g_currentMission:getFarmId() == self.farmId then
		g_currentMission.hud:addMoneyChange(self.moneyType, self.amount)

		local text = nil

		if self.text ~= nil then
			text = g_i18n:getText(self.text)
		end

		g_currentMission.hud:showMoneyChange(self.moneyType, text)
	end
end
