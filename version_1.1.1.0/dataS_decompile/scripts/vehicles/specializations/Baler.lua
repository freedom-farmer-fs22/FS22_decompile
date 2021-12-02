source("dataS/scripts/vehicles/specializations/events/BalerSetIsUnloadingBaleEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerSetBaleTimeEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerCreateBaleEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerDropFromPlatformEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerAutomaticDropEvent.lua")
source("dataS/scripts/vehicles/specializations/events/BalerBaleTypeEvent.lua")

Baler = {
	UNLOADING_CLOSED = 1,
	UNLOADING_OPENING = 2,
	UNLOADING_OPEN = 3,
	UNLOADING_CLOSING = 4
}

function Baler.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("baler", false)
	g_storeManager:addSpecType("balerBaleSizeRound", "shopListAttributeIconBaleSizeRound", Baler.loadSpecValueBaleSizeRound, Baler.getSpecValueBaleSizeRound, "vehicle")
	g_storeManager:addSpecType("balerBaleSizeSquare", "shopListAttributeIconBaleSizeSquare", Baler.loadSpecValueBaleSizeSquare, Baler.getSpecValueBaleSizeSquare, "vehicle")

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Baler")
	schema:register(XMLValueType.FLOAT, "vehicle.baler#fillScale", "Fill scale", 1)
	schema:register(XMLValueType.INT, "vehicle.baler#fillUnitIndex", "Fill unit index", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.baleAnimation#spacing", "Spacing between bales", 0)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.baleAnimation.key(?)#time", "Key time")
	schema:register(XMLValueType.VECTOR_TRANS, "vehicle.baler.baleAnimation.key(?)#pos", "Key position")
	schema:register(XMLValueType.VECTOR_ROT, "vehicle.baler.baleAnimation.key(?)#rot", "Key rotation")
	schema:register(XMLValueType.STRING, "vehicle.baler.baleAnimation#closeAnimationName", "Close animation name")
	schema:register(XMLValueType.FLOAT, "vehicle.baler.baleAnimation#closeAnimationSpeed", "Close animation speed", 1)
	schema:register(XMLValueType.BOOL, "vehicle.baler.automaticDrop#enabled", "Automatic drop default enabled", "true on mobile")
	schema:register(XMLValueType.BOOL, "vehicle.baler.automaticDrop#toggleable", "Automatic bale drop can be toggled", "false on mobile")
	schema:register(XMLValueType.BOOL, "vehicle.baler.baleTypes.baleType(?)#isRoundBale", "Is round bale", false)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.baleTypes.baleType(?)#width", "Bale width", 1.2)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.baleTypes.baleType(?)#height", "Bale height", 0.9)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.baleTypes.baleType(?)#length", "Bale length", 2.4)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.baleTypes.baleType(?)#diameter", "Bale diameter", 2.8)
	schema:register(XMLValueType.BOOL, "vehicle.baler.baleTypes.baleType(?)#isDefault", "Bale type is selected by default", false)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baler.baleTypes.baleType(?).nodes#baleNode", "Bale link node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baler.baleTypes.baleType(?).nodes#baleRootNode", "Bale root node", "Same as baleNode")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baler.baleTypes.baleType(?).nodes#scaleNode", "Bale scale node")
	schema:register(XMLValueType.VECTOR_3, "vehicle.baler.baleTypes.baleType(?).nodes#scaleComponents", "Bale scale component")
	schema:register(XMLValueType.STRING, "vehicle.baler.baleTypes.baleType(?).animations#fillAnimation", "Fill animation while this bale type is active")
	schema:register(XMLValueType.STRING, "vehicle.baler.baleTypes.baleType(?).animations#unloadAnimation", "Unload animation while this bale type is active")
	schema:register(XMLValueType.FLOAT, "vehicle.baler.baleTypes.baleType(?).animations#unloadAnimationSpeed", "Unload animation speed", 1)
	schema:register(XMLValueType.TIME, "vehicle.baler.baleTypes.baleType(?).animations#dropAnimationTime", "Specific time in #unloadAnimation when to drop the bale", "At the end of the unloading animation")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.baler.baleTypes.baleType(?)")
	schema:register(XMLValueType.FLOAT, "vehicle.baler#unfinishedBaleThreshold", "Threshold to unload a unfinished bale", 2000)
	schema:register(XMLValueType.BOOL, "vehicle.baler#canUnloadUnfinishedBale", "Can unload unfinished bale", false)
	SoundManager.registerSampleXMLPaths(schema, "vehicle.baler.sounds", "work")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.baler.sounds", "eject")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.baler.sounds", "door")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.baler.sounds", "knotCleaning")
	AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.baler.animationNodes")
	AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.baler.unloadAnimationNodes")
	EffectManager.registerEffectXMLPaths(schema, "vehicle.baler.fillEffect")
	schema:register(XMLValueType.STRING, "vehicle.baler.knotingAnimation#name", "Knoting animation name")
	schema:register(XMLValueType.FLOAT, "vehicle.baler.knotingAnimation#speed", "Knoting animation speed", 1)
	schema:register(XMLValueType.STRING, "vehicle.baler.compactingAnimation#name", "Compacting animation name")
	schema:register(XMLValueType.FLOAT, "vehicle.baler.compactingAnimation#interval", "Compacting interval", 60)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.compactingAnimation#compactTime", "Compacting time", 5)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.compactingAnimation#speed", "Compacting animation speed", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.compactingAnimation#minFillLevelTime", "Compacting min. fill level animation target time", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.compactingAnimation#maxFillLevelTime", "Compacting max. fill level animation target time", 0.1)
	schema:register(XMLValueType.STRING, "vehicle.baler#maxPickupLitersPerSecond", "Max pickup liters per second", 500)
	schema:register(XMLValueType.BOOL, "vehicle.baler.baleUnloading#allowed", "Bale unloading allowed", false)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.baleUnloading#time", "Bale unloading time", 4)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.baleUnloading#foldThreshold", "Bale unloading fold threshold", 0.25)
	schema:register(XMLValueType.L10N_STRING, "vehicle.baler.automaticDrop#textPos", "Positive toggle automatic drop text", "action_toggleAutomaticBaleDropPos")
	schema:register(XMLValueType.L10N_STRING, "vehicle.baler.automaticDrop#textNeg", "Negative toggle automatic drop text", "action_toggleAutomaticBaleDropNeg")
	schema:register(XMLValueType.L10N_STRING, "vehicle.baleTypes#changeText", "Change bale size text", "action_changeBaleSize")
	schema:register(XMLValueType.STRING, "vehicle.baler.platform#animationName", "Platform animation")
	schema:register(XMLValueType.FLOAT, "vehicle.baler.platform#nextBaleTime", "Animation time when directly the next bale is unloaded after dropping from platform", 0)
	schema:register(XMLValueType.BOOL, "vehicle.baler.platform#automaticDrop", "Bale is automatically dropped from platform", "true on mobile")
	schema:register(XMLValueType.FLOAT, "vehicle.baler.platform#aiSpeed", "Speed of AI while dropping a bale from platform (km/h)", 3)
	schema:register(XMLValueType.INT, "vehicle.baler.buffer#fillUnitIndex", "Buffer fill unit index")
	schema:register(XMLValueType.FLOAT, "vehicle.baler.buffer#capacityPercentage", "If set, this percentage of the bale capacity is set for the buffer. If not set the defined capacity from the xml is used.")
	schema:register(XMLValueType.TIME, "vehicle.baler.buffer#overloadingDuration", "Duration of overloading from buffer to baler unit (sec)", 0.5)
	schema:register(XMLValueType.BOOL, "vehicle.baler.buffer#fillMainUnitAfterOverload", "After overloading the full buffer to the main unit it will continue filling the main unit until it's full", false)
	schema:register(XMLValueType.STRING, "vehicle.baler.buffer#balerDisplayType", "Forced fill type to display on baler unit")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baler.buffer.dummyBale#node", "Dummy bale link node")
	schema:register(XMLValueType.VECTOR_3, "vehicle.baler.buffer.dummyBale#scaleComponents", "Dummy bale link scale components", "1 1 0")
	schema:register(XMLValueType.STRING, "vehicle.baler.buffer.overloadAnimation#name", "Name of overload animation")
	schema:register(XMLValueType.FLOAT, "vehicle.baler.buffer.overloadAnimation#speedScale", "Speed of overload animation", 1)
	schema:register(XMLValueType.STRING, "vehicle.baler.buffer.loadingStateAnimation#name", "Name of loading state animation")
	schema:register(XMLValueType.FLOAT, "vehicle.baler.buffer.loadingStateAnimation#speedScale", "Speed of loading state animation", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.variableSpeedLimit#targetLiterPerSecond", "Target liters per second", 200)
	schema:register(XMLValueType.TIME, "vehicle.baler.variableSpeedLimit#changeInterval", "Interval which adjusts speed limit to conditions", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.variableSpeedLimit#minSpeedLimit", "Min. speed limit", 5)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.variableSpeedLimit#maxSpeedLimit", "Max. speed limit", 15)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.variableSpeedLimit#defaultSpeedLimit", "Default speed limit", 10)
	schema:register(XMLValueType.STRING, "vehicle.baler.variableSpeedLimit.target(?)#fillType", "Name of fill type")
	schema:register(XMLValueType.FLOAT, "vehicle.baler.variableSpeedLimit.target(?)#targetLiterPerSecond", "Target liters per second with this fill type", 200)
	schema:register(XMLValueType.FLOAT, "vehicle.baler.variableSpeedLimit.target(?)#defaultSpeedLimit", "Default speed limit with this fill type", 10)
	schema:register(XMLValueType.BOOL, FillUnit.ALARM_TRIGGER_XML_KEY .. "#needsBaleLoaded", "Alarm triggers only when a full bale is loaded", false)
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame

	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baler#numBales", "Number of bales")
	schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).baler.bale(?)#filename", "XML Filename of bale")
	schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).baler.bale(?)#fillType", "Bale fill type index")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).baler.bale(?)#fillLevel", "Bale fill level")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).baler.bale(?)#baleTime", "Bale time")
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).baler#platformReadyToDrop", "Platform is ready to drop", false)
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baler#baleTypeIndex", "Current bale type index", 1)
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baler#preSelectedBaleTypeIndex", "Pre selected bale type index", 1)
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).baler#fillUnitCapacity", "Current baler capacity depending on bale size")
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).baler#bufferUnloadingStarted", "Baler buffer unloading in progress")
end

function Baler.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end

