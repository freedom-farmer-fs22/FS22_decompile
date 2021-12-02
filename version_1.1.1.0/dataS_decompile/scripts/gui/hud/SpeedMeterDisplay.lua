SpeedMeterDisplay = {}
local SpeedMeterDisplay_mt = Class(SpeedMeterDisplay, HUDDisplayElement)

function SpeedMeterDisplay.new(hudAtlasPath)
	local backgroundOverlay = SpeedMeterDisplay.createBackground(hudAtlasPath)
	local self = SpeedMeterDisplay:superClass().new(backgroundOverlay, nil, SpeedMeterDisplay_mt)
	self.uiScale = 1
	self.vehicle = nil
	self.isVehicleDrawSafe = false
	self.speedIndicatorElement = nil
	self.speedGaugeSegmentElements = nil
	self.speedGaugeSegmentPartElements = nil
	self.speedIndicatorRadiusX = 0
	self.speedIndicatorRadiusY = 0
	self.speedTextOffsetY = 0
	self.speedUnitTextOffsetY = 0
	self.speedTextSize = 0
	self.speedUnitTextSize = 0
	self.speedKmh = 0
	self.speedGaugeMode = g_gameSettings:getValue(GameSettings.SETTING.HUD_SPEED_GAUGE)
	self.speedGaugeUseMiles = g_gameSettings:getValue(GameSettings.SETTING.USE_MILES)
	self.rpmUnitTextOffsetY = 0
	self.rpmUnitTextSize = 0
	self.rpmUnitText = g_i18n:getText("unit_rpmShort")
	self.lastGaugeValue = 0
	self.speedGaugeElements = {}
	self.damageGaugeBackgroundElement = nil
	self.damageGaugeSegmentPartElements = nil
	self.damageGaugeIconElement = nil
	self.damageGaugeRadiusX = 0
	self.damageGaugeRadiusY = 0
	self.damageGaugeActive = false
	self.fuelGaugeBackgroundElement = nil
	self.fuelIndicatorElement = nil
	self.fuelGaugeSegmentPartElements = nil
	self.fuelGaugeIconElement = nil
	self.fuelIndicatorRadiusX = 0
	self.fuelIndicatorRadiusY = 0
	self.fuelGaugeRadiusX = 0
	self.fuelGaugeRadiusY = 0
	self.fuelGaugeActive = false
	self.fuelGaugeUVsDiesel = GuiUtils.getUVs(SpeedMeterDisplay.UV.FUEL_LEVEL_ICON)
	self.fuelGaugeUVsElectric = GuiUtils.getUVs(SpeedMeterDisplay.UV.FUEL_LEVEL_ICON_ELECTRIC)
	self.fuelGaugeUVsMethane = GuiUtils.getUVs(SpeedMeterDisplay.UV.FUEL_LEVEL_ICON_METHANE)
	self.cruiseControlElement = nil
	self.cruiseControlSpeed = 0
	self.cruiseControlColor = nil
	self.cruiseControlTextOffsetX = 0
	self.cruiseControlTextOffsetY = 0
	self.operatingTimeElement = nil
	self.operatingTimeText = ""
	self.operatingTimeTextSize = 1
	self.operatingTimeTextOffsetX = 0
	self.operatingTimeTextOffsetY = 0
	self.operatingTimeTextDrawPositionX = 0
	self.operatingTimeTextDrawPositionY = 0
	self.gearTextPositionY = 0
	self.gearGroupTextPositionY = 0
	self.gearTextSize = 0
	self.gearTexts = {
		"A",
		"B",
		"C"
	}
	self.gearGroupText = ""
	self.gearSelectedIndex = 1
	self.gearHasGroup = false
	self.gearIsChanging = false
	self.gearWarningTime = 0
	self.fadeFuelGaugeAnimation = TweenSequence.NO_SEQUENCE
	self.fadeDamageGaugeAnimation = TweenSequence.NO_SEQUENCE
	self.hudAtlasPath = hudAtlasPath

	self:createComponents(hudAtlasPath)

	return self
end

local HALF_PI = math.pi * 0.5

function SpeedMeterDisplay:getBasePosition()
	local offX, offY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.GAUGE_BACKGROUND))
	local selfX, selfY = self:getPosition()

	return selfX + offX, selfY + offY
end

function SpeedMeterDisplay:createComponents(hudAtlasPath)
	local baseX, baseY = self:getBasePosition()

	self:storeScaledValues(baseX, baseY)

	self.gaugeBackgroundElement = self:createGaugeBackground(hudAtlasPath, baseX, baseY)
	self.damageGaugeIconElement, self.fuelGaugeIconElement = self:createGaugeIconElements(hudAtlasPath, baseX, baseY)
	self.damageBarElement = self:createDamageBar(hudAtlasPath, baseX, baseY)
	self.fuelBarElement = self:createFuelBar(hudAtlasPath, baseX, baseY)
	self.gearElement = self:createGearIndicator(hudAtlasPath, baseX, baseY)
	self.speedIndicatorElement = self:createSpeedGaugeIndicator(hudAtlasPath, baseX, baseY)
	self.operatingTimeElement = self:createOperatingTimeElement(hudAtlasPath, baseX, baseY)

	self.operatingTimeElement:setVisible(false)

	self.cruiseControlElement = self:createCruiseControlElement(hudAtlasPath, baseX, baseY)
end

function SpeedMeterDisplay:setVehicle(vehicle)
	local hadVehicle = self.vehicle ~= nil
	self.vehicle = vehicle
	local hasVehicle = vehicle ~= nil

	self.cruiseControlElement:setVisible(hasVehicle)

	local isMotorized = hasVehicle and vehicle.spec_motorized ~= nil
	local needFuelGauge = true

	if hasVehicle and isMotorized then
		local _, capacity = SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
		needFuelGauge = capacity ~= nil

		if needFuelGauge then
			local fuelType = SpeedMeterDisplay.getVehicleFuelType(vehicle)
			local fuelGaugeIconUVs = self.fuelGaugeUVsDiesel

			if fuelType == FillType.ELECTRICCHARGE then
				fuelGaugeIconUVs = self.fuelGaugeUVsElectric
			elseif fuelType == FillType.METHANE then
				fuelGaugeIconUVs = self.fuelGaugeUVsMethane
			end

			self.fuelGaugeIconElement:setUVs(fuelGaugeIconUVs)
		end

		self:onHudSpeedGaugeModeChanged()
	end

	self.fuelGaugeActive = needFuelGauge

	self:animateFuelGaugeToggle(needFuelGauge)

	local needDamageGauge = hasVehicle and vehicle.getDamageAmount ~= nil and vehicle:getDamageAmount() ~= nil
	self.damageGaugeActive = needDamageGauge

	self:animateDamageGaugeToggle(needDamageGauge)

	local hasOperatingTime = hasVehicle and vehicle.operatingTime ~= nil

	self.operatingTimeElement:setVisible(hasOperatingTime)

	self.isVehicleDrawSafe = false

	if hasVehicle and not hadVehicle then
		g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.HUD_SPEED_GAUGE], self.onHudSpeedGaugeModeChanged, self)
		g_messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_MILES], self.onHudSpeedGaugeUseMilesChanged, self)
	else
		g_messageCenter:unsubscribeAll(self)
	end
