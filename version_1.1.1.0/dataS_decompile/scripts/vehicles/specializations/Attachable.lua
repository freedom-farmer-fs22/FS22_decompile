Attachable = {
	INPUT_ATTACHERJOINT_XML_KEY = "vehicle.attachable.inputAttacherJoints.inputAttacherJoint(?)",
	INPUT_ATTACHERJOINT_CONFIG_XML_KEY = "vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration(?).inputAttacherJoint(?)",
	SUPPORT_XML_KEY = "vehicle.attachable.support(?)",
	STEERING_AXLE_XML_KEY = "vehicle.attachable.steeringAxleAngleScale",
	prerequisitesPresent = function (specializations)
		return true
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onPreAttach")
		SpecializationUtil.registerEvent(vehicleType, "onPostAttach")
		SpecializationUtil.registerEvent(vehicleType, "onPreDetach")
		SpecializationUtil.registerEvent(vehicleType, "onPostDetach")
		SpecializationUtil.registerEvent(vehicleType, "onSetLowered")
		SpecializationUtil.registerEvent(vehicleType, "onSetLoweredAll")
		SpecializationUtil.registerEvent(vehicleType, "onLeaveRootVehicle")
	end
}

function Attachable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadInputAttacherJoint", Attachable.loadInputAttacherJoint)
	SpecializationUtil.registerFunction(vehicleType, "loadAttacherJointHeightNode", Attachable.loadAttacherJointHeightNode)
	SpecializationUtil.registerFunction(vehicleType, "getIsAttacherJointHeightNodeActive", Attachable.getIsAttacherJointHeightNodeActive)
	SpecializationUtil.registerFunction(vehicleType, "getInputAttacherJointByJointDescIndex", Attachable.getInputAttacherJointByJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getAttacherVehicle", Attachable.getAttacherVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getInputAttacherJoints", Attachable.getInputAttacherJoints)
	SpecializationUtil.registerFunction(vehicleType, "getIsAttachedTo", Attachable.getIsAttachedTo)
	SpecializationUtil.registerFunction(vehicleType, "getActiveInputAttacherJointDescIndex", Attachable.getActiveInputAttacherJointDescIndex)
	SpecializationUtil.registerFunction(vehicleType, "getActiveInputAttacherJoint", Attachable.getActiveInputAttacherJoint)
	SpecializationUtil.registerFunction(vehicleType, "getAllowsLowering", Attachable.getAllowsLowering)
	SpecializationUtil.registerFunction(vehicleType, "loadSupportAnimationFromXML", Attachable.loadSupportAnimationFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsSupportAnimationAllowed", Attachable.getIsSupportAnimationAllowed)
	SpecializationUtil.registerFunction(vehicleType, "startDetachProcess", Attachable.startDetachProcess)
	SpecializationUtil.registerFunction(vehicleType, "getIsImplementChainLowered", Attachable.getIsImplementChainLowered)
	SpecializationUtil.registerFunction(vehicleType, "getIsInWorkPosition", Attachable.getIsInWorkPosition)
	SpecializationUtil.registerFunction(vehicleType, "getAttachbleAirConsumerUsage", Attachable.getAttachbleAirConsumerUsage)
	SpecializationUtil.registerFunction(vehicleType, "isDetachAllowed", Attachable.isDetachAllowed)
	SpecializationUtil.registerFunction(vehicleType, "isAttachAllowed", Attachable.isAttachAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsInputAttacherActive", Attachable.getIsInputAttacherActive)
	SpecializationUtil.registerFunction(vehicleType, "getSteeringAxleBaseVehicle", Attachable.getSteeringAxleBaseVehicle)
	SpecializationUtil.registerFunction(vehicleType, "loadSteeringAxleFromXML", Attachable.loadSteeringAxleFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsSteeringAxleAllowed", Attachable.getIsSteeringAxleAllowed)
	SpecializationUtil.registerFunction(vehicleType, "loadSteeringAngleNodeFromXML", Attachable.loadSteeringAngleNodeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "updateSteeringAngleNode", Attachable.updateSteeringAngleNode)
	SpecializationUtil.registerFunction(vehicleType, "attachableAddToolCameras", Attachable.attachableAddToolCameras)
	SpecializationUtil.registerFunction(vehicleType, "attachableRemoveToolCameras", Attachable.attachableRemoveToolCameras)
	SpecializationUtil.registerFunction(vehicleType, "preAttach", Attachable.preAttach)
	SpecializationUtil.registerFunction(vehicleType, "postAttach", Attachable.postAttach)
	SpecializationUtil.registerFunction(vehicleType, "preDetach", Attachable.preDetach)
	SpecializationUtil.registerFunction(vehicleType, "postDetach", Attachable.postDetach)
	SpecializationUtil.registerFunction(vehicleType, "setLowered", Attachable.setLowered)
	SpecializationUtil.registerFunction(vehicleType, "setLoweredAll", Attachable.setLoweredAll)
	SpecializationUtil.registerFunction(vehicleType, "setIsAdditionalAttachment", Attachable.setIsAdditionalAttachment)
	SpecializationUtil.registerFunction(vehicleType, "getIsAdditionalAttachment", Attachable.getIsAdditionalAttachment)
	SpecializationUtil.registerFunction(vehicleType, "setIsSupportVehicle", Attachable.setIsSupportVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getIsSupportVehicle", Attachable.getIsSupportVehicle)
	SpecializationUtil.registerFunction(vehicleType, "registerLoweringActionEvent", Attachable.registerLoweringActionEvent)
	SpecializationUtil.registerFunction(vehicleType, "getLoweringActionEventState", Attachable.getLoweringActionEventState)
	SpecializationUtil.registerFunction(vehicleType, "getAllowMultipleAttachments", Attachable.getAllowMultipleAttachments)
	SpecializationUtil.registerFunction(vehicleType, "resolveMultipleAttachments", Attachable.resolveMultipleAttachments)
	SpecializationUtil.registerFunction(vehicleType, "getBlockFoliageDestruction", Attachable.getBlockFoliageDestruction)
end

function Attachable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "findRootVehicle", Attachable.findRootVehicle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActive", Attachable.getIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsOperating", Attachable.getIsOperating)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", Attachable.getBrakeForce)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Attachable.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", Attachable.getCanToggleTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanImplementBeUsedForAI", Attachable.getCanImplementBeUsedForAI)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", Attachable.getCanAIImplementContinueWork)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave", Attachable.getDeactivateOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getActiveFarm", Attachable.getActiveFarm)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Attachable.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLowered", Attachable.getIsLowered)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "mountDynamic", Attachable.mountDynamic)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getOwner", Attachable.getOwner)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInUse", Attachable.getIsInUse)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getUpdatePriority", Attachable.getUpdatePriority)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeReset", Attachable.getCanBeReset)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAdditionalLightAttributesFromXML", Attachable.loadAdditionalLightAttributesFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLightActive", Attachable.getIsLightActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowered", Attachable.getIsPowered)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConnectionHoseConfigIndex", Attachable.getConnectionHoseConfigIndex)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMapHotspotVisible", Attachable.getIsMapHotspotVisible)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getPowerTakeOffConfigIndex", Attachable.getPowerTakeOffConfigIndex)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", Attachable.loadDashboardGroupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", Attachable.getIsDashboardGroupActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "setWorldPositionQuaternion", Attachable.setWorldPositionQuaternion)
end

function Attachable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDelete", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onSelect", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onUnselect", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", Attachable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", Attachable)
end

