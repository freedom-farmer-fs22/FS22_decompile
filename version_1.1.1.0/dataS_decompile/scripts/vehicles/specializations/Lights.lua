source("dataS/scripts/vehicles/specializations/events/VehicleSetBeaconLightEvent.lua")
source("dataS/scripts/vehicles/specializations/events/VehicleSetTurnLightEvent.lua")
source("dataS/scripts/vehicles/specializations/events/VehicleSetLightEvent.lua")

Lights = {
	TURNLIGHT_OFF = 0,
	TURNLIGHT_LEFT = 1,
	TURNLIGHT_RIGHT = 2,
	TURNLIGHT_HAZARD = 3,
	turnLightSendNumBits = 3,
	LIGHT_TYPE_DEFAULT = 0,
	LIGHT_TYPE_WORK_BACK = 1,
	LIGHT_TYPE_WORK_FRONT = 2,
	LIGHT_TYPE_HIGHBEAM = 3,
	sharedLightXMLSchema = nil,
	beaconLightXMLSchema = nil,
	ADDITIONAL_LIGHT_ATTRIBUTES_KEYS = {
		"vehicle.lights.sharedLight(?)",
		"vehicle.lights.realLights.low.light(?)",
		"vehicle.lights.realLights.low.brakeLight(?)",
		"vehicle.lights.realLights.low.reverseLight(?)",
		"vehicle.lights.realLights.low.turnLightLeft(?)",
		"vehicle.lights.realLights.low.turnLightRight(?)",
		"vehicle.lights.realLights.low.interiorLight(?)",
		"vehicle.lights.realLights.high.light(?)",
		"vehicle.lights.realLights.high.brakeLight(?)",
		"vehicle.lights.realLights.high.reverseLight(?)",
		"vehicle.lights.realLights.high.turnLightLeft(?)",
		"vehicle.lights.realLights.high.turnLightRight(?)",
		"vehicle.lights.realLights.high.interiorLight(?)",
		"vehicle.lights.defaultLights.defaultLight(?)",
		"vehicle.lights.brakeLights.brakeLight(?)",
		"vehicle.lights.reverseLights.reverseLight(?)",
		"vehicle.lights.turnLights.turnLightLeft(?)",
		"vehicle.lights.turnLights.turnLightRight(?)"
	},
	prerequisitesPresent = function (specializations)
		return true
	end
}

function Lights.initSpecialization()
	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Lights")
	schema:register(XMLValueType.FLOAT, "vehicle.lights#reverseLightActivationSpeed", "Speed which needs to be reached to activate reverse lights (km/h)", 1)
	schema:register(XMLValueType.VECTOR_N, "vehicle.lights.states.state(?)#lightTypes", "Light states")
	schema:register(XMLValueType.VECTOR_N, "vehicle.lights.states.aiState#lightTypes", "Light states while ai is active", "0")
	schema:register(XMLValueType.VECTOR_N, "vehicle.lights.states.aiState#lightTypesWork", "Light states while ai is working", "0 1 2")
	schema:register(XMLValueType.STRING, "vehicle.lights.sharedLight(?)#filename", "Shared light filename")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.lights.sharedLight(?)#linkNode", "Link node", "0>")
	schema:register(XMLValueType.VECTOR_N, "vehicle.lights.sharedLight(?)#lightTypes", "Light types")
	schema:register(XMLValueType.VECTOR_N, "vehicle.lights.sharedLight(?)#excludedLightTypes", "Excluded light types")
	schema:register(XMLValueType.STRING, "vehicle.lights.sharedLight(?).rotationNode(?)#name", "Rotation node name")
	schema:register(XMLValueType.VECTOR_ROT, "vehicle.lights.sharedLight(?).rotationNode(?)#rotation", "Rotation")
	Lights.registerRealLightSetupXMLPath(schema, "vehicle.lights.realLights.low")
	Lights.registerRealLightSetupXMLPath(schema, "vehicle.lights.realLights.high")
	Lights.registerStaticLightXMLPath(schema, "vehicle.lights.defaultLights.defaultLight(?)")
	Lights.registerStaticLightXMLPath(schema, "vehicle.lights.brakeLights.brakeLight(?)")
	Lights.registerStaticLightXMLPath(schema, "vehicle.lights.reverseLights.reverseLight(?)")
	Lights.registerStaticLightXMLPath(schema, "vehicle.lights.turnLights.turnLightLeft(?)")
	Lights.registerStaticLightXMLPath(schema, "vehicle.lights.turnLights.turnLightRight(?)")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.lights.beaconLights.beaconLight(?)#node", "Link node")
	schema:register(XMLValueType.STRING, "vehicle.lights.beaconLights.beaconLight(?)#filename", "Beacon light xml file")
	schema:register(XMLValueType.FLOAT, "vehicle.lights.beaconLights.beaconLight(?)#speed", "Beacon light speed override")
	schema:register(XMLValueType.FLOAT, "vehicle.lights.beaconLights.beaconLight(?)#realLightRange", "Factor that is applied on real light range of the beacon light", 1)
	schema:register(XMLValueType.INT, "vehicle.lights.beaconLights.beaconLight(?)#intensity", "Beacon light intensity override")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.lights.beaconLights.beaconLight(?).realLight#node", "Real light node")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.lights.beaconLights.beaconLight(?).rotator#node", "Rotator node")
	schema:register(XMLValueType.BOOL, "vehicle.lights.beaconLights.beaconLight(?)#multiBlink", "Is multiblink light")
	BeaconLightManager.registerXMLPaths(schema, "vehicle.lights.beaconLights.beaconLight(?).device")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.lights.sounds", "toggleLights")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.lights.sounds", "turnLight")
	Dashboard.registerDashboardXMLPaths(schema, "vehicle.lights.dashboards", "lightState | turnLightLeft | turnLightRight | turnLight | turnLightHazard | turnLightAny | beaconLight")
	schema:register(XMLValueType.VECTOR_N, "vehicle.lights.dashboards.dashboard(?)#lightTypes", "Light types")
	schema:register(XMLValueType.VECTOR_N, "vehicle.lights.dashboards.dashboard(?)#excludedLightTypes", "Excluded light types")
	schema:setXMLSpecializationType()

	local sharedLightXMLSchema = XMLSchema.new("sharedLight")

	sharedLightXMLSchema:register(XMLValueType.STRING, "light.filename", "Path to i3d file", nil, true)
	sharedLightXMLSchema:register(XMLValueType.NODE_INDEX, "light.rootNode#node", "Node index", "0")
	Lights.registerSharedLightXMLPath(sharedLightXMLSchema, "light.defaultLight(?)")
	Lights.registerSharedLightXMLPath(sharedLightXMLSchema, "light.brakeLight(?)")
	Lights.registerSharedLightXMLPath(sharedLightXMLSchema, "light.reverseLight(?)")
	Lights.registerSharedLightXMLPath(sharedLightXMLSchema, "light.turnLightLeft(?)")
	Lights.registerSharedLightXMLPath(sharedLightXMLSchema, "light.turnLightRight(?)")
	sharedLightXMLSchema:register(XMLValueType.STRING, "light.rotationNode(?)#name", "Name for reference in vehicle xml")
	sharedLightXMLSchema:register(XMLValueType.NODE_INDEX, "light.rotationNode(?)#node", "Node")

	Lights.sharedLightXMLSchema = sharedLightXMLSchema
	local beaconLightXMLSchema = XMLSchema.new("beaconLight")

	beaconLightXMLSchema:register(XMLValueType.STRING, "beaconLight.filename", "Path to i3d file", nil, true)
	beaconLightXMLSchema:register(XMLValueType.NODE_INDEX, "beaconLight.rootNode#node", "Root node")
	beaconLightXMLSchema:register(XMLValueType.NODE_INDEX, "beaconLight.rotator#node", "Node that is rotating")
	beaconLightXMLSchema:register(XMLValueType.FLOAT, "beaconLight.rotator#speed", "Rotating speed", 0.015)
	beaconLightXMLSchema:register(XMLValueType.NODE_INDEX, "beaconLight.light#node", "Visibility toggle node")
	beaconLightXMLSchema:register(XMLValueType.NODE_INDEX, "beaconLight.light#shaderNode", "Light control shader node")
	beaconLightXMLSchema:register(XMLValueType.FLOAT, "beaconLight.light#intensity", "Light intensity of shader node", 1000)
	beaconLightXMLSchema:register(XMLValueType.BOOL, "beaconLight.light#multiBlink", "Uses multiblink functionality", false)
	beaconLightXMLSchema:register(XMLValueType.NODE_INDEX, "beaconLight.realLight#node", "Real light source node")
	BeaconLightManager.registerXMLPaths(beaconLightXMLSchema, "beaconLight.device")

	Lights.beaconLightXMLSchema = beaconLightXMLSchema
end

