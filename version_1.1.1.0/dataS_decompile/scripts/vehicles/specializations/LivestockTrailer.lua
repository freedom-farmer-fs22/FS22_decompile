LivestockTrailer = {}

function LivestockTrailer.initSpecialization()
	g_storeManager:addSpecType("numAnimalsCow", "shopListAttributeIconCow", LivestockTrailer.loadSpecValueNumberAnimalsCow, LivestockTrailer.getSpecValueNumberAnimalsCow, "vehicle")
	g_storeManager:addSpecType("numAnimalsPig", "shopListAttributeIconPig", LivestockTrailer.loadSpecValueNumberAnimalsPig, LivestockTrailer.getSpecValueNumberAnimalsPig, "vehicle")
	g_storeManager:addSpecType("numAnimalsSheep", "shopListAttributeIconSheep", LivestockTrailer.loadSpecValueNumberAnimalsSheep, LivestockTrailer.getSpecValueNumberAnimalsSheep, "vehicle")
	g_storeManager:addSpecType("numAnimalsHorse", "shopListAttributeIconHorse", LivestockTrailer.loadSpecValueNumberAnimalsHorse, LivestockTrailer.getSpecValueNumberAnimalsHorse, "vehicle")

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("LivestockTrailer")
	schema:register(XMLValueType.STRING, "vehicle.livestockTrailer.animal(?)#type", "Animal type name")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.livestockTrailer.animal(?)#node", "Animal node")
	schema:register(XMLValueType.INT, "vehicle.livestockTrailer.animal(?)#numSlots", "Number of slots")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.livestockTrailer.loadTrigger#node", "Load trigger node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.livestockTrailer.spawnPlaces.spawnPlace(?)#node", "Unload spawn places")
	schema:register(XMLValueType.FLOAT, "vehicle.livestockTrailer.spawnPlaces.spawnPlace(?)#width", "Unloading width", 15)
	schema:setXMLSpecializationType()

	local savegameSchema = Vehicle.xmlSchemaSavegame

	savegameSchema:register(XMLValueType.STRING, "vehicles.vehicle(?).livestockTrailer#animalType", "Animal type name")
	AnimalClusterSystem.registerSavegameXMLPaths(savegameSchema, "vehicles.vehicle(?).livestockTrailer")
end

function LivestockTrailer.prerequisitesPresent(specializations)
	return true
end

function LivestockTrailer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentAnimalType", LivestockTrailer.getCurrentAnimalType)
	SpecializationUtil.registerFunction(vehicleType, "getSupportsAnimalType", LivestockTrailer.getSupportsAnimalType)
	SpecializationUtil.registerFunction(vehicleType, "getSupportsAnimalSubType", LivestockTrailer.getSupportsAnimalSubType)
	SpecializationUtil.registerFunction(vehicleType, "setLoadingTrigger", LivestockTrailer.setLoadingTrigger)
	SpecializationUtil.registerFunction(vehicleType, "getLoadingTrigger", LivestockTrailer.getLoadingTrigger)
	SpecializationUtil.registerFunction(vehicleType, "updateAnimals", LivestockTrailer.updateAnimals)
	SpecializationUtil.registerFunction(vehicleType, "updatedClusters", LivestockTrailer.updatedClusters)
	SpecializationUtil.registerFunction(vehicleType, "clearAnimals", LivestockTrailer.clearAnimals)
	SpecializationUtil.registerFunction(vehicleType, "addAnimals", LivestockTrailer.addAnimals)
	SpecializationUtil.registerFunction(vehicleType, "addCluster", LivestockTrailer.addCluster)
	SpecializationUtil.registerFunction(vehicleType, "getClusters", LivestockTrailer.getClusters)
	SpecializationUtil.registerFunction(vehicleType, "getRideablesInTrigger", LivestockTrailer.getRideablesInTrigger)
	SpecializationUtil.registerFunction(vehicleType, "getClusterById", LivestockTrailer.getClusterById)
	SpecializationUtil.registerFunction(vehicleType, "getClusterSystem", LivestockTrailer.getClusterSystem)
	SpecializationUtil.registerFunction(vehicleType, "getNumOfAnimals", LivestockTrailer.getNumOfAnimals)
	SpecializationUtil.registerFunction(vehicleType, "getMaxNumOfAnimals", LivestockTrailer.getMaxNumOfAnimals)
	SpecializationUtil.registerFunction(vehicleType, "getNumOfFreeAnimalSlots", LivestockTrailer.getNumOfFreeAnimalSlots)
	SpecializationUtil.registerFunction(vehicleType, "onAnimalLoaded", LivestockTrailer.onAnimalLoaded)
	SpecializationUtil.registerFunction(vehicleType, "onAnimalLoadTriggerCallback", LivestockTrailer.onAnimalLoadTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "getAnimalUnloadPlaces", LivestockTrailer.getAnimalUnloadPlaces)
	SpecializationUtil.registerFunction(vehicleType, "setAnimalScreenController", LivestockTrailer.setAnimalScreenController)
	SpecializationUtil.registerFunction(vehicleType, "onAnimalRideableDeleted", LivestockTrailer.onAnimalRideableDeleted)
