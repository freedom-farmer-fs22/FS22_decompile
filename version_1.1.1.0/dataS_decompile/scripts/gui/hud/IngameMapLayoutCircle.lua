IngameMapLayoutCircle = {}
local IngameMapLayoutCircle_mt = Class(IngameMapLayoutCircle, IngameMapLayout)
local HALF_PI = math.pi * 0.5

function IngameMapLayoutCircle.new()
	return IngameMapLayoutCircle:superClass().new(IngameMapLayoutCircle_mt)
end

function IngameMapLayoutCircle:delete()
	delete(self.overlayMask)

	self.overlayMask = nil

	self.backgroundElement:delete()
	self.unreadMessagesElement:delete()
	self.northElement:delete()
	IngameMapLayoutCircle:superClass().delete(self)
end

function IngameMapLayoutCircle:createComponents(element, hudAtlasPath)
	self.overlayMask = createOverlayTextureFromFile("dataS/menu/hud/minimap_mask.png")
	local width, height = getNormalizedScreenValues(unpack(IngameMapLayoutCircle.SIZE.SELF))
	local posX = g_safeFrameOffsetX
	local posY = g_safeFrameOffsetY
	local overlay = Overlay.new(hudAtlasPath, posX, posY, width, height)

	overlay:setUVs(GuiUtils.getUVs(IngameMapLayoutCircle.UV.BACKGROUND))
	overlay:setColor(0, 0, 0, 0.75)

	self.backgroundElement = HUDElement.new(overlay)
	width, height = getNormalizedScreenValues(unpack(IngameMapLayoutCircle.SIZE.UNREAD_MESSAGES_BG))
	local offX, offY = getNormalizedScreenValues(unpack(IngameMapLayoutCircle.POSITION.UNREAD_MESSAGES_BG))
	overlay = Overlay.new(hudAtlasPath, posX + offX, posY + offY, width, height)

	overlay:setUVs(GuiUtils.getUVs(IngameMapLayoutCircle.UV.UNREAD_MESSAGES_BG))
	overlay:setColor(0, 0, 0, 0.75)

	self.unreadMessagesElement = HUDElement.new(overlay)
	width, height = getNormalizedScreenValues(unpack(IngameMapLayoutCircle.SIZE.UNREAD_MESSAGES))
	offX, offY = getNormalizedScreenValues(unpack(IngameMapLayoutCircle.POSITION.UNREAD_MESSAGES))
	overlay = Overlay.new(hudAtlasPath, posX + offX, posY + offY, width, height)

	overlay:setUVs(GuiUtils.getUVs(IngameMapLayoutCircle.UV.UNREAD_MESSAGES))
	overlay:setColor(1, 1, 1, 1)
	self.unreadMessagesElement:addChild(HUDElement.new(overlay))

	width, height = getNormalizedScreenValues(unpack(IngameMapLayoutCircle.SIZE.NORTH_ARROW))
	posY = 0.5
	posX = 0.5
	overlay = Overlay.new(hudAtlasPath, posX, posY, width, height)

	overlay:setUVs(GuiUtils.getUVs(IngameMapLayoutCircle.UV.NORTH_ARROW))
	overlay:setColor(0.5, 0.5, 0.5, 0.9)

	self.northElement = HUDElement.new(overlay)
	local pivotX, pivotY = self.northElement:normalizeUVPivot(IngameMapLayoutCircle.PIVOT.NORTH_ARROW, IngameMapLayoutCircle.SIZE.NORTH_ARROW, IngameMapLayoutCircle.UV.NORTH_ARROW)

	self.northElement:setRotationPivot(pivotX, pivotY)
end

