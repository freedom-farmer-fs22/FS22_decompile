MPLoadingScreen = {
	STATE_NONE = 0,
	STATE_CONNECTING = 1,
	STATE_WAIT_FOR_ACCEPT = 2,
	STATE_SYNCHRONIZING = 3,
	STATE_LOADING = 4,
	STATE_WAIT_FOR_MISSION = 5,
	STATE_READY = 6,
	STATE_PORT_TESTING = 7,
	NUM_GAMEPLAY_HINTS = 3,
	SAVEGAME_LOADING_DIALOG_DELAY = 500,
	CONTROLS = {
		BUTTON_OK_PC = "buttonOkPC",
		MAP_NAME_TEXT = "mapNameText",
		MPLOADING_ANIMATION = "mpLoadingAnimation",
		LOADING_STATUS_TEXT = "loadingStatusText",
		MAP_SELECTION_PREVIEW = "mapSelectionPreview",
		MPLOADING_ANIMATION_DONE = "mpLoadingAnimationDone",
		LOADING_BAR_PERCENTAGE = "loadingBarPercentage",
		LOADING_BAR = "loadingBar",
		BUTTON_DELETE_PC = "buttonDeletePC",
		TIP_STATE_BOX = "tipStateBox",
		GAMEPLAY_HINT_TEXT = "gameplayHintText"
	},
	PERCENTAGE_PER_MS = 7.916666666666667e-06,
	LOAD_TARGETS = {
		ADDITIONAL_FILES = 0.65,
		TERRAIN = 0.6,
		ITEMS = 0.95,
		VEHICLE_VALIDATION = 0.05,
		FINISHED = 0.99,
		MAP = 0.5,
		VEHICLES = 0.85,
		STORE = 0.15,
		DATA = 0.2,
		SPECIALIZATIONS = 0.1
	}
}
local MPLoadingScreen_mt = Class(MPLoadingScreen, ScreenElement)

function MPLoadingScreen.new(target, custom_mt, missionCollaborators, savegameController, loadFunction)
	local self = ScreenElement.new(target, custom_mt or MPLoadingScreen_mt)

	self:registerControls(MPLoadingScreen.CONTROLS)

	self.missionCollaborators = missionCollaborators
	self.savegameController = savegameController
	self.acceptCancelTimer = -1
	self.actionTimerCount = -1
	self.doLoad = false
	self.preSimulateCount = -1
	self.preSimulateSteps = 5
	self.loadFunction = loadFunction
	self.wheelPosX = 0.7
	self.wheelPosY = 0.2
	self.isClient = false
	self.positionOffsetY = 0.024
	self.isBackAllowed = false
	self.currentGameplayHint = nil
	self.currentGameplayHints = nil
	self.isCancel = true
	self.gameplayHintDuration = 6500
	self.gameplayHintTime = self.gameplayHintDuration
	self.savegameLoadingDialogDelay = -1
	self.state = MPLoadingScreen.STATE_NONE
	self.loadTargets = {}

	for _, loadTarget in pairs(MPLoadingScreen.LOAD_TARGETS) do
		table.insert(self.loadTargets, loadTarget)
	end

	table.sort(self.loadTargets, function (a, b)
		return a < b
	end)

	return self
end

function MPLoadingScreen:onGuiSetupFinished()
	MPLoadingScreen:superClass().onGuiSetupFinished(self)
end

function MPLoadingScreen:onCreate()
	self.button = self.buttonOkPC
end

function MPLoadingScreen:onOpen()
	MPLoadingScreen:superClass().onOpen(self)
	self.button:setVisible(false)
	self:setMapTitleAndPreview()
	self.mpLoadingAnimation:setVisible(true)
	self.mpLoadingAnimationDone:setVisible(false)

	self.loadPercentage = 0
	self.loadTarget = 1

	enterCpuBoostMode()
end

function MPLoadingScreen:onClose()
	MPLoadingScreen:superClass().onClose(self)
	self.mapSelectionPreview:setImageFilename("dataS/menu/black.png")
	leaveCpuBoostMode()
end

function MPLoadingScreen:cancelLoading(showConnectionLost)
	saveReadSavegameFinish("", self)
	leaveCpuBoostMode()
	setCamera(g_defaultCamera)

	if self.state == MPLoadingScreen.STATE_PORT_TESTING then
		netShutdown(0, 0)
		g_gui:showGui("MultiplayerScreen")
	elseif self.isClient then
		if g_currentMission ~= nil then
			OnInGameMenuMenu()
		else
			self:cleanup()
		end

		if masterServerConnectFront == nil then
			RestartManager:setStartScreen(RestartManager.START_SCREEN_MULTIPLAYER)
			doRestart(false, "")
		else
			g_gui:showGui("MultiplayerScreen")
		end
	else
		OnInGameMenuMenu()
	end

	if showConnectionLost then
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_connectionLost")
		})
	end
