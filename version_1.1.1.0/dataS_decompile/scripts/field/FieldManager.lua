FieldManager = {
	FIELDSTATE_PLOWED = 0,
	FIELDSTATE_CULTIVATED = 1,
	FIELDSTATE_GROWING = 2,
	FIELDSTATE_HARVESTED = 3,
	FIELDEVENT_PLOWED = 1,
	FIELDEVENT_CULTIVATED = 2,
	FIELDEVENT_HARVESTED = 3,
	FIELDEVENT_GROWN = 4,
	FIELDEVENT_WEEDED = 5,
	FIELDEVENT_SPRAYED = 6,
	FIELDEVENT_SOWN = 7,
	FIELDEVENT_WITHERED = 8,
	FIELDEVENT_GROWING = 9,
	FIELDEVENT_FERTILIZED = 10,
	FIELDEVENT_LIMED = 11,
	DEBUG_SHOW_FIELDSTATUS = false,
	DEBUG_SHOW_FIELDSTATUS_SIZE = 5,
	NPC_START_TIME = 21600000,
	NPC_END_TIME = 79200000
}
local FieldManager_mt = Class(FieldManager, AbstractManager)

function FieldManager.new(customMt)
	local self = AbstractManager.new(customMt or FieldManager_mt)

	return self
end

function FieldManager:initDataStructures()
	self.fields = {}
	self.farmlandIdFieldMapping = {}
	self.fieldStatusParametersToSet = nil
	self.currentFieldPartitionIndex = nil
	self.lastHandledFieldIndex = 0
end

