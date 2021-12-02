Wheels = {
	WHEEL_NO_CONTACT = 0,
	WHEEL_OBJ_CONTACT = 1,
	WHEEL_GROUND_CONTACT = 2,
	WHEEL_GROUND_HEIGHT_CONTACT = 3,
	perlinNoiseSink = {}
}
Wheels.perlinNoiseSink.randomFrequency = 0.2
Wheels.perlinNoiseSink.persistence = 0
Wheels.perlinNoiseSink.numOctaves = 2
Wheels.perlinNoiseSink.randomSeed = 123
Wheels.perlinNoiseWobble = {
	randomFrequency = 0.8,
	persistence = 0,
	numOctaves = 4,
	randomSeed = 321
}
Wheels.GROUND_PARTICLES = {
	true,
	false,
	true,
	false,
	true,
	true,
	true
}
Wheels.MAX_SINK = {
	[FieldGroundType.STUBBLE_TILLAGE] = 0.15,
	[FieldGroundType.CULTIVATED] = 0.2,
	[FieldGroundType.SEEDBED] = 0.15,
	[FieldGroundType.PLOWED] = 0.25,
	[FieldGroundType.ROLLED_SEEDBED] = 0.08,
	[FieldGroundType.SOWN] = 0.08,
	[FieldGroundType.DIRECT_SOWN] = 0.08,
	[FieldGroundType.PLANTED] = 0.08,
	[FieldGroundType.RIDGE] = 0.15,
	[FieldGroundType.ROLLER_LINES] = 0.08,
	[FieldGroundType.HARVEST_READY] = 0.08,
	[FieldGroundType.HARVEST_READY_OTHER] = 0.08,
	[FieldGroundType.GRASS] = 0.1,
	[FieldGroundType.GRASS_CUT] = 0.1
}
Wheels.PARTICLE_SYSTEM_PATH = "$data/effects/wheel/wheelEmitterShape.i3d"
Wheels.MAX_TIRE_TRACK_CREATION_DISTANCE = 75
Wheels.VISUAL_WHEEL_UPDATE_DISTANCE = 300
Wheels.WHEELS_XML_PATH = "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).wheels"
Wheels.WHEEL_XML_PATH = "vehicle.wheels.wheelConfigurations.wheelConfiguration(?).wheels.wheel(?)"
Wheels.xmlSchema = nil
Wheels.xmlSchemaHub = nil
Wheels.xmlSchemaConnector = nil

function Wheels.prerequisitesPresent(specializations)
	return true
end

function Wheels.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onBrake")
	SpecializationUtil.registerEvent(vehicleType, "onFinishedWheelLoading")
	SpecializationUtil.registerEvent(vehicleType, "onWheelConfigurationChanged")
end

function Wheels.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getSteeringRotTimeByCurvature", Wheels.getSteeringRotTimeByCurvature)
	SpecializationUtil.registerFunction(vehicleType, "getTurningRadiusByRotTime", Wheels.getTurningRadiusByRotTime)
	SpecializationUtil.registerFunction(vehicleType, "getWheelConfigurationValue", Wheels.getWheelConfigurationValue)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelFromXML", Wheels.loadWheelFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelBaseData", Wheels.loadWheelBaseData)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelDataFromExternalXML", Wheels.loadWheelDataFromExternalXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelSharedData", Wheels.loadWheelSharedData)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelPhysicsData", Wheels.loadWheelPhysicsData)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelSteeringData", Wheels.loadWheelSteeringData)
	SpecializationUtil.registerFunction(vehicleType, "loadAdditionalWheelsFromXML", Wheels.loadAdditionalWheelsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadAdditionalWheelConnectorFromXML", Wheels.loadAdditionalWheelConnectorFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelChocksFromXML", Wheels.loadWheelChocksFromXML)
	SpecializationUtil.registerFunction(vehicleType, "onWheelChockI3DLoaded", Wheels.onWheelChockI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadWheelParticleSystem", Wheels.loadWheelParticleSystem)
	SpecializationUtil.registerFunction(vehicleType, "onWheelParticleSystemI3DLoaded", Wheels.onWheelParticleSystemI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadHubsFromXML", Wheels.loadHubsFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadHubFromXML", Wheels.loadHubFromXML)
	SpecializationUtil.registerFunction(vehicleType, "onWheelHubI3DLoaded", Wheels.onWheelHubI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadAckermannSteeringFromXML", Wheels.loadAckermannSteeringFromXML)
	SpecializationUtil.registerFunction(vehicleType, "loadNonPhysicalWheelFromXML", Wheels.loadNonPhysicalWheelFromXML)
	SpecializationUtil.registerFunction(vehicleType, "finalizeWheel", Wheels.finalizeWheel)
	SpecializationUtil.registerFunction(vehicleType, "onWheelPartI3DLoaded", Wheels.onWheelPartI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "onAdditionalWheelConnectorI3DLoaded", Wheels.onAdditionalWheelConnectorI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "readWheelDataFromStream", Wheels.readWheelDataFromStream)
	SpecializationUtil.registerFunction(vehicleType, "writeWheelDataToStream", Wheels.writeWheelDataToStream)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelContact", Wheels.updateWheelContact)
	SpecializationUtil.registerFunction(vehicleType, "addTireTrackNode", Wheels.addTireTrackNode)
	SpecializationUtil.registerFunction(vehicleType, "updateTireTrackNode", Wheels.updateTireTrackNode)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelDensityMapHeight", Wheels.updateWheelDensityMapHeight)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelDestruction", Wheels.updateWheelDestruction)
	SpecializationUtil.registerFunction(vehicleType, "getIsWheelFoliageDestructionAllowed", Wheels.getIsWheelFoliageDestructionAllowed)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelSink", Wheels.updateWheelSink)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelFriction", Wheels.updateWheelFriction)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelBase", Wheels.updateWheelBase)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelTireFriction", Wheels.updateWheelTireFriction)
	SpecializationUtil.registerFunction(vehicleType, "setWheelPositionDirty", Wheels.setWheelPositionDirty)
	SpecializationUtil.registerFunction(vehicleType, "setWheelTireFrictionDirty", Wheels.setWheelTireFrictionDirty)
	SpecializationUtil.registerFunction(vehicleType, "getDriveGroundParticleSystemsScale", Wheels.getDriveGroundParticleSystemsScale)
	SpecializationUtil.registerFunction(vehicleType, "getIsVersatileYRotActive", Wheels.getIsVersatileYRotActive)
	SpecializationUtil.registerFunction(vehicleType, "getWheelFromWheelIndex", Wheels.getWheelFromWheelIndex)
	SpecializationUtil.registerFunction(vehicleType, "getWheelByWheelNode", Wheels.getWheelByWheelNode)
	SpecializationUtil.registerFunction(vehicleType, "getWheels", Wheels.getWheels)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentSurfaceSound", Wheels.getCurrentSurfaceSound)
	SpecializationUtil.registerFunction(vehicleType, "getAreSurfaceSoundsActive", Wheels.getAreSurfaceSoundsActive)
	SpecializationUtil.registerFunction(vehicleType, "destroyFruitArea", Wheels.destroyFruitArea)
	SpecializationUtil.registerFunction(vehicleType, "destroySnowArea", Wheels.destroySnowArea)
	SpecializationUtil.registerFunction(vehicleType, "brake", Wheels.brake)
	SpecializationUtil.registerFunction(vehicleType, "getBrakeForce", Wheels.getBrakeForce)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelChocksPosition", Wheels.updateWheelChocksPosition)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelChockPosition", Wheels.updateWheelChockPosition)
	SpecializationUtil.registerFunction(vehicleType, "updateWheelDirtAmount", Wheels.updateWheelDirtAmount)
	SpecializationUtil.registerFunction(vehicleType, "getAllowTireTracks", Wheels.getAllowTireTracks)
	SpecializationUtil.registerFunction(vehicleType, "getTireTrackColor", Wheels.getTireTrackColor)
	SpecializationUtil.registerFunction(vehicleType, "forceUpdateWheelPhysics", Wheels.forceUpdateWheelPhysics)
end

function Wheels.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", Wheels.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", Wheels.removeFromPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getComponentMass", Wheels.getComponentMass)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVehicleWorldXRot", Wheels.getVehicleWorldXRot)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVehicleWorldDirection", Wheels.getVehicleWorldDirection)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "validateWashableNode", Wheels.validateWashableNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIDirectionNode", Wheels.getAIDirectionNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIRootNode", Wheels.getAIRootNode)
end

function Wheels.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onPostUpdate", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateEnd", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterAnimationValueTypes", Wheels)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", Wheels)
end

function Wheels.initSpecialization()
	g_configurationManager:addConfigurationType("wheel", g_i18n:getText("configuration_wheelSetup"), "wheels", nil, Wheels.loadBrandName, Wheels.loadedBrandNames, ConfigurationUtil.SELECTOR_MULTIOPTION, g_i18n:getText("configuration_wheelBrand"), Wheels.getBrands, Wheels.getWheelsByBrand)
	g_configurationManager:addConfigurationType("rimColor", g_i18n:getText("configuration_rimColor"), nil, , ConfigurationUtil.getConfigColorSingleItemLoad, ConfigurationUtil.getConfigColorPostLoad, ConfigurationUtil.SELECTOR_COLOR)
	g_storeManager:addSpecType("wheels", "shopListAttributeIconWheels", Wheels.loadSpecValueWheels, Wheels.getSpecValueWheels, "vehicle")

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Wheels")
	ConfigurationUtil.registerColorConfigurationXMLPaths(schema, "rimColor")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?)")
	schema:register(XMLValueType.STRING, "vehicle.wheels.wheelConfigurations.wheelConfiguration(?)#brand", "Wheel brand")

	local configKey = Wheels.WHEELS_XML_PATH

	schema:register(XMLValueType.FLOAT, configKey .. "#autoRotateBackSpeed", "Auto rotate back speed", 1)
	schema:register(XMLValueType.BOOL, configKey .. "#speedDependentRotateBack", "Speed dependent auto rotate back speed", true)
	schema:register(XMLValueType.INT, configKey .. "#differentialIndex", "Differential index")
	schema:register(XMLValueType.INT, configKey .. "#ackermannSteeringIndex", "Ackermann steering index")
	schema:register(XMLValueType.STRING, configKey .. "#baseConfig", "Base for this configuration")
	schema:register(XMLValueType.BOOL, configKey .. "#hasSurfaceSounds", "Has surface sounds", true)
	schema:register(XMLValueType.STRING, configKey .. "#surfaceSoundTireType", "Tire type that is used for surface sounds", "Tire type of first wheel")
	schema:register(XMLValueType.NODE_INDEX, configKey .. "#surfaceSoundLinkNode", "Surface sound link node", "Root component")
	Wheels.registerWheelXMLPaths(schema, configKey .. ".wheel(?)")
	schema:register(XMLValueType.COLOR, "vehicle.wheels.rimColor", "Rim color")
	schema:register(XMLValueType.BOOL, "vehicle.wheels.rimColor#useBaseColor", "Use base vehicle color", false)
	schema:register(XMLValueType.INT, "vehicle.wheels.rimColor#material", "Material id")

	for i = 0, 7 do
		schema:register(XMLValueType.COLOR, "vehicle.wheels.hubs.color" .. i, "Color")
		schema:register(XMLValueType.INT, "vehicle.wheels.hubs.color" .. i .. "#material", "Material id")
		schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.color" .. i .. "#useBaseColor", "Use base color", false)
		schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.color" .. i .. "#useRimColor", "Use rim color", false)
	end

	schema:register(XMLValueType.NODE_INDEX, "vehicle.wheels.hubs.hub(?)#linkNode", "Link node")
	schema:register(XMLValueType.STRING, "vehicle.wheels.hubs.hub(?)#filename", "Filename")
	schema:register(XMLValueType.BOOL, "vehicle.wheels.hubs.hub(?)#isLeft", "Is left side", false)

	for i = 0, 7 do
		schema:register(XMLValueType.STRING, "vehicle.wheels.hubs.hub(?).color" .. i, "Color")
		schema:register(XMLValueType.INT, "vehicle.wheels.hubs.hub(?).color" .. i .. "#material", "Material id")
	end

	schema:register(XMLValueType.FLOAT, "vehicle.wheels.hubs.hub(?)#offset", "X axis offset")
	schema:register(XMLValueType.VECTOR_SCALE, "vehicle.wheels.hubs.hub(?)#scale", "Hub scale")
	schema:addDelayedRegistrationFunc("AnimatedVehicle:part", function (cSchema, cKey)
		cSchema:register(XMLValueType.INT, cKey .. "#wheelIndex", "Wheel index [1..n]")
		cSchema:register(XMLValueType.ANGLE, cKey .. "#startSteeringAngle", "Start steering angle")
		cSchema:register(XMLValueType.ANGLE, cKey .. "#endSteeringAngle", "End steering angle")
		cSchema:register(XMLValueType.FLOAT, cKey .. "#startBrakeFactor", "Start brake force factor")
		cSchema:register(XMLValueType.FLOAT, cKey .. "#endBrakeFactor", "End brake force factor")
	end)

	local dynaWheelKey = "vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(?)"

	schema:register(XMLValueType.NODE_INDEX, dynaWheelKey .. "#linkNode", "Link node")
	schema:register(XMLValueType.STRING, dynaWheelKey .. "#filename", "Path to wheel xml file")
	schema:register(XMLValueType.STRING, dynaWheelKey .. "#configId", "Wheel config id", "default")
	schema:register(XMLValueType.BOOL, dynaWheelKey .. "#isLeft", "Is left", true)
	schema:register(XMLValueType.BOOL, dynaWheelKey .. "#isInverted", "Tire profile inverted", false)
	schema:register(XMLValueType.ANGLE, dynaWheelKey .. "#xRotOffset", "X rotation offset", 0)
	schema:register(XMLValueType.COLOR, dynaWheelKey .. "#color", "Rim color")
	schema:register(XMLValueType.COLOR, dynaWheelKey .. "#additionalColor", "Color of additional part")
	Wheels.registerAckermannSteeringXMLPaths(schema, "vehicle.wheels.ackermannSteeringConfigurations.ackermannSteering(?)")
	schema:setXMLSpecializationType()

	Wheels.xmlSchema = XMLSchema.new("wheel")

	Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.brand", "Wheel tire brand", "LIZARD")
	Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.name", "Wheel tire name", "Tire")
	Wheels.registerWheelSharedDataXMLPaths(Wheels.xmlSchema, "wheel.default")
	Wheels.registerWheelSharedDataXMLPaths(Wheels.xmlSchema, "wheel.configurations.configuration(?)")
	Wheels.xmlSchema:register(XMLValueType.STRING, "wheel.configurations.configuration(?)#id", "Configuration Id")

	Wheels.xmlSchemaHub = XMLSchema.new("wheelHub")
	local hubSchema = Wheels.xmlSchemaHub

	hubSchema:register(XMLValueType.STRING, "hub.filename", "I3D filename")
	hubSchema:register(XMLValueType.STRING, "hub.nodes#left", "Index of left node in hub i3d file")
	hubSchema:register(XMLValueType.STRING, "hub.nodes#right", "Index of right node in hub i3d file")
	hubSchema:register(XMLValueType.COLOR, "hub.color0", "Color 0")
	hubSchema:register(XMLValueType.COLOR, "hub.color1", "Color 1")
	hubSchema:register(XMLValueType.COLOR, "hub.color2", "Color 2")
	hubSchema:register(XMLValueType.COLOR, "hub.color3", "Color 3")
	hubSchema:register(XMLValueType.COLOR, "hub.color4", "Color 4")
	hubSchema:register(XMLValueType.COLOR, "hub.color5", "Color 5")
	hubSchema:register(XMLValueType.COLOR, "hub.color6", "Color 6")
	hubSchema:register(XMLValueType.COLOR, "hub.color7", "Color 7")

	Wheels.xmlSchemaConnector = XMLSchema.new("wheelConnector")
	local connectorSchema = Wheels.xmlSchemaConnector

	connectorSchema:register(XMLValueType.STRING, "connector.file#name", "I3D filename")
	connectorSchema:register(XMLValueType.STRING, "connector.file#leftNode", "Index of left node in connector i3d file")
	connectorSchema:register(XMLValueType.STRING, "connector.file#rightNode", "Index of right node in connector i3d file")

	local schemaSavegame = Vehicle.xmlSchemaSavegame

	schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).wheels#lastWheelConfiguration", "Last selected wheel configuration", 1)
end

function Wheels.registerWheelXMLPaths(schema, key)
	Wheels.registerWheelBaseDataXMLPaths(schema, key)
	Wheels.registerWheelSharedDataXMLPaths(schema, key)
	Wheels.registerWheelPhysicsDataXMLPaths(schema, key)
	Wheels.registerWheelSteeringDataXMLPaths(schema, key)
	Wheels.registerWheelAdditionalWheelsXMLPaths(schema, key .. ".additionalWheel(?)")
	Wheels.registerWheelChockXMLPaths(schema, key .. ".wheelChock(?)")
	Wheels.registerWheelParticleSystemXMLPaths(schema, key .. ".wheelParticleSystem")
end

function Wheels.registerWheelBaseDataXMLPaths(schema, key)
	schema:register(XMLValueType.NODE_INDEX, key .. ".physics#repr", "Wheel repr node")
	schema:register(XMLValueType.COLOR, key .. "#color", "Wheel color")
	schema:register(XMLValueType.INT, key .. "#material", "Wheel material id")
	schema:register(XMLValueType.COLOR, key .. "#additionalColor", "Additional wheel color")
	schema:register(XMLValueType.INT, key .. "#additionalMaterial", "Additional wheel material id")
	schema:register(XMLValueType.BOOL, key .. "#isLeft", "Is left", true)
	schema:register(XMLValueType.BOOL, key .. "#hasTireTracks", "Has tire tracks", false)
	schema:register(XMLValueType.BOOL, key .. "#hasParticles", "Has particles", false)
	schema:register(XMLValueType.STRING, key .. "#filename", "Filename")
	schema:register(XMLValueType.STRING, key .. "#configId", "Wheel config id", "default")
	schema:register(XMLValueType.ANGLE, key .. "#xRotOffset", "X Rotation offset", 0)
end

function Wheels.registerWheelSharedDataXMLPaths(schema, key)
	schema:register(XMLValueType.FLOAT, key .. ".physics#radius", "Wheel radius")
	schema:register(XMLValueType.FLOAT, key .. ".physics#width", "Wheel width")
	schema:register(XMLValueType.FLOAT, key .. ".physics#mass", "Wheel mass (to.)", 0.1)
	schema:register(XMLValueType.STRING, key .. ".physics#tireType", "Tire type (mud, offRoad, street, crawler)")
	schema:register(XMLValueType.FLOAT, key .. ".physics#frictionScale", "Friction scale")
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxLongStiffness", "Max. longitude stiffness")
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxLatStiffness", "Max. latitude stiffness")
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxLatStiffnessLoad", "Max. latitude stiffness load")
	schema:register(XMLValueType.FLOAT, key .. ".tire#tireTrackAtlasIndex", "Tire track atlas index", 0)
	schema:register(XMLValueType.FLOAT, key .. ".tire#widthOffset", "Width offset", 0)
	schema:register(XMLValueType.FLOAT, key .. ".tire#xOffset", "X offset", 0)
	schema:register(XMLValueType.FLOAT, key .. ".tire#maxDeformation", "Max. deformation", 0)
	schema:register(XMLValueType.FLOAT, key .. ".tire#initialDeformation", "Tire deformation at initial compression value", "min. 0.04 and max. 60% of the deformation")
	schema:register(XMLValueType.FLOAT, key .. ".tire#sideDeformOffset", "Offset from lowerst point in center to lowerest point on the side in percentage (0.95: Radius on the side is 5% smaller than in the center)", 1)
	schema:register(XMLValueType.BOOL, key .. ".tire#isCareWheel", "Is care wheel")
	schema:register(XMLValueType.FLOAT, key .. ".physics#smoothGroundRadius", "Smooth ground radius", "width * 0.75")
	schema:register(XMLValueType.STRING, key .. ".tire#filename", "Path to tire i3d file")
	schema:register(XMLValueType.BOOL, key .. ".tire#isInverted", "Tire profile is inverted")
	schema:register(XMLValueType.STRING, key .. ".tire#node", "Node Index inside tire i3d")
	schema:register(XMLValueType.STRING, key .. ".tire#nodeLeft", "Left node index inside tire i3d")
	schema:register(XMLValueType.STRING, key .. ".tire#nodeRight", "Right node index inside tire i3d")
	schema:register(XMLValueType.STRING, key .. ".outerRim#filename", "Path to outer rim i3d file")
	schema:register(XMLValueType.STRING, key .. ".outerRim#node", "Outer rim node index in i3d file", "0|0")
	schema:register(XMLValueType.STRING, key .. ".outerRim#nodeLeft", "Outer rim node left index in i3d file", "0|0")
	schema:register(XMLValueType.STRING, key .. ".outerRim#nodeRight", "Outer rim node right index in i3d file", "0|0")
	schema:register(XMLValueType.VECTOR_2, key .. ".outerRim#widthAndDiam", "Width and diameter")
	schema:register(XMLValueType.VECTOR_SCALE, key .. ".outerRim#scale", "Outer rim scale")
	schema:register(XMLValueType.STRING, key .. ".innerRim#filename", "Path to inner rim i3d file")
	schema:register(XMLValueType.STRING, key .. ".innerRim#node", "Inner rim node index in i3d file", "0|0")
	schema:register(XMLValueType.STRING, key .. ".innerRim#nodeLeft", "Inner rim node left index in i3d file")
	schema:register(XMLValueType.STRING, key .. ".innerRim#nodeRight", "Inner rim node right index in i3d file")
	schema:register(XMLValueType.VECTOR_2, key .. ".innerRim#widthAndDiam", "Width and diameter")
	schema:register(XMLValueType.FLOAT, key .. ".innerRim#offset", "Inner rim offset", 0)
	schema:register(XMLValueType.VECTOR_SCALE, key .. ".innerRim#scale", "Inner rim scale")
	schema:register(XMLValueType.STRING, key .. ".additional#filename", "Path to additional i3d")
	schema:register(XMLValueType.STRING, key .. ".additional#node", "Additional node index in i3d file")
	schema:register(XMLValueType.STRING, key .. ".additional#nodeLeft", "Additional node left index in i3d file")
	schema:register(XMLValueType.STRING, key .. ".additional#nodeRight", "Additional node right index in i3d file")
	schema:register(XMLValueType.FLOAT, key .. ".additional#offset", "Additional node offset", 0)
	schema:register(XMLValueType.VECTOR_SCALE, key .. ".additional#scale", "Additional node scale")
	schema:register(XMLValueType.FLOAT, key .. ".additional#mass", "Additional mass (to.)")
	schema:register(XMLValueType.VECTOR_2, key .. ".additional#widthAndDiam", "Width and diameter")
