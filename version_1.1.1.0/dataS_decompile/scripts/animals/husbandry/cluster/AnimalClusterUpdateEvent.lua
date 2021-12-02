AnimalClusterUpdateEvent = {}
local AnimalClusterUpdateEvent_mt = Class(AnimalClusterUpdateEvent, Event)

InitStaticEventClass(AnimalClusterUpdateEvent, "AnimalClusterUpdateEvent", EventIds.EVENT_ANIMAL_CLUSTER_UPDATE)

function AnimalClusterUpdateEvent.emptyNew()
	return Event.new(AnimalClusterUpdateEvent_mt, NetworkNode.CHANNEL_SECONDARY)
end

function AnimalClusterUpdateEvent.new(owner, clusters)
	local self = AnimalClusterUpdateEvent.emptyNew()

	assert(#clusters < 65535, "Number of clusters is too big")

	self.owner = owner
	self.clusters = clusters

	return self
end

function AnimalClusterUpdateEvent:readStream(streamId, connection)
	self.owner = NetworkUtil.readNodeObject(streamId)
	local clusterSystem = self.owner:getClusterSystem()

	clusterSystem:readStream(streamId, connection)
end

function AnimalClusterUpdateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.owner)

	local clusterSystem = self.owner:getClusterSystem()

	clusterSystem:writeStream(streamId, connection)
end

function AnimalClusterUpdateEvent:run(connection)
end
