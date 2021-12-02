PlaceableHusbandryAnimals = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(PlaceableHusbandry, specializations)
	end,
	registerEvents = function (placeableType)
		SpecializationUtil.registerEvent(placeableType, "onHusbandryAnimalsCreated")
		SpecializationUtil.registerEvent(placeableType, "onHusbandryAnimalsUpdate")
	end
}

function PlaceableHusbandryAnimals.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "onExternalNavigationMeshLoaded", PlaceableHusbandryAnimals.onExternalNavigationMeshLoaded)
	SpecializationUtil.registerFunction(placeableType, "createHusbandry", PlaceableHusbandryAnimals.createHusbandry)
	SpecializationUtil.registerFunction(placeableType, "updateVisualAnimals", PlaceableHusbandryAnimals.updateVisualAnimals)
	SpecializationUtil.registerFunction(placeableType, "getNumOfFreeAnimalSlots", PlaceableHusbandryAnimals.getNumOfFreeAnimalSlots)
	SpecializationUtil.registerFunction(placeableType, "getNumOfAnimals", PlaceableHusbandryAnimals.getNumOfAnimals)
	SpecializationUtil.registerFunction(placeableType, "getMaxNumOfAnimals", PlaceableHusbandryAnimals.getMaxNumOfAnimals)
	SpecializationUtil.registerFunction(placeableType, "getNumOfClusters", PlaceableHusbandryAnimals.getNumOfClusters)
	SpecializationUtil.registerFunction(placeableType, "getSupportsAnimalSubType", PlaceableHusbandryAnimals.getSupportsAnimalSubType)
	SpecializationUtil.registerFunction(placeableType, "getClusters", PlaceableHusbandryAnimals.getClusters)
	SpecializationUtil.registerFunction(placeableType, "getCluster", PlaceableHusbandryAnimals.getCluster)
	SpecializationUtil.registerFunction(placeableType, "getClusterById", PlaceableHusbandryAnimals.getClusterById)
	SpecializationUtil.registerFunction(placeableType, "getClusterSystem", PlaceableHusbandryAnimals.getClusterSystem)
	SpecializationUtil.registerFunction(placeableType, "getAnimalTypeIndex", PlaceableHusbandryAnimals.getAnimalTypeIndex)
	SpecializationUtil.registerFunction(placeableType, "renameAnimal", PlaceableHusbandryAnimals.renameAnimal)
	SpecializationUtil.registerFunction(placeableType, "addCluster", PlaceableHusbandryAnimals.addCluster)
	SpecializationUtil.registerFunction(placeableType, "addAnimals", PlaceableHusbandryAnimals.addAnimals)
	SpecializationUtil.registerFunction(placeableType, "updatedClusters", PlaceableHusbandryAnimals.updatedClusters)
	SpecializationUtil.registerFunction(placeableType, "consoleCommandAddAnimals", PlaceableHusbandryAnimals.consoleCommandAddAnimals)
	SpecializationUtil.registerFunction(placeableType, "getAnimalSupportsRiding", PlaceableHusbandryAnimals.getAnimalSupportsRiding)
	SpecializationUtil.registerFunction(placeableType, "getAnimalCanBeRidden", PlaceableHusbandryAnimals.getAnimalCanBeRidden)
	SpecializationUtil.registerFunction(placeableType, "startRiding", PlaceableHusbandryAnimals.startRiding)
	SpecializationUtil.registerFunction(placeableType, "onLoadedRideable", PlaceableHusbandryAnimals.onLoadedRideable)
	SpecializationUtil.registerFunction(placeableType, "getIsInAnimalDeliveryArea", PlaceableHusbandryAnimals.getIsInAnimalDeliveryArea)
	SpecializationUtil.registerFunction(placeableType, "loadDeliveryArea", PlaceableHusbandryAnimals.loadDeliveryArea)
end

function PlaceableHusbandryAnimals.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedDayChanged", PlaceableHusbandryAnimals.getNeedDayChanged)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableHusbandryAnimals.updateInfo)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateOutput", PlaceableHusbandryAnimals.updateOutput)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBeSold", PlaceableHusbandryAnimals.canBeSold)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getConditionInfos", PlaceableHusbandryAnimals.getConditionInfos)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getAnimalInfos", PlaceableHusbandryAnimals.getAnimalInfos)
end

