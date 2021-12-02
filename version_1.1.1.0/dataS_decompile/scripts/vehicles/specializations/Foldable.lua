source("dataS/scripts/vehicles/specializations/events/FoldableSetFoldDirectionEvent.lua")

Foldable = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function Foldable.initSpecialization()
	g_configurationManager:addConfigurationType("folding", g_i18n:getText("configuration_folding"), "foldable", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Foldable")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.foldable.foldingConfigurations.foldingConfiguration(?)")
	schema:register(XMLValueType.FLOAT, "vehicle.foldable.foldingConfigurations.foldingConfiguration(?)#workingWidth", "Working width to display in shop")
	Foldable.registerFoldingXMLPaths(schema, "vehicle.foldable.foldingConfigurations.foldingConfiguration(?).foldingParts")
	schema:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_KEY .. "#foldLimitedOuterRange", "Fold limit outer range", false)
	schema:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_KEY .. ".folding#minLimit", "Min. fold limit", 0)
	schema:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_KEY .. ".folding#maxLimit", "Max. fold limit", 1)
	schema:register(XMLValueType.BOOL, WorkArea.WORK_AREA_XML_CONFIG_KEY .. "#foldLimitedOuterRange", "Fold limit outer range", false)
	schema:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".folding#minLimit", "Min. fold limit", 0)
	schema:register(XMLValueType.FLOAT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".folding#maxLimit", "Max. fold limit", 1)
	schema:register(XMLValueType.FLOAT, GroundReference.GROUND_REFERENCE_XML_KEY .. ".folding#minLimit", "Min. fold limit", 0)
	schema:register(XMLValueType.FLOAT, GroundReference.GROUND_REFERENCE_XML_KEY .. ".folding#maxLimit", "Max. fold limit", 1)
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#foldLimitedOuterRange", "Fold limit outer range", false)
	schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#foldMinLimit", "Min. fold limit", 0)
	schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#foldMaxLimit", "Max. fold limit", 1)
	schema:register(XMLValueType.BOOL, Leveler.LEVELER_NODE_XML_KEY .. "#foldLimitedOuterRange", "Fold limit outer range", false)
	schema:register(XMLValueType.FLOAT, Leveler.LEVELER_NODE_XML_KEY .. "#foldMinLimit", "Min. fold limit", 0)
	schema:register(XMLValueType.FLOAT, Leveler.LEVELER_NODE_XML_KEY .. "#foldMaxLimit", "Max. fold limit", 1)
	schema:register(XMLValueType.FLOAT, SlopeCompensation.COMPENSATION_NODE_XML_KEY .. "#foldAngleScale", "Fold angle scale")
	schema:register(XMLValueType.BOOL, SlopeCompensation.COMPENSATION_NODE_XML_KEY .. "#invertFoldAngleScale", "Invert fold angle scale", false)
	schema:register(XMLValueType.FLOAT, Cylindered.MOVING_TOOL_XML_KEY .. "#foldMinLimit", "Fold min. time", 0)
	schema:register(XMLValueType.FLOAT, Cylindered.MOVING_TOOL_XML_KEY .. "#foldMaxLimit", "Fold max. time", 1)
	schema:register(XMLValueType.FLOAT, Cylindered.MOVING_PART_XML_KEY .. "#foldMinLimit", "Fold min. time", 0)
	schema:register(XMLValueType.FLOAT, Cylindered.MOVING_PART_XML_KEY .. "#foldMaxLimit", "Fold max. time", 1)
	schema:register(XMLValueType.FLOAT, GroundAdjustedNodes.GROUND_ADJUSTED_NODE_XML_KEY .. ".foldable#minLimit", "Fold min. time", 0)
	schema:register(XMLValueType.FLOAT, GroundAdjustedNodes.GROUND_ADJUSTED_NODE_XML_KEY .. ".foldable#maxLimit", "Fold max. time", 1)
	schema:register(XMLValueType.FLOAT, Sprayer.SPRAY_TYPE_XML_KEY .. "#foldMinLimit", "Fold min. time", 0)
	schema:register(XMLValueType.FLOAT, Sprayer.SPRAY_TYPE_XML_KEY .. "#foldMaxLimit", "Fold max. time", 1)
	schema:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. "#foldingConfigurationIndex", "Index of folding configuration to activate spray type")
	schema:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. "#foldMinLimit", "Fold min. time", 0)
	schema:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. "#foldMaxLimit", "Fold max. time", 1)
	schema:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. "#foldMinLimit", "Fold min. time", 0)
	schema:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. "#foldMaxLimit", "Fold max. time", 1)
	schema:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. ".heightNode(?)#foldMinLimit", "Fold min. time", 0)
	schema:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_XML_KEY .. ".heightNode(?)#foldMaxLimit", "Fold max. time", 1)
	schema:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. ".heightNode(?)#foldMinLimit", "Fold min. time", 0)
	schema:register(XMLValueType.FLOAT, Attachable.INPUT_ATTACHERJOINT_CONFIG_XML_KEY .. ".heightNode(?)#foldMaxLimit", "Fold max. time", 1)
	schema:register(XMLValueType.FLOAT, Enterable.ADDITIONAL_CHARACTER_XML_KEY .. "#foldMinLimit", "Fold min. time", 0)
	schema:register(XMLValueType.FLOAT, Enterable.ADDITIONAL_CHARACTER_XML_KEY .. "#foldMaxLimit", "Fold max. time", 1)
	schema:register(XMLValueType.FLOAT, Attachable.SUPPORT_XML_KEY .. ".folding#minLimit", "Min. fold limit", 0)
	schema:register(XMLValueType.FLOAT, Attachable.SUPPORT_XML_KEY .. ".folding#maxLimit", "Max. fold limit", 1)
	schema:register(XMLValueType.FLOAT, Attachable.STEERING_AXLE_XML_KEY .. ".folding#minLimit", "Min. fold limit", 0)
	schema:register(XMLValueType.FLOAT, Attachable.STEERING_AXLE_XML_KEY .. ".folding#maxLimit", "Max. fold limit", 1)
	schema:register(XMLValueType.FLOAT, Wheels.WHEEL_XML_PATH .. "#versatileFoldMinLimit", "Fold min. time for versatility", 0)
	schema:register(XMLValueType.FLOAT, Wheels.WHEEL_XML_PATH .. "#versatileFoldMaxLimit", "Fold max. time for versatility", 1)
	schema:register(XMLValueType.FLOAT, FillUnit.FILL_UNIT_XML_KEY .. "#foldMinLimit", "Fold min. time for filling", 0)
	schema:register(XMLValueType.FLOAT, FillUnit.FILL_UNIT_XML_KEY .. "#foldMaxLimit", "Fold max. time for filling", 1)
	schema:register(XMLValueType.FLOAT, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#foldMinLimit", "Fold min. time for running turned on animation", 0)
	schema:register(XMLValueType.FLOAT, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#foldMaxLimit", "Fold max. time for running turned on animation", 1)
	schema:register(XMLValueType.FLOAT, Pickup.PICKUP_XML_KEY .. "#foldMinLimit", "Fold min. time for pickup lowering", 0)
	schema:register(XMLValueType.FLOAT, Pickup.PICKUP_XML_KEY .. "#foldMaxLimit", "Fold max. time for pickup lowering", 1)
	schema:register(XMLValueType.FLOAT, Cutter.CUTTER_TILT_XML_KEY .. "#foldMinLimit", "Fold min. time for cutter automatic tilt", 0)
	schema:register(XMLValueType.FLOAT, Cutter.CUTTER_TILT_XML_KEY .. "#foldMaxLimit", "Fold max. time for cutter automatic tilt", 1)
	schema:register(XMLValueType.FLOAT, VinePrepruner.PRUNER_NODE_XML_KEY .. "#foldMinLimit", "Fold min. time for pruner node update", 0)
	schema:register(XMLValueType.FLOAT, VinePrepruner.PRUNER_NODE_XML_KEY .. "#foldMaxLimit", "Fold max. time for pruner node update", 1)
	schema:register(XMLValueType.FLOAT, Shovel.SHOVEL_NODE_XML_KEY .. "#foldMinLimit", "Fold min. time for shovel pickup", 0)
	schema:register(XMLValueType.FLOAT, Shovel.SHOVEL_NODE_XML_KEY .. "#foldMaxLimit", "Fold max. time for shovel pickup", 1)
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame

	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).foldable#foldAnimTime", "Fold animation time")
end

function Foldable.registerFoldingXMLPaths(schema, basePath)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#posDirectionText", "Positive direction text", "$l10n_action_foldOBJECT")
	schema:register(XMLValueType.L10N_STRING, basePath .. "#negDirectionText", "Negative direction text", "$l10n_action_unfoldOBJECT")
	schema:register(XMLValueType.L10N_STRING, basePath .. "#middlePosDirectionText", "Positive middle direction text", "$l10n_action_liftOBJECT")
	schema:register(XMLValueType.L10N_STRING, basePath .. "#middleNegDirectionText", "Negative middle direction text", "$l10n_action_lowerOBJECT")
	schema:register(XMLValueType.FLOAT, basePath .. "#startAnimTime", "Start animation time", "Depending on startMoveDirection")
	schema:register(XMLValueType.INT, basePath .. "#startMoveDirection", "Start move direction", 0)
	schema:register(XMLValueType.INT, basePath .. "#turnOnFoldDirection", "Turn on fold direction")
	schema:register(XMLValueType.BOOL, basePath .. "#allowUnfoldingByAI", "Allow folding by AI", true)
	schema:register(XMLValueType.STRING, basePath .. "#foldInputButton", "Fold Input action", "IMPLEMENT_EXTRA2")
	schema:register(XMLValueType.STRING, basePath .. "#foldMiddleInputButton", "Fold middle Input action", "LOWER_IMPLEMENT")
	schema:register(XMLValueType.FLOAT, basePath .. "#foldMiddleAnimTime", "Fold middle anim time")
	schema:register(XMLValueType.INT, basePath .. "#foldMiddleDirection", "Fold middle direction", 1)
	schema:register(XMLValueType.INT, basePath .. "#foldMiddleAIRaiseDirection", "Fold middle AI raise direction", "same as foldMiddleDirection")
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnFoldMaxLimit", "Turn on fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#turnOnFoldMinLimit", "Turn on fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#toggleCoverMaxLimit", "Toggle cover fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#toggleCoverMinLimit", "Toggle cover fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#detachingMaxLimit", "Detach fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#detachingMinLimit", "Detach fold min. limit", 0)
	schema:register(XMLValueType.BOOL, basePath .. "#allowDetachingWhileFolding", "Allow detaching while folding", false)
	schema:register(XMLValueType.FLOAT, basePath .. "#loweringMaxLimit", "Lowering fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#loweringMinLimit", "Lowering fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#loadMovingToolStatesMaxLimit", "Load moving tool states fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#loadMovingToolStatesMinLimit", "Load moving tool states fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#dynamicMountMaxLimit", "Dynamic mount fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#dynamicMountMinLimit", "Dynamic mount fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. "#crabSteeringMinLimit", "Crab steering change fold max. limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. "#crabSteeringMaxLimit", "Crab steering change fold min. limit", 0)
	schema:register(XMLValueType.L10N_STRING, basePath .. "#unfoldWarning", "Unfold warning", "$l10n_warning_firstUnfoldTheTool")
	schema:register(XMLValueType.L10N_STRING, basePath .. "#detachWarning", "Detach warning", "$l10n_warning_doNotDetachWhileFolding")
	schema:register(XMLValueType.BOOL, basePath .. "#useParentFoldingState", "The fold state can not be controlled manually. It's always a copy of the fold state of the parent vehicle.", false)
	schema:register(XMLValueType.BOOL, basePath .. "#ignoreFoldMiddleWhileFolded", "While the tool is folded pressing the lowering button will only control the attacher joint state, not the fold state. The lowering key has only function if the tool is unfolded. (only if fold middle time defined)", false)
	schema:register(XMLValueType.BOOL, basePath .. "#lowerWhileDetach", "If tool is in fold middle state it gets lowered on detach and lifted while it's attached again", false)
	schema:register(XMLValueType.BOOL, basePath .. "#keepFoldingWhileDetached", "If set to 'true' the tool is still continuing with the folding animation after the tool is detached, otherwise it's stopped", "true for mobile platform, otherwise false")
	schema:register(XMLValueType.BOOL, basePath .. "#releaseBrakesWhileFolding", "If set to 'true' the tool is releasing it's brakes while the folding is active", false)
	schema:register(XMLValueType.BOOL, basePath .. "#requiresPower", "Vehicle needs to be powered to change folding state", true)
	schema:register(XMLValueType.FLOAT, basePath .. ".foldingPart(?)#speedScale", "Speed scale", 1)
	schema:register(XMLValueType.INT, basePath .. ".foldingPart(?)#componentJointIndex", "Component joint index")
	schema:register(XMLValueType.INT, basePath .. ".foldingPart(?)#anchorActor", "Component joint anchor actor", 0)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".foldingPart(?)#rootNode", "Root node for animation clip")
	schema:register(XMLValueType.STRING, basePath .. ".foldingPart(?)#animationClip", "Animation clip name")
	schema:register(XMLValueType.STRING, basePath .. ".foldingPart(?)#animationName", "Animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".foldingPart(?)#delayDistance", "Distance to be moved by the vehicle until part is played")
	schema:register(XMLValueType.FLOAT, basePath .. ".foldingPart(?)#previousDuration", "lowering duration if previous part", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".foldingPart(?)#loweringDuration", "lowering duration if folding part", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".foldingPart(?)#maxDelayDuration", "Max. duration of distance delay until movement is forced. Decreases by half when not moving", 7.5)
end

function Foldable.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onFoldStateChanged")
	SpecializationUtil.registerEvent(vehicleType, "onFoldTimeChanged")
end

function Foldable.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadFoldingPartFromXML", Foldable.loadFoldingPartFromXML)
	SpecializationUtil.registerFunction(vehicleType, "setFoldDirection", Foldable.setFoldDirection)
	SpecializationUtil.registerFunction(vehicleType, "setFoldState", Foldable.setFoldState)
	SpecializationUtil.registerFunction(vehicleType, "getIsUnfolded", Foldable.getIsUnfolded)
	SpecializationUtil.registerFunction(vehicleType, "getFoldAnimTime", Foldable.getFoldAnimTime)
	SpecializationUtil.registerFunction(vehicleType, "getIsFoldAllowed", Foldable.getIsFoldAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getIsFoldMiddleAllowed", Foldable.getIsFoldMiddleAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getToggledFoldDirection", Foldable.getToggledFoldDirection)
	SpecializationUtil.registerFunction(vehicleType, "getToggledFoldMiddleDirection", Foldable.getToggledFoldMiddleDirection)
end

function Foldable.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "allowLoadMovingToolStates", Foldable.allowLoadMovingToolStates)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Foldable.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Foldable.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadCompensationNodeFromXML", Foldable.loadCompensationNodeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCompensationAngleScale", Foldable.getCompensationAngleScale)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWheelFromXML", Foldable.loadWheelFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsVersatileYRotActive", Foldable.getIsVersatileYRotActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Foldable.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Foldable.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadGroundReferenceNode", Foldable.loadGroundReferenceNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "updateGroundReferenceNode", Foldable.updateGroundReferenceNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadLevelerNodeFromXML", Foldable.loadLevelerNodeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLevelerPickupNodeActive", Foldable.getIsLevelerPickupNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingToolFromXML", Foldable.loadMovingToolFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingToolActive", Foldable.getIsMovingToolActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadMovingPartFromXML", Foldable.loadMovingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsMovingPartActive", Foldable.getIsMovingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Foldable.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsNextCoverStateAllowed", Foldable.getIsNextCoverStateAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInWorkPosition", Foldable.getIsInWorkPosition)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", Foldable.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", Foldable.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowsLowering", Foldable.getAllowsLowering)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsLowered", Foldable.getIsLowered)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", Foldable.getCanAIImplementContinueWork)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIReadyToDrive", Foldable.getIsAIReadyToDrive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIPreparingToDrive", Foldable.getIsAIPreparingToDrive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerLoweringActionEvent", Foldable.registerLoweringActionEvent)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "registerSelfLoweringActionEvent", Foldable.registerSelfLoweringActionEvent)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadGroundAdjustedNodeFromXML", Foldable.loadGroundAdjustedNodeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsGroundAdjustedNodeActive", Foldable.getIsGroundAdjustedNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSprayTypeFromXML", Foldable.loadSprayTypeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSprayTypeActive", Foldable.getIsSprayTypeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Foldable.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadInputAttacherJoint", Foldable.loadInputAttacherJoint)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsInputAttacherActive", Foldable.getIsInputAttacherActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAdditionalCharacterFromXML", Foldable.loadAdditionalCharacterFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAdditionalCharacterActive", Foldable.getIsAdditionalCharacterActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowDynamicMountObjects", Foldable.getAllowDynamicMountObjects)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSupportAnimationFromXML", Foldable.loadSupportAnimationFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSupportAnimationAllowed", Foldable.getIsSupportAnimationAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSteeringAxleFromXML", Foldable.loadSteeringAxleFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSteeringAxleAllowed", Foldable.getIsSteeringAxleAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadFillUnitFromXML", Foldable.loadFillUnitFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitSupportsToolType", Foldable.getFillUnitSupportsToolType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadTurnedOnAnimationFromXML", Foldable.loadTurnedOnAnimationFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsTurnedOnAnimationActive", Foldable.getIsTurnedOnAnimationActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAttacherJointHeightNode", Foldable.loadAttacherJointHeightNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAttacherJointHeightNodeActive", Foldable.getIsAttacherJointHeightNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadPickupFromXML", Foldable.loadPickupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanChangePickupState", Foldable.getCanChangePickupState)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadCutterTiltFromXML", Foldable.loadCutterTiltFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCutterTiltIsActive", Foldable.getCutterTiltIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadPreprunerNodeFromXML", Foldable.loadPreprunerNodeFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPreprunerNodeActive", Foldable.getIsPreprunerNodeActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadShovelNode", Foldable.loadShovelNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getShovelNodeIsActive", Foldable.getShovelNodeIsActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleCrabSteering", Foldable.getCanToggleCrabSteering)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", Foldable.getBrakeForce)
end