end

function Wheels.registerWheelPhysicsDataXMLPaths(schema, key)
	schema:register(XMLValueType.NODE_INDEX, key .. ".physics#driveNode", "Drive node")
	schema:register(XMLValueType.NODE_INDEX, key .. ".physics#linkNode", "Link node")
	schema:register(XMLValueType.FLOAT, key .. ".physics#yOffset", "Y offset", 0)
	schema:register(XMLValueType.BOOL, key .. ".physics#showSteeringAngle", "Show steering angle", true)
	schema:register(XMLValueType.FLOAT, key .. ".physics#suspTravel", "Suspension travel", 0.01)
	schema:register(XMLValueType.FLOAT, key .. ".physics#initialCompression", "Initial compression value")
	schema:register(XMLValueType.FLOAT, key .. ".physics#deltaY", "Delta Y", 0)
	schema:register(XMLValueType.FLOAT, key .. ".physics#spring", "Spring", 0)
	schema:register(XMLValueType.FLOAT, key .. ".physics#brakeFactor", "Brake factor", 1)
	schema:register(XMLValueType.FLOAT, key .. ".physics#autoHoldBrakeFactor", "Auto hold brake factor", "brakeFactor")
	schema:register(XMLValueType.FLOAT, key .. ".physics#damper", "Damper", 0)
	schema:register(XMLValueType.FLOAT, key .. ".physics#damperCompressionLowSpeed", "Damper compression on low speeds")
	schema:register(XMLValueType.FLOAT, key .. ".physics#damperCompressionHighSpeed", "Damper compression on high speeds")
	schema:register(XMLValueType.FLOAT, key .. ".physics#damperCompressionLowSpeedThreshold", "Damper compression on low speeds threshold", 0.1016)
	schema:register(XMLValueType.FLOAT, key .. ".physics#damperRelaxationLowSpeed", "Damper relaxation on low speeds")
	schema:register(XMLValueType.FLOAT, key .. ".physics#damperRelaxationHighSpeed", "Damper relaxation on high speeds")
	schema:register(XMLValueType.FLOAT, key .. ".physics#damperRelaxationLowSpeedThreshold", "Damper relaxation on low speeds threshold", 0.1524)
	schema:register(XMLValueType.FLOAT, key .. ".physics#forcePointRatio", "Force point ratio", 0)
	schema:register(XMLValueType.INT, key .. ".physics#driveMode", "Drive mode", 0)
	schema:register(XMLValueType.FLOAT, key .. ".physics#xOffset", "X axis offset", 0)
	schema:register(XMLValueType.FLOAT, key .. ".physics#transRatio", "Suspension translation ratio between repr and drive node", 0)
	schema:register(XMLValueType.BOOL, key .. ".physics#isSynchronized", "Wheel is synchronized in multiplayer", true)
	schema:register(XMLValueType.INT, key .. ".physics#tipOcclusionAreaGroupId", "Tip occlusion area group id")
	schema:register(XMLValueType.BOOL, key .. ".physics#useReprDirection", "Use repr direction instead of component direction", false)
	schema:register(XMLValueType.BOOL, key .. ".physics#useDriveNodeDirection", "Use drive node direction instead of component direction", false)
	schema:register(XMLValueType.FLOAT, key .. ".physics#mass", "Wheel mass (to.)")
	schema:register(XMLValueType.FLOAT, key .. ".physics#radius", "Wheel radius", 0.5)
	schema:register(XMLValueType.FLOAT, key .. ".physics#width", "Wheel width", 0.6)
	schema:register(XMLValueType.FLOAT, key .. ".physics#widthOffset", "Wheel width offset", 0)
	schema:register(XMLValueType.FLOAT, key .. ".physics#restLoad", "Wheel load while resting", 1)
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxLongStiffness", "Max. longitude stiffness")
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxLatStiffness", "Max. latitude stiffness")
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxLatStiffnessLoad", "Max. latitude stiffness load")
	schema:register(XMLValueType.FLOAT, key .. ".physics#frictionScale", "Wheel friction scale", 1)
	schema:register(XMLValueType.FLOAT, key .. ".physics#rotationDamping", "Rotation damping ", "mass * 0.035")
	schema:register(XMLValueType.STRING, key .. ".physics#tireType", "Tire type (mud, offRoad, street, crawler)")
	schema:register(XMLValueType.FLOAT, key .. ".physics#fieldDirtMultiplier", "Field dirt multiplier", 75)
	schema:register(XMLValueType.FLOAT, key .. ".physics#streetDirtMultiplier", "Street dirt multiplier", -150)
	schema:register(XMLValueType.FLOAT, key .. ".physics#minDirtPercentage", "Min. dirt scale while cleaning on street drive", 0.35)
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxDirtOffset", "Max. dirt amount offset to global dirt node", 0.5)
	schema:register(XMLValueType.FLOAT, key .. ".physics#dirtColorChangeSpeed", "Defines speed to change the dirt color (sec)", 20)
	schema:register(XMLValueType.FLOAT, key .. ".physics#smoothGroundRadius", "Smooth ground radius", "width * 0.75")
	schema:register(XMLValueType.BOOL, key .. ".physics#versatileYRot", "Do versatile Y rotation", false)
	schema:register(XMLValueType.BOOL, key .. ".physics#forceVersatility", "Force versatility, also if no ground contact", false)
	schema:register(XMLValueType.BOOL, key .. ".physics#supportsWheelSink", "Supports wheel sink in field", true)
	schema:register(XMLValueType.FLOAT, key .. ".physics#maxWheelSink", "Max. wheel sink in fields", 0.5)
	schema:register(XMLValueType.ANGLE, key .. ".physics#rotSpeed", "Rotation speed")
	schema:register(XMLValueType.ANGLE, key .. ".physics#rotSpeedNeg", "Rotation speed in negative direction")
	schema:register(XMLValueType.ANGLE, key .. ".physics#rotMax", "Max. rotation")
	schema:register(XMLValueType.ANGLE, key .. ".physics#rotMin", "Min. rotation")
	schema:register(XMLValueType.ANGLE, key .. ".physics#rotSpeedLimit", "Rotation speed limit")
end

function Wheels.registerWheelSteeringDataXMLPaths(schema, key)
	schema:register(XMLValueType.NODE_INDEX, key .. ".steering#node", "Steering node")
	schema:register(XMLValueType.NODE_INDEX, key .. ".steering#rotNode", "Steering rot node")
	schema:register(XMLValueType.FLOAT, key .. ".steering#nodeMinTransX", "Min. X translation")
	schema:register(XMLValueType.FLOAT, key .. ".steering#nodeMaxTransX", "Max. X translation")
	schema:register(XMLValueType.ANGLE, key .. ".steering#nodeMinRotY", "Min. Y rotation")
	schema:register(XMLValueType.ANGLE, key .. ".steering#nodeMaxRotY", "Max. Y rotation")
	schema:register(XMLValueType.NODE_INDEX, key .. ".fender(?)#node", "Fender node")
	schema:register(XMLValueType.ANGLE, key .. ".fender(?)#rotMax", "Max. rotation")
	schema:register(XMLValueType.ANGLE, key .. ".fender(?)#rotMin", "Min. rotation")
	schema:register(XMLValueType.FLOAT, key .. ".steeringAxle#scale", "Steering axle scale")
	schema:register(XMLValueType.ANGLE, key .. ".steeringAxle#rotMax", "Max. rotation")
	schema:register(XMLValueType.ANGLE, key .. ".steeringAxle#rotMin", "Min. rotation")
end

function Wheels.registerWheelAdditionalWheelsXMLPaths(schema, key)
	schema:register(XMLValueType.STRING, key .. "#filename", "Filename")
	schema:register(XMLValueType.STRING, key .. "#configId", "Config id", "default")
	schema:register(XMLValueType.BOOL, key .. "#isLeft", "Is left wheel", false)
	schema:register(XMLValueType.ANGLE, key .. "#xRotOffset", "X Rotation offset", 0)
	schema:register(XMLValueType.COLOR, key .. "#color", "Color")
	schema:register(XMLValueType.BOOL, key .. "#hasParticles", "Has particles", false)
	schema:register(XMLValueType.BOOL, key .. "#hasTireTracks", "Has tire tracks", false)
	schema:register(XMLValueType.FLOAT, key .. "#offset", "X Offset", 0)
	Wheels.registerConnectorXMLPaths(schema, key .. ".connector")
	Wheels.registerWheelParticleSystemXMLPaths(schema, key .. ".wheelParticleSystem")
end

function Wheels.registerConnectorXMLPaths(schema, key)
	schema:register(XMLValueType.STRING, key .. "#filename", "Path to connector i3d or xml file")
	schema:register(XMLValueType.STRING, key .. "#node", "Node in connector i3d file if i3d file is linked instead of xml")
	schema:register(XMLValueType.BOOL, key .. "#useWidthAndDiam", "Use width and diameter from connector definition", false)
	schema:register(XMLValueType.BOOL, key .. "#usePosAndScale", "Use position and scale from connector definition", false)
	schema:register(XMLValueType.FLOAT, key .. "#diameter", "Diameter for shader")
	schema:register(XMLValueType.FLOAT, key .. "#offset", "Additional connector X offset", 0)
	schema:register(XMLValueType.FLOAT, key .. "#width", "Width for shader")
	schema:register(XMLValueType.FLOAT, key .. "#startPos", "Start pos for shader")
	schema:register(XMLValueType.FLOAT, key .. "#endPos", "End pos for shader")
	schema:register(XMLValueType.FLOAT, key .. "#uniformScale", "Uniform scale for shader")
	schema:register(XMLValueType.COLOR, key .. "#color", "Connector color")
end

function Wheels.registerWheelChockXMLPaths(schema, key)
	schema:register(XMLValueType.STRING, key .. "#filename", "Path to wheel chock i3d", "$data/shared/assets/wheelChocks/wheelChock01.i3d")
	schema:register(XMLValueType.VECTOR_SCALE, key .. "#scale", "Scale", "1 1 1")
	schema:register(XMLValueType.NODE_INDEX, key .. "#parkingNode", "Parking node")
	schema:register(XMLValueType.BOOL, key .. "#isInverted", "Is inverted (In front or back of the wheel)", false)
	schema:register(XMLValueType.BOOL, key .. "#isParked", "Default is parked", false)
	schema:register(XMLValueType.VECTOR_TRANS, key .. "#offset", "Translation offset", "0 0 0")
	schema:register(XMLValueType.COLOR, key .. "#color", "Color")
	schema:register(XMLValueType.INT, key .. "#material", "Material")
end

function Wheels.registerWheelParticleSystemXMLPaths(schema, key)
	schema:register(XMLValueType.VECTOR_TRANS, key .. "#psOffset", "Translation offset", "0 0 0")
	schema:register(XMLValueType.FLOAT, key .. "#minSpeed", "Min. speed for activation", 3)
	schema:register(XMLValueType.FLOAT, key .. "#maxSpeed", "Max. speed for activation", 20)
	schema:register(XMLValueType.FLOAT, key .. "#minScale", "Min. scale", 0.1)
	schema:register(XMLValueType.FLOAT, key .. "#maxScale", "Max. scale", 1)
	schema:register(XMLValueType.INT, key .. "#direction", "Moving direction for activation", 0)
	schema:register(XMLValueType.BOOL, key .. "#onlyActiveOnGroundContact", "Only active while wheel has ground contact", true)
end

function Wheels.registerAckermannSteeringXMLPaths(schema, key)
	schema:register(XMLValueType.FLOAT, key .. "#rotSpeed", "Rotation speed")
	schema:register(XMLValueType.FLOAT, key .. "#rotMax", "Max. rotation")
	schema:register(XMLValueType.INT, key .. "#rotCenterWheel1", "Rotation center wheel 1")
	schema:register(XMLValueType.INT, key .. "#rotCenterWheel2", "Rotation center wheel 2")
	schema:register(XMLValueType.NODE_INDEX, key .. "#rotCenterNode", "Rotation center node (Used if rotCenterWheelX not given)")
	schema:register(XMLValueType.VECTOR_2, key .. "#rotCenter", "Center position (from root component) (Used if rotCenterWheelX not given)")
end

function Wheels:onLoad(savegame)
	local spec = self.spec_wheels
	spec.sharedLoadRequestIds = {}

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.driveGroundParticleSystems", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#hasParticles")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheelConfigurations.wheelConfiguration", "vehicle.wheels.wheelConfigurations.wheelConfiguration")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.rimColor", "vehicle.wheels.rimColor")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.hubColor", "vehicle.wheels.hubs.color0")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.dynamicallyLoadedWheels", "vehicle.wheels.dynamicallyLoadedWheels")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ackermannSteeringConfigurations", "vehicle.wheels.ackermannSteeringConfigurations")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheel", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheelConfigurations.wheelConfiguration.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#repr", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel.physics#repr")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#configIndex", "vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel#configId")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ackermannSteering", "vehicle.wheels.ackermannSteeringConfigurations.ackermannSteering")

	spec.configurationSaveIdToIndex, spec.configurationIndexToBaseConfig = Wheels.createConfigSaveIdMapping(self.xmlFile)
	spec.lastWheelConfigIndex = self.configurations.wheel
	local wheelConfigurationId = self.configurations.wheel or 1
	local configKey = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", wheelConfigurationId - 1)
	local wheelsKey = configKey .. ".wheels"

	if self.configurations.wheel ~= nil and not self.xmlFile:hasProperty(wheelsKey) then
		Logging.xmlWarning(self.xmlFile, "Invalid wheelConfigurationId '%d'. Using default wheel config instead!", self.configurations.wheel)

		wheelConfigurationId = 1
		configKey = "vehicle.wheels.wheelConfigurations.wheelConfiguration(0)"
		wheelsKey = configKey .. ".wheels"
	end

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.wheels.wheelConfigurations.wheelConfiguration", wheelConfigurationId, self.components, self)

	spec.rimColor = self.xmlFile:getValue("vehicle.wheels.rimColor", nil, true)

	if spec.rimColor == nil and self.xmlFile:getValue("vehicle.wheels.rimColor#useBaseColor") then
		spec.rimColor = ConfigurationUtil.getColorByConfigId(self, "baseColor", self.configurations.baseColor) or ConfigurationUtil.getColorByConfigId(self, "baseMaterial", self.configurations.baseMaterial)
	end

	if spec.rimColor ~= nil then
		spec.rimColor[4] = self.xmlFile:getValue("vehicle.wheels.rimColor#material")
	end

	spec.overwrittenWheelColors = {
		_rimColor = {}
	}

	for i = 1, 8 do
		spec.overwrittenWheelColors[string.format("_hubColor%d", i - 1)] = {}
	end

	ConfigurationUtil.getOverwrittenMaterialColors(self, self.xmlFile, spec.overwrittenWheelColors)

	local overwrittenRimColor = spec.overwrittenWheelColors._rimColor

	if #overwrittenRimColor > 0 then
		if spec.rimColor == nil then
			spec.rimColor = overwrittenRimColor
		else
			spec.rimColor[3] = overwrittenRimColor[3]
			spec.rimColor[2] = overwrittenRimColor[2]
			spec.rimColor[1] = overwrittenRimColor[1]

			if #overwrittenRimColor == 4 then
				spec.rimColor[4] = overwrittenRimColor[4]
			end
		end
	end

	self:loadHubsFromXML()

	self.maxRotTime = 0
	self.minRotTime = 0
	self.rotatedTimeInterpolator = InterpolatorValue.new(0)
	self.autoRotateBackSpeed = self:getWheelConfigurationValue(self.xmlFile, wheelConfigurationId, configKey, ".wheels#autoRotateBackSpeed", 1)
	self.speedDependentRotateBack = self:getWheelConfigurationValue(self.xmlFile, wheelConfigurationId, configKey, ".wheels#speedDependentRotateBack", true)
	self.differentialIndex = self:getWheelConfigurationValue(self.xmlFile, wheelConfigurationId, configKey, ".wheels#differentialIndex")
	spec.ackermannSteeringIndex = self:getWheelConfigurationValue(self.xmlFile, wheelConfigurationId, configKey, ".wheels#ackermannSteeringIndex")
	spec.wheelSmoothAccumulation = 0
	spec.wheelCreationTimer = 0
	spec.currentUpdateIndex = 1
	spec.maxUpdateIndex = 1
	spec.wheels = {}
	spec.wheelsByNode = {}
	spec.wheelChocks = {}
	spec.tireTrackNodes = {}
	local i = 0

	while true do
		local wheelKey = string.format(".wheels.wheel(%d)", i)

		if not self.xmlFile:hasProperty(configKey .. wheelKey) then
			break
		end

		local wheel = {
			xmlIndex = i,
			updateIndex = i % 4 + 1,
			configIndex = wheelConfigurationId
		}

		if self:loadWheelFromXML(self.xmlFile, configKey, wheelKey, wheel) then
			self:finalizeWheel(wheel)

			spec.maxUpdateIndex = math.max(spec.maxUpdateIndex, wheel.updateIndex)

			table.insert(spec.wheels, wheel)
		end

		i = i + 1
	end

	if self.xmlFile:getValue(wheelsKey .. "#hasSurfaceSounds", true) then
		local surfaceSoundLinkNode = self.xmlFile:getValue(wheelsKey .. "#surfaceSoundLinkNode", self.components[1].node, self.components, self.i3dMappings)
		local tireTypeName = ""

		if #spec.wheels > 0 and spec.wheels[1].tireType ~= nil then
			tireTypeName = WheelsUtil.getTireTypeName(spec.wheels[1].tireType)
		end

		tireTypeName = self.xmlFile:getValue(wheelsKey .. "#surfaceSoundTireType", tireTypeName)
		spec.surfaceSounds = {}
		spec.surfaceIdToSound = {}
		spec.surfaceNameToSound = {}
		spec.currentSurfaceSound = nil

		local function addSurfaceSound(surfaceSound)
			local sample = g_soundManager:cloneSample(surfaceSound.sample, surfaceSoundLinkNode, self)
			sample.sampleName = surfaceSound.name

			table.insert(spec.surfaceSounds, sample)

			spec.surfaceIdToSound[surfaceSound.materialId] = sample
			spec.surfaceNameToSound[surfaceSound.name] = sample
		end

		local surfaceSounds = g_currentMission.surfaceSounds

		for j = 1, #surfaceSounds do
			local surfaceSound = surfaceSounds[j]

			if surfaceSound.type:lower() == ("wheel_" .. tireTypeName):lower() then
				addSurfaceSound(surfaceSound)
			end
		end

		for j = 1, #surfaceSounds do
			local surfaceSound = surfaceSounds[j]

			if spec.surfaceNameToSound[surfaceSound.name] == nil and surfaceSound.type == "wheel" then
				addSurfaceSound(surfaceSound)
			end
		end
	end

	spec.dynamicallyLoadedWheels = {}
	i = 0

	while true do
		local baseName = string.format("vehicle.wheels.dynamicallyLoadedWheels.dynamicallyLoadedWheel(%d)", i)

		if not self.xmlFile:hasProperty(baseName) then
			break
		end

		XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseName .. "#configIndex", baseName .. "#configId")

		local dynamicallyLoadedWheel = {}

		if self:loadNonPhysicalWheelFromXML(dynamicallyLoadedWheel, self.xmlFile, baseName) then
			table.insert(spec.dynamicallyLoadedWheels, dynamicallyLoadedWheel)
		end

		i = i + 1
	end

	spec.networkTimeInterpolator = InterpolationTime.new(1.2)
	local numWheels = #spec.wheels

	for iWheel = 1, numWheels do
		local wheel1 = spec.wheels[iWheel]

		if wheel1.oppositeWheelIndex == nil then
			for jWheel = 1, numWheels do
				if iWheel ~= jWheel then
					local wheel2 = spec.wheels[jWheel]

					if math.abs(wheel1.positionX + wheel2.positionX) < 0.1 and math.abs(wheel1.positionZ - wheel2.positionZ) < 0.1 and math.abs(wheel1.positionY - wheel2.positionY) < 0.1 then
						wheel1.oppositeWheelIndex = jWheel
						wheel2.oppositeWheelIndex = iWheel

						break
					end
				end
			end
		end
	end

	self:loadAckermannSteeringFromXML(self.xmlFile, spec.ackermannSteeringIndex)
	SpecializationUtil.raiseEvent(self, "onFinishedWheelLoading", self.xmlFile, wheelsKey)

	spec.wheelSinkActive = Platform.gameplay.wheelSink
	spec.wheelDensityHeightSmoothActive = Platform.gameplay.wheelDensityHeightSmooth
	spec.wheelVisualPressureActive = Platform.gameplay.wheelVisualPressure
	spec.tyreTracksSegmentsCoeff = getTyreTracksSegmentsCoeff()
	spec.snowSystem = g_currentMission.snowSystem
	spec.fieldGroundSystem = g_currentMission.fieldGroundSystem
	spec.tireTrackGroundGrassValue = spec.fieldGroundSystem:getFieldGroundValue(FieldGroundType.GRASS)
	spec.tireTrackGroundGrassCutValue = spec.fieldGroundSystem:getFieldGroundValue(FieldGroundType.GRASS_CUT)
	spec.brakePedal = 0
	spec.forceIsActiveTime = 3000
	spec.forceIsActiveTimer = 0
	spec.dirtyFlag = self:getNextDirtyFlag()
end

