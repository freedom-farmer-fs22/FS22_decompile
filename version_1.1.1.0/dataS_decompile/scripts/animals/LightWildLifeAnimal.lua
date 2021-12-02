LightWildlifeAnimal = {}
local LightWildlifeAnimal_mt = Class(LightWildlifeAnimal)

function LightWildlifeAnimal.new(spawner, id, nodeId, shaderNode, customMt)
	local self = setmetatable({}, customMt or LightWildlifeAnimal_mt)
	self.stateMachine = FSMUtil.create()
	self.spawner = spawner
	self.id = id
	self.i3dNodeId = nodeId
	self.shaderNode = shaderNode
	self.animation = {
		currentOpcode = 0,
		currentSpeed = 0,
		transitionTimer = 0,
		transitionCurrentTimer = 0,
		transitionOpcode = 0,
		transitionSpeed = 0
	}
	self.steering = {
		targetX = 0,
		targetY = 0,
		targetZ = 0,
		speed = 0,
		velocityX = 0,
		velocityY = 0,
		velocityZ = 0,
		wanderAngle = 0,
		maxVelocity = 0,
		seekPercent = 0,
		wanderPercent = 0,
		separationPercent = 0,
		wanderX = 0,
		wanderY = 0,
		wanderZ = 0,
		wanderTimer = 0,
		maxForce = 0.5,
		mass = 1,
		radius = 1
	}
	self.steering.radiusSq = self.steering.radius * self.steering.radius
	self.guide = {
		enabled = false,
		totalDuration = 0,
		time = 0,
		fromPositionX = 0,
		fromPositionY = 0,
		fromPositionZ = 0,
		toPositionX = 0,
		toPositionY = 0,
		toPositionZ = 0,
		lastPositionX = 0,
		lastPositionY = 0,
		lastPositionZ = 0,
		tiltingActive = false,
		tiltingAngle = 0
	}

	return self
end

function LightWildlifeAnimal:delete()
	self.stateMachine:changeState("default")
end

function LightWildlifeAnimal:init(spawnPosX, spawnPosZ, radius, states)
	local offsetX = math.random() * radius
	local offsetZ = math.random() * radius
	local posX = spawnPosX + offsetX
	local posZ = spawnPosZ + offsetZ
	local posY = self.spawner:getTerrainHeightWithProps(posX, posZ)

	setTranslation(self.i3dNodeId, posX, posY, posZ)
	setRotation(self.i3dNodeId, 0, math.rad(math.random(1, 360)), 0)
	setShaderParameter(self.shaderNode, self.spawner.shaderParmId, self.id, 0, 0, 0, false)

	for _, state in pairs(states) do
		self.stateMachine:addState(state.id, state.classObject.new(state.id, self, self.stateMachine))
	end

	self.stateMachine:changeState("default")
end

function LightWildlifeAnimal:update(dt)
	if self.guide.enabled then
		self:updateGuided(dt)
	else
		self:updateKinematic(dt)
	end

	self.stateMachine:update(dt)
end

function LightWildlifeAnimal:initGuided(targetX, targetY, targetZ, duration)
	self.guide.fromPositionX, self.guide.fromPositionY, self.guide.fromPositionZ = getWorldTranslation(self.i3dNodeId)
	self.guide.toPositionX = targetX
	self.guide.toPositionY = targetY
	self.guide.toPositionZ = targetZ
	self.guide.lastPositionX = self.guide.fromPositionX
	self.guide.lastPositionY = self.guide.fromPositionY
	self.guide.lastPositionZ = self.guide.fromPositionZ
	self.guide.enabled = true
	self.guide.time = 0
	self.guide.totalDuration = duration
end

