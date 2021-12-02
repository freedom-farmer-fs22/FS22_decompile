FSBaseMission = {
	USER_STATE_LOADING = 1,
	USER_STATE_SYNCHRONIZING = 2,
	USER_STATE_CONNECTED = 3,
	USER_STATE_INGAME = 4,
	CONNECTION_LOST_DEFAULT = 0,
	CONNECTION_LOST_KICKED = 1,
	CONNECTION_LOST_BANNED = 2,
	LIMITED_OBJECT_TYPE_BALE = 1,
	INGAME_NOTIFICATION_OK = {
		0.0976,
		0.624,
		0,
		1
	},
	INGAME_NOTIFICATION_INFO = {
		1,
		1,
		1,
		1
	},
	INGAME_NOTIFICATION_GREATDEMAND = {
		1,
		1,
		1,
		1
	},
	INGAME_NOTIFICATION_CRITICAL = {
		0.9301,
		0.2874,
		0.013,
		1
	},
	RECORDING_DEVICE_CHECK_INTERVAL = 2500
}
local l_engineState = true
local l_engineStateTimer = math.random(900000, 1200000)

if getEngineState ~= nil then
	l_engineState = getEngineState()
	getEngineState = nil
end

local function onEngineStateCallback()
	openWebFile("fs2019Purchase.php?type=2", "")
end

source("dataS/scripts/events/SavegameSettingsEvent.lua")
source("dataS/scripts/events/BaseMissionFinishedLoadingEvent.lua")
source("dataS/scripts/events/BaseMissionReadyEvent.lua")
source("dataS/scripts/events/SetSplitShapesEvent.lua")
source("dataS/scripts/events/UpdateSplitShapesEvent.lua")
source("dataS/scripts/events/ConnectionRequestEvent.lua")
source("dataS/scripts/events/ConnectionRequestAnswerEvent.lua")
source("dataS/scripts/events/ChangeLoanEvent.lua")
source("dataS/scripts/events/GamePauseEvent.lua")
source("dataS/scripts/events/GamePauseRequestEvent.lua")
source("dataS/scripts/events/PlayerPermissionsEvent.lua")
source("dataS/scripts/events/FinanceStatsEvent.lua")

local FSBaseMission_mt = Class(FSBaseMission, BaseMission)

function FSBaseMission.new(baseDirectory, customMt, missionCollaborators)
	local self = FSBaseMission:superClass().new(baseDirectory, customMt or FSBaseMission_mt, missionCollaborators)
	self.shopController = missionCollaborators.shopController
	self.inGameMenu = missionCollaborators.inGameMenu
	self.shopMenu = missionCollaborators.shopMenu

	self.inGameMenu:setClient(g_client)
	self.inGameMenu:setServer(g_server)
	self.shopMenu:setClient(g_client)
	self.shopMenu:setServer(g_server)

	self.trainSystems = {}
	self.objectsToCallOnMapFinished = {}

	self:registerToLoadOnMapFinished(self.inGameMenu)
	self:registerToLoadOnMapFinished(self.shopMenu)

	self.mapDensityMapRevision = 1
	self.mapTerrainTextureRevision = 1
	self.mapTerrainLodTextureRevision = 1
	self.mapSplitShapesRevision = 1
	self.mapTipCollisionRevision = 1
	self.mapPlacementCollisionRevision = 1
	self.mapNavigationCollisionRevision = 1
	self.densityMapSyncer = nil
	self.fieldGroundSystem = FieldGroundSystem.new()
	self.stoneSystem = StoneSystem.new()
	self.weedSystem = WeedSystem.new()
	self.sendMoneyUserIndex = 1
	self.playerStartIsAbsolute = false
	self.playersToAccept = {}
	self.playersLoading = {}
	self.doSaveGameState = SavegameController.SAVE_STATE_NONE
	self.currentDeviceHasNoSpace = false
	self.dediEmptyPaused = false
	self.userSigninPaused = false
	self.isSynchronizingWithPlayers = false
	self.playersSynchronizing = {}
	self.userManager = UserManager.new(self:getIsServer())
	self.playerInfoStorage = PlayerInfoStorage.new(self:getIsServer(), self.userManager)
	self.aiSystem = AISystem.new(self:getIsServer(), self)
	self.aiJobTypeManager = AIJobTypeManager.new(self:getIsServer())
	self.aiMessageManager = AIMessageManager.new()
	self.animalSystem = AnimalSystem.new(self:getIsServer(), self)
	self.animalFoodSystem = AnimalFoodSystem.new(self)
	self.animalNameSystem = AnimalNameSystem.new(self)
	self.husbandrySystem = HusbandrySystem.new(self:getIsServer(), self)
	self.wildlifeSpawner = WildlifeSpawner.new()
	self.vineSystem = VineSystem.new(self:getIsServer(), self)
	self.vehicleSaleSystem = VehicleSaleSystem.new(self)
	self.collectiblesSystem = CollectiblesSystem.new(self:getIsServer())
	self.guidedTour = GuidedTour.new(self)
	self.indoorMask = IndoorMask.new(self, self:getIsServer())
	self.snowSystem = SnowSystem.new(self, self:getIsServer())
	self.growthSystem = GrowthSystem.new(self, self:getIsServer())
	self.foliageSystem = FoliageSystem.new()
	self.slotSystem = SlotSystem.new(self)
	self.economyManager = EconomyManager.new()
	self.playerUserId = -1
	self.playerNickname = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)
	self.blockedIps = {}
	self.clientUserId = nil
	self.terrainSize = 1
	self.terrainDetailMapSize = 1
	self.fruitMapSize = 1
	self.dynamicFoliageLayers = {}
	self.terrainDetailId = 0
	self.mapsSplitShapeFileIds = {}
	self.isMasterUser = false
	self.connectionWasClosed = false
	self.connectionWasAccepted = false
	self.checkRecordingDeviceTimer = 0
	self.lastRecordingDeviceState = not Platform.isStadia
	self.cameraPaths = {}
	self.cameraPathIsPlaying = false
	self.cullingWorldXZOffset = 0
	self.cullingWorldMinY = -100
	self.cullingWorldMaxY = 500
	self.densityMapPercentageFraction = 0.7
	self.splitShapesPercentageFraction = 0.2
	self.restPercentageFraction = 1 - self.densityMapPercentageFraction - self.splitShapesPercentageFraction
	self.doghouses = {}
	self.tireTrackSystem = nil
	self.placeables = {}
	self.placeablesToDelete = {}
	self.placeablesDeleteTestTime = 0
	self.liquidManureLoadingStations = {}
	self.manureLoadingStations = {}
	self.limitedObjects = {
		[FSBaseMission.LIMITED_OBJECT_TYPE_BALE] = {
			maxNumObjects = 200,
			objects = {}
		}
	}
	self.vehicleChangeListeners = {}
	self.masterUsers = {}
	self.connectedToDedicatedServer = false

	if g_dedicatedServer ~= nil then
		self.gameStatsInterval = g_dedicatedServer.gameStatsInterval
	else
		self.gameStatsInterval = 60000
	end

	self.gameStatsTime = 0
	self.wasNetworkError = false
	self.ambientSoundSystem = AmbientSoundSystem.new(self, g_soundPlayer)
	self.environmentAreaSystem = EnvironmentAreaSystem.new(self)
	self.reverbSystem = ReverbSystem.new(self)
	self.eventRadioToggle = ""
	self.radioEvents = {}
	self.moneyChanges = {}

	if g_isPresentationVersionPlaytimeCountdown ~= nil then
		self.playtimeReloadTimer = g_isPresentationVersionPlaytimeCountdown * 1000
	end

	return self
end

function FSBaseMission:initialize()
	FSBaseMission:superClass().initialize(self)
	g_treePlantManager:initialize()
	MoneyType.reset()

	self.foliageBendingSystem = nil

	if Platform.supportsFoliageBending then
		self.foliageBendingSystem = FoliageBendingSystem.new()
	end

	self.accessHandler = AccessHandler.new()
	self.storageSystem = StorageSystem.new(self.accessHandler)

	self:subscribeMessages()
	self.inGameMenu:setInGameMap(self.hud:getIngameMap())
	self.inGameMenu:setHUD(self.hud)

	self.productionChainManager = ProductionChainManager.new(self:getIsServer())
end

function FSBaseMission:delete()
	self.isExitingGame = true

	self.inGameMenu:reset()
	self:pauseRadio()

	if self.missionDynamicInfo ~= nil and self.missionDynamicInfo.isMultiplayer then
		voiceChatCleanup()
	end

	if self.receivingDensityMapEvent ~= nil then
		self.receivingDensityMapEvent:delete()

		self.receivingDensityMapEvent = nil
	end

	if self.receivingSplitShapesEvent ~= nil then
		self.receivingSplitShapesEvent:delete()

		self.receivingSplitShapesEvent = nil
	end

	if self.densityMapSyncer ~= nil then
		self.densityMapSyncer:delete()
	end

	destroyLowResCollisionHandler()

	if self.accessHandler ~= nil then
		self.accessHandler:delete()
	end

	if self.playerInfoStorage ~= nil then
		self.playerInfoStorage:delete()
	end

	self.growthSystem:delete()
	self.snowSystem:delete()
	self.indoorMask:delete()
	self.guidedTour:delete()
	self.collectiblesSystem:delete()
	self.vehicleSaleSystem:delete()
	self.reverbSystem:delete()
	self.environmentAreaSystem:delete()
	self.ambientSoundSystem:delete()
	self.aiSystem:delete()
	self.husbandrySystem:delete()
	self.animalFoodSystem:delete()
	self.animalNameSystem:delete()
	self.animalSystem:delete()
	self.fieldGroundSystem:delete()
	self.stoneSystem:delete()
	self.weedSystem:delete()
	self.vineSystem:delete()
	self.foliageSystem:delete()
	self.slotSystem:delete()
	self.aiJobTypeManager:delete()
	self.aiMessageManager:delete()

	if self.wildlifeSpawner ~= nil then
		self.wildlifeSpawner:delete()
	end

	g_farmManager:unloadMapData()
	g_helperManager:unloadMapData()
	g_npcManager:unloadMapData()
	g_farmlandManager:unloadMapData()
	g_missionManager:unloadMapData()
	g_fieldManager:unloadMapData()
	g_gameplayHintManager:unloadMapData()
	g_sprayTypeManager:unloadMapData()
	g_connectionHoseManager:unloadMapData()
	g_densityMapHeightManager:unloadMapData()
	g_vehicleTypeManager:unloadMapData()
	g_placeableTypeManager:unloadMapData()
	g_constructionBrushTypeManager:unloadMapData()
	g_specializationManager:unloadMapData()
	g_placeableSpecializationManager:unloadMapData()
	g_treePlantManager:unloadMapData()
	g_materialManager:unloadMapData()
	g_particleSystemManager:unloadMapData()
	g_motionPathEffectManager:unloadMapData()
	g_effectManager:unloadMapData()
	g_animationManager:unloadMapData()
	g_tensionBeltManager:unloadMapData()
	g_groundTypeManager:unloadMapData()
	g_weatherTypeManager:unloadMapData()
	g_gui:unloadMapData()
	g_xmlManager:unloadMapData()
	g_debugManager:unloadMapData()
	FSBaseMission:superClass().delete(self)

	if AIFieldWorker ~= nil then
		AIFieldWorker.deleteCollisionBox()
	end

	self.shopMenu:reset()

	for placeable in pairs(self.placeablesToDelete) do
		placeable:delete()
	end

	self.placeablesToDelete = {}

	FSDensityMapUtil.clearCache()
	DensityMapHeightUtil.clearCache()
	g_fillTypeManager:unloadMapData()
	g_fruitTypeManager:unloadMapData()
	g_baleManager:unloadMapData()
	g_licensePlateManager:unloadMapData()
	g_helpLineManager:unloadMapData()
	g_storeManager:unloadMapData()
	g_workAreaTypeManager:unloadMapData()
	g_configurationManager:unloadMapData()
	g_toolTypeManager:unloadMapData()
	g_splitTypeManager:unloadMapData()
	g_brandManager:unloadMapData()
	g_sleepManager:unloadMapData()

	if self.productionChainManager ~= nil then
		self.productionChainManager:unloadMapData()
	end

	if self.tireTrackSystem ~= nil then
		self.tireTrackSystem:delete()
	end

	if self.foliageBendingSystem ~= nil then
		self.foliageBendingSystem:delete()
	end

	if self.economyManager ~= nil then
		self.economyManager:delete()

		self.economyManager = nil
	end

	if g_soundPlayer ~= nil then
		g_soundPlayer:removeEventListener(self)

		if not GS_IS_CONSOLE_VERSION and not GS_IS_MOBILE_VERSION then
			g_soundPlayer:setStreamingAccessOwner(nil)
		end
	end

	removeConsoleCommand("gsMoneyAdd")
	removeConsoleCommand("gsStoreItemsExport")
	removeConsoleCommand("gsGreatDemandStart")
	removeConsoleCommand("gsFillUnitAdd")
	removeConsoleCommand("gsLivestockTrailerAdd")
	removeConsoleCommand("gsVehicleFuelSet")
	removeConsoleCommand("gsVehicleOperatingTimeSet")
	removeConsoleCommand("gsPalletAdd")
	removeConsoleCommand("gsTipCollisionsShow")
	removeConsoleCommand("gsPlacementCollisionsShow")
	removeConsoleCommand("gsTipCollisionsUpdate")
	removeConsoleCommand("gsVehicleShowDistance")
	removeConsoleCommand("gsVehicleReload")
	removeConsoleCommand("gsTeleport")
	removeConsoleCommand("gsSaveDediXMLStatsFile")
	removeConsoleCommand("gsSaveGame")
	removeConsoleCommand("gsVehicleLoadAll")
	removeConsoleCommand("gsTreeAdd")
	removeConsoleCommand("gsVehicleAddWear")
	removeConsoleCommand("gsVehicleAddDamage")
	removeConsoleCommand("gsVehicleAddDirt")
	removeConsoleCommand("gsVehicleTemperatureSet")
	removeConsoleCommand("gsActivateCameraPath")

	for _, v in pairs(self.cameraPaths) do
		v:delete()
	end

	if self.missionSuccessSound ~= nil then
		delete(self.missionSuccessSound)
	end

	g_gui:setClient(nil)
	g_gui:setServer(nil)
	self.inGameMenu:setInGameMap(nil)
	self.inGameMenu:setHUD(nil)
	self.inGameMenu:setPlayerFarm(nil)
	self.shopMenu:setPlayerFarm(nil)
	self.userManager:delete()
end

function FSBaseMission:load()
	self:startLoadingTask()

	if g_addCheatCommands then
		addConsoleCommand("gsVehicleShowDistance", "Shows the distance between vehicle and cam", "consoleCommandShowVehicleDistance", self)
	end

	if self:getIsServer() then
		if not self.missionDynamicInfo.isMultiplayer then
			addConsoleCommand("gsVehicleReload", "Reloads currently entered vehicle or vehicles within a range when second radius parameter is given", "consoleCommandReloadVehicle", self)
		end

		if g_addCheatCommands then
			addConsoleCommand("gsTipCollisionsShow", "Shows the collisions for tipping on the ground", "consoleCommandShowTipCollisions", self)
			addConsoleCommand("gsPlacementCollisionsShow", "Shows the collisions for placement and terraforming", "consoleCommandShowPlacementCollisions", self)
			addConsoleCommand("gsPalletAdd", "Adds a pallet", "consoleCommandAddPallet", self)
			addConsoleCommand("gsVehicleFuelSet", "Sets the vehicle fuel level", "consoleCommandSetFuel", self)
			addConsoleCommand("gsVehicleTemperatureSet", "Sets the vehicle motor temperature", "consoleCommandSetMotorTemperature", self)
			addConsoleCommand("gsFillUnitAdd", "Changes a fillUnit with given filllevel and filltype", "consoleCommandFillUnitAdd", self)
			addConsoleCommand("gsVehicleOperatingTimeSet", "Sets the vehicle operating time", "consoleCommandSetOperatingTime", self)
			addConsoleCommand("gsVehicleAddDirt", "Adds a given amount to current dirt amount", "consoleCommandAddDirtAmount", self)
			addConsoleCommand("gsVehicleAddWear", "Adds a given amount to current wear amount", "consoleCommandAddWearAmount", self)
			addConsoleCommand("gsVehicleAddDamage", "Adds a given amount to current damage amount", "consoleCommandAddDamageAmount", self)
			addConsoleCommand("gsVehicleLoadAll", "Load all vehicles", "consoleCommandLoadAllVehicles", self)
			addConsoleCommand("gsTreeAdd", "Load a tree", "consoleCommandLoadTree", self)
			addConsoleCommand("gsTeleport", "Teleports to given field or x/z-position", "consoleCommandTeleport", self)
		end

		if g_addTestCommands then
			addConsoleCommand("gsStoreItemsExport", "Exports storeItem data", "consoleCommandExportStoreItems", self)
			addConsoleCommand("gsGreatDemandStart", "Starts a great demand", "consoleStartGreatDemand", self)
			addConsoleCommand("gsTipCollisionsUpdate", "Updates the collisions for tipping on the ground around the current camera", "consoleCommandUpdateTipCollisions", self)
			addConsoleCommand("gsSaveDediXMLStatsFile", "Saves dedi XML stats file", "consoleCommandSaveDediXMLStatsFile", self)
			addConsoleCommand("gsSaveGame", "Saves the current savegame", "consoleCommandSaveGame", self)
		end
	end

	if g_isDevelopmentVersion then
		addConsoleCommand("gsActivateCameraPath", "Activate camera path", "consoleActivateCameraPath", self)
	end

	self.economyManager:init(self)
	FSBaseMission:superClass().load(self)
	self.inGameMenu:setTerrainSize(self.terrainSize)

	self.missionSuccessSound = createSample("missionSuccessSound")

	loadSample(self.missionSuccessSound, "data/sounds/ui/uiSuccess.wav", false)
	self:setHarvestScaleRatio(unpack(Platform.gameplay.harvestScaleRation))
	self:finishLoadingTask()
end

function FSBaseMission:setHarvestScaleRatio(sprayRatio, plowRatio, limeRatio, weedRatio, stubbleRatio, rollerRatio)
	self.harvestSprayScaleRatio = sprayRatio
	self.harvestPlowScaleRatio = plowRatio
	self.harvestLimeScaleRatio = limeRatio
	self.harvestWeedScaleRatio = weedRatio
	self.harvestStubbleScaleRatio = stubbleRatio
	self.harvestRollerRatio = rollerRatio
end

function FSBaseMission:getHarvestScaleMultiplier(fruitTypeIndex, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPercentage)
	local multiplier = 1
	multiplier = multiplier + self.harvestSprayScaleRatio * sprayFactor
	multiplier = multiplier + self.harvestPlowScaleRatio * plowFactor
	multiplier = multiplier + self.harvestLimeScaleRatio * limeFactor
	multiplier = multiplier + self.harvestWeedScaleRatio * weedFactor
	multiplier = multiplier + self.harvestStubbleScaleRatio * stubbleFactor
	multiplier = multiplier + self.harvestRollerRatio * rollerFactor
	multiplier = multiplier + (beeYieldBonusPercentage or 0)

	return multiplier
end

