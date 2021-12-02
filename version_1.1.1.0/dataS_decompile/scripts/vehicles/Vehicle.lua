Vehicle = {}
local Vehicle_mt = Class(Vehicle, Object)
Vehicle.defaultWidth = 6
Vehicle.defaultLength = 8
Vehicle.defaultHeight = 4
Vehicle.DEFAULT_SIZE = {
	heightOffset = 0,
	lengthOffset = 0,
	widthOffset = 0,
	width = Vehicle.defaultWidth,
	length = Vehicle.defaultLength,
	height = Vehicle.defaultHeight
}
Vehicle.PROPERTY_STATE_NONE = 0
Vehicle.PROPERTY_STATE_OWNED = 1
Vehicle.PROPERTY_STATE_LEASED = 2
Vehicle.PROPERTY_STATE_MISSION = 3
Vehicle.PROPERTY_STATE_SHOP_CONFIG = 4
Vehicle.LOAD_STEP_CREATED = 0
Vehicle.LOAD_STEP_PRE_LOAD = 1
Vehicle.LOAD_STEP_AWAIT_I3D = 2
Vehicle.LOAD_STEP_LOAD = 3
Vehicle.LOAD_STEP_POST_LOAD = 4
Vehicle.LOAD_STEP_AWAIT_SUB_I3D = 5
Vehicle.LOAD_STEP_FINISHED = 6
Vehicle.LOAD_STEP_SYNCHRONIZED = 7
Vehicle.SPRING_SCALE = 10
Vehicle.NUM_INTERACTION_FLAGS = 0
Vehicle.INTERACTION_FLAG_NONE = 0
Vehicle.NUM_STATE_CHANGES = 0
Vehicle.DAMAGED_SPEEDLIMIT_REDUCTION = 0.3
Vehicle.INPUT_CONTEXT_NAME = "VEHICLE"
Vehicle.xmlSchema = nil
Vehicle.xmlSchemaSounds = nil
Vehicle.xmlSchemaSavegame = nil
Vehicle.DEBUG_NETWORK_READ_WRITE = false
Vehicle.DEBUG_NETWORK_READ_WRITE_UPDATE = false

InitStaticObjectClass(Vehicle, "Vehicle", ObjectIds.OBJECT_VEHICLE)
source("dataS/scripts/vehicles/VehicleDebug.lua")
source("dataS/scripts/vehicles/VehicleHudUtils.lua")
source("dataS/scripts/vehicles/VehicleSchemaOverlayData.lua")
source("dataS/scripts/vehicles/VehicleBrokenEvent.lua")
source("dataS/scripts/vehicles/VehicleSetIsReconfiguratingEvent.lua")

function Vehicle.registerInteractionFlag(name)
	local key = "INTERACTION_FLAG_" .. string.upper(name)

	if Vehicle[key] == nil then
		Vehicle.NUM_INTERACTION_FLAGS = Vehicle.NUM_INTERACTION_FLAGS + 1
		Vehicle[key] = Vehicle.NUM_INTERACTION_FLAGS
	end
end

function Vehicle.registerStateChange(name)
	local key = "STATE_CHANGE_" .. string.upper(name)

	if Vehicle[key] == nil then
		Vehicle.NUM_STATE_CHANGES = Vehicle.NUM_STATE_CHANGES + 1
		Vehicle[key] = Vehicle.NUM_STATE_CHANGES
	end
end

function Vehicle.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onPreLoad")
	SpecializationUtil.registerEvent(vehicleType, "onLoad")
	SpecializationUtil.registerEvent(vehicleType, "onPostLoad")
	SpecializationUtil.registerEvent(vehicleType, "onPreLoadFinished")
	SpecializationUtil.registerEvent(vehicleType, "onLoadFinished")
	SpecializationUtil.registerEvent(vehicleType, "onPreDelete")
	SpecializationUtil.registerEvent(vehicleType, "onDelete")
	SpecializationUtil.registerEvent(vehicleType, "onSave")
	SpecializationUtil.registerEvent(vehicleType, "onReadStream")
	SpecializationUtil.registerEvent(vehicleType, "onWriteStream")
	SpecializationUtil.registerEvent(vehicleType, "onReadUpdateStream")
	SpecializationUtil.registerEvent(vehicleType, "onWriteUpdateStream")
	SpecializationUtil.registerEvent(vehicleType, "onReadPositionUpdateStream")
	SpecializationUtil.registerEvent(vehicleType, "onWritePositionUpdateStream")
	SpecializationUtil.registerEvent(vehicleType, "onPreUpdate")
	SpecializationUtil.registerEvent(vehicleType, "onUpdate")
	SpecializationUtil.registerEvent(vehicleType, "onUpdateInterpolation")
	SpecializationUtil.registerEvent(vehicleType, "onUpdateDebug")
	SpecializationUtil.registerEvent(vehicleType, "onPostUpdate")
	SpecializationUtil.registerEvent(vehicleType, "onUpdateTick")
	SpecializationUtil.registerEvent(vehicleType, "onPostUpdateTick")
	SpecializationUtil.registerEvent(vehicleType, "onUpdateEnd")
	SpecializationUtil.registerEvent(vehicleType, "onDraw")
	SpecializationUtil.registerEvent(vehicleType, "onDrawUIInfo")
	SpecializationUtil.registerEvent(vehicleType, "onActivate")
	SpecializationUtil.registerEvent(vehicleType, "onDeactivate")
	SpecializationUtil.registerEvent(vehicleType, "onStateChange")
	SpecializationUtil.registerEvent(vehicleType, "onRegisterActionEvents")
	SpecializationUtil.registerEvent(vehicleType, "onRootVehicleChanged")
	SpecializationUtil.registerEvent(vehicleType, "onSelect")
	SpecializationUtil.registerEvent(vehicleType, "onUnselect")
	SpecializationUtil.registerEvent(vehicleType, "onSetBroken")
end

