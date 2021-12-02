GameInfoDisplay = {}
local GameInfoDisplay_mt = Class(GameInfoDisplay, HUDDisplayElement)

function GameInfoDisplay.new(hudAtlasPath, moneyUnit, l10n)
	local backgroundOverlay = GameInfoDisplay.createBackground()
	local self = GameInfoDisplay:superClass().new(backgroundOverlay, nil, GameInfoDisplay_mt)
	self.moneyUnit = moneyUnit
	self.l10n = l10n
	self.missionStats = nil
	self.environment = nil
	self.showMoney = true
	self.showWeather = true
	self.showTemperature = true
	self.showTime = true
	self.showDate = true
	self.showTutorialProgress = false
	self.infoBoxes = {}
	self.moneyBox = nil
	self.moneyIconOverlay = nil
	self.timeBox = nil
	self.clockElement = nil
	self.timeScaleArrow = nil
	self.timeScaleArrowFast = nil
	self.clockHandLarge = nil
	self.clockHandSmall = nil
	self.dateBox = nil
	self.seasonElement = nil
	self.monthMaxSize = 0
	self.temperatureBox = nil
	self.temperatureIconStable = nil
	self.temperatureIconRising = nil
	self.temperatureIconDropping = nil
	self.weatherBox = nil
	self.weatherTypeIcons = {}
	self.tutorialBox = nil
	self.tutorialProgressBar = nil
	self.boxHeight = 0
	self.boxMarginHeight = 0
	self.boxMarginWidth = 0
	self.moneyBoxWidth = 0
	self.moneyTextSize = 0
	self.moneyTextPositionY = 0
	self.moneyTextPositionX = 0
	self.monthText = ""
	self.timeTextPositionY = 0
	self.timeTextPositionX = 0
	self.timeTextSize = 0
	self.timeScaleTextPositionY = 0
	self.timeScaleTextPositionX = 0
	self.timeScaleTextSize = 0
	self.timeText = ""
	self.clockHandLargePivotY = 0
	self.clockHandLargePivotX = 0
	self.clockHandSmallPivotY = 0
	self.clockHandSmallPivotX = 0
	self.dateTextPositionY = 0
	self.dateTextPositionX = 0
	self.temperatureHighTextPositionY = 0
	self.temperatureHighTextPositionX = 0
	self.temperatureLowTextPositionY = 0
	self.temperatureLowTextPositionX = 0
	self.temperatureTextSize = 0
	self.temperatureDayText = ""
	self.temperatureNightText = ""
	self.tutorialBarHeight = 0
	self.tutorialBarWidth = 0
	self.tutorialTextPositionX = 0
	self.tutorialTextPositionX = 0
	self.tutorialTextSize = 0
	self.tutorialText = utf8ToUpper(l10n:getText(GameInfoDisplay.L10N_SYMBOL.TUTORIAL))
	self.weatherAnimation = TweenSequence.NO_SEQUENCE
	self.currentWeather = ""
	self.nextWeather = ""
	self.temperatureAnimation = TweenSequence.NO_SEQUENCE
	self.lastTutorialProgress = 1

	self:createComponents(hudAtlasPath)

	return self
end

function GameInfoDisplay:setMoneyUnit(moneyUnit)
	if moneyUnit ~= GS_MONEY_EURO and moneyUnit ~= GS_MONEY_POUND and moneyUnit ~= GS_MONEY_DOLLAR then
		moneyUnit = GS_MONEY_DOLLAR
	end

	self.moneyUnit = moneyUnit
	self.moneyCurrencyText = g_i18n:getCurrencySymbol(true)
end

function GameInfoDisplay:setMissionStats(missionStats)
	self.missionStats = missionStats
end

function GameInfoDisplay:setMissionInfo(missionInfo)
	self.missionInfo = missionInfo
end

function GameInfoDisplay:setEnvironment(environment)
	self.environment = environment
end

function GameInfoDisplay:setMoneyVisible(isVisible)
	self.showMoney = isVisible

	self.moneyBox:setVisible(isVisible)
	self:storeScaledValues()
	self:updateSizeAndPositions()
end

function GameInfoDisplay:setTimeVisible(isVisible)
	self.showTime = isVisible

	self.timeBox:setVisible(isVisible)
	self:storeScaledValues()
	self:updateSizeAndPositions()
end

function GameInfoDisplay:setTemperatureVisible(isVisible)
	self.showTemperature = isVisible

	self.temperatureBox:setVisible(isVisible)
	self:storeScaledValues()
	self:updateSizeAndPositions()
end

function GameInfoDisplay:setWeatherVisible(isVisible)
	self.showWeather = isVisible

	self.weatherBox:setVisible(isVisible)
	self:storeScaledValues()
	self:updateSizeAndPositions()
end

function GameInfoDisplay:setTutorialVisible(isVisible)
	self.showTutorialProgress = isVisible

	self.tutorialBox:setVisible(isVisible)
	self:storeScaledValues()
	self:updateSizeAndPositions()
end

function GameInfoDisplay:setDateVisible(isVisible)
	self.showDate = isVisible

	self.dateBox:setVisible(isVisible)
	self:storeScaledValues()
	self:updateSizeAndPositions()
end

function GameInfoDisplay:setTutorialProgress(progress)
	if self.showTutorialProgress and progress ~= self.lastTutorialProgress then
		progress = MathUtil.clamp(progress, 0, 1)
		self.lastTutorialProgress = progress

		self.tutorialProgressBar:setDimension(self.tutorialBarWidth * progress)
	end
end

function GameInfoDisplay:update(dt)
	if self.showTime then
		self:updateTime()
	end

	if self.showTemperature then
		self:updateTemperature()
	end

	if self.showWeather then
		self:updateWeather(dt)
	end

	self:updateBackground()
