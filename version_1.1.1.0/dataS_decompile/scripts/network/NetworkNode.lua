NetworkNode = {}
local NetworkNode_mt = Class(NetworkNode)
NetworkNode.LOCAL_STREAM_ID = 0
NetworkNode.PACKET_EVENT = 1
NetworkNode.PACKET_VEHICLE = 2
NetworkNode.PACKET_PLAYER = 3
NetworkNode.PACKET_SPLITSHAPES = 4
NetworkNode.PACKET_DENSITY_MAPS = 5
NetworkNode.PACKET_TERRAIN_DEFORM = 6
NetworkNode.PACKET_VOICE_CHAT = 7
NetworkNode.PACKET_OTHERS = 8
NetworkNode.NUM_PACKETS = 8
NetworkNode.CHANNEL_MAIN = 1
NetworkNode.CHANNEL_SECONDARY = 2
NetworkNode.CHANNEL_GROUND = 3
NetworkNode.CHANNEL_CHAT = 4
NetworkNode.OBJECT_SEND_NUM_BITS = 24

function NetworkNode.new(customMt)
	local self = setmetatable({}, customMt or NetworkNode_mt)
	self.objects = {}
	self.objectIds = {}
	self.activeObjects = {}
	self.activeObjectsNextFrame = {}
	self.removedObjects = {}
	self.dirtyObjects = {}
	self.lastUploadedKBs = 0
	self.lastUploadedKBsSmooth = 0
	self.maxUploadedKBs = 0
	self.graphColors = {
		[NetworkNode.PACKET_EVENT] = {
			1,
			0,
			0,
			1
		},
		[NetworkNode.PACKET_VEHICLE] = {
			0,
			1,
			0,
			1
		},
		[NetworkNode.PACKET_PLAYER] = {
			0,
			0,
			1,
			1
		},
		[NetworkNode.PACKET_SPLITSHAPES] = {
			1,
			1,
			0,
			1
		},
		[NetworkNode.PACKET_DENSITY_MAPS] = {
			0.5,
			0.5,
			0,
			1
		},
		[NetworkNode.PACKET_TERRAIN_DEFORM] = {
			0.5,
			0.5,
			0.5,
			1
		},
		[NetworkNode.PACKET_VOICE_CHAT] = {
			1,
			0.5,
			0.5,
			1
		},
		[NetworkNode.PACKET_OTHERS] = {
			0,
			1,
			1,
			1
		}
	}
	self.packetGraphs = {}
	self.packetBytes = {}

	for i = 1, NetworkNode.NUM_PACKETS do
		local showGraphLabels = i == 1
		self.packetGraphs[i] = Graph.new(80, 0.2, 0.22, 0.6, 0.6, 0, 1000, showGraphLabels, "bytes")

		self.packetGraphs[i]:setColor(self.graphColors[i][1], self.graphColors[i][2], self.graphColors[i][3], self.graphColors[i][4])

		self.packetBytes[i] = 0
	end

	self.showNetworkTraffic = false
	self.showObjects = false

	return self
end

function NetworkNode:delete()
	for _, object in pairs(self.objects) do
		self:unregisterObject(object, true)
		object:delete()
	end

	self.objects = {}
	self.objectIds = {}
	self.activeObjects = {}
	self.activeObjectsNextFrame = {}
	self.removedObjects = {}
	self.dirtyObjects = {}

	for i = 1, NetworkNode.NUM_PACKETS do
		self.packetGraphs[i]:delete()
	end
end

function NetworkNode:setNetworkListener(listener)
	self.networkListener = listener
end

function NetworkNode:keyEvent(unicode, sym, modifier, isDown)
end

function NetworkNode:mouseEvent(posX, posY, isDown, isUp, button)
end

function NetworkNode:update(dt)
end

function NetworkNode:updateActiveObjects(dt)
	for id, object in pairs(self.removedObjects) do
		self.activeObjects[id] = nil
		self.activeObjectsNextFrame[id] = nil
		self.removedObjects[id] = nil
	end

	for _, object in pairs(self.activeObjects) do
		if object.recieveUpdates then
			object:update(dt)
		end
	end
end

function NetworkNode:updateActiveObjectsTick(dt)
	for i = #self.dirtyObjects, 1, -1 do
		self.dirtyObjects[i] = nil
	end

	for serverId, object in pairs(self.activeObjects) do
		if object.recieveUpdates then
			object:updateTick(dt)
		end

		if object.dirtyMask ~= 0 then
			object.lastServerId = serverId

			table.insert(self.dirtyObjects, object)
		end

		local id = self:getObjectId(object)
		self.activeObjects[id] = nil

		if object.recieveUpdates and self.activeObjectsNextFrame[id] == nil then
			object:updateEnd(dt)
		end
	end

	local oldObject = self.activeObjects
	self.activeObjects = self.activeObjectsNextFrame
	self.activeObjectsNextFrame = oldObject

	return self.dirtyObjects
end

