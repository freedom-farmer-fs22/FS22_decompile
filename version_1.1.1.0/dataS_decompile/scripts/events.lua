function mouseEvent(posX, posY, isDown, isUp, button)
	if g_currentTest ~= nil then
		g_currentTest.mouseEvent(posX, posY, isDown, isUp, button)

		return
	end

	Input.updateMouseButtonState(button, isDown)
	g_inputBinding:mouseEvent(posX, posY, isDown, isUp, button)

	if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
		g_gui:mouseEvent(posX, posY, isDown, isUp, button)
	end

	if g_currentMission ~= nil and g_currentMission.isLoaded then
		g_currentMission:mouseEvent(posX, posY, isDown, isUp, button)
	end

	g_lastMousePosX = posX
	g_lastMousePosY = posY

	if button <= Input.MOUSE_BUTTON_LEFT then
		touchEvent(posX, posY, isDown, isUp, TouchHandler.MOUSE_TOUCH_ID)
	end
end

function touchEvent(posX, posY, isDown, isUp, touchId)
	if g_touchHandler ~= nil then
		g_touchHandler:onTouchEvent(posX, posY, isDown, isUp, touchId)
	end

	if g_inputBinding ~= nil then
		g_inputBinding:keyEvent(posX, posY, isDown, isUp, touchId)
	end
end

function keyEvent(unicode, sym, modifier, isDown)
	if g_currentTest ~= nil then
		g_currentTest.keyEvent(unicode, sym, modifier, isDown)

		return
	end

	Input.updateKeyState(sym, isDown)
	g_inputBinding:keyEvent(unicode, sym, modifier, isDown)

	if g_currentMission == nil or g_currentMission:getAllowsGuiDisplay() then
		g_gui:keyEvent(unicode, sym, modifier, isDown)
	end

	if g_currentMission ~= nil and g_currentMission.isLoaded then
		g_currentMission:keyEvent(unicode, sym, modifier, isDown)
	end
end

function onUserSignedOut()
	g_gamepadSigninScreen.forceShowSigninGui = true

	forceEndFrameRepeatMode()

	if g_currentMission ~= nil then
		if g_currentMission.isMissionStarted then
			g_currentMission:pauseGame()
			g_masterServerConnection:disconnectFromMasterServer()
			g_gui:showGui("GamepadSigninScreen")
		else
			OnInGameMenuMenu(true)
		end
	else
		g_masterServerConnection:disconnectFromMasterServer()
		g_connectionManager:shutdownAll()
		g_gui:showGui("GamepadSigninScreen")
	end
end

function finishedUserProfileSync()
	if GS_PLATFORM_XBOX then
		loadUserSettings(g_gameSettings)
		g_messageCenter:publish(MessageType.USER_PROFILE_CHANGED)
	end
end

function onWaitForPendingGameSession()
	if g_currentMission == nil then
		if g_startupScreen == nil then
			g_skipStartupScreen = true
		else
			g_startupScreen:onStartupEnd()
		end
	else
		OnInGameMenuMenu()
	end

	g_gui:showInfoDialog({
		text = g_i18n:getText("ui_waitForPendingGameSession"),
		okText = g_i18n:getText("button_cancel")
	})
end

function onMultiplayerInviteSent()
	local mission = g_currentMission

	if mission ~= nil then
		if not mission.missionDynamicInfo.isMultiplayer then
			Logging.info("Switching to multiplayer game")
			mission.savegameController:saveSavegame(mission.missionInfo)

			mission.savegameController.onSaveCompleteCallback = onMultiplayerInviteSaveCompleteCallback

			mission.inGameMenu:startSavingGameDisplay()

			g_multiplayerInviteSentData = {
				savegameIndex = mission.missionInfo.savegameIndex
			}

			return true
		end
	else
		onMultiplayerInviteStartSavegame()

		return true
	end

	return false
end

