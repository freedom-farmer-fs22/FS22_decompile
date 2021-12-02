GameInfoDisplayMobile = {}
local GameInfoDisplayMobile_mt = Class(GameInfoDisplayMobile, HUDDisplayElement)
GameInfoDisplayMobile.HIDE_TIME = 500

function GameInfoDisplayMobile.new(hud, hudAtlasPath, moneyUnit, l10n)
	local backgroundOverlay = GameInfoDisplayMobile.createBackground()
	local self = GameInfoDisplayMobile:superClass().new(backgroundOverlay, nil, GameInfoDisplayMobile_mt)
	self.hud = hud
	self.uiScale = 1
	self.hudAtlasPath = hudAtlasPath
	self.moneyUnit = moneyUnit
	self.l10n = l10n
	self.vehicle = nil
	self.isRideable = false
	self.elements = {}
	self.infoElements = {}
	self.inputGlyphs = {}
	self.backgroundHudElement = self:createHUDElement(GameInfoDisplayMobile.POSITION.CENTER_BACKGROUND, GameInfoDisplayMobile.SIZE.CENTER_BACKGROUND, GameInfoDisplayMobile.UV.BACKGROUND)

	table.insert(self.elements, self.backgroundHudElement)
	self:createSeparators()
	self:createBorders()

	if g_isPresentationVersion then
		self:createButtonElement(self.onOpenMenu, GameInfoDisplayMobile.POSITION.MAP_ICON, GameInfoDisplayMobile.SIZE.MAP_ICON, GameInfoDisplayMobile.SIZE.BUTTON_ICON, GameInfoDisplayMobile.UV.MENU, GameInfoDisplayMobile.COLOR.BUTTON, GameInfoDisplayMobile.COLOR.BUTTON_BACKGROUND, GameInfoDisplayMobile.COLOR.BUTTON_SELECTED, InputAction.MENU)
	else
		self:createButtonElement(self.onOpenShop, GameInfoDisplayMobile.POSITION.SHOP_ICON, GameInfoDisplayMobile.SIZE.SHOP_ICON, GameInfoDisplayMobile.SIZE.BUTTON_ICON, GameInfoDisplayMobile.UV.SHOP, GameInfoDisplayMobile.COLOR.BUTTON, GameInfoDisplayMobile.COLOR.BUTTON_BACKGROUND, GameInfoDisplayMobile.COLOR.BUTTON_SELECTED, InputAction.TOGGLE_STORE)
		self:createButtonElement(self.onOpenMap, GameInfoDisplayMobile.POSITION.MAP_ICON, GameInfoDisplayMobile.SIZE.MAP_ICON, GameInfoDisplayMobile.SIZE.BUTTON_ICON, GameInfoDisplayMobile.UV.MAP, GameInfoDisplayMobile.COLOR.BUTTON, GameInfoDisplayMobile.COLOR.BUTTON_BACKGROUND, GameInfoDisplayMobile.COLOR.BUTTON_SELECTED, InputAction.TOGGLE_MAP)
		self:createButtonElement(self.onOpenMenu, GameInfoDisplayMobile.POSITION.MENU_ICON, GameInfoDisplayMobile.SIZE.MENU_ICON, GameInfoDisplayMobile.SIZE.BUTTON_ICON, GameInfoDisplayMobile.UV.MENU, GameInfoDisplayMobile.COLOR.BUTTON, GameInfoDisplayMobile.COLOR.BUTTON_BACKGROUND, GameInfoDisplayMobile.COLOR.BUTTON_SELECTED, InputAction.MENU)
	end

	self:createInfoElement(self.getMoneyValue, GameInfoDisplayMobile.POSITION.MONEY_AREA, GameInfoDisplayMobile.SIZE.MONEY_AREA, GameInfoDisplayMobile.SIZE.MONEY_ICON, GameInfoDisplayMobile.SIZE.ICON_OFFSET_MONEY, GameInfoDisplayMobile.SIZE.ICON_PADDING, GameInfoDisplayMobile.UV.SHOP, GameInfoDisplayMobile.COLOR.BUTTON, GameInfoDisplayMobile.SIZE.TEXT_OFFSET_MONEY, GameInfoDisplayMobile.SIZE.TEXT_SIZE, true)
	self:createInfoElement(self.getFuelValue, GameInfoDisplayMobile.POSITION.FUEL_AREA, GameInfoDisplayMobile.SIZE.FUEL_AREA, GameInfoDisplayMobile.SIZE.FUEL_ICON, GameInfoDisplayMobile.SIZE.ICON_OFFSET_FUEL, GameInfoDisplayMobile.SIZE.ICON_PADDING, GameInfoDisplayMobile.UV.FUEL, GameInfoDisplayMobile.COLOR.BUTTON, GameInfoDisplayMobile.SIZE.TEXT_OFFSET_FUEL, GameInfoDisplayMobile.SIZE.TEXT_SIZE, true)

	for _, element in ipairs(self.elements) do
		self:addChild(element)
	end

	return self
