FarmStats = {}
local FarmStats_mt = Class(FarmStats)
FarmStats.STAT_NAMES = {
	"fuelUsage",
	"seedUsage",
	"sprayUsage",
	"traveledDistance",
	"workedHectares",
	"cultivatedHectares",
	"plowedHectares",
	"sownHectares",
	"sprayedHectares",
	"threshedHectares",
	"weededHectares",
	"workedTime",
	"cultivatedTime",
	"plowedTime",
	"sownTime",
	"sprayedTime",
	"threshedTime",
	"weededTime",
	"baleCount",
	"breedCowsCount",
	"breedPigsCount",
	"breedSheepCount",
	"breedChickenCount",
	"breedHorsesCount",
	"revenue",
	"expenses",
	"playTime",
	"workersHired",
	"storedBales",
	"fieldJobMissionCount",
	"fieldJobMissionByNPC",
	"transportMissionCount",
	"plantedTreeCount",
	"cutTreeCount",
	"woodTonsSold",
	"treeTypesCut",
	"windTurbineCount",
	"petDogCount",
	"tractorDistance",
	"carDistance",
	"truckDistance",
	"horseDistance",
	"horseJumpCount",
	"repairVehicleCount",
	"repaintVehicleCount",
	"soldCottonBales",
	"wrappedBales"
}
FarmStats.HERO_STAT_NAMES = {
	"playTime",
	"moneyEarned",
	"traveledDistance",
	"completedMissions",
	"threshedHectares"
}

function FarmStats.new()
	local self = {}

	setmetatable(self, FarmStats_mt)

	self.statistics = {}

	for _, statName in pairs(FarmStats.STAT_NAMES) do
		self.statistics[statName] = {
			session = 0,
			total = 0
		}
	end

	self.statistics.treeTypesCut = "000000"
	self.finances = FinanceStats.new()
	self.financesHistory = {}
	self.heroStats = {}

	for _, heroStat in pairs(FarmStats.HERO_STAT_NAMES) do
		self.heroStats[heroStat] = {
			accumValue = 0
		}
	end

	self.heroStatsLoaded = false
	self.moneyEarnedHeroAccum = 0
	self.nextHeroAccumUpdate = 0

	if g_currentMission:getIsServer() then
		g_currentMission:addUpdateable(self)
	end

	self.financesVersionCounter = 0
	self.financesHistoryVersionCounter = 0
	self.financesHistoryVersionCounterLocal = 0
	self.updatePlayTime = true

	return self
end

function FarmStats:delete()
	g_currentMission:removeUpdateable(self)
end

