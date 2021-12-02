AttacherJoints = {
	DEFAULT_MAX_UPDATE_DISTANCE = 50,
	MAX_ATTACH_DISTANCE_SQ = 0.48999999999999994,
	MAX_ATTACH_ANGLE = 0.34202,
	SMOOTH_ATTACH_TIME = 500,
	NUM_JOINTTYPES = 0,
	jointTypeNameToInt = {}
}

function AttacherJoints.initSpecialization()
	g_configurationManager:addConfigurationType("attacherJoint", g_i18n:getText("configuration_attacherJoint"), "attacherJoints", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)
	Vehicle.registerStateChange("ATTACH")
	Vehicle.registerStateChange("DETACH")
	Vehicle.registerStateChange("LOWER_ALL_IMPLEMENTS")

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("AttacherJoints")
	AttacherJoints.registerAttacherJointXMLPaths(schema, "vehicle.attacherJoints.attacherJoint(?)")
	AttacherJoints.registerAttacherJointXMLPaths(schema, "vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(?).attacherJoint(?)")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(?)")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.attacherJoints.sounds", "hydraulic")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.attacherJoints.sounds", "attach")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.attacherJoints.sounds", "detach")
	schema:register(XMLValueType.FLOAT, "vehicle.attacherJoints#comboDuration", "Combo duration", 2)
	schema:register(XMLValueType.INT, "vehicle.attacherJoints#connectionHoseConfigId", "Connection hose configuration index to use")
	schema:register(XMLValueType.INT, "vehicle.attacherJoints#powerTakeOffConfigId", "Power take off configuration index to use")
	schema:register(XMLValueType.INT, "vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(?)#connectionHoseConfigId", "Connection hose configuration index to use")
	schema:register(XMLValueType.INT, "vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(?)#powerTakeOffConfigId", "Power take off configuration index to use")
	schema:register(XMLValueType.FLOAT, "vehicle.attacherJoints#maxUpdateDistance", "Max. distance to vehicle root to update attacher joint graphics", AttacherJoints.DEFAULT_MAX_UPDATE_DISTANCE)
	schema:register(XMLValueType.VECTOR_N, Dashboard.GROUP_XML_KEY .. "#attacherJointIndices", "Attacher joint indices")
	schema:register(XMLValueType.VECTOR_N, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. ".heightNode(?)#disablingAttacherJointIndices", "Attacher joint indices that disable heigth node if something is attached")
	schema:register(XMLValueType.VECTOR_N, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. ".heightNode(?)#disablingAttacherJointIndices", "Attacher joint indices that disable heigth node if something is attached")
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame

	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).attacherJoints#comboDirection", "Current combo direction")
	schemaSavegame:register(XMLValueType.INT, "vehicles.attachments(?)#rootVehicleId", "Root vehicle id")
	schemaSavegame:register(XMLValueType.INT, "vehicles.attachments(?).attachment(?)#attachmentId", "Attachment vehicle id")
	schemaSavegame:register(XMLValueType.INT, "vehicles.attachments(?).attachment(?)#inputJointDescIndex", "Index of input attacher joint", 1)
	schemaSavegame:register(XMLValueType.INT, "vehicles.attachments(?).attachment(?)#jointIndex", "Index of attacher joint")
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.attachments(?).attachment(?)#moveDown", "Attachment lowered or lifted")
end

function AttacherJoints.registerAttacherJointXMLPaths(schema, baseName)
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#node", "Node")
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#nodeVisual", "Visual node")
	schema:register(XMLValueType.BOOL, baseName .. "#supportsHardAttach", "Supports hard attach")
	schema:register(XMLValueType.STRING, baseName .. "#jointType", "Joint type", "implement")
	schema:register(XMLValueType.STRING, baseName .. ".subType#name", "If defined this type needs to match with the sub type in the tool")
	schema:register(XMLValueType.STRING, baseName .. ".subType#brandRestriction", "If defined it's only possible to attach tools from these brands (can be multiple separated by ' ')")
	schema:register(XMLValueType.STRING, baseName .. ".subType#vehicleRestriction", "If defined it's only possible to attach tools containing these strings in there xml path (can be multiple separated by ' ')")
	schema:register(XMLValueType.BOOL, baseName .. "#allowsJointLimitMovement", "Allows joint limit movement", true)
	schema:register(XMLValueType.BOOL, baseName .. "#allowsLowering", "Allows lowering", true)
	schema:register(XMLValueType.BOOL, baseName .. "#isDefaultLowered", "Default lowered state", false)
	schema:register(XMLValueType.BOOL, baseName .. "#allowDetachingWhileLifted", "Allow detach while lifted", true)
	schema:register(XMLValueType.BOOL, baseName .. "#allowFoldingWhileAttached", "Allow folding while attached", true)
	schema:register(XMLValueType.BOOL, baseName .. "#canTurnOnImplement", "Can turn on implement", true)
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".rotationNode#node", "Rotation node")
	schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode#lowerRotation", "Lower rotation", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode#upperRotation", "Upper rotation", "rotation in i3d")
	schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode#startRotation", "Start rotation", "rotation in i3d")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".rotationNode2#node", "Rotation node")
	schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode2#lowerRotation", "Lower rotation", "0 0 0")
	schema:register(XMLValueType.VECTOR_ROT, baseName .. ".rotationNode2#upperRotation", "Upper rotation", "rotation in i3d")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".transNode#node", "Translation node")
	schema:register(XMLValueType.FLOAT, baseName .. ".transNode#height", "Height of visual translation node", 0.12)
	schema:register(XMLValueType.FLOAT, baseName .. ".transNode#minY", "Min Y translation")
	schema:register(XMLValueType.FLOAT, baseName .. ".transNode#maxY", "Max Y translation")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".transNode.dependentBottomArm#node", "Dependent bottom arm node")
	schema:register(XMLValueType.FLOAT, baseName .. ".transNode.dependentBottomArm#threshold", "If the trans node Y translation is below this threshold the rotation will be set", "unlimited, so rotation is always set")
	schema:register(XMLValueType.VECTOR_ROT, baseName .. ".transNode.dependentBottomArm#rotation", "Rotation to be set when the translation node is below the threshold", "0 0 0")
	schema:register(XMLValueType.FLOAT, baseName .. ".distanceToGround#lower", "Lower distance to ground", 0.7)
	schema:register(XMLValueType.FLOAT, baseName .. ".distanceToGround#upper", "Upper distance to ground", 1)
	schema:register(XMLValueType.ANGLE, baseName .. "#lowerRotationOffset", "Upper rotation offset", 0)
	schema:register(XMLValueType.ANGLE, baseName .. "#upperRotationOffset", "Lower rotation offset", 0)
	schema:register(XMLValueType.BOOL, baseName .. "#lockDownRotLimit", "Lock down rotation limit", false)
	schema:register(XMLValueType.BOOL, baseName .. "#lockUpRotLimit", "Lock up rotation limit", false)
	schema:register(XMLValueType.BOOL, baseName .. "#lockDownTransLimit", "Lock down translation limit", true)
	schema:register(XMLValueType.BOOL, baseName .. "#lockUpTransLimit", "Lock up translation limit", false)
	schema:register(XMLValueType.VECTOR_ROT, baseName .. "#lowerRotLimit", "Lower rotation limit", "(20 20 20) for implement type, otherwise (0 0 0)")
	schema:register(XMLValueType.VECTOR_ROT, baseName .. "#upperRotLimit", "Upper rotation limit", "Lower rot limit")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#lowerTransLimit", "Lower translation limit", "(0.5 0.5 0.5) for implement type, otherwise (0 0 0)")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#upperTransLimit", "Upper translation limit", "Lower trans limit")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#jointPositionOffset", "Joint position offset", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitSpring", "Rotation limit spring", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitDamping", "Rotation limit damping", "1 1 1")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitForceLimit", "Rotation limit force limit", "-1 -1 -1")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitSpring", "Translation limit spring", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitDamping", "Translation limit damping", "1 1 1")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitForceLimit", "Translation limit force limit", "-1 -1 -1")
	schema:register(XMLValueType.FLOAT, baseName .. "#moveTime", "Move time", 0.5)
	schema:register(XMLValueType.BOOL, baseName .. "#enableCollision", "Collision between vehicle is enabled", false)
	schema:register(XMLValueType.STRING, baseName .. ".topArm#filename", "Path to top arm i3d file")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".topArm#baseNode", "Link node for upper link")
	schema:register(XMLValueType.INT, baseName .. ".topArm#zScale", "Inverts top arm direction", 1)
	schema:register(XMLValueType.BOOL, baseName .. ".topArm#toggleVisibility", "Top arm will be hidden on detach", false)
	schema:register(XMLValueType.COLOR, baseName .. ".topArm#color", "Top arm color")
	schema:register(XMLValueType.COLOR, baseName .. ".topArm#color2", "Top arm color 2")
	schema:register(XMLValueType.COLOR, baseName .. ".topArm#decalColor", "Top arm decal color")
	schema:register(XMLValueType.BOOL, baseName .. ".topArm#secondPartUseMainColor", "Second part of upper link (parts on colorMat3) will use main color or color2", true)
	schema:register(XMLValueType.BOOL, baseName .. ".topArm#useBrandDecal", "Defines if the brand decal on the top arm is allowed or not", true)
	schema:register(XMLValueType.INT, baseName .. ".topArm#material", "Top arm material index")
	schema:register(XMLValueType.INT, baseName .. ".topArm#material2", "Top arm material index 2")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".topArm#rotationNode", "Rotation node if top arm not loaded from i3d")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".topArm#translationNode", "Translation node if top arm not loaded from i3d")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".topArm#referenceNode", "Reference node if top arm not loaded from i3d")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#rotationNode", "Rotation node of bottom arm")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#translationNode", "Translation node of bottom arm")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".bottomArm#referenceNode", "Reference node of bottom arm")
	schema:register(XMLValueType.VECTOR_ROT, baseName .. ".bottomArm#startRotation", "Start rotation", "values set in i3d")
	schema:register(XMLValueType.INT, baseName .. ".bottomArm#zScale", "Inverts bottom arm direction", 1)
	schema:register(XMLValueType.BOOL, baseName .. ".bottomArm#lockDirection", "Lock direction", true)
	schema:register(XMLValueType.ANGLE, baseName .. ".bottomArm#resetSpeed", "Speed of bottom arm to return to idle position (deg/sec)", 45)
	schema:register(XMLValueType.BOOL, baseName .. ".bottomArm#toggleVisibility", "Bottom arm will be hidden on detach", false)
	schema:register(XMLValueType.STRING, baseName .. ".toolbar#filename", "Filename to toolbar i3d", "$data/shared/assets/toolbar.i3d")
	SoundManager.registerSampleXMLPaths(schema, baseName, "attachSound")
	SoundManager.registerSampleXMLPaths(schema, baseName, "detachSound")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".steeringBars#leftNode", "Steering bar left node")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".steeringBars#rightNode", "Steering bar right node")
	schema:register(XMLValueType.BOOL, baseName .. ".steeringBars#forceUsage", "Forces usage of tools steering axle even if no steering bars are defined", true)
	schema:register(XMLValueType.NODE_INDICES, baseName .. ".visuals#nodes", "Visual nodes of attacher joint that will be visible when the joint is active")
	schema:register(XMLValueType.NODE_INDICES, baseName .. ".visuals#hide", "Visual nodes that will be hidden while attacher joint is active if there attacher is inactive")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, baseName)
	schema:register(XMLValueType.BOOL, baseName .. "#delayedObjectChanges", "Defines if object change is deactivated after the bottomArm has moved (if available)", true)
	schema:register(XMLValueType.BOOL, baseName .. "#delayedObjectChangesOnAttach", "Defines if object change is activated on attach or post attach", false)
	schema:register(XMLValueType.INT, baseName .. ".additionalAttachment#attacherJointDirection", "Attacher joint direction")
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#rootNode", "Root node", "first component")
	schema:register(XMLValueType.FLOAT, baseName .. "#comboTime", "Combo time")
	schema:register(XMLValueType.VECTOR_2, baseName .. ".schema#position", "Schema position")
	schema:register(XMLValueType.VECTOR_2, baseName .. ".schema#liftedOffset", "Offset if lifted", "0 5")
	schema:register(XMLValueType.ANGLE, baseName .. ".schema#rotation", "Schema rotation", 0)
	schema:register(XMLValueType.BOOL, baseName .. ".schema#invertX", "Invert X", false)
end

function AttacherJoints.registerJointType(name)
	local key = "JOINTTYPE_" .. string.upper(name)

	if AttacherJoints[key] == nil then
		AttacherJoints.NUM_JOINTTYPES = AttacherJoints.NUM_JOINTTYPES + 1
		AttacherJoints[key] = AttacherJoints.NUM_JOINTTYPES
		AttacherJoints.jointTypeNameToInt[name] = AttacherJoints.NUM_JOINTTYPES
	end
end

AttacherJoints.registerJointType("implement")
AttacherJoints.registerJointType("trailer")
AttacherJoints.registerJointType("trailerLow")
AttacherJoints.registerJointType("trailerSaddled")
AttacherJoints.registerJointType("telehandler")
AttacherJoints.registerJointType("frontloader")
AttacherJoints.registerJointType("loaderFork")
AttacherJoints.registerJointType("semitrailer")
AttacherJoints.registerJointType("semitrailerHook")
AttacherJoints.registerJointType("semitrailerCar")
AttacherJoints.registerJointType("attachableFrontloader")
AttacherJoints.registerJointType("wheelLoader")
AttacherJoints.registerJointType("manureBarrel")
AttacherJoints.registerJointType("cutter")
AttacherJoints.registerJointType("cutterHarvester")
AttacherJoints.registerJointType("cutterTrailer")
AttacherJoints.registerJointType("skidSteer")
AttacherJoints.registerJointType("conveyor")
AttacherJoints.registerJointType("hookLift")
AttacherJoints.registerJointType("bigBag")
AttacherJoints.registerJointType("train")

function AttacherJoints.prerequisitesPresent(specializations)
	return true
end

function AttacherJoints.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onPreAttachImplement")
	SpecializationUtil.registerEvent(vehicleType, "onPostAttachImplement")
	SpecializationUtil.registerEvent(vehicleType, "onPreDetachImplement")
	SpecializationUtil.registerEvent(vehicleType, "onPostDetachImplement")
end

function AttacherJoints.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "saveAttachmentsToXMLFile", AttacherJoints.saveAttachmentsToXMLFile)
	SpecializationUtil.registerFunction(vehicleType, "loadAttachmentsFromXMLFile", AttacherJoints.loadAttachmentsFromXMLFile)
	SpecializationUtil.registerFunction(vehicleType, "loadAttachmentsFinished", AttacherJoints.loadAttachmentsFinished)
	SpecializationUtil.registerFunction(vehicleType, "handleLowerImplementEvent", AttacherJoints.handleLowerImplementEvent)
	SpecializationUtil.registerFunction(vehicleType, "handleLowerImplementByAttacherJointIndex", AttacherJoints.handleLowerImplementByAttacherJointIndex)
	SpecializationUtil.registerFunction(vehicleType, "getAttachedImplements", AttacherJoints.getAttachedImplements)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJoints", AttacherJoints.getAttacherJoints)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJointByJointDescIndex", AttacherJoints.getAttacherJointByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getImplementFromAttacherJointIndex", AttacherJoints.getImplementFromAttacherJointIndex)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJointIndexFromObject", AttacherJoints.getAttacherJointIndexFromObject)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJointDescFromObject", AttacherJoints.getAttacherJointDescFromObject)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherJointIndexFromImplementIndex", AttacherJoints.getAttacherJointIndexFromImplementIndex)
	SpecializationUtil.registerFunction(vehicleType, "getObjectFromImplementIndex", AttacherJoints.getObjectFromImplementIndex)
	SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointGraphics", AttacherJoints.updateAttacherJointGraphics)
	SpecializationUtil.registerFunction(vehicleType, "calculateAttacherJointMoveUpperLowerAlpha", AttacherJoints.calculateAttacherJointMoveUpperLowerAlpha)
	SpecializationUtil.registerFunction(vehicleType, "doGroundHeightNodeCheck", AttacherJoints.doGroundHeightNodeCheck)
	SpecializationUtil.registerFunction(vehicleType, "finishGroundHeightNodeCheck", AttacherJoints.finishGroundHeightNodeCheck)
	SpecializationUtil.registerFunction(vehicleType, "groundHeightNodeCheckCallback", AttacherJoints.groundHeightNodeCheckCallback)
	SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointRotation", AttacherJoints.updateAttacherJointRotation)
	SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointRotationNodes", AttacherJoints.updateAttacherJointRotationNodes)
	SpecializationUtil.registerFunction(vehicleType, "updateAttacherJointSettingsByObject", AttacherJoints.updateAttacherJointSettingsByObject)
	SpecializationUtil.registerFunction(vehicleType, "attachImplementFromInfo", AttacherJoints.attachImplementFromInfo)
	SpecializationUtil.registerFunction(vehicleType, "attachImplement", AttacherJoints.attachImplement)
	SpecializationUtil.registerFunction(vehicleType, "postAttachImplement", AttacherJoints.postAttachImplement)
	SpecializationUtil.registerFunction(vehicleType, "createAttachmentJoint", AttacherJoints.createAttachmentJoint)
	SpecializationUtil.registerFunction(vehicleType, "hardAttachImplement", AttacherJoints.hardAttachImplement)
	SpecializationUtil.registerFunction(vehicleType, "hardDetachImplement", AttacherJoints.hardDetachImplement)
	SpecializationUtil.registerFunction(vehicleType, "detachImplement", AttacherJoints.detachImplement)
	SpecializationUtil.registerFunction(vehicleType, "detachImplementByObject", AttacherJoints.detachImplementByObject)
	SpecializationUtil.registerFunction(vehicleType, "playAttachSound", AttacherJoints.playAttachSound)
	SpecializationUtil.registerFunction(vehicleType, "playDetachSound", AttacherJoints.playDetachSound)
	SpecializationUtil.registerFunction(vehicleType, "detachingIsPossible", AttacherJoints.detachingIsPossible)
	SpecializationUtil.registerFunction(vehicleType, "attachAdditionalAttachment", AttacherJoints.attachAdditionalAttachment)
	SpecializationUtil.registerFunction(vehicleType, "detachAdditionalAttachment", AttacherJoints.detachAdditionalAttachment)
	SpecializationUtil.registerFunction(vehicleType, "getImplementIndexByJointDescIndex", AttacherJoints.getImplementIndexByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getImplementByJointDescIndex", AttacherJoints.getImplementByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getImplementIndexByObject", AttacherJoints.getImplementIndexByObject)
	SpecializationUtil.registerFunction(vehicleType, "getImplementByObject", AttacherJoints.getImplementByObject)
	SpecializationUtil.registerFunction(vehicleType, "callFunctionOnAllImplements", AttacherJoints.callFunctionOnAllImplements)
	SpecializationUtil.registerFunction(vehicleType, "activateAttachments", AttacherJoints.activateAttachments)
	SpecializationUtil.registerFunction(vehicleType, "deactivateAttachments", AttacherJoints.deactivateAttachments)
	SpecializationUtil.registerFunction(vehicleType, "deactivateAttachmentsLights", AttacherJoints.deactivateAttachmentsLights)
	SpecializationUtil.registerFunction(vehicleType, "setJointMoveDown", AttacherJoints.setJointMoveDown)
	SpecializationUtil.registerFunction(vehicleType, "getJointMoveDown", AttacherJoints.getJointMoveDown)
	SpecializationUtil.registerFunction(vehicleType, "getIsHardAttachAllowed", AttacherJoints.getIsHardAttachAllowed)
	SpecializationUtil.registerFunction(vehicleType, "loadAttacherJointFromXML", AttacherJoints.loadAttacherJointFromXML)
	SpecializationUtil.registerFunction(vehicleType, "onTopArmI3DLoaded", AttacherJoints.onTopArmI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "onBottomArmToolbarI3DLoaded", AttacherJoints.onBottomArmToolbarI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "setSelectedImplementByObject", AttacherJoints.setSelectedImplementByObject)
	SpecializationUtil.registerFunction(vehicleType, "getSelectedImplement", AttacherJoints.getSelectedImplement)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleAttach", AttacherJoints.getCanToggleAttach)
	SpecializationUtil.registerFunction(vehicleType, "getShowDetachAttachedImplement", AttacherJoints.getShowDetachAttachedImplement)
	SpecializationUtil.registerFunction(vehicleType, "detachAttachedImplement", AttacherJoints.detachAttachedImplement)
	SpecializationUtil.registerFunction(vehicleType, "startAttacherJointCombo", AttacherJoints.startAttacherJointCombo)
	SpecializationUtil.registerFunction(vehicleType, "registerSelfLoweringActionEvent", AttacherJoints.registerSelfLoweringActionEvent)
	SpecializationUtil.registerFunction(vehicleType, "getIsAttachingAllowed", AttacherJoints.getIsAttachingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getCanSteerAttachable", AttacherJoints.getCanSteerAttachable)
end

function AttacherJoints.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "raiseActive", AttacherJoints.raiseActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerActionEvents", AttacherJoints.registerActionEvents)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeActionEvents", AttacherJoints.removeActionEvents)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AttacherJoints.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", AttacherJoints.removeFromPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTotalMass", AttacherJoints.getTotalMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addChildVehicles", AttacherJoints.addChildVehicles)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAirConsumerUsage", AttacherJoints.getAirConsumerUsage)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addVehicleToAIImplementList", AttacherJoints.addVehicleToAIImplementList)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "collectAIAgentAttachments", AttacherJoints.collectAIAgentAttachments)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setAIVehicleObstacleStateDirty", AttacherJoints.setAIVehicleObstacleStateDirty)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirectionSnapAngle", AttacherJoints.getDirectionSnapAngle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAICollisionTriggers", AttacherJoints.getAICollisionTriggers)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillLevelInformation", AttacherJoints.getFillLevelInformation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "attachableAddToolCameras", AttacherJoints.attachableAddToolCameras)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "attachableRemoveToolCameras", AttacherJoints.attachableRemoveToolCameras)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerSelectableObjects", AttacherJoints.registerSelectableObjects)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", AttacherJoints.getIsReadyForAutomatedTrainTravel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAutomaticShiftingAllowed", AttacherJoints.getIsAutomaticShiftingAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", AttacherJoints.loadDashboardGroupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", AttacherJoints.getIsDashboardGroupActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAttacherJointHeightNode", AttacherJoints.loadAttacherJointHeightNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttacherJointHeightNodeActive", AttacherJoints.getIsAttacherJointHeightNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", AttacherJoints.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", AttacherJoints.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWheelFoliageDestructionAllowed", AttacherJoints.getIsWheelFoliageDestructionAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", AttacherJoints.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConnectionHoseConfigIndex", AttacherJoints.getConnectionHoseConfigIndex)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPowerTakeOffConfigIndex", AttacherJoints.getPowerTakeOffConfigIndex)
end

