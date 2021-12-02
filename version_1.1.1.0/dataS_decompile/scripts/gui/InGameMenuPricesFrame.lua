InGameMenuPricesFrame = {}
local InGameMenuPricesFrame_mt = Class(InGameMenuPricesFrame, TabbedMenuFrameElement)
InGameMenuPricesFrame.CONTROLS = {
	"productList",
	"priceList",
	"noSellpointsText",
	"pricesColumn",
	"fluctuationsColumn",
	"fluctuationBars",
	"fluctuationCurrentPrice",
	"noFluctuationsText",
	"fluctuationsLayout",
	"fluctuationMonthHeader"
}
InGameMenuPricesFrame.MODE_PRICES = 1
InGameMenuPricesFrame.MODE_FLUCTUATIONS = 2

function InGameMenuPricesFrame.new(subclass_mt, l10n, fillTypeManager)
	local self = InGameMenuPricesFrame:superClass().new(nil, subclass_mt or InGameMenuPricesFrame_mt)

	self:registerControls(InGameMenuPricesFrame.CONTROLS)

	self.l10n = l10n
	self.fillTypeManager = fillTypeManager
	self.fillTypes = {}
	self.sellingStations = {}
	self.buyingStations = {}
	self.hasCustomMenuButtons = true
	self.menuButtonInfo = {
		{
			inputAction = InputAction.MENU_BACK
		}
	}
	self.mode = InGameMenuPricesFrame.MODE_PRICES

	return self
end

function InGameMenuPricesFrame:copyAttributes(src)
	InGameMenuPricesFrame:superClass().copyAttributes(self, src)

	self.l10n = src.l10n
	self.fillTypeManager = src.fillTypeManager
end

function InGameMenuPricesFrame:onGuiSetupFinished()
	InGameMenuPricesFrame:superClass().onGuiSetupFinished(self)
	self.productList:setDataSource(self)
	self.priceList:setDataSource(self)
end

function InGameMenuPricesFrame:onFrameOpen()
	InGameMenuPricesFrame:superClass().onFrameOpen(self)
	self:rebuildTable()
	self:setMode(self.mode)
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.productList)
	self:setSoundSuppressed(false)
end

function InGameMenuPricesFrame:onFrameClose()
	InGameMenuPricesFrame:superClass().onFrameClose(self)

	self.currentStations = {}
end

function InGameMenuPricesFrame:initialize()
	self.hotspotButtonInfo = {
		profile = "buttonHotspot",
		inputAction = InputAction.MENU_ACCEPT,
		text = self.l10n:getText(InGameMenuAnimalsFrame.L10N_SYMBOL.BUTTON_HOTSPOT),
		callback = function ()
			self:onButtonHotspot()
		end
	}
	self.toggleModeButtonInfo = {
		profile = "buttonActivate",
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.l10n:getText("button_showFluctuations"),
		callback = function ()
			self:onButtonToggleMode()
		end
	}
end

function InGameMenuPricesFrame:reset()
	InGameMenuPricesFrame:superClass().reset(self)

	self.arePricesInitialized = false
end

function InGameMenuPricesFrame:setMode(mode)
	self.mode = mode

	self.pricesColumn:setVisible(mode == InGameMenuPricesFrame.MODE_PRICES)
	self.fluctuationsColumn:setVisible(mode == InGameMenuPricesFrame.MODE_FLUCTUATIONS)

	if mode == InGameMenuPricesFrame.MODE_FLUCTUATIONS then
		FocusManager:setFocus(self.productList)
	end

	self:updateMenuButtons()
end

function InGameMenuPricesFrame.initialSortStations(station1, station2)
	return station1.uiName < station2.uiName
end

