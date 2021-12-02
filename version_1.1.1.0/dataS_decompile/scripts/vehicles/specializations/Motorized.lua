source("dataS/scripts/vehicles/specializations/events/SetMotorTurnedOnEvent.lua")
source("dataS/scripts/vehicles/specializations/events/MotorGearShiftEvent.lua")

Motorized = {
	DAMAGED_USAGE_INCREASE = 0.3
}

function Motorized.initSpecialization()
	g_configurationManager:addConfigurationType("motor", g_i18n:getText("configuration_motorSetup"), "motorized", nil, Motorized.getStoreAdditionalConfigData, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
	g_storeManager:addSpecType("fuel", "shopListAttributeIconFuel", Motorized.loadSpecValueFuel, Motorized.getSpecValueFuelDiesel, "vehicle")
	g_storeManager:addSpecType("electricCharge", "shopListAttributeIconElectricCharge", Motorized.loadSpecValueFuel, Motorized.getSpecValueFuelElectricCharge, "vehicle")
	g_storeManager:addSpecType("methane", "shopListAttributeIconMethane", Motorized.loadSpecValueFuel, Motorized.getSpecValueFuelMethane, "vehicle")
	g_storeManager:addSpecType("maxSpeed", "shopListAttributeIconMaxSpeed", Motorized.loadSpecValueMaxSpeed, Motorized.getSpecValueMaxSpeed, "vehicle")
	g_storeManager:addSpecType("power", "shopListAttributeIconPower", Motorized.loadSpecValuePower, Motorized.getSpecValuePower, "vehicle")
	g_storeManager:addSpecType("powerConfig", "shopListAttributeIconPower", Motorized.loadSpecValuePowerConfig, Motorized.getSpecValuePowerConfig, "vehicle")
	g_storeManager:addSpecType("transmission", "shopListAttributeIconTransmission", Motorized.loadSpecValueTransmission, Motorized.getSpecValueTransmission, "vehicle")
	Vehicle.registerStateChange("MOTOR_TURN_ON")
	Vehicle.registerStateChange("MOTOR_TURN_OFF")

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Motorized")
	Motorized.registerDifferentialXMLPaths(schema, "vehicle.motorized.differentialConfigurations.differentialConfiguration(?)")
	Motorized.registerDifferentialXMLPaths(schema, "vehicle.motorized.differentials")
	Motorized.registerMotorXMLPaths(schema, "vehicle.motorized.motorConfigurations.motorConfiguration(?)")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.motorized.motorConfigurations.motorConfiguration(?)")
	Motorized.registerConsumerXMLPaths(schema, "vehicle.motorized.consumerConfigurations.consumerConfiguration(?)")
	Motorized.registerConsumerXMLPaths(schema, "vehicle.motorized.consumers")
	schema:register(XMLValueType.FLOAT, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).wheels#maxForwardSpeed", "Max. forward speed")
	schema:register(XMLValueType.FLOAT, "vehicle.wheels#maxForwardSpeed", "Max. forward speed")
	Motorized.registerSoundXMLPaths(schema, "vehicle.motorized.sounds")
	Motorized.registerSoundXMLPaths(schema, "vehicle.motorized.motorConfigurations.motorConfiguration(?).sounds")
	schema:register(XMLValueType.FLOAT, "vehicle.motorized.reverseDriveSound#threshold", "Reverse drive sound turn on speed threshold", 4)
	schema:register(XMLValueType.FLOAT, "vehicle.motorized.brakeCompressor#capacity", "Brake compressor capacity", 6)
	schema:register(XMLValueType.FLOAT, "vehicle.motorized.brakeCompressor#refillFillLevel", "Brake compressor refill threshold", "half of capacity")
	schema:register(XMLValueType.FLOAT, "vehicle.motorized.brakeCompressor#fillSpeed", "Brake compressor fill speed", 0.6)
	ParticleUtil.registerParticleXMLPaths(schema, "vehicle.motorized.exhaustParticleSystems", "exhaustParticleSystem(?)")
	schema:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustParticleSystems#minScale", "Min. scale", 0.5)
	schema:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustParticleSystems#maxScale", "Max. scale", 1)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.motorized.exhaustFlap#node", "Exhaust Flap Node")
	schema:register(XMLValueType.ANGLE, "vehicle.motorized.exhaustFlap#maxRot", "Max. rotation", 0)
	schema:register(XMLValueType.INT, "vehicle.motorized.exhaustFlap#rotationAxis", "Rotation Axis", 1)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#node", "Effect link node")
	schema:register(XMLValueType.STRING, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#filename", "Effect i3d filename")
	schema:register(XMLValueType.VECTOR_4, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#minRpmColor", "Min. rpm color", "0 0 0 1")
	schema:register(XMLValueType.VECTOR_4, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#maxRpmColor", "Max. rpm color", "0.0384 0.0359 0.0627 2.0")
	schema:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#minRpmScale", "Min. rpm scale", 0.25)
	schema:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#maxRpmScale", "Max. rpm scale", 0.95)
	schema:register(XMLValueType.FLOAT, "vehicle.motorized.exhaustEffects.exhaustEffect(?)#upFactor", "Defines how far the effect goes up in the air in meter", 0.75)
	schema:register(XMLValueType.FLOAT, "vehicle.motorized.motorStartDuration", "Motor start duration", "Duration motor takes to start. After this time player can start to drive")
	schema:register(XMLValueType.L10N_STRING, "vehicle.motorized#clutchNoEngagedWarning", "Warning to be displayed if try to start the engine but clutch not engaged", "warning_motorClutchNoEngaged")
	schema:register(XMLValueType.L10N_STRING, "vehicle.motorized#clutchCrackingGearWarning", "Warning to be display if user trys to select a gear without pressing clutch pedal", "action_clutchCrackingGear")
	schema:register(XMLValueType.L10N_STRING, "vehicle.motorized#clutchCrackingGroupWarning", "Warning to be display if user trys to select a gear without pressing clutch pedal", "action_clutchCrackingGroup")
	schema:register(XMLValueType.L10N_STRING, "vehicle.motorized#turnOnText", "Motor start text", "action_startMotor")
	schema:register(XMLValueType.L10N_STRING, "vehicle.motorized#turnOffText", "Motor stop text", "action_stopMotor")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.motorized.gearLevers.gearLever(?)#node", "Gear lever node")
	schema:register(XMLValueType.INT, "vehicle.motorized.gearLevers.gearLever(?)#centerAxis", "Axis of center bay")
	schema:register(XMLValueType.TIME, "vehicle.motorized.gearLevers.gearLever(?)#changeTime", "Time to move lever from one state to another", 0.5)
	schema:register(XMLValueType.TIME, "vehicle.motorized.gearLevers.gearLever(?)#handsOnDelay", "The animation is delayed by this time to have time to put the hand on the lever", 0)
	schema:register(XMLValueType.INT, "vehicle.motorized.gearLevers.gearLever(?).state(?)#gear", "Gear index")
	schema:register(XMLValueType.INT, "vehicle.motorized.gearLevers.gearLever(?).state(?)#group", "Group index")
	schema:register(XMLValueType.ANGLE, "vehicle.motorized.gearLevers.gearLever(?).state(?)#xRot", "X rotation")
	schema:register(XMLValueType.ANGLE, "vehicle.motorized.gearLevers.gearLever(?).state(?)#yRot", "Y rotation")
	schema:register(XMLValueType.ANGLE, "vehicle.motorized.gearLevers.gearLever(?).state(?)#zRot", "Z rotation")
	schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.power", "Power")
	schema:register(XMLValueType.FLOAT, "vehicle.storeData.specs.maxSpeed", "Max speed")
	schema:register(XMLValueType.FLOAT, "vehicle.motorized.motorConfigurations.motorConfiguration(?)#maxSpeed", "Max speed for shop")
	schema:register(XMLValueType.FLOAT, "vehicle.motorized.motorConfigurations.motorConfiguration(?)#hp", "HP for shop")
	schema:register(XMLValueType.STRING, "vehicle.motorized#statsType", "Statistic type", "tractor")
	schema:register(XMLValueType.BOOL, "vehicle.motorized#forceSpeedHudDisplay", "Force usage of vehicle speed display in hud independent of setting", false)
	schema:register(XMLValueType.BOOL, "vehicle.motorized#forceRpmHudDisplay", "Force usage of motor speed display in hud independent of setting", false)
	Dashboard.registerDashboardXMLPaths(schema, "vehicle.motorized.dashboards", "rpm | load | speed | speedDir | fuelUsage | motorTemperature | motorTemperatureWarning | clutchPedal | gear | gearGroup | movingDirection | ignitionState")
	Dashboard.registerDashboardWarningXMLPaths(schema, "vehicle.motorized.dashboards")
	AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.motorized.animationNodes")
	schema:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#isMotorStarting", "Is motor starting")
	schema:register(XMLValueType.BOOL, Dashboard.GROUP_XML_KEY .. "#isMotorRunning", "Is motor running")
	schema:setXMLSpecializationType()
end

function Motorized.registerMotorXMLPaths(schema, baseKey)
	schema:register(XMLValueType.STRING, baseKey .. ".motor#type", "Motor type", "vehicle")
	schema:register(XMLValueType.STRING, baseKey .. ".motor#startAnimationName", "Motor start animation", "vehicle")
	schema:register(XMLValueType.INT, baseKey .. "#consumerConfigurationIndex", "Consumer configuration index", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#minRpm", "Min. RPM", 1000)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#maxRpm", "Max. RPM", 1800)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#minSpeed", "Min. driving speed", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#maxForwardSpeed", "Max. forward speed")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#maxBackwardSpeed", "Max. backward speed")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#accelerationLimit", "Acceleration limit", 2)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#brakeForce", "Brake force", 10)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#lowBrakeForceScale", "Low brake force scale", 0.5)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#lowBrakeForceSpeedLimit", "Low brake force speed limit (below this speed the lowBrakeForceScale is activated)", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#torqueScale", "Scale factor for torque curve", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#ptoMotorRpmRatio", "PTO to motor rpm ratio", 4)
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#minForwardGearRatio", "Min. forward gear ratio")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#maxForwardGearRatio", "Max. forward gear ratio")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#minBackwardGearRatio", "Min. backward gear ratio")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#maxBackwardGearRatio", "Max. backward gear ratio")
	schema:register(XMLValueType.TIME, baseKey .. ".transmission#gearChangeTime", "Gear change time")
	schema:register(XMLValueType.TIME, baseKey .. ".transmission#autoGearChangeTime", "Auto gear change time")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#axleRatio", "Axle ratio", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission#startGearThreshold", "Adjusts which gear is used as start gear", VehicleMotor.GEAR_START_THRESHOLD)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor.torque(?)#normRpm", "Norm RPM (0-1)")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor.torque(?)#rpm", "RPM")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor.torque(?)#torque", "Torque")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#rotInertia", "Rotation inertia", "Peak. motor torque / 600")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#dampingRateScale", "Scales motor damping rate", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".motor#rpmSpeedLimit", "Motor rotation acceleration limit")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.forwardGear(?)#gearRatio", "Gear ratio")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.forwardGear(?)#maxSpeed", "Gear ratio")
	schema:register(XMLValueType.BOOL, baseKey .. ".transmission.forwardGear(?)#defaultGear", "Gear ratio")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.forwardGear(?)#name", "Gear name to display")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.forwardGear(?)#reverseName", "Gear name to display (if reverse direction is active)")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.backwardGear(?)#gearRatio", "Gear ratio")
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.backwardGear(?)#maxSpeed", "Gear ratio")
	schema:register(XMLValueType.BOOL, baseKey .. ".transmission.backwardGear(?)#defaultGear", "Gear ratio")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.backwardGear(?)#name", "Gear name to display")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.backwardGear(?)#reverseName", "Gear name to display (if reverse direction is active)")
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.groups#type", "Type of groups (powershift/default)", "default")
	schema:register(XMLValueType.TIME, baseKey .. ".transmission.groups#changeTime", "Change time if default type", 0.5)
	schema:register(XMLValueType.FLOAT, baseKey .. ".transmission.groups.group(?)#ratio", "Ratio while stage active")
	schema:register(XMLValueType.BOOL, baseKey .. ".transmission.groups.group(?)#isDefault", "Is default stage", false)
	schema:register(XMLValueType.STRING, baseKey .. ".transmission.groups.group(?)#name", "Gear name to display")
	schema:register(XMLValueType.BOOL, baseKey .. ".transmission.directionChange#useGroup", "Use group as reverse change", false)
	schema:register(XMLValueType.INT, baseKey .. ".transmission.directionChange#reverseGroupIndex", "Group will be activated while direction is changed", 1)
	schema:register(XMLValueType.BOOL, baseKey .. ".transmission.directionChange#useGear", "Use gear as reverse change", false)
	schema:register(XMLValueType.INT, baseKey .. ".transmission.directionChange#reverseGearIndex", "Gear will be activated while direction is changed", 1)
	schema:register(XMLValueType.TIME, baseKey .. ".transmission.directionChange#changeTime", "Direction change time", 0.5)
	schema:register(XMLValueType.BOOL, baseKey .. ".transmission.manualShift#gears", "Defines if gears can be shifted manually", true)
	schema:register(XMLValueType.BOOL, baseKey .. ".transmission.manualShift#groups", "Defines if groups can be shifted manually", true)
	schema:register(XMLValueType.L10N_STRING, baseKey .. ".transmission#name", "Name of transmission to display in the shop")
	schema:register(XMLValueType.FLOAT, baseKey .. ".motorStartDuration", "Motor start duration", "Duration motor takes to start. After this time player can start to drive")
end

function Motorized.registerDifferentialXMLPaths(schema, baseKey)
	schema:register(XMLValueType.FLOAT, baseKey .. ".differentials.differential(?)#torqueRatio", "Torque ratio", 0.5)
	schema:register(XMLValueType.FLOAT, baseKey .. ".differentials.differential(?)#maxSpeedRatio", "Max. speed ratio", 1.3)
	schema:register(XMLValueType.INT, baseKey .. ".differentials.differential(?)#wheelIndex1", "Wheel index 1")
	schema:register(XMLValueType.INT, baseKey .. ".differentials.differential(?)#wheelIndex2", "Wheel index 2")
	schema:register(XMLValueType.INT, baseKey .. ".differentials.differential(?)#differentialIndex1", "Differential index 1")
	schema:register(XMLValueType.INT, baseKey .. ".differentials.differential(?)#differentialIndex2", "Differential index 2")
end

function Motorized.registerConsumerXMLPaths(schema, baseKey)
	schema:register(XMLValueType.L10N_STRING, baseKey .. "#consumersEmptyWarning", "Consumers empty warning", "warning_motorFuelEmpty")
	schema:register(XMLValueType.INT, baseKey .. ".consumer(?)#fillUnitIndex", "Fill unit index", 1)
	schema:register(XMLValueType.STRING, baseKey .. ".consumer(?)#fillType", "Fill type name")
	schema:register(XMLValueType.FLOAT, baseKey .. ".consumer(?)#usage", "Usage in l/h", 1)
	schema:register(XMLValueType.BOOL, baseKey .. ".consumer(?)#permanentConsumption", "Do permanent consumption", 1)
	schema:register(XMLValueType.FLOAT, baseKey .. ".consumer(?)#refillLitersPerSecond", "Refill liters per second", 0)
	schema:register(XMLValueType.FLOAT, baseKey .. ".consumer(?)#refillCapacityPercentage", "Refill capacity percentage", 0)
	schema:register(XMLValueType.FLOAT, baseKey .. ".consumer(?)#capacity", "If defined the capacity of the fillUnit fill be overwritten with this value")
end

function Motorized.registerSoundXMLPaths(schema, baseKey)
	SoundManager.registerSampleXMLPaths(schema, baseKey, "motorStart")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "motorStop")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearbox")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "clutchCracking")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearEngaged")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearDisengaged")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearLeverStart")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearLeverEnd")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearGroupLeverStart")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearGroupLeverEnd")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "gearGroupChange")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "blowOffValve")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "retarder")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "motor(?)")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "airCompressorStart")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "airCompressorStop")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "airCompressorRun")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "compressedAir")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "airRelease")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "reverseDrive")
	SoundManager.registerSampleXMLPaths(schema, baseKey, "brake")
end

function Motorized.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(VehicleSettings, specializations)
end

function Motorized.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onStartMotor")
	SpecializationUtil.registerEvent(vehicleType, "onStopMotor")
	SpecializationUtil.registerEvent(vehicleType, "onGearDirectionChanged")
	SpecializationUtil.registerEvent(vehicleType, "onGearChanged")
	SpecializationUtil.registerEvent(vehicleType, "onGearGroupChanged")
	SpecializationUtil.registerEvent(vehicleType, "onClutchCreaking")
end

function Motorized.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadDifferentials", Motorized.loadDifferentials)
	SpecializationUtil.registerFunction(vehicleType, "loadMotor", Motorized.loadMotor)
	SpecializationUtil.registerFunction(vehicleType, "loadGears", Motorized.loadGears)
	SpecializationUtil.registerFunction(vehicleType, "loadGearGroups", Motorized.loadGearGroups)
	SpecializationUtil.registerFunction(vehicleType, "loadExhaustEffects", Motorized.loadExhaustEffects)
	SpecializationUtil.registerFunction(vehicleType, "onExhaustEffectI3DLoaded", Motorized.onExhaustEffectI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadSounds", Motorized.loadSounds)
	SpecializationUtil.registerFunction(vehicleType, "loadConsumerConfiguration", Motorized.loadConsumerConfiguration)
	SpecializationUtil.registerFunction(vehicleType, "getIsMotorStarted", Motorized.getIsMotorStarted)
	SpecializationUtil.registerFunction(vehicleType, "getIsMotorInNeutral", Motorized.getIsMotorInNeutral)
	SpecializationUtil.registerFunction(vehicleType, "getCanMotorRun", Motorized.getCanMotorRun)
	SpecializationUtil.registerFunction(vehicleType, "getStopMotorOnLeave", Motorized.getStopMotorOnLeave)
	SpecializationUtil.registerFunction(vehicleType, "getMotorNotAllowedWarning", Motorized.getMotorNotAllowedWarning)
	SpecializationUtil.registerFunction(vehicleType, "startMotor", Motorized.startMotor)
	SpecializationUtil.registerFunction(vehicleType, "stopMotor", Motorized.stopMotor)
	SpecializationUtil.registerFunction(vehicleType, "updateMotorProperties", Motorized.updateMotorProperties)
	SpecializationUtil.registerFunction(vehicleType, "controlVehicle", Motorized.controlVehicle)
	SpecializationUtil.registerFunction(vehicleType, "updateConsumers", Motorized.updateConsumers)
	SpecializationUtil.registerFunction(vehicleType, "updateMotorTemperature", Motorized.updateMotorTemperature)
	SpecializationUtil.registerFunction(vehicleType, "getMotor", Motorized.getMotor)
	SpecializationUtil.registerFunction(vehicleType, "getMotorStartTime", Motorized.getMotorStartTime)
	SpecializationUtil.registerFunction(vehicleType, "getMotorType", Motorized.getMotorType)
	SpecializationUtil.registerFunction(vehicleType, "getMotorRpmPercentage", Motorized.getMotorRpmPercentage)
	SpecializationUtil.registerFunction(vehicleType, "getMotorRpmReal", Motorized.getMotorRpmReal)
	SpecializationUtil.registerFunction(vehicleType, "getMotorLoadPercentage", Motorized.getMotorLoadPercentage)
	SpecializationUtil.registerFunction(vehicleType, "getMotorBlowOffValveState", Motorized.getMotorBlowOffValveState)
	SpecializationUtil.registerFunction(vehicleType, "getConsumerFillUnitIndex", Motorized.getConsumerFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "getAirConsumerUsage", Motorized.getAirConsumerUsage)
	SpecializationUtil.registerFunction(vehicleType, "getTraveledDistanceStatsActive", Motorized.getTraveledDistanceStatsActive)
	SpecializationUtil.registerFunction(vehicleType, "setGearLeversState", Motorized.setGearLeversState)
	SpecializationUtil.registerFunction(vehicleType, "generateShiftAnimation", Motorized.generateShiftAnimation)
	SpecializationUtil.registerFunction(vehicleType, "getGearInfoToDisplay", Motorized.getGearInfoToDisplay)
	SpecializationUtil.registerFunction(vehicleType, "setTransmissionDirection", Motorized.setTransmissionDirection)
	SpecializationUtil.registerFunction(vehicleType, "getDirectionChangeMode", Motorized.getDirectionChangeMode)
	SpecializationUtil.registerFunction(vehicleType, "getGearShiftMode", Motorized.getGearShiftMode)
	SpecializationUtil.registerFunction(vehicleType, "stopVehicle", Motorized.stopVehicle)
end

function Motorized.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getBrakeForce", Motorized.getBrakeForce)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Motorized.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Motorized.removeFromPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsOperating", Motorized.getIsOperating)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateOnLeave", Motorized.getDeactivateOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDeactivateLightsOnLeave", Motorized.getDeactivateLightsOnLeave)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadDashboardGroupFromXML", Motorized.loadDashboardGroupFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsDashboardGroupActive", Motorized.getIsDashboardGroupActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActiveForInteriorLights", Motorized.getIsActiveForInteriorLights)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsActiveForWipers", Motorized.getIsActiveForWipers)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getName", Motorized.getName)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Motorized.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsPowered", Motorized.getIsPowered)
end

