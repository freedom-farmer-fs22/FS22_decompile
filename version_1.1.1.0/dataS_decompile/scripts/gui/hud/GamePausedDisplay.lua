GamePausedDisplay = {}
local GamePausedDisplay_mt = Class(GamePausedDisplay, HUDDisplayElement)

function GamePausedDisplay.new(hudAtlasPath)
	local backgroundOverlay = GamePausedDisplay.createBackground(hudAtlasPath)
	local self = GamePausedDisplay:superClass().new(backgroundOverlay, nil, GamePausedDisplay_mt)
	self.pauseText = ""
	self.isMenuVisible = false
	self.syncBackgroundElement = nil
	self.textSize = 0
	self.textOffsetY = 0
	self.textOffsetX = 0

	self:storeOriginalPosition()
	self:storeScaledValues()
	self:createComponents(hudAtlasPath)

	return self
end

function GamePausedDisplay:setPauseText(text)
	self.pauseText = text
end

function GamePausedDisplay:onMenuVisibilityChange(isMenuVisible, isOverlayMenu)
	local showFullscreen = isMenuVisible and not isOverlayMenu

	self.syncBackgroundElement:setVisible(showFullscreen)
end

function GamePausedDisplay:draw()
	if self:getVisible() then
		GamePausedDisplay:superClass().draw(self)

		local textHeight = getTextHeight(self.textSize, self.pauseText)
		local baseX, baseY = self:getPosition()
		local posX = baseX + self:getWidth() * 0.5 + self.textOffsetX
		local posY = baseY + (self:getHeight() - textHeight) * 0.5 + self.textOffsetY

		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextColor(unpack(GamePausedDisplay.COLOR.TEXT))
		renderText(posX, posY, self.textSize, self.pauseText)
	end
end

function GamePausedDisplay:setScale(uiScale)
	GamePausedDisplay:superClass().setScale(self, 1)
end

function GamePausedDisplay:storeScaledValues()
	self.textSize = self:scalePixelToScreenHeight(GamePausedDisplay.TEXT_SIZE.PAUSE_TEXT)
	self.textOffsetX, self.textOffsetY = self:scalePixelToScreenVector(GamePausedDisplay.POSITION.PAUSE_TEXT)
end

function GamePausedDisplay.createBackground(hudAtlasPath)
	local _, height = getNormalizedScreenValues(unpack(GamePausedDisplay.SIZE.SELF))
	local overlay = Overlay.new(hudAtlasPath, 0, (1 - height) * 0.5, 1, height)

	overlay:setUVs(GuiUtils.getUVs(GamePausedDisplay.UV.BACKGROUND))
	overlay:setColor(unpack(GamePausedDisplay.COLOR.BACKGROUND))

	return overlay
end

function GamePausedDisplay:createComponents(hudAtlasPath)
	local syncOverlay = Overlay.new(GamePausedDisplay.SYNC_SPLASH_PATH, 0, 0, 1, g_screenWidth / g_screenHeight)
	self.syncBackgroundElement = HUDElement.new(syncOverlay)

	self:addChild(self.syncBackgroundElement)
end

GamePausedDisplay.SYNC_SPLASH_PATH = "shared/splash.png"
GamePausedDisplay.UV = {
	BACKGROUND = {
		8,
		8,
		2,
		2
	}
}
GamePausedDisplay.SIZE = {
	SELF = {
		0,
		75
	}
}
GamePausedDisplay.POSITION = {
	PAUSE_TEXT = {
		0,
		3
	}
}
GamePausedDisplay.TEXT_SIZE = {
	PAUSE_TEXT = 24
}
GamePausedDisplay.COLOR = {
	BACKGROUND = {
		0,
		0,
		0,
		0.75
	},
	TEXT = {
		1,
		1,
		1,
		1
	}
}
