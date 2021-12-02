InGameMenuGameSettingsFrame = {}
local InGameMenuGameSettingsFrame_mt = Class(InGameMenuGameSettingsFrame, TabbedMenuFrameElement)
InGameMenuGameSettingsFrame.CONTROLS = {
	"settingsContainer",
	"boxLayout",
	"textSavegameName",
	"multiTimeScale",
	"economicDifficulty",
	"checkTraffic",
	"checkDirt",
	"checkAutoMotorStart",
	"checkStopAndGoBraking",
	"checkTrailerFillLimit",
	"checkFuelUsage",
	"checkHelperRefillFuel",
	"checkHelperRefillSeed",
	"checkHelperRefillFertilizer",
	"checkHelperRefillSlurry",
	"checkHelperRefillManure",
	"checkSnowEnabled",
	"multiGrowthMode",
	"checkFruitDestruction",
	"checkPlowingRequired",
	"checkStonesEnabled",
	"checkLimeRequired",
	"checkWeedsEnabled",
	"multiAutoSaveInterval",
	"buttonPauseGame",
	"multiFixedSeasonalVisuals",
	"multiPlannedDaysPerPeriod"
}

local function NO_CALLBACK()
end

function InGameMenuGameSettingsFrame.new(subclass_mt, l10n)
	local self = InGameMenuGameSettingsFrame:superClass().new(nil, subclass_mt or InGameMenuGameSettingsFrame_mt)

	self:registerControls(InGameMenuGameSettingsFrame.CONTROLS)

	self.l10n = l10n
	self.pageMapOverview = nil
	self.missionInfo = nil
	self.manureLoadingStations = {}
	self.liquidManureLoadingStations = {}
	self.hasMasterRights = false
	self.hasCustomMenuButtons = true

	return self
end

function InGameMenuGameSettingsFrame:copyAttributes(src)
	InGameMenuGameSettingsFrame:superClass().copyAttributes(self, src)

	self.l10n = src.l10n
end

