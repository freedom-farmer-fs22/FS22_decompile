BaleMission = {
	REWARD_PER_HA_HAY = 3000,
	REWARD_PER_HA_SILAGE = 3300,
	SILAGE_VARIANT_CHANCE = 0.5,
	FILL_SUCCESS_FACTOR = 0.8,
	REWARD_PER_METER = 5
}
local BaleMission_mt = Class(BaleMission, AbstractFieldMission)

InitStaticObjectClass(BaleMission, "BaleMission", ObjectIds.MISSION_BALE)

function BaleMission.new(isServer, isClient, customMt)
	local self = AbstractFieldMission.new(isServer, isClient, customMt or BaleMission_mt)
	self.workAreaTypes = {
		[WorkAreaType.MOWER] = true,
		[WorkAreaType.BALER] = true,
		[WorkAreaType.TEDDER] = true,
		[WorkAreaType.WINDROWER] = true,
		[WorkAreaType.AUXILIARY] = true
	}
	self.reimbursementPerHa = 0
	self.lastSellChange = -1
	self.sellPointId = nil
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.GRASS)
	self.completionModifier = DensityMapModifier.new(fruitDesc.terrainDataPlaneId, fruitDesc.startStateChannel, fruitDesc.numStateChannels, self.mission.terrainRootNode)
	self.completionFilter = DensityMapFilter.new(self.completionModifier)

	self.completionFilter:setValueCompareParams(DensityValueCompareType.EQUAL, fruitDesc.cutState)

	return self
end

function BaleMission:delete()
	if self.sellPoint ~= nil then
		self.sellPoint.missions[self] = nil
	end

	BaleMission:superClass().delete(self)
end

function BaleMission:saveToXMLFile(xmlFile, key)
	BaleMission:superClass().saveToXMLFile(self, xmlFile, key)

	local baleKey = string.format("%s.bale", key)
	local sellingPointPlaceable = self.sellPoint.owningPlaceable
	local unloadingStationIndex = g_currentMission.storageSystem:getPlaceableUnloadingStationIndex(sellingPointPlaceable, self.sellPoint)

	if unloadingStationIndex ~= nil then
		setXMLInt(xmlFile, baleKey .. "#sellPointPlaceableId", sellingPointPlaceable.currentSavegameId)
		setXMLInt(xmlFile, baleKey .. "#unloadingStationIndex", unloadingStationIndex)
		setXMLString(xmlFile, baleKey .. "#fillTypeName", g_fillTypeManager:getFillTypeNameByIndex(self.fillType))
		setXMLFloat(xmlFile, baleKey .. "#depositedLiters", self.depositedLiters)
	else
		Logging.xmlWarning(xmlFile, "Unable to retrieve unloading station index for saving bale mission '%s'", key)
	end
end

function BaleMission:loadFromXMLFile(xmlFile, key)
	if not BaleMission:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end

	local baleKey = key .. ".bale(0)"
	local sellPointPlaceableId = getXMLInt(xmlFile, baleKey .. "#sellPointPlaceableId")
	local unloadingStationIndex = getXMLInt(xmlFile, baleKey .. "#unloadingStationIndex")

	if sellPointPlaceableId == nil then
		Logging.xmlError(xmlFile, "no sellPointPlaceable id given at '%s'", baleKey)

		return false
	end

	if unloadingStationIndex == nil then
		Logging.xmlError(xmlFile, "no unloadting station index given at '%s'", baleKey)

		return false
	end

	local placeable = g_currentMission.placeableSystem:getPlaceableBySavegameId(sellPointPlaceableId)

	if placeable == nil then
		Logging.xmlError(xmlFile, "selling station placeable with id '%d' not available at '%s'", sellPointPlaceableId, baleKey)

		return false
	end

	local unloadingStation = g_currentMission.storageSystem:getPlaceableUnloadingStation(placeable, unloadingStationIndex)

	if unloadingStation == nil then
		Logging.xmlError(xmlFile, "Unable to retrieve unloadingStation %d for placeable %s at '%s'", unloadingStationIndex, placeable.configFileName, baleKey)

		return false
	end

	self.sellPoint = unloadingStation
	self.sellPoint.missions[self] = self
	local fillTypeName = getXMLString(xmlFile, baleKey .. "#fillTypeName")
	self.fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

	self:updateRewardPerHa()

	self.depositedLiters = getXMLFloat(xmlFile, baleKey .. "#depositedLiters")
	self.expectedLiters = self:roundToWholeBales(self:getMaxCutLiters())

	if self.fillType == FillType.SILAGE then
		self.workAreaTypes[WorkAreaType.TEDDER] = false
	end

	return true
