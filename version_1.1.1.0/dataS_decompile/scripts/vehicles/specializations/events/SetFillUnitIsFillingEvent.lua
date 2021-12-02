SetFillUnitIsFillingEvent = {}
local SetFillUnitIsFillingEvent_mt = Class(SetFillUnitIsFillingEvent, Event)

InitStaticEventClass(SetFillUnitIsFillingEvent, "SetFillUnitIsFillingEvent", EventIds.EVENT_SET_FILLUNIT_IS_FILLING)

function SetFillUnitIsFillingEvent.emptyNew()
	local self = Event.new(SetFillUnitIsFillingEvent_mt)

	return self
end

function SetFillUnitIsFillingEvent.new(vehicle, isFilling)
	local self = SetFillUnitIsFillingEvent.emptyNew()
	self.vehicle = vehicle
	self.isFilling = isFilling

	return self
end

function SetFillUnitIsFillingEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.isFilling = streamReadBool(streamId)

	self:run(connection)
end

function SetFillUnitIsFillingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.isFilling)
end

function SetFillUnitIsFillingEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setFillUnitIsFilling(self.isFilling, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(SetFillUnitIsFillingEvent.new(self.vehicle, self.isFilling), nil, connection, self.vehicle)
	end
end
