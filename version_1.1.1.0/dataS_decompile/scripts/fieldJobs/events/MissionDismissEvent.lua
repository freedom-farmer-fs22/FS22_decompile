MissionDismissEvent = {}
local MissionDismissEvent_mt = Class(MissionDismissEvent, Event)

InitStaticEventClass(MissionDismissEvent, "MissionDismissEvent", EventIds.EVENT_MISSION_DISMISS)

function MissionDismissEvent.emptyNew()
	local self = Event.new(MissionDismissEvent_mt)

	return self
end

function MissionDismissEvent.new(mission)
	local self = MissionDismissEvent.emptyNew()
	self.mission = mission

	return self
end

function MissionDismissEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.mission)
end

function MissionDismissEvent:readStream(streamId, connection)
	self.mission = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function MissionDismissEvent:run(connection)
	if not connection:getIsServer() then
		local senderUserId = g_currentMission.userManager:getUserIdByConnection(connection)
		local senderFarm = g_farmManager:getFarmByUserId(senderUserId)
		local isMasterUser = connection:getIsLocal() or g_currentMission.userManager:getIsConnectionMasterUser(connection)

		if g_currentMission:getHasPlayerPermission("manageContracts", connection, senderFarm.farmId) and (self.mission.farmId == senderFarm.farmId or isMasterUser) then
			g_missionManager:dismissMission(self.mission)
			g_messageCenter:publish(MissionDismissEvent, self.mission)
		end
	else
		g_missionManager:removeMissionFromList(self.mission)
		g_messageCenter:publish(MissionDismissEvent, self.mission)
	end
end
