SetSplitShapesEvent = {}
local SetSplitShapesEvent_mt = Class(SetSplitShapesEvent, Event)

InitStaticEventClass(SetSplitShapesEvent, "SetSplitShapesEvent", EventIds.EVENT_SET_SPLIT_SHAPES)

SetSplitShapesEvent.PartSizeBits = 160000

function SetSplitShapesEvent.emptyNew()
	local self = Event.new(SetSplitShapesEvent_mt)
	self.streamId = createStream()

	return self
end

function SetSplitShapesEvent.newAck(ackIndex)
	local self = SetSplitShapesEvent.emptyNew()
	self.ackIndex = ackIndex

	return self
end

function SetSplitShapesEvent.newReceiving(numParts)
	local self = SetSplitShapesEvent.emptyNew()
	self.numParts = numParts

	return self
end

function SetSplitShapesEvent.new()
	local self = SetSplitShapesEvent.emptyNew()
	local streamId = self.streamId
	local numFileIds = table.getn(g_currentMission.mapsSplitShapeFileIds)

	streamWriteInt32(streamId, numFileIds)

	for i = 1, numFileIds do
		streamWriteInt32(streamId, g_currentMission.mapsSplitShapeFileIds[i])
	end

	g_treePlantManager:writeToClientStream(streamId)
	writeSplitShapesToStream(streamId)

	self.currentPartIndex = 0
	self.numParts = math.ceil(streamGetWriteOffset(streamId) / SetSplitShapesEvent.PartSizeBits)
	self.percentage = 0

	return self
end

function SetSplitShapesEvent:delete()
	if self.streamId ~= 0 then
		delete(self.streamId)

		self.streamId = 0
	end
end

function SetSplitShapesEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		local currentPartIndex = streamReadInt32(streamId)

		if currentPartIndex == 0 then
			local numParts = streamReadInt32(streamId)
			g_currentMission.receivingSplitShapesEvent = SetSplitShapesEvent.newReceiving(numParts)
		end

		local event = g_currentMission.receivingSplitShapesEvent

		streamWriteStream(event.streamId, streamId, SetSplitShapesEvent.PartSizeBits, true)
		g_currentMission:onSplitShapesProgress(connection, (currentPartIndex + 1) / event.numParts)
		connection:sendEvent(SetSplitShapesEvent.newAck(currentPartIndex))

		if currentPartIndex == event.numParts - 1 then
			event:processReadData()
			g_currentMission.receivingSplitShapesEvent:delete()

			g_currentMission.receivingSplitShapesEvent = nil
		end
	else
		local ackIndex = streamReadInt32(streamId)
		local syncPlayer = g_currentMission.playersSynchronizing[connection]

		if syncPlayer ~= nil and syncPlayer.splitShapesEvent ~= nil then
			local splitShapesEvent = syncPlayer.splitShapesEvent
			splitShapesEvent.percentage = (ackIndex + 1) / splitShapesEvent.numParts

			if ackIndex + 1 < splitShapesEvent.numParts then
				connection:sendEvent(splitShapesEvent, false)
			end

			g_currentMission:onSplitShapesProgress(connection, (ackIndex + 1) / splitShapesEvent.numParts)
		end
	end
end

function SetSplitShapesEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		assert(g_currentMission.playersSynchronizing[connection].splitShapesEvent == self)

		local currentPartIndex = self.currentPartIndex
		self.currentPartIndex = currentPartIndex + 1

		streamWriteInt32(streamId, currentPartIndex)

		if currentPartIndex == 0 then
			streamWriteInt32(streamId, self.numParts)
		end

		local readOffset = streamGetReadOffset(self.streamId)

		streamSetReadOffset(self.streamId, currentPartIndex * SetSplitShapesEvent.PartSizeBits)
		streamWriteStream(streamId, self.streamId, SetSplitShapesEvent.PartSizeBits, true)
		streamSetReadOffset(self.streamId, readOffset)
	else
		streamWriteInt32(streamId, self.ackIndex)
	end
end

function SetSplitShapesEvent:processReadData()
	local streamId = self.streamId
	local numFileIds = streamReadInt32(streamId)

	for i = 1, numFileIds do
		local fileId = streamReadInt32(streamId)

		setSplitShapesFileIdMapping(g_currentMission.mapsSplitShapeFileIds[i], fileId)
	end

	g_treePlantManager:readFromServerStream(streamId)
	readSplitShapesFromStream(streamId)
end

function SetSplitShapesEvent:run(connection)
end
