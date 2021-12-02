FoldableSetFoldDirectionEvent = {}
local FoldableSetFoldDirectionEvent_mt = Class(FoldableSetFoldDirectionEvent, Event)

InitStaticEventClass(FoldableSetFoldDirectionEvent, "FoldableSetFoldDirectionEvent", EventIds.EVENT_FOLDABLE_SET_FOLD_DIRECTION)

function FoldableSetFoldDirectionEvent.emptyNew()
	local self = Event.new(FoldableSetFoldDirectionEvent_mt)

	return self
end

function FoldableSetFoldDirectionEvent.new(object, direction, moveToMiddle)
	local self = FoldableSetFoldDirectionEvent.emptyNew()
	self.object = object
	self.direction = MathUtil.sign(direction)
	self.moveToMiddle = moveToMiddle

	return self
end

function FoldableSetFoldDirectionEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.direction = streamReadUIntN(streamId, 2) - 1
	self.moveToMiddle = streamReadBool(streamId)

	self:run(connection)
end

function FoldableSetFoldDirectionEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteUIntN(streamId, self.direction + 1, 2)
	streamWriteBool(streamId, self.moveToMiddle)
end

function FoldableSetFoldDirectionEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setFoldState(self.direction, self.moveToMiddle, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(FoldableSetFoldDirectionEvent.new(self.object, self.direction, self.moveToMiddle), nil, connection, self.object)
	end
end
