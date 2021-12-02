ModHubCategoriesFrame = {}
local ModHubCategoriesFrame_mt = Class(ModHubCategoriesFrame, TabbedMenuFrameElement)
ModHubCategoriesFrame.CONTROLS = {
	"headerText",
	"spaceUsageLabel",
	NAV_HEADER = "breadcrumbs",
	CATEGORY_LIST = "categoryList"
}

local function NO_CALLBACK()
end

function ModHubCategoriesFrame.new(subclass_mt, modHubController)
	local self = TabbedMenuFrameElement.new(nil, subclass_mt or ModHubCategoriesFrame_mt)

	self:registerControls(ModHubCategoriesFrame.CONTROLS)

	self.modHubController = modHubController
	self.notifyActivatedCategoryCallback = NO_CALLBACK
	self.notifySearchCallback = NO_CALLBACK
	self.notifyToggleBetaCallback = NO_CALLBACK
	self.categories = {}

	return self
end

function ModHubCategoriesFrame:copyAttributes(src)
	ModHubCategoriesFrame:superClass().copyAttributes(self, src)

	self.modHubController = src.modHubController
end

function ModHubCategoriesFrame:onGuiSetupFinished()
	ModHubCategoriesFrame:superClass().onGuiSetupFinished(self)
	self.categoryList:setDataSource(self)
	self.categoryList:setDelegate(self)
end

function ModHubCategoriesFrame:initialize(categories, categoryClickedCallback, headerText, iconHeightWidthRatio)
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
	self.detailsButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = g_i18n:getText("button_detail"),
		callback = function ()
			self:onButtonDetails()
		end
	}
	self.searchButtonInfo = {
		inputAction = InputAction.MENU_ACTIVATE,
		text = g_i18n:getText("modHub_search"),
		callback = function ()
			self:onButtonSearch()
		end
	}
	self.toggleTopButtonInfo = {
		text = "",
		inputAction = InputAction.MENU_EXTRA_1,
		callback = function ()
			self:onButtonShowToggle()
		end
	}
	self.title = headerText
	self.iconHeightWidthRatio = iconHeightWidthRatio

	self.headerText:setText(headerText)

	self.notifyActivatedCategoryCallback = categoryClickedCallback or NO_CALLBACK

	self:setCategories(categories)
end

function ModHubCategoriesFrame:setCategories(categories)
	self.categories = categories

	self.categoryList:reloadData()
	self:setMenuButtonInfoDirty()
end

function ModHubCategoriesFrame:onFrameOpen()
	ModHubCategoriesFrame:superClass().onFrameOpen(self)
	self:setMenuButtonInfoDirty()
	self.categoryList:forceSelectionUpdate()
end

function ModHubCategoriesFrame:reload()
end

function ModHubCategoriesFrame:getMainElementSize()
	return self.categoryList.size
end

function ModHubCategoriesFrame:getMainElementPosition()
	return self.categoryList.absPosition
end

function ModHubCategoriesFrame:getMenuButtonInfo()
	local buttons = {}

	if #self.categories > 0 then
		table.insert(buttons, self.detailsButtonInfo)
	end

	table.insert(buttons, self.backButtonInfo)
	table.insert(buttons, self.searchButtonInfo)

	self.toggleTopButtonInfo.text = self.getBetaToggleText()

	table.insert(buttons, self.toggleTopButtonInfo)

	return buttons
end

function ModHubCategoriesFrame:setSearchCallback(searchCallback)
	self.notifySearchCallback = searchCallback
end

function ModHubCategoriesFrame:setToggleBetaCallback(callback)
	self.notifyToggleBetaCallback = callback
end

function ModHubCategoriesFrame:setBreadcrumbs(list)
end

function ModHubCategoriesFrame:setBetaToggleTextCallback(callback)
	self.getBetaToggleText = callback
end

function ModHubCategoriesFrame:onActivateCategory()
	local category = self.categories[self.categoryList.selectedIndex]

	self.notifyActivatedCategoryCallback(category.id, category.name)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
end

function ModHubCategoriesFrame:onListSelectionChanged(list, section, itemIndex)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end

function ModHubCategoriesFrame:onButtonDetails()
	self:onActivateCategory()
end

function ModHubCategoriesFrame:onButtonSearch()
	self.notifySearchCallback()
end

function ModHubCategoriesFrame:onButtonShowToggle()
	self:notifyToggleBetaCallback()
end

function ModHubCategoriesFrame:getNumberOfItemsInSection(list, section)
	return #self.categories
end

function ModHubCategoriesFrame:populateCellForItemInSection(list, section, index, cell)
	local category = self.categories[index]

	cell:getAttribute("markerNew"):setVisible(category.numNewItems > 0)
	cell:getAttribute("markerUpdate"):setVisible(category.numAvailableUpdates > 0)
	cell:getAttribute("markerConflict"):setVisible(category.numConflictedItems > 0)
	cell:getAttribute("markerBox"):invalidateLayout()

	local iconElement = cell:getAttribute("image")

	iconElement:setImageFilename(category.iconFilename)
	iconElement:setSize(nil, iconElement.size[2] * (self.iconHeightWidthRatio or 1))
	cell:getAttribute("text"):setText(category.label)
end
