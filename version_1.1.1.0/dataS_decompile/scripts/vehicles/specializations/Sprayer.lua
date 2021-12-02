source("dataS/scripts/vehicles/specializations/events/SprayerDoubledAmountEvent.lua")

Sprayer = {
	SPRAY_TYPE_XML_KEY = "vehicle.sprayer.sprayTypes.sprayType(?)",
	AI_REQUIRED_GROUND_TYPES = {
		FieldGroundType.STUBBLE_TILLAGE,
		FieldGroundType.CULTIVATED,
		FieldGroundType.SEEDBED,
		FieldGroundType.PLOWED,
		FieldGroundType.ROLLED_SEEDBED,
		FieldGroundType.SOWN,
		FieldGroundType.DIRECT_SOWN,
		FieldGroundType.PLANTED,
		FieldGroundType.RIDGE,
		FieldGroundType.ROLLER_LINES,
		FieldGroundType.HARVEST_READY,
		FieldGroundType.HARVEST_READY_OTHER,
		FieldGroundType.GRASS,
		FieldGroundType.GRASS_CUT
	}
}

function Sprayer.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("sprayer", false)

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Sprayer")
	schema:register(XMLValueType.BOOL, "vehicle.sprayer#allowsSpraying", "Allows spraying", true)
	schema:register(XMLValueType.BOOL, "vehicle.sprayer#activateTankOnLowering", "Activate tank on lowering", false)
	schema:register(XMLValueType.BOOL, "vehicle.sprayer#activateOnLowering", "Activate on lowering", false)
	schema:register(XMLValueType.FLOAT, "vehicle.sprayer.usageScales#scale", "Usage scale", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.sprayer.usageScales#workingWidth", "Working width", 12)
	schema:register(XMLValueType.INT, "vehicle.sprayer.usageScales#workAreaIndex", "Work area that is used for working width reference instead of #workingWidth")
	schema:register(XMLValueType.STRING, "vehicle.sprayer.usageScales.sprayUsageScale(?)#fillType", "Fill type name")
	schema:register(XMLValueType.FLOAT, "vehicle.sprayer.usageScales.sprayUsageScale(?)#scale", "Scale")
	schema:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. "#fillUnitIndex", "Fill unit index")
	schema:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. "#unloadInfoIndex", "Unload info index")
	schema:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. "#fillVolumeIndex", "Fill volume index")
	SoundManager.registerSampleXMLPaths(schema, Sprayer.SPRAY_TYPE_XML_KEY .. ".sounds", "work")
	SoundManager.registerSampleXMLPaths(schema, Sprayer.SPRAY_TYPE_XML_KEY .. ".sounds", "spray")
	AnimationManager.registerAnimationNodesXMLPaths(schema, Sprayer.SPRAY_TYPE_XML_KEY .. ".animationNodes")
	EffectManager.registerEffectXMLPaths(schema, Sprayer.SPRAY_TYPE_XML_KEY .. ".effects")
	schema:register(XMLValueType.STRING, Sprayer.SPRAY_TYPE_XML_KEY .. ".turnedAnimation#name", "Turned animation name")
	schema:register(XMLValueType.FLOAT, Sprayer.SPRAY_TYPE_XML_KEY .. ".turnedAnimation#turnOnSpeedScale", "Speed Scale while turned on", 1)
	schema:register(XMLValueType.FLOAT, Sprayer.SPRAY_TYPE_XML_KEY .. ".turnedAnimation#turnOffSpeedScale", "Speed Scale while turned off", "Inversed #turnOnSpeedScale")
	schema:register(XMLValueType.BOOL, Sprayer.SPRAY_TYPE_XML_KEY .. ".turnedAnimation#externalFill", "Animation is played while sprayer is externally filled", true)
	schema:register(XMLValueType.NODE_INDEX, Sprayer.SPRAY_TYPE_XML_KEY .. ".ai.areaMarkers#leftNode", "AI marker left node")
	schema:register(XMLValueType.NODE_INDEX, Sprayer.SPRAY_TYPE_XML_KEY .. ".ai.areaMarkers#rightNode", "AI marker right node")
	schema:register(XMLValueType.NODE_INDEX, Sprayer.SPRAY_TYPE_XML_KEY .. ".ai.areaMarkers#backNode", "AI marker back node")
	schema:register(XMLValueType.NODE_INDEX, Sprayer.SPRAY_TYPE_XML_KEY .. ".ai.sizeMarkers#leftNode", "AI size marker left node")
	schema:register(XMLValueType.NODE_INDEX, Sprayer.SPRAY_TYPE_XML_KEY .. ".ai.sizeMarkers#rightNode", "AI size marker right node")
	schema:register(XMLValueType.NODE_INDEX, Sprayer.SPRAY_TYPE_XML_KEY .. ".ai.sizeMarkers#backNode", "AI size marker back node")
	AIImplement.registerAICollisionTriggerXMLPaths(schema, Sprayer.SPRAY_TYPE_XML_KEY .. ".ai")
	schema:register(XMLValueType.STRING, Sprayer.SPRAY_TYPE_XML_KEY .. "#fillTypes", "Fill types")
	schema:register(XMLValueType.FLOAT, Sprayer.SPRAY_TYPE_XML_KEY .. ".usageScales#workingWidth", "Work width", 12)
	schema:register(XMLValueType.INT, Sprayer.SPRAY_TYPE_XML_KEY .. ".usageScales#workAreaIndex", "Work area that is used for working width reference instead of #workingWidth")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, Sprayer.SPRAY_TYPE_XML_KEY)
	EffectManager.registerEffectXMLPaths(schema, "vehicle.sprayer.effects")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.sprayer.sounds", "work")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.sprayer.sounds", "spray")
	AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.sprayer.animationNodes")
	schema:register(XMLValueType.STRING, "vehicle.sprayer.animation#name", "Spray animation name")
	schema:register(XMLValueType.INT, "vehicle.sprayer#fillUnitIndex", "Fill unit index", 1)
	schema:register(XMLValueType.INT, "vehicle.sprayer#unloadInfoIndex", "Unload info index", 1)
	schema:register(XMLValueType.INT, "vehicle.sprayer#fillVolumeIndex", "Fill volume index")
	schema:register(XMLValueType.VECTOR_3, "vehicle.sprayer#fillVolumeDischargeScrollSpeed", "Fill volume discharge scroll speed", "0 0 0")
	schema:register(XMLValueType.FLOAT, "vehicle.sprayer.doubledAmount#decreasedSpeed", "Speed while doubled amount is sprayed", "automatically calculated")
	schema:register(XMLValueType.FLOAT, "vehicle.sprayer.doubledAmount#decreaseFactor", "Decrease factor that is applied on speedLimit while doubled amount is sprayed", 0.5)
	schema:register(XMLValueType.STRING, "vehicle.sprayer.doubledAmount#toggleButton", "Name of input action to toggle doubled amount", "IMPLEMENT_EXTRA4")
	schema:register(XMLValueType.L10N_STRING, "vehicle.sprayer.doubledAmount#deactivateText", "Deactivated text", "action_deactivateDoubledSprayAmount")
	schema:register(XMLValueType.L10N_STRING, "vehicle.sprayer.doubledAmount#activateText", "Activate text", "action_activateDoubledSprayAmount")
	schema:register(XMLValueType.STRING, "vehicle.sprayer.turnedAnimation#name", "Turned animation name")
	schema:register(XMLValueType.FLOAT, "vehicle.sprayer.turnedAnimation#turnOnSpeedScale", "Speed Scale while turned on", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.sprayer.turnedAnimation#turnOffSpeedScale", "Speed Scale while turned off", "Inversed #turnOnSpeedScale")
	schema:register(XMLValueType.BOOL, "vehicle.sprayer.turnedAnimation#externalFill", "Animation is played while sprayer is externally filled", true)
	schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. "#sprayType", "Spray type index")
	schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. "#sprayType", "Spray type index")
	schema:setXMLSpecializationType()