function Vehicle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setOwnerFarmId", Vehicle.setOwnerFarmId)
	SpecializationUtil.registerFunction(vehicleType, "loadSubSharedI3DFile", Vehicle.loadSubSharedI3DFile)
	SpecializationUtil.registerFunction(vehicleType, "drawUIInfo", Vehicle.drawUIInfo)
	SpecializationUtil.registerFunction(vehicleType, "raiseActive", Vehicle.raiseActive)
	SpecializationUtil.registerFunction(vehicleType, "setLoadingState", Vehicle.setLoadingState)
	SpecializationUtil.registerFunction(vehicleType, "setLoadingStep", Vehicle.setLoadingStep)
	SpecializationUtil.registerFunction(vehicleType, "addNodeObjectMapping", Vehicle.addNodeObjectMapping)
	SpecializationUtil.registerFunction(vehicleType, "removeNodeObjectMapping", Vehicle.removeNodeObjectMapping)
	SpecializationUtil.registerFunction(vehicleType, "addToPhysics", Vehicle.addToPhysics)
	SpecializationUtil.registerFunction(vehicleType, "removeFromPhysics", Vehicle.removeFromPhysics)
	SpecializationUtil.registerFunction(vehicleType, "setVisibility", Vehicle.setVisibility)
	SpecializationUtil.registerFunction(vehicleType, "setRelativePosition", Vehicle.setRelativePosition)
	SpecializationUtil.registerFunction(vehicleType, "setAbsolutePosition", Vehicle.setAbsolutePosition)
	SpecializationUtil.registerFunction(vehicleType, "getLimitedVehicleYPosition", Vehicle.getLimitedVehicleYPosition)
	SpecializationUtil.registerFunction(vehicleType, "setWorldPosition", Vehicle.setWorldPosition)
	SpecializationUtil.registerFunction(vehicleType, "setWorldPositionQuaternion", Vehicle.setWorldPositionQuaternion)
	SpecializationUtil.registerFunction(vehicleType, "updateVehicleSpeed", Vehicle.updateVehicleSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getUpdatePriority", Vehicle.getUpdatePriority)
	SpecializationUtil.registerFunction(vehicleType, "getPrice", Vehicle.getPrice)
	SpecializationUtil.registerFunction(vehicleType, "getSellPrice", Vehicle.getSellPrice)
	SpecializationUtil.registerFunction(vehicleType, "getDailyUpkeep", Vehicle.getDailyUpkeep)
	SpecializationUtil.registerFunction(vehicleType, "getIsOnField", Vehicle.getIsOnField)
	SpecializationUtil.registerFunction(vehicleType, "getParentComponent", Vehicle.getParentComponent)
	SpecializationUtil.registerFunction(vehicleType, "getLastSpeed", Vehicle.getLastSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getDeactivateOnLeave", Vehicle.getDeactivateOnLeave)
	SpecializationUtil.registerFunction(vehicleType, "getOwner", Vehicle.getOwner)
	SpecializationUtil.registerFunction(vehicleType, "getIsVehicleNode", Vehicle.getIsVehicleNode)
	SpecializationUtil.registerFunction(vehicleType, "getIsOperating", Vehicle.getIsOperating)
	SpecializationUtil.registerFunction(vehicleType, "getIsActive", Vehicle.getIsActive)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForInput", Vehicle.getIsActiveForInput)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForSound", Vehicle.getIsActiveForSound)
	SpecializationUtil.registerFunction(vehicleType, "getIsLowered", Vehicle.getIsLowered)
	SpecializationUtil.registerFunction(vehicleType, "updateWaterInfo", Vehicle.updateWaterInfo)
	SpecializationUtil.registerFunction(vehicleType, "onWaterRaycastCallback", Vehicle.onWaterRaycastCallback)
	SpecializationUtil.registerFunction(vehicleType, "setBroken", Vehicle.setBroken)
	SpecializationUtil.registerFunction(vehicleType, "getVehicleDamage", Vehicle.getVehicleDamage)
	SpecializationUtil.registerFunction(vehicleType, "getRepairPrice", Vehicle.getRepairPrice)
	SpecializationUtil.registerFunction(vehicleType, "getRepaintPrice", Vehicle.getRepaintPrice)
	SpecializationUtil.registerFunction(vehicleType, "setMassDirty", Vehicle.setMassDirty)
	SpecializationUtil.registerFunction(vehicleType, "updateMass", Vehicle.updateMass)
	SpecializationUtil.registerFunction(vehicleType, "getMaxComponentMassReached", Vehicle.getMaxComponentMassReached)
	SpecializationUtil.registerFunction(vehicleType, "getAdditionalComponentMass", Vehicle.getAdditionalComponentMass)
	SpecializationUtil.registerFunction(vehicleType, "getTotalMass", Vehicle.getTotalMass)
	SpecializationUtil.registerFunction(vehicleType, "getComponentMass", Vehicle.getComponentMass)
	SpecializationUtil.registerFunction(vehicleType, "getDefaultMass", Vehicle.getDefaultMass)
	SpecializationUtil.registerFunction(vehicleType, "getOverallCenterOfMass", Vehicle.getOverallCenterOfMass)
	SpecializationUtil.registerFunction(vehicleType, "getVehicleWorldXRot", Vehicle.getVehicleWorldXRot)
	SpecializationUtil.registerFunction(vehicleType, "getVehicleWorldDirection", Vehicle.getVehicleWorldDirection)
	SpecializationUtil.registerFunction(vehicleType, "getFillLevelInformation", Vehicle.getFillLevelInformation)
	SpecializationUtil.registerFunction(vehicleType, "activate", Vehicle.activate)
	SpecializationUtil.registerFunction(vehicleType, "deactivate", Vehicle.deactivate)
	SpecializationUtil.registerFunction(vehicleType, "setComponentJointFrame", Vehicle.setComponentJointFrame)
	SpecializationUtil.registerFunction(vehicleType, "setComponentJointRotLimit", Vehicle.setComponentJointRotLimit)
	SpecializationUtil.registerFunction(vehicleType, "setComponentJointTransLimit", Vehicle.setComponentJointTransLimit)
	SpecializationUtil.registerFunction(vehicleType, "loadComponentFromXML", Vehicle.loadComponentFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadComponentJointFromXML", Vehicle.loadComponentJointFromXML)
	SpecializationUtil.registerFunction(vehicleType, "createComponentJoint", Vehicle.createComponentJoint)
	SpecializationUtil.registerFunction(vehicleType, "loadSchemaOverlay", Vehicle.loadSchemaOverlay)
	SpecializationUtil.registerFunction(vehicleType, "getAdditionalSchemaText", Vehicle.getAdditionalSchemaText)
	SpecializationUtil.registerFunction(vehicleType, "dayChanged", Vehicle.dayChanged)
	SpecializationUtil.registerFunction(vehicleType, "periodChanged", Vehicle.periodChanged)
	SpecializationUtil.registerFunction(vehicleType, "raiseStateChange", Vehicle.raiseStateChange)
	SpecializationUtil.registerFunction(vehicleType, "doCheckSpeedLimit", Vehicle.doCheckSpeedLimit)
	SpecializationUtil.registerFunction(vehicleType, "interact", Vehicle.interact)
	SpecializationUtil.registerFunction(vehicleType, "getInteractionHelp", Vehicle.getInteractionHelp)
	SpecializationUtil.registerFunction(vehicleType, "getDistanceToNode", Vehicle.getDistanceToNode)
	SpecializationUtil.registerFunction(vehicleType, "getIsAIActive", Vehicle.getIsAIActive)
	SpecializationUtil.registerFunction(vehicleType, "getIsPowered", Vehicle.getIsPowered)
	SpecializationUtil.registerFunction(vehicleType, "addVehicleToAIImplementList", Vehicle.addVehicleToAIImplementList)
	SpecializationUtil.registerFunction(vehicleType, "setOperatingTime", Vehicle.setOperatingTime)
	SpecializationUtil.registerFunction(vehicleType, "requestActionEventUpdate", Vehicle.requestActionEventUpdate)
	SpecializationUtil.registerFunction(vehicleType, "removeActionEvents", Vehicle.removeActionEvents)
	SpecializationUtil.registerFunction(vehicleType, "updateActionEvents", Vehicle.updateActionEvents)
	SpecializationUtil.registerFunction(vehicleType, "registerActionEvents", Vehicle.registerActionEvents)
	SpecializationUtil.registerFunction(vehicleType, "updateSelectableObjects", Vehicle.updateSelectableObjects)
	SpecializationUtil.registerFunction(vehicleType, "registerSelectableObjects", Vehicle.registerSelectableObjects)
	SpecializationUtil.registerFunction(vehicleType, "addSubselection", Vehicle.addSubselection)
	SpecializationUtil.registerFunction(vehicleType, "getRootVehicle", Vehicle.getRootVehicle)
	SpecializationUtil.registerFunction(vehicleType, "findRootVehicle", Vehicle.findRootVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getChildVehicles", Vehicle.getChildVehicles)
	SpecializationUtil.registerFunction(vehicleType, "addChildVehicles", Vehicle.addChildVehicles)
	SpecializationUtil.registerFunction(vehicleType, "updateVehicleChain", Vehicle.updateVehicleChain)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeSelected", Vehicle.getCanBeSelected)
	SpecializationUtil.registerFunction(vehicleType, "getBlockSelection", Vehicle.getBlockSelection)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleSelectable", Vehicle.getCanToggleSelectable)
	SpecializationUtil.registerFunction(vehicleType, "unselectVehicle", Vehicle.unselectVehicle)
	SpecializationUtil.registerFunction(vehicleType, "selectVehicle", Vehicle.selectVehicle)
	SpecializationUtil.registerFunction(vehicleType, "getIsSelected", Vehicle.getIsSelected)
	SpecializationUtil.registerFunction(vehicleType, "getSelectedObject", Vehicle.getSelectedObject)
	SpecializationUtil.registerFunction(vehicleType, "getSelectedVehicle", Vehicle.getSelectedVehicle)
	SpecializationUtil.registerFunction(vehicleType, "setSelectedVehicle", Vehicle.setSelectedVehicle)
	SpecializationUtil.registerFunction(vehicleType, "setSelectedObject", Vehicle.setSelectedObject)
	SpecializationUtil.registerFunction(vehicleType, "getIsReadyForAutomatedTrainTravel", Vehicle.getIsReadyForAutomatedTrainTravel)
	SpecializationUtil.registerFunction(vehicleType, "getIsAutomaticShiftingAllowed", Vehicle.getIsAutomaticShiftingAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getSpeedLimit", Vehicle.getSpeedLimit)
	SpecializationUtil.registerFunction(vehicleType, "getRawSpeedLimit", Vehicle.getRawSpeedLimit)
	SpecializationUtil.registerFunction(vehicleType, "getActiveFarm", Vehicle.getActiveFarm)
	SpecializationUtil.registerFunction(vehicleType, "onVehicleWakeUpCallback", Vehicle.onVehicleWakeUpCallback)
	SpecializationUtil.registerFunction(vehicleType, "getCanByMounted", Vehicle.getCanByMounted)
	SpecializationUtil.registerFunction(vehicleType, "getName", Vehicle.getName)
	SpecializationUtil.registerFunction(vehicleType, "getFullName", Vehicle.getFullName)
	SpecializationUtil.registerFunction(vehicleType, "getBrand", Vehicle.getBrand)
	SpecializationUtil.registerFunction(vehicleType, "getImageFilename", Vehicle.getImageFilename)
	SpecializationUtil.registerFunction(vehicleType, "getCanBePickedUp", Vehicle.getCanBePickedUp)
	SpecializationUtil.registerFunction(vehicleType, "getCanBeReset", Vehicle.getCanBeReset)
	SpecializationUtil.registerFunction(vehicleType, "getIsInUse", Vehicle.getIsInUse)
	SpecializationUtil.registerFunction(vehicleType, "getPropertyState", Vehicle.getPropertyState)
	SpecializationUtil.registerFunction(vehicleType, "getAreControlledActionsAllowed", Vehicle.getAreControlledActionsAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getAreControlledActionsAvailable", Vehicle.getAreControlledActionsAvailable)
	SpecializationUtil.registerFunction(vehicleType, "playControlledActions", Vehicle.playControlledActions)
	SpecializationUtil.registerFunction(vehicleType, "getActionControllerDirection", Vehicle.getActionControllerDirection)
	SpecializationUtil.registerFunction(vehicleType, "createMapHotspot", Vehicle.createMapHotspot)
	SpecializationUtil.registerFunction(vehicleType, "getMapHotspot", Vehicle.getMapHotspot)
	SpecializationUtil.registerFunction(vehicleType, "updateMapHotspot", Vehicle.updateMapHotspot)
	SpecializationUtil.registerFunction(vehicleType, "getIsMapHotspotVisible", Vehicle.getIsMapHotspotVisible)
	SpecializationUtil.registerFunction(vehicleType, "showInfo", Vehicle.showInfo)
	SpecializationUtil.registerFunction(vehicleType, "loadObjectChangeValuesFromXML", Vehicle.loadObjectChangeValuesFromXML)
	SpecializationUtil.registerFunction(vehicleType, "setObjectChangeValues", Vehicle.setObjectChangeValues)
	SpecializationUtil.registerFunction(vehicleType, "getIsSynchronized", Vehicle.getIsSynchronized)
end

function Vehicle.init()
	g_configurationManager:addConfigurationType("baseColor", g_i18n:getText("configuration_baseColor"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_COLOR)
	g_configurationManager:addConfigurationType("design", g_i18n:getText("configuration_design"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_MULTIOPTION)
	g_configurationManager:addConfigurationType("designColor", g_i18n:getText("configuration_designColor"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_COLOR)
	g_configurationManager:addConfigurationType("vehicleType", g_i18n:getText("configuration_design"), nil, , ConfigurationUtil.getStoreAdditionalConfigData, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)

	for i = 2, 8 do
		g_configurationManager:addConfigurationType(string.format("design%d", i), g_i18n:getText("configuration_design"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_MULTIOPTION)
	end

	g_storeManager:addSpecType("age", "shopListAttributeIconLifeTime", nil, Vehicle.getSpecValueAge, "vehicle")
	g_storeManager:addSpecType("operatingTime", "shopListAttributeIconOperatingHours", nil, Vehicle.getSpecValueOperatingTime, "vehicle")
	g_storeManager:addSpecType("dailyUpkeep", "shopListAttributeIconMaintenanceCosts", nil, Vehicle.getSpecValueDailyUpkeep, "vehicle")
	g_storeManager:addSpecType("workingWidth", "shopListAttributeIconWorkingWidth", Vehicle.loadSpecValueWorkingWidth, Vehicle.getSpecValueWorkingWidth, "vehicle")
	g_storeManager:addSpecType("workingWidthConfig", "shopListAttributeIconWorkingWidth", Vehicle.loadSpecValueWorkingWidthConfig, Vehicle.getSpecValueWorkingWidthConfig, "vehicle")
	g_storeManager:addSpecType("speedLimit", "shopListAttributeIconWorkSpeed", Vehicle.loadSpecValueSpeedLimit, Vehicle.getSpecValueSpeedLimit, "vehicle")
	g_storeManager:addSpecType("weight", "shopListAttributeIconWeight", Vehicle.loadSpecValueWeight, Vehicle.getSpecValueWeight, "vehicle", nil, Vehicle.getSpecConfigValuesWeight)
	g_storeManager:addSpecType("additionalWeight", "shopListAttributeIconAdditionalWeight", Vehicle.loadSpecValueAdditionalWeight, Vehicle.getSpecValueAdditionalWeight, "vehicle")
	g_storeManager:addSpecType("combinations", nil, Vehicle.loadSpecValueCombinations, Vehicle.getSpecValueCombinations, "vehicle")
	g_storeManager:addSpecType("slots", "shopListAttributeIconSlots", nil, Vehicle.getSpecValueSlots, "vehicle")

	Vehicle.xmlSchema = XMLSchema.new("vehicle")
	Vehicle.xmlSchemaSounds = XMLSchema.new("vehicle_sounds")

	Vehicle.xmlSchemaSounds:setRootNodeName("sounds")
	Vehicle.xmlSchema:addSubSchema(Vehicle.xmlSchemaSounds, "sounds")

	Vehicle.xmlSchemaSavegame = XMLSchema.new("savegame_vehicles")

	Vehicle.registers()
end

function Vehicle.postInit()
	local schema = Vehicle.xmlSchema

	for name, _ in pairs(g_configurationManager:getConfigurations()) do
		local specializationKey = g_configurationManager:getConfigurationAttribute(name, "xmlKey")

		if specializationKey ~= nil then
			specializationKey = "." .. specializationKey
		else
			specializationKey = ""
		end

		local configrationsKey = string.format("vehicle%s.%sConfigurations", specializationKey, name)
		local configrationKey = string.format("%s.%sConfiguration(?)", configrationsKey, name)

		schema:setXMLSharedRegistration("configSize", configrationKey)
		schema:register(XMLValueType.FLOAT, configrationKey .. ".size#width", "occupied width of the vehicle when loaded in this configuration")
		schema:register(XMLValueType.FLOAT, configrationKey .. ".size#length", "occupied length of the vehicle when loaded in this configuration")
		schema:register(XMLValueType.FLOAT, configrationKey .. ".size#height", "occupied height of the vehicle when loaded in this configuration")
		schema:register(XMLValueType.FLOAT, configrationKey .. ".size#widthOffset", "width offset")
		schema:register(XMLValueType.FLOAT, configrationKey .. ".size#lengthOffset", "length offset")
		schema:register(XMLValueType.FLOAT, configrationKey .. ".size#heightOffset", "height offset")
		schema:setXMLSharedRegistration()
		schema:register(XMLValueType.L10N_STRING, configrationsKey .. "#title", "Configration title to display in shop")
		schema:register(XMLValueType.L10N_STRING, configrationKey .. "#name", "Configuration name")
		schema:register(XMLValueType.STRING, configrationKey .. "#params", "Extra paramters to insert in #name text")
		schema:register(XMLValueType.L10N_STRING, configrationKey .. "#desc", "Configuration description")
		schema:register(XMLValueType.FLOAT, configrationKey .. "#price", "Price of configuration", 0)
		schema:register(XMLValueType.FLOAT, configrationKey .. "#dailyUpkeep", "Daily up keep with this configration", 0)
		schema:register(XMLValueType.BOOL, configrationKey .. "#isDefault", "Is selected by default in shop config screen", false)
		schema:register(XMLValueType.BOOL, configrationKey .. "#isSelectable", "Configuration can be selected in the shop", true)
		schema:register(XMLValueType.STRING, configrationKey .. "#saveId", "Custom save id", "Number of configuration")
		schema:register(XMLValueType.STRING, configrationKey .. "#displayBrand", "If defined a brand icon is displayed in the shop config screen")
		schema:register(XMLValueType.STRING, configrationKey .. "#vehicleBrand", "Custom brand to display after bought with this configuration")
		schema:register(XMLValueType.STRING, configrationKey .. "#vehicleName", "Custom vehicle name to display after bought with this configuration")
		schema:register(XMLValueType.STRING, configrationKey .. "#vehicleIcon", "Custom icon to display after bought with this configuration")
		schema:register(XMLValueType.FLOAT, configrationKey .. "#workingWidth", "Work width to display in shop while config is active")
		ConfigurationUtil.registerMaterialConfigurationXMLPaths(schema, configrationKey)
	end
end

function Vehicle.registers()
	local schema = Vehicle.xmlSchema
	local schemaSavegame = Vehicle.xmlSchemaSavegame

	schema:register(XMLValueType.STRING, "vehicle#type", "Vehicle type")
	schema:register(XMLValueType.STRING, "vehicle.annotation", "Annotation", nil, true)
	StoreManager.registerStoreDataXMLPaths(schema, "vehicle")
	schema:register(XMLValueType.STRING, "vehicle.storeData.specs.workingWidth", "Working width to display in shop")
	schema:register(XMLValueType.STRING, "vehicle.storeData.specs.combination(?)#xmlFilename", "Combination to display in shop")
	schema:register(XMLValueType.STRING, "vehicle.storeData.specs.combination(?)#filterCategory", "Filter in this category")
	schema:register(XMLValueType.STRING, "vehicle.storeData.specs.combination(?)#filterSpec", "Filter for this spec type")
	schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.combination(?)#filterSpecMin", "Filter spec type in this range (min.)")
	schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.combination(?)#filterSpecMax", "Filter spec type in this range (max.)")
	schema:register(XMLValueType.BOOL, "vehicle.storeData.specs.weight#ignore", "Hide vehicle weight in shop", false)
	schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.weight#minValue", "Min. weight to display in shop")
	schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.weight#maxValue", "Max. weight to display in shop")
	schema:register(XMLValueType.STRING, "vehicle.storeData.specs.weight.config(?)#name", "Name of configuration")
	schema:register(XMLValueType.INT, "vehicle.storeData.specs.weight.config(?)#index", "Index of selected configuration")
	schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.weight.config(?)#value", "Weight value which can be reached with this configuration")
	schema:register(XMLValueType.STRING, "vehicle.base.filename", "Path to i3d filename", nil)
	schema:register(XMLValueType.L10N_STRING, "vehicle.base.typeDesc", "Type description", nil)
	schema:register(XMLValueType.BOOL, "vehicle.base.synchronizePosition", "Vehicle position synchronized", true)
	schema:register(XMLValueType.BOOL, "vehicle.base.supportsPickUp", "Vehicle can be picked up by hand", "true if vehicle is a pallet, false otherwise")
	schema:register(XMLValueType.BOOL, "vehicle.base.canBeReset", "Vehicle can be reset to shop", true)
	schema:register(XMLValueType.BOOL, "vehicle.base.showInVehicleMenu", "Vehicle shows in vehicle menu", true)
	schema:register(XMLValueType.BOOL, "vehicle.base.supportsRadio", "Vehicle supported radio", true)
	schema:register(XMLValueType.BOOL, "vehicle.base.input#allowed", "Vehicle allows key input", true)
	schema:register(XMLValueType.FLOAT, "vehicle.base.tailwaterDepth#warning", "Tailwater depth warning is shown from this water depth", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.base.tailwaterDepth#threshold", "Vehicle is broken after this water depth", 2.5)
	schema:register(XMLValueType.STRING, "vehicle.base.mapHotspot#type", "Map hotspot type")
	schema:register(XMLValueType.BOOL, "vehicle.base.mapHotspot#hasDirection", "Map hotspot has direction")
	schema:register(XMLValueType.BOOL, "vehicle.base.mapHotspot#available", "Map hotspot is available", true)
	schema:register(XMLValueType.FLOAT, "vehicle.base.speedLimit#value", "Speed limit")
	schema:register(XMLValueType.FLOAT, "vehicle.base.size#width", "Occupied width of the vehicle when loaded", nil, true)
	schema:register(XMLValueType.FLOAT, "vehicle.base.size#length", "Occupied length of the vehicle when loaded", nil, true)
	schema:register(XMLValueType.FLOAT, "vehicle.base.size#height", "Occupied height of the vehicle when loaded")
	schema:register(XMLValueType.FLOAT, "vehicle.base.size#widthOffset", "Width offset")
	schema:register(XMLValueType.FLOAT, "vehicle.base.size#lengthOffset", "Width offset")
	schema:register(XMLValueType.FLOAT, "vehicle.base.size#heightOffset", "Height offset")
	schema:register(XMLValueType.ANGLE, "vehicle.base.size#yRotation", "Y Rotation offset in i3d (Needs to be set to the vehicle's rotation in the i3d file and is e.g. used to check ai working direction)", 0)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.base.steeringAxle#node", "Steering axle node used to calculate the steering angle of attachments")
	schema:register(XMLValueType.STRING, "vehicle.base.sounds#filename", "Path to external sound files")
	schema:register(XMLValueType.FLOAT, "vehicle.base.sounds#volumeFactor", "This factor will be applied to all sounds of this vehicle")
	I3DUtil.registerI3dMappingXMLPaths(schema, "vehicle")
	schema:register(XMLValueType.INT, "vehicle.base.components#numComponents", "Number of components loaded from i3d", "number of components the i3d contains")
	schema:register(XMLValueType.FLOAT, "vehicle.base.components#maxMass", "Max. overall mass the vehicle can have", "unlimited")
	schema:register(XMLValueType.FLOAT, "vehicle.base.components.component(?)#mass", "Mass of component", "Mass of component in i3d")
	schema:register(XMLValueType.VECTOR_TRANS, "vehicle.base.components.component(?)#centerOfMass", "Center of mass", "Center of mass in i3d")
	schema:register(XMLValueType.INT, "vehicle.base.components.component(?)#solverIterationCount", "Solver iterations count")
	schema:register(XMLValueType.BOOL, "vehicle.base.components.component(?)#motorized", "Is motorized component", "set by motorized specialization")
	schema:register(XMLValueType.BOOL, "vehicle.base.components.component(?)#collideWithAttachables", "Collides with attachables", false)
	schema:register(XMLValueType.INT, "vehicle.base.components.joint(?)#component1", "First component of the joint")
	schema:register(XMLValueType.INT, "vehicle.base.components.joint(?)#component2", "Second component of the joint")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.base.components.joint(?)#node", "Joint node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.base.components.joint(?)#nodeActor1", "Actor node of second component", "Joint node")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#rotLimit", "Rotation limit", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#transLimit", "Translation limit", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#rotMinLimit", "Min rotation limit", "inversed rotation limit")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#transMinLimit", "Min translation limit", "inversed translation limit")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#rotLimitSpring", "Rotation spring limit", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#rotLimitDamping", "Rotation damping limit", "1 1 1")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#rotLimitForceLimit", "Rotation limit force limit (-1 = infinite)", "-1 -1 -1")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#transLimitForceLimit", "Translation limit force limit (-1 = infinite)", "-1 -1 -1")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#transLimitSpring", "Translation spring limit", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#transLimitDamping", "Translation damping limit", "1 1 1")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.base.components.joint(?)#zRotationNode", "Position of joints z rotation")
	schema:register(XMLValueType.BOOL, "vehicle.base.components.joint(?)#breakable", "Joint is breakable", false)
	schema:register(XMLValueType.FLOAT, "vehicle.base.components.joint(?)#breakForce", "Joint force until it breaks", 10)
	schema:register(XMLValueType.FLOAT, "vehicle.base.components.joint(?)#breakTorque", "Joint torque until it breaks", 10)
	schema:register(XMLValueType.BOOL, "vehicle.base.components.joint(?)#enableCollision", "Enable collision between both components", false)
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#maxRotDriveForce", "Max rotational drive force", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#rotDriveVelocity", "Rotational drive velocity")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#rotDriveRotation", "Rotational drive rotation")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#rotDriveSpring", "Rotational drive spring", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#rotDriveDamping", "Rotational drive damping", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#transDriveVelocity", "Translational drive velocity")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#transDrivePosition", "Translational drive position")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#transDriveSpring", "Translational drive spring", "0 0 0")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#transDriveDamping", "Translational drive damping", "1 1 1")
	schema:register(XMLValueType.VECTOR_3, "vehicle.base.components.joint(?)#maxTransDriveForce", "Max translational drive force", "0 0 0")
	schema:register(XMLValueType.BOOL, "vehicle.base.components.joint(?)#initComponentPosition", "Defines if the component is translated and rotated during loading based on joint movement", true)
	schema:register(XMLValueType.BOOL, "vehicle.base.components.collisionPair(?)#enabled", "Collision between components enabled")
	schema:register(XMLValueType.INT, "vehicle.base.components.collisionPair(?)#component1", "Index of first component")
	schema:register(XMLValueType.INT, "vehicle.base.components.collisionPair(?)#component2", "Index of second component")
	ObjectChangeUtil.registerObjectChangesXMLPaths(schema, "vehicle.base")
	schema:register(XMLValueType.VECTOR_2, "vehicle.base.schemaOverlay#attacherJointPosition", "Position of attacher joint")
	schema:register(XMLValueType.VECTOR_2, "vehicle.base.schemaOverlay#basePosition", "Position of vehicle")
	schema:register(XMLValueType.STRING, "vehicle.base.schemaOverlay#name", "Name of schema overlay")
	schema:register(XMLValueType.FLOAT, "vehicle.base.schemaOverlay#invisibleBorderRight", "Size of invisible border on the right")
	schema:register(XMLValueType.FLOAT, "vehicle.base.schemaOverlay#invisibleBorderLeft", "Size of invisible border on the left")
	ConfigurationUtil.registerColorConfigurationXMLPaths(schema, "baseColor")
	ConfigurationUtil.registerColorConfigurationXMLPaths(schema, "designColor")
	ConfigurationUtil.registerColorConfigurationXMLPaths(schema, "design")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.designConfigurations.designConfiguration(?)")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.vehicleTypeConfigurations.vehicleTypeConfiguration(?)")
	schema:register(XMLValueType.STRING, "vehicle.vehicleTypeConfigurations.vehicleTypeConfiguration(?)#vehicleType", "Vehicle type for configuration")

	for i = 2, 8 do
		ConfigurationUtil.registerColorConfigurationXMLPaths(schema, string.format("design%d", i))
		ObjectChangeUtil.registerObjectChangeXMLPaths(schema, string.format("vehicle.design%dConfigurations.design%dConfiguration(?)", i, i))
	end

	schema:register(XMLValueType.BOOL, "vehicle.designConfigurations#preLoad", "Defines if the design configurations are applied before the execution of load or after. Can help if the configurations manipulate the wheel positions for example.", false)
	StoreItemUtil.registerConfigurationSetXMLPaths(schema, "vehicle")
	schemaSavegame:register(XMLValueType.BOOL, "vehicles#loadAnyFarmInSingleplayer", "Load any farm in singleplayer", false)
	schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?)#filename", "XML filename")
	schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?)#modName", "Vehicle mod name")
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)#defaultFarmProperty", "Property of default farm", false)
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?)#id", "Vehicle id")
	schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?)#tourId", "Tour id")
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?)#farmId", "Farm id")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?)#age", "Age in number of months")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?)#price", "Price")
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?)#propertyState", "Property state")
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?)#activeMissionId", "Active mission id")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?)#operatingTime", "Operating time")
	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?)#isAbsolute", "Position is Absolute")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?)#yOffset", "Y Offset")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?)#xPosition", "X Position")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?)#zPosition", "Z Position")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?)#yRotation", "Y Rotation")
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?)#selectedObjectIndex", "Selected object index")
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?)#subSelectedObjectIndex", "Sub selected object index")
	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).component(?)#index", "Component index")
	schemaSavegame:register(XMLValueType.VECTOR_TRANS, "vehicles.vehicle(?).component(?)#position", "Component position")
	schemaSavegame:register(XMLValueType.VECTOR_ROT, "vehicles.vehicle(?).component(?)#rotation", "Component rotation")
	schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).boughtConfiguration(?)#name", "Configuration name")
	schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).boughtConfiguration(?)#id", "Configuration save id")
	schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).configuration(?)#name", "Configuration name")
	schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).configuration(?)#id", "Configuration save id")
	VehicleActionController.registerXMLPaths(schemaSavegame, "vehicles.vehicle(?).actionController")
	schemaSavegame:register(XMLValueType.INT, "vehicles.attachments(?)#rootVehicleId", "Id of root vehicle")
end

function Vehicle.new(isServer, isClient, customMt)
	local self = Object.new(isServer, isClient, customMt or Vehicle_mt)
	self.finishedLoading = false
	self.isAddedToMission = false
	self.isDeleted = false
	self.updateLoopIndex = -1
	self.sharedLoadRequestId = nil
	self.loadingState = VehicleLoadingUtil.VEHICLE_LOAD_OK
	self.loadingStep = Vehicle.LOAD_STEP_CREATED
	self.syncVehicleLoadingFinished = false
	self.subLoadingTasksFinished = true
	self.numPendingSubLoadingTasks = 0
	self.synchronizedConnections = {}
	self.actionController = VehicleActionController.new(self)
	self.tireTrackSystem = g_currentMission.tireTrackSystem

	return self
end

