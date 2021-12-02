WindrowerEffect = {}
local WindrowerEffect_mt = Class(WindrowerEffect, MorphPositionEffect)

function WindrowerEffect.new(customMt)
	if customMt == nil then
		customMt = WindrowerEffect_mt
	end

	local self = MorphPositionEffect.new(customMt)

	return self
end

function WindrowerEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not WindrowerEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.unloadDirection = Effect.getValue(xmlFile, key, node, "unloadDirection", 0)
	self.width = Effect.getValue(xmlFile, key, node, "width", 0)
	self.dropOffset = Effect.getValue(xmlFile, key, node, "dropOffset", 0)
	self.turnOffRequiredEffect = Effect.getValue(xmlFile, key, node, "turnOffRequiredEffect", 0)
	self.testAreas = {}
	local i = 0

	while true do
		local areaKey = key .. string.format(".testArea(%d)", i)

		if not xmlFile:hasProperty(areaKey) then
			break
		end

		local start = xmlFile:getValue(areaKey .. "#startNode", nil, self.rootNodes, i3dMapping)
		local width = xmlFile:getValue(areaKey .. "#widthNode", nil, self.rootNodes, i3dMapping)
		local height = xmlFile:getValue(areaKey .. "#heightNode", nil, self.rootNodes, i3dMapping)

		table.insert(self.testAreas, {
			start = start,
			width = width,
			height = height
		})

		i = i + 1
	end

	self.particleSystems = {}
	i = 0

	while true do
		local particleKey = key .. string.format(".particleSystem(%d)", i)

		if not xmlFile:hasProperty(particleKey) then
			break
		end

		local emitterShape = xmlFile:getValue(particleKey .. "#emitterShape", nil, self.rootNodes, i3dMapping)
		local particleType = xmlFile:getValue(particleKey .. "#particleType")
		local materialType = xmlFile:getValue(particleKey .. "#materialType", particleType)
		local materialIndex = xmlFile:getValue(particleKey .. "#materialIndex", 1)
		local fadeInRange = xmlFile:getValue(particleKey .. "#fadeInRange", nil, true)
		local fadeOutRange = xmlFile:getValue(particleKey .. "#fadeOutRange", nil, true)

		if emitterShape ~= nil then
			local x, y, z = getWorldTranslation(emitterShape)
			local xOffset, _, _ = worldToLocal(self.node, x, y, z)
			local sourceParticleSystem = g_particleSystemManager:getParticleSystem(particleType)

			if sourceParticleSystem ~= nil then
				local ps = ParticleUtil.copyParticleSystem(xmlFile, particleKey, sourceParticleSystem, emitterShape)
				local psData = {
					xOffset = xOffset,
					fadeInRange = fadeInRange,
					fadeOutRange = fadeOutRange,
					particleSystem = ps,
					materialType = materialType,
					materialIndex = materialIndex,
					fillType = FillType.UNKNOWN
				}

				table.insert(self.particleSystems, psData)
			end
		end

		i = i + 1
	end

	self.lastChargeTime = 0
	self.updateTick = 0
	self.scrollUpdate = false
	self.particleSystemsTurnedOff = false

	return true
end

function WindrowerEffect:delete()
	WindrowerEffect:superClass().delete(self)

	for _, particleSystemData in ipairs(self.particleSystems) do
		ParticleUtil.deleteParticleSystem(particleSystemData.particleSystem)
	end
end

function WindrowerEffect:update(dt)
	WindrowerEffect:superClass().update(self, dt)

	if self.updateTick > 5 and self.state ~= ShaderPlaneEffect.STATE_OFF then
		local minX, maxX, foundFillType = WindrowerEffect.getCurrentTestAreaWidth(self)

		setShaderParameter(self.node, "offsetUV", self.scrollPosition, 0, minX, maxX, false)

		for _, particleSystemData in ipairs(self.particleSystems) do
			local inFadeInRange = particleSystemData.fadeInRange[1] <= self.fadeCur[1] and self.fadeCur[1] <= particleSystemData.fadeInRange[2]
			local inFadeOutRange = particleSystemData.fadeOutRange[1] <= self.fadeCur[2] and self.fadeCur[2] <= particleSystemData.fadeOutRange[2]
			local inXRange = minX <= particleSystemData.xOffset and particleSystemData.xOffset <= maxX

			if inXRange and inFadeInRange and inFadeOutRange and self.state ~= ShaderPlaneEffect.STATE_OFF then
				if particleSystemData.fillType ~= foundFillType then
					local material = g_materialManager:getParticleMaterial(foundFillType, particleSystemData.materialType, particleSystemData.materialIndex)

					if material ~= nil then
						ParticleUtil.setMaterial(particleSystemData.particleSystem, material)
					end

					particleSystemData.fillType = foundFillType
				end

				ParticleUtil.setEmittingState(particleSystemData.particleSystem, true)
			else
				ParticleUtil.setEmittingState(particleSystemData.particleSystem, false)
			end
		end

		self.updateTick = 0
		self.particleSystemsTurnedOff = false
	elseif not self.particleSystemsTurnedOff then
		for _, particleSystemData in ipairs(self.particleSystems) do
			ParticleUtil.setEmittingState(particleSystemData.particleSystem, false)
		end

		self.particleSystemsTurnedOff = true
	end

	local _, y, z, w = getShaderParameter(self.node, "offsetUV")
	self.scrollPosition = (self.scrollPosition + dt * self.scrollSpeed) % self.scrollLength

	setShaderParameter(self.node, "offsetUV", self.scrollPosition, y, z, w, false)

	self.updateTick = self.updateTick + 1
