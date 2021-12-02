source("dataS/scripts/vehicles/specializations/events/AIVehicleIsBlockedEvent.lua")
source("dataS/scripts/vehicles/specializations/events/AIFieldWorkerStateEvent.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategy.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyBaler.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyCollision.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyCombine.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyStraight.lua")
source("dataS/scripts/vehicles/ai/AIDriveStrategyConveyor.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategy.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyDefault.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyBulb1.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyBulb2.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyBulb3.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyHalfCircle.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyDefaultReverse.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyBulb1Reverse.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyBulb2Reverse.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyBulb3Reverse.lua")
source("dataS/scripts/vehicles/ai/AITurnStrategyHalfCircleReverse.lua")

AIFieldWorker = {
	TRAFFIC_COLLISION_BOX_FILENAME = "data/shared/ai/trafficCollision.i3d",
	TRAFFIC_COLLISION = 0,
	hiredHirables = {},
	aiUpdateLowFrequencyDelay = 4,
	aiUpdateDelay = 2,
	aiUpdateDelayLowFps = 1
}

function AIFieldWorker.deleteCollisionBox()
	if AIFieldWorker.TRAFFIC_COLLISION ~= 0 then
		delete(AIFieldWorker.TRAFFIC_COLLISION)

		AIFieldWorker.TRAFFIC_COLLISION = 0
	end
end

function AIFieldWorker.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(AIJobVehicle, specializations) and SpecializationUtil.hasSpecialization(Drivable, specializations)
end

function AIFieldWorker.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("AIFieldWorker")
	schema:register(XMLValueType.FLOAT, "vehicle.ai.didNotMoveTimeout#value", "Did not move time out time", 5000)
	schema:register(XMLValueType.BOOL, "vehicle.ai.didNotMoveTimeout#deactivated", "Did not move time out deactivated", false)
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame

	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).aiFieldWorker#lastTurnDirection", "Last AI turn direction")
	Vehicle.registerStateChange("AI_START_LINE")
	Vehicle.registerStateChange("AI_END_LINE")
	g_i3DManager:loadI3DFileAsync(AIFieldWorker.TRAFFIC_COLLISION_BOX_FILENAME, true, false, AIFieldWorker.onTrafficCollisionLoaded, nil, )
end

function AIFieldWorker.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerStart")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerActive")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerEnd")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerStartTurn")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerTurnProgress")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerEndTurn")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerBlock")
	SpecializationUtil.registerEvent(vehicleType, "onAIFieldWorkerContinue")
end

function AIFieldWorker.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getIsFieldWorkActive", AIFieldWorker.getIsFieldWorkActive)
	SpecializationUtil.registerFunction(vehicleType, "getAICollisionTriggers", AIFieldWorker.getAICollisionTriggers)
	SpecializationUtil.registerFunction(vehicleType, "startFieldWorker", AIFieldWorker.startFieldWorker)
	SpecializationUtil.registerFunction(vehicleType, "stopFieldWorker", AIFieldWorker.stopFieldWorker)
	SpecializationUtil.registerFunction(vehicleType, "getDirectionSnapAngle", AIFieldWorker.getDirectionSnapAngle)
	SpecializationUtil.registerFunction(vehicleType, "getAINeedsTrafficCollisionBox", AIFieldWorker.getAINeedsTrafficCollisionBox)
	SpecializationUtil.registerFunction(vehicleType, "clearAIDebugTexts", AIFieldWorker.clearAIDebugTexts)
	SpecializationUtil.registerFunction(vehicleType, "addAIDebugText", AIFieldWorker.addAIDebugText)
	SpecializationUtil.registerFunction(vehicleType, "clearAIDebugLines", AIFieldWorker.clearAIDebugLines)
	SpecializationUtil.registerFunction(vehicleType, "addAIDebugLine", AIFieldWorker.addAIDebugLine)
	SpecializationUtil.registerFunction(vehicleType, "updateAIFieldWorker", AIFieldWorker.updateAIFieldWorker)
	SpecializationUtil.registerFunction(vehicleType, "updateAIFieldWorkerImplementData", AIFieldWorker.updateAIFieldWorkerImplementData)
	SpecializationUtil.registerFunction(vehicleType, "updateAIFieldWorkerDriveStrategies", AIFieldWorker.updateAIFieldWorkerDriveStrategies)
	SpecializationUtil.registerFunction(vehicleType, "updateAIFieldWorkerLowFrequency", AIFieldWorker.updateAIFieldWorkerLowFrequency)
	SpecializationUtil.registerFunction(vehicleType, "aiFieldWorkerStartTurn", AIFieldWorker.aiFieldWorkerStartTurn)
	SpecializationUtil.registerFunction(vehicleType, "aiFieldWorkerTurnProgress", AIFieldWorker.aiFieldWorkerTurnProgress)
	SpecializationUtil.registerFunction(vehicleType, "aiFieldWorkerEndTurn", AIFieldWorker.aiFieldWorkerEndTurn)
	SpecializationUtil.registerFunction(vehicleType, "getCanAIFieldWorkerContinueWork", AIFieldWorker.getCanAIFieldWorkerContinueWork)
	SpecializationUtil.registerFunction(vehicleType, "getAIFieldWorkerIsTurning", AIFieldWorker.getAIFieldWorkerIsTurning)
	SpecializationUtil.registerFunction(vehicleType, "getAIFieldWorkerLastTurnDirection", AIFieldWorker.getAIFieldWorkerLastTurnDirection)
	SpecializationUtil.registerFunction(vehicleType, "getAttachedAIImplements", AIFieldWorker.getAttachedAIImplements)
	SpecializationUtil.registerFunction(vehicleType, "getCanStartFieldWork", AIFieldWorker.getCanStartFieldWork)