function AttacherJoints.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onPreLoad", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDelete", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onLightsTypesMaskChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnLightStateChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onBrakeLightsVisibilityChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onReverseLightsVisibilityChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onBeaconLightsVisibilityChanged", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onBrake", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onActivate", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", AttacherJoints)
	SpecializationUtil.registerEventListener(vehicleType, "onReverseDirectionChanged", AttacherJoints)
end

function AttacherJoints:onPreLoad(savegame)
	local spec = self.spec_attacherJoints
	spec.attachedImplements = {}
	spec.selectedImplement = nil
	spec.lastInputAttacherCheckIndex = 0
end

function AttacherJoints:onLoad(savegame)
	local spec = self.spec_attacherJoints
	spec.attacherJointCombos = {
		duration = self.xmlFile:getValue("vehicle.attacherJoints#comboDuration", 2) * 1000,
		currentTime = 0,
		direction = -1,
		isRunning = false,
		joints = {}
	}
	spec.maxUpdateDistance = self.xmlFile:getValue("vehicle.attacherJoints#maxUpdateDistance", AttacherJoints.DEFAULT_MAX_UPDATE_DISTANCE)
	spec.visualNodeToAttacherJoints = {}
	spec.hideVisualNodeToAttacherJoints = {}
	spec.attacherJoints = {}
	local i = 0

	while true do
		local baseName = string.format("vehicle.attacherJoints.attacherJoint(%d)", i)

		if not self.xmlFile:hasProperty(baseName) then
			break
		end

		local attacherJoint = {}

		if self:loadAttacherJointFromXML(attacherJoint, self.xmlFile, baseName, i) then
			table.insert(spec.attacherJoints, attacherJoint)

			attacherJoint.index = #spec.attacherJoints
		end

		i = i + 1
	end

	if self.configurations.attacherJoint ~= nil then
		local attacherConfigs = string.format("vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(%d)", self.configurations.attacherJoint - 1)
		i = 0

		while true do
			local baseName = string.format(attacherConfigs .. ".attacherJoint(%d)", i)

			if not self.xmlFile:hasProperty(baseName) then
				break
			end

			local attacherJoint = {}

			if self:loadAttacherJointFromXML(attacherJoint, self.xmlFile, baseName, i) then
				table.insert(spec.attacherJoints, attacherJoint)
			end

			i = i + 1
		end

		ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration", self.configurations.attacherJoint, self.components, self)
	end

	spec.attachableInfo = {
		attacherVehicle = nil,
		attacherVehicleJointDescIndex = nil,
		attachable = nil,
		attachableJointDescIndex = nil
	}
	spec.pendingAttachableInfo = {
		minDistance = math.huge,
		minDistanceY = math.huge,
		attacherVehicle = nil,
		attacherVehicleJointDescIndex = nil,
		attachable = nil,
		attachableJointDescIndex = nil,
		warning = nil
	}

	if self.isClient then
		spec.samples = {}
		spec.isHydraulicSamplePlaying = false
		spec.samples.hydraulic = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJoints.sounds", "hydraulic", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		spec.samples.attach = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJoints.sounds", "attach", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		spec.samples.detach = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.attacherJoints.sounds", "detach", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end

	if self.isClient and g_isDevelopmentVersion then
		for k, attacherJoint in ipairs(spec.attacherJoints) do
			if spec.samples.attach == nil and attacherJoint.sampleAttach == nil then
				Logging.xmlDevWarning(self.xmlFile, "Missing attach sound for attacherjoint '%d'", k)
			end

			if attacherJoint.rotationNode ~= nil and spec.samples.hydraulic == nil then
				Logging.xmlDevWarning(self.xmlFile, "Missing hydraulic sound for attacherjoint '%d'", k)
			end
		end
	end

	spec.showAttachNotAllowedText = 0
	spec.wasInAttachRange = false
	spec.texts = {
		warningToolNotCompatible = g_i18n:getText("warning_toolNotCompatible"),
		warningToolBrandNotCompatible = g_i18n:getText("warning_toolBrandNotCompatible"),
		infoAttachNotAllowed = g_i18n:getText("info_attach_not_allowed"),
		lowerImplementFirst = g_i18n:getText("warning_lowerImplementFirst"),
		detachNotAllowed = g_i18n:getText("warning_detachNotAllowed"),
		actionAttach = g_i18n:getText("action_attach"),
		actionDetach = g_i18n:getText("action_detach"),
		warningFoldingAttacherJoint = g_i18n:getText("warning_foldingNotWhileAttachedToAttacherJoint")
	}
	spec.groundHeightNodeCheckData = {
		isDirty = false,
		currentRaycastDistance = 1,
		lowerDistanceToGround = 0,
		index = -1,
		upperAlpha = 0,
		raycastDistance = 1,
		hit = false,
		lowerAlpha = 0,
		upperDistanceToGround = 0,
		minDistance = math.huge,
		heightNodes = {},
		jointDesc = {},
		currentRaycastWorldPos = {
			0,
			0,
			0
		},
		currentRaycastWorldDir = {
			0,
			0,
			0
		},
		currentJointTransformPos = {
			0,
			0,
			0
		},
		raycastWorldPos = {
			0,
			0,
			0
		},
		raycastWorldDir = {
			0,
			0,
			0
		},
		jointTransformPos = {
			0,
			0,
			0
		}
	}
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function AttacherJoints:onPostLoad(savegame)
	local spec = self.spec_attacherJoints

	for _, attacherJoint in pairs(spec.attacherJoints) do
		attacherJoint.jointOrigRot = {
			getRotation(attacherJoint.jointTransform)
		}
		attacherJoint.jointOrigTrans = {
			getTranslation(attacherJoint.jointTransform)
		}

		if attacherJoint.transNode ~= nil then
			attacherJoint.transNodeMinY = Utils.getNoNil(attacherJoint.transNodeMinY, attacherJoint.jointOrigTrans[2])
			attacherJoint.transNodeMaxY = Utils.getNoNil(attacherJoint.transNodeMaxY, attacherJoint.jointOrigTrans[2])
			_, attacherJoint.transNodeOffsetY, _ = localToLocal(attacherJoint.jointTransform, attacherJoint.transNode, 0, 0, 0)
			_, attacherJoint.transNodeMinY, _ = localToLocal(getParent(attacherJoint.transNode), self.rootNode, 0, attacherJoint.transNodeMinY, 0)
			_, attacherJoint.transNodeMaxY, _ = localToLocal(getParent(attacherJoint.transNode), self.rootNode, 0, attacherJoint.transNodeMaxY, 0)
		end

		if attacherJoint.transNodeDependentBottomArm ~= nil then
			for _, attacherJoint2 in pairs(spec.attacherJoints) do
				if attacherJoint2.bottomArm ~= nil and attacherJoint2.bottomArm.rotationNode == attacherJoint.transNodeDependentBottomArm then
					attacherJoint.transNodeDependentBottomArmAttacherJoint = attacherJoint2
				end
			end

			if attacherJoint.transNodeDependentBottomArmAttacherJoint == nil then
				Logging.xmlWarning(self.xmlFile, "Unable to find dependent bottom arm '%s' in any attacher joint.", getName(attacherJoint.transNodeDependentBottomArm))

				attacherJoint.transNodeDependentBottomArm = nil
			end
		end

		if attacherJoint.bottomArm ~= nil then
			setRotation(attacherJoint.bottomArm.rotationNode, attacherJoint.bottomArm.rotX, attacherJoint.bottomArm.rotY, attacherJoint.bottomArm.rotZ)

			if self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(attacherJoint.bottomArm.rotationNode)
			end
		end

		if attacherJoint.rotationNode ~= nil then
			setRotation(attacherJoint.rotationNode, attacherJoint.rotX, attacherJoint.rotY, attacherJoint.rotZ)
		end

		if self.getInputAttacherJoints ~= nil then
			attacherJoint.inputAttacherJointOffsets = {}

			for _, inputAttacherJoint in ipairs(self:getInputAttacherJoints()) do
				local xDir, yDir, zDir = localDirectionToLocal(attacherJoint.jointTransform, inputAttacherJoint.node, 0, 0, 1)
				local xUp, yUp, zUp = localDirectionToLocal(attacherJoint.jointTransform, inputAttacherJoint.node, 0, 1, 0)
				local xNorm, yNorm, zNorm = localDirectionToLocal(attacherJoint.jointTransform, inputAttacherJoint.node, 1, 0, 0)
				local xOffset, yOffset, zOffset = localToLocal(attacherJoint.jointTransform, inputAttacherJoint.node, 0, 0, 0)

				table.insert(attacherJoint.inputAttacherJointOffsets, {
					xOffset,
					yOffset,
					zOffset,
					xDir,
					yDir,
					zDir,
					xUp,
					yUp,
					zUp,
					xNorm,
					yNorm,
					zNorm
				})
			end
		end

		if self.getAIRootNode ~= nil then
			local aiRootNode = self:getAIRootNode()
			local xDir, yDir, zDir = localDirectionToLocal(attacherJoint.jointTransform, aiRootNode, 0, 0, 1)
			local xUp, yUp, zUp = localDirectionToLocal(attacherJoint.jointTransform, aiRootNode, 0, 1, 0)
			local xNorm, yNorm, zNorm = localDirectionToLocal(attacherJoint.jointTransform, aiRootNode, 1, 0, 0)
			local xOffset, yOffset, zOffset = localToLocal(attacherJoint.jointTransform, aiRootNode, 0, 0, 0)
			attacherJoint.aiRootNodeOffset = {
				xOffset,
				yOffset,
				zOffset,
				xDir,
				yDir,
				zDir,
				xUp,
				yUp,
				zUp,
				xNorm,
				yNorm,
				zNorm
			}
		end
	end

	if savegame ~= nil and not savegame.resetVehicles and spec.attacherJointCombos ~= nil then
		local comboDirection = savegame.xmlFile:getValue(savegame.key .. ".attacherJoints#comboDirection")

		if comboDirection ~= nil then
			spec.attacherJointCombos.direction = comboDirection

			if comboDirection == 1 then
				spec.attacherJointCombos.currentTime = spec.attacherJointCombos.duration
			end
		end
	end

	if #spec.attacherJoints == 0 then
		SpecializationUtil.removeEventListener(self, "onReadStream", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onWriteStream", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onUpdate", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onPostUpdate", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onStateChange", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onLightsTypesMaskChanged", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onTurnLightStateChanged", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onBrakeLightsVisibilityChanged", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onReverseLightsVisibilityChanged", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onBeaconLightsVisibilityChanged", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onBrake", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onTurnedOn", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onTurnedOff", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onLeaveVehicle", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onActivate", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onDeactivate", AttacherJoints)
		SpecializationUtil.removeEventListener(self, "onReverseDirectionChanged", AttacherJoints)
	end
end

function AttacherJoints:onPreDelete()
	local spec = self.spec_attacherJoints

	if spec.attachedImplements ~= nil then
		for i = #spec.attachedImplements, 1, -1 do
			self:detachImplement(1, true)
		end
	end
end

function AttacherJoints:onDelete()
	local spec = self.spec_attacherJoints

	if spec.attacherJoints ~= nil then
		for _, jointDesc in pairs(spec.attacherJoints) do
			g_soundManager:deleteSample(jointDesc.sampleAttach)
			g_soundManager:deleteSample(jointDesc.sampleDetach)

			if jointDesc.sharedLoadRequestIdTopArm ~= nil then
				g_i3DManager:releaseSharedI3DFile(jointDesc.sharedLoadRequestIdTopArm)

				jointDesc.sharedLoadRequestIdTopArm = nil
			end

			local bottomArm = jointDesc.bottomArm

			if bottomArm ~= nil and bottomArm.sharedLoadRequestIdToolbar ~= nil then
				g_i3DManager:releaseSharedI3DFile(bottomArm.sharedLoadRequestIdToolbar)

				bottomArm.sharedLoadRequestIdToolbar = nil
			end
		end

		g_soundManager:deleteSamples(spec.samples)
	end
end

function AttacherJoints:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_attacherJoints

	if spec.attacherJointCombos ~= nil then
		xmlFile:setValue(key .. "#comboDirection", spec.attacherJointCombos.direction)
	end
end

function AttacherJoints:saveAttachmentsToXMLFile(xmlFile, key, vehiclesToId)
	local spec = self.spec_attacherJoints
	local added = false
	local id = vehiclesToId[self]

	if id ~= nil then
		local i = 0

		for _, implement in ipairs(spec.attachedImplements) do
			local object = implement.object

			if object ~= nil and vehiclesToId[object] ~= nil then
				local attachmentKey = string.format("%s.attachment(%d)", key, i)
				local jointDescIndex = implement.jointDescIndex
				local jointDesc = spec.attacherJoints[jointDescIndex]
				local inputJointDescIndex = object:getActiveInputAttacherJointDescIndex()

				xmlFile:setValue(attachmentKey .. "#attachmentId", vehiclesToId[object])
				xmlFile:setValue(attachmentKey .. "#inputJointDescIndex", inputJointDescIndex)
				xmlFile:setValue(attachmentKey .. "#jointIndex", jointDescIndex)
				xmlFile:setValue(attachmentKey .. "#moveDown", jointDesc.moveDown)

				added = true
				i = i + 1
			end
		end

		if added then
			xmlFile:setValue(key .. "#rootVehicleId", id)
		end
	end

	return added
end

function AttacherJoints:onReadStream(streamId, connection)
	local numImplements = streamReadInt8(streamId)

	for i = 1, numImplements do
		local object = NetworkUtil.readNodeObject(streamId)
		local inputJointDescIndex = streamReadInt8(streamId)
		local jointDescIndex = streamReadInt8(streamId)
		local moveDown = streamReadBool(streamId)

		if object ~= nil and object:getIsSynchronized() then
			self:attachImplement(object, inputJointDescIndex, jointDescIndex, true, i, moveDown, true, true)
			self:setJointMoveDown(jointDescIndex, moveDown, true)
		end
	end
end

function AttacherJoints:onWriteStream(streamId, connection)
	local spec = self.spec_attacherJoints

	streamWriteInt8(streamId, #spec.attachedImplements)

	for i = 1, #spec.attachedImplements do
		local implement = spec.attachedImplements[i]
		local inputJointDescIndex = implement.object.spec_attachable.inputAttacherJointDescIndex
		local jointDescIndex = implement.jointDescIndex
		local jointDesc = spec.attacherJoints[jointDescIndex]
		local moveDown = jointDesc.moveDown

		NetworkUtil.writeNodeObject(streamId, implement.object)
		streamWriteInt8(streamId, inputJointDescIndex)
		streamWriteInt8(streamId, jointDescIndex)
		streamWriteBool(streamId, moveDown)
	end
end

function AttacherJoints:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_attacherJoints

	if self.currentUpdateDistance < spec.maxUpdateDistance then
		for _, implement in pairs(spec.attachedImplements) do
			if implement.object ~= nil and self.updateLoopIndex == implement.object.updateLoopIndex then
				self:updateAttacherJointGraphics(implement, dt)
			end
		end
	end

	if self.isClient then
		spec.showAttachNotAllowedText = math.max(spec.showAttachNotAllowedText - dt, 0)

		if spec.showAttachNotAllowedText > 0 then
			g_currentMission:addExtraPrintText(spec.texts.infoAttachNotAllowed)
		end
	end

	local info = spec.attachableInfo

	if Platform.gameplay.automaticAttach and self.isServer or self.isClient and spec.actionEvents ~= nil and spec.actionEvents[InputAction.ATTACH] ~= nil then
		if self:getCanToggleAttach() then
			AttacherJoints.updateVehiclesInAttachRange(self, AttacherJoints.MAX_ATTACH_DISTANCE_SQ, AttacherJoints.MAX_ATTACH_ANGLE, true)
		else
			info.attachableJointDescIndex = nil
			info.attachable = nil
			info.attacherVehicleJointDescIndex = nil
			info.attacherVehicle = nil
		end
	end
end

function AttacherJoints:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		if not implement.attachingIsInProgress then
			local attacherJoint = implement.object:getActiveInputAttacherJoint()

			if attacherJoint ~= nil then
				if spec.attacherJoints[implement.jointDescIndex].steeringBarLeftNode ~= nil and attacherJoint.steeringBarLeftMovingPart ~= nil then
					Cylindered.updateMovingPart(self, attacherJoint.steeringBarLeftMovingPart, nil, true)
				end

				if spec.attacherJoints[implement.jointDescIndex].steeringBarRightNode ~= nil and attacherJoint.steeringBarRightMovingPart ~= nil then
					Cylindered.updateMovingPart(self, attacherJoint.steeringBarRightMovingPart, nil, true)
				end
			end
		end
	end
end

function AttacherJoints:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_attacherJoints
	local playHydraulicSound = false

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil then
			local jointDesc = spec.attacherJoints[implement.jointDescIndex]

			if not implement.object.spec_attachable.isHardAttached then
				if self.isServer and implement.attachingIsInProgress then
					local done = true

					for i = 1, 3 do
						local lastRotLimit = implement.attachingRotLimit[i]
						local lastTransLimit = implement.attachingTransLimit[i]
						implement.attachingRotLimit[i] = math.max(0, implement.attachingRotLimit[i] - implement.attachingRotLimitSpeed[i] * dt)
						implement.attachingTransLimit[i] = math.max(0, implement.attachingTransLimit[i] - implement.attachingTransLimitSpeed[i] * dt)

						if implement.attachingRotLimit[i] > 0 or implement.attachingTransLimit[i] > 0 or lastRotLimit > 0 or lastTransLimit > 0 then
							done = false
						end
					end

					implement.attachingIsInProgress = not done

					if done then
						if implement.object.spec_attachable.attacherJoint.hardAttach and self:getIsHardAttachAllowed(implement.jointDescIndex) then
							self:hardAttachImplement(implement)
						end

						self:postAttachImplement(implement)
					end
				end

				if not implement.attachingIsInProgress then
					local jointFrameInvalid = false

					if jointDesc.allowsLowering and self:getIsActive() then
						local upperAlpha = jointDesc.upperAlpha
						local lowerAlpha = jointDesc.lowerAlpha

						if jointDesc.moveDown then
							upperAlpha, lowerAlpha = self:calculateAttacherJointMoveUpperLowerAlpha(jointDesc, implement.object)
							jointDesc.moveTime = jointDesc.moveDefaultTime * math.abs(upperAlpha - lowerAlpha)
						end

						local moveAlpha = Utils.getMovedLimitedValue(jointDesc.moveAlpha, lowerAlpha, upperAlpha, jointDesc.moveTime, dt, not jointDesc.moveDown)

						if moveAlpha ~= jointDesc.moveAlpha or upperAlpha ~= jointDesc.upperAlpha or lowerAlpha ~= jointDesc.lowerAlpha then
							jointDesc.upperAlpha = upperAlpha
							jointDesc.lowerAlpha = lowerAlpha

							if jointDesc.moveDown then
								if math.abs(jointDesc.moveAlpha - jointDesc.lowerAlpha) < 0.05 then
									jointDesc.isMoving = false
								end
							elseif math.abs(jointDesc.moveAlpha - jointDesc.upperAlpha) < 0.05 then
								jointDesc.isMoving = false
							end

							playHydraulicSound = jointDesc.isMoving
							jointDesc.moveAlpha = moveAlpha
							jointDesc.moveLimitAlpha = 1 - (moveAlpha - jointDesc.lowerAlpha) / (jointDesc.upperAlpha - jointDesc.lowerAlpha)
							jointFrameInvalid = true

							self:updateAttacherJointRotationNodes(jointDesc, jointDesc.moveAlpha)
							self:updateAttacherJointRotation(jointDesc, implement.object)
						end
					end

					jointFrameInvalid = jointFrameInvalid or jointDesc.jointFrameInvalid

					if jointFrameInvalid then
						jointDesc.jointFrameInvalid = false

						if self.isServer then
							setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform)
						end
					end
				end

				if self.isServer then
					local force = implement.attachingIsInProgress

					if (force or jointDesc.allowsLowering and jointDesc.allowsJointLimitMovement) and jointDesc.jointIndex ~= nil and jointDesc.jointIndex ~= 0 then
						if force or implement.object.spec_attachable.attacherJoint.allowsJointRotLimitMovement then
							local alpha = math.max(jointDesc.moveLimitAlpha - implement.rotLimitThreshold, 0) / (1 - implement.rotLimitThreshold)

							for i = 1, 3 do
								AttacherJoints.updateAttacherJointRotationLimit(implement, jointDesc, i, force, alpha)
							end
						end

						if force or implement.object.spec_attachable.attacherJoint.allowsJointTransLimitMovement then
							local alpha = math.max(jointDesc.moveLimitAlpha - implement.transLimitThreshold, 0) / (1 - implement.transLimitThreshold)

							for i = 1, 3 do
								AttacherJoints.updateAttacherJointTranslationLimit(implement, jointDesc, i, force, alpha)
							end
						end
					end
				end
			end
		end
	end

	if self.isClient and spec.samples.hydraulic ~= nil then
		for i = 1, #spec.attacherJoints do
			local jointDesc = spec.attacherJoints[i]

			if jointDesc.bottomArm ~= nil and jointDesc.bottomArm.bottomArmInterpolating then
				playHydraulicSound = true
			end
		end

		if playHydraulicSound then
			if not spec.isHydraulicSamplePlaying then
				g_soundManager:playSample(spec.samples.hydraulic)

				spec.isHydraulicSamplePlaying = true
			end
		elseif spec.isHydraulicSamplePlaying then
			g_soundManager:stopSample(spec.samples.hydraulic)

			spec.isHydraulicSamplePlaying = false
		end
	end

	local combos = spec.attacherJointCombos

	if combos ~= nil and combos.isRunning then
		for _, joint in pairs(combos.joints) do
			local doLowering = nil

			if combos.direction == 1 and joint.time <= combos.currentTime then
				doLowering = true
			elseif combos.direction == -1 and combos.currentTime <= combos.duration - joint.time then
				doLowering = false
			end

			if doLowering ~= nil then
				local implement = self:getImplementFromAttacherJointIndex(joint.jointIndex)

				if implement ~= nil and implement.object.setLoweredAll ~= nil then
					implement.object:setLoweredAll(doLowering, joint.jointIndex)
				end
			end
		end

		if combos.direction == -1 and combos.currentTime == 0 or combos.direction == 1 and combos.currentTime == combos.duration then
			combos.isRunning = false
		end

		combos.currentTime = MathUtil.clamp(combos.currentTime + dt * combos.direction, 0, combos.duration)
	end

	AttacherJoints.updateActionEvents(self)

	if Platform.gameplay.automaticAttach and self.isServer and self:getCanToggleAttach() then
		local info = spec.attachableInfo

		if info.attachable ~= nil and not spec.wasInAttachRange and info.attacherVehicle == self then
			local attachAllowed, warning = info.attachable:isAttachAllowed(self:getActiveFarm(), info.attacherVehicle)

			if attachAllowed then
				if spec.wasInAttachRange == nil then
					spec.wasInAttachRange = true
				else
					self:attachImplementFromInfo(info)
				end
			elseif warning ~= nil then
				g_currentMission:showBlinkingWarning(warning, 2000)
			end
		elseif info.attachable == nil and spec.wasInAttachRange then
			spec.wasInAttachRange = false
		end
	end
end

function AttacherJoints:loadAttachmentsFromXMLFile(xmlFile, key, idsToVehicle)
	local spec = self.spec_attacherJoints
	local i = 0

	while true do
		local attachmentKey = string.format("%s.attachment(%d)", key, i)

		if not xmlFile:hasProperty(attachmentKey) then
			break
		end

		local attachmentId = xmlFile:getValue(attachmentKey .. "#attachmentId")
		local jointIndex = xmlFile:getValue(attachmentKey .. "#jointIndex")
		local inputJointDescIndex = xmlFile:getValue(attachmentKey .. "#inputJointDescIndex", 1)

		if attachmentId ~= nil and jointIndex ~= nil then
			local attachment = idsToVehicle[attachmentId]
			local inputAttacherJoints = nil

			if attachment ~= nil and attachment.getInputAttacherJoints ~= nil then
				inputAttacherJoints = attachment:getInputAttacherJoints()
			end

			local inputAttacherJoint = nil

			if inputAttacherJoints ~= nil then
				inputAttacherJoint = inputAttacherJoints[inputJointDescIndex]
			end

			if inputAttacherJoint ~= nil and spec.attacherJoints[jointIndex] ~= nil and spec.attacherJoints[jointIndex].jointIndex == 0 then
				local moveDown = xmlFile:getValue(attachmentKey .. "#moveDown")

				self:attachImplement(attachment, inputJointDescIndex, jointIndex, true, nil, moveDown, true, true)

				if moveDown ~= nil then
					self:setJointMoveDown(jointIndex, moveDown, true)
				end
			end
		end

		i = i + 1
	end
end

function AttacherJoints:loadAttachmentsFinished()
	if self.rootVehicle == self and self.loadedSelectedObjectIndex ~= nil then
		local object = self.selectableObjects[self.loadedSelectedObjectIndex]

		if object ~= nil then
			self:setSelectedObject(object, self.loadedSubSelectedObjectIndex or 1)
		end

		self.loadedSelectedObjectIndex = nil
		self.loadedSubSelectedObjectIndex = nil
	end
end

function AttacherJoints:handleLowerImplementEvent(vehicle)
	local implement = self:getImplementByObject(vehicle or self:getSelectedVehicle())

	if implement ~= nil then
		local object = implement.object

		if object ~= nil and object.getAttacherVehicle ~= nil then
			local attacherVehicle = object:getAttacherVehicle()

			if attacherVehicle ~= nil then
				local attacherJointIndex = attacherVehicle:getAttacherJointIndexFromObject(object)

				attacherVehicle:handleLowerImplementByAttacherJointIndex(attacherJointIndex)
			end
		end
	end
end

function AttacherJoints:handleLowerImplementByAttacherJointIndex(attacherJointIndex, direction)
	if attacherJointIndex ~= nil then
		local implement = self:getImplementByJointDescIndex(attacherJointIndex)

		if implement ~= nil then
			local object = implement.object
			local attacherJoints = self:getAttacherJoints()
			local attacherJoint = attacherJoints[attacherJointIndex]
			local allowsLowering, warning = object:getAllowsLowering()

			if allowsLowering and attacherJoint.allowsLowering then
				if direction == nil then
					direction = not attacherJoint.moveDown
				end

				self:setJointMoveDown(implement.jointDescIndex, direction, false)
			elseif not allowsLowering and warning ~= nil then
				g_currentMission:showBlinkingWarning(warning, 2000)
			end
		end
	end
end

function AttacherJoints:getAttachedImplements()
	return self.spec_attacherJoints.attachedImplements
end

function AttacherJoints:getAttacherJoints()
	return self.spec_attacherJoints.attacherJoints
end

function AttacherJoints:getAttacherJointByJointDescIndex(jointDescIndex)
	return self.spec_attacherJoints.attacherJoints[jointDescIndex]
end

function AttacherJoints:getImplementFromAttacherJointIndex(attacherJointIndex)
	local spec = self.spec_attacherJoints

	for _, attachedImplement in pairs(spec.attachedImplements) do
		if attachedImplement.jointDescIndex == attacherJointIndex then
			return attachedImplement
		end
	end
end

function AttacherJoints:getAttacherJointIndexFromObject(object)
	local spec = self.spec_attacherJoints

	for _, attachedImplement in pairs(spec.attachedImplements) do
		if attachedImplement.object == object then
			return attachedImplement.jointDescIndex
		end
	end
end

function AttacherJoints:getAttacherJointDescFromObject(object)
	local spec = self.spec_attacherJoints

	for _, attachedImplement in pairs(spec.attachedImplements) do
		if attachedImplement.object == object then
			return spec.attacherJoints[attachedImplement.jointDescIndex]
		end
	end
end

function AttacherJoints:getAttacherJointIndexFromImplementIndex(implementIndex)
	local spec = self.spec_attacherJoints
	local attachedImplement = spec.attachedImplements[implementIndex]

	if attachedImplement ~= nil then
		return attachedImplement.jointDescIndex
	end

	return nil
end

function AttacherJoints:getObjectFromImplementIndex(implementIndex)
	local spec = self.spec_attacherJoints
	local attachedImplement = spec.attachedImplements[implementIndex]

	if attachedImplement ~= nil then
		return attachedImplement.object
	end

	return nil
end

function AttacherJoints:updateAttacherJointGraphics(implement, dt, forceUpdate)
	local spec = self.spec_attacherJoints

	if implement.object ~= nil then
		local jointDesc = spec.attacherJoints[implement.jointDescIndex]
		local attacherJoint = implement.object:getActiveInputAttacherJoint()

		if jointDesc.topArm ~= nil and attacherJoint.topReferenceNode ~= nil then
			local ax, ay, az = getWorldTranslation(jointDesc.topArm.rotationNode)
			local bx, by, bz = getWorldTranslation(attacherJoint.topReferenceNode)
			local x, y, z = worldDirectionToLocal(getParent(jointDesc.topArm.rotationNode), bx - ax, by - ay, bz - az)
			local distance = MathUtil.vector3Length(x, y, z)
			local alpha = math.rad(-90)
			local px, py, pz = getWorldTranslation(jointDesc.topArm.rotationNode)
			local _, _, lz = worldToLocal(self.components[1].node, px, py, pz)

			if lz < 0 then
				alpha = math.rad(90)
			end

			local dx, dy, dz = localDirectionToWorld(jointDesc.topArm.rotationNode, 0, 0, 1)
			dx, dy, dz = worldDirectionToLocal(getParent(jointDesc.topArm.rotationNode), dx, dy, dz)
			local upX = dx
			local upY = math.cos(alpha) * dy - math.sin(alpha) * dz
			local upZ = math.sin(alpha) * dy + math.cos(alpha) * dz

			if not implement.attachingIsInProgress then
				setDirection(jointDesc.topArm.rotationNode, x * jointDesc.topArm.zScale, y * jointDesc.topArm.zScale, z * jointDesc.topArm.zScale, upX, upY, upZ)

				if jointDesc.topArm.translationNode ~= nil then
					local translation = distance - jointDesc.topArm.referenceDistance

					setTranslation(jointDesc.topArm.translationNode, 0, 0, translation * jointDesc.topArm.zScale)

					if jointDesc.topArm.scaleNode ~= nil then
						setScale(jointDesc.topArm.scaleNode, 1, 1, math.max((translation + jointDesc.topArm.scaleReferenceDistance) / jointDesc.topArm.scaleReferenceDistance, 0))
					end
				end
			end
		end

		if jointDesc.bottomArm ~= nil then
			local ax, ay, az = getWorldTranslation(jointDesc.bottomArm.rotationNode)
			local bx, by, bz = getWorldTranslation(attacherJoint.node)
			local x, y, z = worldDirectionToLocal(getParent(jointDesc.bottomArm.rotationNode), bx - ax, by - ay, bz - az)
			local distance = MathUtil.vector3Length(x, y, z)
			local upX = 0
			local upY = 1
			local upZ = 0

			if math.abs(y) > 0.99 * distance then
				upY = 0
				upZ = y > 0 and 1 or -1
			end

			local dirX = 0
			local dirY = y * jointDesc.bottomArm.zScale
			local dirZ = z * jointDesc.bottomArm.zScale

			if not jointDesc.bottomArm.lockDirection then
				dirX = x * jointDesc.bottomArm.zScale
			end

			local changed = false

			if math.abs(jointDesc.bottomArm.lastDirection[1] - dirX) > 0.001 or math.abs(jointDesc.bottomArm.lastDirection[2] - dirY) > 0.001 or math.abs(jointDesc.bottomArm.lastDirection[3] - dirZ) > 0.001 then
				if implement.attachingIsInProgress then
					setDirection(jointDesc.bottomArm.rotationNodeDir, dirX, dirY, dirZ, upX, upY, upZ)
				else
					setDirection(jointDesc.bottomArm.rotationNode, dirX, dirY, dirZ, upX, upY, upZ)
				end

				jointDesc.bottomArm.lastDirection[1] = dirX
				jointDesc.bottomArm.lastDirection[2] = dirY
				jointDesc.bottomArm.lastDirection[3] = dirZ
				changed = true
			end

			if implement.attachingIsInProgress then
				if changed then
					if not implement.bottomArmInterpolating then
						local interpolator = ValueInterpolator.new(jointDesc.bottomArm.interpolatorKey, jointDesc.bottomArm.interpolatorGet, jointDesc.bottomArm.interpolatorSet, {
							getRotation(jointDesc.bottomArm.rotationNodeDir)
						}, AttacherJoints.SMOOTH_ATTACH_TIME)

						if interpolator ~= nil then
							interpolator:setDeleteListenerObject(self)
							interpolator:setFinishedFunc(jointDesc.bottomArm.interpolatorFinished, jointDesc.bottomArm)

							jointDesc.bottomArm.bottomArmInterpolating = true
							implement.bottomArmInterpolating = true
							implement.bottomArmInterpolator = interpolator
						end
					else
						local rx, ry, rz = getRotation(jointDesc.bottomArm.rotationNodeDir)
						local target = implement.bottomArmInterpolator:getTarget()
						target[3] = rz
						target[2] = ry
						target[1] = rx

						implement.bottomArmInterpolator:updateSpeed()
					end
				end
			else
				ValueInterpolator.removeInterpolator(jointDesc.bottomArm.interpolatorKey)

				jointDesc.bottomArm.bottomArmInterpolating = false
				implement.bottomArmInterpolating = false
				implement.bottomArmInterpolator = nil
			end

			if jointDesc.bottomArm.translationNode ~= nil and not implement.attachingIsInProgress then
				setTranslation(jointDesc.bottomArm.translationNode, 0, 0, (distance - jointDesc.bottomArm.referenceDistance) * jointDesc.bottomArm.zScale)
			end

			if self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(jointDesc.bottomArm.rotationNode, forceUpdate, dt)
			end

			if attacherJoint.needsToolbar and jointDesc.bottomArm.toolbar ~= nil then
				local parent = getParent(jointDesc.bottomArm.toolbar)
				local _, yDir, zDir = localDirectionToLocal(attacherJoint.node, jointDesc.rootNode, 1, 0, 0)
				local xDir, yDir, zDir = localDirectionToLocal(jointDesc.rootNode, parent, 0, yDir, zDir)
				local _, yUp, zUp = localDirectionToLocal(attacherJoint.node, jointDesc.rootNode, 0, 1, 0)
				local xUp, yUp, zUp = localDirectionToLocal(jointDesc.rootNode, parent, 0, yUp, zUp)

				setDirection(jointDesc.bottomArm.toolbar, xDir, yDir, zDir, xUp, yUp, zUp)
			end
		end
	end
end

function AttacherJoints:calculateAttacherJointMoveUpperLowerAlpha(jointDesc, object, initial)
	local objectAttacherJoint = object.spec_attachable.attacherJoint

	if jointDesc.allowsLowering then
		local lowerDistanceToGround = jointDesc.lowerDistanceToGround
		local upperDistanceToGround = jointDesc.upperDistanceToGround
		local upperAlpha, lowerAlpha = nil

		if #objectAttacherJoint.heightNodes > 0 and jointDesc.rotationNode ~= nil then
			local checkData = self.spec_attacherJoints.groundHeightNodeCheckData

			if initial then
				checkData.heightNodes = objectAttacherJoint.heightNodes
				checkData.jointDesc = jointDesc
				checkData.objectAttacherJoint = objectAttacherJoint
				checkData.object = object
				checkData.index = -1
				lowerDistanceToGround = jointDesc.lowerDistanceToGround
				upperDistanceToGround = jointDesc.upperDistanceToGround

				for i = 1, #objectAttacherJoint.heightNodes do
					local heightNode = objectAttacherJoint.heightNodes[i]
					local offX, offY, offZ = localToLocal(heightNode.node, heightNode.attacherJointNode, 0, 0, 0)

					self:updateAttacherJointRotationNodes(jointDesc, 1)
					setRotation(jointDesc.jointTransform, unpack(jointDesc.jointOrigRot))

					local _, y, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, 0, 0, 0)
					local delta = jointDesc.lowerDistanceToGround - y
					local _, hy, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, offX, offY, offZ)
					lowerDistanceToGround = hy + delta

					self:updateAttacherJointRotationNodes(jointDesc, 0)

					_, y, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, 0, 0, 0)
					delta = jointDesc.upperDistanceToGround - y
					_, hy, _ = localToLocal(jointDesc.jointTransform, jointDesc.rootNode, offX, offY, offZ)
					upperDistanceToGround = hy + delta
				end
			elseif (jointDesc.moveAlpha or 0) > 0 then
				if checkData.index == -1 then
					checkData.index = 1
					checkData.minDistance = math.huge
					checkData.hit = false

					self:doGroundHeightNodeCheck()
				end

				if checkData.isDirty then
					checkData.isDirty = false

					self:doGroundHeightNodeCheck()
				end

				if jointDesc.upperAlpha ~= nil and checkData.upperAlpha ~= nil then
					upperAlpha = jointDesc.upperAlpha * 0.9 + checkData.upperAlpha * 0.1
					lowerAlpha = jointDesc.lowerAlpha * 0.9 + checkData.lowerAlpha * 0.1
				else
					upperAlpha = checkData.upperAlpha
					lowerAlpha = checkData.lowerAlpha
				end
			else
				upperAlpha = jointDesc.upperAlpha
				lowerAlpha = jointDesc.lowerAlpha
			end
		end

		upperAlpha = upperAlpha or MathUtil.clamp((objectAttacherJoint.upperDistanceToGround - upperDistanceToGround) / (lowerDistanceToGround - upperDistanceToGround), 0, 1)
		lowerAlpha = lowerAlpha or MathUtil.clamp((objectAttacherJoint.lowerDistanceToGround - upperDistanceToGround) / (lowerDistanceToGround - upperDistanceToGround), 0, 1)

		if initial then
			local checkData = self.spec_attacherJoints.groundHeightNodeCheckData
			checkData.upperAlpha = upperAlpha
			checkData.lowerAlpha = lowerAlpha
		end

		if objectAttacherJoint.allowsLowering and jointDesc.allowsLowering then
			return upperAlpha, lowerAlpha
		elseif objectAttacherJoint.isDefaultLowered then
			return lowerAlpha, lowerAlpha
		else
			return upperAlpha, upperAlpha
		end
	end

	if objectAttacherJoint.isDefaultLowered then
		return 1, 1
	else
		return 0, 0
	end