function Foldable.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onSetLoweredAll", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttachImplement", Foldable)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetachImplement", Foldable)
end

function Foldable:onLoad(savegame)
	local spec = self.spec_foldable

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.foldingParts", "vehicle.foldable.foldingConfigurations.foldingConfiguration.foldingParts")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.foldable.foldingParts", "vehicle.foldable.foldingConfigurations.foldingConfiguration.foldingParts")

	local foldingConfigurationId = Utils.getNoNil(self.configurations.folding, 1)
	local configKey = string.format("vehicle.foldable.foldingConfigurations.foldingConfiguration(%d).foldingParts", foldingConfigurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.foldable.foldingConfigurations.foldingConfiguration", foldingConfigurationId, self.components, self)

	spec.posDirectionText = string.format(self.xmlFile:getValue(configKey .. "#posDirectionText", "action_foldOBJECT", self.customEnvironment, false), self.typeDesc)
	spec.negDirectionText = string.format(self.xmlFile:getValue(configKey .. "#negDirectionText", "action_unfoldOBJECT", self.customEnvironment, false), self.typeDesc)
	spec.middlePosDirectionText = string.format(self.xmlFile:getValue(configKey .. "#middlePosDirectionText", "action_liftOBJECT", self.customEnvironment, false), self.typeDesc)
	spec.middleNegDirectionText = string.format(self.xmlFile:getValue(configKey .. "#middleNegDirectionText", "action_lowerOBJECT", self.customEnvironment, false), self.typeDesc)
	spec.startAnimTime = self.xmlFile:getValue(configKey .. "#startAnimTime")
	spec.foldMoveDirection = 0
	spec.moveToMiddle = false

	if spec.startAnimTime == nil then
		spec.startAnimTime = 0
		local startMoveDirection = self.xmlFile:getValue(configKey .. "#startMoveDirection", 0)

		if startMoveDirection > 0.1 then
			spec.startAnimTime = 1
		end
	end

	spec.turnOnFoldDirection = 1

	if spec.startAnimTime > 0.5 then
		spec.turnOnFoldDirection = -1
	end

	spec.turnOnFoldDirection = MathUtil.sign(self.xmlFile:getValue(configKey .. "#turnOnFoldDirection", spec.turnOnFoldDirection))

	if spec.turnOnFoldDirection == 0 then
		Logging.xmlWarning(self.xmlFile, "Foldable 'turnOnFoldDirection' not allowed to be 0! Only -1 and 1 are allowed")

		spec.turnOnFoldDirection = -1
	end

	spec.allowUnfoldingByAI = self.xmlFile:getValue(configKey .. "#allowUnfoldingByAI", true)
	local foldInputButtonStr = self.xmlFile:getValue(configKey .. "#foldInputButton")

	if foldInputButtonStr ~= nil then
		spec.foldInputButton = InputAction[foldInputButtonStr]
	end

	spec.foldInputButton = Utils.getNoNil(spec.foldInputButton, InputAction.IMPLEMENT_EXTRA2)
	local foldMiddleInputButtonStr = self.xmlFile:getValue(configKey .. "#foldMiddleInputButton")

	if foldMiddleInputButtonStr ~= nil then
		spec.foldMiddleInputButton = InputAction[foldMiddleInputButtonStr]
	end

	spec.foldMiddleInputButton = Utils.getNoNil(spec.foldMiddleInputButton, InputAction.LOWER_IMPLEMENT)
	spec.foldMiddleAnimTime = self.xmlFile:getValue(configKey .. "#foldMiddleAnimTime")
	spec.foldMiddleDirection = self.xmlFile:getValue(configKey .. "#foldMiddleDirection", 1)
	spec.foldMiddleAIRaiseDirection = self.xmlFile:getValue(configKey .. "#foldMiddleAIRaiseDirection", spec.foldMiddleDirection)
	spec.turnOnFoldMaxLimit = self.xmlFile:getValue(configKey .. "#turnOnFoldMaxLimit", 1)
	spec.turnOnFoldMinLimit = self.xmlFile:getValue(configKey .. "#turnOnFoldMinLimit", 0)
	spec.toggleCoverMaxLimit = self.xmlFile:getValue(configKey .. "#toggleCoverMaxLimit", 1)
	spec.toggleCoverMinLimit = self.xmlFile:getValue(configKey .. "#toggleCoverMinLimit", 0)
	spec.detachingMaxLimit = self.xmlFile:getValue(configKey .. "#detachingMaxLimit", 1)
	spec.detachingMinLimit = self.xmlFile:getValue(configKey .. "#detachingMinLimit", 0)
	spec.allowDetachingWhileFolding = self.xmlFile:getValue(configKey .. "#allowDetachingWhileFolding", false)
	spec.loweringMaxLimit = self.xmlFile:getValue(configKey .. "#loweringMaxLimit", 1)
	spec.loweringMinLimit = self.xmlFile:getValue(configKey .. "#loweringMinLimit", 0)
	spec.loadMovingToolStatesMaxLimit = self.xmlFile:getValue(configKey .. "#loadMovingToolStatesMaxLimit", 1)
	spec.loadMovingToolStatesMinLimit = self.xmlFile:getValue(configKey .. "#loadMovingToolStatesMinLimit", 0)
	spec.dynamicMountMinLimit = self.xmlFile:getValue(configKey .. "#dynamicMountMinLimit", 0)
	spec.dynamicMountMaxLimit = self.xmlFile:getValue(configKey .. "#dynamicMountMaxLimit", 1)
	spec.crabSteeringMinLimit = self.xmlFile:getValue(configKey .. "#crabSteeringMinLimit", 0)
	spec.crabSteeringMaxLimit = self.xmlFile:getValue(configKey .. "#crabSteeringMaxLimit", 1)
	spec.unfoldWarning = string.format(self.xmlFile:getValue(configKey .. "#unfoldWarning", "warning_firstUnfoldTheTool", self.customEnvironment, false), self.typeDesc)
	spec.detachWarning = string.format(self.xmlFile:getValue(configKey .. "#detachWarning", "warning_doNotDetachWhileFolding", self.customEnvironment, false), self.typeDesc)
	spec.useParentFoldingState = self.xmlFile:getValue(configKey .. "#useParentFoldingState", false)
	spec.subFoldingStateVehicles = {}
	spec.ignoreFoldMiddleWhileFolded = self.xmlFile:getValue(configKey .. "#ignoreFoldMiddleWhileFolded", false)
	spec.lowerWhileDetach = self.xmlFile:getValue(configKey .. "#lowerWhileDetach", false)
	spec.keepFoldingWhileDetached = self.xmlFile:getValue(configKey .. "#keepFoldingWhileDetached", Platform.gameplay.keepFoldingWhileDetached)
	spec.releaseBrakesWhileFolding = self.xmlFile:getValue(configKey .. "#releaseBrakesWhileFolding", false)
	spec.requiresPower = self.xmlFile:getValue(configKey .. "#requiresPower", true)
	spec.foldAnimTime = 0
	spec.maxFoldAnimDuration = 0.0001
	spec.foldingParts = {}
	local i = 0

	while true do
		local baseKey = string.format(configKey .. ".foldingPart(%d)", i)

		if not self.xmlFile:hasProperty(baseKey) then
			break
		end

		local foldingPart = {}

		if self:loadFoldingPartFromXML(self.xmlFile, baseKey, foldingPart) then
			table.insert(spec.foldingParts, foldingPart)

			spec.maxFoldAnimDuration = math.max(spec.maxFoldAnimDuration, foldingPart.animDuration)
		end

		i = i + 1
	end

	if #spec.foldingParts > 0 then
		self.isSelectable = true
	end

	spec.actionEventsLowering = {}

	if savegame ~= nil and not savegame.resetVehicles then
		spec.loadedFoldAnimTime = savegame.xmlFile:getValue(savegame.key .. ".foldable#foldAnimTime")
	end

	if spec.loadedFoldAnimTime == nil then
		spec.loadedFoldAnimTime = spec.startAnimTime
	end

	if self.additionalLoadParameters ~= nil then
		if self.additionalLoadParameters.foldableInvertFoldState then
			spec.loadedFoldAnimTime = 1 - spec.loadedFoldAnimTime
		elseif self.additionalLoadParameters.foldableFoldingTime ~= nil then
			spec.loadedFoldAnimTime = self.additionalLoadParameters.foldableFoldingTime
		end
	end
end

function Foldable:onPostLoad(savegame)
	local spec = self.spec_foldable

	Foldable.setAnimTime(self, spec.loadedFoldAnimTime, false)

	if #spec.foldingParts == 0 or spec.useParentFoldingState then
		SpecializationUtil.removeEventListener(self, "onReadStream", Foldable)
		SpecializationUtil.removeEventListener(self, "onWriteStream", Foldable)
		SpecializationUtil.removeEventListener(self, "onUpdate", Foldable)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", Foldable)
		SpecializationUtil.removeEventListener(self, "onRegisterActionEvents", Foldable)
		SpecializationUtil.removeEventListener(self, "onDeactivate", Foldable)
		SpecializationUtil.removeEventListener(self, "onSetLoweredAll", Foldable)
		SpecializationUtil.removeEventListener(self, "onPostAttach", Foldable)
		SpecializationUtil.removeEventListener(self, "onPreDetach", Foldable)
	end
end

function Foldable:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_foldable

	xmlFile:setValue(key .. "#foldAnimTime", spec.foldAnimTime)
end

function Foldable:onReadStream(streamId, connection)
	local direction = streamReadUIntN(streamId, 2) - 1
	local moveToMiddle = streamReadBool(streamId)
	local animTime = streamReadFloat32(streamId)

	Foldable.setAnimTime(self, animTime, false)
	self:setFoldState(direction, moveToMiddle, true)
end

function Foldable:onWriteStream(streamId, connection)
	local spec = self.spec_foldable
	local direction = MathUtil.sign(spec.foldMoveDirection) + 1

	streamWriteUIntN(streamId, direction, 2)
	streamWriteBool(streamId, spec.moveToMiddle)
	streamWriteFloat32(streamId, spec.foldAnimTime)
end

function Foldable:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_foldable

	if math.abs(spec.foldMoveDirection) > 0.1 then
		local isInvalid = false
		local foldAnimTime = 0

		if spec.foldMoveDirection < -0.1 then
			foldAnimTime = 1
		end

		for _, foldingPart in pairs(spec.foldingParts) do
			local charSet = foldingPart.animCharSet

			if spec.foldMoveDirection > 0 then
				local animTime = nil

				if charSet ~= 0 then
					animTime = getAnimTrackTime(charSet, 0)
				else
					animTime = self:getRealAnimationTime(foldingPart.animationName)
				end

				if animTime < foldingPart.animDuration then
					isInvalid = true
				end

				foldAnimTime = math.max(foldAnimTime, animTime / spec.maxFoldAnimDuration)
			elseif spec.foldMoveDirection < 0 then
				local animTime = nil

				if charSet ~= 0 then
					animTime = getAnimTrackTime(charSet, 0)
				else
					animTime = self:getRealAnimationTime(foldingPart.animationName)
				end

				if animTime > 0 then
					isInvalid = true
				end

				foldAnimTime = math.min(foldAnimTime, animTime / spec.maxFoldAnimDuration)
			end
		end

		foldAnimTime = MathUtil.clamp(foldAnimTime, 0, 1)

		if foldAnimTime ~= spec.foldAnimTime then
			spec.foldAnimTime = foldAnimTime

			SpecializationUtil.raiseEvent(self, "onFoldTimeChanged", spec.foldAnimTime)
		end

		if spec.foldMoveDirection > 0 then
			if not spec.moveToMiddle or spec.foldMiddleAnimTime == nil then
				if spec.foldAnimTime == 1 then
					spec.foldMoveDirection = 0
				end
			elseif spec.foldAnimTime == spec.foldMiddleAnimTime then
				spec.foldMoveDirection = 0
			end
		elseif spec.foldMoveDirection < 0 then
			if not spec.moveToMiddle or spec.foldMiddleAnimTime == nil then
				if spec.foldAnimTime == 0 then
					spec.foldMoveDirection = 0
				end
			elseif spec.foldAnimTime == spec.foldMiddleAnimTime then
				spec.foldMoveDirection = 0
			end
		end

		if isInvalid and self.isServer then
			for _, foldingPart in pairs(spec.foldingParts) do
				if foldingPart.componentJoint ~= nil then
					self:setComponentJointFrame(foldingPart.componentJoint, foldingPart.anchorActor)
				end
			end
		end

		for _, vehicle in pairs(spec.subFoldingStateVehicles) do
			Foldable.setAnimTime(vehicle, spec.foldAnimTime, false)
		end
	end

	for i = 1, #spec.foldingParts do
		local foldingPart = spec.foldingParts[i]
		local delayedLowering = foldingPart.delayedLowering

		if delayedLowering ~= nil and delayedLowering.currentDistance >= 0 then
			delayedLowering.currentDistance = delayedLowering.currentDistance + self.lastMovedDistance

			if delayedLowering.prevDistance == nil and delayedLowering.startTime + delayedLowering.previousDuration < g_time then
				delayedLowering.prevDistance = delayedLowering.currentDistance
			end

			local lowerDistance = self.lastSpeedReal * delayedLowering.loweringDuration
			local prevDistance = delayedLowering.prevDistance or self.lastSpeedReal * delayedLowering.previousDuration
			local distance = delayedLowering.distance + prevDistance - lowerDistance
			local force = g_time > delayedLowering.startTime + delayedLowering.maxDelayDuration * MathUtil.clamp(delayedLowering.currentDistance / distance * 0.5 + 0.5, 0, 1)

			if distance <= delayedLowering.currentDistance or force then
				self:playAnimation(foldingPart.animationName, delayedLowering.speedScale, delayedLowering.animTime, true)

				if delayedLowering.stopAnimTime ~= nil then
					self:setAnimationStopTime(foldingPart.animationName, delayedLowering.stopAnimTime)
				end

				delayedLowering.currentDistance = -1
			end
		end
	end
end

function Foldable:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_foldable

	if self.isClient then
		Foldable.updateActionEventFold(self)

		if spec.foldMiddleAnimTime ~= nil then
			Foldable.updateActionEventFoldMiddle(self)
		end
	end

	if self.isServer and spec.ignoreFoldMiddleWhileFolded and math.abs(spec.foldAnimTime - spec.foldMiddleAnimTime) < 0.001 and spec.foldMoveDirection == 1 == (spec.turnOnFoldDirection == 1) then
		local attacherVehicle = self:getAttacherVehicle()

		if attacherVehicle ~= nil then
			local jointDesc = attacherVehicle:getAttacherJointDescFromObject(self)

			if (jointDesc.allowsLowering or jointDesc.isDefaultLowered) and jointDesc.moveDown then
				self:setFoldState(-1, false)
			end
		end
	end
end

function Foldable:loadFoldingPartFromXML(xmlFile, baseKey, foldingPart)
	local isValid = false
	foldingPart.speedScale = xmlFile:getValue(baseKey .. "#speedScale", 1)

	if foldingPart.speedScale <= 0 then
		Logging.xmlWarning(xmlFile, "Negative speed scale for folding part '%s' not allowed!", baseKey)

		return false
	end

	local componentJointIndex = xmlFile:getValue(baseKey .. "#componentJointIndex")
	local componentJoint = nil

	if componentJointIndex ~= nil then
		if componentJointIndex == 0 then
			Logging.xmlWarning(xmlFile, "Invalid componentJointIndex for folding part '%s'. Indexing starts with 1!", baseKey)

			return false
		else
			componentJoint = self.componentJoints[componentJointIndex]
			foldingPart.componentJoint = componentJoint
		end
	end

	foldingPart.anchorActor = xmlFile:getValue(baseKey .. "#anchorActor", 0)
	foldingPart.animCharSet = 0
	local rootNode = xmlFile:getValue(baseKey .. "#rootNode", nil, self.components, self.i3dMappings)

	if rootNode ~= nil then
		local animCharSet = getAnimCharacterSet(rootNode)

		if animCharSet ~= 0 then
			local clip = getAnimClipIndex(animCharSet, xmlFile:getValue(baseKey .. "#animationClip"))

			if clip >= 0 then
				isValid = true
				foldingPart.animCharSet = animCharSet

				assignAnimTrackClip(foldingPart.animCharSet, 0, clip)
				setAnimTrackLoopState(foldingPart.animCharSet, 0, false)

				foldingPart.animDuration = getAnimClipDuration(foldingPart.animCharSet, clip)
			end
		end
	end

	if not isValid then
		if SpecializationUtil.hasSpecialization(AnimatedVehicle, self.specializations) then
			local animationName = xmlFile:getValue(baseKey .. "#animationName")

			if animationName ~= nil and self:getAnimationExists(animationName) then
				isValid = true
				foldingPart.animDuration = self:getAnimationDuration(animationName)
				foldingPart.animationName = animationName
				local animation = self:getAnimationByName(animationName)
				animation.resetOnStart = true
			end
		elseif xmlFile:getValue(baseKey .. "#animationName") ~= nil then
			Logging.xmlWarning(xmlFile, "Found animationName in folding part '%s', but vehicle has no animations!", baseKey)

			return false
		end
	end

	if not isValid then
		Logging.xmlWarning(xmlFile, "Invalid folding part '%s'. Either a animationClip or animationName needs to be defined!", baseKey)

		return false
	end

	local distance = xmlFile:getValue(baseKey .. "#delayDistance")

	if distance ~= nil then
		foldingPart.delayedLowering = {
			distance = distance,
			previousDuration = xmlFile:getValue(baseKey .. "#previousDuration", 1) * 1000,
			loweringDuration = xmlFile:getValue(baseKey .. "#loweringDuration", 1) * 1000,
			maxDelayDuration = xmlFile:getValue(baseKey .. "#maxDelayDuration", 7.5) * 1000,
			currentDistance = -1,
			startTime = math.huge,
			speedScale = 0,
			animTime = 0,
			stopAnimTime = 0,
			prevDistance = nil
		}
	end

	if componentJoint ~= nil then
		local node = self.components[componentJoint.componentIndices[(foldingPart.anchorActor + 1) % 2 + 1]].node
		foldingPart.x, foldingPart.y, foldingPart.z = worldToLocal(componentJoint.jointNode, getWorldTranslation(node))
		foldingPart.upX, foldingPart.upY, foldingPart.upZ = worldDirectionToLocal(componentJoint.jointNode, localDirectionToWorld(node, 0, 1, 0))
		foldingPart.dirX, foldingPart.dirY, foldingPart.dirZ = worldDirectionToLocal(componentJoint.jointNode, localDirectionToWorld(node, 0, 0, 1))
	end

	return true
end

function Foldable:setFoldDirection(direction, noEventSend)
	self:setFoldState(direction, false, noEventSend)
end

function Foldable:setFoldState(direction, moveToMiddle, noEventSend)
	local spec = self.spec_foldable

	if spec.foldMiddleAnimTime == nil then
		moveToMiddle = false
	end

	if spec.foldMoveDirection ~= direction or spec.moveToMiddle ~= moveToMiddle then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(FoldableSetFoldDirectionEvent.new(self, direction, moveToMiddle), nil, , self)
			else
				g_client:getServerConnection():sendEvent(FoldableSetFoldDirectionEvent.new(self, direction, moveToMiddle))
			end
		end

		spec.foldMoveDirection = direction
		spec.moveToMiddle = moveToMiddle

		for _, foldingPart in pairs(spec.foldingParts) do
			local speedScale = nil

			if spec.foldMoveDirection > 0.1 then
				if not spec.moveToMiddle or spec.foldAnimTime < spec.foldMiddleAnimTime then
					speedScale = foldingPart.speedScale
				end
			elseif spec.foldMoveDirection < -0.1 and (not spec.moveToMiddle or spec.foldMiddleAnimTime < spec.foldAnimTime) then
				speedScale = -foldingPart.speedScale
			end

			local charSet = foldingPart.animCharSet

			if charSet ~= 0 then
				if speedScale ~= nil then
					if speedScale > 0 then
						if getAnimTrackTime(charSet, 0) < 0 then
							setAnimTrackTime(charSet, 0, 0)
						end
					elseif foldingPart.animDuration < getAnimTrackTime(charSet, 0) then
						setAnimTrackTime(charSet, 0, foldingPart.animDuration)
					end

					setAnimTrackSpeedScale(charSet, 0, speedScale)
					enableAnimTrack(charSet, 0)
				else
					disableAnimTrack(charSet, 0)
				end
			else
				local animTime = nil

				if self:getIsAnimationPlaying(foldingPart.animationName) then
					animTime = self:getAnimationTime(foldingPart.animationName)
				else
					animTime = spec.foldAnimTime * spec.maxFoldAnimDuration / self:getAnimationDuration(foldingPart.animationName)
				end

				local alreadyPlaying = self:getIsAnimationPlaying(foldingPart.animationName)

				self:stopAnimation(foldingPart.animationName, true)

				if speedScale ~= nil then
					local stopAnimTime = nil

					if moveToMiddle then
						stopAnimTime = spec.foldMiddleAnimTime * spec.maxFoldAnimDuration / self:getAnimationDuration(foldingPart.animationName)
					end

					local isFolding = direction ~= spec.turnOnFoldDirection == not moveToMiddle

					if foldingPart.delayedLowering == nil or isFolding or alreadyPlaying then
						self:playAnimation(foldingPart.animationName, speedScale, animTime, true)

						if moveToMiddle then
							self:setAnimationStopTime(foldingPart.animationName, stopAnimTime)
						end

						if foldingPart.delayedLowering ~= nil then
							foldingPart.delayedLowering.currentDistance = -1
						end
					else
						local delayedLowering = foldingPart.delayedLowering
						delayedLowering.currentDistance = 0
						delayedLowering.speedScale = speedScale
						delayedLowering.animTime = animTime
						delayedLowering.stopAnimTime = stopAnimTime
						delayedLowering.startTime = g_time
						delayedLowering.prevDistance = nil
					end
				end
			end
		end

		if spec.foldMoveDirection > 0.1 then
			spec.foldAnimTime = math.min(spec.foldAnimTime + 0.0001, math.max(spec.foldAnimTime, 1))
		elseif spec.foldMoveDirection < -0.1 then
			spec.foldAnimTime = math.max(spec.foldAnimTime - 0.0001, math.min(spec.foldAnimTime, 0))
		end

		SpecializationUtil.raiseEvent(self, "onFoldStateChanged", direction, moveToMiddle)
	end
end

function Foldable:getIsUnfolded()
	local spec = self.spec_foldable

	if #spec.foldingParts > 0 then
		if spec.foldMiddleAnimTime ~= nil then
			if spec.turnOnFoldDirection == -1 and spec.foldAnimTime < spec.foldMiddleAnimTime + 0.01 or spec.turnOnFoldDirection == 1 and spec.foldAnimTime > spec.foldMiddleAnimTime - 0.01 then
				return true
			else
				return false
			end
		elseif spec.turnOnFoldDirection == -1 and spec.foldAnimTime == 0 or spec.turnOnFoldDirection == 1 and spec.foldAnimTime == 1 then
			return true
		else
			return false
		end
	else
		return true
	end
end

function Foldable:getFoldAnimTime()
	local spec = self.spec_foldable

	return spec.loadedFoldAnimTime or spec.foldAnimTime
end

function Foldable:getIsFoldAllowed(direction, onAiTurnOn)
	if self.getAttacherVehicle ~= nil and self:getAttacherVehicle() ~= nil then
		local inputAttacherJoint = self:getActiveInputAttacherJoint()

		if inputAttacherJoint.foldMinLimit ~= nil and inputAttacherJoint.foldMaxLimit ~= nil then
			local foldAnimTime = self:getFoldAnimTime()

			if foldAnimTime < inputAttacherJoint.foldMinLimit or inputAttacherJoint.foldMaxLimit < foldAnimTime then
				return false
			end
		end
	end

	return true
end

function Foldable:getIsFoldMiddleAllowed()
	local spec = self.spec_foldable

	return spec.foldMiddleAnimTime ~= nil
end

function Foldable:getToggledFoldDirection()
	local spec = self.spec_foldable
	local foldMidTime = 0.5

	if spec.foldMiddleAnimTime ~= nil then
		if spec.foldMiddleDirection > 0 then
			foldMidTime = (1 + spec.foldMiddleAnimTime) * 0.5
		else
			foldMidTime = spec.foldMiddleAnimTime * 0.5
		end
	end

	if spec.moveToMiddle then
		return spec.foldMiddleDirection
	elseif spec.foldMoveDirection > 0.1 or spec.foldMoveDirection == 0 and foldMidTime < spec.foldAnimTime then
		return -1
	else
		return 1
	end
end

function Foldable:getToggledFoldMiddleDirection()
	local spec = self.spec_foldable
	local ret = 0

	if spec.foldMiddleAnimTime ~= nil then
		if spec.foldMoveDirection > 0.1 then
			ret = -1
		else
			ret = 1
		end

		if spec.foldMiddleDirection > 0 then
			if spec.foldAnimTime >= spec.foldMiddleAnimTime - 0.01 then
				ret = -1
			end
		elseif spec.foldAnimTime <= spec.foldMiddleAnimTime + 0.01 then
			ret = 1
		else
			ret = -1
		end
	end

	return ret
end

function Foldable:allowLoadMovingToolStates(superFunc)
	local spec = self.spec_foldable

	if spec.loadMovingToolStatesMaxLimit < spec.foldAnimTime or spec.foldAnimTime < spec.loadMovingToolStatesMinLimit then
		return false
	end

	return superFunc(self)
end

function Foldable:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end

	speedRotatingPart.foldLimitedOuterRange = xmlFile:getValue(key .. "#foldLimitedOuterRange", false)
	local minFoldLimit = 0
	local maxFoldLimit = 1

	if speedRotatingPart.foldLimitedOuterRange then
		minFoldLimit = 0.5
		maxFoldLimit = 0.5
	end

	speedRotatingPart.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", minFoldLimit)
	speedRotatingPart.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", maxFoldLimit)

	return true
end

function Foldable:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	local spec = self.spec_foldable

	if not speedRotatingPart.foldLimitedOuterRange then
		if speedRotatingPart.foldMaxLimit < spec.foldAnimTime or spec.foldAnimTime < speedRotatingPart.foldMinLimit then
			return false
		end
	elseif spec.foldAnimTime <= speedRotatingPart.foldMaxLimit and speedRotatingPart.foldMinLimit < spec.foldAnimTime then
		return false
	end

	return superFunc(self, speedRotatingPart)
end

function Foldable:loadCompensationNodeFromXML(superFunc, compensationNode, xmlFile, key)
	compensationNode.foldAngleScale = xmlFile:getValue(key .. "#foldAngleScale")
	compensationNode.invertFoldAngleScale = xmlFile:getValue(key .. "#invertFoldAngleScale", false)

	return superFunc(self, compensationNode, xmlFile, key)
end

function Foldable:getCompensationAngleScale(superFunc, compensationNode)
	local scale = superFunc(self, compensationNode)

	if compensationNode.foldAngleScale ~= nil then
		local spec = self.spec_foldable
		local animTime = 1 - spec.foldAnimTime

		if compensationNode.invertFoldAngleScale then
			animTime = 1 - animTime
		end

		if spec.foldMiddleAnimTime ~= nil then
			scale = scale * MathUtil.lerp(compensationNode.foldAngleScale, 1, animTime / (1 - spec.foldMiddleAnimTime))
		else
			scale = scale * MathUtil.lerp(compensationNode.foldAngleScale, 1, animTime)
		end
	end

	return scale
end

function Foldable:loadWheelFromXML(superFunc, xmlFile, key, wheelnamei, wheel)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, "vehicle.wheels#versatileFoldMinLimit", key .. wheelnamei .. "#versatileFoldMinLimit")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, "vehicle.wheels#versatileFoldMaxLimit", key .. wheelnamei .. "#versatileFoldMaxLimit")

	wheel.versatileFoldMinLimit = xmlFile:getValue(key .. wheelnamei .. "#versatileFoldMinLimit", 0)
	wheel.versatileFoldMaxLimit = xmlFile:getValue(key .. wheelnamei .. "#versatileFoldMaxLimit", 1)

	return superFunc(self, xmlFile, key, wheelnamei, wheel)
