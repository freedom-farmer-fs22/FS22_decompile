Field = {}
local Field_mt = Class(Field)

function Field.new(customMt)
	local self = {}

	setmetatable(self, customMt or Field_mt)

	self.fieldId = 0
	self.posX = 0
	self.posZ = 0
	self.rootNode = nil
	self.name = nil
	self.mapHotspot = nil
	self.fieldMissionAllowed = true
	self.fieldGrassMission = false
	self.fieldAngle = 0
	self.fieldDimensions = nil
	self.fieldArea = 1
	self.getFieldStatusPartitions = {}
	self.setFieldStatusPartitions = {}
	self.maxFieldStatusPartitions = {}
	self.isAIActive = true
	self.fruitType = nil
	self.lastCheckedTime = nil
	self.plannedFruit = 0
	self.currentMission = nil

	return self
end

function Field:load(id)
	self.rootNode = id
	local name = getUserAttribute(id, "name")

	if name ~= nil then
		self.name = g_i18n:convertText(name, g_currentMission.loadingMapModName)
	end

	self.fieldMissionAllowed = Utils.getNoNil(getUserAttribute(id, "fieldMissionAllowed"), true)
	self.fieldGrassMission = Utils.getNoNil(getUserAttribute(id, "fieldGrassMission"), false)
	local fieldDimensions = I3DUtil.indexToObject(id, getUserAttribute(id, "fieldDimensionIndex"))

	if fieldDimensions == nil then
		print("Warning: No fieldDimensionIndex defined for Field '" .. getName(id) .. "'!")

		return false
	end

	local angleRad = math.rad(Utils.getNoNil(tonumber(getUserAttribute(id, "fieldAngle")), 0))
	self.fieldAngle = FSDensityMapUtil.convertToDensityMapAngle(angleRad, g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
	self.fieldDimensions = fieldDimensions

	FieldUtil.updateFieldPartitions(self, self.getFieldStatusPartitions, 900)
	FieldUtil.updateFieldPartitions(self, self.setFieldStatusPartitions, 400)
	FieldUtil.updateFieldPartitions(self, self.maxFieldStatusPartitions, 10000000)

	self.posX, self.posZ = FieldUtil.getCenterOfField(self)
	self.nameIndicator = I3DUtil.indexToObject(id, getUserAttribute(id, "nameIndicatorIndex"))

	if self.nameIndicator ~= nil then
		local x, _, z = getWorldTranslation(self.nameIndicator)
		self.posZ = z
		self.posX = x
	end

	self.farmland = nil

	return true
end

function Field:delete()
	if self.mapHotspot == nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()

		self.mapHotspot = nil
	end
end

function Field:getCenterOfFieldWorldPosition()
	return self.posX, self.posZ
end

function Field:setFarmland(farmland)
	self.farmland = farmland
end

function Field:updateOwnership()
	self:setFieldOwned(g_farmlandManager:getFarmlandOwner(self.farmland.id))
end

function Field:setFieldId(fieldId)
	self.fieldId = fieldId
end

function Field:getName()
	return self.name or tostring(self.fieldId)
end

function Field:addMapHotspot()
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()

		self.mapHotspot = nil
	end

	local mapHotspot = FieldHotspot.new()

	mapHotspot:setField(self)

	self.mapHotspot = mapHotspot

	g_currentMission:addMapHotspot(mapHotspot)
end

function Field:setMissionActive(isActive)
	self.mapHotspot:setBlinking(isActive)
	self.mapHotspot:setPersistent(isActive)
end

function Field:setFieldOwned(farmId)
	if self.mapHotspot ~= nil then
		self.mapHotspot:setOwnerFarmId(farmId)
	end

	self.isAIActive = farmId == FarmlandManager.NO_OWNER_FARM_ID
end

function Field:activate()
	self:setFieldOwned(FarmlandManager.NO_OWNER_FARM_ID)
end

function Field:deactivate()
	self:setFieldOwned(g_farmlandManager:getFarmlandOwner(self.farmland.id))
	g_missionManager:cancelMissionOnField(self)
end

function Field:getIsAIActive()
	return self.isAIActive
end
