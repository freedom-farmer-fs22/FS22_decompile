PlowMission = {
	REWARD_PER_HA = 1400
}
local PlowMission_mt = Class(PlowMission, AbstractFieldMission)

InitStaticObjectClass(PlowMission, "PlowMission", ObjectIds.MISSION_PLOW)

function PlowMission.new(isServer, isClient, customMt)
	local self = AbstractFieldMission.new(isServer, isClient, customMt or PlowMission_mt)
	self.workAreaTypes = {
		[WorkAreaType.PLOW] = true
	}
	self.rewardPerHa = PlowMission.REWARD_PER_HA
	self.reimbursementPerHa = 0
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = self.mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	self.completionModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, self.mission.terrainRootNode)
	self.completionFilter = DensityMapFilter.new(self.completionModifier)
	local plowValue = self.mission.fieldGroundSystem:getFieldGroundValue(FieldGroundType.PLOWED)

	self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, plowValue)

	return self
end

function PlowMission:finish(...)
	PlowMission:superClass().finish(self, ...)

	self.field.fruitType = FruitType.UNKNOWN
end

function PlowMission:completeField()
	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, nil, FieldManager.FIELDSTATE_PLOWED, 0, self.sprayFactor, self.fieldSpraySet, self.plowLevelMaxValue)
	end
end

function PlowMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState, stubbleFactor, rollerFactor)
	local fruitType = field.fruitType
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
	local x, z = FieldUtil.getMeasurementPositionOfField(field)

	if fieldPlowFactor > 0 or fruitDesc == nil then
		return false
	end

	local area, _ = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, {}, {}, fruitType, fruitDesc.cutState, fruitDesc.cutState, 0, 0, 0, false)

	if area > 0 then
		return true, FieldManager.FIELDSTATE_HARVESTED
	end

	local state = fruitDesc.numGrowthStates
	local growingArea, _ = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, {}, {}, fruitType, state, state, 0, 0, 0, false)

	if growingArea > 0 then
		return true, FieldManager.FIELDSTATE_GROWING, state + 1
	end

	return false
end

function PlowMission:getData()
	return {
		location = string.format(g_i18n:getText("fieldJob_number"), self.field.fieldId),
		jobType = g_i18n:getText("fieldJob_jobType_plowing"),
		action = g_i18n:getText("fieldJob_desc_action_plowing"),
		description = string.format(g_i18n:getText("fieldJob_desc_plowing"), self.field.fieldId)
	}
end

function PlowMission:partitionCompletion(x, z, widthX, widthZ, heightX, heightZ)
	self.completionModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)

	local _, area, totalArea = self.completionModifier:executeGet(self.completionFilter)

	return area, totalArea
end

function PlowMission:validate(event)
	return event ~= FieldManager.FIELDEVENT_PLOWED and event ~= FieldManager.FIELDEVENT_CULTIVATED
end

g_missionManager:registerMissionType(PlowMission, "plow")