end

function GameInfoDisplay:updateBackground()
	local width = self:getVisibleWidth()
	local posX, _ = GameInfoDisplay.getBackgroundPosition(1)

	self.backgroundOverlay:setDimension(width + g_safeFrameOffsetX)
	self.backgroundOverlay:setPosition(posX - self:getVisibleWidth())
end

function GameInfoDisplay:updateTime()
	local currentTime = self.environment.dayTime / 3600000
	local timeHours = math.floor(currentTime)
	local timeMinutes = math.floor((currentTime - timeHours) * 60)
	self.timeText = string.format("%02d:%02d", timeHours, timeMinutes)

	if self.missionInfo.timeScale < 1 then
		self.timeScaleText = string.format("%0.1f", self.missionInfo.timeScale)
	else
		self.timeScaleText = string.format("%d", self.missionInfo.timeScale)
	end

	self.monthText = g_i18n:formatDayInPeriod(nil, , true)

	self.seasonOverlay:setUVs(GuiUtils.getUVs(GameInfoDisplay.UV.SEASON[self.environment.currentSeason]))

	local hourRotation = -(currentTime % 12 / 12) * math.pi * 2
	local minutesRotation = -(currentTime - timeHours) * math.pi * 2

	self.clockHandSmall:setRotation(hourRotation)
	self.clockHandLarge:setRotation(minutesRotation)

	local isTimeScaleFast = self.missionInfo.timeScale > 1

	self.timeScaleArrow:setVisible(not isTimeScaleFast)
	self.timeScaleArrowFast:setVisible(isTimeScaleFast)
end

function GameInfoDisplay:updateTemperature()
	local minTemp, maxTemp = self.environment.weather:getCurrentMinMaxTemperatures()
	self.temperatureDayText = string.format("%d?", maxTemp)
	self.temperatureNightText = string.format("%d?", minTemp)
	local trend = self.environment.weather:getCurrentTemperatureTrend()

	self.temperatureIconStable:setVisible(trend == 0)
	self.temperatureIconRising:setVisible(trend > 0)
	self.temperatureIconDropping:setVisible(trend < 0)
end

function GameInfoDisplay:getWeatherStates()
	local sixHours = 21600000
	local env = self.environment
	local dayPlus6h, timePlus6h = env:getDayAndDayTime(env.dayTime + sixHours, env.currentMonotonicDay)
	local weatherState = env.weather:getCurrentWeatherType()
	local nextWeatherState = env.weather:getNextWeatherType(dayPlus6h, timePlus6h)

	return weatherState, nextWeatherState
end

function GameInfoDisplay:updateWeather(dt)
	if not self.environment.weather:getIsReady() then
		return
	end

	local weatherState, nextWeatherState = self:getWeatherStates()
	weatherState = weatherState or WeatherType.SUN
	nextWeatherState = nextWeatherState or WeatherType.SUN
	local hasChange = self.currentWeather ~= weatherState or self.nextWeather ~= nextWeatherState

	if hasChange then
		self.currentWeather = weatherState
		self.nextWeather = nextWeatherState

		self:animateWeatherChange()
	end

	if not self.weatherAnimation:getFinished() then
		self.weatherAnimation:update(dt)
	end
end

function GameInfoDisplay:getVisibleWidth()
	local width = -self.boxMarginWidth

	for _, box in pairs(self.infoBoxes) do
		if box:getVisible() then
			width = width + box:getWidth() + self.boxMarginWidth * 2
		end
	end

	if self.currentWeather == self.nextWeather then
		local boxWidth, _ = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.WEATHER_BOX)
		width = width - boxWidth / 2
	end

	return width
end

function GameInfoDisplay:updateSizeAndPositions()
	local width = self:getVisibleWidth()

	self:setDimension(width + g_safeFrameOffsetX, self:getHeight())

	local topRightX, topRightY = GameInfoDisplay.getBackgroundPosition(self:getScale())
	local bottomY = topRightY - self:getHeight()

	self:setPosition(topRightX - width, bottomY)

	local posX = topRightX
	local isRightMostBox = true

	for i, box in ipairs(self.infoBoxes) do
		if box:getVisible() then
			local leftMargin = self.boxMarginWidth
			local rightMargin = 0

			if i > 1 then
				rightMargin = self.boxMarginWidth
			end

			box:setPosition(posX - box:getWidth() - rightMargin, bottomY)

			posX = posX - box:getWidth() - leftMargin - rightMargin

			box.separator:setVisible(not isRightMostBox)

			isRightMostBox = false
		end
	end

	self:storeScaledValues()
end

function GameInfoDisplay:draw()
	GameInfoDisplay:superClass().draw(self)

	if self.showMoney then
		self:drawMoneyText()
	end

	if self.showTime then
		self:drawTimeText()
	end

	if self.showDate then
		self:drawDateText()
	end

	if self.showTemperature then
		self:drawTemperatureText()
	end

	if self.showTutorialProgress then
		self:drawTutorialText()
	end
end

function GameInfoDisplay:drawMoneyText()
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_RIGHT)
	setTextColor(unpack(GameInfoDisplay.COLOR.TEXT))

	if g_currentMission.player ~= nil then
		local farm = g_farmManager:getFarmById(g_currentMission.player.farmId)
		local moneyText = g_i18n:formatMoney(farm.money, 0, false, true)

		renderText(self.moneyTextPositionX, self.moneyTextPositionY, self.moneyTextSize, moneyText)
	end

	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextColor(unpack(GameInfoDisplay.COLOR.ICON))
	renderText(self.moneyCurrencyPositionX, self.moneyCurrencyPositionY, self.moneyTextSize, self.moneyCurrencyText)
end

