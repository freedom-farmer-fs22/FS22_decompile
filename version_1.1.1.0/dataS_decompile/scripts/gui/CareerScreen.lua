CareerScreen = {}
local CareerScreen_mt = Class(CareerScreen, ScreenElement)
CareerScreen.CONTROLS = {
	SAVEGAME_LIST = "savegameList",
	BUTTON_DELETE = "buttonDelete",
	BUTTON_START = "buttonStart",
	LIST_ITEM_TEMPLATE = "listItemTemplate",
	LIST_SLIDER = "listSlider"
}
CareerScreen.LIST_TEMPLATE_ELEMENT_NAME = {
	MONEY = "money",
	CHARACTER = "character",
	TIME_PLAYED = "timePlayed",
	STATUS = "status",
	GAME_NAME = "gameName",
	INFO_TEXT = "infoText",
	DIFFICULTY = "difficulty",
	DATA_BOX = "dataBox",
	STATUS_ICON = "statusIcon",
	TITLE = "title",
	PLAYER_NAME = "playerName",
	GAME_ICON = "gameIcon",
	MAP_NAME = "mapName",
	CREATE_DATE = "createDate",
	TEXT_BOX = "textBox"
}
CareerScreen.MISSING_MAP_ICON_PATH = "dataS/menu/hud/missingMap.png"
CareerScreen.SAVEGAME_LOADING_DIALOG_DELAY = 100
CareerScreen.SAVEGAME_UPDATE_TIME = 20000
CareerScreen.SAVEGAME_REFRESH_TIME = 3000

function CareerScreen.new(target, custom_mt, savegameController, startMissionInfo)
	local self = ScreenElement.new(target, custom_mt or CareerScreen_mt)

	self:registerControls(CareerScreen.CONTROLS)

	self.savegameController = savegameController
	self.startMissionInfo = startMissionInfo
	self.isMultiplayer = false
	self.mapNameTexts = {}
	self.playerNameTexts = {}
	self.playerCharacterTexts = {}
	self.savegameNameTexts = {}
	self.moneyTexts = {}
	self.timePlayedTexts = {}
	self.difficultyTexts = {}
	self.dateTexts = {}
	self.statusTexts = {}
	self.statusIcons = {}
	self.listItemData = {}
	self.listItemTexts = {}
	self.listItemInfoText = {}
	self.savegames = {}
	self.tempIsSliderScrolling = false
	self.ignoreCorruptOnNextUpdate = false
	self.gameIcons = {}
	self.currentIndex = 0
	self.selectedIndexToRestore = 0
	self.recreateListOnOpen = true
	self.savegameUpdateTimer = CareerScreen.SAVEGAME_UPDATE_TIME
	self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME
	self.savegameLoadingDialogDelay = -1

	return self
end

function CareerScreen:onOpen()
	CareerScreen:superClass().onOpen(self)

	local canStart = self.startMissionInfo.canStart

	if canStart then
		self:startCurrentSavegame(true)
	else
		g_messageCenter:subscribe(MessageType.SAVEGAMES_LOADED, self.onSavegamesLoaded, self)

		self.selectedIndexToRestore = 0
		self.ignoreCorruptOnNextUpdate = false

		flushPhysicsCaches()

		if self.recreateListOnOpen then
			self.savegameController:resetStorageDeviceSelection()
			self:recreateSavegameList()
		end

		self:updateButtons()
	end

	g_messageCenter:publish(MessageType.GUI_CAREER_SCREEN_OPEN, canStart)
	self.savegameList:reloadData()
end

function CareerScreen:onClose()
	g_messageCenter:unsubscribe(MessageType.SAVEGAMES_LOADED, self)
	CareerScreen:superClass().onClose(self)
end

