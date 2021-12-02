TrailerToggleManualTipEvent = {}
local TrailerToggleManualTipEvent_mt = Class(TrailerToggleManualTipEvent, Event)

InitStaticEventClass(TrailerToggleManualTipEvent, "TrailerToggleManualTipEvent", EventIds.EVENT_TRAILER_TOGGLE_MANUAL_TIP)

function TrailerToggleManualTipEvent.emptyNew()
	local self = Event.new(TrailerToggleManualTipEvent_mt)

	return self
end

function TrailerToggleManualTipEvent.new(object, state)
	local self = TrailerToggleManualTipEvent.emptyNew()
	self.object = object
	self.state = state

	return self
end

function TrailerToggleManualTipEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)

	self:run(connection)
end

function TrailerToggleManualTipEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.state)
end

function TrailerToggleManualTipEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	if self.object ~= nil and self.object:getIsSynchronized() then
		if self.state then
			self.object:startTipping(nil, true)
		else
			self.object:stopTipping(true)
		end
	end
end

function TrailerToggleManualTipEvent.sendEvent(vehicle, state, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(TrailerToggleManualTipEvent.new(vehicle, state), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(TrailerToggleManualTipEvent.new(vehicle, state))
		end
	end
end
