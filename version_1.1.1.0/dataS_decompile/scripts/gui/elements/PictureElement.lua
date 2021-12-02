PictureElement = {}
local PictureElement_mt = Class(PictureElement, BitmapElement)
PictureElement.CONTENT_MODE = {
	SCALE_TO_FILL = 1,
	SCALE_ASPECT_FIT = 2
}

function PictureElement.new(target, custom_mt)
	local self = BitmapElement.new(target, custom_mt or PictureElement_mt)
	self.contentMode = PictureElement.CONTENT_MODE.SCALE_ASPECT_FIT
	self.imageSize = {
		1,
		1
	}
	self.aspectRatio = 1

	return self
end

function PictureElement:loadFromXML(xmlFile, key)
	PictureElement:superClass().loadFromXML(self, xmlFile, key)

	self.imageSize = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#imageSize"), self.outputSize, self.imageSize)
	self.aspectRatio = self.imageSize[1] / self.imageSize[2]
end

function PictureElement:loadProfile(profile, applyProfile)
	PictureElement:superClass().loadProfile(self, profile, applyProfile)

	self.imageSize = GuiUtils.getNormalizedValues(profile:getValue("imageSize"), self.outputSize, self.imageSize)
	self.aspectRatio = self.imageSize[1] / self.imageSize[2]
	local mode = profile:getValue("pictureContentMode")

	if mode == "scaleToFill" then
		self.contentMode = PictureElement.CONTENT_MODE.SCALE_TO_FILL
	elseif mode == "scaleAspectFit" then
		self.contentMode = PictureElement.CONTENT_MODE.SCALE_ASPECT_FIT
	end
end

function PictureElement:copyAttributes(src)
	PictureElement:superClass().copyAttributes(self, src)

	self.contentMode = src.contentMode
	self.aspectRatio = src.aspectRatio
	self.imageSize = src.imageSize
end

function PictureElement:setImageSize(width, height)
	self.imageSize[1] = Utils.getNoNil(width, self.imageSize[1])
	self.imageSize[2] = Utils.getNoNil(height, self.imageSize[2])
	self.aspectRatio = self.imageSize[1] / self.imageSize[2]
end

function PictureElement:setAspectRatio(ratio)
	local xScale, yScale = self:getAspectScale()
	self.aspectRatio = ratio * xScale / yScale
end

function PictureElement:getAdjustedPosition()
	local xOffset, yOffset = self:getOffset()
	local x = xOffset
	local y = yOffset
	local width = 0
	local height = 0

	if self.contentMode == PictureElement.CONTENT_MODE.SCALE_TO_FILL then
		local elementAspect = self.absSize[1] / g_aspectScaleX / (self.absSize[2] * g_aspectScaleY)
		local imageAspect = self.aspectRatio

		if imageAspect <= elementAspect then
			width = self.absSize[1]
			height = self.absSize[2] * g_screenAspectRatio
		else
			width = self.absSize[1]
			height = self.absSize[2]
		end
	elseif self.contentMode == PictureElement.CONTENT_MODE.SCALE_ASPECT_FIT then
		local r = g_referenceScreenWidth / g_referenceScreenHeight
		width = self.absSize[1]
		height = width / self.aspectRatio * r

		if self.absSize[2] < height then
			height = self.absSize[2]
			width = height * self.aspectRatio / r
			x = x + (self.absSize[1] - width) / 2
		else
			y = y + (self.absSize[2] - height) / 2
		end
	end

	return x, y, width, height
end

function PictureElement:draw(clipX1, clipY1, clipX2, clipY2)
	local x, y, width, height = self:getAdjustedPosition()

	GuiOverlay.renderOverlay(self.overlay, self.absPosition[1] + x, self.absPosition[2] + y, width, height, self:getOverlayState(), clipX1, clipY1, clipX2, clipY2)

	if self.debugEnabled or g_uiDebugEnabled then
		local xPixel = 1 / g_screenWidth
		local yPixel = 1 / g_screenHeight

		drawFilledRect(self.absPosition[1] - xPixel + x, self.absPosition[2] - yPixel + y, width + 2 * xPixel, yPixel, 1, 1, 0, 1)
		drawFilledRect(self.absPosition[1] - xPixel + x, self.absPosition[2] + height + y, width + 2 * xPixel, yPixel, 1, 1, 0, 1)
		drawFilledRect(self.absPosition[1] - xPixel + x, self.absPosition[2] + y, xPixel, height, 1, 1, 0, 1)
		drawFilledRect(self.absPosition[1] + width + x, self.absPosition[2] + y, xPixel, height, 1, 1, 0, 1)
	end

	PictureElement:superClass():superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end
