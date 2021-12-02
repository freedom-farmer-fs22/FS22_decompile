FeedingRobot = {}
local FeedingRobot_mt = Class(FeedingRobot, Object)

InitStaticObjectClass(FeedingRobot, "FeedingRobot", ObjectIds.OBJECT_ANIMAL_HUSBANDRY_FEEDING_ROBOT)
g_xmlManager:addCreateSchemaFunction(function ()
	FeedingRobot.xmlSchema = XMLSchema.new("feedingRobot")
end)
g_xmlManager:addInitSchemaFunction(function ()
	local schema = FeedingRobot.xmlSchema

	schema:register(XMLValueType.STRING, "feedingRobot.filename", "Feeding robot i3d file", nil, true)
	schema:register(XMLValueType.NODE_INDEX, "feedingRobot.robot#node", "Robot node")
	schema:register(XMLValueType.NODE_INDEX, "feedingRobot.robot.door#node", "Robot door node")
	schema:register(XMLValueType.FLOAT, "feedingRobot.robot.door#maxY", "Robot door maxY")
	schema:register(XMLValueType.FLOAT, "feedingRobot.robot.door#duration", "Robot door duration")
	schema:register(XMLValueType.FLOAT, "feedingRobot.robot#maxSpeed", "Max Speed", 0)
	schema:register(XMLValueType.FLOAT, "feedingRobot.robot#acceleration", "Max acceleration", 1)
	schema:register(XMLValueType.FLOAT, "feedingRobot.robot#deceleration", "Max deceleration", -1)
	schema:register(XMLValueType.NODE_INDEX, "feedingRobot.robot#triggerNode", "Vehicle and player trigger node")
	schema:register(XMLValueType.STRING, "feedingRobot.stateMachine.states.state(?)#name", "State name")
	schema:register(XMLValueType.STRING, "feedingRobot.stateMachine.states.state(?)#class", "State class")
	FeedingRobotState.registerXMLPaths(schema, "feedingRobot.stateMachine.states.state(?)")
	FeedingRobotStateFilling.registerXMLPaths(schema, "feedingRobot.stateMachine.states.state(?)")
	I3DUtil.registerI3dMappingXMLPaths(schema, "feedingRobot")
	schema:register(XMLValueType.NODE_INDEX, "feedingRobot.playerTrigger#node", "Vehicle and player trigger node")
	schema:register(XMLValueType.STRING, "feedingRobot.stateMachine.transitions.transition(?)#from", "State name from")
	schema:register(XMLValueType.STRING, "feedingRobot.stateMachine.transitions.transition(?)#to", "State name to")
	AnimatedObject.registerXMLPaths(schema, "feedingRobot.animatedObjects")
	AnimationManager.registerAnimationNodesXMLPaths(schema, "feedingRobot.robot.mixer.animationNodes")
	EffectManager.registerEffectXMLPaths(schema, "feedingRobot.robot.dischargeEffects")
	schema:register(XMLValueType.NODE_INDEX, "feedingRobot.robot.fillPlane#node", "Fillplane base node")
	schema:register(XMLValueType.INT, "feedingRobot.robot.fillPlane#capacity", "Fillplane capacity")
	schema:register(XMLValueType.STRING, "feedingRobot.robot.mixer#recipe", "Recipe filltype")
	FillPlaneUtil.registerFillPlaneXMLPaths(schema, "feedingRobot.robot.fillPlane")
	SoundManager.registerSampleXMLPaths(schema, "feedingRobot.robot.sounds", "driving")
	UnloadTrigger.registerXMLPaths(schema, "feedingRobot.unloadingSpots.unloadingSpot(?).unloadTrigger")
	FillPlane.registerXMLPaths(schema, "feedingRobot.unloadingSpots.unloadingSpot(?).fillPlane", "Fillplane")
	schema:register(XMLValueType.STRING, "feedingRobot.unloadingSpots.unloadingSpot(?)#capacity", "Unloading spot capacity")
	schema:register(XMLValueType.STRING, "feedingRobot.unloadingSpots.unloadingSpot(?)#fillTypes", "Unloading spot filltypes")
	schema:register(XMLValueType.STRING, "feedingRobot.unloadingSpots.unloadingSpot(?)#fillTypeCategories", "Unloading spot filltype categories")
	schema:register(XMLValueType.NODE_INDEX, "feedingRobot.unloadingSpots.unloadingSpot(?)#markerNode", "Unloading spot marker")
end)

