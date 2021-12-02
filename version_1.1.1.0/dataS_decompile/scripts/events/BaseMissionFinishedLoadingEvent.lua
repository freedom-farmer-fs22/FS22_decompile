BaseMissionFinishedLoadingEvent = {}
local BaseMissionFinishedLoadingEvent_mt = Class(BaseMissionFinishedLoadingEvent, Event)

InitStaticEventClass(BaseMissionFinishedLoadingEvent, "BaseMissionFinishedLoadingEvent", EventIds.EVENT_FINISHED_LOADING)

function BaseMissionFinishedLoadingEvent.emptyNew()
	local self = Event.new(BaseMissionFinishedLoadingEvent_mt)

	return self
end

function BaseMissionFinishedLoadingEvent.new(posX, posY, posZ, viewDistanceCoeff)
	local self = BaseMissionFinishedLoadingEvent.emptyNew()
	self.posX = posX
	self.posY = posY
	self.posZ = posZ
	self.viewDistanceCoeff = viewDistanceCoeff

	return self
end

function BaseMissionFinishedLoadingEvent:readStream(streamId, connection)
	self.posX = streamReadFloat32(streamId)
	self.posY = streamReadFloat32(streamId)
	self.posZ = streamReadFloat32(streamId)
	self.viewDistanceCoeff = streamReadFloat32(streamId)

	self:run(connection)
end

function BaseMissionFinishedLoadingEvent:writeStream(streamId, connection)
	streamWriteFloat32(streamId, self.posX)
	streamWriteFloat32(streamId, self.posY)
	streamWriteFloat32(streamId, self.posZ)
	streamWriteFloat32(streamId, self.viewDistanceCoeff)
end

function BaseMissionFinishedLoadingEvent:run(connection)
	if g_currentMission ~= nil then
		g_currentMission:onConnectionFinishedLoading(connection, self.posX, self.posY, self.posZ, self.viewDistanceCoeff)
	end
end