function CareerScreen:update(dt)
	CareerScreen:superClass().update(self, dt)

	if g_dedicatedServer ~= nil then
		self.selectedIndex = g_dedicatedServer.savegame
		local savegame = self.savegameController:getSavegame(self.selectedIndex)

		self:startSavegame(savegame)

		return
	end

	if self.savegameUpdateTimer >= 0 and not self.savegameController:getIsWaitingForSavegameInfo() and not g_gui:getIsDialogVisible() then
		self.savegameUpdateTimer = self.savegameUpdateTimer - dt

		if self.savegameUpdateTimer <= 0 then
			self.savegameUpdateTimer = -1

			self:recreateSavegameList()
		end
	end

	if self.savegameRefreshTimer >= 0 and not self.savegameController:getIsWaitingForSavegameInfo() then
		self.savegameRefreshTimer = self.savegameRefreshTimer - dt

		if self.savegameRefreshTimer <= 0 then
			self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME

			self.savegameController:loadSavegames()
		end
	end

	if not g_messageDialog:getIsOpen() and not self.savegameController:getIsWaitingForSavegameInfo() and self.savegameController:isStorageDeviceUnavailable() then
		g_gui:showYesNoDialog({
			text = g_i18n:getText("ui_savegamesScanSelectDevice"),
			callback = self.onYesNoSavegameSelectDevice,
			target = self
		})
	end

	if self.isMultiplayer then
		Platform.verifyMultiplayerAvailabilityInMenu()
	end

	if self.savegameController:getIsWaitingForSavegameInfo() then
		if self.savegameLoadingDialogDelay <= 0 then
			self.savegameLoadingDialogDelay = CareerScreen.SAVEGAME_LOADING_DIALOG_DELAY
		end
	elseif self.loadingDialog ~= nil then
		self.loadingDialog.target:close()

		self.loadingDialog = nil
	end

	if self.savegameLoadingDialogDelay > 0 then
		self.savegameLoadingDialogDelay = self.savegameLoadingDialogDelay - dt

		if self.savegameLoadingDialogDelay <= 0 then
			self.loadingDialog = g_gui:showDialog("InfoDialog")

			self.loadingDialog.target:setText(g_i18n:getText("ui_loadingSavegames"))
			self.loadingDialog.target:setButtonTexts(g_i18n:getText("button_cancel"))
			self.loadingDialog.target:setCallback(self.onCancelSavegameLoading, self)
		end
	end
end

function CareerScreen:onSavegamesLoaded()
	self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME

	self:setSoundSuppressed(true)
	self.savegameList:reloadData()
	self:setSoundSuppressed(false)
	self:calculateTotalPlaytime()
	self:updateButtons()
end

function CareerScreen:onStartAction(isMouseClick)
	self.savegameController:tryToResolveConflict(self.savegameList.selectedIndex, {
		target = self,
		callback = self.onStartAction,
		extraAttributes = {
			isMouseClick
		}
	}, {
		target = self,
		callback = self.recreateSavegameList,
		extraAttributes = {}
	})

	if self.savegameController:getCanStartGame(self.savegameList.selectedIndex) then
		local savegame = self.savegameController:getSavegame(self.savegameList.selectedIndex)

		self:startSavegame(savegame)
	end
end

function CareerScreen:onDeleteAction(sender)
	local currentIndex = self.savegameList.selectedIndex

	if self.savegameController:getIsSavegameConflicted(currentIndex) then
		self.savegameController:tryToResolveConflict(currentIndex, {
			target = self,
			callback = self.recreateSavegameList,
			extraAttributes = {}
		}, nil, false)

		return
	end

	if self.savegameController:getCanDeleteGame(currentIndex) then
		self.currentSavegame = self.savegameController:getSavegame(currentIndex)

		if GS_PLATFORM_PHONE then
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_youWantToDeleteSavegameMobile"),
				callback = self.onYesNoDeleteSavegame,
				target = self
			})
		else
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_youWantToDeleteSavegame"),
				callback = self.onYesNoDeleteSavegame,
				target = self
			})
		end
	end
end

