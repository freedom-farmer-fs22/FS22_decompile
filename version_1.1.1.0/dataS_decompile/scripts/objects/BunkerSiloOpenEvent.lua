BunkerSiloOpenEvent = {}
local BunkerSiloOpenEvent_mt = Class(BunkerSiloOpenEvent, Event)

InitStaticEventClass(BunkerSiloOpenEvent, "BunkerSiloOpenEvent", EventIds.EVENT_BUNKER_SILO_OPEN)

function BunkerSiloOpenEvent.emptyNew()
	local self = Event.new(BunkerSiloOpenEvent_mt)

	return self
end

function BunkerSiloOpenEvent.new(bunkerSilo, x, y, z)
	local self = BunkerSiloOpenEvent.emptyNew()
	self.bunkerSilo = bunkerSilo
	self.x = x
	self.y = y
	self.z = z

	return self
end

function BunkerSiloOpenEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.bunkerSilo = NetworkUtil.readNodeObject(streamId)
		self.x = streamReadFloat32(streamId)
		self.y = streamReadFloat32(streamId)
		self.z = streamReadFloat32(streamId)
	end

	self:run(connection)
end

function BunkerSiloOpenEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.bunkerSilo)
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
	end
end

function BunkerSiloOpenEvent:run(connection)
	if not connection:getIsServer() then
		self.bunkerSilo:openSilo(self.x, self.y, self.z)
	end
end
