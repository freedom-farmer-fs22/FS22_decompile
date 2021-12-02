MissionManager = {
	CATEGORY_FIELD = 1,
	CATEGORY_TRANSPORT = 2,
	CATEGORY_GRASS_FIELD = 3,
	MAX_MISSIONS = 25,
	MAX_TRANSPORT_MISSIONS = 2,
	MAX_TRIES_PER_GENERATION = 5,
	MAX_MISSIONS_PER_GENERATION = 4,
	MISSION_GENERATION_INTERVAL = 14400000,
	ACTIVE_CONTRACT_LIMIT = 3,
	AI_PRICE_MULTIPLIER = 1
}
local MissionManager_mt = Class(MissionManager, AbstractManager)

function MissionManager.new(customMt)
	local self = AbstractManager.new(customMt or MissionManager_mt)
	self.missionTypes = {}
	self.missionTypeIdToType = {}
	self.defaultMissionMapWidth = 512
	self.defaultMissionMapHeight = 512
	self.missionMapNumChannels = 4
	self.numTransportTriggers = 0
	self.transportTriggers = {}

	return self
end

function MissionManager:initDataStructures()
	self.missions = {}
	self.nextMissionTypeId = 1
	self.missionVehicles = {}
	self.nextGeneratedMissionId = 1
	self.generationTimer = 0
	self.numTransportMissions = 0
	self.fieldToMission = {}
	self.missionMap = nil
	self.transportMissions = {}
	self.transportMissionNextStartTime = 0
	self.possibleTransportMissionsWeighted = {}
end

function MissionManager:loadMapData(xmlFile)
	MissionManager:superClass().loadMapData(self)
	self:createMissionMap()

	if g_currentMission:getIsServer() then
		g_currentMission:addUpdateable(self)

		self.missionNextGenerationTime = g_currentMission.time
		local mission = g_currentMission
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		self.fieldDataDmod = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, mission.terrainRootNode)
		self.fieldDataFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

		self.fieldDataFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
	end

	local transportMissionsXmlFilename = getXMLString(xmlFile, "map.transportMissions#filename")

	if transportMissionsXmlFilename ~= nil then
		local path = Utils.getFilename(transportMissionsXmlFilename, g_currentMission.baseDirectory)

		if path ~= nil and path ~= "" then
			self:loadTransportMissions(path)
		end
	end

	local missionVehicleXmlFilename = getXMLString(xmlFile, "map.missionVehicles#filename")

	if missionVehicleXmlFilename ~= nil then
		local path = Utils.getFilename(missionVehicleXmlFilename, g_currentMission.baseDirectory)

		if path ~= nil then
			self:loadMissionVehicles(path)
		end
	end

	if g_currentMission:getIsServer() then
		for _, missionType in ipairs(self.missionTypes) do
			if missionType.category == MissionManager.CATEGORY_TRANSPORT then
				for _ = 1, missionType.priority do
					table.insert(self.possibleTransportMissionsWeighted, missionType)
				end
			end
		end
	end

	g_messageCenter:subscribe(MessageType.MISSION_DELETED, self.onMissionDeleted, self)

	if g_addTestCommands then
		addConsoleCommand("gsFieldGenerateMission", "Force generating a new mission for given field", "consoleGenerateFieldMission", self)
		addConsoleCommand("gsMissionLoadAllVehicles", "Loading and unloading all field mission vehicles", "consoleLoadAllFieldMissionVehicles", self)
		addConsoleCommand("gsMissionHarvestField", "Harvest a field and print the liters", "consoleHarvestField", self)
		addConsoleCommand("gsMissionTestHarvests", "Run an expansive tests for harvest missions", "consoleHarvestTests", self)
	end
end

