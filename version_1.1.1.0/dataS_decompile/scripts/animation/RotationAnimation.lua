RotationAnimation = {
	STATE_OFF = 0,
	STATE_ON = 1,
	STATE_TURNING_OFF = 2
}
local RotationAnimation_mt = Class(RotationAnimation, Animation)

function RotationAnimation.new(customMt)
	local self = Animation.new(customMt or RotationAnimation_mt)
	self.state = RotationAnimation.STATE_OFF
	self.node = nil
	self.shaderParameterName = nil
	self.shaderComponentScale = {
		1,
		0,
		0,
		0
	}
	self.rotSpeed = 0
	self.currentAlpha = 0
	self.initialTurnOnFadeTime = 1000
	self.turnOnOffVariance = nil
	self.turnOnFadeTime = 0
	self.turnOffFadeTime = 0
	self.rotAxis = 1
	self.currentRot = 0
	self.owner = nil

	function self.speedFunc()
		return 1
	end

	self.speedFuncTarget = self

	return self
end

function RotationAnimation:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if not xmlFile:hasProperty(key) then
		return nil
	end

	self.owner = owner
	self.node = xmlFile:getValue(key .. "#node", nil, rootNodes, i3dMapping)

	if self.node == nil then
		Logging.xmlWarning(xmlFile, "Missing node for rotation animation '%s'!", key)

		return nil
	end

	self.shaderParameterName = xmlFile:getValue(key .. "#shaderParameterName")

	if self.shaderParameterName ~= nil then
		if not getHasShaderParameter(self.node, self.shaderParameterName) then
			Logging.xmlWarning(xmlFile, "Node '%s' has no shader parameter '%s' for animationNode '%s'!", getName(self.node), self.shaderParameterName, key)

			return nil
		end

		self.shaderParameterPrevName = xmlFile:getValue(key .. "#shaderParameterPrevName")

		if self.shaderParameterPrevName ~= nil then
			if not getHasShaderParameter(self.node, self.shaderParameterPrevName) then
				Logging.xmlWarning(xmlFile, "Node '%s' has no shader parameter '%s' (prev) for animationNode '%s'!", getName(self.node), self.shaderParameterPrevName, key)

				return nil
			end
		else
			local prevName = "prev" .. self.shaderParameterName:sub(1, 1):upper() .. self.shaderParameterName:sub(2)

			if getHasShaderParameter(self.node, prevName) then
				self.shaderParameterPrevName = prevName
			end
		end
	end

	self.shaderComponentScale = xmlFile:getValue(key .. "#shaderComponentScale", "1 0 0 0", true)
	self.rotSpeed = xmlFile:getValue(key .. "#rotSpeed", 1) * 0.001
	self.rotAxis = xmlFile:getValue(key .. "#rotAxis", 2)
	self.turnOnFadeTime = math.max(xmlFile:getValue(key .. "#turnOnFadeTime", 2) * 1000, 1)
	self.turnOffFadeTime = math.max(xmlFile:getValue(key .. "#turnOffFadeTime", 2) * 1000, 1)
	self.turnOnOffVariance = xmlFile:getValue(key .. "#turnOnOffVariance")

	if self.turnOnOffVariance ~= nil then
		self.initialTurnOnFadeTime = self.turnOnFadeTime
		self.initialTurnOffFadeTime = self.turnOffFadeTime
		self.turnOnOffVariance = self.turnOnOffVariance * 1000
	end

	local speedFuncStr = xmlFile:getValue(key .. "#speedFunc")

	if speedFuncStr ~= nil then
		if owner[speedFuncStr] ~= nil then
			self.speedFunc = owner[speedFuncStr]
			self.speedFuncTarget = self.owner
		else
			Logging.xmlWarning(xmlFile, "Could not find speed function '%s' for rotation animation '%s'!", speedFuncStr, key)
		end
	end

	self.minAlphaForTurnOff = xmlFile:getValue(key .. "#minAlphaForTurnOff", 0)
	self.delayedTurnOff = false
	self.turnedOffRotation = xmlFile:getValue(key .. "#turnedOffRotation")

	if self.turnedOffRotation ~= nil then
		self.turnOffFadeTimeOrigin = self.turnOffFadeTime
		self.turnedOffSubDivisions = xmlFile:getValue(key .. "#turnedOffSubDivisions", 1)

		if self.shaderParameterName == nil then
			if self.rotAxis == 2 then
				setRotation(self.node, 0, self.turnedOffRotation, 0)
			elseif self.rotAxis == 1 then
				setRotation(self.node, self.turnedOffRotation, 0, 0)
			else
				setRotation(self.node, 0, 0, self.turnedOffRotation)
			end
		end
	end

	return self
end

