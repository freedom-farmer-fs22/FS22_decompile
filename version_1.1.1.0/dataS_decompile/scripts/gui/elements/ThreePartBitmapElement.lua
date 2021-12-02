ThreePartBitmapElement = {}
local ThreePartBitmapElement_mt = Class(ThreePartBitmapElement, BitmapElement)

function ThreePartBitmapElement.new(target, custom_mt)
	local self = BitmapElement.new(target, custom_mt or ThreePartBitmapElement_mt)
	self.startOverlay = {}
	self.endOverlay = {}
	self.startSize = {
		0,
		0
	}
	self.midSize = {
		0,
		0
	}
	self.endSize = {
		0,
		0
	}
	self.isHorizontal = true

	return self
end

function ThreePartBitmapElement:delete()
	GuiOverlay.deleteOverlay(self.startOverlay)
	GuiOverlay.deleteOverlay(self.endOverlay)
	ThreePartBitmapElement:superClass().delete(self)
end

function ThreePartBitmapElement:loadFromXML(xmlFile, key)
	ThreePartBitmapElement:superClass().loadFromXML(self, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.startOverlay, "startImage", self.imageSize, nil, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.endOverlay, "endImage", self.imageSize, nil, xmlFile, key)

	self.startSize = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#startImageSize"), self.outputSize, self.startSize)
	self.midSize = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#midImageSize"), self.outputSize, self.midSize)
	self.endSize = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#endImageSize"), self.outputSize, self.endSize)
	self.isHorizontal = Utils.getNoNil(getXMLBool(xmlFile, key .. "#isHorizontal"), self.isHorizontal)

	GuiOverlay.createOverlay(self.startOverlay)
	GuiOverlay.createOverlay(self.endOverlay)
end

function ThreePartBitmapElement:loadProfile(profile, applyProfile)
	ThreePartBitmapElement:superClass().loadProfile(self, profile, applyProfile)

	local startOld = self.startOverlay.filename
	local endOld = self.endOverlay.filename

	GuiOverlay.loadOverlay(self, self.startOverlay, "startImage", self.imageSize, profile, nil, )
	GuiOverlay.loadOverlay(self, self.endOverlay, "endImage", self.imageSize, profile, nil, )

	self.startSize = GuiUtils.getNormalizedValues(profile:getValue("startImageSize"), self.outputSize, self.startSize)
	self.midSize = GuiUtils.getNormalizedValues(profile:getValue("midImageSize"), self.outputSize, self.midSize)
	self.endSize = GuiUtils.getNormalizedValues(profile:getValue("endImageSize"), self.outputSize, self.endSize)
	self.isHorizontal = profile:getBool("isHorizontal", self.isHorizontal)

	if startOld ~= self.startOverlay.filename then
		GuiOverlay.createOverlay(self.startOverlay)
	end

	if endOld ~= self.endOverlay.filename then
		GuiOverlay.createOverlay(self.endOverlay)
	end
end

function ThreePartBitmapElement:copyAttributes(src)
	ThreePartBitmapElement:superClass().copyAttributes(self, src)

	self.startSize = table.copy(src.startSize)
	self.midSize = table.copy(src.midSize)
	self.endSize = table.copy(src.endSize)
	self.isHorizontal = src.isHorizontal

	GuiOverlay.copyOverlay(self.startOverlay, src.startOverlay)
	GuiOverlay.copyOverlay(self.endOverlay, src.endOverlay)
end

local function alignHorizontalToScreenPixels(x)
	local PIXEL_X_SIZE = 1 / g_screenWidth

	return math.floor(x / PIXEL_X_SIZE) * PIXEL_X_SIZE
end

local function alignSizeToScreenPixels(x)
	local PIXEL_X_SIZE = 1 / g_screenWidth

	return math.ceil(x / PIXEL_X_SIZE) * PIXEL_X_SIZE
end

function ThreePartBitmapElement:applyBitmapAspectScale()
	local xScale, yScale = self:getAspectScale()
	self.startSize[1] = self.startSize[1] * xScale
	self.midSize[1] = self.midSize[1] * xScale
	self.endSize[1] = self.endSize[1] * xScale
	self.startSize[2] = self.startSize[2] * yScale
	self.midSize[2] = self.midSize[2] * yScale
	self.endSize[2] = self.endSize[2] * yScale
end

function ThreePartBitmapElement:applyScreenAlignment()
	self:applyBitmapAspectScale()
	ThreePartBitmapElement:superClass().applyScreenAlignment(self)
end

function ThreePartBitmapElement:draw(clipX1, clipY1, clipX2, clipY2)
	local xOffset, yOffset = self:getOffset()
	local x = self.absPosition[1] + xOffset
	local y = self.absPosition[2] + yOffset
	local state = self:getOverlayState()

	if self.isHorizontal then
		GuiOverlay.renderOverlay(self.startOverlay, x, y, self.startSize[1], self.absSize[2], state, clipX1, clipY1, clipX2, clipY2)
		GuiOverlay.renderOverlay(self.overlay, x + self.startSize[1], y, alignSizeToScreenPixels(self.absSize[1] - self.startSize[1] - self.endSize[1]), self.absSize[2], state, clipX1, clipY1, clipX2, clipY2)
		GuiOverlay.renderOverlay(self.endOverlay, alignHorizontalToScreenPixels(x + self.absSize[1] - self.endSize[1]), y, self.endSize[1], self.absSize[2], state, clipX1, clipY1, clipX2, clipY2)
	else
		GuiOverlay.renderOverlay(self.startOverlay, x, y + self.absSize[2] - self.startSize[2], self.absSize[1], self.startSize[2], state, clipX1, clipY1, clipX2, clipY2)
		GuiOverlay.renderOverlay(self.overlay, x, y + self.endSize[2], self.absSize[1], self.absSize[2] - self.startSize[2] - self.endSize[2], state, clipX1, clipY1, clipX2, clipY2)
		GuiOverlay.renderOverlay(self.endOverlay, x, y, self.absSize[1], self.endSize[2], state, clipX1, clipY1, clipX2, clipY2)
	end

	BitmapElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end
