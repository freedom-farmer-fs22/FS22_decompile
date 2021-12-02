SellHandToolEvent = {
	STATE_SUCCESS = 0,
	STATE_FAILED = 1,
	STATE_NO_PERMISSION = 2,
	STATE_IN_USE = 3
}
local SellHandToolEvent_mt = Class(SellHandToolEvent, Event)

InitStaticEventClass(SellHandToolEvent, "SellHandToolEvent", EventIds.EVENT_SELL_HANDTOOL)

function SellHandToolEvent.emptyNew()
	local self = Event.new(SellHandToolEvent_mt)

	return self
end

function SellHandToolEvent.new(filename, farmId)
	local self = SellHandToolEvent.emptyNew()
	self.filename = filename
	self.state = SellHandToolEvent.STATE_FAILED
	self.isAnswer = false
	self.farmId = farmId

	return self
end

function SellHandToolEvent.newServerToClient(state, filename, farmId)
	local self = SellHandToolEvent.emptyNew()
	self.state = state
	self.filename = filename
	self.farmId = farmId
	self.isAnswer = true

	return self
end

function SellHandToolEvent:readStream(streamId, connection)
	self.filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	self.state = streamReadUIntN(streamId, 2)
	self.isAnswer = streamReadBool(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	self:run(connection)
end

function SellHandToolEvent:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.filename))
	streamWriteUIntN(streamId, self.state, 2)
	streamWriteBool(streamId, self.isAnswer)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function SellHandToolEvent:run(connection)
	local dataStoreItem = g_storeManager:getItemByXMLFilename(self.filename)
	local filename = self.filename

	if dataStoreItem ~= nil then
		filename = dataStoreItem.xmlFilename
	end

	if not connection:getIsServer() then
		local state = SellHandToolEvent.STATE_FAILED

		if not g_currentMission:getHasPlayerPermission("sellVehicle", connection) then
			state = SellHandToolEvent.STATE_NO_PERMISSION
			dataStoreItem = nil
		end

		local toolInUse = false

		if g_currentMission.players ~= nil then
			for _, player in pairs(g_currentMission.players) do
				if player:getEquippedHandtoolFilename():lower() == filename:lower() then
					toolInUse = true

					break
				end
			end
		end

		if dataStoreItem ~= nil and not toolInUse and g_currentMission.players ~= nil then
			self:removeHandTool(filename, self.farmId)

			state = SellHandToolEvent.STATE_SUCCESS

			if g_currentMission:getIsServer() then
				g_server:broadcastEvent(SellHandToolEvent.new(filename, self.farmId), false, connection)
				g_currentMission:addMoney(g_currentMission.economyManager:getSellPrice(dataStoreItem), self.farmId, MoneyType.SHOP_VEHICLE_SELL, true)
			end
		end

		connection:sendEvent(SellHandToolEvent.newServerToClient(state, filename, self.farmId))
	elseif self.isAnswer then
		if self.state == SellHandToolEvent.STATE_SUCCESS then
			self:removeHandTool(filename, self.farmId)
		end

		g_messageCenter:publish(SellHandToolEvent, self.state)
	else
		self:removeHandTool(filename, self.farmId)
	end
end

function SellHandToolEvent:removeHandTool(xmlFilename, farmId)
	g_farmManager:getFarmById(farmId):removeHandTool(xmlFilename)
end
