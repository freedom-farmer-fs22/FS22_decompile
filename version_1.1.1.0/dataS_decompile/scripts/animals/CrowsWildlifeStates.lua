CrowStateDefault = {}
local CrowStateDefault_mt = Class(CrowStateDefault, SimpleState)

function CrowStateDefault.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowStateDefault_mt)

	return self
end

function CrowStateDefault:activate(parms)
	CrowStateDefault:superClass().activate(self, parms)

	local foundgroundTarget = self.owner:chooseRandomTargetNotInWater(2, 2.5, 0, 0)

	if foundgroundTarget then
		self.stateMachine:changeState("idle_walk")
	else
		self.owner:chooseRandomTargetNotInWater(40, 50, 5, 10, self.owner.steering.targetX, self.owner.steering.targetZ)
		self.stateMachine:changeState("takeOff")
	end
end

CrowStateFlyGlide = {}
local CrowStateFlyGlide_mt = Class(CrowStateFlyGlide, SimpleState)

function CrowStateFlyGlide.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowStateFlyGlide_mt)
	self.glideTimer = 10000
	self.timer = 0

	return self
end

function CrowStateFlyGlide:activate(parms)
	CrowStateFlyGlide:superClass().activate(self, parms)

	self.timer = self.glideTimer
	self.owner.steering.seekPercent = 0.6
	self.owner.steering.wanderPercent = 0.3
	self.owner.steering.separationPercent = 0.1
	self.owner.steering.maxForce = 0.1
end

function CrowStateFlyGlide:deactivate()
	CrowStateFlyGlide:superClass().deactivate(self)

	self.owner.steering.maxForce = 0.5
end

function CrowStateFlyGlide:update(dt)
	CrowStateFlyGlide:superClass().update(self, dt)

	self.timer = math.max(self.timer - dt, 0)

	if self.timer == 0 or self.owner:isNearTarget(0.5) then
		local x, y, z = getWorldTranslation(self.owner.i3dNodeId)
		local terrainHeight = self.owner.spawner:getTerrainHeightWithProps(x, z)
		y = math.max(y - terrainHeight, 5)

		self.owner:chooseRandomTargetNotInWater(5, 10, y - 5, y + 5)
		self.stateMachine:changeState("fly")
	end
end

CrowStateFly = {}
local CrowStateFly_mt = Class(CrowStateFly, SimpleState)

function CrowStateFly.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowStateFly_mt)

	return self
end

function CrowStateFly:activate(parms)
	CrowStateFly:superClass().activate(self, parms)

	self.owner.steering.seekPercent = 0.8
	self.owner.steering.wanderPercent = 0.1
	self.owner.steering.separationPercent = 0.1
	self.owner.steering.maxVelocity = 8.2 + math.random() * 2
	self.owner.steering.maxForce = 1
end

function CrowStateFly:deactivate()
	CrowStateFly:superClass().deactivate(self)

	self.owner.steering.maxForce = 0.5
end

function CrowStateFly:update(dt)
	CrowStateFly:superClass().update(self, dt)

	if self.owner:isNearTarget(0.5) then
		local choice = math.random()

		if choice < 0.5 then
			local x, y, z = getWorldTranslation(self.owner.i3dNodeId)
			local terrainHeight = self.owner.spawner:getTerrainHeightWithProps(x, z)
			y = math.max(y - terrainHeight, 5)

			self.owner:chooseRandomTargetNotInWater(10, 5, y - 5, y)
			self.stateMachine:changeState("fly_glide")
		elseif choice < 0.85 then
			local x, y, z = getWorldTranslation(self.owner.i3dNodeId)
			local terrainHeight = self.owner.spawner:getTerrainHeightWithProps(x, z)
			y = math.max(y - terrainHeight, 5)

			self.owner:chooseRandomTargetNotInWater(5, 15, y, y + 5)
		else
			self.owner:chooseRandomTargetNotInWater(35, 50, 0, 0)
			self.stateMachine:changeState("flyDown")
		end
	end
end

CrowStateFlyUp = {}
local CrowStateFlyUp_mt = Class(CrowStateFlyUp, SimpleState)

function CrowStateFlyUp.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowStateFlyUp_mt)

	return self
end

function CrowStateFlyUp:activate(parms)
	CrowStateFlyUp:superClass().activate(self, parms)

	self.owner.steering.seekPercent = 0.8
	self.owner.steering.wanderPercent = 0.1
	self.owner.steering.separationPercent = 0.1
	self.owner.steering.maxVelocity = 8.2 + math.random() * 2
	self.owner.steering.maxForce = 1

	self.owner:initGuided(self.owner.steering.targetX, self.owner.steering.targetY, self.owner.steering.targetZ, 5000)
