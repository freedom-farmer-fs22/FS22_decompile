WoodHarvesterOnDelimbTreeEvent = {}
local WoodHarvesterOnDelimbTreeEvent_mt = Class(WoodHarvesterOnDelimbTreeEvent, Event)

InitStaticEventClass(WoodHarvesterOnDelimbTreeEvent, "WoodHarvesterOnDelimbTreeEvent", EventIds.EVENT_WOODHARVESTER_ON_DELIMB_TREE)

function WoodHarvesterOnDelimbTreeEvent.emptyNew()
	return Event.new(WoodHarvesterOnDelimbTreeEvent_mt)
end

function WoodHarvesterOnDelimbTreeEvent.new(object, state)
	local self = WoodHarvesterOnDelimbTreeEvent.emptyNew()
	self.object = object
	self.state = state

	return self
end

function WoodHarvesterOnDelimbTreeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.state = streamReadBool(streamId)

	self:run(connection)
end

function WoodHarvesterOnDelimbTreeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.state)
end

function WoodHarvesterOnDelimbTreeEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(WoodHarvesterOnDelimbTreeEvent.new(self.object, self.state), nil, connection, self.object)
	end

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:onDelimbTree(self.state)
	end
end
