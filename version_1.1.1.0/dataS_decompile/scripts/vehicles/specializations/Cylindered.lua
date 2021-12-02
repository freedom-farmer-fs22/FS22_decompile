Cylindered = {
	DIRTY_COLLISION_UPDATE_CHECK = false,
	MOVING_TOOL_XML_KEY = "vehicle.cylindered.movingTools.movingTool(?)",
	MOVING_PART_XML_KEY = "vehicle.cylindered.movingParts.movingPart(?)",
	SOUND_TYPE_EVENT = 0,
	SOUND_TYPE_CONTINUES = 1,
	SOUND_TYPE_ENDING = 2,
	SOUND_TYPE_STARTING = 3,
	SOUND_ACTION_TRANSLATING_END = 0,
	SOUND_ACTION_TRANSLATING_END_POS = 1,
	SOUND_ACTION_TRANSLATING_END_NEG = 2,
	SOUND_ACTION_TRANSLATING_START = 3,
	SOUND_ACTION_TRANSLATING_START_POS = 4,
	SOUND_ACTION_TRANSLATING_START_NEG = 5,
	SOUND_ACTION_TRANSLATING_POS = 6,
	SOUND_ACTION_TRANSLATING_NEG = 7,
	SOUND_ACTION_TOOL_MOVE_END = 8,
	SOUND_ACTION_TOOL_MOVE_END_POS = 9,
	SOUND_ACTION_TOOL_MOVE_END_NEG = 10,
	SOUND_ACTION_TOOL_MOVE_END_POS_LIMIT = 11,
	SOUND_ACTION_TOOL_MOVE_END_NEG_LIMIT = 12,
	SOUND_ACTION_TOOL_MOVE_START = 13,
	SOUND_ACTION_TOOL_MOVE_START_POS = 14,
	SOUND_ACTION_TOOL_MOVE_START_NEG = 15,
	SOUND_ACTION_TOOL_MOVE_START_POS_LIMIT = 16,
	SOUND_ACTION_TOOL_MOVE_START_NEG_LIMIT = 17,
	SOUND_ACTION_TOOL_MOVE_POS = 18,
	SOUND_ACTION_TOOL_MOVE_NEG = 19,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(VehicleSettings, specializations)
	end
}

function Cylindered.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Cylindered")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.cylindered.sounds", "hydraulic")
	schema:register(XMLValueType.TIME, "vehicle.cylindered.movingTools#powerConsumingActiveTimeOffset", "Power consumer deactivation delay. After the moving tool has not been moved this long it will no longer consume power.", 5)
	SoundManager.registerSampleXMLPaths(schema, "vehicle.cylindered.sounds", "actionSound(?)")
	schema:register(XMLValueType.STRING, "vehicle.cylindered.sounds.actionSound(?)#actionNames", "Target actions on given nodes")
	schema:register(XMLValueType.STRING, "vehicle.cylindered.sounds.actionSound(?)#nodes", "Nodes that can activate this sound on given action events")
	schema:register(XMLValueType.FLOAT, "vehicle.cylindered.sounds.actionSound(?).pitch#dropOffFactor", "Factor that is applied to pitch while drop off time is active", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.cylindered.sounds.actionSound(?).pitch#dropOffTime", "After this time the sound will be deactivated", 0)

	local partKey = Cylindered.MOVING_PART_XML_KEY

	schema:register(XMLValueType.NODE_INDEX, partKey .. "#node", "Node")
	schema:register(XMLValueType.NODE_INDEX, partKey .. "#referenceFrame", "Reference frame")
	schema:register(XMLValueType.NODE_INDEX, partKey .. "#referencePoint", "Reference point")
	schema:register(XMLValueType.BOOL, partKey .. "#invertZ", "Invert Z axis", false)
	schema:register(XMLValueType.BOOL, partKey .. "#scaleZ", "Allow Z axis scaling", false)
	schema:register(XMLValueType.INT, partKey .. "#limitedAxis", "Limited axis")
	schema:register(XMLValueType.BOOL, partKey .. "#isActiveDirty", "Part is permanently updated", false)
	schema:register(XMLValueType.BOOL, partKey .. "#playSound", "Play hydraulic sound", false)
	schema:register(XMLValueType.BOOL, partKey .. "#moveToReferenceFrame", "Move to reference frame", false)
	schema:register(XMLValueType.BOOL, partKey .. "#doLineAlignment", "Do line alignment (line as ref point)", false)
	schema:register(XMLValueType.BOOL, partKey .. "#doInversedLineAlignment", "Do inversed line alignment (line inside part and fixed ref point)", false)
	schema:register(XMLValueType.FLOAT, partKey .. ".orientationLine#partLength", "Part length (Distance from part to line)", 0.5)
	schema:register(XMLValueType.NODE_INDEX, partKey .. ".orientationLine.lineNode(?)#node", "Line node")
	schema:register(XMLValueType.BOOL, partKey .. "#doDirectionAlignment", "Do direction alignment", true)
	schema:register(XMLValueType.BOOL, partKey .. "#doRotationAlignment", "Do rotation alignment", false)
	schema:register(XMLValueType.FLOAT, partKey .. "#rotMultiplier", "Rotation multiplier for rotation alignment", 0)
	schema:register(XMLValueType.ANGLE, partKey .. "#minRot", "Min. rotation for limited axis")
	schema:register(XMLValueType.ANGLE, partKey .. "#maxRot", "Max. rotation for limited axis")
	schema:register(XMLValueType.BOOL, partKey .. "#alignToWorldY", "Align part to world Y axis", false)
	schema:register(XMLValueType.NODE_INDEX, partKey .. "#localReferencePoint", "Local reference point")
	schema:register(XMLValueType.NODE_INDEX, partKey .. "#referenceDistancePoint", "Z translation will be used as reference distance")
	schema:register(XMLValueType.FLOAT, partKey .. "#localReferenceDistance", "Predefined reference distance", "calculated automatically")
	schema:register(XMLValueType.BOOL, partKey .. "#updateLocalReferenceDistance", "Update distance to local reference point", false)
	schema:register(XMLValueType.BOOL, partKey .. "#dynamicLocalReferenceDistance", "Local reference distance will be calculated based on the initial distance and the localReferencePoint direction", false)
	schema:register(XMLValueType.BOOL, partKey .. "#localReferenceTranslate", "Translate to local reference node", false)
	schema:register(XMLValueType.FLOAT, partKey .. "#referenceDistanceThreshold", "Distance threshold to update moving part while isActiveDirty", 0)
	schema:register(XMLValueType.BOOL, partKey .. "#useLocalOffset", "Use local offset", false)
	schema:register(XMLValueType.FLOAT, partKey .. "#directionThreshold", "Direction threshold to update part if vehicle is inactive", 0.0001)
	schema:register(XMLValueType.FLOAT, partKey .. "#directionThresholdActive", "Direction threshold to update part if vehicle is inactive", 0.0001)
	schema:register(XMLValueType.STRING, partKey .. "#maxUpdateDistance", "Max. distance to vehicle root while isActiveDirty is set ('-' means unlimited)")
	schema:register(XMLValueType.BOOL, partKey .. "#smoothedDirectionScale", "If moving part is deactivated e.g. due to folding limits the direction is slowly interpolated back to the start direction depending on #smoothedDirectionTime", false)
	schema:register(XMLValueType.TIME, partKey .. "#smoothedDirectionTime", "Defines how low it takes until the part is back in original direction (sec.)", 2)
	schema:register(XMLValueType.BOOL, partKey .. "#debug", "Enables debug rendering for this part", false)
	schema:register(XMLValueType.NODE_INDEX, partKey .. ".dependentPart(?)#node", "Dependent part")
	schema:register(XMLValueType.STRING, partKey .. ".dependentPart(?)#maxUpdateDistance", "Max. distance to vehicle root to update dependent part ('-' means unlimited)", "-")
	schema:register(XMLValueType.BOOL, partKey .. "#divideTranslatingDistance", "If true all translating parts will move at the same time. If false they start to move in the order from the xml", true)
	schema:register(XMLValueType.NODE_INDEX, partKey .. ".translatingPart(?)#node", "Translating part")
	schema:register(XMLValueType.NODE_INDEX, partKey .. ".translatingPart(?)#referenceDistancePoint", "Reference distance point")
	schema:register(XMLValueType.FLOAT, partKey .. ".translatingPart(?)#minZTrans", "Min. Z Translation")
	schema:register(XMLValueType.FLOAT, partKey .. ".translatingPart(?)#maxZTrans", "Max. Z Translation")
	schema:register(XMLValueType.VECTOR_N, partKey .. "#wheelIndices", "List of wheel indices to update")
	schema:register(XMLValueType.STRING, partKey .. "#wheelNodes", "List of wheel nodes to update")
	schema:register(XMLValueType.BOOL, partKey .. ".inputAttacherJoint#value", "Update input attacher joint")
	schema:register(XMLValueType.VECTOR_N, partKey .. ".attacherJoint#jointIndices", "List of attacher joints to update")
	Cylindered.registerDependentComponentJointXMLPaths(schema, partKey)
	Cylindered.registerCopyLocalDirectionXMLPaths(schema, partKey)
	Cylindered.registerDependentAnimationXMLPaths(schema, partKey)

	local toolKey = Cylindered.MOVING_TOOL_XML_KEY

	schema:register(XMLValueType.NODE_INDEX, toolKey .. "#node", "Node")
	schema:register(XMLValueType.BOOL, toolKey .. "#isEasyControlTarget", "Is easy control target", false)
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#rotSpeed", "Rotation speed")
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#rotAcceleration", "Rotation acceleration")
	schema:register(XMLValueType.INT, toolKey .. ".rotation#rotationAxis", "Rotation axis", 1)
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#rotMax", "Max. rotation")
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#rotMin", "Min. rotation")
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#startRot", "Start rotation")
	schema:register(XMLValueType.BOOL, toolKey .. ".rotation#syncMaxRotLimits", "Synchronize max. rotation limits", false)
	schema:register(XMLValueType.BOOL, toolKey .. ".rotation#syncMinRotLimits", "Synchronize min. rotation limits", false)
	schema:register(XMLValueType.INT, toolKey .. ".rotation#rotSendNumBits", "Number of bits to synchronize", 8)
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#attachRotMax", "Max. rotation value set during attach")
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#attachRotMin", "Min. rotation value set during attach")
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#detachingRotMaxLimit", "Max. rotation to detach vehicle")
	schema:register(XMLValueType.ANGLE, toolKey .. ".rotation#detachingRotMinLimit", "Min. rotation to detach vehicle")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#transSpeed", "Translation speed")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#transAcceleration", "Translation acceleration")
	schema:register(XMLValueType.INT, toolKey .. ".translation#translationAxis", "Translation axis")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#transMax", "Max. translation")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#transMin", "Min. translation")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#startTrans", "Start translation")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#attachTransMax", "Max. translation value set during attach")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#attachTransMin", "Min. translation value set during attach")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#detachingTransMaxLimit", "Max. translation to detach vehicle")
	schema:register(XMLValueType.FLOAT, toolKey .. ".translation#detachingTransMinLimit", "Min. translation to detach vehicle")
	schema:register(XMLValueType.BOOL, toolKey .. "#playSound", "Play sound", false)
	schema:register(XMLValueType.STRING, toolKey .. ".animation#animName", "Animation name")
	schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animSpeed", "Animation speed")
	schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animAcceleration", "Animation acceleration")
	schema:register(XMLValueType.INT, toolKey .. ".animation#animSendNumBits", "Number of bits to synchronize", 8)
	schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animMaxTime", "Animation max. time", 1)
	schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animMinTime", "Animation min. time", 0)
	schema:register(XMLValueType.FLOAT, toolKey .. ".animation#animStartTime", "Animation start time")
	schema:register(XMLValueType.STRING, toolKey .. ".controls#iconName", "Icon identifier")
	schema:register(XMLValueType.INT, toolKey .. ".controls#groupIndex", "Control group index", 0)
	schema:register(XMLValueType.STRING, toolKey .. ".controls#axis", "Input action name")
	schema:register(XMLValueType.BOOL, toolKey .. ".controls#invertAxis", "Invert input axis", false)
	schema:register(XMLValueType.FLOAT, toolKey .. ".controls#mouseSpeedFactor", "Mouse speed factor", 1)
	schema:register(XMLValueType.BOOL, toolKey .. "#allowSaving", "Allow saving", true)
	schema:register(XMLValueType.BOOL, toolKey .. "#isIntitialDirty", "Is initial dirty", true)
	schema:register(XMLValueType.NODE_INDEX, toolKey .. "#delayedNode", "Delayed node")
	schema:register(XMLValueType.INT, toolKey .. "#delayedFrames", "Delayed frames", 3)
	schema:register(XMLValueType.BOOL, toolKey .. "#isConsumingPower", "While tool is moving the power consumer is set active", false)
	schema:register(XMLValueType.NODE_INDEX, toolKey .. ".dependentPart(?)#node", "Dependent part")
	schema:register(XMLValueType.STRING, toolKey .. ".dependentPart(?)#maxUpdateDistance", "Max. distance to vehicle root to update dependent part ('-' means unlimited)", "-")
	schema:register(XMLValueType.VECTOR_N, toolKey .. "#wheelIndices", "List of wheel indices to update")
	schema:register(XMLValueType.STRING, toolKey .. "#wheelNodes", "List of wheel nodes to update")
	schema:register(XMLValueType.BOOL, toolKey .. ".inputAttacherJoint#value", "Update input attacher joint")
	schema:register(XMLValueType.VECTOR_N, toolKey .. ".attacherJoint#jointIndices", "List of attacher joints to update")
	schema:register(XMLValueType.INT, toolKey .. "#fillUnitIndex", "Fill unit index")
	schema:register(XMLValueType.FLOAT, toolKey .. "#minFillLevel", "Min. fill level")
	schema:register(XMLValueType.FLOAT, toolKey .. "#maxFillLevel", "Max. fill level")
	schema:register(XMLValueType.FLOAT, toolKey .. "#foldMinLimit", "Min. fold time", 0)
	schema:register(XMLValueType.FLOAT, toolKey .. "#foldMaxLimit", "Max. fold time", 1)
	Cylindered.registerDependentComponentJointXMLPaths(schema, toolKey)
	Cylindered.registerDependentAnimationXMLPaths(schema, toolKey)
	schema:register(XMLValueType.NODE_INDEX, toolKey .. ".dependentMovingTool(?)#node", "Dependent part")
	schema:register(XMLValueType.FLOAT, toolKey .. ".dependentMovingTool(?)#speedScale", "Speed scale")
	schema:register(XMLValueType.BOOL, toolKey .. ".dependentMovingTool(?)#requiresMovement", "Requires movement", false)
	schema:register(XMLValueType.ANGLE, toolKey .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#rotation", "Rotation")
	schema:register(XMLValueType.ANGLE, toolKey .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#rotMin", "Min. rotation")
	schema:register(XMLValueType.ANGLE, toolKey .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#rotMax", "Max. rotation")
	schema:register(XMLValueType.FLOAT, toolKey .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#transMin", "Min. translation")
	schema:register(XMLValueType.FLOAT, toolKey .. ".dependentMovingTool(?).rotationBasedLimits.limit(?)#transMax", "Max. translation")
	schema:register(XMLValueType.VECTOR_2, toolKey .. ".dependentMovingTool(?)#minTransLimits", "Min. translation limits")
	schema:register(XMLValueType.VECTOR_2, toolKey .. ".dependentMovingTool(?)#maxTransLimits", "Max. translation limits")
	schema:register(XMLValueType.VECTOR_ROT_2, toolKey .. ".dependentMovingTool(?)#minRotLimits", "Min. rotation limits")
	schema:register(XMLValueType.VECTOR_ROT_2, toolKey .. ".dependentMovingTool(?)#maxRotLimits", "Max. rotation limits")
	schema:register(XMLValueType.L10N_STRING, "vehicle.cylindered.movingTools.controlGroups.controlGroup(?)#name", "Control group name")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.cylindered.movingTools.easyArmControl#rootNode", "Root node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.cylindered.movingTools.easyArmControl#node", "Node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.cylindered.movingTools.easyArmControl#targetNodeZ", "Z target node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.cylindered.movingTools.easyArmControl#refNode", "Reference node")
	schema:register(XMLValueType.FLOAT, "vehicle.cylindered.movingTools.easyArmControl#maxTotalDistance", "Max. total distance the arms can move from rootNode", "automatically calculated")
	schema:register(XMLValueType.FLOAT, "vehicle.cylindered.movingTools.easyArmControl.targetMovement#speed", "Target node move speed", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.cylindered.movingTools.easyArmControl.targetMovement#acceleration", "Target node move acceleration", 50)
	schema:register(XMLValueType.FLOAT, "vehicle.cylindered.movingTools.easyArmControl.zTranslationNodes#minMoveRatio", "Min. ratio between translation and rotation movement [0: only rotation, 1: only translation]", 0.2)
	schema:register(XMLValueType.FLOAT, "vehicle.cylindered.movingTools.easyArmControl.zTranslationNodes#maxMoveRatio", "Max. ratio between translation and rotation movement [0: only rotation, 1: only translation]", 0.8)
	schema:register(XMLValueType.FLOAT, "vehicle.cylindered.movingTools.easyArmControl.zTranslationNodes#moveRatioMinDir", "Defines direction value when the translation parts start to move", 0)
	schema:register(XMLValueType.FLOAT, "vehicle.cylindered.movingTools.easyArmControl.zTranslationNodes#moveRatioMaxDir", "Defines direction value when the rotation parts stop to move", 1)
	schema:register(XMLValueType.BOOL, "vehicle.cylindered.movingTools.easyArmControl.zTranslationNodes#allowNegativeTrans", "Allow translation movement if translation parts are pointing towards the root node", false)
	schema:register(XMLValueType.FLOAT, "vehicle.cylindered.movingTools.easyArmControl.zTranslationNodes#minNegativeTrans", "Min. translation percentage when moving the translation parts into negative direction while they are pointing towards the root node", 0)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.cylindered.movingTools.easyArmControl.zTranslationNodes.zTranslationNode(?)#node", "Z translation node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.cylindered.movingTools.easyArmControl.xRotationNodes.xRotationNode1#node", "X translation node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.cylindered.movingTools.easyArmControl.xRotationNodes.xRotationNode2#node", "X translation node")
	Dashboard.registerDashboardXMLPaths(schema, "vehicle.cylindered.dashboards", "movingTool")
	schema:register(XMLValueType.STRING, "vehicle.cylindered.dashboards.dashboard(?)#axis", "Moving tool input action name")
	schema:register(XMLValueType.INT, "vehicle.cylindered.dashboards.dashboard(?)#attacherJointIndex", "Attacher joint index that needs to be active")
	schema:register(XMLValueType.STRING, "vehicle.cylindered.dashboards.dashboard(?)#axis", "Input action name")
	schema:register(XMLValueType.INT, "vehicle.cylindered.dashboards.dashboard(?)#attacherJointIndex", "Attacher joint index that needs to be active")
	ObjectChangeUtil.addAdditionalObjectChangeXMLPaths(schema, function (_schema, key)
		_schema:register(XMLValueType.ANGLE, key .. "#movingToolRotMaxActive", "Moving tool max. rotation if object change active")
		_schema:register(XMLValueType.ANGLE, key .. "#movingToolRotMaxInactive", "Moving tool max. rotation if object change inactive")
		_schema:register(XMLValueType.ANGLE, key .. "#movingToolRotMinActive", "Moving tool min. rotation if object change active")
		_schema:register(XMLValueType.ANGLE, key .. "#movingToolRotMinInactive", "Moving tool min. rotation if object change inactive")
		_schema:register(XMLValueType.BOOL, key .. "#movingPartUpdateActive", "moving part active state if object change active")
		_schema:register(XMLValueType.BOOL, key .. "#movingPartUpdateInactive", "moving part active state if object change inactive")
	end)
	schema:register(XMLValueType.NODE_INDEX, Dischargeable.DISCHARGE_NODE_XML_PATH .. ".movingToolActivation#node", "Moving tool node")
	schema:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_XML_PATH .. ".movingToolActivation#isInverted", "Activation is inverted", false)
	schema:register(XMLValueType.FLOAT, Dischargeable.DISCHARGE_NODE_XML_PATH .. ".movingToolActivation#openFactor", "Open factor", 1)
	schema:register(XMLValueType.FLOAT, Dischargeable.DISCHARGE_NODE_XML_PATH .. ".movingToolActivation#openOffset", "Open offset", 0)
	schema:register(XMLValueType.NODE_INDEX, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. ".movingToolActivation#node", "Moving tool node")
	schema:register(XMLValueType.BOOL, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. ".movingToolActivation#isInverted", "Activation is inverted", false)
	schema:register(XMLValueType.FLOAT, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. ".movingToolActivation#openFactor", "Open factor", 1)
	schema:register(XMLValueType.FLOAT, Dischargeable.DISCHARGE_NODE_CONFIG_XML_PATH .. ".movingToolActivation#openOffset", "Open offset", 0)
	schema:register(XMLValueType.NODE_INDEX, Shovel.SHOVEL_NODE_XML_KEY .. ".movingToolActivation#node", "Moving tool node")
	schema:register(XMLValueType.BOOL, Shovel.SHOVEL_NODE_XML_KEY .. ".movingToolActivation#isInverted", "Activation is inverted", false)
	schema:register(XMLValueType.FLOAT, Shovel.SHOVEL_NODE_XML_KEY .. ".movingToolActivation#openFactor", "Open factor", 1)
	schema:register(XMLValueType.NODE_INDEX, DynamicMountAttacher.DYNAMIC_MOUNT_GRAB_XML_PATH .. ".movingToolActivation#node", "Moving tool node")
	schema:register(XMLValueType.BOOL, DynamicMountAttacher.DYNAMIC_MOUNT_GRAB_XML_PATH .. ".movingToolActivation#isInverted", "Activation is inverted", false)
	schema:register(XMLValueType.FLOAT, DynamicMountAttacher.DYNAMIC_MOUNT_GRAB_XML_PATH .. ".movingToolActivation#openFactor", "Open factor", 1)
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame

	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).cylindered.movingTool(?)#translation", "Current translation value")
	schemaSavegame:register(XMLValueType.ANGLE, "vehicles.vehicle(?).cylindered.movingTool(?)#rotation", "Current rotation in rad")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).cylindered.movingTool(?)#animationTime", "Current animation time")
end

function Cylindered.registerDependentComponentJointXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. ".componentJoint(?)#index", "Dependent component joint index")
	schema:register(XMLValueType.INT, basePath .. ".componentJoint(?)#anchorActor", "Dependent component anchor actor")
end

function Cylindered.registerCopyLocalDirectionXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".copyLocalDirectionPart(?)#node", "Copy local direction part")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".copyLocalDirectionPart(?)#dirScale", "Direction scale")
	schema:register(XMLValueType.VECTOR_3, basePath .. ".copyLocalDirectionPart(?)#upScale", "Up vector scale")
	Cylindered.registerDependentComponentJointXMLPaths(schema, basePath .. ".copyLocalDirectionPart(?)")
