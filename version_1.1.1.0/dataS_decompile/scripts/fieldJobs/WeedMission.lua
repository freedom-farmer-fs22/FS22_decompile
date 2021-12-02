WeedMission = {
	REWARD_PER_HA = 450
}
local WeedMission_mt = Class(WeedMission, AbstractFieldMission)

InitStaticObjectClass(WeedMission, "WeedMission", ObjectIds.MISSION_WEED)

function WeedMission.new(isServer, isClient, customMt)
	local self = AbstractFieldMission.new(isServer, isClient, customMt or WeedMission_mt)
	self.workAreaTypes = {
		[WorkAreaType.WEEDER] = true
	}
	self.rewardPerHa = WeedMission.REWARD_PER_HA
	self.reimbursementPerHa = 0
	local weedMapId, weedFirstChannel, weedNumChannels = self.mission.weedSystem:getDensityMapData()
	self.completionModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, self.mission.terrainRootNode)
	self.completionFilter = DensityMapFilter.new(self.completionModifier)

	self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)

	return self
end

function WeedMission:completeField()
	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, self.field.fruitType, self.fieldState, self.growthState, self.sprayFactor, self.fieldSpraySet, self.fieldPlowFactor, 0)
	end
end

function WeedMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState, stubbleFactor, rollerFactor)
	local fruitType = field.fruitType
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

	if fruitDesc == nil then
		return false
	end

	if fruitDesc.minHarvestingGrowthState == 2 and fruitDesc.maxHarvestingGrowthState == 2 and fruitDesc.cutState == 3 then
		return false
	end

	local maxGrowthState = FieldUtil.getMaxGrowthState(field, fruitType)

	if maxGrowthState == 0 or maxGrowthState > 2 then
		return false
	end

	return maxWeedState == 2, FieldManager.FIELDSTATE_GROWING, maxGrowthState, maxWeedState
end

function WeedMission:getData()
	return {
		location = string.format(g_i18n:getText("fieldJob_number"), self.field.fieldId),
		jobType = g_i18n:getText("fieldJob_jobType_weeding"),
		action = g_i18n:getText("fieldJob_desc_action_weeding"),
		description = string.format(g_i18n:getText("fieldJob_desc_weeding"), self.field.fieldId)
	}
end

function WeedMission:getIsAvailable()
	local environment = g_currentMission.environment

	if environment ~= nil and environment.currentSeason == Environment.SEASON.WINTER then
		return false
	end

	return WeedMission:superClass().getIsAvailable(self)
end

function WeedMission:partitionCompletion(x, z, widthX, widthZ, heightX, heightZ)
	self.completionModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)

	local _, area, totalArea = self.completionModifier:executeGet(self.completionFilter)

	return area, totalArea
end

function WeedMission:validate(event)
	return event ~= FieldManager.FIELDEVENT_WEEDED and event ~= FieldManager.FIELDEVENT_SPRAYED and event ~= FieldManager.FIELDEVENT_GROWN
end

g_missionManager:registerMissionType(WeedMission, "weed")
