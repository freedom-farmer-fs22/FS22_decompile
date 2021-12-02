InterpolatorQuaternion = {}
local InterpolatorQuaternion_mt = Class(InterpolatorQuaternion)

function InterpolatorQuaternion.new(qx, qy, qz, qw, customMt)
	local self = {}
	local mt = customMt

	if mt == nil then
		mt = InterpolatorQuaternion_mt
	end

	setmetatable(self, mt)

	self.quaternionX = qx
	self.quaternionY = qy
	self.quaternionZ = qz
	self.quaternionW = qw
	self.lastQuaternionX = qx
	self.lastQuaternionY = qy
	self.lastQuaternionZ = qz
	self.lastQuaternionW = qw
	self.targetQuaternionX = qx
	self.targetQuaternionY = qy
	self.targetQuaternionZ = qz
	self.targetQuaternionW = qw

	return self
end

function InterpolatorQuaternion:setQuaternion(qx, qy, qz, qw)
	self.quaternionX = qx
	self.quaternionY = qy
	self.quaternionZ = qz
	self.quaternionW = qw
	self.lastQuaternionX = qx
	self.lastQuaternionY = qy
	self.lastQuaternionZ = qz
	self.lastQuaternionW = qw
	self.targetQuaternionX = qx
	self.targetQuaternionY = qy
	self.targetQuaternionZ = qz
	self.targetQuaternionW = qw
end

function InterpolatorQuaternion:setTargetQuaternion(qx, qy, qz, qw)
	self.targetQuaternionX = qx
	self.targetQuaternionY = qy
	self.targetQuaternionZ = qz
	self.targetQuaternionW = qw
	self.lastQuaternionX = self.quaternionX
	self.lastQuaternionY = self.quaternionY
	self.lastQuaternionZ = self.quaternionZ
	self.lastQuaternionW = self.quaternionW
end

function InterpolatorQuaternion:getInterpolatedValues(interpolationAlpha)
	self.quaternionX, self.quaternionY, self.quaternionZ, self.quaternionW = MathUtil.nlerpQuaternionShortestPath(self.lastQuaternionX, self.lastQuaternionY, self.lastQuaternionZ, self.lastQuaternionW, self.targetQuaternionX, self.targetQuaternionY, self.targetQuaternionZ, self.targetQuaternionW, interpolationAlpha)

	return self.quaternionX, self.quaternionY, self.quaternionZ, self.quaternionW
end
