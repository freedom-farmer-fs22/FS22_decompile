AIDrivable = {
	STATES = {}
}
AIDrivable.STATES[AgentState.DRIVING] = "driving"
AIDrivable.STATES[AgentState.BLOCKED] = "blocked"
AIDrivable.STATES[AgentState.PLANNING] = "planning"
AIDrivable.STATES[AgentState.NOT_REACHABLE] = "not_reachable"
AIDrivable.STATES[AgentState.TARGET_REACHED] = "target_reached"
AIDrivable.TRAILER_LIMIT = 4

function AIDrivable.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AIVehicle, specializations) and SpecializationUtil.hasSpecialization(AIJobVehicle, specializations) and SpecializationUtil.hasSpecialization(Drivable, specializations)
end

function AIDrivable.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("AI")
	schema:register(XMLValueType.FLOAT, "vehicle.ai.agent#width", "AI vehicle width")
	schema:register(XMLValueType.FLOAT, "vehicle.ai.agent#length", "AI vehicle length")
	schema:register(XMLValueType.FLOAT, "vehicle.ai.agent#lengthOffset", "AI vehicle length offset")
	schema:register(XMLValueType.FLOAT, "vehicle.ai.agent#height", "AI vehicle height")
	schema:register(XMLValueType.FLOAT, "vehicle.ai.agent#frontOffset", "AI vehicle front offset")
	schema:register(XMLValueType.FLOAT, "vehicle.ai.agent#maxBrakeAcceleration", "AI vehicle max brake acceleration")
	schema:register(XMLValueType.FLOAT, "vehicle.ai.agent#maxCentripedalAcceleration", "AI vehicle max centripedal acceleration")
	schema:setXMLSpecializationType()
end

function AIDrivable.postInitSpecialization()
	local schema = Vehicle.xmlSchema

	for name, _ in pairs(g_configurationManager:getConfigurations()) do
		local specializationKey = g_configurationManager:getConfigurationAttribute(name, "xmlKey")

		if specializationKey ~= nil then
			specializationKey = "." .. specializationKey
		else
			specializationKey = ""
		end

		local configrationsKey = string.format("vehicle%s.%sConfigurations", specializationKey, name)
		local configrationKey = string.format("%s.%sConfiguration(?)", configrationsKey, name)

		schema:setXMLSharedRegistration("configAIAgent", configrationKey)
		schema:register(XMLValueType.FLOAT, configrationKey .. ".aiAgent#width", "ai width of the vehicle when loaded in this configuration")
		schema:register(XMLValueType.FLOAT, configrationKey .. ".aiAgent#length", "ai length of the vehicle when loaded in this configuration")
		schema:register(XMLValueType.FLOAT, configrationKey .. ".aiAgent#height", "ai height of the vehicle when loaded in this configuration")
		schema:register(XMLValueType.FLOAT, configrationKey .. ".aiAgent#lengthOffset", "length offset")
		schema:register(XMLValueType.FLOAT, configrationKey .. ".aiAgent#frontOffset", "front offset")
		schema:register(XMLValueType.FLOAT, configrationKey .. ".aiAgent#maxBrakeAcceleration", "AI vehicle max brake acceleration")
		schema:register(XMLValueType.FLOAT, configrationKey .. ".aiAgent#maxCentripedalAcceleration", "AI vehicle max centripedal acceleration")
		schema:setXMLSharedRegistration()
	end
end

function AIDrivable.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onAIDrivablePrepare")
	SpecializationUtil.registerEvent(vehicleType, "onAIDriveableStart")
	SpecializationUtil.registerEvent(vehicleType, "onAIDriveableActive")
	SpecializationUtil.registerEvent(vehicleType, "onAIDriveableEnd")
end

