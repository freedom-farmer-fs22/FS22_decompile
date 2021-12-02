WaterLog = {
	STATE_EMERGING = 0,
	STATE_PAUSING = 1,
	STATE_MOVING = 2
}
local WaterLog_mt = Class(WaterLog)

function WaterLog:onCreate(id)
	g_currentMission:addUpdateable(WaterLog.new(id))
end

function WaterLog.new(id)
	local self = {}

	setmetatable(self, WaterLog_mt)

	self.splineId = getChildAt(id, 0)
	self.waterLogId = getChildAt(id, 1)
	self.splinePos = 0
	self.speed = Utils.getNoNil(getUserAttribute(id, "speed"), 0.001)
	self.emergeTime = Utils.getNoNil(getUserAttribute(id, "emergeTime"), 15000)
	self.emergeTimer = self.emergeTime
	self.pauseTime = Utils.getNoNil(getUserAttribute(id, "pauseTime"), 15000)
	self.pauseTimer = self.pauseTime
	self.state = WaterLog.STATE_EMERGING

	return self
end

function WaterLog:delete()
end

function WaterLog:update(dt)
	if self.state == WaterLog.STATE_EMERGING then
		self.emergeTimer = self.emergeTimer - dt

		if self.emergeTimer < 0 then
			self.emergeTimer = 0
			self.state = WaterLog.STATE_PAUSING
		end

		local x, y, z = getSplinePosition(self.splineId, 0)
		local rx, ry, rz = getSplineOrientation(self.splineId, 0, 0, -1, 0)

		setTranslation(self.waterLogId, x, y - 3.5 * self.emergeTimer / self.emergeTime, z)
		setRotation(self.waterLogId, rx, ry, rz)
	elseif self.state == WaterLog.STATE_PAUSING then
		self.pauseTimer = self.pauseTimer - dt

		if self.pauseTimer < 0 then
			self.splinePos = 0
			self.state = WaterLog.STATE_MOVING
		end
	elseif self.state == WaterLog.STATE_MOVING then
		self.splinePos = self.splinePos + dt * self.speed * 0.01

		if self.splinePos > 1 then
			self.splinePos = 1
			self.emergeTimer = self.emergeTime
			self.pauseTimer = self.pauseTime
			self.state = WaterLog.STATE_EMERGING
		end

		local x, y, z = getSplinePosition(self.splineId, self.splinePos)
		local rx, ry, rz = getSplineOrientation(self.splineId, self.splinePos, 0, -1, 0)

		setTranslation(self.waterLogId, x, y, z)
		setRotation(self.waterLogId, rx, ry, rz)
	end
end
