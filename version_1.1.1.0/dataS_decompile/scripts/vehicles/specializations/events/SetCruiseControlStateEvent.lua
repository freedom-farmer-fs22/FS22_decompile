SetCruiseControlStateEvent = {}
local SetCruiseControlStateEvent_mt = Class(SetCruiseControlStateEvent, Event)

InitStaticEventClass(SetCruiseControlStateEvent, "SetCruiseControlStateEvent", EventIds.EVENT_CRUISECONTROL_SET_STATE)

function SetCruiseControlStateEvent.emptyNew()
	local self = Event.new(SetCruiseControlStateEvent_mt)

	return self
end

function SetCruiseControlStateEvent.new(vehicle, state)
	local self = SetCruiseControlStateEvent.emptyNew()
	self.state = state
	self.vehicle = vehicle

	return self
end

function SetCruiseControlStateEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadUIntN(streamId, 2)

	self:run(connection)
end

function SetCruiseControlStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUIntN(streamId, self.state, 2)
end

function SetCruiseControlStateEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setCruiseControlState(self.state, true)
	end
end
