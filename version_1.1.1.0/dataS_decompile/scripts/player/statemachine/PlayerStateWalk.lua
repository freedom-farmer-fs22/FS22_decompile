PlayerStateWalk = {}
local PlayerStateWalk_mt = Class(PlayerStateWalk, PlayerStateBase)

function PlayerStateWalk.new(player, stateMachine)
	local self = PlayerStateBase.new(player, stateMachine, PlayerStateWalk_mt)

	return self
end

function PlayerStateWalk:isAvailable()
	return self:canWalk()
end

function PlayerStateWalk:update(dt)
	local playerInputsCheck = math.abs(self.player.inputInformation.moveForward) > 0.01 or math.abs(self.player.inputInformation.moveRight) > 0.01

	if not self:canWalk() or not playerInputsCheck then
		self:deactivate()
	end
end

function PlayerStateWalk:canWalk()
	local isRunning = self.player.inputInformation.runAxis ~= 0

	return self.player.baseInformation.isOnGround and not isRunning
end