function AIDrivable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "consoleCommandSetTurnRadius", AIDrivable.consoleCommandSetTurnRadius)
	SpecializationUtil.registerFunction(vehicleType, "consoleCommandMove", AIDrivable.consoleCommandMove)
	SpecializationUtil.registerFunction(vehicleType, "consoleCommandClearPath", AIDrivable.consoleCommandClearPath)
	SpecializationUtil.registerFunction(vehicleType, "createAgent", AIDrivable.createAgent)
	SpecializationUtil.registerFunction(vehicleType, "deleteAgent", AIDrivable.deleteAgent)
	SpecializationUtil.registerFunction(vehicleType, "setAITarget", AIDrivable.setAITarget)
	SpecializationUtil.registerFunction(vehicleType, "unsetAITarget", AIDrivable.unsetAITarget)
	SpecializationUtil.registerFunction(vehicleType, "reachedAITarget", AIDrivable.reachedAITarget)
	SpecializationUtil.registerFunction(vehicleType, "getAIRootNode", AIDrivable.getAIRootNode)
	SpecializationUtil.registerFunction(vehicleType, "getAIAllowsBackwards", AIDrivable.getAIAllowsBackwards)
	SpecializationUtil.registerFunction(vehicleType, "drawDebugAIAgent", AIDrivable.drawDebugAIAgent)
	SpecializationUtil.registerFunction(vehicleType, "loadAgentInfoFromXML", AIDrivable.loadAgentInfoFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getAIAgentSize", AIDrivable.getAIAgentSize)
	SpecializationUtil.registerFunction(vehicleType, "getAIAgentMaxBrakeAcceleration", AIDrivable.getAIAgentMaxBrakeAcceleration)
	SpecializationUtil.registerFunction(vehicleType, "updateAIAgentAttachments", AIDrivable.updateAIAgentAttachments)
	SpecializationUtil.registerFunction(vehicleType, "addAIAgentAttachment", AIDrivable.addAIAgentAttachment)
	SpecializationUtil.registerFunction(vehicleType, "startNewAIAgentAttachmentChain", AIDrivable.startNewAIAgentAttachmentChain)
	SpecializationUtil.registerFunction(vehicleType, "updateAIAgentAttachmentOffsetData", AIDrivable.updateAIAgentAttachmentOffsetData)
	SpecializationUtil.registerFunction(vehicleType, "updateAIAgentPoseData", AIDrivable.updateAIAgentPoseData)
	SpecializationUtil.registerFunction(vehicleType, "prepareForAIDriving", AIDrivable.prepareForAIDriving)
	SpecializationUtil.registerFunction(vehicleType, "getAITurningRadius", AIDrivable.getAITurningRadius)
end

function AIDrivable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanHaveAIVehicleObstacle", AIDrivable.getCanHaveAIVehicleObstacle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIReadyToDrive", AIDrivable.getIsAIReadyToDrive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIPreparingToDrive", AIDrivable.getIsAIPreparingToDrive)
end

function AIDrivable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIDrivable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIDrivable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIDrivable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIDrivable)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", AIDrivable)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AIDrivable)
end

function AIDrivable:onLoad(savegame)
	local spec = self.spec_aiDrivable
	spec.agentInfo = {}

	self:loadAgentInfoFromXML(self.xmlFile, spec.agentInfo)

	spec.maxSpeed = math.huge
	spec.isRunning = false
	spec.useManualDriving = false
	spec.lastState = nil
	spec.lastIsBlocked = false
	spec.lastMaxSpeed = 0
	spec.stuckTime = 0
	spec.agentId = nil
	spec.targetZ = nil
	spec.targetY = nil
	spec.targetX = nil
	spec.targetDirZ = nil
	spec.targetDirY = nil
	spec.targetDirX = nil
	spec.attachments = {}
	spec.attachmentChains = {}
	spec.attachmentChainIndex = 1
	spec.attachmentsTrailerOffsetData = {}
	spec.attachmentsMaxWidth = 0
	spec.attachmentsMaxHeight = 0
	spec.attachmentsMaxLengthOffsetPos = 0
	spec.attachmentsMaxLengthOffsetNeg = 0
	spec.poseData = {}
	spec.vehicleObstacleId = nil
	spec.debugVehicle = nil
	spec.debugSizeBox = DebugCube.new()

	spec.debugSizeBox:setColor(0, 1, 1)

	spec.debugFrontMarker = DebugGizmo.new()
	spec.debugDump = nil
end

function AIDrivable:onPostLoad()
	local spec = self.spec_aiDrivable
	local aiRootNode = self:getAIRootNode()
	spec.attacherJointOffsets = {}

	if self.getAttacherJoints ~= nil then
		for _, attacherJoint in ipairs(self:getAttacherJoints()) do
			local node = attacherJoint.jointTransform
			local xDir, yDir, zDir = localDirectionToLocal(node, aiRootNode, 0, 0, 1)
			local xUp, yUp, zUp = localDirectionToLocal(node, aiRootNode, 0, 1, 0)
			local x, y, z = localToLocal(node, aiRootNode, 0, 0, 0)

			table.insert(spec.attacherJointOffsets, {
				x = x,
				y = y,
				z = z,
				xDir = xDir,
				yDir = yDir,
				zDir = zDir,
				xUp = xUp,
				yUp = yUp,
				zUp = zUp
			})
		end
	end
