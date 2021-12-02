SpeakerDisplay = {}
local SpeakerDisplay_mt = Class(SpeakerDisplay, HUDDisplayElement)
SpeakerDisplay.SHADOW_OFFSET_FACTOR = 0.05

function SpeakerDisplay.new(hudAtlasPath, ingameMap)
	local backgroundOverlay = SpeakerDisplay.createBackground(hudAtlasPath)
	local self = SpeakerDisplay:superClass().new(backgroundOverlay, nil, SpeakerDisplay_mt)
	self.ingameMap = ingameMap
	self.maxNumPlayers = g_serverMaxClientCapacity
	self.users = {}
	self.isMenuVisible = true
	self.isInfoWindowVisible = false
	self.isSpeedometerVisible = false
	self.userSpeaking = {}
	self.userAway = {}
	self.userTiming = {}
	self.userVisibility = {}
	self.currentSpeakers = {}
	self.lastVoiceState = {}
	self.mapOffsetY = 0
	self.mapOffsetX = 0
	self.lineHeight = 0
	self.lineWidth = 0
	self.textLineOffsetY = 0
	self.textLineOffsetX = 0
	self.textSize = 0
	self.textOffsetY = 0
	self.shadowOffset = 0

	self:storeScaledValues()
	self:createComponents(hudAtlasPath)

	return self
end

function SpeakerDisplay:delete()
	self.speakerIconOverlay:delete()
	self.speakerIconOverlayMuted:delete()
	self.speakerIconOverlayAway:delete()
	SpeakerDisplay:superClass().delete(self)
end

function SpeakerDisplay:setUsers(users)
	self.users = users
	self.userSpeaking = {}
	self.userAway = {}
	self.userTiming = {}
	self.userVisibility = {}
	self.currentSpeakers = {}
	self.lastVoiceState = {}
end

function SpeakerDisplay:onMenuVisibilityChange(isMenuVisible, isOverlayMenu)
	self.isMenuVisible = isMenuVisible and not isOverlayMenu
	self.isMenuMapVisible = self.isMenuMapVisible and isMenuVisible

	self:updateVisibility()
end

function SpeakerDisplay:onDetailViewVisibilityChange(isSpeedometerVisible, isInfoWindowVisible)
	self.isSpeedometerVisible = isSpeedometerVisible
	self.isInfoWindowVisible = isInfoWindowVisible

	self:updateVisibility()
end

function SpeakerDisplay:getHeight()
	return #self.currentSpeakers * (self.lineHeight + self.lineSpacing)
end

function SpeakerDisplay:updateSpeakingState(dt)
	for _, user in pairs(self.users) do
		local uuid = user:getUniqueUserId()
		local wasSpeakingLastFrame = self.userSpeaking[uuid]
		local isSpeakingNow = VoiceChatUtil.getIsSpeakerActive(uuid) and not user:getIsBlocked()

		if wasSpeakingLastFrame and not isSpeakingNow then
			self.userTiming[uuid] = 500
		elseif isSpeakingNow and not wasSpeakingLastFrame then
			self.userTiming[uuid] = 250
		end

		self.userSpeaking[uuid] = isSpeakingNow

		if self.userTiming[uuid] ~= nil then
			self.userTiming[uuid] = self.userTiming[uuid] - dt

			if self.userTiming[uuid] <= 0 then
				self.userTiming[uuid] = nil

				if self.userSpeaking[uuid] and not self.userVisibility[uuid] then
					table.insert(self.currentSpeakers, user)

					self.userVisibility[uuid] = true
				elseif not self.userSpeaking[uuid] and self.userVisibility[uuid] then
					table.removeElement(self.currentSpeakers, user)

					self.userVisibility[uuid] = false
				end
			end
		end

		if Platform.isStadia then
			local state = voiceChatGetConnectionStatus(uuid)

			if self.lastVoiceState ~= state then
				if state == VoiceChatConnectionStatus.UNAVAILABLE then
					self.userAway[user] = 2000

					table.removeElement(self.currentSpeakers, user)

					self.userVisibility[uuid] = false
				else
					self.userAway[user] = nil
				end

				self.lastVoiceState[uuid] = state
			end

			if self.userAway[user] ~= nil then
				self.userAway[user] = self.userAway[user] - dt

				if self.userAway[user] <= 0 then
					self.userAway[user] = nil
				end
			end
		end
	end