function Wheels:onLoadFinished(savegame)
	self:updateWheelChocksPosition(nil, true)

	if self.isServer then
		local spec = self.spec_wheels

		for _, wheel in pairs(spec.wheels) do
			self.defaultMass = self.defaultMass + wheel.mass

			if wheel.wheelTire ~= nil and wheel.wheelShapeWidthTmp ~= nil then
				local wheelX, _, _ = getTranslation(wheel.wheelTire)
				local additionalWheelX = wheelX + wheel.wheelShapeWidthTotalOffset
				wheel.wheelShapeWidth = wheel.wheelShapeWidthTmp + math.abs(wheelX - additionalWheelX)
				wheel.wheelShapeWidthTmp = nil

				setWheelShapeWidth(wheel.node, wheel.wheelShape, wheel.wheelShapeWidth, wheel.widthOffset)
			end
		end

		if savegame ~= nil and not savegame.resetVehicles then
			local lastWheelConfiguration = savegame.xmlFile:getValue(savegame.key .. ".wheels#lastWheelConfiguration", 1)

			if lastWheelConfiguration ~= self.configurations.wheel then
				for _, wheel in pairs(spec.wheels) do
					local washableNode = self:getWashableNodeByCustomIndex(wheel)

					if washableNode ~= nil then
						self:setNodeDirtAmount(washableNode, 0, true)
					end
				end

				SpecializationUtil.raiseEvent(self, "onWheelConfigurationChanged", lastWheelConfiguration, self.configurations.wheel)
			end
		end
	end
end

function Wheels:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_wheels

	xmlFile:setValue(key .. "#lastWheelConfiguration", spec.lastWheelConfigIndex or 1)
end

function Wheels:onDelete()
	local spec = self.spec_wheels

	if spec.sharedLoadRequestIds ~= nil then
		for _, sharedLoadRequestId in pairs(spec.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
		end
	end

	if spec.hubs ~= nil then
		for _, hub in pairs(spec.hubs) do
			delete(hub.node)
		end
	end

	if spec.wheels ~= nil then
		for _, wheel in pairs(spec.wheels) do
			if wheel.driveGroundParticleSystems ~= nil then
				for _, ps in pairs(wheel.driveGroundParticleSystems) do
					ParticleUtil.deleteParticleSystems(ps)
				end
			end

			if wheel.additionalWheels ~= nil then
				for _, additionalWheel in pairs(wheel.additionalWheels) do
					if additionalWheel.driveGroundParticleSystems ~= nil then
						for _, ps in pairs(additionalWheel.driveGroundParticleSystems) do
							ParticleUtil.deleteParticleSystems(ps)
						end
					end
				end
			end
		end
	end

	if spec.tireTrackNodes ~= nil then
		for i = 1, #spec.tireTrackNodes do
			local tireTrackNode = spec.tireTrackNodes[i]

			self.tireTrackSystem:destroyTrack(tireTrackNode.tireTrackIndex)
		end
	end

	if spec.wheelChocks ~= nil then
		for _, wheelChock in pairs(spec.wheelChocks) do
			if wheelChock.node ~= nil then
				delete(wheelChock.node)

				wheelChock.node = nil
			end
		end
	end

	g_soundManager:deleteSamples(spec.surfaceSounds)

	spec.snowSystem = nil
	spec.fieldGroundSystem = nil
end

function Wheels:onReadStream(streamId, connection)
	if connection.isServer then
		local spec = self.spec_wheels

		spec.networkTimeInterpolator:reset()

		for i = 1, #spec.wheels do
			local wheel = spec.wheels[i]

			if wheel.isSynchronized then
				self:readWheelDataFromStream(wheel, streamId, true)
			end
		end

		self.rotatedTimeInterpolator:setValue(0)
	end
end

function Wheels:onWriteStream(streamId, connection)
	if not connection.isServer then
		local spec = self.spec_wheels

		for i = 1, #spec.wheels do
			local wheel = spec.wheels[i]

			if wheel.isSynchronized then
				self:writeWheelDataToStream(wheel, streamId)
			end
		end
	end
end

function Wheels:onReadUpdateStream(streamId, timestamp, connection)
	if connection.isServer then
		local hasUpdate = streamReadBool(streamId)

		if hasUpdate then
			local spec = self.spec_wheels

			spec.networkTimeInterpolator:startNewPhaseNetwork()

			for i = 1, #spec.wheels do
				local wheel = spec.wheels[i]

				if wheel.isSynchronized then
					self:readWheelDataFromStream(wheel, streamId, false)
				end
			end

			if self.maxRotTime ~= 0 and self.minRotTime ~= 0 then
				local rotatedTimeRange = math.max(self.maxRotTime - self.minRotTime, 0.001)
				local rotatedTime = streamReadUIntN(streamId, 8)

				if math.abs(self.rotatedTime) < 0.001 then
					self.rotatedTime = 0
				end

				local rotatedTimeTarget = rotatedTime / 255 * rotatedTimeRange + self.minRotTime

				self.rotatedTimeInterpolator:setTargetValue(rotatedTimeTarget)
			end
		end
	end
end

function Wheels:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection.isServer then
		local spec = self.spec_wheels

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			for i = 1, #spec.wheels do
				local wheel = spec.wheels[i]

				if wheel.isSynchronized then
					self:writeWheelDataToStream(wheel, streamId)
				end
			end

			if self.maxRotTime ~= 0 and self.minRotTime ~= 0 then
				local rotatedTimeRange = math.max(self.maxRotTime - self.minRotTime, 0.001)
				local rotatedTime = MathUtil.clamp(math.floor((self.rotatedTime - self.minRotTime) / rotatedTimeRange * 255), 0, 255)

				streamWriteUIntN(streamId, rotatedTime, 8)
			end
		end
	end
end

function Wheels:readWheelDataFromStream(wheel, streamId, updateInterpolation)
	local xDrive = streamReadUIntN(streamId, 9)
	xDrive = xDrive / 511 * math.pi * 2

	if updateInterpolation then
		wheel.netInfo.xDrive = xDrive

		wheel.networkInterpolators.xDrive:setAngle(xDrive)
	else
		wheel.networkInterpolators.xDrive:setTargetAngle(xDrive)
	end

	local y = streamReadUIntN(streamId, 8)
	y = y / 255 * wheel.netInfo.sync.yRange + wheel.netInfo.sync.yMin

	if updateInterpolation then
		wheel.netInfo.y = y

		wheel.networkInterpolators.position:setPosition(wheel.netInfo.x, y, wheel.netInfo.z)
	else
		wheel.networkInterpolators.position:setTargetPosition(wheel.netInfo.x, y, wheel.netInfo.z)
	end

	local suspLength = streamReadUIntN(streamId, 7)

	if updateInterpolation then
		wheel.netInfo.suspensionLength = suspLength / 100

		wheel.networkInterpolators.suspensionLength:setValue(suspLength / 100)
	else
		wheel.networkInterpolators.suspensionLength:setTargetValue(suspLength / 100)
	end

	if wheel.syncContactState then
		wheel.contact = streamReadUIntN(streamId, 2)
		wheel.lastContactObjectAllowsTireTracks = streamReadBool(streamId)
	end

	if wheel.versatileYRot then
		local yRot = streamReadUIntN(streamId, 9)
		wheel.steeringAngle = yRot / 511 * math.pi * 2
	end

	wheel.lastTerrainValue = streamReadUIntN(streamId, 3)
end

function Wheels:writeWheelDataToStream(wheel, streamId)
	local xDrive = wheel.netInfo.xDrive % (math.pi * 2)

	streamWriteUIntN(streamId, MathUtil.clamp(math.floor(xDrive / (math.pi * 2) * 511), 0, 511), 9)
	streamWriteUIntN(streamId, MathUtil.clamp(math.floor((wheel.netInfo.y - wheel.netInfo.sync.yMin) / wheel.netInfo.sync.yRange * 255), 0, 255), 8)
	streamWriteUIntN(streamId, MathUtil.clamp(wheel.netInfo.suspensionLength * 100, 0, 128), 7)

	if wheel.syncContactState then
		streamWriteUIntN(streamId, wheel.contact, 2)
		streamWriteBool(streamId, wheel.lastContactObjectAllowsTireTracks)
	end

	if wheel.versatileYRot then
		local yRot = wheel.steeringAngle % (math.pi * 2)

		streamWriteUIntN(streamId, MathUtil.clamp(math.floor(yRot / (math.pi * 2) * 511), 0, 511), 9)
	end

	streamWriteUIntN(streamId, wheel.lastTerrainValue, 3)
end

function Wheels:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_wheels

	if self.isServer and spec.wheelCreationTimer > 0 then
		spec.wheelCreationTimer = spec.wheelCreationTimer - 1

		if spec.wheelCreationTimer == 0 then
			for _, wheel in pairs(spec.wheels) do
				wheel.wheelShapeCreated = true
			end
		end
	end

	if not self.isServer and self.isClient then
		spec.networkTimeInterpolator:update(dt)

		local interpolationAlpha = spec.networkTimeInterpolator:getAlpha()
		self.rotatedTime = self.rotatedTimeInterpolator:getInterpolatedValue(interpolationAlpha)

		for i = 1, table.getn(spec.wheels) do
			local wheel = spec.wheels[i]
			wheel.netInfo.x, wheel.netInfo.y, wheel.netInfo.z = wheel.networkInterpolators.position:getInterpolatedValues(interpolationAlpha)
			wheel.netInfo.xDrive = wheel.networkInterpolators.xDrive:getInterpolatedValue(interpolationAlpha)
			wheel.netInfo.suspensionLength = wheel.networkInterpolators.suspensionLength:getInterpolatedValue(interpolationAlpha)

			if wheel.driveGroundParticleSystems ~= nil then
				for _, typedPs in pairs(wheel.driveGroundParticleSystems) do
					for _, ps in ipairs(typedPs) do
						setTranslation(ps.emitterShape, wheel.netInfo.x + ps.offsets[1], wheel.netInfo.y + ps.offsets[2], wheel.netInfo.z + ps.offsets[3])
					end
				end
			end
		end

		if spec.networkTimeInterpolator:isInterpolating() then
			self:raiseActive()
		end
	end

	local numWheels = #spec.wheels

	if self.finishedFirstUpdate then
		local groundWetness = g_currentMission.environment.weather:getGroundWetness()

		for i = 1, numWheels do
			local wheel = spec.wheels[i]

			if self.isActive then
				if spec.currentUpdateIndex == wheel.updateIndex then
					self:updateWheelContact(wheel)
				end

				if spec.wheelSinkActive then
					self:updateWheelSink(wheel, dt, groundWetness)
				end

				self:updateWheelFriction(wheel, dt, groundWetness)

				if spec.wheelDensityHeightSmoothActive then
					self:updateWheelDensityMapHeight(wheel, dt)
				end

				WheelsUtil.updateWheelPhysics(self, wheel, spec.brakePedal, dt)
			end

			if self.isServer and self.isAddedToPhysics then
				WheelsUtil.updateWheelNetInfo(self, wheel)
			end

			if self.currentUpdateDistance < Wheels.VISUAL_WHEEL_UPDATE_DISTANCE then
				local changed = WheelsUtil.updateWheelGraphics(self, wheel, dt)

				if wheel.updateWheelChock and changed then
					for j = 1, #wheel.wheelChocks do
						self:updateWheelChockPosition(wheel.wheelChocks[j], false)
					end
				end
			end
		end

		spec.currentUpdateIndex = spec.currentUpdateIndex + 1

		if spec.maxUpdateIndex < spec.currentUpdateIndex then
			spec.currentUpdateIndex = 1
		end

		local numTireTrackNodes = #spec.tireTrackNodes

		if numTireTrackNodes > 0 then
			local allowTireTracks = self:getAllowTireTracks()

			for i = 1, numTireTrackNodes do
				local tireTrackNode = spec.tireTrackNodes[i]

				self:updateTireTrackNode(tireTrackNode, allowTireTracks, groundWetness)
			end
		end

		if numWheels > 0 and g_currentMission.missionInfo.fruitDestruction and not self:getIsAIActive() and (self.getBlockFoliageDestruction == nil or not self:getBlockFoliageDestruction()) then
			for i = 1, numWheels do
				local wheel = spec.wheels[i]

				self:updateWheelDestruction(wheel, dt)
			end
		end

		if self:getAreSurfaceSoundsActive() then
			if spec.surfaceSounds ~= nil then
				local currentSound = self:getCurrentSurfaceSound()

				if currentSound ~= spec.currentSurfaceSound then
					if spec.currentSurfaceSound ~= nil then
						g_soundManager:stopSample(spec.currentSurfaceSound)
					end

					if currentSound ~= nil then
						g_soundManager:playSample(currentSound)
					end

					spec.currentSurfaceSound = currentSound
				elseif not g_soundManager:getIsSamplePlaying(currentSound) then
					g_soundManager:playSample(currentSound)
				end
			end
		elseif spec.currentSurfaceSound ~= nil then
			g_soundManager:stopSample(spec.currentSurfaceSound)
		end
	end

	if numWheels > 0 and self.isServer then
		self:raiseDirtyFlags(spec.dirtyFlag)
	end
end

function Wheels:onPostUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isServer then
		local spec = self.spec_wheels

		for _, wheel in ipairs(spec.wheels) do
			if wheel.isPositionDirty then
				self:updateWheelBase(wheel)

				wheel.isPositionDirty = false
			end

			if wheel.isFrictionDirty then
				self:updateWheelTireFriction(wheel)

				wheel.isFrictionDirty = false
			end
		end
	end
end

function Wheels:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_wheels

	for _, wheel in pairs(spec.wheels) do
		if wheel.rotSpeedLimit ~= nil then
			local dir = -1

			if self:getLastSpeed() <= wheel.rotSpeedLimit then
				dir = 1
			end

			wheel.currentRotSpeedAlpha = MathUtil.clamp(wheel.currentRotSpeedAlpha + dir * dt / 1000, 0, 1)
			wheel.rotSpeed = wheel.rotSpeedDefault * wheel.currentRotSpeedAlpha
			wheel.rotSpeedNeg = wheel.rotSpeedNegDefault * wheel.currentRotSpeedAlpha
		end
	end

	if self.isClient then
		local speed = self:getLastSpeed()
		local groundWetness = g_currentMission.environment.weather:getGroundWetness()
		local groundIsWet = groundWetness > 0.2

		for _, wheel in pairs(spec.wheels) do
			if wheel.driveGroundParticleSystems ~= nil then
				local states = wheel.driveGroundParticleStates
				local enableSoilPS = false

				if wheel.lastTerrainValue > 0 and wheel.lastTerrainValue < 9 then
					enableSoilPS = speed > 1
				end

				local sizeScale = 2 * wheel.width * wheel.radiusOriginal
				states.wheel_dry = not wheel.hasSnowContact and enableSoilPS
				states.wheel_wet = not wheel.hasSnowContact and enableSoilPS and groundIsWet
				states.wheel_dust = not wheel.hasSnowContact and not groundIsWet
				states.wheel_snow = wheel.hasSnowContact

				for psName, state in pairs(states) do
					local typedPs = wheel.driveGroundParticleSystems[psName]

					if typedPs ~= nil then
						for _, ps in ipairs(typedPs) do
							if state then
								if self.movingDirection < 0 then
									setRotation(ps.emitterShape, 0, math.pi + wheel.steeringAngle, 0)
								else
									setRotation(ps.emitterShape, 0, wheel.steeringAngle, 0)
								end

								local scale = nil

								if psName ~= "wheel_dust" then
									local wheelSpeed = MathUtil.rpmToMps(wheel.netInfo.xDriveSpeed / (2 * math.pi) * 60, wheel.radius)
									local wheelSlip = math.pow(wheelSpeed / self.lastSpeedReal, 2.5)
									scale = self:getDriveGroundParticleSystemsScale(ps, wheelSpeed) * wheelSlip
								else
									scale = self:getDriveGroundParticleSystemsScale(ps, self.lastSpeedReal)
								end

								if ps.isTintable then
									if ps.lastColor == nil then
										ps.lastColor = {
											ps.wheel.lastColor[1],
											ps.wheel.lastColor[2],
											ps.wheel.lastColor[3]
										}
										ps.targetColor = {
											ps.wheel.lastColor[1],
											ps.wheel.lastColor[2],
											ps.wheel.lastColor[3]
										}
										ps.currentColor = {
											ps.wheel.lastColor[1],
											ps.wheel.lastColor[2],
											ps.wheel.lastColor[3]
										}
										ps.alpha = 1
									end

									if ps.alpha ~= 1 then
										ps.alpha = math.min(ps.alpha + dt / 1000, 1)
										ps.currentColor = {
											MathUtil.vector3ArrayLerp(ps.lastColor, ps.targetColor, ps.alpha)
										}

										if ps.alpha == 1 then
											ps.lastColor[1] = ps.currentColor[1]
											ps.lastColor[2] = ps.currentColor[2]
											ps.lastColor[3] = ps.currentColor[3]
										end
									end

									if ps.alpha == 1 and ps.wheel.lastColor[1] ~= ps.targetColor[1] and ps.wheel.lastColor[2] ~= ps.targetColor[2] and ps.wheel.lastColor[3] ~= ps.targetColor[3] then
										ps.alpha = 0
										ps.targetColor[1] = ps.wheel.lastColor[1]
										ps.targetColor[2] = ps.wheel.lastColor[2]
										ps.targetColor[3] = ps.wheel.lastColor[3]
									end
								end

								if scale > 0 then
									ParticleUtil.setEmittingState(ps, true)

									if ps.isTintable then
										I3DUtil.setShaderParameterRec(ps.shape, "colorAlpha", ps.currentColor[1], ps.currentColor[2], ps.currentColor[3], 1, false)
									end
								else
									ParticleUtil.setEmittingState(ps, false)
								end

								local maxSpeed = 13.88888888888889
								local circum = wheel.radiusOriginal
								local maxWheelRpm = maxSpeed / circum
								local wheelRotFactor = Utils.getNoNil(wheel.netInfo.xDriveSpeed, 0) / maxWheelRpm
								local emitScale = scale * wheelRotFactor * sizeScale

								ParticleUtil.setEmitCountScale(ps, MathUtil.clamp(emitScale, ps.minScale, ps.maxScale))

								local speedFactor = 1

								ParticleUtil.setParticleSystemSpeed(ps, ps.particleSpeed * speedFactor)
								ParticleUtil.setParticleSystemSpeedRandom(ps, ps.particleRandomSpeed * speedFactor)
							else
								ParticleUtil.setEmittingState(ps, false)
							end
						end
					end

					states[psName] = false
				end
			end
		end
	end
end

function Wheels:onUpdateEnd(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_wheels

		for _, wheel in pairs(spec.wheels) do
			if wheel.driveGroundParticleSystems ~= nil then
				for _, typedPs in pairs(wheel.driveGroundParticleSystems) do
					for _, ps in ipairs(typedPs) do
						ParticleUtil.setEmittingState(ps, false)
					end
				end
			end
		end

		if spec.currentSurfaceSound ~= nil then
			g_soundManager:stopSample(spec.currentSurfaceSound)

			spec.currentSurfaceSound = nil
		end
	end
end

function Wheels:getWheelConfigurationValue(xmlFile, configId, configurationKey, key, ...)
	local spec = self.spec_wheels

	return Wheels.getConfigurationValue(spec.configurationSaveIdToIndex, spec.configurationIndexToBaseConfig, xmlFile, configId, configurationKey, key, ...)
end

function Wheels.createConfigSaveIdMapping(xmlFile)
	local configurationSaveIdToIndex = {}
	local configurationIndexToBaseConfig = {}

	xmlFile:iterate("vehicle.wheels.wheelConfigurations.wheelConfiguration", function (index, key)
		XMLUtil.checkDeprecatedXMLElements(xmlFile, key .. ".wheels.foliageBendingModifier", key .. ".foliageBendingModifier")

		local saveId = xmlFile:getValue(key .. "#saveId", index)
		configurationSaveIdToIndex[saveId] = index
		local baseConfigId = xmlFile:getValue(key .. ".wheels#baseConfig")

		if saveId == baseConfigId then
			Logging.xmlError(xmlFile, "Wheel configuration %s references itself as baseConfig! Ignoring this reference", key)
		else
			configurationIndexToBaseConfig[index] = baseConfigId
		end
	end)

	return configurationSaveIdToIndex, configurationIndexToBaseConfig
end

function Wheels.getConfigurationValue(configurationSaveIdToIndex, configurationIndexToBaseConfig, xmlFile, configId, configurationKey, key, ...)
	local baseConfigurationIndex = nil
	local baseConfigurationName = configurationIndexToBaseConfig[configId]

	if baseConfigurationName ~= nil then
		baseConfigurationIndex = configurationSaveIdToIndex[baseConfigurationName]
	end

	local value = xmlFile:getString(configurationKey .. key)

	if value ~= nil or baseConfigurationIndex == nil then
		if value == "-" then
			return nil
		end

		return xmlFile:getValue(configurationKey .. key, ...)
	else
		return Wheels.getConfigurationValue(configurationSaveIdToIndex, configurationIndexToBaseConfig, xmlFile, baseConfigurationIndex, string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", baseConfigurationIndex - 1), key, ...)
	end
end

function Wheels:loadWheelFromXML(xmlFile, configKey, wheelKey, wheel)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, string.format("vehicle.wheels.wheel(%d)#hasTyreTracks", wheel.xmlIndex), string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel(%d)#hasTireTracks", wheel.xmlIndex))
	XMLUtil.checkDeprecatedXMLElements(xmlFile, string.format("vehicle.wheels.wheel(%d)#tyreTrackAtlasIndex", wheel.xmlIndex), string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel(%d)#tireTrackAtlasIndex", wheel.xmlIndex))
	XMLUtil.checkDeprecatedXMLElements(xmlFile, string.format("vehicle.wheels.wheel(%d)#configIndex", wheel.xmlIndex), string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel(%d)#configId", wheel.xmlIndex))

	if not self:loadWheelBaseData(xmlFile, configKey, wheelKey, wheel) then
		return false
	end

	if not self:loadWheelSharedData(xmlFile, configKey, wheelKey, wheel) then
		return false
	end

	if wheel.mass == nil then
		Logging.xmlWarning(xmlFile, "Missing 'mass' for wheel '%s'. Using default '0.1'!", configKey .. wheelKey)

		wheel.mass = 0.1
	end

	if not self:loadWheelPhysicsData(xmlFile, configKey, wheelKey, wheel) then
		return false
	end

	if not self:loadWheelSteeringData(xmlFile, configKey, wheelKey, wheel) then
		return false
	end

	if not self:loadAdditionalWheelsFromXML(xmlFile, configKey, wheelKey, wheel) then
		return false
	end

	if not self:loadWheelChocksFromXML(xmlFile, configKey, wheelKey, wheel) then
		return false
	end

	if wheel.hasParticles then
		self:loadWheelParticleSystem(xmlFile, configKey, wheelKey, wheel)
	end

	wheel.wheelShape = 0
	wheel.wheelShapeCreated = false

	return true
end

function Wheels:loadWheelBaseData(xmlFile, configKey, wheelKey, wheel)
	wheel.repr = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#repr", nil, self.components, self.i3dMappings)

	if wheel.repr == nil then
		Logging.xmlWarning(xmlFile, "Failed to load wheel! Missing repr node for wheel '%s'", configKey .. wheelKey)

		return false
	end

	wheel.color = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. "#color", nil, true)
	wheel.material = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. "#material")
	wheel.additionalColor = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. "#additionalColor", nil, true)
	wheel.additionalMaterial = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. "#additionalMaterial")
	wheel.isLeft = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. "#isLeft", true)
	wheel.hasTireTracks = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. "#hasTireTracks", false)
	wheel.hasParticles = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. "#hasParticles", false)
	local filename = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. "#filename")

	if filename ~= nil and filename ~= "" then
		local wheelConfigId = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. "#configId", "default")
		wheel.xRotOffset = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. "#xRotOffset", 0)

		self:loadWheelDataFromExternalXML(wheel, filename, wheelConfigId, true)
	end

	return true
