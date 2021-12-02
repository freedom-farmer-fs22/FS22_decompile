InGameMenuVehiclesFrame = {}
local InGameMenuVehiclesFrame_mt = Class(InGameMenuVehiclesFrame, TabbedMenuFrameElement)
InGameMenuVehiclesFrame.CONTROLS = {
	TABLE_HEADER_BOX = "tableHeaderBox",
	MAIN_BOX = "mainBox",
	GARAGE_LIST_SLIDER = "garageListSlider",
	VEHICLE_TABLE = "vehicleTable"
}
InGameMenuVehiclesFrame.SCROLL_DELAY = FocusManager.DELAY_TIME
InGameMenuVehiclesFrame.MAX_NUM_VEHICLES = GS_IS_MOBILE_VERSION and 6 or 15

function InGameMenuVehiclesFrame.new(subclass_mt, messageCenter, l10n, storeManager, brandManager, shopController)
	local self = InGameMenuVehiclesFrame:superClass().new(nil, subclass_mt or InGameMenuVehiclesFrame_mt)

	self:registerControls(InGameMenuVehiclesFrame.CONTROLS)

	self.messageCenter = messageCenter
	self.l10n = l10n
	self.storeManager = storeManager
	self.brandManager = brandManager
	self.shopController = shopController
	self.dataBindings = {}
	self.vehicles = {}
	self.maxDisplayVehicles = 0
	self.needTableInit = true
	self.hasCustomMenuButtons = true

	return self
end

function InGameMenuVehiclesFrame:copyAttributes(src)
	InGameMenuVehiclesFrame:superClass().copyAttributes(self, src)

	self.messageCenter = src.messageCenter
	self.l10n = src.l10n
	self.storeManager = src.storeManager
	self.brandManager = src.brandManager
	self.shopController = src.shopController
end

function InGameMenuVehiclesFrame:initialize()
	for _, tableHeader in pairs(self.tableHeaderBox.elements) do
		tableHeader.focusChangeOverride = self:makeTableHeaderFocusOverrideFunction(tableHeader)
	end

	if GS_IS_MOBILE_VERSION then
		self.sellButton = {
			profile = "buttonSell",
			inputAction = InputAction.MENU_CANCEL,
			text = self.l10n:getText("button_sell"),
			callback = function ()
				self:onButtonSell()
			end
		}
	end
end

function InGameMenuVehiclesFrame:delete()
	InGameMenuVehiclesFrame:superClass().delete(self)
	self.messageCenter:unsubscribeAll(self)
end

local function alwaysOverride()
	return true
end

function InGameMenuVehiclesFrame:onFrameOpen()
	InGameMenuVehiclesFrame:superClass().onFrameOpen(self)

	if self.needTableInit then
		self.vehicleTable:initialize()
		self.vehicleTable:setProfileOverrideFilterFunction(alwaysOverride)

		self.maxDisplayVehicles = self.vehicleTable.maxNumItems
		self.needTableInit = false
	end

	self.tableHeaderBox:invalidateLayout()
	self:updateVehicles()
	self:setSoundSuppressed(true)

	if GS_IS_MOBILE_VERSION then
		FocusManager:setFocus(self.vehicleTable)
	else
		FocusManager:setFocus(self.tableHeaderBox)
	end

	self:setSoundSuppressed(false)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.MONEY_UNIT], self.updateGarage, self)
	self.messageCenter:subscribe(SellVehicleEvent, self.onVehicleSellEvent, self)
	self.messageCenter:subscribe(BuyVehicleEvent, self.onVehicleBuyEvent, self)
	self:updateMenuButtons()
end

function InGameMenuVehiclesFrame:onFrameClose()
	InGameMenuVehiclesFrame:superClass().onFrameClose(self)

	self.vehicles = {}

	self.messageCenter:unsubscribeAll(self)
end

