ToggleButtonElement = {}
local ToggleButtonElement_mt = Class(ToggleButtonElement, BitmapElement)

function ToggleButtonElement.new(target, custom_mt)
	if custom_mt == nil then
		custom_mt = ToggleButtonElement_mt
	end

	local self = BitmapElement.new(target, custom_mt)
	self.isChecked = false

	return self
end

function ToggleButtonElement:loadFromXML(xmlFile, key)
	ToggleButtonElement:superClass().loadFromXML(self, xmlFile, key)
	self:addCallback(xmlFile, key .. "#onClick", "onClickCallback")
	self:setIsChecked(Utils.getNoNil(getXMLBool(xmlFile, key .. "#isChecked"), self.isChecked))
end

function ToggleButtonElement:loadProfile(profile, applyProfile)
	ToggleButtonElement:superClass().loadProfile(self, profile, applyProfile)
	self:setIsChecked(profile:getBool("isChecked", self.isChecked))
end

function ToggleButtonElement:copyAttributes(src)
	ToggleButtonElement:superClass().copyAttributes(self, src)

	self.isChecked = src.isChecked
	self.onClickCallback = src.onClickCallback
end

function ToggleButtonElement:setIsChecked(isChecked)
	self.isChecked = isChecked

	if self.elements[1] ~= nil then
		self.elements[1]:setVisible(self.isChecked)
	end

	if self.elements[2] ~= nil then
		self.elements[2]:setVisible(not self.isChecked)
	end
end

function ToggleButtonElement:addElement(element)
	ToggleButtonElement:superClass().addElement(self, element)

	if table.getn(self.elements) <= 2 then
		element.target = self

		element:setCallback("onClickCallback", "onButtonClicked")
		self:setIsChecked(self.isChecked)
		self:setDisabled(self.disabled)
	end
end

function ToggleButtonElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		if not eventUsed and GuiUtils.checkOverlayOverlap(posX, posY, self.absPosition[1], self.absPosition[2], self.size[1], self.size[2]) then
			FocusManager:setHighlight(self)
		else
			FocusManager:unsetHighlight(self)
		end

		return ToggleButtonElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
	end

	return false
end

function ToggleButtonElement:onButtonClicked()
	self:setIsChecked(not self.isChecked)

	if self.onClickCallback ~= nil then
		if self.target ~= nil then
			self.onClickCallback(self.target, self, self.isChecked)
		else
			self:onClickCallback(self.isChecked)
		end
	end
end

function ToggleButtonElement:canReceiveFocus()
	return not self.disabled and not not self:getIsVisible()
end

function ToggleButtonElement:getFocusTarget()
	return self
end

function ToggleButtonElement:onFocusLeave()
	if self.elements[1] ~= nil then
		self.elements[1]:onFocusLeave()
	end

	if self.elements[2] ~= nil then
		self.elements[2]:onFocusLeave()
	end
end

function ToggleButtonElement:onFocusEnter()
	if self.elements[1] ~= nil then
		self.elements[1]:onFocusEnter()
	end

	if self.elements[2] ~= nil then
		self.elements[2]:onFocusEnter()
	end
end

function ToggleButtonElement:onFocusActivate()
	self:onButtonClicked()
end
