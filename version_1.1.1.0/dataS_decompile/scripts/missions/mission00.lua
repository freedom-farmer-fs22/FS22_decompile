Mission00 = {}
local Mission00_mt = Class(Mission00, FSBaseMission)

g_xmlManager:addCreateSchemaFunction(function ()
	Mission00.xmlSchema = XMLSchema.new("mission00")
end)
g_xmlManager:addInitSchemaFunction(function ()
	local schema = Mission00.xmlSchema

	schema:register(XMLValueType.INT, "map#width", "Width of the world", 2048)
	schema:register(XMLValueType.INT, "map#height", "Height of the world", 2048)
	schema:register(XMLValueType.STRING, "map#imageFilename", "2D map filename")
	schema:register(XMLValueType.VECTOR_3, "map#mapFieldColor", "2D map field color rgb")
	schema:register(XMLValueType.VECTOR_3, "map#mapGrassFieldColor", "2D map grass color rgb")
	schema:register(XMLValueType.FLOAT, "map.culling#xzOffset", "")
	schema:register(XMLValueType.FLOAT, "map.culling#minY", "")
	schema:register(XMLValueType.FLOAT, "map.culling#maxY", "")
	schema:register(XMLValueType.INT, "map.densityMap#revision", "")
	schema:register(XMLValueType.INT, "map.terrainTexture#revision", "")
	schema:register(XMLValueType.INT, "map.terrainLodTexture#revision", "")
	schema:register(XMLValueType.INT, "map.splitShapes#revision", "")
	schema:register(XMLValueType.INT, "map.tipCollision#revision", "")
	schema:register(XMLValueType.INT, "map.placementCollision#revision", "")
	schema:register(XMLValueType.INT, "map.navigationCollision#revision", "")
	schema:register(XMLValueType.FLOAT, "map.vertexBufferMemoryUsage", "")
	schema:register(XMLValueType.FLOAT, "map.indexBufferMemoryUsage", "")
	schema:register(XMLValueType.FLOAT, "map.textureMemoryUsage", "")
	schema:register(XMLValueType.STRING, "map.hotspots.placeableHotspot(?)#type", "Placeable hotspot type")
	schema:register(XMLValueType.VECTOR_2, "map.hotspots.placeableHotspot(?)#worldPosition", "Placeable world position")
	schema:register(XMLValueType.VECTOR_3, "map.hotspots.placeableHotspot(?)#teleportWorldPosition", "Placeable teleport world position")
	schema:register(XMLValueType.STRING, "map.hotspots.placeableHotspot(?)#text", "Placeable hotspot text")
end)

function Mission00.new(baseDirectory, customMt, missionCollaborators)
	local self = Mission00:superClass().new(baseDirectory, customMt or Mission00_mt, missionCollaborators)
	self.objectsToCallOnMissionStarted = {}

	if g_dedicatedServer ~= nil then
		self:setAutoSaveInterval(g_dedicatedServer.autoSaveInterval, true)
	end

	self.isSaving = false
	g_mission00StartPoint = nil
	self.gameStarted = false
	self.loadFinishedListeners = {}
	self.mapHotspots = {}

	return self
end

function Mission00:delete()
	if self.xmlFile ~= nil then
		delete(self.xmlFile)

		self.xmlFile = nil
	end

	g_autoSaveManager:unloadMapData()

	for _, hotspot in ipairs(self.mapHotspots) do
		self:removeMapHotspot(hotspot)
		hotspot:delete()
	end

	Mission00:superClass().delete(self)
end

