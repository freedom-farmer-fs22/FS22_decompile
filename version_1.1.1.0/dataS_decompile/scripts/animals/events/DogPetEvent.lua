DogPetEvent = {}
local DogPetEvent_mt = Class(DogPetEvent, Event)

InitStaticEventClass(DogPetEvent, "DogPetEvent", EventIds.EVENT_DOG_PET)

function DogPetEvent.emptyNew()
	local self = Event.new(DogPetEvent_mt)

	return self
end

function DogPetEvent.new(dog)
	local self = DogPetEvent.emptyNew()
	self.dog = dog

	return self
end

function DogPetEvent:readStream(streamId, connection)
	self.dog = NetworkUtil.readNodeObject(streamId)

	self:run(connection)
end

function DogPetEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.dog)
end

function DogPetEvent:run(connection)
	if self.dog ~= nil then
		self.dog:pet()
	end
end
