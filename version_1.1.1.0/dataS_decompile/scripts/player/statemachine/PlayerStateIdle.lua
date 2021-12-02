PlayerStateIdle = {}
local PlayerStateIdle_mt = Class(PlayerStateIdle, PlayerStateBase)

function PlayerStateIdle.new(player, stateMachine)
	local self = PlayerStateBase.new(player, stateMachine, PlayerStateIdle_mt)

	return self
end

function PlayerStateIdle:isAvailable()
	return true
end

function PlayerStateIdle:update(dt)
	local playerInputsCheck = math.abs(self.player.inputInformation.moveForward) > 0.01 or math.abs(self.player.inputInformation.moveRight) > 0.01

	if playerInputsCheck or not self.player.baseInformation.isOnGround then
		self:deactivate()
	end
end
