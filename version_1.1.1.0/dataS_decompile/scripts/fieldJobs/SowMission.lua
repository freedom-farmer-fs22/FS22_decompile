SowMission = {
	REWARD_PER_HA = 1050
}
local SowMission_mt = Class(SowMission, AbstractFieldMission)

InitStaticObjectClass(SowMission, "SowMission", ObjectIds.MISSION_SOW)

function SowMission.new(isServer, isClient, customMt)
	local self = AbstractFieldMission.new(isServer, isClient, customMt or SowMission_mt)
	self.workAreaTypes = {
		[WorkAreaType.SOWINGMACHINE] = true,
		[WorkAreaType.RIDGEMARKER] = true
	}
	self.rewardPerHa = SowMission.REWARD_PER_HA

	return self
end

function SowMission:saveToXMLFile(xmlFile, key)
	SowMission:superClass().saveToXMLFile(self, xmlFile, key)

	local sowKey = string.format("%s.sow", key)
	local fruitTypeName = g_fruitTypeManager:getFruitTypeNameByIndex(self.fruitType)

	setXMLString(xmlFile, sowKey .. "#fruitTypeName", fruitTypeName)
end

function SowMission:loadFromXMLFile(xmlFile, key)
	if not SowMission:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end

	local sowKey = key .. ".sow(0)"
	local fruitTypeName = getXMLString(xmlFile, sowKey .. "#fruitTypeName")
	local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)
	self.fruitType = fruitType.index

	self:updateReimbursement()
	self:createModifier()

	return true
end

function SowMission:writeStream(streamId, connection)
	SowMission:superClass().writeStream(self, streamId, connection)
	streamWriteUIntN(streamId, self.fruitType, FruitTypeManager.SEND_NUM_BITS)
end

function SowMission:readStream(streamId, connection)
	SowMission:superClass().readStream(self, streamId, connection)

	self.fruitType = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)

	self:updateReimbursement()
end

function SowMission:init(field, ...)
	self.fruitType = self:decideFruitType(field)

	if self.fruitType == nil then
		return false
	end

	self:updateReimbursement()

	if not SowMission:superClass().init(self, field, ...) then
		return false
	end

	return true
end

function SowMission:start(...)
	if not SowMission:superClass().start(self, ...) then
		return false
	end

	self:createModifier()

	return true
end

function SowMission:createModifier()
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitType)

	if fruitDesc ~= nil and fruitDesc.terrainDataPlaneId ~= nil then
		self.completionModifier = DensityMapModifier.new(fruitDesc.terrainDataPlaneId, fruitDesc.startStateChannel, fruitDesc.numStateChannels, self.mission.terrainRootNode)
		self.completionFilter = DensityMapFilter.new(self.completionModifier)

		self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
	end
end

function SowMission:decideFruitType(field)
	if field.plannedFruit == 0 then
		return nil
	end

	if not g_fieldManager:canPlantNow(field) then
		return nil
	end

	return field.plannedFruit
end

function SowMission:finish(success)
	self.field.fruitType = self.fruitType

	SowMission:superClass().finish(self, success)
end

function SowMission:completeField()
	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, self.fruitType, FieldManager.FIELDSTATE_GROWING, 1, 0, true, self.fieldPlowFactor, 1)
	end
end

function SowMission:updateReimbursement()
	if self.mission.economyManager == nil then
		printCallstack()
	end

	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.fruitType)
	self.reimbursementPerHa = fruitDesc.seedUsagePerSqm * 10000 * self.mission.economyManager:getCostPerLiter(FillType.SEEDS)
end

function SowMission:getVehicleVariant()
	local fruitType = self.fruitType

	if fruitType == FruitType.SUNFLOWER or fruitType == FruitType.MAIZE then
		return "MAIZE"
	elseif fruitType == FruitType.SUGARBEET then
		return "SUGARBEET"
	elseif fruitType == FruitType.POTATO then
		return "POTATO"
	elseif fruitType == FruitType.COTTON then
		return "COTTON"
	elseif fruitType == FruitType.SUGARCANE then
		return "SUGARCANE"
	else
		return "GRAIN"
	end
end

function SowMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState, stubbleFactor, rollerFactor)
	local fruitType = field.fruitType
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

	if fruitDesc == nil then
		return true, FieldManager.FIELDSTATE_CULTIVATED
	end

	return false
end

function SowMission:getIsAvailable()
	if not g_currentMission.growthSystem:canFruitBePlanted(self.fruitType) then
		return false
	end

	return SowMission:superClass().getIsAvailable(self)
end

function SowMission:getData()
	return {
		location = string.format(g_i18n:getText("fieldJob_number"), self.field.fieldId),
		jobType = g_i18n:getText("fieldJob_jobType_sowing"),
		action = g_i18n:getText("fieldJob_desc_action_sowing"),
		description = string.format(g_i18n:getText("fieldJob_desc_sowing"), self.field.fieldId, g_fruitTypeManager:getFillTypeByFruitTypeIndex(self.fruitType).title),
		extraText = string.format(g_i18n:getText("fieldJob_desc_fillTheUnit"), g_fillTypeManager:getFillTypeByIndex(FillType.SEEDS).title)
	}
end

function SowMission:partitionCompletion(x, z, widthX, widthZ, heightX, heightZ)
	self.completionModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)

	local _, area, totalArea = self.completionModifier:executeGet(self.completionFilter)

	return area, totalArea
end

function SowMission:validate(event)
	return event ~= FieldManager.FIELDEVENT_SOWN
end

g_missionManager:registerMissionType(SowMission, "sow")