function Lights.registerSharedLightXMLPath(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Visual light node")
	schema:register(XMLValueType.FLOAT, basePath .. "#intensity", "Intensity", 25)
	schema:register(XMLValueType.BOOL, basePath .. "#toggleVisibility", "Toggle visibility", false)
	schema:register(XMLValueType.VECTOR_N, basePath .. "#excludedLightTypes", "Excluded light types")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#lightTypes", "Light types")
end

function Lights.registerStaticLightXMLPath(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Visual light node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#shaderNode", "Shader node")
	schema:register(XMLValueType.FLOAT, basePath .. "#intensity", "Intensity", 25)
	schema:register(XMLValueType.BOOL, basePath .. "#toggleVisibility", "Toggle visibility", false)
	schema:register(XMLValueType.VECTOR_N, basePath .. "#excludedLightTypes", "Excluded light types")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#lightTypes", "Light types")
end

function Lights.registerRealLightSetupXMLPath(schema, basePath)
	Lights.registerRealLightXMLPath(schema, basePath .. ".light(?)")
	Lights.registerRealLightXMLPath(schema, basePath .. ".brakeLight(?)")
	Lights.registerRealLightXMLPath(schema, basePath .. ".reverseLight(?)")
	Lights.registerRealLightXMLPath(schema, basePath .. ".turnLightLeft(?)")
	Lights.registerRealLightXMLPath(schema, basePath .. ".turnLightRight(?)")
	Lights.registerRealLightXMLPath(schema, basePath .. ".interiorLight(?)")
end

function Lights.registerRealLightXMLPath(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. "#node", "Light node")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#lightTypes", "Light types")
	schema:register(XMLValueType.VECTOR_N, basePath .. "#excludedLightTypes", "Excluded light types")
end

function Lights.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onTurnLightStateChanged")
	SpecializationUtil.registerEvent(vehicleType, "onBrakeLightsVisibilityChanged")
	SpecializationUtil.registerEvent(vehicleType, "onReverseLightsVisibilityChanged")
	SpecializationUtil.registerEvent(vehicleType, "onLightsTypesMaskChanged")
	SpecializationUtil.registerEvent(vehicleType, "onBeaconLightsVisibilityChanged")
	SpecializationUtil.registerEvent(vehicleType, "onDeactivateLights")
end

function Lights.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadRealLightSetup", Lights.loadRealLightSetup)
	SpecializationUtil.registerFunction(vehicleType, "loadRealLights", Lights.loadRealLights)
	SpecializationUtil.registerFunction(vehicleType, "loadStaticLightNodes", Lights.loadStaticLightNodes)
	SpecializationUtil.registerFunction(vehicleType, "applyAdditionalActiveLightType", Lights.applyAdditionalActiveLightType)
	SpecializationUtil.registerFunction(vehicleType, "loadBeaconLightFromXML", Lights.loadBeaconLightFromXML)
	SpecializationUtil.registerFunction(vehicleType, "onBeaconLightI3DLoaded", Lights.onBeaconLightI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForLights", Lights.getIsActiveForLights)
	SpecializationUtil.registerFunction(vehicleType, "getIsActiveForInteriorLights", Lights.getIsActiveForInteriorLights)
	SpecializationUtil.registerFunction(vehicleType, "getCanToggleLight", Lights.getCanToggleLight)
	SpecializationUtil.registerFunction(vehicleType, "getUseHighProfile", Lights.getUseHighProfile)
	SpecializationUtil.registerFunction(vehicleType, "setNextLightsState", Lights.setNextLightsState)
	SpecializationUtil.registerFunction(vehicleType, "setLightsTypesMask", Lights.setLightsTypesMask)
	SpecializationUtil.registerFunction(vehicleType, "getLightsTypesMask", Lights.getLightsTypesMask)
	SpecializationUtil.registerFunction(vehicleType, "setTurnLightState", Lights.setTurnLightState)
	SpecializationUtil.registerFunction(vehicleType, "getTurnLightState", Lights.getTurnLightState)
	SpecializationUtil.registerFunction(vehicleType, "setBrakeLightsVisibility", Lights.setBrakeLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "setBeaconLightsVisibility", Lights.setBeaconLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "getBeaconLightsVisibility", Lights.getBeaconLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "setReverseLightsVisibility", Lights.setReverseLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "setInteriorLightsVisibility", Lights.setInteriorLightsVisibility)
	SpecializationUtil.registerFunction(vehicleType, "getInteriorLightBrightness", Lights.getInteriorLightBrightness)
	SpecializationUtil.registerFunction(vehicleType, "setLightsState", Lights.setLightsState)
	SpecializationUtil.registerFunction(vehicleType, "setLightState", Lights.setLightState)
	SpecializationUtil.registerFunction(vehicleType, "setRealLightState", Lights.setRealLightState)
	SpecializationUtil.registerFunction(vehicleType, "setStaticLightState", Lights.setStaticLightState)
	SpecializationUtil.registerFunction(vehicleType, "deactivateLights", Lights.deactivateLights)
	SpecializationUtil.registerFunction(vehicleType, "getDeactivateLightsOnLeave", Lights.getDeactivateLightsOnLeave)
	SpecializationUtil.registerFunction(vehicleType, "loadSharedLight", Lights.loadSharedLight)
	SpecializationUtil.registerFunction(vehicleType, "loadStaticLightNodesFromSharedLight", Lights.loadStaticLightNodesFromSharedLight)
	SpecializationUtil.registerFunction(vehicleType, "loadSharedLightI3DLoaded", Lights.loadSharedLightI3DLoaded)
	SpecializationUtil.registerFunction(vehicleType, "loadAdditionalLightAttributesFromXML", Lights.loadAdditionalLightAttributesFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getIsLightActive", Lights.getIsLightActive)
	SpecializationUtil.registerFunction(vehicleType, "updateAILights", Lights.updateAILights)
	SpecializationUtil.registerFunction(vehicleType, "lightsWeatherChanged", Lights.lightsWeatherChanged)
	SpecializationUtil.registerFunction(vehicleType, "deactivateBeaconLights", Lights.deactivateBeaconLights)
end

function Lights.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onLoadFinished", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onStartMotor", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onStopMotor", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onStartReverseDirectionChange", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAutomatedTrainTravelActive", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIDriveableActive", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIDriveableEnd", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerActive", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerBlock", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerContinue", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onAIFieldWorkerEnd", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onVehiclePhysicsUpdate", Lights)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Lights)
end

function Lights:onLoad(savegame)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.low.light#decoration", "vehicle.lights.defaultLights#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.high.light#decoration", "vehicle.lights.defaultLights#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.low.light#realLight", "vehicle.lights.realLights.low.light#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.lights.high.light#realLight", "vehicle.lights.realLights.high.light#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.brakeLights.brakeLight#realLight", "vehicle.lights.realLights.high.brakeLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.brakeLights.brakeLight#decoration", "vehicle.lights.brakeLights.brakeLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#realLight", "vehicle.lights.realLights.high.reverseLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#decoration", "vehicle.lights.reverseLights.reverseLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightLeft#realLight", "vehicle.lights.realLights.high.turnLightLeft#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightLeft#decoration", "vehicle.lights.turnLights.turnLightLeft#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightRight#realLight", "vehicle.lights.realLights.high.turnLightRight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnLights.turnLightRight#decoration", "vehicle.lights.turnLights.turnLightRight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#realLight", "vehicle.lights.realLights.high.reverseLight#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.reverseLights.reverseLight#decoration", "vehicle.lights.reverseLights.reverseLight#node")

	local spec = self.spec_lights
	spec.reverseLightActivationSpeed = self.xmlFile:getValue("vehicle.lights#reverseLightActivationSpeed", 1) / 3600
	spec.sharedLoadRequestIds = {}
	spec.xmlLoadingHandles = {}
	spec.shaderDefaultLights = {}
	spec.shaderBrakeLights = {}
	spec.shaderLeftTurnLights = {}
	spec.shaderRightTurnLights = {}
	spec.shaderReverseLights = {}
	spec.realLights = {
		low = {},
		high = {}
	}
	spec.defaultLights = {}
	spec.brakeLights = {}
	spec.reverseLights = {}
	spec.turnLightsLeft = {}
	spec.turnLightsRight = {}
	spec.lightsTypesMask = 0
	spec.currentLightState = 0
	spec.numLightTypes = 0
	spec.lightStates = {}
	local registeredLightTypes = {}
	local i = 0

	while true do
		local key = string.format("vehicle.lights.states.state(%d)", i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local lightTypes = self.xmlFile:getValue(key .. "#lightTypes", nil, true)

		for _, lightType in pairs(lightTypes) do
			if registeredLightTypes[lightType] == nil then
				registeredLightTypes[lightType] = lightType
				spec.numLightTypes = spec.numLightTypes + 1
			end
		end

		table.insert(spec.lightStates, lightTypes)

		i = i + 1
	end

	local function loadLightsMaskFromXML(xmlFile, key, default)
		local lightTypes = xmlFile:getValue(key, default, true)
		local lightsTypesMask = 0

		for _, lightType in pairs(lightTypes) do
			lightsTypesMask = bitOR(lightsTypesMask, 2^lightType)
		end

		return lightsTypesMask
	end

	spec.aiLightsTypesMask = loadLightsMaskFromXML(self.xmlFile, "vehicle.lights.states.aiState#lightTypes", "0")
	spec.aiLightsTypesMaskWork = loadLightsMaskFromXML(self.xmlFile, "vehicle.lights.states.aiState#lightTypesWork", "0 1 2")
	spec.interiorLightsBrightness = 0
	spec.interiorLightsAvailable = false

	self:loadRealLightSetup(self.xmlFile, "vehicle.lights.realLights.low", spec.realLights.low)
	self:loadRealLightSetup(self.xmlFile, "vehicle.lights.realLights.high", spec.realLights.high)

	spec.staticLights = {}
	spec.defaultLightsStatic = {}
	spec.brakeLightsStatic = {}
	spec.reverseLightsStatic = {}
	spec.turnLightsLeftStatic = {}
	spec.turnLightsRightStatic = {}

	self:loadStaticLightNodes(self.xmlFile, "vehicle.lights.defaultLights.defaultLight", spec.staticLights, spec.defaultLightsStatic)
	self:loadStaticLightNodes(self.xmlFile, "vehicle.lights.brakeLights.brakeLight", spec.staticLights, spec.brakeLightsStatic)
	self:loadStaticLightNodes(self.xmlFile, "vehicle.lights.reverseLights.reverseLight", spec.staticLights, spec.reverseLightsStatic)
	self:loadStaticLightNodes(self.xmlFile, "vehicle.lights.turnLights.turnLightLeft", spec.staticLights, spec.turnLightsLeftStatic)
	self:loadStaticLightNodes(self.xmlFile, "vehicle.lights.turnLights.turnLightRight", spec.staticLights, spec.turnLightsRightStatic)

	spec.sharedLights = {}

	self.xmlFile:iterate("vehicle.lights.sharedLight", function (_, key)
		self:loadSharedLight(self.xmlFile, key, spec.sharedLights)
	end)

	spec.maxLightState = Lights.LIGHT_TYPE_HIGHBEAM

	for j = 1, #spec.staticLights do
		for _, lightType in pairs(spec.staticLights[j].lightTypes) do
			spec.maxLightState = math.max(spec.maxLightState, lightType)
		end
	end

	for j = 1, #spec.realLights.low.realLights do
		for _, lightType in pairs(spec.realLights.low.realLights[j].lightTypes) do
			spec.maxLightState = math.max(spec.maxLightState, lightType)
		end
	end

	for j = 1, #spec.realLights.high.realLights do
		for _, lightType in pairs(spec.realLights.high.realLights[j].lightTypes) do
			spec.maxLightState = math.max(spec.maxLightState, lightType)
		end
	end

	spec.maxLightStateMask = 2^(spec.maxLightState + 1) - 1
	spec.additionalLightTypes = {
		brakeLight = spec.maxLightState + 1,
		turnLightLeft = spec.maxLightState + 2,
		turnLightRight = spec.maxLightState + 3,
		turnLightAny = spec.maxLightState + 4,
		reverseLight = spec.maxLightState + 5,
		interiorLight = spec.maxLightState + 6
	}
	spec.totalNumLightTypes = spec.additionalLightTypes.interiorLight

	if spec.totalNumLightTypes > 31 then
		Logging.xmlError(self.xmlFile, "Max. number of light types reached (31). Please reduce them.")

		spec.totalNumLightTypes = 31
	end

	spec.brakeLightsVisibility = false
	spec.reverseLightsVisibility = false
	spec.turnLightState = Lights.TURNLIGHT_OFF
	spec.turnLightTriState = 0.5
	spec.hasTurnLights = #spec.turnLightsLeft > 0 or #spec.turnLightsRight > 0
	spec.turnLightRepetitionCount = 0
	spec.actionEventsActiveChange = {}
	spec.beaconLightsActive = false
	spec.hasRealBeaconLights = g_gameSettings:getValue("realBeaconLights")
	spec.beaconLights = {}

	self.xmlFile:iterate("vehicle.lights.beaconLights.beaconLight", function (_, key)
		self:loadBeaconLightFromXML(self.xmlFile, key)
	end)

	if self.isClient ~= nil then
		spec.samples = {
			toggleLights = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.lights.sounds", "toggleLights", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			turnLight = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.lights.sounds", "turnLight", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end

	if self.loadDashboardsFromXML ~= nil then
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.lights.dashboards", {
			valueFunc = "lightsTypesMask",
			valueTypeToLoad = "lightState",
			valueObject = spec,
			additionalAttributesFunc = Lights.dashboardLightAttributes,
			stateFunc = Lights.dashboardLightState
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.lights.dashboards", {
			valueFunc = "turnLightState",
			valueTypeToLoad = "turnLightLeft",
			valueObject = spec,
			valueCompare = {
				Lights.TURNLIGHT_LEFT,
				Lights.TURNLIGHT_HAZARD
			}
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.lights.dashboards", {
			valueFunc = "turnLightState",
			valueTypeToLoad = "turnLightRight",
			valueObject = spec,
			valueCompare = {
				Lights.TURNLIGHT_RIGHT,
				Lights.TURNLIGHT_HAZARD
			}
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.lights.dashboards", {
			valueFunc = "turnLightTriState",
			idleValue = 0.5,
			valueTypeToLoad = "turnLight",
			valueObject = spec
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.lights.dashboards", {
			valueFunc = "turnLightState",
			valueTypeToLoad = "turnLightHazard",
			valueObject = spec,
			valueCompare = {
				Lights.TURNLIGHT_HAZARD
			}
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.lights.dashboards", {
			valueFunc = "turnLightState",
			valueTypeToLoad = "turnLightAny",
			valueObject = spec,
			valueCompare = {
				Lights.TURNLIGHT_LEFT,
				Lights.TURNLIGHT_RIGHT,
				Lights.TURNLIGHT_HAZARD
			}
		})
		self:loadDashboardsFromXML(self.xmlFile, "vehicle.lights.dashboards", {
			valueFunc = "beaconLightsActive",
			valueTypeToLoad = "beaconLight",
			valueObject = spec
		})
	end

	if g_currentMission ~= nil and g_currentMission.environment ~= nil then
		g_messageCenter:subscribe(MessageType.WEATHER_CHANGED, self.lightsWeatherChanged, self)
	end
end

function Lights:onLoadFinished(savegame)
	local spec = self.spec_lights

	self:applyAdditionalActiveLightType(spec.brakeLightsStatic, spec.additionalLightTypes.brakeLight)
	self:applyAdditionalActiveLightType(spec.reverseLightsStatic, spec.additionalLightTypes.reverseLight)
	self:applyAdditionalActiveLightType(spec.turnLightsLeftStatic, spec.additionalLightTypes.turnLightLeft)
	self:applyAdditionalActiveLightType(spec.turnLightsLeftStatic, spec.additionalLightTypes.turnLightAny)
	self:applyAdditionalActiveLightType(spec.turnLightsRightStatic, spec.additionalLightTypes.turnLightRight)
	self:applyAdditionalActiveLightType(spec.turnLightsRightStatic, spec.additionalLightTypes.turnLightAny)
	self:applyAdditionalActiveLightType(spec.realLights.low.brakeLights, spec.additionalLightTypes.brakeLight)
	self:applyAdditionalActiveLightType(spec.realLights.low.reverseLights, spec.additionalLightTypes.reverseLight)
	self:applyAdditionalActiveLightType(spec.realLights.low.turnLightsLeft, spec.additionalLightTypes.turnLightLeft)
	self:applyAdditionalActiveLightType(spec.realLights.low.turnLightsLeft, spec.additionalLightTypes.turnLightAny)
	self:applyAdditionalActiveLightType(spec.realLights.low.turnLightsRight, spec.additionalLightTypes.turnLightRight)
	self:applyAdditionalActiveLightType(spec.realLights.low.turnLightsRight, spec.additionalLightTypes.turnLightAny)
	self:applyAdditionalActiveLightType(spec.realLights.low.interiorLights, spec.additionalLightTypes.interiorLight)
	self:applyAdditionalActiveLightType(spec.realLights.high.brakeLights, spec.additionalLightTypes.brakeLight)
	self:applyAdditionalActiveLightType(spec.realLights.high.reverseLights, spec.additionalLightTypes.reverseLight)
	self:applyAdditionalActiveLightType(spec.realLights.high.turnLightsLeft, spec.additionalLightTypes.turnLightLeft)
	self:applyAdditionalActiveLightType(spec.realLights.high.turnLightsLeft, spec.additionalLightTypes.turnLightAny)
	self:applyAdditionalActiveLightType(spec.realLights.high.turnLightsRight, spec.additionalLightTypes.turnLightRight)
	self:applyAdditionalActiveLightType(spec.realLights.high.turnLightsRight, spec.additionalLightTypes.turnLightAny)
	self:applyAdditionalActiveLightType(spec.realLights.high.interiorLights, spec.additionalLightTypes.interiorLight)
end

function Lights:onDelete()
	local spec = self.spec_lights

	if spec.xmlLoadingHandles ~= nil then
		for lightXMLFile, _ in pairs(spec.xmlLoadingHandles) do
			lightXMLFile:delete()

			spec.xmlLoadingHandles[lightXMLFile] = nil
		end
	end

	if spec.sharedLoadRequestIds ~= nil then
		for _, sharedLoadRequestId in ipairs(spec.sharedLoadRequestIds) do
			g_i3DManager:releaseSharedI3DFile(sharedLoadRequestId)
		end
	end

	g_soundManager:deleteSamples(spec.samples)
end

function Lights:onReadStream(streamId, connection)
	local spec = self.spec_lights
	local lightsTypesMask = streamReadUIntN(streamId, spec.totalNumLightTypes)

	self:setLightsTypesMask(lightsTypesMask, true, true)

	local beaconLightsActive = streamReadBool(streamId)

	self:setBeaconLightsVisibility(beaconLightsActive, true, true)
end

function Lights:onWriteStream(streamId, connection)
	local spec = self.spec_lights

	streamWriteUIntN(streamId, spec.lightsTypesMask, spec.totalNumLightTypes)
	streamWriteBool(streamId, spec.beaconLightsActive)
end

function Lights:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_lights

		if spec.beaconLightsActive then
			for _, beaconLight in pairs(spec.beaconLights) do
				if beaconLight.rotatorNode ~= nil then
					rotate(beaconLight.rotatorNode, 0, beaconLight.speed * dt, 0)
				end

				if beaconLight.realLightNode ~= nil and spec.hasRealBeaconLights and beaconLight.multiBlink then
					local x, y, z, _ = getShaderParameter(spec.beaconLights[1].lightShaderNode, "blinkOffset")
					local cTime_s = getShaderTimeSec()
					local alpha = MathUtil.clamp(math.sin(cTime_s * z) - math.max(cTime_s * z % ((x * 2 + y * 2) * math.pi) - (x * 2 - 1) * math.pi, 0) + 0.2, 0, 1)
					local r = beaconLight.defaultColor[1]
					local g = beaconLight.defaultColor[2]
					local b = beaconLight.defaultColor[3]

					setLightColor(beaconLight.realLightNode, r * alpha, g * alpha, b * alpha)

					for i = 0, getNumOfChildren(beaconLight.realLightNode) - 1 do
						setLightColor(getChildAt(beaconLight.realLightNode, i), r * alpha, g * alpha, b * alpha)
					end
				end
			end

			self:raiseActive()
		end

		if spec.turnLightState ~= Lights.TURNLIGHT_OFF then
			local shaderTime = 7 * getShaderTimeSec()
			local alpha = MathUtil.clamp(math.cos(shaderTime) + 0.2, 0, 1)

			if spec.turnLightState == Lights.TURNLIGHT_LEFT or spec.turnLightState == Lights.TURNLIGHT_HAZARD then
				for _, light in pairs(spec.activeTurnLightSetup.turnLightsLeft) do
					setLightColor(light.node, light.defaultColor[1] * alpha, light.defaultColor[2] * alpha, light.defaultColor[3] * alpha)

					for i = 0, getNumOfChildren(light.node) - 1 do
						setLightColor(getChildAt(light.node, i), light.defaultColor[1] * alpha, light.defaultColor[2] * alpha, light.defaultColor[3] * alpha)
					end
				end
			end

			if spec.turnLightState == Lights.TURNLIGHT_RIGHT or spec.turnLightState == Lights.TURNLIGHT_HAZARD then
				for _, light in pairs(spec.activeTurnLightSetup.turnLightsRight) do
					setLightColor(light.node, light.defaultColor[1] * alpha, light.defaultColor[2] * alpha, light.defaultColor[3] * alpha)

					for i = 0, getNumOfChildren(light.node) - 1 do
						setLightColor(getChildAt(light.node, i), light.defaultColor[1] * alpha, light.defaultColor[2] * alpha, light.defaultColor[3] * alpha)
					end
				end
			end

			if spec.samples.turnLight ~= nil and isActiveForInputIgnoreSelection then
				local turnLightRepetitionCount = math.floor((shaderTime + math.acos(-0.2)) / (math.pi * 2))

				if spec.turnLightRepetitionCount ~= nil and turnLightRepetitionCount ~= spec.turnLightRepetitionCount then
					g_soundManager:playSample(spec.samples.turnLight)
				end

				spec.turnLightRepetitionCount = turnLightRepetitionCount
			end

			self:raiseActive()
		end
	end
end

function Lights:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_lights
		local isActiveForLights = self:getIsActiveForLights()

		if spec.interiorLightsAvailable then
			self:setInteriorLightsVisibility(self:getIsActiveForInteriorLights())
		end

		for _, v in ipairs(spec.actionEventsActiveChange) do
			g_inputBinding:setActionEventActive(v, isActiveForLights)
		end

		g_inputBinding:setActionEventActive(spec.actionEventIdLight, isActiveForLights)

		if Platform.gameplay.automaticLights then
			if isActiveForLights then
				if not self:getIsAIActive() then
					self:updateAILights(self.rootVehicle:getActionControllerDirection() == -1)
				end
			elseif spec.lightsTypesMask ~= 0 then
				self:setLightsTypesMask(0)
			end
		end
	end
end

function Lights:getIsActiveForLights(onlyPowered)
	if onlyPowered == true and not self:getIsPowered() then
		return false
	end

	if self.getIsEntered ~= nil and self:getIsEntered() and self:getCanToggleLight() then
		return true
	end

	if self.attacherVehicle ~= nil then
		return self.attacherVehicle:getIsActiveForLights()
	end

	return false
end

function Lights:getIsActiveForInteriorLights()
	return false
end

function Lights:getCanToggleLight()
	local spec = self.spec_lights

	if self:getIsAIActive() then
		return false
	end

	if spec.numLightTypes == 0 then
		return false
	end

	if g_currentMission.controlledVehicle == self then
		return true
	else
		return false
	end
end

function Lights:getUseHighProfile()
	local lightsProfile = g_gameSettings:getValue("lightsProfile")
	lightsProfile = Utils.getNoNil(Platform.gameplay.lightsProfile, lightsProfile)

	return lightsProfile == GS_PROFILE_VERY_HIGH or lightsProfile == GS_PROFILE_HIGH
end

function Lights:setNextLightsState(increment)
	local spec = self.spec_lights

	if spec.lightStates ~= nil and #spec.lightStates > 0 then
		local oldLightsTypesMask = bitAND(spec.lightsTypesMask, spec.maxLightStateMask)
		local currentLightState = spec.currentLightState + increment

		if currentLightState > #spec.lightStates or spec.currentLightState == 0 and oldLightsTypesMask > 0 then
			currentLightState = 0
		elseif currentLightState < 0 then
			currentLightState = #spec.lightStates
		end

		local lightsTypesMask = 0

		if currentLightState > 0 then
			for _, lightType in pairs(spec.lightStates[currentLightState]) do
				lightsTypesMask = bitOR(lightsTypesMask, 2^lightType)
			end
		end

		spec.currentLightState = currentLightState

		self:setLightsTypesMask(lightsTypesMask)
	end
end

function Lights:setLightsTypesMask(lightsTypesMask, force, noEventSend)
	local spec = self.spec_lights

	if self.isServer then
		lightsTypesMask = bitAND(lightsTypesMask, spec.maxLightStateMask)

		if spec.turnLightState == Lights.TURNLIGHT_LEFT then
			lightsTypesMask = bitOR(lightsTypesMask, 2^spec.additionalLightTypes.turnLightLeft)
		end

		if spec.turnLightState == Lights.TURNLIGHT_RIGHT then
			lightsTypesMask = bitOR(lightsTypesMask, 2^spec.additionalLightTypes.turnLightRight)
		end

		if spec.turnLightState == Lights.TURNLIGHT_HAZARD then
			lightsTypesMask = bitOR(lightsTypesMask, 2^spec.additionalLightTypes.turnLightAny)
		end

		if spec.brakeLightsVisibility then
			lightsTypesMask = bitOR(lightsTypesMask, 2^spec.additionalLightTypes.brakeLight)
		end

		if spec.reverseLightsVisibility then
			lightsTypesMask = bitOR(lightsTypesMask, 2^spec.additionalLightTypes.reverseLight)
		end

		if spec.interiorLightsVisibility then
			lightsTypesMask = bitOR(lightsTypesMask, 2^spec.additionalLightTypes.interiorLight)
		end
	else
		lightsTypesMask = bitXOR(lightsTypesMask, 2^spec.additionalLightTypes.interiorLight)

		if spec.interiorLightsVisibility then
			lightsTypesMask = bitOR(lightsTypesMask, 2^spec.additionalLightTypes.interiorLight)
		end
	end

	if lightsTypesMask ~= spec.lightsTypesMask or force then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(VehicleSetLightEvent.new(self, lightsTypesMask, spec.totalNumLightTypes), nil, , self)
			else
				g_client:getServerConnection():sendEvent(VehicleSetLightEvent.new(self, lightsTypesMask, spec.totalNumLightTypes))
			end
		end

		if bitAND(lightsTypesMask, spec.maxLightStateMask) ~= bitAND(spec.lightsTypesMask, spec.maxLightStateMask) and self.isClient then
			g_soundManager:playSample(spec.samples.toggleLights)
		end

		local activeLightSetup = spec.realLights.low
		local inactiveLightSetup = spec.realLights.high

		if self:getUseHighProfile() then
			activeLightSetup = spec.realLights.high
			inactiveLightSetup = spec.realLights.low
		end

		self:setLightsState(inactiveLightSetup.realLights, false)
		self:setLightsState(activeLightSetup.realLights, lightsTypesMask)
		self:setLightsState(spec.staticLights, lightsTypesMask)

		spec.lightsTypesMask = lightsTypesMask

		SpecializationUtil.raiseEvent(self, "onLightsTypesMaskChanged", lightsTypesMask)
	end

	return true
end

function Lights:getLightsTypesMask()
	return self.spec_lights.lightsTypesMask
end

function Lights:setBeaconLightsVisibility(visibility, force, noEventSend)
	local spec = self.spec_lights

	if visibility ~= spec.beaconLightsActive or force then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(VehicleSetBeaconLightEvent.new(self, visibility), nil, , self)
			else
				g_client:getServerConnection():sendEvent(VehicleSetBeaconLightEvent.new(self, visibility))
			end
		end

		local isActiveForInput = self:getIsActiveForInput(true)
		spec.beaconLightsActive = visibility

		for _, beaconLight in pairs(spec.beaconLights) do
			if spec.hasRealBeaconLights and beaconLight.realLightNode ~= nil then
				setVisibility(beaconLight.realLightNode, visibility)
			end

			if beaconLight.lightNode ~= nil then
				setVisibility(beaconLight.lightNode, visibility)
			end

			if beaconLight.lightShaderNode ~= nil then
				local value = 1 * beaconLight.intensity

				if not visibility then
					value = 0
				end

				local _, y, z, w = getShaderParameter(beaconLight.lightShaderNode, "lightControl")

				setShaderParameter(beaconLight.lightShaderNode, "lightControl", value, y, z, w, false)
			end

			if isActiveForInput then
				local device = beaconLight.device

				if device ~= nil then
					if visibility then
						device.deviceId = g_beaconLightManager:activateBeaconLight(device.mode, device.numLEDScale, device.rpm, device.brightnessScale)
					elseif device.deviceId ~= nil then
						g_beaconLightManager:deactivateBeaconLight(device.deviceId)

						device.deviceId = nil
					end
				end
			end
		end

		SpecializationUtil.raiseEvent(self, "onBeaconLightsVisibilityChanged", visibility)
	end

	return true
end

function Lights:getBeaconLightsVisibility()
	return self.spec_lights.beaconLightsActive
end

function Lights:setTurnLightState(state, force, noEventSend)
	local spec = self.spec_lights

	if state ~= spec.turnLightState or force then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(VehicleSetTurnLightEvent.new(self, state), nil, , self)
			else
				g_client:getServerConnection():sendEvent(VehicleSetTurnLightEvent.new(self, state))
			end
		end

		local activeLightSetup = spec.realLights.low

		if self:getUseHighProfile() then
			activeLightSetup = spec.realLights.high
		end

		spec.activeTurnLightSetup = activeLightSetup
		spec.turnLightState = state
		spec.turnLightTriState = spec.turnLightState == Lights.TURNLIGHT_LEFT and 0 or spec.turnLightState == Lights.TURNLIGHT_RIGHT and 1 or 0.5

		if self.isServer then
			self:setLightsTypesMask(spec.lightsTypesMask, nil)
		end

		SpecializationUtil.raiseEvent(self, "onTurnLightStateChanged", state)
	end

	return true
end

function Lights:getTurnLightState()
	return self.spec_lights.turnLightState
end

function Lights:setBrakeLightsVisibility(visibility)
	local spec = self.spec_lights

	if visibility ~= spec.brakeLightsVisibility then
		spec.brakeLightsVisibility = visibility

		self:setLightsTypesMask(spec.lightsTypesMask)
		SpecializationUtil.raiseEvent(self, "onBrakeLightsVisibilityChanged", visibility)
	end

	return true
end

function Lights:setReverseLightsVisibility(visibility)
	local spec = self.spec_lights

	if visibility ~= spec.reverseLightsVisibility then
		spec.reverseLightsVisibility = visibility

		self:setLightsTypesMask(spec.lightsTypesMask)
		SpecializationUtil.raiseEvent(self, "onReverseLightsVisibilityChanged", visibility)
	end

	return true
end

function Lights:setInteriorLightsVisibility(visibility)
	local spec = self.spec_lights
	local brightness, hasChanged = self:getInteriorLightBrightness(true)

	if brightness == 0 then
		visibility = false
	end

	if visibility ~= spec.interiorLightsVisibility or hasChanged then
		spec.interiorLightsVisibility = visibility

		self:setLightsTypesMask(spec.lightsTypesMask, true, true)
	end

	return true
end

function Lights:getInteriorLightBrightness(updateState)
	local spec = self.spec_lights
	local changed = false

	if updateState then
		local brightness = 0
		local hour = g_currentMission.environment.currentHour + g_currentMission.environment.currentMinute / 60

		if hour < 10 then
			brightness = 1 - (hour - 8) / 2
		end

		if hour > 16 then
			brightness = (hour - 16) / 2
		end

		local oldBrightness = spec.interiorLightsBrightness
		spec.interiorLightsBrightness = MathUtil.clamp(brightness, 0, 1)
		changed = spec.interiorLightsBrightness ~= oldBrightness
	end

	return spec.interiorLightsBrightness, changed
end

function Lights:setLightsState(lights, isActive, chargeScale)
	for i = 1, #lights do
		self:setLightState(lights[i], isActive, chargeScale)
	end
end

function Lights:setLightState(light, isActive, chargeScale)
	if self:getIsLightActive(light) then
		if light.lightTypes ~= nil and light.excludedLightTypes ~= nil and type(isActive) == "number" then
			local lightsTypesMask = isActive
			isActive = false

			for _, lightType in pairs(light.lightTypes) do
				if bitAND(lightsTypesMask, 2^lightType) ~= 0 or lightType == -1 and self:getIsActiveForLights(true) then
					if not isActive then
						isActive = true
					elseif self.spec_lights.maxLightState < lightType then
						chargeScale = 2
					end
				end
			end

			if isActive then
				for _, excludedLightType in pairs(light.excludedLightTypes) do
					if bitAND(lightsTypesMask, 2^excludedLightType) ~= 0 then
						isActive = false

						break
					end
				end
			end
		end
	else
		isActive = false
	end

	if isActive and light.customChargeFunction ~= nil then
		chargeScale = light.customChargeFunction(self)
	end

	self:setStaticLightState(light, isActive, chargeScale)
	self:setRealLightState(light, isActive, chargeScale)

	light.isActive = isActive
end

function Lights:setRealLightState(realLight, isActive, chargeScale)
	local lightCharge = chargeScale or isActive and 1 or 0

	if getHasClassId(realLight.node, ClassIds.LIGHT_SOURCE) then
		if realLight.defaultColor ~= nil then
			local color = realLight.defaultColor

			setLightColor(realLight.node, color[1] * lightCharge, color[2] * lightCharge, color[3] * lightCharge)

			for j = 0, getNumOfChildren(realLight.node) - 1 do
				setLightColor(getChildAt(realLight.node, j), color[1] * lightCharge, color[2] * lightCharge, color[3] * lightCharge)
			end
		end

		setVisibility(realLight.node, isActive)
	end
end

function Lights:setStaticLightState(staticLight, isActive, chargeScale)
	local lightCharge = chargeScale or isActive and 1 or 0

	if staticLight.useShaderParameter then
		I3DUtil.setShaderParameterRec(staticLight.node, "lightControl", staticLight.intensity * lightCharge, nil, , )
	end

	if staticLight.toggleVisibility then
		setVisibility(staticLight.node, isActive)
	end
end

function Lights:deactivateLights(keepHazardLightsOn)
	local spec = self.spec_lights

	self:setLightsTypesMask(0, true, true)
	self:setBeaconLightsVisibility(false, true, true)

	if not keepHazardLightsOn or spec.turnLightState ~= Lights.TURNLIGHT_HAZARD then
		self:setTurnLightState(Lights.TURNLIGHT_OFF, true, true)
	end

	self:setBrakeLightsVisibility(false)
	self:setReverseLightsVisibility(false)
	self:setInteriorLightsVisibility(false)

	spec.currentLightState = 0

	SpecializationUtil.raiseEvent(self, "onDeactivateLights")
end

function Lights:deactivateBeaconLights()
	local spec = self.spec_lights

	for _, beaconLight in pairs(spec.beaconLights) do
		local device = beaconLight.device

		if device ~= nil then
			g_beaconLightManager:deactivateBeaconLight(device.deviceId)

			device.deviceId = nil
		end
	end
end

function Lights:getDeactivateLightsOnLeave()
	return true
end

local FS22_RENAMED_LIGHTS = {
	sideMarker_04Orange = "sideMarker05Orange",
	rear2ChamberLight_07 = "rearLight07",
	rearLightCircleOrange_01 = "rearLight21Orange",
	sideMarker_04White = "sideMarker05White",
	frontLightOval_02 = "frontLight04",
	rearLightOvalWhite_01 = "rearLight26White",
	sideMarker_05 = "sideMarker05",
	rearLightOvalLEDRed_02 = "rearLight25",
	sideMarker_04 = "sideMarker04",
	sideMarker_05Red = "sideMarker06Red",
	frontLightRectangle_01Orange = "frontLight06Orange",
	rearLightCircleOrange_02 = "rearLight22Orange",
	rearMultipointLight_05 = "rearLight29",
	rear5ChamberLight_02 = "rearLight16",
	rearLEDLight_01 = "rearLight17",
	frontLightCone_01 = "frontLight02",
	turnLight_01 = "turnLight01",
	frontLightRectangle_02 = "frontLight07",
	rearMultipointLight_01 = "rearLight31",
	rear2ChamberLight_05 = "rearLight05",
	rear2ChamberLed_01 = "rearLight01",
	sideMarker_06White = "sideMarker07White",
	rearLightOvalLEDChromeWhite_01 = "rearLight24",
	frontLightRectangle_01 = "frontLight06White",
	sideMarker_06Orange = "sideMarker07Orange",
	sideMarker_06Red = "sideMarker07Red",
	sideMarker_07White = "sideMarker08White",
	rear2ChamberLight_02 = "rearLight02",
	sideMarker_07Orange = "sideMarker08Orange",
	sideMarker_08White = "sideMarker09White",
	workingLightOval_03 = "workingLight05",
	sideMarker_09White = "sideMarker10White",
	sideMarker_05White = "sideMarker06White",
	sideMarker_02 = "sideMarker02",
	frontLightOval_03 = "frontLight05",
	sideMarker_09Orange = "sideMarker10Orange",
	rearLight_01 = "rearLight18",
	sideMarker_09Red = "sideMarker10Red",
	sideMarker_10Orange = "sideMarker11Orange",
	sideMarker_10Red = "sideMarker11Red",
	sideMarker_14White = "sideMarker14White",
	rear2ChamberLight_03 = "rearLight03",
	rearLightOvalLEDRed_01 = "rearLight23Red",
	sideMarker_09Orange_turn = "turnLight02",
	sideMarker_05Orange = "sideMarker06Orange",
	rear2ChamberTurnLed_01 = "turnLight03",
	rear3ChamberLight_03 = "rearLight10",
	workingLightCircle_02 = "workingLight02",
	rear3ChamberLight_02 = "rearLight09",
	rear4ChamberLight_02 = "rearLight14",
	rearMultipointLEDLight_01 = "rearLight30",
	workingLightOval_02 = "workingLight04",
	sideMarker_08Orange = "sideMarker09Orange",
	workingLightOval_05 = "workingLight07",
	workingLightSquare_01 = "workingLight08",
	rear2ChamberLight_04 = "rearLight04",
	workingLightSquare_02 = "workingLight09",
	workingLightSquare_03 = "workingLight10",
	workingLightOval_01 = "workingLight03",
	workingLightSquare_04 = "workingLight11",
	rearLightOvalLEDWhite_01 = "rearLight22White",
	rearPlateNumberLight_01 = "plateNumberLight01",
	rearLightOvalOrange_01 = "rearLight26Orange",
	rearMultipointLight_04 = "rearLight28",
	rear3ChamberLight_07 = "rearLight35",
	rear3ChamberLight_06 = "rearLight34",
	rearLightCircleWhite_02 = "rearLight22White",
	sideMarker_01 = "sideMarker01",
	frontLightOval_01 = "frontLight03",
	sideMarker_03 = "sideMarker03",
	rearLightCircleRed_02 = "rearLight22Red",
	rearLightCircleRed_01 = "rearLight21Red",
	rearLightCircle_01Orange = "rearLight19Orange",
	rearLightOvalRed_01 = "rearLight26Red",
	rear5ChamberLight_01 = "rearLight15",
	workingLightCircle_01 = "workingLight01",
	rear3ChamberLight_01 = "rearLight08",
	rear4ChamberLight_01 = "rearLight13",
	rearLightCircle_01Red = "rearLight19Red",
	rearLightSquare_01Orange = "rearLight27Orange",
	rearLightOvalLEDOrange_01 = "rearLight23Orange",
	rear3ChamberLight_04 = "rearLight11",
	rearLightCircleLEDRed_01 = "rearLight20",
	frontLight_01 = "frontLight01",
	sideMarker_04Red = "sideMarker05Red",
	rear2ChamberLight_06 = "rearLight06",
	workingLightOval_04 = "workingLight06",
	rearMultipointLight_02 = "rearLight32",
	rear3ChamberLight_05 = "rearLight12",
	sideMarker_06 = "sideMarker06",
	rear2ChamberLight_01 = "rearLight36",
	rearMultipointLight_03 = "rearLight33"
}

function Lights:loadSharedLight(xmlFile, key, targetTable)
	local spec = self.spec_lights
	local xmlFilename = xmlFile:getValue(key .. "#filename")

	if xmlFilename ~= nil then
		xmlFilename = Utils.getFilename(xmlFilename, self.baseDirectory)
		local lightXMLFile = XMLFile.load("sharedLight", xmlFilename, Lights.sharedLightXMLSchema)

		if lightXMLFile ~= nil then
			local filename = lightXMLFile:getValue("light.filename")

			if filename == nil then
				Logging.xmlWarning(lightXMLFile, "Missing light i3d filename!")
				lightXMLFile:delete()

				return
			end

			local sharedLight = {
				linkNode = xmlFile:getValue(key .. "#linkNode", "0>", self.components, self.i3dMappings)
			}

			if sharedLight.linkNode == nil then
				Logging.xmlWarning(xmlFile, "Missing light linkNode in '%s'!", key)
				lightXMLFile:delete()

				return
			end

			sharedLight.lightTypes = xmlFile:getValue(key .. "#lightTypes", nil, true)
			sharedLight.excludedLightTypes = xmlFile:getValue(key .. "#excludedLightTypes", nil, true)
			local rotations = {}
			local i = 0

			while true do
				local rotKey = string.format("%s.rotationNode(%d)", key, i)

				if not xmlFile:hasProperty(rotKey) then
					break
				end

				local name = xmlFile:getValue(rotKey .. "#name")
				local rotation = xmlFile:getValue(rotKey .. "#rotation", nil, true)

				if name ~= nil then
					rotations[name] = rotation
				end

				i = i + 1
			end

			filename = Utils.getFilename(filename, self.baseDirectory)
			sharedLight.filename = filename
			spec.xmlLoadingHandles[lightXMLFile] = true
			local sharedLoadRequestId = self:loadSubSharedI3DFile(filename, false, false, self.loadSharedLightI3DLoaded, self, {
				xmlFile,
				key,
				lightXMLFile,
				sharedLight,
				targetTable,
				rotations
			})

			table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
		else
			for old, new in pairs(FS22_RENAMED_LIGHTS) do
				if xmlFilename:find(old) then
					local newPath = xmlFilename:gsub(old, new)

					if fileExists(newPath) then
						Logging.xmlWarning(xmlFile, "Light '%s' has been renamed to '%s' in '%s'!", old, new, key)
					end
				end
			end
		end
	end
end

function Lights:loadStaticLightNodesFromSharedLight(vehicleXMLFile, vehicleXMLKey, lightXMLFile, lightXMLFileKey, i3dNode, globalTargetTable, specificTargetTable, sharedLight, loadLightTypes)
	lightXMLFile:iterate(lightXMLFileKey, function (_, staticLightKey)
		local node = lightXMLFile:getValue(staticLightKey .. "#node", "0", i3dNode)

		if node ~= nil then
			if I3DUtil.getIsLinkedToNode(sharedLight.node, node) then
				if getHasShaderParameter(node, "lightControl") then
					local staticLight = {
						node = node
					}
					local newStaticLight = true

					for i = 1, #globalTargetTable do
						local globalStaticLight = globalTargetTable[i]

						if globalStaticLight.node == staticLight.node then
							staticLight = globalStaticLight
							newStaticLight = false
						end
					end

					staticLight.useShaderParameter = true
					staticLight.intensity = lightXMLFile:getValue(staticLightKey .. "#intensity", 25)

					I3DUtil.setShaderParameterRec(node, "lightControl", 0, nil, , )

					staticLight.toggleVisibility = lightXMLFile:getValue(staticLightKey .. "#toggleVisibility", false)

					if staticLight.toggleVisibility then
						setVisibility(staticLight.node, false)
					end

					if loadLightTypes then
						staticLight.excludedLightTypes = lightXMLFile:getValue(staticLightKey .. "#excludedLightTypes", staticLight.excludedLightTypes, true)

						if sharedLight.excludedLightTypes ~= nil and #sharedLight.excludedLightTypes > 0 then
							staticLight.excludedLightTypes = table.copy(sharedLight.excludedLightTypes)
						end

						staticLight.lightTypes = lightXMLFile:getValue(staticLightKey .. "#lightTypes", staticLight.lightTypes, true)

						if sharedLight.lightTypes ~= nil and #sharedLight.lightTypes > 0 then
							staticLight.lightTypes = table.copy(sharedLight.lightTypes)
						end
					else
						staticLight.excludedLightTypes = staticLight.excludedLightTypes or {}
						staticLight.lightTypes = staticLight.lightTypes or {}
					end

					self:loadAdditionalLightAttributesFromXML(vehicleXMLFile, vehicleXMLKey, staticLight)

					if newStaticLight then
						table.insert(globalTargetTable, staticLight)
					end

					table.insert(specificTargetTable, staticLight)
				else
					Logging.xmlWarning(lightXMLFile, "Node '%s' has no shaderparameter 'lightControl'. Ignoring node!", getName(node))
				end
			else
				Logging.xmlWarning(lightXMLFile, "Defined node '%s' is not a child of the static light root node in '%s!", getName(node), staticLightKey)
			end
		else
			Logging.xmlWarning(lightXMLFile, "Could not find node for '%s'!", staticLightKey)
		end
	end)
end

function Lights:loadSharedLightI3DLoaded(i3dNode, failedReason, args)
	local spec = self.spec_lights
	local xmlFile, key, lightXMLFile, sharedLight, targetTable, rotations = unpack(args)

	if i3dNode ~= 0 then
		sharedLight.node = lightXMLFile:getValue("light.rootNode#node", "0", i3dNode)

		self:loadStaticLightNodesFromSharedLight(xmlFile, key, lightXMLFile, "light.defaultLight", i3dNode, spec.staticLights, spec.defaultLightsStatic, sharedLight, true)
		self:loadStaticLightNodesFromSharedLight(xmlFile, key, lightXMLFile, "light.brakeLight", i3dNode, spec.staticLights, spec.brakeLightsStatic, sharedLight)
		self:loadStaticLightNodesFromSharedLight(xmlFile, key, lightXMLFile, "light.reverseLight", i3dNode, spec.staticLights, spec.reverseLightsStatic, sharedLight)
		self:loadStaticLightNodesFromSharedLight(xmlFile, key, lightXMLFile, "light.turnLightLeft", i3dNode, spec.staticLights, spec.turnLightsLeftStatic, sharedLight)
		self:loadStaticLightNodesFromSharedLight(xmlFile, key, lightXMLFile, "light.turnLightRight", i3dNode, spec.staticLights, spec.turnLightsRightStatic, sharedLight)
		lightXMLFile:iterate("light.rotationNode", function (_, baseKey)
			local name = lightXMLFile:getValue(baseKey .. "#name")

			if name ~= nil then
				local node = lightXMLFile:getValue(baseKey .. "#node", nil, i3dNode)

				if rotations[name] ~= nil then
					setRotation(node, unpack(rotations[name]))
				end
			end
		end)
		link(sharedLight.linkNode, sharedLight.node)
		delete(i3dNode)
		table.insert(targetTable, sharedLight)
	end

	lightXMLFile:delete()

	spec.xmlLoadingHandles[lightXMLFile] = nil
end

function Lights:loadAdditionalLightAttributesFromXML(xmlFile, key, light)
	return true
end

function Lights:getIsLightActive(light)
	return true
end

function Lights:updateAILights(isWorking)
	local spec = self.spec_lights

	if not g_currentMission.environment.isSunOn then
		local typeMask = spec.aiLightsTypesMask

		if isWorking then
			typeMask = spec.aiLightsTypesMaskWork
		end

		if spec.lightsTypesMask ~= typeMask then
			self:setLightsTypesMask(typeMask)
		end
	elseif spec.lightsTypesMask ~= 0 then
		self:setLightsTypesMask(0)
	end
end

function Lights:lightsWeatherChanged()
	local spec = self.spec_lights

	g_inputBinding:setActionEventTextVisibility(spec.actionEventIdLight, not g_currentMission.environment.isSunOn)
end

function Lights:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient and self.getIsEntered ~= nil and self:getIsEntered() then
		local spec = self.spec_lights

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _ = nil
			_, spec.actionEventIdLight = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_LIGHTS, self, Lights.actionEventToggleLights, false, true, false, true, nil)
			local _, actionEventIdReverse = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_LIGHTS_BACK, self, Lights.actionEventToggleLightsBack, false, true, false, true, nil)
			local _, actionEventIdFront = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_LIGHT_FRONT, self, Lights.actionEventToggleLightFront, false, true, false, true, nil)
			local _, actionEventIdWorkBack = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_WORK_LIGHT_BACK, self, Lights.actionEventToggleWorkLightBack, false, true, false, true, nil)
			local _, actionEventIdWorkFront = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_WORK_LIGHT_FRONT, self, Lights.actionEventToggleWorkLightFront, false, true, false, true, nil)
			local _, actionEventIdHighBeam = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_HIGH_BEAM_LIGHT, self, Lights.actionEventToggleHighBeamLight, false, true, false, true, nil)

			self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TURNLIGHT_HAZARD, self, Lights.actionEventToggleTurnLightHazard, false, true, false, true, nil)
			self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TURNLIGHT_LEFT, self, Lights.actionEventToggleTurnLightLeft, false, true, false, true, nil)
			self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_TURNLIGHT_RIGHT, self, Lights.actionEventToggleTurnLightRight, false, true, false, true, nil)

			local _, actionEventIdBeacon = self:addActionEvent(spec.actionEvents, InputAction.TOGGLE_BEACON_LIGHTS, self, Lights.actionEventToggleBeaconLights, false, true, false, true, nil)
			spec.actionEventsActiveChange = {
				actionEventIdFront,
				actionEventIdWorkBack,
				actionEventIdWorkFront,
				actionEventIdHighBeam,
				actionEventIdBeacon
			}

			for _, actionEvent in pairs(spec.actionEvents) do
				if actionEvent.actionEventId ~= nil then
					g_inputBinding:setActionEventTextVisibility(actionEvent.actionEventId, false)
					g_inputBinding:setActionEventTextPriority(actionEvent.actionEventId, GS_PRIO_LOW)
				end
			end

			g_inputBinding:setActionEventTextVisibility(spec.actionEventIdLight, not g_currentMission.environment.isSunOn)
			g_inputBinding:setActionEventTextVisibility(actionEventIdReverse, false)
		end
	end
