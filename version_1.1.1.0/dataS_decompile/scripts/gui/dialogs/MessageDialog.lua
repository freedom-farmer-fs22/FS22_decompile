MessageDialog = {
	CONTROLS = {
		"dialogElement",
		"dialogTextElement"
	}
}
local MessageDialog_mt = Class(MessageDialog, DialogElement)

function MessageDialog.new(target, custom_mt)
	local self = DialogElement.new(target, custom_mt or MessageDialog_mt)

	self:registerControls(MessageDialog.CONTROLS)

	self.isBackAllowed = false

	return self
end

function MessageDialog:onCreate(element)
	self.defaultDialogHeight = self.dialogElement.size[2]

	if self.dialogTextElement ~= nil then
		local defaultTextHeight, _ = self.dialogTextElement:getTextHeight()
		self.defaultDialogHeight = self.defaultDialogHeight - defaultTextHeight
		self.defaultText = self.dialogTextElement.text
	end

	self:setDialogType(DialogElement.TYPE_WARNING)
end

function MessageDialog:onOpen()
	MessageDialog:superClass().onOpen(self)

	if not self.disableOpenSound then
		if self.dialogType == DialogElement.TYPE_WARNING then
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		else
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.QUERY)
		end
	end
end

function MessageDialog:setText(text)
	if self.dialogTextElement ~= nil then
		self.dialogTextElement:setText(Utils.getNoNil(text, self.defaultText))

		local textHeight, _ = self.dialogTextElement:getTextHeight()

		self:resizeDialog(textHeight)
	end
end

function MessageDialog:resizeDialog(heightOffset)
	self.dialogElement:setSize(nil, self.defaultDialogHeight + heightOffset)
end

function MessageDialog:setUpdateCallback(callback, callbackTarget, args)
	self.updateCallback = callback
	self.updateCallbackTarget = callbackTarget
	self.updateCallbackArgs = args
end

function MessageDialog:update(dt)
	MessageDialog:superClass().update(self, dt)

	if self.updateCallback ~= nil then
		if self.updateCallbackTarget ~= nil then
			self.updateCallback(self.updateCallbackTarget, dt, self.updateCallbackArgs)
		else
			self.updateCallback(dt, self.updateCallbackArgs)
		end
	end
end
