PlaceableTrainSystem = {}

source("dataS/scripts/placeables/specializations/events/PlaceableTrainSystemRentEvent.lua")
source("dataS/scripts/placeables/specializations/events/PlaceableTrainSystemSellEvent.lua")

function PlaceableTrainSystem.prerequisitesPresent(specializations)
	return true
end

function PlaceableTrainSystem.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "createVehicles", PlaceableTrainSystem.createVehicles)
	SpecializationUtil.registerFunction(placeableType, "railroadVehicleLoaded", PlaceableTrainSystem.railroadVehicleLoaded)
	SpecializationUtil.registerFunction(placeableType, "finalizeTrain", PlaceableTrainSystem.finalizeTrain)
	SpecializationUtil.registerFunction(placeableType, "setIsTrainTabbable", PlaceableTrainSystem.setIsTrainTabbable)
	SpecializationUtil.registerFunction(placeableType, "getIsTrainInDriveableRange", PlaceableTrainSystem.getIsTrainInDriveableRange)
	SpecializationUtil.registerFunction(placeableType, "getSplineTime", PlaceableTrainSystem.getSplineTime)
	SpecializationUtil.registerFunction(placeableType, "setSplineTime", PlaceableTrainSystem.setSplineTime)
	SpecializationUtil.registerFunction(placeableType, "addSplinePositionUpdateListener", PlaceableTrainSystem.addSplinePositionUpdateListener)
	SpecializationUtil.registerFunction(placeableType, "removeSplinePositionUpdateListener", PlaceableTrainSystem.removeSplinePositionUpdateListener)
	SpecializationUtil.registerFunction(placeableType, "updateTrainPositionByLocomotiveSpeed", PlaceableTrainSystem.updateTrainPositionByLocomotiveSpeed)
	SpecializationUtil.registerFunction(placeableType, "updateTrainPositionByLocomotiveSplinePosition", PlaceableTrainSystem.updateTrainPositionByLocomotiveSplinePosition)
	SpecializationUtil.registerFunction(placeableType, "updateTrainLength", PlaceableTrainSystem.updateTrainLength)
	SpecializationUtil.registerFunction(placeableType, "toggleRent", PlaceableTrainSystem.toggleRent)
	SpecializationUtil.registerFunction(placeableType, "getCanBeRented", PlaceableTrainSystem.getCanBeRented)
	SpecializationUtil.registerFunction(placeableType, "rentRailroad", PlaceableTrainSystem.rentRailroad)
	SpecializationUtil.registerFunction(placeableType, "returnRailroad", PlaceableTrainSystem.returnRailroad)
	SpecializationUtil.registerFunction(placeableType, "onDeleteObject", PlaceableTrainSystem.onDeleteObject)
	SpecializationUtil.registerFunction(placeableType, "getIsRented", PlaceableTrainSystem.getIsRented)
	SpecializationUtil.registerFunction(placeableType, "getSplineLength", PlaceableTrainSystem.getSplineLength)
	SpecializationUtil.registerFunction(placeableType, "getElectricitySpline", PlaceableTrainSystem.getElectricitySpline)
	SpecializationUtil.registerFunction(placeableType, "getElectricitySplineLength", PlaceableTrainSystem.getElectricitySplineLength)
	SpecializationUtil.registerFunction(placeableType, "getLengthSplineTime", PlaceableTrainSystem.getLengthSplineTime)
	SpecializationUtil.registerFunction(placeableType, "getSpline", PlaceableTrainSystem.getSpline)
	SpecializationUtil.registerFunction(placeableType, "updateDriveableState", PlaceableTrainSystem.updateDriveableState)
	SpecializationUtil.registerFunction(placeableType, "gsIsTrainFilled", PlaceableTrainSystem.gsIsTrainFilled)
	SpecializationUtil.registerFunction(placeableType, "onSellGoodsQuestion", PlaceableTrainSystem.onSellGoodsQuestion)
	SpecializationUtil.registerFunction(placeableType, "sellGoods", PlaceableTrainSystem.sellGoods)
end

function PlaceableTrainSystem.registerOverwrittenFunctions(placeableType)
	SpecializationUtil.registerOverwrittenFunction(placeableType, "getNeedDayChanged", PlaceableTrainSystem.getNeedDayChanged)
end