function Baler.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processBalerArea", Baler.processBalerArea)
	SpecializationUtil.registerFunction(vehicleType, "setBaleTypeIndex", Baler.setBaleTypeIndex)
	SpecializationUtil.registerFunction(vehicleType, "isUnloadingAllowed", Baler.isUnloadingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getTimeFromLevel", Baler.getTimeFromLevel)
	SpecializationUtil.registerFunction(vehicleType, "moveBales", Baler.moveBales)
	SpecializationUtil.registerFunction(vehicleType, "moveBale", Baler.moveBale)
	SpecializationUtil.registerFunction(vehicleType, "setIsUnloadingBale", Baler.setIsUnloadingBale)
	SpecializationUtil.registerFunction(vehicleType, "getIsBaleUnloading", Baler.getIsBaleUnloading)
	SpecializationUtil.registerFunction(vehicleType, "dropBale", Baler.dropBale)
	SpecializationUtil.registerFunction(vehicleType, "finishBale", Baler.finishBale)
	SpecializationUtil.registerFunction(vehicleType, "createBale", Baler.createBale)
	SpecializationUtil.registerFunction(vehicleType, "setBaleTime", Baler.setBaleTime)
	SpecializationUtil.registerFunction(vehicleType, "getCanUnloadUnfinishedBale", Baler.getCanUnloadUnfinishedBale)
	SpecializationUtil.registerFunction(vehicleType, "setBalerAutomaticDrop", Baler.setBalerAutomaticDrop)
	SpecializationUtil.registerFunction(vehicleType, "updateDummyBale", Baler.updateDummyBale)
	SpecializationUtil.registerFunction(vehicleType, "deleteDummyBale", Baler.deleteDummyBale)
	SpecializationUtil.registerFunction(vehicleType, "createDummyBale", Baler.createDummyBale)
	SpecializationUtil.registerFunction(vehicleType, "handleUnloadingBaleEvent", Baler.handleUnloadingBaleEvent)
	SpecializationUtil.registerFunction(vehicleType, "dropBaleFromPlatform", Baler.dropBaleFromPlatform)
end

function Baler.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Baler.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Baler.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Baler.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Baler.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Baler.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Baler.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", Baler.getConsumingLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Baler.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttachedTo", Baler.getIsAttachedTo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", Baler.getAllowDynamicMountFillLevelInfo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAlarmTriggerIsActive", Baler.getAlarmTriggerIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAlarmTrigger", Baler.loadAlarmTrigger)
end

function Baler.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onChangedFillType", Baler)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Baler)
end

function Baler:onLoad(savegame)
	local spec = self.spec_baler

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.fillScale#value", "vehicle.baler#fillScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.baler.animationNodes.animationNode", "baler")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.balingAnimation#name", "vehicle.turnOnVehicle.turnedOnAnimation#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.fillParticleSystems", "vehicle.baler.fillEffect with effectClass 'ParticleEffect'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.uvScrollParts.uvScrollPart", "vehicle.baler.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.balerAlarm", "vehicle.fillUnit.fillUnitConfigurations.fillUnitConfiguration.fillUnits.fillUnit.alarmTriggers.alarmTrigger.alarmSound")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#node", "vehicle.baler.baleTypes.baleType#baleNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#baleNode", "vehicle.baler.baleTypes.baleType#baleNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#scaleNode", "vehicle.baler.baleTypes.baleType#scaleNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#baleScaleComponent", "vehicle.baler.baleTypes.baleType#scaleComponents")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#unloadAnimationName", "vehicle.baler.baleTypes.baleType#unloadAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#unloadAnimationSpeed", "vehicle.baler.baleTypes.baleType#unloadAnimationSpeed")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#baleDropAnimTime", "vehicle.baler.baleTypes.baleType#dropAnimationTime")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler#toggleAutomaticDropTextPos", "vehicle.baler.automaticDrop#textPos")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler#toggleAutomaticDropTextNeg", "vehicle.baler.automaticDrop#textNeg")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baler.baleAnimation#firstBaleMarker", "Please adjust bale nodes to match the default balers")

	spec.fillScale = self.xmlFile:getValue("vehicle.baler#fillScale", 1)
	spec.fillUnitIndex = self.xmlFile:getValue("vehicle.baler#fillUnitIndex", 1)

	if self.xmlFile:hasProperty("vehicle.baler.baleAnimation") then
		local baleAnimCurve = AnimCurve.new(linearInterpolatorN)
		local keyframes = {}
		local lastX, lastY, lastZ = nil
		local totalLength = 0

		self.xmlFile:iterate("vehicle.baler.baleAnimation.key", function (_, key)
			XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#time")

			local keyframe = {}
			keyframe.x, keyframe.y, keyframe.z = self.xmlFile:getValue(key .. "#pos")
			keyframe.rx, keyframe.ry, keyframe.rz = self.xmlFile:getValue(key .. "#rot", "0 0 0")

			if lastX ~= nil then
				keyframe.length = MathUtil.vector3Length(lastX - keyframe.x, lastY - keyframe.y, lastZ - keyframe.z)
				totalLength = totalLength + keyframe.length
				keyframe.pos = totalLength
			end

			table.insert(keyframes, keyframe)

			lastZ = keyframe.z
			lastY = keyframe.y
			lastX = keyframe.x
		end)

		for i = 1, #keyframes do
			local keyframe = keyframes[i]
			local t = 0

			if keyframe.pos ~= nil then
				t = keyframe.pos / totalLength
			end

			baleAnimCurve:addKeyframe({
				keyframe.x,
				keyframe.y,
				keyframe.z,
				keyframe.rx,
				keyframe.ry,
				keyframe.rz,
				time = t
			})
		end

		if #keyframes > 0 then
			spec.baleAnimCurve = baleAnimCurve
			spec.baleAnimLength = totalLength
			spec.baleAnimSpacing = self.xmlFile:getValue("vehicle.baler.baleAnimation#spacing", 0)
		end
	end

	spec.hasUnloadingAnimation = true
	local defaultBaleTypeIndex = 1
	spec.baleTypes = {}

	self.xmlFile:iterate("vehicle.baler.baleTypes.baleType", function (index, key)
		if BalerBaleTypeEvent.MAX_NUM_BALE_TYPES <= #spec.baleTypes then
			Logging.xmlError(self.xmlFile, "Too many bale types defined. Max. amount is '%d'! '%s'", BalerBaleTypeEvent.MAX_NUM_BALE_TYPES, key)

			return false
		end

		local baleTypeDefinition = {
			index = index,
			isRoundBale = self.xmlFile:getValue(key .. "#isRoundBale", false),
			width = MathUtil.round(self.xmlFile:getValue(key .. "#width", 1.2), 2),
			height = MathUtil.round(self.xmlFile:getValue(key .. "#height", 0.9), 2),
			length = MathUtil.round(self.xmlFile:getValue(key .. "#length", 2.4), 2),
			diameter = MathUtil.round(self.xmlFile:getValue(key .. "#diameter", 1.8), 2),
			isDefault = self.xmlFile:getValue(key .. "#isDefault", false)
		}

		if baleTypeDefinition.isDefault then
			defaultBaleTypeIndex = index
		end

		baleTypeDefinition.baleNode = self.xmlFile:getValue(key .. ".nodes#baleNode", nil, self.components, self.i3dMappings)
		baleTypeDefinition.baleRootNode, baleTypeDefinition.baleNodeComponent = self.xmlFile:getValue(key .. ".nodes#baleRootNode", baleTypeDefinition.baleNode, self.components, self.i3dMappings)

		if baleTypeDefinition.baleRootNode ~= nil and baleTypeDefinition.baleNodeComponent == nil then
			baleTypeDefinition.baleNodeComponent = self:getParentComponent(baleTypeDefinition.baleRootNode)
		end

		if baleTypeDefinition.baleNode ~= nil then
			baleTypeDefinition.scaleNode = self.xmlFile:getValue(key .. ".nodes#scaleNode", nil, self.components, self.i3dMappings)
			baleTypeDefinition.scaleComponents = self.xmlFile:getValue(key .. ".nodes#scaleComponents", nil, true)
			baleTypeDefinition.animations = {
				fill = self.xmlFile:getValue(key .. ".animations#fillAnimation"),
				unloading = self.xmlFile:getValue(key .. ".animations#unloadAnimation"),
				unloadingSpeed = self.xmlFile:getValue(key .. ".animations#unloadAnimationSpeed", 1)
			}
			baleTypeDefinition.animations.dropAnimationTime = self.xmlFile:getValue(key .. ".animations#dropAnimationTime", self:getAnimationDuration(baleTypeDefinition.animations.unloading) / 1000)
			baleTypeDefinition.changeObjects = {}

			ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, key, baleTypeDefinition.changeObjects, self.components, self)
			table.insert(spec.baleTypes, baleTypeDefinition)

			spec.hasUnloadingAnimation = spec.hasUnloadingAnimation and baleTypeDefinition.animations.unloading ~= nil
		else
			Logging.xmlError(self.xmlFile, "Missing baleNode for bale type. '%s'", key)
		end
	end)

	local defaultBaleType = spec.baleTypes[defaultBaleTypeIndex]

	if defaultBaleType ~= nil then
		ObjectChangeUtil.setObjectChanges(defaultBaleType.changeObjects, true, self, self.setMovingToolDirty)
	end

	spec.changeBaleTypeText = self.xmlFile:getValue("vehicle.baleTypes#changeText", "action_changeBaleSize", self.customEnvironment)
	spec.preSelectedBaleTypeIndex = defaultBaleTypeIndex
	spec.currentBaleTypeIndex = defaultBaleTypeIndex
	spec.currentBaleXMLFilename = nil
	spec.currentBaleTypeDefinition = nil

	if #spec.baleTypes == 0 then
		Logging.xmlError(self.xmlFile, "No baleTypes definded for baler.")
	end

	if spec.hasUnloadingAnimation then
		spec.automaticDrop = self.xmlFile:getValue("vehicle.baler.automaticDrop#enabled", Platform.gameplay.automaticBaleDrop)
		spec.toggleableAutomaticDrop = self.xmlFile:getValue("vehicle.baler.automaticDrop#toggleable", not Platform.gameplay.automaticBaleDrop)
		spec.toggleAutomaticDropTextPos = self.xmlFile:getValue("vehicle.baler.automaticDrop#textPos", "action_toggleAutomaticBaleDropPos", self.customEnvironment)
		spec.toggleAutomaticDropTextNeg = self.xmlFile:getValue("vehicle.baler.automaticDrop#textNeg", "action_toggleAutomaticBaleDropNeg", self.customEnvironment)
		spec.baleCloseAnimationName = self.xmlFile:getValue("vehicle.baler.baleAnimation#closeAnimationName")
		spec.baleCloseAnimationSpeed = self.xmlFile:getValue("vehicle.baler.baleAnimation#closeAnimationSpeed", 1)
		local closeAnimation = self:getAnimationByName(spec.baleCloseAnimationName)

		if spec.baleCloseAnimationName == nil or closeAnimation == nil then
			Logging.xmlError(self.xmlFile, "Failed to find baler close animation. (%s)", "vehicle.baler.baleAnimation#closeAnimationName")
		else
			closeAnimation.resetOnStart = false
		end
	end

	spec.unfinishedBaleThreshold = self.xmlFile:getValue("vehicle.baler#unfinishedBaleThreshold", 2000)
	spec.canUnloadUnfinishedBale = self.xmlFile:getValue("vehicle.baler#canUnloadUnfinishedBale", false)
	spec.lastBaleFillLevel = nil

	if self.isClient then
		spec.samples = {
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baler.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			eject = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baler.sounds", "eject", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			door = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baler.sounds", "door", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			knotCleaning = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.baler.sounds", "knotCleaning", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.knotCleaningTimer = 10000
		spec.knotCleaningTime = 120000
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.baler.animationNodes", self.components, self, self.i3dMappings)
		spec.unloadAnimationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.baler.unloadAnimationNodes", self.components, self, self.i3dMappings)
		spec.fillEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.baler.fillEffect", self.components, self, self.i3dMappings)
		spec.fillEffectType = FillType.UNKNOWN
		spec.knotingAnimation = self.xmlFile:getValue("vehicle.baler.knotingAnimation#name")
		spec.knotingAnimationSpeed = self.xmlFile:getValue("vehicle.baler.knotingAnimation#speed", 1)
		spec.compactingAnimation = self.xmlFile:getValue("vehicle.baler.compactingAnimation#name")
		spec.compactingAnimationInterval = self.xmlFile:getValue("vehicle.baler.compactingAnimation#interval", 60) * 1000
		spec.compactingAnimationCompactTime = self.xmlFile:getValue("vehicle.baler.compactingAnimation#compactTime", 5) * 1000
		spec.compactingAnimationCompactTimer = spec.compactingAnimationCompactTime
		spec.compactingAnimationTime = spec.compactingAnimationInterval
		spec.compactingAnimationSpeed = self.xmlFile:getValue("vehicle.baler.compactingAnimation#speed", 1)
		spec.compactingAnimationMinTime = self.xmlFile:getValue("vehicle.baler.compactingAnimation#minFillLevelTime", 1)
		spec.compactingAnimationMaxTime = self.xmlFile:getValue("vehicle.baler.compactingAnimation#maxFillLevelTime", 0.1)
	end

	spec.lastAreaBiggerZero = false
	spec.lastAreaBiggerZeroSent = false
	spec.lastAreaBiggerZeroTime = 0
	spec.workAreaParameters = {
		lastPickedUpLiters = 0
	}
	spec.fillUnitOverflowFillLevel = 0
	spec.maxPickupLitersPerSecond = self.xmlFile:getValue("vehicle.baler#maxPickupLitersPerSecond", 500)
	spec.pickUpLitersBuffer = ValueBuffer.new(750)
	spec.unloadingState = Baler.UNLOADING_CLOSED
	spec.pickupFillTypes = {}
	spec.bales = {}
	spec.dummyBale = {
		currentBaleFillType = FillType.UNKNOWN,
		currentBale = nil,
		currentBaleLength = 0
	}
	spec.allowsBaleUnloading = self.xmlFile:getValue("vehicle.baler.baleUnloading#allowed", false)
	spec.baleUnloadingTime = self.xmlFile:getValue("vehicle.baler.baleUnloading#time", 4) * 1000
	spec.baleFoldThreshold = self.xmlFile:getValue("vehicle.baler.baleUnloading#foldThreshold", 0.25) * self:getFillUnitCapacity(spec.fillUnitIndex)
	spec.platformAnimation = self.xmlFile:getValue("vehicle.baler.platform#animationName")
	spec.platformAnimationNextBaleTime = self.xmlFile:getValue("vehicle.baler.platform#nextBaleTime", 0)
	spec.platformAutomaticDrop = self.xmlFile:getValue("vehicle.baler.platform#automaticDrop", Platform.gameplay.automaticBaleDrop)
	spec.platformAIDropSpeed = self.xmlFile:getValue("vehicle.baler.platform#aiSpeed", 3)
	spec.hasPlatform = spec.platformAnimation ~= nil
	spec.hasDynamicMountPlatform = SpecializationUtil.hasSpecialization(DynamicMountAttacher, self.specializations)

	if spec.hasPlatform then
		spec.automaticDrop = true
	end

	spec.platformReadyToDrop = false
	spec.platformDropInProgress = false
	spec.platformDelayedDropping = false
	spec.platformMountDelay = -1
	spec.buffer = {
		fillUnitIndex = self.xmlFile:getValue("vehicle.baler.buffer#fillUnitIndex"),
		capacityPercentage = self.xmlFile:getValue("vehicle.baler.buffer#capacityPercentage"),
		overloadingDuration = self.xmlFile:getValue("vehicle.baler.buffer#overloadingDuration", 1),
		fillMainUnitAfterOverload = self.xmlFile:getValue("vehicle.baler.buffer#fillMainUnitAfterOverload", false),
		unloadingStarted = false,
		fillLevelToEmpty = 0,
		dummyBale = {}
	}
	spec.buffer.dummyBale.available = self.xmlFile:hasProperty("vehicle.baler.buffer.dummyBale")
	spec.buffer.dummyBale.linkNode = self.xmlFile:getValue("vehicle.baler.buffer.dummyBale#node", nil, self.components, self.i3dMappings)
	spec.buffer.dummyBale.scaleComponents = self.xmlFile:getValue("vehicle.baler.buffer.dummyBale#scaleComponents", "1 1 0", true)
	spec.buffer.overloadAnimation = self.xmlFile:getValue("vehicle.baler.buffer.overloadAnimation#name")
	spec.buffer.overloadAnimationSpeed = self.xmlFile:getValue("vehicle.baler.buffer.overloadAnimation#speedScale", 1)
	spec.buffer.loadingStateAnimation = self.xmlFile:getValue("vehicle.baler.buffer.loadingStateAnimation#name")
	spec.buffer.loadingStateAnimationSpeed = self.xmlFile:getValue("vehicle.baler.buffer.loadingStateAnimation#speedScale", 1)
	spec.nonStopBaling = spec.buffer.fillUnitIndex ~= nil

	if spec.nonStopBaling ~= nil then
		local fillTypeName = self.xmlFile:getValue("vehicle.baler.buffer#balerDisplayType")
		local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)

		if fillTypeIndex ~= nil then
			self:setFillUnitFillTypeToDisplay(spec.fillUnitIndex, fillTypeIndex, true)
		end
	end

	spec.variableSpeedLimit = {
		enabled = self.xmlFile:hasProperty("vehicle.baler.variableSpeedLimit"),
		pickupPerSecond = 0,
		pickupPerSecondTimer = 0,
		targetLiterPerSecond = self.xmlFile:getValue("vehicle.baler.variableSpeedLimit#targetLiterPerSecond", 200),
		changeInterval = self.xmlFile:getValue("vehicle.baler.variableSpeedLimit#changeInterval", 1),
		minSpeedLimit = self.xmlFile:getValue("vehicle.baler.variableSpeedLimit#minSpeedLimit", 5),
		maxSpeedLimit = self.xmlFile:getValue("vehicle.baler.variableSpeedLimit#maxSpeedLimit", 15),
		defaultSpeedLimit = self.xmlFile:getValue("vehicle.baler.variableSpeedLimit#defaultSpeedLimit", 10),
		backupSpeedLimit = self.speedLimit,
		usedBackupSpeedLimit = false,
		lastAdjustedSpeedLimit = nil,
		lastAdjustedSpeedLimitType = nil,
		fillTypeToTargetLiterPerSecond = {}
	}

	self.xmlFile:iterate("vehicle.baler.variableSpeedLimit.target", function (index, key)
		local fillType = g_fillTypeManager:getFillTypeIndexByName(self.xmlFile:getValue(key .. "#fillType"))

		if fillType ~= nil then
			local targetLiterPerSecond = self.xmlFile:getValue(key .. "#targetLiterPerSecond", 200)
			local defaultSpeedLimit = self.xmlFile:getValue(key .. "#defaultSpeedLimit", 10)
			spec.variableSpeedLimit.fillTypeToTargetLiterPerSecond[fillType] = {
				targetLiterPerSecond = targetLiterPerSecond,
				defaultSpeedLimit = defaultSpeedLimit
			}
		end
	end)

	spec.isBaleUnloading = false
	spec.texts = {
		warningFoldingBaleLoaded = g_i18n:getText("warning_foldingNotWhileBaleLoaded"),
		warningFoldingTurnedOn = g_i18n:getText("warning_foldingNotWhileTurnedOn"),
		warningTooManyBales = g_i18n:getText("warning_tooManyBales"),
		unloadUnfinishedBale = g_i18n:getText("action_unloadUnfinishedBale"),
		unloadBaler = g_i18n:getText("action_unloadBaler"),
		closeBack = g_i18n:getText("action_closeBack")
	}
	spec.dirtyFlag = self:getNextDirtyFlag()

	if savegame ~= nil and not savegame.resetVehicles then
		local baleTypeIndex = savegame.xmlFile:getValue(savegame.key .. ".baler#baleTypeIndex", spec.currentBaleTypeIndex)

		self:setBaleTypeIndex(baleTypeIndex, true, true)

		local preSelectedBaleTypeIndex = savegame.xmlFile:getValue(savegame.key .. ".baler#preSelectedBaleTypeIndex", spec.preSelectedBaleTypeIndex)

		self:setBaleTypeIndex(preSelectedBaleTypeIndex, nil, true)

		local fillUnitCapacity = savegame.xmlFile:getValue(savegame.key .. ".baler#fillUnitCapacity")

		if fillUnitCapacity ~= nil then
			if fillUnitCapacity == 0 then
				fillUnitCapacity = math.huge
			end

			self:setFillUnitCapacity(spec.fillUnitIndex, fillUnitCapacity)

			if spec.buffer.capacityPercentage ~= nil then
				self:setFillUnitCapacity(spec.fillUnitIndex, fillUnitCapacity * spec.buffer.capacityPercentage, false)
			end
		end

		if spec.nonStopBaling then
			spec.buffer.unloadingStarted = savegame.xmlFile:getValue(savegame.key .. ".baler#bufferUnloadingStarted", spec.buffer.unloadingStarted)
		end
	end