end

function Lights:onEnterVehicle(isControlling)
	local spec = self.spec_lights

	self:setLightsTypesMask(spec.lightsTypesMask, true, true)
	self:setBeaconLightsVisibility(spec.beaconLightsActive, true, true)
	self:setTurnLightState(spec.turnLightState, true, true)
end

function Lights:onLeaveVehicle()
	if self:getDeactivateLightsOnLeave() then
		self:deactivateLights(true)
	end

	self:deactivateBeaconLights()
end

function Lights:onDeactivate()
	self:deactivateBeaconLights()
end

function Lights:onStartMotor()
	self:setLightsTypesMask(self.spec_lights.lightsTypesMask, true, true)
end

function Lights:onStopMotor()
	self:setLightsTypesMask(self.spec_lights.lightsTypesMask, true, true)
end

function Lights:onStartReverseDirectionChange()
	local spec = self.spec_lights

	if spec.lightsTypesMask > 0 then
		self:setLightsTypesMask(spec.lightsTypesMask, true, true)
	end
end

function Lights:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	if attacherVehicle.getLightsTypesMask ~= nil then
		self:setLightsTypesMask(attacherVehicle:getLightsTypesMask(), true, true)
		self:setBeaconLightsVisibility(attacherVehicle:getBeaconLightsVisibility(), true, true)
		self:setTurnLightState(attacherVehicle:getTurnLightState(), true, true)
	end