end

function BaleMission:writeStream(streamId, connection)
	BaleMission:superClass().writeStream(self, streamId, connection)
	NetworkUtil.writeNodeObject(streamId, self.sellPoint)
	streamWriteUIntN(streamId, self.fillType, FillTypeManager.SEND_NUM_BITS)
end

function BaleMission:readStream(streamId, connection)
	BaleMission:superClass().readStream(self, streamId, connection)

	self.sellPointId = NetworkUtil.readNodeObjectId(streamId)
	self.fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

	self:updateRewardPerHa()
end

function BaleMission:init(...)
	if math.random() < BaleMission.SILAGE_VARIANT_CHANCE then
		self.fillType = FillType.SILAGE
		self.workAreaTypes[WorkAreaType.TEDDER] = false
	else
		self.fillType = FillType.DRYGRASS_WINDROW
	end

	self:updateRewardPerHa()

	if not BaleMission:superClass().init(self, ...) then
		return false
	end

	self.depositedLiters = 0
	self.expectedLiters = self:roundToWholeBales(self:getMaxCutLiters())
	local highestPrice = 0

	for _, unloadingStation in pairs(self.mission.storageSystem:getUnloadingStations()) do
		if unloadingStation.owningPlaceable ~= nil and unloadingStation:isa(SellingStation) and unloadingStation.acceptedFillTypes[self.fillType] == true then
			local price = unloadingStation:getEffectiveFillTypePrice(self.fillType)

			if highestPrice < price then
				highestPrice = price
				self.sellPoint = unloadingStation
			end
		end
	end

	if self.sellPoint == nil then
		return false
	end

	self:updateRewardPerHa()

	self.reward = self:calculateReward()

	return true
end

function BaleMission:getIsAvailable()
	local environment = g_currentMission.environment

	if environment ~= nil and environment.currentSeason == Environment.SEASON.WINTER then
		return false
	end

	return BaleMission:superClass().getIsAvailable(self)
end

function BaleMission.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState, stubbleFactor, rollerFactor)
	local fruitType = FruitType.GRASS
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
	local maxGrowthState = FieldUtil.getMaxHarvestState(field, fruitType)
	local environment = g_currentMission.environment

	if environment ~= nil and environment.currentSeason == Environment.SEASON.WINTER then
		return false
	end

	if maxGrowthState == fruitDesc.maxHarvestingGrowthState then
		return true, FieldManager.FIELDSTATE_GROWING, maxGrowthState
	end

	return false
end

function BaleMission:start(...)
	if not BaleMission:superClass().start(self, ...) then
		return false
	end

	if self.sellPointId ~= nil then
		self:tryToResolveSellPoint()
	end

	if self.sellPoint == nil then
		return false
	end

	self.sellPoint.missions[self] = self

	return true
end

function BaleMission:completeField()
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.field.fruitType)

	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, self.field.fruitType, FieldManager.FIELDSTATE_GROWING, fruitDesc.cutState + 1, 0, false, self.fieldPlowFactor)
	end
end

function BaleMission:fillSold(fillDelta)
	self.depositedLiters = math.min(self.depositedLiters + fillDelta, self.expectedLiters)
	local expected = self.expectedLiters * BaleMission.FILL_SUCCESS_FACTOR

	if expected <= self.depositedLiters then
		self.sellPoint.missions[self] = nil
	end

	self.lastSellChange = 30
end