end

function GameInfoDisplayMobile:setVehicle(vehicle)
	self.vehicle = vehicle

	if vehicle ~= nil then
		self.isRideable = SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations)

		self.infoElements[2].icon:setUVs(GuiUtils.getUVs(self.isRideable and GameInfoDisplayMobile.UV.RIDING or GameInfoDisplayMobile.UV.FUEL))
	else
		self.isRideable = false

		self.infoElements[2].icon:setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.FUEL))
	end
end

function GameInfoDisplayMobile:createSeparators()
	local posX = GameInfoDisplayMobile.POSITION.CENTER_BACKGROUND[1] + GameInfoDisplayMobile.POSITION.SEPARATOR_01[1]
	local posY = GameInfoDisplayMobile.POSITION.CENTER_BACKGROUND[2] + GameInfoDisplayMobile.POSITION.SEPARATOR_01[2]
	local separator = self:createHUDElement({
		posX,
		posY
	}, GameInfoDisplayMobile.SIZE.SEPARATOR, HUDElement.UV.FILL, GameInfoDisplayMobile.COLOR.SEPARATOR)

	table.insert(self.elements, separator)
end

function GameInfoDisplayMobile:createBorders()
	if not g_isPresentationVersion then
		local border = self:createHUDElement({
			0,
			0
		}, {
			GameInfoDisplayMobile.SIZE.BACKGROUND[1],
			2
		}, HUDElement.UV.FILL, GameInfoDisplayMobile.COLOR.BORDER)

		table.insert(self.elements, border)

		border = self:createHUDElement({
			0,
			2
		}, {
			2,
			GameInfoDisplayMobile.SIZE.BACKGROUND[2]
		}, HUDElement.UV.FILL, GameInfoDisplayMobile.COLOR.BORDER)

		table.insert(self.elements, border)

		border = self:createHUDElement({
			GameInfoDisplayMobile.SIZE.BACKGROUND[1] - 2,
			2
		}, {
			2,
			GameInfoDisplayMobile.SIZE.BACKGROUND[2]
		}, HUDElement.UV.FILL, GameInfoDisplayMobile.COLOR.BORDER)

		table.insert(self.elements, border)

		border = self:createHUDElement({
			GameInfoDisplayMobile.POSITION.CENTER_BACKGROUND[1] + GameInfoDisplayMobile.SIZE.CENTER_BACKGROUND[1] + GameInfoDisplayMobile.POSITION.CENTER_BACKGROUND[1] / 2,
			2
		}, {
			2,
			GameInfoDisplayMobile.SIZE.BACKGROUND[2]
		}, HUDElement.UV.FILL, GameInfoDisplayMobile.COLOR.BORDER)

		table.insert(self.elements, border)
	else
		local border = self:createHUDElement({
			GameInfoDisplayMobile.POSITION.CENTER_BACKGROUND[1] - 2,
			0
		}, {
			GameInfoDisplayMobile.SIZE.BACKGROUND_REDUCED[1],
			2
		}, HUDElement.UV.FILL, GameInfoDisplayMobile.COLOR.BORDER)

		table.insert(self.elements, border)

		border = self:createHUDElement({
			GameInfoDisplayMobile.POSITION.CENTER_BACKGROUND[1] + GameInfoDisplayMobile.SIZE.CENTER_BACKGROUND[1] + GameInfoDisplayMobile.POSITION.CENTER_BACKGROUND[1] / 2 - 1,
			2
		}, {
			2,
			GameInfoDisplayMobile.SIZE.BACKGROUND[2]
		}, HUDElement.UV.FILL, GameInfoDisplayMobile.COLOR.BORDER)

		table.insert(self.elements, border)
	end

	local border = self:createHUDElement({
		GameInfoDisplayMobile.POSITION.CENTER_BACKGROUND[1] - 2,
		2
	}, {
		2,
		GameInfoDisplayMobile.SIZE.BACKGROUND[2]
	}, HUDElement.UV.FILL, GameInfoDisplayMobile.COLOR.BORDER)

	table.insert(self.elements, border)

	border = self:createHUDElement({
		GameInfoDisplayMobile.POSITION.CENTER_BACKGROUND[1] + GameInfoDisplayMobile.SIZE.CENTER_BACKGROUND[1],
		2
	}, {
		2,
		GameInfoDisplayMobile.SIZE.BACKGROUND[2]
	}, HUDElement.UV.FILL, GameInfoDisplayMobile.COLOR.BORDER)

	table.insert(self.elements, border)