function PlaceableTrainSystem.registerEventListeners(placeableType)
	SpecializationUtil.registerEventListener(placeableType, "onLoad", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onDelete", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onFinalizePlacement", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onReadStream", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onWriteStream", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onReadUpdateStream", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onWriteUpdateStream", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onUpdate", PlaceableTrainSystem)
	SpecializationUtil.registerEventListener(placeableType, "onDayChanged", PlaceableTrainSystem)
end

function PlaceableTrainSystem.registerXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Train")
	schema:register(XMLValueType.FLOAT, basePath .. ".trainSystem.rent#pricePerHour", "Rent price per real time hour", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".trainSystem.spline#node", "Spline node")
	schema:register(XMLValueType.FLOAT, basePath .. ".trainSystem.spline#splineYOffset", "Spline Y offset", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".trainSystem.drivingRange#startNode", "Start of range node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".trainSystem.drivingRange#endNode", "End of range node")
	schema:register(XMLValueType.STRING, basePath .. ".trainSystem.drivingRange#sellingStationId", "Map bound id of selling station")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".trainSystem.electricitySpline#node", "Electricity spline")
	schema:register(XMLValueType.FLOAT, basePath .. ".trainSystem.electricitySpline#splineYOffset", "Electricity spline Y offset", 0)
	schema:register(XMLValueType.STRING, basePath .. ".trainSystem.train.vehicle(?)#xmlFilename", "XMl filename")
	RailroadCrossing.registerXMLPaths(schema, basePath .. ".trainSystem.railroadCrossings.railroadCrossing(?)")
	RailroadCaller.registerXMLPaths(schema, basePath .. ".trainSystem.railroadCallers.railroadCaller(?)")
	schema:setXMLSpecializationType()
end

function PlaceableTrainSystem.registerSavegameXMLPaths(schema, basePath)
	schema:setXMLSpecializationType("Train")
	schema:register(XMLValueType.FLOAT, basePath .. "#splineTime", "Current spline time")
	schema:register(XMLValueType.BOOL, basePath .. "#isRented", "Is train rented")
	schema:register(XMLValueType.INT, basePath .. "#rentFarmId", "Train is rented by farm")
	schema:register(XMLValueType.FLOAT, basePath .. "#currentPrice", "Current pending rent price")
	schema:register(XMLValueType.INT, basePath .. ".railroadVehicle(?)#vehicleId", "Vehicle id")
	schema:register(XMLValueType.INT, basePath .. ".railroadObjects(?)#index", "Object index")
	schema:setXMLSpecializationType()
end

function PlaceableTrainSystem:onLoad(savegame)
	local spec = self.spec_trainSystem
	spec.splineTime = -1
	spec.splineTimeSent = spec.splineTime
	spec.splineEndTime = 0
	spec.trainLengthSplineTime = 0
	spec.splinePositionUpdateListener = {}
	spec.startSplineTime = spec.startSplineTime or 0
	spec.railroadVehicles = {}
	spec.trainLength = 0
	spec.dirtyFlag = self:getNextDirtyFlag()
	spec.stationDirtyFlag = self:getNextDirtyFlag()
	spec.networkTimeInterpolator = InterpolationTime.new(1.2)
	spec.networkSplineTimeInterpolator = InterpolatorValue.new(0)
	spec.isRented = false
	spec.rentFarmId = FarmManager.SPECTATOR_FARM_ID
	spec.lastRentFarmId = FarmManager.SPECTATOR_FARM_ID
	spec.currentPrice = 0
	spec.rentPricePerHour = self.xmlFile:getValue("placeable.trainSystem.rent#pricePerHour", 0)
	spec.rentPricePerMS = spec.rentPricePerHour / 60 / 60 / 1000
	spec.rootLocomotive = nil
	spec.spline = self.xmlFile:getValue("placeable.trainSystem.spline#node", nil, self.components, self.i3dMappings)

	if spec.spline == nil then
		Logging.xmlError(self.xmlFile, "Missing spline node!")
		self:setLoadingState(Placeable.LOADING_STATE_ERROR)

		return
	end

	if not getHasClassId(getGeometry(spec.spline), ClassIds.SPLINE) then
		Logging.xmlError(self.xmlFile, "Given node is not a spline!")
		self:setLoadingState(Placeable.LOADING_STATE_ERROR)

		return
	end

	if not getIsSplineClosed(spec.spline) then
		Logging.xmlError(self.xmlFile, "Train spline is not closed. Open splines are not supported!")
		self:setLoadingState(Placeable.LOADING_STATE_ERROR)

		return false
	end

	spec.splineLength = getSplineLength(spec.spline)
	spec.splineYOffset = self.xmlFile:getValue("placeable.trainSystem.spline#splineYOffset", 0)
	spec.splineDriveRange = {
		0,
		1
	}
	spec.drivingRangeStart = self.xmlFile:getValue("placeable.trainSystem.drivingRange#startNode", nil, self.components, self.i3dMappings)
	spec.drivingRangeEnd = self.xmlFile:getValue("placeable.trainSystem.drivingRange#endNode", nil, self.components, self.i3dMappings)
	spec.drivingRangeSellingStationId = self.xmlFile:getValue("placeable.trainSystem.drivingRange#sellingStationId")
	spec.textDriveInfo = g_i18n:getText("ui_infoTrainDrive")
	spec.textSellQuestion = g_i18n:getText("ui_questionTrainSellGoods")
	spec.hasLimitedRange = false

	if spec.drivingRangeStart ~= nil and spec.drivingRangeEnd ~= nil then
		local nearestDistanceStart = math.huge
		local nearestDistanceEnd = math.huge

		for i = 0, 1, 0.5 / spec.splineLength do
			local sx, sy, sz = getSplinePosition(spec.spline, i)
			local x1, y1, z1 = getWorldTranslation(spec.drivingRangeStart)
			local distance1 = MathUtil.vector3Length(sx - x1, sy - y1, sz - z1)

			if distance1 < nearestDistanceStart then
				nearestDistanceStart = distance1
				spec.splineDriveRange[1] = i
			end

			local x2, y2, z2 = getWorldTranslation(spec.drivingRangeEnd)
			local distance2 = MathUtil.vector3Length(sx - x2, sy - y2, sz - z2)

			if distance2 < nearestDistanceEnd then
				nearestDistanceEnd = distance2
				spec.splineDriveRange[2] = i
			end
		end

		if spec.splineDriveRange[2] < spec.splineDriveRange[1] then
			local secondValue = spec.splineDriveRange[2]
			spec.splineDriveRange[2] = spec.splineDriveRange[1]
			spec.splineDriveRange[1] = secondValue
		end

		spec.hasLimitedRange = true
	end

	spec.sellingStationPlaceable = nil
	spec.sellingStationPlaceableId = nil
	spec.sellingStation = nil
	spec.showDialog = 0
	spec.showDialogDelay = 0
	spec.lastIsInDriveableRange = true
	spec.lastSplineTime = 0
	spec.electricitySpline = self.xmlFile:getValue("placeable.trainSystem.electricitySpline#node", nil, self.components, self.i3dMappings)

	if spec.electricitySpline ~= nil then
		if getHasClassId(getGeometry(spec.electricitySpline), ClassIds.SPLINE) then
			if getIsSplineClosed(spec.electricitySpline) then
				local sx, _, sz = getSplinePosition(spec.spline, 0)
				local esx, _, esz = getSplinePosition(spec.spline, 0)

				if MathUtil.vector2Length(sx - esx, sz - esz) < 5 then
					spec.electricitySplineLength = getSplineLength(spec.electricitySpline)
					spec.electricitySplineYOffset = self.xmlFile:getValue("placeable.trainSystem.electricitySpline#splineYOffset", 0)
				else
					Logging.xmlError(self.xmlFile, "Railroad and electricity spline should almost start at the same x and z positions. Ignoring electricity spline!")

					spec.electricitySpline = nil
				end
			else
				Logging.xmlError(self.xmlFile, "Railroad electricity spline has to be closed. Ignoring electricity spline!")

				spec.electricitySpline = nil
			end
		else
			Logging.xmlError(self.xmlFile, "Given electricitySpline node is not a spline. Ignoring electricity spline!")

			spec.electricitySpline = nil
		end
	end

	spec.vehiclesToLoad = {}

	if self.isServer then
		self.xmlFile:iterate("placeable.trainSystem.train.vehicle", function (_, baseString)
			local filename = self.xmlFile:getValue(baseString .. "#xmlFilename")

			if filename ~= nil then
				table.insert(spec.vehiclesToLoad, filename)
			end
		end)
	end

	spec.railroadObjects = {}
	spec.railroadCrossings = {}

	self.xmlFile:iterate("placeable.trainSystem.railroadCrossings.railroadCrossing", function (_, key)
		local railroadCrossing = RailroadCrossing.new(self.isServer, self.isClient, self, self.rootNode)

		if railroadCrossing:loadFromXML(self.xmlFile, key, self.components, self.i3dMappings) then
			table.insert(spec.railroadCrossings, railroadCrossing)
			table.insert(spec.railroadObjects, railroadCrossing)
		else
			railroadCrossing:delete()
		end
	end)

	spec.railroadCallers = {}

	self.xmlFile:iterate("placeable.trainSystem.railroadCallers.railroadCaller", function (_, key)
		local railroadCaller = RailroadCaller.new(self.isServer, self.isClient, self, self.rootNode)

		if railroadCaller:loadFromXML(self.xmlFile, key, self.components, self.i3dMappings) then
			table.insert(spec.railroadCallers, railroadCaller)
			table.insert(spec.railroadObjects, railroadCaller)
		end
	end)

	for t = 0, 1, 0.5 / spec.splineLength do
		local x1, y1, z1 = getSplinePosition(spec.spline, t)

		for _, object in pairs(spec.railroadObjects) do
			local x2, y2, z2 = getWorldTranslation(object.rootNode)
			local distance = MathUtil.vector3Length(x1 - x2, y1 - y2, z1 - z2)

			if object.nearestDistance == nil then
				object.nearestDistance = distance
				object.nearestTime = t
			elseif distance < object.nearestDistance then
				object.nearestDistance = distance
				object.nearestTime = t
			end
		end
	end

	for _, object in pairs(spec.railroadObjects) do
		if object.setSplineTimeByPosition ~= nil then
			object:setSplineTimeByPosition(object.nearestTime, spec.splineLength)
		end

		if object.onSplinePositionTimeUpdate ~= nil then
			object:onSplinePositionTimeUpdate(spec.splineTime, spec.splineEndTime)
		end
	end

	spec.lastVehicle = nil
	spec.numVehiclesToLoad = 0
end

function PlaceableTrainSystem:onDelete()
	local spec = self.spec_trainSystem

	if spec.railroadObjects ~= nil then
		for _, object in ipairs(spec.railroadObjects) do
			object:delete()
		end
	end

	if spec.railroadVehicles ~= nil then
		for _, vehicle in ipairs(spec.railroadVehicles) do
			vehicle.trainSystem = nil
		end
	end

	g_currentMission:removeTrainSystem(self)
end

function PlaceableTrainSystem:onFinalizePlacement()
	g_currentMission:addTrainSystem(self)
	self:createVehicles()
end

function PlaceableTrainSystem:onReadStream(streamId, connection)
	if connection:getIsServer() then
		local spec = self.spec_trainSystem
		spec.railroadVehicleIds = {}
		local numVehicles = streamReadInt8(streamId)

		for i = 1, numVehicles do
			spec.railroadVehicleIds[i] = NetworkUtil.readNodeObjectId(streamId)
		end

		local splineTime = streamReadFloat32(streamId)

		spec.networkSplineTimeInterpolator:setValue(splineTime)
		spec.networkTimeInterpolator:reset()

		spec.splineTime = splineTime

		for _, railroadObject in ipairs(spec.railroadObjects) do
			if railroadObject.readStream ~= nil then
				railroadObject:readStream(streamId, connection)
			end
		end

		spec.isRented = streamReadBool(streamId)
		spec.rentFarmId = streamReadUIntN(streamId, FarmManager.FARM_ID_SEND_NUM_BITS)
		spec.sellingStationPlaceableId = NetworkUtil.readNodeObjectId(streamId)

		self:raiseActive()
	end
end

function PlaceableTrainSystem:onWriteStream(streamId, connection)
	if not connection:getIsServer() then
		local spec = self.spec_trainSystem
		local numVehicles = #spec.railroadVehicles

		streamWriteInt8(streamId, numVehicles)

		for i = 1, numVehicles do
			NetworkUtil.writeNodeObject(streamId, spec.railroadVehicles[i])
		end

		streamWriteFloat32(streamId, spec.splineTimeSent)

		for _, railroadObject in ipairs(spec.railroadObjects) do
			if railroadObject.writeStream ~= nil then
				railroadObject:writeStream(streamId, connection)
			end
		end

		streamWriteBool(streamId, spec.isRented)
		streamWriteUIntN(streamId, spec.rentFarmId, FarmManager.FARM_ID_SEND_NUM_BITS)
		NetworkUtil.writeNodeObject(streamId, spec.sellingStationPlaceable)
	end
end

function PlaceableTrainSystem:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_trainSystem

	if connection:getIsServer() then
		if streamReadBool(streamId) then
			local splineTime = streamReadFloat32(streamId)

			spec.networkTimeInterpolator:startNewPhaseNetwork()
			spec.networkSplineTimeInterpolator:setTargetValue(splineTime)

			for _, railroadObject in ipairs(spec.railroadObjects) do
				if railroadObject.readUpdateStream ~= nil then
					railroadObject:readUpdateStream(streamId, timestamp, connection)
				end
			end
		end

		if streamReadBool(streamId) then
			spec.sellingStationPlaceableId = NetworkUtil.readNodeObjectId(streamId)
		end
	end
end

function PlaceableTrainSystem:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_trainSystem

	if not connection:getIsServer() then
		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteFloat32(streamId, spec.splineTimeSent)

			for _, railroadObject in ipairs(spec.railroadObjects) do
				if railroadObject.writeUpdateStream ~= nil then
					railroadObject:writeUpdateStream(streamId, connection, dirtyMask)
				end
			end
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.stationDirtyFlag) ~= 0) then
			NetworkUtil.writeNodeObject(streamId, spec.sellingStationPlaceable)
		end
	end
