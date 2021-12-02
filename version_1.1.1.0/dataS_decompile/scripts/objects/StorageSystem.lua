StorageSystem = {}
local StorageSystem_mt = Class(StorageSystem)

function StorageSystem.new(accessHandler, customMt)
	local self = setmetatable({}, customMt or StorageSystem_mt)
	self.accessHandler = accessHandler
	self.loadingStations = {}
	self.placeableLoadingStations = {}
	self.extendableLoadingStations = {}
	self.unloadingStations = {}
	self.placeableUnloadingStations = {}
	self.extendableUnloadingStations = {}
	self.storages = {}
	self.storageExtensions = {}

	return self
end

function StorageSystem:addStorage(storage)
	if storage ~= nil then
		self.storages[storage] = storage

		if storage.isExtension then
			self.storageExtensions[storage] = storage
		end

		return true
	end

	return false
end

function StorageSystem:removeStorage(storage)
	if storage ~= nil then
		self.storages[storage] = nil
		self.storageExtensions[storage] = nil

		return true
	end

	return false
end

function StorageSystem:hasStorage(storage)
	if storage ~= nil then
		return self.storages[storage] ~= nil
	end

	return false
end

function StorageSystem:getStorages()
	return self.storages
end

function StorageSystem:getStorageExtensionsInRange(station, farmId)
	local storagesInRange = {}

	for storage, _ in pairs(self.storageExtensions) do
		if self:getIsStationCompatible(station, storage, farmId) then
			table.insert(storagesInRange, storage)
		end
	end

	return storagesInRange
end

function StorageSystem:addLoadingStation(station, placeable)
	if station ~= nil then
		self.loadingStations[station] = station

		if placeable ~= nil then
			if self.placeableLoadingStations[placeable] == nil then
				self.placeableLoadingStations[placeable] = {}
			end

			table.insert(self.placeableLoadingStations[placeable], station)
		end

		if station.supportsExtension then
			self.extendableLoadingStations[station] = station
		end

		return true
	end

	return false
end

function StorageSystem:removeLoadingStation(station, placeable)
	if station ~= nil then
		self.loadingStations[station] = nil
		self.extendableLoadingStations[station] = nil

		if placeable ~= nil and self.placeableLoadingStations[placeable] ~= nil then
			for k, s in ipairs(self.placeableLoadingStations[placeable]) do
				if station == s then
					table.remove(self.placeableLoadingStations[placeable], k)
				end
			end

			if #self.placeableLoadingStations[placeable] == 0 then
				self.placeableLoadingStations[placeable] = nil
			end
		end

		return true
	end

	return false
end

function StorageSystem:getPlaceableLoadingStationIndex(placeable, station)
	if self.placeableLoadingStations[placeable] ~= nil then
		for k, s in ipairs(self.placeableLoadingStations[placeable]) do
			if station == s then
				return k
			end
		end
	end

	return nil
end

function StorageSystem:getPlaceableLoadingStation(placeable, index)
	local loadingStations = self.placeableLoadingStations[placeable]

	if loadingStations ~= nil then
		return loadingStations[index]
	end

	return nil
end

function StorageSystem:getLoadingStations()
	return self.loadingStations
end

function StorageSystem:getIsLoadingStationAvailable(loadingStation)
	return self.loadingStations[loadingStation] ~= nil
end

function StorageSystem:addStorageToLoadingStation(storage, loadingStation)
	if loadingStation:addSourceStorage(storage) then
		g_messageCenter:publish(MessageType.STORAGE_ADDED_TO_LOADING_STATION, storage, loadingStation)

		return true
	end
end

function StorageSystem:addStorageToLoadingStations(storage, loadingStations, farmId)
	local success = false

	for _, loadingStation in pairs(loadingStations) do
		if self:addStorageToLoadingStation(storage, loadingStation) then
			success = true
		end
	end

	return success
end

function StorageSystem:removeStorageFromLoadingStations(storage, loadingStations)
	local success = false

	for _, loadingStation in pairs(loadingStations) do
		if loadingStation:removeSourceStorage(storage) then
			g_messageCenter:publish(MessageType.STORAGE_REMOVED_FROM_LOADING_STATION, storage, loadingStation)

			success = true
		end
	end

	return success
end

function StorageSystem:getExtendableLoadingStationsInRange(storage, farmId, posX, posY, posZ)
	local stationsInRange = {}

	for station, _ in pairs(self.extendableLoadingStations) do
		if self:getIsStationCompatible(station, storage, farmId, posX, posY, posZ) then
			table.insert(stationsInRange, station)
		end
	end

	return stationsInRange
