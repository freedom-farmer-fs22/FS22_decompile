LocomotiveStateEvent = {}
local LocomotiveStateEvent_mt = Class(LocomotiveStateEvent, Event)

InitStaticEventClass(LocomotiveStateEvent, "LocomotiveStateEvent", EventIds.EVENT_TRAIN_LOCOMOTIVE_STATE)

function LocomotiveStateEvent.emptyNew()
	local self = Event.new(LocomotiveStateEvent_mt)

	return self
end

function LocomotiveStateEvent.new(object, state)
	local self = LocomotiveStateEvent.emptyNew()
	self.object = object
	self.state = state

	return self
end

function LocomotiveStateEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadUIntN(streamId, Locomotive.NUM_BITS_STATE)

	self:run(connection)
end

function LocomotiveStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.state, Locomotive.NUM_BITS_STATE)
end

function LocomotiveStateEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setLocomotiveState(self.state, true)
	end
end