end

function PlaceableTrainSystem:loadFromXMLFile(xmlFile, key)
	local spec = self.spec_trainSystem

	xmlFile:iterate(key .. ".railroadObjects", function (_, railroadKey)
		local index = xmlFile:getValue(railroadKey .. "#index")

		if index ~= nil then
			local object = spec.railroadObjects[index]

			if object ~= nil then
				object:loadFromXMLFile(xmlFile, railroadKey)
			end
		end
	end)

	spec.isRented = xmlFile:getValue(key .. "#isRented", spec.isRented)
	spec.rentFarmId = xmlFile:getValue(key .. "#rentFarmId", spec.rentFarmId)
	spec.lastRentFarmId = spec.rentFarmId
	spec.currentPrice = xmlFile:getValue(key .. "#currentPrice", spec.currentPrice)
	spec.startSplineTime = SplineUtil.getValidSplineTime(xmlFile:getValue(key .. "#splineTime") or 0)
	spec.vehicleIdsToLoad = {}
	local i = 0

	while true do
		local vehicleKey = string.format("%s.railroadVehicle(%d)", key, i)

		if not xmlFile:hasProperty(vehicleKey) then
			break
		end

		local vehicleId = xmlFile:getValue(vehicleKey .. "#vehicleId")

		if vehicleId ~= nil then
			table.insert(spec.vehicleIdsToLoad, vehicleId)
		end

		i = i + 1
	end