end

function Cylindered.registerDependentAnimationXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".dependentAnimation(?)#name", "Dependent animation name")
	schema:register(XMLValueType.INT, basePath .. ".dependentAnimation(?)#translationAxis", "Translation axis")
	schema:register(XMLValueType.INT, basePath .. ".dependentAnimation(?)#rotationAxis", "Rotation axis")
	schema:register(XMLValueType.INT, basePath .. ".dependentAnimation(?)#useTranslatingPartIndex", "Use translation part index")
	schema:register(XMLValueType.FLOAT, basePath .. ".dependentAnimation(?)#minValue", "Min. reference value")
	schema:register(XMLValueType.FLOAT, basePath .. ".dependentAnimation(?)#maxValue", "Max. reference value")
	schema:register(XMLValueType.BOOL, basePath .. ".dependentAnimation(?)#invert", "Invert reference value", false)
end

function Cylindered.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onMovingToolChanged")
end

function Cylindered.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadMovingPartFromXML", Cylindered.loadMovingPartFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadMovingToolFromXML", Cylindered.loadMovingToolFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentMovingTools", Cylindered.loadDependentMovingTools)
	SpecializationUtil.registerFunction(vehicleType, "loadEasyArmControlFromXML", Cylindered.loadEasyArmControlFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentParts", Cylindered.loadDependentParts)
	SpecializationUtil.registerFunction(vehicleType, "resolveDependentPartData", Cylindered.resolveDependentPartData)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentComponentJoints", Cylindered.loadDependentComponentJoints)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentAttacherJoints", Cylindered.loadDependentAttacherJoints)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentWheels", Cylindered.loadDependentWheels)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentTranslatingParts", Cylindered.loadDependentTranslatingParts)
	SpecializationUtil.registerFunction(vehicleType, "loadExtraDependentParts", Cylindered.loadExtraDependentParts)
	SpecializationUtil.registerFunction(vehicleType, "loadDependentAnimations", Cylindered.loadDependentAnimations)
	SpecializationUtil.registerFunction(vehicleType, "loadCopyLocalDirectionParts", Cylindered.loadCopyLocalDirectionParts)
	SpecializationUtil.registerFunction(vehicleType, "loadRotationBasedLimits", Cylindered.loadRotationBasedLimits)
	SpecializationUtil.registerFunction(vehicleType, "updateDirtyMovingParts", Cylindered.updateDirtyMovingParts)
	SpecializationUtil.registerFunction(vehicleType, "setMovingToolDirty", Cylindered.setMovingToolDirty)
	SpecializationUtil.registerFunction(vehicleType, "updateCylinderedInitial", Cylindered.updateCylinderedInitial)
	SpecializationUtil.registerFunction(vehicleType, "allowLoadMovingToolStates", Cylindered.allowLoadMovingToolStates)
	SpecializationUtil.registerFunction(vehicleType, "getMovingToolByNode", Cylindered.getMovingToolByNode)
	SpecializationUtil.registerFunction(vehicleType, "getMovingPartByNode", Cylindered.getMovingPartByNode)
	SpecializationUtil.registerFunction(vehicleType, "getTranslatingPartByNode", Cylindered.getTranslatingPartByNode)
	SpecializationUtil.registerFunction(vehicleType, "getIsMovingToolActive", Cylindered.getIsMovingToolActive)
	SpecializationUtil.registerFunction(vehicleType, "getIsMovingPartActive", Cylindered.getIsMovingPartActive)
	SpecializationUtil.registerFunction(vehicleType, "setDelayedData", Cylindered.setDelayedData)
	SpecializationUtil.registerFunction(vehicleType, "updateDelayedTool", Cylindered.updateDelayedTool)
	SpecializationUtil.registerFunction(vehicleType, "updateEasyControl", Cylindered.updateEasyControl)
	SpecializationUtil.registerFunction(vehicleType, "setIsEasyControlActive", Cylindered.setIsEasyControlActive)
	SpecializationUtil.registerFunction(vehicleType, "updateExtraDependentParts", Cylindered.updateExtraDependentParts)
	SpecializationUtil.registerFunction(vehicleType, "updateDependentAnimations", Cylindered.updateDependentAnimations)
	SpecializationUtil.registerFunction(vehicleType, "updateDependentToolLimits", Cylindered.updateDependentToolLimits)
	SpecializationUtil.registerFunction(vehicleType, "onMovingPartSoundEvent", Cylindered.onMovingPartSoundEvent)
	SpecializationUtil.registerFunction(vehicleType, "updateMovingToolSoundEvents", Cylindered.updateMovingToolSoundEvents)
end

function Cylindered.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", Cylindered.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadObjectChangeValuesFromXML", Cylindered.loadObjectChangeValuesFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setObjectChangeValues", Cylindered.setObjectChangeValues)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDischargeNode", Cylindered.loadDischargeNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDischargeNodeEmptyFactor", Cylindered.getDischargeNodeEmptyFactor)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadShovelNode", Cylindered.loadShovelNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShovelNodeIsActive", Cylindered.getShovelNodeIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDynamicMountGrabFromXML", Cylindered.loadDynamicMountGrabFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDynamicMountGrabOpened", Cylindered.getIsDynamicMountGrabOpened)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setComponentJointFrame", Cylindered.setComponentJointFrame)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAdditionalSchemaText", Cylindered.getAdditionalSchemaText)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Cylindered.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", Cylindered.getDoConsumePtoPower)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", Cylindered.getConsumingLoad)
end

function Cylindered.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdateTick", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onSelect", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onUnselect", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onAnimationPartChanged", Cylindered)
	SpecializationUtil.registerEventListener(vehicleType, "onVehicleSettingChanged", Cylindered)
end

function Cylindered:onLoad(savegame)
	local spec = self.spec_cylindered

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.movingParts", "vehicle.cylindered.movingParts")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.movingTools", "vehicle.cylindered.movingTools")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cylinderedHydraulicSound", "vehicle.cylindered.sounds.hydraulic")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cylindered.movingParts#isActiveDirtyTimeOffset")

	spec.activeDirtyMovingParts = {}
	local referenceNodes = {}
	spec.nodesToMovingParts = {}
	spec.movingParts = {}
	self.anyMovingPartsDirty = false
	spec.detachLockNodes = nil
	local i = 0

	while true do
		local partKey = string.format("vehicle.cylindered.movingParts.movingPart(%d)", i)

		if not self.xmlFile:hasProperty(partKey) then
			break
		end

		local entry = {}

		if self:loadMovingPartFromXML(self.xmlFile, partKey, entry) then
			if referenceNodes[entry.node] == nil then
				referenceNodes[entry.node] = {}
			end

			if spec.nodesToMovingParts[entry.node] == nil then
				table.insert(referenceNodes[entry.node], entry)
				self:loadDependentParts(self.xmlFile, partKey, entry)
				self:loadDependentComponentJoints(self.xmlFile, partKey, entry)
				self:loadCopyLocalDirectionParts(self.xmlFile, partKey, entry)
				self:loadExtraDependentParts(self.xmlFile, partKey, entry)
				self:loadDependentAnimations(self.xmlFile, partKey, entry)

				entry.key = partKey

				table.insert(spec.movingParts, entry)

				if entry.isActiveDirty then
					table.insert(spec.activeDirtyMovingParts, entry)
				end

				spec.nodesToMovingParts[entry.node] = entry
			else
				Logging.xmlWarning(self.xmlFile, "Moving part with node '%s' already exists!", getName(entry.node))
			end
		end

		i = i + 1
	end

	if Cylindered.DIRTY_COLLISION_UPDATE_CHECK then
		local function collectDependentParts(part, target)
			table.insert(target, part)

			if part.dependentPartNodes ~= nil then
				for l = 1, #part.dependentPartNodes do
					local dependentMovingPart = spec.nodesToMovingParts[part.dependentPartNodes[l]]

					if dependentMovingPart ~= nil then
						table.insert(target, dependentMovingPart)
						collectDependentParts(dependentMovingPart, target)
					end
				end
			end
		end

		local function subCollisionErrorFunction(collisionNode, xmlFile, key)
			if getHasClassId(collisionNode, ClassIds.SHAPE) then
				Logging.xmlError(xmlFile, "Found collision '%s' as child of isActiveDirty movingPart '%s'. This can cause the vehicle to never sleep!", getName(collisionNode), key)
			end
		end

		spec.realActiveDirtyParts = {}

		for j = 1, #spec.movingParts do
			local movingPart = spec.movingParts[j]

			if movingPart.isActiveDirty and movingPart.directionThreshold == 0.0001 then
				collectDependentParts(movingPart, spec.realActiveDirtyParts)
			end
		end

		for j = 1, #spec.realActiveDirtyParts do
			local part = spec.realActiveDirtyParts[j]

			I3DUtil.checkForChildCollisions(part.node, subCollisionErrorFunction, self.xmlFile, getName(part.node))
		end
	end

	spec.powerConsumingActiveTimeOffset = self.xmlFile:getValue("vehicle.cylindered.movingTools#powerConsumingActiveTimeOffset", 5)
	spec.powerConsumingTimer = -1

	for _, part in pairs(spec.movingParts) do
		self:resolveDependentPartData(part.dependentPartData, referenceNodes)
	end

	local function addMovingPart(part, newTable, allowDependentParts)
		for _, addedPart in ipairs(newTable) do
			if addedPart == part then
				return
			end
		end

		if part.isDependentPart == true and allowDependentParts ~= true then
			return
		end

		table.insert(newTable, part)

		for _, depPart in pairs(part.dependentPartData) do
			addMovingPart(depPart.part, newTable, true)
		end
	end

	local newParts = {}

	for _, part in ipairs(spec.movingParts) do
		addMovingPart(part, newParts)
	end

	spec.movingParts = newParts
	spec.controlGroups = {}
	spec.controlGroupMapping = {}
	spec.currentControlGroupIndex = 1
	spec.controlGroupNames = {}
	i = 0

	while true do
		local groupKey = string.format("vehicle.cylindered.movingTools.controlGroups.controlGroup(%d)", i)

		if not self.xmlFile:hasProperty(groupKey) then
			break
		end

		local name = self.xmlFile:getValue(groupKey .. "#name", "", self.customEnvironment, false)

		if name ~= nil then
			table.insert(spec.controlGroupNames, name)
		end

		i = i + 1
	end

	spec.nodesToMovingTools = {}
	spec.movingTools = {}
	i = 0

	while true do
		local toolKey = string.format("vehicle.cylindered.movingTools.movingTool(%d)", i)

		if not self.xmlFile:hasProperty(toolKey) then
			break
		end

		local entry = {}

		if self:loadMovingToolFromXML(self.xmlFile, toolKey, entry) then
			if referenceNodes[entry.node] == nil then
				referenceNodes[entry.node] = {}
			end

			if spec.nodesToMovingTools[entry.node] == nil then
				table.insert(referenceNodes[entry.node], entry)
				self:loadDependentMovingTools(self.xmlFile, toolKey, entry)
				self:loadDependentParts(self.xmlFile, toolKey, entry)
				self:loadDependentComponentJoints(self.xmlFile, toolKey, entry)
				self:loadExtraDependentParts(self.xmlFile, toolKey, entry)
				self:loadDependentAnimations(self.xmlFile, toolKey, entry)

				entry.isActive = true
				entry.key = toolKey

				table.insert(spec.movingTools, entry)

				spec.nodesToMovingTools[entry.node] = entry
			else
				Logging.xmlWarning(self.xmlFile, "Moving tool with node '%s' already exists!", getName(entry.node))
			end
		end

		i = i + 1
	end

	local function sort(a, b)
		return a < b
	end

	table.sort(spec.controlGroups, sort)

	for _, groupIndex in ipairs(spec.controlGroups) do
		local subSelectionIndex = self:addSubselection(groupIndex)
		spec.controlGroupMapping[subSelectionIndex] = groupIndex
	end

	for _, part in pairs(spec.movingTools) do
		self:resolveDependentPartData(part.dependentPartData, referenceNodes)

		for j = #part.dependentMovingTools, 1, -1 do
			local dependentTool = part.dependentMovingTools[j]
			local tool = spec.nodesToMovingTools[dependentTool.node]

			if tool ~= nil then
				dependentTool.movingTool = tool
			else
				Logging.xmlWarning(self.xmlFile, "Dependent moving tool '%s' not defined. Ignoring it!", getName(dependentTool.node))
				table.remove(part.dependentMovingTools, j)
			end
		end
	end

	local easyArmControlKey = "vehicle.cylindered.movingTools.easyArmControl"

	if self.xmlFile:hasProperty(easyArmControlKey) then
		local easyArmControl = {}

		if self:loadEasyArmControlFromXML(self.xmlFile, easyArmControlKey, easyArmControl) then
			spec.easyArmControl = easyArmControl
		end
	end

	spec.samples = {}
	spec.actionSamples = {}

	if self.isClient then
		spec.samples.hydraulic = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.cylindered.sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		spec.isHydraulicSamplePlaying = false
		spec.nodesToSamples = {}
		spec.activeSamples = {}
		spec.endingSamples = {}
		spec.endingSamplesBySample = {}
		spec.startingSamples = {}
		spec.startingSamplesBySample = {}
		i = 0

		while true do
			local actionKey = string.format("actionSound(%d)", i)
			local baseKey = "vehicle.cylindered.sounds." .. actionKey

			if not self.xmlFile:hasProperty(baseKey) then
				break
			end

			local sample = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.cylindered.sounds", actionKey, self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)

			if sample ~= nil then
				local actionNamesStr = self.xmlFile:getValue(baseKey .. "#actionNames")
				local actionNames = string.split(actionNamesStr:trim(), " ")
				local nodesStr = self.xmlFile:getValue(baseKey .. "#nodes")
				local nodes = string.split(nodesStr, " ")

				for l = 1, #nodes do
					nodes[l] = I3DUtil.indexToObject(self.components, nodes[l], self.i3dMappings)
				end

				for j = 1, #actionNames do
					local actionName = actionNames[j]
					actionName = "SOUND_ACTION_" .. actionName:upper()
					local action = Cylindered[actionName]

					if action ~= nil then
						for l = 1, #nodes do
							local node = nodes[l]

							if node ~= nil then
								if spec.nodesToSamples[node] == nil then
									spec.nodesToSamples[node] = {}
								end

								if spec.nodesToSamples[node][action] == nil then
									spec.nodesToSamples[node][action] = {}
								end

								local part = self:getMovingPartByNode(node) or self:getTranslatingPartByNode(node) or self:getMovingToolByNode(node)

								if part ~= nil then
									part.samplesByAction = spec.nodesToSamples[node]
								else
									Logging.xmlWarning(self.xmlFile, "Unable to find movingPart or translatingPart for node '%s'", getName(node))
								end

								table.insert(spec.nodesToSamples[node][action], sample)
							end
						end
					else
						Logging.xmlWarning(self.xmlFile, "Unable to find sound action '%s' for sound '%s'", actionName, baseKey)
					end
				end

				sample.dropOffFactor = self.xmlFile:getValue(baseKey .. ".pitch#dropOffFactor", 1)
				sample.dropOffTime = self.xmlFile:getValue(baseKey .. ".pitch#dropOffTime", 0) * 1000
				sample.actionNames = actionNames
				sample.nodes = nodes

				table.insert(spec.actionSamples, sample)
			end

			i = i + 1
		end
	end

	if self.loadDashboardsFromXML ~= nil then
		local dashboardData = {
			maxFunc = 1,
			minFunc = 0,
			valueTypeToLoad = "movingTool",
			idleValue = 0.5,
			valueObject = self,
			valueFunc = Cylindered.getMovingToolDashboardState,
			additionalAttributesFunc = Cylindered.movingToolDashboardAttributes
		}

		self:loadDashboardsFromXML(self.xmlFile, "vehicle.cylindered.dashboards", dashboardData)
	end

	spec.cylinderedDirtyFlag = self:getNextDirtyFlag()
	spec.cylinderedInputDirtyFlag = self:getNextDirtyFlag()

	self:registerVehicleSetting(GameSettings.SETTING.EASY_ARM_CONTROL, true)

	spec.isLoading = true
end

