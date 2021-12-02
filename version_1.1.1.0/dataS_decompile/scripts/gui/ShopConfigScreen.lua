ShopConfigScreen = {}
local ShopConfigScreen_mt = Class(ShopConfigScreen, ScreenElement)
ShopConfigScreen.CONTROLS = {
	"shopMoney",
	"shopConfigBrandIcon",
	"shopConfigItemName",
	"buttonsPanel",
	"configurationLayout",
	"configurationItemTemplate",
	"configurationItemTemplateLarge",
	"configurationsTitle",
	"configurationsBox",
	"configSliderBox",
	"configSlider",
	"basePriceText",
	"upgradesPriceText",
	"totalPriceText",
	"attributesLayout",
	"attributeItem",
	"loadingAnimation",
	"leaseButton",
	"buyButton",
	"configButton",
	"zoomGlyph",
	"lookGlyph",
	CONTENT = "shopConfigContent"
}
ShopConfigScreen.INPUT_CONTEXT_NAME = "MENU_SHOP_CONFIG"
ShopConfigScreen.FADE_TEXTURE_PATH = "dataS/scripts/shared/graph_pixel.png"
ShopConfigScreen.WORKSHOP_PATH = "$data/maps/textures/shared/uiStore.i3d"
ShopConfigScreen.LICENSE_PLATE_PATH = "dataS/menu/licensePlate/creationBox.i3d"
ShopConfigScreen.NEAR_CLIP_DISTANCE = 0.2
ShopConfigScreen.MAX_CAMERA_HEIGHT = 10
ShopConfigScreen.MAX_CAMERA_DISTANCE = 17.5
ShopConfigScreen.CAMERA_MAX_DISTANCE_FACTOR = 3
ShopConfigScreen.DEFAULT_PREVIEW_SIZE = 5.2
ShopConfigScreen.CAMERA_MIN_DISTANCE_FACTOR = 0.8
ShopConfigScreen.CAMERA_MIN_DISTANCE_TO_X_OFFSET_FACTOR = 0.015
ShopConfigScreen.FAR_BLUR_END_DISTANCE = 100
ShopConfigScreen.INITIAL_CAMERA_ROTATION = {
	13.5,
	-135,
	0
}
ShopConfigScreen.MOUSE_SPEED_MULTIPLIER = 2
ShopConfigScreen.MIN_MOUSE_DRAG_INPUT = 0.02 * InputBinding.MOUSE_MOVE_BASE_FACTOR
ShopConfigScreen.NO_VEHICLE = {
	delete = function ()
	end
}
ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG = "motor"
ShopConfigScreen.STORE_ITEM_FILL_UNIT_CONFIG = "fillUnit"

local function NO_CALLBACK()
end

function ShopConfigScreen.new(shopController, messageCenter, l10n, i3dManager, brandManager, configurationManager, vehicleTypeManager, inputManager, inputDisplayManager)
	local self = ScreenElement.new(nil, ShopConfigScreen_mt)
	self.loadRequestIdWorkshop = nil
	self.loadRequestIdLicensePlateBox = nil
	self.currentMission = nil
	self.shopController = shopController
	self.l10n = l10n
	self.i3dManager = i3dManager
	self.brandManager = brandManager
	self.configurationManager = configurationManager
	self.vehicleTypeManager = vehicleTypeManager
	self.inputManager = inputManager
	self.inputDisplayManager = inputDisplayManager

	self:registerControls(ShopConfigScreen.CONTROLS)

	self.fadeOverlay = Overlay.new(ShopConfigScreen.FADE_TEXTURE_PATH, 0, 0, 1, 1)

	self.fadeOverlay:setColor(0, 0, 0, 0)

	self.fadeInAnimation = TweenSequence.NO_SEQUENCE
	self.fadeOutAnimation = TweenSequence.NO_SEQUENCE
	self.rotateInputGlyph = nil
	self.zoomInputGlyph = nil
	self.lastInputHelpMode = nil

	self:createInputGlyphs()

	self.configBasePrice = 0
	self.totalPrice = 0
	self.initialLeasingCosts = 0
	self.lastMoney = 0
	self.displayableOptionCount = 0
	self.displayableColorCount = 0
	self.callbackFunc = nil
	self.requestExitCallback = NO_CALLBACK
	self.workshopWorldPosition = {
		0,
		0,
		0
	}
	self.workshopRootNode = nil
	self.workshopNode = nil
	self.limitRotXDelta = 0
	self.cameraDistance = 10
	self.cameraMaxDistance = 20
	self.cameraMinDistance = 1
	self.zoomTarget = self.cameraDistance
	self.rotZ = 0
	self.rotY = 0
	self.rotX = 0
	self.rotMaxX = MathUtil.degToRad(70)
	self.rotMinX = 0
	self.focusY = 0
	self.rotateNode = nil
	self.cameraNode = nil
	self.previousCamera = nil

	self:createCamera()
	self:resetCamera()

	self.isLoadingInitial = false
	self.previewVehicleSize = 0
	self.previewVehicles = {}
	self.previousVehicles = {}
	self.loadingCount = 0
	self.loadedCount = 0
	self.loadingDelayFrames = 0
	self.loadingDelayTime = 0
	self.inputHorizontal = 0
	self.inputVertical = 0
	self.inputZoom = 0
	self.eventIdUpDownController = ""
	self.eventIdLeftRightController = ""
	self.eventIdUpDownMouse = ""
	self.eventIdLeftRightMouse = ""
	self.inputDragging = false
	self.isDragging = false
	self.accumDraggingInput = 0
	self.lastInputMode = inputManager:getLastInputMode()
	self.lastInputHelpMode = inputManager:getInputHelpMode()
	self.currentConfigSet = 1

	self:createFadeAnimations()
	messageCenter:subscribe(BuyVehicleEvent, self.onVehicleBought, self)
	messageCenter:subscribe(MessageType.STORE_ITEMS_RELOADED, self.onStoreItemsReloaded, self)

	self.openCounter = 0

	addConsoleCommand("gsShopUIToggle", "Toggle shop config screen UI visiblity", "consoleCommandUIToggle", self)

	return self
end

function ShopConfigScreen:createInputGlyphs()
	local iconWidth, iconHeight = getNormalizedScreenValues(unpack(ShopConfigScreen.SIZE.INPUT_GLYPH))
	self.rotateInputGlyph = InputGlyphElement.new(self.inputDisplayManager, iconWidth, iconHeight)

	self.rotateInputGlyph:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_RIGHT)

	self.zoomInputGlyph = InputGlyphElement.new(self.inputDisplayManager, iconWidth, iconHeight)

	self.zoomInputGlyph:setAlignment(Overlay.ALIGN_VERTICAL_MIDDLE, Overlay.ALIGN_HORIZONTAL_RIGHT)
end

function ShopConfigScreen:createFadeAnimations()
	local fadeInAnimation = TweenSequence.new(self)
	local fadeIn = Tween.new(self.fadeScreen, 1, 0, 300)

	fadeInAnimation:addTween(fadeIn)

	self.fadeInAnimation = fadeInAnimation
	local fadeOutAnimation = TweenSequence.new(self)
	local fadeOut = Tween.new(self.fadeScreen, 0, 1, 300)

	fadeOutAnimation:addTween(fadeOut)

	self.fadeOutAnimation = fadeOutAnimation
end

function ShopConfigScreen:fadeScreen(alpha)
	self.fadeOverlay:setColor(nil, , , alpha)
end

function ShopConfigScreen:createWorkshop(assetPath, posX, posY, posZ)
	self.workshopWorldPosition = {
		posX,
		posY,
		posZ
	}
	self.workshopRootNode = createTransformGroup("ShopConfigWorkshop")

	link(getRootNode(), self.workshopRootNode)
	setTranslation(self.workshopRootNode, posX, posY, posZ)
	setVisibility(self.workshopRootNode, false)

	self.loadRequestIdWorkshop = self.i3dManager:loadI3DFileAsync(assetPath, false, true, self.onWorkshopLoaded, self, nil)
	self.loadRequestIdLicensePlateBox = self.i3dManager:loadI3DFileAsync(ShopConfigScreen.LICENSE_PLATE_PATH, false, true, self.onLicensePlateBoxLoaded, self, nil)
end

function ShopConfigScreen:onWorkshopLoaded(node, failedReason, args)
	if node ~= 0 then
		self.loadRequestIdWorkshop = nil
		self.workshopNode = node

		removeFromPhysics(self.workshopNode)
		setTranslation(self.workshopNode, 0, 0, 0)
		link(self.workshopRootNode, self.workshopNode)
		addToPhysics(self.workshopNode)

		self.workshopColorNodes = {}

		I3DUtil.getNodesByShaderParam(node, "colorScale", self.workshopColorNodes, true)

		if #self.workshopColorNodes > 0 then
			self.workshopDefaultColor = {
				getShaderParameter(self.workshopColorNodes[1], "colorScale")
			}
		end
	end
end

function ShopConfigScreen:onLicensePlateBoxLoaded(node, failedReason, args)
	if node ~= 0 then
		self.loadRequestIdLicensePlateBox = nil
		self.creationBox = node

		setVisibility(node, false)
	end
end

function ShopConfigScreen:createCamera()
	self.cameraNode = createCamera("VehicleConfigCamera", math.rad(60), ShopConfigScreen.NEAR_CLIP_DISTANCE, 100)

	setTranslation(self.cameraNode, 0, 0, -self.cameraDistance)
	setRotation(self.cameraNode, 0, math.rad(180), 0)

	self.rotateNode = createTransformGroup("VehicleConfigCameraTarget")

	link(getRootNode(), self.rotateNode)
	setRotation(self.rotateNode, 0, math.rad(180), 0)
	setTranslation(self.rotateNode, 0, 0, 0)
	link(self.rotateNode, self.cameraNode)
end

function ShopConfigScreen:resetCamera()
	local rx, ry, rz = unpack(ShopConfigScreen.INITIAL_CAMERA_ROTATION)
	self.rotZ = MathUtil.degToRad(rz)
	self.rotY = MathUtil.degToRad(ry)
	self.rotX = MathUtil.degToRad(rx)
	self.cameraDistance = (self.cameraMinDistance + self.cameraMaxDistance) * 0.5
end

function ShopConfigScreen:delete()
	self.rotateInputGlyph:delete()
	self.zoomInputGlyph:delete()
	self.fadeOverlay:delete()
	self.configurationItemTemplate:delete()
	self.configurationItemTemplateLarge:delete()
	self.attributeItem:delete()
	self:deletePreviewVehicles()

	if self.workshopNode ~= nil then
		delete(self.workshopNode)

		self.workshopNode = nil
	end

	if self.creationBox ~= nil then
		delete(self.creationBox)

		self.creationBox = nil
	end

	if self.workshopRootNode ~= nil then
		delete(self.workshopRootNode)

		self.workshopRootNode = nil
	end

	if self.rotateNode ~= nil then
		delete(self.rotateNode)
	end

	if self.loadRequestIdWorkshop ~= nil then
		self.i3dManager:cancelStreamI3DFile(self.loadRequestIdWorkshop)
	end

	if self.loadRequestIdLicensePlateBox ~= nil then
		self.i3dManager:cancelStreamI3DFile(self.loadRequestIdLicensePlateBox)
	end

	removeConsoleCommand("gsShopUIToggle")
	ShopConfigScreen:superClass().delete(self)
