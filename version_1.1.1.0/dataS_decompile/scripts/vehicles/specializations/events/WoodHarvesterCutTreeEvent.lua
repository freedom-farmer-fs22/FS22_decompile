WoodHarvesterCutTreeEvent = {}
local WoodHarvesterCutTreeEvent_mt = Class(WoodHarvesterCutTreeEvent, Event)

InitStaticEventClass(WoodHarvesterCutTreeEvent, "WoodHarvesterCutTreeEvent", EventIds.EVENT_WOODHARVESTER_CUT_TREE)

function WoodHarvesterCutTreeEvent.emptyNew()
	local self = Event.new(WoodHarvesterCutTreeEvent_mt)

	return self
end

function WoodHarvesterCutTreeEvent.new(object, length)
	local self = WoodHarvesterCutTreeEvent.emptyNew()
	self.object = object
	self.length = length

	return self
end

function WoodHarvesterCutTreeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.length = streamReadFloat32(streamId)

	self:run(connection)
end

function WoodHarvesterCutTreeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteFloat32(streamId, self.length)
end

function WoodHarvesterCutTreeEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(WoodHarvesterCutTreeEvent.new(self.object, self.length), nil, connection, self.object)
	end

	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:cutTree(self.length, true)
	end
end

function WoodHarvesterCutTreeEvent.sendEvent(object, length, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(WoodHarvesterCutTreeEvent.new(object, length), nil, , object)
		else
			g_client:getServerConnection():sendEvent(WoodHarvesterCutTreeEvent.new(object, length))
		end
	end
end
