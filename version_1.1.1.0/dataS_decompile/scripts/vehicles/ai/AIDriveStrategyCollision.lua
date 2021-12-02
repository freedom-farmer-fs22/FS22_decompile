AIDriveStrategyCollision = {}
local AIDriveStrategyCollision_mt = Class(AIDriveStrategyCollision, AIDriveStrategy)
AIDriveStrategyCollision.UPDATE_INTERVAL = 5
AIDriveStrategyCollision.TRIGGER_SUBDIVISIONS = 5

function AIDriveStrategyCollision.new(driveStrategyStraight, customMt)
	if customMt == nil then
		customMt = AIDriveStrategyCollision_mt
	end

	local self = AIDriveStrategy.new(customMt)
	self.driveStrategyStraight = driveStrategyStraight
	self.numCollidingVehicles = {}
	self.vehicleIgnoreList = {}
	self.collisionTriggerByVehicle = {}
	self.maxUpdateIndex = 1
	self.lastHasCollision = false

	return self
end

function AIDriveStrategyCollision:setAIVehicle(vehicle)
	AIDriveStrategyCollision:superClass().setAIVehicle(self, vehicle)

	if self.vehicle.isServer then
		self.collisionTriggerByVehicle = {}

		vehicle:getAICollisionTriggers(self.collisionTriggerByVehicle)

		if vehicle.getAIImplementCollisionTriggers ~= nil then
			vehicle:getAIImplementCollisionTriggers(self.collisionTriggerByVehicle)
		end

		self.rootVehicle = vehicle:getRootVehicle()
		local index = 1

		for v, trigger in pairs(self.collisionTriggerByVehicle) do
			trigger.updateIndex = index
			trigger.hasCollision = false
			trigger.isValid = true
			trigger.hitCounter = 0
			trigger.curTriggerLength = 5
			trigger.positions = {}

			for i = 1, AIDriveStrategyCollision.TRIGGER_SUBDIVISIONS * 3 do
				table.insert(trigger.positions, 0)
			end

			index = index + AIDriveStrategyCollision.UPDATE_INTERVAL
		end

		self.maxUpdateIndex = index
	end
end

function AIDriveStrategyCollision:update(dt)
	local currentIndex = g_updateLoopIndex % self.maxUpdateIndex

	for v, trigger in pairs(self.collisionTriggerByVehicle) do
		if trigger.updateIndex == currentIndex then
			self:generateTriggerPath(v, trigger)

			if trigger.isValid then
				trigger.hitCounter = 0
				local dx, dy, dz = localDirectionToWorld(trigger.node, 0, 0, 1)

				getVehicleCollisionDistance(trigger.positions, dx, dy, dz, trigger.width, trigger.height, "onVehicleCollisionDistanceCallback", self, trigger, CollisionMask.TRIGGER_AI_COLLISION, true, false, true)
			end
		end
	end

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		for v, trigger in pairs(self.collisionTriggerByVehicle) do
			self:generateTriggerPath(v, trigger)

			if trigger.isValid then
				for i = 1, #trigger.positions - 3, 3 do
					drawDebugLine(trigger.positions[i + 0], trigger.positions[i + 1] + 2, trigger.positions[i + 2], 1, 0, 0, trigger.positions[i + 3], trigger.positions[i + 4] + 2, trigger.positions[i + 5], 0, 1, 0, true)
				end

				local dx, dy, dz = localDirectionToWorld(trigger.node, 0, 0, 1)

				debugDrawVehicleCollision(trigger.positions, dx, dy, dz, trigger.width, trigger.height)
			end
		end
	end
end