function GameInfoDisplay:drawTimeText()
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(unpack(GameInfoDisplay.COLOR.TEXT))
	renderText(self.timeTextPositionX, self.timeTextPositionY, self.timeTextSize, self.timeText)
	renderText(self.timeScaleTextPositionX, self.timeScaleTextPositionY, self.timeScaleTextSize, self.timeScaleText)
end

function GameInfoDisplay:drawDateText()
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(unpack(GameInfoDisplay.COLOR.TEXT))
	renderText(self.monthTextPositionX, self.monthTextPositionY, self.monthTextSize, self.monthText)
end

function GameInfoDisplay:drawTemperatureText()
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_RIGHT)
	setTextColor(unpack(GameInfoDisplay.COLOR.TEXT))
	renderText(self.temperatureHighTextPositionX, self.temperatureHighTextPositionY, self.temperatureTextSize, self.temperatureDayText)
	renderText(self.temperatureLowTextPositionX, self.temperatureLowTextPositionY, self.temperatureTextSize, self.temperatureNightText)
end

function GameInfoDisplay:drawTutorialText()
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_RIGHT)
	setTextColor(unpack(GameInfoDisplay.COLOR.TEXT))
	renderText(self.tutorialTextPositionX, self.tutorialTextPositionY, self.tutorialTextSize, self.tutorialText)
end

function GameInfoDisplay:animateWeatherChange()
	local sequence = TweenSequence.new()

	for weatherType, icon in pairs(self.weatherTypeIcons) do
		local isCurrent = weatherType == self.currentWeather
		local isNext = weatherType == self.nextWeather
		local makeVisible = isCurrent or isNext

		if makeVisible and not icon:getVisible() then
			self:addActiveWeatherAnimation(sequence, isCurrent, icon)
		elseif not makeVisible and icon:getVisible() then
			self:addInactiveWeatherAnimation(sequence, icon)
		else
			self:addBecomeCurrentWeatherAnimation(sequence, icon)
		end
	end

	local isWeatherChanging = self.currentWeather ~= self.nextWeather

	self:addWeatherPositionAnimation(sequence, isWeatherChanging)
	sequence:start()

	self.weatherAnimation = sequence
end

function GameInfoDisplay:addActiveWeatherAnimation(animationSequence, isCurrentWeatherIcon, icon)
	local fullColor = GameInfoDisplay.COLOR.ICON_WEATHER_NEXT

	if isCurrentWeatherIcon then
		fullColor = GameInfoDisplay.COLOR.ICON
	end

	local transparentColor = {
		fullColor[1],
		fullColor[2],
		fullColor[3],
		0
	}
	local fadeInSequence = TweenSequence.new(icon)
	local fadeIn = MultiValueTween.new(icon.setColor, transparentColor, fullColor, HUDDisplayElement.MOVE_ANIMATION_DURATION)

	fadeInSequence:insertTween(fadeIn, 0)
	fadeInSequence:insertCallback(icon.setVisible, true, 0)
	fadeInSequence:start()
	animationSequence:insertTween(fadeInSequence, 0)
end

function GameInfoDisplay:addInactiveWeatherAnimation(animationSequence, icon)
	local currentColor = {
		icon:getColor()
	}
	local transparentColor = {
		currentColor[1],
		currentColor[2],
		currentColor[3],
		0
	}
	local fadeOutSequence = TweenSequence.new(icon)
	local fadeOut = MultiValueTween.new(icon.setColor, currentColor, transparentColor, HUDDisplayElement.MOVE_ANIMATION_DURATION)

	fadeOutSequence:insertTween(fadeOut, 0)
	fadeOutSequence:addCallback(icon.setVisible, false)
	fadeOutSequence:start()
	animationSequence:insertTween(fadeOutSequence, 0)
end

function GameInfoDisplay:addBecomeCurrentWeatherAnimation(animationSequence, icon)
	local currentColor = {
		icon:getColor()
	}
	local makeCurrent = MultiValueTween.new(icon.setColor, currentColor, GameInfoDisplay.COLOR.ICON, HUDDisplayElement.MOVE_ANIMATION_DURATION)

	makeCurrent:setTarget(icon)
	animationSequence:insertTween(makeCurrent, 0)
end

function GameInfoDisplay:addWeatherPositionAnimation(animationSequence, isWeatherChanging)
	local icon = self.weatherTypeIcons[self.currentWeather]
	local boxPosX, boxPosY = self.weatherBox:getPosition()
	local centerX = boxPosX + self.weatherBox:getWidth() * 0.5
	local centerY = boxPosY + (self.weatherBox:getHeight() - icon:getHeight()) * 0.5

	if isWeatherChanging then
		local moveLeft = MultiValueTween.new(icon.setPosition, {
			icon:getPosition()
		}, {
			centerX - icon:getWidth(),
			centerY
		}, HUDDisplayElement.MOVE_ANIMATION_DURATION)

		moveLeft:setTarget(icon)
		animationSequence:insertTween(moveLeft, 0)

		local secondIcon = self.weatherTypeIcons[self.nextWeather]

		if secondIcon:getVisible() then
			local moveRight = MultiValueTween.new(secondIcon.setPosition, {
				secondIcon:getPosition()
			}, {
				centerX,
				centerY
			}, HUDDisplayElement.MOVE_ANIMATION_DURATION)

			moveRight:setTarget(secondIcon)
			animationSequence:insertTween(moveRight, 0)
		else
			secondIcon:setPosition(centerX, centerY)
		end
	else
		local iconPosX, iconPosY = icon:getPosition()

		if iconPosX ~= centerX or iconPosY ~= centerY and self.weatherAnimation:getFinished() then
			local move = MultiValueTween.new(icon.setPosition, {
				icon:getPosition()
			}, {
				centerX,
				centerY
			}, HUDDisplayElement.MOVE_ANIMATION_DURATION)

			move:setTarget(icon)
			animationSequence:insertTween(move, 0)
		end
	end
