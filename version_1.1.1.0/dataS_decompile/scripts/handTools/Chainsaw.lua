Chainsaw = {}
local Chainsaw_mt = Class(Chainsaw, HandTool)

InitStaticObjectClass(Chainsaw, "Chainsaw", ObjectIds.OBJECT_CHAINSAW)

Chainsaw.CAMERA_TRANSITION_STATES = {
	CUT = 1,
	IN = 0,
	OUT = 2,
	NONE = -1
}
Chainsaw.SOUND_STATES = {
	CUT = 5,
	START = 1,
	IDLE = 3,
	QUICKTAP = 6,
	STOP = 2,
	ACTIVE = 4
}

g_xmlManager:addInitSchemaFunction(function ()
	local schema = HandTool.xmlSchema

	schema:setXMLSpecializationType("Chainsaw")
	schema:register(XMLValueType.FLOAT, "handTool.chainsaw.pricePerMinute", "Price per minute", 50)
	schema:register(XMLValueType.FLOAT, "handTool.chainsaw#quicktapThreshold", "Quick tab time threshold", 0)
	schema:register(XMLValueType.VECTOR_3, "handTool.chainsaw.cutAnimation#cutFocusOffset", "Offset for cutting focus point", "0 0 -1")
	schema:register(XMLValueType.VECTOR_3, "handTool.chainsaw.cutAnimation#cutFocusRotation", "Rotation for cutting focus point", "0 0 0")
	schema:register(XMLValueType.FLOAT, "handTool.chainsaw.targetSelection#minCutDistance", "Minimum cut distance", 0.5)
	schema:register(XMLValueType.FLOAT, "handTool.chainsaw.targetSelection#maxCutDistance", "Maxium cut distance", 1)
	schema:register(XMLValueType.FLOAT, "handTool.chainsaw.targetSelection#cutDetectionDistance", "Cut detection distance", 10)
	schema:register(XMLValueType.NODE_INDEX, "handTool.chainsaw.particleSystems.emitterShape(?)#node", "Emitter shape", 0)
	schema:register(XMLValueType.STRING, "handTool.chainsaw.particleSystems.emitterShape(?)#particleType", "Particle type")
	schema:register(XMLValueType.VECTOR_2, "handTool.chainsaw.equipment#uvs", "Equipment uvs", "0 0")
	schema:register(XMLValueType.STRING, "handTool.chainsaw.ringSelector#file", "Ring selector i3d file")
	schema:register(XMLValueType.FLOAT, "handTool.chainsaw.ringSelector#scaleOffset", "Ring selector scale offset", 0.3)
	schema:register(XMLValueType.VECTOR_TRANS, "handTool.handNode.thirdPersonCutting#position", "Third person cutting position", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, "handTool.handNode.thirdPersonCutting#rotation", "Third person cutting rotation", "0 0 0")
	schema:register(XMLValueType.NODE_INDEX, "handTool.handNode.thirdPersonCutting#referenceNode", "Third person cutting reference node")
	AnimationManager.registerAnimationNodesXMLPaths(schema, "handTool.chainsaw.chain")
	SoundManager.registerSampleXMLPaths(schema, "handTool.chainsaw.sounds", "start")
	SoundManager.registerSampleXMLPaths(schema, "handTool.chainsaw.sounds", "idle")
	SoundManager.registerSampleXMLPaths(schema, "handTool.chainsaw.sounds", "cutStart")
	SoundManager.registerSampleXMLPaths(schema, "handTool.chainsaw.sounds", "cutStop")
	SoundManager.registerSampleXMLPaths(schema, "handTool.chainsaw.sounds", "cutLoop")
	SoundManager.registerSampleXMLPaths(schema, "handTool.chainsaw.sounds", "activeStart")
	SoundManager.registerSampleXMLPaths(schema, "handTool.chainsaw.sounds", "activeStop")
	SoundManager.registerSampleXMLPaths(schema, "handTool.chainsaw.sounds", "activeLoop")
	SoundManager.registerSampleXMLPaths(schema, "handTool.chainsaw.sounds", "stop")
	SoundManager.registerSampleXMLPaths(schema, "handTool.chainsaw.sounds.quickTapSounds", "quickTap(?)")
	SoundManager.registerSampleXMLPaths(schema, "handTool.chainsaw.treeSounds", "cut(?)")
	SoundManager.registerSampleXMLPaths(schema, "handTool.chainsaw.branchSounds", "branch(?)")
	ParticleUtil.registerParticleCopyXMLPaths(schema, "handTool.chainsaw.particleSystems.emitterShape(?)")
	schema:setXMLSpecializationType()
end)

function Chainsaw.new(isServer, isClient, customMt)
	local self = HandTool.new(isServer, isClient, customMt or Chainsaw_mt)

	return self
end

