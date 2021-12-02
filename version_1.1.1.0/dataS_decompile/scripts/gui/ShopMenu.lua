ShopMenu = {}
local ShopMenu_mt = Class(ShopMenu, TabbedMenuWithDetails)
ShopMenu.CONTROLS = {
	"pageShopBrands",
	"pageShopVehicles",
	"pageShopTools",
	"pageShopObjects",
	"pageShopGarageOwned",
	"pageShopGarageLeased",
	"pageShopDLCs",
	"pageShopPacks",
	"pageShopOthers",
	"pageUsedSale",
	"pageShopItemDetails",
	"pageShopItemCombinations"
}
ShopMenu.FILTER = {
	OWNED = 1,
	LEASED = 2
}

function ShopMenu.new(target, customMt, messageCenter, l10n, inputManager, fruitTypeManager, fillTypeManager, storeManager, shopController, shopConfigScreen, isConsoleVersion, inAppPurchaseController)
	local self = TabbedMenuWithDetails.new(target, customMt or ShopMenu_mt, messageCenter, l10n, inputManager)

	self:registerControls(ShopMenu.CONTROLS)

	self.fruitTypeManager = fruitTypeManager
	self.fillTypeManager = fillTypeManager
	self.storeManager = storeManager
	self.shopController = shopController
	self.shopConfigScreen = shopConfigScreen
	self.isConsoleVersion = isConsoleVersion
	self.inAppPurchaseController = inAppPurchaseController
	self.performBackgroundBlur = true
	self.gameState = GameState.MENU_SHOP
	self.restorePageIndex = 2
	self.useStack = true
	self.playerFarm = nil
	self.playerFarmId = 0
	self.currentUserId = -1
	self.isShowingOwnedPage = false
	self.paused = false
	self.isMissionTourActive = false
	self.client = nil
	self.server = nil
	self.isMasterUser = false
	self.isServer = false
	self.currentBalanceValue = 0
	self.timeSinceLastMoneyUpdate = 0
	self.needMoneyUpdate = true
	self.selectedDisplayElement = nil
	self.currentDisplayItems = nil
	self.defaultMenuButtonInfo = {}
	self.shopMenuButtonInfo = {}
	self.buyButtonInfo = {}
	self.shopDetailsButtonInfo = {}
	self.garageMenuButtonInfo = {}
	self.switchOwnedLeasedButtonInfo = {}
	self.sellButtonInfo = {}
	self.backButtonInfo = {}

	self.shopConfigScreen:setRequestExitCallback(self:makeSelfCallback(self.exitMenuFromConfig))
	messageCenter:subscribe(MessageType.STORE_ITEMS_RELOADED, self.onStoreItemsReloaded, self)
	messageCenter:subscribe(MessageType.VEHICLE_SALES_CHANGED, self.onVehicleSaleChanged, self)

	return self
end

function ShopMenu:setClient(client)
	self.client = client

	self.shopController:setClient(client)
end

function ShopMenu:setServer(server)
	self.server = server
	self.isServer = server ~= nil
end

function ShopMenu:updateGarageItems()
	if self.isShowingOwnedPage then
		local items = self.shopController:getItemsByCategoryOwnedOrLeased(self.currentCategoryName, not self.isShowingLeasedPage, self.isShowingLeasedPage)

		if #items == 0 then
			self:onButtonBack()
		else
			self.pageShopItemDetails:setDisplayItems(items, true)
		end
	else
		self:updateCurrentDisplayItems()
	end

	self.pageShopGarageOwned:setCategories(self.shopController:getOwnedCategories())
	self.pageShopGarageLeased:setCategories(self.shopController:getLeasedCategories())
end

function ShopMenu:onVehicleSaleChanged()
	self.pageUsedSale:setDisplayItems(self.shopController:getItemsByCategory(ShopController.SALES_CATEGORY))
end

function ShopMenu:onLoadMapFinished()
	self:initializePages()
	self:onMissionTourStateChanged(false)
end

