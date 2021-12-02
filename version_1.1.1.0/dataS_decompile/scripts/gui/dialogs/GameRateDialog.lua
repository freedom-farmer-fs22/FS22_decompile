GameRateDialog = {
	CONTROLS = {
		"okButton",
		"stars"
	}
}
local GameRateDialog_mt = Class(GameRateDialog, MessageDialog)

function GameRateDialog.new(target, custom_mt)
	local self = MessageDialog:new(target, custom_mt or GameRateDialog_mt)
	self.isBackAllowed = false
	self.inputDelay = 250
	self.value = 0

	self:registerControls(GameRateDialog.CONTROLS)

	return self
end

function GameRateDialog:onOpen()
	GameRateDialog:superClass().onOpen(self)
	self:setValue(0)
end

function GameRateDialog:onClose()
	GameRateDialog:superClass().onClose(self)
end

function GameRateDialog:onClickOk()
	self:close()
	openWebFile("lp/fs20-rating.php", "rating=" .. self.value .. "&v2=true")

	return true
end

function GameRateDialog:onClickBack()
	self:close()

	return true
end

function GameRateDialog:onStarHighlight(element)
	local focus = self:getValueForElement(element)

	self:setStars(focus)
end

function GameRateDialog:onStarHighlightRemove()
	self:setStars(self.value)
end

function GameRateDialog:onStarFocus(element)
	local focus = self:getValueForElement(element)

	self:setValue(focus)
end

function GameRateDialog:onStarClick(element)
	self:setValue(self:getValueForElement(element))
end

function GameRateDialog:setValue(value)
	self.value = value or 5

	self:setStars(self.value)

	if self.stars ~= 0 then
		FocusManager:setFocus(self.stars[value])
	end

	self.okButton:setDisabled(self.value == 0)
end

function GameRateDialog:setStars(value)
	for i = 1, value do
		self.stars[i]:applyProfile("voteDialogStarButtonActive")
	end

	for i = value + 1, 5 do
		self.stars[i]:applyProfile("voteDialogStarButton")
	end
end

function GameRateDialog:getValueForElement(element)
	for i, elem in ipairs(self.stars) do
		if element == elem then
			return i
		end
	end

	return nil
end