function Motorized.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onSetBroken", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onGearDirectionChanged", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onGearChanged", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onGearGroupChanged", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onClutchCreaking", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onVehicleSettingChanged", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onAIJobStarted", Motorized)
	SpecializationUtil.registerEventListener(vehicleType, "onAIJobFinished", Motorized)
end

function Motorized:onLoad(savegame)
	local spec = self.spec_motorized

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.motor.animationNodes.animationNode", "motor")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.differentialConfigurations", "vehicle.motorized.differentialConfigurations")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.motorConfigurations", "vehicle.motorized.motorConfigurations")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.maximalAirConsumptionPerFullStop", "vehicle.motorized.consumerConfigurations.consumerConfiguration.consumer(with fill type 'air')#usage (is now in usage per second at full brake power)")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.indoorHud.rpm", "vehicle.motorized.dashboards.dashboard with valueType 'rpm'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.indoorHud.speed", "vehicle.motorized.dashboards.dashboard with valueType 'speed'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.indoorHud.fuelUsage", "vehicle.motorized.dashboards.dashboard with valueType 'fuelUsage'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.indoorHud.fuel", "fillUnit.dashboard with valueType 'fillLevel'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.motor", "vehicle.motorized.motorConfigurations.motorConfiguration(?).motor")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.transmission", "vehicle.motorized.motorConfigurations.motorConfiguration(?).transmission")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.fuelCapacity", "vehicle.motorized.consumerConfigurations.consumerConfiguration.consumer#capacity")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.motorized.motorConfigurations.motorConfiguration(?).fuelCapacity", "vehicle.motorized.consumerConfigurations.consumerConfiguration.consumer#capacity")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle#consumerConfigurationIndex", "vehicle.motorized.motorConfigurations.motorConfiguration(?)#consumerConfigurationIndex'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.motorized.exhaustParticleSystems#count")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, self.configFileName, "vehicle.motorized.exhaustParticleSystems.exhaustParticleSystem1", "vehicle.motorized.exhaustParticleSystems.exhaustParticleSystem")

	spec.motorizedNode = nil

	for _, component in pairs(self.components) do
		if component.motorized then
			spec.motorizedNode = component.node

			break
		end
	end

	spec.directionChangeMode = VehicleMotor.DIRECTION_CHANGE_MODE_AUTOMATIC
	spec.gearShiftMode = VehicleMotor.SHIFT_MODE_AUTOMATIC
	local configKey = string.format("vehicle.motorized.motorConfigurations.motorConfiguration(%d)", self.configurations.motor - 1)

	self:loadDifferentials(self.xmlFile, self.differentialIndex)
	self:loadMotor(self.xmlFile, self.configurations.motor)
	self:loadSounds(self.xmlFile, "vehicle.motorized.sounds")

	if self.xmlFile:hasProperty(configKey) then
		self:loadSounds(self.xmlFile, configKey .. ".sounds")
	end

	self:loadConsumerConfiguration(self.xmlFile, spec.consumerConfigurationIndex)

	if self.isClient then
		self:loadExhaustEffects(self.xmlFile)
	end

	spec.gearLevers = {}
	spec.activeGearLeverInterpolators = {}

	self.xmlFile:iterate("vehicle.motorized.gearLevers.gearLever", function (index, key)
		local entry = {
			node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
		}

		if entry.node ~= nil then
			entry.centerAxis = self.xmlFile:getValue(key .. "#centerAxis")
			entry.changeTime = self.xmlFile:getValue(key .. "#changeTime", 500)
			entry.handsOnDelay = self.xmlFile:getValue(key .. "#handsOnDelay", 0)
			entry.curTarget = {
				getRotation(entry.node)
			}
			entry.states = {}

			self.xmlFile:iterate(key .. ".state", function (stateIndex, stateKey)
				local state = {
					gear = self.xmlFile:getValue(stateKey .. "#gear"),
					group = self.xmlFile:getValue(stateKey .. "#group")
				}

				if state.gear ~= nil or state.group ~= nil then
					state.node = entry.node
					state.gearLever = entry
					local x, y, z = getRotation(entry.node)
					local xRot = self.xmlFile:getValue(stateKey .. "#xRot", x)
					local yRot = self.xmlFile:getValue(stateKey .. "#yRot", y)
					local zRot = self.xmlFile:getValue(stateKey .. "#zRot", z)
					state.rotation = {
						xRot,
						yRot,
						zRot
					}
					state.useRotation = {
						self.xmlFile:getValue(stateKey .. "#xRot") ~= nil,
						self.xmlFile:getValue(stateKey .. "#yRot") ~= nil,
						self.xmlFile:getValue(stateKey .. "#zRot") ~= nil
					}
					state.curRotation = {
						xRot,
						yRot,
						zRot
					}

					table.insert(entry.states, state)
				else
					Logging.xmlWarning(self.xmlFile, "Unable to load gear lever state. Missing gear or group! '%s'", stateKey)
				end
			end)
			table.insert(spec.gearLevers, entry)
		else
			Logging.xmlWarning(self.xmlFile, "Unable to load gear lever. Missing node! '%s'", key)
		end
	end)

	spec.stopMotorOnLeave = true
	spec.motorStartDuration = 0

	if spec.samples ~= nil and spec.samples.motorStart ~= nil then
		spec.motorStartDuration = spec.samples.motorStart.duration
	end

	spec.motorStartDuration = self.xmlFile:getValue("vehicle.motorized.motorStartDuration", spec.motorStartDuration) or 0

	if self.xmlFile:hasProperty(configKey) then
		spec.motorStartDuration = self.xmlFile:getValue(configKey .. ".motorStartDuration", spec.motorStartDuration)
	end

	spec.clutchNoEngagedWarning = self.xmlFile:getValue("vehicle.motorized#clutchNoEngagedWarning", "warning_motorClutchNoEngaged", self.customEnvironment)
	spec.clutchCrackingGearWarning = self.xmlFile:getValue("vehicle.motorized#clutchCrackingGearWarning", "action_clutchCrackingGear", self.customEnvironment)
	spec.clutchCrackingGroupWarning = self.xmlFile:getValue("vehicle.motorized#clutchCrackingGroupWarning", "action_clutchCrackingGroup", self.customEnvironment)
	spec.turnOnText = self.xmlFile:getValue("vehicle.motorized#turnOnText", "action_startMotor", self.customEnvironment)
	spec.turnOffText = self.xmlFile:getValue("vehicle.motorized#turnOffText", "action_stopMotor", self.customEnvironment)
	spec.speedDisplayScale = 1
	spec.motorStartTime = 0
	spec.actualLoadPercentage = 0
	spec.smoothedLoadPercentage = 0
	spec.maxDecelerationDuringBrake = 0
	spec.lastControlParameters = {}
	spec.clutchCrackingTimeOut = math.huge
	spec.clutchState = 0
	spec.clutchStateSent = 0
	spec.isMotorStarted = false
	spec.motorStopTimerDuration = g_gameSettings:getValue("motorStopTimerDuration")
	spec.motorStopTimer = spec.motorStopTimerDuration
	spec.ignitionState = 0
	spec.motorTemperature = {
		value = 20,
		valueSend = 20,
		valueMax = 120,
		valueMin = 20,
		heatingPerMS = 0.0015,
		coolingByWindPerMS = 0.001
	}
	spec.motorFan = {
		enabled = false,
		enableTemperature = 95,
		disableTemperature = 85,
		coolingPerMS = 0.003
	}
	spec.lastFuelUsage = 0
	spec.lastFuelUsageDisplay = 0
	spec.lastFuelUsageDisplayTime = 0
	spec.fuelUsageBuffer = ValueBuffer.new(250)
	spec.lastDefUsage = 0
	spec.lastAirUsage = 0
	spec.lastVehicleDamage = 0
	spec.forceSpeedHudDisplay = self.xmlFile:getValue("vehicle.motorized#forceSpeedHudDisplay", false)
	spec.forceRpmHudDisplay = self.xmlFile:getValue("vehicle.motorized#forceRpmHudDisplay", false)
	spec.statsType = string.lower(self.xmlFile:getValue("vehicle.motorized#statsType", "tractor"))

	if spec.statsType ~= "tractor" and spec.statsType ~= "car" and spec.statsType ~= "truck" then
		spec.statsType = "tractor"
	end

	spec.statsTypeDistance = spec.statsType .. "Distance"

	if self.loadDashboardsFromXML ~= nil then
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			maxFunc = "getMaxRpm",
			valueFunc = "getLastModulatedMotorRpm",
			minFunc = 0,
			valueTypeToLoad = "rpm",
			valueObject = spec.motor
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			valueFactor = 100,
			valueFunc = "getSmoothLoadPercentage",
			minFunc = 0,
			valueTypeToLoad = "load",
			maxFunc = 100,
			valueObject = spec.motor
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			valueFunc = "getLastSpeed",
			minFunc = 0,
			valueTypeToLoad = "speed",
			valueObject = self,
			maxFunc = self:getMotor():getMaximumForwardSpeed() * 3.6
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			valueTypeToLoad = "speedDir",
			centerFunc = 0,
			valueObject = self,
			valueFunc = Motorized.getDashboardSpeedDir,
			minFunc = -self:getMotor():getMaximumBackwardSpeed() * 3.6,
			maxFunc = self:getMotor():getMaximumForwardSpeed() * 3.6
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			valueFunc = "lastFuelUsageDisplay",
			valueTypeToLoad = "fuelUsage",
			valueObject = spec
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			maxFunc = "valueMax",
			valueFunc = "value",
			minFunc = "valueMin",
			valueTypeToLoad = "motorTemperature",
			valueObject = spec.motorTemperature
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			valueFunc = "value",
			valueTypeToLoad = "motorTemperatureWarning",
			valueObject = spec.motorTemperature,
			additionalAttributesFunc = Dashboard.warningAttributes,
			stateFunc = Dashboard.warningState
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			maxFunc = 1,
			valueFunc = "getSmoothedClutchPedal",
			minFunc = 0,
			valueTypeToLoad = "clutchPedal",
			valueObject = spec.motor
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			valueFunc = "getGearToDisplay",
			minFunc = 0,
			valueTypeToLoad = "gear",
			valueObject = spec.motor,
			maxFunc = math.huge
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			valueFunc = "getGearGroupToDisplay",
			minFunc = 0,
			valueTypeToLoad = "gearGroup",
			valueObject = spec.motor,
			maxFunc = math.huge
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			maxFunc = 1,
			valueFunc = "getDrivingDirection",
			minFunc = -1,
			valueTypeToLoad = "movingDirection",
			valueObject = spec.motor
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.motorized.dashboards", {
			maxFunc = 2,
			minFunc = 0,
			valueTypeToLoad = "ignitionState",
			valueObject = self,
			valueFunc = Motorized.getMotorIgnitionState
		})
	end

	spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.motorized.animationNodes", self.components, self, self.i3dMappings)
	spec.traveledDistanceBuffer = 0
	spec.dirtyFlag = self:getNextDirtyFlag()
	spec.inputDirtyFlag = self:getNextDirtyFlag()

	self:registerVehicleSetting(GameSettings.SETTING.DIRECTION_CHANGE_MODE, false)
	self:registerVehicleSetting(GameSettings.SETTING.GEAR_SHIFT_MODE, false)
