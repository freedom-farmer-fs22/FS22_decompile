VehicleCharacter = {
	DEFAULT_MAX_UPDATE_DISTANCE = 35,
	DEFAULT_CLIP_DISTANCE = 75
}
local VehicleCharacter_mt = Class(VehicleCharacter)

function VehicleCharacter.new(vehicle, customMt)
	local self = setmetatable({}, customMt or VehicleCharacter_mt)
	self.vehicle = vehicle
	self.characterNode = nil
	self.allowUpdate = true
	self.ikChainTargets = {}
	self.animationCharsetId = nil
	self.animationPlayer = nil
	self.useAnimation = false

	return self
end

function VehicleCharacter:load(xmlFile, xmlNode)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, xmlNode .. "#index", xmlNode .. "#node")

	self.characterNode = xmlFile:getValue(xmlNode .. "#node", nil, self.vehicle.components, self.vehicle.i3dMappings)

	if self.characterNode ~= nil then
		self.parentComponent = self.vehicle:getParentComponent(self.characterNode)
		self.characterCameraMinDistance = xmlFile:getValue(xmlNode .. "#cameraMinDistance", 1.5)
		self.characterDistanceRefNodeCustom = xmlFile:getValue(xmlNode .. "#distanceRefNode", nil, self.vehicle.components, self.vehicle.i3dMappings)
		self.characterDistanceRefNode = self.characterDistanceRefNodeCustom or self.characterNode

		setVisibility(self.characterNode, false)

		self.useAnimation = xmlFile:getValue(xmlNode .. "#useAnimation", false)

		if not self.useAnimation then
			self.ikChainTargets = {}

			IKUtil.loadIKChainTargets(xmlFile, xmlNode, self.vehicle.components, self.ikChainTargets, self.vehicle.i3dMappings)
		end

		self.characterSpineRotation = xmlFile:getValue(xmlNode .. "#spineRotation", nil, true)
		self.characterSpineSpeedDepended = xmlFile:getValue(xmlNode .. "#speedDependedSpine", false)
		self.characterSpineNodeMinRot = xmlFile:getValue(xmlNode .. "#spineNodeMinRot", 10)
		self.characterSpineNodeMaxRot = xmlFile:getValue(xmlNode .. "#spineNodeMaxRot", -10)
		self.characterSpineNodeMinAcc = xmlFile:getValue(xmlNode .. "#spineNodeMinAcc", -1) / 1000000
		self.characterSpineNodeMaxAcc = xmlFile:getValue(xmlNode .. "#spineNodeMaxAcc", 1) / 1000000
		self.characterSpineNodeAccDeadZone = xmlFile:getValue(xmlNode .. "#spineNodeAccDeadZone", 0.2) / 1000000
		self.characterSpineLastRotation = 0

		self:setCharacterVisibility(false)

		self.maxUpdateDistance = xmlFile:getValue(xmlNode .. "#maxUpdateDistance", VehicleCharacter.DEFAULT_MAX_UPDATE_DISTANCE)

		setClipDistance(self.characterNode, xmlFile:getValue(xmlNode .. "#clipDistance", VehicleCharacter.DEFAULT_CLIP_DISTANCE))

		return true
	end

	return false
end

function VehicleCharacter:getParentComponent()
	return self.parentComponent
end

function VehicleCharacter:loadCharacter(playerStyle, asyncCallbackObject, asyncCallbackFunction, asyncCallbackArguments)
	if self.playerModel ~= nil then
		self.playerModel:delete()
	end

	self.playerModel = PlayerModel.new()

	self.playerModel:load(playerStyle.xmlFilename, false, false, false, self.characterLoaded, self, {
		asyncCallbackObject,
		asyncCallbackFunction,
		asyncCallbackArguments,
		playerStyle
	})
end

