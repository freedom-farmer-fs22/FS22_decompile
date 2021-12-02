source("dataS/scripts/vehicles/specializations/events/BaleLoaderStateEvent.lua")

BaleLoader = {
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(FillUnit, specializations)
	end
}

function BaleLoader.initSpecialization()
	g_storeManager:addSpecType("baleLoaderBaleSizeRound", "shopListAttributeIconBaleSizeRound", BaleLoader.loadSpecValueBaleSizeRound, BaleLoader.getSpecValueBaleSizeRound, "vehicle")
	g_storeManager:addSpecType("baleLoaderBaleSizeSquare", "shopListAttributeIconBaleSizeSquare", BaleLoader.loadSpecValueBaleSizeSquare, BaleLoader.getSpecValueBaleSizeSquare, "vehicle")

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("BaleLoader")
	schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#transportPosition", "Transport position text", "action_baleloaderTransportPosition")
	schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#operatingPosition", "Operating position text", "action_baleloaderOperatingPosition")
	schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#unload", "Unload text", "action_baleloaderUnload")
	schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#tilting", "Tilting text", "info_baleloaderTiltingTable")
	schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#lowering", "Lowering text", "info_baleloaderLoweringTable")
	schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#lowerPlattform", "Lower platform text", "action_baleloaderLowerPlatform")
	schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#abortUnloading", "Abort unloading text", "action_baleloaderAbortUnloading")
	schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#unloadHere", "Unload here text", "action_baleloaderUnloadHere")
	schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#baleNotSupported", "Bale not supported warning", "warning_baleNotSupported")
	schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#baleDoNotAllowFillTypeMixing", "Warning to be shown if the fill type is different from loaded fill types", "warning_baleDoNotAllowFillTypeMixing")
	schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#onlyOneBaleTypeWarning", "Warning to be shown if user tries to collect a different bale type as already loaded", "warning_baleLoaderOnlyAllowOnceSize")
	schema:register(XMLValueType.L10N_STRING, "vehicle.baleLoader.texts#minUnloadingFillLevelWarning", "Warning to be displayed if min fill level is not reached", "warning_baleLoaderNotFullyLoaded")
	BaleLoader.registerAnimationXMLPaths(schema, "vehicle.baleLoader")
	schema:register(XMLValueType.BOOL, "vehicle.baleLoader#transportPositionAfterUnloading", "Activate transport mode after unloading", true)
	schema:register(XMLValueType.BOOL, "vehicle.baleLoader#useBalePlaceAsLoadPosition", "Use bale place position as load position", false)
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader#balePlaceOffset", "Bale place offset", 0)
	schema:register(XMLValueType.BOOL, "vehicle.baleLoader#keepBaleRotationDuringLoad", "Keep the same bale rotation while loading bale", false)
	schema:register(XMLValueType.BOOL, "vehicle.baleLoader#automaticUnloading", "Automatically unload the bale loader if platform lifted", false)
	schema:register(XMLValueType.INT, "vehicle.baleLoader#minUnloadingFillLevel", "Min. fill level until unloading is allowed", 1)
	schema:register(XMLValueType.BOOL, "vehicle.baleLoader.dynamicMount#enabled", "Bales are dynamically mounted", false)
	schema:register(XMLValueType.BOOL, "vehicle.baleLoader.dynamicMount#doInterpolation", "Bale position is interpolated from bale origin position to grabber position", false)
	schema:register(XMLValueType.TIME, "vehicle.baleLoader.dynamicMount#interpolationTimeRot", "Time for bale rotation interpolation", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicMount#interpolationSpeedTrans", "Speed of translation interpolation (m/sec)", 0.1)
	schema:register(XMLValueType.VECTOR_TRANS, "vehicle.baleLoader.dynamicMount#minTransLimits", "Min translation limit")
	schema:register(XMLValueType.VECTOR_TRANS, "vehicle.baleLoader.dynamicMount#maxTransLimits", "Max translation limit")
	schema:register(XMLValueType.BOOL, "vehicle.baleLoader.dynamicBaleUnloading#enabled", "Bales are joint together during unloading")
	schema:register(XMLValueType.VECTOR_N, "vehicle.baleLoader.dynamicBaleUnloading#connectedRows", "Indices of rows that are connected together")
	schema:register(XMLValueType.STRING, "vehicle.baleLoader.dynamicBaleUnloading#interConnectedRowStarts", "Interconnections at row start between rows (e.g. '1-2 3-4')")
	schema:register(XMLValueType.STRING, "vehicle.baleLoader.dynamicBaleUnloading#interConnectedRowEnds", "Interconnections at row ends between rows (e.g. '1-2 3-4')")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicBaleUnloading#widthOffset", "Width offset")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicBaleUnloading#heightOffset", "Height offset")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicBaleUnloading#diameterOffset", "Diameter offset")
	schema:register(XMLValueType.ANGLE, "vehicle.baleLoader.dynamicBaleUnloading#rowConnectionRotLimit", "Rotation limit for row joints")
	schema:register(XMLValueType.ANGLE, "vehicle.baleLoader.dynamicBaleUnloading#rowInterConnectionRotLimit", "Rotation limit for inter row joints")
	schema:register(XMLValueType.STRING, "vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#name", "Reference animation to remove joints")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#time", "If animation time is higher than this time the joints will be removed", 1)
	schema:register(XMLValueType.BOOL, "vehicle.baleLoader.dynamicBaleUnloading.releaseAnimation#useUnloadingMoverTrigger", "Bale joints will be removed as soon all bales hast left the unloading mover trigger", false)
	schema:register(XMLValueType.INT, "vehicle.baleLoader#fillUnitIndex", "Fill unit index", 1)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.grabber#grabNode", "Grab node")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.grabber#pickupRange", "Pickup range", 3)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.grabber#triggerNode", "Trigger node")
	EffectManager.registerEffectXMLPaths(schema, "vehicle.baleLoader.grabber")
	schema:register(XMLValueType.TIME, "vehicle.baleLoader.grabber#effectDisableDuration", "Disable duration", 0.6)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.balePlaces#startBalePlace", "Start bale place node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.balePlaces.balePlace(?)#node", "Bale place node")
	schema:register(XMLValueType.STRING, "vehicle.baleLoader.foldingAnimations#baseAnimation", "Base animation name", "baleGrabberTransportToWork")
	schema:register(XMLValueType.STRING, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#name", "Animation name")
	schema:register(XMLValueType.INT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#baleTypeIndex", "Index of current bale type", "'0' - any bale type")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#minFillLevel", "Min. fill level to use this animation", "-inf")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#maxFillLevel", "Max. fill level to use this animation", "inf")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#minBalePlace", "Min. bales on platform to use this animation", "-inf")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.foldingAnimations.foldingAnimation(?)#maxBalePlace", "Max. bales on platform to use this animation", "inf")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.unloadingMoverNodes#trigger", "As long as bales are in this trigger the mover nodes are active and the player can not lower the platform")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.unloadingMoverNodes.unloadingMoverNode(?)#node", "Node that moves bales")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.unloadingMoverNodes.unloadingMoverNode(?)#speed", "Defines direction and speed of moving in X direction", -1)
	AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.baleLoader.unloadingMoverNodes.animationNodes")
	schema:register(XMLValueType.INT, "vehicle.baleLoader.synchronization#numBitsPosition", "Number of bits to synchronize bale positions", 10)
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.synchronization#maxPosition", "Max. position offset of bales from bale place in meter", 3)
	SoundManager.registerSampleXMLPaths(schema, "vehicle.baleLoader.sounds", "grab")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.baleLoader.sounds", "emptyRotate")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.baleLoader.sounds", "work")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.baleLoader.sounds", "unload")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#diameter", "Bale diameter")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#width", "Bale width")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#height", "Bale height")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#length", "Bale length")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#minDiameter", "Bale min diameter", "diameter value")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#maxDiameter", "Bale max diameter", "diameter value")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#minWidth", "Bale min width", "width value")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#maxWidth", "Bale max width", "width value")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#minHeight", "Bale min height", "height value")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#maxHeight", "Bale max height", "height value")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#minLength", "Bale min length", "length value")
	schema:register(XMLValueType.FLOAT, "vehicle.baleLoader.baleTypes.baleType(?)#maxLength", "Bale max length", "length value")
	schema:register(XMLValueType.INT, "vehicle.baleLoader.baleTypes.baleType(?)#fillUnitIndex", "Fill unit index", "baleLoader#fillUnitIndex")
	schema:register(XMLValueType.BOOL, "vehicle.baleLoader.baleTypes.baleType(?)#mixedFillTypes", "Allow loading of mixed fill types", true)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.baleTypes.baleType(?).balePlaces#startBalePlace", "Start bale place node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.baleTypes.baleType(?).balePlaces.balePlace(?)#node", "Bale place node")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.baleLoader.baleTypes.baleType(?)")
	BaleLoader.registerAnimationXMLPaths(schema, "vehicle.baleLoader.baleTypes.baleType(?)")
	AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.baleLoader.animationNodes")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.baleLoader.balePacker#node", "Node where to create the packed bale")
	schema:register(XMLValueType.STRING, "vehicle.baleLoader.balePacker#packedFilename", "Filename to packed bale")
	schema:addDelayedRegistrationFunc("AnimatedVehicle:part", function (cSchema, cKey)
		cSchema:register(XMLValueType.BOOL, cKey .. "#baleLoaderAnimationNodes", "Bale Loader animation nodes turn on/off")
	end)
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame

	schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).baleLoader#lastFoldingAnimation", "Last folding animation name")
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baleLoader#baleTypeIndex", "Last bale type index")
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).baleLoader#isInWorkPosition", "Is in working Position")
	schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).baleLoader.bale(?)#filename", "Filename")
	schemaSavegame:register(XMLValueType.VECTOR_TRANS, "vehicles.vehicle(?).baleLoader.bale(?)#position", "Position")
	schemaSavegame:register(XMLValueType.VECTOR_ROT, "vehicles.vehicle(?).baleLoader.bale(?)#rotation", "Rotation")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).baleLoader.bale(?)#fillLevel", "Filllevel")
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baleLoader.bale(?)#balePlace", "Bale place index")
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baleLoader.bale(?)#helper", "Helper index")
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).baleLoader.bale(?)#farmId", "Farm index")
	Bale.registerSavegameXMLPaths(schemaSavegame, "vehicles.vehicle(?).baleLoader.bale(?)")
end

function BaleLoader.registerAnimationXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".animations.platform#rotate", "Rotate platform animation name", "rotatePlatform")
	schema:register(XMLValueType.STRING, basePath .. ".animations.platform#rotateBack", "Rotate platform back animation name", "rotatePlatform")
	schema:register(XMLValueType.STRING, basePath .. ".animations.platform#rotateEmpty", "Rotate platform empty animation name", "rotatePlatform")
	schema:register(XMLValueType.BOOL, basePath .. ".animations.platform#allowPickupWhileMoving", "Allow pickup of next bale while platform is rotating", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".animations.baleGrabber#dropBaleReverseSpeed", "Speed of grabber in reverse", 5)
	schema:register(XMLValueType.STRING, basePath .. ".animations.baleGrabber#dropToWork", "Custom grabber animation when moving from drop to work")
	schema:register(XMLValueType.STRING, basePath .. ".animations.baleGrabber#workToDrop", "Bale grabber work to drop animation", "baleGrabberWorkToDrop")
	schema:register(XMLValueType.STRING, basePath .. ".animations.baleGrabber#dropBale", "Bale grabber drop bale animation", "baleGrabberDropBale")
	schema:register(XMLValueType.STRING, basePath .. ".animations.baleGrabber#transportToWork", "Transport to work animation", "baleGrabberTransportToWork")
	schema:register(XMLValueType.STRING, basePath .. ".animations.pusher#emptyHide", "Empty hide animation", "emptyHidePusher1")
	schema:register(XMLValueType.STRING, basePath .. ".animations.pusher#moveToEmpty", "Move to empty position", "moveBalePusherToEmpty")
	schema:register(XMLValueType.BOOL, basePath .. ".animations.pusher#hidePusherOnEmpty", "Reverse move to empty animation after execution", true)
	schema:register(XMLValueType.BOOL, basePath .. ".animations.pusher#pushBalesOnEmpty", "Defines if bale are pushed or pulled on empty", false)
	schema:register(XMLValueType.STRING, basePath .. ".animations.releaseFrontPlatform#name", "Release front platform animation name", "releaseFrontplattform")
	schema:register(XMLValueType.BOOL, basePath .. ".animations.releaseFrontPlatform#fillLevelSpeed", "Front platform speed is dependent on fill level", false)
	schema:register(XMLValueType.STRING, basePath .. ".animations.moveBalePlaces#name", "Move bale places animation", "moveBalePlaces")
	schema:register(XMLValueType.STRING, basePath .. ".animations.moveBalePlaces#extrasOnce", "Move bale places extra once animation", "moveBalePlaces")
	schema:register(XMLValueType.STRING, basePath .. ".animations.moveBalePlaces#empty", "Move bale places empty animation", "moveBalePlaces")
	schema:register(XMLValueType.FLOAT, basePath .. ".animations.moveBalePlaces#emptySpeed", "Speed of move bale places to empty", 1.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".animations.moveBalePlaces#emptyReverseSpeed", "Reverse speed of move bale places to empty", -1)
	schema:register(XMLValueType.FLOAT, basePath .. ".animations.moveBalePlaces#pushOffset", "Delay of empty animation to give pusher time to move to the last bale", 0)
	schema:register(XMLValueType.BOOL, basePath .. ".animations.moveBalePlaces#moveAfterRotatePlatform", "Move bale places after rotate platform", false)
	schema:register(XMLValueType.BOOL, basePath .. ".animations.moveBalePlaces#resetOnSink", "Reset move bale places on platform sink", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".animations.moveBalePlaces#maxGrabberTime", "Max. grabber time to move bale places", "inf")
	schema:register(XMLValueType.BOOL, basePath .. ".animations.moveBalePlaces#alwaysMove", "Always move bale places", false)
	schema:register(XMLValueType.STRING, basePath .. ".animations.emptyRotate#name", "Empty rotate", "emptyRotate")
	schema:register(XMLValueType.BOOL, basePath .. ".animations.emptyRotate#reset", "Reset empty rotate animation", true)
	schema:register(XMLValueType.STRING, basePath .. ".animations#frontBalePusher", "Front bale pusher animation", "frontBalePusher")
	schema:register(XMLValueType.STRING, basePath .. ".animations#balesToOtherRow", "Bales to othe row animation", "balesToOtherRow")
	schema:register(XMLValueType.STRING, basePath .. ".animations#closeGrippers", "Close grippers animation", "closeGrippers")
end

BaleLoader.GRAB_MOVE_UP = 1
BaleLoader.GRAB_MOVE_DOWN = 2
BaleLoader.GRAB_DROP_BALE = 3
BaleLoader.EMPTY_NONE = 1
BaleLoader.EMPTY_TO_WORK = 2
BaleLoader.EMPTY_ROTATE_PLATFORM = 3
BaleLoader.EMPTY_ROTATE1 = 4
BaleLoader.EMPTY_CLOSE_GRIPPERS = 5
BaleLoader.EMPTY_HIDE_PUSHER1 = 6
BaleLoader.EMPTY_HIDE_PUSHER2 = 7
BaleLoader.EMPTY_ROTATE2 = 8
BaleLoader.EMPTY_WAIT_TO_DROP = 9
BaleLoader.EMPTY_WAIT_TO_SINK = 10
BaleLoader.EMPTY_SINK = 11
BaleLoader.EMPTY_CANCEL = 12
BaleLoader.EMPTY_WAIT_TO_REDO = 13
BaleLoader.CHANGE_DROP_BALES = 1
BaleLoader.CHANGE_SINK = 2
BaleLoader.CHANGE_EMPTY_REDO = 3
BaleLoader.CHANGE_EMPTY_START = 4
BaleLoader.CHANGE_EMPTY_CANCEL = 5
BaleLoader.CHANGE_MOVE_TO_WORK = 6
BaleLoader.CHANGE_MOVE_TO_TRANSPORT = 7
BaleLoader.CHANGE_GRAB_BALE = 8
BaleLoader.CHANGE_GRAB_MOVE_UP = 9
BaleLoader.CHANGE_GRAB_DROP_BALE = 10
BaleLoader.CHANGE_GRAB_MOVE_DOWN = 11
BaleLoader.CHANGE_FRONT_PUSHER = 12
BaleLoader.CHANGE_ROTATE_PLATFORM = 13
BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM = 14
BaleLoader.CHANGE_EMPTY_ROTATE1 = 15
BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS = 16
BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1 = 17
BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2 = 18
BaleLoader.CHANGE_EMPTY_ROTATE2 = 19
BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP = 20
BaleLoader.CHANGE_EMPTY_STATE_NIL = 21
BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO = 22
BaleLoader.CHANGE_BUTTON_EMPTY = 23
BaleLoader.CHANGE_BUTTON_EMPTY_ABORT = 24
BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT = 25