end

function SpeedMeterDisplay:update(dt)
	SpeedMeterDisplay:superClass().update(self, dt)

	if not self.animation:getFinished() then
		local baseX, baseY = self.gaugeBackgroundElement:getPosition()

		self:storeScaledValues(baseX, baseY)
	end

	if self.vehicle ~= nil and self.vehicle.spec_motorized ~= nil then
		self:updateSpeedGauge(dt)
		self:updateDamageGauge(dt)
		self:updateFuelGauge(dt)
		self:updateCruiseControl(dt)
		self:updateOperatingTime(dt)
		self:updateGearDisplay(dt)
	end

	self.isVehicleDrawSafe = true
end

function SpeedMeterDisplay:updateGearDisplay(dt)
	local gearName, gearGroupName, gearsAvailable, isAutomatic, prevGearName, nextGearName, prevPrevGearName, nextNextGearName, isGearChanging, showNeutralWarning = self.vehicle:getGearInfoToDisplay()

	if gearName ~= nil and not isAutomatic then
		self.gearHasGroup = gearGroupName ~= nil
		self.gearGroupText = gearGroupName or ""

		if nextGearName == nil and prevGearName == nil then
			self.gearTexts[1] = ""
			self.gearTexts[2] = gearName
			self.gearTexts[3] = ""
			self.gearSelectedIndex = 2
		elseif nextGearName == nil then
			self.gearTexts[1] = prevPrevGearName or ""
			self.gearTexts[2] = prevGearName
			self.gearTexts[3] = gearName
			self.gearSelectedIndex = 3
		elseif prevGearName == nil then
			self.gearTexts[1] = gearName
			self.gearTexts[2] = nextGearName
			self.gearTexts[3] = nextNextGearName or ""
			self.gearSelectedIndex = 1
		else
			self.gearTexts[1] = prevGearName
			self.gearTexts[2] = gearName
			self.gearTexts[3] = nextGearName
			self.gearSelectedIndex = 2
		end
	elseif gearName ~= nil and isAutomatic then
		self.gearHasGroup = false
		self.gearGroupText = ""
		self.gearTexts[1] = "R"
		self.gearTexts[2] = "N"
		self.gearTexts[3] = "D"

		if gearName == "N" then
			self.gearSelectedIndex = 2
		elseif gearName == "D" then
			self.gearSelectedIndex = 3
		elseif gearName == "R" then
			self.gearSelectedIndex = 1
		end
	end

	self.gearIsChanging = isGearChanging

	self:setGearGroupVisible(self.gearGroupText ~= "")
	self.gearSelectorIcon:setPosition(nil, self.gearSelectorPositions[self.gearSelectedIndex])

	if showNeutralWarning then
		self.gearWarningTime = self.gearWarningTime + dt
	else
		self.gearWarningTime = 0
	end
end

function SpeedMeterDisplay:updateOperatingTime(dt)
	if self.operatingTimeElement:getVisible() then
		local minutes = self.vehicle.operatingTime / 60000
		local hours = math.floor(minutes / 60)
		minutes = math.floor((minutes - hours * 60) / 6)
		self.operatingTimeText = string.format(g_i18n:getText("shop_operatingTime"), hours, minutes)
		local posX, posY = self.operatingTimeElement:getPosition()
		self.operatingTimeTextDrawPositionX = posX + self.operatingTimeElement:getWidth() + self.operatingTimeTextOffsetX
		self.operatingTimeTextDrawPositionY = posY + self.operatingTimeTextOffsetY
		self.operatingTimeIsSafe = true
	end
end

function SpeedMeterDisplay:updateCruiseControl(dt)
	local cruiseControlSpeed, isActive = self.vehicle:getCruiseControlDisplayInfo()
	self.cruiseControlSpeed = cruiseControlSpeed
	self.cruiseControlColor = isActive and SpeedMeterDisplay.COLOR.CRUISE_CONTROL_ON or SpeedMeterDisplay.COLOR.CRUISE_CONTROL_OFF

	self.cruiseControlElement:setColor(unpack(self.cruiseControlColor))
end

function SpeedMeterDisplay:updateGaugeIndicator(indicatorElement, radiusX, radiusY, rotation)
	local pivotX, pivotY = indicatorElement:getRotationPivot()
	local cosRot = math.cos(rotation)
	local sinRot = math.sin(rotation)
	local posX = self.gaugeCenterX + cosRot * radiusX - pivotX
	local posY = self.gaugeCenterY + sinRot * radiusY - pivotY

	indicatorElement:setPosition(posX, posY)
	indicatorElement:setRotation(rotation - HALF_PI)
end

function SpeedMeterDisplay:updateSpeedGauge(dt)
	local lastSpeed = self.vehicle:getLastSpeed()
	local kmh = math.max(0, lastSpeed * self.vehicle.spec_motorized.speedDisplayScale)

	if kmh < 0.5 then
		kmh = 0
	end

	self.speedKmh = kmh
	local gaugeValue = nil

	if self.speedGaugeMode == SpeedMeterDisplay.GAUGE_MODE_RPM then
		gaugeValue = MathUtil.clamp((self.vehicle:getMotorRpmReal() - self.speedGaugeMinValue) / (self.speedGaugeMaxValue - self.speedGaugeMinValue), 0, 1)
	else
		local scale = 1

		if self.speedGaugeUseMiles then
			scale = 0.621371
		end

		gaugeValue = MathUtil.clamp((lastSpeed * scale - self.speedGaugeMinValue) / (self.speedGaugeMaxValue - self.speedGaugeMinValue), 0, 1)
	end

	self.lastGaugeValue = self.lastGaugeValue * 0.95 + gaugeValue * 0.05
	local indicatorRotation = MathUtil.lerp(SpeedMeterDisplay.ANGLE.SPEED_GAUGE_MIN, SpeedMeterDisplay.ANGLE.SPEED_GAUGE_MAX, self.lastGaugeValue)

	self:updateGaugeIndicator(self.speedIndicatorElement, self.speedIndicatorRadiusX, self.speedIndicatorRadiusY, indicatorRotation)
