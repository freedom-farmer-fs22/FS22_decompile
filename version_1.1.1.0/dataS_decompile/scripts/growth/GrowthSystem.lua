GrowthSystem = {}
local GrowthSystem_mt = Class(GrowthSystem)
GrowthSystem.MAX_MS_PER_FRAME = 0.5
GrowthSystem.MODE = {
	SEASONAL = 1,
	DAILY = 2,
	DISABLED = 3
}

function GrowthSystem.new(mission, isServer, customMt)
	local self = setmetatable({}, customMt or GrowthSystem_mt)
	self.mission = mission
	self.isServer = isServer
	self.fieldCropsUpdaters = {}
	self.fieldCropsUpdatersCellSize = 16
	self.growthQueue = {}
	self.currentGrowthPeriod = nil

	return self
end

function GrowthSystem:delete()
	g_messageCenter:unsubscribeAll(self)

	for _, updater in pairs(self.fieldCropsUpdaters) do
		if updater.updater ~= nil then
			delete(updater.updater)

			updater.updater = nil
		end
	end

	if self.weedUpdater ~= nil then
		delete(self.weedUpdater)

		self.weedUpdater = nil
	end

	if self.stoneUpdater ~= nil then
		delete(self.stoneUpdater)

		self.stoneUpdater = nil
	end

	if g_addTestCommands then
		removeConsoleCommand("gsGrowNow")
	end
end

function GrowthSystem:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	self.missionInfo = missionInfo
	self.environment = self.mission.environment
	local filename = Utils.getFilename(getXMLString(mapXmlFile, "map.growth#filename"), baseDirectory)
	local xmlFile = XMLFile.load("growth", filename)

	if not xmlFile then
		Logging.fatal("Could not load '%s' from '%s'", filename, mapXmlFile)
	end

	self:loadGrowthData(xmlFile, "growth")
	xmlFile:delete()

	if g_addTestCommands then
		addConsoleCommand("gsGrowNow", "Force growth on foliage", "consoleCommandGrowNow", self)
	end

	g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.onPeriodChanged, self)
end

function GrowthSystem:loadFromXMLFile(xmlFilename)
	if xmlFilename ~= nil then
		local xmlFile = XMLFile.load("environment", xmlFilename)
		self.currentGrowthPeriod = xmlFile:getInt("environment.growth#currentPeriod")

		xmlFile:iterate("environment.growth.queue.period", function (_, key)
			local period = xmlFile:getInt(key)

			table.insert(self.growthQueue, period)
		end)
		xmlFile:delete()
	end

	if self.currentGrowthPeriod ~= nil then
		self:setMonthEngineState(self.currentGrowthPeriod)

		self.numEngineStepsActive = 0

		for _, updater in pairs(self.fieldCropsUpdaters) do
			if setApplyCropsGrowthFinishedCallback(updater.updater, "onEngineStepFinished", self) then
				self.numEngineStepsActive = self.numEngineStepsActive + 1

				setApplyCropsGrowthMaxTimePerFrame(updater.updater, GrowthSystem.MAX_MS_PER_FRAME)
			end
		end

		if self.weedUpdater ~= nil and self.missionInfo.weedsEnabled and setDensityMapUpdaterApplyFinishedCallback(self.weedUpdater, "onEngineStepFinished", self) then
			self.numEngineStepsActive = self.numEngineStepsActive + 1

			setDensityMapUpdaterApplyMaxTimePerFrame(self.weedUpdater, GrowthSystem.MAX_MS_PER_FRAME)
		end

		if self.stoneUpdater ~= nil and self.missionInfo.stonesEnabled and setDensityMapUpdaterApplyFinishedCallback(self.stoneUpdater, "onEngineStepFinished", self) then
			self.numEngineStepsActive = self.numEngineStepsActive + 1

			setDensityMapUpdaterApplyMaxTimePerFrame(self.stoneUpdater, GrowthSystem.MAX_MS_PER_FRAME)
		end

		if self.numEngineStepsActive == 0 then
			self.currentGrowthPeriod = nil
		end
	end

	self:setGrowthEnabled(true)
end

