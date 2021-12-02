WorkshopScreen = {
	CONTROLS = {
		"headerText",
		"vehicleImage",
		"vehicleName",
		"dialogText",
		"priceText",
		"dialogSeparator",
		"dialogInfo",
		"configButton",
		"repairButton",
		"repaintButton",
		"sellButton",
		"operatingHoursText",
		"ageText",
		"conditionBar",
		"paintConditionBar",
		"balanceElement",
		"list",
		"detailBox"
	}
}
local WorkshopScreen_mt = Class(WorkshopScreen, ScreenElement)

function WorkshopScreen.new(target, custom_mt, shopConfigScreen, messageCenter)
	local self = WorkshopScreen:superClass().new(target, custom_mt or WorkshopScreen_mt)
	self.shopConfigScreen = shopConfigScreen

	self:registerControls(WorkshopScreen.CONTROLS)

	self.vehicles = {}

	return self
end

function WorkshopScreen:onOpen()
	WorkshopScreen:superClass().onOpen(self)
	g_messageCenter:subscribe(SellVehicleEvent, self.onVehicleSellEvent, self)
	g_messageCenter:subscribe(MessageType.VEHICLE_REPAIRED, self.onVehicleRepairEvent, self)
	g_messageCenter:subscribe(MessageType.VEHICLE_REPAINTED, self.onVehicleRepaintEvent, self)
end

function WorkshopScreen:onClose()
	WorkshopScreen:superClass().onClose(self)

	self.vehicle = nil

	g_messageCenter:unsubscribeAll(self)
	g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_BUY)
	g_currentMission:showMoneyChange(MoneyType.SHOP_VEHICLE_SELL)
end

function WorkshopScreen:setSellingPoint(sellingPoint, isDealer, isOwnWorkshop, isMobileWorkshop)
	self.owner = sellingPoint
	self.isDealer = isDealer
	self.isOwnWorkshop = isOwnWorkshop
	self.isMobileWorkshop = isMobileWorkshop
end

function WorkshopScreen:setConfigurations(vehicle, buyItem, storeItem, configs, price, licensePlateData)
	self.vehicle = vehicle

	if not buyItem and storeItem ~= nil and configs ~= nil then
		local areChangesMade = false
		local newConfigs = {}

		for configName, configValue in pairs(configs) do
			if self.vehicle.configurations[configName] ~= configValue then
				newConfigs[configName] = configs[configName]
				areChangesMade = true
			end
		end

		if self.vehicle.getLicensePlatesDataIsEqual ~= nil and not self.vehicle:getLicensePlatesDataIsEqual(licensePlateData) then
			areChangesMade = true
		end

		if areChangesMade then
			if not g_currentMission.controlPlayer and g_currentMission.controlledVehicle ~= nil and self.vehicle == g_currentMission.controlledVehicle then
				g_currentMission:onLeaveVehicle()
			end

			g_client:getServerConnection():sendEvent(ChangeVehicleConfigEvent.new(self.vehicle, price, g_currentMission:getFarmId(), newConfigs, licensePlateData))
		end
	else
		self:onClickBack()

		if self.owner ~= nil then
			self.owner:run()
		end
	end
end

function WorkshopScreen:update(dt)
	WorkshopScreen:superClass().update(self, dt)
	self:updateBalanceText()

	if self.vehicle ~= nil then
		if self.vehicle.isDeleted then
			table.removeElement(self.vehicles, self.vehicle)

			self.vehicle = nil

			self.list:reloadData()

			if #self.vehicles == 0 then
				self:setVehicle(nil)
			end
		elseif g_server == nil then
			if self.vehicle.getWearTotalAmount ~= nil then
				self:setStatusBarValue(self.paintConditionBar, 1 - self.vehicle:getWearTotalAmount())
			end

			if self.vehicle.getDamageAmount ~= nil then
				self:setStatusBarValue(self.conditionBar, 1 - self.vehicle:getDamageAmount())
			end
		end
	end
end

function WorkshopScreen:setVehicles(vehicles)
	self.vehicles = vehicles

	self.list:reloadData()

	if #vehicles == 0 then
		self:setVehicle(nil)
	end
end

