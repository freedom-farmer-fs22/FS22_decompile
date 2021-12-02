ShakeAnimation = {
	STATE_OFF = 0,
	STATE_ON = 1,
	STATE_TURNING_OFF = 2
}
local ShakeAnimation_mt = Class(ShakeAnimation, Animation)

function ShakeAnimation.new(customMt)
	local self = Animation.new(customMt or ShakeAnimation_mt)
	self.state = ShakeAnimation.STATE_OFF
	self.node = nil
	self.turnOnOffVariance = nil
	self.turnOnFadeTime = 0
	self.turnOffFadeTime = 0
	self.initialTurnOnFadeTime = 1000
	self.currentAlpha = 0
	self.owner = nil

	function self.speedFunc()
		return 1
	end

	self.speedFuncTarget = self

	return self
end

function ShakeAnimation:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if not xmlFile:hasProperty(key) then
		return nil
	end

	self.owner = owner
	self.node = xmlFile:getValue(key .. "#node", nil, rootNodes, i3dMapping)

	if self.node == nil then
		Logging.xmlWarning(xmlFile, "Missing node for shake animation '%s'!", key)

		return nil
	end

	if not getHasShaderParameter(self.node, "shaking") then
		Logging.xmlWarning(xmlFile, "Node '%s' has no shader parameter 'shaking' for shake animation '%s'!", getName(self.node), key)

		return nil
	end

	self.turnOnFadeTime = math.max(xmlFile:getValue(key .. "#turnOnFadeTime", 2) * 1000, 1)
	self.turnOffFadeTime = math.max(xmlFile:getValue(key .. "#turnOffFadeTime", 2) * 1000, 1)
	self.turnOnOffVariance = xmlFile:getValue(key .. "#turnOnOffVariance")

	if self.turnOnOffVariance ~= nil then
		self.initialTurnOnFadeTime = self.turnOnFadeTime
		self.initialTurnOffFadeTime = self.turnOffFadeTime
		self.turnOnOffVariance = self.turnOnOffVariance * 1000
	end

	self.shaking = xmlFile:getValue(key .. "#shaking", "0 0 0 0", true)

	return self
end

function ShakeAnimation:update(dt)
	ShakeAnimation:superClass().update(self, dt)

	local needUpdate = false

	if self.state == ShakeAnimation.STATE_ON then
		needUpdate = self.currentAlpha < 1
		self.currentAlpha = math.min(1, self.currentAlpha + dt / self.turnOnFadeTime)
	elseif self.state == ShakeAnimation.STATE_TURNING_OFF then
		needUpdate = self.currentAlpha > 0
		self.currentAlpha = math.max(0, self.currentAlpha - dt / self.turnOffFadeTime)
	end

	if needUpdate then
		local shaking = self.shaking
		local alpha = self.currentAlpha

		g_animationManager:setPrevShaderParameter(self.node, "shaking", shaking[1] * alpha, shaking[2] * alpha, shaking[3] * alpha, shaking[4] * alpha, false, "prevShaking")
	end

	if self.state == ShakeAnimation.STATE_TURNING_OFF and self.currentAlpha == 0 then
		self.state = ShakeAnimation.STATE_OFF
	end

	self:updateDuplicates()
end

function ShakeAnimation:isRunning()
	return self.state ~= ShakeAnimation.STATE_OFF
end

function ShakeAnimation:start()
	if self.state ~= ShakeAnimation.STATE_ON then
		if self.state == ShakeAnimation.STATE_OFF and self.turnOnOffVariance ~= nil and self.currentAlpha == 0 then
			self.turnOnFadeTime = self.initialTurnOnFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
			self.turnOffFadeTime = self.initialTurnOffFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
		end

		self.state = ShakeAnimation.STATE_ON

		self:updateDuplicates()

		return true
	end

	return false
end

function ShakeAnimation:stop()
	if self.state ~= ShakeAnimation.STATE_OFF then
		self.state = ShakeAnimation.STATE_TURNING_OFF

		self:updateDuplicates()

		return true
	end

	return false
end

function ShakeAnimation:reset()
	self.currentAlpha = 0
	self.state = ShakeAnimation.STATE_OFF

	self:updateDuplicates()
end

function ShakeAnimation:isDuplicate(otherAnimation)
	if otherAnimation:isa(ShakeAnimation) and self.parent == otherAnimation.parent and self.node == otherAnimation.node then
		return true
	end

	return false
end

function ShakeAnimation:updateDuplicate(otherAnimation)
	otherAnimation.currentAlpha = self.currentAlpha
	otherAnimation.state = self.state
end

function ShakeAnimation.registerAnimationClassXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Node")
	schema:register(XMLValueType.VECTOR_4, basePath .. "#shaking", "(ShakeAnimation) Shaking scale for shader parameters", "0 0 0 0")
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnFadeTime", "Turn on fade time", 2)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOffFadeTime", "Turn off fade time", 2)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnOffVariance", "Turn off time variance")
	schema:register(XMLValueType.STRING, basePath .. "#speedFunc", "Lua speed function")
end