function InGameMenuVehiclesFrame:updateGarage()
	if self:getIsVisible() then
		if GS_IS_MOBILE_VERSION then
			self:setNumberOfPages(math.ceil(#self.vehicles / InGameMenuVehiclesFrame.MAX_NUM_VEHICLES))
		end

		self.vehicleTable:clearData()

		for _, vehicle in ipairs(self.vehicles) do
			if vehicle.showInVehicleMenu then
				local dataRow = self:buildDataRow(vehicle)

				self.vehicleTable:addRow(dataRow)
			end
		end

		self.vehicleTable:updateView(false)
	end
end

function InGameMenuVehiclesFrame:updateVerticalSlider()
	if self.garageListSlider ~= nil then
		local maxVerticalSliderValue = math.max(1, #self.vehicles - self.maxDisplayVehicles)

		self.garageListSlider:setMinValue(1)
		self.garageListSlider:setMaxValue(maxVerticalSliderValue)

		local numVisibleItems = math.min(#self.vehicles, self.maxDisplayVehicles)

		self.garageListSlider:setSliderSize(numVisibleItems, #self.vehicles)
	end
end

function InGameMenuVehiclesFrame:updateVehicles()
	self.vehicles = {}

	if g_currentMission.player ~= nil then
		for _, vehicle in ipairs(g_currentMission.vehicles) do
			local hasAccess = g_currentMission.accessHandler:canPlayerAccess(vehicle)
			local isProperty = vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED or vehicle.propertyState == Vehicle.PROPERTY_STATE_LEASED
			local isPallet = vehicle.typeName == "pallet"

			if hasAccess and vehicle.getSellPrice ~= nil and vehicle.price ~= nil and isProperty and not isPallet and not SpecializationUtil.hasSpecialization(Rideable, vehicle.specializations) then
				table.insert(self.vehicles, vehicle)
			end
		end
	end

	self:updateGarage()
	self:updateVerticalSlider()
end

function InGameMenuVehiclesFrame:getMainElementSize()
	return self.mainBox.size
end

function InGameMenuVehiclesFrame:getMainElementPosition()
	return self.mainBox.absPosition
end

function InGameMenuVehiclesFrame:makeTableHeaderFocusOverrideFunction(headerElement)
	return function (target, direction)
		local doOverride = false
		local newTarget = nil

		if direction == FocusManager.TOP then
			doOverride = true
			newTarget = headerElement

			if self.garageListSlider ~= nil then
				self.garageListSlider:onScrollDown()
			end
		elseif direction == FocusManager.BOTTOM then
			doOverride = true
			newTarget = headerElement

			if self.garageListSlider ~= nil then
				self.garageListSlider:onScrollUp()
			end
		end

		return doOverride, newTarget
	end
end

function InGameMenuVehiclesFrame:updateMenuButtons()
	self.menuButtonInfo = {
		{
			inputAction = InputAction.MENU_BACK
		}
	}

	if GS_IS_MOBILE_VERSION and #self.vehicles > 0 then
		table.insert(self.menuButtonInfo, self.sellButton)
	end

	self:setMenuButtonInfoDirty()
end

InGameMenuVehiclesFrame.DATA_BINDING = {
	ICON_OP_HOURS = "iconOperatingHours",
	DAMAGE = "vehicleDamage",
	ICON_DAMAGE = "iconDamage",
	ICON_LEASING = "iconLeasing",
	ICON_VALUE = "iconValue",
	VALUE = "vehicleValue",
	OP_HOURS = "vehicleOperatingHours",
	NAME = "vehicleName",
	AGE = "vehicleAge",
	LEASING = "vehicleLeasing",
	ICON_AGE = "iconAge"
}

function InGameMenuVehiclesFrame:onDataBindVehicleName(element)
	self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.NAME] = element.name
end

function InGameMenuVehiclesFrame:onDataBindAge(element)
	self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.AGE] = element.name
end

function InGameMenuVehiclesFrame:onDataBindAgeIcon(element)
	self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.ICON_AGE] = element.name
end

function InGameMenuVehiclesFrame:onDataBindOperatingHours(element)
	self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.OP_HOURS] = element.name
end

function InGameMenuVehiclesFrame:onDataBindOperatingHoursIcon(element)
	self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.ICON_OP_HOURS] = element.name
end

function InGameMenuVehiclesFrame:onDataBindDamage(element)
	self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.DAMAGE] = element.name
end

function InGameMenuVehiclesFrame:onDataBindDamageIcon(element)
	self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.ICON_DAMAGE] = element.name
end

function InGameMenuVehiclesFrame:onDataBindLeasing(element)
	self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.LEASING] = element.name
end

function InGameMenuVehiclesFrame:onDataBindLeasingIcon(element)
	self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.ICON_LEASING] = element.name
end

function InGameMenuVehiclesFrame:onDataBindValue(element)
	self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.VALUE] = element.name
end

function InGameMenuVehiclesFrame:onDataBindValueIcon(element)
	self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.ICON_VALUE] = element.name
end