function ShopMenu:initializePages()
	self.inAppPurchaseController:load()

	self.clickBackCallback = self:makeSelfCallback(self.onButtonBack)

	self.shopController:setCurrentMission(g_currentMission)
	self.shopController:setClient(g_client)
	self.shopController:setUpdateShopItemsCallback(self:makeSelfCallback(self.updateCurrentDisplayItems))
	self.shopController:setUpdateAllItemsCallback(self:makeSelfCallback(self.updateGarageItems))
	self.shopController:setStartPlacementModeCallback(self.startPlacementMode, self)
	self.shopController:setSaleItemBoughtCallback(self.closeConfigScreen, self)
	self.shopController:setSwitchToConfigurationCallback(self.showConfigurationScreen, self)
	self.shopController:load()

	local selectCategoryCallback = self:makeSelfCallback(self.onSelectCategory)

	self.pageShopBrands:setUseSections(true)
	self.pageShopBrands:initialize(self.shopController:getBrands(), self:makeSelfCallback(self.onClickBrand), selectCategoryCallback, GuiUtils.getUVs(ShopMenu.TAB_UV.BRANDS), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_BRANDS), ShopMenu.BRAND_IMAGE_HEIGHT_WIDTH_RATIO)

	local clickItemCategoryCallback = self:makeSelfCallback(self.onClickItemCategory)

	self.pageShopVehicles:initialize(self.shopController:getVehicleCategories(), clickItemCategoryCallback, selectCategoryCallback, GuiUtils.getUVs(ShopMenu.TAB_UV.VEHICLES), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_VEHICLES))
	self.pageShopTools:initialize(self.shopController:getToolCategories(), clickItemCategoryCallback, selectCategoryCallback, GuiUtils.getUVs(ShopMenu.TAB_UV.TOOLS), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_TOOLS))
	self.pageShopObjects:initialize(self.shopController:getObjectCategories(), clickItemCategoryCallback, selectCategoryCallback, GuiUtils.getUVs(ShopMenu.TAB_UV.OBJECTS), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_OBJECTS))
	self.pageShopGarageOwned:initialize(self.shopController:getOwnedCategories(), clickItemCategoryCallback, selectCategoryCallback, GuiUtils.getUVs(ShopMenu.TAB_UV.OWNED), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_GARAGE_OWNED), nil, ShopMenu.FILTER.OWNED)
	self.pageShopGarageLeased:initialize(self.shopController:getLeasedCategories(), clickItemCategoryCallback, selectCategoryCallback, GuiUtils.getUVs(ShopMenu.TAB_UV.LEASED), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_GARAGE_LEASED), nil, ShopMenu.FILTER.LEASED)
	self.pageShopDLCs:initialize(self.shopController:getDLCCategories(), self:makeSelfCallback(self.onClickDLC), selectCategoryCallback, GuiUtils.getUVs(ShopMenu.TAB_UV.DLCS), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_DLCS))
	self.pageShopPacks:initialize(self.shopController:getStorePacks(), self:makeSelfCallback(self.onClickPack), selectCategoryCallback, GuiUtils.getUVs(ShopMenu.TAB_UV.PACKS), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_PACKS))
	self.pageShopOthers:initialize(selectCategoryCallback, GuiUtils.getUVs(ShopMenu.TAB_UV.OTHERS), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_OTHERS))
	self.pageUsedSale:initialize()
	self.pageUsedSale:setItemClickCallback(self:makeClickBuyItemCallback())
	self.pageUsedSale:setItemSelectCallback(self:makeSelfCallback(self.onSelectItemBuyDetail))
	self.pageUsedSale:setHeader(GuiUtils.getUVs(ShopMenu.TAB_UV.SALE), self.l10n:getText("ui_usedVehicleSale"))
	self.pageUsedSale:setCategory(GuiUtils.getUVs(ShopMenu.TAB_UV.SALE), nil, self.l10n:getText("ui_usedVehicleSale"), nil, , )
	self.pageShopItemDetails:initialize()
	self.pageShopItemCombinations:initialize()
	self.pageShopItemCombinations:setItemClickCallback(self:makeClickBuyItemCallback())
	self.pageShopItemCombinations:setItemSelectCallback(self:makeSelfCallback(self.onSelectItemBuyDetail))
	self:setDetailButtons()
end

function ShopMenu:setDetailButtons()
	if not self.isShowingOwnedPage then
		self.pageShopItemDetails:setItemClickCallback(self:makeClickBuyItemCallback())
		self.pageShopItemDetails:setItemSelectCallback(self:makeSelfCallback(self.onSelectItemBuyDetail))
	else
		self.pageShopItemDetails:setItemClickCallback(self:makeClickSellItemCallback())
		self.pageShopItemDetails:setItemSelectCallback(self:makeSelfCallback(self.onSelectItemSellDetail))
	end
end

