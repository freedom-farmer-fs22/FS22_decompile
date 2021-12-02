WaterTrailerSetIsFillingEvent = {}
local WaterTrailerSetIsFillingEvent_mt = Class(WaterTrailerSetIsFillingEvent, Event)

InitStaticEventClass(WaterTrailerSetIsFillingEvent, "WaterTrailerSetIsFillingEvent", EventIds.EVENT_WATER_TRAILER_SET_IS_FILLING)

function WaterTrailerSetIsFillingEvent.emptyNew()
	local self = Event.new(WaterTrailerSetIsFillingEvent_mt)

	return self
end

function WaterTrailerSetIsFillingEvent.new(vehicle, isFilling)
	local self = WaterTrailerSetIsFillingEvent.emptyNew()
	self.vehicle = vehicle
	self.isFilling = isFilling

	return self
end

function WaterTrailerSetIsFillingEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.isFilling = streamReadBool(streamId)

	self:run(connection)
end

function WaterTrailerSetIsFillingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.isFilling)
end

function WaterTrailerSetIsFillingEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.vehicle)
	end

	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setIsWaterTrailerFilling(self.isFilling, true)
	end
end

function WaterTrailerSetIsFillingEvent.sendEvent(vehicle, isFilling, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(WaterTrailerSetIsFillingEvent.new(vehicle, isFilling), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(WaterTrailerSetIsFillingEvent.new(vehicle, isFilling))
		end
	end
end
