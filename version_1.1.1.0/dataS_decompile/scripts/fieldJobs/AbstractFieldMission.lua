AbstractFieldMission = {}
local AbstractFieldMission_mt = Class(AbstractFieldMission, AbstractMission)

InitStaticObjectClass(AbstractFieldMission, "AbstractFieldMission", ObjectIds.MISSION_FIELD)

AbstractFieldMission.REWARD_PER_HA = 800
AbstractFieldMission.VEHICLE_USE_COST = 200
AbstractFieldMission.REIMBURSEMENT_FACTOR = 0.95
AbstractFieldMission.FIELD_SIZE_MEDIUM = 1.5
AbstractFieldMission.FIELD_SIZE_LARGE = 5

function AbstractFieldMission.new(isServer, isClient, customMt)
	local self = AbstractMission.new(isServer, isClient, customMt or AbstractFieldMission_mt)
	self.workAreaTypes = {}
	self.vehicles = {}
	self.moneyMultiplier = 1
	self.isInMissionMap = false
	self.fieldPercentageDone = 0
	self.mission = g_currentMission
	self.sprayLevelMaxValue = self.mission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)
	self.plowLevelMaxValue = self.mission.fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
	self.limeLevelMaxValue = self.mission.fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL)

	return self
end

function AbstractFieldMission:delete()
	if self.isInMissionMap then
		g_missionManager:removeMissionFromMissionMap(self)
	end

	if self.field ~= nil then
		self.field:setMissionActive(false)
	end

	self:destroyMapMarker()
	self:removeAccess()
	g_messageCenter:unsubscribeAll(self)
	AbstractFieldMission:superClass().delete(self)

	self.mission = nil
end

function AbstractFieldMission:saveToXMLFile(xmlFile, key)
	AbstractFieldMission:superClass().saveToXMLFile(self, xmlFile, key)

	local fieldKey = string.format("%s.field", key)

	setXMLInt(xmlFile, fieldKey .. "#id", self.field.fieldId)
	setXMLFloat(xmlFile, fieldKey .. "#sprayFactor", self.sprayFactor)
	setXMLBool(xmlFile, fieldKey .. "#spraySet", self.fieldSpraySet)
	setXMLFloat(xmlFile, fieldKey .. "#plowFactor", self.fieldPlowFactor)
	setXMLInt(xmlFile, fieldKey .. "#state", self.fieldState)
	setXMLInt(xmlFile, fieldKey .. "#vehicleGroup", self.vehicleGroupIdentifier)

	if self.vehicleUseCost ~= nil then
		setXMLFloat(xmlFile, fieldKey .. "#vehicleUseCost", self.vehicleUseCost)
	end

	if self.spawnedVehicles ~= nil then
		setXMLBool(xmlFile, fieldKey .. "#spawnedVehicles", self.spawnedVehicles)
	end

	if self.growthState ~= nil then
		setXMLInt(xmlFile, fieldKey .. "#growthState", self.growthState)
	end

	setXMLFloat(xmlFile, fieldKey .. "#limeFactor", self.limeFactor)
	setXMLFloat(xmlFile, fieldKey .. "#weedFactor", self.weedFactor)
	setXMLFloat(xmlFile, fieldKey .. "#stubbleFactor", self.stubbleFactor)

	if self.weedState ~= nil then
		setXMLInt(xmlFile, fieldKey .. "#weedState", self.weedState)
	end

	if self.field.fruitType ~= nil and self.field.fruitType ~= 0 then
		local fruitName = g_fruitTypeManager:getFruitTypeNameByIndex(self.field.fruitType)

		setXMLString(xmlFile, fieldKey .. "#fruitTypeName", fruitName)
	end
end