end

function MPLoadingScreen:onClickCancel()
	if self.isCancel and self.missionDynamicInfo.isMultiplayer and self.missionDynamicInfo.isClient then
		self:cancelLoading()
	end
end

function MPLoadingScreen:onClickOk(element)
	MPLoadingScreen:superClass().onClickOk(self)

	if self.state == MPLoadingScreen.STATE_READY then
		self:setButtonState(MPLoadingScreen.STATE_NONE)
		g_inputBinding:revertContext(false)
		g_currentMission:onStartMission()
		g_inputBinding:setContext(Gui.INPUT_CONTEXT_MENU, false, false)
		g_gui:showGui("")
		g_inputBinding:setShowMouseCursor(false)

		if (g_currentMission:getIsServer() and not self.missionInfo.isValid or not g_currentMission:getIsServer() and self.knownPlayerOnServer == false) and (not g_isPresentationVersion or g_isPresentationVersionWardrobeEnabled) then
			g_gui:changeScreen(nil, WardrobeScreen)
		end

		g_currentMission.pressStartPaused = false

		if g_currentMission:getIsServer() then
			g_currentMission:tryUnpauseGame()
		end

		if g_dedicatedServer ~= nil then
			g_dedicatedServer:lowerFramerate()

			if g_dedicatedServer.pauseGameIfEmpty then
				g_currentMission.dediEmptyPaused = true

				g_currentMission:pauseGame()
			end
		end
	end
end

function MPLoadingScreen:update(dt)
	MPLoadingScreen:superClass().update(self, dt)

	if storeHaveDlcsChanged() then
		g_forceNeedsDlcsAndModsReload = true
		local dlcsVerified = verifyDlcs()

		if not dlcsVerified then
			OnInGameMenuMenu()
			g_gui:showInfoDialog({
				text = g_i18n:getText("ui_storageDeviceWithDlcsRemoved"),
				callback = self.dlcProblemOnQuitOk,
				target = self
			})

			return
		end
	end

	if GS_PLATFORM_PLAYSTATION and self.missionDynamicInfo.isMultiplayer then
		if getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE then
			if g_currentMission ~= nil then
				OnInGameMenuMenu()
			else
				self:cleanup()
				g_gui:showGui("MainScreen")
			end
		end

		if getNetworkError() then
			if g_currentMission ~= nil then
				OnInGameMenuMenu(nil, true)
			else
				self:cleanup()
				ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
			end
		end
	end

	if MPLoadingScreen.STATE_WAIT_FOR_ACCEPT < self.state and self.state < MPLoadingScreen.STATE_READY then
		self.loadPercentage = math.min(self.loadPercentage + MPLoadingScreen.PERCENTAGE_PER_MS * dt, self.loadTargets[self.loadTarget])
		self.loadingBar.absSize[1] = self.loadingBar.parent.absSize[1] * self.loadPercentage

		self.loadingBarPercentage:setText(string.format("%d%%", self.loadPercentage * 100))
	end

	if self.state == MPLoadingScreen.STATE_WAIT_FOR_ACCEPT and GS_PLATFORM_PLAYSTATION and self.acceptCancelTimer > 0 then
		self.acceptCancelTimer = self.acceptCancelTimer - dt

		if self.acceptCancelTimer <= 0 then
			print("Waited too long for accept ... cancelling entire process")
			self:cancelLoading(true)

			return
		end
	end

	if self.state == MPLoadingScreen.STATE_WAIT_FOR_MISSION then
		self:onReadyToStart()
	end

	if self.actionTimerCount >= 0 then
		self.actionTimerCount = self.actionTimerCount - 1

		if self.actionTimerCount < 0 then
			if self.doLoad then
				self.doLoad = false

				g_currentMission:onConnectionRequestAcceptedLoad(self.loadConnection)
			elseif self.preSimulateCount >= 0 then
				self.preSimulateCount = self.preSimulateCount - 1

				if self.preSimulateCount < 0 then
					simulatePhysics(false)
					self:onReadyToStart()
				else
					self.actionTimerCount = 0

					extraUpdatePhysics(g_currentMission.preSimulateTime / self.preSimulateSteps)
				end
			end
		end
	end

	if self.currentGameplayHints ~= nil then
		self.gameplayHintTime = self.gameplayHintTime - dt

		if self.gameplayHintTime <= 0 then
			self.gameplayHintTime = self.gameplayHintDuration
			self.currentGameplayHint = self.currentGameplayHint + 1

			if self.currentGameplayHint > #self.currentGameplayHints then
				self.currentGameplayHint = 1
			end

			self:setGameplayHint(self.currentGameplayHints, self.currentGameplayHint)
		end
	elseif g_gameplayHintManager:getIsLoaded() then
		local hints = g_gameplayHintManager:getRandomGameplayHint(MPLoadingScreen.NUM_GAMEPLAY_HINTS)

		if hints ~= nil then
			self.currentGameplayHints = hints
			self.currentGameplayHint = 1

			self.tipStateBox:setPageCount(MPLoadingScreen.NUM_GAMEPLAY_HINTS)
			self:setGameplayHint(self.currentGameplayHints, self.currentGameplayHint)
		end

		self.gameplayHintTime = self.gameplayHintDuration
	end

	if self.savegameLoadingDialogDelay > 0 then
		self.savegameLoadingDialogDelay = self.savegameLoadingDialogDelay - dt

		if self.savegameLoadingDialogDelay <= 0 then
			self.loadingDialog = g_gui:showDialog("InfoDialog")

			self.loadingDialog.target:setText(g_i18n:getText("ui_loadingSavegame"))
			self.loadingDialog.target:setButtonTexts(g_i18n:getText("button_cancel"))
			self.loadingDialog.target:setCallback(self.onCancelSavegameLoading, self)
		end
	end