end

function PlaceableTrainSystem:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_trainSystem

	xmlFile:setValue(key .. "#splineTime", SplineUtil.getValidSplineTime(spec.splineTime))

	for k, railroadVehicle in ipairs(spec.railroadVehicles) do
		local railroadKey = string.format("%s.railroadVehicle(%d)", key, k - 1)

		xmlFile:setValue(railroadKey .. "#vehicleId", railroadVehicle.currentSavegameId or 0)
	end

	for k, railroadObject in ipairs(spec.railroadObjects) do
		local railroadKey = string.format("%s.railroadObjects(%d)", key, k - 1)

		if railroadObject.saveToXMLFile ~= nil then
			xmlFile:setValue(railroadKey .. "#index", k)
			railroadObject.saveToXMLFile(xmlFile, railroadKey, usedModNames)
		end
	end

	xmlFile:setValue(key .. "#isRented", spec.isRented)
	xmlFile:setValue(key .. "#rentFarmId", spec.rentFarmId)
	xmlFile:setValue(key .. "#currentPrice", spec.currentPrice)
end

function PlaceableTrainSystem:onUpdate(dt)
	local spec = self.spec_trainSystem

	if not self.finishedFirstUpdate then
		self:setIsTrainTabbable(spec.isRented and g_currentMission:getFarmId() == spec.rentFarmId)
	end

	for _, railroadObject in pairs(spec.railroadObjects) do
		if railroadObject.update ~= nil then
			railroadObject:update(dt)
		end
	end

	if spec.isRented then
		spec.currentPrice = spec.currentPrice + spec.rentPricePerMS * dt
	end

	if not self.isServer and self.isClient then
		if spec.railroadVehicleIds ~= nil then
			local allVehiclesSynchronized = true

			for index, id in pairs(spec.railroadVehicleIds) do
				local vehicle = NetworkUtil.getObject(id)

				if vehicle == nil or not vehicle:getIsSynchronized() then
					allVehiclesSynchronized = false
				end
			end

			if allVehiclesSynchronized then
				spec.rootLocomotive = nil

				for index, id in pairs(spec.railroadVehicleIds) do
					local vehicle = NetworkUtil.getObject(id)

					if vehicle ~= nil then
						vehicle:setTrainSystem(self)

						spec.trainLength = spec.trainLength + vehicle:getFrontToBackDistance()
						spec.trainLengthSplineTime = spec.trainLength / spec.splineLength

						table.insert(spec.railroadVehicles, index, vehicle)

						if spec.rootLocomotive == nil and vehicle.startAutomatedTrainTravel ~= nil then
							spec.rootLocomotive = vehicle
						end
					end

					spec.railroadVehicleIds[index] = nil
				end

				if next(spec.railroadVehicleIds) == nil then
					spec.railroadVehicleIds = nil

					self:setIsTrainTabbable(spec.isRented and g_currentMission:getFarmId() == spec.rentFarmId)
				end
			end
		end

		spec.networkTimeInterpolator:update(dt)

		local interpolationAlpha = spec.networkTimeInterpolator:getAlpha()
		local splineTime = spec.networkSplineTimeInterpolator:getInterpolatedValue(interpolationAlpha)
		splineTime = SplineUtil.getValidSplineTime(splineTime)

		self:updateTrainPositionByLocomotiveSplinePosition(splineTime)
	end

	if spec.hasLimitedRange then
		if spec.sellingStationPlaceable == nil and spec.drivingRangeSellingStationId ~= nil then
			for _, placeable in pairs(g_currentMission.placeableSystem.placeables) do
				if placeable.mapBoundId == spec.drivingRangeSellingStationId and placeable.spec_sellingStation ~= nil then
					spec.sellingStationPlaceable = placeable
					spec.sellingStation = placeable.spec_sellingStation.sellingStation

					self:raiseDirtyFlags(spec.stationDirtyFlag)
				end
			end

			spec.drivingRangeSellingStationId = nil
		end

		if spec.sellingStationPlaceable == nil and spec.sellingStationPlaceableId ~= nil then
			local placeable = NetworkUtil.getObject(spec.sellingStationPlaceableId)

			if placeable ~= nil and placeable.spec_sellingStation ~= nil then
				spec.sellingStationPlaceable = placeable
				spec.sellingStation = placeable.spec_sellingStation.sellingStation
			end
		end

		if spec.showDialogDelay > 0 then
			spec.showDialogDelay = spec.showDialogDelay - dt

			if spec.showDialogDelay <= 0 then
				local stationName = "UNKNOWN"

				if spec.sellingStationPlaceable ~= nil then
					stationName = spec.sellingStationPlaceable:getName()
				end

				local textDriveInfo = string.format(spec.textDriveInfo, stationName)
				local textSellQuestion = string.format(spec.textSellQuestion, stationName)

				if spec.showDialog == 2 then
					g_gui:showYesNoDialog({
						text = textDriveInfo .. "\n\n" .. textSellQuestion,
						callback = self.onSellGoodsQuestion,
						target = self
					})
				else
					g_gui:showInfoDialog({
						text = textDriveInfo
					})
				end

				spec.showDialog = 0
			end
		end
	end

	self:raiseActive()
