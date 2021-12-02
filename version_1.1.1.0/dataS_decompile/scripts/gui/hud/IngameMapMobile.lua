IngameMapMobile = {}
local IngameMapMobile_mt = Class(IngameMapMobile, IngameMap)
IngameMapMobile.STATE_HIDDEN = 3

function IngameMapMobile.new(hud, hudAtlasPath, inputDisplayManager, customMt)
	local self = IngameMapMobile:superClass().new(hud, hudAtlasPath, inputDisplayManager, customMt or IngameMapMobile_mt)
	self.showPlayerCoordinates = false
	self.showMapLabel = false
	self.showInputIcon = false
	self.minMapWidth, self.minMapHeight = getNormalizedScreenValues(unpack(IngameMapMobile.SIZE.MAP))

	self:setSize(self.minMapWidth, self.minMapHeight)

	self.resizeTimer = 1
	self.maxMapHeight = self.minMapHeight
	self.maxMapWidth = self.minMapWidth
	self.currentOffsetX = 0
	self.player = nil
	self.state = IngameMapMobile.STATE_HIDDEN

	return self
end

function IngameMapMobile:createComponents(hudAtlasPath)
	local baseX, baseY = self:getPosition()
	local width = self:getWidth()
	local height = self:getHeight()

	self:createFrame(hudAtlasPath, baseX, baseY, width, height)
	self:createPlayerMapArrow()
	self:createOtherMapArrowOverlay()

	local halfCircleElement = self:createOverlayElement(IngameMapMobile.POSITION.HALF_CIRCLE, IngameMapMobile.SIZE.HALF_CIRCLE, IngameMapMobile.UV.HALF_CIRCLE, IngameMapMobile.COLOR.RIGHT_BORDER)

	self:addChild(halfCircleElement)

	local halfCircleIconElement = self:createOverlayElement(IngameMapMobile.POSITION.HALF_CIRCLE_ICON, IngameMapMobile.SIZE.HALF_CIRCLE_ICON, IngameMapMobile.UV.HALF_CIRCLE_ICON, IngameMapMobile.COLOR.MAP_ICON)

	self:addChild(halfCircleIconElement)

	local rightBorderElement = self:createOverlayElement(IngameMapMobile.POSITION.RIGHT_BORDER, IngameMapMobile.SIZE.RIGHT_BORDER, HUDElement.UV.FILL, IngameMapMobile.COLOR.RIGHT_BORDER)

	self:addChild(rightBorderElement)

	self.slideButtonDown = self.hud:addTouchButton(halfCircleElement.overlay, 1, 0.4, self.onSlideMapDown, self, TouchHandler.TRIGGER_DOWN)
	self.slideButtonAlways = self.hud:addTouchButton(halfCircleElement.overlay, 1, 0.4, self.onSlideMapAlways, self, TouchHandler.TRIGGER_ALWAYS)
	self.slideButtonUp = self.hud:addTouchButton(halfCircleElement.overlay, 1, 0.4, self.onSlideMapUp, self, TouchHandler.TRIGGER_UP)

	g_touchHandler:setAreaPressedSizeGain(self.slideButtonDown, 3.5)
	g_touchHandler:setAreaPressedSizeGain(self.slideButtonAlways, 3.5)
	g_touchHandler:setAreaPressedSizeGain(self.slideButtonUp, 3.5)

	self.buttonElement = halfCircleElement
end

function IngameMapMobile:setPlayer(player)
	self.player = player
end

function IngameMapMobile:onSlideMapDown(posX, posY)
	self.startTouchPosX = posX
	self.startPosX = self:getPosition()
end

function IngameMapMobile:onSlideMapAlways(posX, posY)
	self.currentOffsetX = posX - self.startTouchPosX
	local position = MathUtil.clamp(self.startPosX + self.currentOffsetX, self.mapHideWidth, 0)

	self:setPosition(position, nil)
end

function IngameMapMobile:onSlideMapUp(posX, posY)
	if self.currentOffsetX ~= 0 then
		local curX = self:getPosition()
		self.resizeTimer = 1 - curX / self.mapHideWidth

		self:toggleSize(self.startTouchPosX - posX < 0 and IngameMap.STATE_MINIMAP or IngameMapMobile.STATE_HIDDEN, true)

		self.currentOffsetX = 0
	else
		self:toggleSize()
	end
end

function IngameMapMobile:createOverlayElement(pos, size, uvs, color)
	local baseX, baseY = self:getPosition()
	local posX, posY = getNormalizedScreenValues(unpack(pos))
	local sizeX, sizeY = getNormalizedScreenValues(unpack(size))
	local overlay = Overlay.new(self.hudAtlasPath, baseX + posX, baseY + posY, sizeX, sizeY)

	overlay:setUVs(GuiUtils.getUVs(uvs))
	overlay:setColor(unpack(color))

	return HUDElement.new(overlay)
end

function IngameMapMobile:storeScaledValues(uiScale)
	IngameMapMobile:superClass().storeScaledValues(self, uiScale)

	self.minMapWidth, self.minMapHeight = self:scalePixelToScreenVector(IngameMapMobile.SIZE.MAP)
	self.mapSizeX, self.mapSizeY = self:scalePixelToScreenVector(IngameMapMobile.SIZE.MAP)
	self.mapOffsetX, self.mapOffsetY = self:scalePixelToScreenVector(IngameMapMobile.POSITION.MAP)
	self.mapHideWidth = self:scalePixelToScreenVector(IngameMapMobile.SIZE.MAP_HIDE_WIDTH)
	self.mapToFrameDiffY = self:scalePixelToScreenHeight(IngameMapMobile.SIZE.SELF[2] - IngameMapMobile.SIZE.MAP[2])
	self.mapToFrameDiffX = self:scalePixelToScreenWidth(IngameMapMobile.SIZE.SELF[1] - IngameMapMobile.SIZE.MAP[1])