end

function Lights:onPostDetach()
	self:deactivateLights()
end

function Lights:onAutomatedTrainTravelActive()
	self:updateAILights(false)
end

function Lights:onAIDriveableActive()
	self:updateAILights(false)
end

function Lights:onAIDriveableEnd()
	if self.getIsControlled ~= nil and not self:getIsControlled() then
		self:setLightsTypesMask(0)
	end
end

function Lights:onAIFieldWorkerActive()
	self:updateAILights(true)
end

function Lights:onAIFieldWorkerBlock()
	self:setBeaconLightsVisibility(true, true, true)
end

function Lights:onAIFieldWorkerContinue()
	self:setBeaconLightsVisibility(false, true, true)
end

function Lights:onAIFieldWorkerEnd()
	if self.getIsControlled ~= nil and not self:getIsControlled() then
		self:setLightsTypesMask(0)
	end
end

function Lights:onVehiclePhysicsUpdate(acceleratorPedal, brakePedal, automaticBrake, currentSpeed)
	self:setBrakeLightsVisibility(not automaticBrake and math.abs(brakePedal) > 0)

	local reverserDirection = 1

	if self.spec_drivable ~= nil then
		reverserDirection = self.spec_drivable.reverserDirection
	end

	self:setReverseLightsVisibility((currentSpeed < -self.spec_lights.reverseLightActivationSpeed or acceleratorPedal < 0) and reverserDirection == 1)
