ShopController = {}
local ShopController_mt = Class(ShopController)
ShopController.MAX_ATTRIBUTES_PER_ROW = 5
ShopController.COINS_CATEGORY = "COINS"
ShopController.SALES_CATEGORY = "SALES"

function ShopController.new(messageCenter, l10n, storeManager, brandManager, fillTypeManager, inAppPurchaseController)
	local self = setmetatable({}, ShopController_mt)
	self.l10n = l10n
	self.storeManager = storeManager
	self.brandManager = brandManager
	self.fillTypeManager = fillTypeManager
	self.inAppPurchaseController = inAppPurchaseController
	self.client = nil
	self.currentMission = nil
	self.playerFarm = nil
	self.playerFarmId = 0
	self.isInitialized = false
	self.isBuying = false
	self.isSelling = false
	self.buyVehicleNow = 0
	self.buyObjectNow = 0
	self.buyHandToolNow = 0
	self.displayBrands = {}
	self.displayVehicleCategories = {}
	self.displayToolCategories = {}
	self.displayObjectCategories = {}
	self.displayPlaceableCategories = {}
	self.displayPacks = {}
	self.displayDLCs = {}
	self.ownedFarmItems = {}
	self.leasedFarmItems = {}
	self.currentSellStoreItem = nil
	self.currentSellItem = nil
	self.buyItemFilename = nil
	self.buyItemPrice = 0
	self.buyItemIsOutsideBuy = false
	self.buyItemConfigurations = nil
	self.buyItemIsLeasing = false
	self.buyItemLicensePlateData = nil
	self.updateShopItemsCallback = nil
	self.updateAllItemsCallback = nil
	self.switchToConfigurationCallback = nil
	self.startPlacementModeCallback = nil
	self.saleItemBoughtCallback = nil

	self:subscribeEvents(messageCenter)

	return self
end

function ShopController:reset()
	self.isInitialized = false
	self.displayBrands = {}
	self.displayVehicleCategories = {}
	self.displayToolCategories = {}
	self.displayObjectCategories = {}
	self.displayPlaceableCategories = {}
	self.displayPacks = {}
	self.displayDLCs = {}
	self.ownedFarmItems = {}
	self.leasedFarmItems = {}
	self.currentSellItem = nil
	self.isBuying = false
	self.isSelling = false
end

function ShopController:subscribeEvents(messageCenter)
	messageCenter:subscribe(BuyVehicleEvent, self.onVehicleBuyEvent, self)
	messageCenter:subscribe(BuyObjectEvent, self.onObjectBuyEvent, self)
	messageCenter:subscribe(BuyHandToolEvent, self.onHandToolBuyEvent, self)
	messageCenter:subscribe(SellVehicleEvent, self.onVehicleSellEvent, self)
	messageCenter:subscribe(SellPlaceableEvent, self.onPlaceableSellEvent, self)
	messageCenter:subscribe(SellHandToolEvent, self.onHandToolSellEvent, self)
end

function ShopController:addBrandForDisplay(brand)
	table.insert(self.displayBrands, {
		id = brand.index,
		iconFilename = brand.imageShopOverview,
		label = brand.title,
		sortValue = brand.name
	})
end

function ShopController:addCategoryForDisplay(category)
	local categories = nil

	if category.type == StoreManager.CATEGORY_TYPE.VEHICLE then
		categories = self.displayVehicleCategories
	elseif category.type == StoreManager.CATEGORY_TYPE.TOOL then
		categories = self.displayToolCategories
	elseif category.type == StoreManager.CATEGORY_TYPE.OBJECT then
		categories = self.displayObjectCategories
	elseif category.type == StoreManager.CATEGORY_TYPE.PLACEABLE then
		categories = self.displayPlaceableCategories
	end

	if categories ~= nil then
		table.insert(categories, {
			id = category.name,
			iconFilename = category.image,
			label = category.title,
			sortValue = category.orderId
		})
	end
end

function ShopController:load()
	if not self.isInitialized then
		local foundBrands = {}
		local foundCategory = {}
		local foundDLCs = {}

		for _, storeItem in ipairs(self.storeManager:getItems()) do
			if storeItem.categoryName ~= "" and storeItem.showInStore and (storeItem.extraContentId == nil or g_extraContentSystem:getIsItemIdUnlocked(storeItem.extraContentId)) then
				local brand = self.brandManager:getBrandByIndex(storeItem.brandIndex)

				if brand ~= nil and not foundBrands[storeItem.brandIndex] and storeItem.species ~= "placeable" then
					foundBrands[storeItem.brandIndex] = true

					if brand.name ~= "NONE" then
						self:addBrandForDisplay(brand)
					end
				end

				local category = self.storeManager:getCategoryByName(storeItem.categoryName)

				if category ~= nil and not foundCategory[storeItem.categoryName] then
					foundCategory[storeItem.categoryName] = true

					self:addCategoryForDisplay(category)
				end

				if storeItem.customEnvironment ~= nil and foundDLCs[storeItem.customEnvironment] == nil and storeItem.species ~= "placeable" then
					local info = {
						id = storeItem.customEnvironment,
						isMod = storeItem.isMod,
						label = storeItem.dlcTitle,
						iconFilename = g_modManager:getModByName(storeItem.customEnvironment).iconFilename,
						sortValue = storeItem.dlcTitle
					}
					foundDLCs[storeItem.customEnvironment] = true

					table.insert(self.displayDLCs, info)
				end
			end
		end

		for _, pack in pairs(self.storeManager:getPacks()) do
			table.insert(self.displayPacks, {
				id = pack.name,
				iconFilename = pack.image,
				label = pack.title,
				sortValue = pack.orderId
			})
		end

		if Platform.hasInAppPurchases then
			self:addCategoryForDisplay(self.storeManager:getCategoryByName(ShopController.COINS_CATEGORY))
		end

		table.sort(self.displayBrands, ShopController.brandSortFunction)
		table.sort(self.displayToolCategories, ShopController.categorySortFunction)
		table.sort(self.displayObjectCategories, ShopController.categorySortFunction)
		table.sort(self.displayPlaceableCategories, ShopController.categorySortFunction)
		table.sort(self.displayVehicleCategories, ShopController.categorySortFunction)
		table.sort(self.displayPacks, ShopController.categorySortFunction)
		table.sort(self.displayDLCs, ShopController.brandSortFunction)

		self.isInitialized = true
	end
end

