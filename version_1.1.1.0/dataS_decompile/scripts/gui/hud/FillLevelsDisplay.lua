FillLevelsDisplay = {}
local FillLevelsDisplay_mt = Class(FillLevelsDisplay, HUDDisplayElement)

function FillLevelsDisplay.new(hudAtlasPath)
	local backgroundOverlay = FillLevelsDisplay.createBackground()
	local self = FillLevelsDisplay:superClass().new(backgroundOverlay, nil, FillLevelsDisplay_mt)
	self.uiScale = 1
	self.hudAtlasPath = hudAtlasPath
	self.vehicle = nil
	self.fillLevelBuffer = {}
	self.fillLevelTextBuffer = {}
	self.fillTypeTextBuffer = {}
	self.fillTypeFrames = {}
	self.fillTypeLevelBars = {}
	self.weightFrames = {}
	self.frameHeight = 0
	self.fillLevelTextSize = 0
	self.fillLevelTextOffsetX = 0
	self.fillLevelTextOffsetY = 0

	return self
end

local function clearTable(table)
	for i = #table, 1, -1 do
		table[i] = nil
	end
end

local function sortBuffer(a, b)
	return a.addIndex < b.addIndex
end

function FillLevelsDisplay:setVehicle(vehicle)
	self.vehicle = vehicle
end

function FillLevelsDisplay:addFillLevel(fillType, fillLevel, capacity, precision, maxReached)
	local added = false

	for j = 1, #self.fillLevelBuffer do
		local fillLevelInformation = self.fillLevelBuffer[j]

		if fillLevelInformation.fillType == fillType then
			fillLevelInformation.fillLevel = fillLevelInformation.fillLevel + fillLevel
			fillLevelInformation.capacity = fillLevelInformation.capacity + capacity
			fillLevelInformation.precision = precision
			fillLevelInformation.maxReached = maxReached

			if self.addIndex ~= fillLevelInformation.addIndex then
				fillLevelInformation.addIndex = self.addIndex
				self.needsSorting = true
			end

			added = true

			break
		end
	end

	if not added then
		table.insert(self.fillLevelBuffer, {
			fillType = fillType,
			fillLevel = fillLevel,
			capacity = capacity,
			precision = precision,
			addIndex = self.addIndex,
			maxReached = maxReached
		})

		self.needsSorting = true
	end

	self.addIndex = self.addIndex + 1
end

function FillLevelsDisplay:updateFillLevelBuffers()
	clearTable(self.fillLevelTextBuffer)
	clearTable(self.fillTypeTextBuffer)

	for i = 1, #self.fillLevelBuffer do
		local fillLevelInformation = self.fillLevelBuffer[i]
		local frame = self.fillTypeFrames[fillLevelInformation.fillType]

		frame:setVisible(false)
	end

	for i = 1, #self.fillLevelBuffer do
		self.fillLevelBuffer[i].fillLevel = 0
		self.fillLevelBuffer[i].capacity = 0
	end

	self.addIndex = 0
	self.needsSorting = false

	self.vehicle:getFillLevelInformation(self)

	if self.needsSorting then
		table.sort(self.fillLevelBuffer, sortBuffer)
	end
end