function FSBaseMission:onStartMission()
	FSBaseMission:superClass().onStartMission(self)
	g_asyncTaskManager:setAllowedTimePerFrame(nil)

	if g_client ~= nil then
		if self:getIsServer() then
			local connection = g_server.clientConnections[NetworkNode.LOCAL_STREAM_ID]
			local user = self.userManager:getUserByConnection(connection)
			local farm = g_farmManager:getFarmByUserId(user:getId())
			local farmId = FarmManager.SPECTATOR_FARM_ID

			if farm ~= nil then
				farmId = farm.farmId
			end

			self:createPlayer(connection, true, farmId, user:getId())
			user:setState(FSBaseMission.USER_STATE_INGAME)
		else
			g_client:getServerConnection():sendEvent(ClientStartMissionEvent.new())
		end

		if g_dedicatedServer == nil and (not GS_IS_MOBILE_VERSION or not self.missionInfo.isNewSPCareer) then
			local spawnPoint = g_farmManager:getSpawnPoint(self.player.farmId)

			if not self.missionInfo.isValid then
				spawnPoint = g_mission00StartPoint
			end

			if spawnPoint ~= nil then
				local x, y, z = getWorldTranslation(spawnPoint)
				local dx, _, dz = localDirectionToWorld(spawnPoint, 0, 0, -1)
				local ry = MathUtil.getYRotationFromDirection(dx, dz)
				y = math.max(y, getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + 0.2)

				self.player:moveTo(x, y, z, true, false)
				self.player:setRotation(0, ry)
			else
				self.player:moveTo(self.playerStartX, self.playerStartY, self.playerStartZ, self.playerStartIsAbsolute, false)
				self.player:setRotation(self.playerRotX, self.playerRotY)
			end

			self.player:onEnter(true)
			self.hud:setIsControllingPlayer(true)
		end

		if not g_gameSettings:getValue("radioVehicleOnly") then
			self:playRadio()
		end

		self:setRadioVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_RADIO))
		self:setVehicleVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VEHICLE))
		self:setEnvironmentVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_ENVIRONMENT))
		self:setGUIVolume(g_gameSettings:getValue(GameSettings.SETTING.VOLUME_GUI))
	end

	if self.missionInfo ~= nil then
		Logging.info("Savegame Setting 'dirtInterval': %d", self.missionInfo.dirtInterval)
		Logging.info("Savegame Setting 'snowEnabled': %s", self.missionInfo.isSnowEnabled)
		Logging.info("Savegame Setting 'growthMode': %d", self.missionInfo.growthMode)
		Logging.info("Savegame Setting 'fuelUsageLow': %s", self.missionInfo.fuelUsageLow)
		Logging.info("Savegame Setting 'plowingRequiredEnabled': %s", self.missionInfo.plowingRequiredEnabled)
		Logging.info("Savegame Setting 'weedsEnabled': %s", self.missionInfo.weedsEnabled)
		Logging.info("Savegame Setting 'limeRequired': %s", self.missionInfo.limeRequired)
		Logging.info("Savegame Setting 'stonesEnabled': %s", self.missionInfo.stonesEnabled)
		Logging.info("Savegame Setting 'economicDifficulty': %s", self.missionInfo.economicDifficulty)
		Logging.info("Savegame Setting 'fixedSeasonalVisuals': %s", self.missionInfo.fixedSeasonalVisuals)
		Logging.info("Savegame Setting 'plannedDaysPerPeriod': %s", self.missionInfo.plannedDaysPerPeriod)

		if self:getIsServer() then
			local lastSaveDateStr = self.missionInfo.saveDate

			if lastSaveDateStr ~= nil then
				local todayStr = getDate("%Y-%m-%d")
				local yearLastSave, monthLastSave, _ = lastSaveDateStr:match("(%d%d%d%d)-(%d%d)-(%d%d)")
				local yearToday, monthToday, _ = todayStr:match("(%d%d%d%d)-(%d%d)-(%d%d)")
				monthLastSave = tonumber(monthLastSave)
				yearLastSave = tonumber(yearLastSave)
				monthToday = tonumber(monthToday)
				yearToday = tonumber(yearToday)

				if yearLastSave ~= nil and monthLastSave ~= nil and yearToday ~= nil and monthToday ~= nil and (yearLastSave < yearToday or monthLastSave <= monthToday) then
					if monthToday < monthLastSave then
						yearToday = yearToday - 1
						monthLastSave = monthLastSave - 12
					end

					local monthDif = monthToday - monthLastSave + (yearToday - yearLastSave) * 12

					g_achievementManager:tryUnlock("LoadedOldSavegame", monthDif)
				end
			end
		end
	end

	self:updateGameStatsXML()

	if self.helpIconsBase ~= nil then
		self.helpIconsBase:showHelpIcons(g_gameSettings:getValue("showHelpIcons"))
	end

	self:notifyPlayerFarmChanged(self.player)

	if GS_IS_MOBILE_VERSION and self.missionInfo.isNewSPCareer and #self.enterables > 0 then
		self:requestToEnterVehicle(self.enterables[1])
	end

	if self.missionDynamicInfo.isMultiplayer and g_dedicatedServer == nil then
		voiceChatAddLocalUser(self:getIsServer())
	end

	self.slotSystem:updateSlotUsage()

	self.playtimeCountdownEnabled = g_isPresentationVersionPlaytimeCountdown ~= nil
end

function FSBaseMission:createPlayer(connection, isOwner, farmId, userId)
	local player = Player.new(g_server ~= nil, true)
	player.farmId = farmId
	player.userId = userId

	player:load(connection, isOwner)
	player:updateHandTools()
	player:register(false)

	if g_server ~= nil then
		local uniqueUserId = self.userManager:getUniqueUserIdByUserId(userId)
		local playerStyle = nil
		local nickname = self.userManager:getUserByUserId(userId):getNickname()

		if self.playerInfoStorage:hasPlayerWithUniqueUserId(uniqueUserId) then
			playerStyle = self.playerInfoStorage:getPlayerStyle(userId)
		else
			playerStyle = PlayerStyle.defaultStyle()

			self.playerInfoStorage:addNewPlayer(uniqueUserId, playerStyle)
		end

		player:setUIText(nickname)
		player:setStyleAsync(playerStyle, nil, false)
	end
end

function FSBaseMission:getClientPosition()
	return getWorldTranslation(getCamera())
end

function FSBaseMission:setLoadingScreen(loadingScreen)
	self.loadingScreen = loadingScreen
end

function FSBaseMission:onConnectionOpened(connection)
end

function FSBaseMission:onConnectionAccepted(connection)
	self.connectionWasAccepted = true

	if self.loadingScreen ~= nil then
		self.loadingScreen:onWaitingForAccept()
	end

	local playerName = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)

	g_client:getServerConnection():sendEvent(ConnectionRequestEvent.new(g_gameSettings:getValue("mpLanguage"), self.missionDynamicInfo.password, getUniqueUserId(), getUserId(), getPlatformId(), playerName, self.missionDynamicInfo.platformSessionId), nil, true)
end

function FSBaseMission:onConnectionRequest(connection, languageIndex, password, uniqueUserId, platformUserId, platformId, playerName, platformSessionId)
	if connection.streamId ~= NetworkNode.LOCAL_STREAM_ID then
		local userCount = self.userManager:getNumberOfUsers()

		if g_dedicatedServer ~= nil then
			userCount = userCount - 1
		end

		if self.missionDynamicInfo.capacity <= userCount + #self.playersToAccept then
			connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ANSWER_FULL), nil, true)
			g_server:closeConnection(connection)

			return
		end

		if getIsUserBlocked(uniqueUserId, platformUserId, platformId) then
			connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ANSWER_ALWAYS_DENIED), nil, true)
			g_server:closeConnection(connection)

			return
		end

		local keyAlreadyInUse = self.userManager:getUserByUniqueId(uniqueUserId) ~= nil

		if not keyAlreadyInUse then
			for _, playerToAccept in ipairs(self.playersToAccept) do
				if playerToAccept.uniqueUserId == uniqueUserId then
					keyAlreadyInUse = true

					break
				end
			end
		end

		if keyAlreadyInUse then
			connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ALREADY_IN_USE), nil, true)
			g_server:closeConnection(connection)

			return
		end

		if not self.slotSystem:getCanConnect(uniqueUserId, platformId) then
			connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.SLOT_LIMIT_REACHED), nil, true)
			g_server:closeConnection(connection)

			return
		end

		if self.missionDynamicInfo.password == password then
			table.insert(self.playersToAccept, {
				connection = connection,
				playerName = playerName,
				language = languageIndex,
				platformUserId = platformUserId,
				platformId = platformId,
				uniqueUserId = uniqueUserId,
				platformSessionId = platformSessionId
			})
		else
			connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ANSWER_WRONG_PASSWORD), nil, true)
			g_server:closeConnection(connection)

			return
		end
	else
		local userId = self.userManager:getNextUserId()

		assert(userId == 1)

		self.playerUserId = 1
		local user = User.new()

		user:setId(userId)
		user:setConnection(connection)
		user:setUniqueUserId(uniqueUserId)
		user:setPlatformUserId(platformUserId)
		user:setPlatformId(platformId)
		user:setIsMasterUser(true)
		user:setLanguageIndex(languageIndex)
		user:setConnectedTime(self.time)
		user:setState(FSBaseMission.USER_STATE_CONNECTED)
		user:setNickname(playerName)

		self.playerNickname = playerName
		local knownPlayer = self.playerInfoStorage:hasPlayerWithUniqueUserId(uniqueUserId)

		self.userManager:addUser(user)
		self.userManager:addMasterUserByConnection(connection)
		self:sendNumPlayersToMasterServer(1)
		connection:sendEvent(ConnectionRequestAnswerEvent.new(ConnectionRequestAnswerEvent.ANSWER_OK, self.missionInfo.difficulty, self.missionInfo.economicDifficulty, self.missionInfo.timeScale, g_dedicatedServer ~= nil, self.playerUserId, playerName, knownPlayer), nil, true)
		self.slotSystem:updateSlotLimit()
	end
end

function FSBaseMission:canPlayerChangeNickname(player, toNickname)
	if toNickname:len() < 3 then
		return false
	end

	local name = toNickname:trim()
	local filteredName = filterText(name, true, true)

	if name ~= filteredName then
		return false
	end

	local newNickname = toNickname
	local existingUser = self.userManager:getUserByNickname(toNickname, true)
	local index = 1

	while existingUser ~= nil and existingUser.id ~= player.userId do
		newNickname = toNickname .. " (" .. index .. ")"
		existingUser = self.userManager:getUserByNickname(newNickname, true)
		index = index + 1
	end

	return true, newNickname
end

function FSBaseMission:setPlayerNickname(player, nickname, userId, noEventSend)
	local allowed = nil

	if self:getIsServer() then
		allowed, nickname = self:canPlayerChangeNickname(player, nickname)

		if allowed then
			local user = self.userManager:getUserByUserId(player.userId)

			user:setNickname(nickname)
			player:setUIText(user:getNickname())

			if self.player == player then
				self.playerNickname = nickname
			end

			g_messageCenter:publish(MessageType.PLAYER_NICKNAME_CHANGED, player)

			if noEventSend == nil or noEventSend == false then
				g_server:broadcastEvent(PlayerSetNicknameEvent.new(player, nickname, player.userId), false, nil, player)
			end
		end
	elseif noEventSend == nil or noEventSend == false then
		g_client:getServerConnection():sendEvent(PlayerSetNicknameEvent.new(player, nickname, player.userId))
	elseif noEventSend == true then
		local user = self.userManager:getUserByUserId(userId)

		if user ~= nil then
			user:setNickname(nickname)
			player:setUIText(user:getNickname())
		else
			player:setUIText(nickname)
		end

		if self.player == player then
			self.playerNickname = nickname
		end

		g_messageCenter:publish(MessageType.PLAYER_NICKNAME_CHANGED, player)
	end
end

function FSBaseMission:onConnectionDenyAccept(connection, isDenied, isAlwaysDenied)
	local playerToAccept = nil

	for i = 1, #self.playersToAccept do
		local p = self.playersToAccept[i]

		if p.connection == connection then
			playerToAccept = p

			table.remove(self.playersToAccept, i)

			break
		end
	end

	if playerToAccept == nil then
		return
	end

	local playerName = ""
	local user = nil
	local knownPlayer = false
	local answer = ConnectionRequestAnswerEvent.ANSWER_OK

	if isAlwaysDenied then
		setIsUserBlocked(playerToAccept.uniqueUserId, playerToAccept.platformUserId, playerToAccept.platformId, true, playerToAccept.playerName)

		answer = ConnectionRequestAnswerEvent.ANSWER_ALWAYS_DENIED
	elseif isDenied then
		answer = ConnectionRequestAnswerEvent.ANSWER_DENIED
	else
		playerName = playerToAccept.playerName
		local languageIndex = playerToAccept.language
		local uniqueUserId = playerToAccept.uniqueUserId
		local platformUserId = playerToAccept.platformUserId
		local platformId = playerToAccept.platformId
		local platformSessionId = playerToAccept.platformSessionId
		knownPlayer = self.playerInfoStorage:hasPlayerWithUniqueUserId(uniqueUserId)
		local newNickname = playerName
		local index = 1
		local existingUser = self.userManager:getUserByNickname(playerName, true)

		while existingUser ~= nil do
			newNickname = playerName .. " (" .. index .. ")"
			existingUser = self.userManager:getUserByNickname(newNickname, true)
			index = index + 1
		end

		playerName = newNickname
		local financeUpdateSendTime = self.time + math.floor(math.random() * 300 + 400)
		user = User.new()

		user:setId(self.userManager:getNextUserId())
		user:setNickname(playerName)
		user:setConnection(connection)
		user:setUniqueUserId(uniqueUserId)
		user:setPlatformUserId(platformUserId)
		user:setPlatformId(platformId)
		user:setPlatformSessionId(platformSessionId)
		user:setLanguageIndex(languageIndex)
		user:setConnectedTime(self.time)
		user:setState(FSBaseMission.USER_STATE_LOADING)
		user:setFinanceUpdateSendTime(financeUpdateSendTime)
		self.userManager:addUser(user)
		self:sendNumPlayersToMasterServer(self.userManager:getNumberOfUsers())
		self:sendPlatformSessionIdsToMasterServer(self.userManager:getAllPlatformSessionIds())
		voiceChatAddConnection(connection.streamId, playerToAccept.uniqueUserId, playerToAccept.platformUserId, playerToAccept.platformId)

		self.playersLoading[connection] = {
			connection = connection,
			user = user
		}

		self.slotSystem:updateSlotLimit()
	end

	local playerFarm = g_farmManager:getFarmForUniqueUserId(playerToAccept.uniqueUserId)
	local userId = user ~= nil and user:getId() or nil

	connection:sendEvent(ConnectionRequestAnswerEvent.new(answer, self.missionInfo.difficulty, self.missionInfo.economicDifficulty, self.missionInfo.timeScale, g_dedicatedServer ~= nil, userId, playerName, knownPlayer), nil, true)

	if answer == ConnectionRequestAnswerEvent.ANSWER_OK then
		self:createPlayer(connection, false, playerFarm.farmId, user:getId())
	else
		g_server:closeConnection(connection)
	end
end

function FSBaseMission:onConnectionRequestAnswer(connection, answer, difficulty, economicDifficulty, timeScale, connectedToDedicatedServer, clientUserId, playerName, knownPlayer)
	if answer == ConnectionRequestAnswerEvent.ANSWER_OK then
		self.missionInfo.difficulty = difficulty
		self.missionInfo.economicDifficulty = economicDifficulty
		self.missionInfo.timeScale = timeScale
		self.connectedToDedicatedServer = connectedToDedicatedServer

		self:onConnectionRequestAccepted(connection, knownPlayer)

		self.playerUserId = clientUserId
		self.playerNickname = playerName
	else
		self.connectionWasClosed = true
		local text = g_i18n:getText("ui_serverDeniedAccess")

		if answer == ConnectionRequestAnswerEvent.ANSWER_WRONG_PASSWORD then
			text = g_i18n:getText("ui_wrongPassword")
		elseif answer == ConnectionRequestAnswerEvent.ANSWER_ALWAYS_DENIED then
			text = g_i18n:getText("ui_banned")
		elseif answer == ConnectionRequestAnswerEvent.ANSWER_FULL then
			text = g_i18n:getText("ui_gameFull")
		elseif answer == ConnectionRequestAnswerEvent.ALREADY_IN_USE then
			text = g_i18n:getText("ui_connectionLostKeyInUse")
		elseif answer == ConnectionRequestAnswerEvent.SLOT_LIMIT_REACHED then
			text = g_i18n:getText("ui_serverDeniedSlotLimitReached")
		end

		g_gui:showInfoDialog({
			text = text,
			callback = self.onConnectionRequestAnswerOk,
			target = self
		})
	end
end

function FSBaseMission:onConnectionRequestAnswerOk()
	OnInGameMenuMenu()

	if masterServerConnectFront ~= nil then
		g_multiplayerScreen:initJoinGameScreen()
		g_gui:showGui("ConnectToMasterServerScreen")

		if g_masterServerConnection.lastBackServerIndex >= 0 then
			g_connectToMasterServerScreen:connectToBack(g_masterServerConnection.lastBackServerIndex)
		else
			g_connectToMasterServerScreen:connectToFront()
		end
	end
end

function FSBaseMission:onConnectionRequestAccepted(connection, knownPlayer)
	if self.loadingScreen ~= nil then
		self.loadingScreen:loadWithConnection(connection, knownPlayer)
	end
end

function FSBaseMission:onConnectionRequestAcceptedLoad(connection)
	self.loadingConnection = connection

	simulatePhysics(false)
	self:load()
end

function FSBaseMission:onFinishedLoading()
	FSBaseMission:superClass().onFinishedLoading(self)

	local connection = self.loadingConnection

	if not self:getIsServer() then
		setCamera(g_defaultCamera)

		local x, y, z = self:getClientPosition()

		if self.loadingScreen ~= nil then
			self.loadingScreen:onWaitingForDynamicData()
		end

		self.pressStartPaused = true

		self:pauseGame()
		connection:sendEvent(BaseMissionFinishedLoadingEvent.new(x, y, z, getViewDistanceCoeff()), nil, true)
	else
		self.pressStartPaused = true

		self:pauseGame()

		if self.loadingScreen ~= nil then
			self.loadingScreen:onFinishedReceivingDynamicData()
		end
	end
end

function FSBaseMission:getAllowsGuiDisplay()
	if self.isSynchronizingWithPlayers and self.player ~= nil then
		return false
	end

	if g_sleepManager:getIsSleeping() then
		return false
	end

	return true
end

function FSBaseMission:onConnectionFinishedLoading(connection, x, y, z, viewDistanceCoeff)
	assert(not connection:getIsLocal(), "No local connection allowed in BaseMission:onConnectionFinishedLoading")

	if self.playersSynchronizing[connection] ~= nil or self.playersLoading[connection] == nil then
		g_server:closeConnection(connection)

		return
	end

	local user = self.playersLoading[connection].user
	self.playersLoading[connection] = nil

	addSplitShapeConnection(connection.streamId, user:getPlatformId())

	if self.densityMapSyncer ~= nil then
		self.densityMapSyncer:addConnection(connection.streamId)
	end

	addTerrainUpdateConnection(self.terrainRootNode, connection.streamId)
	connection:setIsReadyForEvents(true)
	user:setState(FSBaseMission.USER_STATE_SYNCHRONIZING)

	local syncPlayer = {
		connection = connection,
		user = user
	}
	self.playersSynchronizing[connection] = syncPlayer

	if g_dedicatedServer ~= nil then
		g_dedicatedServer:raiseFramerate()

		self.dediEmptyPaused = false
	end

	self.isSynchronizingWithPlayers = true

	self:pauseGame()
	g_farmManager:playerJoinedGame(user:getUniqueUserId(), user:getId(), user, connection)
	g_server:sendEventIds(connection)
	g_server:sendObjectClassIds(connection)
	connection:sendEvent(OnCreateLoadedObjectEvent.new())
	g_server:sendObjects(connection, x, y, z, viewDistanceCoeff)
	connection:sendEvent(SavegameSettingsEvent.new())
	connection:sendEvent(SlotSystemUpdateEvent.new(self.slotSystem.slotLimit))

	local farm = g_farmManager:getFarmForUniqueUserId(user:getUniqueUserId())

	self:sendInitialClientState(connection, user, farm)

	if self.loadingScreen ~= nil then
		self.loadingScreen:setDynamicDataPercentage(self.restPercentageFraction)
	end

	g_server:broadcastEvent(UserEvent.new(self.userManager:getUsers(), {}, self.missionDynamicInfo.capacity, true))

	local splitShapesEvent = SetSplitShapesEvent.new()
	syncPlayer.splitShapesEvent = splitShapesEvent

	connection:sendEvent(splitShapesEvent, false)
end

function FSBaseMission:sendInitialClientState(connection, user, farm)
	connection:sendEvent(EnvironmentTimeEvent.new(self.environment.currentMonotonicDay, self.environment.currentDay, self.environment.dayTime, self.environment.daysPerPeriod))

	local weather = self.environment.weather

	weather:sendInitialState(connection)
	connection:sendEvent(WeatherAddObjectEvent.new(weather.forecastItems, true))
	connection:sendEvent(FogStateEvent.new(weather.fogUpdater.targetMieScale, weather.fogUpdater.lastMieScale, weather.fogUpdater.alpha, weather.fogUpdater.duration, weather.fog.nightFactor, weather.fog.dayFactor))
	connection:sendEvent(FarmsInitialStateEvent.new(farm.farmId))

	if farm.farmId ~= 0 then
		connection:sendEvent(ChangeLoanEvent.new(farm.loan, farm.farmId))

		for i = 0, 4 do
			connection:sendEvent(FinanceStatsEvent.new(i, farm.farmId))
		end

		user:setFinancesVersionCounter(farm.stats.financesVersionCounter)
	end

	connection:sendEvent(FarmlandInitialStateEvent.new())
	connection:sendEvent(GreatDemandsEvent.new(self.economyManager.greatDemands))
	self.vehicleSaleSystem:sendAllToClient(connection)
	self.collectiblesSystem:onClientJoined(connection)
	self.aiSystem:onClientJoined(connection)
