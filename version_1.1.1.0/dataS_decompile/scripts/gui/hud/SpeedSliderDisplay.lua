SpeedSliderDisplay = {}
local SpeedSliderDisplay_mt = Class(SpeedSliderDisplay, HUDDisplayElement)
SpeedSliderDisplay.GAMEPAD_SWITCH_TIME = 500
SpeedSliderDisplay.SPEED_NEED_OFFSET = math.rad(12)
SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS = {
	0,
	0.2,
	0.4,
	0.6,
	0.8,
	1
}
SpeedSliderDisplay.PLAYER_SNAP_POSITIONS = {
	0,
	0.2,
	0.6,
	1
}

function SpeedSliderDisplay.new(hud, hudAtlasPath)
	local backgroundOverlay = SpeedSliderDisplay.createBackground()
	local self = SpeedSliderDisplay:superClass().new(backgroundOverlay, nil, SpeedSliderDisplay_mt)
	self.hud = hud
	self.uiScale = 1
	self.hudAtlasPath = hudAtlasPath
	self.vehicle = nil
	self.player = nil
	self.isRideable = false
	self.sliderPosition = 0
	self.restPosition = 0.25
	self.hudElements = {}
	self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
	self.sliderState = nil

	self:createComponents()
	g_messageCenter:subscribe(MessageType.GUI_DIALOG_OPENED, self.onDialogOpened, self)

	return self
end

function SpeedSliderDisplay:delete()
	g_messageCenter:unsubscribeAll(self)
	SpeedSliderDisplay:superClass().delete(self)
end

