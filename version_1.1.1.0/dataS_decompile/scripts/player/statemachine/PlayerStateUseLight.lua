PlayerStateUseLight = {}
local PlayerStateUseLight_mt = Class(PlayerStateUseLight, PlayerStateBase)

function PlayerStateUseLight.new(player, stateMachine)
	local self = PlayerStateBase.new(player, stateMachine, PlayerStateUseLight_mt)

	return self
end

function PlayerStateUseLight:isAvailable()
	if self.player.model:getHasTorch() and not g_currentMission:isInGameMessageActive() then
		return true
	end

	return false
end

function PlayerStateUseLight:activate()
	PlayerStateUseLight:superClass().activate(self)
	self.player:setLightIsActive(not self.player.isTorchActive)
	self:deactivate()
end
