ChangeLoanEvent = {}
local ChangeLoanEvent_mt = Class(ChangeLoanEvent, Event)

InitStaticEventClass(ChangeLoanEvent, "ChangeLoanEvent", EventIds.EVENT_CHANGE_LOAN)

function ChangeLoanEvent.emptyNew()
	local self = Event.new(ChangeLoanEvent_mt)

	return self
end

function ChangeLoanEvent.new(loanValue, farmId)
	local self = ChangeLoanEvent.emptyNew()
	self.loanValue = loanValue
	self.farmId = farmId

	return self
end

function ChangeLoanEvent:readStream(streamId, connection)
	self.loanValue = streamReadFloat32(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	self:run(connection)
end

function ChangeLoanEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.loanValue)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function ChangeLoanEvent:run(connection)
	if not connection:getIsServer() then
		if self.farmId ~= 0 and g_currentMission:getHasPlayerPermission("farmManager", connection, self.farmId) then
			local farm = g_farmManager:getFarmById(self.farmId)
			local curLoad = farm.loan
			farm.loan = MathUtil.clamp(curLoad + self.loanValue, 0, farm.loanMax)
			local delta = farm.loan - curLoad

			farm:changeBalance(delta)
			g_server:broadcastEvent(ChangeLoanEvent.new(farm.loan, farm.farmId), false, nil)
			g_messageCenter:publish(ChangeLoanEvent)
		end
	else
		local farm = g_farmManager:getFarmById(self.farmId)

		if farm ~= nil then
			farm.loan = self.loanValue
		end

		g_messageCenter:publish(ChangeLoanEvent)
	end
end
