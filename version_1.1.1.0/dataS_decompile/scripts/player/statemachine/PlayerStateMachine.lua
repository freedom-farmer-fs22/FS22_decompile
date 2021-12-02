PlayerStateMachine = {}
local PlayerStateMachine_mt = Class(PlayerStateMachine)

function PlayerStateMachine.new(player, custom_mt)
	if custom_mt == nil then
		custom_mt = PlayerStateMachine_mt
	end

	local self = setmetatable({}, custom_mt)
	self.player = player
	self.playerStateIdle = PlayerStateIdle.new(self.player, self)
	self.playerStateWalk = PlayerStateWalk.new(self.player, self)
	self.playerStateRun = PlayerStateRun.new(self.player, self)
	self.playerStateJump = PlayerStateJump.new(self.player, self)
	self.playerStateSwim = PlayerStateSwim.new(self.player, self)
	self.playerStateFall = PlayerStateFall.new(self.player, self)
	self.playerStateCrouch = PlayerStateCrouch.new(self.player, self)
	self.playerStateAnimalInteract = PlayerStateAnimalInteract.new(self.player, self)
	self.playerStateAnimalRide = PlayerStateAnimalRide.new(self.player, self)
	self.playerStateAnimalPet = PlayerStateAnimalPet.new(self.player, self)
	self.playerStatePickup = PlayerStatePickup.new(self.player, self)
	self.playerStateDrop = PlayerStateDrop.new(self.player, self)
	self.playerStateThrow = PlayerStateThrow.new(self.player, self)
	self.playerStateUseLight = PlayerStateUseLight.new(self.player, self)
	self.playerStateCycleHandtool = PlayerStateCycleHandtool.new(self.player, self)
	self.stateList = {
		idle = self.playerStateIdle,
		walk = self.playerStateWalk,
		run = self.playerStateRun,
		jump = self.playerStateJump,
		swim = self.playerStateSwim,
		fall = self.playerStateFall,
		crouch = self.playerStateCrouch,
		animalInteract = self.playerStateAnimalInteract,
		animalRide = self.playerStateAnimalRide,
		animalPet = self.playerStateAnimalPet,
		pickup = self.playerStatePickup,
		drop = self.playerStateDrop,
		throw = self.playerStateThrow,
		useLight = self.playerStateUseLight,
		cycleHandtool = self.playerStateCycleHandtool
	}
	self.fsmTable = {
		walk = {}
	}
	self.fsmTable.walk.jump = true
	self.fsmTable.walk.run = true
	self.fsmTable.walk.swim = true
	self.fsmTable.walk.crouch = true
	self.fsmTable.walk.pickup = true
	self.fsmTable.walk.drop = true
	self.fsmTable.walk.throw = true
	self.fsmTable.walk.useLight = true
	self.fsmTable.walk.cycleHandtool = true
	self.fsmTable.run = {
		jump = true,
		swim = true,
		pickup = true,
		drop = true,
		throw = true,
		useLight = true,
		cycleHandtool = true,
		crouch = true
	}
	self.fsmTable.crouch = {
		walk = true,
		jump = true,
		swim = true,
		animalInteract = true,
		animalRide = true,
		animalPet = true,
		pickup = true,
		drop = true,
		throw = true,
		useLight = true,
		cycleHandtool = true
	}
	self.fsmTable.fall = {
		swim = true,
		useLight = true
	}
	self.fsmTable.jump = {}
	self.fsmTable.idle = {
		jump = true,
		crouch = true,
		walk = true,
		run = true,
		animalInteract = true,
		animalRide = true,
		animalPet = true,
		pickup = true,
		drop = true,
		throw = true,
		useLight = true,
		cycleHandtool = true
	}
	self.fsmTable.swim = {
		walk = true,
		run = true,
		useLight = true
	}
	self.fsmTable.animalInteract = {
		crouch = true,
		idle = true,
		walk = true,
		run = true
	}
	self.fsmTable.animalPet = {
		crouch = true,
		idle = true,
		walk = true,
		run = true
	}
	self.debugMode = false

	return self
end

function PlayerStateMachine:delete()
	if self.player.isOwner then
		removeConsoleCommand("gsPlayerFsmDebug")
	end

	for _, stateInstance in pairs(self.stateList) do
		stateInstance:delete()

		stateInstance = {}
	end
end

function PlayerStateMachine:getState(stateName)
	return self.stateList[stateName]
end

function PlayerStateMachine:isAvailable(stateName)
	if self.stateList[stateName] ~= nil then
		local result = self.stateList[stateName].isActive == false and self.stateList[stateName]:isAvailable()

		return result
	end

	return false
end

function PlayerStateMachine:isActive(stateName)
	if self.stateList[stateName] ~= nil then
		return self.stateList[stateName].isActive
	end

	return false
end

function PlayerStateMachine:update(dt)
	for stateName, stateInstance in pairs(self.stateList) do
		if stateInstance.isActive then
			stateInstance:update(dt)
		end
	end
end

function PlayerStateMachine:updateTick(dt)
	for stateName, stateInstance in pairs(self.stateList) do
		if stateInstance.isActive then
			stateInstance:updateTick(dt)
		end
	end
end

function PlayerStateMachine:debugDraw(dt)
	if self.debugMode then
		setTextColor(1, 1, 0, 1)
		renderText(0.05, 0.6, 0.02, "[state machine]")

		local i = 0

		for stateName, stateInstance in pairs(self.stateList) do
			renderText(0.05, 0.58 - i * 0.02, 0.02, string.format("- %s active(%s) isAvailable(%s)", stateName, tostring(stateInstance.isActive), tostring(stateInstance:isAvailable())))

			i = i + 1
		end
	end

	for stateName, stateInstance in pairs(self.stateList) do
		if stateInstance.inDebugMode(self) then
			stateInstance:debugDraw(dt)
		end
	end
end

function PlayerStateMachine:activateState(stateNameTo)
	local allowed = true

	for stateNameFrom, stateInstance in pairs(self.stateList) do
		if stateInstance.isActive and (self.fsmTable[stateNameFrom] == nil or not self.fsmTable[stateNameFrom][stateNameTo]) then
			allowed = false

			break
		end
	end

	if allowed and self.stateList[stateNameTo] ~= nil and self.stateList[stateNameTo].isActive == false then
		self.stateList[stateNameTo]:activate()
	end
end

function PlayerStateMachine:deactivateState(stateName)
	if self.stateList[stateName] ~= nil and self.stateList[stateName].isActive == true then
		self.stateList[stateName]:deactivate()
	end
end

function PlayerStateMachine:load()
	for _, stateInstance in pairs(self.stateList) do
		stateInstance:load()
	end

	if self.player.isOwner then
		addConsoleCommand("gsPlayerFsmDebug", "Toggle debug mode for player state machine", "consoleCommandDebugFinalStateMachine", self)
	end
end

function PlayerStateMachine:consoleCommandDebugFinalStateMachine()
	if self.debugMode then
		self.debugMode = false
	else
		self.debugMode = true
	end
end