end

function AttacherJoints:doGroundHeightNodeCheck()
	local checkData = self.spec_attacherJoints.groundHeightNodeCheckData
	local heightNode = checkData.heightNodes[checkData.index]

	if heightNode ~= nil and checkData.object:getIsAttacherJointHeightNodeActive(heightNode) then
		local offX, offY, offZ = localToLocal(heightNode.node, heightNode.attacherJointNode, 0, 0, 0)

		self:updateAttacherJointRotationNodes(checkData.jointDesc, 1)

		local lWx, lWy, lWz = localToWorld(checkData.jointDesc.jointTransformOrig, offX, offY, offZ)

		self:updateAttacherJointRotationNodes(checkData.jointDesc, 0)

		local uWx, uWy, uWz = localToWorld(checkData.jointDesc.jointTransformOrig, offX, offY, offZ)
		local dirX = lWx - uWx
		local dirY = lWy - uWy
		local dirZ = lWz - uWz
		local distance = MathUtil.vector3Length(dirX, dirY, dirZ)
		dirX, dirY, dirZ = MathUtil.vector3Normalize(dirX, dirY, dirZ)
		checkData.currentRaycastDistance = distance
		checkData.currentRaycastWorldPos[1] = uWx
		checkData.currentRaycastWorldPos[2] = uWy
		checkData.currentRaycastWorldPos[3] = uWz
		checkData.currentRaycastWorldDir[1] = dirX
		checkData.currentRaycastWorldDir[2] = dirY
		checkData.currentRaycastWorldDir[3] = dirZ
		checkData.currentJointTransformPos[1], checkData.currentJointTransformPos[2], checkData.currentJointTransformPos[3] = getWorldTranslation(checkData.jointDesc.jointTransform)
		distance = distance + checkData.objectAttacherJoint.lowerDistanceToGround
		checkData.minDistance = math.min(checkData.minDistance, distance)

		raycastAll(uWx, uWy, uWz, dirX, dirY, dirZ, "groundHeightNodeCheckCallback", distance, self, CollisionMask.TERRAIN, false, true)
		self:updateAttacherJointRotationNodes(checkData.jointDesc, checkData.jointDesc.moveAlpha or 0)
	else
		checkData.index = checkData.index + 1

		if checkData.index > #checkData.heightNodes then
			self:finishGroundHeightNodeCheck()
		else
			checkData.isDirty = true
		end
	end
end

