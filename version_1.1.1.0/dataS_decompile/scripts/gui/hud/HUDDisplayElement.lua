HUDDisplayElement = {}
local HUDDisplayElement_mt = Class(HUDDisplayElement, HUDElement)
HUDDisplayElement.MOVE_ANIMATION_DURATION = 150

function HUDDisplayElement.new(overlay, parentHudElement, customMt)
	local self = HUDDisplayElement:superClass().new(overlay, parentHudElement, customMt or HUDDisplayElement_mt)
	self.origY = 0
	self.origX = 0
	self.animationState = nil

	return self
end

function HUDDisplayElement:setVisible(isVisible, animate)
	if animate and self.animation:getFinished() then
		if isVisible then
			self:animateShow()
		else
			self:animateHide()
		end
	else
		self.animation:stop()
		HUDDisplayElement:superClass().setVisible(self, isVisible)

		local posX, posY = self:getPosition()
		local transX, transY = self:getHidingTranslation()

		if isVisible then
			self:setPosition(self.origX, self.origY)
		else
			self:setPosition(posX + transX, posY + transY)
		end
	end

	self.animationState = isVisible
end

function HUDDisplayElement:setScale(uiScale)
	HUDDisplayElement:superClass().setScale(self, uiScale, uiScale)
end

function HUDDisplayElement:storeOriginalPosition()
	self.origX, self.origY = self:getPosition()
end

function HUDDisplayElement:getHidingTranslation()
	return 0, -0.5
end

function HUDDisplayElement:animationSetPositionX(x)
	self:setPosition(x, nil)
end

function HUDDisplayElement:animationSetPositionY(y)
	self:setPosition(nil, y)
end

function HUDDisplayElement:animateHide()
	local transX, transY = self:getHidingTranslation()
	local startX, startY = self:getPosition()
	local sequence = TweenSequence.new(self)

	sequence:insertTween(MultiValueTween.new(self.setPosition, {
		startX,
		startY
	}, {
		startX + transX,
		startY + transY
	}, HUDDisplayElement.MOVE_ANIMATION_DURATION), 0)
	sequence:addCallback(self.onAnimateVisibilityFinished, false)
	sequence:start()

	self.animation = sequence
end

function HUDDisplayElement:animateShow()
	HUDDisplayElement:superClass().setVisible(self, true)

	local startX, startY = self:getPosition()
	local sequence = TweenSequence.new(self)

	sequence:insertTween(MultiValueTween.new(self.setPosition, {
		startX,
		startY
	}, {
		self.origX,
		self.origY
	}, HUDDisplayElement.MOVE_ANIMATION_DURATION), 0)
	sequence:addCallback(self.onAnimateVisibilityFinished, true)
	sequence:start()

	self.animation = sequence
end

function HUDDisplayElement:onAnimateVisibilityFinished(isVisible)
	if not isVisible then
		HUDDisplayElement:superClass().setVisible(self, isVisible)
	end
end
