SprayerDoubledAmountEvent = {}
local SprayerDoubledAmountEvent_mt = Class(SprayerDoubledAmountEvent, Event)

InitStaticEventClass(SprayerDoubledAmountEvent, "SprayerDoubledAmountEvent", EventIds.EVENT_SPRAYER_DOUBLED_AMOUNT)

function SprayerDoubledAmountEvent.emptyNew()
	local self = Event.new(SprayerDoubledAmountEvent_mt)

	return self
end

function SprayerDoubledAmountEvent.new(object, isActive)
	local self = SprayerDoubledAmountEvent.emptyNew()
	self.object = object
	self.isActive = isActive

	return self
end

function SprayerDoubledAmountEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.isActive = streamReadBool(streamId)

	self:run(connection)
end

function SprayerDoubledAmountEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.isActive)
end

function SprayerDoubledAmountEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setSprayerDoubledAmountActive(self.isActive, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(SprayerDoubledAmountEvent.new(self.object, self.isActive), nil, connection, self.object)
	end
end

function SprayerDoubledAmountEvent.sendEvent(vehicle, isActive, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SprayerDoubledAmountEvent.new(vehicle, isActive), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(SprayerDoubledAmountEvent.new(vehicle, isActive))
		end
	end
end
