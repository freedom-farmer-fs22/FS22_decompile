source("dataS/scripts/events/VehicleRemoveEvent.lua")
source("dataS/scripts/events/OnCreateLoadedObjectEvent.lua")

BaseMission = {}
local BaseMission_mt = Class(BaseMission)
BaseMission.STATE_INTRO = 0
BaseMission.STATE_READY = 1
BaseMission.STATE_RUNNING = 2
BaseMission.STATE_FINISHED = 3
BaseMission.STATE_FAILED = 5
BaseMission.STATE_CONTINUED = 6
BaseMission.INPUT_CONTEXT_VEHICLE = "VEHICLE"
BaseMission.INPUT_CONTEXT_PAUSE = "PAUSE"
BaseMission.INPUT_CONTEXT_SYNCHRONIZING = "MP_SYNC"

function BaseMission.new(baseDirectory, customMt, missionCollaborators)
	local self = setmetatable({}, customMt or BaseMission_mt)
	self.baseDirectory = baseDirectory
	self.server = g_server
	self.client = g_client
	self.messageCenter = missionCollaborators.messageCenter
	self.savegameController = missionCollaborators.savegameController
	self.inputManager = missionCollaborators.inputManager
	self.inputDisplayManager = missionCollaborators.inputDisplayManager
	self.achievementManager = missionCollaborators.achievementManager
	self.modManager = missionCollaborators.modManager
	self.fillTypeManager = missionCollaborators.fillTypeManager
	self.fruitTypeManager = missionCollaborators.fruitTypeManager
	self.guiSoundPlayer = missionCollaborators.guiSoundPlayer
	self.hud = nil
	self.placeableSystem = PlaceableSystem.new(self)
	self.itemSystem = ItemSystem.new(self)
	self.beehiveSystem = BeehiveSystem.new(self)
	self.cancelLoading = false
	self.vertexBufferMemoryUsage = 0
	self.indexBufferMemoryUsage = 0
	self.textureMemoryUsage = 0
	self.waitForDLCVerification = false
	self.waitForCorruptDlcs = false
	self.finishedFirstUpdate = false
	self.waterY = -200
	self.isInsideBuilding = false
	self.players = {}
	self.connectionsToPlayer = {}
	self.updateables = {}
	self.nonUpdateables = {}
	self.drawables = {}
	self.triggerMarkers = {}
	self.triggerMarkersAreVisible = true
	self.dynamicallyLoadedObjects = {}
	self.isPlayerFrozen = false
	self.environment = nil
	self.state = BaseMission.STATE_INTRO
	self.isRunning = false
	self.isLoaded = false
	self.numLoadingTasks = 0
	self.isMissionStarted = false
	self.controlledVehicle = nil
	self.controlledVehicles = {}
	self.controlPlayer = true
	self.isToggleVehicleAllowed = true
	self.vehicles = {}
	self.enterables = {}
	self.interactiveVehicles = {}
	self.attachables = {}
	self.inputAttacherJoints = {}
	self.ownedItems = {}
	self.leasedVehicles = {}
	self.vehiclesToDelete = {}
	self.loadSpawnPlaces = {}
	self.storeSpawnPlaces = {}
	self.restrictedZones = {}
	self.usedLoadPlaces = {}
	self.usedStorePlaces = {}
	self.vehiclesToSpawn = {}
	self.vehiclesToSpawnDirty = false
	self.vehiclesToSpawnLoading = false
	self.nodeToObject = {}
	self.onCreateLoadedObjectsToSave = {}
	self.numOnCreateLoadedObjectsToSave = 0
	self.maps = {}
	self.surfaceSounds = {}
	self.cuttingSounds = {}
	self.preSimulateTime = 4000
	self.snapAIDirection = true

	if GS_IS_CONSOLE_VERSION then
		self.maxNumHirables = 6
	elseif GS_IS_MOBILE_VERSION then
		self.maxNumHirables = 4
	else
		self.maxNumHirables = 10
	end

	self.time = 0
	self.activatableObjectsSystem = ActivatableObjectsSystem.new(self)
	self.pauseListeners = {}
	self.paused = false
	self.pressStartPaused = false
	self.manualPaused = false
	self.suspendPaused = false
	self.lastNonPauseGameState = GameState.PLAY
	self.isLoadingMap = false
	self.numLoadingMaps = 0
	self.loadingMapBaseDirectory = ""
	self.onCreateLoadedObjects = {}
	self.objectsToClassName = {}
	self.vehiclesToAttach = {}
	self.lastInteractionTime = -1
	self.isExitingGame = false

	return self
end

function BaseMission:initialize()
	self:subscribeSettingsChangeMessages()
	self:subscribeGuiOpenCloseMessages()
	self.messageCenter:subscribe(MessageType.GAME_STATE_CHANGED, self.onGameStateChange, self)

	self.hud = self:createHUD()
	self.placementManager = PlacementManager.new()
end

function BaseMission:createHUD()
	local class = Platform.isMobile and MobileHUD or HUD
	local hud = class.new(g_server ~= nil, g_client ~= nil, GS_IS_CONSOLE_VERSION, self.messageCenter, g_i18n, self.inputManager, self.inputDisplayManager, self.modManager, self.fillTypeManager, self.fruitTypeManager, self.guiSoundPlayer, self, g_farmManager, g_farmlandManager)

	return hud
end

function BaseMission:delete()
	self.messageCenter:unsubscribeAll(self)

	self.isExitingGame = true
	self.isRunning = false

	self:setMapTargetHotspot(nil)

	if BaseMission.MAP_TARGET_MARKER ~= nil then
		delete(BaseMission.MAP_TARGET_MARKER)

		BaseMission.MAP_TARGET_MARKER = nil
	end

	if self:getIsClient() and not self.controlPlayer and self.controlledVehicle ~= nil then
		self:onLeaveVehicle()
	end

	for k, v in pairs(self.nonUpdateables) do
		v:delete()

		self.nonUpdateables[k] = nil
	end

	if g_server ~= nil then
		g_server:delete()

		g_server = nil
	end

	if g_client ~= nil then
		g_client:delete()

		g_client = nil
	end

	setCamera(g_defaultCamera)

	if self.hud ~= nil then
		self.messageCenter:unsubscribeAll(self.hud)
		self.hud:setEnvironment(nil)
		self.hud:delete()

		self.hud = nil
	end

	if self.placementManager ~= nil then
		self.placementManager:delete()
	end

	if self.player ~= nil then
		self.player:delete()
	end

	if self.trafficSystem ~= nil then
		self.trafficSystem:setEnabled(false)
		self.trafficSystem:reset()
	end

	if self.pedestrianSystem ~= nil then
		self.pedestrianSystem:delete()

		self.pedestrianSystem = nil
	end

	g_terrainDeformationQueue:cancelAllJobs()

	for _, v in pairs(self.vehicles) do
		v:delete()
	end

	self.vehicles = {}
	self.leasedVehicles = {}
	self.ownedItems = {}

	for _, vehicle in ipairs(self.vehiclesToDelete) do
		if not vehicle.isDeleted then
			vehicle:delete()
		end
	end

	self.placeableSystem:delete()
	self.itemSystem:delete()
	self.beehiveSystem:delete()

	for _, object in pairs(self.dynamicallyLoadedObjects) do
		delete(object)
	end

	if self.environment ~= nil then
		self.inGameMenu:setEnvironment(nil)
		self.environment:delete()

		self.environment = nil
	end

	for k, v in pairs(self.updateables) do
		v:delete()

		self.updateables[k] = nil
	end

	for i = #g_modEventListeners, 1, -1 do
		if g_modEventListeners[i].deleteMap ~= nil then
			g_modEventListeners[i]:deleteMap()
		end
	end

	for _, v in pairs(self.maps) do
		delete(v)
	end

	for _, surfaceSound in pairs(self.surfaceSounds) do
		g_soundManager:deleteSample(surfaceSound.sample)
	end

	self.surfaceSounds = {}

	for _, cuttingSound in pairs(self.cuttingSounds) do
		g_soundManager:deleteSample(cuttingSound)
	end

	self.cuttingSounds = {}

	self:unregisterActionEvents()
	removeConsoleCommand("gsCameraFovSet")
	removeConsoleCommand("gsRender360Screenshot")
	removeConsoleCommand("gsVehicleRemoveAll")
	removeConsoleCommand("gsItemRemoveAll")
	self.inputManager:clearAllContexts()
	g_gui:setCurrentMission(nil)
	g_gui:setClient(nil)