function AttacherJoints:finishGroundHeightNodeCheck()
	local checkData = self.spec_attacherJoints.groundHeightNodeCheckData

	if checkData.minDistance ~= math.huge then
		if not checkData.hit then
			checkData.raycastDistance = checkData.currentRaycastDistance
			checkData.raycastWorldPos[1] = checkData.currentRaycastWorldPos[1]
			checkData.raycastWorldPos[2] = checkData.currentRaycastWorldPos[2]
			checkData.raycastWorldPos[3] = checkData.currentRaycastWorldPos[3]
			checkData.raycastWorldDir[1] = checkData.currentRaycastWorldDir[1]
			checkData.raycastWorldDir[2] = checkData.currentRaycastWorldDir[2]
			checkData.raycastWorldDir[3] = checkData.currentRaycastWorldDir[3]
			checkData.jointTransformPos[1] = checkData.currentJointTransformPos[1]
			checkData.jointTransformPos[2] = checkData.currentJointTransformPos[2]
			checkData.jointTransformPos[3] = checkData.currentJointTransformPos[3]
		end

		local upperAlpha = (checkData.minDistance - checkData.objectAttacherJoint.upperDistanceToGround) / checkData.raycastDistance
		local lowerAlpha = (checkData.minDistance - checkData.objectAttacherJoint.lowerDistanceToGround) / checkData.raycastDistance
		local uWx = checkData.raycastWorldPos[1]
		local uWy = checkData.raycastWorldPos[2]
		local uWz = checkData.raycastWorldPos[3]
		local dirX = checkData.raycastWorldDir[1]
		local dirY = checkData.raycastWorldDir[2]
		local dirZ = checkData.raycastWorldDir[3]
		local x1 = uWx + dirX * checkData.raycastDistance * lowerAlpha
		local y1 = uWy + dirY * checkData.raycastDistance * lowerAlpha
		local z1 = uWz + dirZ * checkData.raycastDistance * lowerAlpha
		local x3 = checkData.jointTransformPos[1]
		local y3 = checkData.jointTransformPos[2]
		local z3 = checkData.jointTransformPos[3]
		local straightToCenter = MathUtil.vector3Length(x1 - x3, y1 - y3, z1 - z3)
		local circleToCenter = MathUtil.vector3Length(uWx - x3, uWy - y3, uWz - z3)
		local straightOffset = circleToCenter - straightToCenter
		local _, h1, h2 = nil
		_, h1, _ = worldToLocal(self.rootNode, x1, y1, z1)
		_, h2, _ = worldToLocal(self.rootNode, uWx, uWy, uWz)
		local angle = math.atan(straightOffset / (h2 - h1))
		local offset = straightOffset * math.sin(angle)
		lowerAlpha = (checkData.minDistance - checkData.objectAttacherJoint.lowerDistanceToGround - offset) / checkData.raycastDistance
		checkData.lowerAlpha = MathUtil.clamp(lowerAlpha, 0, 1)
		checkData.upperAlpha = MathUtil.clamp(upperAlpha, 0, 1)
	end

	checkData.index = -1
end

function AttacherJoints:groundHeightNodeCheckCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if self.isDeleted then
		return
	end

	local checkData = self.spec_attacherJoints.groundHeightNodeCheckData

	if hitObjectId ~= 0 then
		if getRigidBodyType(hitObjectId) == RigidBodyType.STATIC then
			if distance < checkData.minDistance then
				checkData.raycastDistance = checkData.currentRaycastDistance
				checkData.minDistance = distance
				checkData.hit = true
				checkData.raycastWorldPos[1] = checkData.currentRaycastWorldPos[1]
				checkData.raycastWorldPos[2] = checkData.currentRaycastWorldPos[2]
				checkData.raycastWorldPos[3] = checkData.currentRaycastWorldPos[3]
				checkData.raycastWorldDir[1] = checkData.currentRaycastWorldDir[1]
				checkData.raycastWorldDir[2] = checkData.currentRaycastWorldDir[2]
				checkData.raycastWorldDir[3] = checkData.currentRaycastWorldDir[3]
				checkData.jointTransformPos[1] = checkData.currentJointTransformPos[1]
				checkData.jointTransformPos[2] = checkData.currentJointTransformPos[2]
				checkData.jointTransformPos[3] = checkData.currentJointTransformPos[3]
			end
		elseif not isLast then
			return true
		end
	end

	checkData.index = checkData.index + 1

	if checkData.index > #checkData.heightNodes then
		self:finishGroundHeightNodeCheck()
	else
		checkData.isDirty = true
	end

	return false
end

function AttacherJoints:updateAttacherJointRotation(jointDesc, object)
	local objectAttacherJoint = object.spec_attachable.attacherJoint
	local targetRot = MathUtil.lerp(objectAttacherJoint.upperRotationOffset, objectAttacherJoint.lowerRotationOffset, jointDesc.moveAlpha)
	local curRot = MathUtil.lerp(jointDesc.upperRotationOffset, jointDesc.lowerRotationOffset, jointDesc.moveAlpha)
	local rotDiff = targetRot - curRot

	setRotation(jointDesc.jointTransform, unpack(jointDesc.jointOrigRot))
	rotateAboutLocalAxis(jointDesc.jointTransform, rotDiff, 0, 0, 1)
end

function AttacherJoints:updateAttacherJointRotationNodes(jointDesc, alpha)
	if jointDesc.rotationNode ~= nil then
		setRotation(jointDesc.rotationNode, MathUtil.vector3ArrayLerp(jointDesc.upperRotation, jointDesc.lowerRotation, alpha))
	end

	if jointDesc.rotationNode2 ~= nil then
		setRotation(jointDesc.rotationNode2, MathUtil.vector3ArrayLerp(jointDesc.upperRotation2, jointDesc.lowerRotation2, alpha))
	end
end

function AttacherJoints:updateAttacherJointSettingsByObject(vehicle, updateLimit, updateRotationOffset, updateDistanceToGround)
	local jointDesc = self:getAttacherJointDescFromObject(vehicle)
	local implement = self:getImplementByObject(vehicle)
	local objectAttacherJoint = vehicle:getActiveInputAttacherJoint()

	if jointDesc ~= nil and implement ~= nil then
		if updateLimit then
			for i = 1, 3 do
				AttacherJoints.updateAttacherJointLimits(implement, jointDesc, objectAttacherJoint, i)
				AttacherJoints.updateAttacherJointRotationLimit(implement, jointDesc, i, false, jointDesc.moveLimitAlpha)
				AttacherJoints.updateAttacherJointTranslationLimit(implement, jointDesc, i, false, jointDesc.moveLimitAlpha)
			end
		end

		if updateRotationOffset then
			self:updateAttacherJointRotation(jointDesc, vehicle)

			if self.isServer then
				setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform)
			end
		end

		if updateDistanceToGround then
			local upperAlpha, lowerAlpha = self:calculateAttacherJointMoveUpperLowerAlpha(jointDesc, vehicle)
			jointDesc.moveTime = jointDesc.moveDefaultTime * math.abs(upperAlpha - lowerAlpha)
			jointDesc.upperAlpha = upperAlpha
			jointDesc.lowerAlpha = lowerAlpha
		end
	end
end

function AttacherJoints:attachImplementFromInfo(info)
	if info.attachable ~= nil then
		local attacherJoints = info.attacherVehicle.spec_attacherJoints.attacherJoints

		if attacherJoints[info.attacherVehicleJointDescIndex].jointIndex == 0 and info.attachable.isAddedToMission then
			if info.attachable:getActiveInputAttacherJointDescIndex() ~= nil and info.attachable:getAllowMultipleAttachments() then
				info.attachable:resolveMultipleAttachments()
			end

			if GS_IS_MOBILE_VERSION then
				local attacherJointDirection = attacherJoints[info.attacherVehicleJointDescIndex].additionalAttachment.attacherJointDirection

				if attacherJointDirection ~= nil then
					local attachedImplements = info.attacherVehicle:getAttachedImplements()

					for i = 1, #attachedImplements do
						local jointDesc = attacherJoints[attachedImplements[i].jointDescIndex]

						if attacherJointDirection == jointDesc.additionalAttachment.attacherJointDirection then
							return false
						end
					end
				end
			end

			info.attacherVehicle:attachImplement(info.attachable, info.attachableJointDescIndex, info.attacherVehicleJointDescIndex)

			return true
		end
	end

	return false
end

function AttacherJoints:attachImplement(object, inputJointDescIndex, jointDescIndex, noEventSend, index, startLowered, noSmoothAttach, loadFromSavegame)
	local spec = self.spec_attacherJoints
	local objectAttacherJoint = object.spec_attachable.inputAttacherJoints[inputJointDescIndex]
	local jointDesc = spec.attacherJoints[jointDescIndex]
	local attacherJointIndex = self:getAttacherJointIndexFromObject(object)

	if attacherJointIndex ~= nil then
		Logging.info("Cannot attach object. Joint already in use!")

		return
	end

	SpecializationUtil.raiseEvent(self, "onPreAttachImplement", object, inputJointDescIndex, jointDescIndex)
	object:preAttach(self, inputJointDescIndex, jointDescIndex, loadFromSavegame)

	if not jointDesc.delayedObjectChangesOnAttach then
		ObjectChangeUtil.setObjectChanges(jointDesc.changeObjects, true, self, self.setMovingToolDirty)
	end

	for i = 1, #jointDesc.visualNodes do
		local node = jointDesc.visualNodes[i]

		setVisibility(node, true)
	end

	for i = 1, #jointDesc.hideVisuals do
		local node = jointDesc.hideVisuals[i]
		local allowedToHide = true
		local attacherJoints = spec.visualNodeToAttacherJoints[node]

		if attacherJoints ~= nil then
			for j = 1, #attacherJoints do
				if attacherJoints[j].jointIndex ~= 0 then
					allowedToHide = false
				end
			end
		end

		if allowedToHide then
			setVisibility(node, false)
		end
	end

	local upperAlpha, lowerAlpha = self:calculateAttacherJointMoveUpperLowerAlpha(jointDesc, object, true)
	jointDesc.moveTime = jointDesc.moveDefaultTime * math.abs(upperAlpha - lowerAlpha)

	if startLowered == nil then
		startLowered = true

		if objectAttacherJoint.allowsLowering and jointDesc.allowsLowering then
			self:updateAttacherJointRotationNodes(jointDesc, upperAlpha)

			local distanceSqUpper = calcDistanceSquaredFrom(jointDesc.jointTransform, objectAttacherJoint.node)

			self:updateAttacherJointRotationNodes(jointDesc, lowerAlpha)

			local distanceSqLower = calcDistanceSquaredFrom(jointDesc.jointTransform, objectAttacherJoint.node)

			if distanceSqUpper < distanceSqLower * 1.1 then
				startLowered = false
			end

			if objectAttacherJoint.useFoldingLoweredState then
				startLowered = object:getIsLowered()
			end
		elseif not objectAttacherJoint.isDefaultLowered then
			startLowered = false
		end
	end

	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(VehicleAttachEvent.new(self, object, inputJointDescIndex, jointDescIndex, startLowered), nil, , self)
		else
			g_client:getServerConnection():sendEvent(VehicleAttachEvent.new(self, object, inputJointDescIndex, jointDescIndex, startLowered))
		end
	end

	if jointDesc.transNode ~= nil and objectAttacherJoint.attacherHeight ~= nil then
		local minYHeight = jointDesc.transNodeMinY
		local maxYHeight = jointDesc.transNodeMaxY
		local lowerDistanceToGround = jointDesc.lowerDistanceToGround
		local upperDistanceToGround = jointDesc.upperDistanceToGround
		local attacherHeight = objectAttacherJoint.attacherHeight

		if self.getOutputPowerTakeOffsByJointDescIndex ~= nil then
			local ptoOutputs = self:getOutputPowerTakeOffsByJointDescIndex(jointDescIndex)

			if ptoOutputs ~= nil and #ptoOutputs > 0 then
				local ptoOutput = ptoOutputs[1]
				local ptoInput = ptoOutput.connectedInput

				if ptoInput ~= nil then
					local _, y, _ = localToLocal(ptoOutput.outputNode, getParent(jointDesc.transNode), 0, 0, 0)
					local ptoYFactor = (y - minYHeight) / (maxYHeight - minYHeight)
					local ptoRealHeight = MathUtil.lerp(lowerDistanceToGround, upperDistanceToGround, ptoYFactor)
					local ptoSize = (ptoInput.size + jointDesc.transNodeHeight) * 0.5

					if ptoInput.aboveAttacher then
						attacherHeight = MathUtil.clamp(attacherHeight, lowerDistanceToGround, ptoRealHeight - ptoSize)
					else
						attacherHeight = MathUtil.clamp(attacherHeight, ptoRealHeight + ptoSize, upperDistanceToGround)
					end
				end
			end
		end

		attacherHeight = MathUtil.clamp(attacherHeight - jointDesc.transNodeOffsetY, lowerDistanceToGround, upperDistanceToGround)
		local factor = MathUtil.clamp((attacherHeight - lowerDistanceToGround) / (upperDistanceToGround - lowerDistanceToGround), 0, 1)
		local y = MathUtil.lerp(minYHeight, maxYHeight, factor)
		local x, _, z = getTranslation(jointDesc.transNode)
		_, y, _ = localToLocal(self.rootNode, getParent(jointDesc.transNode), 0, y, 0)

		setTranslation(jointDesc.transNode, x, y, z)

		if jointDesc.transNodeDependentBottomArm ~= nil and y <= jointDesc.transNodeDependentBottomArmThreshold then
			local bottomArmJointDesc = jointDesc.transNodeDependentBottomArmAttacherJoint
			local rx = jointDesc.transNodeDependentBottomArmRotation[1]
			local ry = jointDesc.transNodeDependentBottomArmRotation[2]
			local rz = jointDesc.transNodeDependentBottomArmRotation[3]

			if loadFromSavegame then
				setRotation(bottomArmJointDesc.bottomArm.rotationNode, rx, ry, rz)

				if self.setMovingToolDirty ~= nil then
					self:setMovingToolDirty(bottomArmJointDesc.bottomArm.rotationNode)
				end
			else
				local interpolator = ValueInterpolator.new(bottomArmJointDesc.bottomArm.interpolatorKey, bottomArmJointDesc.bottomArm.interpolatorGet, bottomArmJointDesc.bottomArm.interpolatorSet, {
					rx,
					ry,
					rz
				}, AttacherJoints.SMOOTH_ATTACH_TIME * 2)

				if interpolator ~= nil then
					interpolator:setDeleteListenerObject(self)
					interpolator:setFinishedFunc(bottomArmJointDesc.bottomArm.interpolatorFinished, bottomArmJointDesc.bottomArm)

					bottomArmJointDesc.bottomArm.bottomArmInterpolating = true
				end
			end
		end
	elseif jointDesc.transNode == nil then
		local isTrailerAttacher = jointDesc.jointType == AttacherJoints.JOINTTYPE_TRAILER or jointDesc.jointType == AttacherJoints.JOINTTYPE_TRAILERLOW

		if self.checkPowerTakeOffCollision ~= nil then
			self:checkPowerTakeOffCollision(jointDesc.jointTransform, jointDescIndex, isTrailerAttacher)
		end
	end

	local implement = {
		object = object,
		jointDescIndex = jointDescIndex,
		inputJointDescIndex = inputJointDescIndex,
		loadFromSavegame = loadFromSavegame
	}
	jointDesc.upperAlpha = upperAlpha
	jointDesc.lowerAlpha = lowerAlpha
	jointDesc.moveAlpha = upperAlpha
	jointDesc.moveLimitAlpha = 0

	if startLowered then
		jointDesc.moveAlpha = lowerAlpha
		jointDesc.moveLimitAlpha = 1
	end

	self:updateAttacherJointRotationNodes(jointDesc, jointDesc.moveAlpha)
	self:updateAttacherJointRotation(jointDesc, object)
	self:createAttachmentJoint(implement, noSmoothAttach)

	local moveDown = objectAttacherJoint.isDefaultLowered or jointDesc.isDefaultLowered

	if objectAttacherJoint.useFoldingLoweredState then
		moveDown = startLowered
	end

	jointDesc.moveDown = moveDown
	jointDesc.isMoving = true

	object:setLowered(jointDesc.moveDown)

	if index == nil then
		table.insert(spec.attachedImplements, implement)
	else
		spec.attachedImplements[index] = implement
	end

	self:updateAttacherJointGraphics(implement, 0)

	if not loadFromSavegame then
		self:playAttachSound(jointDesc)
	end

	self:attachAdditionalAttachment(jointDesc, objectAttacherJoint, object)
	self.rootVehicle:updateSelectableObjects()
	self:updateVehicleChain()

	local inputAttacherJoint = implement.object:getActiveInputAttacherJoint()
	local selectedVehicle = nil

	if inputAttacherJoint.forceSelection then
		selectedVehicle = implement.object
	end

	self.rootVehicle:setSelectedVehicle(selectedVehicle)

	if not implement.attachingIsInProgress then
		if implement.object.spec_attachable.attacherJoint.hardAttach and self:getIsHardAttachAllowed(implement.jointDescIndex) then
			self:hardAttachImplement(implement)
		end

		self:postAttachImplement(implement)
	end

	return true
end

function AttacherJoints:postAttachImplement(implement)
	local spec = self.spec_attacherJoints
	local object = implement.object
	local inputJointDescIndex = implement.inputJointDescIndex
	local jointDescIndex = implement.jointDescIndex
	local objectAttacherJoint = object.spec_attachable.inputAttacherJoints[inputJointDescIndex]
	local jointDesc = spec.attacherJoints[jointDescIndex]

	if objectAttacherJoint.topReferenceNode ~= nil and jointDesc.topArm ~= nil and jointDesc.topArm.toggleVisibility then
		setVisibility(jointDesc.topArm.rotationNode, true)
	end

	if jointDesc.bottomArm ~= nil then
		if jointDesc.bottomArm.toggleVisibility then
			setVisibility(jointDesc.bottomArm.rotationNode, true)
		end

		if objectAttacherJoint.needsToolbar and jointDesc.bottomArm.toolbar ~= nil then
			setVisibility(jointDesc.bottomArm.toolbar, true)
		end
	end

	if jointDesc.delayedObjectChangesOnAttach then
		ObjectChangeUtil.setObjectChanges(jointDesc.changeObjects, true, self, self.setMovingToolDirty)
	end

	self:updateAttacherJointGraphics(implement, 0)
	SpecializationUtil.raiseEvent(self, "onPostAttachImplement", object, inputJointDescIndex, jointDescIndex)
	object:postAttach(self, inputJointDescIndex, jointDescIndex, implement.loadFromSavegame)

	local data = {
		attacherVehicle = self,
		attachedVehicle = implement.object
	}
	local rootVehicle = self.rootVehicle

	rootVehicle:raiseStateChange(Vehicle.STATE_CHANGE_ATTACH, data)
end

function AttacherJoints:createAttachmentJoint(implement, noSmoothAttach)
	local spec = self.spec_attacherJoints
	local jointDesc = spec.attacherJoints[implement.jointDescIndex]
	local objectAttacherJoint = implement.object.spec_attachable.attacherJoint

	if self.isServer and objectAttacherJoint ~= nil then
		if getRigidBodyType(jointDesc.rootNode) ~= RigidBodyType.DYNAMIC or getRigidBodyType(objectAttacherJoint.rootNode) ~= RigidBodyType.DYNAMIC then
			return
		end

		local xNew = jointDesc.jointOrigTrans[1] + jointDesc.jointPositionOffset[1]
		local yNew = jointDesc.jointOrigTrans[2] + jointDesc.jointPositionOffset[2]
		local zNew = jointDesc.jointOrigTrans[3] + jointDesc.jointPositionOffset[3]
		local x, y, z = localToWorld(getParent(jointDesc.jointTransform), xNew, yNew, zNew)
		local x1, y1, z1 = worldToLocal(jointDesc.jointTransform, x, y, z)

		setTranslation(jointDesc.jointTransform, xNew, yNew, zNew)

		x, y, z = localToWorld(objectAttacherJoint.node, x1, y1, z1)
		local x2, y2, z2 = worldToLocal(getParent(objectAttacherJoint.node), x, y, z)

		setTranslation(objectAttacherJoint.node, x2, y2, z2)

		local constr = JointConstructor.new()

		constr:setActors(jointDesc.rootNode, objectAttacherJoint.rootNode)
		constr:setJointTransforms(jointDesc.jointTransform, objectAttacherJoint.node)

		implement.jointRotLimit = {}
		implement.jointTransLimit = {}
		implement.lowerRotLimit = {}
		implement.lowerTransLimit = {}
		implement.upperRotLimit = {}
		implement.upperTransLimit = {}

		if noSmoothAttach == nil or not noSmoothAttach then
			local dx, dy, dz = localToLocal(objectAttacherJoint.node, jointDesc.jointTransform, 0, 0, 0)
			local _, y, z = localDirectionToLocal(objectAttacherJoint.node, jointDesc.jointTransform, 0, 1, 0)
			local rX = math.atan2(z, y)
			local x, _, z = localDirectionToLocal(objectAttacherJoint.node, jointDesc.jointTransform, 0, 0, 1)
			local rY = math.atan2(x, z)
			local x, y, _ = localDirectionToLocal(objectAttacherJoint.node, jointDesc.jointTransform, 1, 0, 0)
			local rZ = math.atan2(y, x)
			implement.attachingTransLimit = {
				math.abs(dx),
				math.abs(dy),
				math.abs(dz)
			}
			implement.attachingRotLimit = {
				math.abs(rX),
				math.abs(rY),
				math.abs(rZ)
			}
			implement.attachingTransLimitSpeed = {}
			implement.attachingRotLimitSpeed = {}

			for i = 1, 3 do
				implement.attachingTransLimitSpeed[i] = implement.attachingTransLimit[i] / AttacherJoints.SMOOTH_ATTACH_TIME
				implement.attachingRotLimitSpeed[i] = implement.attachingRotLimit[i] / AttacherJoints.SMOOTH_ATTACH_TIME
			end

			implement.attachingIsInProgress = true
		else
			implement.attachingTransLimit = {
				0,
				0,
				0
			}
			implement.attachingRotLimit = {
				0,
				0,
				0
			}
		end

		implement.rotLimitThreshold = objectAttacherJoint.rotLimitThreshold or 0
		implement.transLimitThreshold = objectAttacherJoint.transLimitThreshold or 0

		for i = 1, 3 do
			local rotLimit, transLimit = AttacherJoints.updateAttacherJointLimits(implement, jointDesc, objectAttacherJoint, i)
			local limitRot = rotLimit
			local limitTrans = transLimit

			if noSmoothAttach == nil or not noSmoothAttach then
				limitRot = math.max(rotLimit, implement.attachingRotLimit[i])
				limitTrans = math.max(transLimit, implement.attachingTransLimit[i])
			end

			local rotLimitDown = -limitRot
			local rotLimitUp = limitRot

			if i == 3 then
				if jointDesc.lockDownRotLimit then
					rotLimitDown = math.min(-implement.attachingRotLimit[i], 0)
				end

				if jointDesc.lockUpRotLimit then
					rotLimitUp = math.max(implement.attachingRotLimit[i], 0)
				end
			end

			constr:setRotationLimit(i - 1, rotLimitDown, rotLimitUp)

			implement.jointRotLimit[i] = limitRot
			local transLimitDown = -limitTrans
			local transLimitUp = limitTrans

			if i == 2 then
				if jointDesc.lockDownTransLimit then
					transLimitDown = math.min(-implement.attachingTransLimit[i], 0)
				end

				if jointDesc.lockUpTransLimit then
					transLimitUp = math.max(implement.attachingTransLimit[i], 0)
				end
			end

			constr:setTranslationLimit(i - 1, true, transLimitDown, transLimitUp)

			implement.jointTransLimit[i] = limitTrans
		end

		if jointDesc.enableCollision then
			constr:setEnableCollision(true)
		else
			for _, component in pairs(self.components) do
				if component.node ~= jointDesc.rootNodeBackup and not component.collideWithAttachables then
					setPairCollision(component.node, objectAttacherJoint.rootNode, false)
				end
			end
		end

		local springX = math.max(jointDesc.rotLimitSpring[1], objectAttacherJoint.rotLimitSpring[1])
		local springY = math.max(jointDesc.rotLimitSpring[2], objectAttacherJoint.rotLimitSpring[2])
		local springZ = math.max(jointDesc.rotLimitSpring[3], objectAttacherJoint.rotLimitSpring[3])
		local dampingX = math.max(jointDesc.rotLimitDamping[1], objectAttacherJoint.rotLimitDamping[1])
		local dampingY = math.max(jointDesc.rotLimitDamping[2], objectAttacherJoint.rotLimitDamping[2])
		local dampingZ = math.max(jointDesc.rotLimitDamping[3], objectAttacherJoint.rotLimitDamping[3])
		local forceLimitX = Utils.getMaxJointForceLimit(jointDesc.rotLimitForceLimit[1], objectAttacherJoint.rotLimitForceLimit[1])
		local forceLimitY = Utils.getMaxJointForceLimit(jointDesc.rotLimitForceLimit[2], objectAttacherJoint.rotLimitForceLimit[2])
		local forceLimitZ = Utils.getMaxJointForceLimit(jointDesc.rotLimitForceLimit[3], objectAttacherJoint.rotLimitForceLimit[3])

		constr:setRotationLimitSpring(springX, dampingX, springY, dampingY, springZ, dampingZ)
		constr:setRotationLimitForceLimit(forceLimitX, forceLimitY, forceLimitZ)

		local springX = math.max(jointDesc.transLimitSpring[1], objectAttacherJoint.transLimitSpring[1])
		local springY = math.max(jointDesc.transLimitSpring[2], objectAttacherJoint.transLimitSpring[2])
		local springZ = math.max(jointDesc.transLimitSpring[3], objectAttacherJoint.transLimitSpring[3])
		local dampingX = math.max(jointDesc.transLimitDamping[1], objectAttacherJoint.transLimitDamping[1])
		local dampingY = math.max(jointDesc.transLimitDamping[2], objectAttacherJoint.transLimitDamping[2])
		local dampingZ = math.max(jointDesc.transLimitDamping[3], objectAttacherJoint.transLimitDamping[3])
		local forceLimitX = Utils.getMaxJointForceLimit(jointDesc.transLimitForceLimit[1], objectAttacherJoint.transLimitForceLimit[1])
		local forceLimitY = Utils.getMaxJointForceLimit(jointDesc.transLimitForceLimit[2], objectAttacherJoint.transLimitForceLimit[2])
		local forceLimitZ = Utils.getMaxJointForceLimit(jointDesc.transLimitForceLimit[3], objectAttacherJoint.transLimitForceLimit[3])

		constr:setTranslationLimitSpring(springX, dampingX, springY, dampingY, springZ, dampingZ)
		constr:setTranslationLimitForceLimit(forceLimitX, forceLimitY, forceLimitZ)

		jointDesc.jointIndex = constr:finalize()

		setTranslation(objectAttacherJoint.node, unpack(objectAttacherJoint.jointOrigTrans))
	else
		jointDesc.jointIndex = 1
	end