function MissionManager:loadTransportMissions(xmlFilename)
	local xmlFile = XMLFile.load("TransportMissions", xmlFilename)

	if not xmlFile then
		Logging.error("(%s) File could not be opened", xmlFilename)

		return false
	end

	xmlFile:iterate("transportMissions.mission", function (i, key)
		local mission = {
			rewardScale = xmlFile:getFloat(key .. "#rewardScale", 1),
			name = xmlFile:getString(key .. "#name"),
			title = xmlFile:getString(key .. "#title"),
			description = xmlFile:getString(key .. ".description"),
			npc = xmlFile:getInt(key .. "#npcIndex"),
			id = i
		}
		local npc = g_npcManager:getNPCByIndex(xmlFile:getInt(key .. "#npcIndex"))
		mission.npcIndex = g_npcManager:getRandomIndex()

		if npc ~= nil then
			mission.npcIndex = npc.index
		end

		npc = g_npcManager:getNPCByName(xmlFile:getString(key .. "#npcName"))

		if npc ~= nil then
			mission.npcIndex = npc.index
		end

		if mission.name == nil then
			Logging.error("Transport mission definition requires name")
		else
			mission.pickupTriggers = {}
			mission.dropoffTriggers = {}
			mission.objects = {}

			xmlFile:iterate(key .. ".pickupTrigger", function (_, subKey)
				local index = xmlFile:getString(subKey .. "#index")

				if index == nil then
					Logging.error("(%s) Pickup trigger requires valid index", xmlFilename)
				else
					table.insert(mission.pickupTriggers, {
						index = index,
						rewardScale = xmlFile:getFloat(subKey .. "#rewardScale", 1),
						title = xmlFile:getString(subKey .. "#title")
					})
				end
			end)
			xmlFile:iterate(key .. ".dropoffTrigger", function (_, subKey)
				local index = xmlFile:getString(subKey .. "#index")

				if index == nil then
					Logging.error("(%s) Dropoff trigger requires valid index", xmlFilename)
				else
					table.insert(mission.dropoffTriggers, {
						index = index,
						rewardScale = xmlFile:getFloat(subKey .. "#rewardScale", 1),
						title = xmlFile:getString(subKey .. "#title")
					})
				end
			end)
			xmlFile:iterate(key .. ".object", function (_, subKey)
				local filename = Utils.getFilename(xmlFile:getString(subKey .. "#filename"), g_currentMission.baseDirectory)

				if filename == nil then
					Logging.error("(%s) Object requires valid filename", xmlFilename)
				else
					table.insert(mission.objects, {
						filename = filename,
						min = math.max(xmlFile:getInt(subKey .. "#min", 1), 1),
						max = math.min(xmlFile:getInt(subKey .. "#max", 1), 6),
						rewardScale = xmlFile:getFloat(subKey .. "#rewardScale", 1),
						size = string.getVectorN(xmlFile:getString(subKey .. "#size", "1 1 1"), 3),
						offset = string.getVectorN(xmlFile:getString(subKey .. "#offset", "0 0 0"), 3),
						title = xmlFile:getString(subKey .. "#title")
					})
				end
			end)
			table.insert(self.transportMissions, mission)
		end
	end)
	xmlFile:delete()

	return true
end