end

function AIFieldWorker.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "aiBlock", AIFieldWorker.aiBlock)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "aiContinue", AIFieldWorker.aiContinue)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getStartableAIJob", AIFieldWorker.getStartableAIJob)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getHasStartableAIJob", AIFieldWorker.getHasStartableAIJob)
end

function AIFieldWorker.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIFieldWorker)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIFieldWorker)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AIFieldWorker)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIFieldWorker)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AIFieldWorker)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AIFieldWorker)
end

function AIFieldWorker:onLoad(savegame)
	local spec = self.spec_aiFieldWorker
	spec.aiImplementList = {}
	spec.aiImplementDataDirtyFlag = true
	spec.aiDriveParams = {
		valid = false
	}
	spec.aiUpdateLowFrequencyDt = 0
	spec.aiUpdateDt = 0
	spec.driveStrategies = {}
	spec.aiTrafficCollision = nil
	spec.aiTrafficCollisionTranslation = {
		0,
		0,
		10
	}
	spec.debugTexts = {}
	spec.debugLines = {}
	spec.fieldJob = g_currentMission.aiJobTypeManager:createJob(AIJobType.FIELDWORK)
	spec.didNotMoveTimeout = self.xmlFile:getValue("vehicle.ai.didNotMoveTimeout#value", 5000)

	if self.xmlFile:getValue("vehicle.ai.didNotMoveTimeout#deactivated") then
		spec.didNotMoveTimeout = math.huge
	end

	spec.didNotMoveTimer = spec.didNotMoveTimeout
	spec.isActive = false
	spec.lastTurnDirection = false

	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onUpdateTick", AIFieldWorker)
	end

	if savegame ~= nil and not savegame.resetVehicles then
		spec.lastTurnDirection = savegame.xmlFile:getValue(savegame.key .. ".aiFieldWorker#lastTurnDirection", spec.lastTurnDirection)
	end
end

function AIFieldWorker:onDelete()
	local spec = self.spec_aiFieldWorker

	if spec.aiTrafficCollision ~= nil and entityExists(spec.aiTrafficCollision) then
		delete(spec.aiTrafficCollision)

		spec.aiTrafficCollision = nil
	end
end

function AIFieldWorker:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_aiFieldWorker

	xmlFile:setValue(key .. "#lastTurnDirection", spec.lastTurnDirection)
end

function AIFieldWorker:onReadStream(streamId, connection)
	if streamReadBool(streamId) then
		self:startFieldWorker()
	end
end

function AIFieldWorker:onWriteStream(streamId, connection)
	local spec = self.spec_aiFieldWorker

	streamWriteBool(streamId, spec.isActive)
end

