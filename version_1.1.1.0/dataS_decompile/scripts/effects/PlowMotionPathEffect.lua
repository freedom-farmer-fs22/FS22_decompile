PlowMotionPathEffect = {}
local PlowMotionPathEffect_mt = Class(PlowMotionPathEffect, TypedMotionPathEffect)

function PlowMotionPathEffect.new(customMt)
	local self = TypedMotionPathEffect.new(customMt or PlowMotionPathEffect_mt)
	self.useVehicleSpeed = true
	self.isReverseFadeOutMode = false

	return self
end

function PlowMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not PlowMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.fadeOutScale = 0.25
	self.maxScaleSpeed = xmlFile:getValue(key .. ".motionPathEffect#maxScaleSpeed", 10)
	self.minScaleOffset = xmlFile:getValue(key .. ".motionPathEffect#minScaleOffset", -0.07)

	return true
end

function PlowMotionPathEffect:update(dt)
	local lastSpeed = self.parent:getLastSpeed()
	local reverseFadeOut = self.parent.movingDirection < 0 and lastSpeed > 0.5 or self.isReverseFadeOutMode
	self.inversedFadeOut = self.fadeIn < 0.5 or reverseFadeOut

	if self.state ~= MotionPathEffect.STATE_OFF then
		self.fadeOutScale = lastSpeed < 2 and 0.25 or 1
		local x, _, z = getWorldTranslation(getParent(self.effectNode))
		local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
		local _, ly, _ = worldToLocal(getParent(self.effectNode), x, y, z)
		ly = math.min(ly, (1 - math.min(lastSpeed / self.maxScaleSpeed)) * self.minScaleOffset)
		ly = -((1 - ly)^2 - 1)

		if not reverseFadeOut then
			setTranslation(self.effectNode, 0, ly, 0)
		else
			if not self.isReverseFadeOutMode then
				self.isReverseFadeOutMode = true
			end

			x, y, z = getTranslation(self.effectNode)
			ly = math.min(y - dt * 0.0005, ly)

			setTranslation(self.effectNode, x, ly, z)

			self.fadeOutScale = 0.5
		end

		if ly < -1 then
			if self.state == MotionPathEffect.STATE_TURNING_OFF then
				self.state = MotionPathEffect.STATE_OFF
			end

			self.fadeIn = self.minFade
			self.fadeOut = self.minFade
			self.isReverseFadeOutMode = false
		end

		if self.isReverseFadeOutMode and self.parent:getLastSpeed() > 1 and self.parent.movingDirection > 0 then
			self.isReverseFadeOutMode = false
			self.fadeIn = self.minFade
			self.fadeOut = self.minFade
		end
	else
		setTranslation(self.effectNode, 0, 0, 0)

		self.fadeIn = self.minFade
		self.fadeOut = self.minFade
		self.isReverseFadeOutMode = false
	end

	PlowMotionPathEffect:superClass().update(self, dt)
end

function PlowMotionPathEffect:stop()
	return PlowMotionPathEffect:superClass().stop(self)
end

function PlowMotionPathEffect:reset()
	return PlowMotionPathEffect:superClass().reset(self)
end

function PlowMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
end

function PlowMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
end

function PlowMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
end

function PlowMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
end

function PlowMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
end

function PlowMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
end

function PlowMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#maxScaleSpeed", "(PlowMotionPathEffect) Speed at which the effect reaches the max. scale", 10)
	schema:register(XMLValueType.FLOAT, basePath .. ".motionPathEffect#minScaleOffset", "(PlowMotionPathEffect) Y Offset when the scale is at it's minimum", -0.07)
end