function BaleLoader.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadBaleTypeFromXML", BaleLoader.loadBaleTypeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadBalePlacesFromXML", BaleLoader.loadBalePlacesFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadBaleLoaderAnimationsFromXML", BaleLoader.loadBaleLoaderAnimationsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "createBaleToBaleJoints", BaleLoader.createBaleToBaleJoints)
	SpecializationUtil.registerFunction(vehicleType, "createBaleToBaleJoint", BaleLoader.createBaleToBaleJoint)
	SpecializationUtil.registerFunction(vehicleType, "doStateChange", BaleLoader.doStateChange)
	SpecializationUtil.registerFunction(vehicleType, "getBaleGrabberDropBaleAnimName", BaleLoader.getBaleGrabberDropBaleAnimName)
	SpecializationUtil.registerFunction(vehicleType, "getIsBaleGrabbingAllowed", BaleLoader.getIsBaleGrabbingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "pickupBale", BaleLoader.pickupBale)
	SpecializationUtil.registerFunction(vehicleType, "setBaleLoaderBaleType", BaleLoader.setBaleLoaderBaleType)
	SpecializationUtil.registerFunction(vehicleType, "getBaleTypeByBale", BaleLoader.getBaleTypeByBale)
	SpecializationUtil.registerFunction(vehicleType, "baleGrabberTriggerCallback", BaleLoader.baleGrabberTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "baleLoaderMoveTriggerCallback", BaleLoader.baleLoaderMoveTriggerCallback)
	SpecializationUtil.registerFunction(vehicleType, "mountDynamicBale", BaleLoader.mountDynamicBale)
	SpecializationUtil.registerFunction(vehicleType, "unmountDynamicBale", BaleLoader.unmountDynamicBale)
	SpecializationUtil.registerFunction(vehicleType, "mountBale", BaleLoader.mountBale)
	SpecializationUtil.registerFunction(vehicleType, "unmountBale", BaleLoader.unmountBale)
	SpecializationUtil.registerFunction(vehicleType, "setBalePairCollision", BaleLoader.setBalePairCollision)
	SpecializationUtil.registerFunction(vehicleType, "getLoadedBales", BaleLoader.getLoadedBales)
	SpecializationUtil.registerFunction(vehicleType, "startAutomaticBaleUnloading", BaleLoader.startAutomaticBaleUnloading)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticBaleUnloadingInProgress", BaleLoader.getIsAutomaticBaleUnloadingInProgress)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticBaleUnloadingAllowed", BaleLoader.getIsAutomaticBaleUnloadingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "playBaleLoaderFoldingAnimation", BaleLoader.playBaleLoaderFoldingAnimation)
	SpecializationUtil.registerFunction(vehicleType, "getIsBaleLoaderFoldingPlaying", BaleLoader.getIsBaleLoaderFoldingPlaying)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentFoldingAnimation", BaleLoader.getCurrentFoldingAnimation)
	SpecializationUtil.registerFunction(vehicleType, "updateFoldingAnimation", BaleLoader.updateFoldingAnimation)
	SpecializationUtil.registerFunction(vehicleType, "onBaleMoverBaleRemoved", BaleLoader.onBaleMoverBaleRemoved)
end

function BaleLoader.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", BaleLoader.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowDynamicMountFillLevelInfo", BaleLoader.getAllowDynamicMountFillLevelInfo)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addNodeObjectMapping", BaleLoader.addNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeNodeObjectMapping", BaleLoader.removeNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", BaleLoader.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIReadyToDrive", BaleLoader.getIsAIReadyToDrive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIPreparingToDrive", BaleLoader.getIsAIPreparingToDrive)
end

function BaleLoader.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onActivate", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", BaleLoader)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", BaleLoader)
end