end

function CrowStateFlyUp:deactivate()
	CrowStateFlyUp:superClass().deactivate(self)

	self.owner.steering.maxForce = 0.5
end

function CrowStateFlyUp:update(dt)
	CrowStateFlyUp:superClass().update(self, dt)

	if self.owner:isNearTarget(0.5) then
		local choice = math.random()

		if choice < 0.5 then
			local x, y, z = getWorldTranslation(self.owner.i3dNodeId)
			local terrainHeight = self.owner.spawner:getTerrainHeightWithProps(x, z)
			y = math.max(y - terrainHeight, 5)

			self.owner:chooseRandomTargetNotInWater(10, 5, y - 5, y)
			self.stateMachine:changeState("fly_glide")
		else
			local x, y, z = getWorldTranslation(self.owner.i3dNodeId)
			local terrainHeight = self.owner.spawner:getTerrainHeightWithProps(x, z)
			y = math.max(y - terrainHeight, 5)

			self.owner:chooseRandomTargetNotInWater(5, 15, y, y + 5)
		end
	end
end

CrowStateFlyDown = {}
local CrowStateFlyDown_mt = Class(CrowStateFlyDown, SimpleState)

function CrowStateFlyDown.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowStateFlyDown_mt)

	return self
end

function CrowStateFlyDown:activate(parms)
	CrowStateFlyDown:superClass().activate(self, parms)

	self.owner.steering.seekPercent = 0.8
	self.owner.steering.wanderPercent = 0.1
	self.owner.steering.separationPercent = 0.1
	self.owner.steering.maxVelocity = 8.2 + math.random() * 2
	self.owner.steering.maxForce = 1

	self.owner:initGuided(self.owner.steering.targetX, self.owner.steering.targetY + 0.1, self.owner.steering.targetZ, 5000)
end

function CrowStateFlyDown:deactivate()
	CrowStateFlyDown:superClass().deactivate(self)

	self.owner.steering.maxForce = 0.5
end

function CrowStateFlyDown:update(dt)
	CrowStateFlyDown:superClass().update(self, dt)

	if self.owner:isNearGround(8) then
		self.stateMachine:changeState("flyDownFlapping")
	end
end

CrowStateFlyDownFlapping = {}
local CrowStateFlyDownFlapping_mt = Class(CrowStateFlyDownFlapping, SimpleState)

function CrowStateFlyDownFlapping.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowStateFlyDownFlapping_mt)

	return self
end

function CrowStateFlyDownFlapping:activate(parms)
	CrowStateFlyDown:superClass().activate(self, parms)

	self.owner.guide.tiltingActive = true
	self.owner.guide.tiltingAngle = -45
end

function CrowStateFlyDownFlapping:deactivate()
	CrowStateFlyDown:superClass().deactivate(self)

	self.owner.steering.maxForce = 0.5
end

function CrowStateFlyDownFlapping:update(dt)
	CrowStateFlyDown:superClass().update(self, dt)

	if self.owner:isNearGround(0.5) then
		self.stateMachine:changeState("land")
	end
end

CrowStateLand = {}
local CrowStateLand_mt = Class(CrowStateLand, SimpleState)

function CrowStateLand.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowStateLand_mt)

	return self
end

function CrowStateLand:activate(parms)
	CrowStateLand:superClass().activate(self, parms)

	self.owner.steering.seekPercent = 1
	self.owner.steering.wanderPercent = 0
	self.owner.steering.separationPercent = 0
	self.owner.steering.maxVelocity = 3.2 + math.random() * 2
end

function CrowStateLand:update(dt)
	CrowStateLand:superClass().update(self, dt)

	if self.owner:isNearGround(0) then
		self.stateMachine:changeState("idle_walk")
	end
end

CrowStateTakeOff = {}
local CrowStateTakeOff_mt = Class(CrowStateTakeOff, SimpleState)

function CrowStateTakeOff.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowStateTakeOff_mt)

	return self
end

function CrowStateTakeOff:activate(parms)
	CrowStateTakeOff:superClass().activate(self, parms)

	self.owner.steering.seekPercent = 0.6
	self.owner.steering.wanderPercent = 0.4
	self.owner.steering.separationPercent = 0
	self.owner.steering.maxVelocity = 24.2 + math.random() * 2
	self.owner.steering.maxForce = 10.5

	if self.owner.spawner.soundFSM.currentState.id == CrowsWildlife.CROW_SOUND_STATES.CALM_GROUND then
		self.owner.spawner.soundFSM:changeState(CrowsWildlife.CROW_SOUND_STATES.TAKEOFF)
	end
end

function CrowStateTakeOff:deactivate()
	CrowStateTakeOff:superClass().deactivate(self)

	self.owner.steering.maxForce = 0.5
