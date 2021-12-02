SlurrySideToSideEffect = {}
local SlurrySideToSideEffect_mt = Class(SlurrySideToSideEffect, ShaderPlaneEffect)

function SlurrySideToSideEffect.new(customMt)
	if customMt == nil then
		customMt = SlurrySideToSideEffect_mt
	end

	local self = ShaderPlaneEffect.new(customMt)

	return self
end

function SlurrySideToSideEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not SlurrySideToSideEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.refAnimation = Effect.getValue(xmlFile, key, node, "refAnimation")
	self.offset = Effect.getValue(xmlFile, key, node, "offset", 0.5)

	return true
end

function SlurrySideToSideEffect:update(dt)
	SlurrySideToSideEffect:superClass().update(self, dt)

	local z = (self.parent:getAnimationTime(self.refAnimation) + self.offset) % 1

	setShaderParameter(self.node, "fadeProgress", self.fadeCur[1], self.fadeCur[2], z, 0, false)
end

function SlurrySideToSideEffect:isRunning()
	return SlurrySideToSideEffect:superClass().isRunning(self) or self.state == ShaderPlaneEffect.STATE_ON
end

function SlurrySideToSideEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. "#refAnimation", "(SlurrySideToSideEffect) Reference animation")
	schema:register(XMLValueType.FLOAT, basePath .. "#offset", "(SlurrySideToSideEffect) Animation time offset", 0.5)
end