function FarmStats:saveToXMLFile(xmlFile, key)
	xmlFile:setFloat(key .. ".statistics.traveledDistance", self.statistics.traveledDistance.total)
	xmlFile:setFloat(key .. ".statistics.fuelUsage", self.statistics.fuelUsage.total)
	xmlFile:setFloat(key .. ".statistics.seedUsage", self.statistics.seedUsage.total)
	xmlFile:setFloat(key .. ".statistics.sprayUsage", self.statistics.sprayUsage.total)
	xmlFile:setFloat(key .. ".statistics.workedHectares", self.statistics.workedHectares.total)
	xmlFile:setFloat(key .. ".statistics.cultivatedHectares", self.statistics.cultivatedHectares.total)
	xmlFile:setFloat(key .. ".statistics.sownHectares", self.statistics.sownHectares.total)
	xmlFile:setFloat(key .. ".statistics.sprayedHectares", self.statistics.sprayedHectares.total)
	xmlFile:setFloat(key .. ".statistics.threshedHectares", self.statistics.threshedHectares.total)
	xmlFile:setFloat(key .. ".statistics.plowedHectares", self.statistics.plowedHectares.total)
	xmlFile:setFloat(key .. ".statistics.workedTime", self.statistics.workedTime.total)
	xmlFile:setFloat(key .. ".statistics.cultivatedTime", self.statistics.cultivatedTime.total)
	xmlFile:setFloat(key .. ".statistics.sownTime", self.statistics.sownTime.total)
	xmlFile:setFloat(key .. ".statistics.sprayedTime", self.statistics.sprayedTime.total)
	xmlFile:setFloat(key .. ".statistics.threshedTime", self.statistics.threshedTime.total)
	xmlFile:setFloat(key .. ".statistics.plowedTime", self.statistics.plowedTime.total)
	xmlFile:setInt(key .. ".statistics.baleCount", self.statistics.baleCount.total)
	xmlFile:setInt(key .. ".statistics.breedCowsCount", self.statistics.breedCowsCount.total)
	xmlFile:setInt(key .. ".statistics.breedSheepCount", self.statistics.breedSheepCount.total)
	xmlFile:setInt(key .. ".statistics.breedPigsCount", self.statistics.breedPigsCount.total)
	xmlFile:setInt(key .. ".statistics.breedChickenCount", self.statistics.breedChickenCount.total)
	xmlFile:setInt(key .. ".statistics.breedHorsesCount", self.statistics.breedHorsesCount.total)
	xmlFile:setInt(key .. ".statistics.fieldJobMissionCount", self.statistics.fieldJobMissionCount.total)
	xmlFile:setInt(key .. ".statistics.fieldJobMissionByNPC", self.statistics.fieldJobMissionByNPC.total)
	xmlFile:setInt(key .. ".statistics.transportMissionCount", self.statistics.transportMissionCount.total)
	xmlFile:setFloat(key .. ".statistics.revenue", self.statistics.revenue.total)
	xmlFile:setFloat(key .. ".statistics.expenses", self.statistics.expenses.total)
	xmlFile:setFloat(key .. ".statistics.playTime", self.statistics.playTime.total)
	xmlFile:setInt(key .. ".statistics.plantedTreeCount", self.statistics.plantedTreeCount.total)
	xmlFile:setInt(key .. ".statistics.cutTreeCount", self.statistics.cutTreeCount.total)
	xmlFile:setFloat(key .. ".statistics.woodTonsSold", self.statistics.woodTonsSold.total)
	xmlFile:setString(key .. ".statistics.treeTypesCut", self.statistics.treeTypesCut)
	xmlFile:setInt(key .. ".statistics.petDogCount", self.statistics.petDogCount.total)
	xmlFile:setInt(key .. ".statistics.repairVehicleCount", self.statistics.repairVehicleCount.total)
	xmlFile:setInt(key .. ".statistics.repaintVehicleCount", self.statistics.repaintVehicleCount.total)
	xmlFile:setInt(key .. ".statistics.horseJumpCount", self.statistics.horseJumpCount.total)
	xmlFile:setInt(key .. ".statistics.soldCottonBales", self.statistics.soldCottonBales.total)
	xmlFile:setInt(key .. ".statistics.wrappedBales", self.statistics.wrappedBales.total)
	xmlFile:setFloat(key .. ".statistics.tractorDistance", self.statistics.tractorDistance.total)
	xmlFile:setFloat(key .. ".statistics.carDistance", self.statistics.carDistance.total)
	xmlFile:setFloat(key .. ".statistics.truckDistance", self.statistics.truckDistance.total)
	xmlFile:setFloat(key .. ".statistics.horseDistance", self.statistics.horseDistance.total)

	local toSave = {
		self.finances
	}
	local numHistoricItems = #self.financesHistory

	for n = 3, 0, -1 do
		if n < numHistoricItems then
			table.insert(toSave, self.financesHistory[numHistoricItems - n])
		end
	end

	xmlFile:setSortedTable(key .. ".finances.stats", toSave, function (statsKey, finances, day)
		xmlFile:setInt(statsKey .. "#day", day - 1)
		finances:saveToXMLFile(xmlFile, statsKey)
	end)
end

