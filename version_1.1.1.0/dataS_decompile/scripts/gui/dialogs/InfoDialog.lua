InfoDialog = {
	CONTROLS = {
		OK_BUTTON = "okButton"
	}
}
local InfoDialog_mt = Class(InfoDialog, MessageDialog)

function InfoDialog.new(target, custom_mt)
	local self = MessageDialog.new(target, custom_mt or InfoDialog_mt)

	self:registerControls(InfoDialog.CONTROLS)

	self.buttonAction = InputAction.MENU_ACCEPT
	self.isBackAllowed = false
	self.inputDelay = 250

	return self
end

function InfoDialog:onCreate()
	InfoDialog:superClass().onCreate(self)
	self:setDialogType(DialogElement.TYPE_INFO)

	self.defaultOkText = self.okButton.text
end

function InfoDialog:onOpen()
	InfoDialog:superClass().onOpen(self)

	self.inputDelay = self.time + 250
end

function InfoDialog:onClose()
	InfoDialog:superClass().onClose(self)
	self:setButtonTexts(self.defaultOkText)

	self.buttonAction = InputAction.MENU_ACCEPT

	self:setButtonAction(InputAction.MENU_ACCEPT)
	self:setText("")
end

function InfoDialog:acceptDialog(inputAction, force)
	if (inputAction == self.buttonAction or force) and self.inputDelay < self.time then
		self:close()

		if self.onOk ~= nil then
			if self.target ~= nil then
				self.onOk(self.target, self.args)
			else
				self.onOk(self.args)
			end
		end

		return false
	else
		return true
	end
end

function InfoDialog:onClickBack(forceBack, usedMenuButton)
	if not usedMenuButton then
		return self:acceptDialog(InputAction.MENU_BACK, true)
	else
		return true
	end
end

function InfoDialog:onClickOk()
	return self:acceptDialog(self.buttonAction, false)
end

function InfoDialog:setCallback(onOk, target, args)
	self.onOk = onOk
	self.target = target
	self.args = args
end

function InfoDialog:setButtonTexts(okText)
	self.okButton:setText(Utils.getNoNil(okText, self.defaultOkText))
end

function InfoDialog:setButtonAction(buttonAction)
	if buttonAction ~= nil then
		self.buttonAction = buttonAction

		self.okButton:setInputAction(buttonAction)
	end
end
