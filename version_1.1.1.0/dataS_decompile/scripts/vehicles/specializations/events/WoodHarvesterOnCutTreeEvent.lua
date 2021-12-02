WoodHarvesterOnCutTreeEvent = {}
local WoodHarvesterOnCutTreeEvent_mt = Class(WoodHarvesterOnCutTreeEvent, Event)

InitStaticEventClass(WoodHarvesterOnCutTreeEvent, "WoodHarvesterOnCutTreeEvent", EventIds.EVENT_WOODHARVESTER_ON_CUT_TREE)

function WoodHarvesterOnCutTreeEvent.emptyNew()
	local self = Event.new(WoodHarvesterOnCutTreeEvent_mt)

	return self
end

function WoodHarvesterOnCutTreeEvent.new(object, radius)
	local self = WoodHarvesterOnCutTreeEvent.emptyNew()
	self.object = object
	self.radius = radius

	return self
end

function WoodHarvesterOnCutTreeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.radius = streamReadFloat32(streamId)

	self:run(connection)
end

function WoodHarvesterOnCutTreeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteFloat32(streamId, self.radius)
end

function WoodHarvesterOnCutTreeEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(WoodHarvesterOnCutTreeEvent.new(self.object, self.radius), nil, connection, self.object)
	end

	if self.object ~= nil and self.object:getIsSynchronized() then
		SpecializationUtil.raiseEvent(self.object, "onCutTree", self.radius)
	end
end
