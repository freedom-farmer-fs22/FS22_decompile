FSDensityMapUtil = {}
local old = DensityMapModifier.new

function DensityMapModifier.new(...)
	local modifier = old(...)

	modifier:setPolygonRoundingMode(DensityRoundingMode.INCLUSIVE)

	return modifier
end

FSDensityMapUtil.functionCache = {}

function FSDensityMapUtil.clearCache()
	FSDensityMapUtil.functionCache = {}
end

function FSDensityMapUtil.getFieldDataAtWorldPosition(x, y, z)
	local fieldGroundSystem = g_currentMission.fieldGroundSystem
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	local densityBits = getDensityAtWorldPos(groundTypeMapId, x, y, z)
	local groundType = bitAND(bitShiftRight(densityBits, groundTypeFirstChannel), 2^groundTypeNumChannels - 1)
	local isOnField = groundType ~= 0

	return isOnField, densityBits, groundType
end

function FSDensityMapUtil.cutFruitArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, destroySpray, useMinForageState, excludedSprayType, setsWeeds, limitToField)
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)

	if desc.terrainDataPlaneId == nil then
		return 0
	end

	local functionData = FSDensityMapUtil.functionCache.cutFruitArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
		local stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED)
		local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
		functionData = {
			plowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode),
			plowLevelFilter = DensityMapFilter.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)
		}

		functionData.plowLevelFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		functionData.rollerLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
		functionData.rollerLevelFilter = DensityMapFilter.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)

		functionData.rollerLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)

		functionData.limeLevelModifier = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)
		functionData.stubbleShredModifier = DensityMapModifier.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, terrainRootNode)
		functionData.stubbleShredFilter = DensityMapFilter.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, terrainRootNode)

		functionData.stubbleShredFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)

		functionData.groundTypeFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.groundTypeFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		functionData.sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
		functionData.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		functionData.fruitValueModifiers = {}
		functionData.fruitFilters = {}
		functionData.sownType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.SOWN)
		FSDensityMapUtil.functionCache.cutFruitArea = functionData
	end

	local value = desc.cutState

	if value == 0 then
		return 0
	end

	local minState = desc.minHarvestingGrowthState

	if useMinForageState then
		minState = desc.minForageGrowthState
	end

	local sprayLevelModifier = functionData.sprayLevelModifier
	local plowLevelModifier = functionData.plowLevelModifier
	local plowLevelFilter = functionData.plowLevelFilter
	local rollerLevelModifier = functionData.rollerLevelModifier
	local rollerLevelFilter = functionData.rollerLevelFilter
	local groundTypeModifier = functionData.groundTypeModifier
	local sprayLevelMaxValue = functionData.sprayLevelMaxValue
	local fruitValueModifier = functionData.fruitValueModifiers[fruitIndex]
	local fruitFilter = functionData.fruitFilters[fruitIndex]

	if fruitValueModifier == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		fruitValueModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

		fruitValueModifier:setReturnValueShift(-1)

		fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		functionData.fruitFilters[fruitIndex] = fruitFilter
	end

	fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, minState, desc.maxHarvestingGrowthState)
	fruitValueModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local fruitArea, _, _ = fruitValueModifier:executeGet(fruitFilter)

	if fruitArea == 0 then
		return 0
	end

	sprayLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	plowLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	groundTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local sprayPixelsSum, _, _ = sprayLevelModifier:executeGet(fruitFilter)

	if destroySpray then
		FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, excludedSprayType)
		sprayLevelModifier:executeSet(0, fruitFilter)
	end

	if desc.startSprayState > 0 then
		sprayLevelModifier:executeSet(math.min(desc.startSprayState, sprayLevelMaxValue), fruitFilter)
		FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, excludedSprayType)
	end

	local plowTotalDelta = 0
	local rollerTotalDelta = 0
	local limeTotalDelta = 0
	local stubbleTotalDelta = 0
	local weedFactor = 1
	local missionInfo = g_currentMission.missionInfo

	FSDensityMapUtil.removeWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	if missionInfo.weedsEnabled and desc.plantsWeed then
		weedFactor = 1 - FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)

		FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	else
		FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end

	if desc.lowSoilDensityRequired then
		_, plowTotalDelta, _ = plowLevelModifier:executeGet(fruitFilter, plowLevelFilter)
	end

	if desc.increasesSoilDensity and missionInfo.plowingRequiredEnabled then
		plowLevelModifier:executeAdd(-1, fruitFilter)
	end

	if desc.needsRolling then
		rollerLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

		_, rollerTotalDelta, _ = rollerLevelModifier:executeGet(fruitFilter, rollerLevelFilter)
	end

	if desc.consumesLime and missionInfo.limeRequired then
		local limeLevelModifier = functionData.limeLevelModifier

		limeLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

		_, _, limeTotalDelta, _ = limeLevelModifier:executeAdd(-1, fruitFilter)
	end

	if Platform.gameplay.useStubbleShred then
		local stubbleShredModifier = functionData.stubbleShredModifier

		stubbleShredModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

		_, stubbleTotalDelta, _ = stubbleShredModifier:executeGet(fruitFilter, functionData.stubbleShredFilter)
	end

	local terrainDetailPixelsSum, _, _ = groundTypeModifier:executeGet(fruitFilter)
	local maxArea = 0
	local growthState = minState

	for i = minState, desc.maxHarvestingGrowthState do
		fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

		local _, area = fruitValueModifier:executeGet(fruitFilter)

		if maxArea < area then
			growthState = i
			maxArea = area
		end
	end

	fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, minState, desc.maxHarvestingGrowthState)

	if desc.harvestGroundTypeChange ~= nil then
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundValue = fieldGroundSystem:getFieldGroundValue(desc.harvestGroundTypeChange)

		groundTypeModifier:executeSet(groundValue, fruitFilter)
	end

	local groundTypeFilter = nil

	if limitToField then
		groundTypeFilter = functionData.groundTypeFilter
	end

	local density, numPixels, totalNumPixels = fruitValueModifier:executeSet(value, fruitFilter, groundTypeFilter)
	local plowFactor = 0
	local limeFactor = 0
	local sprayFactor = 0
	local stubbleFactor = 0
	local rollerFactor = 0
	local beeFactor = 0

	if numPixels > 0 then
		if desc.lowSoilDensityRequired and missionInfo.plowingRequiredEnabled then
			plowFactor = math.abs(plowTotalDelta) / numPixels
		else
			plowFactor = 1
		end

		if desc.needsRolling then
			rollerFactor = math.abs(rollerTotalDelta) / numPixels
		else
			rollerFactor = 1
		end

		if desc.growthRequiresLime and missionInfo.limeRequired then
			limeFactor = math.abs(limeTotalDelta) / numPixels
		else
			limeFactor = 1
		end

		sprayFactor = sprayPixelsSum / (numPixels * sprayLevelMaxValue)

		if Platform.gameplay.useStubbleShred then
			stubbleFactor = math.abs(stubbleTotalDelta) / numPixels
		else
			stubbleFactor = 1
		end

		if desc.beeYieldBonusPercentage ~= 0 then
			beeFactor = g_currentMission.beehiveSystem:getBeehiveInfluenceFactorAt(startWorldX, startWorldZ) * desc.beeYieldBonusPercentage
		end
	end

	if desc.allowsPartialGrowthState then
		return density / math.max(desc.maxHarvestingGrowthState - 1, 1), totalNumPixels, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeFactor, growthState, maxArea, terrainDetailPixelsSum
	else
		return numPixels, totalNumPixels, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeFactor, growthState, maxArea, terrainDetailPixelsSum
	end
end

function FSDensityMapUtil.getFruitArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, allowPreparing, useMinForageState)
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)

	if desc.terrainDataPlaneId == nil then
		return 0, 0
	end

	local functionData = FSDensityMapUtil.functionCache.getFruitArea

	if functionData == nil then
		functionData = {
			fruitModifiers = {},
			fruitFilter = {}
		}
		FSDensityMapUtil.functionCache.getFruitArea = functionData
	end

	local fruitModifier = functionData.fruitModifiers[fruitIndex]

	if fruitModifier == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

		fruitModifier:setReturnValueShift(-1)

		functionData.fruitModifiers[fruitIndex] = fruitModifier
		functionData.fruitFilter[fruitIndex] = DensityMapFilter.new(fruitModifier)
	end

	local fruitFilter = functionData.fruitFilter[fruitIndex]
	local minState = desc.minHarvestingGrowthState

	if useMinForageState then
		minState = desc.minForageGrowthState
	end

	fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, minState, desc.maxHarvestingGrowthState)

	local ret, numPixels, totalNumPixels = fruitModifier:executeGet(fruitFilter)

	if allowPreparing and desc.minPreparingGrowthState >= 0 and desc.maxPreparingGrowthState >= 0 then
		fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minPreparingGrowthState, desc.maxPreparingGrowthState)

		local ret2, numPixels2, totalNumPixels2 = fruitModifier:executeGet(fruitFilter)
		ret = ret + ret2
		numPixels = numPixels + numPixels2
		totalNumPixels = totalNumPixels + totalNumPixels2
	end

	local maxArea = 0
	local growthState = minState

	for i = minState, desc.maxHarvestingGrowthState do
		fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

		local _, area = fruitModifier:executeGet(fruitFilter)

		if maxArea < area then
			growthState = i
			maxArea = area
		end
	end

	return ret, numPixels, totalNumPixels, growthState
end

function FSDensityMapUtil.updateRollerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
	local functionData = FSDensityMapUtil.functionCache.updateRollerArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
		local rolledSeedbedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.ROLLED_SEEDBED)
		local rollerLinesType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.ROLLER_LINES)
		local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
		local firstSowingValue, lastSowingValue = fieldGroundSystem:getSowingRange()
		functionData = {
			rollerLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode),
			rollerLevelFilter = DensityMapFilter.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
		}

		functionData.rollerLevelFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		functionData.sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)

		functionData.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		functionData.groundTypeAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
		functionData.rollerLinesFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.rollerLinesFilter:setValueCompareParams(DensityValueCompareType.EQUAL, rollerLinesType)

		functionData.rolledSeedbedFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.rolledSeedbedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, rolledSeedbedType)

		functionData.sownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.sownFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowingValue, lastSowingValue)

		functionData.rolledSeedbedType = rolledSeedbedType
		functionData.rollerLinesType = rollerLinesType
		local stoneSystem = g_currentMission.stoneSystem

		if stoneSystem:getMapHasStones() then
			local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
			local stoneMinValue = stoneSystem:getMinMaxValues()
			functionData.stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)

			functionData.stoneModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)

			functionData.stoneFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)

			functionData.stoneFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stoneMinValue)
		end

		functionData.firstGrowthStateFilters = {}

		for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId ~= nil then
				local firstGrowthStateFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)

				firstGrowthStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 1)
				table.insert(functionData.firstGrowthStateFilters, firstGrowthStateFilter)
			end
		end

		FSDensityMapUtil.functionCache.updateRollerArea = functionData
	end

	local rollerLevelModifier = functionData.rollerLevelModifier
	local rollerLevelFilter = functionData.rollerLevelFilter
	local groundTypeModifier = functionData.groundTypeModifier
	local groundTypeAngleModifier = functionData.groundTypeAngleModifier
	local sownFilter = functionData.sownFilter
	local firstGrowthStateFilters = functionData.firstGrowthStateFilters
	local stoneModifier = functionData.stoneModifier
	local stoneFilter = functionData.stoneFilter
	local sowableFilter = functionData.sowableFilter
	local rollerLinesFilter = functionData.rollerLinesFilter
	local rolledSeedbedFilter = functionData.rolledSeedbedFilter
	local rolledSeedbedType = functionData.rolledSeedbedType
	local rollerLinesType = functionData.rollerLinesType

	if stoneModifier ~= nil then
		stoneModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	end

	rollerLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	groundTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	groundTypeAngleModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	angle = angle or 0
	local totalNumChangedPixels = 0

	for i = 1, #firstGrowthStateFilters do
		local firstGrowthStateFilter = firstGrowthStateFilters[i]

		if stoneModifier ~= nil then
			stoneModifier:executeAdd(-1, stoneFilter, sownFilter, firstGrowthStateFilter)
		end

		local _, changedPixels, _ = rollerLevelModifier:executeSet(0, rollerLevelFilter, sownFilter, firstGrowthStateFilter)
		totalNumChangedPixels = totalNumChangedPixels + changedPixels

		groundTypeModifier:executeSet(rollerLinesType, sownFilter, firstGrowthStateFilter)
		groundTypeAngleModifier:executeSet(angle, rollerLinesFilter, firstGrowthStateFilter)
	end

	if stoneModifier ~= nil then
		stoneModifier:executeAdd(-1, stoneFilter)
	end

	local _, changedPixels, _ = rollerLevelModifier:executeSet(0, rollerLevelFilter, sowableFilter)
	totalNumChangedPixels = totalNumChangedPixels + changedPixels

	groundTypeModifier:executeSet(rolledSeedbedType, sowableFilter)
	groundTypeAngleModifier:executeSet(angle, rolledSeedbedFilter)

	return totalNumChangedPixels
end

