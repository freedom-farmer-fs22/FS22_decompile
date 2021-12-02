ShutdownEvent = {}
local ShutdownEvent_mt = Class(ShutdownEvent, Event)

InitStaticEventClass(ShutdownEvent, "ShutdownEvent", EventIds.EVENT_SHUTDOWN)

function ShutdownEvent.emptyNew()
	local self = Event.new(ShutdownEvent_mt)

	return self
end

function ShutdownEvent.new()
	local self = ShutdownEvent.emptyNew()

	return self
end

function ShutdownEvent:readStream(streamId, connection)
	self:run(connection)
end

function ShutdownEvent:writeStream(streamId, connection)
end

function ShutdownEvent:run(connection)
	g_currentMission:onShutdownEvent(connection)
end
