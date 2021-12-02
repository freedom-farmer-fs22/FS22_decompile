source("dataS/scripts/gui/hud/mapHotspots/MapHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/AIHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/AITargetHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/FieldHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/MissionHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/PlaceableHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/PlayerHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/TourHotspot.lua")
source("dataS/scripts/gui/hud/mapHotspots/VehicleHotspot.lua")
source("dataS/scripts/gui/hud/VehicleHUDExtension.lua")
source("dataS/scripts/gui/hud/HUDElement.lua")
source("dataS/scripts/gui/hud/HUDDisplayElement.lua")
source("dataS/scripts/gui/hud/HUDFrameElement.lua")
source("dataS/scripts/gui/hud/GameInfoDisplay.lua")
source("dataS/scripts/gui/hud/SpeedMeterDisplay.lua")
source("dataS/scripts/gui/hud/FillLevelsDisplay.lua")
source("dataS/scripts/gui/hud/InputGlyphElement.lua")
source("dataS/scripts/gui/hud/ContextActionDisplay.lua")
source("dataS/scripts/gui/hud/AchievementMessage.lua")
source("dataS/scripts/gui/hud/IngameMap.lua")
source("dataS/scripts/gui/hud/IngameMapLayout.lua")
source("dataS/scripts/gui/hud/IngameMapLayoutCircle.lua")
source("dataS/scripts/gui/hud/IngameMapLayoutSquare.lua")
source("dataS/scripts/gui/hud/IngameMapLayoutSquareLarge.lua")
source("dataS/scripts/gui/hud/IngameMapLayoutNone.lua")
source("dataS/scripts/gui/hud/IngameMapLayoutFullscreen.lua")
source("dataS/scripts/gui/hud/InputHelpDisplay.lua")
source("dataS/scripts/gui/hud/VehicleSchemaDisplay.lua")
source("dataS/scripts/gui/hud/HUDPopupMessage.lua")
source("dataS/scripts/gui/hud/SideNotification.lua")
source("dataS/scripts/gui/hud/TopNotification.lua")
source("dataS/scripts/gui/hud/GamePausedDisplay.lua")
source("dataS/scripts/gui/hud/HUDTextDisplay.lua")
source("dataS/scripts/gui/hud/ChatWindow.lua")
source("dataS/scripts/gui/hud/SpeakerDisplay.lua")
source("dataS/scripts/gui/hud/HUDRoundedBarElement.lua")
source("dataS/scripts/gui/hud/InfoDisplay.lua")
source("dataS/scripts/gui/hud/InfoHUDBox.lua")
source("dataS/scripts/gui/hud/KeyValueInfoHUDBox.lua")

HUD = {}
local HUD_mt = Class(HUD)
HUD.SCHEMA_OVERLAY_DEFINITIONS_PATH = "dataS/vehicleSchemaOverlays.xml"
HUD.MENU_BACKGROUND_PATH = "shared/splashBlur.png"
HUD.CONTEXT_PRIORITY = {
	HIGH = 3,
	LOW = 1,
	MEDIUM = 2
}
HUD.GAME_INFO_PART = {
	TIME = 2,
	TEMPERATURE = 4,
	MONEY = 1,
	WEATHER = 8,
	TUTORIAL = 16,
	NONE = 0
}
HUD.ACHIEVEMENT_DISPLAY_DURATION = 5000
HUD.FADE_FOLLOW_DELAY = 100