function ShopController:setClient(client)
	self.client = client
end

function ShopController:setCurrentMission(currentMission)
	self.currentMission = currentMission

	self.inAppPurchaseController:setMission(currentMission)
end

function ShopController:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm

	if playerFarm ~= nil then
		self.playerFarmId = playerFarm.farmId
	else
		self.playerFarmId = 0
	end
end

function ShopController:setUpdateShopItemsCallback(callback, target)
	function self.updateShopItemsCallback()
		callback(target)
	end
end

function ShopController:setUpdateAllItemsCallback(callback, target)
	function self.updateAllItemsCallback()
		callback(target)
	end
end

function ShopController:setSaleItemBoughtCallback(callback, target)
	function self.saleItemBoughtCallback()
		callback(target)
	end
end

function ShopController:setSwitchToConfigurationCallback(callback, target)
	function self.switchToConfigurationCallback(...)
		callback(target, ...)
	end
end

function ShopController:setStartPlacementModeCallback(callback, target)
	function self.startPlacementModeCallback(...)
		callback(target, ...)
	end
end

function ShopController.filterOwnedItemsByFarmId(ownedFarmItems, farmId)
	local filteredItems = {}

	for storeItem, itemInfos in pairs(ownedFarmItems) do
		for _, concreteItem in pairs(itemInfos.items) do
			if concreteItem:getOwnerFarmId() == farmId then
				local filteredItemInfos = filteredItems[storeItem]

				if filteredItemInfos == nil then
					filteredItemInfos = {}
					filteredItems[storeItem] = filteredItemInfos
					filteredItemInfos.storeItem = storeItem
					filteredItemInfos.numItems = 0
					filteredItemInfos.items = {}
				end

				filteredItemInfos.numItems = filteredItemInfos.numItems + 1
				filteredItemInfos.items[concreteItem] = concreteItem
			end
		end
	end

	return filteredItems
end

function ShopController:setOwnedFarmItems(ownedFarmItems, playerFarmId)
	self.ownedFarmItems = ShopController.filterOwnedItemsByFarmId(ownedFarmItems, playerFarmId)
end

function ShopController:setLeasedFarmItems(leasedFarmItems, playerFarmId)
	self.leasedFarmItems = ShopController.filterOwnedItemsByFarmId(leasedFarmItems, playerFarmId)
end

function ShopController:update(dt)
	if self.buyVehicleNow > 0 then
		if self.buyVehicleNow == 2 then
			self.buyVehicleNow = 0

			self.client:getServerConnection():sendEvent(BuyVehicleEvent.new(self.buyItemFilename, self.buyItemIsOutsideBuy, self.buyItemConfigurations, self.buyItemIsLeasing, self.playerFarmId, self.buyItemLicensePlateData, self.buyItemSaleItem))

			if not self.buyItemIsOutsideBuy then
				self.updateShopItemsCallback()
			end
		else
			self.buyVehicleNow = self.buyVehicleNow + 1
		end
	end

	if self.buyObjectNow > 0 then
		if self.buyObjectNow == 2 then
			self.buyObjectNow = 0

			self.client:getServerConnection():sendEvent(BuyObjectEvent.new(self.buyItemFilename, self.buyItemIsOutsideBuy, self.playerFarmId))

			if not self.buyItemIsOutsideBuy then
				self.updateShopItemsCallback()
			end
		else
			self.buyObjectNow = self.buyObjectNow + 1
		end
	end

	if self.buyHandToolNow > 0 then
		if self.buyHandToolNow == 2 then
			self.buyHandToolNow = 0

			self.client:getServerConnection():sendEvent(BuyHandToolEvent.new(self.buyItemFilename, self.playerFarmId))

			if not self.buyItemIsOutsideBuy then
				self.updateShopItemsCallback()
			end
		else
			self.buyHandToolNow = self.buyHandToolNow + 1
		end
	end
end