end

function FSBaseMission:onSplitShapesProgress(connection, percentage)
	if percentage < 1 then
		if not self:getIsServer() and self.loadingScreen ~= nil then
			self.loadingScreen:setDynamicDataPercentage(percentage * self.splitShapesPercentageFraction + self.restPercentageFraction)
		end
	elseif self:getIsServer() then
		local syncPlayer = self.playersSynchronizing[connection]

		if syncPlayer ~= nil then
			if syncPlayer.splitShapesEvent ~= nil then
				syncPlayer.splitShapesEvent:delete()

				syncPlayer.splitShapesEvent = nil
			end

			connection:sendEvent(BaseMissionReadyEvent.new(), nil, true)
		end
	end
end

function FSBaseMission:onFinishedReceivingDynamicData(connection)
	if self.loadingScreen ~= nil then
		self.loadingScreen:onFinishedReceivingDynamicData()
		connection:sendEvent(BaseMissionReadyEvent.new(), nil, true)
	end
end

function FSBaseMission:onConnectionReady(connection)
	local syncPlayer = self.playersSynchronizing[connection]

	if syncPlayer == nil then
		g_server:closeConnection(connection)

		return
	end

	if syncPlayer.densityMapEvent ~= nil then
		syncPlayer.densityMapEvent:delete()

		syncPlayer.densityMapEvent = nil
	end

	if syncPlayer.splitShapesEvent ~= nil then
		syncPlayer.splitShapesEvent:delete()

		syncPlayer.splitShapesEvent = nil
	end

	connection:setIsReadyForObjects(true)

	local user = syncPlayer.user

	user:setState(FSBaseMission.USER_STATE_CONNECTED)

	self.playersSynchronizing[connection] = nil

	if next(self.playersSynchronizing) == nil then
		self.isSynchronizingWithPlayers = false

		self:tryUnpauseGame()
		self:showPauseDisplay(self.paused)
	end
end

function FSBaseMission:onConnectionClosed(connection)
	if not self:getIsServer() then
		if self.receivingDensityMapEvent ~= nil then
			self.receivingDensityMapEvent:delete()

			self.receivingDensityMapEvent = nil
		end

		if self.receivingSplitShapesEvent ~= nil then
			self.receivingSplitShapesEvent:delete()

			self.receivingSplitShapesEvent = nil
		end

		self:pauseGame()

		if not self.connectionWasClosed then
			self.isSynchronizingWithPlayers = false
			self.connectionWasClosed = true

			setPresenceMode(PresenceModes.PRESENCE_IDLE)

			if self.cleanServerShutDown == nil or not self.cleanServerShutDown then
				local text = g_i18n:getText("ui_failedToConnectToGame")

				if self.connectionWasAccepted then
					if self.connectionLostState == FSBaseMission.CONNECTION_LOST_KICKED then
						text = g_i18n:getText("ui_connectionLostKicked")
					elseif self.connectionLostState == FSBaseMission.CONNECTION_LOST_BANNED then
						text = g_i18n:getText("ui_connectionLostBanned")
					else
						text = g_i18n:getText("ui_connectionLost")
					end
				end

				if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "ChatDialog" then
					g_gui:showGui("")
				end

				g_gui:showInfoDialog({
					text = text,
					callback = OnInGameMenuMenu
				})
			end

			self.cleanServerShutDown = false
			self.connectionLostState = nil
		end
	else
		removeSplitShapeConnection(connection.streamId)

		if self.densityMapSyncer ~= nil then
			self.densityMapSyncer:removeConnection(connection.streamId)
		end

		removeTerrainUpdateConnection(self.terrainRootNode, connection.streamId)

		for i = 1, #self.playersToAccept do
			if self.playersToAccept[i].connection == connection then
				table.remove(self.playersToAccept, i)

				break
			end
		end

		self.playersLoading[connection] = nil
		local user = self.userManager:getUserByConnection(connection)

		if user ~= nil then
			g_farmManager:playerQuitGame(user:getId())
		end

		self.wildlifeSpawner:onConnectionClosed()

		for _, vehicle in pairs(self.vehicles) do
			if vehicle.owner == connection then
				g_client:getServerConnection():sendEvent(VehicleLeaveEvent.new(vehicle))
			end
		end

		self.userManager:removeUserByConnection(connection)
		voiceChatRemoveConnection(connection.streamId)

		local syncPlayer = self.playersSynchronizing[connection]

		if syncPlayer ~= nil then
			if syncPlayer.densityMapEvent ~= nil then
				syncPlayer.densityMapEvent:delete()
			end

			if syncPlayer.splitShapesEvent ~= nil then
				syncPlayer.splitShapesEvent:delete()
			end

			self.playersSynchronizing[connection] = nil

			if next(self.playersSynchronizing) == nil then
				self.isSynchronizingWithPlayers = false

				self:tryUnpauseGame()
				self:showPauseDisplay(self.paused)
			end
		end

		if self.connectionsToPlayer[connection] ~= nil then
			local player = self.connectionsToPlayer[connection]

			player:delete()

			self.connectionsToPlayer[connection] = nil
		end

		local userCount = self.userManager:getNumberOfUsers()

		self:sendNumPlayersToMasterServer(userCount)
		self:sendPlatformSessionIdsToMasterServer(self.userManager:getAllPlatformSessionIds())
		g_server:broadcastEvent(UserEvent.new({}, {
			user
		}, self.missionDynamicInfo.capacity, false))
		self.slotSystem:updateSlotLimit()

		if userCount == 1 and g_dedicatedServer ~= nil then
			g_dedicatedServer:lowerFramerate()

			if g_dedicatedServer.pauseGameIfEmpty then
				self.dediEmptyPaused = true

				self:pauseGame()
			end
		end
	end
end

function FSBaseMission:cancelPlayersSynchronizing()
	for connection, _ in pairs(self.playersSynchronizing) do
		g_server:closeConnection(connection)
	end
end

function FSBaseMission:onConnectionsUpdateTick(dt)
	if self:getIsServer() then
		if #g_server.clients > 0 then
			prepareSplitShapesServerWriteUpdateStream(dt)

			if startWriteSplitShapesServerEvents() then
				for streamId, connection in pairs(g_server.clientConnections) do
					if streamId ~= NetworkNode.LOCAL_STREAM_ID then
						connection:sendEvent(UpdateSplitShapesEvent.new())
					end
				end

				finishWriteSplitShapesServerEvents()
			end
		end

		self.sendMoneyUserIndex = self.sendMoneyUserIndex + 2

		if self.userManager:getNumberOfUsers() < self.sendMoneyUserIndex then
			self.sendMoneyUserIndex = 1
		end
	end
end

function FSBaseMission:onConnectionWriteUpdateStream(connection, maxPacketSize, networkDebug)
	if not connection:getIsServer() then
		local treePacketPercentage = 0.3
		local densityPacketPercentage = 0.2
		local terrainDeformPacketPercentage = 0.2
		local startSplitShapesOffset = nil

		if networkDebug then
			startSplitShapesOffset = streamGetWriteOffset(connection.streamId)

			streamWriteInt32(connection.streamId, 0)
		end

		local x, y, z = g_server:getClientPosition(connection.streamId)
		local viewCoeff = g_server:getClientClipDistCoeff(connection.streamId)
		local oldPacketSize = streamGetWriteOffset(connection.streamId)

		writeSplitShapesServerUpdateToStream(connection.streamId, connection.streamId, x, y, z, viewCoeff, maxPacketSize * treePacketPercentage)
		g_server:addPacketSize(NetworkNode.PACKET_SPLITSHAPES, (streamGetWriteOffset(connection.streamId) - oldPacketSize) / 8)

		if networkDebug then
			local endSplitShapesOffset = streamGetWriteOffset(connection.streamId)

			streamSetWriteOffset(connection.streamId, startSplitShapesOffset)
			streamWriteInt32(connection.streamId, endSplitShapesOffset - (startSplitShapesOffset + 32))
			streamSetWriteOffset(connection.streamId, endSplitShapesOffset)
		end

		if self.densityMapSyncer ~= nil then
			local syncerMaxPacketSize = maxPacketSize * densityPacketPercentage

			self.densityMapSyncer:writeUpdateStream(connection, syncerMaxPacketSize, x, y, z, viewCoeff, networkDebug)
		end

		local startTerrainOffset = nil

		if networkDebug then
			startTerrainOffset = streamGetWriteOffset(connection.streamId)

			streamWriteInt32(connection.streamId, 0)
		end

		local syncerMaxPacketSize = maxPacketSize * terrainDeformPacketPercentage
		oldPacketSize = streamGetWriteOffset(connection.streamId)

		writeTerrainUpdateStream(self.terrainRootNode, connection.streamId, connection.streamId, syncerMaxPacketSize, x, y, z)
		g_server:addPacketSize(NetworkNode.PACKET_TERRAIN_DEFORM, (streamGetWriteOffset(connection.streamId) - oldPacketSize) / 8)

		if networkDebug then
			local endTerrainOffset = streamGetWriteOffset(connection.streamId)

			streamSetWriteOffset(connection.streamId, startTerrainOffset)
			streamWriteInt32(connection.streamId, endTerrainOffset - (startTerrainOffset + 32))
			streamSetWriteOffset(connection.streamId, endTerrainOffset)
		end

		local startVoiceChat = nil

		if networkDebug then
			startVoiceChat = streamGetWriteOffset(connection.streamId)

			streamWriteInt32(connection.streamId, 0)
		end

		oldPacketSize = streamGetWriteOffset(connection.streamId)

		voiceChatWriteServerUpdateToStream(connection.streamId, connection.streamId, connection.lastSeqSent)
		g_server:addPacketSize(NetworkNode.PACKET_VOICE_CHAT, (streamGetWriteOffset(connection.streamId) - oldPacketSize) / 8)

		if networkDebug then
			local endVoiceChat = streamGetWriteOffset(connection.streamId)

			streamSetWriteOffset(connection.streamId, startVoiceChat)
			streamWriteInt32(connection.streamId, endVoiceChat - (startVoiceChat + 32))
			streamSetWriteOffset(connection.streamId, endVoiceChat)
		end
	end
end

function FSBaseMission:onConnectionReadUpdateStream(connection, networkDebug)
	if connection:getIsServer() then
		local startOffset = 0
		local numBits = 0

		if networkDebug then
			startOffset = streamGetReadOffset(connection.streamId)
			numBits = streamReadInt32(connection.streamId)
		end

		readSplitShapesServerUpdateFromStream(connection.streamId, g_clientInterpDelay, g_packetPhysicsNetworkTime, g_client.tickDuration)

		if networkDebug then
			g_client:checkObjectUpdateDebugReadSize(connection.streamId, numBits, startOffset, "splitshape")
		end

		if self.densityMapSyncer ~= nil then
			self.densityMapSyncer:readUpdateStream(connection, networkDebug)
		end

		startOffset = 0
		numBits = 0

		if networkDebug then
			startOffset = streamGetReadOffset(connection.streamId)
			numBits = streamReadInt32(connection.streamId)
		end

		readTerrainUpdateStream(self.terrainRootNode, connection.streamId)

		if networkDebug then
			g_client:checkObjectUpdateDebugReadSize(connection.streamId, numBits, startOffset, "terrainmods")
		end

		startOffset = 0
		numBits = 0

		if networkDebug then
			startOffset = streamGetReadOffset(connection.streamId)
			numBits = streamReadInt32(connection.streamId)
		end

		voiceChatReadServerUpdateFromStream(connection.streamId, g_clientInterpDelay, connection.lastSeqSent)

		if networkDebug then
			g_client:checkObjectUpdateDebugReadSize(connection.streamId, numBits, startOffset, "voicechat")
		end
	end
end

function FSBaseMission:onFinishedClientsWriteUpdateStream()
end

function FSBaseMission:onConnectionPacketSent(connection, packetId)
	voiceChatNotifyPacketSent(packetId)
end

function FSBaseMission:onConnectionPacketLost(connection, packetId)
	voiceChatNotifyPacketLost(packetId)

	if not connection:getIsServer() and self.densityMapSyncer ~= nil then
		self.densityMapSyncer:onPacketLost(connection, packetId)
	end
end

function FSBaseMission:onShutdownEvent(connection)
	if not self:getIsServer() then
		self.cleanServerShutDown = true

		setPresenceMode(PresenceModes.PRESENCE_IDLE)
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_serverWasShutdown"),
			callback = self.onShutdownEventOk,
			target = self
		})
	else
		local user = self.userManager:getUserByConnection(connection)

		self.userManager:removeUserByConnection(connection)
		voiceChatRemoveConnection(connection.streamId)
		self:sendNumPlayersToMasterServer(self.userManager:getNumberOfUsers())
		self:sendPlatformSessionIdsToMasterServer(self.userManager:getAllPlatformSessionIds())
		g_server:broadcastEvent(UserEvent.new({}, {
			user
		}, self.missionDynamicInfo.capacity, false))
	end
end

function FSBaseMission:onShutdownEventOk()
	OnInGameMenuMenu()
end

function FSBaseMission:onMasterServerConnectionReady()
end

function FSBaseMission:onMasterServerConnectionFailed(reason)
	if self.isMissionStarted then
		g_gui:showGui("InGameMenu")
		self.inGameMenu:setMasterServerConnectionFailed(reason)
	else
		OnInGameMenuMenu(false, true)
	end
end

function FSBaseMission:getServerUserId()
	return 1
end

function FSBaseMission:getFarmId(connection)
	if self:getIsServer() then
		if self.player ~= nil and connection == nil then
			return self.player.farmId
		end

		if connection == nil then
			return nil
		end

		local player = self:getPlayerByConnection(connection)

		if player == nil then
			return nil
		end

		return player.farmId
	else
		if self.player == nil then
			return 0
		end

		return self.player.farmId
	end
end

function FSBaseMission:farmStats(farmId)
	if farmId == nil then
		farmId = self.player.farmId
	end

	local farm = g_farmManager:getFarmById(farmId)

	if farm == nil then
		print("Error: Farm not found for stats")

		return FarmStats.new()
	end

	return farm.stats
end

function FSBaseMission:getPlayerByConnection(connection)
	return self.connectionsToPlayer[connection]
end

function FSBaseMission:kickUser(user)
	assert(self:getIsServer())

	local connection = user:getConnection()

	connection:sendEvent(KickBanNotificationEvent.new(true))
	g_server:closeConnection(connection)
end

function FSBaseMission:banUser(user)
	user:block()

	if self:getIsServer() then
		local connection = user:getConnection()

		connection:sendEvent(KickBanNotificationEvent.new(false))
		g_server:closeConnection(connection)
	end
end

function FSBaseMission:onObjectCreated(object)
	FSBaseMission:superClass().onObjectCreated(self, object)

	if self.slotSystem:getIsCountableObject(object) then
		self.slotSystem:updateSlotUsage()
	end
end

function FSBaseMission:onObjectDeleted(object)
	FSBaseMission:superClass().onObjectDeleted(self, object)

	if self.slotSystem:getIsCountableObject(object) then
		self.slotSystem:updateSlotUsage()
	end
end

function FSBaseMission:addVehicle(vehicle)
	FSBaseMission:superClass().addVehicle(self, vehicle)

	for _, listener in ipairs(self.vehicleChangeListeners) do
		listener:onVehiclesChanged(vehicle, true, false)
	end
end

function FSBaseMission:removeVehicle(vehicle, callDelete)
	FSBaseMission:superClass().removeVehicle(self, vehicle, callDelete)

	for _, listener in ipairs(self.vehicleChangeListeners) do
		listener:onVehiclesChanged(vehicle, false, self.isExitingGame)
	end
end

function FSBaseMission:addVehicleChangeListener(listener)
	if listener ~= nil then
		table.addElement(self.vehicleChangeListeners, listener)
	end
end

function FSBaseMission:removeVehicleChangeListener(listener)
	if listener ~= nil then
		table.removeElement(self.vehicleChangeListeners, listener)
	end
end

function FSBaseMission:addOwnedItem(item)
	FSBaseMission:superClass().addOwnedItem(self, item)

	local farmId = self.player ~= nil and self.player.farmId or AccessHandler.EVERYONE

	self.shopController:setOwnedFarmItems(self.ownedItems, farmId)
end

function FSBaseMission:removeOwnedItem(item)
	FSBaseMission:superClass().removeOwnedItem(self, item)

	local farmId = self.player ~= nil and self.player.farmId or AccessHandler.EVERYONE

	self.shopController:setOwnedFarmItems(self.ownedItems, farmId)
end

function FSBaseMission:addLeasedItem(item)
	FSBaseMission:superClass().addLeasedItem(self, item)

	local farmId = self.player ~= nil and self.player.farmId or AccessHandler.EVERYONE

	self.shopController:setLeasedFarmItems(self.leasedVehicles, farmId)
end

function FSBaseMission:removeLeasedItem(item)
	FSBaseMission:superClass().removeLeasedItem(self, item)

	local farmId = self.player ~= nil and self.player.farmId or AccessHandler.EVERYONE

	self.shopController:setLeasedFarmItems(self.leasedVehicles, farmId)
end