function Cylindered:onPostLoad(savegame)
	local spec = self.spec_cylindered

	for _, tool in pairs(spec.movingTools) do
		if self:getIsMovingToolActive(tool) then
			if tool.startRot ~= nil then
				tool.curRot[tool.rotationAxis] = tool.startRot

				setRotation(tool.node, unpack(tool.curRot))
			end

			if tool.startTrans ~= nil then
				tool.curTrans[tool.translationAxis] = tool.startTrans

				setTranslation(tool.node, unpack(tool.curTrans))
			end

			if tool.animStartTime ~= nil then
				self:setAnimationTime(tool.animName, tool.animStartTime, nil, false)
			end

			if tool.delayedNode ~= nil then
				self:setDelayedData(tool, true)
			end

			if tool.isIntitialDirty then
				Cylindered.setDirty(self, tool)
			end
		end
	end

	for _, part in pairs(spec.movingParts) do
		self:loadDependentAttacherJoints(self.xmlFile, part.key, part)
		self:loadDependentWheels(self.xmlFile, part.key, part)
	end

	for _, tool in pairs(spec.movingTools) do
		self:loadDependentAttacherJoints(self.xmlFile, tool.key, tool)
		self:loadDependentWheels(self.xmlFile, tool.key, tool)
	end

	if self:allowLoadMovingToolStates() and savegame ~= nil and not savegame.resetVehicles then
		local i = 0

		for _, tool in ipairs(spec.movingTools) do
			if tool.saving then
				if self:getIsMovingToolActive(tool) then
					local toolKey = string.format("%s.cylindered.movingTool(%d)", savegame.key, i)
					local changed = false

					if tool.transSpeed ~= nil then
						local newTrans = savegame.xmlFile:getValue(toolKey .. "#translation")

						if newTrans ~= nil then
							if tool.transMax ~= nil then
								newTrans = math.min(newTrans, tool.transMax)
							end

							if tool.transMin ~= nil then
								newTrans = math.max(newTrans, tool.transMin)
							end
						end

						if newTrans ~= nil and math.abs(newTrans - tool.curTrans[tool.translationAxis]) > 0.0001 then
							tool.curTrans = {
								[tool.translationAxis] = newTrans,
								getTranslation(tool.node)
							}

							setTranslation(tool.node, unpack(tool.curTrans))

							changed = true
						end
					end

					if tool.rotSpeed ~= nil then
						local newRot = savegame.xmlFile:getValue(toolKey .. "#rotation")

						if newRot ~= nil then
							if tool.rotMax ~= nil then
								newRot = math.min(newRot, tool.rotMax)
							end

							if tool.rotMin ~= nil then
								newRot = math.max(newRot, tool.rotMin)
							end
						end

						if newRot ~= nil and math.abs(newRot - tool.curRot[tool.rotationAxis]) > 0.0001 then
							tool.curRot = {
								[tool.rotationAxis] = newRot,
								getRotation(tool.node)
							}

							setRotation(tool.node, unpack(tool.curRot))

							changed = true
						end
					end

					if tool.animSpeed ~= nil then
						local animTime = savegame.xmlFile:getValue(toolKey .. "#animationTime")

						if animTime ~= nil then
							if tool.animMinTime ~= nil then
								animTime = math.max(animTime, tool.animMinTime)
							end

							if tool.animMaxTime ~= nil then
								animTime = math.min(animTime, tool.animMaxTime)
							end

							tool.curAnimTime = animTime

							self:setAnimationTime(tool.animName, animTime, true, false)
						end
					end

					if changed then
						Cylindered.setDirty(self, tool)
					end

					if tool.delayedNode ~= nil then
						self:setDelayedData(tool, true)
					end
				end

				i = i + 1
			end

			for _, dependentTool in pairs(tool.dependentMovingTools) do
				Cylindered.updateRotationBasedLimits(self, tool, dependentTool)
			end
		end
	end

	self:updateEasyControl(9999, true)
	self:updateCylinderedInitial(false)

	local hasTools = #spec.movingTools > 0
	local hasParts = #spec.movingParts > 0

	if not hasTools then
		SpecializationUtil.removeEventListener(self, "onReadStream", Cylindered)
		SpecializationUtil.removeEventListener(self, "onWriteStream", Cylindered)
		SpecializationUtil.removeEventListener(self, "onReadUpdateStream", Cylindered)
		SpecializationUtil.removeEventListener(self, "onWriteUpdateStream", Cylindered)
		SpecializationUtil.removeEventListener(self, "onUpdate", Cylindered)

		if not hasParts then
			SpecializationUtil.removeEventListener(self, "onUpdateTick", Cylindered)
			SpecializationUtil.removeEventListener(self, "onPostUpdate", Cylindered)
			SpecializationUtil.removeEventListener(self, "onPostUpdateTick", Cylindered)
		end
	end

	if not self.isClient or not hasTools then
		SpecializationUtil.removeEventListener(self, "onDraw", Cylindered)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", Cylindered)
	end
end

function Cylindered:onLoadFinished(savegame)
	local spec = self.spec_cylindered
	spec.isLoading = false

	for i = 1, #spec.movingTools do
		local tool = spec.movingTools[i]

		if tool.delayedHistoryIndex ~= nil and tool.delayedHistoryIndex > 0 then
			self:updateDelayedTool(tool, true)
		end
	end
end

function Cylindered:onDelete()
	local spec = self.spec_cylindered

	g_soundManager:deleteSamples(spec.samples)
	g_soundManager:deleteSamples(spec.actionSamples)

	if spec.movingTools ~= nil then
		for _, movingTool in pairs(spec.movingTools) do
			if movingTool.icon ~= nil then
				movingTool.icon:delete()

				movingTool.icon = nil
			end
		end
	end
end

function Cylindered:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_cylindered
	local index = 0

	for _, tool in ipairs(spec.movingTools) do
		if tool.saving then
			local toolKey = string.format("%s.movingTool(%d)", key, index)

			if tool.transSpeed ~= nil then
				xmlFile:setValue(toolKey .. "#translation", tool.curTrans[tool.translationAxis])
			end

			if tool.rotSpeed ~= nil then
				xmlFile:setValue(toolKey .. "#rotation", tool.curRot[tool.rotationAxis])
			end

			if tool.animSpeed ~= nil then
				xmlFile:setValue(toolKey .. "#animationTime", tool.curAnimTime)
			end

			index = index + 1
		end
	end
end

function Cylindered:onReadStream(streamId, connection)
	local spec = self.spec_cylindered

	if connection:getIsServer() and streamReadBool(streamId) then
		for i = 1, #spec.movingTools do
			local tool = spec.movingTools[i]

			if tool.dirtyFlag ~= nil then
				tool.networkTimeInterpolator:reset()

				if tool.transSpeed ~= nil then
					local newTrans = streamReadFloat32(streamId)
					tool.curTrans[tool.translationAxis] = newTrans

					setTranslation(tool.node, unpack(tool.curTrans))
					tool.networkInterpolators.translation:setValue(tool.curTrans[tool.translationAxis])
				end

				if tool.rotSpeed ~= nil then
					local newRot = streamReadFloat32(streamId)
					tool.curRot[tool.rotationAxis] = newRot

					setRotation(tool.node, unpack(tool.curRot))
					tool.networkInterpolators.rotation:setAngle(newRot)
				end

				if tool.animSpeed ~= nil then
					local newAnimTime = streamReadFloat32(streamId)
					tool.curAnimTime = newAnimTime

					self:setAnimationTime(tool.animName, tool.curAnimTime, nil, false)
					tool.networkInterpolators.animation:setValue(newAnimTime)
				end

				if tool.delayedNode ~= nil then
					self:setDelayedData(tool, true)
				end

				Cylindered.setDirty(self, tool)
			end
		end
	end
end

function Cylindered:onWriteStream(streamId, connection)
	local spec = self.spec_cylindered

	if not connection:getIsServer() and streamWriteBool(streamId, self:allowLoadMovingToolStates()) then
		for i = 1, #spec.movingTools do
			local tool = spec.movingTools[i]

			if tool.dirtyFlag ~= nil then
				if tool.transSpeed ~= nil then
					streamWriteFloat32(streamId, tool.curTrans[tool.translationAxis])
				end

				if tool.rotSpeed ~= nil then
					streamWriteFloat32(streamId, tool.curRot[tool.rotationAxis])
				end

				if tool.animSpeed ~= nil then
					streamWriteFloat32(streamId, tool.curAnimTime)
				end
			end
		end
	end
end

function Cylindered:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_cylindered

	if not connection:getIsServer() then
		if streamReadBool(streamId) then
			for _, tool in ipairs(spec.movingTools) do
				if tool.axisActionIndex ~= nil then
					tool.move = (streamReadUIntN(streamId, 12) / 4095 * 2 - 1) * 5

					if math.abs(tool.move) < 0.01 then
						tool.move = 0
					end
				end
			end
		end
	elseif streamReadBool(streamId) then
		for _, tool in ipairs(spec.movingTools) do
			if tool.dirtyFlag ~= nil and streamReadBool(streamId) then
				tool.networkTimeInterpolator:startNewPhaseNetwork()

				if tool.transSpeed ~= nil then
					local newTrans = streamReadFloat32(streamId)

					if math.abs(newTrans - tool.curTrans[tool.translationAxis]) > 0.0001 then
						tool.networkInterpolators.translation:setTargetValue(newTrans)
					end
				end

				if tool.rotSpeed ~= nil then
					local newRot = nil

					if tool.rotMin == nil or tool.rotMax == nil then
						newRot = NetworkUtil.readCompressedAngle(streamId)
					else
						if tool.syncMinRotLimits then
							tool.rotMin = streamReadFloat32(streamId)
						end

						if tool.syncMaxRotLimits then
							tool.rotMax = streamReadFloat32(streamId)
						end

						tool.networkInterpolators.rotation:setMinMax(tool.rotMin, tool.rotMax)

						newRot = NetworkUtil.readCompressedRange(streamId, tool.rotMin, tool.rotMax, tool.rotSendNumBits)
					end

					if math.abs(newRot - tool.curRot[tool.rotationAxis]) > 0.0001 then
						tool.networkInterpolators.rotation:setTargetAngle(newRot)
					end
				end

				if tool.animSpeed ~= nil then
					local newAnimTime = NetworkUtil.readCompressedRange(streamId, tool.animMinTime, tool.animMaxTime, tool.animSendNumBits)

					if math.abs(newAnimTime - tool.curAnimTime) > 0.0001 then
						tool.networkInterpolators.animation:setTargetValue(newAnimTime)
					end
				end
			end
		end
	end
end

function Cylindered:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_cylindered

	if connection:getIsServer() then
		if streamWriteBool(streamId, bitAND(dirtyMask, spec.cylinderedInputDirtyFlag) ~= 0) then
			for _, tool in ipairs(spec.movingTools) do
				if tool.axisActionIndex ~= nil then
					local value = (MathUtil.clamp(tool.moveToSend / 5, -1, 1) + 1) / 2 * 4095

					streamWriteUIntN(streamId, value, 12)
				end
			end
		end
	elseif streamWriteBool(streamId, bitAND(dirtyMask, spec.cylinderedDirtyFlag) ~= 0) then
		for _, tool in ipairs(spec.movingTools) do
			if tool.dirtyFlag ~= nil and streamWriteBool(streamId, bitAND(dirtyMask, tool.dirtyFlag) ~= 0 and self:getIsMovingToolActive(tool)) then
				if tool.transSpeed ~= nil then
					streamWriteFloat32(streamId, tool.curTrans[tool.translationAxis])
				end

				if tool.rotSpeed ~= nil then
					local rot = tool.curRot[tool.rotationAxis]

					if tool.rotMin == nil or tool.rotMax == nil then
						NetworkUtil.writeCompressedAngle(streamId, rot)
					else
						if tool.syncMinRotLimits then
							streamWriteFloat32(streamId, tool.rotMin)
						end

						if tool.syncMaxRotLimits then
							streamWriteFloat32(streamId, tool.rotMax)
						end

						NetworkUtil.writeCompressedRange(streamId, rot, tool.rotMin, tool.rotMax, tool.rotSendNumBits)
					end
				end

				if tool.animSpeed ~= nil then
					NetworkUtil.writeCompressedRange(streamId, tool.curAnimTime, tool.animMinTime, tool.animMaxTime, tool.animSendNumBits)
				end
			end
		end
	end
end

function Cylindered:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_cylindered
	spec.movingToolNeedsSound = false
	spec.movingPartNeedsSound = false

	self:updateEasyControl(dt)

	if self.isServer then
		for i = 1, #spec.movingTools do
			local tool = spec.movingTools[i]
			local rotSpeed = 0
			local transSpeed = 0
			local animSpeed = 0
			local move = tool.move + tool.externalMove

			if math.abs(move) > 0 then
				tool.externalMove = 0

				if tool.rotSpeed ~= nil then
					rotSpeed = move * tool.rotSpeed

					if tool.rotAcceleration ~= nil and math.abs(rotSpeed - tool.lastRotSpeed) >= tool.rotAcceleration * dt then
						if tool.lastRotSpeed < rotSpeed then
							rotSpeed = tool.lastRotSpeed + tool.rotAcceleration * dt
						else
							rotSpeed = tool.lastRotSpeed - tool.rotAcceleration * dt
						end
					end
				end

				if tool.transSpeed ~= nil then
					transSpeed = move * tool.transSpeed

					if tool.transAcceleration ~= nil and math.abs(transSpeed - tool.lastTransSpeed) >= tool.transAcceleration * dt then
						if tool.lastTransSpeed < transSpeed then
							transSpeed = tool.lastTransSpeed + tool.transAcceleration * dt
						else
							transSpeed = tool.lastTransSpeed - tool.transAcceleration * dt
						end
					end
				end

				if tool.animSpeed ~= nil then
					animSpeed = move * tool.animSpeed

					if tool.animAcceleration ~= nil and math.abs(animSpeed - tool.lastAnimSpeed) >= tool.animAcceleration * dt then
						if tool.lastAnimSpeed < animSpeed then
							animSpeed = tool.lastAnimSpeed + tool.animAcceleration * dt
						else
							animSpeed = tool.lastAnimSpeed - tool.animAcceleration * dt
						end
					end
				end
			else
				if tool.rotAcceleration ~= nil then
					if tool.lastRotSpeed < 0 then
						rotSpeed = math.min(tool.lastRotSpeed + tool.rotAcceleration * dt, 0)
					else
						rotSpeed = math.max(tool.lastRotSpeed - tool.rotAcceleration * dt, 0)
					end
				end

				if tool.transAcceleration ~= nil then
					if tool.lastTransSpeed < 0 then
						transSpeed = math.min(tool.lastTransSpeed + tool.transAcceleration * dt, 0)
					else
						transSpeed = math.max(tool.lastTransSpeed - tool.transAcceleration * dt, 0)
					end
				end

				if tool.animAcceleration ~= nil then
					if tool.lastAnimSpeed < 0 then
						animSpeed = math.min(tool.lastAnimSpeed + tool.animAcceleration * dt, 0)
					else
						animSpeed = math.max(tool.lastAnimSpeed - tool.animAcceleration * dt, 0)
					end
				end
			end

			local changed = false

			if rotSpeed ~= nil and rotSpeed ~= 0 then
				changed = changed or Cylindered.setToolRotation(self, tool, rotSpeed, dt)
			else
				tool.lastRotSpeed = 0
			end

			if transSpeed ~= nil and transSpeed ~= 0 then
				changed = changed or Cylindered.setToolTranslation(self, tool, transSpeed, dt)
			else
				tool.lastTransSpeed = 0
			end

			if animSpeed ~= nil and animSpeed ~= 0 then
				changed = changed or Cylindered.setToolAnimation(self, tool, animSpeed, dt)
			else
				tool.lastAnimSpeed = 0
			end

			for _, dependentTool in pairs(tool.dependentMovingTools) do
				if dependentTool.speedScale ~= nil then
					local isAllowed = true

					if dependentTool.requiresMovement and not changed then
						isAllowed = false
					end

					if isAllowed then
						dependentTool.movingTool.externalMove = dependentTool.speedScale * tool.move
					end
				end

				Cylindered.updateRotationBasedLimits(self, tool, dependentTool)
				self:updateDependentToolLimits(tool, dependentTool)
			end

			if changed then
				if tool.playSound then
					spec.movingToolNeedsSound = true
				end

				Cylindered.setDirty(self, tool)

				tool.networkPositionIsDirty = true

				self:raiseDirtyFlags(tool.dirtyFlag)
				self:raiseDirtyFlags(spec.cylinderedDirtyFlag)

				tool.networkDirtyNextFrame = true

				if tool.isConsumingPower then
					spec.powerConsumingTimer = spec.powerConsumingActiveTimeOffset
				end
			elseif tool.networkDirtyNextFrame then
				self:raiseDirtyFlags(tool.dirtyFlag)
				self:raiseDirtyFlags(spec.cylinderedDirtyFlag)

				tool.networkDirtyNextFrame = nil
			end
		end
	else
		for i = 1, #spec.movingTools do
			local tool = spec.movingTools[i]

			tool.networkTimeInterpolator:update(dt)

			local interpolationAlpha = tool.networkTimeInterpolator:getAlpha()
			local changed = false

			if self:getIsMovingToolActive(tool) then
				if tool.rotSpeed ~= nil then
					local newRot = tool.networkInterpolators.rotation:getInterpolatedValue(interpolationAlpha)

					if math.abs(newRot - tool.curRot[tool.rotationAxis]) > 0.0001 then
						changed = true
						tool.curRot[tool.rotationAxis] = newRot

						setRotation(tool.node, tool.curRot[1], tool.curRot[2], tool.curRot[3])
					end
				end

				if tool.transSpeed ~= nil then
					local newTrans = tool.networkInterpolators.translation:getInterpolatedValue(interpolationAlpha)

					if math.abs(newTrans - tool.curTrans[tool.translationAxis]) > 0.0001 then
						changed = true
						tool.curTrans[tool.translationAxis] = newTrans

						setTranslation(tool.node, tool.curTrans[1], tool.curTrans[2], tool.curTrans[3])
					end
				end

				if tool.animSpeed ~= nil then
					local newAnimTime = tool.networkInterpolators.animation:getInterpolatedValue(interpolationAlpha)

					if math.abs(newAnimTime - tool.curAnimTime) > 0.0001 then
						changed = true
						tool.curAnimTime = newAnimTime

						self:setAnimationTime(tool.animName, newAnimTime, nil, true)
					end
				end

				if changed then
					Cylindered.setDirty(self, tool)
				end
			end

			for _, dependentTool in pairs(tool.dependentMovingTools) do
				if not dependentTool.movingTool.syncMinRotLimits or not dependentTool.movingTool.syncMaxRotLimits then
					self:updateDependentToolLimits(tool, dependentTool)
				end
			end

			if tool.networkTimeInterpolator:isInterpolating() then
				self:raiseActive()
			end
		end
	end

	for i = 1, #spec.movingTools do
		local tool = spec.movingTools[i]

		if tool.delayedHistoryIndex ~= nil and tool.delayedHistoryIndex > 0 then
			self:updateDelayedTool(tool)
		end

		if tool.smoothedMove ~= 0 and tool.lastInputTime + 50 < g_time then
			tool.smoothedMove = 0
		end
	end

	if spec.powerConsumingTimer > 0 then
		spec.powerConsumingTimer = spec.powerConsumingTimer - dt
	end

	if next(spec.activeSamples) ~= nil then
		self:raiseActive()
	end
end

function Cylindered:setDelayedData(tool, immediate)
	local x, y, z = getTranslation(tool.node)
	local rx, ry, rz = getRotation(tool.node)
	tool.delayedHistroyData[tool.delayedFrames] = {
		rot = {
			rx,
			ry,
			rz
		},
		trans = {
			x,
			y,
			z
		}
	}

	if immediate then
		for i = 1, tool.delayedFrames - 1 do
			tool.delayedHistroyData[i] = tool.delayedHistroyData[tool.delayedFrames]
		end
	end

	tool.delayedHistoryIndex = tool.delayedFrames
end

function Cylindered:updateDelayedTool(tool, forceLastPosition)
	local spec = self.spec_cylindered

	if forceLastPosition ~= nil and forceLastPosition then
		for i = 1, tool.delayedFrames - 1 do
			tool.delayedHistroyData[i] = tool.delayedHistroyData[tool.delayedFrames]
		end
	end

	local currentData = tool.delayedHistroyData[1]

	for i = 1, tool.delayedFrames - 1 do
		tool.delayedHistroyData[i] = tool.delayedHistroyData[i + 1]
	end

	setRotation(tool.delayedNode, unpack(currentData.rot))
	setTranslation(tool.delayedNode, unpack(currentData.trans))

	tool.delayedHistoryIndex = tool.delayedHistoryIndex - 1
	local movingPart = spec.nodesToMovingParts[tool.delayedNode]
	local movingTool = spec.nodesToMovingTools[tool.delayedNode]

	if movingPart ~= nil then
		Cylindered.setDirty(self, movingPart)
	end

	if spec.nodesToMovingTools[tool.delayedNode] ~= nil then
		Cylindered.setDirty(self, movingTool)
	end
end

