AnimalDialog = {
	CONTROLS = {
		HUSBANDRY_TEXT = "husbandryText",
		HUSBANDRIES_ELEMENT = "husbandriesElement"
	}
}
local AnimalDialog_mt = Class(AnimalDialog, YesNoDialog)

function AnimalDialog.new(target, custom_mt)
	local self = YesNoDialog.new(target, custom_mt or AnimalDialog_mt)
	self.selectedHusbandry = nil

	self:registerControls(AnimalDialog.CONTROLS)

	return self
end

function AnimalDialog:onClickOk()
	self:sendCallback(self.selectedHusbandry)

	return false
end

function AnimalDialog:onClickBack(forceBack, usedMenuButton)
	self:sendCallback(nil)

	return false
end

function AnimalDialog:onClickHusbandry(state)
	self.selectedHusbandry = self.husbandries[state]
end

function AnimalDialog:setHusbandries(husbandries)
	self.husbandries = husbandries
	local husbandryTexts = {}

	for k, husbandry in ipairs(husbandries) do
		table.insert(husbandryTexts, string.format("(%d) %s", k, husbandry:getName()))
	end

	self.husbandriesElement:setTexts(husbandryTexts)
	self.husbandriesElement:setState(1, true)
end