function WorkshopScreen:setVehicle(vehicle)
	local imageFilename = "dataS/menu/blank.png"
	local name = "unknown"
	local age = 0
	local operatingTime = 0
	self.storeItem = nil
	self.canBeConfigured = false

	if self.isMobileWorkshop then
		self.headerText:setText(g_i18n:getText("ui_mobileWorkshop"))
	elseif self.isOwnWorkshop then
		self.headerText:setText(g_i18n:getText("ui_sellOrCustomizeVehicleTitle"))
	else
		self.headerText:setText(g_i18n:getText("ui_dealer"))
	end

	self.canBeSold = not self.mobileWorkshop

	if vehicle ~= nil then
		self.vehicle = vehicle
		self.storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)

		if self.storeItem ~= nil then
			self.canBeConfigured = self.storeItem.configurations ~= nil and vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED
			self.canBeSold = self.storeItem.canBeSold and not self.mobileWorkshop
			imageFilename = vehicle:getImageFilename()
			name = self.vehicle:getFullName()
		end

		operatingTime = vehicle:getOperatingTime()
		age = vehicle.age

		self.sellButton:setDisabled(false)

		if vehicle.propertyState == Vehicle.PROPERTY_STATE_OWNED then
			if not self.canBeConfigured then
				-- Nothing
			end

			self:setButtonText(g_i18n:getText("button_sell"))

			local sellPrice = math.min(math.floor(vehicle:getSellPrice() * EconomyManager.DIRECT_SELL_MULTIPLIER), vehicle:getPrice())

			self.priceText:setText(g_i18n:formatMoney(sellPrice))
		elseif vehicle.propertyState == Vehicle.PROPERTY_STATE_LEASED then
			self:setButtonText(g_i18n:getText("button_return"))
			self.priceText:setText("-")
		elseif vehicle.propertyState == Vehicle.PROPERTY_STATE_MISSION then
			self.sellButton:setDisabled(true)
			self.priceText:setText("-")
		end

		if vehicle.getWearTotalAmount ~= nil then
			self:setStatusBarValue(self.paintConditionBar, 1 - vehicle:getWearTotalAmount())
		end

		self.paintConditionBar.parent.parent:setVisible(vehicle.getWearTotalAmount ~= nil)

		if vehicle.getDamageAmount ~= nil then
			self:setStatusBarValue(self.conditionBar, 1 - vehicle:getDamageAmount())
		end

		self.conditionBar.parent.parent:setVisible(vehicle.getDamageAmount ~= nil)

		local repairPrice = self.vehicle:getRepairPrice() * EconomyManager.DIRECT_SELL_MULTIPLIER

		if repairPrice >= 1 then
			self.repairButton:setText(string.format("%s (%s)", g_i18n:getText("button_repair"), g_i18n:formatMoney(repairPrice, 0, true, true)))
		else
			self.repairButton:setLocaKey("button_repair")
		end

		self.repairButton:setDisabled(repairPrice < 1)

		local repaintPrice = self.vehicle:getRepaintPrice() * EconomyManager.DIRECT_SELL_MULTIPLIER

		if repaintPrice >= 1 then
			self.repaintButton:setText(string.format("%s (%s)", g_i18n:getText("button_repaint"), g_i18n:formatMoney(repaintPrice, 0, true, true)))
		else
			self.repaintButton:setLocaKey("button_repaint")
		end

		self.repaintButton:setDisabled(repaintPrice < 1 or self.vehicle.propertyState == Vehicle.PROPERTY_STATE_MISSION)
	else
		self.repairButton:setLocaKey("button_repair")
		self.repairButton:setDisabled(true)
		self.repaintButton:setLocaKey("button_repaint")
		self.repaintButton:setDisabled(true)
	end

	self.configButton:setDisabled(not self.canBeConfigured)
	self.sellButton:setDisabled(vehicle == nil or self.isOwnWorkshop or self.vehicle.propertyState == Vehicle.PROPERTY_STATE_MISSION or not self.canBeSold)
	self.sellButton:setVisible(vehicle ~= nil and not self.isOwnWorkshop and self.vehicle.propertyState ~= Vehicle.PROPERTY_STATE_MISSION)
	self.repaintButton:setVisible(not self.isOwnWorkshop)
	self.dialogInfo:setVisible(vehicle == nil)
	self.detailBox:setVisible(vehicle ~= nil)
	self.vehicleImage:setImageFilename(imageFilename)
	self.vehicleName:setText(name)

	local minutes = operatingTime / 60000
	local hours = math.floor(minutes / 60)
	minutes = math.floor((minutes - hours * 60) / 6) * 10

	self.operatingHoursText:setText(string.format(g_i18n:getText("shop_operatingTime"), hours, minutes))
	self.ageText:setText(string.format(g_i18n:getText("shop_age"), string.format("%d", age)))
	self.sellButton.parent:invalidateLayout()