end

function MPLoadingScreen:dlcProblemOnQuitOk()
	if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "InfoDialog" then
		g_gui:showGui("MainScreen")
	end
end

function MPLoadingScreen:loadSavegameAndStart()
	local savegame = self.missionInfo

	if savegame.isValid then
		self.savegameLoadingDialogDelay = MPLoadingScreen.SAVEGAME_LOADING_DIALOG_DELAY

		saveReadSavegameStart(savegame.savegameIndex, "onSavegameLoaded", self)
	else
		self:onSavegameLoaded(Savegame.ERROR_OK, nil)
	end
end

function MPLoadingScreen:loadGameRelatedData()
	g_asyncTaskManager:setAllowedTimePerFrame(33.333333333333336)
	g_asyncTaskManager:addTask(function ()
		g_toolTypeManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function ()
		g_splitTypeManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function ()
		g_configurationManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function ()
		g_specializationManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function ()
		g_placeableSpecializationManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function ()
		g_vehicleTypeManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function ()
		g_placeableTypeManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function ()
		g_constructionBrushTypeManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function ()
		g_brandManager:loadMapData()
	end)
	g_asyncTaskManager:addTask(function ()
		g_workAreaTypeManager:loadMapData()
	end)
end

function MPLoadingScreen:unloadGameRelatedData()
	g_specializationManager:unloadMapData()
	g_placeableSpecializationManager:unloadMapData()
	g_vehicleTypeManager:unloadMapData()
	g_placeableTypeManager:unloadMapData()
	g_constructionBrushTypeManager:unloadMapData()
	g_brandManager:unloadMapData()
	g_storeManager:unloadMapData()
	g_workAreaTypeManager:unloadMapData()
	g_configurationManager:unloadMapData()
	g_toolTypeManager:unloadMapData()
	g_splitTypeManager:unloadMapData()
end

function MPLoadingScreen:startClient()
	self:loadGameRelatedData()
	resetSplitShapes()
	setTerrainLoadDirectory("", TerrainLoadFlags.GAME_DEFAULT)

	self.isClient = true
	self.isCancel = true

	self:setButtonState(MPLoadingScreen.STATE_CONNECTING)
	g_asyncTaskManager:addTask(function ()
		g_client = Client.new()

		g_masterServerConnection:setCallbackTarget(self)
		masterServerRequestServerDetails(self.missionDynamicInfo.serverId)
	end)
end

function MPLoadingScreen:startLocal()
	self.isClient = false

	self:setButtonState(MPLoadingScreen.STATE_LOADING)
	g_asyncTaskManager:addTask(function ()
		g_server = Server.new()
		g_client = Client.new()
	end)
	self:initializeLoading()
end

function MPLoadingScreen:showPortTesting()
	self:setMapTitleAndPreview()
	self:setButtonState(MPLoadingScreen.STATE_PORT_TESTING)
	g_gui:showGui("MPLoadingScreen")
end

