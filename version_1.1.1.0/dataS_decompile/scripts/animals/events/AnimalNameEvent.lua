AnimalNameEvent = {}
local AnimalNameEvent_mt = Class(AnimalNameEvent, Event)

InitStaticEventClass(AnimalNameEvent, "AnimalNameEvent", EventIds.EVENT_ANIMAL_NAME)

function AnimalNameEvent.emptyNew()
	local self = Event.new(AnimalNameEvent_mt)

	return self
end

function AnimalNameEvent.new(husbandry, clusterId, name)
	local self = AnimalNameEvent.emptyNew()
	self.husbandry = husbandry
	self.clusterId = clusterId
	self.name = name

	return self
end

function AnimalNameEvent:readStream(streamId, connection)
	self.husbandry = NetworkUtil.readNodeObject(streamId)
	self.clusterId = streamReadInt32(streamId)
	self.name = streamReadString(streamId)

	self:run(connection)
end

function AnimalNameEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.husbandry)
	streamWriteInt32(streamId, self.clusterId)
	streamWriteString(streamId, self.name)
end

function AnimalNameEvent:run(connection)
	self.husbandry:renameAnimal(self.clusterId, self.name, true)

	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false)
	end
end

function AnimalNameEvent.sendEvent(husbandry, clusterId, name, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_currentMission:getIsServer() then
			g_server:broadcastEvent(AnimalNameEvent.new(husbandry, clusterId, name), false)
		else
			g_client:getServerConnection():sendEvent(AnimalNameEvent.new(husbandry, clusterId, name))
		end
	end
end
