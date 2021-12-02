source("dataS/scripts/vehicles/specializations/events/CombineStrawEnableEvent.lua")

Combine = {
	DAMAGED_YIELD_REDUCTION = 0.4,
	RAIN_YIELD_REDUCTION = 0.5,
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("combineChopper", false)
		g_workAreaTypeManager:addWorkAreaType("combineSwath", false)

		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("Combine")
		schema:register(XMLValueType.L10N_STRING, "vehicle.combine.warning#noCutter", "No cutter warning", "$l10n_warning_noCuttersAttached")
		schema:register(XMLValueType.FLOAT, "vehicle.combine#fillLevelBufferTime", "Fill level buffer time for forage harvesters", 2000)
		schema:register(XMLValueType.BOOL, "vehicle.combine#allowThreshingDuringRain", "Allow threshing during rain", false)
		schema:register(XMLValueType.INT, "vehicle.combine#fillUnitIndex", "Fill unit index", 1)
		schema:register(XMLValueType.INT, "vehicle.combine.buffer#fillUnitIndex", "Buffer fill unit index (This fill unit will be filled first until it's full. Will be emptied if stopped to harvest)")
		schema:register(XMLValueType.TIME, "vehicle.combine.buffer#unloadingTime", "Buffer unloading speed", 0)
		schema:register(XMLValueType.INT, "vehicle.combine#loadInfoIndex", "Load info index", 1)
		schema:register(XMLValueType.TIME, "vehicle.combine.buffer#loadingDelay", "Time until the crops from the cutter are added to the tank", 0)
		schema:register(XMLValueType.TIME, "vehicle.combine.buffer#unloadingDelay", "Time until the crops are not longer added to the tank after the cutting has been stopped", "same as #loadingDelay")
		schema:register(XMLValueType.BOOL, "vehicle.combine.swath#available", "Swath is available", false)
		schema:register(XMLValueType.BOOL, "vehicle.combine.swath#isDefaultActive", "Swath is default active", "true if available")
		schema:register(XMLValueType.INT, "vehicle.combine.swath#workAreaIndex", "Swath work area index")
		schema:register(XMLValueType.BOOL, "vehicle.combine.chopper#available", "Chopper is available", false)
		schema:register(XMLValueType.BOOL, "vehicle.combine.chopper#isPowered", "Vehicle needs to be powered to switch chopper", true)
		schema:register(XMLValueType.INT, "vehicle.combine.chopper#workAreaIndex", "Chopper work area index")
		schema:register(XMLValueType.STRING, "vehicle.combine.chopper#animName", "Chopper toggle animation name")
		schema:register(XMLValueType.FLOAT, "vehicle.combine.chopper#animSpeedScale", "Chopper toggle animation speed", 1)
		schema:register(XMLValueType.STRING, "vehicle.combine.ladder#animName", "Ladder animation name")
		schema:register(XMLValueType.FLOAT, "vehicle.combine.ladder#animSpeedScale", "Ladder animation speed scale", 1)
		schema:register(XMLValueType.FLOAT, "vehicle.combine.ladder#foldMinLimit", "Min. folding time to fold ladder", 0.99)
		schema:register(XMLValueType.FLOAT, "vehicle.combine.ladder#foldMaxLimit", "Max. folding time to fold ladder", 1)
		schema:register(XMLValueType.INT, "vehicle.combine.ladder#foldDirection", "Fold direction to unfold ladder", "signed animation speed")
		schema:register(XMLValueType.BOOL, "vehicle.combine.ladder#unfoldWhileCutterAttached", "Unfold ladder while a cutter is attached", false)
		schema:register(XMLValueType.TIME, "vehicle.combine#fillTimeThreshold", "After receiving no input for this threshold time we stop the fill effects", 0.5)
		schema:register(XMLValueType.FLOAT, "vehicle.combine.processing#toggleTime", "Time from crop cutting to dropping straw", 0)
		schema:register(XMLValueType.STRING, "vehicle.combine.threshingStartAnimation#name", "Threshing start animation")
		schema:register(XMLValueType.FLOAT, "vehicle.combine.threshingStartAnimation#speedScale", "Threshing start animation speed scale")
		schema:register(XMLValueType.BOOL, "vehicle.combine.threshingStartAnimation#initialIsStarted", "Threshing start animation is initial started")
		schema:register(XMLValueType.INT, "vehicle.combine.additives#fillUnitIndex", "Additives fill unit index")
		schema:register(XMLValueType.FLOAT, "vehicle.combine.additives#usage", "Usage per picked up liter", 2)
		schema:register(XMLValueType.STRING, "vehicle.combine.additives#fillTypes", "Fill types to apply additives", "CHAFF GRASS_WINDROW")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.combine.automaticTilt.automaticTiltNode(?)#node", "Automatic tilt node")
		schema:register(XMLValueType.ANGLE, "vehicle.combine.automaticTilt.automaticTiltNode(?)#minAngle", "Min. angle", -5)
		schema:register(XMLValueType.ANGLE, "vehicle.combine.automaticTilt.automaticTiltNode(?)#maxAngle", "Max. angle", 5)
		schema:register(XMLValueType.ANGLE, "vehicle.combine.automaticTilt.automaticTiltNode(?)#maxSpeed", "Max. angle change per second", 2)
		schema:register(XMLValueType.BOOL, "vehicle.combine.automaticTilt.automaticTiltNode(?)#updateAttacherJoint", "Update cutter attacher joint")
		schema:register(XMLValueType.STRING, "vehicle.combine.automaticTilt.automaticTiltNode(?)#dependentAnimation", "Animation that is updated depending on tilt state")
		schema:register(XMLValueType.FLOAT, "vehicle.combine.folding#fillLevelThresholdPct", "Max. fill level to be folded (percetange between 0 and 1)", 0.15)
		schema:register(XMLValueType.INT, "vehicle.combine.folding#direction", "Folding direction", 1)
		schema:register(XMLValueType.BOOL, "vehicle.combine.folding#allowWhileThreshing", "Allow folding while combine is threshing", false)
		EffectManager.registerEffectXMLPaths(schema, "vehicle.combine.chopperEffect")
		EffectManager.registerEffectXMLPaths(schema, "vehicle.combine.strawEffect")
		EffectManager.registerEffectXMLPaths(schema, "vehicle.combine.fillEffect")
		EffectManager.registerEffectXMLPaths(schema, "vehicle.combine.effect")
		AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.combine.animationNodes")
		AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.combine.chopperAnimationNodes")
		AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.combine.strawDropAnimationNodes")
		AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.combine.fillingAnimationNodes")
		schema:register(XMLValueType.FLOAT, "vehicle.combine.animationNodes#speedReverseFillLevel", "If fill level is above the animation nodes will be reversed (Percent 0-1)")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.combine.sounds", "start")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.combine.sounds", "stop")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.combine.sounds", "work")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.combine.sounds", "chopperStart")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.combine.sounds", "chopperStop")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.combine.sounds", "chopperWork")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.combine.sounds", "chopStraw")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.combine.sounds", "dropStraw")
		SoundManager.registerSampleXMLPaths(schema, "vehicle.combine.sounds", "fill")
		Dashboard.registerDashboardXMLPaths(schema, "vehicle.combine.dashboards", "workedHectars")
		schema:register(XMLValueType.BOOL, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#activeChopper", "Animation is active while chopper is active", true)
		schema:register(XMLValueType.BOOL, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#activeStrawDrop", "Animation is active while straw drop is active", true)
		schema:register(XMLValueType.BOOL, TurnOnVehicle.TURNED_ON_ANIMATION_XML_PATH .. "#waitForStraw", "Animation is active as long as straw is dropped", true)
		schema:setXMLSpecializationType()

		local schemaSavegame = Vehicle.xmlSchemaSavegame

		schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).combine#isSwathActive", "Swath is active")
		schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).combine#workedHectars", "Worked hectars")
		schemaSavegame:register(XMLValueType.INT, "vehicles.vehicle(?).combine#numAttachedCutters", "Number of last attached cutters")
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(FillUnit, specializations) and (SpecializationUtil.hasSpecialization(Drivable, specializations) or SpecializationUtil.hasSpecialization(Attachable, specializations)) and SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
	end,
	registerEvents = function (vehicleType)
		SpecializationUtil.registerEvent(vehicleType, "onStartThreshing")
		SpecializationUtil.registerEvent(vehicleType, "onStopThreshing")
	end
}

