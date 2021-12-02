PickupSetStateEvent = {}
local PickupSetStateEvent_mt = Class(PickupSetStateEvent, Event)

InitStaticEventClass(PickupSetStateEvent, "PickupSetStateEvent", EventIds.EVENT_SET_PICKUP_STATE)

function PickupSetStateEvent.emptyNew()
	local self = Event.new(PickupSetStateEvent_mt)

	return self
end

function PickupSetStateEvent.new(object, isPickupLowered)
	local self = PickupSetStateEvent.emptyNew()
	self.object = object
	self.isPickupLowered = isPickupLowered

	return self
end

function PickupSetStateEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.isPickupLowered = streamReadBool(streamId)

	self:run(connection)
end

function PickupSetStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.isPickupLowered)
end

function PickupSetStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setPickupState(self.isPickupLowered, true)
	end
end

function PickupSetStateEvent.sendEvent(vehicle, isPickupLowered, noEventSend)
	if isPickupLowered ~= vehicle.spec_pickup.isLowered and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(PickupSetStateEvent.new(vehicle, isPickupLowered), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(PickupSetStateEvent.new(vehicle, isPickupLowered))
		end
	end
end
