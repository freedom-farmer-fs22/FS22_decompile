OptionDialog = {
	CONTROLS = {
		"optionElement"
	}
}
local OptionDialog_mt = Class(OptionDialog, YesNoDialog)

function OptionDialog.new(target, custom_mt)
	local self = YesNoDialog.new(target, custom_mt or OptionDialog_mt)

	self:registerControls(OptionDialog.CONTROLS)

	return self
end

function OptionDialog:onClickOk()
	if self.areButtonsDisabled then
		return true
	else
		self:sendCallback(self.optionElement:getState())

		return false
	end
end

function OptionDialog:onClickBack(forceBack, usedMenuButton)
	self:sendCallback(0)

	return false
end

function OptionDialog:setOptions(options)
	self.options = options

	self.optionElement:setTexts(options)
end