end

function Baler:onPostLoad(savegame)
	local spec = self.spec_baler

	for fillTypeIndex, enabled in pairs(self:getFillUnitSupportedFillTypes(spec.fillUnitIndex)) do
		if enabled and fillTypeIndex ~= FillType.UNKNOWN then
			spec.pickupFillTypes[fillTypeIndex] = 0
		end
	end

	if savegame ~= nil and not savegame.resetVehicles then
		local numBales = savegame.xmlFile:getValue(savegame.key .. ".baler#numBales")

		if numBales ~= nil then
			spec.balesToLoad = {}

			for i = 1, numBales do
				local baleKey = string.format("%s.baler.bale(%d)", savegame.key, i - 1)
				local bale = {}
				local filename = savegame.xmlFile:getValue(baleKey .. "#filename")
				local fillTypeStr = savegame.xmlFile:getValue(baleKey .. "#fillType")
				local fillType = g_fillTypeManager:getFillTypeByName(fillTypeStr)

				if filename ~= nil and fillType ~= nil then
					bale.filename = filename
					bale.fillType = fillType.index
					bale.fillLevel = savegame.xmlFile:getValue(baleKey .. "#fillLevel")
					bale.baleTime = savegame.xmlFile:getValue(baleKey .. "#baleTime")

					table.insert(spec.balesToLoad, bale)
				end
			end
		end

		if spec.hasPlatform then
			spec.platformReadyToDrop = savegame.xmlFile:getValue(savegame.key .. ".baler#platformReadyToDrop", spec.platformReadyToDrop)

			if spec.platformReadyToDrop then
				self:setAnimationTime(spec.platformAnimation, 1, true)
				self:setAnimationTime(spec.platformAnimation, 0, true)

				spec.platformMountDelay = 1
			end
		end
	end
end

