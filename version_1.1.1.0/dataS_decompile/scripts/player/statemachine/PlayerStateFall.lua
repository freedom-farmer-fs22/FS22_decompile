PlayerStateFall = {}
local PlayerStateFall_mt = Class(PlayerStateFall, PlayerStateBase)

function PlayerStateFall.new(player, stateMachine)
	local self = PlayerStateBase.new(player, stateMachine, PlayerStateFall_mt)

	return self
end

function PlayerStateFall:isAvailable()
	local isOnGround = self.player.baseInformation.isOnGround
	local isInWater = self.player.baseInformation.isInWater
	local verticalVelocity = self.player.motionInformation.currentSpeedY

	if not isOnGround and not isInWater and verticalVelocity < self.player.motionInformation.minimumFallingSpeed then
		return true
	end

	return false
end

function PlayerStateFall:update(dt)
	local isOnGround = self.player.baseInformation.isOnGround
	local isInWater = self.player.baseInformation.isInWater

	if isOnGround or isInWater then
		self:deactivate()
	end
end
