InGameMenu = {}
local InGameMenu_mt = Class(InGameMenu, TabbedMenu)
InGameMenu.SAVE_STATE_NONE = 0
InGameMenu.SAVE_STATE_VALIDATE_LIST = 1
InGameMenu.SAVE_STATE_VALIDATE_LIST_DIALOG_WAIT = 2
InGameMenu.SAVE_STATE_VALIDATE_LIST_WAIT = 3
InGameMenu.SAVE_STATE_OVERWRITE_DIALOG = 4
InGameMenu.SAVE_STATE_OVERWRITE_DIALOG_WAIT = 5
InGameMenu.SAVE_STATE_NOP_WRITE = 6
InGameMenu.SAVE_STATE_WRITE = 7
InGameMenu.SAVE_STATE_WRITE_WAIT = 8
InGameMenu.CONTROLS = {
	"pageMapOverview",
	"pageAI",
	"pageCalendar",
	"pageWeather",
	"pagePrices",
	"pageGarageOverview",
	"pageFinances",
	"pageAnimals",
	"pageStatistics",
	"pageSettingsGeneral",
	"pageSettingsGame",
	"pageSettingsControls",
	"pageSettingsMobile",
	"pageMultiplayerFarms",
	"pageMultiplayerUsers",
	"pageContracts",
	"pageProduction",
	"pageHelpLine",
	"pageMain",
	"background"
}
InGameMenu.MULTIPLAYER_SAVING_DISPLAY_DURATION = 800

function InGameMenu.new(target, customMt, messageCenter, l10n, inputManager, savegameController, fruitTypeManager, fillTypeManager, isConsoleVersion)
	local self = InGameMenu:superClass().new(target, customMt or InGameMenu_mt, messageCenter, l10n, inputManager)

	self:registerControls(InGameMenu.CONTROLS)

	self.savegameController = savegameController
	self.fruitTypeManager = fruitTypeManager
	self.fillTypeManager = fillTypeManager
	self.isConsoleVersion = isConsoleVersion
	self.hud = nil
	self.performBackgroundBlur = true
	self.gameState = GameState.MENU_INGAME
	self.playerFarm = nil
	self.playerFarmId = 0
	self.currentUserId = -1
	self.isSaving = false
	self.missionInfo = {}
	self.missionDynamicInfo = {}
	self.activeDetailPage = nil
	self.lastGaragePage = nil
	self.paused = false
	self.playerAlreadySaved = false
	self.doSaveGameState = InGameMenu.SAVE_STATE_NONE
	self.continueEnabled = true
	self.savingMinEndTime = 0
	self.currentDeviceHasNoSpace = false
	self.quitAfterSave = false
	self.client = nil
	self.server = nil
	self.isMasterUser = false
	self.isServer = false
	self.currentBalanceValue = 0
	self.timeSinceLastMoneyUpdate = 0
	self.needMoneyUpdate = true
	self.defaultMenuButtonInfo = {}
	self.backButtonInfo = {}

	return self
end

function InGameMenu:setInGameMap(inGameMap)
	self.pageMapOverview:setInGameMap(inGameMap)
	self.pageAI:setInGameMap(inGameMap)

	self.baseIngameMap = inGameMap
end

function InGameMenu:setHUD(hud)
	self.hud = hud
end

function InGameMenu:setTerrainSize(terrainSize)
	self.pageMapOverview:setTerrainSize(terrainSize)
	self.pageAI:setTerrainSize(terrainSize)
end

function InGameMenu:setMissionFruitTypes(fruitTypes)
	self.pageMapOverview:setMissionFruitTypes(fruitTypes)
end

function InGameMenu:setConnectedUsers(users)
	if self.pageMultiplayerUsers ~= nil then
		self.pageMultiplayerUsers:setUsers(users)
		self.pageMultiplayerFarms:setUsers(users)
	end
end

function InGameMenu:setClient(client)
	self.client = client

	self.pageMapOverview:setClient(client)
	self.pageFinances:setClient(client)
end

function InGameMenu:setServer(server)
	self.server = server
	self.isServer = server ~= nil

	self:updateHasMasterRights()
end