end

function Motorized:onPostLoad(savegame)
	local spec = self.spec_motorized

	if self.isServer then
		local moneyChange = 0

		for _, consumer in pairs(spec.consumersByFillTypeName) do
			local fillLevel = self:getFillUnitFillLevel(consumer.fillUnitIndex)
			local minFillLevel = self:getFillUnitCapacity(consumer.fillUnitIndex) * 0.1

			if fillLevel < minFillLevel then
				local fillLevelToFill = minFillLevel - fillLevel

				self:addFillUnitFillLevel(self:getOwnerFarmId(), consumer.fillUnitIndex, fillLevelToFill, consumer.fillType, ToolType.UNDEFINED)

				local costs = fillLevelToFill * g_currentMission.economyManager:getCostPerLiter(consumer.fillType) * 2

				g_currentMission:farmStats(self:getOwnerFarmId()):updateStats("expenses", costs)
				g_currentMission:addMoney(-costs, self:getOwnerFarmId(), MoneyType.PURCHASE_FUEL)

				moneyChange = moneyChange + costs
			end
		end

		if moneyChange > 0 then
			g_currentMission:addMoneyChange(-moneyChange, self:getOwnerFarmId(), MoneyType.PURCHASE_FUEL, true)
		end
	end

	spec.propellantFillUnitIndices = {}

	for _, fillType in pairs({
		FillType.DIESEL,
		FillType.DEF,
		FillType.ELECTRICCHARGE,
		FillType.METHANE
	}) do
		local fillTypeName = g_fillTypeManager:getFillTypeNameByIndex(fillType)

		if spec.consumersByFillTypeName[fillTypeName] ~= nil then
			table.insert(spec.propellantFillUnitIndices, spec.consumersByFillTypeName[fillTypeName].fillUnitIndex)
		end
	end

	if spec.motor ~= nil then
		spec.motor:postLoad(savegame)
	end
end

