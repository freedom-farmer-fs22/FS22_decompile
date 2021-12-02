BalerDropFromPlatformEvent = {}
local BalerDropFromPlatformEvent_mt = Class(BalerDropFromPlatformEvent, Event)

InitEventClass(BalerDropFromPlatformEvent, "BalerDropFromPlatformEvent")

function BalerDropFromPlatformEvent.emptyNew()
	local self = Event.new(BalerDropFromPlatformEvent_mt)

	return self
end

function BalerDropFromPlatformEvent.new(object, waitForNextBale)
	local self = BalerDropFromPlatformEvent.emptyNew()
	self.object = object
	self.waitForNextBale = waitForNextBale

	return self
end

function BalerDropFromPlatformEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.waitForNextBale = streamReadBool(streamId)

	self:run(connection)
end

function BalerDropFromPlatformEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.waitForNextBale)
end

function BalerDropFromPlatformEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:dropBaleFromPlatform(self.waitForNextBale, true)
	end
end

function BalerDropFromPlatformEvent.sendEvent(object, waitForNextBale, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(BalerDropFromPlatformEvent.new(object, waitForNextBale), nil, , object)
		else
			g_client:getServerConnection():sendEvent(BalerDropFromPlatformEvent.new(object, waitForNextBale))
		end
	end
end
