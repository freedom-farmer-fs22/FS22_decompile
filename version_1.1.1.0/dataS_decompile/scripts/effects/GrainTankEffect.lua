GrainTankEffect = {}
local GrainTankEffect_mt = Class(GrainTankEffect, ShaderPlaneEffect)

function GrainTankEffect.new(customMt)
	if customMt == nil then
		customMt = GrainTankEffect_mt
	end

	local self = ShaderPlaneEffect.new(customMt)

	return self
end

function GrainTankEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not GrainTankEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.minVisHeight = Effect.getValue(xmlFile, key, node, "minVisHeight", -math.huge)
	self.maxVisHeight = Effect.getValue(xmlFile, key, node, "maxVisHeight", math.huge)

	return true
end

function GrainTankEffect:update(dt)
	GrainTankEffect:superClass().update(self, dt)

	local _, y, _ = getTranslation(self.node)

	setVisibility(self.node, self.minVisHeight < y and y < self.maxVisHeight)
end

function GrainTankEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#minVisHeight", "(GrainTankEffect) Min. height to bis visibile", "-inf")
	schema:register(XMLValueType.FLOAT, basePath .. "#maxVisHeight", "(GrainTankEffect) Max. height to bis visibile", "inf")
end