end

function SpeedMeterDisplay:updateDamageGauge(dt)
	if not self.fadeDamageGaugeAnimation:getFinished() then
		self.fadeDamageGaugeAnimation:update(dt)
	end

	if self.damageGaugeActive then
		local gaugeValue = 1
		local vehicles = self.vehicle.rootVehicle.childVehicles

		for i = 1, #vehicles do
			local vehicle = vehicles[i]

			if vehicle.getDamageAmount ~= nil then
				gaugeValue = math.min(gaugeValue, 1 - vehicle:getDamageAmount())
			end
		end

		self.damageBarElement:setValue(gaugeValue, "DAMAGE")

		local neededColor = SpeedMeterDisplay.COLOR.DAMAGE_GAUGE

		if gaugeValue < 0.2 then
			neededColor = SpeedMeterDisplay.COLOR.DAMAGE_GAUGE_LOW
		end

		self.damageBarElement:setBarColor(neededColor[1], neededColor[2], neededColor[3])
	end
end

function SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(vehicle)
	local fuelType = FillType.DIESEL
	local fillUnitIndex = vehicle:getConsumerFillUnitIndex(fuelType)

	if fillUnitIndex == nil then
		fuelType = FillType.ELECTRICCHARGE
		fillUnitIndex = vehicle:getConsumerFillUnitIndex(fuelType)

		if fillUnitIndex == nil then
			fuelType = FillType.METHANE
			fillUnitIndex = vehicle:getConsumerFillUnitIndex(fuelType)
		end
	end

	local level = vehicle:getFillUnitFillLevel(fillUnitIndex)
	local capacity = vehicle:getFillUnitCapacity(fillUnitIndex)

	return level, capacity, fuelType
end

function SpeedMeterDisplay.getVehicleFuelType(vehicle)
	if vehicle:getConsumerFillUnitIndex(FillType.DIESEL) ~= nil then
		return FillType.DIESEL
	elseif vehicle:getConsumerFillUnitIndex(FillType.ELECTRICCHARGE) ~= nil then
		return FillType.ELECTRICCHARGE
	elseif vehicle:getConsumerFillUnitIndex(FillType.METHANE) ~= nil then
		return FillType.METHANE
	end

	return FillType.DIESEL
end

function SpeedMeterDisplay:updateFuelGauge(dt)
	if not self.fadeFuelGaugeAnimation:getFinished() then
		self.fadeFuelGaugeAnimation:update(dt)
	end

	if self.fuelGaugeActive then
		local level, capacity = SpeedMeterDisplay.getVehicleFuelLevelAndCapacity(self.vehicle)

		if capacity > 0 then
			self.fuelBarElement:setValue(level / capacity, "FUEL")
		else
			self.fuelBarElement:setValue(1)
		end
	end
end

function SpeedMeterDisplay:onAnimateVisibilityFinished(isVisible)
	SpeedMeterDisplay:superClass().onAnimateVisibilityFinished(self, isVisible)

	local baseX, baseY = self.gaugeBackgroundElement:getPosition()

	self:storeScaledValues(baseX, baseY)
end

function SpeedMeterDisplay:draw()
	if self.overlay.visible then
		self.overlay:render()

		for _, child in ipairs(self.children) do
			if child ~= self.speedIndicatorElement then
				child:draw()
			end
		end
	end

	if self.isVehicleDrawSafe and self:getVisible() then
		self:drawSpeedText()
		self:drawGearText()
		self:drawOperatingTimeText()
		self:drawCruiseControlText()
	end

	new2DLayer()
	self.speedIndicatorElement:draw()
end

function SpeedMeterDisplay:drawGearText()
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextBold(true)

	local posX, posY = self.gearElement:getPosition()
	posX = posX + self.gearElement:getWidth() * 0.5

	renderText(posX, posY + self.gearGroupTextPositionY, self.gearTextSize, self.gearGroupText)

	for i = 1, 3 do
		local alpha = 1

		if i == 2 then
			alpha = math.abs(math.cos(self.gearWarningTime / 200))
		end

		if self.gearSelectedIndex == i and self.gearIsChanging then
			local r, g, b, a = unpack(SpeedMeterDisplay.COLOR.GEAR_TEXT_CHANGE)

			setTextColor(r, g, b, a * alpha)
		else
			local r, g, b, a = unpack(SpeedMeterDisplay.COLOR.GEAR_TEXT)

			setTextColor(r, g, b, a * alpha)
		end

		renderText(posX, posY + self.gearTextPositionY[i], self.gearTextSize, self.gearTexts[i])
	end

	setTextBold(false)
end

function SpeedMeterDisplay:drawOperatingTimeText()
	if self.operatingTimeElement:getVisible() then
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
		setTextColor(1, 1, 1, 1)
		renderText(self.operatingTimeTextDrawPositionX, self.operatingTimeTextDrawPositionY, self.operatingTimeTextSize, self.operatingTimeText)
	end
end

function SpeedMeterDisplay:drawCruiseControlText()
	if self.cruiseControlElement:getVisible() then
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(unpack(self.cruiseControlColor))
		setTextBold(true)

		local speedText = string.format(g_i18n:getText("ui_cruiseControlSpeed"), g_i18n:getSpeed(self.cruiseControlSpeed))
		local baseX, baseY = self.cruiseControlElement:getPosition()
		local posX = baseX + self.cruiseControlElement:getWidth() + self.cruiseControlTextOffsetX
		local posY = baseY + self.cruiseControlTextOffsetY

		renderText(posX, posY, self.cruiseControlTextSize, speedText)
	end
end