function Chainsaw:postLoad(xmlFile)
	if not Chainsaw:superClass().postLoad(self, xmlFile) then
		return false
	end

	self.rotateInput = 0
	self.activatePressed = false
	self.eventIdRotateHandtool = ""
	self.rotationZ = 0
	self.rotationSpeedZ = 0.003
	self.cutSizeY = 1.1
	self.cutSizeZ = 1
	self.isCutting = false
	self.waitingForResetAfterCut = false
	self.cutNode = getChildAt(self.rootNode, 0)
	self.graphicsNode = getChildAt(self.cutNode, 0)
	self.chainNode = getChildAt(self.graphicsNode, 0)
	self.psNode = getChildAt(self.graphicsNode, 1)
	self.cutPositionNode = getChildAt(self.graphicsNode, 5)
	self.pricePerSecond = xmlFile:getValue("handTool.chainsaw.pricePerMinute", 50) / 1000
	self.quicktapThreshold = xmlFile:getValue("handTool.chainsaw#quicktapThreshold", 0) * 1000
	self.minCutDistance = xmlFile:getValue("handTool.chainsaw.targetSelection#minCutDistance", 0.5)
	self.maxCutDistance = xmlFile:getValue("handTool.chainsaw.targetSelection#maxCutDistance", 1)
	self.cutDetectionDistance = xmlFile:getValue("handTool.chainsaw.targetSelection#cutDetectionDistance", 10)

	if self.isClient then
		self.particleSystems = {}

		xmlFile:iterate("handTool.chainsaw.particleSystems.emitterShape", function (_, key)
			local emitterShape = xmlFile:getValue(key .. "#node", nil, self.rootNode)
			local particleType = xmlFile:getValue(key .. "#particleType")

			if emitterShape ~= nil then
				local fillType = FillType.WOODCHIPS
				local particleSystem = g_particleSystemManager:getParticleSystem(particleType)

				if particleSystem ~= nil then
					local material = g_materialManager:getParticleMaterial(fillType, particleType, 1)

					if material ~= nil then
						ParticleUtil.setMaterial(particleSystem, material)
					end

					table.insert(self.particleSystems, ParticleUtil.copyParticleSystem(xmlFile, key, particleSystem, emitterShape))
				end
			end
		end)

		if #self.particleSystems == 0 then
			self.particleSystems = nil
		end

		self.equipmentUVs = xmlFile:getValue("handTool.chainsaw.equipment#uvs", "0 0", true)
		self.chains = g_animationManager:loadAnimations(xmlFile, "handTool.chainsaw.chain", self.rootNode, self, nil)
		self.samples = {
			start = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "start", self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, ),
			idle = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "idle", self.baseDirectory, self.rootNode, 0, AudioGroup.VEHICLE, nil, ),
			cutStart = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "cutStart", self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, ),
			cutStop = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "cutStop", self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, ),
			cutLoop = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "cutLoop", self.baseDirectory, self.rootNode, 0, AudioGroup.VEHICLE, nil, ),
			activeStart = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "activeStart", self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, ),
			activeStop = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "activeStop", self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, ),
			activeLoop = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "activeLoop", self.baseDirectory, self.rootNode, 0, AudioGroup.VEHICLE, nil, ),
			stop = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds", "stop", self.baseDirectory, self.rootNode, 0, AudioGroup.VEHICLE, nil, )
		}
		self.samplesQuicktap = {}
		local j = 0

		while true do
			local sampleQuicktap = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.sounds.quickTapSounds", string.format("quickTap(%d)", j), self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, )

			if sampleQuicktap == nil then
				break
			end

			table.insert(self.samplesQuicktap, sampleQuicktap)

			j = j + 1
		end

		self.samplesQuicktapCount = j
		self.samplesTree = {
			cut = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.treeSounds", "cut", self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, )
		}
		self.samplesBranch = {}
		local k = 0

		while true do
			local sampleBranch = g_soundManager:loadSampleFromXML(xmlFile, "handTool.chainsaw.branchSounds", string.format("branch(%d)", k), self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, )

			if sampleBranch == nil then
				break
			end

			table.insert(self.samplesBranch, sampleBranch)

			k = k + 1
		end

		self.samplesBranchCount = k
		self.samplesBranchActiveTimer = 0
		self.samplesTreeLinkNode = createTransformGroup("cutSoundLinkNode")

		link(self.cutNode, self.samplesTreeLinkNode)

		if self.samplesTree.cut ~= nil and self.samplesTree.cut.soundNode ~= nil then
			link(self.samplesTreeLinkNode, self.samplesTree.cut.soundNode)
		end

		self.soundFSM = FSMUtil.create()

		self.soundFSM:addState(Chainsaw.SOUND_STATES.START, ChainsawSoundStateStart.new(Chainsaw.SOUND_STATES.START, self, self.soundFSM))
		self.soundFSM:addState(Chainsaw.SOUND_STATES.STOP, ChainsawSoundStateStop.new(Chainsaw.SOUND_STATES.STOP, self, self.soundFSM))
		self.soundFSM:addState(Chainsaw.SOUND_STATES.IDLE, ChainsawSoundStateIdle.new(Chainsaw.SOUND_STATES.IDLE, self, self.soundFSM))
		self.soundFSM:addState(Chainsaw.SOUND_STATES.ACTIVE, ChainsawSoundStateActive.new(Chainsaw.SOUND_STATES.ACTIVE, self, self.soundFSM))
		self.soundFSM:addState(Chainsaw.SOUND_STATES.CUT, ChainsawSoundStateCut.new(Chainsaw.SOUND_STATES.CUT, self, self.soundFSM))
		self.soundFSM:addState(Chainsaw.SOUND_STATES.QUICKTAP, ChainsawSoundStateQuicktap.new(Chainsaw.SOUND_STATES.QUICKTAP, self, self.soundFSM))

		self.ringSelectorScaleOffset = xmlFile:getValue("handTool.chainsaw.ringSelector#scaleOffset", 0.3)
		self.rotationNode = createTransformGroup("chainsaw_rotationNode")

		link(getRootNode(), self.rotationNode)

		self.chainsawCameraFocus = createTransformGroup("chainsaw_cameraFocus")

		link(self.rotationNode, self.chainsawCameraFocus)

		self.chainsawSplitShapeFocus = createTransformGroup("chainsaw_splitShapeFocus")

		link(self.chainsawCameraFocus, self.chainsawSplitShapeFocus)

		local cutFocusOffset = xmlFile:getVector("handTool.chainsaw.cutAnimation#cutFocusOffset", "0 0 -1", 3)

		setTranslation(self.chainsawSplitShapeFocus, unpack(cutFocusOffset))

		local cutFocusRotation = xmlFile:getVector("handTool.chainsaw.cutAnimation#cutFocusRotation", "0 0 0", 3)
		local rotX, rotY, rotZ = unpack(cutFocusRotation)

		setRotation(self.chainsawSplitShapeFocus, math.rad(rotX), math.rad(rotY), math.rad(rotZ))

		local filename = xmlFile:getValue("handTool.chainsaw.ringSelector#file")

		if filename ~= nil then
			filename = Utils.getFilename(filename, self.baseDirectory)

			g_i3DManager:pinSharedI3DFileInCache(filename)

			self.sharedLoadRequestIdRingSelector = g_i3DManager:loadSharedI3DFileAsync(filename, false, false, self.onRingSelectorLoaded, self, self.player)
		end
	end

	if self.player ~= g_currentMission.player then
		self.handNodePositionInCutting = xmlFile:getValue("handTool.handNode.thirdPersonCutting#position", "0 0 0", true)
		self.handNodeRotationInCutting = xmlFile:getValue("handTool.handNode.thirdPersonCutting#rotation", "0 0 0", true)
		self.referenceNodeInCutting = xmlFile:getValue("handTool.handNode.thirdPersonCutting#referenceNode", nil, self.rootNode)
	end

	self.lastWorkTime = 0
	self.maxWorkTime = 300
	self.moveSpeedY = 0.0001
	self.speedFactor = 0
	self.defaultCutDuration = 8
	self.maxTrunkWidthSq = 1
	self.outDuration = 0.15
	self.inDuration = 0.15
	self.cutTimer = 0
	self.outTimer = self.outDuration
	self.transitionAlpha = 0
	self.cameraTransitionState = Chainsaw.CAMERA_TRANSITION_STATES.NONE
	self.minRotationZ = math.rad(90)
	self.maxRotationZ = math.rad(-90)
	self.maxModelTranslation = 0
	self.cutFocusDistance = -1
	self.startCameraDirectionY = {
		0,
		1,
		0
	}
	self.startCameraDirectionZ = {
		0,
		0,
		1
	}
	self.endCameraDirectionY = {
		0,
		1,
		0
	}
	self.endCameraDirectionZ = {
		0,
		0,
		1
	}
	self.startChainsawPosition = {
		0,
		0,
		0
	}
	self.endChainsawPosition = {
		0,
		0,
		0
	}
	self.showNotOwnedWarning = false
	self.isCutting = false
	self.isHorizontalCut = false

	return true
