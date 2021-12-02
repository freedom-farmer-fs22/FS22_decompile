WardrobeOutfitsFrame = {}
local WardrobeOutfitsFrame_mt = Class(WardrobeOutfitsFrame, TabbedMenuFrameElement)
WardrobeOutfitsFrame.CONTROLS = {
	"itemList",
	"title",
	"infoText"
}

function WardrobeOutfitsFrame.new(subclass_mt)
	local self = WardrobeOutfitsFrame:superClass().new(nil, subclass_mt or WardrobeOutfitsFrame_mt)

	self:registerControls(WardrobeOutfitsFrame.CONTROLS)

	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK,
		text = g_i18n:getText("button_confirm")
	}
	self.equipButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText("button_select"),
		callback = function ()
			self:onClickSelect()
		end
	}
	self.colorButtonInfo = {
		inputAction = InputAction.MENU_CANCEL,
		text = g_i18n:getText("button_selectColor"),
		callback = function ()
			self:onClickSelectColor()
		end
	}
	self.hasCustomMenuButtons = true
	self.menuButtonInfo = {
		self.backButtonInfo,
		self.equipButtonInfo
	}
	self.indexMapping = {}
	self.isShowingColors = false

	return self
end

function WardrobeOutfitsFrame:onGuiSetupFinished()
	WardrobeOutfitsFrame:superClass().onGuiSetupFinished(self)
	self.itemList:setDataSource(self)
	self.itemList:setDelegate(self)
end

function WardrobeOutfitsFrame:initialize(delegate, titleKey)
	self.delegate = delegate

	self.title:setLocaKey(titleKey)
end

function WardrobeOutfitsFrame:setPlayerStyle(playerStyle, savedPlayerStyle)
	self.playerStyle = playerStyle
	self.savedPlayerStyle = savedPlayerStyle

	self:resetList()
end

function WardrobeOutfitsFrame:onFrameOpen()
	WardrobeOutfitsFrame:superClass().onFrameOpen(self)

	if not self.isShowingColors then
		self.delegate:onItemSelectionStart()
		self:resetList()
	end
end

function WardrobeOutfitsFrame:resetList()
	if self.playerStyle ~= nil then
		self.indexMapping = {
			{
				-1
			},
			{}
		}
		self.currentlyUsedPreset = self:getCurrentlySelectedPresetIndex()
		local selectedIndex = 1
		local selectedSection = 1

		for i, preset in ipairs(self.playerStyle.presets) do
			local section = preset.brand ~= nil and 2 or 1
			local isCurrentSelection = self.currentlyUsedPreset == i

			if preset.isSelectable and (isCurrentSelection or preset.extraContentId == nil or g_extraContentSystem:getIsItemIdUnlocked(preset.extraContentId)) then
				table.insert(self.indexMapping[section], i)

				if isCurrentSelection then
					selectedIndex = #self.indexMapping[section]
					selectedSection = section
				end
			end
		end

		self.itemList:reloadData()
		self.itemList:setSelectedItem(selectedSection, selectedIndex)
	end
end

function WardrobeOutfitsFrame:getCurrentlySelectedPresetIndex()
	for i, preset in ipairs(self.playerStyle.presets) do
		if self.savedPlayerStyle:getIsPresetUsed(preset) then
			return i
		end
	end

	return nil
end

function WardrobeOutfitsFrame:onFrameClose()
	if not self.isShowingColors then
		for _, cell in ipairs(self.itemList.elements) do
			if not cell.isHeader then
				cell:getAttribute("icon"):setImageFilename(g_baseUIFilename)
			end
		end
	end

	WardrobeOutfitsFrame:superClass().onFrameClose(self)
end

function WardrobeOutfitsFrame:updateSelectionButton()
	local item = self:getSelectedPreset()
	local hasColors = false

	if item ~= nil then
		hasColors = self:getPresetHasColors(item)
	end

	self.menuButtonInfo = {
		self.backButtonInfo,
		self.equipButtonInfo,
		hasColors and self.colorButtonInfo or nil
	}

	self:setMenuButtonInfoDirty()