function AbstractFieldMission:loadFromXMLFile(xmlFile, key)
	if not AbstractFieldMission:superClass().loadFromXMLFile(self, xmlFile, key) then
		return false
	end

	local fieldKey = key .. ".field(0)"
	local fieldId = getXMLInt(xmlFile, fieldKey .. "#id")
	self.field = g_fieldManager:getFieldByIndex(fieldId)

	if self.field == nil then
		Logging.error("(missions.xml) Mission field is not available.")

		return false
	end

	self.sprayFactor = getXMLFloat(xmlFile, fieldKey .. "#sprayFactor")
	self.fieldSpraySet = getXMLBool(xmlFile, fieldKey .. "#spraySet")
	self.fieldPlowFactor = getXMLFloat(xmlFile, fieldKey .. "#plowFactor")
	self.fieldState = getXMLInt(xmlFile, fieldKey .. "#state")
	self.growthState = getXMLInt(xmlFile, fieldKey .. "#growthState")
	self.limeFactor = getXMLFloat(xmlFile, fieldKey .. "#limeFactor")
	self.weedFactor = getXMLFloat(xmlFile, fieldKey .. "#weedFactor")
	self.stubbleFactor = getXMLFloat(xmlFile, fieldKey .. "#stubbleFactor") or 1
	self.rollerFactor = getXMLFloat(xmlFile, fieldKey .. "#rollerFactor") or 1
	self.weedState = getXMLInt(xmlFile, fieldKey .. "#weedState")
	self.vehicleGroupIdentifier = getXMLInt(xmlFile, fieldKey .. "#vehicleGroup")
	self.vehicleUseCost = getXMLFloat(xmlFile, fieldKey .. "#vehicleUseCost")
	self.spawnedVehicles = Utils.getNoNil(getXMLBool(xmlFile, fieldKey .. "#spawnedVehicles"), false)
	self.vehiclesToLoad = self:getVehicleGroupFromIdentifier(self.vehicleGroupIdentifier)
	local name = getXMLString(xmlFile, fieldKey .. "#fruitTypeName")

	if name ~= nil and self.status == AbstractMission.STATUS_RUNNING then
		local fruitType = g_fruitTypeManager:getFruitTypeByName(name)
		self.field.fruitType = fruitType.index
	end

	if self.status == AbstractMission.STATUS_RUNNING then
		self.field.currentMission = self

		self:addToMissionMap()
		g_messageCenter:subscribe(MessageType.VEHICLE_RESET, self.onVehicleReset, self)
	end

	return true
end

function AbstractFieldMission:writeStream(streamId, connection)
	AbstractFieldMission:superClass().writeStream(self, streamId, connection)
	streamWriteInt32(streamId, self.field.fieldId)
	streamWriteFloat32(streamId, self.vehicleUseCost)
	streamWriteInt32(streamId, self.vehicleGroupIdentifier)
	streamWriteBool(streamId, self.spawnedVehicles or false)
end

function AbstractFieldMission:readStream(streamId, connection)
	AbstractFieldMission:superClass().readStream(self, streamId, connection)

	local fieldId = streamReadInt32(streamId)
	self.field = g_fieldManager:getFieldByIndex(fieldId)
	self.vehicleUseCost = streamReadFloat32(streamId)
	self.vehicleGroupIdentifier = streamReadInt32(streamId)
	self.vehiclesToLoad = self:getVehicleGroupFromIdentifier(self.vehicleGroupIdentifier)
	self.spawnedVehicles = streamReadBool(streamId)

	if self.status == AbstractMission.STATUS_RUNNING then
		self:addToMissionMap()
	end
end

function AbstractFieldMission:init(field, sprayFactor, fieldSpraySet, fieldPlowFactor, fieldState, growthState, limeFactor, weedFactor, weedState, stubbleFactor, rollerFactor)
	if not AbstractFieldMission:superClass().init(self) then
		return false
	end

	self.field = field
	self.sprayFactor = sprayFactor
	self.fieldSpraySet = fieldSpraySet
	self.fieldPlowFactor = fieldPlowFactor
	self.fieldState = fieldState
	self.growthState = growthState
	self.limeFactor = limeFactor
	self.weedFactor = weedFactor
	self.weedState = weedState
	self.stubbleFactor = stubbleFactor
	self.rollerFactor = rollerFactor
	self.vehiclesToLoad, self.vehicleGroupIdentifier = self:getVehicleGroup()

	if self.vehicleGroupIdentifier ~= nil then
		self.vehicleUseCost = self:calculateVehicleUseCost()
	end

	self.reward = self:calculateReward()

	return true
end

