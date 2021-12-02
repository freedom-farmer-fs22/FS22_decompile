PlayerStateCycleHandtool = {}
local PlayerStateCycleHandtool_mt = Class(PlayerStateCycleHandtool, PlayerStateBase)

function PlayerStateCycleHandtool.new(player, stateMachine)
	local self = PlayerStateBase.new(player, stateMachine, PlayerStateCycleHandtool_mt)
	self.cycleDirection = 1

	return self
end

function PlayerStateCycleHandtool:isAvailable()
	local farm = g_farmManager:getFarmById(self.player.farmId)
	local isInWater = self.player.baseInformation.isInWater

	return #farm.handTools > 0 and not isInWater and not self.player.isCarryingObject
end

function PlayerStateCycleHandtool:activate()
	PlayerStateCycleHandtool:superClass().activate(self)

	local farm = g_farmManager:getFarmById(self.player.farmId)
	local handTools = farm.handTools
	local currentId = 0

	if self.player:hasHandtoolEquipped() then
		local currentConfigFileName = self.player.baseInformation.currentHandtool.configFileName

		for key, filename in pairs(handTools) do
			if filename:lower() == currentConfigFileName:lower() then
				currentId = key

				break
			end
		end
	end

	currentId = currentId + self.cycleDirection

	if currentId > #handTools then
		currentId = 0
	elseif currentId < 0 then
		currentId = #handTools
	end

	if currentId == 0 then
		self.player:equipHandtool("", false)
	else
		self.player:equipHandtool(handTools[currentId], false)
	end

	self:deactivate()
end
