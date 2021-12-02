VoiceChatUtil = {
	MODE = {
		PUSH_TO_TALK = 3,
		VOICE_ACTIVITY = 2,
		DISABLED = 1
	},
	setOutputVolume = function (volume)
		voiceChatSetMasterVolume(volume)
	end,
	getOutputVolume = function ()
		return voiceChatGetMasterVolume()
	end,
	setInputVolume = function (volume)
		voiceChatSetRecordingVolume(volume)
	end,
	getInputVolume = function ()
		return voiceChatGetRecordingVolume()
	end
}

function VoiceChatUtil.setInputMode(mode)
	if mode == VoiceChatUtil.MODE.DISABLED then
		voiceChatSetRecordingMode(VoiceChatRecordingMode.DISABLED)
	elseif mode == VoiceChatUtil.MODE.VOICE_ACTIVITY then
		voiceChatSetRecordingMode(VoiceChatRecordingMode.AUTOMATIC)
	elseif mode == VoiceChatUtil.MODE.PUSH_TO_TALK then
		voiceChatSetRecordingMode(VoiceChatRecordingMode.MUTED)
	end
end

function VoiceChatUtil.getInputMode()
	if VoiceChatUtil.getIsVoiceRestricted() then
		return VoiceChatUtil.MODE.DISABLED
	end

	return g_gameSettings:getValue(SettingsModel.SETTING.VOICE_MODE)
end

function VoiceChatUtil.setIsPushToTalkPressed(pressed)
	if g_currentMission ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer and VoiceChatUtil.getInputMode() == VoiceChatUtil.MODE.PUSH_TO_TALK then
		if pressed then
			voiceChatSetRecordingMode(VoiceChatRecordingMode.ALWAYS)
		else
			voiceChatSetRecordingMode(VoiceChatRecordingMode.MUTED)
		end
	end
end

function VoiceChatUtil.setUserVolume(uuid, volume)
	voiceChatSetUserVolume(uuid, volume)
end

function VoiceChatUtil.getUserVolume(uuid)
	return voiceChatGetUserVolume(uuid)
end

function VoiceChatUtil.getIsSpeakerActive(uuid)
	return voiceChatGetConnectionStatus(uuid) == VoiceChatConnectionStatus.ACTIVE
end

function VoiceChatUtil.getHasRecordingDevice()
	if Platform.isStadia then
		return voiceChatGetHasRecordingDevice()
	else
		return true
	end
end

function VoiceChatUtil.getIsVoiceRestricted()
	return not getAllowVoiceCommunication(false)
end

function VoiceChatUtil.showVoiceRestrictedPopup()
	getAllowVoiceCommunication(true)
end
