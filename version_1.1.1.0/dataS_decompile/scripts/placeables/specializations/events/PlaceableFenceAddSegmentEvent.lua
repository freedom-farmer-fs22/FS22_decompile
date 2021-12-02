PlaceableFenceAddSegmentEvent = {}
local PlaceableFenceAddSegmentEvent_mt = Class(PlaceableFenceAddSegmentEvent, Event)

InitStaticEventClass(PlaceableFenceAddSegmentEvent, "PlaceableFenceAddSegmentEvent", EventIds.EVENT_PLACEABLE_FENCE_SEGMENT_ADD)

function PlaceableFenceAddSegmentEvent.emptyNew()
	return Event.new(PlaceableFenceAddSegmentEvent_mt)
end

function PlaceableFenceAddSegmentEvent.new(fence, x1, z1, x2, z2, renderFirst, renderLast, gateIndex, price)
	local self = PlaceableFenceAddSegmentEvent.emptyNew()
	self.fence = fence
	self.x1 = x1
	self.z1 = z1
	self.x2 = x2
	self.z2 = z2
	self.renderFirst = renderFirst
	self.renderLast = renderLast
	self.gateIndex = gateIndex
	self.price = price

	return self
end

function PlaceableFenceAddSegmentEvent:readStream(streamId, connection)
	self.fence = NetworkUtil.readNodeObject(streamId)
	self.x1 = streamReadFloat32(streamId)
	self.z1 = streamReadFloat32(streamId)
	self.x2 = streamReadFloat32(streamId)
	self.z2 = streamReadFloat32(streamId)
	self.renderFirst = streamReadBool(streamId)
	self.renderLast = streamReadBool(streamId)
	self.gateIndex = streamReadUInt8(streamId)

	if self.gateIndex == 0 then
		self.gateIndex = nil
	end

	self.price = streamReadInt32(streamId)

	self:run(connection)
end

function PlaceableFenceAddSegmentEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.fence)
	streamWriteFloat32(streamId, self.x1)
	streamWriteFloat32(streamId, self.z1)
	streamWriteFloat32(streamId, self.x2)
	streamWriteFloat32(streamId, self.z2)
	streamWriteBool(streamId, self.renderFirst)
	streamWriteBool(streamId, self.renderLast)
	streamWriteUInt8(streamId, self.gateIndex or 0)
	streamWriteInt32(streamId, self.price)
end

function PlaceableFenceAddSegmentEvent:run(connection)
	if self.fence ~= nil and self.fence:getIsSynchronized() then
		local segment = self.fence:createSegment(self.x1, self.z1, self.x2, self.z2, self.renderFirst, self.gateIndex)
		segment.renderLast = self.renderLast

		self.fence:addSegment(segment, self.gateIndex ~= nil and connection:getIsServer())
		g_messageCenter:publish(PlaceableFenceAddSegmentEvent, self.fence, segment)

		if not connection:getIsServer() then
			g_currentMission:addMoney(-self.price, self.fence:getOwnerFarmId(), MoneyType.SHOP_PROPERTY_BUY, true)
			g_server:broadcastEvent(self, false, nil, self.fence)
		end
	end
end