end

function IngameMapMobile:resetSettings()
	IngameMapMobile:superClass().resetSettings(self)

	if self.overlay == nil then
		return
	end

	if self.state ~= IngameMap.STATE_MAP then
		self:setPosition(self.mapHideWidth * (1 - self.resizeTimer), nil)
	end
end

function IngameMapMobile:updateMapAnimation(dt)
	if self.resizeDir ~= 0 then
		local deltaTime = dt

		if not self.isVisible then
			deltaTime = self.resizeTime * 2
		end

		self.resizeTimer = MathUtil.clamp(self.resizeTimer + deltaTime / 1000 * self.resizeDir, 0, 1)

		self:setPosition(self.mapHideWidth * (1 - self.resizeTimer), nil)

		if self.resizeTimer == 0 or self.resizeTimer == 1 then
			self.resizeDir = 0
		end
	end
end

function IngameMapMobile:toggleSize(state, force)
	if state == nil then
		if self.state == IngameMap.STATE_MINIMAP then
			state = IngameMapMobile.STATE_HIDDEN
		else
			state = IngameMap.STATE_MINIMAP
		end
	end

	IngameMapMobile:superClass().toggleSize(self, state, force)

	if self.state == IngameMapMobile.STATE_HIDDEN then
		self.resizeDir = -1
	else
		self.resizeDir = 1
	end
end

function IngameMapMobile:setFullscreen(isFullscreen)
	IngameMapMobile:superClass().setFullscreen(self, isFullscreen)

	if isFullscreen then
		self.state = IngameMapMobile.STATE_HIDDEN
		self.resizeDir = 0
		self.resizeTimer = 0

		self:setPosition(self.mapHideWidth * (1 - self.resizeTimer), nil)
	end
end

function IngameMapMobile:getBackgroundPosition()
	local widthOffset, _ = getNormalizedScreenValues(unpack(IngameMapMobile.SIZE.MAP_HIDE_WIDTH))
	local _, height = getNormalizedScreenValues(unpack(IngameMapMobile.SIZE.SELF))

	if self.player ~= nil then
		return widthOffset, 0.598611 - height / 2
	end

	return widthOffset, 0.5 - height / 2
end

function IngameMapMobile:createBackground()
	local width, height = getNormalizedScreenValues(unpack(IngameMapMobile.SIZE.SELF))
	local posX, posY = self:getBackgroundPosition()

	return Overlay.new(nil, posX, posY, width, height)
end

function IngameMapMobile:createFrame(hudAtlasPath, baseX, baseY, width, height)
	local frame = HUDFrameElement.new(hudAtlasPath, baseX, baseY, width, height, nil, false, IngameMapMobile.FRAME_THICKNESS)

	frame:setFrameColor(unpack(IngameMapMobile.COLOR.FRAME))

	self.mapFrameElement = frame

	self:addChild(frame)
end

IngameMapMobile.MIN_MAP_WIDTH = 464
IngameMapMobile.MIN_MAP_HEIGHT = 470
IngameMapMobile.FRAME_THICKNESS = 2
IngameMapMobile.SIZE = {
	MAP = {
		IngameMapMobile.MIN_MAP_WIDTH,
		IngameMapMobile.MIN_MAP_HEIGHT
	},
	SELF = {
		IngameMapMobile.MIN_MAP_WIDTH + IngameMapMobile.FRAME_THICKNESS * 2,
		IngameMapMobile.MIN_MAP_HEIGHT + IngameMapMobile.FRAME_THICKNESS
	},
	RIGHT_BORDER = {
		4,
		IngameMapMobile.MIN_MAP_HEIGHT + IngameMapMobile.FRAME_THICKNESS
	},
	HALF_CIRCLE = {
		83,
		165
	},
	HALF_CIRCLE_ICON = {
		48,
		96
	},
	MAP_HIDE_WIDTH = {
		-IngameMapMobile.MIN_MAP_WIDTH - IngameMapMobile.FRAME_THICKNESS * 2 - 4,
		0
	}
}
IngameMapMobile.POSITION = {
	MAP = {
		IngameMapMobile.FRAME_THICKNESS,
		IngameMapMobile.FRAME_THICKNESS
	},
	RIGHT_BORDER = {
		IngameMapMobile.FRAME_THICKNESS + IngameMapMobile.MIN_MAP_WIDTH,
		0
	},
	HALF_CIRCLE = {
		IngameMapMobile.FRAME_THICKNESS + IngameMapMobile.SIZE.RIGHT_BORDER[1] + IngameMapMobile.MIN_MAP_WIDTH,
		IngameMapMobile.MIN_MAP_HEIGHT / 2 - IngameMapMobile.SIZE.HALF_CIRCLE[2] / 2
	},
	HALF_CIRCLE_ICON = {
		IngameMapMobile.FRAME_THICKNESS + IngameMapMobile.SIZE.RIGHT_BORDER[1] + IngameMapMobile.MIN_MAP_WIDTH + 12,
		IngameMapMobile.MIN_MAP_HEIGHT / 2 - IngameMapMobile.SIZE.HALF_CIRCLE_ICON[2] / 2
	}
}
IngameMapMobile.UV = {
	HALF_CIRCLE = {
		102,
		589,
		83,
		165
	},
	HALF_CIRCLE_ICON = {
		600,
		240,
		48,
		96
	}
}
IngameMapMobile.COLOR = {
	RIGHT_BORDER = {
		0.991,
		0.3865,
		0.01,
		1
	},
	MAP_ICON = {
		1,
		1,
		1,
		1
	},
	FRAME = {
		0.098039,
		0.098039,
		0.098039,
		1
	}
}