end

function Wheels:loadWheelDataFromExternalXML(wheel, xmlFilename, wheelConfigId)
	xmlFilename = Utils.getFilename(xmlFilename, self.baseDirectory)
	local xmlFile = XMLFile.load("wheelXml", xmlFilename, Wheels.xmlSchema)

	if xmlFile ~= nil then
		local wheelKey = "wheel"
		wheel.brand = g_brandManager:getBrandByName(xmlFile:getValue(wheelKey .. ".brand"))
		wheel.name = xmlFile:getValue(wheelKey .. ".name")

		self:loadWheelSharedData(xmlFile, wheelKey, ".default", wheel, true)

		if wheelConfigId ~= nil and wheelConfigId ~= "" and wheelConfigId ~= "default" then
			local i = 0
			local wheelConfigFound = false

			while true do
				local configKey = string.format(".configurations.configuration(%d)", i)

				if not xmlFile:hasProperty(wheelKey .. configKey) then
					break
				end

				if xmlFile:getValue(wheelKey .. configKey .. "#id") == wheelConfigId then
					wheelConfigFound = true

					self:loadWheelSharedData(xmlFile, wheelKey, configKey, wheel, true)

					break
				end

				i = i + 1
			end

			if not wheelConfigFound then
				Logging.xmlError(xmlFile, "WheelConfigId '%s' not found!", wheelConfigId)

				return false
			end
		end

		xmlFile:delete()
	else
		return false
	end

	return true
end

function Wheels:loadWheelSharedData(xmlFile, configKey, wheelKey, wheel, skipConfigurations)
	local configIndex = wheel.configIndex

	if skipConfigurations == true then
		configIndex = -1
	end

	local key = "nodeLeft"

	if not wheel.isLeft then
		key = "nodeRight"
	end

	wheel.radius = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".physics#radius", wheel.radius)

	if wheel.radius == nil then
		Logging.xmlWarning(xmlFile, "No radius defined for wheel '%s'! Using default value of 0.5!", configKey .. wheelKey .. ".physics#radius")

		wheel.radius = 0.5
	end

	wheel.width = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".physics#width", wheel.width)

	if wheel.width == nil then
		Logging.xmlWarning(xmlFile, "No width defined for wheel '%s'! Using default value of 0.5!", configKey .. wheelKey .. ".physics#width")

		wheel.width = 0.5
	end

	wheel.mass = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".physics#mass", wheel.mass or 0.1)
	local tireTypeName = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".physics#tireType")

	if tireTypeName ~= nil then
		local tireType = WheelsUtil.getTireType(tireTypeName)

		if tireType ~= nil then
			wheel.tireType = tireType
		else
			Logging.xmlWarning(xmlFile, "Tire type '%s' not defined!", tireTypeName)
		end
	end

	wheel.frictionScale = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".physics#frictionScale", wheel.frictionScale)
	wheel.maxLongStiffness = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".physics#maxLongStiffness", wheel.maxLongStiffness)
	wheel.maxLatStiffness = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".physics#maxLatStiffness", wheel.maxLatStiffness)
	wheel.maxLatStiffnessLoad = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".physics#maxLatStiffnessLoad", wheel.maxLatStiffnessLoad)
	wheel.tireTrackAtlasIndex = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".tire#tireTrackAtlasIndex", wheel.tireTrackAtlasIndex or 0)
	wheel.widthOffset = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".tire#widthOffset", wheel.widthOffset or 0)
	wheel.xOffset = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".tire#xOffset", wheel.xOffset or 0)
	wheel.maxDeformation = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".tire#maxDeformation", wheel.maxDeformation or 0)
	wheel.initialDeformation = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".tire#initialDeformation", wheel.initialDeformation or math.min(0.04, wheel.maxDeformation * 0.6))
	wheel.sideDeformOffset = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".tire#sideDeformOffset", wheel.sideDeformOffset or 1)
	wheel.deformation = 0
	wheel.isCareWheel = Utils.getNoNil(self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".tire#isCareWheel", wheel.isCareWheel), true)
	wheel.smoothGroundRadius = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".physics#smoothGroundRadius", math.max(0.6, wheel.width * 0.75))
	wheel.tireFilename = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".tire#filename", wheel.tireFilename)
	wheel.tireIsInverted = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".tire#isInverted", wheel.tireIsInverted)
	wheel.tireNodeStr = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".tire#node") or self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".tire#" .. key, wheel.tireNodeStr)
	wheel.outerRimFilename = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".outerRim#filename", wheel.outerRimFilename)
	wheel.outerRimNodeStr = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".outerRim#node", nil) or self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".outerRim#" .. key, wheel.outerRimNodeStr) or "0|0"
	wheel.outerRimWidthAndDiam = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".outerRim#widthAndDiam", wheel.outerRimWidthAndDiam, true)
	wheel.outerRimScale = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".outerRim#scale", wheel.outerRimScale, true)
	wheel.innerRimFilename = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".innerRim#filename", wheel.innerRimFilename)
	wheel.innerRimNodeStr = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".innerRim#node", nil) or self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".innerRim#" .. key, wheel.innerRimNodeStr)
	wheel.innerRimWidthAndDiam = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".innerRim#widthAndDiam", wheel.innerRimWidthAndDiam, true)
	wheel.innerRimOffset = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".innerRim#offset", wheel.innerRimOffset) or 0
	wheel.innerRimScale = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".innerRim#scale", wheel.innerRimScale, true)
	wheel.additionalFilename = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".additional#filename", wheel.additionalFilename)
	wheel.additionalNodeStr = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".additional#node", nil) or self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".additional#" .. key, wheel.additionalNodeStr)
	wheel.additionalOffset = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".additional#offset", wheel.additionalOffset) or 0
	wheel.additionalScale = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".additional#scale", wheel.additionalScale, true)
	wheel.additionalMass = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".additional#mass", wheel.additionalMass) or 0
	wheel.additionalWidthAndDiam = self:getWheelConfigurationValue(xmlFile, configIndex, configKey, wheelKey .. ".additional#widthAndDiam", wheel.additionalWidthAndDiam, true)

	return true
end

function Wheels:loadWheelPhysicsData(xmlFile, configKey, wheelKey, wheel)
	wheel.node = self:getParentComponent(wheel.repr)

	if wheel.node ~= 0 then
		wheel.driveNode = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#driveNode", nil, self.components, self.i3dMappings)

		if wheel.driveNode == wheel.repr then
			Logging.xmlWarning(xmlFile, "repr and driveNode may not be equal for '%s'. Using default driveNode instead!", wheelKey)

			wheel.driveNode = nil
		end

		wheel.linkNode = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#linkNode", nil, self.components, self.i3dMappings)

		if wheel.driveNode == nil then
			local newRepr = createTransformGroup("wheelReprNode")
			local reprIndex = getChildIndex(wheel.repr)

			link(getParent(wheel.repr), newRepr, reprIndex)
			setTranslation(newRepr, getTranslation(wheel.repr))
			setRotation(newRepr, getRotation(wheel.repr))
			setScale(newRepr, getScale(wheel.repr))

			wheel.driveNode = wheel.repr

			link(newRepr, wheel.driveNode)
			setTranslation(wheel.driveNode, 0, 0, 0)
			setRotation(wheel.driveNode, 0, 0, 0)
			setScale(wheel.driveNode, 1, 1, 1)

			wheel.repr = newRepr
		end

		if wheel.driveNode ~= nil then
			local driveNodeDirectionNode = createTransformGroup("driveNodeDirectionNode")

			link(getParent(wheel.repr), driveNodeDirectionNode)
			setWorldTranslation(driveNodeDirectionNode, getWorldTranslation(wheel.driveNode))
			setWorldRotation(driveNodeDirectionNode, getWorldRotation(wheel.driveNode))

			wheel.driveNodeDirectionNode = driveNodeDirectionNode
			local defaultX, defaultY, defaultZ = getRotation(wheel.driveNode)

			if math.abs(defaultX) > 0.0001 or math.abs(defaultY) > 0.0001 or math.abs(defaultZ) > 0.0001 then
				Logging.xmlWarning(xmlFile, "Rotation of driveNode '%s' is not 0/0/0 in the i3d file (%.1f/%.1f/%.1f). '%s'", getName(wheel.driveNode), math.deg(defaultX), math.deg(defaultY), math.deg(defaultZ), wheelKey)
			end
		end

		if wheel.linkNode == nil then
			wheel.linkNode = wheel.driveNode
		end

		wheel.yOffset = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#yOffset", 0)

		if wheel.yOffset ~= 0 then
			setTranslation(wheel.driveNode, localToLocal(wheel.driveNode, getParent(wheel.driveNode), 0, wheel.yOffset, 0))
		end

		wheel.showSteeringAngle = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#showSteeringAngle", true)
		wheel.suspTravel = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#suspTravel", 0.01)
		local initialCompression = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#initialCompression")

		if initialCompression ~= nil then
			wheel.deltaY = (1 - initialCompression * 0.01) * wheel.suspTravel
		else
			wheel.deltaY = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#deltaY", 0)
		end

		wheel.spring = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#spring", 0) * Vehicle.SPRING_SCALE
		wheel.torque = 0
		wheel.brakeFactor = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#brakeFactor", 1)
		wheel.autoHoldBrakeFactor = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#autoHoldBrakeFactor", wheel.brakeFactor)
		wheel.damperCompressionLowSpeed = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#damperCompressionLowSpeed")
		wheel.damperRelaxationLowSpeed = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#damperRelaxationLowSpeed")

		if wheel.damperRelaxationLowSpeed == nil then
			wheel.damperRelaxationLowSpeed = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#damper", wheel.damperCompressionLowSpeed or 0)
		end

		wheel.damperRelaxationHighSpeed = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#damperRelaxationHighSpeed", wheel.damperRelaxationLowSpeed * 0.7)

		if wheel.damperCompressionLowSpeed == nil then
			wheel.damperCompressionLowSpeed = wheel.damperRelaxationLowSpeed * 0.9
		end

		wheel.damperCompressionHighSpeed = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#damperCompressionHighSpeed", wheel.damperCompressionLowSpeed * 0.2)
		wheel.damperCompressionLowSpeedThreshold = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#damperCompressionLowSpeedThreshold", 0.1016)
		wheel.damperRelaxationLowSpeedThreshold = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#damperRelaxationLowSpeedThreshold", 0.1524)
		wheel.forcePointRatio = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#forcePointRatio", 0)
		wheel.driveMode = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#driveMode", 0)
		wheel.xOffset = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#xOffset", 0)
		wheel.transRatio = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#transRatio", 0)
		wheel.isSynchronized = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#isSynchronized", true)
		wheel.tipOcclusionAreaGroupId = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#tipOcclusionAreaGroupId")
		wheel.positionX, wheel.positionY, wheel.positionZ = localToLocal(wheel.driveNode, wheel.node, 0, 0, 0)
		wheel.useReprDirection = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#useReprDirection", false)
		wheel.useDriveNodeDirection = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#useDriveNodeDirection", false)
		wheel.mass = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#mass", wheel.mass)
		wheel.radius = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#radius", wheel.radius or 0.5)
		wheel.width = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#width", wheel.width or 0.6)
		wheel.wheelShapeWidth = wheel.width
		wheel.widthOffset = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#widthOffset", 0)
		wheel.restLoad = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#restLoad", wheel.restLoad or 1)
		wheel.maxLongStiffness = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#maxLongStiffness", wheel.maxLongStiffness or 30)
		wheel.maxLatStiffness = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#maxLatStiffness", wheel.maxLatStiffness or 40)
		wheel.maxLatStiffnessLoad = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#maxLatStiffnessLoad", wheel.maxLatStiffnessLoad or 2)
		wheel.frictionScale = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#frictionScale", wheel.frictionScale or 1)
		wheel.rotationDamping = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#rotationDamping", wheel.mass * 0.035)
		wheel.tireGroundFrictionCoeff = 1
		local tireTypeName = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#tireType", "mud")
		wheel.tireType = WheelsUtil.getTireType(tireTypeName)

		if wheel.tireType == nil then
			Logging.xmlWarning(xmlFile, "Failed to find tire type '%s'. Defaulting to 'mud'!", tireTypeName)

			wheel.tireType = WheelsUtil.getTireType("mud")
		end

		local maxWheelSinkDefault = 0.5

		if wheel.tireType == WheelsUtil.getTireType("crawler") then
			maxWheelSinkDefault = 0.01
		end

		wheel.fieldDirtMultiplier = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#fieldDirtMultiplier", 75)
		wheel.streetDirtMultiplier = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#streetDirtMultiplier", -150)
		wheel.minDirtPercentage = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#minDirtPercentage", 0.35)
		wheel.maxDirtOffset = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#maxDirtOffset", 0.5)
		wheel.dirtColorChangeSpeed = 1 / (self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#dirtColorChangeSpeed", 20) * 1000)
		wheel.smoothGroundRadius = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#smoothGroundRadius", wheel.smoothGroundRadius or math.max(0.6, wheel.width * 0.75))
		wheel.versatileYRot = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#versatileYRot", false)
		wheel.forceVersatility = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#forceVersatility", false)
		wheel.supportsWheelSink = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#supportsWheelSink", true)
		wheel.maxWheelSink = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#maxWheelSink", maxWheelSinkDefault)
		wheel.rotSpeed = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#rotSpeed", 0)
		wheel.rotSpeedNeg = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#rotSpeedNeg", 0)
		wheel.rotMax = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#rotMax", 0)
		wheel.rotMin = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#rotMin", 0)
		wheel.rotSpeedLimit = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".physics#rotSpeedLimit")
	else
		Logging.xmlWarning(xmlFile, "Invalid repr for wheel '%s'. Needs to be a child of a collision!", configKey .. wheelKey)

		return false
	end

	return true
end

function Wheels:loadWheelSteeringData(xmlFile, configKey, wheelKey, wheel)
	XMLUtil.checkDeprecatedXMLElements(xmlFile, configKey .. wheelKey .. "#steeringNode", string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration.wheels.wheel(%d).steering#node", wheel.xmlIndex))

	local steeringKey = wheelKey .. ".steering"
	wheel.steeringNode = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, steeringKey .. "#node", nil, self.components, self.i3dMappings)
	wheel.steeringRotNode = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, steeringKey .. "#rotNode", nil, self.components, self.i3dMappings)
	wheel.steeringNodeMinTransX = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, steeringKey .. "#nodeMinTransX")
	wheel.steeringNodeMaxTransX = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, steeringKey .. "#nodeMaxTransX")
	wheel.steeringNodeMinRotY = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, steeringKey .. "#nodeMinRotY")
	wheel.steeringNodeMaxRotY = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, steeringKey .. "#nodeMaxRotY")
	wheel.fenders = {}
	local i = 0

	while true do
		local singleKey = string.format("%s.fender(%d)", wheelKey, i)
		local node = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, singleKey .. "#node", nil, self.components, self.i3dMappings)

		if node == nil then
			break
		end

		local entry = {
			node = node,
			rotMax = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, singleKey .. "#rotMax"),
			rotMin = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, singleKey .. "#rotMin")
		}

		table.insert(wheel.fenders, entry)

		i = i + 1
	end

	local steeringAxleKey = wheelKey .. ".steeringAxle"
	wheel.steeringAxleScale = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, steeringAxleKey .. "#scale", 0)
	wheel.steeringAxleRotMax = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, steeringAxleKey .. "#rotMax", 0)
	wheel.steeringAxleRotMin = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, steeringAxleKey .. "#rotMin", -0)

	return true
end

function Wheels:loadAdditionalWheelsFromXML(xmlFile, configKey, wheelKey, wheel)
	local additionalWheels = {}
	local i = 0

	while true do
		local additionalWheelKey = string.format(wheelKey .. ".additionalWheel(%d)", i)

		if not xmlFile:hasProperty(configKey .. additionalWheelKey) then
			break
		end

		local xmlFilename = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, additionalWheelKey .. "#filename")

		if xmlFilename ~= nil and xmlFilename ~= "" then
			XMLUtil.checkDeprecatedXMLElements(xmlFile, configKey .. additionalWheelKey .. "#configIndex", configKey .. additionalWheelKey .. "#configId")
			XMLUtil.checkDeprecatedXMLElements(xmlFile, configKey .. additionalWheelKey .. "#addRaycast", nil)

			local additionalWheel = {
				node = wheel.node,
				key = configKey .. additionalWheelKey,
				singleKey = additionalWheelKey,
				linkNode = wheel.linkNode
			}
			local wheelConfigId = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, additionalWheelKey .. "#configId", "default")
			additionalWheel.isLeft = Utils.getNoNil(self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, additionalWheelKey .. "#isLeft", wheel.isLeft), false)
			additionalWheel.xRotOffset = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, additionalWheelKey .. "#xRotOffset", 0)
			additionalWheel.color = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, additionalWheelKey .. "#color", nil, true) or wheel.color

			if self:loadWheelDataFromExternalXML(additionalWheel, xmlFilename, wheelConfigId, false) then
				additionalWheel.hasParticles = Utils.getNoNil(self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, additionalWheelKey .. "#hasParticles", wheel.hasParticles), false)
				additionalWheel.hasTireTracks = Utils.getNoNil(self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, additionalWheelKey .. "#hasTireTracks", wheel.hasTireTracks), false)
				additionalWheel.offset = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, additionalWheelKey .. "#offset", 0)

				self:loadAdditionalWheelConnectorFromXML(wheel, additionalWheel, xmlFile, configKey, additionalWheelKey)
				table.insert(additionalWheels, additionalWheel)

				wheel.mass = wheel.mass + additionalWheel.mass + additionalWheel.additionalMass
				wheel.maxLatStiffness = wheel.maxLatStiffness + additionalWheel.maxLatStiffness
				wheel.maxLongStiffness = wheel.maxLongStiffness + additionalWheel.maxLongStiffness
			end
		end

		i = i + 1
	end

	if #additionalWheels > 0 then
		wheel.additionalWheels = additionalWheels
	end

	return true
end

function Wheels:loadAdditionalWheelConnectorFromXML(wheel, additionalWheel, xmlFile, configKey, wheelKey)
	local spec = self.spec_wheels
	local connectorFilename = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".connector#filename")

	if connectorFilename ~= nil and connectorFilename ~= "" then
		XMLUtil.checkDeprecatedXMLElements(xmlFile, configKey .. wheelKey .. ".connector#index", configKey .. wheelKey .. ".connector#node")

		local connector = {}

		if connectorFilename:endsWith(".xml") then
			local xmlFilename = Utils.getFilename(connectorFilename, self.baseDirectory)
			local connectorXmlFile = XMLFile.load("connectorXml", xmlFilename, Wheels.xmlSchemaConnector)

			if connectorXmlFile ~= nil then
				local nodeKey = "leftNode"

				if not wheel.isLeft then
					nodeKey = "rightNode"
				end

				connector.filename = connectorXmlFile:getValue("connector.file#name")
				connector.nodeStr = connectorXmlFile:getValue("connector.file#" .. nodeKey)

				connectorXmlFile:delete()
			else
				Logging.xmlError(xmlFile, "Unable to load connector xml file '%s'!", connectorFilename)
			end
		else
			connector.filename = connectorFilename
			connector.nodeStr = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".connector#node")
		end

		if connector.filename ~= nil and connector.filename ~= "" then
			connector.useWidthAndDiam = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".connector#useWidthAndDiam", false)
			connector.usePosAndScale = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".connector#usePosAndScale", false)
			connector.diameter = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".connector#diameter")
			connector.additionalOffset = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".connector#offset", 0)
			connector.width = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".connector#width")
			connector.startPos = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".connector#startPos")
			connector.endPos = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".connector#endPos")
			connector.scale = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".connector#uniformScale")
			connector.color = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".connector#color", nil, true) or ConfigurationUtil.getColorByConfigId(self, "rimColor", self.configurations.rimColor) or wheel.color or spec.rimColor
			additionalWheel.connector = connector
		end
	end
end

function Wheels:loadWheelChocksFromXML(xmlFile, configKey, wheelKey, wheel)
	local spec = self.spec_wheels
	wheel.wheelChocks = {}
	local i = 0

	while true do
		local chockKey = string.format(wheelKey .. ".wheelChock(%d)", i)

		if not xmlFile:hasProperty(configKey .. chockKey) then
			break
		end

		local filename = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, chockKey .. "#filename", "$data/shared/assets/wheelChocks/wheelChock01.i3d")
		filename = Utils.getFilename(filename, self.baseDirectory)
		local sharedLoadRequestId = self:loadSubSharedI3DFile(filename, false, false, self.onWheelChockI3DLoaded, self, {
			wheel,
			filename,
			xmlFile,
			configKey,
			chockKey
		})

		table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)

		i = i + 1
	end

	return true
end