function InGameMenu:updateHasMasterRights()
	local hasMasterRights = self.isMasterUser or self.isServer

	self.pageFinances:setHasMasterRights(hasMasterRights)

	if self.pageSettingsGame ~= nil then
		self.pageSettingsGame:setHasMasterRights(hasMasterRights)
	end

	if self.pageSettingsMobile ~= nil then
		self.pageSettingsMobile:setHasMasterRights(hasMasterRights)
	end

	if self.saveButtonInfo.disabled ~= not hasMasterRights then
		self.saveButtonInfo.disabled = not hasMasterRights

		if self.currentPage ~= nil then
			self:updateButtonsPanel(self.currentPage)
		end
	end

	if self.currentPage ~= nil then
		self:updatePages()
	end
end

function InGameMenu:onGrowthModeChanged()
	if self.currentPage ~= nil then
		self:updatePages()
	end
end

function InGameMenu:onLoadMapFinished()
	self.pageMapOverview:onLoadMapFinished()
	self.pageAI:onLoadMapFinished()
end

function InGameMenu:initializePages()
	self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)

	self.pageMapOverview:initialize(self.clickBackCallback)
	self.pageAI:initialize(self.clickBackCallback)
	self.pageGarageOverview:initialize()
	self.pagePrices:initialize()
	self.pageCalendar:initialize()
	self.pageWeather:initialize()

	if self.pageContracts ~= nil then
		self.pageContracts:initialize()
	end

	self.pageProduction:initialize()
	self.pageFinances:initialize()
	self.pageAnimals:initialize()

	if not GS_IS_MOBILE_VERSION then
		self.pageMultiplayerFarms:initialize()
		self.pageMultiplayerUsers:initialize()
		self.pageSettingsGame:initialize(self.pageMapOverview, self.clickBackCallback)
		self.pageSettingsGeneral:initialize()
	end

	if self.pageSettingsMobile ~= nil then
		self.pageSettingsMobile:initialize()
	end

	if self.pageMain ~= nil then
		self.pageMain:initialize()
	end

	local function updateSettingsControlsButtonsCallback()
		self:assignMenuButtonInfo(self.pageSettingsControls:getMenuButtonInfo())
	end

	if self.pageSettingsControls ~= nil then
		local controlsController = ControlsController.new()

		self.pageSettingsControls:initialize(controlsController, true)
		self.pageSettingsControls:setRequestButtonUpdateCallback(updateSettingsControlsButtonsCallback)
	end
end

function InGameMenu:setupMenuPages()
	local function mobileFunc()
		return GS_IS_MOBILE_VERSION
	end

	local orderedDefaultPages = {
		{
			self.pageMain,
			mobileFunc,
			InGameMenu.TAB_UV.MAP
		},
		{
			self.pageMapOverview,
			self:makeIsMapEnabledPredicate(),
			InGameMenu.TAB_UV.MAP
		},
		{
			self.pageAI,
			self:makeIsAIEnabledPredicate(),
			InGameMenu.TAB_UV.AI
		},
		{
			self.pageCalendar,
			self:makeIsCalendarEnabledPredicate(),
			InGameMenu.TAB_UV.CALENDAR
		},
		{
			self.pageWeather,
			self:makeIsWeatherEnabledPredicate(),
			InGameMenu.TAB_UV.WEATHER
		},
		{
			self.pagePrices,
			self:makeIsPricesEnabledPredicate(),
			InGameMenu.TAB_UV.PRICES
		},
		{
			self.pageGarageOverview,
			self:makeIsGarageEnabledPredicate(),
			InGameMenu.TAB_UV.VEHICLES
		},
		{
			self.pageFinances,
			self:makeIsFinancesEnabledPredicate(),
			InGameMenu.TAB_UV.FINANCES
		},
		{
			self.pageAnimals,
			self:makeIsAnimalsEnabledPredicate(),
			InGameMenu.TAB_UV.ANIMALS
		},
		{
			self.pageContracts,
			self:makeIsContractsEnabledPredicate(),
			InGameMenu.TAB_UV.CONTRACTS
		},
		{
			self.pageProduction,
			self:makeIsProductionEnabledPredicate(),
			InGameMenu.TAB_UV.PRODUCTION
		},
		{
			self.pageStatistics,
			self:makeIsStatisticsEnabledPredicate(),
			InGameMenu.TAB_UV.STATISTICS
		},
		{
			self.pageMultiplayerFarms,
			self:makeIsMpFarmsEnabledPredicate(),
			InGameMenu.TAB_UV.FARMS
		},
		{
			self.pageMultiplayerUsers,
			self:makeIsMpUsersEnabledPredicate(),
			InGameMenu.TAB_UV.USERS
		},
		{
			self.pageSettingsGame,
			self:makeIsGameSettingsEnabledPredicate(),
			InGameMenu.TAB_UV.GAME_SETTINGS
		},
		{
			self.pageSettingsGeneral,
			self:makeIsGeneralSettingsEnabledPredicate(),
			InGameMenu.TAB_UV.GENERAL_SETTINGS
		},
		{
			self.pageSettingsControls,
			self:makeIsControlsSettingsEnabledPredicate(),
			InGameMenu.TAB_UV.CONTROLS_SETTINGS
		},
		{
			self.pageHelpLine,
			self:makeIsHelpEnabledPredicate(),
			InGameMenu.TAB_UV.HELP
		},
		{
			self.pageSettingsMobile,
			mobileFunc,
			InGameMenu.TAB_UV.HELP
		}
	}

	for i, pageDef in ipairs(orderedDefaultPages) do
		local page, predicate, iconUVs = unpack(pageDef)

		if page ~= nil then
			self:registerPage(page, i, predicate)

			local normalizedUVs = GuiUtils.getUVs(iconUVs)

			self:addPageTab(page, g_iconsUIFilename, normalizedUVs)
		end
	end