function FSDensityMapUtil.updateGrassRollerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, removeStones)
	local functionData = FSDensityMapUtil.functionCache.updateGrassRollerArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local sprayType = fieldGroundSystem:getFieldSprayValue(FieldSprayType.FERTILIZER)
		local sprayTypeMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_TYPE)
		local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		local grassDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.GRASS)
		functionData = {
			grassModifier = DensityMapModifier.new(grassDesc.terrainDataPlaneId, grassDesc.startStateChannel, grassDesc.numStateChannels, terrainRootNode),
			grassFilter = DensityMapFilter.new(grassDesc.terrainDataPlaneId, grassDesc.startStateChannel, grassDesc.numStateChannels, terrainRootNode)
		}

		functionData.grassFilter:setValueCompareParams(DensityValueCompareType.GREATER, 1)

		functionData.sprayTypeModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
		functionData.outsideFieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

		functionData.outsideFieldFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)

		functionData.noGrassVisibleFilter = DensityMapFilter.new(grassDesc.terrainDataPlaneId, grassDesc.startStateChannel, grassDesc.numStateChannels, terrainRootNode)

		functionData.noGrassVisibleFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)

		functionData.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)

		functionData.sprayTypeFilter:setValueCompareParams(DensityValueCompareType.GREATER, sprayType)

		if sprayType > 0 then
			functionData.sprayTypeFilter2 = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)

			functionData.sprayTypeFilter2:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayType - 1)
		end

		functionData.notMaxSprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)

		functionData.notMaxSprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)

		functionData.areaMaskedFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)

		functionData.areaMaskedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sprayTypeMaxValue)

		functionData.sprayType = sprayType
		functionData.maskValue = sprayTypeMaxValue
		local stoneSystem = g_currentMission.stoneSystem

		if stoneSystem:getMapHasStones() then
			local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
			local stoneMinValue = stoneSystem:getMinMaxValues()
			functionData.stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)

			functionData.stoneModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)

			functionData.stoneFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)

			functionData.stoneFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stoneMinValue)
		end

		FSDensityMapUtil.functionCache.updateGrassRollerArea = functionData
	end

	local grassModifier = functionData.grassModifier
	local grassFilter = functionData.grassFilter
	local sprayLevelModifier = functionData.sprayLevelModifier
	local sprayTypeModifier = functionData.sprayTypeModifier
	local stoneModifier = functionData.stoneModifier
	local stoneFilter = functionData.stoneFilter
	local outsideFieldFilter = functionData.outsideFieldFilter
	local noGrassVisibleFilter = functionData.noGrassVisibleFilter
	local sprayTypeFilter = functionData.sprayTypeFilter
	local sprayTypeFilter2 = functionData.sprayTypeFilter2
	local notMaxSprayLevelFilter = functionData.notMaxSprayLevelFilter
	local areaMaskedFilter = functionData.areaMaskedFilter
	local sprayType = functionData.sprayType
	local maskValue = functionData.maskValue

	grassModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	if removeStones ~= false and stoneModifier ~= nil then
		stoneModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	end

	sprayTypeModifier:executeSet(maskValue, grassFilter, sprayTypeFilter, notMaxSprayLevelFilter)

	if sprayTypeFilter2 ~= nil then
		sprayTypeModifier:executeSet(maskValue, grassFilter, sprayTypeFilter2, notMaxSprayLevelFilter)
	end

	sprayTypeModifier:executeSet(0, areaMaskedFilter, outsideFieldFilter)
	sprayTypeModifier:executeSet(0, areaMaskedFilter, noGrassVisibleFilter)

	local _, _, numPixels, totalNumPixels = sprayLevelModifier:executeAdd(1, areaMaskedFilter)

	sprayTypeModifier:executeSet(sprayType, areaMaskedFilter)
	grassModifier:executeSet(1, grassFilter)

	if removeStones ~= false and stoneModifier ~= nil then
		stoneModifier:executeAdd(-1, stoneFilter)
	end

	return numPixels, totalNumPixels
end

function FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, delta, fieldFilter, customFilter)
	local stoneSystem = g_currentMission.stoneSystem

	if not stoneSystem:getMapHasStones() then
		return
	end

	local functionData = FSDensityMapUtil.functionCache.addStoneArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
		local _, stoneMaxValue = stoneSystem:getMinMaxValues()
		local stoneMaskValue = stoneSystem:getMaskValue()
		functionData = {
			stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode),
			stoneFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)
		}

		functionData.stoneFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, stoneMaskValue, stoneMaxValue - 1)

		functionData.stoneMaxReachedFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)

		functionData.stoneMaxReachedFilter:setValueCompareParams(DensityValueCompareType.GREATER, stoneMaxValue)

		functionData.stoneMaxValue = stoneMaxValue
		FSDensityMapUtil.functionCache.addStoneArea = functionData
	end

	local stoneModifier = functionData.stoneModifier
	local stoneFilter = functionData.stoneFilter
	local stoneMaxReachedFilter = functionData.stoneMaxReachedFilter
	local stoneMaxValue = functionData.stoneMaxValue

	stoneModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	if fieldFilter == nil then
		stoneModifier:executeAdd(delta, stoneFilter, customFilter)
	else
		stoneModifier:executeAdd(delta, stoneFilter, fieldFilter, customFilter)
	end

	stoneModifier:executeSet(stoneMaxValue, stoneMaxReachedFilter)
end

function FSDensityMapUtil.getStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local stoneSystem = g_currentMission.stoneSystem

	if not stoneSystem:getMapHasStones() then
		return
	end

	local functionData = FSDensityMapUtil.functionCache.getStoneArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
		local stoneMinValue, stoneMaxValue = stoneSystem:getMinMaxValues()
		functionData = {
			stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode),
			stoneFilters = {}
		}

		for i = 0, stoneMaxValue - stoneMinValue do
			local stoneFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)

			stoneFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stoneMinValue + i)
			table.insert(functionData.stoneFilters, stoneFilter)
		end

		FSDensityMapUtil.functionCache.getStoneArea = functionData
	end

	local stoneModifier = functionData.stoneModifier

	stoneModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	for i = #functionData.stoneFilters, 1, -1 do
		local area, _ = stoneModifier:executeGet(functionData.stoneFilters[i])

		if area > 0 then
			return i
		end
	end

	return 0
end

function FSDensityMapUtil.updateStonePickerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
	local stoneSystem = g_currentMission.stoneSystem

	if not stoneSystem:getMapHasStones() then
		return 0, 0, 0
	end

	local functionData = FSDensityMapUtil.functionCache.updateStonePickerArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
		local stoneMinValue, stoneMaxValue = stoneSystem:getMinMaxValues()
		local cultivatedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.CULTIVATED)
		local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
		local pickedValue = stoneSystem:getPickedValue()
		functionData = {
			stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode),
			stoneFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)
		}

		functionData.stoneFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, stoneMinValue, stoneMaxValue)

		functionData.sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)

		functionData.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		functionData.groundAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
		functionData.stoneMinValue = stoneMinValue
		functionData.cultivatedType = cultivatedType
		functionData.pickedValue = pickedValue
		FSDensityMapUtil.functionCache.updateStonePickerArea = functionData
	end

	local stoneModifier = functionData.stoneModifier
	local stoneFilter = functionData.stoneFilter
	local sowableFilter = functionData.sowableFilter
	local groundTypeModifier = functionData.groundTypeModifier
	local groundAngleModifier = functionData.groundAngleModifier
	local stoneMinValue = functionData.stoneMinValue
	local cultivatedType = functionData.cultivatedType
	local pickedValue = functionData.pickedValue
	angle = angle or 0

	groundTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	groundAngleModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	stoneModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local density, area, totalArea = stoneModifier:executeSet(pickedValue, stoneFilter, sowableFilter)

	groundTypeModifier:executeSet(cultivatedType, sowableFilter)
	groundAngleModifier:executeSet(angle, sowableFilter)

	density = math.max(0, density - area * (stoneMinValue - 1))
	local stoneFactor = 0

	if area > 0 then
		stoneFactor = density / area
	end

	return stoneFactor, area, totalArea
end

function FSDensityMapUtil.removeFieldArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, deleteAll)
	local functionData = FSDensityMapUtil.functionCache.removeFieldArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
		local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
		functionData = {}
		local removeFieldMultiModifier = DensityMapMultiModifier.new()
		local clearFieldModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		removeFieldMultiModifier:addExecuteSet(0, clearFieldModifier)

		local clearSprayModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)

		removeFieldMultiModifier:addExecuteSet(0, clearSprayModifier)

		local clearSprayLeveldModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)

		removeFieldMultiModifier:addExecuteSet(0, clearSprayLeveldModifier)

		local clearAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)

		removeFieldMultiModifier:addExecuteSet(0, clearAngleModifier)

		local clearPlowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)

		removeFieldMultiModifier:addExecuteSet(0, clearPlowLevelModifier)

		local clearLimeLevelModifier = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)

		removeFieldMultiModifier:addExecuteSet(0, clearLimeLevelModifier)

		for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId ~= nil and (deleteAll or desc.destruction.canBeDestroyed) then
				local clearFruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

				clearFruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
				removeFieldMultiModifier:addExecuteSet(0, clearFruitModifier)
			end
		end

		for i = 1, #g_currentMission.dynamicFoliageLayers do
			local id = g_currentMission.dynamicFoliageLayers[i]
			local numChannels = getTerrainDetailNumChannels(id)
			local clearDynamicFoliageLayerModifier = DensityMapModifier.new(id, 0, numChannels, terrainRootNode)

			removeFieldMultiModifier:addExecuteSet(0, clearDynamicFoliageLayerModifier)
		end

		functionData.removeFieldMultiModifier = removeFieldMultiModifier
		FSDensityMapUtil.functionCache.removeFieldArea = functionData
	end

	local removeFieldMultiModifier = functionData.removeFieldMultiModifier

	removeFieldMultiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	removeFieldMultiModifier:execute(false)
end

function FSDensityMapUtil.updateCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, blockedSprayTypeIndex, setsWeeds)
	local functionData = FSDensityMapUtil.functionCache.updateCultivatorArea
	local missionInfo = g_currentMission.missionInfo

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local cultivatedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.CULTIVATED)
		functionData = {
			modifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
			modifierAngle = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode),
			filterCultivatorArea = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		}

		functionData.filterCultivatorArea:setValueCompareParams(DensityValueCompareType.EQUAL, cultivatedType)

		functionData.filterField = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.filterField:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		functionData.notCultivatedFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.notCultivatedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, cultivatedType)

		functionData.cultivatedType = cultivatedType
		functionData.noFruitFilter = nil

		for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId ~= nil then
				functionData.noFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

				functionData.noFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
				functionData.noFruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)

				break
			end
		end

		FSDensityMapUtil.functionCache.updateCultivatorArea = functionData
	end

	local modifier = functionData.modifier
	local modifierAngle = functionData.modifierAngle
	local filterCultivatorArea = functionData.filterCultivatorArea
	local filterField = functionData.filterField
	local notCultivatedFilter = functionData.notCultivatedFilter
	local cultivatedType = functionData.cultivatedType
	local noFruitFilter = functionData.noFruitFilter
	createField = Utils.getNoNil(createField, true)
	limitFruitDestructionToField = Utils.getNoNil(limitFruitDestructionToField, true)
	angle = angle or 0

	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitFruitDestructionToField, false)
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifierAngle:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local _, areaBefore, _ = modifier:executeGet(filterCultivatorArea)

	FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)

	local totalArea, changedArea = nil

	if createField then
		filterField = nil
	end

	if missionInfo.stonesEnabled then
		FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 1, filterField, notCultivatedFilter)
	end

	if missionInfo.weedsEnabled then
		FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end

	_, _, totalArea = modifier:executeSet(cultivatedType, filterField, noFruitFilter)

	modifierAngle:executeSet(angle, filterCultivatorArea)

	local _, areaAfter, _ = modifier:executeGet(filterCultivatorArea)
	changedArea = areaAfter - areaBefore

	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	return changedArea, totalArea
end

function FSDensityMapUtil.updateDiscHarrowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, blockedSprayTypeIndex)
	createField = Utils.getNoNil(createField, true)
	limitFruitDestructionToField = Utils.getNoNil(limitFruitDestructionToField, true)
	angle = angle or 0
	local functionData = FSDensityMapUtil.functionCache.updateDiscHarrowArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local stubbleTillageType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.STUBBLE_TILLAGE)
		local seedbedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.SEEDBED)
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		functionData = {
			modifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
			modifierAngle = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode),
			fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		}

		functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		functionData.seedbedTypeFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.seedbedTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, seedbedType)

		functionData.stubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stubbleTillageType)

		functionData.notStubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.notStubbleTillageFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, stubbleTillageType)

		functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
		functionData.sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)

		functionData.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)

		functionData.multiModifiers = {}
		functionData.fruitFilter = {}
		functionData.noFruitFilter = nil
		functionData.stubbleTillageType = stubbleTillageType
		functionData.seedbedType = seedbedType
		FSDensityMapUtil.functionCache.updateDiscHarrowArea = functionData
	end

	local multiModifiers = functionData.multiModifiers
	local multiModifier = multiModifiers[createField]

	if multiModifier == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fruitModifier, fieldFilter = nil

		if not createField then
			fieldFilter = functionData.fieldFilter
		end

		local sprayLevelFilter = functionData.sprayLevelFilter
		local sprayLevelModifier = functionData.sprayLevelModifier
		multiModifier = DensityMapMultiModifier.new()
		multiModifiers[createField] = multiModifier

		for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId ~= nil then
				if functionData.noFruitFilter == nil then
					functionData.noFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

					functionData.noFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
					functionData.noFruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)
				end

				if desc.destruction.canBeDestroyed then
					local fruitFilter = functionData.fruitFilter[index]

					if fruitFilter == nil then
						fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

						fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 1)

						functionData.fruitFilter[index] = fruitFilter
					end

					fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 1)
					multiModifier:addExecuteSet(functionData.stubbleTillageType, functionData.modifier, fruitFilter, fieldFilter)
					fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.numGrowthStates)
					fruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.EQUAL)
					multiModifier:addExecuteAdd(1, sprayLevelModifier, sprayLevelFilter, fruitFilter)

					if fruitModifier == nil then
						fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					else
						fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					end

					fruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
					fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

					if limitFruitDestructionToField then
						multiModifier:addExecuteSet(0, fruitModifier, fruitFilter, fieldFilter)
					else
						multiModifier:addExecuteSet(0, fruitModifier, fruitFilter)
					end
				end
			end
		end

		for i = 1, #g_currentMission.dynamicFoliageLayers do
			local id = g_currentMission.dynamicFoliageLayers[i]
			local numChannels = getTerrainDetailNumChannels(id)
			local modifier = functionData.dynamicFoliageModifier[id]

			if modifier == nil then
				modifier = DensityMapModifier.new(id, 0, numChannels, terrainRootNode)
				functionData.dynamicFoliageModifier[id] = modifier
			end

			multiModifier:addExecuteSet(0, modifier, fieldFilter)
		end
	end

	local modifier = functionData.modifier
	local modifierAngle = functionData.modifierAngle
	local fieldFilter = functionData.fieldFilter
	local seedbedTypeFilter = functionData.seedbedTypeFilter
	local stubbleTillageFilter = functionData.stubbleTillageFilter
	local notStubbleTillageFilter = functionData.notStubbleTillageFilter
	local seedbedType = functionData.seedbedType
	local noFruitFilter = functionData.noFruitFilter

	if createField then
		fieldFilter = nil
	end

	local _, areaBeforeSeedbed, _ = modifier:executeGet(seedbedTypeFilter)
	local _, areaBeforeStubbleTillage, _ = modifier:executeGet(stubbleTillageFilter)
	local _, _, totalArea = modifier:executeGet()

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifierAngle:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifier:executeSet(seedbedType, notStubbleTillageFilter, fieldFilter, noFruitFilter)
	modifierAngle:executeSet(angle, seedbedTypeFilter)
	modifierAngle:executeSet(angle, stubbleTillageFilter)
	multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	multiModifier:execute(false)

	local _, areaAfterSeedbed, _ = modifier:executeGet(seedbedTypeFilter)
	local _, areaAfterStubbleTillage, _ = modifier:executeGet(stubbleTillageFilter)

	FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)

	if g_currentMission.missionInfo.weedsEnabled then
		FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end

	FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	local changedArea = areaAfterSeedbed - areaBeforeSeedbed + areaAfterStubbleTillage - areaBeforeStubbleTillage

	return changedArea, totalArea
