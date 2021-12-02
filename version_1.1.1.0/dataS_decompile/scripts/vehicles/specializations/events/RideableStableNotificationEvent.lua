RideableStableNotificationEvent = {}
local RideableStableNotificationEvent_mt = Class(RideableStableNotificationEvent, Event)

InitStaticEventClass(RideableStableNotificationEvent, "RideableStableNotificationEvent", EventIds.EVENT_RIDEABLE_STABLE_NOTIFICATION)

function RideableStableNotificationEvent.emptyNew()
	local self = Event.new(RideableStableNotificationEvent_mt)

	return self
end

function RideableStableNotificationEvent.new(isInStable, name)
	local self = RideableStableNotificationEvent.emptyNew()
	self.isInStable = isInStable
	self.name = name

	return self
end

function RideableStableNotificationEvent:readStream(streamId, connection)
	self.isInStable = streamReadBool(streamId)
	self.name = streamReadString(streamId)

	self:run(connection)
end

function RideableStableNotificationEvent:writeStream(streamId, connection)
	streamWriteBool(streamId, self.isInStable)
	streamWriteString(streamId, self.name)
end

function RideableStableNotificationEvent:run(connection)
	if self.isInStable then
		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("ingameNotification_horseInStable"), self.name))
	else
		g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("ingameNotification_horseNotInStable"), self.name))
	end
end
