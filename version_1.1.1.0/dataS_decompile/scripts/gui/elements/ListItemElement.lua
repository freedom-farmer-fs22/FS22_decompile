ListItemElement = {}
local ListItemElement_mt = Class(ListItemElement, BitmapElement)

function ListItemElement.new(target, custom_mt)
	local self = BitmapElement.new(target, custom_mt or ListItemElement_mt)
	self.mouseEntered = false
	self.allowSelected = true
	self.autoSelectChildren = false
	self.handleFocus = false
	self.hideSelection = false
	self.alternateBackgroundColor = nil
	self.attributes = {}

	return self
end

function ListItemElement:loadFromXML(xmlFile, key)
	ListItemElement:superClass().loadFromXML(self, xmlFile, key)

	self.allowSelected = Utils.getNoNil(getXMLBool(xmlFile, key .. "#allowSelected"), self.allowSelected)
	self.autoSelectChildren = Utils.getNoNil(getXMLBool(xmlFile, key .. "#autoSelectChildren"), self.autoSelectChildren)
	self.hideSelection = Utils.getNoNil(getXMLBool(xmlFile, key .. "#hideSelection"), self.hideSelection)

	self:addCallback(xmlFile, key .. "#onFocus", "onFocusCallback")
	self:addCallback(xmlFile, key .. "#onLeave", "onLeaveCallback")
	self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")
end

function ListItemElement:loadProfile(profile, applyProfile)
	ListItemElement:superClass().loadProfile(self, profile, applyProfile)

	self.allowSelected = profile:getBool("allowSelected", self.allowSelected)
	self.autoSelectChildren = profile:getBool("autoSelectChildren", self.autoSelectChildren)
	self.hideSelection = profile:getBool("hideSelection", self.hideSelection)

	if not self.alternateBackgroundLoaded then
		self.backgroundColor = table.copy(GuiOverlay.getOverlayColor(self.overlay, GuiOverlay.STATE_NORMAL))
		self.alternateBackgroundColor = GuiUtils.getColorArray(profile:getValue("alternateBackgroundColor"))
		self.alternateBackgroundLoaded = true
	end
end

function ListItemElement:copyAttributes(src)
	ListItemElement:superClass().copyAttributes(self, src)

	self.allowSelected = src.allowSelected
	self.isSectionHeader = src.isSectionHeader
	self.autoSelectChildren = src.autoSelectChildren
	self.hideSelection = src.hideSelection
	self.backgroundColor = src.backgroundColor
	self.alternateBackgroundColor = src.alternateBackgroundColor
	self.alternateBackgroundLoaded = src.alternateBackgroundLoaded
	self.onLeaveCallback = src.onLeaveCallback
	self.onFocusCallback = src.onFocusCallback
	self.onClickCallback = src.onClickCallback
end

function ListItemElement:getIsSelected()
	if self:getOverlayState() == GuiOverlay.STATE_SELECTED then
		return true
	else
		return ListItemElement:superClass().getIsSelected(self)
	end
end

function ListItemElement:onClose()
	ListItemElement:superClass().onClose(self)
	self:reset()
end

function ListItemElement:clone(parent, includeId, suppressOnCreate)
	local clone = ListItemElement:superClass().clone(self, parent, includeId, suppressOnCreate)

	clone:findAllAttributes()

	return clone
end

function ListItemElement:setSelected(selected)
	if selected and not self.hideSelection then
		if self.allowSelected then
			self:setOverlayState(GuiOverlay.STATE_SELECTED)
		else
			self:setOverlayState(GuiOverlay.STATE_FOCUSED)
		end
	elseif self:getOverlayState() ~= GuiOverlay.STATE_HIGHLIGHTED then
		if self.disabled then
			self:setOverlayState(GuiOverlay.STATE_DISABLED)
		else
			self:setOverlayState(GuiOverlay.STATE_NORMAL)
		end
	end
end

function ListItemElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsVisible() then
		if ListItemElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed) then
			eventUsed = true
		end

		if not eventUsed and GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2]) then
			if not isDown and not isUp then
				if self:getOverlayState() ~= GuiOverlay.STATE_SELECTED and self.handleFocus then
					FocusManager:setHighlight(self)
				end

				if not self.mouseEntered then
					self.mouseEntered = true

					if self.handleFocus then
						self:raiseCallback("onFocusCallback", self)
					end
				end
			end

			if isDown and button == Input.MOUSE_BUTTON_LEFT then
				self.mouseDown = true
			end

			if isUp and button == Input.MOUSE_BUTTON_LEFT and self.mouseDown then
				self.mouseDown = false

				self:raiseCallback("onClickCallback", self)
			end
		else
			if self.mouseEntered then
				self.mouseEntered = false

				if self.handleFocus then
					self:raiseCallback("onLeaveCallback", self)
				end
			end

			self.mouseDown = false

			if not self.focusActive and self.handleFocus and self:getOverlayState() ~= GuiOverlay.STATE_SELECTED then
				FocusManager:unsetHighlight(self)
			end
		end
	end

	return eventUsed
end

function ListItemElement:onGuiSetupFinished()
	ListItemElement:superClass().onGuiSetupFinished(self)
	self:findAllAttributes()
end

function ListItemElement:getFocusTarget(incomingDirection, moveDirection)
	if self.autoSelectChildren then
		return ListItemElement:superClass().getFocusTarget(self, incomingDirection, moveDirection)
	else
		return self
	end
end

function ListItemElement:findAllAttributes()
	local function search(elements)
		for i = 1, #elements do
			local element = elements[i]
			local name = elements[i].name

			if name ~= nil then
				self.attributes[name] = element
			end

			search(element.elements)
		end
	end

	search(self.elements)
end

function ListItemElement:getAttribute(name)
	return self.attributes[name]
end

function ListItemElement:setAlternating(isAlternate)
	if self.alternateBackgroundColor == nil then
		return
	end

	if isAlternate then
		self:setImageColor(GuiOverlay.STATE_NORMAL, unpack(self.alternateBackgroundColor))
	else
		self:setImageColor(GuiOverlay.STATE_NORMAL, unpack(self.backgroundColor))
	end
end
