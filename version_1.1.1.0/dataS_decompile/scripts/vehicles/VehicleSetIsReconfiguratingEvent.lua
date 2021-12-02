VehicleSetIsReconfiguratingEvent = {}
local VehicleSetIsReconfiguratingEvent_mt = Class(VehicleSetIsReconfiguratingEvent, Event)

InitStaticEventClass(VehicleSetIsReconfiguratingEvent, "VehicleSetIsReconfiguratingEvent", EventIds.EVENT_VEHICLE_SET_IS_RECONFIGURATING)

function VehicleSetIsReconfiguratingEvent.emptyNew()
	local self = Event.new(VehicleSetIsReconfiguratingEvent_mt)

	return self
end

function VehicleSetIsReconfiguratingEvent.new(object)
	local self = VehicleSetIsReconfiguratingEvent.emptyNew()
	self.object = object

	return self
end

function VehicleSetIsReconfiguratingEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object.isReconfigurating = true
	end
end

function VehicleSetIsReconfiguratingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end
