InterpolatorValue = {}
local InterpolatorValue_mt = Class(InterpolatorValue)

function InterpolatorValue.new(value, customMt)
	local mt = customMt

	if mt == nil then
		mt = InterpolatorValue_mt
	end

	local self = setmetatable({}, mt)
	self.value = value
	self.lastValue = value
	self.targetValue = value

	return self
end

function InterpolatorValue:setValue(value)
	self.value = value
	self.lastValue = value
	self.targetValue = value
end

function InterpolatorValue:setTargetValue(value)
	self.targetValue = self:clampValue(value)
	self.lastValue = self.value
end

function InterpolatorValue:getInterpolatedValue(interpolationAlpha)
	self.value = self.lastValue + interpolationAlpha * (self.targetValue - self.lastValue)
	self.value = self:clampValue(self.value)

	if self.value == self.min or self.value == self.max then
		self:setValue(self.value)
	end

	return self.value
end

function InterpolatorValue:clampValue(value)
	if self.min ~= nil then
		value = math.max(value, self.min)
	end

	if self.max ~= nil then
		value = math.min(value, self.max)
	end

	return value
end

function InterpolatorValue:setMinMax(min, max)
	self.min = Utils.getNoNil(min, self.min)
	self.max = Utils.getNoNil(max, self.max)
end