end

function ShopConfigScreen:onGuiSetupFinished()
	ShopConfigScreen:superClass().onGuiSetupFinished(self)
	self.configurationItemTemplate:unlinkElement()
	self.configurationItemTemplateLarge:unlinkElement()
	self.attributeItem:unlinkElement()
end

function ShopConfigScreen:updateBalanceText()
	local money = self.currentMission:getMoney()
	self.lastMoney = money

	self.shopMoney:setValue(money)

	if money > 0 then
		self.shopMoney:applyProfile(ShopConfigScreen.GUI_PROFILE.SHOP_MONEY)
	else
		self.shopMoney:applyProfile(ShopConfigScreen.GUI_PROFILE.SHOP_MONEY_NEGATIVE)
	end
end

function ShopConfigScreen:processStoreItemUpkeep(storeItem, realItem, saleItem)
	local dailyUpkeep = 0

	if storeItem.dailyUpkeep ~= nil then
		dailyUpkeep = storeItem.dailyUpkeep

		for name, id in pairs(self.configurations) do
			local configs = storeItem.configurations[name]

			if configs ~= nil and configs[id] ~= nil then
				dailyUpkeep = dailyUpkeep + configs[id].dailyUpkeep
			end
		end
	end

	return dailyUpkeep
end

function ShopConfigScreen:processStoreItemPowerOutput(storeItem, realItem, saleItem)
	local power = 0

	if storeItem.specs ~= nil and storeItem.specs.power ~= nil then
		power = storeItem.specs.power

		if self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil and storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil then
			local configId = self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG]
			power = Utils.getNoNil(storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG][configId].power, power)
		end
	end

	return power
end

function ShopConfigScreen:processStoreItemFuelCapacity(storeItem, realItem, saleItem, fuelFillType)
	local fuel = 0

	if storeItem.specs ~= nil then
		local spec = storeItem.specs.fuel or storeItem.specs.eletricCharge

		if spec ~= nil then
			local consumerIndex = 1

			if self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil and storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil then
				local motorConfigId = self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG]
				consumerIndex = Utils.getNoNil(storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG][motorConfigId].consumerConfigurationIndex, consumerIndex)
			end

			local fuelFillUnitIndex = 0
			local consumerConfiguration = spec.consumers[consumerIndex]

			if consumerConfiguration ~= nil then
				for _, unitConsumers in ipairs(consumerConfiguration) do
					if g_fillTypeManager:getFillTypeIndexByName(unitConsumers.fillType) == fuelFillType then
						fuelFillUnitIndex = unitConsumers.fillUnitIndex

						if unitConsumers.capacity ~= nil then
							return unitConsumers.capacity
						end

						break
					end
				end
			end

			local fillUnitConfigId = 1

			if self.configurations[ShopConfigScreen.STORE_ITEM_FILL_UNIT_CONFIG] ~= nil and storeItem.configurations[ShopConfigScreen.STORE_ITEM_FILL_UNIT_CONFIG] ~= nil then
				fillUnitConfigId = self.configurations[ShopConfigScreen.STORE_ITEM_FILL_UNIT_CONFIG]
			end

			if spec.fillUnits[fillUnitConfigId] ~= nil then
				local fuelFillUnit = spec.fillUnits[fillUnitConfigId][fuelFillUnitIndex]

				if fuelFillUnit ~= nil then
					fuel = math.max(fuelFillUnit.capacity, fuel or 0)
				end
			end
		end
	end

	return fuel
end

function ShopConfigScreen:processStoreItemMaxSpeed(storeItem, realItem, saleItem)
	local maxSpeed = 0

	if storeItem.specs ~= nil and storeItem.specs.maxSpeed ~= nil then
		maxSpeed = storeItem.specs.maxSpeed

		if self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil and storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG] ~= nil then
			local configId = self.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG]
			maxSpeed = Utils.getNoNil(storeItem.configurations[ShopConfigScreen.STORE_ITEM_MOTOR_CONFIG][configId].maxSpeed, maxSpeed)
		end
	end

	return maxSpeed
end

function ShopConfigScreen:processStoreItemCapacity(storeItem, realItem, saleItem)
	if storeItem.specs ~= nil and storeItem.specs.capacity ~= nil then
		return FillUnit.getSpecValueCapacity(storeItem, realItem, self.configurations, saleItem, true)
	else
		return 0, nil
	end
end

function ShopConfigScreen:processStoreItemWeight(storeItem, realItem, saleItem)
	if storeItem.specs ~= nil and storeItem.specs.weight ~= nil then
		local baseWeight = Vehicle.getSpecValueWeight(storeItem, realItem, nil, saleItem, true)
		local additionalWeight = 0

		if storeItem.specs.additionalWeight ~= nil then
			additionalWeight = Vehicle.getSpecValueAdditionalWeight(storeItem, realItem, nil, saleItem, true)
		end

		return baseWeight, additionalWeight
	else
		return 0, 0
	end
end

function ShopConfigScreen:processStoreItemWorkingWidth(storeItem, realItem, saleItem)
	if storeItem.specs ~= nil then
		if storeItem.specs.workingWidth ~= nil then
			return storeItem.specs.workingWidth
		elseif storeItem.specs.workingWidthConfig ~= nil then
			return Vehicle.getSpecValueWorkingWidthConfig(storeItem, realItem, self.configurations, saleItem, true) or 0
		end
	end

	return 0
end

function ShopConfigScreen:processStoreItemWorkingSpeed(storeItem, realItem, saleItem)
	if storeItem.specs ~= nil and storeItem.specs.speedLimit ~= nil then
		return storeItem.specs.speedLimit
	else
		return 0
	end
end

function ShopConfigScreen:processStoreItemPowerNeeded(storeItem, realItem, saleItem)
	if storeItem.specs ~= nil and storeItem.specs.neededPower ~= nil then
		local configValue = storeItem.specs.neededPower.config[self.configurations.powerConsumer]

		return configValue or storeItem.specs.neededPower.base or 0
	else
		return 0
	end
end

function ShopConfigScreen:processStoreItemBalerBaleSize(storeItem)
	if storeItem.specs ~= nil then
		local balerBaleSize = storeItem.specs.balerBaleSizeRound or storeItem.specs.balerBaleSizeSquare

		if balerBaleSize ~= nil then
			local size = Baler.getSpecValueBaleSize(storeItem, nil, , , false, false, balerBaleSize.isRoundBaler)

			if balerBaleSize.isRoundBaler then
				return size, ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND
			else
				return size, ShopConfigScreen.GUI_PROFILE.BALE_SIZE_SQUARE
			end
		end
	else
		return ""
	end
end

function ShopConfigScreen:processStoreItemBaleWrapperBaleSize(storeItem)
	if storeItem.specs ~= nil then
		local roundBaleSize = BaleWrapper.getSpecValueBaleSizeRound(storeItem, nil, , , false, false)
		local squareBaleSize = BaleWrapper.getSpecValueBaleSizeSquare(storeItem, nil, , , false, false)

		if roundBaleSize == nil and squareBaleSize == nil then
			roundBaleSize = InlineWrapper.getSpecValueBaleSizeRound(storeItem, nil, , , false, false)
			squareBaleSize = InlineWrapper.getSpecValueBaleSizeSquare(storeItem, nil, , , false, false)
		end

		return roundBaleSize, squareBaleSize
	end
end

function ShopConfigScreen:processStoreItemBaleLoaderBaleSize(storeItem)
	if storeItem.specs ~= nil then
		local roundBaleSize = BaleLoader.getSpecValueBaleSizeRound(storeItem, nil, , , false, false)
		local squareBaleSize = BaleLoader.getSpecValueBaleSizeSquare(storeItem, nil, , , false, false)

		return roundBaleSize, squareBaleSize
	end
end

