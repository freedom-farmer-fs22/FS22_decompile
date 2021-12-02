KickBanNotificationEvent = {}
local KickBanNotificationEvent_mt = Class(KickBanNotificationEvent, Event)

InitStaticEventClass(KickBanNotificationEvent, "KickBanNotificationEvent", EventIds.EVENT_KICK_BAN_NOTIFICATION)

function KickBanNotificationEvent.emptyNew()
	local self = Event.new(KickBanNotificationEvent_mt, 1)

	return self
end

function KickBanNotificationEvent.new(doKick)
	local self = KickBanNotificationEvent.emptyNew()
	self.doKick = doKick

	return self
end

function KickBanNotificationEvent:readStream(streamId, connection)
	assert(connection:getIsServer(), "KickBanNotificationEvent is a server to client only event")

	if connection:getIsServer() then
		if streamReadBool(streamId) then
			g_currentMission:setConnectionLostState(FSBaseMission.CONNECTION_LOST_KICKED)
		else
			g_currentMission:setConnectionLostState(FSBaseMission.CONNECTION_LOST_BANNED)
		end
	end
end

function KickBanNotificationEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		streamWriteBool(streamId, self.doKick)
	end
end
