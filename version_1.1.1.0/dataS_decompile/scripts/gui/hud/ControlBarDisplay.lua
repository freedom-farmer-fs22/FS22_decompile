ControlBarDisplay = {
	MOVE_ANIMATION_DURATION = 500,
	STATE_TOUCH = 0,
	STATE_CONTROLLER = 1,
	STATE_AI_TOUCH = 2
}
local ControlBarDisplay_mt = Class(ControlBarDisplay, HUDDisplayElement)

function ControlBarDisplay.new(hud, hudAtlasPath)
	local backgroundOverlay = ControlBarDisplay.createBackground()
	local self = ControlBarDisplay:superClass().new(backgroundOverlay, nil, ControlBarDisplay_mt)
	self.hud = hud
	self.uiScale = 1
	self.hudAtlasPath = hudAtlasPath
	self.vehicle = nil
	self.player = nil
	self.hudElements = {}
	self.buttons = {}
	self.controlButtons = {}
	self.inputGlyphs = {}
	self.fillTypeDisplays = {}
	self.numVehicles = 0
	self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD
	self.lastAIState = false
	self.lastGyroscopeSteeringState = false
	self.vehicleControls = {
		attach = {
			prio = 3,
			actionFunc = "detachAttachedImplement",
			fullTapNeeded = true,
			availableFunc = "getShowDetachAttachedImplement",
			triggerType = TouchHandler.TRIGGER_UP,
			uvs = ControlBarDisplay.UV.DETACH,
			inputAction = InputAction.ATTACH
		},
		turnOn = {
			actionFunc = "playControlledActions",
			directionFunc = "getActionControllerDirection",
			fullTapNeeded = true,
			availableFunc = "getAreControlledActionsAvailable",
			allowedFunc = "getAreControlledActionsAllowed",
			prio = 4,
			triggerType = TouchHandler.TRIGGER_UP,
			uvs = ControlBarDisplay.UV.TURN_ON,
			iconColor_pos = ControlBarDisplay.COLOR.BUTTON,
			iconColor_neg = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
			inputAction = InputAction.VEHICLE_ACTION_CONTROL
		},
		ai = {
			actionFunc = "toggleAIVehicle",
			directionFunc = "getIsAIActive",
			fullTapNeeded = true,
			availableFunc = "getCanToggleAIVehicle",
			prio = 5,
			triggerType = TouchHandler.TRIGGER_UP,
			uvs = ControlBarDisplay.UV.AI,
			iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
			iconColor_neg = ControlBarDisplay.COLOR.BUTTON,
			inputAction = InputAction.TOGGLE_AI
		},
		leave = {
			actionFunc = "doLeaveVehicle",
			fullTapNeeded = true,
			availableFunc = "getIsEntered",
			prio = 6,
			triggerType = TouchHandler.TRIGGER_UP,
			uvs = ControlBarDisplay.UV.LEAVE_VEHICLE,
			iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
			iconColor_neg = ControlBarDisplay.COLOR.BUTTON,
			inputAction = InputAction.ENTER
		}
	}
	self.playerControls = {
		enter_vehicle = {
			actionFunc = "onInputEnter",
			fullTapNeeded = true,
			availableFunc = "getCanEnterVehicle",
			prio = 6,
			triggerType = TouchHandler.TRIGGER_UP,
			uvs = ControlBarDisplay.UV.ENTER_VEHICLE,
			iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
			iconColor_neg = ControlBarDisplay.COLOR.BUTTON,
			inputAction = InputAction.ENTER
		},
		enter_horse = {
			actionFunc = "onInputEnter",
			fullTapNeeded = true,
			availableFunc = "getCanEnterRideable",
			prio = 6,
			triggerType = TouchHandler.TRIGGER_UP,
			uvs = ControlBarDisplay.UV.ENTER_HORSE,
			iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
			iconColor_neg = ControlBarDisplay.COLOR.BUTTON,
			inputAction = InputAction.ENTER
		},
		ride = {
			actionFunc = "activateRideState",
			fullTapNeeded = true,
			availableFunc = "getIsRideStateAvailable",
			prio = 7,
			triggerType = TouchHandler.TRIGGER_UP,
			uvs = ControlBarDisplay.UV.ENTER_HORSE,
			iconColor_pos = ControlBarDisplay.COLOR.BUTTON_ACTIVE,
			iconColor_neg = ControlBarDisplay.COLOR.BUTTON,
			inputAction = InputAction.ENTER
		}
	}

	function self.pressButtonCallback(backgroundElement)
		if backgroundElement.overlayId ~= nil and entityExists(backgroundElement.overlayId) then
			backgroundElement:setColor(unpack(ControlBarDisplay.COLOR.BUTTON_ACTIVE))
		end
	end

	function self.releaseButtonCallback(backgroundElement)
		if backgroundElement.overlayId ~= nil and entityExists(backgroundElement.overlayId) then
			backgroundElement:setColor(unpack(ControlBarDisplay.COLOR.BUTTON))
		end
	end

	self:createComponents()

	return self
end

function ControlBarDisplay:removeControls()
	if self.vehicle == nil then
		for i = #self.fillTypeDisplays, 1, -1 do
			self:removeFillLevelDisplay(self.fillTypeDisplays[i])
		end
	end

	for _, vehicleControl in pairs(self.vehicleControls) do
		if vehicleControl.controlButton ~= nil then
			self:removeControlButton(vehicleControl.controlButton)
		end

		vehicleControl.controlButton = nil
	end

	for _, playerControl in pairs(self.playerControls) do
		if playerControl.controlButton ~= nil then
			self:removeControlButton(playerControl.controlButton)
		end

		playerControl.controlButton = nil
	end
end

function ControlBarDisplay:setVehicle(vehicle)
	self.vehicle = vehicle

	self:removeControls()

	if vehicle ~= nil and vehicle.getChildVehicles ~= nil then
		local vehicles = vehicle:getChildVehicles()
		self.numVehicles = #vehicles

		self:addFillLevelDisplaysFromVehicles(vehicles)
	end

	self:updatePositionState()