function SpeedMeterDisplay:drawSpeedText()
	local speedKmh = g_i18n:getSpeed(self.speedKmh)
	local speed = math.floor(speedKmh)

	if math.abs(speedKmh - speed) > 0.5 then
		speed = speed + 1
	end

	local speedI18N = string.format("%1d", speed)
	local speedUnit = utf8ToUpper(g_i18n:getSpeedMeasuringUnit())
	local baseX, baseY = self.gaugeBackgroundElement:getPosition()
	local centerPosX = baseX + self.gaugeBackgroundElement:getWidth() * 0.5

	setTextColor(unpack(SpeedMeterDisplay.COLOR.SPEED_TEXT))
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_CENTER)
	renderText(centerPosX, baseY + self.speedTextOffsetY, self.speedTextSize, speedI18N)
	setTextColor(unpack(SpeedMeterDisplay.COLOR.SPEED_UNIT))
	renderText(centerPosX, baseY + self.speedUnitTextOffsetY, self.speedUnitTextSize, speedUnit)
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_MIDDLE)
	setTextColor(0.7, 0.7, 0.7, 0.65)

	for _, gaugeElement in pairs(self.speedGaugeElements) do
		if gaugeElement.text ~= nil then
			renderText(baseX + gaugeElement.textPosX, baseY + gaugeElement.textPosY, self.speedUnitTextSize, gaugeElement.text)
		end
	end

	if self.speedGaugeMode == SpeedMeterDisplay.GAUGE_MODE_RPM then
		renderText(centerPosX - self.gaugeBackgroundElement:getWidth() * 0.25, baseY + self.rpmUnitTextOffsetY * 0.34, self.rpmUnitTextSize, self.rpmUnitText)
		renderText(centerPosX + self.gaugeBackgroundElement:getWidth() * 0.25, baseY + self.rpmUnitTextOffsetY * 0.34, self.rpmUnitTextSize, "x100")
	end

	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
end

function SpeedMeterDisplay:fadeFuelGauge(alpha)
	self.fuelBarElement:setAlpha(alpha)
	self.fuelGaugeIconElement:setAlpha(alpha)

	local visible = alpha > 0

	if visible ~= self.fuelBarElement:getVisible() then
		self.fuelBarElement:setVisible(visible)
		self.fuelGaugeIconElement:setVisible(visible)
	end
end

function SpeedMeterDisplay:animateFuelGaugeToggle(makeActive)
	local startAlpha = self.fuelBarElement:getAlpha()
	local endAlpha = makeActive and 1 or 0

	if self.fadeFuelGaugeAnimation:getFinished() then
		local sequence = TweenSequence.new(self)
		local fade = Tween.new(self.fadeFuelGauge, startAlpha, endAlpha, HUDDisplayElement.MOVE_ANIMATION_DURATION)

		sequence:addTween(fade)
		sequence:start()

		self.fadeFuelGaugeAnimation = sequence
	else
		self.fadeFuelGaugeAnimation:stop()
		self:fadeFuelGauge(endAlpha)
	end
end

function SpeedMeterDisplay:fadeDamageGauge(alpha)
	self.damageGaugeIconElement:setAlpha(alpha)
	self.damageBarElement:setAlpha(alpha)

	local visible = alpha > 0

	if visible ~= self.damageBarElement:getVisible() then
		self.damageBarElement:setVisible(visible)
	end
end

function SpeedMeterDisplay:animateDamageGaugeToggle(makeActive)
	local startAlpha = self.damageBarElement:getAlpha()
	local endAlpha = makeActive and 1 or 0

	if self.fadeDamageGaugeAnimation:getFinished() then
		local sequence = TweenSequence.new(self)
		local fade = Tween.new(self.fadeDamageGauge, startAlpha, endAlpha, HUDDisplayElement.MOVE_ANIMATION_DURATION)

		sequence:addTween(fade)
		sequence:start()

		self.fadeDamageGaugeAnimation = sequence
	else
		self.fadeDamageGaugeAnimation:stop()
		self:fadeDamageGauge(endAlpha)
	end
end

function SpeedMeterDisplay:setScale(uiScale)
	SpeedMeterDisplay:superClass().setScale(self, uiScale, uiScale)

	self.uiScale = uiScale
	local currentVisibility = self:getVisible()

	self:setVisible(true, false)

	local posX, posY = SpeedMeterDisplay.getBackgroundPosition(uiScale)

	self:setPosition(posX, posY)
	self:storeOriginalPosition()
	self:setVisible(currentVisibility, false)

	local baseX, baseY = self.gaugeBackgroundElement:getPosition()

	self:storeScaledValues(baseX, baseY)
end

function SpeedMeterDisplay:storeGaugeCenterPosition(baseX, baseY)
	local gaugeWidth, gaugeHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.GAUGE_BACKGROUND))
	self.gaugeCenterY = baseY + gaugeHeight * 0.5 * self.uiScale
	self.gaugeCenterX = baseX + gaugeWidth * 0.5 * self.uiScale
end

function SpeedMeterDisplay:storeScaledValues(baseX, baseY)
	self:storeGaugeCenterPosition(baseX, baseY)

	self.cruiseControlTextSize = self:scalePixelToScreenHeight(SpeedMeterDisplay.TEXT_SIZE.CRUISE_CONTROL)
	self.cruiseControlTextOffsetX, self.cruiseControlTextOffsetY = self:scalePixelToScreenVector(SpeedMeterDisplay.POSITION.CRUISE_CONTROL_TEXT)
	self.operatingTimeTextSize = self:scalePixelToScreenHeight(SpeedMeterDisplay.TEXT_SIZE.OPERATING_TIME)
	self.operatingTimeTextOffsetX, self.operatingTimeTextOffsetY = self:scalePixelToScreenVector(SpeedMeterDisplay.POSITION.OPERATING_TIME_TEXT)
	self.speedTextOffsetY = self:scalePixelToScreenHeight(SpeedMeterDisplay.POSITION.SPEED_TEXT[2])
	self.speedUnitTextOffsetY = self:scalePixelToScreenHeight(SpeedMeterDisplay.POSITION.SPEED_UNIT[2])
	self.speedTextSize = self:scalePixelToScreenHeight(SpeedMeterDisplay.TEXT_SIZE.SPEED)
	self.speedUnitTextSize = self:scalePixelToScreenHeight(SpeedMeterDisplay.TEXT_SIZE.SPEED_UNIT)
	self.rpmUnitTextOffsetY = self:scalePixelToScreenHeight(SpeedMeterDisplay.POSITION.SPEED_UNIT_TEXT[2])
	self.rpmUnitTextSize = self:scalePixelToScreenHeight(SpeedMeterDisplay.TEXT_SIZE.RPM_UNIT)
	self.speedIndicatorRadiusX, self.speedIndicatorRadiusY = self:scalePixelToScreenVector(SpeedMeterDisplay.SIZE.GAUGE_INDICATOR_LARGE_RADIUS)
	self.gearTextPositionY = {
		self:scalePixelToScreenHeight(SpeedMeterDisplay.POSITION.GEAR_TEXT_1[2]),
		self:scalePixelToScreenHeight(SpeedMeterDisplay.POSITION.GEAR_TEXT_2[2]),
		self:scalePixelToScreenHeight(SpeedMeterDisplay.POSITION.GEAR_TEXT_3[2])
	}
	self.gearGroupTextPositionY = self:scalePixelToScreenHeight(SpeedMeterDisplay.POSITION.GEAR_GROUP_TEXT[2])
	local circleHeight = self:scalePixelToScreenHeight(SpeedMeterDisplay.SIZE.GEAR_ICON_BG[2])
	local selectorHeight = self:scalePixelToScreenHeight(SpeedMeterDisplay.SIZE.GEAR_SELECTOR[2])
	local _, selfY = self:getPosition()
	local posY = selfY + self:scalePixelToScreenHeight(SpeedMeterDisplay.POSITION.GEAR_INDICATOR[2])
	self.gearGroupBgY = posY + self:scalePixelToScreenHeight(SpeedMeterDisplay.POSITION.GEAR_GROUP[2])
	self.gearIconBgY = posY + self:scalePixelToScreenHeight(SpeedMeterDisplay.POSITION.GEAR_ICON_BG[2])
	local by = posY + (circleHeight - selectorHeight) / 2
	self.gearSelectorPositions = {
		by,
		by + selectorHeight,
		by + selectorHeight * 2
	}
	self.gearTextSize = self:scalePixelToScreenHeight(SpeedMeterDisplay.TEXT_SIZE.GEAR)