function ShopMenu:setupMenuPages()
	local shopEnabledPredicate = self:makeIsShopEnabledPredicate()
	local shopDetailsEnabledPredicate = self:makeIsShopItemsEnabledPredicate()
	local shopCombinationsEnabledPredicate = self:makeIsShopCombinationsEnabledPredicate()
	local orderedDefaultPages = {
		{
			self.pageShopBrands,
			shopEnabledPredicate,
			ShopMenu.TAB_UV.BRANDS
		},
		{
			self.pageShopVehicles,
			shopEnabledPredicate,
			ShopMenu.TAB_UV.VEHICLES
		},
		{
			self.pageShopTools,
			shopEnabledPredicate,
			ShopMenu.TAB_UV.TOOLS
		},
		{
			self.pageShopObjects,
			shopEnabledPredicate,
			ShopMenu.TAB_UV.OBJECTS
		},
		{
			self.pageShopPacks,
			shopEnabledPredicate,
			ShopMenu.TAB_UV.PACKS
		},
		{
			self.pageUsedSale,
			shopEnabledPredicate,
			ShopMenu.TAB_UV.SALE
		},
		{
			self.pageShopGarageOwned,
			shopEnabledPredicate,
			ShopMenu.TAB_UV.OWNED
		},
		{
			self.pageShopGarageLeased,
			shopEnabledPredicate,
			ShopMenu.TAB_UV.LEASED
		},
		{
			self.pageShopDLCs,
			self:makeIsDLCPageEnabledPredicate(),
			ShopMenu.TAB_UV.DLCS
		},
		{
			self.pageShopOthers,
			shopEnabledPredicate,
			ShopMenu.TAB_UV.OTHERS
		},
		{
			self.pageShopItemDetails,
			shopDetailsEnabledPredicate,
			ShopMenu.TAB_UV.VEHICLES
		},
		{
			self.pageShopItemCombinations,
			shopCombinationsEnabledPredicate,
			ShopMenu.TAB_UV.SALE
		}
	}

	for i, pageDef in ipairs(orderedDefaultPages) do
		local page, predicate, iconUVs = unpack(pageDef)

		self:registerPage(page, i, predicate)

		local imageFilename = g_iconsUIFilename
		local normalizedUVs = GuiUtils.getUVs(iconUVs)

		self:addPageTab(page, imageFilename, normalizedUVs)
	end
end

function ShopMenu:setupMenuButtonInfo()
	ShopMenu:superClass().setupMenuButtonInfo(self)

	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK,
		text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BACK),
		callback = self.clickBackCallback
	}
	self.selectButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText("button_select"),
		callback = self.onButtonSelect
	}
	self.defaultMenuButtonInfo = {
		self.backButtonInfo,
		self.onButtonSelect
	}
	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
	self.defaultButtonActionCallbacks = {
		[InputAction.MENU_BACK] = self.clickBackCallback
	}
	local onButtonInfoFunction = self:makeSelfCallback(self.onButtonInfo)

	if Platform.isMobile then
		local function onBrandSwitchFunction()
			error("Not implemented")
		end

		self.brandsSwitchButton = {
			profile = "buttonSwitchGarage",
			inputAction = InputAction.MENU_ACTIVATE,
			text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BRANDS),
			callback = onBrandSwitchFunction,
			clickSound = GuiSoundPlayer.SOUND_SAMPLES.PAGING
		}
		self.shopMenuButtonInfo = {
			self.backButtonInfo,
			self.brandsSwitchButton
		}
	else
		self.shopMenuButtonInfo = {
			self.backButtonInfo,
			self.selectButtonInfo
		}
	end

	self.buyButtonInfo = {
		profile = "buttonBuy",
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BUY),
		callback = self:makeSelfCallback(self.onButtonAcceptItem)
	}

	if Platform.isMobile then
		self.shopDetailsButtonInfo = {
			self.backButtonInfo,
			self.buyButtonInfo,
			{
				profile = "buttonShowInfo",
				inputAction = InputAction.MENU_CANCEL,
				text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_INFO),
				callback = onButtonInfoFunction,
				clickSound = GuiSoundPlayer.SOUND_SAMPLES.PAGING
			}
		}
	else
		self.shopDetailsButtonInfo = {
			self.backButtonInfo,
			self.buyButtonInfo
		}
	end

	self.sellButtonInfo = {
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SELL),
		callback = self:makeSelfCallback(self.onButtonAcceptItem)
	}
	self.combinationsButtonInfo = {
		inputAction = InputAction.MENU_EXTRA_2,
		text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_COMBINATIONS),
		callback = self:makeSelfCallback(self.onButtonCombinations)
	}
	self.hotspotButtonInfo = {
		profile = "buttonHotspot",
		inputAction = InputAction.MENU_CANCEL,
		text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_HOTSPOT),
		callback = self:makeSelfCallback(self.onButtonToggleHotspot)
	}
	self.garageMenuButtonInfo = {
		self.backButtonInfo,
		self.hotspotButtonInfo
	}

	self.pageShopGarageOwned:setMenuButtonInfo(self.garageMenuButtonInfo)
	self.pageShopGarageLeased:setMenuButtonInfo(self.garageMenuButtonInfo)
end