end

function InGameMenu:setupMenuButtonInfo()
	InGameMenu:superClass().setupMenuButtonInfo(self)

	local onButtonBackFunction = self.clickBackCallback
	local onButtonQuitFunction = self:makeSelfCallback(self.onButtonQuit)
	local onButtonSaveGameFunction = self:makeSelfCallback(self.onButtonSaveGame)
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK,
		text = self.l10n:getText(InGameMenu.L10N_SYMBOL.BUTTON_BACK),
		callback = onButtonBackFunction
	}
	self.saveButtonInfo = {
		showWhenPaused = true,
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.l10n:getText(InGameMenu.L10N_SYMBOL.BUTTON_SAVE_GAME),
		callback = onButtonSaveGameFunction
	}
	self.quitButtonInfo = {
		showWhenPaused = true,
		inputAction = InputAction.MENU_CANCEL,
		text = self.l10n:getText(InGameMenu.L10N_SYMBOL.BUTTON_CANCEL_GAME),
		callback = onButtonQuitFunction
	}

	if GS_IS_MOBILE_VERSION then
		self.defaultMenuButtonInfo = {
			self.backButtonInfo
		}
	else
		self.defaultMenuButtonInfo = {
			self.backButtonInfo,
			self.saveButtonInfo,
			self.quitButtonInfo
		}
	end

	if g_isPresentationVersion then
		table.remove(self.defaultMenuButtonInfo, 2)
	end

	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_ACTIVATE] = self.defaultMenuButtonInfo[2]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_CANCEL] = self.defaultMenuButtonInfo[3]
	self.defaultButtonActionCallbacks = {
		[InputAction.MENU_BACK] = onButtonBackFunction,
		[InputAction.MENU_CANCEL] = onButtonQuitFunction,
		[InputAction.MENU_ACTIVATE] = onButtonSaveGameFunction
	}
end

function InGameMenu:onGuiSetupFinished()
	InGameMenu:superClass().onGuiSetupFinished(self)
	self.messageCenter:subscribe(MessageType.GUI_INGAME_OPEN_FINANCES_SCREEN, self.openFinancesScreen, self)
	self.messageCenter:subscribe(MessageType.GUI_INGAME_OPEN_FARMS_SCREEN, self.openFarmsScreen, self)
	self.messageCenter:subscribe(MessageType.GUI_INGAME_OPEN_PRODUCTION_SCREEN, self.openProductionScreen, self)
	self.messageCenter:subscribe(MessageType.GUI_INGAME_OPEN_AI_SCREEN, self.openAIScreen, self)
	self.messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChanged, self)
	self.messageCenter:subscribe(MessageType.MASTERUSER_ADDED, self.onMasterUserAdded, self)
	self.messageCenter:subscribe(MessageType.UNLOADING_STATIONS_CHANGED, self.onUnloadingStationsChanged, self)
	self:initializePages()
	self:setupMenuPages()
end

function InGameMenu:setEnvironment(environment)
	self.pageFinances:setEnvironment(environment)
end

function InGameMenu:updateBackground()
	self.background:setVisible(self.currentPage.needsSolidBackground)
end

function InGameMenu:setMissionInfo(missionInfo, missionDynamicInfo, missionBaseDirectory)
	self.missionInfo = missionInfo
	self.missionDynamicInfo = missionDynamicInfo

	if self.pageSettingsGame ~= nil then
		self.pageSettingsGame:setMissionInfo(missionInfo)
	end

	if self.pageSettingsMobile ~= nil then
		self.pageSettingsMobile:setMissionInfo(missionInfo)
	end

	self.pageHelpLine:setMissionBaseDirectory(missionBaseDirectory)

	self.currentDeviceHasNoSpace = false
