VehicleSaleRemoveEvent = {}
local VehicleSaleRemoveEvent_mt = Class(VehicleSaleRemoveEvent, Event)

InitStaticEventClass(VehicleSaleRemoveEvent, "VehicleSaleRemoveEvent", EventIds.EVENT_VEHICLE_SALE_REMOVE)

function VehicleSaleRemoveEvent.emptyNew()
	local self = Event.new(VehicleSaleRemoveEvent_mt)

	return self
end

function VehicleSaleRemoveEvent.new(saleItemId)
	local self = VehicleSaleRemoveEvent.emptyNew()
	self.saleItemId = saleItemId

	return self
end

function VehicleSaleRemoveEvent:readStream(streamId, connection)
	self.saleItemId = streamReadUInt8(streamId)

	self:run(connection)
end

function VehicleSaleRemoveEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.saleItemId)
end

function VehicleSaleRemoveEvent:run(connection)
	if connection:getIsServer() then
		g_currentMission.vehicleSaleSystem:removeSaleWithId(self.saleItemId, true)
	end
end
