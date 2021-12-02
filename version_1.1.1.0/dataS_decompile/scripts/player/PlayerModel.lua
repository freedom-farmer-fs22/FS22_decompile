PlayerModel = {}
local PlayerModel_mt = Class(PlayerModel)

function PlayerModel.new(customMt)
	local self = setmetatable({}, customMt or PlayerModel_mt)
	self.isLoaded = false
	self.sharedLoadRequestIds = {}
	self.modelParts = {}
	self.capsuleHeight = 0.8
	self.capsuleRadius = 0.4
	self.capsuleTotalHeight = self.capsuleHeight + self.capsuleRadius * 2
	self.style = nil
	self.ikChains = {}
	self.soundInformation = {
		distanceSinceLastFootstep = 0,
		samples = {
			swim = {},
			plunge = {},
			horseBrush = {}
		},
		distancePerFootstep = {
			run = 1.5,
			crouch = 0.5,
			walk = 0.75
		}
	}
	self.particleSystemsInformation = {
		systems = {
			swim = {},
			plunge = {}
		}
	}
	self.animationInformation = {
		player = 0,
		parameters = {
			forwardVelocity = {
				value = 0,
				id = 1,
				type = 1
			},
			verticalVelocity = {
				value = 0,
				id = 2,
				type = 1
			},
			yawVelocity = {
				value = 0,
				id = 3,
				type = 1
			},
			absYawVelocity = {
				value = 0,
				id = 4,
				type = 1
			},
			onGround = {
				value = false,
				id = 5,
				type = 0
			},
			inWater = {
				value = false,
				id = 6,
				type = 0
			},
			isCrouched = {
				value = false,
				id = 7,
				type = 0
			},
			absForwardVelocity = {
				value = 0,
				id = 8,
				type = 1
			},
			isCloseToGround = {
				value = false,
				id = 9,
				type = 0
			},
			isUsingChainsawHorizontal = {
				value = false,
				id = 10,
				type = 0
			},
			isUsingChainsawVertical = {
				value = false,
				id = 11,
				type = 0
			}
		}
	}

	return self
end

function PlayerModel:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

		self.sharedLoadRequestId = nil
	end

	if self.sharedLoadRequestIds ~= nil then
		for _, sharedLoadRequestId in pairs(self.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
		end

		self.sharedLoadRequestIds = nil
	end

	if self.pickUpKinematicHelperNode ~= nil then
		delete(self.pickUpKinematicHelperNode)

		self.pickUpKinematicHelperNode = nil
	end

	if self.leftArmToolNode ~= nil then
		delete(self.leftArmToolNode)

		self.leftArmToolNode = nil
	end

	if self.rightArmToolNode ~= nil then
		delete(self.rightArmToolNode)

		self.rightArmToolNode = nil
	end

	if self.particleSystemsInformation.swimNode ~= nil then
		delete(self.particleSystemsInformation.swimNode)
	end

	if self.particleSystemsInformation.plungeNode ~= nil then
		delete(self.particleSystemsInformation.plungeNode)
	end

	ParticleUtil.deleteParticleSystem(self.particleSystemsInformation.systems.swim)
	ParticleUtil.deleteParticleSystem(self.particleSystemsInformation.systems.plunge)

	if self.thirdPersonSpineNode ~= nil then
		delete(self.thirdPersonSpineNode)
	end

	for chainId, _ in pairs(self.ikChains) do
		IKUtil.deleteIKChain(self.ikChains, chainId)
	end

	if self.isRealPlayer and Platform.hasPlayer then
		for _, sample in pairs(self.soundInformation.samples) do
			g_soundManager:deleteSample(sample)
		end

		g_soundManager:deleteSamples(self.soundInformation.surfaceSounds)
	end

	if self.rootNode ~= nil then
		delete(self.rootNode)

		self.rootNode = nil
	end

	if self.lightNode ~= nil and entityExists(self.lightNode) then
		delete(self.lightNode)

		self.lightNode = nil
	end

	if self.animationInformation.player ~= 0 then
		delete(self.animationInformation.player)

		self.animationInformation.player = 0
	end
end

function PlayerModel:loadEmpty()
	self.rootNode = createTransformGroup("model_rootNode_dummy")

	link(getRootNode(), self.rootNode)

	self.firstPersonCameraTarget = createTransformGroup("camera_target_dummpy")

	link(self.rootNode, self.firstPersonCameraTarget)
	setTranslation(self.firstPersonCameraTarget, 0, 1.7, 0)
end

function PlayerModel:load(xmlFilename, isRealPlayer, isOwner, isAnimated, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	self.xmlFilename = xmlFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)
	local xmlFile = loadXMLFile("playerXML", xmlFilename)

	if xmlFile == 0 then
		return asyncCallbackFunction(asyncCallbackObject, false, asyncCallbackArguments)
	end

	local filename = getXMLString(xmlFile, "player.filename")
	self.filename = Utils.getFilename(filename, self.baseDirectory)
	self.isRealPlayer = isRealPlayer
	self.asyncLoadCallbackArguments = asyncCallbackArguments
	self.asyncLoadCallbackObject = asyncCallbackObject
	self.asyncLoadCallbackFunction = asyncCallbackFunction
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.filename, false, false, self.loadFileFinished, self, {
		isRealPlayer,
		isOwner,
		isAnimated
	})

	delete(xmlFile)