function FeedingRobot.registerSavegameXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".unloadingSpot(?)#index", "Unloading spot index")
	schema:register(XMLValueType.INT, basePath .. ".unloadingSpot(?)#fillLevel", "Unloading spot filllevel")
end

function FeedingRobot.new(isServer, isClient, owner, baseDirectory, customMt)
	local self = Object.new(isServer, isClient, customMt or FeedingRobot_mt)
	self.owner = owner
	self.baseDirectory = baseDirectory
	self.i3dMappings = {}
	self.components = {}
	self.isLoadingFinished = false
	self.requestedStart = false
	self.spline = {
		nodes = {},
		time = 0,
		timeSent = 0,
		length = 0,
		feedingLength = 0,
		feedingFactor = 0,
		dirtyFlag = self:getNextDirtyFlag(),
		timeInterpolator = InterpolationTime.new(1.2),
		interpolator = InterpolatorValue.new(0)
	}
	self.fillTypeToUnloadingSpot = {}
	self.unloadingSpots = {}
	self.dirtyFlagFillLevel = self:getNextDirtyFlag()
	self.robot = nil
	self.playerTrigger = nil
	self.stateChangedListeners = {}
	self.animatedObjects = {}
	self.stateMachineNextIndex = 0
	self.stateIndex = nil
	self.state = {}
	self.stateMachine = {}
	self.stateTransitions = {}

	return self
end

function FeedingRobot:load(linkNode, filename, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArgs)
	local xmlFile = XMLFile.load("feedingRobot", filename, FeedingRobot.xmlSchema)

	if xmlFile == nil then
		return false
	end

	self.configFileName = filename
	local i3dFilename = Utils.getFilename(xmlFile:getValue("feedingRobot.filename"), self.baseDirectory)
	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(i3dFilename, true, false, self.onI3DFileLoaded, self, {
		xmlFile,
		linkNode,
		asyncCallbackFunction,
		asyncCallbackObject,
		asyncCallbackArgs
	})
end

function FeedingRobot:delete()
	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

		self.sharedLoadRequestId = nil
	end

	if self.animatedObjects ~= nil then
		for _, animatedObject in ipairs(self.animatedObjects) do
			animatedObject:delete()
		end

		self.animatedObjects = nil
	end

	if self.isServer then
		if self.robot ~= nil then
			removeTrigger(self.robot.trigger)
		end

		if self.playerTrigger ~= nil then
			removeTrigger(self.playerTrigger)
		end
	end

	if self.robot ~= nil then
		g_animationManager:deleteAnimations(self.robot.mixerAnimationNodes)
		g_effectManager:deleteEffects(self.robot.dischargeEffects)
		g_soundManager:deleteSamples(self.robot.samples)
	end

	if self.unloadingSpots ~= nil then
		for _, spot in ipairs(self.unloadingSpots) do
			if spot.trigger ~= nil then
				spot.trigger:delete()

				spot.trigger = nil
			end

			if spot.markerNode ~= nil then
				g_currentMission:removeTriggerMarker(spot.markerNode)

				spot.markerNode = nil
			end
		end
	end

	if self.rootNode ~= nil then
		delete(self.rootNode)

		self.rootNode = nil
	end

	FeedingRobot:superClass().delete(self)
end