end

function Lights:loadRealLightSetup(xmlFile, key, lightTable, realLightToLight)
	lightTable.realLights = {}
	lightTable.defaultLights = {}
	lightTable.turnLightsLeft = {}
	lightTable.turnLightsRight = {}
	lightTable.brakeLights = {}
	lightTable.reverseLights = {}
	lightTable.interiorLights = {}

	self:loadRealLights(xmlFile, key .. ".light", lightTable.realLights, lightTable.defaultLights)
	self:loadRealLights(xmlFile, key .. ".brakeLight", lightTable.realLights, lightTable.brakeLights)
	self:loadRealLights(xmlFile, key .. ".reverseLight", lightTable.realLights, lightTable.reverseLights)
	self:loadRealLights(xmlFile, key .. ".turnLightLeft", lightTable.realLights, lightTable.turnLightsLeft)
	self:loadRealLights(xmlFile, key .. ".turnLightRight", lightTable.realLights, lightTable.turnLightsRight)
	self:loadRealLights(xmlFile, key .. ".interiorLight", lightTable.realLights, lightTable.interiorLights)

	for i = 1, #lightTable.interiorLights do
		local interiorLight = lightTable.interiorLights[i]
		interiorLight.customChargeFunction = self.getInteriorLightBrightness
		self.spec_lights.interiorLightsAvailable = true
	end
