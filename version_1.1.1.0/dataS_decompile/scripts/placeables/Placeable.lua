Placeable = {}

source("dataS/scripts/placeables/PlaceableNameEvent.lua")

local Placeable_mt = Class(Placeable, Object)

InitStaticObjectClass(Placeable, "Placeable", ObjectIds.OBJECT_PLACEABLE)

Placeable.DEBUG_NETWORK = false
Placeable.DEBUG_NETWORK_UPDATE = false
Placeable.LOAD_STEP_CREATED = 0
Placeable.LOAD_STEP_PRE_LOAD = 1
Placeable.LOAD_STEP_AWAIT_I3D = 2
Placeable.LOAD_STEP_LOAD = 3
Placeable.LOAD_STEP_POST_LOAD = 4
Placeable.LOAD_STEP_AWAIT_SUB_I3D = 5
Placeable.LOAD_STEP_FINISHED = 6
Placeable.LOAD_STEP_SYNCHRONIZED = 7
Placeable.LOADING_STATE_OK = 1
Placeable.LOADING_STATE_ERROR = 2
Placeable.DESTRUCTION = {
	PER_NODE = 2,
	SELL = 1
}

g_xmlManager:addCreateSchemaFunction(function ()
	Placeable.xmlSchema = XMLSchema.new("placeable")
	Placeable.xmlSchemaSavegame = XMLSchema.new("savegame_placeables")
end)

function Placeable.registerEvents(placeableType)
	SpecializationUtil.registerEvent(placeableType, "onPreLoad")
	SpecializationUtil.registerEvent(placeableType, "onLoad")
	SpecializationUtil.registerEvent(placeableType, "onPostLoad")
	SpecializationUtil.registerEvent(placeableType, "onLoadFinished")
	SpecializationUtil.registerEvent(placeableType, "onPreDelete")
	SpecializationUtil.registerEvent(placeableType, "onDelete")
	SpecializationUtil.registerEvent(placeableType, "onSave")
	SpecializationUtil.registerEvent(placeableType, "onReadStream")
	SpecializationUtil.registerEvent(placeableType, "onWriteStream")
	SpecializationUtil.registerEvent(placeableType, "onReadUpdateStream")
	SpecializationUtil.registerEvent(placeableType, "onWriteUpdateStream")
	SpecializationUtil.registerEvent(placeableType, "onPreFinalizePlacement")
	SpecializationUtil.registerEvent(placeableType, "onFinalizePlacement")
	SpecializationUtil.registerEvent(placeableType, "onPostFinalizePlacement")
	SpecializationUtil.registerEvent(placeableType, "onUpdate")
	SpecializationUtil.registerEvent(placeableType, "onUpdateTick")
	SpecializationUtil.registerEvent(placeableType, "onDraw")
	SpecializationUtil.registerEvent(placeableType, "onHourChanged")
	SpecializationUtil.registerEvent(placeableType, "onMinuteChanged")
	SpecializationUtil.registerEvent(placeableType, "onDayChanged")
	SpecializationUtil.registerEvent(placeableType, "onPeriodChanged")
	SpecializationUtil.registerEvent(placeableType, "onWeatherChanged")
	SpecializationUtil.registerEvent(placeableType, "onFarmlandStateChanged")
	SpecializationUtil.registerEvent(placeableType, "onBuy")
	SpecializationUtil.registerEvent(placeableType, "onSell")
end

