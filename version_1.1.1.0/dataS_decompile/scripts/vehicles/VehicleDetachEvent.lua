VehicleDetachEvent = {}
local VehicleDetachEvent_mt = Class(VehicleDetachEvent, Event)

InitStaticEventClass(VehicleDetachEvent, "VehicleDetachEvent", EventIds.EVENT_VEHICLE_DETACH)

function VehicleDetachEvent.emptyNew()
	local self = Event.new(VehicleDetachEvent_mt)

	return self
end

function VehicleDetachEvent.new(vehicle, implement)
	local self = VehicleDetachEvent.emptyNew()
	self.implement = implement
	self.vehicle = vehicle

	return self
end

function VehicleDetachEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.implement = NetworkUtil.readNodeObject(streamId)

	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		if connection:getIsServer() then
			self.vehicle:detachImplementByObject(self.implement, true)
		else
			self.vehicle:detachImplementByObject(self.implement)
		end
	end
end

function VehicleDetachEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	NetworkUtil.writeNodeObject(streamId, self.implement)
end

function VehicleDetachEvent:run(connection)
end
