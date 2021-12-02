KeyValueInfoHUDBox = {}
local KeyValueInfoHUDBox_mt = Class(KeyValueInfoHUDBox, InfoHUDBox)

function KeyValueInfoHUDBox.new(uiScale)
	local self = InfoHUDBox.new(KeyValueInfoHUDBox_mt, uiScale)
	self.displayComponents = {}
	self.cachedLines = {}
	self.activeLines = {}

	return self
end

function KeyValueInfoHUDBox:canDraw()
	return self.doShowNextFrame
end

function KeyValueInfoHUDBox:getDisplayHeight()
	return 2 * self.listMarginHeight + #self.activeLines * self.rowHeight + self.labelTextSize + self.labelTextOffsetY
end

function KeyValueInfoHUDBox:draw(posX, posY)
	local rightX = posX
	local leftX = posX - self.boxWidth
	local y = posY
	local height = 2 * self.listMarginHeight + #self.activeLines * self.rowHeight

	drawFilledRect(leftX, y, self.boxWidth, height, 0, 0, 0, 0.75)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextColor(unpack(KeyValueInfoHUDBox.COLOR.TEXT_DEFAULT))
	setTextBold(true)
	renderText(leftX + self.labelTextOffsetX, y + height + self.labelTextOffsetY, self.titleTextSize, self.title)
	setTextBold(false)

	y = y + self.listMarginHeight
	leftX = leftX + self.leftTextOffsetX + self.listMarginWidth
	rightX = rightX - self.rightTextOffsetX - self.listMarginWidth

	for i = #self.activeLines, 1, -1 do
		local line = self.activeLines[i]

		setTextBold(true)

		if line.accentuate then
			setTextColor(unpack(KeyValueInfoHUDBox.COLOR.TEXT_HIGHLIGHT))
		end

		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(leftX, y + self.leftTextOffsetY, self.rowTextSize, line.key)
		setTextBold(false)
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(rightX, y + self.rightTextOffsetY, self.rowTextSize, line.value)

		if line.accentuate then
			setTextColor(unpack(KeyValueInfoHUDBox.COLOR.TEXT_DEFAULT))
		end

		if i < #self.activeLines then
			drawFilledRect(leftX, y, self.rowWidth, 1 / g_screenHeight, unpack(KeyValueInfoHUDBox.COLOR.SEPARATOR))
		end

		y = y + self.rowHeight
	end

	setTextAlignment(RenderText.ALIGN_LEFT)

	self.doShowNextFrame = false
end

function KeyValueInfoHUDBox:clear()
	for i = #self.activeLines, 1, -1 do
		self.cachedLines[#self.cachedLines + 1] = self.activeLines[i]
		self.activeLines[i] = nil
	end
end

function KeyValueInfoHUDBox:setTitle(title)
	title = utf8ToUpper(title)

	if title ~= self.title then
		self.title = title
		self.titleTextSize = self:textSizeToFit(self.labelTextSize, self.title, self.boxWidth)
	end
end

function KeyValueInfoHUDBox:textSizeToFit(baseSize, text, maxWidth, minSize)
	local size = baseSize

	if minSize == nil then
		minSize = baseSize / 2
	end

	setTextWrapWidth(maxWidth)

	local lengthWithNoLineLimit = getTextLength(size, text, 99999)

	while getTextLength(size, text, 1) < lengthWithNoLineLimit do
		size = size - baseSize * 0.05

		if size <= baseSize / 2 then
			size = size + baseSize * 0.05

			break
		end
	end

	setTextWrapWidth(0)

	return size
end

function KeyValueInfoHUDBox:addLine(key, value, accentuate)
	local line = nil
	local cached = self.cachedLines
	local numCached = #cached

	if numCached > 0 then
		line = self.cachedLines[numCached]
		self.cachedLines[numCached] = nil
	else
		line = {}
	end

	line.key = key
	line.value = value or ""
	line.accentuate = accentuate
	self.activeLines[#self.activeLines + 1] = line
end

function KeyValueInfoHUDBox:showNextFrame()
	self.doShowNextFrame = true
end

function KeyValueInfoHUDBox:setScale(uiScale)
	self.uiScale = uiScale

	self:storeScaledValues()
end

function KeyValueInfoHUDBox:storeScaledValues()
	local scale = self.uiScale

	local function normalize(x, y)
		return x * scale * g_aspectScaleX / g_referenceScreenWidth, y * scale * g_aspectScaleY / g_referenceScreenHeight
	end

	self.boxWidth = normalize(340, 0)
	local _ = nil
	_, self.labelTextSize = normalize(0, HUDElement.TEXT_SIZE.DEFAULT_TITLE)
	_, self.rowTextSize = normalize(0, HUDElement.TEXT_SIZE.DEFAULT_TEXT)
	self.titleTextSize = self.labelTextSize
	self.labelTextOffsetX, self.labelTextOffsetY = normalize(0, 3)
	self.leftTextOffsetX, self.leftTextOffsetY = normalize(0, 6)
	self.rightTextOffsetX, self.rightTextOffsetY = normalize(0, 6)
	self.rowWidth, self.rowHeight = normalize(308, 26)
	self.listMarginWidth, self.listMarginHeight = normalize(16, 15)
end

KeyValueInfoHUDBox.COLOR = {
	TEXT_DEFAULT = {
		1,
		1,
		1,
		1
	},
	TEXT_HIGHLIGHT = {
		0.0003,
		0.5647,
		0.9822,
		1
	},
	SEPARATOR = {
		1,
		1,
		1,
		0.2
	}
}