function ShopController:makeDisplayItem(storeItem, realItem, configurations, saleItem)
	StoreItemUtil.loadSpecsFromXML(storeItem)

	local attributeIconProfiles = {}
	local attributeValues = {}

	local function addAttribute(profiles, values, profile, value)
		if profile ~= nil and value ~= nil then
			table.insert(profiles, profile)
			table.insert(values, value)
		end
	end

	if configurations == nil then
		configurations = storeItem.defaultConfigurationIds
	end

	local usedSpecs = {
		fillTypes = true,
		seedFillTypes = true,
		animalFoodFillTypes = true,
		prodPointInputFillTypes = true,
		prodPointOutputFillTypes = true,
		sellingStationFillTypes = true,
		powerConfig = true
	}

	local function addSpecFromVehicle(specName, specDesc, _storeItem, _realItem, _configurations, _saleItem)
		if usedSpecs[specName] == nil then
			if _realItem ~= nil then
				_configurations = _realItem.configurations
			elseif _saleItem ~= nil then
				_configurations = _saleItem.configurations
			end

			if specDesc.getValueFunc ~= nil then
				local value, profile = specDesc.getValueFunc(_storeItem, _realItem, _configurations, _saleItem)

				if value ~= nil then
					addAttribute(attributeIconProfiles, attributeValues, profile or specDesc.profile, value)

					usedSpecs[specName] = true
				end
			end
		end
	end

	local function addSpec(specName)
		local desc = self.storeManager:getSpecTypeByName(specName)

		if desc ~= nil and desc.species == storeItem.species then
			addSpecFromVehicle(specName, desc, storeItem, realItem, configurations, saleItem)

			if storeItem.bundleInfo ~= nil then
				for _, bundleItem in ipairs(storeItem.bundleInfo.bundleItems) do
					if configurations == nil then
						configurations = {}
					end

					for configName, data in pairs(bundleItem.preSelectedConfigurations) do
						configurations[configName] = data.configValue
					end

					addSpecFromVehicle(specName, desc, bundleItem.item, nil, configurations, saleItem)
				end
			end
		end
	end

	addSpec("operatingTime")
	addSpec("power")
	addSpec("transmission")
	addSpec("fuel")
	addSpec("electricCharge")
	addSpec("methane")
	addSpec("maxSpeed")
	addSpec("neededPower")
	addSpec("incomePerHour")
	addSpec("capacity")
	addSpec("weight")
	addSpec("additionalWeight")
	addSpec("wheels")
	addSpec("balerBaleDensity")
	addSpec("balerBaleSizeRound")
	addSpec("balerBaleSizeSquare")
	addSpec("baleWrapperBaleSizeRound")
	addSpec("baleWrapperBaleSizeSquare")
	addSpec("inlineWrapperBaleSizeRound")
	addSpec("inlineWrapperBaleSizeSquare")
	addSpec("baleLoaderBaleSizeRound")
	addSpec("baleLoaderBaleSizeSquare")
	addSpec("licensePlate")

	if self.currentMission.slotSystem:getAreSlotsVisible() then
		addSpec("slots")
		addSpec("placeableSlots")
	else
		usedSpecs.slots = true
		usedSpecs.placeableSlots = true
	end

	if realItem == nil or realItem.propertyState == Vehicle.PROPERTY_STATE_OWNED or saleItem ~= nil then
		addSpec("dailyUpkeep")
	else
		usedSpecs.dailyUpkeep = true
	end

	if storeItem.lifetime ~= 0 or saleItem ~= nil then
		addSpec("age")
	end

	for _, specDesc in pairs(self.storeManager:getSpecTypes()) do
		if usedSpecs[specDesc.name] == nil then
			addSpec(specDesc.name)
		end
	end

	local fillTypesSpec = self.storeManager:getSpecTypeByName("fillTypes")
	local seedFillTypeSpec = self.storeManager:getSpecTypeByName("seedFillTypes")
	local foodFillTypesSpec = self.storeManager:getSpecTypeByName("animalFoodFillTypes")
	local prodPointInputFillTypesSpec = self.storeManager:getSpecTypeByName("prodPointInputFillTypes")
	local prodPointOutputFillTypesSpec = self.storeManager:getSpecTypeByName("prodPointOutputFillTypes")
	local sellingStationFillTypesSpec = self.storeManager:getSpecTypeByName("sellingStationFillTypes")
	local fillTypeIconFilenames, seedTypeIconFilenames, foodFillTypeIconFilenames, prodPointInputFillTypeIconFilenames, prodPointOutputFillTypeIconFilenames, sellingStationFillTypesIconFilenames = nil

	local function getIconFilenamesForSpec(spec, _storeItem, _realItem, _configurations)
		local iconFilenames = {}

		if spec ~= nil then
			local fillTypeIndicesList = spec.getValueFunc(_storeItem, _realItem, _configurations)

			if fillTypeIndicesList ~= nil then
				for _, fillTypeIndex in pairs(fillTypeIndicesList) do
					local fillType = self.fillTypeManager:getFillTypeByIndex(fillTypeIndex)

					if fillType ~= nil then
						table.insert(iconFilenames, fillType.hudOverlayFilename)
					end
				end
			end
		end

		return iconFilenames
	end

	if storeItem.bundleInfo ~= nil then
		for _, bundleItem in ipairs(storeItem.bundleInfo.bundleItems) do
			if configurations == nil then
				configurations = {}
			end

			for configName, data in pairs(bundleItem.preSelectedConfigurations) do
				configurations[configName] = data.configValue
			end

			fillTypeIconFilenames = getIconFilenamesForSpec(fillTypesSpec, bundleItem.item, nil, configurations)
			seedTypeIconFilenames = getIconFilenamesForSpec(seedFillTypeSpec, bundleItem.item, nil, configurations)
			foodFillTypeIconFilenames = getIconFilenamesForSpec(foodFillTypesSpec, bundleItem.item, nil, configurations)
		end
	else
		fillTypeIconFilenames = getIconFilenamesForSpec(fillTypesSpec, storeItem, realItem)
		seedTypeIconFilenames = getIconFilenamesForSpec(seedFillTypeSpec, storeItem, realItem)
		foodFillTypeIconFilenames = getIconFilenamesForSpec(foodFillTypesSpec, storeItem, realItem)
		prodPointInputFillTypeIconFilenames = getIconFilenamesForSpec(prodPointInputFillTypesSpec, storeItem, realItem)
		prodPointOutputFillTypeIconFilenames = getIconFilenamesForSpec(prodPointOutputFillTypesSpec, storeItem, realItem)
		sellingStationFillTypesIconFilenames = getIconFilenamesForSpec(sellingStationFillTypesSpec, storeItem, realItem)
	end

	local iconFilenames = {
		fillTypeIconFilenames = fillTypeIconFilenames,
		seedTypeIconFilenames = seedTypeIconFilenames,
		foodFillTypeIconFilenames = foodFillTypeIconFilenames,
		prodPointInputFillTypeIconFilenames = prodPointInputFillTypeIconFilenames,
		prodPointOutputFillTypeIconFilenames = prodPointOutputFillTypeIconFilenames,
		sellingStationFillTypesIconFilenames = sellingStationFillTypesIconFilenames
	}
	local descriptionText = table.concat(storeItem.functions, " ")
	local category = self.storeManager:getCategoryByName(storeItem.categoryName)
	local numOwned, numLeased = nil

	if g_currentMission ~= nil then
		if StoreItemUtil.getIsHandTool(storeItem) then
			local farm = g_farmManager:getFarmById(g_currentMission:getFarmId())

			if farm ~= nil and farm:hasHandtool(storeItem.xmlFilename) then
				numOwned = 1
			else
				numOwned = 0
			end
		elseif StoreItemUtil.getIsLeasable(storeItem) then
			numOwned = g_currentMission:getNumOwnedItems(storeItem, g_currentMission:getFarmId())

			if not GS_IS_MOBILE_VERSION then
				numLeased = g_currentMission:getNumLeasedItems(storeItem, g_currentMission:getFarmId())
			end
		elseif not StoreItemUtil.getIsObject(storeItem) then
			numOwned = g_currentMission:getNumOfItems(storeItem, self.playerFarmId)
		end
	end

	return ShopDisplayItem.new(storeItem, realItem, attributeIconProfiles, attributeValues, iconFilenames, descriptionText, category.orderId, numOwned, numLeased, saleItem)
end

function ShopController:updateDisplayItems(displayItems)
	local newDisplayItems = {}

	for _, oldDisplayItem in ipairs(displayItems) do
		local storeItem = g_storeManager:getItemByXMLFilename(oldDisplayItem.storeItem.xmlFilename)
		local newDisplayItem = self:makeDisplayItem(storeItem, nil)

		table.insert(newDisplayItems, newDisplayItem)
	end

	return newDisplayItems
end