end

function FSDensityMapUtil.updatePlowPackerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, angle)
	local functionData = FSDensityMapUtil.functionCache.updatePlowPackerArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local cultivatedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.CULTIVATED)
		local plowedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.PLOWED)
		local seedbedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.SEEDBED)
		functionData = {
			modifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
			modifierAngle = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode),
			filterCultivatorArea = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		}

		functionData.filterCultivatorArea:setValueCompareParams(DensityValueCompareType.EQUAL, cultivatedType)

		functionData.filterPlowArea = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.filterPlowArea:setValueCompareParams(DensityValueCompareType.EQUAL, plowedType)

		functionData.filterSeedbedArea = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.filterSeedbedArea:setValueCompareParams(DensityValueCompareType.EQUAL, seedbedType)

		functionData.seedbedType = seedbedType
		FSDensityMapUtil.functionCache.updatePlowPackerArea = functionData
	end

	local modifier = functionData.modifier
	local modifierAngle = functionData.modifierAngle
	local filterCultivatorArea = functionData.filterCultivatorArea
	local filterPlowArea = functionData.filterPlowArea
	local filterSeedbedArea = functionData.filterSeedbedArea
	local seedbedType = functionData.seedbedType
	angle = angle or 0

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifierAngle:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local _, areaBefore, _ = modifier:executeGet(filterSeedbedArea)
	local totalArea, changedArea = nil
	_, _, _ = modifier:executeSet(seedbedType, filterPlowArea)
	_, _, totalArea = modifier:executeSet(seedbedType, filterCultivatorArea)

	modifierAngle:executeSet(angle, filterSeedbedArea)

	local _, areaAfter, _ = modifier:executeGet(filterSeedbedArea)
	changedArea = areaAfter - areaBefore

	return changedArea, totalArea
end

function FSDensityMapUtil.updateSubsoilerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced)
	local functionData = FSDensityMapUtil.functionCache.updateSubsoilerArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
		local plowLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
		functionData = {
			modifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode),
			fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		}

		functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		functionData.notMaxPlowLevelFilter = DensityMapFilter.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)

		functionData.notMaxPlowLevelFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, plowLevelMaxValue)

		functionData.plowLevelMaxValue = plowLevelMaxValue
		FSDensityMapUtil.functionCache.updateSubsoilerArea = functionData
	end

	local modifier = functionData.modifier
	local fieldFilter = functionData.fieldFilter
	local notMaxPlowLevelFilter = functionData.notMaxPlowLevelFilter
	local plowLevelMaxValue = functionData.plowLevelMaxValue

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	if forced then
		fieldFilter = nil
	end

	if g_currentMission.missionInfo.stonesEnabled then
		FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 2, fieldFilter, notMaxPlowLevelFilter)
	end

	local _, changedArea, totalArea = modifier:executeSet(plowLevelMaxValue, fieldFilter)

	return changedArea, totalArea
end

function FSDensityMapUtil.updatePlowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, createField, limitFruitDestructionToField, angle, resetPlowLevel)
	local functionData = FSDensityMapUtil.functionCache.updatePlowArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
		local plowLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
		local plowedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.PLOWED)
		functionData = {
			groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
			levelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode),
			angleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode),
			plowStateFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		}

		functionData.plowStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, plowedType)

		functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		functionData.notPlowedFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.notPlowedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, plowedType)

		functionData.plowLevelMaxValue = plowLevelMaxValue
		functionData.plowedType = plowedType
		functionData.noFruitFilter = nil

		for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId ~= nil then
				functionData.noFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

				functionData.noFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)
				functionData.noFruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.ALWAYS)

				break
			end
		end

		FSDensityMapUtil.functionCache.updatePlowArea = functionData
	end

	local groundTypeModifier = functionData.groundTypeModifier
	local angleModifier = functionData.angleModifier
	local levelModifier = functionData.levelModifier
	local plowStateFilter = functionData.plowStateFilter
	local fieldFilter = functionData.fieldFilter
	local notPlowedFilter = functionData.notPlowedFilter
	local plowLevelMaxValue = functionData.plowLevelMaxValue
	local plowedType = functionData.plowedType
	local noFruitFilter = functionData.noFruitFilter
	createField = Utils.getNoNil(createField, true)
	limitFruitDestructionToField = Utils.getNoNil(limitFruitDestructionToField, true)
	angle = angle or 0
	resetPlowLevel = Utils.getNoNil(resetPlowLevel, true)

	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitFruitDestructionToField, false)
	groundTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	levelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	angleModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local _, areaBefore, _ = groundTypeModifier:executeGet(plowStateFilter)
	local totalArea = nil

	if createField then
		fieldFilter = nil

		FSDensityMapUtil.clearDecoArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end

	if g_currentMission.missionInfo.stonesEnabled then
		FSDensityMapUtil.addStoneArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, 1, fieldFilter, notPlowedFilter)
	end

	_, _, totalArea = groundTypeModifier:executeSet(plowedType, fieldFilter, noFruitFilter)

	if resetPlowLevel then
		levelModifier:executeSet(plowLevelMaxValue, fieldFilter)
	end

	angleModifier:executeSet(angle, fieldFilter)
	FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, false)

	if g_currentMission.missionInfo.weedsEnabled then
		FSDensityMapUtil.setWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, plowStateFilter)
	end

	local _, areaAfter, _ = groundTypeModifier:executeGet(plowStateFilter)
	local changedArea = areaAfter - areaBefore

	return changedArea, totalArea
end

function FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, onlyOnFields, deleteAll)
	onlyOnFields = Utils.getNoNil(onlyOnFields, false)
	deleteAll = Utils.getNoNil(deleteAll, false)
	local functionData = FSDensityMapUtil.functionCache.updateDestroyCommonArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		functionData = {
			fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		}

		functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
		functionData.sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)

		functionData.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)

		functionData.dynamicFoliageModifier = {}
		functionData.fruitFilter = {}
		functionData.preparingModifier = {}
		functionData.preparingFilter = {}
		functionData.multiModifiers = {}
		FSDensityMapUtil.functionCache.updateDestroyCommonArea = functionData
	end

	local multiModifiers = functionData.multiModifiers

	if multiModifiers[onlyOnFields] == nil then
		multiModifiers[onlyOnFields] = {}
	end

	local multiModifier = multiModifiers[onlyOnFields][deleteAll]

	if multiModifier == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local sprayLevelFilter = functionData.sprayLevelFilter
		local sprayLevelModifier = functionData.sprayLevelModifier
		local fruitModifier = nil
		multiModifier = DensityMapMultiModifier.new()
		multiModifiers[onlyOnFields][deleteAll] = multiModifier
		local fieldFilter = nil

		if onlyOnFields then
			fieldFilter = functionData.fieldFilter
		end

		for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId ~= nil then
				local fruitFilter = functionData.fruitFilter[index]

				if fruitFilter == nil then
					fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

					fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.numGrowthStates)

					functionData.fruitFilter[index] = fruitFilter
				end

				fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.numGrowthStates)
				fruitFilter:setTypeIndexCompareMode(DensityTypeCompareType.EQUAL)
				multiModifier:addExecuteAdd(1, sprayLevelModifier, sprayLevelFilter, fruitFilter, fieldFilter)

				if desc.terrainDataPlaneIdPreparing ~= nil then
					local preparingModifier = functionData.preparingModifier[index]

					if preparingModifier == nil then
						preparingModifier = DensityMapModifier.new(desc.terrainDataPlaneIdPreparing, 0, 1)
						functionData.preparingModifier[index] = preparingModifier
					end

					local preparingFilter = functionData.preparingFilter[index]

					if preparingFilter == nil then
						preparingFilter = DensityMapFilter.new(desc.terrainDataPlaneIdPreparing, 0, 1)

						preparingFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

						functionData.preparingFilter[index] = preparingFilter
					end

					multiModifier:addExecuteSet(0, preparingModifier, preparingFilter)
				end

				if deleteAll or desc.destruction.canBeDestroyed then
					if fruitModifier == nil then
						fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					else
						fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					end

					fruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
					fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
					multiModifier:addExecuteSet(0, fruitModifier, fruitFilter, fieldFilter)
				end
			end
		end

		for i = 1, #g_currentMission.dynamicFoliageLayers do
			local id = g_currentMission.dynamicFoliageLayers[i]
			local numChannels = getTerrainDetailNumChannels(id)
			local modifier = functionData.dynamicFoliageModifier[id]

			if modifier == nil then
				modifier = DensityMapModifier.new(id, 0, numChannels, terrainRootNode)
				functionData.dynamicFoliageModifier[id] = modifier
			end

			multiModifier:addExecuteSet(0, modifier, fieldFilter)
		end
	end

	multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	multiModifier:execute(false)
	FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
end

function FSDensityMapUtil.updateWheelDestructionArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.updateWheelDestructionArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		functionData = {
			modifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode),
			multiModifier = nil,
			filter1 = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
			filter2 = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		}

		functionData.filter2:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		FSDensityMapUtil.functionCache.updateWheelDestructionArea = functionData
	end

	local modifier = functionData.modifier
	local multiModifier = functionData.multiModifier
	local filter1 = functionData.filter1
	local filter2 = functionData.filter2

	g_currentMission.growthSystem:setIgnoreDensityChanges(true)

	if multiModifier == nil then
		multiModifier = DensityMapMultiModifier.new()
		functionData.multiModifier = multiModifier

		for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId ~= nil and desc.destruction.filterStart ~= nil then
				modifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				filter1:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)

				local onlyOnFieldFilter = nil

				if desc.destruction.onlyOnField then
					onlyOnFieldFilter = filter2
				end

				filter1:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.destruction.filterStart, desc.destruction.filterEnd)
				multiModifier:addExecuteSet(desc.destruction.state, modifier, filter1, onlyOnFieldFilter)
			end
		end

		for i = 1, #g_currentMission.dynamicFoliageLayers do
			local id = g_currentMission.dynamicFoliageLayers[i]
			local numChannels = getTerrainDetailNumChannels(id)

			modifier:resetDensityMapAndChannels(id, 0, numChannels)
			multiModifier:addExecuteSet(0, modifier)
		end
	end

	multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	multiModifier:execute(false)
	FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	g_currentMission.growthSystem:setIgnoreDensityChanges(false)
end

function FSDensityMapUtil.setGroundTypeLayerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
	local functionData = FSDensityMapUtil.functionCache.setGroundTypeLayerArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		functionData = {
			groundLayerModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode),
			sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode),
			fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		}

		functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		FSDensityMapUtil.functionCache.setGroundTypeLayerArea = functionData
	end

	local groundLayerModifier = functionData.groundLayerModifier
	local sprayTypeFilter = functionData.sprayTypeFilter
	local fieldFilter = functionData.fieldFilter

	groundLayerModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayTypeFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, value - 1)

	local _, numPixels, totalNumPixels = groundLayerModifier:executeSet(value, sprayTypeFilter, fieldFilter)

	sprayTypeFilter:setValueCompareParams(DensityValueCompareType.GREATER, value)

	local _, numPixels2, totalNumPixels2 = groundLayerModifier:executeSet(value, sprayTypeFilter, fieldFilter)

	return numPixels + numPixels2, totalNumPixels + totalNumPixels2
end

function FSDensityMapUtil.updateSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sprayTypeIndex, sprayAmount)
	local numPixels = 0
	local totalNumPixels = 0
	local desc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)

	if desc ~= nil then
		if desc.isLime then
			numPixels, totalNumPixels = FSDensityMapUtil.updateLimeArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, desc.sprayGroundType)
		elseif desc.isFertilizer then
			numPixels, totalNumPixels = FSDensityMapUtil.updateFertilizerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, desc.sprayGroundType, sprayAmount)
		elseif desc.isHerbicide then
			numPixels, totalNumPixels = FSDensityMapUtil.updateHerbicideArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, desc.sprayGroundType)
		end
	end

	return numPixels, totalNumPixels
end

function FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex, customFilter)
	local functionData = FSDensityMapUtil.functionCache.removeSprayArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		functionData = {
			modifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode),
			filter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		}
		FSDensityMapUtil.functionCache.removeSprayArea = functionData
	end

	local modifier = functionData.modifier
	local filter = functionData.filter

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	if blockedSprayTypeIndex ~= nil then
		local sprayType = g_sprayTypeManager:getSprayTypeByIndex(blockedSprayTypeIndex)

		if sprayType.sprayGroundType > 0 then
			filter:setValueCompareParams(DensityValueCompareType.GREATER, sprayType.sprayGroundType)
			modifier:executeSet(0, filter, customFilter)

			if sprayType.sprayGroundType > 0 then
				filter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayType.sprayGroundType - 1)
				modifier:executeSet(0, filter, customFilter)
			end
		end
	else
		filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
		modifier:executeSet(0, filter, customFilter)
	end
end