function InGameMenuGameSettingsFrame:initialize(pageMapOverview, onClickBackCallback)
	self.pageMapOverview = pageMapOverview

	self:assignStaticTexts()

	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.saveButton = {
		showWhenPaused = true,
		inputAction = InputAction.MENU_ACTIVATE
	}
	self.quitButton = {
		showWhenPaused = true,
		inputAction = InputAction.MENU_CANCEL,
		text = self.l10n:getText(InGameMenu.L10N_SYMBOL.BUTTON_CANCEL_GAME)
	}
	self.serverSettingsButton = {
		inputAction = InputAction.MENU_EXTRA_1,
		text = self.l10n:getText("button_serverSettings"),
		callback = function ()
			self:onButtonOpenServerSettings()
		end
	}

	if g_isPresentationVersion then
		self.saveButton = nil
	end

	self:updateButtons()

	self.boxLayout.wrapAround = false
	local firstSettingElement = self.boxLayout.elements[1]
	local lastSettingElement = self.boxLayout.elements[#self.boxLayout.elements]
	self.onClickBackCallback = onClickBackCallback or NO_CALLBACK

	FocusManager:linkElements(lastSettingElement, FocusManager.BOTTOM, self.buttonPauseGame)
	FocusManager:linkElements(self.buttonPauseGame, FocusManager.BOTTOM, firstSettingElement)
	FocusManager:linkElements(firstSettingElement, FocusManager.TOP, self.buttonPauseGame)
	FocusManager:linkElements(self.buttonPauseGame, FocusManager.TOP, lastSettingElement)
end

function InGameMenuGameSettingsFrame:setMissionInfo(missionInfo)
	self.missionInfo = missionInfo
end

function InGameMenuGameSettingsFrame:setManureTriggers(manureLoadingStations, liquidManureLoadingStations)
	self.manureLoadingStations = manureLoadingStations
	self.liquidManureLoadingStations = liquidManureLoadingStations
end

function InGameMenuGameSettingsFrame:setHasMasterRights(hasMasterRights)
	self.hasMasterRights = hasMasterRights

	if g_currentMission ~= nil then
		self:updateButtons()
	end
end

function InGameMenuGameSettingsFrame:onFrameOpen(element)
	InGameMenuGameSettingsFrame:superClass().onFrameOpen(self)
	self:assignDynamicTexts()
	self:updateGameSettings()
	self:updatePauseButtonState()
	self:updateAvailableProperties()

	if FocusManager:getFocusedElement() == nil then
		self:setSoundSuppressed(true)
		FocusManager:setFocus(self.buttonPauseGame)
		self:setSoundSuppressed(false)
	end
end

function InGameMenuGameSettingsFrame:updateButtons()
	self.menuButtonInfo = {
		self.backButtonInfo,
		self.saveButton,
		self.quitButton
	}

	if self.hasMasterRights and g_currentMission.missionDynamicInfo.isMultiplayer then
		table.insert(self.menuButtonInfo, self.serverSettingsButton)
	end

	self:setMenuButtonInfoDirty()
end

function InGameMenuGameSettingsFrame:updateAvailableProperties()
	self.boxLayout:invalidateLayout()
end

function InGameMenuGameSettingsFrame:updateGameSettings()
	self.savegameName = self.missionInfo.savegameName

	self.textSavegameName:setText(self.missionInfo.savegameName)
	self.multiTimeScale:setState(Utils.getTimeScaleIndex(self.missionInfo.timeScale))
	self.economicDifficulty:setState(self.missionInfo.economicDifficulty)
	self.checkSnowEnabled:setIsChecked(self.missionInfo.isSnowEnabled)
	self.multiGrowthMode:setState(self.missionInfo.growthMode)

	local period = self.missionInfo.fixedSeasonalVisuals

	self.multiFixedSeasonalVisuals:setState(period == nil and 1 or period + 1)

	local days = self.missionInfo.plannedDaysPerPeriod

	self.multiPlannedDaysPerPeriod:setState(days)
	self.checkFruitDestruction:setIsChecked(self.missionInfo.fruitDestruction)
	self.checkPlowingRequired:setIsChecked(self.missionInfo.plowingRequiredEnabled)
	self.checkStonesEnabled:setIsChecked(self.missionInfo.stonesEnabled)
	self.checkLimeRequired:setIsChecked(self.missionInfo.limeRequired)
	self.checkWeedsEnabled:setIsChecked(self.missionInfo.weedsEnabled)
	self.multiAutoSaveInterval:setState(g_autoSaveManager:getIndexFromInterval(g_autoSaveManager:getInterval()))
	self.checkTraffic:setIsChecked(self.missionInfo.trafficEnabled)
	self.checkDirt:setState(self.missionInfo.dirtInterval)
	self.checkAutoMotorStart:setIsChecked(self.missionInfo.automaticMotorStartEnabled)
	self.checkHelperRefillFuel:setIsChecked(self.missionInfo.helperBuyFuel)
	self.checkHelperRefillSeed:setIsChecked(self.missionInfo.helperBuySeeds)
	self.checkHelperRefillFertilizer:setIsChecked(self.missionInfo.helperBuyFertilizer)
	self.checkFuelUsage:setIsChecked(not self.missionInfo.fuelUsageLow)
	self.checkStopAndGoBraking:setIsChecked(self.missionInfo.stopAndGoBraking)
	self.checkTrailerFillLimit:setIsChecked(self.missionInfo.trailerFillLimit)
	self.checkHelperRefillSlurry:setState(self.missionInfo.helperSlurrySource)
	self.checkHelperRefillManure:setState(self.missionInfo.helperManureSource)
	self.textSavegameName:setDisabled(not self.hasMasterRights)
	self.multiTimeScale:setDisabled(not self.hasMasterRights)
	self.economicDifficulty:setDisabled(not self.hasMasterRights)
	self.checkSnowEnabled:setDisabled(not self.hasMasterRights)
	self.multiGrowthMode:setDisabled(not self.hasMasterRights)
	self.multiFixedSeasonalVisuals:setDisabled(not self.hasMasterRights)
	self.multiPlannedDaysPerPeriod:setDisabled(not self.hasMasterRights)
	self.checkFruitDestruction:setDisabled(not self.hasMasterRights)
	self.checkPlowingRequired:setDisabled(not self.hasMasterRights)
	self.checkLimeRequired:setDisabled(not self.hasMasterRights)
	self.checkWeedsEnabled:setDisabled(not self.hasMasterRights)
	self.checkDirt:setDisabled(not self.hasMasterRights)
	self.multiAutoSaveInterval:setDisabled(not g_currentMission:getIsServer())
	self.multiAutoSaveInterval:setVisible(g_currentMission:getIsServer())
end

function InGameMenuGameSettingsFrame:updatePauseButtonState()
	if g_currentMission.paused then
		self.buttonPauseGame:applyProfile(InGameMenuGameSettingsFrame.PROFILE.BUTTON_UNPAUSE)
		self.buttonPauseGame:setText(self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.UNPAUSE))
	else
		self.buttonPauseGame:applyProfile(InGameMenuGameSettingsFrame.PROFILE.BUTTON_PAUSE)
		self.buttonPauseGame:setText(self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.PAUSE))
	end
end

