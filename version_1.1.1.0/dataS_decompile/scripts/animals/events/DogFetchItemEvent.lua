DogFetchItemEvent = {}
local DogFetchItemEvent_mt = Class(DogFetchItemEvent, Event)

InitStaticEventClass(DogFetchItemEvent, "DogFetchItemEvent", EventIds.EVENT_DOG_FETCH_ITEM)

function DogFetchItemEvent.emptyNew()
	local self = Event.new(DogFetchItemEvent_mt)

	return self
end

function DogFetchItemEvent.new(dog, player, item)
	local self = DogFetchItemEvent.emptyNew()
	self.dog = dog
	self.player = player
	self.item = item

	return self
end

function DogFetchItemEvent:readStream(streamId, connection)
	self.dog = NetworkUtil.readNodeObject(streamId)
	self.player = NetworkUtil.readNodeObject(streamId)
	self.item = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function DogFetchItemEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.dog)
	NetworkUtil.writeNodeObject(streamId, self.player)
	NetworkUtil.writeNodeObject(streamId, self.item)
end

function DogFetchItemEvent:run(connection)
	if self.dog ~= nil and self.player ~= nil and self.item ~= nil then
		self.dog:fetchItem(self.player, self.item)
	end
end
