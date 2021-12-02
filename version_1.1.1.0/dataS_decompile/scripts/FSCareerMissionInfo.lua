FSCareerMissionInfo = {}
local FSCareerMissionInfo_mt = Class(FSCareerMissionInfo, FSMissionInfo)
FSCareerMissionInfo.SavegameRevision = 2

if GS_PLATFORM_PLAYSTATION then
	FSCareerMissionInfo.MaxSavegameSize = 52428800
else
	FSCareerMissionInfo.MaxSavegameSize = 26214400
end

FSCareerMissionInfo.BUY_PRICE_MULTIPLIER = {
	0.5,
	0.75,
	1
}
FSCareerMissionInfo.SELL_PRICE_MULTIPLIER = {
	2,
	1.5,
	1
}

function FSCareerMissionInfo.new(baseDirectory, customEnvironment, savegameIndex, customMt)
	if customMt == nil then
		customMt = FSCareerMissionInfo_mt
	end

	local self = FSCareerMissionInfo:superClass().new(baseDirectory, customEnvironment, customMt)
	self.savegameIndex = savegameIndex
	self.savegameDirectory = self:getSavegameDirectory(self.savegameIndex)
	self.displayName = g_i18n:getText("ui_savegame") .. " " .. self.savegameIndex
	self.xmlKey = "careerSavegame"
	self.tipTypeMappings = {}

	return self
end

function FSCareerMissionInfo:delete()
	if self.xmlFile ~= nil then
		delete(self.xmlFile)
	end
end

function FSCareerMissionInfo:loadDefaults()
	FSCareerMissionInfo:superClass().loadDefaults(self)

	self.isValid = false
	self.isInvalidUser = false
	self.isCorruptFile = false
	self.saveDateFormatted = "--/--/--"
	self.saveDate = nil
	self.resetVehicles = false
	self.vehiclesXML = nil
	self.itemsXML = nil
	self.placeablesXML = nil
	self.aiSystemXML = nil
	self.onCreateObjectsXML = nil
	self.environmentXML = nil
	self.vehicleSaleXML = nil
	self.economyXML = nil
	self.farmlandXML = nil
	self.npcXML = nil
	self.missionsXML = nil
	self.fieldsXML = nil
	self.farmsXML = nil
	self.playersXML = nil
	self.densityMapHeightXML = nil
	self.savegameDirectory = nil
	self.densityMapRevision = -1
	self.terrainTextureRevision = -1
	self.terrainLodTextureRevision = -1
	self.splitShapesRevision = -1
	self.tipCollisionRevision = -1
	self.placementCollisionRevision = -1
	self.navigationCollisionRevision = -1
	self.tipTypeMappings = {}
	self.mapId = nil
	self.autoSaveInterval = AutoSaveManager.DEFAULT_INTERVAL
	self.mods = {}
	self.guidedTourActive = true
	self.guidedTourStep = 0
	self.slotUsage = 0
	self.plannedDaysPerPeriod = 1
end