function Mission00:setMissionInfo(missionInfo, missionDynamicInfo)
	local mapXMLFilename = Utils.getFilename(missionInfo.mapXMLFilename, self.baseDirectory)
	local xmlFile = XMLFile.load("MapXML", mapXMLFilename, Mission00.xmlSchema)
	self.xmlFile = xmlFile:getHandle()
	self.mapWidth = xmlFile:getValue("map#width", 2048)
	self.mapHeight = xmlFile:getValue("map#height", 2048)
	self.mapImageFilename = Utils.getFilename(xmlFile:getValue("map#imageFilename"), self.baseDirectory)
	self.mapFieldColor = xmlFile:getValue("map#mapFieldColor", nil, true)
	self.mapGrassFieldColor = xmlFile:getValue("map#mapGrassFieldColor", nil, true)
	self.cullingWorldXZOffset = xmlFile:getValue("map.culling#xzOffset", self.cullingWorldXZOffset)
	self.cullingWorldMinY = xmlFile:getValue("map.culling#minY", self.cullingWorldMinY)
	self.cullingWorldMaxY = xmlFile:getValue("map.culling#maxY", self.cullingWorldMaxY)
	self.mapDensityMapRevision = xmlFile:getValue("map.densityMap#revision", 1)
	self.mapTerrainTextureRevision = xmlFile:getValue("map.terrainTexture#revision", 1)
	self.mapTerrainLodTextureRevision = xmlFile:getValue("map.terrainLodTexture#revision", 1)
	self.mapSplitShapesRevision = xmlFile:getValue("map.splitShapes#revision", 1)
	self.mapTipCollisionRevision = xmlFile:getValue("map.tipCollision#revision", 1)
	self.mapPlacementCollisionRevision = xmlFile:getValue("map.placementCollision#revision", 1)
	self.mapNavigationCollisionRevision = xmlFile:getValue("map.navigationCollision#revision", 1)
	self.vertexBufferMemoryUsage = xmlFile:getValue("map.vertexBufferMemoryUsage", self.vertexBufferMemoryUsage)
	self.indexBufferMemoryUsage = xmlFile:getValue("map.indexBufferMemoryUsage", self.indexBufferMemoryUsage)
	self.textureMemoryUsage = xmlFile:getValue("map.textureMemoryUsage", self.textureMemoryUsage)

	g_asyncTaskManager:addTask(function ()
		self.slotSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		self.fieldGroundSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		self.aiMessageManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
		self.aiJobTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_storeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
		g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.STORE)
	end)
	g_asyncTaskManager:addTask(function ()
		g_gameplayHintManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_groundTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_connectionHoseManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_fillTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_fruitTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_sprayTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_baleManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_weatherTypeManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		self.weedSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		self.stoneSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_depthOfFieldManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		self.aiSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		self.animalSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		self.animalFoodSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		self.animalNameSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_densityMapHeightManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_npcManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_helperManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		if not self.wildlifeSpawner:loadMapData(self.xmlFile, missionInfo, self.baseDirectory) then
			self.wildlifeSpawner:delete()

			self.wildlifeSpawner = nil
		end
	end)
	g_asyncTaskManager:addTask(function ()
		g_treePlantManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_materialManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory, function ()
			self:onMaterialsLoaded(missionInfo, missionDynamicInfo)
		end)
	end)
	g_asyncTaskManager:addTask(function ()
		Mission00:superClass().setMissionInfo(self, missionInfo, missionDynamicInfo)
	end)
end

function Mission00:onMaterialsLoaded(missionInfo, missionDynamicInfo)
	if self.cancelLoading then
		return
	end

	g_asyncTaskManager:addTask(function ()
		g_licensePlateManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_particleSystemManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_motionPathEffectManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_effectManager:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		self.foliageSystem:loadMapData(self.xmlFile, missionInfo, self.baseDirectory)
		g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.DATA)
	end)
end

function Mission00:load()
	self:startLoadingTask()
	self:loadEnvironment(self.xmlFile)

	local mapFilename = getXMLString(self.xmlFile, "map.filename")
	mapFilename = Utils.getFilename(mapFilename, self.baseDirectory)

	self:loadMap(mapFilename, true, self.loadMission00Finished, self)

	local soundFilename = Utils.getNoNil(getXMLString(self.xmlFile, "map.sounds#filename"), "$data/maps/map01_sound.xml")
	soundFilename = Utils.getFilename(soundFilename, self.baseDirectory)
	self.missionInfo.mapSoundXmlFilename = soundFilename

	self:loadMapSounds(soundFilename, self.baseDirectory)
	self.ambientSoundSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)

	self.mapPerformanceTestUtil = MapPerformanceTestUtil.new()

	self.hud:setGameInfoPartVisibility(HUD.GAME_INFO_PART.MONEY + HUD.GAME_INFO_PART.TIME + HUD.GAME_INFO_PART.WEATHER)
	self.collectiblesSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
	self.growthSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
	self.snowSystem:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
