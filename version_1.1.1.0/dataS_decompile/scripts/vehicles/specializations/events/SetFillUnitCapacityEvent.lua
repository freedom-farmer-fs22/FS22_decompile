SetFillUnitCapacityEvent = {}
local SetFillUnitCapacityEvent_mt = Class(SetFillUnitCapacityEvent, Event)

InitStaticEventClass(SetFillUnitCapacityEvent, "SetFillUnitCapacityEvent", EventIds.EVENT_SET_FILLUNIT_CAPACITY)

function SetFillUnitCapacityEvent.emptyNew()
	local self = Event.new(SetFillUnitCapacityEvent_mt)

	return self
end

function SetFillUnitCapacityEvent.new(vehicle, fillUnitIndex, capacity)
	local self = SetFillUnitCapacityEvent.emptyNew()
	self.vehicle = vehicle
	self.fillUnitIndex = fillUnitIndex
	self.capacity = capacity

	return self
end

function SetFillUnitCapacityEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.fillUnitIndex = streamReadUIntN(streamId, 8)
	self.capacity = streamReadFloat32(streamId)

	self:run(connection)
end

function SetFillUnitCapacityEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUIntN(streamId, self.fillUnitIndex, 8)
	streamWriteFloat32(streamId, self.capacity)
end

function SetFillUnitCapacityEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setFillUnitCapacity(self.fillUnitIndex, self.capacity, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(SetFillUnitCapacityEvent.new(self.vehicle, self.fillUnitIndex, self.capacity), nil, connection, self.vehicle)
	end
end

function SetFillUnitCapacityEvent.sendEvent(vehicle, fillUnitIndex, capacity, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetFillUnitCapacityEvent.new(vehicle, fillUnitIndex, capacity), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(SetFillUnitCapacityEvent.new(vehicle, fillUnitIndex, capacity))
		end
	end
end