end

function AttacherJoints:hardAttachImplement(implement)
	local spec = self.spec_attacherJoints
	local implements = {}
	local attachedImplements = nil

	if implement.object.getAttachedImplements ~= nil then
		attachedImplements = implement.object:getAttachedImplements()
	end

	if attachedImplements ~= nil then
		for i = #attachedImplements, 1, -1 do
			local impl = attachedImplements[i]
			local object = impl.object
			local jointDescIndex = impl.jointDescIndex
			local jointDesc = implement.object.spec_attacherJoints.attacherJoints[jointDescIndex]
			local inputJointDescIndex = object.spec_attachable.inputAttacherJointDescIndex
			local moveDown = jointDesc.moveDown

			table.insert(implements, 1, {
				object = object,
				implementIndex = i,
				jointDescIndex = jointDescIndex,
				inputJointDescIndex = inputJointDescIndex,
				moveDown = moveDown
			})
			implement.object:detachImplement(1, true)
		end
	end

	local attacherJoint = spec.attacherJoints[implement.jointDescIndex]
	local implementJoint = implement.object.spec_attachable.attacherJoint
	local baseVehicleComponentNode = self:getParentComponent(attacherJoint.jointTransform)
	local attachedVehicleComponentNode = implement.object:getParentComponent(implement.object.spec_attachable.attacherJoint.node)
	local currentVehicle = self

	while currentVehicle ~= nil do
		currentVehicle:removeFromPhysics()

		currentVehicle = currentVehicle.attacherVehicle
	end

	implement.object:removeFromPhysics()

	if spec.attacherVehicle == nil then
		setIsCompound(baseVehicleComponentNode, true)
	end

	setIsCompoundChild(attachedVehicleComponentNode, true)

	local dirX, dirY, dirZ = localDirectionToLocal(attachedVehicleComponentNode, implementJoint.node, 0, 0, 1)
	local upX, upY, upZ = localDirectionToLocal(attachedVehicleComponentNode, implementJoint.node, 0, 1, 0)

	setDirection(attachedVehicleComponentNode, dirX, dirY, dirZ, upX, upY, upZ)

	local x, y, z = localToLocal(attachedVehicleComponentNode, implementJoint.node, 0, 0, 0)

	setTranslation(attachedVehicleComponentNode, x, y, z)
	link(attacherJoint.jointTransform, attachedVehicleComponentNode)

	if implementJoint.visualNode ~= nil and attacherJoint.jointTransformVisual ~= nil then
		local dirX, dirY, dirZ = localDirectionToLocal(implementJoint.visualNode, implementJoint.node, 0, 0, 1)
		local upX, upY, upZ = localDirectionToLocal(implementJoint.visualNode, implementJoint.node, 0, 1, 0)

		setDirection(implementJoint.visualNode, dirX, dirY, dirZ, upX, upY, upZ)

		local x, y, z = localToLocal(implementJoint.visualNode, implementJoint.node, 0, 0, 0)

		setTranslation(implementJoint.visualNode, x, y, z)
		link(attacherJoint.jointTransformVisual, implementJoint.visualNode)
	end

	implement.object.spec_attachable.isHardAttached = true
	local currentVehicle = self

	while currentVehicle ~= nil do
		currentVehicle:addToPhysics()

		currentVehicle = currentVehicle.attacherVehicle
	end

	for _, attacherJoint in pairs(implement.object.spec_attacherJoints.attacherJoints) do
		attacherJoint.rootNode = self.rootNode
	end

	for _, impl in pairs(implements) do
		implement.object:attachImplement(impl.object, impl.inputJointDescIndex, impl.jointDescIndex, true, impl.implementIndex, impl.moveDown, true)
	end

	if self.isServer then
		self:raiseDirtyFlags(self.vehicleDirtyFlag)
	end

	return true
end

function AttacherJoints:hardDetachImplement(implement)
	for _, attacherJoint in pairs(implement.object.spec_attacherJoints.attacherJoints) do
		attacherJoint.rootNode = attacherJoint.rootNodeBackup
	end

	local implementJoint = implement.object.spec_attachable.attacherJoint
	local attachedVehicleComponentNode = implement.object:getParentComponent(implementJoint.node)
	local currentVehicle = self

	while currentVehicle ~= nil do
		currentVehicle:removeFromPhysics()

		currentVehicle = currentVehicle.attacherVehicle
	end

	setIsCompound(attachedVehicleComponentNode, true)

	local x, y, z = getWorldTranslation(attachedVehicleComponentNode)

	setTranslation(attachedVehicleComponentNode, x, y, z)

	local dirX, dirY, dirZ = localDirectionToWorld(implement.object.rootNode, 0, 0, 1)
	local upX, upY, upZ = localDirectionToWorld(implement.object.rootNode, 0, 1, 0)

	setDirection(attachedVehicleComponentNode, dirX, dirY, dirZ, upX, upY, upZ)
	link(getRootNode(), attachedVehicleComponentNode)

	if implementJoint.visualNode ~= nil and getParent(implementJoint.visualNode) ~= implementJoint.visualNodeData.parent then
		link(implementJoint.visualNodeData.parent, implementJoint.visualNode, implementJoint.visualNodeData.index)
		setRotation(implementJoint.visualNode, implementJoint.visualNodeData.rotation[1], implementJoint.visualNodeData.rotation[2], implementJoint.visualNodeData.rotation[3])
		setTranslation(implementJoint.visualNode, implementJoint.visualNodeData.translation[1], implementJoint.visualNodeData.translation[2], implementJoint.visualNodeData.translation[3])
	end

	local currentVehicle = self

	while currentVehicle ~= nil do
		currentVehicle:addToPhysics()

		currentVehicle = currentVehicle.attacherVehicle
	end

	implement.object:addToPhysics()

	implement.object.spec_attachable.isHardAttached = false

	if self.isServer then
		self:raiseDirtyFlags(self.vehicleDirtyFlag)
	end

	return true
end

function AttacherJoints:detachImplement(implementIndex, noEventSend)
	local spec = self.spec_attacherJoints

	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(VehicleDetachEvent.new(self, spec.attachedImplements[implementIndex].object), nil, , self)
		else
			local implement = spec.attachedImplements[implementIndex]

			if implement.object ~= nil then
				g_client:getServerConnection():sendEvent(VehicleDetachEvent.new(self, implement.object))
			end

			return
		end
	end

	local implement = spec.attachedImplements[implementIndex]

	SpecializationUtil.raiseEvent(self, "onPreDetachImplement", implement)
	implement.object:preDetach(self, implement)

	local jointDesc = nil

	if implement.object ~= nil then
		jointDesc = spec.attacherJoints[implement.jointDescIndex]

		if jointDesc.transNode ~= nil then
			setTranslation(jointDesc.transNode, unpack(jointDesc.transNodeOrgTrans))

			if jointDesc.transNodeDependentBottomArm ~= nil then
				local bottomArmJointDesc = jointDesc.transNodeDependentBottomArmAttacherJoint
				local interpolator = ValueInterpolator.new(bottomArmJointDesc.bottomArm.interpolatorKey, bottomArmJointDesc.bottomArm.interpolatorGet, bottomArmJointDesc.bottomArm.interpolatorSet, {
					bottomArmJointDesc.bottomArm.rotX,
					bottomArmJointDesc.bottomArm.rotY,
					bottomArmJointDesc.bottomArm.rotZ
				}, AttacherJoints.SMOOTH_ATTACH_TIME * 2)

				if interpolator ~= nil then
					interpolator:setDeleteListenerObject(self)
					interpolator:setFinishedFunc(bottomArmJointDesc.bottomArm.interpolatorFinished, bottomArmJointDesc.bottomArm)

					bottomArmJointDesc.bottomArm.bottomArmInterpolating = true
				end
			end
		end

		if not implement.object.spec_attachable.isHardAttached and self.isServer then
			if jointDesc.jointIndex ~= 0 then
				removeJoint(jointDesc.jointIndex)
			end

			if not jointDesc.enableCollision then
				for _, component in pairs(self.components) do
					if component.node ~= jointDesc.rootNodeBackup and not component.collideWithAttachables then
						local attacherJoint = implement.object:getActiveInputAttacherJoint()

						setPairCollision(component.node, attacherJoint.rootNode, true)
					end
				end
			end
		end

		jointDesc.jointIndex = 0
	end

	if not jointDesc.delayedObjectChanges or jointDesc.bottomArm == nil then
		ObjectChangeUtil.setObjectChanges(jointDesc.changeObjects, false, self, self.setMovingToolDirty)
	end

	for i = 1, #jointDesc.hideVisuals do
		local node = jointDesc.hideVisuals[i]
		local allowedToShow = true
		local attacherJoints = spec.hideVisualNodeToAttacherJoints[node]

		if attacherJoints ~= nil then
			for j = 1, #attacherJoints do
				if attacherJoints[j].jointIndex ~= 0 then
					allowedToShow = false
				end
			end
		end

		if allowedToShow then
			setVisibility(node, true)
		end
	end

	for i = 1, #jointDesc.visualNodes do
		local node = jointDesc.visualNodes[i]
		local hideNode = false
		local attacherJoints = spec.hideVisualNodeToAttacherJoints[node]

		if attacherJoints ~= nil then
			for j = 1, #attacherJoints do
				if attacherJoints[j].jointIndex ~= 0 then
					hideNode = true
				end
			end
		end

		if hideNode then
			setVisibility(node, false)
		end
	end

	if implement.object ~= nil then
		local object = implement.object

		if object.spec_attachable.isHardAttached then
			self:hardDetachImplement(implement)
		end

		if self.isClient then
			if jointDesc.topArm ~= nil then
				setRotation(jointDesc.topArm.rotationNode, jointDesc.topArm.rotX, jointDesc.topArm.rotY, jointDesc.topArm.rotZ)

				if jointDesc.topArm.translationNode ~= nil then
					setTranslation(jointDesc.topArm.translationNode, 0, 0, 0)
				end

				if jointDesc.topArm.scaleNode ~= nil then
					setScale(jointDesc.topArm.scaleNode, 1, 1, 1)
				end

				if jointDesc.topArm.toggleVisibility then
					setVisibility(jointDesc.topArm.rotationNode, false)
				end
			end

			if jointDesc.bottomArm ~= nil then
				local interpolator = ValueInterpolator.new(jointDesc.bottomArm.interpolatorKey, jointDesc.bottomArm.interpolatorGet, jointDesc.bottomArm.interpolatorSet, {
					jointDesc.bottomArm.rotX,
					jointDesc.bottomArm.rotY,
					jointDesc.bottomArm.rotZ
				}, nil, jointDesc.bottomArm.resetSpeed)

				if interpolator ~= nil then
					interpolator:setDeleteListenerObject(self)
					interpolator:setFinishedFunc(jointDesc.bottomArm.interpolatorFinished, jointDesc.bottomArm)

					jointDesc.bottomArm.bottomArmInterpolating = true

					if jointDesc.delayedObjectChanges then
						interpolator:setFinishedFunc(function ()
							jointDesc.bottomArm.interpolatorFinished(jointDesc.bottomArm)
							ObjectChangeUtil.setObjectChanges(jointDesc.changeObjects, false, self, self.setMovingToolDirty)
						end)
					end
				end

				jointDesc.bottomArm.lastDirection[3] = 0
				jointDesc.bottomArm.lastDirection[2] = 0
				jointDesc.bottomArm.lastDirection[1] = 0

				if jointDesc.bottomArm.translationNode ~= nil then
					setTranslation(jointDesc.bottomArm.translationNode, 0, 0, 0)
				end

				if jointDesc.bottomArm.toolbar ~= nil then
					setVisibility(jointDesc.bottomArm.toolbar, false)
				end

				if jointDesc.bottomArm.toggleVisibility then
					setVisibility(jointDesc.bottomArm.rotationNode, false)
				end
			end
		end

		setTranslation(jointDesc.jointTransform, unpack(jointDesc.jointOrigTrans))

		local attacherJoint = object:getActiveInputAttacherJoint()

		setTranslation(attacherJoint.node, unpack(attacherJoint.jointOrigTrans))

		if jointDesc.rotationNode ~= nil then
			setRotation(jointDesc.rotationNode, jointDesc.rotX, jointDesc.rotY, jointDesc.rotZ)
		end

		SpecializationUtil.raiseEvent(self, "onPostDetachImplement", implementIndex)
		object:postDetach(implementIndex)
		self:detachAdditionalAttachment(jointDesc, attacherJoint)
	end

	table.remove(spec.attachedImplements, implementIndex)
	self:playDetachSound(jointDesc)

	spec.wasInAttachRange = nil

	self:updateVehicleChain()
	implement.object:updateVehicleChain()

	local data = {
		attacherVehicle = self,
		attachedVehicle = implement.object
	}

	implement.object:raiseStateChange(Vehicle.STATE_CHANGE_DETACH, data)

	local rootVehicle = self.rootVehicle

	rootVehicle:raiseStateChange(Vehicle.STATE_CHANGE_DETACH, data)
	self.rootVehicle:updateSelectableObjects()

	if GS_IS_MOBILE_VERSION then
		local nextImplement = next(spec.attachedImplements)

		if spec.attachedImplements[nextImplement] ~= nil then
			self.rootVehicle:setSelectedVehicle(spec.attachedImplements[nextImplement].object, nil, true)
		else
			self.rootVehicle:setSelectedVehicle(self, nil, true)
		end
	else
		self.rootVehicle:setSelectedVehicle(self, nil, true)
	end

	self.rootVehicle:requestActionEventUpdate()
	implement.object:updateSelectableObjects()
	implement.object:setSelectedVehicle(implement.object, nil, true)
	implement.object:requestActionEventUpdate()

	return true
end

function AttacherJoints:detachImplementByObject(object, noEventSend)
	local spec = self.spec_attacherJoints

	for i, implement in ipairs(spec.attachedImplements) do
		if implement.object == object then
			self:detachImplement(i, noEventSend)

			break
		end
	end

	return true
end

function AttacherJoints:setSelectedImplementByObject(object)
	self.spec_attacherJoints.selectedImplement = self:getImplementByObject(object)
end

function AttacherJoints:getSelectedImplement()
	local spec = self.spec_attacherJoints

	if spec.selectedImplement ~= nil and spec.selectedImplement.object:getAttacherVehicle() ~= self then
		return nil
	end

	return spec.selectedImplement
end

function AttacherJoints:getCanToggleAttach()
	return true
end

function AttacherJoints:getShowDetachAttachedImplement()
	if self:getIsAIActive() then
		return false
	end

	local spec = self.spec_attacherJoints
	local info = spec.attachableInfo

	if info.attacherVehicle == nil then
		local selectedVehicle = self:getSelectedVehicle()

		if selectedVehicle ~= nil and not selectedVehicle.isDeleted and selectedVehicle.getAttacherVehicle ~= nil and selectedVehicle:getAttacherVehicle() ~= nil then
			return true
		end
	end

	return false
end

function AttacherJoints:detachAttachedImplement()
	if self:getCanToggleAttach() then
		AttacherJoints.actionEventAttach(self)
	end
end

function AttacherJoints:startAttacherJointCombo(force)
	local spec = self.spec_attacherJoints

	if not spec.attacherJointCombos.isRunning or force then
		spec.attacherJointCombos.direction = -spec.attacherJointCombos.direction
		spec.attacherJointCombos.isRunning = true
	end
end

function AttacherJoints:getIsAttachingAllowed(attacherJoint)
	return attacherJoint.jointIndex == 0
end

function AttacherJoints:getCanSteerAttachable(attachable)
	local jointDesc = self:getAttacherJointDescFromObject(attachable)

	if jointDesc ~= nil and (jointDesc.steeringBarLeftNode ~= nil or jointDesc.steeringBarRightNode ~= nil or jointDesc.steeringBarForceUsage) then
		return true
	end

	return false
end

function AttacherJoints:registerSelfLoweringActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
end

function AttacherJoints:playAttachSound(jointDesc)
	local spec = self.spec_attacherJoints

	if self.isClient then
		if jointDesc ~= nil and jointDesc.sampleAttach ~= nil then
			g_soundManager:playSample(jointDesc.sampleAttach)
		else
			g_soundManager:playSample(spec.samples.attach)
		end
	end

	return true
end

function AttacherJoints:playDetachSound(jointDesc)
	local spec = self.spec_attacherJoints

	if self.isClient then
		if jointDesc ~= nil and jointDesc.sampleDetach ~= nil then
			g_soundManager:playSample(jointDesc.sampleDetach)
		elseif spec.samples.detach ~= nil then
			g_soundManager:playSample(spec.samples.detach)
		elseif jointDesc ~= nil and jointDesc.sampleAttach ~= nil then
			g_soundManager:playSample(jointDesc.sampleAttach)
		else
			g_soundManager:playSample(spec.samples.attach)
		end
	end

	return true
end

function AttacherJoints:detachingIsPossible()
	local implement = self:getImplementByObject(self:getSelectedVehicle())

	if implement ~= nil then
		local object = implement.object

		if object ~= nil and object.attacherVehicle ~= nil and object:isDetachAllowed() then
			local implementIndex = object.attacherVehicle:getImplementIndexByObject(object)

			if implementIndex ~= nil then
				return true
			end
		end
	end

	return false
end

