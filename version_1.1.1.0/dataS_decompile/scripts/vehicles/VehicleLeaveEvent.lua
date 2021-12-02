VehicleLeaveEvent = {}
local VehicleLeaveEvent_mt = Class(VehicleLeaveEvent, Event)

InitStaticEventClass(VehicleLeaveEvent, "VehicleLeaveEvent", EventIds.EVENT_VEHICLE_LEAVE)

function VehicleLeaveEvent.emptyNew()
	local self = Event.new(VehicleLeaveEvent_mt)

	return self
end

function VehicleLeaveEvent.new(object)
	local self = VehicleLeaveEvent.emptyNew()
	self.object = object

	return self
end

function VehicleLeaveEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function VehicleLeaveEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end

function VehicleLeaveEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		if not connection:getIsServer() then
			if self.object.owner ~= nil then
				self.object:setOwner(nil)

				self.object.controllerFarmId = nil
			end

			g_server:broadcastEvent(VehicleLeaveEvent.new(self.object), nil, connection, self.object)
		end

		self.object:leaveVehicle()
	end
end