function Cylindered:loadEasyArmControlFromXML(xmlFile, key, easyArmControl)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".xRotationNodes#maxDistance")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".xRotationNodes#transRotRatio")

	easyArmControl.rootNode = xmlFile:getValue(key .. "#rootNode", nil, self.components, self.i3dMappings)
	easyArmControl.targetNodeY = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	easyArmControl.targetNodeZ = xmlFile:getValue(key .. "#targetNodeZ", easyArmControl.targetNodeY, self.components, self.i3dMappings)
	easyArmControl.state = false

	if easyArmControl.targetNodeZ ~= nil and easyArmControl.targetNodeY ~= nil then
		local targetYTool = self:getMovingToolByNode(easyArmControl.targetNodeY)
		local targetZTool = self:getMovingToolByNode(easyArmControl.targetNodeZ)

		if targetYTool ~= nil and targetZTool ~= nil then
			easyArmControl.targetNode = easyArmControl.targetNodeZ

			if getParent(easyArmControl.targetNodeY) == easyArmControl.targetNodeZ then
				easyArmControl.targetNode = easyArmControl.targetNodeY
			end

			easyArmControl.targetRefNode = xmlFile:getValue(key .. "#refNode", nil, self.components, self.i3dMappings)
			easyArmControl.lastValidPositionY = {
				getTranslation(easyArmControl.targetNodeY)
			}
			easyArmControl.lastValidPositionZ = {
				getTranslation(easyArmControl.targetNodeZ)
			}
			easyArmControl.moveSpeed = xmlFile:getValue(key .. ".targetMovement#speed", 1) / 1000
			easyArmControl.moveAcceleration = xmlFile:getValue(key .. ".targetMovement#acceleration", 50) / 1000000
			easyArmControl.lastSpeedY = 0
			easyArmControl.lastSpeedZ = 0
			easyArmControl.minTransMoveRatio = xmlFile:getValue(key .. ".zTranslationNodes#minMoveRatio", 0.2)
			easyArmControl.maxTransMoveRatio = xmlFile:getValue(key .. ".zTranslationNodes#maxMoveRatio", 0.8)
			easyArmControl.transMoveRatioMinDir = xmlFile:getValue(key .. ".zTranslationNodes#moveRatioMinDir", 0)
			easyArmControl.transMoveRatioMaxDir = xmlFile:getValue(key .. ".zTranslationNodes#moveRatioMaxDir", 1)
			easyArmControl.allowNegativeTrans = xmlFile:getValue(key .. ".zTranslationNodes#allowNegativeTrans", false)
			easyArmControl.minNegativeTrans = xmlFile:getValue(key .. ".zTranslationNodes#minNegativeTrans", 0)
			easyArmControl.zTranslationNodes = {}
			local maxTrans = 0

			xmlFile:iterate(key .. ".zTranslationNodes.zTranslationNode", function (_, transKey)
				local node = xmlFile:getValue(transKey .. "#node", nil, self.components, self.i3dMappings)

				if node ~= nil then
					local movingTool = self:getMovingToolByNode(node)

					if movingTool ~= nil then
						local maxDistance = math.abs(movingTool.transMin - movingTool.transMax)
						maxTrans = maxTrans + maxDistance
						movingTool.easyArmControlActive = false

						table.insert(easyArmControl.zTranslationNodes, {
							transFactor = 0,
							node = node,
							movingTool = movingTool,
							maxDistance = maxDistance,
							startTranslation = {
								getTranslation(node)
							}
						})
					end
				end
			end)

			for _, translationNode in ipairs(easyArmControl.zTranslationNodes) do
				translationNode.transFactor = translationNode.maxDistance / maxTrans
			end

			easyArmControl.xRotationNodes = {}

			for i = 1, 2 do
				local xRotKey = string.format("%s.xRotationNodes.xRotationNode%d", key, i)

				if not xmlFile:hasProperty(xRotKey) then
					Logging.xmlWarning(xmlFile, "Missing second xRotation node for easy control!")

					return false
				end

				XMLUtil.checkDeprecatedXMLElements(xmlFile, xRotKey .. "#refNode")

				local node = xmlFile:getValue(xRotKey .. "#node", nil, self.components, self.i3dMappings)

				if node ~= nil then
					local movingTool = self:getMovingToolByNode(node)

					if movingTool ~= nil then
						movingTool.easyArmControlActive = false

						table.insert(easyArmControl.xRotationNodes, {
							node = node,
							movingTool = movingTool,
							startRotation = {
								getRotation(node)
							}
						})
					end
				end
			end

			if easyArmControl.targetRefNode ~= nil then
				local xOffset, yOffset, _ = localToLocal(easyArmControl.targetRefNode, easyArmControl.xRotationNodes[2].node, 0, 0, 0)

				if math.abs(xOffset) > 0.0001 or math.abs(yOffset) > 0.0001 then
					Logging.xmlWarning(xmlFile, "Invalid position of '%s'. Offset to second xRotation node is not 0 on X or Y axis (x: %f y: %f)", key .. "#refNode", xOffset, yOffset)

					return false
				end
			end

			local xOffset, yOffset, _ = localToLocal(easyArmControl.xRotationNodes[2].node, easyArmControl.xRotationNodes[1].node, 0, 0, 0)

			if math.abs(xOffset) > 0.0001 or math.abs(yOffset) > 0.0001 then
				Logging.xmlWarning(xmlFile, "Invalid position of xRotationNode2. Offset to second xRotationNode1 is not 0 on X or Y axis (x: %f y: %f)", xOffset, yOffset)

				return false
			end

			local rootOffset = calcDistanceFrom(easyArmControl.rootNode, easyArmControl.xRotationNodes[1].node)

			if rootOffset > 0.05 then
				Logging.xmlWarning(xmlFile, "Distance between easyArmControl rootNode and xRotationNode1 is to big (%.2f). They should be at the same position.", rootOffset)

				return false
			end

			easyArmControl.maxTotalDistance = xmlFile:getValue(key .. "#maxTotalDistance")

			if easyArmControl.maxTotalDistance == nil then
				for i = 1, #easyArmControl.xRotationNodes do
					local xRotationNode = easyArmControl.xRotationNodes[i]
					local curRot = {
						[xRotationNode.movingTool.rotationAxis] = xRotationNode.movingTool.rotMin,
						getRotation(xRotationNode.node)
					}

					setRotation(xRotationNode.node, curRot[1], curRot[2], curRot[3])
				end

				for i = 1, #easyArmControl.zTranslationNodes do
					local zTranslationNode = easyArmControl.zTranslationNodes[i]
					local curTrans = {
						[zTranslationNode.movingTool.translationAxis] = zTranslationNode.movingTool.transMax,
						getTranslation(zTranslationNode.node)
					}

					setTranslation(zTranslationNode.node, curTrans[1], curTrans[2], curTrans[3])
				end

				easyArmControl.maxTotalDistance = calcDistanceFrom(easyArmControl.rootNode, easyArmControl.targetRefNode)
				easyArmControl.maxTransDistance = calcDistanceFrom(easyArmControl.xRotationNodes[#easyArmControl.xRotationNodes].node, easyArmControl.targetRefNode)

				for i = 1, #easyArmControl.xRotationNodes do
					local xRotationNode = easyArmControl.xRotationNodes[i]

					setRotation(xRotationNode.node, xRotationNode.startRotation[1], xRotationNode.startRotation[2], xRotationNode.startRotation[3])
				end

				for i = 1, #easyArmControl.zTranslationNodes do
					local zTranslationNode = easyArmControl.zTranslationNodes[i]

					setTranslation(zTranslationNode.node, zTranslationNode.startTranslation[1], zTranslationNode.startTranslation[2], zTranslationNode.startTranslation[3])
				end
			end
		else
			Logging.xmlError(xmlFile, "Missing moving tools for easy control targets!")

			return false
		end
	else
		Logging.xmlError(xmlFile, "Missing easy control targets!")

		return false
	end

	return true
end

function Cylindered:updateEasyControl(dt, updateDelayedNodes)
	local spec = self.spec_cylindered
	local easyArmControl = spec.easyArmControl

	if easyArmControl ~= nil then
		local targetYTool = self:getMovingToolByNode(easyArmControl.targetNodeY)
		local targetZTool = self:getMovingToolByNode(easyArmControl.targetNodeZ)
		local hasChanged = false

		if targetYTool.move ~= 0 or targetZTool.move ~= 0 then
			hasChanged = true

			if targetYTool.move ~= 0 and targetYTool.isConsumingPower or targetZTool.move ~= 0 and targetZTool.isConsumingPower then
				spec.powerConsumingTimer = spec.powerConsumingActiveTimeOffset
			end
		end

		if self.isServer and easyArmControl.state and hasChanged then
			local transSpeedY = targetYTool.move * easyArmControl.moveSpeed

			if easyArmControl.moveAcceleration ~= nil and math.abs(transSpeedY - easyArmControl.lastSpeedY) >= easyArmControl.moveAcceleration * dt then
				if easyArmControl.lastSpeedY < transSpeedY then
					transSpeedY = easyArmControl.lastSpeedY + easyArmControl.moveAcceleration * dt
				else
					transSpeedY = easyArmControl.lastSpeedY - easyArmControl.moveAcceleration * dt
				end
			end

			local transSpeedZ = targetZTool.move * easyArmControl.moveSpeed

			if easyArmControl.moveAcceleration ~= nil and math.abs(transSpeedZ - easyArmControl.lastSpeedZ) >= easyArmControl.moveAcceleration * dt then
				if easyArmControl.lastSpeedZ < transSpeedZ then
					transSpeedZ = easyArmControl.lastSpeedZ + easyArmControl.moveAcceleration * dt
				else
					transSpeedZ = easyArmControl.lastSpeedZ - easyArmControl.moveAcceleration * dt
				end
			end

			easyArmControl.lastSpeedY = transSpeedY
			local moveY = transSpeedY * dt
			easyArmControl.lastSpeedZ = transSpeedZ
			local moveZ = transSpeedZ * dt
			local worldTargetDirX, worldTargetDirY, worldTargetDirZ = localDirectionToWorld(easyArmControl.rootNode, 0, moveY, moveZ)
			local worldTargetX, worldTargetY, worldTargetZ = getWorldTranslation(easyArmControl.targetRefNode)
			worldTargetZ = worldTargetZ + worldTargetDirZ
			worldTargetY = worldTargetY + worldTargetDirY
			worldTargetX = worldTargetX + worldTargetDirX
			local locTargetX, locTargetY, locTargetZ = worldToLocal(easyArmControl.rootNode, worldTargetX, worldTargetY, worldTargetZ)
			local distanceToTarget = MathUtil.vector3Length(locTargetX, locTargetY, locTargetZ)
			local targetExceedFactor = easyArmControl.maxTotalDistance / distanceToTarget

			if targetExceedFactor < 1 then
				locTargetZ = locTargetZ * targetExceedFactor
				locTargetY = locTargetY * targetExceedFactor
				locTargetX = locTargetX * targetExceedFactor
				worldTargetX, worldTargetY, worldTargetZ = localToWorld(easyArmControl.rootNode, locTargetX, locTargetY, locTargetZ)
				distanceToTarget = easyArmControl.maxTotalDistance
			end

			local circleDistance1 = MathUtil.vector3Length(localToLocal(easyArmControl.xRotationNodes[2].node, easyArmControl.xRotationNodes[1].node, 0, 0, 0))
			local _, _, circleDistance2 = localToLocal(easyArmControl.targetRefNode, easyArmControl.xRotationNodes[2].node, 0, 0, 0)
			local circle1X, circle1Y, circle1Z = localToLocal(easyArmControl.xRotationNodes[1].node, easyArmControl.rootNode, 0, 0, 0)
			local circle2X, circle2Y, circle2Z = worldToLocal(easyArmControl.rootNode, worldTargetX, worldTargetY, worldTargetZ)
			local numZTranslationNodes = #easyArmControl.zTranslationNodes

			if numZTranslationNodes > 0 then
				local inputDirY, inputDirZ = MathUtil.vector2Normalize(math.abs(moveY), math.abs(moveZ))

				if moveY == 0 and moveZ == 0 then
					inputDirZ = 0
					inputDirY = 0
				end

				local transDirX, transDirY, transDirZ = localDirectionToWorld(easyArmControl.zTranslationNodes[1].node, 0, 0, 1)
				transDirX, transDirY, transDirZ = worldDirectionToLocal(easyArmControl.rootNode, transDirX, transDirY, transDirZ)
				local difference = math.acos(MathUtil.dotProduct(0, inputDirY, inputDirZ, 0, transDirY, transDirZ))

				if difference > math.pi * 0.5 then
					difference = -difference + math.pi
				end

				local rotTransRatio = 1 - difference / (math.pi * 0.5)
				rotTransRatio = (rotTransRatio - easyArmControl.transMoveRatioMinDir) / (easyArmControl.transMoveRatioMaxDir - easyArmControl.transMoveRatioMinDir)
				rotTransRatio = MathUtil.clamp(rotTransRatio, easyArmControl.minTransMoveRatio, easyArmControl.maxTransMoveRatio)
				local _, _, targetZOffset = worldToLocal(easyArmControl.xRotationNodes[2].node, worldTargetX, worldTargetY, worldTargetZ)
				local zDifference = targetZOffset - circleDistance2
				local minTransPct = 0

				if not easyArmControl.allowNegativeTrans and transDirZ < 0 then
					if zDifference > 0 then
						rotTransRatio = -2
					end

					minTransPct = easyArmControl.minNegativeTrans * -transDirZ
				end

				local transMove = zDifference * rotTransRatio

				for i = 1, numZTranslationNodes do
					local zTranslationNode = easyArmControl.zTranslationNodes[i]
					local movingTool = zTranslationNode.movingTool
					local delta = transMove / numZTranslationNodes
					local currentTrans = movingTool.curTrans[movingTool.translationAxis]
					local transMin = (movingTool.transMax - movingTool.transMin) * minTransPct + movingTool.transMin
					local newTrans = MathUtil.clamp(currentTrans + delta, transMin, movingTool.transMax)
					local newDelta = newTrans - currentTrans

					Cylindered.setAbsoluteToolTranslation(self, movingTool, currentTrans + newDelta)
				end

				circleDistance2 = MathUtil.vector3Length(worldToLocal(easyArmControl.xRotationNodes[2].node, getWorldTranslation(easyArmControl.targetRefNode)))
			end

			local ix, iy, i2x, i2y = MathUtil.getCircleCircleIntersection(circle1Z, circle1Y, circleDistance1, circle2Z, circle2Y, circleDistance2)

			if ix ~= nil and iy ~= nil then
				local node1Tool = easyArmControl.xRotationNodes[1].movingTool
				local node2Tool = easyArmControl.xRotationNodes[2].movingTool
				local node1Rotation = -math.atan2(iy, ix)
				local node1RotationClamped = MathUtil.clamp(node1Rotation, node1Tool.rotMin, node1Tool.rotMax)
				local node1Overrun = 0

				Cylindered.setAbsoluteToolRotation(self, easyArmControl.xRotationNodes[1].movingTool, node1RotationClamped, updateDelayedNodes)

				local node2Rotation = math.pi - math.acos((circleDistance1 * circleDistance1 + circleDistance2 * circleDistance2 - distanceToTarget * distanceToTarget) / (2 * circleDistance1 * circleDistance2))
				local node2RotationClamped = MathUtil.clamp(node2Rotation + node1Overrun, node2Tool.rotMin, node2Tool.rotMax)
				local node2Overrun = node2Rotation - node2RotationClamped

				Cylindered.setAbsoluteToolRotation(self, easyArmControl.xRotationNodes[2].movingTool, node2RotationClamped, updateDelayedNodes)

				node1RotationClamped = MathUtil.clamp(node1RotationClamped + node2Overrun * 0.5, node1Tool.rotMin, node1Tool.rotMax)

				Cylindered.setAbsoluteToolRotation(self, easyArmControl.xRotationNodes[1].movingTool, node1RotationClamped, updateDelayedNodes)
			end
		end
	end
end

function Cylindered:setIsEasyControlActive(state)
	local spec = self.spec_cylindered

	if self.isServer then
		local easyArmControl = spec.easyArmControl

		if easyArmControl ~= nil then
			local targetYTool = self:getMovingToolByNode(easyArmControl.targetNodeY)
			local targetZTool = self:getMovingToolByNode(easyArmControl.targetNodeZ)

			if state then
				local origin = getParent(easyArmControl.targetNodeY)

				if origin == easyArmControl.targetNodeZ then
					origin = getParent(easyArmControl.targetNodeZ)
				end

				local _, y, _ = localToLocal(easyArmControl.targetRefNode, origin, 0, 0, 0)
				local _, oldY, _ = getTranslation(easyArmControl.targetNodeY)

				if Cylindered.setToolTranslation(self, targetYTool, nil, 0, y - oldY) then
					Cylindered.setDirty(self, targetYTool)
				end

				local z = nil
				_, _, z = localToLocal(easyArmControl.targetRefNode, origin, 0, 0, 0)
				local _, _, oldZ = getTranslation(easyArmControl.targetNodeZ)

				if Cylindered.setToolTranslation(self, targetZTool, nil, 0, z - oldZ) then
					Cylindered.setDirty(self, targetZTool)
				end

				easyArmControl.lastValidPositionY[1], easyArmControl.lastValidPositionY[2], easyArmControl.lastValidPositionY[3] = getTranslation(easyArmControl.targetNodeY)
				easyArmControl.lastValidPositionZ[1], easyArmControl.lastValidPositionZ[2], easyArmControl.lastValidPositionZ[3] = getTranslation(easyArmControl.targetNodeZ)

				self:raiseDirtyFlags(spec.cylinderedDirtyFlag)
			end

			easyArmControl.state = state
		end
	end

	self:requestActionEventUpdate()
end

function Cylindered:updateExtraDependentParts(part, dt)
end

function Cylindered:updateDependentAnimations(part, dt)
	if #part.dependentAnimations > 0 then
		for _, dependentAnimation in ipairs(part.dependentAnimations) do
			local pos = 0

			if dependentAnimation.translationAxis ~= nil then
				local retValues = {
					getTranslation(dependentAnimation.node)
				}
				pos = (retValues[dependentAnimation.translationAxis] - dependentAnimation.minValue) / (dependentAnimation.maxValue - dependentAnimation.minValue)
			end

			if dependentAnimation.rotationAxis ~= nil then
				local retValues = {
					getRotation(dependentAnimation.node)
				}
				pos = (retValues[dependentAnimation.rotationAxis] - dependentAnimation.minValue) / (dependentAnimation.maxValue - dependentAnimation.minValue)
			end

			pos = MathUtil.clamp(math.abs(pos), 0, 1)

			if dependentAnimation.invert then
				pos = 1 - pos
			end

			dependentAnimation.lastPos = pos

			self:setAnimationTime(dependentAnimation.name, pos, true)
		end
	end
end

function Cylindered:updateDependentToolLimits(tool, dependentTool)
	if dependentTool.minTransLimits ~= nil or dependentTool.maxTransLimits ~= nil then
		local state = Cylindered.getMovingToolState(self, tool)

		if dependentTool.minTransLimits ~= nil then
			dependentTool.movingTool.transMin = MathUtil.lerp(dependentTool.minTransLimits[1], dependentTool.minTransLimits[2], 1 - state)
		end

		if dependentTool.maxTransLimits ~= nil then
			dependentTool.movingTool.transMax = MathUtil.lerp(dependentTool.maxTransLimits[1], dependentTool.maxTransLimits[2], 1 - state)
		end

		local transLimitChanged = Cylindered.setToolTranslation(self, dependentTool.movingTool, 0, 0)

		if transLimitChanged then
			Cylindered.setDirty(self, dependentTool.movingTool)
		end
	end

	if dependentTool.minRotLimits ~= nil or dependentTool.maxRotLimits ~= nil then
		local state = Cylindered.getMovingToolState(self, tool)

		if dependentTool.minRotLimits ~= nil then
			dependentTool.movingTool.rotMin = MathUtil.lerp(dependentTool.minRotLimits[1], dependentTool.minRotLimits[2], 1 - state)
		end

		if dependentTool.maxRotLimits ~= nil then
			dependentTool.movingTool.rotMax = MathUtil.lerp(dependentTool.maxRotLimits[1], dependentTool.maxRotLimits[2], 1 - state)
		end

		dependentTool.movingTool.networkInterpolators.rotation:setMinMax(dependentTool.movingTool.rotMin, dependentTool.movingTool.rotMax)

		local rotLimitChanged = Cylindered.setToolRotation(self, dependentTool.movingTool, 0, 0)

		if rotLimitChanged then
			Cylindered.setDirty(self, dependentTool.movingTool)
		end
	end
end

function Cylindered:onMovingPartSoundEvent(part, action, type)
	if part.samplesByAction ~= nil then
		local samples = part.samplesByAction[action]

		if samples ~= nil then
			for i = 1, #samples do
				local sample = samples[i]

				if type == Cylindered.SOUND_TYPE_EVENT then
					if sample.loops == 0 then
						sample.loops = 1
					end

					g_soundManager:playSample(sample)
				elseif type == Cylindered.SOUND_TYPE_CONTINUES then
					if not g_soundManager:getIsSamplePlaying(sample) then
						g_soundManager:playSample(sample)

						sample.lastActivationTime = g_time
						sample.lastActivationPart = part
						local spec = self.spec_cylindered

						table.insert(spec.activeSamples, sample)
					elseif sample.lastActivationPart == part then
						sample.lastActivationTime = g_time
					end
				elseif type == Cylindered.SOUND_TYPE_ENDING then
					local spec = self.spec_cylindered

					if spec.endingSamplesBySample[sample] == nil then
						sample.lastActivationTime = g_time

						table.insert(spec.endingSamples, sample)

						spec.endingSamplesBySample[sample] = sample
					else
						sample.lastActivationTime = g_time
					end
				elseif type == Cylindered.SOUND_TYPE_STARTING then
					local spec = self.spec_cylindered

					if spec.startingSamplesBySample[sample] == nil then
						if sample.loops == 0 then
							sample.loops = 1
						end

						g_soundManager:playSample(sample)

						sample.lastActivationTime = g_time

						table.insert(spec.startingSamples, sample)

						spec.startingSamplesBySample[sample] = sample
					else
						sample.lastActivationTime = g_time
					end
				end
			end
		end
	end
end

function Cylindered:updateMovingToolSoundEvents(tool, direction, hitLimit, wasAtLimit)
	if tool.samplesByAction ~= nil then
		self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END, Cylindered.SOUND_TYPE_ENDING)
		self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START, Cylindered.SOUND_TYPE_STARTING)

		if direction then
			self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_POS, Cylindered.SOUND_TYPE_CONTINUES)
			self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END_POS, Cylindered.SOUND_TYPE_ENDING)
			self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START_POS, Cylindered.SOUND_TYPE_STARTING)

			if hitLimit then
				self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END_POS_LIMIT, Cylindered.SOUND_TYPE_ENDING)
			end

			if wasAtLimit then
				self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START_POS_LIMIT, Cylindered.SOUND_TYPE_STARTING)
			end
		else
			self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_NEG, Cylindered.SOUND_TYPE_CONTINUES)
			self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END_NEG, Cylindered.SOUND_TYPE_ENDING)
			self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START_NEG, Cylindered.SOUND_TYPE_STARTING)

			if hitLimit then
				self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_END_NEG_LIMIT, Cylindered.SOUND_TYPE_ENDING)
			end

			if wasAtLimit then
				self:onMovingPartSoundEvent(tool, Cylindered.SOUND_ACTION_TOOL_MOVE_START_NEG_LIMIT, Cylindered.SOUND_TYPE_STARTING)
			end
		end
	end
