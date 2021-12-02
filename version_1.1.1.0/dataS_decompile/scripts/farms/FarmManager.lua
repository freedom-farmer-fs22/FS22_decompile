FarmManager = {
	SPECTATOR_FARM_ID = 0,
	SINGLEPLAYER_FARM_ID = 1,
	MAX_NUM_FARMS = 8
}
FarmManager.MAX_FARM_ID = FarmManager.MAX_NUM_FARMS
FarmManager.SINGLEPLAYER_UUID = "player"
FarmManager.FARM_ID_SEND_NUM_BITS = 4
FarmManager.INVALID_FARM_ID = FarmManager.FARM_ID_SEND_NUM_BITS^2 - 1
local FarmManager_mt = Class(FarmManager, AbstractManager)

function FarmManager.new(customMt)
	local self = AbstractManager.new(customMt or FarmManager_mt)

	return self
end

function FarmManager:initDataStructures()
	self.farms = {}
	self.farmIdToFarm = {}
	self.spFarmWasMerged = false
	self.debug_hasAskedCreate = false
end

function FarmManager:loadMapData(xmlFile)
	FarmManager:superClass().loadMapData(self)

	if g_currentMission:getIsServer() then
		g_currentMission:addUpdateable(self)

		local spectatorFarm = Farm.new(true, g_client ~= nil, nil, true)
		spectatorFarm.farmId = FarmManager.SPECTATOR_FARM_ID
		spectatorFarm.isSpectator = true
		spectatorFarm.stats.updatePlayTime = false

		spectatorFarm:register()
		table.insert(self.farms, spectatorFarm)

		self.farmIdToFarm[spectatorFarm.farmId] = spectatorFarm
	end

	addConsoleCommand("gsFarmSet", "Set farm for current player or vehicle", "consoleCommandSetFarm", self)
end

function FarmManager:unloadMapData()
	g_currentMission:removeUpdateable(self)
	removeConsoleCommand("gsFarmSet")

	if g_addTestCommands then
		removeConsoleCommand("debugCreateFarm")
	end

	FarmManager:superClass().unloadMapData(self)
end

function FarmManager:saveToXMLFile(xmlFilename)
	local xmlFile = XMLFile.create("farmsXML", xmlFilename, "farms")

	xmlFile:setTable("farms.farm", self.farms, function (path, farm)
		if farm.farmId == FarmManager.SPECTATOR_FARM_ID then
			return 0
		end

		farm:saveToXMLFile(xmlFile, path)
	end)
	xmlFile:save()
	xmlFile:delete()
end

function FarmManager:loadFromXMLFile(xmlFilename)
	if xmlFilename == nil then
		self:loadDefaults()

		return false
	end

	local xmlFile = XMLFile.load("TempXML", xmlFilename)

	if xmlFile == nil then
		return false
	end

	xmlFile:iterate("farms.farm", function (_, key)
		local farm = Farm.new(true, g_client ~= nil)

		if not farm:loadFromXMLFile(xmlFile, key) then
			farm:delete()
		else
			farm:register()
			table.insert(self.farms, farm)

			self.farmIdToFarm[farm.farmId] = farm
		end
	end)
	self:mergeFarmsForSingleplayer()

	if g_currentMission:getIsClient() then
		local uniqueUserId = g_currentMission.missionDynamicInfo.isMultiplayer and getUniqueUserId() or FarmManager.SINGLEPLAYER_UUID

		self:playerJoinedGame(uniqueUserId, g_currentMission:getServerUserId())
	end

	g_fieldManager:updateFieldOwnership()
	xmlFile:delete()

	return true
end

function FarmManager:loadDefaults()
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		local farm = self:createFarm(g_i18n:getText("ui_defaultFarmName"), 1)

		farm:addUser(g_currentMission:getServerUserId(), FarmManager.SINGLEPLAYER_UUID, true)
	end

	g_fieldManager:updateFieldOwnership()
	self:playerJoinedGame(getUniqueUserId(), g_currentMission:getServerUserId())
end

function FarmManager:mergeFarmsForSingleplayer()
	if g_currentMission.missionDynamicInfo.isMultiplayer then
		return
	end

	if #self.farms > 2 or #self.farms >= 2 and self.farms[2].farmId ~= FarmManager.SINGLEPLAYER_FARM_ID then
		local spFarm = self.farms[2]

		for _, farm in ipairs(self.farms) do
			if farm.farmId ~= FarmManager.SPECTATOR_FARM_ID and farm.farmId ~= spFarm.farmId then
				spFarm:merge(farm)
			end
		end

		spFarm.farmId = FarmManager.SINGLEPLAYER_FARM_ID
		local specFarm = self.farmIdToFarm[FarmManager.SPECTATOR_FARM_ID]
		self.farmIdToFarm = {
			[FarmManager.SPECTATOR_FARM_ID] = specFarm,
			[FarmManager.SINGLEPLAYER_FARM_ID] = spFarm
		}
		self.farms = {
			specFarm,
			spFarm
		}
		self.spFarmWasMerged = true
	elseif #self.farms == 1 then
		local farm = self:createFarm(g_i18n:getText("ui_defaultFarmName"), 1)

		farm:addUser(g_currentMission:getServerUserId(), FarmManager.SINGLEPLAYER_UUID, true)

		self.farms = {
			farm
		}
	end

	self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]:resetToSingleplayer()