function FSCareerMissionInfo:loadFromXML(xmlFile)
	local key = self.xmlKey
	local revision = getXMLInt(xmlFile, key .. "#revision")

	if revision ~= FSCareerMissionInfo.SavegameRevision then
		return false
	end

	self.isValid = getXMLBool(xmlFile, key .. "#valid")

	if self.isValid == nil then
		return false
	end

	if self.isValid then
		local mapId = getXMLString(xmlFile, key .. ".settings.mapId")

		if mapId == nil then
			return false
		end

		self.mapTitle = getXMLString(xmlFile, key .. ".settings.mapTitle")

		self:setMapId(mapId)

		self.isInvalidUser = false
		self.savegameName = Utils.getNoNil(getXMLString(xmlFile, key .. ".settings.savegameName"), self.savegameName)
		self.creationDate = Utils.getNoNil(getXMLString(xmlFile, key .. ".settings.creationDate"), self.creationDate)
		self.guidedTourActive = Utils.getNoNil(getXMLBool(xmlFile, key .. ".guidedTour#active"), self.guidedTourActive)
		self.guidedTourStep = Utils.getNoNil(getXMLInt(xmlFile, key .. ".guidedTour#currentStepIndex"), self.guidedTourStep)
		self.densityMapRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.densityMapRevision"), -1)
		self.terrainTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.terrainTextureRevision"), -1)
		self.terrainLodTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.terrainLodTextureRevision"), -1)
		self.splitShapesRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.splitShapesRevision"), -1)
		self.tipCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.tipCollisionRevision"), -1)
		self.placementCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.placementCollisionRevision"), -1)
		self.navigationCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.navigationCollisionRevision"), -1)
		self.mapDensityMapRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapDensityMapRevision"), 1)
		self.mapTerrainTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapTerrainTextureRevision"), 1)
		self.mapTerrainLodTextureRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapTerrainLodTextureRevision"), 1)
		self.mapSplitShapesRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapSplitShapesRevision"), 1)
		self.mapTipCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapTipCollisionRevision"), 1)
		self.mapPlacementCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapPlacementCollisionRevision"), 1)
		self.mapNavigationCollisionRevision = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.mapNavigationCollisionRevision"), 1)
		self.resetVehicles = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.resetVehicles"), self.resetVehicles)
		self.stopAndGoBraking = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.stopAndGoBraking"), true)
		self.trailerFillLimit = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.trailerFillLimit"), false)
		self.fruitDestruction = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.fruitDestruction"), true)
		self.plowingRequiredEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.plowingRequiredEnabled"), true)
		self.stonesEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.stonesEnabled"), true)
		self.weedsEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.weedsEnabled"), true)
		self.limeRequired = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.limeRequired"), true)
		self.automaticMotorStartEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.automaticMotorStartEnabled"), true)
		self.fuelUsageLow = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.fuelUsageLow"), true)
		self.helperBuyFuel = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.helperBuyFuel"), true)
		self.helperBuySeeds = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.helperBuySeeds"), true)
		self.helperBuyFertilizer = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.helperBuyFertilizer"), true)
		self.helperSlurrySource = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.helperSlurrySource"), 2)
		self.helperManureSource = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.helperManureSource"), 2)
		self.difficulty = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.difficulty"), 1)

		self:updateDifficultyProperties()

		self.economicDifficulty = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.economicDifficulty"), self.difficulty)
		self.buyPriceMultiplier = self:getBuyPriceMultiplier()
		self.sellPriceMultiplier = self:getSellPriceMultiplier()
		self.saveDate = Utils.getNoNil(getXMLString(xmlFile, key .. ".settings.saveDate"), nil)
		self.saveDateFormatted = Utils.getNoNil(getXMLString(xmlFile, key .. ".settings.saveDateFormatted"), self.saveDate)
		self.timeScale = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".settings.timeScale"), Platform.gameplay.defaultTimeScale)
		self.trafficEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.trafficEnabled"), true)
		self.dirtInterval = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.dirtInterval"), 3)
		self.isSnowEnabled = Utils.getNoNil(getXMLBool(xmlFile, key .. ".settings.isSnowEnabled"), true)
		self.growthMode = Utils.getNoNil(getXMLInt(xmlFile, key .. ".settings.growthMode"), GrowthSystem.MODE.SEASONAL)
		self.fixedSeasonalVisuals = getXMLInt(xmlFile, key .. ".settings.fixedSeasonalVisuals")
		self.plannedDaysPerPeriod = getXMLInt(xmlFile, key .. ".settings.plannedDaysPerPeriod") or 1
		self.autoSaveInterval = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".settings.autoSaveInterval"), AutoSaveManager.DEFAULT_INTERVAL)
		self.foundHelpIcons = Utils.getNoNil(getXMLString(xmlFile, key .. ".map.foundHelpIcons"), "00000000000000000000")
		self.playTime = Utils.getNoNil(getXMLFloat(xmlFile, key .. ".statistics.playTime"), 0)
		self.money = Utils.getNoNil(tonumber(getXMLString(xmlFile, key .. ".statistics.money")), 0)
		self.slotUsage = getXMLInt(xmlFile, key .. ".slotSystem#slotUsage") or 0
		self.mapsSplitShapeFileIds = {}
		local numSplitShapeFileIds = Utils.getNoNil(getXMLInt(xmlFile, key .. ".mapsSplitShapeFileIds#count"), 0)

		for i = 1, numSplitShapeFileIds do
			local fileIdKey = string.format("%s.mapsSplitShapeFileIds.id(%d)", key, i - 1)
			local id = Utils.getNoNil(getXMLInt(xmlFile, fileIdKey .. "#id"), -1)

			table.insert(self.mapsSplitShapeFileIds, id)
		end

		local mapModNameParts = nil

		if self.mapId ~= nil then
			mapModNameParts = self.mapId:split(".")
		end

		self.mods = {}
		local i = 0

		while true do
			local modKey = key .. string.format(".mod(%d)", i)

			if not hasXMLProperty(xmlFile, modKey) then
				break
			end

			local modName = getXMLString(xmlFile, modKey .. "#modName")
			local title = getXMLString(xmlFile, modKey .. "#title")
			local version = getXMLString(xmlFile, modKey .. "#version")
			local fileHash = getXMLString(xmlFile, modKey .. "#fileHash")
			local required = Utils.getNoNil(getXMLBool(xmlFile, modKey .. "#required"), true)

			if modName ~= nil and title ~= nil then
				table.insert(self.mods, {
					modName = modName,
					title = title,
					version = version,
					fileHash = fileHash,
					required = required
				})
			end

			if self.mapTitle == nil and mapModNameParts ~= nil and #mapModNameParts == 2 and modName == mapModNameParts[1] then
				self.mapTitle = title .. " - " .. mapModNameParts[2]
			end

			i = i + 1
		end
	end

	return true