function HUD.new(isServer, isClient, isConsoleVersion, messageCenter, l10n, inputManager, inputDisplayManager, modManager, fillTypeManager, fruitTypeManager, guiSoundPlayer, currentMission, farmManager, farmlandManager, customMt)
	local self = setmetatable({}, customMt or HUD_mt)
	self.isServer = isServer
	self.isClient = isClient
	self.isConsoleVersion = isConsoleVersion
	self.messageCenter = messageCenter
	self.l10n = l10n
	self.inputManager = inputManager
	self.inputDisplayManager = inputDisplayManager
	self.modManager = modManager
	self.fillTypeManager = fillTypeManager
	self.fruitTypeManager = fruitTypeManager
	self.guiSoundPlayer = guiSoundPlayer
	self.plusOverlay = inputDisplayManager:getPlusOverlay()
	self.currentMission = currentMission
	self.farmManager = farmManager
	self.farmlandManager = farmlandManager
	self.environment = nil
	self.missionInfo = nil
	self.missionStats = nil
	self.isVisible = true
	self.controlPlayer = true
	self.isMenuVisible = false
	self.controlledVehicle = nil
	self.vehicleSchemaOverlays = {}
	self.vehicleHudExtensions = {}
	self.requireHudExtensionsRefresh = false
	self.displayComponents = {}
	self.showTime = true
	self.allowHelpText = false
	self.showVehicleInfo = true
	self.ingameMap = nil
	self.presentationVersionElement = nil
	self.gamePausedDisplay = nil
	self.vehicleNameDisplay = nil
	self.blinkingWarningDisplay = nil
	self.fadeScreenElement = nil
	self.popupMessage = nil
	self.inGameIcon = nil
	self.gameInfoDisplay = nil
	self.vehicleSchema = nil
	self.inputHelp = nil
	self.speedMeter = nil
	self.fillLevelsDisplay = nil
	self.contextActionDisplay = nil
	self.achievementMessage = nil
	self.sideNotifications = nil
	self.topNotification = nil
	self.chatWindow = nil
	self.speakerDisplay = nil
	self.menuBackgroundOverlay = nil
	self.fadeAnimation = TweenSequence.NO_SEQUENCE
	self.fadeFollowDelay = 0
	self.ingameNotificationTime = 12000
	self.moneyChanges = {}
	self.extraTexts = {}
	self.warningsNumLines = {}
	self.showWeatherForecast = true
	self.showHudMissionBase = false
	self.showVehicleSchema = true
	self.chatMessagesShowNum = 7
	self.chatMessagesShowOffset = 0
	self.contextIconOverlays = {}
	local uiScale = g_gameSettings:getValue("uiScale")

	self:createDisplayComponents(uiScale)
	self:subscribeMessages()
	addConsoleCommand("gsHudVisibility", "Toggle HUd visibility", "consoleCommandToggleVisibility", self)

	return self
end

function HUD:consoleCommandToggleVisibility()
	self:setIsVisible(not self:getIsVisible())

	if self:getIsVisible() then
		g_noHudModeEnabled = false

		return "HUD is now visible"
	else
		g_noHudModeEnabled = true

		return "Warning: HUD is now disabled. Use 'gsHudVisibility' to enable again"
	end
end

