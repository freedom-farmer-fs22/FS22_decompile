EffectManager = {}
local EffectManager_mt = Class(EffectManager, AbstractManager)

function EffectManager.new(customMt)
	local self = AbstractManager.new(customMt or EffectManager_mt)

	return self
end

function EffectManager:initDataStructures()
	self.runningEffects = {}
	self.registeredEffectClasses = {}
	self.delayedCommands = {}
	self.validCommands = 0
end

function EffectManager:loadEffect(xmlFile, baseName, rootNode, parent, i3dMapping)
	local effects = {}
	local i = 0

	while true do
		local key = string.format(baseName .. ".effectNode(%d)", i)

		if not xmlFile:hasProperty(key) then
			break
		end

		local effectClassName = xmlFile:getValue(key .. "#effectClass", "ShaderPlaneEffect")
		local effectClass = self:getEffectClass(effectClassName)

		if effectClass == nil then
			if parent.customEnvironment ~= nil and parent.customEnvironment ~= "" then
				effectClass = self:getEffectClass(parent.customEnvironment .. "." .. effectClassName)
			end

			if effectClass == nil then
				effectClass = ClassUtil.getClassObject(effectClassName)
			end
		end

		if effectClass ~= nil then
			local effect = effectClass.new()

			if effect ~= nil then
				table.insert(effects, effect:load(xmlFile, key, rootNode, parent, i3dMapping))
			end
		else
			print("Warning: Unkown effect '" .. effectClassName .. "' in '" .. Utils.getNoNil(parent.configFileName, parent.xmlFilename) .. "'")
		end

		i = i + 1
	end

	return effects
end

function EffectManager:loadFromNode(node, parent)
	local effects = {}

	for i = 0, getNumOfChildren(node) - 1 do
		local child = getChildAt(node, i)
		local effectClassName = Utils.getNoNil(getUserAttribute(child, "effectClass"), "ShaderPlaneEffect")
		local effectClass = self:getEffectClass(effectClassName)

		if effectClass == nil then
			if parent.customEnvironment ~= nil and parent.customEnvironment ~= "" then
				effectClass = self:getEffectClass(parent.customEnvironment .. "." .. effectClassName)
			end

			if effectClass == nil then
				effectClass = ClassUtil.getClassObject(effectClassName)
			end
		end

		if effectClass ~= nil then
			local effect = effectClass.new()

			if effect ~= nil then
				table.insert(effects, effect:loadFromNode(child, parent))
			end
		else
			print("Warning: Unkown effect '" .. effectClassName .. "' in '" .. getName(node) .. "'")
		end
	end

	return effects
end

function EffectManager:registerEffectClass(className, effectClass)
	if not ClassUtil.getIsValidClassName(className) then
		print("Error: Invalid effect class name: " .. className)

		return
	end

	self.registeredEffectClasses[className] = effectClass
end

function EffectManager:getEffectClass(className)
	return self.registeredEffectClasses[className]
end

function EffectManager:deleteEffects(effects)
	if effects ~= nil then
		for _, effect in pairs(effects) do
			self.runningEffects[effect] = nil

			effect:delete()

			for i = 1, #self.delayedCommands do
				local commandSlot = self.delayedCommands[i]

				if commandSlot.isValid and commandSlot.arg1 == effect then
					commandSlot.isValid = false
				end
			end
		end
	end
end

function EffectManager:update(dt)
	for index, effect in pairs(self.runningEffects) do
		effect:update(dt)

		if not effect:isRunning() then
			self.runningEffects[index] = nil
		end
	end

	if self.validCommands > 0 then
		for i = 1, #self.delayedCommands do
			local commandSlot = self.delayedCommands[i]

			if commandSlot.isValid then
				commandSlot.delay = commandSlot.delay - dt

				if commandSlot.delay <= 0 then
					commandSlot.func(self, commandSlot.arg1, commandSlot.arg2)

					commandSlot.isValid = false
					self.validCommands = self.validCommands - 1
				end
			end
		end
	end
