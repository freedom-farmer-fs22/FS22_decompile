HUDFrameElement = {}
local HUDFrameElement_mt = Class(HUDFrameElement, HUDElement)

function HUDFrameElement.new(hudAtlasPath, posX, posY, width, height, parent, showBar, frameThickness, barThickness)
	local backgroundOverlay = Overlay.new(hudAtlasPath, posX, posY, width, height)

	backgroundOverlay:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
	backgroundOverlay:setColor(0, 0, 0, 0)

	local self = HUDElement.new(backgroundOverlay, parent, HUDFrameElement_mt)
	self.topLine = nil
	self.leftLine = nil
	self.rightLine = nil
	self.bottomBar = nil
	self.frameHeight = 0
	self.frameWidth = 0
	self.showBar = Utils.getNoNil(showBar, true)
	self.frameThickness = frameThickness or HUDFrameElement.THICKNESS.FRAME
	self.barThickness = barThickness or HUDFrameElement.THICKNESS.BAR

	self:createComponents(hudAtlasPath, posX, posY, width, height)

	return self
end

function HUDFrameElement:createComponents(hudAtlasPath, baseX, baseY, width, height)
	local refPixelX = 1 / g_referenceScreenWidth
	local refPixelY = 1 / g_referenceScreenHeight
	local screenPixelX = 1 / g_screenWidth
	local screenPixelY = 1 / g_screenHeight
	local onePixelX = math.max(refPixelX, screenPixelX)
	local onePixelY = math.max(refPixelY, screenPixelY)
	local posX = baseX
	local posY = baseY + self:getHeight()
	local frameWidth, frameHeight = getNormalizedScreenValues(self.frameThickness, self.frameThickness)
	local pixelsX = math.ceil(frameWidth / onePixelX)
	local pixelsY = math.ceil(frameHeight / onePixelY)
	self.frameHeight = pixelsY * onePixelY
	self.frameWidth = pixelsX * onePixelX
	local lineOverlay = Overlay.new(hudAtlasPath, posX, posY - self.frameHeight, width, self.frameHeight)

	lineOverlay:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
	lineOverlay:setColor(unpack(HUDFrameElement.COLOR.FRAME))

	local lineElement = HUDElement.new(lineOverlay)
	self.topLine = lineElement

	self:addChild(lineElement)

	posY = baseY + self.frameHeight
	posX = baseX
	lineOverlay = Overlay.new(hudAtlasPath, posX, posY, self.frameWidth, height - self.frameHeight * 2)

	lineOverlay:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
	lineOverlay:setColor(unpack(HUDFrameElement.COLOR.FRAME))

	lineElement = HUDElement.new(lineOverlay)
	self.leftLine = lineElement

	self:addChild(lineElement)

	posY = baseY + self.frameHeight
	posX = baseX + width - self.frameWidth
	lineOverlay = Overlay.new(hudAtlasPath, posX, posY, self.frameWidth, height - self.frameHeight * 2)

	lineOverlay:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
	lineOverlay:setColor(unpack(HUDFrameElement.COLOR.FRAME))

	lineElement = HUDElement.new(lineOverlay)
	self.rightLine = lineElement

	self:addChild(lineElement)

	local barSize = self.barThickness
	local barColor = HUDFrameElement.COLOR.BAR

	if not self.showBar then
		barSize = self.frameThickness
		barColor = HUDFrameElement.COLOR.FRAME
	end

	local _, barHeight = getNormalizedScreenValues(0, barSize)
	pixelsY = math.ceil(barHeight / onePixelY)
	local barOverlay = Overlay.new(hudAtlasPath, baseX, baseY, width, pixelsY * onePixelY)

	barOverlay:setUVs(GuiUtils.getUVs(HUDElement.UV.FILL))
	barOverlay:setColor(unpack(barColor))

	local barElement = HUDElement.new(barOverlay)
	self.bottomBar = barElement

	self:addChild(barElement)
end

function HUDFrameElement:setDimension(width, height)
	HUDFrameElement:superClass().setDimension(self, width, height)

	local lineHeight = nil

	if height ~= nil then
		lineHeight = height - self.frameHeight * 2
	end

	self.topLine:setDimension(width, nil)
	self.leftLine:setDimension(nil, lineHeight)
	self.rightLine:setDimension(nil, lineHeight)
	self.bottomBar:setDimension(width, nil)

	local x, y = self:getPosition()

	self.topLine:setPosition(nil, y + self:getHeight() - self.frameHeight)
	self.rightLine:setPosition(x + self:getWidth() - self.frameWidth, nil)
end

function HUDFrameElement:setBottomBarHeight(height)
	self.bottomBar:setDimension(nil, height)
end

function HUDFrameElement:setBottomBarColor(r, g, b, a)
	self.bottomBar:setColor(r, g, b, a)
end

function HUDFrameElement:setLeftLineVisible(visible)
	self.leftLine:setVisible(visible)
end

function HUDFrameElement:setRightLineVisible(visible)
	self.rightLine:setVisible(visible)
end

function HUDFrameElement:setFrameColor(r, g, b, a)
	self.topLine:setColor(r, g, b, a)
	self.leftLine:setColor(r, g, b, a)
	self.rightLine:setColor(r, g, b, a)
	self.bottomBar:setColor(r, g, b, a)
end

HUDFrameElement.THICKNESS = {
	FRAME = 1,
	BAR = 4
}
HUDFrameElement.COLOR = {
	FRAME = {
		1,
		1,
		1,
		0.3
	},
	BAR = {
		0.991,
		0.3865,
		0.01,
		1
	}
}