function AIFieldWorker:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_aiFieldWorker

	if spec.checkImplementDirection then
		spec.checkImplementDirection = false

		for _, implement in pairs(self:getAttachedAIImplements()) do
			if implement.object:getAINeedsRootAlignment() then
				local yRot = Utils.getYRotationBetweenNodes(self.components[1].node, implement.object.components[1].node, self.yRotationOffset, implement.object.yRotationOffset)

				if math.abs(yRot) > math.pi / 2 then
					self:stopCurrentAIJob(AIMessageErrorImplementWrongWay.new())

					return
				end
			end
		end
	end

	if VehicleDebug.state == VehicleDebug.DEBUG_AI and self.isActiveForInputIgnoreSelectionIgnoreAI then
		if #spec.debugTexts > 0 then
			for i, text in pairs(spec.debugTexts) do
				renderText(0.7, 0.9 - 0.02 * i, 0.02, text)
			end
		end

		if #spec.debugLines > 0 then
			for _, l in pairs(spec.debugLines) do
				drawDebugLine(l.s[1], l.s[2], l.s[3], l.c[1], l.c[2], l.c[3], l.e[1], l.e[2], l.e[3], l.c[1], l.c[2], l.c[3])
			end
		end
	end

	if spec.aiImplementDataDirtyFlag then
		spec.aiImplementDataDirtyFlag = false

		self:updateAIFieldWorkerImplementData()
	end

	if self:getIsFieldWorkActive() and self.isServer then
		if spec.aiTrafficCollision ~= nil and not self:getAIFieldWorkerIsTurning() then
			local x, y, z = localToWorld(self.components[1].node, unpack(spec.aiTrafficCollisionTranslation))

			setTranslation(spec.aiTrafficCollision, x, y, z)
			setRotation(spec.aiTrafficCollision, localRotationToWorld(self.components[1].node, 0, 0, 0))
		end

		if spec.driveStrategies ~= nil then
			for i = 1, #spec.driveStrategies do
				local driveStrategy = spec.driveStrategies[i]

				driveStrategy:update(dt)
			end
		end

		local hirableIndex = 0

		for hirable in pairs(AIFieldWorker.hiredHirables) do
			if self == hirable then
				break
			end

			hirableIndex = hirableIndex + 1
		end

		spec.aiUpdateLowFrequencyDt = spec.aiUpdateLowFrequencyDt + dt

		if (g_updateLoopIndex + hirableIndex) % AIFieldWorker.aiUpdateLowFrequencyDelay == 0 then
			self:updateAIFieldWorkerLowFrequency(spec.aiUpdateLowFrequencyDt)

			spec.aiUpdateLowFrequencyDt = 0
		end

		spec.aiUpdateDt = spec.aiUpdateDt + dt
		local aiUpdateDelay = dt > 25 and AIFieldWorker.aiUpdateDelayLowFps or AIFieldWorker.aiUpdateDelay

		if (g_updateLoopIndex + hirableIndex) % aiUpdateDelay == 0 then
			self:updateAIFieldWorker(spec.aiUpdateDt)

			spec.aiUpdateDt = 0
		end
	end
end

function AIFieldWorker:updateAIFieldWorker(dt)
	local spec = self.spec_aiFieldWorker

	if spec.aiDriveParams.valid then
		local moveForwards = spec.aiDriveParams.moveForwards
		local tX = spec.aiDriveParams.tX
		local tY = spec.aiDriveParams.tY
		local tZ = spec.aiDriveParams.tZ
		local maxSpeed = spec.aiDriveParams.maxSpeed
		local pX, _, pZ = worldToLocal(self:getAISteeringNode(), tX, tY, tZ)

		if not moveForwards and self.spec_articulatedAxis ~= nil and self.spec_articulatedAxis.aiRevereserNode ~= nil then
			pX, _, pZ = worldToLocal(self.spec_articulatedAxis.aiRevereserNode, tX, tY, tZ)
		end

		if not moveForwards and self:getAIReverserNode() ~= nil then
			pX, _, pZ = worldToLocal(self:getAIReverserNode(), tX, tY, tZ)
		end

		local acceleration = 1
		local isAllowedToDrive = maxSpeed ~= 0

		AIVehicleUtil.driveToPoint(self, dt, acceleration, isAllowedToDrive, moveForwards, pX, pZ, maxSpeed)
	end