function FillLevelsDisplay:updateFillLevelFrames()
	local _, yOffset = self:getPosition()
	local isFirst = true

	for i = 1, #self.fillLevelBuffer do
		local fillLevelInformation = self.fillLevelBuffer[i]

		if fillLevelInformation.capacity > 0 or fillLevelInformation.fillLevel > 0 then
			local value = 0

			if fillLevelInformation.capacity > 0 then
				value = fillLevelInformation.fillLevel / fillLevelInformation.capacity
			end

			local frame = self.fillTypeFrames[fillLevelInformation.fillType]

			frame:setVisible(true)

			local fillBar = self.fillTypeLevelBars[fillLevelInformation.fillType]

			fillBar:setValue(value)

			local baseX = self:getPosition()

			if isFirst then
				baseX = baseX + self.firstFillTypeOffset
			end

			frame:setPosition(baseX, yOffset)

			local precision = fillLevelInformation.precision or 0
			local formattedNumber = nil

			if precision > 0 then
				local rounded = MathUtil.round(fillLevelInformation.fillLevel, precision)
				formattedNumber = string.format("%d%s%0" .. precision .. "d", math.floor(rounded), g_i18n.decimalSeparator, (rounded - math.floor(rounded)) * 10^precision)
			else
				formattedNumber = string.format("%d", MathUtil.round(fillLevelInformation.fillLevel))
			end

			self.weightFrames[fillLevelInformation.fillType]:setVisible(fillLevelInformation.maxReached)

			local fillTypeName, unitShort = nil

			if fillLevelInformation.fillType ~= FillType.UNKNOWN then
				local fillTypeDesc = g_fillTypeManager:getFillTypeByIndex(fillLevelInformation.fillType)
				fillTypeName = fillTypeDesc.title
				unitShort = fillTypeDesc.unitShort
			end

			local fillText = string.format("%s%s (%d%%)", formattedNumber, unitShort or "", math.floor(100 * value))
			self.fillLevelTextBuffer[#self.fillLevelTextBuffer + 1] = fillText

			if fillTypeName ~= nil then
				self.fillTypeTextBuffer[#self.fillLevelTextBuffer] = fillTypeName
			end

			yOffset = yOffset + self.frameHeight + self.frameOffsetY
			isFirst = false
		end
	end
end

function FillLevelsDisplay:update(dt)
	FillLevelsDisplay:superClass().update(self, dt)

	if self.vehicle ~= nil then
		self:updateFillLevelBuffers()

		if #self.fillLevelBuffer > 0 then
			if not self:getVisible() and self.animation:getFinished() then
				self:setVisible(true, true)
			end

			self:updateFillLevelFrames()
		elseif self:getVisible() and self.animation:getFinished() then
			self:setVisible(false, true)
		end
	end
end

function FillLevelsDisplay:draw()
	FillLevelsDisplay:superClass().draw(self)

	if self:getVisible() then
		local baseX, baseY = self:getPosition()
		local width = self:getWidth()

		for i = 1, #self.fillLevelTextBuffer do
			local fillLevelText = self.fillLevelTextBuffer[i]
			local posX = baseX + width + self.fillLevelTextOffsetX
			local posY = baseY + (i - 1) * (self.frameHeight + self.frameOffsetY)

			if i == 1 then
				posX = posX + self.firstFillTypeOffset
			end

			setTextColor(unpack(FillLevelsDisplay.COLOR.FILL_LEVEL_TEXT))
			setTextBold(false)
			setTextAlignment(RenderText.ALIGN_RIGHT)
			renderText(posX, posY + self.fillLevelTextOffsetY, self.fillLevelTextSize, fillLevelText)
		end
	end
end

function FillLevelsDisplay:setScale(uiScale)
	FillLevelsDisplay:superClass().setScale(self, uiScale, uiScale)

	local currentVisibility = self:getVisible()

	self:setVisible(true, false)

	self.uiScale = uiScale
	local posX, posY = FillLevelsDisplay.getBackgroundPosition(uiScale, self:getWidth())

	self:setPosition(posX, posY)
	self:storeOriginalPosition()
	self:setVisible(currentVisibility, false)
	self:storeScaledValues()
end

function FillLevelsDisplay.getBackgroundPosition(scale, width)
	local x, y = unpack(FillLevelsDisplay.POSITION.BACKGROUND)
	x = x - 80 + 80 / scale
	local offX, offY = getNormalizedScreenValues(x, y)

	return 1 - g_safeFrameOffsetX - width - offX * scale, g_safeFrameOffsetY + offY * scale
end

function FillLevelsDisplay:storeScaledValues()
	self.fillLevelTextSize = self:scalePixelToScreenHeight(HUDElement.TEXT_SIZE.DEFAULT_TEXT)
	self.fillLevelTextOffsetX, self.fillLevelTextOffsetY = self:scalePixelToScreenVector(FillLevelsDisplay.POSITION.FILL_LEVEL_TEXT)
	self.fillTypeTextOffsetX, self.fillTypeTextOffsetY = self:scalePixelToScreenVector(FillLevelsDisplay.POSITION.FILL_TYPE_TEXT)
	local _ = nil
	_, self.frameHeight = self:scalePixelToScreenVector(FillLevelsDisplay.SIZE.FILL_TYPE_FRAME)
	_, self.frameOffsetY = self:scalePixelToScreenVector(FillLevelsDisplay.POSITION.FILL_TYPE_FRAME_MARGIN)
	self.firstFillTypeOffset = self:scalePixelToScreenVector(FillLevelsDisplay.POSITION.FIRST_FILL_TYPE_OFFSET)
end

function FillLevelsDisplay.createBackground()
	local width, height = getNormalizedScreenValues(unpack(FillLevelsDisplay.SIZE.BACKGROUND))
	local posX, posY = FillLevelsDisplay.getBackgroundPosition(1, width)

	return Overlay.new(nil, posX, posY, width, height)
end

function FillLevelsDisplay:refreshFillTypes(fillTypeManager)
	for _, v in pairs(self.fillTypeFrames) do
		v:delete()
	end

	clearTable(self.fillTypeFrames)
	clearTable(self.fillTypeLevelBars)

	local posX, posY = self:getPosition()

	self:createFillTypeFrames(fillTypeManager, self.hudAtlasPath, posX, posY)
end

function FillLevelsDisplay:createFillTypeFrames(fillTypeManager, hudAtlasPath, baseX, baseY)
	for _, fillType in ipairs(fillTypeManager:getFillTypes()) do
		local frame = self:createFillTypeFrame(hudAtlasPath, baseX, baseY, fillType)
		self.fillTypeFrames[fillType.index] = frame

		frame:setScale(self.uiScale, self.uiScale)
		self:addChild(frame)
	end
end

function FillLevelsDisplay:createFillTypeFrame(hudAtlasPath, baseX, baseY, fillType)
	local frameWidth, frameHeight = self:scalePixelToScreenVector(FillLevelsDisplay.SIZE.FILL_TYPE_FRAME)
	local frameX, frameY = self:scalePixelToScreenVector(FillLevelsDisplay.POSITION.FILL_TYPE_FRAME)
	local posX = baseX + frameX
	local posY = baseY + frameY
	local frameOverlay = Overlay.new(nil, posX, posY, frameWidth, frameHeight)
	local frame = HUDElement.new(frameOverlay)

	frame:setVisible(false)
	self:createFillTypeIcon(frame, posX, posY, fillType)
	self:createFillTypeBar(hudAtlasPath, frame, posX, posY, fillType)

	local weightWidth, weightHeight = getNormalizedScreenValues(unpack(FillLevelsDisplay.SIZE.WEIGHT_LIMIT))
	local weightOffsetX, weightOffsetY = getNormalizedScreenValues(unpack(FillLevelsDisplay.POSITION.WEIGHT_LIMIT))
	local weightOverlay = Overlay.new(hudAtlasPath, posX + weightOffsetX, posY + weightOffsetY, weightWidth, weightHeight)

	weightOverlay:setUVs(GuiUtils.getUVs(FillLevelsDisplay.UV.WEIGHT_LIMIT))

	local weightFrame = HUDElement.new(weightOverlay)

	frame:addChild(weightFrame)

	self.weightFrames[fillType.index] = weightFrame

	return frame
end

function FillLevelsDisplay:createFillTypeIcon(frame, baseX, baseY, fillType)
	if fillType.hudOverlayFilename ~= "" then
		local baseWidth = self:getWidth()
		local width, height = getNormalizedScreenValues(unpack(FillLevelsDisplay.SIZE.FILL_TYPE_ICON))
		local posX, posY = getNormalizedScreenValues(unpack(FillLevelsDisplay.POSITION.FILL_TYPE_ICON))
		local backdropOverlay = Overlay.new(self.hudAtlasPath, baseX + posX, baseY + posY, width, height)

		backdropOverlay:setColor(unpack(FillLevelsDisplay.COLOR.FILL_TYPE_BACKDROP))
		backdropOverlay:setUVs(GuiUtils.getUVs(FillLevelsDisplay.UV.FILL_ICON_BACKDROP))

		local backdrop = HUDElement.new(backdropOverlay)

		frame:addChild(backdrop)

		local iconOverlay = Overlay.new(fillType.hudOverlayFilename, baseX + posX, baseY + posY, width, height)

		iconOverlay:setColor(unpack(FillLevelsDisplay.COLOR.FILL_TYPE_ICON))
		backdrop:addChild(HUDElement.new(iconOverlay))
	end
end

function FillLevelsDisplay:createFillTypeBar(hudAtlasPath, frame, baseX, baseY, fillType)
	local width, height = getNormalizedScreenValues(unpack(FillLevelsDisplay.SIZE.BAR))
	local barX, barY = getNormalizedScreenValues(unpack(FillLevelsDisplay.POSITION.BAR))
	local posX = baseX + barX
	local posY = baseY + barY
	local element = HUDRoundedBarElement.new(hudAtlasPath, posX, posY, width, height, true)

	element:setBarColor(unpack(FillLevelsDisplay.COLOR.BAR_FILLED))
	frame:addChild(element)

	self.fillTypeLevelBars[fillType.index] = element
end

FillLevelsDisplay.SIZE = {
	BACKGROUND = {
		180,
		35
	},
	FILL_TYPE_FRAME = {
		180,
		35
	},
	BAR = {
		140,
		12
	},
	FILL_TYPE_ICON = {
		35,
		35
	},
	WEIGHT_LIMIT = {
		60,
		21
	}
}
FillLevelsDisplay.POSITION = {
	BACKGROUND = {
		350,
		8
	},
	FILL_TYPE_FRAME = {
		0,
		0
	},
	FILL_TYPE_FRAME_MARGIN = {
		0,
		10
	},
	BAR = {
		0,
		2
	},
	FIRST_FILL_TYPE_OFFSET = {
		20,
		0
	},
	FILL_TYPE_ICON = {
		145,
		0
	},
	FILL_LEVEL_TEXT = {
		-40,
		18
	},
	FILL_TYPE_TEXT = {
		-40,
		0
	},
	WEIGHT_LIMIT = {
		40,
		-2.5
	}
}
FillLevelsDisplay.COLOR = {
	BAR_FILLED = {
		0.0003,
		0.5647,
		0.9822
	},
	FILL_TYPE_ICON = {
		1,
		1,
		1,
		1
	},
	FILL_LEVEL_TEXT = {
		1,
		1,
		1,
		1
	},
	FILL_TYPE_BACKDROP = {
		0,
		0,
		0,
		0.54
	}
}
FillLevelsDisplay.UV = {
	FILL_ICON_BACKDROP = {
		431,
		64,
		48,
		48
	},
	WEIGHT_LIMIT = {
		192,
		52,
		60,
		21
	}
}