function ShopMenu:onGuiSetupFinished()
	ShopMenu:superClass().onGuiSetupFinished(self)
	self.messageCenter:subscribe(MessageType.VEHICLE_REPAIRED, self.onVehicleRepairRepaintEvent, self)
	self.messageCenter:subscribe(MessageType.VEHICLE_REPAINTED, self.onVehicleRepairRepaintEvent, self)
	self.messageCenter:subscribe(MessageType.MONEY_CHANGED, self.onMoneyChanged, self)
	self.messageCenter:subscribe(MessageType.MISSION_TOUR_STARTED, self.onMissionTourStateChanged, self, true)
	self.messageCenter:subscribe(MessageType.MISSION_TOUR_FINISHED, self.onMissionTourStateChanged, self, false)
	self:setupMenuPages()
end

function ShopMenu:setPlayerFarm(farm)
	self.playerFarm = farm

	if farm ~= nil then
		self.playerFarmId = farm.farmId
	else
		self.playerFarmId = 0
	end

	self.shopController:setPlayerFarm(farm)

	if self:getIsOpen() then
		self:updatePages()
	end
end

function ShopMenu:setCurrentMission(currentMission)
	self.shopController:setCurrentMission(currentMission)
end

function ShopMenu:setCurrentUserId(currentUserId)
	self.currentUserId = currentUserId
end

function ShopMenu:exitMenuFromConfig()
	self.shopConfigScreen:changeScreen(ShopMenu)
	self:exitMenu()
end

function ShopMenu:reset()
	ShopMenu:superClass().reset(self)
	self.shopController:reset()

	self.isMasterUser = false
	self.isServer = false
	self.selectedDisplayElement = nil
	self.selectedCategory = nil

	if GS_IS_MOBILE_VERSION then
		self.restorePageIndex = 2
	end
end

function ShopMenu:onOpen()
	ShopMenu:superClass().onOpen(self)
	self:onMoneyChanged(self.playerFarmId, self.playerFarm:getBalance())
	g_currentMission.hud:onMenuVisibilityChange(true, false)
	self:updateGarageItems()
	self:onVehicleSaleChanged()
end

function ShopMenu:onClose(element)
	ShopMenu:superClass().onClose(self)

	self.mouseDown = false
	self.alreadyClosed = true
	self.isShowingOwnedPage = false

	if not self.closingForConfigurationScreen then
		self.currentDisplayItems = nil

		g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_BUY)
		g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_SELL)
		g_currentMission:showMoneyChange(MoneyType.SHOP_PROPERTY_BUY)
		g_currentMission:showMoneyChange(MoneyType.SHOP_PROPERTY_SELL)
	end

	self.closingForConfigurationScreen = false
end

function ShopMenu:onMissionTourStateChanged(isMissionTourActive)
	self.isMissionTourActive = isMissionTourActive
end

function ShopMenu:onButtonSelect()
	if self.selectedCategory ~= nil and not self:getIsDetailMode() then
		self:getTopFrame():onOpenCategory()
	end
end

function ShopMenu:onButtonInfo()
	g_gui:showInfoDialog({
		text = self.selectedDisplayElement.functionText
	})
end

function ShopMenu:onButtonShop()
	self:popDetail()
end

function ShopMenu:onButtonCombinations()
	local combinations = self.selectedDisplayElement.storeItem.specs.combinations
	local items = self.shopController:getItemsFromCombinations(combinations)
	self.currentDisplayItems = items

	self.pageShopItemCombinations:setDisplayItems(items, false)

	local details = self.pageShopItemDetails
	local title = string.format(g_i18n:getText("ui_combinationsFor"), self.selectedDisplayElement.storeItem.name)

	self.pageShopItemCombinations:setCategory(details.iconUVs, details.rootName, details.categoryName, nil, g_i18n:getText("ui_combinations"), title)
	self:setDetailButtons()
	self:pushDetail(self.pageShopItemCombinations)
end

function ShopMenu:onVehicleRepairRepaintEvent(vehicle, _)
	if self.selectedDisplayElement ~= nil and self.selectedDisplayElement.concreteItem == vehicle then
		self:updateGarageButtonInfo(true, 1, self.selectedDisplayElement:hasCombinationInfo())
	end
end

function ShopMenu:onButtonAcceptItem()
	if self:getIsDetailMode() then
		self:getTopFrame():onOpenItem()
	end
end

function ShopMenu:setIsGamePaused(paused)
	self.paused = paused

	if self.currentPage ~= nil then
		self:updateButtonsPanel(self.currentPage)
	end
end

function ShopMenu:startPlacementMode(storeItem, isSellingMode, obj)
end

function ShopMenu:onDetailClosed(detailPage)
	self.currentDisplayItems = nil
end

function ShopMenu:update(dt)
	ShopMenu:superClass().update(self, dt)
	self.shopController:update(dt)
	self.inAppPurchaseController:update(dt)
	self:updateCurrentBalanceDisplay(dt)