function ShopConfigScreen:processAttributeData(storeItem, vehicle, saleItem)
	local dailyUpkeep = 0
	local powerOutput = 0
	local transmissionName = nil
	local fuelCapacity = 0
	local electricCapacity = 0
	local methaneCapacity = 0
	local defCapacity = 0
	local maxSpeed = 0
	local capacity = 0
	local capacityUnit = nil
	local weight = 0
	local additionalWeight = 0
	local workingWidth = 0
	local workingSpeed = 0
	local powerNeeded = 0
	local wheelNames = ""
	local baleSize = ""
	local baleSizeProfile = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND
	local wrapperBaleSizeRound, wrapperBaleSizeSquare, loaderBaleSizeRound, loaderBaleSizeSquare, storeItems = nil

	if storeItem.bundleInfo == nil then
		storeItems = {
			storeItem
		}
	else
		storeItems = {}

		for i = 1, #storeItem.bundleInfo.bundleItems do
			table.insert(storeItems, storeItem.bundleInfo.bundleItems[i].item)
		end
	end

	for _, item in ipairs(storeItems) do
		StoreItemUtil.loadSpecsFromXML(item)

		dailyUpkeep = dailyUpkeep + self:processStoreItemUpkeep(item, vehicle, saleItem)
		powerOutput = powerOutput + self:processStoreItemPowerOutput(item, vehicle, saleItem)
		transmissionName = transmissionName or Motorized.getSpecValueTransmission(storeItem, vehicle, nil, saleItem)
		fuelCapacity = fuelCapacity + self:processStoreItemFuelCapacity(item, vehicle, saleItem, FillType.DIESEL)
		electricCapacity = electricCapacity + self:processStoreItemFuelCapacity(item, vehicle, saleItem, FillType.ELECTRICCHARGE)
		methaneCapacity = methaneCapacity + self:processStoreItemFuelCapacity(item, vehicle, saleItem, FillType.METHANE)
		defCapacity = defCapacity + self:processStoreItemFuelCapacity(item, vehicle, saleItem, FillType.DEF)
		local itemCapacity, itemCapacityUnit = self:processStoreItemCapacity(item, vehicle, saleItem)

		if capacityUnit ~= nil and itemCapacityUnit ~= nil and itemCapacityUnit ~= capacityUnit then
			print("Warning: Bundled store items have different fill capacity units. Check " .. tostring(storeItem.xmlFilename))
		end

		capacityUnit = capacityUnit or itemCapacityUnit
		capacity = capacity + itemCapacity
		local itemWeight, itemAdditionalWeight = self:processStoreItemWeight(item, vehicle, saleItem)
		additionalWeight = additionalWeight + (itemAdditionalWeight or 0)
		weight = weight + (itemWeight or 0)
		workingWidth = math.max(workingWidth, self:processStoreItemWorkingWidth(item, vehicle, saleItem))
		workingSpeed = math.max(workingSpeed, self:processStoreItemWorkingSpeed(item, vehicle, saleItem))
		maxSpeed = math.max(maxSpeed, self:processStoreItemMaxSpeed(item, vehicle, saleItem))
		powerNeeded = powerNeeded + self:processStoreItemPowerNeeded(item, vehicle, saleItem)
		local itemBaleSize, itemBaleSizeProfile = self:processStoreItemBalerBaleSize(item)

		if baleSize == "" then
			baleSize = itemBaleSize
			baleSizeProfile = itemBaleSizeProfile
		end

		local roundSize, squareSize = self:processStoreItemBaleWrapperBaleSize(item)
		wrapperBaleSizeRound = wrapperBaleSizeRound or roundSize
		wrapperBaleSizeSquare = wrapperBaleSizeSquare or squareSize
		roundSize, squareSize = self:processStoreItemBaleLoaderBaleSize(item)
		loaderBaleSizeRound = loaderBaleSizeRound or roundSize
		loaderBaleSizeSquare = loaderBaleSizeSquare or squareSize
	end

	if vehicle ~= nil then
		for _, name in ipairs(Wheels.getTireNames(vehicle)) do
			if wheelNames ~= "" then
				wheelNames = wheelNames .. " / "
			end

			wheelNames = wheelNames .. name
		end
	end

	local values = {}

	if dailyUpkeep ~= 0 then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.MAINTENANCE_COST,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.MAINTENANCE_COST), self.l10n:formatMoney(dailyUpkeep, 2))
		})
	end

	if powerOutput ~= 0 then
		local hp, kw = self.l10n:getPower(powerOutput)

		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.POWER,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.POWER), MathUtil.round(kw), MathUtil.round(hp))
		})
	end

	if transmissionName ~= nil then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.TRANSMISSION,
			value = transmissionName
		})
	end

	if fuelCapacity ~= 0 then
		if defCapacity == 0 then
			table.insert(values, {
				profile = ShopConfigScreen.GUI_PROFILE.FUEL,
				value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL), fuelCapacity, self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER))
			})
		elseif defCapacity > 0 then
			table.insert(values, {
				profile = ShopConfigScreen.GUI_PROFILE.FUEL,
				value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL_DEF), fuelCapacity, self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER), defCapacity, self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_LITER), self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.DEF_SHORT))
			})
		end
	elseif electricCapacity ~= 0 then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.ELECTRICCHARGE,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL), electricCapacity, self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_KW))
		})
	elseif methaneCapacity ~= 0 then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.METHANE,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.FUEL), methaneCapacity, self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.UNIT_KG))
		})
	end

	if maxSpeed ~= 0 then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.MAX_SPEED,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.MAX_SPEED), string.format("%1d", self.l10n:getSpeed(maxSpeed)), self.l10n:getSpeedMeasuringUnit())
		})
	end

	if capacity ~= 0 and capacityUnit ~= nil then
		if capacityUnit:sub(1, 6) == "$l10n_" then
			capacityUnit = capacityUnit:sub(7)
		end

		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.CAPACITY,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.CAPACITY), capacity, self.l10n:getText(capacityUnit))
		})
	end

	if weight ~= 0 then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.WEIGHT,
			value = g_i18n:formatMass(weight)
		})
	end

	if additionalWeight ~= 0 then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.ADDITIONAL_WEIGHT,
			value = g_i18n:formatMass(additionalWeight)
		})
	end

	if powerNeeded ~= 0 then
		local hp, kw = self.l10n:getPower(powerNeeded)

		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.POWER_REQUIREMENT,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.POWER_REQUIREMENT), MathUtil.round(kw), MathUtil.round(hp))
		})
	end

	if workingWidth ~= 0 then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.WORKING_WIDTH,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.WORKING_WIDTH), g_i18n:formatNumber(workingWidth, 1, true))
		})
	end

	if workingSpeed ~= 0 then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.WORKING_SPEED,
			value = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.WORKING_SPEED), string.format("%1d", self.l10n:getSpeed(workingSpeed)), self.l10n:getSpeedMeasuringUnit())
		})
	end

	if wheelNames ~= "" then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.WHEELS,
			value = wheelNames
		})
	end

	if baleSize ~= nil and baleSize ~= "" then
		table.insert(values, {
			profile = baleSizeProfile,
			value = baleSize
		})
	end

	if wrapperBaleSizeRound ~= nil then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.BALEWRAPPER_SIZE_ROUND,
			value = wrapperBaleSizeRound
		})
	end

	if wrapperBaleSizeSquare ~= nil then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.BALEWRAPPER_SIZE_SQUARE,
			value = wrapperBaleSizeSquare
		})
	end

	if loaderBaleSizeRound ~= nil then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_ROUND,
			value = loaderBaleSizeRound
		})
	end

	if loaderBaleSizeSquare ~= nil then
		table.insert(values, {
			profile = ShopConfigScreen.GUI_PROFILE.BALE_SIZE_SQUARE,
			value = loaderBaleSizeSquare
		})
	end

	for _ = 1, #self.attributesLayout.elements do
		self.attributesLayout.elements[1]:delete()
	end

	for i, item in ipairs(values) do
		local itemElement = self.attributeItem:clone(self.attributesLayout)
		local iconElement = itemElement:getDescendantByName("icon")
		local textElement = itemElement:getDescendantByName("text")

		itemElement:reloadFocusHandling(true)
		iconElement:applyProfile(item.profile)
		textElement:setText(item.value)
	end

	self.attributesLayout:invalidateLayout()
end

function ShopConfigScreen:getConfigurationCostsAndChanges(storeItem, vehicle, saleItem)
	local basePrice = 0
	local upgradePrice = 0
	local hasChanges = false

	if vehicle ~= nil then
		for name, id in pairs(self.configurations) do
			if vehicle.configurations[name] ~= id then
				hasChanges = true

				if not ConfigurationUtil.hasBoughtConfiguration(self.vehicle, name, id) then
					local configs = storeItem.configurations[name]
					upgradePrice = upgradePrice + configs[id].price
				end
			end
		end

		if self.vehicle.getLicensePlatesDataIsEqual ~= nil and not self.vehicle:getLicensePlatesDataIsEqual(self.licensePlateData) then
			hasChanges = true
		end
	elseif saleItem ~= nil then
		hasChanges = true
		basePrice, upgradePrice = self.currentMission.economyManager:getBuyPrice(storeItem, self.configurations, saleItem)
		basePrice = basePrice - upgradePrice
	elseif storeItem ~= nil then
		hasChanges = true
		basePrice, upgradePrice = self.currentMission.economyManager:getBuyPrice(storeItem, self.configurations)
		basePrice = basePrice - upgradePrice
	end

	return basePrice, upgradePrice, hasChanges
end

function ShopConfigScreen:updatePriceData(basePrice, upgradePrice)
	self.totalPrice = basePrice + upgradePrice
	self.initialLeasingCosts = 0
	self.initialLeasingCosts = self.currentMission.economyManager:getInitialLeasingPrice(self.totalPrice)

	self.basePriceText:setText(self.l10n:formatMoney(basePrice, 0, true, false))
	self.upgradesPriceText:setText("+ " .. self.l10n:formatMoney(upgradePrice, 0, true, false))
	self.totalPriceText:setText(self.l10n:formatMoney(self.totalPrice, 0, true, false))
end

function ShopConfigScreen:updateData(storeItem, vehicle, saleItem)
	local basePrice, upgradePrice, hasChanges = self:getConfigurationCostsAndChanges(storeItem, vehicle, saleItem)

	self:updatePriceData(basePrice, upgradePrice)
	self.buyButton:setDisabled(not hasChanges)

	self.loadingCount = storeItem.bundleInfo ~= nil and #storeItem.bundleInfo.bundleItems or 1
	self.loadedCount = 0

	self:loadCurrentConfiguration(storeItem)
end

function ShopConfigScreen:getDefaultConfigurationColorIndex(configName, configItems, vehicle)
	local index = nil

	for k, item in pairs(configItems) do
		if item.isDefault then
			index = k

			break
		end
	end

	if vehicle ~= nil then
		index = vehicle.configurations[configName]
	end

	if index == nil then
		index = 1
	end

	return index
end

function ShopConfigScreen:updateButtons(storeItem, vehicle, saleItem)
	self.leaseButton:setVisible(vehicle == nil and storeItem.allowLeasing and saleItem == nil)

	local buyButtonText = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.BUTTON_BUY)
	local buyButtonProfile = ShopConfigScreen.GUI_PROFILE.BUTTON_BUY

	if vehicle ~= nil then
		buyButtonText = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.BUTTON_CONFIGURE)
		buyButtonProfile = ShopConfigScreen.GUI_PROFILE.BUTTON_CONFIGURE
	end

	self.buyButton:setText(buyButtonText)
	self.buyButton:applyProfile(buyButtonProfile)
	self.buttonsPanel:invalidateLayout()
end

function ShopConfigScreen:loadCurrentConfiguration(storeItem, vehicleIndex, offsetVector, rotationOffsetVector, preSelectedConfigurations, isBundleItem, bundleRootItem)
	vehicleIndex = vehicleIndex or 1

	if storeItem.bundleInfo ~= nil then
		for _, bundleItem in ipairs(storeItem.bundleInfo.bundleItems) do
			self:loadCurrentConfiguration(bundleItem.item, vehicleIndex, bundleItem.offset, bundleItem.rotationOffset, bundleItem.preSelectedConfigurations, true, storeItem)

			vehicleIndex = vehicleIndex + 1
		end

		return
	end

	local configurations = {}
	local item = g_storeManager:getItemByXMLFilename(storeItem.xmlFilename)

	for configName, value in pairs(self.configurations) do
		if item.configurations[configName] ~= nil then
			configurations[configName] = value
		end
	end

	if preSelectedConfigurations ~= nil then
		for configName, preSelectedOption in pairs(preSelectedConfigurations) do
			if not preSelectedOption.allowChange then
				configurations[configName] = preSelectedOption.configValue
				self.configurations[configName] = preSelectedOption.configValue
			end
		end
	end

	local filename = storeItem.xmlFilename
	local xmlFile = loadXMLFile("LoadConfigStoreItem", filename)
	local typeName = getXMLString(xmlFile, "vehicle#type")

	delete(xmlFile)

	if self.configurations ~= nil and self.configurations.vehicleType and storeItem.configurations.vehicleType ~= nil then
		typeName = storeItem.configurations.vehicleType[self.configurations.vehicleType].vehicleType
	end

	local typeDef = self.vehicleTypeManager:getTypeByName(typeName)
	local modName, _ = Utils.getModNameAndBaseDirectory(filename)

	if modName ~= nil then
		if g_modIsLoaded[modName] == nil or not g_modIsLoaded[modName] then
			print("Error: Mod '" .. modName .. "' of vehicle '" .. filename .. "'")
			print("       is not loaded. This vehicle will not be loaded.")
			self:onVehicleLoaded(nil, VehicleLoadingUtil.VEHICLE_LOAD_ERROR, vehicleIndex)

			return
		end

		if typeDef == nil then
			typeName = modName .. "." .. typeName
			typeDef = self.vehicleTypeManager:getTypeByName(typeName)
		end
	end

	if typeDef == nil then
		Logging.error("Error: Unable to find vehicle type name '%s' for '%s'", typeName, filename)

		return
	end

	local vehicleClass = ClassUtil.getClassObject(typeDef.className)
	local vehicle = vehicleClass.new(true, true)
	local placePosX, placePosY, placePosZ = unpack(self.workshopWorldPosition)

	if offsetVector ~= nil then
		placePosX = placePosX + offsetVector[1]
		placePosY = placePosY + offsetVector[2]
		placePosZ = placePosZ + offsetVector[3]
	end

	local rotX = 0
	local rotY = storeItem.rotation
	local rotZ = 0

	if rotationOffsetVector ~= nil then
		rotX = rotX + rotationOffsetVector[1]
		rotY = rotY + rotationOffsetVector[2]
		rotZ = rotZ + rotationOffsetVector[3]
	end

	local transOffset = storeItem.shopTranslationOffset
	local rotOffset = storeItem.shopRotationOffset

	if bundleRootItem ~= nil then
		transOffset = bundleRootItem.shopTranslationOffset
		rotOffset = bundleRootItem.shopRotationOffset
	end

	if transOffset ~= nil then
		placePosX = placePosX + transOffset[1]
		placePosY = placePosY + transOffset[2]
		placePosZ = placePosZ + transOffset[3]
	end

	local lastVehicleComponentPositions = {}

	if not storeItem.shopIgnoreLastComponentPositions then
		for _, preVehicle in ipairs(self.previewVehicles) do
			if preVehicle.configFileName == storeItem.xmlFilename then
				for i, component in ipairs(preVehicle.components) do
					lastVehicleComponentPositions[i] = {
						{
							getTranslation(component.node)
						},
						{
							getWorldRotation(component.node)
						}
					}
				end
			end
		end
	end

	if not isBundleItem then
		local size = StoreItemUtil.getSizeValues(storeItem.xmlFilename, "vehicle", storeItem.rotation, configurations)
		placePosX = placePosX - size.widthOffset
		placePosY = placePosY - size.heightOffset
		placePosZ = placePosZ - size.lengthOffset
	end

	if rotOffset ~= nil then
		rotX = rotX + rotOffset[1]
		rotY = rotY + rotOffset[2]
		rotZ = rotZ + rotOffset[3]
	end

	local vehicleData = {
		filename = storeItem.xmlFilename,
		isAbsolute = true,
		typeName = typeName,
		price = 0,
		propertyState = Vehicle.PROPERTY_STATE_SHOP_CONFIG,
		posX = placePosX,
		posY = placePosY,
		posZ = placePosZ,
		yOffset = 0,
		rotX = rotX,
		rotY = rotY,
		rotZ = rotZ,
		isVehicleSaved = false,
		additionalLoadParameters = {
			foldableInvertFoldState = MathUtil.round(storeItem.shopFoldingState, 0) == 1,
			foldableFoldingTime = storeItem.shopFoldingTime
		},
		configurations = configurations,
		componentPositions = lastVehicleComponentPositions
	}

	self.loadingAnimation:setVisible(true)
	vehicle:load(vehicleData, self.onVehicleLoaded, self, {
		vehicleIndex = vehicleIndex,
		openCounter = self.openCounter
	})