function Motorized:onDelete()
	local spec = self.spec_motorized

	if spec.motor ~= nil then
		spec.motor:delete()
	end

	if spec.sharedLoadRequestIds ~= nil then
		for _, sharedLoadRequestId in ipairs(spec.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
		end

		spec.sharedLoadRequestIds = nil
	end

	ParticleUtil.deleteParticleSystems(spec.exhaustParticleSystems)
	g_soundManager:deleteSamples(spec.samples)
	g_soundManager:deleteSamples(spec.motorSamples)
	g_animationManager:deleteAnimations(spec.animationNodes)
end

function Motorized:onReadStream(streamId, connection)
	local isMotorStarted = streamReadBool(streamId)

	if isMotorStarted then
		self:startMotor(true)
	else
		self:stopMotor(true)
	end
end

function Motorized:onWriteStream(streamId, connection)
	streamWriteBool(streamId, self.spec_motorized.isMotorStarted)
end

function Motorized:onReadUpdateStream(streamId, timestamp, connection)
	local spec = self.spec_motorized

	if connection.isServer then
		if streamReadBool(streamId) then
			local rpm = streamReadUIntN(streamId, 11) / 2047
			local rpmRange = spec.motor:getMaxRpm() - spec.motor:getMinRpm()

			spec.motor:setEqualizedMotorRpm(rpm * rpmRange + spec.motor:getMinRpm())

			local loadPercentage = streamReadUIntN(streamId, 7)
			spec.motor.rawLoadPercentage = loadPercentage / 127
			spec.brakeCompressor.doFill = streamReadBool(streamId)
			local clutchState = streamReadUIntN(streamId, 5)

			spec.motor:onManualClutchChanged(clutchState / 31)
		end

		if streamReadBool(streamId) then
			spec.motor:readGearDataFromStream(streamId)
		end
	elseif streamReadBool(streamId) and streamReadBool(streamId) then
		spec.clutchState = streamReadUIntN(streamId, 7) / 127

		spec.motor:onManualClutchChanged(spec.clutchState)

		if spec.clutchState > 0 then
			self:raiseActive()
		end
	end
end

function Motorized:onWriteUpdateStream(streamId, connection, dirtyMask)
	local spec = self.spec_motorized

	if not connection.isServer then
		if streamWriteBool(streamId, self.spec_motorized.isMotorStarted) then
			local rpmRange = spec.motor:getMaxRpm() - spec.motor:getMinRpm()
			local rpm = MathUtil.clamp((spec.motor:getEqualizedMotorRpm() - spec.motor:getMinRpm()) / rpmRange, 0, 1)
			rpm = math.floor(rpm * 2047)

			streamWriteUIntN(streamId, rpm, 11)
			streamWriteUIntN(streamId, 127 * spec.actualLoadPercentage, 7)
			streamWriteBool(streamId, spec.brakeCompressor.doFill)
			streamWriteUIntN(streamId, 31 * spec.motor:getClutchPedal(), 5)
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			spec.motor:writeGearDataToStream(streamId)
		end
	elseif streamWriteBool(streamId, bitAND(dirtyMask, spec.inputDirtyFlag) ~= 0) and streamWriteBool(streamId, spec.clutchState ~= spec.clutchStateSent) then
		streamWriteUIntN(streamId, 127 * spec.clutchState, 7)

		spec.clutchStateSent = spec.clutchState
	end
end

function Motorized:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_motorized
	local accInput = 0

	if self.getAxisForward ~= nil then
		accInput = self:getAxisForward()
	end

	if self:getIsMotorStarted() then
		spec.motor:update(dt)

		if self.isServer then
			spec.actualLoadPercentage = spec.motor.rawLoadPercentage
		end

		spec.smoothedLoadPercentage = spec.motor:getSmoothLoadPercentage()

		if self.getCruiseControlState ~= nil and self:getCruiseControlState() ~= Drivable.CRUISECONTROL_STATE_OFF then
			accInput = 1
		end

		if self.isServer then
			self:updateConsumers(dt, accInput)

			local damage = self:getVehicleDamage()

			if math.abs(damage - spec.lastVehicleDamage) > 0.05 then
				self:updateMotorProperties()

				spec.lastVehicleDamage = self:getVehicleDamage()
			end
		end

		if self.isClient then
			local samples = spec.samples
			local rpm = spec.motor:getLastModulatedMotorRpm()
			local minRpm = spec.motor.minRpm
			local maxRpm = spec.motor.maxRpm
			local rpmPercentage = math.max(math.min((rpm - minRpm) / (maxRpm - minRpm), 1), 0)
			local loadPercentage = math.max(math.min(spec.smoothedLoadPercentage, 1), -1)

			g_soundManager:setSamplesLoopSynthesisParameters(spec.motorSamples, rpmPercentage, loadPercentage)

			if g_soundManager:getIsSamplePlaying(spec.motorSamples[1], 1.5 * dt) then
				if samples.airCompressorRun ~= nil and spec.consumersByFillTypeName ~= nil and spec.consumersByFillTypeName.AIR ~= nil then
					local consumer = spec.consumersByFillTypeName.AIR

					if not consumer.doRefill then
						if g_soundManager:getIsSamplePlaying(samples.airCompressorRun) then
							g_soundManager:stopSample(samples.airCompressorRun)
							g_soundManager:playSample(samples.airCompressorStop)
						end
					elseif not g_soundManager:getIsSamplePlaying(samples.airCompressorRun) then
						if samples.airCompressorStart ~= nil then
							if not g_soundManager:getIsSamplePlaying(samples.airCompressorStart, 1.5 * dt) and spec.brakeCompressor.playSampleRunTime == nil then
								g_soundManager:playSample(samples.airCompressorStart)

								spec.brakeCompressor.playSampleRunTime = g_currentMission.time + samples.airCompressorStart.duration
							end

							if not g_soundManager:getIsSamplePlaying(samples.airCompressorStart) then
								spec.brakeCompressor.playSampleRunTime = nil

								g_soundManager:stopSample(samples.airCompressorStart)
								g_soundManager:playSample(samples.airCompressorRun)
							end
						else
							g_soundManager:playSample(samples.airCompressorRun)
						end
					end
				end

				if spec.compressionSoundTime <= g_currentMission.time then
					g_soundManager:playSample(samples.airRelease)

					spec.compressionSoundTime = g_currentMission.time + math.random(10000, 40000)
				end

				local isBraking = self:getDecelerationAxis() > 0 and self:getLastSpeed() > 1

				if samples.compressedAir ~= nil then
					if isBraking then
						samples.compressedAir.brakeTime = samples.compressedAir.brakeTime + dt
					elseif samples.compressedAir.brakeTime > 0 then
						samples.compressedAir.lastBrakeTime = samples.compressedAir.brakeTime
						samples.compressedAir.brakeTime = 0

						g_soundManager:playSample(samples.compressedAir)
					end
				end

				if spec.motor.blowOffValveState > 0 then
					if not g_soundManager:getIsSamplePlaying(samples.blowOffValve) then
						g_soundManager:playSample(samples.blowOffValve)
					end
				elseif g_soundManager:getIsSamplePlaying(samples.blowOffValve) then
					g_soundManager:stopSample(samples.blowOffValve)
				end

				if samples.brake ~= nil then
					if isBraking then
						if not spec.isBrakeSamplePlaying then
							g_soundManager:playSample(samples.brake)

							spec.isBrakeSamplePlaying = true
						end
					elseif spec.isBrakeSamplePlaying then
						g_soundManager:stopSample(samples.brake)

						spec.isBrakeSamplePlaying = false
					end
				end

				if samples.reverseDrive ~= nil then
					local reverserDirection = self.getReverserDirection == nil and 1 or self:getReverserDirection()
					local isReverseDriving = spec.reverseDriveThreshold < self:getLastSpeed() and self.movingDirection ~= reverserDirection

					if not g_soundManager:getIsSamplePlaying(samples.reverseDrive) and isReverseDriving then
						g_soundManager:playSample(samples.reverseDrive)
					elseif not isReverseDriving then
						g_soundManager:stopSample(samples.reverseDrive)
					end
				end
			end

			for state, gearLeverInterpolator in pairs(spec.activeGearLeverInterpolators) do
				local currentInterpolation = gearLeverInterpolator.interpolations[gearLeverInterpolator.currentInterpolation]

				if currentInterpolation ~= nil then
					if gearLeverInterpolator.handsOnDelay > 0 then
						gearLeverInterpolator.handsOnDelay = gearLeverInterpolator.handsOnDelay - dt

						if gearLeverInterpolator.handsOnDelay <= 0 then
							local sample = gearLeverInterpolator.isGear and spec.samples.gearLeverStart or spec.samples.gearGroupLeverStart

							if not g_soundManager:getIsSamplePlaying(sample) then
								g_soundManager:playSample(sample)
							end
						end

						if self.setCharacterTargetNodeStateDirty ~= nil then
							self:setCharacterTargetNodeStateDirty(state.node, true)
						end
					else
						state.curRotation[1], state.curRotation[2], state.curRotation[3] = getRotation(state.node)
						local limit = math.min

						if currentInterpolation.speed < 0 then
							limit = math.max
						end

						state.curRotation[currentInterpolation.axis] = limit(state.curRotation[currentInterpolation.axis] + currentInterpolation.speed * dt, currentInterpolation.tar)

						setRotation(state.node, state.curRotation[1], state.curRotation[2], state.curRotation[3])

						if state.curRotation[currentInterpolation.axis] == currentInterpolation.tar then
							gearLeverInterpolator.currentInterpolation = gearLeverInterpolator.currentInterpolation + 1

							if gearLeverInterpolator.currentInterpolation > #gearLeverInterpolator.interpolations then
								spec.activeGearLeverInterpolators[state] = nil

								if gearLeverInterpolator.isResetPosition and self.resetCharacterTargetNodeStateDefaults ~= nil then
									self:resetCharacterTargetNodeStateDefaults(state.node)
								end

								local sample = gearLeverInterpolator.isGear and spec.samples.gearLeverEnd or spec.samples.gearGroupLeverEnd

								if not g_soundManager:getIsSamplePlaying(sample) then
									g_soundManager:playSample(sample)
								end
							end
						end

						if self.setCharacterTargetNodeStateDirty ~= nil then
							self:setCharacterTargetNodeStateDirty(state.node)
						end
					end
				else
					spec.activeGearLeverInterpolators[state] = nil
				end
			end
		end

		if self.isServer and not self:getIsAIActive() and self:getTraveledDistanceStatsActive() and self.lastMovedDistance > 0.001 then
			spec.traveledDistanceBuffer = spec.traveledDistanceBuffer + self.lastMovedDistance

			if spec.traveledDistanceBuffer > 10 then
				local stats = g_currentMission:farmStats(self:getOwnerFarmId())
				local distance = spec.traveledDistanceBuffer * 0.001

				stats:updateStats("traveledDistance", distance)
				stats:updateStats(spec.statsTypeDistance, distance)

				spec.traveledDistanceBuffer = 0
			end
		end
	end
end

function Motorized:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_motorized

	if self.isServer then
		if not g_currentMission.missionInfo.automaticMotorStartEnabled and spec.isMotorStarted and not self:getIsAIActive() then
			local isEntered = self.getIsEntered ~= nil and self:getIsEntered()
			local isControlled = self.getIsControlled ~= nil and self:getIsControlled()

			if not isEntered and not isControlled then
				local isPlayerInRange = false

				for _, player in pairs(g_currentMission.players) do
					if player.isControlled then
						local distance = calcDistanceFrom(self.rootNode, player.rootNode)

						if distance < 250 then
							isPlayerInRange = true

							break
						end
					end
				end

				if not isPlayerInRange then
					for _, enterable in pairs(g_currentMission.enterables) do
						if enterable.spec_enterable ~= nil and enterable.spec_enterable.isControlled then
							local distance = calcDistanceFrom(self.rootNode, enterable.rootNode)

							if distance < 250 then
								isPlayerInRange = true

								break
							end
						end
					end
				end

				if isPlayerInRange then
					spec.motorStopTimer = spec.motorStopTimerDuration
				else
					spec.motorStopTimer = spec.motorStopTimer - dt

					if spec.motorStopTimer <= 0 then
						self:stopMotor()
					end
				end
			end
		end

		if spec.isMotorStarted then
			self:updateMotorTemperature(dt)
		elseif g_currentMission.missionInfo.automaticMotorStartEnabled and self.getIsControlled ~= nil and self:getIsControlled() and self:getCanMotorRun() then
			self:startMotor(true)
		end
	end

	if self.isClient then
		if self:getIsMotorStarted() then
			if spec.exhaustParticleSystems ~= nil then
				for _, ps in pairs(spec.exhaustParticleSystems) do
					local scale = MathUtil.lerp(spec.exhaustParticleSystems.minScale, spec.exhaustParticleSystems.maxScale, spec.motor:getEqualizedMotorRpm() / spec.motor:getMaxRpm())

					ParticleUtil.setEmitCountScale(spec.exhaustParticleSystems, scale)
					ParticleUtil.setParticleLifespan(ps, ps.originalLifespan * scale)
				end
			end

			if spec.exhaustFlap ~= nil then
				local minRandom = -0.1
				local maxRandom = 0.1
				local angle = MathUtil.lerp(minRandom, maxRandom, math.random()) + spec.exhaustFlap.maxRot * spec.motor:getEqualizedMotorRpm() / spec.motor:getMaxRpm()
				angle = MathUtil.clamp(angle, 0, spec.exhaustFlap.maxRot)

				if spec.exhaustFlap.rotationAxis == 1 then
					setRotation(spec.exhaustFlap.node, angle, 0, 0)
				elseif spec.exhaustFlap.rotationAxis == 2 then
					setRotation(spec.exhaustFlap.node, 0, angle, 0)
				else
					setRotation(spec.exhaustFlap.node, 0, 0, angle)
				end
			end

			if spec.exhaustEffects ~= nil then
				for _, effect in pairs(spec.exhaustEffects) do
					local posX, posY, posZ = localToWorld(effect.effectNode, 0, 0.5, 0)

					if effect.lastPosition == nil then
						effect.lastPosition = {
							posX,
							posY,
							posZ
						}
					end

					local vx = (posX - effect.lastPosition[1]) * 10
					local vy = (posY - effect.lastPosition[2]) * 10
					local vz = (posZ - effect.lastPosition[3]) * 10
					local ex, ey, ez = localToWorld(effect.effectNode, 0, 1, 0)
					vz = ez - vz
					vy = ey - vy + effect.upFactor
					vx = ex - vx
					local lx, ly, lz = worldToLocal(effect.effectNode, vx, vy, vz)
					local distance = MathUtil.vector2Length(lx, lz)
					lx, lz = MathUtil.vector2Normalize(lx, lz)
					ly = math.abs(math.max(ly, 0.01))
					local xFactor = math.atan(distance / ly) * (1.2 + 2 * ly)
					local yFactor = math.atan(distance / ly) * (1.2 + 2 * ly)
					local xRot = math.atan(lz / ly) * xFactor
					local zRot = -math.atan(lx / ly) * yFactor
					effect.xRot = effect.xRot * 0.95 + xRot * 0.05
					effect.zRot = effect.zRot * 0.95 + zRot * 0.05
					local rpmScale = spec.motor:getEqualizedMotorRpm() / spec.motor:getMaxRpm()
					local scale = MathUtil.lerp(effect.minRpmScale, effect.maxRpmScale, rpmScale)

					setShaderParameter(effect.effectNode, "param", effect.xRot, effect.zRot, 0, scale, false)

					local r = MathUtil.lerp(effect.minRpmColor[1], effect.maxRpmColor[1], rpmScale)
					local g = MathUtil.lerp(effect.minRpmColor[2], effect.maxRpmColor[2], rpmScale)
					local b = MathUtil.lerp(effect.minRpmColor[3], effect.maxRpmColor[3], rpmScale)
					local a = MathUtil.lerp(effect.minRpmColor[4], effect.maxRpmColor[4], rpmScale)

					setShaderParameter(effect.effectNode, "exhaustColor", r, g, b, a, false)

					effect.lastPosition[1] = posX
					effect.lastPosition[2] = posY
					effect.lastPosition[3] = posZ
				end
			end

			spec.lastFuelUsageDisplayTime = spec.lastFuelUsageDisplayTime + dt

			if spec.lastFuelUsageDisplayTime > 250 then
				spec.lastFuelUsageDisplayTime = 0
				spec.lastFuelUsageDisplay = spec.fuelUsageBuffer:getAverage()
			end

			spec.fuelUsageBuffer:add(spec.lastFuelUsage)
		end

		if spec.clutchCrackingTimeOut < g_time then
			if g_soundManager:getIsSamplePlaying(spec.samples.clutchCracking) then
				g_soundManager:stopSample(spec.samples.clutchCracking)
			end

			if spec.clutchCrackingGearIndex ~= nil then
				self:setGearLeversState(0, nil, 500)
			end

			if spec.clutchCrackingGroupIndex ~= nil then
				self:setGearLeversState(nil, 0, 500)
			end

			spec.clutchCrackingTimeOut = math.huge
		end

		if isActiveForInputIgnoreSelection then
			if g_currentMission.missionInfo.automaticMotorStartEnabled and not self:getCanMotorRun() then
				local warning = self:getMotorNotAllowedWarning()

				if warning ~= nil then
					g_currentMission:showBlinkingWarning(warning, 2000)
				end
			end

			Motorized.updateActionEvents(self)
		end
	end
end

function Motorized:loadDifferentials(xmlFile, configDifferentialIndex)
	local key, _ = ConfigurationUtil.getXMLConfigurationKey(xmlFile, configDifferentialIndex, "vehicle.motorized.differentialConfigurations.differentialConfiguration", "vehicle.motorized.differentials", "differentials")
	local spec = self.spec_motorized
	spec.differentials = {}

	if self.isServer and spec.motorizedNode ~= nil then
		xmlFile:iterate(key .. ".differentials.differential", function (_, differentialKey)
			local torqueRatio = xmlFile:getValue(differentialKey .. "#torqueRatio", 0.5)
			local maxSpeedRatio = xmlFile:getValue(differentialKey .. "#maxSpeedRatio", 1.3)
			local indices = {
				-1,
				-1
			}
			local indexIsWheel = {
				false,
				false
			}

			for j = 1, 2 do
				local wheelIndex = xmlFile:getValue(differentialKey .. string.format("#wheelIndex%d", j))

				if wheelIndex ~= nil then
					if self:getWheelFromWheelIndex(wheelIndex) ~= nil then
						indices[j] = wheelIndex
						indexIsWheel[j] = true
					else
						Logging.xmlWarning(self.xmlFile, "Unable to find wheelIndex '%d' for differential '%s' (Indices start at 1)", wheelIndex, differentialKey)
					end
				else
					local diffIndex = xmlFile:getValue(differentialKey .. string.format("#differentialIndex%d", j))

					if diffIndex ~= nil then
						indices[j] = diffIndex - 1
						indexIsWheel[j] = false

						if diffIndex == 0 then
							Logging.xmlWarning(self.xmlFile, "Unable to find differentialIndex '0' for differential '%s' (Indices start at 1)", differentialKey)
						end
					end
				end
			end

			if indices[1] ~= -1 and indices[2] ~= -1 then
				table.insert(spec.differentials, {
					torqueRatio = torqueRatio,
					maxSpeedRatio = maxSpeedRatio,
					diffIndex1 = indices[1],
					diffIndex1IsWheel = indexIsWheel[1],
					diffIndex2 = indices[2],
					diffIndex2IsWheel = indexIsWheel[2]
				})
			end
		end)

		if #spec.differentials == 0 then
			Logging.xmlWarning(self.xmlFile, "No differentials defined")
		end
	end
end

function Motorized:loadMotor(xmlFile, motorId)
	local key = nil
	key, motorId = ConfigurationUtil.getXMLConfigurationKey(xmlFile, motorId, "vehicle.motorized.motorConfigurations.motorConfiguration", "vehicle.motorized", "motor")
	local spec = self.spec_motorized
	local fallbackConfigKey = "vehicle.motorized.motorConfigurations.motorConfiguration(0)"
	spec.motorType = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#type", "vehicle", fallbackConfigKey)
	spec.motorStartAnimation = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#startAnimationName", "vehicle", fallbackConfigKey)
	spec.consumerConfigurationIndex = ConfigurationUtil.getConfigurationValue(xmlFile, key, "#consumerConfigurationIndex", "", 1, fallbackConfigKey)
	local wheelKey, _ = ConfigurationUtil.getXMLConfigurationKey(xmlFile, self.configurations.wheel, "vehicle.wheels.wheelConfigurations.wheelConfiguration", "vehicle.wheels", "wheels")

	ObjectChangeUtil.updateObjectChanges(xmlFile, "vehicle.motorized.motorConfigurations.motorConfiguration", motorId, self.components, self)

	local motorMinRpm = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#minRpm", 1000, fallbackConfigKey)
	local motorMaxRpm = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#maxRpm", 1800, fallbackConfigKey)
	local minSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#minSpeed", 1, fallbackConfigKey)
	local maxForwardSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#maxForwardSpeed", nil, fallbackConfigKey)
	local maxBackwardSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#maxBackwardSpeed", nil, fallbackConfigKey)

	if maxForwardSpeed ~= nil then
		maxForwardSpeed = maxForwardSpeed / 3.6
	end

	if maxBackwardSpeed ~= nil then
		maxBackwardSpeed = maxBackwardSpeed / 3.6
	end

	local maxWheelSpeed = ConfigurationUtil.getConfigurationValue(xmlFile, wheelKey, ".wheels", "#maxForwardSpeed", nil, )

	if maxWheelSpeed ~= nil then
		maxForwardSpeed = maxWheelSpeed / 3.6
	end

	local accelerationLimit = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#accelerationLimit", 2, fallbackConfigKey)
	local brakeForce = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#brakeForce", 10, fallbackConfigKey) * 2
	local lowBrakeForceScale = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#lowBrakeForceScale", 0.5, fallbackConfigKey)
	local lowBrakeForceSpeedLimit = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#lowBrakeForceSpeedLimit", 1, fallbackConfigKey) / 3600
	local torqueScale = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#torqueScale", 1, fallbackConfigKey)
	local ptoMotorRpmRatio = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#ptoMotorRpmRatio", 4, fallbackConfigKey)
	local transmissionKey = key .. ".transmission"

	if not xmlFile:hasProperty(transmissionKey) then
		transmissionKey = fallbackConfigKey .. ".transmission"
	end

	local minForwardGearRatio = xmlFile:getValue(transmissionKey .. "#minForwardGearRatio")
	local maxForwardGearRatio = xmlFile:getValue(transmissionKey .. "#maxForwardGearRatio")
	local minBackwardGearRatio = xmlFile:getValue(transmissionKey .. "#minBackwardGearRatio")
	local maxBackwardGearRatio = xmlFile:getValue(transmissionKey .. "#maxBackwardGearRatio")
	local gearChangeTime = xmlFile:getValue(transmissionKey .. "#gearChangeTime")
	local autoGearChangeTime = xmlFile:getValue(transmissionKey .. "#autoGearChangeTime")
	local axleRatio = xmlFile:getValue(transmissionKey .. "#axleRatio", 1)
	local startGearThreshold = xmlFile:getValue(transmissionKey .. "#startGearThreshold", VehicleMotor.GEAR_START_THRESHOLD)

	if maxForwardGearRatio == nil or minForwardGearRatio == nil then
		minForwardGearRatio, maxForwardGearRatio = nil
	else
		minForwardGearRatio = minForwardGearRatio * axleRatio
		maxForwardGearRatio = maxForwardGearRatio * axleRatio
	end

	if minBackwardGearRatio == nil or maxBackwardGearRatio == nil then
		minBackwardGearRatio, maxBackwardGearRatio = nil
	else
		minBackwardGearRatio = minBackwardGearRatio * axleRatio
		maxBackwardGearRatio = maxBackwardGearRatio * axleRatio
	end

	local forwardGears = nil

	if minForwardGearRatio == nil then
		forwardGears = self:loadGears(xmlFile, "forwardGear", transmissionKey, motorMaxRpm, axleRatio, 1)

		if forwardGears == nil then
			print("Warning: Missing forward gear ratios for motor in '" .. self.configFileName .. "'!")

			forwardGears = {
				{
					default = false,
					ratio = 1
				}
			}
		end
	end

	local backwardGears = nil

	if minBackwardGearRatio == nil then
		backwardGears = self:loadGears(xmlFile, "backwardGear", transmissionKey, motorMaxRpm, axleRatio, -1)
	end

	local gearGroups = self:loadGearGroups(xmlFile, transmissionKey .. ".groups", motorMaxRpm, axleRatio)
	local groupsType = xmlFile:getValue(transmissionKey .. ".groups#type", "default")
	local groupChangeTime = xmlFile:getValue(transmissionKey .. ".groups#changeTime", 0.5)
	local directionChangeUseGear = xmlFile:getValue(transmissionKey .. ".directionChange#useGear", false)
	local directionChangeGearIndex = xmlFile:getValue(transmissionKey .. ".directionChange#reverseGearIndex", 1)
	local directionChangeUseGroup = xmlFile:getValue(transmissionKey .. ".directionChange#useGroup", false)
	local directionChangeGroupIndex = xmlFile:getValue(transmissionKey .. ".directionChange#reverseGroupIndex", 1)
	local directionChangeTime = xmlFile:getValue(transmissionKey .. ".directionChange#changeTime", 0.5)
	local manualShiftGears = xmlFile:getValue(transmissionKey .. ".manualShift#gears", true)
	local manualShiftGroups = xmlFile:getValue(transmissionKey .. ".manualShift#groups", true)
	local torqueCurve = AnimCurve.new(linearInterpolator1)
	local torqueI = 0
	local torqueBase = fallbackConfigKey .. ".motor.torque"

	if key ~= nil and xmlFile:hasProperty(key .. ".motor.torque(0)") then
		torqueBase = key .. ".motor.torque"
	end

	while true do
		local torqueKey = string.format(torqueBase .. "(%d)", torqueI)
		local normRpm = xmlFile:getValue(torqueKey .. "#normRpm")
		local rpm = nil

		if normRpm == nil then
			rpm = xmlFile:getValue(torqueKey .. "#rpm")
		else
			rpm = normRpm * motorMaxRpm
		end

		local torque = xmlFile:getValue(torqueKey .. "#torque")

		if torque == nil or rpm == nil then
			break
		end

		torqueCurve:addKeyframe({
			torque * torqueScale,
			time = rpm
		})

		torqueI = torqueI + 1
	end

	spec.motor = VehicleMotor.new(self, motorMinRpm, motorMaxRpm, maxForwardSpeed, maxBackwardSpeed, torqueCurve, brakeForce, forwardGears, backwardGears, minForwardGearRatio, maxForwardGearRatio, minBackwardGearRatio, maxBackwardGearRatio, ptoMotorRpmRatio, minSpeed)

	spec.motor:setGearGroups(gearGroups, groupsType, groupChangeTime)
	spec.motor:setDirectionChange(directionChangeUseGear, directionChangeGearIndex, directionChangeUseGroup, directionChangeGroupIndex, directionChangeTime)
	spec.motor:setManualShift(manualShiftGears, manualShiftGroups)
	spec.motor:setStartGearThreshold(startGearThreshold)

	local rotInertia = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#rotInertia", spec.motor:getRotInertia(), fallbackConfigKey)
	local dampingRateScale = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#dampingRateScale", 1, fallbackConfigKey)

	spec.motor:setRotInertia(rotInertia)
	spec.motor:setDampingRateScale(dampingRateScale)
	spec.motor:setLowBrakeForce(lowBrakeForceScale, lowBrakeForceSpeedLimit)
	spec.motor:setAccelerationLimit(accelerationLimit)

	local motorRotationAccelerationLimit = ConfigurationUtil.getConfigurationValue(xmlFile, key, ".motor", "#rpmSpeedLimit", nil, fallbackConfigKey)

	if motorRotationAccelerationLimit ~= nil then
		motorRotationAccelerationLimit = motorRotationAccelerationLimit * math.pi / 30

		spec.motor:setMotorRotationAccelerationLimit(motorRotationAccelerationLimit)
	end

	if gearChangeTime ~= nil then
		spec.motor:setGearChangeTime(gearChangeTime)
	end

	if autoGearChangeTime ~= nil then
		spec.motor:setAutoGearChangeTime(autoGearChangeTime)
	end
end

function Motorized:loadGears(xmlFile, gearName, key, motorMaxRpm, axleRatio, direction)
	local gears = {}
	local gearI = 0

	while true do
		local gearKey = string.format(key .. ".%s(%d)", gearName, gearI)

		if not xmlFile:hasProperty(gearKey) then
			break
		end

		local gearRatio = xmlFile:getValue(gearKey .. "#gearRatio")
		local maxSpeed = xmlFile:getValue(gearKey .. "#maxSpeed")

		if maxSpeed ~= nil then
			gearRatio = motorMaxRpm * math.pi / (maxSpeed / 3.6 * 30)
		end

		if gearRatio ~= nil then
			local gearEntry = {
				ratio = gearRatio * axleRatio,
				default = xmlFile:getValue(gearKey .. "#defaultGear", false),
				name = xmlFile:getValue(gearKey .. "#name", tostring((gearI + 1) * direction)),
				reverseName = xmlFile:getValue(gearKey .. "#reverseName", tostring((gearI + 1) * direction * -1))
			}

			table.insert(gears, gearEntry)
		end

		gearI = gearI + 1
	end

	if #gears > 0 then
		return gears
	end
end

function Motorized:loadGearGroups(xmlFile, key, motorMaxRpm, axleRatio)
	local groups = {}
	local i = 0

	while true do
		local groupKey = string.format(key .. ".group(%d)", i)

		if not xmlFile:hasProperty(groupKey) then
			break
		end

		local ratio = xmlFile:getValue(groupKey .. "#ratio")

		if ratio ~= nil then
			local groupEntry = {
				ratio = 1 / ratio,
				isDefault = xmlFile:getValue(groupKey .. "#isDefault", false),
				name = xmlFile:getValue(groupKey .. "#name", tostring(i + 1))
			}

			table.insert(groups, groupEntry)
		end

		i = i + 1
	end

	if #groups > 0 then
		return groups
	end
end

function Motorized:loadExhaustEffects(xmlFile)
	local spec = self.spec_motorized
	local minScale = xmlFile:getValue("vehicle.motorized.exhaustParticleSystems#minScale", 0.5)
	local maxScale = xmlFile:getValue("vehicle.motorized.exhaustParticleSystems#maxScale", 1)
	spec.exhaustParticleSystems = {}
	local i = 0

	while true do
		local baseKey = string.format("vehicle.motorized.exhaustParticleSystems.exhaustParticleSystem(%d)", i)

		if not xmlFile:hasProperty(baseKey) then
			break
		end

		local particleSystem = {}

		ParticleUtil.loadParticleSystem(xmlFile, particleSystem, baseKey, self.components, false, nil, self.baseDirectory)

		particleSystem.minScale = minScale
		particleSystem.maxScale = maxScale

		table.insert(spec.exhaustParticleSystems, particleSystem)

		i = i + 1
	end

	if #spec.exhaustParticleSystems == 0 then
		spec.exhaustParticleSystems = nil
	end

	XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, "vehicle.motorized.exhaustFlap#index", "vehicle.motorized.exhaustFlap#node")

	local exhaustFlapNode = xmlFile:getValue("vehicle.motorized.exhaustFlap#node", nil, self.components, self.i3dMappings)

	if exhaustFlapNode ~= nil then
		spec.exhaustFlap = {
			node = exhaustFlapNode,
			maxRot = xmlFile:getValue("vehicle.motorized.exhaustFlap#maxRot", 0),
			rotationAxis = xmlFile:getValue("vehicle.motorized.exhaustFlap#rotationAxis", 1)
		}
	end

	spec.exhaustEffects = {}
	spec.sharedLoadRequestIds = {}

	xmlFile:iterate("vehicle.motorized.exhaustEffects.exhaustEffect", function (index, key)
		XMLUtil.checkDeprecatedXMLElements(xmlFile, self.configFileName, key .. "#index", key .. "#node")

		local linkNode = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
		local filename = xmlFile:getValue(key .. "#filename")

		if filename ~= nil and linkNode ~= nil then
			filename = Utils.getFilename(filename, self.baseDirectory)
			local sharedLoadRequestId = self:loadSubSharedI3DFile(filename, false, false, self.onExhaustEffectI3DLoaded, self, {
				xmlFile,
				key,
				linkNode,
				filename
			})

			table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
		end
	end)

	spec.exhaustEffectMaxSteeringSpeed = 0.001