function Baler:onLoadFinished(savegame)
	local spec = self.spec_baler

	if self.isServer and spec.createBaleNextFrame ~= nil and spec.createBaleNextFrame then
		self:finishBale()

		spec.createBaleNextFrame = nil
	end

	if spec.balesToLoad ~= nil then
		for _, v in ipairs(spec.balesToLoad) do
			if self:createBale(v.fillType, v.fillLevel, nil, v.baleTime, v.filename) then
				self:setBaleTime(#spec.bales, v.baleTime, true)
			end
		end

		spec.balesToLoad = nil
	end
end

function Baler:onDelete()
	local spec = self.spec_baler

	if spec.bales ~= nil then
		if self.isReconfigurating == nil or not self.isReconfigurating then
			for k, _ in pairs(spec.bales) do
				self:dropBale(k)
			end
		else
			for _, bale in pairs(spec.bales) do
				if bale.baleObject ~= nil then
					bale.baleObject:delete()
				end
			end
		end
	end

	self:deleteDummyBale(spec.dummyBale)

	if spec.buffer.dummyBale.available then
		self:deleteDummyBale(spec.buffer.dummyBale)
	end

	g_soundManager:deleteSamples(spec.samples)
	g_effectManager:deleteEffects(spec.fillEffects)
	g_animationManager:deleteAnimations(spec.animationNodes)
	g_animationManager:deleteAnimations(spec.unloadAnimationNodes)
end

function Baler:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_baler

	if not spec.hasUnloadingAnimation or self:getFillUnitFreeCapacity(spec.fillUnitIndex) > 0 then
		xmlFile:setValue(key .. "#numBales", #spec.bales)

		for k, bale in ipairs(spec.bales) do
			local baleKey = string.format("%s.bale(%d)", key, k - 1)

			xmlFile:setValue(baleKey .. "#filename", bale.filename)

			local fillTypeStr = "UNKNOWN"

			if bale.fillType ~= FillType.UNKNOWN then
				fillTypeStr = g_fillTypeManager:getFillTypeNameByIndex(bale.fillType)
			end

			xmlFile:setValue(baleKey .. "#fillType", fillTypeStr)
			xmlFile:setValue(baleKey .. "#fillLevel", bale.fillLevel)

			if spec.baleAnimCurve ~= nil then
				xmlFile:setValue(baleKey .. "#baleTime", bale.time)
			end
		end
	end

	if spec.hasPlatform then
		xmlFile:setValue(key .. "#platformReadyToDrop", spec.platformReadyToDrop)
	end

	xmlFile:setValue(key .. "#baleTypeIndex", spec.currentBaleTypeIndex)
	xmlFile:setValue(key .. "#preSelectedBaleTypeIndex", spec.preSelectedBaleTypeIndex)
	xmlFile:setValue(key .. "#fillUnitCapacity", self:getFillUnitCapacity(spec.fillUnitIndex))

	if spec.nonStopBaling then
		xmlFile:setValue(key .. "#bufferUnloadingStarted", spec.buffer.unloadingStarted)
	end
end

function Baler:onReadStream(streamId, connection)
	local spec = self.spec_baler

	if spec.hasUnloadingAnimation then
		local state = streamReadUIntN(streamId, 7)
		local animTime = streamReadFloat32(streamId)

		if state == Baler.UNLOADING_CLOSED or state == Baler.UNLOADING_CLOSING then
			self:setIsUnloadingBale(false, true)
			self:setRealAnimationTime(spec.baleCloseAnimationName, animTime)
		elseif state == Baler.UNLOADING_OPEN or state == Baler.UNLOADING_OPENING then
			self:setIsUnloadingBale(true, true)
			self:setRealAnimationTime(spec.baleUnloadAnimationName, animTime)
		end
	end

	local numBales = streamReadUInt8(streamId)

	for i = 1, numBales do
		local fillType = streamReadIntN(streamId, FillTypeManager.SEND_NUM_BITS)
		local fillLevel = streamReadFloat32(streamId)

		self:createBale(fillType, fillLevel)

		if spec.baleAnimCurve ~= nil then
			local baleTime = streamReadFloat32(streamId)

			self:setBaleTime(i, baleTime)
		end
	end

	spec.lastAreaBiggerZero = streamReadBool(streamId)

	if spec.hasPlatform then
		spec.platformReadyToDrop = streamReadBool(streamId)

		if spec.platformReadyToDrop then
			self:setAnimationTime(spec.platformAnimation, 1, true)
			self:setAnimationTime(spec.platformAnimation, 0, true)
		end
	end

	spec.currentBaleTypeIndex = streamReadUIntN(streamId, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
	spec.preSelectedBaleTypeIndex = streamReadUIntN(streamId, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
end

function Baler:onWriteStream(streamId, connection)
	local spec = self.spec_baler

	if spec.hasUnloadingAnimation then
		streamWriteUIntN(streamId, spec.unloadingState, 7)

		local animTime = 0

		if spec.unloadingState == Baler.UNLOADING_CLOSED or spec.unloadingState == Baler.UNLOADING_CLOSING then
			animTime = self:getRealAnimationTime(spec.baleCloseAnimationName)
		elseif spec.unloadingState == Baler.UNLOADING_OPEN or spec.unloadingState == Baler.UNLOADING_OPENING then
			animTime = self:getRealAnimationTime(spec.baleUnloadAnimationName)
		end

		streamWriteFloat32(streamId, animTime)
	end

	streamWriteUInt8(streamId, #spec.bales)

	for i = 1, #spec.bales do
		local bale = spec.bales[i]

		streamWriteIntN(streamId, bale.fillType, FillTypeManager.SEND_NUM_BITS)
		streamWriteFloat32(streamId, bale.fillLevel)

		if spec.baleAnimCurve ~= nil then
			streamWriteFloat32(streamId, bale.time)
		end
	end

	streamWriteBool(streamId, spec.lastAreaBiggerZero)

	if spec.hasPlatform then
		streamWriteBool(streamId, spec.platformReadyToDrop)
	end

	streamWriteUIntN(streamId, spec.currentBaleTypeIndex, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
	streamWriteUIntN(streamId, spec.preSelectedBaleTypeIndex, BalerBaleTypeEvent.BALE_TYPE_SEND_NUM_BITS)
end

function Baler:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_baler

	if connection:getIsServer() and streamReadBool(streamId) then
		spec.lastAreaBiggerZero = streamReadBool(streamId)
		spec.fillEffectType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)
	end
end

function Baler:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_baler

	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
		streamWriteBool(streamId, spec.lastAreaBiggerZero)
		streamWriteUIntN(streamId, spec.fillEffectTypeSent, FillTypeManager.SEND_NUM_BITS)
	end
end

function Baler:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_baler

	if self.isClient and spec.baleToMount ~= nil then
		local baleObject = NetworkUtil.getObject(spec.baleToMount.baleServerId)

		if baleObject ~= nil then
			baleObject:mountKinematic(self, spec.baleToMount.jointNode, 0, 0, 0, 0, 0, 0)

			spec.baleToMount.baleInfo.baleObject = baleObject
			spec.baleToMount.baleInfo.baleServerId = spec.baleToMount.baleServerId
			spec.baleToMount = nil
		end
	end

	if self.isServer then
		if self.isAddedToPhysics and spec.createBaleNextFrame ~= nil and spec.createBaleNextFrame then
			self:finishBale()

			spec.createBaleNextFrame = nil
		end

		if spec.variableSpeedLimit.enabled then
			spec.variableSpeedLimit.pickupPerSecondTimer = spec.variableSpeedLimit.pickupPerSecondTimer + dt

			if spec.variableSpeedLimit.changeInterval < spec.variableSpeedLimit.pickupPerSecondTimer then
				local defaultSpeedLimit = spec.variableSpeedLimit.defaultSpeedLimit
				local targetLiterPerSecond = spec.variableSpeedLimit.targetLiterPerSecond
				local fillTypeIndex = self:getFillUnitFillType(spec.fillUnitIndex)

				if fillTypeIndex == FillType.UNKNOWN and spec.nonStopBaling then
					fillTypeIndex = self:getFillUnitFillType(spec.buffer.fillUnitIndex)
				end

				if fillTypeIndex ~= nil and spec.variableSpeedLimit.fillTypeToTargetLiterPerSecond[fillTypeIndex] ~= nil then
					local target = spec.variableSpeedLimit.fillTypeToTargetLiterPerSecond[fillTypeIndex]
					defaultSpeedLimit = target.defaultSpeedLimit
					targetLiterPerSecond = target.targetLiterPerSecond
				end

				local litersPerSecond = spec.variableSpeedLimit.pickupPerSecond / (spec.variableSpeedLimit.changeInterval / 1000)

				if litersPerSecond > 0 then
					if spec.variableSpeedLimit.usedBackupSpeedLimit then
						spec.variableSpeedLimit.usedBackupSpeedLimit = false
						self.speedLimit = spec.variableSpeedLimit.lastAdjustedSpeedLimit or defaultSpeedLimit

						if (spec.variableSpeedLimit.lastAdjustedSpeedLimitType or fillTypeIndex) ~= fillTypeIndex then
							self.speedLimit = defaultSpeedLimit
						end
					end

					local threshold = targetLiterPerSecond * 0.15
					local changeAmount = math.max(math.floor(litersPerSecond * 2 / targetLiterPerSecond), 1)

					if litersPerSecond > targetLiterPerSecond + threshold then
						self.speedLimit = math.max(self.speedLimit - changeAmount, spec.variableSpeedLimit.minSpeedLimit)
					elseif litersPerSecond < targetLiterPerSecond - threshold then
						self.speedLimit = math.min(self.speedLimit + changeAmount, spec.variableSpeedLimit.maxSpeedLimit)
					end

					spec.variableSpeedLimit.lastAdjustedSpeedLimit = self.speedLimit
					spec.variableSpeedLimit.lastAdjustedSpeedLimitType = fillTypeIndex
				else
					spec.variableSpeedLimit.usedBackupSpeedLimit = true
					self.speedLimit = spec.variableSpeedLimit.backupSpeedLimit
				end

				spec.variableSpeedLimit.pickupPerSecondTimer = 0
				spec.variableSpeedLimit.pickupPerSecond = 0
			end
		end
	end
end

function Baler:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_baler

	if self:getIsTurnedOn() then
		if self.isClient then
			if spec.lastAreaBiggerZero and spec.fillEffectType ~= FillType.UNKNOWN then
				spec.lastAreaBiggerZeroTime = 500
			elseif spec.lastAreaBiggerZeroTime > 0 then
				spec.lastAreaBiggerZeroTime = math.max(spec.lastAreaBiggerZeroTime - dt, 0)
			end

			if spec.lastAreaBiggerZeroTime > 0 then
				if spec.fillEffectType ~= FillType.UNKNOWN then
					g_effectManager:setFillType(spec.fillEffects, spec.fillEffectType)
				end

				g_effectManager:startEffects(spec.fillEffects)

				local loadPercentage = spec.pickUpLitersBuffer:get(1000) / spec.maxPickupLitersPerSecond

				g_effectManager:setDensity(spec.fillEffects, math.max(loadPercentage, 0.4))
			else
				g_effectManager:stopEffects(spec.fillEffects)
			end

			if spec.knotCleaningTimer <= g_currentMission.time then
				g_soundManager:playSample(spec.samples.knotCleaning)

				spec.knotCleaningTimer = g_currentMission.time + spec.knotCleaningTime
			end

			if spec.compactingAnimation ~= nil and spec.unloadingState == Baler.UNLOADING_CLOSED then
				if spec.compactingAnimationTime <= g_currentMission.time then
					local fillLevel = self:getFillUnitFillLevelPercentage(spec.fillUnitIndex)
					local stopTime = MathUtil.lerp(spec.compactingAnimationMinTime, spec.compactingAnimationMaxTime, fillLevel)

					if stopTime > 0 then
						self:setAnimationStopTime(spec.compactingAnimation, MathUtil.clamp(stopTime, 0, 1))
						self:playAnimation(spec.compactingAnimation, spec.compactingAnimationSpeed, self:getAnimationTime(spec.compactingAnimation), false)

						spec.compactingAnimationTime = math.huge
					end
				end

				if spec.compactingAnimationTime == math.huge and not self:getIsAnimationPlaying(spec.compactingAnimation) then
					spec.compactingAnimationCompactTimer = spec.compactingAnimationCompactTimer - dt

					if spec.compactingAnimationCompactTimer < 0 then
						self:playAnimation(spec.compactingAnimation, -spec.compactingAnimationSpeed, self:getAnimationTime(spec.compactingAnimation), false)

						spec.compactingAnimationCompactTimer = spec.compactingAnimationCompactTime
					end

					if self:getAnimationTime(spec.compactingAnimation) == 0 then
						spec.compactingAnimationTime = g_currentMission.time + spec.compactingAnimationInterval
					end
				end
			end
		end
	elseif spec.isBaleUnloading and self.isServer then
		local deltaTime = dt / spec.baleUnloadingTime

		self:moveBales(deltaTime)
	end

	if self.isClient and spec.unloadingState == Baler.UNLOADING_OPEN then
		local baleTypeDef = spec.baleTypes[spec.currentBaleTypeIndex]

		if getNumOfChildren(baleTypeDef.baleNode) > 0 then
			delete(getChildAt(baleTypeDef.baleNode, 0))
		end
	end

	if spec.unloadingState == Baler.UNLOADING_OPENING then
		local baleTypeDef = spec.baleTypes[spec.currentBaleTypeIndex]
		local isPlaying = self:getIsAnimationPlaying(baleTypeDef.animations.unloading)
		local animTime = self:getRealAnimationTime(baleTypeDef.animations.unloading)

		if not isPlaying or baleTypeDef.animations.dropAnimationTime <= animTime then
			if #spec.bales > 0 then
				self:dropBale(1)

				if self.isServer then
					self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, self:getFillUnitFillType(spec.fillUnitIndex), ToolType.UNDEFINED)

					spec.buffer.unloadingStarted = false

					for fillType, _ in pairs(spec.pickupFillTypes) do
						spec.pickupFillTypes[fillType] = 0
					end

					if self:getFillUnitFillLevel(spec.fillUnitIndex) == 0 and spec.preSelectedBaleTypeIndex ~= spec.currentBaleTypeIndex then
						self:setBaleTypeIndex(spec.preSelectedBaleTypeIndex)
					end
				end
			end

			if not isPlaying then
				spec.unloadingState = Baler.UNLOADING_OPEN

				if self.isClient then
					g_soundManager:stopSample(spec.samples.eject)
					g_soundManager:stopSample(spec.samples.door)
					g_animationManager:stopAnimations(spec.unloadAnimationNodes)
				end
			end
		else
			g_animationManager:startAnimations(spec.unloadAnimationNodes)
		end
	elseif spec.unloadingState == Baler.UNLOADING_CLOSING and not self:getIsAnimationPlaying(spec.baleCloseAnimationName) then
		spec.unloadingState = Baler.UNLOADING_CLOSED

		if self.isClient then
			g_soundManager:stopSample(spec.samples.door)
		end
	end

	if (spec.unloadingState == Baler.UNLOADING_OPEN or spec.unloadingState == Baler.UNLOADING_CLOSING) and not self.isServer and #spec.bales > 0 then
		self:dropBale(1)
	end

	Baler.updateActionEvents(self)

	if self.isServer then
		if spec.automaticDrop ~= nil and spec.automaticDrop or self:getIsAIActive() then
			if self:isUnloadingAllowed() and (spec.hasUnloadingAnimation or spec.allowsBaleUnloading) and spec.unloadingState == Baler.UNLOADING_CLOSED and #spec.bales > 0 then
				self:setIsUnloadingBale(true)
			end

			if spec.hasUnloadingAnimation and spec.unloadingState == Baler.UNLOADING_OPEN then
				self:setIsUnloadingBale(false)
			end
		end

		spec.pickUpLitersBuffer:add(spec.workAreaParameters.lastPickedUpLiters)

		if spec.platformAutomaticDrop and spec.platformReadyToDrop then
			self:dropBaleFromPlatform(true)
		end

		if spec.hasPlatform then
			if #spec.bales > 0 and spec.platformReadyToDrop then
				self:dropBaleFromPlatform(true)
			end

			if spec.hasDynamicMountPlatform then
				if spec.platformMountDelay > 0 then
					spec.platformMountDelay = spec.platformMountDelay - 1

					if spec.platformMountDelay == 0 then
						self:forceDynamicMountPendingObjects(true)
					end
				elseif spec.platformReadyToDrop and not self:getHasDynamicMountedObjects() then
					self:dropBaleFromPlatform(false)
				end
			end
		end

		if spec.nonStopBaling then
			local bufferLevel = self:getFillUnitFillLevel(spec.buffer.fillUnitIndex)

			if bufferLevel > 0 then
				if bufferLevel == self:getFillUnitCapacity(spec.buffer.fillUnitIndex) then
					local capacity = self:getFillUnitCapacity(spec.fillUnitIndex)

					if (capacity == 0 or capacity == math.huge or self:getFillUnitFreeCapacity(spec.fillUnitIndex) > 0) and not spec.buffer.unloadingStarted and spec.unloadingState == Baler.UNLOADING_CLOSED then
						spec.buffer.unloadingStarted = true

						if spec.buffer.overloadAnimation ~= nil then
							self:playAnimation(spec.buffer.overloadAnimation, spec.buffer.overloadAnimationSpeed)
						end
					end
				end

				if spec.buffer.unloadingStarted then
					if self:getFillUnitFreeCapacity(spec.fillUnitIndex) > 0 then
						local capacity = self:getFillUnitCapacity(spec.buffer.fillUnitIndex)
						local delta = math.min(capacity / spec.buffer.overloadingDuration * dt, bufferLevel)
						local fillType = self:getFillUnitFillType(spec.buffer.fillUnitIndex)
						local realDelta = self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.buffer.fillUnitIndex, -delta, fillType, ToolType.UNDEFINED, nil)

						self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -realDelta, fillType, ToolType.UNDEFINED, nil)

						if spec.buffer.fillLevelToEmpty > 0 then
							spec.buffer.fillLevelToEmpty = math.max(spec.buffer.fillLevelToEmpty - delta, 0)

							if spec.buffer.fillLevelToEmpty == 0 then
								spec.platformDelayedDropping = true
								spec.buffer.unloadingStarted = false
							end
						end
					end

					if self:getFillUnitFillLevelPercentage(spec.fillUnitIndex) == 1 then
						spec.buffer.unloadingStarted = false
					end
				end
			elseif not spec.buffer.fillMainUnitAfterOverload then
				spec.buffer.unloadingStarted = false
			end

			if spec.buffer.overloadAnimation ~= nil and not self:getIsAnimationPlaying(spec.buffer.overloadAnimation) and self:getAnimationTime(spec.buffer.overloadAnimation) > 0.5 then
				self:playAnimation(spec.buffer.overloadAnimation, -spec.buffer.overloadAnimationSpeed)
			end
		end
	end

	if spec.hasPlatform then
		if spec.platformDelayedDropping and not spec.platformDropInProgress then
			Baler.actionEventUnloading(self)

			spec.platformDelayedDropping = false
		end

		if spec.platformDropInProgress and not self:getIsAnimationPlaying(spec.platformAnimation) then
			spec.platformDropInProgress = false
		end
	end
end

function Baler:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_baler

	if #spec.bales > 0 and spec.baleFoldThreshold < self:getFillUnitFillLevel(spec.fillUnitIndex) then
		return false, spec.texts.warningFoldingBaleLoaded
	end

	if #spec.bales > 1 then
		return false, spec.texts.warningFoldingBaleLoaded
	end

	if self:getIsTurnedOn() then
		return false, spec.texts.warningFoldingTurnedOn
	end

	if spec.hasPlatform and (spec.platformReadyToDrop or spec.platformDropInProgress) then
		return false, spec.texts.warningFoldingBaleLoaded
	end

	return superFunc(self, direction, onAiTurnOn)
end

function Baler:onDeactivate()
	local spec = self.spec_baler

	if self.isClient then
		g_effectManager:stopEffects(spec.fillEffects)
		g_soundManager:stopSamples(spec.samples)
	end
end

function Baler:onChangedFillType(fillUnitIndex, fillTypeIndex, oldFillTypeIndex)
	local spec = self.spec_baler

	if (fillUnitIndex == spec.fillUnitIndex or fillUnitIndex == spec.buffer.fillUnitIndex) and fillTypeIndex ~= FillType.UNKNOWN then
		local baleTypeDef = spec.baleTypes[spec.currentBaleTypeIndex]
		spec.currentBaleTypeDefinition = baleTypeDef
		spec.currentBaleXMLFilename, spec.currentBaleIndex = g_baleManager:getBaleXMLFilename(fillTypeIndex, baleTypeDef.isRoundBale, baleTypeDef.width, baleTypeDef.height, baleTypeDef.length, baleTypeDef.diameter, self.customEnvironment)
		local baleCapacity = g_baleManager:getBaleCapacityByBaleIndex(spec.currentBaleIndex, fillTypeIndex)

		if fillUnitIndex == spec.fillUnitIndex then
			self:setFillUnitCapacity(fillUnitIndex, baleCapacity, false)
		elseif spec.buffer.capacityPercentage ~= nil then
			self:setFillUnitCapacity(fillUnitIndex, baleCapacity * spec.buffer.capacityPercentage, false)
		end

		ObjectChangeUtil.setObjectChanges(baleTypeDef.changeObjects, true, self, self.setMovingToolDirty)

		if spec.currentBaleXMLFilename == nil then
			Logging.warning("Could not find bale for given bale type definition '%s'", baleTypeDef.index)
		end
	end
end

function Baler:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_baler

	if fillUnitIndex == spec.fillUnitIndex then
		local baleTypeDef = spec.baleTypes[spec.currentBaleTypeIndex]
		local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)
		local capacity = self:getFillUnitCapacity(spec.fillUnitIndex)

		if self:updateDummyBale(spec.dummyBale, fillTypeIndex, fillLevel, capacity) then
			for i = 1, #spec.baleTypes do
				self:setAnimationTime(spec.baleTypes[i].animations.fill, 0)
			end
		end

		if fillLevel > 0 then
			self:setAnimationTime(baleTypeDef.animations.fill, fillLevel / capacity)
		end

		if self.isServer and fillLevelDelta > 0 then
			if self:getFillUnitFreeCapacity(spec.fillUnitIndex) <= 0 then
				if self.isAddedToPhysics then
					self:finishBale()
				else
					spec.createBaleNextFrame = true
				end

				spec.fillUnitOverflowFillLevel = fillLevelDelta - appliedDelta
			elseif spec.fillUnitOverflowFillLevel > 0 and fillLevelDelta > 0 then
				local overflow = spec.fillUnitOverflowFillLevel
				spec.fillUnitOverflowFillLevel = 0
				overflow = overflow - self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, overflow, fillTypeIndex, toolType)
				spec.fillUnitOverflowFillLevel = overflow
			end
		end
	elseif spec.nonStopBaling and fillUnitIndex == spec.buffer.fillUnitIndex and spec.buffer.dummyBale.available then
		local fillLevel = self:getFillUnitFillLevel(spec.buffer.fillUnitIndex)
		local capacity = self:getFillUnitCapacity(spec.buffer.fillUnitIndex)

		if spec.buffer.overloadAnimation ~= nil and self:getAnimationTime(spec.buffer.overloadAnimation) > 0 and fillLevel > 0 then
			return
		end

		self:updateDummyBale(spec.buffer.dummyBale, fillTypeIndex, fillLevel, capacity)
	end