end

function SpeedMeterDisplay:onHudSpeedGaugeModeChanged()
	self.speedGaugeMode = g_gameSettings:getValue(GameSettings.SETTING.HUD_SPEED_GAUGE)

	if self.vehicle ~= nil then
		local motorizedSpec = self.vehicle.spec_motorized

		if motorizedSpec ~= nil then
			if motorizedSpec.forceSpeedHudDisplay then
				self.speedGaugeMode = SpeedMeterDisplay.GAUGE_MODE_SPEED
			elseif motorizedSpec.forceRpmHudDisplay then
				self.speedGaugeMode = SpeedMeterDisplay.GAUGE_MODE_RPM
			end

			local motor = motorizedSpec.motor

			if self.speedGaugeMode == SpeedMeterDisplay.GAUGE_MODE_RPM then
				self:setupSpeedGauge(self.gaugeBackgroundElement, motor:getMinRpm(), motor:getMaxRpm(), 200)
			else
				local scale = 1

				if self.speedGaugeUseMiles then
					scale = 0.621371
				end

				self:setupSpeedGauge(self.gaugeBackgroundElement, 0, motor:getMaximumForwardSpeed() * 3.6, 5, true, scale)
			end
		end
	end
end

function SpeedMeterDisplay:onHudSpeedGaugeUseMilesChanged()
	self.speedGaugeUseMiles = g_gameSettings:getValue(GameSettings.SETTING.USE_MILES)

	if self.speedGaugeMode == SpeedMeterDisplay.GAUGE_MODE_SPEED then
		self:onHudSpeedGaugeModeChanged()
	end
end

function SpeedMeterDisplay.getBackgroundPosition(scale)
	local gaugeWidth = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.BACKGROUND))
	local selfOffX, selfOffY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.SELF))

	return 1 - g_safeFrameOffsetX - gaugeWidth * scale + selfOffX, g_safeFrameOffsetY - selfOffY
end

function SpeedMeterDisplay.createBackground(hudAtlasPath)
	local width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.BACKGROUND))
	local posX, posY = SpeedMeterDisplay.getBackgroundPosition(1)
	local background = Overlay.new(nil, posX, posY, width, height)

	return background
end

function SpeedMeterDisplay:createGaugeBackground(hudAtlasPath, baseX, baseY)
	local width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.GAUGE_BACKGROUND))
	local gaugeBackgroundOverlay = Overlay.new("dataS/menu/hud/hud_speedometer.png", baseX, baseY, width, height)

	gaugeBackgroundOverlay:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.GAUGE_BACKGROUND))

	local element = HUDElement.new(gaugeBackgroundOverlay)

	self:addChild(element)

	return element
end

local SPEED_GAUGE_START = math.rad(34.5)
local SPEED_GAUGE_RANGE = math.rad(248)
local SPEED_GAUGE_RADIUS = 0.42
local SPEED_GAUGE_RADIUS_TEXT = 0.315