function FSDensityMapUtil.updateFertilizerArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, sprayType, sprayAmount)
	local functionData = FSDensityMapUtil.functionCache.updateFertilizerArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local sprayTypeMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_TYPE)
		functionData = {
			sprayModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode),
			sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode),
			growingFruitFilters = {}
		}

		for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId ~= nil then
				local growingFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)

				growingFruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minHarvestingGrowthState + 1, desc.maxHarvestingGrowthState)
				table.insert(functionData.growingFruitFilters, growingFruitFilter)
			end
		end

		functionData.sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels)

		functionData.sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)

		functionData.outsideFieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

		functionData.outsideFieldFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)

		functionData.maskFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)

		functionData.maskFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)

		functionData.maskValue = sprayTypeMaxValue
		FSDensityMapUtil.functionCache.updateFertilizerArea = functionData
	end

	local sprayModifier = functionData.sprayModifier
	local sprayLevelModifier = functionData.sprayLevelModifier
	local sprayTypeFilter = functionData.sprayTypeFilter
	local outsideFieldFilter = functionData.outsideFieldFilter
	local growingFruitFilters = functionData.growingFruitFilters
	local maskFilter = functionData.maskFilter
	local maskValue = functionData.maskValue

	sprayModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayTypeFilter:setValueCompareParams(DensityValueCompareType.GREATER, sprayType)
	sprayModifier:executeSet(maskValue, sprayTypeFilter, maskFilter)

	if sprayType > 0 then
		sprayTypeFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayType - 1)
		sprayModifier:executeSet(maskValue, sprayTypeFilter, maskFilter)
	end

	sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, maskValue)
	sprayModifier:executeSet(0, sprayTypeFilter, outsideFieldFilter)

	for i = 1, #growingFruitFilters do
		local growingFruitFilter = growingFruitFilters[i]

		sprayModifier:executeSet(0, sprayTypeFilter, growingFruitFilter)
	end

	local _, numPixels, totalNumPixels = nil

	for i = 1, math.max(sprayAmount or 1, 1) do
		_, _, numPixels, totalNumPixels = sprayLevelModifier:executeAdd(1, sprayTypeFilter, maskFilter)
	end

	sprayModifier:executeSet(sprayType, sprayTypeFilter)

	return numPixels, totalNumPixels
end

function FSDensityMapUtil.updateLimeArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundType)
	local functionData = FSDensityMapUtil.functionCache.updateLimeArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
		local limeLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL)
		local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
		functionData = {
			modifierSprayType = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode),
			modifierLimeLevel = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode),
			filterLimeLevel = DensityMapFilter.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)
		}

		functionData.filterLimeLevel:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, limeLevelMaxValue - 1)

		functionData.groundFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

		functionData.groundFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)

		functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

		functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		functionData.cutFruitFilters = {}
		functionData.limeLevelMaxValue = limeLevelMaxValue

		for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId ~= nil then
				local cutFruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)

				cutFruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.cutState)

				functionData.cutFruitFilters[index] = cutFruitFilter
			end
		end

		FSDensityMapUtil.functionCache.updateLimeArea = functionData
	end

	local modifierSprayType = functionData.modifierSprayType
	local modifierLimeLevel = functionData.modifierLimeLevel
	local filterLimeLevel = functionData.filterLimeLevel
	local cutFruitFilters = functionData.cutFruitFilters
	local groundFilter = functionData.groundFilter
	local fieldFilter = functionData.fieldFilter
	local limeLevelMaxValue = functionData.limeLevelMaxValue

	modifierSprayType:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	modifierLimeLevel:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local numPixels = 0
	local totalNumPixels = nil

	for index, cutFruitFilter in pairs(cutFruitFilters) do
		local _, _, _ = modifierSprayType:executeSet(groundType, fieldFilter, cutFruitFilter)
		local _, numP, _ = modifierLimeLevel:executeSet(limeLevelMaxValue, fieldFilter, cutFruitFilter, filterLimeLevel)
		numPixels = numPixels + numP
	end

	local _, _, _ = modifierSprayType:executeSet(groundType, groundFilter)
	local _, numP, totalNumP = modifierLimeLevel:executeSet(limeLevelMaxValue, groundFilter, filterLimeLevel)
	numPixels = numPixels + numP
	totalNumPixels = totalNumP

	return numPixels, totalNumPixels
end

function FSDensityMapUtil.updateHerbicideArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, groundType)
	local numPixels = 0
	local totalNumPixels = 0
	local weedSystem = g_currentMission.weedSystem

	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.updateHerbicideArea

		if functionData == nil then
			local terrainRootNode = g_currentMission.terrainRootNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			local cultivatedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.CULTIVATED)
			local plowedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.PLOWED)
			local replacementData = weedSystem:getHerbicideReplacements()
			functionData = {
				replacements = replacementData.weed.replacements,
				weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode),
				sprayModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode),
				cultivatorFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			}

			functionData.cultivatorFilter:setValueCompareParams(DensityValueCompareType.EQUAL, cultivatedType)

			functionData.plowFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

			functionData.plowFilter:setValueCompareParams(DensityValueCompareType.EQUAL, plowedType)

			functionData.weedFilters = {}

			for sourceState, _ in pairs(replacementData.weed.replacements) do
				local weedFilter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)

				weedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)

				functionData.weedFilters[sourceState] = weedFilter
			end

			functionData.fruitFilters = {}

			for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
				if desc.terrainDataPlaneId ~= nil then
					local fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
					functionData.fruitFilters[index] = fruitFilter
				end
			end

			if replacementData.custom ~= nil then
				functionData.multiModifierCustom = DensityMapMultiModifier.new()
				local fruitModifier, sourceStateFilter = nil

				for _, data in ipairs(replacementData.custom) do
					local desc = data.fruitType

					if desc.terrainDataPlaneId ~= nil then
						if fruitModifier == nil then
							fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
						else
							fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
						end

						if sourceStateFilter == nil then
							sourceStateFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
						else
							sourceStateFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
						end

						for sourceState, targetState in pairs(data.replacements) do
							sourceStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
							functionData.multiModifierCustom:addExecuteSet(targetState, fruitModifier, sourceStateFilter)
						end
					end
				end
			end

			FSDensityMapUtil.functionCache.updateHerbicideArea = functionData
		end

		local weedModifier = functionData.weedModifier
		local weedFilters = functionData.weedFilters
		local fruitFilters = functionData.fruitFilters
		local sprayModifier = functionData.sprayModifier
		local cultivatorFilter = functionData.cultivatorFilter
		local plowFilter = functionData.plowFilter
		local multiModifierCustom = functionData.multiModifierCustom

		weedModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		sprayModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

		for sourceState, targetState in pairs(functionData.replacements) do
			local weedFilter = weedFilters[sourceState]

			for index, fruitFilter in pairs(fruitFilters) do
				local desc = g_fruitTypeManager:getFruitTypeByIndex(index)

				fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 1, desc.minHarvestingGrowthState - 1)
				sprayModifier:executeSet(groundType, fruitFilter, weedFilter)

				local _, numP, totalNumP = weedModifier:executeSet(targetState, fruitFilter, weedFilter)
				numPixels = numPixels + numP
				totalNumPixels = totalNumPixels + totalNumP

				fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.cutState + 1)
				sprayModifier:executeSet(groundType, fruitFilter, weedFilter)

				_, numP, totalNumP = weedModifier:executeSet(targetState, fruitFilter, weedFilter)
				numPixels = numPixels + numP
				totalNumPixels = totalNumPixels + totalNumP

				if desc.destruction ~= nil and desc.destruction.state ~= desc.cutState + 1 then
					fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.destruction.state, desc.destruction.state)
					sprayModifier:executeSet(groundType, fruitFilter, weedFilter)

					_, numP, totalNumP = weedModifier:executeSet(targetState, fruitFilter, weedFilter)
					numPixels = numPixels + numP
					totalNumPixels = totalNumPixels + totalNumP
				end
			end

			sprayModifier:executeSet(groundType, cultivatorFilter, weedFilter)

			local _, numP, totalNumP = weedModifier:executeSet(targetState, cultivatorFilter, weedFilter)
			numPixels = numPixels + numP
			totalNumPixels = totalNumPixels + totalNumP

			sprayModifier:executeSet(groundType, plowFilter, weedFilter)

			_, numP, totalNumP = weedModifier:executeSet(targetState, plowFilter, weedFilter)
			numPixels = numPixels + numP
			totalNumPixels = totalNumPixels + totalNumP
		end

		if multiModifierCustom ~= nil then
			multiModifierCustom:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			multiModifierCustom:execute(false)
		end
	end

	return numPixels, totalNumPixels
end

function FSDensityMapUtil.updateWeederArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, isHoeWeeder)
	local weedSystem = g_currentMission.weedSystem
	local _ = nil
	local areaBefore = 0
	local areaAfter = 0

	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.updateWeederArea

		if functionData == nil then
			functionData = {}
			FSDensityMapUtil.functionCache.updateWeederArea = functionData
		end

		local weederData = functionData[isHoeWeeder]

		if weederData == nil then
			local terrainRootNode = g_currentMission.terrainRootNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			local replacementData = weedSystem:getWeederReplacements(isHoeWeeder)
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local firstSowableState, lastSowableState = fieldGroundSystem:getSowableRange()
			weederData = {
				weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode),
				allWeedFilter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
			}

			weederData.allWeedFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

			weederData.multiModifierGrowing = DensityMapMultiModifier.new()
			weederData.multiModifierSowable = DensityMapMultiModifier.new()
			local fruitStateFilter = nil
			local sourceStateFilter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
			local sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

			sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableState, lastSowableState)

			for sourceState, targetState in pairs(replacementData.weed.replacements) do
				sourceStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)

				for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
					if fruitStateFilter == nil then
						fruitStateFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
					else
						fruitStateFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
					end

					local maxWeederState = desc.maxWeederState

					if isHoeWeeder then
						maxWeederState = desc.maxWeederHoeState
					end

					fruitStateFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, maxWeederState)
					weederData.multiModifierGrowing:addExecuteSet(targetState, weederData.weedModifier, sourceStateFilter, fruitStateFilter)
					fruitStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.cutState)
					weederData.multiModifierGrowing:addExecuteSet(targetState, weederData.weedModifier, sourceStateFilter, fruitStateFilter)
				end

				weederData.multiModifierSowable:addExecuteSet(targetState, weederData.weedModifier, sourceStateFilter, sowableFilter)
			end

			if replacementData.custom ~= nil then
				weederData.multiModifierCustom = DensityMapMultiModifier.new()
				local fruitModifier = nil

				for _, data in ipairs(replacementData.custom) do
					local desc = data.fruitType

					if desc.terrainDataPlaneId ~= nil then
						if fruitModifier == nil then
							fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
						else
							fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
						end

						sourceStateFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

						for sourceState, targetState in pairs(data.replacements) do
							sourceStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
							weederData.multiModifierCustom:addExecuteSet(targetState, fruitModifier, sourceStateFilter)
						end
					end
				end
			end

			FSDensityMapUtil.functionCache.updateWeederArea[isHoeWeeder] = weederData
		end

		local weedModifier = weederData.weedModifier
		local allWeedFilter = weederData.allWeedFilter
		local multiModifierGrowing = weederData.multiModifierGrowing
		local multiModifierSowable = weederData.multiModifierSowable
		local multiModifierCustom = weederData.multiModifierCustom

		weedModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

		_, areaBefore, _ = weedModifier:executeGet(allWeedFilter)

		multiModifierGrowing:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		multiModifierGrowing:execute(false)
		multiModifierSowable:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		multiModifierSowable:execute(false)

		if multiModifierCustom ~= nil then
			multiModifierCustom:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			multiModifierCustom:execute(false)
		end

		_, areaAfter, _ = weedModifier:executeGet(allWeedFilter)
	end

	DensityMapHeightUtil.removeFromGroundByArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, FillType.GRASS_WINDROW)
	DensityMapHeightUtil.removeFromGroundByArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, FillType.DRYGRASS_WINDROW)

	return areaBefore - areaAfter
end

function FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local numPixels = 0
	local totalNumPixels = 0
	local weedSystem = g_currentMission.weedSystem

	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.removeWeedArea

		if functionData == nil then
			local terrainRootNode = g_currentMission.terrainRootNode
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			functionData = {
				weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
			}
			FSDensityMapUtil.functionCache.removeWeedArea = functionData
		end

		local weedModifier = functionData.weedModifier

		weedModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

		local _ = nil
		_, numPixels, totalNumPixels = weedModifier:executeSet(0)
	end

	return numPixels, totalNumPixels
end

function FSDensityMapUtil.setSparseWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local weedSystem = g_currentMission.weedSystem

	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.setSparseWeedArea

		if functionData == nil then
			local terrainRootNode = g_currentMission.terrainRootNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			local infoId, _, _ = weedSystem:getInfoLayerData()
			local blockingStateValue, blockingStateFirstChannel, blockingStateNumChannels = weedSystem:getBlockingStateData()
			local sparseState = weedSystem:getSparseStartState()
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			functionData = {
				weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode),
				fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
			}

			functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

			functionData.notWeedBlockedFilter = DensityMapFilter.new(infoId, blockingStateFirstChannel, blockingStateNumChannels, terrainRootNode)

			functionData.notWeedBlockedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, blockingStateValue)

			functionData.sparseState = sparseState
			FSDensityMapUtil.functionCache.setSparseWeedArea = functionData
		end

		local weedModifier = functionData.weedModifier
		local fieldFilter = functionData.fieldFilter
		local notWeedBlockedFilter = functionData.notWeedBlockedFilter
		local sparseState = functionData.sparseState

		weedModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		weedModifier:executeSet(sparseState, fieldFilter, notWeedBlockedFilter)
	end
end

function FSDensityMapUtil.setSowingWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local weedSystem = g_currentMission.weedSystem

	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.setSowingWeedArea

		if functionData == nil then
			local terrainRootNode = g_currentMission.terrainRootNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			local infoId, _, _ = weedSystem:getInfoLayerData()
			local blockingStateValue, blockingStateFirstChannel, blockingStateNumChannels = weedSystem:getBlockingStateData()
			local sparseState = weedSystem:getSparseStartState()
			local denseState = weedSystem:getDenseStartState()
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
			local stubbleTillageValue = fieldGroundSystem:getFieldGroundValue(FieldGroundType.STUBBLE_TILLAGE)
			functionData = {
				weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode),
				notBlockedFilter = DensityMapFilter.new(infoId, blockingStateFirstChannel, blockingStateNumChannels, terrainRootNode)
			}

			functionData.notBlockedFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, blockingStateValue)

			functionData.stubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

			functionData.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stubbleTillageValue)

			functionData.sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

			functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)

			functionData.sparseState = sparseState
			functionData.denseState = denseState
			FSDensityMapUtil.functionCache.setSowingWeedArea = functionData
		end

		local weedModifier = functionData.weedModifier
		local stubbleTillageFilter = functionData.stubbleTillageFilter
		local notBlockedFilter = functionData.notBlockedFilter
		local sowableFilter = functionData.sowableFilter
		local denseState = functionData.denseState
		local sparseState = functionData.sparseState

		weedModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		weedModifier:executeSet(sparseState, sowableFilter, notBlockedFilter)
		weedModifier:executeSet(denseState, stubbleTillageFilter, notBlockedFilter)
	end