function MissionManager:loadMissionVehicles(xmlFilename)
	local xmlFile = loadXMLFile("MissionVehicles", xmlFilename)

	if xmlFile == 0 then
		return false
	end

	local i = 0

	while true do
		local key = string.format("missionVehicles.mission(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local type = getXMLString(xmlFile, key .. "#type")

		if type == nil then
			Logging.error("(%s) Property type must exist on each mission", xmlFilename)
			delete(xmlFile)

			return false
		end

		local groups = {}
		local j = 0

		while true do
			local groupKey = string.format("%s.group(%d)", key, j)

			if not hasXMLProperty(xmlFile, groupKey) then
				break
			end

			local fieldSize = Utils.getNoNil(getXMLString(xmlFile, groupKey .. "#fieldSize"), "MEDIUM")
			local rewardScale = Utils.getNoNil(getXMLFloat(xmlFile, groupKey .. "#rewardScale"), 1)
			local vehicles = {}
			local group = {
				rewardScale = rewardScale,
				vehicles = vehicles,
				variant = getXMLString(xmlFile, groupKey .. "#variant")
			}
			local k = 0

			while true do
				local vehicleKey = string.format("%s.vehicle(%d)", groupKey, k)

				if not hasXMLProperty(xmlFile, vehicleKey) then
					break
				end

				local filename = Utils.getFilename(getXMLString(xmlFile, vehicleKey .. "#filename"), g_currentMission.baseDirectory)

				if filename == nil then
					Logging.error("(%s) Property filename must exist on each vehicle", xmlFilename)
				else
					local storeItem = g_storeManager:getItemByXMLFilename(filename)

					if storeItem == nil then
						Logging.error("%s: Unable to load store item for '%s'", xmlFilename, filename)
					else
						local configurations = {}
						local p = 0

						while true do
							local configKey = string.format("%s.configuration(%d)", vehicleKey, p)

							if not hasXMLProperty(xmlFile, configKey) then
								break
							end

							local name = getXMLString(xmlFile, configKey .. "#name")
							local id = getXMLInt(xmlFile, configKey .. "#id")

							if name ~= nil and id ~= nil then
								configurations[name] = id
							end

							p = p + 1
						end

						table.insert(vehicles, {
							filename = filename,
							configurations = configurations
						})
					end
				end

				k = k + 1
			end

			if groups[fieldSize] == nil then
				groups[fieldSize] = {}
			end

			table.insert(groups[fieldSize], group)

			group.identifier = table.getn(groups[fieldSize])
			j = j + 1
		end

		self.missionVehicles[type] = groups
		i = i + 1
	end

	delete(xmlFile)

	return true
end

function MissionManager:unloadMapData()
	g_messageCenter:unsubscribeAll(self)
	g_currentMission:removeUpdateable(self)

	self.numTransportTriggers = 0
	self.transportTriggers = {}
	self.fieldDataDmod = nil
	self.fieldDataFilter = nil
	self.fieldToMission = {}
	self.possibleTransportMissionsWeighted = {}

	self:destroyMissionMap()

	if g_addTestCommands then
		removeConsoleCommand("gsFieldGenerateMission")
		removeConsoleCommand("gsMissionLoadAllVehicles")
		removeConsoleCommand("gsMissionHarvestField")
		removeConsoleCommand("gsMissionTestHarvests")
	end

	MissionManager:superClass().unloadMapData(self)
end

function MissionManager:saveToXMLFile(xmlFilename)
	local xmlFile = createXMLFile("missionXML", xmlFilename, "missions")

	if xmlFile ~= nil then
		for k, mission in ipairs(self.missions) do
			local missionKey = string.format("missions.mission(%d)", k - 1)

			setXMLString(xmlFile, missionKey .. "#type", mission.type.name)

			if mission.activeMissionId ~= nil then
				setXMLInt(xmlFile, missionKey .. "#activeId", mission.activeMissionId)
			end

			mission:saveToXMLFile(xmlFile, missionKey)
		end

		saveXMLFile(xmlFile)
		delete(xmlFile)
	end

	return false
end

function MissionManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end

	local xmlFile = loadXMLFile("missionsXML", xmlFilename)

	if xmlFile == 0 then
		return false
	end

	local i = 0

	while true do
		local key = string.format("missions.mission(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local missionTypeName = getXMLString(xmlFile, key .. "#type")
		local missionType = self:getMissionType(missionTypeName)

		if missionType ~= nil then
			local mission = missionType.classObject.new(true, g_client ~= nil)
			mission.type = missionType
			mission.activeMissionId = getXMLInt(xmlFile, key .. "#activeId")

			self:assignGenerationTime(mission)

			if not mission:loadFromXMLFile(xmlFile, key) then
				mission:delete()
			else
				if mission.field ~= nil then
					self.fieldToMission[mission.field.fieldId] = mission
				end

				if mission.type.category == MissionManager.CATEGORY_TRANSPORT then
					self.numTransportMissions = self.numTransportMissions + 1
				end

				mission:register()
				table.insert(self.missions, mission)
			end
		else
			print("Warning: Mission type '" .. tostring(missionType) .. "' not found!")
		end

		i = i + 1
	end

	if #self.missions > 0 then
		for _, vehicle in pairs(g_currentMission.vehicles) do
			if vehicle.activeMissionId ~= nil then
				local mission = self:getMissionForActiveMissionId(vehicle.activeMissionId)

				if mission ~= nil and mission.vehicles ~= nil then
					table.insert(mission.vehicles, vehicle)
				end
			end
		end
	end

	delete(xmlFile)

	return true
end

function MissionManager:delete()
end

function MissionManager:update(dt)
	if g_currentMission:getIsServer() and not GS_IS_MOBILE_VERSION then
		self.generationTimer = self.generationTimer - g_currentMission:getEffectiveTimeScale() * dt

		self:updateMissions(dt)

		if #self.missions < MissionManager.MAX_MISSIONS and self.generationTimer < 0 then
			self:generateMissions(dt)

			self.generationTimer = MissionManager.MISSION_GENERATION_INTERVAL
		end
	end
end

function MissionManager:registerMissionType(classObject, name, category, priority)
	if classObject ~= nil and name ~= nil then
		local id = self.nextMissionTypeId
		local missionType = {
			name = name,
			classObject = classObject,
			category = category or MissionManager.CATEGORY_FIELD,
			priority = math.floor(priority or 1),
			typeId = id
		}

		table.insert(self.missionTypes, missionType)

		self.nextMissionTypeId = self.nextMissionTypeId + 1
		self.missionTypeIdToType[id] = missionType
	end
end

function MissionManager:unregisterMissionType(name)
	if name ~= nil then
		for i, type in ipairs(self.missionTypes) do
			if type.name == name then
				table.remove(self.missionType, i)

				break
			end
		end
	end
end

function MissionManager:getMissionType(name)
	for _, type in ipairs(self.missionTypes) do
		if type.name == name then
			return type
		end
	end

	return nil
end

function MissionManager:getMissionTypeById(id)
	return self.missionTypeIdToType[id]
end

function MissionManager:getTransportMissionConfig(name)
	for _, mission in pairs(self.transportMissions) do
		if mission.name == name then
			return mission
		end
	end

	return nil
end

function MissionManager:getTransportMissionConfigById(id)
	for _, mission in pairs(self.transportMissions) do
		if mission.id == id then
			return mission
		end
	end

	return nil
end

function MissionManager:hasFarmReachedMissionLimit(farmId)
	local total = 0

	for _, mission in ipairs(self.missions) do
		if mission.farmId == farmId and (mission.status == AbstractMission.STATUS_RUNNING or mission.status == AbstractMission.STATUS_FINISHED) then
			total = total + 1
		end
	end

	return MissionManager.ACTIVE_CONTRACT_LIMIT <= total
end

function MissionManager:startMission(mission, farmId, spawnVehicles)
	if farmId == FarmManager.SPECTATOR_FARM_ID then
		return
	end

	if self:hasFarmReachedMissionLimit(farmId) then
		return
	end

	if mission.activeMissionId then
		return
	end

	if g_currentMission:getIsServer() then
		if not self:canMissionStillRun(mission) then
			mission:delete()

			return
		end

		mission.activeMissionId = self:getFreeActiveMissionId()

		if mission.activeMissionId == 0 then
			return
		end

		mission.farmId = farmId

		if mission:start(spawnVehicles) then
			g_messageCenter:publish(MissionStartedEvent, mission)
		else
			mission:delete()
		end
	else
		g_client:getServerConnection():sendEvent(MissionStartEvent.new(mission, farmId, spawnVehicles))
	end
end

function MissionManager:cancelMission(mission)
	if g_currentMission:getIsServer() then
		if mission ~= nil and mission.status ~= AbstractMission.STATUS_FINISHED then
			mission:finish(false)
		end
	else
		g_client:getServerConnection():sendEvent(MissionCancelEvent.new(mission))
	end
end

function MissionManager:cancelMissionOnField(field)
	if field.currentMission ~= nil then
		field.currentMission:delete()

		field.currentMission = nil
	else
		local mission = self.fieldToMission[field.fieldId]

		if mission ~= nil then
			mission:delete()
		end
	end
end

function MissionManager:onMissionDeleted(mission)
	self:deleteMission(mission)
end

function MissionManager:deleteMission(mission)
	if mission.field ~= nil then
		self.fieldToMission[mission.field.fieldId] = nil
	end

	if mission.type.category == MissionManager.CATEGORY_TRANSPORT then
		self.numTransportMissions = self.numTransportMissions - 1
	end

	self:removeMissionFromList(mission)
end

function MissionManager:removeMissionFromList(mission)
	table.removeElement(g_missionManager.missions, mission)
end

function MissionManager:dismissMission(mission)
	if g_currentMission:getIsServer() then
		mission:dismiss()
		g_server:broadcastEvent(MissionDismissEvent.new(mission))
		mission:delete()
		g_messageCenter:publish(MissionDismissEvent, mission)
	else
		g_client:getServerConnection():sendEvent(MissionDismissEvent.new(mission))
	end
end

function MissionManager:getActiveMissions()
	return table.ifilter(self.missions, function (mission)
		return mission.status == AbstractMission.STATUS_RUNNING
	end)
end

function MissionManager:getIsAnyMissionActive()
	return table.getn(self:getActiveMissions()) > 0
end

function MissionManager:getMissionsList(farmId)
	return table.ifilter(self.missions, function (mission)
		return mission.farmId == nil or mission.farmId == farmId
	end)
end

function MissionManager:getFieldData(field)
	if self.fieldDataDmod == nil then
		local mission = g_currentMission
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
		self.fieldDataDmod = DensityMapModifier.new(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, mission.terrainRootNode)
		self.fieldDataFilter = DensityMapFilter.new(groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)

		self.fieldDataFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)
	end

	local x, z = FieldUtil.getMeasurementPositionOfField(field)

	self.fieldDataDmod:setParallelogramWorldCoords(x - 1, z - 1, 2, 0, 0, 2, DensityCoordType.POINT_VECTOR_VECTOR)

	local density, area, _ = self.fieldDataDmod:executeGet(self.fieldDataFilter)
	local fieldSpraySet = density / area > 0.5
	local sprayFactor = FieldUtil.getSprayFactor(field)
	local fieldPlowFactor = FieldUtil.getPlowFactor(field)
	local limeFactor = FieldUtil.getLimeFactor(field)
	local weedFactor = FieldUtil.getWeedFactor(field)
	local maxWeedState = FieldUtil.getMaxWeedState(field)
	local stubbleFactor = FieldUtil.getStubbleFactor(field)
	local rollerFactor = FieldUtil.getRollerFactor(field)

	return fieldSpraySet, sprayFactor, fieldPlowFactor, limeFactor, weedFactor, maxWeedState, stubbleFactor, rollerFactor
end

function MissionManager:canMissionStillRun(mission)
	local field = mission.field

	if field == nil then
		return true
	end

	local fieldSpraySet, sprayFactor, fieldPlowFactor, limeFactor, weedFactor, maxWeedState, stubbleFactor, rollerFactor = self:getFieldData(field)
	local canRun, fieldState, growthState, weedState = mission.type.classObject.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState, stubbleFactor, rollerFactor)

	if canRun then
		mission.sprayFactor = sprayFactor
		mission.fieldSpraySet = fieldSpraySet
		mission.fieldPlowFactor = fieldPlowFactor
		mission.fieldState = fieldState
		mission.growthState = growthState
		mission.limeFactor = limeFactor
		mission.weedFactor = weedFactor
		mission.weedState = weedState
		mission.stubbleFactor = stubbleFactor
	end

	return canRun
