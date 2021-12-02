HarvestMission = {
	REWARD_PER_HA_WIDE = 1500,
	REWARD_PER_HA_SMALL = 4800,
	FAILURE_COST_FACTOR = 0.1,
	FAILURE_COST_OF_TOTAL = 0.95,
	SUCCESS_FACTOR = 0.93
}
local HarvestMission_mt = Class(HarvestMission, AbstractFieldMission)

InitStaticObjectClass(HarvestMission, "HarvestMission", ObjectIds.MISSION_HARVEST)

function HarvestMission.new(isServer, isClient, customMt)
	local self = AbstractFieldMission.new(isServer, isClient, customMt or HarvestMission_mt)
	self.workAreaTypes = {
		[WorkAreaType.CUTTER] = true,
		[WorkAreaType.COMBINECHOPPER] = true,
		[WorkAreaType.COMBINESWATH] = true,
		[WorkAreaType.FRUITPREPARER] = true
	}
	self.reimbursementPerHa = 0
	self.lastSellChange = -1
	self.sellPointId = nil

	return self
end

function HarvestMission:delete()
	if self.sellPoint ~= nil then
		self.sellPoint.missions[self] = nil
	end

	HarvestMission:superClass().delete(self)
end

function HarvestMission:saveToXMLFile(xmlFile, key)
	HarvestMission:superClass().saveToXMLFile(self, xmlFile, key)

	local harvestKey = string.format("%s.harvest", key)
	local sellingPointPlaceable = self.sellPoint.owningPlaceable

	if sellingPointPlaceable == nil then
		local sellPointName = self.sellPoint.getName and self.sellPoint:getName() or "unknown"

		Logging.xmlWarning(xmlFile, "Unable to retrieve placeable of sellPoint '%s' for saving harvest mission '%s' ", sellPointName, key)

		return
	end

	local unloadingStationIndex = g_currentMission.storageSystem:getPlaceableUnloadingStationIndex(sellingPointPlaceable, self.sellPoint)

	if unloadingStationIndex == nil then
		local sellPointName = self.sellPoint.getName and self.sellPoint:getName() or sellingPointPlaceable.getName and sellingPointPlaceable:getName() or "unknown"

		Logging.xmlWarning(xmlFile, "Unable to retrieve unloading station index of sellPoint '%s' for saving harvest mission '%s' ", sellPointName, key)

		return
	end

	setXMLInt(xmlFile, harvestKey .. "#sellPointPlaceableId", sellingPointPlaceable.currentSavegameId)
	setXMLInt(xmlFile, harvestKey .. "#unloadingStationIndex", unloadingStationIndex)
	setXMLFloat(xmlFile, harvestKey .. "#expectedLiters", self.expectedLiters)
	setXMLFloat(xmlFile, harvestKey .. "#depositedLiters", self.depositedLiters)
end

function HarvestMission:loadFromXMLFile(xmlFile, key)
	if not HarvestMission:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end

	local harvestKey = key .. ".harvest(0)"
	local sellPointPlaceableId = getXMLInt(xmlFile, harvestKey .. "#sellPointPlaceableId")
	local unloadingStationIndex = getXMLInt(xmlFile, harvestKey .. "#unloadingStationIndex")

	if sellPointPlaceableId == nil then
		Logging.xmlError(xmlFile, "no sellPointPlaceable id given at '%s'", harvestKey)

		return false
	end

	if unloadingStationIndex == nil then
		Logging.xmlError(xmlFile, "no unloadting station index given at '%s'", harvestKey)

		return false
	end

	local placeable = g_currentMission.placeableSystem:getPlaceableBySavegameId(sellPointPlaceableId)

	if placeable == nil then
		Logging.xmlError(xmlFile, "selling station placeable with id '%d' not available at '%s'", sellPointPlaceableId, harvestKey)

		return false
	end

	local unloadingStation = g_currentMission.storageSystem:getPlaceableUnloadingStation(placeable, unloadingStationIndex)

	if unloadingStation == nil then
		Logging.xmlError(xmlFile, "unable to retrieve unloadingStation %d for placeable %s at '%s'", unloadingStationIndex, placeable.configFileName, harvestKey)

		return false
	end

	self.sellPoint = unloadingStation
	self.sellPoint.missions[self] = self
	self.expectedLiters = getXMLFloat(xmlFile, harvestKey .. "#expectedLiters")
	self.depositedLiters = getXMLFloat(xmlFile, harvestKey .. "#depositedLiters")
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.field.fruitType)

	if not fruitDesc then
		Logging.error("(missions.xml) Harvest mission has no fruit type.")

		return false
	end

	self.fillType = fruitDesc.fillType.index

	self:updateRewardPerHa()

	if self.status == AbstractMission.STATUS_RUNNING then
		self:createModifiers()
	end

	return true
