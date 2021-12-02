WoodUnloadTriggerEvent = {}
local WoodUnloadTriggerEvent_mt = Class(WoodUnloadTriggerEvent, Event)

InitStaticEventClass(WoodUnloadTriggerEvent, "WoodUnloadTriggerEvent", EventIds.EVENT_SELL_WOOD)

function WoodUnloadTriggerEvent.emptyNew()
	local self = Event.new(WoodUnloadTriggerEvent_mt)

	return self
end

function WoodUnloadTriggerEvent.new(woodUnloadTrigger, farmId)
	local self = WoodUnloadTriggerEvent.emptyNew()

	assert(g_server == nil, "Client->Server event")

	self.woodUnloadTrigger = woodUnloadTrigger
	self.farmId = farmId

	return self
end

function WoodUnloadTriggerEvent:readStream(streamId, connection)
	self.woodUnloadTrigger = NetworkUtil.readNodeObject(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	self:run(connection)
end

function WoodUnloadTriggerEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.woodUnloadTrigger)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function WoodUnloadTriggerEvent:run(connection)
	if not connection:getIsServer() then
		self.woodUnloadTrigger:processWood(self.farmId)
	end
end
