print("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")

local animalCounter = 0
local visibleAnimals = {}
local subTypes = {
	{
		visuals = {
			{
				animalTypeIndex = 1,
				minAge = 0
			},
			{
				animalTypeIndex = 2,
				minAge = 5
			},
			{
				animalTypeIndex = 3,
				minAge = 10
			}
		}
	},
	{
		visuals = {
			{
				animalTypeIndex = 4,
				minAge = 0
			},
			{
				animalTypeIndex = 5,
				minAge = 5
			},
			{
				animalTypeIndex = 6,
				minAge = 10
			}
		}
	},
	{
		visuals = {
			{
				animalTypeIndex = 7,
				minAge = 0
			},
			{
				animalTypeIndex = 8,
				minAge = 5
			},
			{
				animalTypeIndex = 9,
				minAge = 10
			}
		}
	}
}
g_currentMission = {
	animalNameSystem = {}
}

function g_currentMission.animalNameSystem.getRandomName(_)
	return "AnimalName" .. math.random(1, 123123)
end

g_currentMission.animalSystem = {
	getSubTypeByIndex = function (_, index)
		return subTypes[index]
	end,
	getAnimalTypeIndexByAge = function (_, subTypeIndex, age)
		local subType = subTypes[subTypeIndex]
		local animalTypeIndex = nil

		for _, visual in ipairs(subType.visuals) do
			if visual.minAge <= age then
				animalTypeIndex = visual.animalTypeIndex
			end
		end

		return animalTypeIndex
	end
}

function createAnimalHusbandry(...)
	log("create husbandry", ...)

	return 1
end

function addHusbandryAnimal(husbandryId, animalTypeIndex)
	animalCounter = animalCounter + 1
	local animal = {
		animalId = animalCounter,
		animalTypeIndex = animalTypeIndex + 1
	}

	table.insert(visibleAnimals, animal)
	log("Added animal", animalCounter, animalTypeIndex + 1)

	return animalCounter
end

function removeHusbandryAnimal(husbandryId, animalId)
	for i = 1, #visibleAnimals do
		if visibleAnimals[i].animalId == animalId then
			table.remove(visibleAnimals, i)
			log("remove animal", animalId)

			return
		end
	end

	printCallstack()
end

TestAnimalCluster = {
	CURRENT_SELECTION_INDEX = 1,
	init = function ()
		g_server = {
			broadcastEvent = function ()
			end
		}
		local self = TestAnimalCluster
		self.clusterSystem = AnimalClusterSystem.new(true, self)

		self.clusterSystem:addClustersUpdatedListener(function ()
			local clusters = self.clusterSystem:getClusters()

			self.animalClusterHusbandry:setClusters(clusters)
		end)

		self.animalClusterHusbandry = AnimalClusterHusbandry.new("horse", 12)

		self.animalClusterHusbandry:create("testXML", 1, 1, 255)
	end,
	update = function (dt)
		local self = TestAnimalCluster

		self.clusterSystem:update(dt)
	end
}

