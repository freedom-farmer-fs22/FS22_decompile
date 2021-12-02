PlaceableUtil = {}

function PlaceableUtil.loadPlaceable(filename, position, rotation, ownerFarmId, savegameData, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	if asyncCallbackFunction == nil then
		Logging.error("PlaceableUtil.loadPlaceable can only be used async")
		printCallstack()

		return
	end

	if g_currentMission.cancelLoading then
		asyncCallbackFunction(asyncCallbackObject, nil, Placeable.LOADING_STATE_OK, asyncCallbackArguments)

		return
	end

	if g_storeManager:getItemByXMLFilename(filename) == nil then
		Logging.warning("PlaceableUtil.loadPlaceable can only load existing store items, no store item for xml filename '%s'", filename)
		asyncCallbackFunction(asyncCallbackObject, nil, Placeable.LOADING_STATE_ERROR, asyncCallbackArguments)

		return
	end

	local xmlFile = XMLFile.load("placeableXml", filename, Placeable.xmlSchema)

	if xmlFile == nil then
		Logging.error("Unable to load placeable xml file '%s'", filename)
		asyncCallbackFunction(asyncCallbackObject, nil, Placeable.LOADING_STATE_ERROR, asyncCallbackArguments)

		return
	end

	local typeName = xmlFile:getValue("placeable#type")

	xmlFile:delete()

	if typeName == nil then
		Logging.error("No type defined for placeable '%s'", filename)
		asyncCallbackFunction(asyncCallbackObject, nil, Placeable.LOADING_STATE_ERROR, asyncCallbackArguments)

		return
	end

	local typeDef = g_placeableTypeManager:getTypeByName(typeName)
	local modName, _ = Utils.getModNameAndBaseDirectory(filename)

	if modName ~= nil then
		if g_modIsLoaded[modName] == nil or not g_modIsLoaded[modName] then
			Logging.error("Mod '%s' of placeable '%s' is not loaded. This placeable will not be loaded", modName, filename)
			asyncCallbackFunction(asyncCallbackObject, nil, Placeable.LOADING_STATE_ERROR, asyncCallbackArguments)

			return
		end

		if typeDef == nil then
			typeName = modName .. "." .. typeName
			typeDef = g_placeableTypeManager:getTypeByName(typeName)
		end
	end

	if typeDef == nil then
		Logging.error("Unknown placeable type '%s' in '%s'", typeName, filename)
		asyncCallbackFunction(asyncCallbackObject, nil, Placeable.LOADING_STATE_ERROR, asyncCallbackArguments)

		return
	end

	local class = ClassUtil.getClassObject(typeDef.className)

	if class == nil then
		Logging.error("Unknown placeable class '%s' for placeable type '%s' in '%s'", typeDef.className, typeName, filename)
		asyncCallbackFunction(asyncCallbackObject, nil, Placeable.LOADING_STATE_ERROR, asyncCallbackArguments)

		return
	end

	local placeable = class.new(g_currentMission:getIsServer(), g_currentMission:getIsClient())
	local data = {
		filename = filename,
		typeName = typeName,
		posX = position.x or 0,
		posY = position.y or 0,
		posZ = position.z or 0,
		rotX = rotation.x or 0,
		rotY = rotation.y or 0,
		rotZ = rotation.z or 0,
		ownerFarmId = ownerFarmId
	}

	if savegameData ~= nil then
		data.savegame = {
			xmlFile = savegameData.xmlFile,
			key = savegameData.key
		}
	end

	placeable:load(data, PlaceableUtil.loadPlaceableFinished, nil, {
		asyncCallbackFunction,
		asyncCallbackObject,
		asyncCallbackArguments
	})

	return placeable
end

function PlaceableUtil.loadPlaceableFinished(_, placeable, loadingState, arguments)
	local asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments = unpack(arguments)

	asyncCallbackFunction(asyncCallbackObject, placeable, loadingState, asyncCallbackArguments)
end