function InGameMenuVehiclesFrame:setNameData(dataCell, vehicle)
	local storeItem = self.storeManager:getItemByXMLFilename(vehicle.configFileName)

	if storeItem ~= nil then
		local name = vehicle:getName()
		local brand = self.brandManager:getBrandByIndex(vehicle:getBrand())

		if brand ~= nil then
			name = brand.title .. " " .. name
		end

		dataCell.text = name

		if g_currentMission.controlledVehicle == vehicle.rootVehicle then
			dataCell.overrideProfileName = "ingameMenuVehicleRowVehicleCellActive"
		else
			dataCell.overrideProfileName = "ingameMenuVehicleRowVehicleCell"
		end
	end
end

function InGameMenuVehiclesFrame:getActiveProfile(profile, vehicle)
	local isActive = g_currentMission.controlledVehicle == vehicle.rootVehicle

	if isActive then
		if profile == InGameMenuVehiclesFrame.PROFILE.ATTRIBUTE_CELL_NEUTRAL then
			return InGameMenuVehiclesFrame.PROFILE.ATTRIBUTE_CELL_ACTIVE_NEUTRAL
		else
			return InGameMenuVehiclesFrame.PROFILE.ATTRIBUTE_CELL_ACTIVE_NEGATIVE
		end
	end

	return profile
end

function InGameMenuVehiclesFrame:setAgeData(dataCell, iconCell, vehicle)
	local profile = InGameMenuVehiclesFrame.PROFILE.ATTRIBUTE_CELL_NEUTRAL
	local storeItem = self.storeManager:getItemByXMLFilename(vehicle.configFileName)
	local maxVehicleAge = storeItem.lifetime
	local ageText = Vehicle.getSpecValueAge(nil, vehicle)

	if maxVehicleAge <= vehicle.age then
		profile = InGameMenuVehiclesFrame.PROFILE.ATTRIBUTE_CELL_NEGATIVE
	end

	dataCell.value = vehicle.age
	dataCell.text = ageText
	dataCell.overrideProfileName = self:getActiveProfile(profile, vehicle)
end

function InGameMenuVehiclesFrame:setOperatingHoursData(dataCell, iconCell, vehicle)
	local opHoursValue = 0
	local opHoursText = "-"

	if vehicle.getOperatingTime ~= nil then
		opHoursValue = vehicle:getOperatingTime()
		opHoursText = Vehicle.getSpecValueOperatingTime(nil, vehicle)
	end

	dataCell.value = opHoursValue
	dataCell.text = opHoursText
	dataCell.overrideProfileName = self:getActiveProfile(InGameMenuVehiclesFrame.PROFILE.ATTRIBUTE_CELL_NEUTRAL, vehicle)
end

function InGameMenuVehiclesFrame:setDamageData(dataCell, iconCell, vehicle)
	if dataCell == nil then
		return
	end

	local damageValue = 0
	local damageText = "-"
	local profile = InGameMenuVehiclesFrame.PROFILE.ATTRIBUTE_CELL_NEUTRAL

	if SpecializationUtil.hasSpecialization(Wearable, vehicle.specializations) then
		damageValue = vehicle:getDamageAmount()
		damageText = self.l10n:formatNumber(math.ceil((1 - damageValue) * 100), 0) .. " %"

		if InGameMenuVehiclesFrame.DAMAGE_NEGATIVE_THRESHOLD <= damageValue then
			profile = InGameMenuVehiclesFrame.PROFILE.ATTRIBUTE_CELL_NEGATIVE
		end
	end

	dataCell.value = damageValue
	dataCell.text = damageText
	dataCell.overrideProfileName = self:getActiveProfile(profile, vehicle)
end

function InGameMenuVehiclesFrame:setLeasingData(dataCell, iconCell, vehicle)
	if dataCell == nil then
		return
	end

	local leasingValue = 0
	local leasingText = "-"
	local profile = InGameMenuVehiclesFrame.PROFILE.ATTRIBUTE_CELL_NEUTRAL

	if vehicle.propertyState == Vehicle.PROPERTY_STATE_LEASED then
		leasingValue = vehicle.price * (EconomyManager.DEFAULT_RUNNING_LEASING_FACTOR + EconomyManager.PER_DAY_LEASING_FACTOR)
		leasingText = self.l10n:formatMoney(leasingValue)
	end

	dataCell.value = leasingValue
	dataCell.text = leasingText
	dataCell.overrideProfileName = self:getActiveProfile(profile, vehicle)
end

function InGameMenuVehiclesFrame:setValueData(dataCell, iconCell, vehicle)
	local sellValue = 0
	local sellValueText = "-"
	local profile = InGameMenuVehiclesFrame.PROFILE.ATTRIBUTE_CELL_NEUTRAL

	if vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED then
		sellValue = vehicle:getSellPrice()
		sellValueText = self.l10n:formatMoney(sellValue)

		if sellValue < vehicle.price * InGameMenuVehiclesFrame.SELL_VALUE_NEGATIVE_FACTOR then
			profile = InGameMenuVehiclesFrame.PROFILE.ATTRIBUTE_CELL_NEGATIVE
		end
	end

	dataCell.value = sellValue
	dataCell.text = sellValueText
	dataCell.overrideProfileName = self:getActiveProfile(profile, vehicle)
