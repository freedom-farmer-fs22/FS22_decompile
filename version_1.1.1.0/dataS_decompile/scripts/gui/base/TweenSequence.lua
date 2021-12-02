TweenSequence = {}
local TweenSequence_mt = Class(TweenSequence, Tween)

function TweenSequence.new(functionTarget)
	local self = Tween.new(nil, , , , TweenSequence_mt)
	self.functionTarget = functionTarget
	self.callbackStates = {}
	self.callbacksCalled = {}
	self.tweenUpdateRanges = {}
	self.callbackInstants = {}
	self.isLooping = false
	self.totalDuration = 0
	self.isFinished = true

	return self
end

function TweenSequence:insertTween(tween, instant)
	self.tweenUpdateRanges[tween] = {
		instant,
		instant + tween:getDuration()
	}
	self.totalDuration = math.max(instant + tween:getDuration(), self.totalDuration)

	if self.functionTarget ~= nil then
		tween:setTarget(self.functionTarget)
	end
end

function TweenSequence:addTween(tween)
	self:insertTween(tween, self.totalDuration)
end

function TweenSequence:insertInterval(interval, instant)
	for tween, range in pairs(self.tweenUpdateRanges) do
		local tweenStartInstant = range[1]
		local tweenEndInstant = range[2]

		if instant <= tweenStartInstant then
			self.tweenUpdateRanges[tween][1] = tweenStartInstant + interval
			self.tweenUpdateRanges[tween][2] = tweenEndInstant + interval
		end
	end

	for callback, callbackInstant in pairs(self.callbackInstants) do
		if instant <= callbackInstant then
			self.callbackInstants[callback] = callbackInstant + interval
		end
	end

	self.totalDuration = self.totalDuration + interval
end

function TweenSequence:addInterval(interval)
	self:insertInterval(interval, self.totalDuration)
end

function TweenSequence:insertCallback(callback, callbackState, instant)
	self.callbackInstants[callback] = instant
	self.callbackStates[callback] = callbackState
	self.callbacksCalled[callback] = false
end

function TweenSequence:addCallback(callback, callbackState)
	self:insertCallback(callback, callbackState, self.totalDuration)
end

function TweenSequence:getDuration()
	return self.totalDuration
end

function TweenSequence:setTarget(target)
	self.functionTarget = target
end

function TweenSequence:setLooping(isLooping)
	self.isLooping = isLooping
end

function TweenSequence:start()
	self.isFinished = false
end

function TweenSequence:stop()
	self.isFinished = true
end

function TweenSequence:reset()
	self.elapsedTime = 0
	self.isFinished = true

	for tween in pairs(self.tweenUpdateRanges) do
		tween:reset()
	end

	for callback in pairs(self.callbacksCalled) do
		self.callbacksCalled[callback] = false
	end
end

function TweenSequence:update(dt)
	if not self.isFinished then
		local lastUpdateInstant = self.elapsedTime
		self.elapsedTime = self.elapsedTime + dt
		local allFinished = self:updateTweens(lastUpdateInstant, dt)

		self:updateCallbacks()

		if self.totalDuration <= self.elapsedTime and allFinished then
			if self.isLooping then
				self:reset()
				self:start()
			else
				self.isFinished = true
			end
		end
	end
end

function TweenSequence:updateTweens(lastInstant, dt)
	local allFinished = true

	for tween, range in pairs(self.tweenUpdateRanges) do
		local tweenStart = range[1]

		if not tween:getFinished() and tweenStart <= self.elapsedTime then
			local maxDt = math.min(self.elapsedTime - tweenStart, dt)

			tween:update(maxDt)

			allFinished = allFinished and tween:getFinished()
		end
	end

	return allFinished
end

function TweenSequence:updateCallbacks()
	for callback, instant in pairs(self.callbackInstants) do
		if not self.callbacksCalled[callback] and instant <= self.elapsedTime then
			if self.functionTarget ~= nil then
				callback(self.functionTarget, self.callbackStates[callback])
			else
				callback(self.callbackStates[callback])
			end

			self.callbacksCalled[callback] = true
		end
	end
end

TweenSequence.NO_SEQUENCE = TweenSequence.new()

function TweenSequence.NO_SEQUENCE.addTween()
end

function TweenSequence.NO_SEQUENCE.addInterval()
end

function TweenSequence.NO_SEQUENCE.addCallback()
end

function TweenSequence.NO_SEQUENCE.insertTween()
end

function TweenSequence.NO_SEQUENCE.insertInterval()
end

function TweenSequence.NO_SEQUENCE.insertCallback()
end

function TweenSequence.NO_SEQUENCE.getFinished()
	return true
end
