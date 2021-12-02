BitmapElement = {}
local BitmapElement_mt = Class(BitmapElement, GuiElement)

function BitmapElement.new(target, custom_mt)
	local self = GuiElement.new(target, custom_mt or BitmapElement_mt)
	self.offset = {
		0,
		0
	}
	self.focusedOffset = {
		0,
		0
	}
	self.overlay = {}

	return self
end

function BitmapElement:delete()
	GuiOverlay.deleteOverlay(self.overlay)
	BitmapElement:superClass().delete(self)
end

function BitmapElement:loadFromXML(xmlFile, key)
	BitmapElement:superClass().loadFromXML(self, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, nil, xmlFile, key)

	self.focusedOffset = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#focusedOffset"), self.outputSize, self.focusedOffset)
	self.offset = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#offset"), self.outputSize, self.offset)

	GuiOverlay.createOverlay(self.overlay)
end

function BitmapElement:loadProfile(profile, applyProfile)
	BitmapElement:superClass().loadProfile(self, profile, applyProfile)

	local oldFilename = self.overlay.filename
	local oldPreviewFilename = self.overlay.previewFilename

	GuiOverlay.loadOverlay(self, self.overlay, "image", self.imageSize, profile, nil, )

	self.offset = GuiUtils.getNormalizedValues(profile:getValue("offset"), self.outputSize, self.offset)
	self.focusedOffset = GuiUtils.getNormalizedValues(profile:getValue("focusedOffset"), self.outputSize, {
		self.offset[1],
		self.offset[2]
	})

	if oldFilename ~= self.overlay.filename or oldPreviewFilename ~= self.overlay.previewFilename then
		GuiOverlay.createOverlay(self.overlay)
	end

	if applyProfile then
		self:applyBitmapAspectScale()
	end
end

function BitmapElement:copyAttributes(src)
	BitmapElement:superClass().copyAttributes(self, src)
	GuiOverlay.copyOverlay(self.overlay, src.overlay)

	self.offset = table.copy(src.offset)
	self.focusedOffset = table.copy(src.focusedOffset)
end

function BitmapElement:applyBitmapAspectScale()
	local xScale, yScale = self:getAspectScale()
	self.offset[1] = self.offset[1] * xScale
	self.focusedOffset[1] = self.focusedOffset[1] * xScale
	self.offset[2] = self.offset[2] * yScale
	self.focusedOffset[2] = self.focusedOffset[2] * yScale
end

function BitmapElement:applyScreenAlignment()
	self:applyBitmapAspectScale()
	BitmapElement:superClass().applyScreenAlignment(self)
end

function BitmapElement:setDisabled(disabled, doNotUpdateChildren)
	BitmapElement:superClass().setDisabled(self, disabled, doNotUpdateChildren)

	if disabled then
		self:setOverlayState(GuiOverlay.STATE_DISABLED)
	else
		self:setOverlayState(GuiOverlay.STATE_NORMAL)
	end
end

function BitmapElement:setAlpha(alpha)
	BitmapElement:superClass().setAlpha(self, alpha)

	if self.overlay ~= nil then
		self.overlay.alpha = self.alpha
	end
end

function BitmapElement:getOffset()
	local xOffset = self.offset[1]
	local yOffset = self.offset[2]
	local state = self:getOverlayState()

	if state == GuiOverlay.STATE_FOCUSED or state == GuiOverlay.STATE_PRESSED or state == GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_HIGHLIGHTED then
		xOffset = self.focusedOffset[1]
		yOffset = self.focusedOffset[2]
	end

	return xOffset, yOffset
end

function BitmapElement:setIsWebOverlay(isWebOverlay)
	self.overlay.isWebOverlay = isWebOverlay
end

function BitmapElement:setImageFilename(filename)
	self.overlay = GuiOverlay.createOverlay(self.overlay, filename)
end

function BitmapElement:setImageColor(state, r, g, b, a)
	local color = GuiOverlay.getOverlayColor(self.overlay, state)
	color[1] = Utils.getNoNil(r, color[1])
	color[2] = Utils.getNoNil(g, color[2])
	color[3] = Utils.getNoNil(b, color[3])
	color[4] = Utils.getNoNil(a, color[4])
end

function BitmapElement:setImageUVs(state, v0, u0, v1, u1, v2, u2, v3, u3)
	state = Utils.getNoNil(state, self:getOverlayState())
	local uvs = GuiOverlay.getOverlayUVs(self.overlay, state)
	uvs[1] = Utils.getNoNil(v0, uvs[1])
	uvs[2] = Utils.getNoNil(u0, uvs[2])
	uvs[3] = Utils.getNoNil(v1, uvs[3])
	uvs[4] = Utils.getNoNil(u1, uvs[4])
	uvs[5] = Utils.getNoNil(v2, uvs[5])
	uvs[6] = Utils.getNoNil(u2, uvs[6])
	uvs[7] = Utils.getNoNil(v3, uvs[7])
	uvs[8] = Utils.getNoNil(u3, uvs[8])
end

function BitmapElement:setImageRotation(rotation)
	self.overlay.rotation = rotation
end

function BitmapElement:draw(clipX1, clipY1, clipX2, clipY2)
	local xOffset, yOffset = self:getOffset()

	GuiOverlay.renderOverlay(self.overlay, self.absPosition[1] + xOffset, self.absPosition[2] + yOffset, self.absSize[1], self.absSize[2], self:getOverlayState(), clipX1, clipY1, clipX2, clipY2)
	BitmapElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end

function BitmapElement:canReceiveFocus()
	if not self.visible or #self.elements < 1 then
		return false
	end

	for _, v in ipairs(self.elements) do
		if not v:canReceiveFocus() then
			return false
		end
	end

	return true
end

function BitmapElement:getFocusTarget()
	if #self.elements > 0 then
		local _, firstElement = next(self.elements)

		if firstElement then
			return firstElement
		end
	end

	return self
end
