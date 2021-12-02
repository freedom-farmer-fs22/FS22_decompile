PlayerStateAnimalPet = {}
local PlayerStateAnimalPet_mt = Class(PlayerStateAnimalPet, PlayerStateBase)

function PlayerStateAnimalPet.new(player, stateMachine)
	local self = PlayerStateBase.new(player, stateMachine, PlayerStateAnimalPet_mt)
	self.dog = nil

	return self
end

function PlayerStateAnimalPet:isAvailable()
	self.dog = nil

	if self.player.isClient and self.player.isEntered and not g_gui:getIsGuiVisible() then
		local playerHandsEmpty = self.player.baseInformation.currentHandtool == nil and not self.player.isCarryingObject
		local dogHouse = g_currentMission:getDoghouse(self.player.farmId)

		if dogHouse == nil then
			return false
		end

		local dog = dogHouse:getDog()

		if dog == nil then
			return false
		end

		local _, playerY, _ = getWorldTranslation(self.player.rootNode)
		playerY = playerY - self.player.model.capsuleTotalHeight * 0.5
		local deltaWater = playerY - self.player.waterY
		local playerInWater = deltaWater < 0
		local playerInDogRange = dog.playersInRange[self.player.rootNode] ~= nil

		if playerHandsEmpty and not playerInWater and playerInDogRange then
			self.dog = dog

			return true
		end
	end

	return false
end

function PlayerStateAnimalPet:activate()
	PlayerStateAnimalPet:superClass().activate(self)

	if self.dog ~= nil then
		self.dog:pet()
	end

	self:deactivate()
end

function PlayerStateAnimalPet:deactivate()
	PlayerStateAnimalPet:superClass().deactivate(self)

	self.dog = nil
end
