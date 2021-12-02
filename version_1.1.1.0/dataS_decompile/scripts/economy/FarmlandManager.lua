FarmlandManager = {
	NO_OWNER_FARM_ID = 0,
	NOT_BUYABLE_FARM_ID = GS_IS_MOBILE_VERSION and 15 or 255
}
local FarmlandManager_mt = Class(FarmlandManager, AbstractManager)

function FarmlandManager.new(customMt)
	local self = AbstractManager.new(customMt or FarmlandManager_mt)

	return self
end

function FarmlandManager:initDataStructures()
	self.farmlands = {}
	self.sortedFarmlandIds = {}
	self.farmlandMapping = {}
	self.localMap = nil
	self.localMapWidth = 0
	self.localMapHeight = 0
	self.numberOfBits = 8
	self.stateChangeListener = {}
end

function FarmlandManager:loadMapData(xmlFile)
	FarmlandManager:superClass().loadMapData(self)

	return XMLUtil.loadDataFromMapXML(xmlFile, "farmlands", g_currentMission.baseDirectory, self, self.loadFarmlandData)
end

function FarmlandManager:loadFarmlandData(xmlFile)
	local filename = Utils.getFilename(getXMLString(xmlFile, "map.farmlands#densityMapFilename"), g_currentMission.baseDirectory)
	self.numberOfBits = Utils.getNoNil(getXMLInt(xmlFile, "map.farmlands#numChannels"), 8)
	self.pricePerHa = Utils.getNoNil(getXMLFloat(xmlFile, "map.farmlands#pricePerHa"), 60000)
	FarmlandManager.NOT_BUYABLE_FARM_ID = 2^self.numberOfBits - 1
	self.localMap = createBitVectorMap("FarmlandMap")
	local success = loadBitVectorMapFromFile(self.localMap, filename, self.numberOfBits)

	if not success then
		print("Warning: Loading farmland file '" .. tostring(filename) .. "' failed!")

		return false
	end

	self.localMapWidth, self.localMapHeight = getBitVectorMapSize(self.localMap)
	local farmlandSizeMapping = {}
	local farmlandCenterData = {}
	local numOfFarmlands = 0
	local maxFarmlandId = 0
	local missingFarmlandDefinitions = false

	for x = 0, self.localMapWidth - 1 do
		for y = 0, self.localMapHeight - 1 do
			local value = getBitVectorMapPoint(self.localMap, x, y, 0, self.numberOfBits)

			if value > 0 then
				if self.farmlandMapping[value] == nil then
					farmlandSizeMapping[value] = 0
					farmlandCenterData[value] = {
						sumPosX = 0,
						sumPosZ = 0
					}
					self.farmlandMapping[value] = FarmlandManager.NO_OWNER_FARM_ID
					numOfFarmlands = numOfFarmlands + 1
					maxFarmlandId = math.max(value, maxFarmlandId)
				end

				farmlandSizeMapping[value] = farmlandSizeMapping[value] + 1
				farmlandCenterData[value].sumPosX = farmlandCenterData[value].sumPosX + x - 0.5
				farmlandCenterData[value].sumPosZ = farmlandCenterData[value].sumPosZ + y - 0.5
			else
				missingFarmlandDefinitions = true
			end
		end
	end

	if missingFarmlandDefinitions then
		print("Warning: Farmland-Ids not set for all pixel in farmland-infoLayer!")
	end

	local isNewSavegame = not g_currentMission.missionInfo.isValid
	local i = 0

	while true do
		local key = string.format("map.farmlands.farmland(%d)", i)

		if not hasXMLProperty(xmlFile, key) then
			break
		end

		local farmland = Farmland.new()

		if farmland:load(xmlFile, key) and self.farmlands[farmland.id] == nil and self.farmlandMapping[farmland.id] ~= nil then
			self.farmlands[farmland.id] = farmland

			table.insert(self.sortedFarmlandIds, farmland.id)

			local shouldAddDefaults = isNewSavegame and g_currentMission.missionInfo.hasInitiallyOwnedFarmlands and not g_currentMission.missionDynamicInfo.isMultiplayer

			if shouldAddDefaults and g_currentMission:getIsServer() and farmland.defaultFarmProperty then
				self:setLandOwnership(farmland.id, FarmManager.SINGLEPLAYER_FARM_ID)
			end
		else
			if self.farmlandMapping[farmland.id] == nil then
				print("Error: Farmland-Id " .. tostring(farmland.id) .. " not defined in farmland ownage file '" .. filename .. "'. Skipping farmland definition!")
			end

			if self.farmlands[farmland.id] ~= nil then
				print("Error: Farmland-id '" .. tostring(farmland.id) .. "' already exists! Ignore it!")
			end

			farmland:delete()
		end

		i = i + 1
	end

	for index, _ in pairs(self.farmlandMapping) do
		if index ~= FarmlandManager.NOT_BUYABLE_FARM_ID and self.farmlands[index] == nil then
			print("Error: Farmland-Id " .. tostring(index) .. " not defined in farmland xml file!")
		end
	end

	local transformFactor = g_currentMission.terrainSize / self.localMapWidth
	local pixelToSqm = transformFactor * transformFactor

	for id, farmland in pairs(self.farmlands) do
		local ha = MathUtil.areaToHa(farmlandSizeMapping[id], pixelToSqm)

		farmland:setArea(ha)

		local posX = (farmlandCenterData[id].sumPosX / farmlandSizeMapping[id] - self.localMapWidth * 0.5) * transformFactor
		local posZ = (farmlandCenterData[id].sumPosZ / farmlandSizeMapping[id] - self.localMapHeight * 0.5) * transformFactor

		self.farmlands[id]:setFarmlandIndicatorPosition(posX, posZ)
	end

	g_messageCenter:subscribe(MessageType.FARM_DELETED, self.farmDestroyed, self)

	if g_currentMission:getIsServer() and g_addCheatCommands then
		addConsoleCommand("gsFarmlandBuy", "Buys farmland with given id", "consoleCommandBuyFarmland", self)
		addConsoleCommand("gsFarmlandBuyAll", "Buys all farmlands", "consoleCommandBuyAllFarmlands", self)
		addConsoleCommand("gsFarmlandSell", "Sells farmland with given id", "consoleCommandSellFarmland", self)
		addConsoleCommand("gsFarmlandSellAll", "Sells all farmlands", "consoleCommandSellAllFarmlands", self)
	end

	return true