function SpeedSliderDisplay:createComponents()
	local baseX, baseY = self:getPosition()

	for _, element in ipairs(self.hudElements) do
		element:delete()
	end

	self.hudElements = {}
	local bgSizeX, bgSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.BACKGROUND))
	local backgroundOverlay = Overlay.new(self.hudAtlasPath, baseX, baseY, bgSizeX, bgSizeY)

	backgroundOverlay:setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.BACKGROUND))

	self.backgroundHudElement = HUDElement.new(backgroundOverlay)

	table.insert(self.hudElements, self.backgroundHudElement)

	self.snapSteps = {
		self:createHUDElement(SpeedSliderDisplay.POSITION.SNAP1, SpeedSliderDisplay.SIZE.SNAP, SpeedSliderDisplay.UV.SNAP),
		self:createHUDElement(SpeedSliderDisplay.POSITION.SNAP2, SpeedSliderDisplay.SIZE.SNAP, SpeedSliderDisplay.UV.SNAP),
		self:createHUDElement(SpeedSliderDisplay.POSITION.SNAP3, SpeedSliderDisplay.SIZE.SNAP, SpeedSliderDisplay.UV.SNAP)
	}

	for i = 1, 3 do
		table.insert(self.hudElements, self.snapSteps[i])
		self.snapSteps[i]:setVisible(false)
	end

	self.positiveBarHudElement = self:createBar(SpeedSliderDisplay.POSITION.POSITIVE_BAR, SpeedSliderDisplay.SIZE.POSITIVE_BAR, SpeedSliderDisplay.COLOR.POSITIVE_BAR)

	table.insert(self.hudElements, self.positiveBarHudElement)

	self.negativeBarHudElement = self:createBar(SpeedSliderDisplay.POSITION.NEGATIVE_BAR, SpeedSliderDisplay.SIZE.NEGATIVE_BAR, SpeedSliderDisplay.COLOR.NEGATIVE_BAR)

	table.insert(self.hudElements, self.negativeBarHudElement)

	self.negativeBarPosX, self.negativeBarPosY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.NEGATIVE_BAR))
	local _, negativeBarSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.NEGATIVE_BAR))
	self.negativeBarSizeY = negativeBarSizeY
	local gpbgPosX, gpbgPosY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.GAMEPAD_BACKGROUND))
	local gpbgSizeX, gpbgSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.GAMEPAD_BACKGROUND))
	local gamepadBackgroundOverlay = Overlay.new(self.hudAtlasPath, baseX + gpbgPosX, baseY + gpbgPosY, gpbgSizeX, gpbgSizeY)

	gamepadBackgroundOverlay:setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.GAMEPAD_BACKGROUND))

	self.gamepadBackgroundHudElement = HUDElement.new(gamepadBackgroundOverlay)

	table.insert(self.hudElements, self.gamepadBackgroundHudElement)

	local gpbgbPosX, gpbgbPosY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.GAMEPAD_BACKGROUND))
	local gpbgbSizeX, gpbgbSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.GAMEPAD_BACKGROUND_BORDER))
	local gamepadBackgroundBorderOverlay = Overlay.new(self.hudAtlasPath, baseX + gpbgbPosX, baseY + gpbgbPosY, gpbgbSizeX, gpbgbSizeY)

	gamepadBackgroundBorderOverlay:setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.GAMEPAD_BACKGROUND_BORDER))
	self.gamepadBackgroundHudElement:addChild(HUDElement.new(gamepadBackgroundBorderOverlay))

	local pljbgPosX, pljbgPosY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.PLAYER_JUMP_BACKGROUND))
	local pljbgSizeX, pljbgSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.PLAYER_JUMP_BACKGROUND))
	self.playerJumpBackgroundHudElement = HUDFrameElement.new(self.hudAtlasPath, baseX + pljbgPosX, baseY + pljbgPosY, pljbgSizeX, pljbgSizeY, nil, false, 2)

	self.playerJumpBackgroundHudElement:setColor(unpack(SpeedSliderDisplay.COLOR.PLAYER_JUMP_BACKGROUND))
	self.playerJumpBackgroundHudElement:setFrameColor(unpack(SpeedSliderDisplay.COLOR.PLAYER_JUMP_BACKGROUND_FRAME))
	table.insert(self.hudElements, self.playerJumpBackgroundHudElement)

	self.textPosX, self.textPosY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.SPEED_TEXT))
	local _, textSize = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.SPEED_TEXT))
	self.textSize = textSize
	local slOffX, slOffY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.SLIDER_OFFSET))
	local slSizeX, slSizeY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.SLIDER_SIZE))
	local sliderOverlay = Overlay.new(self.hudAtlasPath, baseX + slOffX, baseY + slOffY, slSizeX, slSizeY)

	sliderOverlay:setUVs(GuiUtils.getUVs(SpeedSliderDisplay.UV.SLIDER))

	self.sliderPosX = slOffX
	self.sliderPosY = slOffY
	self.backgroundSizeY = bgSizeY - slOffY * 2
	local _, slAreaY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.SLIDER_AREA))
	self.sliderAreaY = slAreaY
	local _, slCenterY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.SLIDER_CENTER))
	self.restPosition = slCenterY / slAreaY
	local sliderMin = self.sliderPosY
	local sliderMax = sliderMin + self.sliderAreaY
	local sliderCenter = sliderMin + self.sliderAreaY * self.restPosition
	self.sliderHudElement = HUDSliderElement.new(sliderOverlay, backgroundOverlay, 2.5, 0.4, 4, 2, sliderMin, sliderCenter, sliderMax, sliderMax)

	self.sliderHudElement:setCallback(self.onSliderPositionChanged, self)
	table.insert(self.hudElements, self.sliderHudElement)

	for _, element in ipairs(self.hudElements) do
		self:addChild(element)
	end

	self.sliderHudElement:setAxisPosition(sliderCenter)
end

function SpeedSliderDisplay:setSliderState(state)
	if self.sliderState ~= state then
		if state then
			self:showSlider()
		else
			self:hideSlider()
		end
	end
end

function SpeedSliderDisplay:hideSlider()
	local _, yOffset = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.GAMEPAD_BACKGROUND))
	local startX, startY = self:getPosition()
	local sequence = TweenSequence.new(self)

	sequence:insertTween(MultiValueTween:new(self.setPosition, {
		startX,
		startY
	}, {
		self.origX,
		self.origY - yOffset
	}, HUDDisplayElement.MOVE_ANIMATION_DURATION), 0)
	sequence:start()

	self.animation = sequence
	self.sliderState = false

	self.sliderHudElement:setTouchIsActive(false)
	self:updateElementsVisibility()
end

