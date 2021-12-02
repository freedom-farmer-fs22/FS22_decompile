UpdateSplitShapesEvent = {}
local UpdateSplitShapesEvent_mt = Class(UpdateSplitShapesEvent, Event)

InitStaticEventClass(UpdateSplitShapesEvent, "UpdateSplitShapesEvent", EventIds.EVENT_UPDATE_SPLIT_SHAPES)

function UpdateSplitShapesEvent.emptyNew()
	local self = Event.new(UpdateSplitShapesEvent_mt)

	return self
end

function UpdateSplitShapesEvent.new()
	local self = UpdateSplitShapesEvent.emptyNew()

	return self
end

function UpdateSplitShapesEvent:readStream(streamId, connection)
	if connection:getIsServer() then
		readSplitShapesServerEventFromStream(streamId)
	end
end

function UpdateSplitShapesEvent:writeStream(streamId, connection)
	if not connection:getIsServer() then
		writeSplitShapesServerEventToStream(streamId, streamId)
	end
end

function UpdateSplitShapesEvent:run(connection)
	print("Error: UpdateSplitShapesEvent is not allowed to be executed on a local client")
end