end

function Chainsaw:delete()
	if self.isClient then
		ParticleUtil.deleteParticleSystems(self.particleSystems)
		g_soundManager:deleteSamples(self.samplesTree)
		g_soundManager:deleteSamples(self.samplesBranch)
		g_soundManager:deleteSamples(self.samples)
		g_soundManager:deleteSamples(self.samplesQuicktap)
		g_animationManager:deleteAnimations(self.chains)

		if self.ringSelector ~= nil then
			delete(self.ringSelector)

			self.ringSelector = nil
		end

		if self.chainsawCameraFocus ~= nil then
			delete(self.chainsawCameraFocus)
		end

		if self.sharedLoadRequestIdRingSelector ~= nil then
			g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestIdRingSelector)

			self.sharedLoadRequestIdRingSelector = nil
		end
	end

	Chainsaw:superClass().delete(self)

	if self.rotationNode ~= nil then
		delete(self.rotationNode)
	end
end

function Chainsaw:cutRaycastCallback(hitObjectId, x, y, z, distance)
	setWorldTranslation(self.chainsawCameraFocus, x, y, z)

	self.cutFocusDistance = distance
end

function Chainsaw:updateCutRaycast()
	self.cutFocusDistance = -1

	setTranslation(self.chainsawCameraFocus, 0, 0, 0)

	local x, y, z = getWorldTranslation(self.player.cameraNode)
	local dx, dy, dz = unProject(0.52, 0.4, 1)
	dx, dy, dz = MathUtil.vector3Normalize(dx, dy, dz)
	local treeCollisionMask = 16789504

	raycastClosest(x, y, z, dx, dy, dz, "cutRaycastCallback", self.cutDetectionDistance, self, treeCollisionMask)
