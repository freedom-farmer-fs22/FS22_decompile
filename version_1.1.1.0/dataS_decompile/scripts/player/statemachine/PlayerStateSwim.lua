PlayerStateSwim = {}
local PlayerStateSwim_mt = Class(PlayerStateSwim, PlayerStateBase)

function PlayerStateSwim.new(player, stateMachine)
	local self = PlayerStateBase.new(player, stateMachine, PlayerStateSwim_mt)

	return self
end

function PlayerStateSwim:isAvailable()
	local isInWater = self.player.baseInformation.isInWater

	if isInWater then
		return true
	end

	return false
end

function PlayerStateSwim:update(dt)
	if not self.player.baseInformation.isInWater then
		self:deactivate()
	end
end
