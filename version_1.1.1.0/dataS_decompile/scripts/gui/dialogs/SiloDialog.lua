SiloDialog = {
	CONTROLS = {
		SILO_ICON = "siloIcon",
		SILO_TEXT = "siloText",
		FILL_TYPES_ELEMENT = "fillTypesElement",
		MESSAGE_BACKGROUND = "messageBackground"
	}
}
local SiloDialog_mt = Class(SiloDialog, YesNoDialog)

function SiloDialog.new(target, custom_mt)
	local self = YesNoDialog.new(target, custom_mt or SiloDialog_mt)
	self.selectedFillType = nil
	self.areButtonsDisabled = false
	self.lastSelectedFillType = nil

	self:registerControls(SiloDialog.CONTROLS)

	return self
end

function SiloDialog:onClickOk()
	if self.areButtonsDisabled then
		return true
	else
		self.lastSelectedFillType = self.selectedFillType

		self:sendCallback(self.selectedFillType)

		return false
	end
end

function SiloDialog:onClickBack(forceBack, usedMenuButton)
	self:sendCallback(FillType.UNKNOWN)

	return false
end

function SiloDialog:onClickFillTypes(state)
	self:setButtonDisabled(false)

	self.selectedFillType = self.fillTypeMapping[state]

	if self.fillLevels ~= nil then
		local siloAmount = self.fillLevels[self.selectedFillType]

		if siloAmount <= 0 then
			self:setButtonDisabled(true)
		end
	end

	local width = self.siloText:getTextWidth()

	self.siloIcon:setPosition(self.siloText.position[1] - width * 0.5 - self.siloIcon.margin[3], nil)

	local fillType = g_fillTypeManager:getFillTypeByIndex(self.selectedFillType)

	self.siloIcon:setImageFilename(fillType.hudOverlayFilename)
end

function SiloDialog:setFillLevels(fillLevels, hasInfiniteCapacity)
	self.fillLevels = fillLevels
	self.fillTypeMapping = {}
	local fillTypesTable = {}
	local selectedId = 1
	local numFillLevels = 1

	for fillTypeIndex, _ in pairs(fillLevels) do
		local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
		local level = Utils.getNoNil(fillLevels[fillTypeIndex], 0)
		local name = nil

		if hasInfiniteCapacity then
			name = string.format("%s", fillType.title)
		else
			name = string.format("%s %s", fillType.title, g_i18n:formatFluid(level))
		end

		table.insert(fillTypesTable, name)
		table.insert(self.fillTypeMapping, fillTypeIndex)

		if fillTypeIndex == self.lastSelectedFillType then
			selectedId = numFillLevels
		end

		numFillLevels = numFillLevels + 1
	end

	self.fillTypesElement:setTexts(fillTypesTable)
	self.fillTypesElement:setState(selectedId, true)
end

function SiloDialog:setButtonDisabled(disabled)
	self.messageBackground:setVisible(disabled)

	self.areButtonsDisabled = disabled

	self.yesButton:setDisabled(disabled)
end
