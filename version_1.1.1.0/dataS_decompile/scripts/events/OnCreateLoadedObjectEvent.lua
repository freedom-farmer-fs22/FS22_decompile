OnCreateLoadedObjectEvent = {}
local OnCreateLoadedObjectEvent_mt = Class(OnCreateLoadedObjectEvent, Event)

InitStaticEventClass(OnCreateLoadedObjectEvent, "OnCreateLoadedObjectEvent", EventIds.EVENT_ON_CREATE_LOADED_OBJECT)

function OnCreateLoadedObjectEvent.emptyNew()
	local self = Event.new(OnCreateLoadedObjectEvent_mt)

	return self
end

function OnCreateLoadedObjectEvent.new()
	local self = OnCreateLoadedObjectEvent.emptyNew()

	return self
end

function OnCreateLoadedObjectEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		local numObjects = streamReadUInt16(streamId)

		assert(numObjects == g_currentMission:getNumOnCreateLoadedObjects())

		for i = 1, numObjects do
			local serverId = NetworkUtil.readNodeObjectId(streamId)
			local object = g_currentMission:getOnCreateLoadedObject(i)

			object:readStream(streamId, connection)
			g_client:finishRegisterObject(object, serverId)
		end

		connection:sendEvent(OnCreateLoadedObjectEvent.new())
	else
		local numObjects = g_currentMission:getNumOnCreateLoadedObjects()

		for i = 1, numObjects do
			local object = g_currentMission:getOnCreateLoadedObject(i)

			g_server:finishRegisterObject(connection, object)
		end
	end
end

function OnCreateLoadedObjectEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		local numObjects = g_currentMission:getNumOnCreateLoadedObjects()

		streamWriteUInt16(streamId, numObjects)

		for i = 1, numObjects do
			local object = g_currentMission:getOnCreateLoadedObject(i)

			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(object))
			object:writeStream(streamId, connection)
		end
	end
end

function OnCreateLoadedObjectEvent:run(connection)
end