function VehicleCharacter:characterLoaded(success, arguments)
	if success then
		if self.playerModel.rootNode == nil then
			return
		end

		local playerStyle = arguments[4]

		self.playerModel:setStyle(playerStyle, false, nil)

		local linkNode = Utils.getNoNil(self.characterNode, self.vehicle.rootNode)

		link(linkNode, self.playerModel.rootNode)
		IKUtil.updateAlignNodes(self.playerModel.ikChains, nil, , linkNode)

		for ikChainId, target in pairs(self.ikChainTargets) do
			IKUtil.setTarget(self.playerModel:getIKChains(), ikChainId, target)
		end

		if self.characterSpineRotation ~= nil and self.playerModel.thirdPersonSpineNode ~= nil then
			setRotation(self.playerModel.thirdPersonSpineNode, unpack(self.characterSpineRotation))
		end

		self.characterDistanceRefNode = self.characterDistanceRefNodeCustom or self.playerModel.thirdPersonHeadNode

		if self.useAnimation and self.playerModel.skeleton ~= nil and getNumOfChildren(self.playerModel.skeleton) > 0 then
			local skeleton = self.playerModel.skeleton
			local animNode = g_animCache:getNode(AnimationCache.VEHICLE_CHARACTER)

			cloneAnimCharacterSet(getChildAt(animNode, 0), skeleton)

			self.animationCharsetId = getAnimCharacterSet(getChildAt(skeleton, 0))
			local animationPlayer = createConditionalAnimation()

			if animationPlayer ~= 0 then
				self.animationPlayer = animationPlayer
			end

			if self.animationCharsetId == 0 then
				self.animationCharsetId = nil

				Logging.devError("-- [VehicleCharacter:loadCharacter] Could not load animation CharSet from: [%s/%s]", getName(getParent(skeleton)), getName(skeleton))
				printScenegraph(getParent(skeleton))
			end
		end

		self:setDirty(true)
		self:setCharacterVisibility(true)
	else
		self.playerModel:delete()

		self.playerModel = nil

		Logging.error("Failed to load vehicleCharacter")
	end

	local asyncCallbackObject, asyncCallbackFunction, asyncCallbackArguments = unpack(arguments)

	if asyncCallbackFunction ~= nil then
		asyncCallbackFunction(asyncCallbackObject, success, asyncCallbackArguments)
	end
end

function VehicleCharacter:delete()
	self:unloadCharacter()
end

function VehicleCharacter:unloadCharacter()
	if self.playerModel ~= nil then
		self.characterDistanceRefNode = self.characterDistanceRefNodeCustom or self.characterNode

		self.playerModel:delete()

		if self.animationPlayer ~= nil then
			delete(self.animationPlayer)

			self.animationPlayer = nil
		end

		self.playerModel = nil
	end
end

function VehicleCharacter:setDirty(setAllDirty)
	if self.playerModel ~= nil then
		for chainId, target in pairs(self.ikChainTargets) do
			if target.setDirty or setAllDirty then
				IKUtil.setIKChainDirty(self.playerModel:getIKChains(), chainId)
			end
		end
	end
end

function VehicleCharacter:updateIKChains()
	IKUtil.updateIKChains(self.playerModel:getIKChains())
end

function VehicleCharacter:setIKChainPoseByTarget(target, poseId)
	if self.playerModel ~= nil then
		local ikChains = self.playerModel:getIKChains()
		local chain = IKUtil.getIKChainByTarget(ikChains, target)

		if chain ~= nil then
			IKUtil.setIKChainPose(ikChains, chain.id, poseId)
		end
	end
end

function VehicleCharacter:setSpineDirty(acc)
	if math.abs(acc) < self.characterSpineNodeAccDeadZone then
		acc = 0
	end

	local alpha = MathUtil.clamp((acc - self.characterSpineNodeMinAcc) / (self.characterSpineNodeMaxAcc - self.characterSpineNodeMinAcc), 0, 1)
	local rotation = MathUtil.lerp(self.characterSpineNodeMinRot, self.characterSpineNodeMaxRot, alpha)

	if rotation ~= self.characterSpineLastRotation then
		self.characterSpineLastRotation = self.characterSpineLastRotation * 0.95 + rotation * 0.05

		setRotation(self.player.spineNode, self.characterSpineLastRotation, 0, 0)
		self:setDirty()
	end