end

function Sprayer.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end

function Sprayer.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onSprayTypeChange")
end

function Sprayer.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processSprayerArea", Sprayer.processSprayerArea)
	SpecializationUtil.registerFunction(vehicleType, "getIsSprayerExternallyFilled", Sprayer.getIsSprayerExternallyFilled)
	SpecializationUtil.registerFunction(vehicleType, "getExternalFill", Sprayer.getExternalFill)
	SpecializationUtil.registerFunction(vehicleType, "getAreEffectsVisible", Sprayer.getAreEffectsVisible)
	SpecializationUtil.registerFunction(vehicleType, "updateSprayerEffects", Sprayer.updateSprayerEffects)
	SpecializationUtil.registerFunction(vehicleType, "getSprayerUsage", Sprayer.getSprayerUsage)
	SpecializationUtil.registerFunction(vehicleType, "getUseSprayerAIRequirements", Sprayer.getUseSprayerAIRequirements)
	SpecializationUtil.registerFunction(vehicleType, "setSprayerAITerrainDetailProhibitedRange", Sprayer.setSprayerAITerrainDetailProhibitedRange)
	SpecializationUtil.registerFunction(vehicleType, "getSprayerFillUnitIndex", Sprayer.getSprayerFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "loadSprayTypeFromXML", Sprayer.loadSprayTypeFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getActiveSprayType", Sprayer.getActiveSprayType)
	SpecializationUtil.registerFunction(vehicleType, "getIsSprayTypeActive", Sprayer.getIsSprayTypeActive)
	SpecializationUtil.registerFunction(vehicleType, "setSprayerDoubledAmountActive", Sprayer.setSprayerDoubledAmountActive)
	SpecializationUtil.registerFunction(vehicleType, "getSprayerDoubledAmountActive", Sprayer.getSprayerDoubledAmountActive)
end

function Sprayer.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIMarkers", Sprayer.getAIMarkers)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAISizeMarkers", Sprayer.getAISizeMarkers)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIImplementCollisionTrigger", Sprayer.getAIImplementCollisionTrigger)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", Sprayer.getDrawFirstFillText)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", Sprayer.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", Sprayer.getCanToggleTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Sprayer.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Sprayer.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Sprayer.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Sprayer.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getRawSpeedLimit", Sprayer.getRawSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillVolumeUVScrollSpeed", Sprayer.getFillVolumeUVScrollSpeed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIRequiresTurnOffOnHeadland", Sprayer.getAIRequiresTurnOffOnHeadland)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Sprayer.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Sprayer.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getEffectByNode", Sprayer.getEffectByNode)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getVariableWorkWidthUsage", Sprayer.getVariableWorkWidthUsage)
end

function Sprayer.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onSetLowered", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onSprayTypeChange", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementEnd", Sprayer)
	SpecializationUtil.registerEventListener(vehicleType, "onVariableWorkWidthSectionChanged", Sprayer)
end

