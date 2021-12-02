BaleWrapperStateEvent = {}
local BaleWrapperStateEvent_mt = Class(BaleWrapperStateEvent, Event)

InitStaticEventClass(BaleWrapperStateEvent, "BaleWrapperStateEvent", EventIds.EVENT_BALE_WRAPPER_STATE)

function BaleWrapperStateEvent.emptyNew()
	local self = Event.new(BaleWrapperStateEvent_mt)

	return self
end

function BaleWrapperStateEvent.new(object, stateId, nearestBaleServerId)
	local self = BaleWrapperStateEvent.emptyNew()
	self.object = object
	self.stateId = stateId

	assert(nearestBaleServerId ~= nil or self.stateId ~= BaleWrapper.CHANGE_GRAB_BALE)

	self.nearestBaleServerId = nearestBaleServerId

	return self
end

function BaleWrapperStateEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.stateId = streamReadInt8(streamId)

	if self.stateId == BaleWrapper.CHANGE_GRAB_BALE then
		self.nearestBaleServerId = NetworkUtil.readNodeObjectId(streamId)
	end

	self:run(connection)
end

function BaleWrapperStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteInt8(streamId, self.stateId)

	if self.stateId == BaleWrapper.CHANGE_GRAB_BALE then
		NetworkUtil.writeNodeObjectId(streamId, self.nearestBaleServerId)
	end
end

function BaleWrapperStateEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:doStateChange(self.stateId, self.nearestBaleServerId)
	end
end