end

function AIDrivable:onDelete()
	local spec = self.spec_aiDrivable
end

function AIDrivable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_aiDrivable

	if self.isServer then
		if spec.isRunning then
			local isStillBlocked = spec.lastIsBlocked and self:getLastSpeed() < 5
			local isCurrentlyBlocked = math.abs(spec.lastMaxSpeed) > 0 and self:getLastSpeed() < 1

			if isCurrentlyBlocked or isStillBlocked then
				spec.stuckTime = spec.stuckTime + dt
			else
				spec.stuckTime = 0
			end

			local isBlocked = spec.stuckTime > 5000
			local aiRootNode = self:getAIRootNode()
			local x, y, z = getWorldTranslation(aiRootNode)
			spec.distanceToTarget = MathUtil.vector2Length(x - spec.targetX, z - spec.targetZ)
			local lastSpeed = self.lastSpeedReal * self.movingDirection * 1000
			local maxSpeed = math.min(spec.maxSpeed, self:getCruiseControlMaxSpeed())

			if spec.useManualDriving then
				local tx, _, tz = worldToLocal(aiRootNode, spec.targetX, spec.targetY, spec.targetZ)

				AIVehicleUtil.driveToPoint(self, dt, 1, true, true, tx, tz, maxSpeed, false)

				spec.lastMaxSpeed = maxSpeed

				if spec.distanceToTarget < 0.5 then
					self:reachedAITarget()
				end
			else
				local dirX, dirY, dirZ = localDirectionToWorld(aiRootNode, 0, 0, 1)

				self:updateAIAgentPoseData()

				local curvature, maxSpeedCurvature, status = getVehicleNavigationAgentNextCurvature(spec.agentId, spec.poseData, lastSpeed)

				if spec.debugDump ~= nil then
					spec.debugDump:addData(dt, x, y, z, dirX, dirY, dirZ, lastSpeed, curvature, maxSpeed, status)
				end

				if status == AgentState.DRIVING then
					maxSpeed = math.min(maxSpeedCurvature * 3.6, maxSpeed)

					AIVehicleUtil.driveAlongCurvature(self, dt, curvature, maxSpeed, 1)
				elseif status == AgentState.PLANNING then
					self:brake(1)
				elseif status == AgentState.BLOCKED then
					isBlocked = true
				elseif status == AgentState.TARGET_REACHED then
					self:reachedAITarget()
				elseif status == AgentState.NOT_REACHABLE then
					self:stopCurrentAIJob(AIMessageErrorNotReachable.new())
				end

				spec.lastState = status
				spec.lastMaxSpeed = maxSpeed
			end

			if spec.debugVehicle ~= nil then
				spec.debugVehicle:update(dt)
			end

			if isBlocked and not spec.lastIsBlocked then
				g_server:broadcastEvent(AIVehicleIsBlockedEvent.new(self, true), true, nil, self)
			elseif not isBlocked and spec.lastIsBlocked then
				g_server:broadcastEvent(AIVehicleIsBlockedEvent.new(self, false), true, nil, self)
			end

			spec.lastIsBlocked = isBlocked

			SpecializationUtil.raiseEvent(self, "onAIDriveableActive")
		end

		if spec.vehicleObstacleId ~= nil then
			local speed = self.lastSpeedReal * 1000
			local poses = self:getAIAgentPoses(speed)

			g_currentMission.aiSystem:setVehiclObstaclePose(spec.vehicleObstacleId, speed, poses)
		end
	end
end

