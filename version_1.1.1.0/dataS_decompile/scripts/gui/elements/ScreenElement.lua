ScreenElement = {
	CONTROLS = {
		PAGE_SELECTOR = "pageSelector"
	}
}
local ScreenElement_mt = Class(ScreenElement, FrameElement)

function ScreenElement.new(target, custom_mt)
	local self = FrameElement.new(target, custom_mt or ScreenElement_mt)
	self.isBackAllowed = true
	self.handleCursorVisibility = true
	self.returnScreenName = nil
	self.returnScreen = nil
	self.returnScreenClass = nil
	self.isOpen = false
	self.lastMouseCursorState = false
	self.isInitialized = false
	self.nextClickSoundMuted = false

	self:registerControls(ScreenElement.CONTROLS)

	return self
end

function ScreenElement:onOpen()
	local rootElement = self:getRootElement()

	for _, child in ipairs(rootElement.elements) do
		child:onOpen()
	end

	if not self.isInitialized then
		self:initializeScreen()
	end

	self.lastMouseCursorState = g_inputBinding:getShowMouseCursor()

	g_inputBinding:setShowMouseCursor(true)

	self.isOpen = true
end

function ScreenElement:initializeScreen()
	self.isInitialized = true

	if self.pageSelector ~= nil and self.pageSelector.disableButtonSounds ~= nil then
		self.pageSelector:disableButtonSounds()
	end
end

function ScreenElement:onClose()
	local rootElement = self:getRootElement()

	for _, child in ipairs(rootElement.elements) do
		child:onClose()
	end

	if self.handleCursorVisibility then
		g_inputBinding:setShowMouseCursor(self.lastMouseCursorState)
	end

	self.isOpen = false
end

function ScreenElement:onClickOk()
	return true
end

function ScreenElement:onClickActivate()
	return true
end

function ScreenElement:onClickCancel()
	return true
end

function ScreenElement:onClickMenuExtra1()
	return true
end

function ScreenElement:onClickMenuExtra2()
	return true
end

function ScreenElement:onClickMenu()
	return true
end

function ScreenElement:onClickShop()
	return true
end

function ScreenElement:onPagePrevious()
	self.pageSelector:inputLeft(true)
end

function ScreenElement:onPageNext()
	self.pageSelector:inputRight(true)
end

function ScreenElement:onClickBack(forceBack, usedMenuButton)
	local eventUnused = true

	if self.isBackAllowed or forceBack then
		if self.returnScreenName ~= nil then
			g_gui:showGui(self.returnScreenName)

			eventUnused = false
		elseif self.returnScreenClass ~= nil then
			self:changeScreen(self.returnScreenClass)

			eventUnused = false
		end
	end

	return eventUnused
end

function ScreenElement:onBackAction()
	return self:onClickBack()
end

function ScreenElement:invalidateScreen()
end

function ScreenElement.callButtonsWithAction(list, action)
	for i = 1, #list do
		local element = list[i]

		if element:isa(ButtonElement) and element:getIsActive() and element.inputActionName == action then
			element:sendAction()

			return true
		elseif ScreenElement.callButtonsWithAction(element.elements, action) then
			return true
		end
	end

	return false
end

function ScreenElement:inputEvent(action, value, eventUsed)
	eventUsed = ScreenElement:superClass().inputEvent(self, action, value, eventUsed)

	if self.inputDisableTime <= 0 then
		if self.pageSelector ~= nil and (action == InputAction.MENU_PAGE_PREV or action == InputAction.MENU_PAGE_NEXT) then
			if action == InputAction.MENU_PAGE_PREV then
				self:onPagePrevious()
			elseif action == InputAction.MENU_PAGE_NEXT then
				self:onPageNext()
			end

			eventUsed = true
		end

		eventUsed = eventUsed or ScreenElement.callButtonsWithAction(self.elements, action)
	end

	return eventUsed
end

function ScreenElement:inputReleaseEvent(action, value, eventUsed)
	eventUsed = ScreenElement:superClass().inputReleaseEvent(self, action, value, eventUsed)

	if self.pageSelector ~= nil and (action == InputAction.MENU_PAGE_PREV or action == InputAction.MENU_PAGE_NEXT) then
		self.pageSelector.leftDelayTime = 0
		self.pageSelector.rightDelayTime = 0

		return true
	end
end

function ScreenElement:setReturnScreen(screenName, screen)
	self.returnScreenName = screenName
	self.returnScreen = screen
end

function ScreenElement:setReturnScreenClass(returnScreenClass)
	self.returnScreenClass = returnScreenClass
end

function ScreenElement:getIsOpen()
	return self.isOpen
end

function ScreenElement:canReceiveFocus()
	if not self.visible then
		return false
	end

	for i = 1, #self.elements do
		if not self.elements[i]:canReceiveFocus() then
			return false
		end
	end

	return true
end

function ScreenElement:setNextScreenClickSoundMuted(value)
	if value == nil then
		value = true
	end

	self.nextClickSoundMuted = value
end