function LightWildlifeAnimal:updateGuided(dt)
	self.guide.time = self.guide.time + dt
	local t = self.guide.time / self.guide.totalDuration

	if t > 1 then
		t = 1
		self.guide.enabled = false
		self.guide.tiltingActive = false
	end

	if t < 0.5 then
		t = 2 * t * t
	else
		t = 1 - math.pow(-2 * t + 2, 2) / 2
	end

	local newPosX = self.guide.fromPositionX + (self.guide.toPositionX - self.guide.fromPositionX) * t
	local newPosY = MathUtil.lerp(self.guide.fromPositionY, self.guide.toPositionY, t)
	local newPosZ = self.guide.fromPositionZ + (self.guide.toPositionZ - self.guide.fromPositionZ) * t
	local dirX = newPosX - self.guide.lastPositionX
	local dirY = newPosY - self.guide.lastPositionY
	local dirZ = newPosZ - self.guide.lastPositionZ
	dirX, dirY, dirZ = MathUtil.vector3Normalize(dirX, dirY, dirZ)
	self.guide.lastPositionX = newPosX
	self.guide.lastPositionY = newPosY
	self.guide.lastPositionZ = newPosZ

	setDirection(self.i3dNodeId, dirX, dirY, dirZ, 0, 1, 0)
	setWorldTranslation(self.i3dNodeId, newPosX, newPosY, newPosZ)

	if self.guide.tiltingActive then
		rotateAboutLocalAxis(self.i3dNodeId, MathUtil.degToRad(self.guide.tiltingAngle), 1, 0, 0)
	end
end

function LightWildlifeAnimal:updateKinematic(dt)
	local dtInSec = dt * 0.001
	local seekForceX = 0
	local seekForceY = 0
	local seekForceZ = 0

	if self.steering.seekPercent > 0 then
		seekForceX, seekForceY, seekForceZ = self:calculateSeekForce()
		seekForceX, seekForceY, seekForceZ = MathUtil.vector3Clamp(seekForceX, seekForceY, seekForceZ, 0, self.steering.maxForce)
	end

	local wanderForceX = 0
	local wanderForceY = 0
	local wanderForceZ = 0

	if self.steering.wanderPercent > 0 then
		wanderForceX, wanderForceY, wanderForceZ = self:calculateWanderForce()
		wanderForceX, wanderForceY, wanderForceZ = MathUtil.vector3Clamp(wanderForceX, wanderForceY, wanderForceZ, 0, self.steering.maxForce)
	end

	local separateForceX = 0
	local separateForceY = 0
	local separateForceZ = 0

	if self.steering.separationPercent > 0 then
		separateForceX, separateForceY, separateForceZ = self:calculateSeparateForce()
		separateForceX, separateForceY, separateForceZ = MathUtil.vector3Clamp(separateForceX, separateForceY, separateForceZ, 0, self.steering.maxForce)
	end

	local totalForceX = self.steering.seekPercent * seekForceX + self.steering.wanderPercent * wanderForceX + self.steering.separationPercent * separateForceX
	local totalForceY = self.steering.seekPercent * seekForceY + self.steering.wanderPercent * wanderForceY + self.steering.separationPercent * separateForceY
	local totalForceZ = self.steering.seekPercent * seekForceZ + self.steering.wanderPercent * wanderForceZ + self.steering.separationPercent * separateForceZ
	totalForceX = totalForceX / self.steering.mass
	totalForceY = totalForceY / self.steering.mass
	totalForceZ = totalForceZ / self.steering.mass
	self.steering.velocityX = self.steering.velocityX + totalForceX
	self.steering.velocityY = self.steering.velocityY + totalForceY
	self.steering.velocityZ = self.steering.velocityZ + totalForceZ
	self.steering.velocityX, self.steering.velocityY, self.steering.velocityZ = MathUtil.vector3Clamp(self.steering.velocityX, self.steering.velocityY, self.steering.velocityZ, 0, self.steering.maxVelocity)
	local positionX, positionY, positionZ = getWorldTranslation(self.i3dNodeId)
	local terrainY = self.spawner:getTerrainHeightWithProps(positionX, positionZ)
	positionX = positionX + self.steering.velocityX * dtInSec
	positionY = math.max(positionY + self.steering.velocityY * dtInSec, terrainY)
	positionZ = positionZ + self.steering.velocityZ * dtInSec

	if self.steering.velocityX > 0 or self.steering.velocityY > 0 or self.steering.velocityZ > 0 then
		local newDirX, newDirY, newDirZ = MathUtil.vector3Normalize(self.steering.velocityX, self.steering.velocityY, self.steering.velocityZ)

		setDirection(self.i3dNodeId, newDirX, newDirY, newDirZ, 0, 1, 0)
	end

	setWorldTranslation(self.i3dNodeId, positionX, positionY, positionZ)
