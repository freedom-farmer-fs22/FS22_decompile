SetCoverStateEvent = {}
local SetCoverStateEvent_mt = Class(SetCoverStateEvent, Event)

InitStaticEventClass(SetCoverStateEvent, "SetCoverStateEvent", EventIds.EVENT_SET_COVER_STATE)

function SetCoverStateEvent.emptyNew()
	return Event.new(SetCoverStateEvent_mt)
end

function SetCoverStateEvent.new(vehicle, state)
	local self = SetCoverStateEvent.emptyNew()
	self.vehicle = vehicle
	self.state = state

	return self
end

function SetCoverStateEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadUIntN(streamId, Cover.SEND_NUM_BITS)

	self:run(connection)
end

function SetCoverStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUIntN(streamId, self.state, Cover.SEND_NUM_BITS)
end

function SetCoverStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.vehicle)
	end

	if self.vehicle ~= nil and self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setCoverState(self.state, true)
	end
end

function SetCoverStateEvent.sendEvent(vehicle, state, noEventSend)
	if vehicle.spec_cover.state ~= state and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(SetCoverStateEvent.new(vehicle, state), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(SetCoverStateEvent.new(vehicle, state))
		end
	end
end