function BaleLoader:onLoad(savegame)
	local spec = self.spec_baleLoader

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleloaderTurnedOnScrollers.baleloaderTurnedOnScroller", "vehicle.baleLoader.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleGrabber", "vehicle.baleLoader.grabber")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.balePlaces", "vehicle.baleLoader.balePlaces")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.grabParticleSystem", "vehicle.baleLoader.grabber.grabParticleSystem")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.grabber.grabParticleSystem", "vehicle.baleLoader.grabber.effectNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#pickupRange", "vehicle.baleLoader.grabber#pickupRange")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleTypes", "vehicle.baleLoader.baleTypes")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textTransportPosition", "vehicle.baleLoader.texts#transportPosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textOperatingPosition", "vehicle.baleLoader.texts#operatingPosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textUnload", "vehicle.baleLoader.texts#unload")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textTilting", "vehicle.baleLoader.texts#tilting")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textLowering", "vehicle.baleLoader.texts#lowering")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textLowerPlattform", "vehicle.baleLoader.texts#lowerPlattform")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textAbortUnloading", "vehicle.baleLoader.texts#abortUnloading")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#textUnloadHere", "vehicle.baleLoader.texts#unloadHere")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#rotatePlatformAnimName", "vehicle.baleLoader.animations#rotatePlatform")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#rotatePlatformBackAnimName", "vehicle.baleLoader.animations#rotatePlatformBack")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#rotatePlatformEmptyAnimName", "vehicle.baleLoader.animations#rotatePlatformEmpty")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#grabberDropBaleReverseSpeed", "vehicle.baleLoader.animations.baleGrabber#dropBaleReverseSpeed")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#grabberDropToWork", "vehicle.baleLoader.animations.baleGrabber#dropToWork")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#rotatePlatform", "vehicle.baleLoader.animations.platform#rotate")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#rotatePlatformBack", "vehicle.baleLoader.animations.platform#rotateBack")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader.animations#rotatePlatformEmpty", "vehicle.baleLoader.animations.platform#rotateEmpty")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#moveBalePlacesAfterRotatePlatform", "vehicle.baleLoader.animations.moveBalePlaces#moveAfterRotatePlatform")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#moveBalePlacesMaxGrabberTime", "vehicle.baleLoader.animations.moveBalePlaces#maxGrabberTime")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#alwaysMoveBalePlaces", "vehicle.baleLoader.animations.moveBalePlaces#alwaysMove")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.baleLoader#resetEmptyRotateAnimation", "vehicle.baleLoader.animations.emptyRotate#reset")

	local baseKey = "vehicle.baleLoader"
	spec.balesToLoad = {}
	spec.balesToMount = {}
	spec.isInWorkPosition = false
	spec.grabberIsMoving = false
	spec.rotatePlatformDirection = 0
	spec.frontBalePusherDirection = 0
	spec.emptyState = BaleLoader.EMPTY_NONE
	spec.texts = {
		transportPosition = self.xmlFile:getValue(baseKey .. ".texts#transportPosition", "action_baleloaderTransportPosition", nil, self.customEnvironment),
		operatingPosition = self.xmlFile:getValue(baseKey .. ".texts#operatingPosition", "action_baleloaderOperatingPosition", nil, self.customEnvironment),
		unload = self.xmlFile:getValue(baseKey .. ".texts#unload", "action_baleloaderUnload", nil, self.customEnvironment),
		tilting = self.xmlFile:getValue(baseKey .. ".texts#tilting", "info_baleloaderTiltingTable", nil, self.customEnvironment),
		lowering = self.xmlFile:getValue(baseKey .. ".texts#lowering", "info_baleloaderLoweringTable", nil, self.customEnvironment),
		lowerPlattform = self.xmlFile:getValue(baseKey .. ".texts#lowerPlattform", "action_baleloaderLowerPlatform", nil, self.customEnvironment),
		abortUnloading = self.xmlFile:getValue(baseKey .. ".texts#abortUnloading", "action_baleloaderAbortUnloading", nil, self.customEnvironment),
		unloadHere = self.xmlFile:getValue(baseKey .. ".texts#unloadHere", "action_baleloaderUnloadHere", nil, self.customEnvironment),
		baleNotSupported = self.xmlFile:getValue(baseKey .. ".texts#baleNotSupported", "warning_baleNotSupported", nil, self.customEnvironment),
		baleDoNotAllowFillTypeMixing = self.xmlFile:getValue(baseKey .. ".texts#baleDoNotAllowFillTypeMixing", "warning_baleDoNotAllowFillTypeMixing", nil, self.customEnvironment),
		onlyOneBaleTypeWarning = self.xmlFile:getValue(baseKey .. ".texts#onlyOneBaleTypeWarning", "warning_baleLoaderOnlyAllowOnceSize", nil, self.customEnvironment),
		minUnloadingFillLevelWarning = self.xmlFile:getValue(baseKey .. ".texts#minUnloadingFillLevelWarning", "warning_baleLoaderNotFullyLoaded", nil, self.customEnvironment),
		youDoNotOwnBale = g_i18n:getText("warning_youDontOwnThisItem")
	}
	spec.transportPositionAfterUnloading = self.xmlFile:getValue(baseKey .. "#transportPositionAfterUnloading", true)
	spec.useBalePlaceAsLoadPosition = self.xmlFile:getValue(baseKey .. "#useBalePlaceAsLoadPosition", false)
	spec.balePlaceOffset = self.xmlFile:getValue(baseKey .. "#balePlaceOffset", 0)
	spec.keepBaleRotationDuringLoad = self.xmlFile:getValue(baseKey .. "#keepBaleRotationDuringLoad", false)
	spec.automaticUnloading = self.xmlFile:getValue(baseKey .. "#automaticUnloading", false)
	spec.minUnloadingFillLevel = self.xmlFile:getValue(baseKey .. "#minUnloadingFillLevel", 1)
	spec.fillUnitIndex = self.xmlFile:getValue(baseKey .. "#fillUnitIndex", 1)
	spec.dynamicMount = {
		enabled = self.xmlFile:getValue(baseKey .. ".dynamicMount#enabled", false),
		jointInterpolation = self.xmlFile:getValue(baseKey .. ".dynamicMount#doInterpolation", false),
		jointInterpolationTimeRot = self.xmlFile:getValue(baseKey .. ".dynamicMount#interpolationTimeRot", 1),
		jointInterpolationSpeedTrans = self.xmlFile:getValue(baseKey .. ".dynamicMount#interpolationSpeedTrans", 0.1) / 1000,
		baleJointsToUpdate = {},
		minTransLimits = self.xmlFile:getValue(baseKey .. ".dynamicMount#minTransLimits", nil, true),
		maxTransLimits = self.xmlFile:getValue(baseKey .. ".dynamicMount#maxTransLimits", nil, true),
		baleMassDirty = false
	}
	spec.dynamicBaleUnloading = {
		enabled = self.xmlFile:getValue(baseKey .. ".dynamicBaleUnloading#enabled", false),
		connectedRows = {}
	}
	local connectedRows = self.xmlFile:getValue(baseKey .. ".dynamicBaleUnloading#connectedRows", nil, true)

	if connectedRows ~= nil then
		for i = 1, #connectedRows do
			spec.dynamicBaleUnloading.connectedRows[connectedRows[i]] = true
		end
	end

	local function getConnectedRows(key)
		local connections = {}
		local connectedRowStartsStr = self.xmlFile:getValue(key)
		local connectedRowStartsParts = string.split(connectedRowStartsStr, " ")

		for i = 1, #connectedRowStartsParts do
			local subParts = string.split(connectedRowStartsParts[i], "-")

			if #subParts ~= 2 then
				Logging.xmlWarning(self.xmlFile, "Unknown row connection '%s' in '%s' (should look like '1-2 3-4')", connectedRowStartsParts[i], key)
			else
				table.insert(connections, {
					tonumber(subParts[1]),
					tonumber(subParts[2])
				})
			end
		end

		return connections
	end

	spec.dynamicBaleUnloading.interConnectedRowStarts = getConnectedRows(baseKey .. ".dynamicBaleUnloading#interConnectedRowStarts")
	spec.dynamicBaleUnloading.interConnectedRowEnds = getConnectedRows(baseKey .. ".dynamicBaleUnloading#interConnectedRowEnds")
	spec.dynamicBaleUnloading.widthOffset = self.xmlFile:getValue(baseKey .. ".dynamicBaleUnloading#widthOffset", 0.05)
	spec.dynamicBaleUnloading.heightOffset = self.xmlFile:getValue(baseKey .. ".dynamicBaleUnloading#heightOffset", 0.05)
	spec.dynamicBaleUnloading.diameterOffset = self.xmlFile:getValue(baseKey .. ".dynamicBaleUnloading#diameterOffset", 0.05)
	spec.dynamicBaleUnloading.rowConnectionRotLimit = self.xmlFile:getValue(baseKey .. ".dynamicBaleUnloading#rowConnectionRotLimit", 4)
	spec.dynamicBaleUnloading.rowInterConnectionRotLimit = self.xmlFile:getValue(baseKey .. ".dynamicBaleUnloading#rowInterConnectionRotLimit", 1)
	spec.dynamicBaleUnloading.releaseAnimation = self.xmlFile:getValue(baseKey .. ".dynamicBaleUnloading.releaseAnimation#name")
	spec.dynamicBaleUnloading.releaseAnimationTime = self.xmlFile:getValue(baseKey .. ".dynamicBaleUnloading.releaseAnimation#time", 1)
	spec.dynamicBaleUnloading.useUnloadingMoverTrigger = self.xmlFile:getValue(baseKey .. ".dynamicBaleUnloading.releaseAnimation#useUnloadingMoverTrigger", false)
	spec.baleGrabber = {
		grabNode = self.xmlFile:getValue(baseKey .. ".grabber#grabNode", nil, self.components, self.i3dMappings),
		pickupRange = self.xmlFile:getValue(baseKey .. ".grabber#pickupRange", 3),
		balesInTrigger = {},
		trigger = self.xmlFile:getValue(baseKey .. ".grabber#triggerNode", nil, self.components, self.i3dMappings)
	}

	if spec.baleGrabber.trigger ~= nil then
		addTrigger(spec.baleGrabber.trigger, "baleGrabberTriggerCallback", self)
	else
		Logging.xmlError(self.xmlFile, "Bale grabber needs a valid trigger!")
	end

	if self.isClient then
		local grabParticleSystem = {}
		local psName = baseKey .. ".grabber.grabParticleSystem"

		if ParticleUtil.loadParticleSystem(self.xmlFile, grabParticleSystem, psName, self.components, false, nil, self.baseDirectory) then
			spec.grabParticleSystem = grabParticleSystem
			spec.grabParticleSystemDisableTime = 0
		end

		spec.grabberEffects = g_effectManager:loadEffect(self.xmlFile, baseKey .. ".grabber", self.components, self, self.i3dMappings)
		spec.grabberEffectDisableDuration = self.xmlFile:getValue(baseKey .. ".grabber#effectDisableDuration", 0.6)
		spec.grabberEffectDisableTime = 0
		spec.samples = {
			grab = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "grab", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			emptyRotate = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "emptyRotate", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			work = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			unload = g_soundManager:loadSampleFromXML(self.xmlFile, baseKey .. ".sounds", "unload", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end

	spec.defaultAnimations = {}

	self:loadBaleLoaderAnimationsFromXML(self.xmlFile, baseKey, spec.defaultAnimations)

	spec.animations = spec.defaultAnimations.animations
	spec.defaultBalePlace = {}
	spec.useSharedBalePlaces = false

	if self:loadBalePlacesFromXML(self.xmlFile, baseKey, spec.defaultBalePlace) then
		spec.useSharedBalePlaces = true
	end

	spec.startBalePlace = spec.defaultBalePlace.startBalePlace
	spec.balePlaces = spec.defaultBalePlace.balePlaces
	spec.baleTypes = {}
	local i = 0

	while true do
		local baleTypeKey = string.format("%s.baleTypes.baleType(%d)", baseKey, i)

		if not self.xmlFile:hasProperty(baleTypeKey) then
			break
		end

		local entry = {}

		if self:loadBaleTypeFromXML(self.xmlFile, baleTypeKey, entry) then
			entry.index = i + 1

			table.insert(spec.baleTypes, entry)
		end

		i = i + 1
	end

	if #spec.baleTypes == 0 then
		Logging.xmlError(self.xmlFile, "No bale types defined for baleLoader!")
	else
		if spec.startBalePlace == nil then
			spec.startBalePlace = spec.baleTypes[1].startBalePlace
		end

		if spec.balePlaces == nil then
			spec.balePlaces = spec.baleTypes[1].balePlaces
		end

		if spec.startBalePlace == nil then
			Logging.xmlError(self.xmlFile, "Could not find startBalePlace for baleLoader!")
		end

		if spec.balePlaces == nil then
			Logging.xmlError(self.xmlFile, "Could not find bale places for baleLoader!")
		end
	end

	self:setBaleLoaderBaleType(1)

	spec.foldingAnimations = {}
	i = 0

	while true do
		local animationKey = string.format("%s.foldingAnimations.foldingAnimation(%d)", baseKey, i)

		if not self.xmlFile:hasProperty(animationKey) then
			break
		end

		local animation = {
			name = self.xmlFile:getValue(animationKey .. "#name"),
			baleTypeIndex = self.xmlFile:getValue(animationKey .. "#baleTypeIndex", 0),
			minFillLevel = self.xmlFile:getValue(animationKey .. "#minFillLevel", -math.huge),
			maxFillLevel = self.xmlFile:getValue(animationKey .. "#maxFillLevel", math.huge),
			minBalePlace = self.xmlFile:getValue(animationKey .. "#minBalePlace", -math.huge),
			maxBalePlace = self.xmlFile:getValue(animationKey .. "#maxBalePlace", math.huge)
		}

		if self:getAnimationExists(animation.name) then
			table.insert(spec.foldingAnimations, animation)
		else
			Logging.xmlWarning(self.xmlFile, "Unknown folding animation '%s' in '%s'", animation.name, animationKey)
		end

		i = i + 1
	end

	spec.hasMultipleFoldingAnimations = #spec.foldingAnimations > 0
	spec.lastFoldingAnimation = spec.animations.baleGrabberTransportToWork

	self:updateFoldingAnimation()

	spec.unloadingMover = {
		trigger = self.xmlFile:getValue(baseKey .. ".unloadingMoverNodes#trigger", nil, self.components, self.i3dMappings)
	}

	if spec.unloadingMover.trigger ~= nil then
		addTrigger(spec.unloadingMover.trigger, "baleLoaderMoveTriggerCallback", self)
	end

	spec.unloadingMover.isActive = false
	spec.unloadingMover.dirtyFlag = self:getNextDirtyFlag()
	spec.unloadingMover.frameDelay = 0
	spec.unloadingMover.balesInTrigger = {}
	spec.unloadingMover.nodes = {}
	spec.unloadingMover.animationNodes = g_animationManager:loadAnimations(self.xmlFile, baseKey .. ".unloadingMoverNodes.animationNodes", self.components, self, self.i3dMappings)
	i = 0

	while true do
		local moverKey = string.format("%s.unloadingMoverNodes.unloadingMoverNode(%d)", baseKey, i)

		if not self.xmlFile:hasProperty(moverKey) then
			break
		end

		local entry = {
			node = self.xmlFile:getValue(moverKey .. "#node", nil, self.components, self.i3dMappings),
			speed = self.xmlFile:getValue(moverKey .. "#speed", -1)
		}

		if entry.node ~= nil then
			table.insert(spec.unloadingMover.nodes, entry)
		else
			Logging.xmlWarning(self.xmlFile, "Unknown node in '%s'", moverKey)
		end

		i = i + 1
	end

	spec.balePacker = {
		node = self.xmlFile:getValue(baseKey .. ".balePacker#node", nil, self.components, self.i3dMappings),
		filename = self.xmlFile:getValue(baseKey .. ".balePacker#packedFilename")
	}

	if spec.balePacker.filename ~= nil then
		spec.balePacker.filename = Utils.getFilename(spec.balePacker.filename, self.baseDirectory)

		if spec.balePacker.filename ~= nil and not fileExists(spec.balePacker.filename) then
			Logging.xmlError(self.xmlFile, "Unable to find packed bale '%s'", spec.balePacker.filename)
		end
	end

	spec.synchronizationNumBitsPosition = self.xmlFile:getValue(baseKey .. ".synchronization#numBitsPosition", 10)
	spec.synchronizationMaxPosition = self.xmlFile:getValue(baseKey .. ".synchronization#maxPosition", 3)
	spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, baseKey .. ".animationNodes", self.components, self, self.i3dMappings)
	spec.animationNodesBlocked = false
	spec.showBaleNotSupportedWarning = false
	spec.baleNotSupportedWarning = nil
	spec.automaticUnloadingInProgress = false
	spec.lastPickupAutomatedUnloadingDelayTime = 15000
	spec.lastPickupTime = -spec.lastPickupAutomatedUnloadingDelayTime
	spec.kinematicMountedBales = {}
	spec.baleJoints = {}
end

function BaleLoader:onPostLoad(savegame)
	if savegame ~= nil then
		local spec = self.spec_baleLoader
		local baleTypeIndex = savegame.xmlFile:getValue(savegame.key .. ".baleLoader#baleTypeIndex")

		if baleTypeIndex ~= nil then
			self:setBaleLoaderBaleType(baleTypeIndex, true)
		end

		if spec.hasMultipleFoldingAnimations and not savegame.resetVehicles then
			spec.lastFoldingAnimation = savegame.xmlFile:getValue(savegame.key .. ".baleLoader#lastFoldingAnimation", spec.lastFoldingAnimation)
		end

		if savegame.xmlFile:getValue(savegame.key .. ".baleLoader#isInWorkPosition", false) then
			if not spec.isInWorkPosition then
				spec.grabberIsMoving = true
				spec.isInWorkPosition = true

				BaleLoader.moveToWorkPosition(self, true)
			end
		else
			BaleLoader.moveToTransportPosition(self)
		end

		spec.startBalePlace.current = 1
		spec.startBalePlace.count = 0
		local numBales = 0

		if not savegame.resetVehicles then
			local i = 0

			while true do
				local baleKey = savegame.key .. string.format(".baleLoader.bale(%d)", i)

				if not savegame.xmlFile:hasProperty(baleKey) then
					break
				end

				local filename = savegame.xmlFile:getValue(baleKey .. "#filename")

				if filename ~= nil then
					filename = NetworkUtil.convertFromNetworkFilename(filename)
					local x, y, z = savegame.xmlFile:getValue(baleKey .. "#position")
					local xRot, yRot, zRot = savegame.xmlFile:getValue(baleKey .. "#rotation")
					local balePlace = savegame.xmlFile:getValue(baleKey .. "#balePlace")
					local helper = savegame.xmlFile:getValue(baleKey .. "#helper")

					if balePlace == nil or balePlace > 0 and (x == nil or y == nil or z == nil or xRot == nil or yRot == nil or zRot == nil) or balePlace < 1 and helper == nil then
						print("Warning: Corrupt savegame, bale " .. filename .. " could not be loaded")
					else
						local translation, rotation = nil

						if balePlace > 0 then
							translation = {
								x,
								y,
								z
							}
							rotation = {
								xRot,
								yRot,
								zRot
							}
						else
							translation = {
								0,
								0,
								0
							}
							rotation = {
								0,
								0,
								0
							}
						end

						local parentNode, bales = nil

						if balePlace < 1 then
							if spec.startBalePlace.node ~= nil and helper <= spec.startBalePlace.numOfPlaces then
								parentNode = getChildAt(spec.startBalePlace.node, helper - 1)

								if spec.startBalePlace.bales == nil then
									spec.startBalePlace.bales = {}
								end

								bales = spec.startBalePlace.bales
								spec.startBalePlace.count = spec.startBalePlace.count + 1
							end
						elseif balePlace <= table.getn(spec.balePlaces) then
							spec.startBalePlace.current = math.max(spec.startBalePlace.current, balePlace + 1)
							parentNode = spec.balePlaces[balePlace].node

							if spec.balePlaces[balePlace].bales == nil then
								spec.balePlaces[balePlace].bales = {}
							end

							bales = spec.balePlaces[balePlace].bales
						end

						if parentNode ~= nil then
							local attributes = {}

							Bale.loadBaleAttributesFromXMLFile(attributes, savegame.xmlFile, baleKey, savegame.resetVehicles)

							numBales = numBales + 1

							table.insert(spec.balesToLoad, {
								parentNode = parentNode,
								filename = filename,
								bales = bales,
								translation = translation,
								rotation = rotation,
								attributes = attributes
							})
						end
					end
				end

				i = i + 1
			end
		end

		self:updateFoldingAnimation()
		BaleLoader.updateBalePlacesAnimations(self)
	end
end

function BaleLoader:onLoadFinished(savegame)
	local spec = self.spec_baleLoader

	for k, v in pairs(spec.balesToLoad) do
		local baleObject = Bale.new(self.isServer, self.isClient)
		local x, y, z = unpack(v.translation)
		local rx, ry, rz = unpack(v.rotation)

		if baleObject:loadFromConfigXML(v.filename, x, y, z, rx, ry, rz) then
			baleObject:applyBaleAttributes(v.attributes)
			baleObject:register()

			if spec.dynamicMount.enabled then
				self:mountDynamicBale(baleObject, v.parentNode)
			else
				self:mountBale(baleObject, self, v.parentNode, x, y, z, rx, ry, rz)
			end

			baleObject:setCanBeSold(false)
			table.insert(v.bales, NetworkUtil.getObjectId(baleObject))
		end

		spec.balesToLoad[k] = nil
	end
end

function BaleLoader:onDelete()
	local spec = self.spec_baleLoader

	if spec.balePlaces ~= nil then
		for _, balePlace in pairs(spec.balePlaces) do
			if balePlace.bales ~= nil then
				for _, baleServerId in pairs(balePlace.bales) do
					local bale = NetworkUtil.getObject(baleServerId)

					if bale ~= nil then
						if spec.dynamicMount.enabled then
							self:unmountDynamicBale(bale)
						else
							self:unmountBale(bale)
						end

						bale:setCanBeSold(true)

						if self.isReconfigurating ~= nil and self.isReconfigurating then
							bale:delete()
						end
					end
				end
			end
		end
	end

	if spec.startBalePlace ~= nil then
		for _, baleServerId in ipairs(spec.startBalePlace.bales) do
			local bale = NetworkUtil.getObject(baleServerId)

			if bale ~= nil then
				if spec.dynamicMount.enabled then
					self:unmountDynamicBale(bale)
				else
					self:unmountBale(bale)
				end

				bale:setCanBeSold(true)

				if self.isReconfigurating ~= nil and self.isReconfigurating then
					bale:delete()
				end
			end
		end
	end

	if spec.baleGrabber ~= nil then
		if spec.baleGrabber.currentBale ~= nil then
			local bale = NetworkUtil.getObject(spec.baleGrabber.currentBale)

			if bale ~= nil then
				if spec.dynamicMount.enabled then
					self:unmountDynamicBale(bale)
				else
					self:unmountBale(bale)
				end

				bale:setCanBeSold(true)
			end
		end

		if spec.baleGrabber.trigger ~= nil then
			removeTrigger(spec.baleGrabber.trigger)
		end
	end

	if spec.unloadingMover ~= nil then
		if spec.unloadingMover.trigger ~= nil then
			removeTrigger(spec.unloadingMover.trigger)
		end

		g_animationManager:deleteAnimations(spec.unloadingMover.animationNodes)
	end

	g_effectManager:deleteEffects(spec.grabberEffects)
	g_soundManager:deleteSamples(spec.samples)
	g_animationManager:deleteAnimations(spec.animationNodes)
end

function BaleLoader:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_baleLoader

	xmlFile:setValue(key .. "#isInWorkPosition", spec.isInWorkPosition)

	if spec.currentBaleType ~= nil then
		xmlFile:setValue(key .. "#baleTypeIndex", spec.currentBaleType.index)
	end

	local baleIndex = 0

	for i, balePlace in pairs(spec.balePlaces) do
		if balePlace.bales ~= nil then
			for _, baleServerId in pairs(balePlace.bales) do
				local bale = NetworkUtil.getObject(baleServerId)

				if bale ~= nil then
					local baleKey = string.format("%s.bale(%d)", key, baleIndex)

					bale:saveToXMLFile(xmlFile, baleKey)

					local startBaleEmpty = table.getn(spec.startBalePlace.bales) == 0
					local loadPlaceEmpty = self:getFillUnitFillLevel(spec.fillUnitIndex) % spec.startBalePlace.numOfPlaces ~= 0
					local lastItem = math.floor(self:getFillUnitFillLevel(spec.fillUnitIndex) / spec.startBalePlace.numOfPlaces) + 1 == i
					local evenCapacity = self:getFillUnitCapacity(spec.fillUnitIndex) % 2 == 0

					if startBaleEmpty and loadPlaceEmpty and lastItem and evenCapacity then
						xmlFile:setValue(baleKey .. "#balePlace", 0)
						xmlFile:setValue(baleKey .. "#helper", 1)
					else
						xmlFile:setValue(baleKey .. "#balePlace", i)
					end

					baleIndex = baleIndex + 1
				end
			end
		end
	end

	for i, baleServerId in ipairs(spec.startBalePlace.bales) do
		local bale = NetworkUtil.getObject(baleServerId)

		if bale ~= nil then
			local baleKey = string.format("%s.bale(%d)", key, baleIndex)

			bale:saveToXMLFile(xmlFile, baleKey)
			xmlFile:setValue(baleKey .. "#balePlace", 0)
			xmlFile:setValue(baleKey .. "#helper", i)

			baleIndex = baleIndex + 1
		end
	end

	if spec.hasMultipleFoldingAnimations and spec.lastFoldingAnimation ~= nil then
		xmlFile:setValue(key .. "#lastFoldingAnimation", spec.lastFoldingAnimation)
	end

	if spec.baleGrabber.currentBale ~= nil then
		local bale = NetworkUtil.getObject(spec.baleGrabber.currentBale)

		if bale ~= nil then
			self:unmountBale(bale)

			spec.baleGrabber.currentBaleIsUnmounted = true
		end
	end
end

function BaleLoader:onReadStream(streamId, connection)
	local spec = self.spec_baleLoader
	spec.isInWorkPosition = streamReadBool(streamId)
	spec.frontBalePusherDirection = streamReadIntN(streamId, 3)
	spec.rotatePlatformDirection = streamReadIntN(streamId, 3)

	if spec.isInWorkPosition then
		BaleLoader.moveToWorkPosition(self)
	end

	local emptyState = streamReadUIntN(streamId, 4)
	spec.startBalePlace.current = streamReadInt8(streamId)

	if streamReadBool(streamId) then
		spec.baleGrabber.currentBale = NetworkUtil.readNodeObjectId(streamId)
		spec.balesToMount[spec.baleGrabber.currentBale] = {
			serverId = spec.baleGrabber.currentBale,
			linkNode = spec.baleGrabber.grabNode,
			trans = {
				0,
				0,
				0
			},
			rot = {
				0,
				0,
				0
			}
		}
	end

	spec.startBalePlace.count = streamReadUInt8(streamId)

	for i = 1, spec.startBalePlace.count do
		local baleServerId = NetworkUtil.readNodeObjectId(streamId)
		local attachNode = getChildAt(spec.startBalePlace.node, i - 1)
		spec.balesToMount[baleServerId] = {
			serverId = baleServerId,
			linkNode = attachNode,
			trans = {
				0,
				0,
				0
			},
			rot = {
				0,
				0,
				0
			}
		}

		table.insert(spec.startBalePlace.bales, baleServerId)
		self:updateFoldingAnimation()
	end

	for i = 1, table.getn(spec.balePlaces) do
		local balePlace = spec.balePlaces[i]
		local numBales = streamReadUInt8(streamId)

		if numBales > 0 then
			balePlace.bales = {}

			for _ = 1, numBales do
				local baleServerId = NetworkUtil.readNodeObjectId(streamId)
				local maxValue = 2^spec.synchronizationNumBitsPosition - 1
				local x = streamReadUIntN(streamId, spec.synchronizationNumBitsPosition) / maxValue * spec.synchronizationMaxPosition * 2 - spec.synchronizationMaxPosition
				local y = streamReadUIntN(streamId, spec.synchronizationNumBitsPosition) / maxValue * spec.synchronizationMaxPosition * 2 - spec.synchronizationMaxPosition
				local z = streamReadUIntN(streamId, spec.synchronizationNumBitsPosition) / maxValue * spec.synchronizationMaxPosition * 2 - spec.synchronizationMaxPosition

				table.insert(balePlace.bales, baleServerId)

				spec.balesToMount[baleServerId] = {
					serverId = baleServerId,
					linkNode = balePlace.node,
					trans = {
						x,
						y,
						z
					},
					rot = {
						0,
						0,
						0
					}
				}
			end
		end
	end

	BaleLoader.updateBalePlacesAnimations(self)

	if BaleLoader.EMPTY_TO_WORK <= emptyState then
		self:doStateChange(BaleLoader.CHANGE_EMPTY_START)
		AnimatedVehicle.updateAnimations(self, 99999999, true)

		if BaleLoader.EMPTY_ROTATE_PLATFORM <= emptyState then
			self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM)
			AnimatedVehicle.updateAnimations(self, 99999999, true)

			if BaleLoader.EMPTY_ROTATE1 <= emptyState then
				self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE1)
				AnimatedVehicle.updateAnimations(self, 99999999, true)

				if BaleLoader.EMPTY_CLOSE_GRIPPERS <= emptyState then
					self:doStateChange(BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS)
					AnimatedVehicle.updateAnimations(self, 99999999, true)

					if BaleLoader.EMPTY_HIDE_PUSHER1 <= emptyState then
						self:doStateChange(BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1)
						AnimatedVehicle.updateAnimations(self, 99999999, true)

						if BaleLoader.EMPTY_HIDE_PUSHER2 <= emptyState then
							self:doStateChange(BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2)
							AnimatedVehicle.updateAnimations(self, 99999999, true)

							if BaleLoader.EMPTY_ROTATE2 <= emptyState then
								self:doStateChange(BaleLoader.CHANGE_EMPTY_ROTATE2)
								AnimatedVehicle.updateAnimations(self, 99999999, true)

								if BaleLoader.EMPTY_WAIT_TO_DROP <= emptyState then
									self:doStateChange(BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP)
									AnimatedVehicle.updateAnimations(self, 99999999, true)

									if emptyState == BaleLoader.EMPTY_CANCEL or emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
										self:doStateChange(BaleLoader.CHANGE_EMPTY_CANCEL)
										AnimatedVehicle.updateAnimations(self, 99999999, true)

										if emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
											self:doStateChange(BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO)
											AnimatedVehicle.updateAnimations(self, 99999999, true)
										end
									elseif emptyState == BaleLoader.EMPTY_WAIT_TO_SINK or emptyState == BaleLoader.EMPTY_SINK then
										self:doStateChange(BaleLoader.CHANGE_DROP_BALES)
										AnimatedVehicle.updateAnimations(self, 99999999, true)

										if emptyState == BaleLoader.EMPTY_SINK then
											self:doStateChange(BaleLoader.CHANGE_SINK)
											AnimatedVehicle.updateAnimations(self, 99999999, true)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	spec.emptyState = emptyState
