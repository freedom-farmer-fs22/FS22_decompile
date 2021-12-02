Graph = {}
local Graph_mt = Class(Graph)
Graph.STYLE_BARS = 0
Graph.STYLE_LINES = 1

function Graph.new(numValues, left, bottom, width, height, minValue, maxValue, showLabels, textExtra, graphStyle, verticalStep, verticalLabel)
	local self = {}

	setmetatable(self, Graph_mt)

	self.values = {}
	self.lowValues = {}
	self.numValues = numValues
	self.nextIndex = 1
	self.overlayId = createImageOverlay("dataS/scripts/shared/graph_pixel.png")
	self.left = left
	self.bottom = bottom
	self.width = width
	self.height = height
	self.minValue = minValue
	self.maxValue = maxValue
	self.textExtra = textExtra
	self.showLabels = showLabels
	self.graphStyle = graphStyle
	self.textSize = getCorrectTextSize(0.011)

	if self.graphStyle == nil then
		self.graphStyle = Graph.STYLE_BARS
	end

	return self
end

function Graph:delete()
	delete(self.overlayId)

	if self.overlayBg ~= nil then
		delete(self.overlayBg)
	end

	if self.overlayHLine ~= nil then
		delete(self.overlayHLine)
	end

	if self.overlayVLine ~= nil then
		delete(self.overlayVLine)
	end
end

function Graph:setColor(r, g, b, a)
	setOverlayColor(self.overlayId, r, g, b, a)
end

function Graph:setBackgroundColor(r, g, b, a)
	if r == nil then
		if self.overlayBg ~= nil then
			delete(self.overlayBg)

			self.overlayBg = nil
		end
	else
		if self.overlayBg == nil then
			self.overlayBg = createImageOverlay("dataS/scripts/shared/graph_pixel.png")
		end

		setOverlayColor(self.overlayBg, r, g, b, a)
	end
end

function Graph:setHorizontalLine(stepSize, showLabel, r, g, b, a)
	if stepSize == nil or stepSize <= 0 then
		if self.overlayHLine ~= nil then
			delete(self.overlayHLine)

			self.overlayHLine = nil
		end
	else
		if self.overlayHLine == nil then
			self.overlayHLine = createImageOverlay("dataS/scripts/shared/graph_pixel.png")
		end

		setOverlayColor(self.overlayHLine, r, g, b, a)

		self.hLineStepSize = stepSize
		self.hLineShowLabel = showLabel
	end
end

function Graph:setVerticalLine(stepSize, showLabel, r, g, b, a)
	if stepSize == nil or stepSize <= 0 then
		if self.overlayVLine ~= nil then
			delete(self.overlayVLine)

			self.overlayVLine = nil
		end
	else
		if self.overlayVLine == nil then
			self.overlayVLine = createImageOverlay("dataS/scripts/shared/graph_pixel.png")
		end

		setOverlayColor(self.overlayVLine, r, g, b, a)

		self.vLineStepSize = stepSize
		self.vLineShowLabel = showLabel
	end
end

function Graph:addValue(value, lowValue, fillFromRight)
	if fillFromRight then
		for i = 1, self.numValues - 1 do
			self.values[i] = self.values[i + 1]
			self.lowValues[i] = self.lowValues[i + 1]
		end

		self.values[self.numValues] = value
		self.lowValues[self.numValues] = lowValue
	else
		self.values[self.nextIndex] = value
		self.lowValues[self.nextIndex] = lowValue
		self.nextIndex = self.nextIndex + 1

		if self.numValues < self.nextIndex then
			self.nextIndex = 1
		end
	end
end

function Graph:setValue(index, value, lowValue)
	index = (index + self.nextIndex - 2) % self.numValues + 1
	self.values[index] = value
	self.lowValues[index] = lowValue
end

function Graph:setXPosition(index, posX)
	index = (index + self.nextIndex - 2) % self.numValues + 1

	if self.xPositions == nil then
		self.xPositions = {}
	end

	self.xPositions[index] = posX
end

