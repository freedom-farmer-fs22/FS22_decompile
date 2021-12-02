BaseMissionReadyEvent = {}
local BaseMissionReadyEvent_mt = Class(BaseMissionReadyEvent, Event)

InitStaticEventClass(BaseMissionReadyEvent, "BaseMissionReadyEvent", EventIds.EVENT_READY_EVENT)

function BaseMissionReadyEvent.emptyNew()
	local self = Event.new(BaseMissionReadyEvent_mt)

	return self
end

function BaseMissionReadyEvent.new()
	local self = BaseMissionReadyEvent.emptyNew()

	return self
end

function BaseMissionReadyEvent:readStream(streamId, connection)
	self:run(connection)
end

function BaseMissionReadyEvent:writeStream(streamId, connection)
end

function BaseMissionReadyEvent:run(connection)
	if connection:getIsServer() then
		g_currentMission:onFinishedReceivingDynamicData(connection)
	else
		g_currentMission:onConnectionReady(connection)
	end
end