end

function Motorized:onExhaustEffectI3DLoaded(i3dNode, failedReason, args)
	local spec = self.spec_motorized
	local xmlFile, key, linkNode, filename = unpack(args)

	if i3dNode ~= 0 then
		local node = getChildAt(i3dNode, 0)

		if getHasShaderParameter(node, "param") then
			local effect = {
				effectNode = node,
				node = linkNode,
				filename = filename
			}

			link(effect.node, effect.effectNode)
			setVisibility(effect.effectNode, false)
			delete(i3dNode)

			effect.minRpmColor = xmlFile:getValue(key .. "#minRpmColor", "0 0 0 1", true)
			effect.maxRpmColor = xmlFile:getValue(key .. "#maxRpmColor", "0.0384 0.0359 0.0627 2.0", true)
			effect.minRpmScale = xmlFile:getValue(key .. "#minRpmScale", 0.25)
			effect.maxRpmScale = xmlFile:getValue(key .. "#maxRpmScale", 0.95)
			effect.upFactor = xmlFile:getValue(key .. "#upFactor", 0.75)
			effect.lastPosition = nil
			effect.xRot = 0
			effect.zRot = 0

			table.insert(spec.exhaustEffects, effect)
		end
	end
end

function Motorized:loadSounds(xmlFile, baseString)
	if self.isClient then
		local spec = self.spec_motorized
		spec.samples = spec.samples or {}
		spec.samples.motorStart = g_soundManager:loadSampleFromXML(xmlFile, baseString, "motorStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.motorStart
		spec.samples.motorStop = g_soundManager:loadSampleFromXML(xmlFile, baseString, "motorStop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.motorStop
		spec.samples.gearbox = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearbox", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearbox
		spec.samples.clutchCracking = g_soundManager:loadSampleFromXML(xmlFile, baseString, "clutchCracking", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.clutchCracking
		spec.samples.gearEngaged = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearEngaged", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearEngaged
		spec.samples.gearDisengaged = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearDisengaged", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearDisengaged
		spec.samples.gearGroupChange = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearGroupChange", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearGroupChange
		spec.samples.gearLeverStart = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearLeverStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearLeverStart
		spec.samples.gearLeverEnd = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearLeverEnd", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearLeverEnd
		spec.samples.gearGroupLeverStart = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearGroupLeverStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearGroupLeverStart
		spec.samples.gearGroupLeverEnd = g_soundManager:loadSampleFromXML(xmlFile, baseString, "gearGroupLeverEnd", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.gearGroupLeverEnd
		spec.samples.blowOffValve = g_soundManager:loadSampleFromXML(xmlFile, baseString, "blowOffValve", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.blowOffValve
		spec.samples.retarder = g_soundManager:loadSampleFromXML(xmlFile, baseString, "retarder", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.retarder
		spec.motorSamples = g_soundManager:loadSamplesFromXML(xmlFile, baseString, "motor", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self, spec.motorSamples)
		spec.samples.airCompressorStart = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airCompressorStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.airCompressorStart
		spec.samples.airCompressorStop = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airCompressorStop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.airCompressorStop
		spec.samples.airCompressorRun = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airCompressorRun", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.airCompressorRun
		spec.samples.compressedAir = g_soundManager:loadSampleFromXML(xmlFile, baseString, "compressedAir", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.compressedAir

		if spec.samples.compressedAir ~= nil then
			spec.samples.compressedAir.brakeTime = 0
			spec.samples.compressedAir.lastBrakeTime = 0
		end

		spec.samples.airRelease = g_soundManager:loadSampleFromXML(xmlFile, baseString, "airRelease", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.airRelease
		spec.samples.reverseDrive = g_soundManager:loadSampleFromXML(xmlFile, baseString, "reverseDrive", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.reverseDrive
		spec.reverseDriveThreshold = xmlFile:getValue("vehicle.motorized.reverseDriveSound#threshold", 4)
		spec.brakeCompressor = {
			capacity = xmlFile:getValue("vehicle.motorized.brakeCompressor#capacity", 6)
		}
		spec.brakeCompressor.refillFilllevel = math.min(spec.brakeCompressor.capacity, xmlFile:getValue("vehicle.motorized.brakeCompressor#refillFillLevel", spec.brakeCompressor.capacity / 2))
		spec.brakeCompressor.fillSpeed = xmlFile:getValue("vehicle.motorized.brakeCompressor#fillSpeed", 0.6) / 1000
		spec.brakeCompressor.fillLevel = 0
		spec.brakeCompressor.doFill = true
		spec.isBrakeSamplePlaying = false
		spec.samples.brake = g_soundManager:loadSampleFromXML(xmlFile, baseString, "brake", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self) or spec.samples.brake
		spec.compressionSoundTime = 0
	end
end

function Motorized:loadConsumerConfiguration(xmlFile, consumerIndex)
	local key = string.format("vehicle.motorized.consumerConfigurations.consumerConfiguration(%d)", consumerIndex - 1)
	local spec = self.spec_motorized
	local fallbackConfigKey = "vehicle.motorized.consumers"
	spec.consumersEmptyWarning = self.xmlFile:getValue(key .. "#consumersEmptyWarning", "warning_motorFuelEmpty", self.customEnvironment)
	spec.consumers = {}
	spec.consumersByFillTypeName = {}
	spec.consumersByFillType = {}

	if not xmlFile:hasProperty(key) then
		return
	end

	local i = 0

	while true do
		local consumerKey = string.format(".consumer(%d)", i)

		if not xmlFile:hasProperty(key .. consumerKey) then
			break
		end

		local consumer = {
			fillUnitIndex = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#fillUnitIndex", 1, fallbackConfigKey)
		}
		local fillTypeName = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#fillType", "consumer", fallbackConfigKey)
		consumer.fillType = g_fillTypeManager:getFillTypeIndexByName(fillTypeName)
		consumer.capacity = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#capacity", nil, fallbackConfigKey)
		local fillUnit = self:getFillUnitByIndex(consumer.fillUnitIndex)

		if fillUnit ~= nil then
			if fillUnit.supportedFillTypes[consumer.fillType] ~= nil then
				fillUnit.capacity = consumer.capacity or fillUnit.capacity
				fillUnit.startFillLevel = fillUnit.capacity
				fillUnit.startFillTypeIndex = consumer.fillType
				local usage = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#usage", 1, fallbackConfigKey)
				consumer.permanentConsumption = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#permanentConsumption", true, fallbackConfigKey)

				if consumer.permanentConsumption then
					consumer.usage = usage / 3600000
				else
					consumer.usage = usage
				end

				consumer.refillLitersPerSecond = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#refillLitersPerSecond", 0, fallbackConfigKey)
				consumer.refillCapacityPercentage = ConfigurationUtil.getConfigurationValue(xmlFile, key, consumerKey, "#refillCapacityPercentage", 0, fallbackConfigKey)
				consumer.fillLevelToChange = 0

				table.insert(spec.consumers, consumer)

				spec.consumersByFillTypeName[fillTypeName:upper()] = consumer
				spec.consumersByFillType[consumer.fillType] = consumer
			else
				Logging.xmlWarning(self.xmlFile, "FillUnit '%d' does not  support fillType '%s' for consumer '%s'", consumer.fillUnitIndex, fillTypeName, key .. consumerKey)
			end
		else
			Logging.xmlWarning(self.xmlFile, "Unknown fillUnit '%d' for consumer '%s'", consumer.fillUnitIndex, key .. consumerKey)
		end

		i = i + 1
	end
end

function Motorized:getIsMotorStarted(isRunning)
	return self.spec_motorized.isMotorStarted and (not isRunning or self.spec_motorized.motorStartTime < g_currentMission.time)
end

function Motorized:getIsMotorInNeutral()
	return self.spec_motorized.motor:getIsInNeutral()
end

function Motorized:getMotorIgnitionState()
	return self.spec_motorized.isMotorStarted and (g_currentMission.time < self.spec_motorized.motorStartTime and 1 or 2) or 0
end

function Motorized:getCanMotorRun()
	local spec = self.spec_motorized

	for _, fillUnitIndex in ipairs(spec.propellantFillUnitIndices) do
		if self:getFillUnitFillLevel(fillUnitIndex) == 0 then
			return false
		end
	end

	if not spec.motor:getCanMotorRun() then
		return false
	end

	return true
end

function Motorized:getStopMotorOnLeave()
	if GS_IS_MOBILE_VERSION and self.rootVehicle:getActionControllerDirection() == -1 then
		return false
	end

	return self.spec_motorized.stopMotorOnLeave
end

function Motorized:getMotorNotAllowedWarning()
	local spec = self.spec_motorized

	for _, fillUnit in pairs(spec.propellantFillUnitIndices) do
		if self:getFillUnitFillLevel(fillUnit) == 0 then
			return spec.consumersEmptyWarning
		end
	end

	local canMotorRun, reason = spec.motor:getCanMotorRun()

	if not canMotorRun and reason == VehicleMotor.REASON_CLUTCH_NOT_ENGAGED then
		return spec.clutchNoEngagedWarning
	end

	return nil
end

function Motorized:startMotor(noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetMotorTurnedOnEvent.new(self, true), nil, , self)
		else
			g_client:getServerConnection():sendEvent(SetMotorTurnedOnEvent.new(self, true))
		end
	end

	local spec = self.spec_motorized

	if not spec.isMotorStarted then
		spec.isMotorStarted = true

		if self.isClient then
			if spec.exhaustParticleSystems ~= nil then
				for _, ps in pairs(spec.exhaustParticleSystems) do
					ParticleUtil.setEmittingState(ps, true)
				end
			end

			if spec.exhaustEffects ~= nil then
				for _, effect in pairs(spec.exhaustEffects) do
					setVisibility(effect.effectNode, true)
					setShaderParameter(effect.effectNode, "param", effect.xRot, effect.zRot, 0, 0, false)

					local color = effect.minRpmColor

					setShaderParameter(effect.effectNode, "exhaustColor", color[1], color[2], color[3], color[4], false)
				end
			end

			if spec.samples == nil then
				Logging.error("Motor samples not found (%s, %d)", self.configFileName, self.loadingState)
				printCallstack()
			end

			g_soundManager:stopSample(spec.samples.motorStop)
			g_soundManager:playSample(spec.samples.motorStart)
			g_soundManager:playSamples(spec.motorSamples, 0, spec.samples.motorStart)
			g_soundManager:playSample(spec.samples.gearbox, 0, spec.samples.motorStart)
			g_soundManager:playSample(spec.samples.retarder, 0, spec.samples.motorStart)
			g_animationManager:startAnimations(spec.animationNodes)

			if spec.motorStartAnimation ~= nil then
				self:playAnimation(spec.motorStartAnimation, 1, nil, true)
			end
		end

		spec.motorStartTime = g_currentMission.time + spec.motorStartDuration
		spec.compressionSoundTime = g_currentMission.time + math.random(5000, 20000)
		spec.motor.lastMotorRpm = 0

		SpecializationUtil.raiseEvent(self, "onStartMotor")
		self.rootVehicle:raiseStateChange(Vehicle.STATE_CHANGE_MOTOR_TURN_ON)
	end

	if self.setDashboardsDirty ~= nil then
		self:setDashboardsDirty()
	end

	if self.isServer then
		self:wakeUp()
	end
end

function Motorized:stopMotor(noEventSend)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(SetMotorTurnedOnEvent.new(self, false), nil, , self)
		else
			g_client:getServerConnection():sendEvent(SetMotorTurnedOnEvent.new(self, false))
		end
	end

	local spec = self.spec_motorized

	if spec.isMotorStarted then
		spec.isMotorStarted = false

		if self.isClient then
			if spec.exhaustParticleSystems ~= nil then
				for _, ps in pairs(spec.exhaustParticleSystems) do
					ParticleUtil.setEmittingState(ps, false)
				end
			end

			if spec.exhaustEffects ~= nil then
				for _, effect in pairs(spec.exhaustEffects) do
					setVisibility(effect.effectNode, false)
				end
			end

			if spec.exhaustFlap ~= nil then
				setRotation(spec.exhaustFlap.node, 0, 0, 0)
			end

			g_soundManager:stopSamples(spec.samples)
			g_soundManager:playSample(spec.samples.motorStop)
			g_soundManager:stopSamples(spec.motorSamples)

			spec.isBrakeSamplePlaying = false

			g_animationManager:stopAnimations(spec.animationNodes)

			if spec.motorStartAnimation ~= nil then
				self:playAnimation(spec.motorStartAnimation, -1, nil, true)
			end
		end

		SpecializationUtil.raiseEvent(self, "onStopMotor")
		self.rootVehicle:raiseStateChange(Vehicle.STATE_CHANGE_MOTOR_TURN_OFF)
	end

	spec.motor.lastMotorRpm = 0

	if self.setDashboardsDirty ~= nil then
		self:setDashboardsDirty()
	end
end

function Motorized:updateConsumers(dt, accInput)
	local spec = self.spec_motorized
	local idleFactor = 0.5
	local rpmPercentage = (spec.motor.lastMotorRpm - spec.motor.minRpm) / (spec.motor.maxRpm - spec.motor.minRpm)
	local rpmFactor = idleFactor + rpmPercentage * (1 - idleFactor)
	local loadFactor = math.max(spec.smoothedLoadPercentage * rpmPercentage, 0)
	local motorFactor = 0.5 * (0.2 * rpmFactor + 1.8 * loadFactor)
	local usageFactor = 1

	if g_currentMission.missionInfo.fuelUsageLow then
		usageFactor = 0.7
	end

	local damage = self:getVehicleDamage()

	if damage > 0 then
		usageFactor = usageFactor * (1 + damage * Motorized.DAMAGED_USAGE_INCREASE)
	end

	for _, consumer in pairs(spec.consumers) do
		if consumer.permanentConsumption and consumer.usage > 0 then
			local used = usageFactor * motorFactor * consumer.usage * dt

			if used ~= 0 then
				consumer.fillLevelToChange = consumer.fillLevelToChange + used

				if math.abs(consumer.fillLevelToChange) > 1 then
					used = consumer.fillLevelToChange
					consumer.fillLevelToChange = 0
					local fillType = self:getFillUnitLastValidFillType(consumer.fillUnitIndex)
					local stats = g_currentMission:farmStats(self:getOwnerFarmId())

					stats:updateStats("fuelUsage", used)

					if self:getIsAIActive() and (fillType == FillType.DIESEL or fillType == FillType.DEF) and g_currentMission.missionInfo.helperBuyFuel then
						if fillType == FillType.DIESEL then
							local price = used * g_currentMission.economyManager:getCostPerLiter(fillType) * 1.5

							stats:updateStats("expenses", price)
							g_currentMission:addMoney(-price, self:getOwnerFarmId(), MoneyType.PURCHASE_FUEL, true)
						end

						used = 0
					end

					if fillType == consumer.fillType then
						self:addFillUnitFillLevel(self:getOwnerFarmId(), consumer.fillUnitIndex, -used, fillType, ToolType.UNDEFINED)
					end
				end

				if consumer.fillType == FillType.DIESEL or consumer.fillType == FillType.ELECTRICCHARGE or consumer.fillType == FillType.METHANE then
					spec.lastFuelUsage = used / dt * 1000 * 60 * 60
				elseif consumer.fillType == FillType.DEF then
					spec.lastDefUsage = used / dt * 1000 * 60 * 60
				end
			end
		end
	end

	if spec.consumersByFillTypeName.AIR ~= nil then
		local consumer = spec.consumersByFillTypeName.AIR
		local fillType = self:getFillUnitLastValidFillType(consumer.fillUnitIndex)

		if fillType == consumer.fillType then
			local usage = 0
			local direction = self.movingDirection * self:getReverserDirection()
			local forwardBrake = direction > 0 and accInput < 0
			local backwardBrake = direction < 0 and accInput > 0
			local brakeIsPressed = self:getLastSpeed() > 1 and (forwardBrake or backwardBrake)

			if brakeIsPressed then
				local delta = math.abs(accInput) * dt * self:getAirConsumerUsage() / 1000

				self:addFillUnitFillLevel(self:getOwnerFarmId(), consumer.fillUnitIndex, -delta, consumer.fillType, ToolType.UNDEFINED)

				usage = delta / dt * 1000
			end

			local fillLevelPercentage = self:getFillUnitFillLevelPercentage(consumer.fillUnitIndex)

			if fillLevelPercentage < consumer.refillCapacityPercentage then
				consumer.doRefill = true
			elseif fillLevelPercentage == 1 then
				consumer.doRefill = false
			end

			if consumer.doRefill then
				local delta = consumer.refillLitersPerSecond / 1000 * dt

				self:addFillUnitFillLevel(self:getOwnerFarmId(), consumer.fillUnitIndex, delta, consumer.fillType, ToolType.UNDEFINED)

				usage = -delta / dt * 1000
			end

			spec.lastAirUsage = usage
		end
	end
end

function Motorized:updateMotorTemperature(dt)
	local spec = self.spec_motorized
	local delta = spec.motorTemperature.heatingPerMS * dt
	local factor = (1 + 4 * spec.actualLoadPercentage) / 5
	delta = delta * (factor + self:getMotorRpmPercentage())
	spec.motorTemperature.value = math.min(spec.motorTemperature.valueMax, spec.motorTemperature.value + delta)
	delta = spec.motorTemperature.coolingByWindPerMS * dt
	local speedFactor = math.pow(math.min(1, self:getLastSpeed() / 30), 2)
	spec.motorTemperature.value = math.max(spec.motorTemperature.valueMin, spec.motorTemperature.value - speedFactor * delta)

	if spec.motorFan.enableTemperature < spec.motorTemperature.value then
		spec.motorFan.enabled = true
	end

	if spec.motorFan.enabled and spec.motorTemperature.value < spec.motorFan.disableTemperature then
		spec.motorFan.enabled = false
	end

	if spec.motorFan.enabled then
		delta = spec.motorFan.coolingPerMS * dt
		spec.motorTemperature.value = math.max(spec.motorTemperature.valueMin, spec.motorTemperature.value - delta)
	end
end

function Motorized:onGearDirectionChanged(direction)
	if self.isServer then
		self:raiseDirtyFlags(self.spec_motorized.dirtyFlag)
	end
end

function Motorized:onGearChanged(gear, targetGear, changeTime)
	self:setGearLeversState(targetGear, nil, changeTime)

	local spec = self.spec_motorized

	if self.isClient then
		if gear == 0 then
			if not g_soundManager:getIsSamplePlaying(spec.samples.gearDisengaged) then
				g_soundManager:playSample(spec.samples.gearDisengaged)
			end
		elseif not g_soundManager:getIsSamplePlaying(spec.samples.gearEngaged) then
			g_soundManager:playSample(spec.samples.gearEngaged)
		end
	end

	if self.isServer then
		self:raiseDirtyFlags(spec.dirtyFlag)
	end
end

function Motorized:onGearGroupChanged(targetGroup, changeTime)
	self:setGearLeversState(nil, targetGroup, changeTime)

	local spec = self.spec_motorized

	if self.isClient and not g_soundManager:getIsSamplePlaying(spec.samples.gearGroupChange) then
		g_soundManager:playSample(spec.samples.gearGroupChange)
	end

	if self.isServer then
		self:raiseDirtyFlags(spec.dirtyFlag)
	end
end

function Motorized:onClutchCreaking(isEvent, groupTransmission, gearIndex, groupIndex)
	local spec = self.spec_motorized

	if groupTransmission then
		g_currentMission:showBlinkingWarning(spec.clutchCrackingGroupWarning, 2000)
	else
		g_currentMission:showBlinkingWarning(spec.clutchCrackingGearWarning, 2000)
	end

	if not g_soundManager:getIsSamplePlaying(spec.samples.clutchCracking) then
		g_soundManager:playSample(spec.samples.clutchCracking)
	end

	if gearIndex ~= nil then
		self:setGearLeversState(gearIndex, nil, 500, false)

		spec.clutchCrackingGearIndex = gearIndex
	end

	if groupIndex ~= nil then
		self:setGearLeversState(nil, groupIndex, 500, false)

		spec.clutchCrackingGroupIndex = groupIndex
	end

	spec.clutchCrackingTimeOut = g_time + (isEvent and 750 or 100)
end

function Motorized:onVehicleSettingChanged(gameSettingId, state)
	local spec = self.spec_motorized
	local motor = spec.motor

	if gameSettingId == GameSettings.SETTING.DIRECTION_CHANGE_MODE then
		spec.directionChangeMode = state

		if motor ~= nil then
			motor:setDirectionChangeMode(state)
			self:requestActionEventUpdate()
		end
	end

	if gameSettingId == GameSettings.SETTING.GEAR_SHIFT_MODE then
		spec.gearShiftMode = state

		if not self:getIsAIActive() and motor ~= nil then
			motor:setGearShiftMode(state)
			self:requestActionEventUpdate()
		end
	end
end

function Motorized:onAIJobStarted(job)
	local spec = self.spec_motorized

	self:startMotor(true)

	if spec.motor ~= nil then
		spec.motor:setGearShiftMode(VehicleMotor.SHIFT_MODE_AUTOMATIC)
	end
end

function Motorized:onAIJobFinished(job)
	if self.getIsControlled == nil or not self:getIsControlled() then
		self:stopMotor(true)
	end

	local spec = self.spec_motorized

	if spec.motor ~= nil then
		spec.motor:setGearShiftMode(spec.gearShiftMode)
	end
end

function Motorized:getMotor()
	return self.spec_motorized.motor
end

function Motorized:getMotorStartTime()
	return self.spec_motorized.motorStartTime
end

function Motorized:getMotorType()
	return self.spec_motorized.motorType
end

function Motorized:getMotorRpmPercentage()
	local motor = self.spec_motorized.motor

	return (motor:getLastModulatedMotorRpm() - motor:getMinRpm()) / (motor:getMaxRpm() - motor:getMinRpm())
end

g_soundManager:registerModifierType("MOTOR_RPM", Motorized.getMotorRpmPercentage)

function Motorized:getMotorRpmReal()
	return self.spec_motorized.motor:getLastModulatedMotorRpm()
end

g_soundManager:registerModifierType("MOTOR_RPM_REAL", Motorized.getMotorRpmReal)

function Motorized:getMotorLoadPercentage()
	return self.spec_motorized.smoothedLoadPercentage
end

g_soundManager:registerModifierType("MOTOR_LOAD", Motorized.getMotorLoadPercentage)

function Motorized:getMotorBrakeTime()
	local sample = self.spec_motorized.samples.compressedAir

	if sample ~= nil then
		return sample.lastBrakeTime / 1000
	end

	return 0
end

g_soundManager:registerModifierType("BRAKE_TIME", Motorized.getMotorBrakeTime)

function Motorized:getMotorBlowOffValveState()
	return self.spec_motorized.motor.blowOffValveState
end

g_soundManager:registerModifierType("BLOW_OFF_VALVE_STATE", Motorized.getMotorBlowOffValveState)

function Motorized:getConsumerFillUnitIndex(fillTypeIndex)
	local spec = self.spec_motorized
	local consumer = spec.consumersByFillType[fillTypeIndex]

	if consumer ~= nil then
		return consumer.fillUnitIndex
	end

	return nil
end

function Motorized:getAirConsumerUsage()
	local spec = self.spec_motorized
	local consumer = spec.consumersByFillTypeName.AIR

	return consumer and consumer.usage or 0
end

function Motorized:getBrakeForce(superFunc)
	local brakeForce = superFunc(self)

	return math.max(brakeForce, self.spec_motorized.motor:getBrakeForce())
end

function Motorized:loadDashboardGroupFromXML(superFunc, xmlFile, key, group)
	if not superFunc(self, xmlFile, key, group) then
		return false
	end

	group.isMotorStarting = xmlFile:getValue(key .. "#isMotorStarting")
	group.isMotorRunning = xmlFile:getValue(key .. "#isMotorRunning")

	return true
end

function Motorized:getIsDashboardGroupActive(superFunc, group)
	local spec = self.spec_motorized

	if group.isMotorRunning and group.isMotorStarting and not spec.isMotorStarted then
		return false
	end

	if group.isMotorStarting and not group.isMotorRunning and (not spec.isMotorStarted or spec.motorStartTime < g_currentMission.time) then
		return false
	end

	if group.isMotorRunning and not group.isMotorStarting and (not spec.isMotorStarted or g_currentMission.time < spec.motorStartTime) then
		return false
	end

	return superFunc(self, group)
end

function Motorized:getIsActiveForInteriorLights(superFunc)
	if self.spec_motorized.isMotorStarted then
		return true
	end

	return superFunc(self)
end

function Motorized:getIsActiveForWipers(superFunc)
	if not self.spec_motorized.isMotorStarted then
		return false
	end

	return superFunc(self)
end

function Motorized:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end

	if self.isServer then
		local spec = self.spec_motorized

		if spec.motorizedNode ~= nil and next(spec.differentials) ~= nil then
			for _, differential in pairs(spec.differentials) do
				local diffIndex1 = differential.diffIndex1
				local diffIndex2 = differential.diffIndex2

				if differential.diffIndex1IsWheel then
					diffIndex1 = self:getWheelFromWheelIndex(diffIndex1).wheelShape
				end

				if differential.diffIndex2IsWheel then
					diffIndex2 = self:getWheelFromWheelIndex(diffIndex2).wheelShape
				end

				addDifferential(spec.motorizedNode, diffIndex1, differential.diffIndex1IsWheel, diffIndex2, differential.diffIndex2IsWheel, differential.torqueRatio, differential.maxSpeedRatio)
			end

			self:updateMotorProperties()
			self:controlVehicle(0, 0, 0, 0, math.huge, 0, 0, 0, 0, 0)
		end
	end

	return true
end

function Motorized:removeFromPhysics(superFunc)
	if self.isServer then
		local spec = self.spec_motorized

		if spec.motorizedNode ~= nil and next(spec.differentials) ~= nil then
			removeAllDifferentials(spec.motorizedNode)
		end
	end

	if not superFunc(self) then
		return false
	end

	return true
end

function Motorized:updateMotorProperties()
	local spec = self.spec_motorized
	local motor = spec.motor
	local torques, rotationSpeeds = motor:getTorqueAndSpeedValues()

	setMotorProperties(spec.motorizedNode, motor:getMinRpm() * math.pi / 30, motor:getMaxRpm() * math.pi / 30, motor:getRotInertia(), motor:getDampingRateFullThrottle(), motor:getDampingRateZeroThrottleClutchEngaged(), motor:getDampingRateZeroThrottleClutchDisengaged(), rotationSpeeds, torques)
end

function Motorized:controlVehicle(acceleratorPedal, maxSpeed, maxAcceleration, minMotorRotSpeed, maxMotorRotSpeed, maxMotorRotAcceleration, minGearRatio, maxGearRatio, maxClutchTorque, neededPtoTorque)
	local spec = self.spec_motorized

	controlVehicle(spec.motorizedNode, acceleratorPedal, maxSpeed, maxAcceleration, minMotorRotSpeed, maxMotorRotSpeed, maxMotorRotAcceleration, minGearRatio, maxGearRatio, maxClutchTorque, neededPtoTorque)

	local lastParameters = spec.lastControlParameters

	if getIsSleeping(spec.motorizedNode) and (acceleratorPedal ~= lastParameters.acceleratorPedal or maxSpeed ~= lastParameters.maxSpeed or maxAcceleration ~= lastParameters.maxAcceleration or minMotorRotSpeed ~= lastParameters.minMotorRotSpeed or maxMotorRotSpeed ~= lastParameters.maxMotorRotSpeed or maxMotorRotAcceleration ~= lastParameters.maxMotorRotAcceleration or minGearRatio ~= lastParameters.minGearRatio or maxGearRatio ~= lastParameters.maxGearRatio or maxClutchTorque ~= lastParameters.maxClutchTorque or neededPtoTorque ~= lastParameters.neededPtoTorque) then
		I3DUtil.wakeUpObject(spec.motorizedNode)
	end

	lastParameters.acceleratorPedal = acceleratorPedal
	lastParameters.maxSpeed = maxSpeed
	lastParameters.maxAcceleration = maxAcceleration
	lastParameters.minMotorRotSpeed = minMotorRotSpeed
	lastParameters.maxMotorRotSpeed = maxMotorRotSpeed
	lastParameters.maxMotorRotAcceleration = maxMotorRotAcceleration
	lastParameters.minGearRatio = minGearRatio
	lastParameters.maxGearRatio = maxGearRatio
	lastParameters.maxClutchTorque = maxClutchTorque
	lastParameters.neededPtoTorque = neededPtoTorque
end

function Motorized:getIsOperating(superFunc)
	return superFunc(self) or self:getIsMotorStarted()
end

function Motorized:getDeactivateOnLeave(superFunc)
	return superFunc(self) and g_currentMission.missionInfo.automaticMotorStartEnabled
end

function Motorized:getDeactivateLightsOnLeave(superFunc)
	return superFunc(self) and g_currentMission.missionInfo.automaticMotorStartEnabled
end

function Motorized:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_motorized

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_MOTOR_STATE, self, Motorized.actionEventToggleMotorState, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
			g_inputBinding:setActionEventText(actionEventId, spec.turnOnText)

			if (spec.motor.minForwardGearRatio == nil or spec.motor.minBackwardGearRatio == nil) and (self:getGearShiftMode() ~= VehicleMotor.SHIFT_MODE_AUTOMATIC or not GS_IS_CONSOLE_VERSION) then
				if spec.motor.manualShiftGears then
					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_UP, self, Motorized.actionEventShiftGear, false, true, false, true, nil)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)

					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_DOWN, self, Motorized.actionEventShiftGear, false, true, false, true, nil)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)

					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_1, self, Motorized.actionEventSelectGear, true, true, true, true, 1)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)

					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_2, self, Motorized.actionEventSelectGear, true, true, true, true, 2)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)

					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_3, self, Motorized.actionEventSelectGear, true, true, true, true, 3)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)

					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_4, self, Motorized.actionEventSelectGear, true, true, true, true, 4)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)

					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_5, self, Motorized.actionEventSelectGear, true, true, true, true, 5)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)

					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_6, self, Motorized.actionEventSelectGear, true, true, true, true, 6)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)

					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_7, self, Motorized.actionEventSelectGear, true, true, true, true, 7)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)

					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GEAR_SELECT_8, self, Motorized.actionEventSelectGear, true, true, true, true, 8)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)
				end

				if spec.motor.manualShiftGroups and spec.motor.gearGroups ~= nil then
					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_UP, self, Motorized.actionEventShiftGroup, false, true, false, true, nil)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)

					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_DOWN, self, Motorized.actionEventShiftGroup, false, true, false, true, nil)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)

					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_SELECT_1, self, Motorized.actionEventSelectGroup, true, true, true, true, 1)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)

					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_SELECT_2, self, Motorized.actionEventSelectGroup, true, true, true, true, 2)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)

					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_SELECT_3, self, Motorized.actionEventSelectGroup, true, true, true, true, 3)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)

					_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.SHIFT_GROUP_SELECT_4, self, Motorized.actionEventSelectGroup, true, true, true, true, 4)

					g_inputBinding:setActionEventTextVisibility(actionEventId, false)
				end

				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.AXIS_CLUTCH_VEHICLE, self, Motorized.actionEventClutch, false, false, true, true, nil)

				g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			end

			if self:getDirectionChangeMode() == VehicleMotor.DIRECTION_CHANGE_MODE_MANUAL or self:getGearShiftMode() ~= VehicleMotor.SHIFT_MODE_AUTOMATIC then
				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.DIRECTION_CHANGE, self, Motorized.actionEventDirectionChange, false, true, false, true, nil, , true)

				g_inputBinding:setActionEventTextVisibility(actionEventId, false)

				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.DIRECTION_CHANGE_POS, self, Motorized.actionEventDirectionChange, false, true, false, true, nil, , true)

				g_inputBinding:setActionEventTextVisibility(actionEventId, false)

				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.DIRECTION_CHANGE_NEG, self, Motorized.actionEventDirectionChange, false, true, false, true, nil, , true)

				g_inputBinding:setActionEventTextVisibility(actionEventId, false)
			end

			Motorized.updateActionEvents(self)
		end
	end