end

function FSCareerMissionInfo:saveToXMLFile()
	if self.xmlFile ~= nil then
		delete(self.xmlFile)
	end

	local xmlFile = createXMLFile("careerSavegameXML", "", "careerSavegame")
	self.xmlFile = xmlFile
	local key = self.xmlKey

	setXMLInt(xmlFile, key .. "#revision", FSCareerMissionInfo.SavegameRevision)
	setXMLBool(xmlFile, key .. "#valid", self.isValid)

	if self.isValid then
		setXMLString(xmlFile, key .. ".settings.savegameName", self.savegameName)
		setXMLString(xmlFile, key .. ".settings.creationDate", self.creationDate)
		setXMLString(xmlFile, key .. ".settings.mapId", self.mapId)
		setXMLString(xmlFile, key .. ".settings.mapTitle", self.map.title)
		setXMLString(xmlFile, key .. ".settings.saveDateFormatted", self.saveDateFormatted)
		setXMLString(xmlFile, key .. ".settings.saveDate", self.saveDate)
		setXMLBool(xmlFile, key .. ".guidedTour#active", self.guidedTourActive)
		setXMLInt(xmlFile, key .. ".guidedTour#currentStepIndex", self.guidedTourStep)
		setXMLBool(xmlFile, key .. ".settings.resetVehicles", self.resetVehicles)
		setXMLBool(xmlFile, key .. ".settings.trafficEnabled", self.trafficEnabled)
		setXMLBool(xmlFile, key .. ".settings.stopAndGoBraking", self.stopAndGoBraking)
		setXMLBool(xmlFile, key .. ".settings.trailerFillLimit", self.trailerFillLimit)
		setXMLBool(xmlFile, key .. ".settings.automaticMotorStartEnabled", self.automaticMotorStartEnabled)
		setXMLInt(xmlFile, key .. ".settings.growthMode", self.growthMode)

		if self.fixedSeasonalVisuals ~= nil then
			setXMLInt(xmlFile, key .. ".settings.fixedSeasonalVisuals", self.fixedSeasonalVisuals)
		end

		setXMLInt(xmlFile, key .. ".settings.plannedDaysPerPeriod", self.plannedDaysPerPeriod)
		setXMLBool(xmlFile, key .. ".settings.fruitDestruction", self.fruitDestruction)
		setXMLBool(xmlFile, key .. ".settings.plowingRequiredEnabled", self.plowingRequiredEnabled)
		setXMLBool(xmlFile, key .. ".settings.stonesEnabled", self.stonesEnabled)
		setXMLBool(xmlFile, key .. ".settings.weedsEnabled", self.weedsEnabled)
		setXMLBool(xmlFile, key .. ".settings.limeRequired", self.limeRequired)
		setXMLBool(xmlFile, key .. ".settings.isSnowEnabled", self.isSnowEnabled)
		setXMLBool(xmlFile, key .. ".settings.fuelUsageLow", self.fuelUsageLow)
		setXMLBool(xmlFile, key .. ".settings.helperBuyFuel", self.helperBuyFuel)
		setXMLBool(xmlFile, key .. ".settings.helperBuySeeds", self.helperBuySeeds)
		setXMLBool(xmlFile, key .. ".settings.helperBuyFertilizer", self.helperBuyFertilizer)
		setXMLInt(xmlFile, key .. ".settings.helperSlurrySource", self.helperSlurrySource)
		setXMLInt(xmlFile, key .. ".settings.helperManureSource", self.helperManureSource)
		setXMLInt(xmlFile, key .. ".settings.densityMapRevision", self.densityMapRevision)
		setXMLInt(xmlFile, key .. ".settings.terrainTextureRevision", self.terrainTextureRevision)
		setXMLInt(xmlFile, key .. ".settings.terrainLodTextureRevision", self.terrainLodTextureRevision)
		setXMLInt(xmlFile, key .. ".settings.splitShapesRevision", self.splitShapesRevision)
		setXMLInt(xmlFile, key .. ".settings.tipCollisionRevision", self.tipCollisionRevision)
		setXMLInt(xmlFile, key .. ".settings.placementCollisionRevision", self.placementCollisionRevision)
		setXMLInt(xmlFile, key .. ".settings.navigationCollisionRevision", self.navigationCollisionRevision)
		setXMLInt(xmlFile, key .. ".settings.mapDensityMapRevision", self.mapDensityMapRevision)
		setXMLInt(xmlFile, key .. ".settings.mapTerrainTextureRevision", self.mapTerrainTextureRevision)
		setXMLInt(xmlFile, key .. ".settings.mapTerrainLodTextureRevision", self.mapTerrainLodTextureRevision)
		setXMLInt(xmlFile, key .. ".settings.mapSplitShapesRevision", self.mapSplitShapesRevision)
		setXMLInt(xmlFile, key .. ".settings.mapTipCollisionRevision", self.mapTipCollisionRevision)
		setXMLInt(xmlFile, key .. ".settings.mapPlacementCollisionRevision", self.mapPlacementCollisionRevision)
		setXMLInt(xmlFile, key .. ".settings.mapNavigationCollisionRevision", self.mapNavigationCollisionRevision)
		setXMLInt(xmlFile, key .. ".settings.difficulty", self.difficulty)
		setXMLInt(xmlFile, key .. ".settings.economicDifficulty", self.economicDifficulty)
		setXMLInt(xmlFile, key .. ".settings.dirtInterval", self.dirtInterval)
		setXMLFloat(xmlFile, key .. ".settings.timeScale", self.timeScale)
		setXMLFloat(xmlFile, key .. ".settings.autoSaveInterval", g_autoSaveManager:getInterval())
		setXMLString(xmlFile, key .. ".map.foundHelpIcons", self.foundHelpIcons)

		local money = 0
		local maxPlayTime = 0

		for _, farm in ipairs(g_farmManager.farms) do
			if not farm.isSpectator then
				money = money + farm.money
				maxPlayTime = math.max(maxPlayTime, farm.stats:getTotalValue("playTime"))
			end
		end

		setXMLString(xmlFile, key .. ".statistics.money", tostring(math.floor(money + 0.0001)))
		setXMLFloat(xmlFile, key .. ".statistics.playTime", maxPlayTime)
		g_currentMission.slotSystem:saveToXMLFile(xmlFile, key .. ".slotSystem")
		g_currentMission.collectiblesSystem:saveToXMLFile(self.savegameDirectory .. "/collectibles.xml")

		local environmentXMLFile = createXMLFile("environmentXMLFile", self.environmentXML, "environment")

		if environmentXMLFile ~= nil then
			if g_currentMission ~= nil then
				g_currentMission.environment:saveToXMLFile(environmentXMLFile, "environment")
				g_currentMission.snowSystem:saveToXMLFile(environmentXMLFile, "environment.snow")
				g_currentMission.growthSystem:saveToXMLFile(environmentXMLFile, "environment.growth")
			end

			saveXMLFile(environmentXMLFile)
			delete(environmentXMLFile)
		end

		setXMLInt(xmlFile, key .. ".mapsSplitShapeFileIds#count", table.getn(self.mapsSplitShapeFileIds))

		for i, id in ipairs(self.mapsSplitShapeFileIds) do
			setXMLInt(xmlFile, string.format("%s.mapsSplitShapeFileIds.id(%d)", key, i - 1) .. "#id", id)
		end

		local usedModNames = {}

		if g_currentMission ~= nil then
			g_currentMission.placeableSystem:setSaveIds()
			VehicleLoadingUtil.setSaveIds(g_currentMission.vehicles)
			VehicleLoadingUtil.save(self.vehiclesXML, usedModNames)
			g_currentMission.placeableSystem:save(self.placeablesXML, usedModNames)
			g_currentMission.itemSystem:save(self.itemsXML, usedModNames)
			g_currentMission.aiSystem:save(self.aiSystemXML, usedModNames)
		end

		local onCreateObjectsXMLFile = createXMLFile("onCreateObjectsXMLFile", self.onCreateObjectsXML, "onCreateLoadedObjects")

		if onCreateObjectsXMLFile ~= nil then
			if g_currentMission ~= nil then
				g_currentMission:saveOnCreateObjects(onCreateObjectsXMLFile, "onCreateLoadedObjects", usedModNames)
			end

			saveXMLFile(onCreateObjectsXMLFile)
			delete(onCreateObjectsXMLFile)
		end

		local economyFile = createXMLFile("economyXML", self.economyXML, "economy")

		if economyFile ~= nil then
			if g_currentMission ~= nil then
				g_currentMission.economyManager:saveToXMLFile(economyFile, "economy")
			end

			saveXMLFile(economyFile)
			delete(economyFile)
		end

		g_farmlandManager:saveToXMLFile(self.farmlandXML)
		g_npcManager:saveToXMLFile(self.npcXML)
		g_fieldManager:saveToXMLFile(self.fieldsXML)
		g_missionManager:saveToXMLFile(self.missionsXML)
		g_farmManager:saveToXMLFile(self.farmsXML)
		g_currentMission.playerInfoStorage:saveToXMLFile(self.playersXML)
		g_densityMapHeightManager:saveToXMLFile(self.densityMapHeightXML)
		g_treePlantManager:saveToXMLFile(self.treePlantXML)
		g_currentMission.vehicleSaleSystem:saveToXMLFile(self.vehicleSaleXML)

		local mapModName = ClassUtil.getClassModName(self.mapId)

		if mapModName ~= nil then
			usedModNames[mapModName] = mapModName
		end

		for _, modItem in pairs(g_currentMission.missionDynamicInfo.mods) do
			usedModNames[modItem.modName] = modItem.modName
		end

		local modIndex = 0

		for modName, _ in pairs(usedModNames) do
			local modItem = g_modManager:getModByName(modName)

			if modItem ~= nil then
				local required = modName == mapModName

				setXMLString(xmlFile, key .. string.format(".mod(%d)#modName", modIndex), modItem.modName)
				setXMLString(xmlFile, key .. string.format(".mod(%d)#title", modIndex), modItem.title)
				setXMLString(xmlFile, key .. string.format(".mod(%d)#version", modIndex), modItem.version)
				setXMLBool(xmlFile, key .. string.format(".mod(%d)#required", modIndex), required)
				setXMLString(xmlFile, key .. string.format(".mod(%d)#fileHash", modIndex), tostring(modItem.fileHash))

				modIndex = modIndex + 1
			end
		end

		saveXMLFile(xmlFile)
	end
