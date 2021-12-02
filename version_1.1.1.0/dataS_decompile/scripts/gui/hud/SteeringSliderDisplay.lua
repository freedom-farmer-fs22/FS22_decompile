SteeringSliderDisplay = {}
local SteeringSliderDisplay_mt = Class(SteeringSliderDisplay, HUDDisplayElement)

function SteeringSliderDisplay.new(hud, hudAtlasPath)
	local backgroundOverlay = SteeringSliderDisplay.createBackground()
	local self = SteeringSliderDisplay:superClass().new(backgroundOverlay, nil, SteeringSliderDisplay_mt)
	self.hud = hud
	self.uiScale = 1
	self.hudAtlasPath = hudAtlasPath
	self.vehicle = nil
	self.isRideable = false
	self.sliderPosition = 0
	self.restPosition = 0.5
	self.resetTime = 2500
	self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
	self.lastGyroscopeSteeringState = false

	self:createComponents()

	return self
end

function SteeringSliderDisplay:setVehicle(vehicle)
	self.vehicle = vehicle

	if vehicle ~= nil then
		self.isRideable = SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)

		self.sliderHudElement:setUVs(GuiUtils.getUVs(SteeringSliderDisplay.UV.SLIDER))
	end
end

function SteeringSliderDisplay:setPlayer(player)
	self.player = player

	self:updateVisibilityState()
end

function SteeringSliderDisplay:createComponents()
	local baseX, baseY = self:getPosition()
	local bgSizeX, bgSizeY = getNormalizedScreenValues(unpack(SteeringSliderDisplay.SIZE.BACKGROUND))
	local backgroundOverlay = Overlay.new(self.hudAtlasPath, baseX, baseY, bgSizeX, bgSizeY)

	backgroundOverlay:setUVs(GuiUtils.getUVs(SteeringSliderDisplay.UV.BACKGROUND))

	self.backgroundHudElement = HUDElement.new(backgroundOverlay)

	self:addChild(self.backgroundHudElement)

	local slOffX, slOffY = getNormalizedScreenValues(unpack(SteeringSliderDisplay.POSITION.SLIDER_OFFSET))
	local slSizeX, slSizeY = getNormalizedScreenValues(unpack(SteeringSliderDisplay.SIZE.SLIDER_SIZE))
	local slBorderX, _ = getNormalizedScreenValues(unpack(SteeringSliderDisplay.SIZE.SLIDER_BORDER))
	local sliderOverlay = Overlay.new(self.hudAtlasPath, baseX + slOffX, baseY + slOffY, slSizeX, slSizeY)

	sliderOverlay:setUVs(GuiUtils.getUVs(SteeringSliderDisplay.UV.SLIDER))

	self.sliderPosX = slOffX - slBorderX
	self.sliderPosY = slOffY
	self.backgroundSizeX = bgSizeX - slOffX * 2
	self.sliderSizeX = slSizeX - slBorderX * 2
	local sliderMin = self.sliderPosX
	local sliderMax = sliderMin + self.backgroundSizeX - self.sliderSizeX
	local sliderCenter = sliderMin + (self.backgroundSizeX - self.sliderSizeX) * 0.5
	self.sliderHudElement = HUDSliderElement.new(sliderOverlay, backgroundOverlay, {
		0.12,
		0.05
	}, 1, 2.5, 1, sliderMin, sliderCenter, sliderMax)

	self.sliderHudElement:setCallback(self.onSliderPositionChanged, self)
	self:addChild(self.sliderHudElement)
	self.sliderHudElement:setAxisPosition(sliderCenter)
end

function SteeringSliderDisplay:setVisible(isVisible, animate)
	if not isVisible or g_inputBinding:getInputHelpMode() ~= GS_INPUT_HELP_MODE_GAMEPAD then
		SteeringSliderDisplay:superClass().setVisible(self, isVisible, animate)
	end
end

function SteeringSliderDisplay:onSliderPositionChanged(position)
	self.sliderPosition = MathUtil.clamp(position, 0, 1)
end