end

function VehicleCharacter:updateVisibility(isVisible)
	if entityExists(self.characterDistanceRefNode) and entityExists(getCamera()) then
		local dist = calcDistanceFrom(self.characterDistanceRefNode, getCamera())
		local visible = self.characterCameraMinDistance <= dist

		self:setCharacterVisibility(visible)
	end
end

function VehicleCharacter:setCharacterVisibility(isVisible)
	if self.characterNode ~= nil then
		setVisibility(self.characterNode, isVisible)
	end

	if self.playerModel ~= nil and self.playerModel.isLoaded then
		self.playerModel:setVisibility(isVisible)
	end
end

function VehicleCharacter:setAllowCharacterUpdate(state)
	self.allowUpdate = state
end

function VehicleCharacter:getAllowCharacterUpdate()
	return self.allowUpdate
end

function VehicleCharacter:update(dt)
	if self.playerModel ~= nil and self.playerModel.isLoaded and self.vehicle.currentUpdateDistance < self.maxUpdateDistance then
		if self:getAllowCharacterUpdate() then
			self:setDirty(false)
		end

		self:updateIKChains()
	end
end

function VehicleCharacter:getIKChainTargets()
	return self.ikChainTargets
end

function VehicleCharacter:setIKChainTargets(targets, force)
	if self.ikChainTargets ~= targets or force then
		self.ikChainTargets = targets

		if self.playerModel ~= nil then
			for ikChainId, target in pairs(self.ikChainTargets) do
				IKUtil.setTarget(self.playerModel:getIKChains(), ikChainId, target)
			end

			self:setDirty(true)
		end
	end
end

function VehicleCharacter:getPlayerStyle()
	if self.playerModel ~= nil then
		return self.playerModel.style
	end
end

function VehicleCharacter.registerCharacterXMLPaths(schema, basePath, name)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Character root node")
	schema:register(XMLValueType.FLOAT, basePath .. "#cameraMinDistance", "Min. distance until character is hidden", 1.5)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#distanceRefNode", "Distance reference node", "Character root node")
	schema:register(XMLValueType.BOOL, basePath .. "#useAnimation", "Use animation instead of ik chains", false)
	schema:register(XMLValueType.VECTOR_ROT, basePath .. "#spineRotation", "Spine rotation")
	schema:register(XMLValueType.BOOL, basePath .. "#speedDependedSpine", "Speed dependent spine", false)
	schema:register(XMLValueType.ANGLE, basePath .. "#spineNodeMinRot", "Spine node min. rotation", 10)
	schema:register(XMLValueType.ANGLE, basePath .. "#spineNodeMaxRot", "Spine node max. rotation", -10)
	schema:register(XMLValueType.FLOAT, basePath .. "#spineNodeMinAcc", "Spine node min. acceleration", -1)
	schema:register(XMLValueType.FLOAT, basePath .. "#spineNodeMaxAcc", "Spine node max. acceleration", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#spineNodeAccDeadZone", "Spine node acceleration dead zone", 0.2)
	schema:register(XMLValueType.FLOAT, basePath .. "#maxUpdateDistance", "Max. distance to vehicle root to update ik chains of character", VehicleCharacter.DEFAULT_MAX_UPDATE_DISTANCE)
	schema:register(XMLValueType.FLOAT, basePath .. "#clipDistance", "Clip distance of character", VehicleCharacter.DEFAULT_CLIP_DISTANCE)
	IKUtil.registerIKChainTargetsXMLPaths(schema, basePath)
end
