WearableRepairEvent = {}
local WearableRepairEvent_mt = Class(WearableRepairEvent, Event)

InitStaticEventClass(WearableRepairEvent, "WearableRepairEvent", EventIds.EVENT_WEARABLE_REPAIR)

function WearableRepairEvent.emptyNew()
	return Event.new(WearableRepairEvent_mt)
end

function WearableRepairEvent.new(vehicle, atSellingPoint)
	local self = WearableRepairEvent.emptyNew()
	self.vehicle = vehicle
	self.atSellingPoint = atSellingPoint

	return self
end

function WearableRepairEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.atSellingPoint = streamReadBool(streamId)

	self:run(connection)
end

function WearableRepairEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.atSellingPoint)
end

function WearableRepairEvent:run(connection)
	if not connection:getIsServer() then
		if self.vehicle ~= nil and self.vehicle:getIsSynchronized() and self.vehicle.repairVehicle ~= nil then
			self.vehicle:repairVehicle(self.atSellingPoint)
			g_server:broadcastEvent(self)
			g_messageCenter:publish(MessageType.VEHICLE_REPAIRED, self.vehicle, self.atSellingPoint)
		end
	else
		g_messageCenter:publish(MessageType.VEHICLE_REPAIRED, self.vehicle, self.atSellingPoint)
	end
end