end

function Cylindered:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_cylindered

		for _, movingTool in pairs(spec.movingTools) do
			if movingTool.axisActionIndex ~= nil and spec.currentControlGroupIndex == movingTool.controlGroupIndex then
				local actionEvent = spec.actionEvents[movingTool.axisActionIndex]

				if actionEvent ~= nil then
					g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:getIsMovingToolActive(movingTool))
				end
			end
		end

		for i = #spec.activeSamples, 1, -1 do
			local sample = spec.activeSamples[i]

			if sample.lastActivationTime + dt * 3 < g_time then
				if g_time <= sample.lastActivationTime + dt * 3 + sample.dropOffTime then
					if not sample.dropOffActive then
						sample.dropOffActive = true

						g_soundManager:setSamplePitchOffset(sample, g_soundManager:getCurrentSamplePitch(sample) * (sample.dropOffFactor - 1))
					end
				else
					sample.dropOffActive = false

					g_soundManager:setSamplePitchOffset(sample, 0)
					g_soundManager:stopSample(sample)
					table.remove(spec.activeSamples, i)
				end
			end
		end

		for i = #spec.endingSamples, 1, -1 do
			local sample = spec.endingSamples[i]

			if sample.lastActivationTime + dt < g_time then
				if sample.loops == 0 then
					sample.loops = 1
				end

				g_soundManager:playSample(sample)
				table.remove(spec.endingSamples, i)

				spec.endingSamplesBySample[sample] = nil
			end
		end

		for i = #spec.startingSamples, 1, -1 do
			local sample = spec.startingSamples[i]

			if sample.lastActivationTime + dt < g_time then
				table.remove(spec.startingSamples, i)

				spec.startingSamplesBySample[sample] = nil
			end
		end
	end
end

function Cylindered:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_cylindered

	for _, part in pairs(spec.activeDirtyMovingParts) do
		Cylindered.setDirty(self, part)
	end

	self:updateDirtyMovingParts(dt, true)
end

function Cylindered:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_cylindered

	for _, part in pairs(spec.activeDirtyMovingParts) do
		if self.currentUpdateDistance < part.maxUpdateDistance then
			Cylindered.setDirty(self, part)
		end
	end

	self:updateDirtyMovingParts(dt, true)
end

function Cylindered:onPostUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	self:updateDirtyMovingParts(dt, false)
end

function Cylindered:updateDirtyMovingParts(dt, updateSound)
	local spec = self.spec_cylindered

	for _, tool in pairs(spec.movingTools) do
		if tool.isDirty then
			if tool.playSound then
				spec.movingToolNeedsSound = true
			end

			if self.isServer then
				Cylindered.updateComponentJoints(self, tool, false)
			end

			self:updateExtraDependentParts(tool, dt)
			self:updateDependentAnimations(tool, dt)

			tool.isDirty = false
		end
	end

	if self.anyMovingPartsDirty then
		for i, part in ipairs(spec.movingParts) do
			if part.isDirty then
				local isActive = self:getIsMovingPartActive(part)

				if isActive or part.smoothedDirectionScale and part.smoothedDirectionScaleAlpha ~= 0 then
					Cylindered.updateMovingPart(self, part, false, nil, isActive)
					self:updateExtraDependentParts(part, dt)
					self:updateDependentAnimations(part, dt)

					if part.playSound then
						spec.cylinderedHydraulicSoundPartNumber = i
						spec.movingPartNeedsSound = true
					end
				end
			elseif spec.isClient and spec.cylinderedHydraulicSoundPartNumber == i then
				spec.movingPartNeedsSound = false
			end
		end

		self.anyMovingPartsDirty = false
	end

	if updateSound and self.isClient then
		if spec.movingToolNeedsSound or spec.movingPartNeedsSound then
			if not spec.isHydraulicSamplePlaying then
				g_soundManager:playSample(spec.samples.hydraulic)

				spec.isHydraulicSamplePlaying = true
			end

			self:raiseActive()
		elseif spec.isHydraulicSamplePlaying then
			g_soundManager:stopSample(spec.samples.hydraulic)

			spec.isHydraulicSamplePlaying = false
		end
	end
end

function Cylindered:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_cylindered

	if #spec.controlGroupNames > 1 and isActiveForInputIgnoreSelection and spec.currentControlGroupIndex ~= 0 then
		g_currentMission:addExtraPrintText(string.format(g_i18n:getText("action_selectedControlGroup"), spec.controlGroupNames[spec.currentControlGroupIndex], spec.currentControlGroupIndex))
	end
end

function Cylindered:loadMovingPartFromXML(xmlFile, key, entry)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")

	local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	local referenceFrame = xmlFile:getValue(key .. "#referenceFrame", nil, self.components, self.i3dMappings)

	if node ~= nil and referenceFrame ~= nil then
		entry.referencePoint = xmlFile:getValue(key .. "#referencePoint", nil, self.components, self.i3dMappings)
		entry.node = node
		entry.parent = getParent(node)
		entry.referenceFrame = referenceFrame
		entry.invertZ = xmlFile:getValue(key .. "#invertZ", false)
		entry.scaleZ = xmlFile:getValue(key .. "#scaleZ", false)
		entry.limitedAxis = xmlFile:getValue(key .. "#limitedAxis")
		entry.isActiveDirty = xmlFile:getValue(key .. "#isActiveDirty", false)
		entry.playSound = xmlFile:getValue(key .. "#playSound", false)
		entry.moveToReferenceFrame = xmlFile:getValue(key .. "#moveToReferenceFrame", false)

		if entry.moveToReferenceFrame then
			local x, y, z = worldToLocal(referenceFrame, getWorldTranslation(node))
			entry.referenceFrameOffset = {
				x,
				y,
				z
			}
		end

		if entry.referenceFrame == entry.node then
			Logging.xmlWarning(xmlFile, "Reference frame equals moving part node. This can lead to bad behaviours! Node '%s' in '%s'.", getName(entry.node), key)
		end

		entry.doLineAlignment = xmlFile:getValue(key .. "#doLineAlignment", false)
		entry.doInversedLineAlignment = xmlFile:getValue(key .. "#doInversedLineAlignment", false)
		entry.partLength = xmlFile:getValue(key .. ".orientationLine#partLength", 0.5)
		entry.orientationLineNodes = {}
		local i = 0

		while true do
			local pointKey = string.format("%s.orientationLine.lineNode(%d)", key, i)

			if not xmlFile:hasProperty(pointKey) then
				break
			end

			local lineNode = xmlFile:getValue(pointKey .. "#node", nil, self.components, self.i3dMappings)

			table.insert(entry.orientationLineNodes, lineNode)

			i = i + 1
		end

		entry.doDirectionAlignment = xmlFile:getValue(key .. "#doDirectionAlignment", true)
		entry.doRotationAlignment = xmlFile:getValue(key .. "#doRotationAlignment", false)
		entry.rotMultiplier = xmlFile:getValue(key .. "#rotMultiplier", 0)
		local minRot = xmlFile:getValue(key .. "#minRot")
		local maxRot = xmlFile:getValue(key .. "#maxRot")

		if minRot ~= nil and maxRot ~= nil then
			if entry.limitedAxis ~= nil then
				entry.minRot = MathUtil.getValidLimit(minRot)
				entry.maxRot = MathUtil.getValidLimit(maxRot)
			else
				print("Warning: minRot/maxRot requires the use of limitedAxis in '" .. self.configFileName .. "'")
			end
		end

		entry.alignToWorldY = xmlFile:getValue(key .. "#alignToWorldY", false)

		if entry.referencePoint ~= nil then
			local localReferencePoint = xmlFile:getValue(key .. "#localReferencePoint", nil, self.components, self.i3dMappings)
			local refX, refY, refZ = worldToLocal(node, getWorldTranslation(entry.referencePoint))

			if localReferencePoint ~= nil then
				local x, y, z = worldToLocal(node, getWorldTranslation(localReferencePoint))
				entry.referenceDistance = MathUtil.vector3Length(refX - x, refY - y, refZ - z)
				entry.lastReferenceDistance = entry.referenceDistance
				entry.localReferencePoint = {
					x,
					y,
					z
				}
				local side = y * (refZ - z) - z * (refY - y)
				entry.localReferenceAngleSide = side
				entry.localReferencePointNode = localReferencePoint
				entry.updateLocalReferenceDistance = xmlFile:getValue(key .. "#updateLocalReferenceDistance", false)
				entry.localReferenceTranslate = xmlFile:getValue(key .. "#localReferenceTranslate", false)

				if entry.localReferenceTranslate then
					entry.localReferenceTranslation = {
						getTranslation(entry.node)
					}
				end

				entry.dynamicLocalReferenceDistance = xmlFile:getValue(key .. "#dynamicLocalReferenceDistance", false)
			else
				entry.referenceDistance = 0
				entry.localReferencePoint = {
					refX,
					refY,
					refZ
				}
			end

			entry.referenceDistanceThreshold = xmlFile:getValue(key .. "#referenceDistanceThreshold", 0)
			entry.useLocalOffset = xmlFile:getValue(key .. "#useLocalOffset", false)
			entry.referenceDistancePoint = xmlFile:getValue(key .. "#referenceDistancePoint", nil, self.components, self.i3dMappings)
			entry.localReferenceDistance = xmlFile:getValue(key .. "#localReferenceDistance", MathUtil.vector2Length(entry.localReferencePoint[2], entry.localReferencePoint[3]))

			self:loadDependentTranslatingParts(xmlFile, key, entry)
		end

		entry.directionThreshold = xmlFile:getValue(key .. "#directionThreshold", 0.0001)
		entry.directionThresholdActive = xmlFile:getValue(key .. "#directionThresholdActive", 1e-05)
		entry.maxUpdateDistance = xmlFile:getValue(key .. "#maxUpdateDistance", "-")

		if entry.maxUpdateDistance == "-" then
			entry.maxUpdateDistance = math.huge
		else
			entry.maxUpdateDistance = tonumber(entry.maxUpdateDistance)
		end

		if entry.isActiveDirty and (xmlFile:getString(key .. "#maxUpdateDistance") == nil or entry.maxUpdateDistance == nil) then
			Logging.xmlWarning(xmlFile, "No max. update distance set for isActiveDirty moving part (%s)! Use #maxUpdateDistance attribute.", key)
		end

		entry.smoothedDirectionScale = self.xmlFile:getValue(key .. "#smoothedDirectionScale", false)
		entry.smoothedDirectionTime = 1 / self.xmlFile:getValue(key .. "#smoothedDirectionTime", 2)
		entry.smoothedDirectionScaleAlpha = nil

		if entry.smoothedDirectionScale then
			entry.initialDirection = {
				localDirectionToLocal(entry.node, getParent(entry.node), 0, 0, 1)
			}
		end

		entry.debug = xmlFile:getValue(key .. "#debug", false)

		if entry.debug then
			Logging.xmlWarning(xmlFile, "MovingPart debug enabled for moving part '%s'", key)
		end

		entry.lastDirection = {
			0,
			0,
			0
		}
		entry.lastUpVector = {
			0,
			0,
			0
		}
		entry.isDirty = false
		entry.isPart = true
		entry.isActive = true

		return true
	end

	return false
end

function Cylindered:loadMovingToolFromXML(xmlFile, key, entry)
	local spec = self.spec_cylindered

	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")

	local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if node ~= nil then
		entry.node = node
		entry.externalMove = 0
		entry.easyArmControlActive = true
		entry.isEasyControlTarget = xmlFile:getValue(key .. "#isEasyControlTarget", false)
		entry.networkInterpolators = {}

		XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#rotSpeed", key .. ".rotation#rotSpeed")

		local rotSpeed = xmlFile:getValue(key .. ".rotation#rotSpeed")

		if rotSpeed ~= nil then
			entry.rotSpeed = rotSpeed / 1000
		end

		local rotAcceleration = xmlFile:getValue(key .. ".rotation#rotAcceleration")

		if rotAcceleration ~= nil then
			entry.rotAcceleration = rotAcceleration / 1000000
		end

		entry.lastRotSpeed = 0
		entry.rotMax = xmlFile:getValue(key .. ".rotation#rotMax")
		entry.rotMin = xmlFile:getValue(key .. ".rotation#rotMin")
		entry.syncMaxRotLimits = xmlFile:getValue(key .. ".rotation#syncMaxRotLimits", false)
		entry.syncMinRotLimits = xmlFile:getValue(key .. ".rotation#syncMinRotLimits", false)
		entry.rotSendNumBits = xmlFile:getValue(key .. ".rotation#rotSendNumBits", 8)
		entry.attachRotMax = xmlFile:getValue(key .. ".rotation#attachRotMax")
		entry.attachRotMin = xmlFile:getValue(key .. ".rotation#attachRotMin")

		XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#transSpeed", key .. ".rotation#transSpeed")

		local transSpeed = xmlFile:getValue(key .. ".translation#transSpeed")

		if transSpeed ~= nil then
			entry.transSpeed = transSpeed / 1000
		end

		local transAcceleration = xmlFile:getValue(key .. ".translation#transAcceleration")

		if transAcceleration ~= nil then
			entry.transAcceleration = transAcceleration / 1000000
		end

		entry.lastTransSpeed = 0
		entry.transMax = xmlFile:getValue(key .. ".translation#transMax")
		entry.transMin = xmlFile:getValue(key .. ".translation#transMin")
		entry.attachTransMax = xmlFile:getValue(key .. ".translation#attachTransMax")
		entry.attachTransMin = xmlFile:getValue(key .. ".translation#attachTransMin")
		entry.playSound = xmlFile:getValue(key .. "#playSound", false)
		entry.isConsumingPower = xmlFile:getValue(key .. "#isConsumingPower", false)

		if SpecializationUtil.hasSpecialization(AnimatedVehicle, self.specializations) then
			local animSpeed = xmlFile:getValue(key .. ".animation#animSpeed")

			if animSpeed ~= nil then
				entry.animSpeed = animSpeed / 1000
			end

			local animAcceleration = xmlFile:getValue(key .. ".animation#animAcceleration")

			if animAcceleration ~= nil then
				entry.animAcceleration = animAcceleration / 1000000
			end

			entry.curAnimTime = 0
			entry.lastAnimSpeed = 0
			entry.animName = xmlFile:getValue(key .. ".animation#animName")
			entry.animSendNumBits = xmlFile:getValue(key .. ".animation#animSendNumBits", 8)
			entry.animMaxTime = math.min(xmlFile:getValue(key .. ".animation#animMaxTime", 1), 1)
			entry.animMinTime = math.max(xmlFile:getValue(key .. ".animation#animMinTime", 0), 0)
			entry.animStartTime = xmlFile:getValue(key .. ".animation#animStartTime")

			if entry.animStartTime ~= nil then
				entry.curAnimTime = entry.animStartTime
			end

			entry.networkInterpolators.animation = InterpolatorValue.new(entry.curAnimTime)

			entry.networkInterpolators.animation:setMinMax(0, 1)
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".controls#iconFilename", key .. ".controls#iconName")

		local iconName = xmlFile:getValue(key .. ".controls#iconName")

		if iconName ~= nil then
			if InputHelpElement.AXIS_ICON[iconName] == nil then
				iconName = (self.customEnvironment or "") .. iconName
			end

			entry.axisActionIcon = iconName
		end

		entry.controlGroupIndex = xmlFile:getValue(key .. ".controls#groupIndex", 0)

		if entry.controlGroupIndex ~= 0 then
			if spec.controlGroupNames[entry.controlGroupIndex] ~= nil then
				table.addElement(spec.controlGroups, entry.controlGroupIndex)
			else
				Logging.xmlWarning(xmlFile, "ControlGroup '%d' not defined for '%s'!", entry.controlGroupIndex, key)
			end
		end

		entry.axis = xmlFile:getValue(key .. ".controls#axis")

		if entry.axis ~= nil then
			entry.axisActionIndex = InputAction[entry.axis]
		end

		entry.invertAxis = xmlFile:getValue(key .. ".controls#invertAxis", false)
		entry.mouseSpeedFactor = xmlFile:getValue(key .. ".controls#mouseSpeedFactor", 1)

		if entry.rotSpeed ~= nil or entry.transSpeed ~= nil or entry.animSpeed ~= nil then
			entry.dirtyFlag = self:getNextDirtyFlag()
			entry.saving = xmlFile:getValue(key .. "#allowSaving", true)
		end

		entry.isDirty = false
		entry.isIntitialDirty = xmlFile:getValue(key .. "#isIntitialDirty", true)
		entry.rotationAxis = xmlFile:getValue(key .. ".rotation#rotationAxis", 1)
		entry.translationAxis = xmlFile:getValue(key .. ".translation#translationAxis", 3)
		local detachingRotMaxLimit = xmlFile:getValue(key .. ".rotation#detachingRotMaxLimit")
		local detachingRotMinLimit = xmlFile:getValue(key .. ".rotation#detachingRotMinLimit")
		local detachingTransMaxLimit = xmlFile:getValue(key .. ".translation#detachingTransMaxLimit")
		local detachingTransMinLimit = xmlFile:getValue(key .. ".translation#detachingTransMinLimit")

		if detachingRotMaxLimit ~= nil or detachingRotMinLimit ~= nil or detachingTransMaxLimit ~= nil or detachingTransMinLimit ~= nil then
			if spec.detachLockNodes == nil then
				spec.detachLockNodes = {}
			end

			local detachLock = {
				detachingRotMaxLimit = detachingRotMaxLimit,
				detachingRotMinLimit = detachingRotMinLimit,
				detachingTransMinLimit = detachingTransMinLimit,
				detachingTransMaxLimit = detachingTransMaxLimit
			}
			spec.detachLockNodes[entry] = detachLock
		end

		local rx, ry, rz = getRotation(node)
		entry.curRot = {
			rx,
			ry,
			rz
		}
		local x, y, z = getTranslation(node)
		entry.curTrans = {
			x,
			y,
			z
		}
		entry.startRot = xmlFile:getValue(key .. ".rotation#startRot")
		entry.startTrans = xmlFile:getValue(key .. ".translation#startTrans")
		entry.move = 0
		entry.moveToSend = 0
		entry.smoothedMove = 0
		entry.lastInputTime = 0

		XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#delayedIndex", key .. "#delayedNode")

		entry.delayedNode = xmlFile:getValue(key .. "#delayedNode", nil, self.components, self.i3dMappings)

		if entry.delayedNode ~= nil then
			entry.delayedFrames = xmlFile:getValue(key .. "#delayedFrames", 3)
			entry.currentDelayedData = {
				rot = {
					rx,
					ry,
					rz
				},
				trans = {
					x,
					y,
					z
				}
			}
			entry.delayedHistroyData = {}

			for i = 1, entry.delayedFrames do
				entry.delayedHistroyData[i] = {
					rot = {
						rx,
						ry,
						rz
					},
					trans = {
						x,
						y,
						z
					}
				}
			end

			entry.delayedHistoryIndex = 0
		end

		entry.networkInterpolators.translation = InterpolatorValue.new(entry.curTrans[entry.translationAxis])

		entry.networkInterpolators.translation:setMinMax(entry.transMin, entry.transMax)

		entry.networkInterpolators.rotation = InterpolatorAngle.new(entry.curRot[entry.rotationAxis])

		entry.networkInterpolators.rotation:setMinMax(entry.rotMin, entry.rotMax)

		entry.networkTimeInterpolator = InterpolationTime.new(1.2)
		entry.isTool = true

		return true
	end

	return false