end

function ShopConfigScreen:onVehicleLoaded(vehicle, loadingState, asyncArguments)
	if loadingState == VehicleLoadingUtil.VEHICLE_LOAD_OK then
		if asyncArguments.openCounter ~= self.openCounter then
			vehicle:delete()

			return
		end

		self:processAttributeData(self.storeItem, vehicle)

		if self.isLoadingInitial or self.isOpen then
			local previousVehicle = self.previewVehicles[asyncArguments.vehicleIndex]

			if previousVehicle ~= nil then
				previousVehicle:removeFromPhysics()
				table.insert(self.previousVehicles, previousVehicle)
			end

			self.previewVehicles[asyncArguments.vehicleIndex] = vehicle

			vehicle:setVisibility(false)
		else
			vehicle:delete()

			self.previewVehicles[asyncArguments.vehicleIndex] = nil
		end

		if vehicle.setLicensePlatesData ~= nil and vehicle.getHasLicensePlates ~= nil and vehicle:getHasLicensePlates() then
			vehicle:setLicensePlatesData(self.licensePlateData)
		end
	else
		if g_currentMission ~= nil then
			Logging.error("Could not load vehicle defined in [%s]. Check vehicle configuration and mods.", tostring(self.storeItem.xmlFilename))

			self.callbackFunc = nil

			self:onClickBack()
		end

		return
	end

	self.loadedCount = self.loadedCount + 1
	local doneLoading = self.loadedCount == self.loadingCount

	if doneLoading then
		if #self.previewVehicles > 1 and self.storeItem.bundleInfo ~= nil then
			for _, attachInfo in pairs(self.storeItem.bundleInfo.attacherInfo) do
				local v1 = self.previewVehicles[attachInfo.bundleElement0]
				local v2 = self.previewVehicles[attachInfo.bundleElement1]

				v1:attachImplement(v2, attachInfo.inputAttacherJointIndex, attachInfo.attacherJointIndex, true, nil, false, true)
			end
		end

		local loadingDelayTime = 0

		if self.isLoadingInitial then
			loadingDelayTime = self.storeItem.shopInitialLoadingDelay or loadingDelayTime
		else
			loadingDelayTime = self.storeItem.shopConfigLoadingDelay or loadingDelayTime
		end

		self.loadingDelayTime = loadingDelayTime
		self.loadingDelayFrames = 3
	end

	if self.isOpen then
		self:disableAlternateBindings()
	end
end

function ShopConfigScreen:onFinishedLoading()
	for i = #self.previousVehicles, 1, -1 do
		self.previousVehicles[i]:delete()

		self.previousVehicles[i] = nil
	end

	for _, loadedVehicle in pairs(self.previewVehicles) do
		loadedVehicle:setVisibility(true)
	end

	self.previewVehicleSize = 0

	for _, loadedVehicle in pairs(self.previewVehicles) do
		local largestDimension = math.max(loadedVehicle.size.width, loadedVehicle.size.length, self.storeItem.shopHeight * 1.5)
		self.previewVehicleSize = self.previewVehicleSize + largestDimension
	end

	if self.previewVehicleSize == 0 then
		self.previewVehicleSize = ShopConfigScreen.DEFAULT_PREVIEW_SIZE
	end

	self.cameraMaxDistance = math.min(self.previewVehicleSize * ShopConfigScreen.CAMERA_MAX_DISTANCE_FACTOR, ShopConfigScreen.MAX_CAMERA_DISTANCE)
	self.cameraMinDistance = self.previewVehicleSize * ShopConfigScreen.CAMERA_MIN_DISTANCE_FACTOR + ShopConfigScreen.NEAR_CLIP_DISTANCE
	self.focusY = self.previewVehicleSize * 0.1

	if self.isLoadingInitial then
		self.cameraDistance = math.min(self.cameraMinDistance * 1.5, self.cameraMaxDistance)
		self.zoomTarget = self.cameraDistance
		self.rotMinX = math.asin(ShopConfigScreen.NEAR_CLIP_DISTANCE / self.cameraMinDistance)
	end

	if self.storeItem.shopDynamicTitle then
		local vehicle = self.previewVehicles[1]

		if vehicle ~= nil then
			local brand = self.brandManager:getBrandByIndex(vehicle:getBrand() or self.storeItem.brandIndex)

			self.shopConfigBrandIcon:setImageFilename(self.storeItem.customBrandIcon or brand.image)
			self.shopConfigBrandIcon:setPosition((self.storeItem.customBrandIconOffset or brand.imageOffset) * self.shopConfigBrandIcon.size[1] * -1, nil)
			self.shopConfigItemName:setText(vehicle:getName() or self.storeItem.name)
		end
	end

	self.isLoadingInitial = false

	self.loadingAnimation:setVisible(false)
end

function ShopConfigScreen:updateDisplay(storeItem, vehicle, saleItem, doNotReload)
	local brandIndex = storeItem.brandIndex
	local vehicleName = storeItem.name

	if storeItem.shopDynamicTitle and vehicle ~= nil then
		brandIndex = vehicle:getBrand()
		vehicleName = vehicle:getName()
	end

	local brand = self.brandManager:getBrandByIndex(brandIndex)

	self.shopConfigBrandIcon:setImageFilename(storeItem.customBrandIcon or brand.image)
	self.shopConfigBrandIcon:setPosition((self.storeItem.customBrandIconOffset or brand.imageOffset) * self.shopConfigBrandIcon.size[1] * -1, nil)
	self.shopConfigItemName:setText(vehicleName)
	self:updateConfigOptionsDisplay(storeItem, vehicle, saleItem)
	self:updateButtons(storeItem, vehicle, saleItem)

	if not doNotReload then
		self:updateData(storeItem, vehicle, saleItem)
	end
end

function ShopConfigScreen:setCurrentMission(currentMission)
	self.currentMission = currentMission

	if currentMission ~= nil and self.shopLighting ~= nil then
		self.shopLighting:setEnvironment(self.currentMission.environment)
	end
end

function ShopConfigScreen:loadMapData(mapXMLFile, missionInfo, baseDirectory)
	if not GS_IS_MOBILE_VERSION then
		local shopConfigFilename = getXMLString(mapXMLFile, "map.shop#filename") or "$data/store/ui/shop.xml"
		shopConfigFilename = Utils.getFilename(shopConfigFilename, baseDirectory)
		local xmlFile = loadXMLFile("shopXml", shopConfigFilename)
		self.workshopFilename = Utils.getFilename(getXMLString(xmlFile, "shop.filename") or ShopConfigScreen.WORKSHOP_PATH, baseDirectory)
		local x = getXMLFloat(xmlFile, "shop.position#xMapPos") or 0
		local y = getXMLFloat(xmlFile, "shop.position#yMapPos") or 0
		local z = getXMLFloat(xmlFile, "shop.position#zMapPos") or 0
		local isLightingStatic = getXMLBool(xmlFile, "shop.lighting#isStatic") or false

		if isLightingStatic then
			self.shopLighting = LightingStatic.new()
		else
			self.shopLighting = Lighting.new()
		end

		self.shopLighting:load(xmlFile, "shop.lighting")
		delete(xmlFile)
		self:createWorkshop(self.workshopFilename, x, y, z)
	end
end

function ShopConfigScreen:unloadMapData()
	if self.workshopNode ~= nil then
		delete(self.workshopNode)
	end

	if self.workshopRootNode ~= nil then
		delete(self.workshopRootNode)
	end

	if self.shopLighting ~= nil then
		self.shopLighting:delete()
	end

	if self.creationBox ~= nil then
		delete(self.creationBox)

		self.creationBox = nil
	end

	if self.loadRequestIdWorkshop ~= nil then
		self.i3dManager:cancelStreamI3DFile(self.loadRequestIdWorkshop)

		self.loadRequestIdWorkshop = nil
	end

	if self.loadRequestIdLicensePlateBox ~= nil then
		self.i3dManager:cancelStreamI3DFile(self.loadRequestIdLicensePlateBox)

		self.loadRequestIdLicensePlateBox = nil
	end

	self.shopLighting = nil
	self.workshopNode = nil
	self.workshopRootNode = nil
end

function ShopConfigScreen:setWorkshopWorldPosition(posX, posY, posZ)
	self.workshopWorldPosition = {
		posX,
		posY,
		posZ
	}
end

function ShopConfigScreen:setCallbacks(callbackFunc, target)
	self.callbackFunc = callbackFunc
	self.target = target
end

function ShopConfigScreen:deletePreviewVehicles()
	for _, vehicle in pairs(self.previewVehicles) do
		vehicle:delete()
	end

	self.previewVehicles = {}
end