function ShopController:getOwnedItems()
	local displayItems = {}

	for storeItem, itemInfos in pairs(self.ownedFarmItems) do
		for concreteItem in pairs(itemInfos.items) do
			if storeItem.canBeSold then
				local displayItem = self:makeDisplayItem(storeItem, concreteItem)

				table.insert(displayItems, displayItem)
			end
		end
	end

	local farmHandTools = self.playerFarm:getHandTools()

	for _, handToolFileName in ipairs(farmHandTools) do
		local handToolStoreItem = self.storeManager:getItemByXMLFilename(handToolFileName)

		if handToolStoreItem ~= nil then
			local displayItem = self:makeDisplayItem(handToolStoreItem)

			table.insert(displayItems, displayItem)
		end
	end

	table.sort(displayItems, ShopController.displayItemSortFunction)

	return displayItems
end

function ShopController:getLeasedVehicles()
	local displayItems = {}

	for storeItem, itemInfos in pairs(self.leasedFarmItems) do
		for concreteItem in pairs(itemInfos.items) do
			local displayItem = self:makeDisplayItem(storeItem, concreteItem)

			table.insert(displayItems, displayItem)
		end
	end

	table.sort(displayItems, ShopController.displayItemSortFunction)

	return displayItems
end

function ShopController:getOwnedFarmItems()
	return self.ownedFarmItems
end

function ShopController:getLeasedFarmItems()
	return self.leasedFarmItems
end

function ShopController:getBrands()
	return self.displayBrands
end

function ShopController:getVehicleCategories()
	return self.displayVehicleCategories
end

function ShopController:getToolCategories()
	return self.displayToolCategories
end

function ShopController:getObjectCategories()
	return self.displayObjectCategories
end

function ShopController:getPlaceableCategories()
	return self.displayPlaceableCategories
end

function ShopController:getItemsByBrand(brandId)
	local items = {}
	local salesCategory = self.storeManager:getCategoryByName("sales")
	local brand = self.brandManager:getBrandByIndex(brandId)

	for _, storeItem in pairs(self.storeManager:getItems()) do
		local sale = nil

		if g_currentMission ~= nil then
			_, _, sale = g_currentMission.economyManager:getBuyPrice(storeItem)
		end

		local isUnlocked = storeItem.extraContentId == nil or g_extraContentSystem:getIsItemIdUnlocked(storeItem.extraContentId)

		if not storeItem.isBundleItem and isUnlocked and storeItem.showInStore and (storeItem.brandIndex == brandId or sale ~= nil and brand.title == salesCategory.title) and storeItem.species ~= "placeable" then
			local displayItem = self:makeDisplayItem(storeItem)

			table.insert(items, displayItem)
		end
	end

	return items
end

function ShopController:getItemsByCategory(categoryName)
	if categoryName == ShopController.COINS_CATEGORY then
		return self:getCoinItems()
	elseif categoryName == ShopController.SALES_CATEGORY then
		return self:getSaleItems()
	end

	local items = {}

	for _, storeItem in pairs(self.storeManager:getItems()) do
		local isUnlocked = storeItem.extraContentId == nil or g_extraContentSystem:getIsItemIdUnlocked(storeItem.extraContentId)

		if not storeItem.isBundleItem and isUnlocked and storeItem.showInStore and storeItem.categoryName == categoryName and storeItem.species ~= "placeable" then
			local displayItem = self:makeDisplayItem(storeItem)

			table.insert(items, displayItem)
		end
	end

	return items
end

function ShopController:getSaleItems()
	local list = {}
	local items = g_currentMission.vehicleSaleSystem:getItems()

	for _, item in ipairs(items) do
		local storeItem = g_storeManager:getItemByXMLFilename(item.xmlFilename)
		local displayItem = self:makeDisplayItem(storeItem, nil, item.configurations, item)

		table.insert(list, displayItem)
	end

	return list
end

function ShopController:getItemsByCategoryOwnedOrLeased(categoryName, owned, leased)
	if categoryName == ShopController.COINS_CATEGORY then
		return self:getCoinItems()
	end

	local input = {}

	if owned then
		input = self.ownedFarmItems
	elseif leased then
		input = self.leasedFarmItems
	end

	local items = {}

	for storeItem, itemInfos in pairs(input) do
		local add = false

		if storeItem.canBeSold and (storeItem.showInStore or storeItem.isBundleItem) and storeItem.categoryName == categoryName then
			add = true
		end

		if add then
			if owned then
				add = self.ownedFarmItems[storeItem] ~= nil
			elseif leased then
				add = self.leasedFarmItems[storeItem] ~= nil
			end
		end

		if add then
			for concreteItem in pairs(itemInfos.items) do
				local displayItem = self:makeDisplayItem(storeItem, concreteItem)

				table.insert(items, displayItem)
			end
		end
	end

	if self.playerFarm ~= nil then
		local farmHandTools = self.playerFarm:getHandTools()

		for _, handToolFileName in ipairs(farmHandTools) do
			local handToolStoreItem = self.storeManager:getItemByXMLFilename(handToolFileName)

			if handToolStoreItem ~= nil and handToolStoreItem.categoryName == categoryName then
				local displayItem = self:makeDisplayItem(handToolStoreItem)

				table.insert(items, displayItem)
			end
		end
	end

	table.sort(items, ShopController.displayItemSortFunction)

	return items
end

function ShopController:getOwnedCategories()
	local output = {}
	local categories = {}

	for storeItem, itemInfos in pairs(self.ownedFarmItems) do
		if storeItem.canBeSold and (storeItem.showInStore or storeItem.isBundleItem) and storeItem.species ~= "placeable" and categories[storeItem.categoryName] == nil then
			local imageFilename = storeItem.imageFilename

			for _, concreteItem in pairs(itemInfos.items) do
				if concreteItem.getImageFilename ~= nil then
					imageFilename = concreteItem:getImageFilename()
				end
			end

			categories[storeItem.categoryName] = imageFilename
		end
	end

	if self.playerFarm ~= nil then
		local farmHandTools = self.playerFarm:getHandTools()

		for _, handToolFileName in ipairs(farmHandTools) do
			local handToolStoreItem = self.storeManager:getItemByXMLFilename(handToolFileName)

			if handToolStoreItem ~= nil and categories[handToolStoreItem.categoryName] == nil then
				local imageFilename = handToolStoreItem.imageFilename
				categories[handToolStoreItem.categoryName] = imageFilename
			end
		end
	end

	for categoryName, iconFilename in pairs(categories) do
		local category = self.storeManager:getCategoryByName(categoryName)

		if category ~= nil then
			table.insert(output, {
				id = category.name,
				iconFilename = iconFilename,
				label = category.title,
				sortValue = category.orderId
			})
		end
	end

	table.sort(output, ShopController.categorySortFunction)

	return output
