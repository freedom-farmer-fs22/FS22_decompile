VehicleSaleSystem = {
	MINIMUM_ITEM_VALUE = 10000,
	MAX_MULTIPLAYER_ITEMS = 20,
	MIN_MULTIPLAYER_ITEM_DURATION = 20,
	MAX_MULTIPLAYER_ITEM_DURATION = 40,
	MULTIPLAYER_ACCEPT_CHANCE = 0.8,
	MAX_GENERATED_ITEMS = 5,
	MIN_GENERATED_ITEM_DURATION = 20,
	MAX_GENERATED_ITEM_DURATION = 40
}
VehicleSaleSystem.GENERATED_HOURLY_CHANCE = 3 / VehicleSaleSystem.MIN_GENERATED_ITEM_DURATION
VehicleSaleSystem.BUYPRICE_FACTOR = 1.1
local VehicleSaleSystem_mt = Class(VehicleSaleSystem)

function VehicleSaleSystem.new(mission)
	local self = setmetatable({}, VehicleSaleSystem_mt)
	self.mission = mission
	self.items = {}
	self.numGeneratedItems = 0
	self.numMultiplayerItems = 0
	self.nextFreeId = 1
	self.freeIds = {}

	g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.onHourChanged, self)

	return self
end

function VehicleSaleSystem:delete(customMt)
	g_messageCenter:unsubscribeAll(self)
end

function VehicleSaleSystem:loadFromXMLFile(xmlFilename)
	local xmlFile = XMLFile.loadIfExists("vehicleSaleXML", xmlFilename)

	if xmlFile == nil then
		self:generateInitialSales()

		return false
	end

	xmlFile:iterate("sales.item", function (_, key)
		local item = {
			id = #self.items + 1,
			timeLeft = xmlFile:getInt(key .. "#timeLeft"),
			isGenerated = xmlFile:getBool(key .. "#isGenerated"),
			xmlFilename = xmlFile:getString(key .. "#xmlFilename"),
			boughtConfigurations = {},
			age = xmlFile:getInt(key .. "#age"),
			price = xmlFile:getInt(key .. "#price"),
			damage = xmlFile:getFloat(key .. "#damage"),
			wear = xmlFile:getFloat(key .. "#wear"),
			operatingTime = xmlFile:getFloat(key .. "#operatingTime") * 1000
		}
		local storeItem = g_storeManager:getItemByXMLFilename(item.xmlFilename)

		if storeItem == nil then
			Logging.xmlWarning(xmlFile, "Store item for sale item '%s' could not be found, ignoring this item", item.xmlFilename)
		else
			xmlFile:iterate(key .. ".boughtConfiguration", function (_, cKey)
				local name = xmlFile:getString(cKey .. "#name")
				local value = xmlFile:getString(cKey .. "#id")

				if storeItem.configurations[name] == nil then
					return
				end

				local id = nil

				for _, config in ipairs(storeItem.configurations[name]) do
					if config.saveId == value then
						id = config.index

						break
					end
				end

				if id ~= nil then
					if item.boughtConfigurations[name] == nil then
						item.boughtConfigurations[name] = {}
					end

					item.boughtConfigurations[name][id] = true
				end
			end)

			if item.isGenerated then
				self.numGeneratedItems = self.numGeneratedItems + 1
			else
				self.numMultiplayerItems = self.numMultiplayerItems + 1
			end

			table.insert(self.items, item)
		end
	end)

	self.nextFreeId = #self.items + 1

	xmlFile:delete()

	return true
end

function VehicleSaleSystem:saveToXMLFile(xmlFilename)
	local xmlFile = XMLFile.create("vehicleSaleXML", xmlFilename, "sales")

	if xmlFile == nil then
		return
	end

	xmlFile:setSortedTable("sales.item", self.items, function (key, item, _)
		xmlFile:setInt(key .. "#timeLeft", item.timeLeft)
		xmlFile:setBool(key .. "#isGenerated", item.isGenerated)
		xmlFile:setString(key .. "#xmlFilename", item.xmlFilename)
		xmlFile:setInt(key .. "#age", item.age)
		xmlFile:setInt(key .. "#price", item.price)
		xmlFile:setFloat(key .. "#damage", item.damage)
		xmlFile:setFloat(key .. "#wear", item.wear)
		xmlFile:setFloat(key .. "#operatingTime", item.operatingTime / 1000)

		local storeItem = g_storeManager:getItemByXMLFilename(item.xmlFilename)
		local i = 0

		for name, ids in pairs(item.boughtConfigurations) do
			for id, _ in pairs(ids) do
				local cKey = string.format("%s.boughtConfiguration(%d)", key, i)

				xmlFile:setString(cKey .. "#name", name)
				xmlFile:setString(cKey .. "#id", tostring(storeItem.configurations[name][id].saveId))

				i = i + 1
			end
		end
	end)
	xmlFile:save()
	xmlFile:delete()

	return true
