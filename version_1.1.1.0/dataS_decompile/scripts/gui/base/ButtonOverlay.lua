ButtonOverlay = {}
local ButtonOverlay_mt = Class(ButtonOverlay)

function ButtonOverlay.new()
	local self = {}

	setmetatable(self, ButtonOverlay_mt)

	local atlasRefSize = {
		1024,
		1024
	}
	local uBase = 101
	local vBase = 100
	local height = 40
	local width = 37
	local sideWidth = 5
	self.textSizeFactor = 0.47
	self.textYOffsetFactor = 0.125
	self.buttonScaleOverlay = Overlay.new(g_baseUIFilename, 0, 0, 0, 0)

	self.buttonScaleOverlay:setUVs(GuiUtils.getUVs({
		uBase + sideWidth,
		vBase,
		1,
		height
	}, atlasRefSize))

	self.buttonLeftOverlay = Overlay.new(g_baseUIFilename, 0, 0, 0, 0)

	self.buttonLeftOverlay:setUVs(GuiUtils.getUVs({
		uBase,
		vBase,
		sideWidth,
		height
	}, atlasRefSize))

	self.buttonLeftRatio = sideWidth * 0.5 / width
	self.buttonRightOverlay = Overlay.new(g_baseUIFilename, 0, 0, 0, 0)

	self.buttonRightOverlay:setUVs(GuiUtils.getUVs({
		uBase + width - sideWidth,
		vBase,
		sideWidth,
		height
	}, atlasRefSize))

	self.buttonRightRatio = sideWidth * 0.5 / width

	self:setColor(0.0723, 0.0723, 0.0723, 1)

	self.debugEnabled = false

	return self
end

function ButtonOverlay:delete()
	if self.buttonScaleOverlay ~= 0 then
		self.buttonScaleOverlay:delete()
	end

	if self.buttonLeftOverlay ~= 0 then
		self.buttonLeftOverlay:delete()
	end

	if self.buttonRightOverlay ~= 0 then
		self.buttonRightOverlay:delete()
	end
end

function ButtonOverlay:setColor(r, g, b, a)
	self.r = Utils.getNoNil(r, self.r)
	self.g = Utils.getNoNil(g, self.g)
	self.b = Utils.getNoNil(b, self.b)
	self.a = Utils.getNoNil(a, self.a)

	if self.buttonScaleOverlay ~= 0 then
		setOverlayColor(self.buttonScaleOverlay.overlayId, self.r, self.g, self.b, self.a)
	end

	if self.buttonLeftOverlay ~= 0 then
		setOverlayColor(self.buttonLeftOverlay.overlayId, self.r, self.g, self.b, self.a)
	end

	if self.buttonRightOverlay ~= 0 then
		setOverlayColor(self.buttonRightOverlay.overlayId, self.r, self.g, self.b, self.a)
	end
end

function ButtonOverlay:renderButton(buttonText, posX, posY, height, alignment, colorText)
	alignment = Utils.getNoNil(alignment, RenderText.ALIGN_LEFT)
	local totalWidth, textWidth, leftButtonWidth, rightButtonWidth, textSize = self:getButtonWidth(buttonText, height)
	local pos = posX

	self.buttonLeftOverlay:setDimension(leftButtonWidth, height)
	self.buttonScaleOverlay:setDimension(textWidth, height)
	self.buttonRightOverlay:setDimension(rightButtonWidth, height)

	if alignment == RenderText.ALIGN_RIGHT then
		pos = pos - (textWidth + leftButtonWidth + rightButtonWidth)
	elseif alignment == RenderText.ALIGN_CENTER then
		pos = pos - (textWidth + leftButtonWidth + rightButtonWidth) / 2
	end

	self.buttonLeftOverlay:setPosition(pos, posY)
	self.buttonLeftOverlay:render()

	pos = pos + leftButtonWidth

	if colorText then
		setTextColor(self.r, self.g, self.b, self.a)
	else
		setTextColor(1, 1, 1, self.a)
	end

	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_CENTER)

	local yCenter = posY + height * 0.5 - textSize * self.textSizeFactor

	renderText(pos + textWidth * 0.5, yCenter + textSize * self.textYOffsetFactor, textSize, utf8ToUpper(buttonText))
	setTextBold(false)
	setTextColor(1, 1, 1, 1)
	self.buttonScaleOverlay:setPosition(pos, posY)
	self.buttonScaleOverlay:render()

	pos = pos + textWidth

	self.buttonRightOverlay:setPosition(pos, posY)
	self.buttonRightOverlay:render()

	if self.debugEnabled or g_uiDebugEnabled then
		local xPixel = 1 / g_screenWidth
		local yPixel = 1 / g_screenHeight

		setOverlayColor(GuiElement.debugOverlay, 1, 0, 1, 0.5)
		renderOverlay(GuiElement.debugOverlay, posX - xPixel, posY - yPixel, totalWidth + 2 * xPixel, yPixel)
		renderOverlay(GuiElement.debugOverlay, posX - xPixel, posY + height, totalWidth + 2 * xPixel, yPixel)
		renderOverlay(GuiElement.debugOverlay, posX - xPixel, posY, xPixel, height)
		renderOverlay(GuiElement.debugOverlay, posX + totalWidth, posY, xPixel, height)
	end

	return totalWidth
end

function ButtonOverlay:getButtonWidth(buttonText, height)
	setTextBold(true)
	setTextAlignment(RenderText.ALIGN_LEFT)

	buttonText = utf8ToUpper(tostring(buttonText))
	local textSize = height * self.textSizeFactor
	local leftButtonWidth = self.buttonLeftRatio * height * g_aspectScaleX
	local rightButtonWidth = self.buttonRightRatio * height * g_aspectScaleX
	local textWidth = getTextWidth(textSize, buttonText) + 2 * leftButtonWidth
	local minWidth = height * g_screenHeight / g_screenWidth - leftButtonWidth - rightButtonWidth
	textWidth = math.max(textWidth, minWidth)

	setTextBold(false)

	local totalWidth = textWidth + leftButtonWidth + rightButtonWidth

	return totalWidth, textWidth, leftButtonWidth, rightButtonWidth, textSize
end
