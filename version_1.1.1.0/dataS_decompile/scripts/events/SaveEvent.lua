SaveEvent = {}
local SaveEvent_mt = Class(SaveEvent, Event)

InitStaticEventClass(SaveEvent, "SaveEvent", EventIds.EVENT_SAVE)

function SaveEvent.emptyNew()
	local self = Event.new(SaveEvent_mt)

	return self
end

function SaveEvent.new()
	local self = SaveEvent.emptyNew()

	return self
end

function SaveEvent:readStream(streamId, connection)
	assert(g_currentMission:getIsServer())

	if g_currentMission:getIsServer() and not connection:getIsServer() and g_currentMission.userManager:getIsConnectionMasterUser(connection) then
		g_messageCenter:publish(SaveEvent, false, true)
	end
end

function SaveEvent:writeStream(streamId, connection)
end

function SaveEvent:run(connection)
	print("Error: SaveEvent is a client to server only event")
end
