FieldUtil = {
	FILTER_EMPTY = {}
}
local plowModifier, plowValueFilter, sprayModifier, sprayLevelMaxValue, limeModifier, limeValueFilter, fieldFilter, fruitModifier, weedModifier, weedFilter, weedMaxValue = nil

function FieldUtil.onCreate(_, id)
	for i = 0, getNumOfChildren(id) - 1 do
		local fieldId = getChildAt(id, i)
		local field = Field.new()

		if field:load(fieldId) then
			g_fieldManager:addField(field)
		else
			field:delete()
		end
	end
end

function FieldUtil.initTerrain(terrainDetailId)
	local mission = g_currentMission
	local fieldGroundSystem = mission.fieldGroundSystem
	local terrainNode = mission.terrainRootNode
	local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
	local maxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
	sprayModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainNode)
	sprayLevelMaxValue = maxValue
	local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
	plowModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainNode)
	plowValueFilter = DensityMapFilter.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels)

	plowValueFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

	local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
	limeModifier = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainNode)
	limeValueFilter = DensityMapFilter.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels)

	limeValueFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

	fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

	local fruitType = g_fruitTypeManager:getFruitTypeByIndex(FruitType.WHEAT)
	fruitModifier = DensityMapModifier.new(fruitType.terrainDataPlaneId, fruitType.startStateChannel, fruitType.numStateChannels, terrainNode)
	local weedMapId, weedFirstChannel, weedNumChannels = mission.weedSystem:getDensityMapData()

	if weedMapId ~= nil then
		weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainNode)
		weedFilter = DensityMapFilter.new(weedModifier)
		weedMaxValue = 2^weedNumChannels - 1
	end
end

function FieldUtil.getSprayFactor(field)
	local x, z = FieldUtil.getMeasurementPositionOfField(field)

	sprayModifier:setParallelogramWorldCoords(x - 1, z - 1, 2, 0, 0, 2, DensityCoordType.POINT_VECTOR_VECTOR)

	local sumPixels, numPixels, _ = sprayModifier:executeGet()

	return sumPixels / (numPixels * sprayLevelMaxValue)
end

function FieldUtil.getPlowFactor(field, fruitIndependent)
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(field.fruitType)

	if fruitIndependent ~= true and (fruitDesc ~= nil and not fruitDesc.lowSoilDensityRequired or not g_currentMission.missionInfo.plowingRequiredEnabled) then
		return 1
	end

	local x, z = FieldUtil.getMeasurementPositionOfField(field)

	plowModifier:setParallelogramWorldCoords(x - 1, z - 1, 2, 0, 0, 2, DensityCoordType.POINT_VECTOR_VECTOR)

	local _, numPixels, totalPixels = plowModifier:executeGet(fieldFilter, plowValueFilter)

	return numPixels / totalPixels
end

function FieldUtil.getLimeFactor(field)
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(field.fruitType)

	if fruitDesc ~= nil and not fruitDesc.growthRequiresLime or not g_currentMission.missionInfo.limeRequired then
		return 1
	end

	local x, z = FieldUtil.getMeasurementPositionOfField(field)

	limeModifier:setParallelogramWorldCoords(x - 1, z - 1, 2, 0, 0, 2, DensityCoordType.POINT_VECTOR_VECTOR)

	local _, numPixels, totalPixels = limeModifier:executeGet(fieldFilter, limeValueFilter)

	return numPixels / totalPixels
end

function FieldUtil.getWeedFactor(field)
	local x, z = FieldUtil.getMeasurementPositionOfField(field)

	return 1 - FSDensityMapUtil.getWeedFactor(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1)
end

function FieldUtil.getStubbleFactor(field)
	local x, z = FieldUtil.getMeasurementPositionOfField(field)

	return FSDensityMapUtil.getStubbleFactor(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1)
end

function FieldUtil.getRollerFactor(field)
	local x, z = FieldUtil.getMeasurementPositionOfField(field)

	return FSDensityMapUtil.getRollerFactor(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1)
end