end

function GameInfoDisplay.getBackgroundPosition(uiScale)
	local offX, offY = getNormalizedScreenValues(unpack(GameInfoDisplay.POSITION.SELF))

	return 1 + offX * uiScale - g_safeFrameOffsetX, 1 - g_safeFrameOffsetY + offY * uiScale
end

function GameInfoDisplay:setScale(uiScale)
	GameInfoDisplay:superClass().setScale(self, uiScale, uiScale)
	self:storeScaledValues()
	self:updateSizeAndPositions()
end

function GameInfoDisplay:storeScaledValues()
	self.boxHeight = self:scalePixelToScreenHeight(GameInfoDisplay.BOX_HEIGHT)
	self.boxMarginWidth, self.boxMarginHeight = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.BOX_MARGIN)
	self.moneyBoxWidth = self:scalePixelToScreenWidth(GameInfoDisplay.SIZE.MONEY_BOX[1])
	self.moneyTextSize = self:scalePixelToScreenHeight(GameInfoDisplay.TEXT_SIZE.MONEY)
	local moneyBoxPosX, moneyBoxPosY = self.moneyBox:getPosition()
	local textOffX, textOffY = self:scalePixelToScreenVector(GameInfoDisplay.POSITION.MONEY_TEXT)
	self.moneyTextPositionX = moneyBoxPosX + self.moneyBox:getWidth() + textOffX
	self.moneyTextPositionY = moneyBoxPosY + self.moneyBox:getHeight() * 0.5 - self.moneyTextSize * 0.5 + textOffY
	local x, y = self.moneyIconOverlay:getPosition()
	self.moneyCurrencyPositionX = self.moneyIconOverlay.width * 0.5 + x
	self.moneyCurrencyPositionY = self.moneyIconOverlay.height * 0.5 + y - self.moneyTextSize * 0.5 + textOffY
	local timeBoxPosX, timeBoxPosY = self.timeBox:getPosition()
	local _ = self.timeBox:getWidth()
	local timeBoxHeight = self.timeBox:getHeight()
	textOffX, textOffY = self:scalePixelToScreenVector(GameInfoDisplay.POSITION.TIME_TEXT)
	self.timeTextPositionX = timeBoxPosX + textOffX
	self.timeTextPositionY = timeBoxPosY + timeBoxHeight * 0.5 + textOffY
	self.timeTextSize = self:scalePixelToScreenHeight(GameInfoDisplay.TEXT_SIZE.TIME)
	textOffX, textOffY = self:scalePixelToScreenVector(GameInfoDisplay.POSITION.TIME_SCALE_TEXT)
	self.timeScaleTextPositionX = timeBoxPosX + textOffX
	self.timeScaleTextPositionY = timeBoxPosY + timeBoxHeight * 0.5 + textOffY
	self.timeScaleTextSize = self:scalePixelToScreenHeight(GameInfoDisplay.TEXT_SIZE.TIME_SCALE)
	self.clockHandLargePivotX, self.clockHandLargePivotY = self:normalizeUVPivot(GameInfoDisplay.PIVOT.CLOCK_HAND_LARGE, GameInfoDisplay.SIZE.CLOCK_HAND_LARGE, GameInfoDisplay.UV.CLOCK_HAND_LARGE)
	self.clockHandSmallPivotX, self.clockHandSmallPivotY = self:normalizeUVPivot(GameInfoDisplay.PIVOT.CLOCK_HAND_SMALL, GameInfoDisplay.SIZE.CLOCK_HAND_SMALL, GameInfoDisplay.UV.CLOCK_HAND_SMALL)
	self.monthTextSize = self:scalePixelToScreenHeight(GameInfoDisplay.TEXT_SIZE.MONTH)
	textOffX, textOffY = self:scalePixelToScreenVector(GameInfoDisplay.POSITION.MONTH_TEXT)
	local dateBoxX, dateBoxY = self.dateBox:getPosition()
	self.monthTextPositionX = dateBoxX + self.seasonOverlay.width + textOffX
	self.monthTextPositionY = dateBoxY + textOffY + (self.dateBox:getHeight() - self.monthTextSize) * 0.5
	self.temperatureTextSize = self:scalePixelToScreenHeight(GameInfoDisplay.TEXT_SIZE.TEMPERATURE)
	local tempBoxPosX, tempBoxPosY = self.temperatureBox:getPosition()
	local tempBoxWidth = self.temperatureBox:getWidth()
	local tempBoxHeight = self.temperatureBox:getHeight()
	textOffX, textOffY = self:scalePixelToScreenVector(GameInfoDisplay.POSITION.TEMPERATURE_HIGH)
	self.temperatureHighTextPositionX = tempBoxPosX + tempBoxWidth + textOffX
	self.temperatureHighTextPositionY = tempBoxPosY + tempBoxHeight * 0.5 + textOffY
	textOffX, textOffY = self:scalePixelToScreenVector(GameInfoDisplay.POSITION.TEMPERATURE_LOW)
	self.temperatureLowTextPositionX = tempBoxPosX + tempBoxWidth + textOffX
	self.temperatureLowTextPositionY = tempBoxPosY + tempBoxHeight * 0.5 + textOffY
	local tutorialBarX, tutorialBarY = self.tutorialProgressBar:getPosition()
	self.tutorialBarWidth, self.tutorialBarHeight = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.TUTORIAL_PROGRESS_BAR)
	textOffX, textOffY = self:scalePixelToScreenVector(GameInfoDisplay.POSITION.TUTORIAL_TEXT)
	self.tutorialTextSize = self:scalePixelToScreenHeight(GameInfoDisplay.TEXT_SIZE.TUTORIAL)
	self.tutorialTextPositionX = tutorialBarX + textOffX
	self.tutorialTextPositionY = tutorialBarY + (self.tutorialBarHeight - self.tutorialTextSize) * 0.5 + textOffY
