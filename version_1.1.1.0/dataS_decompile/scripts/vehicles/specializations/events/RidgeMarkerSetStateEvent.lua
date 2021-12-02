RidgeMarkerSetStateEvent = {}
local RidgeMarkerSetStateEvent_mt = Class(RidgeMarkerSetStateEvent, Event)

InitStaticEventClass(RidgeMarkerSetStateEvent, "RidgeMarkerSetStateEvent", EventIds.EVENT_RIDGE_MARKER_SET_STATE)

function RidgeMarkerSetStateEvent.emptyNew()
	local self = Event.new(RidgeMarkerSetStateEvent_mt)

	return self
end

function RidgeMarkerSetStateEvent.new(vehicle, state)
	local self = RidgeMarkerSetStateEvent.emptyNew()
	self.vehicle = vehicle
	self.state = state

	assert(state >= 0 and state < RidgeMarker.MAX_NUM_RIDGEMARKERS)

	return self
end

function RidgeMarkerSetStateEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadUIntN(streamId, RidgeMarker.SEND_NUM_BITS)

	self:run(connection)
end

function RidgeMarkerSetStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUIntN(streamId, self.state, RidgeMarker.SEND_NUM_BITS)
end

function RidgeMarkerSetStateEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setRidgeMarkerState(self.state, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(RidgeMarkerSetStateEvent.new(self.vehicle, self.state), nil, connection, self.vehicle)
	end
end

function RidgeMarkerSetStateEvent.sendEvent(vehicle, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(RidgeMarkerSetStateEvent.new(vehicle, state), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(RidgeMarkerSetStateEvent.new(vehicle, state))
		end
	end
end
