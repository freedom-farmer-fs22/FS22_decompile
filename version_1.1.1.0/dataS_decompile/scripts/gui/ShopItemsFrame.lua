ShopItemsFrame = {}
local ShopItemsFrame_mt = Class(ShopItemsFrame, TabbedMenuFrameElement)
ShopItemsFrame.CONTROLS = {
	"itemsHeaderIcon",
	"itemsHeaderText",
	"shopSlotsIcon",
	"shopSlotsText",
	"currentBalanceLabel",
	"currentBalanceText",
	"breadcrumbs",
	"itemsList",
	"noItemsText",
	"baseInfoLayout",
	"itemInfoTitle",
	"itemInfoDescription",
	"fruitIconTemplate",
	"attributesLayout",
	"attrValue",
	"attrIcon",
	"attrIconsLayout",
	"itemDetailName",
	"itemDetailOwned",
	"detailSeparator",
	"shopListAttributeInfoIcon",
	"shopListAttributeInfo",
	"detailBox",
	"attrVehicleValue",
	"priceBox"
}
ShopItemsFrame.SLOTS_USAGE_CRITICAL_THRESHOLD = 0.9

local function NO_CALLBACK()
end

function ShopItemsFrame.new(subclass_mt, shopController, l10n, brandManager)
	local self = ShopItemsFrame:superClass().new(nil, subclass_mt or ShopItemsFrame_mt)

	self:registerControls(ShopItemsFrame.CONTROLS)

	self.shopController = shopController
	self.l10n = l10n
	self.brandManager = brandManager
	self.notifyActivatedDisplayItemCallback = NO_CALLBACK
	self.notifySelectedDisplayItemCallback = NO_CALLBACK
	self.displayItems = {}
	self.clonedElements = {}

	return self
end

function ShopItemsFrame:copyAttributes(src)
	ShopItemsFrame:superClass().copyAttributes(self, src)

	self.shopController = src.shopController
	self.l10n = src.l10n
	self.brandManager = src.brandManager
end

function ShopItemsFrame:onGuiSetupFinished()
	ShopItemsFrame:superClass().onGuiSetupFinished(self)
	self.itemsList:setDelegate(self)
	self.itemsList:setDataSource(self)
end

function ShopItemsFrame:initialize()
	local slotsVisible = g_currentMission.slotSystem:getAreSlotsVisible()

	self.shopSlotsIcon:setVisible(slotsVisible)
	self.shopSlotsText:setVisible(slotsVisible)
end

function ShopItemsFrame:onFrameOpen()
	ShopItemsFrame:superClass().onFrameOpen(self)
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.itemsList)

	if self.categoryHasChanged then
		self.itemsList.setNextOpenIndex = 1
		self.categoryHasChanged = false
	end

	self.itemsList:forceSelectionUpdate()
	self.itemsList:makeSelectedCellVisible()
	self:setSoundSuppressed(false)
end

function ShopItemsFrame:setItemClickCallback(itemClickedCallback)
	self.notifyActivatedDisplayItemCallback = itemClickedCallback or NO_CALLBACK
end

function ShopItemsFrame:setItemSelectCallback(itemSelectedCallback)
	self.notifySelectedDisplayItemCallback = itemSelectedCallback or NO_CALLBACK
end

function ShopItemsFrame:setHeader(headerIconUVs, headerText)
	if not GS_IS_MOBILE_VERSION then
		self.itemsHeaderIcon:setImageUVs(nil, unpack(headerIconUVs))
		self.itemsHeaderText:setText(headerText)
		self.itemsHeaderText:updateAbsolutePosition()
	end
end

function ShopItemsFrame:setCategory(categoryIconUVs, rootName, categoryName, isSpecial, secondaryCategoryName, headerTitleOverride)
	if rootName == nil then
		self.breadcrumbs:setBreadcrumbs({
			categoryName,
			secondaryCategoryName
		})
	else
		self.breadcrumbs:setBreadcrumbs({
			rootName,
			categoryName,
			secondaryCategoryName
		})
	end

	self:setHeader(categoryIconUVs, headerTitleOverride or secondaryCategoryName or categoryName)

	self.categoryHasChanged = self.categoryName ~= categoryName
	self.rootName = rootName
	self.categoryName = categoryName
	self.secondaryCategoryName = secondaryCategoryName
	self.iconUVs = categoryIconUVs

	self:setTitle(headerTitleOverride or secondaryCategoryName or categoryName)
