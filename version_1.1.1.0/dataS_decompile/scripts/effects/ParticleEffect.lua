ParticleEffect = {}
local ParticleEffect_mt = Class(ParticleEffect, Effect)

function ParticleEffect.new(customMt)
	local self = Effect.new(customMt or ParticleEffect_mt)
	self.isActive = false
	self.currentFillType = FillType.UNKNOWN

	return self
end

function ParticleEffect:loadEffectAttributes(xmlFile, key, node, i3dNode, i3dMapping)
	if not ParticleEffect:superClass().loadEffectAttributes(self, xmlFile, key, node, i3dNode, i3dMapping) then
		return false
	end

	self.emitterShape = self.node
	self.emitterShapeTrans = createTransformGroup("emitterShapeTrans")

	link(getParent(self.emitterShape), self.emitterShapeTrans, getChildIndex(self.emitterShape))
	link(self.emitterShapeTrans, self.emitterShape)

	self.emitCountScale = Effect.getValue(xmlFile, key, node, "emitCountScale", 1)
	self.particleType = Effect.getValue(xmlFile, key, node, "particleType", "unloading")
	self.materialType = Effect.getValue(xmlFile, key, node, "materialType")
	self.useFruitColor = Effect.getValue(xmlFile, key, node, "useFruitColor", false)
	self.worldSpace = Effect.getValue(xmlFile, key, node, "worldSpace", true)
	self.delay = Effect.getValue(xmlFile, key, node, "delay", 0)
	self.startTime = Effect.getValue(xmlFile, key, node, "startTime", self.delay)
	self.startTimeMs = self.startTime * 1000
	self.stopTime = Effect.getValue(xmlFile, key, node, "stopTime", self.delay)
	self.stopTimeMs = self.stopTime * 1000
	self.lifespan = Effect.getValue(xmlFile, key, node, "lifespan")
	self.extraDistance = Effect.getValue(xmlFile, key, node, "extraDistance", 0.5)
	self.ignoreDistanceLifeSpan = Effect.getValue(xmlFile, key, node, "ignoreDistanceLifeSpan", false)
	self.spriteScale = Effect.getValue(xmlFile, key, node, "spriteScale", 1)
	self.spriteGainScale = Effect.getValue(xmlFile, key, node, "spriteGainScale", self.spriteScale)
	self.realStartTime = math.huge
	self.realStopTime = math.huge
	self.useCuttingWidth = Effect.getValue(xmlFile, key, node, "useCuttingWidth", true)
	self.particleSystem = nil

	return true
end

function ParticleEffect:delete()
	ParticleEffect:superClass().delete(self)
	ParticleUtil.deleteParticleSystem(self.particleSystem)
end

function ParticleEffect:isRunning()
	return self.isActive
end

function ParticleEffect:start()
	if self:canStart() and self.particleSystem ~= nil then
		ParticleUtil.setEmittingState(self.particleSystem, self.totalWidth == nil or self.totalWidth > 0)

		self.isActive = true
		self.realStartTime = g_time
		self.realStopTime = math.huge

		return true
	end

	return false
end

function ParticleEffect:stop()
	ParticleUtil.setEmittingState(self.particleSystem, false)

	if self.particleSystem ~= nil then
		self.realStopTime = g_time
	end

	self.isActive = false
end

function ParticleEffect:reset()
end

function ParticleEffect:setFruitType(fruitType)
	local fillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitType)
	self.useFruitColor = true

	self:setFillType(fillType)
end