function onMultiplayerInviteSaveCompleteCallback(_, errorCode)
	local mission = g_currentMission

	function mission.savegameController.onSaveCompleteCallback()
	end

	mission.inGameMenu:notifySaveComplete()
	g_gui:showMessageDialog({
		visible = false
	})

	if errorCode == Savegame.ERROR_OK then
		OnInGameMenuMenu()
		onMultiplayerInviteStartSavegame(g_multiplayerInviteSentData.savegameIndex)

		g_multiplayerInviteSentData = nil
	else
		local function continue(yes)
			if yes then
				onMultiplayerInviteStartSavegame(nil)
			end
		end

		g_gui:showYesNoDialog({
			text = g_i18n:getText("ui_savingFailedContinueWithoutSaving"),
			callback = continue,
			yesButton = g_i18n:getText("button_continue"),
			noButton = g_i18n:getText("button_cancel")
		})
	end
end

function onMultiplayerInviteStartSavegame(savegameIndex)
	g_gui:setIsMultiplayer(true)
	g_gui:showGui("CareerScreen")

	if savegameIndex ~= nil then
		g_careerScreen.selectedIndex = savegameIndex
		local savegameController = g_careerScreen.savegameController
		local savegame = savegameController:getSavegame(g_careerScreen.selectedIndex)
		g_careerScreen.currentSavegame = savegame

		g_careerScreen:onStartAction()

		if savegame == SavegameController.NO_SAVEGAME or not savegame.isValid then
			return
		end

		if g_gui.currentGuiName == "ModSelectionScreen" then
			g_modSelectionScreen:onClickOk()
		end
	end
end

function onRemovedFromInvite()
	if g_currentMission ~= nil then
		Logging.info("You have been uninvited by the host")
		OnInGameMenuMenu()
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_uninvited")
		})
	end
end

local function onOkSigninAccept()
	g_gamepadSigninScreen.forceShowSigninGui = true

	g_gui:showGui("GamepadSigninScreen")
end

function acceptedGameInvite(platformServerId, requestUserName)
	g_gui:closeDialogByName("InfoDialog")

	if g_currentMission ~= nil then
		OnInGameMenuMenu()
	end

	if Platform.isXbox and (g_gui.currentGuiName == "GamepadSigninScreen" or not g_isSignedIn) then
		g_tempDeepLinkingInfo = {
			platformServerId = platformServerId,
			requestUserName = requestUserName
		}
	elseif Platform.isXbox and requestUserName ~= "" and g_gameSettings:getValue(GameSettings.SETTING.ONLINE_PRESENCE_NAME) ~= requestUserName then
		g_tempDeepLinkingInfo = {
			platformServerId = platformServerId,
			requestUserName = requestUserName
		}

		g_gui:showInfoDialog({
			text = string.format(g_i18n:getText("dialog_signinWithUserToAcceptInvite"), requestUserName),
			callback = onOkSigninAccept
		})
	elseif Platform.isXbox or Platform.isPlaystation then
		if PlatformPrivilegeUtil.checkMultiplayer(acceptedGameInvitePerformConnect, nil, platformServerId, 30000) then
			acceptedGameInvitePerformConnect(platformServerId)
		end
	else
		acceptedGameInvitePerformConnect(platformServerId)
	end
end

function acceptedGameInvitePerformConnect(platformServerId)
	connectToServer(platformServerId)
end

function acceptedGameCreate()
	if g_currentMission ~= nil then
		OnInGameMenuMenu()
	end

	g_createGameScreen.usePendingInvites = true

	g_gui:setIsMultiplayer(true)
	g_gui:showGui("CareerScreen")
end

function onDeepLinkingFailed()
	g_deepLinkingInfo = nil
	g_showDeeplinkingFailedMessage = true
end

function onFriendListChanged()
	g_masterServerConnection:reconnectToMasterServer()
end

function onBlockedListChanged()
end

local hasWindowFocus = true

function notifyWindowGainedFocus()
	hasWindowFocus = true
end

function notifyWindowLostFocus()
	hasWindowFocus = false
end

function getHasWindowFocus()
	return hasWindowFocus
end

function notifyAppSuspended()
	g_appIsSuspended = true

	g_messageCenter:publish(MessageType.APP_SUSPENDED)
end

function notifyAppResumed()
	g_appIsSuspended = false

	g_messageCenter:publish(MessageType.APP_RESUMED)
end