function ShopConfigScreen:setStoreItem(storeItem, vehicle, saleItem, configBasePrice, configurations)
	self:deletePreviewVehicles()

	self.storeItem = storeItem
	self.vehicle = vehicle
	self.saleItem = saleItem
	self.configBasePrice = Utils.getNoNil(configBasePrice, 0)

	if configurations == nil then
		configurations = {}

		if storeItem.defaultConfigurationIds ~= nil then
			for configName, index in pairs(storeItem.defaultConfigurationIds) do
				configurations[configName] = index
			end
		end

		if vehicle ~= nil and vehicle.configurations ~= nil then
			for configName, index in pairs(vehicle.configurations) do
				configurations[configName] = index
			end
		end

		if saleItem ~= nil and saleItem.boughtConfigurations ~= nil then
			for configName, boughtItems in pairs(saleItem.boughtConfigurations) do
				for index, value in pairs(boughtItems) do
					if value then
						configurations[configName] = index
					end
				end
			end
		end
	end

	self.configurations = configurations
	self.subConfigurations = {}
	self.currentConfigSet = 1
	self.isLoadingInitial = true

	if g_licensePlateManager:getAreLicensePlatesAvailable() then
		if vehicle ~= nil then
			if vehicle.getLicensePlatesData ~= nil then
				local data = vehicle:getLicensePlatesData()

				if data ~= nil and data.characters ~= nil then
					self.licensePlateData = {
						variation = data.variation,
						colorIndex = data.colorIndex,
						placementIndex = data.placementIndex,
						characters = table.copy(data.characters)
					}
				else
					self.licensePlateData = g_licensePlateManager:getRandomLicensePlateData()
				end
			end
		else
			self.licensePlateData = g_licensePlateManager:getRandomLicensePlateData()
		end
	end

	self:processStoreItemConfigurations(storeItem, vehicle, saleItem)
	self:updateDisplay(storeItem, vehicle, saleItem)
	self:resetCamera()
end

function ShopConfigScreen:setRequestExitCallback(callback)
	self.requestExitCallback = callback or NO_CALLBACK
end

function ShopConfigScreen:setConfigPrice(configName, configIndex, priceTextElement, vehicle)
	local configItems = self.storeItem.configurations[configName]
	local price = configItems[configIndex].price

	if vehicle ~= nil then
		if ConfigurationUtil.hasBoughtConfiguration(vehicle, configName, configIndex) then
			price = 0
		end
	elseif self.saleItem ~= nil and ConfigurationUtil.hasBoughtConfiguration(self.saleItem, configName, configIndex) then
		price = 0
	end

	priceTextElement:setText("+" .. self.l10n:formatMoney(price) .. "")
	priceTextElement:setVisible(true)
end

function ShopConfigScreen:onPickColor(colorIndex, args, noUpdate)
	if colorIndex ~= nil then
		local configName = args.configName
		local colorOptionIndex = args.colorOptionIndex
		local element = self.colorElements[colorOptionIndex]
		self.configurations[configName] = colorIndex
		local config = self.storeItem.configurations[configName][colorIndex]
		local color = config.uiColor or config.color
		color[4] = 1
		local isMetallic = ConfigurationUtil.isColorMetallic(config.material)

		element:getDescendantByName("colorImage"):setImageColor(nil, unpack(color))
		element:getDescendantByName("colorImage"):setVisible(not isMetallic)
		element:getDescendantByName("colorImageMetallic"):setImageColor(nil, unpack(color))
		element:getDescendantByName("colorImageMetallic"):setVisible(isMetallic)

		local priceElement = element.parent:getDescendantByName("price")

		self:setConfigPrice(configName, colorIndex, priceElement, self.vehicle)

		if not noUpdate then
			self:updateData(self.storeItem, self.vehicle, self.saleItem)
			self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_SPRAY)
		end
	end
end

function ShopConfigScreen:selectFirstConfig()
	local firstElement = self.configurationLayout.elements[1]

	if firstElement ~= nil then
		local focusElement = firstElement:getDescendantByName("option")

		if not focusElement:getIsVisible() then
			focusElement = firstElement:getDescendantByName("color")
		end

		if not focusElement:getIsVisible() then
			focusElement = firstElement:getDescendantByName("button")
		end

		FocusManager:unsetFocus(focusElement)
		FocusManager:setFocus(focusElement)
	else
		FocusManager:unsetFocus(FocusManager:getFocusedElement())

		FocusManager.currentFocusData.focusElement = nil
	end
end

function ShopConfigScreen:processStoreItemConfigurationSet(storeItem, configSet, vehicle, saleItem)
	local options = {}
	local configurationTypes = self.configurationManager:getConfigurationTypes()
	local configNames = {}
	local subConfigIndex = 1

	for _, configName in ipairs(configurationTypes) do
		if self.configurationManager:getConfigurationAttribute(configName, "selectorType") ~= ConfigurationUtil.SELECTOR_COLOR then
			local items = storeItem.configurations[configName]
			local subConfigItems = storeItem.subConfigurations[configName]

			if subConfigItems ~= nil and #subConfigItems.subConfigValues > 1 then
				table.insert(configNames, subConfigIndex, configName)

				subConfigIndex = subConfigIndex + 1
			elseif items ~= nil and #items > 1 and configSet.configurations[configName] == nil then
				table.insert(configNames, configName)
			end
		end
	end

	for i, configName in ipairs(configNames) do
		local option = nil

		if i < subConfigIndex then
			option = self:processStoreItemSubConfigurationOption(storeItem, configName, vehicle, saleItem)
		else
			local items = storeItem.configurations[configName]
			option = self:processStoreItemConfigurationOption(storeItem, configName, items, vehicle, nil, saleItem)
		end

		table.insert(options, option)
	end

	return options
end

function ShopConfigScreen:processStoreItemSubConfigurationOption(storeItem, configName, vehicle, saleItem)
	local subConfig = storeItem.subConfigurations[configName]
	local texts = {}
	local icons = {}
	local subConfigOptions = {}
	local subConfigSelection = {
		selectedIndex = 1,
		isSubConfiguration = true,
		name = configName,
		title = self.configurationManager:getConfigurationDescByName(configName).subConfigurationTitle,
		texts = texts,
		subConfigOptions = subConfigOptions
	}
	local initialIndex = 1

	if vehicle ~= nil then
		initialIndex = StoreItemUtil.getSubConfigurationIndex(storeItem, configName, vehicle.configurations[configName])
	end

	subConfigSelection.selectedIndex = initialIndex
	self.subConfigurations[configName] = initialIndex

	for i, name in pairs(subConfig.subConfigValues) do
		if type(name) == "table" then
			table.insert(subConfigSelection.texts, name.title)
			table.insert(icons, name.icon)
		else
			table.insert(subConfigSelection.texts, name)
		end

		local items = StoreItemUtil.getSubConfigurationItems(storeItem, configName, i)
		local subConfigOption = self:processStoreItemConfigurationOption(storeItem, configName, items, vehicle, true, saleItem)

		table.insert(subConfigSelection.subConfigOptions, subConfigOption)
	end

	if #icons > 0 then
		subConfigSelection.icons = icons
	end

	return subConfigSelection
end

function ShopConfigScreen:processStoreItemConfigurationOption(storeItem, configName, configItems, vehicle, isSubConfigOption)
	local configOption = {
		defaultIndex = 1,
		name = configName,
		title = self.configurationManager:getConfigurationAttribute(configName, "title"),
		texts = {},
		icons = {},
		options = {}
	}
	local initialIndex = 1
	local overwrittenTitle = nil
	local hasValidIcons = false
	local index = 1

	for _, item in ipairs(configItems) do
		if item.isDefault then
			initialIndex = index
			configOption.defaultIndex = index
		end

		local isSelectable = item.isSelectable

		if storeItem.bundleInfo ~= nil then
			for _, bundleItem in ipairs(storeItem.bundleInfo.bundleItems) do
				if bundleItem.preSelectedConfigurations ~= nil and bundleItem.preSelectedConfigurations[configName] ~= nil then
					local preSelectedOption = bundleItem.preSelectedConfigurations[configName]

					if item.index == preSelectedOption.configValue then
						isSelectable = true
						initialIndex = index
						configOption.defaultIndex = index
					end

					if not preSelectedOption.allowChange then
						configOption.isDisabled = true
					end

					if preSelectedOption.hideOption then
						return
					end
				end
			end
		end

		overwrittenTitle = overwrittenTitle or item.overwrittenTitle

		if isSelectable then
			table.insert(configOption.texts, item.name)
			table.insert(configOption.options, item)

			if item.brandIndex ~= nil then
				local iconFilename = g_brandManager:getBrandIconByIndex(item.brandIndex)

				if iconFilename ~= nil then
					table.insert(configOption.icons, iconFilename)

					hasValidIcons = true
				end
			end

			if #configOption.icons ~= #configOption.texts then
				table.insert(configOption.icons, item.name)
			end

			index = index + 1
		end
	end

	if vehicle ~= nil then
		local vehicleConfigIndex = vehicle.configurations[configName]

		for i, item in ipairs(configItems) do
			if item.index == vehicleConfigIndex then
				initialIndex = i

				break
			end
		end
	end

	configOption.defaultIndex = initialIndex
	configOption.title = overwrittenTitle or configOption.title

	if not hasValidIcons then
		configOption.icons = nil
	end

	if #configOption.options <= 1 and not isSubConfigOption then
		return
	end

	return configOption
end

function ShopConfigScreen:processStoreItemColorOption(storeItem, configName, colorItems, colorPickerIndex, vehicle, saleItem)
	local overwrittenTitle = nil

	for _, item in ipairs(colorItems) do
		overwrittenTitle = overwrittenTitle or item.overwrittenTitle
	end

	table.insert(self.colorPickers, {
		title = overwrittenTitle or self.configurationManager:getConfigurationAttribute(configName, "title"),
		configName = configName,
		colorItems = colorItems
	})
end

function ShopConfigScreen:processStoreItemConfigurations(storeItem, vehicle, saleItem)
	self.configSelection = {
		title = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIGURATION_LABEL),
		texts = {},
		prices = {},
		options = {}
	}
	self.currentConfigSet = 1
	local configSets = storeItem.configurationSets

	if #storeItem.configurationSets == 0 then
		local defaultSet = {
			name = "",
			isDefault = true,
			configurations = {}
		}
		configSets = {
			defaultSet
		}
	end

	if storeItem.configurations ~= nil then
		for i, configSet in ipairs(configSets) do
			if configSet.isDefault then
				self.currentConfigSet = i
			end

			if configSet.overwrittenTitle ~= nil then
				self.configSelection.title = configSet.overwrittenTitle
			end

			local price = 0

			for name, index in pairs(configSet.configurations) do
				if self.vehicle == nil or not ConfigurationUtil.hasBoughtConfiguration(self.vehicle, name, index) then
					price = price + storeItem.configurations[name][index].price
				end
			end

			table.insert(self.configSelection.prices, price)
			table.insert(self.configSelection.texts, configSet.name)

			local setOptions = self:processStoreItemConfigurationSet(storeItem, configSet, vehicle, saleItem)

			table.insert(self.configSelection.options, setOptions)
		end

		for name, index in pairs(configSets[self.currentConfigSet].configurations) do
			self.configurations[name] = index
		end

		self.colorPickers = {}
		local colorPickerIndex = 1
		local configurations = g_configurationManager:getConfigurationTypes()

		for i = 1, #configurations do
			local configName = configurations[i]
			local configItems = storeItem.configurations[configName]

			if storeItem.configurations[configName] ~= nil then
				local isColor = self.configurationManager:getConfigurationAttribute(configName, "selectorType") == ConfigurationUtil.SELECTOR_COLOR

				if #configItems > 1 and isColor then
					self:processStoreItemColorOption(storeItem, configName, configItems, colorPickerIndex, vehicle, saleItem)

					colorPickerIndex = colorPickerIndex + 1
				end
			end
		end

		self.displayableColorCount = colorPickerIndex - 1
	else
		table.insert(self.configSelection.options, {})

		self.displayableColorCount = 0
	end

	if storeItem.bundleInfo ~= nil then
		for _, bundleItem in ipairs(storeItem.bundleInfo.bundleItems) do
			if bundleItem.preSelectedConfigurations ~= nil then
				for configName, preSelectedOption in pairs(bundleItem.preSelectedConfigurations) do
					self.configurations[configName] = preSelectedOption.configValue
				end
			end
		end
	end