function Attachable.initSpecialization()
	g_configurationManager:addConfigurationType("inputAttacherJoint", g_i18n:getText("configuration_inputAttacherJoint"), "attachable", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Attachable")
	Attachable.registerInputAttacherJointXMLPaths(schema, Attachable.INPUT_ATTACHERJOINT_XML_KEY)
	Attachable.registerInputAttacherJointXMLPaths(schema, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY)
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration(?)")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, Attachable.INPUT_ATTACHERJOINT_XML_KEY)
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY)
	schema:register(XMLValueType.INT, "vehicle.attachable#connectionHoseConfigId", "Connection hose configuration index to use")
	schema:register(XMLValueType.INT, "vehicle.attachable#powerTakeOffConfigId", "Power take off configuration index to use")
	schema:register(XMLValueType.INT, "vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration(?)#connectionHoseConfigId", "Connection hose configuration index to use")
	schema:register(XMLValueType.INT, "vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration(?)#powerTakeOffConfigId", "Power take off configuration index to use")
	schema:register(XMLValueType.FLOAT, "vehicle.attachable.brakeForce#force", "Brake force", 0)
	schema:register(XMLValueType.FLOAT, "vehicle.attachable.brakeForce#maxForce", "Brake force when vehicle reached mass of #maxForceMass", 0)
	schema:register(XMLValueType.FLOAT, "vehicle.attachable.brakeForce#maxForceMass", "When this mass is reached the vehicle will brake with #maxForce", 0)
	schema:register(XMLValueType.FLOAT, "vehicle.attachable.brakeForce#loweredForce", "Brake force while the tool is lowered")
	schema:register(XMLValueType.FLOAT, "vehicle.attachable.airConsumer#usage", "Air consumption while fully braking", 0)
	schema:register(XMLValueType.BOOL, "vehicle.attachable#allowFoldingWhileAttached", "Allow folding while attached", true)
	schema:register(XMLValueType.BOOL, "vehicle.attachable#allowFoldingWhileLowered", "Allow folding while lowered", true)
	schema:register(XMLValueType.BOOL, "vehicle.attachable#blockFoliageDestruction", "If active the vehicle will block the complete foliage destruction of the vehicle chain", false)
	schema:register(XMLValueType.BOOL, "vehicle.attachable.power#requiresExternalPower", "Tool requires external power from a vehicle with motor to work", true)
	schema:register(XMLValueType.L10N_STRING, "vehicle.attachable.power#attachToPowerWarning", "Warning to be displayed if no vehicle with motor is attached", "warning_attachToPower")
	schema:register(XMLValueType.FLOAT, "vehicle.attachable.steeringAxleAngleScale#startSpeed", "Start speed", 10)
	schema:register(XMLValueType.FLOAT, "vehicle.attachable.steeringAxleAngleScale#endSpeed", "End speed", 30)
	schema:register(XMLValueType.BOOL, "vehicle.attachable.steeringAxleAngleScale#backwards", "Is active backwards", false)
	schema:register(XMLValueType.FLOAT, "vehicle.attachable.steeringAxleAngleScale#speed", "Speed", 0.001)
	schema:register(XMLValueType.BOOL, "vehicle.attachable.steeringAxleAngleScale#useSuperAttachable", "Use super attachable", false)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.attachable.steeringAxleAngleScale.targetNode#node", "Target node")
	schema:register(XMLValueType.ANGLE, "vehicle.attachable.steeringAxleAngleScale.targetNode#refAngle", "Reference angle to transfer from angle between vehicles to defined min. and max. rot for target node")
	schema:register(XMLValueType.ANGLE, "vehicle.attachable.steeringAxleAngleScale#minRot", "Min Rotation", 0)
	schema:register(XMLValueType.ANGLE, "vehicle.attachable.steeringAxleAngleScale#maxRot", "Max Rotation", 0)
	schema:register(XMLValueType.FLOAT, "vehicle.attachable.steeringAxleAngleScale#direction", "Direction", 1)
	schema:register(XMLValueType.BOOL, "vehicle.attachable.steeringAxleAngleScale#forceUsage", "Force usage of steering axle, even if attacher vehicle does not have steering bar nodes", false)
	schema:register(XMLValueType.BOOL, "vehicle.attachable.steeringAxleAngleScale#speedDependent", "Steering axle angle is scaled based on speed with #startSpeed and #endSpeed", true)
	schema:register(XMLValueType.FLOAT, "vehicle.attachable.steeringAxleAngleScale#distanceDelay", "The steering angle is updated delayed after vehicle has been moved this distance", 0)
	schema:register(XMLValueType.INT, "vehicle.attachable.steeringAxleAngleScale#referenceComponentIndex", "If defined the given component is used for steering angle reference. Y between root component and this component will result in steering angle.")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.attachable.steeringAngleNodes.steeringAngleNode(?)#node", "Steering angle node")
	schema:register(XMLValueType.ANGLE, "vehicle.attachable.steeringAngleNodes.steeringAngleNode(?)#speed", "Change speed (degree per second)", 25)
	schema:register(XMLValueType.FLOAT, "vehicle.attachable.steeringAngleNodes.steeringAngleNode(?)#scale", "Scale of vehicle to vehicle angle that is applied", 1)
	schema:register(XMLValueType.STRING, "vehicle.attachable.support(?)#animationName", "Animation name")
	schema:register(XMLValueType.BOOL, "vehicle.attachable.support(?)#delayedOnLoad", "Defines if the animation is played onPostLoad or onLoadFinished -> useful if the animation collides e.g. with the folding animation", false)
	schema:register(XMLValueType.BOOL, "vehicle.attachable.support(?)#delayedOnAttach", "Defines if the animation is played before or after the attaching process", true)
	schema:register(XMLValueType.BOOL, "vehicle.attachable.support(?)#detachAfterAnimation", "Defines if the vehicle is detached after the animation has played", true)
	schema:register(XMLValueType.FLOAT, "vehicle.attachable.support(?)#detachAnimationTime", "Defines when in the support animation the vehicle is detached (detachAfterAnimation needs to be true)", 1)
	schema:register(XMLValueType.STRING, "vehicle.attachable.lowerAnimation#name", "Animation name")
	schema:register(XMLValueType.FLOAT, "vehicle.attachable.lowerAnimation#speed", "Animation speed", 1)
	schema:register(XMLValueType.INT, "vehicle.attachable.lowerAnimation#directionOnDetach", "Direction on detach", 0)
	schema:register(XMLValueType.BOOL, "vehicle.attachable.lowerAnimation#defaultLowered", "Is default lowered", false)

	for i = 1, #Lights.ADDITIONAL_LIGHT_ATTRIBUTES_KEYS do
		local key = Lights.ADDITIONAL_LIGHT_ATTRIBUTES_KEYS[i]

		schema:register(XMLValueType.INT, key .. "#inputAttacherJointIndex", "Index of input attacher joint that needs to be active to activate light")
	end

	schema:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#isAttached", "Tool is attached")
	schema:addDelayedRegistrationFunc("AnimatedVehicle:part", function (cSchema, cKey)
		cSchema:register(XMLValueType.INT, cKey .. "#inputAttacherJointIndex", "Input Attacher Joint Index [1..n]")
		cSchema:register(XMLValueType.VECTOR_3, cKey .. "#lowerRotLimitScaleStart", "Lower rotaton limit start")
		cSchema:register(XMLValueType.VECTOR_3, cKey .. "#lowerRotLimitScaleEnd", "Lower rotaton limit end")
		cSchema:register(XMLValueType.VECTOR_3, cKey .. "#upperRotLimitScaleStart", "Upper rotaton limit start")
		cSchema:register(XMLValueType.VECTOR_3, cKey .. "#upperRotLimitScaleEnd", "Upper rotaton limit end")
		cSchema:register(XMLValueType.VECTOR_3, cKey .. "#lowerTransLimitScaleStart", "Lower translation limit start")
		cSchema:register(XMLValueType.VECTOR_3, cKey .. "#lowerTransLimitScaleEnd", "Lower translation limit end")
		cSchema:register(XMLValueType.VECTOR_3, cKey .. "#upperTransLimitScaleStart", "Upper translation limit start")
		cSchema:register(XMLValueType.VECTOR_3, cKey .. "#upperTransLimitScaleEnd", "Upper translation limit end")
		cSchema:register(XMLValueType.ANGLE, cKey .. "#lowerRotationOffsetStart", "Lower rotation offset start")
		cSchema:register(XMLValueType.ANGLE, cKey .. "#lowerRotationOffsetEnd", "Lower rotation offset end")
		cSchema:register(XMLValueType.ANGLE, cKey .. "#upperRotationOffsetStart", "Upper rotation offset start")
		cSchema:register(XMLValueType.ANGLE, cKey .. "#upperRotationOffsetEnd", "Upper rotation offset end")
		cSchema:register(XMLValueType.FLOAT, cKey .. "#lowerDistanceToGroundStart", "Lower distance to ground start")
		cSchema:register(XMLValueType.FLOAT, cKey .. "#lowerDistanceToGroundEnd", "Lower distance to ground end")
		cSchema:register(XMLValueType.FLOAT, cKey .. "#upperDistanceToGroundStart", "Upper distance to ground start")
		cSchema:register(XMLValueType.FLOAT, cKey .. "#upperDistanceToGroundEnd", "Upper distance to ground end")
	end)
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame

	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).attachable#lowerAnimTime", "Lower animation time")
end

function Attachable.registerInputAttacherJointXMLPaths(schema, baseName)
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#node", "Joint Node")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".heightNode(?)#node", "Height Node")
	schema:register(XMLValueType.STRING, baseName .. "#jointType", "Joint type")
	schema:register(XMLValueType.STRING, baseName .. ".subType#name", "If defined this type needs to match with the sub type in the attacher vehicle")
	schema:register(XMLValueType.BOOL, baseName .. ".subType#showWarning", "Show warning if user tries to attach with a different sub type", true)
	schema:register(XMLValueType.BOOL, baseName .. "#needsTrailerJoint", "Needs trailer joint (only if no joint type is given)", false)
	schema:register(XMLValueType.BOOL, baseName .. "#needsLowJoint", "Needs low trailer joint (only if no joint type is given)", false)
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#topReferenceNode", "Top Reference Node")
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#rootNode", "Root node", "first component")
	schema:register(XMLValueType.BOOL, baseName .. "#allowsDetaching", "Allows detaching", true)
	schema:register(XMLValueType.BOOL, baseName .. "#fixedRotation", "Fixed rotation (Rot limit is freezed)", false)
	schema:register(XMLValueType.BOOL, baseName .. "#hardAttach", "Implement is hard attached", false)
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#nodeVisual", "Visual joint node")
	schema:register(XMLValueType.FLOAT, baseName .. ".distanceToGround#lower", "Lower distance to ground")
	schema:register(XMLValueType.FLOAT, baseName .. ".distanceToGround#upper", "Upper distance to ground")
	schema:register(XMLValueType.STRING, baseName .. ".distanceToGround.vehicle(?)#filename", "Vehicle filename to activate these distances")
	schema:register(XMLValueType.FLOAT, baseName .. ".distanceToGround.vehicle(?)#lower", "Lower distance to ground while attached to this vehicle")
	schema:register(XMLValueType.FLOAT, baseName .. ".distanceToGround.vehicle(?)#upper", "Upper distance to ground while attached to this vehicle")
	schema:register(XMLValueType.ANGLE, baseName .. "#lowerRotationOffset", "Rotation offset if lowered")
	schema:register(XMLValueType.ANGLE, baseName .. "#upperRotationOffset", "Rotation offset if lifted", "8 degrees for implements")
	schema:register(XMLValueType.BOOL, baseName .. "#allowsJointRotLimitMovement", "Rotation limit is changed during lifting/lowering", true)
	schema:register(XMLValueType.BOOL, baseName .. "#allowsJointTransLimitMovement", "Translation limit is changed during lifting/lowering", true)
	schema:register(XMLValueType.BOOL, baseName .. "#needsToolbar", "Needs toolbar", false)
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#steeringBarLeftNode", "Left steering bar node")
	schema:register(XMLValueType.NODE_INDEX, baseName .. "#steeringBarRightNode", "Right steering bar node")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#upperRotLimitScale", "Upper rot limit scale", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#lowerRotLimitScale", "Lower rot limit scale", "0 0 0")
	schema:register(XMLValueType.FLOAT, baseName .. "#rotLimitThreshold", "Defines when the transition from upper to lower rot limit starts (0: directly, 0.9: after 90% of lowering)", 0)
	schema:register(XMLValueType.VECTOR_3, baseName .. "#upperTransLimitScale", "Upper trans limit scale", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#lowerTransLimitScale", "Lower trans limit scale", "0 0 0")
	schema:register(XMLValueType.FLOAT, baseName .. "#transLimitThreshold", "Defines when the transition from upper to lower trans limit starts (0: directly, 0.9: after 90% of lowering)", 0)
	schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitSpring", "Rotation limit spring", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitDamping", "Rotation limit damping", "1 1 1")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#rotLimitForceLimit", "Rotation limit force limit", "-1 -1 -1")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitSpring", "Translation limit spring", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitDamping", "Translation limit damping", "1 1 1")
	schema:register(XMLValueType.VECTOR_3, baseName .. "#transLimitForceLimit", "Translation limit force limit", "-1 -1 -1")
	schema:register(XMLValueType.INT, baseName .. "#attachAngleLimitAxis", "Direction axis which is used to calculate angle to enable attach", 1)
	schema:register(XMLValueType.FLOAT, baseName .. "#attacherHeight", "Height of attacher", "0.9 for trailer, 0.55 for trailer low")
	schema:register(XMLValueType.BOOL, baseName .. "#needsLowering", "Needs lowering")
	schema:register(XMLValueType.BOOL, baseName .. "#allowsLowering", "Allows lowering")
	schema:register(XMLValueType.BOOL, baseName .. "#isDefaultLowered", "Is default lowered", false)
	schema:register(XMLValueType.BOOL, baseName .. "#useFoldingLoweredState", "Use folding lowered state", false)
	schema:register(XMLValueType.BOOL, baseName .. "#forceSelectionOnAttach", "Is selected on attach", true)
	schema:register(XMLValueType.BOOL, baseName .. "#forceAllowDetachWhileLifted", "Attacher vehicle can be always detached no matter if we are lifted or not", false)
	schema:register(XMLValueType.INT, baseName .. "#forcedAttachingDirection", "Tool can be only attached in this direction", 0)
	schema:register(XMLValueType.BOOL, baseName .. "#allowFolding", "Folding is allowed while attached to this attacher joint", true)
	schema:register(XMLValueType.BOOL, baseName .. "#allowTurnOn", "Turn on is allowed while attached to this attacher joint", true)
	schema:register(XMLValueType.BOOL, baseName .. "#allowAI", "Toggeling of AI is allowed while attached to this attacher joint", true)
	schema:register(XMLValueType.BOOL, baseName .. "#allowDetachWhileParentLifted", "If set to false the parent vehicle needs to be lowered to be able to detach this implement", true)
	schema:register(XMLValueType.INT, baseName .. ".dependentAttacherJoint(?)#attacherJointIndex", "Dependent attacher joint index")
	schema:register(XMLValueType.NODE_INDEX, baseName .. ".additionalObjects.additionalObject(?)#node", "Additional object node")
	schema:register(XMLValueType.STRING, baseName .. ".additionalObjects.additionalObject(?)#attacherVehiclePath", "Path to vehicle for object activation")
	schema:register(XMLValueType.STRING, baseName .. ".additionalAttachment#filename", "Path to additional attachment")
	schema:register(XMLValueType.INT, baseName .. ".additionalAttachment#inputAttacherJointIndex", "Input attacher joint index of additional attachment")
	schema:register(XMLValueType.BOOL, baseName .. ".additionalAttachment#needsLowering", "Additional implements needs lowering")
	schema:register(XMLValueType.STRING, baseName .. ".additionalAttachment#jointType", "Additional implement joint type")
end

