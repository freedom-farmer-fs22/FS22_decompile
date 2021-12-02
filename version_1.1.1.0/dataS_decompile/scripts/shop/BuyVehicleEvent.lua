BuyVehicleEvent = {}
local BuyVehicleEvent_mt = Class(BuyVehicleEvent, Event)
BuyVehicleEvent.STATE_SUCCESS = 0
BuyVehicleEvent.STATE_FAILED_TO_LOAD = 1
BuyVehicleEvent.STATE_NO_SPACE = 2
BuyVehicleEvent.STATE_NO_PERMISSION = 3
BuyVehicleEvent.STATE_NOT_ENOUGH_MONEY = 4

InitStaticEventClass(BuyVehicleEvent, "BuyVehicleEvent", EventIds.EVENT_BUY_VEHICLE)

function BuyVehicleEvent.emptyNew()
	local self = Event.new(BuyVehicleEvent_mt)

	return self
end

function BuyVehicleEvent.new(filename, outsideBuy, configurations, leaseVehicle, ownerFarmId, licensePlateData, saleItem)
	local self = BuyVehicleEvent.emptyNew()
	self.filename = filename
	self.outsideBuy = outsideBuy
	self.configurations = Utils.getNoNil(configurations, {})
	self.leaseVehicle = Utils.getNoNil(leaseVehicle, false)
	self.ownerFarmId = ownerFarmId
	self.licensePlateData = licensePlateData
	self.saleItem = saleItem

	return self
end

function BuyVehicleEvent.newServerToClient(errorCode, filename, leaseVehicle, price)
	local self = BuyVehicleEvent.emptyNew()
	self.filename = filename
	self.errorCode = errorCode
	self.leaseVehicle = leaseVehicle
	self.price = price

	return self
end

function BuyVehicleEvent:readStream(streamId, connection)
	self.filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))

	if not connection:getIsServer() then
		self.outsideBuy = streamReadBool(streamId)
		local numConfigurations = streamReadUInt8(streamId)
		self.configurations = {}

		for i = 1, numConfigurations do
			local name = g_configurationManager:getConfigurationNameByIndex(streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS))
			local id = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)
			self.configurations[name] = id
		end

		self.leaseVehicle = streamReadBool(streamId)
		self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.licensePlateData = LicensePlateManager.readLicensePlateData(streamId, connection)
		local saleId = streamReadUInt8(streamId)

		if saleId ~= 0 then
			self.saleItem = g_currentMission.vehicleSaleSystem:getSaleById(saleId)
		end
	else
		self.errorCode = streamReadUIntN(streamId, 3)
		self.leaseVehicle = streamReadBool(streamId)
		self.price = streamReadInt32(streamId)
	end

	self:run(connection)
end

