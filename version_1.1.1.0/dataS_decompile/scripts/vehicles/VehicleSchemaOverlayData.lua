VehicleSchemaOverlayData = {}
local VehicleSchemaOverlayData_mt = Class(VehicleSchemaOverlayData)

function VehicleSchemaOverlayData.new(offsetX, offsetY, schemaName, invisibleBorderRight, invisibleBorderLeft)
	local self = setmetatable({}, VehicleSchemaOverlayData_mt)
	self.offsetX = offsetX or 0
	self.offsetY = offsetY or 0
	self.schemaName = schemaName
	self.invisibleBorderRight = invisibleBorderRight or 0.05
	self.invisibleBorderLeft = invisibleBorderLeft or 0.05
	self.attacherJoints = nil

	return self
end

function VehicleSchemaOverlayData:addAttacherJoint(attacherOffsetX, attacherOffsetY, rotation, invertX, liftedOffsetX, liftedOffsetY)
	if not self.attacherJoints then
		self.attacherJoints = {}
	end

	local attacherJointData = {
		x = attacherOffsetX or 0,
		y = attacherOffsetY or 0,
		rotation = rotation or 0,
		invertX = not not invertX,
		liftedOffsetX = liftedOffsetX or 0,
		liftedOffsetY = liftedOffsetY or 5
	}

	table.insert(self.attacherJoints, attacherJointData)
end

VehicleSchemaOverlayData.SCHEMA_OVERLAY = {
	VEHICLE = "VEHICLE",
	HARVESTER = "HARVESTER",
	IMPLEMENT = "IMPLEMENT",
	TRAILER = "TRAILER",
	COMBINE_HEADER = "COMBINE_HEADER"
}