function MPLoadingScreen:startServer()
	self.isClient = false

	self:setButtonState(MPLoadingScreen.STATE_LOADING)

	self.serverName = self.missionDynamicInfo.serverName
	self.serverPassword = self.missionDynamicInfo.password
	self.capacity = self.missionDynamicInfo.capacity
	self.mods = self.missionDynamicInfo.mods

	g_asyncTaskManager:addTask(function ()
		g_server = Server.new()
		g_client = Client.new()

		g_server:start(self.missionDynamicInfo.serverPort, self.missionDynamicInfo.serverAddress, self.missionDynamicInfo.capacity)
	end)
	g_connectToMasterServerScreen:setNextScreenName("MPLoadingScreen")
	g_connectToMasterServerScreen:setPrevScreenName("CreateGameScreen")
	g_gui:showGui("ConnectToMasterServerScreen")
	g_asyncTaskManager:addTask(function ()
		g_connectToMasterServerScreen:connectToFront()
	end)
end

function MPLoadingScreen:loadWithConnection(connection, knownPlayerOnServer)
	self:setButtonState(MPLoadingScreen.STATE_SYNCHRONIZING)

	self.actionTimerCount = 1
	self.doLoad = true
	self.loadConnection = connection
	self.knownPlayerOnServer = knownPlayerOnServer
end

function MPLoadingScreen:onWaitingForAccept()
	if self.isClient then
		self:setButtonState(MPLoadingScreen.STATE_WAIT_FOR_ACCEPT)

		self.acceptCancelTimer = 120000
	end
end

function MPLoadingScreen:onWaitingForDynamicData()
	self:setButtonState(MPLoadingScreen.STATE_LOADING)
end

function MPLoadingScreen:onCreatingGame()
	self:setStatusText(g_i18n:getText("ui_creatingGame"))
end

function MPLoadingScreen:setDynamicDataPercentage(progress)
	self:setStatusText(g_i18n:getText("ui_synchronizingWithOtherPlayers") .. " " .. math.floor(progress * 100) .. "%")
end

function MPLoadingScreen:reloadAsNewSavegame()
	self.missionInfo:loadDefaults()
	g_careerScreen:startSavegame(self.missionInfo)
end

function MPLoadingScreen:onCancelSavegameLoading()
	self:cancelLoading()
	g_gui:showGui("CareerScreen")
end

