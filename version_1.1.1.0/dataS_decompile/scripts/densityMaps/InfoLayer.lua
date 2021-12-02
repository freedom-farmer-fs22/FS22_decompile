InfoLayer = {}
local InfoLayer_mt = Class(InfoLayer)

function InfoLayer.new(name, baseDirectory, customMt)
	local self = setmetatable({}, customMt or InfoLayer_mt)
	self.baseDirectory = baseDirectory
	self.bitVector = createBitVectorMap(name)
	self.name = name
	self.width = 0
	self.height = 0
	self.doDelete = true

	return self
end

function InfoLayer:loadFromXML(xmlFile, key)
	local filename = Utils.getFilename(xmlFile:getString(key .. "#filename"), self.baseDirectory)
	local numChannels = xmlFile:getInt(key .. "#numChannels")

	return self:load(filename, numChannels)
end

function InfoLayer:load(filename, numChannels)
	local success = loadBitVectorMapFromFile(self.bitVector, filename, numChannels)

	if not success then
		print("Warning: Loading infolayer '" .. self.name .. "' file '" .. tostring(filename) .. "' failed!")

		return false
	end

	self.numChannels = numChannels
	self.width, self.height = getBitVectorMapSize(self.bitVector)

	return true
end

function InfoLayer:create(width, height, numChannels, initAll)
	loadBitVectorMapNew(self.bitVector, width, height, numChannels, initAll)

	self.numChannels = numChannels
	self.width = width
	self.height = height

	return true
end

function InfoLayer:loadFromMap(terrainNode, name)
	local infoLayerId = nil

	if infoLayerId ~= nil then
		return self:loadFromMemory(infoLayerId)
	end

	return false
end

function InfoLayer:loadFromMemory(id)
	self.doDelete = false
	self.bitVector = id
	self.numChannels = getBitVectorMapNumChannels(id)
	self.width, self.height = getBitVectorMapSize(id)

	return true
end

function InfoLayer:delete()
	if self.doDelete then
		delete(self.bitVector)
	end
end

function InfoLayer:writeStream(streamId, connection)
	writeBitVectorMapToStream(self.bitVector, streamId)
end

function InfoLayer:readStream(streamId, connection)
	readBitVectorMapFromStream(self.bitVector, streamId)
end

function InfoLayer:convertWorldToLocalPosition(worldPosX, worldPosZ)
	local terrainSize = g_currentMission.terrainSize

	return math.floor(self.width * (worldPosX + terrainSize * 0.5) / terrainSize), math.floor(self.height * (worldPosZ + terrainSize * 0.5) / terrainSize)
end

function InfoLayer:getValueAtWorldPos(worldX, worldZ, firstChannel, numChannels)
	local x, y = self:convertWorldToLocalPosition(worldX, worldZ)

	return getBitVectorMapPoint(self.bitVector, x, y, firstChannel or 0, numChannels or self.numChannels)
end

function InfoLayer:getValueAtPos(x, y, firstChannel, numChannels)
	return getBitVectorMapPoint(self.bitVector, x, y, firstChannel or 0, numChannels or self.numChannels)
end

function InfoLayer:getValueAtParallelogram(x, y, widthX, widthY, heightX, heightY, firstChannel, numChannels)
	return getBitVectorMapParallelogram(self.bitVector, x, y, widthX, widthY, heightX, heightY, firstChannel or 0, numChannels or self.numChannels)
end

function InfoLayer:getValueAtWorldParallelogram(worldX, worldZ, worldWidthX, worldWidthZ, worldHeightX, worldHeightZ, firstChannel, numChannels)
	local x, y = self:convertWorldToLocalPosition(worldX, worldZ)
	local widthX, widthY = self:convertWorldToLocalPosition(worldWidthX, worldWidthZ)
	local heightX, heightY = self:convertWorldToLocalPosition(worldHeightX, worldHeightZ)

	return getBitVectorMapParallelogram(self.bitVector, x, y, widthX, widthY, heightX, heightY, firstChannel or 0, numChannels or self.numChannels)
end

function InfoLayer:saveToFile(filename, asyncCallback, asyncTarget)
	if asyncCallback == nil then
		saveBitVectorMapToFile(self.bitVector, filename)
	else
		prepareSaveBitVectorMapToFile(self.bitVector, filename)
		savePreparedBitVectorMapToFile(self.bitVector, asyncCallback, asyncTarget)
	end
end