end

function ControlBarDisplay:setPlayer(player)
	self.player = player

	self:removeControls()
	self:updatePositionState()
end

function ControlBarDisplay:createComponents()
	for _, button in pairs(self.buttons) do
		self.hud:removeTouchButton(button)
	end

	self.buttons = {}
	self.controlButtons = {}

	for _, element in ipairs(self.hudElements) do
		self:removeChild(element)
		element:delete()
	end

	self.hudElements = {}
	self.switchElements = {}
	local frame = self:createFrame(ControlBarDisplay.POSITION.BUTTON_OFFSET, ControlBarDisplay.SIZE.BUTTON_SIZE, ControlBarDisplay.COLOR.BUTTON_BACKGROUND, false)

	table.insert(self.hudElements, frame)
	table.insert(self.switchElements, frame)

	local pos = {
		ControlBarDisplay.POSITION.BUTTON_OFFSET[1] - ControlBarDisplay.POSITION.SWITCH_ARROW_OFFSET[1] + (ControlBarDisplay.SIZE.BUTTON_SIZE[1] - ControlBarDisplay.SIZE.SWITCH_ARROW[1]) / 2,
		ControlBarDisplay.POSITION.BUTTON_OFFSET[2] + ControlBarDisplay.POSITION.SWITCH_ARROW_OFFSET[2] + (ControlBarDisplay.SIZE.BUTTON_SIZE[2] - ControlBarDisplay.SIZE.SWITCH_ARROW[2]) / 2
	}
	local swLeftOverlay = self:createOverlayElement(pos, ControlBarDisplay.SIZE.SWITCH_ARROW, ControlBarDisplay.UV.VEHICLE_LEFT, ControlBarDisplay.COLOR.BUTTON)
	local swLeftElement = HUDElement.new(swLeftOverlay)

	table.insert(self.hudElements, swLeftElement)
	table.insert(self.switchElements, swLeftElement)

	local touchOffsetX = {
		0.1,
		0.4
	}

	table.insert(self.buttons, self.hud:addTouchButton(swLeftOverlay, touchOffsetX, 0.5, self.onSwitchLeft, self, TouchHandler.TRIGGER_UP))
	table.insert(self.buttons, self.hud:addTouchButton(swLeftOverlay, touchOffsetX, 0.5, self.pressButtonCallback, swLeftOverlay, TouchHandler.TRIGGER_DOWN))
	table.insert(self.buttons, self.hud:addTouchButton(swLeftOverlay, touchOffsetX, 0.5, self.releaseButtonCallback, swLeftOverlay, TouchHandler.TRIGGER_UP))

	pos = {
		ControlBarDisplay.POSITION.BUTTON_OFFSET[1] * 2 + ControlBarDisplay.SIZE.BUTTON_SIZE[1] - 1,
		ControlBarDisplay.POSITION.BUTTON_OFFSET[2]
	}
	frame = self:createFrame(pos, ControlBarDisplay.SIZE.BUTTON_SIZE, ControlBarDisplay.COLOR.BUTTON_BACKGROUND, false)

	table.insert(self.hudElements, frame)
	table.insert(self.switchElements, frame)

	pos[2] = pos[2] + ControlBarDisplay.POSITION.SWITCH_ARROW_OFFSET[2] + (ControlBarDisplay.SIZE.BUTTON_SIZE[2] - ControlBarDisplay.SIZE.SWITCH_ARROW[2]) / 2
	pos[1] = pos[1] + ControlBarDisplay.POSITION.SWITCH_ARROW_OFFSET[1] + (ControlBarDisplay.SIZE.BUTTON_SIZE[1] - ControlBarDisplay.SIZE.SWITCH_ARROW[1]) / 2
	local swRightOverlay = self:createOverlayElement(pos, ControlBarDisplay.SIZE.SWITCH_ARROW, ControlBarDisplay.UV.VEHICLE_RIGHT, ControlBarDisplay.COLOR.BUTTON)
	local swRightElement = HUDElement.new(swRightOverlay)

	table.insert(self.hudElements, swRightElement)
	table.insert(self.switchElements, swRightElement)

	touchOffsetX = {
		touchOffsetX[2],
		touchOffsetX[1]
	}

	table.insert(self.buttons, self.hud:addTouchButton(swRightOverlay, touchOffsetX, 0.5, self.onSwitchRight, self, TouchHandler.TRIGGER_UP))
	table.insert(self.buttons, self.hud:addTouchButton(swRightOverlay, touchOffsetX, 0.5, self.pressButtonCallback, swRightOverlay, TouchHandler.TRIGGER_DOWN))
	table.insert(self.buttons, self.hud:addTouchButton(swRightOverlay, touchOffsetX, 0.5, self.releaseButtonCallback, swRightOverlay, TouchHandler.TRIGGER_UP))

	local posX = ControlBarDisplay.POSITION.BUTTON_OFFSET[1] * 2 + ControlBarDisplay.SIZE.BUTTON_SIZE[1] * 0.5 + (ControlBarDisplay.SIZE.BUTTON_SIZE[1] - ControlBarDisplay.SIZE.SWITCH_ICON[1]) / 2
	local posY = ControlBarDisplay.POSITION.BUTTON_OFFSET[2] + (ControlBarDisplay.SIZE.BUTTON_SIZE[2] - ControlBarDisplay.SIZE.SWITCH_ICON[2]) / 2
	local swIcBackgroundOverlay = self:createOverlayElement({
		posX + ControlBarDisplay.POSITION.SWITCH_ICON_OFFSET[1] + (ControlBarDisplay.SIZE.SWITCH_ICON[1] - ControlBarDisplay.SIZE.SWITCH_ICON_BACKGROUND[1]) / 2,
		posY + ControlBarDisplay.POSITION.SWITCH_ICON_OFFSET[2] + (ControlBarDisplay.SIZE.SWITCH_ICON[2] - ControlBarDisplay.SIZE.SWITCH_ICON_BACKGROUND[2]) / 2
	}, ControlBarDisplay.SIZE.SWITCH_ICON_BACKGROUND, HUDElement.UV.FILL, ControlBarDisplay.COLOR.BUTTON_BACKGROUND)
	local swIcBackgroundElement = HUDElement.new(swIcBackgroundOverlay)

	table.insert(self.hudElements, swIcBackgroundElement)
	table.insert(self.switchElements, swIcBackgroundElement)

	local swIcOverlay = self:createOverlayElement({
		posX + ControlBarDisplay.POSITION.SWITCH_ICON_OFFSET[1],
		posY + ControlBarDisplay.POSITION.SWITCH_ICON_OFFSET[2]
	}, ControlBarDisplay.SIZE.SWITCH_ICON, ControlBarDisplay.UV.SWITCH_ICON, ControlBarDisplay.COLOR.SWITCH_ICON)
	local swIcElement = HUDElement.new(swIcOverlay)

	table.insert(self.hudElements, swIcElement)
	table.insert(self.switchElements, swIcElement)

	self.gamepadOffset = {
		getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.GAMEPAD_OFFSET))
	}
	self.aiOffset = {
		getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.AI_OFFSET))
	}

	self:updateHudElements()