function FeedingRobot:onI3DFileLoaded(node, failedReason, args)
	local xmlFile, linkNode, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArgs = unpack(args)

	if node ~= 0 then
		local numChildren = getNumOfChildren(node)

		for i = 0, numChildren - 1 do
			local component = {
				node = getChildAt(node, i)
			}

			table.insert(self.components, component)
		end

		if #self.components == 0 then
			Logging.xmlError(xmlFile, "Unable to get feedingRobot components")
			xmlFile:delete()
			asyncCallbackFunction(asyncCallbackObject, self, asyncCallbackArgs)

			return
		end

		I3DUtil.loadI3DMapping(xmlFile, "feedingRobot", self.components, self.i3dMappings)

		for _, component in ipairs(self.components) do
			link(linkNode, component.node)
		end

		self.rootNode = node
		self.robot = {
			node = xmlFile:getValue("feedingRobot.robot#node", nil, self.components, self.i3dMappings)
		}

		if self.isClient then
			self.robot.mixerAnimationNodes = g_animationManager:loadAnimations(xmlFile, "feedingRobot.robot.mixer.animationNodes", self.components, self, self.i3dMappings)
			self.robot.dischargeEffects = g_effectManager:loadEffect(xmlFile, "feedingRobot.robot.dischargeEffects", self.components, self, self.i3dMappings)
			self.robot.samples = {
				driving = g_soundManager:loadSampleFromXML(xmlFile, "feedingRobot.robot.sounds", "driving", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
				discharging = g_soundManager:loadSampleFromXML(xmlFile, "feedingRobot.robot.sounds", "discharging", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
			}
		end

		self.robot.maxSpeed = xmlFile:getValue("feedingRobot.robot#maxSpeed", 1) / 3600
		self.robot.speed = 0
		self.robot.acceleration = xmlFile:getValue("feedingRobot.robot#acceleration", 1) / 3600
		self.robot.deceleration = xmlFile:getValue("feedingRobot.robot#deceleration", -1) / 3600

		if self.robot.deceleration > 0 then
			self.robot.deceleration = -self.robot.deceleration
		end

		self.robot.door = {
			node = xmlFile:getValue("feedingRobot.robot.door#node", nil, self.components, self.i3dMappings),
			maxY = xmlFile:getValue("feedingRobot.robot.door#maxY", 0)
		}
		local duration = xmlFile:getValue("feedingRobot.robot.door#duration", 1) * 1000
		self.robot.door.speed = self.robot.door.maxY / duration
		self.robot.door.isOpen = false
		local recipeFillTypeName = xmlFile:getValue("feedingRobot.robot.mixer#recipe", "")
		local recipeFillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(recipeFillTypeName)

		if recipeFillTypeIndex == nil then
			Logging.xmlError(xmlFile, "Recipe filltype '%s' not defined.", recipeFillTypeName)
		end

		local recipe = g_currentMission.animalFoodSystem:getRecipeByFillTypeIndex(recipeFillTypeIndex)

		if recipe == nil then
			Logging.xmlError(xmlFile, "Recipe '%s' not defined.", recipeFillTypeName)
		else
			self.infos = {}

			for _, ingredient in pairs(recipe.ingredients) do
				local info = {
					text = "",
					title = ingredient.title,
					fillTypes = {}
				}

				for _, fillType in ipairs(ingredient.fillTypes) do
					table.insert(info.fillTypes, fillType)
				end

				table.insert(self.infos, info)
			end
		end

		self.robot.recipe = recipe
		self.robot.fillPlane = {
			baseNode = xmlFile:getValue("feedingRobot.robot.fillPlane#node", nil, self.components, self.i3dMappings),
			capacity = xmlFile:getValue("feedingRobot.robot.fillPlane#capacity", 2000),
			fillLevel = 0
		}
		self.robot.fillPlane.node = FillPlaneUtil.createFromXML(xmlFile, "feedingRobot.robot.fillPlane", self.robot.fillPlane.baseNode, self.robot.fillPlane.capacity)

		if self.robot.fillPlane.node ~= nil then
			FillPlaneUtil.assignDefaultMaterials(self.robot.fillPlane.node)
			FillPlaneUtil.setFillType(self.robot.fillPlane.node, recipeFillTypeIndex)
			setVisibility(self.robot.fillPlane.node, false)
		end

		self.robot.trigger = xmlFile:getValue("feedingRobot.robot#triggerNode", nil, self.components, self.i3dMappings)
		self.robot.objectsInTrigger = {}
		self.robot.isBlocked = false

		if self.isServer then
			addTrigger(self.robot.trigger, "onRobotTrigger", self)
		end

		self.playerTrigger = xmlFile:getValue("feedingRobot.playerTrigger#node", nil, self.components, self.i3dMappings)
		self.nodesInPlayerTrigger = {}

		if self.isServer then
			addTrigger(self.playerTrigger, "onPlayerTrigger", self)
		end

		xmlFile:iterate("feedingRobot.animatedObjects.animatedObject", function (index, fillAnimationKey)
			local animatedObject = AnimatedObject.new(self.isServer, self.isClient)

			animatedObject:setOwnerFarmId(self:getOwnerFarmId(), false)

			if animatedObject:load(self.components, xmlFile, fillAnimationKey, self.configFileName, self.i3dMappings) then
				table.insert(self.animatedObjects, animatedObject)
			else
				Logging.xmlError(xmlFile, "Failed to load animated object %i", index)
			end
		end)

		local maxNumStates = 255

		xmlFile:iterate("feedingRobot.stateMachine.states.state", function (_, stateKey)
			if maxNumStates < self.stateMachineNextIndex then
				Logging.xmlWarning(xmlFile, "Maximum number of states reached (%d)", maxNumStates)

				return
			end

			local stateName = xmlFile:getValue(stateKey .. "#name", ""):upper()

			if self.state[stateName] ~= nil then
				Logging.xmlError(xmlFile, "State '%s' already defined", stateName, stateKey)

				return
			end

			local stateClassName = xmlFile:getValue(stateKey .. "#class", "")
			local class = ClassUtil.getClassObject(stateClassName)

			if class == nil then
				Logging.xmlError(xmlFile, "State class '%s' not defined", stateClassName, stateKey)

				return
			end

			local stateIndex = self.stateMachineNextIndex
			self.state[stateName] = stateIndex
			local state = class.new(self)

			state:load(xmlFile, stateKey)

			self.stateMachine[stateIndex] = state
			self.stateMachineNextIndex = self.stateMachineNextIndex + 1

			if self.stateIndex == nil then
				self.stateIndex = stateIndex
			end
		end)

		if self.state.PAUSED == nil then
			Logging.xmlError(xmlFile, "Mandatory state 'PAUSED' not defined")
			xmlFile:delete()
			asyncCallbackFunction(asyncCallbackObject, self, asyncCallbackArgs)

			return
		end

		if self.state.DRIVING == nil then
			Logging.xmlError(xmlFile, "Mandatory state 'DRIVING' not defined")
			xmlFile:delete()
			asyncCallbackFunction(asyncCallbackObject, self, asyncCallbackArgs)

			return
		end

		xmlFile:iterate("feedingRobot.stateMachine.transitions.transition", function (_, transitionKey)
			local stateFromName = xmlFile:getValue(transitionKey .. "#from", ""):upper()
			local stateFromIndex = self.state[stateFromName]

			if stateFromIndex == nil then
				Logging.xmlError(xmlFile, "Invalid state. Transition from name '%s' not defined for '%s'", stateFromName, transitionKey)

				return
			end

			local stateToName = xmlFile:getValue(transitionKey .. "#to", ""):upper()
			local stateToIndex = self.state[stateToName]

			if stateToIndex == nil then
				Logging.xmlError(xmlFile, "Invalid state. Transition to name '%s' not defined for '%s'", stateToName, transitionKey)

				return
			end

			self.stateTransitions[stateFromIndex] = stateToIndex
		end)
		xmlFile:iterate("feedingRobot.unloadingSpots.unloadingSpot", function (_, unloadingKey)
			local spot = {}
			local unloadTrigger = UnloadTrigger.new(self.isServer, self.isClient)

			if not unloadTrigger:load(self.components, xmlFile, unloadingKey .. ".unloadTrigger", self, nil, self.i3dMappings) then
				unloadTrigger:delete()

				return
			end

			spot.trigger = unloadTrigger
			spot.capacity = xmlFile:getInt(unloadingKey .. "#capacity", 1000)
			spot.FILLLEVEL_NUM_BITS = MathUtil.getNumRequiredBits(spot.capacity)
			spot.fillLevel = 0
			spot.fillTypes = {}
			spot.markerNode = xmlFile:getValue(unloadingKey .. "#markerNode", nil, self.components, self.i3dMappings)

			if spot.markerNode ~= nil then
				g_currentMission:addTriggerMarker(spot.markerNode)
			end

			local fillTypeCategories = xmlFile:getValue(unloadingKey .. "#fillTypeCategories")
			local fillTypeNames = xmlFile:getValue(unloadingKey .. "#fillTypes")
			local fillTypes = nil

			if fillTypeCategories ~= nil and fillTypeNames == nil then
				fillTypes = g_fillTypeManager:getFillTypesByCategoryNames(fillTypeCategories, "Warning: '" .. tostring(unloadingKey) .. "' has invalid fillTypeCategory '%s'.")
			elseif fillTypeCategories == nil and fillTypeNames ~= nil then
				fillTypes = g_fillTypeManager:getFillTypesByNames(fillTypeNames, "Warning: '" .. tostring(unloadingKey) .. "' has invalid fillType '%s'.")
			else
				Logging.xmlWarning(xmlFile, "'%s' An 'unloadingSpot' entry needs either the 'fillTypeCategories' or 'fillTypes' attribute.", unloadingKey)
				unloadTrigger:delete()

				return
			end

			unloadTrigger.fillTypes = {}

			for _, fillType in pairs(fillTypes) do
				table.addElement(spot.fillTypes, fillType)

				self.fillTypeToUnloadingSpot[fillType] = spot
				unloadTrigger.fillTypes[fillType] = true
			end

			if xmlFile:hasProperty(unloadingKey .. ".fillPlane") then
				spot.fillPlane = FillPlane.new()

				spot.fillPlane:load(self.components, xmlFile, unloadingKey .. ".fillPlane", self.i3dMappings)
				FillPlaneUtil.assignDefaultMaterials(spot.fillPlane.node)
				FillPlaneUtil.setFillType(spot.fillPlane.node, next(unloadTrigger.fillTypes))
				setShaderParameter(spot.fillPlane.node, "isCustomShape", 1, 0, 0, 0, false)
			end

			table.insert(self.unloadingSpots, spot)
		end)
		self:raiseActive()
	end

	xmlFile:delete()
	asyncCallbackFunction(asyncCallbackObject, self, asyncCallbackArgs)
end

function FeedingRobot:finalizePlacement()
	for _, component in ipairs(self.components) do
		addToPhysics(component.node)
	end

	for _, animatedObject in ipairs(self.animatedObjects) do
		animatedObject:register(true)
	end

	for _, spot in ipairs(self.unloadingSpots) do
		spot.trigger:register(true)
	end

	self.isLoadingFinished = true
end

function FeedingRobot:readStream(streamId, connection)
	FeedingRobot:superClass().readStream(self, streamId, connection)

	if connection:getIsServer() then
		local stateIndex = streamReadUInt8(streamId)

		self:setState(stateIndex)

		local splineTime = streamReadFloat32(streamId)

		self.spline.interpolator:setValue(splineTime)
		self.spline.timeInterpolator:reset()

		self.spline.time = splineTime

		for _, animatedObject in ipairs(self.animatedObjects) do
			local animatedObjectId = NetworkUtil.readNodeObjectId(streamId)

			animatedObject:readStream(streamId, connection)
			g_client:finishRegisterObject(animatedObject, animatedObjectId)
		end

		for _, spot in ipairs(self.unloadingSpots) do
			local unloadTriggerId = NetworkUtil.readNodeObjectId(streamId)

			spot.trigger:readStream(streamId, connection)
			g_client:finishRegisterObject(spot.trigger, unloadTriggerId)

			spot.fillLevel = streamReadUIntN(streamId, spot.FILLLEVEL_NUM_BITS)

			self:updateUnloadingSpot(spot)
		end

		self:raiseActive()
	end
end

function FeedingRobot:writeStream(streamId, connection)
	FeedingRobot:superClass().writeStream(self, streamId, connection)

	if not connection:getIsServer() then
		streamWriteUInt8(streamId, self.stateIndex)
		streamWriteFloat32(streamId, self.spline.timeSent)

		for _, animatedObject in ipairs(self.animatedObjects) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(animatedObject))
			animatedObject:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, animatedObject)
		end

		for _, spot in ipairs(self.unloadingSpots) do
			NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(spot.trigger))
			spot.trigger:writeStream(streamId, connection)
			g_server:registerObjectInStream(connection, spot.trigger)
			streamWriteUIntN(streamId, spot.fillLevel, spot.FILLLEVEL_NUM_BITS)
		end
	end