end

function PlaceableTrainSystem:createVehicles()
	local spec = self.spec_trainSystem

	if spec.vehicleIdsToLoad ~= nil and #spec.vehicleIdsToLoad > 0 then
		for k, id in ipairs(spec.vehicleIdsToLoad) do
			local vehicle = g_currentMission.savegameIdToVehicle[id]

			if vehicle ~= nil then
				vehicle:setTrainSystem(self)

				vehicle.trainVehicleIndex = k

				table.insert(spec.railroadVehicles, vehicle)
			end
		end

		self:finalizeTrain(false)
	else
		for k, filename in ipairs(spec.vehiclesToLoad) do
			filename = Utils.getFilename(filename, spec.baseDirectory)
			spec.numVehiclesToLoad = spec.numVehiclesToLoad + 1

			VehicleLoadingUtil.loadVehicle(filename, {
				z = 0,
				x = 0,
				yOffset = 0
			}, true, 0, Vehicle.PROPERTY_STATE_NONE, AccessHandler.EVERYONE, nil, , spec.railroadVehicleLoaded, self, {
				filename,
				k
			})
		end

		spec.vehiclesToLoad = {}
	end
end

function PlaceableTrainSystem:railroadVehicleLoaded(vehicle, vehicleLoadState, args)
	local filename, vehicleIndex = unpack(args)
	local spec = self.spec_trainSystem

	if vehicle ~= nil and vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_OK then
		vehicle:setTrainSystem(self)

		vehicle.trainVehicleIndex = vehicleIndex

		table.insert(spec.railroadVehicles, vehicle)
	else
		Logging.warning("(%s) Could not create trainsystem vehicle!", filename)
	end

	spec.numVehiclesToLoad = spec.numVehiclesToLoad - 1

	if spec.numVehiclesToLoad == 0 and #spec.vehiclesToLoad == 0 then
		self:finalizeTrain(true)
	end
