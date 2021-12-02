FertilizeMission = {
	REWARD_PER_HA = 400,
	REIMBURSEMENT_PER_HA = 1150
}
local FertilizeMission_mt = Class(FertilizeMission, AbstractFieldMission)

InitStaticObjectClass(FertilizeMission, "FertilizeMission", ObjectIds.MISSION_FERTILIZE)

function FertilizeMission.new(isServer, isClient, customMt)
	local self = AbstractFieldMission.new(isServer, isClient, customMt or FertilizeMission_mt)
	self.workAreaTypes = {
		[WorkAreaType.SPRAYER] = true
	}
	self.rewardPerHa = FertilizeMission.REWARD_PER_HA
	self.reimbursementPerHa = FertilizeMission.REIMBURSEMENT_PER_HA
	self.reimbursementPerDifficulty = true
	local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = self.mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
	self.completionModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, self.mission.terrainRootNode)
	self.completionFilter = DensityMapFilter.new(self.completionModifier)
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = self.mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	self.completionMaskFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

	self.completionMaskFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

	return self
end

function FertilizeMission:completeField()
	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, self.field.fruitType, self.fieldState, self.growthState, math.min(self.sprayFactor * self.sprayLevelMaxValue + 1, self.sprayLevelMaxValue), true, self.fieldPlowFactor)
	end
end

function FertilizeMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState, stubbleFactor, rollerFactor)
	local fruitType = field.fruitType
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
	local sprayLevelMaxValue = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
	local sprayLevel = sprayFactor * sprayLevelMaxValue

	if fruitDesc == nil then
		return false
	end

	if fruitDesc.minHarvestingGrowthState == 2 and fruitDesc.maxHarvestingGrowthState == 2 and fruitDesc.cutState == 3 then
		return false
	end

	if fieldSpraySet then
		return false
	end

	if sprayLevelMaxValue <= sprayLevel then
		return false
	end

	if maxWeedState == 2 or maxWeedState == 3 then
		return false
	end

	local maxGrowthState = FieldUtil.getMaxGrowthState(field, fruitType)

	if maxGrowthState == 0 or fruitDesc.minHarvestingGrowthState <= maxGrowthState then
		return false
	end

	return true, FieldManager.FIELDSTATE_GROWING, maxGrowthState
end

function FertilizeMission:getData()
	return {
		location = string.format(g_i18n:getText("fieldJob_number"), self.field.fieldId),
		jobType = g_i18n:getText("fieldJob_jobType_fertilizing"),
		action = g_i18n:getText("fieldJob_desc_action_fertilizing"),
		description = string.format(g_i18n:getText("fieldJob_desc_fertilizing"), self.field.fieldId),
		extraText = string.format(g_i18n:getText("fieldJob_desc_fillTheUnit"), g_fillTypeManager:getFillTypeByIndex(FillType.FERTILIZER).title)
	}
end

function FertilizeMission:getIsAvailable()
	local environment = g_currentMission.environment

	if environment ~= nil and environment.currentSeason == Environment.SEASON.WINTER then
		return false
	end

	return FertilizeMission:superClass().getIsAvailable(self)
end

function FertilizeMission:partitionCompletion(x, z, widthX, widthZ, heightX, heightZ)
	local _, area, totalArea = nil

	self.completionModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)

	local newSprayFactor = self.sprayFactor * self.sprayLevelMaxValue

	self.completionFilter:setValueCompareParams(DensityValueCompareType.GREATER, newSprayFactor)

	_, area, totalArea = self.completionModifier:executeGet(self.completionFilter, self.completionMaskFilter)

	return area, totalArea
end

function FertilizeMission:validate(event)
	return event ~= FieldManager.FIELDEVENT_GROWN and event ~= FieldManager.FIELDEVENT_FERTILIZED
end

g_missionManager:registerMissionType(FertilizeMission, "fertilize")