function InGameMenuPricesFrame:updateStations(stations)
	self.sellingStations = {}
	self.buyingStations = {}

	for _, station in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
		if station:isa(SellingStation) and not station.hideFromPricesMenu then
			station.uiName = station:getName()

			table.insert(self.sellingStations, station)
		end
	end

	for _, station in pairs(g_currentMission.storageSystem:getLoadingStations()) do
		if station:isa(BuyingStation) then
			station.uiName = station:getName()

			table.insert(self.buyingStations, station)
		end
	end

	table.sort(self.sellingStations, InGameMenuPricesFrame.initialSortStations)
	table.sort(self.buyingStations, InGameMenuPricesFrame.initialSortStations)
end

function InGameMenuPricesFrame:updateMenuButtons()
	self.menuButtonInfo = {
		{
			inputAction = InputAction.MENU_BACK
		}
	}
	local hotspot = self:getSelectedHotspot()

	if hotspot ~= nil and FocusManager:getFocusedElement() == self.priceList then
		if hotspot == g_currentMission.currentMapTargetHotspot then
			self.hotspotButtonInfo.text = self.l10n:getText(InGameMenuPricesFrame.L10N_SYMBOL.REMOVE_MARKER)
		else
			self.hotspotButtonInfo.text = self.l10n:getText(InGameMenuPricesFrame.L10N_SYMBOL.SET_MARKER)
		end

		table.insert(self.menuButtonInfo, self.hotspotButtonInfo)
	end

	if self.mode == InGameMenuPricesFrame.MODE_FLUCTUATIONS then
		self.toggleModeButtonInfo.text = self.l10n:getText("button_showActualPrices")
	else
		self.toggleModeButtonInfo.text = self.l10n:getText("button_showFluctuations")
	end

	table.insert(self.menuButtonInfo, self.toggleModeButtonInfo)
	self:setMenuButtonInfoDirty()
end

function InGameMenuPricesFrame:updateFluctuations()
	local fillTypeDesc = self.fillTypes[self.productList.selectedIndex]
	local originalPrice = fillTypeDesc.pricePerLiter
	local currentPrice = originalPrice
	local totalPrice = 0
	local totalNumPrices = 0

	for _, station in ipairs(self.currentStations) do
		if station.uiIsSelling then
			totalPrice = totalPrice + station:getEffectiveFillTypePrice(fillTypeDesc.index)
			totalNumPrices = totalNumPrices + 1
		end
	end

	if totalNumPrices > 0 then
		currentPrice = totalPrice / totalNumPrices
	end

	local factors = fillTypeDesc.economy.factors
	local min = math.huge
	local max = 0

	for i = 1, 12 do
		min = math.min(min, factors[i])
		max = math.max(max, factors[i])
	end

	local range = max - min
	min = math.max(min - range * 0.2, 0)
	max = max + range * 0.2
	local hasAnyFluctuations = min ~= max

	self.noFluctuationsText:setVisible(not hasAnyFluctuations)
	self.fluctuationsLayout:setVisible(hasAnyFluctuations)
	self.fluctuationCurrentPrice:setVisible(hasAnyFluctuations)

	if not hasAnyFluctuations then
		return
	end

	for month = 1, 12 do
		local barBg = self.fluctuationBars[month]
		local bar = barBg.elements[1]
		local percentageInView = (factors[month] - min) / (max - min)
		local prevPercentageInView = (factors[(month - 2) % 12 + 1] - min) / (max - min)
		local diff = percentageInView - prevPercentageInView

		if diff > 0 then
			barBg:applyProfile("ingameMenuPriceFluctuationBarBgUp")
			bar:applyProfile("ingameMenuPriceFluctuationBarUp")
			barBg:setPosition(nil, prevPercentageInView * barBg.parent.absSize[2])
		else
			barBg:applyProfile("ingameMenuPriceFluctuationBarBgDown")
			bar:applyProfile("ingameMenuPriceFluctuationBarDown")
			barBg:setPosition(nil, percentageInView * barBg.parent.absSize[2])
		end

		barBg:setSize(nil, math.abs(diff) * barBg.parent.absSize[2])
	end

	local currentFactor = currentPrice / originalPrice

	if originalPrice == 0 then
		currentFactor = 1
	end

	local currentPosition = math.max(math.min((currentFactor - min) / (max - min), 1), 0)

	self.fluctuationCurrentPrice:setPosition(nil, currentPosition * (self.fluctuationCurrentPrice.parent.absSize[2] - self.fluctuationsColumn.elements[1].absSize[2]))

	for i = 1, 12 do
		self.fluctuationMonthHeader[i]:setText(g_i18n:formatPeriod(i, true))
	end