function GrowthSystem:saveToXMLFile(file, key)
	local xmlFile = XMLFile.wrap(file)

	if self.currentGrowthPeriod ~= nil then
		xmlFile:setInt("environment.growth#currentPeriod", self.currentGrowthPeriod)
	end

	xmlFile:setSortedTable("environment.growth.queue.period", self.growthQueue, function (periodKey, value)
		xmlFile:setInt(periodKey, value)
	end)
	xmlFile:delete()
end

function GrowthSystem:saveState(directory)
	for filename, updater in pairs(self.fieldCropsUpdaters) do
		saveCropsGrowthStateToFile(updater.updater, directory .. "/" .. filename .. "_growthState.xml")
	end

	if self.weedUpdater ~= nil then
		saveDensityMapUpdaterStateToFile(self.weedUpdater, directory .. "/weed_growthState.xml")
	end

	if self.stoneUpdater ~= nil then
		saveDensityMapUpdaterStateToFile(self.stoneUpdater, directory .. "/stone_growthState.xml")
	end
end

function GrowthSystem:onTerrainLoad(terrainRootNode)
	if not self.isServer then
		return
	end

	local mission = self.mission
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
	local weedSystem = self.mission.weedSystem

	if weedSystem:getMapHasWeed() then
		local densityMap, firstChannel, numChannels, minValue, maxValue = weedSystem:getDensityMapData()
		self.weedUpdater = createDensityMapUpdater(weedSystem.name, densityMap, firstChannel, numChannels, minValue, maxValue, 0, 0, 0, 0, 0)

		setDensityMapUpdaterMask(self.weedUpdater, groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels)
	end

	local stoneSystem = self.mission.stoneSystem

	if stoneSystem:getMapHasStones() then
		local densityMap, firstChannel, numChannels = stoneSystem:getDensityMapData()
		local minValue, maxValue = stoneSystem:getMinMaxValues()
		self.stoneUpdater = createDensityMapUpdater(stoneSystem.name, densityMap, firstChannel, numChannels, minValue, maxValue, 0, 0, 0, 0, 0)
	end

	for _, updater in pairs(self.fieldCropsUpdaters) do
		local constr = FieldCropsUpdaterConstructor.new(self.fieldCropsUpdatersCellSize)

		for name, id in pairs(updater.ids) do
			local fruitType = g_fruitTypeManager:getFruitTypeByName(name)
			local groundTypeChangedValue = mission.fieldGroundSystem:getFieldGroundValue(fruitType.groundTypeChangeType)
			local groundTypeChangeMask = bitNOT(0)

			if #fruitType.groundTypeChangeMaskTypes > 0 then
				groundTypeChangeMask = 0

				for _, v in ipairs(fruitType.groundTypeChangeMaskTypes) do
					groundTypeChangeMask = bitOR(groundTypeChangeMask, bitShiftLeft(1, v))
				end
			end

			constr:addCropType(id, fruitType.numGrowthStates, 0, fruitType.resetsSpray, fruitType.groundTypeChangeGrowthState, groundTypeChangedValue, groundTypeChangeMask)
		end

		constr:setGroundTerrainDetail(sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels, groundTypeFirstChannel, groundTypeNumChannels)

		updater.updater = constr:finalize("CropsUpdater")
	end

	self:setGrowthEnabled(false)

	if self.missionInfo.isValid and self.missionInfo.densityMapRevision == g_densityMapRevision then
		local dir = self.missionInfo.savegameDirectory

		for filename, updater in pairs(self.fieldCropsUpdaters) do
			loadCropsGrowthStateFromFile(updater.updater, dir .. "/" .. filename .. "_growthState.xml")
		end

		if self.weedUpdater ~= nil then
			loadDensityMapUpdaterStateFromFile(self.weedUpdater, dir .. "/weed_growthState.xml")
		end

		if self.stoneUpdater ~= nil then
			loadDensityMapUpdaterStateFromFile(self.stoneUpdater, dir .. "/stone_growthState.xml")
		end
	end
end

function GrowthSystem:setFruitLayer(mapName, fruitType, layerName, id)
	if self.fieldCropsUpdaters[mapName] == nil then
		self.fieldCropsUpdaters[mapName] = {
			ids = {}
		}
	end

	local updater = self.fieldCropsUpdaters[mapName]
	updater.ids[fruitType.layerName] = id
end

