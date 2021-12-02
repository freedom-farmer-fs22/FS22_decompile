ChangeVehicleConfigEvent = {}
local ChangeVehicleConfigEvent_mt = Class(ChangeVehicleConfigEvent, Event)

InitStaticEventClass(ChangeVehicleConfigEvent, "ChangeVehicleConfigEvent", EventIds.EVENT_CHANGE_VEHICLE_CONFIG)

function ChangeVehicleConfigEvent.emptyNew()
	local self = Event.new(ChangeVehicleConfigEvent_mt)

	return self
end

function ChangeVehicleConfigEvent.new(vehicle, price, farmId, configurations, licensePlateData)
	local self = ChangeVehicleConfigEvent.emptyNew()
	self.vehicle = vehicle
	self.farmId = farmId
	self.configurations = configurations
	self.licensePlateData = licensePlateData
	self.price = price

	return self
end

function ChangeVehicleConfigEvent.newServerToClient(successful)
	local self = ChangeVehicleConfigEvent.emptyNew()
	self.successful = successful

	return self
end

function ChangeVehicleConfigEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.vehicle = NetworkUtil.readNodeObject(streamId)
		self.price = streamReadFloat32(streamId)
		self.farmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		local numConfigurations = streamReadUInt8(streamId)
		self.configurations = {}

		for _ = 1, numConfigurations do
			local name = g_configurationManager:getConfigurationNameByIndex(streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS))
			local id = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)
			self.configurations[name] = id
		end

		self.licensePlateData = LicensePlateManager.readLicensePlateData(streamId, connection)
	else
		self.successful = streamReadBool(streamId)
	end

	self:run(connection)
end

function ChangeVehicleConfigEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		NetworkUtil.writeNodeObject(streamId, self.vehicle)
		streamWriteFloat32(streamId, self.price)
		streamWriteUIntN(streamId, self.farmId, FarmManager.FARM_ID_SEND_NUM_BITS)

		local numConfigurations = 0

		for _, _ in pairs(self.configurations) do
			numConfigurations = numConfigurations + 1
		end

		streamWriteUInt8(streamId, numConfigurations)

		for configName, configId in pairs(self.configurations) do
			streamWriteUIntN(streamId, g_configurationManager:getConfigurationIndexByName(configName), ConfigurationUtil.SEND_NUM_BITS)
			streamWriteUIntN(streamId, configId, ConfigurationUtil.SEND_NUM_BITS)
		end

		LicensePlateManager.writeLicensePlateData(streamId, connection, self.licensePlateData)
	else
		streamWriteBool(streamId, self.successful)
	end
end

function ChangeVehicleConfigEvent:run(connection)
	if not connection:getIsServer() then
		local success = false
		local vehicle = self.vehicle

		if vehicle ~= nil and vehicle.isVehicleSaved and not vehicle.isControlled and g_currentMission:getHasPlayerPermission("buyVehicle", connection) then
			for configName, configId in pairs(self.configurations) do
				ConfigurationUtil.addBoughtConfiguration(vehicle, configName, configId)
				ConfigurationUtil.setConfiguration(vehicle, configName, configId)
			end

			vehicle:setLicensePlatesData(self.licensePlateData)

			vehicle.isReconfigurating = true

			g_server:broadcastEvent(VehicleSetIsReconfiguratingEvent.new(vehicle), nil, , vehicle)

			local xmlFile = Vehicle.getReloadXML(vehicle)
			local key = "vehicles.vehicle(0)"

			local function asyncCallbackFunction(_, newVehicle, vehicleLoadState, arguments)
				if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_OK then
					success = true

					g_currentMission:addMoney(-self.price, self.farmId, MoneyType.SHOP_VEHICLE_BUY, true)
					vehicle:removeFromPhysics()
					g_currentMission:removeVehicle(vehicle)
				else
					g_currentMission:removeVehicle(newVehicle)
					vehicle:addToPhysics()
				end

				xmlFile:delete()
				connection:sendEvent(ChangeVehicleConfigEvent.newServerToClient(success))
			end

			VehicleLoadingUtil.loadVehicleFromSavegameXML(xmlFile, key, false, false, nil, , asyncCallbackFunction, nil, {})
		else
			connection:sendEvent(ChangeVehicleConfigEvent.newServerToClient(false))
		end

		return
	end

	g_workshopScreen:onVehicleChanged(self.successful)
end
