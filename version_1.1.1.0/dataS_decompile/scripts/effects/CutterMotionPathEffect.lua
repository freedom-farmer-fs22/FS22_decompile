CutterMotionPathEffect = {
	DEFAULT_FOLIAGE_CLIP_DISTANCE = 80
}
local CutterMotionPathEffect_mt = Class(CutterMotionPathEffect, TypedMotionPathEffect)

function CutterMotionPathEffect.new(customMt)
	local self = TypedMotionPathEffect.new(customMt or CutterMotionPathEffect_mt)
	self.minValue = 0
	self.maxValue = 0
	self.minValueDelay = ValueDelay.new(400, -1)
	self.maxValueDelay = ValueDelay.new(400, -1)
	self.effectMinValue = 0
	self.effectMaxValue = 0

	return self
end

function CutterMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not CutterMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.useMaxValue = xmlFile:getValue(key .. "#useMaxValue", false)
	self.widthScale = xmlFile:getValue(key .. "#widthScale", 1)
	self.offset = xmlFile:getValue(key .. "#offset", 0)
	self.minOffset = xmlFile:getValue(key .. "#minOffset", 0)
	self.maxOffset = xmlFile:getValue(key .. "#maxOffset", 0)
	self.minDensity = xmlFile:getValue(key .. "#minDensity", 0.25)
	self.maxDensitySpeed = xmlFile:getValue(key .. "#maxDensitySpeed", 8)

	setClipDistance(self.effectNode, CutterMotionPathEffect.DEFAULT_FOLIAGE_CLIP_DISTANCE * getFoliageViewDistanceCoeff())

	return true
end

function CutterMotionPathEffect:update(dt)
	CutterMotionPathEffect:superClass().update(self, dt)

	if self.currentEffectNode ~= nil then
		local minValue = 0.5 - (self.minOffset + self.effectMinValue) * 0.5
		local maxValue = 0.5 + (self.maxOffset + self.effectMaxValue) * 0.5

		self.motionPathEffectManager:setEffectShaderParameter(self.currentEffectNode, "fadeProgress", self.fadeIn, self.fadeOut, maxValue, minValue, false)

		if self.state == MotionPathEffect.STATE_TURNING_ON or self.state == MotionPathEffect.STATE_ON then
			local speed = self.parent:getLastSpeed()
			local density = math.min(speed / self.maxDensitySpeed, 1) * (1 - self.minDensity) + self.minDensity

			self:setDensity(density)
		end
	end
end

function CutterMotionPathEffect:stop()
	self.minValueDelay:reset()
	self.maxValueDelay:reset()

	return CutterMotionPathEffect:superClass().stop(self)
end

function CutterMotionPathEffect:reset()
	self.effectMinValue = 0
	self.effectMaxValue = 0

	return CutterMotionPathEffect:superClass().reset(self)
end

function CutterMotionPathEffect:setMinMaxWidth(minWidth, maxWidth, minWidthNorm, maxWidthNorm, reset)
	if minWidthNorm ~= 0 or maxWidthNorm ~= 0 then
		if self.textureRealWidth ~= nil then
			minWidthNorm = -minWidth / self.textureRealWidth * 2
			maxWidthNorm = maxWidth / self.textureRealWidth * 2
		end

		minWidthNorm = minWidthNorm + 1
		maxWidthNorm = 2 - maxWidthNorm + 1
		minWidthNorm = self.minValueDelay:add(minWidthNorm)
		maxWidthNorm = self.maxValueDelay:add(maxWidthNorm)
		minWidthNorm = minWidthNorm - 1
		maxWidthNorm = 2 - maxWidthNorm + 1
		self.effectMinValue = minWidthNorm * self.widthScale - self.offset
		self.effectMaxValue = maxWidthNorm * self.widthScale + self.offset
	else
		self.minValueDelay:reset()
		self.maxValueDelay:reset()
	end
end

function CutterMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
end

function CutterMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
end

function CutterMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
end

function CutterMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
end

function CutterMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
end

function CutterMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
end

function CutterMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#useMaxValue", "(CutterMotionPathEffect) Use max width of effect", false)
	schema:register(XMLValueType.FLOAT, basePath .. "#widthScale", "(CutterMotionPathEffect) Width scale (Percentage)", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#offset", "(CutterMotionPathEffect) Width offset (Percentage)", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#minOffset", "(CutterMotionPathEffect) Width offset in min direction", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxOffset", "(CutterMotionPathEffect) Width offset in max direction", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#minDensity", "(CutterMotionPathEffect) Min. Density", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxDensitySpeed", "(CutterMotionPathEffect) Speed at which the density is 1", 8)
end