function Vehicle:load(vehicleData, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	if asyncCallbackFunction == nil then
		Logging.xmlWarning(self.xmlFile, "Missing async callback function for '%s'", vehicleData.filename)
		self:setLoadingState(VehicleLoadingUtil.VEHICLE_LOAD_ERROR)
		printCallstack()

		return self.loadingState
	end

	local modName, baseDirectory = Utils.getModNameAndBaseDirectory(vehicleData.filename)

	self:setLoadingStep(Vehicle.LOAD_STEP_PRE_LOAD)

	self.configFileName = vehicleData.filename
	self.configFileNameClean = Utils.getFilenameInfo(vehicleData.filename, true)
	self.baseDirectory = baseDirectory
	self.customEnvironment = modName
	self.typeName = vehicleData.typeName
	self.isVehicleSaved = Utils.getNoNil(vehicleData.isVehicleSaved, true)
	self.configurations = Utils.getNoNil(vehicleData.configurations, {})
	self.boughtConfigurations = Utils.getNoNil(vehicleData.boughtConfigurations, {})
	local typeDef = g_vehicleTypeManager:getTypeByName(self.typeName)

	if typeDef == nil then
		Logging.xmlWarning(self.xmlFile, "Unable to find vehicleType '%s'", self.typeName)
		self:setLoadingState(VehicleLoadingUtil.VEHICLE_LOAD_ERROR)

		return self.loadingState
	end

	self.type = typeDef
	self.specializations = typeDef.specializations
	self.specializationNames = typeDef.specializationNames
	self.specializationsByName = typeDef.specializationsByName
	self.eventListeners = table.copy(typeDef.eventListeners, 2)
	self.actionEvents = {}
	self.xmlFile = XMLFile.load("vehicleXml", vehicleData.filename, Vehicle.xmlSchema)
	self.savegame = vehicleData.savegame
	self.isAddedToPhysics = false
	self.additionalLoadParameters = vehicleData.additionalLoadParameters
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if storeItem ~= nil then
		self.brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)
		self.lifetime = storeItem.lifetime
	end

	self.externalSoundsFilename = self.xmlFile:getValue("vehicle.base.sounds#filename")

	if self.externalSoundsFilename ~= nil then
		self.externalSoundsFilename = Utils.getFilename(self.externalSoundsFilename, self.baseDirectory)
		self.externalSoundsFile = XMLFile.load("TempExternalSounds", self.externalSoundsFilename, Vehicle.xmlSchemaSounds)
	end

	self.soundVolumeFactor = self.xmlFile:getValue("vehicle.base.sounds#volumeFactor")

	for funcName, func in pairs(typeDef.functions) do
		self[funcName] = func
	end

	local data = {
		{
			posX = vehicleData.posX,
			posY = vehicleData.posY,
			posZ = vehicleData.posZ,
			yOffset = vehicleData.yOffset,
			isAbsolute = vehicleData.isAbsolute
		},
		{
			rotX = vehicleData.rotX,
			rotY = vehicleData.rotY,
			rotZ = vehicleData.rotZ
		},
		vehicleData.isVehicleSaved,
		vehicleData.propertyState,
		vehicleData.ownerFarmId,
		vehicleData.price,
		vehicleData.savegame,
		asyncCallbackFunction,
		asyncCallbackObject,
		asyncCallbackArguments,
		vehicleData.componentPositions
	}
	local item = g_storeManager:getItemByXMLFilename(self.configFileName)

	if item ~= nil and item.configurations ~= nil then
		if item.configurationSets ~= nil and #item.configurationSets > 0 and not StoreItemUtil.getConfigurationsMatchConfigSets(self.configurations, item.configurationSets) then
			local closestSet, closestSetMatches = StoreItemUtil.getClosestConfigurationSet(self.configurations, item.configurationSets)

			if closestSet ~= nil then
				for configName, index in pairs(closestSet.configurations) do
					self.configurations[configName] = index
				end

				Logging.xmlInfo(self.xmlFile, "Savegame configurations to not match the configuration sets! Apply closest configuration set '%s' with %d matching configurations.", closestSet.name, closestSetMatches)
			end
		end

		for configName, _ in pairs(item.configurations) do
			local defaultConfigId = StoreItemUtil.getDefaultConfigId(item, configName)

			if self.configurations[configName] == nil then
				ConfigurationUtil.setConfiguration(self, configName, defaultConfigId)
			end

			ConfigurationUtil.addBoughtConfiguration(self, configName, defaultConfigId)
		end

		for configName, value in pairs(self.configurations) do
			if item.configurations[configName] == nil then
				Logging.xmlWarning(self.xmlFile, "Configurations are not present anymore. Ignoring this configuration (%s)!", configName)

				self.configurations[configName] = nil
				self.boughtConfigurations[configName] = nil
			else
				local defaultConfigId = StoreItemUtil.getDefaultConfigId(item, configName)

				if value > #item.configurations[configName] then
					Logging.xmlWarning(self.xmlFile, "Configuration with index '%d' is not present anymore. Using default configuration instead!", value)

					if self.boughtConfigurations[configName] ~= nil then
						self.boughtConfigurations[configName][value] = nil

						if next(self.boughtConfigurations[configName]) == nil then
							self.boughtConfigurations[configName] = nil
						end
					end

					ConfigurationUtil.setConfiguration(self, configName, defaultConfigId)
				else
					ConfigurationUtil.addBoughtConfiguration(self, configName, value)
				end
			end
		end
	end

	for i = 1, #self.specializations do
		local specEntryName = "spec_" .. self.specializationNames[i]

		if self[specEntryName] ~= nil then
			Logging.xmlError(self.xmlFile, "The vehicle specialization '%s' could not be added because variable '%s' already exists!", self.specializationNames[i], specEntryName)
			self:setLoadingState(VehicleLoadingUtil.VEHICLE_LOAD_ERROR)
		end

		local env = {}

		setmetatable(env, {
			__index = self
		})

		env.actionEvents = {}
		self[specEntryName] = env
	end

	SpecializationUtil.raiseEvent(self, "onPreLoad", vehicleData.savegame)

	if self.loadingState ~= VehicleLoadingUtil.VEHICLE_LOAD_OK then
		Logging.xmlError(self.xmlFile, "Vehicle pre-loading failed!")
		self.xmlFile:delete()
		asyncCallbackFunction(asyncCallbackObject, nil, self.loadingState, asyncCallbackArguments)

		return
	end

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.filename", "vehicle.base.filename")

	self.i3dFilename = Utils.getFilename(self.xmlFile:getValue("vehicle.base.filename"), baseDirectory)

	self:setLoadingStep(Vehicle.LOAD_STEP_AWAIT_I3D)

	self.sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(self.i3dFilename, true, false, self.loadFinished, self, data)
end

function Vehicle:loadFinished(i3dNode, failedReason, arguments, i3dLoadingId)
	self:setLoadingState(VehicleLoadingUtil.VEHICLE_LOAD_OK)
	self:setLoadingStep(Vehicle.LOAD_STEP_LOAD)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.forcedMapHotspotType", "vehicle.base.mapHotspot#type")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.forcedMapHotspotType", "vehicle.base.mapHotspot#type")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.speedLimit#value", "vehicle.base.speedLimit#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.steeringAxleNode#index", "vehicle.base.steeringAxle#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.size#width", "vehicle.base.size#width")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.size#length", "vehicle.base.size#length")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.size#widthOffset", "vehicle.base.size#widthOffset")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.size#lengthOffset", "vehicle.base.size#lengthOffset")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.typeDesc", "vehicle.base.typeDesc")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.components", "vehicle.base.components")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.components.component", "vehicle.base.components.component")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.components.component1", "vehicle.base.components.component")

	local position, rotation, _, propertyState, ownerFarmId, price, savegame, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments, componentPositions = unpack(arguments)

	if i3dNode == 0 then
		self:setLoadingState(VehicleLoadingUtil.VEHICLE_LOAD_ERROR)
		Logging.xmlError(self.xmlFile, "Vehicle i3d loading failed!")
		self.xmlFile:delete()
		asyncCallbackFunction(asyncCallbackObject, nil, self.loadingState, asyncCallbackArguments)

		return
	end

	if savegame ~= nil then
		local i = 0

		while true do
			local key = string.format(savegame.key .. ".boughtConfiguration(%d)", i)

			if not savegame.xmlFile:hasProperty(key) then
				break
			end

			local name = savegame.xmlFile:getValue(key .. "#name")
			local id = savegame.xmlFile:getValue(key .. "#id")

			ConfigurationUtil.addBoughtConfiguration(self, name, ConfigurationUtil.getConfigIdBySaveId(self.configFileName, name, id))

			i = i + 1
		end

		self.tourId = nil
		local tourId = savegame.xmlFile:getValue(savegame.key .. "#tourId")

		if tourId ~= nil then
			self.tourId = tourId

			if g_currentMission ~= nil then
				g_currentMission.guidedTour:addVehicle(self, self.tourId)
			end
		end
	end

	self.age = 0
	self.propertyState = propertyState

	self:setOwnerFarmId(ownerFarmId, true)

	if savegame ~= nil then
		local farmId = savegame.xmlFile:getValue(savegame.key .. "#farmId", AccessHandler.EVERYONE)

		if g_farmManager.spFarmWasMerged and farmId ~= AccessHandler.EVERYONE then
			farmId = FarmManager.SINGLEPLAYER_FARM_ID
		end

		self:setOwnerFarmId(farmId, true)
	end

	self.price = price

	if self.price == 0 or self.price == nil then
		local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
		self.price = StoreItemUtil.getDefaultPrice(storeItem, self.configurations)
	end

	self.typeDesc = self.xmlFile:getValue("vehicle.base.typeDesc", "TypeDescription", self.customEnvironment, true)
	self.synchronizePosition = self.xmlFile:getValue("vehicle.base.synchronizePosition", true)
	self.highPrecisionPositionSynchronization = false
	self.supportsPickUp = self.xmlFile:getValue("vehicle.base.supportsPickUp", self.typeName == "pallet")
	self.canBeReset = self.xmlFile:getValue("vehicle.base.canBeReset", true)
	self.showInVehicleMenu = self.xmlFile:getValue("vehicle.base.showInVehicleMenu", true)
	self.rootNode = getChildAt(i3dNode, 0)
	self.serverMass = 0
	self.precalculatedMass = 0
	self.isMassDirty = false
	self.currentUpdateDistance = 0
	self.lastDistanceToCamera = 0
	self.lodDistanceCoeff = getLODDistanceCoeff()
	self.components = {}
	self.vehicleNodes = {}
	local realNumComponents = getNumOfChildren(i3dNode)
	local rootPosition = {
		0,
		0,
		0
	}
	local i = 1
	local numComponents = self.xmlFile:getValue("vehicle.base.components#numComponents", realNumComponents)
	self.maxComponentMass = self.xmlFile:getValue("vehicle.base.components#maxMass", math.huge) / 1000

	while true do
		local namei = string.format("vehicle.base.components.component(%d)", i - 1)

		if not self.xmlFile:hasProperty(namei) then
			break
		end

		if numComponents < i then
			Logging.xmlWarning(self.xmlFile, "Invalid components count. I3D file has '%d' components, but tried to load component no. '%d'!", numComponents, i + 1)

			break
		end

		local component = {
			node = getChildAt(i3dNode, 0)
		}

		if self:loadComponentFromXML(component, self.xmlFile, namei, rootPosition, i) then
			local x, y, z = getWorldTranslation(component.node)
			local qx, qy, qz, qw = getWorldQuaternion(component.node)
			component.networkInterpolators = {
				position = InterpolatorPosition.new(x, y, z),
				quaternion = InterpolatorQuaternion.new(qx, qy, qz, qw)
			}

			table.insert(self.components, component)
		end

		i = i + 1
	end

	delete(i3dNode)

	self.numComponents = #self.components

	if numComponents ~= self.numComponents then
		Logging.xmlWarning(self.xmlFile, "I3D file offers '%d' objects, but '%d' components have been loaded!", numComponents, self.numComponents)
	end

	if self.numComponents == 0 then
		Logging.xmlWarning(self.xmlFile, "No components defined for vehicle!")
		self:setLoadingState(VehicleLoadingUtil.VEHICLE_LOAD_ERROR)
		self.xmlFile:delete()
		asyncCallbackFunction(asyncCallbackObject, nil, self.loadingState, asyncCallbackArguments)

		return
	end

	self.defaultMass = 0

	for j = 1, #self.components do
		self.defaultMass = self.defaultMass + self.components[j].defaultMass
	end

	self.i3dMappings = {}

	I3DUtil.loadI3DMapping(self.xmlFile, "vehicle", self.components, self.i3dMappings, realNumComponents)

	self.steeringAxleNode = self.xmlFile:getValue("vehicle.base.steeringAxle#node", nil, self.components, self.i3dMappings)

	if self.steeringAxleNode == nil then
		self.steeringAxleNode = self.components[1].node
	end

	self:loadSchemaOverlay(self.xmlFile)

	self.componentJoints = {}
	local componentJointI = 0

	while true do
		local key = string.format("vehicle.base.components.joint(%d)", componentJointI)
		local index1 = self.xmlFile:getValue(key .. "#component1")
		local index2 = self.xmlFile:getValue(key .. "#component2")

		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#index", key .. "#node")

		if index1 == nil or index2 == nil then
			break
		end

		local jointNode = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)

		if jointNode ~= nil and jointNode ~= 0 then
			local jointDesc = {}

			if self:loadComponentJointFromXML(jointDesc, self.xmlFile, key, componentJointI, jointNode, index1, index2) then
				table.insert(self.componentJoints, jointDesc)

				jointDesc.index = #self.componentJoints
			end
		end

		componentJointI = componentJointI + 1
	end

	local collisionPairI = 0
	self.collisionPairs = {}

	while true do
		local key = string.format("vehicle.base.components.collisionPair(%d)", collisionPairI)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local enabled = self.xmlFile:getValue(key .. "#enabled")
		local index1 = self.xmlFile:getValue(key .. "#component1")
		local index2 = self.xmlFile:getValue(key .. "#component2")

		if index1 ~= nil and index2 ~= nil and enabled ~= nil then
			local component1 = self.components[index1]
			local component2 = self.components[index2]

			if component1 ~= nil and component2 ~= nil then
				if not enabled then
					table.insert(self.collisionPairs, {
						component1 = component1,
						component2 = component2,
						enabled = enabled
					})
				end
			else
				Logging.xmlWarning(self.xmlFile, "Failed to load collision pair '%s'. Unknown component indices. Indices start with 1.", key)
			end
		end

		collisionPairI = collisionPairI + 1
	end

	self.supportsRadio = self.xmlFile:getValue("vehicle.base.supportsRadio", true)
	self.allowsInput = self.xmlFile:getValue("vehicle.base.input#allowed", true)
	self.size = StoreItemUtil.getSizeValuesFromXML(self.xmlFile, "vehicle", 0, self.configurations)
	self.yRotationOffset = self.xmlFile:getValue("vehicle.base.size#yRotation", 0)
	self.showTailwaterDepthWarning = false
	self.thresholdTailwaterDepthWarning = self.xmlFile:getValue("vehicle.base.tailwaterDepth#warning", 1)
	self.thresholdTailwaterDepth = self.xmlFile:getValue("vehicle.base.tailwaterDepth#threshold", 2.5)
	self.networkTimeInterpolator = InterpolationTime.new(1.2)
	self.movingDirection = 0
	self.requiredDriveMode = 1
	self.rotatedTime = 0
	self.isBroken = false
	self.forceIsActive = false
	self.finishedFirstUpdate = false
	self.lastPosition = nil
	self.lastSpeed = 0
	self.lastSpeedReal = 0
	self.lastSignedSpeed = 0
	self.lastSignedSpeedReal = 0
	self.lastMovedDistance = 0
	self.lastSpeedAcceleration = 0
	self.lastMoveTime = -10000
	self.operatingTime = 0
	self.isSelectable = true
	self.isInWater = false
	self.isInShallowWater = false
	self.waterY = -200
	self.tailwaterDepth = -200
	self.selectionObjects = {}
	self.currentSelection = {
		index = 0,
		subIndex = 1
	}
	self.selectionObject = {
		index = 0,
		isSelected = false,
		vehicle = self,
		subSelections = {}
	}
	self.childVehicles = {
		self
	}
	self.rootVehicle = self
	self.registeredActionEvents = {}
	self.actionEventUpdateRequested = false
	self.vehicleDirtyFlag = self:getNextDirtyFlag()

	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		g_messageCenter:subscribe(MessageType.DAY_CHANGED, self.dayChanged, self)
		g_messageCenter:subscribe(MessageType.PERIOD_CHANGED, self.periodChanged, self)
	end

	self.mapHotspotAvailable = self.xmlFile:getValue("vehicle.base.mapHotspot#available", true)

	if self.mapHotspotAvailable then
		local hotspotType = self.xmlFile:getValue("vehicle.base.mapHotspot#type", "OTHER")
		self.mapHotspotType = VehicleHotspot.getTypeByName(hotspotType) or VehicleHotspot.TYPE.OTHER
		self.mapHotspotHasDirection = self.xmlFile:getValue("vehicle.base.mapHotspot#hasDirection", true)
	end

	local speedLimit = math.huge

	for i = 1, #self.specializations do
		if self.specializations[i].getDefaultSpeedLimit ~= nil then
			local limit = self.specializations[i].getDefaultSpeedLimit(self)
			speedLimit = math.min(limit, speedLimit)
		end
	end

	self.checkSpeedLimit = speedLimit == math.huge
	self.speedLimit = self.xmlFile:getValue("vehicle.base.speedLimit#value", speedLimit)
	local objectChanges = {}

	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, "vehicle.base.objectChanges", objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(objectChanges, true)

	if self.configurations.vehicleType ~= nil then
		ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.vehicleTypeConfigurations.vehicleTypeConfiguration", self.configurations.vehicleType, self.components, self)
	end

	local preLoadDesignConfigurations = self.xmlFile:getValue("vehicle.designConfigurations#preLoad", false)

	if preLoadDesignConfigurations and self.configurations.design ~= nil then
		ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.designConfigurations.designConfiguration", self.configurations.design, self.components, self)
	end

	SpecializationUtil.raiseEvent(self, "onLoad", savegame)

	if self.loadingState ~= VehicleLoadingUtil.VEHICLE_LOAD_OK then
		Logging.xmlError(self.xmlFile, "Vehicle loading failed!")
		self.xmlFile:delete()
		asyncCallbackFunction(asyncCallbackObject, nil, self.loadingState, asyncCallbackArguments)

		return
	end

	if self.actionController ~= nil then
		self.actionController:load(savegame)
	end

	SpecializationUtil.raiseEvent(self, "onRootVehicleChanged", self)

	for configName, configId in pairs(self.configurations) do
		ConfigurationUtil.applyConfigMaterials(self, self.xmlFile, configName, configId)
	end

	if not preLoadDesignConfigurations and self.configurations.design ~= nil then
		ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.designConfigurations.designConfiguration", self.configurations.design, self.components, self)
	end

	for j = 2, 8 do
		local name = string.format("design%d", j)

		if self.configurations[name] ~= nil then
			ObjectChangeUtil.updateObjectChanges(self.xmlFile, string.format("vehicle.%sConfigurations.%sConfiguration", name, name), self.configurations[name], self.components, self)
		end
	end

	if self.configurations.baseColor ~= nil then
		ConfigurationUtil.setColor(self, self.xmlFile, "baseColor", self.configurations.baseColor)
	end

	if self.configurations.designColor ~= nil then
		ConfigurationUtil.setColor(self, self.xmlFile, "designColor", self.configurations.designColor)
	end

	if self.isServer then
		for _, jointDesc in pairs(self.componentJoints) do
			if jointDesc.initComponentPosition then
				local component2 = self.components[jointDesc.componentIndices[2]].node
				local jointNode = jointDesc.jointNode

				if self:getParentComponent(jointNode) == component2 then
					jointNode = jointDesc.jointNodeActor1
				end

				if self:getParentComponent(jointNode) ~= component2 then
					setTranslation(component2, localToLocal(component2, jointNode, 0, 0, 0))
					setRotation(component2, localRotationToLocal(component2, jointNode, 0, 0, 0))
					link(jointNode, component2)
				end
			end
		end
	end

	self:setLoadingStep(Vehicle.LOAD_STEP_POST_LOAD)
	SpecializationUtil.raiseEvent(self, "onPostLoad", savegame)

	if self.loadingState ~= VehicleLoadingUtil.VEHICLE_LOAD_OK then
		Logging.xmlError(self.xmlFile, "Vehicle post-loading failed!")
		self.xmlFile:delete()
		asyncCallbackFunction(asyncCallbackObject, nil, self.loadingState, asyncCallbackArguments)

		return
	end

	if self.isServer then
		for _, jointDesc in pairs(self.componentJoints) do
			if jointDesc.initComponentPosition then
				local component2 = self.components[jointDesc.componentIndices[2]]
				local jointNode = jointDesc.jointNode

				if self:getParentComponent(jointNode) == component2.node then
					jointNode = jointDesc.jointNodeActor1
				end

				if self:getParentComponent(jointNode) ~= component2.node then
					local ox = 0
					local oy = 0
					local oz = 0

					if jointDesc.jointNodeActor1 ~= jointDesc.jointNode then
						local x1, y1, z1 = localToLocal(jointDesc.jointNode, component2.node, 0, 0, 0)
						local x2, y2, z2 = localToLocal(jointDesc.jointNodeActor1, component2.node, 0, 0, 0)
						oz = z1 - z2
						oy = y1 - y2
						ox = x1 - x2
					end

					local x, y, z = localToWorld(component2.node, ox, oy, oz)
					local rx, ry, rz = localRotationToWorld(component2.node, 0, 0, 0)

					link(getRootNode(), component2.node)
					setWorldTranslation(component2.node, x, y, z)
					setWorldRotation(component2.node, rx, ry, rz)

					component2.originalTranslation = {
						x,
						y,
						z
					}
					component2.originalRotation = {
						rx,
						ry,
						rz
					}
					component2.sentTranslation = {
						x,
						y,
						z
					}
					component2.sentRotation = {
						rx,
						ry,
						rz
					}
				end
			end
		end

		for _, jointDesc in pairs(self.componentJoints) do
			self:setComponentJointFrame(jointDesc, 0)
			self:setComponentJointFrame(jointDesc, 1)
		end
	end

	if savegame ~= nil then
		self.currentSavegameId = savegame.xmlFile:getValue(savegame.key .. "#id")
		self.age = savegame.xmlFile:getValue(savegame.key .. "#age", 0)
		self.price = savegame.xmlFile:getValue(savegame.key .. "#price", self.price)
		self.propertyState = savegame.xmlFile:getValue(savegame.key .. "#propertyState", self.propertyState)
		self.activeMissionId = savegame.xmlFile:getValue(savegame.key .. "#activeMissionId")
		local operatingTime = savegame.xmlFile:getValue(savegame.key .. "#operatingTime", self.operatingTime) * 1000

		self:setOperatingTime(operatingTime, true)

		local findPlace = savegame.resetVehicles and not savegame.keepPosition

		if not findPlace then
			local isAbsolute = savegame.xmlFile:getValue(savegame.key .. "#isAbsolute", false)

			if isAbsolute then
				local componentPosition = {}
				local i = 0

				while true do
					local componentKey = string.format(savegame.key .. ".component(%d)", i)

					if not savegame.xmlFile:hasProperty(componentKey) then
						break
					end

					local componentIndex = savegame.xmlFile:getValue(componentKey .. "#index")
					local x, y, z = savegame.xmlFile:getValue(componentKey .. "#position")
					local xRot, yRot, zRot = savegame.xmlFile:getValue(componentKey .. "#rotation")

					if x == nil or y == nil or z == nil or xRot == nil or yRot == nil or zRot == nil then
						findPlace = true

						break
					end

					if componentPosition[componentIndex] ~= nil then
						Logging.xmlWarning(savegame.xmlFile, "Duplicate component index '%s' in '%s' (%s)!", componentIndex, savegame.key, self.xmlFile.filename)
					else
						componentPosition[componentIndex] = {
							x = x,
							y = y,
							z = z,
							xRot = xRot,
							yRot = yRot,
							zRot = zRot
						}
					end

					i = i + 1
				end

				local numSavegameComponents = table.size(componentPosition)

				if numSavegameComponents == #self.components then
					for j = 1, #self.components do
						local p = componentPosition[j]

						self:setWorldPosition(p.x, p.y, p.z, p.xRot, p.yRot, p.zRot, j, true)
					end
				elseif numSavegameComponents >= 1 then
					local p = componentPosition[1]

					self:setAbsolutePosition(p.x, p.y, p.z, p.xRot, p.yRot, p.zRot)
					Logging.xmlWarning(savegame.xmlFile, "Invalid component count found in savegame for '%s'. Reset component positions.", self.xmlFile.filename)
				else
					findPlace = true

					Logging.xmlWarning(savegame.xmlFile, "No component positions found in savegame for '%s'!", self.xmlFile.filename)
				end
			else
				local yOffset = savegame.xmlFile:getValue(savegame.key .. "#yOffset")
				local xPosition = savegame.xmlFile:getValue(savegame.key .. "#xPosition")
				local zPosition = savegame.xmlFile:getValue(savegame.key .. "#zPosition")
				local yRotation = savegame.xmlFile:getValue(savegame.key .. "#yRotation")

				if yOffset == nil or xPosition == nil or zPosition == nil or yRotation == nil then
					findPlace = true
				else
					self:setRelativePosition(xPosition, yOffset, zPosition, math.rad(yRotation))
				end
			end
		end

		if findPlace then
			if savegame.resetVehicles and not savegame.keepPosition then
				local x, _, z, place, width, offset = PlacementUtil.getPlace(g_currentMission:getResetPlaces(), self.size, g_currentMission.usedLoadPlaces, true, false, true)

				if x ~= nil then
					local yRot = MathUtil.getYRotationFromDirection(place.dirPerpX, place.dirPerpZ)

					PlacementUtil.markPlaceUsed(g_currentMission.usedLoadPlaces, place, width)
					self:setRelativePosition(x, offset, z, yRot)
				else
					self:setLoadingState(VehicleLoadingUtil.VEHICLE_LOAD_NO_SPACE)
					self.xmlFile:delete()
					asyncCallbackFunction(asyncCallbackObject, nil, self.loadingState, asyncCallbackArguments)

					return
				end
			else
				self:setLoadingState(VehicleLoadingUtil.VEHICLE_LOAD_DELAYED)
			end
		end
	else
		self:setAbsolutePosition(position.posX, self:getLimitedVehicleYPosition(position), position.posZ, rotation.rotX, rotation.rotY, rotation.rotZ, componentPositions)
	end

	self:updateSelectableObjects()
	self:setSelectedVehicle(self, nil, true)

	if self.rootVehicle == self and savegame ~= nil then
		self.loadedSelectedObjectIndex = savegame.xmlFile:getValue(savegame.key .. "#selectedObjectIndex")
		self.loadedSubSelectedObjectIndex = savegame.xmlFile:getValue(savegame.key .. "#subSelectedObjectIndex")
	end

	if componentPositions ~= nil and savegame == nil then
		self:setAbsolutePosition(position.posX, self:getLimitedVehicleYPosition(position), position.posZ, rotation.rotX, rotation.rotY, rotation.rotZ, componentPositions)
	end

	SpecializationUtil.raiseEvent(self, "onPreLoadFinished", self.savegame)
	self:addNodeObjectMapping(g_currentMission.nodeToObject)

	if not self.subLoadingTasksFinished then
		self:setLoadingStep(Vehicle.LOAD_STEP_AWAIT_SUB_I3D)
	end

	self.syncVehicleLoadingFinished = true
	self.subLoadingTasksFinishedAsyncData = {
		asyncCallbackFunction = asyncCallbackFunction,
		asyncCallbackObject = asyncCallbackObject,
		asyncCallbackArguments = asyncCallbackArguments
	}

	self:setVisibility(false)
	self:tryFinishLoading()