function SteeringSliderDisplay:getSteeringValue()
	local norm = self.sliderPosition * 2 - 1

	if norm == 0 then
		return norm
	end

	local sign = norm / math.abs(norm)

	return norm * norm * sign
end

function SteeringSliderDisplay:getIsSliderActive()
	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		return false
	end

	if self.lastGyroscopeSteeringState then
		return false
	end

	if self.vehicle ~= nil and self.vehicle:getIsAIActive() then
		return false
	end

	if self.player ~= nil then
		return false
	end

	return true
end

function SteeringSliderDisplay:onInputHelpModeChange(inputHelpMode)
	self.lastInputHelpMode = inputHelpMode

	self:updateVisibilityState()
end

function SteeringSliderDisplay:onAIVehicleStateChanged(state, vehicle)
	self:updateVisibilityState()
end

function SteeringSliderDisplay:onGyroscopeSteeringChanged(state)
	self.lastGyroscopeSteeringState = state

	self:updateVisibilityState()
end

function SteeringSliderDisplay:updateVisibilityState()
	local animationState = self:getIsSliderActive()

	if animationState ~= self.animationState then
		self:setVisible(animationState, true)
		self.sliderHudElement:setTouchIsActive(animationState)
	end
end

function SteeringSliderDisplay:update(dt)
	SteeringSliderDisplay:superClass().update(self, dt)

	if not g_gameSettings:getValue(GameSettings.SETTING.GYROSCOPE_STEERING) and self.vehicle ~= nil then
		if self.isRideable then
			self.vehicle:setRideableSteer(self:getSteeringValue())
		elseif self.vehicle.setSteeringInput ~= nil then
			self.vehicle:setSteeringInput(self:getSteeringValue(), true, InputDevice.CATEGORY.WHEEL)
		end
	end

	if self.sliderHudElement ~= nil then
		self.sliderHudElement:update(dt)
	end

	if self.vehicle ~= nil and not g_gui:getIsGuiVisible() then
		local show = Utils.getNoNil(Input.isKeyPressed(Input.KEY_lctrl), false)

		g_inputBinding:setShowMouseCursor(show, false)
	end
end

function SteeringSliderDisplay:setScale(uiScale)
	SteeringSliderDisplay:superClass().setScale(self, uiScale, uiScale)

	local currentVisibility = self:getVisible()

	self:setVisible(true, false)

	self.uiScale = uiScale
	local posX, posY = SteeringSliderDisplay.getBackgroundPosition(uiScale, self:getWidth())

	self:setPosition(posX, posY)
	self:storeOriginalPosition()
	self:setVisible(currentVisibility, false)
end

function SteeringSliderDisplay.getBackgroundPosition(scale, width)
	local offX, offY = getNormalizedScreenValues(unpack(SteeringSliderDisplay.POSITION.BACKGROUND))

	return g_safeFrameOffsetX + offX * scale, g_safeFrameOffsetY - offY * scale
end

function SteeringSliderDisplay.createBackground()
	local width, height = getNormalizedScreenValues(unpack(SteeringSliderDisplay.SIZE.BACKGROUND))
	local posX, posY = SteeringSliderDisplay.getBackgroundPosition(1, width)

	return Overlay.new(nil, posX, posY, width, height)
end

SteeringSliderDisplay.SIZE = {
	BACKGROUND = {
		478,
		144
	},
	SLIDER_SIZE = {
		336,
		240
	},
	SLIDER_BORDER = {
		36,
		0
	}
}
SteeringSliderDisplay.POSITION = {
	BACKGROUND = {
		0,
		13
	},
	SLIDER_OFFSET = {
		-4,
		-52
	},
	HIDE_OFFSET = {
		0,
		-250
	}
}
SteeringSliderDisplay.UV = {
	BACKGROUND = {
		97,
		288,
		478,
		144
	},
	SLIDER = {
		288,
		432,
		336,
		240
	}
}
SteeringSliderDisplay.COLOR = {
	BACKGROUND = {
		1,
		1,
		1,
		0.5
	}
}
