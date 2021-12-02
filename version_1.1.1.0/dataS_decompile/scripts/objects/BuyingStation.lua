BuyingStation = {}
local BuyingStation_mt = Class(BuyingStation, LoadingStation)

InitStaticObjectClass(BuyingStation, "BuyingStation", ObjectIds.OBJECT_BUYING_STATION)

function BuyingStation.new(isServer, isClient, customMt)
	local self = LoadingStation.new(isServer, isClient, customMt or BuyingStation_mt)
	self.incomeName = "other"
	self.incomeNameFuel = "purchaseFuel"
	self.incomeNameLime = "other"

	return self
end

function BuyingStation:load(components, xmlFile, key, customEnv, i3dMappings)
	if not BuyingStation:superClass().load(self, components, xmlFile, key, customEnv, i3dMappings) then
		return false
	end

	self.lastMoneyChange = 0
	self.providedFillTypes = {}
	self.fillTypePricesScale = {}
	self.fillTypeStatsName = {}
	local i = 0

	while true do
		local fillTypeKey = string.format(key .. ".fillType(%d)", i)

		if not xmlFile:hasProperty(fillTypeKey) then
			break
		end

		local fillTypeStr = xmlFile:getValue(fillTypeKey .. "#name")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)
		local fillTypeStatsName = xmlFile:getValue(fillTypeKey .. "#statsName", "other")

		if fillTypeIndex ~= nil then
			if self.supportedFillTypes[fillTypeIndex] ~= nil then
				local priceScale = xmlFile:getValue(fillTypeKey .. "#priceScale", 1)
				self.fillTypePricesScale[fillTypeIndex] = priceScale
				self.fillTypeStatsName[fillTypeIndex] = fillTypeStatsName
				self.providedFillTypes[fillTypeIndex] = true
			else
				Logging.xmlWarning(xmlFile, "FillType '%s' is not supported by loading triggers for buying station", fillTypeStr)
			end
		end

		i = i + 1
	end

	self.moneyChangeType = MoneyType.getMoneyType("other", "finance_other")

	return true
end

function BuyingStation:update(dt)
	if self.lastMoneyChange > 0 then
		self.lastMoneyChange = self.lastMoneyChange - 1

		if self.lastMoneyChange == 0 then
			g_currentMission:showMoneyChange(self.moneyChangeType, "finance_" .. self.lastIncomeName, false, self.lastMoneyChangeFarmId)
		end

		self:raiseActive()
	end
end

function BuyingStation:addSourceStorage(storage)
	print("Error: LoadingStation '" .. tostring(self:getName()) .. "' is a buying point and does not accept any storages!")

	return false
end

function BuyingStation:getAllFillLevels()
	local fillLevels = {}
	local capacity = 1

	for fillType, _ in pairs(self.supportedFillTypes) do
		fillLevels[fillType] = 1
	end

	return fillLevels, capacity
end

function BuyingStation:getEffectiveFillTypePrice(fillTypeIndex)
	local fillType = g_fillTypeManager:getFillTypeByIndex(fillTypeIndex)
	local pricePerLiter = self.fillTypePricesScale[fillTypeIndex] * fillType.pricePerLiter

	return pricePerLiter
end

function BuyingStation:addFillLevelToFillableObject(fillableObject, fillUnitIndex, fillTypeIndex, fillDelta, fillInfo, toolType)
	if fillableObject == nil or fillTypeIndex == FillType.UNKNOWN or fillDelta == 0 or toolType == nil then
		return 0
	end

	local farmId = fillableObject:getOwnerFarmId()

	if g_currentMission:getMoney(farmId) > 0 then
		fillDelta = fillableObject:addFillUnitFillLevel(farmId, fillUnitIndex, fillDelta, fillTypeIndex, toolType, fillInfo)

		if fillDelta > 0 then
			local price = self:getEffectiveFillTypePrice(fillTypeIndex) * fillDelta
			self.lastIncomeName = self:getIncomeNameForFillType(fillTypeIndex, toolType)
			self.moneyChangeType.statistic = self.lastIncomeName

			g_currentMission:addMoney(-price, farmId, self.moneyChangeType, true)

			self.lastMoneyChangeFarmId = farmId
			self.lastMoneyChange = 30

			self:raiseActive()
		end
	else
		fillDelta = 0
	end

	return fillDelta
end

function BuyingStation:getIncomeNameForFillType(fillType, toolType)
	if fillType == FillType.DIESEL then
		return self.incomeNameFuel
	end

	if fillType == FillType.LIME then
		return self.incomeNameLime
	end

	return self.incomeName
end

function BuyingStation:getIsFillAllowedToFarm(farmId)
	return true
end

function BuyingStation:getIsFillTypeSupported(fillType)
	return self.providedFillTypes[fillType] == true
end

function BuyingStation.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#name", "Fill type name")
	schema:register(XMLValueType.STRING, basePath .. ".fillType(?)#statsName", "Name in stats", "other")
	schema:register(XMLValueType.FLOAT, basePath .. ".fillType(?)#priceScale", "Price scale", 1)
	LoadingStation.registerXMLPaths(schema, basePath)
end
