InfoDisplay = {}
local InfoDisplay_mt = Class(InfoDisplay, HUDDisplayElement)

function InfoDisplay.new(hudAtlasPath)
	local backgroundOverlay = InfoDisplay.createBackground(hudAtlasPath)
	local self = InfoDisplay:superClass().new(backgroundOverlay, nil, InfoDisplay_mt)
	self.isEnabled = true
	self.boxMarginY = 0
	self.boxes = {}

	return self
end

function InfoDisplay:delete()
	InfoDisplay:superClass().delete(self)
end

function InfoDisplay:setEnabled(isEnabled)
	self.isEnabled = isEnabled
end

function InfoDisplay:createBox(class)
	local box = class.new(self.uiScale)

	table.insert(self.boxes, box)

	return box
end

function InfoDisplay:destroyBox(box)
	table.removeElement(self.boxes, box)
	box:delete()
end

function InfoDisplay:update(dt)
	InfoDisplay:superClass().update(self, dt)

	if self.isEnabled then
		self:updateSize()
	end
end

function InfoDisplay:updateSize()
	local height = 0

	for i = 1, #self.boxes do
		local box = self.boxes[i]

		if box:canDraw() then
			height = height + box:getDisplayHeight() + self.boxMarginY
		end
	end

	self.totalHeight = height
end

function InfoDisplay:getDisplayHeight()
	if self.isEnabled then
		return self.totalHeight
	else
		return 0
	end
end

function InfoDisplay:draw()
	if not self.isEnabled then
		return
	end

	InfoDisplay:superClass().draw(self)

	local posX = 1 - g_safeFrameOffsetX
	local posY = g_safeFrameOffsetY

	for i = #self.boxes, 1, -1 do
		local box = self.boxes[i]

		if box:canDraw() then
			box:draw(posX, posY)

			posY = posY + box:getDisplayHeight() + self.boxMarginY
		end
	end
end

function InfoDisplay.getBackgroundPosition(uiScale)
	local width, _ = getNormalizedScreenValues(unpack(InfoDisplay.SIZE.SELF))
	local posX = 1 - g_safeFrameOffsetX - width * uiScale
	local posY = g_safeFrameOffsetY

	return posX, posY
end

function InfoDisplay:setScale(uiScale)
	InfoDisplay:superClass().setScale(self, uiScale, uiScale)

	self.uiScale = uiScale

	self:storeScaledValues()

	for _, box in ipairs(self.boxes) do
		self:setScale(uiScale)
	end
end

function InfoDisplay:storeScaledValues()
	self.boxMarginY = self:scalePixelToScreenHeight(InfoDisplay.SIZE.BOX_MARGIN)
end

function InfoDisplay.createBackground()
	local posX, posY = InfoDisplay.getBackgroundPosition(1)
	local width, height = getNormalizedScreenValues(unpack(InfoDisplay.SIZE.SELF))
	local overlay = Overlay.new(g_baseUIFilename, posX, posY, width, height)

	overlay:setUVs(g_colorBgUVs)
	overlay:setColor(1, 0, 0, 0.75)

	return overlay
end

InfoDisplay.SIZE = {
	BOX_MARGIN = 20,
	SELF = {
		340,
		160
	}
}
