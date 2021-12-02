BaleLoaderStateEvent = {}
local BaleLoaderStateEvent_mt = Class(BaleLoaderStateEvent, Event)

InitStaticEventClass(BaleLoaderStateEvent, "BaleLoaderStateEvent", EventIds.EVENT_BALE_LOADER_STATE)

function BaleLoaderStateEvent.emptyNew()
	local self = Event.new(BaleLoaderStateEvent_mt)

	return self
end

function BaleLoaderStateEvent.new(object, stateId, nearestBaleServerId)
	local self = BaleLoaderStateEvent.emptyNew()
	self.object = object
	self.stateId = stateId

	assert(nearestBaleServerId ~= nil or self.stateId ~= BaleLoader.CHANGE_GRAB_BALE)

	self.nearestBaleServerId = nearestBaleServerId

	return self
end

function BaleLoaderStateEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.stateId = streamReadInt8(streamId)

	if self.stateId == BaleLoader.CHANGE_GRAB_BALE then
		self.nearestBaleServerId = NetworkUtil.readNodeObjectId(streamId)
	end

	self:run(connection)
end

function BaleLoaderStateEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteInt8(streamId, self.stateId)

	if self.stateId == BaleLoader.CHANGE_GRAB_BALE then
		NetworkUtil.writeNodeObjectId(streamId, self.nearestBaleServerId)
	end
end

function BaleLoaderStateEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:doStateChange(self.stateId, self.nearestBaleServerId)
	end
end
