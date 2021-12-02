Client = {}
local Client_mt = Class(Client, NetworkNode)
local clientLocalNetConnect = ""

function InitClientOnce()
	if clientLocalNetConnect == "" then
		clientLocalNetConnect = netConnect
	end
end

function Client.new()
	local self = NetworkNode.new(Client_mt)
	self.clientNetworkCardAddress = ""
	self.clientPort = 0
	self.serverConnection = nil
	self.tempClientCreatingObjects = {}
	self.tempClientManuallyRegisteringObjects = {}
	self.tickRate = 30
	self.tickDuration = 1000 / self.tickRate
	self.tickSum = 0
	self.netIsRunning = false
	self.serverStreamId = 0
	self.currentLatency = 80
	self.lastNumUpdatesSent = 0
	self.finishedAsyncObjects = {}

	if g_server == nil then
		addConsoleCommand("gsNetworkShowTraffic", "Toggle network traffic visualization", "consoleCommandToggleShowNetworkTraffic", self)
		addConsoleCommand("gsNetworkShowObjects", "Toggle network show objects", "consoleCommandToggleNetworkShowObjects", self)
	end

	return self
end

function Client:delete()
	if g_server == nil then
		removeConsoleCommand("gsNetworkShowTraffic")
		removeConsoleCommand("gsNetworkShowObjects")
	end

	for _, object in pairs(self.tempClientCreatingObjects) do
		object:delete()
	end

	for _, object in pairs(self.tempClientManuallyRegisteringObjects) do
		object:delete()
	end

	Client:superClass().delete(self)
	self:stop()
end

function Client:update(dt, isRunning)
	if g_server == nil then
		Client:superClass().update(self, dt)

		if self.serverStreamId == 0 then
			return
		end

		if not isRunning then
			return
		end

		for i = 1, #self.finishedAsyncObjects do
			local nextObject = table.remove(self.finishedAsyncObjects, 1)

			if not nextObject.isDeleted then
				g_client:getServerConnection():sendEvent(ObjectAsyncRequestEvent.new(nextObject))
			end
		end

		self:updateActiveObjects(dt)

		self.tickSum = self.tickSum + dt

		if self.tickSum >= self.tickDuration - 3 then
			local dirtyObjects = self:updateActiveObjectsTick(self.tickSum)

			if self.serverConnection:getIsWindowFull() then
				if not self.serverConnection.ackPingPacketSent then
					self.serverConnection.ackPingPacketSent = true

					streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_PING, MessageIds.SEND_NUM_BITS)
					self.serverConnection:writeUpdateAck(self.serverStreamId)
					netSendStream(self.serverStreamId, "medium", "reliable_ordered", 1, true)
				end
			else
				self.serverConnection.ackPingPacketSent = false
				local numDirtyObjects = math.min(table.getn(dirtyObjects), 255)
				local numDirtyObjectsSent = numDirtyObjects

				if numDirtyObjects > 0 then
					streamWriteTimestamp(self.serverStreamId)
				end

				streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_UPDATE, MessageIds.SEND_NUM_BITS)
				self.serverConnection:writeUpdateAck(self.serverStreamId)

				local numDirtyObjectsOffset = streamGetWriteOffset(self.serverStreamId)

				streamWriteUInt8(self.serverStreamId, 0)

				local x = 0
				local y = 0
				local z = 0

				if self.networkListener ~= nil then
					x, y, z = self.networkListener:getClientPosition()
				end

				streamWriteFloat32(self.serverStreamId, x)
				streamWriteFloat32(self.serverStreamId, y)
				streamWriteFloat32(self.serverStreamId, z)

				local oldPacketSize = 0
				local maxUploadSize = g_maxUploadRate * 8 * self.tickDuration

				for j = 1, numDirtyObjects do
					local object = dirtyObjects[j]
					local objectId = dirtyObjects[j].lastServerId

					NetworkUtil.writeNodeObjectId(self.serverStreamId, objectId)
					object:writeUpdateStream(self.serverStreamId, self.serverConnection, object.dirtyMask)

					object.dirtyMask = 0
					local packetSize = streamGetWriteOffset(self.serverStreamId)

					self:addPacketSize(self:getObjectPacketType(object), (packetSize - oldPacketSize) / 8)

					oldPacketSize = packetSize

					if maxUploadSize < packetSize then
						numDirtyObjectsSent = j

						break
					end
				end

				local endOffset = streamGetWriteOffset(self.serverStreamId)

				streamSetWriteOffset(self.serverStreamId, numDirtyObjectsOffset)
				streamWriteUInt8(self.serverStreamId, numDirtyObjectsSent)
				streamSetWriteOffset(self.serverStreamId, endOffset)

				endOffset = streamGetWriteOffset(self.serverStreamId)

				voiceChatWriteClientUpdateToStream(self.serverStreamId, self.serverStreamId, self.serverConnection.lastSeqSent)
				self:addPacketSize(NetworkNode.PACKET_VOICE_CHAT, (streamGetWriteOffset(self.serverStreamId) - endOffset) / 8)
				netSendStream(self.serverStreamId, "medium", "unreliable_sequenced", 1, true)
			end

			self:updatePacketStats(self.tickSum)

			self.tickSum = 0
		end
	end