function HUD:createDisplayComponents(uiScale)
	self.ingameMap = IngameMap.new(self, g_baseHUDFilename, self.inputDisplayManager)

	self.ingameMap:setScale(uiScale)
	table.insert(self.displayComponents, self.ingameMap)

	if g_isPresentationVersion and g_isPresentationVersionLogoEnabled then
		self.ingameMap:setIsVisible(false)

		local width, height = getNormalizedScreenValues(600, 150)
		local overlay = Overlay.new("dataS/menu/presentationVersionLogo.png", g_safeFrameOffsetX, g_safeFrameOffsetY, width, height)
		self.presentationVersionElement = HUDElement.new(overlay)

		table.insert(self.displayComponents, self.presentationVersionElement)
	end

	self.gamePausedDisplay = GamePausedDisplay.new(g_baseHUDFilename)

	self.gamePausedDisplay:setScale(uiScale)
	self.gamePausedDisplay:setVisible(false)
	table.insert(self.displayComponents, self.gamePausedDisplay)

	self.menuBackgroundOverlay = Overlay.new(HUD.MENU_BACKGROUND_PATH, 0.5, 0, 1, g_screenWidth / g_screenHeight)

	self.menuBackgroundOverlay:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_CENTER)

	self.vehicleNameDisplay = HUDTextDisplay.new(0.5, g_safeFrameOffsetY, HUD.TEXT_SIZE.VEHICLE_NAME, RenderText.ALIGN_CENTER, HUD.COLOR.VEHICLE_NAME, true)

	self.vehicleNameDisplay:setTextShadow(true, HUD.COLOR.VEHICLE_NAME_SHADOW)

	local nameFadeTween = TweenSequence.new(self.vehicleNameDisplay)

	nameFadeTween:addTween(Tween.new(self.vehicleNameDisplay.setAlpha, 0, 1, HUD.ANIMATION.VEHICLE_NAME_FADE))
	nameFadeTween:addInterval(HUD.ANIMATION.VEHICLE_NAME_SHOW)
	nameFadeTween:addTween(Tween.new(self.vehicleNameDisplay.setAlpha, 1, 0, HUD.ANIMATION.VEHICLE_NAME_FADE))
	self.vehicleNameDisplay:setAnimation(nameFadeTween)
	self.vehicleNameDisplay:setVisible(false, false)
	table.insert(self.displayComponents, self.vehicleNameDisplay)

	self.blinkingWarning = nil
	self.blinkingWarningDisplay = HUDTextDisplay.new(0.5, 0.5, HUD.TEXT_SIZE.BLINKING_WARNING, RenderText.ALIGN_CENTER, HUD.COLOR.BLINKING_WARNING, true)
	local blinkTween = TweenSequence.new(self.blinkingWarningDisplay)

	blinkTween:addTween(MultiValueTween.new(self.blinkingWarningDisplay.setTextColorChannels, HUD.COLOR.BLINKING_WARNING_1, HUD.COLOR.BLINKING_WARNING_2, HUD.ANIMATION.BLINKING_WARNING_TIME))
	blinkTween:addTween(MultiValueTween.new(self.blinkingWarningDisplay.setTextColorChannels, HUD.COLOR.BLINKING_WARNING_2, HUD.COLOR.BLINKING_WARNING_1, HUD.ANIMATION.BLINKING_WARNING_TIME))
	blinkTween:setLooping(true)
	self.blinkingWarningDisplay:setAnimation(blinkTween)
	self.blinkingWarningDisplay:setVisible(false)
	table.insert(self.displayComponents, self.blinkingWarningDisplay)

	local fadeOverlay = Overlay.new(g_baseHUDFilename, 0, 0, 1, 1)

	fadeOverlay:setUVs(GuiUtils.getUVs(HUD.UV.AREA))
	fadeOverlay:setColor(0, 0, 0, 0)

	self.fadeScreenElement = HUDElement.new(fadeOverlay)

	table.insert(self.displayComponents, self.fadeScreenElement)

	self.popupMessage = HUDPopupMessage.new(g_baseHUDFilename, self.l10n, self.inputManager, self.inputDisplayManager, self.ingameMap, self.guiSoundPlayer)

	self.popupMessage:setScale(uiScale)
	self.popupMessage:storeOriginalPosition()
	table.insert(self.displayComponents, self.popupMessage)

	self.inGameIcon = InGameIcon.new()

	table.insert(self.displayComponents, self.inGameIcon)

	self.gameInfoDisplay = GameInfoDisplay.new(g_baseHUDFilename, g_gameSettings:getValue("moneyUnit"), self.l10n)

	self.gameInfoDisplay:setScale(uiScale)
	self.gameInfoDisplay:setTemperatureVisible(false)
	table.insert(self.displayComponents, self.gameInfoDisplay)

	self.vehicleSchema = VehicleSchemaDisplay.new(self.modManager)

	self.vehicleSchema:setScale(uiScale)
	self.vehicleSchema:setDocked(g_gameSettings:getValue("showHelpMenu"), false)
	self.vehicleSchema:loadVehicleSchemaOverlays()
	table.insert(self.displayComponents, self.vehicleSchema)

	self.speakerDisplay = SpeakerDisplay.new(g_baseHUDFilename, self.ingameMap)

	self.speakerDisplay:setScale(uiScale)
	self.speakerDisplay:storeOriginalPosition()
	self.speakerDisplay:setVisible(false, false)
	table.insert(self.displayComponents, self.speakerDisplay)

	self.chatWindow = ChatWindow.new(g_baseHUDFilename, self.speakerDisplay)

	self.chatWindow:setScale(uiScale)
	self.chatWindow:storeOriginalPosition()
	self.chatWindow:setVisible(false, false)
	table.insert(self.displayComponents, self.chatWindow)

	self.inputHelp = InputHelpDisplay.new(g_baseHUDFilename, self.messageCenter, self.inputManager, self.inputDisplayManager, self.ingameMap, self.chatWindow, self.popupMessage, self.isConsoleVersion)

	self.inputHelp:setScale(uiScale)
	self.inputHelp:storeOriginalPosition()
	self.inputHelp:setVisible(g_gameSettings:getValue("showHelpMenu"), false)
	table.insert(self.displayComponents, self.inputHelp)

	self.speedMeter = SpeedMeterDisplay.new(g_baseHUDFilename)

	self.speedMeter:setVehicle(self.controlledVehicle)
	self.speedMeter:setScale(uiScale)
	self.speedMeter:storeOriginalPosition()
	self.speedMeter:setVisible(false, false)
	table.insert(self.displayComponents, self.speedMeter)

	self.fillLevelsDisplay = FillLevelsDisplay.new(g_baseHUDFilename)

	self.fillLevelsDisplay:setVehicle(self.controlledVehicle)
	self.fillLevelsDisplay:refreshFillTypes(self.fillTypeManager)
	self.fillLevelsDisplay:setScale(uiScale)
	self.fillLevelsDisplay:storeOriginalPosition()
	self.fillLevelsDisplay:setVisible(false, false)
	table.insert(self.displayComponents, self.fillLevelsDisplay)

	self.contextActionDisplay = ContextActionDisplay.new(g_baseHUDFilename, self.inputDisplayManager)

	self.contextActionDisplay:setScale(uiScale)
	self.contextActionDisplay:setVisible(false, false)
	table.insert(self.displayComponents, self.contextActionDisplay)

	self.achievementMessage = AchievementMessage.new(g_baseHUDFilename, self.inputManager, self.guiSoundPlayer, self.contextActionDisplay)

	self.achievementMessage:setScale(uiScale)
	self.achievementMessage:setVisible(false, false)
	table.insert(self.displayComponents, self.achievementMessage)

	self.sideNotifications = SideNotification.new(nil, g_baseHUDFilename)

	self.sideNotifications:setScale(uiScale)
	self.sideNotifications:storeOriginalPosition()
	self.sideNotifications:setVisible(true, false)
	table.insert(self.displayComponents, self.sideNotifications)

	self.topNotification = TopNotification.new(g_baseHUDFilename)

	self.topNotification:setScale(uiScale)
	self.topNotification:storeOriginalPosition()
	self.topNotification:setVisible(false, false)
	table.insert(self.displayComponents, self.topNotification)

	self.infoDisplay = InfoDisplay.new(g_baseHUDFilename)

	self.infoDisplay:setScale(uiScale)
	self.infoDisplay:storeOriginalPosition()
	self.infoDisplay:setVisible(false, false)
	table.insert(self.displayComponents, self.infoDisplay)