end

function GameInfoDisplayMobile:createHUDElement(position, size, uvs, color)
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

function GameInfoDisplayMobile:createButtonElement(callback, position, size, iconSize, uvs, color, backgroundColor, iconColorPressed, inputAction)
	local button = {
		callback = callback,
		display = callback,
		backgroundElement = self:createHUDElement(position, size, HUDElement.UV.FILL, backgroundColor),
		iconColorPressed = iconColorPressed
	}
	local posX = position[1] + size[1] * 0.5 - iconSize[1] * 0.5
	local posY = position[2] + size[2] * 0.5 - iconSize[2] * 0.5
	button.iconElement = self:createHUDElement({
		posX,
		posY
	}, iconSize, uvs, color)
	button.iconColor = color

	table.insert(self.elements, button.backgroundElement)
	table.insert(self.elements, button.iconElement)

	local function pressButton(button)
		button.iconElement:setColor(unpack(button.iconColorPressed))
	end

	local function releaseButton(button)
		button.iconElement:setColor(unpack(button.iconColor))
	end

	local function buttonCb(target, x, y, isCancel)
		if not isCancel then
			callback(target, x, y)
		end
	end

	self.hud:addTouchButton(button.backgroundElement.overlay, 0, 0, buttonCb, self, TouchHandler.TRIGGER_UP, {
		button
	})
	self.hud:addTouchButton(button.backgroundElement.overlay, 0, 0, pressButton, button, TouchHandler.TRIGGER_DOWN)
	self.hud:addTouchButton(button.backgroundElement.overlay, 0, 0, releaseButton, button, TouchHandler.TRIGGER_UP)

	if inputAction ~= nil then
		local glyphWidth, glyphHeight = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.INPUT_GLYPH))
		local baseX, baseY = self:getPosition()
		local sPosX, sPosY = getNormalizedScreenValues(unpack(position))
		local sSizeX, sSizeY = getNormalizedScreenValues(unpack(size))
		local glyphElement = InputGlyphElement.new(g_inputDisplayManager, glyphWidth, glyphHeight)

		glyphElement:setAction(inputAction)
		glyphElement:setButtonGlyphColor(GameInfoDisplayMobile.COLOR.INPUT_GLYPH)

		local actualWidth = glyphElement:getGlyphWidth()

		glyphElement:setPosition(baseX + sPosX + sSizeX - actualWidth, baseY + sPosY + sSizeY - glyphHeight)
		table.insert(self.elements, glyphElement)
		table.insert(self.inputGlyphs, glyphElement)
	end
end

function GameInfoDisplayMobile:createInfoElement(valueFunc, position, size, iconSize, iconOffset, iconPadding, uvs, color, textOffset, textSize, textBold)
	local infoElement = {
		position = position,
		size = size,
		icon = self:createHUDElement(position, iconSize, uvs, color),
		iconSize = iconSize,
		iconOffset = iconOffset,
		iconPadding = iconPadding
	}
	local _, textSizeY = getNormalizedScreenValues(0, textSize[2])
	infoElement.textSize = textSizeY
	local textPosX, textPosY = getNormalizedScreenValues(position[1] + size[1] - textOffset[1], position[2] + size[2] / 2 - textSize[2] / 2 + textOffset[2])
	infoElement.textPos = {
		textPosX,
		textPosY
	}
	infoElement.textOffset = textOffset
	infoElement.textAlign = RenderText.ALIGN_RIGHT
	infoElement.textBold = textBold
	infoElement.valueFunc = valueFunc
	local baseX, baseY = self:getPosition()
	local iconPosX, iconPosY = getNormalizedScreenValues(infoElement.position[1] + infoElement.iconOffset[1] - infoElement.iconPadding[1], infoElement.position[2] + infoElement.iconOffset[2] + infoElement.size[2] / 2 - infoElement.iconSize[2] / 2)

	infoElement.icon:setPosition(baseX + iconPosX, baseY + iconPosY)
	table.insert(self.elements, infoElement.icon)
	table.insert(self.infoElements, infoElement)