function Combine.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadCombineSetup", Combine.loadCombineSetup)
	SpecializationUtil.registerFunction(vehicleType, "loadCombineEffects", Combine.loadCombineEffects)
	SpecializationUtil.registerFunction(vehicleType, "loadCombineRotationNodes", Combine.loadCombineRotationNodes)
	SpecializationUtil.registerFunction(vehicleType, "loadCombineSamples", Combine.loadCombineSamples)
	SpecializationUtil.registerFunction(vehicleType, "setIsSwathActive", Combine.setIsSwathActive)
	SpecializationUtil.registerFunction(vehicleType, "processCombineChopperArea", Combine.processCombineChopperArea)
	SpecializationUtil.registerFunction(vehicleType, "processCombineSwathArea", Combine.processCombineSwathArea)
	SpecializationUtil.registerFunction(vehicleType, "setChopperPSEnabled", Combine.setChopperPSEnabled)
	SpecializationUtil.registerFunction(vehicleType, "setStrawPSEnabled", Combine.setStrawPSEnabled)
	SpecializationUtil.registerFunction(vehicleType, "setCombineIsFilling", Combine.setCombineIsFilling)
	SpecializationUtil.registerFunction(vehicleType, "startThreshing", Combine.startThreshing)
	SpecializationUtil.registerFunction(vehicleType, "stopThreshing", Combine.stopThreshing)
	SpecializationUtil.registerFunction(vehicleType, "setWorkedHectars", Combine.setWorkedHectars)
	SpecializationUtil.registerFunction(vehicleType, "addCutterToCombine", Combine.addCutterToCombine)
	SpecializationUtil.registerFunction(vehicleType, "removeCutterFromCombine", Combine.removeCutterFromCombine)
	SpecializationUtil.registerFunction(vehicleType, "addCutterArea", Combine.addCutterArea)
	SpecializationUtil.registerFunction(vehicleType, "getIsThreshingDuringRain", Combine.getIsThreshingDuringRain)
	SpecializationUtil.registerFunction(vehicleType, "verifyCombine", Combine.verifyCombine)
	SpecializationUtil.registerFunction(vehicleType, "getFillLevelDependentSpeed", Combine.getFillLevelDependentSpeed)
	SpecializationUtil.registerFunction(vehicleType, "getCombineLastValidFillType", Combine.getCombineLastValidFillType)
	SpecializationUtil.registerFunction(vehicleType, "getCombineLoadPercentage", Combine.getCombineLoadPercentage)
	SpecializationUtil.registerFunction(vehicleType, "getIsCutterCompatible", Combine.getIsCutterCompatible)
end

function Combine.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeTurnedOn", Combine.getCanBeTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getTurnedOnNotAllowedWarning", Combine.getTurnedOnNotAllowedWarning)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", Combine.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Combine.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Combine.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Combine.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Combine.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Combine.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadTurnedOnAnimationFromXML", Combine.loadTurnedOnAnimationFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsTurnedOnAnimationActive", Combine.getIsTurnedOnAnimationActive)
end

function Combine.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onDraw", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onChangedFillType", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttachImplement", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetachImplement", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onFoldStateChanged", Combine)
	SpecializationUtil.registerEventListener(vehicleType, "onFillUnitFillLevelChanged", Combine)
end

function Combine:onLoad(savegame)
	local spec = self.spec_combine

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.combine.chopperSwitch", "vehicle.combine.swath and vehicle.combine.chopper")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.combine.rotationNodes.rotationNode", "combine")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.indoorHud.workedHectars", "vehicle.combine.dashboards.dashboard with valueType 'workedHectars'")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.combine.folding#fillLevelThreshold", "vehicle.combine.folding#fillLevelThresholdPct")
	self:loadCombineSetup(self.xmlFile, "vehicle.combine", spec)
	self:loadCombineEffects(self.xmlFile, "vehicle.combine", spec)
	self:loadCombineRotationNodes(self.xmlFile, "vehicle.combine", spec)
	self:loadCombineSamples(self.xmlFile, "vehicle.combine", spec)

	spec.attachedCutters = {}
	spec.numAttachedCutters = 0
	spec.texts = {
		warningFoldingTurnedOn = g_i18n:getText("warning_foldingNotWhileTurnedOn"),
		warningFoldingWhileFilled = g_i18n:getText("warning_foldingNotWhileFilled"),
		warningRainReducesYield = g_i18n:getText("warning_rainReducesYield"),
		warningNoCutter = self.xmlFile:getValue("vehicle.combine.warning#noCutter", g_i18n:getText("warning_noCuttersAttached"), self.customEnvironment)
	}
	spec.threshingDuringRainWarningDisplayed = false
	spec.lastArea = 0
	spec.lastAreaZeroTime = 0
	spec.lastAreaNonZeroTime = -1000000
	spec.lastCuttersArea = 0
	spec.lastCuttersAreaTime = -10000
	spec.lastInputFruitType = FruitType.UNKNOWN
	spec.lastValidInputFruitType = FruitType.UNKNOWN
	spec.lastCuttersFruitType = FruitType.UNKNOWN
	spec.lastCuttersInputFruitType = FruitType.UNKNOWN
	spec.lastValidInputFillType = FillType.UNKNOWN
	spec.lastDischargeTime = 0
	spec.lastChargeTime = 0
	spec.fillLevelBufferTime = self.xmlFile:getValue("vehicle.combine#fillLevelBufferTime", 2000)
	spec.workedHectars = 0
	spec.workedHectarsSent = 0

	if self.loadDashboardsFromXML ~= nil then
		local dashboardData = {
			valueFunc = "workedHectars",
			valueTypeToLoad = "workedHectars",
			valueObject = spec
		}

		self:loadDashboardsFromXML(self.xmlFile, "vehicle.combine.dashboards", dashboardData)
	end

	spec.threshingScale = 1
	spec.lastLostFillLevel = 0
	spec.workAreaParameters = {
		lastRealArea = 0,
		lastArea = 0,
		litersToDrop = 0,
		droppedLiters = 0,
		isChopperEffectEnabled = 0,
		isStrawEffectEnabled = 0,
		effectDensity = 0.2,
		effectDensitySent = 0.2
	}
	spec.dirtyFlag = self:getNextDirtyFlag()
	spec.effectDirtyFlag = self:getNextDirtyFlag()
end

function Combine:onPostLoad(savegame)
	local spec = self.spec_combine

	if savegame ~= nil then
		if spec.swath.isAvailable then
			local isSwathActive = savegame.xmlFile:getValue(savegame.key .. ".combine#isSwathActive", spec.isSwathActive)

			self:setIsSwathActive(isSwathActive, true, true)
		end

		self:setWorkedHectars(savegame.xmlFile:getValue(savegame.key .. ".combine#workedHectars", spec.workedHectars))
	else
		self:setIsSwathActive(spec.isSwathActive, true, true)
	end

	spec.isBufferCombine = self:getFillUnitCapacity(self.spec_combine.fillUnitIndex) == math.huge
	local ladder = spec.ladder

	if ladder.animName ~= nil then
		local time = 0

		if self.getFoldAnimTime ~= nil then
			local foldAnimTime = self:getFoldAnimTime()

			if ladder.foldMaxLimit < foldAnimTime or foldAnimTime < ladder.foldMinLimit then
				time = 1
			end
		end

		if ladder.unfoldWhileCutterAttached and savegame ~= nil and not savegame.resetVehicles then
			local numAttachedCutters = savegame.xmlFile:getValue(savegame.key .. ".combine#numAttachedCutters", 0)

			if numAttachedCutters > 0 then
				time = 1
			end
		end

		if ladder.foldDirection ~= 1 then
			time = 1 - time
		end

		self:setAnimationTime(ladder.animName, time, true)
	end

	if spec.bufferFillUnitIndex ~= nil then
		local fillUnit = self:getFillUnitByIndex(spec.fillUnitIndex)
		local bufferUnit = self:getFillUnitByIndex(spec.bufferFillUnitIndex)

		if fillUnit ~= nil and bufferUnit ~= nil then
			bufferUnit.parentUnitOnHud = spec.fillUnitIndex
			fillUnit.childUnitOnHud = spec.bufferFillUnitIndex
		end
	end

	if self:getFillUnitCapacity(spec.fillUnitIndex) == 0 then
		Logging.xmlWarning(self.xmlFile, "Capacity of fill unit '%d' for combine needs to be set greater 0 or not defined! (not defined = infinity)", spec.fillUnitIndex)
	end
end

function Combine:onDelete()
	local spec = self.spec_combine

	g_effectManager:deleteEffects(spec.effects)
	g_effectManager:deleteEffects(spec.fillEffects)
	g_effectManager:deleteEffects(spec.strawEffects)
	g_effectManager:deleteEffects(spec.chopperEffects)
	g_animationManager:deleteAnimations(spec.animationNodes)
	g_animationManager:deleteAnimations(spec.chopperAnimationNodes)
	g_animationManager:deleteAnimations(spec.strawDropAnimationNodes)
	g_animationManager:deleteAnimations(spec.fillingAnimationNodes)
	g_soundManager:deleteSamples(spec.samples)
end

function Combine:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_combine

	if spec.swath.isAvailable then
		xmlFile:setValue(key .. "#isSwathActive", spec.isSwathActive)
	end

	xmlFile:setValue(key .. "#workedHectars", spec.workedHectars)
	xmlFile:setValue(key .. "#numAttachedCutters", spec.numAttachedCutters)
end

function Combine:onReadStream(streamId, connection)
	local spec = self.spec_combine
	spec.lastValidInputFruitType = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
	local combineIsFilling = streamReadBool(streamId)
	local chopperPSenabled = streamReadBool(streamId)
	local strawPSenabled = streamReadBool(streamId)
	spec.lastValidInputFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

	self:setCombineIsFilling(combineIsFilling, false, true)
	self:setChopperPSEnabled(chopperPSenabled, false, 1, true)
	self:setStrawPSEnabled(strawPSenabled, false, 1, true)

	local isSwathActive = streamReadBool(streamId)

	self:setIsSwathActive(isSwathActive, true)

	local workedHectars = streamReadFloat32(streamId)

	self:setWorkedHectars(workedHectars)
end