end

function BaseMission:load()
	self:startLoadingTask()

	self.controlPlayer = true
	self.controlledVehicle = nil

	addConsoleCommand("gsCameraFovSet", "Sets camera field of view angle", "consoleCommandSetFOV", self)

	if self:getIsServer() and g_addTestCommands then
		addConsoleCommand("gsRender360Screenshot", "Renders 360 screenshots from current camera position", "consoleCommandRender360Screenshot", self)
		addConsoleCommand("gsVehicleRemoveAll", "Removes all vehicles from current mission", "consoleCommandVehicleRemoveAll", self)
		addConsoleCommand("gsItemRemoveAll", "Removes all items from current mission", "consoleCommandItemRemoveAll", self)
	end

	self:finishLoadingTask()
end

function BaseMission:startLoadingTask()
	self.numLoadingTasks = self.numLoadingTasks + 1

	if self.numLoadingTasks == 1 then
		setStreamLowPriorityI3DFiles(false)

		if self.missionDynamicInfo.isMultiplayer then
			netSetIsEventProcessingEnabled(false)
		end
	end
end

function BaseMission:finishLoadingTask()
	self.numLoadingTasks = self.numLoadingTasks - 1

	if self.numLoadingTasks <= 0 then
		if not self.isLoaded then
			self:onFinishedLoading()
		end

		setStreamLowPriorityI3DFiles(true)

		if self.missionDynamicInfo.isMultiplayer then
			netSetIsEventProcessingEnabled(true)
		end
	end
end

function BaseMission:onFinishedLoading()
	self.isLoaded = true

	g_gui:setCurrentMission(self)
	g_gui:setClient(g_client)
end

function BaseMission:canStartMission()
	if self:getIsServer() then
		return true
	end

	for i = 1, #self.vehicles do
		local vehicle = self.vehicles[i]

		if not vehicle:getIsSynchronized() then
			return false
		end
	end

	return self.player ~= nil
end

function BaseMission:onStartMission()
	self:fadeScreen(-1, 1500, nil)

	self.isMissionStarted = true

	self:setShowTriggerMarker(g_gameSettings:getValue("showTriggerMarker"))

	if self:getIsClient() then
		local context = Player.INPUT_CONTEXT_NAME

		if GS_IS_MOBILE_VERSION and self.missionInfo.isNewSPCareer then
			context = Vehicle.INPUT_CONTEXT_NAME
		end

		self.inputManager:setContext(context, true, true)
		self:registerActionEvents()
		self:registerPauseActionEvents()
	end
end

function BaseMission:onObjectCreated(object)
	if object:isa(Player) then
		self.players[object.rootNode] = object

		if object.isOwner then
			self.player = object

			self.inGameMenu:setPlayer(object)
			self.hud:setPlayer(object)
		end

		if self:getIsServer() then
			self.connectionsToPlayer[object.networkInformation.creatorConnection] = object
		end

		g_messageCenter:publish(MessageType.PLAYER_CREATED, object)
	elseif object:isa(Vehicle) or object:isa(RailroadVehicle) then
		self:addVehicle(object)
	elseif object:isa(Farm) then
		g_farmManager:onFarmObjectCreated(object)
	end
end

function BaseMission:onObjectDeleted(object)
	if object:isa(Player) then
		if self.player == object then
			self.player = nil
		end

		self.players[object.rootNode] = nil

		if self:getIsServer() then
			self.connectionsToPlayer[object.networkInformation.creatorConnection] = nil
		end
	elseif object:isa(Vehicle) or object:isa(RailroadVehicle) then
		if object.isAddedToMission then
			self:removeVehicle(object, false)
		end
	elseif object:isa(Farm) then
		g_farmManager:onFarmObjectDeleted(object)
	end
end

function BaseMission:loadMap(filename, addPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	if addPhysics == nil then
		addPhysics = true
	end

	local modMapName, baseDirectory = Utils.getModNameAndBaseDirectory(filename)

	if self.numLoadingMaps == 0 then
		self.loadingMapModName = modMapName
		self.loadingMapBaseDirectory = baseDirectory

		resetModOnCreateFunctions()

		for modName, loaded in pairs(g_modIsLoaded) do
			if loaded and not g_modManager:isModMap(modName) then
				_G[modName].g_onCreateUtil.activateOnCreateFunctions()
			end
		end

		if modMapName ~= nil then
			_G[modMapName].g_onCreateUtil.activateOnCreateFunctions()
		end

		self.isLoadingMap = true
	elseif self.loadingMapBaseDirectory ~= baseDirectory then
		print("Warning: Asynchronous map loading from different mods. onCreate functions will not work correctly")
	end

	self.numLoadingMaps = self.numLoadingMaps + 1

	if asyncCallbackFunction ~= nil then
		g_i3DManager:loadI3DFileAsync(filename, true, addPhysics, self.loadMapFinished, self, {
			filename,
			asyncCallbackFunction,
			asyncCallbackObject,
			asyncCallbackArguments
		})
	else
		Logging.error("Loading the map in sync is not allowed anymore! Please call loadMap with a async callback.")
		printCallstack()
	end
end

function BaseMission:loadMapFinished(node, failedReason, arguments, callAsyncCallback)
	g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.MAP)

	local filename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments = unpack(arguments)

	if node ~= 0 then
		self:findDynamicObjects(node)
	end

	self.numLoadingMaps = self.numLoadingMaps - 1

	if self.numLoadingMaps == 0 then
		self.isLoadingMap = false

		resetModOnCreateFunctions()

		self.loadingMapModName = nil
		self.loadingMapBaseDirectory = ""
	end

	if node ~= 0 and not g_currentMission.cancelLoading then
		table.insert(self.maps, node)
		link(getRootNode(), node)
	end

	for _, v in pairs(g_modEventListeners) do
		if v.loadMap ~= nil then
			v:loadMap(filename)
		end
	end

	if not self.cancelLoading then
		self:setShowFieldInfo(g_gameSettings:getValue("showFieldInfo"))
	end

	if (callAsyncCallback == nil or callAsyncCallback) and asyncCallbackFunction ~= nil then
		asyncCallbackFunction(asyncCallbackObject, node, asyncCallbackArguments)
	end
