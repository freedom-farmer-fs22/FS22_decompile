ChatWindow = {}
local ChatWindow_mt = Class(ChatWindow, HUDDisplayElement)
ChatWindow.MAX_NUM_MESSAGES = 10
ChatWindow.DISPLAY_DURATION = 15000
ChatWindow.SHADOW_OFFSET_FACTOR = 0.05

function ChatWindow.new(hudAtlasPath, speakerDisplay)
	local backgroundOverlay = ChatWindow.createBackground(hudAtlasPath)
	local self = ChatWindow:superClass().new(backgroundOverlay, nil, ChatWindow_mt)
	self.speakerDisplay = speakerDisplay
	self.maxLines = ChatWindow.MAX_NUM_MESSAGES
	self.messages = {}
	self.historyNum = 50
	self.scrollOffset = 0
	self.hideTime = 0
	self.messageOffsetY = 0
	self.messageOffsetX = 0
	self.textSize = 0
	self.textOffsetY = 0
	self.lineOffset = 0
	self.shadowOffset = 0
	self.isMenuVisible = false
	self.newMessageDuringMenu = false

	self:storeScaledValues()

	return self
end

function ChatWindow:setVisible(isVisible, animate)
	if isVisible then
		if not self.isMenuVisible then
			self.newMessageDuringMenu = false
		end

		if self:getVisible() then
			return
		end

		ChatWindow:superClass().setVisible(self, true, false)

		if animate then
			self.hideTime = ChatWindow.DISPLAY_DURATION
		else
			self.hideTime = -1
		end
	else
		self.hideTime = self:getVisible() and ChatWindow.DISPLAY_DURATION or 0
	end
end

function ChatWindow:scrollChatMessages(delta)
	self.scrollOffset = math.max(0, math.min(self.scrollOffset + delta * self.textSize * 1.1, #self.messages * self.textSize * 2.5 - self:getHeight()))
end

function ChatWindow:addMessage(msg, sender, farmId)
	while self.historyNum <= #self.messages do
		table.remove(self.messages, 1)
	end

	table.insert(self.messages, {
		msg = msg,
		sender = sender,
		farmId = farmId
	})

	if self.isMenuVisible and not self:getVisible() then
		self.newMessageDuringMenu = true
	end
end

function ChatWindow:onMenuVisibilityChange(isMenuVisible)
	self.isMenuVisible = isMenuVisible

	if self:getVisible() then
		self.newMessageDuringMenu = false
	end
end

function ChatWindow:getHasNewMessages()
	return self.newMessageDuringMenu
end

function ChatWindow:update(dt)
	ChatWindow:superClass().update(self, dt)

	if self.hideTime >= 0 then
		self.hideTime = self.hideTime - dt

		if self.hideTime <= 0 then
			ChatWindow:superClass().setVisible(self, false, false)
		end
	end
end

function ChatWindow:draw()
	if self:getVisible() and (not self.isMenuVisible or g_gui.currentGuiName == "ChatDialog") and #self.messages > 0 then
		if g_gui.currentGuiName == "ChatDialog" then
			ChatWindow:superClass().draw(self)
		end

		local baseX, baseY = self:getPosition()

		setTextClipArea(baseX, baseY, baseX + self:getWidth(), baseY + self:getHeight())

		local posX = baseX + self.messageOffsetX
		local posY = baseY + self.messageOffsetY
		local lineHeight = self.textSize + self.lineOffset

		setTextWrapWidth(self:getWidth() - self.messageOffsetX * 2)
		setTextAlignment(RenderText.ALIGN_LEFT)

		local currentY = posY - self.scrollOffset

		for i = #self.messages, 1, -1 do
			local sender = self.messages[i].sender .. ":"
			local text = self.messages[i].msg
			local textHeight, numLines = getTextHeight(self.textSize, text)
			currentY = currentY + textHeight

			setTextBold(false)
			setTextColor(unpack(ChatWindow.COLOR.MESSAGE_SHADOW))
			renderText(posX + self.shadowOffset, currentY - self.shadowOffset, self.textSize, text)
			setTextColor(unpack(ChatWindow.COLOR.MESSAGE))
			renderText(posX, currentY, self.textSize, text)

			currentY = currentY + self.textSize

			setTextBold(true)
			setTextColor(unpack(ChatWindow.COLOR.MESSAGE_SHADOW))
			renderText(posX + self.shadowOffset, currentY - self.shadowOffset, self.textSize, sender)

			if self.messages[i].farmId ~= 0 then
				setTextColor(unpack(g_farmManager:getFarmById(self.messages[i].farmId):getColor()))
			else
				setTextColor(unpack(ChatWindow.COLOR.MESSAGE))
			end

			renderText(posX, currentY, self.textSize, sender)

			currentY = currentY + self.textSize * 0.5

			if currentY > posY + self:getHeight() then
				break
			end
		end

		setTextWrapWidth(0)
		setTextClipArea(0, 0, 1, 1)
		setTextBold(false)
	end
end

function ChatWindow:setScale(uiScale)
	ChatWindow:superClass().setScale(self, uiScale)
	self:storeScaledValues()
end

function ChatWindow.getBackgroundPosition(uiScale)
	local offX, offY = getNormalizedScreenValues(unpack(ChatWindow.POSITION.SELF))

	return g_safeFrameMajorOffsetX + offX, g_safeFrameMajorOffsetY + offY
end

function ChatWindow:storeScaledValues()
	self.messageOffsetX, self.messageOffsetY = self:scalePixelToScreenVector(ChatWindow.POSITION.MESSAGE)
	self.textSize = self:scalePixelToScreenHeight(ChatWindow.TEXT_SIZE.MESSAGE)
	self.textOffsetY = self.textSize * 0.15
	self.lineOffset = self.textSize * 0.3
	self.shadowOffset = ChatWindow.SHADOW_OFFSET_FACTOR * self.textSize
end

function ChatWindow.createBackground(hudAtlasPath)
	local posX, posY = ChatWindow.getBackgroundPosition(1)
	local width, height = getNormalizedScreenValues(unpack(ChatWindow.SIZE.SELF))
	local overlay = Overlay.new(hudAtlasPath, posX, posY, width, height)

	overlay:setUVs(GuiUtils.getUVs(HUD.UV.AREA))
	setOverlayCornerColor(overlay.overlayId, 0, 0, 0, 0, 0.9)
	setOverlayCornerColor(overlay.overlayId, 1, 0, 0, 0, 0.9)
	setOverlayCornerColor(overlay.overlayId, 2, 0, 0, 0, 0.4)
	setOverlayCornerColor(overlay.overlayId, 3, 0, 0, 0, 0.4)

	overlay.visible = false

	return overlay
end

ChatWindow.TEXT_SIZE = {
	MESSAGE = 16
}
ChatWindow.SIZE = {
	SELF = {
		560,
		380
	}
}
ChatWindow.POSITION = {
	SELF = {
		0,
		300
	},
	MESSAGE = {
		8,
		8
	}
}
ChatWindow.COLOR = {
	BACKGROUND = {
		1,
		1,
		1,
		1
	},
	MESSAGE = {
		1,
		1,
		1,
		1
	},
	MESSAGE_SHADOW = {
		0,
		0,
		0,
		0.75
	}
}
