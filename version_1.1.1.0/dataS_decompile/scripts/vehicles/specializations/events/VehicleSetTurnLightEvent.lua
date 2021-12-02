VehicleSetTurnLightEvent = {}
local VehicleSetTurnLightEvent_mt = Class(VehicleSetTurnLightEvent, Event)

InitStaticEventClass(VehicleSetTurnLightEvent, "VehicleSetTurnLightEvent", EventIds.EVENT_VEHICLE_SET_TURNLIGHT)

function VehicleSetTurnLightEvent.emptyNew()
	local self = Event.new(VehicleSetTurnLightEvent_mt)

	return self
end

function VehicleSetTurnLightEvent.new(object, state)
	local self = VehicleSetTurnLightEvent.emptyNew()
	self.object = object
	self.state = state

	assert(state >= 0 and state <= Lights.TURNLIGHT_HAZARD)

	return self
end

function VehicleSetTurnLightEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadUIntN(streamId, Lights.turnLightSendNumBits)

	self:run(connection)
end

function VehicleSetTurnLightEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.state, Lights.turnLightSendNumBits)
end

function VehicleSetTurnLightEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setTurnLightState(self.state, true, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(VehicleSetTurnLightEvent.new(self.object, self.state), nil, connection, self.object)
	end
end
