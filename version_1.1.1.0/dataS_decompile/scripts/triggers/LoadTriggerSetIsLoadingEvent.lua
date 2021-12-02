LoadTriggerSetIsLoadingEvent = {}
local loadTriggerSetIsLoadingEvent_mt = Class(LoadTriggerSetIsLoadingEvent, Event)

InitStaticEventClass(LoadTriggerSetIsLoadingEvent, "LoadTriggerSetIsLoadingEvent", EventIds.EVENT_LOADTRIGGER_SET_IS_LOADING)

function LoadTriggerSetIsLoadingEvent.emptyNew()
	local self = Event.new(loadTriggerSetIsLoadingEvent_mt)

	return self
end

function LoadTriggerSetIsLoadingEvent.new(object, isLoading, targetObject, fillUnitIndex, fillType)
	local self = LoadTriggerSetIsLoadingEvent.emptyNew()
	self.object = object
	self.isLoading = isLoading
	self.targetObject = targetObject
	self.fillUnitIndex = fillUnitIndex
	self.fillType = fillType

	return self
end

function LoadTriggerSetIsLoadingEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.isLoading = streamReadBool(streamId)

	if self.isLoading then
		self.targetObject = NetworkUtil.readNodeObject(streamId)
		self.fillUnitIndex = streamReadUInt8(streamId)
		self.fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
	end

	self:run(connection)
end

function LoadTriggerSetIsLoadingEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)

	if streamWriteBool(streamId, self.isLoading) then
		NetworkUtil.writeNodeObject(streamId, self.targetObject)
		streamWriteUInt8(streamId, self.fillUnitIndex)
		streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)
	end
end

function LoadTriggerSetIsLoadingEvent:run(connection)
	self.object:setIsLoading(self.isLoading, self.targetObject, self.fillUnitIndex, self.fillType, true)

	if not connection:getIsServer() then
		g_server:broadcastEvent(LoadTriggerSetIsLoadingEvent.new(self.object, self.isLoading, self.targetObject, self.fillUnitIndex, self.fillType), nil, connection, self.object)
	end
end

function LoadTriggerSetIsLoadingEvent.sendEvent(object, isLoading, targetObject, fillUnitIndex, fillType, noEventSend)
	if isLoading ~= object.isLoading and (noEventSend == nil or noEventSend == false) then
		if g_server ~= nil then
			g_server:broadcastEvent(LoadTriggerSetIsLoadingEvent.new(object, isLoading, targetObject, fillUnitIndex, fillType), nil, , object)
		else
			g_client:getServerConnection():sendEvent(LoadTriggerSetIsLoadingEvent.new(object, isLoading, targetObject, fillUnitIndex, fillType))
		end
	end
end