end

function ShopItemsFrame:setShowBalance(doShowBalance)
	self.currentBalanceLabel:setVisible(doShowBalance)
	self.currentBalanceText:setVisible(doShowBalance)
end

function ShopItemsFrame:setShowNavigation(doShowNavigation)
	if self.breadcrumbs ~= nil then
		self.breadcrumbs:setVisible(doShowNavigation)
	end
end

function ShopItemsFrame:setCurrentBalance(balance, balanceString)
	local balanceProfile = ShopItemsFrame.PROFILE.BALANCE_POSITIVE

	if math.floor(balance) <= -1 then
		balanceProfile = ShopItemsFrame.PROFILE.BALANCE_NEGATIVE
	end

	if self.currentBalanceText.profile ~= balanceProfile then
		self.currentBalanceText:applyProfile(balanceProfile)
	end

	self.currentBalanceText:setText(balanceString)
end

function ShopItemsFrame:setSlotsUsage(slotsUsage, maxSlots)
	local slotsVisible = g_currentMission.slotSystem:getAreSlotsVisible()

	if slotsVisible then
		local text = string.format("%0d / %0d", slotsUsage, maxSlots)
		local profile = ShopItemsFrame.PROFILE.BALANCE_POSITIVE

		if ShopItemsFrame.SLOTS_USAGE_CRITICAL_THRESHOLD <= slotsUsage / maxSlots then
			profile = ShopItemsFrame.PROFILE.BALANCE_NEGATIVE
		end

		self.shopSlotsText:applyProfile(profile)
		self.shopSlotsText:setText(text)
	end

	self.shopSlotsIcon:setVisible(slotsVisible)
	self.shopSlotsText:setVisible(slotsVisible)
end

