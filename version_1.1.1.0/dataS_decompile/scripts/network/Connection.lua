Connection = {}
local Connection_mt = Class(Connection)
Connection.SYNC_CREATING = 1
Connection.SYNC_CREATED = 2
Connection.SYNC_REMOVING = 3
Connection.SYNC_MANUALLY_REGISTERED = 4
Connection.SYNC_HIST_CREATE = 0
Connection.SYNC_HIST_UPDATE = 1
Connection.SYNC_HIST_REMOVE = 2

function Connection.new(id, isServer, reverseConnection)
	local self = {}

	setmetatable(self, Connection_mt)

	self.streamId = id
	self.isServer = isServer
	self.isConnected = true
	self.isReadyForObjects = false
	self.isReadyForEvents = false
	self.objectsInfo = {}
	self.pendingDeleteObjects = {}
	self.pendingDeleteObjectPacketIds = {}
	self.compressionRatio = 1
	self.sendStatsTime = 0
	self.lastSeqSent = 0
	self.lastSeqReceived = 0
	self.highestAckedSeq = 0
	self.ackMask = 0
	self.hasPacketsToAck = false
	self.ackPingPacketSent = false

	if self.streamId == NetworkNode.LOCAL_STREAM_ID then
		self:setIsReadyForObjects(true)
		self:setIsReadyForEvents(true)

		if reverseConnection ~= nil then
			self.localConnection = reverseConnection
		else
			self.localConnection = Connection.new(id, not isServer, self)

			self.localConnection:setIsReadyForObjects(true)
			self.localConnection:setIsReadyForEvents(true)
		end
	end

	return self
end

function Connection:setIsReadyForObjects(isReadyForObjects)
	self.isReadyForObjects = isReadyForObjects
end

function Connection:setIsReadyForEvents(isReadyForEvents)
	self.isReadyForEvents = isReadyForEvents
end

function Connection:updateSendStats(tickSum)
	self.sendStatsTime = self.sendStatsTime + tickSum

	if self.sendStatsTime > 100 then
		self.sendStatsTime = 0
		local sendSize, sendSizeCompressed = netGetAndResetConnectionSendStats(self.streamId)
		local compressionRatio = 1

		if sendSizeCompressed > 0 then
			compressionRatio = MathUtil.clamp(sendSize / sendSizeCompressed, 1, 5)
		end

		self.compressionRatio = 0.8 * self.compressionRatio + 0.2 * compressionRatio
	end
end

function Connection:sendEvent(event, deleteEvent, force)
	if not self.isConnected then
		return
	end

	if self.streamId == NetworkNode.LOCAL_STREAM_ID then
		event:run(self.localConnection)
	elseif self.isReadyForEvents or force then
		if event.eventId == nil then
			print("Error: Invalid event id")
		else
			local channel = event.networkChannel

			if channel == nil then
				channel = NetworkNode.CHANNEL_MAIN
			end

			streamWriteUIntN(self.streamId, MessageIds.EVENT, MessageIds.SEND_NUM_BITS)
			streamWriteUIntN(self.streamId, event.eventId, EventIds.SEND_NUM_BITS)
			event:writeStream(self.streamId, self)

			local dataSent = streamGetWriteOffset(self.streamId)

			netSendStream(self.streamId, "high", "reliable_ordered", channel, true)

			if g_server ~= nil then
				g_server:addPacketSize(NetworkNode.PACKET_EVENT, dataSent / 8)
			else
				g_client:addPacketSize(NetworkNode.PACKET_EVENT, dataSent / 8)
			end
		end
	end

	if deleteEvent then
		event:delete()
	end
end

function Connection:queueSendEvent(event, force, ghostObject)
	if not self.isConnected then
		return
	end

	if self.isReadyForEvents or force then
		local objectInfo = self.objectsInfo[ghostObject.id]

		if objectInfo ~= nil and (objectInfo.sync == Connection.SYNC_CREATING or objectInfo.sync == Connection.SYNC_MANUALLY_REGISTERED) then
			event.queueCount = event.queueCount + 1

			if objectInfo.eventQueue == nil then
				objectInfo.eventQueue = {}
			end

			table.insert(objectInfo.eventQueue, event)
		end
	end
end

function Connection:getIsClient()
	return not self.isServer
end

function Connection:getIsServer()
	return self.isServer
end

function Connection:getIsLocal()
	return self.streamId == NetworkNode.LOCAL_STREAM_ID
end

function Connection:writeUpdateAck(streamId)
	self.lastSeqSent = self.lastSeqSent + 1

	streamWriteUInt8(streamId, self.lastSeqSent)
	streamWriteUInt8(streamId, self.lastSeqReceived)
	streamWriteInt32(streamId, self.ackMask)

	self.hasPacketsToAck = false
end

