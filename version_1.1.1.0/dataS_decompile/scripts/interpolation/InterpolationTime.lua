InterpolationTime = {}
local InterpolationTime_mt = Class(InterpolationTime)

function InterpolationTime.new(maxInterpolationAlpha, customMt)
	local self = {}
	local mt = customMt

	if mt == nil then
		mt = InterpolationTime_mt
	end

	setmetatable(self, mt)

	self.maxInterpolationAlpha = maxInterpolationAlpha
	self.interpolationAlpha = maxInterpolationAlpha
	self.interpolationDuration = 80
	self.isDirty = false
	self.lastPhysicsNetworkTime = nil

	return self
end

function InterpolationTime:startNewPhase(interpolationDuration)
	self.interpolationDuration = interpolationDuration
	self.interpolationAlpha = 0
	self.isDirty = true
end

function InterpolationTime:startNewPhaseNetwork()
	local deltaTime = g_client.tickDuration

	if self.lastPhysicsNetworkTime ~= nil then
		deltaTime = math.min(g_packetPhysicsNetworkTime - self.lastPhysicsNetworkTime, 3 * g_client.tickDuration)
	end

	self.lastPhysicsNetworkTime = g_packetPhysicsNetworkTime
	local interpTimeLeft = g_clientInterpDelay

	if self.interpolationAlpha < 1 then
		interpTimeLeft = (1 - self.interpolationAlpha) * self.interpolationDuration
		interpTimeLeft = interpTimeLeft * 0.95 + g_clientInterpDelay * 0.05
		interpTimeLeft = math.min(interpTimeLeft, 3 * g_clientInterpDelay)
	end

	self.interpolationDuration = interpTimeLeft + deltaTime
	self.interpolationAlpha = 0
	self.isDirty = true
end

function InterpolationTime:reset()
	self.interpolationAlpha = self.maxInterpolationAlpha
	self.isDirty = false
end

function InterpolationTime:update(dt)
	local interpolationAlpha = self.interpolationAlpha + dt / self.interpolationDuration

	if self.maxInterpolationAlpha <= interpolationAlpha then
		interpolationAlpha = self.maxInterpolationAlpha
		self.isDirty = false
	end

	self.interpolationAlpha = interpolationAlpha
end

function InterpolationTime:getAlpha()
	return self.interpolationAlpha
end

function InterpolationTime:isInterpolating()
	return self.interpolationAlpha < self.maxInterpolationAlpha
end