end

function FSDensityMapUtil.setWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, customFilter1, customFilter2)
	local weedSystem = g_currentMission.weedSystem

	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.setWeedBlockingState

		if functionData == nil then
			local terrainRootNode = g_currentMission.terrainRootNode
			local infoId, _, _ = weedSystem:getInfoLayerData()
			local blockingValue, blockingStateFirstChannel, blockingStateNumChannels = weedSystem:getBlockingStateData()
			functionData = {
				weedInfoModifier = DensityMapModifier.new(infoId, blockingStateFirstChannel, blockingStateNumChannels, terrainRootNode),
				blockingValue = blockingValue
			}
			FSDensityMapUtil.functionCache.setWeedBlockingState = functionData
		end

		local weedInfoModifier = functionData.weedInfoModifier
		local blockingValue = functionData.blockingValue

		weedInfoModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		weedInfoModifier:executeSet(blockingValue, customFilter1, customFilter2)
	end
end

function FSDensityMapUtil.removeWeedBlockingState(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local weedSystem = g_currentMission.weedSystem

	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.removeWeedBlockingState

		if functionData == nil then
			local terrainRootNode = g_currentMission.terrainRootNode
			local infoId, _, _ = weedSystem:getInfoLayerData()
			local _, blockingStateFirstChannel, blockingStateNumChannels = weedSystem:getBlockingStateData()
			functionData = {
				weedInfoModifier = DensityMapModifier.new(infoId, blockingStateFirstChannel, blockingStateNumChannels, terrainRootNode)
			}
			FSDensityMapUtil.functionCache.removeWeedBlockingState = functionData
		end

		local weedInfoModifier = functionData.weedInfoModifier

		weedInfoModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		weedInfoModifier:executeSet(0)
	end
end

function FSDensityMapUtil.updateMulcherArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.updateMulcherArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED)
		functionData = {
			multiModifier = DensityMapMultiModifier.new(),
			lastArea = 0,
			lastTotalArea = 0
		}
		local multiModifier = functionData.multiModifier
		local stubbleShredModifier = DensityMapModifier.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, terrainRootNode)
		local sprayTypeModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local fruitFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		local fruitModifier = nil

		for _, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.destruction.canBeDestroyed then
				fruitFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, desc.cutState)

				if desc.mulcher.hasChopperGroundLayer then
					local chopperTypeValue = fieldGroundSystem:getChopperTypeValue(desc.mulcher.chopperTypeIndex)

					if chopperTypeValue ~= nil then
						multiModifier:addExecuteSet(chopperTypeValue, sprayTypeModifier, fruitFilter)
					end
				end

				multiModifier:addExecuteAdd(1, stubbleShredModifier, fruitFilter)

				if fruitModifier == nil then
					fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				else
					fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
				end

				if (desc.mulcher.state or 0) == 0 then
					fruitModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)
				end

				fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
				multiModifier:addExecuteSet(desc.mulcher.state or 0, fruitModifier, fruitFilter)
			end
		end

		local weedSystem = g_currentMission.weedSystem

		if weedSystem ~= nil then
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			local sourceStateFilter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
			local weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
			local replacementData = weedSystem:getMulcherReplacements()

			for sourceState, targetState in pairs(replacementData.weed.replacements) do
				sourceStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
				multiModifier:addExecuteSet(targetState, weedModifier, sourceStateFilter)
			end

			if replacementData.custom ~= nil then
				fruitModifier = nil

				for _, data in ipairs(replacementData.custom) do
					local desc = data.fruitType

					if desc.terrainDataPlaneId ~= nil then
						if fruitModifier == nil then
							fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
						else
							fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
						end

						if sourceStateFilter == nil then
							sourceStateFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
						else
							sourceStateFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
						end

						for sourceState, targetState in pairs(data.replacements) do
							sourceStateFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sourceState)
							multiModifier:addExecuteSet(targetState, fruitModifier, sourceStateFilter)
						end
					end
				end
			end

			local desc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.MEADOW)

			if desc ~= nil and desc.terrainDataPlaneId ~= nil then
				local foliageFilter = nil
				local fruitValueModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

				fruitValueModifier:setNewTypeIndexMode(DensityIndexCompareMode.UPDATE)

				if g_currentMission.foliageSystem ~= nil then
					local decoFoliages = g_currentMission.foliageSystem:getDecoFoliages()

					for _, decoFoliage in pairs(decoFoliages) do
						if decoFoliage.mowable and decoFoliage.terrainDataPlaneId ~= nil then
							if foliageFilter == nil then
								foliageFilter = DensityMapFilter.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels, terrainRootNode)

								foliageFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
							else
								foliageFilter:resetDensityMapAndChannels(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels, terrainRootNode)
							end

							if desc.regrows and desc.firstRegrowthState ~= nil then
								multiModifier:addExecuteSet(desc.firstRegrowthState, fruitValueModifier, foliageFilter)
							end
						end
					end
				end
			end
		end

		FSDensityMapUtil.functionCache.updateMulcherArea = functionData
	end

	local multiModifier = functionData.multiModifier

	multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local area, totalArea = multiModifier:execute(false)
	local changeArea = area - functionData.lastArea
	local changeTotalArea = totalArea - functionData.lastTotalArea
	functionData.lastArea = area
	functionData.lastTotalArea = totalArea

	return changeArea, changeTotalArea
end

function FSDensityMapUtil.updateMowerArea(fruitType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, limitToField)
	local desc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.MEADOW)

	if desc ~= nil and desc.terrainDataPlaneId ~= nil then
		local functionData = FSDensityMapUtil.functionCache.updateMowerArea

		if functionData == nil then
			local terrainRootNode = g_currentMission.terrainRootNode
			functionData = {}
			local multiModifier = DensityMapMultiModifier.new()
			local foliageFilter = nil
			local fruitValueModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

			fruitValueModifier:setNewTypeIndexMode(DensityIndexCompareMode.UPDATE)

			if g_currentMission.foliageSystem ~= nil then
				local decoFoliages = g_currentMission.foliageSystem:getDecoFoliages()

				for _, decoFoliage in pairs(decoFoliages) do
					if decoFoliage.mowable and decoFoliage.terrainDataPlaneId ~= nil then
						if foliageFilter == nil then
							foliageFilter = DensityMapFilter.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels, terrainRootNode)

							foliageFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
						else
							foliageFilter:resetDensityMapAndChannels(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels, terrainRootNode)
						end

						if desc.regrows and desc.firstRegrowthState ~= nil then
							multiModifier:addExecuteSet(desc.firstRegrowthState, fruitValueModifier, foliageFilter)
						end
					end
				end
			end

			functionData.multiModifier = multiModifier
			FSDensityMapUtil.functionCache.updateMowerArea = functionData
		end

		local multiModifier = functionData.multiModifier

		if not limitToField then
			multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
			multiModifier:execute(false)
		end
	end

	return FSDensityMapUtil.cutFruitArea(fruitType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, false, nil, , limitToField)
end

function FSDensityMapUtil.getStubbleFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.getStubbleFactor

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED)
		functionData = {
			stubbleShredModifier = DensityMapModifier.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, terrainRootNode),
			stubbleShredFilter = DensityMapFilter.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, terrainRootNode)
		}

		functionData.stubbleShredFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		FSDensityMapUtil.functionCache.getStubbleFactor = functionData
	end

	local stubbleShredModifier = functionData.stubbleShredModifier

	stubbleShredModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local _, stubbleArea, totalPixels = stubbleShredModifier:executeGet(functionData.stubbleShredFilter)

	return stubbleArea / totalPixels
end

function FSDensityMapUtil.getRollerFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.getRollerFactor

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
		functionData = {
			rollerLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode),
			rollerLevelFilter = DensityMapFilter.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
		}

		functionData.rollerLevelFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		FSDensityMapUtil.functionCache.getRollerFactor = functionData
	end

	local rollerLevelModifier = functionData.rollerLevelModifier

	rollerLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local _, rollerArea, totalPixels = rollerLevelModifier:executeGet(functionData.rollerLevelFilter)

	return rollerArea / totalPixels
end

function FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, force, excludeType)
	local functionData = FSDensityMapUtil.functionCache.resetSprayArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		functionData = {
			resetModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode),
			excludeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode),
			sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
		}

		functionData.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue)

		FSDensityMapUtil.functionCache.resetSprayArea = functionData
	end

	local resetModifier = functionData.resetModifier
	local excludeFilter = functionData.excludeFilter

	resetModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local sprayLevelFilter = nil

	if not force then
		sprayLevelFilter = functionData.sprayLevelFilter
	end

	if excludeType == nil then
		resetModifier:executeSet(0, sprayLevelFilter)
	else
		excludeFilter:setValueCompareParams(DensityValueCompareType.GREATER, excludeType)
		resetModifier:executeSet(0, excludeFilter, sprayLevelFilter)

		if excludeType > 0 then
			excludeFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, excludeType - 1)
			resetModifier:executeSet(0, excludeFilter, sprayLevelFilter)
		end
	end
end

function FSDensityMapUtil.updateSowingArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fieldGroundType, angle, growthState, blockedSprayTypeIndex)
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)

	if desc.terrainDataPlaneId == nil then
		return 0, 0
	end

	local functionData = FSDensityMapUtil.functionCache.updateSowingArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
		local rollerLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.ROLLER_LEVEL)
		local sownType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.SOWN)
		local directSownType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.DIRECT_SOWN)
		local ridgeType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.RIDGE)
		local stubbleTillagedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.STUBBLE_TILLAGE)
		local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
		local firstSowingValue, lastSowingValue = fieldGroundSystem:getSowingRange()
		functionData = {
			groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
			groundAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode),
			fruitModifiers = {},
			fruitFilters = {},
			sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
		}

		functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)

		functionData.sowingFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

		functionData.sowingFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowingValue, lastSowingValue)

		functionData.rollerLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
		functionData.rollerLevelMaxValue = rollerLevelMaxValue
		functionData.sownType = sownType
		functionData.directSownType = directSownType
		functionData.ridgeType = ridgeType
		functionData.firstSowableValue = firstSowableValue
		functionData.lastSowableValue = lastSowableValue
		functionData.firstSowingValue = firstSowingValue
		functionData.lastSowingValue = lastSowingValue
		functionData.stubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stubbleTillagedType)

		functionData.directSownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

		functionData.directSownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, directSownType)

		functionData.sownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

		functionData.sownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sownType)

		FSDensityMapUtil.functionCache.updateSowingArea = functionData
	end

	local fruitModifier = functionData.fruitModifiers[fruitIndex]

	if fruitModifier == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		local fruitFilter = DensityMapFilter.new(fruitModifier)
		functionData.fruitModifiers[fruitIndex] = fruitModifier
		functionData.fruitFilters[fruitIndex] = fruitFilter
	end

	local fruitFilter = functionData.fruitFilters[fruitIndex]
	local groundTypeModifier = functionData.groundTypeModifier
	local groundAngleModifier = functionData.groundAngleModifier
	local sowableFilter = functionData.sowableFilter
	local sowingFilter = functionData.sowingFilter
	local rollerLevelModifier = functionData.rollerLevelModifier
	local rollerLevelMaxValue = functionData.rollerLevelMaxValue
	local stubbleTillageFilter = functionData.stubbleTillageFilter
	local directSownFilter = functionData.directSownFilter
	local sownFilter = functionData.sownFilter
	local directSownType = functionData.directSownType
	local sownType = functionData.sownType
	local ridgeType = functionData.ridgeType
	angle = angle or 0
	growthState = growthState or 1
	fieldGroundType = fieldGroundType or sownType

	fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	groundTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	groundAngleModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	rollerLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local rollerLevelValue = 0

	if desc.needsRolling then
		rollerLevelValue = rollerLevelMaxValue
	end

	rollerLevelModifier:executeSet(rollerLevelValue, sowableFilter)
	fruitFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, growthState)

	local _, numPixels, _ = fruitModifier:executeSet(growthState, fruitFilter, sowableFilter)

	if g_currentMission.missionInfo.weedsEnabled and desc.plantsWeed then
		FSDensityMapUtil.setSowingWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	else
		FSDensityMapUtil.removeWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end

	FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex, sowableFilter)

	local totalArea = 0

	if fieldGroundType ~= ridgeType then
		local _, _, totalAreaStubble = groundTypeModifier:executeSet(directSownType, sowableFilter, stubbleTillageFilter)
		totalArea = totalArea + totalAreaStubble
		local _, directArea, totalSownArea = groundTypeModifier:executeGet(directSownFilter)

		if totalSownArea > 0 and directArea / totalSownArea > 0.5 then
			groundTypeModifier:executeSet(directSownType, sownFilter)
		end
	end

	local _, _, totalAreaSown = groundTypeModifier:executeSet(fieldGroundType, sowableFilter)
	totalArea = totalArea + totalAreaSown

	groundAngleModifier:executeSet(angle, sowingFilter)

	local changedArea = numPixels

	return changedArea, totalArea
end

