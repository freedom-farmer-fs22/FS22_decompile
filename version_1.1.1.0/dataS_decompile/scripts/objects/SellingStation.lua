SellingStation = {
	PRICE_FALLING = 1,
	PRICE_CLIMBING = 2,
	PRICE_LOW = 3,
	PRICE_HIGH = 4,
	PRICE_GREAT_DEMAND = 5,
	PRICE_DROP_DELAY = 3600000
}
local SellingStation_mt = Class(SellingStation, UnloadingStation)

InitStaticObjectClass(SellingStation, "SellingStation", ObjectIds.OBJECT_SELLING_STATION)

function SellingStation.new(isServer, isClient, customMt)
	local self = UnloadingStation.new(isServer, isClient, customMt or SellingStation_mt)
	self.lastMoneyChange = -1
	self.incomeName = "harvestIncome"
	self.incomeNameWool = "soldWool"
	self.incomeNameMilk = "soldMilk"
	self.incomeNameBale = "soldBales"
	self.incomeNameProduct = "soldProducts"
	self.isSellingPoint = true
	self.storeSoldGoods = false
	self.skipSell = false

	return self
end

function SellingStation:load(components, xmlFile, key, customEnv, i3dMappings, rootNode)
	if not SellingStation:superClass().load(self, components, xmlFile, key, customEnv, i3dMappings, rootNode) then
		return false
	end

	if #self.unloadTriggers == 0 then
		local fillTypeCategories = xmlFile:getValue(key .. "#fillTypeCategories")
		local fillTypeNames = xmlFile:getValue(key .. "#fillTypes")

		if fillTypeCategories ~= nil then
			for _, fillType in pairs(g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: SellingStation has invalid fillTypeCategory '%s'.")) do
				self.supportedFillTypes[fillType] = true
			end
		end

		if fillTypeNames ~= nil then
			for _, fillType in pairs(g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: SellingStation has invalid fillType '%s'.")) do
				self.supportedFillTypes[fillType] = true
			end
		end
	end

	self.appearsOnStats = xmlFile:getValue(key .. "#appearsOnStats", false)
	self.suppressWarnings = xmlFile:getValue(key .. "#suppressWarnings", false)
	self.hasDynamic = xmlFile:getValue(key .. "#hasDynamic", true)
	local litersForFullPriceDrop = xmlFile:getValue(key .. "#litersForFullPriceDrop")

	if litersForFullPriceDrop ~= nil then
		self.priceDropPerLiter = (1 - EconomyManager.PRICE_DROP_MIN_PERCENT) / litersForFullPriceDrop
	end

	local fullPriceRecoverHours = xmlFile:getValue(key .. "#fullPriceRecoverHours")

	if fullPriceRecoverHours ~= nil then
		self.priceRecoverPerSecond = (1 - EconomyManager.PRICE_DROP_MIN_PERCENT) / (fullPriceRecoverHours * 60 * 60)
	else
		self.priceRecoverPerSecond = 1
	end

	self.acceptedFillTypes = {}
	self.numFillTypesForSelling = 0
	self.fillTypeSupportsGreatDemand = {}
	self.priceDropDisabled = {}
	self.originalFillTypePricesUnscaled = {}
	self.originalFillTypePrices = {}
	self.fillTypePrices = {}
	self.fillTypePriceInfo = {}
	self.fillTypePriceRandomDelta = {}
	self.priceMultipliers = {}
	self.totalReceived = {}
	self.totalPaid = {}
	self.pendingPriceDrop = {}
	self.prevFillLevel = {}
	self.prevTotalReceived = {}
	self.prevTotalPaid = {}
	self.missions = {}

	xmlFile:iterate(key .. ".fillType", function (_, fillTypeKey)
		local fillTypeStr = xmlFile:getValue(fillTypeKey .. "#name")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)

		if fillTypeIndex ~= nil then
			if self.supportedFillTypes[fillTypeIndex] ~= nil then
				local priceScale = xmlFile:getValue(fillTypeKey .. "#priceScale", 1)
				local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
				local price = fillType.pricePerLiter * priceScale
				local supportsGreatDemand = xmlFile:getValue(fillTypeKey .. "#supportsGreatDemand", false)
				local disablePriceDrop = xmlFile:getValue(fillTypeKey .. "#disablePriceDrop", false)

				self:addAcceptedFillType(fillTypeIndex, price, supportsGreatDemand, disablePriceDrop)
			else
				Logging.xmlWarning(xmlFile, "FillType '%s' is not supported by unload triggers for selling station", fillTypeStr)
			end
		else
			Logging.xmlWarning(xmlFile, "Invalid fillType '%s' in '%s'", fillTypeStr, fillTypeKey)
		end
	end)

	for fillTypeIndex, _ in pairs(self.supportedFillTypes) do
		if self.acceptedFillTypes[fillTypeIndex] == nil then
			local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
			local price = fillType.pricePerLiter

			self:addAcceptedFillType(fillTypeIndex, price, false, false)
		end
	end

	self.moneyChangeType = MoneyType.getMoneyType("soldMaterials", "finance_other")
	self.priceDropTimer = 0
	self.pricingDynamics = {}

	self:initPricingDynamics()

	self.priceSyncTimerDuration = 30000
	self.priceSyncTimer = self.priceSyncTimerDuration
	self.unloadingStationDirtyFlag = self:getNextDirtyFlag()

	g_currentMission.economyManager:addSellingStation(self)

	return true
end

function SellingStation:addAcceptedFillType(fillType, priceUnscaled, supportsGreatDemand, disablePriceDrop)
	if fillType ~= nil and self.acceptedFillTypes[fillType] == nil then
		self.acceptedFillTypes[fillType] = true
		self.fillTypeSupportsGreatDemand[fillType] = supportsGreatDemand

		if supportsGreatDemand then
			self.supportsGreatDemand = true
		end

		local price = priceUnscaled
		self.priceDropDisabled[fillType] = disablePriceDrop
		self.originalFillTypePricesUnscaled[fillType] = priceUnscaled
		self.originalFillTypePrices[fillType] = price
		self.fillTypePrices[fillType] = price
		self.fillTypePriceInfo[fillType] = 0
		self.fillTypePriceRandomDelta[fillType] = 0
		self.priceMultipliers[fillType] = 1
		self.totalReceived[fillType] = 0
		self.totalPaid[fillType] = 0
		self.pendingPriceDrop[fillType] = 0
		self.prevFillLevel[fillType] = 0
		self.prevTotalReceived[fillType] = 0
		self.prevTotalPaid[fillType] = 0
		self.numFillTypesForSelling = 0

		for acceptedFillType, _ in pairs(self.acceptedFillTypes) do
			if self.originalFillTypePrices[acceptedFillType] > 0 then
				self.numFillTypesForSelling = self.numFillTypesForSelling + 1
			end
		end
	end
end

function SellingStation:readStream(streamId, connection)
	SellingStation:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local numFillTypes = streamReadUInt8(streamId)

		for i = 1, numFillTypes do
			local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
			self.fillTypePrices[fillType] = streamReadUInt16(streamId) / 1000
			self.fillTypePriceInfo[fillType] = streamReadUIntN(streamId, 6)
		end
	end
end

function SellingStation:writeStream(streamId, connection)
	SellingStation:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		streamWriteUInt8(streamId, self.numFillTypesForSelling)

		if self.numFillTypesForSelling > 0 then
			for fillType, _ in pairs(self.acceptedFillTypes) do
				if self.originalFillTypePrices[fillType] > 0 then
					streamWriteUIntN(streamId, fillType, FillTypeManager.SEND_NUM_BITS)
					streamWriteUInt16(streamId, math.floor(self:getEffectiveFillTypePrice(fillType) * 1000 + 0.5))
					streamWriteUIntN(streamId, self:getCurrentPricingTrend(fillType), 6)
				end
			end
		end
	end
end

function SellingStation:readUpdateStream(streamId, timestamp, connection)
	SellingStation:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() and streamReadBool(streamId) then
		local numFillTypes = streamReadUInt8(streamId)

		for i = 1, numFillTypes do
			local fillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
			self.fillTypePrices[fillType] = streamReadUInt16(streamId) / 1000
			self.fillTypePriceInfo[fillType] = streamReadUIntN(streamId, 6)
		end
	end
end

function SellingStation:writeUpdateStream(streamId, connection, dirtyMask)
	SellingStation:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, self.unloadingStationDirtyFlag) ~= 0) then
		streamWriteUInt8(streamId, self.numFillTypesForSelling)

		if self.numFillTypesForSelling > 0 then
			for fillType, _ in pairs(self.acceptedFillTypes) do
				if self.originalFillTypePrices[fillType] > 0 then
					streamWriteUIntN(streamId, fillType, FillTypeManager.SEND_NUM_BITS)
					streamWriteUInt16(streamId, math.floor(self:getEffectiveFillTypePrice(fillType) * 1000 + 0.5))
					streamWriteUIntN(streamId, self:getCurrentPricingTrend(fillType), 6)
				end
			end
		end
	end
