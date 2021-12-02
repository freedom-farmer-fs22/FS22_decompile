ValueInterpolator = {}
local ValueInterpolator_mt = Class(ValueInterpolator)

function ValueInterpolator.new(customKey, get, set, target, duration, speed, customMt)
	local self = setmetatable({}, customMt or ValueInterpolator_mt)
	self.customKey = customKey
	self.get = get
	self.set = set
	self.target = target
	self.duration = duration
	self.cur = {
		get()
	}

	if self.duration ~= nil then
		self:updateSpeed()
	else
		speed = (speed or 1) / 1000
		self.speed = {}

		for i = 1, #self.target do
			self.speed[i] = speed
		end
	end

	local isValid = false

	for i = 1, #self.speed do
		if math.abs(self.speed[i]) > 1e-09 then
			isValid = true
		end
	end

	if isValid then
		g_currentMission:addUpdateable(self, customKey)

		return self
	end
end

function ValueInterpolator:setUpdateFunc(updateFunc, updateTarget, ...)
	self.updateFunc = updateFunc
	self.updateTarget = updateTarget
	self.updateArgs = {
		...
	}
end

function ValueInterpolator:setFinishedFunc(finishedFunc, finishedTarget, ...)
	self.finishedFunc = finishedFunc
	self.finishedTarget = finishedTarget
	self.finishedArgs = {
		...
	}
end

function ValueInterpolator:setDeleteListenerObject(object)
	if object ~= nil and object:isa(Object) then
		object:addDeleteListener(self, "onDeleteParent")

		self.deleteListenerObject = object
	end
end

function ValueInterpolator:delete()
end

function ValueInterpolator:getTarget()
	return self.target
end

function ValueInterpolator:updateSpeed()
	if type(self.duration) == "number" then
		self.speed = {}

		for i = 1, #self.target do
			self.speed[i] = math.abs(self.target[i] - self.cur[i]) / self.duration
		end
	else
		self.speed = self.duration
	end
end

function ValueInterpolator:update(dt)
	local finished = true

	for i = 1, #self.cur do
		local direction = MathUtil.sign(self.target[i] - self.cur[i])
		local limitFunc = math.min

		if direction < 0 then
			limitFunc = math.max
		end

		self.cur[i] = limitFunc(self.cur[i] + self.speed[i] * dt * direction, self.target[i])
		finished = finished and self.cur[i] == self.target[i]
	end

	self.set(unpack(self.cur))

	if self.updateFunc ~= nil then
		self.updateFunc(self.updateTarget, unpack(self.updateArgs))
	end

	if self.duration ~= nil then
		self.duration = math.max(self.duration - dt, 1)
	end

	if finished then
		g_currentMission:removeUpdateable(self.customKey)

		if self.deleteListenerObject ~= nil then
			self.deleteListenerObject:removeDeleteListener("onDeleteParent")
		end

		if self.finishedFunc ~= nil then
			self.finishedFunc(self.finishedTarget, unpack(self.finishedArgs))
		end
	end
end

function ValueInterpolator.removeInterpolator(key)
	if g_currentMission:getHasUpdateable(key) then
		g_currentMission:removeUpdateable(key)
	end
end

function ValueInterpolator.hasInterpolator(key)
	return g_currentMission:getHasUpdateable(key)
end

function ValueInterpolator:onDeleteParent()
	g_currentMission:removeUpdateable(self.customKey)
end
