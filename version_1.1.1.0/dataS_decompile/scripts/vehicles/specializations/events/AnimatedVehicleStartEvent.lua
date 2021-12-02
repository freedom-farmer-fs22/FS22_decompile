AnimatedVehicleStartEvent = {}
local AnimatedVehicleStartEvent_mt = Class(AnimatedVehicleStartEvent, Event)

InitStaticEventClass(AnimatedVehicleStartEvent, "AnimatedVehicleStartEvent", EventIds.EVENT_ANIMATED_VEHICLE_START)

function AnimatedVehicleStartEvent.emptyNew()
	local self = Event.new(AnimatedVehicleStartEvent_mt)

	return self
end

function AnimatedVehicleStartEvent.new(object, name, speed, animTime)
	local self = AnimatedVehicleStartEvent.emptyNew()
	self.name = name
	self.speed = speed
	self.animTime = animTime
	self.object = object

	return self
end

function AnimatedVehicleStartEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.name = streamReadString(streamId)
	self.speed = streamReadFloat32(streamId)
	self.animTime = streamReadFloat32(streamId)

	self:run(connection)
end

function AnimatedVehicleStartEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteString(streamId, self.name)
	streamWriteFloat32(streamId, self.speed)
	streamWriteFloat32(streamId, self.animTime)
end

function AnimatedVehicleStartEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:playAnimation(self.name, self.speed, self.animTime, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(AnimatedVehicleStartEvent.new(self.object, self.name, self.speed, self.animTime), nil, connection, self.object)
	end
end