end

function BaseMission:findDynamicObjects(node)
	for i = 1, getNumOfChildren(node) do
		local c = getChildAt(node, i - 1)

		if RigidBodyType.DYNAMIC == getRigidBodyType(c) then
			if (not getHasClassId(c, ClassIds.SHAPE) or getSplitType(c) == 0) and self.missionDynamicInfo.isMultiplayer then
				local mpCreatePhysicsObject = Utils.getNoNil(getUserAttribute(c, "mpCreatePhysicsObject"), false)
				local mpRemoveRigidBody = Utils.getNoNil(getUserAttribute(c, "mpRemoveRigidBody"), true)

				if mpCreatePhysicsObject then
					local object = PhysicsObject.new(self:getIsServer(), self:getIsClient())

					g_currentMission:addOnCreateLoadedObject(object)
					object:loadOnCreate(c)
					object:register(true)
				elseif mpRemoveRigidBody then
					setRigidBodyType(c, RigidBodyType.NONE)
				end
			end
		else
			self:findDynamicObjects(c)
		end
	end
end

function BaseMission:loadMapSounds(xmlFilename, baseDirectory)
	if not self:getIsClient() then
		return
	end

	local xmlFile = loadXMLFile("mapSoundXML", xmlFilename)
	self.surfaceSounds = {}
	local i = 0

	while true do
		local key = string.format("sound.surface.material(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local entry = {}
		local audioGroup = AudioGroup.ENVIRONMENT
		entry.type = Utils.getNoNil(getXMLString(xmlFile, key .. "#type"), "wheel")

		if entry.type == "wheel" then
			audioGroup = AudioGroup.VEHICLE
		end

		entry.materialId = getXMLInt(xmlFile, key .. "#materialId")
		entry.name = getXMLString(xmlFile, key .. "#name")
		local loopCount = getXMLInt(xmlFile, key .. "#loopCount") or 0
		entry.sample = g_soundManager:loadSampleFromXML(xmlFile, "sound.surface", string.format("material(%d)", i), baseDirectory, getRootNode(), loopCount, audioGroup, nil, )

		if entry.sample ~= nil then
			table.insert(self.surfaceSounds, entry)
		end

		i = i + 1
	end

	self.cuttingSounds = {}
	local j = 0

	while true do
		local key = string.format("sound.cutting.sample(%d)", j)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local name = getXMLString(xmlFile, key .. "#name")
		local sample = g_soundManager:loadSampleFromXML(xmlFile, "sound.cutting", string.format("sample(%d)", j), baseDirectory, getRootNode(), 1, AudioGroup.ENVIRONMENT, nil, )

		if name ~= nil then
			self.cuttingSounds[name] = sample
		else
			print("Warning: a cutting sound does not have a name")
		end

		j = j + 1
	end

	delete(xmlFile)
end

function BaseMission:loadObjectAtPlace(xmlFilename, places, usedPlaces, rotationOffset, ownerFarmId)
	local size = StoreItemUtil.getSizeValues(xmlFilename, "object", rotationOffset)
	local isLimitReached = false
	local x, y, z, place, width, _ = PlacementUtil.getPlace(places, size, usedPlaces, true, false, true)

	if x == nil then
		return nil, true, isLimitReached
	end

	local object = nil
	local yRot = MathUtil.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)
	yRot = yRot + rotationOffset
	local xmlFile = loadXMLFile("tempObjectXML", xmlFilename)
	local className = Utils.getNoNil(getXMLString(xmlFile, "object.className"), "")
	local filename = getXMLString(xmlFile, "object.filename")
	local class = ClassUtil.getClassObject(className)

	if class ~= nil then
		if filename ~= nil then
			object = class.new(self:getIsServer(), self:getIsClient())

			object:setOwnerFarmId(ownerFarmId, true)

			filename = Utils.getFilename(filename, self.baseDirectory)

			if object:load(filename, x, y, z, 0, yRot, 0, xmlFilename) then
				object:register()
				object:setFillLevel(object.capacity, false)
			else
				object:delete()

				object = nil
			end
		else
			print("Warning: File '" .. tostring(filename) .. "' not found!")
		end
	else
		print("Warning: Class '" .. tostring(className) .. "' not found!")
	end

	delete(xmlFile)

	if object ~= nil then
		PlacementUtil.markPlaceUsed(usedPlaces, place, width)

		return object, false, isLimitReached
	end

	return nil, false, isLimitReached
end

function BaseMission:addOwnedItem(item)
	BaseMission.addItemToList(self.ownedItems, item)
end

function BaseMission:removeOwnedItem(item)
	BaseMission.removeItemFromList(self.ownedItems, item)
end

function BaseMission:getNumOwnedItems(storeItem, farmId)
	return BaseMission.getNumListItems(self.ownedItems, storeItem, farmId)
end

function BaseMission:addLeasedItem(item)
	BaseMission.addItemToList(self.leasedVehicles, item)
end

function BaseMission:removeLeasedItem(item)
	BaseMission.removeItemFromList(self.leasedVehicles, item)
end

function BaseMission:getNumLeasedItems(storeItem, farmId)
	return BaseMission.getNumListItems(self.leasedVehicles, storeItem, farmId)
end

function BaseMission.getNumListItems(list, storeItem, farmId)
	local numItems = 0

	if storeItem.bundleInfo == nil then
		if list[storeItem] ~= nil then
			if farmId == nil then
				numItems = list[storeItem].numItems
			else
				numItems = 0

				for _, item in pairs(list[storeItem].items) do
					if item:getOwnerFarmId() == farmId then
						numItems = numItems + 1
					end
				end
			end
		end
	else
		local maxNumOfItems = math.huge

		for _, bundleItem in pairs(storeItem.bundleInfo.bundleItems) do
			maxNumOfItems = math.min(maxNumOfItems, BaseMission.getNumListItems(list, bundleItem.item, farmId))
		end

		numItems = maxNumOfItems
	end

	return numItems
end

function BaseMission.addItemToList(list, item)
	if list == nil or item == nil then
		return
	end

	local storeItem = g_storeManager:getItemByXMLFilename(item.configFileName)

	if storeItem ~= nil then
		if list[storeItem] == nil then
			list[storeItem] = {
				numItems = 0,
				storeItem = storeItem,
				items = {}
			}
		end

		if list[storeItem].items[item] == nil then
			list[storeItem].numItems = list[storeItem].numItems + 1
			list[storeItem].items[item] = item
		end
	end
end

function BaseMission.removeItemFromList(list, item)
	if list == nil or item == nil then
		return
	end

	local storeItem = g_storeManager:getItemByXMLFilename(item.configFileName)

	if storeItem ~= nil and list[storeItem] ~= nil and list[storeItem].items[item] ~= nil then
		list[storeItem].numItems = list[storeItem].numItems - 1
		list[storeItem].items[item] = nil

		if list[storeItem].numItems == 0 then
			list[storeItem] = nil
		end
	end
end

function BaseMission:addVehicle(vehicle)
	table.addElement(self.vehicles, vehicle)

	vehicle.isAddedToMission = true

	if vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED then
		self:addOwnedItem(vehicle)
	elseif vehicle.propertyState == Vehicle.PROPERTY_STATE_LEASED then
		self:addLeasedItem(vehicle)
	end