end

function SellingStation:update(dt)
	if self.lastMoneyChange > 0 then
		self.lastMoneyChange = self.lastMoneyChange - 1

		if self.lastMoneyChange == 0 then
			g_currentMission:showMoneyChange(self.moneyChangeType, "finance_" .. self.lastIncomeName, false, self.lastMoneyChangeFarmId)
		end

		self:raiseActive()
	end
end

function SellingStation:updateSellingStation(dt, scaledDt)
	if self.isServer then
		self:updatePrices(scaledDt)

		if self.priceDropTimer > 0 then
			self.priceDropTimer = math.max(self.priceDropTimer - scaledDt, 0)
		end

		if self.priceDropTimer <= 0 then
			for fillType, _ in pairs(self.acceptedFillTypes) do
				if (not self.isGreatDemandActive or self.greatDemandFillType ~= fillType) and self.pendingPriceDrop[fillType] > 0 then
					self:executePriceDrop(self.pendingPriceDrop[fillType], fillType)

					self.pendingPriceDrop[fillType] = 0
				end
			end
		end

		if self.hasDynamic then
			self.priceSyncTimer = self.priceSyncTimer - dt

			if self.priceSyncTimer < 0 then
				self:raiseDirtyFlags(self.unloadingStationDirtyFlag)

				self.priceSyncTimer = self.priceSyncTimerDuration
			end
		end
	end