end

function ShopConfigScreen:updateConfigSetOptionElement(configElementIndex, storeItem, vehicle, saleItem)
	local listElement = self.configurationItemTemplate:clone(self.configurationLayout)
	local optionElement = listElement:getDescendantByName("option")

	optionElement:setDisabled(false)
	optionElement:setVisible(true)
	optionElement:setTexts(self.configSelection.texts)
	optionElement:setState(self.currentConfigSet)
	optionElement:reloadFocusHandling(true)

	function optionElement.onClickCallback(_, configSetIndex)
		for name, _ in pairs(storeItem.configurationSets[self.currentConfigSet].configurations) do
			self.configurations[name] = 1
		end

		for name, index in pairs(storeItem.configurationSets[configSetIndex].configurations) do
			self.configurations[name] = index
		end

		self.currentConfigSet = configSetIndex

		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
		self:updateDisplay(storeItem, vehicle, saleItem)
		self:selectFirstConfig()
	end

	listElement:getDescendantByName("title"):setText(self.configSelection.title)

	local price = self.configSelection.prices[self.currentConfigSet]

	listElement:getDescendantByName("price"):setText("+" .. self.l10n:formatMoney(price))
end

function ShopConfigScreen:updateConfigOptionElement(configElementIndex, option, storeItem, vehicle, saleItem)
	local hasIcons = option.icons ~= nil
	local listElement = nil

	if hasIcons then
		listElement = self.configurationItemTemplateLarge:clone(self.configurationLayout)
	else
		listElement = self.configurationItemTemplate:clone(self.configurationLayout)
	end

	local optionElement = listElement:getDescendantByName("option")

	optionElement:setVisible(true)
	optionElement:setDisabled(#option.options <= 1 or option.isDisabled)

	if hasIcons then
		optionElement:setIcons(option.icons)
	else
		optionElement:setTexts(option.texts)
	end

	optionElement:reloadFocusHandling(true)

	local priceElement = listElement:getDescendantByName("price")
	local configName = option.name
	local configIndex = 0

	for i, item in pairs(option.options) do
		if item.index == self.configurations[configName] then
			configIndex = i

			break
		end
	end

	if configIndex == 0 or option.options[configIndex] == nil then
		configIndex = option.defaultIndex
	end

	optionElement:setState(configIndex)

	self.configurations[configName] = option.options[configIndex].index

	function optionElement.onClickCallback(_, optionIndex)
		local selectedConfigIndex = option.options[optionIndex].index

		self:setConfigPrice(configName, selectedConfigIndex, priceElement, vehicle)

		self.configurations[configName] = selectedConfigIndex

		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
		self:updateData(storeItem, self.vehicle, self.saleItem)
	end

	listElement:getDescendantByName("title"):setText(option.title)
	self:setConfigPrice(configName, option.options[configIndex].index, priceElement, vehicle)
end

function ShopConfigScreen:updateSubConfigOptionElement(configElementIndex, option, storeItem, vehicle, saleItem)
	local hasIcons = option.icons ~= nil
	local listElement = nil

	if hasIcons then
		listElement = self.configurationItemTemplateLarge:clone(self.configurationLayout)
	else
		listElement = self.configurationItemTemplate:clone(self.configurationLayout)
	end

	local optionElement = listElement:getDescendantByName("option")

	optionElement:setVisible(true)
	optionElement:setDisabled(false)

	if hasIcons then
		optionElement:setIcons(option.icons)
	else
		optionElement:setTexts(option.texts)
	end

	optionElement:reloadFocusHandling(true)

	local configName = option.name
	local subConfigIndex = self.subConfigurations[configName] or option.defaultIndex
	self.subConfigurations[configName] = subConfigIndex
	option.selectedIndex = subConfigIndex

	optionElement:setState(subConfigIndex)

	function optionElement.onClickCallback(_, state)
		self.subConfigurations[configName] = state
		option.selectedIndex = state
		local subConfigOptionIndex = option.subConfigOptions[state].defaultIndex
		self.configurations[configName] = subConfigOptionIndex

		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CONFIG_WRENCH)
		self:updateConfigOptionsDisplay(storeItem, vehicle, saleItem)
		self:updateData(storeItem, self.vehicle, saleItem)
		FocusManager:unsetFocus(optionElement)
		FocusManager:setFocus(optionElement)
	end

	listElement:getDescendantByName("price"):setVisible(false)
	listElement:getDescendantByName("title"):setText(option.title)
end

function ShopConfigScreen:updateConfigOptionsData(storeItem, vehicle, saleItem)
	local displayableOptionCount = 0
	local count = 0

	for _ = 1, #self.configurationLayout.elements do
		self.configurationLayout.elements[1]:delete()
	end

	if #self.configSelection.options > 1 then
		displayableOptionCount = displayableOptionCount + 1
		count = 1

		self:updateConfigSetOptionElement(1, storeItem, vehicle, saleItem)
	end

	local optionData = self.configSelection.options[self.currentConfigSet]

	for _, option in ipairs(optionData) do
		displayableOptionCount = displayableOptionCount + 1
		count = count + 1

		if option.isSubConfiguration then
			self:updateSubConfigOptionElement(count, option, storeItem, vehicle, saleItem)
		else
			self:updateConfigOptionElement(count, option, storeItem, vehicle, saleItem)
		end

		if option.isSubConfiguration then
			displayableOptionCount = displayableOptionCount + 1
			count = count + 1
			local subOption = option.subConfigOptions[option.selectedIndex]

			self:updateConfigOptionElement(count, subOption, storeItem, vehicle, saleItem)
		end
	end

	local configSets = storeItem.configurationSets
	local currentConfigSet = configSets[self.currentConfigSet]
	self.colorElements = {}

	if self.displayableColorCount > 0 then
		for i, option in ipairs(self.colorPickers) do
			local visibility = true

			if currentConfigSet ~= nil and currentConfigSet.configurations[option.configName] ~= nil then
				visibility = false
			end

			if storeItem.bundleInfo ~= nil then
				for _, bundleItem in ipairs(storeItem.bundleInfo.bundleItems) do
					if bundleItem.preSelectedConfigurations ~= nil and bundleItem.preSelectedConfigurations[option.configName] ~= nil then
						local preSelectedOption = bundleItem.preSelectedConfigurations[option.configName]

						if preSelectedOption.hideOption then
							visibility = false
						end
					end
				end
			end

			local itemsToDisplay = 0

			for j = 1, #option.colorItems do
				if option.colorItems[j].isSelectable ~= false then
					itemsToDisplay = itemsToDisplay + 1
				end
			end

			visibility = visibility and itemsToDisplay > 1

			if visibility then
				local listElement = self.configurationItemTemplate:clone(self.configurationLayout)
				local colorElement = listElement:getDescendantByName("color")

				colorElement:setVisible(true)
				colorElement:reloadFocusHandling(true)

				self.colorElements[i] = colorElement
				local colorItems = option.colorItems

				function colorElement.onClickCallback(sourceElement)
					local defaultColor = colorItems[self.configurations[option.configName]]

					self.inputManager:setShowMouseCursor(true)
					g_gui:showColorPickerDialog({
						colors = colorItems,
						defaultColor = defaultColor.uiColor or defaultColor.color,
						defaultColorMaterial = defaultColor.material,
						callback = self.onPickColor,
						target = self,
						args = {
							configName = option.configName,
							colorOptionIndex = i
						}
					})
				end

				local defaultColorIndex = self.configurations[option.configName] or self:getDefaultConfigurationColorIndex(option.configName, colorItems, vehicle)

				self:onPickColor(defaultColorIndex, {
					configName = option.configName,
					colorOptionIndex = i
				}, true)
				listElement:getDescendantByName("title"):setText(option.title)

				count = count + 1
			end
		end
	end

	if storeItem.hasLicensePlates and g_licensePlateManager:getAreLicensePlatesAvailable() then
		local listElement = self.configurationItemTemplate:clone(self.configurationLayout)
		local buttonElement = listElement:getDescendantByName("button")

		buttonElement:setVisible(true)
		buttonElement:reloadFocusHandling(true)

		function buttonElement.onClickCallback(sourceElement)
			self:onClickLicensePlate()
		end

		listElement:getDescendantByName("title"):setText(self.l10n:getText("ui_licensePlate"))
		listElement:getDescendantByName("price"):setVisible(false)

		self.licensePlateRender = listElement:getDescendantByName("plate")

		self.licensePlateRender:createScene()

		count = count + 1
	else
		self.licensePlateRender = nil
	end

	self.displayableOptionCount = displayableOptionCount

	return count
end

function ShopConfigScreen:updateConfigOptionsDisplay(storeItem, vehicle, saleItem)
	local current = FocusManager.currentGui

	FocusManager:setGui("ShopConfigScreen")

	local num = self:updateConfigOptionsData(storeItem, vehicle, saleItem)

	self.configurationsTitle:setVisible(num > 0)
	self.configurationsBox:setVisible(num > 0)
	self.configSlider.parent:setVisible(num > 0)
	self.configurationLayout:invalidateLayout()
	FocusManager:setGui(current)

	if self.needsRefocus then
		self:selectFirstConfig()

		self.needsRefocus = false
	end
end

function ShopConfigScreen:update(dt)
	ShopConfigScreen:superClass().update(self, dt)

	if self.vehicle ~= nil and self.vehicle.isDeleted then
		g_gui:showGui("")

		self.vehicle = nil

		return
	end

	if not self.fadeInAnimation:getFinished() then
		self.fadeInAnimation:update(dt)
	end

	if not self.fadeOutAnimation:getFinished() then
		self.fadeOutAnimation:update()
	end

	if self.lastMoney ~= self.currentMission:getMoney() then
		self:updateBalanceText()
	end

	if self.loadingDelayTime > 0 or self.loadingDelayFrames > 0 then
		self.loadingDelayFrames = math.max(self.loadingDelayFrames - 1, 0)
		self.loadingDelayTime = math.max(self.loadingDelayTime - dt, 0)

		if self.loadingDelayTime <= 0 and self.loadingDelayFrames <= 0 then
			self:onFinishedLoading()
		end
	end

	for _, vehicle in pairs(self.previewVehicles) do
		vehicle:update(dt)
		vehicle:updateTick(dt)
	end

	self.shopController:update(dt)
	self:updateInput(dt)
	self:updateCamera(dt)

	if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES and #self.previewVehicles > 0 then
		for i = 1, #self.previewVehicles do
			local vehicle = self.previewVehicles[i]
			local component = vehicle.components[1]

			if component ~= nil then
				local x, y, z = getWorldTranslation(component.node)
				local rx, ry, rz = getWorldRotation(component.node)

				renderText(0.55, 0.05 + (i - 1) * 0.02, 0.015, string.format("Vehicle Position: Translation: %.3f %.3f %.3f Rotation: %.3f %.3f %.3f (%s)", x, y + 100, z, math.deg(rx), math.deg(ry), math.deg(rz), vehicle:getName()))
			end
		end
	end
