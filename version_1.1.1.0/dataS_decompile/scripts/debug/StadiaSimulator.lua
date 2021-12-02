g_isStadiaSimulationActive = false
local isHDRActive = false
local hasRecordingDevice = false

if g_isStadiaSimulationActive then
	print("--> Stadia Simulator active!")

	local activeGamepadIndex = 0
	local oldGetNumOfGamepads = getNumOfGamepads
	local oldGetGamepadId = getGamepadId
	local oldGetGamepadButtonLabel = getGamepadButtonLabel
	local oldGetGamepadName = getGamepadName
	local oldGetInputButton = getInputButton
	local oldGetGamepadAxisLabel = getGamepadAxisLabel
	local oldGetInputAxis = getInputAxis
	local oldKeyEvent = keyEvent

	function keyEvent(unicode, sym, modifier, isDown)
		if isDown then
			if sym == Input.KEY_1 then
				onMultiplayerInviteSent()
			end

			if sym == Input.KEY_2 then
				onWaitForPendingGameSession()
			end

			if sym == Input.KEY_3 then
				onRemovedFromInvite()
			end

			if sym == Input.KEY_4 then
				acceptedGameInvite()
			end

			if sym == Input.KEY_5 then
				isHDRActive = not isHDRActive
			end

			if sym == Input.KEY_6 then
				hasRecordingDevice = not hasRecordingDevice
			end

			if sym == Input.KEY_7 then
				activeGamepadIndex = activeGamepadIndex + 1

				if oldGetNumOfGamepads() <= activeGamepadIndex then
					activeGamepadIndex = 0
				end

				log("-------------------------CHANGED ACTIVE GAMEPAD")
			end
		end

		oldKeyEvent(unicode, sym, modifier, isDown)
	end

	function getHdrAvailable()
		return isHDRActive
	end

	function getHasRecordingDevice()
		return hasRecordingDevice
	end

	function getNumOfGamepads()
		return 1
	end

	function getGamepadId(deviceIndex)
		return oldGetGamepadId(activeGamepadIndex)
	end

	function getGamepadButtonLabel(buttonIndex, deviceIndex)
		return oldGetGamepadButtonLabel(buttonIndex, activeGamepadIndex)
	end

	function getGamepadName(deviceIndex)
		return oldGetGamepadName(activeGamepadIndex)
	end

	function getInputButton(buttonIndex, deviceIndex)
		return oldGetInputButton(buttonIndex, activeGamepadIndex)
	end

	function getGamepadAxisLabel(axisIndex, deviceIndex)
		return oldGetGamepadAxisLabel(axisIndex, activeGamepadIndex)
	end

	function getInputAxis(axisIndex, deviceIndex)
		return oldGetInputAxis(axisIndex, activeGamepadIndex)
	end
end