end

function ShopController:getLeasedCategories()
	local output = {}
	local categories = {}

	for storeItem, _ in pairs(self.leasedFarmItems) do
		if storeItem.showInStore then
			categories[storeItem.categoryName] = storeItem.imageFilename
		end
	end

	for categoryName, iconFilename in pairs(categories) do
		local category = self.storeManager:getCategoryByName(categoryName)

		if category ~= nil then
			table.insert(output, {
				id = category.name,
				iconFilename = iconFilename,
				label = category.title,
				sortValue = category.orderId
			})
		end
	end

	table.sort(output, ShopController.categorySortFunction)

	return output
end

function ShopController:getDLCCategories()
	return self.displayDLCs
end

function ShopController:getStorePacks()
	return self.displayPacks
end

function ShopController:getItemsByPack(packName)
	local items = {}
	local packItems = self.storeManager:getPackItems(packName)

	if packItems == nil then
		return items
	end

	for i = 1, #packItems do
		local storeItem = self.storeManager:getItemByXMLFilename(packItems[i])

		if not storeItem.isBundleItem and storeItem.showInStore then
			local displayItem = self:makeDisplayItem(storeItem)

			table.insert(items, displayItem)
		end
	end

	return items
end

function ShopController:getItemsByDLC(dlcId)
	local items = {}

	for _, storeItem in pairs(self.storeManager:getItems()) do
		if not storeItem.isBundleItem and storeItem.showInStore and storeItem.customEnvironment == dlcId and storeItem.species ~= "placeable" then
			local displayItem = self:makeDisplayItem(storeItem)

			table.insert(items, displayItem)
		end
	end

	return items
end

function ShopController:getItemsWithFilenames(filenames)
	local items = {}

	for _, xmlFilename in ipairs(filenames) do
		local storeItem = self.storeManager:getItemByXMLFilename(xmlFilename)

		if storeItem ~= nil and not storeItem.isBundleItem and storeItem.showInStore then
			local displayItem = self:makeDisplayItem(storeItem)

			table.insert(items, displayItem)
		end
	end

	return items
end

function ShopController:getItemsFromCombinations(combinations)
	local items = {}

	for i = 1, #combinations do
		local combinationData = combinations[i]
		local storeItems = self.storeManager:getItemsByCombinationData(combinationData)

		for j = 1, #storeItems do
			local displayItem = self:makeDisplayItem(storeItems[j].storeItem, nil, storeItems[j].configData)
			displayItem.configurations = storeItems[j].configData

			table.insert(items, displayItem)
		end
	end

	return items
end

function ShopController:canBeBought(storeItem, price)
	local enoughMoney = true

	if self.currentMission ~= nil then
		enoughMoney = price <= g_currentMission:getMoney()
	end

	local enoughSlots = self.currentMission.slotSystem:hasEnoughSlots(storeItem)

	if not enoughMoney then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY)
		})
	elseif not enoughSlots then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_SLOTS)
		})
	end

	local enoughItems = storeItem.maxItemCount == nil or storeItem.maxItemCount ~= nil and self.currentMission:getNumOfItems(storeItem, self.playerFarmId) < storeItem.maxItemCount

	if not enoughItems then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_TOO_MANY_PLACEABLES)
		})
	end

	return enoughSlots and enoughMoney and enoughItems
end

function ShopController:buy(storeItem, saleItem, outsideBuy, configurations)
	if self.isSelling then
		return
	end

	local price = 0

	if not outsideBuy then
		if saleItem ~= nil then
			price = saleItem.price
		else
			price = self.currentMission.economyManager:getBuyPrice(storeItem)
		end
	end

	if StoreItemUtil.getIsVehicle(storeItem) then
		self:buyVehicle(storeItem, saleItem, price, outsideBuy, configurations)
	elseif self:canBeBought(storeItem, price) then
		if StoreItemUtil.getIsPlaceable(storeItem) then
			self.startPlacementModeCallback(storeItem, false)
		elseif StoreItemUtil.getIsObject(storeItem) then
			self:buyObject(storeItem, price, outsideBuy)
		elseif StoreItemUtil.getIsHandTool(storeItem) then
			self:buyHandTool(storeItem, price, outsideBuy)
		end
	end
end

function ShopController:buyVehicle(vehicleStoreItem, saleItem, price, outsideBuy, configurations)
	self.buyItemFilename = vehicleStoreItem.xmlFilename
	self.buyItemPrice = price
	self.buyItemIsOutsideBuy = outsideBuy or false
	self.buyItemConfigurations = nil
	self.buyItemLicensePlateData = nil
	self.buyItemIsLeasing = false
	self.buyItemSaleItem = saleItem

	if StoreItemUtil.getIsLeasable(vehicleStoreItem) and not GS_IS_MOBILE_VERSION then
		self.switchToConfigurationCallback(vehicleStoreItem, saleItem, configurations)
	elseif self:canBeBought(vehicleStoreItem, price) then
		self:finalizeBuy()
	end
end

function ShopController:onYesNoBuyObject(yes)
	if yes then
		self.isBuying = true
		self.buyObjectNow = 1
	end
end

function ShopController:buyObject(objectStoreItem, price, outsideBuy)
	local text = string.format(self.l10n:getText(ShopController.L10N_SYMBOL.BUY_CONFIRMATION), self.l10n:formatMoney(price, 0, true, true))

	g_gui:showYesNoDialog({
		text = text,
		callback = self.onYesNoBuyObject,
		target = self
	})

	self.buyItemFilename = objectStoreItem.xmlFilename
	self.buyItemPrice = price
	self.buyItemIsOutsideBuy = outsideBuy
	self.buyItemConfigurations = nil
	self.buyItemLicensePlateData = nil
	self.buyItemIsLeasing = false
end

function ShopController:onYesNoBuyHandtool(yes)
	if yes then
		self.isBuying = true
		self.buyHandToolNow = 1
	end
end