function Wheels:onWheelChockI3DLoaded(i3dNode, failedReason, args)
	local _ = nil
	local wheel, filename, xmlFile, configKey, chockKey = unpack(args)

	if i3dNode ~= 0 then
		local chockNode = getChildAt(i3dNode, 0)
		local posRefNode = I3DUtil.indexToObject(chockNode, getUserAttribute(chockNode, "posRefNode"), self.i3dMappings)

		if posRefNode ~= nil then
			local chock = {
				wheel = wheel,
				node = chockNode,
				filename = filename,
				scale = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, chockKey .. "#scale", "1 1 1", true)
			}

			setScale(chock.node, unpack(chock.scale))

			chock.parkingNode = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, chockKey .. "#parkingNode", nil, self.components, self.i3dMappings)
			chock.isInverted = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, chockKey .. "#isInverted", false)
			chock.isParked = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, chockKey .. "#isParked", false)
			_, chock.height, chock.zOffset = localToLocal(posRefNode, chock.node, 0, 0, 0)
			chock.height = chock.height / chock.scale[2]
			chock.zOffset = chock.zOffset / chock.scale[3]
			chock.offset = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, chockKey .. "#offset", "0 0 0", true)
			chock.parkedNode = I3DUtil.indexToObject(chockNode, getUserAttribute(chockNode, "parkedNode"), self.i3dMappings)
			chock.linkedNode = I3DUtil.indexToObject(chockNode, getUserAttribute(chockNode, "linkedNode"), self.i3dMappings)
			local color = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, chockKey .. "#color", nil, true)

			if color ~= nil then
				local _, _, _, defaultMaterial = getShaderParameter(chockNode, "colorMat0")
				color[4] = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, chockKey .. "#material", defaultMaterial)

				I3DUtil.setShaderParameterRec(chockNode, "colorMat0", color[1], color[2], color[3], color[4])
			end

			chock.isInParkingPosition = false

			self:updateWheelChockPosition(chock, chock.isParked)

			wheel.updateWheelChock = false

			table.insert(wheel.wheelChocks, chock)
			table.insert(self.spec_wheels.wheelChocks, chock)
		else
			Logging.xmlWarning(xmlFile, "Missing 'posRefNode'-userattribute for wheel-chock '%s'!", chockKey)
		end

		delete(i3dNode)
	end
end

function Wheels:loadWheelParticleSystem(xmlFile, configKey, wheelKey, wheel)
	local spec = self.spec_wheels
	wheel.driveGroundParticleSystems = {}
	wheel.driveGroundParticleStates = {
		wheel_snow = false,
		wheel_wet = false,
		wheel_dry = false,
		wheel_dust = false
	}
	local i3dFilename = Utils.getFilename(Wheels.PARTICLE_SYSTEM_PATH, self.baseDirectory)

	for name, _ in pairs(wheel.driveGroundParticleStates) do
		local sourceParticleSystem = g_particleSystemManager:getParticleSystem(name)

		if sourceParticleSystem ~= nil then
			local args = {
				xmlFile,
				configKey,
				wheelKey,
				wheel,
				wheel,
				sourceParticleSystem,
				name,
				i3dFilename
			}
			local sharedLoadRequestId = self:loadSubSharedI3DFile(i3dFilename, false, false, self.onWheelParticleSystemI3DLoaded, self, args)

			table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)

			if wheel.additionalWheels ~= nil then
				for _, additionalWheel in ipairs(wheel.additionalWheels) do
					if additionalWheel.hasParticles then
						if additionalWheel.driveGroundParticleSystems == nil then
							additionalWheel.driveGroundParticleSystems = {}
						end

						local argsAdditional = {
							xmlFile,
							configKey,
							additionalWheel.singleKey,
							wheel,
							additionalWheel,
							sourceParticleSystem,
							name,
							i3dFilename
						}
						local sharedLoadRequestIdAdditional = self:loadSubSharedI3DFile(i3dFilename, false, false, self.onWheelParticleSystemI3DLoaded, self, argsAdditional)

						table.insert(spec.sharedLoadRequestIds, sharedLoadRequestIdAdditional)
					end
				end
			end
		end
	end
end

function Wheels:onWheelParticleSystemI3DLoaded(i3dNode, failedReason, args)
	local xmlFile, configKey, wheelKey, wheel, wheelData, sourceParticleSystem, name, i3dFilename = unpack(args)

	if i3dNode ~= 0 then
		local emitterShape = getChildAt(i3dNode, 0)

		link(wheel.node, emitterShape)
		delete(i3dNode)

		local particleSystem = ParticleUtil.copyParticleSystem(xmlFile, nil, sourceParticleSystem, emitterShape)
		particleSystem.i3dFilename = i3dFilename
		particleSystem.particleSpeed = ParticleUtil.getParticleSystemSpeed(particleSystem)
		particleSystem.particleRandomSpeed = ParticleUtil.getParticleSystemSpeedRandom(particleSystem)
		particleSystem.isTintable = Utils.getNoNil(getUserAttribute(particleSystem.shape, "tintable"), true)
		particleSystem.offsets = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".wheelParticleSystem#psOffset", "0 0 0", true)
		local wx, wy, wz = worldToLocal(wheel.node, getWorldTranslation(wheel.driveNode))

		setTranslation(particleSystem.emitterShape, wx + particleSystem.offsets[1], wy + particleSystem.offsets[2], wz + particleSystem.offsets[3])
		setScale(particleSystem.emitterShape, wheelData.width, wheelData.radius * 2, wheelData.radius * 2)

		particleSystem.wheel = wheel
		particleSystem.rootNode = particleSystem.emitterShape
		particleSystem.minSpeed = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".wheelParticleSystem#minSpeed", 3) / 3600
		particleSystem.maxSpeed = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".wheelParticleSystem#maxSpeed", 20) / 3600
		particleSystem.minScale = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".wheelParticleSystem#minScale", 0.1)
		particleSystem.maxScale = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".wheelParticleSystem#maxScale", 1)
		particleSystem.direction = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".wheelParticleSystem#direction", 0)
		particleSystem.onlyActiveOnGroundContact = self:getWheelConfigurationValue(xmlFile, wheel.configIndex, configKey, wheelKey .. ".wheelParticleSystem#onlyActiveOnGroundContact", true)
		wheelData.driveGroundParticleSystems[name] = {
			particleSystem
		}
	end
end

function Wheels:loadHubsFromXML()
	local spec = self.spec_wheels
	spec.hubsColors = {}

	for j = 0, 7 do
		local hubsColorsKey = string.format("vehicle.wheels.hubs.color%d", j)
		local color = self.xmlFile:getValue(hubsColorsKey, nil, true)
		local material = self.xmlFile:getValue(hubsColorsKey .. "#material")

		if color ~= nil then
			spec.hubsColors[j] = color
			spec.hubsColors[j][4] = material
		elseif self.xmlFile:getValue(hubsColorsKey .. "#useBaseColor") then
			spec.hubsColors[j] = ConfigurationUtil.getColorByConfigId(self, "baseColor", self.configurations.baseColor) or ConfigurationUtil.getColorByConfigId(self, "baseMaterial", self.configurations.baseMaterial)
		elseif self.xmlFile:getValue(hubsColorsKey .. "#useRimColor") then
			spec.hubsColors[j] = Utils.getNoNil(ConfigurationUtil.getColorByConfigId(self, "rimColor", self.configurations.rimColor), spec.rimColor)
		end

		local overwrittenHubColor = spec.overwrittenWheelColors[string.format("_hubColor%d", j)]

		if #overwrittenHubColor > 0 then
			spec.hubsColors[j] = spec.hubsColors[j] or {
				0,
				0,
				0,
				0
			}
			spec.hubsColors[j][3] = overwrittenHubColor[3]
			spec.hubsColors[j][2] = overwrittenHubColor[2]
			spec.hubsColors[j][1] = overwrittenHubColor[1]

			if #overwrittenHubColor == 4 then
				spec.hubsColors[j][4] = overwrittenHubColor[4]
			end
		end
	end

	spec.hubs = {}

	self.xmlFile:iterate("vehicle.wheels.hubs.hub", function (_, key)
		self:loadHubFromXML(self.xmlFile, key)
	end)
end

function Wheels:loadHubFromXML(xmlFile, key)
	local spec = self.spec_wheels
	local linkNode = xmlFile:getValue(key .. "#linkNode", nil, self.components, self.i3dMappings)

	if linkNode == nil then
		Logging.xmlError(xmlFile, "Missing link node for hub '%s'", key)

		return
	end

	local hub = {
		linkNode = linkNode,
		isLeft = xmlFile:getValue(key .. "#isLeft")
	}
	local hubXmlFilename = xmlFile:getValue(key .. "#filename")
	hub.xmlFilename = Utils.getFilename(hubXmlFilename, self.baseDirectory)
	local xmlFileHub = XMLFile.load("wheelHubXml", hub.xmlFilename, Wheels.xmlSchemaHub)

	if xmlFileHub ~= nil then
		local i3dFilename = xmlFileHub:getValue("hub.filename")

		if i3dFilename == nil then
			Logging.xmlError(xmlFileHub, "Unable to retrieve hub i3d filename!")

			return
		end

		hub.i3dFilename = Utils.getFilename(i3dFilename, self.baseDirectory)
		hub.colors = {}

		for j = 0, 7 do
			hub.colors[j] = xmlFileHub:getValue(string.format("hub.color%d", j), nil, true)
		end

		hub.nodeStr = xmlFileHub:getValue("hub.nodes#" .. (hub.isLeft and "left" or "right"))
		local sharedLoadRequestId = self:loadSubSharedI3DFile(hub.i3dFilename, false, false, self.onWheelHubI3DLoaded, self, {
			hub,
			linkNode,
			xmlFile,
			key
		})

		table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
		xmlFileHub:delete()
	end

	return true
end

function Wheels:onWheelHubI3DLoaded(i3dNode, failedReason, args)
	local spec = self.spec_wheels
	local hub, linkNode, xmlFile, key = unpack(args)

	if i3dNode ~= 0 then
		hub.node = I3DUtil.indexToObject(i3dNode, hub.nodeStr, self.i3dMappings)

		if hub.node ~= nil then
			link(linkNode, hub.node)
			delete(i3dNode)
		else
			Logging.xmlError(xmlFile, "Could not find hub node '%s' in '%s'", hub.nodeStr, hub.xmlFilename)

			return
		end

		for j = 0, 7 do
			local color = XMLUtil.getXMLOverwrittenValue(xmlFile, key, string.format(".color%d", j), "", "global")
			local material = XMLUtil.getXMLOverwrittenValue(xmlFile, key, string.format(".color%d#material", j), "")

			if color == "global" then
				color = spec.hubsColors[j]
			else
				color = ConfigurationUtil.getColorFromString(color)

				if color ~= nil then
					color[4] = material
				end
			end

			if color ~= nil and hub.colors[j] == nil then
				Logging.xmlWarning(xmlFile, "ColorShader 'color%d' is not supported by '%s'.", j, hub.xmlFilename)
			else
				color = color or hub.colors[j]

				if color ~= nil then
					local r, g, b, mat = unpack(color)
					local _ = nil

					if mat == nil then
						_, _, _, mat = I3DUtil.getShaderParameterRec(hub.node, string.format("colorMat%d", j))
					end

					I3DUtil.setShaderParameterRec(hub.node, string.format("colorMat%d", j), r, g, b, mat, false)
				end
			end
		end

		local offset = xmlFile:getValue(key .. "#offset")

		if offset ~= nil then
			if not hub.isLeft then
				offset = offset * -1
			end

			setTranslation(hub.node, offset, 0, 0)
		end

		local scale = xmlFile:getValue(key .. "#scale", nil, true)

		if scale ~= nil then
			setScale(hub.node, scale[1], scale[2], scale[3])
		end

		table.insert(spec.hubs, hub)
	elseif not self.isDeleting and not self.isDeleted then
		Logging.xmlError(xmlFile, "Unable to load hub '%s'", hub.xmlFilename)
	end
end

function Wheels:loadAckermannSteeringFromXML(xmlFile, ackermannSteeringIndex)
	local spec = self.spec_wheels
	local key, _ = ConfigurationUtil.getXMLConfigurationKey(xmlFile, ackermannSteeringIndex, "vehicle.wheels.ackermannSteeringConfigurations.ackermannSteering", nil, "ackermann")
	spec.steeringCenterNode = nil

	if key ~= nil then
		local rotSpeed = xmlFile:getValue(key .. "#rotSpeed")
		local rotMax = xmlFile:getValue(key .. "#rotMax")
		local centerX, centerZ = nil
		local rotCenterWheel1 = xmlFile:getValue(key .. "#rotCenterWheel1")

		if rotCenterWheel1 ~= nil and spec.wheels[rotCenterWheel1] ~= nil then
			local wheel = spec.wheels[rotCenterWheel1]
			centerX, _, centerZ = localToLocal(wheel.node, self.components[1].node, wheel.positionX, wheel.positionY, wheel.positionZ)
			local rotCenterWheel2 = xmlFile:getValue(key .. "#rotCenterWheel2")

			if rotCenterWheel2 ~= nil and spec.wheels[rotCenterWheel2] ~= nil then
				if rotCenterWheel2 == rotCenterWheel1 then
					Logging.xmlWarning(xmlFile, "The ackermann steering wheels are identical (both index %d). Are you sure this is correct? (%s)", rotCenterWheel1, key)
				end

				local wheel2 = spec.wheels[rotCenterWheel2]
				local x, _, z = localToLocal(wheel2.node, self.components[1].node, wheel2.positionX, wheel2.positionY, wheel2.positionZ)
				centerZ = 0.5 * (centerZ + z)
				centerX = 0.5 * (centerX + x)
			end
		else
			local centerNode, _ = xmlFile:getValue(key .. "#rotCenterNode", nil, self.components, self.i3dMappings)

			if centerNode ~= nil then
				centerX, _, centerZ = localToLocal(centerNode, self.components[1].node, 0, 0, 0)
				spec.steeringCenterNode = centerNode
			else
				local p = xmlFile:getValue(key .. "#rotCenter", nil, true)

				if p ~= nil then
					centerX = p[1]
					centerZ = p[2]
				end
			end
		end

		if spec.steeringCenterNode == nil then
			spec.steeringCenterNode = createTransformGroup("steeringCenterNode")

			link(self.components[1].node, spec.steeringCenterNode)

			if centerX ~= nil and centerZ ~= nil then
				setTranslation(spec.steeringCenterNode, centerX, 0, centerZ)
			end
		end

		if rotSpeed ~= nil and rotMax ~= nil and centerX ~= nil then
			rotSpeed = math.abs(math.rad(rotSpeed))
			rotMax = math.abs(math.rad(rotMax))
			local maxTurningRadius = 0
			local maxTurningRadiusWheel = 0

			for i, wheel in ipairs(spec.wheels) do
				if wheel.rotSpeed ~= 0 then
					local diffX, _, diffZ = localToLocal(wheel.node, spec.steeringCenterNode, wheel.positionX, wheel.positionY, wheel.positionZ)
					local turningRadius = math.abs(diffZ) / math.tan(rotMax) + math.abs(diffX)

					if maxTurningRadius <= turningRadius then
						maxTurningRadius = turningRadius
						maxTurningRadiusWheel = i
					end
				end
			end

			self.maxRotation = math.max(Utils.getNoNil(self.maxRotation, 0), rotMax)
			self.maxTurningRadius = maxTurningRadius
			self.maxTurningRadiusWheel = maxTurningRadiusWheel
			self.wheelSteeringDuration = rotMax / rotSpeed

			if maxTurningRadiusWheel > 0 then
				for _, wheel in ipairs(spec.wheels) do
					if wheel.rotSpeed ~= 0 then
						local diffX, _, diffZ = localToLocal(wheel.node, spec.steeringCenterNode, wheel.positionX, wheel.positionY, wheel.positionZ)
						local rotMaxI = math.atan(diffZ / (maxTurningRadius - diffX))
						local rotMinI = -math.atan(diffZ / (maxTurningRadius + diffX))
						local switchMaxMin = rotMaxI < rotMinI

						if switchMaxMin then
							rotMinI = rotMaxI
							rotMaxI = rotMinI
						end

						wheel.rotMax = rotMaxI
						wheel.rotMin = rotMinI
						wheel.rotSpeed = rotMaxI / self.wheelSteeringDuration
						wheel.rotSpeedNeg = -rotMinI / self.wheelSteeringDuration

						if wheel.steeringAxleScale ~= 0 then
							if switchMaxMin then
								wheel.steeringAxleScale = -wheel.steeringAxleScale
							end

							wheel.steeringAxleRotMax = rotMaxI
							wheel.steeringAxleRotMin = rotMinI
						end

						if switchMaxMin then
							wheel.rotSpeedNeg = -wheel.rotSpeed
							wheel.rotSpeed = -wheel.rotSpeedNeg
						end
					end
				end
			end
		end
	end

	for _, wheel in ipairs(spec.wheels) do
		if wheel.rotSpeed ~= 0 then
			if wheel.rotMax >= 0 == (wheel.rotSpeed >= 0) then
				self.maxRotTime = math.max(wheel.rotMax / wheel.rotSpeed, self.maxRotTime)
			end

			if wheel.rotMin >= 0 == (wheel.rotSpeed >= 0) then
				self.maxRotTime = math.max(wheel.rotMin / wheel.rotSpeed, self.maxRotTime)
			end

			local rotSpeedNeg = wheel.rotSpeedNeg

			if rotSpeedNeg == nil then
				rotSpeedNeg = wheel.rotSpeed
			end

			if wheel.rotMax >= 0 ~= (rotSpeedNeg >= 0) then
				self.minRotTime = math.min(wheel.rotMax / rotSpeedNeg, self.minRotTime)
			end

			if wheel.rotMin >= 0 ~= (rotSpeedNeg >= 0) then
				self.minRotTime = math.min(wheel.rotMin / rotSpeedNeg, self.minRotTime)
			end
		end

		for i = 1, #wheel.fenders do
			local fender = wheel.fenders[i]
			fender.rotMax = fender.rotMax or wheel.rotMax
			fender.rotMin = fender.rotMin or wheel.rotMin
		end

		wheel.steeringNodeMaxRot = math.max(wheel.rotMax, wheel.steeringAxleRotMax)
		wheel.steeringNodeMinRot = math.min(wheel.rotMin, wheel.steeringAxleRotMin)

		if wheel.rotSpeedLimit ~= nil then
			wheel.rotSpeedDefault = wheel.rotSpeed
			wheel.rotSpeedNegDefault = wheel.rotSpeedNeg
			wheel.currentRotSpeedAlpha = 1
		end
	end
end

function Wheels:loadNonPhysicalWheelFromXML(dynamicallyLoadedWheel, xmlFile, key)
	dynamicallyLoadedWheel.linkNode = xmlFile:getValue(key .. "#linkNode", self.components[1].node, self.components, self.i3dMappings)
	local wheelXmlFilename = xmlFile:getValue(key .. "#filename")

	if wheelXmlFilename ~= nil and wheelXmlFilename ~= "" then
		local wheelConfigId = xmlFile:getValue(key .. "#configId", "default")
		dynamicallyLoadedWheel.isLeft = xmlFile:getValue(key .. "#isLeft", true)
		dynamicallyLoadedWheel.tireIsInverted = xmlFile:getValue(key .. "#isInverted", false)
		dynamicallyLoadedWheel.xRotOffset = xmlFile:getValue(key .. "#xRotOffset", 0)
		dynamicallyLoadedWheel.color = xmlFile:getValue(key .. "#color", nil, true)
		dynamicallyLoadedWheel.additionalColor = xmlFile:getValue(key .. "#additionalColor", nil, true)

		self:loadWheelDataFromExternalXML(dynamicallyLoadedWheel, wheelXmlFilename, wheelConfigId)
		self:finalizeWheel(dynamicallyLoadedWheel)

		return true
	end

	return false
end

