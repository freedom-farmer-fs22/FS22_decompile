ReceivingHopperSetCreateBoxesEvent = {}
local ReceivingHopperSetCreateBoxesEvent_mt = Class(ReceivingHopperSetCreateBoxesEvent, Event)

InitStaticEventClass(ReceivingHopperSetCreateBoxesEvent, "ReceivingHopperSetCreateBoxesEvent", EventIds.EVENT_RECEIVINGHOPPER_SET_CREATE_BOXES)

function ReceivingHopperSetCreateBoxesEvent.emptyNew()
	local self = Event.new(ReceivingHopperSetCreateBoxesEvent_mt)

	return self
end

function ReceivingHopperSetCreateBoxesEvent.new(object, state)
	local self = ReceivingHopperSetCreateBoxesEvent.emptyNew()
	self.object = object
	self.state = state

	return self
end

function ReceivingHopperSetCreateBoxesEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)

	self:run(connection)
end

function ReceivingHopperSetCreateBoxesEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.state)
end

function ReceivingHopperSetCreateBoxesEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setCreateBoxes(self.state, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(ReceivingHopperSetCreateBoxesEvent.new(self.object, self.state), nil, connection, self.object)
	end
end

function ReceivingHopperSetCreateBoxesEvent.sendEvent(vehicle, state, noEventSend)
	if state ~= vehicle.state and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(ReceivingHopperSetCreateBoxesEvent.new(vehicle, state), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(ReceivingHopperSetCreateBoxesEvent.new(vehicle, state))
		end
	end
end