function ShopController:buyHandTool(handToolStoreItem, price, outsideBuy)
	if not self.playerFarm:hasHandtool(handToolStoreItem.xmlFilename) then
		local text = string.format(self.l10n:getText(ShopController.L10N_SYMBOL.BUY_CONFIRMATION), self.l10n:formatMoney(price, 0, true, true))

		g_gui:showYesNoDialog({
			text = text,
			callback = self.onYesNoBuyHandtool,
			target = self
		})

		self.buyItemFilename = handToolStoreItem.xmlFilename
		self.buyItemPrice = price
		self.buyItemIsOutsideBuy = outsideBuy
		self.buyItemConfigurations = nil
		self.buyItemLicensePlateData = nil
		self.buyItemIsLeasing = false
	else
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_ALREADY_OWNED)
		})
	end
end

function ShopController:sell(storeItem, concreteItem)
	self.isSelling = true
	self.currentSellStoreItem = storeItem
	self.currentSellItem = concreteItem

	if StoreItemUtil.getIsPlaceable(storeItem) then
		if self.currentMission:getNumOwnedItems(storeItem, g_currentMission:getFarmId()) == 1 then
			local canBeSold, warning = concreteItem:canBeSold()

			if warning ~= nil then
				if canBeSold then
					g_gui:showYesNoDialog({
						text = warning,
						callback = self.sellPlaceableWarningInfoClickOk,
						target = self,
						yesText = g_i18n:getText("button_ok"),
						noText = g_i18n:getText("button_cancel")
					})
				else
					g_gui:showInfoDialog({
						text = warning
					})

					self.isSelling = false
				end
			else
				self:sellPlaceableWarningInfoClickOk(true)
			end
		elseif self.currentMission:getNumOwnedItems(storeItem, g_currentMission:getFarmId()) > 1 then
			self:onSellCallback(true)
		end
	else
		local sellPrice = nil

		if concreteItem ~= ShopDisplayItem.NO_CONCRETE_ITEM then
			sellPrice = self.currentMission.economyManager:getSellPrice(concreteItem)
		else
			sellPrice = self.currentMission.economyManager:getSellPrice(storeItem)
		end

		g_gui:showSellItemDialog({
			item = concreteItem,
			price = sellPrice,
			storeItem = storeItem,
			callback = self.onSellCallback,
			target = self
		})
	end
end

function ShopController:sellPlaceableWarningInfoClickOk(yes)
	if yes then
		g_gui:showSellItemDialog({
			item = self.currentSellItem,
			price = g_currentMission.economyManager:getSellPrice(self.currentSellItem),
			callback = self.onSellCallback,
			target = self
		})
	end
end

function ShopController:onSellCallback(yes)
	self.isSelling = false

	if yes then
		self:onSellItem(self.currentSellStoreItem, self.currentSellItem)

		self.currentSellItem = nil
	end
end

function ShopController:onSellItem(storeItem, concreteItem)
	if self.isSelling then
		return
	end

	if StoreItemUtil.getIsPlaceable(storeItem) then
		self:sellPlaceable(storeItem, concreteItem)
	elseif StoreItemUtil.getIsHandTool(storeItem) then
		self:sellHandTool(storeItem)
	else
		self:sellVehicle(concreteItem)
	end
end

function ShopController:sellPlaceable(placeableStoreItem, placeable)
	if self.currentMission:getNumOwnedItems(placeableStoreItem, g_currentMission:getFarmId()) == 1 then
		self.isSelling = true

		g_gui:showMessageDialog({
			visible = true,
			text = self.l10n:getText(ShopController.L10N_SYMBOL.SELLING_VEHICLE)
		})

		if placeable:isMapBound() then
			placeable:setOwnerFarmId(AccessHandler.EVERYONE)
			self:onPlaceableSold(g_currentMission.economyManager:getSellPrice(placeable))
		elseif NetworkUtil.getObjectId(placeable) ~= nil then
			self.client:getServerConnection():sendEvent(SellPlaceableEvent.new(placeable))
		else
			self:onPlaceableSellFailed()
		end
	elseif self.currentMission:getNumOwnedItems(placeableStoreItem, g_currentMission:getFarmId()) > 1 then
		self.startPlacementModeCallback(placeableStoreItem, true, placeable)
	end
end

function ShopController:sellHandTool(handToolStoreItem)
	if self.playerFarm:hasHandtool(handToolStoreItem.xmlFilename) then
		self.isSelling = true

		g_gui:showMessageDialog({
			visible = true,
			text = self.l10n:getText(ShopController.L10N_SYMBOL.SELLING_VEHICLE)
		})
		self.client:getServerConnection():sendEvent(SellHandToolEvent.new(handToolStoreItem.xmlFilename, self.playerFarmId))
	else
		self:onHandToolSellFailed()
	end
end

function ShopController:sellVehicle(vehicle)
	self.isSelling = true

	if self.currentMission:getHasPlayerPermission(Farm.PERMISSION.SELL_VEHICLE) and vehicle == self.currentMission.controlledVehicle then
		self.currentMission:onLeaveVehicle()
	end

	if vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED then
		g_gui:showMessageDialog({
			visible = true,
			text = self.l10n:getText(ShopController.L10N_SYMBOL.SELLING_VEHICLE)
		})
	else
		g_gui:showMessageDialog({
			visible = true,
			text = self.l10n:getText(ShopController.L10N_SYMBOL.RETURNING_VEHICLE)
		})
	end

	if NetworkUtil.getObjectId(vehicle) ~= nil then
		self.client:getServerConnection():sendEvent(SellVehicleEvent.new(vehicle))
	else
		self:onVehicleSellFailed(vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED, SellVehicleEvent.SELL_NO_PERMISSION)
	end
end

function ShopController:setConfigurations(vehicle, leaseItem, storeItem, configs, originalPrice, licensePlateData, saleItem)
	if configs ~= nil then
		local price, _, _ = self.currentMission.economyManager:getBuyPrice(storeItem, configs, saleItem)
		self.buyItemFilename = storeItem.xmlFilename
		self.buyItemPrice = price
		self.buyItemConfigurations = configs
		self.buyItemLicensePlateData = licensePlateData
		self.buyItemIsLeasing = leaseItem
		self.buyItemSaleItem = saleItem

		self:finalizeBuy()
	end
end

function ShopController:finalizeBuy()
	self.isBuying = true
	self.buyVehicleNow = 1
	local text = self.l10n:getText(ShopController.L10N_SYMBOL.BUYING_VEHICLE)

	if self.buyItemIsLeasing then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.LEASING_VEHICLE)
	end

	g_gui:showMessageDialog({
		visible = true,
		text = text
	})
