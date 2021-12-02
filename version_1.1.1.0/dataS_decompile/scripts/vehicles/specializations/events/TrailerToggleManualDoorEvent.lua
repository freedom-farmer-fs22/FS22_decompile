TrailerToggleManualDoorEvent = {}
local TrailerToggleManualDoorEvent_mt = Class(TrailerToggleManualDoorEvent, Event)

InitStaticEventClass(TrailerToggleManualDoorEvent, "TrailerToggleManualDoorEvent", EventIds.EVENT_TRAILER_TOGGLE_MANUAL_DOOR)

function TrailerToggleManualDoorEvent.emptyNew()
	local self = Event.new(TrailerToggleManualDoorEvent_mt)

	return self
end

function TrailerToggleManualDoorEvent.new(object, state)
	local self = TrailerToggleManualDoorEvent.emptyNew()
	self.object = object
	self.state = state

	return self
end

function TrailerToggleManualDoorEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)

	self:run(connection)
end

function TrailerToggleManualDoorEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.state)
end

function TrailerToggleManualDoorEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setTrailerDoorState(self.state, true)
	end
end

function TrailerToggleManualDoorEvent.sendEvent(vehicle, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(TrailerToggleManualDoorEvent.new(vehicle, state), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(TrailerToggleManualDoorEvent.new(vehicle, state))
		end
	end
end
