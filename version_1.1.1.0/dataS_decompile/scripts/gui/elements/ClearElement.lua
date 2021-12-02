ClearElement = {}
local BitmapElement_mt = Class(ClearElement, GuiElement)

function ClearElement.new(target, custom_mt)
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

function ClearElement:delete()
	GuiOverlay.deleteOverlay(self.overlay)
	ClearElement:superClass().delete(self)
end

function ClearElement:loadFromXML(xmlFile, key)
	ClearElement:superClass().loadFromXML(self, xmlFile, key)
	GuiOverlay.loadOverlay(self, self.overlay, "clear", self.imageSize, nil, xmlFile, key)

	self.focusedOffset = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#focusedOffset"), self.outputSize, self.focusedOffset)
	self.offset = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#offset"), self.outputSize, self.offset)
end

function ClearElement:loadProfile(profile, applyProfile)
	ClearElement:superClass().loadProfile(self, profile, applyProfile)
	GuiOverlay.loadOverlay(self, self.overlay, "clear", self.imageSize, profile, nil, )

	self.offset = GuiUtils.getNormalizedValues(profile:getValue("offset"), self.outputSize, self.offset)
	self.focusedOffset = GuiUtils.getNormalizedValues(profile:getValue("focusedOffset"), self.outputSize, {
		self.offset[1],
		self.offset[2]
	})

	if applyProfile then
		self:applyBitmapAspectScale()
	end
end

function ClearElement:copyAttributes(src)
	ClearElement:superClass().copyAttributes(self, src)
	GuiOverlay.copyOverlay(self.overlay, src.overlay)

	self.offset = table.copy(src.offset)
	self.focusedOffset = table.copy(src.focusedOffset)
end

function ClearElement:applyBitmapAspectScale()
	local xScale, yScale = self:getAspectScale()
	self.offset[1] = self.offset[1] * xScale
	self.focusedOffset[1] = self.focusedOffset[1] * xScale
	self.offset[2] = self.offset[2] * yScale
	self.focusedOffset[2] = self.focusedOffset[2] * yScale
end

function ClearElement:applyScreenAlignment()
	self:applyBitmapAspectScale()
	ClearElement:superClass().applyScreenAlignment(self)
end

function ClearElement:setDisabled(disabled, doNotUpdateChildren)
	ClearElement:superClass().setDisabled(self, disabled, doNotUpdateChildren)

	if disabled then
		self:setOverlayState(GuiOverlay.STATE_DISABLED)
	else
		self:setOverlayState(GuiOverlay.STATE_NORMAL)
	end
end

function ClearElement:getOffset()
	local xOffset = self.offset[1]
	local yOffset = self.offset[2]
	local state = self:getOverlayState()

	if state == GuiOverlay.STATE_FOCUSED or state == GuiOverlay.STATE_PRESSED or state == GuiOverlay.STATE_SELECTED or GuiOverlay.STATE_HIGHLIGHTED then
		xOffset = self.focusedOffset[1]
		yOffset = self.focusedOffset[2]
	end

	return xOffset, yOffset
end

function ClearElement:setImageRotation(rotation)
	self.overlay.rotation = rotation
end

function ClearElement:draw(clipX1, clipY1, clipX2, clipY2)
	local xOffset, yOffset = self:getOffset()

	clearOverlayArea(self.absPosition[1] + xOffset, self.absPosition[2] + yOffset, self.size[1], self.size[2], self.overlay.rotation, self.size[1] / 2, self.size[2] / 2)
	ClearElement:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)
end

function ClearElement:canReceiveFocus()
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

function ClearElement:getFocusTarget()
	local _, firstElement = next(self.elements)

	if firstElement then
		return firstElement
	end

	return self
end