end

function MissionManager:addTransportMissionTrigger(trigger)
	self.transportTriggers[trigger.index] = trigger
	self.numTransportTriggers = self.numTransportTriggers + 1
end

function MissionManager:removeTransportMissionTrigger(trigger)
	if trigger ~= nil then
		self.transportTriggers[trigger.index] = nil
		self.numTransportTriggers = self.numTransportTriggers - 1
	end
end

function MissionManager:updateMissions(dt)
	for _, mission in ipairs(self.missions) do
		if mission.timeLeft ~= nil then
			mission.timeLeft = mission.timeLeft - dt * g_currentMission:getEffectiveTimeScale()
		end
	end

	for _, mission in ipairs(self.missions) do
		if not mission:getIsAvailable() and mission.status == AbstractMission.STATUS_STOPPED then
			mission:delete()

			break
		end
	end
end

function MissionManager:generateMissions(dt)
	local numActionsLeft = MissionManager.MAX_TRIES_PER_GENERATION
	local numMissionsLeft = MissionManager.MAX_MISSIONS_PER_GENERATION
	local createdAnyMission = false
	local indices = {}

	for i = 1, #g_fieldManager.fields do
		table.insert(indices, i)
	end

	Utils.shuffle(indices)

	for _, index in ipairs(indices) do
		local field = g_fieldManager.fields[index]

		if self.fieldToMission[field.fieldId] == nil and field.fieldMissionAllowed then
			local mission = self:generateNewFieldMission(field)

			if mission ~= nil then
				mission:register()
				table.insert(self.missions, mission)

				self.fieldToMission[field.fieldId] = mission
				createdAnyMission = true
				numMissionsLeft = numMissionsLeft - 1

				if numMissionsLeft <= 0 then
					break
				end
			end

			numActionsLeft = numActionsLeft - 1

			if numActionsLeft <= 0 then
				break
			end
		end
	end

	if table.getn(self.transportMissions) > 0 and self.numTransportMissions < MissionManager.MAX_TRANSPORT_MISSIONS then
		Utils.shuffle(self.possibleTransportMissionsWeighted)

		for _, missionType in pairs(self.possibleTransportMissionsWeighted) do
			local canRun = missionType.classObject.canRun()

			if canRun then
				local mission = missionType.classObject.new(true, g_client ~= nil)
				mission.type = missionType

				if mission:init() then
					self:assignGenerationTime(mission)
					mission:register()

					self.numTransportMissions = self.numTransportMissions + 1

					table.insert(self.missions, mission)

					createdAnyMission = true

					break
				else
					mission:delete()
				end
			end
		end
	end

	if createdAnyMission then
		g_messageCenter:publish(MessageType.MISSION_GENERATED)
	end