function Wheels:finalizeWheel(wheel, parentWheel)
	local spec = self.spec_wheels

	if parentWheel == nil and wheel.repr ~= nil then
		wheel.startPositionX, wheel.startPositionY, wheel.startPositionZ = getTranslation(wheel.repr)
		wheel.driveNodeStartPosX, wheel.driveNodeStartPosY, wheel.driveNodeStartPosZ = getTranslation(wheel.driveNode)
		wheel.dirtAmount = 0
		wheel.xDriveOffset = 0
		wheel.lastXDrive = 0
		wheel.lastColor = {
			0,
			0,
			0,
			0
		}
		wheel.lastTerrainAttribute = 0
		wheel.contact = Wheels.WHEEL_NO_CONTACT
		wheel.hasSnowContact = false
		wheel.snowScale = 0
		wheel.steeringAngle = 0
		wheel.lastSteeringAngle = 0
		wheel.lastMovement = 0
		wheel.hasGroundContact = false
		wheel.hasHandbrake = true
		wheel.lastContactObjectAllowsTireTracks = true
		wheel.densityBits = 0
		wheel.densityType = 0
		local vehicleNode = self.vehicleNodes[wheel.node]

		if vehicleNode ~= nil and vehicleNode.component ~= nil and vehicleNode.component.motorized == nil then
			vehicleNode.component.motorized = true
		end

		if wheel.useReprDirection then
			wheel.directionX, wheel.directionY, wheel.directionZ = localDirectionToLocal(wheel.repr, wheel.node, 0, -1, 0)
			wheel.axleX, wheel.axleY, wheel.axleZ = localDirectionToLocal(wheel.repr, wheel.node, 1, 0, 0)
		elseif wheel.useDriveNodeDirection then
			wheel.directionX, wheel.directionY, wheel.directionZ = localDirectionToLocal(wheel.driveNodeDirectionNode, wheel.node, 0, -1, 0)
			wheel.axleX, wheel.axleY, wheel.axleZ = localDirectionToLocal(wheel.driveNodeDirectionNode, wheel.node, 1, 0, 0)
		else
			wheel.directionZ = 0
			wheel.directionY = -1
			wheel.directionX = 0
			wheel.axleZ = 0
			wheel.axleY = 0
			wheel.axleX = 1
		end

		wheel.steeringCenterOffsetZ = 0
		wheel.steeringCenterOffsetY = 0
		wheel.steeringCenterOffsetX = 0

		if wheel.repr ~= wheel.driveNode then
			wheel.steeringCenterOffsetX, wheel.steeringCenterOffsetY, wheel.steeringCenterOffsetZ = localToLocal(wheel.driveNode, wheel.repr, 0, 0, 0)
			wheel.steeringCenterOffsetX = -wheel.steeringCenterOffsetX
			wheel.steeringCenterOffsetY = -wheel.steeringCenterOffsetY
			wheel.steeringCenterOffsetZ = -wheel.steeringCenterOffsetZ
		end

		wheel.syncContactState = false

		if wheel.hasTireTracks then
			wheel.tireTrackNodeIndex = self:addTireTrackNode(wheel, false, wheel.node, wheel.repr, wheel.tireTrackAtlasIndex, wheel.width, wheel.radius, wheel.xOffset, wheel.tireIsInverted)
			wheel.syncContactState = true
		end

		wheel.maxLatStiffness = wheel.maxLatStiffness * wheel.restLoad
		wheel.maxLatStiffnessLoad = wheel.maxLatStiffnessLoad * wheel.restLoad
		wheel.mass = wheel.mass + wheel.additionalMass
		wheel.lastTerrainValue = 0
		wheel.sink = 0
		wheel.sinkTarget = 0
		wheel.radiusOriginal = wheel.radius
		wheel.sinkFrictionScaleFactor = 1
		wheel.sinkLongStiffnessFactor = 1
		wheel.sinkLatStiffnessFactor = 1
		local positionY = wheel.positionY + wheel.deltaY
		wheel.netInfo = {
			xDrive = 0,
			xDriveSpeed = 0,
			x = wheel.positionX,
			y = positionY,
			z = wheel.positionZ,
			suspensionLength = wheel.suspTravel * 0.5,
			sync = {
				yRange = 10,
				yMin = -5
			},
			yMin = positionY - 1.2 * wheel.suspTravel
		}
		local width = 0.5 * wheel.width
		local length = math.min(0.5, 0.5 * wheel.width)
		local x, _, z = localToLocal(wheel.driveNode, wheel.repr, 0, 0, 0)
		wheel.destructionStartNode = createTransformGroup("destructionStartNode")
		wheel.destructionWidthNode = createTransformGroup("destructionWidthNode")
		wheel.destructionHeightNode = createTransformGroup("destructionHeightNode")

		link(wheel.repr, wheel.destructionStartNode)
		link(wheel.repr, wheel.destructionWidthNode)
		link(wheel.repr, wheel.destructionHeightNode)
		setTranslation(wheel.destructionStartNode, x + width, 0, z - length)
		setTranslation(wheel.destructionWidthNode, x - width, 0, z - length)
		setTranslation(wheel.destructionHeightNode, x + width, 0, z + length)
		self:updateWheelBase(wheel)
		self:updateWheelTireFriction(wheel)

		wheel.networkInterpolators = {
			xDrive = InterpolatorAngle.new(wheel.netInfo.xDrive),
			position = InterpolatorPosition.new(wheel.netInfo.x, wheel.netInfo.y, wheel.netInfo.z),
			suspensionLength = InterpolatorValue.new(wheel.netInfo.suspensionLength)
		}
	end

	if parentWheel ~= nil then
		wheel.linkNode = createTransformGroup("linkNode")

		link(parentWheel.driveNode, wheel.linkNode)
	end

	if wheel.tireFilename ~= nil then
		local filename = Utils.getFilename(wheel.tireFilename, self.baseDirectory)
		wheel.tireFilename = nil
		local args = {
			fileIdentifier = "tireFilename",
			name = "wheelTire",
			offset = 0,
			wheel = wheel,
			parentWheel = parentWheel,
			linkNode = wheel.linkNode,
			filename = filename,
			index = wheel.tireNodeStr
		}
		local sharedLoadRequestId = self:loadSubSharedI3DFile(filename, false, false, self.onWheelPartI3DLoaded, self, args)

		table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
	end

	if wheel.outerRimFilename ~= nil then
		local filename = Utils.getFilename(wheel.outerRimFilename, self.baseDirectory)
		wheel.outerRimFilename = nil
		local args = {
			fileIdentifier = "outerRimFilename",
			name = "wheelOuterRim",
			offset = 0,
			wheel = wheel,
			parentWheel = parentWheel,
			linkNode = wheel.linkNode,
			filename = filename,
			index = wheel.outerRimNodeStr,
			widthAndDiam = wheel.outerRimWidthAndDiam,
			scale = wheel.outerRimScale
		}
		local sharedLoadRequestId = self:loadSubSharedI3DFile(filename, false, false, self.onWheelPartI3DLoaded, self, args)

		table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
	end

	if wheel.innerRimFilename ~= nil then
		local filename = Utils.getFilename(wheel.innerRimFilename, self.baseDirectory)
		wheel.innerRimFilename = nil
		local args = {
			fileIdentifier = "innerRimFilename",
			name = "wheelInnerRim",
			wheel = wheel,
			parentWheel = parentWheel,
			linkNode = wheel.linkNode,
			filename = filename,
			index = wheel.innerRimNodeStr,
			offset = wheel.innerRimOffset,
			widthAndDiam = wheel.innerRimWidthAndDiam,
			scale = wheel.innerRimScale
		}
		local sharedLoadRequestId = self:loadSubSharedI3DFile(filename, false, false, self.onWheelPartI3DLoaded, self, args)

		table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
	end

	if wheel.additionalFilename ~= nil then
		local filename = Utils.getFilename(wheel.additionalFilename, self.baseDirectory)
		wheel.additionalFilename = nil
		local args = {
			fileIdentifier = "additionalFilename",
			name = "wheelAdditional",
			wheel = wheel,
			parentWheel = parentWheel,
			linkNode = wheel.linkNode,
			filename = filename,
			index = wheel.additionalNodeStr,
			offset = wheel.additionalOffset,
			widthAndDiam = wheel.additionalWidthAndDiam,
			scale = wheel.additionalScale
		}
		local sharedLoadRequestId = self:loadSubSharedI3DFile(filename, false, false, self.onWheelPartI3DLoaded, self, args)

		table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
	end

	if wheel.additionalWheels ~= nil then
		local outmostWheelWidth = 0
		local totalWheelShapeOffset = 0
		local offsetDir = 1

		for _, additionalWheel in pairs(wheel.additionalWheels) do
			self:finalizeWheel(additionalWheel, wheel)

			local baseWheelWidth = MathUtil.mToInch(wheel.width)
			local dualWheelWidth = MathUtil.mToInch(additionalWheel.width)
			local diameter = 0
			local wheelOffset = MathUtil.mToInch(additionalWheel.offset)

			if wheel.outerRimWidthAndDiam ~= nil then
				baseWheelWidth = wheel.outerRimWidthAndDiam[1]
				diameter = wheel.outerRimWidthAndDiam[2]
			end

			if additionalWheel.outerRimWidthAndDiam ~= nil then
				dualWheelWidth = additionalWheel.outerRimWidthAndDiam[1]
			end

			if wheelOffset < 0 then
				if additionalWheel.isLeft then
					offsetDir = -1
				else
					offsetDir = 1
				end
			elseif additionalWheel.isLeft then
				offsetDir = 1
			else
				offsetDir = -1
			end

			local totalOffset = 0
			totalOffset = totalOffset + (additionalWheel.isLeft and 1 or -1) * MathUtil.inchToM(0.5 * baseWheelWidth + wheelOffset + 0.5 * dualWheelWidth)

			if math.abs(totalWheelShapeOffset) < math.abs(totalOffset) then
				totalWheelShapeOffset = math.abs(totalOffset)
				outmostWheelWidth = additionalWheel.width
			end

			if additionalWheel.connector ~= nil then
				local filename = Utils.getFilename(additionalWheel.connector.filename, self.baseDirectory)
				additionalWheel.connector.filename = nil
				local sharedLoadRequestId = self:loadSubSharedI3DFile(filename, false, false, self.onAdditionalWheelConnectorI3DLoaded, self, {
					wheel,
					additionalWheel.connector,
					diameter,
					baseWheelWidth,
					wheelOffset,
					offsetDir,
					dualWheelWidth,
					filename
				})

				table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
			end

			local x, y, z = getTranslation(additionalWheel.linkNode)

			setTranslation(additionalWheel.linkNode, x + totalOffset, y, z)

			if additionalWheel.hasTireTracks then
				additionalWheel.tireTrackNodeIndex = self:addTireTrackNode(wheel, true, wheel.node, additionalWheel.linkNode, additionalWheel.tireTrackAtlasIndex, additionalWheel.width, wheel.radius, wheel.xOffset, wheel.tireIsInverted)
			end

			if additionalWheel.driveGroundParticleSystems ~= nil then
				for name, particleSystems in pairs(additionalWheel.driveGroundParticleSystems) do
					for i = 1, #particleSystems do
						local ps = particleSystems[i]
						ps.offsets[1] = ps.offsets[1] + totalOffset
						local wx, wy, wz = worldToLocal(wheel.node, getWorldTranslation(wheel.driveNode))

						setTranslation(ps.emitterShape, wx + ps.offsets[1], wy + ps.offsets[2], wz + ps.offsets[3])
						table.insert(wheel.driveGroundParticleSystems[name], ps)
					end
				end
			end
		end

		wheel.widthOffset = wheel.widthOffset + offsetDir * totalWheelShapeOffset / 2
		wheel.wheelShapeWidthTotalOffset = totalWheelShapeOffset
		wheel.wheelShapeWidthTmp = wheel.width / 2 + outmostWheelWidth / 2
	end
end

function Wheels:onWheelPartI3DLoaded(i3dNode, failedReason, args)
	local spec = self.spec_wheels
	local wheel = args.wheel
	local parentWheel = args.parentWheel
	local linkNode = args.linkNode
	local name = args.name
	local filename = args.filename
	local index = args.index
	local offset = args.offset
	local widthAndDiam = args.widthAndDiam
	local scale = args.scale
	local fileIdentifier = args.fileIdentifier

	if i3dNode ~= 0 then
		wheel[fileIdentifier] = filename
		wheel[name] = I3DUtil.indexToObject(i3dNode, index)

		if wheel[name] ~= nil then
			link(linkNode, wheel[name])
			delete(i3dNode)

			if offset ~= 0 then
				local dir = 1

				if not wheel.isLeft then
					dir = -1
				end

				setTranslation(wheel[name], offset * dir, 0, 0)
			end

			if scale ~= nil then
				setScale(wheel[name], scale[1], scale[2], scale[3])
			end

			if widthAndDiam ~= nil then
				if getHasShaderParameter(wheel[name], "widthAndDiam") then
					I3DUtil.setShaderParameterRec(wheel[name], "widthAndDiam", widthAndDiam[1], widthAndDiam[2], 0, 0, false)
				else
					local scaleX = MathUtil.inchToM(widthAndDiam[1])
					local scaleZY = MathUtil.inchToM(widthAndDiam[2])

					setScale(wheel[name], scaleX, scaleZY, scaleZY)
				end
			end

			local rimConfigColor = ConfigurationUtil.getColorByConfigId(self, "rimColor", self.configurations.rimColor)
			local rimColor = wheel.color or rimConfigColor or spec.rimColor

			if name == "wheelTire" then
				local zRot = 0

				if wheel.tireIsInverted or parentWheel ~= nil and parentWheel.tireIsInverted then
					zRot = math.pi
				end

				setRotation(wheel.wheelTire, wheel.xRotOffset, 0, zRot)

				local x, y, z, _ = I3DUtil.getShaderParameterRec(wheel.wheelTire, "morphPosition")

				I3DUtil.setShaderParameterRec(wheel.wheelTire, "morphPosition", x, y, z, 0, false)
				I3DUtil.setShaderParameterRec(wheel.wheelTire, "prevMorphPosition", x, y, z, 0, false)
			elseif name == "wheelOuterRim" or name == "wheelInnerRim" then
				if rimColor ~= nil then
					local r, g, b, mat, _ = unpack(rimColor)
					mat = wheel.material or mat

					if wheel.wheelOuterRim ~= nil then
						if mat == nil then
							_, _, _, mat = I3DUtil.getShaderParameterRec(wheel.wheelOuterRim, "colorMat0")
						end

						I3DUtil.setShaderParameterRec(wheel.wheelOuterRim, "colorMat0", r, g, b, mat, false)
					end

					if wheel.wheelInnerRim ~= nil then
						if mat == nil then
							_, _, _, mat = I3DUtil.getShaderParameterRec(wheel.wheelInnerRim, "colorMat0")
						end

						I3DUtil.setShaderParameterRec(wheel.wheelInnerRim, "colorMat0", r, g, b, mat, false)
					end
				end

				if wheel.wheelInnerRim ~= nil then
					for i = 1, 7 do
						local color = spec.hubsColors[i]

						if color ~= nil then
							I3DUtil.setShaderParameterRec(wheel.wheelInnerRim, string.format("colorMat%d", i), color[1], color[2], color[3], color[4], false)
						end
					end
				end
			elseif name == "wheelAdditional" then
				local additionalColor = Utils.getNoNil(wheel.additionalColor, rimColor)

				if wheel.wheelAdditional ~= nil and additionalColor ~= nil then
					local r, g, b, _ = unpack(additionalColor)
					local _, _, _, w = I3DUtil.getShaderParameterRec(wheel.wheelAdditional, "colorMat0")
					w = wheel.additionalMaterial or w

					I3DUtil.setShaderParameterRec(wheel.wheelAdditional, "colorMat0", r, g, b, w, false)
				end
			end
		else
			Logging.xmlWarning(self.xmlFile, "Failed to load node '%s' for file '%s'", index, filename)
		end
	elseif not self.isDeleted and not self.isDeleting then
		Logging.xmlWarning(self.xmlFile, "Failed to load file '%s' wheel part '%s'", filename, name)
	end
end

function Wheels:onAdditionalWheelConnectorI3DLoaded(i3dNode, failedReason, args)
	local wheel, connector, diameter, baseWheelWidth, wheelDistance, offsetDir, dualWheelWidth, filename = unpack(args)

	if i3dNode ~= 0 then
		local node = I3DUtil.indexToObject(i3dNode, connector.nodeStr, self.i3dMappings)

		if node ~= nil then
			connector.node = node
			connector.linkNode = wheel.wheelTire
			connector.filename = filename

			link(wheel.driveNode, connector.node)

			if not connector.useWidthAndDiam then
				if getHasShaderParameter(connector.node, "connectorPos") then
					I3DUtil.setShaderParameterRec(connector.node, "connectorPos", 0, baseWheelWidth, wheelDistance, dualWheelWidth, false)
				end

				local x, _, z, w = I3DUtil.getShaderParameterRec(connector.node, "widthAndDiam")

				I3DUtil.setShaderParameterRec(connector.node, "widthAndDiam", x, diameter, z, w, false)
			else
				local connectorOffset = offsetDir * ((0.5 * baseWheelWidth + 0.5 * wheelDistance) * 0.0254 + connector.additionalOffset)
				local connectorDiameter = connector.diameter or diameter

				setTranslation(connector.node, connectorOffset, 0, 0)
				I3DUtil.setShaderParameterRec(connector.node, "widthAndDiam", connector.width, connectorDiameter, 0, 0, false)
			end

			if connector.usePosAndScale and getHasShaderParameter(connector.node, "connectorPosAndScale") then
				local _, _, _, w = I3DUtil.getShaderParameterRec(connector.node, "connectorPosAndScale")

				I3DUtil.setShaderParameterRec(connector.node, "connectorPosAndScale", connector.startPos, connector.endPos, connector.scale, w, false)
			end

			if connector.color ~= nil and getHasShaderParameter(connector.node, "colorMat0") then
				local r, g, b, mat = unpack(connector.color)

				if mat == nil then
					local _ = nil
					_, _, _, mat = I3DUtil.getShaderParameterRec(connector.node, "colorMat0")
				end

				I3DUtil.setShaderParameterRec(connector.node, "colorMat0", r, g, b, mat, false)
			end
		end

		delete(i3dNode)
	end
end

function Wheels:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end

	local spec = self.spec_wheels

	for _, wheel in pairs(spec.wheels) do
		wheel.xDriveOffset = wheel.netInfo.xDrive
		wheel.updateWheel = false

		self:updateWheelBase(wheel)
		self:updateWheelTireFriction(wheel)
	end

	if self.isServer then
		local brakeForce = self:getBrakeForce()

		for _, wheel in pairs(spec.wheels) do
			setWheelShapeProps(wheel.node, wheel.wheelShape, 0, brakeForce * wheel.brakeFactor, wheel.steeringAngle, wheel.rotationDamping)
			setWheelShapeAutoHoldBrakeForce(wheel.node, wheel.wheelShape, brakeForce * wheel.autoHoldBrakeFactor)
		end

		self:brake(brakeForce)

		spec.wheelCreationTimer = 2
	end

	return true
end

function Wheels:removeFromPhysics(superFunc)
	local ret = superFunc(self)

	if self.isServer then
		local spec = self.spec_wheels

		for _, wheel in pairs(spec.wheels) do
			wheel.wheelShape = 0
			wheel.wheelShapeCreated = false
		end
	end

	return ret
end

function Wheels:getComponentMass(superFunc, component)
	local mass = superFunc(self, component)
	local spec = self.spec_wheels

	for _, wheel in pairs(spec.wheels) do
		if wheel.node == component.node then
			mass = mass + wheel.mass
		end
	end

	return mass
end

function Wheels:getVehicleWorldXRot(superFunc)
	local slopeAngle = 0
	local minWheelZ = math.huge
	local minWheelZHeight = 0
	local maxWheelZ = -math.huge
	local maxWheelZHeight = 0
	local spec = self.spec_wheels

	for i = 1, #spec.wheels do
		local wheel = spec.wheels[i]

		if wheel.hasGroundContact then
			local _, _, z = localToLocal(wheel.node, self.components[1].node, 0, 0, wheel.netInfo.z)
			local _, wheelY, _ = localToWorld(wheel.node, wheel.netInfo.x, wheel.netInfo.y - wheel.radius, wheel.netInfo.z)

			if z < minWheelZ then
				minWheelZ = z
				minWheelZHeight = wheelY
			end

			if maxWheelZ < z then
				maxWheelZ = z
				maxWheelZHeight = wheelY
			end
		end
	end

	if minWheelZ ~= math.huge then
		local y = maxWheelZHeight - minWheelZHeight
		local l = maxWheelZ - minWheelZ

		if l < 0.25 and superFunc ~= nil then
			return superFunc(self)
		end

		slopeAngle = math.pi * 0.5 - math.atan(l / y)

		if slopeAngle > math.pi * 0.5 then
			slopeAngle = slopeAngle - math.pi
		end
	end

	return slopeAngle
end

function Wheels:getVehicleWorldDirection(superFunc)
	local avgDirX = 0
	local avgDirY = 0
	local avgDirZ = 0
	local _ = nil
	local centerZ = 0
	local contactedWheels = 0
	local spec = self.spec_wheels

	for i = 1, #spec.wheels do
		local wheel = spec.wheels[i]

		if wheel.hasGroundContact then
			local _, _, z = localToLocal(wheel.node, self.components[1].node, wheel.netInfo.x, wheel.netInfo.y, wheel.netInfo.z)
			centerZ = centerZ + z
			local dx, dy, dz = localDirectionToWorld(wheel.node, wheel.directionZ, wheel.directionX, -wheel.directionY)
			avgDirZ = avgDirZ + dz
			avgDirY = avgDirY + dy
			avgDirX = avgDirX + dx
			contactedWheels = contactedWheels + 1
		end
	end

	if contactedWheels > 0 then
		avgDirZ = avgDirZ / contactedWheels
		_ = avgDirY / contactedWheels
		avgDirX = avgDirX / contactedWheels
	end

	if contactedWheels > 2 then
		centerZ = centerZ / contactedWheels
		local frontCenterX = 0
		local frontCenterY = 0
		local frontCenterZ = 0
		local frontWheelsCount = 0
		local backCenterX = 0
		local backCenterY = 0
		local backCenterZ = 0
		local backWheelsCount = 0

		for i = 1, #spec.wheels do
			local wheel = spec.wheels[i]

			if wheel.hasGroundContact then
				local x, y, z = localToLocal(wheel.node, self.components[1].node, wheel.netInfo.x + wheel.directionX * wheel.radius, wheel.netInfo.y + wheel.directionY * wheel.radius, wheel.netInfo.z + wheel.directionZ * wheel.radius)

				if z > centerZ + 0.25 then
					frontWheelsCount = frontWheelsCount + 1
					frontCenterZ = frontCenterZ + z
					frontCenterY = frontCenterY + y
					frontCenterX = frontCenterX + x
				elseif z < centerZ - 0.25 then
					backWheelsCount = backWheelsCount + 1
					backCenterZ = backCenterZ + z
					backCenterY = backCenterY + y
					backCenterX = backCenterX + x
				end
			end
		end

		if frontWheelsCount > 0 and backWheelsCount > 0 then
			frontCenterZ = frontCenterZ / frontWheelsCount
			frontCenterY = frontCenterY / frontWheelsCount
			frontCenterX = frontCenterX / frontWheelsCount
			backCenterZ = backCenterZ / backWheelsCount
			backCenterY = backCenterY / backWheelsCount
			backCenterX = backCenterX / backWheelsCount
			frontCenterX, frontCenterY, frontCenterZ = localToWorld(self.components[1].node, frontCenterX, frontCenterY, frontCenterZ)
			backCenterX, backCenterY, backCenterZ = localToWorld(self.components[1].node, backCenterX, backCenterY, backCenterZ)

			if VehicleDebug.state == VehicleDebug.DEBUG_TRANSMISSION then
				DebugUtil.drawDebugGizmoAtWorldPos(frontCenterX, frontCenterY, frontCenterZ, 1, 0, 0, 0, 1, 0, "frontWheels", false)
				DebugUtil.drawDebugGizmoAtWorldPos(backCenterX, backCenterY, backCenterZ, 1, 0, 0, 0, 1, 0, "backWheels", false)
			end

			local dx = frontCenterX - backCenterX
			local dy = frontCenterY - backCenterY
			local dz = frontCenterZ - backCenterZ
			local _ = nil
			_, avgDirY, _ = MathUtil.vector3Normalize(dx, dy, dz)
		else
			return superFunc(self)
		end
	else
		return 0, 0, 0
	end

	return MathUtil.vector3Normalize(avgDirX, avgDirY, avgDirZ)
end