function Placeable.registerFunctions(placeableType)
	SpecializationUtil.registerFunction(placeableType, "setOwnerFarmId", Placeable.setOwnerFarmId)
	SpecializationUtil.registerFunction(placeableType, "setLoadingStep", Placeable.setLoadingStep)
	SpecializationUtil.registerFunction(placeableType, "setLoadingState", Placeable.setLoadingState)
	SpecializationUtil.registerFunction(placeableType, "addToPhysics", Placeable.addToPhysics)
	SpecializationUtil.registerFunction(placeableType, "removeFromPhysics", Placeable.removeFromPhysics)
	SpecializationUtil.registerFunction(placeableType, "raiseLoadingCallback", Placeable.raiseLoadingCallback)
	SpecializationUtil.registerFunction(placeableType, "collectPickObjects", Placeable.collectPickObjects)
	SpecializationUtil.registerFunction(placeableType, "getNeedWeatherChanged", Placeable.getNeedWeatherChanged)
	SpecializationUtil.registerFunction(placeableType, "getNeedHourChanged", Placeable.getNeedHourChanged)
	SpecializationUtil.registerFunction(placeableType, "getNeedMinuteChanged", Placeable.getNeedMinuteChanged)
	SpecializationUtil.registerFunction(placeableType, "getNeedDayChanged", Placeable.getNeedDayChanged)
	SpecializationUtil.registerFunction(placeableType, "initPose", Placeable.initPose)
	SpecializationUtil.registerFunction(placeableType, "getName", Placeable.getName)
	SpecializationUtil.registerFunction(placeableType, "getImageFilename", Placeable.getImageFilename)
	SpecializationUtil.registerFunction(placeableType, "getCanBeRenamedByFarm", Placeable.getCanBeRenamedByFarm)
	SpecializationUtil.registerFunction(placeableType, "setName", Placeable.setName)
	SpecializationUtil.registerFunction(placeableType, "getPrice", Placeable.getPrice)
	SpecializationUtil.registerFunction(placeableType, "canBuy", Placeable.canBuy)
	SpecializationUtil.registerFunction(placeableType, "getCanBePlacedAt", Placeable.getCanBePlacedAt)
	SpecializationUtil.registerFunction(placeableType, "canBeSold", Placeable.canBeSold)
	SpecializationUtil.registerFunction(placeableType, "isMapBound", Placeable.isMapBound)
	SpecializationUtil.registerFunction(placeableType, "getDestructionMethod", Placeable.getDestructionMethod)
	SpecializationUtil.registerFunction(placeableType, "previewNodeDestructionNodes", Placeable.previewNodeDestructionNodes)
	SpecializationUtil.registerFunction(placeableType, "performNodeDestruction", Placeable.performNodeDestruction)
	SpecializationUtil.registerFunction(placeableType, "updateOwnership", Placeable.updateOwnership)
	SpecializationUtil.registerFunction(placeableType, "setOverlayColor", Placeable.setOverlayColor)
	SpecializationUtil.registerFunction(placeableType, "setOverlayColorNodes", Placeable.setOverlayColorNodes)
	SpecializationUtil.registerFunction(placeableType, "getDailyUpkeep", Placeable.getDailyUpkeep)
	SpecializationUtil.registerFunction(placeableType, "getSellPrice", Placeable.getSellPrice)
	SpecializationUtil.registerFunction(placeableType, "setPreviewPosition", Placeable.setPreviewPosition)
	SpecializationUtil.registerFunction(placeableType, "setVisibility", Placeable.setVisibility)
	SpecializationUtil.registerFunction(placeableType, "getIsSynchronized", Placeable.getIsSynchronized)
end

function Placeable.init()
	local schema = Placeable.xmlSchema
	local basePath = "placeable"

	schema:register(XMLValueType.STRING, basePath .. "#type", "Placeable type", nil, true)
	schema:register(XMLValueType.STRING, basePath .. ".annotation", "Annotation", nil, false)
	schema:register(XMLValueType.STRING, basePath .. ".base.filename", "Placeable i3d file", nil, true)
	schema:register(XMLValueType.BOOL, basePath .. ".base.canBeRenamed", "Placeable can be renamed by player", false)
	schema:register(XMLValueType.BOOL, basePath .. ".base.boughtWithFarmland", "Placeable is bough with farmland", false)
	schema:register(XMLValueType.BOOL, basePath .. ".base.buysFarmland", "Placeable buys farmland it is placed on", false)
	StoreManager.registerStoreDataXMLPaths(schema, basePath)
	I3DUtil.registerI3dMappingXMLPaths(schema, basePath)

	local savegameSchema = Placeable.xmlSchemaSavegame
	local basePathSavegame = "placeables.placeable(?)"

	savegameSchema:register(XMLValueType.BOOL, "placeables#loadAnyFarmInSingleplayer", "Load any farm in singleplayer", false)
	savegameSchema:register(XMLValueType.STRING, basePathSavegame .. "#name", "Custom name set by player to be used instead of store item name")
	savegameSchema:register(XMLValueType.STRING, basePathSavegame .. "#mapBoundId", "Map bound identifier (defines that a placeable is placed on a map directly, and with a unique ID)")
	savegameSchema:register(XMLValueType.VECTOR_TRANS, basePathSavegame .. "#position", "Position")
	savegameSchema:register(XMLValueType.VECTOR_ROT, basePathSavegame .. "#rotation", "Rotation")
	savegameSchema:register(XMLValueType.STRING, basePathSavegame .. "#filename", "Path to xml filename")
	savegameSchema:register(XMLValueType.FLOAT, basePathSavegame .. "#age", "Age of placeable in months.", 0)
	savegameSchema:register(XMLValueType.FLOAT, basePathSavegame .. "#price", "Price of placeable")
	savegameSchema:register(XMLValueType.INT, basePathSavegame .. "#farmId", "Owner farmland", 0)
	savegameSchema:register(XMLValueType.INT, basePathSavegame .. "#id", "Save id")
	savegameSchema:register(XMLValueType.BOOL, basePathSavegame .. "#defaultFarmProperty", "Is property of default farm", false)
	savegameSchema:register(XMLValueType.STRING, basePathSavegame .. "#modName", "Name of mod")

	for name, spec in pairs(g_placeableSpecializationManager:getSpecializations()) do
		local classObj = ClassUtil.getClassObject(spec.className)

		if rawget(classObj, "registerXMLPaths") then
			classObj.registerXMLPaths(schema, basePath)
		end

		if rawget(classObj, "registerSavegameXMLPaths") then
			classObj.registerSavegameXMLPaths(savegameSchema, basePathSavegame .. "." .. name)
		end
	end

	g_storeManager:addSpecType("placeableSlots", "shopListAttributeIconSlots", nil, Placeable.getSpecValueSlots, "placeable")