function Graph:draw()
	if self.overlayBg ~= nil then
		renderOverlay(self.overlayBg, self.left, self.bottom, self.width, self.height)
	end

	if self.overlayHLine ~= nil then
		local v = 0

		while v <= self.maxValue do
			local y = self.bottom + v / self.maxValue * self.height

			renderOverlay(self.overlayHLine, self.left, y, self.width, 1 / g_screenHeight)

			if self.hLineShowLabel then
				setTextAlignment(RenderText.ALIGN_RIGHT)
				renderText(self.left - 0.005, y, self.textSize, string.format("%1.2f", self.minValue + v) .. self.textExtra)
				setTextAlignment(RenderText.ALIGN_LEFT)
			end

			v = v + self.hLineStepSize
		end
	end

	if self.overlayVLine ~= nil then
		local v = 0
		local numValues = #self.values

		while v <= numValues do
			local x = self.left + v / numValues * self.width

			renderOverlay(self.overlayHLine, x, self.bottom, 1 / g_screenWidth, self.height)

			if self.vLineShowLabel and v % self.vLineStepSize == 0 then
				setTextAlignment(RenderText.ALIGN_CENTER)
				renderText(x, self.bottom - self.textSize - 0.005, self.textSize, tostring(v))
				setTextAlignment(RenderText.ALIGN_LEFT)
			end

			v = v + 1
		end
	end

	local hasValues = false
	local prevValue, prevPosX = nil

	for i = self.nextIndex, self.numValues do
		local posX = nil

		if self.xPositions ~= nil then
			posX = self.left + self.width * self.xPositions[i]
		else
			posX = self.left + self.width * (i - self.nextIndex) / (self.numValues - 1)
		end

		if self.values[i] ~= nil then
			if self.graphStyle == Graph.STYLE_BARS then
				self:drawBar(posX, self.values[i], self.lowValues[i])

				hasValues = true
			elseif self.graphStyle == Graph.STYLE_LINES then
				if prevValue ~= nil then
					self:drawLine(prevPosX, posX, prevValue, self.values[i])

					hasValues = true
				end

				prevPosX = posX
				prevValue = self.values[i]
			end
		end
	end

	for i = 1, self.nextIndex - 1 do
		local posX = nil

		if self.xPositions ~= nil then
			posX = self.left + self.width * self.xPositions[i]
		else
			posX = self.left + self.width * (self.numValues - self.nextIndex + i) / (self.numValues - 1)
		end

		if self.values[i] ~= nil then
			if self.graphStyle == Graph.STYLE_BARS then
				self:drawBar(posX, self.values[i], self.lowValues[i])

				hasValues = true
			elseif self.graphStyle == Graph.STYLE_LINES then
				if prevValue ~= nil then
					self:drawLine(prevPosX, posX, prevValue, self.values[i])

					hasValues = true
				end

				prevPosX = posX
				prevValue = self.values[i]
			end
		end
	end

	if hasValues and self.showLabels then
		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(self.left - 0.005, self.bottom, self.textSize, string.format("%1.2f", self.minValue) .. self.textExtra)
		renderText(self.left - 0.005, self.bottom + self.height, self.textSize, string.format("%1.2f", self.maxValue) .. self.textExtra)
		setTextAlignment(RenderText.ALIGN_LEFT)
	end
end

function Graph:drawBar(posX, value, lowValue)
	local height = 0.002

	if lowValue ~= nil then
		height = self.height / (self.maxValue - self.minValue) * (value - lowValue)
	end

	if height > 0 then
		local posY = self.bottom + self.height / (self.maxValue - self.minValue) * (value - self.minValue) - height

		renderOverlay(self.overlayId, posX, posY, self.width / (self.numValues - 1), height)
	end
end

function Graph:drawLine(posX1, posX2, value1, value2)
	local posY1 = self.bottom + self.height / (self.maxValue - self.minValue) * (value1 - self.minValue)
	local posY2 = self.bottom + self.height / (self.maxValue - self.minValue) * (value2 - self.minValue)
	local dx = posX2 - posX1
	local dy = posY2 - posY1
	local rot = math.atan(dy / (dx * g_screenAspectRatio))
	dy = dy / g_screenAspectRatio
	local length = math.sqrt(dx * dx + dy * dy)

	setOverlayRotation(self.overlayId, rot, 0, 0)
	renderOverlay(self.overlayId, posX1, posY1, length, 0.002)
end