function FieldManager:loadMapData(xmlFile)
	FieldManager:superClass().loadMapData(self)

	local mission = g_currentMission
	self.mission = mission

	mission:addUpdateable(self)

	local terrainNode = mission.terrainRootNode
	local fieldGroundSystem = mission.fieldGroundSystem
	local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
	local sprayLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
	local plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.PLOW_LEVEL)
	local plowLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
	local limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.LIME_LEVEL)
	local limeLevelMaxValue = fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL)
	local stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.STUBBLE_SHRED)
	self.plowLevelMaxValue = plowLevelMaxValue
	self.limeLevelMaxValue = limeLevelMaxValue
	self.sprayLevelMaxValue = sprayLevelMaxValue
	self.fruitModifiers = {}
	self.sprayLevelModifier = DensityMapModifier.new(sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels, terrainNode)
	self.plowLevelModifier = DensityMapModifier.new(plowLevelMapId, plowLevelFirstChannel, plowLevelNumChannels, terrainNode)
	self.limeLevelModifier = DensityMapModifier.new(limeLevelMapId, limeLevelFirstChannel, limeLevelNumChannels, terrainNode)
	self.stubbleShredModifier = DensityMapModifier.new(stubbleShredLevelMapId, stubbleShredLevelFirstChannel, stubbleShredLevelNumChannels, terrainNode)
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	self.groundTypeModifier = DensityMapModifier.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels, terrainNode)
	local groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_ANGLE)
	self.angleModifier = DensityMapModifier.new(groundAngleMapId, groundAngleFirstChannel, groundAngleNumChannels, terrainNode)
	local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
	self.sprayTypeModifier = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, terrainNode)
	self.fieldFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

	self.fieldFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

	if mission.weedSystem:getMapHasWeed() then
		local weedMapId, weedFirstChannel, weedNumChannels = mission.weedSystem:getDensityMapData()
		self.weedModifier = DensityMapModifier.new(weedMapId, weedFirstChannel, weedNumChannels, terrainNode)
	end

	self.fieldGroundSystem = fieldGroundSystem
	local terrainDetailHeightId = mission.terrainDetailHeightId
	self.terrainHeightTypeModifier = DensityMapModifier.new(terrainDetailHeightId, g_densityMapHeightManager.heightTypeFirstChannel, g_densityMapHeightManager.heightTypeNumChannels)
	self.terrainHeightModifier = DensityMapModifier.new(terrainDetailHeightId, getDensityMapHeightFirstChannel(terrainDetailHeightId), getDensityMapHeightNumChannels(terrainDetailHeightId))
	self.groundTypeSown = fieldGroundSystem:getFieldGroundValue(FieldGroundType.SOWN)
	self.sprayTypeFertilizer = fieldGroundSystem:getFieldSprayValue(FieldSprayType.FERTILIZER)
	self.sprayTypeLime = fieldGroundSystem:getFieldSprayValue(FieldSprayType.LIME)
	self.availableFruitTypeIndices = {}

	for _, fruitType in ipairs(g_fruitTypeManager:getFruitTypes()) do
		if fruitType.useForFieldJob and fruitType.allowsSeeding and fruitType.needsSeeding then
			table.insert(self.availableFruitTypeIndices, fruitType.index)
		end
	end

	self.fruitTypesCount = #self.availableFruitTypeIndices
	self.fieldIndexToCheck = 1

	g_asyncTaskManager:addSubtask(function ()
		for i, field in ipairs(self.fields) do
			local posX, posZ = field:getCenterOfFieldWorldPosition()
			local farmland = g_farmlandManager:getFarmlandAtWorldPosition(posX, posZ)

			if farmland ~= nil then
				field:setFarmland(farmland)

				if self.farmlandIdFieldMapping[farmland.id] == nil then
					self.farmlandIdFieldMapping[farmland.id] = {}
				end

				table.insert(self.farmlandIdFieldMapping[farmland.id], field)
			else
				Logging.error("Failed to find farmland in center of field '%s'", i)
			end
		end
	end)

	if not mission.missionInfo.isValid and g_server ~= nil then
		g_asyncTaskManager:addSubtask(function ()
			local index = 1
			local randomOffset = math.random(1, 100)

			for _, field in pairs(self.fields) do
				if field:getIsAIActive() and field.fieldMissionAllowed and not field.farmland.isOwned then
					local fruitIndex = self.availableFruitTypeIndices[(index * #self.fields * 3 - 1 + randomOffset) % #self.availableFruitTypeIndices + 1]

					if field.fieldGrassMission then
						fruitIndex = FruitType.GRASS
					end

					field.plannedFruit = fruitIndex
					local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
					local fieldState = FieldManager.FIELDSTATE_GROWING
					local plowState = nil

					if not mission.missionInfo.plowingRequiredEnabled then
						plowState = self.plowLevelMaxValue
					else
						plowState = math.random(0, self.plowLevelMaxValue)
					end

					local sprayLevel = math.random(0, self.sprayLevelMaxValue)
					local limeState = math.random(0, self.limeLevelMaxValue)
					local weedValue = 0
					local growthState = g_currentMission.growthSystem:getRandomInitialState(fruitIndex)

					if growthState == nil and fruitIndex == FruitType.GRASS then
						growthState = 2
					end

					if growthState ~= nil then
						if fruitDesc.plantsWeed then
							if growthState > 4 then
								weedValue = math.random(3, 9)
							else
								weedValue = math.random(1, 7)
							end
						end
					else
						fieldState = math.random() < 0.5 and FieldManager.FIELDSTATE_CULTIVATED or FieldManager.FIELDSTATE_PLOWED

						if fieldState == FieldManager.FIELDSTATE_PLOWED then
							plowState = self.plowLevelMaxValue
						end

						fruitIndex = 0
					end

					for i = 1, table.getn(field.maxFieldStatusPartitions) do
						self:setFieldPartitionStatus(field, field.maxFieldStatusPartitions, i, fruitIndex, fieldState, growthState, sprayLevel, false, plowState, weedValue, limeState)
					end

					index = index + 1
				end
			end
		end)
	elseif g_server ~= nil then
		for _, field in pairs(self.fields) do
			g_asyncTaskManager:addSubtask(function ()
				self:findFieldFruit(field)
			end)
		end
	end

	g_asyncTaskManager:addSubtask(function ()
		self:findFieldSizes()
	end)
	g_asyncTaskManager:addSubtask(function ()
		g_farmlandManager:addStateChangeListener(self)

		if mission:getIsServer() and g_addCheatCommands then
			addConsoleCommand("gsFieldSetFruit", "Sets a given fruit to field", "consoleCommandSetFieldFruit", self)
			addConsoleCommand("gsFieldSetFruitAll", "Sets a given fruit to all fields", "consoleCommandSetFieldFruitAll", self)
			addConsoleCommand("gsFieldSetGround", "Sets a given fruit to field", "consoleCommandSetFieldGround", self)
			addConsoleCommand("gsFieldSetGroundAll", "Sets a given fruit to allfield", "consoleCommandSetFieldGroundAll", self)
		end

		if g_addCheatCommands then
			addConsoleCommand("gsFieldToggleStatus", "Shows field status", "consoleCommandToggleDebugFieldStatus", self)
		end
	end)
	g_messageCenter:subscribe(MessageType.FARM_PROPERTY_CHANGED, self.onFarmPropertyChanged, self)
	g_messageCenter:subscribe(MessageType.YEAR_CHANGED, self.onYearChanged, self)
	g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
end

function FieldManager:unloadMapData()
	if self.mission ~= nil then
		self.mission:removeUpdateable(self)
	end

	g_farmlandManager:removeStateChangeListener(self)

	for _, field in pairs(self.fields) do
		field:delete()
	end

	self.fields = {}
	self.fieldGroundSystem = nil
	self.sprayLevelModifier = nil
	self.plowLevelModifier = nil
	self.limeLevelModifier = nil
	self.stubbleShredModifier = nil
	self.fruitModifiers = nil
	self.sprayTypeModifier = nil
	self.angleModifier = nil
	self.groundTypeModifier = nil
	self.fieldFilter = nil
	self.weedModifier = nil
	self.terrainHeightTypeModifier = nil
	self.terrainHeightModifier = nil
	self.mission = nil

	g_messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsFieldSetFruit")
	removeConsoleCommand("gsFieldSetFruitAll")
	removeConsoleCommand("gsFieldSetGround")
	removeConsoleCommand("gsFieldSetGroundAll")
	removeConsoleCommand("gsFieldToggleStatus")
	FieldManager:superClass().unloadMapData(self)
end

function FieldManager:delete()
end

function FieldManager:loadFromXMLFile(xmlFilename)
	local xmlFile = XMLFile.load("fields", xmlFilename)

	if xmlFile == nil then
		return
	end

	xmlFile:iterate("fields.field", function (_, key)
		local fieldId = xmlFile:getInt(key .. "#id")
		local fruitName = xmlFile:getString(key .. "#plannedFruit")
		local fruitDesc = g_fruitTypeManager:getFruitTypeByName(fruitName)

		if fieldId ~= nil then
			local field = self:getFieldByIndex(fieldId)

			if field ~= nil then
				if fruitName == "FALLOW" then
					field.plannedFruit = 0
				elseif fruitDesc ~= nil then
					field.plannedFruit = fruitDesc.index
				end
			end
		end
	end)

	self.lastHandledFieldIndex = xmlFile:getInt("fields.lastHandledFieldIndex", self.lastHandledFieldIndex)

	xmlFile:delete()
end

function FieldManager:saveToXMLFile(xmlFilename)
	local xmlFile = XMLFile.create("fields", xmlFilename, "fields")

	for i = 1, #self.fields do
		local field = self.fields[i]
		local key = string.format("fields.field(%d)", i - 1)

		xmlFile:setInt(key .. "#id", field.fieldId)

		if field.plannedFruit == 0 then
			xmlFile:setString(key .. "#plannedFruit", "FALLOW")
		else
			xmlFile:setString(key .. "#plannedFruit", g_fruitTypeManager:getFruitTypeByIndex(field.plannedFruit).name)
		end
	end

	xmlFile:setInt("fields.lastHandledFieldIndex", self.lastHandledFieldIndex)
	xmlFile:save()
	xmlFile:delete()
end

function FieldManager:update(dt)
	if g_server == nil then
		return
	end

	if self.fieldStatusParametersToSet ~= nil then
		if self.currentFieldPartitionIndex == nil then
			self.currentFieldPartitionIndex = 1
		else
			self.currentFieldPartitionIndex = self.currentFieldPartitionIndex + 1
		end

		if table.getn(self.fieldStatusParametersToSet[2]) < self.currentFieldPartitionIndex then
			self.currentFieldPartitionIndex = nil
			self.fieldStatusParametersToSet = nil
		end

		if self.fieldStatusParametersToSet ~= nil then
			local args = self.fieldStatusParametersToSet
			args[3] = self.currentFieldPartitionIndex

			self:setFieldPartitionStatus(args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8], args[9], args[10], args[11])
		end
	else
		local timePerField = (FieldManager.NPC_END_TIME - FieldManager.NPC_START_TIME) / (#self.fields + 1) * g_currentMission.environment.daysPerPeriod

		while self.lastHandledFieldIndex < #self.fields and g_currentMission.environment.dayTime > FieldManager.NPC_START_TIME + (self.lastHandledFieldIndex + 1) * timePerField do
			self.lastHandledFieldIndex = self.lastHandledFieldIndex + 1
			local fieldId = self.lastHandledFieldIndex
			local field = self.fields[fieldId]

			if field:getIsAIActive() and field.fieldMissionAllowed and field.currentMission == nil and field.fruitType ~= FruitType.GRASS then
				self:updateNPCField(field)
			end
		end
	end
end

function FieldManager:draw()
	if FieldManager.DEBUG_SHOW_FIELDSTATUS then
		local x, _, z = getWorldTranslation(getCamera())
		local size = FieldManager.DEBUG_SHOW_FIELDSTATUS_SIZE
		local startWorldX = x - size * 0.5
		local startWorldZ = z + size * 0.5
		local widthWorldX = x + size * 0.5
		local widthWorldZ = z + size * 0.5
		local heightWorldX = x - size * 0.5
		local heightWorldZ = z - size * 0.5

		DebugUtil.drawDebugAreaRectangle(startWorldX, 0, startWorldZ, widthWorldX, 0, widthWorldZ, heightWorldX, 0, heightWorldZ, true, 1, 0, 0)

		local fieldStatus = FSDensityMapUtil.getStatus(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

		DebugUtil.renderTable(0.1, 0.98, 0.012, fieldStatus, 0.1)
	end
end

function FieldManager:addField(field)
	table.insert(self.fields, field)
	field:setFieldId(#self.fields)
	field:addMapHotspot()
end

function FieldManager:getFieldByIndex(index)
	if index ~= nil then
		return self.fields[index]
	end

	return nil
end

function FieldManager:getFields()
	return self.fields
end

function FieldManager:getFruitModifier(fruitType)
	local modifiers = self.fruitModifiers[fruitType]

	if modifiers == nil then
		local fruitModifier = DensityMapModifier.new(fruitType.terrainDataPlaneId, fruitType.startStateChannel, fruitType.numStateChannels, self.mission.terrainRootNode)
		modifiers = {
			default = fruitModifier
		}
		local preparingOutputId = fruitType.terrainDataPlaneIdPreparing

		if preparingOutputId ~= nil then
			local preparing = DensityMapModifier.new(preparingOutputId, 0, 1, self.mission.terrainRootNode)
			modifiers.preparing = preparing
		end

		self.fruitModifiers = modifiers
	end

	return modifiers.default, modifiers.preparing
end

function FieldManager:findFieldFruit(field)
	if field.fieldMissionAllowed then
		local x, z = FieldUtil.getMeasurementPositionOfField(field)

		local function testFruit(fruitType)
			local minState = 0
			local maxState = 15
			local area, totalArea = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, FieldUtil.FILTER_EMPTY, FieldUtil.FILTER_EMPTY, fruitType, minState, maxState, 0, 0, 0, false)

			return area > 0.5 * totalArea
		end

		for _, fruitType in ipairs(self.availableFruitTypeIndices) do
			if testFruit(fruitType) then
				field.fruitType = fruitType

				break
			end
		end

		if testFruit(FruitType.GRASS) then
			field.fruitType = FruitType.GRASS
		end
	end
end

function FieldManager:findFieldSizes()
	local bitMapSize = 4096
	local terrainSize = getTerrainSize(self.mission.terrainRootNode)

	local function convertWorldToAccessPosition(x, z)
		return math.floor(bitMapSize * (x + terrainSize * 0.5) / terrainSize), math.floor(bitMapSize * (z + terrainSize * 0.5) / terrainSize)
	end

	local function pixelToHa(area)
		local pixelToSqm = terrainSize / bitMapSize

		return area * pixelToSqm * pixelToSqm / 10000
	end

	for _, field in pairs(self.fields) do
		local sumPixel = 0
		local bitVector = createBitVectorMap("field")

		loadBitVectorMapNew(bitVector, bitMapSize, bitMapSize, 1, true)

		for i = 0, getNumOfChildren(field.fieldDimensions) - 1 do
			local dimWidth = getChildAt(field.fieldDimensions, i)
			local dimStart = getChildAt(dimWidth, 0)
			local dimHeight = getChildAt(dimWidth, 1)
			local x0, _, z0 = getWorldTranslation(dimStart)
			local widthX, _, widthZ = getWorldTranslation(dimWidth)
			local heightX, _, heightZ = getWorldTranslation(dimHeight)
			local x, z = convertWorldToAccessPosition(x0, z0)
			widthX, widthZ = convertWorldToAccessPosition(widthX, widthZ)
			heightX, heightZ = convertWorldToAccessPosition(heightX, heightZ)
			sumPixel = sumPixel + setBitVectorMapParallelogram(bitVector, x, z, widthX - x, widthZ - z, heightX - x, heightZ - z, 0, 1, 0)
		end

		field.fieldArea = pixelToHa(sumPixel)

		delete(bitVector)
	end
end

function FieldManager:updateFieldOwnership()
	for _, field in ipairs(self.fields) do
		field:updateOwnership()
	end
end

function FieldManager:updateNPCField(field)
	local x, z = FieldUtil.getMeasurementPositionOfField(field)

	if field.fruitType ~= nil then
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(field.fruitType)

		if fruitDesc == nil then
			field.fruitType = nil

			return
		end

		local fertilizerFruit = fruitDesc.minHarvestingGrowthState == 0 and fruitDesc.maxHarvestingGrowthState == 0 and fruitDesc.cutState == 0
		local maxGrowthState = FieldUtil.getMaxGrowthState(field, field.fruitType)

		if field.maxKnownGrowthState == nil then
			field.maxKnownGrowthState = maxGrowthState
		elseif field.maxKnownGrowthState ~= maxGrowthState then
			field.maxKnownGrowthState = maxGrowthState

			g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_GROWING, true)
		end

		if fruitDesc.minHarvestingGrowthState <= maxGrowthState or fruitDesc.preparedGrowthState ~= -1 and maxGrowthState >= fruitDesc.minPreparingGrowthState + 1 and maxGrowthState <= fruitDesc.maxPreparingGrowthState then
			g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_GROWN)
		end

		if fertilizerFruit then
			if maxGrowthState == 2 then
				self.fieldStatusParametersToSet = {
					field,
					field.setFieldStatusPartitions,
					1,
					nil,
					FieldManager.FIELDSTATE_CULTIVATED,
					0,
					self.sprayLevelMaxValue,
					true
				}

				g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_CULTIVATED)
			end

			return
		end

		local witheredState = fruitDesc.witheredState

		if witheredState ~= nil then
			local area, totalArea = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, FieldUtil.FILTER_EMPTY, FieldUtil.FILTER_EMPTY, field.fruitType, witheredState, witheredState, 0, 0, 0, false)

			if area > 0.5 * totalArea then
				g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_WITHERED)

				local plowState = FieldUtil.getPlowFactor(field, true)

				if plowState == 0 then
					self.fieldStatusParametersToSet = {
						field,
						field.setFieldStatusPartitions,
						1,
						nil,
						FieldManager.FIELDSTATE_PLOWED,
						0,
						nil,
						false
					}

					g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_PLOWED)
				else
					self.fieldStatusParametersToSet = {
						field,
						field.setFieldStatusPartitions,
						1,
						nil,
						FieldManager.FIELDSTATE_CULTIVATED,
						0,
						nil,
						false
					}

					g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_CULTIVATED)
				end

				return
			end
		end

		local harvestReadyState = fruitDesc.maxHarvestingGrowthState

		if fruitDesc.maxPreparingGrowthState > -1 then
			harvestReadyState = fruitDesc.maxPreparingGrowthState
		end

		local maxHarvestState = FieldUtil.getMaxHarvestState(field, field.fruitType)

		if maxHarvestState == harvestReadyState then
			if math.random() < 0.95 then
				local plowState = fruitDesc.increasesSoilDensity and 0 or FieldUtil.getPlowFactor(field, true) * self.plowLevelMaxValue
				local limeState = fruitDesc.consumesLime and 0 or FieldUtil.getLimeFactor(field) * self.limeLevelMaxValue
				self.fieldStatusParametersToSet = {
					field,
					field.setFieldStatusPartitions,
					1,
					field.fruitType,
					FieldManager.FIELDSTATE_HARVESTED,
					fruitDesc.cutState,
					0,
					false,
					plowState,
					0,
					limeState
				}

				g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_HARVESTED)
			end

			return
		end

		local maxWeedState = FieldUtil.getMaxWeedState(field)

		if maxWeedState == 3 and math.random() < 0.75 then
			local replacements = g_currentMission.weedSystem:getWeederReplacements(false).weed.replacements
			self.fieldStatusParametersToSet = {
				field,
				field.setFieldStatusPartitions,
				1,
				field.fruitType,
				nil,
				nil,
				nil,
				true,
				[10] = replacements[maxWeedState] or 0
			}

			g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_WEEDED)

			return
		elseif maxWeedState > 3 and math.random() < 0.9 then
			local replacements = g_currentMission.weedSystem:getHerbicideReplacements().weed.replacements
			self.fieldStatusParametersToSet = {
				field,
				field.setFieldStatusPartitions,
				1,
				field.fruitType,
				nil,
				nil,
				nil,
				true,
				[10] = replacements[maxWeedState] or 0
			}

			g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_SPRAYED)

			return
		end

		local area, totalArea = FieldUtil.getFruitArea(x - 1, z - 1, x + 1, z - 1, x - 1, z + 1, FieldUtil.FILTER_EMPTY, FieldUtil.FILTER_EMPTY, field.fruitType, fruitDesc.cutState, fruitDesc.cutState, 0, 0, 0, false)

		if area > 0.5 * totalArea and g_currentMission.snowSystem.height < SnowSystem.MIN_LAYER_HEIGHT then
			local limeFactor = FieldUtil.getLimeFactor(field)

			if limeFactor == 0 and math.random() < 0.4 then
				self.fieldStatusParametersToSet = {
					field,
					field.setFieldStatusPartitions,
					1,
					field.fruitType,
					nil,
					nil,
					nil,
					true,
					[11] = self.limeLevelMaxValue
				}

				g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_LIMED)

				return
			elseif math.random() < 0.6 then
				field.stateIsKnown = false
				local plowState = FieldUtil.getPlowFactor(field, true)

				if plowState == 0 then
					self.fieldStatusParametersToSet = {
						field,
						field.setFieldStatusPartitions,
						1,
						nil,
						FieldManager.FIELDSTATE_PLOWED,
						0,
						nil,
						false
					}

					g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_PLOWED)
				else
					self.fieldStatusParametersToSet = {
						field,
						field.setFieldStatusPartitions,
						1,
						nil,
						FieldManager.FIELDSTATE_CULTIVATED,
						0,
						nil,
						false
					}

					g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_CULTIVATED)
				end

				return
			end
		end

		local sprayFactor = FieldUtil.getSprayFactor(field)

		if sprayFactor < 1 and math.random() < 0.6 then
			local newSprayValue = sprayFactor * self.sprayLevelMaxValue + 1
			self.fieldStatusParametersToSet = {
				field,
				field.setFieldStatusPartitions,
				1,
				field.fruitType,
				nil,
				nil,
				newSprayValue,
				true
			}

			g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_FERTILIZED)

			return
		end
	else
		local limeFactor = FieldUtil.getLimeFactor(field)

		if limeFactor == 0 and math.random() < 0.75 then
			self.fieldStatusParametersToSet = {
				field,
				field.setFieldStatusPartitions,
				1,
				field.fruitType,
				nil,
				nil,
				nil,
				true,
				[11] = self.limeLevelMaxValue
			}

			g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_LIMED)

			return
		end

		local fruitIndex = self:getFruitIndexForField(field)

		if fruitIndex ~= nil then
			local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
			self.fieldStatusParametersToSet = {
				field,
				field.setFieldStatusPartitions,
				1,
				fruitIndex,
				FieldManager.FIELDSTATE_GROWING,
				1,
				nil,
				false,
				[10] = fruitDesc.plantsWeed and 1 or 0
			}

			g_missionManager:validateMissionOnField(field, FieldManager.FIELDEVENT_SOWN)
		end
	end