end

function ShopConfigScreen:updateCamera(dt)
	local screenOffX = ShopConfigScreen.CAMERA_MIN_DISTANCE_TO_X_OFFSET_FACTOR * g_screenAspectRatio
	local offDist = self.previewVehicleSize * screenOffX * self.cameraDistance / self.cameraMinDistance
	local offX = math.cos(self.rotY) * offDist
	local offZ = -math.sin(self.rotY) * offDist

	setTranslation(self.rotateNode, self.workshopWorldPosition[1] + offX, self.workshopWorldPosition[2] + self.focusY, self.workshopWorldPosition[3] + offZ)
	setRotation(self.rotateNode, self.rotX, self.rotY, 0)

	local camPosX, camPosY, camPosZ = getWorldTranslation(self.cameraNode)
	local targetPosX, targetPosY, targetPosZ = getWorldTranslation(self.rotateNode)
	local dx, dy, dz = MathUtil.vector3Normalize(targetPosX - camPosX, targetPosY - camPosY, targetPosZ - camPosZ)
	local posX = targetPosX - dx * self.cameraDistance
	local posY = targetPosY - dy * self.cameraDistance
	local posZ = targetPosZ - dz * self.cameraDistance
	local lx, ly, lz = worldToLocal(self.rotateNode, posX, posY, posZ)

	setTranslation(self.cameraNode, lx, ly, lz)
	self:updateDepthOfField()
end

function ShopConfigScreen:updateDepthOfField()
	local focusRadius = self.previewVehicleSize * 0.6
	local nearBlurEndDist = math.max(ShopConfigScreen.NEAR_CLIP_DISTANCE, self.cameraDistance - focusRadius)
	local farBlurStartDist = self.cameraDistance + focusRadius * 2
	local farCoCRadius = self.cameraMinDistance * 1.5 / self.cameraDistance

	g_depthOfFieldManager:setManipulatedParams(nil, nearBlurEndDist, farCoCRadius, farBlurStartDist, nil)
end

function ShopConfigScreen:draw()
	ShopConfigScreen:superClass().draw(self)

	if self.fadeOverlay.visible then
		self.fadeOverlay:render()
	end
end

function ShopConfigScreen:onRenderLoad(scene, overlay)
	local licensePlate = g_licensePlateManager:getLicensePlate(LicensePlateManager.PLATE_TYPE.ELONGATED)

	if licensePlate ~= nil then
		local linkNode = I3DUtil.indexToObject(scene, "0|0")

		link(linkNode, licensePlate.node)
		setTranslation(licensePlate.node, 0, 0, 0)
		setRotation(licensePlate.node, 0, 0, 0)

		self.licensePlate = licensePlate

		self:updateLicensePlateGraphics()

		local cameraNode = I3DUtil.indexToObject(self.licensePlateRender.scene, self.licensePlateRender.cameraPath)

		if cameraNode ~= nil then
			local fovY = getFovY(cameraNode)
			local tolerance = 0.005
			local distance = (self.licensePlate.width / 2 + tolerance) / math.tan(fovY / 2) / (self.licensePlateRender.absSize[1] * licensePlate.width / licensePlate.height / 5 / self.licensePlateRender.absSize[2] * g_screenWidth / g_screenHeight)

			setTranslation(cameraNode, 0, 0, distance)
		end
	end
end

function ShopConfigScreen:updateLicensePlateGraphics()
	local currentVariation = self.licensePlateData.variation or 1
	local currentColorIndex = self.licensePlateData.colorIndex or 1
	local currentCharacters = table.copy(self.licensePlateData.characters, math.huge)

	if self.licensePlate ~= nil then
		self.licensePlate:updateData(currentVariation, LicensePlateManager.PLATE_POSITION.BACK, table.concat(currentCharacters, ""))
		self.licensePlate:setColorIndex(currentColorIndex)
		self.licensePlateRender:setRenderDirty()
	end

	if self.licensePlateData.placementIndex == LicensePlateManager.PLATE_POSITION.NONE then
		self.licensePlateRender.parent:setText(self.l10n:getText("configuration_valueLicensePlateNone"))
		self.licensePlateRender:setVisible(false)
	else
		self.licensePlateRender.parent:setText("")
		self.licensePlateRender:setVisible(true)
	end
end

function ShopConfigScreen:onOpen(element)
	ShopConfigScreen:superClass().onOpen(self)

	self.openCounter = self.openCounter + 1

	g_depthOfFieldManager:reset()
	self:updateBalanceText()
	g_gameStateManager:setGameState(GameState.MENU_SHOP_CONFIG)
	self.currentMission.environment:setCustomLighting(self.shopLighting)
	self.currentMission.environment:setSunVisibility(false)
	setVisibility(self.workshopRootNode, true)

	self.previousCamera = getCamera()

	setCamera(self.cameraNode)
	self:updateInputGlyphs()
	self:toggleCustomInputContext(true, ShopConfigScreen.INPUT_CONTEXT_NAME)
	self:registerInputActions()

	self.needsRefocus = true
end

function ShopConfigScreen:onClose()
	self.isLoadingInitial = false

	ShopConfigScreen:superClass().onClose(self)
	self.currentMission.environment:setSunVisibility(true)
	self.currentMission.environment:setCustomLighting(nil)
	setCamera(self.previousCamera)
	setVisibility(self.workshopRootNode, false)
	self:deletePreviewVehicles()

	self.licensePlate = nil
	self.vehicle = nil
	self.loadingDelayFrames = 0
	self.loadingDelayTime = 0

	g_currentMission:resetGameState()
	self.fadeInAnimation:reset()
	g_depthOfFieldManager:reset()
	self:toggleCustomInputContext(false)
end

function ShopConfigScreen:onClickBuy()
	local _, _, hasChanges = self:getConfigurationCostsAndChanges(self.storeItem, self.vehicle, self.saleItem)

	if not hasChanges then
		return
	end

	local enoughMoney = true

	if self.totalPrice > 0 then
		enoughMoney = self.totalPrice <= self.currentMission:getMoney()
	end

	local enoughSlots = self.currentMission.slotSystem:hasEnoughSlots(self.storeItem)

	self.inputManager:setShowMouseCursor(true)

	if not enoughMoney then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_BUY)
		})
	elseif not enoughSlots then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS)
		})
	else
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

		local text = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIRM_BUY), self.l10n:formatMoney(self.totalPrice, 0, true, true))

		g_gui:showYesNoDialog({
			text = text,
			callback = self.onYesNoBuy,
			target = self
		})
	end
end

function ShopConfigScreen:onClickConfigAction()
	if self.focusedColorElement ~= nil then
		self.focusedColorElement:onFocusActivate()
	elseif self.focusedButtonElement ~= nil then
		self.focusedButtonElement:onFocusActivate()
	end
end

function ShopConfigScreen:onClickLicensePlate()
	g_gui:showLicensePlateDialog({
		callback = self.onChangeLicensePlate,
		target = self,
		licensePlateData = self.licensePlateData
	})
end

function ShopConfigScreen:onChangeLicensePlate(licensePlateData)
	if licensePlateData ~= nil then
		self.licensePlateData = licensePlateData

		for i = 1, #self.previewVehicles do
			local vehicle = self.previewVehicles[i]

			if vehicle.setLicensePlatesData ~= nil then
				vehicle:setLicensePlatesData(self.licensePlateData)
			end
		end

		self:updateLicensePlateGraphics()
		self:updateData(self.storeItem, self.vehicle, self.saleItem)
	end
end

function ShopConfigScreen:onFocusConfigurationOption(element)
	self.focusedColorElement = nil
	self.focusedButtonElement = nil
	self.focusedOptionElement = nil

	if element.name == "button" then
		self.focusedButtonElement = element
	elseif element.name == "color" then
		self.focusedColorElement = element
	elseif element.name == "option" then
		self.focusedOptionElement = element
	end

	self:updateConfigurationButton()
end

function ShopConfigScreen:onLeaveConfigurationOption(element)
	self.focusedColorElement = nil
	self.focusedButtonElement = nil
	self.focusedOptionElement = nil

	self:updateConfigurationButton()
end

function ShopConfigScreen:updateConfigurationButton()
	local visible = self.focusedButtonElement ~= nil or self.focusedColorElement ~= nil

	self.configButton:setVisible(visible)
	self.buttonsPanel:invalidateLayout()
end

function ShopConfigScreen:onYesNoBuy(yes)
	if yes then
		self:onCallback(false, self.storeItem, self.configurations, self.totalPrice, self.licensePlateData, self.saleItem)
	end
end

function ShopConfigScreen:onVehicleBought()
	if not GS_IS_CONSOLE_VERSION then
		FocusManager:setFocus(self.buyButton)
	else
		self:selectFirstConfig()
	end
end

function ShopConfigScreen:onStoreItemsReloaded()
	if self.storeItem ~= nil and g_gui.currentGuiName == "ShopConfigScreen" then
		self.needsRefocus = true
		self.storeItem = g_storeManager:getItemByXMLFilename(self.storeItem.xmlFilename)

		self:processStoreItemConfigurations(self.storeItem, self.vehicle, self.saleItem)
		self:updateDisplay(self.storeItem, self.vehicle, self.saleItem)
	end
end

function ShopConfigScreen:onClickLease()
	if self.vehicle ~= nil then
		return
	end

	if not self.storeItem.allowLeasing then
		return
	end

	local enoughMoney = self.initialLeasingCosts <= self.currentMission:getMoney()
	local enoughSlots = self.currentMission.slotSystem:hasEnoughSlots(self.storeItem)

	self.inputManager:setShowMouseCursor(true)

	if not enoughMoney then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.NOT_ENOUGH_MONEY_LEASE)
		})
	elseif not enoughSlots then
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.ERROR)
		g_gui:showInfoDialog({
			text = self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.TOO_FEW_SLOTS)
		})
	else
		self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)

		local text = string.format(self.l10n:getText(ShopConfigScreen.L10N_SYMBOL.CONFIRM_LEASE), self.l10n:formatMoney(self.initialLeasingCosts, 0, true, false))

		g_gui:showYesNoDialog({
			text = text,
			callback = self.onYesNoLease,
			target = self
		})
	end
end

function ShopConfigScreen:onYesNoLease(yes)
	if yes then
		self:onCallback(true, self.storeItem, self.configurations, nil, self.licensePlateData, self.saleItem)
	end
end

function ShopConfigScreen:onClickShop()
	local eventUnused = ShopConfigScreen:superClass().onClickShop(self)

	if eventUnused then
		self:requestExitCallback()

		eventUnused = false
	end

	return eventUnused
end

function ShopConfigScreen:onCallback(leaseItem, storeItem, configurations, price, licensePlateData, saleItem)
	if self.callbackFunc ~= nil then
		if self.target ~= nil then
			self.callbackFunc(self.target, self.vehicle, leaseItem, storeItem, configurations, price, licensePlateData, saleItem)
		else
			self.callbackFunc(self.vehicle, leaseItem, storeItem, configurations, price, licensePlateData, saleItem)
		end

		self.configurations = table.copy(self.configurations)
	end
end

