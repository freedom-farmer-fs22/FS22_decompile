InlineWrapperPushOffEvent = {}
local InlineWrapperPushOffEvent_mt = Class(InlineWrapperPushOffEvent, Event)

InitStaticEventClass(InlineWrapperPushOffEvent, "InlineWrapperPushOffEvent", EventIds.EVENT_INLINE_WRAPPER_PUSH_OFF)

function InlineWrapperPushOffEvent.emptyNew()
	local self = Event.new(InlineWrapperPushOffEvent_mt)

	return self
end

function InlineWrapperPushOffEvent.new(inlineWrapper)
	local self = InlineWrapperPushOffEvent.emptyNew()
	self.inlineWrapper = inlineWrapper

	return self
end

function InlineWrapperPushOffEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.inlineWrapper = NetworkUtil.readNodeObject(streamId)
	end

	self:run(connection)
end

function InlineWrapperPushOffEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.inlineWrapper)
	end
end

function InlineWrapperPushOffEvent:run(connection)
	if not connection:getIsServer() and self.inlineWrapper ~= nil and self.inlineWrapper:getIsSynchronized() then
		self.inlineWrapper:pushOffInlineBale()
	end
end
