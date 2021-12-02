AnimalCleanEvent = {}
local AnimalCleanEvent_mt = Class(AnimalCleanEvent, Event)

InitStaticEventClass(AnimalCleanEvent, "AnimalCleanEvent", EventIds.EVENT_ANIMAL_CLEAN)

function AnimalCleanEvent.emptyNew()
	local self = Event.new(AnimalCleanEvent_mt)

	return self
end

function AnimalCleanEvent.new(husbandry, clusterId)
	local self = AnimalCleanEvent.emptyNew()
	self.husbandry = husbandry
	self.clusterId = clusterId

	return self
end

function AnimalCleanEvent:readStream(streamId, connection)
	self.husbandry = NetworkUtil.readNodeObject(streamId)
	self.clusterId = streamReadInt32(streamId)

	self:run(connection)
end

function AnimalCleanEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.husbandry)
	streamWriteInt32(streamId, self.clusterId)
end

function AnimalCleanEvent:run(connection)
	if self.husbandry ~= nil then
		local cluster = self.husbandry:getClusterById(self.clusterId)

		if cluster ~= nil and cluster.changeDirt ~= nil then
			cluster:changeDirt(AnimalClusterHorse.BRUSH_DELTA)
		end
	end
end