end

function Client:keyEvent(unicode, sym, modifier, isDown)
	if g_server == nil then
		Client:superClass().keyEvent(self, unicode, sym, modifier, isDown)
	end
end

function Client:mouseEvent(posX, posY, isDown, isUp, button)
end

function Client:draw()
	if g_server == nil then
		Client:superClass().draw(self)

		if self.showNetworkTraffic then
			-- Nothing
		end
	end
end

function Client:onObjectFinishedAsyncLoading(object)
	table.insert(self.finishedAsyncObjects, object)
end

function Client:startLocal()
	self.serverConnection = g_server.clientConnections[NetworkNode.LOCAL_STREAM_ID].localConnection

	self:connectionRequestAccepted()
end

function Client:start(serverAddress, serverPort, relayHeader)
	if not self.netIsRunning then
		self.netIsRunning = true

		g_connectionManager:startupWithWorkingPort(g_gameSettings:getValue("defaultServerPort"))
		g_connectionManager:setDefaultListener(Client.packetReceived, self)

		if relayHeader == nil then
			relayHeader = ""
		end

		self.serverStreamId = clientLocalNetConnect(serverAddress, serverPort, "", relayHeader)
		self.serverConnection = Connection.new(self.serverStreamId, true)

		if self.serverStreamId == 0 then
			print("Error: Failed to call connect")

			self.serverConnection.isConnected = false

			self.serverConnection:setIsReadyForObjects(false)
			self.serverConnection:setIsReadyForEvents(false)

			if self.networkListener ~= nil then
				self.networkListener:onConnectionClosed(self.serverConnection)
			end
		else
			self.serverConnection:setIsReadyForObjects(true)
			self.serverConnection:setIsReadyForEvents(true)
		end
	end
end

function Client:stop()
	if self.netIsRunning then
		if self.serverStreamId ~= 0 then
			netCloseConnection(self.serverStreamId, true, 1)

			self.serverStreamId = 0
		end

		self.serverConnection.isConnected = false

		self.serverConnection:setIsReadyForObjects(false)
		self.serverConnection:setIsReadyForEvents(false)
		g_connectionManager:shutdown()
		g_connectionManager:setDefaultListener(nil, )

		self.netIsRunning = false
	end
end