end

function Mission00:loadMission00Finished(node, arguments)
	if self.cancelLoading then
		return
	end

	g_asyncTaskManager:addTask(function ()
		local function callback()
			self.numAdditionalFiles = self.numAdditionalFiles - 1

			if self.numAdditionalFiles == 0 then
				self:loadAdditionalFilesFinished()
			end
		end

		local numAdditionalFiles = self:loadAdditionalFiles(self.xmlFile, callback, nil)

		if numAdditionalFiles > 0 then
			self.numAdditionalFiles = numAdditionalFiles
		else
			self:loadAdditionalFilesFinished()
		end
	end)
end

function Mission00:loadAdditionalFilesFinished()
	if self.cancelLoading then
		return
	end

	g_asyncTaskManager:addTask(function ()
		g_materialManager:loadModMaterialHolders()
		g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.ADDITIONAL_FILES)
	end)
	g_asyncTaskManager:addTask(function ()
		self.hud:loadIngameMap(self.mapImageFilename, self.mapWidth, self.mapHeight, self.mapFieldColor, self.mapGrassFieldColor)
		self:loadHotspots(self.xmlFile, g_currentModDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		self.showWeatherForecast = true
	end)
	g_asyncTaskManager:addTask(function ()
		self.guidedTour:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		g_farmlandManager:loadMapData(self.xmlFile)
	end)
	g_asyncTaskManager:addTask(function ()
		g_fieldManager:loadMapData(self.xmlFile)
	end)
	g_asyncTaskManager:addTask(function ()
		g_farmManager:loadMapData(self.xmlFile)

		if self.missionDynamicInfo.isMultiplayer then
			self:loadCompetitiveMultiplayer(self.xmlFile)
		end
	end)
	g_asyncTaskManager:addTask(function ()
		self:loadVehicles(self.missionInfo.vehiclesXMLLoad, self.missionInfo.resetVehicles)
	end)
	g_asyncTaskManager:addTask(function ()
		g_missionManager:loadMapData(self.xmlFile)
	end)
	g_asyncTaskManager:addTask(function ()
		g_helpLineManager:loadMapData(self.xmlFile, self.missionInfo)
	end)
	g_asyncTaskManager:addTask(function ()
		g_gui:loadMapData(self.xmlFile, self.missionInfo, self.baseDirectory)
	end)
	g_asyncTaskManager:addTask(function ()
		if self:getIsServer() and self.missionInfo.savegameDirectory ~= nil and fileExists(self.missionInfo.savegameDirectory .. "/collectibles.xml") then
			self.collectiblesSystem:loadFromXMLFile(self.missionInfo.savegameDirectory .. "/collectibles.xml")
		end
	end)
	g_asyncTaskManager:addTask(function ()
		if g_mission00StartPoint ~= nil then
			local x, y, z = getTranslation(g_mission00StartPoint)
			local dirX, _, dirZ = localDirectionToWorld(g_mission00StartPoint, 0, 0, -1)
			self.playerStartX = x
			self.playerStartY = y
			self.playerStartZ = z
			self.playerRotX = 0
			self.playerRotY = MathUtil.getYRotationFromDirection(dirX, dirZ)
			self.playerStartIsAbsolute = true
		end
	end)
	g_asyncTaskManager:addTask(function ()
		g_autoSaveManager:loadFinished()
	end)
	g_asyncTaskManager:addTask(function ()
		if not self.missionDynamicInfo.isMultiplayer then
			self:updateFoundHelpIcons()
		else
			self:removeAllHelpIcons()
		end
	end)
	g_asyncTaskManager:addTask(function ()
		if g_isPresentationVersion then
			self:playerOwnsAllFields()
		end
	end)
	g_asyncTaskManager:addTask(function ()
		if self.xmlFile ~= nil then
			delete(self.xmlFile)

			self.xmlFile = nil
		end
	end)
	g_asyncTaskManager:addTask(function ()
		Mission00:superClass().load(self)

		if self.missionInfo.economyXMLLoad ~= nil then
			self:loadEconomy(self.missionInfo.economyXMLLoad)
		end
	end)

	if self:getIsServer() then
		g_asyncTaskManager:addTask(function ()
			g_farmManager:loadFromXMLFile(self.missionInfo.farmsXMLLoad)
		end)
		g_asyncTaskManager:addTask(function ()
			g_farmlandManager:loadFromXMLFile(self.missionInfo.farmlandXMLLoad)
		end)
		g_asyncTaskManager:addTask(function ()
			g_npcManager:loadFromXMLFile(self.missionInfo.npcXMLLoad)
		end)
		g_asyncTaskManager:addTask(function ()
			self.vehicleSaleSystem:loadFromXMLFile(self.missionInfo.vehicleSaleXML)
		end)
		g_asyncTaskManager:addTask(function ()
			if self.missionInfo.playersXMLLoad ~= nil then
				self.playerInfoStorage:loadFromXMLFile(self.missionInfo.playersXMLLoad)
			end
		end)
		g_asyncTaskManager:addTask(function ()
			if self.missionInfo.fieldsXMLLoad ~= nil then
				g_fieldManager:loadFromXMLFile(self.missionInfo.fieldsXMLLoad)
			end
		end)
		g_asyncTaskManager:addTask(function ()
			self.growthSystem:loadFromXMLFile(self.missionInfo.environmentXMLLoad)

			if self.missionInfo.environmentXMLLoad ~= nil then
				self.snowSystem:loadFromXMLFile(self.missionInfo.environmentXMLLoad)
			end
		end)
		g_asyncTaskManager:addTask(function ()
			if self.missionInfo.aiSystemXMLLoad ~= nil then
				self.aiSystem:loadFromXMLFile(self.missionInfo.aiSystemXMLLoad)
			end
		end)
	end

	g_asyncTaskManager:addTask(function ()
		g_treePlantManager:loadFromXMLFile(self.missionInfo.treePlantXMLLoad)
	end)
	g_asyncTaskManager:addTask(function ()
		self:finishLoadingTask()
	end)
end

function Mission00:loadEnvironment(xmlFile)
	local filename = Utils.getFilename(getXMLString(xmlFile, "map.environment#filename"), self.baseDirectory)
	self.environment = Environment.new(self)

	self.environment:load(filename)

	if self.missionInfo.environmentXMLLoad ~= nil and self:getIsServer() then
		local envXmlFile = loadXMLFile("environmentXML", self.missionInfo.environmentXMLLoad)

		self.environment:loadFromXMLFile(envXmlFile, "environment")
		delete(envXmlFile)
	end

	self.hud:setEnvironment(self.environment)
	self.inGameMenu:setEnvironment(self.environment)
end

function Mission00:loadAdditionalFiles(xmlFile, callbackFunc, callbackTarget)
	local i = 0
	local numFiles = 0

	while true do
		local key = string.format("map.additionalFiles.additionalFile(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			return numFiles
		end

		local filename = getXMLString(xmlFile, key .. "#filename")

		if filename ~= nil then
			if filename:contains(".i3d") then
				g_asyncTaskManager:addSubtask(function ()
					filename = Utils.getFilename(filename, self.baseDirectory)

					g_i3DManager:loadI3DFileAsync(filename, true, true, self.onLoadedMapI3DFiles, self, {
						callbackFunc,
						callbackTarget
					})
				end)

				numFiles = numFiles + 1
			elseif filename:contains(".xml") then
				filename = Utils.getFilename(filename, self.baseDirectory)
				local externalXMLFile = XMLFile.load("additionalFilesXML", filename)

				if externalXMLFile ~= nil then
					externalXMLFile:iterate("additionalFiles.additionalFile", function (_, additionalFileKey)
						local externalFilename = externalXMLFile:getString(additionalFileKey .. "#filename")

						if externalFilename ~= nil then
							externalFilename = Utils.getFilename(externalFilename, self.baseDirectory)

							g_i3DManager:loadI3DFileAsync(externalFilename, true, true, self.onLoadedMapI3DFiles, self, {
								callbackFunc,
								callbackTarget
							})

							numFiles = numFiles + 1
						end
					end)
					externalXMLFile:delete()
				end
			end
		end

		i = i + 1
	end
end

function Mission00:onLoadedMapI3DFiles(node, failedReason, args)
	if node ~= 0 then
		unlink(node)
		table.insert(self.dynamicallyLoadedObjects, node)
	end

	local callbackFunc = args[1]
	local callbackTarget = args[2]

	callbackFunc(callbackTarget)
end

function Mission00:loadHotspots(xmlFile, customEnvironment)
	xmlFile = XMLFile.wrap(xmlFile, Mission00.xmlSchema)
	local i = 0

	while true do
		local key = string.format("map.hotspots.placeableHotspot(%d)", i)

		if not xmlFile:hasProperty(key) then
			break
		end

		local hotspot = PlaceableHotspot.new()
		local text = xmlFile:getValue(key .. "#text", nil)

		if text == nil then
			Logging.xmlWarning(xmlFile, "Missing placeable hotspot name for '%s'", key)

			break
		end

		hotspot:setName(g_i18n:convertText(text, customEnvironment))
		hotspot:createIcon()

		local hotspotTypeName = xmlFile:getValue(key .. "#type", "UNLOADING")
		local hotspotType = PlaceableHotspot.getTypeByName(hotspotTypeName)

		if hotspotType == nil then
			Logging.xmlWarning(xmlFile, "Unknown placeable hotspot type '%s'. Falling back to type 'UNLOADING'\nAvailable types: %s", hotspotTypeName, table.concatKeys(PlaceableHotspot.TYPE, " "))

			hotspotType = PlaceableHotspot.TYPE.UNLOADING
		end

		hotspot:setPlaceableType(hotspotType)

		local worldPositionX, worldPositionZ = xmlFile:getValue(key .. "#worldPosition", nil)

		if worldPositionX ~= nil then
			hotspot:setWorldPosition(worldPositionX, worldPositionZ)
		end

		local teleportX, teleportY, teleportZ = xmlFile:getValue(key .. "#teleportWorldPosition", nil)

		if teleportX ~= nil then
			teleportY = math.max(teleportY, getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, teleportX, 0, teleportZ))

			hotspot:setTeleportWorldPosition(teleportX, teleportY, teleportZ)
		end

		self:addMapHotspot(hotspot)
		table.insert(self.mapHotspots, hotspot)

		i = i + 1
	end

	xmlFile:delete()
end

function Mission00:registerObjectToCallOnMissionStart(object)
	table.addElement(self.objectsToCallOnMissionStarted, object)
end

function Mission00:unregisterObjectToCallOnMissionStart(object)
	table.removeElement(self.objectsToCallOnMissionStarted, object)
end

function Mission00:onStartMission()
	Mission00:superClass().onStartMission(self)
	g_gameStateManager:setGameState(GameState.PLAY)
	self.achievementManager:loadMapData()
	g_currentMission.economyManager:restartGreatDemands()

	for _, object in pairs(self.objectsToCallOnMissionStarted) do
		object:onMissionStarted()
	end

	self.objectsToCallOnMissionStarted = {}
	self.gameStarted = true
end

function Mission00:getIsTourSupported()
	return self.missionInfo.difficulty == 1 or GS_IS_MOBILE_VERSION
end

function Mission00:update(dt)
	Mission00:superClass().update(self, dt)

	if self:getIsServer() then
		g_autoSaveManager:update(dt)

		self.isSaving = self.savegameController:getIsSaving()

		if (GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION) and not self.isSaving then
			self:tryUnpauseGame()
		end
	end
end

function Mission00:doPauseGame()
	Mission00:superClass().doPauseGame(self)
	self:showPauseDisplay(true)
end

function Mission00:doUnpauseGame()
	Mission00:superClass().doUnpauseGame(self)
	self:showPauseDisplay(false)
end

function Mission00:canUnpauseGame()
	return Mission00:superClass().canUnpauseGame(self) and not self.isSaving
end

function Mission00:draw()
	Mission00:superClass().draw(self)

	if self.missionDynamicInfo.isMultiplayer and self.gameStarted then
		self.hud:drawCommunicationDisplay()
	end
end

function Mission00:loadVehicles(xmlFilename, resetVehicles)
	if xmlFilename ~= nil then
		if self:getIsServer() then
			self:startLoadingTask()
			VehicleLoadingUtil.loadVehiclesFromSavegame(xmlFilename, resetVehicles, self.missionInfo, self.missionDynamicInfo, self.loadVehiclesFinish, self, {
				xmlFilename,
				resetVehicles
			})
		end
	else
		self:loadVehiclesFinished()
	end
end

function Mission00:loadVehiclesFinish(arguments, vehiclesById)
	self.savegameIdToVehicle = vehiclesById

	if self.cancelLoading then
		self:finishLoadingTask()

		return
	end

	g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.VEHICLES)
	self:loadVehiclesFinished()