function TestAnimalCluster.draw()
	local self = TestAnimalCluster
	local numAnimals = 0
	local clusters = self.clusterSystem:getClusters()
	local sortedClusters = {}

	for i, cluster in ipairs(clusters) do
		table.insert(sortedClusters, cluster)

		local animalTypeIndex = g_currentMission.animalSystem:getAnimalTypeIndexByAge(cluster.subTypeIndex, cluster:getAge())
		local animalIds = {}

		for animalId, c in pairs(self.animalClusterHusbandry.animalIdToCluster) do
			if cluster == c then
				table.insert(animalIds, animalId)
			end
		end

		local animalIdStr = table.concat(animalIds, ", ")

		renderText(0.5, 0.8 - (i - 1) * 0.013, 0.012, string.format("Cluster: %02d  |  Animals: %03d  |  Age: %02d  |  Health: %03d  |  Reproduction: %03d  |  Hash: %s | TypeIndex: %d | AnimalIds: %s", cluster.id, cluster.numAnimals, cluster.age, cluster.health, cluster.reproduction, cluster:getHash(), animalTypeIndex, animalIdStr))

		numAnimals = numAnimals + cluster.numAnimals
	end

	if #clusters > 0 then
		renderText(0.495, 0.8 - (TestAnimalCluster.CURRENT_SELECTION_INDEX - 1) * 0.013, 0.012, ">")
	end

	renderText(0.5, 0.9, 0.012, string.format("Total Num Animals: %d", numAnimals))
	renderText(0.02, 0.9, 0.012, string.format("Total Num Visible Animals: %d", #visibleAnimals))

	for i, animal in ipairs(visibleAnimals) do
		local cluster = self.animalClusterHusbandry.animalIdToCluster[animal.animalId]
		local clusterId = "-"

		if cluster ~= nil then
			clusterId = string.format("%02d", cluster.id)
		end

		renderText(0.02, 0.8 - (i - 1) * 0.013, 0.012, string.format("AnimalId: %02d  |  TypeIndex: %d | Cluster: %s", animal.animalId, animal.animalTypeIndex, clusterId))
	end

	local i = 1

	for animalTypeIndex, typedNumAnimals in pairs(self.animalClusterHusbandry.totalNumAnimalsPerAnimalTypeIndex) do
		renderText(0.2, 0.8 - (i - 1) * 0.013, 0.012, string.format("TypeIndex: %d | Num: %d", animalTypeIndex, typedNumAnimals))

		i = i + 1
	end

	table.sort(sortedClusters, AnimalClusterHusbandry.sortClusters)

	for k, cluster in ipairs(sortedClusters) do
		local animalTypeIndex = g_currentMission.animalSystem:getAnimalTypeIndexByAge(cluster.subTypeIndex, cluster:getAge())

		renderText(0.35, 0.8 - (k - 1) * 0.013, 0.012, string.format("Cluster: %03d | Num: %d | TypeIndex: %d", cluster.id, cluster:getNumAnimals(), animalTypeIndex))
	end
end

function TestAnimalCluster.mouseEvent(posX, posY, isDown, isUp, button)
end

function TestAnimalCluster.keyEvent(unicode, sym, modifier, isDown)
	if not isDown then
		local self = TestAnimalCluster
		local clusters = self.clusterSystem:getClusters()
		TestAnimalCluster.CURRENT_SELECTION_INDEX = math.max(math.min(TestAnimalCluster.CURRENT_SELECTION_INDEX, #clusters), 1)
		local currentCluster = clusters[TestAnimalCluster.CURRENT_SELECTION_INDEX]
		local allModifier = bitAND(modifier, Input.MOD_LSHIFT) > 0

		if sym == Input.KEY_m then
			if allModifier or #clusters == 0 then
				local cluster = self.clusterSystem:createCluster()
				cluster.numAnimals = 1
				cluster.subTypeIndex = math.random(1, 3)

				self.clusterSystem:addPendingAddCluster(cluster)
			elseif currentCluster ~= nil then
				currentCluster.numAnimals = currentCluster.numAnimals + 1

				self.animalClusterHusbandry:setClusters(clusters)
			end
		elseif sym == Input.KEY_n then
			if currentCluster ~= nil then
				self.clusterSystem:addPendingRemoveCluster(currentCluster)
			end
		elseif sym == Input.KEY_q then
			if allModifier then
				for i, cluster in ipairs(clusters) do
					cluster:changeAge(1)
				end
			elseif currentCluster ~= nil then
				currentCluster:changeAge(1)
			end

			self.animalClusterHusbandry:setClusters(clusters)
		elseif sym == Input.KEY_w then
			if allModifier then
				for i, cluster in ipairs(clusters) do
					cluster:changeHealth(1)
				end
			elseif currentCluster ~= nil then
				currentCluster:changeHealth(1)
			end

			self.animalClusterHusbandry:setClusters(clusters)
		elseif sym == Input.KEY_e then
			if allModifier then
				for i, cluster in ipairs(clusters) do
					cluster:changeHealth(-1)
				end
			elseif currentCluster ~= nil then
				currentCluster:changeHealth(-1)
			end

			self.animalClusterHusbandry:setClusters(clusters)
		elseif sym == Input.KEY_s then
			if allModifier then
				for i, cluster in ipairs(clusters) do
					cluster:changeReproduction(1)
				end
			elseif currentCluster ~= nil then
				currentCluster:changeReproduction(1)
			end

			self.animalClusterHusbandry:setClusters(clusters)
		elseif sym == Input.KEY_d then
			if allModifier then
				for i, cluster in ipairs(clusters) do
					cluster:changeReproduction(-1)
				end
			elseif currentCluster ~= nil then
				currentCluster:changeReproduction(-1)
			end

			self.animalClusterHusbandry:setClusters(clusters)
		elseif sym == Input.KEY_up then
			TestAnimalCluster.CURRENT_SELECTION_INDEX = TestAnimalCluster.CURRENT_SELECTION_INDEX - 1
		elseif sym == Input.KEY_down then
			TestAnimalCluster.CURRENT_SELECTION_INDEX = TestAnimalCluster.CURRENT_SELECTION_INDEX + 1
		end

		TestAnimalCluster.CURRENT_SELECTION_INDEX = math.max(math.min(TestAnimalCluster.CURRENT_SELECTION_INDEX, #clusters), 1)

		self.clusterSystem:setDirty()
	end
end