end

function Motorized:actionEventShiftGear(actionName, inputValue, callbackState, isAnalog)
	if actionName == InputAction.SHIFT_GEAR_UP then
		MotorGearShiftEvent.sendEvent(self, MotorGearShiftEvent.TYPE_SHIFT_UP)
	else
		MotorGearShiftEvent.sendEvent(self, MotorGearShiftEvent.TYPE_SHIFT_DOWN)
	end
end

function Motorized:actionEventSelectGear(actionName, inputValue, callbackState, isAnalog)
	MotorGearShiftEvent.sendEvent(self, MotorGearShiftEvent.TYPE_SELECT_GEAR, inputValue == 1 and callbackState or 0)
end

function Motorized:actionEventShiftGroup(actionName, inputValue, callbackState, isAnalog)
	if actionName == InputAction.SHIFT_GROUP_UP then
		MotorGearShiftEvent.sendEvent(self, MotorGearShiftEvent.TYPE_SHIFT_GROUP_UP)
	else
		MotorGearShiftEvent.sendEvent(self, MotorGearShiftEvent.TYPE_SHIFT_GROUP_DOWN)
	end
end

function Motorized:actionEventSelectGroup(actionName, inputValue, callbackState, isAnalog)
	MotorGearShiftEvent.sendEvent(self, MotorGearShiftEvent.TYPE_SELECT_GROUP, inputValue == 1 and callbackState or 0)