end

function HUD:delete()
	for k, v in pairs(self.displayComponents) do
		if v then
			v:delete()

			self.displayComponents[k] = nil
		end
	end

	self.menuBackgroundOverlay:delete()

	self.menuBackgroundOverlay = nil

	self.messageCenter:unsubscribeAll(self)
	removeConsoleCommand("gsHudVisibility")
end

function HUD:subscribeMessages()
	self.messageCenter:subscribe(MessageType.ACHIEVEMENT_UNLOCKED, self.showAchievementMessage, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.SHOW_HELP_MENU], self.setInputHelpVisible, self)
end

function HUD:setScale(scale)
	for _, element in pairs(self.displayComponents) do
		if element.setScale ~= nil then
			element:setScale(scale, scale)
		end
	end

	self.requireHudExtensionsRefresh = true
end

function HUD:drawControlledEntityHUD()
	if self.isVisible then
		if self.controlledVehicle ~= nil then
			if self.showVehicleInfo then
				self.controlledVehicle:draw()
			end
		elseif self.controlPlayer and self.player ~= nil then
			self.player:draw()
			self.infoDisplay:draw()
		end

		self.fillLevelsDisplay:draw()
		self.speedMeter:draw()
		self.contextActionDisplay:draw()
	end
end

function HUD:drawInputHelp()
	if self.isVisible and not self.popupMessage:getVisible() and self.fadeFollowDelay <= 0 then
		self.inputHelp:draw()

		if not self.isMenuVisible then
			self.vehicleSchema:draw()
		end
	end
end

function HUD:drawTopNotification()
	self.topNotification:draw()
end

function HUD:drawBlinkingWarning()
	if not self.popupMessage:getVisible() and self.blinkingWarning ~= nil then
		self.blinkingWarningDisplay:draw()
	end
end

function HUD:drawPresentationVersion()
	if g_isPresentationVersion and g_isPresentationVersionLogoEnabled then
		self.presentationVersionElement:draw()
	end
end

function HUD:drawFading()
	if self.fadeScreenElement:getVisible() and not self.isMenuVisible then
		self.fadeScreenElement:draw()
	end
end

function HUD:drawOverlayAtPositionWithDimensions(overlay, screenX, screenY, screenWidth, screenHeight)
	overlay:setDimension(screenWidth, screenHeight)
	overlay:setPosition(screenX, screenY)
	overlay:render()
end

function HUD:drawOverlayAtPosition(overlay, screenX, screenY)
	overlay:setPosition(screenX, screenY)
	overlay:render()
end

function HUD:drawSideNotification()
	self.sideNotifications:draw()
end