function AIDrivable:createAgent(helperIndex)
	if self.isServer then
		local spec = self.spec_aiDrivable

		self:updateAIAgentAttachments()

		local trailerData = spec.attachmentsTrailerOffsetData
		local navigationMapId = g_currentMission.aiSystem:getNavigationMap()
		local agent = spec.agentInfo
		local width, length, lengthOffset, frontOffset = self:getAIAgentSize()
		local maxBrakeAcceleration = self:getAIAgentMaxBrakeAcceleration()
		local maxCentripedalAcceleration = agent.maxCentripedalAcceleration
		local minTurningRadius = self:getAITurningRadius(self.maxTurningRadius)
		local minLandingTurningRadius = minTurningRadius
		local allowBackwards = self:getAIAllowsBackwards()
		spec.agentId = createVehicleNavigationAgent(navigationMapId, minTurningRadius, minLandingTurningRadius, allowBackwards, width, length, lengthOffset, frontOffset, maxBrakeAcceleration, maxCentripedalAcceleration, trailerData)

		self:setAIVehicleObstacleStateDirty()

		if g_currentMission.aiSystem.debugEnabled then
			if spec.debugVehicle ~= nil then
				spec.debugVehicle:delete()
			end

			spec.debugVehicle = AIDebugVehicle.new(self, {
				math.random(),
				math.random(),
				math.random()
			})

			if spec.debugDump ~= nil then
				spec.debugDump:delete()
			end

			spec.debugDump = AIDebugDump.new(self, spec.agentId)

			spec.debugDump:startRecording(minTurningRadius, allowBackwards, width, length, lengthOffset, frontOffset, maxBrakeAcceleration, maxCentripedalAcceleration)
		end

		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			enableVehicleNavigationAgentDebugRendering(spec.agentId, true)
		end
	end
end

function AIDrivable:deleteAgent()
	local spec = self.spec_aiDrivable
	spec.isRunning = false

	self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)

	if spec.debugDump ~= nil then
		spec.debugDump:delete()

		spec.debugDump = nil
	end

	if spec.agentId ~= nil then
		delete(spec.agentId)

		spec.agentId = nil
	end

	self:setAIVehicleObstacleStateDirty()
end

function AIDrivable:setAITarget(task, x, y, z, dirX, dirY, dirZ, maxSpeed, useManualDriving)
	local spec = self.spec_aiDrivable
	local aiRootNode = self:getAIRootNode()
	local cx, cy, cz = getWorldTranslation(aiRootNode)
	local cDirX, cDirY, cDirZ = localDirectionToWorld(aiRootNode, 0, 0, 1)
	spec.useManualDriving = Utils.getNoNil(useManualDriving, false)
	spec.isRunning = true
	spec.task = task
	spec.maxSpeed = maxSpeed or math.huge
	spec.targetZ = z
	spec.targetY = y
	spec.targetX = x
	spec.targetDirZ = dirZ or 0
	spec.targetDirY = dirY
	spec.targetDirX = dirX or 0
	spec.distanceToTarget = MathUtil.vector2Length(cx - x, cz - z)

	if not spec.useManualDriving and self.isServer then
		setVehicleNavigationAgentTarget(spec.agentId, x, y, z, dirX, dirY, dirZ)
	end

	if spec.debugVehicle ~= nil then
		spec.debugVehicle:setTarget(x, y, z, dirX, dirY, dirZ)
	end

	if spec.debugDump ~= nil then
		spec.debugDump:setTarget(x, y, z, dirX, dirY, dirZ, cx, cy, cz, cDirX, cDirY, cDirZ, spec.maxSpeed)
	end

	SpecializationUtil.raiseEvent(self, "onAIDriveableStart")
end

function AIDrivable:reachedAITarget()
	local spec = self.spec_aiDrivable

	if self.isServer then
		local lastTask = spec.task

		if lastTask ~= nil then
			lastTask:onTargetReached()
		end
	end
end

function AIDrivable:unsetAITarget()
	local spec = self.spec_aiDrivable
	spec.isRunning = false
	spec.task = nil
	spec.useManualDriving = false

	self:brake(1)
	self:stopVehicle()
	self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)
	SpecializationUtil.raiseEvent(self, "onAIDriveableEnd")
end

function AIDrivable:getAIRootNode()
	return self.components[1].node
end

function AIDrivable:getAIAllowsBackwards()
	return false
end

function AIDrivable:onEnterVehicle(isControlling)
	if isControlling then
		addConsoleCommand("gsAISetTurnRadius", "Set Turn radius", "consoleCommandSetTurnRadius", self)
		addConsoleCommand("gsAIMoveVehicle", "Moves vehicles", "consoleCommandMove", self)
		addConsoleCommand("gsAIClearPath", "Clears debug path", "consoleCommandClearPath", self)
	end
end

function AIDrivable:onLeaveVehicle(wasEntered)
	if wasEntered then
		removeConsoleCommand("gsAISetTurnRadius")
		removeConsoleCommand("gsAIMoveVehicle")
		removeConsoleCommand("gsAIClearPath")
	end
end