function InGameMenuGameSettingsFrame:assignStaticTexts()
	self:assignTimeScaleTexts()
	self:assignEconomicDifficultyTexts()
	self:assignDirtTexts()
	self:assignAutoSaveTexts()
	self.checkFuelUsage:setTexts({
		self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.USAGE_LOW),
		self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.USAGE_DEFAULT)
	})

	local helperTexts = {
		self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.OFF),
		self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.BUY)
	}

	self.checkHelperRefillFuel:setTexts(helperTexts)
	self.checkHelperRefillSeed:setTexts(helperTexts)
	self.checkHelperRefillFertilizer:setTexts(helperTexts)
	self.multiGrowthMode:setTexts({
		self.l10n:getText("ui_yes"),
		self.l10n:getText("ui_no"),
		self.l10n:getText("ui_paused")
	})

	local options = {
		self.l10n:getText("ui_off")
	}

	for i = 1, 12 do
		table.insert(options, self.l10n:formatPeriod(i))
	end

	self.multiFixedSeasonalVisuals:setTexts(options)

	local days = {}

	for i = 1, Environment.MAX_DAYS_PER_PERIOD do
		table.insert(days, self.l10n:formatNumDay(i))
	end

	self.multiPlannedDaysPerPeriod:setTexts(days)
end

function InGameMenuGameSettingsFrame:assignTimeScaleTexts()
	local timeScaleTable = {}
	local numTimeScales = Utils.getNumTimeScales()

	for i = 1, numTimeScales do
		table.insert(timeScaleTable, Utils.getTimeScaleString(i))
	end

	self.multiTimeScale:setTexts(timeScaleTable)
end

function InGameMenuGameSettingsFrame:assignEconomicDifficultyTexts()
	local economicDifficultyTable = {}

	table.insert(economicDifficultyTable, self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.DIFFICULTY_EASY))
	table.insert(economicDifficultyTable, self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.DIFFICULTY_NORMAL))
	table.insert(economicDifficultyTable, self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.DIFFICULTY_HARD))
	self.economicDifficulty:setTexts(economicDifficultyTable)
end

function InGameMenuGameSettingsFrame:assignDirtTexts()
	local textTable = {}

	table.insert(textTable, self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.OFF))

	for i = 1, 3 do
		table.insert(textTable, self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.GROWTH_RATE_TEMPLATE .. i))
	end

	self.checkDirt:setTexts(textTable)
end

function InGameMenuGameSettingsFrame:assignAutoSaveTexts()
	local textTable = {}

	for _, interval in ipairs(g_autoSaveManager:getIntervalOptions()) do
		if interval > 0 then
			table.insert(textTable, interval .. " " .. self.l10n:getText("unit_minutesShort"))
		else
			table.insert(textTable, self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.OFF))
		end
	end

	self.multiAutoSaveInterval:setTexts(textTable)
end

function InGameMenuGameSettingsFrame:assignDynamicTexts()
	local helperTexts = {
		self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.OFF),
		self.l10n:getText(InGameMenuGameSettingsFrame.L10N_SYMBOL.BUY)
	}
	local textTable = {}

	table.insert(textTable, helperTexts[1])
	table.insert(textTable, helperTexts[2])

	for _, station in ipairs(self.manureLoadingStations) do
		if g_currentMission.accessHandler:canPlayerAccess(station) then
			table.insert(textTable, station:getName())
		end
	end

	self.checkHelperRefillManure:setTexts(textTable)

	textTable = {}

	table.insert(textTable, helperTexts[1])
	table.insert(textTable, helperTexts[2])

	for _, station in ipairs(self.liquidManureLoadingStations) do
		if g_currentMission.accessHandler:canPlayerAccess(station) then
			table.insert(textTable, station:getName())
		end
	end

	self.checkHelperRefillSlurry:setTexts(textTable)
end

function InGameMenuGameSettingsFrame:getMainElementSize()
	return self.settingsContainer.size
end

function InGameMenuGameSettingsFrame:getMainElementPosition()
	return self.settingsContainer.absPosition
end

function InGameMenuGameSettingsFrame:onEnterPressedSavegameName()
	local newName = self.textSavegameName.text

	if newName ~= self.savegameName then
		if newName == "" then
			newName = g_i18n:getText("defaultSavegameName")

			self.textSavegameName:setText(newName)
		end

		self.missionInfo.savegameName = newName
		self.savegameName = newName

		SavegameSettingsEvent.sendEvent()
	end
end

function InGameMenuGameSettingsFrame:onClickTimeScale(state)
	if self.hasMasterRights then
		g_currentMission:setTimeScale(Utils.getTimeScaleFromIndex(state))
	end
end