end

function MissionManager:generateNewFieldMission(field)
	if not field.fieldMissionAllowed then
		return nil
	end

	if field.currentMission ~= nil or not field:getIsAIActive() then
		return nil
	end

	local category = MissionManager.CATEGORY_FIELD

	if field.fruitType == FruitType.GRASS then
		category = MissionManager.CATEGORY_GRASS_FIELD
	end

	local fieldSpraySet, sprayFactor, fieldPlowFactor, limeFactor, weedFactor, maxWeedState, stubbleFactor, rollerFactor = self:getFieldData(field)

	for _, missionType in ipairs(self.missionTypes) do
		if missionType.category == category then
			local canRun, fieldState, growthState, weedState, args = missionType.classObject.canRunOnField(field, sprayFactor, fieldSpraySet, fieldPlowFactor, limeFactor, maxWeedState, stubbleFactor, rollerFactor)

			if canRun then
				local mission = missionType.classObject.new(true, g_client ~= nil)
				mission.type = missionType

				if mission:init(field, sprayFactor, fieldSpraySet, fieldPlowFactor, fieldState, growthState, limeFactor, weedFactor, weedState, stubbleFactor, rollerFactor, args) then
					self:assignGenerationTime(mission)

					return mission
				else
					mission:delete()
				end
			end
		end
	end

	return nil
