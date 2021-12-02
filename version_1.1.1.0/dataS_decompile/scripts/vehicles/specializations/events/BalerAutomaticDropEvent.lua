BalerAutomaticDropEvent = {}
local BalerAutomaticDropEvent_mt = Class(BalerAutomaticDropEvent, Event)

InitEventClass(BalerAutomaticDropEvent, "BalerAutomaticDropEvent")

function BalerAutomaticDropEvent.emptyNew()
	return Event.new(BalerAutomaticDropEvent_mt)
end

function BalerAutomaticDropEvent.new(object, automaticDrop)
	local self = BalerAutomaticDropEvent.emptyNew()
	self.object = object
	self.automaticDrop = automaticDrop

	return self
end

function BalerAutomaticDropEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.automaticDrop = streamReadBool(streamId)

	self:run(connection)
end

function BalerAutomaticDropEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.automaticDrop)
end

function BalerAutomaticDropEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setBalerAutomaticDrop(self.automaticDrop, true)
	end
end

function BalerAutomaticDropEvent.sendEvent(object, automaticDrop, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(BalerAutomaticDropEvent.new(object, automaticDrop), nil, , object)
		else
			g_client:getServerConnection():sendEvent(BalerAutomaticDropEvent.new(object, automaticDrop))
		end
	end
end