end

function ShopController:onHandToolSellEvent(errorCode)
	if errorCode == SellHandToolEvent.STATE_SUCCESS then
		self:onHandToolSold()
	else
		self:onHandToolSellFailed(errorCode)
	end
end

function ShopController:onHandToolSold()
	g_gui:closeAllDialogs()
	g_gui:showInfoDialog({
		text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_SUCCESS),
		dialogType = DialogElement.TYPE_INFO,
		callback = self.onSoldCallback,
		target = self
	})
end

function ShopController:onHandToolSellFailed(state)
	g_gui:closeAllDialogs()

	local text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_FAILED)

	if state == SellHandToolEvent.STATE_IN_USE then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_IN_USE)
	elseif state == SellHandToolEvent.STATE_NO_PERMISSION then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_NO_PERMISSION)
	end

	g_gui:showInfoDialog({
		text = text,
		callback = self.onSoldCallback,
		target = self
	})
end

function ShopController:onVehicleBuyEvent(errorCode, leaseVehicle, price)
	if errorCode == BuyVehicleEvent.STATE_SUCCESS then
		self:onVehicleBought(leaseVehicle, price)
	else
		self:onVehicleBuyFailed(leaseVehicle, errorCode)
	end
end

function ShopController:onVehicleBought(leaseVehicle, price)
	g_gui:closeAllDialogs()

	if not leaseVehicle then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_SUCCESS),
			dialogType = DialogElement.TYPE_INFO,
			callback = self.onBoughtCallback,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.LEASE_VEHICLE_SUCCESS),
			dialogType = DialogElement.TYPE_INFO,
			callback = self.onBoughtCallback,
			target = self
		})
	end

	self.updateShopItemsCallback()
end

function ShopController:onVehicleBuyFailed(leaseVehicle, errorCode)
	g_gui:closeAllDialogs()

	local text = nil

	if errorCode == BuyVehicleEvent.STATE_NO_SPACE then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_NO_SPACE)
	elseif errorCode == BuyVehicleEvent.STATE_NO_PERMISSION then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_NO_PERMISSION)
	elseif errorCode == BuyVehicleEvent.STATE_NOT_ENOUGH_MONEY then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY)
	else
		text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_FAILED_TO_LOAD)
	end

	g_gui:showInfoDialog({
		text = text,
		callback = self.onBoughtCallback,
		target = self
	})
end

function ShopController:onObjectBuyEvent(errorCode, price)
	if errorCode == BuyObjectEvent.STATE_SUCCESS then
		self:onObjectBought(price)
	else
		self:onObjectBuyFailed(errorCode)
	end
end

function ShopController:onObjectBought(price)
	g_gui:closeAllDialogs()
	self.currentMission:addMoneyChange(-price, self.playerFarmId, MoneyType.SHOP_VEHICLE_BUY)
	g_gui:showInfoDialog({
		text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_OBJECT_SUCCESS),
		dialogType = DialogElement.TYPE_INFO,
		callback = self.onBoughtCallback,
		target = self
	})
end

function ShopController:onObjectBuyFailed(errorCode)
	g_gui:closeAllDialogs()

	if errorCode == BuyObjectEvent.STATE_NO_SPACE then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_NO_SPACE),
			callback = self.onBoughtCallback,
			target = self
		})
	elseif errorCode == BuyObjectEvent.STATE_LIMIT_REACHED then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_TOO_MANY_PALLETS),
			callback = self.onBoughtCallback,
			target = self
		})
	elseif errorCode == BuyObjectEvent.STATE_NOT_ENOUGH_MONEY then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY),
			callback = self.onBoughtCallback,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.LOAD_OBJECT_FAILED),
			callback = self.onBoughtCallback,
			target = self
		})
	end
end

function ShopController:onHandToolBuyEvent(success, errorCode, price)
	if success then
		self:onHandToolBought(price)
	else
		self:onHandToolBuyFailed(errorCode)
	end
end

function ShopController:onHandToolBought(price)
	g_gui:closeAllDialogs()

	if GS_IS_CONSOLE_VERSION or g_inputBinding:getLastInputMode() == GS_INPUT_HELP_MODE_GAMEPAD then
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_CHAINSAW_THANKS),
			dialogType = DialogElement.TYPE_INFO,
			callback = self.onBoughtCallback,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_CHAINSAW_SUCCESS),
			dialogType = DialogElement.TYPE_INFO,
			callback = self.onBoughtCallback,
			target = self
		})
	end
end

function ShopController:onHandToolBuyFailed(errorCode)
	g_gui:closeAllDialogs()

	local text = self.l10n:getText(ShopController.L10N_SYMBOL.LOAD_OBJECT_FAILED)

	if errorCode == BuyHandToolEvent.STATE_NO_PERMISSION then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.BUY_VEHICLE_NO_PERMISSION)
	elseif errorCode == BuyHandToolEvent.STATE_NOT_ENOUGH_MONEY then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.WARNING_NOT_ENOUGH_MONEY)
	end

	g_gui:showInfoDialog({
		text = text,
		callback = self.onBoughtCallback,
		target = self
	})
end

function ShopController:onVehicleSellEvent(isDirectSell, errorCode, sellPrice, isOwned)
	if isDirectSell then
		return
	end

	if errorCode == SellVehicleEvent.SELL_SUCCESS then
		self:onVehicleSold(sellPrice, isOwned)
	else
		self:onVehicleSellFailed(isOwned, errorCode)
	end
end

function ShopController:onVehicleSold(sellPrice, isOwned)
	g_gui:closeAllDialogs()

	local text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_SUCCESS)

	if not isOwned then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_SUCCESS)
	end

	g_gui:showInfoDialog({
		text = text,
		dialogType = DialogElement.TYPE_INFO,
		callback = self.onSoldCallback,
		target = self
	})
end

function ShopController:onVehicleSellFailed(isOwned, errorCode)
	g_gui:closeAllDialogs()

	local text = nil

	if isOwned then
		if errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
			text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_NO_PERMISSION)
		elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
			text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_IN_USE)
		elseif errorCode == SellVehicleEvent.SELL_LAST_VEHICLE then
			text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_LAST_VEHICLE_FAILED)
		else
			text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_VEHICLE_FAILED)
		end
	elseif errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_NO_PERMISSION)
	elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_IN_USE)
	elseif errorCode == SellVehicleEvent.SELL_LAST_VEHICLE then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.RETURN_LAST_VEHICLE_FAILED)
	else
		text = self.l10n:getText(ShopController.L10N_SYMBOL.RETURN_VEHICLE_FAILED)
	end

	g_gui:showInfoDialog({
		text = text,
		callback = self.onSoldCallback,
		target = self
	})