function AIDrivable:getIsAIReadyToDrive(superFunc)
	for _, vehicle in ipairs(self.rootVehicle.childVehicles) do
		if vehicle ~= self and vehicle.getIsAIReadyToDrive ~= nil and not vehicle:getIsAIReadyToDrive() then
			return false, vehicle
		end
	end

	return superFunc(self)
end

function AIDrivable:getIsAIPreparingToDrive(superFunc)
	for _, vehicle in ipairs(self.rootVehicle.childVehicles) do
		if vehicle ~= self and vehicle.getIsAIPreparingToDrive ~= nil and vehicle:getIsAIPreparingToDrive() then
			return true
		end
	end

	return superFunc(self)
end

function AIDrivable:drawDebugAIAgent()
	local spec = self.spec_aiDrivable
	local aiRootNode = self:getAIRootNode()
	local groundOffset = 0.05
	local width, length, lengthOffset, frontOffset, height = self:getAIAgentSize()

	spec.debugSizeBox:createWithNode(aiRootNode, width * 0.5, height * 0.5, length * 0.5, 0, height * 0.5, lengthOffset)
	spec.debugSizeBox:draw()

	local fx, _, fz = localToWorld(aiRootNode, 0, 0, frontOffset)
	local dirX, dirY, dirZ = localDirectionToWorld(aiRootNode, 0, 0, 1)
	local upX, upY, upZ = localDirectionToWorld(aiRootNode, 0, 1, 0)
	local fy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, fx, 0, fz) + 0.05

	spec.debugFrontMarker:createWithWorldPosAndDir(fx, fy, fz, dirX, dirY, dirZ, upX, upY, upZ, "FrontMarker", false, nil, 3)
	spec.debugFrontMarker:draw()

	local x, y, z = getWorldTranslation(aiRootNode)

	if spec.isRunning then
		local text = nil

		if spec.useManualDriving then
			text = string.format("Distance: %.2f", spec.distanceToTarget)
		else
			text = AIDrivable.STATES[spec.lastState]
		end

		Utils.renderTextAtWorldPosition(x, y + 4, z, text, 0.015, 0, {
			1,
			1,
			1,
			1
		})
	end

	if spec.debugVehicle ~= nil then
		spec.debugVehicle:draw(y + 0.1)
	end

	local sx, _, sz = localToWorld(aiRootNode, 0, 0.2, 0)
	local lx, _, lz = localToWorld(aiRootNode, 20, 0.2, 0)
	local rx, _, rz = localToWorld(aiRootNode, -20, 0.2, 0)
	local sy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, sx, 0, sz) + groundOffset
	local ly = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, lx, 0, lz) + groundOffset
	local ry = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, rx, 0, rz) + groundOffset

	drawDebugLine(sx, sy, sz, 1, 0, 0, lx, ly, lz, 1, 0, 0)
	drawDebugLine(sx, sy, sz, 0, 1, 0, rx, ry, rz, 0, 1, 0)

	local dirX1, dirZ1 = MathUtil.vector2Normalize(lx - sx, lz - sz)
	local maxTurningRadius = self.maxTurningRadius
	local currentTurnRadius = self:getTurningRadiusByRotTime(self.rotatedTime)
	local minRadius = self:getAITurningRadius(self.maxTurningRadius)
	local revTime = self:getSteeringRotTimeByCurvature(1 / (currentTurnRadius * (self.rotatedTime >= 0 and 1 or -1)))
	local debugString = string.format([[
ReferenceRadius: %.3fm
MinRadius: %.3fm
Calc Radius: %.3f
RotatedTime: %.3f
RevTime: %.3f]], currentTurnRadius, maxTurningRadius, minRadius, self.rotatedTime, revTime)

	Utils.renderTextAtWorldPosition(sx, sy + 5, sz, debugString, getCorrectTextSize(0.012), 0)

	local wheelSpec = self.spec_wheels

	for _, wheel in ipairs(wheelSpec.wheels) do
		local wsx, _, wsz = localToWorld(wheel.driveNode, 0, 0, 0)
		local wlx, _, wlz = localToWorld(wheel.driveNode, 20, 0, 0)
		local wrx, _, wrz = localToWorld(wheel.driveNode, -20, 0, 0)
		local wsy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wsx, 0, wsz) + groundOffset
		local wly = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wlx, 0, wlz) + groundOffset
		local wry = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wrx, 0, wrz) + groundOffset

		drawDebugLine(wsx, wsy, wsz, 1, 0, 0, wlx, wly, wlz, 1, 0, 0)
		drawDebugLine(wsx, wsy, wsz, 0, 1, 0, wrx, wry, wrz, 0, 1, 0)
	end

	if wheelSpec.steeringCenterNode ~= nil then
		DebugUtil.drawDebugNode(wheelSpec.steeringCenterNode, "SCN", false, nil)
	end

	local sign = MathUtil.sign(self.rotatedTime)
	local cx = sx + sign * dirX1 * currentTurnRadius
	local cz = sz + sign * dirZ1 * currentTurnRadius

	DebugUtil.drawDebugGizmoAtWorldPos(cx, sy, cz, dirX1, 0, dirZ1, 0, 1, 0, "X", false, nil, 3)
