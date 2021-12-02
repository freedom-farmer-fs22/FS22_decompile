InterpolatorAngle = {}
local InterpolatorAngle_mt = Class(InterpolatorAngle)

function InterpolatorAngle.new(value, customMt)
	local self = {}
	local mt = customMt

	if mt == nil then
		mt = InterpolatorAngle_mt
	end

	setmetatable(self, mt)

	self.value = value
	self.lastValue = value
	self.targetValue = value

	return self
end

function InterpolatorAngle:setAngle(value)
	self.value = value
	self.lastValue = value
	self.targetValue = value
end

function InterpolatorAngle:setTargetAngle(targetValue)
	targetValue = self:clampValue(targetValue)
	self.targetValue = targetValue
	self.lastValue = self.value

	if math.pi < targetValue - self.value then
		self.lastValue = self.value + 2 * math.pi
	elseif targetValue - self.value < -math.pi then
		self.lastValue = self.value - 2 * math.pi
	end
end

function InterpolatorAngle:getInterpolatedValue(interpolationAlpha)
	self.value = self.lastValue + interpolationAlpha * (self.targetValue - self.lastValue)
	self.value = self:clampValue(self.value)

	if self.value == self.min or self.value == self.max then
		self:setAngle(self.value)
	end

	return self.value
end

function InterpolatorAngle:clampValue(value)
	if self.min ~= nil then
		value = math.max(value, self.min)
	end

	if self.max ~= nil then
		value = math.min(value, self.max)
	end

	return value
end

function InterpolatorAngle:setMinMax(min, max)
	self.min = Utils.getNoNil(min, self.min)
	self.max = Utils.getNoNil(max, self.max)
end