end

function LightWildlifeAnimal:calculateSeparateForce()
	local positionX, positionY, positionZ = getWorldTranslation(self.i3dNodeId)
	local count = 0
	local sumX = 0
	local sumY = 0
	local sumZ = 0

	for _, animal in pairs(self.spawner.animals) do
		local animalX, animalY, animalZ = getWorldTranslation(animal.i3dNodeId)
		local deltaX = positionX - animalX
		local deltaY = positionY - animalY
		local deltaZ = positionZ - animalZ
		local deltaXSq = deltaX * deltaX
		local deltaYSq = deltaY * deltaY
		local deltaZSq = deltaZ * deltaZ
		local distSq = deltaXSq + deltaYSq + deltaZSq

		if distSq > 0 and distSq < self.steering.radiusSq then
			local dist = math.sqrt(distSq)
			local normDeltaX, normDeltaY, normDeltaZ = MathUtil.vector3Normalize(deltaX, deltaY, deltaZ)
			normDeltaZ = normDeltaZ / dist
			normDeltaY = normDeltaY / dist
			normDeltaX = normDeltaX / dist
			sumZ = sumZ + normDeltaZ
			sumY = sumY + normDeltaY
			sumX = sumX + normDeltaX
			count = count + 1
		end
	end

	if count > 0 then
		sumZ = sumZ / count
		sumY = sumY / count
		sumX = sumX / count
		sumX, sumY, sumZ = MathUtil.vector3SetLength(sumX, sumY, sumZ, self.steering.maxVelocity)

		return sumX - self.steering.velocityX, sumY - self.steering.velocityY, sumZ - self.steering.velocityZ
	end

	return 0, 0, 0
end

function LightWildlifeAnimal:calculateWanderForce()
	if self.steering.velocityX ~= 0 and self.steering.velocityY ~= 0 and self.steering.velocityZ ~= 0 then
		local circleCenterX = self.steering.velocityX
		local circleCenterY = self.steering.velocityY
		local circleCenterZ = self.steering.velocityZ
		local circleDistance = 5
		local circleRadius = 1
		local angleChange = MathUtil.degToRad(35)
		self.steering.wanderAngle = self.steering.wanderAngle + math.random() * angleChange - angleChange * 0.5
		circleCenterX, circleCenterY, circleCenterZ = MathUtil.vector3Normalize(circleCenterX, circleCenterY, circleCenterZ)
		circleCenterX = circleCenterX * circleDistance
		circleCenterY = circleCenterY * circleDistance
		circleCenterZ = circleCenterZ * circleDistance
		local displacementX = math.cos(self.steering.wanderAngle) * circleRadius
		local displacementY = 0
		local displacementZ = math.sin(self.steering.wanderAngle) * circleRadius
		local wanderForceX = circleCenterX + displacementX
		local wanderForceY = circleCenterY + displacementY
		local wanderForceZ = circleCenterZ + displacementZ

		return wanderForceX, wanderForceY, wanderForceZ
	end

	return 0, 0, 0, 0
end

