ScrollingAnimation = {
	STATE_OFF = 0,
	STATE_ON = 1,
	STATE_TURNING_OFF = 2
}
local ScrollingAnimation_mt = Class(ScrollingAnimation, Animation)

function ScrollingAnimation.new(customMt)
	local self = Animation.new(customMt or ScrollingAnimation_mt)
	self.state = ScrollingAnimation.STATE_OFF
	self.node = nil
	self.shaderParameterName = nil
	self.scrollPosition = 0
	self.scrollSpeed = 0
	self.scrollLength = 1
	self.shaderParameterComponent = 1
	self.currentAlpha = 0
	self.initialTurnOnFadeTime = 1000
	self.turnOnOffVariance = nil
	self.turnOnFadeTime = 0
	self.turnOffFadeTime = 0
	self.owner = nil

	function self.speedFunc()
		return 1
	end

	self.speedFuncTarget = self

	return self
end

function ScrollingAnimation:load(xmlFile, key, rootNodes, owner, i3dMapping)
	if not xmlFile:hasProperty(key) then
		return nil
	end

	self.owner = owner
	self.node = xmlFile:getValue(key .. "#node", nil, rootNodes, i3dMapping)

	if self.node == nil then
		Logging.xmlWarning(xmlFile, "Missing node for scrolling animation '%s'!", key)

		return nil
	end

	self.shaderParameterName = xmlFile:getValue(key .. "#shaderParameterName", "offsetUV")
	self.shaderParameterPrevName = xmlFile:getValue(key .. "#shaderParameterPrevName")

	if not getHasShaderParameter(self.node, self.shaderParameterName) then
		Logging.xmlWarning(xmlFile, "Node '%s' has no shader parameter '%s' for animationNode '%s'!", getName(self.node), self.shaderParameterName, key)

		return nil
	end

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

	local fillTypeStr = xmlFile:getValue(key .. "#type")

	if fillTypeStr ~= nil then
		self.fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)
	end

	self.scrollSpeed = xmlFile:getValue(key .. "#scrollSpeed", 1) * 0.001
	self.scrollLength = xmlFile:getValue(key .. "#scrollLength", 1)
	self.shaderParameterComponent = xmlFile:getValue(key .. "#shaderParameterComponent", 1)
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
			Logging.xmlWarning(xmlFile, "Could not find speed function '%s' for scrolling animation '%s'!", speedFuncStr, key)
		end
	end

	self.minAlphaForTurnOff = xmlFile:getValue(key .. "#minAlphaForTurnOff", 0)
	self.delayedTurnOff = false
	self.turnedOffPosition = xmlFile:getValue(key .. "#turnedOffPosition")

	if self.turnedOffPosition ~= nil then
		self.turnOffFadeTimeOrigin = self.turnOffFadeTime
		self.turnedOffSubDivisions = xmlFile:getValue(key .. "#turnedOffSubDivisions", 1)
	end

	return self
end

function ScrollingAnimation:update(dt)
	ScrollingAnimation:superClass().update(self, dt)

	if self.state == ScrollingAnimation.STATE_ON then
		self.currentAlpha = math.min(1, self.currentAlpha + dt / self.turnOnFadeTime)
	elseif self.state == ScrollingAnimation.STATE_TURNING_OFF then
		self.currentAlpha = math.max(0, self.currentAlpha - dt / self.turnOffFadeTime)
	end

	if self.currentAlpha > 0 then
		local speedFactor = self.speedFunc(self.speedFuncTarget)
		local x, y, z, w = getShaderParameter(self.node, self.shaderParameterName)

		if self.shaderParameterComponent == 1 then
			x = self:updateScrollPosition(x, dt, speedFactor)
		elseif self.shaderParameterComponent == 2 then
			y = self:updateScrollPosition(y, dt, speedFactor)
		elseif self.shaderParameterComponent == 3 then
			z = self:updateScrollPosition(z, dt, speedFactor)
		else
			w = self:updateScrollPosition(w, dt, speedFactor)
		end

		if self.shaderParameterPrevName ~= nil then
			g_animationManager:setPrevShaderParameter(self.node, self.shaderParameterName, x, y, z, w, false, self.shaderParameterPrevName)
		else
			setShaderParameter(self.node, self.shaderParameterName, x, y, z, w, false)
		end

		if self.owner ~= nil and self.owner.setMovingToolDirty ~= nil then
			self.owner:setMovingToolDirty(self.node)
		end
	else
		self.state = ScrollingAnimation.STATE_OFF
	end

	if self.delayedTurnOff and self.minAlphaForTurnOff <= self.currentAlpha then
		self.delayedTurnOff = false

		self:stop()
	end

	self:updateDuplicates()
