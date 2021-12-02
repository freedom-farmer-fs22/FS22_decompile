PlaceableSellingStation = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function PlaceableSellingStation.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "getSellingStation", PlaceableSellingStation.getSellingStation)
end

function PlaceableSellingStation.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableSellingStation.collectPickObjects)
end

function PlaceableSellingStation.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableSellingStation)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableSellingStation)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableSellingStation)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableSellingStation)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableSellingStation)
end

function PlaceableSellingStation.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("SellingStation")
	SellingStation.registerXMLPaths(schema, basePath .. ".sellingStation")
	schema:setXMLSpecializationType()
end

function PlaceableSellingStation.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("SellingStation")
	SellingStation.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end

function PlaceableSellingStation.initSpecialization()
	g_storeManager:addSpecType("sellingStationFillTypes", "shopListAttributeIconInput", SellingStation.loadSpecValueFillTypes, SellingStation.getSpecValueFillTypes, "placeable")
end

function PlaceableSellingStation:onLoad(savegame)
	local spec = self.spec_sellingStation
	local xmlFile = self.xmlFile
	spec.sellingStation = SellingStation.new(self.isServer, self.isClient)

	spec.sellingStation:load(self.components, xmlFile, "placeable.sellingStation", self.customEnvironment, self.i3dMappings, self.components[1].node)

	spec.sellingStation.owningPlaceable = self
end

function PlaceableSellingStation:onDelete()
	local spec = self.spec_sellingStation

	if spec.sellingStation ~= nil then
		g_currentMission.storageSystem:removeUnloadingStation(spec.sellingStation, self)
		g_currentMission.economyManager:removeSellingStation(spec.sellingStation)
		spec.sellingStation:delete()
	end
end

function PlaceableSellingStation:onFinalizePlacement()
	local spec = self.spec_sellingStation

	spec.sellingStation:register(true)
	g_currentMission.storageSystem:addUnloadingStation(spec.sellingStation, self)
	g_currentMission.economyManager:addSellingStation(spec.sellingStation)
end

function PlaceableSellingStation:onReadStream(streamId, connection)
	local spec = self.spec_sellingStation
	local sellingStationId = NetworkUtil.readNodeObjectId(streamId)

	spec.sellingStation:readStream(streamId, connection)
	g_client:finishRegisterObject(spec.sellingStation, sellingStationId)
end

function PlaceableSellingStation:onWriteStream(streamId, connection)
	local spec = self.spec_sellingStation

	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.sellingStation))
	spec.sellingStation:writeStream(streamId, connection)
	g_server:registerObjectInStream(connection, spec.sellingStation)
end

function PlaceableSellingStation:getSellingStation()
	return self.spec_sellingStation.sellingStation
end

function PlaceableSellingStation:collectPickObjects(superFunc, node)
	local spec = self.spec_sellingStation
	local foundNode = false

	for _, unloadTrigger in ipairs(spec.sellingStation.unloadTriggers) do
		if node == unloadTrigger.exactFillRootNode then
			foundNode = true

			break
		end
	end

	if not foundNode then
		superFunc(self, node)
	end
end

function PlaceableSellingStation:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_sellingStation

	spec.sellingStation:loadFromXMLFile(xmlFile, key)
end

function PlaceableSellingStation:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_sellingStation

	spec.sellingStation:saveToXMLFile(xmlFile, key, usedModNames)
end
