VehicleLoadingUtil = {
	VEHICLE_LOAD_OK = 1,
	VEHICLE_LOAD_ERROR = 2,
	VEHICLE_LOAD_DELAYED = 3,
	VEHICLE_LOAD_NO_SPACE = 4
}

function VehicleLoadingUtil.loadVehicle(filename, location, save, price, propertyState, ownerFarmId, configurations, savegameData, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, registerVehicle, forceServer)
	if asyncCallbackFunction == nil then
		print("Error: loadVehicle only supports async loading but asyncCallbackFunction is missing!")

		return nil
	end

	if g_currentMission == nil or g_currentMission.cancelLoading then
		asyncCallbackFunction(asyncCallbackObject, nil, VehicleLoadingUtil.VEHICLE_LOAD_ERROR, asyncCallbackArguments)

		return
	end

	registerVehicle = Utils.getNoNil(registerVehicle, true)

	if registerVehicle and not g_currentMission:getIsServer() then
		print("Error: loadVehicle is only allowed on a server")
		printCallstack()
		asyncCallbackFunction(asyncCallbackObject, nil, VehicleLoadingUtil.VEHICLE_LOAD_ERROR, asyncCallbackArguments)

		return
	end

	if g_storeManager:getItemByXMLFilename(filename) == nil then
		printf("Error: loadVehicle can only load existing store items, no store item for xml filename '%s'", filename)
		printCallstack()
		asyncCallbackFunction(asyncCallbackObject, nil, VehicleLoadingUtil.VEHICLE_LOAD_ERROR, asyncCallbackArguments)

		return
	end

	local xmlFile = XMLFile.load("loadVehicleXml", filename, Vehicle.xmlSchema)

	if xmlFile == nil then
		printf("Error: loadVehicle can not load vehicle xml filename '%s'", filename)
		printCallstack()
		asyncCallbackFunction(asyncCallbackObject, nil, VehicleLoadingUtil.VEHICLE_LOAD_ERROR, asyncCallbackArguments)

		return
	end

	local typeName = xmlFile:getValue("vehicle#type")

	xmlFile:delete()

	configurations = Utils.getNoNil(configurations, {})

	if configurations ~= nil and savegameData ~= nil and savegameData.xmlFile ~= 0 then
		local i = 0

		while true do
			local key = string.format(savegameData.key .. ".configuration(%d)", i)

			if not savegameData.xmlFile:hasProperty(key) then
				break
			end

			local name = savegameData.xmlFile:getValue(key .. "#name")
			local id = savegameData.xmlFile:getValue(key .. "#id")
			configurations[name] = ConfigurationUtil.getConfigIdBySaveId(filename, name, id)
			i = i + 1
		end
	end

	if configurations ~= nil and configurations.vehicleType ~= nil then
		local storeItem = g_storeManager:getItemByXMLFilename(filename)

		if storeItem.configurations ~= nil and storeItem.configurations.vehicleType then
			typeName = storeItem.configurations.vehicleType[configurations.vehicleType].vehicleType
		end
	end

	if typeName == nil then
		print("Error loadVehicle: invalid vehicle config file '" .. filename .. "', no type specified")
		asyncCallbackFunction(asyncCallbackObject, nil, VehicleLoadingUtil.VEHICLE_LOAD_ERROR, asyncCallbackArguments)

		return
	end

	local typeDef = g_vehicleTypeManager:getTypeByName(typeName)
	local modName, _ = Utils.getModNameAndBaseDirectory(filename)

	if modName ~= nil then
		if g_modIsLoaded[modName] == nil or not g_modIsLoaded[modName] then
			print("Error: Mod '" .. modName .. "' of vehicle '" .. filename .. "'")
			print("       is not loaded. This vehicle will not be loaded.")
			asyncCallbackFunction(asyncCallbackObject, nil, VehicleLoadingUtil.VEHICLE_LOAD_ERROR, asyncCallbackArguments)

			return
		end

		if typeDef == nil then
			typeName = modName .. "." .. typeName
			typeDef = g_vehicleTypeManager:getTypeByName(typeName)
		end
	end

	if typeDef == nil then
		print("Error loadVehicle: unknown type '" .. typeName .. "' in '" .. filename .. "'")
		asyncCallbackFunction(asyncCallbackObject, nil, VehicleLoadingUtil.VEHICLE_LOAD_ERROR, asyncCallbackArguments)

		return
	end

	local vehicleClass = ClassUtil.getClassObject(typeDef.className)

	if vehicleClass == nil then
		print("Error loadVehicle: unknown vehicle class '" .. typeDef.className .. "' in '" .. filename .. "'")
		asyncCallbackFunction(asyncCallbackObject, nil, VehicleLoadingUtil.VEHICLE_LOAD_ERROR, asyncCallbackArguments)

		return
	end

	forceServer = Utils.getNoNil(forceServer, false)
	local vehicle = vehicleClass.new(forceServer or g_currentMission:getIsServer(), forceServer or g_currentMission:getIsClient())
	local vehicleData = {
		filename = filename,
		isAbsolute = false,
		typeName = typeName,
		price = price,
		propertyState = propertyState,
		ownerFarmId = ownerFarmId,
		posX = location.x,
		posY = location.y,
		posZ = location.z,
		yOffset = location.yOffset or 0,
		rotX = location.xRot or 0,
		rotY = location.yRot or 0,
		rotZ = location.zRot or 0,
		isVehicleSaved = save,
		configurations = configurations
	}

	if savegameData ~= nil then
		vehicleData.savegame = {
			xmlFile = savegameData.xmlFile,
			key = savegameData.key,
			resetVehicles = savegameData.resetVehicles,
			keepPosition = savegameData.keepPosition
		}
	end

	vehicle:load(vehicleData, VehicleLoadingUtil.loadVehicleFinished, nil, {
		asyncCallbackFunction,
		asyncCallbackObject,
		asyncCallbackArguments,
		registerVehicle
	})
