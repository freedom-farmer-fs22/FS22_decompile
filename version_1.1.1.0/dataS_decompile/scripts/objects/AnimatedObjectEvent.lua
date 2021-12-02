AnimatedObjectEvent = {}
local AnimatedObjectEvent_mt = Class(AnimatedObjectEvent, Event)

InitStaticEventClass(AnimatedObjectEvent, "AnimatedObjectEvent", EventIds.EVENT_ANIMATED_OBJECT)

function AnimatedObjectEvent.emptyNew()
	local self = Event.new(AnimatedObjectEvent_mt)

	return self
end

function AnimatedObjectEvent.new(animatedObject, direction)
	local self = AnimatedObjectEvent.emptyNew()
	self.animatedObject = animatedObject
	self.direction = direction

	return self
end

function AnimatedObjectEvent:readStream(streamId, connection)
	assert(g_currentMission:getIsServer())

	self.animatedObject = NetworkUtil.readNodeObject(streamId)
	self.direction = streamReadUIntN(streamId, 2) - 1

	self:run(connection)
end

function AnimatedObjectEvent:writeStream(streamId, connection)
	assert(connection:getIsServer())
	NetworkUtil.writeNodeObject(streamId, self.animatedObject)
	streamWriteUIntN(streamId, self.direction + 1, 2)
end

function AnimatedObjectEvent:run(connection)
	self.animatedObject:setDirection(self.direction)
end
