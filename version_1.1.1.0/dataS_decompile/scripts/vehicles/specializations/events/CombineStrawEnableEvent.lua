CombineStrawEnableEvent = {}
local CombineStrawEnableEvent_mt = Class(CombineStrawEnableEvent, Event)

InitStaticEventClass(CombineStrawEnableEvent, "CombineStrawEnableEvent", EventIds.EVENT_COMBINE_ENABLE_STRAW)

function CombineStrawEnableEvent.emptyNew()
	local self = Event.new(CombineStrawEnableEvent_mt)

	return self
end

function CombineStrawEnableEvent.new(vehicle, isSwathActive)
	local self = CombineStrawEnableEvent.emptyNew()
	self.vehicle = vehicle
	self.isSwathActive = isSwathActive

	return self
end

function CombineStrawEnableEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.isSwathActive = streamReadBool(streamId)

	self:run(connection)
end

function CombineStrawEnableEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteBool(streamId, self.isSwathActive)
end

function CombineStrawEnableEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setIsSwathActive(self.isSwathActive, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(CombineStrawEnableEvent.new(self.vehicle, self.isSwathActive), nil, connection, self.vehicle)
	end
end

function CombineStrawEnableEvent.sendEvent(vehicle, isSwathActive, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(CombineStrawEnableEvent.new(vehicle, isSwathActive), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(CombineStrawEnableEvent.new(vehicle, isSwathActive))
		end
	end
end
