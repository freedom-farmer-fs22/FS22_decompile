CollectibleStateEvent = {}
local CollectibleStateEvent_mt = Class(CollectibleStateEvent, Event)

InitStaticEventClass(CollectibleStateEvent, "CollectibleStateEvent", EventIds.EVENT_COLLECTIBLE_STATE)

function CollectibleStateEvent.emptyNew()
	return Event.new(CollectibleStateEvent_mt)
end

function CollectibleStateEvent.new(state)
	local self = CollectibleStateEvent.emptyNew()
	self.state = state

	return self
end

function CollectibleStateEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, #self.state)

	for i = 1, #self.state do
		streamWriteBool(streamId, self.state[i])
	end
end

function CollectibleStateEvent:readStream(streamId, connection)
	self.state = {}
	local num = streamReadUInt8(streamId)

	for i = 1, num do
		self.state[i] = streamReadBool(streamId)
	end

	self:run(connection)
end

function CollectibleStateEvent:run(connection)
	if connection:getIsServer() then
		g_currentMission.collectiblesSystem:onStateEvent(self.state)
	end
end