function SpeedSliderDisplay:showSlider()
	local startX, startY = self:getPosition()
	local sequence = TweenSequence.new(self)

	sequence:insertTween(MultiValueTween:new(self.setPosition, {
		startX,
		startY
	}, {
		self.origX,
		self.origY
	}, HUDDisplayElement.MOVE_ANIMATION_DURATION), 0)
	sequence:addCallback(self.onSliderVisibilityChangeFinished, true)
	sequence:start()

	self.animation = sequence
	self.sliderState = true

	self.sliderHudElement:resetSlider()
	self.sliderHudElement:setTouchIsActive(true)
end

function SpeedSliderDisplay:updateElementsVisibility()
	for _, element in ipairs(self.hudElements) do
		if not self.sliderState then
			if self.player ~= nil then
				element:setVisible(element == self.playerJumpBackgroundHudElement)
			else
				element:setVisible(element == self.gamepadBackgroundHudElement)
			end
		else
			element:setVisible(element ~= self.playerJumpBackgroundHudElement and element ~= self.gamepadBackgroundHudElement)
		end
	end
end

function SpeedSliderDisplay:onSliderVisibilityChangeFinished(visibility)
	if visibility then
		self:updateElementsVisibility()

		for i = 1, 3 do
			self.snapSteps[i]:setVisible(self.isRideable)
		end
	end
end

function SpeedSliderDisplay:setVehicle(vehicle)
	self.vehicle = vehicle

	if vehicle ~= nil then
		self.isRideable = SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)

		if self.player ~= nil then
			self:setPlayer(nil)
		end

		self:removeJumpButton()
		self.sliderHudElement:resetSlider()
		self.sliderHudElement:clearSnapPositions()

		if self.isRideable then
			for i = 1, #SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS do
				self.sliderHudElement:addSnapPosition(self.sliderPosY + self.sliderAreaY * SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[i])
			end

			self:addJumpButton()
		end

		for i = 1, 3 do
			self.snapSteps[i]:setVisible(self.isRideable)
		end
	end

	self:updateElementsVisibility()
end

function SpeedSliderDisplay:setPlayer(player)
	self.player = player

	if player ~= nil then
		if self.vehicle ~= nil then
			self:setVehicle(nil)
		end

		self:removeJumpButton()
		self:addJumpButton()
		self:setJumpButtonActive(true)
		self.sliderHudElement:resetSlider()
		self.sliderHudElement:clearSnapPositions()

		for i = 1, #SpeedSliderDisplay.PLAYER_SNAP_POSITIONS do
			self.sliderHudElement:addSnapPosition(self.sliderPosY + self.sliderAreaY * SpeedSliderDisplay.PLAYER_SNAP_POSITIONS[i])
		end
	end

	self:updateVisibilityState()
	self:updateElementsVisibility()
end

function SpeedSliderDisplay:addJumpButton()
	if self.jumpButton == nil then
		self.jumpButton = {}
		local position = SpeedSliderDisplay.POSITION.JUMP_BUTTON
		local size = SpeedSliderDisplay.SIZE.JUMP_BUTTON

		if self.player ~= nil then
			local x, y = unpack(SpeedSliderDisplay.POSITION.PLAYER_JUMP_BACKGROUND)
			x = x + (SpeedSliderDisplay.SIZE.PLAYER_JUMP_BACKGROUND[1] - SpeedSliderDisplay.SIZE.PLAYER_JUMP_BACKGROUND_ICON[1]) / 2
			y = y + (SpeedSliderDisplay.SIZE.PLAYER_JUMP_BACKGROUND[2] - SpeedSliderDisplay.SIZE.PLAYER_JUMP_BACKGROUND_ICON[2]) / 2
			position = {
				x,
				y
			}
			size = SpeedSliderDisplay.SIZE.PLAYER_JUMP_BACKGROUND_ICON
		end

		self.jumpButton.iconElement = self:createHUDElement(position, size, SpeedSliderDisplay.UV.JUMP, SpeedSliderDisplay.COLOR.JUMP_UP)
		self.jumpButton.isDisabled = false

		local function pressButton(button)
			if not self.jumpButton.isDisabled then
				button.iconElement:setColor(unpack(SpeedSliderDisplay.COLOR.JUMP_DOWN))
			end
		end

		local function releaseButton(button)
			if not self.jumpButton.isDisabled then
				button.iconElement:setColor(unpack(SpeedSliderDisplay.COLOR.JUMP_UP))
			end
		end

		local function buttonCb(target, x, y, isCancel)
			if not isCancel then
				self.onJumpEventCallback(target, x, y)
			end
		end

		self.jumpButton.touchAreas = {
			self.hud:addTouchButton(self.jumpButton.iconElement.overlay, 1, 1, buttonCb, self, TouchHandler.TRIGGER_UP, {
				self.jumpButton
			}),
			self.hud:addTouchButton(self.jumpButton.iconElement.overlay, 1, 1, pressButton, self.jumpButton, TouchHandler.TRIGGER_DOWN),
			self.hud:addTouchButton(self.jumpButton.iconElement.overlay, 1, 1, releaseButton, self.jumpButton, TouchHandler.TRIGGER_UP)
		}

		self:addChild(self.jumpButton.iconElement)

		self.sliderHudElement.touchAreaDown.areaOffsetY[2] = -0.125
		self.sliderHudElement.touchAreaAlways.areaOffsetY[2] = -0.125
		self.sliderHudElement.touchAreaUp.areaOffsetY[2] = -0.125

		self:setJumpButtonActive(false)
	end

	self.jumpButton.iconElement:setUVs(GuiUtils.getUVs(self.player ~= nil and SpeedSliderDisplay.UV.JUMP_PLAYER or SpeedSliderDisplay.UV.JUMP))