function FarmStats:loadFromXMLFile(xmlFile, rootKey)
	local key = rootKey .. ".statistics"
	self.statistics.traveledDistance.total = xmlFile:getFloat(key .. ".traveledDistance", 0)
	self.statistics.fuelUsage.total = xmlFile:getFloat(key .. ".fuelUsage", 0)
	self.statistics.seedUsage.total = xmlFile:getFloat(key .. ".seedUsage", 0)
	self.statistics.sprayUsage.total = xmlFile:getFloat(key .. ".sprayUsage", 0)
	self.statistics.workedHectares.total = xmlFile:getFloat(key .. ".workedHectares", 0)
	self.statistics.cultivatedHectares.total = xmlFile:getFloat(key .. ".cultivatedHectares", 0)
	self.statistics.sownHectares.total = xmlFile:getFloat(key .. ".sownHectares", 0)
	self.statistics.sprayedHectares.total = xmlFile:getFloat(key .. ".sprayedHectares", 0)
	self.statistics.threshedHectares.total = xmlFile:getFloat(key .. ".threshedHectares", 0)
	self.statistics.weededHectares.total = xmlFile:getFloat(key .. ".weededHectares", 0)
	self.statistics.plowedHectares.total = xmlFile:getFloat(key .. ".plowedHectares", 0)
	self.statistics.workedTime.total = xmlFile:getFloat(key .. ".workedTime", 0)
	self.statistics.cultivatedTime.total = xmlFile:getFloat(key .. ".cultivatedTime", 0)
	self.statistics.sownTime.total = xmlFile:getFloat(key .. ".sownTime", 0)
	self.statistics.sprayedTime.total = xmlFile:getFloat(key .. ".sprayedTime", 0)
	self.statistics.threshedTime.total = xmlFile:getFloat(key .. ".threshedTime", 0)
	self.statistics.weededTime.total = xmlFile:getFloat(key .. ".weededTime", 0)
	self.statistics.plowedTime.total = xmlFile:getFloat(key .. ".plowedTime", 0)
	self.statistics.baleCount.total = xmlFile:getInt(key .. ".baleCount", 0)
	self.statistics.breedCowsCount.total = xmlFile:getInt(key .. ".breedCowsCount", 0)
	self.statistics.breedSheepCount.total = xmlFile:getInt(key .. ".breedSheepCount", 0)
	self.statistics.breedPigsCount.total = xmlFile:getInt(key .. ".breedPigsCount", 0)
	self.statistics.breedChickenCount.total = xmlFile:getInt(key .. ".breedChickenCount", 0)
	self.statistics.breedHorsesCount.total = xmlFile:getInt(key .. ".breedHorsesCount", 0)
	self.statistics.fieldJobMissionCount.total = xmlFile:getInt(key .. ".fieldJobMissionCount", 0)
	self.statistics.fieldJobMissionByNPC.total = xmlFile:getInt(key .. ".fieldJobMissionByNPC", 0)
	self.statistics.transportMissionCount.total = xmlFile:getInt(key .. ".transportMissionCount", 0)
	self.statistics.plantedTreeCount.total = xmlFile:getInt(key .. ".plantedTreeCount", 0)
	self.statistics.cutTreeCount.total = xmlFile:getInt(key .. ".cutTreeCount", 0)
	self.statistics.woodTonsSold.total = xmlFile:getFloat(key .. ".woodTonsSold", 0)
	self.statistics.treeTypesCut = xmlFile:getString(key .. ".treeTypesCut", "000000")
	self.statistics.revenue.total = xmlFile:getFloat(key .. ".revenue", 0)
	self.statistics.expenses.total = xmlFile:getFloat(key .. ".expenses", 0)
	self.statistics.playTime.total = xmlFile:getFloat(key .. ".playTime", 0)
	self.statistics.petDogCount.total = xmlFile:getInt(key .. ".petDogCount", 0)
	self.statistics.repaintVehicleCount.total = xmlFile:getInt(key .. ".repaintVehicleCount", 0)
	self.statistics.repairVehicleCount.total = xmlFile:getInt(key .. ".repairVehicleCount", 0)
	self.statistics.tractorDistance.total = xmlFile:getFloat(key .. ".tractorDistance", 0)
	self.statistics.carDistance.total = xmlFile:getFloat(key .. ".carDistance", 0)
	self.statistics.truckDistance.total = xmlFile:getFloat(key .. ".truckDistance", 0)
	self.statistics.horseDistance.total = xmlFile:getFloat(key .. ".horseDistance", 0)
	self.statistics.horseJumpCount.total = xmlFile:getInt(key .. ".horseJumpCount", 0)
	self.statistics.soldCottonBales.total = xmlFile:getInt(key .. ".soldCottonBales", 0)
	self.statistics.wrappedBales.total = xmlFile:getInt(key .. ".wrappedBales", 0)

	xmlFile:iterate(rootKey .. ".finances.stats", function (day, financeKey)
		local finances = FinanceStats.new()

		finances:loadFromXMLFile(xmlFile, financeKey)

		if day == 1 then
			self.finances = finances
		else
			table.insert(self.financesHistory, finances)
		end
	end)
