TensionBeltsEvent = {}
local TensionBeltsEvent_mt = Class(TensionBeltsEvent, Event)

InitStaticEventClass(TensionBeltsEvent, "TensionBeltsEvent", EventIds.EVENT_TENSION_BELT)

function TensionBeltsEvent.emptyNew()
	local self = Event.new(TensionBeltsEvent_mt)

	return self
end

function TensionBeltsEvent.new(object, isActive, beltId)
	local self = TensionBeltsEvent.emptyNew()
	self.object = object
	self.isActive = isActive
	self.beltId = beltId

	return self
end

function TensionBeltsEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)

	if not streamReadBool(streamId) then
		self.beltId = streamReadUIntN(streamId, TensionBelts.NUM_SEND_BITS) + 1
	end

	self.isActive = streamReadBool(streamId)

	self:run(connection)
end

function TensionBeltsEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.beltId == nil)

	if self.beltId ~= nil then
		streamWriteUIntN(streamId, self.beltId - 1, TensionBelts.NUM_SEND_BITS)
	end

	streamWriteBool(streamId, self.isActive)
end

function TensionBeltsEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setTensionBeltsActive(self.isActive, self.beltId, true)
	end
end

function TensionBeltsEvent.sendEvent(vehicle, isActive, beltId, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(TensionBeltsEvent.new(vehicle, isActive, beltId), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(TensionBeltsEvent.new(vehicle, isActive, beltId))
		end
	end
end