end

function AIDrivable:loadAgentInfoFromXML(xmlFile, agent)
	local baseSizeKey = "vehicle.ai.agent"
	agent.width = xmlFile:getValue(baseSizeKey .. "#width", Vehicle.DEFAULT_SIZE.width)
	agent.length = xmlFile:getValue(baseSizeKey .. "#length", Vehicle.DEFAULT_SIZE.length)
	agent.height = xmlFile:getValue(baseSizeKey .. "#height", Vehicle.DEFAULT_SIZE.height)
	agent.lengthOffset = xmlFile:getValue(baseSizeKey .. "#lengthOffset", Vehicle.DEFAULT_SIZE.lengthOffset)
	agent.frontOffset = xmlFile:getValue(baseSizeKey .. "#frontOffset", 3)
	agent.maxBrakeAcceleration = xmlFile:getValue(baseSizeKey .. "#maxBrakeAcceleration", 5)
	agent.maxCentripedalAcceleration = xmlFile:getValue(baseSizeKey .. "#maxCentripedalAcceleration", 1)

	for name, id in pairs(self.configurations) do
		local specializationKey = g_configurationManager:getConfigurationAttribute(name, "xmlKey")

		if specializationKey ~= nil then
			specializationKey = "." .. specializationKey
		else
			specializationKey = ""
		end

		local key = string.format("vehicle%s.%sConfigurations.%sConfiguration(%d).aiAgent", specializationKey, name, name, id - 1)
		agent.width = math.max(agent.width, xmlFile:getValue(key .. "#width", 0))
		agent.length = math.max(agent.length, xmlFile:getValue(key .. "#length", 0))
		agent.height = math.max(agent.height, xmlFile:getValue(key .. "#height", 0))
		agent.lengthOffset = xmlFile:getValue(key .. "#lengthOffset", agent.lengthOffset)
		agent.frontOffset = xmlFile:getValue(key .. "#frontOffset", agent.frontOffset)
		agent.maxBrakeAcceleration = math.min(xmlFile:getValue(key .. "#maxBrakeAcceleration", agent.maxBrakeAcceleration))
		agent.maxCentripedalAcceleration = math.min(xmlFile:getValue(key .. "#maxCentripedalAcceleration", agent.maxCentripedalAcceleration))
	end
end

function AIDrivable:getAIAgentSize()
	local spec = self.spec_aiDrivable
	local agent = spec.agentInfo
	local width = math.max(agent.width, spec.attachmentsMaxWidth)
	local height = math.max(agent.height, spec.attachmentsMaxHeight)
	local length = agent.length
	local lengthOffset = agent.lengthOffset
	length = length + spec.attachmentsMaxLengthOffsetPos - spec.attachmentsMaxLengthOffsetNeg
	lengthOffset = lengthOffset + spec.attachmentsMaxLengthOffsetPos * 0.5 + spec.attachmentsMaxLengthOffsetNeg * 0.5

	return width, length, lengthOffset, agent.frontOffset, height
end

function AIDrivable:getAIAgentMaxBrakeAcceleration()
	local spec = self.spec_aiDrivable
	local agent = spec.agentInfo

	return agent.maxBrakeAcceleration
end

function AIDrivable:updateAIAgentAttachments()
	local spec = self.spec_aiDrivable
	spec.attachments = {}
	spec.attachmentChains = {}
	spec.attachmentChainIndex = 1
	spec.attachmentsTrailerOffsetData = {}
	spec.attachmentsMaxWidth = 0
	spec.attachmentsMaxHeight = 0
	spec.attachmentsMaxLengthOffsetPos = 0
	spec.attachmentsMaxLengthOffsetNeg = 0

	self:collectAIAgentAttachments(self)
	self:updateAIAgentAttachmentOffsetData()
	self:updateAIAgentPoseData()
