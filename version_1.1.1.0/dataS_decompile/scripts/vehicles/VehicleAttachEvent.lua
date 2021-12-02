VehicleAttachEvent = {}
local VehicleAttachEvent_mt = Class(VehicleAttachEvent, Event)

InitStaticEventClass(VehicleAttachEvent, "VehicleAttachEvent", EventIds.EVENT_VEHICLE_ATTACH)

function VehicleAttachEvent.emptyNew()
	local self = Event.new(VehicleAttachEvent_mt)

	return self
end

function VehicleAttachEvent.new(vehicle, implement, inputJointIndex, jointIndex, startLowered)
	local self = VehicleAttachEvent.emptyNew()
	self.jointIndex = jointIndex
	self.inputJointIndex = inputJointIndex
	self.vehicle = vehicle
	self.implement = implement
	self.startLowered = startLowered

	assert(self.jointIndex >= 0 and self.jointIndex < 127)

	return self
end

function VehicleAttachEvent:readStream(streamId, connection)
	self.vehicle = NetworkUtil.readNodeObject(streamId)
	self.implement = NetworkUtil.readNodeObject(streamId)
	self.jointIndex = streamReadUIntN(streamId, 7)
	self.inputJointIndex = streamReadUIntN(streamId, 7)
	self.startLowered = streamReadBool(streamId)

	self:run(connection)
end

function VehicleAttachEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
	NetworkUtil.writeNodeObject(streamId, self.implement)
	streamWriteUIntN(streamId, self.jointIndex, 7)
	streamWriteUIntN(streamId, self.inputJointIndex, 7)
	streamWriteBool(streamId, self.startLowered)
end

function VehicleAttachEvent:run(connection)
	if self.vehicle ~= nil and self.vehicle:getIsSynchronized() then
		self.vehicle:attachImplement(self.implement, self.inputJointIndex, self.jointIndex, true, nil, self.startLowered)
	end

	if not connection:getIsServer() then
		g_server:broadcastEvent(self, nil, connection, self.object)
	end
end