end

function GameInfoDisplay.createBackground()
	local posX, posY = GameInfoDisplay.getBackgroundPosition(1)
	local width, height = getNormalizedScreenValues(unpack(GameInfoDisplay.SIZE.SELF))
	width = width + g_safeFrameOffsetX
	local overlay = Overlay.new(nil, posX - width, posY - height, width, height)

	return overlay
end

function GameInfoDisplay:createBackgroundOverlay()
	local posX, posY = GameInfoDisplay.getBackgroundPosition(1)
	local width, height = getNormalizedScreenValues(unpack(GameInfoDisplay.SIZE.SELF))
	width = width + g_safeFrameOffsetX
	local overlay = Overlay.new(g_baseUIFilename, posX - width, posY - height, width, height)

	overlay:setUVs(g_colorBgUVs)
	overlay:setColor(0, 0, 0, 0.75)

	local element = HUDElement.new(overlay)

	self:addChild(element)

	return element
end

function GameInfoDisplay:createComponents(hudAtlasPath)
	local topRightX, topRightY = GameInfoDisplay.getBackgroundPosition(1)
	local bottomY = topRightY - self:getHeight()
	local marginWidth, _ = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.BOX_MARGIN)
	self.backgroundOverlay = self:createBackgroundOverlay()
	local rightX = self:createMoneyBox(hudAtlasPath, topRightX, bottomY) - marginWidth
	self.moneyBox.separator = {
		setVisible = function ()
		end
	}
	local sepX = rightX
	rightX = self:createTimeBox(hudAtlasPath, rightX - marginWidth, bottomY) - marginWidth
	local centerY = bottomY + self:getHeight() * 0.5
	local separator = self:createVerticalSeparator(hudAtlasPath, sepX, centerY)

	self.timeBox:addChild(separator)

	self.timeBox.separator = separator
	sepX = rightX
	rightX = self:createDateBox(hudAtlasPath, rightX - marginWidth, bottomY) - marginWidth
	separator = self:createVerticalSeparator(hudAtlasPath, sepX, centerY)

	self.dateBox:addChild(separator)

	self.dateBox.separator = separator
	sepX = rightX
	rightX = self:createTemperatureBox(hudAtlasPath, rightX - marginWidth, bottomY) - marginWidth
	separator = self:createVerticalSeparator(hudAtlasPath, sepX, centerY)

	self.temperatureBox:addChild(separator)

	self.temperatureBox.separator = separator
	sepX = rightX
	rightX = self:createWeatherBox(hudAtlasPath, rightX - marginWidth, bottomY) - marginWidth
	separator = self:createVerticalSeparator(hudAtlasPath, sepX, centerY)

	self.weatherBox:addChild(separator)

	self.weatherBox.separator = separator
	sepX = rightX

	self:createTutorialBox(hudAtlasPath, rightX - marginWidth, bottomY)

	separator = self:createVerticalSeparator(hudAtlasPath, sepX, centerY)

	self.tutorialBox:addChild(separator)

	self.tutorialBox.separator = separator
	local width = self:getVisibleWidth()

	self:setDimension(width + g_safeFrameOffsetX, self:getHeight())
end

function GameInfoDisplay:createMoneyBox(hudAtlasPath, rightX, bottomY)
	local iconWidth, iconHeight = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.MONEY_ICON)
	local boxWidth, boxHeight = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.MONEY_BOX)
	local posX = rightX - boxWidth
	local posY = bottomY + (boxHeight - iconHeight) * 0.5
	local boxOverlay = Overlay.new(nil, posX, bottomY, boxWidth, boxHeight)
	local boxElement = HUDElement.new(boxOverlay)
	self.moneyBox = boxElement

	self:addChild(boxElement)
	table.insert(self.infoBoxes, self.moneyBox)

	local iconOverlay = Overlay.new(hudAtlasPath, posX, posY, iconWidth, iconHeight)

	iconOverlay:setUVs(GuiUtils.getUVs(GameInfoDisplay.UV.MONEY_ICON))
	iconOverlay:setColor(unpack(GameInfoDisplay.COLOR.ICON))

	self.moneyIconOverlay = iconOverlay

	boxElement:addChild(HUDElement.new(iconOverlay))

	self.moneyCurrencyText = g_i18n:getCurrencySymbol(true)

	return posX
end