function MPLoadingScreen:onSavegameLoaded(errorCode, savegameDirectory)
	if self.savegameLoadingDialogDelay > 0 then
		self.savegameLoadingDialogDelay = -1
	end

	if self.loadingDialog ~= nil then
		self.loadingDialog.target:close()
	end

	if errorCode == Savegame.ERROR_OK then
		self:loadGameRelatedData()

		local savegame = self.missionInfo

		if savegame.isValid then
			savegame:setSavegameDirectory(savegameDirectory)
		else
			savegame:setSavegameDirectory(nil)
		end

		if savegame.environmentXML == nil or not fileExists(savegame.environmentXML) then
			savegame.environmentXMLLoad = savegame.defaultEnvironmentXMLFilename
		else
			savegame.environmentXMLLoad = savegame.environmentXML
		end

		if savegame.vehiclesXML == nil or not fileExists(savegame.vehiclesXML) then
			savegame.vehiclesXMLLoad = savegame.defaultVehiclesXMLFilename
		else
			savegame.vehiclesXMLLoad = savegame.vehiclesXML
		end

		if savegame.placeablesXML == nil or not fileExists(savegame.placeablesXML) then
			savegame.placeablesXMLLoad = savegame.defaultPlaceablesXMLFilename
		else
			savegame.placeablesXMLLoad = savegame.placeablesXML
		end

		if savegame.itemsXML == nil or not fileExists(savegame.itemsXML) then
			savegame.itemsXMLLoad = savegame.defaultItemsXMLFilename
		else
			savegame.itemsXMLLoad = savegame.itemsXML
		end

		if savegame.aiSystemXML == nil or not fileExists(savegame.aiSystemXML) then
			savegame.aiSystemXMLLoad = nil
		else
			savegame.aiSystemXMLLoad = savegame.aiSystemXML
		end

		if savegame.onCreateObjectsXML == nil or not fileExists(savegame.onCreateObjectsXML) then
			savegame.onCreateObjectsXMLLoad = nil
		else
			savegame.onCreateObjectsXMLLoad = savegame.onCreateObjectsXML
		end

		if savegame.economyXML == nil or not fileExists(savegame.economyXML) then
			savegame.economyXMLLoad = nil
		else
			savegame.economyXMLLoad = savegame.economyXML
		end

		if savegame.farmlandXML == nil or not fileExists(savegame.farmlandXML) then
			savegame.farmlandXMLLoad = nil
		else
			savegame.farmlandXMLLoad = savegame.farmlandXML
		end

		if savegame.npcXML == nil or not fileExists(savegame.npcXML) then
			savegame.npcXMLLoad = nil
		else
			savegame.npcXMLLoad = savegame.npcXML
		end

		if savegame.missionsXML == nil or not fileExists(savegame.missionsXML) then
			savegame.missionsXMLLoad = nil
		else
			savegame.missionsXMLLoad = savegame.missionsXML
		end

		if savegame.farmsXML == nil or not fileExists(savegame.farmsXML) then
			savegame.farmsXMLLoad = nil
		else
			savegame.farmsXMLLoad = savegame.farmsXML
		end

		if savegame.playersXML == nil or not fileExists(savegame.playersXML) then
			savegame.playersXMLLoad = nil
		else
			savegame.playersXMLLoad = savegame.playersXML
		end

		if savegame.fieldsXML == nil or not fileExists(savegame.fieldsXML) then
			savegame.fieldsXMLLoad = nil
		else
			savegame.fieldsXMLLoad = savegame.fieldsXML
		end

		if savegame.densityMapHeightXML == nil or not fileExists(savegame.densityMapHeightXML) then
			savegame.densityMapHeightXMLLoad = nil
		else
			savegame.densityMapHeightXMLLoad = savegame.densityMapHeightXML
		end

		if savegame.treePlantXML == nil or not fileExists(savegame.treePlantXML) then
			savegame.treePlantXMLLoad = nil
		else
			savegame.treePlantXMLLoad = savegame.treePlantXML
		end

		if self.missionDynamicInfo.isMultiplayer then
			self:startServer()
		else
			self:startLocal()
		end
	elseif errorCode == Savegame.ERROR_DATA_CORRUPT then
		if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
			self:setStatusText("")
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_savegameCorrupt"),
				callback = self.onYesNoSavegameCorrupted,
				target = self,
				yesButton = g_i18n:getText("button_continue"),
				noButton = g_i18n:getText("button_cancel")
			})
		end
	elseif errorCode == Savegame.ERROR_LOAD_INVALID_USER then
		if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
			self:setStatusText("")
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_savegameInvalidUser"),
				callback = self.onYesNoSavegameCorrupted,
				target = self,
				yesButton = g_i18n:getText("button_continue"),
				noButton = g_i18n:getText("button_cancel")
			})
		end
	elseif errorCode == Savegame.ERROR_CLOUD_CONFLICT then
		if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
			self:setStatusText("")
			g_gui:showInfoDialog({
				text = g_i18n:getText("ui_savegameLoadCloudConflict"),
				callback = self.onOkSavegameCloudConflict,
				target = self
			})
		end
	elseif errorCode ~= Savegame.ERROR_CANCELLED then
		if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
			self:setStatusText("")
			g_gui:showInfoDialog({
				text = g_i18n:getText("ui_savegameLoadFailed"),
				callback = self.onOkSavegameLoadFailed,
				target = self
			})
		end
	elseif g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
		self:cancelLoading()
	end
end

function MPLoadingScreen:onSaveGameLoadingFinished(errorCode)
	if errorCode == Savegame.ERROR_OK then
		g_messageCenter:publish(MessageType.SAVEGAME_LOADED)

		if g_currentMission:getIsServer() then
			if g_currentMission.preSimulateTime > 0 then
				simulatePhysics(true)
				extraUpdatePhysics(g_currentMission.preSimulateTime / self.preSimulateSteps)

				self.actionTimerCount = 1
				self.preSimulateCount = self.preSimulateSteps - 1
			else
				self:onReadyToStart()
			end
		else
			self:onReadyToStart()
		end
	elseif errorCode == Savegame.ERROR_DATA_CORRUPT then
		if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_savegameCorrupt"),
				callback = self.onYesNoSavegameCorrupted,
				target = self,
				yesButton = g_i18n:getText("button_continue"),
				noButton = g_i18n:getText("button_cancel")
			})
		end
	elseif errorCode == Savegame.ERROR_LOAD_INVALID_USER then
		if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_savegameInvalidUser"),
				callback = self.onYesNoSavegameCorrupted,
				target = self,
				yesButton = g_i18n:getText("button_continue"),
				noButton = g_i18n:getText("button_cancel")
			})
		end
	elseif errorCode ~= Savegame.ERROR_CANCELLED then
		if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
			g_gui:showInfoDialog({
				text = g_i18n:getText("ui_savegameLoadFailed"),
				callback = self.onOkSavegameLoadFailed,
				target = self
			})
		end
	elseif g_gui:getIsGuiVisible() and g_gui.currentGuiName == "MPLoadingScreen" then
		self:cancelLoading()
	end