end

function Motorized:actionEventDirectionChange(actionName, inputValue, callbackState, isAnalog)
	if actionName == InputAction.DIRECTION_CHANGE_POS then
		MotorGearShiftEvent.sendEvent(self, MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_POS)
	elseif actionName == InputAction.DIRECTION_CHANGE_NEG then
		MotorGearShiftEvent.sendEvent(self, MotorGearShiftEvent.TYPE_DIRECTION_CHANGE_NEG)
	else
		MotorGearShiftEvent.sendEvent(self, MotorGearShiftEvent.TYPE_DIRECTION_CHANGE)
	end
end

function Motorized:actionEventClutch(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_motorized
	spec.clutchState = inputValue

	if self.isServer then
		spec.motor:onManualClutchChanged(spec.clutchState)

		if inputValue > 0 then
			self:raiseActive()
		end
	else
		self:raiseDirtyFlags(spec.inputDirtyFlag)
	end
end

function Motorized:updateActionEvents()
	local spec = self.spec_motorized
	local actionEvent = spec.actionEvents[InputAction.TOGGLE_MOTOR_STATE]

	if actionEvent ~= nil then
		if not g_currentMission.missionInfo.automaticMotorStartEnabled then
			local text = nil

			g_inputBinding:setActionEventActive(actionEvent.actionEventId, true)

			if self:getIsMotorStarted() then
				g_inputBinding:setActionEventTextPriority(actionEvent.actionEventId, GS_PRIO_VERY_LOW)

				text = spec.turnOffText
			else
				g_inputBinding:setActionEventTextPriority(actionEvent.actionEventId, GS_PRIO_VERY_HIGH)

				text = spec.turnOnText
			end

			g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
		else
			g_inputBinding:setActionEventActive(actionEvent.actionEventId, false)
		end
	end
end

function Motorized:getTraveledDistanceStatsActive()
	return true
end

function Motorized:setGearLeversState(gear, group, time, isResetPosition)
	local spec = self.spec_motorized

	for i = 1, #spec.gearLevers do
		local gearLever = spec.gearLevers[i]

		for j = 1, #gearLever.states do
			local state = gearLever.states[j]

			if state.gear ~= nil and state.gear == gear or state.group ~= nil and state.group == group then
				self:generateShiftAnimation(gearLever, state, time, isResetPosition)
			end
		end
	end
end

function Motorized:generateShiftAnimation(gearLever, state, time, isResetPosition)
	local gearLeverInterpolator = {
		interpolations = {}
	}
	state.curRotation[1], state.curRotation[2], state.curRotation[3] = getRotation(gearLever.node)
	local requiresChange = false

	for axis = 1, 3 do
		if math.abs(state.curRotation[axis] - state.rotation[axis]) > 1e-05 then
			requiresChange = true

			break
		end
	end

	local alreadyMovingToTarget = true

	for axis = 1, 3 do
		if math.abs(gearLever.curTarget[axis] - state.rotation[axis]) > 1e-05 then
			alreadyMovingToTarget = false

			break
		end
	end

	if not requiresChange or alreadyMovingToTarget then
		return false
	end

	gearLever.curTarget[3] = state.curRotation[3]
	gearLever.curTarget[2] = state.curRotation[2]
	gearLever.curTarget[1] = state.curRotation[1]
	local requiresMoveToCenter = false

	if gearLever.centerAxis ~= nil then
		local curCenter = state.curRotation[gearLever.centerAxis]
		local tarCenter = state.rotation[gearLever.centerAxis]
		requiresMoveToCenter = math.abs(curCenter - tarCenter) > 1e-05
	end

	if requiresMoveToCenter then
		for axis = 1, 3 do
			if axis ~= gearLever.centerAxis then
				local cur = state.curRotation[axis]
				local tar = state.rotation[axis]

				if gearLever.centerAxis ~= nil then
					tar = 0
				end

				local allowed = math.abs(cur - tar) > 1e-05
				local goToCenter = false

				if gearLever.centerAxis ~= nil and not allowed then
					allowed = state.useRotation[axis] and math.abs(state.curRotation[gearLever.centerAxis] - state.rotation[gearLever.centerAxis]) > 1e-05
					goToCenter = allowed
				end

				if allowed then
					table.insert(gearLeverInterpolator.interpolations, {
						axis = axis,
						cur = cur,
						tar = goToCenter and 0 or tar
					})

					gearLever.curTarget[axis] = tar
				end
			end
		end
	end

	if gearLever.centerAxis ~= nil then
		if requiresMoveToCenter then
			local curCenter = state.curRotation[gearLever.centerAxis]
			local tarCenter = state.rotation[gearLever.centerAxis]

			table.insert(gearLeverInterpolator.interpolations, {
				axis = gearLever.centerAxis,
				cur = curCenter,
				tar = tarCenter
			})

			gearLever.curTarget[gearLever.centerAxis] = tarCenter
		end

		for axis = 1, 3 do
			if axis ~= gearLever.centerAxis then
				local cur = state.curRotation[axis]
				local tar = state.rotation[axis]
				local allowed = math.abs(cur - tar) > 1e-05

				if gearLever.centerAxis ~= nil then
					allowed = allowed or state.useRotation[axis] and math.abs(state.curRotation[gearLever.centerAxis] - state.rotation[gearLever.centerAxis]) > 1e-05
				end

				if allowed then
					table.insert(gearLeverInterpolator.interpolations, {
						axis = axis,
						cur = requiresMoveToCenter and 0 or cur,
						tar = tar
					})

					gearLever.curTarget[axis] = tar
				end
			end
		end
	end

	for intState, _ in pairs(self.spec_motorized.activeGearLeverInterpolators) do
		if intState.gearLever == state.gearLever then
			self.spec_motorized.activeGearLeverInterpolators[intState] = nil
		end
	end

	if self.spec_motorized.activeGearLeverInterpolators[state] == nil then
		local numInterpolations = #gearLeverInterpolator.interpolations

		if numInterpolations > 0 then
			local timePerInterpolation = math.max(gearLever.changeTime, 0.001) / numInterpolations

			for ii = 1, numInterpolations do
				local interpolation = gearLeverInterpolator.interpolations[ii]
				interpolation.speed = (interpolation.tar - interpolation.cur) / timePerInterpolation
			end

			gearLeverInterpolator.currentInterpolation = 1
			gearLeverInterpolator.isResetPosition = isResetPosition == nil or isResetPosition == true
			gearLeverInterpolator.handsOnDelay = gearLever.handsOnDelay
			gearLeverInterpolator.isGear = state.gear ~= nil
			self.spec_motorized.activeGearLeverInterpolators[state] = gearLeverInterpolator
		end
	end
end

function Motorized:getGearInfoToDisplay()
	local gear, gearGroup, gearsAvailable, groupsAvailable, isAutomatic, prevGearName, nextGearName, prevPrevGearName, nextNextGearName, isGearChanging = nil
	local showNeutralWarning = false
	local motor = self.spec_motorized.motor

	if motor ~= nil then
		gear, gearsAvailable, isAutomatic, prevGearName, nextGearName, prevPrevGearName, nextNextGearName, isGearChanging = motor:getGearToDisplay()
		gearGroup, groupsAvailable = motor:getGearGroupToDisplay()

		if not groupsAvailable then
			gearGroup = nil
		end

		if self.getAcDecelerationAxis ~= nil and math.abs(self:getAcDecelerationAxis()) > 0 then
			showNeutralWarning = self:getIsMotorInNeutral()
		end
	end

	return gear, gearGroup, gearsAvailable, isAutomatic, prevGearName, nextGearName, prevPrevGearName, nextNextGearName, isGearChanging, showNeutralWarning
end

function Motorized:setTransmissionDirection(direction)
	local motor = self.spec_motorized.motor

	if motor ~= nil then
		motor:setTransmissionDirection(direction)
	end
end

function Motorized:getDirectionChangeMode()
	return self.spec_motorized.directionChangeMode
end

function Motorized:getGearShiftMode()
	return self.spec_motorized.gearShiftMode
end

function Motorized:onStateChange(state, vehicle, isControlling)
	if state == Vehicle.STATE_CHANGE_ENTER_VEHICLE then
		if g_currentMission.missionInfo.automaticMotorStartEnabled and self:getCanMotorRun() then
			self:startMotor(true)
		end
	elseif state == Vehicle.STATE_CHANGE_LEAVE_VEHICLE then
		if self:getStopMotorOnLeave() and g_currentMission.missionInfo.automaticMotorStartEnabled then
			self:stopMotor(true)
		end

		self:stopVehicle()
	end
end

function Motorized:stopVehicle()
	if self.isServer then
		local spec = self.spec_motorized

		if spec.motorizedNode ~= nil then
			self:controlVehicle(0, 0, 0, 0, math.huge, 0, 0, 0, 0, 0)
		end
	end
end

function Motorized:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	if fillLevelDelta > 0 and fillType == FillType.DIESEL then
		local factor = self:getFillUnitFillLevel(fillUnitIndex) / self:getFillUnitCapacity(fillUnitIndex)
		local defFillUnitIndex = self:getConsumerFillUnitIndex(FillType.DEF)

		if defFillUnitIndex ~= nil then
			local delta = self:getFillUnitCapacity(defFillUnitIndex) * factor - self:getFillUnitFillLevel(defFillUnitIndex)

			self:addFillUnitFillLevel(self:getOwnerFarmId(), defFillUnitIndex, delta, FillType.DEF, ToolType.UNDEFINED, nil)
		end
	end
end

function Motorized:onSetBroken()
	self:stopMotor(true)
end

function Motorized:getName(superFunc)
	local name = superFunc(self)
	local item = g_storeManager:getItemByXMLFilename(self.configFileName)

	if item ~= nil and item.configurations ~= nil then
		local configId = self.configurations.motor
		local config = item.configurations.motor[configId]

		if config.name and config.name ~= "" then
			name = config.name
		end
	end

	return name
end

function Motorized:getCanBeSelected(superFunc)
	if not g_currentMission.missionInfo.automaticMotorStartEnabled then
		local vehicles = self.rootVehicle:getChildVehicles()

		for _, vehicle in pairs(vehicles) do
			if vehicle.spec_motorized ~= nil then
				return true
			end
		end
	end

	return superFunc(self)
end

function Motorized:getIsPowered(superFunc)
	local ret = superFunc(self)

	if ret and not self.spec_motorized.isMotorStarted then
		local vehicles = self.rootVehicle:getChildVehicles()

		for _, vehicle in pairs(vehicles) do
			if vehicle ~= self and vehicle.spec_motorized ~= nil and vehicle.spec_motorized.isMotorStarted then
				return true
			end
		end

		if self:getCanMotorRun() then
			return false, g_i18n:getText("warning_motorNotStarted")
		else
			return false, self:getMotorNotAllowedWarning()
		end
	end

	return ret
end

function Motorized:getDashboardSpeedDir()
	return self:getLastSpeed() * self.movingDirection
end

function Motorized:actionEventToggleMotorState(actionName, inputValue, callbackState, isAnalog)
	if not self:getIsAIActive() then
		local spec = self.spec_motorized

		if spec.isMotorStarted then
			self:stopMotor()
		elseif self:getCanMotorRun() then
			self:startMotor()
		else
			local warning = self:getMotorNotAllowedWarning()

			if warning ~= nil then
				g_currentMission:showBlinkingWarning(warning, 2000)
			end
		end
	end
end

function Motorized.getStoreAdditionalConfigData(xmlFile, baseXMLName, baseDir, customEnvironment, isMod, configItem)
	configItem.power = xmlFile:getValue(baseXMLName .. "#hp")
	configItem.maxSpeed = xmlFile:getValue(baseXMLName .. "#maxSpeed")
	configItem.consumerConfigurationIndex = xmlFile:getValue(baseXMLName .. "#consumerConfigurationIndex")
end

function Motorized.loadSpecValueFuel(xmlFile, customEnvironment)
	local rootName = xmlFile:getRootName()
	local fillUnits = {}
	local i = 0

	while true do
		local configKey = string.format(rootName .. ".fillUnit.fillUnitConfigurations.fillUnitConfiguration(%d)", i)

		if not xmlFile:hasProperty(configKey) then
			break
		end

		local configFillUnits = {}
		local j = 0

		while true do
			local fillUnitKey = string.format(configKey .. ".fillUnits.fillUnit(%d)", j)

			if not xmlFile:hasProperty(fillUnitKey) then
				break
			end

			local fillTypes = xmlFile:getValue(fillUnitKey .. "#fillTypes")
			local capacity = xmlFile:getValue(fillUnitKey .. "#capacity")

			table.insert(configFillUnits, {
				fillTypes = fillTypes,
				capacity = capacity
			})

			j = j + 1
		end

		table.insert(fillUnits, configFillUnits)

		i = i + 1
	end

	local consumers = {}
	i = 0

	while true do
		local key = string.format(rootName .. ".motorized.consumerConfigurations.consumerConfiguration(%d)", i)

		if not xmlFile:hasProperty(key) then
			break
		end

		local consumer = {}
		local j = 0

		while true do
			local consumerKey = string.format(key .. ".consumer(%d)", j)

			if not xmlFile:hasProperty(consumerKey) then
				break
			end

			local fillType = xmlFile:getValue(consumerKey .. "#fillType")
			local fillUnitIndex = xmlFile:getValue(consumerKey .. "#fillUnitIndex")
			local capacity = xmlFile:getValue(consumerKey .. "#capacity")

			table.insert(consumer, {
				fillType = fillType,
				fillUnitIndex = fillUnitIndex,
				capacity = capacity
			})

			j = j + 1
		end

		table.insert(consumers, consumer)

		i = i + 1
	end

	return {
		fillUnits = fillUnits,
		consumers = consumers
	}
end

function Motorized.getSpecValueFuelDiesel(storeItem, realItem, configurations)
	return Motorized.getSpecValueFuel(storeItem, realItem, configurations, FillType.DIESEL)
end

function Motorized.getSpecValueFuelElectricCharge(storeItem, realItem, configurations)
	return Motorized.getSpecValueFuel(storeItem, realItem, configurations, FillType.ELECTRICCHARGE)
end

function Motorized.getSpecValueFuelMethane(storeItem, realItem, configurations)
	return Motorized.getSpecValueFuel(storeItem, realItem, configurations, FillType.METHANE)
end

function Motorized.getSpecValueFuel(storeItem, realItem, configurations, fillTypeFilter)
	local consumerIndex = 1

	if realItem ~= nil and storeItem.configurations ~= nil and realItem.configurations.motor ~= nil and storeItem.configurations.motor ~= nil then
		local motorConfigId = realItem.configurations.motor
		consumerIndex = Utils.getNoNil(storeItem.configurations.motor[motorConfigId].consumerConfigurationIndex, consumerIndex)
	elseif configurations ~= nil then
		local motorConfigId = configurations.motor

		if motorConfigId ~= nil then
			consumerIndex = Utils.getNoNil(storeItem.configurations.motor[motorConfigId].consumerConfigurationIndex, consumerIndex)
		end
	end

	local fuel, def, electricCharge, methane = nil
	local fuelFillUnitIndex = 0
	local defFillUnitIndex = 0
	local electricFillUnitIndex = 0
	local methaneFillUnitIndex = 0
	local consumerConfiguration = storeItem.specs.fuel and storeItem.specs.fuel.consumers[consumerIndex]

	if consumerConfiguration ~= nil then
		for _, unitConsumers in ipairs(consumerConfiguration) do
			local fillType = g_fillTypeManager:getFillTypeIndexByName(unitConsumers.fillType)

			if fillTypeFilter == nil or fillType == fillTypeFilter then
				if fillType == FillType.DIESEL then
					fuelFillUnitIndex = unitConsumers.fillUnitIndex
					fuel = unitConsumers.capacity

					if fillType == FillType.DEF then
						defFillUnitIndex = unitConsumers.fillUnitIndex
						def = unitConsumers.capacity
					end
				elseif fillType == FillType.ELECTRICCHARGE then
					electricFillUnitIndex = unitConsumers.fillUnitIndex
					electricCharge = unitConsumers.capacity
				elseif fillType == FillType.METHANE then
					methaneFillUnitIndex = unitConsumers.fillUnitIndex
					methane = unitConsumers.capacity
				end
			end
		end
	end

	local fuelConfigIndex = 1

	if realItem ~= nil and storeItem.configurations ~= nil and realItem.configurations.fillUnit ~= nil and storeItem.configurations.fillUnit ~= nil then
		fuelConfigIndex = realItem.configurations.fillUnit
	end

	if storeItem.specs.fuel and storeItem.specs.fuel.fillUnits[fuelConfigIndex] ~= nil then
		local fuelFillUnit = storeItem.specs.fuel.fillUnits[fuelConfigIndex][fuelFillUnitIndex]

		if fuelFillUnit ~= nil and fuel == nil then
			fuel = math.max(fuelFillUnit.capacity, fuel or 0)
		end

		local defFillUnit = storeItem.specs.fuel.fillUnits[fuelConfigIndex][defFillUnitIndex]

		if defFillUnit ~= nil and def == nil then
			def = math.max(defFillUnit.capacity, def or 0)
		end

		local electricFillUnit = storeItem.specs.fuel.fillUnits[fuelConfigIndex][electricFillUnitIndex]

		if electricFillUnit ~= nil and electricCharge == nil then
			electricCharge = math.max(electricFillUnit.capacity, electricCharge or 0)
		end

		local methaneFillUnit = storeItem.specs.fuel.fillUnits[fuelConfigIndex][methaneFillUnitIndex]

		if methaneFillUnit ~= nil and methane == nil then
			methane = math.max(methaneFillUnit.capacity, methane or 0)
		end
	end

	if fuel ~= nil then
		if def ~= nil and def > 0 then
			return string.format(g_i18n:getText("shop_fuelDefValue"), fuel, g_i18n:getText("unit_literShort"), def, g_i18n:getText("unit_literShort"), g_i18n:getText("fillType_def_short"))
		else
			return string.format(g_i18n:getText("shop_fuelValue"), fuel, g_i18n:getText("unit_literShort"))
		end
	elseif electricCharge ~= nil then
		return string.format(g_i18n:getText("shop_fuelValue"), electricCharge, g_i18n:getText("unit_kw"))
	elseif methane ~= nil then
		return string.format(g_i18n:getText("shop_fuelValue"), methane, g_i18n:getText("unit_kg"))
	end

	return nil
end

function Motorized.loadSpecValueMaxSpeed(xmlFile, customEnvironment)
	local motorKey = nil

	if xmlFile:hasProperty("vehicle.motorized.motorConfigurations.motorConfiguration(0)") then
		motorKey = "vehicle.motorized.motorConfigurations.motorConfiguration(0)"
	elseif xmlFile:hasProperty("vehicle.motor") then
		motorKey = "vehicle"
	end

	if motorKey ~= nil then
		local maxRpm = xmlFile:getValue(motorKey .. ".motor#maxRpm", 1800)
		local minForwardGearRatio = xmlFile:getValue(motorKey .. ".transmission#minForwardGearRatio", nil)
		local axleRatio = xmlFile:getValue(motorKey .. ".transmission#axleRatio", 1)
		local forwardGears = Motorized.loadGears(nil, xmlFile, "forwardGear", motorKey .. ".transmission", maxRpm, axleRatio, 1)
		local calculatedMaxSpeed = math.ceil(VehicleMotor.calculatePhysicalMaximumSpeed(minForwardGearRatio, forwardGears, maxRpm) * 3.6)
		local storeDataMaxSpeed = xmlFile:getValue("vehicle.storeData.specs.maxSpeed")
		local maxSpeed = xmlFile:getValue("vehicle.motorized.motorConfigurations.motorConfiguration(0)#maxSpeed")
		local maxForwardSpeed = xmlFile:getValue(motorKey .. ".motor#maxForwardSpeed")

		if storeDataMaxSpeed ~= nil then
			return storeDataMaxSpeed
		elseif maxSpeed ~= nil then
			return maxSpeed
		elseif maxForwardSpeed ~= nil then
			return math.min(maxForwardSpeed, calculatedMaxSpeed)
		else
			return calculatedMaxSpeed
		end
	end

	return nil
end

function Motorized.getSpecValueMaxSpeed(storeItem, realItem)
	local maxSpeed = nil

	if realItem ~= nil and storeItem.configurations ~= nil and realItem.configurations.motor ~= nil and storeItem.configurations.motor ~= nil then
		local configId = realItem.configurations.motor
		maxSpeed = Utils.getNoNil(storeItem.configurations.motor[configId].maxSpeed, maxSpeed)
	end

	if maxSpeed == nil then
		maxSpeed = storeItem.specs.maxSpeed
	end

	if maxSpeed ~= nil then
		return string.format(g_i18n:getText("shop_maxSpeed"), string.format("%1d", g_i18n:getSpeed(maxSpeed)), g_i18n:getSpeedMeasuringUnit())
	end

	return nil
end

function Motorized.loadSpecValuePower(xmlFile, customEnvironment)
	return xmlFile:getValue("vehicle.storeData.specs.power")
end

function Motorized.getSpecValuePower(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	local minPower, maxPower = nil

	if realItem ~= nil and storeItem.configurations ~= nil and realItem.configurations.motor ~= nil and storeItem.configurations.motor ~= nil then
		local configId = realItem.configurations.motor
		minPower = storeItem.configurations.motor[configId].power
		maxPower = minPower
	elseif realItem == nil and storeItem.configurations ~= nil and storeItem.configurations.motor ~= nil then
		for configId = 1, #storeItem.configurations.motor do
			local configItem = storeItem.configurations.motor[configId]

			if configItem.power ~= nil then
				minPower = math.min(minPower or math.huge, configItem.power)
				maxPower = math.max(maxPower or 0, configItem.power)
			end
		end
	end

	if minPower == nil then
		minPower = storeItem.specs.power
		maxPower = minPower
	end

	if minPower ~= nil then
		if returnValues == nil or returnValues == false then
			if minPower ~= maxPower then
				return string.format(g_i18n:getText("shop_maxPowerValueRange"), MathUtil.round(minPower), MathUtil.round(maxPower))
			else
				return string.format(g_i18n:getText("shop_maxPowerValueSingle"), MathUtil.round(minPower))
			end
		else
			return MathUtil.round(minPower), MathUtil.round(maxPower)
		end
	end

	return nil
end

function Motorized.loadSpecValuePowerConfig(xmlFile, customEnvironment)
	local powerValues = {}
	local isValid = false

	for name, id in pairs(g_configurationManager:getConfigurations()) do
		local specializationKey = g_configurationManager:getConfigurationAttribute(name, "xmlKey")

		if specializationKey ~= nil then
			specializationKey = "." .. specializationKey
		else
			specializationKey = ""
		end

		local configrationsKey = string.format("vehicle%s.%sConfigurations", specializationKey, name)
		powerValues[name] = {}
		local i = 0

		while true do
			local baseKey = string.format("%s.%sConfiguration(%d)", configrationsKey, name, i)

			if not xmlFile:hasProperty(baseKey) then
				break
			end

			local configValue = getXMLInt(xmlFile.handle, baseKey .. "#hp")

			if configValue ~= nil then
				powerValues[name][i + 1] = MathUtil.round(configValue)
				isValid = true
			end

			i = i + 1
		end
	end

	if isValid then
		return powerValues
	end

	return nil
end

function Motorized.getSpecValuePowerConfig(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	if storeItem.specs.powerConfig ~= nil then
		local minPower, maxPower = nil

		if configurations ~= nil then
			for configName, config in pairs(configurations) do
				local configPower = storeItem.specs.powerConfig[configName][config]

				if configPower ~= nil then
					minPower = configPower
					maxPower = configPower
				end
			end
		else
			minPower = math.huge
			maxPower = 0
			local numConfigs = 0

			for _, configs in pairs(storeItem.specs.powerConfig) do
				for _, configPower in pairs(configs) do
					minPower = math.min(minPower, configPower)
					maxPower = math.max(maxPower, configPower)
					numConfigs = numConfigs + 1
				end
			end
		end

		if minPower ~= nil then
			if not returnValues then
				if minPower ~= maxPower then
					return string.format(g_i18n:getText("shop_maxPowerValueRange"), MathUtil.round(minPower), MathUtil.round(maxPower))
				else
					return string.format(g_i18n:getText("shop_maxPowerValueSingle"), MathUtil.round(minPower))
				end
			else
				return MathUtil.round(minPower), MathUtil.round(maxPower)
			end
		end
	end

	return nil
end

function Motorized.loadSpecValueTransmission(xmlFile, customEnvironment)
	local nameByConfigIndex = {}

	xmlFile:iterate("vehicle.motorized.motorConfigurations.motorConfiguration", function (index, key)
		nameByConfigIndex[index] = xmlFile:getValue(key .. ".transmission#name", nil, customEnvironment, false)
	end)

	return nameByConfigIndex
end

function Motorized.getSpecValueTransmission(storeItem, realItem, configurations, saleItem, returnValues, returnRange)
	local name = nil

	if realItem ~= nil and storeItem.configurations ~= nil and realItem.configurations.motor ~= nil and storeItem.configurations.motor ~= nil then
		name = storeItem.specs.transmission[realItem.configurations.motor]

		if name == nil then
			name = storeItem.specs.transmission[1]
		end
	else
		name = storeItem.specs.transmission[1]
	end

	return name
end
