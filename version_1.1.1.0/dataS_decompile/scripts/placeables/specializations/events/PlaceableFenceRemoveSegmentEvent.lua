PlaceableFenceRemoveSegmentEvent = {}
local PlaceableFenceRemoveSegmentEvent_mt = Class(PlaceableFenceRemoveSegmentEvent, Event)

InitStaticEventClass(PlaceableFenceRemoveSegmentEvent, "PlaceableFenceRemoveSegmentEvent", EventIds.EVENT_PLACEABLE_FENCE_SEGMENT_REMOVE)

function PlaceableFenceRemoveSegmentEvent.emptyNew()
	return Event.new(PlaceableFenceRemoveSegmentEvent_mt)
end

function PlaceableFenceRemoveSegmentEvent.new(fence, segmentIndex, poleIndex)
	local self = PlaceableFenceRemoveSegmentEvent.emptyNew()
	self.fence = fence
	self.segmentIndex = segmentIndex
	self.poleIndex = poleIndex

	return self
end

function PlaceableFenceRemoveSegmentEvent:readStream(streamId, connection)
	self.fence = NetworkUtil.readNodeObject(streamId)
	self.segmentIndex = streamReadInt32(streamId)
	self.poleIndex = streamReadInt32(streamId)

	self:run(connection)
end

function PlaceableFenceRemoveSegmentEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.fence)
	streamWriteInt32(streamId, self.segmentIndex)
	streamWriteInt32(streamId, self.poleIndex)
end

function PlaceableFenceRemoveSegmentEvent:run(connection)
	if self.fence ~= nil and self.fence:getIsSynchronized() then
		local spec = self.fence.spec_fence

		self.fence:doDeletePanel(spec.segments[self.segmentIndex], self.segmentIndex, self.poleIndex)
		g_messageCenter:publish(PlaceableFenceRemoveSegmentEvent, self.fence, self.segmentIndex, self.poleIndex)

		if not connection:getIsServer() then
			g_server:broadcastEvent(self)
		end
	end
end