end

function VehicleSaleSystem:sendAllToClient(connection)
	for i = 1, #self.items do
		connection:sendEvent(VehicleSaleAddEvent.new(self.items[i]))
	end
end

function VehicleSaleSystem:generateInitialSales()
	for i = 1, VehicleSaleSystem.MAX_GENERATED_ITEMS - 1 do
		local randomVehicle = self:generateRandomVehicle()

		if randomVehicle ~= nil then
			self:addSale(randomVehicle)
		end
	end
end

function VehicleSaleSystem:getItems()
	return self.items
end

function VehicleSaleSystem:getSaleById(id)
	for _, item in ipairs(self.items) do
		if item.id == id then
			return item
		end
	end

	return nil
end

function VehicleSaleSystem:getFreeId()
	if #self.freeIds > 0 then
		return table.pop(self.freeIds)
	end

	local id = self.nextFreeId
	self.nextFreeId = self.nextFreeId + 1

	return id
end

function VehicleSaleSystem:onHourChanged()
	if not self.mission:getIsServer() then
		return
	end

	if self.numGeneratedItems < VehicleSaleSystem.MAX_GENERATED_ITEMS and math.random() < VehicleSaleSystem.GENERATED_HOURLY_CHANCE then
		local randomVehicle = self:generateRandomVehicle()

		if randomVehicle ~= nil then
			self:addSale(randomVehicle)
		end
	end

	for i = #self.items, 1, -1 do
		local item = self.items[i]
		item.timeLeft = item.timeLeft - 1
		local storeItem = g_storeManager:getItemByXMLFilename(item.xmlFilename)

		if item.timeLeft <= 0 or storeItem == nil then
			self:removeSale(item, i)
		end
	end
end

function VehicleSaleSystem:addSale(item, noEventSend)
	table.insert(self.items, item)

	if self.mission:getIsServer() then
		item.id = self:getFreeId()

		if item.isGenerated then
			self.numGeneratedItems = self.numGeneratedItems + 1
		else
			self.numMultiplayerItems = self.numMultiplayerItems + 1
		end

		if not noEventSend then
			g_server:broadcastEvent(VehicleSaleAddEvent.new(item))
		end
	end

	g_messageCenter:publish(MessageType.VEHICLE_SALES_CHANGED)
end

function VehicleSaleSystem:removeSale(item, index, noEventSend)
	if item == nil then
		return
	end

	if index == nil then
		for i, it in ipairs(self.items) do
			if item == it then
				index = i

				break
			end
		end
	end

	if index == nil then
		return
	end

	table.remove(self.items, index)

	if self.mission:getIsServer() then
		table.push(self.freeIds, index)

		if item.isGenerated then
			self.numGeneratedItems = self.numGeneratedItems - 1
		else
			self.numMultiplayerItems = self.numMultiplayerItems - 1
		end

		if not noEventSend then
			g_server:broadcastEvent(VehicleSaleRemoveEvent.new(item.id))
		end
	end

	g_messageCenter:publish(MessageType.VEHICLE_SALES_CHANGED)
end

function VehicleSaleSystem:removeSaleWithId(saleItemId)
	for i = 1, #self.items do
		if self.items[i].id == saleItemId then
			table.remove(self.items, i)

			break
		end
	end

	g_messageCenter:publish(MessageType.VEHICLE_SALES_CHANGED)
end