end

function Vehicle:loadSubSharedI3DFile(filename, callOnCreate, addToPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)
	if asyncCallbackFunction ~= nil and not self.syncVehicleLoadingFinished then
		local targetAsyncCallbackFunction = asyncCallbackFunction

		function asyncCallbackFunction(target, i3dNode, ...)
			self.numPendingSubLoadingTasks = self.numPendingSubLoadingTasks - 1
			self.subLoadingTasksFinished = self.numPendingSubLoadingTasks == 0

			if self.isDeleted or self.isDeleting then
				delete(i3dNode)
				targetAsyncCallbackFunction(target, 0, ...)

				return
			else
				targetAsyncCallbackFunction(target, i3dNode, ...)

				if self.syncVehicleLoadingFinished then
					self:tryFinishLoading()
				end
			end
		end

		self.subLoadingTasksFinished = false
		self.numPendingSubLoadingTasks = self.numPendingSubLoadingTasks + 1
	end

	local sharedLoadRequestId = g_i3DManager:loadSharedI3DFileAsync(filename, callOnCreate, addToPhysics, asyncCallbackFunction, asyncCallbackObject, asyncCallbackArguments)

	return sharedLoadRequestId
end

function Vehicle:tryFinishLoading()
	if self.subLoadingTasksFinished then
		self:setVisibility(true)
		self:addToPhysics()
		self:setLoadingStep(Vehicle.LOAD_STEP_FINISHED)
		SpecializationUtil.raiseEvent(self, "onLoadFinished", self.savegame)

		if self.isServer then
			self:setLoadingStep(Vehicle.LOAD_STEP_SYNCHRONIZED)
		end

		if g_currentMission ~= nil and self.propertyState ~= Vehicle.PROPERTY_STATE_SHOP_CONFIG and self.mapHotspotAvailable then
			self:createMapHotspot()
		end

		self.finishedLoading = true
		local asyncData = self.subLoadingTasksFinishedAsyncData

		asyncData.asyncCallbackFunction(asyncData.asyncCallbackObject, self, self.loadingState, asyncData.asyncCallbackArguments)

		self.savegame = nil
	end
end

function Vehicle:delete()
	if self.isDeleted then
		Logging.devError("Trying to delete a already deleted vehicle")
		printCallstack()

		return
	end

	VehicleDebug.delete(self)

	if self.tourId ~= nil and g_currentMission ~= nil then
		g_currentMission.guidedTour:removeVehicle(self.tourId)
	end

	self.isDeleting = true

	g_messageCenter:unsubscribeAll(self)
	self:deleteMapHotspot()

	local rootVehicle = self.rootVehicle

	if rootVehicle ~= nil and rootVehicle:getIsAIActive() then
		rootVehicle:stopCurrentAIJob(AIMessageErrorVehicleDeleted.new())
	end

	g_inputBinding:beginActionEventsModification(Vehicle.INPUT_CONTEXT_NAME)
	self:removeActionEvents()
	g_inputBinding:endActionEventsModification()
	SpecializationUtil.raiseEvent(self, "onPreDelete")
	SpecializationUtil.raiseEvent(self, "onDelete")

	if self.isServer and self.componentJoints ~= nil then
		for _, v in pairs(self.componentJoints) do
			if v.jointIndex ~= 0 then
				removeJoint(v.jointIndex)
			end
		end

		removeWakeUpReport(self.rootNode)
	end

	self:removeNodeObjectMapping(g_currentMission.nodeToObject)

	if self.components ~= nil then
		for _, v in pairs(self.components) do
			delete(v.node)
		end
	end

	if self.sharedLoadRequestId ~= nil then
		g_i3DManager:releaseSharedI3DFile(self.sharedLoadRequestId)

		self.sharedLoadRequestId = nil
	end

	self.xmlFile:delete()

	if self.externalSoundsFile ~= nil then
		self.externalSoundsFile:delete()
	end

	self.isDeleting = false
	self.isDeleted = true

	Vehicle:superClass().delete(self)

	if self.currentSavegameId ~= nil then
		g_currentMission.savegameIdToVehicle[self.currentSavegameId] = nil
	end
end

function Vehicle:saveToXMLFile(xmlFile, key, usedModNames)
	xmlFile:setValue(key .. "#id", self.currentSavegameId)
	xmlFile:setValue(key .. "#isAbsolute", true)
	xmlFile:setValue(key .. "#age", self.age)
	xmlFile:setValue(key .. "#price", self.price)
	xmlFile:setValue(key .. "#farmId", self:getOwnerFarmId())
	xmlFile:setValue(key .. "#propertyState", self.propertyState)
	xmlFile:setValue(key .. "#operatingTime", self.operatingTime / 1000)

	if self.activeMissionId ~= nil then
		xmlFile:setValue(key .. "#activeMissionId", self.activeMissionId)
	end

	if self.tourId ~= nil then
		xmlFile:setValue(key .. "#tourId", self.tourId)
	end

	if self.rootVehicle == self then
		xmlFile:setValue(key .. "#selectedObjectIndex", self.currentSelection.index)

		if self.currentSelection.subIndex ~= nil then
			xmlFile:setValue(key .. "#subSelectedObjectIndex", self.currentSelection.subIndex)
		end
	end

	if not self.isBroken then
		for k, component in ipairs(self.components) do
			local compKey = string.format("%s.component(%d)", key, k - 1)
			local node = component.node
			local x, y, z = getWorldTranslation(node)
			local xRot, yRot, zRot = getWorldRotation(node)

			xmlFile:setValue(compKey .. "#index", k)
			xmlFile:setValue(compKey .. "#position", x, y, z)
			xmlFile:setValue(compKey .. "#rotation", xRot, yRot, zRot)
		end
	end

	local configIndex = 0

	for configName, configId in pairs(self.configurations) do
		local saveId = ConfigurationUtil.getSaveIdByConfigId(self.configFileName, configName, configId)

		if saveId ~= nil then
			local configKey = string.format("%s.configuration(%d)", key, configIndex)

			xmlFile:setValue(configKey .. "#name", configName)
			xmlFile:setValue(configKey .. "#id", saveId)

			configIndex = configIndex + 1
		end
	end

	configIndex = 0

	for configName, configIds in pairs(self.boughtConfigurations) do
		for configId, _ in pairs(configIds) do
			local saveId = ConfigurationUtil.getSaveIdByConfigId(self.configFileName, configName, configId)

			if saveId ~= nil then
				local configKey = string.format("%s.boughtConfiguration(%d)", key, configIndex)

				xmlFile:setValue(configKey .. "#name", configName)
				xmlFile:setValue(configKey .. "#id", saveId)

				configIndex = configIndex + 1
			end
		end
	end

	for id, spec in pairs(self.specializations) do
		local name = self.specializationNames[id]

		if spec.saveToXMLFile ~= nil then
			spec.saveToXMLFile(self, xmlFile, key .. "." .. name, usedModNames)
		end
	end

	if self.actionController ~= nil then
		self.actionController:saveToXMLFile(xmlFile, key .. ".actionController", usedModNames)
	end
end

function Vehicle:saveStatsToXMLFile(xmlFile, key)
	local isTabbable = self.getIsTabbable == nil or self:getIsTabbable()

	if self.isDeleted or not self.isVehicleSaved or not isTabbable then
		return false
	end

	local name = "Unknown"
	local categoryName = "unknown"
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if storeItem ~= nil then
		if storeItem.name ~= nil then
			name = tostring(storeItem.name)
		end

		if storeItem.categoryName ~= nil and storeItem.categoryName ~= "" then
			categoryName = tostring(storeItem.categoryName)
		end
	end

	setXMLString(xmlFile, key .. "#name", HTMLUtil.encodeToHTML(name))
	setXMLString(xmlFile, key .. "#category", HTMLUtil.encodeToHTML(categoryName))
	setXMLString(xmlFile, key .. "#type", HTMLUtil.encodeToHTML(tostring(self.typeName)))

	if self.components[1] ~= nil and self.components[1].node ~= 0 then
		local x, y, z = getWorldTranslation(self.components[1].node)

		setXMLFloat(xmlFile, key .. "#x", x)
		setXMLFloat(xmlFile, key .. "#y", y)
		setXMLFloat(xmlFile, key .. "#z", z)
	end

	for id, spec in pairs(self.specializations) do
		if spec.saveStatsToXMLFile ~= nil then
			spec.saveStatsToXMLFile(self, xmlFile, key)
		end
	end

	return true
end

function Vehicle:readStream(streamId, connection, objectId)
	Vehicle:superClass().readStream(self, streamId, connection, objectId)
	self:setConnectionSynchronized(connection, false)

	local configFile = NetworkUtil.convertFromNetworkFilename(streamReadString(streamId))
	local typeName = streamReadString(streamId)
	local configurations = {}
	local numConfigs = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)

	for _ = 1, numConfigs do
		local configNameId = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)
		local configId = streamReadUInt16(streamId)
		local configName = g_configurationManager:getConfigurationNameByIndex(configNameId + 1)

		if configName ~= nil then
			configurations[configName] = configId + 1
		end
	end

	local boughtConfigurations = {}
	numConfigs = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)

	for _ = 1, numConfigs do
		local configNameId = streamReadUIntN(streamId, ConfigurationUtil.SEND_NUM_BITS)
		local configName = g_configurationManager:getConfigurationNameByIndex(configNameId + 1)
		boughtConfigurations[configName] = {}
		local numBoughtConfigIds = streamReadUInt16(streamId)

		for _ = 1, numBoughtConfigIds do
			local boughtConfigId = streamReadUInt16(streamId)
			boughtConfigurations[configName][boughtConfigId + 1] = true
		end
	end

	self.propertyState = streamReadUIntN(streamId, 2)

	if self.configFileName == nil then
		local vehicleData = {
			filename = configFile,
			isAbsolute = false,
			typeName = typeName,
			posX = 0,
			posY = nil,
			posZ = 0,
			yOffset = 0,
			rotX = 0,
			rotY = 0,
			rotZ = 0,
			isVehicleSaved = true,
			price = 0,
			propertyState = self.propertyState,
			ownerFarmId = self.ownerFarmId,
			isLeased = 0,
			configurations = configurations,
			boughtConfigurations = boughtConfigurations
		}
		local vehicle = self

		local function asyncCallbackFunction(_, v, loadingState, args)
			if loadingState == VehicleLoadingUtil.VEHICLE_LOAD_OK then
				g_client:onObjectFinishedAsyncLoading(vehicle)
			else
				Logging.error("Failed to load vehicle on client")

				if v ~= nil then
					v:delete()
				end

				printCallstack()

				return
			end
		end

		self:load(vehicleData, asyncCallbackFunction, self)
	end
end

function Vehicle:postReadStream(streamId, connection)
	self:removeFromPhysics()

	local paramsXZ = self.highPrecisionPositionSynchronization and g_currentMission.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosCompressionParams
	local paramsY = self.highPrecisionPositionSynchronization and g_currentMission.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosCompressionParams

	for i = 1, #self.components do
		local component = self.components[i]
		local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
		local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
		local x_rot = NetworkUtil.readCompressedAngle(streamId)
		local y_rot = NetworkUtil.readCompressedAngle(streamId)
		local z_rot = NetworkUtil.readCompressedAngle(streamId)
		local qx, qy, qz, qw = mathEulerToQuaternion(x_rot, y_rot, z_rot)

		self:setWorldPositionQuaternion(x, y, z, qx, qy, qz, qw, i, true)
		component.networkInterpolators.position:setPosition(x, y, z)
		component.networkInterpolators.quaternion:setQuaternion(qx, qy, qz, qw)
	end

	self.networkTimeInterpolator:reset()
	self:addToPhysics()

	self.serverMass = streamReadFloat32(streamId)
	self.age = streamReadUInt16(streamId)

	self:setOperatingTime(streamReadFloat32(streamId), true)

	self.price = streamReadInt32(streamId)

	if Vehicle.DEBUG_NETWORK_READ_WRITE then
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

	self:setConnectionSynchronized(connection, true)
	self:setLoadingStep(Vehicle.LOAD_STEP_SYNCHRONIZED)
end

function Vehicle:writeStream(streamId, connection)
	Vehicle:superClass().writeStream(self, streamId, connection)
	self:setConnectionSynchronized(connection, false)
	streamWriteString(streamId, NetworkUtil.convertToNetworkFilename(self.configFileName))
	streamWriteString(streamId, self.typeName)

	local numConfigs = 0

	for _, _ in pairs(self.configurations) do
		numConfigs = numConfigs + 1
	end

	streamWriteUIntN(streamId, numConfigs, ConfigurationUtil.SEND_NUM_BITS)

	for configName, configId in pairs(self.configurations) do
		local configNameId = g_configurationManager:getConfigurationIndexByName(configName)

		streamWriteUIntN(streamId, configNameId - 1, ConfigurationUtil.SEND_NUM_BITS)
		streamWriteUInt16(streamId, configId - 1)
	end

	local numBoughtConfigs = 0

	for _, _ in pairs(self.boughtConfigurations) do
		numBoughtConfigs = numBoughtConfigs + 1
	end

	streamWriteUIntN(streamId, numBoughtConfigs, ConfigurationUtil.SEND_NUM_BITS)

	for configName, configIds in pairs(self.boughtConfigurations) do
		local numBoughtConfigIds = 0

		for _, _ in pairs(configIds) do
			numBoughtConfigIds = numBoughtConfigIds + 1
		end

		local configNameId = g_configurationManager:getConfigurationIndexByName(configName)

		streamWriteUIntN(streamId, configNameId - 1, ConfigurationUtil.SEND_NUM_BITS)
		streamWriteUInt16(streamId, numBoughtConfigIds)

		for id, _ in pairs(configIds) do
			streamWriteUInt16(streamId, id - 1)
		end
	end

	streamWriteUIntN(streamId, self.propertyState, 2)
end

function Vehicle:postWriteStream(streamId, connection)
	local paramsXZ = self.highPrecisionPositionSynchronization and g_currentMission.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosCompressionParams
	local paramsY = self.highPrecisionPositionSynchronization and g_currentMission.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosCompressionParams

	for i = 1, #self.components do
		local component = self.components[i]
		local x, y, z = getWorldTranslation(component.node)
		local x_rot, y_rot, z_rot = getWorldRotation(component.node)

		NetworkUtil.writeCompressedWorldPosition(streamId, x, paramsXZ)
		NetworkUtil.writeCompressedWorldPosition(streamId, y, paramsY)
		NetworkUtil.writeCompressedWorldPosition(streamId, z, paramsXZ)
		NetworkUtil.writeCompressedAngle(streamId, x_rot)
		NetworkUtil.writeCompressedAngle(streamId, y_rot)
		NetworkUtil.writeCompressedAngle(streamId, z_rot)
	end

	streamWriteFloat32(streamId, self.serverMass)
	streamWriteUInt16(streamId, self.age)
	streamWriteFloat32(streamId, self.operatingTime)
	streamWriteInt32(streamId, self.price)

	if Vehicle.DEBUG_NETWORK_READ_WRITE then
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

	self:setConnectionSynchronized(connection, true)
end