function ParticleEffect:setFillType(fillType)
	local success = true

	if self.currentFillType ~= fillType or self.particleSystem == nil then
		if self.particleSystem == nil then
			local sourceParticleSystem = g_particleSystemManager:getParticleSystem(self.particleType)

			if sourceParticleSystem ~= nil then
				local psClone = clone(sourceParticleSystem.shape, true, false, true)
				local particleSystem = {}
				local emitterShape = self.emitterShape

				ParticleUtil.loadParticleSystemFromNode(psClone, particleSystem, false, self.worldSpace, sourceParticleSystem.forceFullLifespan)
				ParticleUtil.setEmitterShape(particleSystem, emitterShape)

				local scale = particleSystem.emitterShapeSize / particleSystem.defaultEmitterShapeSize * self.emitCountScale

				ParticleUtil.initEmitterScale(particleSystem, scale)
				ParticleUtil.setEmitCountScale(particleSystem, 1)

				if self.lifespan ~= nil then
					ParticleUtil.setParticleLifespan(particleSystem, self.lifespan * 1000)

					particleSystem.originalLifespan = self.lifespan * 1000
				end

				ParticleUtil.setParticleStartStopTime(particleSystem, self.startTime, self.stopTime)

				if self.spriteScale ~= 1 then
					local originalSpriteScaleX = ParticleUtil.getParticleSystemSpriteScaleX(particleSystem)

					ParticleUtil.setParticleSystemSpriteScaleX(particleSystem, originalSpriteScaleX * self.spriteScale)

					local originalSpriteScaleY = ParticleUtil.getParticleSystemSpriteScaleY(particleSystem)

					ParticleUtil.setParticleSystemSpriteScaleY(particleSystem, originalSpriteScaleY * self.spriteScale)
				end

				if self.spriteGainScale ~= 1 then
					local originalSpriteGainScaleX = ParticleUtil.getParticleSystemSpriteScaleXGain(particleSystem)

					ParticleUtil.setParticleSystemSpriteScaleXGain(particleSystem, originalSpriteGainScaleX * self.spriteGainScale)

					local originalSpriteGainScaleY = ParticleUtil.getParticleSystemSpriteScaleYGain(particleSystem)

					ParticleUtil.setParticleSystemSpriteScaleYGain(particleSystem, originalSpriteGainScaleY * self.spriteGainScale)
				end

				if not particleSystem.worldSpace then
					link(getParent(emitterShape), particleSystem.shape, getChildIndex(emitterShape))
					setTranslation(particleSystem.shape, getTranslation(emitterShape))
					setRotation(particleSystem.shape, getRotation(emitterShape))
					link(particleSystem.shape, emitterShape)
					setTranslation(emitterShape, 0, 0, 0)
					setRotation(emitterShape, 0, 0, 0)
					ParticleUtil.setParticleSystemVelocityScale(particleSystem, 0)
				end

				if self.materialType ~= nil then
					local effectMaterial = g_materialManager:getBaseMaterialByName(self.materialType)

					if effectMaterial ~= nil then
						ParticleUtil.setMaterial(particleSystem, effectMaterial)

						if particleSystem ~= nil and particleSystem.shape ~= nil then
							setMaterial(particleSystem.shape, effectMaterial, 0)

							if getMaterialCustomShaderFilename(effectMaterial):contains("psSubUVShader") then
								local fillTypeTextureDiffuseMap, _, _, _ = g_fillTypeManager:getFillTypeTextureArrays()

								if fillTypeTextureDiffuseMap ~= nil then
									effectMaterial = getMaterial(particleSystem.shape, 0)
									local newMaterial = setMaterialCustomMap(effectMaterial, "fillTypeColorMap", fillTypeTextureDiffuseMap, false)

									if newMaterial ~= effectMaterial then
										setMaterial(particleSystem.shape, newMaterial, 0)
									end
								end
							else
								g_fillTypeManager:assignFillTypeTextureArrays(particleSystem.shape, true, true, true)
							end
						end
					else
						Logging.error("Failed to assign material to shader plane effect. Base Material '%s' not found!", self.materialType)
					end
				end

				self.particleSystem = particleSystem
				self.distanceToLifespans = {}

				for j = 0, 1, 0.1 do
					local invJ = 1 - j
					local lifespans = AnimCurve.new(linearInterpolator1)

					for i = 1, 20 do
						local lifespan = i * 100
						local normalSpeed, _ = getParticleSystemAverageSpeed(self.particleSystem.geometry)
						local gravity = 7.17e-06
						local distance = normalSpeed * lifespan * invJ + gravity * lifespan * lifespan

						lifespans:addKeyframe({
							lifespan,
							time = distance
						})
					end

					table.insert(self.distanceToLifespans, lifespans)
				end
			else
				Logging.error("Failed to find particle system for type '%s'.", self.particleType)

				success = false
			end
		end

		if self.materialType ~= nil and self.particleSystem ~= nil and self.particleSystem.shape ~= nil then
			local textureArrayIndex = g_fillTypeManager:getTextureArrayIndexByFillTypeIndex(fillType)

			if textureArrayIndex ~= nil then
				setShaderParameter(self.particleSystem.shape, "fillTypeId", textureArrayIndex - 1, 0, 0, 0, false)
			end

			if self.particleType:lower():contains("smoke") or self.materialType:lower():contains("smoke") then
				local color = g_fillTypeManager:getSmokeColorByFillTypeIndex(fillType, self.useFruitColor)

				if color ~= nil then
					setShaderParameter(self.particleSystem.shape, "colorAlpha", color[1], color[2], color[3], color[4], false)
				end
			end
		end

		self.currentFillType = fillType
	end

	return success
