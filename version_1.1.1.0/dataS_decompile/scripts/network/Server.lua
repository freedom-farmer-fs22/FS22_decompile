Server = {}
local Server_mt = Class(Server, NetworkNode)

function Server.new()
	local self = NetworkNode.new(Server_mt)
	self.clients = {}
	self.clientConnections = {}
	self.clientPositions = {}
	self.clientClipDistCoeffs = {}
	self.objects = {}
	self.tickRate = 30
	self.tickDuration = 1000 / self.tickRate
	self.tickSum = 0
	self.netIsRunning = false

	addConsoleCommand("gsNetworkShowTraffic", "Toggle network traffic visualization", "consoleCommandToggleShowNetworkTraffic", self)
	addConsoleCommand("gsNetworkDebug", "Toggle network debugging", "consoleCommandToggleNetworkDebug", self)
	addConsoleCommand("gsNetworkShowObjects", "Toggle network show objects", "consoleCommandToggleNetworkShowObjects", self)

	return self
end

function Server:delete()
	removeConsoleCommand("gsNetworkShowTraffic")
	removeConsoleCommand("gsNetworkDebug")
	removeConsoleCommand("gsNetworkShowObjects")
	Server:superClass().delete(self)
	self:stop()
end

function Server:update(dt, isRunning)
	Server:superClass().update(self, dt)

	if not isRunning then
		return
	end

	self:updateActiveObjects(dt)

	self.tickSum = self.tickSum + dt

	if self.tickSum >= self.tickDuration - 3 then
		local numClients = #self.clients
		local maxUploadSize = math.min(g_maxUploadRatePerClient, g_maxUploadRate / numClients) * 8 * self.tickSum

		if self.networkListener ~= nil then
			self.networkListener:onConnectionsUpdateTick(self.tickSum)
		end

		self:updateActiveObjectsTick(self.tickSum)

		for i = 1, #self.clients do
			local streamId = self.clients[i]
			local connection = self.clientConnections[streamId]

			if connection.isReadyForObjects then
				if connection:getIsWindowFull() then
					if not connection.ackPingPacketSent then
						connection.ackPingPacketSent = true

						streamWriteUIntN(streamId, MessageIds.OBJECT_PING, MessageIds.SEND_NUM_BITS)
						connection:writeUpdateAck(streamId)
						netSendStream(streamId, "high", "reliable_ordered", 1, true)
					end
				else
					connection:updateSendStats(self.tickSum)

					connection.ackPingPacketSent = false
					local maxPacketSize = maxUploadSize * connection.compressionRatio
					self.currentWriteStreamConnection = connection
					self.currentWriteStreamConnectionIsInitial = false
					local objectsInfo = connection.objectsInfo
					local pendingDeleteObjects = connection.pendingDeleteObjects
					local pendingDeleteObjectPacketIds = connection.pendingDeleteObjectPacketIds
					local sendInfos = {}
					local x, y, z = self:getClientPosition(streamId)
					local coeff = self:getClientClipDistCoeff(streamId)

					for _, object in pairs(self.objects) do
						local objectInfo = objectsInfo[object.id]

						if objectInfo ~= nil then
							objectInfo.dirtyMask = bitOR(objectInfo.dirtyMask, object.dirtyMask)
						end

						if objectInfo == nil then
							if object:testScope(x, y, z, coeff) then
								local updatePriority = object:getUpdatePriority(2, x, y, z, coeff, connection)

								table.insert(sendInfos, {
									id = 1,
									object = object,
									prio = updatePriority
								})
							end
						elseif objectInfo.sync == Connection.SYNC_CREATED then
							if object:testScope(x, y, z, coeff) then
								if object.synchronizedConnections[connection] then
									if objectInfo.dirtyMask ~= 0 then
										objectInfo.skipCount = objectInfo.skipCount + 1
										local updatePriority = object:getUpdatePriority(objectInfo.skipCount, x, y, z, coeff, connection)

										table.insert(sendInfos, {
											id = 2,
											object = object,
											prio = updatePriority
										})
									else
										objectInfo.skipCount = 0
									end
								end
							else
								objectInfo.skipCount = objectInfo.skipCount + 1
								local updatePriority = object:getUpdatePriority(objectInfo.skipCount, x, y, z, coeff, connection)

								table.insert(sendInfos, {
									id = 3,
									object = object,
									prio = updatePriority
								})
							end
						end
					end

					for objectId in pairs(pendingDeleteObjects) do
						table.insert(sendInfos, {
							id = 0,
							prio = 100,
							objectId = objectId
						})
					end

					table.sort(sendInfos, Server.prioCmp)
					streamWriteTimestamp(streamId)
					streamWriteUIntN(streamId, MessageIds.OBJECT_UPDATE, MessageIds.SEND_NUM_BITS)
					streamWriteInt32(streamId, g_physicsNetworkTime)
					connection:writeUpdateAck(streamId)
					streamWriteBool(streamId, g_networkDebug)

					if self.networkListener ~= nil then
						self.networkListener:onConnectionWriteUpdateStream(connection, maxPacketSize, g_networkDebug)
					end

					local numInfosOffset = streamGetWriteOffset(streamId)

					streamWriteUInt8(streamId, 0)

					local numInfosSent = math.min(#sendInfos, 255)

					for j = 1, numInfosSent do
						local oldPacketSize = streamGetWriteOffset(streamId)
						local sendInfo = sendInfos[j]
						local startOffset = nil

						if g_networkDebug then
							startOffset = streamGetWriteOffset(streamId)

							streamWriteInt32(streamId, 0)
						end

						local object = sendInfo.object
						local infoId = sendInfo.id

						streamWriteUIntN(streamId, infoId, 2)

						if infoId == 0 then
							NetworkUtil.writeNodeObjectId(streamId, sendInfo.objectId)

							pendingDeleteObjects[sendInfo.objectId] = nil
							pendingDeleteObjectPacketIds[sendInfo.objectId] = connection.lastSeqSent
						elseif infoId == 1 then
							streamWriteUIntN(streamId, object.classId, ObjectIds.SEND_NUM_BITS)
							NetworkUtil.writeNodeObjectId(streamId, object.id)
							object:writeStream(streamId, connection)

							objectsInfo[object.id] = {
								dirtyMask = 0,
								skipCount = 0,
								sync = Connection.SYNC_CREATING,
								history = {}
							}
							objectsInfo[object.id].history[connection.lastSeqSent] = {
								mask = 0,
								sync = Connection.SYNC_HIST_CREATE
							}
						elseif infoId == 2 then
							local objectInfo = objectsInfo[object.id]
							local dirtyMask = objectInfo.dirtyMask

							NetworkUtil.writeNodeObjectId(streamId, object.id)
							object:writeUpdateStream(streamId, connection, dirtyMask)

							objectInfo.history[connection.lastSeqSent] = {
								mask = dirtyMask,
								sync = Connection.SYNC_HIST_UPDATE
							}
							objectInfo.skipCount = 0
							objectInfo.dirtyMask = 0
						else
							local objectInfo = objectsInfo[object.id]

							NetworkUtil.writeNodeObjectId(streamId, object.id)

							objectInfo.sync = Connection.SYNC_REMOVING
							objectInfo.history[connection.lastSeqSent] = {
								mask = 0,
								sync = Connection.SYNC_HIST_REMOVE
							}
						end

						if g_networkDebug then
							local endOffset = streamGetWriteOffset(streamId)

							streamSetWriteOffset(streamId, startOffset)
							streamWriteInt32(streamId, endOffset - (startOffset + 32))
							streamSetWriteOffset(streamId, endOffset)
						end

						local packetSize = streamGetWriteOffset(streamId)

						self:addPacketSize(self:getObjectPacketType(object), (packetSize - oldPacketSize) / 8)

						if g_networkDebugPrints and infoId == 2 then
							local extraInfo = ""

							if object.configFileName ~= nil then
								extraInfo = "(" .. object.configFileName .. ")"
							end

							print("  send object " .. extraInfo .. ", size " .. (packetSize - oldPacketSize) / 8 .. " bytes")
						end

						if maxPacketSize < packetSize then
							numInfosSent = j

							break
						end
					end

					local endOffset = streamGetWriteOffset(streamId)

					streamSetWriteOffset(streamId, numInfosOffset)
					streamWriteUInt8(streamId, numInfosSent)
					streamSetWriteOffset(streamId, endOffset)
					netSendStream(streamId, "medium", "unreliable_sequenced", 1, true)

					self.currentWriteStreamConnection = nil
				end
			end
		end

		if self.networkListener ~= nil then
			self.networkListener:onFinishedClientsWriteUpdateStream()
		end

		for _, object in pairs(self.objects) do
			object.dirtyMask = 0
		end

		self:updatePacketStats(self.tickSum)

		self.tickSum = 0
	end
end

function Server:mouseEvent(posX, posY, isDown, isUp, button)
end

function Server:startLocal()
	if g_client ~= nil then
		self.clientConnections[NetworkNode.LOCAL_STREAM_ID] = Connection.new(NetworkNode.LOCAL_STREAM_ID, false)

		self.clientConnections[NetworkNode.LOCAL_STREAM_ID]:setIsReadyForObjects(true)
		self.clientConnections[NetworkNode.LOCAL_STREAM_ID]:setIsReadyForEvents(true)
	end
end

function Server:start(serverPort, serverAddress, maxConnections)
	if not self.netIsRunning then
		self.netIsRunning = true

		print("Started network game (" .. serverPort .. ")")

		if not g_connectionManager:startup(serverPort, serverAddress, maxConnections) then
			print("Error: Failed to startup network. Probably the select port is already in use")
		end

		g_connectionManager:setDefaultListener(Server.packetReceived, self)

		if g_client ~= nil then
			self.clientConnections[NetworkNode.LOCAL_STREAM_ID] = Connection.new(NetworkNode.LOCAL_STREAM_ID, false)
		end
	end
end

function Server:init()
	EventIds.assignEventIds()
	ObjectIds.assignObjectClassIds()
end

function Server:stop()
	if self.netIsRunning then
		for streamId in ipairs(self.clients) do
			netCloseConnection(streamId, true, 1)
		end

		self.clients = {}

		for _, connection in pairs(self.clientConnections) do
			connection.isConnected = false

			connection:setIsReadyForObjects(false)
			connection:setIsReadyForEvents(false)
		end

		self.clientConnections = {}

		g_connectionManager:shutdown()
		g_connectionManager:setDefaultListener(nil, )

		self.netIsRunning = false
	end
end

function Server:closeConnection(connection)
	if connection.isConnected then
		self:removeStreamFromClients(connection.streamId)

		if self.networkListener ~= nil then
			self.networkListener:onConnectionClosed(connection)
		end

		netCloseConnection(connection.streamId, true, 1)

		connection.streamId = 0
	end
end

function Server:packetReceived(packetType, timestamp, streamId)
	Server:superClass().packetReceived(self, packetType, timestamp, streamId)

	if packetType == Network.TYPE_APPLICATION then
		local messageId = streamReadUIntN(streamId, MessageIds.SEND_NUM_BITS)

		if messageId == MessageIds.OBJECT_CREATED then
			local connection = self.clientConnections[streamId]

			if connection ~= nil then
				local objectsInfo = connection.objectsInfo
				local objectClassId = streamReadUIntN(streamId, ObjectIds.SEND_NUM_BITS)
				local clientObjectId = NetworkUtil.readNodeObjectId(streamId)
				local objectClass = ObjectIds.getObjectClassById(objectClassId)

				if objectClass ~= nil then
					local tempObject = objectClass.new(true, g_client ~= nil)

					tempObject:readStream(streamId, connection)

					tempObject.isManuallyReplicated = false
					tempObject.isRegistered = true

					self:addObject(tempObject, tempObject.id)

					objectsInfo[tempObject.id] = {
						dirtyMask = 0,
						skipCount = 0,
						sync = Connection.SYNC_CREATING,
						history = {}
					}

					streamWriteUIntN(streamId, MessageIds.OBJECT_SERVER_ID, MessageIds.SEND_NUM_BITS)
					NetworkUtil.writeNodeObjectId(streamId, tempObject.id)
					NetworkUtil.writeNodeObjectId(streamId, clientObjectId)
					netSendStream(streamId, "high", "reliable_ordered", 1, true)
				end
			end
		elseif messageId == MessageIds.OBJECT_SERVER_ID_ACK then
			local connection = self.clientConnections[streamId]

			if connection ~= nil then
				local serverObjectId = NetworkUtil.readNodeObjectId(streamId)
				local objectInfo = connection.objectsInfo[serverObjectId]

				if objectInfo ~= nil and objectInfo.sync == Connection.SYNC_CREATING then
					objectInfo.sync = Connection.SYNC_CREATED

					connection:sendObjectEventQueue(objectInfo)
				end
			end
		elseif messageId == MessageIds.OBJECT_DELETED then
			local connection = self.clientConnections[streamId]

			if connection ~= nil then
				local serverObjectId = NetworkUtil.readNodeObjectId(streamId)
				local object = self:getObject(serverObjectId)

				if object ~= nil then
					for _, connectionI in pairs(self.clientConnections) do
						connectionI:notifyObjectDeleted(serverObjectId, connectionI == connection)
					end

					self:unregisterObject(object, true)
					object:delete()
				end
			end
		elseif messageId == MessageIds.OBJECT_UPDATE then
			local connection = self.clientConnections[streamId]

			if connection ~= nil then
				connection:readUpdateAck(streamId)

				local numObjects = streamReadUInt8(streamId)
				local x = streamReadFloat32(streamId)
				local y = streamReadFloat32(streamId)
				local z = streamReadFloat32(streamId)

				self:setClientPosition(streamId, x, y, z)

				for i = 1, numObjects do
					local objectId = NetworkUtil.readNodeObjectId(streamId)
					local object = self:getObject(objectId)

					if object == nil then
						Logging.devError("Server: Trying to readUpdateStream from not registered object with id '%d'", objectId)
					end

					object:readUpdateStream(streamId, timestamp, connection)
					object:raiseActive()
				end

				voiceChatReadClientUpdateFromStream(connection.streamId, g_clientInterpDelay, connection.streamId, connection.lastSeqSent)
			end
		elseif messageId == MessageIds.OBJECT_PING then
			local connection = self.clientConnections[streamId]

			if connection ~= nil then
				connection:readUpdateAck(streamId)
				streamWriteUIntN(streamId, MessageIds.OBJECT_ACK, MessageIds.SEND_NUM_BITS)
				connection:writeUpdateAck(streamId)
				netSendStream(streamId, "medium", "reliable_ordered", 1, true)
			end
		elseif messageId == MessageIds.OBJECT_ACK then
			local connection = self.clientConnections[streamId]

			if connection ~= nil then
				connection:readUpdateAck(streamId)
			end
		elseif messageId == MessageIds.EVENT then
			local eventId = streamReadUIntN(streamId, EventIds.SEND_NUM_BITS)
			local eventClass = EventIds.getEventClassById(eventId)

			if eventClass ~= nil then
				local tempEvent = eventClass.emptyNew()

				tempEvent:readStream(streamId, self.clientConnections[streamId])
				tempEvent:delete()
			end
		elseif messageId == MessageIds.CLIP_COEFF then
			local coeff = streamReadFloat32(streamId)

			self:setClientClipDistCoeff(self.clientConnections[streamId], coeff)
		else
			log("Error: Invalid message id ", messageId)
		end
	elseif packetType == Network.TYPE_NEW_INCOMING_CONNECTION then
		if self.clientConnections[streamId] == nil then
			table.insert(self.clients, streamId)

			self.clientConnections[streamId] = Connection.new(streamId, false)

			for _, object in pairs(self.objects) do
				if object.isManuallyReplicated then
					self.clientConnections[streamId].objectsInfo[object.id] = {
						dirtyMask = 0,
						skipCount = 0,
						sync = Connection.SYNC_MANUALLY_REGISTERED,
						history = {}
					}
				end
			end

			if self.networkListener ~= nil then
				self.networkListener:onConnectionOpened(self.clientConnections[streamId])
			end
		end
	elseif packetType == Network.TYPE_DISCONNECTION_NOTIFICATION then
		local connection = self.clientConnections[streamId]

		self:removeStreamFromClients(streamId)

		if connection ~= nil and self.networkListener ~= nil then
			self.networkListener:onConnectionClosed(connection)
		end
	elseif packetType == Network.TYPE_CONNECTION_ATTEMPT_FAILED or packetType == Network.TYPE_CONNECTION_LOST or packetType == Network.TYPE_CONNECTION_BANNED or packetType == Network.TYPE_INVALID_PASSWORD then
		local connection = self.clientConnections[streamId]

		self:removeStreamFromClients(streamId)

		if connection ~= nil and self.networkListener ~= nil then
			self.networkListener:onConnectionClosed(connection)
		end
	end
end

function Server:removeStreamFromClients(streamId)
	for i = 1, #self.clients do
		if self.clients[i] == streamId then
			table.remove(self.clients, i)

			break
		end
	end

	if self.clientConnections[streamId] ~= nil then
		self.clientConnections[streamId].isConnected = false

		self.clientConnections[streamId]:setIsReadyForEvents(false)
		self.clientConnections[streamId]:setIsReadyForObjects(false)

		self.clientConnections[streamId] = nil
	end
end

function Server:registerObject(object, alreadySent)
	if not object.isRegistered then
		object.isRegistered = true

		self:addObject(object, object.id)

		object.isManuallyReplicated = alreadySent

		if alreadySent then
			for streamId, connection in pairs(self.clientConnections) do
				if streamId ~= NetworkNode.LOCAL_STREAM_ID then
					connection.objectsInfo[object.id] = {
						dirtyMask = 0,
						skipCount = 0,
						sync = Connection.SYNC_MANUALLY_REGISTERED,
						history = {}
					}
				end
			end
		end
	end
end

function Server:unregisterObject(object, alreadySent)
	if object.isRegistered then
		local objectId = object.id

		if self.objects[objectId] ~= nil then
			self:removeObject(object, object.id)

			for _, connection in pairs(self.clientConnections) do
				connection:notifyObjectDeleted(objectId, alreadySent)
			end
		end

		object.isRegistered = false
	end
end

function Server:broadcastEvent(event, sendLocal, ignoreConnection, ghostObject, force, connectionList, allowQueuing)
	local connections = connectionList or self.clientConnections

	for k, v in pairs(connections) do
		if (k ~= NetworkNode.LOCAL_STREAM_ID or sendLocal) and (ignoreConnection == nil or v ~= ignoreConnection) then
			if ghostObject == nil or self:hasGhostObject(v, ghostObject) then
				self.currentSendEventConnection = v

				v:sendEvent(event, false, force)

				self.currentSendEventConnection = nil
			elseif ghostObject ~= nil and allowQueuing then
				v:queueSendEvent(event, force, ghostObject)
			end
		end
	end

	if event.queueCount == 0 then
		event:delete()
	end
end

function Server:sendEventIds(connection)
	local streamId = connection.streamId

	streamWriteUIntN(streamId, MessageIds.EVENT_IDS, MessageIds.SEND_NUM_BITS)

	local numIds = 0

	for _, _ in pairs(EventIds.eventClasses) do
		numIds = numIds + 1
	end

	streamWriteInt32(streamId, numIds)

	for className, classObject in pairs(EventIds.eventClasses) do
		streamWriteUIntN(streamId, classObject.eventId, EventIds.SEND_NUM_BITS)
		streamWriteString(streamId, className)
	end

	netSendStream(streamId, "high", "reliable_ordered", 1, true)
end

function Server:sendObjectClassIds(connection)
	local streamId = connection.streamId

	streamWriteUIntN(streamId, MessageIds.OBJECT_CLASS_IDS, MessageIds.SEND_NUM_BITS)

	local numIds = 0

	for _, _ in pairs(ObjectIds.objectClasses) do
		numIds = numIds + 1
	end

	streamWriteInt32(streamId, numIds)

	for className, classObject in pairs(ObjectIds.objectClasses) do
		streamWriteUIntN(streamId, classObject.classId, ObjectIds.SEND_NUM_BITS)
		streamWriteString(streamId, className)
	end

	netSendStream(streamId, "high", "reliable_ordered", 1, true)
end

function Server:sendObjects(connection, x, y, z, viewDistanceCoeff)
	connection:setIsReadyForObjects(false)

	self.currentWriteStreamConnection = connection
	self.currentWriteStreamConnectionIsInitial = true
	local streamId = connection.streamId
	local objectsInfo = connection.objectsInfo

	streamWriteUIntN(streamId, MessageIds.OBJECT_INITIAL_ARRAY, MessageIds.SEND_NUM_BITS)
	streamWriteBool(streamId, g_networkDebug)

	local numToSendOffset = streamGetWriteOffset(streamId)

	streamWriteInt32(streamId, 0)

	local numToSend = 0

	for _, object in pairs(self.objects) do
		if objectsInfo[object.id] == nil and not object.isManuallyReplicated and object:testScope(x, y, z, viewDistanceCoeff) then
			numToSend = numToSend + 1
			local startOffset = 0

			if g_networkDebug then
				startOffset = streamGetWriteOffset(streamId)

				streamWriteInt32(streamId, 0)
			end

			streamWriteUIntN(streamId, object.classId, ObjectIds.SEND_NUM_BITS)
			NetworkUtil.writeNodeObjectId(streamId, object.id)
			object:writeStream(streamId, connection)

			objectsInfo[object.id] = {
				dirtyMask = 0,
				skipCount = 0,
				sync = Connection.SYNC_CREATED,
				history = {}
			}

			if g_networkDebug then
				local endOffset = streamGetWriteOffset(streamId)

				streamSetWriteOffset(streamId, startOffset)
				streamWriteInt32(streamId, endOffset - (startOffset + 32))
				streamSetWriteOffset(streamId, endOffset)
			end
		end
	end

	local endOffset = streamGetWriteOffset(streamId)

	streamSetWriteOffset(streamId, numToSendOffset)
	streamWriteInt32(streamId, numToSend)
	streamSetWriteOffset(streamId, endOffset)
	netSendStream(streamId, "high", "reliable_ordered", 1, true)

	self.currentWriteStreamConnection = nil
end

function Server:setClientPosition(client, x, y, z)
	self.clientPositions[client] = {
		x,
		y,
		z
	}
end

function Server:getClientPosition(client)
	local pos = self.clientPositions[client]

	if pos ~= nil then
		return unpack(pos)
	end

	return 0, 0, 0
end

function Server:setClientClipDistCoeff(client, coeff)
	self.clientClipDistCoeffs[client] = coeff
end

function Server:getClientClipDistCoeff(client)
	local ret = self.clientClipDistCoeffs[client]

	if ret == nil then
		ret = 1
	end

	return ret
end

function Server:hasGhostObject(connection, ghostObject)
	if connection:getIsLocal() then
		return true
	end

	local objectInfo = connection.objectsInfo[ghostObject.id]

	return objectInfo ~= nil and objectInfo.sync == Connection.SYNC_CREATED
end

function Server:finishRegisterObject(connection, object)
	local objectInfo = connection.objectsInfo[object.id]

	if objectInfo ~= nil and objectInfo.sync == Connection.SYNC_MANUALLY_REGISTERED then
		objectInfo.sync = Connection.SYNC_CREATED

		connection:sendObjectEventQueue(objectInfo)
	end
end

function Server:registerObjectInStream(connection, object)
	if self.currentWriteStreamConnection ~= connection and self.currentSendEventConnection ~= connection then
		print("Error: Server:registerObjectInStream is only allowed in writeStream calls")

		return
	end

	local objectInfo = connection.objectsInfo[object.id]

	if objectInfo ~= nil and objectInfo.sync == Connection.SYNC_MANUALLY_REGISTERED then
		if self.currentWriteStreamConnectionIsInitial then
			objectInfo.sync = Connection.SYNC_CREATED
		else
			objectInfo.sync = Connection.SYNC_CREATING
			objectInfo.history[connection.lastSeqSent] = {
				mask = 0,
				sync = Connection.SYNC_HIST_CREATE
			}
		end

		objectInfo.dirtyMask = 0
		objectInfo.skipCount = 0
	end
end

function Server.prioCmp(w1, w2)
	if w2.prio < w1.prio then
		return true
	else
		return false
	end
end

function Server:consoleCommandToggleNetworkDebug()
	g_networkDebug = not g_networkDebug

	return "NetworkDebug = " .. tostring(g_networkDebug)
end
