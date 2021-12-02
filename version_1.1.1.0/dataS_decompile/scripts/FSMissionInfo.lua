FSMissionInfo = {}
local FSMissionInfo_mt = Class(FSMissionInfo, MissionInfo)

function FSMissionInfo.new(baseDirectory, customEnvironment, customMt)
	local self = FSMissionInfo:superClass().new(baseDirectory, customEnvironment, customMt or FSMissionInfo_mt)

	return self
end

function FSMissionInfo:loadDefaults()
	FSMissionInfo:superClass().loadDefaults(self)

	self.automaticMotorStartEnabled = true
	self.stopAndGoBraking = true
	self.trailerFillLimit = true
	self.fruitDestruction = Platform.gameplay.defaultFruitDestruction
	self.plowingRequiredEnabled = true
	self.stonesEnabled = true
	self.weedsEnabled = true
	self.limeRequired = true
	self.fuelUsageLow = false
	self.helperBuyFuel = false
	self.helperBuySeeds = false
	self.helperBuyFertilizer = false
	self.helperSlurrySource = 2
	self.helperManureSource = 2
	self.difficulty = 1
	self.economicDifficulty = 2
	self.buyPriceMultiplier = 1
	self.sellPriceMultiplier = 1
	self.fuelUsage = 0
	self.seedUsage = 0
	self.sprayUsage = 0
	self.traveledDistance = 0
	self.workedHectares = 0
	self.cultivatedHectares = 0
	self.sownHectares = 0
	self.sprayedHectares = 0
	self.threshedHectares = 0
	self.revenue = 0
	self.expenses = 0
	self.playTime = 0
	self.creationDate = getDate("%Y-%m-%d")
	self.saveDate = nil
	self.dayTime = 400

	if g_isPresentationVersion then
		self.dayTime = 900
	end

	self.timeScale = Platform.gameplay.defaultTimeScale
	self.timeScaleMultiplier = 1
	self.missionFrequency = 2
	self.isSnowEnabled = true
	self.growthMode = GrowthSystem.MODE.SEASONAL
	self.trafficEnabled = true
	self.dirtInterval = 3
	self.steeringBackSpeed = 5
	self.steeringSensitivity = 1
	self.fieldJobMissionCount = 0
	self.transportMissionCount = 0
	self.fieldJobMissionByNPC = 0
	self.foundHelpIcons = "00000000000000000000"
	self.savegameName = g_i18n:getText("defaultSavegameName")
	self.plantedTreeCount = 0
	self.cutTreeCount = 0
	self.woodTonsSold = 0
	self.treeTypesCut = "000000"
	self.windTurbineCount = 0
end

function FSMissionInfo:getIsDensityMapValid(mission)
	return false
end

function FSMissionInfo:getIsTerrainLodTextureValid(mission)
	return false
end

function FSMissionInfo:getAreSplitShapesValid(mission)
	return false
end

function FSMissionInfo:getIsTipCollisionValid(mission)
	return false
end

function FSMissionInfo:getIsPlacementCollisionValid(mission)
	return false
end

function FSMissionInfo:getIsNavigationCollisionValid(mission)
	return false
end

function FSMissionInfo:getIsLoadedFromSavegame()
	return true
end

function FSMissionInfo:getEffectiveTimeScale()
	return self.timeScale * (self.timeScaleMultiplier or 1)
end