end

function AIFieldWorker:getIsFieldWorkActive()
	local spec = self.spec_aiFieldWorker

	return spec.isActive
end

function AIFieldWorker:getStartableAIJob(superFunc)
	local job = superFunc(self)

	if job == nil then
		self:updateAIFieldWorkerImplementData()

		if self:getCanStartFieldWork() then
			local spec = self.spec_aiFieldWorker
			local fieldJob = spec.fieldJob

			fieldJob:applyCurrentState(self, g_currentMission, g_currentMission.player.farmId, true)
			fieldJob:setValues()

			local success = fieldJob:validate(false)

			if success then
				job = fieldJob
			end
		end
	end

	return job
end

function AIFieldWorker:getHasStartableAIJob(superFunc)
	return self:getCanStartFieldWork()
end

function AIFieldWorker:getCanStartFieldWork()
	local spec = self.spec_aiFieldWorker

	if spec.isActive then
		return false
	end

	if #spec.aiImplementList > 0 then
		return true
	end

	return false
end

function AIFieldWorker:startFieldWorker()
	local spec = self.spec_aiFieldWorker
	spec.isActive = true

	if self.isServer then
		self:updateAIFieldWorkerImplementData()
		self:updateAIFieldWorkerDriveStrategies()

		spec.checkImplementDirection = true
	end

	AIFieldWorker.hiredHirables[self] = self

	self:raiseAIEvent("onAIFieldWorkerStart", "onAIImplementStart")

	if self:getAINeedsTrafficCollisionBox() and AIFieldWorker.TRAFFIC_COLLISION ~= nil and AIFieldWorker.TRAFFIC_COLLISION ~= 0 and spec.aiTrafficCollision == nil then
		local collision = clone(AIFieldWorker.TRAFFIC_COLLISION, true, false, true)
		spec.aiTrafficCollision = collision
	end
end

function AIFieldWorker:stopFieldWorker()
	local spec = self.spec_aiFieldWorker
	AIFieldWorker.hiredHirables[self] = nil
	spec.aiDriveParams.valid = false

	self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF, true)

	if self.isServer then
		WheelsUtil.updateWheelsPhysics(self, 0, spec.lastSpeedReal * spec.movingDirection, 0, true, true)

		if spec.driveStrategies ~= nil and #spec.driveStrategies > 0 then
			for i = #spec.driveStrategies, 1, -1 do
				spec.driveStrategies[i]:delete()
				table.remove(spec.driveStrategies, i)
			end

			spec.driveStrategies = {}
		end
	end

	if self:getAINeedsTrafficCollisionBox() then
		setTranslation(spec.aiTrafficCollision, 0, -1000, 0)
	end

	if self.brake ~= nil then
		self:brake(1)
	end

	local actionController = self.rootVehicle.actionController

	if actionController ~= nil then
		actionController:resetCurrentState()
	end

	self:raiseAIEvent("onAIFieldWorkerEnd", "onAIImplementEnd")

	spec.isTurning = false
	spec.lastTurnStrategy = nil
	spec.isActive = false
end

function AIFieldWorker:getAICollisionTriggers(collisionTriggers)
end

function AIFieldWorker:getDirectionSnapAngle()
	return 0
end

function AIFieldWorker:getAINeedsTrafficCollisionBox()
	return self.isServer
end

function AIFieldWorker:clearAIDebugTexts()
	for i = #self.spec_aiFieldWorker.debugTexts, 1, -1 do
		self.spec_aiFieldWorker.debugTexts[i] = nil
	end
end

function AIFieldWorker:addAIDebugText(text)
	local spec = self.spec_aiFieldWorker

	table.insert(spec.debugTexts, text)
end

function AIFieldWorker:clearAIDebugLines()
	for i = #self.spec_aiFieldWorker.debugLines, 1, -1 do
		self.spec_aiFieldWorker.debugLines[i] = nil
	end
end

function AIFieldWorker:addAIDebugLine(s, e, c)
	local spec = self.spec_aiFieldWorker

	table.insert(spec.debugLines, {
		s = s,
		e = e,
		c = c
	})