end

function HarvestMission:writeStream(streamId, connection)
	HarvestMission:superClass().writeStream(self, streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.sellPoint)
	streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)
end

function HarvestMission:readStream(streamId, connection)
	HarvestMission:superClass().readStream(self, streamId, connection)

	self.sellPointId = NetworkUtil.readNodeObjectId(streamId)
	self.fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

	self:updateRewardPerHa()
end

function HarvestMission:init(field, ...)
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(field.fruitType)
	self.fillType = fruitDesc.fillType.index

	self:updateRewardPerHa()

	if not HarvestMission:superClass().init(self, field, ...) then
		return false
	end

	self.depositedLiters = 0
	self.expectedLiters = self:getMaxCutLiters()
	self.sellPoint = self:getHighestSellPointPrice()

	if self.sellPoint == nil then
		return false
	end

	return true
end

function HarvestMission:start(...)
	if not HarvestMission:superClass().start(self, ...) then
		return false
	end

	if self.sellPointId ~= nil then
		self:tryToResolveSellPoint()
	end

	if self.sellPoint == nil then
		return false
	end

	self.sellPoint.missions[self] = self

	self:createModifiers()

	return true
end

function HarvestMission:finish(success)
	HarvestMission:superClass().finish(self, success)

	self.sellPoint.missions[self] = nil
end

function HarvestMission:calculateStealingCost()
	if not self.success and self.isServer then
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.field.fruitType)
		local multiplier = self.mission:getHarvestScaleMultiplier(self.fruitType, self.sprayFactor, self.fieldPlowFactor, self.limeFactor, self.weedFactor, self.stubbleFactor, self.rollerFactor)
		local area = self.field.fieldArea * multiplier
		local harvestedArea = self.fieldPercentageDone * area
		local litersHarvested = fruitDesc.literPerSqm * harvestedArea * 10000
		litersHarvested = litersHarvested - self:getFruitInVehicles()
		local diff = litersHarvested - self.depositedLiters

		if diff > litersHarvested * HarvestMission.FAILURE_COST_FACTOR then
			local _, pricePerLiter = self:getHighestSellPointPrice()
			local farmReimbursement = diff * HarvestMission.FAILURE_COST_OF_TOTAL * pricePerLiter

			return farmReimbursement
		end
	end

	return 0
end

function HarvestMission:getFruitInVehicles()
	local totalLiters = 0

	for _, vehicle in pairs(self.vehicles) do
		if vehicle.spec_fillUnit ~= nil then
			for index, _ in pairs(vehicle:getFillUnits()) do
				local fillType = vehicle:getFillUnitFillType(index)

				if fillType == self.fillType then
					local level = vehicle:getFillUnitFillLevel(index)
					totalLiters = totalLiters + level
				end
			end
		end
	end

	return totalLiters
end

function HarvestMission:getHighestSellPointPrice()
	local highestPrice = 0
	local sellPoint = nil

	for _, unloadingStation in pairs(self.mission.storageSystem:getUnloadingStations()) do
		if unloadingStation.owningPlaceable ~= nil and unloadingStation.isSellingPoint and unloadingStation.acceptedFillTypes[self.fillType] then
			local price = unloadingStation:getEffectiveFillTypePrice(self.fillType)

			if highestPrice < price then
				highestPrice = price
				sellPoint = unloadingStation
			end
		end
	end

	return sellPoint, highestPrice
end

function HarvestMission:completeField()
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.field.fruitType)

	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, self.field.fruitType, FieldManager.FIELDSTATE_HARVESTED, fruitDesc.cutState, 0, false, self.fieldPlowFactor)
	end
end

function HarvestMission:fillSold(fillDelta)
	self.depositedLiters = math.min(self.depositedLiters + fillDelta, self.expectedLiters)
	local expected = self.expectedLiters * AbstractMission.SUCCESS_FACTOR

	if expected <= self.depositedLiters then
		self.sellPoint.missions[self] = nil
	end

	self.lastSellChange = 30
end