end

function Chainsaw:testTooLow(shape, minY, maxY, minZ, maxZ)
	local _, a, _ = localToLocal(self.chainsawSplitShapeFocus, shape, 0, minY, minZ)
	local _, b, _ = localToLocal(self.chainsawSplitShapeFocus, shape, 0, maxY, minZ)
	local _, c, _ = localToLocal(self.chainsawSplitShapeFocus, shape, 0, maxY, maxZ)
	local cutTooLow = a < 0.01 or b < 0.03 or c < 0.01

	if not cutTooLow then
		local x1, y1, z1 = localToWorld(self.chainsawSplitShapeFocus, 0, minY, minZ)
		local x2, y2, z2 = localToWorld(self.chainsawSplitShapeFocus, 0, minY, maxZ)
		local x3, y3, z3 = localToWorld(self.chainsawSplitShapeFocus, 0, maxY, minZ)
		local x4, y4, z4 = localToWorld(self.chainsawSplitShapeFocus, 0, maxY, maxZ)
		local h1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, y1, z1)
		local h2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, y2, z2)
		local h3 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x3, y3, z3)
		local h4 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x4, y4, z4)
		cutTooLow = h1 < 0.01 or h2 < 0.01 or h3 < 0.03 or h4 < 0.01
	end

	if cutTooLow then
		return true
	end

	return false
end

function Chainsaw:getLookAt(cameraNode, targetX, targetY, targetZ)
	local xx, xy, xz, yx, yy, yz, zx, zy, zz = nil
	local nodePosition = {
		getWorldTranslation(cameraNode)
	}
	local nodeUpDirection = {
		localDirectionToWorld(getParent(cameraNode), 0, -1, 0)
	}
	zx = nodePosition[1] - targetX
	zy = nodePosition[2] - targetY
	zz = nodePosition[3] - targetZ
	zx, zy, zz = MathUtil.vector3Normalize(zx, zy, zz)
	xx, xy, xz = MathUtil.crossProduct(zx, zy, zz, nodeUpDirection[1], nodeUpDirection[2], nodeUpDirection[3])
	xx, xy, xz = MathUtil.vector3Normalize(xx, xy, xz)
	yx, yy, yz = MathUtil.crossProduct(zx, zy, zz, xx, xy, xz)
	yx, yy, yz = MathUtil.vector3Normalize(yx, yy, yz)

	return yx, yy, yz, zx, zy, zz
end

function Chainsaw:getCutStartEnd()
	local selectorPosition = {
		getWorldTranslation(self.ringSelector)
	}
	local selectorScale = {
		getScale(self.ringSelector)
	}
	local cutDirection = {
		localDirectionToWorld(self.ringSelector, 0, 1, 0)
	}
	local cutStartposition = {
		selectorPosition[1] - 0.5 * selectorScale[1] * cutDirection[1],
		selectorPosition[2] - 0.5 * selectorScale[2] * cutDirection[2],
		selectorPosition[3] - 0.5 * selectorScale[3] * cutDirection[3]
	}
	local cutEndposition = {
		selectorPosition[1] + 0.5 * selectorScale[1] * cutDirection[1],
		selectorPosition[2] + 0.5 * selectorScale[2] * cutDirection[2],
		selectorPosition[3] + 0.5 * selectorScale[3] * cutDirection[3]
	}

	return cutStartposition[1], cutStartposition[2], cutStartposition[3], cutEndposition[1], cutEndposition[2], cutEndposition[3]
end

function Chainsaw:calculateCutDuration()
	local startX, startY, startZ, endX, endY, endZ = self:getCutStartEnd()
	local trunkWidthSq = MathUtil.vector3LengthSq(endX - startX, endY - startY, endZ - startZ)
	trunkWidthSq = MathUtil.clamp(trunkWidthSq, 0, self.maxTrunkWidthSq)
	local cutDuration = trunkWidthSq * self.defaultCutDuration / self.maxTrunkWidthSq

	return cutDuration
end

