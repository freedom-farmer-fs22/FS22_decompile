IngameMapLayoutSquare = {}
local IngameMapLayoutSquare_mt = Class(IngameMapLayoutSquare, IngameMapLayout)

function IngameMapLayoutSquare.new()
	return IngameMapLayoutSquare:superClass().new(IngameMapLayoutSquare_mt)
end

function IngameMapLayoutSquare:delete()
	delete(self.overlayMask)

	self.overlayMask = nil

	self.backgroundElement:delete()
	self.unreadMessagesElement:delete()
	IngameMapLayoutSquare:superClass().delete(self)
end

function IngameMapLayoutSquare:createComponents(element, hudAtlasPath)
	self.overlayMask = createOverlayTextureFromFile("dataS/menu/hud/minimap_mask_square.png")
	local width, height = getNormalizedScreenValues(unpack(IngameMapLayoutSquare.SIZE.SELF))
	local posX = g_safeFrameOffsetX
	local posY = g_safeFrameOffsetY
	local overlay = Overlay.new(hudAtlasPath, posX, posY, width, height)

	overlay:setUVs(GuiUtils.getUVs(IngameMapLayoutSquare.UV.BACKGROUND))
	overlay:setColor(0, 0, 0, 0.75)

	self.backgroundElement = HUDElement.new(overlay)
	width, height = getNormalizedScreenValues(unpack(IngameMapLayoutSquare.SIZE.UNREAD_MESSAGES_BG))
	local offX, offY = getNormalizedScreenValues(unpack(IngameMapLayoutSquare.POSITION.UNREAD_MESSAGES_BG))
	overlay = Overlay.new(hudAtlasPath, posX + offX, posY + offY, width, height)

	overlay:setUVs(GuiUtils.getUVs(IngameMapLayoutSquare.UV.UNREAD_MESSAGES_BG))
	overlay:setColor(0, 0, 0, 0.75)

	self.unreadMessagesElement = HUDElement.new(overlay)
	width, height = getNormalizedScreenValues(unpack(IngameMapLayoutSquare.SIZE.UNREAD_MESSAGES))
	offX, offY = getNormalizedScreenValues(unpack(IngameMapLayoutSquare.POSITION.UNREAD_MESSAGES))
	overlay = Overlay.new(hudAtlasPath, posX + offX, posY + offY, width, height)

	overlay:setUVs(GuiUtils.getUVs(IngameMapLayoutSquare.UV.UNREAD_MESSAGES))
	overlay:setColor(1, 1, 1, 1)
	self.unreadMessagesElement:addChild(HUDElement.new(overlay))
end

function IngameMapLayoutSquare:storeScaledValues(element, uiScale)
	self.backgroundElement:setScale(uiScale, uiScale)

	self.mapOffsetX, self.mapOffsetY = element:scalePixelToScreenVector(IngameMapLayoutSquare.POSITION.MAP)
	self.mapSizeX, self.mapSizeY = element:scalePixelToScreenVector(IngameMapLayoutSquare.SIZE.MAP)
	self.mapPosY = g_safeFrameOffsetY + self.mapOffsetY
	self.mapPosX = g_safeFrameOffsetX + self.mapOffsetX
	self.coordinateFontSize = element:scalePixelToScreenHeight(IngameMapLayoutSquare.TEXT_SIZE.COORDINATES)
	self.coordOffsetX, self.coordOffsetY = element:scalePixelToScreenVector(IngameMapLayoutSquare.POSITION.COORDINATES)
	self.latencyFontSize = element:scalePixelToScreenHeight(IngameMapLayoutSquare.TEXT_SIZE.LATENCY)
	self.latencyOffsetX, self.latencyOffsetY = element:scalePixelToScreenVector(IngameMapLayoutSquare.POSITION.LATENCY)
end

function IngameMapLayoutSquare:drawBefore()
	self.backgroundElement:draw()
	set2DMaskFromTexture(self.overlayMask, true, self.mapPosX, self.mapPosY, self.mapSizeX, self.mapSizeY)
end

function IngameMapLayoutSquare:drawAfter()
	set2DMaskFromTexture(0, true, 0, 0, 0, 0)

	if self.hasMessages then
		self.unreadMessagesElement:draw()
	end
end

