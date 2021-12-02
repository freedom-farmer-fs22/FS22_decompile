LevelerEffect = {}
local LevelerEffect_mt = Class(LevelerEffect, ShaderPlaneEffect)

function LevelerEffect.new(customMt)
	local self = ShaderPlaneEffect.new(customMt or LevelerEffect_mt)

	return self
end

function LevelerEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not LevelerEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.speed = Effect.getValue(xmlFile, key, node, "speed", 1) * 0.001
	self.minHeight = Effect.getValue(xmlFile, key, node, "minHeight", -0.5)
	self.maxHeight = Effect.getValue(xmlFile, key, node, "maxHeight", 1)
	self.scrollPosition = 0
	self.depthTarget = 0
	self.fillLevel = 0
	self.lastVehicleSpeed = 0

	return true
end

function LevelerEffect:update(dt)
	LevelerEffect:superClass().update(self, dt)

	if self.state == ShaderPlaneEffect.STATE_ON then
		setVisibility(self.node, true)

		if self.depthTarget < self.fillLevel then
			self.depthTarget = math.min(self.fillLevel, self.depthTarget + 0.001 * dt)
		elseif self.fillLevel < self.depthTarget then
			self.depthTarget = math.max(self.fillLevel, self.depthTarget - 0.001 * dt)
		end

		self.scrollPosition = self.scrollPosition + self.lastVehicleSpeed * self.speed

		setShaderParameter(self.node, "VertxoffsetVertexdeformMotionUVscale", self.maxHeight, self.minHeight + self.depthTarget * (self.maxHeight - self.minHeight), self.scrollPosition, 6, false)
	else
		setVisibility(self.node, false)
	end
end

function LevelerEffect:isRunning()
	return LevelerEffect:superClass().isRunning(self) or self.state == ShaderPlaneEffect.STATE_ON
end

function LevelerEffect:setFillLevel(fillLevel)
	self.fillLevel = fillLevel
end

function LevelerEffect:setLastVehicleSpeed(speed)
	self.lastVehicleSpeed = speed
end

function LevelerEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#speed", "speed", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#minHeight", "(LevelerEffect) Min. height", -0.5)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxHeight", "(LevelerEffect) Max. height", 1)
end
