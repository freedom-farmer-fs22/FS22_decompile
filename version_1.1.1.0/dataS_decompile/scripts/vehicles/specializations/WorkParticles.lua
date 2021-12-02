WorkParticles = {
	PARTICLE_MAPPING_XML_PATH = "vehicle.workParticles.particle(?).node(?)",
	prerequisitesPresent = function (specializations)
		return true
	end
}

function WorkParticles.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("WorkParticles")
	schema:register(XMLValueType.STRING, "vehicle.workParticles.particleAnimation(?)#file", "External effect i3d file")
	schema:register(XMLValueType.FLOAT, "vehicle.workParticles.particleAnimation(?)#speedThreshold", "Speed threshold", 0)
	WorkParticles.registerGroundAnimationMappingXMLPaths(schema, "vehicle.workParticles.particleAnimation(?).node(?)")
	schema:register(XMLValueType.STRING, "vehicle.workParticles.particle(?)#file", "External effect i3d file")
	WorkParticles.registerGroundParticleMappingXMLPaths(schema, "vehicle.workParticles.particle(?).node(?)")
	EffectManager.registerEffectXMLPaths(schema, "vehicle.workParticles.effect(?)")
	schema:register(XMLValueType.FLOAT, "vehicle.workParticles.effect(?)#speedThreshold", "Speed threshold", 0.5)
	schema:register(XMLValueType.INT, "vehicle.workParticles.effect(?)#activeDirection", "Active Direction (effect will be turned off wen in opposite direction)", 1)
	schema:register(XMLValueType.INT, "vehicle.workParticles.effect(?)#workAreaIndex", "Work area index")
	schema:register(XMLValueType.INT, "vehicle.workParticles.effect(?)#groundReferenceNodeIndex", "Index of ground reference node")
	schema:register(XMLValueType.BOOL, "vehicle.workParticles.effect(?)#needsSetIsTurnedOn", "Needs set is turned on", false)
	schema:register(XMLValueType.NODE_INDEX, GroundReference.GROUND_REFERENCE_XML_KEY .. "#depthNode", "Depth node")
	schema:setXMLSpecializationType()
end

function WorkParticles.registerGroundAnimationMappingXMLPaths(schema, key)
	schema:register(XMLValueType.NODE_INDEX, key .. "#node", "Link node in vehicle")
	schema:register(XMLValueType.INT, key .. "#refNodeIndex", "Ground reference node index")
	schema:register(XMLValueType.STRING, key .. "#animMeshNode", "Animation mesh node in external file")
	schema:register(XMLValueType.STRING, key .. "#materialType", "Material type name (If external file is not given)")
	schema:register(XMLValueType.INT, key .. "#materialId", "Material index (If external file is not given)", 1)
	schema:register(XMLValueType.FLOAT, key .. "#maxDepth", "Max. depth", -0.1)
end

function WorkParticles.registerGroundParticleMappingXMLPaths(schema, key)
	schema:register(XMLValueType.NODE_INDEX, key .. "#node", "Link node in vehicle")
	schema:register(XMLValueType.INT, key .. "#refNodeIndex", "Ground reference node index")
	schema:register(XMLValueType.STRING, key .. "#particleNode", "Particle node in external file")
	schema:register(XMLValueType.STRING, key .. "#particleType", "Particle type name (If external file is not given)")
	schema:register(XMLValueType.STRING, key .. "#fillType", "Fill type for particles (If external file is not given)", "UNKNOWN")
	schema:register(XMLValueType.FLOAT, key .. "#speedThreshold", "Speed threshold", 0.5)
	schema:register(XMLValueType.INT, key .. "#movingDirection", "Moving direction")
	ParticleUtil.registerParticleCopyXMLPaths(schema, key)
end

function WorkParticles.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getDoGroundManipulation", WorkParticles.getDoGroundManipulation)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundAnimations", WorkParticles.loadGroundAnimations)
	SpecializationUtil.registerFunction(vehicleType, "onGroundAnimationI3DLoaded", WorkParticles.onGroundAnimationI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundAnimationMapping", WorkParticles.loadGroundAnimationMapping)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundParticles", WorkParticles.loadGroundParticles)
	SpecializationUtil.registerFunction(vehicleType, "groundParticleI3DLoaded", WorkParticles.groundParticleI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundParticleMapping", WorkParticles.loadGroundParticleMapping)
	SpecializationUtil.registerFunction(vehicleType, "loadGroundEffects", WorkParticles.loadGroundEffects)
	SpecializationUtil.registerFunction(vehicleType, "getFillTypeFromWorkAreaIndex", WorkParticles.getFillTypeFromWorkAreaIndex)
end

function WorkParticles.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadGroundReferenceNode", WorkParticles.loadGroundReferenceNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateGroundReferenceNode", WorkParticles.updateGroundReferenceNode)
end