function BaleMission:tryToResolveSellPoint()
	if self.sellPointId == nil then
		return
	end

	self.sellPoint = NetworkUtil.getObject(self.sellPointId)

	if self.sellPoint ~= nil then
		self.sellPointId = nil
	end
end

function BaleMission:update(dt)
	BaleMission:superClass().update(self, dt)

	if self.sellPointId ~= nil then
		self:tryToResolveSellPoint()
	end

	if g_currentMission.player.farmId == self.farmId and self.isClient and self.status == AbstractMission.STATUS_RUNNING and not self:hasMapMarker() then
		self:createMapMarkerAtSellingStation(self.sellPoint)
	end

	if self.lastSellChange > 0 then
		self.lastSellChange = self.lastSellChange - 1

		if self.lastSellChange == 0 then
			local expected = self.expectedLiters * BaleMission.FILL_SUCCESS_FACTOR
			local percentage = math.floor(self.depositedLiters / expected * 100)

			self.mission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("fieldJob_progress_transporting_forField"), percentage, self.field.fieldId))
		end
	end
end

local BALE_SIZES = {
	3500,
	5500,
	7500,
	5000,
	6000,
	6500
}

function BaleMission:roundToWholeBales(liters)
	local minBales = math.huge
	local minBaleIndex = 1

	for i = 1, #BALE_SIZES do
		local bales = math.floor(liters / BALE_SIZES[i])

		if bales < minBales then
			minBales = bales
			minBaleIndex = i
		end
	end

	return minBales * BALE_SIZES[minBaleIndex]
end

function BaleMission:updateRewardPerHa()
	if self.fillType == FillType.SILAGE then
		self.rewardPerHa = BaleMission.REWARD_PER_HA_SILAGE
	else
		self.rewardPerHa = BaleMission.REWARD_PER_HA_HAY
	end
end

function BaleMission:calculateReward()
	local driveReward = 0

	if self.sellPoint ~= nil then
		local distance = calcDistanceFrom(self.field.rootNode, self.sellPoint.rootNode)
		driveReward = BaleMission.REWARD_PER_METER * distance
	end

	return self:superClass().calculateReward(self) + driveReward
end

function BaleMission:getVehicleVariant()
	if self.fillType == FillType.SILAGE then
		return "SILAGE"
	else
		return "HAY"
	end
end

function BaleMission:getData()
	if self.sellPointId ~= nil then
		self:tryToResolveSellPoint()
	end

	local l10nString = nil

	if self.fillType == FillType.SILAGE then
		l10nString = "fieldJob_desc_baling_silage"
	else
		l10nString = "fieldJob_desc_baling_hay"
	end

	return {
		location = string.format(g_i18n:getText("fieldJob_number"), self.field.fieldId),
		jobType = g_i18n:getText("fieldJob_jobType_baling"),
		action = g_i18n:getText("fieldJob_desc_action_baling"),
		description = string.format(g_i18n:getText(l10nString), self.field.fieldId, self.sellPoint:getName())
	}
end

function BaleMission:getCompletion()
	local transportCompletion = math.min(1, self.depositedLiters / self.expectedLiters / BaleMission.FILL_SUCCESS_FACTOR)
	local fieldCompletion = self:getFieldCompletion()
	local mowCompletion = math.min(1, fieldCompletion / AbstractMission.SUCCESS_FACTOR)

	return math.min(1, 0.2 * mowCompletion + 0.8 * transportCompletion)
end

function BaleMission:partitionCompletion(x, z, widthX, widthZ, heightX, heightZ)
	self.completionModifier:setParallelogramWorldCoords(x, z, widthX, widthZ, heightX, heightZ, DensityCoordType.POINT_VECTOR_VECTOR)

	local _, area, totalArea = self.completionModifier:executeGet(self.completionFilter)

	return area, totalArea
end

function BaleMission:validate(event)
	return event ~= FieldManager.FIELDEVENT_HARVESTED
end

g_missionManager:registerMissionType(BaleMission, "mow_bale", MissionManager.CATEGORY_GRASS_FIELD)
