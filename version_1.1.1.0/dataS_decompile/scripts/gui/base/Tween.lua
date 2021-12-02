Tween = {}
local Tween_mt = Class(Tween)

function Tween.new(setterFunction, startValue, endValue, duration, customMt)
	local self = setmetatable({}, customMt or Tween_mt)
	self.setter = setterFunction
	self.startValue = startValue
	self.endValue = endValue
	self.duration = duration
	self.elapsedTime = 0
	self.isFinished = duration == 0
	self.functionTarget = nil
	self.curveFunc = Tween.CURVE.LINEAR

	return self
end

function Tween:getDuration()
	return self.duration
end

function Tween:getFinished()
	return self.isFinished
end

function Tween:reset()
	self.elapsedTime = 0
	self.isFinished = self.duration == 0
end

function Tween:setTarget(target)
	self.functionTarget = target
end

function Tween:update(dt)
	if self.isFinished then
		return
	end

	self.elapsedTime = self.elapsedTime + dt
	local newValue = nil

	if self.duration <= self.elapsedTime then
		self.isFinished = true
		newValue = self:tweenValue(1)
	else
		local t = self.elapsedTime / self.duration
		newValue = self:tweenValue(t)
	end

	self:applyValue(newValue)
end

function Tween:tweenValue(t)
	return MathUtil.lerp(self.startValue, self.endValue, self.curveFunc(t))
end

function Tween:applyValue(newValue)
	if self.functionTarget ~= nil then
		self.setter(self.functionTarget, newValue)
	else
		self.setter(newValue)
	end
end

function Tween:setCurve(func)
	self.curveFunc = func or Tween.CURVE.LINEAR
end

Tween.CURVE = {
	LINEAR = function (t)
		return t
	end,
	EASE_IN = function (t)
		return t * t * t
	end,
	EASE_OUT = function (t)
		local invT = t - 1

		return invT * invT * invT + 1
	end
}

function Tween.CURVE.EASE_IN_OUT(t)
	if t < 0.5 then
		return 0.5 * Tween.CURVE.EASE_IN(t * 2)
	else
		return 0.5 * Tween.CURVE.EASE_OUT((t - 0.5) * 2) + 0.5
	end
end

function Tween.CURVE.EASE_OUT_IN(t)
	if t < 0.5 then
		return 0.5 * Tween.CURVE.EASE_OUT(t * 2)
	else
		return 0.5 * Tween.CURVE.EASE_IN((t - 0.5) * 2) + 0.5
	end
end

function Tween.CURVE.EASE_IN_BACK(t)
	local s = 1.70158

	return math.pow(t, 2) * ((s + 1) * t - s)
end

function Tween.CURVE.EASE_OUT_BACK(t)
	local invT = t - 1
	local s = 1.70158

	return math.pow(invT, 2) * ((s + 1) * invT + s) + 1
end

function Tween.CURVE.EASE_IN_OUT_BACK(t)
	if t < 0.5 then
		return 0.5 * Tween.CURVE.EASE_IN_BACK(t * 2)
	else
		return 0.5 * Tween.CURVE.EASE_OUT_BACK((t - 0.5) * 2) + 0.5
	end
end

function Tween.CURVE.EASE_OUT_IN_BACK(t)
	if t < 0.5 then
		return 0.5 * Tween.CURVE.EASE_OUT_BACK(t * 2)
	else
		return 0.5 * Tween.CURVE.EASE_IN_BACK((t - 0.5) * 2) + 0.5
	end
end