function GameInfoDisplay:createTimeBox(hudAtlasPath, rightX, bottomY)
	local boxWidth, boxHeight = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.TIME_BOX)
	local posX = rightX - boxWidth
	local boxOverlay = Overlay.new(nil, posX, bottomY, boxWidth, boxHeight)
	local boxElement = HUDElement.new(boxOverlay)
	self.timeBox = boxElement

	self:addChild(boxElement)
	table.insert(self.infoBoxes, self.timeBox)

	local clockWidth, clockHeight = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.TIME_ICON)
	local posY = bottomY + (boxHeight - clockHeight) * 0.5
	local clockOverlay = Overlay.new(hudAtlasPath, posX, posY, clockWidth, clockHeight)

	clockOverlay:setUVs(GuiUtils.getUVs(GameInfoDisplay.UV.TIME_ICON))
	clockOverlay:setColor(unpack(GameInfoDisplay.COLOR.ICON))

	local clockElement = HUDElement.new(clockOverlay)
	self.clockElement = clockElement

	boxElement:addChild(clockElement)

	posY = posY + clockHeight * 0.5
	posX = posX + clockWidth * 0.5
	self.clockHandSmall = self:createClockHand(hudAtlasPath, posX, posY, GameInfoDisplay.SIZE.CLOCK_HAND_SMALL, GameInfoDisplay.UV.CLOCK_HAND_SMALL, GameInfoDisplay.COLOR.CLOCK_HAND_SMALL, GameInfoDisplay.PIVOT.CLOCK_HAND_SMALL)

	clockElement:addChild(self.clockHandSmall)

	self.clockHandLarge = self:createClockHand(hudAtlasPath, posX, posY, GameInfoDisplay.SIZE.CLOCK_HAND_LARGE, GameInfoDisplay.UV.CLOCK_HAND_LARGE, GameInfoDisplay.COLOR.CLOCK_HAND_LARGE, GameInfoDisplay.PIVOT.CLOCK_HAND_LARGE)

	clockElement:addChild(self.clockHandLarge)

	local arrowOffX, arrowOffY = self:scalePixelToScreenVector(GameInfoDisplay.POSITION.TIME_SCALE_ARROW)
	posY = bottomY + boxHeight * 0.5 + arrowOffY
	posX = rightX - boxWidth + clockWidth + arrowOffX
	self.timeScaleArrow = self:createTimeScaleArrow(hudAtlasPath, posX, posY, GameInfoDisplay.SIZE.TIME_SCALE_ARROW, GameInfoDisplay.UV.TIME_SCALE_ARROW)

	boxElement:addChild(self.timeScaleArrow)

	self.timeScaleArrowFast = self:createTimeScaleArrow(hudAtlasPath, posX, posY, GameInfoDisplay.SIZE.TIME_SCALE_ARROW_FAST, GameInfoDisplay.UV.TIME_SCALE_ARROW_FAST)

	boxElement:addChild(self.timeScaleArrowFast)

	return rightX - boxWidth
end

function GameInfoDisplay:createDateBox(hudAtlasPath, rightX, bottomY)
	local boxWidth, boxHeight = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.DATE_BOX)
	local maxMonthWidth = 0
	local textSize = self:scalePixelToScreenHeight(GameInfoDisplay.TEXT_SIZE.MONTH)

	for i = 1, 12 do
		local text = g_i18n:formatPeriod(i, true)
		local width = getTextWidth(textSize, text)
		maxMonthWidth = math.max(maxMonthWidth, width)
	end

	boxWidth = boxWidth + maxMonthWidth
	local posX = rightX - boxWidth
	local boxOverlay = Overlay.new(nil, posX, bottomY, boxWidth, boxHeight)
	self.dateBox = HUDElement.new(boxOverlay)

	self:addChild(self.dateBox)
	table.insert(self.infoBoxes, self.dateBox)

	local seasonWidth, seasonHeight = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.SEASON_ICON)
	local _, seasonOffsetY = self:scalePixelToScreenVector(GameInfoDisplay.POSITION.SEASON_ICON)
	local posY = bottomY + (boxHeight - seasonHeight) * 0.5
	self.seasonOverlay = Overlay.new(hudAtlasPath, posX, posY + seasonOffsetY, seasonWidth, seasonHeight)

	self.seasonOverlay:setUVs(GuiUtils.getUVs(GameInfoDisplay.UV.SEASON[0]))
	self.seasonOverlay:setColor(unpack(GameInfoDisplay.COLOR.ICON))

	self.seasonElement = HUDElement.new(self.seasonOverlay)

	self.dateBox:addChild(self.seasonElement)

	return rightX - boxWidth
end

function GameInfoDisplay:createTemperatureBox(hudAtlasPath, rightX, bottomY)
	local boxWidth, boxHeight = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.TEMPERATURE_BOX)
	local posX = rightX - boxWidth
	local boxOverlay = Overlay.new(nil, posX, bottomY, boxWidth, boxHeight)
	local boxElement = HUDElement.new(boxOverlay)
	self.temperatureBox = boxElement

	self:addChild(boxElement)
	table.insert(self.infoBoxes, self.temperatureBox)

	self.temperatureIconStable = self:createTemperatureIcon(hudAtlasPath, posX, bottomY, boxHeight, GameInfoDisplay.UV.TEMPERATURE_ICON_STABLE, GameInfoDisplay.COLOR.ICON)

	boxElement:addChild(self.temperatureIconStable)

	self.temperatureIconRising = self:createTemperatureIcon(hudAtlasPath, posX, bottomY, boxHeight, GameInfoDisplay.UV.TEMPERATURE_ICON_RISING, GameInfoDisplay.COLOR.ICON)

	boxElement:addChild(self.temperatureIconRising)

	self.temperatureIconDropping = self:createTemperatureIcon(hudAtlasPath, posX, bottomY, boxHeight, GameInfoDisplay.UV.TEMPERATURE_ICON_DROPPING, GameInfoDisplay.COLOR.ICON)

	boxElement:addChild(self.temperatureIconDropping)

	return rightX - boxWidth
end

function GameInfoDisplay:createWeatherBox(hudAtlasPath, rightX, bottomY)
	local boxWidth, boxHeight = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.WEATHER_BOX)
	local posX = rightX - boxWidth
	local boxOverlay = Overlay.new(nil, posX, bottomY, boxWidth, boxHeight)
	local boxElement = HUDElement.new(boxOverlay)
	self.weatherBox = boxElement

	self:addChild(boxElement)
	table.insert(self.infoBoxes, self.weatherBox)

	self.weatherBoxRight = rightX
	local weatherUvs = self:getWeatherUVs()

	for weatherId, uvs in pairs(weatherUvs) do
		local weatherIcon = self:createWeatherIcon(hudAtlasPath, weatherId, boxHeight, uvs, GameInfoDisplay.COLOR.ICON)

		boxElement:addChild(weatherIcon)

		self.weatherTypeIcons[weatherId] = weatherIcon
	end

	return rightX - boxWidth
end