end

function AIFieldWorker:onStateChange(state, data)
	if state == Vehicle.STATE_CHANGE_ATTACH or state == Vehicle.STATE_CHANGE_DETACH then
		local spec = self.spec_aiFieldWorker
		spec.aiImplementDataDirtyFlag = true
	end
end

function AIFieldWorker:updateAIFieldWorkerImplementData()
	local spec = self.spec_aiFieldWorker
	spec.aiImplementList = {}

	self:addVehicleToAIImplementList(spec.aiImplementList)
end

function AIFieldWorker:updateAIFieldWorkerDriveStrategies()
	local spec = self.spec_aiFieldWorker

	if #spec.aiImplementList > 0 then
		if spec.driveStrategies ~= nil and #spec.driveStrategies > 0 then
			for i = #spec.driveStrategies, 1, -1 do
				spec.driveStrategies[i]:delete()
				table.remove(spec.driveStrategies, i)
			end

			spec.driveStrategies = {}
		end

		local foundCombine = false
		local foundBaler = false

		for _, implement in pairs(spec.aiImplementList) do
			if SpecializationUtil.hasSpecialization(Combine, implement.object.specializations) then
				foundCombine = true
			end

			if SpecializationUtil.hasSpecialization(Baler, implement.object.specializations) then
				foundBaler = true
			end
		end

		foundCombine = foundCombine or SpecializationUtil.hasSpecialization(Combine, spec.specializations)

		if foundCombine then
			local driveStrategyCombine = AIDriveStrategyCombine.new()

			driveStrategyCombine:setAIVehicle(self)
			table.insert(spec.driveStrategies, driveStrategyCombine)
		end

		foundBaler = foundBaler or SpecializationUtil.hasSpecialization(Baler, spec.specializations)

		if foundBaler then
			local driveStrategyCombine = AIDriveStrategyBaler.new()

			driveStrategyCombine:setAIVehicle(self)
			table.insert(spec.driveStrategies, driveStrategyCombine)
		end

		local driveStrategyStraight = AIDriveStrategyStraight.new()
		local driveStrategyCollision = AIDriveStrategyCollision.new(driveStrategyStraight)

		driveStrategyCollision:setAIVehicle(self)
		driveStrategyStraight:setAIVehicle(self)
		table.insert(spec.driveStrategies, driveStrategyCollision)
		table.insert(spec.driveStrategies, driveStrategyStraight)
	end
end

function AIFieldWorker:updateAIFieldWorkerLowFrequency(dt)
	local spec = self.spec_aiFieldWorker

	self:clearAIDebugTexts()
	self:clearAIDebugLines()

	if self:getIsFieldWorkActive() then
		if spec.driveStrategies ~= nil and #spec.driveStrategies > 0 then
			local vX, vY, vZ = getWorldTranslation(self:getAISteeringNode())
			local tX, tZ, moveForwards, maxSpeedStra, maxSpeed, distanceToStop = nil

			for i = 1, #spec.driveStrategies do
				local driveStrategy = spec.driveStrategies[i]
				tX, tZ, moveForwards, maxSpeedStra, distanceToStop = driveStrategy:getDriveData(dt, vX, vY, vZ)
				maxSpeed = math.min(maxSpeedStra or math.huge, maxSpeed or math.huge)

				if tX ~= nil or not self:getIsFieldWorkActive() then
					break
				end
			end

			if tX == nil and self:getIsFieldWorkActive() then
				self:stopCurrentAIJob(AIMessageSuccessFinishedJob.new())
			end

			if not self:getIsFieldWorkActive() then
				return
			end

			local minimumSpeed = 5
			local lookAheadDistance = 5

			if self:getAIFieldWorkerIsTurning() then
				minimumSpeed = 1.5
				lookAheadDistance = 2
			end

			local distSpeed = math.max(minimumSpeed, maxSpeed * math.min(1, distanceToStop / lookAheadDistance))
			local speedLimit, _ = self:getSpeedLimit(true)
			maxSpeed = math.min(maxSpeed, distSpeed, speedLimit)
			maxSpeed = math.min(maxSpeed, self:getCruiseControlMaxSpeed())

			if VehicleDebug.state == VehicleDebug.DEBUG_AI then
				self:addAIDebugText(string.format("===> maxSpeed = %.2f", maxSpeed))
			end

			local isAllowedToDrive = maxSpeed ~= 0
			spec.aiDriveParams.moveForwards = moveForwards
			spec.aiDriveParams.tX = tX
			spec.aiDriveParams.tY = vY
			spec.aiDriveParams.tZ = tZ
			spec.aiDriveParams.maxSpeed = maxSpeed
			spec.aiDriveParams.valid = true

			if isAllowedToDrive and self:getLastSpeed() < 0.5 then
				spec.didNotMoveTimer = spec.didNotMoveTimer - dt
			else
				spec.didNotMoveTimer = spec.didNotMoveTimeout
			end

			if spec.didNotMoveTimer < 0 then
				if self:getAIFieldWorkerIsTurning() then
					if spec.lastTurnStrategy ~= nil then
						spec.lastTurnStrategy:skipTurnSegment()
					end
				else
					self:stopCurrentAIJob(AIMessageErrorBlockedByObject.new())
				end

				spec.didNotMoveTimer = spec.didNotMoveTimeout
			end
		end

		self:raiseAIEvent("onAIFieldWorkerActive", "onAIImplementActive")
	end