end

function BaseMission:removeVehicle(vehicle, callDelete)
	if self:getIsClient() and vehicle == self.controlledVehicle then
		self:onLeaveVehicle()
	end

	if vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED then
		self:removeOwnedItem(vehicle)
	elseif vehicle.propertyState == Vehicle.PROPERTY_STATE_LEASED then
		self:removeLeasedItem(vehicle)
	end

	table.removeElement(self.vehicles, vehicle)
	vehicle:removeNodeObjectMapping(self.nodeToObject)
	table.removeElement(self.vehiclesToDelete, vehicle)

	vehicle.isAddedToMission = false

	if callDelete == nil or callDelete == true then
		if self:getIsServer() then
			table.addElement(self.vehiclesToDelete, vehicle)
		else
			g_client:getServerConnection():sendEvent(VehicleRemoveEvent.new(vehicle))
		end
	end
end

function BaseMission:addVehicleToDelete(vehicle)
	table.addElement(self.vehiclesToDelete, vehicle)
end

function BaseMission:addVehicleToSpawn(xmlFilename, xmlKey)
	table.insert(self.vehiclesToSpawn, {
		xmlFilename = xmlFilename,
		xmlKey = xmlKey
	})

	self.vehiclesToSpawnDirty = true
end

function BaseMission:addUpdateable(updateable, key)
	assert(updateable.isa == nil or not updateable:isa(Object), "No network objects allowed in addUpdateable")

	if updateable.update == nil then
		Logging.error("Given updateable has no update function")
		printCallstack()

		return
	end

	self.updateables[key or updateable] = updateable
end

function BaseMission:removeUpdateable(updateable)
	self.updateables[updateable] = nil
end

function BaseMission:getHasUpdateable(updateable)
	return self.updateables[updateable] ~= nil
end

function BaseMission:getHasDrawable(drawable)
	return self.drawables[drawable] ~= nil
end

function BaseMission:addDrawable(drawable, key)
	self.drawables[key or drawable] = drawable
end

function BaseMission:removeDrawable(drawable)
	self.drawables[drawable] = nil
end

function BaseMission:addNonUpdateable(nonUpdateable)
	assert(nonUpdateable.isa == nil or not nonUpdateable:isa(Object), "No network objects allowed in addNonUpdateable")

	self.nonUpdateables[nonUpdateable] = nonUpdateable
end

function BaseMission:removeNonUpdateable(nonUpdateable)
	self.nonUpdateables[nonUpdateable] = nil
end

function BaseMission:addOnCreateLoadedObject(object)
	if not self.isLoadingMap then
		print("Error: BaseMission:addOnCreateLoadedObject(): only allowed to add objects while loading maps")
		printCallstack()

		return
	end

	table.insert(self.onCreateLoadedObjects, object)

	return #self.onCreateLoadedObjects
end

function BaseMission:getOnCreateLoadedObject(index)
	return self.onCreateLoadedObjects[index]
end

function BaseMission:getNumOnCreateLoadedObjects()
	return #self.onCreateLoadedObjects
end

function BaseMission:addNodeObject(node, object)
	if self.nodeToObject[node] ~= nil then
		Logging.error("Node '%s' already has a node-object mapping '%s'", getName(node), tostring(object))
		printCallstack()

		return
	end

	self.nodeToObject[node] = object
end

function BaseMission:removeNodeObject(node)
	self.nodeToObject[node] = nil
end

function BaseMission:getNodeObject(node)
	return self.nodeToObject[node]
end

function BaseMission:addOnCreateLoadedObjectToSave(object)
	if not self.isLoadingMap then
		print("Error: Only allowed to add onCreate loaded objects to save while loading maps")

		return
	end

	if object.saveToXMLFile == nil then
		print("Error: Adding onCreate loaded object so save which does not have a saveToXMLFile function")

		return
	end

	if object.saveId == nil then
		print("Error: Adding onCreate loaded object with invalid saveId")

		return
	end

	local prevObject = self.onCreateLoadedObjectsToSave[object.saveId]

	if prevObject == object then
		return
	end

	if prevObject ~= nil then
		print("Error: Adding onCreate loaded object with duplicate saveId " .. tostring(object.saveId))

		return
	end

	self.onCreateLoadedObjectsToSave[object.saveId] = object
	self.numOnCreateLoadedObjectsToSave = self.numOnCreateLoadedObjectsToSave + 1
	object.saveOrderIndex = self.numOnCreateLoadedObjectsToSave
end

function BaseMission:removeOnCreateLoadedObjectToSave(object)
	if object.saveId ~= nil then
		local prevObject = self.onCreateLoadedObjectsToSave[object.saveId]

		if prevObject == object then
			self.onCreateLoadedObjectsToSave[object.saveId] = nil
		end
	end
end

function BaseMission:pauseGame()
	if not self.paused then
		self:doPauseGame()

		if self:getIsServer() then
			GamePauseEvent.sendEvent()
		end
	end
end

function BaseMission:tryUnpauseGame()
	if self:canUnpauseGame() then
		self:doUnpauseGame()

		if self:getIsServer() then
			GamePauseEvent.sendEvent()
		end

		return true
	end

	return false
end

function BaseMission:canUnpauseGame()
	return self.paused and not self.manualPaused and not self.suspendPaused and not self.pressStartPaused
end

function BaseMission:setManualPause(doPause)
	if (self:getIsServer() or self.isMasterUser) and doPause ~= self.manualPaused then
		self.manualPaused = doPause

		if self:getIsServer() then
			if doPause then
				self:pauseGame()
			else
				self:tryUnpauseGame()
			end
		else
			g_client:getServerConnection():sendEvent(GamePauseRequestEvent.new(doPause))
		end
	end
end

function BaseMission:doPauseGame()
	self.paused = true
	self.isRunning = false

	simulatePhysics(false)
	simulateParticleSystems(false)
	self:resetGameState()

	if self.hud ~= nil and not g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU) then
		self.hud:setInputHelpVisible(true)
	end

	for target, callbackFunc in pairs(self.pauseListeners) do
		callbackFunc(target, self.paused)
	end

	if self.trafficSystem ~= nil then
		self.trafficSystem:setEnabled(false)
	end

	if self.pedestrianSystem ~= nil then
		self.pedestrianSystem:setEnabled(false)
	end
end

function BaseMission:doUnpauseGame()
	self.paused = false
	self.isRunning = true

	simulatePhysics(true)
	simulateParticleSystems(true)

	if self.hud ~= nil and not g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU) then
		self.hud:setInputHelpVisible(g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU))
	end

	local lastNonPauseGameState = self.lastNonPauseGameState

	if lastNonPauseGameState == GameState.MENU_INGAME and g_gui.currentGuiName ~= "InGameMenu" then
		lastNonPauseGameState = GameState.PLAY
	end

	g_gameStateManager:setGameState(lastNonPauseGameState)

	for target, callbackFunc in pairs(self.pauseListeners) do
		callbackFunc(target, self.paused)
	end

	if self.trafficSystem ~= nil then
		self.trafficSystem:setEnabled(g_currentMission.missionInfo.trafficEnabled)
	end

	if self.pedestrianSystem ~= nil then
		self.pedestrianSystem:setEnabled(true)
	end
end

function BaseMission:addPauseListeners(target, callbackFunc)
	self.pauseListeners[target] = callbackFunc
