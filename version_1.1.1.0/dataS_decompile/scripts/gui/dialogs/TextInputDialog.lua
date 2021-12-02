TextInputDialog = {}
local TextInputDialog_mt = Class(TextInputDialog, YesNoDialog)
TextInputDialog.CONTROLS = {
	TEXT_INPUT = "textElement"
}

local function NO_CALLBACK()
end

function TextInputDialog.new(target, custom_mt, inputManager)
	local self = YesNoDialog.new(target, custom_mt or TextInputDialog_mt)

	self:registerControls(TextInputDialog.CONTROLS)

	self.inputManager = inputManager
	self.onTextEntered = NO_CALLBACK
	self.callbackArgs = nil
	self.extraInputDisableTime = 0
	self.doHide = GS_IS_CONSOLE_VERSION and imeIsSupported()
	self.disableOpenSound = true

	return self
end

function TextInputDialog:onOpen()
	TextInputDialog:superClass().onOpen(self)

	self.extraInputDisableTime = 100

	FocusManager:setFocus(self.textElement)

	self.textElement.blockTime = 0

	self.textElement:onFocusActivate()

	if self.textElement.imeActive then
		if self.yesButton ~= nil then
			self.yesButton:setVisible(false)
		end

		if self.noButton ~= nil then
			self.noButton:setVisible(false)
		end
	end
end

function TextInputDialog:onClose()
	TextInputDialog:superClass().onClose(self)

	if not GS_IS_CONSOLE_VERSION then
		self.textElement:setForcePressed(false)
	end

	if self.yesButton ~= nil then
		self.yesButton:setVisible(true)
	end

	if self.noButton ~= nil then
		self.noButton:setVisible(true)
	end
end

function TextInputDialog:setCallback(onTextEntered, target, defaultInputText, dialogPrompt, imePrompt, maxCharacters, callbackArgs, isPasswordDialog, disableFilter)
	self.onTextEntered = onTextEntered or NO_CALLBACK
	self.target = target
	self.callbackArgs = callbackArgs

	self.textElement:setText(defaultInputText or "")

	self.textElement.maxCharacters = maxCharacters or self.textElement.maxCharacters
	self.isPasswordDialog = isPasswordDialog or false
	self.disableFilter = disableFilter or false

	if dialogPrompt ~= nil then
		self.dialogTextElement:setText(dialogPrompt)
	end

	if imePrompt ~= nil then
		self.textElement.imeTitle = imePrompt
		self.textElement.imeDescription = imePrompt
		self.textElement.imePlaceholder = imePrompt
	end
end

function TextInputDialog:sendCallback(clickOk)
	local text = self.textElement.text

	self:close()

	if self.target ~= nil then
		self.onTextEntered(self.target, text, clickOk, self.callbackArgs)
	else
		self.onTextEntered(text, clickOk, self.callbackArgs)
	end
end

function TextInputDialog:onEnterPressed(element, dismissal)
	if not dismissal then
		return self:onClickOk()
	end

	return true
end

function TextInputDialog:onEscPressed(element)
	return self:onClickBack()
end

function TextInputDialog:onClickBack(forceBack, usedMenuButton)
	if not self:isInputDisabled() then
		self:sendCallback(false)

		return false
	else
		return true
	end
end

function TextInputDialog:onClickOk()
	if not self:isInputDisabled() then
		if not self.isPasswordDialog and self.disableFilter ~= true then
			local baseText = self.textElement.text
			local filteredText = filterText(baseText, true, true)

			if baseText ~= "" and baseText ~= filteredText then
				self.textElement:setText(filteredText)
				Logging.info("Entered text contains profanity and has been adjusted.")

				return false
			end
		end

		self:sendCallback(true)

		return false
	else
		return true
	end
end

function TextInputDialog:update(dt)
	TextInputDialog:superClass().update(self, dt)

	if self.extraInputDisableTime > 0 then
		self.extraInputDisableTime = self.extraInputDisableTime - dt
	end
end

function TextInputDialog:isInputDisabled()
	return self.extraInputDisableTime > 0 and not self.doHide
end

function TextInputDialog:disableInputForDuration(duration)
end

function TextInputDialog:getIsVisible()
	if self.doHide then
		return false
	end

	return TextInputDialog:superClass().getIsVisible(self)
end