function Sprayer:onLoad(savegame)
	local spec = self.spec_sprayer

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sprayParticles.emitterShape", "vehicle.sprayer.effects.effectNode#effectClass='ParticleEffect'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sprayer#needsTankActivation")

	spec.allowsSpraying = self.xmlFile:getValue("vehicle.sprayer#allowsSpraying", true)
	spec.activateTankOnLowering = self.xmlFile:getValue("vehicle.sprayer#activateTankOnLowering", false)
	spec.activateOnLowering = self.xmlFile:getValue("vehicle.sprayer#activateOnLowering", false)
	spec.usageScale = {
		default = self.xmlFile:getValue("vehicle.sprayer.usageScales#scale", 1),
		workingWidth = self.xmlFile:getValue("vehicle.sprayer.usageScales#workingWidth", 12),
		workAreaIndex = self.xmlFile:getValue("vehicle.sprayer.usageScales#workAreaIndex"),
		fillTypeScales = {}
	}
	local i = 0

	while true do
		local key = string.format("vehicle.sprayer.usageScales.sprayUsageScale(%d)", i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local fillTypeStr = self.xmlFile:getValue(key .. "#fillType")
		local scale = self.xmlFile:getValue(key .. "#scale")

		if fillTypeStr ~= nil and scale ~= nil then
			local fillTypeIndex = g_fillTypeManager:getFillTypeIndexByName(fillTypeStr)

			if fillTypeIndex ~= nil then
				spec.usageScale.fillTypeScales[fillTypeIndex] = scale
			else
				print("Warning: Invalid spray usage scale fill type '" .. fillTypeStr .. "' in '" .. self.configFileName .. "'")
			end
		end

		i = i + 1
	end

	spec.sprayTypes = {}
	i = 0

	while true do
		local key = string.format("vehicle.sprayer.sprayTypes.sprayType(%d)", i)

		if not self.xmlFile:hasProperty(key) then
			break
		end

		local sprayType = {}

		if self:loadSprayTypeFromXML(self.xmlFile, key, sprayType) then
			table.insert(spec.sprayTypes, sprayType)

			sprayType.index = #spec.sprayTypes
		end

		i = i + 1
	end

	spec.lastActiveSprayType = nil

	if self.isClient then
		spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.sprayer.effects", self.components, self, self.i3dMappings)
		spec.animationName = self.xmlFile:getValue("vehicle.sprayer.animation#name", "")
		spec.samples = {
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.sprayer.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			spray = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.sprayer.sounds", "spray", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.sampleFillEnabled = false
		spec.sampleFillStopTime = -1
		spec.lastFillLevel = -1
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.sprayer.animationNodes", self.components, self, self.i3dMappings)
	end

	if self.addAIGroundTypeRequirements ~= nil then
		self:addAIGroundTypeRequirements(Sprayer.AI_REQUIRED_GROUND_TYPES)
	end

	spec.supportedSprayTypes = {}
	spec.fillUnitIndex = self.xmlFile:getValue("vehicle.sprayer#fillUnitIndex", 1)
	spec.unloadInfoIndex = self.xmlFile:getValue("vehicle.sprayer#unloadInfoIndex", 1)
	spec.fillVolumeIndex = self.xmlFile:getValue("vehicle.sprayer#fillVolumeIndex")
	spec.dischargeUVScrollSpeed = self.xmlFile:getValue("vehicle.sprayer#fillVolumeDischargeScrollSpeed", "0 0 0", true)

	if self:getFillUnitByIndex(spec.fillUnitIndex) == nil then
		Logging.xmlError(self.xmlFile, "FillUnit '%d' not defined!", spec.fillUnitIndex)
		self:setLoadingState(VehicleLoadingUtil.VEHICLE_LOAD_ERROR)

		return
	end

	local decreasedSpeedLimit = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#decreasedSpeed")

	if decreasedSpeedLimit == nil then
		local decreaseFactor = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#decreaseFactor", 0.5)
		decreasedSpeedLimit = self:getSpeedLimit() * decreaseFactor
	end

	spec.doubledAmountSpeed = decreasedSpeedLimit
	spec.doubledAmountIsActive = false
	local toggleButtonStr = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#toggleButton")

	if toggleButtonStr ~= nil then
		spec.toggleDoubledAmountInputBinding = InputAction[toggleButtonStr]
	end

	spec.toggleDoubledAmountInputBinding = spec.toggleDoubledAmountInputBinding or InputAction.DOUBLED_SPRAY_AMOUNT
	spec.doubledAmountDeactivateText = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#deactivateText", "action_deactivateDoubledSprayAmount", self.customEnvironment)
	spec.doubledAmountActivateText = self.xmlFile:getValue("vehicle.sprayer.doubledAmount#activateText", "action_activateDoubledSprayAmount", self.customEnvironment)
	spec.turnedAnimation = self.xmlFile:getValue("vehicle.sprayer.turnedAnimation#name", "")
	spec.turnedAnimationTurnOnSpeedScale = self.xmlFile:getValue("vehicle.sprayer.turnedAnimation#turnOnSpeedScale", 1)
	spec.turnedAnimationTurnOffSpeedScale = self.xmlFile:getValue("vehicle.sprayer.turnedAnimation#turnOffSpeedScale", -spec.turnedAnimationTurnOnSpeedScale)
	spec.turnedAnimationExternalFill = self.xmlFile:getValue("vehicle.sprayer.turnedAnimation#externalFill", true)
	spec.needsToBeFilledToTurnOn = true
	spec.useSpeedLimit = true
	spec.isWorking = false
	spec.lastEffectsState = false
	spec.isSlurryTanker = self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.LIQUIDMANURE) or self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.DIGESTATE)
	spec.isManureSpreader = self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.MANURE)
	spec.isFertilizerSprayer = not spec.isSlurryTanker and not spec.isManureSpreader
	spec.workAreaParameters = {
		sprayVehicle = nil,
		sprayVehicleFillUnitIndex = nil,
		lastChangedArea = 0,
		lastTotalArea = 0,
		lastIsExternallyFilled = false,
		lastSprayTime = -math.huge,
		usage = 0,
		usagePerMin = 0
	}
end

function Sprayer:onDelete()
	local spec = self.spec_sprayer

	g_effectManager:deleteEffects(spec.effects)
	g_soundManager:deleteSamples(spec.samples)
	g_animationManager:deleteAnimations(spec.animationNodes)

	if spec.sprayTypes ~= nil then
		for _, sprayType in ipairs(spec.sprayTypes) do
			g_effectManager:deleteEffects(sprayType.effects)
			g_soundManager:deleteSamples(sprayType.samples)
			g_animationManager:deleteAnimations(sprayType.animationNodes)
		end
	end
end

function Sprayer:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local activeSprayType = self:getActiveSprayType()

	if activeSprayType ~= nil then
		local spec = self.spec_sprayer

		if activeSprayType ~= spec.lastActiveSprayType then
			for _, sprayType in ipairs(spec.sprayTypes) do
				if sprayType == spec.lastActiveSprayType then
					g_effectManager:stopEffects(sprayType.effects)
					g_animationManager:stopAnimations(sprayType.animationNodes)
				end
			end

			SpecializationUtil.raiseEvent(self, "onSprayTypeChange", activeSprayType)

			spec.lastActiveSprayType = activeSprayType

			self:updateSprayerEffects(true)
		end
	end

	if self.isClient then
		local spec = self.spec_sprayer
		local actionEvent = spec.actionEvents[spec.toggleDoubledAmountInputBinding]

		if actionEvent ~= nil then
			local text = nil

			if spec.doubledAmountIsActive then
				text = spec.doubledAmountDeactivateText
			else
				text = spec.doubledAmountActivateText
			end

			g_inputBinding:setActionEventText(actionEvent.actionEventId, text)

			local _, isAllowed = self:getSprayerDoubledAmountActive(spec.workAreaParameters.sprayType)

			g_inputBinding:setActionEventActive(actionEvent.actionEventId, isAllowed)
		end
	end

	if self.isServer then
		local spec = self.spec_sprayer

		if spec.pendingActivationAfterLowering and self:getCanBeTurnedOn() then
			self:setIsTurnedOn(true)

			spec.pendingActivationAfterLowering = false
		end
	end
end

function Sprayer:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_sprayer

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.toggleDoubledAmountInputBinding, self, Sprayer.actionEventDoubledAmount, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
		end
	end
end

function Sprayer:actionEventDoubledAmount(actionName, inputValue, callbackState, isAnalog)
	self:setSprayerDoubledAmountActive(not self.spec_sprayer.doubledAmountIsActive)
end

function Sprayer:processSprayerArea(workArea, dt)
	local spec = self.spec_sprayer

	if self:getIsAIActive() and self.isServer and (spec.workAreaParameters.sprayFillType == nil or spec.workAreaParameters.sprayFillType == FillType.UNKNOWN) then
		local rootVehicle = self.rootVehicle

		rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())

		return 0, 0
	end

	if spec.workAreaParameters.sprayFillLevel <= 0 then
		return 0, 0
	end

	local sx, _, sz = getWorldTranslation(workArea.start)
	local wx, _, wz = getWorldTranslation(workArea.width)
	local hx, _, hz = getWorldTranslation(workArea.height)
	local sprayAmount = self:getSprayerDoubledAmountActive(spec.workAreaParameters.sprayType) and 2 or 1
	local changedArea, totalArea = FSDensityMapUtil.updateSprayArea(sx, sz, wx, wz, hx, hz, spec.workAreaParameters.sprayType, sprayAmount)
	spec.workAreaParameters.isActive = true
	spec.workAreaParameters.lastChangedArea = spec.workAreaParameters.lastChangedArea + changedArea
	spec.workAreaParameters.lastStatsArea = spec.workAreaParameters.lastStatsArea + changedArea
	spec.workAreaParameters.lastTotalArea = spec.workAreaParameters.lastTotalArea + totalArea
	spec.workAreaParameters.lastSprayTime = g_time

	if self:getLastSpeed() > 1 then
		spec.isWorking = true
	end

	return changedArea, totalArea
