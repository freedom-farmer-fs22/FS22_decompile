User = {}
local User_mt = Class(User)

function User.new(customMt)
	local self = setmetatable({}, customMt or User_mt)
	self.id = -1
	self.connection = nil
	self.state = FSBaseMission.USER_STATE_LOADING
	self.nickname = ""
	self.languageIndex = 1
	self.isMasterUser = false
	self.connectedTime = 0
	self.uniqueUserId = ""
	self.platformUserId = 0
	self.platformId = 0
	self.platformSessionId = ""
	self.financesVersionCounter = -1
	self.financeUpdateSendTime = 0
	self.playerStyle = nil
	self.unmutedVoiceVolume = 1
	self.blockStates = {}
	self.sentUserBlocked = nil

	return self
end

function User:readStream(streamId, connection)
	self.id = streamReadInt32(streamId)
	self.nickname = streamReadString(streamId)
	self.languageIndex = streamReadUInt8(streamId)
	self.isMasterUser = streamReadBool(streamId)
	local playtime = streamReadInt32(streamId)
	self.connectedTime = g_currentMission.time - playtime
	self.uniqueUserId = streamReadString(streamId)
	self.platformUserId = streamReadString(streamId)
	self.platformId = streamReadUInt8(streamId)
	self.platformSessionId = streamReadString(streamId)
end

function User:writeStream(streamId, connection)
	streamWriteInt32(streamId, self.id)
	streamWriteString(streamId, self.nickname)
	streamWriteUInt8(streamId, self.languageIndex)
	streamWriteBool(streamId, self.isMasterUser)
	streamWriteInt32(streamId, g_currentMission.time - self.connectedTime)
	streamWriteString(streamId, self.uniqueUserId)
	streamWriteString(streamId, self.platformUserId)
	streamWriteUInt8(streamId, self.platformId)
	streamWriteString(streamId, self.platformSessionId)
end

function User:setId(id)
	self.id = id
end

function User:getId()
	return self.id
end

function User:setState(state)
	self.state = state
end

function User:getState()
	return self.state
end

function User:setConnection(connection)
	self.connection = connection
end

function User:getConnection()
	return self.connection
end

function User:setNickname(name)
	self.nickname = name
end

function User:getNickname()
	if self:getIsBlocked() and not getPlatformIdsAreCompatible(self.platformId, getPlatformId()) then
		return string.format("Player %d", self.id)
	end

	return self.nickname
end

function User:setLanguageIndex(index)
	self.languageIndex = index
end

function User:getLanguageIndex()
	return self.languageIndex
end

function User:setIsMasterUser(isMasterUser)
	self.isMasterUser = isMasterUser
end

function User:getIsMasterUser()
	return self.isMasterUser
end

function User:setConnectedTime(connectedTime)
	self.connectedTime = connectedTime
end

function User:getConnectedTime(connectedTime)
	return self.connectedTime
end

function User:setUniqueUserId(uniqueUserId)
	self.uniqueUserId = uniqueUserId
end

function User:getUniqueUserId()
	return self.uniqueUserId
end

function User:setPlatformUserId(platformUserId)
	self.platformUserId = platformUserId
end

function User:getPlatformUserId()
	return self.platformUserId
end

function User:setPlatformId(platformId)
	self.platformId = platformId
end

function User:getPlatformId()
	return self.platformId
end

function User:setPlatformSessionId(platformSessionId)
	self.platformSessionId = platformSessionId
end

function User:getPlatformSessionId()
	return self.platformSessionId
end

function User:setFinancesVersionCounter(financesVersionCounter)
	self.financesVersionCounter = financesVersionCounter
end

function User:getFinancesVersionCounter()
	return self.financesVersionCounter
end

function User:setFinanceUpdateSendTime(financeUpdateSendTime)
	self.financeUpdateSendTime = financeUpdateSendTime
end

function User:getFinanceUpdateSendTime()
	return self.financeUpdateSendTime
end

function User:setPlayerStyle(playerStyle)
	self.playerStyle = playerStyle
end

function User:getPlayerStyle()
	return self.playerStyle
end

function User:getIsBlocked()
	return getIsUserBlocked(self.uniqueUserId, self.platformUserId, self.platformId)
end

function User:getAllowVoiceCommunication()
	return getAllowVoiceCommunicationWithUser(self.uniqueUserId, self.platformUserId, self.platformId) == AsyncResult.YES
end

function User:getAllowTextCommunication()
	return getAllowTextCommunicationWithUser(self.uniqueUserId, self.platformUserId, self.platformId) == AsyncResult.YES
end

function User:block()
	setIsUserBlocked(self.uniqueUserId, self.platformUserId, self.platformId, true, self.nickname)
	self:updateSentUserBlockedState()
end

function User:unblock()
	setIsUserBlocked(self.uniqueUserId, self.platformUserId, self.platformId, false, "")
	self:updateSentUserBlockedState()
end

function User:report(reason)
	reportUser(self.uniqueUserId, self.platformUserId, self.platformId, reason)
end

function User:getVoiceVolume()
	return VoiceChatUtil.getUserVolume(self.uniqueUserId)
end

function User:setVoiceVolume(volume)
	VoiceChatUtil.setUserVolume(self.uniqueUserId, volume)
end

function User:getVoiceMuted()
	if self.id == g_currentMission.playerUserId then
		return voiceChatGetRecordingMode() == VoiceChatRecordingMode.MUTED
	else
		return self.isMuted
	end
end

function User:setVoiceMuted(isMuted)
	if self.id == g_currentMission.playerUserId then
		if voiceChatGetRecordingMode() == VoiceChatRecordingMode.MUTED then
			voiceChatSetRecordingMode(g_gameSettings:getValue(SettingsModel.SETTING.VOICE_MODE))
		else
			voiceChatSetRecordingMode(VoiceChatRecordingMode.MUTED)
		end
	elseif self.isMuted ~= isMuted then
		self.isMuted = isMuted

		if isMuted then
			self.unmutedVoiceVolume = VoiceChatUtil.getUserVolume(self.uniqueUserId)

			VoiceChatUtil.setUserVolume(self.uniqueUserId, 0)
		else
			VoiceChatUtil.setUserVolume(self.uniqueUserId, self.unmutedVoiceVolume)
		end
	end
end

function User:updateSentUserBlockedState()
	local isBlocked = self:getIsBlocked()

	if isBlocked ~= self.sentUserBlocked then
		self.sentUserBlocked = isBlocked

		UserBlockEvent.sendEvent(self:getId(), isBlocked)
	end

	return nil
end

function User:setIsBlockedBy(user, isBlocked)
	self.blockStates[user:getUniqueUserId()] = isBlocked

	voiceChatSetUserPairBlocked(self:getUniqueUserId(), user:getUniqueUserId(), isBlocked)
end

function User:getIsBlockedBy(user)
	return self.blockStates[user:getUniqueUserId()] ~= false
end