end

function AIDrivable:addAIAgentAttachment(attachmentData, level)
	local spec = self.spec_aiDrivable
	spec.attachmentsMaxWidth = math.max(spec.attachmentsMaxWidth, attachmentData.width)
	spec.attachmentsMaxHeight = math.max(spec.attachmentsMaxHeight, attachmentData.height)
	attachmentData.level = level

	if spec.attachmentChains[spec.attachmentChainIndex] == nil then
		spec.attachmentChains[spec.attachmentChainIndex] = {}
	end

	table.insert(spec.attachments, attachmentData)
	table.insert(spec.attachmentChains[spec.attachmentChainIndex], attachmentData)
end

function AIDrivable:startNewAIAgentAttachmentChain()
	local spec = self.spec_aiDrivable

	if spec.attachmentChains[spec.attachmentChainIndex] ~= nil then
		spec.attachmentChainIndex = spec.attachmentChainIndex + 1
	end
end

function AIDrivable:updateAIAgentAttachmentOffsetData()
	local spec = self.spec_aiDrivable
	local _, agentLength, lengthOffset, _ = self:getAIAgentSize()
	local numTrailers = 0

	for ci = 1, #spec.attachmentChains do
		local chainAttachments = spec.attachmentChains[ci]
		local isDynamicChain = true
		local isStaticChain = true
		local parentSteeringCenterNode = self.components[1].node
		local parentSteeringCenterOffsetZ = lengthOffset

		for i = 1, #chainAttachments do
			local agentAttachment = chainAttachments[i]

			if agentAttachment.rotCenterNode ~= nil and isDynamicChain then
				if numTrailers < AIDrivable.TRAILER_LIMIT then
					local jointNode = agentAttachment.jointNode or agentAttachment.jointNodeDynamic
					local attacherVehicleJointNode = agentAttachment.attacherVehicleJointNode or jointNode

					if attacherVehicleJointNode ~= nil and jointNode ~= nil then
						local x1, _, z1 = getWorldTranslation(attacherVehicleJointNode)
						local x2, _, z2 = localToWorld(parentSteeringCenterNode, 0, 0, -parentSteeringCenterOffsetZ)
						local tractorHitchOffset = -MathUtil.vector2Length(x1 - x2, z1 - z2)
						x1, _, z1 = getWorldTranslation(jointNode)
						x2, _, z2 = getWorldTranslation(agentAttachment.rotCenterNode)
						local trailerHitchOffset = MathUtil.vector2Length(x1 - x2, z1 - z2)
						local centerOffset = agentAttachment.lengthOffset + agentLength * 0.5 - agentAttachment.length * 0.5
						local hasCollision = 0

						table.insert(spec.attachmentsTrailerOffsetData, tractorHitchOffset)
						table.insert(spec.attachmentsTrailerOffsetData, trailerHitchOffset)
						table.insert(spec.attachmentsTrailerOffsetData, centerOffset)
						table.insert(spec.attachmentsTrailerOffsetData, hasCollision)

						parentSteeringCenterNode = agentAttachment.rotCenterNode
						parentSteeringCenterOffsetZ = 0
						numTrailers = numTrailers + 1
					end

					isStaticChain = false
				end
			elseif isStaticChain then
				isDynamicChain = false
				local aiRootNode = self:getAIRootNode()
				local _, _, z1 = localToLocal(agentAttachment.rootNode, aiRootNode, 0, 0, agentAttachment.length * 0.5)
				local _, _, z2 = localToLocal(agentAttachment.rootNode, aiRootNode, 0, 0, -agentAttachment.length * 0.5)
				local minZ = -spec.agentInfo.length * 0.5 + spec.agentInfo.lengthOffset
				local maxZ = spec.agentInfo.length * 0.5 + spec.agentInfo.lengthOffset
				local zDiffNeg = math.min(0, z1 - minZ, z2 - minZ)
				local zDiffPos = math.max(0, z1 - maxZ, z2 - maxZ)
				spec.attachmentsMaxLengthOffsetPos = math.max(spec.attachmentsMaxLengthOffsetPos, zDiffPos)
				spec.attachmentsMaxLengthOffsetNeg = math.min(spec.attachmentsMaxLengthOffsetNeg, zDiffNeg)
			end
		end
	end