end

function Baler:onTurnedOn()
	if self.setFoldState ~= nil then
		self:setFoldState(-1, false)
	end

	if self.isClient then
		local spec = self.spec_baler

		g_animationManager:startAnimations(spec.animationNodes)
		g_soundManager:playSample(spec.samples.work)
	end
end

function Baler:onTurnedOff()
	if self.isClient then
		local spec = self.spec_baler

		g_effectManager:stopEffects(spec.fillEffects)
		g_animationManager:stopAnimations(spec.animationNodes)
		g_soundManager:stopSamples(spec.samples)
	end
end

function Baler:onRootVehicleChanged(rootVehicle)
	local spec = self.spec_baler
	local actionController = rootVehicle.actionController

	if actionController ~= nil then
		if spec.controlledAction ~= nil then
			spec.controlledAction:updateParent(actionController)

			return
		end

		spec.controlledAction = actionController:registerAction("baleUnload", nil, 1)

		spec.controlledAction:setCallback(self, Baler.actionControllerBaleUnloadEvent)
		spec.controlledAction:setFinishedFunctions(self, Baler.getIsBaleUnloading, false, false)
	elseif spec.controlledAction ~= nil then
		spec.controlledAction:remove()
	end
end

function Baler:actionControllerBaleUnloadEvent(direction)
	if direction < 0 then
		local spec = self.spec_baler

		if self:isUnloadingAllowed() and spec.allowsBaleUnloading and spec.unloadingState == Baler.UNLOADING_CLOSED and #spec.bales > 0 then
			self:setIsUnloadingBale(true)
		end
	end
