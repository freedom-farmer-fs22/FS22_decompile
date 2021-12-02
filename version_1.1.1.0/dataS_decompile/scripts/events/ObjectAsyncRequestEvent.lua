ObjectAsyncRequestEvent = {}
local ObjectAsyncRequestEvent_mt = Class(ObjectAsyncRequestEvent, Event)

InitStaticEventClass(ObjectAsyncRequestEvent, "ObjectAsyncRequestEvent", EventIds.EVENT_OBJECT_ASYNC_REQUEST)

function ObjectAsyncRequestEvent.emptyNew()
	local self = Event.new(ObjectAsyncRequestEvent_mt)

	return self
end

function ObjectAsyncRequestEvent.new(object)
	local self = ObjectAsyncRequestEvent.emptyNew()
	self.object = object

	return self
end

function ObjectAsyncRequestEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function ObjectAsyncRequestEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
end

function ObjectAsyncRequestEvent:run(connection)
	if not connection:getIsServer() and self.object ~= nil then
		g_server:broadcastEvent(ObjectAsyncStreamEvent.new(self.object), false, nil, , , {
			connection
		})
	end
end
