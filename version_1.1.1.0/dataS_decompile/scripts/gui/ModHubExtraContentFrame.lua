ModHubExtraContentFrame = {}
local ModHubExtraContentFrame_mt = Class(ModHubExtraContentFrame, TabbedMenuFrameElement)
ModHubExtraContentFrame.CONTROLS = {
	ITEMS_LIST = "itemsList",
	ITEM_BOX = "itemDescriptionBox",
	ITEM_NAME = "itemDescription",
	NO_ITEMS = "noItemsElement",
	HEADER_TEXT = "headerText",
	NAVIGATION_HEADER = "breadcrumbs"
}

function ModHubExtraContentFrame.new(subclass_mt)
	local self = TabbedMenuFrameElement.new(nil, subclass_mt or ModHubExtraContentFrame_mt)

	self:registerControls(ModHubExtraContentFrame.CONTROLS)

	self.items = {}
	self.title = ""

	return self
end

function ModHubExtraContentFrame:onGuiSetupFinished()
	ModHubExtraContentFrame:superClass().onGuiSetupFinished(self)
	self.itemsList:setDataSource(self)
	self.itemsList:setDelegate(self)
end

function ModHubExtraContentFrame:initialize(title)
	self.title = title

	self.headerText:setText(title)

	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.unlockButton = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.BUTTON_UNLOCK),
		callback = function ()
			self:onButtonUnlock()
		end
	}
end

function ModHubExtraContentFrame:onFrameOpen()
	ModHubExtraContentFrame:superClass().onFrameOpen(self)
	self:updateList()
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.itemsList)
	self:setSoundSuppressed(false)
end

function ModHubExtraContentFrame:getMenuButtonInfo()
	local buttons = {}

	table.insert(buttons, self.backButtonInfo)

	if g_extraContentSystem:getHasLockedItems() then
		table.insert(buttons, self.unlockButton)
	end

	return buttons
end

function ModHubExtraContentFrame:setBreadcrumbs(list)
	self.headerText:setText(list[#list])
	self.breadcrumbs:setBreadcrumbs(list)
end

function ModHubExtraContentFrame:reload()
	self:updateList()
end

function ModHubExtraContentFrame:updateList()
	self.items = g_extraContentSystem:getUnlockedItems()

	self.itemsList:reloadData()
	self.itemDescriptionBox:setVisible(#self.items > 0)
	self.noItemsElement:setVisible(#self.items == 0)
	self:setMenuButtonInfoDirty()
end

function ModHubExtraContentFrame:getMainElementSize()
	return self.itemDescriptionBox.size
end

function ModHubExtraContentFrame:getMainElementPosition()
	return self.itemDescriptionBox.absPosition
end

function ModHubExtraContentFrame:onClickLeft()
	self.itemsList:scrollTo(self.itemsList.firstVisibleItem - self.itemsList.itemsPerCol)
end

function ModHubExtraContentFrame:onClickRight()
	self.itemsList:scrollTo(self.itemsList.firstVisibleItem + self.itemsList.itemsPerCol)
end

function ModHubExtraContentFrame:onListSelectionChanged(list, section, index)
	local item = self.items[index]

	if item ~= nil then
		self.itemDescription:setText(item.description)
	end

	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end

function ModHubExtraContentFrame:onButtonUnlock(defaultText)
	g_gui:showTextInputDialog({
		disableFilter = true,
		callback = self.onExtraContentKeyEntered,
		target = self,
		dialogPrompt = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.UNLOCK_ITEM_KEY),
		imePrompt = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.UNLOCK_ITEM_KEY),
		maxCharacters = ExtraContentSystem.KEY_LENGTH,
		confirmText = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.UNLOCK_ITEM),
		defaultText = defaultText or ""
	})
end

function ModHubExtraContentFrame:onExtraContentKeyEntered(text, ok, categoryId)
	if ok then
		local upperText = text:upper()
		local item, errorCode = g_extraContentSystem:unlockItem(upperText, false)
		local message = nil

		if errorCode == ExtraContentSystem.UNLOCKED then
			self:updateList()
			g_gui:showInfoDialog({
				text = string.format(g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.UNLOCKED_ITEM), item.title)
			})

			return
		elseif errorCode == ExtraContentSystem.ERROR_ALREADY_UNLOCKED then
			message = string.format(g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.ALREADY_UNLOCKED_ITEM), item.title)
		elseif errorCode == ExtraContentSystem.ERROR_KEY_INVALID_FORMAT then
			message = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.INVALID_KEY_FORMAT)
		else
			message = g_i18n:getText(ModHubExtraContentFrame.L10N_SYMBOL.INVALID_KEY)
		end

		g_gui:showInfoDialog({
			text = message,
			callback = self.onButtonUnlock,
			target = self,
			args = text
		})
	end
end

function ModHubExtraContentFrame:getNumberOfItemsInSection(list, section)
	local total = #self.items

	if self.listSizeLimit ~= nil then
		return math.min(total, self.listSizeLimit)
	end

	return total
end

function ModHubExtraContentFrame:populateCellForItemInSection(list, section, index, cell)
	local item = self.items[index]
	local iconElement = cell:getAttribute("icon")

	iconElement:setImageFilename(item.imageFilename)
	cell:getAttribute("nameLabel"):setText(item.title)
end

ModHubExtraContentFrame.L10N_SYMBOL = {
	UNLOCKED_ITEM = "modHub_unlocked_item",
	UNLOCK_ITEM_KEY = "modHub_unlock_key",
	INVALID_KEY = "modHub_invalid_key",
	UNLOCK_ITEM = "modHub_unlock",
	ALREADY_UNLOCKED_ITEM = "modHub_already_unlocked_item",
	BUTTON_UNLOCK = "modHub_unlock",
	INVALID_KEY_FORMAT = "modHub_invalid_key_format"
}
