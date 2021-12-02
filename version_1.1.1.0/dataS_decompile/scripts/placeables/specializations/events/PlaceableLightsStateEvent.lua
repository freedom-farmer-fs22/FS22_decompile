PlaceableLightsStateEvent = {}
local PlaceableLightsStateEvent_mt = Class(PlaceableLightsStateEvent, Event)

InitStaticEventClass(PlaceableLightsStateEvent, "PlaceableLightsStateEvent", EventIds.EVENT_PLACEABLE_LIGHTS_STATE)

function PlaceableLightsStateEvent.emptyNew()
	return Event.new(PlaceableLightsStateEvent_mt)
end

function PlaceableLightsStateEvent.new(placeable, groupIndex, isActive)
	local self = PlaceableLightsStateEvent.emptyNew()
	self.placeable = placeable
	self.groupIndex = groupIndex
	self.isActive = isActive

	return self
end

function PlaceableLightsStateEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	self.groupIndex = streamReadUIntN(streamId, PlaceableLights.MAX_NUM_BITS)
	self.isActive = streamReadBool(streamId)

	self:run(connection)
end

function PlaceableLightsStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
	streamWriteUIntN(streamId, self.groupIndex, PlaceableLights.MAX_NUM_BITS)
	streamWriteBool(streamId, self.isActive)
end

function PlaceableLightsStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.placeable)
	end

	if self.placeable ~= nil and self.placeable:getIsSynchronized() and self.placeable.setGroupIsActive ~= nil then
		self.placeable:setGroupIsActive(self.groupIndex, self.isActive, true)
	end
end

function PlaceableLightsStateEvent.sendEvent(placeable, groupIndex, isActive, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlaceableLightsStateEvent.new(placeable, groupIndex, isActive), nil, , placeable)
		else
			g_client:getServerConnection():sendEvent(PlaceableLightsStateEvent.new(placeable, groupIndex, isActive))
		end
	end
end