end

function InGameMenu:setPlayerFarm(farm)
	self.playerFarm = farm

	if farm ~= nil then
		self.playerFarmId = farm.farmId
	else
		self.playerFarmId = 0
	end

	self.pageMapOverview:setPlayerFarm(farm)
	self.pageAI:setPlayerFarm(farm)
	self.pageFinances:setPlayerFarm(farm)
	self.pageStatistics:setPlayerFarm(farm)

	if self.pageMultiplayerUsers ~= nil then
		self.pageMultiplayerUsers:setPlayerFarm(farm)
		self.pageMultiplayerFarms:setPlayerFarm(farm)
	end

	self.pageAnimals:setPlayerFarm(farm)
	self.pageProduction:setPlayerFarm(farm)

	if farm ~= nil and self:getIsOpen() then
		self:updatePages()
	end
end

function InGameMenu:setPlayer(player)
	if self.pageMultiplayerFarms ~= nil then
		self.pageMultiplayerFarms:setPlayer(player)
	end
end

function InGameMenu:setCurrentUserId(currentUserId)
	self.currentUserId = currentUserId

	if self.pageMultiplayerUsers ~= nil then
		self.pageMultiplayerUsers:setCurrentUserId(currentUserId)
		self.pageMultiplayerFarms:setCurrentUserId(currentUserId)
	end
end

function InGameMenu:setManureTriggers(manureLoadingStations, liquidManureLoadingStations)
	if self.pageSettingsGame ~= nil then
		self.pageSettingsGame:setManureTriggers(manureLoadingStations, liquidManureLoadingStations)
	end
end

function InGameMenu:leaveCurrentGame()
	OnInGameMenuMenu()
end

function InGameMenu:exitMenu()
	if self.continueEnabled and not self.isSaving then
		InGameMenu:superClass().exitMenu(self)
	end
end

function InGameMenu:reset()
	InGameMenu:superClass().reset(self)

	self.isSaving = false
	self.playerAlreadySaved = false
	self.doSaveGameState = InGameMenu.SAVE_STATE_NONE
	self.savingMinEndTime = 0
	self.currentDeviceHasNoSpace = false
	self.quitAfterSave = false
	self.isMasterUser = false
	self.isServer = false
	self.quitAfterSave = false
	self.continueEnabled = true
end

function InGameMenu:onMenuOpened()
	if self.playerFarmId == FarmManager.SPECTATOR_FARM_ID then
		self:setSoundSuppressed(true)

		local farmsPageId = self.pagingElement:getPageIdByElement(self.pageMultiplayerFarms)
		local farmsPageIndex = self.pagingElement:getPageMappingIndex(farmsPageId)

		self.pageSelector:setState(farmsPageIndex, true)
		self:setSoundSuppressed(false)
	end

	if GS_IS_MOBILE_VERSION then
		g_currentMission:setManualPause(true)
	end

	if self.currentPage.dynamicMapImageLoading ~= nil then
		if not self.currentPage.dynamicMapImageLoading:getIsVisible() then
			self.messageCenter:publish(MessageType.GUI_INGAME_OPEN)
		else
			self.sendDelayedOpenMessage = true
		end
	else
		self.messageCenter:publish(MessageType.GUI_INGAME_OPEN)
	end
end

function InGameMenu:onClose(element)
	if GS_IS_MOBILE_VERSION then
		g_currentMission:setManualPause(false)
	end

	InGameMenu:superClass().onClose(self)

	self.mouseDown = false
	self.alreadyClosed = true

	if GS_IS_MOBILE_VERSION then
		g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_SELL)
		g_currentMission:showMoneyChange(MoneyType.SHOP_PROPERTY_SELL)
		g_currentMission:showMoneyChange(MoneyType.ANIMAL_UPKEEP)
	end

	g_gameSettings:saveToXMLFile(g_savegameXML)
end