end

function Cylindered:loadDependentMovingTools(xmlFile, baseName, entry)
	entry.dependentMovingTools = {}
	local j = 0

	while true do
		local refBaseName = baseName .. string.format(".dependentMovingTool(%d)", j)

		if not xmlFile:hasProperty(refBaseName) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, refBaseName .. "#index", refBaseName .. "#index")

		local node = xmlFile:getValue(refBaseName .. "#node", nil, self.components, self.i3dMappings)
		local speedScale = xmlFile:getValue(refBaseName .. "#speedScale")
		local requiresMovement = xmlFile:getValue(refBaseName .. "#requiresMovement", false)
		local rotationBasedLimits = AnimCurve.new(Cylindered.limitInterpolator)
		local found = false
		local i = 0

		while true do
			local key = string.format("%s.limit(%d)", refBaseName .. ".rotationBasedLimits", i)

			if not xmlFile:hasProperty(key) then
				break
			end

			local keyFrame = self:loadRotationBasedLimits(xmlFile, key, entry)

			if keyFrame ~= nil then
				rotationBasedLimits:addKeyframe(keyFrame)

				found = true
			end

			i = i + 1
		end

		if not found then
			rotationBasedLimits = nil
		end

		local minTransLimits = xmlFile:getValue(refBaseName .. "#minTransLimits", nil, true)
		local maxTransLimits = xmlFile:getValue(refBaseName .. "#maxTransLimits", nil, true)
		local minRotLimits = xmlFile:getValue(refBaseName .. "#minRotLimits", nil, true)
		local maxRotLimits = xmlFile:getValue(refBaseName .. "#maxRotLimits", nil, true)

		if node ~= nil and (rotationBasedLimits ~= nil or speedScale ~= nil or minTransLimits ~= nil or maxTransLimits ~= nil or minRotLimits ~= nil or maxRotLimits ~= nil) then
			local dependentTool = {
				node = node,
				rotationBasedLimits = rotationBasedLimits,
				speedScale = speedScale,
				requiresMovement = requiresMovement,
				minTransLimits = minTransLimits,
				maxTransLimits = maxTransLimits,
				minRotLimits = minRotLimits,
				maxRotLimits = maxRotLimits
			}

			table.insert(entry.dependentMovingTools, dependentTool)
		end

		j = j + 1
	end
end

function Cylindered:loadDependentParts(xmlFile, baseName, entry)
	entry.dependentPartData = {}

	xmlFile:iterate(baseName .. ".dependentPart", function (_, key)
		XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")

		local dependentPart = {
			node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
		}

		if dependentPart.node ~= nil then
			dependentPart.maxUpdateDistance = xmlFile:getValue(key .. "#maxUpdateDistance", "-")

			if dependentPart.maxUpdateDistance == "-" then
				dependentPart.maxUpdateDistance = math.huge
			else
				dependentPart.maxUpdateDistance = tonumber(dependentPart.maxUpdateDistance)
			end

			dependentPart.part = nil

			table.insert(entry.dependentPartData, dependentPart)
		end
	end)
end

function Cylindered:resolveDependentPartData(dependentPartData, referenceNodes)
	for _, dependentPart in pairs(dependentPartData) do
		if dependentPart.part == nil and referenceNodes[dependentPart.node] ~= nil then
			for j = 1, #referenceNodes[dependentPart.node] do
				local depPart = referenceNodes[dependentPart.node][j]

				if j == 1 then
					dependentPart.part = depPart
					depPart.isDependentPart = true
				else
					table.insert(dependentPartData, {
						node = dependentPart.node,
						maxUpdateDistance = dependentPart.maxUpdateDistance,
						part = depPart
					})

					depPart.isDependentPart = true
				end
			end
		end
	end

	for j = #dependentPartData, 1, -1 do
		local data = dependentPartData[j]

		if data.part == nil then
			table.remove(dependentPartData, j)
		end
	end
end

function Cylindered:loadDependentComponentJoints(xmlFile, baseName, entry)
	if not self.isServer then
		return
	end

	entry.componentJoints = {}

	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#componentJointIndex", baseName .. ".componentJoint#index")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#anchorActor", baseName .. ".componentJoint#anchorActor")

	local i = 0

	while true do
		local key = baseName .. string.format(".componentJoint(%d)", i)

		if not xmlFile:hasProperty(key) then
			break
		end

		local index = xmlFile:getValue(key .. "#index")

		if index ~= nil and self.componentJoints[index] ~= nil then
			local anchorActor = xmlFile:getValue(key .. "#anchorActor", 0)
			local componentJoint = self.componentJoints[index]
			local jointEntry = {
				componentJoint = componentJoint,
				anchorActor = anchorActor,
				index = index
			}
			local jointNode = componentJoint.jointNode

			if jointEntry.anchorActor == 1 then
				jointNode = componentJoint.jointNodeActor1
			end

			local node = self.components[componentJoint.componentIndices[2]].node
			jointEntry.x, jointEntry.y, jointEntry.z = localToLocal(node, jointNode, 0, 0, 0)
			jointEntry.upX, jointEntry.upY, jointEntry.upZ = localDirectionToLocal(node, jointNode, 0, 1, 0)
			jointEntry.dirX, jointEntry.dirY, jointEntry.dirZ = localDirectionToLocal(node, jointNode, 0, 0, 1)

			table.insert(entry.componentJoints, jointEntry)
		else
			Logging.xmlWarning(xmlFile, "Invalid index for '%s'", key)
		end

		i = i + 1
	end
end

function Cylindered:loadDependentAttacherJoints(xmlFile, baseName, entry)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#jointIndices", baseName .. ".attacherJoint#jointIndices")

	local indices = xmlFile:getValue(baseName .. ".attacherJoint#jointIndices", nil, true)

	if indices ~= nil then
		entry.attacherJoints = {}
		local availableAttacherJoints = nil

		if self.getAttacherJoints ~= nil then
			availableAttacherJoints = self:getAttacherJoints()
		end

		if availableAttacherJoints ~= nil then
			for i = 1, #indices do
				if availableAttacherJoints[indices[i]] ~= nil then
					table.insert(entry.attacherJoints, availableAttacherJoints[indices[i]])
				end
			end
		end
	end

	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#inputAttacherJoint", baseName .. ".inputAttacherJoint#value")

	entry.inputAttacherJoint = xmlFile:getValue(baseName .. ".inputAttacherJoint#value", false)
end

function Cylindered:loadDependentWheels(xmlFile, baseName, entry)
	if SpecializationUtil.hasSpecialization(Wheels, self.specializations) then
		local indices = xmlFile:getValue(baseName .. "#wheelIndices", nil, true)

		if indices ~= nil then
			entry.wheels = {}

			for _, wheelIndex in pairs(indices) do
				local wheel = self:getWheelFromWheelIndex(wheelIndex)

				if wheel ~= nil then
					table.insert(entry.wheels, wheel)
				else
					Logging.xmlWarning(xmlFile, "Invalid wheelIndex '%s' for '%s'!", wheelIndex, baseName)
				end
			end
		end

		local wheelNodesStr = xmlFile:getValue(baseName .. "#wheelNodes")

		if wheelNodesStr ~= nil and wheelNodesStr ~= "" then
			local wheelNodes = wheelNodesStr:split(" ")

			for i = 1, #wheelNodes do
				local wheel = self:getWheelByWheelNode(wheelNodes[i])

				if wheel ~= nil then
					table.insert(entry.wheels, wheel)
				else
					Logging.xmlWarning(xmlFile, "Invalid wheelNode '%s' for '%s'!", wheelNodes[i], baseName)
				end
			end
		end
	end
end

function Cylindered:loadDependentTranslatingParts(xmlFile, baseName, entry)
	entry.translatingParts = {}

	if entry.referencePoint ~= nil then
		entry.divideTranslatingDistance = xmlFile:getValue(baseName .. "#divideTranslatingDistance", true)
		local j = 0

		while true do
			local refBaseName = baseName .. string.format(".translatingPart(%d)", j)

			if not xmlFile:hasProperty(refBaseName) then
				break
			end

			XMLUtil.checkDeprecatedXMLElements(xmlFile, refBaseName .. "#index", refBaseName .. "#node")

			local node = xmlFile:getValue(refBaseName .. "#node", nil, self.components, self.i3dMappings)

			if node ~= nil then
				local transEntry = {
					node = node
				}
				local x, y, z = getTranslation(node)
				transEntry.startPos = {
					x,
					y,
					z
				}
				transEntry.lastZ = z
				local _, _, refZ = worldToLocal(node, getWorldTranslation(entry.referencePoint))
				transEntry.referenceDistance = refZ
				transEntry.referenceDistancePoint = xmlFile:getValue(refBaseName .. "#referenceDistancePoint", nil, self.components, self.i3dMappings)
				transEntry.minZTrans = xmlFile:getValue(refBaseName .. "#minZTrans")
				transEntry.maxZTrans = xmlFile:getValue(refBaseName .. "#maxZTrans")

				table.insert(entry.translatingParts, transEntry)
			end

			j = j + 1
		end
	end
end

function Cylindered:loadExtraDependentParts(xmlFile, baseName, entry)
	return true
end

function Cylindered:loadDependentAnimations(xmlFile, baseName, entry)
	entry.dependentAnimations = {}
	local i = 0

	while true do
		local baseKey = string.format("%s.dependentAnimation(%d)", baseName, i)

		if not xmlFile:hasProperty(baseKey) then
			break
		end

		local animationName = xmlFile:getValue(baseKey .. "#name")

		if animationName ~= nil then
			local dependentAnimation = {
				name = animationName,
				lastPos = 0,
				translationAxis = xmlFile:getValue(baseKey .. "#translationAxis"),
				rotationAxis = xmlFile:getValue(baseKey .. "#rotationAxis"),
				node = entry.node
			}
			local useTranslatingPartIndex = xmlFile:getValue(baseKey .. "#useTranslatingPartIndex")

			if useTranslatingPartIndex ~= nil and entry.translatingParts[useTranslatingPartIndex] ~= nil then
				dependentAnimation.node = entry.translatingParts[useTranslatingPartIndex].node
			end

			dependentAnimation.minValue = xmlFile:getValue(baseKey .. "#minValue")
			dependentAnimation.maxValue = xmlFile:getValue(baseKey .. "#maxValue")

			if dependentAnimation.rotationAxis ~= nil then
				dependentAnimation.minValue = MathUtil.degToRad(dependentAnimation.minValue)
				dependentAnimation.maxValue = MathUtil.degToRad(dependentAnimation.maxValue)
			end

			dependentAnimation.invert = xmlFile:getValue(baseKey .. "#invert", false)

			table.insert(entry.dependentAnimations, dependentAnimation)
		end

		i = i + 1
	end
end

function Cylindered:loadCopyLocalDirectionParts(xmlFile, baseName, entry)
	entry.copyLocalDirectionParts = {}
	local j = 0

	while true do
		local refBaseName = baseName .. string.format(".copyLocalDirectionPart(%d)", j)

		if not xmlFile:hasProperty(refBaseName) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(xmlFile, refBaseName .. "#index", refBaseName .. "#node")

		local node = xmlFile:getValue(refBaseName .. "#node", nil, self.components, self.i3dMappings)

		if node ~= nil then
			local copyLocalDirectionPart = {
				node = node,
				dirScale = xmlFile:getValue(refBaseName .. "#dirScale", nil, true),
				upScale = xmlFile:getValue(refBaseName .. "#upScale", nil, true)
			}

			self:loadDependentComponentJoints(xmlFile, refBaseName, copyLocalDirectionPart)
			table.insert(entry.copyLocalDirectionParts, copyLocalDirectionPart)
		end

		j = j + 1
	end
end

function Cylindered:loadRotationBasedLimits(xmlFile, key, tool)
	local rotation = xmlFile:getValue(key .. "#rotation")
	local rotMin = xmlFile:getValue(key .. "#rotMin")
	local rotMax = xmlFile:getValue(key .. "#rotMax")
	local transMin = xmlFile:getValue(key .. "#transMin")
	local transMax = xmlFile:getValue(key .. "#transMax")

	if rotation ~= nil and (rotMin ~= nil or rotMax ~= nil or transMin ~= nil or transMax ~= nil) then
		local time = (rotation - tool.rotMin) / (tool.rotMax - tool.rotMin)

		return {
			rotMin = rotMin,
			rotMax = rotMax,
			transMin = transMin,
			transMax = transMax,
			time = time
		}
	end

	return nil
end

function Cylindered:setMovingToolDirty(node, forceUpdate, dt)
	local spec = self.spec_cylindered
	local tool = spec.nodesToMovingTools[node]

	if tool ~= nil then
		if tool.transSpeed ~= nil then
			local oldTrans = tool.curTrans[tool.translationAxis]
			tool.curTrans[1], tool.curTrans[2], tool.curTrans[3] = getTranslation(tool.node)
			local newTrans = tool.curTrans[tool.translationAxis]
			local diff = newTrans - oldTrans

			if math.abs(diff) > 0.0001 then
				self:updateMovingToolSoundEvents(tool, diff > 0, math.abs(newTrans - (tool.transMax or math.huge)) < 0.0001 or math.abs(newTrans - (tool.transMin or math.huge)) < 0.0001, math.abs(oldTrans - (tool.transMax or math.huge)) < 0.0001 or math.abs(oldTrans - (tool.transMin or math.huge)) < 0.0001)
			end
		end

		if tool.rotSpeed ~= nil then
			local oldRot = tool.curRot[tool.rotationAxis]
			tool.curRot[1], tool.curRot[2], tool.curRot[3] = getRotation(tool.node)
			local newRot = tool.curRot[tool.rotationAxis]
			local diff = newRot - oldRot

			if math.abs(diff) > 0.0001 then
				self:updateMovingToolSoundEvents(tool, diff > 0, math.abs(newRot - (tool.rotMax or math.huge)) < 0.0001 or math.abs(newRot - (tool.rotMin or math.huge)) < 0.0001, math.abs(oldRot - (tool.rotMax or math.huge)) < 0.0001 or math.abs(oldRot - (tool.rotMin or math.huge)) < 0.0001)
			end
		end

		Cylindered.setDirty(self, tool)

		if not self.isServer and self.isClient then
			tool.networkInterpolators.translation:setValue(tool.curTrans[tool.translationAxis])
			tool.networkInterpolators.rotation:setAngle(tool.curRot[tool.rotationAxis])
		end

		if forceUpdate or self.finishedFirstUpdate and not self.isActive then
			self:updateDirtyMovingParts(dt or g_currentDt, true)
		end
	end
end

function Cylindered:updateCylinderedInitial(placeComponents, keepDirty)
	if placeComponents == nil then
		placeComponents = true
	end

	if keepDirty == nil then
		keepDirty = false
	end

	local spec = self.spec_cylindered

	for _, part in pairs(spec.activeDirtyMovingParts) do
		Cylindered.setDirty(self, part)
	end

	for _, tool in ipairs(spec.movingTools) do
		if tool.isDirty then
			Cylindered.updateWheels(self, tool)

			if self.isServer then
				Cylindered.updateComponentJoints(self, tool, placeComponents)
			end

			tool.isDirty = keepDirty
		end

		self:updateExtraDependentParts(tool, 9999)
		self:updateDependentAnimations(tool, 9999)
	end

	for _, part in ipairs(spec.movingParts) do
		local isActive = self:getIsMovingPartActive(part)

		if isActive or part.smoothedDirectionScale and part.smoothedDirectionScaleAlpha ~= 0 then
			if part.isDirty then
				Cylindered.updateMovingPart(self, part, placeComponents, nil, isActive, false)
				Cylindered.updateWheels(self, part)

				part.isDirty = keepDirty
			end

			self:updateExtraDependentParts(part, 9999)
			self:updateDependentAnimations(part, 9999)
		end
	end
end

function Cylindered:allowLoadMovingToolStates(superFunc)
	return true
end

function Cylindered:getMovingToolByNode(node)
	return self.spec_cylindered.nodesToMovingTools[node]
end

function Cylindered:getMovingPartByNode(node)
	return self.spec_cylindered.nodesToMovingParts[node]
end

function Cylindered:getTranslatingPartByNode(node)
	local spec = self.spec_cylindered

	for i = 1, #spec.movingParts do
		local part = spec.movingParts[i]

		if part.translatingParts ~= nil then
			for j = 1, #part.translatingParts do
				if part.translatingParts[j].node == node then
					return part.translatingParts[j]
				end
			end
		end
	end
end

function Cylindered:getIsMovingToolActive(movingTool)
	return movingTool.isActive
end

function Cylindered:getIsMovingPartActive(movingPart)
	return movingPart.isActive
end

function Cylindered:isDetachAllowed(superFunc)
	local spec = self.spec_cylindered

	if spec.detachLockNodes ~= nil then
		for entry, data in pairs(spec.detachLockNodes) do
			local node = entry.node
			local rot = {
				getRotation(node)
			}

			if data.detachingRotMinLimit ~= nil and rot[entry.rotationAxis] < data.detachingRotMinLimit then
				return false, nil
			end

			if data.detachingRotMaxLimit ~= nil and data.detachingRotMaxLimit < rot[entry.rotationAxis] then
				return false, nil
			end

			local trans = {
				getTranslation(node)
			}

			if data.detachingTransMinLimit ~= nil and trans[entry.translationAxis] < data.detachingTransMinLimit then
				return false, nil
			end

			if data.detachingTransMaxLimit ~= nil and data.detachingTransMaxLimit < trans[entry.translationAxis] then
				return false, nil
			end
		end
	end

	return superFunc(self)
end

function Cylindered:loadObjectChangeValuesFromXML(superFunc, xmlFile, key, node, object)
	superFunc(self, xmlFile, key, node, object)

	local spec = self.spec_cylindered

	if spec.nodesToMovingTools ~= nil and spec.nodesToMovingTools[node] ~= nil then
		local movingTool = spec.nodesToMovingTools[node]
		object.movingToolRotMaxActive = xmlFile:getValue(key .. "#movingToolRotMaxActive", movingTool.rotMax)
		object.movingToolRotMaxInactive = xmlFile:getValue(key .. "#movingToolRotMaxInactive", movingTool.rotMax)
		object.movingToolRotMinActive = xmlFile:getValue(key .. "#movingToolRotMinActive", movingTool.rotMin)
		object.movingToolRotMinInactive = xmlFile:getValue(key .. "#movingToolRotMinInactive", movingTool.rotMin)
	end

	ObjectChangeUtil.loadValueType(object.values, xmlFile, key, "movingPartUpdate", nil, function (state)
		if self.getMovingPartByNode ~= nil then
			local movingPart = self:getMovingPartByNode(node)

			if movingPart ~= nil then
				movingPart.isActive = state
			end
		end
	end, false)
end

function Cylindered:setObjectChangeValues(superFunc, object, isActive)
	superFunc(self, object, isActive)

	local spec = self.spec_cylindered

	if spec.nodesToMovingTools ~= nil and spec.nodesToMovingTools[object.node] ~= nil then
		local movingTool = spec.nodesToMovingTools[object.node]

		if isActive then
			movingTool.rotMax = object.movingToolRotMaxActive
			movingTool.rotMin = object.movingToolRotMinActive
		else
			movingTool.rotMax = object.movingToolRotMaxInactive
			movingTool.rotMin = object.movingToolRotMinInactive
		end
	end
end