end

function ControlBarDisplay:createOverlayElement(pos, size, uvs, color)
	local baseX, baseY = self:getPosition()
	local posX, posY = getNormalizedScreenValues(unpack(pos))
	local sizeX, sizeY = getNormalizedScreenValues(unpack(size))
	local overlay = Overlay.new(self.hudAtlasPath, baseX + posX, baseY + posY, sizeX, sizeY)

	overlay:setUVs(GuiUtils.getUVs(uvs))
	overlay:setColor(unpack(color))

	return overlay
end

function ControlBarDisplay:createFrame(pos, size, backgroundColor, showBar, showSideLines)
	local baseX, baseY = self:getPosition()
	local posX, posY = getNormalizedScreenValues(unpack(pos))
	local sizeX, sizeY = getNormalizedScreenValues(unpack(size))
	local frame = HUDFrameElement.new(self.hudAtlasPath, baseX + posX, baseY + posY, sizeX, sizeY, nil, showBar, 2)

	frame:setColor(unpack(backgroundColor))
	frame:setFrameColor(unpack(ControlBarDisplay.COLOR.FRAME))

	if showSideLines == false then
		frame:setLeftLineVisible(false)
		frame:setRightLineVisible(false)
	end

	return frame
end

function ControlBarDisplay:createOverlayArea(pos, size)
	local baseX, baseY = self:getPosition()
	local posX, posY = getNormalizedScreenValues(unpack(pos))
	local sizeX, sizeY = getNormalizedScreenValues(unpack(size))
	local backgroundOverlay = Overlay.new(self.hudAtlasPath, baseX + posX, baseY + posY, sizeX, sizeY)

	backgroundOverlay:setColor(0, 0, 0, 0)

	return HUDElement.new(backgroundOverlay)
end

function ControlBarDisplay:getScaledPosAndSize(pos, size, scale)
	pos = {
		unpack(pos)
	}
	size = {
		unpack(size)
	}
	local posOffsetX = size[1] * (1 - scale) / 2
	local posOffsetY = size[2] * (1 - scale) / 2
	pos[2] = pos[2] + posOffsetY
	pos[1] = pos[1] + posOffsetX
	size[2] = size[2] * scale
	size[1] = size[1] * scale

	return pos, size, posOffsetX, posOffsetY
end

function ControlBarDisplay:addControlButton(allowedFunc, callback, callbackTarget, triggerType, uvs, prio, inputAction)
	local controlButton = {}
	local pos, size, posOffsetX, _ = self:getScaledPosAndSize(ControlBarDisplay.POSITION.CONTROL_BUTTON_OFFSET, ControlBarDisplay.SIZE.BUTTON_SIZE, 0.8)
	local overlay = self:createOverlayElement(pos, size, uvs, ControlBarDisplay.COLOR.BUTTON)
	local icon = HUDElement.new(overlay)
	icon.overlayOffsetX = posOffsetX
	local frame = self:createFrame(ControlBarDisplay.POSITION.CONTROL_BUTTON_OFFSET, ControlBarDisplay.SIZE.BUTTON_SIZE, ControlBarDisplay.COLOR.BUTTON_BACKGROUND, false)
	controlButton.elements = {}

	table.insert(controlButton.elements, frame)
	table.insert(controlButton.elements, icon)

	local glyphElement, offsetX = nil

	if inputAction ~= nil then
		glyphElement, offsetX = self:createInputGlyph(ControlBarDisplay.POSITION.CONTROL_BUTTON_OFFSET, ControlBarDisplay.SIZE.BUTTON_SIZE, inputAction)

		table.insert(controlButton.elements, glyphElement)

		glyphElement.overlayOffsetXScreenSpace = offsetX
		controlButton.glyphElement = glyphElement
	end

	local function buttonCallback()
		if allowedFunc ~= nil then
			local allowed, warning = allowedFunc(callbackTarget)

			if not allowed then
				g_currentMission:showBlinkingWarning(warning, 2500)

				return
			end
		end

		callback(callbackTarget)
	end

	controlButton.frame = frame
	controlButton.overlay = overlay
	controlButton.buttons = {
		self.hud:addTouchButton(overlay, 0.2, 0.2, buttonCallback, callbackTarget, triggerType),
		self.hud:addTouchButton(overlay, 0.2, 0.2, self.pressButtonCallback, icon, TouchHandler.TRIGGER_DOWN),
		self.hud:addTouchButton(overlay, 0.2, 0.2, self.releaseButtonCallback, icon, TouchHandler.TRIGGER_UP)
	}
	controlButton.prio = prio
	controlButton.visible = true

	for _, element in ipairs(controlButton.elements) do
		table.insert(self.hudElements, element)
	end

	table.insert(self.controlButtons, controlButton)
	self:updateControlButtons()
	self:updateHudElements()

	return controlButton