function AbstractFieldMission:update(dt)
	AbstractFieldMission:superClass().update(self, dt)

	if self.vehicleIndexToLoadNext ~= nil and self.lastVehicleIndexToLoad == self.vehicleIndexToLoadNext then
		if self.vehicleLoadWaitFrameCounter == nil then
			self.vehicleIndexToLoadNext = self.vehicleIndexToLoadNext + 1

			if self.vehicleIndexToLoadNext <= table.getn(self.vehiclesToLoad) and not self:loadNextVehicle() then
				Logging.error("Failed to load all vehicles: no space at spawn point")

				self.vehicleIndexToLoadNext = nil
			end
		else
			self.vehicleLoadWaitFrameCounter = self.vehicleLoadWaitFrameCounter - 1

			if self.vehicleLoadWaitFrameCounter == 0 then
				self.vehicleLoadWaitFrameCounter = nil
			end
		end
	end
end

function AbstractFieldMission:start(spawnVehicles)
	if not AbstractFieldMission:superClass().start(self, spawnVehicles) then
		return false
	end

	if self.isServer then
		if spawnVehicles and self.vehiclesToLoad ~= nil then
			self.spawnedVehicles = true
			self.lastVehicleIndexToLoad = 0
			self.vehicleIndexToLoadNext = 0
		end

		self.field.currentMission = self

		self:resetField()
	end

	self:addToMissionMap()

	if g_currentMission.player.farmId == self.farmId then
		self.field:setMissionActive(true)
	end

	g_messageCenter:subscribe(MessageType.VEHICLE_RESET, self.onVehicleReset, self)

	return true
end

function AbstractFieldMission:started()
	if self.isClient then
		self:addToMissionMap()

		if g_currentMission.player.farmId == self.farmId then
			self.field:setMissionActive(true)
		end
	end
end

function AbstractFieldMission:finish(success)
	AbstractFieldMission:superClass().finish(self, success)

	self.success = success

	self:destroyMapMarker()

	if g_currentMission:getIsServer() then
		if success then
			g_farmManager:getFarmById(self.farmId).stats:updateFieldJobsDone(self.field.farmland.npcIndex)

			local npc = g_npcManager:getNPCByIndex(self.field.farmland.npcIndex)
			npc.finishedMissions = npc.finishedMissions + 1
		else
			self:resetField()
		end
	end

	if not success then
		self:removeAccess()
	end

	if g_currentMission:getFarmId() == self.farmId then
		if success then
			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format(g_i18n:getText("fieldJob_finishedField"), self.field.fieldId))
		else
			g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format(g_i18n:getText("fieldJob_failedField"), self.field.fieldId))
		end
	end
end

function AbstractFieldMission:dismiss()
	if #self.vehicles > 0 then
		self.reward = self.reward - self.vehicleUseCost + self:calculateReimbursement()
	end

	if self.success then
		self:removeAccess()
		self:completeField()
	end

	self.field.currentMission = nil

	AbstractFieldMission:superClass().dismiss(self)
end

function AbstractFieldMission:removeAccess()
	if self.isInMissionMap then
		g_missionManager:removeMissionFromMissionMap(self)

		self.isInMissionMap = false
	end

	if self.isServer then
		for _, vehicle in ipairs(self.vehicles) do
			g_currentMission:removeVehicle(vehicle)
		end

		self.vehicles = {}
	end
end

function AbstractFieldMission:hasLeasableVehicles()
	return self.vehiclesToLoad ~= nil
end

function AbstractFieldMission:hasField()
	return true
end

function AbstractFieldMission:resetField()
	for i = 1, table.getn(self.field.maxFieldStatusPartitions) do
		g_fieldManager:setFieldPartitionStatus(self.field, self.field.maxFieldStatusPartitions, i, self.field.fruitType, self.fieldState, self.growthState, self.sprayFactor * self.sprayLevelMaxValue, self.fieldSpraySet, self.fieldPlowFactor * self.plowLevelMaxValue, self.weedState, self.limeFactor * self.limeLevelMaxValue)
	end
end

function AbstractFieldMission:completeField()
end

function AbstractFieldMission:getCompletion()
	local fieldCompletion = self:getFieldCompletion()

	return fieldCompletion / AbstractMission.SUCCESS_FACTOR
end