end

function Foldable:getIsVersatileYRotActive(superFunc, wheel)
	local spec = self.spec_foldable

	if wheel.versatileFoldMaxLimit < spec.foldAnimTime or spec.foldAnimTime < wheel.versatileFoldMinLimit then
		return false
	end

	return superFunc(self, wheel)
end

function Foldable:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	workArea.foldLimitedOuterRange = xmlFile:getValue(key .. "#foldLimitedOuterRange", false)
	local minFoldLimit = 0
	local maxFoldLimit = 1

	if workArea.foldLimitedOuterRange then
		minFoldLimit = 0.5
		maxFoldLimit = 0.5
	end

	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#foldMinLimit", key .. ".folding#minLimit")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#foldMaxLimit", key .. ".folding#maxLimit")

	workArea.foldMinLimit = xmlFile:getValue(key .. ".folding#minLimit", minFoldLimit)
	workArea.foldMaxLimit = xmlFile:getValue(key .. ".folding#maxLimit", maxFoldLimit)

	return superFunc(self, workArea, xmlFile, key)
end

function Foldable:getIsWorkAreaActive(superFunc, workArea)
	local spec = self.spec_foldable

	if not workArea.foldLimitedOuterRange then
		if workArea.foldMaxLimit < spec.foldAnimTime or spec.foldAnimTime < workArea.foldMinLimit then
			return false
		end
	elseif spec.foldAnimTime <= workArea.foldMaxLimit and workArea.foldMinLimit < spec.foldAnimTime then
		return false
	end

	return superFunc(self, workArea)