end

function WorkshopScreen:setButtonText(text)
	self.sellButton:setText(text)
end

function WorkshopScreen:setStatusBarValue(bar, value)
	if math.abs((bar.lastStatusBarValue or -1) - value) > 0.01 then
		local fullWidth = bar.parent.size[1] - bar.margin[1] * 2
		local minSize = 0

		if bar.startSize ~= nil then
			minSize = bar.startSize[1] + bar.endSize[1]
		end

		if value <= 0.1 then
			bar:applyProfile("workshopStatusBarDanger")
		elseif value <= 0.4 then
			bar:applyProfile("workshopStatusBarWarning")
		else
			bar:applyProfile("workshopStatusBar")
		end

		bar:setSize(math.max(minSize, fullWidth * math.min(value, 1)), nil)

		bar.lastStatusBarValue = value
	end
end

function WorkshopScreen:updateBalanceText()
	local balance = g_currentMission ~= nil and g_currentMission:getMoney() or 0
	self.lastBalance = balance

	self.balanceElement:setValue(balance)

	if balance > 0 then
		self.balanceElement:applyProfile(AnimalScreen.PROFILE.POSITIVE_BALANCE)
	else
		self.balanceElement:applyProfile(AnimalScreen.PROFILE.NEGATIVE_BALANCE)
	end
end

function WorkshopScreen:onClickBack(forceBack)
	WorkshopScreen:superClass().onClickBack(self)

	self.vehicle = nil
	self.vehicles = {}

	self:changeScreen(nil)
end

function WorkshopScreen:onClickRepair()
	if self.vehicle ~= nil and self.vehicle:getRepairPrice(true) >= 1 then
		g_gui:showYesNoDialog({
			text = string.format(g_i18n:getText("ui_repairDialog"), g_i18n:formatMoney(self.vehicle:getRepairPrice(true))),
			callback = self.onYesNoRepairDialog,
			target = self,
			yesSound = GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH
		})

		return true
	else
		return false
	end
end

function WorkshopScreen:onClickRepaint()
	if self.vehicle ~= nil and self.vehicle:getRepaintPrice() >= 1 then
		g_gui:showYesNoDialog({
			text = string.format(g_i18n:getText("ui_repaintDialog"), g_i18n:formatMoney(self.vehicle:getRepaintPrice())),
			callback = self.onYesNoRepaintDialog,
			target = self,
			yesSound = GuiSoundPlayer.SOUND_SAMPLES.CONFIG_SPRAY
		})

		return true
	else
		return false
	end
end

function WorkshopScreen:onClickConfigure()
	if self.canBeConfigured then
		local changePrice = EconomyManager.CONFIG_CHANGE_PRICE

		if self.isOwnWorkshop then
			changePrice = 0
		end

		local vehicle = self.vehicle
		local storeItem = self.storeItem

		self:changeScreen(ShopConfigScreen, nil, WorkshopScreen)
		self.shopConfigScreen:setReturnScreen(self.name)
		self.shopConfigScreen:setStoreItem(storeItem, vehicle, nil, changePrice)
		self.shopConfigScreen:setCallbacks(self.setConfigurations, self)

		return false
	end

	return true
end

function WorkshopScreen:onClickSell()
	if self.vehicle ~= nil and not self.isOwnWorkshop and self.vehicle.propertyState ~= Vehicle.PROPERTY_STATE_MISSION and self.canBeSold then
		local l10nString = "ui_youWantToSellVehicle"

		g_gui:showYesNoDialog({
			text = g_i18n:getText(l10nString),
			callback = self.sellVehicleYesNo,
			target = self
		})

		return false
	end

	return true