end

function BaseMission:removePauseListeners(target)
	self.pauseListeners[target] = nil
end

function BaseMission:resetGameState()
	if self.pressStartPaused then
		g_gameStateManager:setGameState(GameState.LOADING)
	elseif self.paused then
		g_gameStateManager:setGameState(GameState.PAUSED)
	else
		g_gameStateManager:setGameState(GameState.PLAY)
	end
end

function BaseMission:toggleVehicle(delta)
	if not self.isToggleVehicleAllowed then
		return
	end

	local numVehicles = #self.enterables

	if numVehicles > 0 then
		local index = 1
		local oldIndex = 1

		if not self.controlPlayer and self.controlledVehicle ~= nil then
			for i = 1, numVehicles do
				if self.controlledVehicle == self.enterables[i] then
					oldIndex = i
					index = i + delta

					if numVehicles < index then
						index = 1
					end

					if index < 1 then
						index = numVehicles
					end

					break
				end
			end
		elseif delta < 0 then
			index = numVehicles
		end

		local found = false

		repeat
			local enterable = self.enterables[index]

			if enterable:getIsTabbable() and enterable:getIsEnterable() then
				found = true
			else
				index = index + delta

				if numVehicles < index then
					index = 1
				end

				if index < 1 then
					index = numVehicles
				end
			end
		until found or index == oldIndex

		if found then
			g_currentMission:requestToEnterVehicle(self.enterables[index])
		end
	end
end

function BaseMission:getIsClient()
	return g_client ~= nil
end

function BaseMission:getIsServer()
	return g_server ~= nil
end

function BaseMission:mouseEvent(posX, posY, isDown, isUp, button)
	if self.isRunning and not g_gui:getIsGuiVisible() then
		if g_server ~= nil then
			g_server:mouseEvent(posX, posY, isDown, isUp, button)
		end

		if g_client ~= nil then
			g_client:mouseEvent(posX, posY, isDown, isUp, button)
		end

		if self:getIsClient() and self.controlPlayer then
			self.player:mouseEvent(posX, posY, isDown, isUp, button)
		end
	end

	for _, v in pairs(g_modEventListeners) do
		if v.mouseEvent ~= nil then
			v:mouseEvent(posX, posY, isDown, isUp, button)
		end
	end
end

function BaseMission:keyEvent(unicode, sym, modifier, isDown)
	if self.isRunning and not g_gui:getIsGuiVisible() then
		if self:getIsServer() then
			g_server:keyEvent(unicode, sym, modifier, isDown)
		end

		if self:getIsClient() then
			g_client:keyEvent(unicode, sym, modifier, isDown)
		end
	end

	for _, v in pairs(g_modEventListeners) do
		if v.keyEvent ~= nil then
			v:keyEvent(unicode, sym, modifier, isDown)
		end
	end
end

function BaseMission:preUpdate(dt)
	if not self.waitForCorruptDlcs then
		if self.waitForDLCVerification and verifyDlcs() and g_gui:getIsGuiVisible() and g_gui.currentGuiName == "InfoDialog" then
			g_gui:showGui("")

			self.waitForDLCVerification = false
		end

		if storeAreDlcsCorrupted() then
			self.waitForCorruptDlcs = true
			local infoDialog = g_gui:showGui("InfoDialog")

			infoDialog.target:setText(g_i18n:getText("dialog_dlcsCorruptQuit"))
			infoDialog.target:setButtonText(g_i18n:getText("button_quit"))
			infoDialog.target:setCallbacks(self.dlcProblemOnQuitOk, self, true)
		elseif not self.waitForDLCVerification and storeHaveDlcsChanged() then
			g_forceNeedsDlcsAndModsReload = true

			if not verifyDlcs() then
				self.waitForDLCVerification = true
				local infoDialog = g_gui:showGui("InfoDialog")

				infoDialog.target:setText(g_i18n:getText("dialog_reinsertDlcMedia"))
				infoDialog.target:setButtonText(g_i18n:getText("button_quit"))
				infoDialog.target:setCallbacks(self.dlcProblemOnQuitOk, self, true)
			elseif checkForNewDlcs() then
				self.hud:showInGameMessage(g_i18n:getText("message_newDlcsRestartTitle"), g_i18n:getText("message_newDlcsRestartText"), -1)
			end
		end
	end
end

function BaseMission:dlcProblemOnQuitOk()
	OnInGameMenuMenu()
end

function BaseMission:update(dt)
	if self.waitForDLCVerification or self.waitForCorruptDlcs then
		return
	end

	if self:getIsServer() then
		g_server:update(dt, self.isRunning)
	end

	if self:getIsClient() then
		g_client:update(dt, self.isRunning)
	end

	while next(self.vehiclesToDelete) ~= nil do
		local i = #self.vehiclesToDelete
		local vehicle = self.vehiclesToDelete[i]

		table.remove(self.vehiclesToDelete, i)
		vehicle:delete()
	end

	for i = #self.vehiclesToAttach, 1, -1 do
		local info = self.vehiclesToAttach[i]
		local v1 = NetworkUtil.getObject(info.v1)
		local v2 = NetworkUtil.getObject(info.v2)

		if v1 ~= nil and v2 ~= nil then
			v1:attachImplement(v2, info.inputJointIndex, info.jointIndex, true, nil, , true)
			table.remove(self.vehiclesToAttach, i)
		end
	end

	if self.gameStarted and g_appIsSuspended ~= self.suspendPaused then
		self.suspendPaused = g_appIsSuspended

		if g_appIsSuspended then
			self:pauseGame()
		else
			self:tryUnpauseGame()
		end
	end

	self.activatableObjectsSystem:update(dt)
	self.achievementManager:update(dt)
	self.hud:update(dt)

	if not self.isRunning then
		return
	end

	if self.vehiclesToSpawnDirty then
		local function asyncCallbackFunction(_, vehicle, vehicleLoadState, arguments)
			local xmlFilename, key, xmlFile = unpack(arguments)

			if vehicleLoadState ~= VehicleLoadingUtil.VEHICLE_LOAD_OK then
				printf("Warning: corrupt vehicles xml '%s', vehicle '%s' could not be loaded", xmlFilename, key)
			end

			xmlFile:delete()
			table.remove(self.vehiclesToSpawn, 1)

			self.vehiclesToSpawnLoading = false
			self.vehiclesToSpawnDirty = true
		end

		if #self.vehiclesToSpawn > 0 and not self.vehiclesToSpawnLoading then
			local vehicleToSpawn = self.vehiclesToSpawn[1]
			local xmlFilename = vehicleToSpawn.xmlFilename
			local xmlFile = XMLFile.load("VehiclesXML", xmlFilename, Vehicle.xmlSchemaSavegame)
			local key = vehicleToSpawn.xmlKey
			self.vehiclesToSpawnLoading = true

			VehicleLoadingUtil.loadVehicleFromSavegameXML(xmlFile, key, true, false, nil, , asyncCallbackFunction, nil, {
				xmlFilename,
				key,
				xmlFile
			})
		end

		self.vehiclesToSpawnDirty = false
	end

	for k in pairs(self.usedStorePlaces) do
		self.usedStorePlaces[k] = nil
	end

	for k in pairs(self.usedLoadPlaces) do
		self.usedLoadPlaces[k] = nil
	end

	self.time = self.time + dt

	if self:getIsClient() then
		if not g_gui:getIsGuiVisible() then
			self.hud:updateBlinkingWarning(dt)

			if self.currentMapTargetHotspot ~= nil and not self.disableMapTargetHotspotHiding then
				local x, _, z = getWorldTranslation(getCamera())
				local hotspotX, hotspotZ = self.currentMapTargetHotspot:getWorldPosition()
				local distance = MathUtil.vector2Length(x - hotspotX, z - hotspotZ)

				if distance < 10 then
					self:setMapTargetHotspot(nil)
				end
			end
		end

		self.interactiveVehicleInRange = self:getInteractiveVehicleInRange()
	end

	if self.environment ~= nil then
		self.environment:update(dt)
	end

	for _, v in pairs(self.updateables) do
		v:update(dt)
	end

	for _, v in pairs(g_modEventListeners) do
		if v.update ~= nil then
			v:update(dt)
		end
	end

	g_sleepManager:update(dt)
	g_baleManager:update(dt)

	self.finishedFirstUpdate = true

	if g_touchHandler ~= nil then
		g_touchHandler:update(dt)
	end