function AttacherJoints:attachAdditionalAttachment(jointDesc, inputJointDesc, object)
	if jointDesc.additionalAttachment.attacherJointDirection ~= nil and inputJointDesc.additionalAttachment.filename ~= nil then
		local storeItem = g_storeManager:getItemByXMLFilename(inputJointDesc.additionalAttachment.filename)

		if storeItem ~= nil then
			local targetDirection = -jointDesc.additionalAttachment.attacherJointDirection
			local attacherJoint, attacherJointIndex = nil

			for index, attacherJointToCheck in ipairs(self:getAttacherJoints()) do
				if attacherJointToCheck.additionalAttachment.attacherJointDirection == targetDirection then
					if attacherJointToCheck.jointIndex ~= 0 then
						attacherJoint = nil

						break
					elseif attacherJointToCheck.jointType == inputJointDesc.additionalAttachment.jointType then
						attacherJoint = attacherJointToCheck
						attacherJointIndex = index
					end
				end
			end

			if attacherJoint ~= nil then
				local x, y, z = localToWorld(attacherJoint.jointTransform, 0, 0, 0)
				local dirX, _, dirZ = localDirectionToWorld(attacherJoint.jointTransform, 1, 0, 0)
				local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)
				local location = {
					x = x,
					y = y,
					z = z,
					yRot = yRot
				}
				jointDesc.additionalAttachment.currentAttacherJointIndex = attacherJointIndex
				local asyncCallbackArguments = {
					attacherJointIndex,
					inputJointDesc.additionalAttachment.inputAttacherJointIndex,
					attacherJoint.jointTransform,
					inputJointDesc.additionalAttachment.needsLowering,
					object
				}
				local vehicle = VehicleLoadingUtil.loadVehicle(storeItem.xmlFilename, location, false, 0, Vehicle.PROPERTY_STATE_NONE, self:getActiveFarm(), {}, nil, AttacherJoints.additionalAttachmentLoaded, self, asyncCallbackArguments)

				if vehicle ~= nil and vehicle.setIsAdditionalAttachment ~= nil then
					vehicle:setIsAdditionalAttachment(inputJointDesc.additionalAttachment.needsLowering, false)
				else
					Logging.warning("Failed to load additional attachment '%s'.", storeItem.xmlFilename)
				end
			end
		end
	end
end

function AttacherJoints:detachAdditionalAttachment(jointDesc, inputJointDesc)
	if jointDesc.additionalAttachment.currentAttacherJointIndex ~= nil and inputJointDesc.additionalAttachment.filename ~= nil then
		local implement = self:getImplementByJointDescIndex(jointDesc.additionalAttachment.currentAttacherJointIndex)

		if implement ~= nil and implement.object:getIsAdditionalAttachment() and not g_currentMission.isExitingGame then
			g_currentMission:removeVehicle(implement.object)
		end
	end
end

function AttacherJoints:additionalAttachmentLoaded(vehicle, vehicleLoadState, asyncCallbackArguments)
	local offset = {
		0,
		0,
		0
	}

	if vehicle.getInputAttacherJoints ~= nil then
		local inputAttacherJoints = vehicle:getInputAttacherJoints()

		if inputAttacherJoints[asyncCallbackArguments[2]] ~= nil then
			offset = inputAttacherJoints[asyncCallbackArguments[2]].jointOrigOffsetComponent
		end
	end

	local x, y, z = localToWorld(asyncCallbackArguments[3], unpack(offset))
	local dirX, _, dirZ = localDirectionToWorld(asyncCallbackArguments[3], 1, 0, 0)
	local yRot = MathUtil.getYRotationFromDirection(dirX, dirZ)
	local terrainY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

	vehicle:setAbsolutePosition(x, math.max(y, terrainY + 0.05), z, 0, yRot, 0)
	self:attachImplement(vehicle, asyncCallbackArguments[2], asyncCallbackArguments[1], true, nil, , true)
	vehicle:setIsAdditionalAttachment(asyncCallbackArguments[4], true)

	if vehicle.addDirtAmount ~= nil and asyncCallbackArguments[5] ~= nil and asyncCallbackArguments[5].getDirtAmount ~= nil then
		vehicle:addDirtAmount(asyncCallbackArguments[5]:getDirtAmount())
	end

	self.rootVehicle:updateSelectableObjects()
	self.rootVehicle:setSelectedVehicle(asyncCallbackArguments[5] or self)
end

function AttacherJoints:getImplementIndexByJointDescIndex(jointDescIndex)
	local spec = self.spec_attacherJoints

	for i, implement in pairs(spec.attachedImplements) do
		if implement.jointDescIndex == jointDescIndex then
			return i
		end
	end

	return nil
end

function AttacherJoints:getImplementByJointDescIndex(jointDescIndex)
	local spec = self.spec_attacherJoints

	for i, implement in pairs(spec.attachedImplements) do
		if implement.jointDescIndex == jointDescIndex then
			return implement
		end
	end

	return nil
end

function AttacherJoints:getImplementIndexByObject(object)
	local spec = self.spec_attacherJoints

	for i, implement in pairs(spec.attachedImplements) do
		if implement.object == object then
			return i
		end
	end

	return nil
end

function AttacherJoints:getImplementByObject(object)
	local spec = self.spec_attacherJoints

	for i, implement in pairs(spec.attachedImplements) do
		if implement.object == object then
			return implement
		end
	end

	return nil
end

function AttacherJoints:callFunctionOnAllImplements(functionName, ...)
	for _, implement in pairs(self:getAttachedImplements()) do
		local vehicle = implement.object

		if vehicle ~= nil and vehicle[functionName] ~= nil then
			vehicle[functionName](vehicle, ...)
		end
	end
end

function AttacherJoints:activateAttachments()
	local spec = self.spec_attacherJoints

	for _, v in pairs(spec.attachedImplements) do
		if v.object ~= nil then
			v.object:activate()
		end
	end
end

function AttacherJoints:deactivateAttachments()
	local spec = self.spec_attacherJoints

	for _, v in pairs(spec.attachedImplements) do
		if v.object ~= nil then
			v.object:deactivate()
		end
	end
end

function AttacherJoints:deactivateAttachmentsLights()
	local spec = self.spec_attacherJoints

	for _, v in pairs(spec.attachedImplements) do
		if v.object ~= nil and v.object.deactivateLights ~= nil then
			v.object:deactivateLights()
		end
	end
end

function AttacherJoints:setJointMoveDown(jointDescIndex, moveDown, noEventSend)
	local spec = self.spec_attacherJoints

	VehicleLowerImplementEvent.sendEvent(self, jointDescIndex, moveDown, noEventSend)

	local jointDesc = spec.attacherJoints[jointDescIndex]

	if jointDesc.allowsLowering then
		jointDesc.moveDown = moveDown
		jointDesc.isMoving = true
		local implementIndex = self:getImplementIndexByJointDescIndex(jointDescIndex)

		if implementIndex ~= nil then
			local implement = spec.attachedImplements[implementIndex]

			if implement.object ~= nil then
				implement.object:setLowered(moveDown)
			end
		end
	end

	return true
end

function AttacherJoints:getJointMoveDown(jointDescIndex)
	local jointDesc = self.spec_attacherJoints.attacherJoints[jointDescIndex]

	if jointDesc.allowsLowering then
		return jointDesc.moveDown
	end

	return false
end

function AttacherJoints:getIsHardAttachAllowed(jointDescIndex)
	local spec = self.spec_attacherJoints

	return spec.attacherJoints[jointDescIndex].supportsHardAttach
end