end

function InGameMenuVehiclesFrame:buildDataRow(vehicle)
	local dataRow = TableElement.DataRow.new(vehicle.id, self.dataBindings)
	local nameCell = dataRow.columnCells[self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.NAME]]
	local ageCell = dataRow.columnCells[self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.AGE]]
	local ageIconCell = dataRow.columnCells[self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.ICON_AGE]]
	local opHoursCell = dataRow.columnCells[self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.OP_HOURS]]
	local opHoursIconCell = dataRow.columnCells[self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.ICON_OP_HOURS]]
	local damageCell = dataRow.columnCells[self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.DAMAGE]]
	local damageIconCell = dataRow.columnCells[self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.ICON_DAMAGE]]
	local leasingCell = dataRow.columnCells[self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.LEASING]]
	local leasingIconCell = dataRow.columnCells[self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.ICON_LEASING]]
	local valueCell = dataRow.columnCells[self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.VALUE]]
	local valueIconCell = dataRow.columnCells[self.dataBindings[InGameMenuVehiclesFrame.DATA_BINDING.ICON_VALUE]]

	self:setNameData(nameCell, vehicle)
	self:setAgeData(ageCell, ageIconCell, vehicle)
	self:setOperatingHoursData(opHoursCell, opHoursIconCell, vehicle)
	self:setDamageData(damageCell, damageIconCell, vehicle)
	self:setLeasingData(leasingCell, leasingIconCell, vehicle)
	self:setValueData(valueCell, valueIconCell, vehicle)

	return dataRow
end

function InGameMenuVehiclesFrame.sortAttributes(sortCell1, sortCell2)
	return sortCell1.value - sortCell2.value
end

function InGameMenuVehiclesFrame:onClickVehicleHeader(element)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	self.vehicleTable:setCustomSortFunction(nil)
	self.vehicleTable:onClickHeader(element)
	self.vehicleTable:updateView(true)
end

function InGameMenuVehiclesFrame:onClickAttributeHeader(element)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	self.vehicleTable:setCustomSortFunction(InGameMenuVehiclesFrame.sortAttributes, true)
	self.vehicleTable:onClickHeader(element)
	self.vehicleTable:updateView(true)
end

function InGameMenuVehiclesFrame:onPageChanged(page, fromPage)
	InGameMenuVehiclesFrame:superClass().onPageChanged(self, page, fromPage)

	local firstIndex = (page - 1) * InGameMenuVehiclesFrame.MAX_NUM_VEHICLES + 1

	self.vehicleTable:scrollTo(firstIndex)
end

function InGameMenuVehiclesFrame:onButtonSell()
	local vehicle = self.vehicles[self.vehicleTable.selectedIndex]

	if vehicle ~= nil then
		local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)

		self.shopController:sell(storeItem, vehicle)
	end
end

function InGameMenuVehiclesFrame:onSelectionChanged()
	if self.vehicleTable ~= nil then
		self:updateMenuButtons()
	end
end

function InGameMenuVehiclesFrame:onVehicleSellEvent()
	self:updateVehicles()
end

function InGameMenuVehiclesFrame:onVehicleBuyEvent()
	self:updateVehicles()
end

InGameMenuVehiclesFrame.SELL_VALUE_NEGATIVE_FACTOR = 0.3
InGameMenuVehiclesFrame.DAMAGE_NEGATIVE_THRESHOLD = 0.8
InGameMenuVehiclesFrame.PROFILE = {
	ATTRIBUTE_ICON_CELL_NEGATIVE = "ingameMenuVehicleRowAttributeIconCellNegative",
	ATTRIBUTE_ICON_CELL_NEUTRAL = "ingameMenuVehicleRowAttributeIconCell",
	ATTRIBUTE_CELL_NEUTRAL = "ingameMenuVehicleRowAttributeCell",
	ATTRIBUTE_CELL_ACTIVE_NEUTRAL = "ingameMenuVehicleRowAttributeCellActive",
	ATTRIBUTE_CELL_ACTIVE_NEGATIVE = "ingameMenuVehicleRowAttributeCellActiveNegative",
	ATTRIBUTE_CELL_NEGATIVE = "ingameMenuVehicleRowAttributeCellNegative"
}
