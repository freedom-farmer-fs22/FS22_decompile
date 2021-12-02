AnimalClusterHusbandry = {}
local AnimalClusterHusbandry_mt = Class(AnimalClusterHusbandry)

function AnimalClusterHusbandry.new(placeable, animalTypeName, maxVisualAnimals, customMt)
	local self = setmetatable({}, customMt or AnimalClusterHusbandry_mt)
	self.placeable = placeable
	self.husbandry = nil
	self.navigationNode = nil
	self.maxVisualAnimals = maxVisualAnimals
	self.animalTypeName = animalTypeName
	self.animalSystem = g_currentMission.animalSystem
	self.animalIdToCluster = {}
	self.animalIdToVisualAnimalIndex = {}
	self.totalNumAnimalsPerVisualAnimalIndex = {}

	return self
end

function AnimalClusterHusbandry:delete()
	if self.husbandry ~= nil then
		for animalId, _ in pairs(self.animalIdToCluster) do
			removeHusbandryAnimal(self.husbandry, animalId)
		end

		g_soundManager:removeIndoorStateChangedListener(self)
		delete(self.husbandry)

		self.husbandry = nil
	end
end

function AnimalClusterHusbandry:update(dt)
	if self.husbandry ~= nil then
		setAnimalDaytime(self.husbandry, g_currentMission.environment.dayTime)

		if self.visualUpdatePending and isHusbandryReady(self.husbandry) then
			self:updateVisuals()

			self.visualUpdatePending = false
		end
	end
end

function AnimalClusterHusbandry:getNeedsUpdate()
	return self.visualUpdatePending
end

function AnimalClusterHusbandry:create(xmlFilename, navigationNode, raycastDistance, collisionMask)
	self.navigationNode = navigationNode
	local raycastCollisionFlag = CollisionMask.ANIMAL_POSITIONING
	local husbandry = createAnimalHusbandry(self.animalTypeName, navigationNode, xmlFilename, raycastDistance, raycastCollisionFlag, collisionMask)

	if husbandry ~= 0 then
		self.husbandry = husbandry
		self.visualUpdatePending = true

		g_soundManager:addIndoorStateChangedListener(self)
		setAnimalUseOutdoorAudioSetup(self.husbandry, not g_soundManager:getIsIndoor())

		return self.husbandry
	end

	return nil
end

function AnimalClusterHusbandry:getPlaceable()
	return self.placeable
end