end

function Lights:loadRealLights(xmlFile, key, globalTargetTable, specificTargetTable)
	xmlFile:iterate(key, function (_, realLightKey)
		local node = xmlFile:getValue(realLightKey .. "#node", nil, self.components, self.i3dMappings)

		if node ~= nil then
			if getHasClassId(node, ClassIds.LIGHT_SOURCE) then
				local realLight = {
					node = node,
					toggleVisibility = true
				}
				local newRealLight = true

				for i = 1, #globalTargetTable do
					local globalRealLight = globalTargetTable[i]

					if globalRealLight.node == realLight.node then
						realLight = globalRealLight
						newRealLight = false
					end
				end

				I3DUtil.interateRecursively(node, function (childNode)
					if not getVisibility(childNode) then
						Logging.xmlWarning(xmlFile, "Real light source '%s' is hidden in '%s'!", getName(childNode), realLightKey)
					end
				end)
				setVisibility(node, false)

				realLight.defaultColor = realLight.defaultColor or {
					getLightColor(node)
				}
				local excludedLightTypes = xmlFile:getValue(realLightKey .. "#excludedLightTypes", nil, true)

				if realLight.excludedLightTypes == nil then
					realLight.excludedLightTypes = excludedLightTypes
				else
					for j = 1, #excludedLightTypes do
						table.insert(realLight.excludedLightTypes, excludedLightTypes[j])
					end
				end

				local lightTypes = xmlFile:getValue(realLightKey .. "#lightTypes", nil, true)

				if realLight.lightTypes == nil then
					realLight.lightTypes = lightTypes
				else
					for j = 1, #lightTypes do
						table.insert(realLight.lightTypes, lightTypes[j])
					end
				end

				self:loadAdditionalLightAttributesFromXML(xmlFile, realLightKey, realLight)

				if newRealLight then
					table.insert(globalTargetTable, realLight)
				end

				table.insert(specificTargetTable, realLight)
			else
				Logging.xmlWarning(xmlFile, "Node '%s' is not a real light source in '%s'", getName(node), key)
			end
		else
			Logging.xmlWarning(xmlFile, "RealLight node missing for light '%s'", key)
		end
	end)
