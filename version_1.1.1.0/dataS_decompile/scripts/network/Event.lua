Event = {}
local Event_mt = Class(Event)

function Event.new(customMt, channel)
	local self = setmetatable({}, customMt or Event_mt)
	self.networkChannel = channel
	self.queueCount = 0

	return self
end

function Event:delete()
end

function Event:readStream(streamId, connection)
end

function Event:writeStream(streamId, connection)
end
