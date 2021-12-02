BuyPlaceableEvent = {}
local BuyPlaceableEvent_mt = Class(BuyPlaceableEvent, Event)
BuyPlaceableEvent.STATE_SUCCESS = 0
BuyPlaceableEvent.STATE_FAILED_TO_LOAD = 1
BuyPlaceableEvent.STATE_NO_SPACE = 2
BuyPlaceableEvent.STATE_NO_PERMISSION = 3
BuyPlaceableEvent.STATE_NOT_ENOUGH_MONEY = 4
BuyPlaceableEvent.STATE_TERRAIN_DEFORMATION_FAILED = 5

InitStaticEventClass(BuyPlaceableEvent, "BuyPlaceableEvent", EventIds.EVENT_BUY_PLACEABLE)

function BuyPlaceableEvent.emptyNew()
	local self = Event.new(BuyPlaceableEvent_mt)

	return self
end

function BuyPlaceableEvent.new(filename, x, y, z, rx, ry, rz, displacementCosts, ownerFarmId, modifyTerrain, colorIndex, forFree)
	local self = BuyPlaceableEvent.emptyNew()
	self.filename = filename
	self.x = x
	self.y = y
	self.z = z
	self.rx = rx
	self.ry = ry
	self.rz = rz
	self.displacementCosts = displacementCosts
	self.ownerFarmId = ownerFarmId
	self.modifyTerrain = modifyTerrain
	self.colorIndex = colorIndex or 0
	self.forFree = Utils.getNoNil(forFree, false)

	return self
end

function BuyPlaceableEvent.newServerToClient(errorCode, price)
	local self = BuyPlaceableEvent.emptyNew()
	self.errorCode = errorCode
	self.price = price

	return self
end

function BuyPlaceableEvent:readStream(streamId, connection)
	if not connection:getIsServer() then
		self.filename = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
		self.x = streamReadFloat32(streamId)
		self.y = streamReadFloat32(streamId)
		self.z = streamReadFloat32(streamId)
		self.rx = streamReadFloat32(streamId)
		self.ry = streamReadFloat32(streamId)
		self.rz = streamReadFloat32(streamId)
		self.displacementCosts = streamReadInt32(streamId)
		self.ownerFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		self.modifyTerrain = streamReadBool(streamId)
		self.colorIndex = streamReadUInt8(streamId)
		self.forFree = streamReadBool(streamId)
	else
		self.errorCode = streamReadUIntN(streamId, 3)
		self.price = streamReadInt32(streamId)
	end

	self:run(connection)
end

function BuyPlaceableEvent:writeStream(streamId, connection)
	if connection:getIsServer() then
		streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.filename))
		streamWriteFloat32(streamId, self.x)
		streamWriteFloat32(streamId, self.y)
		streamWriteFloat32(streamId, self.z)
		streamWriteFloat32(streamId, self.rx)
		streamWriteFloat32(streamId, self.ry)
		streamWriteFloat32(streamId, self.rz)
		streamWriteInt32(streamId, self.displacementCosts)
		streamWriteUIntN(streamId, self.ownerFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		streamWriteBool(streamId, self.modifyTerrain)
		streamWriteUInt8(streamId, self.colorIndex)
		streamWriteBool(streamId, self.forFree)
	else
		streamWriteUIntN(streamId, self.errorCode, 3)
		streamWriteInt32(streamId, self.price)
	end
end

function BuyPlaceableEvent:run(connection)
	if not connection:getIsServer() then
		local errorOccurred = false
		local errorCode = BuyPlaceableEvent.STATE_FAILED_TO_LOAD
		local price = 0

		if not g_currentMission:getHasPlayerPermission("buyPlaceable", connection) then
			errorCode = BuyPlaceableEvent.STATE_NO_PERMISSION
			errorOccurred = true
		else
			local dataStoreItem = g_storeManager:getItemByXMLFilename(self.filename)

			if dataStoreItem ~= nil then
				if not self.forFree then
					price = g_currentMission.economyManager:getBuyPrice(dataStoreItem)
					price = price + self.displacementCosts
				end

				if price <= g_currentMission:getMoney(self.ownerFarmId) then
					local position = {
						x = self.x,
						y = self.y,
						z = self.z
					}
					local rotation = {
						x = self.rx,
						y = self.ry,
						z = self.rz
					}

					PlaceableUtil.loadPlaceable(self.filename, position, rotation, self.ownerFarmId, nil, self.placeableLoaded, self, {
						price,
						connection
					})
				else
					errorCode = BuyPlaceableEvent.STATE_NOT_ENOUGH_MONEY
					errorOccurred = true
				end
			end
		end

		if errorOccurred then
			connection:sendEvent(BuyPlaceableEvent.newServerToClient(errorCode, price))
		end
	else
		g_messageCenter:publish(BuyPlaceableEvent, self.errorCode, self.price)
	end
end

function BuyPlaceableEvent:placeableLoaded(placeable, loadingState, args)
	local price, connection = unpack(args)

	if loadingState == Placeable.LOADING_STATE_ERROR then
		connection:sendEvent(BuyPlaceableEvent.newServerToClient(BuyPlaceableEvent.STATE_FAILED_TO_LOAD, price))

		if placeable ~= nil then
			placeable:delete()
		end

		return
	end

	if placeable ~= nil then
		if GS_IS_CONSOLE_VERSION and not fileExists(self.filename) then
			placeable:delete()
		else
			local ownerFarmId = self.ownerFarmId

			local function deformationCallback(errorCode, displacedVolume, blockedObjectName)
				if errorCode ~= TerrainDeformation.STATE_SUCCESS then
					placeable:delete()
					connection:sendEvent(BuyPlaceableEvent.newServerToClient(BuyPlaceableEvent.STATE_TERRAIN_DEFORMATION_FAILED, price))
				else
					if self.colorIndex ~= 0 and placeable.setColor ~= nil then
						placeable:setColor(self.colorIndex)
					end

					local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, placeable.position.x, 0, placeable.position.z)
					placeable.position.y = y

					placeable:initPose()
					placeable:finalizePlacement()
					placeable:register()
					g_currentMission:addMoney(-price, ownerFarmId, MoneyType.SHOP_PROPERTY_BUY, true)
					placeable:onBuy()

					local serverFarmId = g_currentMission:getFarmId()
					local numPlaceables = 0
					local numBeehives = 0
					local numProductionPoints = 0

					for _, existingPlaceable in ipairs(g_currentMission.placeableSystem.placeables) do
						if existingPlaceable:getOwnerFarmId() == serverFarmId then
							if existingPlaceable.spec_beehive ~= nil then
								numBeehives = numBeehives + 1
							end

							if existingPlaceable.spec_productionPoint ~= nil then
								numProductionPoints = numProductionPoints + 1
							end

							numPlaceables = numPlaceables + 1
						end
					end

					g_achievementManager:tryUnlock("NumPlaceables", numPlaceables)
					g_achievementManager:tryUnlock("NumBeehives", numBeehives)
					g_achievementManager:tryUnlock("NumProductionPoints", numProductionPoints)
					connection:sendEvent(BuyPlaceableEvent.newServerToClient(BuyPlaceableEvent.STATE_SUCCESS, price))
				end
			end

			if self.modifyTerrain and placeable.applyDeformation ~= nil then
				placeable:applyDeformation(false, deformationCallback)
			else
				deformationCallback(TerrainDeformation.STATE_SUCCESS, 0, nil)
			end
		end
	else
		connection:sendEvent(BuyPlaceableEvent.newServerToClient(BuyPlaceableEvent.STATE_NO_SPACE, price))
	end
end