function FSDensityMapUtil.updateDirectSowingArea(fruitIndex, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fieldGroundType, angle, growthState, blockedSprayTypeIndex)
	local fruitTypeManager = g_fruitTypeManager
	local desc = fruitTypeManager:getFruitTypeByIndex(fruitIndex)

	if desc.terrainDataPlaneId == nil then
		return 0, 0
	end

	angle = angle or 0
	growthState = growthState or 1
	local functionData = FSDensityMapUtil.functionCache.updateDirectSowingArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local sownType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.SOWN)
		local directSownType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.DIRECT_SOWN)
		local ridgeType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.RIDGE)
		local stubbleTillagedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.STUBBLE_TILLAGE)
		local firstSowableValue, lastSowableValue = fieldGroundSystem:getSowableRange()
		local firstSowingValue, lastSowingValue = fieldGroundSystem:getSowingRange()
		local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
		local rollerLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.ROLLER_LEVEL)
		functionData = {
			multiModifiers = {},
			fruitModifiers = {},
			fruitFilters = {},
			sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode),
			sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels)
		}

		functionData.sprayLevelFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 0, sprayLevelMaxValue - 1)

		functionData.sprayTypeModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode)
		functionData.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		functionData.groundAngleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainRootNode)
		functionData.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

		functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		functionData.sowableFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

		functionData.sowableFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowableValue, lastSowableValue)

		functionData.sowingFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.sowingFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, firstSowingValue, lastSowingValue)

		functionData.stubbleTillageFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		functionData.stubbleTillageFilter:setValueCompareParams(DensityValueCompareType.EQUAL, stubbleTillagedType)

		functionData.directSownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

		functionData.directSownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, directSownType)

		functionData.sownFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

		functionData.sownFilter:setValueCompareParams(DensityValueCompareType.EQUAL, sownType)

		functionData.rollerLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode)
		functionData.rollerLevelMaxValue = rollerLevelMaxValue
		functionData.sownType = sownType
		functionData.directSownType = directSownType
		functionData.ridgeType = ridgeType
		FSDensityMapUtil.functionCache.updateDirectSowingArea = functionData
	end

	local sowableFilter = functionData.sowableFilter
	local sowingFilter = functionData.sowingFilter
	local fieldFilter = functionData.fieldFilter
	local ridgeType = functionData.ridgeType
	local directSownType = functionData.directSownType
	local stubbleTillageFilter = functionData.stubbleTillageFilter
	local directSownFilter = functionData.directSownFilter
	local sownFilter = functionData.sownFilter
	local sprayLevelModifier = functionData.sprayLevelModifier
	local sprayLevelFilter = functionData.sprayLevelFilter
	local sprayTypeModifier = functionData.sprayTypeModifier
	local groundTypeModifier = functionData.groundTypeModifier
	local groundAngleModifier = functionData.groundAngleModifier
	local fruitMultiModifier = functionData.multiModifiers[fruitIndex]
	local fruitModifier = functionData.fruitModifiers[fruitIndex]
	local terrainRootNode = g_currentMission.terrainRootNode
	local rollerLevelModifier = functionData.rollerLevelModifier
	local rollerLevelMaxValue = functionData.rollerLevelMaxValue

	if fruitMultiModifier == nil then
		fruitMultiModifier = {}
		functionData.multiModifiers[fruitIndex] = fruitMultiModifier
		fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		functionData.fruitModifiers[fruitIndex] = fruitModifier
	end

	local multiModifier = fruitMultiModifier[growthState]

	if multiModifier == nil then
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local stubbleTillagedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.STUBBLE_TILLAGE)
		multiModifier = DensityMapMultiModifier.new()
		fruitMultiModifier[growthState] = multiModifier

		for index, fruitDesc in pairs(fruitTypeManager:getFruitTypes()) do
			if fruitDesc.terrainDataPlaneId ~= nil and fruitDesc.destruction.canBeDestroyed then
				local fruitFilter = functionData.fruitFilters[index]

				if fruitFilter == nil then
					fruitFilter = DensityMapFilter.new(fruitDesc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
					functionData.fruitFilters[index] = fruitFilter
				end

				if fruitDesc.cutState > 1 then
					fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, fruitDesc.numGrowthStages)
					multiModifier:addExecuteAdd(1, sprayLevelModifier, sprayLevelFilter, fieldFilter, fruitFilter)
					multiModifier:addExecuteSet(1, sprayTypeModifier, sprayLevelFilter, fruitFilter)
				end

				if fruitDesc.allowsSeeding then
					if index ~= fruitIndex then
						fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
						multiModifier:addExecuteSet(stubbleTillagedType, groundTypeModifier, fieldFilter, fruitFilter)
					else
						fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, growthState + 1, math.max(fruitDesc.maxHarvestingGrowthState, fruitDesc.cutState))
						multiModifier:addExecuteSet(stubbleTillagedType, groundTypeModifier, fieldFilter, fruitFilter)
					end

					if fruitDesc.mulcher.state ~= nil and fruitDesc.mulcher.state > 0 then
						fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, fruitDesc.mulcher.state)
						multiModifier:addExecuteSet(stubbleTillagedType, groundTypeModifier, fieldFilter, fruitFilter)
					end
				end

				local modifier = functionData.fruitModifiers[index]

				if modifier == nil then
					modifier = DensityMapModifier.new(fruitDesc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
					functionData.fruitModifiers[index] = modifier
				end

				if index ~= fruitIndex then
					fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, 2, math.max(fruitDesc.maxHarvestingGrowthState, fruitDesc.cutState))
				else
					fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, growthState + 1, math.max(fruitDesc.maxHarvestingGrowthState, fruitDesc.cutState))
				end

				multiModifier:addExecuteSet(0, modifier, fruitFilter, fieldFilter)
			end
		end
	end

	fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	groundTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	groundAngleModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	rollerLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	multiModifier:execute(false)

	if g_currentMission.missionInfo.weedsEnabled and desc.plantsWeed then
		FSDensityMapUtil.setSowingWeedArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	end

	local rollerLevelValue = 0

	if desc.needsRolling then
		rollerLevelValue = rollerLevelMaxValue
	end

	rollerLevelModifier:executeSet(rollerLevelValue, sowableFilter)

	local _, changedArea, totalArea = fruitModifier:executeSet(growthState, sowableFilter)

	if fieldGroundType ~= ridgeType then
		groundTypeModifier:executeSet(directSownType, sowableFilter, stubbleTillageFilter)

		local _, directArea, totalSownArea = groundTypeModifier:executeGet(directSownFilter)

		if totalSownArea > 0 and directArea / totalSownArea > 0.5 then
			groundTypeModifier:executeSet(directSownType, sownFilter)
		end
	end

	groundTypeModifier:executeSet(fieldGroundType, sowableFilter)
	groundAngleModifier:executeSet(angle, sowingFilter)
	FSDensityMapUtil.removeSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, blockedSprayTypeIndex)
	DensityMapHeightUtil.clearArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	return changedArea, totalArea
end

function FSDensityMapUtil.updateFruitPreparerArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, startDropWorldX, startDropWorldZ, widthDropWorldX, widthDropWorldZ, heightDropWorldX, heightDropWorldZ)
	local functionData = FSDensityMapUtil.functionCache.updateFruitPreparerArea

	if functionData == nil then
		functionData = {
			fruitModifiers = {},
			fruitFilters = {},
			dropModifiers = {},
			dropFilters = {}
		}
		FSDensityMapUtil.functionCache.updateFruitPreparerArea = functionData
	end

	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
	local fruitModifier = functionData.fruitModifiers[fruitId]

	if fruitModifier == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		local fruitFilter = DensityMapFilter.new(fruitModifier)

		fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minPreparingGrowthState, desc.maxPreparingGrowthState)

		local dropModifier = DensityMapModifier.new(desc.terrainDataPlaneIdPreparing, 0, 1, terrainRootNode)
		local dropFilter = DensityMapFilter.new(fruitModifier)

		dropFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		functionData.dropModifiers[fruitId] = dropModifier
		functionData.dropFilters[fruitId] = dropFilter
		functionData.fruitFilters[fruitId] = fruitFilter
		functionData.fruitModifiers[fruitId] = fruitModifier
	end

	local fruitFilter = functionData.fruitFilters[fruitId]

	fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local _, numChangedPixels = fruitModifier:executeSet(desc.preparedGrowthState, fruitFilter)

	if desc.terrainDataPlaneIdPreparing ~= nil and numChangedPixels > 0 then
		local dropModifier = functionData.dropModifiers[fruitId]
		local dropFilter = functionData.dropFilters[fruitId]

		dropModifier:setParallelogramWorldCoords(startDropWorldX, startDropWorldZ, widthDropWorldX, widthDropWorldZ, heightDropWorldX, heightDropWorldZ, DensityCoordType.POINT_POINT_POINT)
		dropModifier:executeSet(1, dropFilter)
	end

	return numChangedPixels
end

function FSDensityMapUtil.clearDecoArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.clearDecoArea

	if functionData == nil then
		local decoFoliages = nil

		if g_currentMission.foliageSystem ~= nil then
			decoFoliages = g_currentMission.foliageSystem:getDecoFoliages()
		end

		local terrainRootNode = g_currentMission.terrainRootNode

		if decoFoliages ~= nil and #decoFoliages > 0 then
			functionData = {
				decoModifiers = {},
				decoFilters = {},
				decoFoliages = decoFoliages
			}

			for index, decoFoliage in pairs(decoFoliages) do
				if decoFoliage.terrainDataPlaneId ~= nil then
					local decoModifier = DensityMapModifier.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels, terrainRootNode)

					decoModifier:setNewTypeIndexMode(DensityIndexCompareMode.ZERO)

					local decoFilter = DensityMapFilter.new(decoFoliage.terrainDataPlaneId, decoFoliage.startStateChannel, decoFoliage.numStateChannels, terrainRootNode)

					decoFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

					functionData.decoModifiers[index] = decoModifier
					functionData.decoFilters[index] = decoFilter
				end
			end

			FSDensityMapUtil.functionCache.clearDecoArea = functionData
		end
	end

	if functionData ~= nil then
		local area = 0
		local totalArea = 0
		local nonMowableCut = false

		for index, decoFoliage in pairs(functionData.decoFoliages) do
			if decoFoliage.terrainDataPlaneId ~= nil then
				local decoModifier = functionData.decoModifiers[index]
				local decoFilter = functionData.decoFilters[index]

				if decoModifier ~= nil and decoFilter ~= nil then
					decoModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

					local _, _area, _totalArea = decoModifier:executeSet(0, decoFilter)
					totalArea = totalArea + _totalArea
					area = area + _area

					if _area > 0 and not decoFoliage.mowable then
						nonMowableCut = true
					end
				end
			end
		end

		return area, totalArea, nonMowableCut
	end

	return 0, 0, false
end

function FSDensityMapUtil.createVineArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.createVineArea

	if functionData == nil then
		functionData = {
			fruitData = {}
		}
		local stoneSystem = g_currentMission.stoneSystem

		if stoneSystem:getMapHasStones() then
			local terrainRootNode = g_currentMission.terrainRootNode
			local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
			functionData.stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)
		end

		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local terrainRootNode = g_currentMission.terrainRootNode
		local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
		functionData.limeLevelModifier = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)
		functionData.limeLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL)
		FSDensityMapUtil.functionCache.createVineArea = functionData
	end

	local fruitData = functionData.fruitData[fruitId]

	if fruitData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local grassType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.GRASS)

		if desc.terrainDataPlaneId == nil then
			return 0
		end

		fruitData = {
			fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		}

		fruitData.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)

		fruitData.fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

		fruitData.fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)

		fruitData.groundModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)

		fruitData.groundModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)

		fruitData.grassType = grassType
		functionData.fruitData[fruitId] = fruitData
	end

	local fruitModifier = fruitData.fruitModifier
	local fruitFilter = fruitData.fruitFilter
	local groundModifier = fruitData.groundModifier
	local grassType = fruitData.grassType
	local stoneModifier = functionData.stoneModifier
	local limeLevelModifier = functionData.limeLevelModifier

	fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	groundModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, false, false)

	if stoneModifier ~= nil then
		stoneModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		stoneModifier:executeSet(0)
	end

	if limeLevelModifier ~= nil then
		limeLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
		limeLevelModifier:executeSet(functionData.limeLevelMaxValue)
	end

	local _, area = fruitModifier:executeSet(1, fruitFilter)

	groundModifier:executeSet(grassType)

	return area
end

function FSDensityMapUtil.destroyVineArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.destroyVineArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		functionData = {
			groundModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		}

		functionData.groundModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)

		FSDensityMapUtil.functionCache.destroyVineArea = functionData
	end

	local groundModifier = functionData.groundModifier

	FSDensityMapUtil.updateDestroyCommonArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, false, true)
	groundModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	groundModifier:executeSet(0)
end

function FSDensityMapUtil.updateVineAreaValues(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, values)
	local functionData = FSDensityMapUtil.functionCache.updateVineAreaValues

	if functionData == nil then
		functionData = {
			fruitData = {}
		}
		FSDensityMapUtil.functionCache.updateVineAreaValues = functionData
	end

	local fruitData = functionData.fruitData[fruitId]

	if fruitData == nil then
		fruitData = {}
		local terrainRootNode = g_currentMission.terrainRootNode
		local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)

		if desc.terrainDataPlaneId == nil then
			for i = 0, desc.numStateChannels^2 - 1 do
				values[i] = 0
			end

			return 0
		end

		fruitData.modifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

		fruitData.modifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)

		fruitData.filters = {}

		for i = 0, desc.numStateChannels^2 - 1 do
			fruitData.filters[i] = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

			fruitData.filters[i]:setValueCompareParams(DensityValueCompareType.EQUAL, i)
		end

		functionData.fruitData[fruitId] = fruitData
	end

	fruitData.modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local totalArea = 0

	for state, _ in pairs(values) do
		local filter = fruitData.filters[state]
		local _, area, tArea = fruitData.modifier:executeGet(filter)
		values[state] = area
		totalArea = math.max(totalArea, tArea)
	end

	return totalArea
end

function FSDensityMapUtil:setVineAreaValue(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, value)
	local functionData = FSDensityMapUtil.functionCache.setVineAreaValue

	if functionData == nil then
		functionData = {
			fruitData = {}
		}
		FSDensityMapUtil.functionCache.setVineAreaValue = functionData
	end

	local fruitData = functionData.fruitData[fruitId]

	if fruitData == nil then
		fruitData = {}
		local terrainRootNode = g_currentMission.terrainRootNode
		local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)
		fruitData.modifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		functionData.fruitData[fruitId] = fruitData
	end

	fruitData.modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	fruitData.modifier:executeSet(value)
end