end

function FSCareerMissionInfo:loadFromMission(mission)
	self.mapDensityMapRevision = mission.mapDensityMapRevision
	self.mapTerrainTextureRevision = mission.mapTerrainTextureRevision
	self.mapTerrainLodTextureRevision = mission.mapTerrainLodTextureRevision
	self.mapSplitShapesRevision = mission.mapSplitShapesRevision
	self.mapTipCollisionRevision = mission.mapTipCollisionRevision
	self.mapPlacementCollisionRevision = mission.mapPlacementCollisionRevision
	self.mapNavigationCollisionRevision = mission.mapNavigationCollisionRevision
	self.mapsSplitShapeFileIds = {}

	for _, id in ipairs(mission.mapsSplitShapeFileIds) do
		table.insert(self.mapsSplitShapeFileIds, id)
	end

	self.saveDate = getDate("%Y-%m-%d")
	self.saveDateFormatted = g_i18n:getCurrentDate()
end

function FSCareerMissionInfo:setSavegameDirectory(directory)
	self.savegameDirectory = directory

	if directory ~= nil then
		self.vehiclesXML = self.savegameDirectory .. "/vehicles.xml"
		self.itemsXML = self.savegameDirectory .. "/items.xml"
		self.placeablesXML = self.savegameDirectory .. "/placeables.xml"
		self.aiSystemXML = self.savegameDirectory .. "/aiSystem.xml"
		self.onCreateObjectsXML = self.savegameDirectory .. "/onCreateObjects.xml"
		self.environmentXML = self.savegameDirectory .. "/environment.xml"
		self.vehicleSaleXML = self.savegameDirectory .. "/sales.xml"
		self.economyXML = self.savegameDirectory .. "/economy.xml"
		self.farmlandXML = self.savegameDirectory .. "/farmland.xml"
		self.npcXML = self.savegameDirectory .. "/npc.xml"
		self.missionsXML = self.savegameDirectory .. "/missions.xml"
		self.fieldsXML = self.savegameDirectory .. "/fields.xml"
		self.farmsXML = self.savegameDirectory .. "/farms.xml"
		self.playersXML = self.savegameDirectory .. "/players.xml"
		self.densityMapHeightXML = self.savegameDirectory .. "/densityMapHeight.xml"
		self.treePlantXML = self.savegameDirectory .. "/treePlant.xml"
	else
		self.vehiclesXML = nil
		self.itemsXML = nil
		self.placeablesXML = nil
		self.aiSystemXML = nil
		self.onCreateObjectsXML = nil
		self.economyXML = nil
		self.environmentXML = nil
		self.vehicleSaleXML = nil
		self.farmlandXML = nil
		self.npcXML = nil
		self.missionsXML = nil
		self.fieldsXML = nil
		self.farmsXML = nil
		self.playersXML = nil
		self.densityMapHeightXML = nil
	end