function GrowthSystem:loadGrowthData(xmlFile, root)
	self.seasonalFruitData = {}
	self.nonSeasonalFruitData = {}

	xmlFile:iterate(root .. ".seasonal.fruit", function (_, fruitKey)
		local fruitName = xmlFile:getString(fruitKey .. "#name")

		if fruitName == nil then
			Logging.error("Fruit name is missing at %s", fruitKey)

			return
		end

		local fruitDesc = g_fruitTypeManager:getFruitTypeByName(fruitName)

		if fruitDesc == nil then
			Logging.error("Fruit with name '%s' does not exist at %s", fruitName, fruitKey)

			return
		end

		local initialState = self:parseRange(fruitDesc, xmlFile:getString(fruitKey .. "#initialState"))
		self.seasonalFruitData[fruitDesc.index] = {
			initialState = initialState
		}
		local fruitData = self.seasonalFruitData[fruitDesc.index]

		xmlFile:iterate(fruitKey .. ".period", function (_, periodKey)
			local period = xmlFile:getInt(periodKey .. "#index")

			if period == nil or period < 1 or period > 12 then
				Logging.xmlError(xmlFile, "Invalid period for '%s'", periodKey)

				return
			end

			local info = {
				plantingAllowed = xmlFile:getBool(periodKey .. "#plantingAllowed", false),
				growthMapping = {}
			}
			fruitData[period] = info

			for state = 1, fruitDesc.witheredState do
				info.growthMapping[state] = state
			end

			info.growthMapping[fruitDesc.cutState] = fruitDesc.cutState

			xmlFile:iterate(periodKey .. ".update", function (_, updateKey)
				local range = self:parseRange(fruitDesc, xmlFile:getString(updateKey .. "#range"))

				if range == nil then
					Logging.xmlError(xmlFile, "Update action of fruit growth definition is missing range", updateKey)

					return
				end

				local add = xmlFile:getInt(updateKey .. "#add")

				if add ~= nil then
					for state = range[1], range[2] do
						info.growthMapping[state] = state + add
					end
				else
					local set = self:parseStateValue(fruitDesc, xmlFile:getString(updateKey .. "#set"))

					if set ~= nil then
						for state = range[1], range[2] do
							info.growthMapping[state] = set
						end
					end
				end
			end)
		end)

		for period = 1, 12 do
			if fruitData[period].plantingAllowed then
				local state = 1

				for offset = 0, 24 do
					local currentPeriod = (period + offset - 1) % 12 + 1

					if fruitDesc.minHarvestingGrowthState <= state and state <= fruitDesc.maxHarvestingGrowthState then
						fruitData[currentPeriod].harvestPossible = true
					elseif fruitDesc.minPreparingGrowthState <= state and state <= fruitDesc.maxPreparingGrowthState then
						fruitData[currentPeriod].harvestPossible = true
					elseif state == fruitDesc.witheredState then
						break
					end

					local mapping = fruitData[currentPeriod].growthMapping
					state = mapping[state]
				end
			end
		end
	end)
	xmlFile:iterate(root .. ".nonSeasonal.fruit", function (_, fruitKey)
		local fruitName = xmlFile:getString(fruitKey .. "#name")

		if fruitName == nil then
			Logging.xmlError(xmlFile, "Fruit name is missing at %s", fruitKey)

			return
		end

		local fruitDesc = g_fruitTypeManager:getFruitTypeByName(fruitName)

		if fruitDesc == nil then
			Logging.xmlError(xmlFile, "Fruit with name '%s' does not exist at %s", fruitName, fruitKey)

			return
		end

		local fruitData = {
			growthMapping = {}
		}

		for state = 1, fruitDesc.witheredState do
			fruitData.growthMapping[state] = state
		end

		xmlFile:iterate(fruitKey .. ".update", function (_, updateKey)
			local range = self:parseRange(fruitDesc, xmlFile:getString(updateKey .. "#range"))

			if range == nil then
				Logging.xmlError(xmlFile, "Update action of fruit growth definition is missing range", updateKey)

				return
			end

			local add = xmlFile:getInt(updateKey .. "#add")

			if add ~= nil then
				for state = range[1], range[2] do
					fruitData.growthMapping[state] = state + add
				end
			else
				local set = self:parseStateValue(fruitDesc, xmlFile:getString(updateKey .. "#set"))

				if set ~= nil then
					for state = range[1], range[2] do
						fruitData.growthMapping[state] = set
					end
				end
			end
		end)

		self.nonSeasonalFruitData[fruitDesc.index] = fruitData
	end)
