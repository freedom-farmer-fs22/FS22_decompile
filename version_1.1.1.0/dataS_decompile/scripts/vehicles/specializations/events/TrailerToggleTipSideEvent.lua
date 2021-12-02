TrailerToggleTipSideEvent = {}
local TrailerToggleTipSideEvent_mt = Class(TrailerToggleTipSideEvent, Event)

InitStaticEventClass(TrailerToggleTipSideEvent, "TrailerToggleTipSideEvent", EventIds.EVENT_TRAILER_TOGGLE_TIP_SIDE)

function TrailerToggleTipSideEvent.emptyNew()
	local self = Event.new(TrailerToggleTipSideEvent_mt)

	return self
end

function TrailerToggleTipSideEvent.new(object, tipSideIndex)
	local self = TrailerToggleTipSideEvent.emptyNew()
	self.object = object
	self.tipSideIndex = tipSideIndex

	return self
end

function TrailerToggleTipSideEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.tipSideIndex = streamReadUIntN(streamId, Trailer.TIP_SIDE_NUM_BITS)

	self:run(connection)
end

function TrailerToggleTipSideEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.tipSideIndex, Trailer.TIP_SIDE_NUM_BITS)
end

function TrailerToggleTipSideEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setPreferedTipSide(self.tipSideIndex, true)
	end
end