end

function MPLoadingScreen:onOkSavegameLoadFailed()
	self:cancelLoading()
end

function MPLoadingScreen:onOkSavegameCloudConflict()
	self:cancelLoading()
	g_gui:showGui("CareerScreen")
	self.savegameController:tryToResolveConflict(self.missionInfo.savegameIndex)
end

function MPLoadingScreen:onYesNoSavegameCorrupted(yes)
	if yes then
		self:cancelLoading()
		g_gui:showGui("MPLoadingScreen")
		self:reloadAsNewSavegame()
	else
		self:cancelLoading()
	end
end

function MPLoadingScreen:onFinishedReceivingDynamicData()
	if self.missionInfo.isValid then
		g_asyncTaskManager:addTask(function ()
			saveReadSavegameFinish("onSaveGameLoadingFinished", self)
		end)
	else
		self:onSaveGameLoadingFinished(Savegame.ERROR_OK)
	end
end

function MPLoadingScreen:onReadyToStart()
	if g_currentMission:canStartMission() then
		setCamera(g_defaultCamera)
		self.mpLoadingAnimation:setVisible(false)
		self.mpLoadingAnimationDone:setVisible(true)

		self.isCancel = false

		self:setButtonState(MPLoadingScreen.STATE_READY)

		self.loadingBar.absSize[1] = self.loadingBar.parent.absSize[1]

		self.loadingBarPercentage:setText("100%")

		if g_dedicatedServer ~= nil or GS_IS_MOBILE_VERSION or StartParams.getIsSet("autoStart") then
			self:onClickOk()
		end
	else
		self:setButtonState(MPLoadingScreen.STATE_WAIT_FOR_MISSION)
	end
end

function MPLoadingScreen:initializeLoading()
	g_gameStateManager:setGameState(GameState.LOADING)
	self:setMapTitleAndPreview()
	Object.resetObjectIds()
	g_asyncTaskManager:addTask(function ()
		if self.missionInfo:isa(FSCareerMissionInfo) then
			InitClientOnce()

			if #self.missionDynamicInfo.mods > 0 then
				if not GS_IS_CONSOLE_VERSION and not GS_PLATFORM_GGP then
					masterServerConnectFront = nil
					masterServerConnectBack = nil
					masterServerAddServer = nil
					masterServerAddServerModStart = nil
					masterServerAddServerMod = nil
					masterServerAddServerModEnd = nil
					masterServerRequestConnectionToServer = nil
					netConnect = nil
				end

				if not g_isPresentationVersion or g_isPresentationVersionDlcEnabled then
					table.sort(self.missionDynamicInfo.mods, MPLoadingScreen.modSortFunc)

					self.missionDynamicInfo.hasScriptsLoaded = false

					for _, modItem in ipairs(self.missionDynamicInfo.mods) do
						loadMod(modItem.modName, modItem.modDir, modItem.modFile, modItem.title)

						if modItem.hasScripts then
							self.missionDynamicInfo.hasScriptsLoaded = true
						end
					end
				end
			end
		end
	end)
	g_asyncTaskManager:addTask(function ()
		g_xmlManager:createSchemas()
	end)
	g_asyncTaskManager:addTask(function ()
		g_xmlManager:initSchemas()
	end)
	g_asyncTaskManager:addTask(function ()
		g_vehicleTypeManager:validateTypes()
		self:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.VEHICLE_VALIDATION)
	end)
	g_asyncTaskManager:addTask(function ()
		g_vehicleTypeManager:finalizeTypes()
	end)
	g_asyncTaskManager:addTask(function ()
		g_placeableTypeManager:validateTypes()
	end)
	g_asyncTaskManager:addTask(function ()
		g_placeableTypeManager:finalizeTypes()
	end)
	g_asyncTaskManager:addTask(function ()
		Vehicle.init()
		Placeable.init()
		g_specializationManager:initSpecializations()
		g_placeableSpecializationManager:initSpecializations()
		Vehicle.postInit()
		Placeable.postInit()
		g_specializationManager:postInitSpecializations()
		g_placeableSpecializationManager:postInitSpecializations()
		self:hitLoadingTarget(MPLoadingScreen.LOAD_TARGETS.SPECIALIZATIONS)
	end)
	g_asyncTaskManager:addTask(function ()
		g_xmlManager:initSchemas()
	end)
	g_asyncTaskManager:addTask(function ()
		g_constructionBrushTypeManager:initBrushTypes()
	end)
	g_asyncTaskManager:addTask(function ()
		HandTool.init()
	end)
	setCamera(0)
	self.loadFunction(self.missionCollaborators, self.missionInfo, self.missionDynamicInfo, self)