function CareerScreen:onSaveGameUpdateComplete(errorCode)
	self.savegameRefreshTimer = CareerScreen.SAVEGAME_REFRESH_TIME
	self.savegameUpdateTimer = CareerScreen.SAVEGAME_UPDATE_TIME
	local ignoreCorruptOnNextUpdate = self.ignoreCorruptOnNextUpdate
	self.ignoreCorruptOnNextUpdate = false

	if errorCode == Savegame.ERROR_OK or errorCode == Savegame.ERROR_DATA_CORRUPT then
		self.savegameController:loadSavegames()

		if errorCode == Savegame.ERROR_DATA_CORRUPT and not ignoreCorruptOnNextUpdate and g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen" then
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_someSavegamesCorrupt"),
				callback = self.onYesNoSavegameCorrupted,
				target = self,
				yesButton = g_i18n:getText("button_continue"),
				noButton = g_i18n:getText("button_cancel")
			})
		end
	elseif errorCode == Savegame.ERROR_SCAN_IN_PROGRESS then
		self.savegameUpdateTimer = 0
	elseif errorCode == Savegame.ERROR_SCAN_FAILED then
		if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen" then
			g_gui:showInfoDialog({
				text = g_i18n:getText("ui_savegamesScanFailed"),
				callback = self.onOkSavegameScanFailed,
				target = self
			})
		end
	elseif errorCode == Savegame.ERROR_DEVICE_UNAVAILABLE then
		if g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen" then
			g_gui:showInfoDialog({
				text = g_i18n:getText("ui_savegamesScanNoDevice"),
				callback = self.onOkSavegameScanFailed,
				target = self
			})
		end
	elseif g_gui:getIsGuiVisible() and g_gui.currentGuiName == "CareerScreen" then
		self:changeScreen(MainScreen)
	end

	if self.savegameUpdateTimer > 0 then
		self.savegameLoadingDialogDelay = -1

		if self.loadingDialog ~= nil then
			self.loadingDialog.target:close()

			self.loadingDialog = nil
		end
	end
end

function CareerScreen:calculateTotalPlaytime()
	local total = 0

	for i = 1, SavegameController.NUM_SAVEGAMES do
		local savegame = self.savegameController:getSavegame(i)

		if savegame.isValid then
			total = total + math.floor(savegame.playTime / 60 + 0.0001)
		end
	end

	self.totalPlayedHours = total
end

function CareerScreen:onYesNoSavegameCorrupted(yes)
	if yes then
		self.recreateListOnOpen = false

		self:changeScreen(CareerScreen, MainScreen)

		self.recreateListOnOpen = true
	else
		self:changeScreen(MainScreen)
	end
end

function CareerScreen:onOkSavegameScanFailed()
	self:changeScreen(MainScreen)
end

function CareerScreen:onSaveComplete(errorCode)
	if errorCode == Savegame.ERROR_OK then
		self:updateSavegameText(self.currentSavegame.savegameIndex)
	end
end

function CareerScreen:onCancelSavegameLoading()
	self.savegameController:cancelSavegameUpdate()
end

function CareerScreen:recreateSavegameList()
	if not self.savegameController:getIsWaitingForSavegameInfo() then
		self.savegameUpdateTimer = -1
		self.savegameRefreshTimer = -1
		self.savegameLoadingDialogDelay = CareerScreen.SAVEGAME_LOADING_DIALOG_DELAY

		self.savegameController:updateSavegames(self.onSaveGameUpdateComplete, self)
	elseif self.savegameUpdateTimer > 0 then
		self.savegameUpdateTimer = 0
	end
end

function CareerScreen:onYesNoDeleteSavegame(yes)
	if yes then
		self:deleteCurrentSavegame()
	else
		self.recreateListOnOpen = false

		self:changeScreen(CareerScreen, MainScreen)

		self.recreateListOnOpen = true
	end
end

function CareerScreen:updateButtons()
	local canDeleteGame = self.savegameController:getCanDeleteGame(self.savegameList.selectedIndex)

	if self.buttonDelete then
		self.buttonDelete:setDisabled(not canDeleteGame and not g_isPresentationVersion)
	end

	local canStartGame = self.savegameController:getCanStartGame(self.savegameList.selectedIndex)

	if self.buttonStart then
		self.buttonStart:setDisabled(not canStartGame)
	end
end

function CareerScreen:onYesNoSavegameSelectDevice(yes)
	if yes then
		self:changeScreen(CareerScreen)
	else
		self:changeScreen(MainScreen)
	end
end

