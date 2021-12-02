BunkerSiloCloseEvent = {}
local BunkerSiloCloseEvent_mt = Class(BunkerSiloCloseEvent, Event)

InitStaticEventClass(BunkerSiloCloseEvent, "BunkerSiloCloseEvent", EventIds.EVENT_BUNKER_SILO_CLOSE)

function BunkerSiloCloseEvent.emptyNew()
	local self = Event.new(BunkerSiloCloseEvent_mt)

	return self
end

function BunkerSiloCloseEvent.new(bunkerSilo)
	local self = BunkerSiloCloseEvent.emptyNew()
	self.bunkerSilo = bunkerSilo

	return self
end

function BunkerSiloCloseEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.bunkerSilo = NetworkUtil.readNodeObject(streamId)
	end

	self:run(connection)
end

function BunkerSiloCloseEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.bunkerSilo)
	end
end

function BunkerSiloCloseEvent:run(connection)
	if not connection:getIsServer() then
		self.bunkerSilo:setState(BunkerSilo.STATE_CLOSED)
	end
end