end

function Foldable:loadGroundReferenceNode(superFunc, xmlFile, key, groundReferenceNode)
	local returnValue = superFunc(self, xmlFile, key, groundReferenceNode)

	if returnValue then
		groundReferenceNode.foldMinLimit = xmlFile:getValue(key .. ".folding#minLimit", 0)
		groundReferenceNode.foldMaxLimit = xmlFile:getValue(key .. ".folding#maxLimit", 1)
	end

	return returnValue
end

function Foldable:updateGroundReferenceNode(superFunc, groundReferenceNode)
	superFunc(self, groundReferenceNode)

	local foldAnimTime = self:getFoldAnimTime()

	if groundReferenceNode.foldMaxLimit < foldAnimTime or foldAnimTime < groundReferenceNode.foldMinLimit then
		groundReferenceNode.isActive = false
	end
end

function Foldable:loadLevelerNodeFromXML(superFunc, levelerNode, xmlFile, key)
	levelerNode.foldLimitedOuterRange = xmlFile:getValue(key .. "#foldLimitedOuterRange", false)
	local minFoldLimit = 0
	local maxFoldLimit = 1

	if levelerNode.foldLimitedOuterRange then
		minFoldLimit = 0.5
		maxFoldLimit = 0.5
	end

	levelerNode.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", minFoldLimit)
	levelerNode.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", maxFoldLimit)

	return superFunc(self, levelerNode, xmlFile, key)
