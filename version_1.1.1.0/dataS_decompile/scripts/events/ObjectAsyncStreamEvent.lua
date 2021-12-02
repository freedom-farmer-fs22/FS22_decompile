ObjectAsyncStreamEvent = {}
local ObjectAsyncStreamEvent_mt = Class(ObjectAsyncStreamEvent, Event)

InitStaticEventClass(ObjectAsyncStreamEvent, "ObjectAsyncStreamEvent", EventIds.EVENT_OBJECT_ASYNC_STREAM)

function ObjectAsyncStreamEvent.emptyNew()
	local self = Event.new(ObjectAsyncStreamEvent_mt)

	return self
end

function ObjectAsyncStreamEvent.new(object)
	local self = ObjectAsyncStreamEvent.emptyNew()
	self.object = object

	return self
end

function ObjectAsyncStreamEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)

	self.object:postReadStream(streamId, connection)
end

function ObjectAsyncStreamEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	self.object:postWriteStream(streamId, connection)
end