function HUD:drawBaseHUD()
	self.ingameMap:draw()
	self.gameInfoDisplay:draw()
	self:drawSideNotification()
	self.achievementMessage:draw()
end

function HUD:drawCommunicationDisplay()
	if self.isVisible and not self:getIsFading() then
		self.chatWindow:draw()
		self.speakerDisplay:draw()
	end
end

function HUD:setTutorialProgress(progress)
	self.gameInfoDisplay:setTutorialProgress(progress)
end

function HUD:drawGamePaused(beforeMissionStart)
	if beforeMissionStart then
		self.menuBackgroundOverlay:render()
	else
		self.gamePausedDisplay:draw()
	end
end

function HUD:drawVehicleName()
	local hasVehicle = self.currentVehicleName ~= nil
	local isObstructed = self.popupMessage:getVisible() or self.contextActionDisplay:getVisible()

	if not self.isMenuVisible and hasVehicle and not isObstructed then
		self.vehicleNameDisplay:draw()
	end
end

function HUD:drawInGameMessageAndIcon()
	self.popupMessage:draw()

	local posX, posY = self.inputHelp:getPosition()

	self.inGameIcon:setPosition(posX, posY)
	self.inGameIcon:draw()
end

function HUD:drawMissionCompleted()
	self:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_messageTutorialAccomplished"), -1, nil, self.onEndMissionCallback, self)
end

function HUD:drawMissionFailed()
	self:showInGameMessage(g_i18n:getText("ui_tutorial"), g_i18n:getText("tutorial_messageTutorialFailed"), -1, nil, self.onEndMissionCallback, self)
end

function HUD:showInGameMessage(title, message, duration, controlGlyphs, callback, callbackTarget)
	self.popupMessage:showMessage(title, message, duration, controlGlyphs, callback, callbackTarget)
end

function HUD:isInGameMessageVisible()
	return self.popupMessage:getVisible()
end

function HUD:showBlinkingWarning(text, duration, priority)
	if priority == nil then
		priority = 0
	end

	if self.blinkingWarning == nil or self.blinkingWarning.priority <= priority and text ~= self.blinkingWarning.text then
		self.blinkingWarning = {
			text = text,
			duration = duration or 2000,
			priority = priority
		}

		self.blinkingWarningDisplay:setText(text)
		self.blinkingWarningDisplay:setVisible(true, true)
	elseif self.blinkingWarning ~= nil and self.blinkingWarning.priority == priority and text == self.blinkingWarning.text then
		self.blinkingWarning.duration = duration or 2000
	end
end

function HUD:addMoneyChange(moneyType, amount)
	if self.moneyChanges[moneyType.id] == nil then
		self.moneyChanges[moneyType.id] = 0
	end

	self.moneyChanges[moneyType.id] = self.moneyChanges[moneyType.id] + amount
end

function HUD:showMoneyChange(moneyType, text)
	if self.moneyChanges[moneyType.id] ~= nil and self.moneyChanges[moneyType.id] ~= 0 then
		local change = self.moneyChanges[moneyType.id]

		if text == nil then
			text = g_i18n:getText(moneyType.title)
		end

		if text ~= nil and text ~= "" then
			text = " (" .. text .. ")"
		else
			text = ""
		end

		if change > 0 then
			self:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_OK, string.format("+ %s%s", g_i18n:formatMoney(change, 0, true), text), nil, GuiSoundPlayer.SOUND_SAMPLES.TRANSACTION)
		elseif change <= -1 then
			self:addSideNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, string.format("- %s%s", g_i18n:formatMoney(math.abs(change), 0, true), text), nil, GuiSoundPlayer.SOUND_SAMPLES.TRANSACTION)
		end

		self.moneyChanges[moneyType.id] = 0
	end
end

function HUD:addExtraPrintText(text)
	self.inputHelp:addHelpText(text)
end

function HUD:showVehicleName(vehicleName)
	self.vehicleNameDisplay:setVisible(false, true)

	self.currentVehicleName = vehicleName

	self.vehicleNameDisplay:setText(vehicleName)
	self.vehicleNameDisplay:setVisible(true, true)

	self.vehicleNameTextTime = HUD.ANIMATION.VEHICLE_NAME_SHOW + HUD.ANIMATION.VEHICLE_NAME_FADE * 2
end

function HUD:addSideNotification(color, text, duration, sound)
	self.sideNotifications:addNotification(text, color, duration or self.ingameNotificationTime)

	if sound ~= nil then
		self.guiSoundPlayer:playSample(sound)
	end
end