end

function GameInfoDisplayMobile:updateInfoElement(infoElement)
	if infoElement.icon:getVisible() then
		local baseX, baseY = self:getPosition()

		setTextColor(1, 1, 1, 1)
		setTextBold(infoElement.textBold)
		setTextAlignment(infoElement.textAlign)
		renderText(baseX + infoElement.textPos[1], baseY + infoElement.textPos[2], infoElement.textSize, infoElement.valueFunc(self))
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextBold(false)
	end
end

function GameInfoDisplayMobile:getMoneyValue()
	if g_currentMission.player ~= nil then
		local farm = g_farmManager:getFarmById(g_currentMission.player.farmId)

		return g_i18n:formatMoney(farm.money, 0, false, true)
	end

	return "0"
end

function GameInfoDisplayMobile:getFuelValue()
	if self.vehicle ~= nil and self.vehicle.getConsumerFillUnitIndex ~= nil then
		local fillUnitIndex = self.vehicle:getConsumerFillUnitIndex(FillType.DIESEL)

		if fillUnitIndex ~= nil then
			local fillLevelPct = self.vehicle:getFillUnitFillLevelPercentage(fillUnitIndex)

			return string.format("%d%%", fillLevelPct * 100)
		end
	end

	return "-"
end

function GameInfoDisplayMobile:getTimeValue()
	local currentTime = self.environment.dayTime / 3600000
	local timeHours = math.floor(currentTime)
	local timeMinutes = math.floor((currentTime - timeHours) * 60)

	return string.format("%02d:%02d", timeHours, timeMinutes)
end

function GameInfoDisplayMobile:onOpenShop()
	g_currentMission:onToggleStore()
end

function GameInfoDisplayMobile:onOpenMap()
	g_currentMission:onToggleMap()
end

function GameInfoDisplayMobile:onOpenMenu()
	g_currentMission:onToggleMenu()
end

function GameInfoDisplayMobile:setMoneyUnit(moneyUnit)
	if moneyUnit ~= GS_MONEY_EURO and moneyUnit ~= GS_MONEY_POUND and moneyUnit ~= GS_MONEY_DOLLAR then
		moneyUnit = GS_MONEY_DOLLAR
	end

	self.moneyUnit = moneyUnit

	self.infoElements[1].icon:setUVs(GuiUtils.getUVs(GameInfoDisplayMobile.UV.MONEY_ICON[moneyUnit]))
end

function GameInfoDisplayMobile:setMissionStats(missionStats)
	self.missionStats = missionStats
end

function GameInfoDisplayMobile:setMissionInfo(missionInfo)
	self.missionInfo = missionInfo
end

function GameInfoDisplayMobile:setEnvironment(environment)
	self.environment = environment
end

function GameInfoDisplayMobile:setMoneyVisible(isVisible)
end

function GameInfoDisplayMobile:setTimeVisible(isVisible)
end

function GameInfoDisplayMobile:setTemperatureVisible(isVisible)
end

function GameInfoDisplayMobile:setWeatherVisible(isVisible)
end

function GameInfoDisplayMobile:setTutorialVisible(isVisible)
end

function GameInfoDisplayMobile:setTutorialProgress(progress)
end

function GameInfoDisplayMobile:draw()
	GameInfoDisplayMobile:superClass().draw(self)

	for _, infoElement in ipairs(self.infoElements) do
		self:updateInfoElement(infoElement)
	end
end

function GameInfoDisplayMobile:onInputHelpModeChange(inputHelpMode, force)
	self.lastInputHelpMode = inputHelpMode
	local showGlyphs = inputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD

	for _, glyph in ipairs(self.inputGlyphs) do
		glyph:setVisible(showGlyphs)
	end
end

function GameInfoDisplayMobile:setScale(uiScale)
	GameInfoDisplayMobile:superClass().setScale(self, uiScale, uiScale)

	local currentVisibility = self:getVisible()

	self:setVisible(true, false)

	self.uiScale = uiScale
	local posX, posY = GameInfoDisplayMobile.getBackgroundPosition(uiScale, self:getWidth())

	self:setPosition(posX, posY)
	self:storeOriginalPosition()
	self:setVisible(currentVisibility, false)
end