function Chainsaw:updateCuttingTimers(dt, isCutting)
	local dtInSec = dt * 0.001
	self.transitionAlpha = 0

	if isCutting then
		local cutDuration = self:calculateCutDuration()

		if self.cutTimer == 0 then
			self.outTimer = 0
			self.cameraTransitionState = Chainsaw.CAMERA_TRANSITION_STATES.IN
		elseif self.cutTimer == self.inDuration then
			self.cameraTransitionState = Chainsaw.CAMERA_TRANSITION_STATES.CUT
		end

		if self.cutTimer >= 0 and self.cutTimer < self.inDuration then
			self.cutTimer = math.min(self.cutTimer + dtInSec, self.inDuration)
			self.transitionAlpha = MathUtil.clamp(self.cutTimer, 0, self.inDuration) / self.inDuration
		elseif self.inDuration <= self.cutTimer and self.cutTimer < cutDuration then
			local restCutDuration = math.max(cutDuration - self.inDuration, 0)
			self.cutTimer = math.min(self.cutTimer + dtInSec, cutDuration)
			self.transitionAlpha = MathUtil.clamp(self.cutTimer - self.inDuration, 0, restCutDuration) / restCutDuration
		else
			self.transitionAlpha = 1
		end
	else
		if self.outTimer == 0 then
			self.cutTimer = 0
			self.cameraTransitionState = Chainsaw.CAMERA_TRANSITION_STATES.OUT
		end

		if self.outTimer >= 0 and self.outTimer < self.outDuration then
			self.outTimer = math.min(self.outTimer + dtInSec, self.outDuration)
			self.transitionAlpha = MathUtil.clamp(self.outTimer, 0, self.outDuration) / self.outDuration
		end
	end
end

function Chainsaw:resetTransitionState()
	if self.cameraTransitionState ~= Chainsaw.CAMERA_TRANSITION_STATES.NONE then
		self.cameraTransitionState = Chainsaw.CAMERA_TRANSITION_STATES.NONE
	end
end

function Chainsaw:updateCuttingCamera(isCutting)
end

function Chainsaw:updateChainsawModel(isCutting)
	local currentPos = {
		getWorldTranslation(self.graphicsNode)
	}

	if isCutting then
		local startPos = {}
		local endPos = {}
		startPos[1], startPos[2], startPos[3], endPos[1], endPos[2], endPos[3] = self:getCutStartEnd()

		if self.cameraTransitionState == Chainsaw.CAMERA_TRANSITION_STATES.IN then
			self.startChainsawPosition = currentPos
			self.endChainsawPosition = startPos
		elseif self.cameraTransitionState == Chainsaw.CAMERA_TRANSITION_STATES.CUT then
			self.startChainsawPosition = startPos
			self.endChainsawPosition = endPos
		end
	elseif self.cameraTransitionState == Chainsaw.CAMERA_TRANSITION_STATES.OUT then
		self.startChainsawPosition = currentPos

		setTranslation(self.graphicsNode, 0, 0, 0)

		self.endChainsawPosition = {
			getWorldTranslation(self.graphicsNode)
		}
	end

	if isCutting or self.outTimer < self.outDuration then
		local smoothPosition = {
			MathUtil.lerp(self.startChainsawPosition[1], self.endChainsawPosition[1], self.transitionAlpha),
			MathUtil.lerp(self.startChainsawPosition[2], self.endChainsawPosition[2], self.transitionAlpha),
			MathUtil.lerp(self.startChainsawPosition[3], self.endChainsawPosition[3], self.transitionAlpha)
		}
		local offset = {
			localToLocal(self.cutPositionNode, self.graphicsNode, 0, 0, 0)
		}
		local cutDirection = {
			localDirectionToWorld(self.ringSelector, 0, 0, offset[3])
		}
		local destination = {
			smoothPosition[1] - cutDirection[1],
			smoothPosition[2] - cutDirection[2],
			smoothPosition[3] - cutDirection[3]
		}
		local modelTranslation = {
			worldToLocal(getParent(self.graphicsNode), destination[1], destination[2], destination[3])
		}
		local distance = MathUtil.vector3Length(modelTranslation[1], modelTranslation[2], modelTranslation[3])

		if self.maxModelTranslation < distance then
			modelTranslation = {
				MathUtil.vector3Normalize(modelTranslation[1], modelTranslation[2], modelTranslation[3])
			}
			modelTranslation = {
				modelTranslation[1] * self.maxModelTranslation,
				modelTranslation[2] * self.maxModelTranslation,
				modelTranslation[3] * self.maxModelTranslation
			}
			local screen = {
				project(destination[1], destination[2], destination[3])
			}

			setTranslation(self.graphicsNode, modelTranslation[1], modelTranslation[2], modelTranslation[3])

			local graph = {
				getWorldTranslation(self.graphicsNode)
			}
			local screen2 = {
				project(graph[1], graph[2], graph[3])
			}
			local world2 = {
				unProject(screen[1], screen[2], screen2[3])
			}

			setWorldTranslation(self.graphicsNode, world2[1], world2[2], world2[3])
		else
			setTranslation(self.graphicsNode, modelTranslation[1], modelTranslation[2], modelTranslation[3])
		end
	else
		setTranslation(self.graphicsNode, 0, 0, 0)
	end
end

function Chainsaw:getCutShapeInformation()
	local x, y, z = getWorldTranslation(self.chainsawSplitShapeFocus)
	local nx, ny, nz = localDirectionToWorld(self.chainsawSplitShapeFocus, 1, 0, 0)
	local yx, yy, yz = localDirectionToWorld(self.chainsawSplitShapeFocus, 0, 1, 0)

	return x, y, z, nx, ny, nz, yx, yy, yz