end

function ScrollingAnimation:isRunning()
	return self.state ~= ScrollingAnimation.STATE_OFF
end

function ScrollingAnimation:start()
	if self.state ~= ScrollingAnimation.STATE_ON then
		if self.state == ScrollingAnimation.STATE_OFF and self.turnOnOffVariance ~= nil and self.currentAlpha == 0 then
			self.turnOnFadeTime = self.initialTurnOnFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
			self.turnOffFadeTime = self.initialTurnOffFadeTime + math.random(-self.turnOnOffVariance, self.turnOnOffVariance)
		end

		self.state = ScrollingAnimation.STATE_ON

		self:updateDuplicates()

		return true
	end

	return false
end

function ScrollingAnimation:stop()
	if self.state ~= ScrollingAnimation.STATE_OFF then
		if self.minAlphaForTurnOff > 0 and self.currentAlpha < self.minAlphaForTurnOff then
			self.delayedTurnOff = true
			self.state = RotationAnimation.STATE_ON

			return true
		end

		self.state = ScrollingAnimation.STATE_TURNING_OFF

		self:updateDuplicates()

		if self.turnedOffPosition ~= nil then
			local speedFactor = self.speedFunc(self.speedFuncTarget)
			local x, y, z, w = getShaderParameter(self.node, self.shaderParameterName)
			local scrollPosition = w

			if self.shaderParameterComponent == 1 then
				scrollPosition = x
			elseif self.shaderParameterComponent == 2 then
				scrollPosition = y
			elseif self.shaderParameterComponent == 3 then
				scrollPosition = z
			end

			self.turnOffFadeTime = Animation.calculateTurnOffFadeTime(self.currentAlpha, self.scrollSpeed * speedFactor, MathUtil.sign(self.scrollSpeed), scrollPosition, self.turnedOffPosition, self.turnOffFadeTimeOrigin, self.scrollLength, self.turnedOffSubDivisions)
		end

		return true
	end

	return false
end

function ScrollingAnimation:reset()
	self.currentAlpha = 0
	self.state = ScrollingAnimation.STATE_OFF

	self:updateDuplicates()
end

function ScrollingAnimation:setFillType(fillTypeIndex)
	if self.fillTypeIndex ~= nil then
		setVisibility(self.node, self.fillTypeIndex == fillTypeIndex)
	end
end

function ScrollingAnimation:updateScrollPosition(scrollPosition, dt, speedFactor)
	return (scrollPosition + self.currentAlpha * dt * self.scrollSpeed * speedFactor) % self.scrollLength
end

function ScrollingAnimation:isDuplicate(otherAnimation)
	if otherAnimation:isa(ScrollingAnimation) and self.parent == otherAnimation.parent and self.node == otherAnimation.node then
		return true
	end

	return false
end

function ScrollingAnimation:updateDuplicate(otherAnimation)
	otherAnimation.currentAlpha = self.currentAlpha
	otherAnimation.state = self.state
end

function ScrollingAnimation.registerAnimationClassXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Node")
	schema:register(XMLValueType.STRING, basePath .. "#shaderParameterName", "Shader parameter name")
	schema:register(XMLValueType.STRING, basePath .. "#shaderParameterPrevName", "Prev Shader parameter name", "automatically calculated from #shaderParameterName")
	schema:register(XMLValueType.STRING, basePath .. "#type", "(ScrollingAnimation) Fill type name")
	schema:register(XMLValueType.FLOAT, basePath .. "#scrollSpeed", "(ScrollingAnimation) Scroll speed", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#scrollLength", "(ScrollingAnimation) Scroll length", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#shaderParameterComponent", "(ScrollingAnimation) Shader parameter component", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnFadeTime", "Turn on fade time", 2)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOffFadeTime", "Turn off fade time", 2)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnOffVariance", "Turn off time variance")
	schema:register(XMLValueType.FLOAT, basePath .. "#turnedOffPosition", "(ScrollingAnimation) Target position while turned off")
	schema:register(XMLValueType.FLOAT, basePath .. "#turnedOffSubDivisions", "Amount of sub divisions which have the same state", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#minAlphaForTurnOff", "Min. alpha for turn off (speed [0-1])", 0)
	schema:register(XMLValueType.STRING, basePath .. "#speedFunc", "Lua speed function")
end