function IngameMapLayoutSquare:drawCoordinates(text)
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextBold(false)

	local x = self.mapPosX + self.mapSizeX / 2
	local y = self.mapPosY + self.coordOffsetY

	setTextColor(0, 0, 0, 1)
	renderText(x + 1 / g_screenWidth, y - 1 / g_screenHeight, self.coordinateFontSize, text)
	setTextColor(unpack(IngameMap.COLOR.COORDINATES_TEXT))
	renderText(x, y, self.coordinateFontSize, text)
end

function IngameMapLayoutSquare:drawLatency(text, color)
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_RIGHT)

	local x = self.mapPosX + self.mapSizeX + self.latencyOffsetX
	local y = self.mapPosY + self.latencyOffsetY

	setTextColor(0, 0, 0, 1)
	renderText(x + 1 / g_screenWidth, y - 1 / g_screenHeight, self.latencyFontSize, text)
	setTextColor(unpack(color))
	renderText(x, y, self.latencyFontSize, text)
end

function IngameMapLayoutSquare:setPlayerPosition(x, z, yRot)
	self.playerU = x * 0.5 + 0.25
	self.playerV = (1 - z) * 0.5 + 0.25
	self.playerRot = yRot
end

function IngameMapLayoutSquare:setPlayerVelocity(speed)
	self.velocityZoomFactor = MathUtil.clamp(speed / 50, 0, 1)
end

function IngameMapLayoutSquare:setWorldSize(worldSizeX, worldSizeZ)
	self.worldSizeFactor = worldSizeX / 2048
end

function IngameMapLayoutSquare:setHasUnreadMessages(hasMessages)
	self.hasMessages = hasMessages
end

function IngameMapLayoutSquare:getMapPosition()
	local mapWidth, mapHeight = self:getMapSize()
	local playerScreenX = self.mapPosX + self.mapSizeX / 2
	local playerScreenY = self.mapPosY + self.mapSizeY / 2
	local offX = playerScreenX - self.playerU * mapWidth
	local offY = playerScreenY - self.playerV * mapHeight

	return offX, offY
end

function IngameMapLayoutSquare:getMapSize()
	local width = (1 - 0.25 * self.velocityZoomFactor) * self.worldSizeFactor

	return width, width * g_screenAspectRatio
end

function IngameMapLayoutSquare:getMapAlpha()
	return 0.7
end

function IngameMapLayoutSquare:getShowsToggleAction()
	return false
end

function IngameMapLayoutSquare:getShowsToggleActionText()
	return true
end

function IngameMapLayoutSquare:getShowSmallIconVariation()
	return true
end

function IngameMapLayoutSquare:getIconZoom()
	return 0.5
end

function IngameMapLayoutSquare:getHeight()
	return self.mapSizeY
end

function IngameMapLayoutSquare:getMapObjectPosition(objectU, objectV, width, height, rot, persistent)
	local mapWidth, mapHeight = self:getMapSize()
	local mapX, mapY = self:getMapPosition()
	local objectX = objectU * mapWidth + mapX - width * 0.5
	local objectY = (1 - objectV) * mapHeight + mapY - height * 0.5

	if persistent then
		objectX = MathUtil.clamp(objectX, self.mapPosX - width * 0.5, self.mapPosX + self.mapSizeX - width * 0.5)
		objectY = MathUtil.clamp(objectY, self.mapPosY - height * 0.5, self.mapPosY + self.mapSizeY - height * 0.5)
	end

	local minX = self.mapPosX - width
	local maxX = self.mapPosX + self.mapSizeX + width
	local minY = self.mapPosY - height
	local maxY = self.mapPosY + self.mapSizeY + height

	if objectX < minX or maxX < objectX or objectY < minY or maxY < objectY then
		return 0, 0, 0, false
	end

	return objectX, objectY, rot, true
end

IngameMapLayoutSquare.SIZE = {
	SELF = {
		256,
		256
	},
	MAP = {
		236,
		236
	},
	UNREAD_MESSAGES = {
		32,
		32
	},
	UNREAD_MESSAGES_BG = {
		38,
		38
	}
}
IngameMapLayoutSquare.TEXT_SIZE = {
	COORDINATES = 14,
	LATENCY = 14
}
IngameMapLayoutSquare.POSITION = {
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
	},
	UNREAD_MESSAGES = {
		3,
		262
	},
	UNREAD_MESSAGES_BG = {
		0,
		259
	}
}
IngameMapLayoutSquare.UV = {
	BACKGROUND = {
		435,
		350,
		10,
		10
	},
	UNREAD_MESSAGES = {
		377,
		331,
		32,
		32
	},
	UNREAD_MESSAGES_BG = {
		472,
		331,
		44,
		44
	}
}