end

function SellingStation:loadFromXMLFile(xmlFile, key)
	local i = 0

	while true do
		local statsKey = string.format(key .. ".stats(%d)", i)

		if not xmlFile:hasProperty(statsKey) then
			break
		end

		local fillTypeStr = xmlFile:getValue(statsKey .. "#fillType")
		local fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)

		if fillType ~= nil and self.acceptedFillTypes[fillType] then
			self.totalReceived[fillType] = xmlFile:getValue(statsKey .. "#received", 0)
			self.totalPaid[fillType] = xmlFile:getValue(statsKey .. "#paid", 0)

			self.pricingDynamics[fillType]:loadFromXMLFile(xmlFile, statsKey)
		end

		i = i + 1
	end

	return true
end

function SellingStation:saveToXMLFile(xmlFile, key, usedModNames)
	local index = 0

	for fillTypeIndex, _ in pairs(self.acceptedFillTypes) do
		if self.originalFillTypePrices[fillTypeIndex] > 0 then
			local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillTypeIndex)
			local statsKey = string.format("%s.stats(%d)", key, index)

			xmlFile:setValue(statsKey .. "#fillType", fillTypeName)
			xmlFile:setValue(statsKey .. "#received", self.totalReceived[fillTypeIndex])
			xmlFile:setValue(statsKey .. "#paid", self.totalPaid[fillTypeIndex])
			self.pricingDynamics[fillTypeIndex]:saveToXMLFile(xmlFile, statsKey, usedModNames)

			index = index + 1
		end
	end
end

function SellingStation:getName()
	return self.stationName or self.owningPlaceable and self.owningPlaceable:getName() or "Selling Station"
end

function SellingStation:getIsFillTypeAllowed(fillTypeIndex, extraAttributes)
	if self.acceptedFillTypes[fillTypeIndex] then
		return true
	end

	return false
end

