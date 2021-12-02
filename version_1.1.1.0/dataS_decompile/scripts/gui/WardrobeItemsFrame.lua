WardrobeItemsFrame = {}
local WardrobeItemsFrame_mt = Class(WardrobeItemsFrame, TabbedMenuFrameElement)
WardrobeItemsFrame.CONTROLS = {
	"itemList",
	"title",
	"infoText"
}

function WardrobeItemsFrame.new(subclass_mt)
	local self = WardrobeItemsFrame:superClass().new(nil, subclass_mt or WardrobeItemsFrame_mt)

	self:registerControls(WardrobeItemsFrame.CONTROLS)

	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK,
		text = g_i18n:getText("button_confirm")
	}
	self.selectButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText("button_select"),
		callback = function ()
			self:onClickSelect()
		end
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
		self.selectButtonInfo
	}
	self.indexMapping = {}
	self.isShowingColors = false

	return self
end

function WardrobeItemsFrame:onGuiSetupFinished()
	WardrobeItemsFrame:superClass().onGuiSetupFinished(self)
	self.itemList:setDataSource(self)
	self.itemList:setDelegate(self)
end

function WardrobeItemsFrame:initialize(configName, delegate, titleKey)
	self.configName = configName
	self.delegate = delegate

	self.title:setLocaKey(titleKey)
end

function WardrobeItemsFrame:setPlayerStyle(playerStyle, savedPlayerStyle)
	self.playerStyle = playerStyle
	self.savedPlayerStyle = savedPlayerStyle

	self:resetList()
end

function WardrobeItemsFrame:onFrameOpen()
	WardrobeItemsFrame:superClass().onFrameOpen(self)

	if not self.isShowingColors then
		self.delegate:onItemSelectionStart()
		self:resetList()
	end
end

function WardrobeItemsFrame:resetList()
	self.indexMapping = {
		{},
		{}
	}

	if self.playerStyle ~= nil and self.configName ~= nil then
		if self.playerStyle[self.configName].items[0] ~= nil then
			self.indexMapping[1][1] = 0
		end

		local totalItems = 0
		local selectedIndex = 1
		local selectedSection = 1

		for index, itemIndex in ipairs(self.playerStyle[self.configName].listMappingGetter(self.playerStyle)) do
			local item = self.playerStyle[self.configName].items[itemIndex]
			local isCurrentSelection = itemIndex == self.playerStyle[self.configName].selection

			if isCurrentSelection or item.extraContentId == nil or g_extraContentSystem:getIsItemIdUnlocked(item.extraContentId) then
				local section = item.brand ~= nil and 2 or 1

				table.insert(self.indexMapping[section], itemIndex)

				totalItems = totalItems + 1

				if isCurrentSelection then
					selectedIndex = #self.indexMapping[section]
					selectedSection = section
				end
			end
		end

		if totalItems == 0 then
			if self.configName == "beardConfig" or self.configName == "mustacheConfig" then
				self.infoText:setLocaKey("ui_noItemsAvailable")
			else
				self.infoText:setLocaKey("ui_noItemsAvailable_onepieceSelected")
			end
		else
			self.infoText:setLocaKey()
		end

		self.menuButtonInfo = {
			self.backButtonInfo
		}

		if totalItems > 0 then
			table.insert(self.menuButtonInfo, self.selectButtonInfo)
		end

		self:setMenuButtonInfoDirty()
		self.itemList:reloadData()
		self.itemList:setSelectedItem(selectedSection, selectedIndex)
	end
end

function WardrobeItemsFrame:onFrameClose()
	if not self.isShowingColors then
		for _, cell in ipairs(self.itemList.elements) do
			if not cell.isHeader then
				cell:getAttribute("icon"):setImageFilename(g_baseUIFilename)
			end
		end
	end

	WardrobeItemsFrame:superClass().onFrameClose(self)
end

function WardrobeItemsFrame:updateSelectionButton()
	local item = self:getSelectedItem()
	local isEquipping = true
	self.menuButtonInfo = {
		self.backButtonInfo
	}

	if item ~= nil then
		table.insert(self.menuButtonInfo, isEquipping and self.equipButtonInfo or self.selectButtonInfo)
	end

	if item.numColors > 0 then
		table.insert(self.menuButtonInfo, self.colorButtonInfo)
	end

	self:setMenuButtonInfoDirty()
end

function WardrobeItemsFrame:getNumberOfSections()
	return #self.indexMapping[2] > 0 and 2 or 1
end

function WardrobeItemsFrame:getTitleForSectionHeader(list, section)
	if section == 2 then
		return g_i18n:getText("character_section_branded")
	else
		return nil
	end
end

function WardrobeItemsFrame:getNumberOfItemsInSection(list, section)
	return #self.indexMapping[section]
end

function WardrobeItemsFrame:populateCellForItemInSection(list, section, index, cell)
	local itemIndex = self.indexMapping[section][index]
	local item = self.playerStyle[self.configName].items[itemIndex]
	local icon = cell:getAttribute("icon")

	if item.iconFilename ~= nil then
		icon:setImageFilename(item.iconFilename)
	else
		icon:setImageFilename(self.playerStyle.atlasFilename)
	end

	icon:setImageUVs(nil, self.playerStyle:getSlotUVs(item.uvSlot))
	cell:getAttribute("selected"):setVisible(self.savedPlayerStyle[self.configName].selection == itemIndex)
	cell:getAttribute("hasColors"):setVisible(item.numColors > 0)
end

function WardrobeItemsFrame:onListSelectionChanged(list, section, index)
	self:setItemToIndex(section, index)
	self.delegate:onItemSelectionChanged()
	self:updateSelectionButton()
end

function WardrobeItemsFrame:onListHighlightChanged(list, section, index)
	if index == nil then
		self.delegate:onItemSelectionCancelled()
	else
		self:setItemToIndex(section, index)
		self.delegate:onItemSelectionChanged()
	end
end

function WardrobeItemsFrame:setItemToIndex(section, index)
	local itemIndex = self.indexMapping[section][index]
	local config = self.playerStyle[self.configName]

	config.setter(self.playerStyle, itemIndex)

	local savedConfig = self.savedPlayerStyle[self.configName]

	if savedConfig.selection == itemIndex and config.items[itemIndex].numColors > 0 then
		config.color = savedConfig.color
	end
end

function WardrobeItemsFrame:onClickSelect()
	self:setItemToIndex(self.itemList.selectedSectionIndex, self.itemList.selectedIndex)
	self.delegate:onItemSelectionConfirmed()
	self.itemList:reloadData()
end

function WardrobeItemsFrame:onClickSelectColor()
	local item = self:getSelectedItem()
	self.isShowingColors = true
	local originalColor = self.playerStyle[self.configName].color

	self.delegate:onItemShowColors(self.configName, item, function (confirmed, keepOpen)
		if not keepOpen then
			self.isShowingColors = false
		end

		if not confirmed then
			self.playerStyle[self.configName].color = originalColor

			self.delegate:onItemSelectionChanged()
			self.itemList:reloadData()
		else
			originalColor = self.playerStyle[self.configName].color

			self.itemList:reloadData()
		end
	end)
end

function WardrobeItemsFrame:getSelectedItem()
	local itemIndex = self.indexMapping[self.itemList.selectedSectionIndex][self.itemList.selectedIndex]

	return self.playerStyle[self.configName].items[itemIndex]
end
