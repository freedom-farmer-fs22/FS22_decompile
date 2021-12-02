ColorPickButtonElement = {}
local ColorPickButtonElement_mt = Class(ColorPickButtonElement, ButtonElement)

function ColorPickButtonElement.new(target, custom_mt)
	local self = ColorPickButtonElement:superClass().new(target, custom_mt or ColorPickButtonElement_mt)
	self.colors = {
		{
			1,
			1,
			1,
			1
		}
	}
	self.selectionFrameThickness = {
		0,
		0
	}
	self.selectionFrameColor = {
		1,
		1,
		1,
		1
	}

	return self
end

function ColorPickButtonElement:loadFromXML(xmlFile, key)
	ColorPickButtonElement:superClass().loadFromXML(self, xmlFile, key)

	self.selectionFrameThickness = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#selectionFrameThickness"), self.outputSize, self.selectionFrameThickness)
	self.selectionFrameColor = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#selectionFrameColor"), self.selectionFrameColor)
end

function ColorPickButtonElement:loadProfile(profile, applyProfile)
	ColorPickButtonElement:superClass().loadProfile(self, profile, applyProfile)

	self.selectionFrameThickness = GuiUtils.getNormalizedValues(profile:getValue("selectionFrameThickness"), self.outputSize, self.selectionFrameThickness)
	self.selectionFrameColor = GuiUtils.getColorArray(profile:getValue("selectionFrameColor"), self.selectionFrameColor)
	self.metallicImageUVs = GuiUtils.getUVs(profile:getValue("metallicImageUVs"))
	self.nonMetallicImageUVs = table.copy(self.overlay.uvs)
end

function ColorPickButtonElement:copyAttributes(src)
	ColorPickButtonElement:superClass().copyAttributes(self, src)

	self.selectionFrameThickness = table.copy(src.selectionFrameThickness)
	self.selectionFrameColor = table.copy(src.selectionFrameColor)
	self.metallicImageUVs = table.copy(src.metallicImageUVs)
	self.nonMetallicImageUVs = table.copy(src.nonMetallicImageUVs)
end

function ColorPickButtonElement:draw(clipX1, clipY1, clipX2, clipY2)
	if self:getIsSelected() then
		GuiOverlay.renderOverlay(self.overlay, self.absPosition[1] + self.absSize[1] * 0.15, self.absPosition[2] + self.absSize[2] * 0.15, self.absSize[1] * 0.7, self.absSize[2] * 0.7, self:getOverlayState(), clipX1, clipY1, clipX2, clipY2)

		local r, g, b, a = unpack(self.selectionFrameColor)

		drawFilledRect(self.absPosition[1], self.absPosition[2], self.absSize[1], self.selectionFrameThickness[2], r, g, b, a)
		drawFilledRect(self.absPosition[1], self.absPosition[2] + self.absSize[2] - self.selectionFrameThickness[2], self.absSize[1], self.selectionFrameThickness[2], r, g, b, a)
		drawFilledRect(self.absPosition[1], self.absPosition[2], self.selectionFrameThickness[1], self.absSize[2], r, g, b, a)
		drawFilledRect(self.absPosition[1] + self.absSize[1] - self.selectionFrameThickness[1], self.absPosition[2], self.selectionFrameThickness[1], self.absSize[2], r, g, b, a)
	else
		GuiOverlay.renderOverlay(self.overlay, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2], self:getOverlayState(), clipX1, clipY1, clipX2, clipY2)
	end

	if self.debugEnabled or g_uiDebugEnabled then
		local xPixel = 1 / g_screenWidth
		local yPixel = 1 / g_screenHeight
		local posX1 = self.absPosition[1]
		local posX2 = self.absPosition[1] + self.size[1] - xPixel
		local posY1 = self.absPosition[2]
		local posY2 = self.absPosition[2] + self.size[2] - yPixel

		drawFilledRect(posX1, posY1, posX2 - posX1, yPixel, 0, 1, 0, 0.7)
		drawFilledRect(posX1, posY2, posX2 - posX1, yPixel, 0, 1, 0, 0.7)
		drawFilledRect(posX1, posY1, xPixel, posY2 - posY1, 0, 1, 0, 0.7)
		drawFilledRect(posX1 + posX2 - posX1, posY1, xPixel, posY2 - posY1, 0, 1, 0, 0.7)
	end
end

function ColorPickButtonElement:setColor(r, g, b)
	local color = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_NORMAL)
	color[1] = r
	color[2] = g
	color[3] = b
	color[4] = 1
	color = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_HIGHLIGHTED)
	color[1] = r
	color[2] = g
	color[3] = b
	color[4] = 0.5
	color = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_SELECTED)
	color[1] = r
	color[2] = g
	color[3] = b
	color[4] = 1
	color = GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_FOCUSED)
	color[1] = r
	color[2] = g
	color[3] = b
	color[4] = 1
end

function ColorPickButtonElement:setMaterial(materialId)
	local isMetallic = ConfigurationUtil.isColorMetallic(materialId)
	local uvs = GuiOverlay.getOverlayUVs(self.overlay, GuiOverlay.STATE_NORMAL)

	for i = 1, 8 do
		if isMetallic then
			uvs[i] = self.metallicImageUVs[i]
		else
			uvs[i] = self.nonMetallicImageUVs[i]
		end
	end
end

function ColorPickButtonElement:setColors(r1, g1, b1, r2, g2, b2)
	log("SET COLORS", r1, g1, b1, r2, g2, b2)
end