end

function ControlBarDisplay:createInputGlyph(position, size, inputAction)
	local _, baseY = self:getPosition()
	local _, posY = unpack(position)
	local _, sPosY = getNormalizedScreenValues(0, posY + 2)
	local sizeX, sizeY = unpack(size)
	local sSizeX, sSizeY = getNormalizedScreenValues(sizeX, sizeY - 4)
	local glyphWidth, glyphHeight = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.INPUT_GLYPH))
	local glyphElement = InputGlyphElement.new(g_inputDisplayManager, glyphWidth, glyphHeight)

	glyphElement:setAction(inputAction)
	glyphElement:setButtonGlyphColor(GameInfoDisplayMobile.COLOR.INPUT_GLYPH)

	local actualWidth = glyphElement:getGlyphWidth()

	glyphElement:setPosition(0, baseY + sPosY + sSizeY - glyphHeight)
	table.insert(self.inputGlyphs, glyphElement)

	if self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD then
		glyphElement:setVisible(true)
	end

	return glyphElement, sSizeX - actualWidth
end

function ControlBarDisplay:addFillLevelDisplaysFromVehicles(vehicles)
	for i = #self.fillTypeDisplays, 1, -1 do
		self:removeFillLevelDisplay(self.fillTypeDisplays[i])
	end

	for _, subVehicle in ipairs(vehicles) do
		if subVehicle.getFillUnits ~= nil then
			for i, fillUnit in ipairs(subVehicle:getFillUnits()) do
				if fillUnit.showOnHud then
					self:addFillLevelDisplay(subVehicle, i)
				end
			end
		end
	end
end

function ControlBarDisplay:addFillLevelDisplay(vehicle, fillUnitIndex)
	local fillLevelDisplay = {}
	local posX, posY = unpack(ControlBarDisplay.POSITION.CONTROL_BUTTON_OFFSET)
	local sizeX, sizeY = unpack(ControlBarDisplay.SIZE.BUTTON_SIZE)
	local xOffset = (ControlBarDisplay.SIZE.BUTTON_SIZE[1] - ControlBarDisplay.SIZE.FILL_LEVEL_BAR[1]) / 2 + ControlBarDisplay.POSITION.FILL_LEVEL_BAR[1] + 1
	local position = {
		posX + xOffset,
		posY + ControlBarDisplay.POSITION.FILL_LEVEL_BAR[2]
	}
	local fillLevelBarBackgroundOverlay = self:createOverlayElement(position, ControlBarDisplay.SIZE.FILL_LEVEL_BAR, ControlBarDisplay.UV.FILL_LEVEL_BAR, ControlBarDisplay.COLOR.FILL_LEVEL_BAR_BACKGROUND)
	local fillLevelBarBackground = HUDElement.new(fillLevelBarBackgroundOverlay)
	fillLevelBarBackground.overlayOffsetX = xOffset
	fillLevelBarBackground.currentUVs = GuiUtils.getUVs(ControlBarDisplay.UV.FILL_LEVEL_BAR)
	fillLevelBarBackground.defaultPosOffset = {
		getNormalizedScreenValues(xOffset, ControlBarDisplay.POSITION.FILL_LEVEL_BAR[2])
	}
	fillLevelBarBackground.defaultPos = {
		getNormalizedScreenValues(posX, posY)
	}
	fillLevelBarBackground.defaultSize = {
		getNormalizedScreenValues(unpack(ControlBarDisplay.SIZE.FILL_LEVEL_BAR))
	}
	local fillLevelBarOverlay = self:createOverlayElement(position, ControlBarDisplay.SIZE.FILL_LEVEL_BAR, ControlBarDisplay.UV.FILL_LEVEL_BAR, ControlBarDisplay.COLOR.FILL_LEVEL_BAR)
	local fillLevelBar = HUDElement.new(fillLevelBarOverlay)
	fillLevelBar.overlayOffsetX = xOffset
	fillLevelDisplay.normUVs = GuiUtils.getUVs(ControlBarDisplay.UV.FILL_LEVEL_BAR)
	fillLevelDisplay.currentUVs = GuiUtils.getUVs(ControlBarDisplay.UV.FILL_LEVEL_BAR)
	local barOffset = ControlBarDisplay.SIZE.FILL_LEVEL_BAR[2] + ControlBarDisplay.POSITION.FILL_LEVEL_BAR[2]
	local offsetPos = {
		ControlBarDisplay.POSITION.CONTROL_BUTTON_OFFSET[1] + barOffset,
		ControlBarDisplay.POSITION.CONTROL_BUTTON_OFFSET[2] + barOffset
	}
	local pos, size, posOffsetX, _ = self:getScaledPosAndSize(offsetPos, {
		ControlBarDisplay.SIZE.BUTTON_SIZE[1] - barOffset / 2,
		ControlBarDisplay.SIZE.BUTTON_SIZE[2] - barOffset - 2
	}, 0.7)
	local iconOverlay = self:createOverlayElement(pos, size, HUDElement.UV.FILL, ControlBarDisplay.COLOR.BUTTON)
	local icon = HUDElement.new(iconOverlay)
	icon.overlayOffsetX = posOffsetX + (barOffset + 2) / 4
	local frame = self:createFrame(ControlBarDisplay.POSITION.CONTROL_BUTTON_OFFSET, ControlBarDisplay.SIZE.BUTTON_SIZE, ControlBarDisplay.COLOR.BUTTON_BACKGROUND, false)
	fillLevelDisplay.elements = {}

	table.insert(fillLevelDisplay.elements, frame)
	table.insert(fillLevelDisplay.elements, fillLevelBarBackground)
	table.insert(fillLevelDisplay.elements, fillLevelBar)
	table.insert(fillLevelDisplay.elements, icon)

	fillLevelDisplay.isSowingMachine = false

	if vehicle.getSowingMachineFillUnitIndex ~= nil and vehicle:getSowingMachineFillUnitIndex() == fillUnitIndex then
		fillLevelDisplay.isSowingMachine = true
	end

	local function buttonCallbackDown(display, x, y)
		icon:setColor(unpack(ControlBarDisplay.COLOR.BUTTON_ACTIVE))
	end

	local function buttonCallbackUp(display, x, y)
		icon:setColor(unpack(ControlBarDisplay.COLOR.BUTTON))
	end

	local inputAction = nil

	if fillLevelDisplay.isSowingMachine then
		function buttonCallbackUp(display, x, y)
			if not display.vehicle:getIsAIActive() then
				display.vehicle:changeSeedIndex()
			end

			icon:setColor(unpack(ControlBarDisplay.COLOR.BUTTON))
		end

		inputAction = InputAction.TOGGLE_SEEDS
	end

	if inputAction ~= nil then
		local offsetX = nil
		fillLevelDisplay.glyphElement, offsetX = self:createInputGlyph({
			0,
			0
		}, ControlBarDisplay.SIZE.BUTTON_SIZE, inputAction)

		table.insert(fillLevelDisplay.elements, fillLevelDisplay.glyphElement)

		fillLevelDisplay.glyphElement.overlayOffsetXScreenSpace = offsetX
	end

	fillLevelDisplay.fillLevelBar = fillLevelBarOverlay
	fillLevelDisplay.fillLevelBarBackground = fillLevelBarBackground
	fillLevelDisplay.frame = frame
	fillLevelDisplay.icon = icon
	fillLevelDisplay.buttons = {
		self.hud:addTouchButton(frame.overlay, 0, 0, buttonCallbackDown, fillLevelDisplay, TouchHandler.TRIGGER_DOWN),
		self.hud:addTouchButton(frame.overlay, 0, 0, buttonCallbackUp, fillLevelDisplay, TouchHandler.TRIGGER_UP)
	}
	fillLevelDisplay.prio = fillLevelDisplay.isSowingMachine and 1 or 2
	fillLevelDisplay.vehicle = vehicle
	fillLevelDisplay.fillUnitIndex = fillUnitIndex

	function fillLevelDisplay.visibleFunc(display)
		if fillLevelDisplay.isSowingMachine then
			return true
		end

		if display.vehicle:getFillUnitExists(display.fillUnitIndex) then
			return display.vehicle:getFillUnitFillLevelPercentage(display.fillUnitIndex) > 0
		end

		return false
	end

	fillLevelDisplay.visible = true
	fillLevelDisplay.lastFillLevel = 0
	fillLevelDisplay.lastFillLevelPct = 0

	for _, element in ipairs(fillLevelDisplay.elements) do
		table.insert(self.hudElements, element)
	end

	table.insert(self.controlButtons, fillLevelDisplay)
	table.insert(self.fillTypeDisplays, fillLevelDisplay)
	self:updateControlButtons()
	self:updateHudElements()

	return fillLevelDisplay