end

function AIDrivable:updateAIAgentPoseData()
	local spec = self.spec_aiDrivable
	local aiRootNode = self:getAIRootNode()
	spec.poseData[1], spec.poseData[2], spec.poseData[3] = getWorldTranslation(aiRootNode)
	spec.poseData[4], spec.poseData[5], spec.poseData[6] = localDirectionToWorld(aiRootNode, 0, 0, 1)
	local numTrailers = 0
	local currentIndex = 6

	for ci = 1, #spec.attachmentChains do
		local chainAttachments = spec.attachmentChains[ci]
		local isDynamicChain = true

		for i = 1, #chainAttachments do
			local agentAttachment = chainAttachments[i]

			if agentAttachment.rotCenterNode ~= nil and isDynamicChain then
				if numTrailers < AIDrivable.TRAILER_LIMIT then
					spec.poseData[currentIndex + 1], spec.poseData[currentIndex + 2], spec.poseData[currentIndex + 3] = getWorldTranslation(agentAttachment.rotCenterNode)
					spec.poseData[currentIndex + 4], spec.poseData[currentIndex + 5], spec.poseData[currentIndex + 6] = localDirectionToWorld(agentAttachment.rotCenterNode, 0, 0, 1)
					numTrailers = numTrailers + 1
					currentIndex = currentIndex + 6
				end
			else
				isDynamicChain = false
			end
		end
	end

	while currentIndex < #spec.poseData do
		table.remove(spec.poseData, #spec.poseData)
	end
end

function AIDrivable:prepareForAIDriving()
	self:raiseAIEvent("onAIDrivablePrepare", "onAIImplementPrepare")
end

function AIDrivable:getAITurningRadius(minRadius)
	return minRadius
end

function AIDrivable:getCanHaveAIVehicleObstacle(superFunc)
	local spec = self.spec_aiDrivable

	if spec.agentId ~= nil then
		return false
	end

	return superFunc(self)
end

function AIDrivable:consoleCommandClearPath()
	local spec = self.spec_aiDrivable

	if spec.debugVehicle ~= nil then
		spec.debugVehicle:clear()
	end
end

function AIDrivable:consoleCommandSetTurnRadius(turnRadius)
	turnRadius = tonumber(turnRadius) or 10
	local rotatedTime = self:getSteeringRotTimeByCurvature(1 / turnRadius)
	local axisSide = nil

	if rotatedTime > 0 then
		axisSide = rotatedTime / -self.maxRotTime
	else
		axisSide = rotatedTime / self.minRotTime
	end

	axisSide = self:getSteeringDirection() * axisSide
	self.spec_drivable.axisSide = axisSide
end

function AIDrivable:consoleCommandMove(distance)
	local vehicles = {}
	local attachedVehicles = self:getChildVehicles()

	for _, vehicle in ipairs(attachedVehicles) do
		vehicle:removeFromPhysics()
		table.insert(vehicles, vehicle)
	end

	local aiRootNode = self:getAIRootNode()
	local dirX, dirY, dirZ = localDirectionToWorld(aiRootNode, 1, 0, 0)
	local moveX = dirX * distance
	local moveY = dirY * distance
	local moveZ = dirZ * distance
	local currentTurnRadius = self:getTurningRadiusByRotTime(self.rotatedTime)
	local gizmo = DebugGizmo.new()
	local x, y, z = localToWorld(aiRootNode, currentTurnRadius, 0.05, 0)

	gizmo:createWithWorldPosAndDir(x, y, z, 0, 0, 1, 0, 1, 0, "", false, nil)
	g_debugManager:addPermanentElement(gizmo)

	currentTurnRadius = -currentTurnRadius + distance
	self.rotatedTime = self:getSteeringRotTimeByCurvature(1 / currentTurnRadius)

	if self.rotatedTime < 0 then
		self.spec_wheels.axisSide = self.rotatedTime / -self.maxRotTime / self:getSteeringDirection()
	else
		self.spec_wheels.axisSide = self.rotatedTime / self.minRotTime / self:getSteeringDirection()
	end

	for _, vehicle in ipairs(vehicles) do
		for _, component in ipairs(vehicle.components) do
			x, y, z = getWorldTranslation(component.node)

			setWorldTranslation(component.node, x + moveX, y + moveY, z + moveZ)
		end
	end

	for _, vehicle in ipairs(vehicles) do
		vehicle:addToPhysics()
	end
end
