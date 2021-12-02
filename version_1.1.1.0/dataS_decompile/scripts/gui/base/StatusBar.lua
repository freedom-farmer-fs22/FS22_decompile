StatusBar = {}
local StatusBar_mt = Class(StatusBar)

function StatusBar.new(filename, uvsBg, uvsMarker, bgColor, valueColor, markerSize, x, y, width, height, custom_mt)
	if custom_mt == nil then
		custom_mt = StatusBar_mt
	end

	local self = setmetatable({}, custom_mt)
	self.value = 0
	self.width = width
	self.height = height
	self.isDisabled = false
	self.x = x
	self.y = y
	self.markerSize = markerSize
	self.overlayBackground = Overlay.new(filename, x, y, width, height)

	self.overlayBackground:setColor(unpack(bgColor))
	self.overlayBackground:setUVs(uvsBg)

	self.overlayValue = Overlay.new(filename, x, y, width, height)

	self.overlayValue:setColor(unpack(valueColor))
	self.overlayValue:setUVs(uvsBg)

	if uvsMarker ~= nil then
		self.overlayMarker = Overlay.new(filename, x - markerSize[1] / 2, y + (height - markerSize[2]) / 2, markerSize[1], markerSize[2])

		self.overlayMarker:setColor(unpack(valueColor))
		self.overlayMarker:setUVs(uvsMarker)
	end

	self:setValue(0)

	return self
end

function StatusBar:delete()
	if self.overlayBackground ~= nil then
		self.overlayBackground:delete()
	end

	if self.overlayValue ~= nil then
		self.overlayValue:delete()
	end

	if self.overlayMarker ~= nil then
		self.overlayMarker:delete()
	end
end

function StatusBar:setDisabled(isDisabled)
	self.isDisabled = isDisabled
end

function StatusBar:setPosition(x, y)
	self.x = x
	self.y = y

	if self.overlayBackground ~= nil then
		self.overlayBackground:setPosition(x, y)
	end

	if self.overlayValue ~= nil then
		self.overlayValue:setPosition(x, y)
	end

	if self.overlayMarker ~= nil then
		self.overlayMarker:setPosition(x - self.markerSize[1] / 2, y + (self.height - self.markerSize[2]) / 2)
	end
end

function StatusBar:setColor(r, g, b, a)
	if self.overlayMarker ~= nil then
		self.overlayMarker:setColor(r, g, b, a)
	end

	if self.overlayValue ~= nil then
		self.overlayValue:setColor(r, g, b, a)
	end
end

function StatusBar:setValue(newValue)
	self.value = MathUtil.clamp(newValue, 0, 1)
	local markerPosX = newValue * self.width

	self.overlayValue:setDimension(newValue * self.width, self.overlayValue.height)

	if self.overlayMarker ~= nil then
		self.overlayMarker:setPosition(self.x + markerPosX - self.markerSize[1] / 2, self.overlayMarker.y)
	end
end

function StatusBar:render()
	self.overlayBackground:render()

	if not self.isDisabled then
		self.overlayValue:render()

		if self.overlayMarker ~= nil then
			self.overlayMarker:render()
		end
	end
end