function SpeedMeterDisplay:setupSpeedGauge(gaugeBackgroundElement, minSpeedGaugeValue, maxSpeedGaugeValue, speedGaugeRounding, fixedLowerLimit, valueScale)
	local sizeValues = self.speedGaugeSizeValues

	if sizeValues == nil then
		sizeValues = {}
		local _ = nil
		sizeValues.stepWidthOrig, sizeValues.stepHeightOrig = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.GAUGE_BAR))
		sizeValues.stepSmallWidthOrig, sizeValues.stepSmallHeightOrig = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.GAUGE_BAR_SMALL))
		sizeValues.centerOffsetXOrig, sizeValues.centerOffsetYOrig = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.GAUGE_CENTER))
		sizeValues.stepXOffsetOrig, _ = getNormalizedScreenValues(1, 0)
		sizeValues.stepUVs = GuiUtils.getUVs(SpeedMeterDisplay.UV.GAUGE_STEP)
		sizeValues.stepSmallUVs = GuiUtils.getUVs(SpeedMeterDisplay.UV.GAUGE_STEP_SMALL)
		self.speedGaugeSizeValues = sizeValues
	end

	sizeValues.stepWidth = sizeValues.stepWidthOrig * self.uiScale
	sizeValues.stepHeight = sizeValues.stepHeightOrig * self.uiScale
	sizeValues.stepSmallWidth = sizeValues.stepSmallWidthOrig * self.uiScale
	sizeValues.stepSmallHeight = sizeValues.stepSmallHeightOrig * self.uiScale
	sizeValues.centerOffsetX = sizeValues.centerOffsetXOrig * self.uiScale
	sizeValues.centerOffsetY = sizeValues.centerOffsetYOrig * self.uiScale
	sizeValues.stepXOffset = sizeValues.stepXOffsetOrig * self.uiScale
	valueScale = valueScale or 1
	minSpeedGaugeValue = minSpeedGaugeValue * valueScale
	maxSpeedGaugeValue = maxSpeedGaugeValue * valueScale
	local range = maxSpeedGaugeValue - minSpeedGaugeValue
	local stepDistance = math.ceil(range / 8 / speedGaugeRounding) * speedGaugeRounding
	local minGaugeValue = math.floor(minSpeedGaugeValue / speedGaugeRounding) * speedGaugeRounding - stepDistance
	local maxGaugeValue = math.floor(maxSpeedGaugeValue / speedGaugeRounding) * speedGaugeRounding + stepDistance

	if fixedLowerLimit then
		minGaugeValue = minSpeedGaugeValue
	end

	self.speedGaugeMinValue = minGaugeValue
	self.speedGaugeMaxValue = maxGaugeValue
	local baseX, baseY = gaugeBackgroundElement:getPosition()
	local gaugeCenterX = baseX + sizeValues.centerOffsetX
	local gaugeCenterY = baseY + sizeValues.centerOffsetY
	local baseWidth = gaugeBackgroundElement:getWidth()
	local baseHeight = gaugeBackgroundElement:getHeight()
	local centerOffset = baseWidth * SPEED_GAUGE_RADIUS
	local numSmallSteps = 4
	local numBigSteps = math.floor((maxGaugeValue - minGaugeValue) / stepDistance)
	local numSteps = numBigSteps * (numSmallSteps + 1) + 1
	local curValue = minGaugeValue
	local maxStep = 0

	for i = 1, numSteps do
		local rotation = SPEED_GAUGE_START - (i - 1) * SPEED_GAUGE_RANGE / (numSteps - 1)
		local isSmallStep = (i - 1) % (numSmallSteps + 1) ~= 0
		local xOffset = isSmallStep and 0 or -sizeValues.stepXOffset
		local color = isSmallStep and SpeedMeterDisplay.COLOR.GAUGE_STEP_SMALL or SpeedMeterDisplay.COLOR.GAUGE_STEP

		if self.speedGaugeMode == SpeedMeterDisplay.GAUGE_MODE_RPM and i >= numSteps - 5 then
			color = isSmallStep and SpeedMeterDisplay.COLOR.GAUGE_STEP_WARN_SMALL or SpeedMeterDisplay.COLOR.GAUGE_STEP_WARN
		end

		local gaugeElement = self.speedGaugeElements[i]

		if gaugeElement == nil then
			gaugeElement = {
				stepOverlay = Overlay.new(self.hudAtlasPath, gaugeCenterX - centerOffset + xOffset, gaugeCenterY - sizeValues.stepHeight * 0.5, isSmallStep and sizeValues.stepSmallWidth or sizeValues.stepWidth, isSmallStep and sizeValues.stepSmallHeight or sizeValues.stepHeight)
			}

			if isSmallStep then
				gaugeElement.stepOverlay:setUVs(sizeValues.stepSmallUVs)
			else
				gaugeElement.stepOverlay:setUVs(sizeValues.stepUVs)
			end

			gaugeElement.stepOverlay:setColor(color[1], color[2], color[3], color[4])
			gaugeElement.stepOverlay:setRotation(rotation, centerOffset - xOffset, sizeValues.stepHeight * 0.5)
			self:addChild(HUDElement.new(gaugeElement.stepOverlay))
		else
			gaugeElement.stepOverlay:setColor(color[1], color[2], color[3], color[4])
			gaugeElement.stepOverlay:setRotation(rotation, centerOffset - xOffset, sizeValues.stepHeight * 0.5)
		end

		gaugeElement.stepOverlay:setIsVisible(true)

		if not isSmallStep then
			if self.speedGaugeMode == SpeedMeterDisplay.GAUGE_MODE_RPM then
				gaugeElement.text = string.format("%d", curValue / 100)
			else
				gaugeElement.text = string.format("%d", curValue)
			end

			local cosRot = math.cos(rotation - math.pi)
			local sinRot = math.sin(rotation - math.pi)
			gaugeElement.textPosX = sizeValues.centerOffsetX + cosRot * baseWidth * SPEED_GAUGE_RADIUS_TEXT
			gaugeElement.textPosY = sizeValues.centerOffsetY + sinRot * baseHeight * SPEED_GAUGE_RADIUS_TEXT
			curValue = curValue + stepDistance
		end

		self.speedGaugeElements[i] = gaugeElement
		maxStep = i
	end

	for i = maxStep + 1, #self.speedGaugeElements do
		self.speedGaugeElements[i].stepOverlay:setIsVisible(false)

		self.speedGaugeElements[i].text = nil
	end
end

function SpeedMeterDisplay:createDamageBar(hudAtlasPath, baseX, baseY)
	local width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.DAMAGE_LEVEL_BAR))
	local posX, posY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.DAMAGE_LEVEL_BAR))
	local element = HUDRoundedBarElement.new(hudAtlasPath, baseX + posX, baseY + posY, width, height, false)

	element:setBarColor(unpack(SpeedMeterDisplay.COLOR.DAMAGE_GAUGE))
	self:addChild(element)

	return element
end

function SpeedMeterDisplay:createFuelBar(hudAtlasPath, baseX, baseY)
	local width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.FUEL_LEVEL_BAR))
	local posX, posY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.FUEL_LEVEL_BAR))
	local element = HUDRoundedBarElement.new(hudAtlasPath, baseX + posX, baseY + posY, width, height, false)

	element:setBarColor(unpack(SpeedMeterDisplay.COLOR.FUEL_GAUGE))
	self:addChild(element)

	return element
end

function SpeedMeterDisplay:createGaugeIconElements(hudAtlasPath, baseX, baseY)
	local posX, posY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.DAMAGE_LEVEL_ICON))
	local width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.DAMAGE_LEVEL_ICON))
	local iconOverlay = Overlay.new(hudAtlasPath, baseX + posX, baseY + posY, width, height)

	iconOverlay:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.DAMAGE_LEVEL_ICON))

	local damageGaugeIconElement = HUDElement.new(iconOverlay)

	self:addChild(damageGaugeIconElement)

	posX, posY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.FUEL_LEVEL_ICON))
	width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.FUEL_LEVEL_ICON))
	iconOverlay = Overlay.new(hudAtlasPath, baseX + posX, baseY + posY, width, height)

	iconOverlay:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.FUEL_LEVEL_ICON))

	local fuelGaugeIconElement = HUDElement.new(iconOverlay)

	self:addChild(fuelGaugeIconElement)

	return damageGaugeIconElement, fuelGaugeIconElement
end

function SpeedMeterDisplay:createCruiseControlElement(hudAtlasPath, baseX, baseY)
	local posX, posY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.CRUISE_CONTROL))
	local width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.CRUISE_CONTROL))
	local cruiseControlOverlay = Overlay.new(hudAtlasPath, baseX + posX, baseY + posY, width, height)

	cruiseControlOverlay:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.CRUISE_CONTROL))

	local element = HUDElement.new(cruiseControlOverlay)

	self:addChild(element)

	return element
