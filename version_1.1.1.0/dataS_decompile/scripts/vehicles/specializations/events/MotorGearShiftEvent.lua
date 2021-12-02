MotorGearShiftEvent = {
	TYPE_SHIFT_UP = 1,
	TYPE_SHIFT_DOWN = 2,
	TYPE_SELECT_GEAR = 3,
	TYPE_SHIFT_GROUP_UP = 4,
	TYPE_SHIFT_GROUP_DOWN = 5,
	TYPE_SELECT_GROUP = 6,
	TYPE_DIRECTION_CHANGE = 7,
	TYPE_DIRECTION_CHANGE_POS = 8,
	TYPE_DIRECTION_CHANGE_NEG = 9
}
local MotorGearShiftEvent_mt = Class(MotorGearShiftEvent, Event)

InitStaticEventClass(MotorGearShiftEvent, "MotorGearShiftEvent", EventIds.EVENT_MOTOR_GEAR_SHIFT)

function MotorGearShiftEvent.emptyNew()
	local self = Event.new(MotorGearShiftEvent_mt)

	return self
end

function MotorGearShiftEvent.new(vehicle, shiftType, shiftValue)
	local self = MotorGearShiftEvent.emptyNew()
	self.vehicle = vehicle
	self.shiftType = shiftType
	self.shiftValue = shiftValue

	return self
end

function MotorGearShiftEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.shiftType = streamReadUIntN(streamId, 4)

	if self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR or self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
		self.shiftValue = streamReadUIntN(streamId, 3)
	end

	self:run(connection)
end

function MotorGearShiftEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	streamWriteUIntN(streamId, self.shiftType, 4)

	if self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR or self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
		streamWriteUIntN(streamId, self.shiftValue, 3)
	end
end

function MotorGearShiftEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		local spec = self.vehicle.spec_motorized

		if spec ~= nil and spec.isMotorStarted then
			if self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_UP then
				spec.motor:shiftGear(true)
			elseif self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_DOWN then
				spec.motor:shiftGear(false)
			elseif self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GEAR then
				spec.motor:selectGear(self.shiftValue, self.shiftValue ~= 0)
			elseif self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_GROUP_UP then
				spec.motor:shiftGroup(true)
			elseif self.shiftType == MotorGearShiftEvent.TYPE_SHIFT_GROUP_DOWN then
				spec.motor:shiftGroup(false)
			elseif self.shiftType == MotorGearShiftEvent.TYPE_SELECT_GROUP then
				spec.motor:selectGroup(self.shiftValue, self.shiftValue ~= 0)
			elseif self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE then
				spec.motor:changeDirection()
			elseif self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_POS then
				spec.motor:changeDirection(1)
			elseif self.shiftType == MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_NEG then
				spec.motor:changeDirection(-1)
			end
		end
	end
end

function MotorGearShiftEvent.sendEvent(vehicle, shiftType, shiftValue)
	if g_client ~= nil then
		g_client:getServerConnection():sendEvent(MotorGearShiftEvent.new(vehicle, shiftType, shiftValue))
	end
end