function FSBaseMission:loadMap(filename, addPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local loadingFileId = -1

	if self.missionInfo.mapsSplitShapeFileIds ~= nil then
		loadingFileId = Utils.getNoNil(self.missionInfo.mapsSplitShapeFileIds[#self.mapsSplitShapeFileIds + 1], -1)
	end

	setSplitShapesLoadingFileId(loadingFileId)

	local splitShapeFileId = setSplitShapesNextFileId()

	table.insert(self.mapsSplitShapeFileIds, splitShapeFileId)
	FSBaseMission:superClass().loadMap(self, filename, addPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
end

function FSBaseMission:registerToLoadOnMapFinished(object)
	table.insert(self.objectsToCallOnMapFinished, object)
end

function FSBaseMission:loadMapFinished(node, failedReason, arguments, callAsyncCallback)
	local startedRepeat = startFrameRepeatMode()

	FSBaseMission:superClass().loadMapFinished(self, node, failedReason, arguments, false)

	local filename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments = unpack(arguments)

	if self.trafficSystem ~= nil and self.trafficSystem.trafficSystemId ~= nil and self.pedestrianSystem ~= nil and self.pedestrianSystem.pedestrianSystemId ~= nil then
		setPedestrianSystemTrafficSystem(self.pedestrianSystem.pedestrianSystemId, self.trafficSystem.trafficSystemId)
	end

	if node ~= 0 then
		local terrainNode = 0
		local numChildren = getNumOfChildren(node)

		for i = 0, numChildren - 1 do
			local t = getChildAt(node, i)

			if getHasClassId(t, ClassIds.TERRAIN_TRANSFORM_GROUP) then
				terrainNode = t

				break
			end
		end

		if terrainNode ~= 0 then
			self:initTerrain(terrainNode, filename)
		end
	end

	if setTrafficSystemVehicleNavigationMap ~= nil and self.trafficSystem ~= nil and self.trafficSystem.trafficSystemId ~= nil and self.aiSystem.navigationMap ~= nil then
		setTrafficSystemVehicleNavigationMap(self.trafficSystem.trafficSystemId, self.aiSystem.navigationMap)
	end

	if (callAsyncCallback == nil or callAsyncCallback) and asyncCallbackFunction ~= nil then
		asyncCallbackFunction(asyncCallbackObject, node, asyncCallbackArguments)
	end

	if startedRepeat then
		endFrameRepeatMode()
	end

	if not self.cancelLoading then
		for _, object in pairs(self.objectsToCallOnMapFinished) do
			object:onLoadMapFinished()
		end

		self.inGameMenu:setManureTriggers(self.manureLoadingStations, self.liquidManureLoadingStations)
		self.inGameMenu:setConnectedUsers(self.userManager:getUsers())
		self.hud:setConnectedUsers(self.userManager:getUsers())
	end

	self.objectsToCallOnMapFinished = {}
end

function FSBaseMission:initTerrain(terrainId, filename)
	local isMultiplayer = self.missionDynamicInfo.isMultiplayer
	self.terrainRootNode = terrainId
	local terrainColMask = getCollisionMask(self.terrainRootNode)
	local newTerrainColMask = terrainColMask

	if not CollisionFlag.getHasFlagSet(terrainId, CollisionFlag.TERRAIN) then
		newTerrainColMask = bitOR(newTerrainColMask, CollisionFlag.TERRAIN)

		Logging.warning("Missing collision mask bit '%d'. Automatically added bit to terrain node '%s'", CollisionFlag.getBit(CollisionFlag.TERRAIN), getName(terrainId))
	end

	if CollisionFlag.getHasFlagSet(terrainId, CollisionFlag.AI_BLOCKING) then
		newTerrainColMask = bitAND(newTerrainColMask, bitNOT(CollisionFlag.AI_BLOCKING))

		Logging.warning("Terrain node '%s' has bit '%d' activated. Automatically removed this bit from collision mask", getName(terrainId), CollisionFlag.getBit(CollisionFlag.AI_BLOCKING))
	end

	if terrainColMask ~= newTerrainColMask then
		setCollisionMask(self.terrainRootNode, newTerrainColMask)
	end

	self.terrainSize = getTerrainSize(self.terrainRootNode)

	self.inGameMenu:setTerrainSize(self.terrainSize)
	createLowResCollisionHandler(64, 64, 1, 1048543, 4, 1048543, 5)
	setLowResCollisionHandlerTerrainRootNode(g_currentMission.terrainRootNode)

	local x, y, z = getWorldTranslation(self.terrainRootNode)

	if math.abs(x) > 0.1 or math.abs(z) > 0.1 or y < 0 then
		print("Warning: the terrain node needs to be a x=0 and z=0 and y >= 0")
	end

	self.areaCompressionParams = NetworkUtil.createWorldPositionCompressionParams(self.terrainSize, 0.5 * self.terrainSize, 0.02)
	self.areaRelativeCompressionParams = NetworkUtil.createWorldPositionCompressionParams(100, 50, 0.02)
	self.vehicleXZPosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(self.terrainSize + 500, 0.5 * (self.terrainSize + 500), 0.005)
	self.vehicleYPosCompressionParams = NetworkUtil.createWorldPositionCompressionParams(1500, 0, 0.005)
	self.vehicleXZPosHighPrecisionCompressionParams = NetworkUtil.createWorldPositionCompressionParams(self.terrainSize + 500, 0.5 * (self.terrainSize + 500), 0.0001)
	self.vehicleYPosHighPrecisionCompressionParams = NetworkUtil.createWorldPositionCompressionParams(1500, 0, 0.0001)

	setSplitShapesWorldCompressionParams(self.terrainSize, 0.5 * self.terrainSize, 0.005, 1700, 200, 0.005, self.terrainSize, 0.5 * self.terrainSize, 0.005)

	local worldSizeHalf = 0.5 * self.terrainSize + self.cullingWorldXZOffset
	local worldMinY = self.cullingWorldMinY
	local worldMaxY = self.cullingWorldMaxY

	setAudioCullingWorldProperties(-worldSizeHalf, worldMinY, -worldSizeHalf, worldSizeHalf, worldMaxY, worldSizeHalf, 16)
	setLightCullingWorldProperties(-worldSizeHalf, worldMinY, -worldSizeHalf, worldSizeHalf, worldMaxY, worldSizeHalf, 16)

	if GS_PLATFORM_PLAYSTATION then
		setShapeCullingWorldProperties(-worldSizeHalf, worldMinY, -worldSizeHalf, worldSizeHalf, worldMaxY, worldSizeHalf, 16)
	else
		setShapeCullingWorldProperties(-worldSizeHalf, worldMinY, -worldSizeHalf, worldSizeHalf, worldMaxY, worldSizeHalf, 64)
	end

	local foliageViewCoeff = getFoliageViewDistanceCoeff()
	local lodBlendStart, lodBlendEnd = getTerrainLodBlendDynamicDistances(self.terrainRootNode)

	setTerrainLodBlendDynamicDistances(self.terrainRootNode, lodBlendStart * foliageViewCoeff, lodBlendEnd * foliageViewCoeff)

	if self.foliageBendingSystem then
		self.foliageBendingSystem:setTerrainTransformGroup(self.terrainRootNode)
	end

	self.terrainDetailId = getTerrainDataPlaneByName(self.terrainRootNode, "terrainDetail")

	if self.terrainDetailId ~= 0 then
		self.terrainDetailMapSize = getDensityMapSize(self.terrainDetailId)
	end

	self.fieldGroundSystem:initTerrain(self, self.terrainRootNode, self.terrainDetailId)
	self.stoneSystem:initTerrain(self, self.terrainRootNode, self.terrainDetailId)
	self.weedSystem:initTerrain(self, self.terrainRootNode, self.terrainDetailId)
	self.vineSystem:initTerrain(self.terrainSize, self.terrainDetailMapSize)
	self.foliageSystem:initTerrain(self, self.terrainRootNode, self.terrainDetailId)

	if isMultiplayer then
		self.densityMapSyncer = DensityMapSyncer.new(self.terrainRootNode, 32)

		for _, id in pairs(self.dynamicFoliageLayers) do
			self.densityMapSyncer:addDensityMap(id)
		end

		self.fieldGroundSystem:addDensityMapSyncer(self.densityMapSyncer)
		self.stoneSystem:addDensityMapSyncer(self.densityMapSyncer)
		self.weedSystem:addDensityMapSyncer(self.densityMapSyncer)
		self.foliageSystem:addDensityMapSyncer(self.densityMapSyncer)
	end

	local fruitTypes = {}

	for _, fruitType in ipairs(g_fruitTypeManager:getFruitTypes()) do
		local isValid = false
		local id = getTerrainDataPlaneByName(self.terrainRootNode, fruitType.layerName)

		if id ~= nil and id ~= 0 then
			isValid = true
			fruitType.terrainDataPlaneId = id
			fruitType.foliageTransformGroupId = getFoliageTransformGroupIdByFoliageName(self.terrainRootNode, fruitType.layerName)
			self.fruitMapSize = math.max(self.fruitMapSize, getDensityMapSize(id))

			if self:getIsServer() and fruitType.isGrowing then
				local mapName = getDensityMapFilename(id)
				mapName = Utils.getFilenameInfo(mapName)

				self.growthSystem:setFruitLayer(mapName, fruitType, fruitType.layerName, id)
			end

			if isMultiplayer then
				self.densityMapSyncer:addDensityMap(id)
			end
		end

		if fruitType.preparingOutputName ~= nil then
			local preparingId = getTerrainDataPlaneByName(self.terrainRootNode, fruitType.preparingOutputName)

			if preparingId ~= nil and preparingId ~= 0 then
				isValid = true
				fruitType.terrainDataPlaneIdPreparing = preparingId

				if isMultiplayer then
					self.densityMapSyncer:addDensityMap(preparingId)
				end
			end
		end

		if isValid then
			table.insert(fruitTypes, fruitType)
		end
	end

	self.inGameMenu:setMissionFruitTypes(fruitTypes)
	self.growthSystem:onTerrainLoad(self.terrainRootNode)

	if self.terrainDetailId ~= 0 then
		self.fieldCropsQuery = FieldCropsQuery.new(self.terrainDetailId)
	end

	self.terrainDetailHeightId = getTerrainDataPlaneByName(self.terrainRootNode, "terrainDetailHeight")
	self.terrainDetailHeightTGId = getTerrainDetailByName(self.terrainRootNode, "terrainDetailHeight")
	self.terrainDetailHeightMapSize = self.fruitMapSize

	if self.terrainDetailHeightId ~= 0 then
		self.terrainDetailHeightMapSize = getDensityMapSize(self.terrainDetailHeightId)

		g_densityMapHeightManager:loadFromXMLFile(self.missionInfo.densityMapHeightXMLLoad)

		local generatedTipCollisionMap = getInfoLayerFromTerrain(self.terrainRootNode, "tipCollisionGenerated")
		local generatedPlacementCollisionMap = getInfoLayerFromTerrain(self.terrainRootNode, "placementCollisionGenerated")

		g_densityMapHeightManager:initialize(self:getIsServer(), generatedTipCollisionMap, generatedPlacementCollisionMap)

		local terrainHeightUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()

		if terrainHeightUpdater ~= nil and isMultiplayer then
			self.densityMapSyncer:addDensityMap(g_currentMission.terrainDetailHeightId)
		end
	end

	self.indoorMask:onTerrainLoad(self.terrainRootNode)
	self.snowSystem:onTerrainLoad(self.terrainRootNode)
	self.aiSystem:onTerrainLoad(self.terrainRootNode)
	g_groundTypeManager:initTerrain(self.terrainRootNode)
	DensityMapHeightUtil.initTerrain(self, self.terrainDetailId, self.terrainDetailHeightId)
	FieldUtil.initTerrain(self.terrainDetailId)
	g_mpLoadingScreen:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.TERRAIN)
end

function FSBaseMission:addOnCreateLoadedObject(object)
	if self.userManager:getNumberOfUsers() > 1 then
		print("Error: addOnCreateLoadedObject is only allowed during map loading when no client is connected")
		printCallstack()

		return
	end

	return FSBaseMission:superClass().addOnCreateLoadedObject(self, object)
end

function FSBaseMission:addTrainSystem(trainSystem)
	self.trainSystems[trainSystem] = trainSystem
end

function FSBaseMission:removeTrainSystem(trainSystem)
	self.trainSystems[trainSystem] = nil
end

function FSBaseMission:setTrainSystemTabbable(isTabbable)
	for trainSystem, _ in pairs(self.trainSystems) do
		trainSystem:setIsTrainTabbable(isTabbable)
	end
end

function FSBaseMission:addLimitedObject(objectType, object)
	if GS_IS_CONSOLE_VERSION then
		if self.limitedObjects[objectType].maxNumObjects > 0 then
			local numObjects = table.getn(self.limitedObjects[objectType])
			local i = 1

			while self.limitedObjects[objectType].maxNumObjects <= numObjects and i <= numObjects do
				local object_i = self.limitedObjects[i]

				if object_i:getAllowsAutoDelete() then
					table.remove(self.limitedObjects, i)
					object_i:delete()

					numObjects = numObjects - 1
				else
					i = i + 1
				end
			end
		end

		table.insert(self.limitedObjects[objectType].objects, object)
	end
end

function FSBaseMission:removeLimitedObject(objectType, object)
	if GS_IS_CONSOLE_VERSION then
		for i, object_i in pairs(self.limitedObjects[objectType].objects) do
			if object_i == object then
				table.remove(self.limitedObjects[objectType].objects, i)

				break
			end
		end
	end
end

function FSBaseMission:getCanAddLimitedObject(objectType)
	if not GS_IS_CONSOLE_VERSION then
		return true
	else
		return #self.limitedObjects[objectType].objects + 1 <= self.limitedObjects[objectType].maxNumObjects
	end
end

function FSBaseMission:mouseEvent(posX, posY, isDown, isUp, button)
	FSBaseMission:superClass().mouseEvent(self, posX, posY, isDown, isUp, button)
	self.hud:mouseEvent(posX, posY, isDown, isUp, button)
end

function FSBaseMission:updatePauseInputContext()
	local hasPauseContext = self.inputManager:getContextName() == BaseMission.INPUT_CONTEXT_PAUSE or self.inputManager:getContextName() == BaseMission.INPUT_CONTEXT_SYNCHRONIZING
	local needPause = self.gameStarted and self.paused and (not g_gui:getIsGuiVisible() or self.isSynchronizingWithPlayers)
	local needUnpause = self.gameStarted and not self.paused

	if not self.isSynchronizingWithPlayers and self.inputManager:getContextName() == BaseMission.INPUT_CONTEXT_SYNCHRONIZING then
		self.inputManager:revertContext()
	end

	if needPause and not hasPauseContext then
		g_gui:closeAllDialogs()
		self.inputManager:setContext(BaseMission.INPUT_CONTEXT_PAUSE)
	elseif needUnpause and hasPauseContext then
		self.inputManager:revertContext()
	end

	if needPause and self.isSynchronizingWithPlayers and self.inputManager:getContextName() ~= BaseMission.INPUT_CONTEXT_SYNCHRONIZING then
		self.inputManager:setContext(BaseMission.INPUT_CONTEXT_SYNCHRONIZING, true)
	end
end

function FSBaseMission:update(dt)
	FSBaseMission:superClass().update(self, dt)

	if not l_engineState and self.isRunning then
		local playTimeH = Utils.getNoNil(g_farmManager:getFarmById(self.player.farmId).stats:getTotalValue("playTime"), 0) / 60

		if playTimeH > 4 then
			l_engineStateTimer = l_engineStateTimer - dt

			if l_engineStateTimer < 0 and not g_gui:getIsGuiVisible() then
				g_gui:showInfoDialog({
					text = g_i18n:getText("dialog_getFullVersion"),
					callback = onEngineStateCallback
				})

				l_engineStateTimer = math.random(1200000, 1800000)
			end
		end
	end

	self.hud:updateMessageAndIcon(dt)
	self.hud:updateMap(dt)
	self.aiSystem:update(dt)
	self.environmentAreaSystem:update(dt)
	self.reverbSystem:update(dt)
	self.ambientSoundSystem:update(dt)
	self.vineSystem:update(dt)
	self.userManager:update(dt)
	self.snowSystem:update(dt)

	if self.economyManager ~= nil then
		self.economyManager:update(dt)
	end

	g_densityMapHeightManager:update(dt)

	if self.wildlifeSpawner ~= nil then
		self.wildlifeSpawner:update(dt)
	end

	self:updatePauseInputContext()

	if self.playtimeCountdownEnabled then
		self.playtimeReloadTimer = self.playtimeReloadTimer - dt

		if self.playtimeReloadTimer <= 0 then
			self:onReloadSavegame()
		end
	end

	if not self.isRunning and g_dedicatedServer == nil then
		if self.paused and not self.isSynchronizingWithPlayers and not g_gui:getIsGuiVisible() and GS_PLATFORM_PLAYSTATION then
			setPresenceMode(PresenceModes.PRESENCE_IDLE)

			self.presenceMode = PresenceModes.PRESENCE_IDLE
		end

		self:updateSaving()

		return
	end

	if #self.playersToAccept > 0 then
		if self.missionDynamicInfo.autoAccept then
			self:onConnectionDenyAccept(self.playersToAccept[1].connection, false, false)
		elseif self:getCanAcceptPlayers() then
			local player = self.playersToAccept[1]

			g_gui:showDenyAcceptDialog({
				callback = self.onConnectionDenyAccept,
				target = self,
				connection = player.connection,
				nickname = player.playerName,
				platformId = player.platformId,
				splitShapesWithinLimits = getIsSplitShapeConnectionWithinLimits(player.platformId)
			})
		end
	end

	g_effectManager:update(dt)
	g_animationManager:update(dt)
	self.guidedTour:update(dt)
	self.growthSystem:update(dt)

	if self:getIsServer() then
		for k, user in ipairs(self.userManager:getUsers()) do
			if k > 1 then
				local farm = g_farmManager:getFarmByUserId(user:getId())

				if user:getState() == FSBaseMission.USER_STATE_INGAME and user:getFinanceUpdateSendTime() < self.time then
					user:setFinanceUpdateSendTime(self.time + math.floor(math.random() * 300 + 5000))

					if farm.stats.financesVersionCounter ~= user:getFinancesVersionCounter() then
						user:setFinancesVersionCounter(farm.stats.financesVersionCounter)
						user:getConnection():sendEvent(FinanceStatsEvent.new(0, farm.farmId))
					end
				end
			end
		end

		if g_dedicatedServer ~= nil and self.gameStatsTime <= self.time then
			self:updateGameStatsXML()
		end

		g_treePlantManager:updateTrees(dt, dt * self:getEffectiveTimeScale())
	end

	for placeable in pairs(self.placeablesToDelete) do
		placeable:delete()

		self.placeablesToDelete[placeable] = nil
	end

	if self:getIsClient() then
		if not g_gui:getIsGuiVisible() then
			if g_soundPlayer ~= nil then
				local isRadioToggleActive = self.controlledVehicle ~= nil and self.controlledVehicle.supportsRadio or not g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY)

				self.inputManager:setActionEventActive(self.eventRadioToggle, isRadioToggleActive)
			end

			self.hud:updateVehicleName(dt)
		end

		self:updateSaving()
		self:checkRecordingDeviceState(dt)
	end

	local presenceMode = nil

	if self.missionInfo:isa(FSCareerMissionInfo) then
		if self.missionDynamicInfo.isMultiplayer then
			if self:getIsServer() then
				local activeUsers = 0

				for _, user in ipairs(self.userManager:getUsers()) do
					local connection = user:getConnection()

					if user:getState() == FSBaseMission.USER_STATE_INGAME and connection ~= nil and self.connectionsToPlayer[connection] ~= nil then
						activeUsers = activeUsers + 1
					end
				end

				if activeUsers > 1 then
					presenceMode = PresenceModes.PRESENCE_MULTIPLAYER
				else
					presenceMode = PresenceModes.PRESENCE_MULTIPLAYER_ALONE
				end
			else
				presenceMode = PresenceModes.PRESENCE_MULTIPLAYER
			end
		else
			presenceMode = PresenceModes.PRESENCE_CAREER
		end
	else
		presenceMode = PresenceModes.PRESENCE_TUTORIAL
	end

	if self.wasNetworkError and GS_PLATFORM_PLAYSTATION then
		presenceMode = PresenceModes.PRESENCE_IDLE
	end

	if (self.presenceMode == PresenceModes.PRESENCE_MULTIPLAYER or self.presenceMode == PresenceModes.PRESENCE_MULTIPLAYER_CROSSPLAY) and presenceMode ~= self.presenceMode then
		setPresenceMode(presenceMode)

		self.presenceMode = presenceMode
	elseif self.presenceMode ~= presenceMode and (not g_gui:getIsGuiVisible() or self:getIsServer()) then
		setPresenceMode(presenceMode)

		self.presenceMode = presenceMode
	end

	if GS_PLATFORM_PLAYSTATION and self.missionDynamicInfo.isMultiplayer then
		local networkError = getNetworkError()

		if networkError and not self.wasNetworkError then
			networkError = string.gsub(networkError, "Network", "dialog_network")
			self.wasNetworkError = true

			g_gui:showConnectionFailedDialog({
				text = g_i18n:getText(networkError),
				callback = g_connectionFailedDialog.onOkCallback,
				target = g_connectionFailedDialog,
				args = {
					g_gui.currentGuiName
				}
			})
		elseif not networkError and self.wasNetworkError then
			self.wasNetworkError = false
		end

		if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
			OnInGameMenuMenu()
		end
	end

	if self.isExitingGame then
		OnInGameMenuMenu()
	end

	if GS_PLATFORM_PHONE then
		self:testForGameRating()
	end

	if self.debugVehiclesToBeLoaded ~= nil then
		self:consoleCommandLoadAllVehiclesNext()
	end
end

function FSBaseMission:checkRecordingDeviceState(dt)
	if self.missionDynamicInfo.isMultiplayer and Platform.isStadia then
		self.checkRecordingDeviceTimer = self.checkRecordingDeviceTimer + dt

		if FSBaseMission.RECORDING_DEVICE_CHECK_INTERVAL <= self.checkRecordingDeviceTimer then
			self.checkRecordingDeviceTimer = 0
			local hasDevice = VoiceChatUtil.getHasRecordingDevice()

			if hasDevice ~= self.lastRecordingDeviceState then
				self.lastRecordingDeviceState = hasDevice

				if hasDevice then
					self:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("ui_microphoneDetected"))
				else
					self:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, g_i18n:getText("ui_microphoneRemoved"))
				end
			end
		end
	end
end

function FSBaseMission:testForGameRating()
	if g_gui:getIsGuiVisible() then
		return
	end

	local lifetimeStats = g_lifetimeStats
	local totalPlayTime = lifetimeStats:getTotalRuntime()
	local amountGameRateDialogShown = lifetimeStats.gameRateMessagesShown
	local show = amountGameRateDialogShown < 4 and totalPlayTime >= amountGameRateDialogShown * 3 + 1

	if show then
		lifetimeStats.gameRateMessagesShown = amountGameRateDialogShown + 1

		lifetimeStats:save()
		g_gui:showGameRateDialog()
	end
end