function AttacherJoints:loadAttacherJointFromXML(attacherJoint, xmlFile, baseName, index)
	local spec = self.spec_attacherJoints

	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#index", baseName .. "#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#indexVisual", baseName .. "#nodeVisual")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#ptoOutputNode", "vehicle.powerTakeOffs.output")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#lowerDistanceToGround", baseName .. ".distanceToGround#lower")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#upperDistanceToGround", baseName .. ".distanceToGround#upper")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#rotationNode", baseName .. ".rotationNode#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#upperRotation", baseName .. ".rotationNode#upperRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#lowerRotation", baseName .. ".rotationNode#lowerRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#startRotation", baseName .. ".rotationNode#startRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#rotationNode2", baseName .. ".rotationNode2#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#upperRotation2", baseName .. ".rotationNode2#upperRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#lowerRotation2", baseName .. ".rotationNode2#lowerRotation")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNode", baseName .. ".transNode#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNodeMinY", baseName .. ".transNode#minY")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNodeMaxY", baseName .. ".transNode#maxY")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, baseName .. "#transNodeHeight", baseName .. ".transNode#height")

	local node = xmlFile:getValue(baseName .. "#node", nil, self.components, self.i3dMappings)

	if node == nil then
		Logging.xmlWarning(self.xmlFile, "Missing node for attacherJoint '%s'", baseName)

		return false
	end

	attacherJoint.jointTransform = node
	attacherJoint.jointComponent = self:getParentComponent(attacherJoint.jointTransform)
	attacherJoint.jointTransformVisual = xmlFile:getValue(baseName .. "#nodeVisual", nil, self.components, self.i3dMappings)
	attacherJoint.supportsHardAttach = xmlFile:getValue(baseName .. "#supportsHardAttach", true)
	attacherJoint.jointOrigOffsetComponent = {
		localToLocal(attacherJoint.jointComponent, attacherJoint.jointTransform, 0, 0, 0)
	}
	attacherJoint.jointOrigDirOffsetComponent = {
		localDirectionToLocal(attacherJoint.jointComponent, attacherJoint.jointTransform, 0, 0, 1)
	}
	attacherJoint.jointTransformOrig = createTransformGroup("jointTransformOrig")

	link(getParent(node), attacherJoint.jointTransformOrig)
	setTranslation(attacherJoint.jointTransformOrig, getTranslation(node))
	setRotation(attacherJoint.jointTransformOrig, getRotation(node))

	local jointTypeStr = xmlFile:getValue(baseName .. "#jointType")
	local jointType = nil

	if jointTypeStr ~= nil then
		jointType = AttacherJoints.jointTypeNameToInt[jointTypeStr]

		if jointType == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid jointType '%s' for attacherJoint '%s'!", tostring(jointTypeStr), baseName)
		end
	end

	if jointType == nil then
		jointType = AttacherJoints.JOINTTYPE_IMPLEMENT
	end

	attacherJoint.jointType = jointType
	local subTypeStr = xmlFile:getValue(baseName .. ".subType#name")
	attacherJoint.subTypes = string.split(subTypeStr, " ")

	if #attacherJoint.subTypes == 0 then
		attacherJoint.subTypes = nil
	end

	local brandRestrictionStr = xmlFile:getValue(baseName .. ".subType#brandRestriction")
	attacherJoint.brandRestrictions = string.split(brandRestrictionStr, " ")

	if #attacherJoint.brandRestrictions == 0 then
		attacherJoint.brandRestrictions = nil
	else
		for i = 1, #attacherJoint.brandRestrictions do
			local brand = g_brandManager:getBrandByName(attacherJoint.brandRestrictions[i])

			if brand ~= nil then
				attacherJoint.brandRestrictions[i] = brand
			else
				Logging.xmlError(xmlFile, "Unknown brand '%s' in '%s'", attacherJoint.brandRestrictions[i], baseName .. ".subType#brandRestriction")

				attacherJoint.brandRestrictions = nil

				break
			end
		end
	end

	local vehicleRestrictionStr = xmlFile:getValue(baseName .. ".subType#vehicleRestriction")
	attacherJoint.vehicleRestrictions = string.split(vehicleRestrictionStr, " ")

	if #attacherJoint.vehicleRestrictions == 0 then
		attacherJoint.vehicleRestrictions = nil
	end

	attacherJoint.allowsJointLimitMovement = xmlFile:getValue(baseName .. "#allowsJointLimitMovement", true)
	attacherJoint.allowsLowering = xmlFile:getValue(baseName .. "#allowsLowering", true)
	attacherJoint.isDefaultLowered = xmlFile:getValue(baseName .. "#isDefaultLowered", false)
	attacherJoint.allowDetachingWhileLifted = xmlFile:getValue(baseName .. "#allowDetachingWhileLifted", true)
	attacherJoint.allowFoldingWhileAttached = xmlFile:getValue(baseName .. "#allowFoldingWhileAttached", true)

	if jointType == AttacherJoints.JOINTTYPE_TRAILER or jointType == AttacherJoints.JOINTTYPE_TRAILERLOW then
		attacherJoint.allowsLowering = false
	end

	attacherJoint.canTurnOnImplement = xmlFile:getValue(baseName .. "#canTurnOnImplement", true)
	local rotationNode = xmlFile:getValue(baseName .. ".rotationNode#node", nil, self.components, self.i3dMappings)

	if rotationNode ~= nil then
		attacherJoint.rotationNode = rotationNode
		attacherJoint.lowerRotation = xmlFile:getValue(baseName .. ".rotationNode#lowerRotation", "0 0 0", true)
		attacherJoint.upperRotation = xmlFile:getValue(baseName .. ".rotationNode#upperRotation", {
			getRotation(rotationNode)
		}, true)
		attacherJoint.rotX, attacherJoint.rotY, attacherJoint.rotZ = xmlFile:getValue(baseName .. ".rotationNode#startRotation", {
			getRotation(rotationNode)
		})
		local lowerValues = {
			attacherJoint.lowerRotation[1],
			attacherJoint.lowerRotation[2],
			attacherJoint.lowerRotation[3]
		}
		local upperValues = {
			attacherJoint.upperRotation[1],
			attacherJoint.upperRotation[2],
			attacherJoint.upperRotation[3]
		}

		for i = 1, 3 do
			local l = lowerValues[i]
			local u = upperValues[i]

			if u < l then
				upperValues[i] = l
				lowerValues[i] = u
			end
		end

		attacherJoint.rotX = MathUtil.clamp(attacherJoint.rotX, lowerValues[1], upperValues[1])
		attacherJoint.rotY = MathUtil.clamp(attacherJoint.rotY, lowerValues[2], upperValues[2])
		attacherJoint.rotZ = MathUtil.clamp(attacherJoint.rotZ, lowerValues[3], upperValues[3])
	end

	local rotationNode2 = xmlFile:getValue(baseName .. ".rotationNode2#node", nil, self.components, self.i3dMappings)

	if rotationNode2 ~= nil then
		attacherJoint.rotationNode2 = rotationNode2
		local defaultLowerRotation2 = {
			-attacherJoint.lowerRotation[1],
			-attacherJoint.lowerRotation[2],
			-attacherJoint.lowerRotation[3]
		}
		attacherJoint.lowerRotation2 = xmlFile:getValue(baseName .. ".rotationNode2#lowerRotation", defaultLowerRotation2, true)
		local defaultUpperRotation2 = {
			-attacherJoint.upperRotation[1],
			-attacherJoint.upperRotation[2],
			-attacherJoint.upperRotation[3]
		}
		attacherJoint.upperRotation2 = xmlFile:getValue(baseName .. ".rotationNode2#upperRotation", defaultUpperRotation2, true)
	end

	attacherJoint.transNode = xmlFile:getValue(baseName .. ".transNode#node", nil, self.components, self.i3dMappings)

	if attacherJoint.transNode ~= nil then
		attacherJoint.transNodeOrgTrans = {
			getTranslation(attacherJoint.transNode)
		}
		attacherJoint.transNodeHeight = xmlFile:getValue(baseName .. ".transNode#height", 0.12)
		attacherJoint.transNodeMinY = xmlFile:getValue(baseName .. ".transNode#minY")
		attacherJoint.transNodeMaxY = xmlFile:getValue(baseName .. ".transNode#maxY")
		attacherJoint.transNodeDependentBottomArm = xmlFile:getValue(baseName .. ".transNode.dependentBottomArm#node", nil, self.components, self.i3dMappings)
		attacherJoint.transNodeDependentBottomArmThreshold = xmlFile:getValue(baseName .. ".transNode.dependentBottomArm#threshold", math.huge)
		attacherJoint.transNodeDependentBottomArmRotation = xmlFile:getValue(baseName .. ".transNode.dependentBottomArm#rotation", "0 0 0", true)
	end

	if (attacherJoint.rotationNode ~= nil or attacherJoint.transNode ~= nil) and xmlFile:getValue(baseName .. ".distanceToGround#lower") == nil then
		Logging.xmlWarning(self.xmlFile, "Missing '.distanceToGround#lower' for attacherJoint '%s'. Use console command 'gsVehicleAnalyze' to get correct values!", baseName)
	end

	attacherJoint.lowerDistanceToGround = xmlFile:getValue(baseName .. ".distanceToGround#lower", 0.7)

	if (attacherJoint.rotationNode ~= nil or attacherJoint.transNode ~= nil) and xmlFile:getValue(baseName .. ".distanceToGround#upper") == nil then
		Logging.xmlWarning(self.xmlFile, "Missing '.distanceToGround#upper' for attacherJoint '%s'. Use console command 'gsVehicleAnalyze' to get correct values!", baseName)
	end

	attacherJoint.upperDistanceToGround = xmlFile:getValue(baseName .. ".distanceToGround#upper", 1)

	if attacherJoint.upperDistanceToGround < attacherJoint.lowerDistanceToGround then
		Logging.xmlWarning(self.xmlFile, "distanceToGround#lower may not be larger than distanceToGround#upper for attacherJoint '%s'. Switching values!", baseName)

		local copy = attacherJoint.lowerDistanceToGround
		attacherJoint.lowerDistanceToGround = attacherJoint.upperDistanceToGround
		attacherJoint.upperDistanceToGround = copy
	end

	attacherJoint.lowerRotationOffset = xmlFile:getValue(baseName .. "#lowerRotationOffset", 0)
	attacherJoint.upperRotationOffset = xmlFile:getValue(baseName .. "#upperRotationOffset", 0)
	attacherJoint.lockDownRotLimit = xmlFile:getValue(baseName .. "#lockDownRotLimit", false)
	attacherJoint.lockUpRotLimit = xmlFile:getValue(baseName .. "#lockUpRotLimit", false)
	attacherJoint.lockDownTransLimit = xmlFile:getValue(baseName .. "#lockDownTransLimit", true)
	attacherJoint.lockUpTransLimit = xmlFile:getValue(baseName .. "#lockUpTransLimit", false)
	local lowerRotLimitStr = "20 20 20"

	if jointType ~= AttacherJoints.JOINTTYPE_IMPLEMENT then
		lowerRotLimitStr = "0 0 0"
	end

	local lx, ly, lz = xmlFile:getValue(baseName .. "#lowerRotLimit", lowerRotLimitStr)
	attacherJoint.lowerRotLimit = {
		math.abs(Utils.getNoNil(lx, 20)),
		math.abs(Utils.getNoNil(ly, 20)),
		math.abs(Utils.getNoNil(lz, 20))
	}
	local ux, uy, uz = xmlFile:getValue(baseName .. "#upperRotLimit")
	attacherJoint.upperRotLimit = {
		math.abs(Utils.getNoNil(Utils.getNoNil(ux, lx), 20)),
		math.abs(Utils.getNoNil(Utils.getNoNil(uy, ly), 20)),
		math.abs(Utils.getNoNil(Utils.getNoNil(uz, lz), 20))
	}
	local lowerTransLimitStr = "0.5 0.5 0.5"

	if jointType ~= AttacherJoints.JOINTTYPE_IMPLEMENT then
		lowerTransLimitStr = "0 0 0"
	end

	lx, ly, lz = xmlFile:getValue(baseName .. "#lowerTransLimit", lowerTransLimitStr)
	attacherJoint.lowerTransLimit = {
		math.abs(Utils.getNoNil(lx, 0)),
		math.abs(Utils.getNoNil(ly, 0)),
		math.abs(Utils.getNoNil(lz, 0))
	}
	ux, uy, uz = xmlFile:getValue(baseName .. "#upperTransLimit")
	attacherJoint.upperTransLimit = {
		math.abs(Utils.getNoNil(Utils.getNoNil(ux, lx), 0)),
		math.abs(Utils.getNoNil(Utils.getNoNil(uy, ly), 0)),
		math.abs(Utils.getNoNil(Utils.getNoNil(uz, lz), 0))
	}
	attacherJoint.jointPositionOffset = xmlFile:getValue(baseName .. "#jointPositionOffset", "0 0 0", true)
	attacherJoint.rotLimitSpring = xmlFile:getValue(baseName .. "#rotLimitSpring", "0 0 0", true)
	attacherJoint.rotLimitDamping = xmlFile:getValue(baseName .. "#rotLimitDamping", "1 1 1", true)
	attacherJoint.rotLimitForceLimit = xmlFile:getValue(baseName .. "#rotLimitForceLimit", "-1 -1 -1", true)
	attacherJoint.transLimitSpring = xmlFile:getValue(baseName .. "#transLimitSpring", "0 0 0", true)
	attacherJoint.transLimitDamping = xmlFile:getValue(baseName .. "#transLimitDamping", "1 1 1", true)
	attacherJoint.transLimitForceLimit = xmlFile:getValue(baseName .. "#transLimitForceLimit", "-1 -1 -1", true)
	attacherJoint.moveDefaultTime = xmlFile:getValue(baseName .. "#moveTime", 0.5) * 1000
	attacherJoint.moveTime = attacherJoint.moveDefaultTime
	attacherJoint.enableCollision = xmlFile:getValue(baseName .. "#enableCollision", false)
	local topArmFilename = xmlFile:getValue(baseName .. ".topArm#filename")

	if topArmFilename ~= nil then
		local baseNode = xmlFile:getValue(baseName .. ".topArm#baseNode", nil, self.components, self.i3dMappings)

		if baseNode ~= nil then
			topArmFilename = Utils.getFilename(topArmFilename, self.baseDirectory)
			attacherJoint.sharedLoadRequestIdTopArm = self:loadSubSharedI3DFile(topArmFilename, false, false, self.onTopArmI3DLoaded, self, {
				xmlFile,
				baseName,
				attacherJoint,
				baseNode
			})
		end
	else
		local rotationNode = xmlFile:getValue(baseName .. ".topArm#rotationNode", nil, self.components, self.i3dMappings)
		local translationNode = xmlFile:getValue(baseName .. ".topArm#translationNode", nil, self.components, self.i3dMappings)
		local referenceNode = xmlFile:getValue(baseName .. ".topArm#referenceNode", nil, self.components, self.i3dMappings)

		if rotationNode ~= nil then
			local topArm = {
				rotationNode = rotationNode
			}
			topArm.rotX, topArm.rotY, topArm.rotZ = getRotation(rotationNode)

			if translationNode ~= nil and referenceNode ~= nil then
				topArm.translationNode = translationNode
				local x, y, z = getTranslation(translationNode)

				if math.abs(x) >= 0.0001 or math.abs(y) >= 0.0001 or math.abs(z) >= 0.0001 then
					Logging.xmlWarning(self.xmlFile, "TopArm translation of attacherJoint '%s' is not 0/0/0!", baseName)
				end

				topArm.referenceDistance = calcDistanceFrom(referenceNode, translationNode)
			end

			topArm.zScale = MathUtil.sign(xmlFile:getValue(baseName .. ".topArm#zScale", 1))
			topArm.toggleVisibility = xmlFile:getValue(baseName .. ".topArm#toggleVisibility", false)

			if topArm.toggleVisibility then
				setVisibility(topArm.rotationNode, false)
			end

			attacherJoint.topArm = topArm
		end
	end

	local rotationNode = xmlFile:getValue(baseName .. ".bottomArm#rotationNode", nil, self.components, self.i3dMappings)
	local translationNode = xmlFile:getValue(baseName .. ".bottomArm#translationNode", nil, self.components, self.i3dMappings)
	local referenceNode = xmlFile:getValue(baseName .. ".bottomArm#referenceNode", nil, self.components, self.i3dMappings)

	if rotationNode ~= nil then
		local bottomArm = {
			rotationNode = rotationNode,
			rotationNodeDir = createTransformGroup("rotationNodeDirTemp")
		}

		link(getParent(rotationNode), bottomArm.rotationNodeDir)
		setTranslation(bottomArm.rotationNodeDir, getTranslation(rotationNode))
		setRotation(bottomArm.rotationNodeDir, getRotation(rotationNode))

		bottomArm.lastDirection = {
			0,
			0,
			0
		}
		bottomArm.rotX, bottomArm.rotY, bottomArm.rotZ = xmlFile:getValue(baseName .. ".bottomArm#startRotation", {
			getRotation(rotationNode)
		})

		function bottomArm.interpolatorGet()
			return getRotation(bottomArm.rotationNode)
		end

		function bottomArm.interpolatorSet(x, y, z)
			setRotation(bottomArm.rotationNode, x, y, z)

			if self.setMovingToolDirty ~= nil then
				self:setMovingToolDirty(bottomArm.rotationNode)
			end
		end

		function bottomArm.interpolatorFinished(_)
			bottomArm.bottomArmInterpolating = false
		end

		bottomArm.interpolatorKey = rotationNode .. "rotation"
		bottomArm.bottomArmInterpolating = false

		if translationNode ~= nil and referenceNode ~= nil then
			bottomArm.translationNode = translationNode
			local x, y, z = getTranslation(translationNode)

			if math.abs(x) >= 0.0001 or math.abs(y) >= 0.0001 or math.abs(z) >= 0.0001 then
				Logging.xmlWarning(self.xmlFile, "BottomArm translation of attacherJoint '%s' is not 0/0/0!", baseName)
			end

			bottomArm.referenceDistance = calcDistanceFrom(referenceNode, translationNode)
		end

		bottomArm.zScale = MathUtil.sign(xmlFile:getValue(baseName .. ".bottomArm#zScale", 1))
		bottomArm.lockDirection = xmlFile:getValue(baseName .. ".bottomArm#lockDirection", true)
		bottomArm.resetSpeed = xmlFile:getValue(baseName .. ".bottomArm#resetSpeed", 45)
		bottomArm.toggleVisibility = xmlFile:getValue(baseName .. ".bottomArm#toggleVisibility", false)

		if bottomArm.toggleVisibility then
			setVisibility(bottomArm.rotationNode, false)
		end

		if jointType == AttacherJoints.JOINTTYPE_IMPLEMENT then
			local toolbarI3dFilename = Utils.getFilename(xmlFile:getValue(baseName .. ".toolbar#filename", "$data/shared/assets/toolbar.i3d"), self.baseDirectory)
			bottomArm.sharedLoadRequestIdToolbar = self:loadSubSharedI3DFile(toolbarI3dFilename, false, false, self.onBottomArmToolbarI3DLoaded, self, {
				bottomArm,
				referenceNode
			})
		end

		attacherJoint.bottomArm = bottomArm
	end

	if self.isClient then
		attacherJoint.sampleAttach = g_soundManager:loadSampleFromXML(xmlFile, baseName, "attachSound", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		attacherJoint.sampleDetach = g_soundManager:loadSampleFromXML(xmlFile, baseName, "detachSound", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
	end

	attacherJoint.steeringBarLeftNode = xmlFile:getValue(baseName .. ".steeringBars#leftNode", nil, self.components, self.i3dMappings)
	attacherJoint.steeringBarRightNode = xmlFile:getValue(baseName .. ".steeringBars#rightNode", nil, self.components, self.i3dMappings)
	attacherJoint.steeringBarForceUsage = xmlFile:getValue(baseName .. ".steeringBars#forceUsage", true)
	attacherJoint.visualNodes = xmlFile:getValue(baseName .. ".visuals#nodes", nil, self.components, self.i3dMappings, true)

	for i = 1, #attacherJoint.visualNodes do
		local visualNode = attacherJoint.visualNodes[i]

		if spec.visualNodeToAttacherJoints[visualNode] == nil then
			spec.visualNodeToAttacherJoints[visualNode] = {}
		end

		table.insert(spec.visualNodeToAttacherJoints[visualNode], attacherJoint)
	end

	attacherJoint.hideVisuals = xmlFile:getValue(baseName .. ".visuals#hide", nil, self.components, self.i3dMappings, true)

	for i = 1, #attacherJoint.hideVisuals do
		local hideNode = attacherJoint.hideVisuals[i]

		if spec.hideVisualNodeToAttacherJoints[hideNode] == nil then
			spec.hideVisualNodeToAttacherJoints[hideNode] = {}
		end

		table.insert(spec.hideVisualNodeToAttacherJoints[hideNode], attacherJoint)
	end

	attacherJoint.changeObjects = {}

	ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, baseName, attacherJoint.changeObjects, self.components, self)
	ObjectChangeUtil.setObjectChanges(attacherJoint.changeObjects, false, self, self.setMovingToolDirty, true)

	attacherJoint.delayedObjectChanges = xmlFile:getValue(baseName .. "#delayedObjectChanges", true)
	attacherJoint.delayedObjectChangesOnAttach = xmlFile:getValue(baseName .. "#delayedObjectChangesOnAttach", false)
	attacherJoint.additionalAttachment = {
		attacherJointDirection = xmlFile:getValue(baseName .. ".additionalAttachment#attacherJointDirection")
	}
	attacherJoint.rootNode = xmlFile:getValue(baseName .. "#rootNode", self.components[1].node, self.components, self.i3dMappings)
	attacherJoint.rootNodeBackup = attacherJoint.rootNode
	attacherJoint.jointIndex = 0
	local t = xmlFile:getValue(baseName .. "#comboTime")

	if t ~= nil then
		table.insert(spec.attacherJointCombos.joints, {
			jointIndex = index + 1,
			time = MathUtil.clamp(t, 0, 1) * spec.attacherJointCombos.duration
		})
	end

	local schemaKey = baseName .. ".schema"

	if xmlFile:hasProperty(schemaKey) then
		local x, y = xmlFile:getValue(schemaKey .. "#position")
		local liftedOffsetX, liftedOffsetY = xmlFile:getValue(schemaKey .. "#liftedOffset", "0 5")

		self.schemaOverlay:addAttacherJoint(x, y, xmlFile:getValue(schemaKey .. "#rotation", 0), xmlFile:getValue(schemaKey .. "#invertX", false), liftedOffsetX, liftedOffsetY)
	else
		Logging.xmlWarning(self.xmlFile, "Missing schema overlay attacherJoint '%s'!", baseName)
	end

	return true
end

function AttacherJoints:onTopArmI3DLoaded(i3dNode, failedReason, args)
	local xmlFile, baseName, attacherJoint, baseNode = unpack(args)

	if i3dNode ~= 0 then
		local rootNode = getChildAt(i3dNode, 0)

		link(baseNode, rootNode)
		delete(i3dNode)
		setTranslation(rootNode, 0, 0, 0)

		local translationNode = getChildAt(rootNode, 0)
		local referenceNode = getChildAt(translationNode, 0)
		local topArm = {
			rotationNode = rootNode,
			rotZ = 0,
			rotY = 0,
			rotX = 0,
			translationNode = translationNode
		}
		local _, _, referenceDistance = getTranslation(referenceNode)
		topArm.referenceDistance = referenceDistance
		topArm.zScale = 1
		local zScale = MathUtil.sign(xmlFile:getValue(baseName .. ".topArm#zScale", 1))

		if zScale < 0 then
			topArm.rotY = math.pi

			setRotation(rootNode, topArm.rotX, topArm.rotY, topArm.rotZ)
		end

		if getNumOfChildren(rootNode) > 1 then
			topArm.scaleNode = getChildAt(rootNode, 1)
			local scaleReferenceNode = getChildAt(topArm.scaleNode, 0)
			local _, _, scaleReferenceDistance = getTranslation(scaleReferenceNode)
			topArm.scaleReferenceDistance = scaleReferenceDistance
		end

		topArm.toggleVisibility = xmlFile:getValue(baseName .. ".topArm#toggleVisibility", false)

		if topArm.toggleVisibility then
			setVisibility(topArm.rotationNode, false)
		end

		local colorValue = xmlFile:getValue(baseName .. ".topArm#color", nil, true)
		local colorValue2 = xmlFile:getValue(baseName .. ".topArm#color2", nil, true)
		local decalColor = xmlFile:getValue(baseName .. ".topArm#decalColor", nil, true)
		local useMainColor = xmlFile:getValue(baseName .. ".topArm#secondPartUseMainColor", true)
		local useBrandDecal = xmlFile:getValue(baseName .. ".topArm#useBrandDecal", true)

		if not useBrandDecal then
			local brandDecal = I3DUtil.getChildByName(rootNode, "brandDecal")

			if brandDecal ~= nil then
				delete(brandDecal)
			else
				Logging.xmlDevWarning(xmlFile, "Unable to find brand decal to remove for '%s'", baseName .. ".topArm")
			end
		end

		if decalColor == nil and colorValue ~= nil then
			local brightness = MathUtil.getBrightnessFromColor(colorValue[1], colorValue[2], colorValue[3])
			brightness = brightness > 0.075 and 1 or 0
			decalColor = {
				1 - brightness,
				1 - brightness,
				1 - brightness
			}
		end

		local _, _, _, mat0 = I3DUtil.getShaderParameterRec(rootNode, "colorMat0")
		local _, _, _, mat1 = I3DUtil.getShaderParameterRec(rootNode, "colorMat1")

		if colorValue ~= nil then
			local material = xmlFile:getValue(baseName .. ".topArm#material")

			I3DUtil.setShaderParameterRec(rootNode, "colorMat0", colorValue[1], colorValue[2], colorValue[3], material or mat0)
		end

		if colorValue2 ~= nil then
			local material2 = xmlFile:getValue(baseName .. ".topArm#material2")

			I3DUtil.setShaderParameterRec(rootNode, "colorMat1", colorValue2[1], colorValue2[2], colorValue2[3], material2 or mat1)
		end

		if useMainColor then
			if colorValue ~= nil then
				local material = xmlFile:getValue(baseName .. ".topArm#material")

				I3DUtil.setShaderParameterRec(rootNode, "colorMat3", colorValue[1], colorValue[2], colorValue[3], material or mat0)
			else
				local x, y, z, w = I3DUtil.getShaderParameterRec(rootNode, "colorMat0")

				I3DUtil.setShaderParameterRec(rootNode, "colorMat3", x, y, z, w)
			end
		elseif colorValue2 ~= nil then
			local material2 = xmlFile:getValue(baseName .. ".topArm#material2")

			I3DUtil.setShaderParameterRec(rootNode, "colorMat3", colorValue2[1], colorValue2[2], colorValue2[3], material2 or mat1)
		else
			local x, y, z, w = I3DUtil.getShaderParameterRec(rootNode, "colorMat1")

			I3DUtil.setShaderParameterRec(rootNode, "colorMat3", x, y, z, w)
		end

		if decalColor ~= nil then
			I3DUtil.setShaderParameterRec(rootNode, "colorMat2", decalColor[1], decalColor[2], decalColor[3], 1)
		end

		attacherJoint.topArm = topArm
	end
end

function AttacherJoints:onBottomArmToolbarI3DLoaded(i3dNode, failedReason, args)
	local bottomArm, referenceNode = unpack(args)

	if i3dNode ~= 0 then
		local rootNode = getChildAt(i3dNode, 0)

		link(referenceNode, rootNode)
		delete(i3dNode)
		setTranslation(rootNode, 0, 0, 0)

		bottomArm.toolbar = rootNode

		setVisibility(rootNode, false)
	end
end

function AttacherJoints:raiseActive(superFunc)
	local spec = self.spec_attacherJoints

	superFunc(self)

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil then
			implement.object:raiseActive()
		end
	end
end

function AttacherJoints:registerActionEvents(superFunc, excludedVehicle)
	local spec = self.spec_attacherJoints

	superFunc(self, excludedVehicle)

	if self ~= excludedVehicle then
		local selectedObject = self:getSelectedObject()

		if selectedObject ~= nil and self ~= selectedObject.vehicle and excludedVehicle ~= selectedObject.vehicle then
			selectedObject.vehicle:registerActionEvents()
		end

		for _, implement in pairs(spec.attachedImplements) do
			if implement.object ~= nil then
				if selectedObject == nil then
					printCallstack()
				end

				implement.object:registerActionEvents(selectedObject.vehicle)
			end
		end
	end
end

function AttacherJoints:removeActionEvents(superFunc)
	local spec = self.spec_attacherJoints

	superFunc(self)

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil then
			implement.object:removeActionEvents()
		end
	end
end

function AttacherJoints:addToPhysics(superFunc)
	local spec = self.spec_attacherJoints

	if not superFunc(self) then
		return false
	end

	for _, implement in pairs(spec.attachedImplements) do
		if not implement.object.spec_attachable.isHardAttached then
			self:createAttachmentJoint(implement)
		end
	end

	return true
end

function AttacherJoints:removeFromPhysics(superFunc)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		if not implement.object.spec_attachable.isHardAttached then
			local jointDesc = spec.attacherJoints[implement.jointDescIndex]

			if jointDesc.jointIndex ~= 0 then
				jointDesc.jointIndex = 0
			end
		end
	end

	if not superFunc(self) then
		return false
	end

	return true
end

function AttacherJoints:getTotalMass(superFunc, onlyGivenVehicle)
	local spec = self.spec_attacherJoints
	local mass = superFunc(self)

	if onlyGivenVehicle == nil or not onlyGivenVehicle then
		for _, implement in pairs(spec.attachedImplements) do
			local object = implement.object
			mass = mass + object:getTotalMass(onlyGivenVehicle)
		end
	end

	return mass
end

function AttacherJoints:addChildVehicles(superFunc, vehicles)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		implement.object:addChildVehicles(vehicles)
	end

	return superFunc(self, vehicles)
end

function AttacherJoints:getAirConsumerUsage(superFunc)
	local spec = self.spec_attacherJoints
	local usage = superFunc(self)

	for _, implement in pairs(spec.attachedImplements) do
		local object = implement.object

		if object.getAttachbleAirConsumerUsage ~= nil then
			usage = usage + object:getAttachbleAirConsumerUsage()
		end
	end

	return usage
end

function AttacherJoints:addVehicleToAIImplementList(superFunc, list)
	superFunc(self, list)

	for _, implement in pairs(self:getAttachedImplements()) do
		implement.object:addVehicleToAIImplementList(list)
	end
end

function AttacherJoints:collectAIAgentAttachments(superFunc, aiDrivableVehicle)
	superFunc(self, aiDrivableVehicle)

	for _, implement in pairs(self:getAttachedImplements()) do
		implement.object:collectAIAgentAttachments(aiDrivableVehicle)
		aiDrivableVehicle:startNewAIAgentAttachmentChain()
	end
end

function AttacherJoints:setAIVehicleObstacleStateDirty(superFunc)
	superFunc(self)

	for _, implement in pairs(self:getAttachedImplements()) do
		if implement.object ~= nil then
			implement.object:setAIVehicleObstacleStateDirty()
		end
	end
end

function AttacherJoints:getDirectionSnapAngle(superFunc)
	local spec = self.spec_attacherJoints
	local maxAngle = superFunc(self)

	for _, implement in pairs(spec.attachedImplements) do
		local object = implement.object

		if object.getDirectionSnapAngle ~= nil then
			maxAngle = math.max(maxAngle + object:getDirectionSnapAngle())
		end
	end

	return maxAngle
end

function AttacherJoints:getAICollisionTriggers(superFunc, collisionTriggers)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local object = implement.object

		if object.getAIImplementCollisionTriggers ~= nil then
			object:getAIImplementCollisionTriggers(collisionTriggers)
		end

		if object.getAICollisionTriggers ~= nil then
			object:getAICollisionTriggers(collisionTriggers)
		end
	end

	return superFunc(self)
end

function AttacherJoints:getFillLevelInformation(superFunc, display)
	local spec = self.spec_attacherJoints

	superFunc(self, display)

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil then
			implement.object:getFillLevelInformation(display)
		end
	end
end

function AttacherJoints:attachableAddToolCameras(superFunc)
	local spec = self.spec_attacherJoints

	superFunc(self)

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil then
			implement.object:attachableAddToolCameras()
		end
	end
end

function AttacherJoints:attachableRemoveToolCameras(superFunc)
	local spec = self.spec_attacherJoints

	superFunc(self)

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil then
			implement.object:attachableRemoveToolCameras()
		end
	end
end

function AttacherJoints:registerSelectableObjects(superFunc, selectableObjects)
	superFunc(self, selectableObjects)

	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local object = implement.object

		if object ~= nil then
			object:registerSelectableObjects(selectableObjects)
		end
	end
end

function AttacherJoints:getIsReadyForAutomatedTrainTravel(superFunc)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil and implement.object.getIsReadyForAutomatedTrainTravel ~= nil and not implement.object:getIsReadyForAutomatedTrainTravel() then
			return false
		end
	end

	return superFunc(self)
end

function AttacherJoints:getIsAutomaticShiftingAllowed(superFunc)
	local spec = self.spec_attacherJoints
	local lastSpeed = self:getLastSpeed()

	for _, implement in pairs(spec.attachedImplements) do
		if lastSpeed < 2 then
			if implement.attachingIsInProgress then
				return false
			else
				local jointDescIndex = implement.jointDescIndex
				local jointDesc = spec.attacherJoints[jointDescIndex]

				if jointDesc.isMoving then
					return false
				end
			end
		end

		if implement.object ~= nil and implement.object.getIsAutomaticShiftingAllowed ~= nil and not implement.object:getIsAutomaticShiftingAllowed() then
			return false
		end
	end

	return superFunc(self)
end

function AttacherJoints:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
		return false
	end

	group.attacherJointIndices = xmlFile:getValue(key .. "#attacherJointIndices", "", true)

	return true
end

function AttacherJoints:getIsDashboardGroupActive(superFunc, group)
	local hasAttachment = #group.attacherJointIndices == 0

	for _, jointIndex in ipairs(group.attacherJointIndices) do
		if self:getImplementFromAttacherJointIndex(jointIndex) ~= nil then
			hasAttachment = true
		end
	end

	return superFunc(self, group) and hasAttachment
end

function AttacherJoints:loadAttacherJointHeightNode(superFunc, xmlFile, key, heightNode, attacherJointNode)
	heightNode.disablingAttacherJointIndices = xmlFile:getValue(key .. "#disablingAttacherJointIndices", "", true)

	return superFunc(self, xmlFile, key, heightNode, attacherJointNode)
end

function AttacherJoints:getIsAttacherJointHeightNodeActive(superFunc, heightNode)
	for _, jointIndex in ipairs(heightNode.disablingAttacherJointIndices) do
		if self:getImplementFromAttacherJointIndex(jointIndex) ~= nil then
			return false
		end
	end

	return superFunc(self, heightNode)
end

function AttacherJoints:isDetachAllowed(superFunc)
	local detachAllowed, warning, showWarning = superFunc(self)

	if not detachAllowed then
		return detachAllowed, warning, showWarning
	end

	local spec = self.spec_attacherJoints

	for attacherJointIndex, attacherJoint in ipairs(spec.attacherJoints) do
		if not attacherJoint.allowDetachingWhileLifted and not attacherJoint.moveDown then
			local implement = self:getImplementByJointDescIndex(attacherJointIndex)

			if implement ~= nil then
				local inputAttacherJoint = implement.object:getInputAttacherJointByJointDescIndex(implement.inputJointDescIndex)

				if inputAttacherJoint ~= nil and not inputAttacherJoint.forceAllowDetachWhileLifted then
					return false, string.format(spec.texts.lowerImplementFirst, implement.object.typeDesc)
				end
			end
		end
	end

	return true
end

function AttacherJoints:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_attacherJoints

	for attacherJointIndex, attacherJoint in ipairs(spec.attacherJoints) do
		if not attacherJoint.allowFoldingWhileAttached and attacherJoint.jointIndex ~= 0 then
			return false, spec.texts.warningFoldingAttacherJoint
		end
	end

	return superFunc(self, direction, onAiTurnOn)
end

function AttacherJoints:getIsWheelFoliageDestructionAllowed(superFunc, wheel)
	if not superFunc(self, wheel) then
		return false
	end

	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local object = implement.object

		if object ~= nil and object.getBlockFoliageDestruction ~= nil and object:getBlockFoliageDestruction() then
			return false
		end
	end

	return true
end

function AttacherJoints:getAreControlledActionsAllowed(superFunc)
	local allowed, warning = superFunc(self)

	if not allowed then
		return false, warning
	end

	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local object = implement.object

		if object ~= nil and object.getAreControlledActionsAllowed ~= nil then
			allowed, warning = object:getAreControlledActionsAllowed()

			if not allowed then
				return false, warning
			end
		end
	end

	return true, warning
end

function AttacherJoints:getConnectionHoseConfigIndex(superFunc)
	local index = superFunc(self)
	index = self.xmlFile:getValue("vehicle.attacherJoints#connectionHoseConfigId", index)

	if self.configurations.attacherJoint ~= nil then
		local configKey = string.format("vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(%d)", self.configurations.attacherJoint - 1)
		index = self.xmlFile:getValue(configKey .. "#connectionHoseConfigId", index)
	end

	return index
end

function AttacherJoints:getPowerTakeOffConfigIndex(superFunc)
	local index = superFunc(self)
	index = self.xmlFile:getValue("vehicle.attacherJoints#powerTakeOffConfigId", index)

	if self.configurations.attacherJoint ~= nil then
		local configKey = string.format("vehicle.attacherJoints.attacherJointConfigurations.attacherJointConfiguration(%d)", self.configurations.attacherJoint - 1)
		index = self.xmlFile:getValue(configKey .. "#powerTakeOffConfigId", index)
	end

	return index
end

function AttacherJoints:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_attacherJoints

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			if #spec.attacherJoints > 0 then
				local selectedImplement = self:getSelectedImplement()

				if selectedImplement ~= nil and selectedImplement.object ~= self then
					for _, attachedImplement in pairs(spec.attachedImplements) do
						if attachedImplement == selectedImplement then
							selectedImplement.object:registerLoweringActionEvent(spec.actionEvents, InputAction.LOWER_IMPLEMENT, selectedImplement.object, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, , true)
						end
					end
				end

				local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.LOWER_ALL_IMPLEMENTS, self, AttacherJoints.actionEventLowerAllImplements, false, true, false, true, nil, , true)

				g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			end

			if self:getSelectedVehicle() == self then
				local state, _ = self:registerSelfLoweringActionEvent(spec.actionEvents, InputAction.LOWER_IMPLEMENT, self, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, , true)

				if (state == nil or not state) and #spec.attachedImplements == 1 then
					local firstImplement = spec.attachedImplements[1]

					if firstImplement ~= nil then
						firstImplement.object:registerLoweringActionEvent(spec.actionEvents, InputAction.LOWER_IMPLEMENT, firstImplement.object, AttacherJoints.actionEventLowerImplement, false, true, false, true, nil, , true)
					end
				end
			end

			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ATTACH, self, AttacherJoints.actionEventAttach, false, true, false, true, nil, , true)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)

			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.DETACH, self, AttacherJoints.actionEventDetach, false, true, false, true, nil, , true)

			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			AttacherJoints.updateActionEvents(self)
		end
	end