function ShopItemsFrame:setDisplayItems(displayItems, areItemsOwned)
	self:setSoundSuppressed(true)

	self.displayItems = displayItems or {}
	self.areItemsOwned = areItemsOwned

	self.shopListAttributeInfo:setVisible(false)
	self.shopListAttributeInfoIcon:setVisible(false)
	self.itemsList:reloadData()
	self.detailBox:setVisible(#displayItems > 0)
	self.noItemsText:setVisible(#displayItems == 0)
end

function ShopItemsFrame:getStoreItemDisplayPrice(storeItem, item, isSellingOrReturning, saleItem)
	local priceStr = "-"
	local isHandTool = StoreItemUtil.getIsHandTool(storeItem)

	if saleItem ~= nil then
		local defaultPrice = StoreItemUtil.getDefaultPrice(storeItem, saleItem.boughtConfigurations)
		priceStr = string.format("%s (-%d%%)", g_i18n:formatMoney(saleItem.price, 0, true, true), (1 - saleItem.price / defaultPrice) * 100)
	elseif isSellingOrReturning then
		if item ~= nil and item.propertyState ~= Vehicle.PROPERTY_STATE_LEASED or isHandTool then
			local price, _ = g_currentMission.economyManager:getSellPrice(item or storeItem)
			priceStr = g_i18n:formatMoney(price, 0, true, true)
		end
	elseif storeItem.isInAppPurchase then
		priceStr = storeItem.price
	else
		local price, _, _ = g_currentMission.economyManager:getBuyPrice(storeItem)
		priceStr = g_i18n:formatMoney(price, 0, true, true)
	end

	return priceStr
end

function ShopItemsFrame:assignItemFillTypesData(baseIconProfile, iconFilenames, attributeIndex)
	local parentBox = self.attrIconsLayout[attributeIndex]

	if parentBox == nil then
		return attributeIndex
	end

	if attributeIndex > #self.attrValue or #iconFilenames == 0 then
		parentBox:setVisible(false)

		return attributeIndex
	end

	local totalWidth = 0
	local maxWidth = self.attributesLayout.absSize[1] * 0.75

	self.attrIcon[attributeIndex]:applyProfile(baseIconProfile)
	self.attrIcon[attributeIndex]:setVisible(true)
	parentBox:setVisible(true)
	self.attrValue[attributeIndex]:setVisible(false)

	for i = 1, #iconFilenames do
		local icon = self.fruitIconTemplate:clone(parentBox)

		icon:setVisible(true)
		table.insert(self.clonedElements, icon)

		totalWidth = totalWidth + icon.absSize[1] + icon.margin[1] + icon.margin[3]

		if maxWidth <= totalWidth then
			icon:applyProfile(ShopItemsFrame.PROFILE.ICON_FILL_TYPES_PLUS)
			icon:setImageFilename(g_baseUIFilename)

			break
		else
			icon:applyProfile(ShopItemsFrame.PROFILE.ICON_FRUIT_TYPE)
			icon:setImageFilename(iconFilenames[i])
		end
	end

	parentBox:setSize(totalWidth, nil)
	parentBox:invalidateLayout()

	return attributeIndex + 1
end

function ShopItemsFrame:assignItemTextData(displayItem)
	if self.attrVehicleValue ~= nil then
		local storeItem = displayItem.storeItem
		local concreteItem = nil

		if self.areItemsOwned and displayItem.concreteItem ~= ShopDisplayItem.NO_CONCRETE_ITEM then
			concreteItem = displayItem.concreteItem
		end

		self.attrVehicleValue:setText(self:getStoreItemDisplayPrice(storeItem, concreteItem, self.areItemsOwned))
		self.priceBox:setVisible(not storeItem.isInAppPurchase)
	end

	local numAttributesUsed = 0

	for i = 1, #self.attrValue do
		local attributeVisible = false

		if i <= #displayItem.attributeValues then
			local value = displayItem.attributeValues[i]
			local profile = displayItem.attributeIconProfiles[i]

			if profile ~= nil and profile ~= "" then
				self.attrValue[i]:setText(value)
				self.attrValue[i]:updateAbsolutePosition()
				self.attrIcon[i]:applyProfile(profile)

				attributeVisible = value ~= nil and value ~= ""
			end
		end

		self.attrValue[i]:setVisible(attributeVisible)
		self.attrIcon[i]:setVisible(attributeVisible)
		self.attrIconsLayout[i]:setVisible(false)

		if attributeVisible then
			numAttributesUsed = numAttributesUsed + 1
		end
	end

	return numAttributesUsed
end

function ShopItemsFrame:assignItemAttributeData(displayItem)
	for k, clone in pairs(self.clonedElements) do
		clone:delete()

		self.clonedElements[k] = nil
	end

	local numAttributesUsed = self:assignItemTextData(displayItem)
	local nextAttributeIndex = self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, displayItem.fillTypeIconFilenames, numAttributesUsed + 1)
	nextAttributeIndex = self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_FILL_TYPES, displayItem.foodFillTypeIconFilenames, nextAttributeIndex)
	nextAttributeIndex = self:assignItemFillTypesData(ShopItemsFrame.PROFILE.ICON_SEED_FILL_TYPES, displayItem.seedTypeIconFilenames, nextAttributeIndex)

	self.detailSeparator:setVisible(nextAttributeIndex ~= 1)

	local visible = not GS_IS_MOBILE_VERSION or displayItem.storeItem.isInAppPurchase

	self.shopListAttributeInfo:setText(displayItem.functionText)
	self.shopListAttributeInfo:setVisible(visible)
	self.shopListAttributeInfoIcon:setVisible(displayItem.functionText ~= "" and visible)

	local name = displayItem.storeItem.name

	if displayItem.concreteItem ~= nil and displayItem.concreteItem.getName ~= nil then
		name = displayItem.concreteItem:getName()
	end

	local brand = g_brandManager:getBrandByIndex(displayItem.storeItem.brandIndex)

	if displayItem.concreteItem ~= nil and displayItem.concreteItem.getBrand ~= nil then
		brand = g_brandManager:getBrandByIndex(displayItem.concreteItem:getBrand())
	end

	if brand ~= nil then
		name = brand.title .. " " .. name
	end

	self.itemDetailName:setText(name)

	if displayItem.numLeased == nil then
		self.itemDetailOwned:setText(string.format(g_i18n:getText("ui_shop_numOwnedFormat"), displayItem.numOwned))
	else
		self.itemDetailOwned:setText(string.format(g_i18n:getText("ui_shop_numOwnedLeasedFormat"), displayItem.numOwned, displayItem.numLeased))
	end

	self.attributesLayout:invalidateLayout()