function Vehicle:readUpdateStream(streamId, timestamp, connection)
	if connection.isServer then
		local hasUpdate = streamReadBool(streamId)

		if hasUpdate then
			self.networkTimeInterpolator:startNewPhaseNetwork()

			local paramsXZ = self.highPrecisionPositionSynchronization and g_currentMission.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosCompressionParams
			local paramsY = self.highPrecisionPositionSynchronization and g_currentMission.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosCompressionParams

			for i = 1, #self.components do
				local component = self.components[i]

				if not component.isStatic then
					local x = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
					local y = NetworkUtil.readCompressedWorldPosition(streamId, paramsY)
					local z = NetworkUtil.readCompressedWorldPosition(streamId, paramsXZ)
					local x_rot = NetworkUtil.readCompressedAngle(streamId)
					local y_rot = NetworkUtil.readCompressedAngle(streamId)
					local z_rot = NetworkUtil.readCompressedAngle(streamId)
					local qx, qy, qz, qw = mathEulerToQuaternion(x_rot, y_rot, z_rot)

					component.networkInterpolators.position:setTargetPosition(x, y, z)
					component.networkInterpolators.quaternion:setTargetQuaternion(qx, qy, qz, qw)
				end
			end

			SpecializationUtil.raiseEvent(self, "onReadPositionUpdateStream", streamId, connection)
		end
	end

	if Vehicle.DEBUG_NETWORK_READ_WRITE_UPDATE then
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

function Vehicle:writeUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer and streamWriteBool(streamId, bitAND(dirtyMask, self.vehicleDirtyFlag) ~= 0) then
		local paramsXZ = self.highPrecisionPositionSynchronization and g_currentMission.vehicleXZPosHighPrecisionCompressionParams or g_currentMission.vehicleXZPosCompressionParams
		local paramsY = self.highPrecisionPositionSynchronization and g_currentMission.vehicleYPosHighPrecisionCompressionParams or g_currentMission.vehicleYPosCompressionParams

		for i = 1, #self.components do
			local component = self.components[i]

			if not component.isStatic then
				local x, y, z = getWorldTranslation(component.node)
				local x_rot, y_rot, z_rot = getWorldRotation(component.node)

				NetworkUtil.writeCompressedWorldPosition(streamId, x, paramsXZ)
				NetworkUtil.writeCompressedWorldPosition(streamId, y, paramsY)
				NetworkUtil.writeCompressedWorldPosition(streamId, z, paramsXZ)
				NetworkUtil.writeCompressedAngle(streamId, x_rot)
				NetworkUtil.writeCompressedAngle(streamId, y_rot)
				NetworkUtil.writeCompressedAngle(streamId, z_rot)
			end
		end

		SpecializationUtil.raiseEvent(self, "onWritePositionUpdateStream", streamId, connection, dirtyMask)
	end

	if Vehicle.DEBUG_NETWORK_READ_WRITE_UPDATE then
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

function Vehicle:updateVehicleSpeed(dt)
	if self.finishedFirstUpdate and not self.components[1].isStatic then
		local speedReal = 0
		local movedDistance = 0
		local movingDirection = 0
		local signedSpeedReal = 0

		if not self.isServer or self.components[1].isKinematic then
			if not self.isServer and self.synchronizePosition then
				local interpPos = self.components[1].networkInterpolators.position
				local dx = 0
				local dy = 0
				local dz = 0

				if self.networkTimeInterpolator:isInterpolating() then
					dx, dy, dz = worldDirectionToLocal(self.components[1].node, interpPos.targetPositionX - interpPos.lastPositionX, interpPos.targetPositionY - interpPos.lastPositionY, interpPos.targetPositionZ - interpPos.lastPositionZ)
				end

				if dz > 0.001 then
					movingDirection = 1
				elseif dz < -0.001 then
					movingDirection = -1
				end

				speedReal = MathUtil.vector3Length(dx, dy, dz) / self.networkTimeInterpolator.interpolationDuration
				signedSpeedReal = speedReal * (dz >= 0 and 1 or -1)
				movedDistance = speedReal * dt
			else
				local x, y, z = getWorldTranslation(self.components[1].node)

				if self.lastPosition == nil then
					self.lastPosition = {
						x,
						y,
						z
					}
				end

				local dx, dy, dz = worldDirectionToLocal(self.components[1].node, x - self.lastPosition[1], y - self.lastPosition[2], z - self.lastPosition[3])
				self.lastPosition[3] = z
				self.lastPosition[2] = y
				self.lastPosition[1] = x

				if dz > 0.001 then
					movingDirection = 1
				elseif dz < -0.001 then
					movingDirection = -1
				end

				movedDistance = MathUtil.vector3Length(dx, dy, dz)
				speedReal = movedDistance / dt
				signedSpeedReal = speedReal * (dz >= 0 and 1 or -1)
			end
		elseif self.components[1].isDynamic then
			local vx, vy, vz = getLocalLinearVelocity(self.components[1].node)
			speedReal = MathUtil.vector3Length(vx, vy, vz) * 0.001
			movedDistance = speedReal * g_physicsDt
			signedSpeedReal = speedReal * (vz >= 0 and 1 or -1)

			if vz > 0.001 then
				movingDirection = 1
			elseif vz < -0.001 then
				movingDirection = -1
			end
		end

		if self.isServer then
			if g_physicsDtNonInterpolated > 0 then
				self.lastSpeedAcceleration = (speedReal * movingDirection - self.lastSpeedReal * self.movingDirection) / g_physicsDtNonInterpolated
			end
		else
			self.lastSpeedAcceleration = (speedReal * movingDirection - self.lastSpeedReal * self.movingDirection) / dt
		end

		if self.isServer then
			self.lastSpeed = self.lastSpeed * 0.5 + speedReal * 0.5
			self.lastSignedSpeed = self.lastSignedSpeed * 0.5 + signedSpeedReal * 0.5
		else
			self.lastSpeed = self.lastSpeed * 0.9 + speedReal * 0.1
			self.lastSignedSpeed = self.lastSignedSpeed * 0.9 + signedSpeedReal * 0.1
		end

		self.lastSpeedReal = speedReal
		self.lastSignedSpeedReal = signedSpeedReal
		self.movingDirection = movingDirection
		self.lastMovedDistance = movedDistance
	end
end

function Vehicle:update(dt)
	self.isActive = self:getIsActive()
	local isActiveForInput = self:getIsActiveForInput()
	local isActiveForInputIgnoreSelection = self:getIsActiveForInput(true)
	local isSelected = self:getIsSelected()
	self.lastDistanceToCamera = calcDistanceFrom(self.rootNode, getCamera())
	self.currentUpdateDistance = self.lastDistanceToCamera / self.lodDistanceCoeff
	self.isActiveForInputIgnoreSelectionIgnoreAI = self:getIsActiveForInput(true, true)
	self.updateLoopIndex = g_updateLoopIndex

	SpecializationUtil.raiseEvent(self, "onPreUpdate", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)

	if not self.isServer and self.synchronizePosition then
		self.networkTimeInterpolator:update(dt)

		local interpolationAlpha = self.networkTimeInterpolator:getAlpha()

		for i, component in pairs(self.components) do
			if not component.isStatic then
				local posX, posY, posZ = component.networkInterpolators.position:getInterpolatedValues(interpolationAlpha)
				local quatX, quatY, quatZ, quatW = component.networkInterpolators.quaternion:getInterpolatedValues(interpolationAlpha)

				self:setWorldPositionQuaternion(posX, posY, posZ, quatX, quatY, quatZ, quatW, i, false)
			end
		end

		if self.networkTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end

	SpecializationUtil.raiseEvent(self, "onUpdateInterpolation", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	self:updateVehicleSpeed(dt)

	if self.actionEventUpdateRequested then
		self:updateActionEvents()
	end

	if Platform.gameplay.automaticVehicleControl then
		if self.actionController ~= nil then
			self.actionController:update(dt)
			self.actionController:updateForAI(dt)
		end
	elseif self.actionController ~= nil then
		self.actionController:updateForAI(dt)
	end

	SpecializationUtil.raiseEvent(self, "onUpdate", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)

	if Vehicle.debuggingActive then
		SpecializationUtil.raiseEvent(self, "onUpdateDebug", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	end

	SpecializationUtil.raiseEvent(self, "onPostUpdate", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)

	if self.vehicleCharacter ~= nil then
		self.vehicleCharacter:setDirty(true)
	end

	if self.finishedFirstUpdate and self.isMassDirty then
		self.isMassDirty = false

		self:updateMass()
	end

	self.finishedFirstUpdate = true

	if self.isServer and not getIsSleeping(self.rootNode) then
		self:raiseActive()
	end

	VehicleDebug.updateDebug(self, dt)
	self:updateMapHotspot()
end

function Vehicle:updateTick(dt)
	local isActiveForInput = self:getIsActiveForInput()
	local isActiveForInputIgnoreSelection = self:getIsActiveForInput(true)
	local isSelected = self:getIsSelected()
	self.wasTooFast = false

	if self.isActive then
		self:updateWaterInfo()
	end

	if self.isServer then
		if self.synchronizePosition then
			local hasOwner = self:getOwner() ~= nil

			for i = 1, #self.components do
				local component = self.components[i]

				if not component.isStatic then
					local x, y, z = getWorldTranslation(component.node)
					local x_rot, y_rot, z_rot = getWorldRotation(component.node)
					local sentTranslation = component.sentTranslation
					local sentRotation = component.sentRotation

					if hasOwner or math.abs(x - sentTranslation[1]) > 0.005 or math.abs(y - sentTranslation[2]) > 0.005 or math.abs(z - sentTranslation[3]) > 0.005 or math.abs(x_rot - sentRotation[1]) > 0.1 or math.abs(y_rot - sentRotation[2]) > 0.1 or math.abs(z_rot - sentRotation[3]) > 0.1 then
						self:raiseDirtyFlags(self.vehicleDirtyFlag)

						sentTranslation[1] = x
						sentTranslation[2] = y
						sentTranslation[3] = z
						sentRotation[1] = x_rot
						sentRotation[2] = y_rot
						sentRotation[3] = z_rot
						self.lastMoveTime = g_currentMission.time
					end
				end
			end
		end

		self.showTailwaterDepthWarning = false

		if not self.isBroken and not g_gui:getIsGuiVisible() and self.thresholdTailwaterDepthWarning < self.tailwaterDepth then
			self.showTailwaterDepthWarning = true

			if self.thresholdTailwaterDepth < self.tailwaterDepth then
				self:setBroken()
			end
		end

		local rootAttacherVehicle = self.rootVehicle

		if rootAttacherVehicle ~= nil and rootAttacherVehicle ~= self then
			rootAttacherVehicle.showTailwaterDepthWarning = rootAttacherVehicle.showTailwaterDepthWarning or self.showTailwaterDepthWarning
		end
	end

	if self:getIsOperating() then
		self:setOperatingTime(self.operatingTime + dt)
	end

	SpecializationUtil.raiseEvent(self, "onUpdateTick", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	SpecializationUtil.raiseEvent(self, "onPostUpdateTick", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
end

function Vehicle:updateEnd(dt)
	local isActiveForInput = self:getIsActiveForInput()
	local isActiveForInputIgnoreSelection = self:getIsActiveForInput(true)
	local isSelected = self:getIsSelected()

	SpecializationUtil.raiseEvent(self, "onUpdateEnd", dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
end

function Vehicle:draw(subDraw)
	if self:getIsSynchronized() then
		local rootVehicle = self.rootVehicle
		local selectedVehicle = self:getSelectedVehicle()

		if not subDraw then
			if self ~= rootVehicle and selectedVehicle ~= rootVehicle then
				rootVehicle:draw(true)
			end

			if selectedVehicle ~= nil and self ~= selectedVehicle and selectedVehicle ~= rootVehicle then
				selectedVehicle:draw(true)
			end
		end

		if selectedVehicle == self or rootVehicle == self then
			local isActiveForInput = self:getIsActiveForInput()
			local isActiveForInputIgnoreSelection = self:getIsActiveForInput(true)

			SpecializationUtil.raiseEvent(self, "onDraw", isActiveForInput, isActiveForInputIgnoreSelection, true)
		end

		VehicleDebug.drawDebug(self)

		if self.showTailwaterDepthWarning then
			g_currentMission:showBlinkingWarning(g_i18n:getText("warning_dontDriveIntoWater"), 2000)
		end
	end
end

function Vehicle:drawUIInfo()
	if self:getIsSynchronized() then
		SpecializationUtil.raiseEvent(self, "onDrawUIInfo")

		if g_showVehicleDistance then
			local dist = calcDistanceFrom(self.rootNode, getCamera())

			if dist <= 350 then
				local x, y, z = getWorldTranslation(self.rootNode)

				Utils.renderTextAtWorldPosition(x, y + 1, z, string.format("%.0f", dist), getCorrectTextSize(0.02), 0)
			end
		end
	end
end

function Vehicle:setLoadingState(loadingState)
	if loadingState == VehicleLoadingUtil.VEHICLE_LOAD_OK or loadingState == VehicleLoadingUtil.VEHICLE_LOAD_ERROR or loadingState == VehicleLoadingUtil.VEHICLE_LOAD_DELAYED or loadingState == VehicleLoadingUtil.VEHICLE_LOAD_NO_SPACE then
		self.loadingState = loadingState
	else
		printCallstack()
		Logging.error("Invalid loading state '%s'!", loadingState)
	end
end

function Vehicle:setLoadingStep(loadingStep)
	if loadingStep == Vehicle.LOAD_STEP_CREATED or loadingStep == Vehicle.LOAD_STEP_PRE_LOAD or loadingStep == Vehicle.LOAD_STEP_AWAIT_I3D or loadingStep == Vehicle.LOAD_STEP_LOAD or loadingStep == Vehicle.LOAD_STEP_POST_LOAD or loadingStep == Vehicle.LOAD_STEP_AWAIT_SUB_I3D or loadingStep == Vehicle.LOAD_STEP_FINISHED or loadingStep == Vehicle.LOAD_STEP_SYNCHRONIZED then
		self.loadingStep = loadingStep
	else
		printCallstack()
		Logging.error("Invalid loading step '%s'!", loadingStep)
	end
end

function Vehicle:addNodeObjectMapping(list)
	for _, v in pairs(self.components) do
		list[v.node] = self
	end
end

function Vehicle:removeNodeObjectMapping(list)
	if self.components ~= nil then
		for _, v in pairs(self.components) do
			list[v.node] = nil
		end
	end
end

function Vehicle:addToPhysics()
	if not self.isAddedToPhysics then
		local lastMotorizedNode = nil

		for _, component in pairs(self.components) do
			addToPhysics(component.node)

			if component.motorized then
				if lastMotorizedNode ~= nil and self.isServer then
					addVehicleLink(lastMotorizedNode, component.node)
				end

				lastMotorizedNode = component.node
			end
		end

		self.isAddedToPhysics = true

		if self.isServer then
			for _, jointDesc in pairs(self.componentJoints) do
				self:createComponentJoint(self.components[jointDesc.componentIndices[1]], self.components[jointDesc.componentIndices[2]], jointDesc)
			end

			addWakeUpReport(self.rootNode, "onVehicleWakeUpCallback", self)
		end

		for _, collisionPair in pairs(self.collisionPairs) do
			setPairCollision(collisionPair.component1.node, collisionPair.component2.node, collisionPair.enabled)
		end

		self:setMassDirty()
	end

	return true
end

function Vehicle:removeFromPhysics()
	for _, component in pairs(self.components) do
		removeFromPhysics(component.node)
	end

	if self.isServer then
		for _, jointDesc in pairs(self.componentJoints) do
			jointDesc.jointIndex = 0
		end

		removeWakeUpReport(self.rootNode)
	end

	self.isAddedToPhysics = false

	return true
end

function Vehicle:setVisibility(state)
	for _, component in pairs(self.components) do
		setVisibility(component.node, state)
	end
end

function Vehicle:setRelativePosition(positionX, offsetY, positionZ, yRot)
	local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, positionX, 300, positionZ)

	self:setAbsolutePosition(positionX, terrainHeight + offsetY, positionZ, 0, yRot, 0)
end

function Vehicle:setAbsolutePosition(positionX, positionY, positionZ, xRot, yRot, zRot, componentPositions)
	local tempRootNode = createTransformGroup("tempRootNode")

	setTranslation(tempRootNode, positionX, positionY, positionZ)
	setRotation(tempRootNode, xRot, yRot, zRot)

	for i, component in pairs(self.components) do
		local x, y, z = localToWorld(tempRootNode, unpack(component.originalTranslation))
		local rx, ry, rz = localRotationToWorld(tempRootNode, unpack(component.originalRotation))

		if componentPositions ~= nil and #componentPositions == #self.components then
			x, y, z = unpack(componentPositions[i][1])
			rx, ry, rz = unpack(componentPositions[i][2])
		end

		self:setWorldPosition(x, y, z, rx, ry, rz, i, true)
	end

	delete(tempRootNode)
	self.networkTimeInterpolator:reset()
end

function Vehicle:getLimitedVehicleYPosition(position)
	if position.posY == nil then
		local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, position.posX, 300, position.posZ)

		return terrainHeight + Utils.getNoNil(position.yOffset, 0)
	end

	return position.posY
end

function Vehicle:setWorldPosition(x, y, z, xRot, yRot, zRot, i, changeInterp)
	local component = self.components[i]

	setWorldTranslation(component.node, x, y, z)
	setWorldRotation(component.node, xRot, yRot, zRot)

	if changeInterp then
		local qx, qy, qz, qw = mathEulerToQuaternion(xRot, yRot, zRot)

		component.networkInterpolators.quaternion:setQuaternion(qx, qy, qz, qw)
		component.networkInterpolators.position:setPosition(x, y, z)
	end
end

function Vehicle:setWorldPositionQuaternion(x, y, z, qx, qy, qz, qw, i, changeInterp)
	local component = self.components[i]

	setWorldTranslation(component.node, x, y, z)
	setWorldQuaternion(component.node, qx, qy, qz, qw)

	if changeInterp then
		component.networkInterpolators.quaternion:setQuaternion(qx, qy, qz, qw)
		component.networkInterpolators.position:setPosition(x, y, z)
	end
end

function Vehicle:getUpdatePriority(skipCount, x, y, z, coeff, connection)
	if self:getOwner() == connection then
		return 50
	end

	local x1, y1, z1 = getWorldTranslation(self.components[1].node)
	local dist = MathUtil.vector3Length(x1 - x, y1 - y, z1 - z)
	local clipDist = getClipDistance(self.components[1].node) * coeff

	return (1 - dist / clipDist) * 0.8 + 0.5 * skipCount * 0.2
end

function Vehicle:getPrice()
	return self.price
end

function Vehicle:getSellPrice()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	return Vehicle.calculateSellPrice(storeItem, self.age, self.operatingTime, self:getPrice(), self:getRepairPrice(), self:getRepaintPrice())
end

function Vehicle.calculateSellPrice(storeItem, age, operatingTime, price, repairPrice, repaintPrice)
	local operatingTimeHours = operatingTime / 3600000
	local maxVehicleAge = storeItem.lifetime
	local ageInYears = age / Environment.PERIODS_IN_YEAR

	StoreItemUtil.loadSpecsFromXML(storeItem)

	local motorizedFactor = 1

	if storeItem.specs.power == nil then
		motorizedFactor = 1.3
	end

	local operatingTimeFactor = 1 - operatingTimeHours^motorizedFactor / maxVehicleAge
	local ageFactor = math.min(-0.1 * math.log(ageInYears) + 0.75, 0.8)

	return math.max(price * operatingTimeFactor * ageFactor - repairPrice - repaintPrice, price * 0.03)
end

function Vehicle:getIsOnField()
	for _, component in pairs(self.components) do
		local wx, wy, wz = localToWorld(component.node, getCenterOfMass(component.node))
		local h = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx, wy, wz)

		if wy < h - 1 then
			break
		end

		local isOnField, _ = FSDensityMapUtil.getFieldDataAtWorldPosition(wx, wy, wz)

		if isOnField then
			return true
		end
	end

	return false
end

function Vehicle:getParentComponent(node)
	while node ~= 0 do
		if self:getIsVehicleNode(node) then
			return node
		end

		node = getParent(node)
	end

	return 0
end

function Vehicle:getLastSpeed(useAttacherVehicleSpeed)
	if useAttacherVehicleSpeed and self.attacherVehicle ~= nil then
		return self.attacherVehicle:getLastSpeed(true)
	end

	return self.lastSpeed * 3600
end

g_soundManager:registerModifierType("SPEED", Vehicle.getLastSpeed)

function Vehicle:getDeactivateOnLeave()
	return true
end

function Vehicle:getIsSynchronized()
	return self.loadingStep == Vehicle.LOAD_STEP_SYNCHRONIZED
end

function Vehicle:getOwner()
	if self.owner ~= nil then
		return self.owner
	end

	return nil
end

function Vehicle:getActiveFarm()
	return self:getOwnerFarmId()
end

function Vehicle:getIsVehicleNode(nodeId)
	return self.vehicleNodes[nodeId] ~= nil
end

function Vehicle:getIsOperating()
	return false
end

function Vehicle:getIsActive()
	if self.isBroken then
		return false
	end

	if self.forceIsActive then
		return true
	end

	return false
end

function Vehicle:getIsActiveForInput(ignoreSelection, activeForAI)
	if not self.allowsInput then
		return false
	end

	if not g_currentMission.isRunning then
		return false
	end

	if (activeForAI == nil or not activeForAI) and self:getIsAIActive() then
		return false
	end

	if not ignoreSelection or ignoreSelection == nil then
		local rootVehicle = self.rootVehicle

		if rootVehicle ~= nil then
			local selectedObject = rootVehicle:getSelectedVehicle()

			if self ~= selectedObject then
				return false
			end
		else
			return false
		end
	end

	local rootAttacherVehicle = self.rootVehicle

	if rootAttacherVehicle ~= self then
		if not rootAttacherVehicle:getIsActiveForInput(true, activeForAI) then
			return false
		end
	elseif self.getIsEntered == nil and self.getAttacherVehicle ~= nil and self:getAttacherVehicle() == nil then
		return false
	end

	return true
end

function Vehicle:getIsActiveForSound()
	print("Warning: Vehicle:getIsActiveForSound() is deprecated")

	return false
end

function Vehicle:getIsLowered(defaultIsLowered)
	return false
end

function Vehicle:updateWaterInfo()
	local x, y, z = getWorldTranslation(self.rootNode)

	g_currentMission.environmentAreaSystem:getWaterYAtWorldPositionAsync(x, y, z, self.onWaterRaycastCallback, self, {
		x,
		y,
		z
	})
end

function Vehicle:onWaterRaycastCallback(waterY, args)
	local x, y, z = unpack(args)
	waterY = waterY or -2000
	self.waterY = waterY
	self.isInWater = y < waterY
	self.isInShallowWater = false

	if self.isInWater then
		local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
		local waterDepth = math.max(0, waterY - terrainHeight)
		self.isInShallowWater = waterDepth < 0.4
	end

	self.tailwaterDepth = math.max(0, waterY - y)
end

function Vehicle:setBroken()
	if self.isServer and not self.isBroken then
		g_server:broadcastEvent(VehicleBrokenEvent.new(self), nil, , self)
	end

	self.isBroken = true

	SpecializationUtil.raiseEvent(self, "onSetBroken")
end

function Vehicle:getVehicleDamage()
	return 0
end

function Vehicle:getRepairPrice()
	return 0
end

function Vehicle:getRepaintPrice()
	return 0
end

function Vehicle:requestActionEventUpdate()
	local vehicle = self.rootVehicle

	if vehicle == self then
		self.actionEventUpdateRequested = true
	else
		vehicle:requestActionEventUpdate()
	end

	vehicle:removeActionEvents()
end

function Vehicle:removeActionEvents()
	g_inputBinding:removeActionEventsByTarget(self)
end

function Vehicle:updateActionEvents()
	local rootVehicle = self.rootVehicle

	rootVehicle:registerActionEvents()
end

function Vehicle:registerActionEvents(excludedVehicle)
	if not g_gui:getIsGuiVisible() and not g_currentMission.isPlayerFrozen and excludedVehicle ~= self then
		self.actionEventUpdateRequested = false
		local isActiveForInput = self:getIsActiveForInput()
		local isActiveForInputIgnoreSelection = self:getIsActiveForInput(true)

		if isActiveForInput then
			g_inputBinding:resetActiveActionBindings()
		end

		g_inputBinding:beginActionEventsModification(Vehicle.INPUT_CONTEXT_NAME)
		SpecializationUtil.raiseEvent(self, "onRegisterActionEvents", isActiveForInput, isActiveForInputIgnoreSelection)
		self:clearActionEventsTable(self.actionEvents)

		if self:getCanToggleSelectable() then
			local numSelectableObjects = 0

			for _, object in ipairs(self.selectableObjects) do
				numSelectableObjects = numSelectableObjects + 1 + #object.subSelections
			end

			if numSelectableObjects > 1 then
				local _, actionEventId = self:addActionEvent(self.actionEvents, InputAction.SWITCH_IMPLEMENT, self, Vehicle.actionEventToggleSelection, false, true, false, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)

				_, actionEventId = self:addActionEvent(self.actionEvents, InputAction.SWITCH_IMPLEMENT_BACK, self, Vehicle.actionEventToggleSelectionReverse, false, true, false, true, nil)

				g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			end
		end

		VehicleDebug.registerActionEvents(self)

		if Platform.gameplay.automaticVehicleControl and self.actionController ~= nil and self:getIsActiveForInput(true) and self == self.rootVehicle then
			self.actionController:registerActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
		end

		g_inputBinding:endActionEventsModification()
	end
end

function Vehicle:clearActionEventsTable(actionEventsTable)
	if actionEventsTable ~= nil then
		for actionEventName, actionEvent in pairs(actionEventsTable) do
			g_inputBinding:removeActionEvent(actionEvent.actionEventId)

			actionEventsTable[actionEventName] = nil
		end
	end
end

function Vehicle:addPoweredActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions, reportAnyDeviceCollision)
	local function newCallback(vehicle, actionName, inputValue, state, isAnalog, isMouse, deviceCategory, binding)
		local isPowered, warning = vehicle:getIsPowered()

		if isPowered then
			callback(vehicle, actionName, inputValue, state, isAnalog, isMouse, deviceCategory, binding)
		elseif inputValue ~= 0 and warning ~= nil then
			g_currentMission:showBlinkingWarning(warning, 2000)
		end
	end

	return self:addActionEvent(actionEventsTable, inputAction, target, newCallback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions, reportAnyDeviceCollision)
end

function Vehicle:addActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName, ignoreCollisions, reportAnyDeviceCollision)
	local state, actionEventId, otherEvents = g_inputBinding:registerActionEvent(inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, true, reportAnyDeviceCollision)

	if state then
		actionEventsTable[inputAction] = {
			actionEventId = actionEventId
		}
		local event = g_inputBinding.events[actionEventId]

		if event ~= nil then
			event.parentEventsTable = actionEventsTable
		end

		if customIconName and customIconName ~= "" then
			g_inputBinding:setActionEventIcon(actionEventId, customIconName)
		end
	end

	if otherEvents ~= nil and (ignoreCollisions == nil or not ignoreCollisions) then
		if self:getIsSelected() then
			local clearedVehicleEvent = false

			for _, otherEvent in ipairs(otherEvents) do
				if otherEvent.parentEventsTable ~= nil then
					g_inputBinding:removeActionEvent(otherEvent.id)

					otherEvent.parentEventsTable[otherEvent.id] = nil
					clearedVehicleEvent = true
				end
			end

			if clearedVehicleEvent then
				return self:addActionEvent(actionEventsTable, inputAction, target, callback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, customIconName)
			end
		else
			g_inputBinding:removeActionEvent(actionEventId)

			for _, otherEvent in ipairs(otherEvents) do
				if otherEvent.targetObject.getIsSelected ~= nil and not otherEvent.targetObject:getIsSelected() and otherEvent.parentEventsTable ~= nil then
					g_inputBinding:removeActionEvent(otherEvent.id)

					otherEvent.parentEventsTable[otherEvent.id] = nil
				end
			end
		end
	end

	return state, actionEventId