end

function AttacherJoints:onActivate()
	self:activateAttachments()
end

function AttacherJoints:onDeactivate()
	self:deactivateAttachments()

	if self.isClient then
		local spec = self.spec_attacherJoints

		g_soundManager:stopSample(spec.samples.hydraulic)

		spec.isHydraulicSamplePlaying = false
	end
end

function AttacherJoints:onReverseDirectionChanged(direction)
	local spec = self.spec_attacherJoints

	if spec.attacherJointCombos ~= nil then
		for _, joint in pairs(spec.attacherJointCombos.joints) do
			joint.time = math.abs(joint.time - spec.attacherJointCombos.duration)
		end
	end
end

function AttacherJoints:onDeactivateLights()
	self:deactivateAttachmentsLights()
end

function AttacherJoints:onStateChange(state, data)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		if implement.object ~= nil then
			implement.object:raiseStateChange(state, data)
		end
	end

	if state == Vehicle.STATE_CHANGE_LOWER_ALL_IMPLEMENTS and #spec.attacherJoints > 0 then
		self:startAttacherJointCombo()
	end
end

function AttacherJoints:onLightsTypesMaskChanged(lightsTypesMask)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil and vehicle.setLightsTypesMask ~= nil then
			vehicle:setLightsTypesMask(lightsTypesMask, true, true)
		end
	end
end

function AttacherJoints:onTurnLightStateChanged(state)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil and vehicle.setTurnLightState ~= nil then
			vehicle:setTurnLightState(state, true, true)
		end
	end
end

function AttacherJoints:onBrakeLightsVisibilityChanged(visibility)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil and vehicle.setBrakeLightsVisibility ~= nil then
			vehicle:setBrakeLightsVisibility(visibility)
		end
	end
end

function AttacherJoints:onReverseLightsVisibilityChanged(visibility)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil and vehicle.setReverseLightsVisibility ~= nil then
			vehicle:setReverseLightsVisibility(visibility)
		end
	end
end

function AttacherJoints:onBeaconLightsVisibilityChanged(visibility)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil and vehicle.setBeaconLightsVisibility ~= nil then
			vehicle:setBeaconLightsVisibility(visibility, true, true)
		end
	end
end

function AttacherJoints:onBrake(brakePedal)
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil and vehicle.brake ~= nil then
			vehicle:brake(brakePedal)
		end
	end
end

function AttacherJoints:onTurnedOn()
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil then
			local turnedOnVehicleSpec = vehicle.spec_turnOnVehicle

			if turnedOnVehicleSpec and turnedOnVehicleSpec.turnedOnByAttacherVehicle then
				vehicle:setIsTurnedOn(true, true)
			end
		end
	end
end

function AttacherJoints:onTurnedOff()
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil then
			local turnedOnVehicleSpec = vehicle.spec_turnOnVehicle

			if turnedOnVehicleSpec and turnedOnVehicleSpec.turnedOnByAttacherVehicle then
				vehicle:setIsTurnedOn(false, true)
			end
		end
	end
end

function AttacherJoints:onLeaveVehicle()
	local spec = self.spec_attacherJoints

	for _, implement in pairs(spec.attachedImplements) do
		local vehicle = implement.object

		if vehicle ~= nil then
			SpecializationUtil.raiseEvent(vehicle, "onLeaveRootVehicle")
		end
	end
end

function AttacherJoints.getAttacherJointCompatibility(vehicle, attacherJoint, inputAttacherVehicle, inputAttacherJoint)
	if inputAttacherJoint.forcedAttachingDirection ~= 0 and attacherJoint.additionalAttachment.attacherJointDirection ~= nil and inputAttacherJoint.forcedAttachingDirection ~= attacherJoint.additionalAttachment.attacherJointDirection then
		return false
	end

	if attacherJoint.subTypes ~= nil then
		if inputAttacherJoint.subTypes == nil then
			return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
		end

		local found = false

		for i = 1, #attacherJoint.subTypes do
			for j = 1, #inputAttacherJoint.subTypes do
				if attacherJoint.subTypes[i] == inputAttacherJoint.subTypes[j] then
					found = true

					break
				end
			end
		end

		if not found then
			return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
		end
	elseif inputAttacherJoint.subTypes ~= nil then
		if inputAttacherJoint.subTypeShowWarning then
			return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
		end

		return false
	end

	if attacherJoint.brandRestrictions ~= nil then
		local found = false

		for i = 1, #attacherJoint.brandRestrictions do
			if inputAttacherVehicle.brand ~= nil and inputAttacherVehicle.brand == attacherJoint.brandRestrictions[i] then
				found = true

				break
			end
		end

		if not found then
			local brandString = ""

			for i = 1, #attacherJoint.brandRestrictions do
				if i > 1 then
					brandString = brandString .. ", "
				end

				brandString = brandString .. attacherJoint.brandRestrictions[i].title
			end

			return false, string.format(vehicle.spec_attacherJoints.texts.warningToolBrandNotCompatible, brandString)
		end
	end

	if attacherJoint.vehicleRestrictions ~= nil then
		local found = false

		for i = 1, #attacherJoint.vehicleRestrictions do
			if inputAttacherVehicle.configFileName:find(attacherJoint.vehicleRestrictions[i]) ~= nil then
				found = true

				break
			end
		end

		if not found then
			return false, vehicle.spec_attacherJoints.texts.warningToolNotCompatible
		end
	end

	return true
end

local getAttacherJointCompatibility = AttacherJoints.getAttacherJointCompatibility

function AttacherJoints.findVehicleInAttachRange()
	log("function 'AttacherJoints.findVehicleInAttachRange' is deprecated. Use 'AttacherJoints.updateVehiclesInAttachRange' instead. Valid output of this function is now up to 5 frames delayed, if parameter 4 is not 'true'.")
end

function AttacherJoints.updateVehiclesInAttachRange(vehicle, maxDistanceSq, maxAngle, fullUpdate)
	local spec = vehicle.spec_attacherJoints

	if spec ~= nil then
		local attachableInfo = spec.attachableInfo
		local pendingInfo = spec.pendingAttachableInfo

		if vehicle.getAttachedImplements ~= nil then
			local implements = vehicle:getAttachedImplements()

			for _, implement in pairs(implements) do
				if implement.object ~= nil then
					local attacherVehicle, attacherVehicleJointDescIndex, attachable, attachableJointDescIndex, warning = AttacherJoints.updateVehiclesInAttachRange(implement.object, maxDistanceSq, maxAngle, fullUpdate)

					if attacherVehicle ~= nil then
						attachableInfo.warning = warning
						attachableInfo.attachableJointDescIndex = attachableJointDescIndex
						attachableInfo.attachable = attachable
						attachableInfo.attacherVehicleJointDescIndex = attacherVehicleJointDescIndex
						attachableInfo.attacherVehicle = attacherVehicle

						return attacherVehicle, attacherVehicleJointDescIndex, attachable, attachableJointDescIndex, warning
					end
				end
			end
		end

		local numJoints = #g_currentMission.inputAttacherJoints
		local minUpdateJoints = math.max(math.floor(numJoints / 5), 1)
		local firstJoint = spec.lastInputAttacherCheckIndex % numJoints + 1
		local lastJoint = math.min(firstJoint + minUpdateJoints, numJoints)

		if fullUpdate then
			firstJoint = 1
			lastJoint = numJoints
		end

		spec.lastInputAttacherCheckIndex = lastJoint % numJoints

		for attacherJointIndex = 1, #spec.attacherJoints do
			local attacherJoint = spec.attacherJoints[attacherJointIndex]

			if attacherJoint.jointIndex == 0 and vehicle:getIsAttachingAllowed(attacherJoint) then
				local x, y, z = getWorldTranslation(attacherJoint.jointTransform)

				for i = firstJoint, lastJoint do
					local jointInfo = g_currentMission.inputAttacherJoints[i]

					if jointInfo.jointType == attacherJoint.jointType then
						local distSq = MathUtil.vector2LengthSq(x - jointInfo.translation[1], z - jointInfo.translation[3])

						if distSq < maxDistanceSq and distSq < pendingInfo.minDistance then
							local distY = y - jointInfo.translation[2]
							local distSqY = distY * distY

							if distSqY < maxDistanceSq * 4 and distSqY < pendingInfo.minDistanceY and (jointInfo.vehicle:getActiveInputAttacherJointDescIndex() == nil or jointInfo.vehicle:getAllowMultipleAttachments()) then
								local compatibility, notAllowedWarning = getAttacherJointCompatibility(vehicle, attacherJoint, jointInfo.vehicle, jointInfo.inputAttacherJoint)

								if compatibility then
									local angleInRange = nil
									local attachAngleLimitAxis = jointInfo.inputAttacherJoint.attachAngleLimitAxis

									if attachAngleLimitAxis == 1 then
										local dx, _, _ = localDirectionToLocal(jointInfo.node, attacherJoint.jointTransform, 1, 0, 0)
										angleInRange = maxAngle < dx
									elseif attachAngleLimitAxis == 2 then
										local _, dy, _ = localDirectionToLocal(jointInfo.node, attacherJoint.jointTransform, 0, 1, 0)
										angleInRange = maxAngle < dy
									else
										local _, _, dz = localDirectionToLocal(jointInfo.node, attacherJoint.jointTransform, 0, 0, 1)
										angleInRange = maxAngle < dz
									end

									if angleInRange then
										pendingInfo.minDistance = distSq
										pendingInfo.minDistanceY = distSqY
										pendingInfo.attacherVehicle = vehicle
										pendingInfo.attacherVehicleJointDescIndex = attacherJointIndex
										pendingInfo.attachable = jointInfo.vehicle
										pendingInfo.attachableJointDescIndex = jointInfo.jointIndex
									end
								else
									pendingInfo.warning = pendingInfo.warning or notAllowedWarning
								end
							end
						end
					end
				end
			end
		end

		if spec.lastInputAttacherCheckIndex == 0 then
			attachableInfo.attacherVehicle = pendingInfo.attacherVehicle
			attachableInfo.attacherVehicleJointDescIndex = pendingInfo.attacherVehicleJointDescIndex
			attachableInfo.attachable = pendingInfo.attachable
			attachableInfo.attachableJointDescIndex = pendingInfo.attachableJointDescIndex
			attachableInfo.warning = pendingInfo.warning
			pendingInfo.minDistance = math.huge
			pendingInfo.minDistanceY = math.huge
			pendingInfo.attacherVehicle = nil
			pendingInfo.attacherVehicleJointDescIndex = nil
			pendingInfo.attachable = nil
			pendingInfo.attachableJointDescIndex = nil
			pendingInfo.warning = nil
		end

		return attachableInfo.attacherVehicle, attachableInfo.attacherVehicleJointDescIndex, attachableInfo.attachable, attachableInfo.attachableJointDescIndex, attachableInfo.warning
	end

	return nil, , , 
end

function AttacherJoints:actionEventAttach(actionName, inputValue, callbackState, isAnalog)
	local info = self.spec_attacherJoints.attachableInfo

	if info.attachable ~= nil then
		local attachAllowed, warning = info.attachable:isAttachAllowed(self:getActiveFarm(), info.attacherVehicle)

		if attachAllowed then
			if self.isServer then
				self:attachImplementFromInfo(info)
			else
				g_client:getServerConnection():sendEvent(VehicleAttachRequestEvent.new(info))
			end
		elseif warning ~= nil then
			g_currentMission:showBlinkingWarning(warning, 2000)
		end
	else
		local object = self:getSelectedVehicle()

		if object ~= nil and object ~= self and object.isDetachAllowed ~= nil then
			local detachAllowed, warning, showWarning = object:isDetachAllowed()

			if detachAllowed then
				object:startDetachProcess()
			elseif showWarning == nil or showWarning then
				g_currentMission:showBlinkingWarning(warning or self.spec_attacherJoints.texts.detachNotAllowed, 2000)
			end
		end
	end
end

function AttacherJoints:actionEventDetach(actionName, inputValue, callbackState, isAnalog)
	local object = self:getSelectedVehicle()

	if object ~= nil and object ~= self and object.isDetachAllowed ~= nil then
		local detachAllowed, warning, showWarning = object:isDetachAllowed()

		if detachAllowed then
			object:startDetachProcess()
		elseif showWarning == nil or showWarning then
			g_currentMission:showBlinkingWarning(warning or self.spec_attacherJoints.texts.detachNotAllowed, 2000)
		end
	end
end

function AttacherJoints:actionEventLowerImplement(actionName, inputValue, callbackState, isAnalog)
	if self.getAttacherVehicle ~= nil then
		self:getAttacherVehicle():handleLowerImplementEvent()
	end
end

function AttacherJoints:actionEventLowerAllImplements(actionName, inputValue, callbackState, isAnalog)
	self:startAttacherJointCombo(true)
	self.rootVehicle:raiseStateChange(Vehicle.STATE_CHANGE_LOWER_ALL_IMPLEMENTS)
end

function AttacherJoints:updateActionEvents()
	local spec = self.spec_attacherJoints
	local info = spec.attachableInfo

	if self.isClient and spec.actionEvents ~= nil then
		local attachActionEvent = spec.actionEvents[InputAction.ATTACH]

		if attachActionEvent ~= nil then
			local visible = false

			if self:getCanToggleAttach() then
				if info.warning ~= nil then
					g_currentMission:showBlinkingWarning(info.warning, 500)
				end

				local text = ""
				local prio = GS_PRIO_VERY_LOW
				local selectedVehicle = self:getSelectedVehicle()

				if selectedVehicle ~= nil and not selectedVehicle.isDeleted and selectedVehicle.isDetachAllowed ~= nil and selectedVehicle:isDetachAllowed() and selectedVehicle:getAttacherVehicle() ~= nil then
					visible = true
					text = spec.texts.actionDetach
				end

				if info.attacherVehicle ~= nil then
					if g_currentMission.accessHandler:canFarmAccess(self:getActiveFarm(), info.attachable) then
						visible = true
						text = spec.texts.actionAttach

						g_currentMission:showAttachContext(info.attachable)

						prio = GS_PRIO_VERY_HIGH
					else
						spec.showAttachNotAllowedText = 100
					end
				end

				g_inputBinding:setActionEventText(attachActionEvent.actionEventId, text)
				g_inputBinding:setActionEventTextPriority(attachActionEvent.actionEventId, prio)
			end

			g_inputBinding:setActionEventTextVisibility(attachActionEvent.actionEventId, visible)
		end

		local lowerActionEvent = spec.actionEvents[InputAction.LOWER_IMPLEMENT]

		if lowerActionEvent ~= nil then
			local showLower = false
			local text = ""
			local selectedImplement = self:getSelectedImplement()

			for _, attachedImplement in pairs(spec.attachedImplements) do
				if attachedImplement == selectedImplement then
					showLower, text = attachedImplement.object:getLoweringActionEventState()

					break
				end
			end

			g_inputBinding:setActionEventActive(lowerActionEvent.actionEventId, showLower)
			g_inputBinding:setActionEventText(lowerActionEvent.actionEventId, text)
			g_inputBinding:setActionEventTextPriority(lowerActionEvent.actionEventId, GS_PRIO_NORMAL)
		end
	end
end

function AttacherJoints.updateAttacherJointLimits(implement, attacherJointDesc, inputAttacherJointDesc, axis)
	local lowerRotLimit = attacherJointDesc.lowerRotLimit[axis] * inputAttacherJointDesc.lowerRotLimitScale[axis]
	local upperRotLimit = attacherJointDesc.upperRotLimit[axis] * inputAttacherJointDesc.upperRotLimitScale[axis]

	if inputAttacherJointDesc.fixedRotation then
		lowerRotLimit = 0
		upperRotLimit = 0
	end

	local upperTransLimit = attacherJointDesc.lowerTransLimit[axis] * inputAttacherJointDesc.lowerTransLimitScale[axis]
	local lowerTransLimit = attacherJointDesc.upperTransLimit[axis] * inputAttacherJointDesc.upperTransLimitScale[axis]
	implement.lowerRotLimit[axis] = lowerRotLimit
	implement.upperRotLimit[axis] = upperRotLimit
	implement.lowerTransLimit[axis] = upperTransLimit
	implement.upperTransLimit[axis] = lowerTransLimit

	if not attacherJointDesc.allowsLowering then
		implement.upperRotLimit[axis] = lowerRotLimit
		implement.upperTransLimit[axis] = upperTransLimit
	end

	local rotLimit = lowerRotLimit
	local transLimit = upperTransLimit

	if attacherJointDesc.allowsLowering and attacherJointDesc.allowsJointLimitMovement then
		if inputAttacherJointDesc.allowsJointRotLimitMovement then
			rotLimit = MathUtil.lerp(upperRotLimit, lowerRotLimit, attacherJointDesc.moveAlpha)
		end

		if inputAttacherJointDesc.allowsJointTransLimitMovement then
			transLimit = MathUtil.lerp(lowerTransLimit, upperTransLimit, attacherJointDesc.moveAlpha)
		end
	end

	return rotLimit, transLimit
end

function AttacherJoints.updateAttacherJointRotationLimit(implement, attacherJointDesc, axis, force, alpha)
	local newRotLimit = MathUtil.lerp(math.max(implement.attachingRotLimit[axis], implement.upperRotLimit[axis]), math.max(implement.attachingRotLimit[axis], implement.lowerRotLimit[axis]), alpha)

	if force or math.abs(newRotLimit - implement.jointRotLimit[axis]) > 0.0005 then
		local rotLimitDown = -newRotLimit
		local rotLimitUp = newRotLimit

		if axis == 3 then
			if attacherJointDesc.lockDownRotLimit then
				rotLimitDown = math.min(-implement.attachingRotLimit[axis], 0)
			end

			if attacherJointDesc.lockUpRotLimit then
				rotLimitUp = math.max(implement.attachingRotLimit[axis], 0)
			end
		end

		setJointRotationLimit(attacherJointDesc.jointIndex, axis - 1, true, rotLimitDown, rotLimitUp)

		implement.jointRotLimit[axis] = newRotLimit
	end
end

function AttacherJoints.updateAttacherJointTranslationLimit(implement, attacherJointDesc, axis, force, alpha)
	local newTransLimit = MathUtil.lerp(math.max(implement.attachingTransLimit[axis], implement.upperTransLimit[axis]), math.max(implement.attachingTransLimit[axis], implement.lowerTransLimit[axis]), alpha)

	if force or math.abs(newTransLimit - implement.jointTransLimit[axis]) > 0.0005 then
		local transLimitDown = -newTransLimit
		local transLimitUp = newTransLimit

		if axis == 2 then
			if attacherJointDesc.lockDownTransLimit then
				transLimitDown = math.min(-implement.attachingTransLimit[axis], 0)
			end

			if attacherJointDesc.lockUpTransLimit then
				transLimitUp = math.max(implement.attachingTransLimit[axis], 0)
			end
		end

		setJointTranslationLimit(attacherJointDesc.jointIndex, axis - 1, true, transLimitDown, transLimitUp)

		implement.jointTransLimit[axis] = newTransLimit
	end
end