function AbstractFieldMission:getFieldCompletion()
	self.fieldPercentageDone = 0

	if self.currentFieldJobPartitionIndex == nil then
		self.currentFieldJobPartitionIndex = 1
		local numPartitions = table.getn(self.field.getFieldStatusPartitions)

		for i = 1, numPartitions do
			self.field.getFieldStatusPartitions[i].percentage = 0
		end
	else
		local partition = self.field.getFieldStatusPartitions[self.currentFieldJobPartitionIndex]

		if partition ~= nil then
			local area, totalArea = self:partitionCompletion(partition.x0, partition.z0, partition.widthX, partition.widthZ, partition.heightX, partition.heightZ)

			if area == nil then
				return 0
			end

			partition.percentage = area / totalArea
		else
			g_missionManager:deleteMission(self)
		end

		local totalPercentage = 0
		local numPartitions = table.getn(self.field.getFieldStatusPartitions)

		for i = 1, numPartitions do
			totalPercentage = totalPercentage + self.field.getFieldStatusPartitions[i].percentage
		end

		self.fieldPercentageDone = totalPercentage / numPartitions
		self.currentFieldJobPartitionIndex = self.currentFieldJobPartitionIndex + 1

		if numPartitions < self.currentFieldJobPartitionIndex then
			self.currentFieldJobPartitionIndex = 1
		end
	end

	return self.fieldPercentageDone
end

function AbstractFieldMission:getFieldSize()
	local fieldSize = "small"

	if AbstractFieldMission.FIELD_SIZE_LARGE < self.field.fieldArea then
		fieldSize = "large"
	elseif AbstractFieldMission.FIELD_SIZE_MEDIUM < self.field.fieldArea then
		fieldSize = "medium"
	end

	return fieldSize
end

function AbstractFieldMission:getVehicleGroup()
	return g_missionManager:getRandomVehicleGroup(self.type.name, self:getFieldSize(), self:getVehicleVariant())
end

function AbstractFieldMission:getVehicleVariant()
	return nil
end

function AbstractFieldMission:getVehicleGroupFromIdentifier(identifier)
	return g_missionManager:getVehicleGroupFromIdentifier(self.type.name, self:getFieldSize(), identifier)
end

function AbstractFieldMission:onVehicleReset(oldVehicle, newVehicle)
	if oldVehicle.activeMissionId == self.activeMissionId then
		newVehicle.activeMissionId = self.activeMissionId

		table.removeElement(self.vehicles, oldVehicle)
		table.insert(self.vehicles, newVehicle)
	end
end

function AbstractFieldMission:calculateReward()
	local fruitMultiplier = 1

	if self.field.fruitType ~= nil then
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.field.fruitType)

		if fruitDesc ~= nil then
			fruitMultiplier = fruitDesc.missionMultiplier
		end
	end

	return fruitMultiplier * self.rewardPerHa * self.field.fieldArea + self.reimbursementPerHa * self.field.fieldArea
end

function AbstractFieldMission:getReward()
	local difficultyMultiplier = 1.3 - 0.1 * g_currentMission.missionInfo.economicDifficulty
	local reimbursement = self.reimbursementPerHa * self.field.fieldArea
	local base = self.reward - reimbursement

	if self.reimbursementPerDifficulty then
		local factor = 1.4 - 0.1 * g_currentMission.missionInfo.economicDifficulty
		reimbursement = reimbursement * factor
	end

	return base * difficultyMultiplier + reimbursement
end

function AbstractFieldMission:calculateVehicleUseCost()
	local difficultyMultiplier = 0.7 + 0.3 * g_currentMission.missionInfo.economicDifficulty

	return AbstractFieldMission.VEHICLE_USE_COST * self.field.fieldArea * difficultyMultiplier
end

function AbstractFieldMission:addToMissionMap()
	self.isInMissionMap = true

	g_missionManager:addMissionToMissionMap(self)
end

function AbstractFieldMission:loadNextVehicle()
	local info = self.vehiclesToLoad[self.vehicleIndexToLoadNext]
	local filename = info.filename
	local storeItem = g_storeManager:getItemByXMLFilename(filename)

	if storeItem == nil then
		Logging.error("Trying to load invalid store item '%s' for mission.", filename)

		return false
	end

	local size = StoreItemUtil.getSizeValues(storeItem.xmlFilename, "vehicle", storeItem.rotation, info.configurations)
	local places = g_currentMission.storeSpawnPlaces
	local usedPlaces = g_currentMission.usedStorePlaces
	local x, _, z, place, width, _ = PlacementUtil.getPlace(places, size, usedPlaces)

	if x == nil then
		return false
	end

	local yRot = MathUtil.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)
	yRot = yRot + storeItem.rotation
	local location = {
		yOffset = 0,
		x = x,
		z = z,
		yRot = yRot
	}

	VehicleLoadingUtil.loadVehicle(filename, location, true, 0, Vehicle.PROPERTY_STATE_MISSION, self.farmId, info.configurations, nil, self.loadNextVehicleCallback, self, {
		self.vehicleIndexToLoadNext
	})
	PlacementUtil.markPlaceUsed(usedPlaces, place, width)

	return true
