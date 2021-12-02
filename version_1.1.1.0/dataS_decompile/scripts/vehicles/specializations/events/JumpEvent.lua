JumpEvent = {}
local JumpEvent_mt = Class(JumpEvent, Event)

InitStaticEventClass(JumpEvent, "JumpEvent", EventIds.EVENT_JUMP)

function JumpEvent.emptyNew()
	local self = Event.new(JumpEvent_mt)

	return self
end

function JumpEvent.new(object)
	local self = JumpEvent.emptyNew()
	self.object = object

	return self
end

function JumpEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.object = NetworkUtil.readNodeObject(streamId)

		self:run(connection)
	end
end

function JumpEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.object)
	end
end

function JumpEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:jump(true)
	end
end