end

function SpeedSliderDisplay:removeJumpButton()
	if self.jumpButton ~= nil then
		self.jumpButton.iconElement:delete()

		for i = 1, 3 do
			self.hud:removeTouchButton(self.jumpButton.touchAreas[i])
		end

		self.jumpButton = nil
		self.sliderHudElement.touchAreaDown.areaOffsetY[2] = 0.2
		self.sliderHudElement.touchAreaAlways.areaOffsetY[2] = 0.2
		self.sliderHudElement.touchAreaUp.areaOffsetY[2] = 0.2
	end
end

function SpeedSliderDisplay:setJumpButtonActive(state)
	if self.jumpButton ~= nil then
		self.jumpButton.isDisabled = not state

		if state then
			self.jumpButton.iconElement:setColor(unpack(SpeedSliderDisplay.COLOR.JUMP_UP))
		else
			self.jumpButton.iconElement:setColor(unpack(SpeedSliderDisplay.COLOR.JUMP_DISABLED))
		end
	end
end

function SpeedSliderDisplay:createHUDElement(position, size, uvs, color)
	local baseX, baseY = self:getPosition()
	local posX, posY = getNormalizedScreenValues(unpack(position))
	local sizeX, sizeY = getNormalizedScreenValues(unpack(size))
	local overlay = Overlay.new(self.hudAtlasPath, baseX + posX, baseY + posY, sizeX, sizeY)

	overlay:setUVs(GuiUtils.getUVs(uvs))

	if color ~= nil then
		overlay:setColor(unpack(color))
	end

	return HUDElement.new(overlay)
end

function SpeedSliderDisplay:createBar(position, size, color)
	local baseX, baseY = self:getPosition()
	local posX, posY = getNormalizedScreenValues(unpack(position))
	local sizeX, sizeY = getNormalizedScreenValues(unpack(size))
	local barOverlay = Overlay.new(self.hudAtlasPath, baseX + posX, baseY + posY, sizeX, sizeY)

	barOverlay:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
	barOverlay:setColor(unpack(color))

	return HUDElement.new(barOverlay)
end

function SpeedSliderDisplay:onSliderPositionChanged(position)
	self.sliderPosition = MathUtil.clamp(position, 0, 1)
	local selfX, selfY = self:getPosition()
	local acc, brake = self:getAccelerateAndBrakeValue()

	self.positiveBarHudElement:setScale(1, acc)
	self.positiveBarHudElement:setColor(unpack(self.cruiseControlIsActive and SpeedSliderDisplay.COLOR.CRUISE_CONTROL or SpeedSliderDisplay.COLOR.POSITIVE_BAR))
	self.negativeBarHudElement:setPosition(selfX + self.negativeBarPosX, selfY + self.negativeBarPosY + self.negativeBarSizeY * (1 - brake))
	self.negativeBarHudElement:setScale(1, brake)

	if self.vehicle ~= nil and self.isRideable then
		for gait = 1, #SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS do
			if math.abs(position - SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[gait]) < 0.01 then
				self.vehicle:setCurrentGait(gait)

				self.lastGait = gait
				self.lastGaitTime = g_time

				break
			end
		end

		self:setJumpButtonActive(self.vehicle:getIsRideableJumpAllowed(true))
	end