end

function FarmStats:update(dt)
	if GS_PLATFORM_XBOX or GS_PLATFORM_GGP then
		if not self.heroStatsLoaded and areStatsAvailable() then
			self.heroStatsLoaded = true

			for heroStatName, heroStat in pairs(self.heroStats) do
				heroStat.id = statsGetIndex(heroStatName)
				heroStat.value = statsGet(heroStat.id)

				if heroStat.accumValue ~= 0 then
					heroStat.value = heroStat.value + heroStat.accumValue

					statsSet(heroStat.id, heroStat.value)

					heroStat.accumValue = 0
				end
			end
		end

		if self.nextHeroAccumUpdate <= g_time and self.moneyEarnedHeroAccum > 0 then
			self:addValueToHeroStat("moneyEarned", self.moneyEarnedHeroAccum)

			self.moneyEarnedHeroAccum = 0
			self.nextHeroAccumUpdate = g_time + 10000
		end
	end

	self:updateStats("playTime", dt / 60000, self.updatePlayTime)
end

function FarmStats:addValueToHeroStat(name, value)
	local heroStat = self.heroStats[name]

	if self.heroStatsLoaded then
		heroStat.value = heroStat.value + value

		statsSet(heroStat.id, heroStat.value)
	else
		heroStat.accumValue = heroStat.accumValue + value
	end
end

function FarmStats:changeFinanceStats(amount, statType)
	if statType ~= nil and self.finances[statType] ~= nil then
		self.finances[statType] = self.finances[statType] + amount

		if g_currentMission:getIsServer() then
			self.financesVersionCounter = self.financesVersionCounter + 1

			if self.financesVersionCounter > 999999 then
				self.financesVersionCounter = 0
			end
		end
	end
end

function FarmStats:archiveFinances()
	if g_currentMission:getIsServer() then
		table.insert(self.financesHistory, self.finances)

		self.finances = FinanceStats.new()
		self.financesVersionCounter = self.financesVersionCounter + 1

		if self.financesVersionCounter > 999999 then
			self.financesVersionCounter = 0
		end

		self.financesHistoryVersionCounter = self.financesHistoryVersionCounter + 1

		if self.financesHistoryVersionCounter > 127 then
			self.financesHistoryVersionCounter = 0
		end
	end
end

function FarmStats:getCompletedFieldMissions()
	return self:getTotalValue("fieldJobMissionCount")
end

function FarmStats:getCompletedFieldMissionsSession()
	return self:getSessionValue("fieldJobMissionCount")
end

function FarmStats:getCompletedTransportMissions()
	return self:getTotalValue("transportMissionCount")
end

function FarmStats:getCompletedTransportMissionsSession()
	return self:getSessionValue("transportMissionCount")
end

function FarmStats:getCompletedMissions()
	return self:getTotalValue("fieldJobMissionCount") + self:getTotalValue("transportMissionCount")
end

function FarmStats:getCompletedMissionsSession()
	return self:getSessionValue("fieldJobMissionCount") + self:getSessionValue("transportMissionCount")
end

function FarmStats:updateStats(statName, delta, ignoreHeroStats)
	local total, session = nil

	if delta == nil then
		printCallstack()
	end

	if self.statistics[statName] ~= nil then
		self.statistics[statName].session = self.statistics[statName].session + delta
		session = self.statistics[statName].session

		if self.statistics[statName].total ~= nil then
			self.statistics[statName].total = self.statistics[statName].total + delta
			total = self.statistics[statName].total
		end
	else
		print("Error: Invalid statistic '" .. statName .. "'")
	end

	if ignoreHeroStats == nil or not ignoreHeroStats then
		self:addHeroStat(statName, delta)
	end

	return total, session
end

function FarmStats:addHeroStat(statName, delta)
	if self.heroStats[statName] ~= nil then
		if statName == "moneyEarned" then
			self.moneyEarnedHeroAccum = self.moneyEarnedHeroAccum + delta
		else
			self:addValueToHeroStat(statName, delta)
		end
	elseif statName == "fieldJobMissionCount" or statName == "transportMissionCount" then
		self:addValueToHeroStat("completedMissions", delta)
	end
end