end

function FSCareerMissionInfo:getSavegameDirectory(index)
	return getUserProfileAppPath() .. "savegame" .. index
end

function FSCareerMissionInfo:getSavegameAutoBackupBasePath()
	return getUserProfileAppPath() .. "savegameBackup"
end

function FSCareerMissionInfo:getSavegameAutoBackupDirectoryBase(index)
	return "savegame" .. index .. "_backup"
end

function FSCareerMissionInfo:getSavegameAutoBackupLatestFilename(index)
	return "savegame" .. index .. "_backupLatest.txt"
end

function FSCareerMissionInfo:getStateI18NKey()
	if self.hasConflict and not self.isSoftConflict then
		return "savegame_state_conflicted"
	elseif self.uploadState == UploadState.UPLOADED then
		return "savegame_state_uploaded"
	elseif self.uploadState == UploadState.NOT_UPLOADED then
		return "savegame_state_not_uploaded"
	elseif self.uploadState == UploadState.UPLOADING then
		return "savegame_state_uploading"
	end
end

function FSCareerMissionInfo:setMapId(mapId)
	self.mapId = mapId
	local map = g_mapManager:getMapById(self.mapId)

	if map == nil then
		return false
	end

	self.map = map
	self.mapTitle = map.title
	self.scriptFilename = map.scriptFilename
	self.scriptClass = map.className
	self.mapXMLFilename = map.mapXMLFilename
	self.defaultVehiclesXMLFilename = map.defaultVehiclesXMLFilename
	self.defaultItemsXMLFilename = map.defaultItemsXMLFilename
	self.defaultPlaceablesXMLFilename = map.defaultPlaceablesXMLFilename
	self.customEnvironment = map.customEnvironment
	self.baseDirectory = map.baseDirectory

	return true
