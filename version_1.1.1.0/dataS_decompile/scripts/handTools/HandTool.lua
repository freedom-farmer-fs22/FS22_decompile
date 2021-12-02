HandTool = {}
local HandTool_mt = Class(HandTool, Object)

InitStaticObjectClass(HandTool, "HandTool", ObjectIds.OBJECT_HANDTOOL)

HandTool.xmlSchema = nil
HandTool.handToolTypes = {}

function registerHandTool(typeName, classObject)
	if not ClassUtil.getIsValidClassName(typeName) then
		print("Error: invalid handtool typeName: " .. typeName)

		return
	end

	HandTool.handToolTypes[typeName] = classObject
end

g_xmlManager:addCreateSchemaFunction(function ()
	HandTool.xmlSchema = XMLSchema.new("handTool")
end)
g_xmlManager:addInitSchemaFunction(function ()
	local schema = HandTool.xmlSchema

	StoreManager.registerStoreDataXMLPaths(schema, "handTool")
	schema:register(XMLValueType.STRING, "handTool.handToolType", "Hand tool type", nil, true)
	schema:register(XMLValueType.STRING, "handTool.filename", "HandTool i3d file", nil, true)
	schema:register(XMLValueType.VECTOR_TRANS, "handTool.handNode.firstPerson#position", "Position", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, "handTool.handNode.firstPerson#rotation", "Rotation", "0 0 0")
	schema:register(XMLValueType.NODE_INDEX, "handTool.handNode.firstPerson#node", "First person node", "root node")
	schema:register(XMLValueType.NODE_INDEX, "handTool.handNode.firstPerson#referenceNode", "Reference node")
	schema:register(XMLValueType.VECTOR_TRANS, "handTool.handNode.thirdPerson#position", "Position", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, "handTool.handNode.thirdPerson#rotation", "Rotation", "0 0 0")
	schema:register(XMLValueType.NODE_INDEX, "handTool.handNode.thirdPerson#node", "First person node", "root node")
	schema:register(XMLValueType.NODE_INDEX, "handTool.handNode.thirdPerson#referenceNode", "Reference node")
	schema:register(XMLValueType.STRING, "handTool.playerWorkStylePreset", "Custom Player workstyle preset name")
	I3DUtil.registerI3dMappingXMLPaths(schema, "handTool")
	IKUtil.registerIKChainTargetsXMLPaths(schema, "handTool.targets")
end)

function HandTool.init()
	for _, classObject in pairs(HandTool.handToolTypes) do
		if rawget(classObject, "init") then
			classObject.init()
		end
	end
end

function HandTool.new(isServer, isClient, customMt)
	local mt = customMt

	if mt == nil then
		mt = HandTool_mt
	end

	local self = Object.new(isServer, isClient, mt)
	self.static = true
	self.player = nil
	self.owner = nil
	self.currentPlayerHandNode = nil
	self.price = 0
	self.age = 0
	self.activatePressed = false
	self.isDeleted = false
	self.components = {}
	self.i3dMappings = {}

	return self
end

function HandTool:load(xmlFilename, player, asyncCallbackFunction, asyncCallbackArguments)
	self.configFileName = xmlFilename
	self.customEnvironment, self.baseDirectory = Utils.getModNameAndBaseDirectory(xmlFilename)
	local xmlFile = XMLFile.load("TempXML", xmlFilename, HandTool.xmlSchema)

	if xmlFile == nil then
		return false
	end

	local i3dFilename = xmlFile:getValue("handTool.filename")

	if i3dFilename == nil then
		xmlFile:delete()

		return false
	end

	self.i3dFilename = Utils.getFilename(i3dFilename, self.baseDirectory)
	self.player = player

	g_i3DManager:pinSharedI3DFileInCache(self.i3dFilename)

	if asyncCallbackFunction ~= nil then
		self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, false, false, self.handToolI3DLoaded, self, {
			xmlFile,
			asyncCallbackFunction,
			asyncCallbackArguments
		})
	else
		local i3dNode, sharedLoadRequestId, failedReason = g_i3DManager:loadSharedI3DFile(self.i3dFilename, false, false)
		self.sharedLoadRequestId = sharedLoadRequestId

		self:handToolI3DLoaded(i3dNode, failedReason, {
			xmlFile,
			asyncCallbackFunction,
			asyncCallbackArguments
		})
	end

	return true
end

function HandTool:handToolI3DLoaded(i3dNode, failedReason, args)
	local xmlFile, asyncCallbackFunction, asyncCallbackArguments = unpack(args)

	if i3dNode ~= 0 then
		if not self.isDeleted then
			self.rootNode = getChildAt(i3dNode, 0)
			local numChildren = getNumOfChildren(i3dNode)

			for i = 0, numChildren - 1 do
				local component = {
					node = getChildAt(i3dNode, i)
				}

				table.insert(self.components, component)
			end

			unlink(self.rootNode)
			I3DUtil.loadI3DMapping(xmlFile, "handTool", self.components, self.i3dMappings)
			self:postLoad(xmlFile)
		end

		xmlFile:delete()
		delete(i3dNode)

		if asyncCallbackFunction ~= nil then
			asyncCallbackFunction(self.player, self, asyncCallbackArguments)
		end
	end
end