end

function FarmManager:mergeFarmlandsForSingleplayer()
	if not g_currentMission.missionDynamicInfo.isMultiplayer and self.spFarmWasMerged then
		for _, farmland in pairs(g_farmlandManager:getFarmlands()) do
			if g_farmlandManager:getFarmlandOwner(farmland.id) ~= FarmlandManager.NO_OWNER_FARM_ID then
				g_farmlandManager:setLandOwnership(farmland.id, FarmManager.SINGLEPLAYER_FARM_ID)
			end
		end
	end
end

function FarmManager:mergeObjectsForSingleplayer()
	if not g_currentMission.missionDynamicInfo.isMultiplayer and self.spFarmWasMerged then
		for _, vehicle in pairs(g_currentMission.vehicles) do
			if vehicle:getOwnerFarmId() ~= AccessHandler.EVERYONE then
				vehicle:setOwnerFarmId(FarmManager.SINGLEPLAYER_FARM_ID)
			end
		end

		for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
			if placeable:getOwnerFarmId() ~= AccessHandler.EVERYONE then
				placeable:setOwnerFarmId(FarmManager.SINGLEPLAYER_FARM_ID)
			end
		end

		for _, item in pairs(g_currentMission.itemSystem.itemsToSave) do
			if item.getOwnerFarmId ~= nil and item:getOwnerFarmId() ~= AccessHandler.EVERYONE then
				item:setOwnerFarmId(FarmManager.SINGLEPLAYER_FARM_ID)
			end
		end
	end
end

function FarmManager:delete()
end

function FarmManager:update(dt)
	if g_currentMission:getIsClient() and self.spFarmWasMerged and not self.mergedMessageShown then
		g_gui:showInfoDialog({
			isCloseAllowed = true,
			visible = true,
			text = g_i18n:getText("ui_farmedMergedSP"),
			dialogType = DialogElement.TYPE_INFO
		})

		self.mergedMessageShown = true
	end
end

function FarmManager:getFarmForUniqueUserId(uniqueUserId)
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		return self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]
	end

	for _, farm in ipairs(self.farms) do
		local player = farm.uniqueUserIdToPlayer[uniqueUserId]

		if not farm.isSpectator and player ~= nil then
			return farm
		end
	end

	return self.farmIdToFarm[FarmManager.SPECTATOR_FARM_ID]
end

function FarmManager:getFarmByUserId(userId)
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		return self.farmIdToFarm[FarmManager.SINGLEPLAYER_FARM_ID]
	end

	for _, farm in ipairs(self.farms) do
		local player = farm.userIdToPlayer[userId]

		if player ~= nil then
			return farm
		end
	end

	return self.farmIdToFarm[0]
end

function FarmManager:getFarmById(farmId)
	return self.farmIdToFarm[farmId]
end

function FarmManager:getSpawnPoint(farmId)
	local farm = self:getFarmById(farmId)

	if farm == nil then
		return nil
	end

	return farm:getSpawnPoint()
end

function FarmManager:getSleepCamera(farmId)
	local farm = self:getFarmById(farmId)

	if farm == nil then
		return nil
	end

	return farm:getSleepCamera()
end

function FarmManager:updateFarms(farms, playerFarmId)
	self.farms = farms
	self.farmIdToFarm = {}

	for _, farm in ipairs(self.farms) do
		self.farmIdToFarm[farm.farmId] = farm
	end
end

function FarmManager:appendFarm(farm)
	if self.farmIdToFarm[farm.farmId] == nil then
		self.farmIdToFarm[farm.farmId] = farm

		table.insert(self.farms, farm)
	end
end

function FarmManager:getFarms()
	return self.farms
end

function FarmManager:onFarmObjectCreated(object)
	if not g_currentMission:getIsServer() then
		self:appendFarm(object)
		g_messageCenter:publish(MessageType.FARM_CREATED, object.farmId)
	end
end

function FarmManager:onFarmObjectDeleted(object)
	self:removeFarm(object.farmId)
	g_messageCenter:publishDelayed(MessageType.FARM_DELETED, object.farmId)
end

function FarmManager:updateFarmStats(farmId, stat, delta)
	local farm = self.farmIdToFarm[farmId]

	if farm ~= nil then
		farm.stats:updateStats(stat, delta)
	end
end