end

function FarmlandManager:unloadMapData()
	removeConsoleCommand("gsFarmlandBuy")
	removeConsoleCommand("gsFarmlandBuyAll")
	removeConsoleCommand("gsFarmlandSell")
	removeConsoleCommand("gsFarmlandSellAll")
	g_messageCenter:unsubscribeAll(self)

	if self.localMap ~= nil then
		delete(self.localMap)

		self.localMap = nil
	end

	if self.farmlands ~= nil then
		for _, farmland in pairs(self.farmlands) do
			farmland:delete()
		end
	end

	FarmlandManager:superClass().unloadMapData(self)
end

function FarmlandManager:saveToXMLFile(xmlFilename)
	local xmlFile = createXMLFile("farmlandsXML", xmlFilename, "farmlands")

	if xmlFile ~= nil then
		local index = 0

		for farmlandId, farmId in pairs(self.farmlandMapping) do
			local farmlandKey = string.format("farmlands.farmland(%d)", index)

			setXMLInt(xmlFile, farmlandKey .. "#id", farmlandId)
			setXMLInt(xmlFile, farmlandKey .. "#farmId", Utils.getNoNil(farmId, FarmlandManager.NO_OWNER_FARM_ID))

			index = index + 1
		end

		saveXMLFile(xmlFile)
		delete(xmlFile)

		return true
	end

	return false
end

function FarmlandManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		return false
	end

	local xmlFile = loadXMLFile("farmlandXML", xmlFilename)

	if xmlFile == 0 then
		return false
	end

	local farmlandCounter = 0

	while true do
		local key = string.format("farmlands.farmland(%d)", farmlandCounter)
		local farmlandId = getXMLInt(xmlFile, key .. "#id")

		if farmlandId == nil then
			break
		end

		local farmId = getXMLInt(xmlFile, key .. "#farmId")

		if FarmlandManager.NO_OWNER_FARM_ID < farmId then
			self:setLandOwnership(farmlandId, farmId)
		end

		farmlandCounter = farmlandCounter + 1
	end

	delete(xmlFile)
	g_farmManager:mergeFarmlandsForSingleplayer()

	return true
end

function FarmlandManager:delete()
end

function FarmlandManager:getLocalMap()
	return self.localMap
end

function FarmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, worldPosX, worldPosZ)
	if farmId == FarmlandManager.NO_OWNER_FARM_ID or farmId == nil then
		return false
	end

	local farmlandId = self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)

	return self.farmlandMapping[farmlandId] == farmId
end

function FarmlandManager:getCanAccessLandAtWorldPosition(farmId, worldPosX, worldPosZ)
	if farmId == FarmlandManager.NO_OWNER_FARM_ID or farmId == nil then
		return false
	end

	local farmlandId = self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
	local ownerFarmId = self.farmlandMapping[farmlandId]

	if ownerFarmId == farmId then
		return true
	end

	return g_currentMission.accessHandler:canFarmAccessOtherId(farmId, ownerFarmId)
end

function FarmlandManager:getFarmlandOwner(farmlandId)
	if farmlandId == nil or self.farmlandMapping[farmlandId] == nil then
		return FarmlandManager.NO_OWNER_FARM_ID
	end

	return self.farmlandMapping[farmlandId]
end

function FarmlandManager:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)
	local localPosX, localPosZ = self:convertWorldToLocalPosition(worldPosX, worldPosZ)

	return getBitVectorMapPoint(self.localMap, localPosX, localPosZ, 0, self.numberOfBits)