function Combine:onWriteStream(streamId, connection)
	local spec = self.spec_combine

	streamWriteUIntN(streamId, spec.lastValidInputFruitType, FruitTypeManager.SEND_NUM_BITS)
	streamWriteBool(streamId, spec.isFilling)
	streamWriteBool(streamId, spec.chopperPSenabled)
	streamWriteBool(streamId, spec.strawPSenabled)
	streamWriteUIntN(streamId, self:getCombineLastValidFillType(), FillTypeManager.SEND_NUM_BITS)
	streamWriteBool(streamId, spec.isSwathActive)
	streamWriteFloat32(streamId, spec.workedHectars)
end

function Combine:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_combine

		if streamReadBool(streamId) then
			spec.lastValidInputFruitType = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)
			local workedHectars = streamReadFloat32(streamId)

			self:setWorkedHectars(workedHectars)
		end

		if streamReadBool(streamId) then
			local combineIsFilling = streamReadBool(streamId)
			local chopperPSenabled = streamReadBool(streamId)
			local strawPSenabled = streamReadBool(streamId)
			local effectDensity = streamReadUIntN(streamId, 5)
			effectDensity = effectDensity / 31
			spec.lastValidInputFillType = streamReadUIntN(streamId, FillTypeManager.SEND_NUM_BITS)

			self:setCombineIsFilling(combineIsFilling, false, true)
			self:setChopperPSEnabled(chopperPSenabled, false, effectDensity, true)
			self:setStrawPSEnabled(strawPSenabled, false, effectDensity, true)
		end
	end
end

function Combine:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_combine

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.dirtyFlag) ~= 0) then
			streamWriteUIntN(streamId, spec.lastValidInputFruitType, FruitTypeManager.SEND_NUM_BITS)
			streamWriteFloat32(streamId, spec.workedHectars)
		end

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.effectDirtyFlag) ~= 0) then
			streamWriteBool(streamId, spec.isFilling)
			streamWriteBool(streamId, spec.chopperPSenabled)
			streamWriteBool(streamId, spec.strawPSenabled)
			streamWriteUIntN(streamId, spec.workAreaParameters.effectDensity * 31, 5)
			streamWriteUIntN(streamId, self:getCombineLastValidFillType(), FillTypeManager.SEND_NUM_BITS)
		end
	end
end

function Combine:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_combine
	local isTurnedOn = self:getIsTurnedOn()

	if isTurnedOn and self.isServer and spec.swath.isAvailable then
		local fillUnitIndex = spec.bufferFillUnitIndex or spec.fillUnitIndex
		local fruitType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(self:getFillUnitFillType(fillUnitIndex))

		if spec.isSwathActive and fruitType ~= nil and fruitType ~= FruitType.UNKNOWN then
			local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

			if not fruitDesc.hasWindrow then
				self:setIsSwathActive(false)
			end
		elseif (not spec.chopper.isAvailable or spec.automatedChopperSwitch) and not spec.isSwathActive and fruitType ~= nil and fruitType ~= FruitType.UNKNOWN then
			local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

			if fruitDesc.hasWindrow then
				self:setIsSwathActive(true)

				local inputBuffer = spec.processing.inputBuffer

				for i = 1, #inputBuffer.buffer do
					inputBuffer.buffer[i].area = 0
					inputBuffer.buffer[i].realArea = 0
					inputBuffer.buffer[i].liters = 0
					inputBuffer.buffer[i].inputLiters = 0
				end
			end
		end
	end

	if self.isServer and self:getFillUnitFillLevel(spec.fillUnitIndex) < 0.0001 then
		spec.lastDischargeTime = g_time
	end

	if spec.automaticTilt.hasNodes then
		local currentDelta = 0
		local isActive = false
		local doReset = false
		local _, cutter = next(spec.attachedCutters)

		if cutter ~= nil and cutter:getCutterTiltIsAvailable() then
			currentDelta, isActive, doReset = cutter:getCutterTiltDelta()
		end

		for i = 1, #spec.automaticTilt.nodes do
			local automaticTiltNode = spec.automaticTilt.nodes[i]
			local _, _, curZ = getRotation(automaticTiltNode.node)

			if not isActive and doReset then
				currentDelta = -curZ * 0.1
			end

			if math.abs(currentDelta) > 1e-05 then
				local speedScale = math.min(math.pow(math.abs(currentDelta) / 0.01745, 2), 1) * MathUtil.sign(currentDelta)
				local rotSpeed = speedScale * automaticTiltNode.maxSpeed * dt
				local newRotZ = MathUtil.clamp(curZ + rotSpeed, automaticTiltNode.minAngle, automaticTiltNode.maxAngle)

				setRotation(automaticTiltNode.node, 0, 0, newRotZ)

				if automaticTiltNode.dependentAnimation ~= nil then
					local alpha = MathUtil.inverseLerp(automaticTiltNode.minAngle, automaticTiltNode.maxAngle, newRotZ)

					self:setAnimationTime(automaticTiltNode.dependentAnimation, alpha, true)
				end

				if cutter ~= nil and automaticTiltNode.updateAttacherJoint and math.abs(newRotZ - automaticTiltNode.lastJointUpdateRot) > 1e-05 then
					automaticTiltNode.lastJointUpdateRot = newRotZ
					local jointDesc = self:getAttacherJointDescFromObject(cutter)

					if jointDesc.jointIndex ~= 0 then
						setJointFrame(jointDesc.jointIndex, 0, jointDesc.jointTransform)
					end
				end

				if self.setMovingToolDirty ~= nil then
					self:setMovingToolDirty(automaticTiltNode.node)
				end
			end
		end
	end
end

function Combine:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_combine

	if self.isServer then
		spec.lastArea = spec.lastCuttersArea
		spec.lastAreaZeroTime = spec.lastAreaZeroTime + dt

		if spec.lastArea > 0 then
			spec.lastAreaZeroTime = 0
			spec.lastAreaNonZeroTime = g_currentMission.time
		end

		spec.lastInputFruitType = spec.lastCuttersInputFruitType
		spec.lastCuttersArea = 0
		spec.lastCuttersInputFruitType = FruitType.UNKNOWN
		spec.lastCuttersFruitType = FruitType.UNKNOWN

		if spec.lastInputFruitType ~= FruitType.UNKNOWN then
			spec.lastValidInputFruitType = spec.lastInputFruitType
		end

		local inputBuffer = spec.processing.inputBuffer

		if spec.fillTimeThreshold < spec.lastAreaZeroTime and spec.fillDisableTime == nil then
			spec.fillDisableTime = g_currentMission.time + spec.processing.toggleTime
		end

		if spec.fillEnableTime ~= nil and spec.fillEnableTime <= g_currentMission.time then
			self:setCombineIsFilling(true, false, false)

			spec.fillEnableTime = nil
		end

		if spec.fillDisableTime ~= nil and spec.fillDisableTime <= g_currentMission.time then
			self:setCombineIsFilling(false, false, false)

			spec.fillDisableTime = nil
		end

		spec.workAreaParameters.isChopperEffectEnabled = math.max(spec.workAreaParameters.isChopperEffectEnabled - dt, 0)
		spec.workAreaParameters.isStrawEffectEnabled = math.max(spec.workAreaParameters.isStrawEffectEnabled - dt, 0)
		local density = spec.workAreaParameters.effectDensity
		local chopperPSActive = spec.workAreaParameters.isChopperEffectEnabled > 0
		local strawPSActive = spec.workAreaParameters.isStrawEffectEnabled > 0

		self:setChopperPSEnabled(chopperPSActive, false, density, false)
		self:setStrawPSEnabled(strawPSActive, false, density, false)

		if chopperPSActive or strawPSActive then
			self:raiseActive()
		end

		if self:getIsTurnedOn() then
			local stats = g_currentMission:farmStats(self:getOwnerFarmId())

			stats:updateStats("threshedTime", dt / 60000)
			self:updateLastWorkedArea(0)
		end

		inputBuffer.slotTimer = inputBuffer.slotTimer - dt

		if inputBuffer.slotTimer < 0 then
			inputBuffer.slotTimer = inputBuffer.slotDuration
			inputBuffer.fillIndex = inputBuffer.fillIndex + 1

			if inputBuffer.slotCount < inputBuffer.fillIndex then
				inputBuffer.fillIndex = 1
			end

			local lastDropIndex = inputBuffer.dropIndex
			inputBuffer.dropIndex = inputBuffer.dropIndex + 1

			if inputBuffer.slotCount < inputBuffer.dropIndex then
				inputBuffer.dropIndex = 1
			end

			inputBuffer.buffer[inputBuffer.dropIndex].liters = inputBuffer.buffer[inputBuffer.dropIndex].liters + inputBuffer.buffer[lastDropIndex].liters
			inputBuffer.buffer[inputBuffer.dropIndex].inputLiters = inputBuffer.buffer[inputBuffer.dropIndex].inputLiters + inputBuffer.buffer[lastDropIndex].liters
			inputBuffer.buffer[lastDropIndex].area = 0
			inputBuffer.buffer[lastDropIndex].realArea = 0
			inputBuffer.buffer[lastDropIndex].liters = 0
			inputBuffer.buffer[lastDropIndex].inputLiters = 0
		end

		if spec.bufferFillUnitIndex ~= nil and spec.lastCuttersAreaTime + dt * 10 < g_currentMission.time and self:getFillUnitFillLevel(spec.bufferFillUnitIndex) > 0 then
			local deltaFillLevel = dt * self:getFillUnitCapacity(spec.bufferFillUnitIndex) / spec.bufferUnloadingTime
			deltaFillLevel = self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.bufferFillUnitIndex, -deltaFillLevel, self:getFillUnitFillType(spec.bufferFillUnitIndex), ToolType.UNDEFINED)

			self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -deltaFillLevel, self:getFillUnitFillType(spec.bufferFillUnitIndex), ToolType.UNDEFINED, self:getFillVolumeLoadInfo(spec.loadInfoIndex))
		end

		if spec.loadingDelay > 0 then
			for i = 1, #spec.loadingDelaySlots do
				local slot = spec.loadingDelaySlots[i]

				if slot.valid and slot.time + spec.loadingDelay < g_time then
					slot.valid = false

					self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, slot.fillLevelDelta, slot.fillType, ToolType.UNDEFINED, self:getFillVolumeLoadInfo(spec.loadInfoIndex))
				end
			end
		end

		if spec.isFilling ~= spec.sentIsFilling or spec.chopperPSenabled ~= spec.sentChopperPSenabled or spec.strawPSenabled ~= spec.sentStrawPSenabled or math.abs(spec.workAreaParameters.effectDensity - spec.workAreaParameters.effectDensitySent) > 0.05 then
			self:raiseDirtyFlags(spec.effectDirtyFlag)

			spec.sentIsFilling = spec.isFilling
			spec.sentChopperPSenabled = spec.chopperPSenabled
			spec.sentStrawPSenabled = spec.strawPSenabled
			spec.workAreaParameters.effectDensitySent = spec.workAreaParameters.effectDensity
		end
	end