end

function Mission00:loadVehiclesFinished()
	g_asyncTaskManager:addSubtask(function ()
		g_messageCenter:publish(MessageType.LOADED_ALL_SAVEGAME_VEHICLES)
		self:loadPlaceables(self.missionInfo.placeablesXMLLoad)
	end)
end

function Mission00:loadPlaceables(xmlFilename)
	if xmlFilename ~= nil then
		self.placeableSystem:load(xmlFilename, self.missionInfo, self.missionDynamicInfo, self.loadPlaceablesFinished, self, nil)
	else
		self:loadPlaceablesFinished()
	end
end

function Mission00:loadPlaceablesFinished()
	g_asyncTaskManager:addSubtask(function ()
		g_messageCenter:publish(MessageType.LOADED_ALL_SAVEGAME_PLACEABLES)
		self:loadItems(self.missionInfo.itemsXMLLoad)
	end)
end

function Mission00:loadItems(xmlFilename, resetItems)
	if xmlFilename ~= nil then
		self.itemSystem:loadItems(xmlFilename, resetItems, self.missionInfo, self.missionDynamicInfo, self.loadItemsFinished, self, nil)
	else
		self:loadItemsFinished()
	end
end

function Mission00:loadItemsFinished()
	g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.ITEMS)

	if self:getIsServer() then
		g_asyncTaskManager:addTask(function ()
			g_missionManager:loadFromXMLFile(self.missionInfo.missionsXMLLoad)
		end)
		g_asyncTaskManager:addTask(function ()
			g_farmManager:mergeObjectsForSingleplayer()
		end)
		g_asyncTaskManager:addSubtask(function ()
			if self.missionInfo.onCreateObjectsXMLLoad ~= nil then
				self:loadOnCreateLoadedObjects(self.missionInfo.onCreateObjectsXMLLoad)
			end
		end)
		g_asyncTaskManager:addSubtask(function ()
			for _, listener in ipairs(self.loadFinishedListeners) do
				g_asyncTaskManager:addSubtask(function ()
					listener:onLoadFinished()
				end)
			end
		end)
		g_asyncTaskManager:addSubtask(function ()
			self:finishLoadingTask()
		end)
	end
