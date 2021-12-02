WearableRepaintEvent = {}
local WearableRepaintEvent_mt = Class(WearableRepaintEvent, Event)

InitStaticEventClass(WearableRepaintEvent, "WearableRepaintEvent", EventIds.EVENT_WEARABLE_REPAINT)

function WearableRepaintEvent.emptyNew()
	return Event.new(WearableRepaintEvent_mt)
end

function WearableRepaintEvent.new(vehicle)
	local self = WearableRepaintEvent.emptyNew()
	self.vehicle = vehicle

	return self
end

function WearableRepaintEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function WearableRepaintEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
end

function WearableRepaintEvent:run(connection)
	if not connection:getIsServer() then
		if self.vehicle ~= nil and self.vehicle:getIsSynchronized() and self.vehicle.repaintVehicle ~= nil then
			self.vehicle:repaintVehicle()
			g_server:broadcastEvent(self)
			g_messageCenter:publish(MessageType.VEHICLE_REPAINTED, self.vehicle)
		end
	else
		g_messageCenter:publish(MessageType.VEHICLE_REPAINTED, self.vehicle)
	end
end
