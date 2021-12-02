ProductionPointProductionStateEvent = {}
local ProductionPointProductionStateEvent_mt = Class(ProductionPointProductionStateEvent, Event)

InitStaticEventClass(ProductionPointProductionStateEvent, "ProductionPointProductionStateEvent", EventIds.EVENT_PRODUCTION_CHANGED_STATE)

function ProductionPointProductionStateEvent.emptyNew()
	local self = Event.new(ProductionPointProductionStateEvent_mt)

	return self
end

function ProductionPointProductionStateEvent.new(productionPoint, productionId, isEnabled)
	local self = ProductionPointProductionStateEvent.emptyNew()
	self.productionPoint = productionPoint
	self.productionId = productionId
	self.isEnabled = isEnabled

	return self
end

function ProductionPointProductionStateEvent:readStream(streamId, connection)
	self.productionPoint = NetworkUtil.readNodeObject(streamId)
	self.productionId = streamReadString(streamId)
	self.isEnabled = streamReadBool(streamId)

	self:run(connection)
end

function ProductionPointProductionStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.productionPoint)
	streamWriteString(streamId, self.productionId)
	streamWriteBool(streamId, self.isEnabled)
end

function ProductionPointProductionStateEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection)
	end

	if self.productionPoint ~= nil then
		self.productionPoint:setProductionState(self.productionId, self.isEnabled, true)
	end
end

function ProductionPointProductionStateEvent.sendEvent(productionPoint, productionId, isEnabled, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(ProductionPointProductionStateEvent.new(productionPoint, productionId, isEnabled))
		else
			g_client:getServerConnection():sendEvent(ProductionPointProductionStateEvent.new(productionPoint, productionId, isEnabled))
		end
	end
end