function ShopConfigScreen:updateInputGlyphs()
	self.zoomGlyph:setActions({
		InputAction.AXIS_MAP_ZOOM_IN,
		InputAction.AXIS_MAP_ZOOM_OUT
	})

	local platformActions = nil

	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		platformActions = {
			InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE,
			InputAction.AXIS_LOOK_UPDOWN_VEHICLE
		}
	else
		platformActions = {
			InputAction.AXIS_LOOK_LEFTRIGHT_DRAG,
			InputAction.AXIS_LOOK_UPDOWN_DRAG
		}
	end

	self.lookGlyph:setActions(platformActions)
end

function ShopConfigScreen:toggleHUDVisible()
	self.shopConfigContent.parent:setVisible(not self.shopConfigContent.parent:getIsVisible())
end

function ShopConfigScreen:registerInputActions()
	local isController = self.inputManager:getLastInputMode() == GS_INPUT_HELP_MODE_GAMEPAD
	local _ = nil
	_, self.eventIdUpDownController = self.inputManager:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_VEHICLE, self, self.onCameraUpDown, false, false, true, isController)
	_, self.eventIdLeftRightController = self.inputManager:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE, self, self.onCameraLeftRight, false, false, true, isController)

	self.inputManager:registerActionEvent(InputAction.AXIS_MAP_ZOOM_IN, self, self.onCameraZoom, false, false, true, true, -1)
	self.inputManager:registerActionEvent(InputAction.AXIS_MAP_ZOOM_OUT, self, self.onCameraZoom, false, false, true, true, 1)

	_, self.eventIdUpDownMouse = self.inputManager:registerActionEvent(InputAction.AXIS_LOOK_UPDOWN_DRAG, self, self.onCameraUpDown, false, false, true, not isController)
	_, self.eventIdLeftRightMouse = self.inputManager:registerActionEvent(InputAction.AXIS_LOOK_LEFTRIGHT_DRAG, self, self.onCameraLeftRight, false, false, true, not isController)

	self:disableAlternateBindings()
end

function ShopConfigScreen:disableAlternateBindings()
	self.inputManager:disableAlternateBindingsForAction(InputAction.MENU_AXIS_UP_DOWN)
	self.inputManager:disableAlternateBindingsForAction(InputAction.MENU_AXIS_LEFT_RIGHT)
end

function ShopConfigScreen:onCameraLeftRight(actionName, inputValue, callbackState, isAnalog)
	if actionName == InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE then
		self.inputHorizontal = inputValue * -1
	elseif not self.configSlider.mouseDown then
		local dragValue = inputValue * ShopConfigScreen.MOUSE_SPEED_MULTIPLIER
		self.accumDraggingInput = self.accumDraggingInput + math.abs(dragValue * g_screenAspectRatio)

		if ShopConfigScreen.MIN_MOUSE_DRAG_INPUT <= self.accumDraggingInput then
			self.inputDragging = true
			self.inputHorizontal = dragValue
		else
			self.inputHorizontal = 0
		end
	end
end

function ShopConfigScreen:onCameraUpDown(actionName, inputValue, callbackState, isAnalog)
	if actionName == InputAction.AXIS_LOOK_UPDOWN_VEHICLE then
		self.inputVertical = inputValue
	elseif not self.configSlider.mouseDown then
		local dragValue = inputValue * ShopConfigScreen.MOUSE_SPEED_MULTIPLIER
		self.accumDraggingInput = self.accumDraggingInput + math.abs(dragValue)

		if ShopConfigScreen.MIN_MOUSE_DRAG_INPUT <= self.accumDraggingInput then
			self.inputDragging = true
			self.inputVertical = dragValue
		else
			self.inputVertical = 0
		end
	end
end

function ShopConfigScreen:onCameraZoom(actionName, inputValue, direction, isAnalog, isMouse)
	if isMouse and self.configSlider:getIsVisible() then
		local mouseX, mouseY = self.inputManager:getMousePosition()
		local cursorOnSlider = GuiUtils.checkOverlayOverlap(mouseX, mouseY, self.configSlider.absPosition[1], self.configSlider.absPosition[2], self.configSlider.size[1], self.configSlider.size[2])

		if cursorOnSlider then
			return
		end

		local cursorInList = GuiUtils.checkOverlayOverlap(mouseX, mouseY, self.configurationLayout.absPosition[1], self.configurationLayout.absPosition[2], self.configurationLayout.size[1], self.configurationLayout.size[2])

		if cursorInList then
			return
		end
	end

	local modifier = 0.05 * direction

	if not isAnalog then
		modifier = 0.2 * direction

		if isMouse then
			modifier = modifier * InputBinding.MOUSE_WHEEL_INPUT_FACTOR
		end
	end

	self.inputZoom = self.inputZoom + inputValue * modifier
end

function ShopConfigScreen:updateInput(dt)
	self:updateInputContext()

	if self.inputVertical ~= 0 then
		local value = self.inputVertical
		self.inputVertical = 0
		local rotSpeed = 0.001 * dt

		if self.limitRotXDelta > 0.001 then
			self.rotX = math.min(self.rotX - rotSpeed * value, self.rotX)
		elseif self.limitRotXDelta < -0.001 then
			self.rotX = math.max(self.rotX - rotSpeed * value, self.rotX)
		else
			self.rotX = self.rotX - rotSpeed * value
		end
	end

	if self.inputHorizontal ~= 0 then
		local value = self.inputHorizontal
		self.inputHorizontal = 0
		local rotSpeed = 0.001 * dt
		self.rotY = self.rotY - rotSpeed * value
	end

	if self.inputZoom ~= 0 then
		self.zoomTarget = self.zoomTarget + dt * self.inputZoom * 0.1
		self.zoomTarget = MathUtil.clamp(self.zoomTarget, self.cameraMinDistance, self.cameraMaxDistance)
		self.inputZoom = 0
	end

	self.cameraDistance = self.zoomTarget + math.pow(0.99579, dt) * (self.cameraDistance - self.zoomTarget)
	self.rotX = self:limitXRotation(self.rotX)
	local inputHelpMode = self.inputManager:getInputHelpMode()

	if inputHelpMode ~= self.lastInputHelpMode then
		self.lastInputHelpMode = inputHelpMode

		self:updateInputGlyphs()
	end

	if not self.isDragging and self.inputDragging then
		self.isDragging = true

		self.inputManager:setShowMouseCursor(false, true)
	elseif self.isDragging and not self.inputDragging then
		self.isDragging = false

		self.inputManager:setShowMouseCursor(true)

		self.accumDraggingInput = 0
	end

	self.inputDragging = false
end

function ShopConfigScreen:limitXRotation(currentXRotation)
	local camHeight = self.cameraDistance * math.sin(self.rotX) + self.focusY
	local maxHeight = math.min(camHeight, ShopConfigScreen.MAX_CAMERA_HEIGHT - self.focusY)
	local limitedRotX = self.rotMaxX

	if maxHeight <= self.cameraDistance then
		limitedRotX = math.min(self.rotMaxX, math.asin(maxHeight / self.cameraDistance))
	end

	return math.max(self.rotMinX, math.min(limitedRotX, self.rotX))
end

function ShopConfigScreen:updateInputContext()
	local currentInputMode = self.inputManager:getLastInputMode()

	if currentInputMode ~= self.lastInputMode then
		local isController = currentInputMode == GS_INPUT_HELP_MODE_GAMEPAD

		self.inputManager:setActionEventActive(self.eventIdUpDownController, isController)
		self.inputManager:setActionEventActive(self.eventIdLeftRightController, isController)
		self.inputManager:setActionEventActive(self.eventIdUpDownMouse, not isController)
		self.inputManager:setActionEventActive(self.eventIdLeftRightMouse, not isController)

		self.lastInputMode = currentInputMode
		self.isDragging = false

		self.inputManager:setShowMouseCursor(true)
		self:disableAlternateBindings()
	end
end

function ShopConfigScreen:consoleCommandUIToggle()
	self:toggleHUDVisible()

	return "ShopConfigScreen hudVisible=" .. tostring(self.shopConfigContent:getIsVisible())
end

function ShopConfigScreen:inputEvent(action, value, eventUsed)
	eventUsed = ShopConfigScreen:superClass().inputEvent(self, action, value, eventUsed)

	if not eventUsed and action == InputAction.TOGGLE_STORE then
		self:onClickBack()
	end

	return eventUsed
end

ShopConfigScreen.GUI_PROFILE = {
	ADDITIONAL_WEIGHT = "shopConfigAttributeIconAdditionalWeight",
	METHANE = "shopConfigAttributeIconMethane",
	BALEWRAPPER_SIZE_SQUARE = "shopConfigAttributeIconBaleWrapperBaleSizeSquare",
	BALE_SIZE_SQUARE = "shopConfigAttributeIconBaleSizeSquare",
	WHEELS = "shopConfigAttributeIconWheels",
	CAPACITY = "shopConfigAttributeIconCapacity",
	SHOP_MONEY = "shopMoney",
	POWER_REQUIREMENT = "shopConfigAttributeIconPowerReq",
	WORKING_WIDTH = "shopConfigAttributeIconWorkingWidth",
	BUTTON_BUY = "buttonBuy",
	BUTTON_CONFIGURE = "buttonConfigurate",
	TRANSMISSION = "shopConfigAttributeIconTransmission",
	MAX_SPEED = "shopConfigAttributeIconMaxSpeed",
	POWER = "shopConfigAttributeIconPower",
	WEIGHT = "shopConfigAttributeIconWeight",
	BALE_SIZE_ROUND = "shopConfigAttributeIconBaleSizeRound",
	MAINTENANCE_COST = "shopConfigAttributeIconMaintenanceCosts",
	WORKING_SPEED = "shopConfigAttributeIconWorkSpeed",
	FUEL = "shopConfigAttributeIconFuel",
	BALEWRAPPER_SIZE_ROUND = "shopConfigAttributeIconBaleWrapperBaleSizeRound",
	ELECTRICCHARGE = "shopConfigAttributeIconElectricCharge",
	SHOP_MONEY_NEGATIVE = "shopMoneyNeg"
}
ShopConfigScreen.L10N_SYMBOL = {
	MAINTENANCE_COST = "shop_maintenanceValue",
	UNIT_KG = "unit_kg",
	UNIT_LITER = "unit_literShort",
	BUTTON_BUY = "button_buy",
	CONFIRM_LEASE = "shop_doYouWantToLease",
	CAPACITY = "shop_capacityValue",
	CONFIGURATION_LABEL = "shop_configuration",
	POWER_REQUIREMENT = "shopConfig_neededPowerValue",
	WORKING_WIDTH = "shop_workingWidthValue",
	NOT_ENOUGH_MONEY_BUY = "shop_messageNotEnoughMoneyToBuy",
	CONFIRM_BUY = "shop_doYouWantToBuy",
	NOT_ENOUGH_MONEY_LEASE = "shop_messageNotEnoughMoneyToLease",
	BUTTON_CONFIGURE = "button_configurate",
	FUEL_DEF = "shopConfig_fuelDefValue",
	UNIT_KW = "unit_kw",
	MAX_SPEED = "shop_maxSpeed",
	POWER = "shopConfig_maxPowerValue",
	DEF_SHORT = "fillType_def_short",
	WORKING_SPEED = "shop_maxSpeed",
	FUEL = "shop_fuelValue",
	TOO_FEW_SLOTS = "shop_messageNotEnoughSlotsToBuy"
}
ShopConfigScreen.SIZE = {
	INPUT_GLYPH = {
		48,
		48
	}
}
