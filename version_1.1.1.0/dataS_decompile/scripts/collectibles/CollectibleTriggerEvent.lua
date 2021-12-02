CollectibleTriggerEvent = {}
local CollectibleTriggerEvent_mt = Class(CollectibleTriggerEvent, Event)

InitStaticEventClass(CollectibleTriggerEvent, "CollectibleTriggerEvent", EventIds.EVENT_COLLECTIBLE_TRIGGER)

function CollectibleTriggerEvent.emptyNew()
	return Event.new(CollectibleTriggerEvent_mt)
end

function CollectibleTriggerEvent.new(player, index)
	local self = CollectibleTriggerEvent.emptyNew()
	self.player = player
	self.index = index

	return self
end

function CollectibleTriggerEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.player)
	streamWriteUInt8(streamId, self.index)
end

function CollectibleTriggerEvent:readStream(streamId, connection)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.index = streamReadUInt8(streamId)

	self:run(connection)
end

function CollectibleTriggerEvent:run(connection)
	g_currentMission.collectiblesSystem:onTriggerEvent(self.index, self.player)
end