end

function FeedingRobot:readUpdateStream(streamId, timestamp, connection)
	FeedingRobot:superClass().readUpdateStream(self, streamId, timestamp, connection)

	if connection:getIsServer() then
		if streamReadBool(streamId) then
			local splineTime = streamReadFloat32(streamId)

			self.spline.timeInterpolator:startNewPhaseNetwork()
			self.spline.interpolator:setTargetValue(splineTime)
		end

		if streamReadBool(streamId) then
			for _, spot in ipairs(self.unloadingSpots) do
				spot.fillLevel = streamReadUIntN(streamId, spot.FILLLEVEL_NUM_BITS)

				self:updateUnloadingSpot(spot)
			end
		end
	end
end

function FeedingRobot:writeUpdateStream(streamId, connection, dirtyMask)
	FeedingRobot:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)

	if not connection:getIsServer() then
		if streamWriteBool(streamId, bitAND(dirtyMask, self.spline.dirtyFlag) ~= 0) then
			streamWriteFloat32(streamId, self.spline.timeSent)
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, self.dirtyFlagFillLevel) ~= 0) then
			for _, spot in ipairs(self.unloadingSpots) do
				streamWriteUIntN(streamId, spot.fillLevel, spot.FILLLEVEL_NUM_BITS)
			end
		end
	end
