EditFarmDialog = {}
local EditFarmDialog_mt = Class(EditFarmDialog, ColorPickerDialog)
EditFarmDialog.MAX_COLUMNS = 8
EditFarmDialog.CONTROLS = {
	"titleText",
	"farmNameInput",
	"farmPasswordInput",
	"farmIconPreview",
	"buttonTemplate",
	"colorButtonLayout",
	"editButton",
	"dialogButtonLayout"
}

function EditFarmDialog.new(target, custom_mt, l10n, farmManager)
	if custom_mt == nil then
		custom_mt = EditFarmDialog_mt
	end

	local self = ColorPickerDialog.new(target, custom_mt)
	self.l10n = l10n
	self.farmManager = farmManager
	self.farmId = nil
	self.isCreatingNewFarm = true
	self.availableColorIndexMap = {}
	self.availableColors = {}
	self.selectedColorIndex = 1

	self:registerControls(EditFarmDialog.CONTROLS)

	return self
end

function EditFarmDialog:onClose()
	EditFarmDialog:superClass().onClose(self)

	self.isCreatingNewFarm = true
end

function EditFarmDialog:setExistingFarm(farmId)
	self.farmId = farmId

	self:storeAvailableColors(farmId)

	if farmId ~= nil and farmId ~= FarmManager.INVALID_FARM_ID and farmId ~= FarmManager.SPECTATOR_FARM_ID then
		self.isCreatingNewFarm = false
		local farm = self.farmManager:getFarmById(farmId)
		local titleTemplate = self.l10n:getText(EditFarmDialog.L10N_SYMBOL.TITLE_EDIT_FARM_TEMPLATE)
		local title = string.format(titleTemplate, farm.name)

		self.titleText:setText(title)
		self.farmNameInput:setText(farm.name)
		self.farmPasswordInput:setText(farm.password or "")

		self.selectedColorIndex = farm.color

		self:setButtonTexts(self.l10n:getText(EditFarmDialog.L10N_SYMBOL.BUTTON_CONFIRM))
	else
		self.titleText:setText(self.l10n:getText(EditFarmDialog.L10N_SYMBOL.TITLE_CREATE_FARM))
		self.farmNameInput:setText(self.l10n:getText(EditFarmDialog.L10N_SYMBOL.DEFAULT_FARM_NAME))
		self.farmPasswordInput:setText("")

		self.selectedColorIndex = self.availableColorIndexMap[1]

		self:setButtonTexts(self.l10n:getText(EditFarmDialog.L10N_SYMBOL.BUTTON_CREATE))
	end

	self.farmIconPreview:setImageUVs(nil, unpack(GuiUtils.getUVs(Farm.ICON_UVS[self.selectedColorIndex])))
	self:setColors(self.availableColors, self.availableColors[1])
	self.dialogButtonLayout:invalidateLayout()
end

function EditFarmDialog:storeAvailableColors(editingFarmId)
	self.availableColors = {}
	self.availableColorIndexMap = {}
	local colorBlind = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE)
	local farms = self.farmManager:getFarms()

	for farmColorIndex, color in ipairs(Farm.COLORS) do
		local colorTaken = false

		for _, farm in pairs(farms) do
			if farm.farmId ~= FarmManager.SPECTATOR_FARM_ID and farm.farmId ~= editingFarmId and farm.color == farmColorIndex then
				colorTaken = true

				break
			end
		end

		if not colorTaken then
			table.insert(self.availableColors, color)

			self.availableColorIndexMap[#self.availableColors] = farmColorIndex
		end
	end
end

function EditFarmDialog:resizeDialog(heightOffset)
end

function EditFarmDialog:focusLinkColorButtons(numCols)
	EditFarmDialog:superClass().focusLinkColorButtons(self, numCols)

	for i = 1, #self.colorButtonLayout.elements do
		local button = self.colorButtonLayout.elements[i]

		FocusManager:linkElements(button, FocusManager.TOP, self.farmPasswordInput)
		FocusManager:linkElements(button, FocusManager.BOTTOM, self.farmNameInput)
	end
end

function EditFarmDialog:setInitialFocus()
end

function EditFarmDialog:onClickColorButton(element)
	local buttonIndex = self.colorMapping[element]
	self.selectedColorIndex = self.availableColorIndexMap[buttonIndex]

	self.farmIconPreview:setImageUVs(nil, unpack(GuiUtils.getUVs(Farm.ICON_UVS[self.selectedColorIndex])))
end

function EditFarmDialog:onClickDone()
	local farmName = self.farmNameInput.text
	local password = self.farmPasswordInput.text

	if password == "" then
		password = nil
	end

	local filteredName = filterText(farmName, true, true)

	if farmName ~= "" then
		if farmName ~= filteredName then
			self.farmNameInput:setText(filteredName)
			Logging.info("Entered farm name contains profanity and has been adjusted.")
		else
			if self.isCreatingNewFarm then
				g_client:getServerConnection():sendEvent(FarmCreateUpdateEvent.new(farmName, self.selectedColorIndex, password, false, nil))
			else
				g_client:getServerConnection():sendEvent(FarmCreateUpdateEvent.new(farmName, self.selectedColorIndex, password, true, self.farmId))
			end

			self:close()
		end
	end

	return false
end

function EditFarmDialog:onClickEdit()
	local focusedElement = FocusManager:getFocusedElement()

	if focusedElement == self.farmNameInput then
		self.farmNameInput:onFocusActivate()
	elseif focusedElement == self.farmPasswordInput then
		self.farmPasswordInput:onFocusActivate()
	else
		for _, button in ipairs(self.colorButtonLayout.elements) do
			if button == focusedElement then
				button:sendAction()
			end
		end
	end
end

EditFarmDialog.L10N_SYMBOL = {
	TITLE_EDIT_FARM_TEMPLATE = "ui_editFarm",
	TITLE_CREATE_FARM = "ui_createNewFarm",
	BUTTON_CONFIRM = "button_confirm",
	BUTTON_CREATE = "button_mp_createFarm",
	DEFAULT_FARM_NAME = "ui_defaultFarmName"
}