end

function PlaceableTrainSystem:finalizeTrain(attachVehicles)
	local spec = self.spec_trainSystem

	table.sort(spec.railroadVehicles, function (a, b)
		return a.trainVehicleIndex < b.trainVehicleIndex
	end)

	spec.rootLocomotive = nil

	for _, railroadVehicle in pairs(spec.railroadVehicles) do
		railroadVehicle:addDeleteListener(self)

		if spec.rootLocomotive == nil and railroadVehicle.startAutomatedTrainTravel ~= nil then
			spec.rootLocomotive = railroadVehicle
		end

		if attachVehicles and lastVehicle ~= nil then
			lastVehicle:attachImplement(railroadVehicle, 1, 1, true)
		end

		local lastVehicle = railroadVehicle
	end

	self:updateTrainLength(spec.startSplineTime)
	self:setIsTrainTabbable(spec.isRented and g_currentMission:getFarmId() == spec.rentFarmId)
end

function PlaceableTrainSystem:setIsTrainTabbable(isTabbable)
	local spec = self.spec_trainSystem
	isTabbable = isTabbable and g_gameSettings:getValue("isTrainTabbable")

	if spec.hasLimitedRange then
		isTabbable = isTabbable and spec.lastIsInDriveableRange
	end

	for _, railroadVehicle in ipairs(spec.railroadVehicles) do
		if railroadVehicle.setIsTabbable ~= nil then
			railroadVehicle:setIsTabbable(isTabbable)
		end
	end
end

function PlaceableTrainSystem:getIsTrainInDriveableRange()
	return self.spec_trainSystem.lastIsInDriveableRange
end

function PlaceableTrainSystem:getSplineTime()
	return self.spec_trainSystem.splineTime
end

function PlaceableTrainSystem:setSplineTime(startTime, endTime)
	local spec = self.spec_trainSystem

	if startTime ~= spec.splineTime then
		if spec.hasLimitedRange then
			self:updateDriveableState(startTime)
		end

		local t1 = SplineUtil.getValidSplineTime(startTime)

		for _, railroadVehicle in ipairs(spec.railroadVehicles) do
			t1 = railroadVehicle:alignToSplineTime(spec.spline, spec.splineYOffset, t1)
		end

		for _, listener in ipairs(spec.splinePositionUpdateListener) do
			listener:onSplinePositionTimeUpdate(startTime, endTime)
		end

		spec.splineTime = startTime
		spec.splineEndTime = endTime

		if self.isServer then
			local threshold = 0.02 / spec.splineLength

			if threshold < math.abs(spec.splineTime - spec.splineTimeSent) then
				spec.splineTimeSent = spec.splineTime

				self:raiseDirtyFlags(spec.dirtyFlag)
			end
		end
	end
