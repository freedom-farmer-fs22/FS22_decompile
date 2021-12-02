VehicleBrokenEvent = {}
local VehicleBrokenEvent_mt = Class(VehicleBrokenEvent, Event)

InitStaticEventClass(VehicleBrokenEvent, "VehicleBrokenEvent", EventIds.EVENT_VEHICLE_BROKEN)

function VehicleBrokenEvent.emptyNew()
	local self = Event.new(VehicleBrokenEvent_mt)

	return self
end

function VehicleBrokenEvent.new(object)
	local self = VehicleBrokenEvent.emptyNew()
	self.object = object

	return self
end

function VehicleBrokenEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function VehicleBrokenEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end

function VehicleBrokenEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setBroken()
	end
end
