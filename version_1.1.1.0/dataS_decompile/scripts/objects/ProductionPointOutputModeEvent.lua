ProductionPointOutputModeEvent = {}
local ProductionPointOutputModeEvent_mt = Class(ProductionPointOutputModeEvent, Event)

InitStaticEventClass(ProductionPointOutputModeEvent, "ProductionPointOutputModeEvent", EventIds.EVENT_PRODUCTION_CHANGED_OUTPUT_MODE)

function ProductionPointOutputModeEvent.emptyNew()
	local self = Event.new(ProductionPointOutputModeEvent_mt)

	return self
end

function ProductionPointOutputModeEvent.new(productionPoint, outputFillTypeId, outputMode)
	local self = ProductionPointOutputModeEvent.emptyNew()
	self.productionPoint = productionPoint
	self.outputFillTypeId = outputFillTypeId
	self.outputMode = outputMode

	return self
end

function ProductionPointOutputModeEvent:readStream(streamId, connection)
	self.productionPoint = NetworkUtil.readNodeObject(streamId)
	self.outputFillTypeId = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
	self.outputMode = streamReadUIntN(streamId, ProductionPoint.OUTPUT_MODE_NUM_BITS)

	self:run(connection)
end

function ProductionPointOutputModeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.productionPoint)
	streamWriteUIntN(streamId, self.outputFillTypeId, FillTypeManager.SEND_NUM_BITS)
	streamWriteUIntN(streamId, self.outputMode, ProductionPoint.OUTPUT_MODE_NUM_BITS)
end

function ProductionPointOutputModeEvent:run(connection)
	if not connection:getIsServer() then
		g_server:broadcastEvent(self, false, connection)
	end

	if self.productionPoint ~= nil then
		self.productionPoint:setOutputDistributionMode(self.outputFillTypeId, self.outputMode, true)
	end
end

function ProductionPointOutputModeEvent.sendEvent(productionPoint, outputFillTypeId, outputMode, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(ProductionPointOutputModeEvent.new(productionPoint, outputFillTypeId, outputMode))
		else
			g_client:getServerConnection():sendEvent(ProductionPointOutputModeEvent.new(productionPoint, outputFillTypeId, outputMode))
		end
	end
end
