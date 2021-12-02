MorphPositionEffect = {}
local MorphPositionEffect_mt = Class(MorphPositionEffect, ShaderPlaneEffect)

function MorphPositionEffect.new(customMt)
	if customMt == nil then
		customMt = MorphPositionEffect_mt
	end

	local self = ShaderPlaneEffect.new(customMt)

	return self
end

function MorphPositionEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not MorphPositionEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.speed = Effect.getValue(xmlFile, key, node, "speed", 1)
	self.fadeCur = {
		0,
		0
	}
	self.fadeDir = {
		0,
		0
	}
	self.scrollLength = Effect.getValue(xmlFile, key, node, "scrollLength", 1)
	self.scrollSpeed = Effect.getValue(xmlFile, key, node, "scrollSpeed", 1) * 0.001
	self.scrollPosition = 0
	self.scrollUpdate = true

	setShaderParameter(self.node, "morphPosition", 0, 1, 1, 0, false)
	setShaderParameter(self.node, "pervMorphPosition", 0, 1, 1, 0, false)
	setVisibility(self.node, false)

	return true
end

function MorphPositionEffect:update(dt)
	local running = false

	if self.state ~= ShaderPlaneEffect.STATE_OFF then
		local fadeTime = self.fadeInTime

		if self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
			fadeTime = self.fadeOutTime
		end

		self.fadeCur[1] = math.max(0, math.min(1, self.fadeCur[1] + self.fadeDir[1] * dt / fadeTime))
		self.fadeCur[2] = math.max(0, math.min(1, self.fadeCur[2] + self.fadeDir[2] * dt / fadeTime), self.offset)

		if self.state ~= ShaderPlaneEffect.STATE_OFF and self.state ~= ShaderPlaneEffect.STATE_TURNING_OFF then
			self.fadeCur[1] = self.offset
		end

		g_animationManager:setPrevShaderParameter(self.node, "morphPosition", self.fadeCur[1], self.fadeCur[2], 1, self.speed, false, "prevMorphPosition")

		local isVisible = true

		if self.state == ShaderPlaneEffect.STATE_TURNING_OFF and self.fadeCur[1] == 1 then
			isVisible = false
			self.fadeCur[1] = 0
			self.fadeCur[2] = 0
			self.state = ShaderPlaneEffect.STATE_OFF
		end

		setVisibility(self.node, isVisible)

		if (self.state ~= ShaderPlaneEffect.STATE_TURNING_ON or self.fadeCur[1] ~= 0 or self.fadeCur[2] ~= 1) and (self.state ~= ShaderPlaneEffect.STATE_TURNING_OFF or self.fadeCur[1] ~= 1 or self.fadeCur[2] ~= 1) then
			running = true
		end
	else
		running = true
	end

	if self.scrollUpdate then
		self.scrollPosition = (self.scrollPosition + dt * self.scrollSpeed) % self.scrollLength
		local _, y, z, w = getShaderParameter(self.node, "offsetUV")

		setShaderParameter(self.node, "offsetUV", self.scrollPosition, y, z, w, false)
	end

	if not running then
		if self.state == ShaderPlaneEffect.STATE_TURNING_ON then
			self.state = ShaderPlaneEffect.STATE_ON
		elseif self.state == ShaderPlaneEffect.STATE_TURNING_OFF then
			self.state = ShaderPlaneEffect.STATE_OFF
		end
	end
end

function MorphPositionEffect:start(skipDelay)
	if self.startDelay == 0 or skipDelay then
		if self:canStart() and self.state ~= ShaderPlaneEffect.STATE_TURNING_ON and self.state ~= ShaderPlaneEffect.STATE_ON then
			self.state = ShaderPlaneEffect.STATE_TURNING_ON
			self.fadeCur = {
				math.min(self.offset, 0),
				math.min(self.offset, self.fadeCur[2])
			}
			self.fadeDir = {
				0,
				1
			}

			return true
		end
	else
		return false, self.startDelay
	end

	return false
end

function MorphPositionEffect:stop(skipDelay)
	if self.stopDelay == 0 or skipDelay then
		if self.state ~= ShaderPlaneEffect.STATE_TURNING_OFF and self.state ~= ShaderPlaneEffect.STATE_OFF then
			self.state = ShaderPlaneEffect.STATE_TURNING_OFF
			self.fadeDir = {
				1,
				1
			}

			return true
		end
	else
		return false, self.stopDelay
	end

	return false
end

function MorphPositionEffect:reset()
	self.fadeCur = {
		math.min(self.offset, 0),
		math.min(self.offset, 0)
	}
	self.fadeDir = {
		0,
		1
	}

	g_animationManager:setPrevShaderParameter(self.node, "morphPosition", self.fadeCur[1], self.fadeCur[2], 0, self.scrollSpeed, false, "prevMorphPosition")
	setVisibility(self.node, false)

	self.state = ShaderPlaneEffect.STATE_OFF
end

function MorphPositionEffect:setScrollUpdate(state)
	if state == nil then
		self.scrollUpdate = not self.scrollUpdate
	else
		self.scrollUpdate = state
	end
end

function MorphPositionEffect:getIsVisible()
	return self.fadeCur[1] > 0
end

function MorphPositionEffect:getIsFullyVisible()
	return self.fadeCur[2] == 1 and self.fadeCur[1] == 0
end

function MorphPositionEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#speed", "speed", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#scrollLength", "(MorphPositionEffect) scroll length", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#scrollSpeed", "(MorphPositionEffect) scroll speed", 1)
end