end

function BaseMission:draw()
	local isNotFading = not self.hud:getIsFading()

	if self:getIsClient() and self.isRunning and not g_gui:getIsGuiVisible() and isNotFading then
		self.hud:drawControlledEntityHUD()

		for _, vehicle in pairs(self.enterables) do
			vehicle:drawUIInfo()
		end

		for _, player in pairs(self.players) do
			player:drawUIInfo()
		end

		g_soundManager:draw()
	end

	local isUIHidden = not g_gui:getIsGuiVisible()

	if isUIHidden and isNotFading then
		new2DLayer()

		if self.isRunning or self.paused then
			self.hud:drawInputHelp()
		end

		if self.isRunning then
			self.hud:drawTopNotification()
			self.hud:drawBlinkingWarning()

			if g_server ~= nil then
				g_server:draw()
			elseif g_client ~= nil then
				g_client:draw()
			end

			for _, v in pairs(g_modEventListeners) do
				if v.draw ~= nil then
					v:draw()
				end
			end

			for _, v in pairs(self.drawables) do
				v:draw()
			end

			self.hud:drawPresentationVersion()
		end
	end

	if self.paused and not self.isMissionStarted and not g_gui:getIsGuiVisible() then
		self.hud:drawGamePaused(true)
	end

	self.hud:drawFading()

	if g_touchHandler ~= nil then
		g_touchHandler:draw()
	end
end

function BaseMission:setPedestrianSystem(pedestrianSystem)
	if pedestrianSystem ~= nil and self.pedestrianSystem ~= nil then
		Logging.error("BaseMission: Pedestrian system already set")

		return false
	end

	self.pedestrianSystem = pedestrianSystem

	return true
end

function BaseMission:getPedestrianSystem()
	return self.pedestrianSystem
end

function BaseMission:requestToEnterVehicle(vehicle)
	local playerStyle = self.player:getStyle()

	if self.accessHandler:canPlayerAccess(vehicle) and playerStyle ~= nil then
		g_client:getServerConnection():sendEvent(VehicleEnterRequestEvent.new(vehicle, playerStyle, self:getFarmId()))
	end
end

function BaseMission:enterVehicleWithPlayer(vehicle, player)
	local enterableSpec = vehicle.spec_enterable

	if vehicle ~= nil and enterableSpec ~= nil and enterableSpec.isControlled == false then
		local connection = player.networkInformation.creatorConnection

		vehicle:setOwner(connection)

		vehicle.controllerFarmId = player.farmId

		g_server:broadcastEvent(VehicleEnterResponseEvent.new(NetworkUtil.getObjectId(vehicle), false, player:getStyle(), player.farmId))
		connection:sendEvent(VehicleEnterResponseEvent.new(NetworkUtil.getObjectId(vehicle), true, player:getStyle(), player.farmId))
	end
end

function BaseMission:onEnterVehicle(vehicle, playerStyle, farmId)
	if self.controlPlayer then
		self.player:onLeave()
	elseif self.controlledVehicle ~= nil then
		g_client:getServerConnection():sendEvent(VehicleLeaveEvent.new(self.controlledVehicle))
		self.controlledVehicle:leaveVehicle()
	end

	local oldContext = self.inputManager:getContextName()

	self.inputManager:setContext(Vehicle.INPUT_CONTEXT_NAME, true, false)
	self:registerActionEvents()
	self:registerPauseActionEvents()

	self.controlledVehicle = vehicle

	self.controlledVehicle:enterVehicle(true, playerStyle, farmId)

	if g_gui:getIsGuiVisible() and oldContext ~= Vehicle.INPUT_CONTEXT_NAME then
		self.inputManager:setContext(oldContext, false, false)
	end

	self.controlPlayer = false

	self.hud:setControlledVehicle(vehicle)
	self.hud:setIsControllingPlayer(false)
end

function BaseMission:onLeaveVehicle(playerTargetPosX, playerTargetPosY, playerTargetPosZ, isAbsolute, isRootNode)
	if not self.controlPlayer and self.controlledVehicle ~= nil then
		g_client:getServerConnection():sendEvent(VehicleLeaveEvent.new(self.controlledVehicle))

		if self.controlledVehicle.getIsEntered ~= nil and self.controlledVehicle:getIsEntered() then
			self.controlledVehicle:leaveVehicle()
		end

		self.inputManager:resetActiveActionBindings()

		local prevContext = self.inputManager:getContextName()
		local isVehicleContext = prevContext == BaseMission.INPUT_CONTEXT_VEHICLE
		local isInMenu = g_gui:getIsGuiVisible()

		if isInMenu then
			self.inputManager:beginActionEventsModification(Player.INPUT_CONTEXT_NAME, true)
		else
			self.inputManager:setContext(Player.INPUT_CONTEXT_NAME, true, isVehicleContext)
		end

		self:registerActionEvents()

		self.controlPlayer = true

		if playerTargetPosX ~= nil and playerTargetPosY ~= nil and playerTargetPosZ ~= nil then
			self.player:moveTo(playerTargetPosX, playerTargetPosY, playerTargetPosZ, isAbsolute, isRootNode)
		else
			self.player:moveToExitPoint(self.controlledVehicle)
		end

		self.player:onEnter(true)
		self.player:onLeaveVehicle()

		self.controlledVehicle = nil

		self.hud:setIsControllingPlayer(true)
		self.hud:setControlledVehicle(nil)

		if isInMenu then
			self.inputManager:endActionEventsModification(true)
			self.inputManager:setPreviousContext(Gui.INPUT_CONTEXT_MENU, Player.INPUT_CONTEXT_NAME)
		end

		self:registerPauseActionEvents()
	end
end

function BaseMission:getTrailerInTipRange(vehicle, minDistance)
	Logging.warning("BaseMission.getTrailerInTipRange() is deprecated")

	return false
end

function BaseMission:getIsTrailerInTipRange()
	Logging.warning("BaseMission.getIsTrailerInTipRange() is deprecated")

	return false
end

function BaseMission:addInteractiveVehicle(vehicle)
	self.interactiveVehicles[vehicle] = vehicle
end

function BaseMission:removeInteractiveVehicle(vehicle)
	self.interactiveVehicles[vehicle] = nil