function SellingStation:addFillLevelFromTool(farmId, deltaFillLevel, fillType, fillInfo, toolType, extraAttributes)
	local movedFillLevel = 0

	if deltaFillLevel > 0 then
		local storageAccess = not self.storeSoldGoods or self.storeSoldGoods and self:getIsFillAllowedFromFarm(farmId)

		if self:getIsFillTypeAllowed(fillType, extraAttributes) and storageAccess then
			local usedByMission = false

			for _, mission in pairs(self.missions) do
				if mission.fillSold ~= nil and mission.fillType == fillType and mission.farmId == farmId then
					mission:fillSold(deltaFillLevel)

					usedByMission = true

					break
				end
			end

			if self.storeSoldGoods then
				movedFillLevel = SellingStation:superClass().addFillLevelFromTool(self, farmId, deltaFillLevel, fillType, fillInfo, toolType, extraAttributes)
			else
				movedFillLevel = deltaFillLevel

				self:startFx(fillType)
			end

			if not usedByMission and not self.skipSell and movedFillLevel > 0.001 then
				self:sellFillType(farmId, movedFillLevel, fillType, toolType, extraAttributes)
			end
		end
	end

	return movedFillLevel
end

function SellingStation:addTargetStorage(storage)
	if not self.storeSoldGoods then
		print("Error: UnloadingStation '" .. tostring(self:getName()) .. "' is a selling point which does not accept storages!")

		return false
	end

	return SellingStation:superClass().addTargetStorage(self, storage)
end

function SellingStation:sellFillType(farmId, fillDelta, fillTypeIndex, toolType, extraAttributes)
	if not self.priceDropDisabled[fillTypeIndex] then
		self:doPriceDrop(fillDelta, fillTypeIndex)
	end

	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	fillType.totalAmount = fillType.totalAmount + fillDelta
	self.totalReceived[fillTypeIndex] = self.totalReceived[fillTypeIndex] + fillDelta
	local pricePerLiter = self:getEffectiveFillTypePrice(fillTypeIndex, toolType)
	local priceScale = 1

	if extraAttributes ~= nil then
		pricePerLiter = extraAttributes.price or pricePerLiter
		priceScale = extraAttributes.priceScale or priceScale
	end

	local price = fillDelta * pricePerLiter * priceScale
	self.totalPaid[fillTypeIndex] = self.totalPaid[fillTypeIndex] + price
	self.lastIncomeName = self:getIncomeNameForFillType(fillTypeIndex, toolType)
	self.moneyChangeType.statistic = self.lastIncomeName

	g_currentMission:addMoney(price, farmId, self.moneyChangeType, true)

	self.lastMoneyChange = 30
	self.lastMoneyChangeFarmId = farmId

	self:raiseActive()

	return price
end

function SellingStation:getEffectiveFillTypePrice(fillType, toolType)
	if self.fillTypePrices[fillType] == nil then
		log("Missing filltype", g_fillTypeManager:getFillTypeNameByIndex(fillType), tostring(self:getName()))
		printCallstack()
	end

	if self.isServer then
		return (self.fillTypePrices[fillType] + self.fillTypePriceRandomDelta[fillType]) * self.priceMultipliers[fillType] * EconomyManager.getPriceMultiplier()
	else
		return self.fillTypePrices[fillType]
	end
end

function SellingStation:getIncomeNameForFillType(fillType, toolType)
	if toolType == ToolType.BALE then
		return self.incomeNameBale
	end

	if fillType == FillType.WOOL then
		return self.incomeNameWool
	end

	if fillType == FillType.MILK then
		return self.incomeNameMilk
	end

	if fillType == FillType.WOOD then
		return "soldWood"
	end

	if g_fillTypeManager:getIsFillTypeInCategory(fillType, "PRODUCT") then
		return self.incomeNameProduct
	end

	return self.incomeName
end