function HUD:addTopNotification(title, text, info, icon, duration, notification, iconFilename)
	self.topNotification:setNotification(title, text, info, icon, duration, iconFilename)
end

function HUD:hideTopNotification()
	self.topNotification:setVisible(false, true)
end

function HUD:getIsFading()
	return not self.fadeAnimation:getFinished() or self.fadeScreenElement:getAlpha() > 0
end

function HUD:setGameInfoPartVisibility(partFlags)
	local moneyVisible = bitAND(partFlags, HUD.GAME_INFO_PART.MONEY) ~= 0
	local timeVisible = bitAND(partFlags, HUD.GAME_INFO_PART.TIME) ~= 0
	local weatherVisible = bitAND(partFlags, HUD.GAME_INFO_PART.WEATHER) ~= 0
	local tutorialVisible = bitAND(partFlags, HUD.GAME_INFO_PART.TUTORIAL) ~= 0

	self.gameInfoDisplay:setMoneyVisible(moneyVisible)
	self.gameInfoDisplay:setTimeVisible(timeVisible)
	self.gameInfoDisplay:setDateVisible(timeVisible)
	self.gameInfoDisplay:setTemperatureVisible(false)
	self.gameInfoDisplay:setWeatherVisible(weatherVisible)
	self.gameInfoDisplay:setTutorialVisible(tutorialVisible)
end

function HUD:onMenuVisibilityChange(isMenuVisible, isOverlayMenu)
	self.isMenuVisible = isMenuVisible

	self.achievementMessage:onMenuVisibilityChange(isMenuVisible)
	self.popupMessage:onMenuVisibilityChange(isMenuVisible)
	self.gamePausedDisplay:onMenuVisibilityChange(isMenuVisible, isOverlayMenu)
	self.chatWindow:onMenuVisibilityChange(isMenuVisible)
	self.speakerDisplay:onMenuVisibilityChange(isMenuVisible, isOverlayMenu)
	self.inputHelp:onMenuVisibilityChange(isMenuVisible, isOverlayMenu)
end

function HUD:onMapVisibilityChange(isMapVisible)
end

function HUD:onPauseGameChange(isPaused, pauseText)
	if isPaused ~= nil then
		self.popupMessage:setPaused(isPaused)
		self.gamePausedDisplay:setVisible(isPaused)
	end

	self.gamePausedDisplay:setPauseText(pauseText)
end

function HUD:setIsVisible(isVisible)
	self.isVisible = isVisible
	self.allowShowWeatherForecast = self.showWeatherForecast or self.allowShowWeatherForecast
	self.allowShowTime = self.showTime or self.allowShowTime
	self.allowShowVehicleInfo = self.showVehicleInfo or self.allowShowVehicleInfo
	self.allowHelpText = g_gameSettings:getValue("showHelpMenu") or self.allowHelpText
	self.showWeatherForecast = isVisible and self.allowShowWeatherForecast

	g_gameSettings:setValue("showHelpMenu", isVisible and self.allowHelpText)

	self.showTime = isVisible and self.allowShowTime
	self.showVehicleInfo = isVisible and self.allowShowVehicleInfo

	if self.showHudMissionBaseOriginal == nil then
		self.showHudMissionBaseOriginal = self.showHudMissionBase
	end

	self.showHudMissionBase = isVisible and self.showHudMissionBaseOriginal
	self.showVehicleSchema = isVisible
end

function HUD:setInputHelpVisible(isVisible)
	self.inputHelp:setVisible(isVisible, true)
	self.vehicleSchema:setDocked(isVisible, true)
end

function HUD:setInfoVisible(isVisible)
	self.infoDisplay:setEnabled(isVisible)
	self.speakerDisplay:onDetailViewVisibilityChange(self.controlledVehicle ~= nil and self.controlledVehicle.spec_motorized ~= nil, isVisible)
end

function HUD:addCustomInputHelpEntry(actionName1, actionName2, displayText, ignoreComboButtons)
	self.inputHelp:addCustomEntry(actionName1, actionName2, displayText, ignoreComboButtons)
end

function HUD:clearCustomInputHelpEntries()
	self.inputHelp:clearCustomEntries()
end

function HUD:getIsVisible()
	return self.isVisible
end

