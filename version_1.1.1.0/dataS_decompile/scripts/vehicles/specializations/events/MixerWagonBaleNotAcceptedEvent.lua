MixerWagonBaleNotAcceptedEvent = {}
local MixerWagonBaleNotAcceptedEvent_mt = Class(MixerWagonBaleNotAcceptedEvent, Event)

InitStaticEventClass(MixerWagonBaleNotAcceptedEvent, "MixerWagonBaleNotAcceptedEvent", EventIds.EVENT_MIXERWAGON_BALE_NOT_ACCEPTED)

function MixerWagonBaleNotAcceptedEvent.emptyNew()
	local self = Event.new(MixerWagonBaleNotAcceptedEvent_mt)

	return self
end

function MixerWagonBaleNotAcceptedEvent.new()
	local self = MixerWagonBaleNotAcceptedEvent.emptyNew()

	return self
end

function MixerWagonBaleNotAcceptedEvent:readStream(streamId, connection)
	self:run(connection)
end

function MixerWagonBaleNotAcceptedEvent:writeStream(streamId, connection)
end

function MixerWagonBaleNotAcceptedEvent:run(connection)
	g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("warning_baleNotSupported"))
end