end

function InGameMenuPricesFrame:rebuildTable()
	self.fillTypes = {}

	for _, fillTypesDesc in pairs(self.fillTypeManager:getFillTypes()) do
		if fillTypesDesc.showOnPriceTable then
			table.insert(self.fillTypes, fillTypesDesc)
		end
	end

	self.productList:reloadData()
end

function InGameMenuPricesFrame:getSelectedHotspot()
	local selectedIndex = self.priceList.selectedIndex

	if selectedIndex < 1 then
		return nil
	end

	local station = self.currentStations[selectedIndex]

	if station ~= nil and station.owningPlaceable ~= nil then
		return station.owningPlaceable:getHotspot(1)
	end

	return nil
end

function InGameMenuPricesFrame:getStorageFillLevel(fillType, farmSilo)
	local totalCapacity = 0
	local usedCapacity = 0
	local farmId = g_currentMission:getFarmId()

	for _, storage in pairs(g_currentMission.storageSystem:getStorages()) do
		if storage:getOwnerFarmId() == farmId and storage.foreignSilo ~= farmSilo and storage:getIsFillTypeSupported(fillType.index) then
			usedCapacity = usedCapacity + storage:getFillLevel(fillType.index)
			totalCapacity = totalCapacity + storage:getCapacity(fillType.index)
		end
	end

	if totalCapacity > 0 then
		return usedCapacity, totalCapacity
	else
		return -1, -1
	end
end

function InGameMenuPricesFrame:getNumberOfItemsInSection(list, section)
	if list == self.productList then
		return #self.fillTypes
	else
		return #self.currentStations
	end
end

function InGameMenuPricesFrame:populateCellForItemInSection(list, section, index, cell)
	if list == self.productList then
		local fillTypeDesc = self.fillTypes[index]

		cell:getAttribute("icon"):setImageFilename(fillTypeDesc.hudOverlayFilename)
		cell:getAttribute("title"):setText(fillTypeDesc.title)

		local localLiters = self:getStorageFillLevel(fillTypeDesc, true)
		local foreignLiters = self:getStorageFillLevel(fillTypeDesc, false)

		if localLiters < 0 and foreignLiters < 0 then
			cell:getAttribute("storage"):setText("-")
		else
			cell:getAttribute("storage"):setText(self.l10n:formatVolume(math.max(localLiters, 0) + math.max(foreignLiters, 0)))
		end
	else
		local station = self.currentStations[index]
		local fillTypeDesc = self.fillTypes[self.productList.selectedIndex]
		local hasHotspot = station.owningPlaceable:getHotspot(1) ~= nil

		cell:getAttribute("hotspot"):setVisible(hasHotspot)

		if hasHotspot then
			local isTagActive = g_currentMission.currentMapTargetHotspot ~= nil and station.owningPlaceable:getHotspot(1) == g_currentMission.currentMapTargetHotspot

			cell:getAttribute("hotspot"):applyProfile(isTagActive and "ingameMenuPriceItemHotspotActive" or "ingameMenuPriceItemHotspot")
		end

		cell:getAttribute("title"):setText(station.uiName)

		local price = tostring(station:getEffectiveFillTypePrice(fillTypeDesc.index))

		cell:getAttribute("price"):setVisible(station.uiIsSelling)
		cell:getAttribute("buyPrice"):setVisible(not station.uiIsSelling)

		if station.uiIsSelling then
			cell:getAttribute("price"):setValue(price * 1000)

			local priceTrend = station:getCurrentPricingTrend(fillTypeDesc.index)
			local profile = "ingameMenuPriceArrow"

			if priceTrend ~= nil then
				if Utils.isBitSet(priceTrend, SellingStation.PRICE_GREAT_DEMAND) then
					profile = "ingameMenuPriceArrowGreatDemand"
				elseif Utils.isBitSet(priceTrend, SellingStation.PRICE_CLIMBING) then
					profile = "ingameMenuPriceArrowClimbing"
				elseif Utils.isBitSet(priceTrend, SellingStation.PRICE_FALLING) then
					profile = "ingameMenuPriceArrowFalling"
				end
			end

			cell:getAttribute("priceTrend"):applyProfile(profile)
		else
			cell:getAttribute("buyPrice"):setValue(price * 100)
			cell:getAttribute("priceTrend"):applyProfile("ingameMenuPriceArrow")
		end
	end