end

function SpeedSliderDisplay:getAccelerateAndBrakeValue()
	return MathUtil.clamp((self.sliderPosition - self.restPosition) / (1 - self.restPosition), 0, 1), 1 - MathUtil.clamp(self.sliderPosition / self.restPosition, 0, 1)
end

function SpeedSliderDisplay:onJumpEventCallback()
	if self.vehicle ~= nil and self.isRideable and self.vehicle:getIsRideableJumpAllowed() then
		self.vehicle:jump()
	end

	if self.player ~= nil then
		self.player:onInputJump(_, 1)
	end
end

function SpeedSliderDisplay:update(dt)
	SpeedSliderDisplay:superClass().update(self, dt)

	if self.sliderHudElement ~= nil then
		self.sliderHudElement:update(dt)
	end

	if self.vehicle ~= nil then
		if self.vehicle.setAccelerationPedalInput ~= nil then
			local acceleration, brake = self:getAccelerateAndBrakeValue()
			local direction = acceleration > 0 and 1 or brake > 0 and -1 or 0

			self.vehicle:setTargetSpeedAndDirection(math.abs(acceleration + brake), direction)
		end

		if self.isRideable then
			local currentGait = self.vehicle:getCurrentGait()

			if currentGait ~= self.lastGait and self.lastGaitTime < g_time - 250 and SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[currentGait] ~= nil then
				self.sliderHudElement:setAxisPosition(self.sliderPosY + self.sliderAreaY * SpeedSliderDisplay.RIDEABLE_SNAP_POSITIONS[currentGait])

				self.lastGait = currentGait
			end
		end
	end

	if self.player ~= nil then
		local acceleration, brake = self:getAccelerateAndBrakeValue()

		self.player:onInputMoveForward(_, -(acceleration - brake))

		if acceleration > 0.75 then
			self.player:onInputRun(_, 1)
		end
	end

	if (self.vehicle ~= nil or self.player ~= nil) and not g_gui:getIsGuiVisible() then
		local show = Utils.getNoNil(Input.isKeyPressed(Input.KEY_lctrl), false)

		g_inputBinding:setShowMouseCursor(show, false)
	end
end

function SpeedSliderDisplay:getIsSliderActive()
	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
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

function SpeedSliderDisplay:onInputHelpModeChange(inputHelpMode)
	self.lastInputHelpMode = inputHelpMode

	if inputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		self.sliderHudElement:setAxisPosition(self.sliderPosY + self.sliderAreaY * self.restPosition)
	end

	self:updateVisibilityState()
end

function SpeedSliderDisplay:onAIVehicleStateChanged(state, vehicle)
	if vehicle == self.vehicle then
		self:updateVisibilityState()
	end
end

function SpeedSliderDisplay:updateVisibilityState()
	local sliderState = self:getIsSliderActive()

	if sliderState ~= self.sliderState then
		self:setSliderState(sliderState, true)
	end
end

function SpeedSliderDisplay:draw()
	SpeedSliderDisplay:superClass().draw(self)

	if self.vehicle ~= nil and not self.isRideable then
		local speed = self.vehicle:getLastSpeed()
		local baseX, baseY = self:getPosition()

		setTextColor(1, 1, 1, 1)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		renderText(baseX + self.textPosX, baseY + self.textPosY, self.textSize, string.format("%02d", speed))
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
	end
end

function SpeedSliderDisplay:setScale(uiScale)
	SpeedSliderDisplay:superClass().setScale(self, uiScale, uiScale)

	local currentVisibility = self:getVisible()

	self:setVisible(true, false)

	self.uiScale = uiScale
	local posX, posY = SpeedSliderDisplay.getBackgroundPosition(uiScale, self:getWidth())

	self:setPosition(posX, posY)
	self:storeOriginalPosition()
	self:setVisible(currentVisibility, false)
end