end

function MissionManager:assignGenerationTime(mission)
	mission.generationTime = self.nextGeneratedMissionId
	self.nextGeneratedMissionId = self.nextGeneratedMissionId + 1
end

function MissionManager:getRandomVehicleGroup(missionType, fieldSize, variant)
	local groups = self.missionVehicles[missionType]

	if groups == nil then
		return nil, 1
	end

	local sized = groups[fieldSize]

	if sized == nil then
		return nil, 1
	end

	local variantGroups = table.ifilter(sized, function (group)
		return variant == nil or group.variant == variant
	end)
	local group = table.getRandomElement(variantGroups)

	if group == nil then
		return nil, 1
	end

	return group.vehicles, group.identifier
end

function MissionManager:getVehicleGroupFromIdentifier(missionType, fieldSize, identifier)
	local groups = self.missionVehicles[missionType]

	if groups == nil then
		return nil, 1
	end

	local sized = groups[fieldSize]

	if sized == nil then
		return nil, 1
	end

	local group = sized[identifier]

	if group == nil then
		return nil, 1
	end

	return group.vehicles, group.rewardScale
end

function MissionManager:getFreeActiveMissionId()
	for i = 1, MissionManager.MAX_MISSIONS do
		if self:getMissionForActiveMissionId(i) == nil then
			return i
		end
	end

	return 0
end

function MissionManager:validateMissionOnField(field, event, canRunCheck)
	local mission = self.fieldToMission[field.fieldId]

	if mission == nil then
		return
	end

	if not mission:validate(event) then
		return mission:delete()
	end

	if canRunCheck and not self:canMissionStillRun(mission) then
		mission:delete()
	end
end

function MissionManager:createMissionMap()
	self.missionMap = createBitVectorMap("MissionAccessMap")

	loadBitVectorMapNew(self.missionMap, self.defaultMissionMapWidth, self.defaultMissionMapHeight, self.missionMapNumChannels, false)

	self.missionMapWidth, self.missionMapHeight = getBitVectorMapSize(self.missionMap)

	if g_currentMission:getIsServer() then
		g_currentMission.growthSystem:setGrowthMask(self.missionMap, 0, self.missionMapNumChannels)
	end
end

function MissionManager:destroyMissionMap()
	if g_currentMission:getIsServer() and self.growthSystem ~= nil then
		self.growthSystem:resetGrowthMask()
	end

	if self.missionMap ~= nil then
		delete(self.missionMap)

		self.missionMap = nil
	end
end

function MissionManager:setMissionMapForMission(mission, value)
	for i = 0, getNumOfChildren(mission.field.fieldDimensions) - 1 do
		local dimWidth = getChildAt(mission.field.fieldDimensions, i)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x0, _, z0 = getWorldTranslation(dimStart)
		local widthX, _, widthZ = getWorldTranslation(dimWidth)
		local heightX, _, heightZ = getWorldTranslation(dimHeight)
		local x, z = self:convertWorldToAccessPosition(x0, z0)
		widthX, widthZ = self:convertWorldToAccessPosition(widthX, widthZ)
		heightX, heightZ = self:convertWorldToAccessPosition(heightX, heightZ)

		setBitVectorMapParallelogram(self.missionMap, x, z, widthX - x, widthZ - z, heightX - x, heightZ - z, 0, self.missionMapNumChannels, value)
	end