function RotationAnimation:update(dt)
	RotationAnimation:superClass().update(self, dt)

	if self.state == RotationAnimation.STATE_ON then
		self.currentAlpha = math.min(1, self.currentAlpha + dt / self.turnOnFadeTime)
	elseif self.state == RotationAnimation.STATE_TURNING_OFF then
		self.currentAlpha = math.max(0, self.currentAlpha - dt / self.turnOffFadeTime)
	end

	if self.currentAlpha > 0 then
		local speedFactor = self.speedFunc(self.speedFuncTarget)
		local rot = self.currentAlpha * dt * self.rotSpeed * speedFactor

		if self.shaderParameterName == nil then
			if self.rotAxis == 2 then
				rotate(self.node, 0, rot, 0)
			elseif self.rotAxis == 1 then
				rotate(self.node, rot, 0, 0)
			else
				rotate(self.node, 0, 0, rot)
			end

			self.currentRot = self.currentRot + rot
		else
			self.currentRot = self.currentRot + rot

			if self.shaderParameterPrevName ~= nil then
				g_animationManager:setPrevShaderParameter(self.node, self.shaderParameterName, self.currentRot * self.shaderComponentScale[1], self.currentRot * self.shaderComponentScale[2], self.currentRot * self.shaderComponentScale[3], self.currentRot * self.shaderComponentScale[4], false, self.shaderParameterPrevName)
			else
				setShaderParameter(self.node, self.shaderParameterName, self.currentRot * self.shaderComponentScale[1], self.currentRot * self.shaderComponentScale[2], self.currentRot * self.shaderComponentScale[3], self.currentRot * self.shaderComponentScale[4], false)
			end
		end

		if self.owner ~= nil and self.owner.setMovingToolDirty ~= nil then
			self.owner:setMovingToolDirty(self.node)
		end
	else
		self.state = RotationAnimation.STATE_OFF
	end

	if self.delayedTurnOff and self.minAlphaForTurnOff <= self.currentAlpha then
		self.delayedTurnOff = false

		self:stop()
	end

	self:updateDuplicates()
end

function RotationAnimation:isRunning()
	return self.state ~= RotationAnimation.STATE_OFF
end

function RotationAnimation:start()
	if self.state ~= RotationAnimation.STATE_ON then
		if self.state == RotationAnimation.STATE_OFF and self.turnOnOffVariance ~= nil and self.currentAlpha == 0 then
			self.turnOnFadeTime = self.initialTurnOnFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
			self.turnOffFadeTime = self.initialTurnOffFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
		end

		self.state = RotationAnimation.STATE_ON

		self:updateDuplicates()

		return true
	end

	return false
end

function RotationAnimation:stop()
	if self.state ~= RotationAnimation.STATE_OFF then
		if self.minAlphaForTurnOff > 0 and self.currentAlpha < self.minAlphaForTurnOff then
			self.delayedTurnOff = true
			self.state = RotationAnimation.STATE_ON

			return true
		end

		self.state = RotationAnimation.STATE_TURNING_OFF

		self:updateDuplicates()

		if self.turnedOffRotation ~= nil then
			local rotation = {
				getRotation(self.node)
			}
			local currentRot = rotation[self.rotAxis]
			local speedFactor = self.speedFunc(self.speedFuncTarget)
			self.turnOffFadeTime = Animation.calculateTurnOffFadeTime(self.currentAlpha, self.rotSpeed * speedFactor, MathUtil.sign(self.rotSpeed), currentRot, self.turnedOffRotation, self.turnOffFadeTimeOrigin, 2 * math.pi, self.turnedOffSubDivisions)
		end

		return true
	end

	return false
end

function RotationAnimation:reset()
	self.currentAlpha = 0
	self.state = RotationAnimation.STATE_OFF

	self:updateDuplicates()
end

function RotationAnimation:isDuplicate(otherAnimation)
	if otherAnimation:isa(RotationAnimation) and self.parent == otherAnimation.parent and self.node == otherAnimation.node then
		return true
	end

	return false
end

function RotationAnimation:updateDuplicate(otherAnimation)
	otherAnimation.currentAlpha = self.currentAlpha
	otherAnimation.currentRot = self.currentRot
	otherAnimation.state = self.state
end

function RotationAnimation.registerAnimationClassXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Node")
	schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Shader parameter name")
	schema:register(XMLValueType.VECTOR_4, basePath .. "#shaderComponentScale", "Shader parameter name", "1 0 0 0")
	schema:register(XMLValueType.ANGLE, basePath .. "#rotSpeed", "Rotation speed", 1)
	schema:register(XMLValueType.ANGLE, basePath .. "#turnedOffRotation", "(RotationAnimation) Target rotation while turned off")
	schema:register(XMLValueType.FLOAT, basePath .. "#minAlphaForTurnOff", "Min. alpha for turn off (speed [0-1])", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnedOffSubDivisions", "Amount of sub divisions which have the same state", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#rotAxis", "Rotation axis", 2)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnFadeTime", "Turn on fade time", 2)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOffFadeTime", "Turn off fade time", 2)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnOffVariance", "Turn off time variance")
	schema:register(XMLValueType.STRING, basePath .. "#speedFunc", "Lua speed function")
end
