FertilizingCultivator = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(Cultivator, specializations) and SpecializationUtil.hasSpecialization(Sprayer, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("FertilizingCultivator")
		schema:register(XMLValueType.BOOL, "vehicle.fertilizingCultivator#needsSetIsTurnedOn", "Needs to be turned on to spray", false)
		schema:setXMLSpecializationType()
	end
}

function FertilizingCultivator.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processCultivatorArea", FertilizingCultivator.processCultivatorArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setSprayerAITerrainDetailProhibitedRange", FertilizingCultivator.setSprayerAITerrainDetailProhibitedRange)
end

function FertilizingCultivator.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FertilizingCultivator)
end

function FertilizingCultivator:onLoad(savegame)
	local spec = self.spec_fertilizingCultivator
	spec.needsSetIsTurnedOn = self.xmlFile:getValue("vehicle.fertilizingCultivator#needsSetIsTurnedOn", false)
	self.spec_sprayer.useSpeedLimit = false

	self:clearAITerrainDetailRequiredRange()
	self:updateCultivatorAIRequirements()
end

function FertilizingCultivator:processCultivatorArea(superFunc, workArea, dt)
	local spec = self.spec_fertilizingCultivator
	local specCultivator = self.spec_cultivator
	local specSpray = self.spec_sprayer
	local xs, _, zs = getWorldTranslation(workArea.start)
	local xw, _, zw = getWorldTranslation(workArea.width)
	local xh, _, zh = getWorldTranslation(workArea.height)
	local cultivatorParams = specCultivator.workAreaParameters
	local sprayerParams = specSpray.workAreaParameters
	local sprayTypeIndex = SprayType.FERTILIZER

	if sprayerParams.sprayFillLevel <= 0 or spec.needsSetIsTurnedOn and not self:getIsTurnedOn() then
		sprayTypeIndex = nil
	end

	local cultivatorChangedArea, cultivatorTotalArea = nil

	if specCultivator.useDeepMode then
		cultivatorChangedArea, cultivatorTotalArea = FSDensityMapUtil.updateCultivatorArea(xs, zs, xw, zw, xh, zh, not cultivatorParams.limitToField, cultivatorParams.limitFruitDestructionToField, cultivatorParams.angle, sprayTypeIndex)
		cultivatorChangedArea = cultivatorChangedArea + FSDensityMapUtil.updateVineCultivatorArea(xs, zs, xw, zw, xh, zh)
	else
		cultivatorChangedArea, cultivatorTotalArea = FSDensityMapUtil.updateDiscHarrowArea(xs, zs, xw, zw, xh, zh, not cultivatorParams.limitToField, cultivatorParams.limitFruitDestructionToField, cultivatorParams.angle, sprayTypeIndex)
		cultivatorChangedArea = cultivatorChangedArea + FSDensityMapUtil.updateVineCultivatorArea(xs, zs, xw, zw, xh, zh)
	end

	cultivatorParams.lastChangedArea = cultivatorParams.lastChangedArea + cultivatorChangedArea
	cultivatorParams.lastTotalArea = cultivatorParams.lastTotalArea + cultivatorTotalArea
	cultivatorParams.lastStatsArea = cultivatorParams.lastStatsArea + cultivatorChangedArea

	if specCultivator.isSubsoiler then
		FSDensityMapUtil.updateSubsoilerArea(xs, zs, xw, zw, xh, zh)
	end

	FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)

	if sprayTypeIndex ~= nil then
		local sprayAmount = specSpray.doubledAmountIsActive and 2 or 1
		local sprayChangedArea, sprayTotalArea = FSDensityMapUtil.updateSprayArea(xs, zs, xw, zw, xh, zh, sprayTypeIndex, sprayAmount)
		sprayerParams.lastChangedArea = sprayerParams.lastChangedArea + sprayChangedArea
		sprayerParams.lastTotalArea = sprayerParams.lastTotalArea + sprayTotalArea
		sprayerParams.lastStatsArea = 0
		sprayerParams.isActive = true
	end

	specCultivator.isWorking = true

	return cultivatorChangedArea, cultivatorTotalArea
end

function FertilizingCultivator:setSprayerAITerrainDetailProhibitedRange(superFunc, fillType)
	if self.addAITerrainDetailProhibitedRange ~= nil then
		self:clearAITerrainDetailProhibitedRange()

		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)

		if sprayTypeDesc ~= nil then
			local mission = g_currentMission
			local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
			local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
			local sprayLevelMaxValue = mission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)

			self:addAITerrainDetailProhibitedRange(sprayTypeDesc.sprayGroundType, sprayTypeDesc.sprayGroundType, sprayTypeFirstChannel, sprayTypeNumChannels)
		end
	end
end