end

function Baler:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsTurnedOn() and self:getIsLowered()
end

function Baler:setBaleTypeIndex(baleTypeIndex, force, noEventSend)
	local spec = self.spec_baler
	spec.preSelectedBaleTypeIndex = baleTypeIndex

	if self:getFillUnitFillLevel(spec.fillUnitIndex) == 0 or force then
		spec.currentBaleTypeIndex = baleTypeIndex
	end

	Baler.updateActionEvents(self)
	BalerBaleTypeEvent.sendEvent(self, baleTypeIndex, noEventSend)
end

function Baler:isUnloadingAllowed()
	local spec = self.spec_baler

	if (spec.platformReadyToDrop or spec.platformDropInProgress) and spec.unloadingState ~= Baler.UNLOADING_OPEN then
		return false
	end

	if self.spec_baleWrapper == nil then
		return not spec.allowsBaleUnloading or spec.allowsBaleUnloading and not self:getIsTurnedOn() and not spec.isBaleUnloading
	end

	return self:allowsGrabbingBale()
end

function Baler:handleUnloadingBaleEvent()
	local spec = self.spec_baler

	if self:isUnloadingAllowed() and (spec.hasUnloadingAnimation or spec.allowsBaleUnloading) then
		if spec.unloadingState == Baler.UNLOADING_CLOSED then
			if #spec.bales > 0 or self:getCanUnloadUnfinishedBale() then
				self:setIsUnloadingBale(true)
			end
		elseif spec.unloadingState == Baler.UNLOADING_OPEN and spec.hasUnloadingAnimation then
			self:setIsUnloadingBale(false)
		end
	end
end

function Baler:dropBaleFromPlatform(waitForNextBale, noEventSend)
	local spec = self.spec_baler

	if spec.platformReadyToDrop then
		self:setAnimationTime(spec.platformAnimation, 0, false)
		self:playAnimation(spec.platformAnimation, 1, self:getAnimationTime(spec.platformAnimation), true)

		if waitForNextBale == true then
			self:setAnimationStopTime(spec.platformAnimation, spec.platformAnimationNextBaleTime)
		end

		spec.platformReadyToDrop = false
		spec.platformDropInProgress = true

		if self.isServer and spec.hasDynamicMountPlatform then
			self:forceUnmountDynamicMountedObjects()
		end
	end

	BalerDropFromPlatformEvent.sendEvent(self, waitForNextBale, noEventSend)
end

function Baler:setIsUnloadingBale(isUnloadingBale, noEventSend)
	local spec = self.spec_baler

	if spec.hasUnloadingAnimation then
		if isUnloadingBale then
			if spec.unloadingState ~= Baler.UNLOADING_OPENING then
				if #spec.bales == 0 and spec.canUnloadUnfinishedBale and spec.unfinishedBaleThreshold < self:getFillUnitFillLevel(spec.fillUnitIndex) then
					local fillTypeIndex = self:getFillUnitFillType(spec.fillUnitIndex)
					local currentFillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)
					local delta = self:getFillUnitFreeCapacity(spec.fillUnitIndex)
					spec.lastBaleFillLevel = currentFillLevel

					self:setFillUnitFillLevelToDisplay(spec.fillUnitIndex, currentFillLevel)
					self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, delta, fillTypeIndex, ToolType.UNDEFINED)

					spec.buffer.unloadingStarted = false
				end

				BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)

				spec.unloadingState = Baler.UNLOADING_OPENING

				if self.isClient then
					g_soundManager:playSample(spec.samples.eject)
					g_soundManager:playSample(spec.samples.door)
				end

				local baleTypeDef = spec.baleTypes[spec.currentBaleTypeIndex]

				self:playAnimation(baleTypeDef.animations.unloading, baleTypeDef.animations.unloadingSpeed, nil, true)
			end
		elseif spec.unloadingState ~= Baler.UNLOADING_CLOSING and spec.unloadingState ~= Baler.UNLOADING_CLOSED then
			BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)

			spec.unloadingState = Baler.UNLOADING_CLOSING

			if self.isClient then
				g_soundManager:playSample(spec.samples.door)
			end

			self:playAnimation(spec.baleCloseAnimationName, spec.baleCloseAnimationSpeed, nil, true)
		end
	elseif spec.allowsBaleUnloading and isUnloadingBale then
		BalerSetIsUnloadingBaleEvent.sendEvent(self, isUnloadingBale, noEventSend)

		spec.isBaleUnloading = true
	end
end

function Baler:getIsBaleUnloading()
	return self.spec_baler.isBaleUnloading
end

function Baler:getTimeFromLevel(level)
	local spec = self.spec_baler

	if spec.currentBaleTypeDefinition ~= nil then
		local baleLength = spec.currentBaleTypeDefinition.length + spec.baleAnimSpacing

		return level / self:getFillUnitCapacity(spec.fillUnitIndex) * baleLength / spec.baleAnimLength
	end

	return 0
end

function Baler:moveBales(dt)
	local spec = self.spec_baler

	for i = #spec.bales, 1, -1 do
		self:moveBale(i, dt)
	end
end

function Baler:moveBale(i, dt, noEventSend)
	local spec = self.spec_baler
	local bale = spec.bales[i]

	self:setBaleTime(i, bale.time + dt, noEventSend)
end

function Baler:setBaleTime(i, baleTime, noEventSend)
	local spec = self.spec_baler

	if spec.baleAnimCurve ~= nil then
		local bale = spec.bales[i]

		if bale ~= nil then
			bale.time = baleTime

			if self.isServer then
				local v = spec.baleAnimCurve:get(bale.time)

				setTranslation(bale.baleJointNode, v[1], v[2], v[3])
				setRotation(bale.baleJointNode, v[4], v[5], v[6])

				if bale.baleJointIndex ~= 0 then
					setJointFrame(bale.baleJointIndex, 0, bale.baleJointNode)
				end
			end

			if bale.time >= 1 then
				self:dropBale(i)
			end

			if #spec.bales == 0 then
				spec.isBaleUnloading = false
			end

			if self.isServer and (noEventSend == nil or not noEventSend) then
				g_server:broadcastEvent(BalerSetBaleTimeEvent.new(self, i, bale.time), nil, , self)
			end
		end
	end
end

