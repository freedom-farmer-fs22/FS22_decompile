PlowRotationEvent = {}
local PlowRotationEvent_mt = Class(PlowRotationEvent, Event)

InitStaticEventClass(PlowRotationEvent, "PlowRotationEvent", EventIds.EVENT_PLOW_ROTATION)

function PlowRotationEvent.emptyNew()
	local self = Event.new(PlowRotationEvent_mt)

	return self
end

function PlowRotationEvent.new(object, rotationMax)
	local self = PlowRotationEvent.emptyNew()
	self.object = object
	self.rotationMax = rotationMax

	return self
end

function PlowRotationEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.rotationMax = streamReadBool(streamId)

	self:run(connection)
end

function PlowRotationEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.rotationMax)
end

function PlowRotationEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setRotationMax(self.rotationMax, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(PlowRotationEvent.new(self.object, self.rotationMax), nil, connection, self.object)
	end
end