end

function MPLoadingScreen:setMapTitleAndPreview()
	local mapName = ""
	local mapPreview = self.mapSelectionPreview.overlay.filename

	if self.missionInfo ~= nil then
		if self.missionInfo.name then
			mapName = tostring(self.missionInfo.name)
		end

		local map = g_mapManager:getMapById(self.missionInfo.mapId)

		if map ~= nil then
			mapPreview = map.iconFilename

			if self.missionInfo:isa(FSCareerMissionInfo) then
				mapName = map.title
			end
		end
	end

	self.mapSelectionPreview:setImageFilename(mapPreview)
	self.mapNameText:setText(mapName)
end

function MPLoadingScreen:onServerInfoDetails(id, name, language, capacity, numPlayers, mapName, mapId, hasPassword, isLanServer, modTitles, modHashes, allowCrossPlay, platformId, password)
	if id == self.missionDynamicInfo.serverId then
		local missingMods = ""
		local numMissingsMods = 0

		for i = 1, table.getn(modHashes) do
			local modItem = g_modManager:getModByFileHash(modHashes[i])

			if modItem == nil then
				local parts = modTitles[i]:split(";")

				if missingMods:len() ~= 0 then
					missingMods = missingMods .. ", "
				end

				missingMods = missingMods .. parts[1]
				numMissingsMods = numMissingsMods + 1

				if numMissingsMods >= 4 then
					break
				end
			end
		end

		if numMissingsMods > 0 then
			local text = g_i18n:getText("ui_failedToConnectToGame")

			if g_deepLinkingInfo ~= nil then
				text = g_i18n:getText("ui_notAllModsAvailable")
				text = text .. "\n" .. missingMods
				g_deepLinkingInfo = nil
			end

			self:showFailedToConnectDialog(text)

			return
		end

		if not self.missionInfo:setMapId(mapId) then
			g_deepLinkingInfo = nil

			self:showFailedToConnectDialog()

			return
		end

		self.missionDynamicInfo.mods = {}

		for i = 1, table.getn(modHashes) do
			local modItem = g_modManager:getModByFileHash(modHashes[i])

			table.insert(self.missionDynamicInfo.mods, modItem)
		end

		g_deepLinkingInfo = nil

		self:setMapTitleAndPreview()
		masterServerRequestConnectionToServer(self.missionDynamicInfo.password, id, "onNatPunchSuceeded", "onNatPunchFailed", self)
	else
		Logging.warning("Invalid server id '%s' for server '%s'. Requested server id '%s'!", tostring(id), tostring(name), tostring(self.missionDynamicInfo.serverId))

		g_deepLinkingInfo = nil

		self:showFailedToConnectDialog()
	end
end

function MPLoadingScreen:showFailedToConnectDialog(text)
	g_gui:showConnectionFailedDialog({
		text = text or g_i18n:getText("ui_failedToConnectToGame"),
		callback = g_connectionFailedDialog.onOkCallback,
		target = g_connectionFailedDialog,
		args = {
			"JoinGameScreen"
		}
	})
	self:cleanup()
end

function MPLoadingScreen:onServerInfoDetailsFailed()
	g_deepLinkingInfo = nil

	self:showFailedToConnectDialog()
end

function MPLoadingScreen:onNatPunchSuceeded(ip, port, platformSessionId, relayHeader)
	print("nat punch suceeded")

	self.missionDynamicInfo.serverAddress = ip
	self.missionDynamicInfo.serverPort = port
	self.missionDynamicInfo.platformSessionId = platformSessionId
	self.missionDynamicInfo.relayHeader = relayHeader

	self:initializeLoading()
end

function MPLoadingScreen:onNatPunchFailed(reason)
	ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, "JoinGameScreen")
	self:cleanup()
end