function InGameMenu:onButtonSaveGame()
	if g_isPresentationVersion or self.missionDynamicInfo.isMultiplayer and self.missionDynamicInfo.isClient and not self.isMasterUser or not g_currentMission.isMissionStarted or self.isSaving then
		return true
	end

	if self.missionInfo:isa(FSCareerMissionInfo) and self.doSaveGameState == InGameMenu.SAVE_STATE_NONE then
		if not self.isServer and self.isMasterUser and self.missionDynamicInfo.isMultiplayer then
			self.client:getServerConnection():sendEvent(SaveEvent.new())
			self:notifyStartSaving()

			self.savingDisplayTimer = g_time + InGameMenu.MULTIPLAYER_SAVING_DISPLAY_DURATION
		else
			self.messageCenter:publish(SaveEvent, false, false)
		end
	end
end

function InGameMenu:onButtonQuit()
	if self.isSaving then
		return
	end

	local isMultiplayerClient = self.missionDynamicInfo.isMultiplayer and self.missionDynamicInfo.isClient

	if (not self.playerAlreadySaved or not self.missionInfo:isa(FSCareerMissionInfo)) and not isMultiplayerClient then
		local text = self.l10n:getText(InGameMenu.L10N_SYMBOL.END_TUTORIAL)

		if self.missionInfo:isa(FSCareerMissionInfo) then
			text = self.l10n:getText(InGameMenu.L10N_SYMBOL.END_WITHOUT_SAVING)
		end

		g_gui:showYesNoDialog({
			text = text,
			callback = self.onYesNoEnd,
			target = self
		})
	else
		self:leaveCurrentGame()
	end
end

function InGameMenu:onButtonBack()
	if not GS_IS_MOBILE_VERSION or self.currentPage == self.pageMain or self.currentPage == self.pageMapOverview then
		InGameMenu:superClass().onButtonBack(self)
	else
		self:goToPage(self.pageMain)
	end
end

function InGameMenu:setIsGamePaused(paused)
	self.paused = paused

	if self.currentPage ~= nil then
		self:updateButtonsPanel(self.currentPage)
	end
end

function InGameMenu:startSavingGameDisplay()
	g_gui:showMessageDialog({
		isCloseAllowed = false,
		visible = true,
		text = self.l10n:getText(InGameMenu.L10N_SYMBOL.SAVING_CONTENT)
	})

	self.savingMinEndTime = getTimeSec() + SavegameController.SAVING_DURATION
	self.isSaving = true
end

function InGameMenu:update(dt)
	self.alreadyClosed = false

	if self.doSaveGameState == InGameMenu.SAVE_STATE_NONE and self.isSaving and self.savingMinEndTime <= getTimeSec() then
		self.savingMinEndTime = 0

		g_gui:showMessageDialog({
			visible = false
		})

		self.isSaving = false

		if self.quitAfterSave then
			self:leaveCurrentGame()

			return
		end
	end

	if self.savingDisplayTimer ~= nil and self.savingDisplayTimer < g_time then
		self:notifySaveComplete()

		self.savingDisplayTimer = nil
	end

	if self.isSaving then
		return
	end

	InGameMenu:superClass().update(self, dt)

	if GS_PLATFORM_PLAYSTATION and g_currentMission ~= nil and self.missionDynamicInfo.isMultiplayer and getMultiplayerAvailability() == MultiplayerAvailability.NOT_AVAILABLE and self.continueEnabled then
		self.continueEnabled = false

		g_gui:changeScreen(InGameMenu)
	end

	self:updateCurrentBalanceDisplay(dt)

	if self.sendDelayedOpenMessage and self.currentPage ~= nil and self.currentPage.dynamicMapImageLoading ~= nil and not self.currentPage.dynamicMapImageLoading:getIsVisible() then
		self.messageCenter:publish(MessageType.GUI_INGAME_OPEN)

		self.sendDelayedOpenMessage = false
	end
end

function InGameMenu:updateButtonsPanel(page)
	local buttonsDisabled = page.hasFullScreenMap

	self.buttonsPanel:setVisible(not buttonsDisabled)
	self.buttonsPanel:setDisabled(buttonsDisabled)
	InGameMenu:superClass().updateButtonsPanel(self, page)
end

function InGameMenu:openFinancesScreen()
	if self.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID then
		self:changeScreen(InGameMenu)

		local financesPageIndex = self.pagingElement:getPageMappingIndexByElement(self.pageFinances)

		self.pageSelector:setState(financesPageIndex, true)
	end
end

function InGameMenu:openAIScreen()
	self:changeScreen(InGameMenu)

	local pageAIIndex = self.pagingElement:getPageMappingIndexByElement(self.pageAI)

	self.pageSelector:setState(pageAIIndex, true)
end