function PlaceableHusbandryAnimals.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onPeriodChanged", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onDayChanged", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onInfoTriggerEnter", PlaceableHusbandryAnimals)
	SpecializationUtil.registerEventListener(placeableType, "onInfoTriggerLeave", PlaceableHusbandryAnimals)
end

function PlaceableHusbandryAnimals.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")

	basePath = basePath .. ".husbandry.animals"

	schema:register(XMLValueType.NODE_INDEX, basePath .. ".navigation#rootNode", "Navigation mesh rootnode")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".navigation#node", "Navigation mesh node")
	schema:register(XMLValueType.STRING, basePath .. ".navigation#filename", "Filename for an external navigation mesh")
	schema:register(XMLValueType.STRING, basePath .. ".navigation#nodePath", "Nodepath for an external navigation mesh")
	schema:register(XMLValueType.STRING, basePath .. "#type", "Animal type")
	schema:register(XMLValueType.STRING, basePath .. "#filename", "Animal configuration file")
	schema:register(XMLValueType.FLOAT, basePath .. "#placementRaycastDistance", "Placement raycast distance", 2)
	schema:register(XMLValueType.INT, basePath .. "#maxNumAnimals", "Max number of animals", 16)
	schema:register(XMLValueType.INT, basePath .. "#maxNumVisualAnimals", "Max number of visual animals")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".loadingTrigger#node", "Animal loading trigger")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".deliveryAreas.deliveryArea(?)#startNode", "Animal delivery area start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".deliveryAreas.deliveryArea(?)#widthNode", "Animal delivery area width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".deliveryAreas.deliveryArea(?)#heightNode", "Animal delivery area height node")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryAnimals.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Husbandry")
	AnimalClusterSystem.registerSavegameXMLPaths(schema, basePath .. ".clusters")
	schema:setXMLSpecializationType()
end

function PlaceableHusbandryAnimals.initSpecialization()
	g_storeManager:addSpecType("numberAnimals", "shopListAttributeIconCapacity", PlaceableHusbandryAnimals.loadSpecValueNumberAnimals, PlaceableHusbandryAnimals.getSpecValueNumberAnimals, "placeable")
end

