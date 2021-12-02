ObjectFarmChangeEvent = {}
local ObjectFarmChangeEvent_mt = Class(ObjectFarmChangeEvent, Event)

InitStaticEventClass(ObjectFarmChangeEvent, "ObjectFarmChangeEvent", EventIds.EVENT_OBJECT_OWNER_CHANGE)

function ObjectFarmChangeEvent.emptyNew()
	local self = Event.new(ObjectFarmChangeEvent_mt)

	return self
end

function ObjectFarmChangeEvent.new(object, farmId)
	local self = ObjectFarmChangeEvent.emptyNew()
	self.object = object
	self.farmId = farmId

	return self
end

function ObjectFarmChangeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)
end

function ObjectFarmChangeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)

	self:run(connection)
end

function ObjectFarmChangeEvent:run(connection)
	if connection:getIsServer() then
		self.object:setOwnerFarmId(self.farmId, true)
	end
end