function HandTool:postLoad(xmlFile)
	self.handNodePosition = {}
	self.handNodeRotation = {}
	self.handNode = nil
	self.originalHandNodeParent = nil
	self.referenceNode = nil

	if self.player == g_currentMission.player then
		self.handNodePosition = xmlFile:getValue("handTool.handNode.firstPerson#position", "0 0 0", true)
		self.handNodeRotation = xmlFile:getValue("handTool.handNode.firstPerson#rotation", "0 0 0", true)
		self.handNode = xmlFile:getValue("handTool.handNode.firstPerson#node", self.rootNode, self.components, self.i3dMappings)
		self.referenceNode = xmlFile:getValue("handTool.handNode.firstPerson#referenceNode", nil, self.components, self.i3dMappings)
	else
		self.handNodePosition = xmlFile:getValue("handTool.handNode.thirdPerson#position", "0 0 0", true)
		self.handNodeRotation = xmlFile:getValue("handTool.handNode.thirdPerson#rotation", "0 0 0", true)
		self.handNode = xmlFile:getValue("handTool.handNode.thirdPerson#node", self.rootNode, self.components, self.i3dMappings)
		self.referenceNode = xmlFile:getValue("handTool.handNode.thirdPerson#referenceNode", nil, self.components, self.i3dMappings)
	end

	if self.rootNode ~= self.handNode then
		self.originalHandNodeParent = getParent(self.handNode)
	end

	self.customWorkStylePresetName = xmlFile:getValue("handTool.playerWorkStylePreset", nil)

	setTranslation(self.handNode, unpack(self.handNodePosition))
	setRotation(self.handNode, unpack(self.handNodeRotation))

	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if self.price == 0 or self.price == nil then
		self.price = StoreItemUtil.getDefaultPrice(storeItem)
	end

	if g_currentMission ~= nil and storeItem.canBeSold then
		g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)
	end

	self.targets = {}

	IKUtil.loadIKChainTargets(xmlFile, "handTool.targets", self.components, self.targets, self.i3dMappings)
	setVisibility(self.rootNode, false)

	self.isActive = false

	return true
end

function HandTool:setHandNode(playerHandNode)
	if self.currentPlayerHandNode ~= playerHandNode then
		self.currentPlayerHandNode = playerHandNode

		link(playerHandNode, self.handNode)

		if self.referenceNode ~= nil then
			local x, y, z = getWorldTranslation(self.referenceNode)
			x, y, z = worldToLocal(getParent(self.handNode), x, y, z)
			local a, b, c = getTranslation(self.handNode)

			setTranslation(self.handNode, a - x, b - y, c - z)
		end
	end
end

function HandTool:delete()
	self:removeActionEvents()

	if g_currentMission ~= nil then
		g_messageCenter:unsubscribe(MessageType.PERIOD_CHANGED, self)
	end

	if self.rootNode ~= nil and self.rootNode ~= 0 then
		if self.originalHandNodeParent ~= nil and getParent(self.handNode) ~= self.originalHandNodeParent then
			link(self.originalHandNodeParent, self.handNode)
		end

		delete(self.rootNode)
	end

	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

		self.sharedLoadRequestId = nil
	end

	HandTool:superClass().delete(self)

	self.isDeleted = true
end

function HandTool:update(dt, allowInput)
	if self.isActive then
		self:raiseActive()
	end
end

function HandTool:getNeedCustomWorkStyle()
	return true
end

function HandTool:onActivate(allowInput)
	setVisibility(self.rootNode, true)

	self.isActive = true

	self:raiseActive()

	if self.player.isOwner then
		self:registerActionEvents()
	end

	if self:getNeedCustomWorkStyle() then
		self.player:setCustomWorkStylePreset(self.customWorkStylePresetName)
	end
end

function HandTool:onDeactivate(allowInput)
	setVisibility(self.rootNode, false)

	self.isActive = false

	self:removeActionEvents()
	self.player:setCustomWorkStylePreset(nil)
end

function HandTool:loadFromXMLFile(xmlFile, key, resetVehicles)
	return true
end

function HandTool:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(self.configFileName)))
end

function HandTool:getDailyUpkeep()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
	local multiplier = 1

	if storeItem.lifetime ~= nil and storeItem.lifetime ~= 0 then
		local ageMultiplier = math.min(self.age / storeItem.lifetime, 1)
		multiplier = EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * ageMultiplier
	end

	return StoreItemUtil.getDailyUpkeep(storeItem, nil) * multiplier
end

function HandTool:getSellPrice()
	local priceMultiplier = 0.5
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
	local maxVehicleAge = storeItem.lifetime

	if maxVehicleAge ~= nil and maxVehicleAge ~= 0 then
		priceMultiplier = priceMultiplier * math.exp(-3.5 * math.min(self.age / maxVehicleAge, 1))
	end

	return math.floor(self.price * math.max(priceMultiplier, 0.05))
end

function HandTool:periodChanged()
	self.age = self.age + 1
end

function HandTool:isBeingUsed()
	return false
end

function HandTool:registerActionEvents()
	g_inputBinding:beginActionEventsModification(Player.INPUT_CONTEXT_NAME)
	g_inputBinding:endActionEventsModification()
end

function HandTool:removeActionEvents()
	g_inputBinding:beginActionEventsModification(Player.INPUT_CONTEXT_NAME)
	g_inputBinding:removeActionEventsByTarget(self)
	g_inputBinding:endActionEventsModification()
end