end

function FeedingRobot:loadFromXMLFile(xmlFile, key)
	xmlFile:iterate(key .. ".unloadingSpot", function (_, fillLevelKey)
		local spotIndex = xmlFile:getValue(fillLevelKey .. "#index")
		local fillLevel = xmlFile:getValue(fillLevelKey .. "#fillLevel")

		if spotIndex ~= nil and fillLevel ~= nil then
			local spot = self.unloadingSpots[spotIndex]

			if spot ~= nil then
				spot.fillLevel = MathUtil.clamp(fillLevel, 0, spot.capacity)

				self:updateUnloadingSpot(spot)
			end
		end
	end)
end

function FeedingRobot:saveToXMLFile(xmlFile, key, usedModNames)
	local index = 0

	for spotIndex, spot in pairs(self.unloadingSpots) do
		local spotKey = string.format("%s.unloadingSpot(%d)", key, index)

		xmlFile:setValue(spotKey .. "#index", spotIndex)
		xmlFile:setValue(spotKey .. "#fillLevel", spot.fillLevel)

		index = index + 1
	end
end

function FeedingRobot:setOwnerFarmId(ownerFarmId, noEventSend)
	FeedingRobot:superClass().setOwnerFarmId(self, ownerFarmId, noEventSend)

	for _, animatedObject in ipairs(self.animatedObjects) do
		animatedObject:setOwnerFarmId(ownerFarmId, true)
	end
