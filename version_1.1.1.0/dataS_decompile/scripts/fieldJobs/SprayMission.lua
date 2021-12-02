SprayMission = {
	REWARD_PER_HA = 250,
	REIMBURSEMENT_PER_HA = 1000
}
local SprayMission_mt = Class(SprayMission, AbstractFieldMission)

InitStaticObjectClass(SprayMission, "SprayMission", ObjectIds.MISSION_SPRAY)

function SprayMission.new(isServer, isClient, customMt)
	local self = AbstractFieldMission.new(isServer, isClient, customMt or SprayMission_mt)
	self.workAreaTypes = {
		[WorkAreaType.SPRAYER] = true
	}
	self.rewardPerHa = SprayMission.REWARD_PER_HA
	self.reimbursementPerHa = SprayMission.REIMBURSEMENT_PER_HA
	self.reimbursementPerDifficulty = true

	if isServer then
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = self.mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local weedMapId, weedFirstChannel, weedNumChannels = self.mission.weedSystem:getDensityMapData()
		self.completionModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, self.mission.terrainRootNode)
		self.completionMaskFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

		self.completionMaskFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		self.completionFilter = DensityMapFilter.new(self.completionModifier)
	end

	return self
end

function SprayMission:loadFromXMLFile(xmlFile, key)
	if not SprayMission:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end

	if self.status == AbstractMission.STATUS_RUNNING then
		self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self:getNewWeedState())
	end

	return true
end

function SprayMission:resetField()
	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, self.field.fruitType, self.fieldState, self.growthState, self.sprayFactor, self.fieldSpraySet, self.fieldPlowFactor, self.weedState)
	end
end

function SprayMission:completeField()
	local weedState = self:getNewWeedState()

	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, self.field.fruitType, self.fieldState, self.growthState, self.sprayFactor, self.fieldSpraySet, self.fieldPlowFactor, weedState)
	end
end

function SprayMission:getNewWeedState()
	local weedState = self.weedState
	local replacements = self.mission.weedSystem:getHerbicideReplacements().weed.replacements

	for sourceState, targetState in ipairs(replacements) do
		if sourceState == weedState then
			return targetState
		end
	end

	return weedState
end

function SprayMission:start(...)
	if not SprayMission:superClass().start(self, ...) then
		return false
	end

	self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, self:getNewWeedState())

	return true
end

function SprayMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState, stubbleFactor, rollerFactor)
	local fruitType = field.fruitType
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

	if fruitDesc == nil then
		return false
	end

	if fruitDesc.minHarvestingGrowthState == 2 and fruitDesc.maxHarvestingGrowthState == 2 and fruitDesc.cutState == 3 then
		return false
	end

	local maxGrowthState = FieldUtil.getMaxGrowthState(field, fruitType)

	if maxGrowthState == 0 or fruitDesc.minHarvestingGrowthState <= maxGrowthState then
		return false
	end

	local replacements = g_currentMission.weedSystem:getHerbicideReplacements().weed.replacements

	return replacements[maxWeedState] ~= nil and replacements[maxWeedState] ~= 0, FieldManager.FIELDSTATE_GROWING, maxGrowthState, maxWeedState
end

function SprayMission:getIsAvailable()
	local environment = g_currentMission.environment

	if environment ~= nil and environment.currentSeason == Environment.SEASON.WINTER then
		return false
	end

	return SprayMission:superClass().getIsAvailable(self)
end

function SprayMission:getData()
	return {
		location = string.format(g_i18n:getText("fieldJob_number"), self.field.fieldId),
		jobType = g_i18n:getText("fieldJob_jobType_spraying"),
		action = g_i18n:getText("fieldJob_desc_action_spraying"),
		description = string.format(g_i18n:getText("fieldJob_desc_spraying"), self.field.fieldId),
		extraText = string.format(g_i18n:getText("fieldJob_desc_fillTheUnit"), g_fillTypeManager:getFillTypeByIndex(FillType.HERBICIDE).title)
	}
end

function SprayMission:partitionCompletion(x, z, widthX, widthZ, heightX, heightZ)
	self.completionModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)

	local _, area, totalArea = self.completionModifier:executeGet(self.completionFilter, self.completionMaskFilter)

	return area, totalArea
end

function SprayMission:validate(event)
	return event ~= FieldManager.FIELDEVENT_WEEDED and event ~= FieldManager.FIELDEVENT_SPRAYED and event ~= FieldManager.FIELDEVENT_GROWN
end

g_missionManager:registerMissionType(SprayMission, "spray")
