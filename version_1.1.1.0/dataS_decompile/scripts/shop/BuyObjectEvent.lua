BuyObjectEvent = {}
local BuyObjectEvent_mt = Class(BuyObjectEvent, Event)
BuyObjectEvent.STATE_SUCCESS = 0
BuyObjectEvent.STATE_FAILED_TO_LOAD = 1
BuyObjectEvent.STATE_NO_SPACE = 2
BuyObjectEvent.STATE_LIMIT_REACHED = 3
BuyObjectEvent.STATE_NOT_ENOUGH_MONEY = 4

InitStaticEventClass(BuyObjectEvent, "BuyObjectEvent", EventIds.EVENT_BUY_OBJECT)

function BuyObjectEvent.emptyNew()
	local self = Event.new(BuyObjectEvent_mt)

	return self
end

function BuyObjectEvent.new(filename, outsideBuy, ownerFarmId)
	local self = BuyObjectEvent.emptyNew()
	self.filename = filename
	self.outsideBuy = outsideBuy
	self.ownerFarmId = ownerFarmId

	return self
end

function BuyObjectEvent.newServerToClient(errorCode, price)
	local self = BuyObjectEvent.emptyNew()
	self.errorCode = errorCode
	self.price = price

	return self
end

function BuyObjectEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
		self.outsideBuy = streamReadBool(streamId)
		self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	else
		self.errorCode = streamReadUIntN(streamId, 3)
		self.price = streamReadFloat32(streamId)
	end

	self:run(connection)
end

function BuyObjectEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.filename))
		streamWriteBool(streamId, self.outsideBuy)
		streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
		streamWriteFloat32(streamId, self.price)
	end
end

function BuyObjectEvent:run(connection)
	if not connection:getIsServer() then
		self.filename = self.filename:lower()
		local dataStoreItem = g_storeManager:getItemByXMLFilename(self.filename)
		local errorCode = BuyObjectEvent.STATE_FAILED_TO_LOAD
		local price = 0
		local _ = nil

		if dataStoreItem ~= nil then
			price, _ = g_currentMission.economyManager:getBuyPrice(dataStoreItem, self.saleItem)

			if price <= g_currentMission:getMoney(self.ownerFarmId) then
				local object, hasNoSpace, isLimitReached = g_currentMission:loadObjectAtPlace(dataStoreItem.xmlFilename, g_currentMission.storeSpawnPlaces, g_currentMission.usedStorePlaces, MathUtil.degToRad(dataStoreItem.rotation), self.ownerFarmId)

				if object ~= nil then
					if GS_IS_CONSOLE_VERSION and not fileExists(dataStoreItem.xmlFilename) then
						object:delete()
					else
						if not self.outsideBuy then
							local financeCategory = MoneyType.OTHER

							if object.fillType == FillType.TREESAPLINGS or object.fillType == FillType.POPLAR then
								financeCategory = MoneyType.PURCHASE_SAPLINGS
							elseif object.fillType == FillType.FERTILIZER or object.fillType == FillType.LIQUIDFERTILIZER then
								financeCategory = MoneyType.PURCHASE_FERTILIZER
							elseif object.fillType == FillType.SEEDS then
								financeCategory = MoneyType.PURCHASE_SEEDS
							end

							g_currentMission:addMoney(-price, self.ownerFarmId, financeCategory)
						end

						errorCode = BuyObjectEvent.STATE_SUCCESS
					end
				elseif hasNoSpace then
					errorCode = BuyObjectEvent.STATE_NO_SPACE
				elseif isLimitReached then
					errorCode = BuyObjectEvent.STATE_LIMIT_REACHED
				end
			else
				errorCode = BuyObjectEvent.STATE_NOT_ENOUGH_MONEY
			end
		end

		connection:sendEvent(BuyObjectEvent.newServerToClient(errorCode, price))
	else
		g_messageCenter:publish(BuyObjectEvent, self.errorCode, self.price)
	end
end