end

function Foldable:getIsLevelerPickupNodeActive(superFunc, levelerNode)
	local spec = self.spec_foldable

	if not levelerNode.foldLimitedOuterRange then
		if levelerNode.foldMaxLimit < spec.foldAnimTime or spec.foldAnimTime < levelerNode.foldMinLimit then
			return false
		end
	elseif spec.foldAnimTime <= levelerNode.foldMaxLimit and levelerNode.foldMinLimit < spec.foldAnimTime then
		return false
	end

	return superFunc(self, levelerNode)
end

function Foldable:loadMovingToolFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end

	entry.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	entry.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)

	return true
end

function Foldable:getIsMovingToolActive(superFunc, movingTool)
	local foldAnimTime = self:getFoldAnimTime()

	if movingTool.foldMaxLimit < foldAnimTime or foldAnimTime < movingTool.foldMinLimit then
		return false
	end

	return superFunc(self, movingTool)
end

function Foldable:loadMovingPartFromXML(superFunc, xmlFile, key, entry)
	if not superFunc(self, xmlFile, key, entry) then
		return false
	end

	entry.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	entry.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)

	return true
end

function Foldable:getIsMovingPartActive(superFunc, movingPart)
	local foldAnimTime = self:getFoldAnimTime()

	if movingPart.foldMaxLimit < foldAnimTime or foldAnimTime < movingPart.foldMinLimit then
		return false
	end

	return superFunc(self, movingPart)