function InGameMenu:openFarmsScreen()
	self:changeScreen(InGameMenu)

	local farmsPageIndex = self.pagingElement:getPageMappingIndexByElement(self.pageMultiplayerFarms)

	self.pageSelector:setState(farmsPageIndex, true)
end

function InGameMenu:openProductionScreen(productionPoint)
	self:changeScreen(InGameMenu)

	local productionPageIndex = self.pagingElement:getPageMappingIndexByElement(self.pageProduction)

	self.pageSelector:setState(productionPageIndex, true)
	self.pageProduction:setSelectedProductionPoint(productionPoint)
end

function InGameMenu:setMasterServerConnectionFailed(reason)
	local gameSettingsPageIndex = self.pagingElement:getPageMappingIndexByElement(self.pageSettingsGame)

	self.pageSelector:setState(gameSettingsPageIndex, true)

	local quitGame = reason == MasterServerConnection.FAILED_PERMANENT_BAN or reason == MasterServerConnection.FAILED_TEMPORARY_BAN or not g_currentMission.isMissionStarted

	if quitGame or not self.isServer then
		self:leaveCurrentGame()
		g_gui:showInfoDialog({
			text = self.l10n:getText(InGameMenu.L10N_SYMBOL.MASTER_SERVER_CONNECTION_LOST),
			callback = self.onConnectionFailedDialogClick,
			target = self
		})
	else
		self.continueEnabled = false

		g_gui:showYesNoDialog({
			text = self.l10n:getText(InGameMenu.L10N_SYMBOL.MASTER_SERVER_CONNECTION_LOST),
			yesText = self.l10n:getText("button_save"),
			callback = self.onConnectionFailedDialogClick,
			target = self
		})
	end
end

function InGameMenu:onMasterUserAdded(user)
	if user:getId() == g_currentMission.playerUserId then
		self.isMasterUser = true

		self:updateHasMasterRights()
	end
end

function InGameMenu:onUnloadingStationsChanged()
	self.pagePrices:updateStations()
end

function InGameMenu:updateCurrentBalanceDisplay(dt)
	self.timeSinceLastMoneyUpdate = self.timeSinceLastMoneyUpdate + dt

	if self.needMoneyUpdate and TabbedMenu.MONEY_UPDATE_INTERVAL <= self.timeSinceLastMoneyUpdate then
		self.pageMapOverview:onMoneyChanged(self.playerFarmId, self.currentBalanceValue)

		if self.pageMultiplayerUsers ~= nil then
			self.pageMultiplayerUsers:updateBalance()
		end

		self.timeSinceLastMoneyUpdate = 0
		self.needMoneyUpdate = false
	end
end

function InGameMenu:getTabBarProfile()
	if self.currentPage.hasFullScreenMap then
		return InGameMenu.PROFILES.TAB_BAR_DARK
	end

	return InGameMenu.PROFILES.TAB_BAR_LIGHT
end

function InGameMenu:onClickMenu()
	self:exitMenu()

	return true
end

function InGameMenu:onMoneyChanged(farmId, newMoneyValue)
	if farmId == self.playerFarmId then
		self.needMoneyUpdate = true
		self.currentBalanceValue = newMoneyValue
	end
end

function InGameMenu:onYesNoEnd(yes)
	if yes then
		if self.missionDynamicInfo.isMultiplayer and self.isServer then
			self.server:broadcastEvent(ShutdownEvent.new())
		end

		self:leaveCurrentGame()
	end
end

