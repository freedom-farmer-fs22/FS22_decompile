PlayerStateThrow = {}
local PlayerStateThrow_mt = Class(PlayerStateThrow, PlayerStateBase)

function PlayerStateThrow.new(player, stateMachine)
	local self = PlayerStateBase.new(player, stateMachine, PlayerStateThrow_mt)

	return self
end

function PlayerStateThrow:isAvailable()
	if self.player.isClient and self.player.isEntered and not self.player:hasHandtoolEquipped() and (self.player.isCarryingObject or not self.player.isCarryingObject and self.player.isObjectInRange and self.player.lastFoundObject ~= nil) and self.player.lastFoundObjectMass <= Player.MAX_PICKABLE_OBJECT_MASS then
		return true
	end

	return false
end

function PlayerStateThrow:activate()
	PlayerStateThrow:superClass().activate(self)
	self.player:throwObject()
	self:deactivate()
end