end

function Foldable:getCanBeTurnedOn(superFunc)
	local spec = self.spec_foldable

	if spec.turnOnFoldMaxLimit < spec.foldAnimTime or spec.foldAnimTime < spec.turnOnFoldMinLimit then
		return false
	end

	return superFunc(self)
end

function Foldable:getIsNextCoverStateAllowed(superFunc, nextState)
	if not superFunc(self, nextState) then
		return false
	end

	local spec = self.spec_foldable

	if spec.toggleCoverMaxLimit < spec.foldAnimTime or spec.foldAnimTime < spec.toggleCoverMinLimit then
		return false
	end

	return true
end

function Foldable:getIsInWorkPosition(superFunc)
	local spec = self.spec_foldable

	if spec.turnOnFoldDirection ~= 0 and #spec.foldingParts ~= 0 and (spec.turnOnFoldDirection ~= -1 or spec.foldAnimTime ~= 0) and (spec.turnOnFoldDirection ~= 1 or spec.foldAnimTime ~= 1) then
		return false
	end

	return superFunc(self)
end

function Foldable:getTurnedOnNotAllowedWarning(superFunc)
	local spec = self.spec_foldable

	if spec.turnOnFoldMaxLimit < spec.foldAnimTime or spec.foldAnimTime < spec.turnOnFoldMinLimit then
		return spec.unfoldWarning
	end

	return superFunc(self)
end

function Foldable:isDetachAllowed(superFunc)
	local spec = self.spec_foldable

	if spec.detachingMaxLimit < spec.foldAnimTime or spec.foldAnimTime < spec.detachingMinLimit then
		return false, spec.unfoldWarning
	end

	if not spec.allowDetachingWhileFolding and (spec.foldMiddleAnimTime == nil or math.abs(spec.foldAnimTime - spec.foldMiddleAnimTime) > 0.001) and spec.foldAnimTime > 0 and spec.foldAnimTime < 1 then
		return false, spec.detachWarning
	end

	return superFunc(self)
end

function Foldable:getAllowsLowering(superFunc)
	local spec = self.spec_foldable

	if spec.loweringMaxLimit < spec.foldAnimTime or spec.foldAnimTime < spec.loweringMinLimit then
		return false, spec.unfoldWarning
	end

	return superFunc(self)
end

function Foldable:getIsLowered(superFunc, default)
	local spec = self.spec_foldable

	if self:getIsFoldMiddleAllowed() and spec.foldMiddleAnimTime ~= nil and spec.foldMiddleInputButton ~= nil then
		local ignoreFoldMiddle = false

		if spec.ignoreFoldMiddleWhileFolded and spec.foldMiddleAnimTime < self:getFoldAnimTime() then
			ignoreFoldMiddle = true
		end

		if not ignoreFoldMiddle then
			if spec.foldMoveDirection ~= 0 then
				if spec.foldMiddleDirection > 0 then
					if spec.foldAnimTime < spec.foldMiddleAnimTime + 0.01 then
						return spec.foldMoveDirection < 0 and spec.moveToMiddle ~= true
					end
				elseif spec.foldAnimTime > spec.foldMiddleAnimTime - 0.01 then
					return spec.foldMoveDirection > 0 and spec.moveToMiddle ~= true
				end
			elseif spec.foldMiddleDirection > 0 and spec.foldAnimTime < 0.01 then
				return true
			elseif spec.foldMiddleDirection < 0 and math.abs(1 - spec.foldAnimTime) < 0.01 then
				return true
			end

			return false
		else
			return superFunc(self, default)
		end
	end

	return superFunc(self, default)
end

function Foldable:registerLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
	local spec = self.spec_foldable

	if #spec.foldingParts > 0 and spec.foldMiddleAnimTime ~= nil then
		self:clearActionEventsTable(spec.actionEventsLowering)

		local state, actionEventId = nil

		if spec.requiresPower then
			state, actionEventId = self:addPoweredActionEvent(spec.actionEventsLowering, spec.foldMiddleInputButton, self, Foldable.actionEventFoldMiddle, false, true, false, true, nil, , ignoreCollisions)
		else
			state, actionEventId = self:addActionEvent(spec.actionEventsLowering, spec.foldMiddleInputButton, self, Foldable.actionEventFoldMiddle, false, true, false, true, nil, , ignoreCollisions)
		end

		g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
		Foldable.updateActionEventFoldMiddle(self)

		if spec.foldMiddleInputButton == inputAction then
			return state, actionEventId
		end
	end

	return superFunc(self, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
end

function Foldable:registerSelfLoweringActionEvent(superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
	return Foldable.registerLoweringActionEvent(self, superFunc, actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions)
end

function Foldable:loadGroundAdjustedNodeFromXML(superFunc, xmlFile, key, adjustedNode)
	if not superFunc(self, xmlFile, key, adjustedNode) then
		return false
	end

	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#foldMinLimit", key .. ".foldable#minLimit")
	XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. "#foldMaxLimit", key .. ".foldable#maxLimit")

	adjustedNode.foldMinLimit = xmlFile:getValue(key .. ".foldable#minLimit", 0)
	adjustedNode.foldMaxLimit = xmlFile:getValue(key .. ".foldable#maxLimit", 1)

	return true
end

function Foldable:getIsGroundAdjustedNodeActive(superFunc, adjustedNode)
	local spec = self.spec_foldable
	local foldAnimTime = spec.foldAnimTime

	if foldAnimTime ~= nil and (adjustedNode.foldMaxLimit < foldAnimTime or foldAnimTime < adjustedNode.foldMinLimit) then
		return false
	end

	return superFunc(self, adjustedNode)
end

function Foldable:loadSprayTypeFromXML(superFunc, xmlFile, key, sprayType)
	sprayType.foldMinLimit = self.xmlFile:getValue(key .. "#foldMinLimit")
	sprayType.foldMaxLimit = self.xmlFile:getValue(key .. "#foldMaxLimit")
	sprayType.foldingConfigurationIndex = self.xmlFile:getValue(key .. "#foldingConfigurationIndex")

	return superFunc(self, xmlFile, key, sprayType)
end

function Foldable:getIsSprayTypeActive(superFunc, sprayType)
	local spec = self.spec_foldable

	if sprayType.foldMinLimit ~= nil and sprayType.foldMaxLimit ~= nil then
		local foldAnimTime = spec.foldAnimTime

		if foldAnimTime ~= nil and (sprayType.foldMaxLimit < foldAnimTime or foldAnimTime < sprayType.foldMinLimit) then
			return false
		end
	end

	if sprayType.foldingConfigurationIndex ~= nil and (self.configurations.folding or 1) ~= sprayType.foldingConfigurationIndex then
		return false
	end

	return superFunc(self, sprayType)
end

function Foldable:getCanBeSelected(superFunc)
	return true
end

function Foldable:loadInputAttacherJoint(superFunc, xmlFile, key, inputAttacherJoint, index)
	inputAttacherJoint.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit")
	inputAttacherJoint.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit")

	return superFunc(self, xmlFile, key, inputAttacherJoint, index)
end

function Foldable:getIsInputAttacherActive(superFunc, inputAttacherJoint)
	if inputAttacherJoint.foldMinLimit ~= nil and inputAttacherJoint.foldMaxLimit ~= nil then
		local foldAnimTime = self:getFoldAnimTime()

		if foldAnimTime < inputAttacherJoint.foldMinLimit or inputAttacherJoint.foldMaxLimit < foldAnimTime then
			return false
		end
	end

	return superFunc(self, inputAttacherJoint)
end

function Foldable:loadAdditionalCharacterFromXML(superFunc, xmlFile)
	local spec = self.spec_enterable
	spec.additionalCharacterFoldMinLimit = xmlFile:getValue("vehicle.enterable.additionalCharacter#foldMinLimit")
	spec.additionalCharacterFoldMaxLimit = xmlFile:getValue("vehicle.enterable.additionalCharacter#foldMaxLimit")

	return superFunc(self, xmlFile)
end

function Foldable:getIsAdditionalCharacterActive(superFunc)
	local spec = self.spec_enterable

	if spec.additionalCharacterFoldMinLimit ~= nil and spec.additionalCharacterFoldMaxLimit ~= nil then
		local foldAnimTime = self:getFoldAnimTime()

		if spec.additionalCharacterFoldMinLimit <= foldAnimTime and foldAnimTime <= spec.additionalCharacterFoldMaxLimit then
			return true
		end
	end

	return superFunc(self)
end

function Foldable:getAllowDynamicMountObjects(superFunc)
	local spec = self.spec_foldable
	local foldAnimTime = self:getFoldAnimTime()

	if foldAnimTime < spec.dynamicMountMinLimit or spec.dynamicMountMaxLimit < foldAnimTime then
		return false
	end

	return superFunc(self)
end

function Foldable:loadSupportAnimationFromXML(superFunc, supportAnimation, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#foldMinLimit", key .. ".folding#minLimit")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#foldMaxLimit", key .. ".folding#maxLimit")

	supportAnimation.foldMinLimit = xmlFile:getValue(key .. ".folding#minLimit", 0)
	supportAnimation.foldMaxLimit = xmlFile:getValue(key .. ".folding#maxLimit", 1)

	return superFunc(self, supportAnimation, xmlFile, key)
end

function Foldable:getIsSupportAnimationAllowed(superFunc, supportAnimation)
	local foldAnimTime = self:getFoldAnimTime()

	if foldAnimTime < supportAnimation.foldMinLimit or supportAnimation.foldMaxLimit < foldAnimTime then
		return false
	end

	return superFunc(self, supportAnimation)
end

function Foldable:loadSteeringAxleFromXML(superFunc, spec, xmlFile, key)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#foldMinLimit", key .. ".folding#minLimit")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#foldMaxLimit", key .. ".folding#maxLimit")

	spec.foldMinLimit = xmlFile:getValue(key .. ".folding#minLimit", 0)
	spec.foldMaxLimit = xmlFile:getValue(key .. ".folding#maxLimit", 1)

	return superFunc(self, spec, xmlFile, key)
end

function Foldable:getIsSteeringAxleAllowed(superFunc)
	local spec = self.spec_attachable
	local foldAnimTime = self:getFoldAnimTime()

	if foldAnimTime < spec.foldMinLimit or spec.foldMaxLimit < foldAnimTime then
		return false
	end

	return superFunc(self)
end

function Foldable:loadFillUnitFromXML(superFunc, xmlFile, key, entry, index)
	entry.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	entry.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)

	return superFunc(self, xmlFile, key, entry, index)
end

function Foldable:getFillUnitSupportsToolType(superFunc, fillUnitIndex, toolType)
	if toolType ~= ToolType.UNDEFINED then
		local fillUnit = self.spec_fillUnit.fillUnits[fillUnitIndex]

		if fillUnit ~= nil and fillUnit.foldMinLimit ~= nil and fillUnit.foldMaxLimit ~= nil then
			local foldAnimTime = self:getFoldAnimTime()

			if foldAnimTime < fillUnit.foldMinLimit or fillUnit.foldMaxLimit < foldAnimTime then
				return false
			end
		end
	end

	return superFunc(self, fillUnitIndex, toolType)
end

function Foldable:loadTurnedOnAnimationFromXML(superFunc, xmlFile, key, turnedOnAnimation)
	turnedOnAnimation.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	turnedOnAnimation.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)

	return superFunc(self, xmlFile, key, turnedOnAnimation)
