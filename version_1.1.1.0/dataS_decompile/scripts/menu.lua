function OnLoadingScreen(missionCollaborators, missionInfo, missionDynamicInfo, loadingScreen)
	local modName = Utils.getModNameAndBaseDirectory(missionInfo.scriptFilename)

	source(missionInfo.scriptFilename, modName)

	if modName ~= nil and ClassUtil.getClassModName(missionInfo.scriptClass) ~= modName then
		print("Error: mission class " .. missionInfo.scriptClass .. " does not match expected mod name " .. modName)
		OnInGameMenuMenu()

		return
	end

	local missionClass = ClassUtil.getClassObject(missionInfo.scriptClass)

	if missionClass ~= nil then
		g_asyncTaskManager:addTask(function ()
			if g_server == nil and g_client == nil then
				return
			end

			g_currentMission = missionClass.new(missionInfo.baseDirectory, nil, missionCollaborators)

			g_masterServerConnection:setCallbackTarget(g_currentMission)
		end)
		g_asyncTaskManager:addTask(function ()
			if g_server == nil and g_client == nil then
				return
			end

			g_currentMission:initialize()
			g_currentMission:setLoadingScreen(loadingScreen)
		end)
		g_asyncTaskManager:addTask(function ()
			if g_server == nil and g_client == nil then
				return
			end

			g_currentMission:setMissionInfo(missionInfo, missionDynamicInfo)
		end)
	else
		print("Error: mission class " .. missionInfo.scriptClass .. " could not be found.")
		OnInGameMenuMenu()

		return
	end

	g_asyncTaskManager:addTask(function ()
		if g_server == nil and g_client == nil then
			return
		end

		if not g_currentMission.cancelLoading then
			if missionDynamicInfo.isMultiplayer then
				if missionDynamicInfo.isClient then
					g_client:setNetworkListener(g_currentMission)
					g_client:start(missionDynamicInfo.serverAddress, missionDynamicInfo.serverPort, missionDynamicInfo.relayHeader)
					g_masterServerConnection:disconnectFromMasterServer()
				else
					g_server:setNetworkListener(g_currentMission)
					g_client:setNetworkListener(g_currentMission)
				end
			else
				g_server:setNetworkListener(g_currentMission)
				g_client:setNetworkListener(g_currentMission)
				g_server:startLocal()
			end

			if g_server ~= nil then
				g_server:init()
			end

			if not missionDynamicInfo.isMultiplayer or not missionDynamicInfo.isClient then
				g_client:startLocal()
			end
		end
	end)
end

function OnInGameMenuMenu(goToSignIn, wasNetworkError)
	saveReadSavegameFinish("", nil)
	startFrameRepeatMode()
	setPresenceMode(PresenceModes.PRESENCE_IDLE)

	if g_currentMission ~= nil then
		g_currentMission.cancelLoading = true
	end

	cancelAllStreamedI3DFiles()
	cancelAllStreamedI3DFiles()
	g_asyncTaskManager:flushAllTasks()
	g_asyncTaskManager:flushAllTasks()
	setStreamLowPriorityI3DFiles(true)

	if g_currentMission ~= nil and g_currentMission.missionDynamicInfo ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer then
		netSetIsEventProcessingEnabled(true)
	end

	g_masterServerConnection:disconnectFromMasterServer()
	g_masterServerConnection:setCallbackTarget(nil)

	if g_client ~= nil then
		g_client:stop()
	end

	if g_server ~= nil then
		g_server:stop()
	end

	local isCareer = false
	local goToMainMenu = false

	if g_currentMission ~= nil then
		if g_currentMission.missionInfo ~= nil then
			isCareer = g_currentMission.missionInfo:isa(FSCareerMissionInfo)

			if g_currentMission.missionInfo:isa(FSCareerMissionInfo) then
				isCareer = false

				if false then
					isCareer = true
				end
			end
		end
	else
		goToMainMenu = true
	end

	local hasScriptsLoaded = g_currentMission ~= nil and g_currentMission.missionDynamicInfo ~= nil and g_currentMission.missionDynamicInfo.hasScriptsLoaded

	if g_currentMission ~= nil then
		g_gui:showGui("")
		g_currentMission:delete()
	end

	g_currentMission = nil
	g_server = nil
	g_client = nil

	g_connectionManager:shutdownAll()
	g_i3DManager:clearEntireSharedI3DFileCache(g_isDevelopmentVersion)
	g_mpLoadingScreen:unloadGameRelatedData()

	if g_createGameScreen ~= nil then
		g_createGameScreen:removePortMapping()
	end

	g_gameStateManager:setGameState(GameState.MENU_MAIN)
	forceEndFrameRepeatMode()

	if wasNetworkError and GS_PLATFORM_PLAYSTATION then
		ConnectionFailedDialog.showMasterServerConnectionFailedReason(MasterServerConnection.FAILED_CONNECTION_LOST, "MainScreen")
	elseif isCareer then
		if next(g_modIsLoaded) ~= nil then
			if hasScriptsLoaded then
				RestartManager:setStartScreen(RestartManager.START_SCREEN_MAIN)
				doRestart(false, "")

				return
			else
				reloadDlcsAndMods()
			end
		end

		if goToSignIn then
			g_gui:showGui("GamepadSigninScreen")
		else
			g_gui:showGui("MainScreen")
		end
	elseif not goToMainMenu then
		g_gameSettings:saveToXMLFile(g_savegameXML)

		if goToSignIn then
			g_gui:showGui("GamepadSigninScreen")
		else
			g_gui:showGui("MainScreen")
		end
	else
		g_gui:showGui("MainScreen")
	end

	g_inputBinding:setShowMouseCursor(true)
	simulatePhysics(false)
end