function BuyVehicleEvent:writeStream(streamId, connection)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.filename))

	if connection:getIsServer() then
		streamWriteBool(streamId, self.outsideBuy)

		local config = {}

		for name, id in pairs(Utils.getNoNil(self.configurations, {})) do
			table.insert(config, {
				nameId = g_configurationManager:getConfigurationIndexByName(name),
				configId = id
			})
		end

		streamWriteUInt8(streamId, #config)

		for i = 1, #config do
			streamWriteUIntN(streamId, config[i].nameId, ConfigurationUtil.SEND_NUM_BITS)
			streamWriteUIntN(streamId, config[i].configId, ConfigurationUtil.SEND_NUM_BITS)
		end

		streamWriteBool(streamId, self.leaseVehicle)
		streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		LicensePlateManager.writeLicensePlateData(streamId, connection, self.licensePlateData)

		if self.saleItem ~= nil then
			streamWriteUInt8(streamId, self.saleItem.id)
		else
			streamWriteUInt8(streamId, 0)
		end
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
		streamWriteBool(streamId, self.leaseVehicle)
		streamWriteInt32(streamId, self.price)
	end
end

function BuyVehicleEvent:run(connection)
	if not connection:getIsServer() then
		if g_currentMission:getHasPlayerPermission(Farm.PERMISSION.BUY_VEHICLE, connection) then
			self.filename = self.filename:lower()
			local dataStoreItem = g_storeManager:getItemByXMLFilename(self.filename)

			if dataStoreItem ~= nil then
				local propertyState = Vehicle.PROPERTY_STATE_OWNED
				local price, _ = g_currentMission.economyManager:getBuyPrice(dataStoreItem, self.configurations, self.saleItem)
				local payedPrice = price

				if self.leaseVehicle then
					propertyState = Vehicle.PROPERTY_STATE_LEASED
					payedPrice = g_currentMission.economyManager:getInitialLeasingPrice(price)
				end

				if payedPrice <= g_currentMission:getMoney(self.ownerFarmId) then
					if not GS_IS_CONSOLE_VERSION or fileExists(dataStoreItem.xmlFilename) then
						local asyncParams = {
							targetOwner = self,
							connection = connection,
							leaseVehicle = self.leaseVehicle,
							outsideBuy = self.outsideBuy,
							price = payedPrice,
							ownerFarmId = self.ownerFarmId,
							filename = self.filename,
							licensePlateData = self.licensePlateData
						}

						VehicleLoadingUtil.loadVehiclesAtPlace(dataStoreItem, g_currentMission.storeSpawnPlaces, g_currentMission.usedStorePlaces, self.configurations, price, propertyState, self.ownerFarmId, self.saleItem, self.onVehicleBoughtCallback, self, asyncParams)
					end
				else
					connection:sendEvent(BuyVehicleEvent.newServerToClient(BuyVehicleEvent.STATE_NOT_ENOUGH_MONEY, self.filename, self.leaseVehicle, payedPrice))
				end
			end
		else
			connection:sendEvent(BuyVehicleEvent.newServerToClient(BuyVehicleEvent.STATE_NO_PERMISSION, self.filename, self.leaseVehicle, 0))
		end
	else
		g_messageCenter:publish(BuyVehicleEvent, self.errorCode, self.leaseVehicle, self.price, self.licensePlateData)
	end
end

function BuyVehicleEvent:onVehicleBoughtCallback(code, params)
	local errorCode = BuyVehicleEvent.STATE_FAILED_TO_LOAD

	if code == VehicleLoadingUtil.VEHICLE_LOAD_OK then
		if not params.outsideBuy then
			if not params.leaseVehicle then
				local dataStoreItem = g_storeManager:getItemByXMLFilename(self.filename)
				local financeCategory = MoneyType.getMoneyTypeByName(dataStoreItem.financeCategory) or MoneyType.SHOP_VEHICLE_BUY

				g_currentMission:addMoney(-params.price, params.ownerFarmId, financeCategory, true)

				if self.saleItem ~= nil then
					g_currentMission.vehicleSaleSystem:onVehicleBought(self.saleItem)
				end

				local serverFarmId = g_currentMission:getFarmId()
				local numDrivables = 0
				local numVehicles = 0

				for _, item in ipairs(g_currentMission.vehicles) do
					if item:getOwnerFarmId() == serverFarmId then
						if item.spec_drivable ~= nil then
							numDrivables = numDrivables + 1
							numVehicles = numVehicles + 1
						elseif item.spec_attachable ~= nil and item.spec_bigBag == nil then
							numVehicles = numVehicles + 1
						end
					end
				end

				g_achievementManager:tryUnlock("NumDrivables", numDrivables)
				g_achievementManager:tryUnlock("NumVehiclesSmall", numVehicles)
				g_achievementManager:tryUnlock("NumVehiclesLarge", numVehicles)
			else
				g_currentMission:addMoney(-params.price, params.ownerFarmId, MoneyType.LEASING_COSTS, true)
			end
		end

		errorCode = BuyVehicleEvent.STATE_SUCCESS
	elseif code == VehicleLoadingUtil.VEHICLE_LOAD_NO_SPACE then
		errorCode = BuyVehicleEvent.STATE_NO_SPACE
	end

	params.connection:sendEvent(BuyVehicleEvent.newServerToClient(errorCode, params.filename, params.leaseVehicle, params.price))
end