end

function Mission00:loadOnCreateLoadedObjects(xmlFilename)
	if self:getIsServer() then
		local xmlFile = loadXMLFile("onCreateLoadedObjectsXML", xmlFilename)
		local i = 0

		while true do
			local key = string.format("onCreateLoadedObjects.onCreateLoadedObject(%d)", i)
			local saveId = getXMLString(xmlFile, key .. "#saveId")

			if saveId ~= nil then
				local object = self.onCreateLoadedObjectsToSave[saveId]

				if object ~= nil then
					if object.loadFromXMLFile == nil or not object:loadFromXMLFile(xmlFile, key) then
						print("Warning: corrupt savegame, onCreateLoadedObject " .. i .. " with saveId " .. saveId .. " could not be loaded")
					end
				else
					print("Error: Corrupt savegame, onCreateLoadedObject " .. i .. " has invalid saveId '" .. saveId .. "'")
				end
			else
				local id = getXMLInt(xmlFile, key .. "#id")

				if id == nil then
					break
				end

				local object = nil

				for _, objectI in pairs(self.onCreateLoadedObjectsToSave) do
					if objectI.saveOrderIndex == id then
						object = objectI

						break
					end
				end

				if object ~= nil then
					if object.loadFromXMLFile == nil or not object:loadFromXMLFile(xmlFile, key) then
						print("Warning: corrupt savegame, onCreateLoadedObject " .. i .. " with id " .. id .. " could not be loaded")
					end
				else
					print("Error: Corrupt savegame, onCreateLoadedObject " .. i .. " has invalid id '" .. id .. "'")
				end
			end

			i = i + 1
		end

		delete(xmlFile)
	end
