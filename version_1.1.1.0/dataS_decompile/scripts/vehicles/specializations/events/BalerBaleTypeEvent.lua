BalerBaleTypeEvent = {
	BALE_TYPE_SEND_NUM_BITS = 4
}
BalerBaleTypeEvent.MAX_NUM_BALE_TYPES = 2^BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS - 1
local BalerBaleTypeEvent_mt = Class(BalerBaleTypeEvent, Event)

InitEventClass(BalerBaleTypeEvent, "BalerBaleTypeEvent")

function BalerBaleTypeEvent.emptyNew()
	return Event.new(BalerBaleTypeEvent_mt)
end

function BalerBaleTypeEvent.new(object, baleTypeIndex)
	local self = BalerBaleTypeEvent.emptyNew()
	self.object = object
	self.baleTypeIndex = baleTypeIndex

	return self
end

function BalerBaleTypeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.baleTypeIndex = streamReadUIntN(streamId, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)

	self:run(connection)
end

function BalerBaleTypeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.baleTypeIndex, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
end

function BalerBaleTypeEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setBaleTypeIndex(self.baleTypeIndex, false, true)
	end
end

function BalerBaleTypeEvent.sendEvent(object, baleTypeIndex, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(BalerBaleTypeEvent.new(object, baleTypeIndex), nil, , object)
		else
			g_client:getServerConnection():sendEvent(BalerBaleTypeEvent.new(object, baleTypeIndex))
		end
	end
end