end

function Sprayer:getIsSprayerExternallyFilled()
	if self:getIsAIActive() then
		local sprayCapacity = self:getFillUnitCapacity(self:getSprayerFillUnitIndex())

		if sprayCapacity == 0 then
			local spec = self.spec_sprayer
			local hasSource = false

			for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
				if #spec.fillTypeSources[supportedSprayType] > 0 then
					hasSource = true

					break
				end
			end

			if not hasSource then
				return false
			end
		end

		local spec = self.spec_sprayer

		return spec.isSlurryTanker and g_currentMission.missionInfo.helperSlurrySource > 1 or spec.isManureSpreader and g_currentMission.missionInfo.helperManureSource > 1 or spec.isFertilizerSprayer and g_currentMission.missionInfo.helperBuyFertilizer
	end

	return false
end

function Sprayer:getExternalFill(fillType, dt)
	local found = false
	local isUnknownFillType = fillType == FillType.UNKNOWN
	local allowLiquidManure = self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.LIQUIDMANURE)
	local allowDigestate = self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.DIGESTATE)
	local allowManure = self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.MANURE)
	local allowLiquidFertilizer = self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.LIQUIDFERTILIZER)
	local allowFertilizer = self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.FERTILIZER)
	local allowsLiquidManureDigistate = allowLiquidManure or allowDigestate
	local usage = 0
	local farmId = self:getActiveFarm()
	local stats = g_currentMission:farmStats(self:getLastTouchedFarmlandFarmId())

	if fillType == FillType.LIQUIDMANURE or fillType == FillType.DIGESTATE or isUnknownFillType and allowsLiquidManureDigistate then
		if g_currentMission.missionInfo.helperSlurrySource == 2 then
			found = true

			if g_currentMission.economyManager:getCostPerLiter(FillType.LIQUIDMANURE, false) then
				fillType = FillType.LIQUIDMANURE
			else
				fillType = FillType.DIGESTATE
			end

			usage = self:getSprayerUsage(fillType, dt)

			if self.isServer then
				local price = usage * g_currentMission.economyManager:getCostPerLiter(fillType, false) * 1.5

				stats:updateStats("expenses", price)
				g_currentMission:addMoney(-price, farmId, MoneyType.PURCHASE_FERTILIZER)
			end
		elseif g_currentMission.missionInfo.helperSlurrySource > 2 then
			local loadingStation = g_currentMission.liquidManureLoadingStations[g_currentMission.missionInfo.helperSlurrySource - 2]

			if self.isServer and loadingStation ~= nil then
				usage = self:getSprayerUsage(FillType.LIQUIDMANURE, dt)
				local used = loadingStation:removeFillLevel(FillType.LIQUIDMANURE, usage, farmId or self:getOwnerFarmId())

				if math.abs(used - usage) > 1 then
					found = true
					fillType = FillType.LIQUIDMANURE
				else
					used = loadingStation:removeFillLevel(FillType.DIGESTATE, usage, farmId or self:getOwnerFarmId())

					if math.abs(used - usage) > 0.1 then
						found = true
						fillType = FillType.DIGESTATE
					end
				end
			end
		end
	elseif fillType == FillType.MANURE or fillType == FillType.UNKNOWN and allowManure then
		if g_currentMission.missionInfo.helperManureSource == 2 then
			found = true
			fillType = FillType.MANURE
			usage = self:getSprayerUsage(fillType, dt)

			if self.isServer then
				local price = usage * g_currentMission.economyManager:getCostPerLiter(fillType, false) * 1.5

				stats:updateStats("expenses", price)
				g_currentMission:addMoney(-price, farmId, MoneyType.PURCHASE_FERTILIZER)
			end
		elseif g_currentMission.missionInfo.helperManureSource > 2 then
			local loadingStation = g_currentMission.manureLoadingStations[g_currentMission.missionInfo.helperManureSource - 2]

			if self.isServer and loadingStation ~= nil then
				usage = self:getSprayerUsage(FillType.MANURE, dt)
				local used = loadingStation:removeFillLevel(FillType.MANURE, usage, farmId or self:getOwnerFarmId())

				if math.abs(used - usage) > 0.1 then
					found = true
					fillType = FillType.MANURE
				end
			end
		end
	elseif (fillType == FillType.FERTILIZER or fillType == FillType.LIQUIDFERTILIZER or fillType == FillType.HERBICIDE or fillType == FillType.LIME or fillType == FillType.UNKNOWN and (allowLiquidFertilizer or allowFertilizer)) and g_currentMission.missionInfo.helperBuyFertilizer then
		found = true

		if fillType == FillType.UNKNOWN then
			if self:getFillUnitAllowsFillType(self:getSprayerFillUnitIndex(), FillType.LIQUIDFERTILIZER) then
				fillType = FillType.LIQUIDFERTILIZER
			else
				fillType = FillType.FERTILIZER
			end
		end

		usage = self:getSprayerUsage(fillType, dt)

		if self.isServer then
			local price = usage * g_currentMission.economyManager:getCostPerLiter(fillType, false) * 1.5

			stats:updateStats("expenses", price)
			g_currentMission:addMoney(-price, farmId, MoneyType.PURCHASE_FERTILIZER)
		end
	end

	if found then
		return fillType, usage
	end

	return FillType.UNKNOWN, 0
end

function Sprayer:getAreEffectsVisible()
	return g_time < self.spec_sprayer.workAreaParameters.lastSprayTime + 100
end

