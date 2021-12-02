PalletSpawner = {
	RESULT_NO_SPACE = 0,
	RESULT_SUCCESS = 1,
	RESULT_ERROR_LOADING_PALLET = 2,
	PALLET_ALREADY_PRESENT = 3,
	NO_PALLET_FOR_FILLTYPE = 4
}
local PalletSpawner_mt = Class(PalletSpawner)

function PalletSpawner.new(customMt)
	local self = setmetatable({}, customMt or PalletSpawner_mt)
	self.spawnQueue = {}
	self.currentObjectToSpawn = nil

	return self
end

function PalletSpawner:load(components, xmlFile, key, customEnv, i3dMappings)
	self.rootNode = xmlFile:getValue(key .. "#node", components[1].node, components, i3dMappings)
	self.spawnPlaces = {}

	xmlFile:iterate(key .. ".spawnPlaces.spawnPlace", function (index, spawnPlaceKey)
		local spawnPlace = PlacementUtil.loadPlaceFromXML(xmlFile, spawnPlaceKey, components, i3dMappings)

		table.insert(self.spawnPlaces, spawnPlace)
	end)

	if #self.spawnPlaces == 0 then
		Logging.xmlError(xmlFile, "No spawn place(s) defined for pallet spawner %s%s", key, ".spawnPlaces")

		return false
	end

	self.pallets = {}
	self.fillTypeIdToPallet = {}

	for fillTypeId, fillType in pairs(g_fillTypeManager.indexToFillType) do
		if fillType.palletFilename then
			self:loadPalletFromFilename(fillType.palletFilename, fillTypeId)
		end
	end

	xmlFile:iterate(key .. ".pallets.pallet", function (index, palletKey)
		local palletFilename = Utils.getFilename(xmlFile:getValue(palletKey .. "#filename"), self.baseDirectory)

		self:loadPalletFromFilename(palletFilename)
	end)

	return true
end

function PalletSpawner:delete()
end

function PalletSpawner:loadPalletFromFilename(palletFilename, limitFillTypeId)
	if palletFilename ~= nil then
		local pallet = {
			filename = palletFilename,
			size = StoreItemUtil.getSizeValues(palletFilename, "vehicle", 0, {})
		}
		local palletXmlFile = XMLFile.load("palletXmlFilename", palletFilename, Vehicle.xmlSchema)
		local fillTypeNamesAndCategories = FillUnit.getFillTypeNamesFromXML(palletXmlFile)
		pallet.capacity = FillUnit.getCapacityFromXml(palletXmlFile)

		palletXmlFile:delete()

		local palletFillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeNamesAndCategories.fillTypeCategoryNames)
		local fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNamesAndCategories.fillTypeNames)

		for i = 1, #fillTypes do
			table.insert(palletFillTypes, fillTypes[i])
		end

		local hadMatchingFillType = false

		for i = 1, #palletFillTypes do
			local fillTypeId = palletFillTypes[i]

			if limitFillTypeId == nil or limitFillTypeId == fillTypeId then
				self.fillTypeIdToPallet[fillTypeId] = pallet
				hadMatchingFillType = true
			end
		end

		if hadMatchingFillType then
			table.insert(self.pallets, pallet)

			return pallet
		end
	end

	return nil
end

function PalletSpawner:getSupportedFillTypes()
	return self.fillTypeIdToPallet
end

function PalletSpawner:spawnPallet(farmId, fillTypeId, callback, callbackTarget)
	local pallet = self.fillTypeIdToPallet[fillTypeId]

	if pallet ~= nil then
		table.insert(self.spawnQueue, {
			pallet = pallet,
			fillType = fillTypeId,
			farmId = farmId,
			callback = callback,
			callbackTarget = callbackTarget
		})
		g_currentMission:addUpdateable(self)
	else
		Logging.devError("PalletSpawner: no pallet for fillTypeId", fillTypeId)
		callback(callbackTarget, nil, PalletSpawner.NO_PALLET_FOR_FILLTYPE, fillTypeId)
	end
end