end

function Lights:loadStaticLightNodes(xmlFile, key, globalTargetTable, specificTargetTable)
	xmlFile:iterate(key, function (_, staticLightKey)
		local node = xmlFile:getValue(staticLightKey .. "#node", nil, self.components, self.i3dMappings)
		local shaderNode = xmlFile:getValue(staticLightKey .. "#shaderNode", nil, self.components, self.i3dMappings)

		if node ~= nil or shaderNode ~= nil then
			local staticLight = {
				node = node or shaderNode
			}
			local newStaticLight = true

			for i = 1, #globalTargetTable do
				local globalStaticLight = globalTargetTable[i]

				if globalStaticLight.node == staticLight.node then
					staticLight = globalStaticLight
					newStaticLight = false
				end
			end

			if shaderNode ~= nil then
				staticLight.useShaderParameter = true
				staticLight.intensity = xmlFile:getValue(staticLightKey .. "#intensity", 25)

				I3DUtil.setShaderParameterRec(shaderNode, "lightControl", 0, nil, , )
			end

			staticLight.toggleVisibility = xmlFile:getValue(staticLightKey .. "#toggleVisibility", node ~= nil)

			if staticLight.toggleVisibility then
				setVisibility(staticLight.node, false)
			end

			local excludedLightTypes = xmlFile:getValue(staticLightKey .. "#excludedLightTypes", nil, true)

			if staticLight.excludedLightTypes == nil then
				staticLight.excludedLightTypes = excludedLightTypes
			else
				for j = 1, #excludedLightTypes do
					table.insert(staticLight.excludedLightTypes, excludedLightTypes[j])
				end
			end

			local lightTypes = xmlFile:getValue(staticLightKey .. "#lightTypes", nil, true)

			if staticLight.lightTypes == nil then
				staticLight.lightTypes = lightTypes
			else
				for j = 1, #lightTypes do
					table.insert(staticLight.lightTypes, lightTypes[j])
				end
			end

			self:loadAdditionalLightAttributesFromXML(xmlFile, staticLightKey, staticLight)

			if newStaticLight then
				table.insert(globalTargetTable, staticLight)
			end

			table.insert(specificTargetTable, staticLight)
		end
	end)