function GameInfoDisplayMobile.getBackgroundPosition(scale, width)
	local offX, offY = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.BACKGROUND))
	local sizeX, _ = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.BACKGROUND))

	if g_isPresentationVersion then
		sizeX, _ = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.BACKGROUND_REDUCED))
		local centerOff, _ = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.POSITION.CENTER_BACKGROUND))
		offX = offX + centerOff
	end

	return 0.5 - sizeX / 2 - offX, 1 - g_safeFrameOffsetY - offY * scale
end

function GameInfoDisplayMobile.createBackground()
	local width, height = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.BACKGROUND))

	if g_isPresentationVersion then
		width, height = getNormalizedScreenValues(unpack(GameInfoDisplayMobile.SIZE.BACKGROUND_REDUCED))
	end

	local posX, posY = GameInfoDisplayMobile.getBackgroundPosition(1, width)

	return Overlay.new(nil, posX, posY, width, height)
end

GameInfoDisplayMobile.SIZE = {
	BACKGROUND = {
		1072,
		100
	},
	BACKGROUND_REDUCED = {
		759,
		100
	},
	CENTER_BACKGROUND = {
		650,
		100
	},
	SEPARATOR = {
		2,
		71
	},
	BUTTON_ICON = {
		96,
		96
	},
	MONEY_ICON = {
		71,
		71
	},
	FUEL_ICON = {
		74,
		74
	},
	TIME_ICON = {
		79,
		79
	},
	SHOP_ICON = {
		207,
		100
	},
	MAP_ICON = {
		103,
		100
	},
	MENU_ICON = {
		102,
		100
	},
	ICON_PADDING = {
		10,
		10
	},
	ICON_OFFSET_MONEY = {
		19,
		2.5
	},
	ICON_OFFSET_FUEL = {
		15,
		3.5
	},
	ICON_OFFSET_TIME = {
		13,
		2.5
	},
	MONEY_ICON_PADDING = {
		5,
		5
	},
	MONEY_AREA = {
		410,
		99
	},
	FUEL_AREA = {
		234,
		99
	},
	TEXT_OFFSET_MONEY = {
		18,
		7.5
	},
	TEXT_OFFSET_FUEL = {
		16,
		7.5
	},
	TEXT_OFFSET_TIME = {
		12,
		7.5
	},
	TEXT_SIZE = {
		0,
		53
	},
	INPUT_GLYPH = {
		36,
		36
	}
}
GameInfoDisplayMobile.POSITION = {
	BACKGROUND = {
		0,
		52
	},
	CENTER_BACKGROUND = {
		211,
		2
	},
	SHOP_ICON = {
		2,
		2
	},
	MAP_ICON = {
		863,
		2
	},
	MENU_ICON = {
		968,
		2
	},
	SEPARATOR_01 = {
		411,
		15
	},
	MONEY_AREA = {
		211,
		1
	},
	FUEL_AREA = {
		622,
		1
	},
	INPUT_GLYPH = {
		-3,
		-3
	}
}
GameInfoDisplayMobile.UV = {
	BACKGROUND = {
		133,
		908,
		872,
		100
	},
	SHOP = {
		384,
		48,
		96,
		96
	},
	FUEL = {
		576,
		144,
		96,
		96
	},
	TIME = {
		672,
		144,
		96,
		96
	},
	MAP = {
		480,
		48,
		96,
		96
	},
	MENU = {
		576,
		48,
		96,
		96
	},
	RIDING = {
		672,
		336,
		96,
		96
	},
	MONEY_ICON = {
		[GS_MONEY_EURO] = {
			864,
			240,
			96,
			96
		},
		[GS_MONEY_POUND] = {
			768,
			240,
			96,
			96
		},
		[GS_MONEY_DOLLAR] = {
			672,
			240,
			96,
			96
		}
	}
}
GameInfoDisplayMobile.COLOR = {
	BACKGROUND = {
		1,
		1,
		1,
		0.5
	},
	SEPARATOR = {
		1,
		1,
		1,
		0.5
	},
	BORDER = {
		0.152941,
		0.152941,
		0.152941,
		1
	},
	BUTTON_BACKGROUND = {
		0.04706,
		0.04706,
		0.04706,
		1
	},
	BUTTON = {
		1,
		1,
		1,
		1
	},
	BUTTON_SELECTED = {
		0.991,
		0.3865,
		0.01,
		1
	},
	INPUT_GLYPH = {
		0.991,
		0.3865,
		0.01,
		1
	}
}