end

function SpeakerDisplay:updateVisibility()
	self:setVisible(true)
end

function SpeakerDisplay:update(dt)
	SpeakerDisplay:superClass().update(self, dt)
	self:updateSpeakingState(dt)
	self:updateVisibility()

	if not self.isMenuVisible then
		if self.isSpeedometerVisible then
			local _, y = g_currentMission.hud.speedMeter:getPosition()
			local h = g_currentMission.hud.speedMeter:getHeight()

			self:setPosition(nil, y + h)
		else
			local h = g_currentMission.hud.infoDisplay:getDisplayHeight()

			self:setPosition(nil, g_safeFrameMajorOffsetY + h)
		end
	else
		self:setPosition(nil, g_safeFrameMajorOffsetY)
	end
end

function SpeakerDisplay:draw()
	if self:getVisible() then
		new2DLayer()
		SpeakerDisplay:superClass().draw(self)
		setTextBold(true)
		setTextAlignment(RenderText.ALIGN_RIGHT)

		local posX, posY = self:getPosition()

		local function drawItem(index, user, isMuted, isAway)
			local name = utf8ToUpper(user:getNickname())
			local lineY = posY + (index - 1) * (self.lineHeight + self.lineSpacing)
			local width = getTextWidth(self.textSize, name) + math.abs(self.textOffsetX) + self.linePadding

			drawFilledRect(posX - width, lineY, width, self.lineHeight, unpack(SpeakerDisplay.COLOR.BACKGROUND))

			local textX = posX + self.textOffsetX
			local textY = lineY + (self.lineHeight - self.textSize) * 0.5 + self.textOffsetY

			setTextColor(unpack(SpeakerDisplay.COLOR.NAME_SHADOW))
			renderText(textX + self.shadowOffset, textY - self.shadowOffset, self.textSize, name)
			setTextColor(unpack(SpeakerDisplay.COLOR.NAME))
			renderText(textX, textY, self.textSize, name)

			if isAway then
				renderOverlay(self.speakerIconOverlayAway.overlayId, posX - self.linePadding - self.iconWidth, lineY + (self.lineHeight - self.iconHeight) * 0.5, self.iconWidth, self.iconHeight)
			elseif isMuted then
				renderOverlay(self.speakerIconOverlayMuted.overlayId, posX - self.linePadding - self.iconWidth, lineY + (self.lineHeight - self.iconHeight) * 0.5, self.iconWidth, self.iconHeight)
			else
				renderOverlay(self.speakerIconOverlay.overlayId, posX - self.linePadding - self.iconWidth, lineY + (self.lineHeight - self.iconHeight) * 0.5, self.iconWidth, self.iconHeight)
			end
		end

		for i = 1, #self.currentSpeakers do
			local user = self.currentSpeakers[i]

			drawItem(i, user, user:getVoiceMuted(), false)
		end

		local i = #self.currentSpeakers

		for user, _ in pairs(self.userAway) do
			i = i + 1

			drawItem(i, user, user:getVoiceMuted(), true)
		end
	end
end

function SpeakerDisplay:setScale(uiScale)
	SpeakerDisplay:superClass().setScale(self, uiScale)
	self:storeScaledValues()
end

function SpeakerDisplay.getBackgroundPosition(uiScale)
	local offX, offY = getNormalizedScreenValues(unpack(SpeakerDisplay.POSITION.SELF))

	return 1 - g_safeFrameMajorOffsetX + offX, g_safeFrameMajorOffsetY + offY
end