end

function SpeedMeterDisplay:createOperatingTimeElement(hudAtlasPath, baseX, baseY)
	local operatingTimeWidth, operatingTimeHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.OPERATING_TIME))
	local operatingTimeOffsetX, operatingTimeOffsetY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.OPERATING_TIME))
	local operatingTimeOverlay = Overlay.new(hudAtlasPath, baseX + operatingTimeOffsetX, baseY + operatingTimeOffsetY, operatingTimeWidth, operatingTimeHeight)

	operatingTimeOverlay:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.OPERATING_TIME))

	local element = HUDElement.new(operatingTimeOverlay)

	self:addChild(element)

	return element
end

function SpeedMeterDisplay:createSpeedGaugeIndicator(hudAtlasPath, baseX, baseY)
	local width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.GAUGE_INDICATOR_LARGE))
	local indicatorOverlay = Overlay.new(hudAtlasPath, 0, 0, width, height)

	indicatorOverlay:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.GAUGE_INDICATOR_LARGE))
	indicatorOverlay:setColor(unpack(SpeedMeterDisplay.COLOR.SPEED_GAUGE_INDICATOR))

	local indicatorElement = HUDElement.new(indicatorOverlay)
	local pivotX, pivotY = self:normalizeUVPivot(SpeedMeterDisplay.PIVOT.GAUGE_INDICATOR_LARGE, SpeedMeterDisplay.SIZE.GAUGE_INDICATOR_LARGE, SpeedMeterDisplay.UV.GAUGE_INDICATOR_LARGE)

	indicatorElement:setRotationPivot(pivotX, pivotY)
	self:addChild(indicatorElement)

	return indicatorElement
end

function SpeedMeterDisplay:createGearIndicator(hudAtlasPath, baseX, baseY)
	local width, height = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.GEAR_INDICATOR))
	local posX, posY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.GEAR_INDICATOR))
	local selfX, selfY = self:getPosition()
	posX = selfX + posX
	posY = selfY + posY
	local background = Overlay.new(nil, posX, posY, width, height)
	local element = HUDElement.new(background)

	self:addChild(element)

	local circleWidth, circleHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.GEAR_ICON_BG))
	local groupX, groupY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.GEAR_GROUP))
	local iconBgX, iconBgY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.GEAR_ICON_BG))
	local iconWidth, iconHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.GEAR_ICON))
	local barX, barY = getNormalizedScreenValues(unpack(SpeedMeterDisplay.POSITION.GEARS_BAR))
	local barWidth, barHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.GEARS_BAR))
	local selectorWidth, selectorHeight = getNormalizedScreenValues(unpack(SpeedMeterDisplay.SIZE.GEAR_SELECTOR))
	local gearGroupBg = Overlay.new(hudAtlasPath, posX + groupX, posY + groupY, circleWidth, circleHeight)

	gearGroupBg:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.GEAR_CIRCLE))
	gearGroupBg:setColor(unpack(SpeedMeterDisplay.COLOR.GEARS_BG))

	self.gearGroupBg = HUDElement.new(gearGroupBg)

	element:addChild(self.gearGroupBg)

	local iconBg = Overlay.new(hudAtlasPath, posX + iconBgX, posY + iconBgY, circleWidth, circleHeight)

	iconBg:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.GEAR_CIRCLE))
	iconBg:setColor(unpack(SpeedMeterDisplay.COLOR.GEARS_BG))

	self.gearIconBg = HUDElement.new(iconBg)

	element:addChild(self.gearIconBg)

	local icon = Overlay.new(hudAtlasPath, posX + iconBgX + (circleWidth - iconWidth) / 2, posY + iconBgY + (circleHeight - iconHeight) / 2, iconWidth, iconHeight)

	icon:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.GEAR_ICON))
	icon:setColor(unpack(SpeedMeterDisplay.COLOR.GEAR_ICON))

	self.gearIcon = HUDElement.new(icon)

	element:addChild(self.gearIcon)

	local bar = Overlay.new(hudAtlasPath, posX + barX, posY + barY, barWidth, barHeight)

	bar:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.GEARS_BAR))
	bar:setColor(unpack(SpeedMeterDisplay.COLOR.GEARS_BG))

	self.gearBg = HUDElement.new(bar)

	element:addChild(self.gearBg)

	local selectorIcon = Overlay.new(hudAtlasPath, posX + (circleWidth - selectorWidth) / 2, posY + (circleHeight - selectorHeight) / 2, selectorWidth, selectorHeight)

	selectorIcon:setUVs(GuiUtils.getUVs(SpeedMeterDisplay.UV.GEAR_SELECTOR))
	selectorIcon:setColor(unpack(SpeedMeterDisplay.COLOR.GEAR_SELECTOR))

	self.gearSelectorIcon = HUDElement.new(selectorIcon)

	element:addChild(self.gearSelectorIcon)

	return element
end

function SpeedMeterDisplay:setGearGroupVisible(visible)
	self.gearGroupBg:setVisible(visible)

	if visible then
		self.gearGroupBg:setPosition(nil, self.gearGroupBgY)
		self.gearIconBg:setPosition(nil, self.gearIconBgY)
		self.gearIcon:setPosition(nil, self.gearIconBgY + (self.gearIconBg.overlay.height - self.gearIcon.overlay.height) / 2)
	else
		self.gearIconBg:setPosition(nil, self.gearGroupBgY)
		self.gearIcon:setPosition(nil, self.gearGroupBgY + (self.gearIconBg.overlay.height - self.gearIcon.overlay.height) / 2)
	end
end