function Wheels:validateWashableNode(superFunc, node)
	if Vehicle.LOAD_STEP_FINISHED <= self.loadingStep then
		local spec = self.spec_wheels

		for i = 1, #spec.wheels do
			local wheel = spec.wheels[i]
			local wheelNode = wheel.driveNode

			if wheel.linkNode ~= wheel.driveNode then
				wheelNode = wheel.linkNode
			end

			if wheel.wheelDirtNodes == nil then
				wheel.wheelDirtNodes = {}

				I3DUtil.getNodesByShaderParam(wheelNode, "RDT", wheel.wheelDirtNodes)
			end

			if wheel.wheelDirtNodes[node] ~= nil then
				local nodeData = {
					wheel = wheel,
					fieldDirtMultiplier = wheel.fieldDirtMultiplier,
					streetDirtMultiplier = wheel.streetDirtMultiplier,
					minDirtPercentage = wheel.minDirtPercentage,
					maxDirtOffset = wheel.maxDirtOffset,
					dirtColorChangeSpeed = wheel.dirtColorChangeSpeed,
					isSnowNode = true
				}

				function nodeData.loadFromSavegameFunc(xmlFile, key)
					nodeData.wheel.snowScale = xmlFile:getValue(key .. "#snowScale", 0)
					local defaultColor, snowColor = g_currentMission.environment:getDirtColors()
					local r, g, b = MathUtil.lerp3(defaultColor[1], defaultColor[2], defaultColor[3], snowColor[1], snowColor[2], snowColor[3], nodeData.wheel.snowScale)
					local washableNode = self:getWashableNodeByCustomIndex(wheel)

					self:setNodeDirtColor(washableNode, r, g, b, true)
				end

				function nodeData.saveToSavegameFunc(xmlFile, key)
					xmlFile:setValue(key .. "#snowScale", nodeData.wheel.snowScale)
				end

				return false, self.updateWheelDirtAmount, wheel, nodeData
			end
		end
	end

	return superFunc(self, node)
end

function Wheels:getAIDirectionNode(superFunc)
	return self.spec_wheels.steeringCenterNode or superFunc(self)
end

function Wheels:getAIRootNode(superFunc)
	return self.spec_wheels.steeringCenterNode or superFunc(self)
end

function Wheels:updateWheelDirtAmount(nodeData, dt, allowsWashingByRain, rainScale, timeSinceLastRain, temperature)
	local dirtAmount = self:updateDirtAmount(nodeData, dt, allowsWashingByRain, rainScale, timeSinceLastRain, temperature)
	local allowManipulation = true

	if nodeData.wheel ~= nil and nodeData.wheel.contact == Wheels.WHEEL_NO_CONTACT then
		allowManipulation = false
	end

	if allowManipulation then
		local spec = self.spec_wheels
		local isOnField = nodeData.wheel.hasSnowContact

		if nodeData.wheel ~= nil and nodeData.wheel.densityType ~= 0 and nodeData.wheel.densityType ~= spec.tireTrackGroundGrassValue and nodeData.wheel.densityType ~= spec.tireTrackGroundGrassCutValue then
			isOnField = true
		end

		local lastSpeed = self.lastSpeed * 3600

		if isOnField then
			dirtAmount = dirtAmount * nodeData.fieldDirtMultiplier
		elseif nodeData.minDirtPercentage < nodeData.dirtAmount then
			local speedFactor = lastSpeed / 20
			dirtAmount = dirtAmount * nodeData.streetDirtMultiplier * speedFactor
		end

		local globalValue = self.spec_washable.washableNodes[1].dirtAmount
		local minDirtOffset = nodeData.maxDirtOffset * (math.pow(1 - globalValue, 2) * 0.75 + 0.25)
		local maxDirtOffset = nodeData.maxDirtOffset * (math.pow(1 - globalValue, 2) * 0.95 + 0.05)

		if minDirtOffset < globalValue - nodeData.dirtAmount then
			if dirtAmount < 0 then
				dirtAmount = 0
			end
		elseif globalValue - nodeData.dirtAmount < -maxDirtOffset and dirtAmount > 0 then
			dirtAmount = 0
		end

		local factor = nodeData.wheel.hasSnowContact and 1 or -0.25
		local speedFactor = math.min(lastSpeed / 5, 2)
		local lastSnowScale = nodeData.wheel.snowScale
		nodeData.wheel.snowScale = math.min(math.max(lastSnowScale + factor * dt * nodeData.dirtColorChangeSpeed * speedFactor, 0), 1)

		if nodeData.wheel.snowScale ~= lastSnowScale then
			local defaultColor, snowColor = g_currentMission.environment:getDirtColors()
			local r, g, b = MathUtil.lerp3(defaultColor[1], defaultColor[2], defaultColor[3], snowColor[1], snowColor[2], snowColor[3], nodeData.wheel.snowScale)

			self:setNodeDirtColor(nodeData, r, g, b)
		end
	end

	return dirtAmount
end

function Wheels:getAllowTireTracks()
	return self.currentUpdateDistance < Wheels.MAX_TIRE_TRACK_CREATION_DISTANCE and self.spec_wheels.tyreTracksSegmentsCoeff > 0
end

function Wheels:setWheelPositionDirty(wheel)
	if wheel ~= nil then
		wheel.isPositionDirty = true
	end
end

function Wheels:setWheelTireFrictionDirty(wheel)
	if wheel ~= nil then
		wheel.isFrictionDirty = true
	end
end

function Wheels:updateWheelContact(wheel)
	local wx = wheel.netInfo.x
	local wy = wheel.netInfo.y
	local wz = wheel.netInfo.z
	wy = wy - wheel.radius
	wx = wx + wheel.xOffset
	wx, wy, wz = localToWorld(wheel.node, wx, wy, wz)
	local mission = g_currentMission

	if self.isServer and self.isAddedToPhysics and wheel.wheelShapeCreated then
		wheel.hasGroundContact = getWheelShapeContactPoint(wheel.node, wheel.wheelShape) ~= nil
		local contactObject, contactSubShapeIndex = getWheelShapeContactObject(wheel.node, wheel.wheelShape)

		if contactObject == mission.terrainRootNode then
			if contactSubShapeIndex <= 0 then
				wheel.contact = Wheels.WHEEL_GROUND_CONTACT
			else
				wheel.contact = Wheels.WHEEL_GROUND_HEIGHT_CONTACT
			end
		elseif wheel.hasGroundContact and contactObject ~= 0 then
			wheel.contact = Wheels.WHEEL_OBJ_CONTACT
			wheel.lastContactObjectAllowsTireTracks = getRigidBodyType(contactObject) == RigidBodyType.STATIC and getUserAttribute(contactObject, "noTireTracks") ~= true
		else
			wheel.contact = Wheels.WHEEL_NO_CONTACT
		end
	end

	if wheel.contact == Wheels.WHEEL_GROUND_CONTACT then
		local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
		wheel.densityBits = getDensityAtWorldPos(groundTypeMapId, wx, wy, wz)
		wheel.densityType = bitAND(bitShiftRight(wheel.densityBits, groundTypeFirstChannel), 2^groundTypeNumChannels - 1)
	else
		wheel.densityBits = 0
		wheel.densityType = 0
	end

	if wheel.contact ~= Wheels.WHEEL_NO_CONTACT then
		local densityHeightBits = getDensityAtWorldPos(mission.terrainDetailHeightId, wx, wy, wz)
		local numChannels = g_densityMapHeightManager.heightTypeNumChannels
		local heightType = bitAND(densityHeightBits, 2^numChannels - 1)
		wheel.hasSnowContact = heightType == self.spec_wheels.snowSystem.snowHeightTypeIndex
	else
		wheel.hasSnowContact = false
	end

	wheel.shallowWater = wy < self.waterY
end

function Wheels:getTireTrackColor(wheel, wx, wy, wz, groundWetness)
	local r, g, b = nil
	local a = 0
	local t = nil

	if wheel.contact == Wheels.WHEEL_GROUND_CONTACT then
		local isOnField = wheel.densityType ~= 0
		local dirtAmount = 1

		if isOnField then
			local spec = self.spec_wheels
			r, g, b, a = spec.fieldGroundSystem:getFieldGroundTyreTrackColor(wheel.densityBits)
			t = 1

			if wheel.densityType == spec.tireTrackGroundGrassValue then
				dirtAmount = 0.7
			elseif wheel.densityType == spec.tireTrackGroundGrassCutValue then
				dirtAmount = 0.6
			end
		else
			r, g, b, a, t = getTerrainAttributesAtWorldPos(g_currentMission.terrainRootNode, wx, wy, wz, true, true, true, true, false)
			dirtAmount = 0.5
		end

		wheel.dirtAmount = dirtAmount
		wheel.lastColor[1] = r
		wheel.lastColor[2] = g
		wheel.lastColor[3] = b
		wheel.lastColor[4] = a
		wheel.lastTerrainAttribute = t
	elseif wheel.contact == Wheels.WHEEL_OBJ_CONTACT and wheel.lastContactObjectAllowsTireTracks and wheel.dirtAmount > 0 then
		local maxTrackLength = 30 * (1 + groundWetness)
		local speedFactor = math.min(self:getLastSpeed(), 20) / 20
		maxTrackLength = maxTrackLength * (2 - speedFactor)
		wheel.dirtAmount = math.max(wheel.dirtAmount - self.lastMovedDistance / maxTrackLength, 0)
		b = wheel.lastColor[3]
		g = wheel.lastColor[2]
		r = wheel.lastColor[1]
		a = 0
	end

	return r, g, b, a, t
end

function Wheels:forceUpdateWheelPhysics(dt)
	local spec = self.spec_wheels

	for i = 1, #spec.wheels do
		WheelsUtil.updateWheelPhysics(self, spec.wheels[i], spec.brakePedal, dt)
	end
end

function Wheels:addTireTrackNode(wheel, isAdditionalTrack, parent, linkNode, tireTrackAtlasIndex, width, radius, xOffset, inverted, activeFunc)
	local spec = self.spec_wheels
	local tireTrackNode = {
		wheel = wheel,
		isAdditionalTrack = isAdditionalTrack,
		parent = parent,
		linkNode = linkNode,
		tireTrackAtlasIndex = tireTrackAtlasIndex,
		width = width,
		radius = radius,
		xOffset = xOffset,
		inverted = inverted,
		activeFunc = activeFunc
	}

	if self.tireTrackSystem ~= nil then
		tireTrackNode.tireTrackIndex = self.tireTrackSystem:createTrack(width, tireTrackAtlasIndex)

		if tireTrackNode.tireTrackIndex ~= nil then
			table.insert(spec.tireTrackNodes, tireTrackNode)

			return #spec.tireTrackNodes
		end
	end
end

function Wheels:updateTireTrackNode(tireTrackNode, allowTireTracks, groundWetness)
	local wheel = tireTrackNode.wheel

	if not allowTireTracks then
		self.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)

		return
	end

	if tireTrackNode.activeFunc ~= nil and not tireTrackNode.activeFunc() then
		self.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)

		return
	end

	local wx, wy, wz = nil

	if not tireTrackNode.isAdditionalTrack then
		local netInfo = wheel.netInfo
		wz = netInfo.z
		wy = netInfo.y
		wx = netInfo.x
	else
		wx, wy, wz = worldToLocal(tireTrackNode.parent, getWorldTranslation(tireTrackNode.linkNode))
	end

	wy = wy - tireTrackNode.radius
	wx = wx + tireTrackNode.xOffset
	wx, wy, wz = localToWorld(tireTrackNode.parent, wx, wy, wz)
	wy = math.max(wy, getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx, wy, wz))
	local r, g, b, a, _ = self:getTireTrackColor(wheel, wx, wy, wz, groundWetness)

	if r ~= nil then
		local ux, uy, uz = localDirectionToWorld(wheel.node, -wheel.directionX, -wheel.directionY, -wheel.directionZ)
		local tireDirection = self.movingDirection

		if tireTrackNode.inverted then
			tireDirection = tireDirection * -1
		end

		self.tireTrackSystem:addTrackPoint(tireTrackNode.tireTrackIndex, wx, wy, wz, ux, uy, uz, r, g, b, wheel.dirtAmount, a, tireDirection)
	else
		self.tireTrackSystem:cutTrack(tireTrackNode.tireTrackIndex)
	end
end

function Wheels:getCurrentSurfaceSound()
	local spec = self.spec_wheels

	for i, wheel in ipairs(spec.wheels) do
		if wheel.hasTireTracks or i == #spec.wheels then
			if wheel.contact == Wheels.WHEEL_GROUND_CONTACT then
				local isOnField = wheel.densityType ~= 0
				local shallowWater = wheel.shallowWater

				if isOnField then
					return spec.surfaceNameToSound.field
				elseif shallowWater then
					return spec.surfaceNameToSound.shallowWater
				else
					local lastTerrainAttribute = wheel.lastTerrainAttribute

					if not wheel.hasTireTracks then
						local wx, wy, wz = getWorldTranslation(wheel.driveNode)
						local _, _, _, _, t = getTerrainAttributesAtWorldPos(g_currentMission.terrainRootNode, wx, wy, wz, true, true, true, true, false)
						lastTerrainAttribute = t
					end

					return spec.surfaceIdToSound[lastTerrainAttribute]
				end
			elseif wheel.contact == Wheels.WHEEL_GROUND_HEIGHT_CONTACT then
				if wheel.hasSnowContact then
					return spec.surfaceNameToSound.snow
				end
			elseif wheel.contact == Wheels.WHEEL_OBJ_CONTACT then
				return spec.surfaceNameToSound.asphalt
			elseif wheel.contact ~= Wheels.WHEEL_NO_CONTACT then
				break
			end
		end
	end
end

function Wheels:getAreSurfaceSoundsActive()
	return self.isActive
end

function Wheels:updateWheelDensityMapHeight(wheel, dt)
	if not self.isServer then
		return
	end

	local spec = self.spec_wheels
	local wheelSmoothAmount = 0

	if self.lastSpeedReal > 0.0002 then
		wheelSmoothAmount = spec.wheelSmoothAccumulation + math.max(self.lastMovedDistance * 1.2, 0.0003 * dt)
		local rounded = DensityMapHeightUtil.getRoundedHeightValue(wheelSmoothAmount)
		spec.wheelSmoothAccumulation = wheelSmoothAmount - rounded
	else
		spec.wheelSmoothAccumulation = 0
	end

	if wheelSmoothAmount == 0 then
		return
	end

	local wx = wheel.netInfo.x
	local wy = wheel.netInfo.y
	local wz = wheel.netInfo.z
	wy = wy - wheel.radius
	wx = wx + wheel.xOffset
	wx, wy, wz = localToWorld(wheel.node, wx, wy, wz)

	if wheel.smoothGroundRadius > 0 then
		local smoothYOffset = -0.1
		local heightType = DensityMapHeightUtil.getHeightTypeDescAtWorldPos(wx, wy, wz, wheel.smoothGroundRadius)

		if heightType ~= nil and heightType.allowsSmoothing then
			local terrainHeightUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()

			if terrainHeightUpdater ~= nil then
				local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx, wy, wz)
				local physicsDeltaHeight = wy - terrainHeight
				local deltaHeight = (physicsDeltaHeight + heightType.collisionBaseOffset) / heightType.collisionScale
				deltaHeight = math.min(math.max(deltaHeight, physicsDeltaHeight + heightType.minCollisionOffset), physicsDeltaHeight + heightType.maxCollisionOffset)
				deltaHeight = math.max(deltaHeight + smoothYOffset, 0)
				local internalHeight = terrainHeight + deltaHeight

				smoothDensityMapHeightAtWorldPos(terrainHeightUpdater, wx, internalHeight, wz, wheelSmoothAmount, heightType.index, 0, wheel.smoothGroundRadius, wheel.smoothGroundRadius + 1.2)

				if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
					DebugUtil.drawDebugCircle(wx, internalHeight, wz, wheel.smoothGroundRadius, 10)
				end
			end
		end

		if wheel.additionalWheels ~= nil then
			for _, additionalWheel in pairs(wheel.additionalWheels) do
				local refNode = wheel.repr
				local xShift, yShift, zShift = localToLocal(additionalWheel.wheelTire, refNode, additionalWheel.xOffset, 0, 0)
				wx, wy, wz = localToWorld(refNode, xShift, yShift - additionalWheel.radius, zShift)
				heightType = DensityMapHeightUtil.getHeightTypeDescAtWorldPos(wx, wy, wz, additionalWheel.smoothGroundRadius)

				if heightType ~= nil and heightType.allowsSmoothing then
					local terrainHeightUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()

					if terrainHeightUpdater ~= nil then
						local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx, wy, wz)
						local physicsDeltaHeight = wy - terrainHeight
						local deltaHeight = (physicsDeltaHeight + heightType.collisionBaseOffset) / heightType.collisionScale
						deltaHeight = math.min(math.max(deltaHeight, physicsDeltaHeight + heightType.minCollisionOffset), physicsDeltaHeight + heightType.maxCollisionOffset)
						deltaHeight = math.max(deltaHeight + smoothYOffset, 0)
						local internalHeight = terrainHeight + deltaHeight

						smoothDensityMapHeightAtWorldPos(terrainHeightUpdater, wx, internalHeight, wz, wheelSmoothAmount, heightType.index, 0, additionalWheel.smoothGroundRadius, additionalWheel.smoothGroundRadius + 1.2)

						if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
							DebugUtil.drawDebugCircle(wx, internalHeight, wz, additionalWheel.smoothGroundRadius, 10)
						end
					end
				end
			end
		end
	end
end

function Wheels:updateWheelDestruction(wheel, dt)
	local doFruitDestruction = self:getIsWheelFoliageDestructionAllowed(wheel)
	local doSnowDestruction = wheel.contact ~= Wheels.WHEEL_NO_CONTACT and wheel.hasSnowContact

	if doFruitDestruction or doSnowDestruction then
		if doFruitDestruction then
			local x0, _, z0 = getWorldTranslation(wheel.destructionStartNode)

			if g_currentMission.accessHandler:canFarmAccessLand(self:getActiveFarm(), x0, z0) then
				local x1, _, z1 = getWorldTranslation(wheel.destructionWidthNode)
				local x2, _, z2 = getWorldTranslation(wheel.destructionHeightNode)

				self:destroyFruitArea(x0, z0, x1, z1, x2, z2)
			end
		end

		if doSnowDestruction then
			local snowOffset = wheel.radius * 0.75 * self.movingDirection
			local x3, _, z3 = localToWorld(wheel.destructionStartNode, 0, 0, snowOffset)
			local x4, _, z4 = localToWorld(wheel.destructionWidthNode, 0, 0, snowOffset)
			local x5, _, z5 = localToWorld(wheel.destructionHeightNode, 0, 0, snowOffset)

			self:destroySnowArea(x3, z3, x4, z4, x5, z5)
		end

		if wheel.additionalWheels ~= nil then
			for _, additionalWheel in pairs(wheel.additionalWheels) do
				local width = 0.5 * additionalWheel.width
				local length = math.min(0.5, 0.5 * additionalWheel.width)
				local refNode = wheel.node

				if wheel.repr ~= wheel.driveNode then
					refNode = wheel.repr
				end

				local xShift, yShift, zShift = localToLocal(additionalWheel.wheelTire, refNode, 0, 0, 0)

				if doFruitDestruction then
					local x0, _, z0 = localToWorld(refNode, xShift + width, yShift, zShift - length)

					if g_farmlandManager:getIsOwnedByFarmAtWorldPosition(self:getActiveFarm(), x0, z0) then
						local x1, _, z1 = localToWorld(refNode, xShift - width, yShift, zShift - length)
						local x2, _, z2 = localToWorld(refNode, xShift + width, yShift, zShift + length)

						self:destroyFruitArea(x0, z0, x1, z1, x2, z2)
					end
				end

				if doSnowDestruction then
					local snowOffset = wheel.radius * 0.75 * self.movingDirection
					local x3, _, z3 = localToWorld(refNode, xShift + width, yShift, zShift - length + snowOffset)
					local x4, _, z4 = localToWorld(refNode, xShift - width, yShift, zShift - length + snowOffset)
					local x5, _, z5 = localToWorld(refNode, xShift + width, yShift, zShift + length + snowOffset)

					self:destroySnowArea(x3, z3, x4, z4, x5, z5)
				end
			end
		end
	end
end

function Wheels:getIsWheelFoliageDestructionAllowed(wheel)
	if not g_currentMission.missionInfo.fruitDestruction then
		return false
	end

	if self:getIsAIActive() then
		return false
	end

	if wheel.contact ~= Wheels.WHEEL_GROUND_CONTACT then
		return false
	end

	if wheel.isCareWheel then
		return false
	end

	if self.getBlockFoliageDestruction ~= nil and self:getBlockFoliageDestruction() then
		return false
	end

	return true
end

function Wheels:updateWheelSink(wheel, dt, groundWetness)
	if wheel.supportsWheelSink and self.isServer and self.isAddedToPhysics then
		local spec = self.spec_wheels
		local maxSink = wheel.maxWheelSink
		local sinkTarget = wheel.sinkTarget
		local lastSpeed = self:getLastSpeed()
		local interpolationFactor = 1

		if wheel.contact ~= Wheels.WHEEL_NO_CONTACT and lastSpeed > 0.3 then
			local x, _, z = getWorldTranslation(wheel.repr)
			local noiseValue = 0

			if wheel.densityType > 0 then
				local xPerlin = math.floor(x * 100) * 0.01
				local zPerlin = math.floor(z * 100) * 0.01
				local perlinNoise = Wheels.perlinNoiseSink
				local noiseSink = 0.5 * (1 + getPerlinNoise2D(xPerlin * perlinNoise.randomFrequency, zPerlin * perlinNoise.randomFrequency, perlinNoise.persistence, perlinNoise.numOctaves, perlinNoise.randomSeed))
				perlinNoise = Wheels.perlinNoiseWobble
				local noiseWobble = 0.5 * (1 + getPerlinNoise2D(xPerlin * perlinNoise.randomFrequency, zPerlin * perlinNoise.randomFrequency, perlinNoise.persistence, perlinNoise.numOctaves, perlinNoise.randomSeed))
				local gravity = 9.81
				local tireLoad = getWheelShapeContactForce(wheel.node, wheel.wheelShape)

				if tireLoad ~= nil then
					local nx, ny, nz = getWheelShapeContactNormal(wheel.node, wheel.wheelShape)
					local dx, dy, dz = localDirectionToWorld(wheel.node, 0, -1, 0)
					tireLoad = -tireLoad * MathUtil.dotProduct(dx, dy, dz, nx, ny, nz)
					tireLoad = tireLoad + math.max(ny * gravity, 0) * wheel.mass
				else
					tireLoad = 0
				end

				tireLoad = tireLoad / gravity
				local loadFactor = math.min(1, math.max(0, tireLoad / wheel.maxLatStiffnessLoad))
				noiseSink = 0.333 * (2 * loadFactor + groundWetness) * noiseSink
				noiseValue = math.max(noiseSink, noiseWobble)
			end

			maxSink = Wheels.MAX_SINK[wheel.densityType] or maxSink

			if wheel.densityType == FieldGroundType.PLOWED and wheel.oppositeWheelIndex ~= nil then
				local oppositeWheel = spec.wheels[wheel.oppositeWheelIndex]

				if oppositeWheel.densityType ~= nil and oppositeWheel.densityType ~= FieldGroundType.PLOWED then
					maxSink = maxSink * 1.3
				end
			end

			sinkTarget = math.min(0.2 * wheel.radiusOriginal, math.min(maxSink, wheel.maxWheelSink) * noiseValue)
		elseif wheel.contact == Wheels.WHEEL_NO_CONTACT then
			sinkTarget = 0
			interpolationFactor = 0.05
		end

		if wheel.sinkTarget < sinkTarget then
			wheel.sinkTarget = math.min(sinkTarget, wheel.sinkTarget + 0.05 * math.min(30, math.max(0, lastSpeed - 0.2)) * dt / 1000 * interpolationFactor)
		elseif sinkTarget < wheel.sinkTarget then
			wheel.sinkTarget = math.max(sinkTarget, wheel.sinkTarget - 0.05 * math.min(30, math.max(0, lastSpeed - 0.2)) * dt / 1000 * interpolationFactor)
		end

		if math.abs(wheel.sink - wheel.sinkTarget) > 0.001 then
			wheel.sink = wheel.sinkTarget
			local radius = wheel.radiusOriginal - wheel.sink

			if radius ~= wheel.radius then
				wheel.radius = radius

				if self.isServer then
					self:setWheelPositionDirty(wheel)

					local sinkFactor = wheel.sink / maxSink * (1 + 0.4 * groundWetness)
					wheel.sinkLongStiffnessFactor = 1 - 0.1 * sinkFactor
					wheel.sinkLatStiffnessFactor = 1 - 0.2 * sinkFactor

					self:setWheelTireFrictionDirty(wheel)
				end
			end
		end
	end