end

function BaleLoader:onWriteStream(streamId, connection)
	local spec = self.spec_baleLoader

	streamWriteBool(streamId, spec.isInWorkPosition)
	streamWriteIntN(streamId, spec.frontBalePusherDirection, 3)
	streamWriteIntN(streamId, spec.rotatePlatformDirection, 3)
	streamWriteUIntN(streamId, spec.emptyState, 4)
	streamWriteInt8(streamId, spec.startBalePlace.current)

	if streamWriteBool(streamId, spec.baleGrabber.currentBale ~= nil) then
		NetworkUtil.writeNodeObjectId(streamId, spec.baleGrabber.currentBale)
	end

	streamWriteUInt8(streamId, spec.startBalePlace.count)

	for i = 1, spec.startBalePlace.count do
		local baleServerId = spec.startBalePlace.bales[i]

		NetworkUtil.writeNodeObjectId(streamId, baleServerId)
	end

	for i = 1, table.getn(spec.balePlaces) do
		local balePlace = spec.balePlaces[i]
		local numBales = 0

		if balePlace.bales ~= nil then
			numBales = table.getn(balePlace.bales)
		end

		streamWriteUInt8(streamId, numBales)

		if balePlace.bales ~= nil then
			for baleI = 1, numBales do
				local baleServerId = balePlace.bales[baleI]
				local bale = NetworkUtil.getObject(baleServerId)
				local nodeId = bale.nodeId
				local x, y, z = getTranslation(nodeId)

				NetworkUtil.writeNodeObjectId(streamId, baleServerId)

				if spec.synchronizationMaxPosition < math.abs(x) or spec.synchronizationMaxPosition < math.abs(y) or spec.synchronizationMaxPosition < math.abs(z) then
					Logging.xmlWarning(self.xmlFile, "Position of bale '%d' could not be synchronized correctly. Position out of range (%.2f, %.2f, %.2f) > %.2f. Increase 'vehicle.baleLoader.synchronization#maxPosition'", baleI, x, y, z, spec.synchronizationMaxPosition)
				end

				local maxValue = 2^spec.synchronizationNumBitsPosition - 1

				streamWriteUIntN(streamId, (spec.synchronizationMaxPosition + x) / (spec.synchronizationMaxPosition * 2) * maxValue, spec.synchronizationNumBitsPosition)
				streamWriteUIntN(streamId, (spec.synchronizationMaxPosition + y) / (spec.synchronizationMaxPosition * 2) * maxValue, spec.synchronizationNumBitsPosition)
				streamWriteUIntN(streamId, (spec.synchronizationMaxPosition + z) / (spec.synchronizationMaxPosition * 2) * maxValue, spec.synchronizationNumBitsPosition)
			end
		end
	end
end

function BaleLoader:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_baleLoader

	if connection:getIsServer() and streamReadBool(streamId) then
		local moverActive = streamReadBool(streamId)

		if moverActive ~= spec.unloadingMover.isActive then
			if moverActive then
				g_animationManager:startAnimations(spec.unloadingMover.animationNodes)
				g_soundManager:playSample(spec.samples.unload)
			else
				g_animationManager:stopAnimations(spec.unloadingMover.animationNodes)
				g_soundManager:stopSample(spec.samples.unload)
			end

			spec.unloadingMover.isActive = moverActive
		end
	end
end

function BaleLoader:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_baleLoader

	if not connection:getIsServer() and streamWriteBool(streamId, bitAND(dirtyMask, spec.unloadingMover.dirtyFlag) ~= 0) then
		streamWriteBool(streamId, spec.unloadingMover.isActive)
	end
end

function BaleLoader:updateBalePlacesAnimations()
	local spec = self.spec_baleLoader

	if spec.startBalePlace ~= nil and spec.startBalePlace.numOfPlaces < spec.startBalePlace.current or spec.animations.moveBalePlacesAfterRotatePlatform and spec.startBalePlace.current > 1 then
		local delta = 1
		local numBalePlaces = table.getn(spec.balePlaces)

		if spec.animations.moveBalePlacesAfterRotatePlatform and not spec.animations.moveBalePlacesAlways and not spec.useBalePlaceAsLoadPosition then
			delta = 0
		end

		if spec.useBalePlaceAsLoadPosition then
			numBalePlaces = numBalePlaces - 1
			delta = delta + spec.balePlaceOffset
		end

		self:playAnimation(spec.animations.moveBalePlaces, 1, 0, true)
		self:setAnimationStopTime(spec.animations.moveBalePlaces, (spec.startBalePlace.current - delta) / numBalePlaces)
		AnimatedVehicle.updateAnimations(self, 99999999, true)
	end

	if spec.startBalePlace ~= nil and spec.startBalePlace.count >= 1 then
		self:playAnimation(spec.animations.balesToOtherRow, 20, nil, true)
		AnimatedVehicle.updateAnimations(self, 99999999, true)

		if spec.startBalePlace.numOfPlaces <= spec.startBalePlace.count then
			BaleLoader.rotatePlatform(self)
		end
	end
end

function BaleLoader:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_baleLoader

	if self.finishedFirstUpdate then
		for k, baleToMount in pairs(spec.balesToMount) do
			local bale = NetworkUtil.getObject(baleToMount.serverId)

			if bale ~= nil then
				local x, y, z = unpack(baleToMount.trans)
				local rx, ry, rz = unpack(baleToMount.rot)

				if spec.dynamicMount.enabled then
					self:mountDynamicBale(bale, baleToMount.linkNode)
				else
					self:mountBale(bale, self, baleToMount.linkNode, x, y, z, rx, ry, rz)
				end

				local baleType = self:getBaleTypeByBale(bale)

				if baleType ~= nil then
					self:setBaleLoaderBaleType(baleType.index)
				end

				spec.balesToMount[k] = nil
			end
		end
	end

	if self.isClient and spec.grabberEffectDisableTime ~= 0 and spec.grabberEffectDisableTime < g_currentMission.time then
		g_effectManager:stopEffects(spec.grabberEffects)

		spec.grabberEffectDisableTime = 0
	end

	if spec.grabberIsMoving and not self:getIsBaleLoaderFoldingPlaying() then
		spec.grabberIsMoving = false
	end

	spec.showBaleNotSupportedWarning = false

	if self:getIsBaleGrabbingAllowed() and spec.baleGrabber.grabNode ~= nil and spec.baleGrabber.currentBale == nil then
		local nearestBale, nearestBaleType, warning = BaleLoader.getBaleInRange(self, spec.baleGrabber.grabNode, spec.baleGrabber.balesInTrigger)

		if nearestBale ~= nil then
			if nearestBaleType == nil then
				spec.showBaleNotSupportedWarning = true
				spec.baleNotSupportedWarning = warning
			elseif self.isServer then
				self:pickupBale(nearestBale, nearestBaleType)
			end
		end
	end

	if self.isServer then
		if spec.grabberMoveState ~= nil then
			if spec.grabberMoveState == BaleLoader.GRAB_MOVE_UP then
				if not self:getIsAnimationPlaying(spec.animations.baleGrabberWorkToDrop) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_GRAB_MOVE_UP), true, nil, self)
				end
			elseif spec.grabberMoveState == BaleLoader.GRAB_DROP_BALE then
				if not self:getIsAnimationPlaying(spec.currentBaleGrabberDropBaleAnimName) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_GRAB_DROP_BALE), true, nil, self)
				end
			elseif spec.grabberMoveState == BaleLoader.GRAB_MOVE_DOWN then
				local name = spec.animations.baleGrabberDropToWork or spec.animations.baleGrabberWorkToDrop

				if not self:getIsAnimationPlaying(name) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_GRAB_MOVE_DOWN), true, nil, self)
					self:setAnimationTime(spec.currentBaleGrabberDropBaleAnimName, 0, false)
					self:setAnimationTime(spec.animations.baleGrabberWorkToDrop, 0, false)
				end
			end
		end

		if spec.frontBalePusherDirection ~= 0 and not self:getIsAnimationPlaying(spec.animations.frontBalePusher) then
			g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_FRONT_PUSHER), true, nil, self)
		end

		if spec.rotatePlatformDirection ~= 0 then
			local name = spec.animations.rotatePlatform

			if spec.rotatePlatformDirection < 0 then
				name = spec.animations.rotatePlatformBack
			end

			if not self:getIsAnimationPlaying(name) and not self:getIsAnimationPlaying(spec.animations.moveBalePlacesExtrasOnce) and not spec.moveBalePlacesDelayedMovement then
				g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_ROTATE_PLATFORM), true, nil, self)
			end
		end

		if spec.emptyState ~= BaleLoader.EMPTY_NONE then
			if spec.emptyState == BaleLoader.EMPTY_TO_WORK then
				if not self:getIsBaleLoaderFoldingPlaying() then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_ROTATE_PLATFORM then
				if not self:getIsAnimationPlaying(spec.animations.rotatePlatformEmpty) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_ROTATE1), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_ROTATE1 then
				if not self:getIsAnimationPlaying(spec.animations.emptyRotate) and not self:getIsAnimationPlaying(spec.animations.moveBalePlacesToEmpty) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_CLOSE_GRIPPERS then
				if not self:getIsAnimationPlaying(spec.animations.closeGrippers) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_HIDE_PUSHER1 then
				if not self:getIsAnimationPlaying(spec.animations.pusherEmptyHide1) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_HIDE_PUSHER2 then
				if self:getAnimationTime(spec.animations.pusherMoveToEmpty) < 0.7 or not self:getIsAnimationPlaying(spec.animations.pusherMoveToEmpty) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_ROTATE2), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_ROTATE2 then
				if not self:getIsAnimationPlaying(spec.animations.emptyRotate) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_SINK then
				if not self:getIsAnimationPlaying(spec.animations.emptyRotate) and not self:getIsAnimationPlaying(spec.animations.moveBalePlacesToEmpty) and not self:getIsAnimationPlaying(spec.animations.pusherEmptyHide1) and not self:getIsAnimationPlaying(spec.animations.rotatePlatformEmpty) then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_STATE_NIL), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_CANCEL and not self:getIsAnimationPlaying(spec.animations.emptyRotate) then
				g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO), true, nil, self)
			end
		end
	end

	if spec.baleGrabber.currentBaleIsUnmounted then
		spec.baleGrabber.currentBaleIsUnmounted = false
		local bale = NetworkUtil.getObject(spec.baleGrabber.currentBale)

		if bale ~= nil then
			if spec.dynamicMount.enabled then
				self:mountDynamicBale(bale, spec.baleGrabber.grabNode)
			else
				self:mountBale(bale, self, spec.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0)
			end

			bale:setCanBeSold(false)
		end
	end
end