end

function GrowthSystem:parseRange(fruitDesc, str)
	if str == nil then
		return nil
	end

	local min, max = nil
	local items = str:split("-")

	if #items == 0 or #items > 2 then
		return nil
	end

	min = self:parseStateValue(fruitDesc, items[1])

	if #items == 2 then
		max = self:parseStateValue(fruitDesc, items[2])
	else
		max = min
	end

	return {
		min,
		max
	}
end

function GrowthSystem:parseStateValue(fruitDesc, str)
	if str == nil then
		return nil
	end

	str = str:lower()

	if str == "max" then
		return fruitDesc.numGrowthStates
	elseif str == "cut" then
		return fruitDesc.cutState + 1
	elseif str == "withered" then
		return fruitDesc.witheredState
	end

	local num = tonumber(str)

	if num == nil then
		return nil
	end

	return math.floor(num)
end

function GrowthSystem:update(dt)
end

function GrowthSystem:onPeriodChanged()
	local transitionPeriod = self.environment.currentPeriod - 1

	if transitionPeriod == 0 then
		transitionPeriod = 12
	end

	self:triggerGrowth(transitionPeriod)
end

function GrowthSystem:setMonthEngineState(period)
	for _, updater in pairs(self.fieldCropsUpdaters) do
		for name, id in pairs(updater.ids) do
			local fruitType = g_fruitTypeManager:getFruitTypeByName(name)

			if self.missionInfo.growthMode == GrowthSystem.MODE.SEASONAL then
				if self.seasonalFruitData[fruitType.index] ~= nil then
					local mapping = self.seasonalFruitData[fruitType.index][period].growthMapping

					for from = 1, #mapping do
						setCropsGrowthNextState(updater.updater, id, from, mapping[from])
					end
				end
			elseif self.missionInfo.growthMode == GrowthSystem.MODE.DAILY then
				local customGrowthData = self.nonSeasonalFruitData[fruitType.index]

				if customGrowthData == nil then
					for from = 1, fruitType.numGrowthStates - 1 do
						setCropsGrowthNextState(updater.updater, id, from, from + 1)
					end

					if fruitType.regrows then
						setCropsGrowthNextState(updater.updater, id, fruitType.cutState, fruitType.firstRegrowthState)
					end
				else
					local mapping = customGrowthData.growthMapping

					for from = 1, #mapping do
						setCropsGrowthNextState(updater.updater, id, from, mapping[from])
					end
				end
			end
		end
	end

	if self.weedUpdater ~= nil then
		for from, to in pairs(self.mission.weedSystem:getGrowthMapping()) do
			setDensityMapUpdaterNextValue(self.weedUpdater, 0, from, to)
		end
	end

	if self.stoneUpdater ~= nil then
		for _, mapping in ipairs(self.mission.stoneSystem:getGrowthMapping()) do
			if mapping.period == period then
				setDensityMapUpdaterNextValue(self.stoneUpdater, 0, mapping.from, mapping.to)
			end
		end
	end
end