end

function MissionManager:addMissionToMissionMap(mission)
	if self.missionMap ~= nil then
		self:setMissionMapForMission(mission, mission.activeMissionId)
	end
end

function MissionManager:removeMissionFromMissionMap(mission)
	if self.missionMap ~= nil then
		self:setMissionMapForMission(mission, 0)
	end
end

function MissionManager:convertWorldToAccessPosition(x, z)
	local size = g_currentMission.terrainSize

	return math.floor(self.missionMapWidth * (x + size * 0.5) / size), math.floor(self.missionMapHeight * (z + size * 0.5) / size)
end

function MissionManager:getMissionMapValue(x, z)
	local lx, lz = self:convertWorldToAccessPosition(x, z)

	return getBitVectorMapPoint(self.missionMap, lx, lz, 0, self.missionMapNumChannels)
end

function MissionManager:getMissionForActiveMissionId(activeMissionId)
	for _, mission in ipairs(self.missions) do
		if mission.activeMissionId == activeMissionId then
			return mission
		end
	end

	return nil
end

function MissionManager:getIsMissionWorkAllowed(farmId, x, z, workAreaType)
	local mission = self:getMissionAtWorldPosition(x, z)

	if mission ~= nil and mission.farmId == farmId and (workAreaType == nil or mission.workAreaTypes[workAreaType]) then
		return true
	end

	return false
end

function MissionManager:getMissionAtWorldPosition(x, z)
	local missionId = self:getMissionMapValue(x, z)

	if missionId > 0 then
		return self:getMissionForActiveMissionId(missionId)
	end

	return nil
end

function MissionManager:consoleGenerateFieldMission(fieldId)
	fieldId = tonumber(fieldId)
	local field = g_fieldManager:getFieldByIndex(fieldId)

	if field == nil then
		return "Field not found"
	end

	g_missionManager:cancelMissionOnField(field)

	local mission = self:generateNewFieldMission(field)

	if mission == nil then
		return "Could not generate a mission"
	end

	mission:register()
	table.insert(self.missions, mission)

	self.fieldToMission[field.fieldId] = mission

	return "Generated mission and added to mission list"
end

