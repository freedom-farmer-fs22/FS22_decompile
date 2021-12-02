BaleOpenEvent = {}
local BaleOpenEvent_mt = Class(BaleOpenEvent, Event)

InitStaticEventClass(BaleOpenEvent, "BaleOpenEvent", EventIds.EVENT_OPEN_BALE)

function BaleOpenEvent.emptyNew()
	local self = Event.new(BaleOpenEvent_mt)

	return self
end

function BaleOpenEvent.new(bale)
	local self = BaleOpenEvent.emptyNew()
	self.bale = bale

	return self
end

function BaleOpenEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.bale = NetworkUtil.readNodeObject(streamId)
	end

	self:run(connection)
end

function BaleOpenEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.bale)
	end
end

function BaleOpenEvent:run(connection)
	if not connection:getIsServer() then
		self.bale:open()
	end
end