end

function StorageSystem:addUnloadingStation(station, placeable)
	if station ~= nil then
		self.unloadingStations[station] = station

		g_messageCenter:publish(MessageType.UNLOADING_STATIONS_CHANGED)

		if placeable == nil then
			Logging.error("StorageSystem:addUnloadingStation(): no placeable given")
			printCallstack()

			return false
		end

		if self.placeableUnloadingStations[placeable] == nil then
			self.placeableUnloadingStations[placeable] = {}
		end

		table.insert(self.placeableUnloadingStations[placeable], station)

		if station.supportsExtension then
			self.extendableUnloadingStations[station] = station
		end

		return true
	end

	return false
end

function StorageSystem:removeUnloadingStation(station, placeable)
	if station ~= nil then
		self.unloadingStations[station] = nil
		self.extendableUnloadingStations[station] = nil

		if placeable ~= nil and self.placeableUnloadingStations[placeable] ~= nil then
			for k, s in ipairs(self.placeableUnloadingStations[placeable]) do
				if station == s then
					table.remove(self.placeableUnloadingStations[placeable], k)
				end
			end

			if #self.placeableUnloadingStations[placeable] == 0 then
				self.placeableUnloadingStations[placeable] = nil
			end
		end

		g_messageCenter:publish(MessageType.UNLOADING_STATIONS_CHANGED)

		return true
	end

	return false
end

function StorageSystem:getPlaceableUnloadingStationIndex(placeable, station)
	if self.placeableUnloadingStations[placeable] ~= nil then
		for k, s in ipairs(self.placeableUnloadingStations[placeable]) do
			if station == s then
				return k
			end
		end
	end

	return nil
end

function StorageSystem:getPlaceableUnloadingStation(placeable, index)
	local unloadingStations = self.placeableUnloadingStations[placeable]

	if unloadingStations ~= nil then
		return unloadingStations[index]
	end

	return nil
end

function StorageSystem:getUnloadingStations()
	return self.unloadingStations
end

function StorageSystem:getIsUnloadingStationAvailable(unloadingStation)
	return self.unloadingStations[unloadingStation] ~= nil
end

function StorageSystem:addStorageToUnloadingStation(storage, unloadingStation)
	if unloadingStation:addTargetStorage(storage) then
		g_messageCenter:publish(MessageType.STORAGE_ADDED_TO_UNLOADING_STATION, storage, unloadingStation)

		return true
	end
end

function StorageSystem:addStorageToUnloadingStations(storage, unloadingStations)
	local success = false

	for _, unloadingStation in pairs(unloadingStations) do
		if self:addStorageToUnloadingStation(storage, unloadingStation) then
			success = true
		end
	end

	return success
end

function StorageSystem:removeStorageFromUnloadingStations(storage, unloadingStations)
	local success = false

	for _, unloadingStation in pairs(unloadingStations) do
		if unloadingStation:removeTargetStorage(storage) then
			g_messageCenter:publish(MessageType.STORAGE_REMOVED_FROM_UNLOADING_STATION, storage, unloadingStation)

			success = true
		end
	end

	return success
end

function StorageSystem:getExtendableUnloadingStationsInRange(storage, farmId, posX, posY, posZ)
	local stationsInRange = {}

	for station, _ in pairs(self.extendableUnloadingStations) do
		if self:getIsStationCompatible(station, storage, farmId, posX, posY, posZ) then
			table.insert(stationsInRange, station)
		end
	end

	return stationsInRange
end

function StorageSystem:getIsStationCompatible(station, storage, farmId, posX, posY, posZ)
	local hasRadius = station.storageRadius ~= nil
	local canAccessTarget = self.accessHandler:canFarmAccess(farmId, station)

	if hasRadius and canAccessTarget then
		local distance = nil

		if posX ~= nil and posY ~= nil and posZ ~= nil then
			local x, y, z = getWorldTranslation(station.rootNode)
			distance = MathUtil.vector3Length(x - posX, y - posY, z - posZ)
		else
			distance = calcDistanceFrom(storage.rootNode, station.rootNode)
		end

		local isInRange = distance < station.storageRadius

		if not isInRange then
			return false
		end

		local hasMatchingFillType = false

		for fillType, _ in pairs(storage.fillTypes) do
			if station.supportedFillTypes[fillType] ~= nil then
				hasMatchingFillType = true
			end
		end

		if not hasMatchingFillType then
			return false
		end

		return true
	end

	return false
end
