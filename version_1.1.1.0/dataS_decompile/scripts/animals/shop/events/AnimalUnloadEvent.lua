AnimalUnloadEvent = {
	UNLOAD_SUCCESS = 0,
	UNLOAD_ERROR_NO_PERMISSION = 1,
	UNLOAD_ERROR_INVALID_CLUSTER = 2,
	UNLOAD_ERROR_NOT_ENOUGH_ANIMALS = 3,
	UNLOAD_ERROR_DOES_NOT_SUPPORT_UNLOADING = 4,
	UNLOAD_ERROR_TRAILER_DOES_NOT_EXIST = 5,
	UNLOAD_ERROR_NO_SPACE = 6,
	UNLOAD_ERROR_COULD_NOT_BE_LOADED = 7,
	UNLOAD_ERROR_RIDEABLE_LIMIT_REACHED = 8,
	SEND_NUM_BITS = 4
}
local AnimalUnloadEvent_mt = Class(AnimalUnloadEvent, Event)

InitStaticEventClass(AnimalUnloadEvent, "AnimalUnloadEvent", EventIds.EVENT_ANIMAL_UNLOAD)

function AnimalUnloadEvent.emptyNew()
	local self = Event.new(AnimalUnloadEvent_mt)

	return self
end

function AnimalUnloadEvent.new(trailer, clusterId)
	local self = AnimalUnloadEvent.emptyNew()
	self.trailer = trailer
	self.clusterId = clusterId

	return self
end

function AnimalUnloadEvent.newServerToClient(errorCode)
	local self = AnimalUnloadEvent.emptyNew()
	self.errorCode = errorCode

	return self
end

function AnimalUnloadEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.trailer = NetworkUtil.readNodeObject(streamId)
		self.clusterId = streamReadInt32(streamId)
	else
		self.errorCode = streamReadUIntN(streamId, AnimalUnloadEvent.SEND_NUM_BITS)
	end

	self:run(connection)
end

function AnimalUnloadEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.trailer)
		streamWriteInt32(streamId, self.clusterId)
	else
		streamWriteUIntN(streamId, self.errorCode, AnimalUnloadEvent.SEND_NUM_BITS)
	end
end

function AnimalUnloadEvent:run(connection)
	if not connection:getIsServer() then
		local errorCode = AnimalUnloadEvent.validate(self.trailer, self.clusterId)

		if errorCode ~= nil then
			connection:sendEvent(AnimalUnloadEvent.newServerToClient(errorCode))

			return
		end

		local cluster = self.trailer:getClusterById(self.clusterId)
		local filename = cluster:getRidableFilename()
		local size = StoreItemUtil.getSizeValues(filename, "vehicle", 0, {})
		local x, _, z, place, _, _ = PlacementUtil.getPlace(self.trailer:getAnimalUnloadPlaces(), size, {}, true, true, true)

		if x == nil then
			connection:sendEvent(AnimalUnloadEvent.newServerToClient(AnimalUnloadEvent.UNLOAD_ERROR_NO_SPACE))

			return
		end

		local location = {
			x = x,
			z = z,
			yRot = place.rotY
		}
		local farmId = self.trailer:getOwnerFarmId()

		VehicleLoadingUtil.loadVehicle(filename, location, true, 0, Vehicle.PROPERTY_STATE_OWNED, farmId, nil, , self.onLoadedRideable, self, {
			cluster,
			connection,
			self.trailer
		})
	else
		g_messageCenter:publish(AnimalUnloadEvent, self.errorCode)
	end
end

function AnimalUnloadEvent:onLoadedRideable(rideableVehicle, vehicleLoadState, arguments)
	local cluster, connection, trailer = unpack(arguments)

	if rideableVehicle == nil then
		connection:sendEvent(AnimalUnloadEvent.newServerToClient(AnimalUnloadEvent.UNLOAD_ERROR_COULD_NOT_BE_LOADED))

		return
	end

	if vehicleLoadState ~= VehicleLoadingUtil.VEHICLE_LOAD_OK then
		rideableVehicle:delete()
		connection:sendEvent(AnimalUnloadEvent.newServerToClient(AnimalUnloadEvent.UNLOAD_ERROR_COULD_NOT_BE_LOADED))

		return
	end

	local newCluster = cluster:clone()

	newCluster:changeNumAnimals(1)
	rideableVehicle:setCluster(newCluster)

	local clusterSystem = trailer:getClusterSystem()

	cluster:changeNumAnimals(-1)
	clusterSystem:updateNow()
	connection:sendEvent(AnimalUnloadEvent.newServerToClient(AnimalUnloadEvent.UNLOAD_SUCCESS))
end

function AnimalUnloadEvent.validate(trailer, clusterId)
	if trailer == nil then
		return AnimalUnloadEvent.UNLOAD_ERROR_TRAILER_DOES_NOT_EXIST
	end

	local cluster = trailer:getClusterById(clusterId)

	if cluster == nil then
		return AnimalUnloadEvent.UNLOAD_ERROR_INVALID_CLUSTER
	end

	if cluster:getNumAnimals() == 0 then
		return AnimalUnloadEvent.UNLOAD_ERROR_NOT_ENOUGH_ANIMALS
	end

	local filename = cluster:getRidableFilename()

	if filename == nil then
		return AnimalUnloadEvent.UNLOAD_ERROR_DOES_NOT_SUPPORT_UNLOADING
	end

	local farmId = trailer:getOwnerFarmId()

	if not g_currentMission.husbandrySystem:getCanAddRideable(farmId) then
		return AnimalUnloadEvent.UNLOAD_ERROR_RIDEABLE_LIMIT_REACHED
	end

	return nil
end
