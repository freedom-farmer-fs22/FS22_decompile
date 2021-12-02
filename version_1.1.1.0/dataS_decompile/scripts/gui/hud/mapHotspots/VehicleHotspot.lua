VehicleHotspot = {
	TYPE = {}
}
VehicleHotspot.TYPE.TRACTOR = 1
VehicleHotspot.TYPE.TRUCK = 2
VehicleHotspot.TYPE.CAR = 3
VehicleHotspot.TYPE.HARVESTER = 4
VehicleHotspot.TYPE.WHEELLOADER = 5
VehicleHotspot.TYPE.TRAILER = 6
VehicleHotspot.TYPE.TOOL = 7
VehicleHotspot.TYPE.TOOL_TRAILED = 8
VehicleHotspot.TYPE.CUTTER = 9
VehicleHotspot.TYPE.OTHER = 10
VehicleHotspot.TYPE.HORSE = 11
VehicleHotspot.TYPE.TRAIN = 12
VehicleHotspot.CATEGORY_MAPPING = {
	[VehicleHotspot.TYPE.TRACTOR] = MapHotspot.CATEGORY_STEERABLE,
	[VehicleHotspot.TYPE.TRUCK] = MapHotspot.CATEGORY_STEERABLE,
	[VehicleHotspot.TYPE.CAR] = MapHotspot.CATEGORY_STEERABLE,
	[VehicleHotspot.TYPE.HARVESTER] = MapHotspot.CATEGORY_COMBINE,
	[VehicleHotspot.TYPE.WHEELLOADER] = MapHotspot.CATEGORY_STEERABLE,
	[VehicleHotspot.TYPE.TRAILER] = MapHotspot.CATEGORY_TRAILER,
	[VehicleHotspot.TYPE.TOOL] = MapHotspot.CATEGORY_TOOL,
	[VehicleHotspot.TYPE.TOOL_TRAILED] = MapHotspot.CATEGORY_TOOL,
	[VehicleHotspot.TYPE.CUTTER] = MapHotspot.CATEGORY_TOOL,
	[VehicleHotspot.TYPE.OTHER] = MapHotspot.CATEGORY_TOOL,
	[VehicleHotspot.TYPE.HORSE] = MapHotspot.CATEGORY_ANIMAL,
	[VehicleHotspot.TYPE.TRAIN] = MapHotspot.CATEGORY_STEERABLE
}
VehicleHotspot.FILE_RESOLUTION = {
	1024,
	512
}
VehicleHotspot.FILENAME = "dataS/menu/hud/mapHotspots.png"
VehicleHotspot.UV = {
	[VehicleHotspot.TYPE.TRUCK] = GuiUtils.getUVs({
		112,
		4,
		100,
		100
	}, VehicleHotspot.FILE_RESOLUTION),
	[VehicleHotspot.TYPE.TRACTOR] = GuiUtils.getUVs({
		220,
		4,
		100,
		100
	}, VehicleHotspot.FILE_RESOLUTION),
	[VehicleHotspot.TYPE.HARVESTER] = GuiUtils.getUVs({
		328,
		4,
		100,
		100
	}, VehicleHotspot.FILE_RESOLUTION),
	[VehicleHotspot.TYPE.CAR] = GuiUtils.getUVs({
		436,
		4,
		100,
		100
	}, VehicleHotspot.FILE_RESOLUTION),
	[VehicleHotspot.TYPE.WHEELLOADER] = GuiUtils.getUVs({
		544,
		4,
		100,
		100
	}, VehicleHotspot.FILE_RESOLUTION),
	[VehicleHotspot.TYPE.OTHER] = GuiUtils.getUVs({
		652,
		4,
		100,
		100
	}, VehicleHotspot.FILE_RESOLUTION),
	[VehicleHotspot.TYPE.CUTTER] = GuiUtils.getUVs({
		4,
		111,
		100,
		100
	}, VehicleHotspot.FILE_RESOLUTION),
	[VehicleHotspot.TYPE.TRAILER] = GuiUtils.getUVs({
		112,
		111,
		100,
		100
	}, VehicleHotspot.FILE_RESOLUTION),
	[VehicleHotspot.TYPE.TOOL] = GuiUtils.getUVs({
		220,
		111,
		100,
		100
	}, VehicleHotspot.FILE_RESOLUTION),
	[VehicleHotspot.TYPE.TOOL_TRAILED] = GuiUtils.getUVs({
		328,
		111,
		100,
		100
	}, VehicleHotspot.FILE_RESOLUTION),
	[VehicleHotspot.TYPE.HORSE] = GuiUtils.getUVs({
		544,
		111,
		100,
		100
	}, VehicleHotspot.FILE_RESOLUTION),
	[VehicleHotspot.TYPE.TRAIN] = GuiUtils.getUVs({
		652,
		111,
		100,
		100
	}, VehicleHotspot.FILE_RESOLUTION)
}
local refSize = {
	100,
	100
}
VehicleHotspot.CLICK_AREAS = {
	[VehicleHotspot.TYPE.TRACTOR] = MapHotspot.getClickArea({
		29,
		18,
		42,
		64
	}, refSize, 0),
	[VehicleHotspot.TYPE.TRUCK] = MapHotspot.getClickArea({
		32,
		5,
		40,
		90
	}, refSize, 0),
	[VehicleHotspot.TYPE.CAR] = MapHotspot.getClickArea({
		33,
		23,
		34,
		54
	}, refSize, 0),
	[VehicleHotspot.TYPE.HARVESTER] = MapHotspot.getClickArea({
		28,
		3,
		44,
		94
	}, refSize, 0),
	[VehicleHotspot.TYPE.WHEELLOADER] = MapHotspot.getClickArea({
		30,
		8,
		40,
		84
	}, refSize, 0),
	[VehicleHotspot.TYPE.TRAILER] = MapHotspot.getClickArea({
		15,
		37,
		70,
		26
	}, refSize, 0),
	[VehicleHotspot.TYPE.TOOL] = MapHotspot.getClickArea({
		35,
		37,
		30,
		26
	}, refSize, 0),
	[VehicleHotspot.TYPE.TOOL_TRAILED] = MapHotspot.getClickArea({
		31,
		18,
		38,
		64
	}, refSize, 0),
	[VehicleHotspot.TYPE.CUTTER] = MapHotspot.getClickArea({
		32,
		29,
		36,
		42
	}, refSize, 0),
	[VehicleHotspot.TYPE.OTHER] = MapHotspot.getClickArea({
		34,
		34,
		32,
		32
	}, refSize, 0),
	[VehicleHotspot.TYPE.HORSE] = MapHotspot.getClickArea({
		30,
		11,
		40,
		78
	}, refSize, 0),
	[VehicleHotspot.TYPE.TRAIN] = MapHotspot.getClickArea({
		35,
		6,
		30,
		88
	}, refSize, 0)
}
local VehicleHotspot_mt = Class(VehicleHotspot, MapHotspot)