function LightWildlifeAnimal:calculateSeekForce()
	local positionX, positionY, positionZ = getWorldTranslation(self.i3dNodeId)
	local dirToTargetX = self.steering.targetX - positionX
	local dirToTargetY = self.steering.targetY - positionY
	local dirToTargetZ = self.steering.targetZ - positionZ

	if dirToTargetX ~= 0 or dirToTargetY ~= 0 or dirToTargetZ ~= 0 then
		dirToTargetX, dirToTargetY, dirToTargetZ = MathUtil.vector3Normalize(dirToTargetX, dirToTargetY, dirToTargetZ)
		local desiredVelX = dirToTargetX * self.steering.maxVelocity
		local desiredVelY = dirToTargetY * self.steering.maxVelocity
		local desiredVelZ = dirToTargetZ * self.steering.maxVelocity

		return desiredVelX - self.steering.velocityX, desiredVelY - self.steering.velocityY, desiredVelZ - self.steering.velocityZ
	end

	return 0, 0, 0
end

function LightWildlifeAnimal:setTarget(x, y, z)
	self.steering.targetX = x
	self.steering.targetY = y
	self.steering.targetZ = z
end

function LightWildlifeAnimal:isNearTarget(distance)
	local positionX, positionY, positionZ = getWorldTranslation(self.i3dNodeId)
	local dirToTargetX = self.steering.targetX - positionX
	local dirToTargetY = self.steering.targetY - positionY
	local dirToTargetZ = self.steering.targetZ - positionZ
	local distanceSq = dirToTargetX * dirToTargetX + dirToTargetY * dirToTargetY + dirToTargetZ * dirToTargetZ

	return distanceSq < distance * distance
end

function LightWildlifeAnimal:isNearGround(distanceToGround)
	local positionX, positionY, positionZ = getWorldTranslation(self.i3dNodeId)
	local groundY = self.spawner:getTerrainHeightWithProps(positionX, positionZ)

	return distanceToGround >= positionY - groundY
end

function LightWildlifeAnimal:isNearestPlayerClose(distance)
	local testDistanceSq = distance * distance
	local positionX, positionY, positionZ = getWorldTranslation(self.i3dNodeId)
	local minDistSq = nil
	local nearPosX = 0
	local nearPosY = 0
	local nearPosZ = 0

	for _, player in pairs(g_currentMission.players) do
		if player.isControlled then
			local playerX, playerY, playerZ = getWorldTranslation(player.rootNode)
			local deltaX = playerX - positionX
			local deltaY = playerY - positionY
			local deltaZ = playerZ - positionZ
			local distSq = deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ

			if minDistSq == nil or minDistSq ~= nil and distSq < minDistSq then
				minDistSq = distSq
				nearPosZ = playerZ
				nearPosY = playerY
				nearPosX = playerX
			end
		end
	end

	for _, enterable in pairs(g_currentMission.enterables) do
		if enterable:getIsEntered() then
			local px, py, pz = getWorldTranslation(enterable.rootNode)
			local deltaX = px - positionX
			local deltaY = py - positionY
			local deltaZ = pz - positionZ
			local distSq = deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ

			if minDistSq == nil or minDistSq ~= nil and distSq < minDistSq then
				minDistSq = distSq
				nearPosZ = pz
				nearPosY = py
				nearPosX = px
			end
		end
	end

	if minDistSq == nil then
		return false
	end

	return minDistSq < testDistanceSq, nearPosX, nearPosY, nearPosZ
end

