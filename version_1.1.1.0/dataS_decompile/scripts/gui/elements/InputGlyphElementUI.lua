InputGlyphElementUI = {}
local InputGlyphElementUI_mt = Class(InputGlyphElementUI, GuiElement)

function InputGlyphElementUI.new(target, custom_mt)
	local self = GuiElement.new(target, custom_mt or InputGlyphElementUI_mt)
	self.color = {
		1,
		1,
		1,
		1
	}

	return self
end

function InputGlyphElementUI:delete()
	if self.glyphElement ~= nil then
		self.glyphElement:delete()

		self.glyphElement = nil
	end

	InputGlyphElementUI:superClass().delete(self)
end

function InputGlyphElementUI:loadFromXML(xmlFile, key)
	InputGlyphElementUI:superClass().loadFromXML(self, xmlFile, key)

	self.color = GuiUtils.getColorArray(getXMLString(xmlFile, key .. "#glyphColor"), self.color)

	self:rebuildGlyph()
end

function InputGlyphElementUI:loadProfile(profile, applyProfile)
	InputGlyphElementUI:superClass().loadProfile(self, profile, applyProfile)

	self.color = GuiUtils.getColorArray(profile:getValue("glyphColor"), self.color)

	self:rebuildGlyph()
end

function InputGlyphElementUI:copyAttributes(src)
	InputGlyphElementUI:superClass().copyAttributes(self, src)

	self.color = table.copy(src.color)

	if src.glyphElement ~= nil then
		local actionNames = src.glyphElement.actionNames
		local actionText = src.glyphElement.actionText
		local actionTextSize = src.glyphElement.actionTextSize

		self:rebuildGlyph()
		self:setActions(actionNames, actionText, actionTextSize)
	end
end

function InputGlyphElementUI:rebuildGlyph()
	if self.glyphElement ~= nil then
		self.glyphElement:delete()
	end

	self.glyphElement = InputGlyphElement.new(g_inputDisplayManager, self.absSize[1], self.absSize[2])

	self.glyphElement:setButtonGlyphColor(self.color)
	self.glyphElement:setKeyboardGlyphColor(self.color)
end

function InputGlyphElementUI:updateAbsolutePosition()
	InputGlyphElementUI:superClass().updateAbsolutePosition(self)

	if self.glyphElement ~= nil then
		self.glyphElement:setPosition(self.absPosition[1], self.absPosition[2])
		self.glyphElement:setDimension(self.originalWidth or self.absSize[1], self.absSize[2])
		self.glyphElement:setBaseSize(self.originalWidth or self.absSize[1], self.absSize[2])

		self.didSetAbsolutePosition = true
	end
end

function InputGlyphElementUI:draw(clipX1, clipY1, clipX2, clipY2)
	InputGlyphElementUI:superClass().draw(self, clipX1, clipY1, clipX2, clipY2)

	if self.glyphElement ~= nil then
		self.glyphElement:draw()
	end
end

function InputGlyphElementUI:setActions(actions, ...)
	if self.glyphElement ~= nil then
		self.glyphElement:setActions(actions, ...)

		if not self.didSetAbsolutePosition then
			self:updateAbsolutePosition()
		end

		if self.originalWidth == nil then
			self.originalWidth = self.absSize[1]
		end

		self.absSize[1] = self.glyphElement:getGlyphWidth()
		self.size[1] = self.absSize[1] / g_aspectScaleX

		if self.parent ~= nil and self.parent.invalidateLayout ~= nil then
			self.parent:invalidateLayout()
		end
	end
end
