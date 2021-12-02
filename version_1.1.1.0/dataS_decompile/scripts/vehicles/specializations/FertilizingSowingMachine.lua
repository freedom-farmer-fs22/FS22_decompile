FertilizingSowingMachine = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(SowingMachine, specializations) and SpecializationUtil.hasSpecialization(Sprayer, specializations)
	end,
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("FertilizingSowingMachine")
		schema:register(XMLValueType.BOOL, "vehicle.fertilizingSowingMachine#needsSetIsTurnedOn", "Needs to be turned on to spray", false)
		schema:setXMLSpecializationType()
	end
}

function FertilizingSowingMachine.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "processSowingMachineArea", FertilizingSowingMachine.processSowingMachineArea)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUseSprayerAIRequirements", FertilizingSowingMachine.getUseSprayerAIRequirements)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreEffectsVisible", FertilizingSowingMachine.getAreEffectsVisible)
end

function FertilizingSowingMachine.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", FertilizingSowingMachine)
end

function FertilizingSowingMachine:onLoad(savegame)
	local spec = self.spec_fertilizingSowingMachine
	spec.needsSetIsTurnedOn = self.xmlFile:getValue("vehicle.fertilizingSowingMachine#needsSetIsTurnedOn", false)
	self.spec_sprayer.needsToBeFilledToTurnOn = false
	self.spec_sprayer.useSpeedLimit = false
end

function FertilizingSowingMachine:processSowingMachineArea(superFunc, workArea, dt)
	local spec = self.spec_fertilizingSowingMachine
	local specSowingMachine = self.spec_sowingMachine
	local specSpray = self.spec_sprayer
	local sprayerParams = specSpray.workAreaParameters
	local sowingParams = specSowingMachine.workAreaParameters
	local changedArea, totalArea = nil
	self.spec_sowingMachine.isWorking = self:getLastSpeed() > 0.5

	if not sowingParams.isActive then
		return 0, 0
	end

	if (not self:getIsAIActive() or not g_currentMission.missionInfo.helperBuySeeds) and sowingParams.seedsVehicle == nil then
		if self:getIsAIActive() then
			local rootVehicle = self.rootVehicle

			rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())
		end

		return 0, 0
	end

	if not g_currentMission.missionInfo.helperBuyFertilizer and self:getIsAIActive() then
		if sprayerParams.sprayFillType == nil or sprayerParams.sprayFillType == FillType.UNKNOWN then
			if sprayerParams.lastAIHasSprayed ~= nil then
				local rootVehicle = self.rootVehicle

				rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())

				sprayerParams.lastAIHasSprayed = nil
			end
		else
			sprayerParams.lastAIHasSprayed = true
		end
	end

	if not sowingParams.canFruitBePlanted then
		return 0, 0
	end

	local sprayTypeIndex = SprayType.FERTILIZER

	if sprayerParams.sprayFillLevel <= 0 or spec.needsSetIsTurnedOn and not self:getIsTurnedOn() then
		sprayTypeIndex = nil
	end

	local startX, _, startZ = getWorldTranslation(workArea.start)
	local widthX, _, widthZ = getWorldTranslation(workArea.width)
	local heightX, _, heightZ = getWorldTranslation(workArea.height)

	if not specSowingMachine.useDirectPlanting then
		changedArea, totalArea = FSDensityMapUtil.updateSowingArea(sowingParams.seedsFruitType, startX, startZ, widthX, widthZ, heightX, heightZ, sowingParams.fieldGroundType, sowingParams.angle, nil, sprayTypeIndex)
	else
		changedArea, totalArea = FSDensityMapUtil.updateDirectSowingArea(sowingParams.seedsFruitType, startX, startZ, widthX, widthZ, heightX, heightZ, sowingParams.fieldGroundType, sowingParams.angle, nil, sprayTypeIndex)
	end

	self.spec_sowingMachine.isProcessing = self.spec_sowingMachine.isWorking

	if sprayTypeIndex ~= nil then
		local sprayAmount = specSpray.doubledAmountIsActive and 2 or 1
		local sprayChangedArea, sprayTotalArea = FSDensityMapUtil.updateSprayArea(startX, startZ, widthX, widthZ, heightX, heightZ, sprayTypeIndex, sprayAmount)
		sprayerParams.lastChangedArea = sprayerParams.lastChangedArea + sprayChangedArea
		sprayerParams.lastTotalArea = sprayerParams.lastTotalArea + sprayTotalArea
		sprayerParams.lastStatsArea = 0
		sprayerParams.isActive = true
		sprayerParams.lastSprayTime = g_time
		local stats = g_currentMission:farmStats(self:getLastTouchedFarmlandFarmId())
		local ha = MathUtil.areaToHa(sprayerParams.lastChangedArea, g_currentMission:getFruitPixelsToSqm())

		stats:updateStats("sprayedHectares", ha)
		stats:updateStats("sprayedTime", dt / 60000)
		stats:updateStats("sprayUsage", sprayerParams.usage)
	end

	sowingParams.lastChangedArea = sowingParams.lastChangedArea + changedArea
	sowingParams.lastStatsArea = sowingParams.lastStatsArea + changedArea
	sowingParams.lastTotalArea = sowingParams.lastTotalArea + totalArea

	FSDensityMapUtil.eraseTireTrack(startX, startZ, widthX, widthZ, heightX, heightZ)
	self:updateMissionSowingWarning(startX, startZ)

	return changedArea, totalArea
end

function FertilizingSowingMachine:getUseSprayerAIRequirements(superFunc)
	return false
end

function FertilizingSowingMachine:getAreEffectsVisible(superFunc)
	return superFunc(self) and self:getFillUnitFillType(self:getSprayerFillUnitIndex()) ~= FillType.UNKNOWN
end
