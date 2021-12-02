VehicleSaleAddEvent = {}
local VehicleSaleAddEvent_mt = Class(VehicleSaleAddEvent, Event)

InitStaticEventClass(VehicleSaleAddEvent, "VehicleSaleAddEvent", EventIds.EVENT_VEHICLE_SALE_ADD)

function VehicleSaleAddEvent.emptyNew()
	local self = Event.new(VehicleSaleAddEvent_mt, NetworkNode.CHANNEL_SECONDARY)

	return self
end

function VehicleSaleAddEvent.new(saleItem)
	local self = VehicleSaleAddEvent.emptyNew()
	self.saleItem = saleItem

	return self
end

function VehicleSaleAddEvent:readStream(streamId, connection)
	local saleItem = {
		id = streamReadUInt8(streamId),
		xmlFilename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId)),
		age = streamReadUInt16(streamId),
		price = streamReadInt32(streamId),
		damage = NetworkUtil.readCompressedPercentages(streamId, 10),
		wear = NetworkUtil.readCompressedPercentages(streamId, 10),
		operatingTime = streamReadFloat32(streamId),
		boughtConfigurations = {}
	}
	local numConfigurations = streamReadUInt8(streamId)

	for i = 1, numConfigurations do
		local name = g_configurationManager:getConfigurationNameByIndex(streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS))
		local id = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)

		if saleItem.boughtConfigurations[name] == nil then
			saleItem.boughtConfigurations[name] = {}
		end

		saleItem.boughtConfigurations[name][id] = true
	end

	self.saleItem = saleItem

	self:run(connection)
end

function VehicleSaleAddEvent:writeStream(streamId, connection)
	local saleItem = self.saleItem

	streamWriteUInt8(streamId, saleItem.id)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(saleItem.xmlFilename))
	streamWriteUInt16(streamId, saleItem.age)
	streamWriteInt32(streamId, saleItem.price)
	NetworkUtil.writeCompressedPercentages(streamId, saleItem.damage, 10)
	NetworkUtil.writeCompressedPercentages(streamId, saleItem.wear, 10)
	streamWriteFloat32(streamId, saleItem.operatingTime)

	local config = {}

	for name, ids in pairs(saleItem.boughtConfigurations) do
		for id, _ in pairs(ids) do
			table.insert(config, {
				nameId = g_configurationManager:getConfigurationIndexByName(name),
				configId = id
			})
		end
	end

	streamWriteUInt8(streamId, #config)

	for i = 1, #config do
		streamWriteUIntN(streamId, config[i].nameId, ConfigurationUtil.SEND_NUM_BITS)
		streamWriteUIntN(streamId, config[i].configId, ConfigurationUtil.SEND_NUM_BITS)
	end
end

function VehicleSaleAddEvent:run(connection)
	if connection:getIsServer() then
		g_currentMission.vehicleSaleSystem:addSale(self.saleItem, true)
	end
end
