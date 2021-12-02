PlayerStateDrop = {}
local PlayerStateDrop_mt = Class(PlayerStateDrop, PlayerStateBase)

function PlayerStateDrop.new(player, stateMachine)
	local self = PlayerStateBase.new(player, stateMachine, PlayerStateDrop_mt)

	return self
end

function PlayerStateDrop:isAvailable()
	if self.player.isCarryingObject then
		return true
	end

	return false
end

function PlayerStateDrop:activate()
	PlayerStateDrop:superClass().activate(self)
	self.player:pickUpObject(false)
	self:deactivate()
end
