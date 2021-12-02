AIConveyorBeltSetAngleEvent = {}
local AIConveyorBeltSetAngleEvent_mt = Class(AIConveyorBeltSetAngleEvent, Event)

InitStaticEventClass(AIConveyorBeltSetAngleEvent, "AIConveyorBeltSetAngleEvent", EventIds.EVENT_AIVEHICLE_SET_CONVEYORBELT_ANGLE)

function AIConveyorBeltSetAngleEvent.emptyNew()
	local self = Event.new(AIConveyorBeltSetAngleEvent_mt)

	return self
end

function AIConveyorBeltSetAngleEvent.new(vehicle, currentAngle)
	local self = AIConveyorBeltSetAngleEvent.emptyNew()
	self.currentAngle = currentAngle
	self.vehicle = vehicle

	return self
end

function AIConveyorBeltSetAngleEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.currentAngle = streamReadInt8(streamId)

	self:run(connection)
end

function AIConveyorBeltSetAngleEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteInt8(streamId, self.currentAngle)
end

function AIConveyorBeltSetAngleEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:setAIConveyorBeltAngle(self.currentAngle, true)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(AIConveyorBeltSetAngleEvent.new(self.vehicle, self.currentAngle), nil, connection, self.vehicle)
	end
end