end

function Wheels:updateWheelFriction(wheel, dt, groundWetness)
	if self.isServer then
		local isOnField = wheel.densityType ~= 0
		local depth = wheel.lastColor[4]
		local snowScale = 0

		if wheel.hasSnowContact then
			groundWetness = 0
			snowScale = 1
		end

		local groundType = WheelsUtil.getGroundType(isOnField, wheel.contact ~= Wheels.WHEEL_GROUND_CONTACT, depth)
		local coeff = WheelsUtil.getTireFriction(wheel.tireType, groundType, groundWetness, snowScale)

		if self:getLastSpeed() > 0.2 and coeff ~= wheel.tireGroundFrictionCoeff then
			wheel.tireGroundFrictionCoeff = coeff

			self:setWheelTireFrictionDirty(wheel)
		end
	end
end

function Wheels:updateWheelBase(wheel)
	if self.isServer and self.isAddedToPhysics then
		local positionX = wheel.positionX - wheel.directionX * wheel.deltaY
		local positionY = wheel.positionY - wheel.directionY * wheel.deltaY
		local positionZ = wheel.positionZ - wheel.directionZ * wheel.deltaY
		local collisionMask = 251
		wheel.wheelShape = createWheelShape(wheel.node, positionX, positionY, positionZ, wheel.radius, wheel.suspTravel, wheel.spring, wheel.damperCompressionLowSpeed, wheel.damperCompressionHighSpeed, wheel.damperCompressionLowSpeedThreshold, wheel.damperRelaxationLowSpeed, wheel.damperRelaxationHighSpeed, wheel.damperRelaxationLowSpeedThreshold, wheel.mass, collisionMask, wheel.wheelShape)
		local forcePointY = positionY - wheel.radius * wheel.forcePointRatio
		local steeringX, steeringY, steeringZ = localToLocal(getParent(wheel.repr), wheel.node, wheel.startPositionX, wheel.startPositionY + wheel.deltaY, wheel.startPositionZ)

		setWheelShapeForcePoint(wheel.node, wheel.wheelShape, wheel.positionX, forcePointY, positionZ)
		setWheelShapeSteeringCenter(wheel.node, wheel.wheelShape, steeringX, steeringY, steeringZ)
		setWheelShapeDirection(wheel.node, wheel.wheelShape, wheel.directionX, wheel.directionY, wheel.directionZ, wheel.axleX, wheel.axleY, wheel.axleZ)
		setWheelShapeWidth(wheel.node, wheel.wheelShape, wheel.wheelShapeWidth, wheel.widthOffset)

		if wheel.driveGroundParticleSystems ~= nil then
			for _, typedPs in pairs(wheel.driveGroundParticleSystems) do
				for _, ps in ipairs(typedPs) do
					setTranslation(ps.emitterShape, wheel.positionX + ps.offsets[1], positionY + ps.offsets[2], wheel.positionZ + ps.offsets[3])
				end
			end
		end
	end
end

function Wheels:updateWheelTireFriction(wheel)
	if self.isServer and self.isAddedToPhysics then
		setWheelShapeTireFriction(wheel.node, wheel.wheelShape, wheel.sinkFrictionScaleFactor * wheel.maxLongStiffness, wheel.sinkLatStiffnessFactor * wheel.maxLatStiffness, wheel.maxLatStiffnessLoad, wheel.sinkFrictionScaleFactor * wheel.frictionScale * wheel.tireGroundFrictionCoeff)
	end
end

function Wheels:getDriveGroundParticleSystemsScale(particleSystem, speed)
	local wheel = particleSystem.wheel

	if wheel ~= nil then
		if particleSystem.onlyActiveOnGroundContact and wheel.contact ~= Wheels.WHEEL_GROUND_CONTACT and not wheel.hasSnowContact then
			return 0
		end

		if not Wheels.GROUND_PARTICLES[wheel.lastTerrainAttribute] and not wheel.hasSnowContact then
			return 0
		end

		local grassValue = g_currentMission.fieldGroundSystem:getFieldGroundValue(FieldGroundType.GRASS)

		if wheel.densityType == grassValue then
			return 0
		end
	end

	local minSpeed = particleSystem.minSpeed
	local direction = particleSystem.direction

	if minSpeed < speed and (direction == 0 or direction > 0 == (self.movingDirection > 0)) then
		local maxSpeed = particleSystem.maxSpeed
		local alpha = math.min((speed - minSpeed) / (maxSpeed - minSpeed), 1)
		local scale = MathUtil.lerp(particleSystem.minScale, particleSystem.maxScale, alpha)

		return scale
	end

	return 0
end

function Wheels:getIsVersatileYRotActive(wheel)
	return true
end

function Wheels:getWheelFromWheelIndex(wheelIndex)
	return self.spec_wheels.wheels[wheelIndex]
end

function Wheels:getWheelByWheelNode(wheelNode)
	local spec = self.spec_wheels

	if type(wheelNode) == "string" then
		local mapping = self.i3dMappings[wheelNode]

		if mapping ~= nil then
			wheelNode = mapping.nodeId
		end
	end

	for i = 1, #spec.wheels do
		local wheel = spec.wheels[i]

		if wheel.repr == wheelNode or wheel.driveNode == wheelNode or wheel.linkNode == wheelNode then
			return wheel
		end
	end

	return nil
end

function Wheels:getWheels()
	return self.spec_wheels.wheels
end

function Wheels:destroyFruitArea(x0, z0, x1, z1, x2, z2)
	FSDensityMapUtil.updateWheelDestructionArea(x0, z0, x1, z1, x2, z2)
end

function Wheels:destroySnowArea(x0, z0, x1, z1, x2, z2)
	local spec = self.spec_wheels
	local curHeight = spec.snowSystem:getSnowHeightAtArea(x0, z0, x1, z1, x2, z2)
	local sinkHeight = curHeight

	if curHeight > SnowSystem.MAX_HEIGHT * 1.5 then
		sinkHeight = curHeight * 0.9
	elseif curHeight == spec.snowSystem.height then
		sinkHeight = math.min(spec.snowSystem.height, SnowSystem.MAX_HEIGHT) * 0.7
	end

	if SnowSystem.MIN_LAYER_HEIGHT <= sinkHeight and sinkHeight ~= curHeight then
		spec.snowSystem:setSnowHeightAtArea(x0, z0, x1, z1, x2, z2, sinkHeight)
	end
end

function Wheels:brake(brakePedal)
	local spec = self.spec_wheels

	if brakePedal ~= spec.brakePedal then
		spec.brakePedal = brakePedal

		for _, wheel in pairs(spec.wheels) do
			WheelsUtil.updateWheelPhysics(self, wheel, spec.brakePedal, 0)
		end

		SpecializationUtil.raiseEvent(self, "onBrake", spec.brakePedal)
	end
end

function Wheels:getBrakeForce()
	return 0
end

function Wheels:updateWheelChocksPosition(isInParkingPosition, continueUpdate)
	local spec = self.spec_wheels

	for _, wheelChock in pairs(spec.wheelChocks) do
		wheelChock.wheel.updateWheelChock = continueUpdate
		isInParkingPosition = Utils.getNoNil(isInParkingPosition, wheelChock.isParked)

		self:updateWheelChockPosition(wheelChock, isInParkingPosition)
	end
end

function Wheels:updateWheelChockPosition(wheelChock, isInParkingPosition)
	if isInParkingPosition == nil then
		isInParkingPosition = wheelChock.isInParkingPosition
	end

	wheelChock.isInParkingPosition = isInParkingPosition

	if isInParkingPosition then
		if wheelChock.parkingNode ~= nil then
			setTranslation(wheelChock.node, 0, 0, 0)
			setRotation(wheelChock.node, 0, 0, 0)
			link(wheelChock.parkingNode, wheelChock.node)
			setVisibility(wheelChock.node, true)
		else
			setVisibility(wheelChock.node, false)
		end
	else
		setVisibility(wheelChock.node, true)

		local wheel = wheelChock.wheel
		local radiusChockHeightOffset = wheel.radius - wheel.deformation - wheelChock.height
		local angle = math.acos(radiusChockHeightOffset / wheel.radius)
		local zWheelIntersection = wheel.radius * math.sin(angle)
		local zChockOffset = -zWheelIntersection - wheelChock.zOffset

		link(wheel.node, wheelChock.node)

		local _, yRot, _ = localRotationToLocal(getParent(wheel.repr), wheel.node, getRotation(wheel.repr))

		if wheelChock.isInverted then
			yRot = yRot + math.pi
		end

		setRotation(wheelChock.node, 0, yRot, 0)

		local dirX, dirY, dirZ = localDirectionToLocal(wheelChock.node, wheel.node, 0, 0, 1)
		local normX, normY, normZ = localDirectionToLocal(wheelChock.node, wheel.node, 1, 0, 0)
		local posX, posY, posZ = localToLocal(wheel.driveNode, wheel.node, 0, 0, 0)
		posX = posX + normX * wheelChock.offset[1] + dirX * (zChockOffset + wheelChock.offset[3])
		posY = posY + normY * wheelChock.offset[1] + dirY * (zChockOffset + wheelChock.offset[3]) - wheel.radius + wheel.deformation + wheelChock.offset[2]
		posZ = posZ + normZ * wheelChock.offset[1] + dirZ * (zChockOffset + wheelChock.offset[3])

		setTranslation(wheelChock.node, posX, posY, posZ)
	end

	if wheelChock.parkedNode ~= nil then
		setVisibility(wheelChock.parkedNode, isInParkingPosition)
	end

	if wheelChock.linkedNode ~= nil then
		setVisibility(wheelChock.linkedNode, not isInParkingPosition)
	end

	return true
end

function Wheels:onLeaveVehicle()
	local spec = self.spec_wheels

	if self.isServer and self.isAddedToPhysics then
		for _, wheel in pairs(spec.wheels) do
			setWheelShapeProps(wheel.node, wheel.wheelShape, 0, self:getBrakeForce() * wheel.brakeFactor, wheel.steeringAngle, wheel.rotationDamping)
		end
	end
end

function Wheels:onPreAttach()
	self:updateWheelChocksPosition(true, false)
end

function Wheels:onPostDetach()
	self:updateWheelChocksPosition(false, true)
end

function Wheels:getSteeringRotTimeByCurvature(curvature)
	local targetRotTime = 0

	if curvature ~= 0 then
		local spec = self.spec_wheels
		targetRotTime = math.huge

		if curvature > 0 then
			targetRotTime = -math.huge
		end

		for i, wheel in ipairs(spec.wheels) do
			if wheel.rotSpeed ~= 0 then
				local diffX, _, diffZ = localToLocal(wheel.node, spec.steeringCenterNode, wheel.positionX, wheel.positionY, wheel.positionZ)
				local targetRot = math.atan(diffZ * math.abs(curvature) / (1 - math.abs(curvature) * math.abs(diffX)))
				local wheelRotTime = targetRot / wheel.rotSpeed

				if curvature > 0 then
					wheelRotTime = -wheelRotTime
					targetRotTime = math.max(targetRotTime, wheelRotTime)
				else
					targetRotTime = math.min(targetRotTime, wheelRotTime)
				end
			end
		end

		targetRotTime = targetRotTime * -1
	end

	return targetRotTime
end

function Wheels:getTurningRadiusByRotTime(rotTime)
	local spec = self.spec_wheels
	local maxTurningRadius = math.huge

	if spec.steeringCenterNode ~= nil then
		for i, wheel in ipairs(spec.wheels) do
			if wheel.rotSpeed ~= 0 then
				local rotSpeed = math.abs(wheel.rotSpeed)
				local wheelRot = math.abs(rotTime * rotSpeed)
				local diffX, _, diffZ = localToLocal(wheel.node, spec.steeringCenterNode, wheel.positionX, wheel.positionY, wheel.positionZ)
				local turningRadius = math.abs(diffZ) / math.tan(wheelRot) + math.abs(diffX)

				if maxTurningRadius > turningRadius then
					maxTurningRadius = turningRadius
				end
			end
		end
	end

	return maxTurningRadius
end

function Wheels:onRegisterAnimationValueTypes()
	self:registerAnimationValueType("steeringAngle", "startSteeringAngle", "endSteeringAngle", false, AnimationValueFloat, function (value, xmlFile, xmlKey)
		value.wheelIndex = xmlFile:getValue(xmlKey .. "#wheelIndex")

		if value.wheelIndex ~= nil then
			value:setWarningInformation("wheelIndex: " .. value.wheelIndex)
			value:addCompareParameters("wheelIndex")

			return true
		end

		return false
	end, function (value)
		if value.wheelIndex ~= nil then
			if value.wheel == nil then
				value.wheel = self:getWheelFromWheelIndex(value.wheelIndex)

				if value.wheel == nil then
					Logging.xmlWarning(self.xmlFile, "Unknown wheel index '%s' for animation part.", value.wheelIndex)

					value.wheelIndex = nil

					return 0
				end
			end

			return value.wheel.steeringAngle
		end

		return 0
	end, function (value, steeringAngle)
		if value.wheel ~= nil then
			value.wheel.steeringAngle = steeringAngle
		end
	end)
	self:registerAnimationValueType("brakeFactor", "startBrakeFactor", "endBrakeFactor", false, AnimationValueFloat, function (value, xmlFile, xmlKey)
		value.wheelIndex = xmlFile:getValue(xmlKey .. "#wheelIndex")

		if value.wheelIndex ~= nil then
			value:setWarningInformation("wheelIndex: " .. value.wheelIndex)
			value:addCompareParameters("wheelIndex")

			return true
		end

		return false
	end, function (value)
		if value.wheel == nil then
			local wheel = value.vehicle:getWheelFromWheelIndex(value.wheelIndex)

			if wheel == nil then
				Logging.xmlWarning(self.xmlFile, "Unknown wheel index '%s' for animation part.", value.wheelIndex)

				value.startValue = nil

				return 0
			end

			value.wheel = wheel
		end

		return value.wheel.brakeFactor
	end, function (value, brakeFactor)
		if value.wheel ~= nil then
			value.wheel.brakeFactor = brakeFactor

			WheelsUtil.updateWheelPhysics(self, value.wheel, self.spec_wheels.brakePedal, 16.66)
		end
	end)
end

function Wheels:onPostAttachImplement(object, inputJointDescIndex, jointDescIndex)
	SpecializationUtil.raiseEvent(self, "onBrake", self.spec_wheels.brakePedal)
end

function Wheels.getTireNames(instance)
	local spec = instance.spec_wheels
	local tireNames = {}

	if spec ~= nil then
		for i = 1, #spec.wheels do
			local wheel = spec.wheels[i]

			if wheel.name ~= nil then
				tireNames[wheel.name] = true
			end
		end

		for i = 1, #spec.dynamicallyLoadedWheels do
			local wheel = spec.dynamicallyLoadedWheels[i]

			if wheel.name ~= nil then
				tireNames[wheel.name] = true
			end
		end
	end

	return table.toList(tireNames)
end

function Wheels.loadBrandName(xmlFile, key, baseDir, customEnvironment, isMod, configItem)
	local name = xmlFile:getValue(key .. "#brand")
	configItem.wheelBrandKey = key

	if name ~= nil then
		local brandDesc = g_brandManager:getBrandByName(name)

		if brandDesc ~= nil then
			configItem.wheelBrandName = brandDesc.title
			configItem.wheelBrandIconFilename = brandDesc.image

			table.insert(configItem.nameCompareParams, "wheelBrandName")
		else
			Logging.warning("Wheel brand '%s' is not defined for '%s'!", name, key)
		end
	end
end

function Wheels.loadedBrandNames(xmlFile, baseKey, baseDir, customEnvironment, isMod, configurationItems, storeItem)
	local hasWheelBrands = false

	for _, item in ipairs(configurationItems) do
		if item.wheelBrandName ~= nil then
			hasWheelBrands = true

			break
		end
	end

	if hasWheelBrands then
		for _, item in ipairs(configurationItems) do
			if item.wheelBrandName == nil then
				Logging.xmlWarning(xmlFile, "Wheel brand missing for wheel configuration '%s'!", item.wheelBrandKey)
			end
		end
	end
end

function Wheels.getBrands(items)
	local brands = {}
	local addedBrands = {}

	for _, item in ipairs(items) do
		if item.wheelBrandName ~= nil and addedBrands[item.wheelBrandName] == nil then
			table.insert(brands, {
				title = item.wheelBrandName,
				icon = item.wheelBrandIconFilename
			})

			addedBrands[item.wheelBrandName] = true
		end
	end

	return brands
end

function Wheels.getWheelsByBrand(items, brand)
	local wheels = {}

	for _, item in ipairs(items) do
		if item.wheelBrandName == brand.title then
			table.insert(wheels, item)
		end
	end

	return wheels
end

function Wheels.getWheelMassFromExternalFile(filename, wheelConfigId)
	local mass = 0
	local wheelXMLFile = XMLFile.load("specWeightWheelXml", filename, Wheels.xmlSchema)

	if wheelXMLFile ~= nil then
		local wheelMass = wheelXMLFile:getValue("wheel.default.physics#mass", 0.1)
		local additionalMass = wheelXMLFile:getValue("wheel.default.additional#mass", 0)

		if wheelConfigId ~= nil then
			wheelXMLFile:iterate("wheel.configurations.configuration", function (_, configKey)
				if wheelXMLFile:getValue(configKey .. "#id") == wheelConfigId then
					wheelMass = wheelXMLFile:getValue(configKey .. ".physics#mass", wheelMass)
					additionalMass = wheelXMLFile:getValue(configKey .. ".additional#mass", additionalMass)

					return false
				end
			end)
		end

		mass = wheelMass + additionalMass

		wheelXMLFile:delete()
	end

	return mass
end

function Wheels.loadSpecValueWheelWeight(xmlFile, customEnvironment)
	local configurationSaveIdToIndex, configurationIndexToBaseConfig = Wheels.createConfigSaveIdMapping(xmlFile)
	local defaultConfigIndex = 0

	xmlFile:iterate("vehicle.wheels.wheelConfigurations.wheelConfiguration", function (configIndex, wheelConfigKey)
		if xmlFile:getValue(wheelConfigKey .. "#isDefault") then
			defaultConfigIndex = configIndex

			return false
		end
	end)

	local defaultConfigKey = string.format("vehicle.wheels.wheelConfigurations.wheelConfiguration(%d)", defaultConfigIndex)
	local configMass = 0

	xmlFile:iterate(defaultConfigKey .. ".wheels.wheel", function (index, key)
		local mass = Wheels.getConfigurationValue(configurationSaveIdToIndex, configurationIndexToBaseConfig, xmlFile, defaultConfigIndex, defaultConfigKey, string.format(".wheels.wheel(%d).physics#mass", index - 1))

		if mass ~= nil then
			configMass = configMass + mass
		else
			local filename = Wheels.getConfigurationValue(configurationSaveIdToIndex, configurationIndexToBaseConfig, xmlFile, defaultConfigIndex, defaultConfigKey, string.format(".wheels.wheel(%d)#filename", index - 1))

			if filename ~= nil then
				local wheelConfigId = Wheels.getConfigurationValue(configurationSaveIdToIndex, configurationIndexToBaseConfig, xmlFile, defaultConfigIndex, defaultConfigKey, string.format(".wheels.wheel(%d)#configId", index - 1))
				filename = Utils.getFilename(filename, customEnvironment)
				configMass = configMass + Wheels.getWheelMassFromExternalFile(filename, wheelConfigId)
			else
				configMass = configMass + 0.1
			end

			xmlFile:iterate(defaultConfigKey .. string.format(".wheels.wheel(%d).additionalWheel", index - 1), function (additionalIndex, _)
				local additionalFilename = Wheels.getConfigurationValue(configurationSaveIdToIndex, configurationIndexToBaseConfig, xmlFile, defaultConfigIndex, defaultConfigKey, string.format(".wheels.wheel(%d).additionalWheel(%d)#filename", index - 1, additionalIndex - 1))

				if additionalFilename ~= nil then
					local wheelConfigId = Wheels.getConfigurationValue(configurationSaveIdToIndex, configurationIndexToBaseConfig, xmlFile, defaultConfigIndex, defaultConfigKey, string.format(".wheels.wheel(%d).additionalWheel(%d)#configId", index - 1, additionalIndex - 1))
					additionalFilename = Utils.getFilename(additionalFilename, customEnvironment)
					configMass = configMass + Wheels.getWheelMassFromExternalFile(additionalFilename, wheelConfigId)
				end
			end)
		end
	end)

	return configMass
end

function Wheels.loadSpecValueWheels(xmlFile, customEnvironment)
	return nil
end

function Wheels.getSpecValueWheels(storeItem, realItem)
	if realItem == nil then
		return nil
	end

	return table.concat(Wheels.getTireNames(realItem), " / ")
end