end

function Mission00:saveOnCreateObjects(xmlFile, key, usedModNames)
	local index = 0

	for id, object in pairs(self.onCreateLoadedObjectsToSave) do
		local objectKey = string.format("%s.onCreateLoadedObject(%d)", key, index)

		setXMLString(xmlFile, objectKey .. "#saveId", id)
		object:saveToXMLFile(xmlFile, objectKey, usedModNames)

		index = index + 1
	end
end

function Mission00:onCreateStartPoint(id)
	g_mission00StartPoint = id
end

function Mission00:addChatMessage(sender, msg, farmId, userId)
	local isAllowed = true

	if userId ~= nil then
		local user = self.userManager:getUserByUserId(userId, false)

		if user ~= nil then
			sender = user:getNickname()
			isAllowed = user:getAllowTextCommunication()
		end
	end

	if isAllowed then
		self.hud:addChatMessage(msg, sender, farmId)
	end
end

function Mission00:scrollChatMessages(delta)
	self.hud:scrollChatMessages(delta)
end

function Mission00:loadEconomy(xmlFilename)
	if self:getIsServer() then
		local xmlFile = loadXMLFile("economyXML", xmlFilename)

		g_currentMission.economyManager:loadFromXMLFile(xmlFile, "economy")
		delete(xmlFile)
	end
