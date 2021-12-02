YesNoDialog = {
	CONTROLS = {
		NO_BUTTON = "noButton",
		DIALOG_TITLE = "dialogTitleElement",
		YES_BUTTON = "yesButton"
	}
}
local YesNoDialog_mt = Class(YesNoDialog, MessageDialog)

function YesNoDialog.new(target, custom_mt)
	local self = MessageDialog.new(target, custom_mt or YesNoDialog_mt)
	self.isBackAllowed = false
	self.inputDelay = 250

	self:registerControls(YesNoDialog.CONTROLS)

	return self
end

function YesNoDialog:onCreate()
	YesNoDialog:superClass().onCreate(self)
	self:setDialogType(DialogElement.TYPE_QUESTION)

	if self.dialogTitleElement ~= nil then
		self.defaultTitle = self.dialogTitleElement.text
	end

	self.defaultYesText = self.yesButton.text
	self.defaultNoText = self.noButton.text
end

function YesNoDialog:onOpen()
	YesNoDialog:superClass().onOpen(self)

	self.inputDelay = self.time + 250
end

function YesNoDialog:onClose()
	self:setDialogType(DialogElement.TYPE_QUESTION)
	self:setTitle(nil)
	self:setText(nil)
	self:setButtonTexts(self.defaultYesText, self.defaultNoText)
	YesNoDialog:superClass().onClose(self)
end

function YesNoDialog:sendCallback(value)
	if self.inputDelay < self.time then
		self:close()

		if self.callbackFunc ~= nil then
			if self.target ~= nil then
				self.callbackFunc(self.target, value, self.callbackArgs)
			else
				self.callbackFunc(value, self.callbackArgs)
			end
		end
	end
end

function YesNoDialog:setCallback(callbackFunc, target, args)
	self.callbackFunc = callbackFunc
	self.target = target
	self.callbackArgs = args
end

function YesNoDialog:setTitle(text)
	if self.dialogTitleElement ~= nil then
		self.dialogTitleElement:setText(Utils.getNoNil(text, self.defaultTitle))
	end
end

function YesNoDialog:setButtonTexts(yesText, noText)
	self.yesButton:setText(Utils.getNoNil(yesText, self.defaultYesText))
	self.noButton:setText(Utils.getNoNil(noText, self.defaultNoText))
end

function YesNoDialog:setButtonSounds(yesSound, noSound)
	self.yesButton.clickSoundName = Utils.getNoNil(yesSound, self.yesButton.clickSoundName)
	self.noButton.clickSoundName = Utils.getNoNil(noSound, self.noButton.clickSoundName)
end

function YesNoDialog:onYes(sender)
	self:sendCallback(true)
end

function YesNoDialog:onNo(sender)
	self:sendCallback(false)
end