function MPLoadingScreen:onMasterServerConnectionReady()
	if self.missionDynamicInfo.isClient then
		masterServerRequestConnectionToServer(self.missionDynamicInfo.password, self.missionDynamicInfo.serverId, "onNatPunchSuceeded", "onNatPunchFailed", self)

		return
	end

	g_masterServerConnection:setCallbackTarget(self)
	self:onCreatingGame()
	log("STARTING MP Game")
	masterServerAddServerModStart()

	for i = 1, table.getn(self.missionDynamicInfo.mods) do
		local modItem = self.missionDynamicInfo.mods[i]

		assert(modItem.fileHash ~= nil and modItem.isSelectable)

		local modTitleStr = ServerDetailScreen.packModInfo(modItem.title, modItem.version, modItem.author, modItem.modName)

		log("    adding mod", modTitleStr, modItem.fileHash)
		masterServerAddServerMod(modTitleStr, modItem.fileHash)
	end

	masterServerAddServerModEnd()

	local map = g_mapManager:getMapById(self.missionInfo.mapId)

	masterServerAddServer(self.missionDynamicInfo.serverName, self.missionDynamicInfo.password, self.missionDynamicInfo.capacity, 0, map.title, self.missionInfo.mapId, self.missionDynamicInfo.allowOnlyFriends, g_createGameScreen.usePendingInvites, self.missionDynamicInfo.allowCrossPlay)
	self:initializeLoading()
end

function MPLoadingScreen:onMasterServerConnectionFailed(reason)
	assert(g_currentMission == nil)
	saveReadSavegameFinish("", self)
	self:cleanup()

	local nextScreen = "CreateGameScreen"

	if self.isClient then
		nextScreen = "MultiplayerScreen"
	end

	ConnectionFailedDialog.showMasterServerConnectionFailedReason(reason, nextScreen)
end

function MPLoadingScreen:cleanup()
	self:unloadGameRelatedData()
	g_masterServerConnection:disconnectFromMasterServer()
	g_asyncTaskManager:flushAllTasks()
	g_asyncTaskManager:flushAllTasks()

	if g_client ~= nil then
		g_client:delete()

		g_client = nil
	end

	if g_server ~= nil then
		g_server:delete()

		g_server = nil
	else
		g_connectionManager:shutdownAll()
	end
end

function MPLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
	self.missionInfo = missionInfo
	self.missionDynamicInfo = missionDynamicInfo
	self.preSimulateCount = -1
	self.doLoad = false
end

function MPLoadingScreen:setGameplayHint(currentGameplayHints, id)
	if currentGameplayHints[id] ~= nil then
		local text = string.gsub(currentGameplayHints[id], "$CURRENCY_SYMBOL", g_i18n:getCurrencySymbol(true))

		self.gameplayHintText:setText(text)
		self.tipStateBox:setPageIndex(id)
	end
end

function MPLoadingScreen.modSortFunc(mod1, mod2)
	if mod1.isDLC == mod2.isDLC then
		return string.lower(mod1.modName) < string.lower(mod2.modName)
	elseif mod1.isDLC then
		return true
	elseif mod2.isDLC then
		return false
	end
end

function MPLoadingScreen:setStatusText(text)
	self.loadingStatusText:setText(text)
end

function MPLoadingScreen:setButtonState(state)
	self.state = state
	local isStartButtonVisible = false
	local isCancelButtonVisible = false

	if self.state == MPLoadingScreen.STATE_CONNECTING then
		isCancelButtonVisible = true

		self:setStatusText(g_i18n:getText("ui_connectingPleaseWait"))
	elseif self.state == MPLoadingScreen.STATE_LOADING then
		self:setStatusText(g_i18n:getText("ui_gameIsLoadingPleaseWait"))

		if self.missionDynamicInfo.isMultiplayer and self.isClient then
			isCancelButtonVisible = true

			self:setStatusText(g_i18n:getText("ui_synchronizingWithOtherPlayers"))
		end
	elseif self.state == MPLoadingScreen.STATE_READY then
		self:setStatusText("")

		isStartButtonVisible = true

		FocusManager:setFocus(self.buttonOkPC)
	elseif self.state == MPLoadingScreen.STATE_PORT_TESTING then
		isCancelButtonVisible = true

		self:setStatusText(g_i18n:getText("ui_testingPort"))
	elseif self.state == MPLoadingScreen.STATE_SYNCHRONIZING or self.state == MPLoadingScreen.STATE_LOADING then
		self:setStatusText(g_i18n:getText("ui_gameIsLoadingPleaseWait"))

		if self.missionDynamicInfo.isMultiplayer and self.isClient then
			isCancelButtonVisible = true
		end
	elseif self.state == MPLoadingScreen.STATE_WAIT_FOR_ACCEPT then
		self:setStatusText(g_i18n:getText("ui_waitingForAccept"))

		isCancelButtonVisible = true
	end

	self.buttonOkPC:setVisible(isStartButtonVisible)
	self.buttonDeletePC:setVisible(isCancelButtonVisible)
end

function MPLoadingScreen:hitLoadingTarget(target)
	while self.loadTargets[self.loadTarget] ~= nil and self.loadTargets[self.loadTarget] <= target do
		self.loadTarget = self.loadTarget + 1
	end

	self.loadPercentage = target
end
