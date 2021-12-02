BuyExistingPlaceableEvent = {}
local BuyExistingPlaceableEvent_mt = Class(BuyExistingPlaceableEvent, Event)
BuyExistingPlaceableEvent.STATE_SUCCESS = 0
BuyExistingPlaceableEvent.STATE_NO_PERMISSION = 1
BuyExistingPlaceableEvent.STATE_NOT_ENOUGH_MONEY = 2
BuyExistingPlaceableEvent.STATE_NUM_BITS = 2
BuyExistingPlaceableEvent.DIALOG_MESSAGES = {
	[BuyExistingPlaceableEvent.STATE_SUCCESS] = {
		text = "shop_messageBoughtPlaceable",
		dialogType = DialogElement.TYPE_INFO
	},
	[BuyExistingPlaceableEvent.STATE_NO_PERMISSION] = {
		text = "shop_messageNoPermissionGeneral",
		dialogType = DialogElement.TYPE_WARNING
	},
	[BuyExistingPlaceableEvent.STATE_NOT_ENOUGH_MONEY] = {
		text = "shop_messageNotEnoughMoneyToBuy",
		dialogType = DialogElement.TYPE_WARNING
	}
}

InitStaticEventClass(BuyExistingPlaceableEvent, "BuyExistingPlaceableEvent", EventIds.EVENT_BUY_EXISTING_PLACEABLE)

function BuyExistingPlaceableEvent.emptyNew()
	local self = Event.new(BuyExistingPlaceableEvent_mt)

	return self
end

function BuyExistingPlaceableEvent.new(placeable, ownerFarmId)
	local self = BuyExistingPlaceableEvent.emptyNew()
	self.placeable = placeable
	self.ownerFarmId = ownerFarmId

	return self
end

function BuyExistingPlaceableEvent.newServerToClient(statusCode, price)
	local self = BuyExistingPlaceableEvent.emptyNew()
	self.statusCode = statusCode
	self.price = price

	return self
end

function BuyExistingPlaceableEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.placeable = NetworkUtil.readNodeObject(streamId)
		self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
	else
		self.statusCode = streamReadUIntN(streamId, BuyExistingPlaceableEvent.STATE_NUM_BITS)
		self.price = streamReadInt32(streamId)
	end

	self:run(connection)
end

function BuyExistingPlaceableEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.placeable)
		streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
	else
		streamWriteUIntN(streamId, self.statusCode, BuyExistingPlaceableEvent.STATE_NUM_BITS)
		streamWriteInt32(streamId, self.price)
	end
end

function BuyExistingPlaceableEvent:run(connection)
	if not connection:getIsServer() then
		local statusCode = BuyExistingPlaceableEvent.STATE_SUCCESS
		local price = 0

		if not g_currentMission:getHasPlayerPermission("buyPlaceable", connection) then
			statusCode = BuyExistingPlaceableEvent.STATE_NO_PERMISSION
		else
			local dataStoreItem = g_storeManager:getItemByXMLFilename(self.placeable.configFileName)

			if dataStoreItem ~= nil then
				price = g_currentMission.economyManager:getBuyPrice(dataStoreItem)

				if self.placeable.buysFarmland and self.placeable.farmlandId ~= nil then
					local farmland = g_farmlandManager:getFarmlandById(self.placeable.farmlandId)

					if farmland ~= nil and g_farmlandManager:getFarmlandOwner(self.placeable.farmlandId) ~= self.ownerFarmId then
						price = price + farmland.price
					end
				end

				if price <= g_currentMission:getMoney(self.ownerFarmId) then
					g_currentMission:addMoney(-price, self.ownerFarmId, MoneyType.SHOP_PROPERTY_BUY, true, true)
					self.placeable:setOwnerFarmId(self.ownerFarmId)
				else
					statusCode = BuyExistingPlaceableEvent.STATE_NOT_ENOUGH_MONEY
				end
			end
		end

		connection:sendEvent(BuyExistingPlaceableEvent.newServerToClient(statusCode, price))
	else
		g_messageCenter:publish(BuyExistingPlaceableEvent, self.statusCode, self.price)
	end
end
