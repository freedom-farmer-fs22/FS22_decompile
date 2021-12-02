MissionDynamicInfoEvent = {}
local MissionDynamicInfoEvent_mt = Class(MissionDynamicInfoEvent, Event)

InitStaticEventClass(MissionDynamicInfoEvent, "MissionDynamicInfoEvent", EventIds.EVENT_MISSION_INFO_DYNAMIC)

MissionDynamicInfoEvent.sendCapNumBits = 4

function MissionDynamicInfoEvent.emptyNew()
	local self = Event.new(MissionDynamicInfoEvent_mt)

	return self
end

function MissionDynamicInfoEvent.new()
	local self = MissionDynamicInfoEvent.emptyNew()

	return self
end

function MissionDynamicInfoEvent:readStream(streamId, connection)
	local serverName = streamReadString(streamId)
	local autoAccept = streamReadBool(streamId)
	local password = streamReadString(streamId)
	local capacity = streamReadUIntN(streamId, MissionDynamicInfoEvent.sendCapNumBits) + 1
	local allowOnlyFriends = false

	if GS_IS_CONSOLE_VERSION then
		allowOnlyFriends = streamReadBool(streamId)
	end

	local allowCrossPlay = streamReadBool(streamId)

	g_currentMission:updateMissionDynamicInfo(serverName, capacity, password, autoAccept, allowOnlyFriends, allowCrossPlay)

	if not connection:getIsServer() then
		g_currentMission:updateMasterServerInfo(connection)
	end
end

function MissionDynamicInfoEvent:writeStream(streamId, connection)
	streamWriteString(streamId, g_currentMission.missionDynamicInfo.serverName)
	streamWriteBool(streamId, g_currentMission.missionDynamicInfo.autoAccept)
	streamWriteString(streamId, g_currentMission.missionDynamicInfo.password)
	streamWriteUIntN(streamId, g_currentMission.missionDynamicInfo.capacity - 1, MissionDynamicInfoEvent.sendCapNumBits)

	if GS_IS_CONSOLE_VERSION then
		streamWriteBool(streamId, g_currentMission.missionDynamicInfo.allowOnlyFriends)
	end

	streamWriteBool(streamId, g_currentMission.missionDynamicInfo.allowCrossPlay)
end

function MissionDynamicInfoEvent:run(connection)
end