function SpeedSliderDisplay.getBackgroundPosition(scale, width)
	local offX, offY = getNormalizedScreenValues(unpack(SpeedSliderDisplay.POSITION.BACKGROUND))

	return 1 - g_safeFrameOffsetX - width - offX * scale, g_safeFrameOffsetY - offY * scale
end

function SpeedSliderDisplay.createBackground()
	local width, height = getNormalizedScreenValues(unpack(SpeedSliderDisplay.SIZE.BACKGROUND))
	local posX, posY = SpeedSliderDisplay.getBackgroundPosition(1, width)

	return Overlay.new(nil, posX, posY, width, height)
end

function SpeedSliderDisplay:onDialogOpened(guiName, overlappingDialog)
	if not overlappingDialog then
		self.sliderHudElement:resetSlider()
	end
end

SpeedSliderDisplay.SIZE = {
	BACKGROUND = {
		91,
		628
	},
	GAMEPAD_BACKGROUND = {
		91,
		71
	},
	GAMEPAD_BACKGROUND_BORDER = {
		91,
		2
	},
	PLAYER_JUMP_BACKGROUND = {
		115,
		120
	},
	PLAYER_JUMP_BACKGROUND_ICON = {
		90,
		90
	},
	SLIDER_SIZE = {
		192,
		144
	},
	SLIDER_AREA = {
		192,
		500
	},
	POSITIVE_BAR = {
		66,
		398
	},
	NEGATIVE_BAR = {
		66,
		98
	},
	BACKGROUND_COLOR = {
		139,
		555
	},
	SPEED_TEXT = {
		0,
		60
	},
	GAMEPAD_OFFSET = {
		0,
		-557
	},
	JUMP_BUTTON = {
		69,
		69
	},
	SNAP = {
		75,
		2
	}
}
SpeedSliderDisplay.POSITION = {
	BACKGROUND = {
		18,
		0
	},
	GAMEPAD_BACKGROUND = {
		0,
		557
	},
	PLAYER_JUMP_BACKGROUND = {
		-24,
		557
	},
	SLIDER_OFFSET = {
		-49,
		-41
	},
	SLIDER_CENTER = {
		0,
		100
	},
	POSITIVE_BAR = {
		12,
		136
	},
	NEGATIVE_BAR = {
		12,
		36
	},
	BACKGROUND_COLOR = {
		6,
		40
	},
	SPEED_TEXT = {
		45.5,
		569.5
	},
	JUMP_BUTTON = {
		11,
		557.5
	},
	SNAP1 = {
		8,
		234
	},
	SNAP2 = {
		8,
		334
	},
	SNAP3 = {
		8,
		434
	}
}
SpeedSliderDisplay.UV = {
	BACKGROUND = {
		5,
		293,
		91,
		628
	},
	GAMEPAD_BACKGROUND = {
		5,
		293,
		91,
		71
	},
	GAMEPAD_BACKGROUND_BORDER = {
		5,
		293,
		91,
		2
	},
	SLIDER = {
		97,
		432,
		192,
		142
	},
	JUMP = {
		576,
		336,
		96,
		96
	},
	JUMP_PLAYER = {
		768,
		336,
		96,
		96
	},
	SNAP = {
		13,
		385,
		75,
		2
	}
}
SpeedSliderDisplay.COLOR = {
	BACKGROUND = {
		1,
		1,
		1,
		0.5
	},
	POSITIVE_BAR = {
		0,
		0.486274,
		0.8549019,
		0.5
	},
	NEGATIVE_BAR = {
		1,
		0.1,
		0.1,
		0.5
	},
	BACKGROUND_COLOR = {
		0.40784,
		0.40784,
		0.40784,
		0.8
	},
	CRUISE_CONTROL = {
		0.991,
		0.3865,
		0.01,
		0.9
	},
	JUMP_UP = {
		1,
		1,
		1,
		1
	},
	JUMP_DOWN = {
		0.991,
		0.3865,
		0.01,
		1
	},
	JUMP_DISABLED = {
		0.15,
		0.15,
		0.15,
		1
	},
	PLAYER_JUMP_BACKGROUND = {
		0.015686,
		0.015686,
		0.015686,
		1
	},
	PLAYER_JUMP_BACKGROUND_FRAME = {
		0.098039,
		0.098039,
		0.098039,
		1
	}
}