end

function AbstractFieldMission:loadNextVehicleCallback(vehicle, vehicleLoadState, arguments)
	if vehicle ~= nil then
		self.lastVehicleIndexToLoad = arguments[1]
		self.vehicleLoadWaitFrameCounter = 2
		vehicle.activeMissionId = self.activeMissionId

		vehicle:addWearAmount(math.random() * 0.3 + 0.1)
		vehicle:setOperatingTime(3600000 * (math.random() * 40 + 30))
		table.insert(self.vehicles, vehicle)
	end
end

function AbstractFieldMission:getMaxCutLiters()
	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(self.field.fruitType)
	local multiplier = g_currentMission:getHarvestScaleMultiplier(self.fruitType, self.sprayFactor, self.fieldPlowFactor, self.limeFactor, self.weedFactor, self.stubbleFactor, self.rollerFactor)
	local area = self.field.fieldArea * multiplier
	local literPerSqm = nil

	if fruitDesc.hasWindrow then
		literPerSqm = fruitDesc.windrowLiterPerSqm
	else
		literPerSqm = fruitDesc.literPerSqm
	end

	return literPerSqm * area * 10000
end

function AbstractFieldMission:isSpawnSpaceAvailable()
	local result = true
	local places = g_currentMission.storeSpawnPlaces
	local usedPlaces = g_currentMission.usedStorePlaces
	local placesFilled = {}

	for _, v in ipairs(self.vehiclesToLoad) do
		local storeItem = g_storeManager:getItemByXMLFilename(v.filename)
		local size = StoreItemUtil.getSizeValues(v.filename, "vehicle", storeItem.rotation, v.configurations)
		local x, _, _, place, width, _ = PlacementUtil.getPlace(places, size, usedPlaces)

		if x == nil then
			result = false

			break
		end

		PlacementUtil.markPlaceUsed(usedPlaces, place, width)
		table.insert(placesFilled, place)
	end

	for _, place in ipairs(placesFilled) do
		PlacementUtil.unmarkPlaceUsed(usedPlaces, place)
	end

	return result
end

function AbstractFieldMission:calculateReimbursement()
	local totalWorth = 0

	for _, vehicle in pairs(self.vehicles) do
		if vehicle.spec_fillUnit ~= nil then
			for fillUnitIndex, _ in pairs(vehicle:getFillUnits()) do
				local fillType = vehicle:getFillUnitFillType(fillUnitIndex)

				if fillType ~= nil and fillType ~= FillType.DIESEL and fillType ~= FillType.DEF and fillType ~= FillType.AIR and g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(fillType) == nil then
					local level = vehicle:getFillUnitFillLevel(fillUnitIndex)
					local fillDesc = g_fillTypeManager:getFillTypeByIndex(fillType)
					totalWorth = totalWorth + level * fillDesc.pricePerLiter
				end
			end
		end
	end

	return totalWorth * AbstractFieldMission.REIMBURSEMENT_FACTOR
end

function AbstractFieldMission:getNPC()
	return self.field.farmland:getNPC()
end

function AbstractFieldMission:createMapMarkerAtSellingStation(sellingStation)
	local x, _, z = getWorldTranslation(sellingStation.owningPlaceable.rootNode)
	local hotspot = sellingStation.mapHotspot

	if hotspot ~= nil then
		x, z = hotspot:getWorldPosition()
	end

	local mapHotspot = MissionHotspot.new()

	mapHotspot:setWorldPosition(x, z)
	g_currentMission:addMapHotspot(mapHotspot)

	self.mapHotspot = mapHotspot

	return mapHotspot
end

function AbstractFieldMission:destroyMapMarker()
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()

		self.mapHotspot = nil
	end
end

function AbstractFieldMission:hasMapMarker()
	return self.mapHotspot ~= nil
end

function AbstractFieldMission.canRunOnField(field)
	return false
end
