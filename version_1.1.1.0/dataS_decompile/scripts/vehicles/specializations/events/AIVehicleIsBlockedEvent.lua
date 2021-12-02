AIVehicleIsBlockedEvent = {}
local AIVehicleIsBlockedEvent_mt = Class(AIVehicleIsBlockedEvent, Event)

InitStaticEventClass(AIVehicleIsBlockedEvent, "AIVehicleIsBlockedEvent", EventIds.EVENT_AIVEHICLE_IS_BLOCKED)

function AIVehicleIsBlockedEvent.emptyNew()
	local self = Event.new(AIVehicleIsBlockedEvent_mt)

	return self
end

function AIVehicleIsBlockedEvent.new(object, isBlocked)
	local self = AIVehicleIsBlockedEvent.emptyNew()
	self.object = object
	self.isBlocked = isBlocked

	return self
end

function AIVehicleIsBlockedEvent:readStream(streamId, connection)
	self.object = NetworkUtil.readNodeObject(streamId)
	self.isBlocked = streamReadBool(streamId)

	self:run(connection)
end

function AIVehicleIsBlockedEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.object)
	streamWriteBool(streamId, self.isBlocked)
end

function AIVehicleIsBlockedEvent:run(connection)
	if self.object ~= nil and self.object:getIsSynchronized() then
		if self.isBlocked then
			self.object:aiBlock()
		else
			self.object:aiContinue()
		end
	end
end