function BaleLoader:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_baleLoader

	if self.isClient then
		local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA]

		if actionEvent ~= nil then
			local showAction = false

			if spec.emptyState == BaleLoader.EMPTY_NONE and spec.grabberMoveState == nil then
				if spec.isInWorkPosition then
					g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.transportPosition)

					showAction = true
				else
					g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.operatingPosition)

					showAction = true
				end
			end

			g_inputBinding:setActionEventActive(actionEvent.actionEventId, showAction)
		end

		actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA2]

		if actionEvent ~= nil then
			g_inputBinding:setActionEventActive(actionEvent.actionEventId, spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP)
		end

		actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]

		if actionEvent ~= nil then
			local showAction = false

			if spec.emptyState == BaleLoader.EMPTY_NONE then
				if BaleLoader.getAllowsStartUnloading(self) then
					g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.unload)

					showAction = true
				end
			elseif spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
				g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.unloadHere)

				showAction = true
			elseif spec.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK then
				if not spec.unloadingMover.isActive then
					g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.lowerPlattform)

					showAction = true
				end
			elseif spec.emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
				g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.unload)

				showAction = true
			end

			g_inputBinding:setActionEventActive(actionEvent.actionEventId, showAction)
		end
	end

	if self.isServer then
		if spec.automaticUnloading or spec.automaticUnloadingInProgress then
			if spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
				self:doStateChange(BaleLoader.CHANGE_BUTTON_EMPTY)
			end

			local isPlaying = self:getIsAnimationPlaying(spec.animations.releaseFrontPlatform)

			if spec.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK and not isPlaying and not spec.unloadingMover.isActive then
				self:doStateChange(BaleLoader.CHANGE_SINK)
			end
		end

		if #spec.baleJoints > 0 then
			local removeJoints = false

			if spec.dynamicBaleUnloading.useUnloadingMoverTrigger and spec.unloadingMover.frameDelay == 0 and next(spec.unloadingMover.balesInTrigger) == nil then
				removeJoints = true
			end

			if spec.dynamicBaleUnloading.useUnloadingMoverTrigger == nil or removeJoints then
				removeJoints = false

				if spec.dynamicBaleUnloading.releaseAnimation ~= nil then
					local animation = spec.dynamicBaleUnloading.releaseAnimation

					if spec.dynamicBaleUnloading.releaseAnimationTime <= self:getAnimationTime(animation) or not self:getIsAnimationPlaying(animation) then
						removeJoints = true
					end
				end
			end

			if removeJoints then
				for i = #spec.baleJoints, 1, -1 do
					removeJoint(spec.baleJoints[i])

					spec.baleJoints[i] = nil
				end
			end
		end

		if spec.unloadingMover.isActive then
			spec.unloadingMover.frameDelay = math.max(spec.unloadingMover.frameDelay - 1, 0)

			if spec.unloadingMover.frameDelay == 0 and next(spec.unloadingMover.balesInTrigger) == nil then
				spec.unloadingMover.isActive = false

				for i = 1, #spec.unloadingMover.nodes do
					setFrictionVelocity(spec.unloadingMover.nodes[i].node, 0)
				end

				if self.isClient then
					g_animationManager:stopAnimations(spec.unloadingMover.animationNodes)
					g_soundManager:stopSample(spec.samples.unload)
				end

				self:raiseDirtyFlags(spec.unloadingMover.dirtyFlag)
			end
		end

		if spec.dynamicMount.enabled then
			local jointNodePositionChanged = false

			for i, jointNode in ipairs(spec.dynamicMount.baleJointsToUpdate) do
				if jointNode.quaternion == nil then
					local qx, qy, qz, qw = getQuaternion(jointNode.node)
					jointNode.quaternion = {
						qx,
						qy,
						qz,
						qw
					}
				end

				if jointNode.time < spec.dynamicMount.jointInterpolationTimeRot then
					jointNode.time = jointNode.time + dt
					local qx = 0
					local qy = 0
					local qz = 0
					local qw = 1

					if math.abs(jointNode.quaternion[2]) > 0.5 then
						qx, qy, qz, qw = MathUtil.slerpQuaternionShortestPath(jointNode.quaternion[1], jointNode.quaternion[2], jointNode.quaternion[3], jointNode.quaternion[4], 0, 1, 0, 0, jointNode.time / spec.dynamicMount.jointInterpolationTimeRot)
					elseif math.abs(jointNode.quaternion[2]) < 0.5 then
						qx, qy, qz, qw = MathUtil.slerpQuaternionShortestPath(jointNode.quaternion[1], jointNode.quaternion[2], jointNode.quaternion[3], jointNode.quaternion[4], 0, 0, 0, 1, jointNode.time / spec.dynamicMount.jointInterpolationTimeRot)
					end

					setQuaternion(jointNode.node, qx, qy, qz, qw)

					jointNodePositionChanged = true
				end

				local x, y, z = getTranslation(jointNode.node)

				if math.abs(x) + math.abs(y) + math.abs(z) > 0.001 then
					local move = spec.dynamicMount.jointInterpolationSpeedTrans * dt

					local function moveValue(old)
						local limit = MathUtil.sign(old) > 0 and math.max or math.min

						return limit(old - MathUtil.sign(old) * move, 0)
					end

					setTranslation(jointNode.node, moveValue(x), moveValue(y), moveValue(z))

					jointNodePositionChanged = true
				elseif spec.dynamicMount.jointInterpolationTimeRot < jointNode.time then
					table.remove(spec.dynamicMount.baleJointsToUpdate, i)
				end
			end

			local anyAnimationPlaying = false

			for name, _ in pairs(self.spec_animatedVehicle.animations) do
				if self:getIsAnimationPlaying(name) then
					anyAnimationPlaying = true
				end
			end

			if anyAnimationPlaying or jointNodePositionChanged or spec.dynamicMount.baleMassDirty then
				for _, balePlace in pairs(spec.balePlaces) do
					if balePlace.bales ~= nil then
						for _, baleServerId in pairs(balePlace.bales) do
							local bale = NetworkUtil.getObject(baleServerId)

							if bale ~= nil then
								if bale.dynamicMountJointIndex ~= nil then
									setJointFrame(bale.dynamicMountJointIndex, 0, bale.dynamicMountJointNode)
								end

								if bale.backupMass == nil then
									local mass = getMass(bale.nodeId)

									if mass ~= 1 then
										bale.backupMass = mass

										setMass(bale.nodeId, 0.1)

										spec.dynamicMount.baleMassDirty = false
									end
								end
							end
						end
					end
				end

				if spec.startBalePlace ~= nil then
					for _, baleServerId in ipairs(spec.startBalePlace.bales) do
						local bale = NetworkUtil.getObject(baleServerId)

						if bale ~= nil then
							if bale.dynamicMountJointIndex ~= nil then
								setJointFrame(bale.dynamicMountJointIndex, 0, bale.dynamicMountJointNode)
							end

							if bale.backupMass == nil then
								local mass = getMass(bale.nodeId)

								if mass ~= 1 then
									bale.backupMass = mass

									setMass(bale.nodeId, 0.1)

									spec.dynamicMount.baleMassDirty = false
								end
							end
						end
					end
				end

				if spec.baleGrabber.currentBale ~= nil then
					local bale = NetworkUtil.getObject(spec.baleGrabber.currentBale)

					if bale ~= nil and bale.dynamicMountJointIndex ~= nil then
						setJointFrame(bale.dynamicMountJointIndex, 0, bale.dynamicMountJointNode)
					end
				end
			end
		end
	end

	if spec.moveBalePlacesDelayedMovement and self:getAnimationTime(spec.animations.baleGrabberWorkToDrop) < spec.animations.moveBalePlacesMaxGrabberTime then
		spec.rotatePlatformDirection = -1

		self:playAnimation(spec.animations.rotatePlatformBack, -1, nil, true)

		if spec.animations.moveBalePlacesAfterRotatePlatform and (spec.startBalePlace ~= nil and spec.startBalePlace.current <= #spec.balePlaces or spec.animations.moveBalePlacesAlways) then
			self:playAnimation(spec.animations.moveBalePlaces, 1, (spec.startBalePlace.current - 1) / #spec.balePlaces, true)
			self:setAnimationStopTime(spec.animations.moveBalePlaces, spec.startBalePlace.current / #spec.balePlaces)
			self:playAnimation(spec.animations.moveBalePlacesExtrasOnce, 1, nil, true)
		end

		spec.moveBalePlacesDelayedMovement = nil
	end

	if spec.animations.moveBalePlacesToEmptyPushOffsetTime > 0 then
		spec.animations.moveBalePlacesToEmptyPushOffsetTime = spec.animations.moveBalePlacesToEmptyPushOffsetTime - dt

		if spec.animations.moveBalePlacesToEmptyPushOffsetTime <= 0 then
			local balePlacesTime = self:getRealAnimationTime(spec.animations.moveBalePlaces)
			local duration = self:getAnimationDuration(spec.animations.moveBalePlacesToEmpty)
			local startTime = balePlacesTime / duration
			local speedFactor = (duration - balePlacesTime) / (duration - balePlacesTime - spec.animations.moveBalePlacesToEmptyPushOffsetDelay * spec.animations.moveBalePlacesToEmptySpeed)
			local speed = spec.animations.moveBalePlacesToEmptySpeed * speedFactor

			self:playAnimation(spec.animations.moveBalePlacesToEmpty, speed, startTime, true)

			spec.animations.moveBalePlacesToEmptyPushOffsetTime = 0
		end
	end
end

function BaleLoader:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_baleLoader

	if spec.showBaleNotSupportedWarning and spec.baleNotSupportedWarning ~= nil then
		g_currentMission:showBlinkingWarning(spec.baleNotSupportedWarning, 2000)
	end
end

function BaleLoader:getBaleInRange(refNode, balesInTrigger)
	local spec = self.spec_baleLoader
	local nearestDistance = spec.baleGrabber.pickupRange
	local nearestBale, nearestBaleType = nil
	local warning = spec.texts.baleNotSupported

	for bale, state in pairs(balesInTrigger) do
		if state ~= nil and state > 0 then
			local isValidBale = true
			local otherBale = nil

			for _, balePlace in pairs(spec.balePlaces) do
				if balePlace.bales ~= nil then
					for _, baleServerId in pairs(balePlace.bales) do
						local baleInPlace = NetworkUtil.getObject(baleServerId)

						if baleInPlace ~= nil and baleInPlace == bale then
							isValidBale = false
						end

						otherBale = baleInPlace
					end
				end
			end

			if spec.startBalePlace ~= nil then
				for _, baleServerId in ipairs(spec.startBalePlace.bales) do
					local baleInPlace = NetworkUtil.getObject(baleServerId)

					if baleInPlace ~= nil and baleInPlace == bale then
						isValidBale = false
					end

					otherBale = baleInPlace
				end
			end

			if bale == nil or not entityExists(bale.nodeId) then
				isValidBale = false
			end

			if isValidBale then
				local distance = calcDistanceFrom(refNode, bale.nodeId)

				if distance < nearestDistance then
					local foundBaleType = self:getBaleTypeByBale(bale)

					if foundBaleType ~= spec.currentBaleType and self:getFillUnitFillLevel(spec.currentBaleType.fillUnitIndex) ~= 0 then
						foundBaleType = nil
						warning = spec.texts.onlyOneBaleTypeWarning
					end

					if foundBaleType ~= nil and not foundBaleType.mixedFillTypes and otherBale ~= nil and bale:getFillType() ~= otherBale:getFillType() then
						foundBaleType = nil
						warning = spec.texts.baleDoNotAllowFillTypeMixing
					end

					if bale.dynamicMountJointIndex ~= nil then
						foundBaleType = nil
					end

					if not bale:getBaleSupportsBaleLoader() then
						foundBaleType = nil
					end

					local activeFarmId = self:getActiveFarm()

					if activeFarmId ~= bale.ownerFarmId and not g_currentMission.accessHandler:canFarmAccessOtherId(activeFarmId, bale.ownerFarmId) then
						foundBaleType = nil
						warning = spec.texts.youDoNotOwnBale
					end

					if foundBaleType ~= nil or nearestBaleType == nil then
						if foundBaleType ~= nil then
							nearestDistance = distance
						end

						nearestBale = bale
						nearestBaleType = foundBaleType
					end
				end
			end
		end
	end

	return nearestBale, nearestBaleType, warning
end

function BaleLoader:onActivate()
	local spec = self.spec_baleLoader

	if spec.isInWorkPosition and not spec.animationNodesBlocked then
		g_animationManager:startAnimations(spec.animationNodes)
		g_soundManager:playSample(spec.samples.work)
	end
end

function BaleLoader:onDeactivate()
	local spec = self.spec_baleLoader

	g_effectManager:stopEffects(spec.grabberEffects)
	g_animationManager:stopAnimations(spec.animationNodes)
	g_soundManager:stopSample(spec.samples.work)
end

function BaleLoader:onRootVehicleChanged(rootVehicle)
	local spec = self.spec_baleLoader
	local actionController = rootVehicle.actionController

	if actionController ~= nil then
		if spec.controlledAction ~= nil then
			spec.controlledAction:updateParent(actionController)

			return
		end

		spec.controlledAction = actionController:registerAction("baleLoaderWorkstate", nil, 4)

		spec.controlledAction:setCallback(self, BaleLoader.actionControllerEvent)

		local function finishedFunc(vehicle)
			return vehicle.spec_baleLoader.isInWorkPosition
		end

		spec.controlledAction:setFinishedFunctions(self, finishedFunc, true, false)
		spec.controlledAction:addAIEventListener(self, "onAIImplementPrepare", -1)
	elseif spec.controlledAction ~= nil then
		spec.controlledAction:remove()
	end
end

function BaleLoader:actionControllerEvent(direction)
	local spec = self.spec_baleLoader

	if direction > 0 and not spec.isInWorkPosition or direction < 0 and spec.isInWorkPosition then
		BaleLoader.actionEventWorkTransport(self)

		return true
	end
end

function BaleLoader:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_baleLoader

	if fillUnitIndex == spec.fillUnitIndex then
		self:updateFoldingAnimation()
	end
end

function BaleLoader:onRegisterAnimationValueTypes()
	local spec = self.spec_baleLoader

	self:registerAnimationValueType("baleLoaderAnimationNodes", "baleLoaderAnimationNodes", "", false, AnimationValueBool, function (value, xmlFile, xmlKey)
		return true
	end, function (value)
		return not spec.animationNodesBlocked
	end, function (value, state)
		spec.animationNodesBlocked = not state

		if not spec.animationNodesBlocked and spec.isInWorkPosition then
			g_animationManager:startAnimations(spec.animationNodes)
			g_soundManager:playSample(spec.samples.work)
		end

		if spec.animationNodesBlocked and spec.isInWorkPosition then
			g_animationManager:stopAnimations(spec.animationNodes)
			g_soundManager:stopSample(spec.samples.work)
		end
	end)
end

function BaleLoader:loadBaleTypeFromXML(xmlFile, key, baleType)
	local spec = self.spec_baleLoader

	local function getDimensionValue(xml, valueKey, valueName, minValueName, maxValueName)
		local value = xml:getValue(valueKey .. "#" .. valueName)
		local minValue = xml:getValue(valueKey .. "#" .. minValueName)
		local maxValue = xml:getValue(valueKey .. "#" .. maxValueName)
		minValue = minValue or maxValue or value
		maxValue = maxValue or minValue

		if minValue == nil or maxValue == nil then
			Logging.xmlError(xmlFile, "Unable to load bale dimension. '%s' is not available in '%s'", valueName, valueKey)

			return 0, 0
		end

		return MathUtil.round(minValue, 2), MathUtil.round(maxValue, 2)
	end

	baleType.dimensions = {}
	local dimensions = baleType.dimensions
	dimensions.isRoundbale = self.xmlFile:getString(key .. "#diameter") ~= nil or self.xmlFile:getString(key .. "#minDiameter") ~= nil or self.xmlFile:getString(key .. "#maxDiameter") ~= nil

	if dimensions.isRoundbale then
		dimensions.minWidth, dimensions.maxWidth = getDimensionValue(self.xmlFile, key, "width", "minWidth", "maxWidth")
		dimensions.minDiameter, dimensions.maxDiameter = getDimensionValue(self.xmlFile, key, "diameter", "minDiameter", "maxDiameter")
	else
		dimensions.minWidth, dimensions.maxWidth = getDimensionValue(self.xmlFile, key, "width", "minWidth", "maxWidth")
		dimensions.minHeight, dimensions.maxHeight = getDimensionValue(self.xmlFile, key, "height", "minHeight", "maxHeight")
		dimensions.minLength, dimensions.maxLength = getDimensionValue(self.xmlFile, key, "length", "minLength", "maxLength")
	end

	baleType.mixedFillTypes = self.xmlFile:getValue(key .. "#mixedFillTypes", true)
	baleType.fillUnitIndex = self.xmlFile:getValue(key .. "#fillUnitIndex", spec.fillUnitIndex)
	baleType.changeObjects = {}

	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, key, baleType.changeObjects, self.components, self)
	self:loadBalePlacesFromXML(xmlFile, key, baleType)

	if not self:loadBaleLoaderAnimationsFromXML(xmlFile, key, baleType, spec.defaultAnimations) then
		return false
	end

	return true
end

function BaleLoader:loadBaleLoaderAnimationsFromXML(xmlFile, key, target, defaultTarget)
	target.animations = {}
	local default = target.animations

	if defaultTarget ~= nil then
		default = defaultTarget.animations or target.animations
	end

	target.animations.rotatePlatform = xmlFile:getValue(key .. ".animations.platform#rotate", default.rotatePlatform or "rotatePlatform")
	target.animations.rotatePlatformBack = xmlFile:getValue(key .. ".animations.platform#rotateBack", default.rotatePlatformBack or "rotatePlatform")
	target.animations.rotatePlatformEmpty = xmlFile:getValue(key .. ".animations.platform#rotateEmpty", default.rotatePlatformEmpty or "rotatePlatform")
	target.animations.rotatePlatformAllowPickup = xmlFile:getValue(key .. ".animations.platform#allowPickupWhileMoving", Utils.getNoNil(default.rotatePlatformAllowPickup, false))
	target.animations.baleGrabberDropBaleReverseSpeed = xmlFile:getValue(key .. ".animations.baleGrabber#dropBaleReverseSpeed", default.baleGrabberDropBaleReverseSpeed or 5)
	target.animations.baleGrabberDropToWork = xmlFile:getValue(key .. ".animations.baleGrabber#dropToWork", default.baleGrabberDropToWork)
	target.animations.baleGrabberWorkToDrop = xmlFile:getValue(key .. ".animations.baleGrabber#workToDrop", default.baleGrabberWorkToDrop or "baleGrabberWorkToDrop")
	target.animations.baleGrabberDropBale = xmlFile:getValue(key .. ".animations.baleGrabber#dropBale", default.baleGrabberDropBale or "baleGrabberDropBale")
	target.animations.baleGrabberTransportToWork = xmlFile:getValue(key .. ".animations.baleGrabber#transportToWork", default.baleGrabberTransportToWork or "baleGrabberTransportToWork")
	target.animations.pusherEmptyHide1 = xmlFile:getValue(key .. ".animations.pusher#emptyHide", default.pusherEmptyHide1 or "emptyHidePusher1")
	target.animations.pusherMoveToEmpty = xmlFile:getValue(key .. ".animations.pusher#moveToEmpty", default.pusherMoveToEmpty or "moveBalePusherToEmpty")
	target.animations.pusherHideOnEmpty = xmlFile:getValue(key .. ".animations.pusher#hidePusherOnEmpty", Utils.getNoNil(default.pusherHideOnEmpty, true))
	target.animations.pusherPushBalesOnEmpty = xmlFile:getValue(key .. ".animations.pusher#pushBalesOnEmpty", Utils.getNoNil(default.pusherPushBalesOnEmpty, false))
	target.animations.releaseFrontPlatform = xmlFile:getValue(key .. ".animations.releaseFrontPlatform#name", default.releaseFrontPlatform or "releaseFrontplattform")
	target.animations.releaseFrontPlatformFillLevelSpeed = xmlFile:getValue(key .. ".animations.releaseFrontPlatform#fillLevelSpeed", Utils.getNoNil(default.releaseFrontPlatformFillLevelSpeed, false))
	target.animations.moveBalePlaces = xmlFile:getValue(key .. ".animations.moveBalePlaces#name", default.moveBalePlaces or "moveBalePlaces")
	target.animations.moveBalePlacesExtrasOnce = xmlFile:getValue(key .. ".animations.moveBalePlaces#extrasOnce", default.moveBalePlacesExtrasOnce or "moveBalePlacesExtrasOnce")
	target.animations.moveBalePlacesToEmpty = xmlFile:getValue(key .. ".animations.moveBalePlaces#empty", default.moveBalePlacesToEmpty or "moveBalePlacesToEmpty")
	target.animations.moveBalePlacesToEmptySpeed = xmlFile:getValue(key .. ".animations.moveBalePlaces#emptySpeed", default.moveBalePlacesToEmptySpeed or 1.5)
	target.animations.moveBalePlacesToEmptyReverseSpeed = xmlFile:getValue(key .. ".animations.moveBalePlaces#emptyReverseSpeed", default.moveBalePlacesToEmptyReverseSpeed or -1)
	target.animations.moveBalePlacesToEmptyPushOffset = xmlFile:getValue(key .. ".animations.moveBalePlaces#pushOffset", default.moveBalePlacesToEmptyPushOffset or 0)
	target.animations.moveBalePlacesToEmptyPushOffsetDelay = 0
	target.animations.moveBalePlacesToEmptyPushOffsetTime = 0
	target.animations.moveBalePlacesAfterRotatePlatform = xmlFile:getValue(key .. ".animations.moveBalePlaces#moveAfterRotatePlatform", Utils.getNoNil(default.moveBalePlacesAfterRotatePlatform, false))
	target.animations.moveBalePlacesResetOnSink = xmlFile:getValue(key .. ".animations.moveBalePlaces#resetOnSink", Utils.getNoNil(default.moveBalePlacesResetOnSink, false))
	target.animations.moveBalePlacesMaxGrabberTime = xmlFile:getValue(key .. ".animations.moveBalePlaces#maxGrabberTime", default.moveBalePlacesMaxGrabberTime or math.huge)
	target.animations.moveBalePlacesAlways = xmlFile:getValue(key .. ".animations.moveBalePlaces#alwaysMove", Utils.getNoNil(default.moveBalePlacesAlways, false))
	target.animations.emptyRotate = xmlFile:getValue(key .. ".animations.emptyRotate#name", default.emptyRotate or "emptyRotate")
	target.animations.emptyRotateReset = xmlFile:getValue(key .. ".animations.emptyRotate#reset", Utils.getNoNil(default.emptyRotateReset, true))
	target.animations.frontBalePusher = xmlFile:getValue(key .. ".animations#frontBalePusher", default.frontBalePusher or "frontBalePusher")
	target.animations.balesToOtherRow = xmlFile:getValue(key .. ".animations#balesToOtherRow", default.balesToOtherRow or "balesToOtherRow")
	target.animations.closeGrippers = xmlFile:getValue(key .. ".animations#closeGrippers", default.closeGrippers or "closeGrippers")

	return true
end

function BaleLoader:loadBalePlacesFromXML(xmlFile, key, target)
	local useSharedBalePlaces = true
	target.startBalePlace = {
		bales = {},
		node = self.xmlFile:getValue(key .. ".balePlaces#startBalePlace", nil, self.components, self.i3dMappings)
	}

	if target.startBalePlace.node ~= nil then
		target.startBalePlace.numOfPlaces = getNumOfChildren(target.startBalePlace.node)

		if target.startBalePlace.numOfPlaces == 0 then
			target.startBalePlace.node = nil
		else
			target.startBalePlace.origRot = {}
			target.startBalePlace.origTrans = {}

			for i = 1, target.startBalePlace.numOfPlaces do
				local node = getChildAt(target.startBalePlace.node, i - 1)
				target.startBalePlace.origRot[i] = {
					getRotation(node)
				}
				target.startBalePlace.origTrans[i] = {
					getTranslation(node)
				}
			end
		end
	else
		target.startBalePlace.numOfPlaces = 0
		useSharedBalePlaces = false
	end

	target.startBalePlace.count = 0
	target.startBalePlace.current = 1
	target.balePlaces = {}
	local i = 0

	while true do
		local balePlaceKey = string.format("%s.balePlaces.balePlace(%d)", key, i)

		if not self.xmlFile:hasProperty(balePlaceKey) then
			break
		end

		local node = self.xmlFile:getValue(balePlaceKey .. "#node", nil, self.components, self.i3dMappings)

		if node ~= nil then
			local entry = {
				node = node
			}

			table.insert(target.balePlaces, entry)
		end

		i = i + 1
	end

	if #target.balePlaces == 0 then
		useSharedBalePlaces = false
	end

	return useSharedBalePlaces
end

function BaleLoader:createBaleToBaleJoints(baleLines)
	if #baleLines > 1 then
		local dynamicBaleUnloading = self.spec_baleLoader.dynamicBaleUnloading
		local lineRotLimit = dynamicBaleUnloading.rowConnectionRotLimit
		local sideRotLimit = dynamicBaleUnloading.rowInterConnectionRotLimit

		for lineIndex, bales in ipairs(baleLines) do
			local isRoundbale = bales[1].isRoundbale

			if dynamicBaleUnloading.connectedRows[lineIndex] then
				for i = 1, #bales - 1 do
					if isRoundbale then
						self:createBaleToBaleJoint(bales[i], bales[i + 1], 0, dynamicBaleUnloading.heightOffset, bales[i].width + dynamicBaleUnloading.widthOffset, lineRotLimit, 0, 0, i)
					else
						self:createBaleToBaleJoint(bales[i], bales[i + 1], bales[i].width + dynamicBaleUnloading.widthOffset, dynamicBaleUnloading.heightOffset, 0, 0, 0, lineRotLimit * 5, i)
					end
				end
			end

			for _, connection in ipairs(dynamicBaleUnloading.interConnectedRowStarts) do
				if connection[1] == lineIndex then
					local bales2 = baleLines[connection[2]]

					if bales2 ~= nil then
						if isRoundbale then
							self:createBaleToBaleJoint(bales[1], bales2[1], bales[1].diameter + dynamicBaleUnloading.diameterOffset, dynamicBaleUnloading.heightOffset, 0, sideRotLimit, sideRotLimit, sideRotLimit, 1)
						else
							self:createBaleToBaleJoint(bales[1], bales2[1], 0, bales[1].height + 0.05, 0, lineRotLimit, 0, 0, 1)
						end
					end
				end
			end

			for _, connection in ipairs(dynamicBaleUnloading.interConnectedRowEnds) do
				if connection[1] == lineIndex then
					local bales2 = baleLines[connection[2]]

					if bales2 ~= nil and #bales == #bales2 then
						if isRoundbale then
							self:createBaleToBaleJoint(bales[#bales], bales2[#bales2], bales[#bales].diameter + dynamicBaleUnloading.diameterOffset, dynamicBaleUnloading.heightOffset, 0, sideRotLimit, sideRotLimit, sideRotLimit, #bales)
						else
							self:createBaleToBaleJoint(bales[#bales], bales2[#bales2], 0, bales[#bales].height + 0.05, 0, lineRotLimit, 0, 0, #bales)
						end
					end
				end
			end
		end
	end
end

function BaleLoader:createBaleToBaleJoint(bale1, bale2, x, y, z, rx, ry, rz, balePlaceIndex)
	local spec = self.spec_baleLoader
	local balePlaceRot = spec.balePlaces[balePlaceIndex].node
	local constr = JointConstructor.new()

	constr:setActors(bale1.nodeId, bale2.nodeId)

	local jointTransform1 = createTransformGroup("jointTransform1")

	link(bale1.nodeId, jointTransform1)
	setRotation(jointTransform1, localRotationToLocal(balePlaceRot, bale1.nodeId, 0, 0, 0))

	local jointTransform2 = createTransformGroup("jointTransform2")

	link(bale2.nodeId, jointTransform2)
	setRotation(jointTransform2, localRotationToLocal(balePlaceRot, bale2.nodeId, 0, 0, 0))
	constr:setJointTransforms(jointTransform1, jointTransform2)
	constr:setEnableCollision(true)
	constr:setRotationLimit(0, -rx, rx)
	constr:setRotationLimit(1, -ry, ry)
	constr:setRotationLimit(2, -rz, rz)
	constr:setTranslationLimit(0, true, -x, x)
	constr:setTranslationLimit(1, true, -y, y)
	constr:setTranslationLimit(2, true, -z, z)

	local jointIndex = constr:finalize()

	table.insert(spec.baleJoints, jointIndex)
end

function BaleLoader:doStateChange(id, nearestBaleServerId)
	local spec = self.spec_baleLoader

	if id == BaleLoader.CHANGE_DROP_BALES then
		local baleLines = {}

		if spec.startBalePlace ~= nil then
			spec.startBalePlace.current = 1
		end

		local packBales = spec.balePacker.node ~= nil and spec.balePacker.filename ~= nil
		local packedFarmId = FarmManager.SPECTATOR_FARM_ID
		local packedFillType = FillType.UNKNOWN
		local packedFillLevel = 0

		for _, balePlace in pairs(spec.balePlaces) do
			if balePlace.bales ~= nil then
				for i, baleServerId in pairs(balePlace.bales) do
					local bale = NetworkUtil.getObject(baleServerId)

					if bale ~= nil then
						if spec.dynamicMount.enabled then
							self:unmountDynamicBale(bale)
						else
							self:unmountBale(bale)
						end

						bale:setCanBeSold(true)

						if spec.baleGrabber.balesInTrigger[bale] ~= nil then
							spec.baleGrabber.balesInTrigger[bale] = nil
						end

						if spec.dynamicBaleUnloading.enabled then
							if baleLines[i] == nil then
								table.insert(baleLines, {
									bale
								})
							else
								table.insert(baleLines[i], bale)
							end
						end

						if packBales then
							packedFarmId = bale.ownerFarmId
							packedFillType = bale.fillType
							packedFillLevel = packedFillLevel + bale.fillLevel

							bale:delete()
						end
					end

					spec.balesToMount[baleServerId] = nil
				end

				balePlace.bales = nil
			end
		end

		if self.isServer and packBales then
			local baleObject = PackedBale.new(self.isServer, self.isClient)
			local x, y, z = getWorldTranslation(spec.balePacker.node)
			local rx, ry, rz = getWorldRotation(spec.balePacker.node)

			if baleObject:loadFromConfigXML(spec.balePacker.filename, x, y, z, rx, ry, rz) then
				baleObject:setFillType(packedFillType)
				baleObject:setFillLevel(packedFillLevel)
				baleObject:setOwnerFarmId(packedFarmId, true)
				baleObject:register()
			end
		end

		if spec.dynamicBaleUnloading.enabled then
			self:createBaleToBaleJoints(baleLines)
		end

		local speed = 1

		if spec.animations.releaseFrontPlatformFillLevelSpeed then
			speed = 1 / (self:getFillUnitFillLevel(spec.fillUnitIndex) / self:getFillUnitCapacity(spec.fillUnitIndex))
		end

		self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, self:getFillUnitFirstSupportedFillType(spec.fillUnitIndex), ToolType.UNDEFINED, nil)

		if self.isServer and spec.unloadingMover.trigger ~= nil then
			spec.unloadingMover.isActive = true
			spec.unloadingMover.frameDelay = 3

			for i = 1, #spec.unloadingMover.nodes do
				local unloadingMoverNode = spec.unloadingMover.nodes[i]

				setFrictionVelocity(unloadingMoverNode.node, unloadingMoverNode.speed)
			end

			if self.isClient then
				g_animationManager:startAnimations(spec.unloadingMover.animationNodes)
				g_soundManager:playSample(spec.samples.unload)
			end

			self:raiseDirtyFlags(spec.unloadingMover.dirtyFlag)
		end

		self:playAnimation(spec.animations.releaseFrontPlatform, speed, nil, true)
		self:playAnimation(spec.animations.closeGrippers, -1, nil, true)

		spec.emptyState = BaleLoader.EMPTY_WAIT_TO_SINK
	elseif id == BaleLoader.CHANGE_SINK then
		if spec.animations.emptyRotateReset then
			self:playAnimation(spec.animations.emptyRotate, -1, nil, true)
		end

		self:playAnimation(spec.animations.moveBalePlacesToEmpty, spec.animations.moveBalePlacesToEmptyReverseSpeed, nil, true)

		if spec.animations.moveBalePlacesResetOnSink then
			self:playAnimation(spec.animations.moveBalePlaces, -999999, nil, true)
		end

		self:playAnimation(spec.animations.pusherEmptyHide1, -1, nil, true)
		self:playAnimation(spec.animations.rotatePlatformEmpty, -1, nil, true)

		if not spec.isInWorkPosition then
			self:playAnimation(spec.animations.closeGrippers, 1, self:getAnimationTime(spec.animations.closeGrippers), true)
		end

		spec.emptyState = BaleLoader.EMPTY_SINK
	elseif id == BaleLoader.CHANGE_EMPTY_REDO then
		self:playAnimation(spec.animations.emptyRotate, 1, nil, true)

		spec.emptyState = BaleLoader.EMPTY_ROTATE2
	elseif id == BaleLoader.CHANGE_EMPTY_START then
		if GS_IS_MOBILE_VERSION then
			if self.rootVehicle:getActionControllerDirection() > 0 then
				spec.controlledAction.parent:startActionSequence()
			end

			spec.emptyState = BaleLoader.EMPTY_TO_WORK
		else
			BaleLoader.moveToWorkPosition(self)

			spec.emptyState = BaleLoader.EMPTY_TO_WORK
		end
	elseif id == BaleLoader.CHANGE_EMPTY_CANCEL then
		self:playAnimation(spec.animations.emptyRotate, -1, nil, true)

		spec.emptyState = BaleLoader.EMPTY_CANCEL
	elseif id == BaleLoader.CHANGE_MOVE_TO_TRANSPORT then
		if spec.isInWorkPosition then
			spec.grabberIsMoving = true
			spec.isInWorkPosition = false

			g_animationManager:stopAnimations(spec.animationNodes)
			g_soundManager:stopSample(spec.samples.work)
			BaleLoader.moveToTransportPosition(self)
		end
	elseif id == BaleLoader.CHANGE_MOVE_TO_WORK then
		if not spec.isInWorkPosition then
			spec.grabberIsMoving = true
			spec.isInWorkPosition = true

			if not spec.animationNodesBlocked then
				g_animationManager:startAnimations(spec.animationNodes)
				g_soundManager:playSample(spec.samples.work)
			end

			BaleLoader.moveToWorkPosition(self)
		end
	elseif id == BaleLoader.CHANGE_GRAB_BALE then
		local bale = NetworkUtil.getObject(nearestBaleServerId)
		spec.baleGrabber.currentBale = nearestBaleServerId

		if bale ~= nil then
			if spec.dynamicMount.enabled then
				self:mountDynamicBale(bale, spec.baleGrabber.grabNode)
			else
				self:mountBale(bale, self, spec.baleGrabber.grabNode, 0, 0, 0, 0, 0, 0, true)
			end

			bale:setCanBeSold(false)

			local baleType = self:getBaleTypeByBale(bale)

			if baleType ~= nil then
				self:setBaleLoaderBaleType(baleType.index)
			end

			spec.balesToMount[nearestBaleServerId] = nil
		else
			spec.balesToMount[nearestBaleServerId] = {
				serverId = nearestBaleServerId,
				linkNode = spec.baleGrabber.grabNode,
				trans = {
					0,
					0,
					0
				},
				rot = {
					0,
					0,
					0
				}
			}
		end

		spec.grabberMoveState = BaleLoader.GRAB_MOVE_UP

		self:playAnimation(spec.animations.baleGrabberWorkToDrop, 1, nil, true)
		self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, 1, self:getFillUnitFirstSupportedFillType(spec.fillUnitIndex), ToolType.UNDEFINED, nil)

		if self.isClient then
			g_soundManager:playSample(spec.samples.grab)

			if bale ~= nil then
				g_effectManager:setFillType(spec.grabberEffects, bale:getFillType())
				g_effectManager:startEffects(spec.grabberEffects)

				spec.grabberEffectDisableTime = g_currentMission.time + spec.grabberEffectDisableDuration
			end
		end
	elseif id == BaleLoader.CHANGE_GRAB_MOVE_UP then
		spec.currentBaleGrabberDropBaleAnimName = self:getBaleGrabberDropBaleAnimName()

		self:playAnimation(spec.currentBaleGrabberDropBaleAnimName, 1, nil, true)

		spec.grabberMoveState = BaleLoader.GRAB_DROP_BALE
	elseif id == BaleLoader.CHANGE_GRAB_DROP_BALE then
		if spec.startBalePlace ~= nil and spec.startBalePlace.count < spec.startBalePlace.numOfPlaces and spec.startBalePlace.node ~= nil then
			local attachNode = getChildAt(spec.startBalePlace.node, spec.startBalePlace.count)
			local bale = NetworkUtil.getObject(spec.baleGrabber.currentBale)

			if bale ~= nil then
				if spec.dynamicMount.enabled then
					self:mountDynamicBale(bale, attachNode)
				else
					local rx = 0
					local ry = 0
					local rz = 0

					if spec.keepBaleRotationDuringLoad then
						rx, ry, rz = localRotationToLocal(bale.nodeId, attachNode, 0, 0, 0)
					end

					self:mountBale(bale, self, attachNode, 0, 0, 0, rx, ry, rz)
				end

				spec.balesToMount[spec.baleGrabber.currentBale] = nil
			else
				spec.balesToMount[spec.baleGrabber.currentBale] = {
					serverId = spec.baleGrabber.currentBale,
					linkNode = attachNode,
					trans = {
						0,
						0,
						0
					},
					rot = {
						0,
						0,
						0
					}
				}
			end

			spec.startBalePlace.count = spec.startBalePlace.count + 1

			table.insert(spec.startBalePlace.bales, spec.baleGrabber.currentBale)

			spec.baleGrabber.currentBale = nil

			self:updateFoldingAnimation()

			if spec.startBalePlace.count < spec.startBalePlace.numOfPlaces then
				spec.frontBalePusherDirection = 1

				self:playAnimation(spec.animations.balesToOtherRow, 1, nil, true)
				self:playAnimation(spec.animations.frontBalePusher, 1, nil, true)
			elseif spec.startBalePlace.count == spec.startBalePlace.numOfPlaces then
				BaleLoader.rotatePlatform(self)
			end

			if spec.animations.baleGrabberDropToWork ~= nil then
				self:playAnimation(spec.animations.baleGrabberDropToWork, 1, 0, true)
			else
				self:playAnimation(spec.currentBaleGrabberDropBaleAnimName, -spec.animations.baleGrabberDropBaleReverseSpeed, nil, true)
				self:playAnimation(spec.animations.baleGrabberWorkToDrop, -1, nil, true)
			end

			spec.grabberMoveState = BaleLoader.GRAB_MOVE_DOWN
		end
	elseif id == BaleLoader.CHANGE_GRAB_MOVE_DOWN then
		spec.grabberMoveState = nil
	elseif id == BaleLoader.CHANGE_FRONT_PUSHER then
		if spec.frontBalePusherDirection > 0 then
			self:playAnimation(spec.animations.frontBalePusher, -1, nil, true)

			spec.frontBalePusherDirection = -1
		else
			spec.frontBalePusherDirection = 0
		end
	elseif id == BaleLoader.CHANGE_ROTATE_PLATFORM then
		if spec.startBalePlace ~= nil and spec.rotatePlatformDirection > 0 then
			local balePlace = spec.balePlaces[spec.startBalePlace.current]
			spec.startBalePlace.current = spec.startBalePlace.current + 1

			for i = 1, table.getn(spec.startBalePlace.bales) do
				local node = getChildAt(spec.startBalePlace.node, i - 1)
				local x, y, z = getTranslation(node)
				local rx, ry, rz = getRotation(node)
				local baleServerId = spec.startBalePlace.bales[i]
				local bale = NetworkUtil.getObject(baleServerId)

				if bale ~= nil then
					if spec.keepBaleRotationDuringLoad then
						x, y, z = localToLocal(bale.nodeId, balePlace.node, 0, 0, 0)
						rx, ry, rz = localRotationToLocal(bale.nodeId, balePlace.node, 0, 0, 0)
					end

					if spec.dynamicMount.enabled then
						self:mountDynamicBale(bale, balePlace.node)
					else
						self:mountBale(bale, self, balePlace.node, x, y, z, rx, ry, rz)
					end

					spec.balesToMount[baleServerId] = nil
				else
					spec.balesToMount[baleServerId] = {
						serverId = baleServerId,
						linkNode = balePlace.node,
						trans = {
							x,
							y,
							z
						},
						rot = {
							rx,
							ry,
							rz
						}
					}
				end
			end

			balePlace.bales = spec.startBalePlace.bales
			spec.startBalePlace.bales = {}
			spec.startBalePlace.count = 0

			self:updateFoldingAnimation()

			for i = 1, spec.startBalePlace.numOfPlaces do
				local node = getChildAt(spec.startBalePlace.node, i - 1)

				setRotation(node, unpack(spec.startBalePlace.origRot[i]))
				setTranslation(node, unpack(spec.startBalePlace.origTrans[i]))
			end

			if spec.emptyState == BaleLoader.EMPTY_NONE then
				if self:getAnimationTime(spec.animations.baleGrabberWorkToDrop) < spec.animations.moveBalePlacesMaxGrabberTime or spec.animations.moveBalePlacesMaxGrabberTime == math.huge then
					spec.rotatePlatformDirection = -1

					self:playAnimation(spec.animations.rotatePlatformBack, -1, nil, true)

					if spec.animations.moveBalePlacesAfterRotatePlatform and (spec.startBalePlace.current <= table.getn(spec.balePlaces) or spec.animations.moveBalePlacesAlways) then
						self:playAnimation(spec.animations.moveBalePlaces, 1, (spec.startBalePlace.current - 1) / table.getn(spec.balePlaces), true)
						self:setAnimationStopTime(spec.animations.moveBalePlaces, spec.startBalePlace.current / table.getn(spec.balePlaces))
						self:playAnimation(spec.animations.moveBalePlacesExtrasOnce, 1, nil, true)
					end
				else
					spec.rotatePlatformDirection = -1
					spec.moveBalePlacesDelayedMovement = true
				end
			else
				spec.rotatePlatformDirection = 0
			end
		else
			spec.rotatePlatformDirection = 0
		end
	elseif id == BaleLoader.CHANGE_EMPTY_ROTATE_PLATFORM then
		spec.emptyState = BaleLoader.EMPTY_ROTATE_PLATFORM

		if spec.startBalePlace ~= nil and spec.startBalePlace.count == 0 then
			self:playAnimation(spec.animations.rotatePlatformEmpty, 1, nil, true)
		else
			BaleLoader.rotatePlatform(self)
		end
	elseif id == BaleLoader.CHANGE_EMPTY_ROTATE1 then
		self:playAnimation(spec.animations.emptyRotate, 1, nil, true)
		self:setAnimationStopTime(spec.animations.emptyRotate, 0.2)

		local balePlacesTime = self:getRealAnimationTime(spec.animations.moveBalePlaces)
		local pusherAnimSpeed = spec.animations.moveBalePlacesToEmptySpeed

		if spec.animations.pusherPushBalesOnEmpty and spec.startBalePlace ~= nil then
			local usedPlaces = spec.startBalePlace.current

			if #spec.startBalePlace.bales == 0 then
				usedPlaces = usedPlaces - 1
			end

			local placeTargetTime = 1 - balePlacesTime / self:getAnimationDuration(spec.animations.moveBalePlacesToEmpty)
			local pusherTargetTime = 1 - usedPlaces / #spec.balePlaces
			pusherAnimSpeed = spec.animations.moveBalePlacesToEmptySpeed * pusherTargetTime / placeTargetTime

			self:playAnimation(spec.animations.pusherMoveToEmpty, pusherAnimSpeed, 0, true)
			self:setAnimationStopTime(spec.animations.pusherMoveToEmpty, pusherTargetTime)
		else
			self:playAnimation(spec.animations.pusherMoveToEmpty, spec.animations.moveBalePlacesToEmptySpeed, balePlacesTime / self:getAnimationDuration(spec.animations.pusherMoveToEmpty), true)
		end

		local allowOffset = true
		local lastPlace = spec.balePlaces[spec.startBalePlace.current - 1]

		if lastPlace ~= nil and #lastPlace.bales < spec.startBalePlace.numOfPlaces then
			allowOffset = false
		end

		if spec.animations.moveBalePlacesToEmptyPushOffset > 0 and allowOffset then
			spec.animations.moveBalePlacesToEmptyPushOffsetDelay = spec.animations.moveBalePlacesToEmptyPushOffset * self:getAnimationDuration(spec.animations.pusherMoveToEmpty) / pusherAnimSpeed
			spec.animations.moveBalePlacesToEmptyPushOffsetTime = spec.animations.moveBalePlacesToEmptyPushOffsetDelay
		else
			self:playAnimation(spec.animations.moveBalePlacesToEmpty, spec.animations.moveBalePlacesToEmptySpeed, balePlacesTime / self:getAnimationDuration(spec.animations.moveBalePlacesToEmpty), true)
		end

		spec.emptyState = BaleLoader.EMPTY_ROTATE1

		if self.isClient then
			g_soundManager:playSample(spec.samples.emptyRotate)
		end
	elseif id == BaleLoader.CHANGE_EMPTY_CLOSE_GRIPPERS then
		self:playAnimation(spec.animations.closeGrippers, 1, nil, true)

		spec.emptyState = BaleLoader.EMPTY_CLOSE_GRIPPERS
	elseif id == BaleLoader.CHANGE_EMPTY_HIDE_PUSHER1 then
		self:playAnimation(spec.animations.pusherEmptyHide1, 1, nil, true)

		spec.emptyState = BaleLoader.EMPTY_HIDE_PUSHER1
	elseif id == BaleLoader.CHANGE_EMPTY_HIDE_PUSHER2 then
		if spec.animations.pusherHideOnEmpty then
			self:playAnimation(spec.animations.pusherMoveToEmpty, -2, nil, true)

			spec.emptyState = BaleLoader.EMPTY_HIDE_PUSHER2
		elseif self.isServer then
			g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_ROTATE2), true, nil, self)
		end
	elseif id == BaleLoader.CHANGE_EMPTY_ROTATE2 then
		self:playAnimation(spec.animations.emptyRotate, 1, self:getAnimationTime(spec.animations.emptyRotate), true)

		spec.emptyState = BaleLoader.EMPTY_ROTATE2
	elseif id == BaleLoader.CHANGE_EMPTY_WAIT_TO_DROP then
		spec.emptyState = BaleLoader.EMPTY_WAIT_TO_DROP
	elseif id == BaleLoader.CHANGE_EMPTY_STATE_NIL then
		spec.emptyState = BaleLoader.EMPTY_NONE

		if GS_IS_MOBILE_VERSION then
			if self.rootVehicle:getActionControllerDirection() < 0 then
				spec.controlledAction.parent:startActionSequence()
			end
		elseif spec.transportPositionAfterUnloading then
			BaleLoader.moveToTransportPosition(self)

			if self.isServer then
				g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_MOVE_TO_TRANSPORT), true, nil, self)
			end
		end

		spec.automaticUnloadingInProgress = false
	elseif id == BaleLoader.CHANGE_EMPTY_WAIT_TO_REDO then
		spec.emptyState = BaleLoader.EMPTY_WAIT_TO_REDO
	elseif id == BaleLoader.CHANGE_BUTTON_EMPTY then
		assert(self.isServer)

		if spec.emptyState ~= BaleLoader.EMPTY_NONE then
			if spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
				g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_DROP_BALES), true, nil, self)
			elseif spec.emptyState == BaleLoader.EMPTY_WAIT_TO_SINK then
				if not spec.unloadingMover.isActive then
					g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_SINK), true, nil, self)
				end
			elseif spec.emptyState == BaleLoader.EMPTY_WAIT_TO_REDO then
				g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_REDO), true, nil, self)
			end
		elseif BaleLoader.getAllowsStartUnloading(self) then
			g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_START), true, nil, self)
		end
	elseif id == BaleLoader.CHANGE_BUTTON_EMPTY_ABORT then
		assert(self.isServer)

		if spec.emptyState ~= BaleLoader.EMPTY_NONE and spec.emptyState == BaleLoader.EMPTY_WAIT_TO_DROP then
			g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_EMPTY_CANCEL), true, nil, self)
		end
	elseif id == BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT then
		assert(self.isServer)

		if spec.emptyState == BaleLoader.EMPTY_NONE and spec.grabberMoveState == nil then
			if spec.isInWorkPosition then
				g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_MOVE_TO_TRANSPORT), true, nil, self)
			else
				g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_MOVE_TO_WORK), true, nil, self)
			end
		end
	end