end

function EffectManager:addDelayedCommand(func, arg1, arg2, delay)
	local slotToUse = nil

	for i = 1, #self.delayedCommands do
		local commandSlot = self.delayedCommands[i]

		if not commandSlot.isValid then
			slotToUse = commandSlot
		end
	end

	if slotToUse == nil then
		slotToUse = {
			isValid = true,
			func = func,
			arg1 = arg1,
			arg2 = arg2,
			delay = delay
		}

		table.insert(self.delayedCommands, slotToUse)
	else
		slotToUse.func = func
		slotToUse.arg1 = arg1
		slotToUse.arg2 = arg2
		slotToUse.delay = delay
		slotToUse.isValid = true
	end

	self.validCommands = self.validCommands + 1
end

function EffectManager:startEffects(effects)
	if effects ~= nil then
		for _, effect in pairs(effects) do
			self:startEffect(effect)
		end
	end
end

function EffectManager:startEffect(effect, skipDelay)
	if effect ~= nil then
		local success, delay = effect:start(skipDelay)

		if success then
			self.runningEffects[effect] = effect
		elseif delay ~= nil then
			self:addDelayedCommand(self.startEffect, effect, true, delay)
		end
	end
end

function EffectManager:stopEffects(effects)
	if effects ~= nil then
		for _, effect in pairs(effects) do
			self:stopEffect(effect)
		end
	end
end

function EffectManager:stopEffect(effect, skipDelay)
	if effect ~= nil then
		local success, delay = effect:stop(skipDelay)

		if success then
			self.runningEffects[effect] = effect
		elseif delay ~= nil then
			self:addDelayedCommand(self.stopEffect, effect, true, delay)
		end
	end
end

function EffectManager:resetEffects(effects)
	if effects ~= nil then
		for _, effect in pairs(effects) do
			self:resetEffect(effect)
		end
	end
end

function EffectManager:resetEffect(effect)
	if effect ~= nil then
		self.runningEffects[effect] = nil

		effect:reset()
	end
end

function EffectManager:setFillType(effects, fillType, growthState)
	if effects ~= nil then
		for _, effect in pairs(effects) do
			if effect.setFillType ~= nil then
				effect:setFillType(fillType, growthState)
			end
		end
	end
end

function EffectManager:setFruitType(effects, fruitType, growthState)
	if effects ~= nil then
		for _, effect in pairs(effects) do
			if effect.setFruitType ~= nil then
				effect:setFruitType(fruitType, growthState)
			end
		end
	end
end

function EffectManager:setMinMaxWidth(effects, minWidth, maxWidth, minWidthNorm, maxWidthNorm, reset)
	if effects ~= nil then
		for _, effect in pairs(effects) do
			if effect.setMinMaxWidth ~= nil then
				effect:setMinMaxWidth(minWidth, maxWidth, minWidthNorm, maxWidthNorm, reset)
			end
		end
	end
end

function EffectManager:setDensity(effects, density)
	if effects ~= nil then
		for _, effect in pairs(effects) do
			if effect.setDensity ~= nil then
				effect:setDensity(density)
			end
		end
	end
end

function EffectManager.registerEffectXMLPaths(schema, basePath)
	schema:setXMLSharedRegistration("EffectNode", basePath)
	schema:register(XMLValueType.STRING, basePath .. ".effectNode(?)#effectClass", "Effect class", "ShaderPlaneEffect")
	Effect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	LevelerEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	MorphPositionEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	ParticleEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	PipeEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	ShaderPlaneEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	SlurrySideToSideEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	WindrowerEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	TipEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	GrainTankEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	CutterMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	CultivatorMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	PlowMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	WindrowerMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	FertilizerMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	SnowPlowMotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	MotionPathEffect.registerEffectXMLPaths(schema, basePath .. ".effectNode(?)")
	schema:setXMLSharedRegistration()
end

g_effectManager = EffectManager.new()
