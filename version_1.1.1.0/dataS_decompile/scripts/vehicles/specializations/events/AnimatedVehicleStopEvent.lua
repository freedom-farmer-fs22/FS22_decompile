AnimatedVehicleStopEvent = {}
local AnimatedVehicleStopEvent_mt = Class(AnimatedVehicleStopEvent, Event)

InitStaticEventClass(AnimatedVehicleStopEvent, "AnimatedVehicleStopEvent", EventIds.EVENT_ANIMATED_VEHICLE_STOP)

function AnimatedVehicleStopEvent.emptyNew()
	local self = Event.new(AnimatedVehicleStopEvent_mt)

	return self
end

function AnimatedVehicleStopEvent.new(object, name)
	local self = AnimatedVehicleStopEvent.emptyNew()
	self.name = name
	self.object = object

	return self
end

function AnimatedVehicleStopEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.name = streamReadString(streamId)

	self:run(connection)
end

function AnimatedVehicleStopEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteString(streamId, self.name)
end

function AnimatedVehicleStopEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:stopAnimation(self.name, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(AnimatedVehicleStopEvent.new(self.object, self.name), nil, connection, self.object)
	end
end