function PlaceableHusbandryAnimals:onLoad(savegame)
	local spec = self.spec_husbandryAnimals
	local xmlFile = self.xmlFile
	spec.infoHealth = {
		text = "",
		title = g_i18n:getText("ui_horseHealth")
	}
	spec.infoNumAnimals = {
		text = "",
		title = g_i18n:getText("ui_numAnimals")
	}
	spec.updateVisuals = false
	local animalTypeName = xmlFile:getValue("placeable.husbandry.animals#type")

	if animalTypeName == nil then
		Logging.xmlError(xmlFile, "Missing animal type!")
		self:setLoadingState(Placeable.LOADING_STATE_ERROR)

		return
	end

	spec.animalType = g_currentMission.animalSystem:getTypeByName(animalTypeName)

	if spec.animalType == nil then
		Logging.xmlError(xmlFile, "Animal type '%s' not found!", animalTypeName)
		self:setLoadingState(Placeable.LOADING_STATE_ERROR)

		return
	end

	spec.animalTypeIndex = spec.animalType.typeIndex
	spec.navigationMeshRootNode = xmlFile:getValue("placeable.husbandry.animals.navigation#rootNode", nil, self.components, self.i3dMappings)
	spec.navigationMesh = xmlFile:getValue("placeable.husbandry.animals.navigation#node", nil, self.components, self.i3dMappings)
	local navigationMeshFilename = xmlFile:getValue("placeable.husbandry.animals.navigation#filename", nil)

	if navigationMeshFilename ~= nil then
		navigationMeshFilename = Utils.getFilename(navigationMeshFilename, self.baseDirectory)
		local loadingTask = self:createLoadingTask(spec)
		spec.navigationMeshNodePath = xmlFile:getValue("placeable.husbandry.animals.navigation#nodePath", "0")
		spec.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(navigationMeshFilename, true, false, self.onExternalNavigationMeshLoaded, self, {
			loadingTask
		})
	end

	spec.placementRaycastDistance = xmlFile:getValue("placeable.husbandry.animals#placementRaycastDistance", 10)
	spec.maxNumAnimals = xmlFile:getValue("placeable.husbandry.animals#maxNumAnimals", 16)

	if spec.animalTypeIndex == AnimalType.HORSE then
		spec.maxNumVisualAnimals = math.min(spec.maxNumAnimals, 16)
		spec.maxNumAnimals = math.min(spec.maxNumAnimals, 16)
	else
		local profileClass = Utils.getPerformanceClassId()

		if GS_PLATFORM_XBOX or profileClass == GS_PROFILE_LOW then
			spec.maxNumVisualAnimals = 10
		elseif GS_PROFILE_VERY_HIGH <= profileClass then
			spec.maxNumVisualAnimals = 25
		elseif GS_PROFILE_HIGH <= profileClass then
			spec.maxNumVisualAnimals = 20
		else
			spec.maxNumVisualAnimals = 16
		end
	end

	local maxAnimals = 2^AnimalCluster.NUM_BITS_NUM_ANIMALS - 1

	if maxAnimals < spec.maxNumAnimals then
		Logging.xmlWarning(xmlFile, "Maximum number of animals reached! Maximum is '%d'!", maxAnimals)

		spec.maxNumAnimals = maxAnimals
	end

	if GS_IS_MOBILE_VERSION then
		spec.maxNumVisualAnimals = math.min(spec.maxNumVisualAnimals, 8)
	end

	local maxNumVisualAnimals = xmlFile:getValue("placeable.husbandry.animals#maxNumVisualAnimals")

	if maxNumVisualAnimals ~= nil then
		if spec.maxNumAnimals < maxNumVisualAnimals then
			maxNumVisualAnimals = spec.maxNumAnimals
		end

		if spec.maxNumVisualAnimals < maxNumVisualAnimals then
			maxNumVisualAnimals = spec.maxNumVisualAnimals
		end

		spec.maxNumVisualAnimals = maxNumVisualAnimals
	end

	spec.clusterHusbandry = AnimalClusterHusbandry.new(self, animalTypeName, spec.maxNumVisualAnimals)
	spec.clusterSystem = AnimalClusterSystem.new(self.isServer, self)

	g_messageCenter:subscribe(AnimalClusterUpdateEvent, self.updatedClusters, self)

	local animalLoadingTriggerNode = xmlFile:getValue("placeable.husbandry.animals.loadingTrigger#node", nil, self.components, self.i3dMappings)

	if animalLoadingTriggerNode ~= nil then
		spec.animalLoadingTrigger = AnimalLoadingTrigger.new(self.isServer, self.isClient)

		if not spec.animalLoadingTrigger:load(animalLoadingTriggerNode, self) then
			spec.animalLoadingTrigger:delete()
		end
	end

	spec.deliveryAreas = {}

	self.xmlFile:iterate("placeable.husbandry.animals.deliveryAreas.deliveryArea", function (_, key)
		local area = {}

		if self:loadDeliveryArea(self.xmlFile, key, area) then
			table.insert(spec.deliveryAreas, area)
		end
	end)

	spec.info = {
		text = "",
		title = g_i18n:getText("statistic_productivity")
	}
end

function PlaceableHusbandryAnimals:onDelete()
	local spec = self.spec_husbandryAnimals

	g_messageCenter:unsubscribe(AnimalClusterUpdateEvent, self)

	if self.isServer then
		removeConsoleCommand("gsHusbandryAddAnimals")
	end

	if spec.clusterHusbandry ~= nil then
		g_currentMission.husbandrySystem:removeClusterHusbandry(spec.clusterHusbandry)
		spec.clusterHusbandry:delete()

		spec.clusterHusbandry = nil
	end

	if spec.animalLoadingTrigger ~= nil then
		spec.animalLoadingTrigger:delete()

		spec.animalLoadingTrigger = nil
	end

	if spec.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(spec.sharedLoadRequestId)
	end

	g_currentMission:unregisterObjectToCallOnMissionStart(self)
end

function PlaceableHusbandryAnimals:onFinalizePlacement()
	self:createHusbandry()
	g_currentMission:registerObjectToCallOnMissionStart(self)
end

function PlaceableHusbandryAnimals:onReadStream(streamId, connection)
	local spec = self.spec_husbandryAnimals

	spec.clusterSystem:readStream(streamId, connection)
end

function PlaceableHusbandryAnimals:onWriteStream(streamId, connection)
	local spec = self.spec_husbandryAnimals

	spec.clusterSystem:writeStream(streamId, connection)
end

