SnowPlowMotionPathEffect = {}
local SnowPlowMotionPathEffect_mt = Class(SnowPlowMotionPathEffect, TypedMotionPathEffect)
SnowPlowMotionPathEffect.Y_OFFSET = 0.75

function SnowPlowMotionPathEffect.new(customMt)
	local self = TypedMotionPathEffect.new(customMt or SnowPlowMotionPathEffect_mt)
	self.fillLevelPct = 0
	self.lastSpeed = 0

	return self
end

function SnowPlowMotionPathEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not SnowPlowMotionPathEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.shaderPlaneNode = xmlFile:getValue(key .. ".snowPlowEffect#shaderPlane", nil, self.rootNodes, i3dMapping)
	self.shaderPlaneMinScale = xmlFile:getValue(key .. ".snowPlowEffect#minScale", {
		1,
		1,
		1
	}, true)
	self.shaderPlaneMaxScale = xmlFile:getValue(key .. ".snowPlowEffect#maxScale", {
		1,
		1,
		1
	}, true)
	self.shaderPlaneScrollSpeed = xmlFile:getValue(key .. ".snowPlowEffect#scrollSpeed", 1) * 0.001
	self.shaderPlaneScrollTime = 0

	if self.shaderPlaneNode ~= nil then
		local x, y, z = localToLocal(self.shaderPlaneNode, self.effectNode, 0, 0, 0)
		local rx, ry, rz = localRotationToLocal(self.shaderPlaneNode, self.effectNode, 0, 0, 0)

		link(self.effectNode, self.shaderPlaneNode)
		setTranslation(self.shaderPlaneNode, x, y, z)
		setRotation(self.shaderPlaneNode, rx, ry, rz)
	end

	setTranslation(self.effectNode, 0, -SnowPlowMotionPathEffect.Y_OFFSET, 0)

	return true
end

function SnowPlowMotionPathEffect:update(dt)
	self.fadeIn = 1
	self.fadeOut = 0

	if self.currentEffectNode ~= nil then
		local activeState = self.fillLevelPct > 0.005 and self.lastSpeed > 0.1
		local alpha = MathUtil.clamp(self.lastSpeed / 20, 0.1, 1)

		if self.state ~= MotionPathEffect.STATE_OFF then
			self.motionPathEffectManager:setEffectShaderParameter(self.currentEffectNode, "scrollPosition", nil, 0, 1, alpha, false)

			if self.shaderPlaneNode ~= nil then
				local sx, sy, sz = MathUtil.lerp3(self.shaderPlaneMinScale[1], self.shaderPlaneMinScale[2], self.shaderPlaneMinScale[3], self.shaderPlaneMaxScale[1], self.shaderPlaneMaxScale[2], self.shaderPlaneMaxScale[3], alpha)

				setScale(self.shaderPlaneNode, sx, sy, sz)

				self.shaderPlaneScrollTime = self.shaderPlaneScrollTime + self.shaderPlaneScrollSpeed * dt * self.effectSpeedScale

				setShaderParameter(self.shaderPlaneNode, "offsetUV", self.shaderPlaneScrollTime, 0, 0, 0, false)
				setShaderParameter(self.shaderPlaneNode, "VertxoffsetVertexdeformMotionUVscale", -35, 1, self.shaderPlaneScrollTime, 6, false)
			end
		end

		if activeState then
			self.effectSpeedScale = self.effectSpeedScaleOrig * math.max(alpha, 0.3)
			local x, y, z = getTranslation(self.effectNode)
			y = math.min(y + dt * 0.001, 0)
			local wx, wy, wz = getWorldTranslation(self.effectNode)
			local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx, wy, wz) - 0.5
			local _, minY, _ = worldToLocal(getParent(self.effectNode), wx, terrainHeight, wz)
			y = math.max(y, minY)

			setTranslation(self.effectNode, x, y, z)
			setVisibility(self.effectNode, y > -SnowPlowMotionPathEffect.Y_OFFSET)
		else
			self.effectSpeedScale = self.effectSpeedScaleOrig * 0.5
			local x, y, z = getTranslation(self.effectNode)
			y = math.max(y - dt * 0.001, -SnowPlowMotionPathEffect.Y_OFFSET)

			setTranslation(self.effectNode, x, y, z)
			setVisibility(self.effectNode, y > -SnowPlowMotionPathEffect.Y_OFFSET)
		end
	end

	SnowPlowMotionPathEffect:superClass().update(self, dt)
end

function SnowPlowMotionPathEffect:setFillLevel(fillLevelPct)
	self.fillLevelPct = fillLevelPct
end

function SnowPlowMotionPathEffect:setLastVehicleSpeed(lastSpeed)
	self.lastSpeed = lastSpeed
end

function SnowPlowMotionPathEffect:stop()
	return SnowPlowMotionPathEffect:superClass().stop(self)
end

function SnowPlowMotionPathEffect:reset()
	return SnowPlowMotionPathEffect:superClass().reset(self)
end

function SnowPlowMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
	TypedMotionPathEffect.loadEffectDefinitionFromXML(motionPathEffect, xmlFile, key)
end

function SnowPlowMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
	TypedMotionPathEffect.loadEffectMeshFromXML(effectMesh, xmlFile, key)
end

function SnowPlowMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
	TypedMotionPathEffect.loadEffectMaterialFromXML(effectMaterial, xmlFile, key)
end

function SnowPlowMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectDefinitionXMLPaths(schema, basePath)
end

function SnowPlowMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMeshXMLPaths(schema, basePath)
end

function SnowPlowMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectMaterialXMLPaths(schema, basePath)
end

function SnowPlowMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	TypedMotionPathEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".snowPlowEffect#shaderPlane", "(SnowPlowMotionPathEffect) Node of shader plane effect to control the same way")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".snowPlowEffect#minScale", "(SnowPlowMotionPathEffect) Min. Scale which corresponds to the first motion path array state", "1 1 1")
	schema:register(XMLValueType.VECTOR_SCALE, basePath .. ".snowPlowEffect#maxScale", "(SnowPlowMotionPathEffect) Max. Scale which corresponds to the second motion path array state", "1 1 1")
	schema:register(XMLValueType.FLOAT, basePath .. ".snowPlowEffect#scrollSpeed", "(SnowPlowMotionPathEffect) UV scroll speed", 1)
end