end

function ControlBarDisplay:updateControlButtons()
	local baseX, _ = self:getPosition()
	local buttonsByPrio = {}

	for _, controlButton in pairs(self.controlButtons) do
		local visible = true

		if controlButton.visibleFunc ~= nil then
			visible = controlButton:visibleFunc()
		end

		if visible then
			table.insert(buttonsByPrio, controlButton)
		end

		self:setButtonVisibility(controlButton, visible)
	end

	table.sort(buttonsByPrio, function (a, b)
		return a.prio < b.prio
	end)

	for index, controlButton in ipairs(buttonsByPrio) do
		local posX = ControlBarDisplay.POSITION.CONTROL_BUTTON_OFFSET[1] + ControlBarDisplay.SIZE.BUTTON_SIZE[1] * (index - 1)

		if index > 1 then
			posX = posX - 1
		end

		posX, _ = getNormalizedScreenValues(posX, 0)

		for _, element in ipairs(controlButton.elements) do
			local offset, _ = getNormalizedScreenValues(element.overlayOffsetX or 0, 0)
			offset = offset + (element.overlayOffsetXScreenSpace or 0)

			element:setPosition(baseX + posX + offset)
		end

		if controlButton.frame ~= nil then
			local width = ControlBarDisplay.SIZE.BUTTON_SIZE[1]

			if index == 1 then
				width = width - HUDFrameElement.THICKNESS.FRAME
			end

			width, _ = getNormalizedScreenValues(width, 0)

			controlButton.frame:setDimension(width)
			controlButton.frame:setRightLineVisible(index == #buttonsByPrio)
		end
	end
end

function ControlBarDisplay:setButtonVisibility(controlButton, visible)
	for _, element in ipairs(controlButton.elements) do
		element:setVisible(visible)
	end

	if controlButton.buttons ~= nil then
		for _, button in pairs(controlButton.buttons) do
			if visible then
				self.hud:showTouchButton(button)
			else
				self.hud:hideTouchButton(button)
			end
		end
	end

	if controlButton.glyphElement ~= nil and visible and self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD then
		controlButton.glyphElement:setVisible(false)
	end

	controlButton.visible = visible
end

function ControlBarDisplay:updateFillTypeDisplay(fillLevelDisplay, dt, index)
	local fillLevel = 0
	local fillLevelPct = 0
	local fillTypeIcon = ""

	if fillLevelDisplay.vehicle:getFillUnitExists(fillLevelDisplay.fillUnitIndex) then
		fillLevel = fillLevelDisplay.vehicle:getFillUnitFillLevel(fillLevelDisplay.fillUnitIndex)
		fillLevelPct = fillLevelDisplay.vehicle:getFillUnitFillLevelPercentage(fillLevelDisplay.fillUnitIndex)

		if fillLevelDisplay.isSowingMachine then
			fillTypeIcon = fillLevelDisplay.vehicle:getCurrentSeedTypeIcon()
		else
			local fillTypeIndex = fillLevelDisplay.vehicle:getFillUnitFillType(fillLevelDisplay.fillUnitIndex)

			if fillTypeIndex ~= nil then
				local fillUnit = fillLevelDisplay.vehicle:getFillUnitByIndex(fillLevelDisplay.fillUnitIndex)

				if fillUnit.fillTypeToDisplay ~= FillType.UNKNOWN then
					fillTypeIndex = fillUnit.fillTypeToDisplay
				end

				local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
				fillTypeIcon = fillType.hudOverlayFilename
			end
		end

		if fillLevelPct > 0 and not fillLevelDisplay.visible or fillLevelPct <= 0 and fillLevelDisplay.visible then
			self:updateControlButtons()
		end
	end

	fillLevelDisplay.currentUVs[5] = (fillLevelDisplay.normUVs[5] - fillLevelDisplay.normUVs[1]) * fillLevelPct + fillLevelDisplay.normUVs[1]
	fillLevelDisplay.currentUVs[7] = (fillLevelDisplay.normUVs[7] - fillLevelDisplay.normUVs[3]) * fillLevelPct + fillLevelDisplay.normUVs[3]

	fillLevelDisplay.fillLevelBar:setUVs(fillLevelDisplay.currentUVs)
	fillLevelDisplay.fillLevelBar:setScale(fillLevelPct, 1)

	local fillLevelBarBackground = fillLevelDisplay.fillLevelBarBackground
	fillLevelBarBackground.currentUVs[1] = (fillLevelDisplay.normUVs[5] - fillLevelDisplay.normUVs[1]) * fillLevelPct + fillLevelDisplay.normUVs[1]
	fillLevelBarBackground.currentUVs[3] = (fillLevelDisplay.normUVs[7] - fillLevelDisplay.normUVs[3]) * fillLevelPct + fillLevelDisplay.normUVs[3]

	fillLevelBarBackground:setUVs(fillLevelBarBackground.currentUVs)

	local baseX, _ = self:getPosition()
	local offsetX = ControlBarDisplay.SIZE.BUTTON_SIZE[1] * (index - 1) - (index > 1 and 1 or 0)
	offsetX, _ = getNormalizedScreenValues(offsetX, 0)

	fillLevelBarBackground:setPosition(baseX + offsetX + fillLevelBarBackground.defaultPos[1] + fillLevelBarBackground.defaultPosOffset[1] + fillLevelBarBackground.defaultSize[1] * fillLevelPct)
	fillLevelBarBackground:setScale(1 - fillLevelPct, 1)

	if fillTypeIcon ~= "" and fillLevelDisplay.icon.overlay ~= nil then
		fillLevelDisplay.icon:setImage(fillTypeIcon)
	end

	fillLevelDisplay.lastFillLevel = fillLevel
	fillLevelDisplay.lastFillLevelPct = fillLevelPct
end

function ControlBarDisplay:setControlButtonDirection(controlButton, vehicleControl, direction)
	if vehicleControl.uvs_pos ~= nil and vehicleControl.uvs_neg ~= nil then
		local uvs = direction == 1 and vehicleControl.uvs_pos or vehicleControl.uvs_neg

		controlButton.overlay:setUVs(GuiUtils.getUVs(uvs))
	end

	if vehicleControl.iconColor_pos ~= nil and vehicleControl.iconColor_neg ~= nil then
		local color = direction == 1 and vehicleControl.iconColor_pos or vehicleControl.iconColor_neg

		controlButton.overlay:setColor(unpack(color))
	end

	if vehicleControl.bottomBarSize_pos ~= nil and vehicleControl.bottomBarSize_neg ~= nil then
		local size = direction == 1 and vehicleControl.bottomBarSize_pos or vehicleControl.bottomBarSize_neg
		local _, barHeight = getNormalizedScreenValues(0, size[2])

		controlButton.frame:setBottomBarHeight(barHeight)
	end

	if vehicleControl.bottomBarColor_pos ~= nil and vehicleControl.bottomBarColor_neg ~= nil then
		local color = direction == 1 and vehicleControl.bottomBarColor_pos or vehicleControl.bottomBarColor_neg

		controlButton.frame:setBottomBarColor(unpack(color))
	end
end

function ControlBarDisplay:setControlButtonIcon(controlButton, vehicleControl, iconFilename)
	if controlButton.overlay ~= nil then
		controlButton.overlay:setImage(iconFilename)
	end
end

function ControlBarDisplay:removeControlButton(controlButton)
	for _, element in ipairs(controlButton.elements) do
		if element.overlay ~= nil and not element:isa(InputGlyphElement) then
			element.overlay:delete()
		end

		self:removeChild(element)
	end

	for _, button in pairs(controlButton.buttons) do
		self.hud:removeTouchButton(button)
	end

	for _, element in ipairs(controlButton.elements) do
		table.removeElement(self.hudElements, element)
	end

	table.removeElement(self.controlButtons, controlButton)

	if controlButton.glyphElement ~= nil then
		table.removeElement(self.inputGlyphs, controlButton.glyphElement)
	end

	self:updateControlButtons()
end

function ControlBarDisplay:removeFillLevelDisplay(fillLevelDisplay)
	table.removeElement(self.fillTypeDisplays, fillLevelDisplay)
	self:removeControlButton(fillLevelDisplay)

	if fillLevelDisplay.glyphElement ~= nil then
		table.removeElement(self.inputGlyphs, fillLevelDisplay.glyphElement)
	end
end

function ControlBarDisplay:updateHudElements()
	for _, element in ipairs(self.hudElements) do
		if element.parent ~= self then
			self:addChild(element)
		end
	end
end

function ControlBarDisplay:onSwitchLeft(x, y, isCancel)
	if not isCancel then
		g_currentMission:toggleVehicle(-1)
	end
end

function ControlBarDisplay:onSwitchRight(x, y, isCancel)
	if not isCancel then
		g_currentMission:toggleVehicle(1)
	end
end

function ControlBarDisplay:updatePositionState(force)
	if self.player ~= nil and self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD then
		return self:setPositionState(ControlBarDisplay.STATE_TOUCH, force)
	end

	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD or self.vehicle ~= nil and self.vehicle:getIsAIActive() or self.lastGyroscopeSteeringState then
		self:setPositionState(ControlBarDisplay.STATE_CONTROLLER, force)

		return
	end

	self:setPositionState(ControlBarDisplay.STATE_TOUCH, force)
end

function ControlBarDisplay:onInputHelpModeChange(inputHelpMode, force)
	self.lastInputHelpMode = inputHelpMode
	local showGlyphs = inputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD

	for _, glyph in ipairs(self.inputGlyphs) do
		glyph:setVisible(showGlyphs)
	end

	self:updatePositionState(force)
end

function ControlBarDisplay:onAIVehicleStateChanged(state, vehicle, force)
	self.lastAIState = state

	self:updatePositionState(force)
end

function ControlBarDisplay:onGyroscopeSteeringChanged(state)
	self.lastGyroscopeSteeringState = state

	self:updatePositionState()
end

function ControlBarDisplay:setPositionState(state, force)
	if state ~= self.lastPositionState then
		local startX, startY = self:getPosition()
		local targetX = self.origX
		local targetY = self.origY
		local startAlpha = 1
		local endAlpha = 1
		local speed = ControlBarDisplay.MOVE_ANIMATION_DURATION / 5

		if state == ControlBarDisplay.STATE_TOUCH or state == ControlBarDisplay.STATE_AI_TOUCH then
			if self.lastPositionState == ControlBarDisplay.STATE_CONTROLLER then
				endAlpha = 1
				startAlpha = 0
			end
		elseif state == ControlBarDisplay.STATE_CONTROLLER then
			targetX, targetY = unpack(self.gamepadOffset)
			targetY = self.origY + targetY
			targetX = self.origX + targetX
			endAlpha = 0
			startAlpha = 1
			speed = ControlBarDisplay.MOVE_ANIMATION_DURATION
		end

		if force then
			speed = 0.01
		end

		local sequence = TweenSequence.new(self)

		sequence:insertTween(MultiValueTween:new(self.setSwitchIconsAlpha, {
			startAlpha
		}, {
			endAlpha
		}, speed / 2), 0)
		sequence:insertTween(MultiValueTween:new(self.setPosition, {
			startX,
			startY
		}, {
			targetX,
			targetY
		}, speed), 0)
		sequence:start()

		self.animation = sequence
		self.lastPositionState = state
	end
end

function ControlBarDisplay:setSwitchIconsAlpha(alphaValue)
	for _, element in ipairs(self.switchElements) do
		element:setColor(nil, , , alphaValue)

		if element.setFrameColor ~= nil then
			element:setFrameColor(nil, , , alphaValue)
		end
	end
end

function ControlBarDisplay:update(dt)
	ControlBarDisplay:superClass().update(self, dt)

	local vehicle = self.vehicle

	if vehicle ~= nil then
		for name, vehicleControl in pairs(self.vehicleControls) do
			local updated = false
			local _, isAvailable = self:updateVehicleControl(vehicle, vehicleControl, name)

			if not isAvailable then
				if vehicleControl.useAttachables and vehicle.getAttachedImplements ~= nil then
					for _, implement in ipairs(vehicle:getAttachedImplements()) do
						local hasAvailable, isAvailable = self:updateVehicleControl(implement.object, vehicleControl, name)

						if hasAvailable and isAvailable then
							updated = true

							break
						end
					end
				end
			else
				updated = true
			end

			if not updated and vehicleControl.controlButton ~= nil then
				self:removeControlButton(vehicleControl.controlButton)

				vehicleControl.controlButton = nil
				vehicleControl.lastCustomIcon = nil
				vehicleControl.lastDirection = nil
			end
		end

		if vehicle.getChildVehicles ~= nil then
			local vehicles = vehicle:getChildVehicles()

			if #vehicles ~= self.numVehicles then
				self.numVehicles = #vehicles

				self:addFillLevelDisplaysFromVehicles(vehicles)
			end
		end

		local displayIndex = 1

		for i = 1, #self.fillTypeDisplays do
			self:updateFillTypeDisplay(self.fillTypeDisplays[i], dt, displayIndex)

			if self.fillTypeDisplays[i].visible then
				displayIndex = displayIndex + 1
			end
		end
	end

	if self.player ~= nil then
		for name, playerControl in pairs(self.playerControls) do
			self:updateVehicleControl(self.player, playerControl, name)
		end
	end

	if vehicle ~= nil and not g_gui:getIsGuiVisible() then
		local show = Utils.getNoNil(Input.isKeyPressed(Input.KEY_lctrl), false)

		g_inputBinding:setShowMouseCursor(show, false)
	end
end

function ControlBarDisplay:updateVehicleControl(vehicle, vehicleControl, name)
	local availableFunc = vehicle[vehicleControl.availableFunc]

	if availableFunc ~= nil then
		if availableFunc(vehicle) then
			if vehicleControl.controlButton == nil then
				local allowedFunc = vehicle[vehicleControl.allowedFunc]
				local actionFunc = vehicle[vehicleControl.actionFunc]
				vehicleControl.controlButton = self:addControlButton(allowedFunc, actionFunc, vehicle, vehicleControl.triggerType, vehicleControl.uvs or vehicleControl.uvs_pos, vehicleControl.prio, vehicleControl.inputAction)
				vehicleControl.lastDirection = nil
			end
		elseif vehicleControl.controlButton ~= nil then
			self:removeControlButton(vehicleControl.controlButton)

			vehicleControl.controlButton = nil
			vehicleControl.lastCustomIcon = nil
			vehicleControl.lastDirection = nil
		end

		if vehicleControl.controlButton ~= nil then
			if vehicleControl.directionFunc ~= nil then
				local directionFunc = vehicle[vehicleControl.directionFunc]

				if directionFunc ~= nil then
					local direction = directionFunc(vehicle)

					if type(direction) == "boolean" then
						if direction then
							direction = 1
						else
							direction = -1
						end
					end

					if direction ~= vehicleControl.lastDirection then
						self:setControlButtonDirection(vehicleControl.controlButton, vehicleControl, direction)

						vehicleControl.lastDirection = direction
					end
				end
			end

			if vehicleControl.customIconFunc ~= nil then
				local customIconFunc = vehicle[vehicleControl.customIconFunc]

				if customIconFunc ~= nil then
					local customIcon = customIconFunc(vehicle)

					if customIcon ~= vehicleControl.lastCustomIcon and customIcon ~= nil then
						self:setControlButtonIcon(vehicleControl.controlButton, vehicleControl, customIcon)

						vehicleControl.lastCustomIcon = customIcon
					end
				end
			end
		end

		return true, vehicleControl.controlButton ~= nil
	end

	return false, false
end

function ControlBarDisplay:setScale(uiScale)
	ControlBarDisplay:superClass().setScale(self, uiScale, uiScale)

	local currentVisibility = self:getVisible()

	self:setVisible(true, false)

	self.uiScale = uiScale
	local posX, posY = ControlBarDisplay.getBackgroundPosition(uiScale, self:getWidth())

	self:setPosition(posX, posY)
	self:storeOriginalPosition()
	self:setVisible(currentVisibility, false)
end

function ControlBarDisplay.getBackgroundPosition(scale, width)
	local offX, offY = getNormalizedScreenValues(unpack(ControlBarDisplay.POSITION.BACKGROUND))

	return g_safeFrameOffsetX + offX * scale, g_safeFrameOffsetY - offY * scale
end

function ControlBarDisplay.createBackground()
	local width, height = getNormalizedScreenValues(unpack(ControlBarDisplay.SIZE.BACKGROUND))
	local posX, posY = ControlBarDisplay.getBackgroundPosition(1, width)

	return Overlay.new(nil, posX, posY, width, height)
end

ControlBarDisplay.SIZE = {
	BACKGROUND = {
		500,
		110
	},
	SWITCH_ICON = {
		96,
		96
	},
	SWITCH_ICON_BACKGROUND = {
		96,
		76
	},
	SWITCH_ARROW = {
		76,
		76
	},
	BUTTON_SIZE = {
		115,
		120
	},
	BOTTOM_BAR = {
		0,
		1
	},
	BOTTOM_BAR_ACTIVE = {
		0,
		4
	},
	FILL_LEVEL_INFO_CENTER = {
		20,
		45
	},
	FILL_LEVEL_INFO_EDGE = {
		48,
		48
	},
	FILL_LEVEL_INFO_ARROW = {
		24,
		24
	},
	FILL_LEVEL_INFO_TEXT = {
		0,
		35
	},
	FILL_LEVEL_BAR = {
		100,
		11
	}
}
ControlBarDisplay.POSITION = {
	BACKGROUND = {
		500,
		0
	},
	GAMEPAD_OFFSET = {
		-770,
		0
	},
	AI_OFFSET = {
		-500,
		0
	},
	SWITCH_ICON = {
		0,
		0
	},
	SWITCH_ICON_OFFSET = {
		0,
		0
	},
	SWITCH_ARROW_OFFSET = {
		12,
		0
	},
	BUTTON_OFFSET = {
		0,
		0
	},
	CONTROL_BUTTON_OFFSET = {
		270,
		0
	},
	FILL_LEVEL_INFO_OFFSET = {
		0,
		20
	},
	FILL_LEVEL_INFO_EDGE = {
		0,
		-3
	},
	FILL_LEVEL_INFO_TEXT_OFFSET = {
		0,
		4
	},
	FILL_LEVEL_BAR = {
		0,
		10
	}
}
ControlBarDisplay.COLOR = {
	SWITCH_ICON_BACKGROUND = {
		0.03137,
		0.03137,
		0.03137,
		0.9
	},
	SWITCH_ICON = {
		1,
		1,
		1,
		1
	},
	BUTTON = {
		1,
		1,
		1,
		1
	},
	BUTTON_BACKGROUND = {
		0.015686,
		0.015686,
		0.015686,
		1
	},
	BUTTON_ACTIVE = {
		0.991,
		0.3865,
		0.01,
		1
	},
	BOTTOM_BAR = {
		1,
		1,
		1,
		0.3
	},
	BOTTOM_BAR_ACTIVE = {
		1,
		1,
		1,
		1
	},
	FILL_LEVEL_BAR = {
		0.991,
		0.3865,
		0.01,
		1
	},
	FILL_LEVEL_INFO = {
		0.01568,
		0.01568,
		0.01568,
		1
	},
	FILL_LEVEL_BAR_BACKGROUND = {
		0.172549,
		0.172549,
		0.172549,
		1
	},
	FRAME = {
		0.098039,
		0.098039,
		0.098039,
		1
	}
}
ControlBarDisplay.UV = {
	DETACH = {
		864,
		48,
		96,
		96
	},
	TURN_ON = {
		768,
		48,
		96,
		96
	},
	AI = {
		672,
		48,
		96,
		96
	},
	LEAVE_VEHICLE = {
		466,
		672,
		96,
		96
	},
	ENTER_VEHICLE = {
		864,
		336,
		96,
		96
	},
	ENTER_HORSE = {
		371,
		672,
		96,
		96
	},
	SWITCH_ICON = {
		864,
		144,
		96,
		96
	},
	VEHICLE_LEFT = {
		768,
		144,
		96,
		96
	},
	VEHICLE_RIGHT = {
		864,
		144,
		-96,
		96
	},
	FILL_LEVEL_INFO_EDGE_LEFT = {
		288,
		576,
		-48,
		48
	},
	FILL_LEVEL_INFO_EDGE_RIGHT = {
		240,
		576,
		48,
		48
	},
	FILL_LEVEL_INFO_BOTTOM = {
		288,
		576,
		24,
		24
	},
	FILL_LEVEL_BAR = {
		485,
		5,
		100,
		11
	}
}