end

function WorkshopScreen:getNumberOfItemsInSection(list, section)
	return #self.vehicles
end

function WorkshopScreen:populateCellForItemInSection(list, section, index, cell)
	local vehicle = self.vehicles[index]

	cell:getAttribute("icon"):setImageFilename(vehicle:getImageFilename())
	cell:getAttribute("name"):setText(vehicle:getName())

	local brand = g_brandManager:getBrandByIndex(vehicle:getBrand())

	if brand ~= nil then
		cell:getAttribute("brand"):setText(brand.title)
	else
		cell:getAttribute("brand"):setText("")
	end
end

function WorkshopScreen:onListSelectionChanged(list, section, index)
	self:setVehicle(self.vehicles[index])
end

function WorkshopScreen:onInfoDialogCallback()
end

function WorkshopScreen:onYesNoRepaintDialog(yes)
	if yes then
		g_client:getServerConnection():sendEvent(WearableRepaintEvent.new(self.vehicle, true))
	end
end

function WorkshopScreen:onYesNoRepairDialog(yes)
	if yes then
		g_client:getServerConnection():sendEvent(WearableRepairEvent.new(self.vehicle, true))
	end
end

function WorkshopScreen:sellVehicleYesNo(yes)
	if yes then
		g_client:getServerConnection():sendEvent(SellVehicleEvent.new(self.vehicle, EconomyManager.DIRECT_SELL_MULTIPLIER, true))

		self.vehicle = nil
	end
end

function WorkshopScreen:onVehicleSold(sellPrice, isOwned, ownerFarmId)
	local text = g_i18n:getText("shop_messageSoldVehicle")

	if not isOwned then
		text = g_i18n:getText("shop_messageReturnedVehicle")
	end

	g_gui:showInfoDialog({
		text = text,
		dialogType = DialogElement.TYPE_INFO,
		callback = self.onInfoDialogCallback,
		target = self
	})
end

function WorkshopScreen:onVehicleSellFailed(isOwned, errorCode)
	local text = nil

	if isOwned then
		if errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
			text = g_i18n:getText("shop_messageNoPermissionToSellVehicleText")
		elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
			text = g_i18n:getText("shop_messageSellVehicleInUse")
		else
			text = g_i18n:getText("shop_messageFailedToSellVehicle")
		end
	elseif errorCode == SellVehicleEvent.SELL_NO_PERMISSION then
		text = g_i18n:getText("shop_messageNoPermissionToReturnVehicleText")
	elseif errorCode == SellVehicleEvent.SELL_VEHICLE_IN_USE then
		text = g_i18n:getText("shop_messageReturnVehicleInUse")
	else
		text = g_i18n:getText("shop_messageFailedToReturnVehicle")
	end

	g_gui:showInfoDialog({
		text = text
	})
end

function WorkshopScreen:onVehicleChanged(success)
	if success then
		g_gui:showInfoDialog({
			text = g_i18n:getText("shop_messageConfigurationChanged"),
			dialogType = DialogElement.TYPE_INFO,
			callback = self.onInfoDialogCallback,
			target = self
		})
	else
		g_gui:showInfoDialog({
			text = g_i18n:getText("shop_messageConfigurationChangeFailed"),
			callback = self.onInfoDialogCallback,
			target = self
		})
	end
end

function WorkshopScreen:onVehicleRepairEvent(vehicle, atSellingPoint)
	if vehicle == self.vehicle then
		self:setVehicle(vehicle)
	end
end

function WorkshopScreen:onVehicleRepaintEvent(vehicle, atSellingPoint)
	if vehicle == self.vehicle then
		self:setVehicle(vehicle)
	end
end

function WorkshopScreen:onVehicleSellEvent(isDirectSell, errorCode, sellPrice, isOwned, ownerFarmId)
	if not isDirectSell then
		return
	end

	if errorCode == SellVehicleEvent.SELL_SUCCESS then
		self:onVehicleSold(sellPrice, isOwned, ownerFarmId)
	else
		self:onVehicleSellFailed(isOwned, errorCode)
	end
end