function HUD:setControlledVehicle(vehicle)
	self.controlledVehicle = vehicle

	self.inputHelp:setVehicle(vehicle)
	self.speedMeter:setVehicle(vehicle)
	self.speedMeter:setVisible(vehicle ~= nil and vehicle.spec_motorized ~= nil, true)
	self.speakerDisplay:onDetailViewVisibilityChange(vehicle ~= nil and vehicle.spec_motorized ~= nil, self.infoDisplay:getVisible())
	self.fillLevelsDisplay:setVehicle(vehicle)
	self.fillLevelsDisplay:setVisible(vehicle ~= nil, true)
	self.vehicleSchema:setVehicle(vehicle)
end

function HUD:setIsControllingPlayer(isControllingPlayer)
	self.controlPlayer = isControllingPlayer
end

function HUD:setMoneyUnit(unit)
	self.gameInfoDisplay:setMoneyUnit(unit)
end

function HUD:showAchievementMessage(achievementName, achievementDescription, iconFilename, iconUVs)
	self.achievementMessage:showMessage(achievementName, achievementDescription, iconFilename, iconUVs, HUD.ACHIEVEMENT_DISPLAY_DURATION)
end

function HUD:showAttachContext(attachVehicleName)
	self.contextActionDisplay:setContext(InputAction.ATTACH, ContextActionDisplay.CONTEXT_ICON.ATTACH, attachVehicleName, HUD.CONTEXT_PRIORITY.LOW)
end

function HUD:showTipContext(fillTypeName)
	self.contextActionDisplay:setContext(InputAction.TOGGLE_TIPSTATE, ContextActionDisplay.CONTEXT_ICON.TIP, fillTypeName, HUD.CONTEXT_PRIORITY.MEDIUM)
end

function HUD:showFuelContext(fuelingVehicleName)
	local actionText = g_i18n:getText("action_refuel")

	self.contextActionDisplay:setContext(InputAction.ACTIVATE_OBJECT, ContextActionDisplay.CONTEXT_ICON.FUEL, fuelingVehicleName, HUD.CONTEXT_PRIORITY.HIGH, actionText)
end

function HUD:showFillDogBowlContext(dogName)
	local actionText = g_i18n:getText("action_doghouseFillbowl")
	local targetText = dogName or ""

	self.contextActionDisplay:setContext(InputAction.ACTIVATE_OBJECT, ContextActionDisplay.CONTEXT_ICON.FILL_BOWL, targetText, HUD.CONTEXT_PRIORITY.LOW, actionText)
end

function HUD:setPlayer(player)
	self.player = player
end

function HUD:setConnectedUsers(users)
	self.speakerDisplay:setUsers(users)
end

function HUD:updateMessageAndIcon(dt)
	self.popupMessage:update(dt)
	self.inGameIcon:update(dt)
end

function HUD:update(dt)
	if not self.fadeAnimation:getFinished() then
		self.fadeAnimation:update(dt)
	end

	self.fadeFollowDelay = self.fadeFollowDelay - dt

	self.infoDisplay:update(dt)
	self.speedMeter:update(dt)
	self.fillLevelsDisplay:update(dt)
	self.gameInfoDisplay:update(dt)
	self.inputHelp:update(dt)
	self.vehicleSchema:update(dt)
	self.contextActionDisplay:update(dt)
	self.achievementMessage:update(dt)
	self.sideNotifications:update(dt)
	self.topNotification:update(dt)
	self.chatWindow:update(dt)
	self.speakerDisplay:update(dt)
	self.ingameMap:setHasUnreadMessages(self.chatWindow:getHasNewMessages())
end

function HUD:updateBlinkingWarning(dt)
	if self.blinkingWarning ~= nil then
		self.blinkingWarningDisplay:update(dt)

		self.blinkingWarning.duration = self.blinkingWarning.duration - dt

		if self.blinkingWarning.duration < 0 then
			self.blinkingWarning = nil

			self.blinkingWarningDisplay:setVisible(false, false)
		end
	end
end

function HUD:updateMap(dt)
	self.ingameMap:update(dt)
end

function HUD:updateVehicleName(dt)
	if self.currentVehicleName ~= nil then
		self.vehicleNameTextTime = self.vehicleNameTextTime - dt

		self.vehicleNameDisplay:update(dt)

		if self.vehicleNameTextTime < 0 then
			self.currentVehicleName = nil

			self.vehicleNameDisplay:setVisible(false, false)
		end
	end
end

