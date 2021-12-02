PlayerStateBase = {}
local PlayerStateBase_mt = Class(PlayerStateBase)

function PlayerStateBase.new(player, stateMachine, custom_mt)
	if custom_mt == nil then
		custom_mt = PlayerStateBase_mt
	end

	local self = setmetatable({}, custom_mt)
	self.isActive = false
	self.isInDebugMode = false
	self.player = player
	self.stateMachine = stateMachine

	return self
end

function PlayerStateBase:delete()
end

function PlayerStateBase:load()
end

function PlayerStateBase:activate()
	self.isActive = true
end

function PlayerStateBase:deactivate()
	self.isActive = false
end

function PlayerStateBase:toggleDebugMode()
	if self.isInDebugMode then
		self.isInDebugMode = false
	else
		self.isInDebugMode = true
	end
end

function PlayerStateBase:inDebugMode()
	return self.isInDebugMode
end

function PlayerStateBase:debugDraw(dt)
end

function PlayerStateBase:getStateMachine()
	return self.stateMachine
end

function PlayerStateBase:update(dt)
end

function PlayerStateBase:updateTick(dt)
end