end

function PlaceableTrainSystem:addSplinePositionUpdateListener(listener)
	if listener ~= nil then
		local spec = self.spec_trainSystem

		table.addElement(spec.splinePositionUpdateListener, listener)
	end
end

function PlaceableTrainSystem:removeSplinePositionUpdateListener(listener)
	if listener ~= nil then
		local spec = self.spec_trainSystem

		table.removeElement(spec.splinePositionUpdateListener, listener)
	end
end

function PlaceableTrainSystem:updateTrainPositionByLocomotiveSpeed(dt, speed)
	local spec = self.spec_trainSystem
	local distance = speed * dt / 1000
	local increment = distance / spec.splineLength
	local splineTime = self:getSplineTime() + increment

	self:setSplineTime(splineTime, splineTime - spec.trainLengthSplineTime)
end

function PlaceableTrainSystem:updateTrainPositionByLocomotiveSplinePosition(splinePosition)
	local spec = self.spec_trainSystem
	local splineTime = splinePosition

	self:setSplineTime(splineTime, splineTime - spec.trainLengthSplineTime)
end

function PlaceableTrainSystem:updateTrainLength(splinePosition)
	local spec = self.spec_trainSystem

	for _, railroadVehicle in ipairs(spec.railroadVehicles) do
		spec.trainLength = spec.trainLength + railroadVehicle:getFrontToBackDistance()
	end

	spec.trainLengthSplineTime = spec.trainLength / spec.splineLength

	self:updateTrainPositionByLocomotiveSplinePosition(splinePosition)
end

function PlaceableTrainSystem:toggleRent(farmId, position)
	local spec = self.spec_trainSystem

	if spec.isRented then
		if spec.rentFarmId == farmId then
			self:returnRailroad()
		end
	else
		self:rentRailroad(farmId, position, false)
	end
end

function PlaceableTrainSystem:rentRailroad(farmId, position, noEventSend)
	local spec = self.spec_trainSystem
	spec.isRented = true
	spec.rentFarmId = farmId
	spec.lastRentFarmId = farmId

	spec.rootLocomotive:setRequestedSplinePosition(position)

	for _, railroadVehicle in pairs(spec.railroadVehicles) do
		railroadVehicle:setOwnerFarmId(spec.rentFarmId, true)
	end

	self:setIsTrainTabbable(g_currentMission:getFarmId() == farmId)
	PlaceableTrainSystemRentEvent.sendEvent(self, true, farmId, position, noEventSend)
end

function PlaceableTrainSystem:returnRailroad(noEventSend)
	local spec = self.spec_trainSystem
	spec.isRented = false

	if self.isServer then
		if spec.currentPrice > 0 then
			g_currentMission:addMoney(-spec.currentPrice, spec.rentFarmId, MoneyType.LEASING_COSTS, true)
			g_currentMission:showMoneyChange(MoneyType.LEASING_COSTS, nil, false, spec.rentFarmId)

			spec.currentPrice = 0
		end

		spec.rootLocomotive:startAutomatedTrainTravel()
	end

	spec.rentFarmId = FarmManager.SPECTATOR_FARM_ID

	for _, railroadVehicle in pairs(spec.railroadVehicles) do
		railroadVehicle:setOwnerFarmId(spec.rentFarmId, true)
	end

	self:setIsTrainTabbable(false)
	PlaceableTrainSystemRentEvent.sendEvent(self, false, nil, , noEventSend)
end

function PlaceableTrainSystem:onDayChanged()
	if self.isServer then
		local spec = self.spec_trainSystem

		if spec.currentPrice > 0 then
			g_currentMission:addMoney(-spec.currentPrice, spec.rentFarmId, MoneyType.LEASING_COSTS, true)
			g_currentMission:showMoneyChange(MoneyType.LEASING_COSTS, nil, false, spec.rentFarmId)

			spec.currentPrice = 0
		end
	end
end

function PlaceableTrainSystem:getIsRented()
	local spec = self.spec_trainSystem

	return spec.isRented
end

function PlaceableTrainSystem:getCanBeRented(farmId)
	local spec = self.spec_trainSystem

	if spec.isRented and spec.rentFarmId ~= farmId then
		return false
	end

	return true
end

function PlaceableTrainSystem:onDeleteObject(object)
	local spec = self.spec_trainSystem

	if table.removeElement(spec.railroadVehicles, object) then
		self:updateTrainLength(spec.splineTime)
	end
end