end

function Combine:onDraw(isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_combine

	if self:getIsTurnedOn() and self:getIsThreshingDuringRain(false) then
		if not spec.threshingDuringRainWarningDisplayed then
			g_currentMission:showBlinkingWarning(spec.texts.warningRainReducesYield, 4000)

			spec.threshingDuringRainWarningDisplayed = true
		end
	else
		spec.threshingDuringRainWarningDisplayed = false
	end
end

function Combine:loadCombineSetup(xmlFile, baseKey, entry)
	entry.allowThreshingDuringRain = xmlFile:getValue(baseKey .. "#allowThreshingDuringRain", false)
	entry.fillUnitIndex = xmlFile:getValue(baseKey .. "#fillUnitIndex", 1)
	entry.bufferFillUnitIndex = xmlFile:getValue(baseKey .. ".buffer#fillUnitIndex")
	entry.bufferUnloadingTime = xmlFile:getValue(baseKey .. ".buffer#unloadingTime", 0)
	entry.loadInfoIndex = xmlFile:getValue(baseKey .. "#loadInfoIndex", 1)
	entry.loadingDelay = xmlFile:getValue(baseKey .. ".buffer#loadingDelay", 0)

	if entry.loadingDelay > 0 then
		entry.unloadingDelay = xmlFile:getValue(baseKey .. ".buffer#unloadingDelay", entry.loadingDelay / 1000)
		entry.loadingDelaySlotsDelayedInsert = false
		entry.loadingDelaySlots = {}

		for i = 1, entry.loadingDelay / 1000 * 60 + 1 do
			entry.loadingDelaySlots[i] = {
				valid = false,
				fillLevelDelta = 0,
				fillType = 0,
				time = -math.huge
			}
		end
	end

	entry.swath = {
		isAvailable = xmlFile:getValue(baseKey .. ".swath#available", false)
	}
	local isDefaultActive = xmlFile:getValue(baseKey .. ".swath#isDefaultActive", entry.swath.isAvailable)

	if entry.swath.isAvailable then
		entry.swath.workAreaIndex = xmlFile:getValue(baseKey .. ".swath#workAreaIndex")

		if entry.swath.workAreaIndex == nil then
			entry.swath.isAvailable = false

			Logging.xmlWarning(xmlFile, "Missing 'swath#workAreaIndex' for combine swath function!")
		end

		entry.warningTime = 0
	end

	entry.chopper = {
		isAvailable = xmlFile:getValue(baseKey .. ".chopper#available", false),
		isPowered = xmlFile:getValue(baseKey .. ".chopper#isPowered", true)
	}

	if entry.chopper.isAvailable then
		entry.chopper.workAreaIndex = xmlFile:getValue(baseKey .. ".chopper#workAreaIndex")

		if entry.chopper.workAreaIndex == nil then
			entry.chopper.isAvailable = false

			Logging.xmlWarning(xmlFile, "Missing 'chopper#workAreaIndex' for combine chopper function!")
		end

		entry.chopper.animName = xmlFile:getValue(baseKey .. ".chopper#animName")
		entry.chopper.animSpeedScale = xmlFile:getValue(baseKey .. ".chopper#animSpeedScale", 1)
	end

	entry.automatedChopperSwitch = GS_IS_MOBILE_VERSION
	entry.isSwathActive = isDefaultActive
	entry.ladder = {
		animName = xmlFile:getValue(baseKey .. ".ladder#animName"),
		animSpeedScale = xmlFile:getValue(baseKey .. ".ladder#animSpeedScale", 1),
		foldMinLimit = xmlFile:getValue(baseKey .. ".ladder#foldMinLimit", 0.99),
		foldMaxLimit = xmlFile:getValue(baseKey .. ".ladder#foldMaxLimit", 1)
	}
	entry.ladder.foldDirection = xmlFile:getValue(baseKey .. ".ladder#foldDirection", MathUtil.sign(entry.ladder.animSpeedScale))
	entry.ladder.unfoldWhileCutterAttached = xmlFile:getValue(baseKey .. ".ladder#unfoldWhileCutterAttached", false)
	entry.fillTimeThreshold = xmlFile:getValue(baseKey .. "#fillTimeThreshold", 0.5)
	entry.processing = {}
	local toggleTime = xmlFile:getValue(baseKey .. ".processing#toggleTime")

	if toggleTime == nil and entry.chopper.animName ~= nil then
		toggleTime = self:getAnimationDurection(entry.chopper.animName)

		if toggleTime ~= nil then
			toggleTime = toggleTime / 1000
		end
	end

	entry.processing.toggleTime = Utils.getNoNil(toggleTime, 0) * 1000
	local inputBuffer = {}
	local slotDuration = 300
	local slotCount = MathUtil.clamp(math.ceil(entry.processing.toggleTime / slotDuration), 2, 20)
	inputBuffer.slotCount = slotCount
	inputBuffer.slotDuration = math.ceil(entry.processing.toggleTime / inputBuffer.slotCount)
	inputBuffer.fillIndex = 1
	inputBuffer.dropIndex = inputBuffer.fillIndex + 1
	inputBuffer.slotTimer = inputBuffer.slotDuration
	inputBuffer.activeTimeout = inputBuffer.slotDuration * (inputBuffer.slotCount + 2)
	inputBuffer.activeTimer = inputBuffer.activeTimeout
	inputBuffer.buffer = {}

	for _ = 1, inputBuffer.slotCount do
		table.insert(inputBuffer.buffer, {
			effectDensity = 0.2,
			strawRatio = 0,
			inputLiters = 0,
			realArea = 0,
			area = 0,
			liters = 0
		})
	end

	entry.processing.inputBuffer = inputBuffer
	entry.threshingStartAnimation = xmlFile:getValue(baseKey .. ".threshingStartAnimation#name")
	entry.threshingStartAnimationSpeedScale = xmlFile:getValue(baseKey .. ".threshingStartAnimation#speedScale", 1)
	entry.threshingStartAnimationInitialIsStarted = xmlFile:getValue(baseKey .. ".threshingStartAnimation#initialIsStarted", false)
	entry.foldFillLevelThreshold = xmlFile:getValue(baseKey .. ".folding#fillLevelThresholdPct", 0.15) * (self:getFillUnitCapacity(entry.fillUnitIndex) or 0.04)
	entry.foldDirection = xmlFile:getValue(baseKey .. ".folding#direction", 1)
	entry.allowFoldWhileThreshing = xmlFile:getValue(baseKey .. ".folding#allowWhileThreshing", false)
	entry.additives = {
		fillUnitIndex = xmlFile:getValue(baseKey .. ".additives#fillUnitIndex")
	}
	entry.additives.available = self:getFillUnitByIndex(entry.additives.fillUnitIndex) ~= nil
	entry.additives.usage = xmlFile:getValue(baseKey .. ".additives#usage", 0)
	local additivesFillTypeNames = xmlFile:getValue(baseKey .. ".additives#fillTypes", "CHAFF GRASS_WINDROW")
	entry.additives.fillTypes = g_fillTypeManager:getFillTypesByNames(additivesFillTypeNames, "Warning: '" .. xmlFile:getFilename() .. "' has invalid fillType '%s'.")
	entry.automaticTilt = {
		nodes = {}
	}

	xmlFile:iterate(baseKey .. ".automaticTilt.automaticTiltNode", function (index, key)
		local automaticTiltNode = {
			node = xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
		}

		if automaticTiltNode.node ~= nil then
			automaticTiltNode.minAngle = xmlFile:getValue(key .. "#minAngle", -5)
			automaticTiltNode.maxAngle = xmlFile:getValue(key .. "#maxAngle", 5)
			automaticTiltNode.maxSpeed = xmlFile:getValue(key .. "#maxSpeed", 2) / 1000
			automaticTiltNode.updateAttacherJoint = xmlFile:getValue(key .. "#updateAttacherJoint")
			automaticTiltNode.dependentAnimation = xmlFile:getValue(key .. "#dependentAnimation")
			automaticTiltNode.lastJointUpdateRot = 0

			table.insert(entry.automaticTilt.nodes, automaticTiltNode)
		end
	end)

	entry.automaticTilt.hasNodes = #entry.automaticTilt.nodes > 0
end

function Combine:loadCombineEffects(xmlFile, baseKey, entry)
	if self.isClient then
		XMLUtil.checkDeprecatedXMLElements(xmlFile, baseKey .. ".chopperParticleSystems", baseKey .. ".chopperEffect")
		XMLUtil.checkDeprecatedXMLElements(xmlFile, baseKey .. ".strawParticleSystems", baseKey .. ".strawEffect")
		XMLUtil.checkDeprecatedXMLElements(xmlFile, baseKey .. ".threshingFillParticleSystems", baseKey .. ".fillEffect")

		entry.chopperEffects = g_effectManager:loadEffect(xmlFile, baseKey .. ".chopperEffect", self.components, self, self.i3dMappings)
		entry.strawEffects = g_effectManager:loadEffect(xmlFile, baseKey .. ".strawEffect", self.components, self, self.i3dMappings)
		entry.fillEffects = g_effectManager:loadEffect(xmlFile, baseKey .. ".fillEffect", self.components, self, self.i3dMappings)
		entry.effects = g_effectManager:loadEffect(xmlFile, baseKey .. ".effect", self.components, self, self.i3dMappings)
		entry.strawPSenabled = false
		entry.chopperPSenabled = false
		entry.isFilling = false
		entry.fillEnableTime = nil
		entry.fillDisableTime = nil
		entry.lastEffectFillType = FillType.UNKNOWN
	end
end

function Combine:loadCombineRotationNodes(xmlFile, baseKey, entry)
	if self.isClient then
		entry.animationNodes = g_animationManager:loadAnimations(xmlFile, baseKey .. ".animationNodes", self.components, self, self.i3dMappings)
		entry.chopperAnimationNodes = g_animationManager:loadAnimations(xmlFile, baseKey .. ".chopperAnimationNodes", self.components, self, self.i3dMappings)
		entry.strawDropAnimationNodes = g_animationManager:loadAnimations(xmlFile, baseKey .. ".strawDropAnimationNodes", self.components, self, self.i3dMappings)
		entry.fillingAnimationNodes = g_animationManager:loadAnimations(xmlFile, baseKey .. ".fillingAnimationNodes", self.components, self, self.i3dMappings)
		entry.rotationNodesSpeedReverseFillLevel = xmlFile:getValue(baseKey .. ".animationNodes#speedReverseFillLevel")
	end
end

function Combine:loadCombineSamples(xmlFile, key, entry)
	if self.isClient then
		entry.samples = {
			start = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "start", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			stop = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "stop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			work = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			chopperStart = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "chopperStart", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			chopperStop = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "chopperStop", self.baseDirectory, self.components, 1, AudioGroup.VEHICLE, self.i3dMappings, self),
			chopperWork = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "chopperWork", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			chopStraw = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "chopStraw", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			dropStraw = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "dropStraw", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			fill = g_soundManager:loadSampleFromXML(xmlFile, key .. ".sounds", "fill", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end
end

function Combine:setIsSwathActive(isSwathActive, noEventSend, force)
	local spec = self.spec_combine

	if isSwathActive ~= spec.isSwathActive or force then
		CombineStrawEnableEvent.sendEvent(self, isSwathActive, noEventSend)

		spec.isSwathActive = isSwathActive
		local anim = spec.chopper.animName

		if self.playAnimation ~= nil and anim ~= nil then
			local dir = 1

			if isSwathActive then
				dir = -1
			end

			self:playAnimation(anim, dir * spec.chopper.animSpeedScale, self:getAnimationTime(anim), true)

			if force then
				AnimatedVehicle.updateAnimationByName(self, anim, 9999999, true)
			end
		end

		local inputBuffer = spec.processing.inputBuffer

		for i = 1, #inputBuffer.buffer do
			inputBuffer.buffer[i].liters = 0
		end

		if self:getIsTurnedOn() and self.isClient then
			if spec.isSwathActive then
				g_animationManager:stopAnimations(spec.chopperAnimationNodes)
				g_animationManager:startAnimations(spec.strawDropAnimationNodes)

				if g_soundManager:getIsSamplePlaying(spec.samples.chopperWork) then
					g_soundManager:stopSample(spec.samples.chopperWork)
					g_soundManager:playSample(spec.samples.chopperStop)
				end
			else
				g_animationManager:stopAnimations(spec.strawDropAnimationNodes)
				g_animationManager:startAnimations(spec.chopperAnimationNodes)
				g_soundManager:stopSample(spec.samples.chopperStop)
				g_soundManager:playSample(spec.samples.chopperStart)
				g_soundManager:playSample(spec.samples.chopperWork, 0, spec.samples.chopperStart)
			end
		end

		Combine.updateToggleStrawText(self)
	end
end

function Combine:processCombineChopperArea(workArea)
	local spec = self.spec_combine

	if not spec.isSwathActive then
		local litersToDrop = spec.workAreaParameters.litersToDrop
		local strawRatio = spec.workAreaParameters.strawRatio
		local strawGroundType = spec.workAreaParameters.strawGroundType
		spec.workAreaParameters.droppedLiters = litersToDrop

		if litersToDrop > 0 and strawRatio > 0 then
			if Platform.gameplay.useSprayDiffuseMaps and strawRatio > 0.5 and strawGroundType ~= nil then
				local xs, _, zs = getWorldTranslation(workArea.start)
				local xw, _, zw = getWorldTranslation(workArea.width)
				local xh, _, zh = getWorldTranslation(workArea.height)

				FSDensityMapUtil.setGroundTypeLayerArea(xs, zs, xw, zw, xh, zh, strawGroundType)
			end

			self:raiseActive()

			spec.workAreaParameters.isChopperEffectEnabled = 500
		end
	end

	return spec.workAreaParameters.lastRealArea, spec.workAreaParameters.lastArea
end

function Combine:processCombineSwathArea(workArea)
	local spec = self.spec_combine
	local litersToDrop = spec.workAreaParameters.litersToDrop

	if spec.isSwathActive and litersToDrop > 0 then
		local droppedLiters = 0
		local fruitDesc = g_fruitTypeManager:getFruitTypeByFillTypeIndex(spec.workAreaParameters.dropFillType)

		if fruitDesc ~= nil and fruitDesc.windrowLiterPerSqm ~= nil then
			local windrowFillType = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(fruitDesc.index)

			if windrowFillType ~= nil then
				local sx, sy, sz, ex, ey, ez = DensityMapHeightUtil.getLineByArea(workArea.start, workArea.width, workArea.height, true)
				local dropped, lineOffset = DensityMapHeightUtil.tipToGroundAroundLine(self, litersToDrop, windrowFillType, sx, sy, sz, ex, ey, ez, 0, nil, workArea.lineOffset, false, nil, false)
				droppedLiters = dropped
				workArea.lineOffset = lineOffset
			end
		end

		if droppedLiters > 0 then
			spec.workAreaParameters.isStrawEffectEnabled = 500
		end

		spec.workAreaParameters.droppedLiters = droppedLiters
	end

	return spec.workAreaParameters.lastRealArea, spec.workAreaParameters.lastArea
end

function Combine:setChopperPSEnabled(chopperPSenabled, fruitTypeChanged, density, isSynchronized)
	local spec = self.spec_combine

	if spec.chopperPSenabled ~= chopperPSenabled or fruitTypeChanged then
		spec.chopperPSenabled = chopperPSenabled

		if self.isServer and isSynchronized then
			spec.sentChopperPSenabled = chopperPSenabled
		end

		if self.isClient then
			if not chopperPSenabled or fruitTypeChanged then
				g_effectManager:stopEffects(spec.chopperEffects)
			end

			if chopperPSenabled then
				g_effectManager:setFillType(spec.chopperEffects, self:getCombineLastValidFillType())
				g_effectManager:startEffects(spec.chopperEffects)

				if not g_soundManager:getIsSamplePlaying(spec.samples.chopStraw) then
					g_soundManager:playSample(spec.samples.chopStraw)
				end
			elseif g_soundManager:getIsSamplePlaying(spec.samples.chopStraw) then
				g_soundManager:stopSample(spec.samples.chopStraw)
			end
		end
	end

	if spec.chopperPSenabled and density ~= nil then
		g_effectManager:setDensity(spec.chopperEffects, density)
	end
end

function Combine:setStrawPSEnabled(strawPSenabled, fruitTypeChanged, density, isSynchronized)
	local spec = self.spec_combine

	if spec.strawPSenabled ~= strawPSenabled or fruitTypeChanged then
		spec.strawPSenabled = strawPSenabled

		if self.isServer and isSynchronized then
			spec.sentStrawPSenabled = strawPSenabled
		end

		if not strawPSenabled then
			spec.strawToDrop = 0
		end

		if self.isClient then
			if not strawPSenabled or fruitTypeChanged then
				g_effectManager:stopEffects(spec.strawEffects)
			end

			if strawPSenabled then
				g_effectManager:setFillType(spec.strawEffects, self:getCombineLastValidFillType())
				g_effectManager:startEffects(spec.strawEffects)

				if not g_soundManager:getIsSamplePlaying(spec.samples.dropStraw) then
					g_soundManager:playSample(spec.samples.dropStraw)
				end
			elseif g_soundManager:getIsSamplePlaying(spec.samples.dropStraw) then
				g_soundManager:stopSample(spec.samples.dropStraw)
			end
		end
	end

	if spec.strawPSenabled and density ~= nil then
		g_effectManager:setDensity(spec.strawEffects, density)
	end
end

function Combine:setCombineIsFilling(isFilling, fruitTypeChanged, isSynchronized)
	local spec = self.spec_combine

	if spec.isFilling ~= isFilling or fruitTypeChanged then
		spec.isFilling = isFilling

		if self.isServer and isSynchronized then
			spec.sentIsFilling = isFilling
		end

		if self.isClient then
			if isFilling then
				g_animationManager:startAnimations(spec.fillingAnimationNodes)
			else
				g_animationManager:stopAnimations(spec.fillingAnimationNodes)
			end

			g_animationManager:setFillType(spec.fillingAnimationNodes, self:getCombineLastValidFillType())
			g_effectManager:setFillType(spec.effects, self:getCombineLastValidFillType(spec.fillUnitIndex))

			if not isFilling or fruitTypeChanged then
				g_effectManager:stopEffects(spec.fillEffects)
			end

			if isFilling then
				g_effectManager:setFillType(spec.fillEffects, self:getCombineLastValidFillType())
				g_effectManager:startEffects(spec.fillEffects)
			end

			if isFilling then
				if not g_soundManager:getIsSamplePlaying(spec.samples.fill) then
					g_soundManager:playSample(spec.samples.fill)
				end
			elseif g_soundManager:getIsSamplePlaying(spec.samples.fill) then
				g_soundManager:stopSample(spec.samples.fill)
			end
		end
	end
end

function Combine:startThreshing()
	local spec = self.spec_combine

	if spec.numAttachedCutters > 0 then
		local allowLowering = not self:getIsAIActive() or not self.rootVehicle:getAIFieldWorkerIsTurning()

		for _, cutter in pairs(spec.attachedCutters) do
			if allowLowering and cutter ~= self then
				local jointDescIndex = self:getAttacherJointIndexFromObject(cutter)

				self:setJointMoveDown(jointDescIndex, true, true)
			end

			cutter:setIsTurnedOn(true, true)
		end

		if spec.threshingStartAnimation ~= nil and self.playAnimation ~= nil then
			self:playAnimation(spec.threshingStartAnimation, spec.threshingStartAnimationSpeedScale, self:getAnimationTime(spec.threshingStartAnimation), true)
		end

		if self.isClient then
			g_soundManager:stopSample(spec.samples.stop)
			g_soundManager:stopSample(spec.samples.work)
			g_soundManager:playSample(spec.samples.start)
			g_soundManager:playSample(spec.samples.work, 0, spec.samples.start)
		end

		SpecializationUtil.raiseEvent(self, "onStartThreshing")
	end
end

function Combine:stopThreshing()
	local spec = self.spec_combine

	if self.isClient then
		g_soundManager:stopSample(spec.samples.start)
		g_soundManager:stopSample(spec.samples.work)
		g_soundManager:playSample(spec.samples.stop)
	end

	self:setCombineIsFilling(false, false, true)

	for cutter, _ in pairs(spec.attachedCutters) do
		if cutter ~= self then
			local jointDescIndex = self:getAttacherJointIndexFromObject(cutter)

			self:setJointMoveDown(jointDescIndex, false, true)
		end

		cutter:setIsTurnedOn(false, true)
	end

	if spec.threshingStartAnimation ~= nil and spec.playAnimation ~= nil then
		self:playAnimation(spec.threshingStartAnimation, -spec.threshingStartAnimationSpeedScale, self:getAnimationTime(spec.threshingStartAnimation), true)
	end

	SpecializationUtil.raiseEvent(self, "onStopThreshing")
end

function Combine:setWorkedHectars(hectars)
	local spec = self.spec_combine
	spec.workedHectars = hectars

	if self.isServer and math.abs(spec.workedHectars - spec.workedHectarsSent) > 0.01 then
		self:raiseDirtyFlags(spec.dirtyFlag)

		spec.workedHectarsSent = spec.workedHectars
	end
end

function Combine:addCutterToCombine(cutter)
	local spec = self.spec_combine

	if spec.attachedCutters[cutter] == nil then
		spec.attachedCutters[cutter] = cutter
		spec.numAttachedCutters = spec.numAttachedCutters + 1
		local ladder = self.spec_combine.ladder

		if ladder.unfoldWhileCutterAttached and ladder.animName ~= nil and self:getAnimationTime(ladder.animName) < 1 then
			self:playAnimation(ladder.animName, ladder.animSpeedScale, self:getAnimationTime(ladder.animName), true)
		end
	end
end

function Combine:removeCutterFromCombine(cutter)
	local spec = self.spec_combine

	if spec.attachedCutters[cutter] ~= nil then
		spec.numAttachedCutters = spec.numAttachedCutters - 1

		if spec.numAttachedCutters == 0 then
			self:setIsTurnedOn(false, true)

			if spec.isBufferCombine then
				local currentFillType = self:getFillUnitFillType(spec.fillUnitIndex)

				if currentFillType ~= FillType.UNKNOWN then
					self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.fillUnitIndex, -math.huge, currentFillType, ToolType.UNDEFINED, nil)
				end
			end
		end

		spec.attachedCutters[cutter] = nil
		local ladder = self.spec_combine.ladder

		if ladder.unfoldWhileCutterAttached and ladder.animName ~= nil then
			local fold = true

			if self.getFoldAnimTime ~= nil then
				local foldAnimTime = self:getFoldAnimTime()

				if ladder.foldMaxLimit < foldAnimTime or foldAnimTime < ladder.foldMinLimit then
					fold = false
				end
			end

			if fold then
				self:playAnimation(ladder.animName, -ladder.animSpeedScale, self:getAnimationTime(ladder.animName), true)
			end
		end
	end
end

function Combine:addCutterArea(area, realArea, inputFruitType, outputFillType, strawRatio, strawGroundType, farmId, cutterLoad)
	local spec = self.spec_combine

	if area > 0 and (spec.lastCuttersFruitType == FruitType.UNKNOWN or spec.lastCuttersArea == 0 or spec.lastCuttersOutputFillType == outputFillType) then
		spec.lastCuttersArea = spec.lastCuttersArea + area
		spec.lastCuttersOutputFillType = outputFillType
		spec.lastCuttersInputFruitType = inputFruitType
		spec.lastCuttersAreaTime = g_currentMission.time

		if not spec.swath.isAvailable then
			local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(inputFruitType)
			spec.isSwathActive = not fruitDesc.hasWindrow
		end

		local litersPerSqm = 60
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(inputFruitType)

		if fruitDesc.windrowLiterPerSqm ~= nil then
			litersPerSqm = fruitDesc.windrowLiterPerSqm
		end

		if self:getIsThreshingDuringRain() then
			realArea = realArea * (1 - Combine.RAIN_YIELD_REDUCTION)
		end

		if self:getFillUnitLastValidFillType(spec.fillUnitIndex) == outputFillType or self:getFillUnitLastValidFillType(spec.bufferFillUnitIndex) == outputFillType then
			local liters = realArea * g_currentMission:getFruitPixelsToSqm() * litersPerSqm * strawRatio

			if liters > 0 then
				local inputBuffer = spec.processing.inputBuffer
				local slot = inputBuffer.buffer[inputBuffer.fillIndex]
				slot.area = slot.area + area
				slot.realArea = slot.realArea + realArea
				slot.liters = slot.liters + liters
				slot.inputLiters = slot.inputLiters + liters
				slot.strawRatio = strawRatio
				slot.strawGroundType = strawGroundType
				slot.effectDensity = cutterLoad * strawRatio * 0.8 + 0.2
			end
		end

		if spec.fillEnableTime == nil then
			spec.fillEnableTime = g_currentMission.time + spec.processing.toggleTime
		end

		local pixelToSqm = g_currentMission:getFruitPixelsToSqm()
		local literPerSqm = 1

		if inputFruitType ~= FruitType.UNKNOWN then
			fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(inputFruitType)
			literPerSqm = fruitDesc.literPerSqm
		end

		local sqm = realArea * pixelToSqm
		local deltaFillLevel = sqm * literPerSqm * spec.threshingScale
		local fillType = outputFillType

		if spec.additives.available then
			local fillTypeSupported = false

			for i = 1, #spec.additives.fillTypes do
				if fillType == spec.additives.fillTypes[i] then
					fillTypeSupported = true

					break
				end
			end

			if fillTypeSupported then
				local additivesFillLevel = self:getFillUnitFillLevel(spec.additives.fillUnitIndex)

				if additivesFillLevel > 0 then
					local usage = spec.additives.usage * deltaFillLevel
					local availableUsage = usage / additivesFillLevel
					deltaFillLevel = deltaFillLevel * (1 + 0.05 * availableUsage)

					self:addFillUnitFillLevel(self:getOwnerFarmId(), spec.additives.fillUnitIndex, -usage, self:getFillUnitFillType(spec.additives.fillUnitIndex), ToolType.UNDEFINED)
				end
			end
		end

		self:setWorkedHectars(spec.workedHectars + MathUtil.areaToHa(realArea, g_currentMission:getFruitPixelsToSqm()))

		if farmId ~= AccessHandler.EVERYONE then
			local damage = self:getVehicleDamage()

			if damage > 0 then
				deltaFillLevel = deltaFillLevel * (1 - damage * Combine.DAMAGED_YIELD_REDUCTION)
			end
		end

		if self:getFillUnitCapacity(spec.fillUnitIndex) == math.huge and self:getFillUnitFillLevel(spec.fillUnitIndex) > 0.001 and spec.lastDischargeTime + spec.fillLevelBufferTime < g_time then
			return deltaFillLevel
		end

		local fillUnitIndex = spec.fillUnitIndex

		if spec.bufferFillUnitIndex ~= nil and self:getFillUnitFreeCapacity(spec.bufferFillUnitIndex) > 0 then
			fillUnitIndex = spec.bufferFillUnitIndex
		end

		if spec.loadingDelay > 0 then
			for i = 1, #spec.loadingDelaySlots do
				if not spec.loadingDelaySlots[i].valid then
					spec.loadingDelaySlots[i].valid = true
					spec.loadingDelaySlots[i].fillLevelDelta = deltaFillLevel
					spec.loadingDelaySlots[i].fillType = fillType

					if spec.loadingDelaySlotsDelayedInsert then
						spec.loadingDelaySlots[i].time = g_time
					else
						spec.loadingDelaySlots[i].time = g_time + spec.unloadingDelay - spec.loadingDelay
					end

					spec.loadingDelaySlotsDelayedInsert = not spec.loadingDelaySlotsDelayedInsert

					break
				end
			end

			return deltaFillLevel
		end

		local loadInfo = self:getFillVolumeLoadInfo(spec.loadInfoIndex)

		return self:addFillUnitFillLevel(self:getOwnerFarmId(), fillUnitIndex, deltaFillLevel, fillType, ToolType.UNDEFINED, loadInfo)
	end

	return 0
end

function Combine:getIsThreshingDuringRain(earlyWarning)
	local spec = self.spec_combine

	if not spec.allowThreshingDuringRain then
		local rainScale = g_currentMission.environment.weather:getRainFallScale()
		local timeSinceLastRain = g_currentMission.environment.weather:getTimeSinceLastRain()

		if earlyWarning ~= nil and earlyWarning == true then
			if rainScale >= 0.02 and timeSinceLastRain < 20 then
				return true
			end
		elseif rainScale >= 0.1 and timeSinceLastRain < 20 then
			return true
		end
	end

	return false
end

function Combine:verifyCombine(fruitType, outputFillType)
	local spec = self.spec_combine
	local fillUnitIndex = spec.bufferFillUnitIndex or spec.fillUnitIndex

	if self:getFillTypeChangeThreshold() < self:getFillUnitFillLevelPercentage(fillUnitIndex) or spec.isBufferCombine then
		local currentFillType = self:getFillUnitFillType(fillUnitIndex)

		if currentFillType ~= FillType.UNKNOWN and fruitType ~= FruitType.UNKNOWN and currentFillType ~= outputFillType then
			if spec.isBufferCombine then
				self:addFillUnitFillLevel(self:getOwnerFarmId(), fillUnitIndex, -math.huge, currentFillType, ToolType.UNDEFINED, nil)

				return self
			end

			return nil, self, currentFillType
		end
	end

	local maxFreeCapacity = 0

	if spec.bufferFillUnitIndex ~= nil then
		maxFreeCapacity = self:getFillUnitFillLevel(spec.bufferFillUnitIndex)
	end

	if self:getFillUnitFreeCapacity(spec.fillUnitIndex) <= maxFreeCapacity then
		return nil
	end

	return self
end

function Combine:getFillLevelDependentSpeed()
	local spec = self.spec_combine

	if spec.rotationNodesSpeedReverseFillLevel ~= nil then
		local fillLevelPct = self:getFillUnitFillLevel(spec.fillUnitIndex) / self:getFillUnitCapacity(spec.fillUnitIndex)

		if spec.rotationNodesSpeedReverseFillLevel < fillLevelPct then
			return -1
		else
			return 1
		end
	else
		return 1
	end
end

function Combine:getIsCutterCompatible(fillTypes)
	local spec = self.spec_combine
	local supportedTypes = self:getFillUnitSupportedFillTypes(spec.fillUnitIndex)

	for i = 1, #fillTypes do
		local fillType = fillTypes[i]

		for supportedType, _ in pairs(supportedTypes) do
			if fillType == supportedType then
				return true
			end
		end
	end

	return false
end

function Combine:getCombineLastValidFillType()
	local spec = self.spec_combine
	local fillType = FillType.UNKNOWN

	if spec.bufferFillUnitIndex ~= nil then
		fillType = self:getFillUnitLastValidFillType(spec.bufferFillUnitIndex)
	end

	if fillType == FillType.UNKNOWN then
		fillType = self:getFillUnitLastValidFillType(spec.fillUnitIndex)
	end

	if fillType == FillType.UNKNOWN and spec.loadingDelay > 0 then
		for i = 1, #spec.loadingDelaySlots do
			if spec.loadingDelaySlots[i].valid then
				fillType = spec.loadingDelaySlots[i].fillType

				break
			end
		end
	end

	if fillType == FillType.UNKNOWN then
		fillType = spec.lastValidInputFillType
	end

	return fillType
end

function Combine:getCombineLoadPercentage()
	local spec = self.spec_combine

	if spec ~= nil and spec.numAttachedCutters > 0 then
		local loadSum = 0

		for cutter, _ in pairs(spec.attachedCutters) do
			if cutter.getCutterLoad ~= nil then
				loadSum = loadSum + cutter:getCutterLoad()
			end
		end

		return loadSum / spec.numAttachedCutters
	end

	return 0
end

g_soundManager:registerModifierType("COMBINE_LOAD", Combine.getCombineLoadPercentage)

function Combine:getCanBeTurnedOn(superFunc)
	local spec = self.spec_combine

	if spec.numAttachedCutters <= 0 then
		return false
	end

	for cutter, _ in pairs(spec.attachedCutters) do
		if cutter ~= self and cutter.getCanBeTurnedOn ~= nil and not cutter:getCanBeTurnedOn() then
			return false
		end
	end

	return superFunc(self)
end

function Combine:getTurnedOnNotAllowedWarning(superFunc)
	if self:getIsActiveForInput(true) then
		local spec = self.spec_combine

		if not self:getCanBeTurnedOn() then
			if spec.numAttachedCutters == 0 then
				return spec.texts.warningNoCutter
			else
				for cutter, _ in pairs(spec.attachedCutters) do
					if cutter ~= self and cutter.getTurnedOnNotAllowedWarning ~= nil then
						local warning = cutter:getTurnedOnNotAllowedWarning()

						if warning ~= nil then
							return warning
						end
					end
				end
			end
		end
	end

	return superFunc(self)
end

function Combine:getAreControlledActionsAllowed(superFunc)
	local spec = self.spec_combine

	if spec.numAttachedCutters <= 0 then
		return false, spec.texts.warningNoCutter
	end

	return superFunc(self)
end

function Combine:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_combine

	if not spec.allowFoldWhileThreshing and self:getIsTurnedOn() then
		return false, spec.texts.warningFoldingTurnedOn
	end

	local fillLevel = self:getFillUnitFillLevel(spec.fillUnitIndex)

	if direction == spec.foldDirection and spec.foldFillLevelThreshold < fillLevel and self:getFillUnitCapacity(spec.fillUnitIndex) ~= math.huge then
		return false, spec.texts.warningFoldingWhileFilled
	end

	return superFunc(self, direction, onAiTurnOn)
end

function Combine:getCanBeSelected(superFunc)
	return true
end

function Combine:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	if not superFunc(self, workArea, xmlFile, key) then
		return false
	end

	if workArea.type == WorkAreaType.COMBINECHOPPER or workArea.type == WorkAreaType.COMBINESWATH then
		if xmlFile:getValue(key .. "#requiresOwnedFarmland") == nil then
			workArea.requiresOwnedFarmland = false
		end

		if xmlFile:getValue(key .. "#needsSetIsTurnedOn") == nil then
			workArea.needsSetIsTurnedOn = false
		end
	end

	return true
end

function Combine:getDirtMultiplier(superFunc)
	local spec = self.spec_combine

	for cutter, _ in pairs(spec.attachedCutters) do
		if cutter.spec_cutter ~= nil and cutter.spec_cutter.isWorking then
			return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / cutter.speedLimit
		end
	end

	return superFunc(self)
end

function Combine:getWearMultiplier(superFunc)
	local spec = self.spec_combine

	for cutter, _ in pairs(spec.attachedCutters) do
		if cutter.spec_cutter ~= nil and cutter.spec_cutter.isWorking then
			local stoneMultiplier = cutter:getCutterStoneMultiplier()

			return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / cutter.speedLimit * stoneMultiplier
		end
	end

	return superFunc(self)
end

function Combine:loadTurnedOnAnimationFromXML(superFunc, xmlFile, key, turnedOnAnimation)
	turnedOnAnimation.activeChopper = xmlFile:getValue(key .. "#activeChopper", true)
	turnedOnAnimation.activeStrawDrop = xmlFile:getValue(key .. "#activeStrawDrop", true)
	turnedOnAnimation.waitForStraw = xmlFile:getValue(key .. "#waitForStraw", false)

	return superFunc(self, xmlFile, key, turnedOnAnimation)
end

function Combine:getIsTurnedOnAnimationActive(superFunc, turnedOnAnimation)
	local spec = self.spec_combine

	if not turnedOnAnimation.activeChopper and not spec.isSwathActive or not turnedOnAnimation.activeStrawDrop and spec.isSwathActive then
		return false
	end

	if turnedOnAnimation.waitForStraw then
		return superFunc(self, turnedOnAnimation) or spec.workAreaParameters.isChopperEffectEnabled > 0
	end

	return superFunc(self, turnedOnAnimation)
end

function Combine:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_combine

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection and spec.swath.isAvailable and spec.chopper.isAvailable then
			local func = self.addActionEvent

			if spec.chopper.isPowered then
				func = self.addPoweredActionEvent
			end

			local _, actionEventId = func(self, spec.actionEvents, InputAction.TOGGLE_CHOPPER, self, Combine.actionEventToggleChopper, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
			Combine.updateToggleStrawText(self)
		end
	end
end

function Combine:onStartWorkAreaProcessing(dt)
	local spec = self.spec_combine
	spec.workAreaParameters.droppedLiters = 0
	spec.workAreaParameters.litersToDrop = 0
	spec.workAreaParameters.strawRatio = 0
	spec.workAreaParameters.dropFillType = FillType.UNKNOWN
	local fillUnitIndex = spec.bufferFillUnitIndex or spec.fillUnitIndex
	local lastValidFillType = self:getFillUnitLastValidFillType(fillUnitIndex)

	if lastValidFillType ~= FillType.UNKNOWN then
		local inputBuffer = spec.processing.inputBuffer
		local inputLiters = inputBuffer.buffer[inputBuffer.dropIndex].inputLiters
		spec.workAreaParameters.litersToDrop = math.min(inputBuffer.buffer[inputBuffer.dropIndex].liters, dt / inputBuffer.slotDuration * inputLiters)
		spec.workAreaParameters.strawRatio = inputBuffer.buffer[inputBuffer.dropIndex].strawRatio
		spec.workAreaParameters.strawGroundType = inputBuffer.buffer[inputBuffer.dropIndex].strawGroundType
		spec.workAreaParameters.effectDensity = inputBuffer.buffer[inputBuffer.dropIndex].effectDensity
		spec.workAreaParameters.dropFillType = lastValidFillType
	end

	spec.workAreaParameters.lastRealArea = 0
	spec.workAreaParameters.lastArea = 0
end

function Combine:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self.spec_combine
	local inputBuffer = spec.processing.inputBuffer
	inputBuffer.buffer[inputBuffer.dropIndex].liters = math.max(0, inputBuffer.buffer[inputBuffer.dropIndex].liters - spec.workAreaParameters.droppedLiters)
end

function Combine:onChangedFillType(fillUnitIndex, fillTypeIndex)
	local spec = self.spec_combine

	if (spec.bufferFillUnitIndex ~= nil and fillUnitIndex == spec.bufferFillUnitIndex or fillUnitIndex == spec.fillUnitIndex) and fillTypeIndex ~= FillType.UNKNOWN then
		if fillTypeIndex ~= spec.lastEffectFillType then
			if spec.chopperPSenabled then
				self:setChopperPSEnabled(true, true, 0, true)
			end

			if spec.strawPSenabled then
				self:setStrawPSEnabled(true, true, 0, true)
			end

			if spec.isFilling then
				self:setCombineIsFilling(true, true, true)
			end
		end

		spec.lastEffectFillType = fillTypeIndex
	end
end

function Combine:onDeactivate()
	local spec = self.spec_combine

	self:setChopperPSEnabled(false, false, 0, true)
	self:setStrawPSEnabled(false, false, 0, true)
	self:setCombineIsFilling(false, false, true)

	spec.fillEnableTime = nil
	spec.fillDisableTime = nil
end

function Combine:onPostAttachImplement(attachable, inputJointDescIndex, jointDescIndex)
	local attacherJoint = attachable:getActiveInputAttacherJoint()

	if attacherJoint ~= nil and (attacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTER or attacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTERHARVESTER) then
		self:addCutterToCombine(attachable)
	end
end

function Combine:onPostDetachImplement(implementIndex)
	local object = self:getObjectFromImplementIndex(implementIndex)

	if object ~= nil then
		local attacherJoint = object:getActiveInputAttacherJoint()

		if attacherJoint ~= nil and (attacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTER or attacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTERHARVESTER) then
			self:removeCutterFromCombine(object)
		end
	end
end

function Combine:onTurnedOn()
	self:startThreshing()

	if self.isClient then
		local spec = self.spec_combine

		g_animationManager:startAnimations(spec.animationNodes)

		if spec.isSwathActive then
			g_animationManager:startAnimations(spec.strawDropAnimationNodes)
		else
			g_animationManager:startAnimations(spec.chopperAnimationNodes)
			g_soundManager:stopSample(spec.samples.chopperStop)
			g_soundManager:playSample(spec.samples.chopperStart)
			g_soundManager:playSample(spec.samples.chopperWork, 0, spec.samples.chopperStart)
		end

		g_effectManager:setFillType(spec.effects, self:getCombineLastValidFillType())
		g_effectManager:startEffects(spec.effects)
	end
end

function Combine:onTurnedOff()
	self:stopThreshing()

	if self.isClient then
		local spec = self.spec_combine

		g_animationManager:stopAnimations(spec.animationNodes)
		g_animationManager:stopAnimations(spec.chopperAnimationNodes)
		g_animationManager:stopAnimations(spec.strawDropAnimationNodes)
		g_effectManager:stopEffects(spec.effects)

		if g_soundManager:getIsSamplePlaying(spec.samples.chopperWork) then
			g_soundManager:stopSample(spec.samples.chopperWork)
			g_soundManager:playSample(spec.samples.chopperStop)
		end
	end
end

function Combine:onEnterVehicle()
	local ladder = self.spec_combine.ladder

	if ladder.animName ~= nil then
		local fold = true

		if self.getFoldAnimTime ~= nil then
			local foldAnimTime = self:getFoldAnimTime()

			if ladder.foldMaxLimit < foldAnimTime or foldAnimTime < ladder.foldMinLimit then
				fold = false
			end
		end

		if ladder.unfoldWhileCutterAttached and self.spec_combine.numAttachedCutters > 0 then
			fold = false
		end

		if fold then
			self:playAnimation(ladder.animName, -ladder.animSpeedScale, self:getAnimationTime(ladder.animName), true)
		end
	end
end

function Combine:onLeaveVehicle()
	local ladder = self.spec_combine.ladder

	if ladder.animName ~= nil then
		local fold = true

		if self.getFoldAnimTime ~= nil then
			local foldAnimTime = self:getFoldAnimTime()

			if ladder.foldMaxLimit < foldAnimTime or foldAnimTime < ladder.foldMinLimit then
				fold = false
			end
		end

		if ladder.unfoldWhileCutterAttached and self.spec_combine.numAttachedCutters > 0 then
			fold = false
		end

		if fold then
			self:playAnimation(ladder.animName, ladder.animSpeedScale, self:getAnimationTime(ladder.animName), true)
		end
	end
end

function Combine:onFoldStateChanged(direction, moveToMiddle)
	local ladder = self.spec_combine.ladder

	if ladder.animName ~= nil and direction ~= 0 and not moveToMiddle then
		local fold = true

		if ladder.unfoldWhileCutterAttached and self.spec_combine.numAttachedCutters > 0 then
			fold = false
		end

		if fold then
			self:playAnimation(ladder.animName, direction * ladder.animSpeedScale * ladder.foldDirection, self:getAnimationTime(ladder.animName), true)
		end
	end
end

function Combine:onFillUnitFillLevelChanged(fillUnitIndex, fillLevelDelta, fillTypeIndex, toolType, fillPositionData, appliedDelta)
	local spec = self.spec_combine

	if fillUnitIndex == spec.fillUnitIndex and fillLevelDelta < 0 then
		spec.lastDischargeTime = g_time
	end
end

function Combine:actionEventToggleChopper(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_combine

	if spec.swath.isAvailable then
		local fillUnitIndex = spec.bufferFillUnitIndex or spec.fillUnitIndex
		local fruitType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(self:getFillUnitFillType(fillUnitIndex))

		if fruitType ~= nil and fruitType ~= FruitType.UNKNOWN then
			local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)

			if fruitDesc.hasWindrow then
				self:setIsSwathActive(not spec.isSwathActive)
			else
				g_currentMission:showBlinkingWarning(g_i18n:getText("warning_couldNotToggleChopper"), 2000)
			end
		else
			self:setIsSwathActive(not spec.isSwathActive)
		end
	end
end

function Combine:updateToggleStrawText()
	local spec = self.spec_combine
	local actionEvent = spec.actionEvents[InputAction.TOGGLE_CHOPPER]

	if actionEvent ~= nil and actionEvent.actionEventId ~= nil then
		local text = nil

		if spec.isSwathActive then
			text = g_i18n:getText("action_disableStrawSwath")
		else
			text = g_i18n:getText("action_enableStrawSwath")
		end

		g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
	end
end