function FSDensityMapUtil.updateVineCutArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.updateVineCutArea
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
		local plowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)
		functionData = {
			fruitData = {},
			plowLevelModifier = plowLevelModifier,
			sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL),
			sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode),
			sprayLevelFilters = {}
		}

		for i = 1, functionData.sprayLevelMaxValue do
			local sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)

			sprayLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

			functionData.sprayLevelFilters[i] = sprayLevelFilter
		end

		FSDensityMapUtil.functionCache.updateVineCutArea = functionData
	end

	local fruitData = functionData.fruitData[fruitId]

	if fruitData == nil then
		fruitData = {}
		local terrainRootNode = g_currentMission.terrainRootNode

		if desc.terrainDataPlaneId == nil then
			return 0
		end

		fruitData.fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

		fruitData.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)

		fruitData.transitionFilters = {}

		for src, target in pairs(desc.harvestTransitions) do
			local harvestFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

			harvestFilter:setValueCompareParams(DensityValueCompareType.EQUAL, src)

			fruitData.transitionFilters[target] = harvestFilter
		end

		fruitData.harvestFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

		fruitData.harvestFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minHarvestingGrowthState, desc.maxHarvestingGrowthState)

		if desc.harvestWeedState ~= nil then
			fruitData.weedFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

			fruitData.weedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.harvestWeedState)
		end

		functionData.fruitData[fruitId] = fruitData
	end

	local fruitModifier = fruitData.fruitModifier
	local transitionFilters = fruitData.transitionFilters
	local weedFilter = fruitData.weedFilter
	local harvestFilter = fruitData.harvestFilter
	local sprayLevelModifier = functionData.sprayLevelModifier
	local sprayLevelMaxValue = functionData.sprayLevelMaxValue
	local plowLevelModifier = functionData.plowLevelModifier
	local sprayLevelFilters = functionData.sprayLevelFilters

	fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	plowLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local _ = nil
	local sprayLevel = 0

	for i, filter in pairs(sprayLevelFilters) do
		local _, sprayLevelArea, _ = sprayLevelModifier:executeGet(filter)

		if sprayLevelArea > 0 and sprayLevel < i then
			sprayLevel = i
		end
	end

	FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, nil)
	sprayLevelModifier:executeSet(0, harvestFilter)

	if desc.startSprayState > 0 then
		sprayLevelModifier:executeSet(math.min(desc.startSprayState, sprayLevelMaxValue), harvestFilter)
		FSDensityMapUtil.resetSprayArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, true, nil)
	end

	local weedArea = 0

	if weedFilter ~= nil then
		_, weedArea, _ = fruitModifier:executeGet(weedFilter)
	end

	local plowArea = 0
	local plowLevel, _, _ = plowLevelModifier:executeAdd(-1, harvestFilter)
	local area = 0
	local totalArea, filterArea = nil

	for target, filter in pairs(transitionFilters) do
		_, filterArea, totalArea = fruitModifier:executeSet(target, filter)
		area = area + filterArea
	end

	if plowLevel > 0 then
		plowArea = area
	end

	if weedArea < totalArea then
		weedArea = 0
	end

	local weedFactor = 1 - weedArea / totalArea
	local sprayFactor = sprayLevel / sprayLevelMaxValue
	local plowFactor = plowArea / totalArea

	return area, totalArea, weedFactor, sprayFactor, plowFactor
end

function FSDensityMapUtil.updateVinePrepareArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.updateVinePrepareArea

	if functionData == nil then
		functionData = {
			fruitData = {}
		}
		FSDensityMapUtil.functionCache.updateVinePrepareArea = functionData
	end

	local fruitData = functionData.fruitData[fruitId]

	if fruitData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)

		if desc.terrainDataPlaneId == nil then
			return 0
		end

		if desc.witheredState == nil then
			return 0
		end

		fruitData = {
			fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
		}

		fruitData.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)

		fruitData.fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

		fruitData.fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, desc.witheredState)

		functionData.fruitData[fruitId] = fruitData
	end

	local fruitModifier = fruitData.fruitModifier
	local fruitFilter = fruitData.fruitFilter

	fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local _, area, totalArea = fruitModifier:executeSet(1, fruitFilter)

	return area, totalArea
end

function FSDensityMapUtil.resetVineArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, resetState)
	local functionData = FSDensityMapUtil.functionCache.resetVineArea

	if functionData == nil then
		functionData = {
			fruitData = {}
		}
		FSDensityMapUtil.functionCache.resetVineArea = functionData
	end

	local fruitData = functionData.fruitData[fruitId]

	if fruitData == nil then
		fruitData = {}
		local terrainRootNode = g_currentMission.terrainRootNode
		local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitId)

		if desc.terrainDataPlaneId == nil then
			return 0
		end

		fruitData.fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

		fruitData.fruitModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST)

		fruitData.fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)

		fruitData.fruitFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		functionData.fruitData[fruitId] = fruitData
	end

	local fruitModifier = fruitData.fruitModifier
	local fruitFilter = fruitData.fruitFilter

	fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local _, area, totalArea = fruitModifier:executeSet(resetState, fruitFilter)

	return area, totalArea
end

function FSDensityMapUtil.updateVineCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.updateVineCultivatorArea

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local cultivatedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.CULTIVATED)
		local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
		local groundModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		functionData = {
			fruitData = {},
			groundModifier = groundModifier,
			groundFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		}

		functionData.groundFilter:setValueCompareParams(DensityValueCompareType.EQUAL, cultivatedType)

		local multiModifier = DensityMapMultiModifier.new()
		local fruitFilter = nil
		local plowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)

		for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId ~= nil and desc.cultivationStates ~= nil then
				if fruitFilter == nil then
					fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
				else
					fruitFilter:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
				end

				for _, state in ipairs(desc.cultivationStates) do
					fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, state)
					multiModifier:addExecuteSet(cultivatedType, groundModifier, fruitFilter)
					multiModifier:addExecuteAdd(1, plowLevelModifier, fruitFilter)
				end
			end
		end

		functionData.multiModifier = multiModifier
		FSDensityMapUtil.functionCache.updateVineCultivatorArea = functionData
	end

	local multiModifier = functionData.multiModifier
	local groundModifier = functionData.groundModifier
	local groundFilter = functionData.groundFilter

	groundModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local _, areaBefore, _ = groundModifier:executeGet(groundFilter)

	multiModifier:updateParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	multiModifier:execute(false)

	local _, areaAfter, _ = groundModifier:executeGet(groundFilter)

	return areaAfter - areaBefore
end

function FSDensityMapUtil.eraseTireTrack(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local tireTrackSystem = g_currentMission.tireTrackSystem

	if tireTrackSystem ~= nil then
		tireTrackSystem:eraseParallelogram(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	end
end

function FSDensityMapUtil.getAreaDensity(id, firstChannel, numChannels, value, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.getAreaDensity

	if functionData == nil then
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		functionData = {
			filter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels),
			densityMapIdToModifier = {}
		}
		FSDensityMapUtil.functionCache.getAreaDensity = functionData
	end

	local modifier = functionData.densityMapIdToModifier[id]
	local filter = functionData.filter

	if modifier == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		modifier = DensityMapModifier.new(id, firstChannel, numChannels, terrainRootNode)
		functionData.densityMapIdToModifier[id] = modifier
	end

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	filter:setValueCompareParams(DensityValueCompareType.EQUAL, value)

	return modifier:executeGet(filter)
end

function FSDensityMapUtil.getFieldDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.getFieldDensity

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		functionData = {
			modifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
			filter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode)
		}

		functionData.filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		FSDensityMapUtil.functionCache.getFieldDensity = functionData
	end

	local modifier = functionData.modifier
	local filter = functionData.filter

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	return modifier:executeGet(filter)
end

function FSDensityMapUtil.getBushDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.getBushDensity

	if functionData == nil then
		local bushId = getTerrainDataPlaneByName(g_currentMission.terrainRootNode, "decoBush")

		if bushId ~= 0 then
			local terrainRootNode = g_currentMission.terrainRootNode
			functionData = {
				modifier = DensityMapModifier.new(bushId, 0, 4, terrainRootNode)
			}

			functionData.modifier:setReturnValueShift(-1)

			local filter = DensityMapFilter.new(bushId, 0, 4, terrainRootNode)

			filter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

			functionData.filter = filter
			FSDensityMapUtil.functionCache.getBushDensity = functionData
		else
			return 0, 0, 0
		end
	end

	local modifier = functionData.modifier
	local filter = functionData.filter

	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	return modifier:executeGet(filter)
end

function FSDensityMapUtil.convertToDensityMapAngle(angle, maxDensityValue)
	local lowProfile = Platform.id == PlatformId.XBOX_ONE or Platform.id == PlatformId.PS4

	if lowProfile then
		maxDensityValue = 3
	end

	local value = math.floor(angle / math.pi * (maxDensityValue + 1) + 0.5)

	while maxDensityValue < value do
		value = value - (maxDensityValue + 1)
	end

	while value < 0 do
		value = value + maxDensityValue + 1
	end

	if lowProfile then
		value = value * 2
	end

	return value
end

function FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)
	local weedFactor = 0
	local weedSystem = g_currentMission.weedSystem

	if weedSystem:getMapHasWeed() then
		local functionData = FSDensityMapUtil.functionCache.getWeedFactor

		if functionData == nil then
			local terrainRootNode = g_currentMission.terrainRootNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			local factors = weedSystem:getFactors()
			functionData = {
				weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode),
				fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			}

			functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

			functionData.fruitFilters = {}
			functionData.weedStateFilters = {}

			for state, factor in pairs(factors) do
				local filter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)

				filter:setValueCompareParams(DensityValueCompareType.EQUAL, state)

				functionData.weedStateFilters[filter] = factor
			end

			FSDensityMapUtil.functionCache.getWeedFactor = functionData
		end

		local weedModifier = functionData.weedModifier
		local weedStateFilters = functionData.weedStateFilters
		local fieldFilter = functionData.fieldFilter
		local _, pixels, totalPixels, fruitFilter = nil

		if fruitIndex ~= nil then
			fruitFilter = functionData.fruitFilters[fruitIndex]

			if fruitFilter == nil then
				local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
				fruitFilter = DensityMapFilter.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)

				fruitFilter:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minForageGrowthState or desc.minHarvestingGrowthState, desc.maxHarvestingGrowthState)

				functionData.fruitFilters[fruitIndex] = fruitFilter
			end
		end

		weedModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

		_, totalPixels, _ = weedModifier:executeGet(fieldFilter, fruitFilter)

		if totalPixels ~= 0 then
			for filter, factor in pairs(weedStateFilters) do
				_, pixels, _ = weedModifier:executeGet(filter, fieldFilter, fruitFilter)
				weedFactor = weedFactor + pixels / totalPixels * factor
			end
		end
	end

	return weedFactor
end

function FSDensityMapUtil.getFieldStatusAsync(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, callbackFunc, callbackTarget)
	g_asyncTaskManager:addTask(function ()
		local weedSystem = g_currentMission.weedSystem
		local functionData = FSDensityMapUtil.functionCache.getFieldStatusAsync

		if functionData == nil then
			local terrainRootNode = g_currentMission.terrainRootNode
			local fieldGroundSystem = g_currentMission.fieldGroundSystem
			local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
			local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
			local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
			functionData = {
				fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
			}

			functionData.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

			functionData.plowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)
			functionData.plowLevelFilter = DensityMapFilter.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode)

			functionData.plowLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)

			functionData.limeLevelModifier = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)
			functionData.limeLevelFilter = DensityMapFilter.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode)

			functionData.limeLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, 0)

			functionData.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
			functionData.sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode)
			functionData.sprayLevelMaxValue = sprayLevelMaxValue
			functionData.fruitModifiers = {}
			functionData.fruitFilters = {}

			for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
				if desc.terrainDataPlaneId ~= nil then
					local fruitModifier = DensityMapModifier.new(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels, terrainRootNode)
					functionData.fruitModifiers[index] = fruitModifier
					local fruitFilters = {}
					functionData.fruitFilters[index] = fruitFilters

					for i = 0, 2^desc.numStateChannels - 1 do
						local fruitFilter = DensityMapFilter.new(fruitModifier)

						fruitFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)
						table.insert(fruitFilters, fruitFilter)
					end
				end
			end

			FSDensityMapUtil.functionCache.getFieldStatusAsync = functionData
		end

		local fieldFilter = functionData.fieldFilter
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local _, fieldArea, _ = FSDensityMapUtil.getFieldDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

		if fieldArea == 0 then
			callbackFunc(callbackTarget, nil)

			return
		end

		local status = {
			fieldArea = fieldArea,
			farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition((startWorldX + widthWorldX + heightWorldX) / 3, (startWorldZ + widthWorldZ + heightWorldZ) / 3)
		}
		status.ownerFarmId = g_farmlandManager:getFarmlandOwner(status.farmlandId)

		g_asyncTaskManager:addSubtask(function ()
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local cultivatedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.CULTIVATED)
			local _, numPixels, _ = FSDensityMapUtil.getAreaDensity(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, cultivatedType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			status.cultivatorFactor = numPixels / fieldArea
		end)
		g_asyncTaskManager:addSubtask(function ()
			local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
			local plowedType = fieldGroundSystem:getFieldGroundValue(FieldGroundType.PLOWED)
			local _, numPixels, _ = FSDensityMapUtil.getAreaDensity(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, plowedType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			status.plowFactor = numPixels / fieldArea
		end)
		g_asyncTaskManager:addSubtask(function ()
			local limeLevelModifier = functionData.limeLevelModifier
			local limeLevelFilter = functionData.limeLevelFilter

			limeLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

			local _, numPixels, _ = limeLevelModifier:executeGet(limeLevelFilter, fieldFilter)
			status.needsLimeFactor = numPixels / fieldArea
		end)
		g_asyncTaskManager:addSubtask(function ()
			local plowLevelModifier = functionData.plowLevelModifier
			local plowLevelFilter = functionData.plowLevelFilter

			plowLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

			local _, numPixels, _ = plowLevelModifier:executeGet(plowLevelFilter, fieldFilter)
			status.needsPlowFactor = numPixels / fieldArea
		end)
		g_asyncTaskManager:addSubtask(function ()
			status.rollerFactor = FSDensityMapUtil.getRollerFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		end)
		g_asyncTaskManager:addSubtask(function ()
			status.stubbleFactor = FSDensityMapUtil.getRollerFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		end)
		g_asyncTaskManager:addSubtask(function ()
			local sprayLevelModifier = functionData.sprayLevelModifier
			local sprayLevelFilter = functionData.sprayLevelFilter
			local sprayLevelMaxValue = functionData.sprayLevelMaxValue

			sprayLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

			status.fertilizerFactor = 0

			for i = 1, sprayLevelMaxValue do
				sprayLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

				local _, numPixels, _ = sprayLevelModifier:executeGet(sprayLevelFilter, fieldFilter)
				status.fertilizerFactor = status.fertilizerFactor + i * numPixels
			end

			status.fertilizerFactor = status.fertilizerFactor / (sprayLevelMaxValue * fieldArea)
		end)

		status.fruits = {}
		status.fruitPixels = {}

		for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
			if desc.terrainDataPlaneId ~= nil then
				g_asyncTaskManager:addSubtask(function ()
					local fruitModifier = functionData.fruitModifiers[index]
					local fruitFilters = functionData.fruitFilters[index]

					fruitModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

					local maxState = 0
					local maxPixels = 0

					for i = 0, 2^desc.numStateChannels - 1 do
						local _, numPixels, _ = fruitModifier:executeGet(fruitFilters[i + 1], fieldFilter)

						if maxPixels < numPixels then
							maxState = i
							maxPixels = numPixels
						end
					end

					status.fruits[desc.index] = maxState
					status.fruitPixels[desc.index] = maxPixels
				end)
			end
		end

		if weedSystem:getMapHasWeed() then
			g_asyncTaskManager:addSubtask(function ()
				status.weedFactor = 1 - FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			end)
		end

		g_asyncTaskManager:addSubtask(function ()
			callbackFunc(callbackTarget, status)
		end)
	end)