end

function BaseMission:getInteractiveVehicleInRange()
	local nearestVehicle = nil

	if self.player ~= nil and not self.player.isCarryingObject then
		local nearestDistance = math.huge

		for _, vehicle in pairs(self.interactiveVehicles) do
			if not vehicle.isBroken and not vehicle.isControlled then
				local vehicleDistance = vehicle:getDistanceToNode(self.player.rootNode)

				if vehicleDistance < nearestDistance then
					nearestDistance = vehicleDistance
					nearestVehicle = vehicle
				end
			end
		end
	end

	return nearestVehicle
end

function BaseMission:addEnterableVehicle(vehicle)
	table.addElement(self.enterables, vehicle)
end

function BaseMission:isEnterableVehicle(vehicle)
	for _, enterable in ipairs(self.enterables) do
		if enterable == vehicle then
			return true
		end
	end

	return false
end

function BaseMission:removeEnterableVehicle(vehicle)
	table.removeElement(self.enterables, vehicle)
end

function BaseMission:addAttachableVehicle(vehicle)
	table.addElement(self.attachables, vehicle)
end

function BaseMission:removeAttachableVehicle(vehicle)
	table.removeElement(self.attachables, vehicle)
end

function BaseMission:onSunkVehicle(vehicle)
end

function BaseMission:registerInputAttacherJoint(vehicle, inputAttacherJointIndex, inputAttacherJoint)
	local inputAttacherJointInfo = {
		vehicle = vehicle,
		jointIndex = inputAttacherJointIndex,
		inputAttacherJoint = inputAttacherJoint,
		node = inputAttacherJoint.node,
		jointType = inputAttacherJoint.jointType,
		translation = {
			getWorldTranslation(inputAttacherJoint.node)
		}
	}

	table.addElement(self.inputAttacherJoints, inputAttacherJointInfo)

	return inputAttacherJointInfo
end

function BaseMission:updateInputAttacherJoint(inputAttacherJointInfo)
	local x, y, z = getWorldTranslation(inputAttacherJointInfo.node)
	inputAttacherJointInfo.translation[3] = z
	inputAttacherJointInfo.translation[2] = y
	inputAttacherJointInfo.translation[1] = x
end

function BaseMission:removeInputAttacherJoint(inputAttacherJointInfo)
	table.removeElement(self.inputAttacherJoints, inputAttacherJointInfo)
end

function BaseMission:setMissionInfo(missionInfo, missionDynamicInfo)
	self.missionInfo = missionInfo
	self.missionDynamicInfo = missionDynamicInfo

	self:setMoneyUnit(g_gameSettings:getValue(GameSettings.SETTING.MONEY_UNIT))
	self:setUseMiles(g_gameSettings:getValue(GameSettings.SETTING.USE_MILES))
	self:setUseFahrenheit(g_gameSettings:getValue(GameSettings.SETTING.USE_FAHRENHEIT))
	self:setUseAcre(g_gameSettings:getValue(GameSettings.SETTING.USE_ACRE))
	self.hud:setMissionInfo(missionInfo)
	self.inGameMenu:setMissionInfo(missionInfo, missionDynamicInfo, self.baseDirectory)
end

function BaseMission:onCreateTriggerMarker(id)
	g_currentMission:addTriggerMarker(id)
end

function BaseMission:addTriggerMarker(id)
	setVisibility(id, self.triggerMarkersAreVisible)
	table.addElement(self.triggerMarkers, id)
end

function BaseMission:removeTriggerMarker(id)
	table.removeElement(self.triggerMarkers, id)
end

function BaseMission:setShowTriggerMarker(areVisible)
	self.triggerMarkersAreVisible = areVisible

	for _, node in ipairs(self.triggerMarkers) do
		setVisibility(node, areVisible)
	end
end

function BaseMission:setShowFieldInfo(isVisible)
	self.hud:setInfoVisible(isVisible)
end

function BaseMission:addHelpButtonText(text, actionName1, actionName2, prio)
end

function BaseMission:addHelpAxis(actionName, overlay)
end

function BaseMission:addExtraPrintText(text)
	self.hud:addExtraPrintText(text)
end

function BaseMission:addGameNotification(title, text, info, icon, duration, notification, iconFilename)
	return self.hud:addTopNotification(title, text, info, icon, duration, notification, iconFilename)
end

function BaseMission:showBlinkingWarning(text, duration, priority)
	self.hud:showBlinkingWarning(text, duration, priority)
end

function BaseMission:setMoneyUnit(unit)
end

function BaseMission:setUseMiles(useMiles)
end

function BaseMission:setUseAcre(useAcrea)
end

function BaseMission:setUseFahrenheit(useFahrenheit)
end

function BaseMission:fadeScreen(direction, duration, callbackFunc, callbackTarget, arguments)
	self.hud:fadeScreen(direction, duration, callbackFunc, callbackTarget, arguments)
end

function BaseMission:setIsInsideBuilding(isInsideBuilding)
	self.isInsideBuilding = isInsideBuilding

	if g_soundManager ~= nil then
		g_soundManager:setIsInsideBuilding(isInsideBuilding)
	end
end

function BaseMission:getNumOfItems(storeItem, farmId)
	local numItems = 0

	if self.ownedItems[storeItem] ~= nil then
		if farmId == nil then
			numItems = numItems + self.ownedItems[storeItem].numItems
		elseif self.ownedItems[storeItem].numItems > 0 then
			for _, item in pairs(self.ownedItems[storeItem].items) do
				if item:getOwnerFarmId() == farmId then
					numItems = numItems + 1
				end
			end
		end
	end

	if self.leasedVehicles[storeItem] ~= nil then
		if farmId == nil then
			numItems = numItems + self.leasedVehicles[storeItem].numItems
		elseif self.leasedVehicles[storeItem].numItems > 0 then
			for _, item in pairs(self.leasedVehicles[storeItem].items) do
				if item:getOwnerFarmId() == farmId then
					numItems = numItems + 1
				end
			end
		end
	end

	return numItems
end

function BaseMission:spawnCollisionTestCallback(transformId)
	if self.nodeToObject[transformId] ~= nil then
		self.spawnCollisionsFound = true
	end
end

function BaseMission:setMapTargetHotspot(mapHotspot)
	if self.currentMapTargetHotspot ~= nil then
		self.currentMapTargetHotspot:setBlinking(false)
		self.currentMapTargetHotspot:setPersistent(false)
		g_currentMission.economyManager:updateGreatDemandsPDASpots()
	end

	if mapHotspot ~= nil then
		local x, z = mapHotspot:getWorldPosition()
		local h = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

		self:setMapTargetMarker(true, x, h, z)
		mapHotspot:setBlinking(true)
		mapHotspot:setPersistent(true)
	else
		self:setMapTargetMarker(false, 0, 0, 0)
	end

	self.currentMapTargetHotspot = mapHotspot
end

function BaseMission:setMapTargetMarker(isActive, posX, posY, posZ)
	if BaseMission.MAP_TARGET_MARKER ~= nil then
		if isActive then
			setTranslation(BaseMission.MAP_TARGET_MARKER, posX, posY, posZ)
		end

		setVisibility(BaseMission.MAP_TARGET_MARKER, isActive)
	end
end