end

function Placeable.postInit()
end

function Placeable.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or Placeable_mt)
	self.finishedLoading = false
	self.rootNode = nil
	self.i3dMappings = {}
	self.components = {}
	self.loadingState = Placeable.LOADING_STATE_OK
	self.loadingStep = Placeable.LOAD_STEP_CREATED
	self.isDeleting = false
	self.isDeleted = false
	self.isLoadedFromSavegame = false
	self.loadingTasks = {}
	self.readyForFinishLoading = false
	self.age = 0
	self.price = 0
	self.farmlandId = 0
	self.pickObjects = {}
	self.mapBoundId = nil
	self.synchronizedConnections = {}

	return self
end

function Placeable:load(placeableData, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	self.asyncData = {
		callback = asyncCallbackFunction,
		object = asyncCallbackObject,
		arguments = asyncCallbackArguments
	}

	if asyncCallbackFunction == nil then
		self:onLoadingError("Missing asyncCallbackFunction. Placeable only supports async loading!")

		return
	end

	local modName, baseDirectory = Utils.getModNameAndBaseDirectory(placeableData.filename)

	self:setLoadingStep(Placeable.LOAD_STEP_PRE_LOAD)

	self.configFileName = placeableData.filename
	self.baseDirectory = baseDirectory
	self.customEnvironment = modName
	self.typeName = placeableData.typeName
	local typeDef = g_placeableTypeManager:getTypeByName(self.typeName)

	if typeDef == nil then
		self:onLoadingError("Unable to find placeable type '%s'", self.typeName)

		return
	end

	self.type = typeDef
	self.specializations = typeDef.specializations
	self.specializationNames = typeDef.specializationNames
	self.specializationsByName = typeDef.specializationsByName
	self.eventListeners = table.copy(typeDef.eventListeners, 2)
	self.xmlFile = XMLFile.load("placeableXml", placeableData.filename, Placeable.xmlSchema)
	self.savegame = placeableData.savegame
	self.position = {
		x = placeableData.posX,
		y = placeableData.posY,
		z = placeableData.posZ
	}
	self.rotation = {
		x = placeableData.rotX,
		y = placeableData.rotY,
		z = placeableData.rotZ
	}

	if placeableData.ownerFarmId ~= nil then
		self:setOwnerFarmId(placeableData.ownerFarmId, true)
	end

	self.storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if self.storeItem ~= nil then
		self.brand = g_brandManager:getBrandByIndex(self.storeItem.brandIndex)

		if self.price == 0 or self.price == nil then
			self.price = StoreItemUtil.getDefaultPrice(self.storeItem)
		end
	else
		self:onLoadingError("Missing storeItem for placable '%s'", self.configFileName)

		return
	end

	for funcName, func in pairs(typeDef.functions) do
		self[funcName] = func
	end

	for i = 1, #self.specializations do
		local specEntryName = "spec_" .. self.specializationNames[i]

		if self[specEntryName] ~= nil then
			self:onLoadingError("The placeable specialization '%s' could not be added because variable '%s' already exists!", self.specializationNames[i], specEntryName)

			return
		end

		local env = setmetatable({}, {
			__index = self
		})
		self[specEntryName] = env
	end

	SpecializationUtil.raiseEvent(self, "onPreLoad", self.savegame)

	if self.loadingState ~= Placeable.LOADING_STATE_OK then
		self:onLoadingError("Placeable pre-loading failed!")

		return
	end

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.filename", "placeable.base.filename")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "placeable.dayNightObjects", "Visiblity Condition-Tab in GIANTS Editor / Exporter")

	self.i3dFilename = self.xmlFile:getValue("placeable.base.filename")

	if self.i3dFilename == nil then
		self:onLoadingError("Placeable filename missing!")

		return
	end

	self.canBeRenamed = self.xmlFile:getValue("placeable.base.canBeRenamed", false)
	self.boughtWithFarmland = self.xmlFile:getValue("placeable.base.boughtWithFarmland", false)
	self.buysFarmland = self.xmlFile:getValue("placeable.base.buysFarmland", false)

	self:setLoadingStep(Placeable.LOAD_STEP_AWAIT_I3D)

	self.i3dFilename = Utils.getFilename(self.i3dFilename, baseDirectory)
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, false, self.loadI3dFinished, self, nil)
end