end

function InGameMenuPricesFrame:onListSelectionChanged(list, section, index)
	if list == self.productList then
		local fillTypeDesc = self.fillTypes[index]
		self.currentStations = {}

		for _, station in ipairs(self.sellingStations) do
			if station:getIsFillTypeAllowed(fillTypeDesc.index) then
				station.uiIsSelling = true

				table.insert(self.currentStations, station)
			end
		end

		for _, station in ipairs(self.buyingStations) do
			if station:getIsFillTypeSupported(fillTypeDesc.index) then
				station.uiIsSelling = false

				table.insert(self.currentStations, station)
			end
		end

		self.noSellpointsText:setVisible(#self.currentStations == 0)
		self.priceList:reloadData()
		self:updateFluctuations()
	end

	self:updateMenuButtons()
end

function InGameMenuPricesFrame:onButtonHotspot()
	local hotspot = self:getSelectedHotspot()

	if hotspot ~= nil then
		if g_currentMission.currentMapTargetHotspot == hotspot then
			g_currentMission:setMapTargetHotspot(nil)
		else
			g_currentMission:setMapTargetHotspot(hotspot)
		end

		self:updateMenuButtons()
	else
		g_currentMission:setMapTargetHotspot(nil)
	end

	self.priceList:reloadData()
end

function InGameMenuPricesFrame:onButtonToggleMode()
	if self.mode == InGameMenuPricesFrame.MODE_PRICES then
		self:setMode(InGameMenuPricesFrame.MODE_FLUCTUATIONS)
	else
		self:setMode(InGameMenuPricesFrame.MODE_PRICES)
	end
end

InGameMenuPricesFrame.PROFILE = {
	PRICE_CELL_TREND_UP = "ingameMenuPriceRowPriceCellTrendUp",
	PRICE_CELL_GREAT_DEMAND = "ingameMenuPriceRowPriceCellGreatDemand",
	SILO_NAME = "ingameMenuPriceRowSiloNameCell",
	SILO_CAPACITY_LABEL = "ingameMenuPriceRowSiloCapacity",
	LITERS = "ingameMenuPriceRowLiters",
	PRICE_CELL_TREND_DOWN = "ingameMenuPriceRowPriceCellTrendDown",
	LITERS_LAST_ROW = "ingameMenuPriceRowLitersLastRow",
	SELLING_POINT_CELL_TAGGED = "ingameMenuPriceRowSellingPointCellTagged",
	SILO_LITERS = "ingameMenuPriceRowSiloLiters",
	SILO_LITERS_LAST_ROW = "ingameMenuPriceRowSiloLitersLastRow",
	SELLING_POINT_CELL_NONE = "ingameMenuPriceRowSellingPointCellNone",
	PRICE_CELL_NEUTRAL = "ingameMenuPriceRowPriceCell",
	SELLING_POINT_CELL_NEUTRAL = "ingameMenuPriceRowSellingPointCell",
	SILO_NAME_LAST_ROW = "ingameMenuPriceRowSiloNameCellLastRow",
	SILO_CAPACITY_VALUE = "ingameMenuPriceRowSiloCapacityValue"
}
InGameMenuPricesFrame.L10N_SYMBOL = {
	SET_MARKER = "action_tag",
	REMOVE_MARKER = "action_untag",
	SILO_CAPACITY = "ui_silos_totalCapacity"
}