end

function Vehicle:removeActionEvent(actionEventsTable, inputAction)
	if actionEventsTable[inputAction] ~= nil then
		g_inputBinding:removeActionEvent(actionEventsTable[inputAction].actionEventId)

		actionEventsTable[inputAction] = nil
	end
end

function Vehicle:updateSelectableObjects()
	self.selectableObjects = {}

	if self == self.rootVehicle then
		self:registerSelectableObjects(self.selectableObjects)
	end
end

function Vehicle:registerSelectableObjects(selectableObjects)
	if self:getCanBeSelected() and not self:getBlockSelection() then
		table.insert(selectableObjects, self.selectionObject)

		self.selectionObject.index = #selectableObjects
	end
end

function Vehicle:addSubselection(subSelection)
	table.insert(self.selectionObject.subSelections, subSelection)

	return #self.selectionObject.subSelections
end

function Vehicle:getCanBeSelected()
	return VehicleDebug.state ~= 0
end

function Vehicle:getBlockSelection()
	return false
end

function Vehicle:getCanToggleSelectable()
	return false
end

function Vehicle:getRootVehicle()
	return self.rootVehicle
end

function Vehicle:findRootVehicle()
	return self
end

function Vehicle:getChildVehicles()
	return self.childVehicles
end

function Vehicle:addChildVehicles(vehicles)
	table.insert(vehicles, self)
end

function Vehicle:updateVehicleChain(secondCall)
	local rootVehicle = self:findRootVehicle()

	if rootVehicle ~= self.rootVehicle then
		self.rootVehicle = rootVehicle

		SpecializationUtil.raiseEvent(self, "onRootVehicleChanged", rootVehicle)
	end

	if rootVehicle ~= self and not secondCall then
		rootVehicle:updateVehicleChain()

		return
	end

	for i = #self.childVehicles, 1, -1 do
		self.childVehicles[i] = nil
	end

	self:addChildVehicles(self.childVehicles)

	if rootVehicle == self then
		for i = 1, #self.childVehicles do
			if self.childVehicles[i] ~= rootVehicle then
				self.childVehicles[i]:updateVehicleChain(true)
			end
		end
	end
end

function Vehicle:unselectVehicle()
	self.selectionObject.isSelected = false

	SpecializationUtil.raiseEvent(self, "onUnselect")
	self:requestActionEventUpdate()
end

function Vehicle:selectVehicle(subSelectionIndex, ignoreActionEventUpdate)
	self.selectionObject.isSelected = true

	SpecializationUtil.raiseEvent(self, "onSelect", subSelectionIndex)

	if ignoreActionEventUpdate == nil or not ignoreActionEventUpdate then
		self:requestActionEventUpdate()
	end
end

function Vehicle:setSelectedVehicle(vehicle, subSelectionIndex, ignoreActionEventUpdate)
	local object = nil

	if vehicle == nil or not vehicle:getCanBeSelected() or self:getBlockSelection() then
		vehicle = nil

		for _, o in ipairs(self.selectableObjects) do
			if o.vehicle:getCanBeSelected() and not o.vehicle:getBlockSelection() then
				vehicle = o.vehicle

				break
			end
		end
	end

	if vehicle ~= nil then
		object = vehicle.selectionObject
	end

	return self:setSelectedObject(object, subSelectionIndex, ignoreActionEventUpdate)
end

function Vehicle:setSelectedObject(object, subSelectionIndex, ignoreActionEventUpdate)
	local currentSelection = self.currentSelection

	if object == nil then
		object = self:getSelectedObject()
	end

	local found = false

	for _, o in ipairs(self.selectableObjects) do
		if o == object then
			found = true
		end
	end

	if found then
		for _, o in ipairs(self.selectableObjects) do
			if o ~= object and o.vehicle:getIsSelected() then
				o.vehicle:unselectVehicle()
			end
		end

		if object ~= currentSelection.object or subSelectionIndex ~= currentSelection.subIndex then
			currentSelection.object = object
			currentSelection.index = object.index

			if subSelectionIndex ~= nil then
				currentSelection.subIndex = subSelectionIndex
			end

			if currentSelection.subIndex > #object.subSelections then
				currentSelection.subIndex = 1
			end

			currentSelection.object.vehicle:selectVehicle(currentSelection.subIndex, ignoreActionEventUpdate)

			return true
		end
	else
		object = self:getSelectedObject()
		found = false

		for _, o in ipairs(self.selectableObjects) do
			if o == object then
				found = true
			end
		end

		if not found then
			currentSelection.object = nil
			currentSelection.index = 1
			currentSelection.subIndex = 1
		end
	end

	return false
end

function Vehicle:getIsSelected()
	return self.selectionObject.isSelected
end

function Vehicle:getSelectedObject()
	local rootVehicle = self.rootVehicle

	if rootVehicle == self then
		return self.currentSelection.object
	end

	return rootVehicle:getSelectedObject()
end

function Vehicle:getSelectedVehicle()
	local selectedObject = self:getSelectedObject()

	if selectedObject ~= nil then
		return selectedObject.vehicle
	end

	return nil
end

function Vehicle:hasInputConflictWithSelection(inputs)
	printCallstack()
	Logging.xmlWarning(self.xmlFile, "Vehicle:hasInputConflictWithSelection() is deprecated!")

	return false
end

function Vehicle:setMassDirty()
	self.isMassDirty = true
end

function Vehicle:updateMass()
	self.serverMass = 0

	for _, component in ipairs(self.components) do
		if component.defaultMass == nil then
			if component.isDynamic then
				component.defaultMass = getMass(component.node)
			else
				component.defaultMass = 1
			end

			component.mass = component.defaultMass
		end

		local mass = self:getAdditionalComponentMass(component)
		component.mass = component.defaultMass + mass
		self.serverMass = self.serverMass + component.mass
	end

	local realTotalMass = 0

	for _, component in ipairs(self.components) do
		realTotalMass = realTotalMass + self:getComponentMass(component)
	end

	self.precalculatedMass = realTotalMass - self.serverMass

	for _, component in ipairs(self.components) do
		local maxFactor = self.serverMass / (self.maxComponentMass - self.precalculatedMass)

		if maxFactor > 1 then
			component.mass = component.mass / maxFactor
		end

		if self.isServer and component.isDynamic and math.abs(component.lastMass - component.mass) > 0.02 then
			setMass(component.node, component.mass)

			component.lastMass = component.mass
		end
	end

	self.serverMass = math.min(self.serverMass, self.maxComponentMass - self.precalculatedMass)
end

function Vehicle:getMaxComponentMassReached()
	return self.serverMass >= self.maxComponentMass - self.precalculatedMass
end

function Vehicle:getAvailableComponentMass()
	return math.max(self.maxComponentMass - self.precalculatedMass - self.serverMass, 0)
end

function Vehicle:getAdditionalComponentMass(component)
	return 0
end

function Vehicle:getTotalMass(onlyGivenVehicle)
	local mass = 0

	for _, component in ipairs(self.components) do
		mass = mass + self:getComponentMass(component)
	end

	return mass
end

function Vehicle:getComponentMass(component)
	if component ~= nil then
		return component.mass
	end

	return 0
end

function Vehicle:getDefaultMass()
	local mass = 0

	for _, component in ipairs(self.components) do
		mass = mass + (component.defaultMass or 0)
	end

	return mass
end

function Vehicle:getOverallCenterOfMass()
	local cx = 0
	local cy = 0
	local cz = 0
	local totalMass = self:getTotalMass(true)
	local numComponents = #self.components

	for i = 1, numComponents do
		local component = self.components[i]
		local ccx, ccy, ccz = localToWorld(component.node, getCenterOfMass(component.node))
		local percentage = self:getComponentMass(component) / totalMass
		cz = cz + ccz * percentage
		cy = cy + ccy * percentage
		cx = cx + ccx * percentage
	end

	return cx, cy, cz
end

function Vehicle:getVehicleWorldXRot()
	local _, y, _ = localDirectionToWorld(self.components[1].node, 0, 0, 1)
	local slopeAngle = math.pi * 0.5 - math.atan(1 / y)

	if slopeAngle > math.pi * 0.5 then
		slopeAngle = slopeAngle - math.pi
	end

	return slopeAngle
end

function Vehicle:getVehicleWorldDirection()
	return localDirectionToWorld(self.components[1].node, 0, 0, 1)
end

function Vehicle:getFillLevelInformation(display)
end

function Vehicle:activate()
	SpecializationUtil.raiseEvent(self, "onActivate")
end

function Vehicle:deactivate()
	SpecializationUtil.raiseEvent(self, "onDeactivate")
end

function Vehicle:setComponentJointFrame(jointDesc, anchorActor)
	if anchorActor == 0 then
		local localPoses = jointDesc.jointLocalPoses[1]
		localPoses.trans[1], localPoses.trans[2], localPoses.trans[3] = localToLocal(jointDesc.jointNode, self.components[jointDesc.componentIndices[1]].node, 0, 0, 0)
		localPoses.rot[1], localPoses.rot[2], localPoses.rot[3] = localRotationToLocal(jointDesc.jointNode, self.components[jointDesc.componentIndices[1]].node, 0, 0, 0)
	else
		local localPoses = jointDesc.jointLocalPoses[2]
		localPoses.trans[1], localPoses.trans[2], localPoses.trans[3] = localToLocal(jointDesc.jointNodeActor1, self.components[jointDesc.componentIndices[2]].node, 0, 0, 0)
		localPoses.rot[1], localPoses.rot[2], localPoses.rot[3] = localRotationToLocal(jointDesc.jointNodeActor1, self.components[jointDesc.componentIndices[2]].node, 0, 0, 0)
	end

	local jointNode = jointDesc.jointNode

	if anchorActor == 1 then
		jointNode = jointDesc.jointNodeActor1
	end

	if jointDesc.jointIndex ~= 0 then
		setJointFrame(jointDesc.jointIndex, anchorActor, jointNode)
	end
end

function Vehicle:setComponentJointRotLimit(componentJoint, axis, minLimit, maxLimit)
	if self.isServer then
		componentJoint.rotLimit[axis] = maxLimit
		componentJoint.rotMinLimit[axis] = minLimit

		if componentJoint.jointIndex ~= 0 then
			if minLimit <= maxLimit then
				setJointRotationLimit(componentJoint.jointIndex, axis - 1, true, minLimit, maxLimit)
			else
				setJointRotationLimit(componentJoint.jointIndex, axis - 1, false, 0, 0)
			end
		end
	end
end

function Vehicle:setComponentJointTransLimit(componentJoint, axis, minLimit, maxLimit)
	if self.isServer then
		componentJoint.transLimit[axis] = maxLimit
		componentJoint.transMinLimit[axis] = minLimit

		if componentJoint.jointIndex ~= 0 then
			if minLimit <= maxLimit then
				setJointTranslationLimit(componentJoint.jointIndex, axis - 1, true, minLimit, maxLimit)
			else
				setJointTranslationLimit(componentJoint.jointIndex, axis - 1, false, 0, 0)
			end
		end
	end
end