function PlaceableHusbandryAnimals:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_husbandryAnimals

	spec.clusterSystem:saveToXMLFile(xmlFile, key .. ".clusters", usedModNames)
end

function PlaceableHusbandryAnimals:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_husbandryAnimals

	spec.clusterSystem:loadFromXMLFile(xmlFile, key .. ".clusters")
end

function PlaceableHusbandryAnimals:onUpdate(dt)
	local spec = self.spec_husbandryAnimals

	if self.isServer then
		spec.clusterSystem:update(dt)
	end

	if spec.clusterHusbandry ~= nil then
		spec.clusterHusbandry:update(dt)
	end

	if spec.updateVisuals then
		self:updateVisualAnimals()

		spec.updateVisuals = false
	end

	if spec.clusterHusbandry:getNeedsUpdate() then
		self:raiseActive()
	end
end

function PlaceableHusbandryAnimals:onExternalNavigationMeshLoaded(node, failedReason, args)
	local spec = self.spec_husbandryAnimals
	local loadingTask = unpack(args)

	if node == 0 or node == nil then
		self:finishLoadingTask(loadingTask)
		Logging.error("Missing navigation mesh in external navigation mesh file!")

		return
	end

	spec.navigationMesh = I3DUtil.indexToObject(node, spec.navigationMeshNodePath)

	link(spec.navigationMeshRootNode, spec.navigationMesh)
	delete(node)
	self:finishLoadingTask(loadingTask)
end

function PlaceableHusbandryAnimals:createHusbandry()
	local spec = self.spec_husbandryAnimals

	if spec.navigationMesh == nil then
		Logging.error("Navigation mesh node not defined for animal husbandry!")

		return
	end

	if not getHasClassId(spec.navigationMesh, ClassIds.NAVIGATION_MESH) then
		Logging.error("Given mesh node '%s' is not a navigation mesh!", getName(spec.navigationMesh))

		return
	end

	local collisionMaskFilter = CollisionMask.ANIMAL_SINGLEPLAYER

	if g_currentMission.missionDynamicInfo.isMultiplayer then
		collisionMaskFilter = CollisionMask.ANIMAL_MULTIPLAYER
	end

	local xmlFilename = Utils.getFilename(spec.animalType.configFilename, spec.baseDirectory)
	local husbandry = spec.clusterHusbandry:create(xmlFilename, spec.navigationMesh, spec.placementRaycastDistance, collisionMaskFilter)

	if husbandry == nil or husbandry == 0 then
		Logging.error("Could not create animal husbandry!")

		return
	end

	if husbandry ~= nil then
		g_currentMission.husbandrySystem:addClusterHusbandry(spec.clusterHusbandry)
	end

	SpecializationUtil.raiseEvent(self, "onHusbandryAnimalsCreated", husbandry)
end

function PlaceableHusbandryAnimals:updateInfo(superFunc, infoTable)
	superFunc(self, infoTable)

	local spec = self.spec_husbandryAnimals
	local health = 0
	local numAnimals = 0
	local clusters = spec.clusterSystem:getClusters()
	local numClusters = #clusters

	if numClusters > 0 then
		for _, cluster in ipairs(clusters) do
			health = health + cluster.health
			numAnimals = numAnimals + cluster.numAnimals
		end

		health = health / numClusters
	end

	spec.infoNumAnimals.text = string.format("%d", numAnimals)
	spec.infoHealth.text = string.format("%d %%", health)

	table.insert(infoTable, spec.infoNumAnimals)
	table.insert(infoTable, spec.infoHealth)
end

function PlaceableHusbandryAnimals:getNeedDayChanged(superFunc)
	return true
end

function PlaceableHusbandryAnimals:onMissionStarted()
	self:updateVisualAnimals()
end

function PlaceableHusbandryAnimals:updateVisualAnimals()
	local spec = self.spec_husbandryAnimals
	local clusters = spec.clusterSystem:getClusters()

	spec.clusterHusbandry:setClusters(clusters)
	self:raiseActive()
end

function PlaceableHusbandryAnimals:getAnimalTypeIndex()
	local spec = self.spec_husbandryAnimals

	return spec.animalTypeIndex
end

function PlaceableHusbandryAnimals:updateOutput(superFunc, foodFactor, productionFactor, globalProductionFactor)
	if self.isServer then
		local spec = self.spec_husbandryAnimals
		local clusters = spec.clusterSystem:getClusters()

		for _, cluster in ipairs(clusters) do
			cluster:updateHealth(foodFactor)
		end

		self:raiseActive()
	end

	superFunc(self, foodFactor, productionFactor, globalProductionFactor)