end

function FieldManager:getFruitIndexForField(field)
	if field.plannedFruit == 0 then
		return nil
	end

	if not self:canPlantNow(field) then
		return nil
	end

	return field.plannedFruit
end

function FieldManager:canPlantNow(field)
	local fruitIndex = field.plannedFruit

	if fruitIndex == nil or fruitIndex == 0 then
		return false
	end

	local mission = self.mission

	return mission.growthSystem:canFruitBePlanted(fruitIndex, mission.environment.currentPeriod)
end

function FieldManager:generateFieldContents()
	for i = 1, #self.fields do
		local field = self.fields[i]
		field.plannedFruit = self:generatePlannedFruitForField(field)
	end
end

function FieldManager:generatePlannedFruitForField(field)
	if field.fieldGrassMission then
		return FruitType.GRASS
	else
		return self.availableFruitTypeIndices[math.random(1, self.fruitTypesCount)]
	end
end

function FieldManager:onFarmPropertyChanged(farmId)
	for _, field in ipairs(self.fields) do
		if g_farmlandManager:getFarmlandOwner(field.farmland.id) == farmId then
			field:setFieldOwned(farmId)
		end
	end
end

function FieldManager:onYearChanged()
	self:generateFieldContents()
end

function FieldManager:onPeriodChanged()
	self.lastHandledFieldIndex = 0
