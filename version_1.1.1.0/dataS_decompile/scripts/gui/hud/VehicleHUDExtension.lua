VehicleHUDExtension = {}
local VehicleHUDExtension_mt = Class(VehicleHUDExtension)

function VehicleHUDExtension.new(class_mt, vehicle, uiScale, uiTextColor, uiTextSize)
	local self = setmetatable({}, class_mt or VehicleHUDExtension_mt)
	self.vehicle = vehicle
	self.uiTextColor = uiTextColor
	self.uiTextSize = uiTextSize
	self.uiScale = uiScale
	self.displayComponents = {}

	return self
end

function VehicleHUDExtension:delete()
	for k, component in pairs(self.displayComponents) do
		component:delete()

		self.displayComponents[k] = nil
	end
end

function VehicleHUDExtension:addComponentForCleanup(component)
	if component.delete then
		table.insert(self.displayComponents, component)
	end
end

function VehicleHUDExtension:getDisplayHeight()
	return 0
end

function VehicleHUDExtension:canDraw()
	return true
end

function VehicleHUDExtension:draw(leftPosX, rightPosX, posY)
end

local registry = {}

function VehicleHUDExtension.registerHUDExtension(spec, hudExtensionType)
	registry[spec] = hudExtensionType
end

function VehicleHUDExtension.createHUDExtensionForSpecialization(spec, vehicle, uiScale, uiTextColor, uiTextSize)
	local extType = registry[spec]
	local extension = nil

	if extType then
		extension = extType.new(vehicle, uiScale, uiTextColor, uiTextSize)
	end

	return extension
end

function VehicleHUDExtension.hasHUDExtensionForSpecialization(spec)
	return not not registry[spec]
end