function Placeable:loadI3dFinished(i3dNode, failedReason, args)
	self:setLoadingState(Placeable.LOADING_STATE_OK)
	self:setLoadingStep(Placeable.LOAD_STEP_LOAD)
	self:removeFromPhysics()

	if i3dNode == 0 then
		self:onLoadingError("Placeable i3d loading failed!!")

		return
	end

	self.rootNode = i3dNode

	link(getRootNode(), i3dNode)
	I3DUtil.loadI3DComponents(i3dNode, self.components)

	if #self.components == 0 then
		self:onLoadingError("Unable to get placeable components")

		return
	end

	I3DUtil.loadI3DMapping(self.xmlFile, "placeable", self.components, self.i3dMappings)
	self:initPose()
	SpecializationUtil.raiseEvent(self, "onLoad", self.savegame)

	if self.loadingState ~= Placeable.LOADING_STATE_OK then
		self:onLoadingError("Placeable loading failed!")

		return
	end

	self:setLoadingStep(Placeable.LOAD_STEP_POST_LOAD)
	SpecializationUtil.raiseEvent(self, "onPostLoad", self.savegame)

	if self.loadingState ~= Placeable.LOADING_STATE_OK then
		self:onLoadingError("Placeable post-loading failed!")

		return
	end

	self:setVisibility(false)

	if #self.loadingTasks == 0 then
		self:onFinishedLoading()
	else
		self.readyForFinishLoading = true

		self:setLoadingStep(Placeable.LOAD_STEP_AWAIT_SUB_I3D)
	end
end

function Placeable:onFinishedLoading()
	self:setVisibility(true)

	if self.isServer and self.savegame ~= nil then
		self.currentSavegameId = self.savegame.xmlFile:getValue(self.savegame.key .. "#id")

		for id, spec in pairs(self.specializations) do
			local name = self.specializationNames[id]

			if spec.loadFromXMLFile ~= nil then
				spec.loadFromXMLFile(self, self.savegame.xmlFile, self.savegame.key .. "." .. name, self.savegame.reset)
			end
		end

		self.mapBoundId = self.savegame.xmlFile:getValue(self.savegame.key .. "#mapBoundId", self.mapBoundId)
		self.name = self.savegame.xmlFile:getValue(self.savegame.key .. "#name")
		self.age = self.savegame.xmlFile:getValue(self.savegame.key .. "#age", 0)
		self.price = self.savegame.xmlFile:getValue(self.savegame.key .. "#price", self.price)

		if not self.savegame.ignoreFarmId then
			self:setOwnerFarmId(self.savegame.xmlFile:getValue(self.savegame.key .. "#farmId", AccessHandler.EVERYONE), true)
		end

		self.isLoadedFromSavegame = true
	end

	self:setLoadingStep(Placeable.LOAD_STEP_FINISHED)
	SpecializationUtil.raiseEvent(self, "onLoadFinished", self.savegame)

	if self.isLoadedFromSavegame then
		self:finalizePlacement()
	end

	if self.isServer then
		self:setLoadingStep(Placeable.LOAD_STEP_SYNCHRONIZED)
	end

	self.finishedLoading = true

	self:raiseLoadingCallback()

	self.savegame = nil
end

function Placeable:onLoadingError(msg, ...)
	if self.xmlFile ~= nil then
		Logging.xmlError(self.xmlFile, msg, ...)
		self.xmlFile:delete()

		self.xmlFile = nil
	else
		Logging.error(msg, ...)
	end

	self:setLoadingState(Placeable.LOADING_STATE_ERROR)
	self:raiseLoadingCallback()