end

function PlaceableHusbandryAnimals:onPeriodChanged()
	if self.isServer then
		local spec = self.spec_husbandryAnimals
		local clusters = spec.clusterSystem:getClusters()
		local totalNumAnimals = self:getNumOfAnimals()
		local freeSlots = math.max(spec.maxNumAnimals - totalNumAnimals, 0)

		for _, cluster in ipairs(clusters) do
			cluster:onPeriodChanged()

			local numNewAnimals = cluster:updateReproduction()

			if numNewAnimals > 0 then
				numNewAnimals = math.min(freeSlots, numNewAnimals)

				if numNewAnimals > 0 then
					local newCluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(cluster:getSubTypeIndex())
					newCluster.numAnimals = numNewAnimals
					freeSlots = freeSlots - numNewAnimals

					spec.clusterSystem:addPendingAddCluster(newCluster)

					local subType = g_currentMission.animalSystem:getSubTypeByIndex(cluster:getSubTypeIndex())
					local animalType = g_currentMission.animalSystem:getTypeByIndex(subType.typeIndex)

					if animalType.statsBreedingName ~= nil then
						local stats = g_currentMission:farmStats(self:getOwnerFarmId())

						stats:updateStats(animalType.statsBreedingName, newCluster.numAnimals)
					end
				end
			end
		end

		self:raiseActive()
	end
end

function PlaceableHusbandryAnimals:onDayChanged()
	if self.isServer then
		local spec = self.spec_husbandryAnimals
		local clusters = spec.clusterSystem:getClusters()

		for _, cluster in ipairs(clusters) do
			cluster:onDayChanged()
		end
	end
end

function PlaceableHusbandryAnimals:getNumOfAnimals()
	local spec = self.spec_husbandryAnimals
	local numAnimals = 0
	local clusters = spec.clusterSystem:getClusters()

	for _, cluster in ipairs(clusters) do
		numAnimals = numAnimals + cluster.numAnimals
	end

	return numAnimals
end

function PlaceableHusbandryAnimals:getMaxNumOfAnimals()
	local spec = self.spec_husbandryAnimals

	return spec.maxNumAnimals
end

function PlaceableHusbandryAnimals:getNumOfFreeAnimalSlots()
	local spec = self.spec_husbandryAnimals
	local totalNumAnimals = self:getNumOfAnimals()

	return math.max(spec.maxNumAnimals - totalNumAnimals, 0)
end

function PlaceableHusbandryAnimals:getSupportsAnimalSubType(subTypeIndex)
	local spec = self.spec_husbandryAnimals
	local animalSystem = g_currentMission.animalSystem
	local subType = animalSystem:getSubTypeByIndex(subTypeIndex)

	return spec.animalTypeIndex == subType.typeIndex
end

function PlaceableHusbandryAnimals:getNumOfClusters()
	local spec = self.spec_husbandryAnimals
	local clusters = spec.clusterSystem:getClusters()

	return #clusters
end

function PlaceableHusbandryAnimals:getClusters()
	local spec = self.spec_husbandryAnimals

	return spec.clusterSystem:getClusters()
end

function PlaceableHusbandryAnimals:getCluster(index)
	local spec = self.spec_husbandryAnimals

	return spec.clusterSystem:getCluster(index)
end

function PlaceableHusbandryAnimals:getClusterById(id)
	local spec = self.spec_husbandryAnimals

	return spec.clusterSystem:getClusterById(id)
end

function PlaceableHusbandryAnimals:addCluster(cluster)
	if cluster ~= nil then
		local spec = self.spec_husbandryAnimals

		spec.clusterSystem:addPendingAddCluster(cluster)
		self:raiseActive()
	end
end

function PlaceableHusbandryAnimals:addAnimals(subTypeIndex, numAnimals, age)
	local cluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(subTypeIndex)

	if cluster:getSupportsMerging() then
		cluster.numAnimals = numAnimals
		cluster.age = age
		cluster.subTypeIndex = subTypeIndex

		self:addCluster(cluster)
	else
		for i = 1, numAnimals do
			cluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
			cluster.numAnimals = 1
			cluster.age = age

			self:addCluster(cluster)
		end
	end
end