function Attachable:onLoad(savegame)
	local spec = self.spec_attachable

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attacherJoint", "vehicle.inputAttacherJoints.inputAttacherJoint")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.needsLowering", "vehicle.inputAttacherJoints.inputAttacherJoint#needsLowering")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.allowsLowering", "vehicle.inputAttacherJoints.inputAttacherJoint#allowsLowering")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.isDefaultLowered", "vehicle.inputAttacherJoints.inputAttacherJoint#isDefaultLowered")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.forceSelectionOnAttach#value", "vehicle.inputAttacherJoints.inputAttacherJoint#forceSelectionOnAttach")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.topReferenceNode#index", "vehicle.attacherJoint#topReferenceNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attachRootNode#index", "vehicle.attacherJoint#rootNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.inputAttacherJoints", "vehicle.attachable.inputAttacherJoints")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.inputAttacherJointConfigurations", "vehicle.attachable.inputAttacherJointConfigurations")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.brakeForce", "vehicle.attachable.brakeForce#force")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attachable.brakeForce", "vehicle.attachable.brakeForce#force", nil, true)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.steeringAxleAngleScale", "vehicle.attachable.steeringAxleAngleScale")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.support", "vehicle.attachable.support")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lowerAnimation", "vehicle.attachable.lowerAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.toolCameras", "vehicle.attachable.toolCameras")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attachable.toolCameras#count", "vehicle.attachable.toolCameras")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attachable.toolCameras.toolCamera1", "vehicle.attachable.toolCamera")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attachable.toolCameras.toolCamera2", "vehicle.attachable.toolCamera")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attachable.toolCameras.toolCamera3", "vehicle.attachable.toolCamera")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.foldable.foldingParts#onlyFoldOnDetach", "vehicle.attachable#allowFoldingWhileAttached")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.maximalAirConsumptionPerFullStop", "vehicle.attachable.airConsumer#usage (is now in usage per second at full brake power)")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.attachable.steeringAxleAngleScale#targetNode", "vehicle.attachable.steeringAxleAngleScale.targetNode#node")

	spec.attacherJoint = nil
	spec.inputAttacherJoints = {}

	self.xmlFile:iterate("vehicle.attachable.inputAttacherJoints.inputAttacherJoint", function (i, key)
		local inputAttacherJoint = {}

		if self:loadInputAttacherJoint(self.xmlFile, key, inputAttacherJoint, i - 1) then
			table.insert(spec.inputAttacherJoints, inputAttacherJoint)

			inputAttacherJoint.jointInfo = g_currentMission:registerInputAttacherJoint(self, #spec.inputAttacherJoints, inputAttacherJoint)
		end
	end)

	if self.configurations.inputAttacherJoint ~= nil then
		local attacherConfigs = string.format("vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration(%d)", self.configurations.inputAttacherJoint - 1)

		self.xmlFile:iterate(attacherConfigs .. ".inputAttacherJoint", function (i, baseName)
			local inputAttacherJoint = {}

			if self:loadInputAttacherJoint(self.xmlFile, baseName, inputAttacherJoint, i - 1) then
				table.insert(spec.inputAttacherJoints, inputAttacherJoint)

				inputAttacherJoint.jointInfo = g_currentMission:registerInputAttacherJoint(self, #spec.inputAttacherJoints, inputAttacherJoint)
			end
		end)
		ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration", self.configurations.inputAttacherJoint, self.components, self)
	end

	spec.brakeForce = self.xmlFile:getValue("vehicle.attachable.brakeForce#force", 0) * 10
	spec.maxBrakeForce = self.xmlFile:getValue("vehicle.attachable.brakeForce#maxForce", 0) * 10
	spec.loweredBrakeForce = self.xmlFile:getValue("vehicle.attachable.brakeForce#loweredForce", -1) * 10
	spec.maxBrakeForceMass = self.xmlFile:getValue("vehicle.attachable.brakeForce#maxForceMass", 0) / 1000
	spec.airConsumerUsage = self.xmlFile:getValue("vehicle.attachable.airConsumer#usage", 0)
	spec.allowFoldingWhileAttached = self.xmlFile:getValue("vehicle.attachable#allowFoldingWhileAttached", true)
	spec.allowFoldingWhileLowered = self.xmlFile:getValue("vehicle.attachable#allowFoldingWhileLowered", true)
	spec.blockFoliageDestruction = self.xmlFile:getValue("vehicle.attachable#blockFoliageDestruction", false)
	spec.requiresExternalPower = self.xmlFile:getValue("vehicle.attachable.power#requiresExternalPower", true)
	spec.attachToPowerWarning = self.xmlFile:getValue("vehicle.attachable.power#attachToPowerWarning", "warning_attachToPower", self.customEnvironment)
	spec.updateWheels = true
	spec.updateSteeringAxleAngle = true
	spec.isSelected = false
	spec.attachTime = 0
	spec.steeringAxleAngle = 0
	spec.steeringAxleTargetAngle = 0

	self:loadSteeringAxleFromXML(spec, self.xmlFile, "vehicle.attachable.steeringAxleAngleScale")

	if spec.steeringAxleDistanceDelay > 0 then
		spec.steeringAxleTargetAngleHistory = {}

		for i = 1, math.floor(spec.steeringAxleDistanceDelay / 0.1) do
			spec.steeringAxleTargetAngleHistory[i] = 0
		end

		spec.steeringAxleTargetAngleHistoryIndex = 1
		spec.steeringAxleTargetAngleHistoryMoved = 1
	end

	spec.steeringAngleNodes = {}

	self.xmlFile:iterate("vehicle.attachable.steeringAngleNodes.steeringAngleNode", function (_, key)
		local entry = {}

		if self:loadSteeringAngleNodeFromXML(entry, self.xmlFile, key) then
			table.insert(spec.steeringAngleNodes, entry)
		end
	end)

	spec.detachingInProgress = false
	spec.supportAnimations = {}

	self.xmlFile:iterate("vehicle.attachable.support", function (_, baseKey)
		local entry = {}

		if self:loadSupportAnimationFromXML(entry, self.xmlFile, baseKey) then
			table.insert(spec.supportAnimations, entry)
		end
	end)

	spec.lowerAnimation = self.xmlFile:getValue("vehicle.attachable.lowerAnimation#name")
	spec.lowerAnimationSpeed = self.xmlFile:getValue("vehicle.attachable.lowerAnimation#speed", 1)
	spec.lowerAnimationDirectionOnDetach = self.xmlFile:getValue("vehicle.attachable.lowerAnimation#directionOnDetach", 0)
	spec.lowerAnimationDefaultLowered = self.xmlFile:getValue("vehicle.attachable.lowerAnimation#defaultLowered", false)
	spec.toolCameras = {}

	self.xmlFile:iterate("vehicle.attachable.toolCameras.toolCamera", function (_, cameraKey)
		local camera = VehicleCamera.new(self)

		if camera:loadFromXML(self.xmlFile, cameraKey) then
			table.insert(spec.toolCameras, camera)
		end
	end)

	spec.isHardAttached = false
	spec.isAdditionalAttachment = false
	spec.texts = {
		liftObject = g_i18n:getText("action_liftOBJECT"),
		lowerObject = g_i18n:getText("action_lowerOBJECT"),
		warningFoldingAttached = g_i18n:getText("warning_foldingNotWhileAttached"),
		warningFoldingLowered = g_i18n:getText("warning_foldingNotWhileLowered"),
		warningFoldingAttacherJoint = g_i18n:getText("warning_foldingNotWhileAttachedToAttacherJoint"),
		lowerImplementFirst = g_i18n:getText("warning_lowerImplementFirst")
	}
end

function Attachable:onPostLoad(savegame)
	local spec = self.spec_attachable

	for _, supportAnimation in ipairs(spec.supportAnimations) do
		if not supportAnimation.delayedOnLoad and self:getIsSupportAnimationAllowed(supportAnimation) then
			self:playAnimation(supportAnimation.animationName, 1, nil, true, false)
			AnimatedVehicle.updateAnimationByName(self, supportAnimation.animationName, 9999999, true)
		end
	end

	if savegame ~= nil and not savegame.resetVehicles then
		if spec.lowerAnimation ~= nil and self.playAnimation ~= nil then
			local lowerAnimTime = savegame.xmlFile:getValue(savegame.key .. ".attachable#lowerAnimTime")

			if lowerAnimTime ~= nil then
				local speed = 1

				if lowerAnimTime < 0.5 then
					speed = -1
				end

				self:playAnimation(spec.lowerAnimation, speed, nil, true, false)
				self:setAnimationTime(spec.lowerAnimation, lowerAnimTime)
				AnimatedVehicle.updateAnimationByName(self, spec.lowerAnimation, 9999999, true)

				if self.updateCylinderedInitial ~= nil then
					self:updateCylinderedInitial(false)
				end
			end
		end
	elseif spec.lowerAnimationDefaultLowered then
		self:playAnimation(spec.lowerAnimation, 1, nil, true, false)
		AnimatedVehicle.updateAnimationByName(self, spec.lowerAnimation, 9999999, true)
	end

	for _, inputAttacherJoint in pairs(spec.inputAttacherJoints) do
		if self.getMovingPartByNode ~= nil then
			if inputAttacherJoint.steeringBarLeftNode ~= nil then
				local movingPart = self:getMovingPartByNode(inputAttacherJoint.steeringBarLeftNode)

				if movingPart ~= nil then
					inputAttacherJoint.steeringBarLeftMovingPart = movingPart
				else
					inputAttacherJoint.steeringBarLeftNode = nil
				end
			end

			if inputAttacherJoint.steeringBarRightNode ~= nil then
				local movingPart = self:getMovingPartByNode(inputAttacherJoint.steeringBarRightNode)

				if movingPart ~= nil then
					inputAttacherJoint.steeringBarRightMovingPart = movingPart
				else
					inputAttacherJoint.steeringBarRightNode = nil
				end
			end
		else
			inputAttacherJoint.steeringBarLeftNode = nil
			inputAttacherJoint.steeringBarRightNode = nil
		end
	end

	if self.brake ~= nil then
		local brakeForce = self:getBrakeForce()

		if brakeForce > 0 then
			self:brake(brakeForce, true)
		end
	end

	spec.updateSteeringAxleAngle = #spec.steeringAngleNodes > 0 or spec.steeringAxleTargetNode ~= nil or self.getWheels ~= nil and #self:getWheels() > 0

	if #spec.inputAttacherJoints > 0 then
		g_currentMission:addAttachableVehicle(self)
	else
		SpecializationUtil.removeEventListener(self, "onUpdate", Attachable)
	end
end

function Attachable:onLoadFinished(savegame)
	local spec = self.spec_attachable

	for _, supportAnimation in ipairs(spec.supportAnimations) do
		if supportAnimation.delayedOnLoad and self:getIsSupportAnimationAllowed(supportAnimation) then
			self:playAnimation(supportAnimation.animationName, 1, nil, true, false)
			AnimatedVehicle.updateAnimationByName(self, supportAnimation.animationName, 9999999, true)
		end
	end
end

function Attachable:onPreDelete()
	local spec = self.spec_attachable

	if spec.attacherVehicle ~= nil then
		spec.attacherVehicle:detachImplementByObject(self, true)
	end

	if spec.inputAttacherJoints ~= nil then
		for i = 1, #spec.inputAttacherJoints do
			local inputAttacherJoint = spec.inputAttacherJoints[i]

			g_currentMission:removeInputAttacherJoint(inputAttacherJoint.jointInfo)
		end
	end

	g_currentMission:removeAttachableVehicle(self)
end

function Attachable:onDelete()
	local spec = self.spec_attachable

	if spec.toolCameras ~= nil then
		for _, camera in ipairs(spec.toolCameras) do
			camera:delete()
		end
	end
end

function Attachable:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_attachable

	if spec.lowerAnimation ~= nil and self.playAnimation ~= nil then
		local lowerAnimTime = self:getAnimationTime(spec.lowerAnimation)

		xmlFile:setValue(key .. "#lowerAnimTime", lowerAnimTime)
	end
end

function Attachable:onReadStream(streamId, connection)
	if streamReadBool(streamId) then
		local object = NetworkUtil.readNodeObject(streamId)
		local inputJointDescIndex = streamReadInt8(streamId)
		local jointDescIndex = streamReadInt8(streamId)
		local moveDown = streamReadBool(streamId)
		local implementIndex = streamReadInt8(streamId)

		if object ~= nil and object:getIsSynchronized() then
			object:attachImplement(self, inputJointDescIndex, jointDescIndex, true, implementIndex, moveDown, true, true)
			object:setJointMoveDown(jointDescIndex, moveDown, true)
		end
	end
end

function Attachable:onWriteStream(streamId, connection)
	local spec = self.spec_attachable

	streamWriteBool(streamId, spec.attacherVehicle ~= nil)

	if spec.attacherVehicle ~= nil then
		local attacherJointVehicleSpec = spec.attacherVehicle.spec_attacherJoints
		local implementIndex = spec.attacherVehicle:getImplementIndexByObject(self)
		local implement = attacherJointVehicleSpec.attachedImplements[implementIndex]
		local inputJointDescIndex = spec.inputAttacherJointDescIndex
		local jointDescIndex = implement.jointDescIndex
		local jointDesc = attacherJointVehicleSpec.attacherJoints[jointDescIndex]
		local moveDown = jointDesc.moveDown

		NetworkUtil.writeNodeObject(streamId, spec.attacherVehicle)
		streamWriteInt8(streamId, inputJointDescIndex)
		streamWriteInt8(streamId, jointDescIndex)
		streamWriteBool(streamId, moveDown)
		streamWriteInt8(streamId, implementIndex)
	end
end

function Attachable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_attachable
	local yRot = nil

	if spec.updateSteeringAxleAngle and (self:getLastSpeed() > 0.25 or not self.finishedFirstUpdate) then
		local steeringAngle = 0
		local baseVehicle = self:getSteeringAxleBaseVehicle()

		if (baseVehicle ~= nil or spec.steeringAxleReferenceComponentNode ~= nil) and (self.movingDirection >= 0 or spec.steeringAxleUpdateBackwards) then
			yRot = Utils.getYRotationBetweenNodes(self.steeringAxleNode, spec.steeringAxleReferenceComponentNode or baseVehicle.steeringAxleNode)
			local scale = 1

			if spec.steeringAxleAngleScaleSpeedDependent then
				local startSpeed = spec.steeringAxleAngleScaleStart
				local endSpeed = spec.steeringAxleAngleScaleEnd
				scale = MathUtil.clamp(1 + (self:getLastSpeed() - startSpeed) * 1 / (startSpeed - endSpeed), 0, 1)
			end

			steeringAngle = yRot * scale
		elseif self:getLastSpeed() > 0.2 then
			steeringAngle = 0
		end

		if not self:getIsSteeringAxleAllowed() then
			steeringAngle = 0
		end

		if spec.steeringAxleDistanceDelay > 0 then
			spec.steeringAxleTargetAngleHistoryMoved = spec.steeringAxleTargetAngleHistoryMoved + self.lastMovedDistance

			if spec.steeringAxleTargetAngleHistoryMoved > 0.1 then
				spec.steeringAxleTargetAngleHistory[spec.steeringAxleTargetAngleHistoryIndex] = steeringAngle
				spec.steeringAxleTargetAngleHistoryIndex = spec.steeringAxleTargetAngleHistoryIndex + 1

				if spec.steeringAxleTargetAngleHistoryIndex > #spec.steeringAxleTargetAngleHistory then
					spec.steeringAxleTargetAngleHistoryIndex = 1
				end
			end

			local lastIndex = spec.steeringAxleTargetAngleHistoryIndex + 1

			if lastIndex > #spec.steeringAxleTargetAngleHistory then
				lastIndex = 1
			end

			spec.steeringAxleTargetAngle = spec.steeringAxleTargetAngleHistory[lastIndex]
		else
			spec.steeringAxleTargetAngle = steeringAngle
		end

		local dir = MathUtil.sign(spec.steeringAxleTargetAngle - spec.steeringAxleAngle)
		local speed = spec.steeringAxleAngleSpeed

		if not self.finishedFirstUpdate then
			speed = 9999
		end

		if dir == 1 then
			spec.steeringAxleAngle = math.min(spec.steeringAxleAngle + dir * dt * speed, spec.steeringAxleTargetAngle)
		else
			spec.steeringAxleAngle = math.max(spec.steeringAxleAngle + dir * dt * speed, spec.steeringAxleTargetAngle)
		end

		if spec.steeringAxleTargetNode ~= nil then
			local angle = nil

			if spec.steeringAxleTargetNodeRefAngle ~= nil then
				local alpha = MathUtil.clamp(spec.steeringAxleAngle / spec.steeringAxleTargetNodeRefAngle, -1, 1)

				if alpha >= 0 then
					angle = spec.steeringAxleAngleMaxRot * alpha
				else
					angle = spec.steeringAxleAngleMinRot * -alpha
				end
			else
				angle = MathUtil.clamp(spec.steeringAxleAngle, spec.steeringAxleAngleMinRot, spec.steeringAxleAngleMaxRot)
			end

			setRotation(spec.steeringAxleTargetNode, 0, angle * spec.steeringAxleDirection, 0)
			self:setMovingToolDirty(spec.steeringAxleTargetNode)
		end
	end

	local numSteeringAngleNodes = #spec.steeringAngleNodes

	if numSteeringAngleNodes > 0 and yRot == nil then
		local baseVehicle = self:getSteeringAxleBaseVehicle()

		if baseVehicle ~= nil then
			yRot = Utils.getYRotationBetweenNodes(self.steeringAxleNode, baseVehicle.steeringAxleNode)
		end
	end

	if yRot ~= nil then
		for i = 1, numSteeringAngleNodes do
			self:updateSteeringAngleNode(spec.steeringAngleNodes[i], yRot, dt)
		end
	end

	local attacherVehicle = self:getAttacherVehicle()

	if spec.detachingInProgress then
		local doDetach = false

		for i = 1, #spec.supportAnimations do
			local animation = spec.supportAnimations[i]

			if animation.detachAfterAnimation then
				if not self:getIsAnimationPlaying(animation.animationName) then
					doDetach = true
				elseif animation.detachAnimationTime < 1 and animation.detachAnimationTime < self:getAnimationTime(animation.animationName) then
					doDetach = true
				end
			end
		end

		if doDetach then
			if attacherVehicle ~= nil then
				attacherVehicle:detachImplementByObject(self)
			end

			spec.detachingInProgress = false
		end
	end

	if attacherVehicle ~= nil and self.currentUpdateDistance < attacherVehicle.spec_attacherJoints.maxUpdateDistance and self.updateLoopIndex == attacherVehicle.updateLoopIndex then
		local implement = attacherVehicle:getImplementByObject(self)

		if implement ~= nil then
			attacherVehicle:updateAttacherJointGraphics(implement, dt, true)
		end
	end
end

function Attachable:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_attachable

	for i = 1, #spec.inputAttacherJoints do
		local inputAttacherJoint = spec.inputAttacherJoints[i]

		g_currentMission:updateInputAttacherJoint(inputAttacherJoint.jointInfo)
	end
end

function Attachable:loadInputAttacherJoint(xmlFile, key, inputAttacherJoint, index)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#index", key .. "#node")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#indexVisual", key .. "#nodeVisual")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#ptoInputNode", "vehicle.powerTakeOffs.input")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#lowerDistanceToGround", key .. ".distanceToGround#lower")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#upperDistanceToGround", key .. ".distanceToGround#upper")

	local node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

	if node ~= nil then
		inputAttacherJoint.node = node
		inputAttacherJoint.heightNodes = {}

		xmlFile:iterate(key .. ".heightNode", function (_, heightNodeKey)
			local heightNode = {}

			if self:loadAttacherJointHeightNode(xmlFile, heightNodeKey, heightNode, node) then
				table.insert(inputAttacherJoint.heightNodes, heightNode)
			end
		end)

		local jointTypeStr = xmlFile:getValue(key .. "#jointType")
		local jointType = nil

		if jointTypeStr ~= nil then
			jointType = AttacherJoints.jointTypeNameToInt[jointTypeStr]

			if jointType == nil then
				Logging.xmlWarning(self.xmlFile, "Invalid jointType '%s' for inputAttacherJoint '%s'!", tostring(jointTypeStr), key)
			end
		else
			Logging.xmlWarning(self.xmlFile, "Missing jointType for inputAttacherJoint '%s'!", key)
		end

		if jointType == nil then
			local needsTrailerJoint = xmlFile:getValue(key .. "#needsTrailerJoint", false)
			local needsLowTrailerJoint = xmlFile:getValue(key .. "#needsLowJoint", false)

			if needsTrailerJoint then
				if needsLowTrailerJoint then
					jointType = AttacherJoints.JOINTTYPE_TRAILERLOW
				else
					jointType = AttacherJoints.JOINTTYPE_TRAILER
				end
			else
				jointType = AttacherJoints.JOINTTYPE_IMPLEMENT
			end
		end

		inputAttacherJoint.jointType = jointType
		local subTypeStr = xmlFile:getValue(key .. ".subType#name")
		inputAttacherJoint.subTypes = string.split(subTypeStr, " ")

		if #inputAttacherJoint.subTypes == 0 then
			inputAttacherJoint.subTypes = nil
		end

		inputAttacherJoint.subTypeShowWarning = xmlFile:getValue(key .. ".subType#showWarning", true)
		inputAttacherJoint.jointOrigTrans = {
			getTranslation(inputAttacherJoint.node)
		}
		inputAttacherJoint.jointOrigOffsetComponent = {
			localToLocal(self:getParentComponent(inputAttacherJoint.node), inputAttacherJoint.node, 0, 0, 0)
		}
		inputAttacherJoint.jointOrigDirOffsetComponent = {
			localDirectionToLocal(self:getParentComponent(inputAttacherJoint.node), inputAttacherJoint.node, 0, 0, 1)
		}
		inputAttacherJoint.topReferenceNode = xmlFile:getValue(key .. "#topReferenceNode", nil, self.components, self.i3dMappings)
		inputAttacherJoint.rootNode = xmlFile:getValue(key .. "#rootNode", self.components[1].node, self.components, self.i3dMappings)
		inputAttacherJoint.rootNodeBackup = inputAttacherJoint.rootNode
		inputAttacherJoint.allowsDetaching = xmlFile:getValue(key .. "#allowsDetaching", true)
		inputAttacherJoint.fixedRotation = xmlFile:getValue(key .. "#fixedRotation", false)
		inputAttacherJoint.hardAttach = xmlFile:getValue(key .. "#hardAttach", false)

		if inputAttacherJoint.hardAttach and #self.components > 1 then
			Logging.xmlWarning(self.xmlFile, "hardAttach only available for single component vehicles! InputAttacherJoint '%s'!", key)

			inputAttacherJoint.hardAttach = false
		end

		inputAttacherJoint.visualNode = xmlFile:getValue(key .. "#nodeVisual", nil, self.components, self.i3dMappings)

		if inputAttacherJoint.hardAttach and inputAttacherJoint.visualNode ~= nil then
			inputAttacherJoint.visualNodeData = {
				parent = getParent(inputAttacherJoint.visualNode),
				translation = {
					getTranslation(inputAttacherJoint.visualNode)
				},
				rotation = {
					getRotation(inputAttacherJoint.visualNode)
				},
				index = getChildIndex(inputAttacherJoint.visualNode)
			}
		end

		if jointType == AttacherJoints.JOINTTYPE_IMPLEMENT or jointType == AttacherJoints.JOINTTYPE_CUTTER or jointType == AttacherJoints.JOINTTYPE_CUTTERHARVESTER then
			if xmlFile:getValue(key .. ".distanceToGround#lower") == nil then
				Logging.xmlWarning(self.xmlFile, "Missing '.distanceToGround#lower' for inputAttacherJoint '%s'!", key)
			end

			if xmlFile:getValue(key .. ".distanceToGround#upper") == nil then
				Logging.xmlWarning(self.xmlFile, "Missing '.distanceToGround#upper' for inputAttacherJoint '%s'!", key)
			end
		end

		inputAttacherJoint.lowerDistanceToGround = xmlFile:getValue(key .. ".distanceToGround#lower", 0.7)
		inputAttacherJoint.upperDistanceToGround = xmlFile:getValue(key .. ".distanceToGround#upper", 1)

		if inputAttacherJoint.upperDistanceToGround < inputAttacherJoint.lowerDistanceToGround then
			Logging.xmlWarning(self.xmlFile, "distanceToGround#lower may not be larger than distanceToGround#upper for inputAttacherJoint '%s'. Switching values!", key)

			local copy = inputAttacherJoint.lowerDistanceToGround
			inputAttacherJoint.lowerDistanceToGround = inputAttacherJoint.upperDistanceToGround
			inputAttacherJoint.upperDistanceToGround = copy
		end

		inputAttacherJoint.distanceToGroundByVehicle = {}

		xmlFile:iterate(key .. ".distanceToGround.vehicle", function (_, vehicleKey)
			local entry = {
				filename = xmlFile:getValue(vehicleKey .. "#filename")
			}

			if entry.filename ~= nil then
				entry.filename = entry.filename:lower()
				entry.lower = xmlFile:getValue(vehicleKey .. "#lower", inputAttacherJoint.lowerDistanceToGround)
				entry.upper = xmlFile:getValue(vehicleKey .. "#upper", inputAttacherJoint.upperDistanceToGround)

				table.insert(inputAttacherJoint.distanceToGroundByVehicle, entry)
			end
		end)

		inputAttacherJoint.lowerDistanceToGroundOriginal = inputAttacherJoint.lowerDistanceToGround
		inputAttacherJoint.upperDistanceToGroundOriginal = inputAttacherJoint.upperDistanceToGround
		inputAttacherJoint.lowerRotationOffset = xmlFile:getValue(key .. "#lowerRotationOffset", 0)
		local defaultUpperRotationOffset = 8

		if jointType == AttacherJoints.JOINTTYPE_CUTTER or jointType == AttacherJoints.JOINTTYPE_CUTTERHARVESTER or jointType == AttacherJoints.JOINTTYPE_WHEELLOADER or jointType == AttacherJoints.JOINTTYPE_TELEHANDLER or jointType == AttacherJoints.JOINTTYPE_FRONTLOADER or jointType == AttacherJoints.JOINTTYPE_LOADERFORK then
			defaultUpperRotationOffset = 0
		end

		inputAttacherJoint.upperRotationOffset = xmlFile:getValue(key .. "#upperRotationOffset", defaultUpperRotationOffset)
		inputAttacherJoint.allowsJointRotLimitMovement = xmlFile:getValue(key .. "#allowsJointRotLimitMovement", true)
		inputAttacherJoint.allowsJointTransLimitMovement = xmlFile:getValue(key .. "#allowsJointTransLimitMovement", true)
		inputAttacherJoint.needsToolbar = xmlFile:getValue(key .. "#needsToolbar", false)

		if inputAttacherJoint.needsToolbar and jointType ~= AttacherJoints.JOINTTYPE_IMPLEMENT then
			Logging.xmlWarning(self.xmlFile, "'needsToolbar' requires jointType 'implement' for inputAttacherJoint '%s'!", key)

			inputAttacherJoint.needsToolbar = false
		end

		inputAttacherJoint.steeringBarLeftNode = xmlFile:getValue(key .. "#steeringBarLeftNode", nil, self.components, self.i3dMappings)
		inputAttacherJoint.steeringBarRightNode = xmlFile:getValue(key .. "#steeringBarRightNode", nil, self.components, self.i3dMappings)
		inputAttacherJoint.upperRotLimitScale = xmlFile:getValue(key .. "#upperRotLimitScale", "0 0 0", true)
		local x, y, z = xmlFile:getValue(key .. "#lowerRotLimitScale")

		if jointType == AttacherJoints.JOINTTYPE_IMPLEMENT then
			inputAttacherJoint.lowerRotLimitScale = {
				Utils.getNoNil(x, 0),
				Utils.getNoNil(y, 0),
				Utils.getNoNil(z, 1)
			}
		else
			inputAttacherJoint.lowerRotLimitScale = {
				Utils.getNoNil(x, 1),
				Utils.getNoNil(y, 1),
				Utils.getNoNil(z, 1)
			}
		end

		inputAttacherJoint.rotLimitThreshold = xmlFile:getValue(key .. "#rotLimitThreshold", 0)
		inputAttacherJoint.upperTransLimitScale = xmlFile:getValue(key .. "#upperTransLimitScale", "0 0 0", true)
		inputAttacherJoint.lowerTransLimitScale = xmlFile:getValue(key .. "#lowerTransLimitScale", "0 1 0", true)
		inputAttacherJoint.transLimitThreshold = xmlFile:getValue(key .. "#transLimitThreshold", 0)
		inputAttacherJoint.rotLimitSpring = xmlFile:getValue(key .. "#rotLimitSpring", "0 0 0", true)
		inputAttacherJoint.rotLimitDamping = xmlFile:getValue(key .. "#rotLimitDamping", "1 1 1", true)
		inputAttacherJoint.rotLimitForceLimit = xmlFile:getValue(key .. "#rotLimitForceLimit", "-1 -1 -1", true)
		inputAttacherJoint.transLimitSpring = xmlFile:getValue(key .. "#transLimitSpring", "0 0 0", true)
		inputAttacherJoint.transLimitDamping = xmlFile:getValue(key .. "#transLimitDamping", "1 1 1", true)
		inputAttacherJoint.transLimitForceLimit = xmlFile:getValue(key .. "#transLimitForceLimit", "-1 -1 -1", true)
		inputAttacherJoint.attachAngleLimitAxis = xmlFile:getValue(key .. "#attachAngleLimitAxis", 1)
		inputAttacherJoint.attacherHeight = xmlFile:getValue(key .. "#attacherHeight")

		if inputAttacherJoint.attacherHeight == nil then
			if jointType == AttacherJoints.JOINTTYPE_TRAILER then
				inputAttacherJoint.attacherHeight = 0.9
			elseif jointType == AttacherJoints.JOINTTYPE_TRAILERLOW then
				inputAttacherJoint.attacherHeight = 0.55
			end
		end

		local defaultNeedsLowering = true
		local defaultAllowsLowering = false

		if inputAttacherJoint.jointType == AttacherJoints.JOINTTYPE_TRAILER or inputAttacherJoint.jointType == AttacherJoints.JOINTTYPE_TRAILERLOW then
			defaultNeedsLowering = false
		end

		if inputAttacherJoint.jointType ~= AttacherJoints.JOINTTYPE_TRAILER and inputAttacherJoint.jointType ~= AttacherJoints.JOINTTYPE_TRAILERLOW then
			defaultAllowsLowering = true
		end

		inputAttacherJoint.needsLowering = xmlFile:getValue(key .. "#needsLowering", defaultNeedsLowering)
		inputAttacherJoint.allowsLowering = xmlFile:getValue(key .. "#allowsLowering", defaultAllowsLowering)
		inputAttacherJoint.isDefaultLowered = xmlFile:getValue(key .. "#isDefaultLowered", false)
		inputAttacherJoint.useFoldingLoweredState = xmlFile:getValue(key .. "#useFoldingLoweredState", false)
		inputAttacherJoint.forceSelection = xmlFile:getValue(key .. "#forceSelectionOnAttach", true)
		inputAttacherJoint.forceAllowDetachWhileLifted = xmlFile:getValue(key .. "#forceAllowDetachWhileLifted", false)
		inputAttacherJoint.forcedAttachingDirection = xmlFile:getValue(key .. "#forcedAttachingDirection", 0)
		inputAttacherJoint.allowFolding = xmlFile:getValue(key .. "#allowFolding", true)
		inputAttacherJoint.allowTurnOn = xmlFile:getValue(key .. "#allowTurnOn", true)
		inputAttacherJoint.allowAI = xmlFile:getValue(key .. "#allowAI", true)
		inputAttacherJoint.allowDetachWhileParentLifted = xmlFile:getValue(key .. "#allowDetachWhileParentLifted", true)
		inputAttacherJoint.dependentAttacherJoints = {}
		local k = 0

		while true do
			local dependentKey = string.format(key .. ".dependentAttacherJoint(%d)", k)

			if not xmlFile:hasProperty(dependentKey) then
				break
			end

			local attacherJointIndex = xmlFile:getValue(dependentKey .. "#attacherJointIndex")

			if attacherJointIndex ~= nil then
				table.insert(inputAttacherJoint.dependentAttacherJoints, attacherJointIndex)
			end

			k = k + 1
		end

		if inputAttacherJoint.hardAttach then
			inputAttacherJoint.needsLowering = false
			inputAttacherJoint.allowsLowering = false
			inputAttacherJoint.isDefaultLowered = false
			inputAttacherJoint.upperRotationOffset = 0
		end

		inputAttacherJoint.changeObjects = {}

		ObjectChangeUtil.loadObjectChangeFromXML(xmlFile, key, inputAttacherJoint.changeObjects, self.components, self)

		inputAttacherJoint.additionalObjects = {}
		local i = 0

		while true do
			local baseKey = string.format("%s.additionalObjects.additionalObject(%d)", key, i)

			if not xmlFile:hasProperty(baseKey) then
				break
			end

			local entry = {
				node = xmlFile:getValue(baseKey .. "#node", nil, self.components, self.i3dMappings),
				attacherVehiclePath = xmlFile:getValue(baseKey .. "#attacherVehiclePath")
			}

			if entry.node ~= nil and entry.attacherVehiclePath ~= nil then
				entry.attacherVehiclePath = NetworkUtil.convertToNetworkFilename(entry.attacherVehiclePath)

				table.insert(inputAttacherJoint.additionalObjects, entry)
			end

			i = i + 1
		end

		inputAttacherJoint.additionalAttachment = {}
		local filename = xmlFile:getValue(key .. ".additionalAttachment#filename")

		if filename ~= nil then
			inputAttacherJoint.additionalAttachment.filename = Utils.getFilename(filename, self.customEnvironment)
		end

		inputAttacherJoint.additionalAttachment.inputAttacherJointIndex = xmlFile:getValue(key .. ".additionalAttachment#inputAttacherJointIndex", 1)
		inputAttacherJoint.additionalAttachment.needsLowering = xmlFile:getValue(key .. ".additionalAttachment#needsLowering", false)
		local additionalJointTypeStr = xmlFile:getValue(key .. ".additionalAttachment#jointType")
		local additionalJointType = nil

		if additionalJointTypeStr ~= nil then
			additionalJointType = AttacherJoints.jointTypeNameToInt[additionalJointTypeStr]

			if additionalJointType == nil then
				Logging.xmlWarning(self.xmlFile, "Invalid jointType '%s' for additonal implement '%s'!", tostring(additionalJointTypeStr), inputAttacherJoint.additionalAttachment.filename)
			end
		end

		inputAttacherJoint.additionalAttachment.jointType = additionalJointType or AttacherJoints.JOINTTYPE_IMPLEMENT

		return true
	end

	return false
end

function Attachable:loadAttacherJointHeightNode(xmlFile, key, heightNode, attacherJointNode)
	heightNode.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	heightNode.attacherJointNode = attacherJointNode

	return true
end

function Attachable:getIsAttacherJointHeightNodeActive(heightNode)
	return true
end

function Attachable:getInputAttacherJointByJointDescIndex(index)
	return self.spec_attachable.inputAttacherJoints[index]
end

function Attachable:getAttacherVehicle()
	return self.spec_attachable.attacherVehicle
end

function Attachable:getInputAttacherJoints()
	return self.spec_attachable.inputAttacherJoints
end

function Attachable:getIsAttachedTo(vehicle)
	if vehicle == self then
		return true
	end

	local spec = self.spec_attachable

	if spec.attacherVehicle ~= nil then
		if spec.attacherVehicle == vehicle then
			return true
		end

		if spec.attacherVehicle.getIsAttachedTo ~= nil then
			return spec.attacherVehicle:getIsAttachedTo(vehicle)
		end
	end

	return false
end

function Attachable:getActiveInputAttacherJointDescIndex()
	return self.spec_attachable.inputAttacherJointDescIndex
end

function Attachable:getActiveInputAttacherJoint()
	return self.spec_attachable.attacherJoint
end

function Attachable:getAllowsLowering()
	local spec = self.spec_attachable

	if spec.isAdditionalAttachment and not spec.additionalAttachmentNeedsLowering then
		return false, nil
	end

	local inputAttacherJoint = self:getActiveInputAttacherJoint()

	if inputAttacherJoint ~= nil and not inputAttacherJoint.allowsLowering then
		return false, nil
	end

	return true, nil
end

function Attachable:loadSupportAnimationFromXML(supportAnimation, xmlFile, key)
	supportAnimation.animationName = xmlFile:getValue(key .. "#animationName")
	supportAnimation.delayedOnLoad = xmlFile:getValue(key .. "#delayedOnLoad", false)
	supportAnimation.delayedOnAttach = xmlFile:getValue(key .. "#delayedOnAttach", true)
	supportAnimation.detachAfterAnimation = xmlFile:getValue(key .. "#detachAfterAnimation", true)
	supportAnimation.detachAnimationTime = xmlFile:getValue(key .. "#detachAnimationTime", 1)

	return supportAnimation.animationName ~= nil
end

function Attachable:getIsSupportAnimationAllowed(supportAnimation)
	return self.playAnimation ~= nil
end

function Attachable:startDetachProcess()
	local spec = self.spec_attachable
	local playedAnimation = false

	for i = 1, #spec.supportAnimations do
		if spec.supportAnimations[i].detachAfterAnimation and self:getIsSupportAnimationAllowed(spec.supportAnimations[i]) then
			self:playAnimation(spec.supportAnimations[i].animationName, 1, nil, true)

			playedAnimation = true
		end
	end

	spec.detachingInProgress = playedAnimation

	if not playedAnimation then
		local attacherVehicle = self:getAttacherVehicle()

		if attacherVehicle ~= nil then
			attacherVehicle:detachImplementByObject(self)
		end
	end

	return playedAnimation
end

function Attachable:getIsImplementChainLowered(defaultIsLowered)
	if not self:getIsLowered(defaultIsLowered) then
		return false
	end

	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil and attacherVehicle.getAllowsLowering ~= nil and attacherVehicle:getAllowsLowering() and not attacherVehicle:getIsImplementChainLowered(defaultIsLowered) then
		return false
	end

	return true
end

function Attachable:getIsInWorkPosition()
	return true
end

function Attachable:getAttachbleAirConsumerUsage()
	return self.spec_attachable.airConsumerUsage
end

function Attachable:isDetachAllowed()
	local spec = self.spec_attachable

	if spec.attacherJoint ~= nil then
		if spec.attacherJoint.allowsDetaching == false then
			return false, nil, false
		end

		if spec.attacherJoint.allowDetachWhileParentLifted == false then
			local attacherVehicle = self:getAttacherVehicle()

			if attacherVehicle ~= nil and attacherVehicle.getIsLowered ~= nil and not attacherVehicle:getIsLowered(true) then
				return false, string.format(spec.texts.lowerImplementFirst, attacherVehicle.typeDesc), true
			end
		end
	end

	if spec.isAdditionalAttachment then
		return false
	end

	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		local implement = attacherVehicle:getImplementByObject(self)

		if implement ~= nil and implement.attachingIsInProgress then
			return false
		end
	end

	return true, nil
end

function Attachable:isAttachAllowed(farmId, attacherVehicle)
	if not g_currentMission.accessHandler:canFarmAccess(farmId, self) then
		return false, nil
	end

	return true, nil
end

function Attachable:getIsInputAttacherActive(inputAttacherJoint)
	return true
end

function Attachable:getSteeringAxleBaseVehicle()
	local spec = self.spec_attachable

	if spec.steeringAxleUseSuperAttachable and spec.attacherVehicle ~= nil and spec.attacherVehicle.getAttacherVehicle ~= nil then
		return spec.attacherVehicle:getAttacherVehicle()
	end

	if spec.attacherVehicle ~= nil and (spec.steeringAxleForceUsage or spec.attacherVehicle:getCanSteerAttachable(self)) then
		return spec.attacherVehicle
	end

	return nil
end

function Attachable:loadSteeringAxleFromXML(spec, xmlFile, key)
	spec.steeringAxleAngleScaleStart = xmlFile:getValue(key .. "#startSpeed", 10)
	spec.steeringAxleAngleScaleEnd = xmlFile:getValue(key .. "#endSpeed", 30)
	spec.steeringAxleAngleScaleSpeedDependent = xmlFile:getValue(key .. "#speedDependent", true)
	spec.steeringAxleUpdateBackwards = xmlFile:getValue(key .. "#backwards", false)
	spec.steeringAxleAngleSpeed = xmlFile:getValue(key .. "#speed", 0.001)
	spec.steeringAxleUseSuperAttachable = xmlFile:getValue(key .. "#useSuperAttachable", false)
	spec.steeringAxleTargetNode = xmlFile:getValue(key .. ".targetNode#node", nil, self.components, self.i3dMappings)
	spec.steeringAxleTargetNodeRefAngle = xmlFile:getValue(key .. ".targetNode#refAngle")
	spec.steeringAxleAngleMinRot = xmlFile:getValue(key .. "#minRot", 0)
	spec.steeringAxleAngleMaxRot = xmlFile:getValue(key .. "#maxRot", 0)
	spec.steeringAxleDirection = xmlFile:getValue(key .. "#direction", 1)
	spec.steeringAxleForceUsage = xmlFile:getValue(key .. "#forceUsage", spec.steeringAxleTargetNode ~= nil)
	spec.steeringAxleDistanceDelay = xmlFile:getValue(key .. "#distanceDelay", 0)
	local referenceComponentIndex = xmlFile:getValue(key .. "#referenceComponentIndex")

	if referenceComponentIndex ~= nil then
		local component = self.components[referenceComponentIndex]

		if component ~= nil then
			spec.steeringAxleReferenceComponentNode = component.node
		end
	end
end

function Attachable:getIsSteeringAxleAllowed()
	return true
end

function Attachable:loadSteeringAngleNodeFromXML(entry, xmlFile, key)
	entry.node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	entry.speed = xmlFile:getValue(key .. "#speed", 25) / 1000
	entry.scale = xmlFile:getValue(key .. "#scale", 1)
	entry.currentAngle = 0

	return true
end

function Attachable:updateSteeringAngleNode(steeringAngleNode, angle, dt)
	local direction = MathUtil.sign(angle - steeringAngleNode.currentAngle)
	local limit = direction < 0 and math.max or math.min
	local newAngle = limit(steeringAngleNode.currentAngle + steeringAngleNode.speed * dt * direction, angle)

	if newAngle ~= steeringAngleNode.currentAngle then
		steeringAngleNode.currentAngle = newAngle

		setRotation(steeringAngleNode.node, 0, steeringAngleNode.currentAngle * steeringAngleNode.scale, 0)
	end
end

function Attachable:attachableAddToolCameras()
	local spec = self.spec_attachable

	if #spec.toolCameras > 0 then
		local rootAttacherVehicle = self.rootVehicle

		if rootAttacherVehicle ~= nil and rootAttacherVehicle.addToolCameras ~= nil then
			rootAttacherVehicle:addToolCameras(spec.toolCameras)
		end
	end
end

function Attachable:attachableRemoveToolCameras()
	local spec = self.spec_attachable

	if #spec.toolCameras > 0 then
		local rootAttacherVehicle = self.rootVehicle

		if rootAttacherVehicle ~= nil and rootAttacherVehicle.removeToolCameras ~= nil then
			rootAttacherVehicle:removeToolCameras(spec.toolCameras)
		end
	end
end

function Attachable:preAttach(attacherVehicle, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local spec = self.spec_attachable
	spec.attacherVehicle = attacherVehicle
	spec.attacherJoint = spec.inputAttacherJoints[inputJointDescIndex]
	spec.inputAttacherJointDescIndex = inputJointDescIndex
	local distanceToGroundByVehicle = spec.attacherJoint.distanceToGroundByVehicle

	if #spec.attacherJoint.distanceToGroundByVehicle > 0 then
		local useDefault = true

		for i = 1, #distanceToGroundByVehicle do
			local vehicleData = distanceToGroundByVehicle[i]

			if attacherVehicle.configFileName:lower():endsWith(vehicleData.filename) then
				spec.attacherJoint.lowerDistanceToGround = vehicleData.lower
				spec.attacherJoint.upperDistanceToGround = vehicleData.upper
				useDefault = false
			end
		end

		if useDefault then
			spec.attacherJoint.lowerDistanceToGround = spec.attacherJoint.lowerDistanceToGroundOriginal
			spec.attacherJoint.upperDistanceToGround = spec.attacherJoint.upperDistanceToGroundOriginal
		end
	end

	for _, additionalObject in ipairs(spec.attacherJoint.additionalObjects) do
		setVisibility(additionalObject.node, additionalObject.attacherVehiclePath == NetworkUtil.convertToNetworkFilename(attacherVehicle.configFileName))
	end

	for _, supportAnimation in ipairs(spec.supportAnimations) do
		if self:getIsSupportAnimationAllowed(supportAnimation) and not supportAnimation.delayedOnAttach then
			local skipAnimation = self.propertyState == Vehicle.PROPERTY_STATE_SHOP_CONFIG or loadFromSavegame

			self:playAnimation(supportAnimation.animationName, -1, nil, true, not skipAnimation)

			if skipAnimation then
				AnimatedVehicle.updateAnimationByName(self, supportAnimation.animationName, 9999999, true)
			end
		end
	end

	SpecializationUtil.raiseEvent(self, "onPreAttach", attacherVehicle, inputJointDescIndex, jointDescIndex)
end

function Attachable:postAttach(attacherVehicle, inputJointDescIndex, jointDescIndex, loadFromSavegame)
	local spec = self.spec_attachable
	local rootVehicle = self.rootVehicle

	if rootVehicle ~= nil and rootVehicle.getIsControlled ~= nil and rootVehicle:getIsControlled() then
		self:activate()
	end

	if self.setLightsTypesMask ~= nil then
		local lightsSpecAttacherVehicle = attacherVehicle.spec_lights

		if lightsSpecAttacherVehicle ~= nil then
			self:setLightsTypesMask(lightsSpecAttacherVehicle.lightsTypesMask, true, true)
			self:setBeaconLightsVisibility(lightsSpecAttacherVehicle.beaconLightsActive, true, true)
			self:setTurnLightState(lightsSpecAttacherVehicle.turnLightState, true, true)
		end
	end

	spec.attachTime = g_currentMission.time

	for _, supportAnimation in ipairs(spec.supportAnimations) do
		if self:getIsSupportAnimationAllowed(supportAnimation) and supportAnimation.delayedOnAttach then
			local skipAnimation = self.propertyState == Vehicle.PROPERTY_STATE_SHOP_CONFIG or loadFromSavegame

			self:playAnimation(supportAnimation.animationName, -1, nil, true, not skipAnimation)

			if skipAnimation then
				AnimatedVehicle.updateAnimationByName(self, supportAnimation.animationName, 9999999, true)
			end
		end
	end

	self:attachableAddToolCameras()
	ObjectChangeUtil.setObjectChanges(spec.attacherJoint.changeObjects, true, self, self.setMovingToolDirty)

	local jointDesc = attacherVehicle:getAttacherJointByJointDescIndex(jointDescIndex)

	if jointDesc.steeringBarLeftNode ~= nil and spec.attacherJoint.steeringBarLeftMovingPart ~= nil then
		for _, movingPart in pairs(self.spec_cylindered.movingParts) do
			if movingPart.referencePoint == spec.attacherJoint.steeringBarLeftMovingPart.referencePoint and movingPart ~= spec.attacherJoint.steeringBarLeftMovingPart then
				movingPart.referencePoint = jointDesc.steeringBarLeftNode
			end
		end

		spec.attacherJoint.steeringBarLeftMovingPart.referencePoint = jointDesc.steeringBarLeftNode
	end

	if jointDesc.steeringBarRightNode ~= nil and spec.attacherJoint.steeringBarRightMovingPart ~= nil then
		for _, movingPart in pairs(self.spec_cylindered.movingParts) do
			if movingPart.referencePoint == spec.attacherJoint.steeringBarRightMovingPart.referencePoint and movingPart ~= spec.attacherJoint.steeringBarRightMovingPart then
				movingPart.referencePoint = jointDesc.steeringBarRightNode
			end
		end

		spec.attacherJoint.steeringBarRightMovingPart.referencePoint = jointDesc.steeringBarRightNode
	end

	local actionController = self.rootVehicle.actionController

	if actionController ~= nil then
		local inputJointDesc = self:getActiveInputAttacherJoint()

		if inputJointDesc ~= nil and inputJointDesc.needsLowering and inputJointDesc.allowsLowering and jointDesc.allowsLowering then
			spec.controlledAction = actionController:registerAction("lower", InputAction.LOWER_IMPLEMENT, 2)

			spec.controlledAction:setCallback(self, Attachable.actionControllerLowerImplementEvent)
			spec.controlledAction:setFinishedFunctions(self, self.getIsLowered, true, false)
			spec.controlledAction:setIsSaved(true)

			if self:getAINeedsLowering() then
				spec.controlledAction:addAIEventListener(self, "onAIImplementStartLine", 1)
				spec.controlledAction:addAIEventListener(self, "onAIImplementEndLine", -1)
				spec.controlledAction:addAIEventListener(self, "onAIImplementPrepare", -1)
			end
		end
	end

	SpecializationUtil.raiseEvent(self, "onPostAttach", attacherVehicle, inputJointDescIndex, jointDescIndex, loadFromSavegame)
end

function Attachable:preDetach(attacherVehicle, implement)
	local spec = self.spec_attachable

	if spec.controlledAction ~= nil then
		spec.controlledAction:remove()
	end

	SpecializationUtil.raiseEvent(self, "onPreDetach", attacherVehicle, implement)
end

function Attachable:postDetach(implementIndex)
	local spec = self.spec_attachable

	self:deactivate()
	ObjectChangeUtil.setObjectChanges(spec.attacherJoint.changeObjects, false, self, self.setMovingToolDirty)

	if self.playAnimation ~= nil then
		for _, supportAnimation in ipairs(spec.supportAnimations) do
			if self:getIsSupportAnimationAllowed(supportAnimation) then
				if not supportAnimation.detachAfterAnimation then
					self:playAnimation(supportAnimation.animationName, 1, nil, true)
				elseif self:getAnimationTime(supportAnimation.animationName) < 1 then
					self:playAnimation(supportAnimation.animationName, 1, nil, true)
				end
			end
		end

		if spec.lowerAnimation ~= nil and spec.lowerAnimationDirectionOnDetach ~= 0 then
			self:playAnimation(spec.lowerAnimation, spec.lowerAnimationDirectionOnDetach, nil, true)
		end
	end

	self:attachableRemoveToolCameras()

	for _, additionalObject in ipairs(spec.attacherJoint.additionalObjects) do
		setVisibility(additionalObject.node, false)
	end

	spec.attacherVehicle = nil
	spec.attacherJoint = nil
	spec.attacherJointIndex = nil
	spec.inputAttacherJointDescIndex = nil

	SpecializationUtil.raiseEvent(self, "onPostDetach")
end

function Attachable:setLowered(lowered)
	local spec = self.spec_attachable

	if spec.lowerAnimation ~= nil and self.playAnimation ~= nil then
		if lowered then
			self:playAnimation(spec.lowerAnimation, spec.lowerAnimationSpeed, self:getAnimationTime(spec.lowerAnimation), true)
		else
			self:playAnimation(spec.lowerAnimation, -spec.lowerAnimationSpeed, self:getAnimationTime(spec.lowerAnimation), true)
		end
	end

	if spec.attacherJoint ~= nil then
		for _, dependentAttacherJointIndex in pairs(spec.attacherJoint.dependentAttacherJoints) do
			if self.getAttacherJoints ~= nil then
				local attacherJoints = self:getAttacherJoints()

				if attacherJoints[dependentAttacherJointIndex] ~= nil then
					self:setJointMoveDown(dependentAttacherJointIndex, lowered, true)
				else
					Logging.xmlWarning(self.xmlFile, "Failed to lower dependent attacher joint index '%d', No attacher joint defined!", dependentAttacherJointIndex)
				end
			else
				Logging.xmlWarning(self.xmlFile, "Failed to lower dependent attacher joint index '%d', AttacherJoint specialization is missing!", dependentAttacherJointIndex)
			end
		end
	end

	SpecializationUtil.raiseEvent(self, "onSetLowered", lowered)
end

function Attachable:setLoweredAll(doLowering, jointDescIndex)
	self:getAttacherVehicle():handleLowerImplementByAttacherJointIndex(jointDescIndex, doLowering)
	SpecializationUtil.raiseEvent(self, "onSetLoweredAll", doLowering, jointDescIndex)
end

function Attachable:setIsAdditionalAttachment(needsLowering, vehicleLoaded)
	local spec = self.spec_attachable
	spec.isAdditionalAttachment = true
	spec.additionalAttachmentNeedsLowering = needsLowering

	if vehicleLoaded then
		self:requestActionEventUpdate()

		if not needsLowering and spec.controlledAction ~= nil then
			spec.controlledAction:remove()
		end
	end
end

function Attachable:getIsAdditionalAttachment()
	return self.spec_attachable.isAdditionalAttachment
end

function Attachable:setIsSupportVehicle(state)
	local spec = self.spec_attachable

	if state == nil then
		state = true
	end

	spec.isSupportVehicle = state
end

function Attachable:getIsSupportVehicle()
	return self.spec_attachable.isSupportVehicle
end

function Attachable:registerLoweringActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
	self:addPoweredActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
end

function Attachable:getLoweringActionEventState()
	local showLower = false
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		local jointDesc = attacherVehicle:getAttacherJointDescFromObject(self)
		local inputJointDesc = self:getActiveInputAttacherJoint()
		showLower = jointDesc.allowsLowering and inputJointDesc.allowsLowering
	end

	local spec = self.spec_attachable
	local text = nil

	if self:getIsLowered() then
		text = string.format(spec.texts.liftObject, self.typeDesc)
	else
		text = string.format(spec.texts.lowerObject, self.typeDesc)
	end

	return showLower, text
end

function Attachable:getAllowMultipleAttachments()
	return false
end

function Attachable:resolveMultipleAttachments()
end

function Attachable:getBlockFoliageDestruction()
	return self.spec_attachable.blockFoliageDestruction
end

function Attachable:onDeactivate()
	if self.brake ~= nil then
		local brakeForce = self:getBrakeForce()

		if brakeForce > 0 then
			self:brake(brakeForce, true)
		end
	end
end

function Attachable:onSelect(subSelectionIndex)
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		attacherVehicle:setSelectedImplementByObject(self)
	end
end

function Attachable:onUnselect()
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		attacherVehicle:setSelectedImplementByObject(nil)
	end
end

function Attachable:findRootVehicle(superFunc)
	local spec = self.spec_attachable

	if spec.attacherVehicle ~= nil then
		return spec.attacherVehicle:findRootVehicle()
	end

	return superFunc(self)
end

function Attachable:getIsActive(superFunc)
	if superFunc(self) then
		return true
	end

	local spec = self.spec_attachable

	if spec.attacherVehicle ~= nil then
		return spec.attacherVehicle:getIsActive()
	end

	return false
end

function Attachable:getIsOperating(superFunc)
	local spec = self.spec_attachable
	local isOperating = superFunc(self)

	if not isOperating and spec.attacherVehicle ~= nil then
		isOperating = spec.attacherVehicle:getIsOperating()
	end

	return isOperating
end

function Attachable:getBrakeForce(superFunc)
	local superBrakeForce = superFunc(self)
	local spec = self.spec_attachable
	local brakeForce = spec.brakeForce

	if spec.maxBrakeForceMass > 0 then
		local mass = self:getTotalMass(true)
		local percentage = math.min(math.max((mass - self.defaultMass) / (spec.maxBrakeForceMass - self.defaultMass), 0), 1)
		brakeForce = MathUtil.lerp(spec.brakeForce, spec.maxBrakeForce, percentage)
	end

	if spec.loweredBrakeForce >= 0 and self:getIsLowered(false) then
		brakeForce = spec.loweredBrakeForce
	end

	return math.max(superBrakeForce, brakeForce)
end

function Attachable:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_attachable

	if not spec.allowFoldingWhileAttached and self:getAttacherVehicle() ~= nil then
		return false, spec.texts.warningFoldingAttached
	end

	if not spec.allowFoldingWhileLowered and self:getIsLowered() then
		return false, spec.texts.warningFoldingLowered
	end

	if spec.attacherJoint ~= nil and not spec.attacherJoint.allowFolding then
		return false, spec.texts.warningFoldingAttacherJoint
	end

	return superFunc(self)
end

function Attachable:getCanToggleTurnedOn(superFunc)
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		local jointDesc = attacherVehicle:getAttacherJointDescFromObject(self)

		if jointDesc ~= nil and not jointDesc.canTurnOnImplement then
			return false
		end
	end

	local spec = self.spec_attachable

	if spec.attacherJoint ~= nil and not spec.attacherJoint.allowTurnOn then
		return false
	end

	return superFunc(self)
end

function Attachable:getCanImplementBeUsedForAI(superFunc)
	local spec = self.spec_attachable

	if spec.attacherJoint ~= nil and not spec.attacherJoint.allowAI then
		return false
	end

	if spec.detachingInProgress then
		return false
	end

	return superFunc(self)
end

function Attachable:getDeactivateOnLeave(superFunc)
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil and not attacherVehicle:getDeactivateOnLeave() then
		return false
	end

	return superFunc(self)
end

function Attachable:getCanAIImplementContinueWork(superFunc)
	local canContinue, stopAI, stopReason = superFunc(self)

	if not canContinue then
		return false, stopAI, stopReason
	end

	local spec = self.spec_attachable
	local isReady = true

	if spec.lowerAnimation ~= nil then
		local time = self:getAnimationTime(spec.lowerAnimation)
		isReady = time == 1 or time == 0
	end

	local jointDesc = spec.attacherVehicle:getAttacherJointDescFromObject(self)

	if jointDesc.allowsLowering and self:getAINeedsLowering() and jointDesc.moveDown and jointDesc.moveAlpha ~= jointDesc.lowerAlpha then
		isReady = jointDesc.moveAlpha == jointDesc.upperAlpha and isReady
	end

	return isReady
end

function Attachable:getActiveFarm(superFunc)
	local spec = self.spec_attachable

	if self.spec_enterable ~= nil and self.spec_enterable.controllerFarmId ~= 0 then
		return superFunc(self)
	end

	if spec.attacherVehicle ~= nil then
		return spec.attacherVehicle:getActiveFarm()
	else
		return superFunc(self)
	end
end

function Attachable:getCanBeSelected(superFunc)
	return true
end

function Attachable:getIsLowered(superFunc, defaultIsLowered)
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		local jointDesc = attacherVehicle:getAttacherJointDescFromObject(self)

		if jointDesc ~= nil then
			if jointDesc.allowsLowering or jointDesc.isDefaultLowered then
				return jointDesc.moveDown
			else
				return defaultIsLowered
			end
		end
	end

	return superFunc(self, defaultIsLowered)
end

function Attachable:mountDynamic(superFunc, object, objectActorId, jointNode, mountType, forceAcceleration)
	local spec = self.spec_attachable

	if spec.attacherVehicle ~= nil then
		return false
	end

	return superFunc(self, object, objectActorId, jointNode, mountType, forceAcceleration)
end

function Attachable:getOwner(superFunc)
	local spec = self.spec_attachable

	if spec.attacherVehicle ~= nil then
		return spec.attacherVehicle:getOwner()
	end

	return superFunc(self)
end

function Attachable:getIsInUse(superFunc, connection)
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		return attacherVehicle:getIsInUse(connection)
	end

	return superFunc(self, connection)
end

function Attachable:getUpdatePriority(superFunc, skipCount, x, y, z, coeff, connection)
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		return attacherVehicle:getUpdatePriority(skipCount, x, y, z, coeff, connection)
	end

	return superFunc(self, skipCount, x, y, z, coeff, connection)
end

function Attachable:getCanBeReset(superFunc)
	if self:getIsAdditionalAttachment() then
		return false
	end

	if self:getIsSupportVehicle() then
		return false
	end

	return superFunc(self)
end

function Attachable:loadAdditionalLightAttributesFromXML(superFunc, xmlFile, key, light)
	if not superFunc(self, xmlFile, key, light) then
		return false
	end

	light.inputAttacherJointIndex = xmlFile:getValue(key .. "#inputAttacherJointIndex")

	return true
end

function Attachable:getIsLightActive(superFunc, light)
	if light.inputAttacherJointIndex ~= nil and light.inputAttacherJointIndex ~= self:getActiveInputAttacherJointDescIndex() then
		return false
	end

	return superFunc(self, light)
end

function Attachable:getIsPowered(superFunc)
	local attacherVehicle = self:getAttacherVehicle()

	if attacherVehicle ~= nil then
		local isPowered, warning = attacherVehicle:getIsPowered()

		if not isPowered then
			return isPowered, warning
		end
	else
		local spec = self.spec_attachable

		if spec.requiresExternalPower and not SpecializationUtil.hasSpecialization(Motorized, self.specializations) then
			return false, spec.attachToPowerWarning
		end
	end

	return superFunc(self)
end

function Attachable:getConnectionHoseConfigIndex(superFunc)
	local index = superFunc(self)
	index = self.xmlFile:getValue("vehicle.attachable#connectionHoseConfigId", index)

	if self.configurations.inputAttacherJoint ~= nil then
		local configKey = string.format("vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration(%d)", self.configurations.inputAttacherJoint - 1)
		index = self.xmlFile:getValue(configKey .. "#connectionHoseConfigId", index)
	end

	return index
end

function Attachable:getIsMapHotspotVisible(superFunc)
	if not superFunc(self) then
		return false
	end

	if self:getIsAdditionalAttachment() then
		return false
	end

	if self:getIsSupportVehicle() then
		return false
	end

	return self:getAttacherVehicle() == nil
end

function Attachable:getPowerTakeOffConfigIndex(superFunc)
	local index = superFunc(self)
	index = self.xmlFile:getValue("vehicle.attachable#powerTakeOffConfigId", index)

	if self.configurations.inputAttacherJoint ~= nil then
		local configKey = string.format("vehicle.attachable.inputAttacherJointConfigurations.inputAttacherJointConfiguration(%d)", self.configurations.inputAttacherJoint - 1)
		index = self.xmlFile:getValue(configKey .. "#powerTakeOffConfigId", index)
	end

	return index
end

function Attachable:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
		return false
	end

	group.isAttached = xmlFile:getValue(key .. "#isAttached")

	return true
end

function Attachable:getIsDashboardGroupActive(superFunc, group)
	if group.isAttached ~= nil and group.isAttached ~= (self:getAttacherVehicle() ~= nil) then
		return false
	end

	return superFunc(self, group)
end

function Attachable:setWorldPositionQuaternion(superFunc, x, y, z, qx, qy, qz, qw, i, changeInterp)
	if not self.isServer then
		if not self.spec_attachable.isHardAttached then
			return superFunc(self, x, y, z, qx, qy, qz, qw, i, changeInterp)
		end

		return
	end

	return superFunc(self, x, y, z, qx, qy, qz, qw, i, changeInterp)
end

function Attachable:actionControllerLowerImplementEvent(direction)
	local spec = self.spec_attachable

	if self:getAllowsLowering() then
		local moveDown = true

		if direction < 0 then
			moveDown = false
		end

		local jointDescIndex = spec.attacherVehicle:getAttacherJointIndexFromObject(self)

		if spec.attacherVehicle:getJointMoveDown(jointDescIndex) ~= moveDown then
			spec.attacherVehicle:setJointMoveDown(jointDescIndex, moveDown, false)
		end

		return true
	end

	return false
end

function Attachable:onStateChange(state, data)
	if self.getAILowerIfAnyIsLowered ~= nil and self:getAILowerIfAnyIsLowered() then
		if state == Vehicle.STATE_CHANGE_AI_START_LINE then
			Attachable.actionControllerLowerImplementEvent(self, 1)
		elseif state == Vehicle.STATE_CHANGE_AI_END_LINE then
			Attachable.actionControllerLowerImplementEvent(self, -1)
		end
	end
end

function Attachable:onRootVehicleChanged(rootVehicle)
	local spec = self.spec_attachable
	local actionController = rootVehicle.actionController

	if actionController ~= nil and spec.controlledAction ~= nil then
		spec.controlledAction:updateParent(actionController)
	end
end

function Attachable:onFoldStateChanged(direction, moveToMiddle)
	local spec = self.spec_foldable

	if spec.foldMiddleAnimTime ~= nil then
		if not moveToMiddle and direction == spec.turnOnFoldDirection then
			SpecializationUtil.raiseEvent(self, "onSetLowered", true)
		else
			SpecializationUtil.raiseEvent(self, "onSetLowered", false)
		end
	end
end

function Attachable:onRegisterAnimationValueTypes()
	local function loadInputAttacherJoint(value, xmlFile, xmlKey)
		value.inputAttacherJointIndex = xmlFile:getValue(xmlKey .. "#inputAttacherJointIndex")

		if value.inputAttacherJointIndex ~= nil then
			value:setWarningInformation("inputAttacherJointIndex: " .. value.inputAttacherJointIndex)
			value:addCompareParameters("inputAttacherJointIndex")

			return true
		end

		return false
	end

	local function resolveAttacherJoint(value)
		if value.inputAttacherJoint == nil then
			value.inputAttacherJoint = self:getInputAttacherJointByJointDescIndex(value.inputAttacherJointIndex)

			if value.inputAttacherJoint == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown inputAttacherJointIndex '%s' for animation part.", value.inputAttacherJointIndex)

				value.inputAttacherJointIndex = nil

				return 0
			end
		end
	end

	local function updateJointSettings(...)
		local attacherVehicle = self:getAttacherVehicle()

		if attacherVehicle ~= nil then
			attacherVehicle:updateAttacherJointSettingsByObject(self, ...)
		end
	end

	self:registerAnimationValueType("lowerRotLimitScale", "lowerRotLimitScaleStart", "lowerRotLimitScaleEnd", false, AnimationValueFloat, loadInputAttacherJoint, function (value)
		if value.inputAttacherJointIndex ~= nil then
			resolveAttacherJoint(value)
		end

		if value.inputAttacherJoint ~= nil then
			return unpack(value.inputAttacherJoint.lowerRotLimitScale)
		else
			return 0, 0, 0
		end
	end, function (value, x, y, z)
		if value.inputAttacherJoint ~= nil then
			value.inputAttacherJoint.lowerRotLimitScale[1] = x
			value.inputAttacherJoint.lowerRotLimitScale[2] = y
			value.inputAttacherJoint.lowerRotLimitScale[3] = z

			updateJointSettings(true)
		end
	end)
	self:registerAnimationValueType("upperRotLimitScale", "upperRotLimitScaleStart", "upperRotLimitScaleEnd", false, AnimationValueFloat, loadInputAttacherJoint, function (value)
		if value.inputAttacherJointIndex ~= nil then
			resolveAttacherJoint(value)
		end

		if value.inputAttacherJoint ~= nil then
			return unpack(value.inputAttacherJoint.upperRotLimitScale)
		else
			return 0, 0, 0
		end
	end, function (value, x, y, z)
		if value.inputAttacherJoint ~= nil then
			value.inputAttacherJoint.upperRotLimitScale[1] = x
			value.inputAttacherJoint.upperRotLimitScale[2] = y
			value.inputAttacherJoint.upperRotLimitScale[3] = z

			updateJointSettings(true)
		end
	end)
	self:registerAnimationValueType("lowerTransLimitScale", "lowerTransLimitScaleStart", "lowerTransLimitScaleEnd", false, AnimationValueFloat, loadInputAttacherJoint, function (value)
		if value.inputAttacherJointIndex ~= nil then
			resolveAttacherJoint(value)
		end

		if value.inputAttacherJoint ~= nil then
			return unpack(value.inputAttacherJoint.lowerTransLimitScale)
		else
			return 0, 0, 0
		end
	end, function (value, x, y, z)
		if value.inputAttacherJoint ~= nil then
			value.inputAttacherJoint.lowerTransLimitScale[1] = x
			value.inputAttacherJoint.lowerTransLimitScale[2] = y
			value.inputAttacherJoint.lowerTransLimitScale[3] = z

			updateJointSettings(true)
		end
	end)
	self:registerAnimationValueType("upperTransLimitScale", "upperTransLimitScaleStart", "upperTransLimitScaleEnd", false, AnimationValueFloat, loadInputAttacherJoint, function (value)
		if value.inputAttacherJointIndex ~= nil then
			resolveAttacherJoint(value)
		end

		if value.inputAttacherJoint ~= nil then
			return unpack(value.inputAttacherJoint.upperTransLimitScale)
		else
			return 0, 0, 0
		end
	end, function (value, x, y, z)
		if value.inputAttacherJoint ~= nil then
			value.inputAttacherJoint.upperTransLimitScale[1] = x
			value.inputAttacherJoint.upperTransLimitScale[2] = y
			value.inputAttacherJoint.upperTransLimitScale[3] = z

			updateJointSettings(true)
		end
	end)
	self:registerAnimationValueType("lowerRotationOffset", "lowerRotationOffsetStart", "lowerRotationOffsetEnd", false, AnimationValueFloat, loadInputAttacherJoint, function (value)
		if value.inputAttacherJointIndex ~= nil then
			resolveAttacherJoint(value)
		end

		if value.inputAttacherJoint ~= nil then
			return value.inputAttacherJoint.lowerRotationOffset
		else
			return 0
		end
	end, function (value, lowerRotationOffset)
		if value.inputAttacherJoint ~= nil then
			value.inputAttacherJoint.lowerRotationOffset = lowerRotationOffset

			updateJointSettings(false, true)
		end
	end)
	self:registerAnimationValueType("upperRotationOffset", "upperRotationOffsetStart", "upperRotationOffsetEnd", false, AnimationValueFloat, loadInputAttacherJoint, function (value)
		if value.inputAttacherJointIndex ~= nil then
			resolveAttacherJoint(value)
		end

		if value.inputAttacherJoint ~= nil then
			return value.inputAttacherJoint.upperRotationOffset
		else
			return 0
		end
	end, function (value, upperRotationOffset)
		if value.inputAttacherJoint ~= nil then
			value.inputAttacherJoint.upperRotationOffset = upperRotationOffset

			updateJointSettings(false, true)
		end
	end)
	self:registerAnimationValueType("lowerDistanceToGround", "lowerDistanceToGroundStart", "lowerDistanceToGroundEnd", false, AnimationValueFloat, loadInputAttacherJoint, function (value)
		if value.inputAttacherJointIndex ~= nil then
			resolveAttacherJoint(value)
		end

		if value.inputAttacherJoint ~= nil then
			return value.inputAttacherJoint.lowerDistanceToGround
		else
			return 0
		end
	end, function (value, lowerDistanceToGround)
		if value.inputAttacherJoint ~= nil then
			value.inputAttacherJoint.lowerDistanceToGround = lowerDistanceToGround

			updateJointSettings(false, false, true)
		end
	end)
	self:registerAnimationValueType("upperDistanceToGround", "upperDistanceToGroundStart", "upperDistanceToGroundEnd", false, AnimationValueFloat, loadInputAttacherJoint, function (value)
		if value.inputAttacherJointIndex ~= nil then
			resolveAttacherJoint(value)
		end

		if value.inputAttacherJoint ~= nil then
			return value.inputAttacherJoint.upperDistanceToGround
		else
			return 0
		end
	end, function (value, upperDistanceToGround)
		if value.inputAttacherJoint ~= nil then
			value.inputAttacherJoint.upperDistanceToGround = upperDistanceToGround

			updateJointSettings(false, false, true)
		end
	end)
end