function BaseMission:onCreateMapTargetMarker(node)
	if BaseMission.MAP_TARGET_MARKER == nil then
		BaseMission.MAP_TARGET_MARKER = node

		link(getRootNode(), node)
		setVisibility(node, false)
	end
end

function BaseMission:onCreateLoadSpawnPlace(node)
	local place = PlacementUtil.loadPlaceFromNode(node)

	table.insert(g_currentMission.loadSpawnPlaces, place)
end

function BaseMission:onCreateStoreSpawnPlace(node)
	local place = PlacementUtil.loadPlaceFromNode(node)

	table.insert(g_currentMission.storeSpawnPlaces, place)
end

function BaseMission:onCreateRestrictedZone(node)
	local restrictedZone = PlacementUtil.createRestrictedZone(node)

	table.insert(g_currentMission.restrictedZones, restrictedZone)
end

function BaseMission:getResetPlaces()
	if #self.loadSpawnPlaces > 0 then
		return self.loadSpawnPlaces
	end

	return self.storeSpawnPlaces
end

function BaseMission:consoleCommandRender360Screenshot(resolution, subDir)
	local screenShotFolder = g_screenshotsDirectory

	if subDir ~= nil then
		screenShotFolder = screenShotFolder .. subDir .. "/"
	else
		screenShotFolder = screenShotFolder .. "fsScreen_" .. getDate("%Y_%m_%d_%H_%M_%S") .. "/"
	end

	createFolder(screenShotFolder)

	local baseFilename = screenShotFolder .. "fsScreen360"
	resolution = tonumber(resolution) or 512
	local numMSAA = 1
	local clearColorR = 0
	local clearColorG = 0
	local clearColorB = 0
	local clearColorA = 0
	local bloomQuality = 5
	local useDOF = true
	local ssaoQuality = 15
	local cloudQuality = 4

	render360Screenshot(baseFilename, resolution, "hdr_raw", numMSAA, clearColorR, clearColorG, clearColorB, clearColorA, bloomQuality, useDOF, ssaoQuality, cloudQuality)
end

function BaseMission:consoleCommandSetFOV(fovY)
	fovY = tonumber(fovY)

	if fovY ~= nil then
		local cameraBase = self.player

		if self.controlledVehicle ~= nil then
			cameraBase = self.controlledVehicle:getActiveCamera()
		end

		if fovY < 0 then
			fovY = cameraBase.fovY or cameraBase.fovYBackup
			cameraBase.fovYBackup = nil
		else
			if cameraBase.fovY == nil and cameraBase.fovYBackup == nil then
				cameraBase.fovYBackup = getFovY(cameraBase.cameraNode)
			end

			fovY = math.rad(fovY)
		end

		setFovY(cameraBase.cameraNode, fovY)

		return "Set camera fov to " .. tostring(math.deg(fovY))
	else
		return "Command needs number argument. gsCameraFovSet fieldOfViewAngle (-1 to reset to default)"
	end
end

function BaseMission:consoleCommandVehicleRemoveAll()
	local numDeleted = 0

	for i = #self.vehicles, 1, -1 do
		local vehicle = self.vehicles[i]

		if vehicle.isa ~= nil and vehicle:isa(Vehicle) and vehicle.trainSystem == nil and vehicle.typeName ~= "pallet" then
			self:removeVehicle(vehicle)

			numDeleted = numDeleted + 1
		end
	end

	return string.format("Deleted %i vehicle(s)! Excluded train and pallets", numDeleted)
end

function BaseMission:consoleCommandItemRemoveAll()
	local numDeleted = self.itemSystem:deleteAll()

	for i = #self.vehicles, 1, -1 do
		local vehicle = self.vehicles[i]

		if vehicle.isa ~= nil and vehicle:isa(Vehicle) and vehicle.typeName == "pallet" then
			self:removeVehicle(vehicle)

			numDeleted = numDeleted + 1
		end
	end

	return string.format("Deleted %i item(s)!", numDeleted)
end

function BaseMission:setLastInteractionTime(timeDelta)
	self.lastInteractionTime = g_time
end

function BaseMission:subscribeSettingsChangeMessages()
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self.setMoneyUnit, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_MILES], self.setUseMiles, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_ACRE], self.setUseAcre, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_FAHRENHEIT], self.setUseFahrenheit, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_TRIGGER_MARKER], self.setShowTriggerMarker, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_FIELD_INFO], self.setShowFieldInfo, self)
end

function BaseMission:subscribeGuiOpenCloseMessages()
	self.messageCenter:subscribe(MessageType.GUI_BEFORE_OPEN, self.onBeforeMenuOpen, self)
	self.messageCenter:subscribe(MessageType.GUI_AFTER_CLOSE, self.onAfterMenuClose, self)
end

function BaseMission:onBeforeMenuOpen()
	self.hud:onMenuVisibilityChange(true, g_gui:getIsOverlayGuiVisible())
end

function BaseMission:onAfterMenuClose()
	self.hud:onMenuVisibilityChange(false, false)
end

function BaseMission:onGameStateChange(newGameState, oldGameState)
	if newGameState ~= GameState.PAUSED then
		self.lastNonPauseGameState = newGameState
	end
end

function BaseMission:registerActionEvents()
	local _, eventId = self.inputManager:registerActionEvent(InputAction.PAUSE, self, self.onPause, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.TOGGLE_HELP_TEXT, self, self.onToggleHelpText, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.SWITCH_VEHICLE, self, self.onSwitchVehicle, false, true, false, true, 1)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.SWITCH_VEHICLE_BACK, self, self.onSwitchVehicle, false, true, false, true, -1)

	self.inputManager:setActionEventTextVisibility(eventId, false)
	self.hud:registerInput()
end

function BaseMission:unregisterActionEvents()
	self.inputManager:removeActionEventsByTarget(self)
	self.inputManager:beginActionEventsModification(BaseMission.INPUT_CONTEXT_PAUSE)
	self.inputManager:removeActionEventsByTarget(self)
	self.inputManager:endActionEventsModification()
end

function BaseMission:registerPauseActionEvents()
	self.inputManager:beginActionEventsModification(BaseMission.INPUT_CONTEXT_PAUSE)

	local _, eventId = nil

	if GS_IS_CONSOLE_VERSION then
		_, eventId = self.inputManager:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onConsoleAcceptPause, false, true, false, true)

		self.inputManager:setActionEventTextVisibility(eventId, false)
	end

	_, eventId = self.inputManager:registerActionEvent(InputAction.PAUSE, self, self.onPause, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, true)
	self.inputManager:setActionEventText(eventId, g_i18n:getText("ui_unpause"))
	self.inputManager:endActionEventsModification()
end

function BaseMission:onPause()
	if self.gameStarted then
		self:setManualPause(not self.manualPaused)
	end
end

function BaseMission:onConsoleAcceptPause()
	if self.gameStarted and self.manualPaused and GS_IS_CONSOLE_VERSION then
		self:setManualPause(false)
	end
end

function BaseMission:onToggleHelpText()
	local isVisible = not g_gameSettings:getValue(GameSettings.SETTING.SHOW_HELP_MENU)

	g_gameSettings:setValue(GameSettings.SETTING.SHOW_HELP_MENU, isVisible)
end

function BaseMission:onSwitchVehicle(_, _, directionValue)
	if not self.isPlayerFrozen and self.isRunning then
		self:toggleVehicle(directionValue)
	end
end
