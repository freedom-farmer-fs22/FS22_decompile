SplineFollower = {}
local SplineFollower_mt = Class(SplineFollower)

function SplineFollower:onCreate(node)
	SplineFollower.new(node)
end

function SplineFollower.new(node)
	local self = setmetatable({}, SplineFollower_mt)
	self.spline = node
	self.follower = getChildAt(node, 0)
	local length = getSplineLength(self.spline)
	self.speed = Utils.getNoNil(getUserAttribute(node, "speed"), 1)

	if length ~= 0 then
		self.speed = self.speed / length
	end

	self.speed = self.speed / 1000
	self.splinePos = 0

	g_currentMission:addUpdateable(self)

	return self
end

function SplineFollower:delete()
end

function SplineFollower:update(dt)
	self.splinePos = self.splinePos + dt * self.speed

	if self.splinePos > 1 then
		self.splinePos = self.splinePos - 1
	end

	local x, y, z = getSplinePosition(self.spline, self.splinePos)

	setWorldTranslation(self.follower, x, y, z)
end