function PlaceableTrainSystem:getSplineLength()
	local spec = self.spec_trainSystem

	return spec.splineLength
end

function PlaceableTrainSystem:getElectricitySpline()
	local spec = self.spec_trainSystem

	return spec.electricitySpline
end

function PlaceableTrainSystem:getElectricitySplineLength()
	local spec = self.spec_trainSystem

	return spec.electricitySplineLength or 0
end

function PlaceableTrainSystem:getNeedDayChanged(superFunc)
	return true
end

function PlaceableTrainSystem:getLengthSplineTime()
	local spec = self.spec_trainSystem

	return spec.trainLengthSplineTime
end

function PlaceableTrainSystem:getSpline()
	local spec = self.spec_trainSystem

	return spec.spline
end

function PlaceableTrainSystem:updateDriveableState(newSplineTime)
	local spec = self.spec_trainSystem
	local isInDriveableRange = spec.splineDriveRange[1] <= newSplineTime % 1 and newSplineTime % 1 <= spec.splineDriveRange[2]

	if isInDriveableRange ~= spec.lastIsInDriveableRange then
		spec.lastIsInDriveableRange = isInDriveableRange

		if not isInDriveableRange then
			for _, railroadVehicle in ipairs(spec.railroadVehicles) do
				if self.isClient and railroadVehicle.getIsEntered ~= nil and railroadVehicle:getIsEntered() then
					g_currentMission:onLeaveVehicle()

					spec.showDialogDelay = 100
					spec.showDialog = 1

					if self:gsIsTrainFilled() then
						spec.showDialog = 2
					end
				end

				if self.isServer then
					local locomotiveSpec = railroadVehicle.spec_locomotive

					if locomotiveSpec ~= nil and locomotiveSpec.state ~= Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE and locomotiveSpec.state ~= Locomotive.STATE_REQUESTED_POSITION and locomotiveSpec.state ~= Locomotive.STATE_REQUESTED_POSITION_BRAKING then
						railroadVehicle:setLocomotiveState(Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE)

						if not self:gsIsTrainFilled() and spec.isRented then
							self:returnRailroad()
						end

						if spec.splineTime < newSplineTime then
							locomotiveSpec.sellingDirection = 1
						else
							locomotiveSpec.sellingDirection = -1
						end
					end
				end
			end
		elseif self.isServer then
			for _, railroadVehicle in ipairs(spec.railroadVehicles) do
				local locomotiveSpec = railroadVehicle.spec_locomotive

				if locomotiveSpec ~= nil then
					if not railroadVehicle:getIsReadyForAutomatedTrainTravel() then
						if locomotiveSpec.state == Locomotive.STATE_AUTOMATIC_TRAVEL_ACTIVE then
							railroadVehicle:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_INACTIVE)

							locomotiveSpec.sellingDirection = 1
						end
					elseif locomotiveSpec.sellingDirection ~= nil and locomotiveSpec.sellingDirection < 0 then
						locomotiveSpec.sellingDirection = 1

						railroadVehicle:setLocomotiveState(Locomotive.STATE_MANUAL_TRAVEL_INACTIVE)
					end
				end
			end
		end

		self:setIsTrainTabbable(spec.isRented and g_currentMission:getFarmId() == spec.rentFarmId)
	end
end

function PlaceableTrainSystem:gsIsTrainFilled()
	local spec = self.spec_trainSystem

	for _, railroadVehicle2 in ipairs(spec.railroadVehicles) do
		if railroadVehicle2.getFillUnits ~= nil then
			local fillUnits = railroadVehicle2:getFillUnits()

			for fillUnitIndex, fillUnit in ipairs(fillUnits) do
				if fillUnit.fillLevel > 0 then
					return true
				end
			end
		end
	end

	return false
end

function PlaceableTrainSystem:onSellGoodsQuestion(yes)
	if yes then
		g_client:getServerConnection():sendEvent(PlaceableTrainSystemSellEvent.new(self))
	end
end

function PlaceableTrainSystem:sellGoods()
	local spec = self.spec_trainSystem

	if spec.sellingStation ~= nil and spec.rentFarmId ~= 0 then
		local soldDelta = 0

		for _, railroadVehicle in ipairs(spec.railroadVehicles) do
			if railroadVehicle.getFillUnits ~= nil then
				local fillUnits = railroadVehicle:getFillUnits()

				for fillUnitIndex, fillUnit in ipairs(fillUnits) do
					local delta = spec.sellingStation:addFillLevelFromTool(spec.rentFarmId, fillUnit.fillLevel, fillUnit.fillType, nil, ToolType.UNDEFINED)

					railroadVehicle:addFillUnitFillLevel(railroadVehicle:getOwnerFarmId(), fillUnitIndex, -delta, fillUnit.fillType, ToolType.UNDEFINED, nil)

					soldDelta = soldDelta + delta
				end
			end
		end

		if soldDelta > 0 and spec.isRented then
			self:returnRailroad()
		end
	end
end
