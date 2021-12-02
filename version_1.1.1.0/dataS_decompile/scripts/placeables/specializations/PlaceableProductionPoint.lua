PlaceableProductionPoint = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(PlaceableInfoTrigger, specializations)
	end,
	registerEvents = function (placeableType)
		SpecializationUtil.registerEvent(placeableType, "onOutputFillTypesChanged")
		SpecializationUtil.registerEvent(placeableType, "onProductionStatusChanged")
	end
}

function PlaceableProductionPoint.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "outputsChanged", PlaceableProductionPoint.outputsChanged)
	SpecializationUtil.registerFunction(placeableType, "productionStatusChanged", PlaceableProductionPoint.productionStatusChanged)
end

function PlaceableProductionPoint.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "setOwnerFarmId", PlaceableProductionPoint.setOwnerFarmId)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "collectPickObjects", PlaceableProductionPoint.collectPickObjects)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "canBuy", PlaceableProductionPoint.canBuy)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "updateInfo", PlaceableProductionPoint.updateInfo)
end

function PlaceableProductionPoint.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableProductionPoint)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableProductionPoint)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableProductionPoint)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableProductionPoint)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableProductionPoint)
end

function PlaceableProductionPoint.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("ProductionPoint")
	ProductionPoint.registerXMLPaths(schema, basePath .. ".productionPoint")
	schema:setXMLSpecializationType()
end

function PlaceableProductionPoint.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("ProductionPoint")
	ProductionPoint.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType()
end

function PlaceableProductionPoint.initSpecialization()
	g_storeManager:addSpecType("prodPointInputFillTypes", "shopListAttributeIconInput", ProductionPoint.loadSpecValueInputFillTypes, ProductionPoint.getSpecValueInputFillTypes, "placeable")
	g_storeManager:addSpecType("prodPointOutputFillTypes", "shopListAttributeIconOutput", ProductionPoint.loadSpecValueOutputFillTypes, ProductionPoint.getSpecValueOutputFillTypes, "placeable")
end

function PlaceableProductionPoint:onLoad(savegame)
	local spec = self.spec_productionPoint
	local productionPoint = ProductionPoint.new(self.isServer, self.isClient)
	productionPoint.owningPlaceable = self

	if productionPoint:load(self.components, self.xmlFile, "placeable.productionPoint", self.customEnvironment, self.i3dMappings) then
		spec.productionPoint = productionPoint
	else
		productionPoint:delete()
		self:setLoadingState(Placeable.LOADING_STATE_ERROR)
	end
end

function PlaceableProductionPoint:onDelete()
	local spec = self.spec_productionPoint

	if spec.productionPoint ~= nil then
		spec.productionPoint:delete()

		spec.productionPoint = nil
	end
end

function PlaceableProductionPoint:onFinalizePlacement()
	local spec = self.spec_productionPoint

	if spec.productionPoint ~= nil then
		spec.productionPoint:register(true)
		spec.productionPoint:setOwnerFarmId(self:getOwnerFarmId())
		spec.productionPoint:updateFxState()
	end
end

function PlaceableProductionPoint:updateInfo(superFunc, infoTable)
	self.spec_productionPoint.productionPoint:updateInfo(superFunc, infoTable)
end

function PlaceableProductionPoint:outputsChanged(outputs, state)
	SpecializationUtil.raiseEvent(self, "onOutputFillTypesChanged", outputs, state)
end

function PlaceableProductionPoint:productionStatusChanged(production, status)
	SpecializationUtil.raiseEvent(self, "onProductionStatusChanged", production, status)
end

function PlaceableProductionPoint:onReadStream(streamId, connection)
	local spec = self.spec_productionPoint

	if spec.productionPoint ~= nil then
		local productionPointId = NetworkUtil.readNodeObjectId(streamId)

		spec.productionPoint:readStream(streamId, connection)
		g_client:finishRegisterObject(spec.productionPoint, productionPointId)
	end
end

function PlaceableProductionPoint:onWriteStream(streamId, connection)
	local spec = self.spec_productionPoint

	if spec.productionPoint ~= nil then
		NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spec.productionPoint))
		spec.productionPoint:writeStream(streamId, connection)
		g_server:registerObjectInStream(connection, spec.productionPoint)
	end
end

function PlaceableProductionPoint:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_productionPoint

	if spec.productionPoint ~= nil then
		spec.productionPoint:loadFromXMLFile(xmlFile, key)
	end
end

function PlaceableProductionPoint:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_productionPoint

	if spec.productionPoint ~= nil then
		spec.productionPoint:saveToXMLFile(xmlFile, key, usedModNames)
	end
end

function PlaceableProductionPoint:setOwnerFarmId(superFunc, farmId, noEventSend)
	superFunc(self, farmId, noEventSend)

	local spec = self.spec_productionPoint

	if spec.productionPoint ~= nil then
		spec.productionPoint:setOwnerFarmId(farmId)
	end
end

function PlaceableProductionPoint:collectPickObjects(superFunc, node)
	local spec = self.spec_productionPoint

	if spec.productionPoint.loadingStation ~= nil then
		for i = 1, #spec.productionPoint.loadingStation.loadTriggers do
			local loadTrigger = spec.productionPoint.loadingStation.loadTriggers[i]

			if node == loadTrigger.triggerNode then
				return
			end
		end
	end

	for i = 1, #spec.productionPoint.unloadingStation.unloadTriggers do
		local unloadTrigger = spec.productionPoint.unloadingStation.unloadTriggers[i]

		if node == unloadTrigger.exactFillRootNode then
			return
		end
	end

	superFunc(self, node)
end

function PlaceableProductionPoint:canBuy(superFunc)
	if not g_currentMission.productionChainManager:getHasFreeSlots() then
		return false, "max number of production points reached"
	end

	return superFunc(self)
end