end

function FSCareerMissionInfo:updateDifficultyProperties()
	if self.difficulty == 1 then
		self.hasInitiallyOwnedFarmlands = true
		self.initialLoan = 0
		self.initialMoney = 100000
		self.loadDefaultFarm = true
		self.economicDifficulty = 1
	elseif self.difficulty == 2 then
		self.hasInitiallyOwnedFarmlands = false
		self.initialLoan = 0
		self.initialMoney = 1500000
		self.loadDefaultFarm = false
		self.economicDifficulty = 2
	else
		self.hasInitiallyOwnedFarmlands = false
		self.initialLoan = 200000
		self.initialMoney = 500000
		self.loadDefaultFarm = false
		self.economicDifficulty = 3
	end
end

function FSCareerMissionInfo:setDifficulty(difficulty)
	self.difficulty = difficulty

	if self.difficulty == 1 then
		self.stopAndGoBraking = true
		self.trailerFillLimit = false
		self.automaticMotorStartEnabled = true
		self.growthMode = GrowthSystem.MODE.SEASONAL
		self.isSnowEnabled = true
		self.helperBuyFuel = true
		self.helperBuySeeds = true
		self.helperBuyFertilizer = true
		self.helperSlurrySource = 2
		self.helperManureSource = 2
		self.fuelUsageLow = true
		self.plowingRequiredEnabled = false
	elseif self.difficulty == 2 then
		self.stopAndGoBraking = true
		self.trailerFillLimit = false
		self.automaticMotorStartEnabled = true
		self.growthMode = GrowthSystem.MODE.SEASONAL
		self.isSnowEnabled = true
		self.helperBuyFuel = true
		self.helperBuySeeds = true
		self.helperBuyFertilizer = true
		self.helperSlurrySource = 2
		self.helperManureSource = 2
		self.fuelUsageLow = false
	else
		self.stopAndGoBraking = false
		self.trailerFillLimit = false
		self.automaticMotorStartEnabled = false
		self.growthMode = GrowthSystem.MODE.SEASONAL
		self.isSnowEnabled = true
		self.helperBuyFuel = false
		self.helperBuySeeds = false
		self.helperBuyFertilizer = false
		self.helperSlurrySource = 1
		self.helperManureSource = 1
		self.fuelUsageLow = false
	end

	self.buyPriceMultiplier = self:getBuyPriceMultiplier()
	self.sellPriceMultiplier = self:getSellPriceMultiplier()

	self:updateDifficultyProperties()