end

function ShopMenu:setConfigurations(vehicle, leaseItem, storeItem, configs, price, licensePlateData, saleItem)
	self.shopController:setConfigurations(vehicle, leaseItem, storeItem, configs, price, licensePlateData, saleItem)
end

function ShopMenu:showConfigurationScreen(storeItem, saleItem, configurations)
	self.closingForConfigurationScreen = true

	self:changeScreen(ShopConfigScreen)
	self.shopConfigScreen:setReturnScreen(self.name)
	self.shopConfigScreen:setStoreItem(storeItem, nil, saleItem, nil, configurations)
	self.shopConfigScreen:setCallbacks(self.setConfigurations, self)
end

function ShopMenu:updateCurrentBalanceDisplay(dt)
	self.timeSinceLastMoneyUpdate = self.timeSinceLastMoneyUpdate + dt

	if self.needMoneyUpdate and TabbedMenu.MONEY_UPDATE_INTERVAL <= self.timeSinceLastMoneyUpdate then
		local balanceMoneyText = self.l10n:formatMoney(self.currentBalanceValue, 0, false) .. " " .. self.l10n:getCurrencySymbol(true)

		self.pageShopItemDetails:setCurrentBalance(self.currentBalanceValue, balanceMoneyText)
		self.pageShopItemCombinations:setCurrentBalance(self.currentBalanceValue, balanceMoneyText)
		self.pageUsedSale:setCurrentBalance(self.currentBalanceValue, balanceMoneyText)

		self.timeSinceLastMoneyUpdate = 0
		self.needMoneyUpdate = false
	end
end

function ShopMenu:updateCurrentDisplayItems()
	if self.currentDisplayItems ~= nil then
		local updatedDisplayItems = self.shopController:updateDisplayItems(self.currentDisplayItems)

		if #updatedDisplayItems == 0 then
			self:onButtonBack()
		else
			self.pageShopItemDetails:setDisplayItems(updatedDisplayItems, false)
			self:setDetailButtons()
		end
	end
end

function ShopMenu:onStoreItemsReloaded()
	self:updateCurrentDisplayItems()
end

function ShopMenu:inputEvent(action, value, eventUsed)
	eventUsed = ShopMenu:superClass().inputEvent(self, action, value, eventUsed)

	if not eventUsed and action == InputAction.TOGGLE_STORE then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.BACK)
		self:exitMenu()

		eventUsed = true
	end

	return eventUsed
end

function ShopMenu:onClickMenu()
	self:exitMenu()

	return true
end

function ShopMenu:exitMenu()
	self.pageShopItemDetails:setDisplayItems({}, false)
	self.pageShopItemCombinations:setDisplayItems({}, false)
	self.pageUsedSale:setDisplayItems({}, false)

	self.selectedDisplayElement = nil
	self.currentDisplayItems = nil

	ShopMenu:superClass().exitMenu(self)
end

function ShopMenu:onMoneyChanged(farmId, newMoneyValue)
	if farmId == self.playerFarmId and self:getIsVisible() then
		self.currentBalanceValue = newMoneyValue
		self.needMoneyUpdate = true
	end
end

function ShopMenu:onSlotUsageChanged(currentSlotUsage, maxSlotUsage)
	self.pageShopItemDetails:setSlotsUsage(currentSlotUsage, maxSlotUsage)
	self.pageShopItemCombinations:setSlotsUsage(currentSlotUsage, maxSlotUsage)
	self.pageUsedSale:setSlotsUsage(currentSlotUsage, maxSlotUsage)
end

function ShopMenu:onSelectCategory(category, selectedElement)
	self.selectedCategory = category
end

function ShopMenu:onSelectItemBuyDetail(displayItem, selectedElementIndex)
	self.selectedDisplayElement = displayItem
	local buttons = self:getPageButtonInfo(self.pageShopItemDetails)

	for i = 1, #buttons do
		buttons[i] = nil
	end

	local isVehicle = StoreItemUtil.getIsVehicle(displayItem.storeItem)
	local isConfigurable = StoreItemUtil.getIsConfigurable(displayItem.storeItem)

	if isVehicle and isConfigurable and not GS_IS_MOBILE_VERSION then
		self.buyButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_CUSTOMIZE)
	else
		local isHandTool = StoreItemUtil.getIsHandTool(displayItem.storeItem)

		if not isConfigurable and not isHandTool and not GS_IS_MOBILE_VERSION then
			self.buyButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_DETAILS)
		else
			self.buyButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_BUY)
		end
	end

	if isVehicle and GS_IS_MOBILE_VERSION and displayItem.storeItem.canBeRecovered then
		self.buyButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_RECOVER)
		self.buyButtonInfo.profile = "buttonRecover"
	else
		self.buyButtonInfo.profile = "buttonBuy"
	end

	table.insert(buttons, self.backButtonInfo)
	table.insert(buttons, self.buyButtonInfo)

	if displayItem:hasCombinationInfo() and self:getTopFrame() ~= self.pageShopItemCombinations then
		table.insert(buttons, self.combinationsButtonInfo)
	end

	self:updateButtonsPanel(self.pageShopItemDetails)
