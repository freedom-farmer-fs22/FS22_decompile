MissionCancelEvent = {}
local MissionCancelEvent_mt = Class(MissionCancelEvent, Event)

InitStaticEventClass(MissionCancelEvent, "MissionCancelEvent", EventIds.EVENT_MISSION_CANCEL)

function MissionCancelEvent.emptyNew()
	local self = Event.new(MissionCancelEvent_mt)

	return self
end

function MissionCancelEvent.new(mission)
	local self = MissionCancelEvent.emptyNew()
	self.mission = mission

	return self
end

function MissionCancelEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.mission)
end

function MissionCancelEvent:readStream(streamId, connection)
	self.mission = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function MissionCancelEvent:run(connection)
	if not connection:getIsServer() then
		local senderUserId = g_currentMission.userManager:getUserIdByConnection(connection)
		local senderFarm = g_farmManager:getFarmByUserId(senderUserId)
		local isMasterUser = connection:getIsLocal() or g_currentMission.userManager:getIsConnectionMasterUser(connection)

		if g_currentMission:getHasPlayerPermission("manageContracts", connection, senderFarm.farmId) and (self.mission.farmId == senderFarm.farmId or isMasterUser) then
			g_missionManager:cancelMission(self.mission)
		end
	end
end