function Baler:finishBale()
	local spec = self.spec_baler

	if spec.baleTypes ~= nil then
		local fillTypeIndex = self:getFillUnitFillType(spec.fillUnitIndex)

		if not spec.hasUnloadingAnimation then
			self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, fillTypeIndex, ToolType.UNDEFINED)

			spec.buffer.unloadingStarted = false

			for fillType, _ in pairs(spec.pickupFillTypes) do
				spec.pickupFillTypes[fillType] = 0
			end

			if self:createBale(fillTypeIndex, self:getFillUnitCapacity(spec.fillUnitIndex)) then
				local bale = spec.bales[#spec.bales]

				g_server:broadcastEvent(BalerCreateBaleEvent.new(self, fillTypeIndex, bale.time), nil, , self)

				if self:getFillUnitFillLevel(spec.fillUnitIndex) == 0 and spec.preSelectedBaleTypeIndex ~= spec.currentBaleTypeIndex then
					self:setBaleTypeIndex(spec.preSelectedBaleTypeIndex)
				end
			else
				Logging.error("Failed to create bale!")
			end
		elseif self:createBale(fillTypeIndex, self:getFillUnitCapacity(spec.fillUnitIndex)) then
			local bale = spec.bales[#spec.bales]

			g_server:broadcastEvent(BalerCreateBaleEvent.new(self, fillTypeIndex, 0, NetworkUtil.getObjectId(bale.baleObject)), nil, , self)
		else
			Logging.error("Failed to create bale!")
		end
	end
end

function Baler:createBale(baleFillType, fillLevel, baleServerId, baleTime, xmlFilename)
	local spec = self.spec_baler

	if spec.knotingAnimation ~= nil then
		self:playAnimation(spec.knotingAnimation, spec.knotingAnimationSpeed, nil, true)
	end

	local isValid = false
	local baleTypeDef = spec.baleTypes[spec.currentBaleTypeIndex]

	if baleTime == nil then
		self:deleteDummyBale(spec.dummyBale)
	end

	local bale = {
		filename = xmlFilename or spec.currentBaleXMLFilename,
		time = baleTime
	}

	if bale.time == nil and spec.baleAnimLength ~= nil then
		bale.time = baleTypeDef.length * 0.5 / spec.baleAnimLength
	end

	bale.fillType = baleFillType
	bale.fillLevel = fillLevel

	if spec.hasUnloadingAnimation then
		if self.isServer then
			local baleObject = Bale.new(self.isServer, self.isClient)
			local x, y, z = getWorldTranslation(baleTypeDef.baleRootNode)
			local rx, ry, rz = getWorldRotation(baleTypeDef.baleRootNode)

			if baleObject:loadFromConfigXML(bale.filename, x, y, z, rx, ry, rz) then
				baleObject:setFillType(baleFillType)
				baleObject:setFillLevel(fillLevel)

				local ownerFarmId = self:getLastTouchedFarmlandFarmId()

				if ownerFarmId == FarmManager.SPECTATOR_FARM_ID then
					ownerFarmId = self:getOwnerFarmId()
				end

				baleObject:setOwnerFarmId(ownerFarmId, true)
				baleObject:setIsMissionBale(self:getLastActiveMissionWork())
				baleObject:register()
				baleObject:mountKinematic(self, baleTypeDef.baleRootNode, 0, 0, 0, 0, 0, 0)

				bale.baleObject = baleObject
				isValid = true
			end
		elseif baleServerId ~= nil then
			local baleObject = NetworkUtil.getObject(baleServerId)

			if baleObject ~= nil then
				bale.baleServerId = baleServerId

				baleObject:mountKinematic(self, baleTypeDef.baleRootNode, 0, 0, 0, 0, 0, 0)
			else
				spec.baleToMount = {
					baleServerId = baleServerId,
					jointNode = baleTypeDef.baleRootNode,
					baleInfo = bale
				}
			end

			isValid = true
		end
	end

	if self.isServer and not spec.hasUnloadingAnimation then
		local x, y, z = getWorldTranslation(baleTypeDef.baleRootNode)
		local rx, ry, rz = getWorldRotation(baleTypeDef.baleRootNode)
		local baleJointNode = createTransformGroup("BaleJointTG")

		link(baleTypeDef.baleRootNode, baleJointNode)

		if bale.time ~= nil then
			local v = spec.baleAnimCurve:get(bale.time)

			setTranslation(baleJointNode, v[1], v[2], v[3])
			setRotation(baleJointNode, v[4], v[5], v[6])

			x, y, z = localToWorld(baleTypeDef.baleRootNode, v[1], v[2], v[3])
			rx, ry, rz = localRotationToWorld(baleTypeDef.baleRootNode, v[4], v[5], v[6])
		else
			setTranslation(baleJointNode, 0, 0, 0)
			setRotation(baleJointNode, 0, 0, 0)
		end

		local baleObject = Bale.new(self.isServer, self.isClient)

		if baleObject:loadFromConfigXML(bale.filename, x, y, z, rx, ry, rz) then
			baleObject:setFillType(baleFillType)
			baleObject:setFillLevel(fillLevel)

			local ownerFarmId = self:getLastTouchedFarmlandFarmId()

			if ownerFarmId == FarmManager.SPECTATOR_FARM_ID then
				ownerFarmId = self:getOwnerFarmId()
			end

			baleObject:setOwnerFarmId(ownerFarmId, true)
			baleObject:setIsMissionBale(self:getLastActiveMissionWork())
			baleObject:register()
			baleObject:setCanBeSold(false)

			local constr = JointConstructor.new()

			constr:setActors(baleTypeDef.baleNodeComponent, baleObject.nodeId)
			constr:setJointTransforms(baleJointNode, baleObject.nodeId)

			for i = 1, 3 do
				constr:setRotationLimit(i - 1, 0, 0)
				constr:setTranslationLimit(i - 1, true, 0, 0)
			end

			constr:setEnableCollision(false)

			local baleJointIndex = constr:finalize()

			g_currentMission.itemSystem:removeItemToSave(baleObject)

			bale.baleJointNode = baleJointNode
			bale.baleJointIndex = baleJointIndex
			bale.baleObject = baleObject

			for i = 1, #spec.bales do
				local otherBale = spec.bales[i]

				setPairCollision(otherBale.baleObject.nodeId, baleObject.nodeId, false)
			end

			isValid = true
		end
	elseif not self.isServer and not spec.hasUnloadingAnimation then
		isValid = true
	end

	if isValid then
		table.insert(spec.bales, bale)
	end

	return isValid
end

function Baler:dropBale(baleIndex)
	local spec = self.spec_baler
	local bale = spec.bales[baleIndex]

	if self.isServer then
		local baleObject = bale.baleObject

		if bale.baleJointIndex ~= nil then
			removeJoint(bale.baleJointIndex)
			delete(bale.baleJointNode)
			g_currentMission.itemSystem:addItemToSave(bale.baleObject)
		else
			baleObject:unmountKinematic()
		end

		for i = 1, #spec.bales do
			if i ~= baleIndex then
				local otherBale = spec.bales[i]

				setPairCollision(otherBale.baleObject.nodeId, baleObject.nodeId, true)
			end
		end

		if spec.lastBaleFillLevel ~= nil and #spec.bales == 1 then
			baleObject:setFillLevel(spec.lastBaleFillLevel)

			spec.lastBaleFillLevel = nil
		end

		baleObject:setCanBeSold(true)

		if baleObject.nodeId ~= nil and baleObject.nodeId ~= 0 then
			local baleTypeDef = spec.baleTypes[spec.currentBaleTypeIndex]
			local x, y, z = getWorldTranslation(baleObject.nodeId)
			local vx, vy, vz = getVelocityAtWorldPos(baleTypeDef.baleNodeComponent or self.components[1].node, x, y, z)

			setLinearVelocity(baleObject.nodeId, vx, vy, vz)
		end

		g_farmManager:updateFarmStats(self:getLastTouchedFarmlandFarmId(), "baleCount", 1)
	elseif spec.hasUnloadingAnimation then
		local baleObject = NetworkUtil.getObject(bale.baleServerId)

		if baleObject ~= nil then
			baleObject:unmountKinematic()
		end
	end

	table.remove(spec.bales, baleIndex)

	if spec.hasPlatform then
		if not spec.platformReadyToDrop then
			spec.platformReadyToDrop = true
		end

		if spec.hasDynamicMountPlatform then
			spec.platformMountDelay = 5
		end
	end
end

function Baler:updateDummyBale(dummyBaleData, fillTypeIndex, fillLevel, capacity)
	local spec = self.spec_baler
	local baleTypeDef = dummyBaleData.baleTypeDef or spec.baleTypes[spec.currentBaleTypeIndex]
	local generatedBale = false
	local baleNode = dummyBaleData.linkNode or baleTypeDef.baleNode

	if baleNode ~= nil and fillLevel > 0 and fillLevel < capacity and (dummyBaleData.currentBale == nil or dummyBaleData.currentBaleFillType ~= fillTypeIndex) then
		if dummyBaleData.currentBale ~= nil then
			self:deleteDummyBale(dummyBaleData)
		end

		self:createDummyBale(dummyBaleData, fillTypeIndex)

		generatedBale = true
	end

	if dummyBaleData.currentBale ~= nil then
		local scaleNode = dummyBaleData.linkNode or baleTypeDef.scaleNode

		if scaleNode ~= nil then
			local percentage = fillLevel / capacity
			local x = 1
			local y = baleTypeDef.isRoundBale and percentage or 1
			local z = percentage
			local scaleComponents = dummyBaleData.scaleComponents or baleTypeDef.scaleComponents

			if scaleComponents ~= nil then
				z = 1
				y = 1
				x = 1

				for axis, value in ipairs(scaleComponents) do
					if value > 0 then
						if axis == 1 then
							x = percentage * value
						elseif axis == 2 then
							y = percentage * value
						else
							z = percentage * value
						end
					end
				end
			end

			setScale(scaleNode, x, y, z)
		end
	end

	return generatedBale
end

function Baler:deleteDummyBale(dummyBaleData)
	if dummyBaleData ~= nil then
		if dummyBaleData.currentBale ~= nil then
			delete(dummyBaleData.currentBale)

			dummyBaleData.currentBale = nil
		end

		if dummyBaleData.sharedLoadRequestId ~= nil then
			g_i3DManager:releaseSharedI3DFile(dummyBaleData.sharedLoadRequestId)

			dummyBaleData.sharedLoadRequestId = nil
		end
	end
end

function Baler:createDummyBale(dummyBaleData, fillTypeIndex)
	local spec = self.spec_baler

	if spec.currentBaleXMLFilename ~= nil then
		local baleId, sharedLoadRequestId = Bale.createDummyBale(spec.currentBaleXMLFilename, fillTypeIndex)
		local baleTypeDef = spec.baleTypes[spec.currentBaleTypeIndex]
		local linkNode = dummyBaleData.linkNode or baleTypeDef.baleNode

		link(linkNode, baleId)

		dummyBaleData.currentBale = baleId
		dummyBaleData.baleTypeDef = baleTypeDef
		dummyBaleData.currentBaleFillType = fillTypeIndex
		dummyBaleData.sharedLoadRequestId = sharedLoadRequestId
	end
end

function Baler:getCanUnloadUnfinishedBale()
	local spec = self.spec_baler

	return spec.canUnloadUnfinishedBale and spec.unfinishedBaleThreshold < self:getFillUnitFillLevel(spec.fillUnitIndex)
end

function Baler:setBalerAutomaticDrop(state, noEventSend)
	local spec = self.spec_baler

	if state == nil then
		if spec.hasPlatform then
			state = not spec.platformAutomaticDrop
		else
			state = not spec.automaticDrop
		end
	end

	if spec.hasPlatform then
		spec.platformAutomaticDrop = state
	else
		spec.automaticDrop = state
	end

	self:requestActionEventUpdate()
	BalerAutomaticDropEvent.sendEvent(self, state, noEventSend)
end

function Baler:getCanBeTurnedOn(superFunc)
	local spec = self.spec_baler

	if spec.isBaleUnloading then
		return false
	end

	return superFunc(self)
end

function Baler:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	speedRotatingPart.rotateOnlyIfFillLevelIncreased = xmlFile:getValue(key .. "#rotateOnlyIfFillLevelIncreased", false)

	return superFunc(self, speedRotatingPart, xmlFile, key)
end

function Baler:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	local spec = self.spec_baler

	if speedRotatingPart.rotateOnlyIfFillLevelIncreased ~= nil and speedRotatingPart.rotateOnlyIfFillLevelIncreased and spec.lastAreaBiggerZeroTime == 0 then
		return false
	end

	return superFunc(self, speedRotatingPart)
end

function Baler.getDefaultSpeedLimit()
	return 25
end

function Baler:getIsWorkAreaActive(superFunc, workArea)
	local spec = self.spec_baler

	if not g_currentMission:getCanAddLimitedObject(FSBaseMission.LIMITED_OBJECT_TYPE_BALE) and self:getIsTurnedOn() then
		g_currentMission:showBlinkingWarning(spec.texts.warningTooManyBales, 500)

		return false
	end

	if self:getFillUnitFreeCapacity(spec.buffer.fillUnitIndex or spec.fillUnitIndex) == 0 then
		return false
	end

	if self.allowPickingUp ~= nil and not self:allowPickingUp() then
		return false
	end

	if spec.hasUnloadingAnimation and not spec.nonStopBaling and (#spec.bales > 0 or spec.unloadingState ~= Baler.UNLOADING_CLOSED) then
		return false
	end

	return superFunc(self, workArea)
end

function Baler:getConsumingLoad(superFunc)
	local value, count = superFunc(self)
	local spec = self.spec_baler
	local loadPercentage = spec.pickUpLitersBuffer:get(1000) / spec.maxPickupLitersPerSecond

	return value + loadPercentage, count + 1
end

function Baler:getCanBeSelected(superFunc)
	return true
end

function Baler:getIsAttachedTo(superFunc, vehicle)
	if superFunc(self, vehicle) then
		return true
	end

	local spec = self.spec_baler

	for i = 1, #spec.bales do
		if spec.bales[i].baleObject == vehicle then
			return true
		end
	end

	return false
end

function Baler:getAllowDynamicMountFillLevelInfo(superFunc)
	return false
end

function Baler:getAlarmTriggerIsActive(superFunc, alarmTrigger)
	local ret = superFunc(self, alarmTrigger)

	if alarmTrigger.needsBaleLoaded and self.spec_baler ~= nil and #self.spec_baler.bales == 0 then
		return false
	end

	return ret
end

function Baler:loadAlarmTrigger(superFunc, xmlFile, key, alarmTrigger, fillUnit)
	local ret = superFunc(self, xmlFile, key, alarmTrigger, fillUnit)
	alarmTrigger.needsBaleLoaded = xmlFile:getValue(key .. "#needsBaleLoaded", false)

	return ret
end

function Baler:processBalerArea(workArea, dt)
	local spec = self.spec_baler
	local lsx, lsy, lsz, lex, ley, lez, lineRadius = DensityMapHeightUtil.getLineByArea(workArea.start, workArea.width, workArea.height)

	if self.isServer then
		spec.fillEffectType = FillType.UNKNOWN
	end

	for fillTypeIndex, _ in pairs(spec.pickupFillTypes) do
		local pickedUpLiters = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, fillTypeIndex, lsx, lsy, lsz, lex, ley, lez, lineRadius, nil, , false, nil)

		if pickedUpLiters > 0 then
			if self.isServer then
				spec.fillEffectType = fillTypeIndex
			end

			spec.pickupFillTypes[fillTypeIndex] = spec.pickupFillTypes[fillTypeIndex] + pickedUpLiters
			spec.workAreaParameters.lastPickedUpLiters = spec.workAreaParameters.lastPickedUpLiters + pickedUpLiters

			return pickedUpLiters, pickedUpLiters
		end
	end

	return 0, 0
end

function Baler:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_baler

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			if not spec.automaticDrop or not spec.platformAutomaticDrop then
				local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, Baler.actionEventUnloading, false, true, false, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			end

			if #spec.baleTypes > 1 then
				local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_BALE_TYPES, self, Baler.actionEventToggleSize, false, true, false, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			end

			if spec.toggleableAutomaticDrop then
				local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA4, self, Baler.actionEventToggleAutomaticDrop, false, true, false, true, nil)
				local automaticDropState = spec.automaticDrop

				if spec.hasPlatform then
					automaticDropState = spec.platformAutomaticDrop
				end

				g_inputBinding:setActionEventText(actionEventId, automaticDropState and spec.toggleAutomaticDropTextNeg or spec.toggleAutomaticDropTextPos)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			end

			Baler.updateActionEvents(self)
		end
	end
end

function Baler:onStartWorkAreaProcessing(dt)
	local spec = self.spec_baler

	if self.isServer then
		spec.lastAreaBiggerZero = false
		spec.workAreaParameters.lastPickedUpLiters = 0
	end
end

function Baler:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self.spec_baler

	if self.isServer then
		local maxFillType = FillType.UNKNOWN
		local maxFillTypeFillLevel = 0

		for fillTypeIndex, fillLevel in pairs(spec.pickupFillTypes) do
			if maxFillTypeFillLevel < fillLevel then
				maxFillType = fillTypeIndex
				maxFillTypeFillLevel = fillLevel
			end
		end

		local pickedUpLiters = spec.workAreaParameters.lastPickedUpLiters

		if pickedUpLiters > 0 then
			spec.lastAreaBiggerZero = true
			local deltaLevel = pickedUpLiters * spec.fillScale
			spec.variableSpeedLimit.pickupPerSecond = spec.variableSpeedLimit.pickupPerSecond + deltaLevel

			if not spec.hasUnloadingAnimation then
				local deltaTime = self:getTimeFromLevel(deltaLevel)

				self:moveBales(deltaTime)
			end

			local fillUnitIndex = spec.fillUnitIndex

			if spec.nonStopBaling then
				if not spec.buffer.fillMainUnitAfterOverload or not spec.buffer.unloadingStarted then
					fillUnitIndex = spec.buffer.fillUnitIndex
				elseif self:getFillUnitFreeCapacity(spec.fillUnitIndex) <= 0 then
					fillUnitIndex = spec.buffer.fillUnitIndex
				end
			end

			if spec.buffer.loadingStateAnimation ~= nil then
				local animTime = self:getAnimationTime(spec.buffer.loadingStateAnimation)

				if fillUnitIndex == spec.fillUnitIndex then
					if animTime >= 0.99 then
						self:playAnimation(spec.buffer.loadingStateAnimation, -spec.buffer.loadingStateAnimationSpeed)
					end
				elseif animTime <= 0.01 then
					self:playAnimation(spec.buffer.loadingStateAnimation, spec.buffer.loadingStateAnimationSpeed)
				end
			end

			self:setFillUnitFillType(fillUnitIndex, maxFillType)
			self:addFillUnitFillLevel(self:getOwnerFarmId(), fillUnitIndex, deltaLevel, maxFillType, ToolType.UNDEFINED)
		end

		if spec.lastAreaBiggerZero ~= spec.lastAreaBiggerZeroSent then
			self:raiseDirtyFlags(spec.dirtyFlag)

			spec.lastAreaBiggerZeroSent = spec.lastAreaBiggerZero
		end

		if spec.fillEffectType ~= spec.fillEffectTypeSent then
			spec.fillEffectTypeSent = spec.fillEffectType

			self:raiseDirtyFlags(spec.dirtyFlag)
		end
	end
end

function Baler:actionEventUnloading(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_baler

	if not spec.hasPlatform then
		self:handleUnloadingBaleEvent()
	elseif self:getCanUnloadUnfinishedBale() and not spec.platformReadyToDrop then
		self:handleUnloadingBaleEvent()
	else
		self:dropBaleFromPlatform(false)
	end
end

function Baler:actionEventToggleSize(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_baler
	local newIndex = spec.preSelectedBaleTypeIndex + 1

	if newIndex > #spec.baleTypes then
		newIndex = 1
	end

	self:setBaleTypeIndex(newIndex)
end

function Baler:actionEventToggleAutomaticDrop(actionName, inputValue, callbackState, isAnalog)
	self:setBalerAutomaticDrop()
end

function Baler:updateActionEvents()
	local spec = self.spec_baler
	local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]

	if actionEvent ~= nil then
		local showAction = false

		if self:isUnloadingAllowed() and (spec.hasUnloadingAnimation or spec.allowsBaleUnloading) then
			if spec.unloadingState == Baler.UNLOADING_CLOSED then
				if self:getCanUnloadUnfinishedBale() then
					g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.unloadUnfinishedBale)

					showAction = true
				end

				if #spec.bales > 0 then
					g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.unloadBaler)

					showAction = true
				end
			elseif spec.unloadingState == Baler.UNLOADING_OPEN and spec.hasUnloadingAnimation then
				g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.closeBack)

				showAction = true
			end
		end

		if spec.platformReadyToDrop then
			g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.unloadBaler)

			showAction = true
		end

		g_inputBinding:setActionEventActive(actionEvent.actionEventId, showAction)
	end

	if spec.toggleableAutomaticDrop then
		actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA4]

		if actionEvent ~= nil then
			local automaticDropState = spec.automaticDrop

			if spec.hasPlatform then
				automaticDropState = spec.platformAutomaticDrop
			end

			g_inputBinding:setActionEventText(actionEvent.actionEventId, automaticDropState and spec.toggleAutomaticDropTextNeg or spec.toggleAutomaticDropTextPos)
		end
	end

	if #spec.baleTypes > 1 then
		actionEvent = spec.actionEvents[InputAction.TOGGLE_BALE_TYPES]

		if actionEvent ~= nil then
			local baleTypeDef = spec.baleTypes[spec.preSelectedBaleTypeIndex]
			local baleSize = nil

			if spec.hasUnloadingAnimation then
				baleSize = baleTypeDef.diameter
			else
				baleSize = baleTypeDef.length
			end

			g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.changeBaleTypeText:format(baleSize * 100))
		end
	end
