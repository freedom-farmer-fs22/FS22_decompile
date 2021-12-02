SlotSystemUpdateEvent = {}
local SlotSystemUpdateEvent_mt = Class(SlotSystemUpdateEvent, Event)

InitStaticEventClass(SlotSystemUpdateEvent, "SlotSystemUpdateEvent", EventIds.EVENT_SLOT_SYSTEM_UPDATE)

function SlotSystemUpdateEvent.emptyNew()
	local self = Event.new(SlotSystemUpdateEvent_mt)

	return self
end

function SlotSystemUpdateEvent.new(slotLimit)
	local self = SlotSystemUpdateEvent.emptyNew()
	self.slotLimit = slotLimit

	assert(g_server ~= nil, "Server->client event")

	return self
end

function SlotSystemUpdateEvent:readStream(streamId, connection)
	local slotLimit = streamReadUInt16(streamId)

	if slotLimit == 0 then
		slotLimit = math.huge
	end

	self.slotLimit = slotLimit

	self:run(connection)
end

function SlotSystemUpdateEvent:writeStream(streamId, connection)
	local slotLimit = self.slotLimit

	if slotLimit == math.huge then
		slotLimit = 0
	end

	streamWriteUInt16(streamId, slotLimit)
end

function SlotSystemUpdateEvent:run(connection)
	g_currentMission.slotSystem:setSlotLimit(self.slotLimit)
end