end

function Foldable:getIsTurnedOnAnimationActive(superFunc, turnedOnAnimation)
	local foldAnimTime = self:getFoldAnimTime()

	if foldAnimTime < turnedOnAnimation.foldMinLimit or turnedOnAnimation.foldMaxLimit < foldAnimTime then
		return false
	end

	return superFunc(self, turnedOnAnimation)
end

function Foldable:loadAttacherJointHeightNode(superFunc, xmlFile, key, heightNode, attacherJointNode)
	heightNode.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	heightNode.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)

	return superFunc(self, xmlFile, key, heightNode, attacherJointNode)
end

function Foldable:getIsAttacherJointHeightNodeActive(superFunc, heightNode)
	local foldAnimTime = self:getFoldAnimTime()

	if foldAnimTime < heightNode.foldMinLimit or heightNode.foldMaxLimit < foldAnimTime then
		return false
	end

	return superFunc(self, heightNode)
end

function Foldable:loadPickupFromXML(superFunc, xmlFile, key, spec)
	spec.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	spec.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)

	return superFunc(self, xmlFile, key, spec)
end

function Foldable:getCanChangePickupState(superFunc, spec, newState)
	local foldAnimTime = self:getFoldAnimTime()

	if foldAnimTime < spec.foldMinLimit or spec.foldMaxLimit < foldAnimTime then
		return false
	end

	return superFunc(self, spec, newState)
end

function Foldable:loadCutterTiltFromXML(superFunc, xmlFile, key, target)
	if not superFunc(self, xmlFile, key, target) then
		return false
	end

	target.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	target.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)

	return true
end

function Foldable:getCutterTiltIsActive(superFunc, automaticTilt)
	local isActive, doReset = superFunc(self, automaticTilt)

	if not isActive then
		return isActive, doReset
	end

	local foldAnimTime = self:getFoldAnimTime()

	if foldAnimTime < automaticTilt.foldMinLimit or automaticTilt.foldMaxLimit < foldAnimTime then
		return false, true
	end

	return true, false
end

function Foldable:loadPreprunerNodeFromXML(superFunc, xmlFile, key, prunerNode)
	if not superFunc(self, xmlFile, key, prunerNode) then
		return false
	end

	prunerNode.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	prunerNode.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)

	return true
end

function Foldable:getIsPreprunerNodeActive(superFunc, prunerNode)
	local foldAnimTime = self:getFoldAnimTime()

	if foldAnimTime < prunerNode.foldMinLimit or prunerNode.foldMaxLimit < foldAnimTime then
		return false
	end

	return superFunc(self, prunerNode)
end

function Foldable:loadShovelNode(superFunc, xmlFile, key, shovelNode)
	superFunc(self, xmlFile, key, shovelNode)

	shovelNode.foldMinLimit = xmlFile:getValue(key .. "#foldMinLimit", 0)
	shovelNode.foldMaxLimit = xmlFile:getValue(key .. "#foldMaxLimit", 1)

	return true
end

function Foldable:getShovelNodeIsActive(superFunc, shovelNode)
	local foldAnimTime = self:getFoldAnimTime()

	if foldAnimTime < shovelNode.foldMinLimit or shovelNode.foldMaxLimit < foldAnimTime then
		return false
	end

	return superFunc(self, shovelNode)
end

function Foldable:getCanToggleCrabSteering(superFunc)
	local spec = self.spec_foldable
	local foldAnimTime = self:getFoldAnimTime()

	if foldAnimTime < spec.crabSteeringMinLimit or spec.crabSteeringMaxLimit < foldAnimTime then
		return false, spec.unfoldWarning
	end

	return superFunc(self)
end

function Foldable:getBrakeForce(superFunc)
	local spec = self.spec_foldable

	if spec.releaseBrakesWhileFolding and spec.foldMoveDirection ~= 0 then
		return 0
	end

	return superFunc(self)
end

function Foldable:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_foldable

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local isOnlyLowering = spec.foldMiddleAnimTime ~= nil and spec.foldMiddleAnimTime == 1

			if not isOnlyLowering then
				local _, actionEventId = nil

				if spec.requiresPower then
					_, actionEventId = self:addPoweredActionEvent(spec.actionEvents, spec.foldInputButton, self, Foldable.actionEventFold, false, true, false, true, nil)
				else
					_, actionEventId = self:addActionEvent(spec.actionEvents, spec.foldInputButton, self, Foldable.actionEventFold, false, true, false, true, nil)
				end

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
				Foldable.updateActionEventFold(self)

				_, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.FOLD_ALL_IMPLEMENTS, self, Foldable.actionEventFoldAll, false, true, false, true, nil)

				g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			end
		end
	end
end

function Foldable:getCanAIImplementContinueWork(superFunc)
	local canContinue, stopAI, stopReason = superFunc(self)

	if not canContinue then
		return false, stopAI, stopReason
	end

	local spec = self.spec_foldable

	if #spec.foldingParts > 0 and spec.allowUnfoldingByAI then
		canContinue = spec.foldAnimTime == spec.foldMiddleAnimTime or spec.foldAnimTime == 0 or spec.foldAnimTime == 1
	end

	return canContinue
end

function Foldable:getIsAIReadyToDrive(superFunc)
	local spec = self.spec_foldable

	if #spec.foldingParts > 0 and spec.allowUnfoldingByAI then
		if spec.turnOnFoldDirection > 0 then
			if spec.foldAnimTime > 0 then
				return false
			end
		elseif spec.foldAnimTime < 1 then
			return false
		end
	end

	return superFunc(self)
end

function Foldable:getIsAIPreparingToDrive(superFunc)
	local spec = self.spec_foldable

	if #spec.foldingParts > 0 and spec.allowUnfoldingByAI and spec.foldAnimTime ~= spec.foldMiddleAnimTime and spec.foldAnimTime ~= 0 and spec.foldAnimTime ~= 1 then
		return true
	end

	return superFunc(self)
end

function Foldable:onDeactivate()
	local spec = self.spec_foldable

	if not spec.keepFoldingWhileDetached and not spec.lowerWhileDetach then
		self:setFoldDirection(0, true)
	end
end

function Foldable:onSetLoweredAll(doLowering, jointDescIndex)
	local spec = self.spec_foldable

	if spec.foldMiddleAnimTime ~= nil and self:getIsFoldMiddleAllowed() then
		if doLowering then
			self:setFoldState(-spec.foldMiddleAIRaiseDirection, false)
		else
			self:setFoldState(spec.foldMiddleAIRaiseDirection, true)
		end
	end
end

function Foldable:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_foldable

	if spec.lowerWhileDetach and attacherVehicle ~= nil then
		local jointDesc = attacherVehicle:getAttacherJointByJointDescIndex(jointDescIndex)

		if not jointDesc.moveDown and self:getFoldAnimTime() < 0.001 then
			self:setFoldState(1, true, true)
		end
	end
end

function Foldable:onRootVehicleChanged(rootVehicle)
	local spec = self.spec_foldable

	if #spec.foldingParts > 0 then
		local actionController = rootVehicle.actionController

		if actionController ~= nil then
			if spec.controlledActionFold ~= nil then
				spec.controlledActionFold:updateParent(actionController)

				if spec.controlledActionLower ~= nil then
					spec.controlledActionLower:updateParent(actionController)
				end

				return
			end

			local unfoldedTime = spec.foldMiddleAnimTime

			if unfoldedTime == nil then
				unfoldedTime = 1

				if spec.turnOnFoldDirection < 0 then
					unfoldedTime = 0
				end
			end

			local foldedTime = 0

			if spec.turnOnFoldDirection < 0 then
				foldedTime = 1
			end

			spec.controlledActionFold = actionController:registerAction("fold", spec.toggleTurnOnInputBinding, 4)

			spec.controlledActionFold:setCallback(self, Foldable.actionControllerFoldEvent)
			spec.controlledActionFold:setFinishedFunctions(self, self.getFoldAnimTime, unfoldedTime, foldedTime)

			if spec.allowUnfoldingByAI then
				spec.controlledActionFold:addAIEventListener(self, "onAIFieldWorkerStart", 1)
				spec.controlledActionFold:addAIEventListener(self, "onAIImplementStart", 1)
				spec.controlledActionFold:addAIEventListener(self, "onAIImplementPrepare", -1, true)

				if Platform.gameplay.foldAfterAIFinished then
					spec.controlledActionFold:addAIEventListener(self, "onAIImplementEnd", -1, true)
					spec.controlledActionFold:addAIEventListener(self, "onAIFieldWorkerEnd", -1)
				end
			end

			if self:getIsFoldMiddleAllowed() then
				spec.controlledActionLower = actionController:registerAction("lowerFoldable", spec.toggleTurnOnInputBinding, 3)

				spec.controlledActionLower:setCallback(self, Foldable.actionControllerLowerEvent)
				spec.controlledActionLower:setFinishedFunctions(self, self.getFoldAnimTime, 1 - foldedTime, spec.foldMiddleAnimTime)
				spec.controlledActionLower:setResetOnDeactivation(false)

				if spec.allowUnfoldingByAI then
					spec.controlledActionLower:addAIEventListener(self, "onAIImplementStartLine", 1)
					spec.controlledActionLower:addAIEventListener(self, "onAIImplementEndLine", -1)
				end
			end
		else
			if spec.controlledActionFold ~= nil then
				spec.controlledActionFold:remove()
			end

			if spec.controlledActionLower ~= nil then
				spec.controlledActionLower:remove()
			end
		end
	end