function Client:packetReceived(packetType, timestamp, streamId)
	if streamId ~= self.serverStreamId then
		return
	end

	Client:superClass().packetReceived(self, packetType, timestamp, streamId)

	if packetType == Network.TYPE_APPLICATION then
		local messageId = streamReadUIntN(streamId, MessageIds.SEND_NUM_BITS)

		if messageId == MessageIds.OBJECT_UPDATE then
			g_packetPhysicsNetworkTime = streamReadInt32(streamId)
			g_networkTime = netGetTime()
			self.currentLatency = self.currentLatency * 0.9 + math.max(g_networkTime - timestamp, 0.5) * 0.1
			local tickDelay = 60

			if self.lastReceivedNetworkTime ~= nil then
				tickDelay = g_networkTime - self.lastReceivedNetworkTime
			end

			self.lastReceivedNetworkTime = g_networkTime
			local interpBuffer = g_clientInterpDelayBufferOffset + tickDelay * g_clientInterpDelayBufferScale
			interpBuffer = MathUtil.clamp(interpBuffer, g_clientInterpDelayBufferMin, g_clientInterpDelayBufferMax)
			local targetDelay = tickDelay + interpBuffer
			local adjust = g_clientInterpDelayAdjustDown

			if g_clientInterpDelay < targetDelay then
				adjust = g_clientInterpDelayAdjustUp
			end

			g_clientInterpDelay = g_clientInterpDelay * (1 - adjust) + targetDelay * adjust
			g_clientInterpDelay = MathUtil.clamp(g_clientInterpDelay, g_clientInterpDelayMin, g_clientInterpDelayMax)

			self.serverConnection:readUpdateAck(streamId)

			local networkDebug = streamReadBool(streamId)

			if self.networkListener ~= nil then
				self.networkListener:onConnectionReadUpdateStream(self.serverConnection, networkDebug)
			end

			local numInfos = streamReadUInt8(streamId)

			for i = 1, numInfos do
				local numBits = nil
				local startOffset = 0

				if networkDebug then
					startOffset = streamGetReadOffset(streamId)
					numBits = streamReadInt32(streamId)
				end

				local infoId = streamReadUIntN(streamId, 2)

				if infoId == 0 then
					local objectId = NetworkUtil.readNodeObjectId(streamId)
					local object = self:getObject(objectId)

					if object ~= nil then
						self:unregisterObject(object, true)
						object:delete()
					end

					if networkDebug then
						self:checkObjectUpdateDebugReadSize(streamId, numBits, startOffset, "object", object)
					end
				elseif infoId == 1 then
					if g_server ~= nil then
						print("Error: Unexpected packet object created")

						return
					end

					local objectClassId = streamReadUIntN(streamId, ObjectIds.SEND_NUM_BITS)
					local objectId = NetworkUtil.readNodeObjectId(streamId)
					local object = self:getObject(objectId)
					local needsCreation = object == nil

					if needsCreation then
						local objectClass = ObjectIds.getObjectClassById(objectClassId)

						if objectClass ~= nil then
							object = objectClass.new(false, true)
							object.isManuallyReplicated = false
							object.isRegistered = true
						end
					end

					if object == nil then
						return
					end

					object:readStream(streamId, self.serverConnection, objectId)

					if needsCreation then
						self:addObject(object, objectId)
					else
						object:onGhostAdd()
					end

					self.serverConnection.objectsInfo[objectId] = {
						dirtyMask = 0,
						sync = Connection.SYNC_CREATED,
						history = {}
					}

					if networkDebug then
						self:checkObjectUpdateDebugReadSize(streamId, numBits, startOffset, "creation", object)
					end
				elseif infoId == 2 then
					local objectId = NetworkUtil.readNodeObjectId(streamId)
					local object = self:getObject(objectId)

					if object == nil then
						return
					end

					object:readUpdateStream(streamId, timestamp, self.serverConnection)
					object:raiseActive()

					if networkDebug then
						self:checkObjectUpdateDebugReadSize(streamId, numBits, startOffset, "update", object)
					end
				else
					local objectId = NetworkUtil.readNodeObjectId(streamId)
					local object = self:getObject(objectId)

					if object ~= nil then
						object:onGhostRemove()
					end

					if networkDebug then
						self:checkObjectUpdateDebugReadSize(streamId, numBits, startOffset, "removal", object)
					end
				end
			end
		elseif messageId == MessageIds.OBJECT_PING then
			self.serverConnection:readUpdateAck(streamId)
			streamWriteUIntN(streamId, MessageIds.OBJECT_ACK, MessageIds.SEND_NUM_BITS)
			self.serverConnection:writeUpdateAck(streamId)
			netSendStream(streamId, "high", "reliable_ordered", 1, true)
		elseif messageId == MessageIds.OBJECT_ACK then
			self.serverConnection:readUpdateAck(streamId)
		elseif messageId == MessageIds.OBJECT_INITIAL_ARRAY then
			self.waitingForObjects = false

			if g_server ~= nil then
				print("Error: Unexpected packet object created array")

				return
			end

			local networkDebug = streamReadBool(streamId)
			local numObjects = streamReadInt32(streamId)

			print("Joined network game (" .. numObjects .. ")")

			for i = 1, numObjects do
				local numBits = 0
				local startOffset = 0

				if networkDebug then
					startOffset = streamGetReadOffset(streamId)
					numBits = streamReadInt32(streamId)
				end

				local objectClassId = streamReadUIntN(streamId, ObjectIds.SEND_NUM_BITS)
				local objectId = NetworkUtil.readNodeObjectId(streamId)
				local objectClass = ObjectIds.getObjectClassById(objectClassId)
				local object = nil

				if objectClass ~= nil then
					object = objectClass.new(false, true)
					object.isManuallyReplicated = false
					object.isRegistered = true
				end

				if object == nil then
					print("Error: Failed to create new object with class id " .. objectClassId .. " in initial object array")

					return
				end

				object:readStream(streamId, self.serverConnection, objectId)
				self:addObject(object, objectId)

				if networkDebug then
					local endOffset = streamGetReadOffset(streamId)
					local readNumBits = endOffset - (startOffset + 32)

					if readNumBits ~= numBits then
						local extraInfo = ""

						if object.configFileName ~= nil then
							extraInfo = " (" .. object.configFileName .. ")"
						end

						print("Error: Not all bits read in object create array (" .. readNumBits .. " vs " .. numBits .. "), Class: " .. objectClass.className .. extraInfo)
					end
				end
			end
		elseif messageId == MessageIds.OBJECT_SERVER_ID then
			local serverObjectId = NetworkUtil.readNodeObjectId(streamId)
			local clientObjectId = NetworkUtil.readNodeObjectId(streamId)
			local object = self.tempClientCreatingObjects[clientObjectId]

			streamWriteUIntN(streamId, MessageIds.OBJECT_SERVER_ID_ACK, MessageIds.SEND_NUM_BITS)
			NetworkUtil.writeNodeObjectId(streamId, serverObjectId)
			netSendStream(streamId, "high", "reliable_ordered", 1, true)

			if object ~= nil then
				self:finishRegisterObject(object, serverObjectId)

				self.tempClientCreatingObjects[clientObjectId] = nil
			else
				streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_DELETED, MessageIds.SEND_NUM_BITS)
				NetworkUtil.writeNodeObjectId(self.serverStreamId, serverObjectId)
				netSendStream(self.serverStreamId, "high", "reliable_ordered", 1, true)
			end
		elseif messageId == MessageIds.EVENT then
			local eventId = streamReadUIntN(streamId, EventIds.SEND_NUM_BITS)
			local eventClass = EventIds.getEventClassById(eventId)

			if eventClass ~= nil then
				local tempEvent = eventClass.emptyNew()

				tempEvent:readStream(streamId, self.serverConnection)
				tempEvent:delete()
			end
		elseif messageId == MessageIds.EVENT_IDS then
			local numIds = streamReadInt32(streamId)

			for i = 1, numIds do
				local eventId = streamReadUIntN(streamId, EventIds.SEND_NUM_BITS)
				local className = streamReadString(streamId)

				EventIds.assignEventId(className, eventId)
			end
		elseif messageId == MessageIds.OBJECT_CLASS_IDS then
			local numIds = streamReadInt32(streamId)

			for i = 1, numIds do
				local eventId = streamReadUIntN(streamId, ObjectIds.SEND_NUM_BITS)
				local className = streamReadString(streamId)

				ObjectIds.assignObjectClassId(className, eventId)
			end
		else
			print("Error: Invalid message id " .. messageId)
		end
	elseif packetType == Network.TYPE_CONNECTION_REQUEST_ACCEPTED then
		streamWriteUIntN(self.serverStreamId, MessageIds.CLIP_COEFF, MessageIds.SEND_NUM_BITS)
		streamWriteFloat32(self.serverStreamId, getViewDistanceCoeff())
		netSendStream(self.serverStreamId, "high", "reliable_ordered", 1, true)
		self:connectionRequestAccepted()
	elseif packetType == Network.TYPE_DISCONNECTION_NOTIFICATION then
		if streamId == self.serverStreamId then
			self.serverStreamId = 0
			self.serverConnection.isConnected = false

			self.serverConnection:setIsReadyForObjects(false)
			self.serverConnection:setIsReadyForEvents(false)

			if self.networkListener ~= nil then
				self.networkListener:onConnectionClosed(self.serverConnection)
			end
		end
	elseif (packetType == Network.TYPE_CONNECTION_ATTEMPT_FAILED or packetType == Network.TYPE_CONNECTION_LOST or packetType == Network.TYPE_CONNECTION_BANNED or packetType == Network.TYPE_INVALID_PASSWORD) and streamId == self.serverStreamId then
		self.serverStreamId = 0
		self.serverConnection.isConnected = false

		self.serverConnection:setIsReadyForObjects(false)
		self.serverConnection:setIsReadyForEvents(false)

		if self.networkListener ~= nil then
			self.networkListener:onConnectionClosed(self.serverConnection)
		end
	end