end

function ShopMenu:onSelectItemSellDetail(displayItem, selectedElementIndex)
	self.selectedDisplayElement = displayItem
	local concreteItem = displayItem.concreteItem
	local itemPropertyState = concreteItem.propertyState
	local isOwned = itemPropertyState == nil or itemPropertyState ~= Vehicle.PROPERTY_STATE_LEASED

	self:updateGarageButtonInfo(isOwned, 1, displayItem:hasCombinationInfo())
end

function ShopMenu:updateGarageButtonInfo(isOwned, numItems, hasCombinations)
	local buttons = self:getPageButtonInfo(self.pageShopItemDetails)

	for i = 1, #buttons do
		buttons[i] = nil
	end

	table.insert(buttons, self.backButtonInfo)

	if numItems > 0 then
		table.insert(buttons, self.sellButtonInfo)

		if isOwned then
			self.sellButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_SELL)
		else
			self.sellButtonInfo.text = self.l10n:getText(ShopMenu.L10N_SYMBOL.BUTTON_RETURN)
		end
	end

	if self.selectedDisplayElement ~= nil and self.selectedDisplayElement.concreteItem.getMapHotspot ~= nil then
		table.insert(buttons, self.hotspotButtonInfo)
	end

	if hasCombinations then
		table.insert(buttons, self.combinationsButtonInfo)
	end

	self:updateButtonsPanel(self.pageShopItemDetails)
end

function ShopMenu:getPageButtonInfo(page)
	local buttonInfo = ShopMenu:superClass().getPageButtonInfo(self, page)

	if self:getIsDetailMode() then
		if page == self.pageShopGarageOwned or page == self.pageShopGarageLeased then
			buttonInfo = self.garageMenuButtonInfo
		else
			buttonInfo = self.shopDetailsButtonInfo
		end
	else
		buttonInfo = self.shopMenuButtonInfo
	end

	return buttonInfo
end

function ShopMenu:onClickBrand(brandId, _, _, categoryDisplayName)
	self.isShowingOwnedPage = false
	self.isShowingLeasedPage = false
	local brandItems = self.shopController:getItemsByBrand(brandId)
	self.currentDisplayItems = brandItems

	self.pageShopItemDetails:setDisplayItems(brandItems, false)
	self.pageShopItemDetails:setCategory(GuiUtils.getUVs(ShopMenu.TAB_UV.BRANDS), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_BRANDS), categoryDisplayName)
	self:setDetailButtons()
	self:pushDetail(self.pageShopItemDetails)
end

function ShopMenu:onClickPack(packName, _, _, categoryDisplayName)
	self.isShowingOwnedPage = false
	self.isShowingLeasedPage = false
	local items = self.shopController:getItemsByPack(packName)
	self.currentDisplayItems = items

	self.pageShopItemDetails:setDisplayItems(items, false)
	self.pageShopItemDetails:setCategory(GuiUtils.getUVs(ShopMenu.TAB_UV.PACKS), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_PACKS), categoryDisplayName)
	self:setDetailButtons()
	self:pushDetail(self.pageShopItemDetails)
end

function ShopMenu:onClickOtherStore(storeName, _, _, categoryDisplayName)
end

function ShopMenu:onClickDLC(dlcId, _, _, categoryDisplayName)
	self.isShowingOwnedPage = false
	self.isShowingLeasedPage = false
	local items = self.shopController:getItemsByDLC(dlcId)
	self.currentDisplayItems = items

	self.pageShopItemDetails:setDisplayItems(items, false)
	self.pageShopItemDetails:setCategory(GuiUtils.getUVs(ShopMenu.TAB_UV.DLCS), self.l10n:getText(ShopMenu.L10N_SYMBOL.HEADER_DLCS), categoryDisplayName)
	self:setDetailButtons()
	self:pushDetail(self.pageShopItemDetails)
end