function WorkParticles.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", WorkParticles)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", WorkParticles)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", WorkParticles)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", WorkParticles)
end

function WorkParticles:onLoad(savegame)
	local spec = self.spec_workParticles

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.groundParticleAnimations.groundParticleAnimation", "vehicle.workParticles.particleAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.groundParticleAnimations.groundParticle", "vehicle.workParticles.particle")

	if self.isClient then
		spec.particleAnimations = {}
		local i = 0

		while true do
			local key = string.format("vehicle.workParticles.particleAnimation(%d)", i)

			if not self.xmlFile:hasProperty(key) then
				break
			end

			local animation = {}

			if self:loadGroundAnimations(self.xmlFile, key, animation, i) then
				table.insert(spec.particleAnimations, animation)
			end

			i = i + 1
		end

		spec.particles = {}
		i = 0

		while true do
			local key = string.format("vehicle.workParticles.particle(%d)", i)

			if not self.xmlFile:hasProperty(key) then
				break
			end

			local particle = {}

			if self:loadGroundParticles(self.xmlFile, key, particle, i) then
				table.insert(spec.particles, particle)
			end

			i = i + 1
		end

		spec.effects = {}
		i = 0

		while true do
			local key = string.format("vehicle.workParticles.effect(%d)", i)

			if not self.xmlFile:hasProperty(key) then
				break
			end

			local effect = {}

			if self:loadGroundEffects(self.xmlFile, key, effect, i) then
				table.insert(spec.effects, effect)
			end

			i = i + 1
		end
	end

	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onDelete", WorkParticles)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", WorkParticles)
		SpecializationUtil.removeEventListener(self, "onDeactivate", WorkParticles)
	end
end

function WorkParticles:onDelete()
	local spec = self.spec_workParticles

	if spec.particleAnimations ~= nil then
		for _, animation in ipairs(spec.particleAnimations) do
			if animation.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(animation.sharedLoadRequestId)

				animation.sharedLoadRequestId = nil
			end
		end
	end

	if spec.particles ~= nil then
		for _, ps in pairs(spec.particles) do
			for _, mapping in ipairs(ps.mappings) do
				ParticleUtil.deleteParticleSystem(mapping.particleSystem)
			end

			if ps.sharedLoadRequestId ~= nil then
				g_i3DManager:releaseSharedI3DFile(ps.sharedLoadRequestId)

				ps.sharedLoadRequestId = nil
			end
		end
	end

	if spec.effects ~= nil then
		for _, effect in pairs(spec.effects) do
			g_effectManager:deleteEffects(effect.effect)
		end
	end
end