function Sprayer:updateSprayerEffects(force)
	local spec = self.spec_sprayer
	local effectsState = self:getAreEffectsVisible()

	if effectsState ~= spec.lastEffectsState or force then
		if effectsState then
			local fillType = self:getFillUnitLastValidFillType(self:getSprayerFillUnitIndex())

			if fillType == FillType.UNKNOWN then
				fillType = self:getFillUnitFirstSupportedFillType(self:getSprayerFillUnitIndex())
			end

			g_effectManager:setFillType(spec.effects, fillType)
			g_effectManager:startEffects(spec.effects)
			g_soundManager:playSample(spec.samples.spray)

			local sprayType = self:getActiveSprayType()

			if sprayType ~= nil then
				g_effectManager:setFillType(sprayType.effects, fillType)
				g_effectManager:startEffects(sprayType.effects)
				g_animationManager:startAnimations(sprayType.animationNodes)
				g_soundManager:playSample(sprayType.samples.spray)
			end

			g_animationManager:startAnimations(spec.animationNodes)
		else
			g_effectManager:stopEffects(spec.effects)
			g_animationManager:stopAnimations(spec.animationNodes)
			g_soundManager:stopSample(spec.samples.spray)

			for _, sprayType in ipairs(spec.sprayTypes) do
				g_effectManager:stopEffects(sprayType.effects)
				g_animationManager:stopAnimations(sprayType.animationNodes)
				g_soundManager:stopSample(sprayType.samples.spray)
			end
		end

		spec.lastEffectsState = effectsState
	end
end

function Sprayer:getSprayerUsage(fillType, dt)
	if fillType == FillType.UNKNOWN then
		return 0
	end

	local spec = self.spec_sprayer
	local scale = Utils.getNoNil(spec.usageScale.fillTypeScales[fillType], spec.usageScale.default)
	local litersPerSecond = 1
	local sprayType = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)

	if sprayType ~= nil then
		litersPerSecond = sprayType.litersPerSecond
	end

	local usageScale = spec.usageScale
	local activeSprayType = self:getActiveSprayType()

	if activeSprayType ~= nil then
		usageScale = activeSprayType.usageScale
	end

	local workWidth = nil

	if usageScale.workAreaIndex ~= nil then
		workWidth = self:getWorkAreaWidth(usageScale.workAreaIndex)
	else
		workWidth = usageScale.workingWidth
	end

	return scale * litersPerSecond * self.speedLimit * workWidth * dt * 0.001
end

function Sprayer:getUseSprayerAIRequirements()
	return true
end

function Sprayer:setSprayerAITerrainDetailProhibitedRange(fillType)
	if self:getUseSprayerAIRequirements() and self.addAITerrainDetailProhibitedRange ~= nil then
		self:clearAITerrainDetailProhibitedRange()
		self:clearAIFruitRequirements()
		self:clearAIFruitProhibitions()
		self:addAIGroundTypeRequirements(Sprayer.AI_REQUIRED_GROUND_TYPES)

		local sprayTypeDesc = g_sprayTypeManager:getSprayTypeByFillTypeIndex(fillType)

		if sprayTypeDesc ~= nil then
			if sprayTypeDesc.isHerbicide then
				local weedSystem = g_currentMission.weedSystem

				if weedSystem ~= nil then
					local weedMapId, weedFirstChannel, weedNumChannels = weedSystem:getDensityMapData()
					local replacementData = weedSystem:getHerbicideReplacements()

					if replacementData.weed ~= nil then
						local startState = -1
						local lastState = -1

						for sourceState, targetState in pairs(replacementData.weed.replacements) do
							if startState == -1 then
								startState = sourceState
							elseif sourceState ~= lastState + 1 then
								self:addAIFruitRequirement(nil, startState, lastState, weedMapId, weedFirstChannel, weedNumChannels)

								startState = sourceState
							end

							lastState = sourceState
						end

						if startState ~= -1 then
							self:addAIFruitRequirement(nil, startState, lastState, weedMapId, weedFirstChannel, weedNumChannels)
						end
					end
				end
			else
				local mission = g_currentMission
				local sprayTypeMapId, sprayTypeFirstChannel, sprayTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_TYPE)
				local sprayLevelMapId, sprayLevelFirstChannel, sprayLevelNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.SPRAY_LEVEL)
				local sprayLevelMaxValue = mission.fieldGroundSystem:getMaxValue(FieldDensityMap.SPRAY_LEVEL)

				self:addAITerrainDetailProhibitedRange(sprayTypeDesc.sprayGroundType, sprayTypeDesc.sprayGroundType, sprayTypeFirstChannel, sprayTypeNumChannels)
			end

			if sprayTypeDesc.isHerbicide or sprayTypeDesc.isFertilizer then
				for _, fruitType in pairs(g_fruitTypeManager:getFruitTypes()) do
					if fruitType.terrainDataPlaneId ~= nil and fruitType.name:lower() ~= "grass" and fruitType.minHarvestingGrowthState ~= nil and fruitType.maxHarvestingGrowthState ~= nil then
						self:addAIFruitProhibitions(fruitType.index, fruitType.minHarvestingGrowthState, fruitType.maxHarvestingGrowthState)
					end
				end
			end
		end
	end
end

function Sprayer:getSprayerFillUnitIndex()
	local sprayType = self:getActiveSprayType()

	if sprayType ~= nil then
		return sprayType.fillUnitIndex
	end

	return self.spec_sprayer.fillUnitIndex
end

function Sprayer:loadSprayTypeFromXML(xmlFile, key, sprayType)
	sprayType.fillUnitIndex = xmlFile:getValue(key .. "#fillUnitIndex", 1)
	sprayType.unloadInfoIndex = xmlFile:getValue(key .. "#unloadInfoIndex", 1)
	sprayType.fillVolumeIndex = xmlFile:getValue(key .. "#fillVolumeIndex")
	sprayType.samples = {
		work = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
		spray = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "spray", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	}
	sprayType.effects = g_effectManager:loadEffect(xmlFile, key .. ".effects", self.components, self, self.i3dMappings)
	sprayType.animationNodes = g_animationManager:loadAnimations(xmlFile, key .. ".animationNodes", self.components, self, self.i3dMappings)
	sprayType.turnedAnimation = self.xmlFile:getValue(key .. ".turnedAnimation#name", "")
	sprayType.turnedAnimationTurnOnSpeedScale = self.xmlFile:getValue(key .. ".turnedAnimation#turnOnSpeedScale", 1)
	sprayType.turnedAnimationTurnOffSpeedScale = self.xmlFile:getValue(key .. ".turnedAnimation#turnOffSpeedScale", -sprayType.turnedAnimationTurnOnSpeedScale)
	sprayType.turnedAnimationExternalFill = self.xmlFile:getValue(key .. ".turnedAnimation#externalFill", true)
	sprayType.ai = {
		leftMarker = self.xmlFile:getValue(key .. ".ai.areaMarkers#leftNode", nil, self.components, self.i3dMappings),
		rightMarker = self.xmlFile:getValue(key .. ".ai.areaMarkers#rightNode", nil, self.components, self.i3dMappings),
		backMarker = self.xmlFile:getValue(key .. ".ai.areaMarkers#backNode", nil, self.components, self.i3dMappings),
		sizeLeftMarker = self.xmlFile:getValue(key .. ".ai.sizeMarkers#leftNode", nil, self.components, self.i3dMappings),
		sizeRightMarker = self.xmlFile:getValue(key .. ".ai.sizeMarkers#rightNode", nil, self.components, self.i3dMappings),
		sizeBackMarker = self.xmlFile:getValue(key .. ".ai.sizeMarkers#backNode", nil, self.components, self.i3dMappings)
	}

	if self.loadAICollisionTriggerFromXML ~= nil then
		sprayType.ai.collisionTrigger = self:loadAICollisionTriggerFromXML(self.xmlFile, key .. ".ai")
	end

	local fillTypesStr = xmlFile:getValue(key .. "#fillTypes")

	if fillTypesStr ~= nil then
		sprayType.fillTypes = fillTypesStr:split(" ")
	end

	sprayType.objectChanges = {}

	ObjectChangeUtil.loadObjectChangeFromXML(self.xmlFile, key, sprayType.objectChanges, self.components, self)
	ObjectChangeUtil.setObjectChanges(sprayType.objectChanges, false)

	sprayType.usageScale = {
		workingWidth = self.xmlFile:getValue(key .. ".usageScales#workingWidth", 12),
		workAreaIndex = self.xmlFile:getValue(key .. ".usageScales#workAreaIndex")
	}

	return true