end

function FieldManager:onFarmlandStateChanged(farmlandId, farmId)
	local fields = self.farmlandIdFieldMapping[farmlandId]

	if fields ~= nil then
		for _, field in ipairs(fields) do
			if farmId == FarmlandManager.NO_OWNER_FARM_ID then
				field:activate()
				self:findFieldFruit(field)
			else
				field:deactivate()
			end
		end
	end
end

function FieldManager:setFieldPartitionStatus(field, fieldPartitions, fieldPartitionIndex, fruitIndex, fieldState, growthState, sprayState, setSpray, plowState, weedState, limeState)
	field.lastCheckedTime = nil
	field.fruitType = fruitIndex
	field.stateIsKnown = false
	local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)
	local state = growthState

	if state == nil and fruitType ~= nil then
		state = math.random(1, fruitType.maxHarvestingGrowthState)

		if fruitType.minPreparingGrowthState ~= -1 then
			state = math.random(1, fruitType.maxPreparingGrowthState)
		end
	end

	local mission = self.mission
	local partition = fieldPartitions[fieldPartitionIndex]

	if partition ~= nil then
		local x = partition.x0
		local z = partition.z0
		local widthX = partition.widthX
		local widthZ = partition.widthZ
		local heightX = partition.heightX
		local heightZ = partition.heightZ
		local x0 = x
		local z0 = z
		local x1 = x + widthX
		local z1 = z + widthZ
		local x2 = x + heightX
		local z2 = z + heightZ

		self.terrainHeightModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)
		self.terrainHeightModifier:executeSet(0)
		self.terrainHeightTypeModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)
		self.terrainHeightTypeModifier:executeSet(0)

		if fieldState == FieldManager.FIELDSTATE_CULTIVATED then
			FSDensityMapUtil.updateCultivatorArea(x0, z0, x1, z1, x2, z2, true, false, field.fieldAngle, nil)
			FSDensityMapUtil.eraseTireTrack(x0, z0, x1, z1, x2, z2)

			field.fruitType = nil
		elseif fieldState == FieldManager.FIELDSTATE_PLOWED then
			FSDensityMapUtil.updatePlowArea(x0, z0, x1, z1, x2, z2, true, false, field.fieldAngle)
			FSDensityMapUtil.eraseTireTrack(x0, z0, x1, z1, x2, z2)

			field.fruitType = nil
		elseif fieldState == FieldManager.FIELDSTATE_GROWING then
			local groundTypeValue = self.groundTypeSown

			if fruitType.groundTypeChangeGrowthState >= 0 and fruitType.groundTypeChangeGrowthState <= state then
				groundTypeValue = mission.fieldGroundSystem:getFieldGroundValue(fruitType.groundTypeChangeType)
			end

			self.angleModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)
			self.angleModifier:executeSet(field.fieldAngle)
			self.groundTypeModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)
			self.groundTypeModifier:executeSet(groundTypeValue)

			local fruitModifier, fruitModifierPreparing = self:getFruitModifier(fruitType)

			fruitModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)
			fruitModifier:executeSet(state)

			if fruitModifierPreparing ~= nil then
				fruitModifierPreparing:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)
				fruitModifierPreparing:executeSet(0)
			end
		elseif fieldState == FieldManager.FIELDSTATE_HARVESTED then
			state = fruitType.cutState

			self.angleModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)
			self.angleModifier:executeSet(field.fieldAngle)
			self.groundTypeModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)
			self.groundTypeModifier:executeSet(self.groundTypeSown)

			local fruitModifier, fruitModifierPreparing = self:getFruitModifier(fruitType)

			fruitModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)
			fruitModifier:executeSet(state)

			if fruitModifierPreparing ~= nil then
				fruitModifierPreparing:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)
				fruitModifierPreparing:executeSet(1)
			end
		end

		if sprayState ~= nil then
			if self.sprayLevelMaxValue < sprayState then
				sprayState = self.sprayLevelMaxValue
			end

			self.sprayLevelModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)
			self.sprayLevelModifier:executeSet(sprayState)
		end

		if plowState ~= nil then
			self.plowLevelModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)
			self.plowLevelModifier:executeSet(plowState)
		end

		if weedState ~= nil and self.weedModifier ~= nil then
			self.weedModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)
			self.weedModifier:executeSet(weedState)
		end

		if limeState ~= nil then
			self.limeLevelModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)
			self.limeLevelModifier:executeSet(limeState)
		end

		self.sprayTypeModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)

		if setSpray == true and sprayState ~= nil and sprayState > 0 then
			self.sprayTypeModifier:executeSet(self.sprayTypeFertilizer)
		elseif setSpray == true and limeState ~= nil then
			self.sprayTypeModifier:executeSet(self.sprayTypeLime)
		else
			self.sprayTypeModifier:executeSet(0, self.fieldFilter)
		end
	end