function WorkParticles:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_workParticles
	local isOnField = self:getIsOnField()

	for _, animation in ipairs(spec.particleAnimations) do
		for _, mapping in ipairs(animation.mappings) do
			local refNode = mapping.groundRefNode

			if refNode ~= nil and refNode.depthNode ~= nil then
				local depth = MathUtil.clamp(refNode.depth / mapping.maxWorkDepth, 0, 1)

				if not isOnField then
					depth = 0
				end

				depth = MathUtil.clamp(math.min(depth, mapping.lastDepth + refNode.movingDirection * refNode.movedDistance / 0.5), 0, 1)
				mapping.lastDepth = depth
				mapping.speed = mapping.speed - refNode.movedDistance * refNode.movingDirection

				setVisibility(mapping.animNode, depth > 0)
				setShaderParameter(mapping.animNode, "VertxoffsetVertexdeformMotionUVscale", -6, depth, mapping.speed, 1.5, false)
			end
		end
	end

	local lastSpeed = self:getLastSpeed(true)
	local enabled = self:getDoGroundManipulation() and isOnField

	for _, ps in pairs(spec.particles) do
		for _, mapping in ipairs(ps.mappings) do
			local nodeEnabled = enabled
			nodeEnabled = nodeEnabled and mapping.groundRefNode.isActive and mapping.speedThreshold < lastSpeed

			if mapping.movingDirection ~= nil then
				nodeEnabled = nodeEnabled and mapping.movingDirection == self.movingDirection
			end

			ParticleUtil.setEmittingState(mapping.particleSystem, nodeEnabled)
		end
	end

	for _, effect in pairs(spec.effects) do
		local state = enabled and effect.speedThreshold < lastSpeed

		if effect.needsSetIsTurnedOn and self.getIsTurnedOn ~= nil then
			local turnedOn = self:getIsTurnedOn()

			if self.getAttacherVehicle ~= nil then
				local attacherVehicle = self:getAttacherVehicle()

				if attacherVehicle ~= nil and attacherVehicle.getIsTurnedOn ~= nil then
					turnedOn = turnedOn or attacherVehicle:getIsTurnedOn()
				end
			end

			state = state and turnedOn
		end

		local workArea = self:getWorkAreaByIndex(effect.workAreaIndex)

		if workArea ~= nil and workArea.requiresGroundContact then
			state = state and workArea.groundReferenceNode ~= nil and workArea.groundReferenceNode.isActive
		end

		if effect.groundReferenceNodeIndex ~= nil and effect.groundReferenceNode == nil then
			effect.groundReferenceNode = self:getGroundReferenceNodeFromIndex(effect.groundReferenceNodeIndex)

			if effect.groundReferenceNode == nil then
				Logging.warning("Unknown ground reference node '%s' for WorkParticle effect!", effect.groundReferenceNodeIndex)

				effect.groundReferenceNodeIndex = nil
			end
		end

		if effect.groundReferenceNode ~= nil then
			state = state and effect.groundReferenceNode.isActive
		end

		state = state and (self.movingDirection ~= -effect.activeDirection or self:getLastSpeed() < 0.5)

		if state then
			local fillType = self:getFillTypeFromWorkAreaIndex(effect.workAreaIndex)

			g_effectManager:setFillType(effect.effect, fillType)
			g_effectManager:startEffects(effect.effect)
		else
			g_effectManager:stopEffects(effect.effect)
		end
	end
end

function WorkParticles:getDoGroundManipulation()
	return true
end

function WorkParticles:loadGroundAnimations(xmlFile, key, animation, index)
	animation.speedThreshold = xmlFile:getValue(key .. "#speedThreshold", 0)
	animation.mappings = {}
	local j = 0

	while true do
		local nodeBaseName = string.format(key .. ".node(%d)", j)

		if not self.xmlFile:hasProperty(nodeBaseName) then
			break
		end

		local mapping = {}

		if self:loadGroundAnimationMapping(xmlFile, nodeBaseName, mapping, j) then
			table.insert(animation.mappings, mapping)
		end

		j = j + 1
	end

	local filenameStr = self.xmlFile:getValue(key .. "#file")

	if filenameStr ~= nil then
		filenameStr = Utils.getFilename(filenameStr, self.baseDirectory)
		animation.sharedLoadRequestId = self:loadSubSharedI3DFile(filenameStr, false, false, self.onGroundAnimationI3DLoaded, self, {
			filenameStr,
			animation
		})
	end

	return true
end

function WorkParticles:onGroundAnimationI3DLoaded(i3dNode, args)
	local filename, animation = unpack(args)

	if i3dNode ~= 0 then
		for _, mapping in ipairs(animation.mappings) do
			link(mapping.node, mapping.animNode)
			setVisibility(mapping.animNode, false)
		end

		animation.filename = filename

		delete(i3dNode)
	end
end