end

function Sprayer:getActiveSprayType()
	local spec = self.spec_sprayer

	for _, sprayType in ipairs(spec.sprayTypes) do
		if self:getIsSprayTypeActive(sprayType) then
			return sprayType
		end
	end

	return nil
end

function Sprayer:getIsSprayTypeActive(sprayType)
	if sprayType.fillTypes ~= nil then
		local retValue = false
		local currentFillType = self:getFillUnitFillType(sprayType.fillUnitIndex or self.spec_sprayer.fillUnitIndex)

		for _, fillType in ipairs(sprayType.fillTypes) do
			if currentFillType == g_fillTypeManager:getFillTypeIndexByName(fillType) then
				retValue = true
			end
		end

		if not retValue then
			return false
		end
	end

	return true
end

function Sprayer:setSprayerDoubledAmountActive(isActive, noEventSend)
	local spec = self.spec_sprayer

	if isActive ~= spec.doubledAmountIsActive then
		spec.doubledAmountIsActive = isActive

		SprayerDoubledAmountEvent.sendEvent(self, isActive, noEventSend)
	end
end

function Sprayer:getSprayerDoubledAmountActive(sprayTypeIndex)
	local spec = self.spec_sprayer

	if not spec.isFertilizerSprayer then
		if sprayTypeIndex == nil then
			return spec.doubledAmountIsActive, true
		else
			local desc = g_sprayTypeManager:getSprayTypeByIndex(sprayTypeIndex)

			if desc ~= nil then
				if desc.isFertilizer then
					return spec.doubledAmountIsActive, true
				end
			else
				return spec.doubledAmountIsActive, true
			end
		end
	end

	return false, false
end

function Sprayer:getAIMarkers(superFunc)
	local spec = self.spec_aiImplement
	local sprayType = self:getActiveSprayType()

	if sprayType ~= nil and not spec.useAttributesOfAttachedImplement and sprayType.ai.rightMarker ~= nil then
		if spec.aiMarkersInverted then
			return sprayType.ai.rightMarker, sprayType.ai.leftMarker, sprayType.ai.backMarker, true
		else
			return sprayType.ai.leftMarker, sprayType.ai.rightMarker, sprayType.ai.backMarker, false
		end
	end

	return superFunc(self)
end

function Sprayer:getAISizeMarkers(superFunc)
	local sprayType = self:getActiveSprayType()

	if sprayType ~= nil and sprayType.ai.sizeLeftMarker ~= nil then
		return sprayType.ai.sizeLeftMarker, sprayType.ai.sizeRightMarker, sprayType.ai.sizeBackMarker
	end

	return superFunc(self)
end

function Sprayer:getAIImplementCollisionTrigger(superFunc)
	local sprayType = self:getActiveSprayType()

	if sprayType ~= nil and sprayType.ai.collisionTrigger ~= nil then
		return sprayType.ai.collisionTrigger
	end

	return superFunc(self)
end

function Sprayer:getDrawFirstFillText(superFunc)
	if self.isClient then
		local spec = self.spec_sprayer

		if spec.needsToBeFilledToTurnOn and self:getIsActiveForInput() and self:getIsSelected() and not self.isAlwaysTurnedOn and not self:getCanBeTurnedOn() and self:getFillUnitFillLevel(self:getSprayerFillUnitIndex()) <= 0 and self:getFillUnitCapacity(self:getSprayerFillUnitIndex()) > 0 then
			return true
		end
	end

	return superFunc(self)
end

function Sprayer:getAreControlledActionsAllowed(superFunc)
	local spec = self.spec_sprayer

	if spec.needsToBeFilledToTurnOn and self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 and self:getFillUnitCapacity(spec.fillUnitIndex) ~= 0 then
		return false, g_i18n:getText("info_firstFillTheTool")
	end

	return superFunc(self)
end

function Sprayer:getCanToggleTurnedOn(superFunc)
	if self.isClient then
		local spec = self.spec_sprayer

		if spec.needsToBeFilledToTurnOn and not self:getCanBeTurnedOn() and self:getFillUnitCapacity(self:getSprayerFillUnitIndex()) <= 0 then
			return false
		end
	end

	return superFunc(self)
end

function Sprayer:getCanBeTurnedOn(superFunc)
	local spec = self.spec_sprayer

	if not spec.allowsSpraying then
		return false
	end

	if self:getFillUnitFillLevel(self:getSprayerFillUnitIndex()) <= 0 and spec.needsToBeFilledToTurnOn and not self:getIsAIActive() then
		local sprayVehicle = nil

		for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
			for _, src in ipairs(spec.fillTypeSources[supportedSprayType]) do
				local vehicle = src.vehicle

				if vehicle:getFillUnitFillType(src.fillUnitIndex) == supportedSprayType and vehicle:getFillUnitFillLevel(src.fillUnitIndex) > 0 then
					sprayVehicle = vehicle

					break
				end
			end
		end

		if sprayVehicle == nil then
			return false
		end
	end

	return superFunc(self)
end

function Sprayer:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)

	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.SPRAYER
	end

	workArea.sprayType = xmlFile:getValue(key .. "#sprayType")

	return retValue
end

function Sprayer:getIsWorkAreaActive(superFunc, workArea)
	if workArea.sprayType ~= nil then
		local sprayType = self:getActiveSprayType()

		if sprayType ~= nil and sprayType.index ~= workArea.sprayType then
			return false
		end
	end

	return superFunc(self, workArea)
end

function Sprayer:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsTurnedOn() and self.spec_sprayer.useSpeedLimit
end

