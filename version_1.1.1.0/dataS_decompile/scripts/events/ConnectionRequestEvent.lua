ConnectionRequestEvent = {}
local ConnectionRequestEvent_mt = Class(ConnectionRequestEvent, Event)

InitStaticEventClass(ConnectionRequestEvent, "ConnectionRequestEvent", EventIds.EVENT_CONNECTION_REQUEST)

function ConnectionRequestEvent.emptyNew()
	local self = Event.new(ConnectionRequestEvent_mt)

	return self
end

function ConnectionRequestEvent.new(language, password, uniqueUserId, platformUserId, platformId, playerName, platformSessionId)
	local self = ConnectionRequestEvent.emptyNew()
	self.language = language
	self.password = password
	self.uniqueUserId = uniqueUserId
	self.platformUserId = platformUserId
	self.platformId = platformId
	self.playerName = playerName
	self.platformSessionId = platformSessionId

	return self
end

function ConnectionRequestEvent:readStream(streamId, connection)
	self.language = streamReadUInt8(streamId)
	self.password = streamReadString(streamId)
	self.uniqueUserId = streamReadString(streamId)
	self.platformUserId = streamReadString(streamId)
	self.platformId = streamReadUInt8(streamId)
	self.playerName = streamReadString(streamId)
	self.platformSessionId = streamReadString(streamId)

	self:run(connection)
end

function ConnectionRequestEvent:writeStream(streamId, connection)
	streamWriteUInt8(streamId, self.language)
	streamWriteString(streamId, self.password)
	streamWriteString(streamId, self.uniqueUserId)
	streamWriteString(streamId, self.platformUserId)
	streamWriteUInt8(streamId, self.platformId)
	streamWriteString(streamId, self.playerName)
	streamWriteString(streamId, self.platformSessionId)
end

function ConnectionRequestEvent:run(connection)
	g_currentMission:onConnectionRequest(connection, self.language, self.password, self.uniqueUserId, self.platformUserId, self.platformId, self.playerName, self.platformSessionId)
end