end

function LivestockTrailer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalComponentMass", LivestockTrailer.getAdditionalComponentMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSellPrice", LivestockTrailer.getSellPrice)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "dayChanged", LivestockTrailer.dayChanged)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "periodChanged", LivestockTrailer.periodChanged)
end

function LivestockTrailer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", LivestockTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", LivestockTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", LivestockTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", LivestockTrailer)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", LivestockTrailer)
end

function LivestockTrailer:onLoad(savegame)
	local spec = self.spec_livestockTrailer
	spec.animalPlaces = {}
	spec.animalTypeIndexToPlaces = {}
	local i = 0

	while true do
		local key = string.format("vehicle.livestockTrailer.animal(%d)", i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local place = {
			numUsed = 0
		}
		local animalTypeStr = self.xmlFile:getValue(key .. "#type")
		local animalTypeIndex = g_currentMission.animalSystem:getTypeIndexByName(animalTypeStr)

		if animalTypeIndex == nil then
			Logging.xmlWarning(self.xmlFile, "Animal type '%s' could not be found!", animalTypeStr)

			break
		end

		place.animalTypeIndex = animalTypeIndex
		place.slots = {}
		local parent = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
		local numSlots = math.abs(self.xmlFile:getValue(key .. "#numSlots", 0))

		if getNumOfChildren(parent) < numSlots then
			Logging.xmlWarning(self.xmlFile, "numSlots is greater than available children for '%s'", key)

			numSlots = getNumOfChildren(parent)
		end

		for j = 0, numSlots - 1 do
			local slotNode = getChildAt(parent, j)

			table.insert(place.slots, {
				linkNode = slotNode,
				place = place
			})
		end

		table.insert(spec.animalPlaces, place)

		spec.animalTypeIndexToPlaces[place.animalTypeIndex] = place
		i = i + 1
	end

	local trigger = self.xmlFile:getValue("vehicle.livestockTrailer.loadTrigger#node", nil, self.components, self.i3dMappings)

	if trigger ~= nil then
		addTrigger(trigger, "onAnimalLoadTriggerCallback", self)

		spec.triggerNode = trigger
	end

	spec.rideablesInTrigger = {}
	spec.spawnPlaces = {}

	self.xmlFile:iterate("vehicle.livestockTrailer.spawnPlaces.spawnPlace", function (_, key)
		local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
		local width = self.xmlFile:getValue(key .. "#width", 5)

		if node ~= nil then
			table.insert(spec.spawnPlaces, {
				node = node,
				width = width
			})
		end
	end)

	if #spec.spawnPlaces > 0 or spec.triggerNode ~= nil then
		spec.activatable = LivestockTrailerActivatable.new(self)

		if g_currentMission ~= nil then
			g_currentMission.activatableObjectsSystem:addActivatable(spec.activatable)
		end
	end

	spec.clusterSystem = AnimalClusterSystem.new(self.isServer, self)

	g_messageCenter:subscribe(AnimalClusterUpdateEvent, self.updatedClusters, self)

	spec.loadingTrigger = nil
	spec.animalScreenController = nil

	if g_currentMission ~= nil then
		g_currentMission.husbandrySystem:addLivestockTrailer(self)
	end
end

function LivestockTrailer:onLoadFinished(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		local spec = self.spec_livestockTrailer
		local xmlFile = savegame.xmlFile
		local key = savegame.key

		spec.clusterSystem:loadFromXMLFile(xmlFile, key .. ".livestockTrailer")
		spec.clusterSystem:updateNow()
	end
end

function LivestockTrailer:onDelete()
	self:clearAnimals()
	g_messageCenter:unsubscribe(AnimalClusterUpdateEvent, self)

	if g_currentMission ~= nil then
		g_currentMission.husbandrySystem:removeLivestockTrailer(self)
	end

	local spec = self.spec_livestockTrailer

	if spec.triggerNode ~= nil then
		removeTrigger(spec.triggerNode)
	end

	if spec.activatable ~= nil then
		g_currentMission.activatableObjectsSystem:removeActivatable(spec.activatable)
	end

	if spec.loadingTrigger ~= nil then
		spec.loadingTrigger:setLoadingTrailer(nil)
	end
end

function LivestockTrailer:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_livestockTrailer

	spec.clusterSystem:saveToXMLFile(xmlFile, key, usedModNames)
end

function LivestockTrailer:onReadStream(streamId, connection)
	local spec = self.spec_livestockTrailer

	spec.clusterSystem:readStream(streamId, connection)
end

function LivestockTrailer:onWriteStream(streamId, connection)
	local spec = self.spec_livestockTrailer

	spec.clusterSystem:writeStream(streamId, connection)
end

function LivestockTrailer:getSupportsAnimalType(animalTypeIndex)
	return self.spec_livestockTrailer.animalTypeIndexToPlaces[animalTypeIndex] ~= nil
end

function LivestockTrailer:getSupportsAnimalSubType(subTypeIndex)
	local animalSystem = g_currentMission.animalSystem
	local subType = animalSystem:getSubTypeByIndex(subTypeIndex)
	local animalType = animalSystem:getTypeByIndex(subType.typeIndex)

	return self:getSupportsAnimalType(animalType.typeIndex)
end

function LivestockTrailer:getCurrentAnimalType()
	local spec = self.spec_livestockTrailer
	local clusters = spec.clusterSystem:getClusters()

	if #clusters == 0 then
		return nil
	end

	local animalSystem = g_currentMission.animalSystem
	local subTypeIndex = clusters[1]:getSubTypeIndex()
	local subType = animalSystem:getSubTypeByIndex(subTypeIndex)
	local animalType = animalSystem:getTypeByIndex(subType.typeIndex)

	return animalType
end

function LivestockTrailer:setLoadingTrigger(trigger)
	self.spec_livestockTrailer.loadingTrigger = trigger
end

function LivestockTrailer:getLoadingTrigger()
	return self.spec_livestockTrailer.loadingTrigger
end

function LivestockTrailer:setAnimalScreenController(controller)
	self.spec_livestockTrailer.animalScreenController = controller
end

function LivestockTrailer:addAnimals(subTypeIndex, numAnimals, age)
	local cluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(subTypeIndex)

	if cluster:getSupportsMerging() then
		cluster.numAnimals = numAnimals
		cluster.age = age

		self:addCluster(cluster)
	else
		for i = 1, numAnimals do
			if i > 1 then
				cluster = g_currentMission.animalSystem:createClusterFromSubTypeIndex(subTypeIndex)
			end

			cluster.numAnimals = 1
			cluster.age = age

			self:addCluster(cluster)
		end
	end
end

function LivestockTrailer:addCluster(cluster)
	local spec = self.spec_livestockTrailer

	spec.clusterSystem:addPendingAddCluster(cluster)
	spec.clusterSystem:updateNow()
end

function LivestockTrailer:getClusters()
	local spec = self.spec_livestockTrailer

	return spec.clusterSystem:getClusters()
end

function LivestockTrailer:getRideablesInTrigger()
	local spec = self.spec_livestockTrailer

	return spec.rideablesInTrigger
end

function LivestockTrailer:getClusterById(id)
	local spec = self.spec_livestockTrailer

	return spec.clusterSystem:getClusterById(id)
end

function LivestockTrailer:getClusterSystem()
	local spec = self.spec_livestockTrailer

	return spec.clusterSystem
end

function LivestockTrailer:getNumOfAnimals()
	local spec = self.spec_livestockTrailer
	local clusters = spec.clusterSystem:getClusters()

	if #clusters == 0 then
		return 0
	end

	local subTypeIndex = clusters[1]:getSubTypeIndex()
	local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
	local place = spec.animalTypeIndexToPlaces[subType.typeIndex]

	return place.usedSlots or 0
end

function LivestockTrailer:getMaxNumOfAnimals(animalType)
	local spec = self.spec_livestockTrailer
	local currentAnimalType = self:getCurrentAnimalType()

	if animalType == nil and currentAnimalType == nil then
		return 0
	end

	if currentAnimalType ~= nil and animalType ~= currentAnimalType then
		return 0
	end

	animalType = animalType or currentAnimalType

	if not self:getSupportsAnimalType(animalType.typeIndex) then
		return 0
	end

	local place = spec.animalTypeIndexToPlaces[animalType.typeIndex]

	return #place.slots
end

function LivestockTrailer:getNumOfFreeAnimalSlots(subTypeIndex)
	local animalSystem = g_currentMission.animalSystem
	local subType = animalSystem:getSubTypeByIndex(subTypeIndex)
	local animalType = animalSystem:getTypeByIndex(subType.typeIndex)
	local used = self:getNumOfAnimals()
	local total = self:getMaxNumOfAnimals(animalType)

	return total - used
end

function LivestockTrailer:updatedClusters(trailer)
	if trailer == self then
		self:updateAnimals()
		self:setMassDirty()
	end
end

function LivestockTrailer:updateAnimals()
	local spec = self.spec_livestockTrailer

	self:clearAnimals()

	local slotIndex = 1
	local clusters = spec.clusterSystem:getClusters()
	local animalType = self:getCurrentAnimalType()

	if animalType ~= nil then
		local place = spec.animalTypeIndexToPlaces[animalType.typeIndex]
		place.usedSlots = 0

		for _, cluster in ipairs(clusters) do
			for i = 1, cluster:getNumAnimals() do
				local slot = place.slots[slotIndex]
				slot.meshLoadingInProgress = true
				local visual = g_currentMission.animalSystem:getVisualByAge(cluster:getSubTypeIndex(), cluster:getAge())
				local filename = visual.visualAnimal.filenamePosed
				slot.filename = filename
				local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.onAnimalLoaded, self, {
					slot,
					visual
				})
				slot.sharedLoadRequestId = sharedLoadRequestId
				slotIndex = slotIndex + 1
				place.usedSlots = place.usedSlots + 1
			end
		end
	end
end

function LivestockTrailer:clearAnimals()
	local spec = self.spec_livestockTrailer

	if spec.animalTypeIndexToPlaces ~= nil then
		for _, place in pairs(spec.animalTypeIndexToPlaces) do
			for _, slot in ipairs(place.slots) do
				if slot.sharedLoadRequestId ~= nil then
					g_i3DManager:releaseSharedI3DFile(slot.sharedLoadRequestId)

					slot.sharedLoadRequestId = nil
				end

				if slot.loadedMesh ~= nil then
					delete(slot.loadedMesh)

					slot.loadedMesh = nil
				end
			end
		end
	end
end

function LivestockTrailer:onAnimalLoaded(i3dNode, failedReason, args)
	local slot, visual = unpack(args)

	if i3dNode ~= 0 then
		link(slot.linkNode, i3dNode)

		slot.loadedMesh = i3dNode
		slot.meshLoadingInProgress = false
		local variations = visual.visualAnimal.variations[1]
		local tileU = variations.tileUIndex / variations.numTilesU
		local tileV = variations.tileVIndex / variations.numTilesV

		I3DUtil.setShaderParameterRec(i3dNode, "atlasInvSizeAndOffsetUV", nil, , tileU, tileV, false)
		I3DUtil.setShaderParameterRec(i3dNode, "RDT", nil, 0, nil, , false)
	end
end

function LivestockTrailer:getAdditionalComponentMass(superFunc, component)
	local additionalMass = superFunc(self, component)
	local spec = self.spec_livestockTrailer
	local clusters = spec.clusterSystem:getClusters()

	for _, cluster in ipairs(clusters) do
		local subTypeIndex = cluster:getSubTypeIndex()
		local subType = g_currentMission.animalSystem:getSubTypeByIndex(subTypeIndex)
		local fillTypeIndex = subType.fillTypeIndex
		local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
		additionalMass = additionalMass + fillType.massPerLiter * cluster:getNumAnimals()
	end

	return additionalMass
end

function LivestockTrailer:getSellPrice(superFunc)
	local sellPrice = superFunc(self)
	local spec = self.spec_livestockTrailer
	local clusters = spec.clusterSystem:getClusters()

	for _, cluster in ipairs(clusters) do
		local sellPriceCluster = cluster:getSellPrice() * cluster:getNumAnimals()
		sellPrice = sellPrice + sellPriceCluster * 0.75
	end

	return sellPrice
end

function LivestockTrailer:dayChanged(superFunc)
	superFunc(self)

	local spec = self.spec_livestockTrailer
	local clusters = spec.clusterSystem:getClusters()

	for _, cluster in ipairs(clusters) do
		cluster:onDayChanged()
	end
end

function LivestockTrailer:periodChanged(superFunc)
	superFunc(self)

	local spec = self.spec_livestockTrailer
	local clusters = spec.clusterSystem:getClusters()

	for _, cluster in ipairs(clusters) do
		cluster:onPeriodChanged()
	end
end

function LivestockTrailer:onAnimalLoadTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter or onLeave then
		local spec = self.spec_livestockTrailer
		local vehicle = g_currentMission.nodeToObject[otherId]

		if vehicle ~= nil and vehicle.spec_rideable ~= nil then
			local cluster = vehicle:getCluster()

			if cluster ~= nil then
				local subTypeIndex = cluster:getSubTypeIndex()

				if self:getSupportsAnimalSubType(subTypeIndex) then
					if onEnter then
						table.addElement(spec.rideablesInTrigger, vehicle)
						vehicle:addDeleteListener(self, "onAnimalRideableDeleted")
					else
						table.removeElement(spec.rideablesInTrigger, vehicle)
						vehicle:removeDeleteListener(self, "onAnimalRideableDeleted")
					end

					if spec.animalScreenController ~= nil then
						spec.animalScreenController:onAnimalsChanged(self, nil)
					end
				end
			end
		end
	end
end

function LivestockTrailer:onAnimalRideableDeleted(rideable)
	local spec = self.spec_livestockTrailer

	table.removeElement(spec.rideablesInTrigger, rideable)

	if spec.animalScreenController ~= nil then
		spec.animalScreenController:onAnimalsChanged(self, nil)
	end
end

function LivestockTrailer:getAnimalUnloadPlaces()
	local spec = self.spec_livestockTrailer
	local places = {}

	for _, spawnPlace in ipairs(spec.spawnPlaces) do
		local node = spawnPlace.node
		local x, y, z = getWorldTranslation(node)
		local place = {
			startZ = z,
			startY = y,
			startX = x
		}
		place.rotX, place.rotY, place.rotZ = getWorldRotation(node)
		place.dirX, place.dirY, place.dirZ = localDirectionToWorld(node, 1, 0, 0)
		place.dirPerpX, place.dirPerpY, place.dirPerpZ = localDirectionToWorld(node, 0, 0, 1)
		place.yOffset = 1
		place.maxWidth = math.huge
		place.maxLength = math.huge
		place.maxHeight = math.huge
		place.width = spawnPlace.width

		table.insert(places, place)
	end

	return places
end

function LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, animalTypeName)
	local maxNumAnimals = nil
	local i = 0
	local root = xmlFile:getRootName()

	while true do
		local key = string.format("%s.livestockTrailer.animal(%d)", root, i)

		if not xmlFile:hasProperty(key) then
			break
		end

		local typeName = xmlFile:getValue(key .. "#type")

		if typeName ~= nil and string.lower(typeName) == string.lower(animalTypeName) then
			maxNumAnimals = xmlFile:getValue(key .. "#numSlots", 0)

			break
		end

		i = i + 1
	end

	return maxNumAnimals
