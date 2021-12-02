PlaceableFenceAddGateEvent = {}
local PlaceableFenceAddGateEvent_mt = Class(PlaceableFenceAddGateEvent, Event)

InitStaticEventClass(PlaceableFenceAddGateEvent, "PlaceableFenceAddGateEvent", EventIds.EVENT_PLACEABLE_FENCE_GATE_ADD)

function PlaceableFenceAddGateEvent.emptyNew()
	return Event.new(PlaceableFenceAddGateEvent_mt)
end

function PlaceableFenceAddGateEvent.new(fence, segmentIndex, animatedObject)
	local self = PlaceableFenceAddGateEvent.emptyNew()
	self.fence = fence
	self.segmentIndex = segmentIndex
	self.animatedObject = animatedObject

	return self
end

function PlaceableFenceAddGateEvent:readStream(streamId, connection)
	self.fence = NetworkUtil.readNodeObject(streamId)
	self.segmentIndex = streamReadInt32(streamId)
	self.animatedObject = self.fence:getSegment(self.segmentIndex).animatedObject
	local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)

	self.animatedObject:readStream(streamId, connection)
	g_client:finishRegisterObject(self.animatedObject, animatedObjectId)
	self:run(connection)
end

function PlaceableFenceAddGateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.fence)
	streamWriteInt32(streamId, self.segmentIndex)
	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.animatedObject))
	self.animatedObject:writeStream(streamId, connection)
	g_server:registerObjectInStream(connection, self.animatedObject)
end

function PlaceableFenceAddGateEvent:run(connection)
end