end

function Foldable:actionControllerFoldEvent(direction)
	local spec = self.spec_foldable

	if #spec.foldingParts > 0 then
		if self:getIsFoldMiddleAllowed() and spec.foldAnimTime > 0 and spec.foldAnimTime < spec.foldMiddleAnimTime then
			return false
		end

		direction = spec.turnOnFoldDirection * direction

		if self:getIsFoldAllowed(direction, false) then
			if direction == spec.turnOnFoldDirection then
				self:setFoldState(direction, true)
			else
				self:setFoldState(direction, false)
			end

			return true
		end
	end

	return false
end

function Foldable:actionControllerLowerEvent(direction)
	local spec = self.spec_foldable

	if #spec.foldingParts > 0 then
		direction = spec.turnOnFoldDirection * direction

		if self:getIsFoldMiddleAllowed() then
			if direction == spec.turnOnFoldDirection then
				self:setFoldState(direction, false)
			elseif spec.foldMiddleDirection > 0 then
				if spec.foldAnimTime >= spec.foldMiddleAnimTime - 0.01 then
					self:setFoldState(-direction, true)
				else
					self:setFoldState(direction, true)
				end
			elseif spec.foldAnimTime <= spec.foldMiddleAnimTime + 0.01 then
				self:setFoldState(-direction, true)
			else
				self:setFoldState(direction, true)
			end

			return true
		end
	end

	return false
end

function Foldable:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_foldable

	if spec.lowerWhileDetach then
		local foldAnimTime = self:getFoldAnimTime()

		if math.abs(foldAnimTime - spec.foldMiddleAnimTime) < 0.001 then
			self:setFoldState(-1, false, true)
		end
	end
end

function Foldable:onPreAttachImplement(object, inputJointDescIndex, jointDescIndex)
	local subSpec = object.spec_foldable

	if subSpec ~= nil and subSpec.useParentFoldingState then
		self.spec_foldable.subFoldingStateVehicles[object] = object

		Foldable.setAnimTime(object, self.spec_foldable.foldAnimTime, false)
	end
end

function Foldable:onPreDetachImplement(implement)
	local subSpec = implement.object.spec_foldable

	if subSpec ~= nil and subSpec.useParentFoldingState then
		self.spec_foldable.subFoldingStateVehicles[implement.object] = nil
	end
end

function Foldable:setAnimTime(animTime, placeComponents)
	local spec = self.spec_foldable
	spec.foldAnimTime = animTime
	spec.loadedFoldAnimTime = nil

	for _, foldingPart in pairs(spec.foldingParts) do
		if foldingPart.animCharSet ~= 0 then
			enableAnimTrack(foldingPart.animCharSet, 0)
			setAnimTrackTime(foldingPart.animCharSet, 0, spec.foldAnimTime * foldingPart.animDuration, true)
			disableAnimTrack(foldingPart.animCharSet, 0)
		else
			animTime = spec.foldAnimTime * spec.maxFoldAnimDuration / self:getAnimationDuration(foldingPart.animationName)

			self:setAnimationTime(foldingPart.animationName, animTime, true)
		end
	end

	if placeComponents == nil then
		placeComponents = true
	end

	if self.updateCylinderedInitial ~= nil then
		self:updateCylinderedInitial(placeComponents)
	end

	if placeComponents and self.isServer then
		for _, foldingPart in pairs(spec.foldingParts) do
			if foldingPart.componentJoint ~= nil then
				local componentJoint = foldingPart.componentJoint
				local jointNode = componentJoint.jointNode

				if foldingPart.anchorActor == 1 then
					jointNode = componentJoint.jointNodeActor1
				end

				local node = self.components[componentJoint.componentIndices[(foldingPart.anchorActor + 1) % 2 + 1]].node
				local x, y, z = localToWorld(jointNode, foldingPart.x, foldingPart.y, foldingPart.z)
				local upX, upY, upZ = localDirectionToWorld(jointNode, foldingPart.upX, foldingPart.upY, foldingPart.upZ)
				local dirX, dirY, dirZ = localDirectionToWorld(jointNode, foldingPart.dirX, foldingPart.dirY, foldingPart.dirZ)

				setWorldTranslation(node, x, y, z)
				I3DUtil.setWorldDirection(node, dirX, dirY, dirZ, upX, upY, upZ)
				self:setComponentJointFrame(componentJoint, foldingPart.anchorActor)
			end
		end
	end

	for _, vehicle in pairs(spec.subFoldingStateVehicles) do
		Foldable.setAnimTime(vehicle, animTime, placeComponents)
	end

	SpecializationUtil.raiseEvent(self, "onFoldTimeChanged", spec.foldAnimTime)
end

function Foldable:updateActionEventFold()
	local spec = self.spec_foldable
	local actionEvent = spec.actionEvents[spec.foldInputButton]

	if actionEvent ~= nil then
		local direction = self:getToggledFoldDirection()
		local text = nil

		if direction == spec.turnOnFoldDirection then
			text = spec.negDirectionText
		else
			text = spec.posDirectionText
		end

		g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
	end
end

function Foldable:updateActionEventFoldMiddle()
	local spec = self.spec_foldable
	local actionEvent = spec.actionEventsLowering[spec.foldMiddleInputButton]

	if actionEvent ~= nil then
		local state = self:getIsFoldMiddleAllowed()

		g_inputBinding:setActionEventActive(actionEvent.actionEventId, state)

		if state then
			local direction = self:getToggledFoldMiddleDirection() == spec.foldMiddleDirection

			if spec.ignoreFoldMiddleWhileFolded and spec.foldMiddleAnimTime < self:getFoldAnimTime() then
				direction = self:getIsLowered(true)
			end

			local text = nil

			if direction then
				text = spec.middlePosDirectionText
			else
				text = spec.middleNegDirectionText
			end

			g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
		end
	end
end

function Foldable:actionEventFold(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_foldable

	if #spec.foldingParts > 0 then
		local toggleDirection = self:getToggledFoldDirection()
		local allowed, warning = self:getIsFoldAllowed(toggleDirection, false)

		if allowed then
			if toggleDirection == spec.turnOnFoldDirection then
				self:setFoldState(toggleDirection, true)
			else
				self:setFoldState(toggleDirection, false)

				if self:getIsFoldMiddleAllowed() and self.getAttacherVehicle ~= nil then
					local attacherVehicle = self:getAttacherVehicle()
					local attacherJointIndex = attacherVehicle:getAttacherJointIndexFromObject(self)

					if attacherJointIndex ~= nil then
						local moveDown = attacherVehicle:getJointMoveDown(attacherJointIndex)
						local targetMoveDown = toggleDirection == spec.turnOnFoldDirection

						if targetMoveDown ~= moveDown then
							attacherVehicle:setJointMoveDown(attacherJointIndex, targetMoveDown)
						end
					end
				end
			end
		elseif warning ~= nil then
			g_currentMission:showBlinkingWarning(warning, 2000)
		end
	end
end

function Foldable:actionEventFoldMiddle(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_foldable

	if #spec.foldingParts > 0 and self:getIsFoldMiddleAllowed() then
		local ignoreFoldMiddle = false

		if spec.ignoreFoldMiddleWhileFolded and spec.foldMiddleAnimTime < self:getFoldAnimTime() then
			ignoreFoldMiddle = true
		end

		if not ignoreFoldMiddle then
			local direction = self:getToggledFoldMiddleDirection()

			if direction ~= 0 then
				if direction == spec.turnOnFoldDirection then
					self:setFoldState(direction, false)
				else
					self:setFoldState(direction, true)
				end

				if self.getAttacherVehicle ~= nil then
					local attacherVehicle = self:getAttacherVehicle()
					local attacherJointIndex = attacherVehicle:getAttacherJointIndexFromObject(self)

					if attacherJointIndex ~= nil then
						local moveDown = attacherVehicle:getJointMoveDown(attacherJointIndex)
						local targetMoveDown = direction == spec.turnOnFoldDirection

						if targetMoveDown ~= moveDown then
							attacherVehicle:setJointMoveDown(attacherJointIndex, targetMoveDown)
						end
					end
				end
			end
		else
			local attacherVehicle = self:getAttacherVehicle()

			if attacherVehicle ~= nil then
				attacherVehicle:handleLowerImplementEvent(self)
			end
		end
	end
end

function Foldable:actionEventFoldAll(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_foldable

	if #spec.foldingParts > 0 then
		local displayWarning = true
		local warningToDisplay = nil
		local toggleDirection = self:getToggledFoldDirection()
		local allowed, warning = self:getIsFoldAllowed(toggleDirection, false)

		if allowed then
			if toggleDirection == spec.turnOnFoldDirection then
				self:setFoldState(toggleDirection, true)
			else
				self:setFoldState(toggleDirection, false)
			end

			displayWarning = false
		elseif warning ~= nil then
			warningToDisplay = warning
		end

		local vehicles = self.rootVehicle:getChildVehicles()

		for i = 1, #vehicles do
			local vehicle = vehicles[i]

			if vehicle.setFoldState ~= nil then
				local spec2 = vehicle.spec_foldable
				local toggleDirection2 = vehicle:getToggledFoldDirection()
				local allowed2, warning2 = vehicle:getIsFoldAllowed(toggleDirection, false)

				if allowed2 then
					if toggleDirection == spec.turnOnFoldDirection == (toggleDirection2 == spec2.turnOnFoldDirection) then
						if toggleDirection2 == spec2.turnOnFoldDirection then
							vehicle:setFoldState(toggleDirection2, true)
						else
							vehicle:setFoldState(toggleDirection2, false)
						end

						displayWarning = false
					end
				elseif warning2 ~= nil then
					warningToDisplay = warning2
				end
			end
		end

		if displayWarning and warningToDisplay ~= nil then
			g_currentMission:showBlinkingWarning(warningToDisplay, 2000)
		end
	end
end