end

function Placeable:createLoadingTask(target)
	local task = {
		target = target
	}

	table.insert(self.loadingTasks, task)

	return task
end

function Placeable:finishLoadingTask(task)
	for k, t in ipairs(self.loadingTasks) do
		if t == task then
			table.remove(self.loadingTasks, k)

			break
		end
	end

	if self.readyForFinishLoading and #self.loadingTasks == 0 then
		self:onFinishedLoading()
	end
end

function Placeable:raiseLoadingCallback()
	local asyncData = self.asyncData
	local obj = self

	if asyncData ~= nil and asyncData.callback ~= nil then
		asyncData.callback(asyncData.object, obj, self.loadingState, asyncData.arguments)
	end

	self.asyncData = nil
end

function Placeable:initPose()
	setTranslation(self.rootNode, self.position.x, self.position.y, self.position.z)
	setRotation(self.rootNode, self.rotation.x, self.rotation.y, self.rotation.z)
end

function Placeable:finalizePlacement()
	SpecializationUtil.raiseEvent(self, "onPreFinalizePlacement")
	self:addToPhysics()
	g_currentMission.placeableSystem:addPlaceable(self)
	g_currentMission:addOwnedItem(self)
	self:collectPickObjects(self.rootNode)

	for _, node in pairs(self.pickObjects) do
		g_currentMission:addNodeObject(node, self)
	end

	local x, _, z = getWorldTranslation(self.rootNode)
	self.farmlandId = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)

	if self.boughtWithFarmland then
		if self.isServer then
			self:updateOwnership(true)
		end

		g_farmlandManager:addStateChangeListener(self)
	end

	SpecializationUtil.raiseEvent(self, "onFinalizePlacement")
	SpecializationUtil.raiseEvent(self, "onPostFinalizePlacement")

	if self:getNeedWeatherChanged() then
		g_messageCenter:subscribe(MessageType.WEATHER_CHANGED, self.weatherChanged, self)
	end

	if self:getNeedHourChanged() then
		g_messageCenter:subscribe(MessageType.HOUR_CHANGED, self.hourChanged, self)
	end

	if self:getNeedMinuteChanged() then
		g_messageCenter:subscribe(MessageType.MINUTE_CHANGED, self.minuteChanged, self)
	end

	if self:getNeedDayChanged() then
		g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.dayChanged, self)
	end

	g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)
end

function Placeable:delete()
	if self.isDeleted then
		Logging.devError("Trying to delete a already deleted vehicle")
		printCallstack()

		return
	end

	g_messageCenter:unsubscribeAll(self)

	self.isDeleting = true

	SpecializationUtil.raiseEvent(self, "onPreDelete")
	g_currentMission:removePlaceableToDelete(self)
	g_currentMission.placeableSystem:removePlaceable(self)
	g_currentMission:removeOwnedItem(self)

	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

		self.sharedLoadRequestId = nil
	end

	for _, node in pairs(self.pickObjects) do
		g_currentMission:removeNodeObject(node)
	end

	SpecializationUtil.raiseEvent(self, "onDelete")

	if self.boughtWithFarmland and self.isServer then
		g_farmlandManager:removeStateChangeListener(self)
	end

	if self.rootNode ~= nil then
		delete(self.rootNode)

		self.rootNode = nil
	end

	if self.xmlFile ~= nil then
		self.xmlFile:delete()

		self.xmlFile = nil
	end

	self.isDeleting = false
	self.isDeleted = true

	Placeable:superClass().delete(self)
end

function Placeable:readStream(streamId, connection, objectId)
	Placeable:superClass().readStream(self, streamId, connection, objectId)
	self:setConnectionSynchronized(connection, false)

	local configFileName = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	local typeName = streamReadString(streamId)

	if configFileName ~= nil then
		local data = {
			filename = configFileName,
			typeName = typeName,
			posX = streamReadFloat32(streamId),
			posY = streamReadFloat32(streamId),
			posZ = streamReadFloat32(streamId),
			rotX = NetworkUtil.readCompressedAngle(streamId),
			rotY = NetworkUtil.readCompressedAngle(streamId),
			rotZ = NetworkUtil.readCompressedAngle(streamId),
			initRandom = false
		}
		local isNew = self.configFileName == nil
		local placeable = self

		local function asyncCallbackFunction(_, p, loadingState, args)
			if loadingState == Placeable.LOADING_STATE_OK then
				g_client:onObjectFinishedAsyncLoading(placeable)
			else
				Logging.error("Failed to load placeable on client")

				if p ~= nil then
					p:delete()
				end

				printCallstack()

				return
			end
		end

		if isNew then
			self:load(data, asyncCallbackFunction)
		end
	end
