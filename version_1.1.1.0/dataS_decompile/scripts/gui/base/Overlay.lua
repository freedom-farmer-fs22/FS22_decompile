Overlay = {}
local Overlay_mt = Class(Overlay)
Overlay.ALIGN_VERTICAL_BOTTOM = 1
Overlay.ALIGN_VERTICAL_MIDDLE = 2
Overlay.ALIGN_VERTICAL_TOP = 3
Overlay.ALIGN_HORIZONTAL_LEFT = 4
Overlay.ALIGN_HORIZONTAL_CENTER = 5
Overlay.ALIGN_HORIZONTAL_RIGHT = 6
Overlay.DEFAULT_UVS = {
	0,
	0,
	0,
	1,
	1,
	0,
	1,
	1
}

function Overlay.new(overlayFilename, x, y, width, height, customMt)
	local overlayId = 0

	if overlayFilename ~= nil then
		overlayId = createImageOverlay(overlayFilename)
	end

	local self = setmetatable({}, customMt or Overlay_mt)
	self.overlayId = overlayId
	self.filename = overlayFilename
	self.uvs = {
		1,
		0,
		1,
		1,
		0,
		0,
		0,
		1
	}
	self.x = x
	self.y = y
	self.offsetX = 0
	self.offsetY = 0
	self.defaultWidth = width
	self.width = width
	self.defaultHeight = height
	self.height = height
	self.scaleWidth = 1
	self.scaleHeight = 1
	self.visible = true
	self.alignmentVertical = Overlay.ALIGN_VERTICAL_BOTTOM
	self.alignmentHorizontal = Overlay.ALIGN_HORIZONTAL_LEFT
	self.invertX = false
	self.rotation = 0
	self.rotationCenterX = 0
	self.rotationCenterY = 0
	self.r = 1
	self.g = 1
	self.b = 1
	self.a = 1
	self.debugEnabled = false

	return self
end

function Overlay:delete()
	if self.overlayId ~= 0 then
		delete(self.overlayId)
	end
end

function Overlay:setColor(r, g, b, a)
	r = r or self.r
	g = g or self.g
	b = b or self.b
	a = a or self.a

	if r ~= self.r or g ~= self.g or b ~= self.b or a ~= self.a then
		self.a = a
		self.b = b
		self.g = g
		self.r = r

		if self.overlayId ~= 0 then
			setOverlayColor(self.overlayId, self.r, self.g, self.b, self.a)
		end
	end
end

function Overlay:setUVs(uvs)
	if self.overlayId ~= 0 then
		self.uvs = uvs

		setOverlayUVs(self.overlayId, unpack(uvs))
	end
end

function Overlay:setPosition(x, y)
	self.x = x or self.x
	self.y = y or self.y
end

function Overlay:getPosition()
	return self.x, self.y
end

function Overlay:setDimension(width, height)
	self.width = width or self.width
	self.height = height or self.height

	self:setAlignment(self.alignmentVertical, self.alignmentHorizontal)
end

function Overlay:resetDimensions()
	self.scaleWidth = 1
	self.scaleHeight = 1

	self:setDimension(self.defaultWidth, self.defaultHeight)
end

function Overlay:setInvertX(invertX)
	if self.invertX ~= invertX then
		self.invertX = invertX

		if self.overlayId ~= 0 then
			if invertX then
				setOverlayUVs(self.overlayId, self.uvs[5], self.uvs[6], self.uvs[7], self.uvs[8], self.uvs[1], self.uvs[2], self.uvs[3], self.uvs[4])
			else
				setOverlayUVs(self.overlayId, unpack(self.uvs))
			end
		end
	end
end

function Overlay:setRotation(rotation, centerX, centerY)
	if self.rotation ~= rotation or self.rotationCenterX ~= centerX or self.rotationCenterY ~= centerY then
		self.rotation = rotation
		self.rotationCenterX = centerX
		self.rotationCenterY = centerY

		if self.overlayId ~= 0 then
			setOverlayRotation(self.overlayId, rotation, centerX, centerY)
		end
	end
end

function Overlay:setScale(scaleWidth, scaleHeight)
	self.width = self.defaultWidth * scaleWidth
	self.height = self.defaultHeight * scaleHeight
	self.scaleWidth = scaleWidth
	self.scaleHeight = scaleHeight

	self:setAlignment(self.alignmentVertical, self.alignmentHorizontal)
end

function Overlay:getScale()
	return self.scaleWidth, self.scaleHeight
end

function Overlay:render()
	if self.visible and self.overlayId ~= 0 and self.a > 0 then
		renderOverlay(self.overlayId, self.x + self.offsetX, self.y + self.offsetY, self.width, self.height)
	end
end

function Overlay:setAlignment(vertical, horizontal)
	if vertical == Overlay.ALIGN_VERTICAL_TOP then
		self.offsetY = -self.height
	elseif vertical == Overlay.ALIGN_VERTICAL_MIDDLE then
		self.offsetY = -self.height * 0.5
	else
		self.offsetY = 0
	end

	self.alignmentVertical = vertical or Overlay.ALIGN_VERTICAL_BOTTOM

	if horizontal == Overlay.ALIGN_HORIZONTAL_RIGHT then
		self.offsetX = -self.width
	elseif horizontal == Overlay.ALIGN_HORIZONTAL_CENTER then
		self.offsetX = -self.width * 0.5
	else
		self.offsetX = 0
	end

	self.alignmentHorizontal = horizontal or Overlay.ALIGN_HORIZONTAL_LEFT
end

function Overlay:setIsVisible(visible)
	self.visible = visible
end

function Overlay:setImage(overlayFilename)
	if self.filename ~= overlayFilename then
		if self.overlayId ~= 0 then
			delete(self.overlayId)
		end

		self.filename = overlayFilename
		self.overlayId = createImageOverlay(overlayFilename)
	end
end
