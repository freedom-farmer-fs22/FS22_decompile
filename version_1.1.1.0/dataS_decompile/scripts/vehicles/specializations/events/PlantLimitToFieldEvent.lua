PlantLimitToFieldEvent = {}
local PlantLimitToFieldEvent_mt = Class(PlantLimitToFieldEvent, Event)

InitStaticEventClass(PlantLimitToFieldEvent, "PlantLimitToFieldEvent", EventIds.EVENT_PLANT_LIMIT_TO_FIELD)

function PlantLimitToFieldEvent.emptyNew()
	local self = Event.new(PlantLimitToFieldEvent_mt)

	return self
end

function PlantLimitToFieldEvent.new(object, plantLimitToField)
	local self = PlantLimitToFieldEvent.emptyNew()
	self.object = object
	self.plantLimitToField = plantLimitToField

	return self
end

function PlantLimitToFieldEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.plantLimitToField = streamReadBool(streamId)

	self:run(connection)
end

function PlantLimitToFieldEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.plantLimitToField)
end

function PlantLimitToFieldEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setPlantLimitToField(self.plantLimitToField, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(PlantLimitToFieldEvent.new(self.object, self.plantLimitToField), nil, connection, self.object)
	end
end

function PlantLimitToFieldEvent.sendEvent(vehicle, plantLimitToField, noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlantLimitToFieldEvent.new(vehicle, plantLimitToField), nil, , vehicle)
		else
			g_client:getServerConnection():sendEvent(PlantLimitToFieldEvent.new(vehicle, plantLimitToField))
		end
	end
end
