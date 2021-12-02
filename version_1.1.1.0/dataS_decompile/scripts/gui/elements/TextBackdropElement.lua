TextBackdropElement = {}
local TextBackdropElement_mt = Class(TextBackdropElement, BitmapElement)

function TextBackdropElement.new(target, custom_mt)
	local self = BitmapElement.new(target, custom_mt or TextBackdropElement_mt)
	self.padding = {
		0,
		0,
		0,
		0
	}

	return self
end

function TextBackdropElement:loadFromXML(xmlFile, key)
	TextBackdropElement:superClass().loadFromXML(self, xmlFile, key)

	self.padding = GuiUtils.getNormalizedValues(getXMLString(xmlFile, key .. "#padding"), self.outputSize, self.padding)
end

function TextBackdropElement:loadProfile(profile, applyProfile)
	TextBackdropElement:superClass().loadProfile(self, profile, applyProfile)

	self.padding = GuiUtils.getNormalizedValues(profile:getValue("padding"), self.outputSize, self.padding)
end

function TextBackdropElement:copyAttributes(src)
	TextBackdropElement:superClass().copyAttributes(self, src)

	self.padding = table.copy(src.padding)
end

function TextBackdropElement:clone(parent, includeId, suppressOnCreate)
	local clonedElement = TextBackdropElement:superClass().clone(self, parent, includeId, suppressOnCreate)

	clonedElement:installTextElement()

	return clonedElement
end

function TextBackdropElement:onGuiSetupFinished()
	TextBackdropElement:superClass().onGuiSetupFinished(self)
	self:installTextElement()
end

function TextBackdropElement:installTextElement()
	assertWithCallstack(#self.elements > 0)

	self.textElement = self.elements[1]

	assertWithCallstack(self.textElement:isa(TextElement))

	self.textElement.setSize = Utils.overwrittenFunction(self.textElement.setSize, function (textElement, superFunc, width, height)
		superFunc(textElement, width, height)
		self:updateSizeAndContents(width * g_aspectScaleX)
	end)

	self:updateSizeAndContents(self.textElement.absSize[1])
end

function TextBackdropElement:updateSizeAndContents(textElementWidth)
	local width = textElementWidth + self.padding[1] + self.padding[3]

	self:setSize(width, nil)
	self.elements[1]:setPosition(self.padding[1])
end
