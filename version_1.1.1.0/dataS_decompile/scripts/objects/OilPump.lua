OilPump = {}
local OilPump_mt = Class(OilPump)

function OilPump:onCreate(id)
	g_currentMission:addUpdateable(OilPump.new(id))
end

function OilPump.new(name)
	local self = {}

	setmetatable(self, OilPump_mt)

	self.axisTable = {
		0,
		0,
		0
	}
	self.me = name
	self.head = getChildAt(self.me, 1)
	self.cylinders = getChildAt(self.me, 2)
	self.innerCylinders = getChildAt(self.cylinders, 0)
	self.speed = 0.0012
	self.zRotationMin = 0
	self.zRotationMax = MathUtil.degToRad(40)
	self.timer = math.random() * 2 * math.pi

	return self
end

function OilPump:delete()
end

function OilPump:update(dt)
	self.timer = self.timer + dt * 0.001

	if self.timer >= 2 * math.pi then
		self.timer = 0
	end

	local sinValue = (math.sin(self.timer) + 1) / 2
	local zRotation = self.zRotationMax * sinValue
	local fakeValue = 2.105 - 1.977 / math.cos(zRotation - self.zRotationMax / 2)
	local xRotation = MathUtil.degToRad(-fakeValue * 15)
	local yScale = 1 + 0.5 * sinValue

	setRotation(self.head, 0, 0, zRotation)
	setRotation(self.cylinders, 0, 0, xRotation)
	setScale(self.innerCylinders, 1, yScale, 1)
end
