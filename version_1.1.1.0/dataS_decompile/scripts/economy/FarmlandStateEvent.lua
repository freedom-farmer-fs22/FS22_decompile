FarmlandStateEvent = {}
local FarmlandStateEvent_mt = Class(FarmlandStateEvent, Event)

InitStaticEventClass(FarmlandStateEvent, "FarmlandStateEvent", EventIds.EVENT_FARMLAND_STATE)

function FarmlandStateEvent.emptyNew()
	local self = Event.new(FarmlandStateEvent_mt)

	return self
end

function FarmlandStateEvent.new(id, farmId, price)
	local self = FarmlandStateEvent.emptyNew()
	self.id = id
	self.farmId = farmId
	self.price = price

	return self
end

function FarmlandStateEvent:readStream(streamId, connection)
	self.id = streamReadUIntN(streamId, g_farmlandManager.numberOfBits)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	self.price = streamReadInt32(streamId)

	self:run(connection)
end

function FarmlandStateEvent:writeStream(streamId, connection)
	streamWriteUIntN(streamId, self.id, g_farmlandManager.numberOfBits)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	streamWriteInt32(streamId, self.price)
end

function FarmlandStateEvent:run(connection)
	if g_farmlandManager:getIsValidFarmlandId(self.id) then
		if not connection:getIsServer() then
			local currentOwner = g_farmlandManager:getFarmlandOwner(self.id)

			if self.farmId == FarmlandManager.NO_OWNER_FARM_ID or currentOwner == FarmlandManager.NO_OWNER_FARM_ID then
				local player = g_currentMission:getPlayerByConnection(connection)
				local farmAllowed = player ~= nil and g_currentMission:getHasPlayerPermission("farmManager", connection, player.farmId) and (player.farmId == self.farmId or currentOwner == player.farmId)

				if player ~= nil and player.farmId > 0 and farmAllowed then
					if self.price > 0 then
						local farmId = player.farmId
						local money = g_currentMission:getMoney(farmId)

						if self.farmId ~= FarmlandManager.NO_OWNER_FARM_ID then
							if money < self.price then
								return
							end

							g_currentMission:addMoney(-self.price, farmId, MoneyType.FIELD_BUY, true, true)
						else
							g_currentMission:addMoney(self.price, farmId, MoneyType.FIELD_SELL, true, true)
						end
					end

					g_server:broadcastEvent(self, true)
				end
			end
		else
			g_farmlandManager:setLandOwnership(self.id, self.farmId)
		end
	end
end
