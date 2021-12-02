VehicleRemoveEvent = {}
local VehicleRemoveEvent_mt = Class(VehicleRemoveEvent, Event)

InitStaticEventClass(VehicleRemoveEvent, "VehicleRemoveEvent", EventIds.EVENT_VEHICLE_REMOVE)

function VehicleRemoveEvent.emptyNew()
	local self = Event.new(VehicleRemoveEvent_mt)

	return self
end

function VehicleRemoveEvent.new(vehicle)
	local self = VehicleRemoveEvent.emptyNew()
	self.vehicle = vehicle

	assert(g_server == nil, "Client->Server event")

	return self
end

function VehicleRemoveEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function VehicleRemoveEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
end

function VehicleRemoveEvent:run(connection)
	g_currentMission:removeVehicle(self.vehicle)
end