end

function FarmlandManager:getFarmlandAtWorldPosition(worldPosX, worldPosZ)
	local farmlandId = self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)

	return self.farmlands[farmlandId]
end

function FarmlandManager:getOwnerIdAtWorldPosition(worldPosX, worldPosZ)
	local farmlandId = self:getFarmlandIdAtWorldPosition(worldPosX, worldPosZ)

	return self:getFarmlandOwner(farmlandId)
end

function FarmlandManager:getIsValidFarmlandId(farmlandId)
	if farmlandId == nil or farmlandId == 0 or farmlandId < 0 then
		return false
	end

	if self:getFarmlandById(farmlandId) == nil then
		return false
	end

	return true
end

function FarmlandManager:setLandOwnership(farmlandId, farmId)
	if not self:getIsValidFarmlandId(farmlandId) then
		return false
	end

	if farmId == nil or farmId < FarmlandManager.NO_OWNER_FARM_ID or farmId == FarmlandManager.NOT_BUYABLE_FARM_ID then
		return false
	end

	local farmland = self:getFarmlandById(farmlandId)

	if farmland == nil then
		print("Warning: Farmland not defined in map!")

		return
	end

	self.farmlandMapping[farmlandId] = farmId
	farmland.isOwned = farmId ~= FarmlandManager.NO_OWNER_FARM_ID

	for _, listener in pairs(self.stateChangeListener) do
		listener:onFarmlandStateChanged(farmlandId, farmId)
	end
end

function FarmlandManager:getFarmlandById(farmlandId)
	return self.farmlands[farmlandId]
end

function FarmlandManager:getFarmlands()
	return self.farmlands
end

function FarmlandManager:getPricePerHa()
	return self.pricePerHa
end

function FarmlandManager:getOwnedFarmlandIdsByFarmId(id)
	local farmlandIds = {}

	for farmlandId, farmId in pairs(self.farmlandMapping) do
		if farmId == id then
			table.insert(farmlandIds, farmlandId)
		end
	end

	return farmlandIds
end

function FarmlandManager:convertWorldToLocalPosition(worldPosX, worldPosZ)
	local terrainSize = g_currentMission.terrainSize

	return math.floor(self.localMapWidth * (worldPosX + terrainSize * 0.5) / terrainSize), math.floor(self.localMapHeight * (worldPosZ + terrainSize * 0.5) / terrainSize)
end

function FarmlandManager:farmDestroyed(farmId)
	for _, farmland in pairs(self:getFarmlands()) do
		if self:getFarmlandOwner(farmland.id) == farmId then
			self:setLandOwnership(farmland.id, FarmlandManager.NO_OWNER_FARM_ID)
		end
	end
end

function FarmlandManager:addStateChangeListener(listener)
	if listener ~= nil and listener.onFarmlandStateChanged ~= nil then
		self.stateChangeListener[listener] = listener
	end
end

function FarmlandManager:removeStateChangeListener(listener)
	if listener ~= nil then
		self.stateChangeListener[listener] = nil
	end
end

function FarmlandManager:consoleCommandBuyFarmland(farmlandId)
	if (g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient() then
		farmlandId = tonumber(farmlandId)

		if farmlandId == nil then
			return "Invalid farmland id. Use gsFarmlandBuy <farmlandId>"
		end

		local farmId = g_currentMission.player.farmId

		g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(farmlandId, farmId, 0))

		return "Bought farmland " .. farmlandId
	else
		return "Command not allowed"
	end
end

function FarmlandManager:consoleCommandBuyAllFarmlands()
	if (g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient() then
		local farmId = g_currentMission.player.farmId

		for k, _ in pairs(g_farmlandManager:getFarmlands()) do
			g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(k, farmId, 0))
		end

		return "Bought all farmlands"
	else
		return "Command not allowed"
	end
end

function FarmlandManager:consoleCommandSellFarmland(farmlandId)
	if (g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient() then
		farmlandId = tonumber(farmlandId)

		if farmlandId == nil then
			return "Invalid farmland id. Use gsFarmlandSell <farmlandId>"
		end

		g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(farmlandId, FarmlandManager.NO_OWNER_FARM_ID, 0))

		return "Sold farmland " .. farmlandId
	else
		return "Command not allowed"
	end
end

function FarmlandManager:consoleCommandSellAllFarmlands()
	if (g_currentMission:getIsServer() or g_currentMission.isMasterUser) and g_currentMission:getIsClient() then
		for k, _ in pairs(g_farmlandManager:getFarmlands()) do
			g_client:getServerConnection():sendEvent(FarmlandStateEvent.new(k, FarmlandManager.NO_OWNER_FARM_ID, 0))
		end

		return "Sold all farmlands"
	else
		return "Command not allowed"
	end
end

g_farmlandManager = FarmlandManager.new()
