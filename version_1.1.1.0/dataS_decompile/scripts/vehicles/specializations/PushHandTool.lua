PushHandTool = {
	PLAYER_COLLISION_MASK = CollisionFlag.DEFAULT + CollisionFlag.STATIC_WORLD + CollisionFlag.STATIC_OBJECTS + CollisionFlag.STATIC_OBJECT,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("PushHandTool")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.raycast#node1", "Front raycast node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.raycast#node2", "Back raycast node")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.raycast#playerNode", "Player node to adjust")
		schema:register(XMLValueType.VECTOR_N, "vehicle.pushHandTool.wheels#front", "Indices of front wheels")
		schema:register(XMLValueType.VECTOR_N, "vehicle.pushHandTool.wheels#back", "Indices of back wheels")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.pushHandTool.handle#node", "Handle node")
		schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.handle#upperLimit", "Max. upper distance between handle node and hand ik root node", 0.4)
		schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.handle#lowerLimit", "Max. lower distance between handle node and hand ik root node", 0.4)
		schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.handle#interpolateDistance", "Interpolation distance if limit is exceeded", 0.4)
		schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.handle#minRot", "Min. rotation of handle", -20)
		schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.handle#maxRot", "Max. rotation of handle", 20)
		IKUtil.registerIKChainTargetsXMLPaths(schema, "vehicle.pushHandTool.ikChains")
		EffectManager.registerEffectXMLPaths(schema, "vehicle.pushHandTool.effect")
		schema:register(XMLValueType.STRING, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#chainId", "Chain identifier string", 20)
		schema:register(XMLValueType.INT, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#nodeIndex", "Index of node")
		schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#minRx", "Min. X rotation")
		schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#maxRx", "Max. X rotation")
		schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#minRy", "Min. Y rotation")
		schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#maxRy", "Max. Y rotation")
		schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#minRz", "Min. Z rotation")
		schema:register(XMLValueType.ANGLE, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#maxRz", "Max. Z rotation")
		schema:register(XMLValueType.FLOAT, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#damping", "Damping")
		schema:register(XMLValueType.BOOL, "vehicle.pushHandTool.customChainLimits.customChainLimit(?)#localLimits", "Local limits")

		local function registerConditionalAnimation(xmlKey)
			schema:register(XMLValueType.STRING, xmlKey .. ".item(?)#id", "")
			schema:register(XMLValueType.FLOAT, xmlKey .. ".item(?)#entryTransitionDuration", "")
			schema:register(XMLValueType.FLOAT, xmlKey .. ".item(?)#exitTransitionDuration", "")
			schema:register(XMLValueType.STRING, xmlKey .. ".item(?).clips#speedScaleType", "")
			schema:register(XMLValueType.FLOAT, xmlKey .. ".item(?).clips#speedScaleParameter", "")
			schema:register(XMLValueType.BOOL, xmlKey .. ".item(?).clips#blended", "")
			schema:register(XMLValueType.STRING, xmlKey .. ".item(?).clips#blendingParameter", "")
			schema:register(XMLValueType.STRING, xmlKey .. ".item(?).clips#blendingParameterType", "")
			schema:register(XMLValueType.STRING, xmlKey .. ".item(?).clips.clip(?)#clipName", "")
			schema:register(XMLValueType.STRING, xmlKey .. ".item(?).clips.clip(?)#id", "")
			schema:register(XMLValueType.FLOAT, xmlKey .. ".item(?).clips.clip(?)#blendingThreshold", "")
			schema:register(XMLValueType.STRING, xmlKey .. ".item(?).conditions.conditionGroup(?).condition(?)#parameter", "")
			schema:register(XMLValueType.BOOL, xmlKey .. ".item(?).conditions.conditionGroup(?).condition(?)#equal", "")
			schema:register(XMLValueType.STRING, xmlKey .. ".item(?).conditions.conditionGroup(?).condition(?)#between", "")
			schema:register(XMLValueType.FLOAT, xmlKey .. ".item(?).conditions.conditionGroup(?).condition(?)#greater", "")
			schema:register(XMLValueType.FLOAT, xmlKey .. ".item(?).conditions.conditionGroup(?).condition(?)#lower", "")
		end

		registerConditionalAnimation("vehicle.pushHandTool.playerConditionalAnimation")
		schema:setXMLSpecializationType()
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TestAreas, specializations)
	end
}

function PushHandTool.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getRaycastPosition", PushHandTool.getRaycastPosition)
	SpecializationUtil.registerFunction(vehicleType, "playerRaycastCallback", PushHandTool.playerRaycastCallback)
	SpecializationUtil.registerFunction(vehicleType, "postAnimationUpdate", PushHandTool.postAnimationUpdate)
	SpecializationUtil.registerFunction(vehicleType, "customVehicleCharacterLoaded", PushHandTool.customVehicleCharacterLoaded)
end

function PushHandTool.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setVehicleCharacter", PushHandTool.setVehicleCharacter)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowCharacterVisibilityUpdate", PushHandTool.getAllowCharacterVisibilityUpdate)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setActiveCameraIndex", PushHandTool.setActiveCameraIndex)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartAIVehicle", PushHandTool.getCanStartAIVehicle)
end

function PushHandTool.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onCameraChanged", PushHandTool)
	SpecializationUtil.registerEventListener(vehicleType, "onVehicleCharacterChanged", PushHandTool)
end

function PushHandTool:onLoad(savegame)
	local spec = self.spec_pushHandTool
	spec.animationParameters = {
		absSmoothedForwardVelocity = {
			value = 0,
			id = 1,
			type = 1
		},
		smoothedForwardVelocity = {
			value = 0,
			id = 2,
			type = 1
		},
		accelerate = {
			value = false,
			id = 3,
			type = 0
		},
		leftRightWeight = {
			value = 0,
			id = 4,
			type = 1
		}
	}
	spec.raycastNode1 = self.xmlFile:getValue("vehicle.pushHandTool.raycast#node1", nil, self.components, self.i3dMappings)
	spec.raycastNode2 = self.xmlFile:getValue("vehicle.pushHandTool.raycast#node2", nil, self.components, self.i3dMappings)
	spec.playerNode = self.xmlFile:getValue("vehicle.pushHandTool.raycast#playerNode", nil, self.components, self.i3dMappings)
	spec.playerTargetNode = createTransformGroup("playerTargetNode")

	if spec.playerNode ~= nil then
		link(getParent(spec.playerNode), spec.playerTargetNode)
		setTranslation(spec.playerTargetNode, getTranslation(spec.playerNode))
	end

	local frontWheels = self.xmlFile:getValue("vehicle.pushHandTool.wheels#front", nil, true)
	spec.frontWheels = {}

	for i = 1, #frontWheels do
		local wheel = self:getWheelFromWheelIndex(frontWheels[i])

		if wheel ~= nil then
			table.insert(spec.frontWheels, wheel)
		end
	end

	local backWheels = self.xmlFile:getValue("vehicle.pushHandTool.wheels#back", nil, true)
	spec.backWheels = {}

	for i = 1, #backWheels do
		local wheel = self:getWheelFromWheelIndex(backWheels[i])

		if wheel ~= nil then
			table.insert(spec.backWheels, wheel)
		end
	end

	spec.handle = {
		node = self.xmlFile:getValue("vehicle.pushHandTool.handle#node", nil, self.components, self.i3dMappings),
		upperLimit = self.xmlFile:getValue("vehicle.pushHandTool.handle#upperLimit", 0.4),
		lowerLimit = self.xmlFile:getValue("vehicle.pushHandTool.handle#lowerLimit", 0.4),
		interpolateDistance = self.xmlFile:getValue("vehicle.pushHandTool.handle#interpolateDistance", 0.4),
		minRot = self.xmlFile:getValue("vehicle.pushHandTool.handle#minRot", -20),
		maxRot = self.xmlFile:getValue("vehicle.pushHandTool.handle#maxRot", 20)
	}
	spec.characterIKNodes = {}
	spec.ikChainTargets = {}

	IKUtil.loadIKChainTargets(self.xmlFile, "vehicle.pushHandTool.ikChains", self.components, spec.ikChainTargets, self.i3dMappings)

	spec.lastRaycastPosition = {
		0,
		0,
		0,
		0
	}
	spec.lastRaycastHit = false

	if self.isClient then
		spec.cutterEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.pushHandTool.effect", self.components, self, self.i3dMappings)
	end

	spec.customChainLimits = {}

	self.xmlFile:iterate("vehicle.pushHandTool.customChainLimits.customChainLimit", function (index, key)
		local entry = {
			chainId = self.xmlFile:getValue(key .. "#chainId"),
			nodeIndex = self.xmlFile:getValue(key .. "#nodeIndex")
		}

		if entry.chainId ~= nil and entry.nodeIndex ~= nil then
			entry.minRx = self.xmlFile:getValue(key .. "#minRx")
			entry.maxRx = self.xmlFile:getValue(key .. "#maxRx")
			entry.minRy = self.xmlFile:getValue(key .. "#minRy")
			entry.maxRy = self.xmlFile:getValue(key .. "#maxRy")
			entry.minRz = self.xmlFile:getValue(key .. "#minRz")
			entry.maxRz = self.xmlFile:getValue(key .. "#maxRz")
			entry.damping = self.xmlFile:getValue(key .. "#damping")
			entry.localLimits = self.xmlFile:getValue(key .. "#localLimits")

			table.insert(spec.customChainLimits, entry)
		end
	end)

	spec.effectDirtyFlag = self:getNextDirtyFlag()
	spec.raycastsValid = true
	spec.lastSmoothSpeed = 0

	self:setTestAreaRequirements(FruitType.GRASS, nil, false)

	spec.postAnimationCallback = addPostAnimationCallback(self.postAnimationUpdate, self)
end

function PushHandTool:onDelete()
	local spec = self.spec_pushHandTool

	g_effectManager:deleteEffects(spec.cutterEffects)
	removePostAnimationCallback(spec.postAnimationCallback)
end

function PushHandTool:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_pushHandTool

	if self:getIsTurnedOn() and self:getLastSpeed() > 0.5 then
		local currentTestAreaMinX, currentTestAreaMaxX, testAreaMinX, testAreaMaxX = self:getTestAreaWidthByWorkAreaIndex(1)
		local reset = false

		if currentTestAreaMinX == math.huge and currentTestAreaMaxX == -math.huge then
			currentTestAreaMinX = 0
			currentTestAreaMaxX = 0
			reset = true
		end

		if spec.movingDirection > 0 then
			currentTestAreaMinX = currentTestAreaMinX * -1
			currentTestAreaMaxX = currentTestAreaMaxX * -1

			if currentTestAreaMinX > currentTestAreaMaxX then
				local t = currentTestAreaMinX
				currentTestAreaMinX = currentTestAreaMaxX
				currentTestAreaMaxX = t
			end
		end

		if self.isClient then
			local inputFruitType = FruitType.UNKNOWN
			local inputGrowthState = 3

			if self.spec_mower ~= nil then
				local specMower = self.spec_mower

				if g_time - specMower.workAreaParameters.lastCutTime < 500 then
					inputFruitType = specMower.workAreaParameters.lastInputFruitType
					inputGrowthState = specMower.workAreaParameters.lastInputGrowthState
				end
			end

			if inputFruitType ~= nil and inputFruitType ~= FruitType.UNKNOWN then
				g_effectManager:setFruitType(spec.cutterEffects, inputFruitType, inputGrowthState)
				g_effectManager:setMinMaxWidth(spec.cutterEffects, currentTestAreaMinX, currentTestAreaMaxX, currentTestAreaMinX / testAreaMinX, currentTestAreaMaxX / testAreaMaxX, reset)
				g_effectManager:startEffects(spec.cutterEffects)

				spec.effectsAreRunning = not reset
			elseif spec.effectsAreRunning then
				g_effectManager:stopEffects(spec.cutterEffects)

				spec.effectsAreRunning = false
			end
		end
	elseif spec.effectsAreRunning then
		g_effectManager:stopEffects(spec.cutterEffects)

		spec.effectsAreRunning = false
	end

	local lastSpeed = self.lastSignedSpeed * 1000
	local avgSpeed = 0
	local numWheels = 0

	for _, wheel in pairs(spec.backWheels) do
		if wheel.netInfo.xDriveSpeed ~= nil then
			local wheelSpeed = MathUtil.rpmToMps(wheel.netInfo.xDriveSpeed / (2 * math.pi) * 60, wheel.radius) * 1000
			avgSpeed = avgSpeed + wheelSpeed
			numWheels = numWheels + 1
		end
	end

	if numWheels > 0 then
		lastSpeed = avgSpeed / numWheels
	end

	spec.lastSmoothSpeed = spec.lastSmoothSpeed * 0.9 + lastSpeed * 0.1
	spec.animationParameters.smoothedForwardVelocity.value = spec.lastSmoothSpeed
	spec.animationParameters.absSmoothedForwardVelocity.value = math.abs(spec.lastSmoothSpeed)
	spec.animationParameters.leftRightWeight.value = self.rotatedTime
	spec.animationParameters.accelerate.value = self:getAccelerationAxis() > 0

	if self:getIsEntered() or self:getIsControlled() then
		local character = self:getVehicleCharacter()

		if character ~= nil and character.animationCharsetId ~= nil and character.animationPlayer ~= nil then
			for _, parameter in pairs(spec.animationParameters) do
				if parameter.type == 0 then
					setConditionalAnimationBoolValue(character.animationPlayer, parameter.id, parameter.value)
				elseif parameter.type == 1 then
					setConditionalAnimationFloatValue(character.animationPlayer, parameter.id, parameter.value)
				end
			end

			setConditionalAnimationSpecificParameterIds(character.animationPlayer, spec.animationParameters.absSmoothedForwardVelocity.id, 0)
			updateConditionalAnimation(character.animationPlayer, dt)
		end
	end

	if spec.raycastNode1 ~= nil and spec.raycastNode2 ~= nil and spec.playerNode ~= nil and #spec.frontWheels >= 1 and #spec.backWheels >= 1 then
		local x1, y1, z1 = self:getRaycastPosition(spec.raycastNode1)
		local x2, y2, z2 = self:getRaycastPosition(spec.raycastNode2)

		if x1 ~= nil and x2 ~= nil then
			local tx = (x1 + x2) * 0.5
			local ty = (y1 + y2) * 0.5
			local tz = (z1 + z2) * 0.5

			setWorldTranslation(spec.playerTargetNode, tx, ty, tz)

			local dirX = x1 - x2
			local dirY = y1 - y2
			local dirZ = z1 - z2
			dirX, dirY, dirZ = MathUtil.vector3Normalize(dirX, dirY, dirZ)

			if spec.lastYDirection == nil then
				spec.lastYDirection = dirY
			else
				dirY = spec.lastYDirection * 0.9 + dirY * 0.1
				spec.lastYDirection = dirY
			end

			I3DUtil.setWorldDirection(spec.playerTargetNode, dirX, dirY, dirZ, 0, 1, 0)

			if spec.lastWorldTrans == nil then
				spec.lastWorldTrans = {
					getWorldTranslation(spec.playerNode)
				}
			end

			local cx = spec.lastWorldTrans[1]
			local cy = spec.lastWorldTrans[2]
			local cz = spec.lastWorldTrans[3]
			local smoothFactor = 0.5 - math.abs(math.min(self.rotatedTime / 0.5), 1) * 0.15
			local moveX = (cx - tx) * smoothFactor
			local moveY = (cy - ty) * smoothFactor
			local moveZ = (cz - tz) * smoothFactor
			local newX = cx - moveX
			local newY = cy - moveY
			local newZ = cz - moveZ

			setWorldTranslation(spec.playerNode, newX, newY, newZ)

			spec.lastWorldTrans[3] = newZ
			spec.lastWorldTrans[2] = newY
			spec.lastWorldTrans[1] = newX
			local direction = self.movingDirection

			if direction == 0 then
				direction = 1
			end

			tx, ty, tz = localToWorld(spec.playerTargetNode, 0, 0, 0.2 * direction)
			local dirY2, _ = nil
			dirZ = tz - newZ
			dirY2 = ty - newY
			dirX = tx - newX
			dirX, _, dirZ = MathUtil.vector3Normalize(dirX, dirY2, dirZ)

			if direction < 0 then
				dirZ = -dirZ
				dirX = -dirX
			end

			local fcx = 0
			local fcy = 0
			local fcz = 0
			local numFrontWheels = #spec.frontWheels

			for i = 1, numFrontWheels do
				local wheel = spec.frontWheels[i]
				local wx = wheel.netInfo.x
				local wy = wheel.netInfo.y
				local wz = wheel.netInfo.z
				wy = wy - wheel.radius
				wx = wx + wheel.xOffset
				wx, wy, wz = localToWorld(wheel.node, wx, wy, wz)
				fcz = fcz + wz
				fcy = fcy + wy
				fcx = fcx + wx
			end

			fcz = fcz / numFrontWheels
			fcy = fcy / numFrontWheels
			fcx = fcx / numFrontWheels
			local bcx = 0
			local bcy = 0
			local bcz = 0
			local numBackWheels = #spec.backWheels

			for i = 1, numBackWheels do
				local wheel = spec.backWheels[i]
				local wx = wheel.netInfo.x
				local wy = wheel.netInfo.y
				local wz = wheel.netInfo.z
				wy = wy - wheel.radius
				wx = wx + wheel.xOffset
				wx, wy, wz = localToWorld(wheel.node, wx, wy, wz)
				bcz = bcz + wz
				bcy = bcy + wy
				bcx = bcx + wx
			end

			bcz = bcz / numBackWheels
			bcy = bcy / numBackWheels
			bcx = bcx / numBackWheels
			local wDirX = bcx - fcx
			local wDirY = bcy - fcy
			local wDirZ = bcz - fcz
			_, wDirY, _ = MathUtil.vector3Normalize(wDirX, wDirY, wDirZ)
			local dir = wDirY < 0 and 1 or -1
			dirY = wDirY + math.min(0.15, math.abs(wDirY)) * dir
			local upX, upY, upZ = localDirectionToWorld(self.rootNode, 0, 1, 0)
			upY = upY + 0.5
			upX, upY, upZ = MathUtil.vector3Normalize(upX, upY, upZ)

			I3DUtil.setWorldDirection(spec.playerNode, dirX, dirY, dirZ, upX, upY, upZ)

			spec.raycastsValid = true
		elseif spec.raycastsValid and self:getIsEntered() then
			spec.raycastsValid = false
			local character = self:getVehicleCharacter()

			if character ~= nil then
				character:setCharacterVisibility(false)
			end

			self:setActiveCameraIndex(self.spec_enterable.camIndex)
		end
	end
end

function PushHandTool:setVehicleCharacter(superFunc, playerStyle)
	local enterableSpec = self.spec_enterable

	if enterableSpec.vehicleCharacter ~= nil then
		enterableSpec.vehicleCharacter:delete()
		enterableSpec.vehicleCharacter:loadCharacter(playerStyle, self, self.customVehicleCharacterLoaded)
	end
end

function PushHandTool:customVehicleCharacterLoaded(success, arguments)
	local enterableSpec = self.spec_enterable

	if success then
		local character = enterableSpec.vehicleCharacter

		if character ~= nil then
			character:updateVisibility()
		end

		SpecializationUtil.raiseEvent(self, "onVehicleCharacterChanged", character)

		local spec = self.spec_pushHandTool
		spec.characterIKNodes = {}

		for name, ikChain in pairs(character.playerModel.ikChains) do
			if spec.ikChainTargets[name] ~= nil then
				for k, nodeData in pairs(ikChain.nodes) do
					if spec.characterIKNodes[nodeData.node] == nil then
						local duplicate = createTransformGroup(getName(nodeData.node) .. "_ikChain")
						local parent = getParent(nodeData.node)

						if spec.characterIKNodes[parent] ~= nil then
							parent = spec.characterIKNodes[parent]
						end

						link(parent, duplicate)
						setTranslation(duplicate, getTranslation(nodeData.node))
						setRotation(duplicate, getRotation(nodeData.node))

						spec.characterIKNodes[nodeData.node] = duplicate
					end
				end
			end

			for k, nodeData in pairs(ikChain.nodes) do
				if spec.characterIKNodes[nodeData.node] ~= nil then
					nodeData.node = spec.characterIKNodes[nodeData.node]
				end
			end
		end

		character.ikChainTargets = spec.ikChainTargets

		for ikChainId, target in pairs(spec.ikChainTargets) do
			IKUtil.setTarget(character.playerModel.ikChains, ikChainId, target)
		end

		spec.ikChains = character.playerModel.ikChains

		for name, ikChain in pairs(character.playerModel.ikChains) do
			ikChain.ikChainSolver = IKChain.new(#ikChain.nodes)

			for i, node in ipairs(ikChain.nodes) do
				local minRx = node.minRx
				local maxRx = node.maxRx
				local minRy = node.minRy
				local maxRy = node.maxRy
				local minRz = node.minRz
				local maxRz = node.maxRz
				local damping = node.damping
				local localLimits = node.localLimits

				for j = 1, #spec.customChainLimits do
					local customLimit = spec.customChainLimits[j]

					if customLimit.chainId == name and customLimit.nodeIndex == i then
						minRx = customLimit.minRx or minRx
						maxRx = customLimit.maxRx or maxRx
						minRy = customLimit.minRy or minRy
						maxRy = customLimit.maxRy or maxRy
						minRz = customLimit.minRz or minRz
						maxRz = customLimit.maxRz or maxRz
						damping = customLimit.damping or damping

						if customLimit.localLimits ~= nil then
							localLimits = customLimit.localLimits
						end
					end
				end

				ikChain.ikChainSolver:setJointTransformGroup(i - 1, node.node, minRx, maxRx, minRy, maxRy, minRz, maxRz, damping, localLimits)
			end

			ikChain.numIterations = 40
			ikChain.positionThreshold = 0.0001
		end

		character:setDirty()

		if character ~= nil and character.animationCharsetId ~= nil and character.animationPlayer ~= nil then
			for key, parameter in pairs(spec.animationParameters) do
				conditionalAnimationRegisterParameter(character.animationPlayer, parameter.id, parameter.type, key)
			end

			initConditionalAnimation(character.animationPlayer, character.animationCharsetId, self.configFileName, "vehicle.pushHandTool.playerConditionalAnimation")
			conditionalAnimationZeroiseTrackTimes(character.animationPlayer)
		end

		IKUtil.updateAlignNodes(character.playerModel.ikChains, self.getParentComponent, self)
	end
end

function PushHandTool:getAllowCharacterVisibilityUpdate(superFunc)
	if not superFunc(self) then
		return false
	end

	if self:getIsEntered() then
		local activeCamera = self:getActiveCamera()

		if activeCamera ~= nil and activeCamera.isInside then
			return false
		end
	end

	local spec = self.spec_pushHandTool

	if not spec.raycastsValid then
		return false
	end

	return true
end

function PushHandTool:setActiveCameraIndex(superFunc, index)
	local spec = self.spec_pushHandTool

	if not spec.raycastsValid then
		local specEnterable = self.spec_enterable

		if specEnterable.numCameras < index then
			index = 1
		end

		local activeCamera = specEnterable.cameras[index]

		if activeCamera.isInside then
			for i, camera in pairs(specEnterable.cameras) do
				if not camera.isInside then
					index = i

					break
				end
			end
		end
	end

	return superFunc(self, index)
end

function PushHandTool:getCanStartAIVehicle(superFunc)
	return false
end

function PushHandTool:onEnterVehicle(isControlling)
	local hideCharacter = false

	if isControlling then
		local activeCamera = self:getActiveCamera()

		if activeCamera ~= nil and activeCamera.isInside then
			hideCharacter = true
		end
	end

	local spec = self.spec_pushHandTool

	if not spec.raycastsValid then
		hideCharacter = true
	end

	if hideCharacter then
		local character = self:getVehicleCharacter()

		if character ~= nil then
			character:setCharacterVisibility(false)
		end
	end
end

function PushHandTool:onLeaveVehicle()
	local spec = self.spec_pushHandTool
	spec.characterIKNodes = {}
end

function PushHandTool:onCameraChanged(activeCamera, camIndex)
	if self:getIsEntered() then
		local character = self:getVehicleCharacter()

		if character ~= nil and activeCamera.isInside then
			character:setCharacterVisibility(false)
		end
	end
end

function PushHandTool:onVehicleCharacterChanged(character)
	if self:getIsEntered() and character ~= nil then
		local activeCamera = self:getActiveCamera()

		if activeCamera ~= nil and activeCamera.isInside then
			character:setCharacterVisibility(false)
		end
	end
end

function PushHandTool:postAnimationUpdate(dt)
	if self.isActive then
		local spec = self.spec_pushHandTool

		if spec.raycastsValid and spec.handle.node ~= nil and spec.ikChains ~= nil then
			local yDifference = nil

			for name, ikChain in pairs(spec.ikChains) do
				local node = ikChain.nodes[1].node

				if node ~= nil and spec.ikChainTargets[name] ~= nil then
					local targetNode = spec.ikChainTargets[name].targetNode

					if targetNode ~= nil then
						local x, y, z = getRotation(spec.handle.node)

						setRotation(spec.handle.node, 0, 0, 0)

						if yDifference == nil then
							yDifference = calcDistanceFrom(node, targetNode)
						else
							yDifference = (yDifference + calcDistanceFrom(node, targetNode)) / 2
						end

						setRotation(spec.handle.node, x, y, z)
					end
				end
			end

			if yDifference ~= nil then
				if yDifference < spec.handle.upperLimit then
					local alpha = (spec.handle.upperLimit - yDifference) / spec.handle.interpolateDistance

					setRotation(spec.handle.node, spec.handle.minRot * alpha, 0, 0)
				elseif spec.handle.lowerLimit < yDifference then
					local alpha = (yDifference - spec.handle.lowerLimit) / spec.handle.interpolateDistance

					setRotation(spec.handle.node, spec.handle.maxRot * alpha, 0, 0)
				end
			end
		end

		if spec.ikChains ~= nil then
			for chainId, target in pairs(spec.ikChainTargets) do
				IKUtil.setIKChainDirty(spec.ikChains, chainId)
			end

			IKUtil.updateIKChains(spec.ikChains)

			for target, source in pairs(spec.characterIKNodes) do
				setRotation(target, getRotation(source))
			end

			for ikChainId, target in pairs(spec.ikChainTargets) do
				IKUtil.setIKChainPose(spec.ikChains, ikChainId, target.poseId)
			end
		end
	end
end

function PushHandTool:getRaycastPosition(node)
	local spec = self.spec_pushHandTool
	local x, y, z = getWorldTranslation(node)
	local dirX, dirY, dirZ = localDirectionToWorld(node, 0, -1, 0)
	dirY = dirY * 1.5
	spec.lastRaycastHit = false

	raycastAll(x, y, z, dirX, dirY, dirZ, "playerRaycastCallback", 2, self, PushHandTool.PLAYER_COLLISION_MASK)

	if spec.lastRaycastHit and spec.lastRaycastPosition[4] > 0.35 and spec.lastRaycastPosition[2] < y - 0.25 then
		return unpack(spec.lastRaycastPosition)
	end

	return nil
end

function PushHandTool:playerRaycastCallback(hitObjectId, x, y, z, distance)
	local spec = self.spec_pushHandTool
	local vehicle = g_currentMission.nodeToObject[hitObjectId]

	if vehicle ~= nil and vehicle == self then
		return true
	end

	spec.lastRaycastPosition[1] = x
	spec.lastRaycastPosition[2] = y
	spec.lastRaycastPosition[3] = z
	spec.lastRaycastPosition[4] = distance
	spec.lastRaycastHit = true

	return false
end
