SideNotification = {}
local SideNotification_mt = Class(SideNotification, HUDDisplayElement)
SideNotification.MAX_NOTIFICATIONS = 5
SideNotification.FADE_DURATION = 500

function SideNotification.new(customMt, hudAtlasPath)
	local self = SideNotification:superClass().new(nil, , customMt or SideNotification_mt)
	self.overlay = self:createBackground(hudAtlasPath)
	self.notificationQueue = {}
	self.textSize = 0
	self.textOffsetY = 0
	self.lineOffset = 0
	self.notificationMarginY = 0
	self.notificationMarginX = 0

	return self
end

function SideNotification:addNotification(text, color, displayDuration)
	local notification = {
		text = text,
		color = color,
		duration = displayDuration,
		startDuration = displayDuration
	}

	table.insert(self.notificationQueue, notification)
	self:updateSizeAndPositions()
end

function SideNotification:update(dt)
	local hasRemoval = false

	for i = math.min(#self.notificationQueue, SideNotification.MAX_NOTIFICATIONS), 1, -1 do
		local notification = self.notificationQueue[i]

		if notification.duration <= 0 then
			table.remove(self.notificationQueue, i)

			hasRemoval = true
		else
			notification.duration = math.max(0, notification.duration - dt)
		end
	end

	if hasRemoval then
		self:updateSizeAndPositions()
	end
end

function SideNotification:draw()
	if self:getVisible() and #self.notificationQueue > 0 then
		SideNotification:superClass().draw(self)

		local baseX, baseY = self:getPosition()
		local width = self:getWidth()
		local height = self:getHeight()
		local offsetX = 1 / g_screenWidth
		local offsetY = 1 / g_screenHeight
		local notificationX = baseX + width - self.notificationMarginX
		local notificationY = baseY + height - self.textSize - self.notificationMarginY
		local _, _, _, alpha = self:getColor()

		for i = 1, math.min(#self.notificationQueue, SideNotification.MAX_NOTIFICATIONS) do
			local notification = self.notificationQueue[i]
			local fadeAlpha = 1

			if notification.startDuration - notification.duration < SideNotification.FADE_DURATION then
				fadeAlpha = (notification.startDuration - notification.duration) / SideNotification.FADE_DURATION
			elseif notification.duration < SideNotification.FADE_DURATION then
				fadeAlpha = notification.duration / SideNotification.FADE_DURATION
			end

			setTextBold(false)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			setTextColor(0, 0, 0, alpha * fadeAlpha)
			renderText(notificationX + offsetX, notificationY - offsetY + self.textOffsetY, self.textSize, notification.text)
			setTextColor(notification.color[1], notification.color[2], notification.color[3], notification.color[4] * alpha * fadeAlpha)
			renderText(notificationX, notificationY + self.textOffsetY, self.textSize, notification.text)

			notificationY = notificationY - self.textSize - self.lineOffset
		end

		setTextColor(1, 1, 1, 1)
	end
end

function SideNotification.getBackgroundPosition(uiScale)
	local offX, offY = getNormalizedScreenValues(unpack(SideNotification.POSITION.SELF))

	return 1 - g_safeFrameOffsetX + offX * uiScale, 1 - g_safeFrameOffsetY + offY * uiScale
end

function SideNotification:setScale(uiScale)
	SideNotification:superClass().setScale(self, uiScale)
	self:updateSizeAndPositions()
end

function SideNotification:updateSizeAndPositions()
	local numLines = math.min(#self.notificationQueue, SideNotification.MAX_NOTIFICATIONS)
	local height = numLines * self.textSize + (numLines - 1) * self.lineOffset + self.notificationMarginY * 2
	local width = self:getWidth()

	self:setDimension(width, height)

	local topRightX, topRightY = SideNotification.getBackgroundPosition(self:getScale())
	local bottomY = topRightY - self:getHeight()

	self:setPosition(topRightX - width, bottomY)
	self:storeScaledValues()
end

function SideNotification:storeScaledValues()
	self.textSize = self:scalePixelToScreenHeight(SideNotification.TEXT_SIZE.DEFAULT_NOTIFICATION)
	self.textOffsetY = self.textSize * 0.15
	self.lineOffset = self.textSize * 0.3
	self.notificationMarginX, self.notificationMarginY = self:scalePixelToScreenVector(SideNotification.SIZE.NOTIFICATION_MARGIN)
end

function SideNotification:createBackground(hudAtlasPath)
	local posX, posY = SideNotification.getBackgroundPosition(1)
	local width, height = getNormalizedScreenValues(unpack(SideNotification.SIZE.SELF))
	local overlay = Overlay.new(hudAtlasPath, posX - width, posY - height, width, height)

	overlay:setUVs(GuiUtils.getUVs(SideNotification.UV.DEFAULT_BACKGROUND))
	overlay:setColor(unpack(SideNotification.COLOR.DEFAULT_BACKGROUND))

	return overlay
end

function SideNotification:createComponents(hudAtlasPath)
end

SideNotification.UV = {
	DEFAULT_BACKGROUND = {
		16,
		840,
		152,
		1
	}
}
SideNotification.POSITION = {
	SELF = {
		0,
		-80
	}
}
SideNotification.SIZE = {
	SELF = {
		264,
		144
	},
	NOTIFICATION_MARGIN = {
		6,
		12
	}
}
SideNotification.COLOR = {
	DEFAULT_BACKGROUND = {
		1,
		1,
		1,
		1
	}
}
SideNotification.TEXT_SIZE = {
	DEFAULT_NOTIFICATION = 21
}
