g_isConsoleSimulationActive = false

if g_isConsoleSimulationActive then
	print("--> Console Simulator active!")

	forcedNetworkError = nil
	forcedMPAvailability = nil
	colorGradingActive = false
	forcedNewDLCs = false
	forcedStoreHaveDLCsChanged = false
	local achievementsAvailable = true
	local allSpeakersTalking = false
	local oldKeyEvent = keyEvent

	function keyEvent(unicode, sym, modifier, isDown)
		if isDown then
			if sym == Input.KEY_1 then
				forcedNetworkError = "ERROR"
			elseif sym == Input.KEY_2 then
				forcedNetworkError = nil
			elseif sym == Input.KEY_3 then
				forcedMPAvailability = nil
			elseif sym == Input.KEY_4 then
				forcedMPAvailability = MultiplayerAvailability.AVAILABILITY_UNKNOWN
			elseif sym == Input.KEY_5 then
				forcedMPAvailability = MultiplayerAvailability.NOT_AVAILABLE
			elseif sym == Input.KEY_6 then
				forcedMPAvailability = MultiplayerAvailability.NO_PRIVILEGES
			elseif sym == Input.KEY_7 then
				finishedUserProfileSync()
			elseif sym == Input.KEY_8 then
				onActiveUserChanged(true)
			elseif sym == Input.KEY_9 then
				g_currentMission:onMasterServerConnectionFailed(MasterServerConnection.FAILED_CONNECTION_LOST)
			elseif sym == Input.KEY_0 then
				forcedNewDLCs = true
				forcedStoreHaveDLCsChanged = true
			elseif sym == Input.KEY_KP_1 then
				achievementsAvailable = not achievementsAvailable
			elseif sym == Input.KEY_KP_2 then
				allSpeakersTalking = not allSpeakersTalking
			end
		end

		oldKeyEvent(unicode, sym, modifier, isDown)
	end

	local oldGetNetworkError = getNetworkError

	function getNetworkError()
		return forcedNetworkError or oldGetNetworkError()
	end

	local oldCheckForNewDlcs = checkForNewDlcs

	function checkForNewDlcs()
		local retValue = forcedNewDLCs or oldCheckForNewDlcs()

		return retValue
	end

	local oldStoreHaveDlcsChanged = storeHaveDlcsChanged

	function storeHaveDlcsChanged()
		local retValue = forcedStoreHaveDLCsChanged or oldStoreHaveDlcsChanged()

		return retValue
	end

	local oldStartFrameRepeatMode = startFrameRepeatMode

	function startFrameRepeatMode()
		return oldStartFrameRepeatMode()
	end

	local oldEndFrameRepeatMode = endFrameRepeatMode

	function endFrameRepeatMode()
		return oldEndFrameRepeatMode()
	end

	local oldForceEndFrameRepeatMode = forceEndFrameRepeatMode

	function forceEndFrameRepeatMode()
		oldForceEndFrameRepeatMode()
	end

	local oldGetMultiplayerAvailability = getMultiplayerAvailability

	function getMultiplayerAvailability()
		if forcedMPAvailability ~= nil then
			return forcedMPAvailability, false
		end

		return oldGetMultiplayerAvailability()
	end

	function imeIsSupported()
		log("[console debug] Reporting IME as available")

		return true
	end

	function imeAbort()
		log("[console debug] IME aborted")
	end

	function imeOpen(text, title, description, placeholder, keyboardType, maxCharacters)
		log("[console debug] Opened IME with text=", text, "; title=", title, "; description=", description, "; placeholder=", placeholder, "; keyboardType=", keyboardType, "; maxCharacters=", maxCharacters)

		if title == nil then
			log("Error: IME title must be set")
		end

		if description == nil then
			log("Error: IME description must be set")
		end

		if placeholder == nil then
			log("Error: IME placeholder must be set")
		end

		log("[console debug] IME will be closed directly with string 'hello console world'")

		return true
	end

	function imeIsComplete()
		return true, false
	end

	function imeGetLastString()
		return "hello console world"
	end

	function areAchievementsAvailable()
		return achievementsAvailable
	end

	function openMpFriendInvitation(num, max)
		log("[console debug] Open friend invitation. Currently online", num, "capacity", max)
	end

	function connectToInvite(platformServerId, requestUserName)
		acceptedGameInvite(platformServerId, requestUserName)
	end

	addConsoleCommand("gsDebugAcceptInvite", "Debug console invitation", "connectToInvite", nil)
end