function Cylindered:loadDischargeNode(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end

	local baseKey = key .. ".movingToolActivation"

	if xmlFile:hasProperty(baseKey) then
		entry.movingToolActivation = {
			node = xmlFile:getValue(baseKey .. "#node", nil, self.components, self.i3dMappings),
			isInverted = xmlFile:getValue(baseKey .. "#isInverted", false),
			openFactor = xmlFile:getValue(baseKey .. "#openFactor", 1),
			openOffset = xmlFile:getValue(baseKey .. "#openOffset", 0)
		}
		entry.movingToolActivation.openOffsetInv = 1 - entry.movingToolActivation.openOffset
	end

	return true
end

function Cylindered:getDischargeNodeEmptyFactor(superFunc, dischargeNode)
	if dischargeNode.movingToolActivation == nil then
		return superFunc(self, dischargeNode)
	else
		local spec = self.spec_cylindered
		local movingToolActivation = dischargeNode.movingToolActivation
		local currentSpeed = superFunc(self, dischargeNode)
		local movingTool = spec.nodesToMovingTools[movingToolActivation.node]
		local state = MathUtil.clamp(Cylindered.getMovingToolState(self, movingTool), 0, 1)

		if movingToolActivation.isInverted then
			state = math.abs(state - 1)
		end

		state = math.max(state - movingToolActivation.openOffset, 0) / movingToolActivation.openOffsetInv
		local speedFactor = MathUtil.clamp(state / movingToolActivation.openFactor, 0, 1)

		return currentSpeed * speedFactor
	end
end

function Cylindered:loadShovelNode(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end

	local baseKey = key .. ".movingToolActivation"

	if not xmlFile:hasProperty(baseKey) then
		return true
	end

	entry.movingToolActivation = {
		node = xmlFile:getValue(baseKey .. "#node", nil, self.components, self.i3dMappings),
		isInverted = xmlFile:getValue(baseKey .. "#isInverted", false),
		openFactor = xmlFile:getValue(baseKey .. "#openFactor", 1)
	}

	return true
end

function Cylindered:getShovelNodeIsActive(superFunc, shovelNode)
	local isActive = superFunc(self, shovelNode)

	if not isActive or shovelNode.movingToolActivation == nil then
		return isActive
	end

	local spec = self.spec_cylindered
	local movingToolActivation = shovelNode.movingToolActivation
	local movingTool = spec.nodesToMovingTools[movingToolActivation.node]
	local state = Cylindered.getMovingToolState(self, movingTool)

	if movingToolActivation.isInverted then
		state = math.abs(state - 1)
	end

	return movingToolActivation.openFactor < state
end

function Cylindered:loadDynamicMountGrabFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end

	local baseKey = key .. ".movingToolActivation"

	if not xmlFile:hasProperty(baseKey) then
		return true
	end

	entry.movingToolActivation = {
		node = xmlFile:getValue(baseKey .. "#node", nil, self.components, self.i3dMappings),
		isInverted = xmlFile:getValue(baseKey .. "#isInverted", false),
		openFactor = xmlFile:getValue(baseKey .. "#openFactor", 1)
	}

	return true
end

function Cylindered:getIsDynamicMountGrabOpened(superFunc, grab)
	local isActive = superFunc(self, grab)

	if not isActive or grab.movingToolActivation == nil then
		return isActive
	end

	local spec = self.spec_cylindered
	local movingToolActivation = grab.movingToolActivation
	local movingTool = spec.nodesToMovingTools[movingToolActivation.node]
	local state = Cylindered.getMovingToolState(self, movingTool)

	if movingToolActivation.isInverted then
		state = math.abs(state - 1)
	end

	return movingToolActivation.openFactor < state
end

function Cylindered:setComponentJointFrame(superFunc, jointDesc, anchorActor)
	superFunc(self, jointDesc, anchorActor)

	local spec = self.spec_cylindered

	for _, movingTool in ipairs(spec.movingTools) do
		for _, componentJoint in ipairs(movingTool.componentJoints) do
			local componentJointDesc = self.componentJoints[componentJoint.index]
			local jointNode = componentJointDesc.jointNode

			if componentJoint.anchorActor == 1 then
				jointNode = componentJointDesc.jointNodeActor1
			end

			local node = self.components[componentJointDesc.componentIndices[2]].node
			componentJoint.x, componentJoint.y, componentJoint.z = localToLocal(node, jointNode, 0, 0, 0)
			componentJoint.upX, componentJoint.upY, componentJoint.upZ = localDirectionToLocal(node, jointNode, 0, 1, 0)
			componentJoint.dirX, componentJoint.dirY, componentJoint.dirZ = localDirectionToLocal(node, jointNode, 0, 0, 1)
		end
	end
end

function Cylindered:getAdditionalSchemaText(superFunc)
	local t = superFunc(self)

	if self.isClient and self:getIsActiveForInput(true) then
		local spec = self.spec_cylindered

		if #spec.controlGroupNames > 1 and spec.currentControlGroupIndex ~= 0 then
			t = tostring(spec.currentControlGroupIndex)
		end
	end

	return t
end

function Cylindered:getWearMultiplier(superFunc)
	local spec = self.spec_cylindered
	local multiplier = superFunc(self)

	if spec.isHydraulicSamplePlaying then
		multiplier = multiplier + self:getWorkWearMultiplier()
	end

	return multiplier
end

function Cylindered:getDoConsumePtoPower(superFunc)
	return superFunc(self) or self.spec_cylindered.powerConsumingTimer > 0
end

function Cylindered:getConsumingLoad(superFunc)
	local value, count = superFunc(self)
	local spec = self.spec_cylindered
	local loadPercentage = math.max(spec.powerConsumingTimer / spec.powerConsumingActiveTimeOffset, 0)

	return value + loadPercentage, count + 1
end

function Cylindered:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_cylindered

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			for i = 1, #spec.movingTools do
				local movingTool = spec.movingTools[i]
				local isSelectedGroup = movingTool.controlGroupIndex == 0 or movingTool.controlGroupIndex == spec.currentControlGroupIndex
				local canBeControlled = not g_gameSettings:getValue("easyArmControl") and not movingTool.isEasyControlTarget or movingTool.easyArmControlActive

				if movingTool.axisActionIndex ~= nil and isSelectedGroup and canBeControlled then
					local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, movingTool.axisActionIndex, self, Cylindered.actionEventInput, false, false, true, true, i, movingTool.axisActionIcon)

					g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
				end
			end
		end
	end
end

function Cylindered:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_cylindered

	for _, tool in ipairs(spec.movingTools) do
		local changed = false

		if tool.transSpeed ~= nil then
			local trans = tool.curTrans[tool.translationAxis]
			local changedTrans = false

			if tool.attachTransMax ~= nil and tool.attachTransMax < trans then
				trans = tool.attachTransMax
				changedTrans = true
			elseif tool.attachTransMin ~= nil and trans < tool.attachTransMin then
				trans = tool.attachTransMin
				changedTrans = true
			end

			if changedTrans then
				tool.curTrans[tool.translationAxis] = trans

				setTranslation(tool.node, unpack(tool.curTrans))

				changed = true
			end
		end

		if tool.rotSpeed ~= nil then
			local rot = tool.curRot[tool.rotationAxis]
			local changedRot = false

			if tool.attachRotMax ~= nil and tool.attachRotMax < rot then
				rot = tool.attachRotMax
				changedRot = true
			elseif tool.attachRotMin ~= nil and rot < tool.attachRotMin then
				rot = tool.attachRotMin
				changedRot = true
			end

			if changedRot then
				tool.curRot[tool.rotationAxis] = rot

				setRotation(tool.node, unpack(tool.curRot))

				changed = true
			end
		end

		if changed then
			Cylindered.setDirty(self, tool)
		end
	end
end

function Cylindered:onSelect(subSelectionIndex)
	local spec = self.spec_cylindered
	local controlGroupIndex = spec.controlGroupMapping[subSelectionIndex]

	if controlGroupIndex ~= nil then
		spec.currentControlGroupIndex = controlGroupIndex
	else
		spec.currentControlGroupIndex = 0
	end
end

function Cylindered:onUnselect()
	local spec = self.spec_cylindered
	spec.currentControlGroupIndex = 0
end

function Cylindered:onDeactivate()
	if self.isClient then
		local spec = self.spec_cylindered

		g_soundManager:stopSample(spec.samples.hydraulic)

		spec.isHydraulicSamplePlaying = false
	end
end

function Cylindered:onAnimationPartChanged(node)
	self:setMovingToolDirty(node)
end

function Cylindered:onVehicleSettingChanged(gameSettingId, state)
	if gameSettingId == GameSettings.SETTING.EASY_ARM_CONTROL then
		self:setIsEasyControlActive(state)
	end
end

function Cylindered:setToolTranslation(tool, transSpeed, dt, delta)
	tool.curTrans[1], tool.curTrans[2], tool.curTrans[3] = getTranslation(tool.node)
	local newTrans = tool.curTrans[tool.translationAxis]
	local oldTrans = newTrans

	if transSpeed ~= nil then
		newTrans = newTrans + transSpeed * dt
	else
		newTrans = newTrans + delta
	end

	if tool.transMax ~= nil then
		newTrans = math.min(newTrans, tool.transMax)
	end

	if tool.transMin ~= nil then
		newTrans = math.max(newTrans, tool.transMin)
	end

	local diff = newTrans - oldTrans

	if dt ~= 0 then
		tool.lastTransSpeed = diff / dt
	end

	if math.abs(diff) > 0.0001 then
		tool.curTrans[tool.translationAxis] = newTrans

		setTranslation(tool.node, tool.curTrans[1], tool.curTrans[2], tool.curTrans[3])
		self:updateMovingToolSoundEvents(tool, diff > 0, newTrans == tool.transMax or newTrans == tool.transMin, oldTrans == tool.transMax or oldTrans == tool.transMin)
		SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, transSpeed, dt)

		return true
	end

	return false
end

function Cylindered:setAbsoluteToolTranslation(tool, translation)
	tool.curTrans[1], tool.curTrans[2], tool.curTrans[3] = getTranslation(tool.node)
	local oldTrans = tool.curTrans[tool.translationAxis]

	if Cylindered.setToolTranslation(self, tool, nil, 0, translation - oldTrans) then
		Cylindered.setDirty(self, tool)
		self:raiseDirtyFlags(tool.dirtyFlag)
		self:raiseDirtyFlags(self.spec_cylindered.cylinderedDirtyFlag)
	end
end

function Cylindered:setToolRotation(tool, rotSpeed, dt, delta)
	tool.curRot[1], tool.curRot[2], tool.curRot[3] = getRotation(tool.node)
	local newRot = tool.curRot[tool.rotationAxis]
	local oldRot = newRot

	if rotSpeed ~= nil then
		newRot = newRot + rotSpeed * dt
	else
		newRot = newRot + delta
	end

	if tool.rotMax ~= nil then
		newRot = math.min(newRot, tool.rotMax)
	end

	if tool.rotMin ~= nil then
		newRot = math.max(newRot, tool.rotMin)
	end

	local diff = newRot - tool.curRot[tool.rotationAxis]

	if rotSpeed ~= nil and dt ~= 0 then
		tool.lastRotSpeed = diff / dt
	end

	if math.abs(diff) > 0.0001 then
		if tool.rotMin == nil and tool.rotMax == nil then
			if newRot > 2 * math.pi then
				newRot = newRot - 2 * math.pi
			end

			if newRot < 0 then
				newRot = newRot + 2 * math.pi
			end
		end

		tool.curRot[tool.rotationAxis] = newRot

		setRotation(tool.node, tool.curRot[1], tool.curRot[2], tool.curRot[3])
		self:updateMovingToolSoundEvents(tool, diff > 0, newRot == tool.rotMax or newRot == tool.rotMin, oldRot == tool.rotMax or oldRot == tool.rotMin)
		SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, rotSpeed, dt)

		return true
	end

	return false
end

function Cylindered:setAbsoluteToolRotation(tool, rotation, updateDelayedNodes)
	tool.curRot[1], tool.curRot[2], tool.curRot[3] = getRotation(tool.node)
	local oldRot = tool.curRot[tool.rotationAxis]

	if Cylindered.setToolRotation(self, tool, nil, 0, rotation - oldRot) then
		Cylindered.setDirty(self, tool)

		if updateDelayedNodes ~= nil and updateDelayedNodes then
			self:updateDelayedTool(tool)
		end

		self:raiseDirtyFlags(tool.dirtyFlag)
		self:raiseDirtyFlags(self.spec_cylindered.cylinderedDirtyFlag)
	end
end

function Cylindered:setToolAnimation(tool, animSpeed, dt)
	tool.curAnimTime = self:getAnimationTime(tool.animName)
	local newAnimTime = tool.curAnimTime + animSpeed * dt
	local oldAnimTime = tool.curAnimTime

	if tool.animMaxTime ~= nil then
		newAnimTime = math.min(newAnimTime, tool.animMaxTime)
	end

	if tool.animMinTime ~= nil then
		newAnimTime = math.max(newAnimTime, tool.animMinTime)
	end

	local diff = newAnimTime - tool.curAnimTime

	if dt ~= 0 then
		tool.lastAnimSpeed = diff / dt
	end

	if math.abs(diff) > 0.0001 then
		tool.curAnimTime = newAnimTime

		self:setAnimationTime(tool.animName, newAnimTime, nil, true)
		self:updateMovingToolSoundEvents(tool, diff > 0, newAnimTime == tool.animMaxTime or newAnimTime == tool.animMinTime or newAnimTime == 0 or newAnimTime == 1, oldAnimTime == tool.animMaxTime or oldAnimTime == tool.animMinTime or oldAnimTime == 0 or oldAnimTime == 1)
		SpecializationUtil.raiseEvent(self, "onMovingToolChanged", tool, animSpeed, dt)

		return true
	end

	return false
end

function Cylindered:getMovingToolState(tool)
	local state = 0

	if tool.rotMax ~= nil and tool.rotMin ~= nil then
		state = (tool.curRot[tool.rotationAxis] - tool.rotMin) / (tool.rotMax - tool.rotMin)
	elseif tool.transMax ~= nil and tool.transMin ~= nil then
		state = (tool.curTrans[tool.translationAxis] - tool.transMin) / (tool.transMax - tool.transMin)
	end

	return state
end

function Cylindered:setDirty(part)
	if not part.isDirty or self.spec_cylindered.isLoading then
		part.isDirty = true
		self.anyMovingPartsDirty = true

		if part.delayedNode ~= nil then
			self:setDelayedData(part)
		end

		if part.isTool then
			Cylindered.updateAttacherJoints(self, part)
			Cylindered.updateWheels(self, part)
		end

		for _, data in pairs(part.dependentPartData) do
			if self.currentUpdateDistance < data.maxUpdateDistance then
				Cylindered.setDirty(self, data.part)
			end
		end
	end
end

function Cylindered:updateWheels(part)
	if part.wheels ~= nil then
		for _, wheel in pairs(part.wheels) do
			wheel.positionX, wheel.positionY, wheel.positionZ = localToLocal(getParent(wheel.repr), wheel.node, wheel.startPositionX - wheel.steeringCenterOffsetX, wheel.startPositionY - wheel.steeringCenterOffsetY, wheel.startPositionZ - wheel.steeringCenterOffsetZ)

			if wheel.useReprDirection then
				wheel.directionX, wheel.directionY, wheel.directionZ = localDirectionToLocal(wheel.repr, wheel.node, 0, -1, 0)
				wheel.axleX, wheel.axleY, wheel.axleZ = localDirectionToLocal(wheel.repr, wheel.node, 1, 0, 0)
			elseif wheel.useDriveNodeDirection then
				wheel.directionX, wheel.directionY, wheel.directionZ = localDirectionToLocal(wheel.driveNodeDirectionNode, wheel.node, 0, -1, 0)
				wheel.axleX, wheel.axleY, wheel.axleZ = localDirectionToLocal(wheel.driveNodeDirectionNode, wheel.node, 1, 0, 0)
			end

			self:updateWheelBase(wheel)

			for j = 1, #wheel.wheelChocks do
				self:updateWheelChockPosition(wheel.wheelChocks[j])
			end
		end
	end
end