function AIDriveStrategyCollision:generateTriggerPath(vehicle, trigger)
	trigger.positions[1], trigger.positions[2], trigger.positions[3] = getWorldTranslation(trigger.node)
	trigger.positions[2] = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, trigger.positions[1], trigger.positions[2], trigger.positions[3]) + trigger.height * 0.5
	trigger.isValid = self.vehicle.movingDirection >= 0 or trigger.hasCollision

	if trigger.isValid then
		if not trigger.hasCollision then
			trigger.curTriggerLength = MathUtil.clamp(self.vehicle:getLastSpeed() * 0.75, math.min(3, trigger.length), trigger.length)
		end

		local posIndex = 3
		local pointToPointDistance = trigger.curTriggerLength / AIDriveStrategyCollision.TRIGGER_SUBDIVISIONS
		local remainingDistance = trigger.curTriggerLength
		local remainingPoints = AIDriveStrategyCollision.TRIGGER_SUBDIVISIONS
		local px, _, pz = localToWorld(trigger.node, 0, 0, pointToPointDistance)
		trigger.positions[posIndex + 3] = pz
		trigger.positions[posIndex + 2] = trigger.positions[2]
		trigger.positions[posIndex + 1] = px
		posIndex = posIndex + 3
		remainingDistance = remainingDistance - pointToPointDistance
		remainingPoints = remainingPoints - 1
		local _, _, zOffset = worldToLocal(self.vehicle:getAIDirectionNode(), trigger.positions[1], trigger.positions[2], trigger.positions[3])

		if zOffset >= 0 or vehicle == self.vehicle then
			if self.turnStrategy ~= nil then
				if not self.turnStrategy:calculatePathPrediction(trigger.positions, trigger.node, px, trigger.positions[2], pz, posIndex, pointToPointDistance, remainingDistance, remainingPoints) then
					trigger.isValid = false
				end
			else
				local x, z = MathUtil.projectOnLine(px, pz, self.vehicle.aiDriveTarget[1], self.vehicle.aiDriveTarget[2], self.vehicle.aiDriveDirection[1], self.vehicle.aiDriveDirection[2])

				for i = 1, remainingPoints do
					z = z + self.vehicle.aiDriveDirection[2] * pointToPointDistance
					x = x + self.vehicle.aiDriveDirection[1] * pointToPointDistance
					trigger.positions[posIndex + 3] = z
					trigger.positions[posIndex + 2] = trigger.positions[2]
					trigger.positions[posIndex + 1] = x
					posIndex = posIndex + 3
				end
			end
		else
			local target = self.vehicle:getAIDirectionNode()

			if self.collisionTriggerByVehicle[self.vehicle] ~= nil then
				target = self.collisionTriggerByVehicle[self.vehicle].node
			end

			local sx = trigger.positions[1]
			local sy = trigger.positions[2]
			local sz = trigger.positions[3]
			local ex, ey, ez = getWorldTranslation(target)
			local dirX, _, dirZ = MathUtil.vector3Normalize(ex - sx, ey - sy, ez - sz)

			for i = 1, remainingPoints do
				trigger.positions[posIndex + 3] = trigger.positions[posIndex] + dirZ * pointToPointDistance
				trigger.positions[posIndex + 2] = trigger.positions[2]
				trigger.positions[posIndex + 1] = trigger.positions[posIndex - 2] + dirX * pointToPointDistance
				posIndex = posIndex + 3
			end
		end
	end
end

function AIDriveStrategyCollision:getDriveData(dt, vX, vY, vZ)
	if self.vehicle.movingDirection < 0 and self.vehicle:getLastSpeed(true) > 2 then
		return nil, , , , 
	end

	for v, trigger in pairs(self.collisionTriggerByVehicle) do
		if trigger.hasCollision then
			local tX, _, tZ = localToWorld(self.vehicle:getAIDirectionNode(), 0, 0, 1)

			if VehicleDebug.state == VehicleDebug.DEBUG_AI then
				self.vehicle:addAIDebugText(" AIDriveStrategyCollision :: STOP due to collision")
			end

			self:setHasCollision(true)

			return tX, tZ, true, 0, math.huge
		end
	end

	self:setHasCollision(false)

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		self.vehicle:addAIDebugText(" AIDriveStrategyCollision :: no collision")
	end

	return nil, , , , 
end

function AIDriveStrategyCollision:setTurnData(isLeft, turnStrategy)
	self.turnStrategy = turnStrategy
end

function AIDriveStrategyCollision:setHasCollision(state)
	if state ~= self.lastHasCollision then
		self.lastHasCollision = state

		if g_server ~= nil then
			g_server:broadcastEvent(AIVehicleIsBlockedEvent.new(self.vehicle, state), true, nil, self.vehicle)
		end
	end
end

function AIDriveStrategyCollision:updateDriving(dt)
end

function AIDriveStrategyCollision:onVehicleCollisionDistanceCheckFinished(trigger)
	trigger.hasCollision = trigger.hitCounter > 0
end

function AIDriveStrategyCollision:onVehicleCollisionDistanceCallback(distance, objectId, subShapeIndex, isLast, trigger)
	if g_currentMission ~= nil and self.collisionTriggerByVehicle ~= nil then
		if objectId ~= 0 then
			local vehicle = g_currentMission.nodeToObject[objectId]

			if self.collisionTriggerByVehicle[vehicle] == nil and not getHasTrigger(objectId) and (vehicle == nil or vehicle.getRootVehicle == nil or vehicle:getRootVehicle() ~= self.rootVehicle) then
				trigger.hitCounter = trigger.hitCounter + 1
			end
		end

		if objectId == 0 or isLast then
			self:onVehicleCollisionDistanceCheckFinished(trigger)

			return false
		else
			return true
		end
	end
end