function FarmStats:getTotalValue(statName)
	if self.statistics[statName] ~= nil then
		return self.statistics[statName].total
	end

	return nil
end

function FarmStats:getSessionValue(statName)
	if self.statistics[statName] ~= nil then
		return self.statistics[statName].session
	end

	return nil
end

function FarmStats:updateTreeTypesCut(splitTypeName)
	local trees = {
		"oak",
		"birch",
		"maple",
		{
			"spruce",
			"pine"
		},
		"poplar",
		"ash"
	}

	for i, treeName in ipairs(trees) do
		local treeMatch = false

		if type(treeName) == "table" then
			for _, subTreeName in pairs(treeName) do
				if splitTypeName == subTreeName then
					treeMatch = true
				end
			end
		elseif splitTypeName == treeName then
			treeMatch = true
		end

		if treeMatch then
			local stats = self.statistics
			stats.treeTypesCut = string.sub(stats.treeTypesCut, 1, i - 1) .. "1" .. string.sub(stats.treeTypesCut, i + 1, string.len(stats.treeTypesCut))
		end
	end
end

function FarmStats:updateFieldJobsDone(npcIndex)
	self:updateStats("fieldJobMissionCount", 1)

	local npcValue = 2^npcIndex
	self.statistics.fieldJobMissionByNPC.total = bitOR(self.statistics.fieldJobMissionByNPC.total, npcValue)

	self:updateJobAchievements()
end

function FarmStats:updateTransportJobsDone()
	self:updateStats("transportMissionCount", 1)
	self:updateJobAchievements()
end

function FarmStats:updateJobAchievements()
	local contractCount = self:getTotalValue("fieldJobMissionCount") + self:getTotalValue("transportMissionCount")

	g_achievementManager:tryUnlock("MissionFirst", contractCount)
	g_achievementManager:tryUnlock("Mission", contractCount)
end