end

function Client:connectionRequestAccepted()
	if self.networkListener ~= nil then
		self.networkListener:onConnectionAccepted(self.serverConnection)
	end
end

function Client:registerObject(object, alreadySent)
	if not object.isRegistered then
		object.isManuallyReplicated = alreadySent
		object.isRegistered = true

		if alreadySent then
			self.tempClientManuallyRegisteringObjects[object.id] = object
		else
			if g_server ~= nil then
				print("Error: Client:registerObject not expected")
				printCallstack()
			end

			self.tempClientCreatingObjects[object.id] = object

			streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_CREATED, MessageIds.SEND_NUM_BITS)
			streamWriteUIntN(self.serverStreamId, object.classId, ObjectIds.SEND_NUM_BITS)
			NetworkUtil.writeNodeObjectId(self.serverStreamId, object.id)
			object:writeStream(self.serverStreamId, self.serverConnection)
			netSendStream(self.serverStreamId, "high", "reliable_ordered", 1, true)
		end
	end
end

function Client:unregisterObject(object, alreadySent)
	if object.isRegistered then
		local serverId = self:getObjectId(object)

		if serverId ~= nil then
			if (alreadySent == nil or not alreadySent) and self.serverStreamId ~= 0 then
				streamWriteUIntN(self.serverStreamId, MessageIds.OBJECT_DELETED, MessageIds.SEND_NUM_BITS)
				NetworkUtil.writeNodeObjectId(self.serverStreamId, serverId)
				netSendStream(self.serverStreamId, "high", "reliable_ordered", 1, true)
			end

			self:removeObject(object, serverId)
		else
			self.tempClientManuallyRegisteringObjects[object.id] = nil
			self.tempClientCreatingObjects[object.id] = nil
		end

		object.isRegistered = false
	end
end

function Client:finishRegisterObject(object, serverId)
	self:addObject(object, serverId)

	self.serverConnection.objectsInfo[serverId] = {
		dirtyMask = 0,
		sync = Connection.SYNC_CREATED,
		history = {}
	}
	self.tempClientManuallyRegisteringObjects[object.id] = nil
	self.tempClientCreatingObjects[object.id] = nil
end

function Client:getServerConnection()
	return self.serverConnection
end