function NetworkNode:drawConnectionNetworkStats(connection, offsetY)
	if connection.streamId == NetworkNode.LOCAL_STREAM_ID then
		return false
	end

	local ping, download, upload, packetLoss = netGetConnectionStats(connection.streamId)

	if ping == nil then
		packetLoss = 0
		upload = 0
		download = 0
		ping = 0
	end

	if connection.pingSmooth == nil then
		connection.packetLossSmooth = packetLoss
		connection.uploadSmooth = upload
		connection.downloadSmooth = download
		connection.pingSmooth = ping
	end

	connection.pingSmooth = connection.pingSmooth + (ping - connection.pingSmooth) * 0.2
	connection.downloadSmooth = connection.downloadSmooth + (download - connection.downloadSmooth) * 0.2
	connection.uploadSmooth = connection.uploadSmooth + (upload - connection.uploadSmooth) * 0.2
	connection.packetLossSmooth = connection.packetLossSmooth + (packetLoss - connection.packetLossSmooth) * 0.2
	packetLoss = connection.packetLossSmooth
	upload = connection.uploadSmooth
	download = connection.downloadSmooth
	ping = connection.pingSmooth

	renderText(0.5, 0.77 - offsetY * 0.03, 0.025, string.format("%dms", ping))
	renderText(0.55, 0.77 - offsetY * 0.03, 0.025, string.format("w:%2d", connection.lastSeqSent - connection.highestAckedSeq))
	renderText(0.6, 0.77 - offsetY * 0.03, 0.025, string.format("d:%4.2fkb/s", download / 1024))
	renderText(0.69, 0.77 - offsetY * 0.03, 0.025, string.format("u:%4.2fkb/s", upload / 1024))
	renderText(0.78, 0.77 - offsetY * 0.03, 0.025, string.format("l:%4.2f%%", packetLoss * 100))
	renderText(0.85, 0.77 - offsetY * 0.03, 0.025, string.format("comp:%.2f%%", 1 / connection.compressionRatio * 100))

	return true
end

function NetworkNode:getObjectPacketType(object)
	if object == nil then
		return NetworkNode.PACKET_OTHERS
	elseif object:isa(Vehicle) then
		return NetworkNode.PACKET_VEHICLE
	elseif object:isa(Player) then
		return NetworkNode.PACKET_PLAYER
	else
		return NetworkNode.PACKET_OTHERS
	end
end

function NetworkNode:getPacketTypeName(packetType)
	for key, value in pairs(Network) do
		if value == packetType then
			return key
		end
	end

	return "TYPE_UNKNOWN"
end

function NetworkNode:checkObjectUpdateDebugReadSize(streamId, numBits, startOffset, name, object)
	local endOffset = streamGetReadOffset(streamId)
	local readNumBits = endOffset - (startOffset + 32)

	if readNumBits ~= numBits then
		local objectInfo = ""

		if object ~= nil then
			objectInfo = ": " .. object.className

			if object.configFileName ~= nil then
				objectInfo = objectInfo .. " (" .. object.configFileName .. ")"
			end
		end

		print("Error: Not all bits read in object " .. name .. " (" .. readNumBits .. " vs " .. numBits .. ")" .. objectInfo)
	end
end

function NetworkNode:addPacketSize(packetType, packetSizeInBytes)
	if self.showNetworkTraffic then
		self.packetBytes[packetType] = self.packetBytes[packetType] + packetSizeInBytes
	end
end

function NetworkNode:updatePacketStats(dt)
	if self.showNetworkTraffic then
		local packetBytesSum = 0

		for i = 1, NetworkNode.NUM_PACKETS do
			self.packetGraphs[i]:addValue(packetBytesSum + self.packetBytes[i], packetBytesSum)

			packetBytesSum = packetBytesSum + self.packetBytes[i]
			self.packetBytes[i] = 0
		end

		self.lastUploadedKBs = packetBytesSum / 1024 * 1000 / dt
	end
end