end

function ShopItemsFrame:onOpenItem()
	local displayItem = self.displayItems[self.itemsList.selectedIndex]

	if displayItem ~= nil then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
		self.notifyActivatedDisplayItemCallback(displayItem)
	end
end

function ShopItemsFrame:onListSelectionChanged(list, section, index)
	self:updateItemAttributeData(index)
end

function ShopItemsFrame:updateItemAttributeData(index)
	index = index or self.itemsList.selectedIndex
	local displayItem = self.displayItems[index]

	if displayItem ~= nil and self:getIsVisible() then
		self:assignItemAttributeData(displayItem)
		self.notifySelectedDisplayItemCallback(displayItem, index)
	end
end

function ShopItemsFrame:getSelectedDisplayItem()
	return self.displayItems[self.itemsList.selectedIndex]
end

function ShopItemsFrame:getNumberOfItemsInSection(list, section)
	return #self.displayItems
end

function ShopItemsFrame:populateCellForItemInSection(list, section, index, cell)
	local displayItem = self.displayItems[index]
	local storeItem = displayItem.storeItem

	if storeItem.isInAppPurchase then
		cell:getAttribute("icon"):setImageFilename(storeItem.imageFilename)

		if storeItem.canBeRecovered then
			cell:getAttribute("title"):setText(self.l10n:getText("ui_iap_recoverable"))
		else
			cell:getAttribute("title"):setText(storeItem.priceText)
		end

		cell:getAttribute("value"):setText(storeItem.title)
		cell:getAttribute("value"):setVisible(true)
		cell:getAttribute("brandIcon"):setVisible(false)
	else
		local imageFilename = storeItem.imageFilename

		if displayItem.concreteItem.getImageFilename ~= nil then
			imageFilename = displayItem.concreteItem:getImageFilename()
		end

		cell:getAttribute("icon"):setImageFilename(imageFilename)

		local brandIcon = cell:getAttribute("brandIcon")
		local brandIndex = storeItem.brandIndex

		if displayItem.concreteItem.getBrand ~= nil then
			brandIndex = displayItem.concreteItem:getBrand()
		end

		local itemBrand = self.brandManager:getBrandByIndex(brandIndex)

		brandIcon:setImageFilename(storeItem.customBrandIcon or itemBrand.image)
		brandIcon:setVisible(true)

		local title = storeItem.name

		if displayItem.concreteItem.getName ~= nil then
			title = displayItem.concreteItem:getName()
		end

		cell:getAttribute("title"):setText(title)

		local concreteItem = nil

		if self.areItemsOwned and displayItem.concreteItem ~= ShopDisplayItem.NO_CONCRETE_ITEM then
			concreteItem = displayItem.concreteItem
		end

		if Platform.isMobile then
			cell:getAttribute("value"):setVisible(false)
		else
			cell:getAttribute("value"):setText(self:getStoreItemDisplayPrice(storeItem, concreteItem, self.areItemsOwned, displayItem.saleItem))
		end

		if storeItem.isMod and storeItem.dlcTitle == nil then
			cell:getAttribute("modDlc"):setText("Mod")
		elseif storeItem.isMod and storeItem.dlcTitle ~= nil then
			cell:getAttribute("modDlc"):setText(storeItem.dlcTitle .. " (Mod)")
		elseif storeItem.dlcTitle ~= nil then
			cell:getAttribute("modDlc"):setText(storeItem.dlcTitle)
		else
			cell:getAttribute("modDlc"):setText("")
		end
	end
end

ShopItemsFrame.PROFILE = {
	ICON_FRUIT_TYPE = "shopListAttributeFruitIcon",
	ICON_FILL_TYPES = "shopListAttributeIconFillTypes",
	ICON_SEED_FILL_TYPES = "shopListAttributeIconSeeds",
	BALANCE_NEGATIVE = "shopMoneyNeg",
	BALANCE_POSITIVE = "shopMoney",
	ICON_FILL_TYPES_PLUS = "shopListAttributeIconPlus"
}