end

function Chainsaw:update(dt, allowInput)
	Chainsaw:superClass().update(self, dt, allowInput)

	if self.isServer then
		local price = self.pricePerSecond * dt / 1000

		g_farmManager:getFarmById(self.player.farmId).stats:updateStats("expenses", price)
		g_currentMission:addMoney(-price, self.player.farmId, MoneyType.VEHICLE_RUNNING_COSTS)
	end

	local wrx, wry, wrz = getWorldRotation(self.player.cameraNode)

	setWorldRotation(self.rotationNode, wrx, wry, wrz)

	if self.isClient then
		if not self.isCutting then
			self:updateCutRaycast()
		end

		if self.showNotOwnedWarning then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"), 2000)

			self.showNotOwnedWarning = false
		end
	end

	self.shouldDelimb = false
	local lockPlayerInput = false

	if allowInput then
		local isCutting = false
		local hasBeenCut = false

		setRotation(self.graphicsNode, math.rad(math.random(-1, 1)) * 0.1, math.rad(math.random(-1, 1)) * 0.1, math.rad(-180))

		if self.curSplitShape == nil then
			lockPlayerInput = self.rotateInput ~= 0

			if self.rotateInput ~= 0 then
				self.rotationZ = MathUtil.clamp(self.rotationZ + self.rotationSpeedZ * self.rotateInput * dt, self.maxRotationZ, self.minRotationZ)

				setRotation(self.rootNode, self.handNodeRotation[1], self.handNodeRotation[2], self.handNodeRotation[3] - self.rotationZ)
				setRotation(self.chainsawCameraFocus, 0, 0, -self.rotationZ)
			end
		end

		local shape = 0

		if not self.waitingForResetAfterCut and (self.curSplitShape ~= nil or self.cutTimer == 0) then
			if self.curSplitShape == nil or not entityExists(self.curSplitShape) then
				self.curSplitShape = nil
				local x, y, z, nx, ny, nz, yx, yy, yz = self:getCutShapeInformation()
				local minY, maxY, minZ, maxZ = nil
				shape, minY, maxY, minZ, maxZ = findSplitShape(x, y, z, nx, ny, nz, yx, yy, yz, self.cutSizeY, self.cutSizeZ)

				if shape ~= nil and shape ~= 0 then
					if self:isCuttingAllowed(x, y, z) then
						self.showNotOwnedWarning = false
						local cutTooLow = self:testTooLow(shape, minY, maxY, minZ, maxZ)
						local outsideRange = self.cutFocusDistance < 0 or self.cutDetectionDistance <= self.cutFocusDistance

						if cutTooLow or outsideRange then
							self.player.walkingIsLocked = false
							self.curSplitShape = nil
							maxZ = nil
							minZ = nil
							maxY = nil
							minY = nil
							shape = 0
						end
					else
						self.showNotOwnedWarning = true
					end
				end

				self.curSplitShapeMinY = minY
				self.curSplitShapeMaxY = maxY
				self.curSplitShapeMinZ = minZ
				self.curSplitShapeMaxZ = maxZ
			else
				shape = self.curSplitShape
			end

			self:updateRingSelector(shape)
		end

		if self.activatePressed then
			self.speedFactor = math.min(self.speedFactor + dt / self.maxWorkTime, 1)

			if not self.waitingForResetAfterCut then
				local inRange = self.minCutDistance <= self.cutFocusDistance and self.cutFocusDistance < self.maxCutDistance
				self.shouldDelimb = inRange

				if (self.curSplitShape ~= nil or self.cutTimer == 0) and inRange then
					if self.curSplitShape ~= nil and entityExists(self.curSplitShape) then
						lockPlayerInput = true
						local x, y, z, nx, ny, nz, yx, yy, yz = self:getCutShapeInformation()
						local minY, maxY, minZ, maxZ = testSplitShape(self.curSplitShape, x, y, z, nx, ny, nz, yx, yy, yz, self.cutSizeY, self.cutSizeZ)

						if minY == nil then
							self.player.walkingIsLocked = false
							self.curSplitShape = nil
						else
							local cutTooLow = self:testTooLow(self.curSplitShape, minY, maxY, minZ, maxZ)

							if cutTooLow then
								self.player.walkingIsLocked = false
								self.curSplitShape = nil
							end
						end

						self.curSplitShapeMinY = minY
						self.curSplitShapeMaxY = maxY
						self.curSplitShapeMinZ = minZ
						self.curSplitShapeMaxZ = maxZ
					elseif shape ~= 0 then
						self.player.walkingIsLocked = true
						self.curSplitShape = shape
					end

					if self.curSplitShape ~= nil then
						local x, y, z, nx, ny, nz, yx, yy, yz = self:getCutShapeInformation()

						if self:isCuttingAllowed(x, y, z) then
							isCutting = true
						end

						if self.cutTimer > 0 then
							self.lastWorkTime = math.min(self.lastWorkTime, self.maxWorkTime * 0.7)
						end

						local cutDuration = self:calculateCutDuration()

						if cutDuration <= self.cutTimer then
							if g_currentMission:getIsServer() then
								ChainsawUtil.cutSplitShape(self.curSplitShape, x, y, z, nx, ny, nz, yx, yy, yz, self.cutSizeY, self.cutSizeZ, self.player.farmId)
							else
								g_client:getServerConnection():sendEvent(ChainsawCutEvent.new(self.curSplitShape, x, y, z, nx, ny, nz, yx, yy, yz, self.cutSizeY, self.cutSizeZ, self.player.farmId))
							end

							hasBeenCut = true
							self.waitingForResetAfterCut = true
							self.player.walkingIsLocked = false
							self.curSplitShape = nil
							self.curSplitShapeMinY = nil

							self:updateRingSelector(0)
						end
					end
				end
			end
		else
			self.speedFactor = math.max(self.speedFactor - dt / self.maxWorkTime, 0)
			self.waitingForResetAfterCut = false
			self.player.walkingIsLocked = false
			self.curSplitShape = nil
			self.curSplitShapeMinY = nil
			self.lastWorkTime = math.max(self.lastWorkTime - dt, 0)
			self.workUpPlayed = false
		end

		self.player:lockInput(lockPlayerInput)
		self:updateCuttingTimers(dt, isCutting)
		self:updateCuttingCamera(isCutting)
		self:updateChainsawModel(isCutting)
		self:updateDelimb()
		self:setCutting(isCutting, self.rotationZ > 0.7, hasBeenCut)
	end

	self.soundFSM:update(dt)
	self:updateParticles()

	self.rotateInput = 0
	self.activatePressed = false