function NetworkNode:draw()
	if self.showNetworkTraffic then
		local smoothAlpha = 0.8
		self.lastUploadedKBsSmooth = self.lastUploadedKBsSmooth * smoothAlpha + self.lastUploadedKBs * (1 - smoothAlpha)

		renderText(0.6, 0.8, getCorrectTextSize(0.025), string.format("Game Data Upload %.2fkb/s ", self.lastUploadedKBsSmooth))

		for i = 1, NetworkNode.NUM_PACKETS do
			self.packetGraphs[i]:draw()
		end

		local x = self.packetGraphs[1].left + self.packetGraphs[1].width + 0.01
		local y = self.packetGraphs[1].bottom
		local textSize = getCorrectTextSize(0.025)

		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_EVENT]))
		renderText(x, y, textSize, "event")
		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_VEHICLE]))
		renderText(x, y + textSize, textSize, "vehicle")
		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_PLAYER]))
		renderText(x, y + 2 * textSize, textSize, "player")
		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_SPLITSHAPES]))
		renderText(x, y + 3 * textSize, textSize, "split shapes")
		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_DENSITY_MAPS]))
		renderText(x, y + 4 * textSize, textSize, "density maps")
		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_TERRAIN_DEFORM]))
		renderText(x, y + 5 * textSize, textSize, "terrain deform")
		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_VOICE_CHAT]))
		renderText(x, y + 6 * textSize, textSize, "voice chat")
		setTextColor(unpack(self.graphColors[NetworkNode.PACKET_OTHERS]))
		renderText(x, y + 7 * textSize, textSize, "others")
		setTextColor(1, 1, 1, 1)

		if self.clientConnections ~= nil then
			local i = 0

			for _, connection in pairs(self.clientConnections) do
				if self:drawConnectionNetworkStats(connection, i) then
					i = i + 1
				end
			end
		elseif self.serverConnection ~= nil then
			self:drawConnectionNetworkStats(self.serverConnection, 0)
		end
	end

	if self.showObjects then
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_LEFT)

		local count = 0

		for id, object in pairs(self.activeObjects) do
			count = count + 1
			object.serverId = self.objectIds[object] or 0
		end

		local allObjects = {}

		for _, object in pairs(self.objects) do
			object.serverId = self.objectIds[object] or 0
			object.debugClassName = tostring(ClassUtil.getClassNameByObject(object))

			table.insert(allObjects, object)
		end

		local sortByClassName = self.debugSortByClassName

		table.sort(allObjects, function (a, b)
			if sortByClassName and a.debugClassName ~= b.debugClassName then
				return a.debugClassName < b.debugClassName
			end

			return a.serverId < b.serverId
		end)

		local posX = 0.015
		local posY = 0.96
		local offsetX = 1 / g_screenWidth
		local offsetY = -1 / g_screenHeight
		local title = string.format("Registered Objects: %d | Objects in update-loop: %d", #allObjects, count)

		setTextColor(0, 0, 0, 1)
		renderText(posX + offsetX, 0.98 + offsetY, 0.013, title)
		setTextColor(1, 1, 1, 1)
		renderText(posX, 0.98, 0.013, title)

		for _, object in ipairs(allObjects) do
			local path = object.configFileName

			if path ~= nil then
				path = Utils.getFilenameFromPath(path)
			end

			local serverId = tostring(object.serverId)
			local text = string.format(" - %s - %s", object.debugClassName, tostring(path))
			local isActive = self.activeObjects[object.serverId] ~= nil

			setTextBold(isActive)
			setTextColor(0, 0, 0, 1)
			renderText(posX + offsetX, posY + offsetY, 0.01, text)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(posX + offsetX, posY + offsetY, 0.01, serverId)

			if isActive then
				setTextColor(0.1254, 0.7647, 0, 1)
			else
				setTextColor(1, 1, 1, 1)
			end

			renderText(posX, posY, 0.01, serverId)
			setTextAlignment(RenderText.ALIGN_LEFT)
			renderText(posX, posY, 0.01, text)

			posY = posY - 0.011

			if posY < 0 then
				posX = posX + 0.14
				posY = 0.96
			end
		end

		setTextBold(false)
		setTextColor(1, 1, 1, 1)
	end
end

function NetworkNode:packetReceived(packetType, timestamp, streamId)
end

function NetworkNode:getObject(id)
	return self.objects[id]
end

function NetworkNode:getObjectId(object)
	return self.objectIds[object]
end

function NetworkNode:addObject(object, id)
	self.objects[id] = object
	self.objectIds[object] = id

	self:addObjectToUpdateLoop(object)

	if self.networkListener ~= nil then
		self.networkListener:onObjectCreated(object)
	end
end

function NetworkNode:removeObject(object, id)
	self:removeObjectFromUpdateLoop(object)

	if self.networkListener ~= nil then
		self.networkListener:onObjectDeleted(object)
	end

	self.objects[id] = nil
	self.objectIds[object] = nil
end

function NetworkNode:addObjectToUpdateLoop(object)
	if object.isRegistered then
		local id = self:getObjectId(object)

		if id ~= nil then
			self.activeObjects[id] = object
			self.activeObjectsNextFrame[id] = object
		end
	end
end

function NetworkNode:removeObjectFromUpdateLoop(object)
	local id = self:getObjectId(object)

	if id ~= nil then
		self.removedObjects[id] = object
		self.activeObjects[id] = nil
		self.activeObjectsNextFrame[id] = nil
	end
end

function NetworkNode:registerObject(object, alreadySent)
end

function NetworkNode:unregisterObject(object, alreadySent)
end

function NetworkNode:consoleCommandToggleShowNetworkTraffic()
	self.showNetworkTraffic = not self.showNetworkTraffic

	return "ShowNetworkTraffic = " .. tostring(self.showNetworkTraffic)
end

function NetworkNode:consoleCommandToggleNetworkShowObjects(sortByClassName)
	self.showObjects = not self.showObjects
	self.debugSortByClassName = string.lower(sortByClassName or "true") == "true"

	return "NetworkShowObjects = " .. tostring(self.showObjects)
end