function MissionManager:consoleLoadAllFieldMissionVehicles()
	local vehiclesToLoad = {}

	for _, groups in pairs(self.missionVehicles) do
		for _, data in pairs(groups) do
			for _, v in pairs(data) do
				for _, vehicle in pairs(v.vehicles) do
					table.insert(vehiclesToLoad, {
						filename = vehicle.filename,
						configurations = vehicle.configurations
					})
				end
			end
		end
	end

	printf("%d vehicles to load", #vehiclesToLoad)
	self:loadNextVehicle(nil, , {
		vehiclesToLoad
	})
end

function MissionManager:loadNextVehicle(previousVehicle, vehicleLoadState, arguments)
	if previousVehicle ~= nil and vehicleLoadState ~= VehicleLoadingUtil.VEHICLE_LOAD_OK then
		Logging.error("loading '%s'", previousVehicle.configFileName)
	end

	if previousVehicle ~= nil then
		g_currentMission:removeVehicle(previousVehicle)
	end

	local vehiclesToLoad = unpack(arguments)

	if #vehiclesToLoad == 0 then
		log("finishied loading all mission vehicles")

		return
	end

	local info = table.remove(vehiclesToLoad, 1)
	local filename = info.filename
	local storeItem = g_storeManager:getItemByXMLFilename(filename)

	if storeItem == nil then
		Logging.error("Trying to load invalid store item '%s' for mission.", filename)
	end

	local size = StoreItemUtil.getSizeValues(storeItem.xmlFilename, "vehicle", storeItem.rotation, info.configurations)
	local places = g_currentMission.storeSpawnPlaces
	local usedPlaces = g_currentMission.usedStorePlaces
	local x, _, z, place, width, _ = PlacementUtil.getPlace(places, size, usedPlaces)
	local yRot = MathUtil.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)
	yRot = yRot + storeItem.rotation
	local location = {
		yOffset = 0,
		x = x,
		z = z,
		yRot = yRot
	}

	VehicleLoadingUtil.loadVehicle(filename, location, true, 0, Vehicle.PROPERTY_STATE_MISSION, self.farmId, info.configurations, nil, self.loadNextVehicle, self, {
		vehiclesToLoad
	})
	PlacementUtil.markPlaceUsed(usedPlaces, place, width)
	printf("loading vehicle %s, %d left", filename, #vehiclesToLoad)
end

function MissionManager:testHarvestField(field)
	local sumArea = 0
	local numDimensions = getNumOfChildren(field.fieldDimensions)

	for i = 1, numDimensions do
		local dimWidth = getChildAt(field.fieldDimensions, i - 1)
		local dimStart = getChildAt(dimWidth, 0)
		local dimHeight = getChildAt(dimWidth, 1)
		local x, _, z = getWorldTranslation(dimStart)
		local x1, _, z1 = getWorldTranslation(dimWidth)
		local x2, _, z2 = getWorldTranslation(dimHeight)
		local destroySpray = true
		local useMinForageState = false
		local excludedSprayType = nil
		local realArea, _, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, _, _, _, _ = FSDensityMapUtil.cutFruitArea(field.fruitType, x, z, x1, z1, x2, z2, destroySpray, useMinForageState, excludedSprayType)
		local multiplier = g_currentMission:getHarvestScaleMultiplier(field.fruitType, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor)
		sumArea = sumArea + realArea * multiplier
	end

	local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(field.fruitType)
	local litersPerSqm = fruitDesc.literPerSqm
	local totalLiters = sumArea * g_currentMission:getFruitPixelsToSqm() * litersPerSqm

	return totalLiters
end

function MissionManager:consoleHarvestField(fieldId)
	fieldId = tonumber(fieldId)
	local field = g_fieldManager:getFieldByIndex(fieldId)

	if field == nil then
		return "Field not found"
	end

	local harvestMission = self.fieldToMission[fieldId]

	if harvestMission == nil then
		return "No harvest mission to compare to"
	end

	if harvestMission.type.name ~= "harvest" and harvestMission.type.name ~= "mow_bale" then
		return "No harvest mission to compare to"
	end

	log("Expected by mission: ", harvestMission:getMaxCutLiters())
	log("Field area in m2", field.fieldArea * 10000)

	local totalLiters = self:testHarvestField(field)

	log("Liters", totalLiters)

	if harvestMission.type.name == "mow_bale" then
		local expectedNum = harvestMission.expectedLiters / 4000

		log("It is a baling mission. Expected number of bales:", expectedNum, expectedNum * 0.95 * 0.95)

		local actual = totalLiters / 4000

		log("Actual bales", actual, math.floor(actual))
	end
end

function MissionManager:consoleHarvestTests(fieldId)
	if fieldId ~= nil then
		fieldId = tonumber(fieldId)
	end

	local numHarvests = 0
	local numHarvestsFailed = 0

	for _, field in pairs(g_fieldManager.fields) do
		if field.fieldMissionAllowed and field:getIsAIActive() and (fieldId == nil or field.fieldId == fieldId) then
			for _, fruitType in ipairs(g_fieldManager.availableFruitTypeIndices) do
				local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

				if fruitType ~= FruitType.POTATO and fruitType ~= FruitType.SUGARBEET then
					for growthState = 7, 7 do
						for weedState = 0, 5 do
							for plowingState = 0, 1 do
								for limeState = 0, 3 do
									for fertilizerState = 0, 2 do
										g_fieldManager:setFieldFruit(field, fruitDesc, growthState, 1, fertilizerState, plowingState, weedState, limeState)
										g_missionManager:cancelMissionOnField(field)

										local mission = self:generateNewFieldMission(field)

										if mission ~= nil and mission.type.name == "harvest" then
											mission:register()
											table.insert(self.missions, mission)

											self.fieldToMission[field.fieldId] = mission
											local cutLiters = self:testHarvestField(field)
											local expectedLiters = mission:getMaxCutLiters()

											if cutLiters < expectedLiters * 0.95 then
												log("Error: Found wrong field setup. Field", field.fieldId, "expected", expectedLiters, "got", cutLiters, "for", fruitDesc.name, growthState, 1, fertilizerState, plowingState, weedState, limeState, false)

												numHarvestsFailed = numHarvestsFailed + 1
											else
												log("OK: Found correct field setup. Field", field.fieldId, "expected", expectedLiters, "got", cutLiters, "for", fruitDesc.name, growthState, 1, fertilizerState, plowingState, weedState, limeState, false)
											end

											numHarvests = numHarvests + 1
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	log("Total harvests:", numHarvests)
	log("Total failed:", numHarvestsFailed)
end

g_missionManager = MissionManager.new()
