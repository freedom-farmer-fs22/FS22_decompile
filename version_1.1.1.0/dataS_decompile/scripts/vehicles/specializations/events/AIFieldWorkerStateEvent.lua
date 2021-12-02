AIFieldWorkerStateEvent = {}
local AIFieldWorkerStateEvent_mt = Class(AIFieldWorkerStateEvent, Event)

InitStaticEventClass(AIFieldWorkerStateEvent, "AIFieldWorkerStateEvent", EventIds.EVENT_AI_FIELDWORKER_STATE)

function AIFieldWorkerStateEvent.emptyNew()
	local self = Event.new(AIFieldWorkerStateEvent_mt)

	return self
end

function AIFieldWorkerStateEvent.new(vehicle, isActive)
	local self = AIFieldWorkerStateEvent.emptyNew()
	self.vehicle = vehicle
	self.isActive = isActive

	return self
end

function AIFieldWorkerStateEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.isActive = streamReadBool(streamId)

	self:run(connection)
end

function AIFieldWorkerStateEvent:writeStream(streamId, connection)
	assert(not connection:getIsServer(), "AIFieldWorkerStateEvent is a server to client event only")
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.isActive)
end

function AIFieldWorkerStateEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		if self.isActive then
			self.vehicle:startFieldWorker()
		else
			self.vehicle:stopFieldWorker()
		end
	end
end