function ShopMenu:onClickItemCategory(categoryName, baseCategoryIconUVs, baseCategoryDisplayName, categoryDisplayName, filter)
	self.isShowingOwnedPage = filter ~= nil
	self.isShowingLeasedPage = filter == ShopMenu.FILTER.LEASED
	local categoryItems = nil
	categoryItems = (not self.isShowingOwnedPage or self.shopController:getItemsByCategoryOwnedOrLeased(categoryName, filter == ShopMenu.FILTER.OWNED, filter == ShopMenu.FILTER.LEASED)) and self.shopController:getItemsByCategory(categoryName)
	self.currentCategoryName = categoryName
	self.currentDisplayItems = categoryItems

	self.pageShopItemDetails:setDisplayItems(categoryItems, self.isShowingOwnedPage)
	self:setDetailButtons()

	local isSpecial = false

	if categoryName == ShopController.COINS_CATEGORY then
		isSpecial = true

		if not self.inAppPurchaseController:getIsAvailable() then
			g_gui:showInfoDialog({
				dialogType = DialogElement.TYPE_INFO,
				text = self.l10n:getText("ui_iap_notAvailable")
			})

			return
		else
			self.inAppPurchaseController:setPendingPurchaseCallback(function ()
				if self:getTopFrame() ~= self.pageShopItemDetails or not self.currentDisplayItems[1].storeItem.isInAppPurchase then
					self.inAppPurchaseController:setPendingPurchaseCallback(nil)

					return
				end

				self.currentDisplayItems = self.shopController:getCoinItems()

				self.pageShopItemDetails:setDisplayItems(self.currentDisplayItems, false)
			end)
		end
	end

	self.pageShopItemDetails:setCategory(baseCategoryIconUVs, baseCategoryDisplayName, categoryDisplayName, isSpecial)
	self:pushDetail(self.pageShopItemDetails)
end

function ShopMenu:buyItem(displayItem)
	if GS_IS_MOBILE_VERSION then
		local storeItem = displayItem.storeItem

		if storeItem.isInAppPurchase then
			return self:purchaseInAppProduct(storeItem.product)
		end

		local enoughMoney = true
		local price = g_currentMission.economyManager:getBuyPrice(storeItem)

		if price > 0 then
			enoughMoney = price <= g_currentMission:getMoney()
		end

		local enoughSlots = g_currentMission.slotSystem:hasEnoughSlots(storeItem)

		if not enoughMoney then
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)

			if self.inAppPurchaseController:getIsAvailable() then
				g_gui:showYesNoDialog({
					title = self.l10n:getText("ui_buy"),
					text = self.l10n:getText("shop_messageNotEnoughMoneyToBuy_buyCoins"),
					callback = function (self, yes)
						if yes then
							self:showCoinShop()
						end
					end,
					target = self
				})
			else
				g_gui:showInfoDialog({
					text = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_BUY)
				})
			end
		elseif not enoughSlots then
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
			g_gui:showInfoDialog({
				text = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS)
			})
		else
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

			local text = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIRM_BUY), self.l10n:formatMoney(price, 0, true, true))
			self.currentBuyDialogItem = displayItem

			g_gui:showYesNoDialog({
				text = text,
				callback = self.onYesNoBuy,
				target = self
			})
		end
	else
		self.shopController:buy(displayItem.storeItem, displayItem.saleItem, false, displayItem.configurations)
	end
end

function ShopMenu:onYesNoBuy(yes)
	if yes then
		self.shopController:buy(self.currentBuyDialogItem.storeItem, self.currentBuyDialogItem.saleItem, false)
	end

	self.currentBuyDialogItem = nil
end

function ShopMenu:purchaseInAppProduct(product)
	if not self.inAppPurchaseController:tryPerformPendingPurchase(product, function ()
		g_gui:showInfoDialog({
			dialogType = DialogElement.TYPE_INFO,
			text = self.l10n:getText("ui_iap_purchaseComplete")
		})

		self.currentDisplayItems = self.shopController:getCoinItems()

		self.pageShopItemDetails:setDisplayItems(self.currentDisplayItems, false)
	end) then
		self.inAppPurchaseController:purchase(product, function (success, cancelled, error)
			if success then
				g_gui:showInfoDialog({
					dialogType = DialogElement.TYPE_INFO,
					text = self.l10n:getText("ui_iap_purchaseComplete")
				})
			elseif cancelled then
				return
			else
				g_gui:showInfoDialog({
					dialogType = DialogElement.TYPE_INFO,
					text = self.l10n:getText(error)
				})
			end
		end)
	end
end

function ShopMenu:showCoinShop()
	self:changeScreen(ShopMenu)
	self:goToPage(self.pageShopVehicles)
	self:onClickItemCategory(ShopController.COINS_CATEGORY, nil, , self.l10n:getText("ui_coins"))
end

function ShopMenu:onButtonToggleHotspot()
	if self:getIsDetailMode() then
		local displayItem = self:getTopFrame():getSelectedDisplayItem()
		local vehicle = displayItem.concreteItem

		if vehicle:getMapHotspot() == g_currentMission.currentMapTargetHotspot then
			g_currentMission:setMapTargetHotspot()
		else
			g_currentMission:setMapTargetHotspot(vehicle:getMapHotspot())
		end
	end
