HUDTextDisplay = {}
local HUDTextDisplay_mt = Class(HUDTextDisplay, HUDDisplayElement)
HUDTextDisplay.SHADOW_OFFSET_FACTOR = 0.05

function HUDTextDisplay.new(posX, posY, textSize, textAlignment, textColor, textBold)
	local backgroundOverlay = Overlay.new(nil, 0, 0, 0, 0)

	backgroundOverlay:setColor(1, 1, 1, 1)

	local self = HUDTextDisplay:superClass().new(backgroundOverlay, nil, HUDTextDisplay_mt)
	self.initialPosX = posX
	self.initialPosY = posY
	self.text = ""
	self.textSize = textSize or 0
	self.screenTextSize = self:scalePixelToScreenHeight(self.textSize)
	self.textAlignment = textAlignment or RenderText.ALIGN_LEFT
	self.textColor = textColor or {
		1,
		1,
		1,
		1
	}
	self.textBold = textBold or false
	self.hasShadow = false
	self.shadowColor = {
		0,
		0,
		0,
		1
	}

	return self
end

function HUDTextDisplay:setText(text, textSize, textAlignment, textColor, textBold)
	self.text = text or self.text
	self.textSize = textSize or self.textSize
	self.screenTextSize = self:scalePixelToScreenHeight(self.textSize)
	self.textAlignment = textAlignment or self.textAlignment
	self.textColor = textColor or self.textColor
	self.textBold = textBold or self.textBold
	local width = getTextWidth(self.screenTextSize, self.text)
	local height = getTextHeight(self.screenTextSize, self.text)

	self:setDimension(width, height)

	local posX = self.initialPosX
	local posY = self.initialPosY

	self:setPosition(posX, posY)
end

function HUDTextDisplay:setScale(uiScale)
	HUDTextDisplay:superClass().setScale(self, uiScale)

	self.screenTextSize = self:scalePixelToScreenHeight(self.textSize)
end

function HUDTextDisplay:setVisible(isVisible, animate)
	HUDElement.setVisible(self, isVisible)

	if animate then
		if not isVisible or not self.animation:getFinished() then
			self.animation:reset()
		end

		if isVisible then
			self.animation:start()
		end
	end
end

function HUDTextDisplay:setAlpha(alpha)
	self:setColor(nil, , , alpha)
end

function HUDTextDisplay:setTextColorChannels(r, g, b, a)
	self.textColor[1] = r
	self.textColor[2] = g
	self.textColor[3] = b
	self.textColor[4] = a
end

function HUDTextDisplay:setTextShadow(isShadowEnabled, shadowColor)
	self.hasShadow = isShadowEnabled or self.hasShadow
	self.shadowColor = shadowColor or self.shadowColor
end

function HUDTextDisplay:setAnimation(animationTween)
	self:storeOriginalPosition()

	self.animation = animationTween or TweenSequence.NO_SEQUENCE
end

function HUDTextDisplay:update(dt)
	if self:getVisible() then
		HUDTextDisplay:superClass().update(self, dt)
	end
end

function HUDTextDisplay:draw()
	setTextBold(self.textBold)

	local posX, posY = self:getPosition()

	setTextAlignment(self.textAlignment)
	setTextWrapWidth(0.9)

	if self.hasShadow then
		local offset = self.screenTextSize * HUDTextDisplay.SHADOW_OFFSET_FACTOR
		local r, g, b, a = unpack(self.shadowColor)

		setTextColor(r, g, b, a * self.overlay.a)
		renderText(posX + offset, posY - offset, self.screenTextSize, self.text)
	end

	local r, g, b, a = unpack(self.textColor)

	setTextColor(r, g, b, a * self.overlay.a)
	renderText(posX, posY, self.screenTextSize, self.text)
	setTextAlignment(RenderText.ALIGN_LEFT)
	setTextWrapWidth(0)
	setTextBold(false)
	setTextColor(1, 1, 1, 1)
end
