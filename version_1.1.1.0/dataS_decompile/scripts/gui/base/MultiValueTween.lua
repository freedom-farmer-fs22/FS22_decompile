MultiValueTween = {}
local MultiValueTween_mt = Class(MultiValueTween, Tween)

function MultiValueTween.new(setterFunction, startValues, endValues, duration, customMt)
	local self = Tween.new(setterFunction, startValues, endValues, duration, customMt or MultiValueTween_mt)
	self.values = {
		unpack(startValues)
	}

	return self
end

function MultiValueTween:setTarget(target)
	local hadTarget = self.functionTarget ~= nil

	MultiValueTween:superClass().setTarget(self, target)

	if target ~= nil and not hadTarget then
		table.insert(self.values, 1, target)
	elseif target == nil and hadTarget then
		table.remove(self.values, 1)
	else
		self.values[1] = target
	end
end

function MultiValueTween:tweenValue(t)
	local targetOffset = self.functionTarget ~= nil and 1 or 0

	for i = 1, #self.startValue do
		local startValue = self.startValue[i]
		local endValue = self.endValue[i]
		self.values[i + targetOffset] = MathUtil.lerp(startValue, endValue, self.curveFunc(t))
	end

	return self.values
end

function MultiValueTween:applyValue()
	self.setter(unpack(self.values))
end
