BaleWrapperAutomaticDropEvent = {}
local BaleWrapperAutomaticDropEvent_mt = Class(BaleWrapperAutomaticDropEvent, Event)

InitEventClass(BaleWrapperAutomaticDropEvent, "BaleWrapperAutomaticDropEvent")

function BaleWrapperAutomaticDropEvent.emptyNew()
	return Event.new(BaleWrapperAutomaticDropEvent_mt)
end

function BaleWrapperAutomaticDropEvent.new(object, automaticDrop)
	local self = BaleWrapperAutomaticDropEvent.emptyNew()
	self.object = object
	self.automaticDrop = automaticDrop

	return self
end

function BaleWrapperAutomaticDropEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.automaticDrop = streamReadBool(streamId)

	self:run(connection)
end

function BaleWrapperAutomaticDropEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.automaticDrop)
end

function BaleWrapperAutomaticDropEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setBaleWrapperAutomaticDrop(self.automaticDrop, true)
	end
end

function BaleWrapperAutomaticDropEvent.sendEvent(object, automaticDrop, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(BaleWrapperAutomaticDropEvent.new(object, automaticDrop), nil, , object)
		else
			g_client:getServerConnection():sendEvent(BaleWrapperAutomaticDropEvent.new(object, automaticDrop))
		end
	end
end
