Barrier = {}
local Barrier_mt = Class(Barrier)

function Barrier:onCreate(id)
	g_currentMission:addUpdateable(Barrier.new(id))
end

function Barrier.new(id, customMt)
	local self = {}

	setmetatable(self, customMt or Barrier_mt)

	self.triggerId = id

	addTrigger(id, "triggerCallback", self)

	self.barriers = {}
	local num = getNumOfChildren(id)

	for i = 0, num - 1 do
		local childLevel1 = getChildAt(id, i)

		if childLevel1 ~= 0 and getNumOfChildren(id) >= 1 then
			local barrierId = getChildAt(childLevel1, 0)

			if barrierId ~= 0 then
				table.insert(self.barriers, barrierId)
			end
		end
	end

	self.isEnabled = true
	self.count = 0
	self.angle = 90
	self.maxAngle = 90
	self.minAngle = 0

	return self
end

function Barrier:delete()
	removeTrigger(self.triggerId)
end

function Barrier:update(dt)
	local old = self.angle

	if self.count > 0 then
		if self.angle < self.maxAngle then
			self.angle = self.angle + dt * 0.001 * 60
		end

		if self.maxAngle < self.angle then
			self.angle = self.maxAngle
		end
	else
		if self.minAngle < self.angle then
			self.angle = self.angle - dt * 0.001 * 60
		end

		if self.angle < self.minAngle then
			self.angle = self.minAngle
		end
	end

	if old ~= self.angle then
		for i = 1, table.getn(self.barriers) do
			setRotation(self.barriers[i], 0, 0, MathUtil.degToRad(self.angle))
		end
	end
end

function Barrier:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter and self.isEnabled then
		self.count = self.count + 1
	elseif onLeave then
		self.count = self.count - 1
	end
end