function AnimalClusterHusbandry:updateVisuals()
	if self.husbandry == nil or not isHusbandryReady(self.husbandry) then
		self.visualUpdatePending = true

		return
	end

	local clusters = self.nextUpdateClusters or {}
	self.totalNumAnimalsPerVisualAnimalIndex = {}
	local clusterToNumAnimals = {}
	local clusterToVisualAnimalIndex = {}
	local newAnimalMapping = {}
	local newAnimalIdToVisualAnimalIndex = {}
	local groupedClusters = {}
	local visualAnimalIndexToDataIndex = {}
	local totalNumAnimals = 0

	for _, cluster in ipairs(clusters) do
		local numAnimals = cluster:getNumAnimals()

		if numAnimals > 0 then
			local subTypeIndex = cluster:getSubTypeIndex()
			local age = cluster:getAge()
			local visualAnimalIndex = self.animalSystem:getVisualAnimalIndexByAge(subTypeIndex, age)
			clusterToVisualAnimalIndex[cluster] = visualAnimalIndex
			totalNumAnimals = totalNumAnimals + numAnimals
			local index = visualAnimalIndexToDataIndex[visualAnimalIndex]

			if index == nil then
				table.insert(groupedClusters, {
					numAnimals = 0,
					visualAnimalIndex = visualAnimalIndex,
					clusters = {},
					minClusterId = math.huge
				})

				index = #groupedClusters
				visualAnimalIndexToDataIndex[visualAnimalIndex] = index
			end

			local data = groupedClusters[index]
			data.numAnimals = data.numAnimals + numAnimals
			data.minClusterId = math.min(cluster.id, data.minClusterId)

			table.insert(data.clusters, cluster)

			self.totalNumAnimalsPerVisualAnimalIndex[visualAnimalIndex] = (self.totalNumAnimalsPerVisualAnimalIndex[visualAnimalIndex] or 0) + numAnimals
		end
	end

	table.sort(groupedClusters, function (a, b)
		if a.numAnimals == b.numAnimals then
			return a.minClusterId < b.minClusterId
		end

		return b.numAnimals < a.numAnimals
	end)

	for _, data in ipairs(groupedClusters) do
		table.sort(data.clusters, AnimalClusterHusbandry.sortClusters)
	end

	local exclusiveSlots = math.min(#groupedClusters, self.maxVisualAnimals)
	local freeSlots = self.maxVisualAnimals - exclusiveSlots

	for _, data in ipairs(groupedClusters) do
		local numAnimals = 0

		if exclusiveSlots > 0 then
			numAnimals = 1
			exclusiveSlots = exclusiveSlots - 1
		end

		if freeSlots > 0 then
			local ratio = self.totalNumAnimalsPerVisualAnimalIndex[data.visualAnimalIndex] / totalNumAnimals
			local additionalAnimals = math.min(math.ceil(ratio * freeSlots), freeSlots, data.numAnimals - 1)
			numAnimals = numAnimals + additionalAnimals
			freeSlots = freeSlots - additionalAnimals
		end

		local index = 1

		while numAnimals > 0 do
			if index > #data.clusters then
				index = 1
			end

			local cluster = data.clusters[index]

			if clusterToNumAnimals[cluster] == nil then
				clusterToNumAnimals[cluster] = 0
			end

			if clusterToNumAnimals[cluster] < cluster.numAnimals then
				clusterToNumAnimals[cluster] = clusterToNumAnimals[cluster] + 1
				numAnimals = numAnimals - 1
			end

			index = index + 1
		end

		if exclusiveSlots == 0 and freeSlots == 0 then
			break
		end
	end

	for animalId, cluster in pairs(self.animalIdToCluster) do
		if clusterToNumAnimals[cluster] ~= nil then
			local visualAnimalIndex = self.animalIdToVisualAnimalIndex[animalId]
			local clusterVisualAnimalIndex = clusterToVisualAnimalIndex[cluster]

			if visualAnimalIndex ~= clusterVisualAnimalIndex then
				setAnimalSubType(self.husbandry, animalId, clusterVisualAnimalIndex - 1)
			end

			clusterToNumAnimals[cluster] = clusterToNumAnimals[cluster] - 1

			if clusterToNumAnimals[cluster] <= 0 then
				clusterToNumAnimals[cluster] = nil
			end

			newAnimalMapping[animalId] = cluster
			newAnimalIdToVisualAnimalIndex[animalId] = clusterVisualAnimalIndex
			self.animalIdToCluster[animalId] = nil
			self.animalIdToVisualAnimalIndex[animalId] = nil
		end
	end

	for cluster, numAnimals in pairs(clusterToNumAnimals) do
		for i = 1, numAnimals do
			local found = false
			local visualAnimalIndex = clusterToVisualAnimalIndex[cluster]

			for animalId, typeIndex in pairs(self.animalIdToVisualAnimalIndex) do
				if visualAnimalIndex == typeIndex then
					self.animalIdToCluster[animalId] = nil
					newAnimalMapping[animalId] = cluster
					newAnimalIdToVisualAnimalIndex[animalId] = typeIndex
					clusterToNumAnimals[cluster] = clusterToNumAnimals[cluster] - 1

					if clusterToNumAnimals[cluster] <= 0 then
						clusterToNumAnimals[cluster] = nil

						break
					end

					found = true

					break
				end
			end

			if not found then
				break
			end
		end
	end

	for animalId, cluster in pairs(self.animalIdToCluster) do
		removeHusbandryAnimal(self.husbandry, animalId)
	end

	for cluster, numAnimals in pairs(clusterToNumAnimals) do
		for i = 1, numAnimals do
			local visualAnimalIndex = clusterToVisualAnimalIndex[cluster]
			local animalId = addHusbandryAnimal(self.husbandry, visualAnimalIndex - 1)
			local subTypeIndex = cluster:getSubTypeIndex()
			local age = cluster:getAge()
			local visualData = self.animalSystem:getVisualByAge(subTypeIndex, age)
			local variations = visualData.visualAnimal.variations

			if #variations > 1 then
				local variation = variations[math.random(1, #variations)]

				setAnimalTextureTile(self.husbandry, animalId, variation.tileUIndex, variation.tileVIndex)
			end

			newAnimalMapping[animalId] = cluster
			newAnimalIdToVisualAnimalIndex[animalId] = visualAnimalIndex
		end
	end

	for animalId, cluster in pairs(newAnimalMapping) do
		local dirtFactor = 0

		if cluster.getDirtFactor ~= nil then
			dirtFactor = cluster:getDirtFactor()
		end

		local animalRootNode = getAnimalRootNode(self.husbandry, animalId)

		I3DUtil.setShaderParameterRec(animalRootNode, "RDT", nil, dirtFactor, nil, )

		local x, y, z, w = getAnimalShaderParameter(self.husbandry, animalId, "atlasInvSizeAndOffsetUV")

		I3DUtil.setShaderParameterRec(animalRootNode, "atlasInvSizeAndOffsetUV", x, y, z, w)
	end

	self.animalIdToCluster = newAnimalMapping
	self.animalIdToVisualAnimalIndex = newAnimalIdToVisualAnimalIndex
	self.nextUpdateClusters = nil
end

function AnimalClusterHusbandry:setClusters(clusters)
	self.nextUpdateClusters = clusters
	self.visualUpdatePending = true
end

function AnimalClusterHusbandry:getHusbandryId()
	return self.husbandry
end

function AnimalClusterHusbandry:getAnimalPosition(clusterId)
	for animalId, cluster in pairs(self.animalIdToCluster) do
		if cluster.id == clusterId then
			local x, y, z = getAnimalPosition(self.husbandry, animalId)
			local rx, ry, rz = getAnimalRotation(self.husbandry, animalId)

			return x, y, z, rx, ry, rz
		end
	end

	return nil
end

function AnimalClusterHusbandry:getClusterByAnimalId(animalId)
	return self.animalIdToCluster[animalId]
end

function AnimalClusterHusbandry:onIndoorStateChanged(isIndoor)
	setAnimalUseOutdoorAudioSetup(self.husbandry, not g_soundManager:getIsIndoor())
end

function AnimalClusterHusbandry.sortClusters(a, b)
	local numAnimalsA = a:getNumAnimals()
	local numAnimalsB = b:getNumAnimals()

	if numAnimalsA == numAnimalsB then
		return a.id < b.id
	end

	return b:getNumAnimals() < a:getNumAnimals()
end