function WorkParticles:loadGroundAnimationMapping(xmlFile, key, mapping, index)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#index", key .. "#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#animMeshIndex", key .. "#animMeshNode")

	local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if node == nil then
		Logging.xmlWarning(self.xmlFile, "Invalid node '%s' for '%s'", getXMLString(xmlFile.handle, key .. "#node"), key)

		return false
	end

	local groundRefIndex = xmlFile:getValue(key .. "#refNodeIndex")

	if groundRefIndex == nil or self:getGroundReferenceNodeFromIndex(groundRefIndex) == nil then
		Logging.xmlWarning(self.xmlFile, "Invalid refNodeIndex '%s' for '%s'", xmlFile:getValue(key .. "#refNodeIndex"), key)

		return false
	end

	local animNode = nil
	local animMeshNode = xmlFile:getValue(key .. "#animMeshNode")

	if animMeshNode ~= nil then
		animNode = I3DUtil.indexToObject(node, animMeshNode, self.i3dMappings)

		if animNode == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid animMesh node '%s' '%s'", xmlFile:getValue(key .. "#animMeshNode"), key)

			return false
		end
	else
		local materialType = xmlFile:getValue(key .. "#materialType")
		local materialId = xmlFile:getValue(key .. "#materialId", 1)

		if materialType == nil then
			Logging.xmlWarning(self.xmlFile, "Missing materialType in '%s'", key)

			return false
		end

		animNode = node
		local material = g_materialManager:getBaseMaterialByName(materialType)

		if material ~= nil then
			setMaterial(node, material, 0)
		else
			Logging.xmlWarning(self.xmlFile, "Invalid materialType '%s' or materialId '%s' in '%s'", materialType, materialId, key)
		end

		setVisibility(animNode, false)
	end

	mapping.node = node
	mapping.animNode = animNode
	mapping.groundRefNode = self:getGroundReferenceNodeFromIndex(groundRefIndex)
	mapping.lastDepth = 0
	mapping.speed = 0
	mapping.maxWorkDepth = xmlFile:getValue(key .. "#maxDepth", -0.1)

	return true
end

function WorkParticles:loadGroundParticles(xmlFile, key, particle, index)
	particle.mappings = {}
	local filename = xmlFile:getValue(key .. "#file")

	if filename ~= nil then
		filename = Utils.getFilename(filename, self.baseDirectory)
		particle.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.groundParticleI3DLoaded, self, {
			xmlFile,
			key,
			particle,
			filename
		})
	else
		local j = 0

		while true do
			local nodeBaseName = string.format(key .. ".node(%d)", j)

			if not xmlFile:hasProperty(nodeBaseName) then
				break
			end

			local mapping = {}

			if self:loadGroundParticleMapping(xmlFile, nodeBaseName, mapping, j) then
				table.insert(particle.mappings, mapping)
			end

			j = j + 1
		end
	end

	return true
end

function WorkParticles:groundParticleI3DLoaded(i3dNode, failedReason, args)
	local xmlFile, key, particle, filename = unpack(args)
	local j = 0

	while true do
		local nodeBaseName = string.format(key .. ".node(%d)", j)

		if not xmlFile:hasProperty(nodeBaseName) then
			break
		end

		local mapping = {}

		if self:loadGroundParticleMapping(xmlFile, nodeBaseName, mapping, j, i3dNode) then
			table.insert(particle.mappings, mapping)
		end

		j = j + 1
	end

	if i3dNode ~= 0 then
		for _, mapping in ipairs(particle.mappings) do
			link(mapping.node, mapping.particleNode)
			ParticleUtil.loadParticleSystemFromNode(mapping.particleNode, mapping.particleSystem, false, true)
		end

		particle.filename = filename

		delete(i3dNode)
	end
end

function WorkParticles:loadGroundParticleMapping(xmlFile, key, mapping, index, i3dNode)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#index", key .. "#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#particleIndex", key .. "#particleNode")

	mapping.particleSystem = {}
	local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if node == nil then
		Logging.xmlWarning(self.xmlFile, "Invalid node '%s' for '%s'", xmlFile:getValue(key .. "#node"), key)

		return false
	end

	local groundRefIndex = xmlFile:getValue(key .. "#refNodeIndex")

	if groundRefIndex == nil or self:getGroundReferenceNodeFromIndex(groundRefIndex) == nil then
		Logging.xmlWarning(self.xmlFile, "Invalid refNodeIndex '%s' for '%s'", xmlFile:getValue(key .. "#refNodeIndex"), key)

		return false
	end

	local particleNode = nil
	local particleNodeIndex = xmlFile:getValue(key .. "#particleNode")

	if particleNodeIndex ~= nil then
		particleNode = I3DUtil.indexToObject(i3dNode, particleNodeIndex, self.i3dMappings)

		if particleNode == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid particle node '%s' '%s'", xmlFile:getValue(key .. "#particleNode"), key)

			return false
		end
	else
		particleNode = node
		local particleType = xmlFile:getValue(key .. "#particleType")

		if particleType == nil then
			Logging.xmlWarning(self.xmlFile, "Missing particleType in '%s'", key)

			return false
		end

		local fillTypeStr = xmlFile:getValue(key .. "#fillType")
		local fillType = Utils.getNoNil(g_fillTypeManager:getFillTypeIndexByName(fillTypeStr), FillType.UNKNOWN)
		local particleSystem = g_particleSystemManager:getParticleSystem(particleType)

		if particleSystem ~= nil then
			if fillType ~= FillType.UNKNOWN then
				local material = g_materialManager:getParticleMaterial(fillType, particleType, 1)

				if material ~= nil then
					ParticleUtil.setMaterial(particleSystem, material)
				end
			end

			mapping.particleSystem = ParticleUtil.copyParticleSystem(xmlFile, key, particleSystem, node)
		else
			return false
		end
	end

	mapping.node = node
	mapping.particleNode = particleNode
	mapping.groundRefNode = self:getGroundReferenceNodeFromIndex(groundRefIndex)
	mapping.speedThreshold = xmlFile:getValue(key .. "#speedThreshold", 0.5)
	mapping.movingDirection = xmlFile:getValue(key .. "#movingDirection")

	return true