end

function Lights:applyAdditionalActiveLightType(lights, lightType)
	for i = 1, #lights do
		local light = lights[i]

		table.insert(light.lightTypes, lightType)
	end
end

function Lights:loadBeaconLightFromXML(xmlFile, key)
	local spec = self.spec_lights
	local beaconLight = {
		node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
	}

	if beaconLight.node ~= nil then
		local lightXmlFilename = xmlFile:getValue(key .. "#filename")
		beaconLight.speed = xmlFile:getValue(key .. "#speed")
		beaconLight.realLightRange = xmlFile:getValue(key .. "#realLightRange", 1)
		beaconLight.intensity = xmlFile:getValue(key .. "#intensity")

		if lightXmlFilename ~= nil then
			lightXmlFilename = Utils.getFilename(lightXmlFilename, self.baseDirectory)
			local beaconLightXMLFile = XMLFile.load("beaconLightXML", lightXmlFilename, Lights.beaconLightXMLSchema)

			if beaconLightXMLFile ~= nil then
				spec.xmlLoadingHandles[beaconLightXMLFile] = true
				beaconLight.xmlFile = beaconLightXMLFile
				local i3dFilename = beaconLightXMLFile:getValue("beaconLight.filename")

				if i3dFilename ~= nil then
					beaconLight.filename = Utils.getFilename(i3dFilename, self.baseDirectory)
					local sharedLoadRequestId = self:loadSubSharedI3DFile(beaconLight.filename, false, false, self.onBeaconLightI3DLoaded, self, beaconLight)

					table.insert(spec.sharedLoadRequestIds, sharedLoadRequestId)
				end
			end
		else
			beaconLight.lightShaderNode = beaconLight.node
			beaconLight.realLightNode = xmlFile:getValue(key .. ".realLight#node", nil, self.components, self.i3dMappings)
			beaconLight.rotatorNode = xmlFile:getValue(key .. ".rotator#node", nil, self.components, self.i3dMappings)
			beaconLight.multiBlink = xmlFile:getValue(key .. "#multiBlink", false)
			beaconLight.device = BeaconLightManager.loadDeviceFromXML(xmlFile, key .. ".device")

			if beaconLight.realLightNode ~= nil then
				beaconLight.defaultColor = {
					getLightColor(beaconLight.realLightNode)
				}

				setVisibility(beaconLight.realLightNode, false)

				beaconLight.defaultLightRange = getLightRange(beaconLight.realLightNode)

				setLightRange(beaconLight.realLightNode, beaconLight.defaultLightRange * beaconLight.realLightRange)
			end

			table.insert(spec.beaconLights, beaconLight)
		end
	end
end

function Lights:onBeaconLightI3DLoaded(i3dNode, failedReason, beaconLight)
	local spec = self.spec_lights
	local xmlFile = beaconLight.xmlFile

	if i3dNode ~= 0 then
		local rootNode = xmlFile:getValue("beaconLight.rootNode#node", nil, i3dNode)
		local lightNode = xmlFile:getValue("beaconLight.light#node", nil, i3dNode)
		local lightShaderNode = xmlFile:getValue("beaconLight.light#shaderNode", nil, i3dNode)

		if rootNode ~= nil and (lightNode ~= nil or lightShaderNode ~= nil) then
			beaconLight.rootNode = rootNode
			beaconLight.lightNode = lightNode
			beaconLight.lightShaderNode = lightShaderNode
			beaconLight.realLightNode = xmlFile:getValue("beaconLight.realLight#node", nil, i3dNode)
			beaconLight.rotatorNode = xmlFile:getValue("beaconLight.rotator#node", nil, i3dNode)
			beaconLight.speed = xmlFile:getValue("beaconLight.rotator#speed", beaconLight.speed or 0.015)
			beaconLight.intensity = xmlFile:getValue("beaconLight.light#intensity", beaconLight.intensity or 1000)
			beaconLight.multiBlink = xmlFile:getValue("beaconLight.light#multiBlink", false)
			beaconLight.device = BeaconLightManager.loadDeviceFromXML(xmlFile, "beaconLight.device")

			link(beaconLight.node, rootNode)
			setTranslation(rootNode, 0, 0, 0)

			if beaconLight.realLightNode ~= nil then
				beaconLight.defaultColor = {
					getLightColor(beaconLight.realLightNode)
				}

				setVisibility(beaconLight.realLightNode, false)

				beaconLight.defaultLightRange = getLightRange(beaconLight.realLightNode)

				setLightRange(beaconLight.realLightNode, beaconLight.defaultLightRange * beaconLight.realLightRange)
			end

			if lightNode ~= nil then
				setVisibility(lightNode, false)
			end

			if lightShaderNode ~= nil then
				local _, y, z, w = getShaderParameter(lightShaderNode, "lightControl")

				setShaderParameter(lightShaderNode, "lightControl", 0, y, z, w, false)
			end

			if beaconLight.speed > 0 then
				local rot = math.random(0, math.pi * 2)

				if beaconLight.rotatorNode ~= nil then
					setRotation(beaconLight.rotatorNode, 0, rot, 0)
				end
			end

			table.insert(spec.beaconLights, beaconLight)
		end

		delete(i3dNode)
	end

	xmlFile:delete()

	beaconLight.xmlFile = nil
	spec.xmlLoadingHandles[xmlFile] = nil
end

function Lights:actionEventToggleLightFront(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() and spec.numLightTypes >= 1 then
		local lightsTypesMask = bitXOR(spec.lightsTypesMask, 2^Lights.LIGHT_TYPE_DEFAULT)

		self:setLightsTypesMask(lightsTypesMask)
	end
end

function Lights:actionEventToggleLights(actionName, inputValue, callbackState, isAnalog)
	if self:getCanToggleLight() then
		self:setNextLightsState(1)
	end
end

function Lights:actionEventToggleLightsBack(actionName, inputValue, callbackState, isAnalog)
	if self:getCanToggleLight() then
		self:setNextLightsState(-1)
	end
end

function Lights:actionEventToggleWorkLightBack(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() then
		local lightsTypesMask = bitXOR(spec.lightsTypesMask, 2^Lights.LIGHT_TYPE_WORK_BACK)

		self:setLightsTypesMask(lightsTypesMask)
	end
end

function Lights:actionEventToggleWorkLightFront(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() then
		local lightsTypesMask = bitXOR(spec.lightsTypesMask, 2^Lights.LIGHT_TYPE_WORK_FRONT)

		self:setLightsTypesMask(lightsTypesMask)
	end
end

function Lights:actionEventToggleHighBeamLight(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() then
		local lightsTypesMask = bitXOR(spec.lightsTypesMask, 2^Lights.LIGHT_TYPE_HIGHBEAM)

		self:setLightsTypesMask(lightsTypesMask)
	end
end

function Lights:actionEventToggleTurnLightHazard(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() then
		local state = Lights.TURNLIGHT_OFF

		if spec.turnLightState ~= Lights.TURNLIGHT_HAZARD then
			state = Lights.TURNLIGHT_HAZARD
		end

		self:setTurnLightState(state)
	end
end

function Lights:actionEventToggleTurnLightLeft(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() then
		local state = Lights.TURNLIGHT_OFF

		if spec.turnLightState ~= Lights.TURNLIGHT_LEFT then
			state = Lights.TURNLIGHT_LEFT
		end

		self:setTurnLightState(state)
	end
end

function Lights:actionEventToggleTurnLightRight(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() then
		local state = Lights.TURNLIGHT_OFF

		if spec.turnLightState ~= Lights.TURNLIGHT_RIGHT then
			state = Lights.TURNLIGHT_RIGHT
		end

		self:setTurnLightState(state)
	end
end

function Lights:actionEventToggleBeaconLights(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_lights

	if self:getCanToggleLight() then
		self:setBeaconLightsVisibility(not spec.beaconLightsActive)
	end
end

function Lights:dashboardLightAttributes(xmlFile, key, dashboard, isActive)
	dashboard.lightTypes = xmlFile:getValue(key .. "#lightTypes", nil, true)
	dashboard.excludedLightTypes = xmlFile:getValue(key .. "#excludedLightTypes", nil, true)
	dashboard.lightStates = {}

	for i = 0, self.spec_lights.maxLightState do
		dashboard.lightStates[i] = false
	end

	return true
end

function Lights:dashboardLightState(dashboard, newValue, minValue, maxValue, isActive)
	local lightsTypesMask = self.spec_lights.lightsTypesMask

	if dashboard.displayTypeIndex == Dashboard.TYPES.MULTI_STATE then
		for i = 0, self.spec_lights.maxLightState do
			dashboard.lightStates[i] = bitAND(lightsTypesMask, 2^i) ~= 0
		end

		Dashboard.defaultMultiStateDashboardStateFunc(self, dashboard, dashboard.lightStates, minValue, maxValue, isActive)
	else
		local lightIsActive = false

		if dashboard.lightTypes ~= nil then
			for _, lightType in pairs(dashboard.lightTypes) do
				if bitAND(lightsTypesMask, 2^lightType) ~= 0 or lightType == -1 and self:getIsActiveForLights(true) then
					lightIsActive = true

					break
				end
			end
		end

		if lightIsActive then
			for _, excludedLightType in pairs(dashboard.excludedLightTypes) do
				if bitAND(lightsTypesMask, 2^excludedLightType) ~= 0 then
					lightIsActive = false

					break
				end
			end
		end

		Dashboard.defaultDashboardStateFunc(self, dashboard, lightIsActive, minValue, maxValue, isActive)
	end
end
