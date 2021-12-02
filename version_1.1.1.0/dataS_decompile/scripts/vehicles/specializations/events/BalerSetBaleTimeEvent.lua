BalerSetBaleTimeEvent = {}
local BalerSetBaleTimeEvent_mt = Class(BalerSetBaleTimeEvent, Event)

InitStaticEventClass(BalerSetBaleTimeEvent, "BalerSetBaleTimeEvent", EventIds.EVENT_BALER_SET_BALE_TIME)

function BalerSetBaleTimeEvent.emptyNew()
	local self = Event.new(BalerSetBaleTimeEvent_mt)

	return self
end

function BalerSetBaleTimeEvent.new(object, bale, baleTime)
	local self = BalerSetBaleTimeEvent.emptyNew()
	self.object = object
	self.bale = bale
	self.baleTime = baleTime

	return self
end

function BalerSetBaleTimeEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.bale = streamReadInt32(streamId)
	self.baleTime = streamReadFloat32(streamId)

	self:run(connection)
end

function BalerSetBaleTimeEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteInt32(streamId, self.bale)
	streamWriteFloat32(streamId, self.baleTime)
end

function BalerSetBaleTimeEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		self.object:setBaleTime(self.bale, self.baleTime)
	end
end
