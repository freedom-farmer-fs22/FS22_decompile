VoteDialog = {
	CONTROLS = {
		"stars",
		"okButton"
	}
}
local VoteDialog_mt = Class(VoteDialog, MessageDialog)

function VoteDialog.new(target, custom_mt)
	local self = MessageDialog.new(target, custom_mt or VoteDialog_mt)

	self:registerControls(VoteDialog.CONTROLS)

	self.value = 0
	self.isBackAllowed = true
	self.inputDelay = 250

	return self
end

function VoteDialog:onClickBack(forceBack, usedMenuButton)
	self:close()

	if self.callback ~= nil then
		if self.target ~= nil then
			self.callback(self.target, self.args, nil)
		else
			self.callback(self.args, nil)
		end
	end

	return false
end

function VoteDialog:onClickOk()
	if self.value == 0 then
		return
	end

	if self.inputDelay < self.time then
		self:close()

		if self.callback ~= nil then
			if self.target ~= nil then
				self.callback(self.target, self.value)
			else
				self.callback(self.value)
			end
		end

		return false
	else
		return true
	end
end

function VoteDialog:setCallback(callback, target)
	self.callback = callback
	self.target = target
end

function VoteDialog:setValue(value)
	self.value = value or 5

	self:setStars(self.value)
	self.okButton:setDisabled(value == 0)
	FocusManager:setFocus(self.stars[value])
end

function VoteDialog:onStarHighlight(element)
	local focus = self:getValueForElement(element)

	self:setStars(focus)
end

function VoteDialog:onStarHighlightRemove()
	self:setStars(self.value)
end

function VoteDialog:onStarFocus(element)
	local focus = self:getValueForElement(element)

	self:setValue(focus)
end

function VoteDialog:onStarClick(element)
	self:setValue(self:getValueForElement(element))
end

function VoteDialog:getValueForElement(element)
	for i, elem in ipairs(self.stars) do
		if element == elem then
			return i
		end
	end

	return nil
end

function VoteDialog:setStars(value)
	for i = 1, value do
		self.stars[i]:applyProfile("voteDialogStarButtonActive")
	end

	for i = value + 1, 5 do
		self.stars[i]:applyProfile("voteDialogStarButton")
	end
end
