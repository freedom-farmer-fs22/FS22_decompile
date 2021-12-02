SetDischargeStateEvent = {}
local SetDischargeStateEvent_mt = Class(SetDischargeStateEvent, Event)

InitStaticEventClass(SetDischargeStateEvent, "SetDischargeStateEvent", EventIds.EVENT_SET_DISCHARGE_STATE)

function SetDischargeStateEvent.emptyNew()
	local self = Event.new(SetDischargeStateEvent_mt)

	return self
end

function SetDischargeStateEvent.new(vehicle, state)
	local self = SetDischargeStateEvent.emptyNew()
	self.vehicle = vehicle
	self.state = state

	return self
end

function SetDischargeStateEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadUIntN(streamId, 2)

	self:run(connection)
end

function SetDischargeStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUIntN(streamId, self.state, 2)
end

function SetDischargeStateEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setDischargeState(self.state, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(SetDischargeStateEvent.new(self.vehicle, self.state), nil, connection, self.vehicle)
	end
end

function SetDischargeStateEvent.sendEvent(vehicle, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetDischargeStateEvent.new(vehicle, state), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(SetDischargeStateEvent.new(vehicle, state))
		end
	end
end