function FSBaseMission:updateSaving()
	if self.doSaveGameState ~= SavegameController.SAVE_STATE_NONE then
		if self.doSaveGameState == SavegameController.SAVE_STATE_VALIDATE_LIST then
			if self.savegameController:isStorageDeviceUnavailable() then
				self.doSaveGameState = SavegameController.SAVE_STATE_VALIDATE_LIST_DIALOG_WAIT

				if g_dedicatedServer == nil then
					self.inGameMenu:notifyValidateSavegameList(self.currentDeviceHasNoSpace, self.onYesNoSavegameSelectDevice, self)
				else
					Logging.error("The device no space to save the game.")
				end
			else
				self.doSaveGameState = SavegameController.SAVE_STATE_OVERWRITE_DIALOG
			end
		elseif self.doSaveGameState == SavegameController.SAVE_STATE_OVERWRITE_DIALOG then
			local metadata, _ = saveGetInfoById(self.missionInfo.savegameIndex)

			if metadata ~= "" then
				self.doSaveGameState = SavegameController.SAVE_STATE_OVERWRITE_DIALOG_WAIT

				if g_dedicatedServer == nil then
					self.inGameMenu:notifyOverwriteSavegame(self.onYesNoSavegameOverwrite, self)
				else
					self:onYesNoSavegameOverwrite(true)
				end
			else
				self.doSaveGameState = SavegameController.SAVE_STATE_NOP_WRITE
			end
		elseif self.doSaveGameState == SavegameController.SAVE_STATE_NOP_WRITE then
			self.doSaveGameState = SavegameController.SAVE_STATE_WRITE
		elseif self.doSaveGameState == SavegameController.SAVE_STATE_WRITE then
			if g_dedicatedServer == nil then
				self.inGameMenu:notifyStartSaving()
			end

			self.doSaveGameState = SavegameController.SAVE_STATE_WRITE_WAIT
			self.savingMinEndTime = getTimeSec() + SavegameController.SAVING_DURATION

			self:saveSavegame(self.doSaveGameBlocking)
		elseif self.doSaveGameState == SavegameController.SAVE_STATE_WRITE_WAIT and not self.savegameController:getIsSaving() then
			local errorCode = self.savegameController:getSavingErrorCode()

			if errorCode ~= Savegame.ERROR_OK then
				if errorCode == Savegame.ERROR_SAVE_NO_SPACE and not GS_PLATFORM_PLAYSTATION then
					self.currentDeviceHasNoSpace = true

					if g_dedicatedServer == nil then
						self.inGameMenu:notifySaveFailedNoSpace(self.onYesNoSavegameSelectDevice, self)
					end
				else
					self.doSaveGameState = SavegameController.SAVE_STATE_NONE
					self.savingMinEndTime = 0

					self.savegameController:resetStorageDeviceSelection()

					if g_dedicatedServer == nil then
						self.inGameMenu:notifySavegameNotSaved()
					end
				end
			else
				self.doSaveGameState = SavegameController.SAVE_STATE_NONE

				if g_dedicatedServer == nil then
					self.inGameMenu:notifySaveComplete()
				end
			end
		end

		return
	end
end

function FSBaseMission:onYesNoSavegameSelectDevice(yes)
	if yes then
		self.doSaveGameState = SavegameController.SAVE_STATE_VALIDATE_LIST_WAIT

		self.savegameController:resetStorageDeviceSelection()
		self.savegameController:updateSavegames()
	else
		self.doSaveGameState = SavegameController.SAVE_STATE_NONE
		self.savingMinEndTime = 0

		self.inGameMenu:notifySavegameNotSaved()
	end
end

function FSBaseMission:onSaveGameUpdateComplete(errorCode)
	if self.doSaveGameState == SavegameController.SAVE_STATE_VALIDATE_LIST_WAIT then
		if errorCode == Savegame.ERROR_OK or errorCode == Savegame.ERROR_DATA_CORRUPT then
			self.currentDeviceHasNoSpace = false
			self.doSaveGameState = SavegameController.SAVE_STATE_OVERWRITE_DIALOG
		else
			self.doSaveGameState = SavegameController.SAVE_STATE_NONE

			self.savegameController:resetStorageDeviceSelection()
			self.inGameMenu:notifySavegameNotSaved(errorCode)
		end
	end
end

function FSBaseMission:onYesNoSavegameOverwrite(yes)
	if yes then
		self.doSaveGameState = InGameMenu.SAVE_STATE_NOP_WRITE
	else
		self.doSaveGameState = InGameMenu.SAVE_STATE_NONE
		self.savingMinEndTime = 0

		self.inGameMenu:notifySavegameNotSaved()
	end
end

function FSBaseMission:getSynchronizingPercentage()
	local percentage = 0
	local numSyncPlayers = 0

	for _, syncPlayer in pairs(self.playersSynchronizing) do
		percentage = percentage + self.restPercentageFraction

		if syncPlayer.densityMapEvent ~= nil then
			percentage = percentage + syncPlayer.densityMapEvent.percentage * self.densityMapPercentageFraction
		end

		if syncPlayer.splitShapesEvent ~= nil then
			percentage = percentage + syncPlayer.splitShapesEvent.percentage * self.splitShapesPercentageFraction
		end

		numSyncPlayers = numSyncPlayers + 1
	end

	if numSyncPlayers > 0 then
		percentage = percentage / numSyncPlayers
	end

	return math.floor(percentage * 100)
end

function FSBaseMission:showPauseDisplay(enableDisplay)
	local pauseText = ""

	if enableDisplay then
		pauseText = g_i18n:getText("ui_gamePaused")

		if GS_IS_CONSOLE_VERSION and self:getIsServer() then
			if Platform.xoSwap then
				pauseText = pauseText .. " " .. g_i18n:getText("ui_continueGame_ps_xo")
			else
				pauseText = pauseText .. " " .. g_i18n:getText("ui_continueGame")
			end
		end
	end

	if self.hud ~= nil then
		self.hud:onPauseGameChange(enableDisplay, pauseText)
	end
end

function FSBaseMission:draw()
	self.indoorMask:draw()

	if self.paused then
		if self.isSynchronizingWithPlayers then
			local percentageStr = ""

			if self:getIsServer() then
				percentageStr = string.format(" %i%%", self:getSynchronizingPercentage())
			end

			local pauseText = g_i18n:getText("ui_synchronizingWithOtherPlayers") .. percentageStr

			self.hud:onPauseGameChange(nil, pauseText)
		end

		local menuVisible = g_gui:getIsGuiVisible() and not g_gui:getIsOverlayGuiVisible()

		if not menuVisible or self.isSynchronizingWithPlayers then
			self.hud:drawGamePaused(not self.isMissionStarted and not menuVisible)
		end
	end

	if self.isRunning and (not g_gui:getIsGuiVisible() or g_gui:getIsOverlayGuiVisible()) and not self.hud:getIsFading() and self.hud:getIsVisible() then
		self.hud:drawBaseHUD()
		self.hud:drawVehicleName()
	end

	FSBaseMission:superClass().draw(self)

	if not self.hud:getIsFading() then
		self.hud:drawInGameMessageAndIcon()
	end

	if g_isPresentationVersionPlaytimeCountdown ~= nil then
		local text = string.format("%0.1d:%0.2d", self.playtimeReloadTimer / 60000, self.playtimeReloadTimer / 1000 % 60)

		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(0.5, g_gui:getIsGuiVisible() and 0.85 or 0.932, 0.05, text)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
	end
end

function FSBaseMission:addMoneyChange(amount, farmId, moneyType, forceShow)
	if self:getIsServer() then
		if self.moneyChanges[moneyType.id] == nil then
			self.moneyChanges[moneyType.id] = {}
		end

		local changes = self.moneyChanges[moneyType.id]

		if changes[farmId] == nil then
			changes[farmId] = 0
		end

		changes[farmId] = changes[farmId] + amount

		if self:getFarmId() == farmId then
			self.hud:addMoneyChange(moneyType, amount)
		end

		if forceShow then
			self:broadcastNotifications(moneyType, farmId)
		end
	else
		Logging.error("addMoneyChange() called on client")
		printCallstack()
	end
end

function FSBaseMission:showMoneyChange(moneyType, text, allFarms, farmId)
	if self:getIsServer() then
		if allFarms then
			for _, farm in ipairs(g_farmManager:getFarms()) do
				self:broadcastNotifications(moneyType, farm.farmId, text)
			end
		else
			self:broadcastNotifications(moneyType, farmId or g_currentMission:getFarmId(), text)
		end
	else
		g_client:getServerConnection():sendEvent(RequestMoneyChangeEvent.new(moneyType))
	end
end

function FSBaseMission:broadcastNotifications(moneyType, farmId, text)
	if moneyType == nil then
		printCallstack()
	end

	local farms = g_currentMission.moneyChanges[moneyType.id]

	if farms then
		local amount = farms[farmId]

		if amount then
			g_currentMission:broadcastEventToFarm(MoneyChangeEvent.new(amount, moneyType, farmId, text), farmId, false)

			if farmId == g_currentMission:getFarmId() then
				if text ~= nil then
					text = g_i18n:getText(text)
				end

				g_currentMission.hud:showMoneyChange(moneyType, text)
			end

			farms[farmId] = nil
		end
	end
end

function FSBaseMission:showAttachContext(attachableVehicle)
	self.hud:showAttachContext(self:getVehicleName(attachableVehicle))
end

function FSBaseMission:showTipContext(fillTypeIndex)
	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)

	self.hud:showTipContext(fillType.title)
end

function FSBaseMission:showFuelContext(fuelingVehicle)
	self.hud:showFuelContext(self:getVehicleName(fuelingVehicle))
end

function FSBaseMission:showFillDogBowlContext(dogName)
	self.hud:showFillDogBowlContext(dogName)
end

function FSBaseMission:addIngameNotification(notificationType, text)
	self.hud:addSideNotification(notificationType, text)
end

function FSBaseMission:getIsAutoSaveSupported()
	return not g_isPresentationVersion and not g_isPresentationVersionUseReloadButton
end

function FSBaseMission:doPauseGame()
	FSBaseMission:superClass().doPauseGame(self)
	self.inGameMenu:setIsGamePaused(true)
	self.shopMenu:setIsGamePaused(true)

	if self.growthSystem ~= nil then
		self.growthSystem:setIsGamePaused(true)
	end
end

function FSBaseMission:canUnpauseGame()
	return FSBaseMission:superClass().canUnpauseGame(self) and not self.isSynchronizingWithPlayers and not self.dediEmptyPaused and not self.userSigninPaused
end

function FSBaseMission:doUnpauseGame()
	FSBaseMission:superClass().doUnpauseGame(self)
	self.inGameMenu:setIsGamePaused(false)
	self.shopMenu:setIsGamePaused(false)
	self.growthSystem:setIsGamePaused(false)

	if g_dedicatedServer ~= nil then
		g_dedicatedServer:raiseFramerate()
	end
end

function FSBaseMission:getCanAcceptPlayers()
	return not g_gui:getIsDialogVisible()
end

function FSBaseMission:drawMissionCompleted()
	self.hud:drawMissionCompleted()
end

function FSBaseMission:drawMissionFailed()
	self.hud:drawMissionFailed()
end

function FSBaseMission:onEndMissionCallback()
	if self.state == BaseMission.STATE_FINISHED or self.state == BaseMission.STATE_FAILED then
		self.isExitingGame = true
	end
end

function FSBaseMission:setMissionInfo(missionInfo, missionDynamicInfo)
	resetSplitShapes()
	setUseKinematicSplitShapes(not self:getIsServer())

	if missionInfo.isValid then
		local flags = TerrainLoadFlags.TEXTURE_CACHE + TerrainLoadFlags.NORMAL_MAP_CACHE + TerrainLoadFlags.OCCLUDER_CACHE

		if missionInfo:getIsDensityMapValid(self) then
			flags = flags + TerrainLoadFlags.DENSITY_MAPS_USE_LOAD_DIR
		else
			Logging.warning("density map is not valid, ignoring density map from savegame")
		end

		if not GS_IS_MOBILE_VERSION then
			flags = flags + TerrainLoadFlags.HEIGHT_MAP_USE_LOAD_DIR + TerrainLoadFlags.NORMAL_MAP_CACHE_USE_LOAD_DIR + TerrainLoadFlags.OCCLUDER_CACHE_USE_LOAD_DIR

			if missionInfo:getIsTerrainLodTextureValid(self) then
				flags = flags + TerrainLoadFlags.TEXTURE_CACHE_USE_LOAD_DIR

				if missionInfo:getIsTerrainLodTextureValid(self) and g_densityMapHeightManager ~= nil and g_densityMapHeightManager:checkTypeMappings() then
					flags = flags + TerrainLoadFlags.LOD_TEXTURE_CACHE
				end
			end
		end

		setTerrainLoadDirectory(missionInfo.savegameDirectory, flags)
	else
		setTerrainLoadDirectory("", TerrainLoadFlags.GAME_DEFAULT)
	end

	if missionInfo:getAreSplitShapesValid(self) then
		loadSplitShapesFromFile(missionInfo.savegameDirectory .. "/splitShapes.gmss")
	elseif missionInfo.isValid then
		Logging.warning("splitshapes are not valid, ignoring splitshapes from savegame")
	end

	FSBaseMission:superClass().setMissionInfo(self, missionInfo, missionDynamicInfo)

	if g_soundPlayer ~= nil then
		g_soundPlayer:addEventListener(self)

		if not GS_IS_CONSOLE_VERSION and not GS_IS_MOBILE_VERSION then
			g_soundPlayer:setStreamingAccessOwner(self)
		end
	end

	self:updateMaxNumHirables()
	self.hud:setIngameMapSize(g_gameSettings:getValue("ingameMapState"))
end

function FSBaseMission:updateMaxNumHirables()
	if self.missionDynamicInfo.isMultiplayer then
		if self.missionDynamicInfo.capacity ~= nil then
			self.maxNumHirables = math.max(4, math.min(self.missionDynamicInfo.capacity, g_helperManager:getNumOfHelpers()))
		end
	elseif GS_IS_CONSOLE_VERSION then
		self.maxNumHirables = math.min(6, g_helperManager:getNumOfHelpers())
	elseif GS_IS_MOBILE_VERSION then
		self.maxNumHirables = math.min(4, g_helperManager:getNumOfHelpers())
	else
		self.maxNumHirables = g_helperManager:getNumOfHelpers()
	end
end

function FSBaseMission:addLiquidManureLoadingStation(loadingStation)
	local success = table.addElement(self.liquidManureLoadingStations, loadingStation)

	if not success then
		print("Error: Liquid manure loading station already added")
	end
end

function FSBaseMission:removeLiquidManureLoadingStation(loadingStation)
	table.removeElement(self.liquidManureLoadingStations, loadingStation)
end

function FSBaseMission:addManureLoadingStation(loadingStation)
	local success = table.addElement(self.manureLoadingStations, loadingStation)

	if not success then
		print("Error: Manure loading station already added")
	end
end

function FSBaseMission:removeManureLoadingStation(loadingStation)
	table.removeElement(self.manureLoadingStations, loadingStation)
end

function FSBaseMission:addMoney(amount, farmId, moneyType, addChange, forceShowChange)
	if self:getIsServer() then
		if farmId == 0 then
			print("Error: Can't change money of spectator farm")
			printCallstack()

			return
		end

		local farm = g_farmManager:getFarmById(farmId)

		if farm == nil then
			return
		end

		farm:changeBalance(amount, moneyType)

		if addChange then
			self:addMoneyChange(amount, farmId, moneyType, forceShowChange)
		end
	else
		print("Error: FSBaseMission:addMoney is only allowed on a server")
		printCallstack()
	end
end

function FSBaseMission:addPurchasedMoney(amount)
	if self:getIsServer() then
		local farm = g_farmManager:getFarmById(FarmManager.SINGLEPLAYER_FARM_ID)

		if farm == nil then
			return
		end

		farm:addPurchasedCoins(amount)
	else
		print("Error: FSBaseMission:addPurchasedMoney is only allowed on a server")
		printCallstack()
	end
end

function FSBaseMission:getMoney(farmId)
	if farmId == nil then
		farmId = self.player == nil and FarmManager.SINGLEPLAYER_FARM_ID or self.player.farmId
	end

	local farm = g_farmManager:getFarmById(farmId)

	if farm == nil then
		return 0
	end

	self.cacheFarm = farm

	return farm.money
end

function FSBaseMission:setPlayerPermission(userId, permission, allow)
	if self:getIsServer() then
		local farm = g_farmManager:getFarmByUserId(userId)
		local player = farm.userIdToPlayer[userId]
		player.permissions[permission] = allow
	end
end

function FSBaseMission:setPlayerPermissions(userId, permissions)
	if self:getIsServer() then
		local farm = g_farmManager:getFarmByUserId(userId)
		local player = farm.userIdToPlayer[userId]

		for _, permission in ipairs(Farm.PERMISSIONS) do
			if permissions[permission] ~= nil then
				player.permissions[permission] = permissions[permission]
			end
		end
	end
end

function FSBaseMission:getHasPlayerPermission(permission, connection, farmId, checkClient)
	if checkClient == nil or not checkClient then
		if self:getIsServer() then
			if connection == nil or connection:getIsLocal() or connection:getIsServer() or self.userManager:getIsConnectionMasterUser(connection) then
				return true
			end
		elseif self.isMasterUser then
			return true
		end

		if connection ~= nil and connection:getIsServer() then
			return true
		end
	end

	local user = nil

	if connection ~= nil then
		user = self.userManager:getUserByConnection(connection)
	else
		user = self.userManager:getUserByUserId(self.playerUserId)
	end

	local farm = g_farmManager:getFarmByUserId(user:getId())
	local player = farm.userIdToPlayer[user:getId()]

	if farmId ~= nil and farm.farmId ~= farmId then
		return false
	end

	if player == nil then
		return false
	end

	return player.isFarmManager or Utils.getNoNil(player.permissions[permission], false)
end

function FSBaseMission:getTerrainDetailPixelsToSqm()
	local f = self.terrainSize / self.terrainDetailMapSize

	return f * f
end

function FSBaseMission:getFruitPixelsToSqm()
	local f = self.terrainSize / self.fruitMapSize

	return f * f
end

function FSBaseMission:getIngameMap()
	return self.hud:getIngameMap()
end

function FSBaseMission:sendNumPlayersToMasterServer(numPlayers)
	if self.missionDynamicInfo.isMultiplayer then
		if g_dedicatedServer ~= nil then
			numPlayers = numPlayers - 1
		end

		masterServerSetServerNumPlayers(numPlayers)
	end
end

function FSBaseMission:sendPlatformSessionIdsToMasterServer(platformSessionIds)
	if self.missionDynamicInfo.isMultiplayer then
		masterServerSetServerPlatformSessionIds(platformSessionIds)
	end
end

function FSBaseMission:setTimeScale(timeScale, noEventSend)
	if timeScale ~= self.missionInfo.timeScale then
		self.missionInfo.timeScale = timeScale

		g_messageCenter:publish(MessageType.TIMESCALE_CHANGED)
		SavegameSettingsEvent.sendEvent(noEventSend)

		if g_server ~= nil then
			EnvironmentTimeEvent.broadcastEvent()
		end
	end
end

function FSBaseMission:setTimeScaleMultiplier(timeScaleMultiplier)
	if timeScaleMultiplier ~= self.missionInfo.timeScaleMultiplier then
		self.missionInfo.timeScaleMultiplier = timeScaleMultiplier

		g_messageCenter:publish(MessageType.TIMESCALE_CHANGED)
	end
end

function FSBaseMission:getEffectiveTimeScale()
	return self.missionInfo:getEffectiveTimeScale()
end

function FSBaseMission:setEconomicDifficulty(economicDifficulty, noEventSend)
	if economicDifficulty ~= self.missionInfo.economicDifficulty then
		self.missionInfo.economicDifficulty = economicDifficulty

		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting 'economicDifficulty': %s", economicDifficulty)
	end
end

function FSBaseMission:setSnowEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.isSnowEnabled then
		self.missionInfo.isSnowEnabled = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)

		if not isEnabled then
			self.snowSystem:removeAll()
		end

		Logging.info("Savegame Setting 'snowEnabled': %s", isEnabled)
	end
end

function FSBaseMission:setSavegameName(name, noEventSend)
	if name ~= self.missionInfo.savegameName then
		self.missionInfo.savegameName = name

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:startSaveCurrentGame(hiddenUI, blocking)
	self.currentDeviceHasNoSpace = false

	if g_dedicatedServer ~= nil then
		self:saveSavegame(blocking)
	else
		self.doSaveGameState = InGameMenu.SAVE_STATE_WRITE
		self.doSaveGameBlocking = blocking

		self.inGameMenu:startSavingGameDisplay()
	end

	g_gameSettings:saveToXMLFile(g_savegameXML)
end

function FSBaseMission:saveSavegame(blocking)
	if not g_sleepManager:getIsSleeping() then
		if GS_IS_CONSOLE_VERSION or GS_IS_MOBILE_VERSION then
			self.isSaving = true

			self:pauseGame()
		end

		self.savegameController:saveSavegame(self.missionInfo, blocking)
	end