function FieldUtil.updateFieldPartitions(field, partitionTable, partitionTargetArea)
	if partitionTable == nil then
		return
	end

	local targetArea = Utils.getNoNil(partitionTargetArea, 400)
	local numDimensions = getNumOfChildren(field.fieldDimensions)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(field.fieldDimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x0, _, z0 = getWorldTranslation(dimStart)
		local x1, _, z1 = getWorldTranslation(dimWidth)
		local x2, _, z2 = getWorldTranslation(dimHeight)
		local _, _, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(x0, z0, x1, z1, x2, z2)
		local widthLength = MathUtil.vector2Length(widthX, widthZ)
		local heightLength = MathUtil.vector2Length(heightX, heightZ)
		local _, area, _ = MathUtil.crossProduct(widthX, 0, widthZ, heightX, 0, heightZ)
		area = math.abs(area)
		local widthNumSteps = math.max(1, math.floor(math.sqrt(widthLength * area / (targetArea * heightLength)) + 0.5))
		local heightNumSteps = math.ceil(area / (widthNumSteps * targetArea))
		local widthStepX = widthX / widthNumSteps
		local widthStepZ = widthZ / widthNumSteps
		local heightStepX = heightX / heightNumSteps
		local heightStepZ = heightZ / heightNumSteps
		local widthStepScale = 1 + 0.1 / (widthLength / widthNumSteps)
		local heightStepScale = 1 + 0.1 / (heightLength / heightNumSteps)

		for iWidth = 0, widthNumSteps - 1 do
			for iHeight = 0, heightNumSteps - 1 do
				local partition = {
					x0 = x0 + widthStepX * iWidth + heightStepX * iHeight,
					z0 = z0 + widthStepZ * iWidth + heightStepZ * iHeight
				}

				if iWidth < widthNumSteps - 1 then
					partition.widthX = widthStepX * widthStepScale
					partition.widthZ = widthStepZ * widthStepScale
				else
					partition.widthX = widthStepX
					partition.widthZ = widthStepZ
				end

				if iHeight < heightNumSteps - 1 then
					partition.heightX = heightStepX * heightStepScale
					partition.heightZ = heightStepZ * heightStepScale
				else
					partition.heightX = heightStepX
					partition.heightZ = heightStepZ
				end

				table.insert(partitionTable, partition)
			end
		end
	end
end

function FieldUtil.getMeasurementPositionOfField(field)
	local dimWidth = getChildAt(field.fieldDimensions, 0)
	local dimStart = getChildAt(dimWidth, 0)
	local dimHeight = getChildAt(dimWidth, 1)
	local x0, _, z0 = getWorldTranslation(dimStart)
	local x1, _, z1 = getWorldTranslation(dimWidth)
	local x2, _, z2 = getWorldTranslation(dimHeight)

	return (x0 + x1 + x2) / 3, (z0 + z1 + z2) / 3
end

function FieldUtil.getCenterOfField(field)
	local posX, posZ = nil
	local sum = 0
	local numDimensions = getNumOfChildren(field.fieldDimensions)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(field.fieldDimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x0, _, z0 = getWorldTranslation(dimStart)
		local x1, _, z1 = getWorldTranslation(dimWidth)
		local x2, _, z2 = getWorldTranslation(dimHeight)
		posX = x0 + x1 + x2
		posZ = z0 + z1 + z2
		sum = sum + 3
	end

	if sum > 0 then
		posX = posX / sum
		posZ = posZ / sum
	end

	return posX, posZ
end

function FieldUtil.getMaxHarvestState(field, fruitType)
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

	if fruitDesc == nil then
		return nil
	end

	local x, z = FieldUtil.getMeasurementPositionOfField(field)
	local minState = fruitDesc.minHarvestingGrowthState
	local maxState = fruitDesc.maxHarvestingGrowthState

	if fruitDesc.preparedGrowthState ~= -1 then
		minState = fruitDesc.minPreparingGrowthState
		maxState = fruitDesc.maxPreparingGrowthState
	end

	local area, _ = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, FieldUtil.FILTER_EMPTY, FieldUtil.FILTER_EMPTY, fruitType, minState, maxState, 0, 0, 0, false)

	if area > 0 then
		local maxArea = 0
		local maxGrowthState = 0

		for i = minState, maxState do
			local growthStateArea, _ = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, FieldUtil.FILTER_EMPTY, FieldUtil.FILTER_EMPTY, fruitType, i, i, 0, 0, 0, false)

			if maxArea < growthStateArea then
				maxArea = growthStateArea
				maxGrowthState = i
			end
		end

		return maxGrowthState
	end

	return nil
end