function Vehicle:loadComponentFromXML(component, xmlFile, key, rootPosition, i)
	if not self.isServer and getRigidBodyType(component.node) == RigidBodyType.DYNAMIC then
		setRigidBodyType(component.node, RigidBodyType.KINEMATIC)
	end

	link(getRootNode(), component.node)

	if i == 1 then
		rootPosition[1], rootPosition[2], rootPosition[3] = getTranslation(component.node)

		if rootPosition[2] ~= 0 then
			Logging.xmlWarning(self.xmlFile, "Y-Translation of component 1 (node 0>) has to be 0. Current value is: %.5f", rootPosition[2])
		end
	end

	if getRigidBodyType(component.node) == RigidBodyType.STATIC then
		component.isStatic = true
	elseif getRigidBodyType(component.node) == RigidBodyType.KINEMATIC then
		component.isKinematic = true
	elseif getRigidBodyType(component.node) == RigidBodyType.DYNAMIC then
		component.isDynamic = true
	end

	if not CollisionFlag.getHasFlagSet(component.node, CollisionFlag.VEHICLE) then
		Logging.xmlWarning(self.xmlFile, "Missing collision mask bit '%d'. Please add this bit to component node '%s'", CollisionFlag.getBit(CollisionFlag.VEHICLE), getName(component.node))
	end

	if not CollisionFlag.getHasFlagSet(component.node, CollisionFlag.TRIGGER_VEHICLE) then
		Logging.xmlWarning(self.xmlFile, "Missing collision mask bit '%d'. Please add this bit to component node '%s'", CollisionFlag.getBit(CollisionFlag.TRIGGER_VEHICLE), getName(component.node))
	end

	if not getVisibility(component.node) then
		Logging.xmlDevWarning(self.xmlFile, "Found hidden component '%s' in i3d file. Components are not allowed to be hidden!", getName(component.node))
		setVisibility(component.node, true)
	end

	translate(component.node, -rootPosition[1], -rootPosition[2], -rootPosition[3])

	local x, y, z = getTranslation(component.node)
	local rx, ry, rz = getRotation(component.node)
	component.originalTranslation = {
		x,
		y,
		z
	}
	component.originalRotation = {
		rx,
		ry,
		rz
	}
	component.sentTranslation = {
		x,
		y,
		z
	}
	component.sentRotation = {
		rx,
		ry,
		rz
	}
	component.defaultMass = nil
	component.mass = nil
	local mass = xmlFile:getValue(key .. "#mass")

	if mass ~= nil then
		if mass < 10 then
			Logging.xmlDevWarning(self.xmlFile, "Mass is lower than 10kg for '%s'. Mass unit is kilogramms. Is this correct?", key)
		end

		if component.isDynamic then
			setMass(component.node, mass / 1000)
		end

		component.defaultMass = mass / 1000
		component.mass = component.defaultMass
		component.lastMass = component.mass
	else
		Logging.xmlWarning(self.xmlFile, "Missing 'mass' for '%s'. Using default mass 500kg instead!", key)

		component.defaultMass = 0.5
		component.mass = 0.5
		component.lastMass = component.mass
	end

	local comX, comY, comZ = xmlFile:getValue(key .. "#centerOfMass")

	if comX ~= nil then
		setCenterOfMass(component.node, comX, comY, comZ)
	end

	local count = xmlFile:getValue(key .. "#solverIterationCount")

	if count ~= nil then
		setSolverIterationCount(component.node, count)

		component.solverIterationCount = count
	end

	component.motorized = xmlFile:getValue(key .. "#motorized")
	self.vehicleNodes[component.node] = {
		component = component
	}
	local clipDistance = getClipDistance(component.node)

	if clipDistance >= 1000000 and getVisibility(component.node) then
		local defaultClipdistance = 300

		Logging.xmlWarning(self.xmlFile, "No clipdistance is set to component node '%s' (%s>). Set default clipdistance '%d'", getName(component.node), i - 1, defaultClipdistance)
		setClipDistance(component.node, defaultClipdistance)
	end

	component.collideWithAttachables = xmlFile:getValue(key .. "#collideWithAttachables", false)

	if getRigidBodyType(component.node) ~= RigidBodyType.NONE then
		if getLinearDamping(component.node) > 0.01 then
			Logging.xmlDevWarning(self.xmlFile, "Non-zero linear damping (%.4f) for component node '%s' (%s>). Is this correct?", getLinearDamping(component.node), getName(component.node), i - 1)
		elseif getAngularDamping(component.node) > 0.05 then
			Logging.xmlDevWarning(self.xmlFile, "Large angular damping (%.4f) for component node '%s' (%s>). Is this correct?", getAngularDamping(component.node), getName(component.node), i - 1)
		elseif getAngularDamping(component.node) < 0.0001 then
			Logging.xmlDevWarning(self.xmlFile, "Zero damping for component node '%s' (%s>). Is this correct?", getName(component.node), i - 1)
		end
	end

	local name = getName(component.node)

	if not name:endsWith("component" .. i) then
		Logging.xmlDevWarning(self.xmlFile, "Name of component '%d' ('%s') does not correpond with the component naming convention! (vehicleName_componentName_component%d)", i, name, i)
	end

	return true
end

function Vehicle:loadComponentJointFromXML(jointDesc, xmlFile, key, componentJointI, jointNode, index1, index2)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#indexActor1", key .. "#nodeActor1")

	jointDesc.componentIndices = {
		index1,
		index2
	}
	jointDesc.jointNode = jointNode
	jointDesc.jointNodeActor1 = xmlFile:getValue(key .. "#nodeActor1", jointNode, self.components, self.i3dMappings)

	if self.isServer then
		if self.components[index1] == nil or self.components[index2] == nil then
			Logging.xmlWarning(self.xmlFile, "Invalid component indices (component1: %d, component2: %d) for component joint %d. Indices start with 1!", index1, index2, componentJointI)

			return false
		end

		local x, y, z = xmlFile:getValue(key .. "#rotLimit")
		local rotLimits = {
			math.rad(Utils.getNoNil(x, 0)),
			math.rad(Utils.getNoNil(y, 0)),
			math.rad(Utils.getNoNil(z, 0))
		}
		x, y, z = xmlFile:getValue(key .. "#transLimit")
		local transLimits = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		jointDesc.rotLimit = rotLimits
		jointDesc.transLimit = transLimits
		x, y, z = xmlFile:getValue(key .. "#rotMinLimit")
		local rotMinLimits = {
			Utils.getNoNilRad(x, nil),
			Utils.getNoNilRad(y, nil),
			Utils.getNoNilRad(z, nil)
		}
		x, y, z = xmlFile:getValue(key .. "#transMinLimit")
		local transMinLimits = {
			x,
			y,
			z
		}

		for i = 1, 3 do
			if rotMinLimits[i] == nil then
				if rotLimits[i] >= 0 then
					rotMinLimits[i] = -rotLimits[i]
				else
					rotMinLimits[i] = rotLimits[i] + 1
				end
			end

			if transMinLimits[i] == nil then
				if transLimits[i] >= 0 then
					transMinLimits[i] = -transLimits[i]
				else
					transMinLimits[i] = transLimits[i] + 1
				end
			end
		end

		jointDesc.jointLocalPoses = {}
		local trans = {
			localToLocal(jointDesc.jointNode, self.components[index1].node, 0, 0, 0)
		}
		local rot = {
			localRotationToLocal(jointDesc.jointNode, self.components[index1].node, 0, 0, 0)
		}
		jointDesc.jointLocalPoses[1] = {
			trans = trans,
			rot = rot
		}
		trans = {
			localToLocal(jointDesc.jointNodeActor1, self.components[index2].node, 0, 0, 0)
		}
		rot = {
			localRotationToLocal(jointDesc.jointNodeActor1, self.components[index2].node, 0, 0, 0)
		}
		jointDesc.jointLocalPoses[2] = {
			trans = trans,
			rot = rot
		}
		jointDesc.rotMinLimit = rotMinLimits
		jointDesc.transMinLimit = transMinLimits
		x, y, z = xmlFile:getValue(key .. "#rotLimitSpring")
		local rotLimitSpring = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		x, y, z = xmlFile:getValue(key .. "#rotLimitDamping")
		local rotLimitDamping = {
			Utils.getNoNil(x, 1),
			Utils.getNoNil(y, 1),
			Utils.getNoNil(z, 1)
		}
		jointDesc.rotLimitSpring = rotLimitSpring
		jointDesc.rotLimitDamping = rotLimitDamping
		x, y, z = xmlFile:getValue(key .. "#rotLimitForceLimit")
		local rotLimitForceLimit = {
			Utils.getNoNil(x, -1),
			Utils.getNoNil(y, -1),
			Utils.getNoNil(z, -1)
		}
		x, y, z = xmlFile:getValue(key .. "#transLimitForceLimit")
		local transLimitForceLimit = {
			Utils.getNoNil(x, -1),
			Utils.getNoNil(y, -1),
			Utils.getNoNil(z, -1)
		}
		jointDesc.rotLimitForceLimit = rotLimitForceLimit
		jointDesc.transLimitForceLimit = transLimitForceLimit
		x, y, z = xmlFile:getValue(key .. "#transLimitSpring")
		local transLimitSpring = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		x, y, z = xmlFile:getValue(key .. "#transLimitDamping")
		local transLimitDamping = {
			Utils.getNoNil(x, 1),
			Utils.getNoNil(y, 1),
			Utils.getNoNil(z, 1)
		}
		jointDesc.transLimitSpring = transLimitSpring
		jointDesc.transLimitDamping = transLimitDamping
		jointDesc.zRotationXOffset = 0
		local zRotationNode = xmlFile:getValue(key .. "#zRotationNode", nil, self.components, self.i3dMappings)

		if zRotationNode ~= nil then
			local _ = nil
			jointDesc.zRotationXOffset, _, _ = localToLocal(zRotationNode, jointNode, 0, 0, 0)
		end

		jointDesc.isBreakable = xmlFile:getValue(key .. "#breakable", false)

		if jointDesc.isBreakable then
			jointDesc.breakForce = xmlFile:getValue(key .. "#breakForce", 10)
			jointDesc.breakTorque = xmlFile:getValue(key .. "#breakTorque", 10)
		end

		jointDesc.enableCollision = xmlFile:getValue(key .. "#enableCollision", false)
		x, y, z = xmlFile:getValue(key .. "#maxRotDriveForce")
		local maxRotDriveForce = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		x, y, z = xmlFile:getValue(key .. "#rotDriveVelocity")
		local rotDriveVelocity = {
			Utils.getNoNilRad(x, nil),
			Utils.getNoNilRad(y, nil),
			Utils.getNoNilRad(z, nil)
		}
		x, y, z = xmlFile:getValue(key .. "#rotDriveRotation")
		local rotDriveRotation = {
			Utils.getNoNilRad(x, nil),
			Utils.getNoNilRad(y, nil),
			Utils.getNoNilRad(z, nil)
		}
		x, y, z = xmlFile:getValue(key .. "#rotDriveSpring")
		local rotDriveSpring = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		x, y, z = xmlFile:getValue(key .. "#rotDriveDamping")
		local rotDriveDamping = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		jointDesc.rotDriveVelocity = rotDriveVelocity
		jointDesc.rotDriveRotation = rotDriveRotation
		jointDesc.rotDriveSpring = rotDriveSpring
		jointDesc.rotDriveDamping = rotDriveDamping
		jointDesc.maxRotDriveForce = maxRotDriveForce
		x, y, z = xmlFile:getValue(key .. "#maxTransDriveForce")
		local maxTransDriveForce = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		x, y, z = xmlFile:getValue(key .. "#transDriveVelocity")
		local transDriveVelocity = {
			x,
			y,
			z
		}
		x, y, z = xmlFile:getValue(key .. "#transDrivePosition")
		local transDrivePosition = {
			x,
			y,
			z
		}
		x, y, z = xmlFile:getValue(key .. "#transDriveSpring")
		local transDriveSpring = {
			Utils.getNoNil(x, 0),
			Utils.getNoNil(y, 0),
			Utils.getNoNil(z, 0)
		}
		x, y, z = xmlFile:getValue(key .. "#transDriveDamping")
		local transDriveDamping = {
			Utils.getNoNil(x, 1),
			Utils.getNoNil(y, 1),
			Utils.getNoNil(z, 1)
		}
		jointDesc.transDriveVelocity = transDriveVelocity
		jointDesc.transDrivePosition = transDrivePosition
		jointDesc.transDriveSpring = transDriveSpring
		jointDesc.transDriveDamping = transDriveDamping
		jointDesc.maxTransDriveForce = maxTransDriveForce
		jointDesc.initComponentPosition = xmlFile:getValue(key .. "#initComponentPosition", true)
		jointDesc.jointIndex = 0
	end

	return true
end

function Vehicle:createComponentJoint(component1, component2, jointDesc)
	if component1 == nil or component2 == nil or jointDesc == nil then
		Logging.xmlWarning(self.xmlFile, "Could not create component joint. No component1, component2 or jointDesc given!")

		return false
	end

	local constr = JointConstructor.new()

	constr:setActors(component1.node, component2.node)

	local localPoses1 = jointDesc.jointLocalPoses[1]
	local localPoses2 = jointDesc.jointLocalPoses[2]

	constr:setJointLocalPositions(localPoses1.trans[1], localPoses1.trans[2], localPoses1.trans[3], localPoses2.trans[1], localPoses2.trans[2], localPoses2.trans[3])
	constr:setJointLocalRotations(localPoses1.rot[1], localPoses1.rot[2], localPoses1.rot[3], localPoses2.rot[1], localPoses2.rot[2], localPoses2.rot[3])
	constr:setRotationLimitSpring(jointDesc.rotLimitSpring[1], jointDesc.rotLimitDamping[1], jointDesc.rotLimitSpring[2], jointDesc.rotLimitDamping[2], jointDesc.rotLimitSpring[3], jointDesc.rotLimitDamping[3])
	constr:setTranslationLimitSpring(jointDesc.transLimitSpring[1], jointDesc.transLimitDamping[1], jointDesc.transLimitSpring[2], jointDesc.transLimitDamping[2], jointDesc.transLimitSpring[3], jointDesc.transLimitDamping[3])
	constr:setZRotationXOffset(jointDesc.zRotationXOffset)

	for i = 1, 3 do
		if jointDesc.rotMinLimit[i] <= jointDesc.rotLimit[i] then
			constr:setRotationLimit(i - 1, jointDesc.rotMinLimit[i], jointDesc.rotLimit[i])
		end

		if jointDesc.transMinLimit[i] <= jointDesc.transLimit[i] then
			constr:setTranslationLimit(i - 1, true, jointDesc.transMinLimit[i], jointDesc.transLimit[i])
		else
			constr:setTranslationLimit(i - 1, false, 0, 0)
		end
	end

	constr:setRotationLimitForceLimit(jointDesc.rotLimitForceLimit[1], jointDesc.rotLimitForceLimit[2], jointDesc.rotLimitForceLimit[3])
	constr:setTranslationLimitForceLimit(jointDesc.transLimitForceLimit[1], jointDesc.transLimitForceLimit[2], jointDesc.transLimitForceLimit[3])

	if jointDesc.isBreakable then
		constr:setBreakable(jointDesc.breakForce, jointDesc.breakTorque)
	end

	constr:setEnableCollision(jointDesc.enableCollision)

	for i = 1, 3 do
		if jointDesc.maxRotDriveForce[i] > 0.0001 and (jointDesc.rotDriveVelocity[i] ~= nil or jointDesc.rotDriveRotation[i] ~= nil) then
			local pos = Utils.getNoNil(jointDesc.rotDriveRotation[i], 0)
			local vel = Utils.getNoNil(jointDesc.rotDriveVelocity[i], 0)

			constr:setAngularDrive(i - 1, jointDesc.rotDriveRotation[i] ~= nil, jointDesc.rotDriveVelocity[i] ~= nil, jointDesc.rotDriveSpring[i], jointDesc.rotDriveDamping[i], jointDesc.maxRotDriveForce[i], pos, vel)
		end

		if jointDesc.maxTransDriveForce[i] > 0.0001 and (jointDesc.transDriveVelocity[i] ~= nil or jointDesc.transDrivePosition[i] ~= nil) then
			local pos = Utils.getNoNil(jointDesc.transDrivePosition[i], 0)
			local vel = Utils.getNoNil(jointDesc.transDriveVelocity[i], 0)

			constr:setLinearDrive(i - 1, jointDesc.transDrivePosition[i] ~= nil, jointDesc.transDriveVelocity[i] ~= nil, jointDesc.transDriveSpring[i], jointDesc.transDriveDamping[i], jointDesc.maxTransDriveForce[i], pos, vel)
		end
	end

	jointDesc.jointIndex = constr:finalize()

	return true
end

function Vehicle.prefixSchemaOverlayName(baseName, prefix)
	local name = baseName

	if name ~= "" and not VehicleSchemaOverlayData.SCHEMA_OVERLAY[baseName] then
		name = prefix .. baseName
	end

	return name
end

function Vehicle:loadSchemaOverlay(xmlFile)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#file")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#width")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#height")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#invisibleBorderRight", "vehicle.base.schemaOverlay#invisibleBorderRight")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#invisibleBorderLeft", "vehicle.base.schemaOverlay#invisibleBorderLeft")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#attacherJointPosition", "vehicle.base.schemaOverlay#attacherJointPosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#basePosition", "vehicle.base.schemaOverlay#basePosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#fileSelected")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#fileTurnedOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.schemaOverlay#fileSelectedTurnedOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.schemaOverlay.default#name", "vehicle.base.schemaOverlay#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.schemaOverlay.turnedOn#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.schemaOverlay.selected#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.base.schemaOverlay.turnedOnSelected#name")

	if xmlFile:hasProperty("vehicle.base.schemaOverlay") then
		XMLUtil.checkDeprecatedXMLElements(xmlFile, "vehicle.schemaOverlay.attacherJoint", "vehicle.attacherJoints.attacherJoint.schema")

		local x, y = xmlFile:getValue("vehicle.base.schemaOverlay#attacherJointPosition")
		local baseX, baseY = xmlFile:getValue("vehicle.base.schemaOverlay#basePosition")

		if baseX == nil then
			baseX = x
		end

		if baseY == nil then
			baseY = y
		end

		local schemaName = xmlFile:getValue("vehicle.base.schemaOverlay#name", "")
		local modPrefix = self.customEnvironment or ""
		schemaName = Vehicle.prefixSchemaOverlayName(schemaName, modPrefix)
		self.schemaOverlay = VehicleSchemaOverlayData.new(baseX, baseY, schemaName, xmlFile:getValue("vehicle.base.schemaOverlay#invisibleBorderRight"), xmlFile:getValue("vehicle.base.schemaOverlay#invisibleBorderLeft"))
	end
end

function Vehicle:getAdditionalSchemaText()
	return nil
end

function Vehicle:dayChanged()
end

function Vehicle:periodChanged()
	self.age = self.age + 1
end

function Vehicle:raiseStateChange(state, ...)
	SpecializationUtil.raiseEvent(self, "onStateChange", state, ...)
end

function Vehicle:doCheckSpeedLimit()
	return false
end

function Vehicle:getWorkLoad()
	return 0, 0
end

function Vehicle:interact()
end

function Vehicle:getInteractionHelp()
	return ""
end

function Vehicle:getDistanceToNode(node)
	self.interactionFlag = Vehicle.INTERACTION_FLAG_NONE

	return math.huge
end

function Vehicle:getIsAIActive()
	if self.getAttacherVehicle ~= nil then
		local attacherVehicle = self:getAttacherVehicle()

		if attacherVehicle ~= nil then
			return attacherVehicle:getIsAIActive()
		end
	end

	return false
end

function Vehicle:getIsPowered()
	return true
end

function Vehicle:addVehicleToAIImplementList(list)
end

function Vehicle:setOperatingTime(operatingTime, isLoading)
	if not isLoading and self.propertyState == Vehicle.PROPERTY_STATE_LEASED and g_currentMission ~= nil and g_currentMission.economyManager ~= nil and math.floor(self.operatingTime / 3600000) < math.floor(operatingTime / 3600000) then
		g_currentMission.economyManager:vehicleOperatingHourChanged(self)
	end

	self.operatingTime = math.max(Utils.getNoNil(operatingTime, 0), 0)
end

function Vehicle:getOperatingTime()
	return self.operatingTime
end

function Vehicle:doCollisionMaskCheck(targetCollisionMask, path, node, str)
	local ignoreCheck = false

	if path ~= nil then
		ignoreCheck = self.xmlFile:getValue(path, false)
	end

	if not ignoreCheck then
		local hasMask = false

		if node == nil then
			for _, component in ipairs(self.components) do
				hasMask = hasMask or bitAND(getCollisionMask(component.node), targetCollisionMask) == targetCollisionMask
			end
		else
			hasMask = hasMask or bitAND(getCollisionMask(node), targetCollisionMask) == targetCollisionMask
		end

		if not hasMask then
			printCallstack()
			Logging.xmlWarning(self.xmlFile, "%s has wrong collision mask! Following bit(s) need to be set '%s' or use '%s'", str or self.typeName, MathUtil.numberToSetBitsStr(targetCollisionMask), path)

			return false
		end
	end

	return true
end

function Vehicle:getIsReadyForAutomatedTrainTravel()
	return true
end

function Vehicle:getIsAutomaticShiftingAllowed()
	return true
end

