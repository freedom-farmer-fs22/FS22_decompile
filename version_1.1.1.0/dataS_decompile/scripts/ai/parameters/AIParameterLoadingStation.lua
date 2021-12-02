AIParameterLoadingStation = {}
local AIParameterLoadingStation_mt = Class(AIParameterLoadingStation, AIParameter)

function AIParameterLoadingStation.new(customMt)
	local self = AIParameter.new(customMt or AIParameterLoadingStation_mt)
	self.type = AIParameterType.LOADING_STATION
	self.loadingStationId = nil
	self.loadingStationIds = {}

	return self
end

function AIParameterLoadingStation:saveToXMLFile(xmlFile, key, usedModNames)
	local loadingStation = self:getLoadingStation()

	if loadingStation ~= nil then
		local owningPlaceable = loadingStation.owningPlaceable

		if owningPlaceable ~= nil and owningPlaceable.currentSavegameId ~= nil then
			local index = g_currentMission.storageSystem:getPlaceableLoadingStationIndex(owningPlaceable, loadingStation)

			if index ~= nil then
				xmlFile:setInt(key .. "#stationId", owningPlaceable.currentSavegameId)
				xmlFile:setInt(key .. "#stationIndex", index)
			end
		end
	end
end

function AIParameterLoadingStation:loadFromXMLFile(xmlFile, key)
	local loadingStationSavegameId = xmlFile:getInt(key .. "#stationId")
	local stationIndex = xmlFile:getInt(key .. "#stationIndex")

	if loadingStationSavegameId ~= nil and stationIndex ~= nil and not self:setLoadingStationFromSavegameId(loadingStationSavegameId, stationIndex) then
		g_messageCenter:subscribeOneshot(MessageType.LOADED_ALL_SAVEGAME_PLACEABLES, self.onPlaceableLoaded, self, {
			loadingStationSavegameId,
			stationIndex
		})
	end
end

function AIParameterLoadingStation:onPlaceableLoaded(args)
	g_messageCenter:unsubscribe(MessageType.LOADED_ALL_SAVEGAME_PLACEABLES, self)
	self:setLoadingStationFromSavegameId(args[1], args[2])
end

function AIParameterLoadingStation:setLoadingStationFromSavegameId(savegameId, index)
	local placeable = g_currentMission.placeableSystem:getPlaceableBySavegameId(savegameId)

	if placeable ~= nil then
		local loadingStation = g_currentMission.storageSystem:getPlaceableLoadingStation(placeable, index)

		self:setLoadingStation(loadingStation)

		return true
	end

	return false
end

function AIParameterLoadingStation:readStream(streamId, connection)
	if streamReadBool(streamId) then
		self.loadingStationId = NetworkUtil.readNodeObjectId(streamId)
	end
end

function AIParameterLoadingStation:writeStream(streamId, connection)
	if streamWriteBool(streamId, self.loadingStationId ~= nil) then
		NetworkUtil.writeNodeObjectId(streamId, self.loadingStationId)
	end
end

function AIParameterLoadingStation:setLoadingStation(loadingStation)
	self.loadingStationId = NetworkUtil.getObjectId(loadingStation)
end

function AIParameterLoadingStation:getLoadingStation()
	local loadingStation = NetworkUtil.getObject(self.loadingStationId)

	if loadingStation ~= nil and loadingStation.owningPlaceable ~= nil and loadingStation.owningPlaceable:getIsSynchronized() then
		return loadingStation
	end

	return nil
end

function AIParameterLoadingStation:getString()
	local loadingStation = NetworkUtil.getObject(self.loadingStationId)

	if loadingStation ~= nil then
		return loadingStation:getName()
	end

	return ""
end

function AIParameterLoadingStation:setValidLoadingStations(loadingStationIds)
	self.loadingStationIds = {}
	local nextLoadingStationId = nil

	for _, loadingStation in ipairs(loadingStationIds) do
		local id = NetworkUtil.getObjectId(loadingStation)

		if id ~= nil then
			if id == self.loadingStationId then
				nextLoadingStationId = id
			end

			table.insert(self.loadingStationIds, id)
		end
	end

	self.loadingStationId = nextLoadingStationId or self.loadingStationIds[1]
end

function AIParameterLoadingStation:setNextItem()
	local nextIndex = 0

	for k, loadingStationId in ipairs(self.loadingStationIds) do
		if loadingStationId == self.loadingStationId then
			nextIndex = k + 1
		end
	end

	if nextIndex > #self.loadingStationIds then
		nextIndex = 1
	end

	self.loadingStationId = self.loadingStationIds[nextIndex]
end

function AIParameterLoadingStation:setPreviousItem()
	local previousIndex = 0

	for k, loadingStationId in ipairs(self.loadingStationIds) do
		if loadingStationId == self.loadingStationId then
			previousIndex = k - 1
		end
	end

	if previousIndex < 1 then
		previousIndex = #self.loadingStationIds
	end

	self.loadingStationId = self.loadingStationIds[previousIndex]
end

function AIParameterLoadingStation:validate(fillTypeIndex, farmId)
	if self.loadingStationId == nil then
		return false, g_i18n:getText("ai_validationErrorNoLoadingStation")
	end

	local loadingStation = self:getLoadingStation()

	if loadingStation == nil then
		return false, g_i18n:getText("ai_validationErrorLoadingStationDoesNotExistAnymore")
	end

	if fillTypeIndex ~= nil then
		if not loadingStation:getIsFillTypeAISupported(fillTypeIndex) then
			return false, g_i18n:getText("ai_validationErrorFillTypeNotSupportedByLoadingStation")
		elseif loadingStation:getFillLevel(fillTypeIndex, farmId) <= 0 then
			return false, g_i18n:getText("ai_validationErrorLoadingStationIsEmpty")
		end
	end

	return true, nil
end
