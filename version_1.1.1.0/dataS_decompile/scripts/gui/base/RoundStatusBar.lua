RoundStatusBar = {}
local RoundStatusBar_mt = Class(RoundStatusBar)

function RoundStatusBar.new(frontFilename, valueFilename, markerFilename, color, valueColor, bgColor, radius, markerSize, x, y, width, height, valueWidth, valueHeight, custom_mt)
	if custom_mt == nil then
		custom_mt = RoundStatusBar_mt
	end

	local self = setmetatable({}, custom_mt)
	self.value = 0
	self.width = width
	self.height = height
	self.radius = radius
	self.offsetX = (width - valueWidth) / 2
	self.offsetY = (height - valueHeight) / 2
	self.x = x
	self.y = y

	if frontFilename ~= nil then
		self.overlayFront = Overlay.new(frontFilename, x, y, width, height)

		self.overlayFront:setColor(unpack(color))
	end

	self.overlayBackground1 = Overlay.new(valueFilename, x + self.offsetX, y + self.offsetY, valueWidth, valueHeight)
	self.overlayBackground2 = Overlay.new(valueFilename, x + self.offsetX, y + self.offsetY, valueWidth, valueHeight)
	self.overlayValue1 = Overlay.new(valueFilename, x + self.offsetX, y + self.offsetY, valueWidth, valueHeight)
	self.overlayValue2 = Overlay.new(valueFilename, x + self.offsetX, y + self.offsetY, valueWidth, valueHeight)

	self.overlayBackground1:setColor(unpack(bgColor))
	self.overlayBackground2:setColor(unpack(bgColor))
	self.overlayValue1:setColor(unpack(valueColor))
	self.overlayValue2:setColor(unpack(valueColor))

	if markerFilename ~= nil then
		self.overlayMarker = Overlay.new(markerFilename, x, y, markerSize[1], markerSize[2])

		self.overlayMarker:setColor(unpack(valueColor))
	end

	self.overlayValue2:setRotation(math.rad(180), self.overlayValue2.width * 0.5, self.overlayValue2.height * 0.5)
	self:setValue(0)

	return self
end

function RoundStatusBar:delete()
	if self.overlayFront ~= nil then
		self.overlayFront:delete()
	end

	if self.overlayBackground1 ~= nil then
		self.overlayBackground1:delete()
	end

	if self.overlayBackground2 ~= nil then
		self.overlayBackground2:delete()
	end

	if self.overlayValue1 ~= nil then
		self.overlayValue1:delete()
	end

	if self.overlayValue2 ~= nil then
		self.overlayValue2:delete()
	end

	if self.overlayMarker ~= nil then
		self.overlayMarker:delete()
	end
end

function RoundStatusBar:setPosition(x, y)
	self.x = Utils.getNoNil(x, self.x)
	self.y = Utils.getNoNil(y, self.y)

	self.overlayValue1:setPosition(self.x + self.offsetX, self.y + self.offsetY)
	self.overlayValue2:setPosition(self.x + self.offsetX, self.y + self.offsetY)
	self.overlayBackground1:setPosition(self.x + self.offsetX, self.y + self.offsetY)
	self.overlayBackground2:setPosition(self.x + self.offsetX, self.y + self.offsetY)

	if self.overlayFront ~= nil then
		self.overlayFront:setPosition(self.x, self.y)
	end
end

function RoundStatusBar:setValue(newValue)
	self.value = MathUtil.clamp(newValue, 0, 1)

	self.overlayValue1:setRotation(math.rad((1 - self.value) * 360), self.overlayValue1.width * 0.5, self.overlayValue1.height * 0.5)
	self.overlayBackground1:setRotation(math.rad(180 + -self.value * 360), self.overlayBackground1.width * 0.5, self.overlayBackground1.height * 0.5)

	if self.overlayMarker ~= nil then
		local markerPosX = math.cos(math.rad((1 - self.value) * 360 + 90)) * self.radius[1]
		local markerPosY = math.sin(math.rad((1 - self.value) * 360 + 90)) * self.radius[2]

		self.overlayMarker:setPosition(self.x + self.width / 2 - self.overlayMarker.width / 2 + markerPosX, self.y + self.height / 2 - self.overlayMarker.height / 2 + markerPosY)
	end
end

function RoundStatusBar:render()
	if self.value > 0.5 then
		self.overlayBackground2:render()
	end

	self.overlayValue1:render()

	if self.value > 0.5 then
		self.overlayValue2:render()
	else
		self.overlayBackground2:render()
		self.overlayBackground1:render()
	end

	if self.overlayFront ~= nil then
		self.overlayFront:render()
	end

	if self.overlayMarker ~= nil then
		self.overlayMarker:render()
	end
end
