BuyHandToolEvent = {}
local BuyHandToolEvent_mt = Class(BuyHandToolEvent, Event)

InitStaticEventClass(BuyHandToolEvent, "BuyHandToolEvent", EventIds.EVENT_BUY_HANDTOOL)

BuyHandToolEvent.STATE_SUCCESS = 0
BuyHandToolEvent.STATE_NO_PERMISSION = 1
BuyHandToolEvent.STATE_FAILED_TO_LOAD = 2
BuyHandToolEvent.STATE_NOT_ENOUGH_MONEY = 3

function BuyHandToolEvent.emptyNew()
	local self = Event.new(BuyHandToolEvent_mt)

	return self
end

function BuyHandToolEvent.new(filename, farmId)
	local self = BuyHandToolEvent.emptyNew()
	self.isAnswer = false
	self.filename = filename
	self.farmId = farmId

	return self
end

function BuyHandToolEvent.newServerToClient(successful, filename, farmId, price, errorCode)
	local self = BuyHandToolEvent.emptyNew()
	self.isAnswer = true
	self.successful = successful
	self.errorCode = errorCode
	self.filename = filename
	self.farmId = farmId
	self.price = price

	return self
end

function BuyHandToolEvent:readStream(streamId, connection)
	self.isAnswer = streamReadBool(streamId)

	if self.isAnswer then
		self.successful = streamReadBool(streamId)
	end

	if self.isAnswer and self.successful or not self.isAnswer then
		self.filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	end

	if self.isAnswer and not self.successful then
		self.errorCode = streamReadUIntN(streamId, 2)
	else
		self.errorCode = BuyHandToolEvent.STATE_SUCCESS
	end

	if self.isAnswer then
		self.price = streamReadFloat32(streamId)
	end

	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	self:run(connection)
end

function BuyHandToolEvent:writeStream(streamId, connection)
	streamWriteBool(streamId, self.isAnswer)

	if self.isAnswer then
		streamWriteBool(streamId, self.successful)
	end

	if self.isAnswer and self.successful or not self.isAnswer then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.filename))
	end

	if self.isAnswer and not self.successful then
		streamWriteUIntN(streamId, self.errorCode, 2)
	end

	if self.isAnswer then
		streamWriteFloat32(streamId, self.price)
	end

	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function BuyHandToolEvent:run(connection)
	if not connection:getIsServer() then
		local price = 0
		local _ = nil

		if g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_VEHICLE, connection) then
			local dataStoreItem = g_storeManager:getItemByXMLFilename(self.filename)

			if dataStoreItem ~= nil then
				price, _ = g_currentMission.economyManager:getBuyPrice(dataStoreItem)

				if price <= g_currentMission:getMoney(self.farmId) then
					local storeItemXmlFilename = dataStoreItem.xmlFilename
					local successful = false

					if storeItemXmlFilename ~= nil and g_currentMission.players ~= nil then
						successful = true

						self:addHandTool(storeItemXmlFilename, false, self.farmId)
						g_currentMission:addMoney(-price, self.farmId, MoneyType.SHOP_VEHICLE_BUY, true)
						g_server:broadcastEvent(BuyHandToolEvent.new(storeItemXmlFilename, self.farmId), nil, connection)
					end

					connection:sendEvent(BuyHandToolEvent.newServerToClient(successful, storeItemXmlFilename, self.farmId, price))
				else
					connection:sendEvent(BuyHandToolEvent.newServerToClient(false, nil, self.farmId, price, BuyHandToolEvent.STATE_NOT_ENOUGH_MONEY))
				end
			else
				connection:sendEvent(BuyHandToolEvent.newServerToClient(false, nil, self.farmId, price, BuyHandToolEvent.STATE_FAILED_TO_LOAD))
			end
		else
			connection:sendEvent(BuyHandToolEvent.newServerToClient(false, nil, self.farmId, price, BuyHandToolEvent.STATE_NO_PERMISSION))
		end
	elseif self.isAnswer then
		if self.successful and not g_currentMission:getIsServer() then
			self:addHandTool(self.filename, true, self.farmId)
		end

		g_messageCenter:publish(BuyHandToolEvent, self.successful, self.errorCode, self.price)
	else
		self:addHandTool(self.filename, true, self.farmId)
	end
end

function BuyHandToolEvent:addHandTool(xmlFilename, useStoreItemPath, farmId)
	if useStoreItemPath then
		xmlFilename = g_storeManager:getItemByXMLFilename(xmlFilename).xmlFilename
	end

	g_farmManager:getFarmById(farmId):addHandTool(xmlFilename)
end
