PlowLimitToFieldEvent = {}
local PlowLimitToFieldEvent_mt = Class(PlowLimitToFieldEvent, Event)

InitStaticEventClass(PlowLimitToFieldEvent, "PlowLimitToFieldEvent", EventIds.EVENT_PLOW_LIMIT_TO_FIELD)

function PlowLimitToFieldEvent.emptyNew()
	local self = Event.new(PlowLimitToFieldEvent_mt)

	return self
end

function PlowLimitToFieldEvent.new(object, plowLimitToField)
	local self = PlowLimitToFieldEvent.emptyNew()
	self.object = object
	self.plowLimitToField = plowLimitToField

	return self
end

function PlowLimitToFieldEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.plowLimitToField = streamReadBool(streamId)

	self:run(connection)
end

function PlowLimitToFieldEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.plowLimitToField)
end

function PlowLimitToFieldEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setPlowLimitToField(self.plowLimitToField, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(PlowLimitToFieldEvent.new(self.object, self.plowLimitToField), nil, connection, self.object)
	end
end