end

function Placeable:writeStream(streamId, connection)
	Placeable:superClass().writeStream(self, streamId, connection)
	self:setConnectionSynchronized(connection, false)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.configFileName))
	streamWriteString(streamId, self.typeName)

	local x, y, z = getTranslation(self.rootNode)
	local x_rot, y_rot, z_rot = getRotation(self.rootNode)

	streamWriteFloat32(streamId, x)
	streamWriteFloat32(streamId, y)
	streamWriteFloat32(streamId, z)
	NetworkUtil.writeCompressedAngle(streamId, x_rot)
	NetworkUtil.writeCompressedAngle(streamId, y_rot)
	NetworkUtil.writeCompressedAngle(streamId, z_rot)
end

function Placeable:postReadStream(streamId, connection)
	self:finalizePlacement()

	if Placeable.DEBUG_NETWORK then
		print("-------------------------------------------------------------")
		print(self.configFileName)

		for _, spec in ipairs(self.eventListeners.onReadStream) do
			local className = ClassUtil.getClassName(spec)
			local startBits = streamGetReadOffset(streamId)

			spec.onReadStream(self, streamId, connection)
			print("  " .. tostring(className) .. " read " .. streamGetReadOffset(streamId) - startBits .. " bits")
		end
	else
		SpecializationUtil.raiseEvent(self, "onReadStream", streamId, connection)
	end

	if streamReadBool(streamId) then
		self:setName(streamReadString(streamId), true)
	end

	self:setConnectionSynchronized(connection, true)
	self:setLoadingStep(Placeable.LOAD_STEP_SYNCHRONIZED)
	self:raiseActive()
end

function Placeable:postWriteStream(streamId, connection)
	if Placeable.DEBUG_NETWORK then
		print("-------------------------------------------------------------")
		print(self.configFileName)

		for _, spec in ipairs(self.eventListeners.onWriteStream) do
			local className = ClassUtil.getClassName(spec)
			local startBits = streamGetWriteOffset(streamId)

			spec.onWriteStream(self, streamId, connection)
			print("  " .. tostring(className) .. " Wrote " .. streamGetWriteOffset(streamId) - startBits .. " bits")
		end
	else
		SpecializationUtil.raiseEvent(self, "onWriteStream", streamId, connection)
	end

	if streamWriteBool(streamId, self.name ~= nil) then
		streamWriteString(streamId, self.name)
	end

	self:setConnectionSynchronized(connection, true)
end

function Placeable:readUpdateStream(streamId, timestamp, connection)
	if Placeable.DEBUG_NETWORK_UPDATE then
		print("-------------------------------------------------------------")
		print(self.configFileName)

		for _, spec in ipairs(self.eventListeners.onReadUpdateStream) do
			local className = ClassUtil.getClassName(spec)
			local startBits = streamGetReadOffset(streamId)

			spec.onReadUpdateStream(self, streamId, timestamp, connection)
			print("  " .. tostring(className) .. " read " .. streamGetReadOffset(streamId) - startBits .. " bits")
		end
	else
		SpecializationUtil.raiseEvent(self, "onReadUpdateStream", streamId, timestamp, connection)
	end
end

function Placeable:writeUpdateStream(streamId, connection, dirtyMask)
	if Placeable.DEBUG_NETWORK_UPDATE then
		print("-------------------------------------------------------------")
		print(self.configFileName)

		for _, spec in ipairs(self.eventListeners.onWriteUpdateStream) do
			local className = ClassUtil.getClassName(spec)
			local startBits = streamGetWriteOffset(streamId)

			spec.onWriteUpdateStream(self, streamId, connection, dirtyMask)
			print("  " .. tostring(className) .. " Wrote " .. streamGetWriteOffset(streamId) - startBits .. " bits")
		end
	else
		SpecializationUtil.raiseEvent(self, "onWriteUpdateStream", streamId, connection, dirtyMask)
	end
end