function HarvestMission:tryToResolveSellPoint()
	if self.sellPointId == nil then
		return
	end

	self.sellPoint = NetworkUtil.getObject(self.sellPointId)

	if self.sellPoint ~= nil then
		self.sellPointId = nil
	end
end

function HarvestMission:update(dt)
	HarvestMission:superClass().update(self, dt)

	if self.sellPointId ~= nil then
		self:tryToResolveSellPoint()
	end

	if g_currentMission.player.farmId == self.farmId and self.sellPoint ~= nil and not self:hasMapMarker() and self.status == AbstractMission.STATUS_RUNNING then
		self:createMapMarkerAtSellingStation(self.sellPoint)
	end

	if self.lastSellChange > 0 then
		self.lastSellChange = self.lastSellChange - 1

		if self.lastSellChange == 0 then
			local expected = self.expectedLiters * AbstractMission.SUCCESS_FACTOR
			local percentage = math.floor(self.depositedLiters / expected * 100)

			self.mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("fieldJob_progress_transporting_forField"), percentage, self.field.fieldId))
		end
	end
end

function HarvestMission:getVehicleVariant()
	local fruitType = self.field.fruitType

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

function HarvestMission:updateRewardPerHa()
	if self.fillType == FillType.SUGARCANE or self.fillType == FillType.POTATO or self.fillType == FillType.SUGARBEET then
		self.rewardPerHa = HarvestMission.REWARD_PER_HA_SMALL
	else
		self.rewardPerHa = HarvestMission.REWARD_PER_HA_WIDE
	end
end

function HarvestMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState, stubbleFactor, rollerFactor)
	local fruitType = field.fruitType
	local maxGrowthState = FieldUtil.getMaxHarvestState(field, fruitType)

	if maxGrowthState == nil then
		return false
	end

	if fruitType == FruitType.COTTON and field.fieldArea < 0.4 then
		return false
	end

	return true, FieldManager.FIELDSTATE_GROWING, maxGrowthState
end

function HarvestMission:getData()
	if self.sellPointId ~= nil then
		self:tryToResolveSellPoint()
	end

	local name = "Unknown"

	if self.sellPoint ~= nil then
		name = self.sellPoint:getName()
	end

	return {
		location = string.format(g_i18n:getText("fieldJob_number"), self.field.fieldId),
		jobType = g_i18n:getText("fieldJob_jobType_harvesting"),
		action = g_i18n:getText("fieldJob_desc_action_harvesting"),
		description = string.format(g_i18n:getText("fieldJob_desc_harvesting"), g_fillTypeManager:getFillTypeByIndex(self.fillType).title, self.field.fieldId, name)
	}
end

function HarvestMission:getCompletion()
	local sellCompletion = self.depositedLiters / self.expectedLiters / HarvestMission.SUCCESS_FACTOR
	local fieldCompletion = self:getFieldCompletion()
	local harvestCompletion = fieldCompletion / AbstractMission.SUCCESS_FACTOR

	return math.min(1, 0.8 * harvestCompletion + 0.2 * sellCompletion)
end

function HarvestMission:getExtraProgressText()
	if self.completion >= 0.1 then
		local title = "Unknown"

		if self.sellPointId ~= nil then
			self:tryToResolveSellPoint()
		end

		if self.sellPoint ~= nil then
			title = self.sellPoint:getName()
		end

		return string.format(g_i18n:getText("fieldJob_progress_harvesting_nextUnloadDesc"), g_fillTypeManager:getFillTypeByIndex(self.fillType).title, title)
	else
		return ""
	end
end

function HarvestMission:createModifiers()
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.field.fruitType)

	if fruitDesc ~= nil and fruitDesc.terrainDataPlaneId ~= nil then
		self.completionModifier = DensityMapModifier.new(fruitDesc.terrainDataPlaneId, fruitDesc.startStateChannel, fruitDesc.numStateChannels, self.mission.terrainRootNode)
		self.completionFilter = DensityMapFilter.new(self.completionModifier)

		self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, fruitDesc.cutState)
	end
end

function HarvestMission:partitionCompletion(x, z, widthX, widthZ, heightX, heightZ)
	self.completionModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)

	local _, area, totalArea = self.completionModifier:executeGet(self.completionFilter)

	return area, totalArea
end

function HarvestMission:validate(event)
	return event ~= FieldManager.FIELDEVENT_HARVESTED and event ~= FieldManager.FIELDEVENT_WITHERED and event ~= FieldManager.FIELDEVENT_CULTIVATED
end

g_missionManager:registerMissionType(HarvestMission, "harvest")
