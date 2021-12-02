VehiclePlacementCallback = {}
local VehiclePlacementCallback_mt = Class(VehiclePlacementCallback)

function VehiclePlacementCallback.new()
	local instance = {}

	setmetatable(instance, VehiclePlacementCallback_mt)

	return instance
end

function VehiclePlacementCallback:callback(transformName, x, y, z, distance)
	self.raycastHitName = transformName
	self.x = x
	self.y = y
	self.z = z
	self.distance = distance

	return true
end