end

function CrowStateTakeOff:update(dt)
	CrowStateTakeOff:superClass().update(self, dt)
	self.stateMachine:changeState("flyUp")
end

CrowStateIdleWalk = {}
local CrowStateIdleWalk_mt = Class(CrowStateIdleWalk, SimpleState)

function CrowStateIdleWalk.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowStateIdleWalk_mt)

	return self
end

function CrowStateIdleWalk:activate(parms)
	CrowStateIdleWalk:superClass().activate(self, parms)

	self.owner.steering.seekPercent = 0.3
	self.owner.steering.wanderPercent = 0.7
	self.owner.steering.separationPercent = 0
	self.owner.steering.maxVelocity = 0.7 + math.random() * 0.1
end

function CrowStateIdleWalk:update(dt)
	CrowStateIdleWalk:superClass().update(self, dt)

	if self.owner:isNearestPlayerClose(15) then
		self.stateMachine:changeState("idle_attention")
	elseif self.owner:isNearTarget(0.5) then
		local choice = math.random(1, 2)

		if choice == 1 then
			self.stateMachine:changeState("idle_eat")
		elseif choice == 2 then
			self.owner:chooseRandomTargetNotInWater(0, 5, 0, 0)
		end
	end
end

CrowStateIdleEat = {}
local CrowStateIdleEat_mt = Class(CrowStateIdleEat, SimpleState)

function CrowStateIdleEat.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowStateIdleEat_mt)
	self.eatTimer = 1000
	self.timer = 0

	return self
end

function CrowStateIdleEat:activate(parms)
	CrowStateIdleEat:superClass().activate(self, parms)

	self.timer = self.eatTimer
	self.owner.steering.seekPercent = 0
	self.owner.steering.wanderPercent = 0
	self.owner.steering.separationPercent = 0
	self.owner.steering.maxVelocity = 0
end

function CrowStateIdleEat:update(dt)
	CrowStateIdleEat:superClass().update(self, dt)

	self.timer = math.max(self.timer - dt, 0)

	if self.timer == 0 then
		local foundgroundTarget = self.owner:chooseRandomTargetNotInWater(2, 2.5, 0, 0)

		if foundgroundTarget then
			self.stateMachine:changeState("idle_walk")
		else
			self.owner:chooseRandomTargetNotInWater(40, 50, 5, 10, self.owner.steering.targetX, self.owner.steering.targetZ)
			self.stateMachine:changeState("takeOff")
		end
	end
end

CrowStateIdleAttention = {}
local CrowStateIdleAttention_mt = Class(CrowStateIdleAttention, SimpleState)

function CrowStateIdleAttention.new(id, owner, stateMachine, custom_mt)
	local self = SimpleState.new(id, owner, stateMachine, custom_mt or CrowStateIdleAttention_mt)
	self.attentionTimer = 2000
	self.timer = 0

	return self
end

function CrowStateIdleAttention:activate(parms)
	CrowStateIdleAttention:superClass().activate(self, parms)

	self.timer = self.attentionTimer
	self.owner.steering.seekPercent = 0
	self.owner.steering.wanderPercent = 0
	self.owner.steering.separationPercent = 0
	self.owner.steering.maxVelocity = 0
end

function CrowStateIdleAttention:update(dt)
	CrowStateIdleAttention:superClass().update(self, dt)

	self.timer = math.max(self.timer - dt, 0)
	local playerTooClose, posX, _, posZ = self.owner:isNearestPlayerClose(10)

	if playerTooClose then
		self.owner:chooseRandomTargetNotInWater(20, 25, 25, 30, posX, posZ)
		self.owner.spawner:searchTree(self.owner.steering.targetX, self.owner.steering.targetY, self.owner.steering.targetZ, 20)

		if self.owner.spawner.tree ~= nil then
			local treeX, _, treeZ = getWorldTranslation(self.owner.spawner.tree)
			self.owner.steering.targetZ = treeZ
			self.owner.steering.targetX = treeX
		end

		self.stateMachine:changeState("takeOff")
	elseif self.timer == 0 then
		local choice = math.random(1, 2)

		if choice == 1 then
			self.stateMachine:changeState("idle_eat")
		elseif choice == 2 then
			local foundgroundTarget = self.owner:chooseRandomTargetNotInWater(2, 2.5, 0, 0)

			if foundgroundTarget then
				self.stateMachine:changeState("idle_walk")
			else
				self.owner:chooseRandomTargetNotInWater(40, 50, 5, 10, self.owner.steering.targetX, self.owner.steering.targetZ)
				self.stateMachine:changeState("takeOff")
			end
		end
	end
end