end

function ShopController:onPlaceableSellEvent(errorCode, sellPrice)
	if errorCode == SellPlaceableEvent.STATE_SUCCESS then
		self:onPlaceableSold(sellPrice)
	else
		self:onPlaceableSellFailed(errorCode)
	end
end

function ShopController:onPlaceableSold(sellPrice)
	if self.ignoreSoldPlaceableEvent then
		return
	end

	g_gui:closeAllDialogs()
	g_gui:showInfoDialog({
		text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_OBJECT_SUCCESS),
		dialogType = DialogElement.TYPE_INFO,
		callback = self.onSoldCallback,
		target = self
	})
end

function ShopController:onPlaceableSellFailed(state)
	g_gui:closeAllDialogs()

	local text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_OBJECT_FAILED)

	if state == SellPlaceableEvent.STATE_IN_USE then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.SELL_OBJECT_IN_USE)
	elseif state == SellPlaceableEvent.STATE_NO_PERMISSION then
		text = self.l10n:getText(ShopController.L10N_SYMBOL.NO_PERMISSION)
	end

	g_gui:showInfoDialog({
		text = text,
		callback = self.onSoldCallback,
		target = self
	})
end

function ShopController:onBoughtCallback()
	self.isBuying = false

	self.updateAllItemsCallback()

	if self.buyItemSaleItem ~= nil then
		self.saleItemBoughtCallback()
	end
end

function ShopController:onSoldCallback()
	self.isSelling = false

	self.updateAllItemsCallback()
end

function ShopController.brandSortFunction(item1, item2)
	return utf8ToUpper(item1.sortValue) < utf8ToUpper(item2.sortValue)
end

function ShopController.categorySortFunction(item1, item2)
	return item1.sortValue < item2.sortValue
end

function ShopController.displayItemSortFunction(item1, item2)
	if item1.orderValue == item2.orderValue then
		local sellPrice1 = item1:getSellPrice()
		local sellPrice2 = item2:getSellPrice()

		if sellPrice1 == sellPrice2 then
			return item2:getSortId() < item1:getSortId()
		else
			return sellPrice2 < sellPrice1
		end
	else
		return item1.orderValue < item2.orderValue
	end
end

function ShopController:getCoinItems()
	local list = {}

	if not self.inAppPurchaseController:getIsAvailable() then
		return list
	end

	for _, product in ipairs(self.inAppPurchaseController:getProducts()) do
		local storeItem = {
			isInAppPurchase = true,
			name = product:getId(),
			priceText = product:getPriceText(),
			title = product:getTitle(),
			imageFilename = product:getImageFilename(),
			product = product,
			canBeRecovered = self.inAppPurchaseController:getHasPendingPurchase(product)
		}
		local displayItem = ShopDisplayItem.new(storeItem, nil, , , , self.l10n:getText("function_coins"), #list)

		table.insert(list, displayItem)
	end

	return list
end

ShopController.PROFILE = {
	ICON_LEASED = "shopListAttributeIconLeased",
	ICON_OWNED = "shopListAttributeIconOwned"
}
ShopController.L10N_SYMBOL = {
	SELL_OBJECT_SUCCESS = "shop_messageSoldObject",
	RETURN_LAST_VEHICLE_FAILED = "shop_messageFailedToReturnLastVehicleText",
	SELLING_VEHICLE = "shop_messageSellingVehicle",
	RETURN_VEHICLE_SUCCESS = "shop_messageReturnedVehicle",
	LOAD_OBJECT_FAILED = "shop_messageFailedToLoadObject",
	WARNING_NOT_ENOUGH_MONEY = "shop_messageNotEnoughMoneyToBuy",
	BUYING_VEHICLE = "shop_messageBuyingVehicle",
	BUY_OBJECT_SUCCESS = "shop_messageGardenCenterPurchaseReady",
	WARNING_TOO_MANY_PLACEABLES = "warning_tooManyPlaceables",
	RETURNING_VEHICLE = "shop_messageReturningVehicle",
	WARNING_NOT_ENOUGH_SLOTS = "shop_messageNotEnoughSlotsToBuy",
	BUY_CONFIRMATION = "shop_doYouWantToBuy",
	WARNING_TOO_MANY_PALLETS = "warning_tooManyPallets",
	SELL_VEHICLE_FAILED = "shop_messageFailedToSellVehicle",
	SELL_LAST_VEHICLE_FAILED = "shop_messageFailedToSellLastVehicleText",
	SELL_VEHICLE_IN_USE = "shop_messageSellVehicleInUse",
	BUY_VEHICLE_FAILED_TO_LOAD = "shop_messageFailedToLoadVehicle",
	RETURN_VEHICLE_NO_PERMISSION = "shop_messageNoPermissionToReturnVehicleText",
	RETURN_VEHICLE_FAILED = "shop_messageFailedToReturnVehicle",
	BUY_VEHICLE_NO_PERMISSION = "shop_messageNoPermissionToBuyVehicleText",
	LEASE_VEHICLE_SUCCESS = "shop_messageLeasingReady",
	BUY_CHAINSAW_THANKS = "shop_messageThanksForBuying",
	SELL_OBJECT_FAILED = "shop_messageFailedToSellObject",
	SELL_VEHICLE_SUCCESS = "shop_messageSoldVehicle",
	NO_PERMISSION = "shop_messageNoPermissionGeneral",
	SELL_OBJECT_IN_USE = "shop_messageObjectInUse",
	LEASING_VEHICLE = "shop_messageLeasingVehicle",
	BUY_CHAINSAW_SUCCESS = "shop_messageBoughtChainsaw",
	BUY_ALREADY_OWNED = "shop_messageAlreadyOwned",
	CANNOT_SELL_TOUR_ITEMS = "shop_messageTourItemsCannotBeSold",
	WARNING_NO_SPACE = "shop_messageNoSpace",
	SELL_VEHICLE_NO_PERMISSION = "shop_messageNoPermissionToSellVehicleText",
	BUY_VEHICLE_SUCCESS = "shop_messagePurchaseReady",
	RETURN_VEHICLE_IN_USE = "shop_messageReturnVehicleInUse"
}