end

function FeedingRobot:addSpline(node, direction, isFeeding)
	local length = getSplineLength(node)

	table.insert(self.spline.nodes, {
		endTime = 0,
		startTime = 0,
		node = node,
		direction = direction,
		length = length,
		isFeeding = isFeeding
	})

	self.spline.length = self.spline.length + length

	if isFeeding then
		self.spline.feedingLength = self.spline.feedingLength + length
	end

	local startTime = 0

	for _, splineNode in ipairs(self.spline.nodes) do
		splineNode.startTime = math.max(startTime, 0)
		splineNode.endTime = math.min(startTime + splineNode.length / self.spline.length, 1)
		startTime = splineNode.endTime
	end
end

function FeedingRobot:update(dt)
	if not self.isLoadingFinished then
		return
	end

	local state = self.stateMachine[self.stateIndex]

	if self.isServer then
		if state:isDone() then
			local nextStateIndex = self.stateTransitions[self.stateIndex]

			self:setState(nextStateIndex)
			self:raiseActive()
		elseif state:raiseActive() then
			self:raiseActive()
		end
	end

	state:update(dt)

	if not self.isServer and self.isClient and self:getIsDriving() then
		self.spline.timeInterpolator:update(dt)

		local interpolationAlpha = self.spline.timeInterpolator:getAlpha()
		local splineTime = self.spline.interpolator:getInterpolatedValue(interpolationAlpha)
		splineTime = SplineUtil.getValidSplineTime(splineTime)

		self:setSplineTime(splineTime)

		if self.spline.timeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end

	local door = self.robot.door
	local dir = 1

	if not door.isOpen then
		dir = -1
	end

	local _, y, _ = getTranslation(door.node)
	y = MathUtil.clamp(y + dir * dt * door.speed, 0, door.maxY)

	setTranslation(door.node, 0, y, 0)
end

function FeedingRobot:start()
	if self.isServer and self.stateIndex == self.state.PAUSED then
		for node, _ in pairs(self.nodesInPlayerTrigger) do
			if not entityExists(node) then
				self.nodesInPlayerTrigger[node] = nil
			end
		end

		if next(self.nodesInPlayerTrigger) == nil then
			self.requestedStart = true

			self:raiseActive()
		end
	end
end

function FeedingRobot:getIsDriving()
	return self.stateIndex == self.state.DRIVING
end

function FeedingRobot:addStateChangedListener(func)
	table.addElement(self.stateChangedListeners, func)
end

function FeedingRobot:resetRobot()
	self:setSplineTime(0)
end

function FeedingRobot:addSplineDelta(delta)
	self:setSplineTime(self.spline.time + delta / self.spline.length)
end