function IngameMapLayoutCircle:storeScaledValues(element, uiScale)
	self.backgroundElement:setScale(uiScale, uiScale)

	self.mapOffsetX, self.mapOffsetY = element:scalePixelToScreenVector(IngameMapLayoutCircle.POSITION.MAP)
	self.mapSizeX, self.mapSizeY = element:scalePixelToScreenVector(IngameMapLayoutCircle.SIZE.MAP)
	self.mapPosY = g_safeFrameOffsetY + self.mapOffsetY
	self.mapPosX = g_safeFrameOffsetX + self.mapOffsetX
	self.fontSize = element:scalePixelToScreenHeight(HUDElement.TEXT_SIZE.DEFAULT_TEXT)
	self.coordinateFontSize = element:scalePixelToScreenHeight(IngameMapLayoutCircle.TEXT_SIZE.COORDINATES)
	self.coordOffsetX, self.coordOffsetY = element:scalePixelToScreenVector(IngameMapLayoutCircle.POSITION.COORDINATES)
	self.latencyFontSize = element:scalePixelToScreenHeight(IngameMapLayoutCircle.TEXT_SIZE.LATENCY)
	self.latencyOffsetX, self.latencyOffsetY = element:scalePixelToScreenVector(IngameMapLayoutCircle.POSITION.LATENCY)
end

function IngameMapLayoutCircle:drawBefore()
	set2DMaskFromTexture(self.overlayMask, true, self.mapPosX, self.mapPosY, self.mapSizeX, self.mapSizeY)
end

function IngameMapLayoutCircle:drawAfter()
	set2DMaskFromTexture(0, true, 0, 0, 0, 0)
	self.backgroundElement:draw()

	if self.hasMessages then
		self.unreadMessagesElement:draw()
	end

	self:drawNorthArrow(-self.playerRot + math.pi / 2)
end

function IngameMapLayoutCircle:drawCoordinates(text)
	setTextAlignment(RenderText.ALIGN_CENTER)
	setTextBold(false)

	local x = self.mapPosX + self.mapSizeX / 2
	local y = self.mapPosY + self.coordOffsetY

	setTextColor(0, 0, 0, 1)
	renderText(x + 1 / g_screenWidth, y - 1 / g_screenHeight, self.coordinateFontSize, text)
	setTextColor(unpack(IngameMap.COLOR.COORDINATES_TEXT))
	renderText(x, y, self.coordinateFontSize, text)
end

function IngameMapLayoutCircle:drawLatency(text, color)
	setTextBold(false)
	setTextAlignment(RenderText.ALIGN_CENTER)

	local x = self.mapPosX + self.mapSizeX / 2 + self.latencyOffsetX
	local y = self.mapPosY + self.mapSizeY + self.latencyOffsetY

	setTextColor(0, 0, 0, 1)
	renderText(x + 1 / g_screenWidth, y - 1 / g_screenHeight, self.latencyFontSize, text)
	setTextColor(unpack(color))
	renderText(x, y, self.latencyFontSize, text)
end

function IngameMapLayoutCircle:drawNorthArrow(rotation)
	local radiusX = self.mapSizeX / 2
	local radiusY = self.mapSizeY / 2
	local pivotX, pivotY = self.northElement:getRotationPivot()
	local centerX = self.mapPosX + radiusX
	local centerY = self.mapPosY + radiusY
	local cosRot = math.cos(rotation)
	local sinRot = math.sin(rotation)
	local posX = centerX + cosRot * radiusX - pivotX
	local posY = centerY + sinRot * radiusY - pivotY

	self.northElement:setPosition(posX, posY)
	self.northElement:setRotation(rotation - HALF_PI)
	self.northElement:draw()
end

function IngameMapLayoutCircle:setPlayerPosition(x, z, yRot)
	self.playerU = x * 0.5 + 0.25
	self.playerV = (1 - z) * 0.5 + 0.25
	self.playerRot = yRot
end

function IngameMapLayoutCircle:setPlayerVelocity(speed)
	self.velocityZoomFactor = MathUtil.clamp(speed / 50, 0, 1)
end

function IngameMapLayoutCircle:setWorldSize(worldSizeX, worldSizeZ)
	self.worldSizeFactor = worldSizeX / 2048
end

function IngameMapLayoutCircle:setHasUnreadMessages(hasMessages)
	self.hasMessages = hasMessages
end