end

function AIFieldWorker:aiFieldWorkerStartTurn(left, turnStrategy)
	local spec = self.spec_aiFieldWorker
	spec.isTurning = true
	spec.lastTurnDirection = left
	spec.lastTurnStrategy = turnStrategy

	for i = 1, #spec.driveStrategies do
		local driveStrategy = spec.driveStrategies[i]

		if driveStrategy.setTurnData ~= nil then
			driveStrategy:setTurnData(left, turnStrategy)
		end
	end

	self:raiseAIEvent("onAIFieldWorkerStartTurn", "onAIImplementStartTurn", left, turnStrategy)
end

function AIFieldWorker:aiFieldWorkerTurnProgress(progress, left)
	self:raiseAIEvent("onAIFieldWorkerTurnProgress", "onAIImplementTurnProgress", progress, left)
end

function AIFieldWorker:aiFieldWorkerEndTurn(left)
	local spec = self.spec_aiFieldWorker
	spec.isTurning = false
	spec.lastTurnStrategy = nil

	for i = 1, #spec.driveStrategies do
		local driveStrategy = spec.driveStrategies[i]

		if driveStrategy.setTurnData ~= nil then
			driveStrategy:setTurnData()
		end
	end

	self:raiseAIEvent("onAIFieldWorkerEndTurn", "onAIImplementEndTurn", left)
end

function AIFieldWorker:aiBlock(superFunc)
	superFunc(self)
	self:raiseAIEvent("onAIFieldWorkerBlock", "onAIImplementBlock")
end

function AIFieldWorker:aiContinue(superFunc)
	superFunc(self)
	self:raiseAIEvent("onAIFieldWorkerContinue", "onAIImplementContinue")
end

function AIFieldWorker:getCanAIFieldWorkerContinueWork()
	for _, implement in ipairs(self:getAttachedAIImplements()) do
		local canContinue, stopAI, stopReason = implement.object:getCanAIImplementContinueWork()

		if not canContinue then
			return false, stopAI, stopReason
		end
	end

	if SpecializationUtil.hasSpecialization(AIImplement, self.specializations) then
		local canContinue, stopAI, stopReason = self:getCanAIImplementContinueWork()

		if not canContinue then
			return false, stopAI, stopReason
		end
	end

	return true, false
end

function AIFieldWorker:getAIFieldWorkerIsTurning()
	return self.spec_aiFieldWorker.isTurning
end

function AIFieldWorker:getAIFieldWorkerLastTurnDirection()
	return self.spec_aiFieldWorker.lastTurnDirection
end

function AIFieldWorker:getAttachedAIImplements()
	return self.spec_aiFieldWorker.aiImplementList
end

function AIFieldWorker.onTrafficCollisionLoaded(_, i3dNode)
	if i3dNode ~= 0 then
		local collision = getChildAt(i3dNode, 0)

		link(getRootNode(), collision)

		AIFieldWorker.TRAFFIC_COLLISION = collision

		delete(i3dNode)
	end
end