function FarmManager:playerJoinedGame(uniqueUserId, userId, user, connection)
	if g_currentMission:getIsServer() then
		local farm = self:getFarmForUniqueUserId(uniqueUserId)
		local didJoinFarm = farm:onUserJoinGame(uniqueUserId, userId, user)

		g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(FarmManager.INVALID_FARM_ID, farm.farmId, userId), nil, connection)

		if didJoinFarm then
			local player = farm.userIdToPlayer[userId]

			if player ~= nil then
				g_server:broadcastEvent(PlayerPermissionsEvent.new(userId, player.permissions, player.isFarmManager), nil, connection)
			end
		end
	else
		print("Error: FarmManager:playerJoinedGame() only allowed on server")
	end
end

function FarmManager:playerQuitGame(userId)
	if g_currentMission:getIsServer() then
		local farm = self:getFarmByUserId(userId)

		farm:onUserQuitGame(userId)
		g_server:broadcastEvent(PlayerSwitchedFarmEvent.new(farm.farmId, FarmManager.INVALID_FARM_ID, userId))
	else
		print("Error: FarmManager:playerQuitGame() only allowed on server")
	end
end

function FarmManager:transferMoney(destinationFarm, amount)
	g_client:getServerConnection():sendEvent(TransferMoneyEvent.new(amount, destinationFarm.farmId))
end

function FarmManager:removeUserFromFarm(userId)
	g_client:getServerConnection():sendEvent(RemovePlayerFromFarmEvent.new(userId))
end

function FarmManager:createFarm(name, color, password, farmId)
	if not g_currentMission:getIsServer() then
		print("Error: FarmManager:createFarm() only allowed on server")

		return nil
	end

	if not g_currentMission.missionDynamicInfo.isMultiplayer and table.getn(self.farms) > 2 then
		return nil
	end

	local farm = Farm.new(true, g_client ~= nil)

	if table.getn(self.farms) == FarmManager.MAX_FARM_ID + 1 then
		return nil, "Farm limit reached"
	end

	if self.farmIdToFarm[farmId] ~= nil then
		farmId = nil
	end

	if farmId == nil then
		farmId = self:findNextFarmId()
	end

	farm.farmId = farmId
	farm.name = name
	farm.color = color

	if password ~= "" then
		farm.password = password
	end

	farm:register()
	table.insert(self.farms, farm)

	self.farmIdToFarm[farm.farmId] = farm

	g_messageCenter:publish(MessageType.FARM_CREATED, farm.farmId)

	return farm
end

function FarmManager:destroyFarm(farmId)
	if not g_currentMission.missionDynamicInfo.isMultiplayer then
		return
	end

	local farm = self.farmIdToFarm[farmId]

	if farm ~= nil then
		farm:delete()
		self:removeFarm(farmId)

		for i = #g_currentMission.vehicles, 1, -1 do
			local vehicle = g_currentMission.vehicles[i]

			if vehicle:getOwnerFarmId() == farmId then
				g_currentMission:removeVehicle(vehicle)
			end
		end

		for i = #g_currentMission.placeableSystem.placeables, 1, -1 do
			local placeable = g_currentMission.placeableSystem.placeables[i]

			if placeable:getOwnerFarmId() == farmId then
				placeable:delete()
			end
		end

		for _, item in pairs(g_currentMission.itemSystem.itemsToSave) do
			if item.getOwnerFarmId ~= nil and item:getOwnerFarmId() == farmId then
				item:delete()
			end
		end

		g_messageCenter:publish(MessageType.FARM_DELETED, farmId)
	end
end

function FarmManager:removeFarm(farmId)
	self.farmIdToFarm[farmId] = nil

	for i, farm in ipairs(self.farms) do
		if farm.farmId == farmId then
			table.remove(self.farms, i)

			break
		end
	end
end

function FarmManager:findNextFarmId()
	for i = 1, FarmManager.MAX_FARM_ID do
		local inUse = false

		for _, farm in ipairs(self.farms) do
			if i == farm.farmId then
				inUse = true

				break
			end
		end

		if not inUse then
			return i
		end
	end

	return nil
end

function FarmManager:consoleCommandSetFarm(farmId)
	if farmId == nil then
		if g_currentMission.controlPlayer then
			log(g_currentMission.player.farmId)
		else
			log(g_currentMission.controlledVehicle:getOwnerFarmId())
		end

		return
	end

	farmId = tonumber(farmId)

	if g_currentMission.controlPlayer then
		g_client:getServerConnection():sendEvent(PlayerSetFarmEvent.new(g_currentMission.player, farmId))
	else
		if not g_currentMission:getIsServer() then
			return "This command currently only works on server"
		end

		local vehicle = g_currentMission.controlledVehicle
		local farm = self:getFarmById(farmId)

		if farm == nil then
			return "Farm with id " .. tostring(farmId) .. " does not exist."
		end

		vehicle:setOwnerFarmId(farmId)
	end
end

g_farmManager = FarmManager.new()
