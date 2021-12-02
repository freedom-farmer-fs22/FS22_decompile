CultivatorMotionPathEffect = {}
local CultivatorMotionPathEffect_mt = Class(CultivatorMotionPathEffect, TypedMotionPathEffect)

function CultivatorMotionPathEffect.new(customMt)
	local self = TypedMotionPathEffect.new(customMt or CultivatorMotionPathEffect_mt)
	self.shapeVariationStateDelay = ValueDelay.new(500)
	self.shapeVariationStateSmoothed = 0
	self.densityScale = math.random(75, 100) * 0.01

	return self
end

function CultivatorMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not CultivatorMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.isCultivatorSweepEffect = xmlFile:getValue(key .. ".motionPathEffect#isCultivatorSweepEffect", false)
	self.minDensity = 0.4
	self.maxDensitySpeed = 4

	if self.isCultivatorSweepEffect then
		self.minDensity = 0
		self.maxDensitySpeed = 10
	end

	self.minDensity = xmlFile:getValue(key .. ".motionPathEffect#minDensity", self.minDensity)
	self.maxDensitySpeed = xmlFile:getValue(key .. ".motionPathEffect#maxDensitySpeed", self.maxDensitySpeed)
	self.densityScale = xmlFile:getValue(key .. ".motionPathEffect#densityScale", self.densityScale)
	self.maxVariationState = xmlFile:getValue(key .. ".motionPathEffect#maxVariationState", 1)

	return true
end

function CultivatorMotionPathEffect:update(dt)
	local lastSpeed = self.parent:getLastSpeed()

	if self.isCultivatorSweepEffect then
		if self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON then
			local variationState = MathUtil.clamp((lastSpeed - 5) / 10, 0, 1)
			self.effectSpeedScale = self.effectSpeedScaleOrig * (0.5 + variationState * 0.5)
		end
	else
		local speedScale = MathUtil.clamp(lastSpeed / 10, 0, 1)
		self.effectSpeedScale = self.effectSpeedScaleOrig * (0.5 + speedScale * 0.5)
	end

	if self.state == MotionPathEffect.STATE_ON and lastSpeed < 1 then
		g_effectManager:stopEffect(self)
	end

	if self.state == MotionPathEffect.STATE_TURNING_OFF then
		self.effectSpeedScale = self.effectSpeedScaleOrig * MathUtil.clamp(lastSpeed / 10, 0.4, 1)
		local x, y, z = getTranslation(self.effectNode)
		y = y - dt * 0.001

		setTranslation(self.effectNode, x, y, z)

		if y < -0.5 then
			self.fadeIn = self.minFade
			self.fadeOut = self.minFade
			self.state = MotionPathEffect.STATE_OFF

			setTranslation(self.effectNode, 0, 0, 0)
		end
	else
		setTranslation(self.effectNode, 0, 0, 0)
	end

	CultivatorMotionPathEffect:superClass().update(self, dt)

	if self.currentEffectNode ~= nil then
		if self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON then
			local density = math.min(lastSpeed / self.maxDensitySpeed, 1) * (1 - self.minDensity) + self.minDensity

			self:setDensity(density * self.densityScale)

			local variationMin = 0
			local variationMax = 0
			local variationAlpha = 0

			if self.isCultivatorSweepEffect then
				local variationState = MathUtil.clamp((lastSpeed - 5) / 10, 0, self.maxVariationState)
				self.shapeVariationStateSmoothed = self.shapeVariationStateSmoothed * 0.985 + variationState * 0.015
				variationMin = math.floor(self.shapeVariationStateSmoothed * 2)
				variationMax = math.floor(self.shapeVariationStateSmoothed * 2 + 1)
				variationAlpha = self.shapeVariationStateSmoothed * 2 % 1
			end

			self.motionPathEffectManager:setEffectShaderParameter(self.currentEffectNode, "scrollPosition", nil, variationMin, variationMax, variationAlpha, false)
		end

		if self.state == MotionPathEffect.STATE_OFF then
			self.shapeVariationStateDelay:reset()

			self.shapeVariationStateSmoothed = 0
		end
	end
end

function CultivatorMotionPathEffect:stop()
	return CultivatorMotionPathEffect:superClass().stop(self)
end

function CultivatorMotionPathEffect:reset()
	return CultivatorMotionPathEffect:superClass().reset(self)
end

function CultivatorMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
end

function CultivatorMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
end

function CultivatorMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
end

function CultivatorMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
end

function CultivatorMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
end

function CultivatorMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
end

function CultivatorMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. ".motionPathEffect#isCultivatorSweepEffect", "(CultivatorMotionPathEffect) Is sweep effect", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#minDensity", "(CultivatorMotionPathEffect) Min. Density", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#maxDensitySpeed", "(CultivatorMotionPathEffect) Speed at which the density is 1", 8)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#densityScale", "(CultivatorMotionPathEffect) Density Scale", "Random between 0.75 and 1")
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#maxVariationState", "(CultivatorMotionPathEffect) Max. variation state", "Max state of variation depending on speed (0 -> slow, 0.5 -> normal, 1 -> fast)")
end
