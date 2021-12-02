PlowPackerStateEvent = {}
local PlowPackerStateEvent_mt = Class(PlowPackerStateEvent, Event)

InitStaticEventClass(PlowPackerStateEvent, "PlowPackerStateEvent", EventIds.EVENT_PLOW_PACKER_STATE)

function PlowPackerStateEvent.emptyNew()
	return Event.new(PlowPackerStateEvent_mt)
end

function PlowPackerStateEvent.new(object, state, updateAnimations)
	local self = PlowPackerStateEvent.emptyNew()
	self.object = object
	self.state = state
	self.updateAnimations = updateAnimations

	return self
end

function PlowPackerStateEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)
	self.updateAnimations = streamReadBool(streamId)

	self:run(connection)
end

function PlowPackerStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.state)
	streamWriteBool(streamId, self.updateAnimations)
end

function PlowPackerStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection, self.object)
	end

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setPackerState(self.state, self.updateAnimations, true)
	end
end

function PlowPackerStateEvent.sendEvent(object, state, updateAnimations, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlowPackerStateEvent.new(object, state, updateAnimations), nil, , object)
		else
			g_client:getServerConnection():sendEvent(PlowPackerStateEvent.new(object, state, updateAnimations))
		end
	end
end