function SellingStation:initPricingDynamics()
	local timeScaling = 1
	local amp = 0.2
	local ampVar = 0.15
	local ampDist = PricingDynamics.AMP_DIST_LINEAR_DOWN
	local per = 172800000
	local perVar = 0.375 * per
	local perDist = PricingDynamics.AMP_DIST_CONSTANT
	local plateauFactor = 0.3
	local initialPlateauFraction = 0.75
	local amp2 = 0.1
	local ampVar2 = 0.02
	local ampDist2 = PricingDynamics.AMP_DIST_CONSTANT
	local per2 = 604800000
	local perVar2 = 0.2 * per2
	local perDist2 = PricingDynamics.AMP_DIST_CONSTANT
	self.levelThreshold = 0.8 * amp
	per = per / timeScaling
	perVar = perVar / timeScaling
	per2 = per2 / timeScaling
	perVar2 = perVar2 / timeScaling

	for fillType, _ in pairs(self.acceptedFillTypes) do
		self.pricingDynamics[fillType] = PricingDynamics.new(0, amp * self.originalFillTypePrices[fillType], ampVar * self.originalFillTypePrices[fillType], ampDist, per, perVar, perDist, plateauFactor, initialPlateauFraction)

		self.pricingDynamics[fillType]:addCurve(amp2 * self.originalFillTypePrices[fillType], ampVar2 * self.originalFillTypePrices[fillType], ampDist2, per2, perVar2, perDist2)
	end
end

function SellingStation:executePriceDrop(priceDrop, fillType)
	local lowestPrice = self.originalFillTypePrices[fillType] * EconomyManager.PRICE_DROP_MIN_PERCENT
	self.fillTypePrices[fillType] = math.max(self.fillTypePrices[fillType] - priceDrop, lowestPrice)
end

function SellingStation:doPriceDrop(fillLevel, fillType)
	if self.pendingPriceDrop[fillType] ~= nil and self.priceDropPerLiter ~= nil then
		self.pendingPriceDrop[fillType] = self.pendingPriceDrop[fillType] + self.priceDropPerLiter * fillLevel * self.originalFillTypePrices[fillType]
		self.priceDropTimer = SellingStation.PRICE_DROP_DELAY
	end
end

function SellingStation:updatePrices(dt)
	if self.numFillTypesForSelling > 0 and self.hasDynamic then
		local priceRecoverBase = self.priceRecoverPerSecond * dt * 0.001

		for fillType, _ in pairs(self.acceptedFillTypes) do
			if not self.isGreatDemandActive or self.greatDemandFillType ~= fillType then
				self.pricingDynamics[fillType]:update(dt)

				self.fillTypePriceRandomDelta[fillType] = self.pricingDynamics[fillType]:evaluate()
				self.fillTypePriceInfo[fillType] = Utils.clearBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_CLIMBING)
				self.fillTypePriceInfo[fillType] = Utils.clearBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_FALLING)

				if self.pricingDynamics[fillType]:getBaseCurveTrend() == PricingDynamics.TREND_FALLING then
					self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_FALLING)
				elseif self.pricingDynamics[fillType]:getBaseCurveTrend() == PricingDynamics.TREND_CLIMBING then
					self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_CLIMBING)
				end

				local priceRecover = priceRecoverBase * self.originalFillTypePrices[fillType]
				self.fillTypePrices[fillType] = math.min(self.fillTypePrices[fillType] + priceRecover, self.originalFillTypePrices[fillType])
				self.fillTypePriceInfo[fillType] = Utils.clearBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_LOW)
				self.fillTypePriceInfo[fillType] = Utils.clearBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_HIGH)
				local correctedDelta = self.fillTypePriceRandomDelta[fillType] - (self.originalFillTypePrices[fillType] - self.fillTypePrices[fillType])

				if self.levelThreshold < correctedDelta then
					self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_HIGH)
				elseif correctedDelta < -self.levelThreshold then
					self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_LOW)
				end
			end
		end
	end
end

function SellingStation:setPriceMultiplier(fillType, priceMultiplier)
	self.priceMultipliers[fillType] = priceMultiplier
end

function SellingStation:getSupportsGreatDemand(fillType)
	if fillType == nil or self.fillTypeSupportsGreatDemand[fillType] == nil then
		return false
	end

	return self.fillTypeSupportsGreatDemand[fillType]
end