function VehicleHotspot.new(customMt)
	local self = MapHotspot.new(customMt or VehicleHotspot_mt)
	self.width, self.height = getNormalizedScreenValues(60, 60)
	self.vehicleType = VehicleHotspot.TYPE.OTHER
	self.hasRotation = true

	return self
end

function VehicleHotspot:getCategory()
	return VehicleHotspot.CATEGORY_MAPPING[self.vehicleType]
end

function VehicleHotspot:setVehicle(vehicle)
	self.vehicle = vehicle

	if self.icon ~= nil then
		self.icon:delete()
	end

	self.icon = Overlay.new(VehicleHotspot.FILENAME, 0, 0, self.width, self.height)

	self.icon:setColor(unpack(self.color))
	self.icon:setScale(self.scale, self.scale)
	self:setVehicleType(self.vehicleType)
end

function VehicleHotspot:getVehicle()
	return self.vehicle
end

function VehicleHotspot:setVehicleType(vehicleType)
	self.vehicleType = vehicleType

	if self.icon ~= nil then
		self.icon:setUVs(VehicleHotspot.UV[vehicleType])
	end

	self.clickArea = VehicleHotspot.CLICK_AREAS[vehicleType]
end

function VehicleHotspot:setHasRotation(hasRotation)
	self.hasRotation = hasRotation
end

function VehicleHotspot:getWorldPosition()
	local x, _, z = nil

	if self.vehicle ~= nil then
		x, _, z = getWorldTranslation(self.vehicle.rootNode)
	end

	return x, z
end

function VehicleHotspot:getWorldRotation()
	if self.vehicle == nil or not self.hasRotation then
		return 0
	end

	local dx, _, dz = localDirectionToWorld(self.vehicle.rootNode, 0, 0, 1)

	return MathUtil.getYRotationFromDirection(dx, dz) + math.pi
end

function VehicleHotspot.getTypeByName(name)
	if name == nil then
		return nil
	end

	name = name:upper()

	return VehicleHotspot.TYPE[name]
end

function VehicleHotspot:getColor()
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		local farm = g_farmManager:getFarmById(self.ownerFarmId)

		if farm ~= nil then
			local color = Farm.COLORS[farm.color]

			if color ~= nil then
				return color
			end
		end
	end

	return self.color
end