function IngameMapLayoutCircle:getMapPosition()
	local mapWidth, mapHeight = self:getMapSize()
	local playerScreenX = self.mapPosX + self.mapSizeX / 2
	local playerScreenY = self.mapPosY + self.mapSizeY / 2
	local offX = playerScreenX - self.playerU * mapWidth
	local offY = playerScreenY - self.playerV * mapHeight

	return offX, offY
end

function IngameMapLayoutCircle:getMapPivot()
	local mapWidth, mapHeight = self:getMapSize()

	return self.playerU * mapWidth, self.playerV * mapHeight
end

function IngameMapLayoutCircle:getMapRotation()
	return -self.playerRot
end

function IngameMapLayoutCircle:getMapSize()
	local width = (1 - 0.25 * self.velocityZoomFactor) * self.worldSizeFactor

	return width, width * g_screenAspectRatio
end

function IngameMapLayoutCircle:getMapAlpha()
	return 0.7
end

function IngameMapLayoutCircle:getShowsToggleAction()
	return false
end

function IngameMapLayoutCircle:getShowSmallIconVariation()
	return true
end

function IngameMapLayoutCircle:getShowsToggleActionText()
	return true
end

function IngameMapLayoutCircle:getIconZoom()
	return 0.5
end

function IngameMapLayoutCircle:getHeight()
	return self.mapSizeY
end

function IngameMapLayoutCircle:rotateWithMap(x, y, rot, lockToBorder)
	local angle = self:getMapRotation()
	local s = math.sin(angle)
	local c = math.cos(angle)
	local cx = self.mapPosX + self.mapSizeX / 2
	local cy = self.mapPosY + self.mapSizeY / 2
	x = (x - cx) * g_screenAspectRatio
	y = y - cy
	local xNew = x * c - y * s
	local yNew = x * s + y * c

	if lockToBorder then
		local length = math.sqrt(xNew * xNew + yNew * yNew)
		local neededLength = self.mapSizeY / 2
		local factor = math.min(neededLength / length, 1)
		xNew = xNew * factor
		yNew = yNew * factor
	end

	xNew = xNew / g_screenAspectRatio + cx
	yNew = yNew * 1 + cy

	return xNew, yNew, rot + angle
end

function IngameMapLayoutCircle:getMapObjectPosition(objectU, objectV, width, height, rot, persistent)
	local mapWidth, mapHeight = self:getMapSize()
	local mapX, mapY = self:getMapPosition()
	local objectX = objectU * mapWidth + mapX
	local objectY = (1 - objectV) * mapHeight + mapY
	objectX, objectY, rot = self:rotateWithMap(objectX, objectY, rot, persistent)
	objectX = objectX - width * 0.5
	objectY = objectY - height * 0.5
	local minX = self.mapPosX - 2 * width
	local maxX = self.mapPosX + self.mapSizeX + 2 * width
	local minY = self.mapPosY - 2 * height
	local maxY = self.mapPosY + self.mapSizeY + 2 * height

	if objectX < minX or maxX < objectX or objectY < minY or maxY < objectY then
		return 0, 0, 0, false
	end

	return objectX, objectY, rot, true
end

IngameMapLayoutCircle.SIZE = {
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
	},
	NORTH_ARROW = {
		9,
		7
	}
}
IngameMapLayoutCircle.TEXT_SIZE = {
	LATENCY = 10,
	COORDINATES = 14
}
IngameMapLayoutCircle.POSITION = {
	MAP = {
		10,
		10
	},
	COORDINATES = {
		0,
		12
	},
	LATENCY = {
		0,
		-12
	},
	UNREAD_MESSAGES = {
		3,
		221
	},
	UNREAD_MESSAGES_BG = {
		0,
		218
	},
	NORTH_ARROW = {
		0,
		100
	}
}
IngameMapLayoutCircle.PIVOT = {
	NORTH_ARROW = {
		5,
		0
	}
}
IngameMapLayoutCircle.UV = {
	BACKGROUND = {
		48,
		288,
		256,
		256
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
	},
	NORTH_ARROW = {
		480,
		296,
		9,
		7
	}
}
