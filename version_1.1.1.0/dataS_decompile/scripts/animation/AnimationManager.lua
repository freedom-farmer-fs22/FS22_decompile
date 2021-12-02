AnimationManager = {}
local AnimationManager_mt = Class(AnimationManager, AbstractManager)

function AnimationManager.new(customMt)
	local self = AbstractManager.new(customMt or AnimationManager_mt)

	return self
end

function AnimationManager:initDataStructures()
	self.runningAnimations = {}
	self.registeredAnimations = {}
	self.registeredAnimationClasses = {}
	self.prevShaderParametersToSet = {}
end

function AnimationManager:registerAnimationClass(className, animationClass)
	if not ClassUtil.getIsValidClassName(className) then
		print("Error: Invalid animation class name: " .. className)

		return
	end

	self.registeredAnimationClasses[className] = animationClass
end

function AnimationManager:getAnimationClass(className)
	return self.registeredAnimationClasses[className]
end

function AnimationManager:loadAnimations(xmlFile, baseName, rootNode, parent, i3dMapping)
	local animations = {}
	local i = 0

	while true do
		local key = string.format(baseName .. ".animationNode(%d)", i)

		if not xmlFile:hasProperty(key) then
			break
		end

		local animationClassName = xmlFile:getValue(key .. "#class") or "RotationAnimation"
		local animationClass = self:getAnimationClass(animationClassName)

		if animationClass == nil then
			if parent.customEnvironment ~= nil and parent.customEnvironment ~= "" then
				animationClass = self:getAnimationClass(parent.customEnvironment .. "." .. animationClassName)
			end

			if animationClass == nil then
				animationClass = ClassUtil.getClassObject(animationClassName)
			end
		end

		if animationClass ~= nil then
			local animation = animationClass.new()

			if animation ~= nil then
				local anim = animation:load(xmlFile, key, rootNode, parent, i3dMapping)

				if anim ~= nil then
					for j = 1, #self.registeredAnimations do
						local otherAnim = self.registeredAnimations[j]

						if anim:isDuplicate(otherAnim) then
							anim:addDuplicate(otherAnim)
							otherAnim:addDuplicate(anim)
						end
					end

					table.insert(animations, anim)
					table.insert(self.registeredAnimations, anim)
				end
			end
		else
			print("Warning: Unkown animation '" .. animationClassName .. "' in '" .. Utils.getNoNil(parent.configFileName, parent.xmlFilename) .. "'")
		end

		i = i + 1
	end

	return animations
end

function AnimationManager:deleteAnimations(animations)
	if animations ~= nil then
		for i = #animations, 1, -1 do
			local animation = animations[i]
			self.runningAnimations[animation] = nil

			animation:delete()
			table.remove(animations, i)
			table.removeElement(self.registeredAnimations, animation)
		end
	end
end

function AnimationManager:update(dt)
	for index, animation in pairs(self.runningAnimations) do
		animation:update(dt)

		if not animation:isRunning() then
			self.runningAnimations[index] = nil
		end
	end

	for i = 1, #self.prevShaderParametersToSet do
		local prevShaderParameterData = self.prevShaderParametersToSet[i]

		if prevShaderParameterData.isValid and prevShaderParameterData.loopIndex < g_updateLoopIndex then
			if entityExists(prevShaderParameterData.node) then
				setShaderParameter(prevShaderParameterData.node, prevShaderParameterData.parameterNamePrev, prevShaderParameterData.x, prevShaderParameterData.y, prevShaderParameterData.z, prevShaderParameterData.w, prevShaderParameterData.shared)
			end

			prevShaderParameterData.isValid = false
		end
	end
end

function AnimationManager:areAnimationsRunning(animations)
	if animations ~= nil then
		for _, animation in ipairs(animations) do
			if animation:isRunning() then
				return true
			end
		end
	end

	return false
end

function AnimationManager:startAnimations(animations)
	if animations ~= nil then
		for _, animation in ipairs(animations) do
			self:startAnimation(animation)
		end
	end
end

function AnimationManager:startAnimation(animation)
	if animation ~= nil and animation:start() then
		self.runningAnimations[animation] = animation
	end
end

function AnimationManager:stopAnimations(animations)
	if animations ~= nil then
		for _, animation in ipairs(animations) do
			self:stopAnimation(animation)
		end
	end
end

function AnimationManager:stopAnimation(animation)
	if animation.stop == nil then
		printCallstack()
	end

	if animation ~= nil and animation:stop() then
		self.runningAnimations[animation] = animation
	end
end

function AnimationManager:resetAnimations(animations)
	if animations ~= nil then
		for _, animation in ipairs(animations) do
			self:resetAnimation(animation)
		end
	end
end

function AnimationManager:resetAnimation(animation)
	if animation ~= nil then
		self.runningAnimations[animation] = nil

		animation:reset()
	end
end

function AnimationManager:setFillType(animations, fillType)
	if animations ~= nil then
		for _, animation in ipairs(animations) do
			if animation.setFillType ~= nil then
				animation:setFillType(fillType)
			end
		end
	end
end

function AnimationManager:setPrevShaderParameter(node, parameterName, x, y, z, w, shared, parameterNamePrev)
	setShaderParameter(node, parameterName, x, y, z, w, shared)

	local slot = nil

	for i = 1, #self.prevShaderParametersToSet do
		local prevShaderParameterData = self.prevShaderParametersToSet[i]

		if not prevShaderParameterData.isValid then
			slot = prevShaderParameterData
		end
	end

	if slot == nil then
		slot = {}

		table.insert(self.prevShaderParametersToSet, slot)
	end

	slot.node = node
	slot.parameterNamePrev = parameterNamePrev
	slot.x = x
	slot.y = y
	slot.z = z
	slot.w = w
	slot.shared = shared
	slot.isValid = true
	slot.loopIndex = g_updateLoopIndex
end

function AnimationManager.registerAnimationNodesXMLPaths(schema, basePath)
	schema:setXMLSharedRegistration("AnimationNode", basePath)
	schema:register(XMLValueType.STRING, basePath .. ".animationNode(?)#class", "Animation class (RotationAnimation | RotationAnimationSpikes | ScrollingAnimation | ShakeAnimation)", "RotationAnimation")
	RotationAnimation.registerAnimationClassXMLPaths(schema, basePath .. ".animationNode(?)")
	RotationAnimationSpikes.registerAnimationClassXMLPaths(schema, basePath .. ".animationNode(?)")
	ScrollingAnimation.registerAnimationClassXMLPaths(schema, basePath .. ".animationNode(?)")
	ShakeAnimation.registerAnimationClassXMLPaths(schema, basePath .. ".animationNode(?)")
	schema:setXMLSharedRegistration()
end

g_animationManager = AnimationManager.new()