end

function FSBaseMission:setGrowthMode(mode, noEventSend)
	self.growthSystem:setGrowthMode(mode, noEventSend)
	self.inGameMenu:onGrowthModeChanged()
end

function FSBaseMission:setFixedSeasonalVisuals(period, noEventSend)
	if period ~= self.missionInfo.fixedSeasonalVisuals then
		self.environment:setFixedPeriod(period)
		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting 'fixedSeasonalVisuals': %s", period)
	end
end

function FSBaseMission:setPlannedDaysPerPeriod(days, noEventSend)
	days = MathUtil.clamp(days, 1, Environment.MAX_DAYS_PER_PERIOD)

	if days ~= self.missionInfo.plannedDaysPerPeriod then
		self.environment:setPlannedDaysPerPeriod(days)
		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting 'plannedDaysPerPeriod': %s", days)
	end
end

function FSBaseMission:setFruitDestructionEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.fruitDestruction then
		self.missionInfo.fruitDestruction = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting 'fruitDesctructionEnabled': %s", isEnabled)
	end
end

function FSBaseMission:setPlowingRequiredEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.plowingRequiredEnabled then
		self.missionInfo.plowingRequiredEnabled = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting 'plowingRequiredEnabled': %s", isEnabled)
	end
end

function FSBaseMission:setStonesEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.stonesEnabled then
		self.missionInfo.stonesEnabled = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting 'stonesEnabled': %s", isEnabled)
	end
end

function FSBaseMission:setLimeRequired(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.limeRequired then
		self.missionInfo.limeRequired = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting 'limeRequired': %s", isEnabled)
	end
end

function FSBaseMission:setWeedsEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.weedsEnabled then
		self.missionInfo.weedsEnabled = isEnabled

		self.growthSystem:onWeedGrowthChanged()
		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting 'weedsEnabled': %s", isEnabled)
	end
end

function FSBaseMission:setStopAndGoBraking(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.stopAndGoBraking then
		self.missionInfo.stopAndGoBraking = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setTrailerFillLimit(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.trailerFillLimit then
		self.missionInfo.trailerFillLimit = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setAutoSaveInterval(interval, noEventSend)
	if interval ~= g_autoSaveManager:getInterval() then
		g_autoSaveManager:setInterval(interval)
		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setTrafficEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.trafficEnabled then
		self.missionInfo.trafficEnabled = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)

		if self.trafficSystem ~= nil then
			self.trafficSystem:setEnabled(self.missionInfo.trafficEnabled)

			if not self.missionInfo.trafficEnabled then
				self.trafficSystem:reset()
			end
		end
	end
end

function FSBaseMission:setDirtInterval(dirtInterval, noEventSend)
	if dirtInterval ~= self.missionInfo.dirtInterval then
		self.missionInfo.dirtInterval = dirtInterval

		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting 'dirtInterval': %d", dirtInterval)
	end
end

function FSBaseMission:setFuelUsageLow(fuelUsageLow, noEventSend)
	if fuelUsageLow ~= self.missionInfo.fuelUsageLow then
		self.missionInfo.fuelUsageLow = fuelUsageLow

		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting 'fuelUsageLow': %s", fuelUsageLow)
	end
end

function FSBaseMission:setHelperBuyFuel(helperBuyFuel, noEventSend)
	if helperBuyFuel ~= self.missionInfo.helperBuyFuel then
		self.missionInfo.helperBuyFuel = helperBuyFuel

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setHelperBuySeeds(helperBuySeeds, noEventSend)
	if helperBuySeeds ~= self.missionInfo.helperBuySeeds then
		self.missionInfo.helperBuySeeds = helperBuySeeds

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setHelperBuyFertilizer(helperBuyFertilizer, noEventSend)
	if helperBuyFertilizer ~= self.missionInfo.helperBuyFertilizer then
		self.missionInfo.helperBuyFertilizer = helperBuyFertilizer

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setHelperSlurrySource(helperSlurrySource, noEventSend)
	if helperSlurrySource ~= self.missionInfo.helperSlurrySource then
		self.missionInfo.helperSlurrySource = helperSlurrySource

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setHelperManureSource(helperManureSource, noEventSend)
	if helperManureSource ~= self.missionInfo.helperManureSource then
		self.missionInfo.helperManureSource = helperManureSource

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:setAutomaticMotorStartEnabled(isEnabled, noEventSend)
	if isEnabled ~= self.missionInfo.automaticMotorStartEnabled then
		self.missionInfo.automaticMotorStartEnabled = isEnabled

		SavegameSettingsEvent.sendEvent(noEventSend)
	end
end

function FSBaseMission:addKnownSplitShape(shape)
end

function FSBaseMission:removeKnownSplitShape(shape)
end

function FSBaseMission:getDoghouse(farmId)
	for _, doghouse in pairs(self.doghouses) do
		if doghouse:getOwnerFarmId() == farmId then
			return doghouse
		end
	end

	return nil
end

function FSBaseMission:onDayChanged()
end

function FSBaseMission:onHourChanged()
	if self:getIsServer() then
		self:showMoneyChange(MoneyType.AI, nil, true)
	end
end

function FSBaseMission:onMinuteChanged()
end

function FSBaseMission:onLeaveVehicle(playerTargetPosX, playerTargetPosY, playerTargetPosZ, isAbsolute, isRootNode)
	FSBaseMission:superClass().onLeaveVehicle(self, playerTargetPosX, playerTargetPosY, playerTargetPosZ, isAbsolute, isRootNode)

	if g_gameSettings:getValue("radioVehicleOnly") then
		self:pauseRadio()
	end
end

function FSBaseMission:pauseRadio()
	if g_soundPlayer ~= nil then
		self:setRadioActionEventsState(false)

		if self.hud ~= nil then
			self.hud:hideTopNotification()
		end

		g_soundPlayer:pause()
	end
end

function FSBaseMission:playRadio()
	if g_soundPlayer ~= nil and g_gameSettings:getValue(GameSettings.SETTING.RADIO_IS_ACTIVE) then
		local hasStartedPlaying = g_soundPlayer:play()

		self:setRadioActionEventsState(hasStartedPlaying)
	end
end

function FSBaseMission:getIsRadioPlaying()
	if g_soundPlayer ~= nil then
		return g_soundPlayer:getIsPlaying()
	end

	return false
end

function FSBaseMission:onSoundPlayerChange(channelName, itemName, isOnlineStream, iconFilename)
	if not GS_IS_MOBILE_VERSION then
		local rating = ""
		local iconKey = TopNotification.ICON.RADIO

		if isOnlineStream then
			rating = g_i18n:getText("ui_radioRating")
		end

		self:addGameNotification(string.upper(channelName), string.upper(itemName), rating, iconKey, 4000, self.radioNotification, iconFilename)
	end

	g_messageCenter:publish(MessageType.RADIO_CHANNEL_CHANGE, channelName, itemName, isOnlineStream)
end

function FSBaseMission:onSoundPlayerStreamAccess()
	if g_gameSettings:getValue("isSoundPlayerStreamAccessAllowed") then
		self:onStreamAccessAllowed(true)
	else
		g_gui:showYesNoDialog({
			text = g_i18n:getText("ui_radioRating") .. "\n\n" .. g_i18n:getText("ui_continueQuestion"),
			callback = self.onStreamAccessAllowed,
			target = self
		})
	end
end

function FSBaseMission:onStreamAccessAllowed(yes)
	if g_soundPlayer ~= nil then
		if yes then
			g_gameSettings:setValue("isSoundPlayerStreamAccessAllowed", true, true)
		end

		g_soundPlayer:setStreamAccessAllowed(yes)
	end
end

function FSBaseMission:setRadioVolume(volume)
	g_gameSettings:setValue(GameSettings.SETTING.VOLUME_RADIO, MathUtil.clamp(volume, 0, 1))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.RADIO, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_RADIO))
end

function FSBaseMission:setVehicleVolume(volume)
	g_gameSettings:setValue(GameSettings.SETTING.VOLUME_VEHICLE, MathUtil.clamp(volume, 0, 1))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.VEHICLE, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_VEHICLE))
end

function FSBaseMission:setEnvironmentVolume(volume)
	g_gameSettings:setValue(GameSettings.SETTING.VOLUME_ENVIRONMENT, MathUtil.clamp(volume, 0, 1))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.ENVIRONMENT, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_ENVIRONMENT))

	if GS_IS_MOBILE_VERSION then
		g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.DEFAULT, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_ENVIRONMENT))
	end
end

function FSBaseMission:setGUIVolume(volume)
	g_gameSettings:setValue(GameSettings.SETTING.VOLUME_GUI, MathUtil.clamp(volume, 0, 1))
	g_soundMixer:setAudioGroupVolumeFactor(AudioGroup.GUI, g_gameSettings:getValue(GameSettings.SETTING.VOLUME_GUI))
end

function FSBaseMission:getVehicleName(vehicle)
	local name = vehicle:getFullName()
	name = utf8ToUpper(name)

	return name
end

function FSBaseMission:onEnterVehicle(vehicle, playerStyle, farmId)
	FSBaseMission:superClass().onEnterVehicle(self, vehicle, playerStyle, farmId)

	if g_soundPlayer ~= nil then
		if not self:getIsRadioPlaying() then
			if vehicle.supportsRadio then
				self:playRadio()
			end
		elseif not vehicle.supportsRadio and g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY) then
			self:pauseRadio()
		end
	end

	self.currentVehicleName = self:getVehicleName(vehicle)

	self.hud:showVehicleName(self.currentVehicleName)
end

function FSBaseMission:setMoneyUnit(unit)
	FSBaseMission:superClass().setMoneyUnit(self, unit)
	self.hud:setMoneyUnit(unit)
end

function FSBaseMission:consoleCommandCheatMoney(amount)
	amount = tonumber(Utils.getNoNil(amount, 10000000))
	local farmId = self.player.farmId

	if self:getIsServer() or self.isMasterUser then
		if self:getIsServer() then
			self:addMoney(amount, farmId, MoneyType.OTHER, true, true)
		else
			g_client:getServerConnection():sendEvent(CheatMoneyEvent.new(amount, farmId))
		end

		return string.format("Added money %d. Use 'gsMoneyAdd <amount>' to add or remove a custom amount", amount)
	end
end