function VehicleSaleSystem:generateRandomVehicle()
	local items = g_storeManager:getItems()
	local storeItem = nil

	for try = 1, #items do
		local index = math.random(1, #items)
		local item = items[index]

		if StoreItemUtil.getIsVehicle(item) and item.showInStore and VehicleSaleSystem.MINIMUM_ITEM_VALUE <= item.price and item.extraContentId == nil then
			storeItem = item

			break
		end
	end

	if storeItem == nil then
		return nil
	end

	StoreItemUtil.loadSpecsFromXML(storeItem)

	local boughtConfigurations = {}

	if storeItem.configurations ~= nil then
		for name, options in pairs(storeItem.configurations) do
			if #options > 1 then
				local includedInSet = false

				for _, configSet in ipairs(storeItem.configurationSets) do
					if configSet.configurations[name] ~= nil then
						includedInSet = true

						break
					end
				end

				if not includedInSet and math.random() < 0.1 then
					local index = math.random(1, #options)
					boughtConfigurations[name] = {
						[index] = true
					}
				end
			end
		end
	end

	for _, configSet in ipairs(storeItem.configurationSets) do
		if math.random() < 0.1 then
			for name, index in pairs(configSet.configurations) do
				if boughtConfigurations[name] == nil then
					boughtConfigurations[name] = {}
				end

				boughtConfigurations[name][index] = true
			end
		end
	end

	local age = math.random(6, 40)
	local damage = math.random() * 0.8 + 0.2
	local wear = math.random() * 0.8 + 0.2
	local operatingTime = age * (math.random() * 0.8 + 0.5) * 60 * 60 * 1000
	local defaultPrice = StoreItemUtil.getDefaultPrice(storeItem, boughtConfigurations)
	local repairPrice = Wearable.calculateRepairPrice(defaultPrice, damage, true)
	local repaintPrice = Wearable.calculateRepaintPrice(defaultPrice, wear)
	local price = Vehicle.calculateSellPrice(storeItem, age, operatingTime, defaultPrice, repairPrice, repaintPrice)

	return {
		isGenerated = true,
		timeLeft = math.random(VehicleSaleSystem.MIN_GENERATED_ITEM_DURATION, VehicleSaleSystem.MAX_GENERATED_ITEM_DURATION),
		xmlFilename = storeItem.xmlFilename,
		boughtConfigurations = boughtConfigurations,
		age = age,
		price = price,
		damage = damage,
		wear = wear,
		operatingTime = operatingTime
	}
end

function VehicleSaleSystem:onVehicleWillSell(vehicle)
	local storeItem = g_storeManager:getItemByXMLFilename(vehicle.configFileName)

	if self.mission.missionDynamicInfo.isMultiplayer and self.numMultiplayerItems < VehicleSaleSystem.MAX_MULTIPLAYER_ITEMS and math.random() < VehicleSaleSystem.MULTIPLAYER_ACCEPT_CHANCE and VehicleSaleSystem.MINIMUM_ITEM_VALUE <= storeItem.price then
		local item = {
			damage = 0,
			wear = 0,
			isGenerated = false,
			timeLeft = math.random(VehicleSaleSystem.MIN_MULTIPLAYER_ITEM_DURATION, VehicleSaleSystem.MAX_MULTIPLAYER_ITEM_DURATION),
			xmlFilename = vehicle.configFileName,
			boughtConfigurations = table.copy(vehicle.boughtConfigurations, 3),
			age = vehicle.age,
			price = vehicle:getSellPrice() * VehicleSaleSystem.BUYPRICE_FACTOR,
			operatingTime = vehicle.operatingTime
		}

		if vehicle.getDamageAmount ~= nil then
			item.damage = vehicle:getDamageAmount()
		end

		if vehicle.getWearTotalAmount ~= nil then
			item.wear = vehicle:getWearTotalAmount()
		end

		self:addSale(item)
	end
end

function VehicleSaleSystem:onVehicleBought(saleItem)
	self:removeSale(saleItem)
end

function VehicleSaleSystem:setVehicleState(vehicle, saleItem, noEventSend)
	if saleItem == nil or vehicle == nil then
		return
	end

	if self.mission:getIsServer() then
		if vehicle.addDamageAmount ~= nil then
			vehicle:addDamageAmount(saleItem.damage, true)
		end

		if vehicle.addWearAmount ~= nil then
			vehicle:addWearAmount(saleItem.wear, true)
		end
	end

	vehicle.operatingTime = saleItem.operatingTime
	vehicle.age = saleItem.age

	for name, ids in pairs(saleItem.boughtConfigurations) do
		for id, _ in ipairs(ids) do
			ConfigurationUtil.addBoughtConfiguration(vehicle, name, id)
		end
	end

	if not noEventSend then
		g_server:broadcastEvent(VehicleSaleSetEvent.new(vehicle, saleItem), false, nil, vehicle, true, nil, true)
	end
end
