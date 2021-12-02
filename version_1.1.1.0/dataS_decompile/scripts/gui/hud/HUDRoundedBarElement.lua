HUDRoundedBarElement = {}
local HUDRoundedBarElement_mt = Class(HUDRoundedBarElement, HUDElement)

function HUDRoundedBarElement.new(hudAtlasPath, posX, posY, width, height, isHorizontal, customMt)
	local overlay = Overlay.new(nil, posX, posY, width, height)
	local self = HUDElement.new(overlay, nil, customMt or HUDRoundedBarElement_mt)
	self.isHorizontal = isHorizontal or false
	self.xPadding = 0
	self.yPadding = 0
	self.value = 0

	self:createComponents(hudAtlasPath)

	return self
end

function HUDRoundedBarElement:delete()
	if self.overlayFront ~= nil then
		self.overlayFront:delete()

		self.overlayFront = nil

		self.overlayMiddle:delete()

		self.overlayMiddle = nil

		self.overlayBack:delete()

		self.overlayBack = nil

		self.barOverlayFront:delete()

		self.barOverlayFront = nil

		self.barOverlayMiddle:delete()

		self.barOverlayMiddle = nil

		self.barOverlayBack:delete()

		self.barOverlayBack = nil
	end

	HUDRoundedBarElement:superClass().delete(self)
end

function HUDRoundedBarElement:createComponents(hudAtlasPath)
	local x = 0
	local y = 0
	local width = 1
	local height = 1
	local uvs = HUDRoundedBarElement.UV.HORIZONTAL[self.isHorizontal]
	self.overlayFront = Overlay.new(hudAtlasPath, x, y, width, height)

	self.overlayFront:setUVs(GuiUtils.getUVs(uvs.FRONT))
	self.overlayFront:setColor(unpack(HUDRoundedBarElement.COLOR.BACKGROUND))

	self.overlayMiddle = Overlay.new(hudAtlasPath, x, y, width, height)

	self.overlayMiddle:setUVs(GuiUtils.getUVs(uvs.MIDDLE))
	self.overlayMiddle:setColor(unpack(HUDRoundedBarElement.COLOR.BACKGROUND))

	self.overlayBack = Overlay.new(hudAtlasPath, x, y, width, height)

	self.overlayBack:setUVs(GuiUtils.getUVs(uvs.BACK))
	self.overlayBack:setColor(unpack(HUDRoundedBarElement.COLOR.BACKGROUND))

	self.barOverlayFront = Overlay.new(hudAtlasPath, x, y, width, height)

	self.barOverlayFront:setUVs(GuiUtils.getUVs(uvs.FRONT))

	self.barOverlayMiddle = Overlay.new(hudAtlasPath, x, y, width, height)

	self.barOverlayMiddle:setUVs(GuiUtils.getUVs(uvs.MIDDLE))

	self.barOverlayBack = Overlay.new(hudAtlasPath, x, y, width, height)

	self.barOverlayBack:setUVs(GuiUtils.getUVs(uvs.BACK))
	self:updateComponents()
end

function HUDRoundedBarElement:setValue(value, d)
	value = math.max(math.min(value, 1), 0)

	if math.abs(value - self.value) > 0.005 then
		self.value = value

		self:updateComponents(true)
	end
end

function HUDRoundedBarElement:setBarColor(r, g, b)
	self.barOverlayFront:setColor(r, g, b, 1)
	self.barOverlayMiddle:setColor(r, g, b, 1)
	self.barOverlayBack:setColor(r, g, b, 1)
end

function HUDRoundedBarElement:setPosition(x, y)
	HUDRoundedBarElement:superClass().setPosition(self, x, y)
	self:updateComponents()
end

function HUDRoundedBarElement:setAlpha(alpha)
	self.overlay:setColor(nil, , , alpha)
	self.barOverlayFront:setColor(nil, , , alpha)
	self.barOverlayMiddle:setColor(nil, , , alpha)
	self.barOverlayBack:setColor(nil, , , alpha)

	local origAlpha = HUDRoundedBarElement.COLOR.BACKGROUND[4]

	self.overlayFront:setColor(nil, , , alpha * origAlpha)
	self.overlayMiddle:setColor(nil, , , alpha * origAlpha)
	self.overlayBack:setColor(nil, , , alpha * origAlpha)
end

function HUDRoundedBarElement:setDimension(width, height)
	self.overlay:setDimension(width, height)
	self:updateComponents()