end

function Chainsaw:isCuttingAllowed(x, y, z)
	return g_currentMission.accessHandler:canFarmAccessLand(self.player.farmId, x, z)
end

function Chainsaw:updateDelimb()
	if self.shouldDelimb then
		local x, y, z, nx, ny, nz, yx, yy, yz = self:getCutShapeInformation()

		if g_currentMission:getIsServer() then
			findAndRemoveSplitShapeAttachments(x, y, z, nx, ny, nz, yx, yy, yz, 0.7, self.cutSizeY, self.cutSizeZ)
		else
			g_client:getServerConnection():sendEvent(ChainsawDelimbEvent.new(self.player, x, y, z, nx, ny, nz, yx, yy, yz, false))
		end
	end
end

function Chainsaw:updateParticles()
	if self.particleSystems ~= nil then
		local active = false

		if self.isCutting and (g_currentMission.time < self.samplesBranchActiveTimer or self.curSplitShapeMinY ~= nil and self.curSplitShapeMaxY ~= nil and self.inDuration < self.cutTimer) then
			active = true
		end

		if self.isCutting and self.player.isOwner then
			active = true
		end

		for _, ps in pairs(self.particleSystems) do
			ParticleUtil.setEmittingState(ps, active)
		end
	end
end

function Chainsaw:onRingSelectorLoaded(node, failedReason, args)
	if node ~= 0 then
		if not self.isDeleted then
			self.ringSelector = getChildAt(node, 0)

			setVisibility(self.ringSelector, false)
			link(self.chainsawSplitShapeFocus, self.ringSelector)
		end

		delete(node)
	end
end

function Chainsaw:updateRingSelector(shape)
	if self.ringSelector ~= nil then
		local hasShape = shape ~= nil and shape ~= 0

		if g_woodCuttingMarkerEnabled and hasShape then
			local inDetectionRange = false
			local inCutRange = false

			if self.cutFocusDistance ~= nil and self.cutFocusDistance >= 0 and self.cutFocusDistance < self.cutDetectionDistance then
				inDetectionRange = true
				inCutRange = self.minCutDistance <= self.cutFocusDistance and self.cutFocusDistance < self.maxCutDistance
			end

			if not getVisibility(self.ringSelector) and inDetectionRange then
				local x, y, z = getWorldTranslation(self.ringSelector)

				if self:isCuttingAllowed(x, y, z) then
					setVisibility(self.ringSelector, true)
				else
					setVisibility(self.ringSelector, false)
				end
			elseif getVisibility(self.ringSelector) and not inDetectionRange then
				setVisibility(self.ringSelector, false)
			end

			if getVisibility(self.ringSelector) then
				if inCutRange then
					setShaderParameter(self.ringSelector, "colorScale", 0.395, 0.925, 0.115, 1, false)
				else
					setShaderParameter(self.ringSelector, "colorScale", 0.098, 0.45, 0.96, 1, false)
				end

				if self.curSplitShapeMinY ~= nil then
					local scale = math.max(self.curSplitShapeMaxY - self.curSplitShapeMinY + self.ringSelectorScaleOffset, self.curSplitShapeMaxZ - self.curSplitShapeMinZ + self.ringSelectorScaleOffset)

					setScale(self.ringSelector, 1, scale, scale)

					local a, b, c = localToWorld(self.chainsawSplitShapeFocus, 0, (self.curSplitShapeMinY + self.curSplitShapeMaxY) * 0.5, (self.curSplitShapeMinZ + self.curSplitShapeMaxZ) * 0.5)
					local x, y, z = worldToLocal(getParent(self.ringSelector), a, b, c)

					setTranslation(self.ringSelector, x, y, z)
				else
					setScale(self.ringSelector, 1, 1, 1)
				end
			end
		else
			setVisibility(self.ringSelector, false)
		end
	end