function LightWildlifeAnimal:chooseRandomTarget(minDistance, maxDistance, minHeight, maxHeight, fleePosX, fleePosZ)
	local finalDirX, finalDirZ = nil

	if fleePosX ~= nil and fleePosZ ~= nil then
		local posX, _, posZ = getWorldTranslation(self.i3dNodeId)
		local dirX = posX - fleePosX
		local dirZ = posZ - fleePosZ
		dirX, dirZ = MathUtil.vector2Normalize(dirX, dirZ)
		finalDirZ = dirZ
		finalDirX = dirX
	else
		local randomAngle = math.random() * 30
		local angleChange = MathUtil.degToRad(randomAngle)
		local x = -math.sin(angleChange)
		local z = math.cos(angleChange)
		local dirX, _, dirZ = localDirectionToWorld(self.i3dNodeId, x, 0, z)
		finalDirZ = dirZ
		finalDirX = dirX
	end

	local deltaDist = maxDistance - minDistance
	local distance = minDistance + math.random() * deltaDist
	local positionX, _, positionZ = getWorldTranslation(self.i3dNodeId)
	positionZ = positionZ + finalDirZ * distance
	positionX = positionX + finalDirX * distance
	local deltaHeight = maxHeight - minHeight
	local positionY = minHeight + math.random() * deltaHeight
	local terrainY = self.spawner:getTerrainHeightWithProps(positionX, positionZ)
	positionY = positionY + terrainY

	self:setTarget(positionX, positionY, positionZ)
end

function LightWildlifeAnimal:chooseRandomTargetNotInWater(minDistance, maxDistance, minHeight, maxHeight, fleePosX, fleePosZ)
	local found = false
	local numTry = 2

	while not found and numTry > 0 do
		self:chooseRandomTarget(minDistance, maxDistance, minHeight, maxHeight, fleePosX, fleePosZ)

		found = not self.spawner:getIsInWater(self.steering.targetX, self.steering.targetY, self.steering.targetZ)
		numTry = numTry - 1
	end

	return found
end

function LightWildlifeAnimal:updateAnimation(dt)
	if self.animation.transitionCurrentTimer > 0 then
		self.animation.transitionCurrentTimer = math.max(self.animation.transitionCurrentTimer - dt, 0)

		if self.animation.transitionCurrentTimer == 0 then
			setShaderParameter(self.shaderNode, self.spawner.shaderParmOpcode, self.animation.transitionOpcode, 0, 0, 0, false)
			setShaderParameter(self.shaderNode, self.spawner.shaderParmSpeed, self.animation.transitionSpeed, 0, 0, 0, false)

			self.animation.currentOpcode = self.animation.transitionOpcode
			self.animation.currentSpeed = self.animation.transitionSpeed
			self.animation.transitionOpcode = 0
			self.animation.transitionSpeed = 0
		else
			local alpha = 1 - self.animation.transitionCurrentTimer / self.animation.transitionTimer

			setShaderParameter(self.shaderNode, self.spawner.shaderParmOpcode, self.animation.currentOpcode, self.animation.transitionOpcode, alpha, 0, false)
		end
	end

	if not self:checkAnimationState() then
		self:synchronizeAnimation()
	end
end

function LightWildlifeAnimal:synchronizeAnimation()
	local currentState = self.stateMachine.currentState.id
	local animation = self.spawner.animations[currentState]

	if animation.transitionTimer > 0 then
		self.animation.transitionCurrentTimer = animation.transitionTimer
		self.animation.transitionTimer = animation.transitionTimer
		self.animation.transitionOpcode = animation.opcode
		self.animation.transitionSpeed = animation.speed

		setShaderParameter(self.shaderNode, self.spawner.shaderParmOpcode, self.animation.currentOpcode, self.animation.transitionOpcode, 0, 0, false)
		setShaderParameter(self.shaderNode, self.spawner.shaderParmSpeed, self.animation.currentSpeed, self.animation.transitionSpeed, 0, 0, false)
	end
end

function LightWildlifeAnimal:checkAnimationState()
	local currentState = self.stateMachine.currentState.id
	local animation = self.spawner.animations[currentState]

	if self.animation.transitionCurrentTimer > 0 and self.animation.transitionOpcode == animation.opcode then
		return true
	elseif self.animation.transitionCurrentTimer == 0 and self.animation.currentOpcode == animation.opcode then
		return true
	end

	return false
end