end

function ShopMenu:closeConfigScreen()
	self.shopConfigScreen:changeScreen(ShopMenu)
end

function ShopMenu:onButtonConstruction()
	self:changeScreen(ConstructionScreen)
end

function ShopMenu:getIsDetailMode()
	return ShopMenu:superClass().getIsDetailMode(self) or self.currentPage == self.pageUsedSale
end

function ShopMenu:makeIsShopEnabledPredicate()
	return function ()
		return not self:getIsDetailMode() or self.currentPage == self.pageUsedSale
	end
end

function ShopMenu:makeIsShopItemsEnabledPredicate()
	return function ()
		return ShopMenu:superClass().getIsDetailMode(self) and (self:getTopFrame() == self.pageShopItemDetails or self.currentPage == self.pageUsedSale)
	end
end

function ShopMenu:makeIsShopCombinationsEnabledPredicate()
	return function ()
		return self:getIsDetailMode() and self:getTopFrame() == self.pageShopItemCombinations
	end
end

function ShopMenu:makeIsLandscapingEnabledPredicate()
	return function ()
		local userPermissions = self.playerFarm:getUserPermissions(self.currentUserId)
		local hasPermission = userPermissions[Farm.PERMISSION.LANDSCAPING] or self.isMasterUser

		return not self.isMissionTourActive and hasPermission
	end
end

function ShopMenu:makeIsDLCPageEnabledPredicate()
	return function ()
		return #self.shopController:getDLCCategories() > 0
	end
end

function ShopMenu:makeClickBuyItemCallback()
	return function (displayItem)
		self:buyItem(displayItem)
	end
end

function ShopMenu:makeClickSellItemCallback()
	return function (displayItem)
		self.shopController:sell(displayItem.storeItem, displayItem.concreteItem)
	end
end

ShopMenu.TAB_UV = {
	VEHICLES = {
		260,
		0,
		65,
		65
	},
	BRANDS = {
		65,
		65,
		65,
		65
	},
	TOOLS = {
		130,
		65,
		65,
		65
	},
	OBJECTS = {
		195,
		65,
		65,
		65
	},
	PLACEABLES = {
		260,
		65,
		65,
		65
	},
	LANDSCAPING = {
		585,
		65,
		65,
		65
	},
	OWNED = {
		325,
		65,
		65,
		65
	},
	LEASED = {
		390,
		65,
		65,
		65
	},
	DLCS = {
		520,
		65,
		65,
		65
	},
	PACKS = {
		455,
		65,
		65,
		65
	},
	SALE = {
		845,
		65,
		65,
		65
	},
	OTHERS = {
		0,
		260,
		65,
		65
	}
}
ShopMenu.L10N_SYMBOL = {
	BUTTON_INFO = "button_detail",
	BUTTON_SHOP = "ui_shop",
	BUTTON_BUY = "button_buy",
	BUTTON_DETAILS = "button_detail",
	BUTTON_BRANDS = "button_shop_brands",
	BUTTON_HOTSPOT = "button_showOnMap",
	HEADER_TOOLS = "ui_tools",
	HEADER_BRANDS = "ui_brands",
	NOT_ENOUGH_MONEY_BUY = "shop_messageNotEnoughMoneyToBuy",
	BUTTON_COMBINATIONS = "ui_combinations",
	HEADER_GARAGE_LEASED = "ui_garageLeased",
	HEADER_SALES = "category_sales",
	BUTTON_CUSTOMIZE = "button_configurate",
	BUTTON_SELL = "button_sell",
	BUTTON_BACK = "button_back",
	LEASED_ITEMS = "shop_leasedItems",
	HEADER_OBJECTS = "ui_objects",
	BUTTON_CATEGORIES = "button_shop_categories",
	HEADER_PLACEABLES = "category_placeables",
	OWNED_ITEMS = "shop_ownedItems",
	BUTTON_RECOVER = "button_recover",
	BUTTON_GARAGE = "button_garage",
	HEADER_ANIMALS = "category_animals",
	HEADER_GARAGE_OWNED = "ui_garageOwned",
	HEADER_OTHERS = "ui_storeOthers",
	MESSAGE_NO_PERMISSION = "shop_messageNoPermissionGeneral",
	BUTTON_RETURN = "button_return",
	HEADER_PACKS = "ui_storePacks",
	HEADER_DLCS = "ui_modsAndDlcs",
	HEADER_VEHICLES = GS_IS_MOBILE_VERSION and "ui_categories" or "ui_vehicles"
}
ShopMenu.BRAND_IMAGE_HEIGHT_WIDTH_RATIO = 2
