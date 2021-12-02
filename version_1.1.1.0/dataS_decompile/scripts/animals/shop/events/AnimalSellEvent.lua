AnimalSellEvent = {
	SELL_SUCCESS = 0,
	SELL_ERROR_NO_PERMISSION = 1,
	SELL_ERROR_INVALID_CLUSTER = 2,
	SELL_ERROR_NOT_ENOUGH_ANIMALS = 3,
	SELL_ERROR_CANNOT_BE_SOLD = 4,
	SELL_ERROR_OBJECT_DOES_NOT_EXIST = 5
}
local AnimalSellEvent_mt = Class(AnimalSellEvent, Event)

InitStaticEventClass(AnimalSellEvent, "AnimalSellEvent", EventIds.EVENT_ANIMAL_SELL)

function AnimalSellEvent.emptyNew()
	local self = Event.new(AnimalSellEvent_mt)

	return self
end

function AnimalSellEvent.new(object, clusterId, numAnimals, sellPrice, feePrice)
	local self = AnimalSellEvent.emptyNew()
	self.object = object
	self.clusterId = clusterId
	self.numAnimals = numAnimals
	self.sellPrice = sellPrice
	self.feePrice = feePrice

	return self
end

function AnimalSellEvent.newServerToClient(errorCode)
	local self = AnimalSellEvent.emptyNew()
	self.errorCode = errorCode

	return self
end

function AnimalSellEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.object = NetworkUtil.readNodeObject(streamId)
		self.clusterId = streamReadInt32(streamId)
		self.numAnimals = streamReadUInt8(streamId)
		self.sellPrice = streamReadInt32(streamId)
		self.feePrice = -streamReadInt32(streamId)
	else
		self.errorCode = streamReadUIntN(streamId, 3)
	end

	self:run(connection)
end

function AnimalSellEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.object)
		streamWriteInt32(streamId, self.clusterId)
		streamWriteUInt8(streamId, self.numAnimals)
		streamWriteInt32(streamId, math.abs(self.sellPrice))
		streamWriteInt32(streamId, math.abs(self.feePrice))
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
	end
end

function AnimalSellEvent:run(connection)
	if not connection:getIsServer() then
		if not g_currentMission:getHasPlayerPermission("tradeAnimals", connection) then
			connection:sendEvent(AnimalSellEvent.newServerToClient(AnimalSellEvent.SELL_ERROR_NO_PERMISSION))

			return
		end

		local errorCode = AnimalSellEvent.validate(self.object, self.clusterId, self.numAnimals, self.sellPrice, self.feePrice)

		if errorCode ~= nil then
			connection:sendEvent(AnimalSellEvent.newServerToClient(errorCode))

			return
		end

		local cluster = self.object:getClusterById(self.clusterId)
		local clusterSystem = self.object:getClusterSystem()

		cluster:changeNumAnimals(-self.numAnimals)
		clusterSystem:updateNow()

		local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
		local farm = g_farmManager:getFarmForUniqueUserId(uniqueUserId)
		local price = self.sellPrice + self.feePrice

		g_currentMission:addMoney(price, farm.farmId, MoneyType.SOLD_ANIMALS, true, true)
		connection:sendEvent(AnimalSellEvent.newServerToClient(AnimalSellEvent.SELL_SUCCESS))
	else
		g_messageCenter:publish(AnimalSellEvent, self.errorCode)
	end
end

function AnimalSellEvent.validate(object, clusterId, numAnimals, sellPrice, feePrice)
	if object == nil then
		return AnimalSellEvent.SELL_ERROR_OBJECT_DOES_NOT_EXIST
	end

	local cluster = object:getClusterById(clusterId)

	if cluster == nil then
		return AnimalSellEvent.SELL_ERROR_INVALID_CLUSTER
	end

	if cluster:getNumAnimals() < numAnimals then
		return AnimalSellEvent.SELL_ERROR_NOT_ENOUGH_ANIMALS
	end

	if not cluster:getCanBeSold() then
		return AnimalSellEvent.SELL_ERROR_CANNOT_BE_SOLD
	end

	return nil
end
