VehicleSaleSetEvent = {}
local VehicleSaleSetEvent_mt = Class(VehicleSaleSetEvent, Event)

InitStaticEventClass(VehicleSaleSetEvent, "VehicleSaleSetEvent", EventIds.EVENT_VEHICLE_SALE_SET)

function VehicleSaleSetEvent.emptyNew()
	local self = Event.new(VehicleSaleSetEvent_mt)

	return self
end

function VehicleSaleSetEvent.new(vehicle, saleItem)
	local self = VehicleSaleSetEvent.emptyNew()
	self.vehicle = vehicle
	self.saleItem = saleItem

	return self
end

function VehicleSaleSetEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.saleItem = g_currentMission.vehicleSaleSystem:getSaleById(streamReadUInt8(streamId))

	self:run(connection)
end

function VehicleSaleSetEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUInt8(streamId, self.saleItem.id)
end

function VehicleSaleSetEvent:run(connection)
	if connection:getIsServer() then
		g_currentMission.vehicleSaleSystem:setVehicleState(self.vehicle, self.saleItem, true)
	end
end