end

function FieldManager:setFieldGround(field, groundTypeState, angle, sprayTypeState, fertilizerState, plowingState, weedState, limeState, stubbleState, buyField, removeFoliage)
	if field == nil or field.fieldDimensions == nil then
		return false
	end

	if buyField and field.isActive then
		g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(field.farmland.id, 1, 0))
	end

	field.fruitType = nil
	angle = tonumber(angle) or 0
	sprayTypeState = tonumber(sprayTypeState) or 0
	local mission = self.mission
	local groundTypeValue = mission.fieldGroundSystem:getFieldGroundValue(groundTypeState)
	local numDimensions = getNumOfChildren(field.fieldDimensions)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(field.fieldDimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x, _, z = getWorldTranslation(dimStart)
		local x1, _, z1 = getWorldTranslation(dimWidth)
		local x2, _, z2 = getWorldTranslation(dimHeight)

		if removeFoliage then
			FSDensityMapUtil.updateDestroyCommonArea(x, z, x1, z1, x2, z2, true, false)
		end

		self.groundTypeModifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
		self.groundTypeModifier:executeSet(groundTypeValue)
		self.sprayTypeModifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
		self.sprayTypeModifier:executeSet(sprayTypeState)
		self.angleModifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
		self.angleModifier:executeSet(angle)
		self.sprayLevelModifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
		self.sprayLevelModifier:executeSet(fertilizerState)
		self.plowLevelModifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
		self.plowLevelModifier:executeSet(plowingState)
		self.limeLevelModifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
		self.limeLevelModifier:executeSet(limeState)
		self.stubbleShredModifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
		self.stubbleShredModifier:executeSet(stubbleState)

		if self.weedModifier ~= nil then
			self.weedModifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
			self.weedModifier:executeSet(weedState)
		end
	end

	return true
end

function FieldManager:setFieldFruit(field, fruitType, state, sprayTypeState, fertilizerState, plowingState, weedState, limeState, stubbleState)
	if field == nil or field.fieldDimensions == nil or fruitType == nil then
		return false
	end

	field.fruitType = fruitType.index

	if g_missionManager.fieldToMission[field.fieldId] ~= nil then
		g_missionManager:deleteMission(g_missionManager.fieldToMission[field.fieldId])
	end

	state = MathUtil.clamp(state, 0, 2^fruitType.numStateChannels - 1)
	local groundTypeValue = self.fieldGroundSystem:getFieldGroundValue(FieldGroundType.SOWN)

	if fruitType ~= nil and fruitType.groundTypeChangeGrowthState >= 0 and fruitType.groundTypeChangeGrowthState <= state then
		groundTypeValue = self.fieldGroundSystem:getFieldGroundValue(fruitType.groundTypeChangeType)
	end

	local fruitModifier, fruitPreparingModifier = self:getFruitModifier(fruitType)

	if state == fruitType.preparedGrowthState then
		fruitModifier = fruitPreparingModifier
		state = 1
	end

	local numDimensions = getNumOfChildren(field.fieldDimensions)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(field.fieldDimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x, _, z = getWorldTranslation(dimStart)
		local x1, _, z1 = getWorldTranslation(dimWidth)
		local x2, _, z2 = getWorldTranslation(dimHeight)
		local heightTypes = g_densityMapHeightManager:getFillTypeToDensityMapHeightTypes()

		for fillTypeIndex, _ in pairs(heightTypes) do
			DensityMapHeightUtil.removeFromGroundByArea(x, z, x1, z1, x2, z2, fillTypeIndex)
		end

		fruitModifier:setParallelogramWorldCoords(x, z, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
		fruitModifier:executeSet(state)
	end

	return self:setFieldGround(field, groundTypeValue, 0, sprayTypeState, fertilizerState, plowingState, weedState, limeState, stubbleState, false, false)
end

function FieldManager:consoleCommandSetFieldFruit(fieldIndex, fruitName, state, groundTypeName, sprayTypeState, fertilizerState, plowingState, weedState, limeState, stubbleState, setSpray, buyField)
	local mission = self.mission

	if (mission:getIsServer() or mission.isMasterUser) and mission:getIsClient() then
		fieldIndex = tonumber(fieldIndex)
		state = tonumber(state)
		sprayTypeState = Utils.getNoNil(tonumber(sprayTypeState), 0)
		fertilizerState = math.min(Utils.getNoNil(tonumber(fertilizerState), 0), self.sprayLevelMaxValue)
		plowingState = Utils.getNoNil(tonumber(plowingState), 0)
		weedState = Utils.getNoNil(tonumber(weedState), 0)
		limeState = Utils.getNoNil(tonumber(limeState), 0)
		stubbleState = Utils.getNoNil(tonumber(stubbleState), 0)
		buyField = tostring(buyField):lower() == "true"
		local usage = "Use gsFieldSetFruit fieldId fruitName [growthState] [groundTypeName] [sprayTypeState] [fertilizerState] [plowingState] [weedState] [limeState] [stubbleState] [setSpray] [buyField]"

		if fieldIndex == nil then
			return usage
		end

		local field = self:getFieldByIndex(fieldIndex)

		if field == nil then
			return "Error: Invalid Field-Index. " .. usage
		end

		local groundType = groundTypeName ~= nil and FieldGroundType.getByName(groundTypeName)

		if groundType == nil then
			local availableFieldGroundType = table.concatKeys(FieldGroundType.getAll(), ", ")

			return "Error: Invalid groundType.\nAvaiable types: " .. availableFieldGroundType .. "\n" .. usage
		end

		local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitName)

		if fruitType == nil then
			local availableFruitTypes = table.concatKeys(g_fruitTypeManager.nameToFruitType, " ")

			return "Error: Invalid fruitType.\nAvailable fruit types: " .. availableFruitTypes .. "\n" .. usage
		else
			state = state or fruitType.maxHarvestingGrowthState or 5
		end

		if field.fieldDimensions ~= nil then
			if buyField and field.isActive then
				g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(field.farmland.id, 1, 0))
				print("Info: Bought field farmland")
			end

			self:setFieldFruit(field, fruitType, state, sprayTypeState, fertilizerState, plowingState, weedState, limeState, stubbleState, setSpray)

			return "Updated field"
		end

		return "Error: Field not found"
	else
		return "Error: Command not allowed"
	end
end

function FieldManager:consoleCommandSetFieldFruitAll(fruitName, state, sprayTypeState, fertilizerState, plowingState, weedState, limeState, stubbleState, setSpray, buyField)
	local mission = self.mission

	if (mission:getIsServer() or mission.isMasterUser) and mission:getIsClient() then
		state = tonumber(state) or 5
		sprayTypeState = Utils.getNoNil(tonumber(sprayTypeState), 0)
		fertilizerState = math.min(Utils.getNoNil(tonumber(fertilizerState), 0), self.sprayLevelMaxValue)
		plowingState = Utils.getNoNil(tonumber(plowingState), 0)
		weedState = Utils.getNoNil(tonumber(weedState), 0)
		limeState = Utils.getNoNil(tonumber(limeState), 0)
		stubbleState = Utils.getNoNil(tonumber(stubbleState), 0)
		buyField = tostring(buyField):lower() == "true"
		local usage = "Use gsFieldSetFruitAll fruitName [growthState] [sprayTypeState] [fertilizerState] [plowingState] [weedState] [limeState] [stubbleState] [setSpray] [buyField]"
		local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitName)

		if fruitType == nil then
			local availableFruitTypes = table.concatKeys(g_fruitTypeManager.nameToFruitType, " ")

			return "Error: Invalid fruitType.\nAvailable fruit types: " .. availableFruitTypes .. "\n" .. usage
		end

		for _, field in ipairs(self.fields) do
			if field.fieldDimensions ~= nil then
				if buyField and field.isActive then
					g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(field.farmland.id, 1, 0))
					print("Info: Bought field farmland")
				end

				self:setFieldFruit(field, fruitType, state, sprayTypeState, fertilizerState, plowingState, weedState, limeState, stubbleState, setSpray)
			end
		end

		return "Updated field"
	else
		return "Error: Command not allowed"
	end
