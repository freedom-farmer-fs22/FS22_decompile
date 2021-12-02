PlayerStateRun = {}
local PlayerStateRun_mt = Class(PlayerStateRun, PlayerStateBase)

function PlayerStateRun.new(player, stateMachine)
	local self = PlayerStateBase.new(player, stateMachine, PlayerStateRun_mt)

	return self
end

function PlayerStateRun:isAvailable()
	return self:canRun()
end

function PlayerStateRun:update(dt)
	local playerInputsCheck = self.player.inputInformation.runAxis ~= 0 and (math.abs(self.player.inputInformation.moveForward) > 0.01 or math.abs(self.player.inputInformation.moveRight) > 0.01)

	if self:canRun() == false or playerInputsCheck == false then
		self:deactivate()
	end
end

function PlayerStateRun:canRun()
	return self.player.baseInformation.isOnGround
end
