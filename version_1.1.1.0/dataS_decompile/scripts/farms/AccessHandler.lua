AccessHandler = {
	EVERYONE = 0,
	NOBODY = 2^FarmManager.FARM_ID_SEND_NUM_BITS - 1
}
local AccessHandler_mt = Class(AccessHandler)

function AccessHandler.new(customMt)
	local self = {}

	setmetatable(self, customMt or AccessHandler_mt)

	return self
end

function AccessHandler:delete()
end

function AccessHandler:canPlayerAccess(object, player)
	local playerFarmId = nil

	if player == nil then
		playerFarmId = g_currentMission:getFarmId()
	else
		playerFarmId = player.farmId
	end

	return self:canFarmAccess(playerFarmId, object)
end

function AccessHandler:canFarmAccess(farmId, object, allowEqualAlways)
	if object == nil then
		return false
	end

	local ownerFarmId = object:getOwnerFarmId()

	if farmId == FarmManager.SPECTATOR_FARM_ID and (not allowEqualAlways or farmId ~= ownerFarmId) then
		return false
	end

	if ownerFarmId == nil or ownerFarmId == AccessHandler.EVERYONE then
		return true
	end

	if farmId == nil then
		return ownerFarmId == AccessHandler.EVERYONE
	end

	return self:canFarmAccessOtherId(farmId, ownerFarmId)
end

function AccessHandler:canFarmAccessOtherId(farmId, objectFarmId)
	if objectFarmId == AccessHandler.EVERYONE then
		return true
	end

	if objectFarmId == AccessHandler.NOBODY then
		return false
	end

	if objectFarmId == farmId then
		return true
	end

	local farm = g_farmManager:getFarmById(farmId)

	if farm == nil then
		return false
	end

	return farm:getIsContractingFor(objectFarmId)
end

function AccessHandler:canFarmAccessLand(farmId, x, z, disallowContracting)
	if farmId == FarmlandManager.NO_OWNER_FARM_ID then
		return false
	end

	local ownerFarmId = g_farmlandManager:getOwnerIdAtWorldPosition(x, z)

	if ownerFarmId == farmId then
		return true
	end

	local farm = g_farmManager:getFarmById(farmId)

	if farm == nil then
		return false
	end

	return disallowContracting ~= true and farm:getIsContractingFor(ownerFarmId)
end