function CareerScreen:startSavegame(savegame)
	self.currentSavegame = savegame

	if not savegame.isValid then
		if savegame.isInvalidUser then
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_savegameInvalidUser"),
				callback = self.onYesNoSavegameInvalidUser,
				target = self,
				yesButton = g_i18n:getText("button_continue"),
				noButton = g_i18n:getText("button_cancel")
			})
		elseif savegame.isCorruptFile then
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_savegameCorrupt"),
				callback = self.onYesNoSavegameInvalidUser,
				target = self,
				yesButton = g_i18n:getText("button_continue"),
				noButton = g_i18n:getText("button_cancel")
			})
		else
			self:onYesNoSavegameInvalidUser(true)
		end
	elseif savegame.map and not savegame.map.isMultiplayerSupported and self.isMultiplayer then
		g_gui:showInfoDialog({
			text = string.format(g_i18n:getText("ui_modsZipOnly"), savegame.map.title)
		})
	elseif SlotSystem.TOTAL_NUM_GARAGE_SLOTS[GS_PLATFORM_ID] < savegame.slotUsage then
		g_gui:showInfoDialog({
			text = g_i18n:getText("ui_savegameSlotLimitReached")
		})
	else
		local missingModTitles = {}
		local hasRequiredMissing = false
		local hasNoMpMods = false

		for _, modInfo in pairs(savegame.mods) do
			local mod = g_modManager:getModByName(modInfo.modName)

			if mod == nil then
				if modInfo.required then
					table.insert(missingModTitles, 1, modInfo.title)

					hasRequiredMissing = true
				else
					table.insert(missingModTitles, modInfo.title)
				end
			elseif not mod.isMultiplayerSupported and self.isMultiplayer then
				if not hasRequiredMissing and not GS_IS_CONSOLE_VERSION then
					hasNoMpMods = true

					table.insert(missingModTitles, 1, mod.title)
				else
					table.insert(missingModTitles, mod.title)
				end
			end
		end

		if #missingModTitles > 0 and g_dedicatedServer == nil then
			local numMissing = math.min(#missingModTitles, 4)
			local modsText = missingModTitles[1]

			for i = 2, numMissing do
				modsText = modsText .. ", " .. missingModTitles[i]
			end

			if hasRequiredMissing then
				g_gui:showInfoDialog({
					text = g_i18n:getText("ui_savegameHasMissingDlcs") .. "\n" .. modsText
				})
			elseif hasNoMpMods then
				g_gui:showInfoDialog({
					text = string.format(g_i18n:getText("ui_modsZipOnly"), missingModTitles[1]),
					callback = CareerScreen.onOkZipModsOptional,
					target = self
				})
			else
				g_gui:showYesNoDialog({
					text = g_i18n:getText("ui_savegameHasMissingDlcsOptional") .. "\n" .. modsText .. "\n\n" .. g_i18n:getText("ui_continueQuestion"),
					callback = self.onYesNoInstallMissingModsOptional,
					target = self,
					yesButton = g_i18n:getText("button_continue"),
					noButton = g_i18n:getText("button_cancel")
				})
			end
		else
			self:startCurrentSavegame()
		end
	end
end

function CareerScreen:onYesNoNotEnoughSpaceForNewSaveGame(yes)
	self.startMissionInfo.createGame = yes

	if yes then
		if g_isPresentationVersion and g_presentationVersionDifficulty ~= nil then
			self.startMissionInfo.difficulty = MathUtil.clamp(g_presentationVersionDifficulty, 1, 3)

			self:changeScreen(MapSelectionScreen, CareerScreen)
		else
			self:changeScreen(DifficultyScreen, CareerScreen)
		end
	else
		self:changeScreen(CareerScreen)
	end
end

function CareerScreen:onYesNoSavegameInvalidUser(yes)
	if yes then
		if saveGetHasSpaceForSaveGame(self.currentSavegame.savegameIndex, FSCareerMissionInfo.MaxSavegameSize) then
			self:onYesNoNotEnoughSpaceForNewSaveGame(true)
		else
			g_gui:showYesNoDialog({
				text = g_i18n:getText("ui_notEnoughSpaceForNewSavegame"),
				callback = self.onYesNoNotEnoughSpaceForNewSaveGame,
				target = self,
				yesButton = g_i18n:getText("button_continue"),
				noButton = g_i18n:getText("button_cancel")
			})
		end
	else
		self.recreateListOnOpen = false

		self:changeScreen(CareerScreen)

		self.recreateListOnOpen = true
	end
end

function CareerScreen:onYesNoInstallMissingModsOptional(yes)
	if yes then
		self:startCurrentSavegame()
	else
		self.recreateListOnOpen = false

		self:changeScreen(CareerScreen)

		self.recreateListOnOpen = true
	end
end

function CareerScreen:onOkZipModsOptional()
	self:startCurrentSavegame()
end

function CareerScreen:startCurrentSavegame(useStartMissionInfo)
	local savegame = self.currentSavegame

	if useStartMissionInfo then
		savegame:setMapId(self.startMissionInfo.mapId)
		savegame:setDifficulty(self.startMissionInfo.difficulty)
	end

	savegame.isNewSPCareer = false

	if not savegame.isValid then
		savegame.startSiloAmounts = {}

		if not g_isPresentationVersion then
			if savegame.difficulty == 1 then
				local low = 8000
				local high = 16000
				savegame.startSiloAmounts.wheat = math.random(low, high)
				savegame.startSiloAmounts.barley = math.random(low, high)
				savegame.startSiloAmounts.canola = math.random(low, high)
				savegame.startSiloAmounts.maize = math.random(low, high)
				savegame.startSiloAmounts.oat = math.random(low, high)
				savegame.startSiloAmounts.soybean = math.random(low, high)
				savegame.startSiloAmounts.sunflower = math.random(low, high)
			end
		else
			savegame.startSiloAmounts.wheat = 40000
		end

		savegame.vehiclesXMLLoad = savegame.defaultVehiclesXMLFilename
		savegame.itemsXMLLoad = savegame.defaultItemsXMLFilename
		savegame.placeablesXMLLoad = savegame.defaultPlaceablesXMLFilename
		savegame.onCreateObjectsXMLLoad = nil
		savegame.environmentXML = nil
		savegame.economyXMLLoad = nil
		savegame.farmlandXMLLoad = nil
		savegame.aiSystemXMLLoad = nil
		savegame.npcXMLLoad = nil
		savegame.npcXMLLoad = nil
		savegame.densityMapHeightXMLLoad = nil
		savegame.treePlantXMLLoad = nil
		savegame.timeScale = Platform.gameplay.defaultTimeScale
		savegame.dirtInterval = 3
		savegame.trafficEnabled = true
		savegame.fieldJobMissionCount = 0
		savegame.fieldJobMissionByNPC = 0
		savegame.transportMissionCount = 0
		savegame.eastState1 = 0
		savegame.eastState2 = 0

		if g_isPresentationVersion then
			savegame.isNewSPCareer = false
		else
			savegame.isNewSPCareer = true
		end
	end

	local missionInfo = savegame
	local missionDynamicInfo = {
		isMultiplayer = self.isMultiplayer,
		autoSave = false
	}

	if self.isMultiplayer and g_modManager:getNumOfValidMods() > 0 or not self.isMultiplayer and g_modManager:getNumOfMods() > 0 then
		g_modSelectionScreen:setMissionInfo(missionInfo, missionDynamicInfo)

		self.startMissionInfo.canStart = false

		self:changeScreen(ModSelectionScreen, missionInfo.isValid and CareerScreen or MapSelectionScreen)
	else
		missionDynamicInfo.mods = {}

		self:startGame(missionInfo, missionDynamicInfo)
	end
end

function CareerScreen:startGame(missionInfo, missionDynamicInfo)
	if self.isMultiplayer then
		self.startMissionInfo.createGame = true

		g_createGameScreen:setMissionInfo(missionInfo, missionDynamicInfo)
		self:changeScreen(CreateGameScreen)
	else
		g_mpLoadingScreen:setMissionInfo(missionInfo, missionDynamicInfo)
		self:changeScreen(MPLoadingScreen)
		g_mpLoadingScreen:loadSavegameAndStart()
		self.startMissionInfo:reset()
	end
end

function CareerScreen:onSavegameDeleted(errorCode)
	self.recreateListOnOpen = false

	self:changeScreen(CareerScreen)

	self.recreateListOnOpen = true

	g_gui:showMessageDialog({
		visible = false
	})

	self.selectedIndexToRestore = self.currentSavegame.savegameIndex
	self.currentSavegame = nil
	self.ignoreCorruptOnNextUpdate = not self.savegameController:isStorageDeviceUnavailable()

	self:recreateSavegameList()
end

function CareerScreen:deleteCurrentSavegame()
	g_gui:showMessageDialog({
		isCloseAllowed = false,
		visible = true,
		text = g_i18n:getText("ui_deletingSavegame"),
		dialogType = DialogElement.TYPE_LOADING
	})
	self.savegameController:deleteSavegame(self.savegameList.selectedIndex, self.onSavegameDeleted, self)
end

function CareerScreen:setIsMultiplayer(isMultiplayer)
	self.isMultiplayer = isMultiplayer

	if self.isMultiplayer then
		self:setReturnScreen("MultiplayerScreen")
	else
		self:setReturnScreen("MainScreen")
	end
end

function CareerScreen:getNumberOfItemsInSection(list, section)
	return self.savegameController:getMaxNumberOfSavegames()
end

function CareerScreen:populateCellForItemInSection(list, section, index, cell)
	local savegame = self.savegameController:getSavegame(index)

	if Platform.isMobile then
		local letters = "ABC"

		cell:getAttribute("title"):setText(letters:sub(index, index))
	else
		cell:getAttribute("title"):setText(g_i18n:getText("ui_savegame") .. " " .. tostring(index))
	end

	cell:getAttribute("gameIcon"):setVisible(savegame.isValid)
	cell:getAttribute("title"):setVisible(savegame.isValid)
	cell:getAttribute("dataBox"):setVisible(savegame.isValid)
	cell:getAttribute("textBox"):setVisible(not savegame.isValid)

	if savegame.isValid then
		local playTimeHoursF = savegame.playTime / 60 + 0.0001
		local playTimeHours = math.floor(playTimeHoursF)
		local playTimeMinutes = math.floor((playTimeHoursF - playTimeHours) * 60)

		cell:getAttribute("gameName"):setText(savegame.savegameName)

		if savegame.map ~= nil then
			cell:getAttribute("mapName"):setText(savegame.map.title)
			cell:getAttribute("gameIcon"):setImageFilename(savegame.map.iconFilename)
		else
			cell:getAttribute("mapName"):setText(Utils.getNoNil(savegame.mapTitle, savegame.mapId))
			cell:getAttribute("gameIcon"):setImageFilename(CareerScreen.MISSING_MAP_ICON_PATH)
		end

		cell:getAttribute("money"):setText(g_i18n:formatMoney(savegame.money or 0, 0, not GS_IS_MOBILE_VERSION))
		cell:getAttribute("timePlayed"):setText(string.format("%02d:%02d", playTimeHours, playTimeMinutes))
		cell:getAttribute("difficulty"):setLocaKey("ui_difficulty" .. savegame.difficulty)
		cell:getAttribute("createDate"):setText(savegame.saveDateFormatted)

		if Platform.isMobile then
			local state = ""

			if GS_PLATFORM_PHONE then
				state = g_i18n:getText(savegame:getStateI18NKey())
			end

			cell:getAttribute("status"):setText(state)
			cell:getAttribute("status"):setVisible(state ~= "")
		end
	elseif savegame.isInvalidUser then
		cell:getAttribute("infoText"):setLocaKey("ui_savegameBelongsToAnotherUser")
	elseif savegame.isCorruptFile then
		cell:getAttribute("infoText"):setLocaKey("ui_savegameIsCorrupted")
	elseif Platform.isMobile then
		cell:getAttribute("infoText"):setLocaKey("ui_newGame")
	else
		cell:getAttribute("infoText"):setLocaKey("ui_savegameEmptySlot")
	end
end

function CareerScreen:onListSelectionChanged(list, section, index)
	self:updateButtons()
end

function CareerScreen:onAchievementsClick(element)
	self:changeScreen(MainScreen)
	FocusManager:setFocus(g_mainScreen.achievementsButton)
	g_mainScreen:onAchievementsClick(element)
end

function CareerScreen:onCreditsClick(element)
	self:changeScreen(MainScreen)
	FocusManager:setFocus(g_mainScreen.creditsButton)
	g_mainScreen:onCreditsClick(element)
end
