PlaceableBuyingStation = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableBuyingStation.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getBuyingStation", PlaceableBuyingStation.getBuyingStation)
end

function PlaceableBuyingStation.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableBuyingStation.collectPickObjects)
end

function PlaceableBuyingStation.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableBuyingStation)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableBuyingStation)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableBuyingStation)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableBuyingStation)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableBuyingStation)
end

function PlaceableBuyingStation.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("BuyingStation")
	BuyingStation.registerXMLPaths(schema, basePath .. ".buyingStation")
	schema:setXMLSpecializationType()
end

function PlaceableBuyingStation:onLoad(savegame)
	local spec = self.spec_buyingStation
	local buyingStation = BuyingStation.new(self.isServer, self.isClient)

	if buyingStation:load(self.components, self.xmlFile, "placeable.buyingStation", self.customEnvironment, self.i3dMappings) then
		spec.buyingStation = buyingStation
		spec.buyingStation.owningPlaceable = self

		g_currentMission.storageSystem:addLoadingStation(spec.buyingStation, spec.buyingStation.owningPlaceable)
	else
		Logging.xmlError(self.xmlFile, "Could not load buying station")
		buyingStation:delete()
	end
end

function PlaceableBuyingStation:onDelete()
	local spec = self.spec_buyingStation

	if spec.buyingStation ~= nil then
		g_currentMission.storageSystem:removeLoadingStation(spec.buyingStation, spec.buyingStation.owningPlaceable)
		spec.buyingStation:delete()
	end
end

function PlaceableBuyingStation:onFinalizePlacement()
	local spec = self.spec_buyingStation

	if spec.buyingStation ~= nil then
		spec.buyingStation:register(true)
	end
end

function PlaceableBuyingStation:onReadStream(streamId, connection)
	local spec = self.spec_buyingStation

	if spec.buyingStation ~= nil then
		local buyingStationId = NetworkUtil.readNodeObjectId(streamId)

		spec.buyingStation:readStream(streamId, connection)
		g_client:finishRegisterObject(spec.buyingStation, buyingStationId)
	end
end

function PlaceableBuyingStation:onWriteStream(streamId, connection)
	local spec = self.spec_buyingStation

	if spec.buyingStation ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.buyingStation))
		spec.buyingStation:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, spec.buyingStation)
	end
end

function PlaceableBuyingStation:collectPickObjects(superFunc, node)
	local spec = self.spec_buyingStation

	if spec.buyingStation ~= nil then
		for _, loadTrigger in ipairs(spec.buyingStation.loadTriggers) do
			if node == loadTrigger.triggerNode then
				return
			end
		end
	end

	superFunc(self, node)
end

function PlaceableBuyingStation:getBuyingStation()
	return self.spec_buyingStation.buyingStation
end
