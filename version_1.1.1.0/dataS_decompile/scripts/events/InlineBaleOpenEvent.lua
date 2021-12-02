InlineBaleOpenEvent = {}
local InlineBaleOpenEvent_mt = Class(InlineBaleOpenEvent, Event)

InitStaticEventClass(InlineBaleOpenEvent, "InlineBaleOpenEvent", EventIds.EVENT_OPEN_INLINE_BALE)

function InlineBaleOpenEvent.emptyNew()
	local self = Event.new(InlineBaleOpenEvent_mt)

	return self
end

function InlineBaleOpenEvent.new(inlineBale, x, y, z)
	local self = InlineBaleOpenEvent.emptyNew()
	self.inlineBale = inlineBale
	self.x = x
	self.y = y
	self.z = z

	return self
end

function InlineBaleOpenEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.inlineBale = NetworkUtil.readNodeObject(streamId)
		self.x = streamReadFloat32(streamId)
		self.y = streamReadFloat32(streamId)
		self.z = streamReadFloat32(streamId)
	end

	self:run(connection)
end

function InlineBaleOpenEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.inlineBale)
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
	end
end

function InlineBaleOpenEvent:run(connection)
	if not connection:getIsServer() then
		self.inlineBale:openBaleAtPosition(self.x, self.y, self.z)
	end
end