function FSBaseMission:consoleCommandExportStoreItems()
	local csvFile = getUserProfileAppPath() .. "storeItems.csv"
	local specTypes = g_storeManager:getSpecTypes()
	local file = io.open(csvFile, "w")

	if file ~= nil then
		local header = "xmlFilename;category;brand;name;price;lifetime;dailyUpkeep;showInStore;"

		for _, spec in pairs(specTypes) do
			header = header .. spec.name .. ";"
		end

		file:write(header .. "\n")

		local storeItems = g_storeManager:getItems()

		for _, storeItem in pairs(storeItems) do
			local brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)
			local data = string.format("%s;%s;%s;%s;%s;%s;%s;%s;", storeItem.xmlFilename, storeItem.categoryName, brand.name, storeItem.name, storeItem.price, storeItem.lifetime, storeItem.dailyUpkeep, storeItem.showInStore)

			StoreItemUtil.loadSpecsFromXML(storeItem)

			for _, spec in pairs(specTypes) do
				local value = nil

				if spec.species == storeItem.species then
					value = spec.getValueFunc(storeItem, nil)
				end

				if value == nil or type(value) == "table" then
					value = ""
				end

				data = data .. tostring(value):trim() .. ";"
			end

			file:write(data .. "\n")
		end

		printf("Exported %i store items to '%s'", #storeItems, csvFile)
		file:close()
	else
		printf("Error: Unable to create csv file '%s'", csvFile)
	end
end

function FSBaseMission:consoleStartGreatDemand()
	for _, greatDemand in pairs(self.economyManager.greatDemands) do
		self.economyManager:stopGreatDemand(greatDemand)
	end

	for _, greatDemand in pairs(self.economyManager.greatDemands) do
		greatDemand:setUpRandomDemand(true, self.economyManager.greatDemands, self)

		greatDemand.demandStart.day = g_currentMission.environment.currentDay
		greatDemand.demandStart.hour = g_currentMission.environment.currentHour + 1
	end

	return "Great demand starts in the next hour..."
end

function FSBaseMission:consoleCommandReloadVehicle(resetVehicle, radius)
	local usage = "Usage: gsVehicleReload [resetVehicle] [radius]"

	if g_gui.currentGuiName == "ShopMenu" or g_gui.currentGuiName == "ShopConfigScreen" then
		return "Error: Reload not supported while in shop!"
	end

	if self:getIsServer() and not self.missionDynamicInfo.isMultiplayer then
		self.isReloadingVehicles = true

		if self.controlledVehicle ~= nil or self.controlPlayer then
			resetVehicle = Utils.stringToBoolean(resetVehicle)
			radius = tonumber(radius) or 0
			local posX = 0
			local posY = 0
			local posZ = 0

			if self.controlledVehicle ~= nil then
				posX, posY, posZ = getWorldTranslation(self.controlledVehicle.rootNode)
			elseif self.controlPlayer then
				posX, posY, posZ = getWorldTranslation(self.player.rootNode)
			end

			g_soundManager:reloadSoundTemplates()

			local affectedVehicles = {}
			local usedVehicles = {}
			local usedModNames = {}

			local function addVehicle(v, list)
				if v.isVehicleSaved then
					v:removeFromPhysics()

					v.isReconfigurating = true

					table.insert(list, v)

					usedVehicles[v] = true

					if v ~= nil and v.getAttachedImplements ~= nil then
						local attachedImplements = v:getAttachedImplements()

						for _, implement in pairs(attachedImplements) do
							addVehicle(implement.object, list)
						end
					end
				else
					self:removeVehicle(v)
				end
			end

			if self.controlledVehicle ~= nil then
				addVehicle(self.controlledVehicle, affectedVehicles)
			end

			if radius ~= 0 then
				for _, v in pairs(self.vehicles) do
					if v ~= self.controlledVehicle then
						local vx, vy, vz = getWorldTranslation(v.rootNode)

						if MathUtil.vector3Length(vx - posX, vy - posY, vz - posZ) < radius and usedVehicles[v.rootVehicle] == nil then
							addVehicle(v.rootVehicle, affectedVehicles)
						end
					end
				end
			end

			if #affectedVehicles == 0 then
				return "Warning: No vehicle reloaded. Enter a vehicle first or use the command with the radius parameter given, e.g. 'gsVehicleReload false 25'\n" .. usage
			end

			local xmlFile = XMLFile.create("vehicleXMLFile", "", "vehicles", Vehicle.xmlSchemaSavegame)

			VehicleLoadingUtil.setSaveIds(affectedVehicles)

			local savedVehiclesToId = VehicleLoadingUtil.saveVehiclesToSavegameXML(xmlFile, "vehicles", affectedVehicles, usedModNames)
			local steerableId = savedVehiclesToId[self.controlledVehicle]

			g_i3DManager:clearEntireSharedI3DFileCache(false)

			local loadedVehicles = {}
			local numLoadedVehicles = 0
			local success = true

			local function asyncCallbackFunction(_, newVehicle, vehicleLoadState, arguments)
				if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_OK then
					loadedVehicles[newVehicle.currentSavegameId] = newVehicle
				else
					success = false
				end

				numLoadedVehicles = numLoadedVehicles + 1

				if numLoadedVehicles == #affectedVehicles then
					if success then
						for _, affected_vehicle in pairs(affectedVehicles) do
							self:removeVehicle(affected_vehicle)
						end

						local loadedAttachmentVehicles = {}
						local n = 0

						while true do
							local key = string.format("vehicles.attachments(%d)", n)

							if not xmlFile:hasProperty(key) then
								break
							end

							local id = xmlFile:getValue(key .. "#rootVehicleId")

							if id ~= nil then
								local loadedVehicle = loadedVehicles[id]

								if loadedVehicle ~= nil then
									loadedVehicle:loadAttachmentsFromXMLFile(xmlFile, key, loadedVehicles)

									loadedAttachmentVehicles[loadedVehicle] = true
								end
							end

							n = n + 1
						end

						for v, _ in pairs(loadedAttachmentVehicles) do
							v:loadAttachmentsFinished()
						end

						if steerableId ~= nil then
							local steerableVehicle = loadedVehicles[steerableId]

							if steerableVehicle ~= nil then
								self:requestToEnterVehicle(steerableVehicle)
							end
						end
					else
						for _, loadedVehicle in pairs(loadedVehicles) do
							self:removeVehicle(loadedVehicle)
						end

						for _, vehicle in ipairs(affectedVehicles) do
							vehicle:addToPhysics()
						end
					end

					xmlFile:delete()

					self.isReloadingVehicles = false

					return string.format("%d vehicle(s) reloaded", #affectedVehicles)
				end
			end

			local i = 1

			while true do
				local key = string.format("vehicles.vehicle(%d)", i - 1)

				if not xmlFile:hasProperty(key) then
					break
				end

				VehicleLoadingUtil.loadVehicleFromSavegameXML(xmlFile, key, resetVehicle, true, nil, resetVehicle, asyncCallbackFunction, nil, {})

				i = i + 1
			end
		end
	end
end

function FSBaseMission:consoleCommandLoadTree(length, treeType, growthState)
	length = tonumber(length)
	local usage = "gsTreeAdd length [type (available: " .. table.concatKeys(g_treePlantManager.nameToTreeType, " ") .. ")] [growthState]"

	if length == nil then
		return "No length given. " .. usage
	end

	if treeType == nil then
		treeType = "SPRUCE1"
	end

	local treeTypeDesc = g_treePlantManager:getTreeTypeDescFromName(treeType)

	if treeTypeDesc == nil then
		return "Invalid tree type. " .. usage
	end

	growthState = Utils.getNoNil(growthState, table.getn(treeTypeDesc.treeFilenames))
	local x = 0
	local y = 0
	local z = 0
	local dirX = 1
	local dirY = 0
	local dirZ = 0

	if self.controlPlayer then
		if self.player ~= nil and self.player.isControlled and self.player.rootNode ~= nil and self.player.rootNode ~= 0 then
			x, y, z = getWorldTranslation(self.player.rootNode)
			dirZ = -math.cos(self.player.rotY)
			dirY = 0
			dirX = -math.sin(self.player.rotY)
		end
	elseif self.controlledVehicle ~= nil then
		x, y, z = getWorldTranslation(self.controlledVehicle.rootNode)
		dirX, dirY, dirZ = localDirectionToWorld(self.controlledVehicle.rootNode, 0, 0, 1)
	end

	z = z + dirZ * 4
	x = x + dirX * 4
	y = y + 1

	g_treePlantManager:loadTreeTrunk(treeTypeDesc, x, y, z, dirX, dirY, dirZ, length, growthState)
end

function FSBaseMission:consoleCommandTeleport(fieldIdOrX, zPos)
	local usage = "gsTeleport xPos|field [zPos] (if zPos is not given first parameter is used as field id)"
	fieldIdOrX = tonumber(fieldIdOrX)
	zPos = tonumber(zPos)

	if fieldIdOrX == nil then
		return "Invalid field or x-position. " .. usage
	end

	local targetX, targetZ = nil

	if zPos == nil then
		local field = g_fieldManager:getFieldByIndex(fieldIdOrX)

		if field ~= nil then
			targetZ = field.posZ
			targetX = field.posX
		else
			return "Invalid field id. " .. usage
		end
	else
		local worldSizeX = self.terrainSize
		local worldSizeZ = self.terrainSize
		targetX = MathUtil.clamp(fieldIdOrX, 0, worldSizeX) - worldSizeX * 0.5
		targetZ = MathUtil.clamp(zPos, 0, worldSizeZ) - worldSizeZ * 0.5
	end

	if self.controlledVehicle == nil then
		self.player:moveTo(targetX, 0.5, targetZ, false, false)
	else
		local vehicleCombos = {}
		local vehicles = {}

		local function addVehiclePositions(vehicle)
			local x, y, z = getWorldTranslation(vehicle.rootNode)

			table.insert(vehicles, {
				vehicle = vehicle,
				offset = {
					worldToLocal(self.controlledVehicle.rootNode, x, y, z)
				}
			})

			if vehicle.getAttachedImplements ~= nil then
				for _, impl in pairs(vehicle:getAttachedImplements()) do
					addVehiclePositions(impl.object)
					table.insert(vehicleCombos, {
						vehicle = vehicle,
						object = impl.object,
						jointDescIndex = impl.jointDescIndex,
						inputAttacherJointDescIndex = impl.object:getActiveInputAttacherJointDescIndex()
					})
				end

				for _ = table.getn(vehicle:getAttachedImplements()), 1, -1 do
					vehicle:detachImplement(1, true)
				end
			end

			vehicle:removeFromPhysics()
		end

		addVehiclePositions(self.controlledVehicle)

		for k, data in pairs(vehicles) do
			local x = targetX
			local z = targetZ
			local _ = nil

			if k > 1 then
				x, _, z = localToWorld(self.controlledVehicle.rootNode, unpack(data.offset))
			end

			local _, ry, _ = getWorldRotation(data.vehicle.rootNode)

			data.vehicle:setRelativePosition(x, 0.5, z, ry, true)
			data.vehicle:addToPhysics()
		end

		for _, combo in pairs(vehicleCombos) do
			combo.vehicle:attachImplement(combo.object, combo.inputAttacherJointDescIndex, combo.jointDescIndex, true, nil, , false)
		end
	end
end

function FSBaseMission:consoleCommandAddDirtAmount(amount)
	if self:getIsServer() then
		amount = Utils.getNoNil(tonumber(amount), 0)

		if self.controlledVehicle ~= nil then
			for _, v in pairs(self.vehicles) do
				if v:getIsActive() and v.addDirtAmount ~= nil then
					v:addDirtAmount(amount)
				end
			end
		else
			return "Enter a vehicle first!"
		end
	end
end

function FSBaseMission:consoleCommandAddWearAmount(amount)
	if self:getIsServer() then
		amount = Utils.getNoNil(tonumber(amount), 0)

		if self.controlledVehicle ~= nil then
			for _, v in pairs(self.vehicles) do
				if v:getIsActive() and v.addWearAmount ~= nil then
					v:addWearAmount(amount)
				end
			end
		else
			return "Enter a vehicle first!"
		end
	end
end

function FSBaseMission:consoleCommandAddDamageAmount(amount)
	if self:getIsServer() then
		amount = Utils.getNoNil(tonumber(amount), 0)

		if self.controlledVehicle ~= nil then
			for _, v in pairs(self.vehicles) do
				if v:getIsActive() and v.addDamageAmount ~= nil then
					v:addDamageAmount(amount)
				end
			end
		else
			return "Enter a vehicle first!"
		end
	end
end

function FSBaseMission:consoleCommandLoadAllVehicles(loadConfigs, modsOnly, palletsOnly, verbose)
	if not self:getIsServer() and self.missionDynamicInfo.isMultiplayer then
		return "Error: Command not allowed in multiplayer"
	end

	if self.debugVehiclesToBeLoaded ~= nil then
		return "Loading task is currently running!"
	end

	loadConfigs = string.lower(loadConfigs or "false") == "true"
	modsOnly = string.lower(modsOnly or "false") == "true"
	palletsOnly = string.lower(palletsOnly or "false") == "true"
	verbose = string.lower(verbose or "false") == "true"
	self.debugVehiclesToBeLoaded = {}
	local numVehicles = 0
	self.debugVehiclesToBeLoadedStartTime = g_time
	I3DManager.VERBOSE_LOADING = verbose

	if not palletsOnly then
		for _, storeItem in pairs(g_storeManager:getItems()) do
			if StoreItemUtil.getIsVehicle(storeItem) and (not modsOnly or storeItem.isMod) then
				table.insert(self.debugVehiclesToBeLoaded, {
					storeItem = storeItem,
					configurations = {}
				})

				numVehicles = numVehicles + 1

				if loadConfigs then
					if storeItem.configurations ~= nil then
						for name, items in pairs(storeItem.configurations) do
							if #items > 1 then
								local includedInSet = false

								for i = 1, #storeItem.configurationSets do
									local configSet = storeItem.configurationSets[i]

									if configSet.configurations[name] ~= nil then
										includedInSet = true

										break
									end
								end

								if not includedInSet then
									for k, _ in ipairs(items) do
										local configs = {
											[name] = k
										}

										table.insert(self.debugVehiclesToBeLoaded, {
											storeItem = storeItem,
											configurations = configs
										})
									end
								end
							end
						end
					end

					for i = 1, #storeItem.configurationSets do
						local configSet = storeItem.configurationSets[i]
						local configs = {}

						for name, index in pairs(configSet.configurations) do
							configs[name] = index
						end

						table.insert(self.debugVehiclesToBeLoaded, {
							storeItem = storeItem,
							configurations = configs
						})
					end
				end
			end
		end
	else
		for _, fillType in pairs(g_fillTypeManager:getFillTypes()) do
			if fillType.palletFilename ~= nil then
				local storeItem = g_storeManager:getItemByXMLFilename(fillType.palletFilename)

				table.insert(self.debugVehiclesToBeLoaded, {
					storeItem = storeItem,
					configurations = {}
				})
			end
		end
	end

	local modStr = modsOnly and "mod " or ""

	if loadConfigs then
		print(string.format("Loading %i %svehicles with all configs...", numVehicles, modStr))
	else
		print(string.format("Loading %i %svehicles (add first param 'true' to include configs, add second param 'true' to only load mods, add third param 'true' to only load pallets, add fourth param 'verbose' to print i3d loading messages)...", numVehicles, modStr))
	end
end

function FSBaseMission:consoleCommandLoadAllVehiclesNext()
	if self.debugVehiclesToBeLoaded == nil then
		return
	end

	if self.debugVehiclesLoadingCount ~= nil and self.debugVehiclesLoadingCount > 0 then
		return
	end

	local data = table.remove(self.debugVehiclesToBeLoaded, 1)

	if data == nil then
		local totalTime = g_time - self.debugVehiclesToBeLoadedStartTime

		print(string.format("Successfully loaded and removed all vehicles in %.1f seconds!", totalTime / 1000))

		self.debugVehiclesToBeLoaded = nil
		self.debugVehiclesLoadingCount = nil
		self.debugVehiclesLoaded = nil
		I3DManager.VERBOSE_LOADING = true

		return
	end

	if self.debugVehiclesLoaded ~= nil then
		for _, vehicle in pairs(self.debugVehiclesLoaded) do
			if not vehicle.isDeleted then
				g_currentMission:removeVehicle(vehicle)
			end
		end

		self.debugVehiclesLoaded = nil
	end

	log(#self.debugVehiclesToBeLoaded, data.storeItem.xmlFilename)

	local storeItem = data.storeItem
	local items = {}

	if storeItem.bundleInfo ~= nil then
		for _, item in pairs(storeItem.bundleInfo.bundleItems) do
			table.insert(items, {
				xmlFilename = item.xmlFilename
			})
		end
	else
		table.insert(items, {
			xmlFilename = storeItem.xmlFilename
		})
	end

	self.debugVehiclesLoadingCount = #items
	self.debugVehiclesLoaded = {}

	local function asyncCallbackFunction(_, newVehicle, vehicleLoadState, arguments)
		self.debugVehiclesLoadingCount = self.debugVehiclesLoadingCount - 1

		if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_OK then
			table.insert(self.debugVehiclesLoaded, newVehicle)
		end
	end

	for _, item in pairs(items) do
		VehicleLoadingUtil.loadVehicle(item.xmlFilename, {
			z = 0,
			x = 0,
			yOffset = 0
		}, true, 0, Vehicle.PROPERTY_STATE_OWNED, AccessHandler.EVERYONE, data.configurations, nil, asyncCallbackFunction, nil)
	end
end

function FSBaseMission:consoleCommandFillUnitAdd(fillUnitIndex, fillTypeName, amount)
	local usage = "Usage: 'gsFillUnitAdd <fillUnitIndex> <fillTypeName> [amount]'"
	local fillableVehicle = nil

	if self.controlledVehicle.getSelectedObject ~= nil then
		local selectedObject = self.controlledVehicle:getSelectedObject()

		if selectedObject ~= nil and selectedObject.vehicle.addFillUnitFillLevel ~= nil then
			fillableVehicle = selectedObject.vehicle
		end
	end

	if fillableVehicle == nil and self.controlledVehicle.addFillUnitFillLevel ~= nil then
		fillableVehicle = self.controlledVehicle
	end

	local farmId = self:getFarmId()

	if fillableVehicle == nil or fillableVehicle.getFillUnitSupportedToolTypes == nil then
		return "'Error: could not find a fillable vehicle!"
	end

	local function getSupportedFilltypesString()
		local fillUnits = {}

		for fillUnitIdx, fillTypesIndices in pairs(fillableVehicle:debugGetSupportedFillTypesPerFillUnit()) do
			table.insert(fillUnits, string.format("FillUnit %d - FillTypes: %s", fillUnitIdx, table.concat(g_fillTypeManager:getFillTypeNamesByIndices(fillTypesIndices), " ")))
		end

		return "Available FillUnits and supported FillTypes:\n" .. table.concat(fillUnits, "\n")
	end

	if fillUnitIndex == nil or fillTypeName == nil then
		return "Error: Missing parameters.\n" .. usage
	end

	if not self:getIsServer() then
		return "Error: 'gsFillUnitAdd' can only be called on server side!"
	end

	if self.controlledVehicle == nil then
		return "Error: 'gsFillUnitAdd' can only be used from within a controlled vehicle!"
	end

	fillUnitIndex = tonumber(fillUnitIndex)
	local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
	amount = tonumber(amount)

	if fillUnitIndex == nil then
		return "Error: Missing fillUnitIndex!\n" .. usage
	end

	if not fillableVehicle:getFillUnitExists(fillUnitIndex) then
		return string.format("Error: FillUnit '%d' in '%s' does not exist!\n%s", fillUnitIndex, fillableVehicle:getName(), getSupportedFilltypesString())
	end

	if fillTypeIndex == nil then
		return string.format("Error: Unknown fillType '%s'!\n%s", fillTypeName, getSupportedFilltypesString())
	end

	local capacity = fillableVehicle:getFillUnitCapacity(fillUnitIndex)

	if capacity == 0 then
		return string.format("Error: Selected Vehicle '%s' cannot be filled. Capacity is 0!", fillableVehicle:getName())
	end

	local fillUnitSupportsFillType = fillableVehicle:getFillUnitSupportsFillType(fillUnitIndex, fillTypeIndex)

	if not fillUnitSupportsFillType then
		return string.format("Error: fillUnit '%d' in '%s' does not support fillType '%s'\n%s", fillUnitIndex, fillableVehicle:getName(), fillTypeName, getSupportedFilltypesString())
	end

	amount = amount or capacity

	if amount == 0 then
		amount = -capacity
	end

	fillableVehicle:addFillUnitFillLevel(farmId, fillUnitIndex, amount, fillTypeIndex, ToolType.UNDEFINED)

	local fillLevel = fillableVehicle:getFillUnitFillLevel(fillUnitIndex)
	fillTypeIndex = fillableVehicle:getFillUnitFillType(fillUnitIndex)
	fillTypeName = Utils.getNoNil(g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex), "unknown")

	return string.format("new fillLevel: %.1f, fillType: %d (%s)", fillLevel, fillTypeIndex, fillTypeName)
end

function FSBaseMission:consoleCommandSetFuel(fuelLevel)
	if self:getIsServer() then
		if fuelLevel == nil then
			return "No fuellevel given! Usage: gsVehicleFuelSet <fuelLevel>"
		end

		fuelLevel = Utils.getNoNil(tonumber(fuelLevel), 10000000000.0)
		local vehicle = self.controlledVehicle

		if vehicle ~= nil then
			if vehicle.getConsumerFillUnitIndex ~= nil then
				local fillUnitIndex = vehicle:getConsumerFillUnitIndex(FillType.DIESEL) or vehicle:getConsumerFillUnitIndex(FillType.ELECTRICCHARGE) or vehicle:getConsumerFillUnitIndex(FillType.METHANE)

				if fillUnitIndex ~= nil then
					local fillLevel = vehicle:getFillUnitFillLevel(fillUnitIndex)
					local delta = fuelLevel - fillLevel

					vehicle:addFillUnitFillLevel(self:getFarmId(), fillUnitIndex, delta, vehicle:getFillUnitFirstSupportedFillType(fillUnitIndex), ToolType.UNDEFINED, nil)
				else
					return "No Fuel filltype supported!"
				end
			end
		else
			return "Enter a vehicle first!"
		end
	end
end

function FSBaseMission:consoleCommandSetMotorTemperature(temperature)
	if self:getIsServer() then
		if temperature == nil then
			return "No temperature given! Usage: gsVehicleTemperatureSet <temperature>"
		end

		temperature = Utils.getNoNil(tonumber(temperature), 0)
		local vehicle = self.controlledVehicle

		if vehicle ~= nil then
			local spec = vehicle.spec_motorized

			if spec ~= nil then
				spec.motorTemperature.value = MathUtil.clamp(temperature, spec.motorTemperature.valueMin, spec.motorTemperature.valueMax)

				return "Set motor temperature to " .. spec.motorTemperature.value
			end
		else
			return "Enter a vehicle first!"
		end
	end
end

function FSBaseMission:consoleCommandSetOperatingTime(operatingTime)
	if self:getIsServer() then
		if operatingTime == nil then
			return "No operatingTime given! Usage: gsVehicleOperatingTimeSet <operatingTime (h)>"
		end

		operatingTime = Utils.getNoNil(tonumber(operatingTime), 0)
		operatingTime = operatingTime * 1000 * 60 * 60

		if self.controlledVehicle ~= nil then
			if self.controlledVehicle.setOperatingTime ~= nil then
				self.controlledVehicle:setOperatingTime(operatingTime)
			end
		else
			return "Enter a vehicle first!"
		end
	end
end

function FSBaseMission:consoleCommandShowVehicleDistance(active)
	g_showVehicleDistance = Utils.getNoNil(active, not g_showVehicleDistance)
end

function FSBaseMission:consoleCommandShowTipCollisions(active)
	g_showTipCollisions = Utils.getNoNil(active, not g_showTipCollisions)

	if g_showTipCollisions and StartParams.getValue("scriptDebug") == nil then
		return "Error: Game must be started with '-scriptDebug' parameter"
	end

	return "showTipCollisions=" .. tostring(g_showTipCollisions)
end

function FSBaseMission:consoleCommandShowPlacementCollisions(active)
	g_showPlacementCollisions = Utils.getNoNil(active, not g_showPlacementCollisions)

	if g_showPlacementCollisions and StartParams.getValue("scriptDebug") == nil then
		return "Error: Game must be started with '-scriptDebug' parameter"
	end

	local output = "showPlacementCollisions=" .. tostring(g_showPlacementCollisions)

	if g_showPlacementCollisions then
		return output .. "\nEnable debug view (F5) to render collision information"
	end

	return output
end

function FSBaseMission:consoleCommandUpdateTipCollisions(width)
	local x, _, z = getWorldTranslation(getCamera(0))
	width = MathUtil.clamp(tonumber(width) or 20, 2, 1000)
	local halfWidth = width / 2

	g_densityMapHeightManager:updateCollisionMap(x - halfWidth, z - halfWidth, x + halfWidth, z + halfWidth)

	return string.format("Updated tipCollision in a %ix%i area around the camera. Add a number as a parameter to update a custom area", width, width)
end

function FSBaseMission:consoleCommandAddPallet(palletType)
	local pallets = {}

	for _, fillType in pairs(g_fillTypeManager:getFillTypes()) do
		if fillType.palletFilename ~= nil then
			pallets[fillType.name] = fillType.palletFilename
		end
	end

	palletType = string.upper(palletType or "")
	local xmlFilename = pallets[palletType]

	if xmlFilename ~= nil then
		local x = 0
		local y = 0
		local z = 0
		local dirX = 1
		local dirZ = 0
		local _ = nil

		if self.controlPlayer then
			if self.player ~= nil and self.player.isControlled and self.player.rootNode ~= nil and self.player.rootNode ~= 0 then
				x, y, z = getWorldTranslation(self.player.rootNode)
				dirZ = -math.cos(self.player.rotY)
				dirX = -math.sin(self.player.rotY)
			end
		elseif self.controlledVehicle ~= nil then
			x, y, z = getWorldTranslation(self.controlledVehicle.rootNode)
			dirX, _, dirZ = localDirectionToWorld(self.controlledVehicle.rootNode, 0, 0, 1)
		end

		z = z + dirZ * 4
		x = x + dirX * 4
		y = y + 1.5
		local location = {
			x = x,
			y = y,
			z = z
		}

		local function asyncCallbackFunction(_, vehicle, vehicleLoadState, arguments)
			if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_OK then
				local fillTypeIndex = vehicle:getFillUnitFirstSupportedFillType(1)

				vehicle:addFillUnitFillLevel(1, 1, math.huge, fillTypeIndex, ToolType.UNDEFINED, nil)
			end
		end

		VehicleLoadingUtil.loadVehicle(xmlFilename, location, true, 0, Vehicle.PROPERTY_STATE_OWNED, 1, nil, , asyncCallbackFunction, nil)
	else
		return "Invalid pallet type. Valid types are " .. table.concatKeys(pallets, " ")
	end
end

function FSBaseMission:consoleActivateCameraPath(cameraPathIndex)
	cameraPathIndex = tonumber(cameraPathIndex)

	if cameraPathIndex == nil or cameraPathIndex < 1 or table.getn(self.cameraPaths) < cameraPathIndex then
		return "Invalid argument. Argument: cameraPathIndex"
	end

	if self.currentCameraPath ~= nil then
		self.currentCameraPath:deactivate()
	end

	self.cameraPathIsPlaying = false
	self.currentCameraPath = self.cameraPaths[cameraPathIndex]

	local function finishedCallback()
		print("camera path finished")
		self.currentCameraPath:deactivate()
	end

	self.currentCameraPath.finishedCallback = finishedCallback

	self.currentCameraPath:activate()
	g_currentMission:addUpdateable(self.currentCameraPath)

	return "Camera path activated"
end

function FSBaseMission:consoleCommandSaveDediXMLStatsFile()
	self:updateGameStatsXML()
end

function FSBaseMission:consoleCommandSaveGame()
	self:saveSavegame()
end

function FSBaseMission:updateFoundHelpIcons()
	if self.helpIconsBase ~= nil then
		for i = 1, string.len(self.missionInfo.foundHelpIcons) do
			if string.sub(self.missionInfo.foundHelpIcons, i, i) == "1" then
				self.helpIconsBase:deleteHelpIcon(i)
			end
		end
	end
end

function FSBaseMission:removeAllHelpIcons()
	if self.helpIconsBase ~= nil then
		for i = 1, string.len(self.missionInfo.foundHelpIcons) do
			self.helpIconsBase:deleteHelpIcon(i)
		end
	end
end

function FSBaseMission:playerOwnsAllFields()
	for k, _ in pairs(g_farmlandManager:getFarmlands()) do
		g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(k, 1, 0))
	end
end

function FSBaseMission:addPlaceableToDelete(placeable)
	placeable.markedForDeletion = true
	self.placeablesToDelete[placeable] = placeable
end

function FSBaseMission:removePlaceableToDelete(placeable)
	self.placeablesToDelete[placeable] = nil
end

function FSBaseMission:broadcastEventToMasterUser(event, ignoreConnection)
	for _, user in pairs(self.userManager:getMasterUsers()) do
		local connection = user:getConnection()

		if connection ~= ignoreConnection then
			connection:sendEvent(event)
		end
	end

	event:delete()
end

function FSBaseMission:broadcastMissionDynamicInfo(connection)
	assert(self:getIsServer(), "broadcastMissionDynamicInfo call is only allowed on Server")
	self:broadcastEventToMasterUser(MissionDynamicInfoEvent.new(), connection)
end

function FSBaseMission:updateMissionDynamicInfo(serverName, capacity, password, autoAccept, allowOnlyFriends, allowCrossPlay)
	if serverName ~= "" and g_dedicatedServer == nil then
		self.missionDynamicInfo.serverName = serverName
	end

	if g_dedicatedServer == nil then
		self.missionDynamicInfo.capacity = capacity
	end

	self.missionDynamicInfo.password = password
	self.missionDynamicInfo.autoAccept = autoAccept or g_dedicatedServer ~= nil
	self.missionDynamicInfo.allowOnlyFriends = allowOnlyFriends
	self.missionDynamicInfo.allowCrossPlay = allowCrossPlay

	self:updateMaxNumHirables()

	if g_dedicatedServer ~= nil then
		self:updateDedicatedServerXML()
	end
end

function FSBaseMission:updateMasterServerInfo(connection)
	if self:getIsServer() then
		local userCount = self.userManager:getNumberOfUsers()

		if g_dedicatedServer ~= nil then
			userCount = userCount - 1
		end

		masterServerSetServerInfo(g_currentMission.missionDynamicInfo.serverName, g_currentMission.missionDynamicInfo.password, g_currentMission.missionDynamicInfo.capacity, userCount, g_currentMission.missionDynamicInfo.allowOnlyFriends)
		self:broadcastMissionDynamicInfo(connection)
	end
end

function FSBaseMission:updateDedicatedServerXML()
	if g_dedicatedServer ~= nil then
		local info = self.missionDynamicInfo

		g_dedicatedServer:updateServerInfo(info.serverName, info.password, info.capacity)
	end
end

function FSBaseMission:updateGameStatsXML()
	if g_dedicatedServer ~= nil then
		local statsPath = g_dedicatedServer.gameStatsPath
		local key = "Server"
		local xmlFile = createXMLFile("serverStatsFile", statsPath, key)

		if xmlFile ~= nil and xmlFile ~= 0 then
			local gameName = self.missionDynamicInfo.serverName or ""
			local mapName = "Unknown"
			local map = g_mapManager:getMapById(self.missionInfo.mapId)

			if map ~= nil then
				mapName = map.title
			end

			local dayTime = 0

			if self.environment ~= nil then
				dayTime = self.environment.dayTime
			end

			local mapSize = Utils.getNoNil(self.terrainSize, 2048)
			local numUsers = self.userManager:getNumberOfUsers()

			if g_dedicatedServer ~= nil then
				numUsers = numUsers - 1
			end

			local capacity = self.missionDynamicInfo.capacity or 0

			setXMLString(xmlFile, key .. "#game", "Farming Simulator 20")
			setXMLString(xmlFile, key .. "#version", g_gameVersionDisplay .. g_gameVersionDisplayExtra)
			setXMLString(xmlFile, key .. "#name", HTMLUtil.encodeToHTML(gameName))
			setXMLString(xmlFile, key .. "#mapName", HTMLUtil.encodeToHTML(mapName))
			setXMLInt(xmlFile, key .. "#dayTime", dayTime)
			setXMLString(xmlFile, key .. "#mapOverviewFilename", NetworkUtil.convertToNetworkFilename(self.mapImageFilename))
			setXMLInt(xmlFile, key .. "#mapSize", mapSize)
			setXMLInt(xmlFile, key .. ".Slots#capacity", capacity)
			setXMLInt(xmlFile, key .. ".Slots#numUsed", numUsers)

			local i = 0

			for _, user in ipairs(self.userManager:getUsers()) do
				local player = nil
				local connection = user:getConnection()

				if connection ~= nil then
					player = self.connectionsToPlayer[connection]
				end

				if user:getId() ~= self:getServerUserId() or g_dedicatedServer == nil then
					local playerKey = string.format("%s.Slots.Player(%d)", key, i)
					local playtime = (self.time - user:getConnectedTime()) / 60000

					setXMLBool(xmlFile, playerKey .. "#isUsed", true)
					setXMLBool(xmlFile, playerKey .. "#isAdmin", user:getIsMasterUser())
					setXMLInt(xmlFile, playerKey .. "#uptime", playtime)

					if player ~= nil and player.isControlled and player.rootNode ~= nil and player.rootNode ~= 0 then
						local x, y, z = getWorldTranslation(player.rootNode)

						setXMLFloat(xmlFile, playerKey .. "#x", x)
						setXMLFloat(xmlFile, playerKey .. "#y", y)
						setXMLFloat(xmlFile, playerKey .. "#z", z)
					end

					setXMLString(xmlFile, playerKey, HTMLUtil.encodeToHTML(user:getNickname(), true))

					i = i + 1
				end
			end

			for n = numUsers + 1, capacity do
				local playerKey = string.format("%s.Slots.Player(%d)", key, n)

				setXMLBool(xmlFile, playerKey .. "#isUsed", false)
			end

			i = 0

			for _, vehicle in pairs(self.vehicles) do
				local vehicleKey = string.format("%s.Vehicles.Vehicle(%d)", key, i)

				if vehicle:saveStatsToXMLFile(xmlFile, vehicleKey) then
					i = i + 1
				end
			end

			i = 0

			for _, mod in pairs(self.missionDynamicInfo.mods) do
				local modKey = string.format("%s.Mods.Mod(%d)", key, i)

				setXMLString(xmlFile, modKey .. "#name", HTMLUtil.encodeToHTML(mod.modName))
				setXMLString(xmlFile, modKey .. "#author", HTMLUtil.encodeToHTML(mod.author))
				setXMLString(xmlFile, modKey .. "#version", HTMLUtil.encodeToHTML(mod.version))
				setXMLString(xmlFile, modKey, HTMLUtil.encodeToHTML(mod.title, true))

				if mod.fileHash ~= nil then
					setXMLString(xmlFile, modKey .. "#hash", HTMLUtil.encodeToHTML(mod.fileHash))
				end

				i = i + 1
			end

			i = 0

			for _, farmland in pairs(g_farmlandManager:getFarmlands()) do
				local farmlandKey = string.format("%s.Farmlands.Farmland(%d)", key, i)

				setXMLString(xmlFile, farmlandKey .. "#name", tostring(farmland.name))
				setXMLInt(xmlFile, farmlandKey .. "#id", farmland.id)
				setXMLInt(xmlFile, farmlandKey .. "#owner", g_farmlandManager:getFarmlandOwner(farmland.id))
				setXMLFloat(xmlFile, farmlandKey .. "#area", farmland.areaInHa)
				setXMLInt(xmlFile, farmlandKey .. "#area", farmland.price)
				setXMLFloat(xmlFile, farmlandKey .. "#x", farmland.xWorldPos)
				setXMLFloat(xmlFile, farmlandKey .. "#z", farmland.zWorldPos)

				i = i + 1
			end

			i = 0

			for _, field in pairs(g_fieldManager:getFields()) do
				local fieldKey = string.format("%s.Fields.Field(%d)", key, i)

				setXMLString(xmlFile, fieldKey .. "#id", tostring(field.fieldId))
				setXMLFloat(xmlFile, fieldKey .. "#x", field.posX)
				setXMLFloat(xmlFile, fieldKey .. "#z", field.posZ)
				setXMLBool(xmlFile, fieldKey .. "#isOwned", not field.isAIActive)

				i = i + 1
			end

			saveXMLFile(xmlFile)
			delete(xmlFile)
		end
	end

	self.gameStatsTime = self.time + self.gameStatsInterval
end

function FSBaseMission:setVisibilityOfGUIComponents(state)
	self.hud:setIsVisible(state)
end

function FSBaseMission:setConnectionLostState(state)
	self.connectionLostState = state
end

function FSBaseMission:addMapHotspot(hotspot)
	return self.hud:addMapHotspot(hotspot)
end

function FSBaseMission:removeMapHotspot(hotspot)
	self.hud:removeMapHotspot(hotspot)
end

function FSBaseMission:isInGameMessageActive()
	return self.hud:isInGameMessageActive()
end

function FSBaseMission:registerActionEvents()
	FSBaseMission:superClass().registerActionEvents(self)

	local _, eventId = nil

	if not g_isPresentationVersionMenuDisabled then
		_, eventId = self.inputManager:registerActionEvent(InputAction.MENU, self, self.onToggleMenu, false, true, false, true)

		self.inputManager:setActionEventTextVisibility(eventId, false)
	end

	_, eventId = self.inputManager:registerActionEvent(InputAction.TOGGLE_STORE, self, self.onToggleStore, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.TOGGLE_MAP, self, self.onToggleMap, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.TOGGLE_CHARACTER_CREATION, self, self.onToggleCharacterCreation, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.TOGGLE_CONSTRUCTION, self, self.onToggleConstructionScreen, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	if g_isPresentationVersionUseReloadButton then
		_, eventId = self.inputManager:registerActionEvent(InputAction.RELOAD_GAME, self, self.onReloadSavegame, false, true, false, true)

		self.inputManager:setActionEventTextVisibility(eventId, false)
	end

	if g_soundPlayer ~= nil then
		_, eventId = self.inputManager:registerActionEvent(InputAction.RADIO_TOGGLE, self, self.onToggleRadio, false, true, false, false)

		self.inputManager:setActionEventTextVisibility(eventId, GS_IS_CONSOLE_VERSION)

		self.eventRadioToggle = eventId
		local radioEventsActive = self:getIsRadioPlaying()
		local radioEvents = {}
		_, eventId = self.inputManager:registerActionEvent(InputAction.RADIO_PREVIOUS_CHANNEL, g_soundPlayer, g_soundPlayer.previousChannel, false, true, false, radioEventsActive)

		self.inputManager:setActionEventTextVisibility(eventId, GS_IS_CONSOLE_VERSION)
		table.insert(radioEvents, eventId)

		_, eventId = self.inputManager:registerActionEvent(InputAction.RADIO_NEXT_CHANNEL, g_soundPlayer, g_soundPlayer.nextChannel, false, true, false, radioEventsActive)

		self.inputManager:setActionEventTextVisibility(eventId, GS_IS_CONSOLE_VERSION)
		table.insert(radioEvents, eventId)

		_, eventId = self.inputManager:registerActionEvent(InputAction.RADIO_NEXT_ITEM, g_soundPlayer, g_soundPlayer.nextItem, false, true, false, radioEventsActive)

		self.inputManager:setActionEventTextVisibility(eventId, false)
		table.insert(radioEvents, eventId)

		_, eventId = self.inputManager:registerActionEvent(InputAction.RADIO_PREVIOUS_ITEM, g_soundPlayer, g_soundPlayer.previousItem, false, true, false, radioEventsActive)

		self.inputManager:setActionEventTextVisibility(eventId, false)
		table.insert(radioEvents, eventId)

		self.radioEvents = radioEvents
	end

	_, eventId = self.inputManager:registerActionEvent(InputAction.INCREASE_TIMESCALE, self, self.onChangeTimescale, false, true, false, true, 1)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	_, eventId = self.inputManager:registerActionEvent(InputAction.DECREASE_TIMESCALE, self, self.onChangeTimescale, false, true, false, true, -1)

	self.inputManager:setActionEventTextVisibility(eventId, false)

	if self.missionDynamicInfo.isMultiplayer then
		self.inputManager:registerActionEvent(InputAction.CHAT, self, self.toggleChat, false, true, false, true)
	end
end

function FSBaseMission:registerPauseActionEvents()
	FSBaseMission:superClass().registerPauseActionEvents(self)
	self.inputManager:beginActionEventsModification(BaseMission.INPUT_CONTEXT_PAUSE)

	local _, eventId = self.inputManager:registerActionEvent(InputAction.MENU, self, self.onToggleMenu, false, true, false, true)

	self.inputManager:setActionEventTextVisibility(eventId, true)
	self.inputManager:endActionEventsModification()
end

function FSBaseMission:onReloadSavegame()
	if g_gamingStationManager:getIsActive() then
		OnInGameMenuMenu()
		g_gui:showGui("CareerScreen")

		return
	end

	local savegameIndex = self.missionInfo.savegameIndex
	local isSaved = self.missionInfo.isValid

	OnInGameMenuMenu()

	if isSaved then
		g_gui:setIsMultiplayer(false)
		g_gui:showGui("CareerScreen")

		g_careerScreen.selectedIndex = savegameIndex
		local savegameController = g_careerScreen.savegameController
		local savegame = savegameController:getSavegame(savegameIndex)

		if savegame == SavegameController.NO_SAVEGAME or not savegame.isValid then
			return
		end

		g_careerScreen.currentSavegame = savegame

		g_careerScreen:onStartAction()

		if g_gui.currentGuiName == "ModSelectionScreen" then
			g_modSelectionScreen:onClickOk()
		end
	end
end

function FSBaseMission:onToggleMenu()
	if not self.isSynchronizingWithPlayers then
		g_gui:changeScreen(nil, InGameMenu)

		if GS_IS_MOBILE_VERSION then
			self.inGameMenu:goToPage(self.inGameMenu.pageMain)
		end
	end
end

function FSBaseMission:onToggleMap()
	if not self.isSynchronizingWithPlayers then
		g_gui:changeScreen(nil, InGameMenu)

		if GS_IS_MOBILE_VERSION then
			self.inGameMenu:goToPage(self.inGameMenu.pageMapOverview)
		end
	end
end

function FSBaseMission:onToggleStore()
	if not self.isSynchronizingWithPlayers then
		if not g_currentMission.missionInfo:isa(FSCareerMissionInfo) then
			g_gui:showInfoDialog({
				text = g_i18n:getText("dialog_shopOnlyWorksInCareer")
			})
		end

		if (not g_isPresentationVersion or g_isPresentationVersionShopEnabled) and g_currentMission.missionInfo:isa(FSCareerMissionInfo) and not self.isPlayerFrozen and self.player.farmId ~= FarmManager.SPECTATOR_FARM_ID then
			g_gui:changeScreen(nil, ShopMenu)
		end
	end
end

function FSBaseMission:onToggleCharacterCreation()
	if not self.isSynchronizingWithPlayers and (not g_isPresentationVersion or g_isPresentationVersionWardrobeEnabled) then
		g_gui:changeScreen(nil, WardrobeScreen)
	end
end

function FSBaseMission:onToggleConstructionScreen()
	if not self.isSynchronizingWithPlayers and self.player.farmId ~= FarmManager.SPECTATOR_FARM_ID and (not g_isPresentationVersion or g_isPresentationVersionBuildModeEnabled) then
		g_gui:changeScreen(nil, ConstructionScreen)
	end
end

function FSBaseMission:toggleChat(isActive)
	if not self.isSynchronizingWithPlayers then
		if isActive == nil or isActive then
			g_gui:showGui("ChatDialog")

			isActive = true
		else
			isActive = false
		end

		self.hud:setChatWindowVisible(isActive)
	end
end

function FSBaseMission:onToggleRadio()
	local isActive = g_gameSettings:getValue(GameSettings.SETTING.RADIO_IS_ACTIVE)

	g_gameSettings:setValue(GameSettings.SETTING.RADIO_IS_ACTIVE, not isActive)
end

function FSBaseMission:onChangeTimescale(_, _, indexStep)
	if (self:getIsServer() or self.isMasterUser) and not g_sleepManager:getIsSleeping() then
		local timeScaleIndex = Utils.getTimeScaleIndex(self.missionInfo.timeScale)
		local newTimeScale = Utils.getTimeScaleFromIndex(timeScaleIndex + indexStep)

		if newTimeScale ~= nil then
			self:setTimeScale(newTimeScale)
		end
	end
end

function FSBaseMission:onShowHelpIconsChanged(isVisible)
	if self.helpIconsBase ~= nil then
		self.helpIconsBase:showHelpIcons(isVisible)
	end
end

function FSBaseMission:onRadioVehicleOnlyChanged(isVehicleOnly)
	local isRadioPlayingSettingActive = g_gameSettings:getValue(GameSettings.SETTING.RADIO_IS_ACTIVE)
	local canPlayRadioNow = not isVehicleOnly or isVehicleOnly and self.controlledVehicle ~= nil and self.controlledVehicle.supportsRadio

	if isRadioPlayingSettingActive then
		if canPlayRadioNow then
			if not self:getIsRadioPlaying() then
				self:playRadio()
			end
		else
			self:pauseRadio()
		end
	end
end

function FSBaseMission:onRadioIsActiveChanged(isActive)
	if not isActive then
		self:pauseRadio()
	else
		local isVehicleOnly = g_gameSettings:getValue(GameSettings.SETTING.RADIO_VEHICLE_ONLY)

		if not isVehicleOnly or isVehicleOnly and self.controlledVehicle ~= nil and self.controlledVehicle.supportsRadio then
			self:playRadio()
		end
	end
end

function FSBaseMission:setRadioActionEventsState(isActive)
	for _, eventId in pairs(self.radioEvents) do
		self.inputManager:setActionEventActive(eventId, isActive)
	end
end

function FSBaseMission:subscribeMessages()
	self.messageCenter:subscribe(SaveEvent, self.startSaveCurrentGame, self)
	self.messageCenter:subscribe(MessageType.PLAYER_FARM_CHANGED, self.notifyPlayerFarmChanged, self)
	self.messageCenter:subscribe(MessageType.USER_ADDED, self.onUserAdded, self)
	self.messageCenter:subscribe(MessageType.USER_REMOVED, self.onUserRemoved, self)
	self.messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.IS_TRAIN_TABBABLE], self.setTrainSystemTabbable, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_HELP_ICONS], self.onShowHelpIconsChanged, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.RADIO_VEHICLE_ONLY], self.onRadioVehicleOnlyChanged, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.RADIO_IS_ACTIVE], self.onRadioIsActiveChanged, self)
	self.messageCenter:subscribe(MessageType.APP_SUSPENDED, self.onAppSuspended, self)
	self.messageCenter:subscribe(MessageType.APP_RESUMED, self.onAppResumed, self)