end

function ParticleEffect:setMinMaxWidth(minValue, maxValue, minWidthNorm, maxWidthNorm, reset)
	if self.useCuttingWidth then
		local widthX = math.abs(minValue - maxValue)
		local emitterShape = self.emitterShape
		local _, sy, sz = getScale(emitterShape)

		setScale(emitterShape, widthX, sy, sz)

		local _, y, z = getTranslation(emitterShape)

		setTranslation(emitterShape, -(maxValue - widthX * 0.5), y, z)
		ParticleUtil.setEmitCountScale(self.particleSystem, widthX)

		self.totalWidth = widthX

		if self.isActive then
			ParticleUtil.setEmittingState(self.particleSystem, widthX > 0)
		end
	end
end

function ParticleEffect:setDistance(distance, terrain)
	if self.particleSystem ~= nil and not self.ignoreDistanceLifeSpan and not self.particleSystem.forceFullLifespan then
		local _, dirY, _ = localDirectionToWorld(self.particleSystem.emitterShape, 0, 1, 0)
		local direction = dirY / 1
		local index = math.floor(direction * #self.distanceToLifespans)
		local curve = self.distanceToLifespans[MathUtil.clamp(index, 1, #self.distanceToLifespans)]
		local lifespan = curve:get(distance + self.extraDistance)

		ParticleUtil.setParticleLifespan(self.particleSystem, lifespan)
	end
end

function ParticleEffect:getIsVisible()
	return self:getIsFullyVisible()
end

function ParticleEffect:getIsFullyVisible()
	return self.realStartTime + self.startTimeMs < g_time and g_time < self.realStopTime + self.stopTimeMs
end

function ParticleEffect.registerEffectXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. "#emitCountScale", "(ParticleEffect) Emit count scale", 1)
	schema:register(XMLValueType.STRING, basePath .. "#particleType", "(ParticleEffect) Particle type", "unloading")
	schema:register(XMLValueType.STRING, basePath .. "#materialType", "(ParticleEffect) Material type")
	schema:register(XMLValueType.BOOL, basePath .. "#useFruitColor", "(ParticleEffect) Apply the fruit color to the smoke effect instead of the fill color", false)
	schema:register(XMLValueType.BOOL, basePath .. "#worldSpace", "(ParticleEffect) World space", true)
	schema:register(XMLValueType.FLOAT, basePath .. "#delay", "(ParticleEffect) Delay", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#startTime", "(ParticleEffect) Start time", "delay")
	schema:register(XMLValueType.FLOAT, basePath .. "#stopTime", "(ParticleEffect) Stop time", "delay")
	schema:register(XMLValueType.FLOAT, basePath .. "#lifespan", "(ParticleEffect) Lifespan")
	schema:register(XMLValueType.FLOAT, basePath .. "#extraDistance", "(ParticleEffect) Extra distance", 0.5)
	schema:register(XMLValueType.BOOL, basePath .. "#ignoreDistanceLifeSpan", "(ParticleEffect) Ignore distance based lifespan and apply fixed lifespan", false)
	schema:register(XMLValueType.FLOAT, basePath .. "#spriteScale", "(ParticleEffect) Scale factor that is applied on sprite scale loaded from particle system", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#spriteGainScale", "(ParticleEffect) Scale factor that is applied on sprite gain scale loaded from particle system", "#spriteScale value")
	schema:register(XMLValueType.BOOL, basePath .. "#useCuttingWidth", "(ParticleEffect) Use cutting width", true)
end