end

function BaleLoader:getAllowsStartUnloading()
	local spec = self.spec_baleLoader

	if self:getFillUnitFillLevel(spec.fillUnitIndex) == 0 then
		return false
	end

	if spec.rotatePlatformDirection ~= 0 then
		return false
	end

	if spec.frontBalePusherDirection ~= 0 then
		return false
	end

	if spec.grabberIsMoving or spec.grabberMoveState ~= nil then
		return false
	end

	if spec.emptyState ~= BaleLoader.EMPTY_NONE then
		return false
	end

	return true
end

function BaleLoader:rotatePlatform()
	local spec = self.spec_baleLoader
	spec.rotatePlatformDirection = 1

	self:playAnimation(spec.animations.rotatePlatform, 1, nil, true)

	if spec.startBalePlace.current > 1 and not spec.animations.moveBalePlacesAfterRotatePlatform or spec.animations.moveBalePlacesAlways then
		self:playAnimation(spec.animations.moveBalePlaces, 1, (spec.startBalePlace.current - 1) / table.getn(spec.balePlaces), true)
		self:setAnimationStopTime(spec.animations.moveBalePlaces, spec.startBalePlace.current / table.getn(spec.balePlaces))
		self:playAnimation(spec.animations.moveBalePlacesExtrasOnce, 1, nil, true)
	end
