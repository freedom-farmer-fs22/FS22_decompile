ConstructionBrush = {}
local ConstructionBrush_mt = Class(ConstructionBrush)
ConstructionBrush.ERROR = {
	LAND_UNOWNED = 1,
	RESTRICTED_ZONE = 2,
	STORE_PLACE = 3,
	SPAWN_PLACE = 4,
	NO_PERMISSION = 5
}
ConstructionBrush.ERROR_MESSAGES = {
	[ConstructionBrush.ERROR.LAND_UNOWNED] = "ui_construction_landIsNotOwned",
	[ConstructionBrush.ERROR.RESTRICTED_ZONE] = "ui_construction_areaRestricted",
	[ConstructionBrush.ERROR.STORE_PLACE] = "ui_construction_storeAreaRestricted",
	[ConstructionBrush.ERROR.SPAWN_PLACE] = "ui_construction_spawnAreaRestricted",
	[ConstructionBrush.ERROR.NO_PERMISSION] = "ui_construction_noBuildPermission"
}
ConstructionBrush.CURSOR_SIZES = {
	1,
	2,
	4,
	8,
	16
}

function ConstructionBrush.new(subclass_mt, cursor)
	local self = setmetatable({}, subclass_mt or ConstructionBrush_mt)
	self.isActive = false
	self.cursor = cursor
	self.supportsPrimaryButton = false
	self.supportsPrimaryDragging = false
	self.supportsSecondaryButton = false
	self.supportsSecondaryDragging = false
	self.supportsTertiaryButton = false
	self.supportsPrimaryAxis = false
	self.supportsSecondaryAxis = false
	self.primaryAxisIsContinuous = false
	self.secondaryAxisIsContinuous = false
	self.inputTextDirty = true

	return self
end

function ConstructionBrush:delete()
	if self.isActive then
		self:deactivate()
	end
end

function ConstructionBrush:activate()
	self.isActive = true
	self.currentUserId = g_currentMission.playerUserId
	self.playerFarm = g_farmManager:getFarmById(g_currentMission:getFarmId())

	self.cursor:setCursorTerrainOffset(false)
end

function ConstructionBrush:deactivate()
	self.isActive = false
	self.currentUserId = nil
	self.playerFarm = nil
end

function ConstructionBrush:copyState(from)
end

function ConstructionBrush:setParameters(...)
end

function ConstructionBrush:setStoreItem(storeItem)
	self.storeItem = storeItem
end

function ConstructionBrush:canCancel()
	return false
end

function ConstructionBrush:verifyAccess(x, y, z)
	if not self:hasPlayerPermission() then
		return ConstructionBrush.ERROR.NO_PERMISSION
	elseif not g_currentMission.accessHandler:canFarmAccessLand(g_currentMission.player.farmId, x, z, true) then
		return ConstructionBrush.ERROR.LAND_UNOWNED
	elseif PlacementUtil.isInsidePlacementPlaces(g_currentMission.storeSpawnPlaces, x, y, z) then
		return ConstructionBrush.ERROR.STORE_PLACE
	elseif PlacementUtil.isInsidePlacementPlaces(g_currentMission.loadSpawnPlaces, x, y, z) then
		return ConstructionBrush.ERROR.SPAWN_PLACE
	elseif PlacementUtil.isInsideRestrictedZone(g_currentMission.restrictedZones, x, y, z) then
		return ConstructionBrush.ERROR.RESTRICTED_ZONE
	end

	return nil
end

function ConstructionBrush:hasPlayerPermission()
	if self.requiredPermission == nil then
		return true
	end

	local userPermissions = self.playerFarm:getUserPermissions(self.currentUserId)

	return userPermissions[self.requiredPermission] or g_currentMission.isMasterUser
end

function ConstructionBrush:update(dt)
end

function ConstructionBrush:cancel()
end

function ConstructionBrush:onButtonPrimary()
end

function ConstructionBrush:onButtonSecondary()
end

function ConstructionBrush:onButtonTertiary()
end

function ConstructionBrush:onAxisPrimary(inputValue)
end

function ConstructionBrush:onAxisSecondary(inputValue)
end

function ConstructionBrush:setInputTextDirty()
	self.inputTextDirty = true
end

function ConstructionBrush:getButtonPrimaryText()
	return "PRIMARY"
end

function ConstructionBrush:getButtonSecondaryText()
	return "SECONDARY"
end

function ConstructionBrush:getButtonTertiaryText()
	return "TERTIARY"
end

function ConstructionBrush:getAxisPrimaryText()
	return "PRIMARY AXIS"
end

function ConstructionBrush:getAxisSecondaryText()
	return "SECONDARY AXIS"
end
