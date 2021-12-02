VehicleShopBase = {}
local VehicleShopBase_mt = Class(VehicleShopBase)

function VehicleShopBase:onCreate(id)
	g_currentMission:addUpdateable(VehicleShopBase.new(id))
end

function VehicleShopBase.new(name)
	local self = {}

	setmetatable(self, VehicleShopBase_mt)

	self.id = name
	self.balloons = getChildAt(self.id, 1)
	self.alphaBadWeather = 0.4
	self.timer = 0
	self.updateDelay = 2000
	self.alphaCurve = AnimCurve.new(linearInterpolator1)

	self.alphaCurve:addKeyframe({
		0.3,
		time = 0
	})
	self.alphaCurve:addKeyframe({
		0.3,
		time = 330
	})
	self.alphaCurve:addKeyframe({
		0.6,
		time = 360
	})
	self.alphaCurve:addKeyframe({
		1,
		time = 420
	})
	self.alphaCurve:addKeyframe({
		1,
		time = 1200
	})
	self.alphaCurve:addKeyframe({
		0.3,
		time = 1320
	})
	self.alphaCurve:addKeyframe({
		0.3,
		time = 1440
	})

	if g_currentMission ~= nil then
		g_currentMission.vehicleShopBase = self

		if g_currentMission.environment ~= nil then
			local dayMinutes = g_currentMission.environment.dayTime / 60000

			setShaderParameter(self.balloons, "alpha", self.alphaCurve:get(dayMinutes), 0, 0, 0, true)
		end
	end

	setVisibility(self.id, false)

	return self
end

function VehicleShopBase:delete()
end

function VehicleShopBase:update(dt)
	if g_currentMission ~= nil and g_currentMission.environment ~= nil and getVisibility(self.id) then
		self.timer = self.timer + dt

		if self.updateDelay < self.timer then
			self.timer = 0
		end
	end
end