function GameInfoDisplay:getWeatherUVs()
	return {
		[WeatherType.SUN] = GameInfoDisplay.UV.WEATHER_ICON_CLEAR,
		[WeatherType.RAIN] = GameInfoDisplay.UV.WEATHER_ICON_RAIN,
		[WeatherType.CLOUDY] = GameInfoDisplay.UV.WEATHER_ICON_CLOUDY,
		[WeatherType.SNOW] = GameInfoDisplay.UV.WEATHER_ICON_SNOW
	}
end

function GameInfoDisplay:createWeatherIcon(hudAtlasPath, weatherId, boxHeight, uvs, color)
	local width, height = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.WEATHER_ICON)
	local overlay = Overlay.new(hudAtlasPath, 0, 0, width, height)

	overlay:setUVs(GuiUtils.getUVs(uvs))

	local element = HUDElement.new(overlay)

	element:setVisible(false)

	return element
end

function GameInfoDisplay:createTemperatureIcon(hudAtlasPath, leftX, bottomY, boxHeight, uvs, color)
	local iconWidth, iconHeight = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.TEMPERATURE_ICON)
	local posY = bottomY + (boxHeight - iconHeight) * 0.5
	local overlay = Overlay.new(hudAtlasPath, leftX, posY, iconWidth, iconHeight)

	overlay:setUVs(GuiUtils.getUVs(uvs))
	overlay:setColor(unpack(color))

	return HUDElement.new(overlay)
end

function GameInfoDisplay:createClockHand(hudAtlasPath, posX, posY, size, uvs, color, pivot)
	local pivotX, pivotY = self:normalizeUVPivot(pivot, size, uvs)
	local width, height = self:scalePixelToScreenVector(size)
	local clockHandOverlay = Overlay.new(hudAtlasPath, posX - pivotX, posY - pivotY, width, height)

	clockHandOverlay:setUVs(GuiUtils.getUVs(uvs))
	clockHandOverlay:setColor(unpack(color))

	local clockHandElement = HUDElement.new(clockHandOverlay)

	clockHandElement:setRotationPivot(pivotX, pivotY)

	return clockHandElement
end

function GameInfoDisplay:createTimeScaleArrow(hudAtlasPath, posX, posY, size, uvs)
	local arrowWidth, arrowHeight = self:scalePixelToScreenVector(size)
	local arrowOverlay = Overlay.new(hudAtlasPath, posX, posY, arrowWidth, arrowHeight)

	arrowOverlay:setUVs(GuiUtils.getUVs(uvs))
	arrowOverlay:setColor(unpack(GameInfoDisplay.COLOR.ICON))

	return HUDElement.new(arrowOverlay)
end

function GameInfoDisplay:createVerticalSeparator(hudAtlasPath, posX, centerPosY)
	local width, height = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.SEPARATOR)
	width = math.max(width, 1 / g_screenWidth)
	local overlay = Overlay.new(hudAtlasPath, posX - width * 0.5, centerPosY - height * 0.5, width, height)

	overlay:setUVs(GuiUtils.getUVs(GameInfoDisplay.UV.SEPARATOR))
	overlay:setColor(unpack(GameInfoDisplay.COLOR.SEPARATOR))

	return HUDElement.new(overlay)
end

function GameInfoDisplay:createTutorialBox(hudAtlasPath, rightX, bottomY)
	local boxWidth, boxHeight = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.TUTORIAL_BOX)
	local posX = rightX - boxWidth
	local boxOverlay = Overlay.new(nil, posX, bottomY, boxWidth, boxHeight)
	local boxElement = HUDElement.new(boxOverlay)
	self.tutorialBox = boxElement

	self:addChild(boxElement)
	table.insert(self.infoBoxes, self.tutorialBox)

	local offX, offY = self:scalePixelToScreenVector(GameInfoDisplay.POSITION.TUTORIAL_PROGRESS_BAR)
	local barWidth, barHeight = self:scalePixelToScreenVector(GameInfoDisplay.SIZE.TUTORIAL_PROGRESS_BAR)
	local barPosX = rightX - barWidth + offX
	local barPosY = bottomY + (boxHeight - barHeight) * 0.5 + offY
	local pixelX = 1 / g_screenWidth
	local pixelY = 1 / g_screenHeight
	local topLine = Overlay.new(hudAtlasPath, barPosX - pixelX, barPosY + barHeight, barWidth + pixelX * 2, pixelY)
	local bottomLine = Overlay.new(hudAtlasPath, barPosX - pixelX, barPosY - pixelY, barWidth + pixelX * 2, pixelY)
	local leftLine = Overlay.new(hudAtlasPath, barPosX - pixelX, barPosY, pixelX, barHeight)
	local rightLine = Overlay.new(hudAtlasPath, barPosX + barWidth, barPosY, pixelX, barHeight)

	for _, lineOverlay in pairs({
		topLine,
		bottomLine,
		leftLine,
		rightLine
	}) do
		lineOverlay:setUVs(GuiUtils.getUVs(GameInfoDisplay.UV.SEPARATOR))
		lineOverlay:setColor(unpack(GameInfoDisplay.COLOR.SEPARATOR))

		local lineElement = HUDElement.new(lineOverlay)

		self.tutorialBox:addChild(lineElement)
	end

	local barOverlay = Overlay.new(hudAtlasPath, barPosX, barPosY, barWidth, barHeight)

	barOverlay:setUVs(GuiUtils.getUVs(GameInfoDisplay.UV.SEPARATOR))
	barOverlay:setColor(unpack(GameInfoDisplay.COLOR.TUTORIAL_PROGRESS_BAR))

	local barElement = HUDElement.new(barOverlay)

	self.tutorialBox:addChild(barElement)

	self.tutorialProgressBar = barElement

	return rightX - boxWidth