function Vehicle:getSpeedLimit(onlyIfWorking)
	local limit = math.huge
	local doCheckSpeedLimit = self:doCheckSpeedLimit()

	if onlyIfWorking == nil or onlyIfWorking and doCheckSpeedLimit then
		limit = self:getRawSpeedLimit()
		local damage = self:getVehicleDamage()

		if damage > 0 then
			limit = limit * (1 - damage * Vehicle.DAMAGED_SPEEDLIMIT_REDUCTION)
		end
	end

	local attachedImplements = nil

	if self.getAttachedImplements ~= nil then
		attachedImplements = self:getAttachedImplements()
	end

	if attachedImplements ~= nil then
		for _, implement in pairs(attachedImplements) do
			if implement.object ~= nil then
				local speed, implementDoCheckSpeedLimit = implement.object:getSpeedLimit(onlyIfWorking)

				if onlyIfWorking == nil or onlyIfWorking and implementDoCheckSpeedLimit then
					limit = math.min(limit, speed)
				end

				doCheckSpeedLimit = doCheckSpeedLimit or implementDoCheckSpeedLimit
			end
		end
	end

	return limit, doCheckSpeedLimit
end

function Vehicle:getRawSpeedLimit()
	return self.speedLimit
end

function Vehicle:onVehicleWakeUpCallback(id)
	self:raiseActive()
end

function Vehicle:getCanByMounted()
	return entityExists(self.components[1].node)
end

function Vehicle:getDailyUpkeep()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	return Vehicle.calculateDailyUpkeep(storeItem, self.age, self.operatingTime, self.configurations)
end

function Vehicle.calculateDailyUpkeep(storeItem, age, operatingTime, configurations)
	local multiplier = 1

	if storeItem.lifetime ~= nil and storeItem.lifetime ~= 0 then
		local ageMultiplier = 0.3 * math.min(age / storeItem.lifetime, 1)
		operatingTime = operatingTime / 3600000
		local operatingTimeMultiplier = 0.7 * math.min(operatingTime / (storeItem.lifetime * EconomyManager.LIFETIME_OPERATINGTIME_RATIO), 1)
		multiplier = 1 + EconomyManager.MAX_DAILYUPKEEP_MULTIPLIER * (ageMultiplier + operatingTimeMultiplier)
	end

	return StoreItemUtil.getDailyUpkeep(storeItem, configurations) * multiplier
end

function Vehicle:getName()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if storeItem ~= nil and storeItem.configurations ~= nil then
		for configName, _ in pairs(storeItem.configurations) do
			local configId = self.configurations[configName]
			local config = storeItem.configurations[configName][configId]

			if config.vehicleName ~= nil and config.vehicleName ~= "" then
				return config.vehicleName
			end
		end
	end

	return storeItem.name
end

function Vehicle:getFullName()
	local name = self:getName()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if storeItem ~= nil then
		local brand = g_brandManager:getBrandByIndex(self:getBrand())

		if brand ~= nil then
			name = brand.title .. " " .. name
		end
	end

	return name
end

function Vehicle:getBrand()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if storeItem ~= nil and storeItem.configurations ~= nil then
		for configName, _ in pairs(storeItem.configurations) do
			local configId = self.configurations[configName]
			local config = storeItem.configurations[configName][configId]

			if config.vehicleBrand ~= nil then
				return config.vehicleBrand
			end
		end
	end

	return storeItem.brandIndex
end

function Vehicle:getImageFilename()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)

	if storeItem ~= nil and storeItem.configurations ~= nil then
		for configName, _ in pairs(storeItem.configurations) do
			local configId = self.configurations[configName]
			local config = storeItem.configurations[configName][configId]

			if config == nil then
				Logging.xmlWarning(self.xmlFile, "Vehicle has an invalid configuration value %s for %s", configId, configName)
			elseif config.vehicleIcon ~= nil and config.vehicleIcon ~= "" then
				return config.vehicleIcon
			end
		end
	end

	return storeItem.imageFilename
end

function Vehicle:getCanBePickedUp(byPlayer)
	return self.supportsPickUp and g_currentMission.accessHandler:canPlayerAccess(self, byPlayer)
end

function Vehicle:getCanBeReset()
	return self.canBeReset
end

function Vehicle:getIsInUse(connection)
	return false
end

function Vehicle:getPropertyState()
	return self.propertyState
end

function Vehicle:getAreControlledActionsAvailable()
	if self:getIsAIActive() then
		return false
	end

	if self.actionController ~= nil then
		return self.actionController:getAreControlledActionsAvailable()
	end

	return false
end

function Vehicle:getAreControlledActionsAllowed()
	return not self:getIsAIActive(), ""
end

function Vehicle:playControlledActions()
	if self.actionController ~= nil then
		self.actionController:playControlledActions()
	end
end

function Vehicle:getActionControllerDirection()
	if self.actionController ~= nil then
		return self.actionController:getActionControllerDirection()
	end

	return 1
end

function Vehicle:createMapHotspot()
	local mapHotspot = VehicleHotspot.new()

	mapHotspot:setVehicle(self)
	mapHotspot:setVehicleType(self.mapHotspotType)
	mapHotspot:setHasRotation(self.mapHotspotHasDirection)
	mapHotspot:setOwnerFarmId(self:getOwnerFarmId())

	self.mapHotspot = mapHotspot

	g_currentMission:addMapHotspot(mapHotspot)
end

function Vehicle:deleteMapHotspot()
	if self.mapHotspot ~= nil then
		g_currentMission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()

		self.mapHotspot = nil
	end
end

function Vehicle:getMapHotspot()
	return self.mapHotspot
end

function Vehicle:updateMapHotspot()
	if self.mapHotspot ~= nil then
		self.mapHotspot:setVisible(self:getIsMapHotspotVisible())
	end
end

function Vehicle:getIsMapHotspotVisible()
	return true
end

function Vehicle:showInfo(box)
end

function Vehicle:loadObjectChangeValuesFromXML(xmlFile, key, node, object)
end

function Vehicle:setObjectChangeValues(object, isActive)
end

function Vehicle:wakeUp()
	I3DUtil.wakeUpObject(self.components[1].node)
end

function Vehicle:setOwnerFarmId(farmId, noEventSend)
	Vehicle:superClass().setOwnerFarmId(self, farmId, noEventSend)

	if self.mapHotspot ~= nil then
		self.mapHotspot:setOwnerFarmId(farmId)
	end
end

function Vehicle:actionEventToggleSelection(actionName, inputValue, callbackState, isAnalog)
	local currentSelection = self.currentSelection
	local currentObject = currentSelection.object
	local currentObjectIndex = currentSelection.index
	local currentSubObjectIndex = currentSelection.subIndex
	local numSubSelections = 0

	if currentObject ~= nil then
		numSubSelections = #currentObject.subSelections
	end

	local newSelectedSubObjectIndex = currentSubObjectIndex + 1
	local newSelectedObjectIndex = currentObjectIndex
	local newSelectedObject = currentObject

	if numSubSelections < newSelectedSubObjectIndex then
		newSelectedSubObjectIndex = 1
		newSelectedObjectIndex = currentObjectIndex + 1

		if newSelectedObjectIndex > #self.selectableObjects then
			newSelectedObjectIndex = 1
		end

		newSelectedObject = self.selectableObjects[newSelectedObjectIndex]
	end

	if currentObject ~= newSelectedObject or currentObjectIndex ~= newSelectedObjectIndex or currentSubObjectIndex ~= newSelectedSubObjectIndex then
		self:setSelectedObject(newSelectedObject, newSelectedSubObjectIndex)
	end
end

function Vehicle:actionEventToggleSelectionReverse(actionName, inputValue, callbackState, isAnalog)
	local currentSelection = self.currentSelection
	local currentObject = currentSelection.object
	local currentObjectIndex = currentSelection.index
	local currentSubObjectIndex = currentSelection.subIndex
	local newSelectedSubObjectIndex = currentSubObjectIndex - 1
	local newSelectedObjectIndex = currentObjectIndex
	local newSelectedObject = currentObject

	if newSelectedSubObjectIndex < 1 then
		newSelectedSubObjectIndex = 1
		newSelectedObjectIndex = currentObjectIndex - 1

		if newSelectedObjectIndex < 1 then
			newSelectedObjectIndex = #self.selectableObjects
		end

		newSelectedObject = self.selectableObjects[newSelectedObjectIndex]

		if newSelectedObject ~= nil then
			newSelectedSubObjectIndex = #newSelectedObject.subSelections
		end
	end

	if currentObject ~= newSelectedObject or currentObjectIndex ~= newSelectedObjectIndex or currentSubObjectIndex ~= newSelectedSubObjectIndex then
		self:setSelectedObject(newSelectedObject, newSelectedSubObjectIndex)
	end
end

function Vehicle.getReloadXML(vehicle)
	local vehicleXMLFile = XMLFile.create("vehicleXMLFile", "", "vehicles", Vehicle.xmlSchemaSavegame)

	if vehicleXMLFile ~= nil then
		local key = string.format("vehicles.vehicle(%d)", 0)

		vehicleXMLFile:setValue(key .. "#id", 1)
		vehicleXMLFile:setValue(key .. "#filename", HTMLUtil.encodeToHTML(NetworkUtil.convertToNetworkFilename(vehicle.configFileName)))

		vehicle.currentSavegameId = 1

		vehicle:saveToXMLFile(vehicleXMLFile, key, {})

		return vehicleXMLFile
	end

	return nil
end

function Vehicle.getSpecValueAge(storeItem, realItem, _, saleItem)
	if realItem ~= nil and realItem.age ~= nil then
		return string.format(g_i18n:getText("shop_age"), realItem.age)
	elseif saleItem ~= nil and saleItem.age ~= nil then
		return string.format(g_i18n:getText("shop_age"), saleItem.age)
	end

	return nil
end

function Vehicle.getSpecValueDailyUpkeep(storeItem, realItem, _, saleItem)
	local dailyUpkeep = storeItem.dailyUpkeep

	if realItem ~= nil and realItem.getDailyUpkeep ~= nil then
		dailyUpkeep = realItem:getDailyUpkeep()
	elseif saleItem ~= nil then
		dailyUpkeep = 0
	end

	if dailyUpkeep == 0 then
		return nil
	end

	return string.format(g_i18n:getText("shop_maintenanceValue"), g_i18n:formatMoney(dailyUpkeep, 2))
end

function Vehicle.getSpecValueOperatingTime(storeItem, realItem, _, saleItem)
	local operatingTime = nil

	if realItem ~= nil and realItem.operatingTime ~= nil then
		operatingTime = realItem.operatingTime
	elseif saleItem ~= nil then
		operatingTime = saleItem.operatingTime
	else
		return nil
	end

	local minutes = operatingTime / 60000
	local hours = math.floor(minutes / 60)
	minutes = math.floor((minutes - hours * 60) / 6)

	return string.format(g_i18n:getText("shop_operatingTime"), hours, minutes)
end

function Vehicle.loadSpecValueWorkingWidth(xmlFile, customEnvironment)
	return xmlFile:getValue("vehicle.storeData.specs.workingWidth")
end

function Vehicle.getSpecValueWorkingWidth(storeItem, realItem)
	if storeItem.specs.workingWidth ~= nil then
		return string.format(g_i18n:getText("shop_workingWidthValue"), g_i18n:formatNumber(storeItem.specs.workingWidth, 1, true))
	end

	return nil
end

function Vehicle.loadSpecValueWorkingWidthConfig(xmlFile, customEnvironment)
	local workingWidths = {}
	local isValid = false

	for name, id in pairs(g_configurationManager:getConfigurations()) do
		local specializationKey = g_configurationManager:getConfigurationAttribute(name, "xmlKey")

		if specializationKey ~= nil then
			specializationKey = "." .. specializationKey
		else
			specializationKey = ""
		end

		local configrationsKey = string.format("vehicle%s.%sConfigurations", specializationKey, name)
		workingWidths[name] = {}
		local i = 0

		while true do
			local baseKey = string.format("%s.%sConfiguration(%d)", configrationsKey, name, i)

			if not xmlFile:hasProperty(baseKey) then
				break
			end

			workingWidths[name][i + 1] = xmlFile:getValue(baseKey .. "#workingWidth")

			if workingWidths[name][i + 1] ~= nil then
				isValid = true
			end

			i = i + 1
		end
	end

	if isValid then
		return workingWidths
	end
end

function Vehicle.getSpecValueWorkingWidthConfig(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.workingWidthConfig ~= nil then
		local minWorkingWidth = 0
		local workingWidth = 0

		if configurations ~= nil and (realItem ~= nil or saleItem ~= nil) then
			for configName, config in pairs(configurations) do
				local width = storeItem.specs.workingWidthConfig[configName][config]

				if width ~= nil then
					workingWidth = width
				end
			end
		else
			local minWidth = math.huge
			local maxWidth = 0

			for configName, configs in pairs(storeItem.specs.workingWidthConfig) do
				for _, width in pairs(configs) do
					minWidth = math.min(minWidth, width)
					maxWidth = math.max(maxWidth, width)
				end
			end

			minWorkingWidth = minWidth
			workingWidth = maxWidth
		end

		if not returnValues then
			if minWorkingWidth ~= 0 and minWorkingWidth ~= math.huge and minWorkingWidth ~= workingWidth then
				return string.format(g_i18n:getText("shop_workingWidthValue"), string.format("%s-%s", g_i18n:formatNumber(minWorkingWidth, 1, true), g_i18n:formatNumber(workingWidth, 1, true)))
			else
				return string.format(g_i18n:getText("shop_workingWidthValue"), g_i18n:formatNumber(workingWidth, 1, true))
			end
		else
			return workingWidth
		end
	end

	return nil
end

function Vehicle.loadSpecValueSpeedLimit(xmlFile, customEnvironment)
	return xmlFile:getValue("vehicle.base.speedLimit#value")
end

function Vehicle.getSpecValueSpeedLimit(storeItem, realItem)
	if storeItem.specs.speedLimit ~= nil then
		return string.format(g_i18n:getText("shop_maxSpeed"), string.format("%1d", g_i18n:getSpeed(storeItem.specs.speedLimit)), g_i18n:getSpeedMeasuringUnit())
	end

	return nil
end

function Vehicle.loadSpecValueWeight(xmlFile, customEnvironment)
	local massData = {
		componentMass = 0
	}

	xmlFile:iterate("vehicle.base.components.component", function (index, key)
		local mass = xmlFile:getValue(key .. "#mass", 0) / 1000
		massData.componentMass = massData.componentMass + mass
	end)

	massData.fillUnitMassData = FillUnit.loadSpecValueFillUnitMassData(xmlFile, customEnvironment)
	massData.wheelMassDefaultConfig = Wheels.loadSpecValueWheelWeight(xmlFile, customEnvironment)
	local configMin, configMax = nil
	massData.storeDataConfigs = {}

	xmlFile:iterate("vehicle.storeData.specs.weight.config", function (index, key)
		local config = {
			name = xmlFile:getValue(key .. "#name")
		}

		if config.name ~= nil then
			config.index = xmlFile:getValue(key .. "#index", 1)
			config.value = xmlFile:getValue(key .. "#value", 0) / 1000
			configMin = math.min(configMin or math.huge, config.value * 1000)
			configMax = math.max(configMax or -math.huge, config.value * 1000)

			table.insert(massData.storeDataConfigs, config)
		end
	end)

	if #massData.storeDataConfigs == 0 then
		massData.storeDataConfigs = nil
	end

	if not xmlFile:getValue("vehicle.storeData.specs.weight#ignore", false) then
		massData.storeDataMin = xmlFile:getValue("vehicle.storeData.specs.weight#minValue", configMin)
		massData.storeDataMax = xmlFile:getValue("vehicle.storeData.specs.weight#maxValue", configMax)

		if massData.componentMass > 0 or massData.storeDataMin ~= nil then
			return massData
		end
	end
end

function Vehicle.getSpecConfigValuesWeight(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.weight ~= nil and storeItem.specs.weight.storeDataConfigs ~= nil then
		return storeItem.specs.weight.storeDataConfigs
	end
end

function Vehicle.getSpecValueWeight(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.weight ~= nil then
		local vehicleMass, vehicleMassMax = nil

		if realItem ~= nil then
			realItem:updateMass()

			vehicleMass = realItem:getTotalMass(true)
		elseif storeItem.specs.weight.storeDataMin ~= nil then
			vehicleMass = (storeItem.specs.weight.storeDataMin or 0) / 1000
			vehicleMassMax = (storeItem.specs.weight.storeDataMax or 0) / 1000
		elseif storeItem.specs.weight.componentMass ~= nil then
			vehicleMass = storeItem.specs.weight.componentMass + (storeItem.specs.weight.wheelMassDefaultConfig or 0)
			vehicleMass = vehicleMass + FillUnit.getSpecValueStartFillUnitMassByMassData(storeItem.specs.weight.fillUnitMassData)
		end

		if vehicleMass ~= nil and vehicleMass ~= 0 then
			if returnValues then
				if returnRange then
					return vehicleMass, vehicleMassMax
				else
					return vehicleMass
				end
			elseif vehicleMassMax ~= nil and vehicleMassMax ~= 0 then
				return g_i18n:formatMass(vehicleMass, vehicleMassMax)
			else
				return g_i18n:formatMass(vehicleMass)
			end
		end
	end

	return nil
end

function Vehicle.loadSpecValueAdditionalWeight(xmlFile, customEnvironment)
	local maxWeight = xmlFile:getValue("vehicle.base.components#maxMass")

	if maxWeight ~= nil then
		return maxWeight / 1000
	end
end

function Vehicle.getSpecValueAdditionalWeight(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if not g_currentMission.missionInfo.trailerFillLimit then
		return nil
	end

	if storeItem.specs.additionalWeight ~= nil then
		local baseWeight = Vehicle.getSpecValueWeight(storeItem, realItem, configurations, saleItem, true)

		if baseWeight ~= nil then
			local additionalWeight = storeItem.specs.additionalWeight - baseWeight

			if returnValues then
				return additionalWeight
			else
				return g_i18n:formatMass(additionalWeight)
			end
		end
	end

	return nil
end

function Vehicle.loadSpecValueCombinations(xmlFile, customEnvironment, baseDirectory)
	local combinations = {}

	xmlFile:iterate("vehicle.storeData.specs.combination", function (index, key)
		local combinationData = {}
		local xmlFilename = xmlFile:getValue(key .. "#xmlFilename")

		if xmlFilename ~= nil then
			combinationData.xmlFilename = Utils.getFilename(xmlFilename)
			combinationData.customXMLFilename = Utils.getFilename(xmlFilename, baseDirectory)
		end

		local filterCategoryStr = xmlFile:getValue(key .. "#filterCategory")

		if filterCategoryStr ~= nil then
			combinationData.filterCategories = filterCategoryStr:split(" ")
		end

		combinationData.filterSpec = xmlFile:getValue(key .. "#filterSpec")
		combinationData.filterSpecMin = xmlFile:getValue(key .. "#filterSpecMin", 0)
		combinationData.filterSpecMax = xmlFile:getValue(key .. "#filterSpecMax", 1)

		if combinationData.xmlFilename ~= nil or combinationData.filterCategories ~= nil or combinationData.filterSpec then
			table.insert(combinations, combinationData)
		end
	end)

	return combinations
end

function Vehicle.getSpecValueCombinations(storeItem, realItem)
	return storeItem.specs.combinations
end

function Vehicle.getSpecValueSlots(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	local numOwned = g_currentMission:getNumOfItems(storeItem)
	local valueText = ""

	if realItem ~= nil then
		local sellSlotUsage = g_currentMission.slotSystem:getStoreItemSlotUsage(storeItem, numOwned == 1)

		if sellSlotUsage ~= 0 then
			valueText = "+" .. sellSlotUsage
		end
	else
		local buySlotUsage = g_currentMission.slotSystem:getStoreItemSlotUsage(storeItem, numOwned == 0)

		if storeItem.bundleInfo ~= nil then
			buySlotUsage = 0

			for i = 1, #storeItem.bundleInfo.bundleItems do
				local bundleInfo = storeItem.bundleInfo.bundleItems[i]
				local numBundleItemOwned = g_currentMission:getNumOfItems(bundleInfo.item)
				local usage = g_currentMission.slotSystem:getStoreItemSlotUsage(bundleInfo.item, numBundleItemOwned == 0)
				buySlotUsage = buySlotUsage + usage
			end
		end

		if buySlotUsage ~= 0 then
			valueText = "-" .. buySlotUsage
		end
	end

	if valueText ~= "" then
		return valueText
	else
		return nil
	end
end