end

function PlayerModel:loadFileFinished(rootNode, failedReason, arguments)
	if rootNode == nil then
		Logging.error("Unable to load player model %s", self.filename)

		return self.asyncLoadCallbackFunction(self.asyncLoadCallbackObject, false, self.asyncLoadCallbackArguments)
	end

	local xmlFile = loadXMLFile("playerXML", self.xmlFilename)

	if xmlFile == 0 then
		return self.asyncLoadCallbackFunction(self.asyncLoadCallbackObject, false, self.asyncLoadCallbackArguments)
	end

	local isRealPlayer = arguments[1]
	local isOwner = arguments[2]
	local isAnimated = arguments[3]
	self.rootNode = rootNode

	if isRealPlayer then
		local cNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.camera#index"))

		if cNode == nil then
			Logging.devError("Error: Failed to find player camera position in '%s'", self.filename)
		end

		local x, y, z = localToLocal(cNode, rootNode, 0, 0, 0)
		local target = createTransformGroup("1p_camera_target")

		link(rootNode, target)
		setTranslation(target, x, y, z)

		self.firstPersonCameraTarget = target
	end

	if isRealPlayer then
		self.animRootThirdPerson = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#animRootNode"))

		if self.animRootThirdPerson == nil then
			Logging.devError("Error: Failed to find animation root node in '%s'", self.filename)

			return self.asyncLoadCallbackFunction(self.asyncLoadCallbackObject, false, self.asyncLoadCallbackArguments)
		end

		self.capsuleHeight = getXMLFloat(xmlFile, "player.character#physicsCapsuleHeight")
		self.capsuleRadius = getXMLFloat(xmlFile, "player.character#physicsCapsuleRadius")
		self.capsuleTotalHeight = self.capsuleHeight + self.capsuleRadius * 2
	end

	self.style = PlayerStyle.new()
	self.skeleton = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#skeleton"))

	if self.skeleton == nil then
		Logging.devError("Error: Failed to find skeleton root node in '%s'", self.filename)
	end

	self.mesh = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#mesh"))

	if self.mesh == nil then
		Logging.devError("Error: Failed to find player mesh in '%s'", self.filename)
	end

	self.thirdPersonSpineNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#spine"))
	self.thirdPersonSuspensionNode = Utils.getNoNil(I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#suspension")), self.thirdPersonSpineNode)
	self.thirdPersonRightHandNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#rightHandNode"))
	self.thirdPersonLeftHandNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#leftHandNode"))
	self.thirdPersonHeadNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.character.thirdPerson#headNode"))
	self.lightNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.light#index"))

	if self.lightNode ~= nil then
		setVisibility(self.lightNode, false)
	end

	if self.mesh ~= nil then
		setClipDistance(self.mesh, 200)
	end

	local pickUpKinematicHelperNode = I3DUtil.indexToObject(rootNode, getXMLString(xmlFile, "player.pickUpKinematicHelper#index"))

	if pickUpKinematicHelperNode ~= nil then
		if getRigidBodyType(pickUpKinematicHelperNode) == RigidBodyType.KINEMATIC then
			self.pickUpKinematicHelperNode = pickUpKinematicHelperNode
			self.pickUpKinematicHelperNodeChild = createTransformGroup("pickUpKinematicHelperNodeChild")

			link(self.pickUpKinematicHelperNode, self.pickUpKinematicHelperNodeChild)
			addToPhysics(self.pickUpKinematicHelperNode)
		else
			Logging.xmlWarning(xmlFile, "Given pickUpKinematicHelper '%s' is not a kinematic object", getName(pickUpKinematicHelperNode))
		end
	end

	self:loadIKChains(xmlFile, rootNode, isRealPlayer)

	if isAnimated and self.skeleton ~= nil and getNumOfChildren(self.skeleton) > 0 then
		local animNode = g_animCache:getNode(AnimationCache.CHARACTER)

		cloneAnimCharacterSet(animNode, getParent(self.skeleton))

		local animCharsetId = getAnimCharacterSet(getChildAt(self.skeleton, 0))
		self.animationInformation.player = createConditionalAnimation()

		for key, parameter in pairs(self.animationInformation.parameters) do
			conditionalAnimationRegisterParameter(self.animationInformation.player, parameter.id, parameter.type, key)
		end

		initConditionalAnimation(self.animationInformation.player, animCharsetId, self.xmlFilename, "player.conditionalAnimation")
		setConditionalAnimationSpecificParameterIds(self.animationInformation.player, self.animationInformation.parameters.absForwardVelocity.id, self.animationInformation.parameters.yawVelocity.id)
	end

	if isRealPlayer then
		self.skeletonRootNode = createTransformGroup("player_skeletonRootNode")

		link(getRootNode(), self.rootNode)
		link(self.rootNode, self.skeletonRootNode)

		if self.animRootThirdPerson ~= nil then
			link(self.skeletonRootNode, self.animRootThirdPerson)

			if self.skeleton ~= nil then
				link(self.animRootThirdPerson, self.skeleton)
			end
		end

		self.leftArmToolNode = createTransformGroup("leftArmToolNode")
		self.rightArmToolNode = createTransformGroup("rightArmToolNode")

		if isOwner then
			local toolRotation = string.getVectorN(Utils.getNoNil(getXMLString(xmlFile, "player.character.toolNode#firstPersonRotation"), "0 0 0"), 3)
			local rotX, rotY, rotZ = unpack(toolRotation)

			setRotation(self.rightArmToolNode, math.rad(rotX), math.rad(rotY), math.rad(rotZ))

			local toolTranslate = string.getVectorN(Utils.getNoNil(getXMLString(xmlFile, "player.character.toolNode#firstPersonTranslation"), "0 0 0"), 3)
			local transX, transY, transZ = unpack(toolTranslate)

			setTranslation(self.rightArmToolNode, transX, transY, transZ)
		else
			local toolRotationR = string.getVectorN(Utils.getNoNil(getXMLString(xmlFile, "player.character.toolNode#thirdPersonRightNodeRotation"), "0 0 0"), 3)
			local rotRX, rotRY, rotRZ = unpack(toolRotationR)

			setRotation(self.rightArmToolNode, math.rad(rotRX), math.rad(rotRY), math.rad(rotRZ))

			local toolTranslateR = string.getVectorN(Utils.getNoNil(getXMLString(xmlFile, "player.character.toolNode#thirdPersonRightNodeTranslation"), "0 0 0"), 3)
			local transRX, transRY, transRZ = unpack(toolTranslateR)

			setTranslation(self.rightArmToolNode, transRX, transRY, transRZ)
			link(self.thirdPersonRightHandNode, self.rightArmToolNode)

			local toolRotationL = string.getVectorN(Utils.getNoNil(getXMLString(xmlFile, "player.character.toolNode#thirdPersonLeftNodeRotation"), "0 0 0"), 3)
			local rotLX, rotLY, rotLZ = unpack(toolRotationL)

			setRotation(self.leftArmToolNode, math.rad(rotLX), math.rad(rotLY), math.rad(rotLZ))

			local toolTranslateL = string.getVectorN(Utils.getNoNil(getXMLString(xmlFile, "player.character.toolNode#thirdPersonLeftNodeTranslation"), "0 0 0"), 3)
			local transLX, transLY, transLZ = unpack(toolTranslateL)

			setTranslation(self.leftArmToolNode, transLX, transLY, transLZ)
			link(self.thirdPersonLeftHandNode, self.leftArmToolNode)
			link(self.thirdPersonHeadNode, self.lightNode)

			local lightRotation = string.getVectorN(Utils.getNoNil(getXMLString(xmlFile, "player.light#thirdPersonRotation"), "0 0 0"), 3)
			local lightRotX, lightRotY, lightRotZ = unpack(lightRotation)
			local lightTranslate = string.getVectorN(Utils.getNoNil(getXMLString(xmlFile, "player.light#thirdPersonTranslation"), "0 0 0"), 3)
			local lightTransX, lightTransY, lightTransZ = unpack(lightTranslate)

			setRotation(self.lightNode, math.rad(lightRotX), math.rad(lightRotY), math.rad(lightRotZ))
			setTranslation(self.lightNode, lightTransX, lightTransY, lightTransZ)
		end

		self.particleSystemsInformation.swimNode = createTransformGroup("swimFXNode")

		link(getRootNode(), self.particleSystemsInformation.swimNode)

		self.particleSystemsInformation.plungeNode = createTransformGroup("plungeFXNode")

		link(getRootNode(), self.particleSystemsInformation.plungeNode)
		ParticleUtil.loadParticleSystem(xmlFile, self.particleSystemsInformation.systems.swim, "player.particleSystems.swim", self.particleSystemsInformation.swimNode, false, nil, self.baseDirectory)
		ParticleUtil.loadParticleSystem(xmlFile, self.particleSystemsInformation.systems.plunge, "player.particleSystems.plunge", self.particleSystemsInformation.plungeNode, false, nil, self.baseDirectory)
	else
		link(self.rootNode, self.skeleton)

		if self.pickUpKinematicHelperNode ~= nil then
			delete(self.pickUpKinematicHelperNode)

			self.pickUpKinematicHelperNode = nil
		end

		if self.lightNode ~= nil then
			delete(self.lightNode)

			self.lightNode = nil
		end

		local offset = {
			localToLocal(self.thirdPersonSpineNode, self.skeleton, 0, 0, 0)
		}

		setTranslation(self.skeleton, -offset[1], -offset[2], -offset[3])
	end

	if isRealPlayer and Platform.hasPlayer then
		self:loadSounds(xmlFile, isOwner)
	end

	delete(xmlFile)

	self.isLoaded = true

	return self.asyncLoadCallbackFunction(self.asyncLoadCallbackObject, true, self.asyncLoadCallbackArguments)
end

function PlayerModel:loadIKChains(xmlFile, rootNode, isRealPlayer)
	self.ikChains = {}
	local i = 0

	while true do
		local key = string.format("player.ikChains.ikChain(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		IKUtil.loadIKChain(xmlFile, key, rootNode, rootNode, self.ikChains)

		i = i + 1
	end

	IKUtil.setIKChainInactive(self.ikChains, "spine")

	if isRealPlayer then
		IKUtil.deleteIKChain(self.ikChains, "rightFoot")
		IKUtil.deleteIKChain(self.ikChains, "leftFoot")
		IKUtil.deleteIKChain(self.ikChains, "rightArm")
		IKUtil.deleteIKChain(self.ikChains, "leftArm")
		IKUtil.deleteIKChain(self.ikChains, "spine")
	end
end

function PlayerModel:loadSounds(xmlFile, isOwner)
	local si = self.soundInformation
	si.surfaceSounds = {}
	si.surfaceIdToSound = {}
	si.surfaceNameToSound = {}
	si.currentSurfaceSound = nil

	if not isOwner then
		for _, surfaceSound in pairs(g_currentMission.surfaceSounds) do
			if surfaceSound.type == "footstep" and surfaceSound.sample ~= nil then
				local sample = g_soundManager:cloneSample(surfaceSound.sample, self.rootNode, self)
				sample.sampleName = surfaceSound.name

				table.insert(si.surfaceSounds, sample)

				si.surfaceIdToSound[surfaceSound.materialId] = sample
				si.surfaceNameToSound[surfaceSound.name] = sample
			end
		end

		si.samples.swim = g_soundManager:loadSampleFromXML(xmlFile, "player.sounds.water", "swim", self.baseDirectory, self.rootNode, 0, AudioGroup.ENVIRONMENT, nil, )
		si.samples.swimIdle = g_soundManager:loadSampleFromXML(xmlFile, "player.sounds.water", "swimIdle", self.baseDirectory, self.rootNode, 0, AudioGroup.ENVIRONMENT, nil, )
		si.samples.plunge = g_soundManager:loadSampleFromXML(xmlFile, "player.sounds.water", "plunge", self.baseDirectory, self.rootNode, 1, AudioGroup.ENVIRONMENT, nil, )
		si.samples.flashlight = g_soundManager:loadSampleFromXML(xmlFile, "player.sounds.tools", "flashlight", self.baseDirectory, self.rootNode, 1, AudioGroup.ENVIRONMENT, nil, )
		si.samples.horseBrush = g_soundManager:loadSampleFromXML(xmlFile, "player.sounds.tools", "horseBrush", self.baseDirectory, self.rootNode, 1, AudioGroup.ENVIRONMENT, nil, )
		si.samples.jump = g_soundManager:loadSampleFromXML(xmlFile, "player.sounds.jump", "takeoff", self.baseDirectory, self.rootNode, 0, AudioGroup.ENVIRONMENT, nil, )
		si.samples.touchGround = g_soundManager:loadSampleFromXML(xmlFile, "player.sounds.jump", "landing", self.baseDirectory, self.rootNode, 0, AudioGroup.ENVIRONMENT, nil, )
	else
		for _, surfaceSound in pairs(g_currentMission.surfaceSounds) do
			if surfaceSound.type == "footstep" and surfaceSound.sample ~= nil then
				local sample = g_soundManager:cloneSample2D(surfaceSound.sample, self)
				sample.sampleName = surfaceSound.name

				table.insert(si.surfaceSounds, sample)

				si.surfaceIdToSound[surfaceSound.materialId] = sample
				si.surfaceNameToSound[surfaceSound.name] = sample
			end
		end

		si.samples = {
			swim = g_soundManager:loadSample2DFromXML(xmlFile, "player.sounds.water", "swim", self.baseDirectory, 0, AudioGroup.ENVIRONMENT),
			swimIdle = g_soundManager:loadSample2DFromXML(xmlFile, "player.sounds.water", "swimIdle", self.baseDirectory, 0, AudioGroup.ENVIRONMENT),
			plunge = g_soundManager:loadSample2DFromXML(xmlFile, "player.sounds.water", "plunge", self.baseDirectory, 1, AudioGroup.ENVIRONMENT),
			flashlight = g_soundManager:loadSample2DFromXML(xmlFile, "player.sounds.tools", "flashlight", self.baseDirectory, 1, AudioGroup.ENVIRONMENT),
			horseBrush = g_soundManager:loadSample2DFromXML(xmlFile, "player.sounds.tools", "horseBrush", self.baseDirectory, 1, AudioGroup.ENVIRONMENT),
			jump = g_soundManager:loadSample2DFromXML(xmlFile, "player.sounds.jump", "takeoff", self.baseDirectory, 0, AudioGroup.ENVIRONMENT),
			touchGround = g_soundManager:loadSample2DFromXML(xmlFile, "player.sounds.jump", "landing", self.baseDirectory, 0, AudioGroup.ENVIRONMENT),
			handtoolStop = {}
		}
	end

	si.distancePerFootstep.crouch = Utils.getNoNil(getXMLFloat(xmlFile, "player.sounds.footsteps#distancePerFootstepCrouch"), 0.5)
	si.distancePerFootstep.walk = Utils.getNoNil(getXMLFloat(xmlFile, "player.sounds.footsteps#distancePerFootstepWalk"), 0.75)
	si.distancePerFootstep.run = Utils.getNoNil(getXMLFloat(xmlFile, "player.sounds.footsteps#distancePerFootstepRun"), 1.5)
end

function PlayerModel:readStream(streamId, connection)
end

function PlayerModel:writeStream(streamId, connection)
end

function PlayerModel:setVisibility(isVisible)
	setVisibility(self.rootNode, isVisible)
end

function PlayerModel:getCapsuleSize()
	return self.capsuleRadius, self.capsuleHeight
end

function PlayerModel:getRootNode()
	return self.rootNode
end

function PlayerModel:setIKDirty()
	IKUtil.setIKChainDirty(self.ikChains, "rightFoot")
	IKUtil.setIKChainDirty(self.ikChains, "leftFoot")
	IKUtil.setIKChainDirty(self.ikChains, "rightArm")
	IKUtil.setIKChainDirty(self.ikChains, "leftArm")
	IKUtil.setIKChainDirty(self.ikChains, "spine")
end

function PlayerModel:getIKChains()
	return self.ikChains
end

function PlayerModel:enableTorch(enabled, playSound)
	if self.lightNode ~= nil then
		setVisibility(self.lightNode, enabled)

		if playSound then
			g_soundManager:playSample(self.soundInformation.samples.flashlight)
		end
	end
end

function PlayerModel:linkTorchToCamera(camera)
	if self.lightNode ~= nil then
		link(camera, self.lightNode)
	end
end

function PlayerModel:linkRightHandToCamera(camera)
	if self.rightArmToolNode ~= nil then
		if camera == nil then
			link(getRootNode(), self.rightArmToolNode)
		else
			link(camera, self.rightArmToolNode)
		end
	end
end

function PlayerModel:getHasTorch()
	return self.lightNode ~= nil
end

function PlayerModel:applyCustomWorkStyle(presetName)
	local preset = nil

	if presetName ~= nil then
		preset = self.style:getPresetByName(presetName)
	end

	if self.baseStyle ~= nil then
		if preset ~= nil then
			local tempStyle = PlayerStyle.new()

			tempStyle:copyFrom(self.baseStyle)
			tempStyle:setPreset(preset)
			self:setStyle(tempStyle, true, nil)
		else
			self:setStyle(self.baseStyle, false, nil)
		end
	end
end

function PlayerModel:setStyle(playerStyle, isTempStyle, callback)
	if not isTempStyle then
		self.baseStyle = PlayerStyle.new()

		self.baseStyle:copyFrom(playerStyle)
	end

	if playerStyle.xmlFilename ~= self.xmlFilename then
		Logging.error("Can't set player style with different filename to player model")

		return
	end

	if self.setStyleFinishCallback ~= nil then
		self.setStyleFinishCallback(false)
	end

	self.setStyleFinishCallback = callback

	self.style:copyFrom(playerStyle)

	local oldIds = self.sharedLoadRequestIds
	self.sharedLoadRequestIds = {}

	for filename, node in pairs(self.modelParts) do
		delete(node)

		self.modelParts[filename] = nil
	end

	self.filesToLoad = {}
	local required = playerStyle:getRequiredNodeFiles()

	for _, filename in ipairs(required) do
		if self.sharedLoadRequestIds[filename] == nil then
			local args = {
				filename = filename
			}
			local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, false, true, self.onModelPartLoaded, self, args)
			self.sharedLoadRequestIds[filename] = sharedLoadRequestId
			self.filesToLoad[filename] = true
		end
	end

	for _, sharedLoadRequestId in pairs(oldIds) do
		g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
	end

	self:tryFinish()
end

function PlayerModel:setStyleFinish()
	self.style:apply(self.skeleton, self.mesh, nil, self.modelParts)

	for filename, node in pairs(self.modelParts) do
		delete(node)

		self.modelParts[filename] = nil
	end

	if self.setStyleFinishCallback ~= nil then
		local cb = self.setStyleFinishCallback
		self.setStyleFinishCallback = nil

		cb(true)
	end
end

function PlayerModel:onModelPartLoaded(node, failedReason, args)
	local filename = args.filename
	self.filesToLoad[filename] = nil
	self.modelParts[filename] = node

	self:tryFinish()
end

function PlayerModel:tryFinish()
	if next(self.filesToLoad) == nil then
		self:setStyleFinish()
	end
end

function PlayerModel:getStyle(currentStyle)
	if currentStyle then
		return self.style
	end

	return self.baseStyle or self.style
end

function PlayerModel:getLastForwardVelocity()
	if self.animationInformation.player ~= 0 then
		return getConditionalAnimationFloatValue(self.animationInformation.player, self.animationInformation.parameters.absForwardVelocity.id)
	else
		return 0
	end
end

function PlayerModel:setSkeletonRotation(yRot)
	if self.skeletonRootNode ~= nil then
		setRotation(self.skeletonRootNode, 0, yRot, 0)
	end
end

function PlayerModel:getKinematicHelpers()
	return self.pickUpKinematicHelperNode, self.pickUpKinematicHelperNodeChild
end

function PlayerModel:linkKinematicHelperToCamera(camera)
	if self.pickUpKinematicHelperNode ~= nil then
		if camera == nil then
			link(self.animRootThirdPerson, self.pickUpKinematicHelperNode)
		else
			link(camera, self.pickUpKinematicHelperNode)
		end
	end
end

function PlayerModel:updateAnimations(dt)
	if self.animationInformation.player ~= 0 then
		updateConditionalAnimation(self.animationInformation.player, dt)
	end
end

function PlayerModel:setAnimationParameters(isOnGround, isInWater, isCrouched, isCloseToGround, forwardVelocity, verticalVelocity, yawVelocity)
	if not self.isLoaded then
		return
	end

	local params = self.animationInformation.parameters
	params.forwardVelocity.value = forwardVelocity
	params.verticalVelocity.value = verticalVelocity
	params.yawVelocity.value = yawVelocity
	params.absYawVelocity.value = math.abs(yawVelocity)
	params.onGround.value = isOnGround
	params.inWater.value = isInWater
	params.isCrouched.value = isCrouched
	params.absForwardVelocity.value = math.abs(forwardVelocity)
	params.isCloseToGround.value = isCloseToGround
	params.isUsingChainsawHorizontal.value = false
	params.isUsingChainsawVertical.value = false

	for _, parameter in pairs(self.animationInformation.parameters) do
		if parameter.type == 0 then
			setConditionalAnimationBoolValue(self.animationInformation.player, parameter.id, parameter.value)
		elseif parameter.type == 1 then
			setConditionalAnimationFloatValue(self.animationInformation.player, parameter.id, parameter.value)
		end
	end
end

function PlayerModel:getFirstPersonCameraTargetNode()
	return self.firstPersonCameraTarget
end

function PlayerModel:getCurrentSurfaceSound(x, y, z, waterLevel, waterY)
	local mask = CollisionFlag.STATIC_WORLD + CollisionFlag.PLAYER + CollisionFlag.ANIMAL + CollisionFlag.TERRAIN
	self.belowPlayerObject = nil

	raycastClosest(x, y + 0.5, z, 0, -1, 0, "groundRaycastCallback", 10, self, mask)

	local hitTerrain = self.belowPlayerObject == g_currentMission.terrainRootNode
	local deltaWater = y - waterY
	local shallowWater = waterLevel < deltaWater and deltaWater < 0

	if hitTerrain then
		local snowHeight = g_currentMission.snowSystem:getSnowHeightAtArea(x, z, x + 0.1, z + 0.1, x + 0.1, z)

		if snowHeight > 0 then
			return self.soundInformation.surfaceNameToSound.snow, shallowWater
		else
			local isOnField, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(x, y, z)

			if isOnField then
				return self.soundInformation.surfaceNameToSound.field, shallowWater
			elseif shallowWater then
				return self.soundInformation.surfaceNameToSound.shallowWater, shallowWater
			end
		end

		local _, _, _, _, materialId = getTerrainAttributesAtWorldPos(g_currentMission.terrainRootNode, x, y, z, true, true, true, true, false)

		return self.soundInformation.surfaceIdToSound[materialId], shallowWater
	else
		return self.soundInformation.surfaceNameToSound.asphalt, shallowWater
	end
end

function PlayerModel:groundRaycastCallback(hitObjectId, x, y, z, distance)
	self.belowPlayerObject = hitObjectId

	return false
end

function PlayerModel:setSoundParameters(forwardVel, isCrouching, isWalking, isRunning, isSwimming, isPlungedInWater, isInWater, coveredGroundDistance, maxSwimmingSpeed, waterLevel, didJump, didTouchGround, waterY)
	if not self.isLoaded then
		return
	end

	local distanceToCheck = -1
	local info = self.soundInformation

	if isCrouching then
		distanceToCheck = info.distancePerFootstep.crouch
	elseif isWalking then
		distanceToCheck = info.distancePerFootstep.walk
	elseif isRunning then
		distanceToCheck = info.distancePerFootstep.run
	end

	if distanceToCheck > 0 or isSwimming then
		local delta = coveredGroundDistance - info.distanceSinceLastFootstep
		delta = delta - distanceToCheck

		if delta > 0 or isSwimming then
			local wx, wy, wz = getWorldTranslation(self.rootNode)
			local sample, shallowWater = self:getCurrentSurfaceSound(wx, wy, wz, waterLevel, waterY)

			if not isInWater then
				if g_soundManager:getIsSamplePlaying(info.samples.swim) then
					g_soundManager:stopSample(info.samples.swim)
				end

				if g_soundManager:getIsSamplePlaying(info.samples.swimIdle) then
					g_soundManager:stopSample(info.samples.swimIdle)
				end
			end

			if isInWater and not shallowWater then
				if math.abs(forwardVel) < maxSwimmingSpeed * 0.75 then
					if g_soundManager:getIsSamplePlaying(info.samples.swim) then
						g_soundManager:stopSample(info.samples.swim)
					end

					if not g_soundManager:getIsSamplePlaying(info.samples.swimIdle) then
						g_soundManager:playSample(info.samples.swimIdle)
					end
				else
					if g_soundManager:getIsSamplePlaying(info.samples.swimIdle) then
						g_soundManager:stopSample(info.samples.swimIdle)
					end

					if not g_soundManager:getIsSamplePlaying(info.samples.swim) then
						g_soundManager:playSample(info.samples.swim)
					end
				end
			elseif sample ~= nil then
				g_soundManager:playSample(sample)
			end

			info.distanceSinceLastFootstep = coveredGroundDistance + delta
		end
	end

	if isPlungedInWater then
		g_soundManager:playSample(info.samples.plunge)
	end

	if didJump then
		g_soundManager:playSample(info.samples.jump)
	end

	if didTouchGround then
		g_soundManager:playSample(info.samples.touchGround)
	end
end

function PlayerModel:updateFX(x, y, z, isInWater, plungedInWater, waterY)
	if isInWater then
		setWorldTranslation(self.particleSystemsInformation.swimNode, x, waterY, z)
		ParticleUtil.setEmittingState(self.particleSystemsInformation.systems.swim, true)
	else
		ParticleUtil.resetNumOfEmittedParticles(self.particleSystemsInformation.systems.swim)
		ParticleUtil.setEmittingState(self.particleSystemsInformation.systems.swim, false)
	end

	if plungedInWater then
		setWorldTranslation(self.particleSystemsInformation.plungeNode, x, waterY, z)
		ParticleUtil.resetNumOfEmittedParticles(self.particleSystemsInformation.systems.plunge)
		ParticleUtil.setEmittingState(self.particleSystemsInformation.systems.plunge, true)
	end
end