end

function Mission00:addLoadFinishedListener(listener)
	table.addElement(self.loadFinishedListeners, listener)
end

function Mission00:removeLoadFinishedListener(listener)
	table.removeElement(self.loadFinishedListeners, listener)
end

function Mission00:loadCompetitiveMultiplayer(xmlFile)
	local filename = getXMLString(xmlFile, "map.competitiveMultiplayer#filename")

	if filename == nil or not self:getIsServer() then
		return
	end

	filename = Utils.getFilename(filename, self.baseDirectory)

	if not self.missionInfo.isValid then
		local farmXmlFile = loadXMLFile("CompetitiveXML", filename)
		local i = 0

		while true do
			local farmKey = string.format("competitiveMultiplayer.farms.farm(%d)", i)

			if not hasXMLProperty(farmXmlFile, farmKey) then
				break
			end

			local farmId = getXMLInt(farmXmlFile, farmKey .. "#farmId")
			local name = getXMLString(farmXmlFile, farmKey .. "#name")
			local color = getXMLInt(farmXmlFile, farmKey .. "#color")
			local farm = g_farmManager:createFarm(name, color, nil, farmId)

			if farm ~= nil then
				local money = getXMLFloat(farmXmlFile, farmKey .. "#money")

				if money ~= nil then
					farm.money = money
				end

				local loan = getXMLFloat(farmXmlFile, farmKey .. "#loan")

				if loan ~= nil then
					farm.loan = loan
				end
			end

			i = i + 1
		end

		delete(farmXmlFile)
	end

	self.missionInfo.isCompetitiveMultiplayer = true
end