function FeedingRobot:setSplineTime(splineTime)
	local spline = self.spline
	spline.time = MathUtil.clamp(splineTime, 0, 1)
	local dischargeEffectActive = false
	local feedingLength = 0

	for _, splineNode in ipairs(spline.nodes) do
		if splineNode.startTime <= splineTime and splineTime <= splineNode.endTime then
			local rangeTime = (splineTime - splineNode.startTime) / (splineNode.endTime - splineNode.startTime)
			local node = splineNode.node
			local robotNode = self.robot.node
			local x, y, z = getSplinePosition(node, rangeTime)
			local dirX, dirY, dirZ = getSplineDirection(node, rangeTime)
			dirX, dirY, dirZ = worldDirectionToLocal(getParent(robotNode), dirX, dirY, dirZ)
			dirX = dirX * splineNode.direction
			dirZ = dirZ * splineNode.direction

			setWorldTranslation(robotNode, x, y, z)
			setDirection(robotNode, dirX, dirY, dirZ, 0, 1, 0)

			if splineNode.isFeeding then
				dischargeEffectActive = true
				feedingLength = feedingLength + splineNode.length * rangeTime
			end

			break
		end

		if splineNode.isFeeding then
			feedingLength = feedingLength + splineNode.length
		end
	end

	local feedingFactor = 0

	if self.spline.feedingLength > 0 then
		feedingFactor = feedingLength / self.spline.feedingLength
	end

	self.spline.feedingFactor = feedingFactor

	if dischargeEffectActive then
		if not g_soundManager:getIsSamplePlaying(self.robot.samples.discharging) then
			g_soundManager:playSample(self.robot.samples.discharging)
		end

		if not self.robot.dischargeEffectsActive then
			g_effectManager:setFillType(self.robot.dischargeEffects, self.robot.recipe.fillType)
			g_effectManager:startEffects(self.robot.dischargeEffects)

			self.robot.dischargeEffectsActive = true
		end
	else
		if g_soundManager:getIsSamplePlaying(self.robot.samples.discharging) then
			g_soundManager:stopSample(self.robot.samples.discharging)
		end

		if self.robot.dischargeEffectsActive then
			g_effectManager:stopEffects(self.robot.dischargeEffects)

			self.robot.dischargeEffectsActive = false
		end
	end

	self.robot.door.isOpen = dischargeEffectActive

	if self.isServer then
		local threshold = 0.02 / self.spline.length

		if threshold < math.abs(self.spline.time - self.spline.timeSent) then
			self.spline.timeSent = self.spline.time

			self:raiseDirtyFlags(self.spline.dirtyFlag)
		end
	end
end

function FeedingRobot:getFeedingFactor()
	return self.spline.feedingFactor
end

function FeedingRobot:setState(newState)
	if newState ~= self.stateIndex then
		if self.isServer then
			g_server:broadcastEvent(FeedingRobotStateEvent.new(self, newState), false)
		end

		local oldStateIndex = self.stateIndex
		self.stateIndex = newState
		local oldState = self.stateMachine[oldStateIndex]
		local state = self.stateMachine[newState]

		oldState:deactivate()
		state:activate()

		for _, func in ipairs(self.stateChangedListeners) do
			func(self, newState)
		end

		if self.isClient then
			if newState == self.state.DRIVING and not g_soundManager:getIsSamplePlaying(self.robot.samples.driving) then
				g_soundManager:playSample(self.robot.samples.driving)
			elseif newState ~= self.state.DRIVING and g_soundManager:getIsSamplePlaying(self.robot.samples.driving) then
				g_soundManager:stopSamples(self.robot.samples)
			end
		end
	end
end

function FeedingRobot:getState()
	return self.stateIndex
end

function FeedingRobot:setFillScale(scale)
	local fillPlane = self.robot.fillPlane

	if fillPlane ~= nil and fillPlane.node ~= nil then
		local targetLevel = scale * fillPlane.capacity
		local delta = targetLevel - fillPlane.fillLevel

		if math.abs(delta) > 10 then
			fillPlane.fillLevel = targetLevel
			local node = fillPlane.node
			local x, y, z = localToWorld(node, 0, 0, 0)
			local d1x, d1y, d1z = localDirectionToWorld(node, 0.5, 0, 0)
			local d2x, d2y, d2z = localDirectionToWorld(node, 0, 0, 0.5)

			fillPlaneAdd(node, delta, x, y, z, d1x, d1y, d1z, d2x, d2y, d2z)
		end

		setVisibility(fillPlane.node, scale > 0)
	end
end