end

function WindrowerEffect:start()
	local success = WindrowerEffect:superClass().start(self)

	if success and self.unloadDirection ~= 0 then
		local minX, fade = WindrowerEffect.getCurrentTestAreaWidth(self, true)

		if self.unloadDirection < 0 then
			fade = minX
		end

		fade = fade / (self.width / 2)
		fade = (fade + 1) / 2
		self.fadeCur[2] = MathUtil.clamp(fade, 0, 1)

		if self.unloadDirection < 0 then
			self.fadeCur[2] = math.abs(1 - self.fadeCur[2])
		end
	end

	return success
end

function WindrowerEffect:stop()
	local success = WindrowerEffect:superClass().stop(self)

	if success and self.unloadDirection ~= 0 and self.fadeCur[1] == 0 then
		local _, _, fade, maxX = getShaderParameter(self.node, "offsetUV")

		if self.unloadDirection < 0 then
			fade = maxX
		end

		fade = fade / (self.width / 2)
		fade = (fade + 1) / 2
		self.fadeCur[1] = MathUtil.clamp(fade, 0, 1)

		if self.unloadDirection < 0 then
			self.fadeCur[1] = math.abs(1 - self.fadeCur[1])
		end
	end

	return success
end

function WindrowerEffect:getCurrentTestAreaWidth(real)
	local minX = self.width / 2 + self.dropOffset
	local maxX = -self.width / 2 - self.dropOffset
	local foundFillType = FillType.UNKNOWN

	for _, testArea in ipairs(self.testAreas) do
		local x0, y0, z0 = getWorldTranslation(testArea.start)
		local x1, y1, z1 = getWorldTranslation(testArea.width)
		local x2, _, z2 = getWorldTranslation(testArea.height)
		local fillType = DensityMapHeightUtil.getFillTypeAtArea(x0, z0, x1, z1, x2, z2)

		if fillType ~= FillType.UNKNOWN then
			local xStart, _, _ = worldToLocal(self.node, x0, y0, z0)
			local xWidth, _, _ = worldToLocal(self.node, x1, y1, z1)

			if xStart < minX then
				minX = xStart
			end

			if maxX < xWidth then
				maxX = xWidth
			end

			foundFillType = fillType
		end
	end

	if (not real or real == nil) and self.unloadDirection ~= 0 then
		if self.unloadDirection < 0 then
			minX = -self.width / 2 - self.dropOffset
		end

		if self.unloadDirection > 0 then
			maxX = self.width / 2 + self.dropOffset
		end
	end

	return minX, maxX, foundFillType
end

function WindrowerEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#unloadDirection", "(WindrowerEffect) Unload direction")
	schema:register(XMLValueType.FLOAT, basePath .. "#width", "(WindrowerEffect) Width", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#dropOffset", "(WindrowerEffect) Drop offset", 0)
	schema:register(XMLValueType.INT, basePath .. "#turnOffRequiredEffect", "(WindrowerEffect) Index of turn off required effect", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".testArea(?)#startNode", "(WindrowerEffect) Test area start node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".testArea(?)#widthNode", "(WindrowerEffect) Test area width node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".testArea(?)#heightNode", "(WindrowerEffect) Test area height node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".particleSystem(?)#emitterShape", "(WindrowerEffect) Emitter shape node")
	schema:register(XMLValueType.STRING, basePath .. ".particleSystem(?)#particleType", "(WindrowerEffect) Particle type")
	schema:register(XMLValueType.STRING, basePath .. ".particleSystem(?)#materialType", "(WindrowerEffect) Material type", "same as particleType")
	schema:register(XMLValueType.INT, basePath .. ".particleSystem(?)#materialIndex", "(WindrowerEffect) Particle type", 1)
	schema:register(XMLValueType.VECTOR_2, basePath .. ".particleSystem(?)#fadeInRange", "(WindrowerEffect) Fade in range")
	schema:register(XMLValueType.VECTOR_2, basePath .. ".particleSystem(?)#fadeOutRange", "(WindrowerEffect) Fade out range")
	ParticleUtil.registerParticleCopyXMLPaths(schema, basePath .. ".particleSystem(?)")
end