function GrowthSystem:triggerGrowth(period)
	if self.currentGrowthPeriod ~= nil then
		self.growthQueue[#self.growthQueue + 1] = period
	else
		self:startEngineGrowth(period)
	end
end

function GrowthSystem:startEngineGrowth(period)
	Logging.devInfo("GrowthSystem:startEngineGrowth %d - Pending growth tasks %d", period, #self.growthQueue)
	self:setMonthEngineState(period)

	self.currentGrowthPeriod = period
	self.numEngineStepsActive = 0

	if self.missionInfo.growthMode == GrowthSystem.MODE.DISABLED then
		self:onEngineGrowthFinished()

		return
	end

	for _, updater in pairs(self.fieldCropsUpdaters) do
		self.numEngineStepsActive = self.numEngineStepsActive + 1

		applyCropsGrowth(updater.updater, "onEngineStepFinished", self, GrowthSystem.MAX_MS_PER_FRAME)
	end

	if self.weedUpdater ~= nil and self.missionInfo.weedsEnabled then
		self.numEngineStepsActive = self.numEngineStepsActive + 1

		applyDensityMapUpdater(self.weedUpdater, "onEngineStepFinished", self, GrowthSystem.MAX_MS_PER_FRAME)
	end

	if self.stoneUpdater ~= nil and self.missionInfo.stonesEnabled then
		self.numEngineStepsActive = self.numEngineStepsActive + 1

		applyDensityMapUpdater(self.stoneUpdater, "onEngineStepFinished", self, GrowthSystem.MAX_MS_PER_FRAME)
	end

	self:performScriptBasedGrowth(period)
end

function GrowthSystem:onEngineGrowthFinished()
	local finishedPeriod = self.currentGrowthPeriod
	self.currentGrowthPeriod = nil

	if #self.growthQueue > 0 then
		local period = self.growthQueue[1]

		table.remove(self.growthQueue, 1)
		self:startEngineGrowth(period)
	end

	g_messageCenter:publish(MessageType.FINISHED_GROWTH_PERIOD, finishedPeriod)
end

function GrowthSystem:onEngineStepFinished()
	self.numEngineStepsActive = self.numEngineStepsActive - 1

	if self.numEngineStepsActive == 0 then
		self:onEngineGrowthFinished()
	end
end

function GrowthSystem:performScriptBasedGrowth(period)
end

function GrowthSystem:setGrowthMode(mode, noEventSend)
	if self.missionInfo.growthMode ~= mode then
		self.missionInfo.growthMode = mode

		SavegameSettingsEvent.sendEvent(noEventSend)
		Logging.info("Savegame Setting 'growthMode': %d", mode)
	end
end

function GrowthSystem:getGrowthMode()
	return self.missionInfo.growthMode
end

function GrowthSystem:setGrowthMask(map, firstChannel, numChannels)
	for _, updater in pairs(self.fieldCropsUpdaters) do
		if updater.updater ~= nil then
			setCropsGrowthMask(updater.updater, map, firstChannel, numChannels)
		end
	end

	if self.weedUpdater ~= nil then
		setDensityMapUpdaterMask(self.weedUpdater, map, firstChannel, numChannels)
	end
end

function GrowthSystem:resetGrowthMask()
	self:setGrowthMask(0, 0, 0)
end

function GrowthSystem:setIgnoreDensityChanges(ignore)
end

function GrowthSystem:setIsGamePaused(isPaused)
end

function GrowthSystem:setGrowthEnabled(isEnabled)
	self.growthEnabled = isEnabled

	for _, updater in pairs(self.fieldCropsUpdaters) do
		if updater.updater ~= nil then
			setCropsEnableGrowth(updater.updater, isEnabled)
		end
	end

	if self.weedUpdater ~= nil then
		setDensityMapUpdaterEnabled(self.weedUpdater, isEnabled)
	end
end

function GrowthSystem:onWeedGrowthChanged()
end

function GrowthSystem:canFruitBePlanted(fruitIndex, period)
	if self.missionInfo.growthMode ~= GrowthSystem.MODE.SEASONAL then
		return true
	end

	if period == nil then
		period = self.environment.currentPeriod
	end

	local fruitData = self.seasonalFruitData[fruitIndex]

	if fruitData == nil then
		return false
	end

	return fruitData[period].plantingAllowed
end

function GrowthSystem:canFruitBeHarvested(fruitIndex, period)
	if self.missionInfo.growthMode ~= GrowthSystem.MODE.SEASONAL then
		return true
	end

	local fruitData = self.seasonalFruitData[fruitIndex]

	if fruitData == nil then
		return false
	end

	return fruitData[period].harvestPossible
end

function GrowthSystem:getRandomInitialState(fruitIndex)
	if self.missionInfo.growthMode == GrowthSystem.MODE.SEASONAL then
		if self.seasonalFruitData[fruitIndex] == nil then
			return nil
		end

		local initialState = self.seasonalFruitData[fruitIndex].initialState

		if initialState == nil then
			return nil
		end

		if initialState[2] == 0 then
			return nil
		else
			return math.random(initialState[1], initialState[2])
		end
	else
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitIndex)

		return math.random(1, fruitDesc.numGrowthStates)
	end
end

function GrowthSystem:consoleCommandGrowNow(period)
	local usage = "Usage: gsGrowNow period(1..12)"
	period = tonumber(period)

	if period ~= nil then
		self:triggerGrowth(period)

		return "Triggered growth"
	else
		return "Error: No period given. " .. usage
	end
end