function FeedingRobot:onRobotTrigger(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter then
		self.robot.objectsInTrigger[otherId] = true
	elseif onLeave then
		self.robot.objectsInTrigger[otherId] = nil
	end

	self.robot.isBlocked = next(self.robot.objectsInTrigger) ~= nil
end

function FeedingRobot:onPlayerTrigger(triggerId, otherId, onEnter, onLeave, onStay)
	if onEnter then
		self.nodesInPlayerTrigger[otherId] = true
	elseif onLeave then
		self.nodesInPlayerTrigger[otherId] = nil
	end
end

function FeedingRobot:getIsNodeUsed(node)
	for _, spot in ipairs(self.unloadingSpots) do
		if spot.trigger ~= nil and spot.trigger.exactFillRootNode == node then
			return true
		end
	end

	return false
end

function FeedingRobot:getFreeCapacity(fillTypeIndex)
	local spot = self.fillTypeToUnloadingSpot[fillTypeIndex]

	if spot ~= nil then
		return spot.capacity - spot.fillLevel
	end

	return 0
end

function FeedingRobot:getIsFillTypeAllowed(fillTypeIndex)
	local spot = self.fillTypeToUnloadingSpot[fillTypeIndex]

	return spot ~= nil
end

function FeedingRobot:getIsToolTypeAllowed(toolType)
	return true
end

function FeedingRobot:addFillLevelFromTool(farmId, deltaFillLevel, fillTypeIndex, fillPositionData, toolType, extraAttributes)
	local spot = self.fillTypeToUnloadingSpot[fillTypeIndex]

	if spot == nil then
		return 0
	end

	if spot.capacity <= spot.fillLevel then
		return 0
	end

	deltaFillLevel = math.min(spot.capacity - spot.fillLevel, deltaFillLevel)

	if self.isServer then
		self:raiseDirtyFlags(self.dirtyFlagFillLevel)
	end

	spot.fillLevel = spot.fillLevel + deltaFillLevel

	self:updateUnloadingSpot(spot)

	return deltaFillLevel
end

function FeedingRobot:removeFillLevel(deltaFillLevel, fillTypeIndex)
	local spot = self.fillTypeToUnloadingSpot[fillTypeIndex]
	local absDelta = math.abs(deltaFillLevel)

	if spot ~= nil then
		local spotDelta = math.min(absDelta, spot.fillLevel)
		spot.fillLevel = spot.fillLevel - spotDelta
		absDelta = absDelta - spotDelta

		if self.isServer then
			self:raiseDirtyFlags(self.dirtyFlagFillLevel)
		end

		self:updateUnloadingSpot(spot)
	end

	return math.abs(deltaFillLevel) - absDelta
end

function FeedingRobot:getFillLevel(fillTypeIndex)
	local fillLevel = 0
	local spot = self.fillTypeToUnloadingSpot[fillTypeIndex]

	if spot ~= nil then
		fillLevel = fillLevel + spot.fillLevel
	end

	return fillLevel
end

function FeedingRobot:updateUnloadingSpot(spot)
	if spot.fillPlane ~= nil then
		spot.fillPlane:setState(spot.fillLevel / spot.capacity)
	end
end

function FeedingRobot:createFoodMixture()
	if self.isServer then
		local recipe = self.robot.recipe
		local maxLiters = math.min(self.robot.fillPlane.capacity, self.owner:getFreeFoodCapacity(recipe.fillType))

		for _, ingredient in pairs(recipe.ingredients) do
			local fillLevel = 0

			for _, fillType in ipairs(ingredient.fillTypes) do
				fillLevel = fillLevel + self:getFillLevel(fillType)
			end

			maxLiters = math.min(maxLiters, fillLevel / ingredient.ratio)

			if maxLiters <= 0 then
				return
			end
		end

		for _, ingredient in pairs(recipe.ingredients) do
			local usedFillLevel = maxLiters * ingredient.ratio

			for _, fillType in ipairs(ingredient.fillTypes) do
				local delta = self:removeFillLevel(usedFillLevel, fillType)
				usedFillLevel = usedFillLevel - delta

				if usedFillLevel <= 0 then
					break
				end
			end
		end

		self.owner:addFood(self:getOwnerFarmId(), maxLiters, recipe.fillType, nil, , )
		self:start()
	end
end

function FeedingRobot:updateInfo(infoTable)
	if self.infos ~= nil then
		for _, info in ipairs(self.infos) do
			local fillLevel = 0

			for _, fillType in ipairs(info.fillTypes) do
				fillLevel = fillLevel + self:getFillLevel(fillType)
			end

			info.text = string.format("%d l", fillLevel)

			table.insert(infoTable, info)
		end
	end
end