end

function FSCareerMissionInfo:getIsDensityMapValid(mission)
	return self.isValid and self.densityMapRevision == g_densityMapRevision and self.mapDensityMapRevision == mission.mapDensityMapRevision
end

function FSCareerMissionInfo:getIsTerrainTextureValid(mission)
	return self.isValid and self.terrainTextureRevision == g_terrainTextureRevision and self.mapTerrainTextureRevision == mission.mapTerrainTextureRevision
end

function FSCareerMissionInfo:getIsTerrainLodTextureValid(mission)
	return self.isValid and self.terrainLodTextureRevision == g_terrainLodTextureRevision and self.mapTerrainLodTextureRevision == mission.mapTerrainLodTextureRevision
end

function FSCareerMissionInfo:getAreSplitShapesValid(mission)
	return self.isValid and self.splitShapesRevision == g_splitShapesRevision and self.mapSplitShapesRevision == mission.mapSplitShapesRevision
end

function FSCareerMissionInfo:getIsTipCollisionValid(mission)
	return self.isValid and self.tipCollisionRevision == g_tipCollisionRevision and self.mapTipCollisionRevision == mission.mapTipCollisionRevision
end

function FSCareerMissionInfo:getIsPlacementCollisionValid(mission)
	return self.isValid and self.placementCollisionRevision == g_placementCollisionRevision and self.mapPlacementCollisionRevision == mission.mapPlacementCollisionRevision
end

function FSCareerMissionInfo:getIsNavigationCollisionValid(mission)
	return self.isValid and self.navigationCollisionRevision == g_navigationCollisionRevision and self.mapNavigationCollisionRevision == mission.mapNavigationCollisionRevision
end

function FSCareerMissionInfo:getSellPriceMultiplier()
	return Utils.getNoNil(FSCareerMissionInfo.SELL_PRICE_MULTIPLIER[self.economicDifficulty], 1)
end

function FSCareerMissionInfo:getBuyPriceMultiplier()
	return Utils.getNoNil(FSCareerMissionInfo.BUY_PRICE_MULTIPLIER[self.economicDifficulty], 1)
end

function FSCareerMissionInfo:getIsLoadedFromSavegame()
	return self.isValid
end
