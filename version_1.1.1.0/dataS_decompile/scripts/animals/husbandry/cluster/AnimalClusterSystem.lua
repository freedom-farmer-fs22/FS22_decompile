AnimalClusterSystem = {}
local AnimalClusterSystem_mt = Class(AnimalClusterSystem)

function AnimalClusterSystem.registerSavegameXMLPaths(schema, basePath)
end

function AnimalClusterSystem.new(isServer, owner, customMt)
	local self = setmetatable({}, customMt or AnimalClusterSystem_mt)
	self.isServer = isServer
	self.owner = owner
	self.clusters = {}
	self.idToIndex = {}
	self.clustersToAdd = {}
	self.clustersToRemove = {}
	self.needsUpdate = false

	return self
end

function AnimalClusterSystem:delete()
	self.clusters = {}
end

function AnimalClusterSystem:readStream(streamId, connection)
	local numClusters = streamReadUInt16(streamId)
	local ids = {}

	for i = 1, numClusters do
		local id = streamReadInt32(streamId)
		local subTypeIndex = streamReadUIntN(streamId, AnimalCluster.NUM_BITS_SUB_TYPE)
		ids[id] = true
		local index = self.idToIndex[id]
		local cluster = nil

		if index == nil then
			cluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
			cluster.id = id

			self:addCluster(cluster)
		else
			cluster = self.clusters[index]
		end

		cluster:readStream(streamId, connection)
	end

	for i = #self.clusters, 1, -1 do
		local cluster = self.clusters[i]

		if ids[cluster.id] == nil then
			self:removeCluster(i)
		end
	end

	self:updateIdMapping()
	g_messageCenter:publish(AnimalClusterUpdateEvent, self.owner, self.clusters)
end

function AnimalClusterSystem:writeStream(streamId, connection)
	streamWriteUInt16(streamId, #self.clusters)

	for _, cluster in ipairs(self.clusters) do
		streamWriteInt32(streamId, cluster.id)
		streamWriteUIntN(streamId, cluster.subTypeIndex, AnimalCluster.NUM_BITS_SUB_TYPE)
		cluster:writeStream(streamId, connection)
	end
end

function AnimalClusterSystem:saveToXMLFile(xmlFile, key, usedModNames)
	for i, cluster in ipairs(self.clusters) do
		local animalKey = string.format("%s.animal(%d)", key, i - 1)
		local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster.subTypeIndex)

		xmlFile:setString(animalKey .. "#subType", subType.name)
		cluster:saveToXMLFile(xmlFile, animalKey, usedModNames)
	end
end

function AnimalClusterSystem:loadFromXMLFile(xmlFile, key)
	local i = 0

	while true do
		local animalKey = string.format("%s.animal(%d)", key, i)

		if not xmlFile:hasProperty(animalKey) then
			break
		end

		local subTypeName = xmlFile:getString(animalKey .. "#subType", "")
		local subType = g_currentMission.animalSystem:getSubTypeByName(subTypeName)

		if subType ~= nil then
			local cluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(subType.subTypeIndex)

			if cluster:loadFromXMLFile(xmlFile, animalKey) then
				self:addPendingAddCluster(cluster)
			end
		else
			Logging.xmlWarning(xmlFile, "SubType '%s' not defined. Ignoring animal '%s'.", tostring(subTypeName), animalKey)
		end

		i = i + 1
	end

	self:updateClusters()

	self.needsUpdate = false
end

function AnimalClusterSystem:update(dt)
	if self.isServer and self.needsUpdate then
		self:updateNow()
	end
end

function AnimalClusterSystem:updateNow()
	if self.needsUpdate then
		self:updateClusters()

		self.needsUpdate = false
	end
end

function AnimalClusterSystem:updateIdMapping()
	self.idToIndex = {}

	for index, cluster in ipairs(self.clusters) do
		self.idToIndex[cluster.id] = index
	end
end

function AnimalClusterSystem:setDirty()
	self.needsUpdate = true

	self.owner:raiseActive()
end

function AnimalClusterSystem:addPendingAddCluster(cluster)
	assert(self.isServer, "AnimalClusterSystem:addPendingAddCluster is a server function")

	self.clustersToAdd[cluster] = true
	self.clustersToRemove[cluster] = nil

	self:setDirty()
end

function AnimalClusterSystem:addPendingRemoveCluster(cluster)
	assert(self.isServer, "AnimalClusterSystem:addPendingRemoveCluster is a server function")

	self.clustersToRemove[cluster] = true
	self.clustersToAdd[cluster] = nil

	self:setDirty()
end

function AnimalClusterSystem:addCluster(cluster)
	table.insert(self.clusters, cluster)

	cluster.clusterSystem = self
end

function AnimalClusterSystem:removeCluster(clusterIndex)
	local cluster = self.clusters[clusterIndex]

	table.remove(self.clusters, clusterIndex)

	cluster.clusterSystem = nil
end

function AnimalClusterSystem:getClusters()
	return self.clusters
end

function AnimalClusterSystem:getCluster(index)
	return self.clusters[index]
end

function AnimalClusterSystem:getClusterById(clusterId)
	local index = self.idToIndex[clusterId]

	if index == nil then
		return nil
	end

	return self.clusters[index]
end

function AnimalClusterSystem:updateClusters()
	assert(self.isServer, "AnimalClusterSystem:updateClusters is a server function")

	local isDirty = false
	local hashToIndex = {}
	local removedClusterIndices = {}

	for clusterToAdd, _ in pairs(self.clustersToAdd) do
		self:addCluster(clusterToAdd)

		isDirty = true
	end

	for clusterIndex, cluster in ipairs(self.clusters) do
		if cluster.isDirty then
			isDirty = true
			cluster.isDirty = false
		end

		if self.clustersToRemove[cluster] ~= nil or cluster:getNumAnimals() == 0 then
			table.insert(removedClusterIndices, clusterIndex)
		elseif cluster:getSupportsMerging() then
			local hash = cluster:getHash()
			local index = hashToIndex[hash]

			if index ~= nil then
				local hashedCluster = self.clusters[index]

				hashedCluster:merge(cluster)
				table.insert(removedClusterIndices, clusterIndex)
			else
				hashToIndex[hash] = clusterIndex
			end
		end
	end

	for i = #removedClusterIndices, 1, -1 do
		isDirty = true
		local clusterIndexToRemove = removedClusterIndices[i]

		self:removeCluster(clusterIndexToRemove)
	end

	if isDirty then
		g_server:broadcastEvent(AnimalClusterUpdateEvent.new(self.owner, self.clusters), true)
		g_messageCenter:publish(AnimalClusterUpdateEvent, self.owner, self.clusters)
	end

	self.clustersToAdd = {}
	self.clustersToRemove = {}

	self:updateIdMapping()
end