end

function VehicleLoadingUtil.loadVehicleFinished(_, vehicle, vehicleLoadState, arguments)
	local asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, registerVehicle = unpack(arguments)

	if registerVehicle and vehicle ~= nil then
		vehicle:register()
	end

	asyncCallbackFunction(asyncCallbackObject, vehicle, vehicleLoadState, asyncCallbackArguments)
end

function VehicleLoadingUtil.loadVehiclesFromListAdd(list, filename, x, yOffset, z, yRot, save, varName, varObject, ownerFarmId, configurations)
	table.insert(list, {
		filename = filename,
		location = {
			x = x,
			z = z,
			yOffset = yOffset,
			yRot = yRot
		},
		save = save,
		varName = varName,
		varObject = varObject,
		ownerFarmId = Utils.getNoNil(ownerFarmId, AccessHandler.EVERYONE),
		configurations = Utils.getNoNil(configurations, {})
	})
end

function VehicleLoadingUtil.loadVehiclesFromList(list, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	if #list == 0 or g_currentMission.cancelLoading then
		asyncCallbackFunction(asyncCallbackObject, asyncCallbackArguments)

		return
	end

	local firstVehicle = list[1]

	VehicleLoadingUtil.loadVehicle(firstVehicle.filename, firstVehicle.location, firstVehicle.save, 0, Vehicle.PROPERTY_STATE_NONE, firstVehicle.ownerFarmId, firstVehicle.configurations, nil, VehicleLoadingUtil.loadVehiclesFromListFinished, nil, {
		asyncCallbackFunction,
		asyncCallbackObject,
		asyncCallbackArguments,
		list
	})
end

function VehicleLoadingUtil.loadVehiclesFromListFinished(_, vehicle, vehicleLoadState, arguments)
	local asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, list = unpack(arguments)

	if vehicle == nil then
		asyncCallbackFunction(asyncCallbackObject, vehicleLoadState, asyncCallbackArguments)

		return
	end

	local loadedVehicle = list[1]

	if loadedVehicle.varObject ~= nil and loadedVehicle.varName ~= nil then
		loadedVehicle.varObject[loadedVehicle.varName] = vehicle
	end

	table.remove(list, 1)

	if #list == 0 or g_currentMission.cancelLoading then
		asyncCallbackFunction(asyncCallbackObject, asyncCallbackArguments)

		return
	end

	local next = list[1]

	VehicleLoadingUtil.loadVehicle(next.filename, next.location, next.save, 0, Vehicle.PROPERTY_STATE_NONE, next.ownerFarmId, next.configurations, nil, VehicleLoadingUtil.loadVehiclesFromListFinished, nil, arguments)
end

function VehicleLoadingUtil.loadVehiclesAtPlace(storeItem, places, usedPlaces, configurations, price, propertyState, ownerFarmId, saleItem, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local size = StoreItemUtil.getSizeValues(storeItem.xmlFilename, "vehicle", storeItem.rotation, configurations)
	local vehiclesToLoad = {
		asyncCallbackFunction = asyncCallbackFunction,
		asyncCallbackObject = asyncCallbackObject,
		asyncCallbackArguments = asyncCallbackArguments
	}
	local x, _, z, place, width, offset = PlacementUtil.getPlace(places, size, usedPlaces, true, false, true)

	if x == nil then
		VehicleLoadingUtil.loadVehiclesAtPlaceFinished(asyncCallbackArguments.targetOwner, vehiclesToLoad, VehicleLoadingUtil.VEHICLE_LOAD_NO_SPACE)

		return
	end

	local yRot = MathUtil.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)
	yRot = yRot + storeItem.rotation
	local items = {}

	if storeItem.bundleInfo ~= nil then
		for _, bundleItem in pairs(storeItem.bundleInfo.bundleItems) do
			local itemConfigurations = {}

			for name, index in pairs(configurations) do
				if bundleItem.item.configurations[name] ~= nil then
					itemConfigurations[name] = index
				end
			end

			table.insert(items, {
				rotation = 0,
				xmlFilename = bundleItem.xmlFilename,
				x = x,
				z = z,
				yRot = yRot,
				yOffset = offset,
				offset = bundleItem.offset,
				rotationOffset = bundleItem.rotationOffset,
				price = bundleItem.price,
				propertyState = propertyState,
				ownerFarmId = ownerFarmId,
				configurations = itemConfigurations
			})
		end
	else
		table.insert(items, {
			rotation = 0,
			xmlFilename = storeItem.xmlFilename,
			x = x,
			z = z,
			yRot = yRot,
			yOffset = offset,
			offset = {
				0,
				0,
				0
			},
			price = price,
			propertyState = propertyState,
			ownerFarmId = ownerFarmId,
			configurations = configurations
		})
	end

	vehiclesToLoad.storeItem = storeItem
	vehiclesToLoad.loadedVehicles = {}
	vehiclesToLoad.vehicles = items
	vehiclesToLoad.loadedVehicleIndex = 0
	vehiclesToLoad.usedPlaces = usedPlaces
	vehiclesToLoad.place = place
	vehiclesToLoad.width = width
	vehiclesToLoad.licensePlateData = asyncCallbackArguments.licensePlateData
	vehiclesToLoad.saleItem = saleItem

	if not VehicleLoadingUtil.loadVehiclesAtPlaceStep(asyncCallbackArguments.targetOwner, vehiclesToLoad) then
		VehicleLoadingUtil.loadVehiclesAtPlaceFinished(asyncCallbackArguments.targetOwner, vehiclesToLoad, VehicleLoadingUtil.VEHICLE_LOAD_ERROR)
	end
end

function VehicleLoadingUtil.loadVehiclesAtPlaceStep(targetOwner, vehiclesToLoad)
	local vehicles = vehiclesToLoad.vehicles
	local index = vehiclesToLoad.loadedVehicleIndex + 1

	if index <= #vehicles then
		local item = vehicles[index]
		local x = item.x
		local offset = item.yOffset + item.offset[2]
		local z = item.z
		local xRot = 0
		local yRot = item.yRot + item.rotation
		local zRot = 0

		if item.rotationOffset ~= nil then
			xRot = xRot + item.rotationOffset[1]
			yRot = yRot + item.rotationOffset[2]
			zRot = zRot + item.rotationOffset[3]
		end

		local dirX, dirZ = MathUtil.getDirectionFromYRotation(item.yRot)
		local upX, upZ = MathUtil.getDirectionFromYRotation(item.yRot + math.pi / 2)
		x = x + upX * item.offset[1] + dirX * item.offset[3]
		z = z + upZ * item.offset[1] + dirZ * item.offset[3]
		local location = {
			x = x,
			z = z,
			yOffset = offset,
			xRot = xRot,
			yRot = yRot,
			zRot = zRot
		}

		VehicleLoadingUtil.loadVehicle(item.xmlFilename, location, true, item.price, item.propertyState, item.ownerFarmId, item.configurations, nil, VehicleLoadingUtil.loadVehiclesAtPlaceStepFinished, nil, {
			targetOwner,
			vehiclesToLoad
		})

		return true
	end

	return false
end

function VehicleLoadingUtil.loadVehiclesAtPlaceStepFinished(_, vehicle, vehicleLoadState, arguments)
	local targetOwner, vehiclesToLoad = unpack(arguments)

	if vehicle ~= nil then
		vehiclesToLoad.loadedVehicleIndex = vehiclesToLoad.loadedVehicleIndex + 1

		table.insert(vehiclesToLoad.loadedVehicles, vehicle)

		if vehicle.setLicensePlatesData ~= nil and vehicle.getHasLicensePlates ~= nil and vehicle:getHasLicensePlates() then
			vehicle:setLicensePlatesData(vehiclesToLoad.licensePlateData)
		end

		if vehiclesToLoad.saleItem ~= nil then
			g_currentMission.vehicleSaleSystem:setVehicleState(vehicle, vehiclesToLoad.saleItem)
		end

		if not VehicleLoadingUtil.loadVehiclesAtPlaceStep(targetOwner, vehiclesToLoad) then
			VehicleLoadingUtil.loadVehiclesAtPlaceFinished(targetOwner, vehiclesToLoad, VehicleLoadingUtil.VEHICLE_LOAD_OK)
		end
	else
		VehicleLoadingUtil.loadVehiclesAtPlaceFinished(targetOwner, vehiclesToLoad, VehicleLoadingUtil.VEHICLE_LOAD_NO_SPACE)
	end
end

function VehicleLoadingUtil.loadVehiclesAtPlaceFinished(targetOwner, vehiclesToLoad, code)
	if code == VehicleLoadingUtil.VEHICLE_LOAD_OK then
		if vehiclesToLoad.storeItem.bundleInfo ~= nil then
			local loadedVehicles = vehiclesToLoad.loadedVehicles
			local bundleInfo = {}

			for _, attachInfo in pairs(vehiclesToLoad.storeItem.bundleInfo.attacherInfo) do
				local v1 = loadedVehicles[attachInfo.bundleElement0]
				local v2 = loadedVehicles[attachInfo.bundleElement1]

				v1:attachImplement(v2, attachInfo.inputAttacherJointIndex, attachInfo.attacherJointIndex, true, nil, , true)
				table.insert(bundleInfo, {
					v1 = v1,
					v2 = v2,
					input = attachInfo.inputAttacherJointIndex,
					attacher = attachInfo.attacherJointIndex
				})
			end

			if g_server ~= nil then
				g_server:broadcastEvent(VehicleBundleAttachEvent.new(bundleInfo), nil, , g_currentMission)
			end
		end

		PlacementUtil.markPlaceUsed(vehiclesToLoad.usedPlaces, vehiclesToLoad.place, vehiclesToLoad.width)
	end

	if vehiclesToLoad.asyncCallbackFunction ~= nil then
		vehiclesToLoad.asyncCallbackFunction(vehiclesToLoad.asyncCallbackObject, code, vehiclesToLoad.asyncCallbackArguments)
	end
end

function VehicleLoadingUtil.loadVehiclesFromSavegame(xmlFilename, resetVehicles, missionInfo, missionDynamicInfo, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	local xmlFile = XMLFile.load("VehiclesXML", xmlFilename, Vehicle.xmlSchemaSavegame)
	local loadingData = {
		xmlFile = xmlFile,
		xmlFilename = xmlFilename,
		resetVehicles = resetVehicles,
		missionInfo = missionInfo,
		missionDynamicInfo = missionDynamicInfo,
		index = 0,
		vehiclesById = {},
		asyncCallbackFunction = asyncCallbackFunction,
		asyncCallbackObject = asyncCallbackObject,
		asyncCallbackArguments = asyncCallbackArguments
	}

	if not VehicleLoadingUtil.loadVehiclesFromSavegameStep(loadingData) then
		VehicleLoadingUtil.loadVehiclesFromSavegameFinished(loadingData)
	end
end

function VehicleLoadingUtil.loadVehiclesFromSavegameStep(loadingData)
	if g_currentMission.cancelLoading then
		return false
	end

	local xmlFile = loadingData.xmlFile
	local missionInfo = loadingData.missionInfo
	local missionDynamicInfo = loadingData.missionDynamicInfo
	local defaultItemsToSPFarm = xmlFile:getValue("vehicles#loadAnyFarmInSingleplayer", false)

	while true do
		local index = loadingData.index
		loadingData.index = loadingData.index + 1
		local key = string.format("vehicles.vehicle(%d)", index)

		if not xmlFile:hasProperty(key) then
			return false
		end

		local modName = xmlFile:getValue(key .. "#modName")
		local filename = xmlFile:getValue(key .. "#filename")
		local defaultProperty = xmlFile:getValue(key .. "#defaultFarmProperty", false)
		local farmId = xmlFile:getValue(key .. "#farmId")
		local loadForCompetitive = defaultProperty and missionInfo.isCompetitiveMultiplayer and g_farmManager:getFarmById(farmId) ~= nil
		local loadDefaultProperty = defaultProperty and missionInfo.loadDefaultFarm and not missionDynamicInfo.isMultiplayer and (farmId == FarmManager.SINGLEPLAYER_FARM_ID or defaultItemsToSPFarm)
		local allowedToLoad = missionInfo.isValid or not defaultProperty or loadDefaultProperty or loadForCompetitive

		if (modName == nil or g_modIsLoaded[modName]) and filename ~= nil and allowedToLoad then
			if loadDefaultProperty and defaultItemsToSPFarm and farmId ~= FarmManager.SINGLEPLAYER_FARM_ID then
				xmlFile:setValue(key .. "#farmId", FarmManager.SINGLEPLAYER_FARM_ID)
			end

			filename = NetworkUtil.convertFromNetworkFilename(filename)
			local savegame = {
				xmlFile = xmlFile,
				key = key,
				resetVehicles = loadingData.resetVehicles
			}
			loadingData.key = key
			local location = {
				x = 0,
				z = 0
			}

			VehicleLoadingUtil.loadVehicle(filename, location, true, 0, Vehicle.PROPERTY_STATE_NONE, AccessHandler.EVERYONE, nil, savegame, VehicleLoadingUtil.loadVehiclesFromSavegameStepFinished, nil, loadingData)

			return true
		end
	end
end

function VehicleLoadingUtil.loadVehiclesFromSavegameStepFinished(_, vehicle, vehicleLoadState, loadingData)
	if g_currentMission == nil or g_currentMission.cancelLoading then
		VehicleLoadingUtil.loadVehiclesFromSavegameFinished(loadingData)

		return
	end

	if vehicle ~= nil then
		if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_ERROR then
			print("Warning: corrupt savegame, vehicle " .. vehicle.configFileName .. " could not be loaded")
			g_currentMission:removeVehicle(vehicle)
		elseif vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_DELAYED then
			g_currentMission:addVehicleToSpawn(loadingData.xmlFilename, loadingData.key)
			g_currentMission:removeVehicle(vehicle)
		elseif vehicle.currentSavegameId ~= nil then
			loadingData.vehiclesById[vehicle.currentSavegameId] = vehicle
		end
	end

	if not VehicleLoadingUtil.loadVehiclesFromSavegameStep(loadingData) then
		VehicleLoadingUtil.loadVehiclesFromSavegameFinished(loadingData)
	end
end

function VehicleLoadingUtil.loadVehiclesFromSavegameFinished(loadingData)
	g_asyncTaskManager:addTask(function ()
		if g_currentMission ~= nil and not g_currentMission.cancelLoading and not loadingData.resetVehicles then
			local loadedVehicles = {}
			local i = 0

			while true do
				local key = string.format("vehicles.attachments(%d)", i)

				if not loadingData.xmlFile:hasProperty(key) then
					break
				end

				local id = loadingData.xmlFile:getValue(key .. "#rootVehicleId")

				if id ~= nil then
					local vehicle = loadingData.vehiclesById[id]

					if vehicle ~= nil and vehicle.loadAttachmentsFromXMLFile ~= nil then
						vehicle:loadAttachmentsFromXMLFile(loadingData.xmlFile, key, loadingData.vehiclesById)

						loadedVehicles[vehicle] = true
					end
				end

				i = i + 1
			end

			for vehicle, _ in pairs(loadedVehicles) do
				vehicle:loadAttachmentsFinished()
			end
		end

		loadingData.asyncCallbackFunction(loadingData.asyncCallbackObject, loadingData.asyncCallbackArguments, loadingData.vehiclesById)
		loadingData.xmlFile:delete()
	end)
end

function VehicleLoadingUtil.loadVehicleFromSavegameXML(xmlFile, key, resetVehicle, allowDelayed, xmlFilename, keepPosition, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	if xmlFile == nil then
		asyncCallbackFunction(asyncCallbackObject, nil, VehicleLoadingUtil.VEHICLE_LOAD_ERROR, asyncCallbackArguments)

		return VehicleLoadingUtil.VEHICLE_LOAD_ERROR
	end

	local filename = xmlFile:getValue(key .. "#filename")

	if filename == nil then
		asyncCallbackFunction(asyncCallbackObject, nil, VehicleLoadingUtil.VEHICLE_LOAD_ERROR, asyncCallbackArguments)

		return VehicleLoadingUtil.VEHICLE_LOAD_ERROR
	end

	filename = NetworkUtil.convertFromNetworkFilename(filename)

	if keepPosition == nil then
		keepPosition = false
	end

	local vehicle, vehicleLoadState = VehicleLoadingUtil.loadVehicle(filename, {
		yOffset = 0
	}, true, 0, Vehicle.PROPERTY_STATE_NONE, AccessHandler.EVERYONE, nil, {
		xmlFile = xmlFile,
		key = key,
		resetVehicles = resetVehicle,
		keepPosition = keepPosition
	}, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)

	if vehicle == nil then
		return VehicleLoadingUtil.VEHICLE_LOAD_ERROR
	end

	if vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_ERROR then
		g_currentMission:removeVehicle(vehicle)

		return VehicleLoadingUtil.VEHICLE_LOAD_ERROR
	elseif vehicleLoadState == VehicleLoadingUtil.VEHICLE_LOAD_DELAYED then
		g_currentMission:removeVehicle(vehicle)

		if allowDelayed and xmlFilename ~= nil then
			g_currentMission:addVehicleToSpawn(xmlFilename, key)

			return VehicleLoadingUtil.VEHICLE_LOAD_DELAYED
		elseif allowDelayed then
			vehicle = VehicleLoadingUtil.loadVehicleFromSavegameXML(xmlFile, key, true, true, xmlFilename, false, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)

			return VehicleLoadingUtil.VEHICLE_LOAD_DELAYED, vehicle
		end

		return VehicleLoadingUtil.VEHICLE_LOAD_ERROR
	end

	return vehicleLoadState, vehicle
end

function VehicleLoadingUtil.saveVehiclesToSavegameXML(xmlFile, key, vehicles, usedModNames)
	if g_isDevelopmentVersion then
		xmlFile:setString(key .. "#xmlns:xsi", "http://www.w3.org/2001/XMLSchema-instance")
		xmlFile:setString(key .. "#xsi:noNamespaceSchemaLocation", "D:/code/lsim2022/bin/shared/xml/schema/savegame_vehicles.xsd")
	end

	local savedVehiclesToId = {}
	local curId = 1

	for _, vehicle in pairs(vehicles) do
		if vehicle.isVehicleSaved then
			local vehicleKey = string.format("%s.vehicle(%d)", key, curId - 1)
			savedVehiclesToId[vehicle] = vehicle.currentSavegameId
			local modName = vehicle.customEnvironment

			if modName ~= nil then
				if usedModNames ~= nil then
					usedModNames[modName] = modName
				end

				xmlFile:setValue(vehicleKey .. "#modName", modName)
			end

			xmlFile:setValue(vehicleKey .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(vehicle.configFileName)))
			vehicle:saveToXMLFile(xmlFile, vehicleKey, usedModNames)

			curId = curId + 1
		end
	end

	local attachementIndex = 0

	for _, vehicle in pairs(vehicles) do
		if vehicle.isVehicleSaved and vehicle.saveAttachmentsToXMLFile ~= nil and vehicle:saveAttachmentsToXMLFile(xmlFile, string.format("%s.attachments(%d)", key, attachementIndex), savedVehiclesToId) then
			attachementIndex = attachementIndex + 1
		end
	end

	return savedVehiclesToId
end

function VehicleLoadingUtil.setSaveIds(vehicles)
	local curId = 1

	for _, vehicle in ipairs(vehicles) do
		if vehicle.isVehicleSaved then
			vehicle.currentSavegameId = curId
			curId = curId + 1
		end
	end
end

function VehicleLoadingUtil.save(xmlFileName, usedModNames)
	local vehicleXMLFile = XMLFile.create("vehicleXMLFile", xmlFileName, "vehicles", Vehicle.xmlSchemaSavegame)

	if vehicleXMLFile ~= nil then
		VehicleLoadingUtil.saveVehiclesToSavegameXML(vehicleXMLFile, "vehicles", g_currentMission.vehicles, usedModNames)
		vehicleXMLFile:save()
		vehicleXMLFile:delete()
	end
end