function Sprayer:getRawSpeedLimit(superFunc)
	local spec = self.spec_sprayer
	local sprayType = nil

	if spec.workAreaParameters ~= nil then
		sprayType = spec.workAreaParameters.sprayType
	end

	if self:getSprayerDoubledAmountActive(sprayType) and self:getIsTurnedOn() then
		return spec.doubledAmountSpeed
	end

	return superFunc(self)
end

function Sprayer:getFillVolumeUVScrollSpeed(superFunc, fillVolumeIndex)
	local spec = self.spec_sprayer
	local sprayerFillVolumeIndex = spec.fillVolumeIndex
	local sprayType = self:getActiveSprayType()

	if sprayType ~= nil then
		sprayerFillVolumeIndex = sprayType.fillVolumeIndex or sprayerFillVolumeIndex
	end

	if fillVolumeIndex == sprayerFillVolumeIndex and self:getIsTurnedOn() and not self:getIsSprayerExternallyFilled() then
		return spec.dischargeUVScrollSpeed[1], spec.dischargeUVScrollSpeed[2], spec.dischargeUVScrollSpeed[3]
	end

	return superFunc(self, fillVolumeIndex)
end

function Sprayer:getAIRequiresTurnOffOnHeadland(superFunc)
	return true
end

function Sprayer:getDirtMultiplier(superFunc)
	local spec = self.spec_sprayer

	if spec.isWorking then
		return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return superFunc(self)
end

function Sprayer:getWearMultiplier(superFunc)
	local spec = self.spec_sprayer

	if spec.isWorking then
		return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return superFunc(self)
end

function Sprayer:getEffectByNode(superFunc, node)
	local spec = self.spec_sprayer

	for i = 1, #spec.effects do
		local effect = spec.effects[i]

		if node == effect.node then
			return effect
		end
	end

	for i = 1, #spec.sprayTypes do
		local sprayType = spec.sprayTypes[i]

		for j = 1, #sprayType.effects do
			local effect = sprayType.effects[j]

			if node == effect.node then
				return effect
			end
		end
	end

	return superFunc(self, node)
end

function Sprayer:getVariableWorkWidthUsage(superFunc)
	local usage = superFunc(self)

	if usage == nil then
		if self:getIsTurnedOn() then
			return self.spec_sprayer.workAreaParameters.usagePerMin
		end

		return 0
	end

	return usage
end

function Sprayer:onTurnedOn()
	local spec = self.spec_sprayer

	if self.isClient then
		self:updateSprayerEffects()

		if spec.animationName ~= "" and self.playAnimation ~= nil then
			self:playAnimation(spec.animationName, 1, self:getAnimationTime(spec.animationName), true)
		end

		g_soundManager:playSample(spec.samples.work)

		local sprayType = self:getActiveSprayType()

		if sprayType ~= nil then
			g_soundManager:playSample(sprayType.samples.work)

			if sprayType.turnedAnimationExternalFill or not self:getIsSprayerExternallyFilled() then
				self:playAnimation(sprayType.turnedAnimation, sprayType.turnedAnimationTurnOnSpeedScale, self:getAnimationTime(sprayType.turnedAnimation), true)
			end
		end

		if spec.turnedAnimationExternalFill or not self:getIsSprayerExternallyFilled() then
			self:playAnimation(spec.turnedAnimation, spec.turnedAnimationTurnOnSpeedScale, self:getAnimationTime(spec.turnedAnimation), true)
		end
	end
end

function Sprayer:onTurnedOff()
	local spec = self.spec_sprayer

	if self.isClient then
		self:updateSprayerEffects()

		if spec.animationName ~= "" and self.stopAnimation ~= nil then
			self:stopAnimation(spec.animationName, true)
		end

		g_soundManager:stopSample(spec.samples.work)

		for _, sprayType in ipairs(spec.sprayTypes) do
			g_soundManager:stopSample(sprayType.samples.work)
			self:playAnimation(sprayType.turnedAnimation, sprayType.turnedAnimationTurnOffSpeedScale, self:getAnimationTime(sprayType.turnedAnimation), true)
		end

		self:playAnimation(spec.turnedAnimation, spec.turnedAnimationTurnOffSpeedScale, self:getAnimationTime(spec.turnedAnimation), true)
	end
end

function Sprayer:onPreDetach(attacherVehicle, jointDescIndex)
	if attacherVehicle.setIsTurnedOn ~= nil and attacherVehicle:getIsTurnedOn() then
		attacherVehicle:setIsTurnedOn(false)
	end
end

function Sprayer:onStartWorkAreaProcessing(dt)
	local spec = self.spec_sprayer
	local sprayVehicle, sprayVehicleFillUnitIndex = nil
	local fillType = self:getFillUnitFillType(self:getSprayerFillUnitIndex())
	local usage = self:getSprayerUsage(fillType, dt)
	local sprayFillLevel = self:getFillUnitFillLevel(self:getSprayerFillUnitIndex())

	if sprayFillLevel > 0 then
		sprayVehicle = self
		sprayVehicleFillUnitIndex = self:getSprayerFillUnitIndex()
	else
		for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
			for _, src in ipairs(spec.fillTypeSources[supportedSprayType]) do
				local vehicle = src.vehicle

				if vehicle:getIsFillUnitActive(src.fillUnitIndex) then
					local vehicleFillType = vehicle:getFillUnitFillType(src.fillUnitIndex)
					local vehicleFillLevel = vehicle:getFillUnitFillLevel(src.fillUnitIndex)

					if vehicleFillLevel > 0 and vehicleFillType == supportedSprayType then
						sprayVehicle = vehicle
						sprayVehicleFillUnitIndex = src.fillUnitIndex
						fillType = sprayVehicle:getFillUnitFillType(sprayVehicleFillUnitIndex)
						usage = self:getSprayerUsage(fillType, dt)
						sprayFillLevel = vehicleFillLevel

						break
					end
				elseif self:getIsAIActive() and vehicle.setIsTurnedOn ~= nil and not vehicle:getIsTurnedOn() then
					vehicle:setIsTurnedOn(true)
				end
			end
		end
	end

	local isExternallyFilled = self:getIsSprayerExternallyFilled()

	if isExternallyFilled and self:getIsTurnedOn() then
		fillType, usage = self:getExternalFill(fillType, dt)
		sprayFillLevel = usage
		sprayVehicle, sprayVehicleFillUnitIndex = nil
	end

	if isExternallyFilled ~= spec.workAreaParameters.lastIsExternallyFilled then
		local sprayType = self:getActiveSprayType()

		if sprayType ~= nil then
			if isExternallyFilled then
				if not sprayType.turnedAnimationExternalFill and self:getIsAnimationPlaying(sprayType.turnedAnimation) then
					self:stopAnimation(sprayType.turnedAnimation)
				end
			elseif not self:getIsAnimationPlaying(sprayType.turnedAnimation) then
				self:playAnimation(sprayType.turnedAnimation, sprayType.turnedAnimationTurnOnSpeedScale, self:getAnimationTime(sprayType.turnedAnimation), true)
			end
		end

		if isExternallyFilled then
			if not spec.turnedAnimationExternalFill and self:getIsAnimationPlaying(spec.turnedAnimation) then
				self:stopAnimation(spec.turnedAnimation)
			end
		elseif not self:getIsAnimationPlaying(spec.turnedAnimation) then
			self:playAnimation(spec.turnedAnimation, spec.turnedAnimationTurnOnSpeedScale, self:getAnimationTime(spec.turnedAnimation), true)
		end

		spec.workAreaParameters.lastIsExternallyFilled = isExternallyFilled
	end

	if self.isServer and fillType ~= FillType.UNKNOWN and fillType ~= spec.workAreaParameters.sprayFillType then
		self:setSprayerAITerrainDetailProhibitedRange(fillType)
	end

	spec.workAreaParameters.sprayType = g_sprayTypeManager:getSprayTypeIndexByFillTypeIndex(fillType)
	spec.workAreaParameters.sprayFillType = fillType
	spec.workAreaParameters.sprayFillLevel = sprayFillLevel
	spec.workAreaParameters.usage = usage
	spec.workAreaParameters.usagePerMin = usage / dt * 1000 * 60
	spec.workAreaParameters.sprayVehicle = sprayVehicle
	spec.workAreaParameters.sprayVehicleFillUnitIndex = sprayVehicleFillUnitIndex
	spec.workAreaParameters.lastChangedArea = 0
	spec.workAreaParameters.lastTotalArea = 0
	spec.workAreaParameters.lastStatsArea = 0
	spec.workAreaParameters.isActive = false
	spec.isWorking = false