function SellingStation:setIsInGreatDemand(fillType, isInGreatDemand)
	if isInGreatDemand then
		self.fillTypePriceInfo[fillType] = Utils.setBit(self.fillTypePriceInfo[fillType], SellingStation.PRICE_GREAT_DEMAND)
		self.isGreatDemandActive = true
		self.greatDemandFillType = fillType
	else
		if self.greatDemandFillType ~= nil and self.fillTypePriceInfo[self.greatDemandFillType] ~= nil then
			self.fillTypePriceInfo[self.greatDemandFillType] = Utils.clearBit(self.fillTypePriceInfo[self.greatDemandFillType], SellingStation.PRICE_GREAT_DEMAND)
		end

		self.isGreatDemandActive = false
		self.greatDemandFillType = FillType.UNKNOWN
	end

	self:raiseDirtyFlags(self.unloadingStationDirtyFlag)

	self.priceSyncTimer = self.priceSyncTimerDuration
end

function SellingStation:getPriceMultiplier(fillType)
	return self.priceMultipliers[fillType]
end

function SellingStation:getTotalReceived(fillType)
	return self.totalReceived[fillType]
end

function SellingStation:getTotalPaid(fillType)
	return self.totalPaid[fillType]
end

function SellingStation:getCurrentPricingTrend(fillType)
	return self.fillTypePriceInfo[fillType]
end

function SellingStation:getFreeCapacity(fillTypeIndex)
	return math.huge
end

function SellingStation:getIsFillAllowedFromFarm(farmId)
	if self.storeSoldGoods then
		return SellingStation:superClass().getIsFillAllowedFromFarm(self, farmId)
	end

	return true
end

function SellingStation:getAppearsOnStats()
	return self.appearsOnStats
end

function SellingStation.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. "#appearsOnStats", "Appears on Stats", false)
	schema:register(XMLValueType.BOOL, basePath .. "#suppressWarnings", "Suppress warnings", false)
	schema:register(XMLValueType.BOOL, basePath .. "#hasDynamic", "Has dynamic prices", true)
	schema:register(XMLValueType.INT, basePath .. "#litersForFullPriceDrop", "Liters for full price drop")
	schema:register(XMLValueType.FLOAT, basePath .. "#fullPriceRecoverHours", "Full price recover ingame hours")
	schema:register(XMLValueType.STRING, basePath .. "#fillTypeCategories", "Supported filltypes if no unloadtriggers defined")
	schema:register(XMLValueType.STRING, basePath .. "#fillTypes", "Supported filltypes if no unloadtriggers defined")
	schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#name", "Fill type name")
	schema:register(XMLValueType.FLOAT, basePath .. ".fillType(?)#priceScale", "Price scale", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".fillType(?)#supportsGreatDemand", "Supports great demand", false)
	schema:register(XMLValueType.BOOL, basePath .. ".fillType(?)#disablePriceDrop", "Disable price drop", false)
	UnloadingStation.registerXMLPaths(schema, basePath)
end

function SellingStation.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".stats(?)#fillType", "Fill type")
	schema:register(XMLValueType.FLOAT, basePath .. ".stats(?)#received", "Recieved fill level", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".stats(?)#paid", "Payed fill level", 0)
	PricingDynamics.registerSavegameXMLPaths(schema, basePath .. ".stats(?)")
end

function SellingStation.loadSpecValueFillTypes(xmlFile, customEnvironment)
	local fillTypeNames = nil
	local fillTypesNamesString = xmlFile:getValue("placeable.sellingStation#fillTypes")

	if fillTypesNamesString ~= nil and fillTypesNamesString:trim() ~= "" then
		fillTypeNames = {}

		for _, fillTypeName in pairs(string.split(fillTypesNamesString, " ")) do
			fillTypeNames[fillTypeName] = true
		end
	end

	xmlFile:iterate("placeable.sellingStation.unloadTrigger", function (_, unloadTriggerKey)
		local fillTypeNamesString = xmlFile:getValue(unloadTriggerKey .. "#fillTypes")

		if fillTypeNamesString ~= nil and fillTypeNamesString:trim() ~= "" then
			fillTypeNames = fillTypeNames or {}

			for _, fillTypeName in pairs(string.split(fillTypeNamesString, " ")) do
				fillTypeNames[fillTypeName] = true
			end
		end
	end)

	return fillTypeNames
end

function SellingStation.getSpecValueFillTypes(storeItem, realItem)
	if storeItem.specs.sellingStationFillTypes == nil then
		return nil
	end

	return g_fillTypeManager:getFillTypesByNames(table.concatKeys(storeItem.specs.sellingStationFillTypes, " "))
end