function PalletSpawner:getOrSpawnPallet(farmId, fillTypeId, callback, callbackTarget)
	self.foundExistingPallet = nil
	self.getOrSpawnPalletFilltype = fillTypeId

	for i = 1, #self.spawnPlaces do
		local place = self.spawnPlaces[i]
		local x = place.startX + place.width / 2 * place.dirX
		local y = place.startY + place.width / 2 * place.dirY
		local z = place.startZ + place.width / 2 * place.dirZ

		overlapBox(x, y, z, place.rotX, place.rotY, place.rotZ, place.width / 2, 1, 1, "onFindExistingPallet", self, CollisionMask.VEHICLE, true, false, true)
	end

	if self.foundExistingPallet ~= nil then
		callback(callbackTarget, self.foundExistingPallet, PalletSpawner.PALLET_ALREADY_PRESENT, fillTypeId)
	else
		self:spawnPallet(farmId, fillTypeId, callback, callbackTarget)
	end
end

function PalletSpawner:getAllPallets(fillTypeId, callbackFunc, callbackTarget)
	self.getAllPalletsFoundPallets = {}
	self.getAllPalletsFilltype = fillTypeId

	for i = 1, #self.spawnPlaces do
		local place = self.spawnPlaces[i]
		local x = place.startX + place.width / 2 * place.dirX
		local y = place.startY + place.width / 2 * place.dirY
		local z = place.startZ + place.width / 2 * place.dirZ

		overlapBox(x, y, z, place.rotX, place.rotY, place.rotZ, place.width / 2, 1, 1, "onFindPallet", self, CollisionMask.VEHICLE, true, false, true)
	end

	callbackFunc(callbackTarget, table.toList(self.getAllPalletsFoundPallets))
end

function PalletSpawner:update(dt)
	if #self.spawnQueue > 0 then
		if self.currentObjectToSpawn == nil then
			self.currentObjectToSpawn = self.spawnQueue[1]

			g_currentMission.placementManager:getPlaceAsync(self.spawnPlaces, self.currentObjectToSpawn.pallet.size, self.onSpawnSearchFinished, self)
		end
	else
		g_currentMission:removeUpdateable(self)
	end
end

function PalletSpawner:onSpawnSearchFinished(location)
	local objectToSpawn = self.currentObjectToSpawn

	if location ~= nil then
		location.yOffset = 0.3

		VehicleLoadingUtil.loadVehicle(objectToSpawn.pallet.filename, location, true, 0, Vehicle.PROPERTY_STATE_OWNED, objectToSpawn.farmId, nil, , self.onFinishLoadingPallet, self)
	else
		objectToSpawn.callback(objectToSpawn.callbackTarget, nil, PalletSpawner.RESULT_NO_SPACE)

		self.currentObjectToSpawn = nil

		table.remove(self.spawnQueue, 1)
	end
end

function PalletSpawner:onFinishLoadingPallet(vehicle, vehicleLoadState)
	local objectToSpawn = self.currentObjectToSpawn
	local statusCode = vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_OK and PalletSpawner.RESULT_SUCCESS or PalletSpawner.RESULT_ERROR_LOADING_PALLET

	objectToSpawn.callback(objectToSpawn.callbackTarget, vehicle, statusCode, objectToSpawn.fillType)

	self.currentObjectToSpawn = nil

	table.remove(self.spawnQueue, 1)
end

function PalletSpawner:onFindExistingPallet(node)
	local object = g_currentMission.nodeToObject[node]

	if object ~= nil and object.isa ~= nil and object:isa(Vehicle) and object.typeName == "pallet" and object:getFillUnitFreeCapacity(1, self.getOrSpawnPalletFilltype) > 0 then
		self.foundExistingPallet = object

		return false
	end
end

function PalletSpawner:onFindPallet(node)
	local object = g_currentMission.nodeToObject[node]

	if object ~= nil and object.isa ~= nil and object:isa(Vehicle) and object.typeName == "pallet" and object:getFillUnitFillType(1) == self.getAllPalletsFilltype then
		self.getAllPalletsFoundPallets[object] = true
	end
end

function PalletSpawner.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "root node")
	PlacementUtil.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".pallets.pallet(?)#filename", "Path to pallet xml file")
end
