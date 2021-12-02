VehicleAttachRequestEvent = {}
local VehicleAttachRequestEvent_mt = Class(VehicleAttachRequestEvent, Event)

InitStaticEventClass(VehicleAttachRequestEvent, "VehicleAttachRequestEvent", EventIds.EVENT_VEHICLE_ATTACH_REQUEST)

function VehicleAttachRequestEvent.emptyNew()
	return Event.new(VehicleAttachRequestEvent_mt)
end

function VehicleAttachRequestEvent.new(info)
	local self = VehicleAttachRequestEvent.emptyNew()
	self.attacherVehicle = info.attacherVehicle
	self.attachable = info.attachable
	self.attacherVehicleJointDescIndex = info.attacherVehicleJointDescIndex
	self.attachableJointDescIndex = info.attachableJointDescIndex

	return self
end

function VehicleAttachRequestEvent:readStream(streamId, connection)
	self.attacherVehicle = NetworkUtil.readNodeObject(streamId)
	self.attachable = NetworkUtil.readNodeObject(streamId)
	self.attacherVehicleJointDescIndex = streamReadUIntN(streamId, 7)
	self.attachableJointDescIndex = streamReadUIntN(streamId, 7)

	self:run(connection)
end

function VehicleAttachRequestEvent:writeStream(streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.attacherVehicle)
	NetworkUtil.writeNodeObject(streamId, self.attachable)
	streamWriteUIntN(streamId, self.attacherVehicleJointDescIndex, 7)
	streamWriteUIntN(streamId, self.attachableJointDescIndex, 7)
end

function VehicleAttachRequestEvent:run(connection)
	if not connection:getIsServer() and self.attacherVehicle ~= nil and self.attacherVehicle:getIsSynchronized() then
		self.attacherVehicle:attachImplementFromInfo(self)
	end
end
