HonkEvent = {}
local HonkEvent_mt = Class(HonkEvent, Event)

InitStaticEventClass(HonkEvent, "HonkEvent", EventIds.EVENT_HONK)

function HonkEvent.emptyNew()
	local self = Event.new(HonkEvent_mt)

	return self
end

function HonkEvent.new(object, isPlaying)
	local self = HonkEvent.emptyNew()
	self.object = object
	self.isPlaying = isPlaying

	return self
end

function HonkEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.isPlaying = streamReadBool(streamId)

	self:run(connection)
end

function HonkEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.isPlaying)
end

function HonkEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:playHonk(self.isPlaying, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(HonkEvent.new(self.object, self.isPlaying), nil, connection, self.object)
	end
end

function HonkEvent.sendEvent(vehicle, isPlaying, noEventSend)
	if vehicle.spec_honk ~= nil and vehicle.spec_honk.isPlaying ~= isPlaying and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(HonkEvent.new(vehicle, isPlaying), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(HonkEvent.new(vehicle, isPlaying))
		end
	end
end