end

function LivestockTrailer.loadSpecValueNumberAnimalsCow(xmlFile, customEnvironment)
	return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, "cow")
end

function LivestockTrailer.loadSpecValueNumberAnimalsPig(xmlFile, customEnvironment)
	return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, "pig")
end

function LivestockTrailer.loadSpecValueNumberAnimalsSheep(xmlFile, customEnvironment)
	return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, "sheep")
end

function LivestockTrailer.loadSpecValueNumberAnimalsHorse(xmlFile, customEnvironment)
	return LivestockTrailer.loadSpecValueNumberAnimals(xmlFile, customEnvironment, "horse")
end

function LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, specName)
	if storeItem.specs[specName] == nil then
		return nil
	end

	return string.format("%d %s", storeItem.specs[specName], g_i18n:getText("unit_pieces"))
end

function LivestockTrailer.getSpecValueNumberAnimalsCow(storeItem, realItem)
	return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsCow")
end

function LivestockTrailer.getSpecValueNumberAnimalsPig(storeItem, realItem)
	return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsPig")
end

function LivestockTrailer.getSpecValueNumberAnimalsSheep(storeItem, realItem)
	return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsSheep")
end

function LivestockTrailer.getSpecValueNumberAnimalsHorse(storeItem, realItem)
	return LivestockTrailer.getSpecValueNumberAnimals(storeItem, realItem, "numAnimalsHorse")
end

LivestockTrailerActivatable = {}
local LivestockTrailerActivatable_mt = Class(LivestockTrailerActivatable)

function LivestockTrailerActivatable.new(livestockTrailer)
	local self = {}

	setmetatable(self, LivestockTrailerActivatable_mt)

	self.livestockTrailer = livestockTrailer
	self.activateText = g_i18n:getText("action_openLivestockTrailerMenu")

	return self
end

function LivestockTrailerActivatable:getIsActivatable()
	if self.livestockTrailer:getLoadingTrigger() ~= nil then
		return false
	end

	local rideables = self.livestockTrailer:getRideablesInTrigger()

	if #rideables > 0 or self.livestockTrailer:getNumOfAnimals() > 0 then
		if self.livestockTrailer:getIsActiveForInput(true) then
			return true
		end

		for _, rideable in ipairs(rideables) do
			if rideable:getIsActiveForInput(true) then
				return true
			end
		end
	end

	return false
end

function LivestockTrailerActivatable:run()
	local controller = AnimalScreenTrailer.new(self.livestockTrailer)

	controller:init()
	g_animalScreen:setController(controller)
	g_gui:showGui("AnimalScreen")
end
