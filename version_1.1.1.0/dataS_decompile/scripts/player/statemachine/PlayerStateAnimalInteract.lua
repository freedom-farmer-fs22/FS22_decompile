PlayerStateAnimalInteract = {}
local PlayerStateAnimalInteract_mt = Class(PlayerStateAnimalInteract, PlayerStateBase)

function PlayerStateAnimalInteract.new(player, stateMachine)
	local self = PlayerStateBase.new(player, stateMachine, PlayerStateAnimalInteract_mt)
	self.dog = nil
	self.husbandry = nil
	self.cluster = nil
	self.castDistance = 1.5
	self.interactText = ""

	return self
end

function PlayerStateAnimalInteract:isAvailable()
	self.dog = nil

	if self.player.isClient and self.player.isEntered and not g_gui:getIsGuiVisible() then
		local playerHandsEmpty = self.player.baseInformation.currentHandtool == nil and not self.player.isCarryingObject
		local dogHouse = g_currentMission:getDoghouse(self.player.farmId)

		if playerHandsEmpty and dogHouse ~= nil then
			local dog = dogHouse:getDog()

			if dog ~= nil and dog.playersInRange[self.player.rootNode] ~= nil then
				self.dog = dog

				if dog.entityFollow == self.player.rootNode then
					self.interactText = g_i18n:getText("action_interactAnimalStopFollow")
				else
					self.interactText = g_i18n:getText("action_interactAnimalFollow")
				end

				return true
			end
		end
	end

	self:detectAnimal()

	if self.husbandry ~= nil then
		self.interactText = string.format(g_i18n:getText("action_interactAnimalClean"), self.cluster:getName())

		return true
	end

	self.interactText = ""

	return false
end

function PlayerStateAnimalInteract:activate()
	PlayerStateAnimalInteract:superClass().activate(self)

	if self.dog ~= nil then
		if self.dog.entityFollow == self.player.rootNode then
			self.dog:goToSpawn()
		else
			self.dog:followEntity(self.player)
		end

		self:deactivate()
	elseif self.husbandry ~= nil and self.cluster ~= nil then
		g_client:getServerConnection():sendEvent(AnimalCleanEvent.new(self.husbandry, self.cluster.id))
		g_soundManager:playSample(self.player.model.soundInformation.samples.horseBrush)
		self:deactivate()
	end
end

function PlayerStateAnimalInteract:deactivate()
	PlayerStateAnimalInteract:superClass().deactivate(self)

	self.dog = nil
	self.husbandry = nil
	self.cluster = nil
end

function PlayerStateAnimalInteract:detectAnimal()
	local collisionMask = CollisionFlag.ANIMAL
	local cameraX, cameraY, cameraZ = localToWorld(self.player.cameraNode, 0, 0, 0)
	local dirX, dirY, dirZ = localDirectionToWorld(self.player.cameraNode, 0, 0, -1)
	self.husbandry = nil
	self.cluster = nil

	raycastClosest(cameraX, cameraY, cameraZ, dirX, dirY, dirZ, "animalRaycastCallback", self.castDistance, self, collisionMask)
end

function PlayerStateAnimalInteract:update(dt)
	self:detectAnimal()
end

function PlayerStateAnimalInteract:animalRaycastCallback(hitObjectId, x, y, z, distance)
	local husbandryId, animalId = getAnimalFromCollisionNode(hitObjectId)

	if husbandryId ~= nil and husbandryId ~= 0 then
		local clusterHusbandry = g_currentMission.husbandrySystem:getClusterHusbandyById(husbandryId)

		if clusterHusbandry ~= nil then
			local husbandry = clusterHusbandry:getPlaceable()
			local cluster = clusterHusbandry:getClusterByAnimalId(animalId)

			if cluster ~= nil and g_currentMission.accessHandler:canFarmAccess(self.player.farmId, husbandry) and cluster.changeDirt ~= nil and cluster.getName ~= nil and cluster:getDirtFactor() > 0 then
				self.husbandry = husbandry
				self.cluster = cluster

				return true
			end
		end
	end

	return false
end

function PlayerStateAnimalInteract:getCanClean()
	return self.husbandry ~= nil and self.cluster ~= nil
end
