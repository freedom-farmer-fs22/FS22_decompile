AnimalLoadEvent = {
	LOAD_SUCCESS = 0,
	LOAD_ERROR_NO_PERMISSION = 1,
	LOAD_ERROR_RIDEABLE_DOES_NOT_EXIST = 2,
	LOAD_ERROR_TRAILER_DOES_NOT_EXIST = 3,
	LOAD_ERROR_INVALID_CLUSTER = 4,
	LOAD_ERROR_NOT_ENOUGH_ANIMALS = 5,
	LOAD_ERROR_ANIMAL_NOT_SUPPORTED = 6,
	LOAD_ERROR_NOT_ENOUGH_SPACE = 7
}
local AnimalLoadEvent_mt = Class(AnimalLoadEvent, Event)

InitStaticEventClass(AnimalLoadEvent, "AnimalLoadEvent", EventIds.EVENT_ANIMAL_LOAD)

function AnimalLoadEvent.emptyNew()
	local self = Event.new(AnimalLoadEvent_mt)

	return self
end

function AnimalLoadEvent.new(trailer, rideable)
	local self = AnimalLoadEvent.emptyNew()
	self.trailer = trailer
	self.rideable = rideable

	return self
end

function AnimalLoadEvent.newServerToClient(errorCode)
	local self = AnimalLoadEvent.emptyNew()
	self.errorCode = errorCode

	return self
end

function AnimalLoadEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.trailer = NetworkUtil.readNodeObject(streamId)
		self.rideable = NetworkUtil.readNodeObject(streamId)
	else
		self.errorCode = streamReadUIntN(streamId, 3)
	end

	self:run(connection)
end

function AnimalLoadEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.trailer)
		NetworkUtil.writeNodeObject(streamId, self.rideable)
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
	end
end

function AnimalLoadEvent:run(connection)
	if not connection:getIsServer() then
		local uniqueUserId = g_currentMission.userManager:getUniqueUserIdByConnection(connection)
		local farm = g_farmManager:getFarmForUniqueUserId(uniqueUserId)
		local farmId = farm.farmId
		local errorCode = AnimalLoadEvent.validate(self.trailer, self.rideable, farmId)

		if errorCode ~= nil then
			connection:sendEvent(AnimalLoadEvent.newServerToClient(errorCode))

			return
		end

		local cluster = self.rideable:getCluster()

		self.trailer:addCluster(cluster)
		g_currentMission:removeVehicle(self.rideable)
		connection:sendEvent(AnimalLoadEvent.newServerToClient(AnimalLoadEvent.LOAD_SUCCESS))
	else
		g_messageCenter:publish(AnimalLoadEvent, self.errorCode)
	end
end

function AnimalLoadEvent.validate(trailer, rideable, farmId)
	if trailer == nil then
		return AnimalLoadEvent.LOAD_ERROR_TRAILER_DOES_NOT_EXIST
	end

	if rideable == nil then
		return AnimalLoadEvent.LOAD_ERROR_RIDEABLE_DOES_NOT_EXIST
	end

	if not g_currentMission.accessHandler:canFarmAccess(farmId, trailer) then
		return AnimalLoadEvent.LOAD_ERROR_NO_PERMISSION
	end

	if not g_currentMission.accessHandler:canFarmAccess(farmId, rideable) then
		return AnimalLoadEvent.LOAD_ERROR_NO_PERMISSION
	end

	local cluster = rideable:getCluster()

	if cluster == nil then
		return AnimalLoadEvent.LOAD_ERROR_INVALID_CLUSTER
	end

	if cluster:getNumAnimals() == 0 then
		return AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_ANIMALS
	end

	if not trailer:getSupportsAnimalSubType(cluster:getSubTypeIndex()) then
		return AnimalLoadEvent.LOAD_ERROR_ANIMAL_NOT_SUPPORTED
	end

	if trailer:getNumOfFreeAnimalSlots(cluster:getSubTypeIndex()) == 0 then
		return AnimalLoadEvent.LOAD_ERROR_NOT_ENOUGH_SPACE
	end

	return nil
end
