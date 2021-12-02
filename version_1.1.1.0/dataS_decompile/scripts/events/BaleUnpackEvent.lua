BaleUnpackEvent = {}
local BaleUnpackEvent_mt = Class(BaleUnpackEvent, Event)

InitStaticEventClass(BaleUnpackEvent, "BaleUnpackEvent", EventIds.EVENT_UNPACK_BALE)

function BaleUnpackEvent.emptyNew()
	local self = Event.new(BaleUnpackEvent_mt)

	return self
end

function BaleUnpackEvent.new(bale)
	local self = BaleUnpackEvent.emptyNew()
	self.bale = bale

	return self
end

function BaleUnpackEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.bale = NetworkUtil.readNodeObject(streamId)
	end

	self:run(connection)
end

function BaleUnpackEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.bale)
	end
end

function BaleUnpackEvent:run(connection)
	self.bale:unpack()
end