end

function FSBaseMission:onAppSuspended()
	if not self.isLoaded then
		return
	end

	if GS_IS_MOBILE_VERSION and not self.savegameController:getIsSaving() then
		self:saveSavegame(true)
	end
end

function FSBaseMission:onAppResumed()
	if not g_gui:getIsGuiVisible() then
		g_autoSaveManager:resetTime()
		g_gui:changeScreen(nil, InGameMenu)
	end
end

function FSBaseMission:notifyPlayerFarmChanged(player)
	if player == self.player then
		if self:getIsClient() and self.controlledVehicle ~= nil then
			self:onLeaveVehicle()
		end

		local farm = g_farmManager:getFarmById(self.player.farmId)

		self.inGameMenu:setPlayerFarm(farm)
		self.shopMenu:setPlayerFarm(farm)
		self.shopController:setOwnedFarmItems(self.ownedItems, self.player.farmId)
		self.shopController:setLeasedFarmItems(self.leasedVehicles, self.player.farmId)
		self.inGameMenu:onMoneyChanged(farm.farmId, farm:getBalance())
		self.shopMenu:onMoneyChanged(farm.farmId, farm:getBalance())
	end
end

function FSBaseMission:onUserAdded(user)
	self:updateMaxNumHirables()

	if user:getId() == self.playerUserId then
		self.inGameMenu:setCurrentUserId(self.playerUserId)
		self.shopMenu:setCurrentUserId(self.playerUserId)
	end

	if user:getId() ~= g_currentMission:getServerUserId() and user:getId() ~= self.playerUserId then
		print(user:getNickname() .. " joined the game")
		g_currentMission:addChatMessage(user:getNickname(), g_i18n:getText("ui_serverUserJoin"), FarmManager.SPECTATOR_FARM_ID)
	end

	self:updateGameStatsXML()
	self.inGameMenu:setConnectedUsers(self.userManager:getUsers())
	self.hud:setConnectedUsers(self.userManager:getUsers())
	self.userManager:setUserBlockDataDirty()
end

function FSBaseMission:onUserRemoved(user)
	self:updateMaxNumHirables()

	if user:getId() ~= g_currentMission:getServerUserId() and user:getId() ~= self.playerUserId then
		print(user:getNickname() .. " left the game")
		g_currentMission:addChatMessage(user:getNickname(), g_i18n:getText("ui_serverUserLeave"), FarmManager.SPECTATOR_FARM_ID)
	end

	self:updateGameStatsXML()
	self.inGameMenu:setConnectedUsers(self.userManager:getUsers())
	self.hud:setConnectedUsers(self.userManager:getUsers())
end

function FSBaseMission:onMasterUserAdded(user)
	if user:getId() == self.playerUserId then
		self.isMasterUser = true

		if g_addCheatCommands then
			addConsoleCommand("gsMoneyAdd", "Add a lot of money", "consoleCommandCheatMoney", self)
		end
	end

	if self:getIsServer() then
		g_server:broadcastEvent(UserDataEvent.new({
			user
		}))
	end
end

function FSBaseMission:broadcastEventToFarm(event, farmId, sendLocal, ignoreConnection, ghostObject, force)
	local connectionList = {}

	for streamId, connection in pairs(g_server.clientConnections) do
		local player = self.connectionsToPlayer[connection]

		if player ~= nil and player.farmId == farmId then
			connectionList[streamId] = connection
		end
	end

	g_server:broadcastEvent(event, sendLocal, ignoreConnection, ghostObject, force, connectionList)
end

function FSBaseMission:getDefaultServerName()
	local name = nil
	local nickname = g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME)

	if g_languageShort == "pl" then
		name = nickname .. " - " .. g_i18n:getText("ui_serverNameGame")
	elseif nickname:endsWith("s") then
		name = nickname .. "' " .. g_i18n:getText("ui_serverNameGame")
	elseif nickname:endsWith("'") then
		name = nickname .. "s " .. g_i18n:getText("ui_serverNameGame")
	else
		name = nickname .. "'s " .. g_i18n:getText("ui_serverNameGame")
	end

	return name
end