function InGameMenu:onPageChange(pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
	local prevPage = self.pagingElement:getPageElementByIndex(self.currentPageId)

	if prevPage == self.pageMapOverview then
		self.pageAI.ingameMap:copySettingsFromElement(self.pageMapOverview.ingameMap)
	elseif prevPage == self.pageAI then
		self.pageMapOverview.ingameMap:copySettingsFromElement(self.pageAI.ingameMap)
	end

	InGameMenu:superClass().onPageChange(self, pageIndex, pageMappingIndex, element, skipTabVisualUpdate)

	local page = self.pagingElement:getPageElementByIndex(pageIndex)

	if page.hasFullScreenMap then
		page:setStaticUIDeadzone(self.header.absPosition[1], self.header.absPosition[2], self.header.size[1], self.header.size[2])
		page:resetUIDeadzones()
		self.hud:onMapVisibilityChange(true)
	else
		self.hud:onMapVisibilityChange(false)
	end

	self.header:applyProfile(self:getTabBarProfile())
	self:updateBackground()
end

function InGameMenu:getPageButtonInfo(page)
	local buttonInfo = InGameMenu:superClass().getPageButtonInfo(self, page)

	return buttonInfo
end

function InGameMenu:onConnectionFailedDialogClick(yes)
	if yes then
		self.quitAfterSave = true

		self.messageCenter:publish(SaveEvent, false, false)
	else
		self:leaveCurrentGame()
	end
end

function InGameMenu:onVehiclesChanged(vehicle, wasAdded, isExitingGame)
	self.pageMapOverview:onVehiclesChanged(vehicle, wasAdded, isExitingGame)
	self.pageAI:onVehiclesChanged(vehicle, wasAdded, isExitingGame)
end

function InGameMenu:notifyValidateSavegameList(currentDeviceHasNoSpace, dialogCallback, callbackTarget)
	self.doSaveGameState = SavegameController.SAVE_STATE_VALIDATE_LIST_DIALOG_WAIT
	local text = self.l10n:getText(InGameMenu.L10N_SYMBOL.SELECT_DEVICE)

	if currentDeviceHasNoSpace then
		text = self.l10n:getText(InGameMenu.L10N_SYMBOL.SAVE_NO_SPACE)
	end

	g_gui:showYesNoDialog({
		text = text,
		callback = dialogCallback,
		target = callbackTarget
	})
end

function InGameMenu:notifyStartSaving()
	self.doSaveGameState = SavegameController.SAVE_STATE_NOP_WRITE

	self:startSavingGameDisplay()
end

function InGameMenu:notifySaveComplete()
	self.doSaveGameState = SavegameController.SAVE_STATE_NONE
	self.playerAlreadySaved = true
end

function InGameMenu:notifySavegameNotSaved(errorCode)
	self.doSaveGameState = SavegameController.SAVE_STATE_NONE
	self.savingMinEndTime = 0
	local text = self.l10n:getText(InGameMenu.L10N_SYMBOL.NOT_SAVED)

	if errorCode == Savegame.ERROR_DEVICE_UNAVAILABLE then
		text = self.l10n:getText(InGameMenu.L10N_SYMBOL.SAVE_NO_DEVICE)
	end

	g_gui:showInfoDialog({
		text = text
	})
end

function InGameMenu:notifyOverwriteSavegame(dialogCallback, callbackTarget)
	self.doSaveGameState = SavegameController.SAVE_STATE_OVERWRITE_DIALOG_WAIT

	g_gui:showMessageDialog({
		visible = false
	})
	g_gui:showYesNoDialog({
		text = self.l10n:getText(InGameMenu.L10N_SYMBOL.SAVE_OVERWRITE),
		callback = dialogCallback,
		target = callbackTarget
	})
end

function InGameMenu:notifySaveFailedNoSpace(dialogCallback, callbackTarget)
	g_gui:showYesNoDialog({
		text = self.l10n:getText(InGameMenu.L10N_SYMBOL.SAVE_NO_SPACE),
		callback = dialogCallback,
		target = callbackTarget
	})
end

function InGameMenu:makeIsMapEnabledPredicate()
	return function ()
		return true
	end
end

function InGameMenu:makeIsAIEnabledPredicate()
	return function ()
		return not g_isPresentationVersion or g_isPresentationVersionAIEnabled
	end
end

function InGameMenu:makeIsCalendarEnabledPredicate()
	return function ()
		return g_currentMission.missionInfo.growthMode == GrowthSystem.MODE.SEASONAL
	end
end

function InGameMenu:makeIsWeatherEnabledPredicate()
	return function ()
		return true
	end
end

function InGameMenu:makeIsPricesEnabledPredicate()
	return function ()
		local isNotMultiplayerOrIsInFarm = not self.missionDynamicInfo.isMultiplayer or self.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID

		return isNotMultiplayerOrIsInFarm and not g_isPresentationVersion
	end
end

function InGameMenu:makeIsAnimalsEnabledPredicate()
	return function ()
		local isNotMultiplayerOrIsInFarm = not self.missionDynamicInfo.isMultiplayer or self.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID

		return isNotMultiplayerOrIsInFarm and not g_isPresentationVersion
	end
end

function InGameMenu:makeIsContractsEnabledPredicate()
	return function ()
		local isNotMultiplayerOrIsInFarm = not self.missionDynamicInfo.isMultiplayer or self.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID

		return isNotMultiplayerOrIsInFarm and not g_isPresentationVersion
	end
end

function InGameMenu:makeIsGarageEnabledPredicate()
	return function ()
		local isNotMultiplayerOrIsInFarm = not self.missionDynamicInfo.isMultiplayer or self.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID

		return isNotMultiplayerOrIsInFarm and not g_isPresentationVersion
	end
end

function InGameMenu:makeIsFinancesEnabledPredicate()
	return function ()
		local isNotMultiplayerOrIsInFarm = not self.missionDynamicInfo.isMultiplayer or self.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID

		return isNotMultiplayerOrIsInFarm
	end
end

function InGameMenu:makeIsStatisticsEnabledPredicate()
	return function ()
		return not self.missionDynamicInfo.isMultiplayer
	end
end

function InGameMenu:makeIsGameSettingsEnabledPredicate()
	return function ()
		local isMultiplayer = self.missionDynamicInfo.isMultiplayer
		local canChangeSettings = not isMultiplayer or isMultiplayer and self.isServer or self.isMasterUser

		return canChangeSettings
	end
end

function InGameMenu:makeIsGeneralSettingsEnabledPredicate()
	return function ()
		return true
	end
end

function InGameMenu:makeIsControlsSettingsEnabledPredicate()
	return function ()
		return not self.isConsoleVersion and not g_isPresentationVersion
	end
end

function InGameMenu:makeIsMpUsersEnabledPredicate()
	return function ()
		local isMultiplayer = self.missionDynamicInfo.isMultiplayer

		return isMultiplayer
	end
end

function InGameMenu:makeIsMpFarmsEnabledPredicate()
	return function ()
		return self.missionDynamicInfo.isMultiplayer
	end
end

function InGameMenu:makeIsHelpEnabledPredicate()
	return function ()
		return not g_isPresentationVersion
	end
end

function InGameMenu:makeIsProductionEnabledPredicate()
	return function ()
		local isNotMultiplayerOrIsInFarm = not self.missionDynamicInfo.isMultiplayer or self.playerFarmId ~= FarmManager.SPECTATOR_FARM_ID

		return isNotMultiplayerOrIsInFarm
	end
end

InGameMenu.TAB_UV = {
	MAP = {
		0,
		0,
		65,
		65
	},
	AI = {
		910,
		65,
		65,
		65
	},
	CALENDAR = {
		65,
		0,
		65,
		65
	},
	WEATHER = {
		130,
		0,
		65,
		65
	},
	PRICES = {
		195,
		0,
		65,
		65
	},
	VEHICLES = {
		260,
		0,
		65,
		65
	},
	FINANCES = {
		325,
		0,
		65,
		65
	},
	ANIMALS = {
		390,
		0,
		65,
		65
	},
	CONTRACTS = {
		455,
		0,
		65,
		65
	},
	PRODUCTION = {
		520,
		0,
		65,
		65
	},
	STATISTICS = {
		585,
		0,
		65,
		65
	},
	GAME_SETTINGS = {
		650,
		0,
		65,
		65
	},
	GENERAL_SETTINGS = {
		715,
		0,
		65,
		65
	},
	CONTROLS_SETTINGS = {
		845,
		0,
		65,
		65
	},
	HELP = {
		0,
		65,
		65,
		65
	},
	FARMS = {
		260,
		65,
		65,
		65
	},
	USERS = {
		650,
		65,
		65,
		65
	}
}
InGameMenu.L10N_SYMBOL = {
	END_WITHOUT_SAVING = "ui_endWithoutSaving",
	BUTTON_RESTART = "button_restart",
	SELECT_DEVICE = "dialog_savegameSelectDevice",
	SAVE_OVERWRITE = "dialog_savegameOverwrite",
	TUTORIAL_NOT_SAVED = "ui_tutorialIsNotSaved",
	BUTTON_SAVE_GAME = "button_saveGame",
	SAVING_CONTENT = "ui_savingContent",
	SAVE_NO_SPACE = "ui_savegameSaveNoSpace",
	MASTER_SERVER_CONNECTION_LOST = "ui_masterServerConnectionLost",
	BUTTON_CANCEL_GAME = "button_cancelGame",
	END_TUTORIAL = "ui_endTutorial",
	NOT_SAVED = "ui_savegameNotSaved",
	SAVE_NO_DEVICE = "ui_savegameSaveNoDevice",
	BUTTON_BACK = "button_back"
}
InGameMenu.PROFILES = {
	TAB_BAR_DARK = "uiInGameMenuHeaderDark",
	TAB_BAR_LIGHT = "uiInGameMenuHeader"
}