end

function FieldManager:consoleCommandSetFieldGround(fieldIndex, groundTypeName, angle, groundLayer, fertilizerState, plowingState, weedState, limeState, stubbleState, buyField, removeFoliage)
	local mission = self.mission

	if (mission:getIsServer() or mission.isMasterUser) and mission:getIsClient() then
		local groundTypes = FieldGroundType.getAll()
		local groundTypesStr = ""
		local shortcutType = nil

		for name, t in pairs(groundTypes) do
			if groundTypeName ~= nil and name:startsWith(groundTypeName:upper()) then
				shortcutType = t

				break
			end

			if groundTypesStr ~= "" then
				groundTypesStr = groundTypesStr .. " "
			end

			groundTypesStr = groundTypesStr .. name
		end

		local usage = "Use gsFieldSetGround fieldIndex groundTypeName[" .. groundTypesStr .. "] [angle] [groundLayer] [fertilizerState] [plowingState] [weedState] [limeState] [stubbleState] [buyField] [removeFoliage]"
		local groundType = groundTypeName ~= nil and FieldGroundType.getByName(groundTypeName) or shortcutType

		if groundType == nil then
			return "Invalid groundType. " .. usage
		end

		buyField = tostring(buyField):lower() == "true"
		fieldIndex = tonumber(fieldIndex)
		fertilizerState = tonumber(fertilizerState) or 0
		plowingState = tonumber(plowingState) or 0
		angle = tonumber(angle) or 0
		weedState = tonumber(weedState) or 0
		limeState = tonumber(limeState) or 0
		stubbleState = tonumber(stubbleState) or 0
		removeFoliage = tostring(removeFoliage):lower() ~= "false"
		local field = self:getFieldByIndex(fieldIndex)

		if field == nil then
			return "Invalid Field-Index. " .. usage
		end

		if self:setFieldGround(field, groundType, angle, groundLayer, fertilizerState, plowingState, weedState, limeState, stubbleState, buyField, removeFoliage) then
			return "Updated field"
		end

		return "Could not update field"
	end

	return "Fields are not activated"