function FarmStats:getStatisticData()
	if not g_currentMission.missionDynamicInfo.isMultiplayer or not g_currentMission.missionDynamicInfo.isClient then
		self:addStatistic("workedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("workedHectares")), g_i18n:getArea(self:getTotalValue("workedHectares")), "%.2f")
		self:addStatistic("cultivatedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("cultivatedHectares")), g_i18n:getArea(self:getTotalValue("cultivatedHectares")), "%.2f")

		if not GS_IS_MOBILE_VERSION then
			self:addStatistic("plowedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("plowedHectares")), g_i18n:getArea(self:getTotalValue("plowedHectares")), "%.2f")
		end

		self:addStatistic("sownHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("sownHectares")), g_i18n:getArea(self:getTotalValue("sownHectares")), "%.2f")
		self:addStatistic("sprayedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("sprayedHectares")), g_i18n:getArea(self:getTotalValue("sprayedHectares")), "%.2f")
		self:addStatistic("threshedHectares", g_i18n:getAreaUnit(false), g_i18n:getArea(self:getSessionValue("threshedHectares")), g_i18n:getArea(self:getTotalValue("threshedHectares")), "%.2f")

		if not GS_IS_MOBILE_VERSION then
			self:addStatistic("workedTime", nil, Utils.formatTime(self:getSessionValue("workedTime")), Utils.formatTime(self:getTotalValue("workedTime")), "%s")
			self:addStatistic("cultivatedTime", nil, Utils.formatTime(self:getSessionValue("cultivatedTime")), Utils.formatTime(self:getTotalValue("cultivatedTime")), "%s")
			self:addStatistic("plowedTime", nil, Utils.formatTime(self:getSessionValue("plowedTime")), Utils.formatTime(self:getTotalValue("plowedTime")), "%s")
			self:addStatistic("sownTime", nil, Utils.formatTime(self:getSessionValue("sownTime")), Utils.formatTime(self:getTotalValue("sownTime")), "%s")
			self:addStatistic("sprayedTime", nil, Utils.formatTime(self:getSessionValue("sprayedTime")), Utils.formatTime(self:getTotalValue("sprayedTime")), "%s")
			self:addStatistic("threshedTime", nil, Utils.formatTime(self:getSessionValue("threshedTime")), Utils.formatTime(self:getTotalValue("threshedTime")), "%s")
		end

		self:addStatistic("traveledDistance", g_i18n:getMeasuringUnit(), g_i18n:getDistance(self:getSessionValue("traveledDistance")), g_i18n:getDistance(self:getTotalValue("traveledDistance")), "%.2f")
		self:addStatistic("fuelUsage", g_i18n:getText("unit_liter"), g_i18n:getFluid(self:getSessionValue("fuelUsage")), g_i18n:getFluid(self:getTotalValue("fuelUsage")), "%.2f")
		self:addStatistic("seedUsage", g_i18n:getText("unit_liter"), g_i18n:getFluid(self:getSessionValue("seedUsage")), g_i18n:getFluid(self:getTotalValue("seedUsage")), "%.2f")
		self:addStatistic("sprayUsage", g_i18n:getText("unit_liter"), g_i18n:getFluid(self:getSessionValue("sprayUsage")), g_i18n:getFluid(self:getTotalValue("sprayUsage")), "%.2f")

		if not GS_IS_MOBILE_VERSION then
			self:addStatistic("baleCount", nil, self:getSessionValue("baleCount"), self:getTotalValue("baleCount"), "%d")
			self:addStatistic("plantedTreeCount", nil, self:getSessionValue("plantedTreeCount"), self:getTotalValue("plantedTreeCount"), "%d")
			self:addStatistic("cutTreeCount", nil, self:getSessionValue("cutTreeCount"), self:getTotalValue("cutTreeCount"), "%d")
			self:addStatistic("fieldJobMissionCount", nil, self:getSessionValue("fieldJobMissionCount"), self:getTotalValue("fieldJobMissionCount"), "%d")

			if #g_missionManager.transportMissions > 0 then
				self:addStatistic("transportMissionCount", nil, self:getSessionValue("transportMissionCount"), self:getTotalValue("transportMissionCount"), "%d")
			end
		end

		self:addStatistic("playTime", nil, Utils.formatTime(self:getSessionValue("playTime")), Utils.formatTime(self:getTotalValue("playTime")), "%s")

		local year = g_currentMission.environment.currentYear

		if Environment.PERIOD.MID_WINTER <= g_currentMission.environment.currentPeriod then
			year = year + 1
		end

		self:addStatistic("yearsPlayed", nil, , year, "%s")
		self:addStatistic("workersHired", nil, self:getSessionValue("workersHired"), nil, "%s")

		if GS_IS_MOBILE_VERSION then
			self:addStatistic("storedBales", nil, self:getSessionValue("storedBales"), nil, "%s")
		end

		if g_currentMission.collectiblesSystem:getIsActive() then
			self:addStatistic("collectibles", nil, , g_currentMission.collectiblesSystem:getTotalCollected() .. " / " .. g_currentMission.collectiblesSystem:getTotalCollectable(), "%s")
		end
	end

	return Utils.getNoNil(self.statisticData, {})
end

function FarmStats:addStatistic(name, unit, valueSession, valueTotal, stringFormat)
	if self.statisticData == nil then
		self.statisticData = {}
		self.statisticDataRev = {}
	end

	local formattedName = g_i18n:getText("statistic_" .. name, g_currentMission.missionInfo.customEnvironment)

	if unit ~= nil then
		formattedName = formattedName .. " [" .. unit .. "]"
	end

	local newDataSet = self.statisticDataRev[name]

	if newDataSet == nil then
		newDataSet = {}
		self.statisticDataRev[name] = newDataSet

		table.insert(self.statisticData, newDataSet)
	end

	newDataSet.name = formattedName
	newDataSet.valueSession = string.format(stringFormat, Utils.getNoNil(valueSession, ""))
	newDataSet.valueTotal = string.format(stringFormat, Utils.getNoNil(valueTotal, ""))
end

function FarmStats:merge(other)
	for _, statName in ipairs(FarmStats.STAT_NAMES) do
		if statName == "treeTypesCut" then
			local cut = self.statistics.treeTypesCut

			for i = 1, string.len(cut) do
				if string.sub(other.statistics.treeTypesCut, i, i) == "1" then
					cut = string.sub(cut, 1, i - 1) .. "1" .. string.sub(cut, i + 1, string.len(cut))
				end
			end

			self.statistics.treeTypesCut = cut
		else
			self.statistics[statName].total = self.statistics[statName].total + other.statistics[statName].total
		end
	end

	self.finances:merge(other.finances)

	return self
end