end

function WardrobeOutfitsFrame:getNumberOfSections()
	return #self.indexMapping[2] > 0 and 2 or 1
end

function WardrobeOutfitsFrame:getTitleForSectionHeader(list, section)
	if section == 2 then
		return g_i18n:getText("character_section_branded")
	else
		return nil
	end
end

function WardrobeOutfitsFrame:getNumberOfItemsInSection(list, section)
	return #self.indexMapping[section]
end

function WardrobeOutfitsFrame:populateCellForItemInSection(list, section, index, cell)
	local presetIndex = self.indexMapping[section][index]

	if presetIndex == -1 then
		local icon = cell:getAttribute("icon")

		icon:setImageFilename(self.playerStyle.atlasFilename)
		icon:setImageUVs(nil, self.playerStyle:getSlotUVs(1))
		cell:getAttribute("selected"):setVisible(self.currentlyUsedPreset == nil)
		cell:getAttribute("hasColors"):setVisible(false)
	else
		local preset = self.playerStyle.presets[presetIndex]
		local icon = cell:getAttribute("icon")

		icon:setImageFilename(self.playerStyle.atlasFilename)
		icon:setImageUVs(nil, self.playerStyle:getSlotUVs(preset.uvSlot))
		cell:getAttribute("selected"):setVisible(self.currentlyUsedPreset == presetIndex)
		cell:getAttribute("hasColors"):setVisible(self:getPresetHasColors(preset))
	end
end

function WardrobeOutfitsFrame:onListSelectionChanged(list, section, index)
	local preset = self:getPresetFromItem(section, index)

	if preset == nil then
		self.delegate:onItemSelectionCancelled()
	else
		local presetIndex = self.indexMapping[section][index]

		self.playerStyle:setPreset(preset, self.currentlyUsedPreset ~= presetIndex)
		self.delegate:onItemSelectionChanged()
	end

	self:updateSelectionButton()
end

function WardrobeOutfitsFrame:onListHighlightChanged(list, section, index)
	if index == nil then
		self.delegate:onItemSelectionCancelled()
	else
		local preset = self:getPresetFromItem(section, index)

		if preset == nil then
			self.delegate:onItemSelectionCancelled()
		else
			self.playerStyle:setPreset(preset, self.currentlyUsedPreset ~= self:getCurrentlySelectedPresetIndex())
			self.delegate:onItemSelectionChanged()
		end
	end
end

function WardrobeOutfitsFrame:onClickSelect()
	self.delegate:onItemSelectionConfirmed()

	self.currentlyUsedPreset = self:getCurrentlySelectedPresetIndex()

	self.itemList:reloadData()
end

function WardrobeOutfitsFrame:onClickSelectColor()
	local preset = self:getSelectedPreset()
	self.isShowingColors = true
	local item = self.playerStyle.onepieceConfig.items[preset.onepiece]
	local originalColor = self.playerStyle.onepieceConfig.color

	self.delegate:onItemShowColors("onepieceConfig", item, function (confirmed, keepOpen)
		if not keepOpen then
			self.isShowingColors = false
		end

		if not confirmed then
			self.playerStyle.onepieceConfig.color = originalColor

			self.delegate:onItemSelectionChanged()
		else
			originalColor = self.playerStyle.onepieceConfig.color
		end
	end)
end

function WardrobeOutfitsFrame:getSelectedPreset()
	return self:getPresetFromItem(self.itemList.selectedSectionIndex, self.itemList.selectedIndex)
end

function WardrobeOutfitsFrame:getPresetFromItem(section, index)
	local presetIndex = self.indexMapping[section][index]

	if presetIndex == -1 then
		return nil
	else
		return self.playerStyle.presets[presetIndex]
	end
end

function WardrobeOutfitsFrame:getPresetHasColors(preset)
	if preset.onepiece ~= nil and preset.onepiece ~= 0 then
		local onepiece = self.playerStyle.onepieceConfig.items[preset.onepiece]

		return onepiece.numColors > 0
	end

	return false
end
