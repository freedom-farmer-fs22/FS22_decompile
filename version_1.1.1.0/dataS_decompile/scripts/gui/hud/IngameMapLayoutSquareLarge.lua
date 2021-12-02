IngameMapLayoutSquareLarge = {}
local IngameMapLayoutSquareLarge_mt = Class(IngameMapLayoutSquareLarge, IngameMapLayout)

function IngameMapLayoutSquareLarge.new()
	return IngameMapLayoutSquareLarge:superClass().new(IngameMapLayoutSquareLarge_mt)
end

function IngameMapLayoutSquareLarge:delete()
	delete(self.overlayMask)

	self.overlayMask = nil

	self.backgroundElement:delete()
	IngameMapLayoutSquareLarge:superClass().delete(self)
end

function IngameMapLayoutSquareLarge:createComponents(element, hudAtlasPath)
	self.overlayMask = createOverlayTextureFromFile("dataS/menu/hud/minimap_mask_square.png")
	local width, height = getNormalizedScreenValues(unpack(IngameMapLayoutSquareLarge.SIZE.SELF))
	local posX = g_safeFrameOffsetX
	local posY = g_safeFrameOffsetY
	local overlay = Overlay.new(hudAtlasPath, posX, posY, width, height)

	overlay:setUVs(GuiUtils.getUVs(IngameMapLayoutSquareLarge.UV.BACKGROUND))
	overlay:setColor(0, 0, 0, 0.75)

	self.backgroundElement = HUDElement.new(overlay)
end

function IngameMapLayoutSquareLarge:storeScaledValues(element, uiScale)
	self.backgroundElement:setScale(uiScale, uiScale)

	self.mapOffsetX, self.mapOffsetY = element:scalePixelToScreenVector(IngameMapLayoutSquareLarge.POSITION.MAP)
	self.mapSizeX, self.mapSizeY = element:scalePixelToScreenVector(IngameMapLayoutSquareLarge.SIZE.MAP)
	self.mapPosY = g_safeFrameOffsetY + self.mapOffsetY
	self.mapPosX = g_safeFrameOffsetX + self.mapOffsetX
	self.coordinateFontSize = element:scalePixelToScreenHeight(IngameMapLayoutSquareLarge.TEXT_SIZE.COORDINATES)
	self.coordOffsetX, self.coordOffsetY = element:scalePixelToScreenVector(IngameMapLayoutSquareLarge.POSITION.COORDINATES)
	self.latencyFontSize = element:scalePixelToScreenHeight(IngameMapLayoutSquare.TEXT_SIZE.LATENCY)
	self.latencyOffsetX, self.latencyOffsetY = element:scalePixelToScreenVector(IngameMapLayoutSquare.POSITION.LATENCY)
end

function IngameMapLayoutSquareLarge:drawBefore()
	self.backgroundElement:draw()
	set2DMaskFromTexture(self.overlayMask, true, self.mapPosX, self.mapPosY, self.mapSizeX, self.mapSizeY)
end

function IngameMapLayoutSquareLarge:drawAfter()
	set2DMaskFromTexture(0, true, 0, 0, 0, 0)
end

function IngameMapLayoutSquareLarge:drawCoordinates(text)
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextBold(false)

	local x = self.mapPosX + self.mapSizeX / 2
	local y = self.mapPosY + self.coordOffsetY

	setTextColor(0, 0, 0, 1)
	renderText(x + 1 / g_screenWidth, y - 1 / g_screenHeight, self.coordinateFontSize, text)
	setTextColor(unpack(IngameMap.COLOR.COORDINATES_TEXT))
	renderText(x, y, self.coordinateFontSize, text)
end

function IngameMapLayoutSquareLarge:drawLatency(text, color)
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_RIGHT)

	local x = self.mapPosX + self.mapSizeX + self.latencyOffsetX
	local y = self.mapPosY + self.latencyOffsetY

	setTextColor(0, 0, 0, 1)
	renderText(x + 1 / g_screenWidth, y - 1 / g_screenHeight, self.latencyFontSize, text)
	setTextColor(unpack(color))
	renderText(x, y, self.latencyFontSize, text)
end

function IngameMapLayoutSquareLarge:getMapPosition()
	return -self.mapSizeX / 2 + self.mapPosX, -self.mapSizeY / 2 + self.mapPosY
end

function IngameMapLayoutSquareLarge:getMapSize()
	return self.mapSizeX * 2, self.mapSizeY * 2
end

function IngameMapLayoutSquareLarge:getMapAlpha()
	return 0.7
end

function IngameMapLayoutSquareLarge:getShowsToggleAction()
	return false
end

function IngameMapLayoutSquareLarge:getShowsToggleActionText()
	return true
end

function IngameMapLayoutSquareLarge:getShowSmallIconVariation()
	return true
end

function IngameMapLayoutSquareLarge:getIconZoom()
	return 0.75
end

function IngameMapLayoutSquareLarge:getHeight()
	return self.mapSizeY
end

function IngameMapLayoutSquareLarge:getMapObjectPosition(objectU, objectV, width, height, rot, persistent)
	local mapWidth, mapHeight = self:getMapSize()
	local mapX, mapY = self:getMapPosition()
	local objectX = objectU * mapWidth + mapX - width * 0.5
	local objectY = (1 - objectV) * mapHeight + mapY - height * 0.5

	return objectX, objectY, rot, true
end

IngameMapLayoutSquareLarge.SIZE = {
	SELF = {
		700,
		700
	},
	MAP = {
		680,
		680
	}
}
IngameMapLayoutSquareLarge.TEXT_SIZE = {
	COORDINATES = 14,
	LATENCY = 14
}
IngameMapLayoutSquareLarge.POSITION = {
	MAP = {
		10,
		10
	},
	COORDINATES = {
		0,
		4
	},
	LATENCY = {
		-4,
		4
	}
}
IngameMapLayoutSquareLarge.UV = {
	BACKGROUND = {
		435,
		350,
		10,
		10
	}
}