end

function BaleLoader:moveToWorkPosition(onLoad)
	local spec = self.spec_baleLoader
	local speed = 1

	if onLoad then
		speed = 9999
	end

	self:playBaleLoaderFoldingAnimation(speed)

	local animTime = nil

	if self:getAnimationTime(spec.animations.closeGrippers) ~= 0 then
		animTime = self:getAnimationTime(spec.animations.closeGrippers)
	end

	self:playAnimation(spec.animations.closeGrippers, -1, animTime, true)
end

function BaleLoader:moveToTransportPosition()
	self:playBaleLoaderFoldingAnimation(-1)

	local spec = self.spec_baleLoader

	self:playAnimation(spec.animations.closeGrippers, 1, MathUtil.clamp(self:getAnimationTime(spec.animations.closeGrippers), 0, 1), true)
end

function BaleLoader:getBaleGrabberDropBaleAnimName()
	local spec = self.spec_baleLoader
	local name = string.format("%s%d", spec.animations.baleGrabberDropBale, spec.startBalePlace.count)

	if self:getAnimationExists(name) then
		return name
	end

	return spec.animations.baleGrabberDropBale
end

function BaleLoader:getIsBaleGrabbingAllowed()
	local spec = self.spec_baleLoader

	if not spec.isInWorkPosition then
		return false
	end

	if spec.grabberIsMoving or spec.grabberMoveState ~= nil then
		return false
	end

	if spec.startBalePlace.numOfPlaces <= spec.startBalePlace.count then
		return false
	end

	if spec.frontBalePusherDirection ~= 0 then
		return false
	end

	if not spec.animations.rotatePlatformAllowPickup and spec.rotatePlatformDirection ~= 0 then
		return false
	end

	if spec.animations.moveBalePlacesAlways and self:getIsAnimationPlaying(spec.animations.moveBalePlaces) then
		return false
	end

	if spec.emptyState ~= BaleLoader.EMPTY_NONE then
		return false
	end

	if self:getFillUnitFreeCapacity(spec.fillUnitIndex) == 0 then
		return false
	end

	return true
end

function BaleLoader:pickupBale(nearestBale, nearestBaleType)
	local spec = self.spec_baleLoader
	spec.lastPickupTime = g_time

	self:setBaleLoaderBaleType(nearestBaleType.index)
	g_server:broadcastEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_GRAB_BALE, NetworkUtil.getObjectId(nearestBale)), true, nil, self)
end

function BaleLoader:setBaleLoaderBaleType(baleTypeIndex, forceUpdate)
	local spec = self.spec_baleLoader
	local newBaleType = spec.baleTypes[baleTypeIndex] or spec.baleTypes[1]

	if newBaleType ~= spec.currentBaleType then
		spec.currentBaleType = newBaleType
		spec.animations = newBaleType.animations

		if not spec.useSharedBalePlaces then
			if newBaleType.startBalePlace.node ~= nil then
				spec.startBalePlace = newBaleType.startBalePlace
			else
				spec.startBalePlace = spec.defaultBalePlace.startBalePlace
			end

			if #newBaleType.balePlaces > 0 then
				spec.balePlaces = newBaleType.balePlaces
			else
				spec.balePlaces = spec.defaultBalePlace.balePlaces
			end
		end

		spec.fillUnitIndex = newBaleType.fillUnitIndex

		for i = 1, #spec.baleTypes do
			local baleType = spec.baleTypes[i]
			local fillUnit = self:getFillUnitByIndex(baleType.fillUnitIndex)
			fillUnit.showOnHud = baleType.fillUnitIndex == spec.fillUnitIndex
		end

		ObjectChangeUtil.setObjectChanges(newBaleType.changeObjects, true, self, self.setMovingToolDirty, forceUpdate)
	end
end