end

GameInfoDisplay.UV = {
	SEPARATOR = {
		8,
		8,
		1,
		1
	},
	MONEY_ICON = {
		144,
		144,
		48,
		48
	},
	TIME_ICON = {
		144,
		144,
		48,
		48
	},
	CLOCK_HAND_LARGE = {
		216,
		154,
		3,
		16
	},
	CLOCK_HAND_SMALL = {
		263,
		159,
		3,
		11
	},
	TIME_SCALE_ARROW = {
		286,
		164,
		24,
		15
	},
	TIME_SCALE_ARROW_FAST = {
		286,
		146,
		24,
		15
	},
	TEMPERATURE_ICON_STABLE = {
		336,
		192,
		48,
		48
	},
	TEMPERATURE_ICON_RISING = {
		384,
		192,
		48,
		48
	},
	TEMPERATURE_ICON_DROPPING = {
		432,
		192,
		48,
		48
	},
	WEATHER_ICON_CLEAR = {
		0,
		240,
		48,
		48
	},
	WEATHER_ICON_CLOUDY = {
		48,
		240,
		48,
		48
	},
	WEATHER_ICON_MIXED = {
		96,
		240,
		48,
		48
	},
	WEATHER_ICON_RAIN = {
		144,
		240,
		48,
		48
	},
	WEATHER_ICON_SNOW = {
		192,
		240,
		48,
		48
	},
	WEATHER_ICON_HAIL = {
		240,
		240,
		48,
		48
	},
	WEATHER_ICON_FOG = {
		288,
		240,
		48,
		48
	},
	WEATHER_ICON_WINDY = {
		240,
		192,
		48,
		48
	},
	WEATHER_ICON_THUNDER = {
		288,
		192,
		48,
		48
	},
	SEASON = {
		[0] = {
			384,
			240,
			48,
			48
		},
		{
			432,
			240,
			48,
			48
		},
		{
			480,
			240,
			48,
			48
		},
		{
			336,
			240,
			48,
			48
		}
	}
}
GameInfoDisplay.PIVOT = {
	CLOCK_HAND_LARGE = {
		1.5,
		1.5
	},
	CLOCK_HAND_SMALL = {
		1.5,
		1.5
	}
}
GameInfoDisplay.TEXT_SIZE = {
	TUTORIAL = 21,
	TEMPERATURE = 21,
	MONEY = 20,
	TIME_SCALE = 16,
	MONTH = 20,
	TIME = 20
}
GameInfoDisplay.BOX_HEIGHT = 75
GameInfoDisplay.SIZE = {
	SELF = {
		960,
		GameInfoDisplay.BOX_HEIGHT
	},
	BOX_MARGIN = {
		12,
		0
	},
	MONEY_BOX = {
		200,
		GameInfoDisplay.BOX_HEIGHT
	},
	TIME_BOX = {
		100,
		GameInfoDisplay.BOX_HEIGHT
	},
	DATE_BOX = {
		60,
		GameInfoDisplay.BOX_HEIGHT
	},
	TEMPERATURE_BOX = {
		72,
		GameInfoDisplay.BOX_HEIGHT
	},
	WEATHER_BOX = {
		80,
		GameInfoDisplay.BOX_HEIGHT
	},
	TUTORIAL_BOX = {
		320,
		GameInfoDisplay.BOX_HEIGHT
	},
	MONEY_ICON = {
		40,
		40
	},
	TIME_ICON = {
		40,
		40
	},
	CLOCK_HAND_SMALL = {
		3,
		8
	},
	CLOCK_HAND_LARGE = {
		3,
		10
	},
	TIME_SCALE_ARROW = {
		24,
		15
	},
	TIME_SCALE_ARROW_FAST = {
		24,
		15
	},
	SEASON_ICON = {
		40,
		40
	},
	TEMPERATURE_ICON = {
		34,
		34
	},
	WEATHER_ICON = {
		40,
		40
	},
	TUTORIAL_PROGRESS_BAR = {
		120,
		24
	},
	SEPARATOR = {
		1,
		35
	}
}
GameInfoDisplay.POSITION = {
	SELF = {
		0,
		-8
	},
	TIME_SCALE_ARROW = {
		5,
		-16
	},
	MONEY_TEXT = {
		0,
		3
	},
	TIME_TEXT = {
		45,
		2
	},
	TIME_SCALE_TEXT = {
		74,
		-14
	},
	SEASON_ICON = {
		0,
		0
	},
	MONTH_TEXT = {
		4,
		0
	},
	TEMPERATURE_HIGH = {
		0,
		1.5
	},
	TEMPERATURE_LOW = {
		0,
		-16.5
	},
	TUTORIAL_PROGRESS_BAR = {
		0,
		0
	},
	TUTORIAL_TEXT = {
		-12,
		2
	}
}
GameInfoDisplay.COLOR = {
	TEXT = {
		1,
		1,
		1,
		1
	},
	ICON = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	ICON_WEATHER_NEXT = {
		0.6,
		0.6,
		0.6,
		1
	},
	CLOCK_HAND_LARGE = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	CLOCK_HAND_SMALL = {
		0.0003,
		0.5647,
		0.9822,
		0.8
	},
	TUTORIAL_PROGRESS_BAR = {
		0.991,
		0.3865,
		0.01,
		1
	},
	TUTORIAL_PROGRESS_BAR_HIGHLIGHT = {
		1,
		0.773,
		0.5,
		1
	},
	SEPARATOR = {
		1,
		1,
		1,
		0.2
	}
}
GameInfoDisplay.ANIMATION = {
	TUTORIAL_PROGRESS_BAR_FLASH = 250
}
GameInfoDisplay.L10N_SYMBOL = {
	TUTORIAL = "fieldJob_progress"
}