end

function FSDensityMapUtil.getStatus(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local functionData = FSDensityMapUtil.functionCache.getStatus

	if functionData == nil then
		local terrainRootNode = g_currentMission.terrainRootNode
		local fieldGroundSystem = g_currentMission.fieldGroundSystem
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
		local sprayLevelMaxValue = 2^sprayLevelNumChannels - 1
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
		local plowLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
		local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
		local limeLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL)
		local stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED)
		local stubbleShredLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.STUBBLE_SHRED)
		local rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.ROLLER_LEVEL)
		local rollerLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.ROLLER_LEVEL)
		local sprayTypeMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_TYPE)
		functionData = {
			modifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
			filter1 = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
			filter2 = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainRootNode),
			plowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode),
			plowLevelFilter = DensityMapFilter.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainRootNode),
			plowLevelMaxValue = plowLevelMaxValue,
			limeLevelModifier = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode),
			limeLevelFilter = DensityMapFilter.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainRootNode),
			limeLevelMaxValue = limeLevelMaxValue,
			stubbleShredModifier = DensityMapModifier.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, terrainRootNode),
			stubbleShredFilter = DensityMapFilter.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, terrainRootNode),
			stubbleShredLevelMaxValue = stubbleShredLevelMaxValue,
			rollerLevelModifier = DensityMapModifier.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode),
			rollerLevelFilter = DensityMapFilter.new(rollerLevelMapId, rollerLevelFirstChannel, rollerLevelNumChannels, terrainRootNode),
			rollerLevelMaxValue = rollerLevelMaxValue,
			sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode),
			sprayLevelFilter = DensityMapFilter.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainRootNode),
			sprayLevelMaxValue = sprayLevelMaxValue,
			sprayTypeModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode),
			sprayTypeFilter = DensityMapFilter.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainRootNode),
			sprayTypeMaxValue = sprayTypeMaxValue
		}
		local stoneSystem = g_currentMission.stoneSystem

		if stoneSystem:getMapHasStones() then
			local stoneMapId, stoneFirstChannel, stoneNumChannels = stoneSystem:getDensityMapData()
			functionData.stoneModifier = DensityMapModifier.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)
			functionData.stoneFilter = DensityMapFilter.new(stoneMapId, stoneFirstChannel, stoneNumChannels, terrainRootNode)
			functionData.stoneNumChannels = stoneNumChannels
		end

		local weedSystem = g_currentMission.weedSystem

		if weedSystem:getMapHasWeed() then
			local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
			functionData.weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
			functionData.weedFilter = DensityMapFilter.new(weedMapId, weedFirstChannel, weedNumChannels, terrainRootNode)
			functionData.weedNumChannels = weedNumChannels
			local infoId, _, _ = weedSystem:getInfoLayerData()
			local _, blockingStateFirstChannel, blockingStateNumChannels = weedSystem:getBlockingStateData()
			functionData.weedBlockingModifier = DensityMapModifier.new(infoId, blockingStateFirstChannel, blockingStateNumChannels, terrainRootNode)
			functionData.weedBlockingFilter = DensityMapFilter.new(infoId, blockingStateFirstChannel, blockingStateNumChannels, terrainRootNode)
			functionData.weedBlockingNumChannels = blockingStateNumChannels
		end

		FSDensityMapUtil.functionCache.getStatus = functionData
	end

	local plowLevelModifier = functionData.plowLevelModifier
	local limeLevelModifier = functionData.limeLevelModifier
	local stubbleShredModifier = functionData.stubbleShredModifier
	local rollerLevelModifier = functionData.rollerLevelModifier
	local sprayLevelModifier = functionData.sprayLevelModifier
	local stoneModifier = functionData.stoneModifier
	local weedModifier = functionData.weedModifier
	local weedBlockingModifier = functionData.weedBlockingModifier
	local sprayTypeModifier = functionData.sprayTypeModifier

	plowLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	limeLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	stubbleShredModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	rollerLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayLevelModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	sprayTypeModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	if stoneModifier ~= nil then
		stoneModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	end

	if weedModifier ~= nil then
		weedModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	end

	if weedBlockingModifier ~= nil then
		weedBlockingModifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)
	end

	local _ = nil
	local modifier = functionData.modifier
	local filter1 = functionData.filter1
	local filter2 = functionData.filter2
	local fieldGroundSystem = g_currentMission.fieldGroundSystem
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)

	modifier:resetDensityMapAndChannels(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
	modifier:setParallelogramWorldCoords(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, DensityCoordType.POINT_POINT_POINT)

	local status = {}
	local groundTypes = FieldGroundType.getAllOrdered()
	local isFirst = true
	local numPixels, totalPixels = nil

	for _, groundValue in pairs(groundTypes) do
		_, numPixels, totalPixels = FSDensityMapUtil.getAreaDensity(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, groundValue, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

		if isFirst then
			table.insert(status, {
				name = "TotalPixels",
				value = totalPixels
			})
			table.insert(status, {
				value = "",
				name = ""
			})

			isFirst = false
		end

		local name = FieldGroundType.getName(groundValue)

		table.insert(status, {
			name = name .. " " .. groundValue,
			value = numPixels
		})
	end

	table.insert(status, {
		value = "",
		name = ""
	})

	local limeLevelFilter = functionData.limeLevelFilter

	for i = 0, functionData.limeLevelMaxValue do
		limeLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

		_, numPixels, _ = limeLevelModifier:executeGet(limeLevelFilter)

		table.insert(status, {
			name = "lime " .. i,
			value = numPixels
		})
	end

	table.insert(status, {
		value = "",
		name = ""
	})

	local plowLevelFilter = functionData.plowLevelFilter

	for i = 0, functionData.plowLevelMaxValue do
		plowLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

		_, numPixels, _ = plowLevelModifier:executeGet(plowLevelFilter)

		table.insert(status, {
			name = "plow " .. i,
			value = numPixels
		})
	end

	table.insert(status, {
		value = "",
		name = ""
	})

	local stubbleShredFilter = functionData.stubbleShredFilter

	for i = 0, functionData.stubbleShredLevelMaxValue do
		stubbleShredFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

		_, numPixels, _ = stubbleShredModifier:executeGet(stubbleShredFilter)

		table.insert(status, {
			name = "stubbleShred " .. i,
			value = numPixels
		})
	end

	table.insert(status, {
		value = "",
		name = ""
	})

	local rollerLevelFilter = functionData.rollerLevelFilter

	for i = 0, functionData.rollerLevelMaxValue do
		rollerLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

		_, numPixels, _ = rollerLevelModifier:executeGet(rollerLevelFilter)

		table.insert(status, {
			name = "roller " .. i,
			value = numPixels
		})
	end

	table.insert(status, {
		value = "",
		name = ""
	})

	local sprayLevelFilter = functionData.sprayLevelFilter

	for i = 0, functionData.sprayLevelMaxValue do
		sprayLevelFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

		_, numPixels, _ = sprayLevelModifier:executeGet(sprayLevelFilter)

		table.insert(status, {
			name = "fertilizer " .. i,
			value = numPixels
		})
	end

	table.insert(status, {
		value = "",
		name = ""
	})

	local sprayTypeFilter = functionData.sprayTypeFilter
	local sprayTypeMaxValue = functionData.sprayTypeMaxValue

	for i = 0, sprayTypeMaxValue do
		sprayTypeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

		_, numPixels, _ = sprayTypeModifier:executeGet(sprayTypeFilter)
		local sprayType = nil

		for identifier, layerId in pairs(fieldGroundSystem.fieldSprayTypeValue) do
			if layerId == i then
				sprayType = identifier
			end
		end

		if sprayType ~= nil then
			local name = FieldSprayType.getName(sprayType)

			table.insert(status, {
				name = name .. " " .. i,
				value = numPixels
			})
		elseif i == g_currentMission.fieldGroundSystem:getChopperTypeValue(FieldChopperType.CHOPPER_STRAW) then
			table.insert(status, {
				name = "Straw " .. i,
				value = numPixels
			})
		elseif i == g_currentMission.fieldGroundSystem:getChopperTypeValue(FieldChopperType.CHOPPER_MAIZE) then
			table.insert(status, {
				name = "Maize " .. i,
				value = numPixels
			})
		elseif i == sprayTypeMaxValue then
			table.insert(status, {
				name = "Mask " .. i,
				value = numPixels
			})
		end
	end

	if stoneModifier ~= nil then
		table.insert(status, {
			value = "",
			name = ""
		})

		local stoneFilter = functionData.stoneFilter

		for i = 0, 2^functionData.stoneNumChannels - 1 do
			stoneFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

			_, numPixels, _ = stoneModifier:executeGet(stoneFilter)

			table.insert(status, {
				name = "stone " .. i,
				value = numPixels
			})
		end
	end

	if weedModifier ~= nil then
		table.insert(status, {
			value = "",
			name = ""
		})
		table.insert(status, {
			name = "WeedFactor",
			value = FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		})
		table.insert(status, {
			value = "",
			name = ""
		})

		local weedFilter = functionData.weedFilter

		for i = 0, 2^functionData.weedNumChannels - 1 do
			weedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

			_, numPixels, _ = weedModifier:executeGet(weedFilter)

			table.insert(status, {
				name = "weed " .. i,
				value = numPixels
			})
		end
	end

	if weedBlockingModifier ~= nil then
		table.insert(status, {
			value = "",
			name = ""
		})

		local weedBlockingFilter = functionData.weedBlockingFilter

		for i = 0, 2^functionData.weedBlockingNumChannels - 1 do
			weedBlockingFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

			_, numPixels, _ = weedBlockingModifier:executeGet(weedBlockingFilter)

			table.insert(status, {
				name = "weed blocking " .. i,
				value = numPixels
			})
		end
	end

	table.insert(status, {
		value = "",
		name = "",
		newColumn = true
	})

	local foundFruits = {}
	local foundFruitsTotalPixels = {}
	local numFruit = 0

	for index, desc in pairs(g_fruitTypeManager:getFruitTypes()) do
		if desc.terrainDataPlaneId ~= nil then
			modifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
			filter1:resetDensityMapAndChannels(modifier)
			table.insert(status, {
				value = "",
				name = desc.name
			})

			for i = 0, 2^desc.numStateChannels - 1 do
				filter1:setValueCompareParams(DensityValueCompareType.EQUAL, i)

				_, numPixels, _ = modifier:executeGet(filter1)

				if numPixels > 0 and desc.minHarvestingGrowthState < i and i <= desc.maxHarvestingGrowthState then
					local added = table.addElement(foundFruits, index)

					if added then
						table.insert(foundFruitsTotalPixels, numPixels)
					end
				end

				table.insert(status, {
					name = "state " .. i,
					value = numPixels
				})
			end

			if desc.terrainDataPlaneIdPreparing ~= nil then
				modifier:resetDensityMapAndChannels(desc.terrainDataPlaneIdPreparing, 0, 1)
				filter1:resetDensityMapAndChannels(modifier)
				filter1:setValueCompareParams(DensityValueCompareType.GREATER, 0)

				_, numPixels, _ = modifier:executeGet(filter1)

				table.insert(status, {
					name = "state preparing",
					value = numPixels
				})
			end

			numFruit = numFruit + 1

			table.insert(status, {
				value = "",
				name = "",
				newColumn = numFruit % 3 == 0
			})
		end
	end

	status[#status].newColumn = true

	plowLevelFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
	limeLevelFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
	sprayLevelFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

	for k, fruitIndex in ipairs(foundFruits) do
		local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)

		table.insert(status, {
			name = "weedFactor " .. desc.name,
			value = 1 - FSDensityMapUtil.getWeedFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, fruitIndex)
		})

		local fruitTotalPixels = foundFruitsTotalPixels[k]

		filter2:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
		filter2:setValueCompareParams(DensityValueCompareType.BETWEEN, desc.minHarvestingGrowthState + 1, desc.maxHarvestingGrowthState)

		local _, plowPixels, _ = plowLevelModifier:executeGet(plowLevelFilter, filter2)

		table.insert(status, {
			name = "plowFactor " .. desc.name,
			value = string.format("%.4f | %d | %d ", plowPixels / fruitTotalPixels, plowPixels, fruitTotalPixels)
		})

		local _, limePixels, _ = limeLevelModifier:executeGet(limeLevelFilter, filter2)

		table.insert(status, {
			name = "limeFactor " .. desc.name,
			value = string.format("%.4f | %d | %d", limePixels / fruitTotalPixels, limePixels, fruitTotalPixels)
		})

		local sprayPixelsSum, sprayNumPixels, _ = sprayLevelModifier:executeGet(sprayLevelFilter, filter2)
		local sprayFactor = 0

		if sprayNumPixels > 0 then
			sprayFactor = sprayPixelsSum / (fruitTotalPixels * functionData.sprayLevelMaxValue)
		end

		table.insert(status, {
			name = "sprayFactor " .. desc.name,
			value = string.format("%.4f | %d | %d", sprayFactor, sprayPixelsSum, fruitTotalPixels * functionData.sprayLevelMaxValue)
		})
		table.insert(status, {
			name = "rollerFactor",
			value = string.format("%.4f", FSDensityMapUtil.getRollerFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ))
		})
		table.insert(status, {
			name = "stubbleFactor",
			value = string.format("%.4f", FSDensityMapUtil.getStubbleFactor(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ))
		})
	end

	return status
end

function FSDensityMapUtil.assert(bool, warning)
	if FSDensityMapUtil.DEBUG_ENABLED then
		assert(bool, warning)
	end
end