end

function FieldManager:consoleCommandSetFieldGroundAll(groundTypeName, angle, groundLayer, fertilizerState, plowingState, weedState, limeState, stubbleState, buyFields, removeFoliage)
	local mission = self.mission

	if (mission:getIsServer() or mission.isMasterUser) and mission:getIsClient() then
		local groundTypes = FieldGroundType.getAll()
		local groundTypesStr = ""
		local shortcutType = nil

		for name, t in pairs(groundTypes) do
			if name:startsWith(groundTypeName:upper()) then
				shortcutType = t

				break
			end

			if groundTypesStr ~= "" then
				groundTypesStr = groundTypesStr .. " "
			end

			groundTypesStr = groundTypesStr .. name
		end

		local usage = "Use gsFieldSetGroundAll groundType[" .. groundTypesStr .. "] [angle] [groundLayer] [fertilizerState] [plowingState] [weedState] [limeState] [stubbleState] [buyFields] [removeFoliage]"
		local groundType = FieldGroundType.getByName(groundTypeName) or shortcutType

		if groundType == nil then
			return "Invalid groundType. " .. usage
		end

		buyFields = tostring(buyFields):lower() == "true"
		fertilizerState = tonumber(fertilizerState) or 0
		plowingState = tonumber(plowingState) or 0
		angle = tonumber(angle) or 0
		weedState = tonumber(weedState) or 0
		limeState = tonumber(limeState) or 0
		stubbleState = tonumber(stubbleState) or 0
		removeFoliage = tostring(removeFoliage):lower() ~= "false"

		for i, field in ipairs(self.fields) do
			self:setFieldGround(field, groundType, angle, groundLayer, fertilizerState, plowingState, weedState, limeState, stubbleState, buyFields, removeFoliage)
		end

		return "Updated fields"
	end

	return "Fields are not activated"
end

function FieldManager:consoleCommandToggleDebugFieldStatus(size)
	FieldManager.DEBUG_SHOW_FIELDSTATUS = not FieldManager.DEBUG_SHOW_FIELDSTATUS
	FieldManager.DEBUG_SHOW_FIELDSTATUS_SIZE = math.abs(Utils.getNoNil(tonumber(size), 10))

	if FieldManager.DEBUG_SHOW_FIELDSTATUS then
		g_currentMission:addDrawable(self)
	else
		g_currentMission:removeDrawable(self)
	end

	return "ToggleFieldStatus: " .. tostring(FieldManager.DEBUG_SHOW_FIELDSTATUS) .. " " .. tostring(FieldManager.DEBUG_SHOW_FIELDSTATUS_SIZE) .. "m"
end

g_fieldManager = FieldManager.new()
