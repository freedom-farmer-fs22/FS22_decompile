PlayerStateAnimalRide = {}
local PlayerStateAnimalRide_mt = Class(PlayerStateAnimalRide, PlayerStateBase)
PlayerStateAnimalRide.INPUT_CONTEXT_EMPTY = "ANIMAL_LOAD_EMPTY"

function PlayerStateAnimalRide.new(player, stateMachine)
	local self = PlayerStateBase.new(player, stateMachine, PlayerStateAnimalRide_mt)
	self.placeable = nil
	self.cluster = nil
	self.castDistance = 1.5
	self.timeFadeToBlack = 250

	return self
end

function PlayerStateAnimalRide:isAvailable()
	local cameraX, cameraY, cameraZ = localToWorld(self.player.cameraNode, 0, 0, 0)
	local dirX, dirY, dirZ = localDirectionToWorld(self.player.cameraNode, 0, 0, -1)
	local collisionMask = CollisionFlag.ANIMAL
	self.placeable = nil
	self.cluster = nil

	raycastClosest(cameraX, cameraY, cameraZ, dirX, dirY, dirZ, "animalRaycastCallback", self.castDistance, self, collisionMask)

	if self.placeable ~= nil then
		return true
	end

	return false
end

function PlayerStateAnimalRide:activate()
	PlayerStateAnimalRide:superClass().activate(self)

	if self.placeable ~= nil then
		if self.placeable:getAnimalCanBeRidden(self.cluster.id) then
			g_currentMission:fadeScreen(1, self.timeFadeToBlack, self.endFadeToBlack, self, {
				self.placeable,
				self.cluster,
				self.player
			})
			g_inputBinding:setContext(PlayerStateAnimalRide.INPUT_CONTEXT_EMPTY, true, false)
		else
			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("shop_messageAnimalRideableLimitReached"))
		end
	end

	self:deactivate()
end

function PlayerStateAnimalRide:endFadeToBlack(arguments)
	local placeable = arguments[1]
	local cluster = arguments[2]
	local player = arguments[3]

	placeable:startRiding(cluster.id, player)
end

function PlayerStateAnimalRide:animalRaycastCallback(hitObjectId, x, y, z, distance)
	local husbandryId, animalId = getAnimalFromCollisionNode(hitObjectId)

	if husbandryId ~= nil and husbandryId ~= 0 then
		local clusterHusbandry = g_currentMission.husbandrySystem:getClusterHusbandyById(husbandryId)

		if clusterHusbandry ~= nil then
			local placeable = clusterHusbandry:getPlaceable()
			local cluster = clusterHusbandry:getClusterByAnimalId(animalId)

			if cluster ~= nil and g_currentMission.accessHandler:canFarmAccess(self.player.farmId, placeable) and placeable:getAnimalSupportsRiding(cluster.id) then
				self.placeable = placeable
				self.cluster = cluster

				return true
			end
		end
	end

	return false
end

function PlayerStateAnimalRide:getRideableName()
	local rideableName = ""

	if self.placeable ~= nil and self.cluster.getName ~= nil then
		rideableName = self.cluster:getName()
	end

	return rideableName
end
