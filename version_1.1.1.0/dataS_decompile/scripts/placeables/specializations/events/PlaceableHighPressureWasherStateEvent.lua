PlaceableHighPressureWasherStateEvent = {}
local PlaceableHighPressureWasherStateEvent_mt = Class(PlaceableHighPressureWasherStateEvent, Event)

InitStaticEventClass(PlaceableHighPressureWasherStateEvent, "PlaceableHighPressureWasherStateEvent", EventIds.EVENT_HIGHPRESSURE_WASHER_TURN_ON)

function PlaceableHighPressureWasherStateEvent.emptyNew()
	local self = Event.new(PlaceableHighPressureWasherStateEvent_mt)

	return self
end

function PlaceableHighPressureWasherStateEvent.new(placeable, isTurnedOn, player)
	local self = PlaceableHighPressureWasherStateEvent.emptyNew()
	self.placeable = placeable
	self.isTurnedOn = isTurnedOn
	self.player = player

	return self
end

function PlaceableHighPressureWasherStateEvent:readStream(streamId, connection)
	self.placeable = NetworkUtil.readNodeObject(streamId)
	self.isTurnedOn = streamReadBool(streamId)

	if self.isTurnedOn then
		self.player = NetworkUtil.readNodeObject(streamId)
	end

	self:run(connection)
end

function PlaceableHighPressureWasherStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.placeable)
	streamWriteBool(streamId, self.isTurnedOn)

	if self.isTurnedOn then
		NetworkUtil.writeNodeObject(streamId, self.player)
	end
end

function PlaceableHighPressureWasherStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.placeable)
	end

	if self.placeable ~= nil and self.placeable:getIsSynchronized() then
		self.placeable:setIsHighPressureWasherTurnedOn(self.isTurnedOn, self.player, true)
	end
end