function Placeable:saveToXMLFile(xmlFile, key, usedModNames)
	local x, y, z = getTranslation(self.rootNode)
	local xRot, yRot, zRot = getRotation(self.rootNode)

	xmlFile:setValue(key .. "#id", self.currentSavegameId)
	xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.configFileName)))
	xmlFile:setValue(key .. "#position", x, y, z)
	xmlFile:setValue(key .. "#rotation", xRot, yRot, zRot)
	xmlFile:setValue(key .. "#age", self.age)
	xmlFile:setValue(key .. "#price", self.price)
	xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId() or 1)

	if self.canBeRenamed and self.name ~= nil and self.name:trim() ~= "" then
		xmlFile:setValue(key .. "#name", self.name)
	end

	if self.mapBoundId ~= nil then
		xmlFile:setValue(key .. "#mapBoundId", self.mapBoundId)
	end

	for id, spec in pairs(self.specializations) do
		local name = self.specializationNames[id]

		if spec.saveToXMLFile ~= nil then
			spec.saveToXMLFile(self, xmlFile, key .. "." .. name, usedModNames)
		end
	end
end

function Placeable:setVisibility(state)
	for _, component in pairs(self.components) do
		setVisibility(component.node, state)
	end
end

function Placeable:getIsSynchronized()
	return self.loadingStep == Placeable.LOAD_STEP_SYNCHRONIZED
end

function Placeable:getNeedsSaving()
	return true
end

function Placeable:update(dt)
	SpecializationUtil.raiseEvent(self, "onUpdate", dt)
end

function Placeable:updateTick(dt)
	SpecializationUtil.raiseEvent(self, "onUpdateTick", dt)
end

function Placeable:draw()
	SpecializationUtil.raiseEvent(self, "onDraw")
end

function Placeable:getName()
	return self.name or self.storeItem.name
end

function Placeable:getImageFilename()
	return self.storeItem.imageFilename
end

function Placeable:getCanBeRenamedByFarm(farmId)
	return self.canBeRenamed and self:getOwnerFarmId() == farmId
end

function Placeable:setName(name, noEventSend)
	if self.canBeRenamed then
		if name and name:trim() == "" then
			return false
		end

		PlaceableNameEvent.sendEvent(self, name, noEventSend)

		self.name = name

		g_messageCenter:publish(MessageType.UNLOADING_STATIONS_CHANGED)

		return true
	end

	return false
end

function Placeable:onBuy()
	SpecializationUtil.raiseEvent(self, "onBuy")
end

function Placeable:onSell()
	g_messageCenter:publish(MessageType.FARM_PROPERTY_CHANGED, {
		self:getOwnerFarmId()
	})
	SpecializationUtil.raiseEvent(self, "onSell")
end

function Placeable:getPrice()
	return self.price
end

function Placeable:canBuy()
	local storeItem = self.storeItem
	local maxItemCount = storeItem.maxItemCount

	if maxItemCount == nil then
		return true
	end

	if g_currentMission:getNumOfItems(storeItem, g_currentMission:getFarmId()) < storeItem.maxItemCount then
		return true
	end

	return false
end

function Placeable:getCanBePlacedAt(x, y, z, farmId)
	return true, nil
end

function Placeable:canBeSold()
	return true, nil
end

function Placeable:isMapBound()
	return self.mapBoundId ~= nil
end

function Placeable:getDestructionMethod()
	return Placeable.DESTRUCTION.SELL
end

function Placeable:previewNodeDestructionNodes(node)
	return nil
end

function Placeable:performNodeDestruction(node)
	return false
end

function Placeable:onFarmlandStateChanged(farmlandId, farmId)
	if self.boughtWithFarmland and farmlandId == self.farmlandId then
		self:updateOwnership(true)
	end
end

function Placeable:setOwnerFarmId(farmId, noEventSend)
	if self.buysFarmland then
		g_farmlandManager:setLandOwnership(self.farmlandId, farmId)
	end

	Placeable:superClass().setOwnerFarmId(self, farmId, noEventSend)
end

function Placeable:updateOwnership(updateOwner)
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if storeItem == nil then
		Logging.error("Missing storeItem for placable '%s'", self.configFileName)

		return
	end

	local farmId = g_farmlandManager:getFarmlandOwner(self.farmlandId)

	if not storeItem.canBeSold and farmId == AccessHandler.EVERYONE then
		farmId = AccessHandler.NOBODY
	end

	if self.isServer and updateOwner then
		self:setOwnerFarmId(farmId)
	end

	g_currentMission:removeOwnedItem(self)
	g_currentMission:addOwnedItem(self)
end

function Placeable:setLoadingState(loadingState)
	if loadingState == Placeable.LOADING_STATE_OK or loadingState == Placeable.LOADING_STATE_ERROR then
		self.loadingState = loadingState
	else
		printCallstack()
		Logging.error("Invalid loading state '%s'!", loadingState)
	end
end

