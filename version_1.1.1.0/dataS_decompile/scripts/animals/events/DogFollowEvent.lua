DogFollowEvent = {}
local DogFollowEvent_mt = Class(DogFollowEvent, Event)

InitStaticEventClass(DogFollowEvent, "DogFollowEvent", EventIds.EVENT_DOG_FOLLOW)

function DogFollowEvent.emptyNew()
	local self = Event.new(DogFollowEvent_mt)

	return self
end

function DogFollowEvent.new(dog, player)
	local self = DogFollowEvent.emptyNew()
	self.dog = dog
	self.player = player
	self.follow = player ~= nil

	return self
end

function DogFollowEvent:readStream(streamId, connection)
	self.dog = NetworkUtil.readNodeObject(streamId)
	self.follow = streamReadBool(streamId)

	if self.follow then
		self.player = NetworkUtil.readNodeObject(streamId)
	end

	self:run(connection)
end

function DogFollowEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.dog)

	if streamWriteBool(streamId, self.follow) then
		NetworkUtil.writeNodeObject(streamId, self.player)
	end
end

function DogFollowEvent:run(connection)
	if self.dog ~= nil then
		if self.follow then
			if self.player ~= nil then
				self.dog:followEntity(self.player)
			end
		else
			self.dog:goToSpawn()
		end
	end
end