end

function HUDRoundedBarElement:updateComponents(barOnly)
	local baseX = self.overlay.x
	local baseY = self.overlay.y
	local width = self.overlay.width
	local height = self.overlay.height
	local endUVs = HUDRoundedBarElement.UV.HORIZONTAL[self.isHorizontal].FRONT
	local endSizeX, endSizeY = getNormalizedScreenValues(endUVs[3], endUVs[4])
	local paddingX, paddingY = getNormalizedScreenValues(unpack(HUDRoundedBarElement.PADDING[self.isHorizontal]))

	if self.isHorizontal then
		if not barOnly then
			local endWidth = endSizeX / endSizeY * height

			self.overlayFront:setDimension(endWidth, height)
			self.overlayFront:setPosition(baseX, baseY)
			self.overlayMiddle:setDimension(width - 2 * endWidth, height)
			self.overlayMiddle:setPosition(baseX + endWidth, baseY)
			self.overlayBack:setDimension(endWidth, height)
			self.overlayBack:setPosition(baseX + width - endWidth, baseY)
		end

		local barWidth = width - 2 * paddingX
		local barHeight = math.max(height - 2 * paddingY, 1 / g_screenHeight)
		local endWidth = endSizeX / endSizeY * barHeight
		local barWidthValued = (barWidth - 2 * endWidth) * self.value + 2 * endWidth

		self.barOverlayFront:setDimension(endWidth, barHeight)
		self.barOverlayFront:setPosition(baseX + paddingX, baseY + paddingY)
		self.barOverlayMiddle:setDimension(barWidthValued - 2 * endWidth, barHeight)
		self.barOverlayMiddle:setPosition(baseX + paddingX + endWidth, baseY + paddingY)
		self.barOverlayBack:setDimension(endWidth, barHeight)
		self.barOverlayBack:setPosition(baseX + paddingX + barWidthValued - endWidth, baseY + paddingY)
	else
		if not barOnly then
			local endHeight = endSizeY / endSizeX * width

			self.overlayFront:setDimension(width, endHeight)
			self.overlayFront:setPosition(baseX, baseY)
			self.overlayMiddle:setDimension(width, height - 2 * endHeight)
			self.overlayMiddle:setPosition(baseX, baseY + endHeight)
			self.overlayBack:setDimension(width, endHeight)
			self.overlayBack:setPosition(baseX, baseY + height - endHeight)
		end

		local barWidth = math.max(width - 2 * paddingX, 1 / g_screenWidth)
		local barHeight = height - 2 * paddingY
		local endHeight = endSizeY / endSizeX * barWidth
		local barHeightValued = (barHeight - 2 * endHeight) * self.value + 2 * endHeight

		self.barOverlayFront:setDimension(barWidth, endHeight)
		self.barOverlayFront:setPosition(baseX + paddingX, baseY + paddingY)
		self.barOverlayMiddle:setDimension(barWidth, barHeightValued - 2 * endHeight)
		self.barOverlayMiddle:setPosition(baseX + paddingX, baseY + paddingY + endHeight)
		self.barOverlayBack:setDimension(barWidth, endHeight)
		self.barOverlayBack:setPosition(baseX + paddingX, baseY + paddingY + barHeightValued - endHeight)
	end
end

function HUDRoundedBarElement:draw()
	if self.overlay.visible then
		self.overlayFront:render()
		self.overlayMiddle:render()
		self.overlayBack:render()
		self.barOverlayFront:render()
		self.barOverlayMiddle:render()
		self.barOverlayBack:render()
	end
end

HUDRoundedBarElement.PADDING = {
	[true] = {
		3.5,
		3
	},
	[false] = {
		3,
		3.5
	}
}
HUDRoundedBarElement.UV = {
	HORIZONTAL = {
		[true] = {
			FRONT = {
				258,
				123,
				8,
				14
			},
			MIDDLE = {
				300,
				123,
				1,
				14
			},
			BACK = {
				361,
				123,
				8,
				14
			}
		},
		[false] = {
			FRONT = {
				401,
				167,
				14,
				8
			},
			MIDDLE = {
				401,
				100,
				14,
				1
			},
			BACK = {
				401,
				64,
				14,
				8
			}
		}
	}
}
HUDRoundedBarElement.COLOR = {
	BACKGROUND = {
		0,
		0,
		0,
		0.54
	}
}