function Cylindered:updateMovingPart(part, placeComponents, updateDependentParts, isActive, updateSounds)
	local refX, refY, refZ = nil
	local dirX = 0
	local dirY = 0
	local dirZ = 0
	local changed = false
	local applyDirection = false

	if part.referencePoint ~= nil then
		if part.moveToReferenceFrame then
			local x, y, z = localToLocal(part.referenceFrame, getParent(part.node), part.referenceFrameOffset[1], part.referenceFrameOffset[2], part.referenceFrameOffset[3])

			setTranslation(part.node, x, y, z)

			changed = true
		end

		refX, refY, refZ = getWorldTranslation(part.referencePoint)

		if part.referenceDistance == 0 then
			if part.useLocalOffset then
				local lx, ly, lz = worldToLocal(part.node, refX, refY, refZ)
				dirX, dirY, dirZ = localDirectionToWorld(part.node, lx - part.localReferencePoint[1], ly - part.localReferencePoint[2], lz)
			else
				local x, y, z = getWorldTranslation(part.node)
				dirZ = refZ - z
				dirY = refY - y
				dirX = refX - x
			end
		else
			if part.updateLocalReferenceDistance then
				local _, y, z = worldToLocal(part.node, getWorldTranslation(part.localReferencePointNode))
				part.localReferenceDistance = MathUtil.vector2Length(y, z)
			end

			if part.referenceDistancePoint ~= nil then
				local _, _, z = worldToLocal(part.node, getWorldTranslation(part.referenceDistancePoint))
				part.referenceDistance = z
			end

			if part.localReferenceTranslate then
				local _, ly, lz = worldToLocal(part.node, refX, refY, refZ)

				if math.abs(ly) < part.referenceDistance then
					local dz = math.sqrt(part.referenceDistance * part.referenceDistance - ly * ly)
					local z1 = lz - dz - part.localReferenceDistance
					local z2 = lz + dz - part.localReferenceDistance

					if math.abs(z2) < math.abs(z1) then
						z1 = z2
					end

					local parentNode = getParent(part.node)
					local tx, ty, tz = unpack(part.localReferenceTranslation)
					local _, _, coz = localToLocal(parentNode, part.node, tx, ty, tz)
					local ox, oy, oz = localDirectionToLocal(part.node, parentNode, 0, 0, z1 - coz)

					setTranslation(part.node, tx + ox, ty + oy, tz + oz)

					changed = true
				end
			else
				local r1 = part.localReferenceDistance
				local r2 = part.referenceDistance

				if part.dynamicLocalReferenceDistance then
					local _, y1, z1 = worldToLocal(part.node, getWorldTranslation(part.localReferencePointNode))
					local _, y2, z2 = worldToLocal(part.node, localToWorld(part.localReferencePointNode, 0, 0, part.referenceDistance))
					r2 = MathUtil.vector2Length(y1 - y2, z1 - z2)
				end

				local _, ly, lz = worldToLocal(part.node, refX, refY, refZ)
				local ix, iy, i2x, i2y = MathUtil.getCircleCircleIntersection(0, 0, r1, ly, lz, r2)
				local allowUpdate = true

				if part.referenceDistanceThreshold > 0 then
					local lRefX, lRefY, lRefZ = worldToLocal(part.node, getWorldTranslation(part.referencePoint))
					local x, y, z = worldToLocal(part.node, getWorldTranslation(part.localReferencePointNode))
					local currentDistance = MathUtil.vector3Length(lRefX - x, lRefY - y, lRefZ - z)

					if math.abs(currentDistance - part.referenceDistance) < part.referenceDistanceThreshold then
						allowUpdate = false
					end
				end

				if allowUpdate and ix ~= nil then
					if i2x ~= nil then
						local side = ix * (lz - iy) - iy * (ly - ix)

						if side < 0 ~= (part.localReferenceAngleSide < 0) then
							iy = i2y
							ix = i2x
						end
					end

					dirX, dirY, dirZ = localDirectionToWorld(part.node, 0, ix, iy)
					changed = true
				end
			end
		end

		if part.doInversedLineAlignment then
			if part.doInversedLineAlignmentRoot == nil then
				part.doInversedLineAlignmentRoot = createTransformGroup("inversedLineAlignmentRoot")

				link(getParent(part.node), part.doInversedLineAlignmentRoot, getChildIndex(part.node))
				setTranslation(part.doInversedLineAlignmentRoot, getTranslation(part.node))
				setRotation(part.doInversedLineAlignmentRoot, getRotation(part.node))
				link(part.doInversedLineAlignmentRoot, part.node)
				setTranslation(part.node, 0, 0, 0)
				setRotation(part.node, 0, 0, 0)
			end

			for i = 1, #part.orientationLineNodes - 1 do
				local startNode = part.orientationLineNodes[i]
				local endNode = part.orientationLineNodes[i + 1]
				local _, sy, sz = localToLocal(startNode, part.node, 0, 0, 0)
				local _, ey, ez = localToLocal(endNode, part.node, 0, 0, 0)
				local minLength = MathUtil.vector2Length(sy, sz)
				local maxLength = MathUtil.vector2Length(ey, ez)
				local targetLength = calcDistanceFrom(part.referencePoint, part.doInversedLineAlignmentRoot)

				if minLength <= targetLength and targetLength <= maxLength then
					local alpha = (targetLength - minLength) / (maxLength - minLength)
					local ty = MathUtil.lerp(sy, ey, alpha)
					local tz = MathUtil.lerp(sz, ez, alpha)
					local upX, upY, upZ = localDirectionToWorld(part.referenceFrame, 0, 1, 0)
					dirX, dirY, dirZ = localDirectionToWorld(part.doInversedLineAlignmentRoot, 0, -ty, tz)

					I3DUtil.setWorldDirection(part.node, dirX, dirY, dirZ, upX, upY, upZ, part.limitedAxis, part.minRot, part.maxRot)

					local x, y, z = getWorldTranslation(part.doInversedLineAlignmentRoot)
					dirZ = refZ - z
					dirY = refY - y
					dirX = refX - x

					I3DUtil.setWorldDirection(part.doInversedLineAlignmentRoot, dirX, dirY, dirZ, upX, upY, upZ, part.limitedAxis, part.minRot, part.maxRot)

					changed = true

					break
				end
			end
		end
	else
		if part.alignToWorldY then
			dirX, dirY, dirZ = localDirectionToWorld(getRootNode(), 0, 1, 0)
			local lDX, lDY, lDZ = worldDirectionToLocal(part.referenceFrame, dirX, dirY, dirZ)

			if lDZ < 0 then
				lDZ = -lDZ
			end

			dirX, dirY, dirZ = localDirectionToWorld(part.referenceFrame, lDX, lDY, lDZ)
			changed = true
		else
			dirX, dirY, dirZ = localDirectionToWorld(part.referenceFrame, 0, 0, 1)
			changed = true
		end

		if part.moveToReferenceFrame then
			local x, y, z = localToLocal(part.referenceFrame, getParent(part.node), part.referenceFrameOffset[1], part.referenceFrameOffset[2], part.referenceFrameOffset[3])

			setTranslation(part.node, x, y, z)

			changed = true
		end

		if part.doLineAlignment then
			local foundPoint = false

			for i = 1, #part.orientationLineNodes - 1 do
				local startNode = part.orientationLineNodes[i]
				local endNode = part.orientationLineNodes[i + 1]
				local _, sy, sz = localToLocal(startNode, part.referenceFrame, 0, 0, 0)
				local _, ey, ez = localToLocal(endNode, part.referenceFrame, 0, 0, 0)
				local _, cy, cz = localToLocal(part.node, part.referenceFrame, 0, 0, 0)
				local hasIntersection, i1y, i1z, i2y, i2z = MathUtil.getCircleLineIntersection(cy, cz, part.partLength, sy, sz, ey, ez)

				if hasIntersection then
					local targetY, targetZ = nil

					if not MathUtil.getIsOutOfBounds(i1y, sy, ey) and not MathUtil.getIsOutOfBounds(i1z, sz, ez) then
						targetZ = i1z
						targetY = i1y
						foundPoint = true
					end

					if not MathUtil.getIsOutOfBounds(i2y, sy, ey) and not MathUtil.getIsOutOfBounds(i2z, sz, ez) then
						targetZ = i2z
						targetY = i2y
						foundPoint = true
					end

					if foundPoint and not MathUtil.isNan(targetY) and not MathUtil.isNan(targetZ) then
						dirX, dirY, dirZ = localDirectionToWorld(part.referenceFrame, 0, targetY, targetZ)
						changed = true
						applyDirection = true

						break
					end
				end
			end
		end
	end

	if part.smoothedDirectionScale then
		if part.smoothedDirectionScaleAlpha == nil then
			part.smoothedDirectionScaleAlpha = isActive and 1 or 0
		end

		local dt = g_currentDt or 9999

		if isActive then
			part.smoothedDirectionScaleAlpha = math.min(part.smoothedDirectionScaleAlpha + dt * part.smoothedDirectionTime, 1)
		else
			part.smoothedDirectionScaleAlpha = math.max(part.smoothedDirectionScaleAlpha - dt * part.smoothedDirectionTime, 0)
		end

		local inDirX, inDirY, inDirZ = localDirectionToWorld(getParent(part.node), unpack(part.initialDirection))
		dirX, dirY, dirZ = MathUtil.lerp3(inDirX, inDirY, inDirZ, dirX, dirY, dirZ, part.smoothedDirectionScaleAlpha)
	end

	if (part.doDirectionAlignment or applyDirection) and (dirX ~= 0 or dirY ~= 0 or dirZ ~= 0) then
		local upX, upY, upZ = localDirectionToWorld(part.referenceFrame, 0, 1, 0)

		if part.invertZ then
			dirX = -dirX
			dirY = -dirY
			dirZ = -dirZ
		end

		local directionThreshold = part.directionThresholdActive

		if not self:getIsActive() and part.directionThreshold ~= nil and part.directionThreshold > 0 then
			directionThreshold = part.directionThreshold
		end

		local lDirX, lDirY, lDirZ = worldDirectionToLocal(part.parent, dirX, dirY, dirZ)
		local lastDirection = part.lastDirection
		local lastUpVector = part.lastUpVector

		if directionThreshold < math.abs(lastDirection[1] - lDirX) or directionThreshold < math.abs(lastDirection[2] - lDirY) or directionThreshold < math.abs(lastDirection[3] - lDirZ) or directionThreshold < math.abs(lastUpVector[1] - upX) or directionThreshold < math.abs(lastUpVector[2] - upY) or directionThreshold < math.abs(lastUpVector[3] - upZ) then
			I3DUtil.setWorldDirection(part.node, dirX, dirY, dirZ, upX, upY, upZ, part.limitedAxis, part.minRot, part.maxRot)

			if part.debug then
				local x, y, z = getWorldTranslation(part.node)
				local length = 1
				local _ = nil

				if part.referencePoint ~= nil then
					_, _, length = worldToLocal(part.node, refX, refY, refZ)
				end

				drawDebugLine(x, y, z, 1, 0, 0, x + dirX * length, y + dirY * length, z + dirZ * length, 0, 1, 0, true)
			end

			lastDirection[3] = lDirZ
			lastDirection[2] = lDirY
			lastDirection[1] = lDirX
			lastUpVector[3] = upZ
			lastUpVector[2] = upY
			lastUpVector[1] = upX
			changed = true
		else
			changed = false
		end

		if part.scaleZ and part.localReferenceDistance ~= nil then
			local len = MathUtil.vector3Length(dirX, dirY, dirZ)

			setScale(part.node, 1, 1, len / part.localReferenceDistance)

			if part.debug then
				DebugUtil.drawDebugNode(part.node, string.format("scale:%.2f", len / part.localReferenceDistance), false)
			end
		end
	end

	if part.doRotationAlignment then
		local x, y, z = getRotation(part.referenceFrame)

		setRotation(part.node, x * part.rotMultiplier, y * part.rotMultiplier, z * part.rotMultiplier)

		changed = true
	end

	if part.referencePoint ~= nil then
		local numTranslatingParts = #part.translatingParts
		local distanceDivider = part.divideTranslatingDistance and numTranslatingParts or 1

		if numTranslatingParts > 0 then
			local _, _, dist = worldToLocal(part.node, refX, refY, refZ)

			for i = 1, numTranslatingParts do
				local translatingPart = part.translatingParts[i]
				local newZ = (dist - translatingPart.referenceDistance) / distanceDivider

				if translatingPart.minZTrans ~= nil then
					newZ = math.max(translatingPart.minZTrans, newZ)
				end

				if translatingPart.maxZTrans ~= nil then
					newZ = math.min(translatingPart.maxZTrans, newZ)
				end

				if not part.divideTranslatingDistance then
					dist = dist - (newZ - translatingPart.startPos[3])
				end

				local allowUpdate = true

				if part.referenceDistanceThreshold > 0 and math.abs(translatingPart.lastZ - newZ) < part.referenceDistanceThreshold then
					allowUpdate = false
				end

				if allowUpdate then
					if updateSounds ~= false and (part.samplesByAction ~= nil or translatingPart.samplesByAction ~= nil) and newZ ~= translatingPart.lastZ and math.abs(translatingPart.lastZ - newZ) > 0.0001 then
						self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_END, Cylindered.SOUND_TYPE_ENDING)
						self:onMovingPartSoundEvent(translatingPart, Cylindered.SOUND_ACTION_TRANSLATING_END, Cylindered.SOUND_TYPE_ENDING)
						self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_START, Cylindered.SOUND_TYPE_STARTING)
						self:onMovingPartSoundEvent(translatingPart, Cylindered.SOUND_ACTION_TRANSLATING_START, Cylindered.SOUND_TYPE_STARTING)

						if newZ > translatingPart.lastZ + 0.0001 then
							self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_POS, Cylindered.SOUND_TYPE_CONTINUES)
							self:onMovingPartSoundEvent(translatingPart, Cylindered.SOUND_ACTION_TRANSLATING_POS, Cylindered.SOUND_TYPE_CONTINUES)
							self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_END_POS, Cylindered.SOUND_TYPE_ENDING)
							self:onMovingPartSoundEvent(translatingPart, Cylindered.SOUND_ACTION_TRANSLATING_END_POS, Cylindered.SOUND_TYPE_ENDING)
							self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_START_POS, Cylindered.SOUND_TYPE_STARTING)
							self:onMovingPartSoundEvent(translatingPart, Cylindered.SOUND_ACTION_TRANSLATING_START_POS, Cylindered.SOUND_TYPE_STARTING)
						elseif newZ < translatingPart.lastZ - 0.0001 then
							self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_NEG, Cylindered.SOUND_TYPE_CONTINUES)
							self:onMovingPartSoundEvent(translatingPart, Cylindered.SOUND_ACTION_TRANSLATING_NEG, Cylindered.SOUND_TYPE_CONTINUES)
							self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_END_NEG, Cylindered.SOUND_TYPE_ENDING)
							self:onMovingPartSoundEvent(translatingPart, Cylindered.SOUND_ACTION_TRANSLATING_END_NEG, Cylindered.SOUND_TYPE_ENDING)
							self:onMovingPartSoundEvent(part, Cylindered.SOUND_ACTION_TRANSLATING_START_NEG, Cylindered.SOUND_TYPE_STARTING)
							self:onMovingPartSoundEvent(translatingPart, Cylindered.SOUND_ACTION_TRANSLATING_START_NEG, Cylindered.SOUND_TYPE_STARTING)
						end
					end

					translatingPart.lastZ = newZ

					setTranslation(translatingPart.node, translatingPart.startPos[1], translatingPart.startPos[2], newZ)

					changed = true
				end
			end
		end
	end

	if changed then
		if part.copyLocalDirectionParts ~= nil then
			for _, copyLocalDirectionPart in pairs(part.copyLocalDirectionParts) do
				local dx, dy, dz = localDirectionToWorld(part.node, 0, 0, 1)
				dx, dy, dz = worldDirectionToLocal(getParent(part.node), dx, dy, dz)
				dx = dx * copyLocalDirectionPart.dirScale[1]
				dy = dy * copyLocalDirectionPart.dirScale[2]
				dz = dz * copyLocalDirectionPart.dirScale[3]
				local ux, uy, uz = localDirectionToWorld(part.node, 0, 1, 0)
				ux, uy, uz = worldDirectionToLocal(getParent(part.node), ux, uy, uz)
				ux = ux * copyLocalDirectionPart.upScale[1]
				uy = uy * copyLocalDirectionPart.upScale[2]
				uz = uz * copyLocalDirectionPart.upScale[3]

				setDirection(copyLocalDirectionPart.node, dx, dy, dz, ux, uy, uz)

				if self.isServer then
					Cylindered.updateComponentJoints(self, copyLocalDirectionPart, placeComponents)
				end
			end
		end

		if self.isServer then
			Cylindered.updateComponentJoints(self, part, placeComponents)
			Cylindered.updateAttacherJoints(self, part)
			Cylindered.updateWheels(self, part)
		end

		Cylindered.updateWheels(self, part)
	end

	if updateDependentParts then
		for _, data in pairs(part.dependentPartData) do
			if self.currentUpdateDistance < data.maxUpdateDistance then
				local dependentPart = data.part
				local dependentIsActive = self:getIsMovingPartActive(dependentPart)

				if dependentIsActive or dependentPart.smoothedDirectionScale and dependentPart.smoothedDirectionScaleAlpha ~= 0 then
					Cylindered.updateMovingPart(self, dependentPart, placeComponents, updateDependentParts, dependentIsActive)
				end
			end
		end
	end

	part.isDirty = false
end

function Cylindered:updateComponentJoints(entry, placeComponents)
	if self.isServer and entry.componentJoints ~= nil then
		for _, joint in ipairs(entry.componentJoints) do
			local componentJoint = joint.componentJoint
			local jointNode = componentJoint.jointNode

			if joint.anchorActor == 1 then
				jointNode = componentJoint.jointNodeActor1
			end

			if placeComponents then
				local node = self.components[componentJoint.componentIndices[2]].node
				local x, y, z = localToWorld(jointNode, joint.x, joint.y, joint.z)
				local upX, upY, upZ = localDirectionToWorld(jointNode, joint.upX, joint.upY, joint.upZ)
				local dirX, dirY, dirZ = localDirectionToWorld(jointNode, joint.dirX, joint.dirY, joint.dirZ)

				setWorldTranslation(node, x, y, z)
				I3DUtil.setWorldDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
			end

			self:setComponentJointFrame(componentJoint, joint.anchorActor)
		end
	end
end

function Cylindered:updateAttacherJoints(entry)
	if self.isServer then
		if entry.attacherJoints ~= nil then
			for _, joint in ipairs(entry.attacherJoints) do
				if joint.jointIndex ~= 0 then
					setJointFrame(joint.jointIndex, 0, joint.jointTransform)
				end
			end
		end

		if entry.inputAttacherJoint and self.getAttacherVehicle ~= nil then
			local attacherVehicle = self:getAttacherVehicle()

			if attacherVehicle ~= nil then
				local attacherJoints = attacherVehicle:getAttacherJoints()

				if attacherJoints ~= nil then
					local jointDescIndex = attacherVehicle:getAttacherJointIndexFromObject(self)

					if jointDescIndex ~= nil then
						local jointDesc = attacherJoints[jointDescIndex]
						local inputAttacherJoint = self:getActiveInputAttacherJoint()

						if inputAttacherJoint ~= nil then
							local xNew = jointDesc.jointOrigTrans[1] + jointDesc.jointPositionOffset[1]
							local yNew = jointDesc.jointOrigTrans[2] + jointDesc.jointPositionOffset[2]
							local zNew = jointDesc.jointOrigTrans[3] + jointDesc.jointPositionOffset[3]
							local ox, oy, oz = getTranslation(jointDesc.jointTransform)

							setTranslation(jointDesc.jointTransform, unpack(jointDesc.jointOrigTrans))

							local x, y, z = localToWorld(getParent(jointDesc.jointTransform), xNew, yNew, zNew)
							local x1, y1, z1 = worldToLocal(jointDesc.jointTransform, x, y, z)

							setTranslation(jointDesc.jointTransform, ox, oy, oz)

							x, y, z = localToWorld(inputAttacherJoint.node, x1, y1, z1)
							local x2, y2, z2 = worldToLocal(getParent(inputAttacherJoint.node), x, y, z)

							setTranslation(inputAttacherJoint.node, x2, y2, z2)
							setJointFrame(jointDesc.jointIndex, 1, inputAttacherJoint.node)
							setTranslation(inputAttacherJoint.node, unpack(inputAttacherJoint.jointOrigTrans))
						end
					end
				end
			end
		end
	end
end

function Cylindered.limitInterpolator(first, second, alpha)
	local oneMinusAlpha = 1 - alpha
	local rotMin, rotMax, transMin, transMax = nil

	if first.rotMin ~= nil and second.rotMin ~= nil then
		rotMin = first.rotMin * alpha + second.rotMin * oneMinusAlpha
	end

	if first.rotMax ~= nil and second.rotMax ~= nil then
		rotMax = first.rotMax * alpha + second.rotMax * oneMinusAlpha
	end

	if first.transMin ~= nil and second.transMin ~= nil then
		transMin = first.minTrans * alpha + second.transMin * oneMinusAlpha
	end

	if first.transMax ~= nil and second.transMax ~= nil then
		transMax = first.transMax * alpha + second.transMax * oneMinusAlpha
	end

	return rotMin, rotMax, transMin, transMax
end

function Cylindered:updateRotationBasedLimits(tool, dependentTool)
	if dependentTool.rotationBasedLimits ~= nil then
		local state = Cylindered.getMovingToolState(self, tool)

		if dependentTool.rotationBasedLimits ~= nil then
			local minRot, maxRot, minTrans, maxTrans = dependentTool.rotationBasedLimits:get(state)

			if minRot ~= nil then
				dependentTool.movingTool.rotMin = minRot
			end

			if maxRot ~= nil then
				dependentTool.movingTool.rotMax = maxRot
			end

			if minTrans ~= nil then
				dependentTool.movingTool.transMin = minTrans
			end

			if maxTrans ~= nil then
				dependentTool.movingTool.transMax = maxTrans
			end

			local isDirty = false

			if minRot ~= nil or maxRot ~= nil then
				isDirty = isDirty or Cylindered.setToolRotation(self, dependentTool.movingTool, 0, 0)
			end

			if minTrans ~= nil or maxTrans ~= nil then
				isDirty = isDirty or Cylindered.setToolTranslation(self, dependentTool.movingTool, 0, 0)
			end

			if isDirty then
				Cylindered.setDirty(self, dependentTool.movingTool)
				self:raiseDirtyFlags(dependentTool.movingTool.dirtyFlag)
				self:raiseDirtyFlags(self.spec_cylindered.cylinderedDirtyFlag)
			end
		end
	end
end

function Cylindered:actionEventInput(actionName, inputValue, callbackState, isAnalog, isMouse)
	local spec = self.spec_cylindered
	local tool = spec.movingTools[callbackState]

	if tool ~= nil then
		tool.lastInputTime = g_time
		local move = nil

		if tool.invertAxis then
			move = -inputValue
		else
			move = inputValue
		end

		move = move * g_gameSettings:getValue(GameSettings.SETTING.VEHICLE_ARM_SENSITIVITY)

		if isMouse then
			move = move * 16.666 / g_currentDt * tool.mouseSpeedFactor

			if tool.moveLocked then
				if math.abs(inputValue) < 0.75 then
					if math.abs(move) > math.abs(tool.lockTool.move) * 2 then
						tool.moveLocked = false
					else
						move = 0
					end
				else
					tool.moveLocked = false
				end
			else
				local function checkOtherTools(tools)
					for tool2Index, tool2 in ipairs(tools) do
						if tool2Index ~= callbackState and tool2.move ~= nil and tool2.move ~= 0 then
							if math.abs(tool2.move) < math.abs(move) then
								tool2.move = 0
								tool2.moveToSend = 0
								tool2.moveLocked = true
								tool2.lockTool = tool
							else
								move = 0
								tool.moveLocked = true
								tool.lockTool = tool2
							end
						end
					end
				end

				checkOtherTools(spec.movingTools)

				if self.getAttachedImplements ~= nil then
					for _, implement in pairs(self:getAttachedImplements()) do
						local vehicle = implement.object

						if vehicle.spec_cylindered ~= nil then
							checkOtherTools(vehicle.spec_cylindered.movingTools)
						end
					end
				end
			end
		end

		if move ~= tool.move then
			tool.move = move
		end

		if tool.move ~= tool.moveToSend then
			tool.moveToSend = tool.move

			self:raiseDirtyFlags(spec.cylinderedInputDirtyFlag)
		end

		tool.smoothedMove = tool.smoothedMove * 0.9 + move * 0.1
	end
end

function Cylindered:getMovingToolDashboardState(dashboard)
	local vehicle = self

	if dashboard.attacherJointIndex ~= nil then
		local implement = self:getImplementFromAttacherJointIndex(dashboard.attacherJointIndex)

		if implement ~= nil then
			vehicle = implement.object
		else
			vehicle = nil
		end
	end

	if vehicle ~= nil then
		local spec = vehicle.spec_cylindered

		if spec ~= nil then
			for _, movingTool in ipairs(spec.movingTools) do
				if movingTool.axis == dashboard.axis then
					return (movingTool.smoothedMove + 1) / 2
				end
			end
		end
	end

	return 0.5
end

function Cylindered:movingToolDashboardAttributes(xmlFile, key, dashboard)
	dashboard.axis = xmlFile:getValue(key .. "#axis")

	if dashboard.axis == nil then
		Logging.xmlWarning(xmlFile, "Misssing axis attribute for dashboard '%s'", key)

		return false
	end

	dashboard.attacherJointIndex = xmlFile:getValue(key .. "#attacherJointIndex")

	return true
end
