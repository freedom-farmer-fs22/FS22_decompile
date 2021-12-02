PlayerStatePickup = {}
local PlayerStatePickup_mt = Class(PlayerStatePickup, PlayerStateBase)

function PlayerStatePickup.new(player, stateMachine)
	local self = PlayerStateBase.new(player, stateMachine, PlayerStatePickup_mt)

	return self
end

function PlayerStatePickup:isAvailable()
	if self.player.isClient and self.player.isEntered and not self.player:hasHandtoolEquipped() and not self.player.isCarryingObject and self.player.isObjectInRange then
		if self.player.lastFoundObjectMass <= Player.MAX_PICKABLE_OBJECT_MASS then
			return true
		else
			g_currentMission:addExtraPrintText(g_i18n:getText("warning_objectTooHeavy"))
		end
	end

	return false
end

function PlayerStatePickup:activate()
	PlayerStatePickup:superClass().activate(self)
	self.player:pickUpObject(true)
	self:deactivate()
end