end

function WorkParticles:loadGroundEffects(xmlFile, key, effect, index)
	effect.speedThreshold = xmlFile:getValue(key .. "#speedThreshold", 0.5)
	effect.activeDirection = xmlFile:getValue(key .. "#activeDirection", 1)
	effect.workAreaIndex = xmlFile:getValue(key .. "#workAreaIndex")
	effect.groundReferenceNodeIndex = xmlFile:getValue(key .. "#groundReferenceNodeIndex")
	effect.needsSetIsTurnedOn = xmlFile:getValue(key .. "#needsSetIsTurnedOn", false)
	effect.effect = g_effectManager:loadEffect(xmlFile, key, self.components, self, self.i3dMappings)

	return true
end

function WorkParticles:getFillTypeFromWorkAreaIndex(workAreaIndex)
	local fillType = FillType.UNKNOWN
	local workArea = self:getWorkAreaByIndex(workAreaIndex)

	if workArea ~= nil then
		if workArea.fillType ~= nil then
			fillType = workArea.fillType
		elseif workArea.fruitType ~= nil then
			fillType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(workArea.fruitType)
		end
	end

	return fillType
end

function WorkParticles:loadGroundReferenceNode(superFunc, xmlFile, key, groundReferenceNode)
	local returnValue = superFunc(self, xmlFile, key, groundReferenceNode)

	if returnValue then
		groundReferenceNode.depthNode = xmlFile:getValue(key .. "#depthNode", nil, self.components, self.i3dMappings)
		groundReferenceNode.movedDistance = 0
		groundReferenceNode.depth = 0
		groundReferenceNode.movingDirection = 0
	end

	return returnValue
end

function WorkParticles:updateGroundReferenceNode(superFunc, groundReferenceNode, x, y, z, terrainHeight, densityHeight)
	superFunc(self, groundReferenceNode, x, y, z, terrainHeight, densityHeight)

	if self.isClient and groundReferenceNode.depthNode ~= nil then
		local newX, newY, newZ = getWorldTranslation(groundReferenceNode.depthNode)

		if groundReferenceNode.lastPosition == nil then
			groundReferenceNode.lastPosition = {
				newX,
				newY,
				newZ
			}
		end

		local dx, dy, dz = worldDirectionToLocal(groundReferenceNode.depthNode, newX - groundReferenceNode.lastPosition[1], newY - groundReferenceNode.lastPosition[2], newZ - groundReferenceNode.lastPosition[3])
		groundReferenceNode.movingDirection = 0

		if dz > 0.0001 then
			groundReferenceNode.movingDirection = 1
		elseif dz < -0.0001 then
			groundReferenceNode.movingDirection = -1
		end

		groundReferenceNode.movedDistance = MathUtil.vector3Length(dx, dy, dz)
		groundReferenceNode.lastPosition[3] = newZ
		groundReferenceNode.lastPosition[2] = newY
		groundReferenceNode.lastPosition[1] = newX
		local terrainHeightDepthNode = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, newX, newY, newZ)
		groundReferenceNode.depth = newY - terrainHeightDepthNode
	end
end

function WorkParticles:onDeactivate()
	local spec = self.spec_workParticles

	for _, ps in pairs(spec.particles) do
		for _, mapping in ipairs(ps.mappings) do
			ParticleUtil.setEmittingState(mapping.particleSystem, false)
		end
	end

	for _, animation in ipairs(spec.particleAnimations) do
		for _, mapping in ipairs(animation.mappings) do
			setVisibility(mapping.animNode, false)
		end
	end
end