function FieldUtil.getMaxGrowthState(field, fruitType)
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

	if fruitDesc == nil then
		return nil
	end

	local maxGrowthState = 0
	local maxArea = 0
	local x, z = FieldUtil.getMeasurementPositionOfField(field)
	local growthStateLimit = fruitDesc.minHarvestingGrowthState - 1

	if fruitDesc.preparedGrowthState ~= -1 then
		growthStateLimit = fruitDesc.maxPreparingGrowthState
	end

	for i = 0, growthStateLimit do
		local area, _ = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, FieldUtil.FILTER_EMPTY, FieldUtil.FILTER_EMPTY, fruitType, i, i, 0, 0, 0, false)

		if maxArea < area then
			maxGrowthState = i
			maxArea = area
		end
	end

	return maxGrowthState
end

function FieldUtil.getMaxWeedState(field)
	if weedModifier ~= nil then
		local maxState = 0
		local maxArea = 0
		local x, z = FieldUtil.getMeasurementPositionOfField(field)

		weedModifier:setParallelogramWorldCoords(x - 1, z - 1, 2, 0, 0, 2, DensityCoordType.POINT_VECTOR_VECTOR)

		for i = 1, weedMaxValue do
			weedFilter:setValueCompareParams(DensityValueCompareType.EQUAL, i)

			local area, _ = weedModifier:executeGet(weedFilter, fieldFilter)

			if maxArea < area then
				maxState = i
				maxArea = area
			end
		end

		return maxState
	end

	return 0
end

function FieldUtil.getFruitArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, terrainDetailRequiredValueRanges, terrainDetailProhibitValueRanges, requiredFruitType, requiredMinGrowthState, requiredMaxGrowthState, prohibitedFruitType, prohibitedMinGrowthState, prohibitedMaxGrowthState, useWindrowed)
	local query = g_currentMission.fieldCropsQuery
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = g_currentMission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)

	if requiredFruitType ~= FruitType.UNKNOWN then
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(requiredFruitType)

		if fruitTypeDesc ~= nil and fruitTypeDesc.terrainDataPlaneId ~= nil then
			if useWindrowed then
				return 0, 1
			end

			query:addRequiredCropType(fruitTypeDesc.terrainDataPlaneId, requiredMinGrowthState, requiredMaxGrowthState, fruitTypeDesc.startStateChannel, fruitTypeDesc.numStateChannels, 0, 0)
		end
	end

	if prohibitedFruitType ~= FruitType.UNKNOWN then
		local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(prohibitedFruitType)

		if fruitTypeDesc ~= nil and fruitTypeDesc.terrainDataPlaneId ~= nil then
			query:addProhibitedCropType(fruitTypeDesc.terrainDataPlaneId, prohibitedMinGrowthState, prohibitedMaxGrowthState, fruitTypeDesc.startStateChannel, fruitTypeDesc.numStateChannels, groundTypeFirstChannel, groundTypeNumChannels)
		end
	end

	for _, valueRange in pairs(terrainDetailRequiredValueRanges) do
		query:addRequiredGroundValue(valueRange[1], valueRange[2], valueRange[3], valueRange[4])
	end

	for _, valueRange in pairs(terrainDetailProhibitValueRanges) do
		query:addProhibitedGroundValue(valueRange[1], valueRange[2], valueRange[3], valueRange[4])
	end

	local x, z, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	return query:getParallelogram(x, z, widthX, widthZ, heightX, heightZ, true)
end

function FieldUtil.setAreaFruit(dimensions, fruitTypeIndex, state)
	local numDimensions = getNumOfChildren(dimensions)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(dimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x, _, z = getWorldTranslation(dimStart)
		local x1, _, z1 = getWorldTranslation(dimWidth)
		local x2, _, z2 = getWorldTranslation(dimHeight)

		FieldUtil.setFruit(x, z, x1, z1, x2, z2, fruitTypeIndex, state)
	end
end

function FieldUtil.setFruit(x, z, xWidth, zWidth, xHeight, zHeight, fruitTypeIndex, state)
	local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)

	fruitModifier:resetDensityMapAndChannels(desc.terrainDataPlaneId, desc.startStateChannel, desc.numStateChannels)
	fruitModifier:setParallelogramWorldCoords(x, z, xWidth, zWidth, xHeight, zHeight, DensityCoordType.POINT_POINT_POINT)
	fruitModifier:executeSet(state)
end