function PlaceableHusbandryAnimals:getClusterSystem()
	local spec = self.spec_husbandryAnimals

	return spec.clusterSystem
end

function PlaceableHusbandryAnimals:updatedClusters(husbandry)
	if husbandry == self then
		local spec = self.spec_husbandryAnimals
		local clusters = spec.clusterSystem:getClusters()

		SpecializationUtil.raiseEvent(self, "onHusbandryAnimalsUpdate", clusters)
		g_messageCenter:publish(MessageType.HUSBANDRY_ANIMALS_CHANGED, self)

		spec.updateVisuals = true

		self:raiseActive()
	end
end

function PlaceableHusbandryAnimals:renameAnimal(clusterId, name, noEventSend)
	local spec = self.spec_husbandryAnimals

	AnimalNameEvent.sendEvent(self, clusterId, name, noEventSend)

	local cluster = spec.clusterSystem:getClusterById(clusterId)

	if cluster ~= nil then
		cluster:setName(name)
	end
end

function PlaceableHusbandryAnimals:getAnimalSupportsRiding(clusterId)
	local spec = self.spec_husbandryAnimals
	local cluster = spec.clusterSystem:getClusterById(clusterId)

	if cluster ~= nil then
		local filename = cluster:getRidableFilename()

		if filename ~= nil then
			return true
		end
	end

	return false
end

function PlaceableHusbandryAnimals:getAnimalCanBeRidden(clusterId)
	return g_currentMission.husbandrySystem:getCanAddRideable(self:getOwnerFarmId())
end

function PlaceableHusbandryAnimals:startRiding(clusterId, player)
	if not self.isServer then
		g_client:getServerConnection():sendEvent(AnimalRidingEvent.new(self, clusterId, player))
	else
		local spec = self.spec_husbandryAnimals
		local cluster = spec.clusterSystem:getClusterById(clusterId)

		if cluster ~= nil then
			local x, _, z, _, ry, _ = spec.clusterHusbandry:getAnimalPosition(clusterId)

			if x ~= nil then
				local farmId = self:getOwnerFarmId()
				local filename = cluster:getRidableFilename()
				local location = {
					x = x,
					z = z,
					yRot = ry
				}

				VehicleLoadingUtil.loadVehicle(filename, location, true, 0, Vehicle.PROPERTY_STATE_OWNED, farmId, nil, , self.onLoadedRideable, self, {
					player,
					cluster
				})
			end
		end
	end
end

function PlaceableHusbandryAnimals:onLoadedRideable(rideableVehicle, vehicleLoadState, arguments)
	local player, cluster = unpack(arguments)

	if rideableVehicle == nil then
		return
	end

	if vehicleLoadState ~= VehicleLoadingUtil.VEHICLE_LOAD_OK then
		rideableVehicle:delete()

		return
	end

	local newCluster = cluster:clone()

	newCluster:changeNumAnimals(1)
	rideableVehicle:setCluster(newCluster)
	rideableVehicle:setPlayerToEnter(player)

	local spec = self.spec_husbandryAnimals

	cluster:changeNumAnimals(-1)
	spec.clusterSystem:updateNow()
end

function PlaceableHusbandryAnimals:loadDeliveryArea(xmlFile, key, area)
	local start = xmlFile:getValue(key .. "#startNode", nil, self.components, self.i3dMappings)

	if start == nil then
		Logging.xmlWarning(xmlFile, "Delivery area start node not defined for '%s'", key)

		return false
	end

	local width = xmlFile:getValue(key .. "#widthNode", nil, self.components, self.i3dMappings)

	if width == nil then
		Logging.xmlWarning(xmlFile, "Delivery area width node not defined for '%s'", key)

		return false
	end

	local height = xmlFile:getValue(key .. "#heightNode", nil, self.components, self.i3dMappings)

	if height == nil then
		Logging.xmlWarning(xmlFile, "Delivery area height node not defined for '%s'", key)

		return false
	end

	area.start = start
	area.width = width
	area.height = height

	return true
end