end

function Baler.loadSpecValueBaleSize(xmlFile, customEnvironment)
	local rootName = xmlFile:getRootName()
	local baleSizeAttributes = {
		isRoundBaler = false,
		maxDiameter = -math.huge,
		minDiameter = math.huge,
		maxLength = -math.huge,
		minLength = math.huge
	}

	xmlFile:iterate(rootName .. ".baler.baleTypes.baleType", function (_, key)
		baleSizeAttributes.isRoundBaler = xmlFile:getValue(key .. "#isRoundBale", baleSizeAttributes.isRoundBaler)
		local diameter = MathUtil.round(xmlFile:getValue(key .. "#diameter", 0), 2)
		baleSizeAttributes.minDiameter = math.min(baleSizeAttributes.minDiameter, diameter)
		baleSizeAttributes.maxDiameter = math.max(baleSizeAttributes.maxDiameter, diameter)
		local length = MathUtil.round(xmlFile:getValue(key .. "#length", 0), 2)
		baleSizeAttributes.minLength = math.min(baleSizeAttributes.minLength, length)
		baleSizeAttributes.maxLength = math.max(baleSizeAttributes.maxLength, length)
	end)

	if baleSizeAttributes.minDiameter ~= math.huge or baleSizeAttributes.minLength ~= math.huge then
		return baleSizeAttributes
	end
end

function Baler.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, roundBale)
	local baleSizeAttributes = roundBale and storeItem.specs.balerBaleSizeRound or storeItem.specs.balerBaleSizeSquare

	if baleSizeAttributes ~= nil then
		local minValue = baleSizeAttributes.isRoundBaler and baleSizeAttributes.minDiameter or baleSizeAttributes.minLength
		local maxValue = baleSizeAttributes.isRoundBaler and baleSizeAttributes.maxDiameter or baleSizeAttributes.maxLength

		if returnValues == nil or not returnValues then
			local unit = g_i18n:getText("unit_cmShort")
			local size = nil

			if maxValue ~= minValue then
				size = string.format("%d%s-%d%s", minValue * 100, unit, maxValue * 100, unit)
			else
				size = string.format("%d%s", minValue * 100, unit)
			end

			return size
		elseif returnRange == true and maxValue ~= minValue then
			return minValue * 100, maxValue * 100, g_i18n:getText("unit_cmShort")
		else
			return minValue * 100, g_i18n:getText("unit_cmShort")
		end
	elseif returnValues and returnRange then
		return 0, 0, ""
	elseif returnValues then
		return 0, ""
	else
		return ""
	end
end

function Baler.loadSpecValueBaleSizeRound(xmlFile, customEnvironment)
	local baleSizeAttributes = Baler.loadSpecValueBaleSize(xmlFile, customEnvironment)

	if baleSizeAttributes ~= nil and baleSizeAttributes.isRoundBaler then
		return baleSizeAttributes
	end
end

function Baler.loadSpecValueBaleSizeSquare(xmlFile, customEnvironment)
	local baleSizeAttributes = Baler.loadSpecValueBaleSize(xmlFile, customEnvironment)

	if baleSizeAttributes ~= nil and not baleSizeAttributes.isRoundBaler then
		return baleSizeAttributes
	end
end

function Baler.getSpecValueBaleSizeRound(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.balerBaleSizeRound ~= nil and storeItem.specs.balerBaleSizeRound.isRoundBaler then
		return Baler.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, true)
	end
end

function Baler.getSpecValueBaleSizeSquare(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.balerBaleSizeSquare ~= nil and not storeItem.specs.balerBaleSizeSquare.isRoundBaler then
		return Baler.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, false)
	end
end
