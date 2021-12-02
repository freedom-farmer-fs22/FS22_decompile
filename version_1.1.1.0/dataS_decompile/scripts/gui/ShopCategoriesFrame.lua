ShopCategoriesFrame = {}
local ShopCategoriesFrame_mt = Class(ShopCategoriesFrame, TabbedMenuFrameElement)
ShopCategoriesFrame.CONTROLS = {
	"categoryHeaderIcon",
	"categoryHeaderText",
	"categoryList",
	"listSlider",
	"noItemsText"
}

local function NO_CALLBACK()
end

function ShopCategoriesFrame.new(subclass_mt, shopController)
	local self = TabbedMenuFrameElement.new(nil, subclass_mt or ShopCategoriesFrame_mt)

	self:registerControls(ShopCategoriesFrame.CONTROLS)

	self.shopController = shopController
	self.notifyActivatedCategoryCallback = NO_CALLBACK
	self.headerLabelText = ""
	self.headerIconUVs = {}
	self.categories = {}

	return self
end

function ShopCategoriesFrame:copyAttributes(src)
	ShopCategoriesFrame:superClass().copyAttributes(self, src)

	self.shopController = src.shopController
end

function ShopCategoriesFrame:onGuiSetupFinished()
	ShopCategoriesFrame:superClass().onGuiSetupFinished(self)
	self.categoryList:setDataSource(self)
	self.categoryList:setDelegate(self)
end

function ShopCategoriesFrame:initialize(categories, categoryClickedCallback, categorySelectedCallback, headerIconUVs, headerText, iconHeightWidthRatio, filter)
	self.headerLabelText = headerText
	self.headerIconUVs = headerIconUVs
	self.iconHeightWidthRatio = iconHeightWidthRatio
	self.filter = filter

	self:setCategories(categories)

	self.notifyActivatedCategoryCallback = categoryClickedCallback or NO_CALLBACK
	self.notifySelectedCategoryCallback = categorySelectedCallback or NO_CALLBACK

	if self.categoryHeaderText ~= nil then
		self.categoryHeaderIcon:setImageUVs(nil, unpack(headerIconUVs))
		self.categoryHeaderText:setText(headerText)
		self.categoryHeaderText:updateAbsolutePosition()
	end

	self:setTitle(headerText)
end

function ShopCategoriesFrame:setUseSections(use)
	self.useSections = use
end

function ShopCategoriesFrame:setCategories(categories)
	if self.useSections then
		self.categories = {}
		local lastLetter = nil

		for i, category in ipairs(categories) do
			local letter = category.label:sub(1, 1):upper()

			if lastLetter ~= letter then
				lastLetter = letter
				self.categories[#self.categories + 1] = {}
				self.categories[#self.categories].name = letter
			end

			local list = self.categories[#self.categories]
			list[#list + 1] = category
		end
	else
		self.categoryList.sectionHeaderCellName = nil
		self.categories = {
			categories
		}
	end

	self.categoryList:reloadData()
	self.noItemsText:setVisible(self.categoryList.totalItemCount == 0)

	if Platform.isMobile then
		-- Nothing
	end
end

function ShopCategoriesFrame:onFrameOpen()
	ShopCategoriesFrame:superClass().onFrameOpen(self)
	self.notifySelectedCategoryCallback(nil)
	self.categoryList:reloadData()
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.categoryList)
	self:setSoundSuppressed(false)
end

function ShopCategoriesFrame:onFrameClose()
	ShopCategoriesFrame:superClass().onFrameClose(self)
end

function ShopCategoriesFrame:onOpenCategory()
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

	local categories = self.categories[self.categoryList.selectedSectionIndex]

	if categories ~= nil then
		local category = categories[self.categoryList.selectedIndex]

		if category ~= nil then
			self.notifyActivatedCategoryCallback(category.id, self.headerIconUVs, self.headerLabelText, category.label, self.filter)
		end
	end
end

function ShopCategoriesFrame:onListSelectionChanged(list, section, index)
	self.notifySelectedCategoryCallback(self.categories[section][index])
end

function ShopCategoriesFrame:onPageChanged(page, fromPage)
	ShopCategoriesFrame:superClass().onPageChanged(self, page, fromPage)

	local firstIndex = (page - 1) * self.categoryList.itemsPerRow * self.categoryList.itemsPerCol + 1

	self.categoryList:scrollTo(firstIndex)
end

function ShopCategoriesFrame:getNumberOfSections(list)
	return #self.categories
end

function ShopCategoriesFrame:getNumberOfItemsInSection(list, section)
	return #self.categories[section]
end

function ShopCategoriesFrame:populateCellForItemInSection(list, section, index, cell)
	local category = self.categories[section][index]

	cell:getAttribute("icon"):setAspectRatio(self.iconHeightWidthRatio or 1)
	cell:getAttribute("icon"):setImageFilename(category.iconFilename)
	cell:getAttribute("title"):setText(category.label)
end

function ShopCategoriesFrame:getTitleForSectionHeader(list, section)
	return self.categories[section].name or ""
end
