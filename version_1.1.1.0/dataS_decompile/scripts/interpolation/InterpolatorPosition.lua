InterpolatorPosition = {}
local InterpolatorPosition_mt = Class(InterpolatorPosition)

function InterpolatorPosition.new(positionX, positionY, positionZ, customMt)
	local self = {}
	local mt = customMt

	if mt == nil then
		mt = InterpolatorPosition_mt
	end

	setmetatable(self, mt)

	self.positionX = positionX
	self.positionY = positionY
	self.positionZ = positionZ
	self.lastPositionX = positionX
	self.lastPositionY = positionY
	self.lastPositionZ = positionZ
	self.targetPositionX = positionX
	self.targetPositionY = positionY
	self.targetPositionZ = positionZ

	return self
end

function InterpolatorPosition:setPosition(x, y, z)
	self.positionX = x
	self.positionY = y
	self.positionZ = z
	self.lastPositionX = x
	self.lastPositionY = y
	self.lastPositionZ = z
	self.targetPositionX = x
	self.targetPositionY = y
	self.targetPositionZ = z
end

function InterpolatorPosition:setTargetPosition(x, y, z)
	self.targetPositionX = x
	self.targetPositionY = y
	self.targetPositionZ = z
	self.lastPositionX = self.positionX
	self.lastPositionY = self.positionY
	self.lastPositionZ = self.positionZ
end

function InterpolatorPosition:getInterpolatedValues(interpolationAlpha)
	self.positionX = self.lastPositionX + interpolationAlpha * (self.targetPositionX - self.lastPositionX)
	self.positionY = self.lastPositionY + interpolationAlpha * (self.targetPositionY - self.lastPositionY)
	self.positionZ = self.lastPositionZ + interpolationAlpha * (self.targetPositionZ - self.lastPositionZ)

	return self.positionX, self.positionY, self.positionZ
end