SpeedMeterDisplay.UV = {
	FUEL_LEVEL_ICON = {
		192,
		0,
		48,
		48
	},
	FUEL_LEVEL_ICON_ELECTRIC = {
		480,
		0,
		48,
		48
	},
	FUEL_LEVEL_ICON_METHANE = {
		528,
		0,
		48,
		48
	},
	DAMAGE_LEVEL_ICON = {
		144,
		0,
		48,
		48
	},
	OPERATING_TIME = {
		16,
		0,
		32,
		48
	},
	CRUISE_CONTROL = {
		96,
		146,
		42,
		42
	},
	GAUGE_BACKGROUND = {
		0,
		0,
		1024,
		1024
	},
	GAUGE_INDICATOR_LARGE = {
		0,
		288,
		48,
		96
	},
	GAUGE_STEP = {
		194,
		76,
		27,
		8
	},
	GAUGE_STEP_SMALL = {
		195,
		87,
		18,
		5
	},
	GEAR_ICON = {
		337,
		353,
		32,
		32
	},
	GEAR_SELECTOR = {
		337,
		387,
		32,
		32
	},
	GEAR_CIRCLE = {
		472,
		331,
		44,
		44
	},
	GEARS_BAR = {
		417,
		331,
		44,
		110
	}
}
SpeedMeterDisplay.GAUGE_TEXTURE_SCALE = 0.6
SpeedMeterDisplay.SIZE = {
	BACKGROUND = {
		277,
		256
	},
	GAUGE_BACKGROUND = {
		256,
		256
	},
	FUEL_LEVEL_ICON = {
		28,
		28
	},
	DAMAGE_LEVEL_ICON = {
		28,
		28
	},
	FUEL_LEVEL_BAR = {
		12,
		110
	},
	DAMAGE_LEVEL_BAR = {
		12,
		110
	},
	CRUISE_CONTROL = {
		27,
		27
	},
	OPERATING_TIME = {
		17,
		25
	},
	GAUGE_INDICATOR_LARGE = {
		SpeedMeterDisplay.UV.GAUGE_INDICATOR_LARGE[3],
		SpeedMeterDisplay.UV.GAUGE_INDICATOR_LARGE[4]
	},
	GAUGE_INDICATOR_LARGE_RADIUS = {
		110 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE,
		110 * SpeedMeterDisplay.GAUGE_TEXTURE_SCALE
	},
	GAUGE_BAR = {
		15,
		3
	},
	GAUGE_BAR_SMALL = {
		9,
		2
	},
	GEAR_INDICATOR = {
		44,
		228
	},
	GEAR_GROUP = {
		44,
		44
	},
	GEARS_BAR = {
		44,
		110
	},
	GEAR_ICON_BG = {
		44,
		44
	},
	GEAR_ICON = {
		32,
		32
	},
	GEAR_SELECTOR = {
		32,
		32
	}
}
SpeedMeterDisplay.POSITION = {
	SELF = {
		-64,
		0
	},
	GAUGE_BACKGROUND = {
		(SpeedMeterDisplay.SIZE.BACKGROUND[1] - SpeedMeterDisplay.SIZE.BACKGROUND[1]) * 0.5,
		(SpeedMeterDisplay.SIZE.BACKGROUND[2] - SpeedMeterDisplay.SIZE.BACKGROUND[2]) * 0.5
	},
	GAUGE_CENTER = {
		128,
		128
	},
	FUEL_LEVEL_ICON = {
		230,
		10
	},
	DAMAGE_LEVEL_ICON = {
		230,
		210
	},
	FUEL_LEVEL_BAR = {
		262,
		8
	},
	DAMAGE_LEVEL_BAR = {
		262,
		126
	},
	CRUISE_CONTROL = {
		100,
		75
	},
	CRUISE_CONTROL_TEXT = {
		8,
		5
	},
	OPERATING_TIME = {
		90,
		20
	},
	OPERATING_TIME_TEXT = {
		5,
		6
	},
	SPEED_TEXT = {
		0,
		133
	},
	SPEED_UNIT = {
		0,
		115
	},
	SPEED_UNIT_TEXT = {
		0,
		183
	},
	GEAR_TEXT = {
		0,
		155
	},
	GEAR_INDICATOR = {
		290,
		10
	},
	GEARS_BAR = {
		0,
		0
	},
	GEAR_GROUP = {
		0,
		125
	},
	GEAR_ICON_BG = {
		0,
		184
	},
	GEAR_TEXT_1 = {
		0,
		16
	},
	GEAR_TEXT_2 = {
		0,
		48
	},
	GEAR_TEXT_3 = {
		0,
		80
	},
	GEAR_GROUP_TEXT = {
		0,
		141
	}
}
SpeedMeterDisplay.TEXT_SIZE = {
	CRUISE_CONTROL = 22,
	OPERATING_TIME = 18,
	SPEED = 50,
	SPEED_UNIT = 14,
	RPM_UNIT = 10,
	GEAR = 16
}
SpeedMeterDisplay.COLOR = {
	SHADOW_BACKGROUND = {
		1,
		1,
		1,
		1
	},
	SPEED_TEXT = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	SPEED_UNIT = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	SPEED_GAUGE_INDICATOR = {
		1,
		1,
		1,
		1
	},
	GAUGE_STEP = {
		0.7,
		0.7,
		0.7,
		0.6
	},
	GAUGE_STEP_SMALL = {
		0.7,
		0.7,
		0.7,
		0.3
	},
	GAUGE_STEP_WARN = {
		0.7,
		0.04,
		0.04,
		0.8
	},
	GAUGE_STEP_WARN_SMALL = {
		0.7,
		0.04,
		0.04,
		0.8
	},
	DAMAGE_GAUGE = {
		1,
		0.4233,
		0
	},
	DAMAGE_GAUGE_LOW = {
		1,
		0.1233,
		0
	},
	FUEL_GAUGE = {
		0.4423,
		0.6724,
		0.0093
	},
	CRUISE_CONTROL_OFF = {
		1,
		1,
		1,
		0.5
	},
	CRUISE_CONTROL_ON = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	GEAR_TEXT = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	GEAR_TEXT_CHANGE = {
		1,
		1,
		1,
		0.5
	},
	GEAR_ICON = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	GEAR_SELECTOR = {
		0.0003,
		0.5647,
		0.9822,
		0.4
	},
	GEARS_BG = {
		0,
		0,
		0,
		0.54
	},
	GEARS_BG_WARN = {
		1,
		0,
		0,
		0.54
	}
}
SpeedMeterDisplay.PIVOT = {
	GAUGE_INDICATOR_LARGE = {
		24,
		23
	}
}
SpeedMeterDisplay.SPEED_GAUGE_FULL_ANGLE = 249
SpeedMeterDisplay.ANGLE = {
	SPEED_GAUGE_MIN = MathUtil.degToRad(90 + SpeedMeterDisplay.SPEED_GAUGE_FULL_ANGLE * 0.5),
	SPEED_GAUGE_MAX = MathUtil.degToRad(90 - SpeedMeterDisplay.SPEED_GAUGE_FULL_ANGLE * 0.5)
}
SpeedMeterDisplay.GAUGE_MODE_RPM = 1
SpeedMeterDisplay.GAUGE_MODE_SPEED = 2