function Connection:readUpdateAck(streamId)
	local seq = streamReadUInt8(streamId)
	local highestAck = streamReadUInt8(streamId)
	local ackMask = streamReadInt32(streamId)
	seq = seq + bitAND(self.lastSeqReceived, 4294967040.0)

	if seq < self.lastSeqReceived then
		seq = seq + 256
	end

	if seq > self.lastSeqReceived + 31 then
		return false
	end

	highestAck = highestAck + bitAND(self.highestAckedSeq, 4294967040.0)

	if highestAck < self.highestAckedSeq then
		highestAck = highestAck + 256
	end

	if self.lastSeqSent < highestAck then
		return false
	end

	self.ackMask = bitShiftLeft(self.ackMask, seq - self.lastSeqReceived)
	self.ackMask = self.ackMask + 1
	self.hasPacketsToAck = true

	for i = self.highestAckedSeq + 1, highestAck do
		local isTransmitted = bitAND(ackMask, bitShiftLeft(1, highestAck - i)) ~= 0

		if isTransmitted then
			self:onPacketSent(i)
		else
			self:onPacketLost(i)
		end
	end

	self.highestAckedSeq = highestAck
	self.lastSeqReceived = seq

	return true
end

function Connection:getIsWindowFull()
	return self.lastSeqSent - self.highestAckedSeq >= 29
end

function Connection:onPacketSent(i)
	for objectId, objectInfo in pairs(self.objectsInfo) do
		local historyEntry = objectInfo.history[i]

		if historyEntry ~= nil then
			if g_networkDebug then
				for k, _ in pairs(objectInfo.history) do
					assert(i <= k)
				end
			end

			objectInfo.history[i] = nil

			if historyEntry.sync == Connection.SYNC_HIST_CREATE then
				if objectInfo.sync == Connection.SYNC_CREATING then
					objectInfo.sync = Connection.SYNC_CREATED

					self:sendObjectEventQueue(objectInfo)
				end
			elseif historyEntry.sync == Connection.SYNC_HIST_REMOVE and objectInfo.sync == Connection.SYNC_REMOVING then
				self.objectsInfo[objectId] = nil
			end
		end
	end

	for objectId, packetId in pairs(self.pendingDeleteObjectPacketIds) do
		if packetId == i then
			self.pendingDeleteObjectPacketIds[objectId] = nil
		end
	end

	g_currentMission:onConnectionPacketSent(self, i)
end

function Connection:onPacketLost(i)
	for objectId, objectInfo in pairs(self.objectsInfo) do
		local historyEntry = objectInfo.history[i]

		if historyEntry ~= nil then
			if g_networkDebug then
				for k, _ in pairs(objectInfo.history) do
					assert(i <= k)
				end
			end

			objectInfo.history[i] = nil

			if historyEntry.sync == Connection.SYNC_HIST_CREATE then
				if objectInfo.sync == Connection.SYNC_CREATING then
					self.objectsInfo[objectId] = nil
				end
			elseif historyEntry.sync == Connection.SYNC_HIST_REMOVE then
				if objectInfo.sync == Connection.SYNC_REMOVING then
					objectInfo.sync = Connection.SYNC_CREATED
				end
			else
				local laterUpdatedMask = 0

				for _, h in pairs(objectInfo.history) do
					laterUpdatedMask = bitOR(laterUpdatedMask, h.mask)
				end

				local notLaterUpdatedMask = bitAND(historyEntry.mask, bitNOT(laterUpdatedMask))

				if notLaterUpdatedMask ~= 0 then
					objectInfo.dirtyMask = bitOR(objectInfo.dirtyMask, notLaterUpdatedMask)
				end
			end
		end
	end

	for objectId, packetId in pairs(self.pendingDeleteObjectPacketIds) do
		if packetId == i then
			self.pendingDeleteObjectPacketIds[objectId] = nil
			self.pendingDeleteObjects[objectId] = objectId
		end
	end

	g_currentMission:onConnectionPacketLost(self, i)
end

function Connection:sendObjectEventQueue(objectInfo)
	if objectInfo.eventQueue ~= nil then
		for _, event in ipairs(objectInfo.eventQueue) do
			self:sendEvent(event, false, true)

			event.queueCount = event.queueCount - 1

			if event.queueCount == 0 then
				event:delete()
			end
		end

		objectInfo.eventQueue = nil
	end
end

function Connection:dropObjectEventQueue(objectInfo)
	if objectInfo.eventQueue ~= nil then
		for _, event in ipairs(objectInfo.eventQueue) do
			event.queueCount = event.queueCount - 1

			if event.queueCount == 0 then
				event:delete()
			end
		end

		objectInfo.eventQueue = nil
	end
end

function Connection:notifyObjectDeleted(objectId, alreadySent)
	assert(not self.isServer)

	local objectInfo = self.objectsInfo[objectId]

	if objectInfo ~= nil then
		self:dropObjectEventQueue(objectInfo)

		self.objectsInfo[objectId] = nil
	end

	if not alreadySent and self.streamId ~= NetworkNode.LOCAL_STREAM_ID and self.pendingDeleteObjectPacketIds[objectId] == nil then
		self.pendingDeleteObjects[objectId] = objectId
	end
end

function Connection:getLatency()
	return 20
end