function HUD:fadeScreen(direction, duration, callbackFunc, callbackTarget, arguments)
	local startAlpha = 0
	local endAlpha = 1

	if direction <= 0 then
		startAlpha = 1
		endAlpha = 0
	end

	local function callbackClosure()
		if callbackFunc ~= nil then
			callbackFunc(callbackTarget, arguments)
		end

		self.fadeFollowDelay = HUD.FADE_FOLLOW_DELAY
	end

	local seq = TweenSequence.new(self.fadeScreenElement)
	local tween = Tween.new(self.fadeScreenElement.setAlpha, startAlpha, endAlpha, duration)

	tween:setCurve(Tween.CURVE.EASE_IN)
	seq:addTween(tween)
	seq:addCallback(callbackClosure)
	seq:start()

	self.fadeAnimation = seq
end

function HUD:loadIngameMap(ingameMapFilename, ingameMapWidth, ingameMapHeight, fieldColor, grassFieldColor)
	self.ingameMap:loadMap(ingameMapFilename, ingameMapWidth, ingameMapHeight, fieldColor, grassFieldColor)
end

function HUD:setIngameMapSize(sizeIndex)
	self.ingameMap:toggleSize(sizeIndex)
	self.ingameMap:updateHotspotFilters()
end

function HUD:getIngameMap()
	return self.ingameMap
end

function HUD:isInGameMessageActive()
	return self.popupMessage:getVisible()
end

function HUD:mouseEvent(posX, posY, isDown, isUp, button)
	self.inGameIcon:mouseEvent(posX, posY, isDown, isUp, button)
end

function HUD:setEnvironment(environment)
	self.environment = environment

	self.gameInfoDisplay:setEnvironment(environment)
end

function HUD:setMissionInfo(missionInfo)
	self.missionInfo = missionInfo

	self.fillLevelsDisplay:refreshFillTypes(self.fillTypeManager)
	self.gameInfoDisplay:setMissionInfo(missionInfo)
end

function HUD:setMissionStats(missionStats)
	self.missionStats = missionStats

	self.gameInfoDisplay:setMissionStats(missionStats)
end

function HUD:setInGameIconOnPickup(fillType, amount, text, duration)
	if fillType == FillType.EGG then
		if self.inGameIcon.fileName ~= "dataS/menu/hud/egg.png" then
			self.inGameIcon:setIcon("dataS/menu/hud/egg.png")
		end

		self.inGameIcon:setText("+1")
		self.inGameIcon:showIcon(2000)
	end
end

function HUD:scrollChatMessages(delta)
	self.chatWindow:scrollChatMessages(delta)
end

function HUD:setChatWindowVisible(isVisible, animate)
	self.chatWindow:setVisible(isVisible, animate)
end

function HUD:setChatMessagesReference(chatMessages)
	self.chatWindow:setChatMessages(chatMessages)
end

function HUD:addChatMessage(msg, sender, farmId)
	self.chatWindow:addMessage(msg, sender, farmId)
	self.chatWindow:setVisible(true, true)
end

function HUD:registerInput()
	self.ingameMap:registerInput()
end

function HUD:addMapHotspot(hotspot)
	return self.ingameMap:addMapHotspot(hotspot)
end

function HUD:removeMapHotspot(hotspot)
	self.ingameMap:removeMapHotspot(hotspot)
end

HUD.UV = {
	AREA = {
		8,
		8,
		2,
		2
	}
}
HUD.COLOR = {
	TUTORIAL_STATUS_VALUE = {
		0.0075,
		0.0075,
		0.0075,
		1
	},
	TUTORIAL_STATUS_BACKGROUND = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	FIELD_JOB_ICON = {
		1,
		0.491,
		0,
		1
	},
	FIELD_JOB_TIME_BACKGROUND = {
		0.0075,
		0.0075,
		0.0075,
		1
	},
	RADIO_STREAM = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	FRAME_BACKGROUND = {
		0.01,
		0.01,
		0.01,
		0.6
	},
	BLINKING_WARNING = {
		1,
		1,
		0.25,
		1
	},
	BLINKING_WARNING_1 = {
		1,
		1,
		0.25,
		1
	},
	BLINKING_WARNING_2 = {
		0.75,
		0,
		0,
		1
	},
	VEHICLE_NAME = {
		1,
		1,
		1,
		1
	},
	VEHICLE_NAME_SHADOW = {
		0,
		0,
		0,
		1
	}
}
HUD.TEXT_SIZE = {
	VEHICLE_NAME = 36,
	BLINKING_WARNING = GS_IS_MOBILE_VERSION and 50 or 24
}
HUD.ANIMATION = {
	VEHICLE_NAME_SHOW = 3000,
	VEHICLE_NAME_FADE = 1000,
	BLINKING_WARNING_TIME = 500
}