function InGameMenuGameSettingsFrame:onClickEconomicDifficulty(state)
	if self.hasMasterRights then
		g_currentMission:setEconomicDifficulty(state)
	end
end

function InGameMenuGameSettingsFrame:onClickTraffic(state)
	if self.hasMasterRights then
		g_currentMission:setTrafficEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickDirt(state)
	if self.hasMasterRights then
		g_currentMission:setDirtInterval(state)
	end
end

function InGameMenuGameSettingsFrame:onClickFuelUsage(state)
	if self.hasMasterRights then
		g_currentMission:setFuelUsageLow(state ~= CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickHelperRefillFuel(state)
	if self.hasMasterRights then
		g_currentMission:setHelperBuyFuel(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickHelperRefillSeed(state)
	if self.hasMasterRights then
		g_currentMission:setHelperBuySeeds(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickHelperRefillFertilizer(state)
	if self.hasMasterRights then
		g_currentMission:setHelperBuyFertilizer(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickHelperRefillSlurry(state)
	if self.hasMasterRights then
		g_currentMission:setHelperSlurrySource(state)
	end
end

function InGameMenuGameSettingsFrame:onClickHelperRefillManure(state)
	if self.hasMasterRights then
		g_currentMission:setHelperManureSource(state)
	end
end

function InGameMenuGameSettingsFrame:onClickAutomaticMotorStart(state)
	if self.hasMasterRights then
		g_currentMission:setAutomaticMotorStartEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickSnowEnabled(state)
	if self.hasMasterRights then
		g_currentMission:setSnowEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickPlannedDaysPerPeriod(state)
	if self.hasMasterRights then
		g_currentMission:setPlannedDaysPerPeriod(state)
	end
end

function InGameMenuGameSettingsFrame:onClickGrowthMode(state)
	if self.hasMasterRights then
		g_currentMission:setGrowthMode(state)
	end
end

function InGameMenuGameSettingsFrame:onClickFixedSeasonalVisuals(state)
	if self.hasMasterRights then
		if state == 1 then
			g_currentMission:setFixedSeasonalVisuals(nil)
		else
			g_currentMission:setFixedSeasonalVisuals(state - 1)
		end
	end
end

function InGameMenuGameSettingsFrame:onClickFruitDestruction(state)
	if self.hasMasterRights then
		g_currentMission:setFruitDestructionEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickPlowingRequired(state)
	if self.hasMasterRights then
		g_currentMission:setPlowingRequiredEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickStonesEnabled(state)
	if self.hasMasterRights then
		g_currentMission:setStonesEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickLimeRequired(state)
	if self.hasMasterRights then
		g_currentMission:setLimeRequired(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickWeedsEnabled(state)
	if self.hasMasterRights then
		g_currentMission:setWeedsEnabled(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickStopAndGoBraking(state)
	if self.hasMasterRights then
		g_currentMission:setStopAndGoBraking(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickTrailerFillLimit(state)
	if self.hasMasterRights then
		g_currentMission:setTrailerFillLimit(state == CheckedOptionElement.STATE_CHECKED)
	end
end

function InGameMenuGameSettingsFrame:onClickAutoSaveInterval(state)
	if self.hasMasterRights then
		g_currentMission:setAutoSaveInterval(g_autoSaveManager:getIntervalFromIndex(state))
	end
end

function InGameMenuGameSettingsFrame:onClickPauseGame()
	self.pageMapOverview:notifyPause()

	if GS_IS_CONSOLE_VERSION then
		self.onClickBackCallback()
	end

	g_currentMission:setManualPause(not g_currentMission.paused)
	self:updatePauseButtonState()
end

function InGameMenuGameSettingsFrame:onButtonOpenServerSettings()
	g_gui:showServerSettingsDialog({})
end

InGameMenuGameSettingsFrame.PROFILE = {
	BUTTON_PAUSE = "ingameMenuSettingsPauseButton",
	BUTTON_UNPAUSE = "ingameMenuSettingsUnpauseButton"
}
InGameMenuGameSettingsFrame.L10N_SYMBOL = {
	UNPAUSE = "ui_unpause",
	BUY = "ui_buy",
	OFF = "ui_off",
	PAUSE = "input_PAUSE",
	USAGE_LOW = "setting_fuelUsageLow",
	USAGE_DEFAULT = "setting_fuelUsageDefault",
	DIFFICULTY_NORMAL = "button_normal",
	DIFFICULTY_HARD = "button_hard",
	SUBSTITUTION_PREFIX = "$l10n_",
	DIFFICULTY_EASY = "button_easy",
	GROWTH_RATE_TEMPLATE = "setting_plantGrowthRateState"
}