function BaleLoader:getBaleTypeByBale(bale)
	local spec = self.spec_baleLoader
	local foundBaleType = nil

	for _, baleType in pairs(spec.baleTypes) do
		local dimensions = baleType.dimensions

		if dimensions.isRoundbale then
			if dimensions.isRoundbale and dimensions.minWidth <= bale.width and bale.width <= dimensions.maxWidth and dimensions.minDiameter <= bale.diameter and bale.diameter <= dimensions.maxDiameter then
				foundBaleType = baleType

				break
			end
		elseif not dimensions.isRoundbale and dimensions.minWidth <= bale.width and bale.width <= dimensions.maxWidth and dimensions.minHeight <= bale.height and bale.height <= dimensions.maxHeight and dimensions.minLength <= bale.length and bale.length <= dimensions.maxLength then
			foundBaleType = baleType

			break
		end
	end

	return foundBaleType
end

function BaleLoader:baleGrabberTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if otherId ~= 0 then
		local rigidBodyType = getRigidBodyType(otherId)

		if self.isServer and rigidBodyType == RigidBodyType.DYNAMIC or not self.isServer and rigidBodyType == RigidBodyType.KINEMATIC then
			local object = g_currentMission:getNodeObject(otherId)

			if object ~= nil and object:isa(Bale) then
				local spec = self.spec_baleLoader

				if onEnter then
					spec.baleGrabber.balesInTrigger[object] = Utils.getNoNil(spec.baleGrabber.balesInTrigger[object], 0) + 1
				elseif onLeave and spec.baleGrabber.balesInTrigger[object] ~= nil then
					spec.baleGrabber.balesInTrigger[object] = math.max(0, spec.baleGrabber.balesInTrigger[object] - 1)

					if spec.baleGrabber.balesInTrigger[object] == 0 then
						spec.baleGrabber.balesInTrigger[object] = nil
					end
				end
			end
		end
	end
end

function BaleLoader:baleLoaderMoveTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
	if otherId ~= 0 and getRigidBodyType(otherId) == RigidBodyType.DYNAMIC then
		local object = g_currentMission:getNodeObject(otherId)

		if object ~= nil and object:isa(Bale) then
			local spec = self.spec_baleLoader

			if onEnter then
				spec.unloadingMover.balesInTrigger[object] = Utils.getNoNil(spec.unloadingMover.balesInTrigger[object], 0) + 1

				if spec.unloadingMover.balesInTrigger[object] == 1 then
					object:addDeleteListener(self, "onBaleMoverBaleRemoved")
				end
			elseif onLeave and spec.unloadingMover.balesInTrigger[object] ~= nil then
				spec.unloadingMover.balesInTrigger[object] = math.max(0, spec.unloadingMover.balesInTrigger[object] - 1)

				if spec.unloadingMover.balesInTrigger[object] == 0 then
					spec.unloadingMover.balesInTrigger[object] = nil

					object:removeDeleteListener(self, "onBaleMoverBaleRemoved")
				end
			end
		end
	end
end

function BaleLoader:mountDynamicBale(bale, node)
	local spec = self.spec_baleLoader

	if self.isServer then
		if bale.dynamicMountJointIndex ~= nil then
			local x, y, z = getWorldTranslation(bale.dynamicMountJointNode)
			local rx, ry, rz = getWorldRotation(bale.dynamicMountJointNode)

			link(node, bale.dynamicMountJointNode)
			setWorldTranslation(bale.dynamicMountJointNode, x, y, z)
			setWorldRotation(bale.dynamicMountJointNode, rx, ry, rz)
			setJointFrame(bale.dynamicMountJointIndex, 0, bale.dynamicMountJointNode)

			if spec.dynamicMount.jointInterpolation then
				table.insert(spec.dynamicMount.baleJointsToUpdate, {
					time = 0,
					node = bale.dynamicMountJointNode
				})
			end
		else
			local jointNode = createTransformGroup("baleJoint")

			link(node, jointNode)

			if spec.dynamicMount.jointInterpolation then
				setWorldTranslation(jointNode, getWorldTranslation(bale.nodeId))
				setWorldRotation(jointNode, getWorldRotation(bale.nodeId))
			else
				local x, y, z = getWorldTranslation(jointNode)
				local quatX, quatY, quatZ, quatW = getWorldQuaternion(jointNode)

				removeFromPhysics(bale.nodeId)
				bale:setWorldPositionQuaternion(x, y, z, quatX, quatY, quatZ, quatW, true)
				addToPhysics(bale.nodeId)
				link(jointNode, bale.meshNode)
			end

			local jointComponent = self:getParentComponent(node)

			bale:mountDynamic(self, jointComponent, jointNode, DynamicMountUtil.TYPE_FIX_ATTACH, 0, false)

			if spec.dynamicMount.minTransLimits ~= nil and spec.dynamicMount.maxTransLimits ~= nil then
				for i = 1, 3 do
					local active = spec.dynamicMount.minTransLimits[i] ~= 0 or spec.dynamicMount.maxTransLimits[i] ~= 0

					if active then
						setJointTranslationLimit(bale.dynamicMountJointIndex, i - 1, active, spec.dynamicMount.minTransLimits[i], spec.dynamicMount.maxTransLimits[i])
					end
				end
			end

			if spec.dynamicMount.jointInterpolation then
				table.insert(spec.dynamicMount.baleJointsToUpdate, {
					time = 0,
					node = jointNode
				})
			end

			spec.dynamicMount.jointNode = jointNode
			spec.dynamicMount.baleMassDirty = true

			g_currentMission.itemSystem:removeItemToSave(bale)
		end
	end
end

function BaleLoader:unmountDynamicBale(bale)
	if self.isServer then
		local spec = self.spec_baleLoader

		bale:unmountDynamic()

		if spec.dynamicMount.jointNode ~= nil then
			delete(spec.dynamicMount.jointNode)

			spec.dynamicMount.jointNode = nil
		end

		spec.dynamicMount.baleJointsToUpdate = {}

		if bale.backupMass ~= nil then
			setMass(bale.nodeId, bale.backupMass)

			bale.backupMass = nil
		end

		g_currentMission.itemSystem:addItemToSave(bale)
	end
end

function BaleLoader:mountBale(bale, object, node, x, y, z, rx, ry, rz, noKinematicMounting)
	local spec = self.spec_baleLoader

	if spec.unloadingMover.balesInTrigger[bale] ~= nil then
		spec.unloadingMover.balesInTrigger[bale] = nil
	end

	if noKinematicMounting == true then
		bale:mount(object, node, x, y, z, rx, ry, rz)
	else
		bale:mountKinematic(object, node, x, y, z, rx, ry, rz)
	end

	if not table.hasElement(spec.kinematicMountedBales, bale) then
		self:setBalePairCollision(bale, false)
		table.addElement(spec.kinematicMountedBales, bale)
	end
end

function BaleLoader:unmountBale(bale)
	local spec = self.spec_baleLoader

	if bale.dynamicMountType == MountableObject.MOUNT_TYPE_DEFAULT then
		bale:unmount()
	elseif bale.dynamicMountType == MountableObject.MOUNT_TYPE_KINEMATIC then
		bale:unmountKinematic()
	end

	table.removeElement(spec.kinematicMountedBales, bale)
	self:setBalePairCollision(bale, true)
end

function BaleLoader:setBalePairCollision(bale, state)
	local spec = self.spec_baleLoader

	for i = 1, #self.components do
		setPairCollision(self.components[i].node, bale.nodeId, state)
	end

	for i = 1, #spec.kinematicMountedBales do
		local bale2 = spec.kinematicMountedBales[i]

		setPairCollision(bale2.nodeId, bale.nodeId, state)
	end
end

function BaleLoader:getLoadedBales()
	local bales = {}
	local spec = self.spec_baleLoader

	for _, balePlace in pairs(spec.balePlaces) do
		if balePlace.bales ~= nil then
			for _, baleServerId in pairs(balePlace.bales) do
				local bale = NetworkUtil.getObject(baleServerId)

				if bale ~= nil then
					table.insert(bales, bale)
				end
			end
		end
	end

	for _, baleServerId in ipairs(spec.startBalePlace.bales) do
		local bale = NetworkUtil.getObject(baleServerId)

		if bale ~= nil then
			table.insert(bales, bale)
		end
	end

	return bales
end

function BaleLoader:startAutomaticBaleUnloading()
	local spec = self.spec_baleLoader

	if spec.emptyState == BaleLoader.EMPTY_NONE then
		spec.automaticUnloadingInProgress = true

		g_client:getServerConnection():sendEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_BUTTON_EMPTY))
	end
end

function BaleLoader:getIsAutomaticBaleUnloadingInProgress()
	return self.spec_baleLoader.automaticUnloadingInProgress
end

function BaleLoader:getIsAutomaticBaleUnloadingAllowed()
	if self:getIsAutomaticBaleUnloadingInProgress() then
		return false
	end

	if g_time < self.spec_baleLoader.lastPickupTime + self.spec_baleLoader.lastPickupAutomatedUnloadingDelayTime then
		return false
	end

	if not BaleLoader.getAllowsStartUnloading(self) then
		return false
	end

	return true
end

function BaleLoader:playBaleLoaderFoldingAnimation(speed)
	local animationName = self:getCurrentFoldingAnimation()

	self:playAnimation(animationName, speed, MathUtil.clamp(self:getAnimationTime(animationName), 0, 1), true)
end

function BaleLoader:getIsBaleLoaderFoldingPlaying()
	return self:getIsAnimationPlaying(self:getCurrentFoldingAnimation())
end

function BaleLoader:getCurrentFoldingAnimation()
	local spec = self.spec_baleLoader

	if not spec.hasMultipleFoldingAnimations then
		return spec.animations.baleGrabberTransportToWork
	end

	return spec.lastFoldingAnimation
end

function BaleLoader:updateFoldingAnimation()
	local spec = self.spec_baleLoader
	local name = spec.animations.baleGrabberTransportToWork
	local fillLevel = MathUtil.round(self:getFillUnitFillLevel(spec.fillUnitIndex))
	local balePlace = #spec.startBalePlace.bales
	local baleTypeIndex = 1

	if spec.currentBaleType ~= nil then
		baleTypeIndex = spec.currentBaleType.index
	end

	for _, foldingAnimation in ipairs(spec.foldingAnimations) do
		if (foldingAnimation.baleTypeIndex == 0 or foldingAnimation.baleTypeIndex == baleTypeIndex) and foldingAnimation.minFillLevel <= fillLevel and fillLevel <= foldingAnimation.maxFillLevel and foldingAnimation.minBalePlace <= balePlace and balePlace <= foldingAnimation.maxBalePlace then
			name = foldingAnimation.name

			break
		end
	end

	if name ~= spec.lastFoldingAnimation then
		if spec.lastFoldingAnimation ~= nil then
			local animTime = self:getAnimationTime(spec.lastFoldingAnimation)

			self:setAnimationTime(name, animTime, false)
		end

		spec.lastFoldingAnimation = name
	end
end

function BaleLoader:onBaleMoverBaleRemoved(bale)
	local spec = self.spec_baleLoader
	spec.unloadingMover.balesInTrigger[bale] = nil
end

function BaleLoader:getCanBeSelected(superFunc)
	return true
end

function BaleLoader:getAllowDynamicMountFillLevelInfo(superFunc)
	local spec = self.spec_baleLoader

	if spec.dynamicMount.enabled then
		return false
	end

	return superFunc(self)
end

function BaleLoader:addNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_baleLoader

	if spec.baleGrabber.trigger ~= nil then
		list[spec.baleGrabber.trigger] = self
	end
end

function BaleLoader:removeNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_baleLoader

	if spec.baleGrabber ~= nil and spec.baleGrabber.trigger ~= nil then
		list[spec.baleGrabber.trigger] = nil
	end
end

function BaleLoader:getAreControlledActionsAllowed(superFunc)
	if self:getIsAutomaticBaleUnloadingInProgress() then
		return false
	end

	return superFunc(self)
end

function BaleLoader:getIsAIReadyToDrive(superFunc)
	local spec = self.spec_baleLoader

	if spec.isInWorkPosition or spec.grabberIsMoving then
		return false
	end

	return superFunc(self)
end

function BaleLoader:getIsAIPreparingToDrive(superFunc)
	local spec = self.spec_baleLoader

	if spec.grabberIsMoving then
		return true
	end

	return superFunc(self)
end

function BaleLoader:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_baleLoader

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, BaleLoader.actionEventEmpty, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)

			_, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA, self, BaleLoader.actionEventWorkTransport, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)

			_, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA2, self, BaleLoader.actionEventAbortEmpty, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			g_inputBinding:setActionEventText(actionEventId, spec.texts.abortUnloading)
		end
	end
end

function BaleLoader:actionEventEmpty(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_baleLoader

	if spec.minUnloadingFillLevel <= self:getFillUnitFillLevel(spec.fillUnitIndex) or spec.emptyState ~= BaleLoader.EMPTY_NONE then
		g_client:getServerConnection():sendEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_BUTTON_EMPTY))
	else
		g_currentMission:showBlinkingWarning(spec.texts.minUnloadingFillLevelWarning, 2500)
	end
end

function BaleLoader:actionEventAbortEmpty(actionName, inputValue, callbackState, isAnalog)
	g_client:getServerConnection():sendEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_BUTTON_EMPTY_ABORT))
end

function BaleLoader:actionEventWorkTransport(actionName, inputValue, callbackState, isAnalog)
	g_client:getServerConnection():sendEvent(BaleLoaderStateEvent.new(self, BaleLoader.CHANGE_BUTTON_WORK_TRANSPORT))
end

function BaleLoader.loadSpecValueBaleSize(xmlFile, customEnvironment, roundBaleLoader)
	local rootName = xmlFile:getRootName()
	local baleSizeAttributes = {
		maxDiameter = -math.huge,
		minDiameter = math.huge,
		maxLength = -math.huge,
		minLength = math.huge
	}

	xmlFile:iterate(rootName .. ".baleLoader.baleTypes.baleType", function (_, key)
		if (xmlFile:getValue(key .. "#diameter") ~= nil or xmlFile:getValue(key .. "#minDiameter") ~= nil or xmlFile:getValue(key .. "#maxDiameter") ~= nil) == roundBaleLoader then
			local diameter = MathUtil.round(xmlFile:getValue(key .. "#diameter"), 2)
			local minDiameter = MathUtil.round(xmlFile:getValue(key .. "#minDiameter"), 2)
			local maxDiameter = MathUtil.round(xmlFile:getValue(key .. "#maxDiameter"), 2)
			baleSizeAttributes.minDiameter = math.min(baleSizeAttributes.minDiameter, diameter or baleSizeAttributes.minDiameter, minDiameter or baleSizeAttributes.minDiameter, maxDiameter or baleSizeAttributes.minDiameter)
			baleSizeAttributes.maxDiameter = math.max(baleSizeAttributes.maxDiameter, diameter or baleSizeAttributes.maxDiameter, minDiameter or baleSizeAttributes.maxDiameter, maxDiameter or baleSizeAttributes.maxDiameter)
			local length = MathUtil.round(xmlFile:getValue(key .. "#length"), 2)
			local minLength = MathUtil.round(xmlFile:getValue(key .. "#minLength"), 2)
			local maxLength = MathUtil.round(xmlFile:getValue(key .. "#maxLength"), 2)
			baleSizeAttributes.minLength = math.min(baleSizeAttributes.minLength, length or baleSizeAttributes.minLength, minLength or baleSizeAttributes.minLength, maxLength or baleSizeAttributes.minLength)
			baleSizeAttributes.maxLength = math.max(baleSizeAttributes.maxLength, length or baleSizeAttributes.maxLength, minLength or baleSizeAttributes.maxLength, maxLength or baleSizeAttributes.maxLength)
		end
	end)

	if baleSizeAttributes.minDiameter ~= math.huge or baleSizeAttributes.minLength ~= math.huge then
		return baleSizeAttributes
	end
end

function BaleLoader.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, roundBaleLoader)
	local baleSizeAttributes = roundBaleLoader and storeItem.specs.baleLoaderBaleSizeRound or storeItem.specs.baleLoaderBaleSizeSquare

	if baleSizeAttributes ~= nil then
		local minValue = roundBaleLoader and baleSizeAttributes.minDiameter or baleSizeAttributes.minLength
		local maxValue = roundBaleLoader and baleSizeAttributes.maxDiameter or baleSizeAttributes.maxLength

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

function BaleLoader.loadSpecValueBaleSizeRound(xmlFile, customEnvironment)
	return BaleLoader.loadSpecValueBaleSize(xmlFile, customEnvironment, true)
end

function BaleLoader.loadSpecValueBaleSizeSquare(xmlFile, customEnvironment)
	return BaleLoader.loadSpecValueBaleSize(xmlFile, customEnvironment, false)
end

function BaleLoader.getSpecValueBaleSizeRound(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.baleLoaderBaleSizeRound ~= nil then
		return BaleLoader.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, true)
	end
end

function BaleLoader.getSpecValueBaleSizeSquare(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.baleLoaderBaleSizeSquare ~= nil then
		return BaleLoader.getSpecValueBaleSize(storeItem, realItem, configurations, saleItem, returnValues, returnRange, false)
	end
end