function PlaceableHusbandryAnimals:getIsInAnimalDeliveryArea(x, z)
	local spec = self.spec_husbandryAnimals

	for _, deliveryArea in ipairs(spec.deliveryAreas) do
		local startX, _, startZ = getWorldTranslation(deliveryArea.start)
		local widthX, _, widthZ = getWorldTranslation(deliveryArea.width)
		local heightX, _, heightZ = getWorldTranslation(deliveryArea.height)
		widthZ = widthZ - startZ
		widthX = widthX - startX
		heightZ = heightZ - startZ
		heightX = heightX - startX
		local inArea = MathUtil.isPointInParallelogram(x, z, startX, startZ, widthX, widthZ, heightX, heightZ)

		if inArea then
			return true
		end
	end

	if #spec.deliveryAreas == 0 then
		local px, _, pz = getWorldTranslation(self.rootNode)

		if MathUtil.vector2Length(px - x, pz - z) < 30 then
			return true
		end
	end

	return false
end

function PlaceableHusbandryAnimals.loadSpecValueNumberAnimals(xmlFile, customEnvironment)
	local data = nil

	if xmlFile:hasProperty("placeable.husbandry.animals") then
		local maxNumAnimals = xmlFile:getInt("placeable.husbandry.animals#maxNumAnimals", 16)
		local animalTypeName = xmlFile:getString("placeable.husbandry.animals#type")
		data = {
			maxNumAnimals = maxNumAnimals,
			animalTypeName = animalTypeName
		}
	end

	return data
end

function PlaceableHusbandryAnimals.getSpecValueNumberAnimals(storeItem, realItem)
	local data = storeItem.specs.numberAnimals

	if data == nil then
		return nil
	end

	local profile = nil
	local animalTypeIndex = g_currentMission.animalSystem:getTypeIndexByName(data.animalTypeName)

	if animalTypeIndex == AnimalType.COW then
		profile = "shopListAttributeIconCow"
	elseif animalTypeIndex == AnimalType.SHEEP then
		profile = "shopListAttributeIconSheep"
	elseif animalTypeIndex == AnimalType.HORSE then
		profile = "shopListAttributeIconHorse"
	elseif animalTypeIndex == AnimalType.PIG then
		profile = "shopListAttributeIconPig"
	elseif animalTypeIndex == AnimalType.CHICKEN then
		profile = "shopListAttributeIconChicken"
	end

	return data.maxNumAnimals, profile
end

function PlaceableHusbandryAnimals:onInfoTriggerEnter()
	if self.isServer then
		addConsoleCommand("gsHusbandryAddAnimals", "Add animals to husbandry", "consoleCommandAddAnimals", self)
	end
end

function PlaceableHusbandryAnimals:onInfoTriggerLeave()
	if self.isServer then
		removeConsoleCommand("gsHusbandryAddAnimals")
	end
end

function PlaceableHusbandryAnimals:canBeSold(superFunc)
	if self:getNumOfAnimals() > 0 then
		return false, g_i18n:getText("info_husbandryNotEmpty")
	end

	return superFunc(self)
end

function PlaceableHusbandryAnimals:getConditionInfos(superFunc)
	local infos = superFunc(self)
	local spec = self.spec_husbandryAnimals

	if self:getAnimalTypeIndex() ~= AnimalType.HORSE then
		local productivity = self:getGlobalProductionFactor()
		spec.info.value = productivity
		spec.info.ratio = productivity
		spec.info.valueText = string.format("%d %%", g_i18n:formatNumber(productivity * 100, 0))

		table.insert(infos, spec.info)
	end

	return infos
end

function PlaceableHusbandryAnimals:getAnimalInfos(superFunc, cluster)
	local infos = superFunc(self)

	cluster:addInfos(infos)

	return infos
end

function PlaceableHusbandryAnimals:consoleCommandAddAnimals(numAnimals, subTypeIndex)
	local spec = self.spec_husbandryAnimals
	numAnimals = tonumber(numAnimals) or 0
	subTypeIndex = tonumber(subTypeIndex) or 1

	if self:getNumOfFreeAnimalSlots() == 0 then
		return "Husbandry is full"
	end

	numAnimals = math.min(numAnimals, self:getNumOfFreeAnimalSlots())

	if numAnimals > 0 then
		local globalSubTypeIndex = spec.animalType.subTypes[subTypeIndex]

		if globalSubTypeIndex ~= nil then
			local newCluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(globalSubTypeIndex)
			newCluster.numAnimals = numAnimals

			spec.clusterSystem:addPendingAddCluster(newCluster)
			self:raiseActive()

			return "Added " .. numAnimals .. " animals"
		else
			return "Invalid subtype index"
		end
	else
		return "Invalid number of animals"
	end
end