end

function Sprayer:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self.spec_sprayer

	if self.isServer and spec.workAreaParameters.isActive then
		local sprayVehicle = spec.workAreaParameters.sprayVehicle
		local usage = spec.workAreaParameters.usage

		if sprayVehicle ~= nil then
			local sprayVehicleFillUnitIndex = spec.workAreaParameters.sprayVehicleFillUnitIndex
			local sprayFillType = spec.workAreaParameters.sprayFillType
			local unloadInfoIndex = spec.unloadInfoIndex
			local sprayType = self:getActiveSprayType()

			if sprayType ~= nil then
				unloadInfoIndex = sprayType.unloadInfoIndex
			end

			local unloadInfo = self:getFillVolumeUnloadInfo(unloadInfoIndex)

			sprayVehicle:addFillUnitFillLevel(self:getOwnerFarmId(), sprayVehicleFillUnitIndex, -usage, sprayFillType, ToolType.UNDEFINED, unloadInfo)
		end

		local ha = MathUtil.areaToHa(spec.workAreaParameters.lastStatsArea, g_currentMission:getFruitPixelsToSqm())
		local stats = g_currentMission:farmStats(self:getLastTouchedFarmlandFarmId())

		stats:updateStats("sprayedHectares", ha)
		stats:updateStats("sprayedTime", dt / 60000)
		stats:updateStats("sprayUsage", usage)
		self:updateLastWorkedArea(spec.workAreaParameters.lastStatsArea)
	end

	self:updateSprayerEffects()
end

function Sprayer:onStateChange(state, data)
	if state == Vehicle.STATE_CHANGE_ATTACH or state == Vehicle.STATE_CHANGE_DETACH or Vehicle.STATE_CHANGE_FILLTYPE_CHANGE then
		local spec = self.spec_sprayer
		spec.fillTypeSources = {}
		local supportedFillTypes = self:getFillUnitSupportedFillTypes(self:getSprayerFillUnitIndex())
		spec.supportedSprayTypes = {}

		if supportedFillTypes ~= nil then
			for fillType, supported in pairs(supportedFillTypes) do
				if supported then
					spec.fillTypeSources[fillType] = {}

					table.insert(spec.supportedSprayTypes, fillType)
				end
			end
		end

		local root = self.rootVehicle

		FillUnit.addFillTypeSources(spec.fillTypeSources, root, self, spec.supportedSprayTypes)
	end
end

function Sprayer:onSetLowered(isLowered)
	local spec = self.spec_sprayer

	if self.isServer then
		if spec.activateOnLowering then
			if self:getCanBeTurnedOn() then
				self:setIsTurnedOn(isLowered)
			else
				spec.pendingActivationAfterLowering = true
			end
		end

		if not isLowered then
			spec.pendingActivationAfterLowering = false
		end
	end

	if spec.activateTankOnLowering then
		for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
			for _, src in ipairs(spec.fillTypeSources[supportedSprayType]) do
				local vehicle = src.vehicle

				if vehicle.getIsTurnedOn ~= nil then
					vehicle:setIsTurnedOn(isLowered, true)
				end
			end
		end
	end
end

function Sprayer:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillType, toolType, fillPositionData, appliedDelta)
	local fillLevel = self:getFillUnitFillLevel(fillUnitIndex)

	if fillLevel == 0 and self:getIsTurnedOn() and not self:getIsAIActive() then
		local spec = self.spec_sprayer
		local hasValidSource = false

		if spec.fillTypeSources[fillType] ~= nil then
			for _, src in ipairs(spec.fillTypeSources[fillType]) do
				local vehicle = src.vehicle

				if vehicle:getIsFillUnitActive(src.fillUnitIndex) then
					local vehicleFillType = vehicle:getFillUnitFillType(src.fillUnitIndex)
					local vehicleFillLevel = vehicle:getFillUnitFillLevel(src.fillUnitIndex)

					if vehicleFillLevel > 0 and vehicleFillType == fillType then
						hasValidSource = true
					end
				end
			end
		end

		if not hasValidSource then
			self:setIsTurnedOn(false)
		end
	end
end

function Sprayer:onSprayTypeChange(activeSprayType)
	local spec = self.spec_sprayer

	for _, sprayType in ipairs(spec.sprayTypes) do
		ObjectChangeUtil.setObjectChanges(sprayType.objectChanges, sprayType == activeSprayType)
	end
end

function Sprayer:onAIImplementEnd()
	local spec = self.spec_sprayer

	for _, supportedSprayType in ipairs(spec.supportedSprayTypes) do
		for _, src in ipairs(spec.fillTypeSources[supportedSprayType]) do
			local vehicle = src.vehicle

			if vehicle.getIsTurnedOn ~= nil and vehicle:getIsTurnedOn() then
				vehicle:setIsTurnedOn(false, true)
			end
		end
	end
end

function Sprayer:onVariableWorkWidthSectionChanged()
	self:updateSprayerEffects(true)
end

function Sprayer.getDefaultSpeedLimit()
	return 15
end