function SpeakerDisplay:storeScaledValues()
	self.positionXHUD, self.positionYHUD = self:scalePixelToScreenVector(SpeakerDisplay.POSITION.SELF)
	self.positionXMenu, self.positionYMenu = self:scalePixelToScreenVector(SpeakerDisplay.POSITION.SELF_MENU)
	self.lineWidth, self.lineHeight = self:scalePixelToScreenVector(SpeakerDisplay.SIZE.LINE)
	self.lineSpacing = self:scalePixelToScreenHeight(SpeakerDisplay.POSITION.LINE_SPACING[2])
	self.linePadding = self:scalePixelToScreenWidth(SpeakerDisplay.POSITION.LINE_PADDING[1])
	self.iconWidth, self.iconHeight = self:scalePixelToScreenVector(SpeakerDisplay.SIZE.SPEAKER_ICON)
	self.textOffsetX, self.textOffsetY = self:scalePixelToScreenVector(SpeakerDisplay.POSITION.NAME)
	self.textSize = self:scalePixelToScreenHeight(SpeakerDisplay.TEXT_SIZE.NAME)
	self.shadowOffset = SpeakerDisplay.SHADOW_OFFSET_FACTOR * self.textSize
end

function SpeakerDisplay.createBackground(hudAtlasPath)
	local posX, posY = SpeakerDisplay.getBackgroundPosition(1)
	local width, height = getNormalizedScreenValues(unpack(SpeakerDisplay.SIZE.SELF))
	local overlay = Overlay.new(nil, posX, posY, width, height)

	return overlay
end

function SpeakerDisplay:createComponents(hudAtlasPath)
	local baseX, baseY = SpeakerDisplay.getBackgroundPosition(1)
	local offX, offY = self:scalePixelToScreenVector(SpeakerDisplay.POSITION.SPEAKER_ICON)
	local iconWidth, iconHeight = self:scalePixelToScreenVector(SpeakerDisplay.SIZE.SPEAKER_ICON)
	local overlay = Overlay.new(hudAtlasPath, 0, 0, iconWidth, iconHeight)

	overlay:setUVs(GuiUtils.getUVs(SpeakerDisplay.UV.SPEAKER_ICON))
	overlay:setColor(unpack(SpeakerDisplay.COLOR.SPEAKER_ICON))

	self.speakerIconOverlay = overlay
	overlay = Overlay.new(hudAtlasPath, 0, 0, iconWidth, iconHeight)

	overlay:setUVs(GuiUtils.getUVs(SpeakerDisplay.UV.SPEAKER_ICON_MUTED))
	overlay:setColor(unpack(SpeakerDisplay.COLOR.SPEAKER_ICON_MUTED))

	self.speakerIconOverlayMuted = overlay
	overlay = Overlay.new(hudAtlasPath, 0, 0, iconWidth, iconHeight)

	overlay:setUVs(GuiUtils.getUVs(SpeakerDisplay.UV.SPEAKER_ICON_AWAY))
	overlay:setColor(unpack(SpeakerDisplay.COLOR.SPEAKER_ICON_AWAY))

	self.speakerIconOverlayAway = overlay
end

SpeakerDisplay.UV = {
	LINE = {
		8,
		8,
		2,
		2
	},
	SPEAKER_ICON = {
		102,
		102,
		36,
		36
	},
	SPEAKER_ICON_MUTED = {
		317,
		146,
		36,
		36
	},
	SPEAKER_ICON_AWAY = {
		257,
		52,
		36,
		36
	}
}
SpeakerDisplay.TEXT_SIZE = {
	NAME = 16
}
SpeakerDisplay.SIZE = {
	SELF = {
		290,
		168
	},
	LINE = {
		290,
		28
	},
	SPEAKER_ICON = {
		24,
		24
	}
}
SpeakerDisplay.POSITION = {
	SELF = {
		0,
		200
	},
	SELF_MENU = {
		0,
		0
	},
	LINE_SPACING = {
		0,
		6
	},
	LINE_PADDING = {
		4,
		0
	},
	SPEAKER_ICON = {
		0,
		0
	},
	NAME = {
		-36,
		0
	}
}
SpeakerDisplay.COLOR = {
	BACKGROUND = {
		0,
		0,
		0,
		0.75
	},
	SPEAKER_ICON = {
		1,
		1,
		1,
		0.5
	},
	SPEAKER_ICON_MUTED = {
		1,
		1,
		1,
		0.5
	},
	SPEAKER_ICON_AWAY = {
		1,
		1,
		1,
		0.5
	},
	NAME = {
		1,
		1,
		1,
		1
	},
	NAME_SHADOW = {
		0,
		0,
		0,
		0.75
	}
}
