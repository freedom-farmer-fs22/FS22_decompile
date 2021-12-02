ProductionPointProductionStatusEvent = {}
local ProductionPointProductionStatusEvent_mt = Class(ProductionPointProductionStatusEvent, Event)

InitStaticEventClass(ProductionPointProductionStatusEvent, "ProductionPointProductionStatusEvent", EventIds.EVENT_PRODUCTION_CHANGED_STATUS)

function ProductionPointProductionStatusEvent.emptyNew()
	local self = Event.new(ProductionPointProductionStatusEvent_mt)

	return self
end

function ProductionPointProductionStatusEvent.new(productionPoint, productionId, status)
	local self = ProductionPointProductionStatusEvent.emptyNew()
	self.productionPoint = productionPoint
	self.productionId = productionId
	self.status = status

	return self
end

function ProductionPointProductionStatusEvent:readStream(streamId, connection)
	self.productionPoint = NetworkUtil.readNodeObject(streamId)
	self.productionId = streamReadString(streamId)
	self.status = streamReadUIntN(streamId, ProductionPoint.PROD_STATUS_NUM_BITS)

	self:run(connection)
end

function ProductionPointProductionStatusEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.productionPoint)
	streamWriteString(streamId, self.productionId)
	streamWriteUIntN(streamId, self.status, ProductionPoint.PROD_STATUS_NUM_BITS)
end

function ProductionPointProductionStatusEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection)
	end

	if self.productionPoint ~= nil then
		self.productionPoint:setProductionStatus(self.productionId, self.status, true)
	end
end

function ProductionPointProductionStatusEvent.sendEvent(productionPoint, productionId, status, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(ProductionPointProductionStatusEvent.new(productionPoint, productionId, status))
		else
			g_client:getServerConnection():sendEvent(ProductionPointProductionStatusEvent.new(productionPoint, productionId, status))
		end
	end
end