end

function Chainsaw:setCutting(isCutting, isHorizontalCut, hasBeenCut, noEventSend)
	ChainsawStateEvent.sendEvent(self.player, isCutting, isHorizontalCut, hasBeenCut, noEventSend)

	if not self.player.isOwner then
		self.player:setCuttingAnim(isCutting, isHorizontalCut)

		if self.isCutting ~= isCutting then
			if isCutting then
				setTranslation(self.handNode, unpack(self.handNodePositionInCutting))
				setRotation(self.handNode, unpack(self.handNodeRotationInCutting))

				if self.referenceNodeInCutting ~= nil then
					local x, y, z = getWorldTranslation(self.referenceNodeInCutting)
					x, y, z = worldToLocal(getParent(self.handNode), x, y, z)
					local a, b, c = getTranslation(self.handNode)

					setTranslation(self.handNode, a - x, b - y, c - z)
				end
			else
				setTranslation(self.handNode, unpack(self.handNodePosition))
				setRotation(self.handNode, unpack(self.handNodeRotation))

				if self.referenceNode ~= nil then
					local x, y, z = getWorldTranslation(self.referenceNode)
					x, y, z = worldToLocal(getParent(self.handNode), x, y, z)
					local a, b, c = getTranslation(self.handNode)

					setTranslation(self.handNode, a - x, b - y, c - z)
				end
			end
		end
	end

	self.isCutting = isCutting
	self.isHorizontalCut = isHorizontalCut
	self.hasBeenCut = hasBeenCut
end

function Chainsaw:getChainSpeedFactor()
	return self.speedFactor
end

function Chainsaw:onActivate(allowInput)
	Chainsaw:superClass().onActivate(self)

	self.rotationZ = 0

	setRotation(self.rootNode, self.handNodeRotation[1], self.handNodeRotation[2], self.handNodeRotation[3])
	setRotation(self.chainsawCameraFocus, 0, 0, self.rotationZ)

	self.startTime = g_currentMission.time

	if self.isClient then
		g_animationManager:startAnimations(self.chains)
	end

	self.cutTimer = 0

	setTranslation(self.graphicsNode, 0, 0, 0)
	self.soundFSM:changeState(Chainsaw.SOUND_STATES.START)
end

function Chainsaw:onDeactivate(allowInput)
	Chainsaw:superClass().onDeactivate(self)

	self.speedFactor = 0
	self.curSplitShape = nil

	self.player:lockInput(false)

	self.player.walkingIsLocked = false

	if self.isClient then
		g_animationManager:stopAnimations(self.chains)

		self.cutTimer = 0

		setTranslation(self.graphicsNode, 0, 0, 0)

		if self.particleSystems ~= nil then
			for _, ps in pairs(self.particleSystems) do
				ParticleUtil.resetNumOfEmittedParticles(ps)
				ParticleUtil.setEmittingState(ps, false)
			end
		end

		if self.ringSelector ~= nil then
			setVisibility(self.ringSelector, false)
		end
	end

	self.soundFSM:changeState(Chainsaw.SOUND_STATES.STOP)
end

function Chainsaw:registerActionEvents()
	g_inputBinding:beginActionEventsModification(Player.INPUT_CONTEXT_NAME)

	local _, eventId = g_inputBinding:registerActionEvent(InputAction.AXIS_ROTATE_HANDTOOL, self, self.onInputRotate, false, false, true, true)

	g_inputBinding:setActionEventText(eventId, g_i18n:getText("action_rotate"))

	self.eventIdRotateHandtool = eventId

	g_inputBinding:endActionEventsModification()
end

function Chainsaw:onInputRotate(_, inputValue)
	self.rotateInput = self.rotateInput + inputValue
end

function Chainsaw:isBeingUsed()
	return self.isCutting
end

function Chainsaw:getNeedCustomWorkStyle()
	local style = self.player.model:getStyle()

	if style == nil then
		return false
	end

	local glovesConfig = style.glovesConfig
	local gloveIndex = glovesConfig.selection

	if gloveIndex == 0 then
		return true
	end

	if glovesConfig.items[gloveIndex] == nil or not glovesConfig.items[gloveIndex].isForestryItem then
		return true
	end

	local headgearConfig = style.headgearConfig
	local headgearIndex = headgearConfig.selection

	if headgearIndex == 0 then
		return true
	end

	if headgearConfig.items[headgearIndex] == nil or not headgearConfig.items[headgearIndex].isForestryItem then
		return true
	end

	return false
end