function Placeable:collectPickObjects(node)
	if getRigidBodyType(node) ~= RigidBodyType.NONE then
		table.insert(self.pickObjects, node)
	end

	local numChildren = getNumOfChildren(node)

	for i = 1, numChildren do
		self:collectPickObjects(getChildAt(node, i - 1))
	end
end

function Placeable:setLoadingStep(loadingStep)
	if loadingStep == Placeable.LOAD_STEP_CREATED or loadingStep == Placeable.LOAD_STEP_PRE_LOAD or loadingStep == Placeable.LOAD_STEP_AWAIT_I3D or loadingStep == Placeable.LOAD_STEP_LOAD or loadingStep == Placeable.LOAD_STEP_POST_LOAD or loadingStep == Placeable.LOAD_STEP_AWAIT_SUB_I3D or loadingStep == Placeable.LOAD_STEP_FINISHED or loadingStep == Placeable.LOAD_STEP_SYNCHRONIZED then
		self.loadingStep = loadingStep
	else
		printCallstack()
		Logging.error("Invalid loading step '%s'!", loadingStep)
	end
end

function Placeable:setOverlayColor(r, g, b, alpha)
	if self.overlayColorNodes == nil then
		self.overlayColorNodes = {}

		self:setOverlayColorNodes(self.rootNode, self.overlayColorNodes)
	end

	for i = 1, #self.overlayColorNodes do
		setShaderParameter(self.overlayColorNodes[i], "placeableColorScale", r, g, b, alpha, false)
	end
end

function Placeable:setOverlayColorNodes(node, nodeTable)
	if getHasClassId(node, ClassIds.SHAPE) and getHasShaderParameter(node, "placeableColorScale") then
		nodeTable[#nodeTable + 1] = node
	end

	local numChildren = getNumOfChildren(node)

	for i = 0, numChildren - 1 do
		self:setOverlayColorNodes(getChildAt(node, i), nodeTable)
	end
end

function Placeable:getDailyUpkeep()
	local storeItem = self.storeItem
	local multiplier = 1

	if storeItem.lifetime ~= nil and storeItem.lifetime ~= 0 then
		local ageMultiplier = math.min(self.age / storeItem.lifetime, 1)
		multiplier = 1 + EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * ageMultiplier
	end

	return StoreItemUtil.getDailyUpkeep(storeItem, nil) * multiplier
end

function Placeable:getSellPrice()
	local priceMultiplier = 0.5
	local maxAge = self.storeItem.lifetime

	if maxAge ~= nil and maxAge ~= 0 then
		priceMultiplier = priceMultiplier * math.exp(-3.5 * math.min(self.age / maxAge, 1))
	end

	return math.floor(self.price * math.max(priceMultiplier, 0.05))
end

function Placeable:addToPhysics()
	if self.rootNode ~= nil then
		addToPhysics(self.rootNode)
	end
end

function Placeable:removeFromPhysics()
	if self.rootNode ~= nil then
		removeFromPhysics(self.rootNode)
	end
end

function Placeable:setPreviewPosition(x, y, z, rotX, rotY, rotZ)
	setWorldTranslation(self.rootNode, x, y, z)
	setRotation(self.rootNode, 0, rotY, 0)
end

function Placeable:getNeedWeatherChanged()
	return false
end

function Placeable:weatherChanged()
	SpecializationUtil.raiseEvent(self, "onWeatherChanged")
end

function Placeable:getNeedHourChanged()
	return false
end

function Placeable:hourChanged(hour)
	SpecializationUtil.raiseEvent(self, "onHourChanged", hour)
end

function Placeable:getNeedMinuteChanged()
	return false
end

function Placeable:minuteChanged(minute)
	SpecializationUtil.raiseEvent(self, "onMinuteChanged", minute)
end

function Placeable:getNeedDayChanged()
	return false
end

function Placeable:dayChanged(day)
	SpecializationUtil.raiseEvent(self, "onDayChanged", day)
end

function Placeable:periodChanged(period)
	self.age = self.age + 1

	SpecializationUtil.raiseEvent(self, "onPeriodChanged", period)
end

function Placeable.getSpecValueSlots(storeItem, realItem)
	local numOwned = g_currentMission:getNumOfItems(storeItem)
	local slotUsage = g_currentMission.slotSystem:getStoreItemSlotUsage(storeItem, numOwned == 0) * -1

	return string.format("%0d (%0d / %0d)", slotUsage, g_currentMission.slotSystem.slotUsage, g_currentMission.slotSystem.slotLimit)
end
