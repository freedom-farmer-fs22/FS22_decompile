source("dataS/scripts/vehicles/specializations/events/SetSeedIndexEvent.lua")

SowingMachine = {
	DAMAGED_USAGE_INCREASE = 0.3,
	AI_REQUIRED_GROUND_TYPES = {
		FieldGroundType.STUBBLE_TILLAGE,
		FieldGroundType.CULTIVATED,
		FieldGroundType.SEEDBED,
		FieldGroundType.PLOWED,
		FieldGroundType.ROLLED_SEEDBED
	},
	AI_OUTPUT_GROUND_TYPES = {
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

function SowingMachine.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("sowingMachine", true)
	g_storeManager:addSpecType("seedFillTypes", "shopListAttributeIconSeeds", SowingMachine.loadSpecValueSeedFillTypes, SowingMachine.getSpecValueSeedFillTypes, "vehicle")

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("SowingMachine")
	schema:register(XMLValueType.BOOL, "vehicle.sowingMachine.allowFillFromAirWhileTurnedOn#value", "Allow fill from air while turned on")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.sowingMachine.directionNode#node", "Direction node")
	schema:register(XMLValueType.BOOL, "vehicle.sowingMachine.useDirectPlanting#value", "Use direct planting", false)
	schema:register(XMLValueType.STRING, "vehicle.sowingMachine.seedFruitTypeCategories", "Seed fruit type categories")
	schema:register(XMLValueType.STRING, "vehicle.sowingMachine.seedFruitTypes", "Seed fruit types")
	schema:register(XMLValueType.BOOL, "vehicle.sowingMachine.needsActivation#value", "Needs activation", false)
	schema:register(XMLValueType.BOOL, "vehicle.sowingMachine.requiresFilling#value", "Requires filling", true)
	schema:register(XMLValueType.STRING, "vehicle.sowingMachine.fieldGroundType#value", "Defines the field ground type", "SOWN")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.sowingMachine.sounds", "work")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.sowingMachine.sounds", "airBlower")
	AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.sowingMachine.animationNodes")
	schema:register(XMLValueType.STRING, "vehicle.sowingMachine.changeSeedInputButton", "Input action name", "IMPLEMENT_EXTRA3")
	schema:register(XMLValueType.INT, "vehicle.sowingMachine#fillUnitIndex", "Fill unit index", 1)
	schema:register(XMLValueType.INT, "vehicle.sowingMachine#unloadInfoIndex", "Unload info index", 1)
	EffectManager.registerEffectXMLPaths(schema, "vehicle.sowingMachine.effects")
	schema:register(XMLValueType.STRING, "vehicle.storeData.specs.seedFruitTypeCategories", "Seed fruit type categories")
	schema:register(XMLValueType.STRING, "vehicle.storeData.specs.seedFruitTypes", "Seed fruit types")
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame

	schemaSavegame:register(XMLValueType.STRING, "vehicles.vehicle(?).sowingMachine#selectedSeedFruitType", "Selected fruit type name")
end

function SowingMachine.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(FillUnit, specializations) and SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TurnOnVehicle, specializations)
end

function SowingMachine.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "setSeedFruitType", SowingMachine.setSeedFruitType)
	SpecializationUtil.registerFunction(vehicleType, "setSeedIndex", SowingMachine.setSeedIndex)
	SpecializationUtil.registerFunction(vehicleType, "changeSeedIndex", SowingMachine.changeSeedIndex)
	SpecializationUtil.registerFunction(vehicleType, "getIsSeedChangeAllowed", SowingMachine.getIsSeedChangeAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getSowingMachineFillUnitIndex", SowingMachine.getSowingMachineFillUnitIndex)
	SpecializationUtil.registerFunction(vehicleType, "getCurrentSeedTypeIcon", SowingMachine.getCurrentSeedTypeIcon)
	SpecializationUtil.registerFunction(vehicleType, "processSowingMachineArea", SowingMachine.processSowingMachineArea)
	SpecializationUtil.registerFunction(vehicleType, "getUseSowingMachineAIRequirements", SowingMachine.getUseSowingMachineAIRequirements)
	SpecializationUtil.registerFunction(vehicleType, "setFillTypeSourceDisplayFillType", SowingMachine.setFillTypeSourceDisplayFillType)
	SpecializationUtil.registerFunction(vehicleType, "updateMissionSowingWarning", SowingMachine.updateMissionSowingWarning)
	SpecializationUtil.registerFunction(vehicleType, "getCanPlantOutsideSeason", SowingMachine.getCanPlantOutsideSeason)
end

function SowingMachine.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDrawFirstFillText", SowingMachine.getDrawFirstFillText)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAreControlledActionsAllowed", SowingMachine.getAreControlledActionsAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getFillUnitAllowsFillType", SowingMachine.getFillUnitAllowsFillType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanToggleTurnedOn", SowingMachine.getCanToggleTurnedOn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowFillFromAir", SowingMachine.getAllowFillFromAir)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirectionSnapAngle", SowingMachine.getDirectionSnapAngle)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addFillUnitFillLevel", SowingMachine.addFillUnitFillLevel)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", SowingMachine.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", SowingMachine.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", SowingMachine.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", SowingMachine.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", SowingMachine.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", SowingMachine.getCanAIImplementContinueWork)
end

function SowingMachine.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", SowingMachine)
	SpecializationUtil.registerEventListener(vehicleType, "onChangedFillType", SowingMachine)
end

function SowingMachine:onLoad(savegame)
	local spec = self.spec_sowingMachine

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.sowingMachine.animationNodes.animationNode", "sowingMachine")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnScrollers", "vehicle.sowingMachine.scrollerNodes.scrollerNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.useDirectPlanting", "vehicle.sowingMachine.useDirectPlanting#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.needsActivation#value", "vehicle.sowingMachine.needsActivation#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sowingEffects", "vehicle.sowingMachine.effects")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sowingEffectsWithFixedFillType", "vehicle.sowingMachine.fixedEffects")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sowingMachine#supportsAiWithoutSowingMachine", "vehicle.turnOnVehicle.aiRequiresTurnOn")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.sowingMachine.directionNode#index", "vehicle.sowingMachine.directionNode#node")

	spec.allowFillFromAirWhileTurnedOn = self.xmlFile:getValue("vehicle.sowingMachine.allowFillFromAirWhileTurnedOn#value", true)
	spec.directionNode = self.xmlFile:getValue("vehicle.sowingMachine.directionNode#node", self.components[1].node, self.components, self.i3dMappings)
	spec.useDirectPlanting = self.xmlFile:getValue("vehicle.sowingMachine.useDirectPlanting#value", false)
	spec.isWorking = false
	spec.isProcessing = false
	spec.stoneLastState = 0
	spec.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("SOWINGMACHINE")
	spec.seeds = {}
	local fruitTypes = {}
	local fruitTypeCategories = self.xmlFile:getValue("vehicle.sowingMachine.seedFruitTypeCategories")
	local fruitTypeNames = self.xmlFile:getValue("vehicle.sowingMachine.seedFruitTypes")

	if fruitTypeCategories ~= nil and fruitTypeNames == nil then
		fruitTypes = g_fruitTypeManager:getFruitTypesByCategoryNames(fruitTypeCategories, "Warning: '" .. self.configFileName .. "' has invalid fruitTypeCategory '%s'.")
	elseif fruitTypeCategories == nil and fruitTypeNames ~= nil then
		fruitTypes = g_fruitTypeManager:getFruitTypesByNames(fruitTypeNames, "Warning: '" .. self.configFileName .. "' has invalid fruitType '%s'.")
	else
		print("Warning: '" .. self.configFileName .. "' a sowingMachine needs either the 'seedFruitTypeCategories' or 'seedFruitTypes' element.")
	end

	if fruitTypes ~= nil then
		for _, fruitType in pairs(fruitTypes) do
			table.insert(spec.seeds, fruitType)
		end
	end

	spec.needsActivation = self.xmlFile:getValue("vehicle.sowingMachine.needsActivation#value", false)
	spec.requiresFilling = self.xmlFile:getValue("vehicle.sowingMachine.requiresFilling#value", true)
	spec.fieldGroundType = g_currentMission.fieldGroundSystem:getFieldGroundValueByName(self.xmlFile:getValue("vehicle.sowingMachine.fieldGroundType#value", "SOWN"))

	if self.isClient then
		spec.isWorkSamplePlaying = false
		spec.samples = {
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.sowingMachine.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			airBlower = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.sowingMachine.sounds", "airBlower", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.sampleFillEnabled = false
		spec.sampleFillStopTime = -1
		spec.lastFillLevel = -1
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.sowingMachine.animationNodes", self.components, self, self.i3dMappings)

		g_animationManager:setFillType(spec.animationNodes, FillType.UNKNOWN)

		local changeSeedInputButtonStr = self.xmlFile:getValue("vehicle.sowingMachine.changeSeedInputButton")

		if changeSeedInputButtonStr ~= nil then
			spec.changeSeedInputButton = InputAction[changeSeedInputButtonStr]
		end

		spec.changeSeedInputButton = Utils.getNoNil(spec.changeSeedInputButton, InputAction.TOGGLE_SEEDS)
	end

	spec.currentSeed = 1
	spec.allowsSeedChanging = true
	spec.showFruitCanNotBePlantedWarning = false
	spec.showWrongFruitForMissionWarning = false
	spec.warnings = {
		fruitCanNotBePlanted = g_i18n:getText("warning_theSelectedFruitTypeIsNotAvailableOnThisMap"),
		wrongFruitForMission = g_i18n:getText("warning_theSelectedFruitTypeIsWrongForTheMission"),
		wrongPlantingTime = g_i18n:getText("warning_theSelectedFruitTypeCantBePlantedInThisPeriod")
	}
	spec.fillUnitIndex = self.xmlFile:getValue("vehicle.sowingMachine#fillUnitIndex", 1)
	spec.unloadInfoIndex = self.xmlFile:getValue("vehicle.sowingMachine#unloadInfoIndex", 1)

	if self:getFillUnitByIndex(spec.fillUnitIndex) == nil then
		Logging.xmlError(self.xmlFile, "FillUnit '%d' not defined!", spec.fillUnitIndex)
		self:setLoadingState(VehicleLoadingUtil.VEHICLE_LOAD_ERROR)

		return
	end

	spec.fillTypeSources = {}

	if self.isClient then
		spec.effects = g_effectManager:loadEffect(self.xmlFile, "vehicle.sowingMachine.effects", self.components, self, self.i3dMappings)
	end

	spec.workAreaParameters = {
		seedsFruitType = nil,
		angle = 0,
		lastChangedArea = 0,
		lastStatsArea = 0,
		lastArea = 0
	}

	self:setSeedIndex(1, true)

	if savegame ~= nil then
		local selectedSeedFruitType = savegame.xmlFile:getValue(savegame.key .. ".sowingMachine#selectedSeedFruitType")

		if selectedSeedFruitType ~= nil then
			local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByName(selectedSeedFruitType)

			if fruitTypeDesc ~= nil then
				self:setSeedFruitType(fruitTypeDesc.index, true)
			end
		end
	end

	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onUpdate", SowingMachine)
		SpecializationUtil.removeEventListener(self, "onUpdateTick", SowingMachine)
	end
end

function SowingMachine:onPostLoad(savegame)
	SowingMachine.updateAiParameters(self)
end

function SowingMachine:onDelete()
	local spec = self.spec_sowingMachine

	g_soundManager:deleteSamples(spec.samples)
	g_effectManager:deleteEffects(spec.effects)
	g_animationManager:deleteAnimations(spec.animationNodes)
end

function SowingMachine:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_sowingMachine
	local selectedSeedFruitTypeName = "unknown"
	local selectedSeedFruitType = spec.seeds[spec.currentSeed]

	if selectedSeedFruitType ~= nil and selectedSeedFruitType ~= FruitType.UNKNOWN then
		local fruitType = g_fruitTypeManager:getFruitTypeByIndex(selectedSeedFruitType)
		selectedSeedFruitTypeName = fruitType.name
	end

	xmlFile:setValue(key .. "#selectedSeedFruitType", selectedSeedFruitTypeName)
end

function SowingMachine:onReadStream(streamId, connection)
	local seedIndex = streamReadUInt8(streamId)

	self:setSeedIndex(seedIndex, true)
end

function SowingMachine:onWriteStream(streamId, connection)
	local spec = self.spec_sowingMachine

	streamWriteUInt8(streamId, spec.currentSeed)
end

function SowingMachine:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_sowingMachine

	if spec.isProcessing then
		local fillType = self:getFillUnitForcedMaterialFillType(spec.fillUnitIndex)

		if fillType ~= nil then
			g_effectManager:setFillType(spec.effects, fillType)
			g_effectManager:startEffects(spec.effects)
		end
	else
		g_effectManager:stopEffects(spec.effects)
	end
end

function SowingMachine:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_sowingMachine
	local actionEvent = spec.actionEvents[spec.changeSeedInputButton]

	if actionEvent ~= nil then
		g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:getIsSeedChangeAllowed())
	end

	if self.isActiveForInputIgnoreSelectionIgnoreAI then
		if spec.showFruitCanNotBePlantedWarning then
			g_currentMission:showBlinkingWarning(spec.warnings.fruitCanNotBePlanted)
		elseif spec.showWrongFruitForMissionWarning then
			g_currentMission:showBlinkingWarning(spec.warnings.wrongFruitForMission)
		elseif spec.showWrongPlantingTimeWarning then
			g_currentMission:showBlinkingWarning(string.format(spec.warnings.wrongPlantingTime, g_i18n:formatPeriod()))
		end
	end
end

function SowingMachine:setSeedIndex(seedIndex, noEventSend)
	local spec = self.spec_sowingMachine

	SetSeedIndexEvent.sendEvent(self, seedIndex, noEventSend)

	spec.currentSeed = math.min(math.max(seedIndex, 1), table.getn(spec.seeds))
	local fillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.seeds[spec.currentSeed])

	self:setFillUnitFillTypeToDisplay(spec.fillUnitIndex, fillType, true)
	self:setFillTypeSourceDisplayFillType(fillType)
	SowingMachine.updateAiParameters(self)
	SowingMachine.updateChooseSeedActionEvent(self)
end

function SowingMachine:changeSeedIndex(increment)
	local spec = self.spec_sowingMachine
	local seed = spec.currentSeed + increment

	if seed > #spec.seeds then
		seed = 1
	elseif seed < 1 then
		seed = #spec.seeds
	end

	self:setSeedIndex(seed)
end

function SowingMachine:setSeedFruitType(fruitType, noEventSend)
	local spec = self.spec_sowingMachine

	for i, v in ipairs(spec.seeds) do
		if v == fruitType then
			self:setSeedIndex(i, noEventSend)

			break
		end
	end
end

function SowingMachine:getIsSeedChangeAllowed()
	return self.spec_sowingMachine.allowsSeedChanging
end

function SowingMachine:getSowingMachineFillUnitIndex()
	return self.spec_sowingMachine.fillUnitIndex
end

function SowingMachine:getCurrentSeedTypeIcon()
	local spec = self.spec_sowingMachine
	local fillType = g_fruitTypeManager:getFillTypeByFruitTypeIndex(spec.seeds[spec.currentSeed])

	if fillType ~= nil then
		return fillType.hudOverlayFilename
	end

	return nil
end

function SowingMachine:processSowingMachineArea(workArea, dt)
	local spec = self.spec_sowingMachine
	local changedArea = 0
	local totalArea = 0
	spec.isWorking = self:getLastSpeed() > 0.5

	if not spec.workAreaParameters.isActive then
		return changedArea, totalArea
	end

	if (not self:getIsAIActive() or not g_currentMission.missionInfo.helperBuySeeds) and spec.workAreaParameters.seedsVehicle == nil then
		if self:getIsAIActive() then
			local rootVehicle = self.rootVehicle

			rootVehicle:stopCurrentAIJob(AIMessageErrorOutOfFill.new())
		end

		return changedArea, totalArea
	end

	if not spec.workAreaParameters.canFruitBePlanted then
		return changedArea, totalArea
	end

	local sx, _, sz = getWorldTranslation(workArea.start)
	local wx, _, wz = getWorldTranslation(workArea.width)
	local hx, _, hz = getWorldTranslation(workArea.height)
	spec.isProcessing = spec.isWorking

	if not spec.useDirectPlanting then
		local area, _ = FSDensityMapUtil.updateSowingArea(spec.workAreaParameters.seedsFruitType, sx, sz, wx, wz, hx, hz, spec.workAreaParameters.fieldGroundType, spec.workAreaParameters.angle, nil)
		changedArea = changedArea + area
	else
		local area, _ = FSDensityMapUtil.updateDirectSowingArea(spec.workAreaParameters.seedsFruitType, sx, sz, wx, wz, hx, hz, spec.workAreaParameters.fieldGroundType, spec.workAreaParameters.angle, nil)
		changedArea = changedArea + area
	end

	if spec.isWorking then
		spec.stoneLastState = FSDensityMapUtil.getStoneArea(sx, sz, wx, wz, hx, hz)
	else
		spec.stoneLastState = 0
	end

	spec.workAreaParameters.lastChangedArea = spec.workAreaParameters.lastChangedArea + changedArea
	spec.workAreaParameters.lastStatsArea = spec.workAreaParameters.lastStatsArea + changedArea
	spec.workAreaParameters.lastTotalArea = spec.workAreaParameters.lastTotalArea + totalArea

	FSDensityMapUtil.eraseTireTrack(sx, sz, wx, wz, hx, hz)
	self:updateMissionSowingWarning(sx, sz)

	return changedArea, totalArea
end

function SowingMachine:updateMissionSowingWarning(x, z)
	local spec = self.spec_sowingMachine
	spec.showWrongFruitForMissionWarning = false

	if self:getLastTouchedFarmlandFarmId() == 0 then
		local mission = g_missionManager:getMissionAtWorldPosition(x, z)

		if mission ~= nil and mission.type.name == "sow" and mission.fruitType ~= spec.workAreaParameters.seedsFruitType then
			spec.showWrongFruitForMissionWarning = true
		end
	end
end

function SowingMachine:getUseSowingMachineAIRequirements()
	return self:getAIRequiresTurnOn() or self:getIsTurnedOn()
end

function SowingMachine:setFillTypeSourceDisplayFillType(fillType)
	local spec = self.spec_sowingMachine

	if spec.fillTypeSources[FillType.SEEDS] ~= nil then
		for _, src in ipairs(spec.fillTypeSources[FillType.SEEDS]) do
			local vehicle = src.vehicle

			if vehicle:getFillUnitFillLevel(src.fillUnitIndex) > 0 and vehicle:getFillUnitFillType(src.fillUnitIndex) == FillType.SEEDS then
				vehicle:setFillUnitFillTypeToDisplay(src.fillUnitIndex, fillType)

				break
			end
		end
	end
end

function SowingMachine:getDrawFirstFillText(superFunc)
	local spec = self.spec_sowingMachine

	if self.isClient and self:getIsActiveForInput() and self:getIsSelected() and self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 and self:getFillUnitCapacity(spec.fillUnitIndex) ~= 0 then
		return true
	end

	return superFunc(self)
end

function SowingMachine:getAreControlledActionsAllowed(superFunc)
	local spec = self.spec_sowingMachine

	if spec.requiresFilling and self:getFillUnitFillLevel(spec.fillUnitIndex) <= 0 and self:getFillUnitCapacity(spec.fillUnitIndex) ~= 0 then
		return false, g_i18n:getText("info_firstFillTheTool")
	end

	return superFunc(self)
end

function SowingMachine:getFillUnitAllowsFillType(superFunc, fillUnitIndex, fillType)
	if superFunc(self, fillUnitIndex, fillType) then
		return true
	end

	local spec = self.spec_fillUnit

	if spec.fillUnits[fillUnitIndex] ~= nil and self:getFillUnitSupportsFillType(fillUnitIndex, fillType) and (fillType == FillType.SEEDS or spec.fillUnits[fillUnitIndex].fillType == FillType.SEEDS) then
		return true
	end

	return false
end

function SowingMachine:getCanToggleTurnedOn(superFunc)
	local spec = self.spec_sowingMachine

	if not spec.needsActivation then
		return false
	end

	return superFunc(self)
end

function SowingMachine:getCanPlantOutsideSeason()
	return false
end

function SowingMachine:getAllowFillFromAir(superFunc)
	local spec = self.spec_sowingMachine

	if self:getIsTurnedOn() and not spec.allowFillFromAirWhileTurnedOn then
		return false
	end

	return superFunc(self)
end

function SowingMachine:getDirectionSnapAngle(superFunc)
	local spec = self.spec_sowingMachine
	local seedsFruitType = spec.seeds[spec.currentSeed]
	local desc = g_fruitTypeManager:getFruitTypeByIndex(seedsFruitType)
	local snapAngle = 0

	if desc ~= nil then
		snapAngle = desc.directionSnapAngle
	end

	return math.max(snapAngle, superFunc(self))
end

function SowingMachine:addFillUnitFillLevel(superFunc, farmId, fillUnitIndex, fillLevelDelta, fillType, toolType, fillInfo)
	local spec = self.spec_sowingMachine

	if fillUnitIndex == spec.fillUnitIndex then
		if self:getFillUnitSupportsFillType(fillUnitIndex, fillType) then
			fillType = FillType.SEEDS

			self:setFillUnitForcedMaterialFillType(fillUnitIndex, fillType)
		end

		local fruitType = spec.seeds[spec.currentSeed]

		if fruitType ~= nil then
			local seedsFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitType)

			if seedsFillType ~= nil and self:getFillUnitSupportsFillType(fillUnitIndex, seedsFillType) then
				self:setFillUnitForcedMaterialFillType(fillUnitIndex, seedsFillType)
			end
		end
	end

	return superFunc(self, farmId, fillUnitIndex, fillLevelDelta, fillType, toolType, fillInfo)
end

function SowingMachine:doCheckSpeedLimit(superFunc)
	local spec = self.spec_sowingMachine

	return superFunc(self) or self:getIsImplementChainLowered() and (not spec.needsActivation or self:getIsTurnedOn())
end

function SowingMachine:getDirtMultiplier(superFunc)
	local spec = self.spec_sowingMachine
	local multiplier = superFunc(self)

	if self.movingDirection > 0 and spec.isWorking and (not spec.needsActivation or self:getIsTurnedOn()) then
		multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return multiplier
end

function SowingMachine:getWearMultiplier(superFunc)
	local spec = self.spec_sowingMachine
	local multiplier = superFunc(self)

	if self.movingDirection > 0 and spec.isWorking and (not spec.needsActivation or self:getIsTurnedOn()) then
		local stoneMultiplier = 1

		if spec.stoneLastState ~= 0 and spec.stoneWearMultiplierData ~= nil then
			stoneMultiplier = spec.stoneWearMultiplierData[spec.stoneLastState] or 1
		end

		multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * stoneMultiplier
	end

	return multiplier
end

function SowingMachine:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)

	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.SOWINGMACHINE
	end

	return retValue
end

function SowingMachine:getCanBeSelected(superFunc)
	return true
end

function SowingMachine:getCanAIImplementContinueWork(superFunc)
	local canContinue, stopAI, stopReason = superFunc(self)

	if not canContinue then
		return false, stopAI, stopReason
	end

	if not self:getCanPlantOutsideSeason() then
		local spec = self.spec_sowingMachine

		if not g_currentMission.growthSystem:canFruitBePlanted(spec.workAreaParameters.seedsFruitType) then
			return false, true, AIMessageErrorWrongSeason.new()
		end
	end

	return canContinue, stopAI, stopReason
end

function SowingMachine:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_sowingMachine

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection and table.getn(spec.seeds) > 1 then
			local _, actionEventId = self:addActionEvent(spec.actionEvents, spec.changeSeedInputButton, self, SowingMachine.actionEventToggleSeedType, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			SowingMachine.updateChooseSeedActionEvent(self)

			_, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.TOGGLE_SEEDS_BACK, self, SowingMachine.actionEventToggleSeedTypeBack, false, true, false, true, nil)

			g_inputBinding:setActionEventTextVisibility(actionEventId, false)
		end
	end
end

function SowingMachine:updateChooseSeedActionEvent()
	local spec = self.spec_sowingMachine
	local actionEvent = spec.actionEvents[spec.changeSeedInputButton]

	if actionEvent ~= nil then
		local additionalText = ""
		local fillType = g_fillTypeManager:getFillTypeByIndex(g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.seeds[spec.currentSeed]))

		if fillType ~= nil and fillType ~= FillType.UNKNOWN then
			additionalText = string.format(" (%s)", fillType.title)
		end

		g_inputBinding:setActionEventText(actionEvent.actionEventId, string.format("%s%s", g_i18n:getText("action_chooseSeed"), additionalText))
	end
end

function SowingMachine:onTurnedOn()
	if self.isClient then
		local spec = self.spec_sowingMachine

		g_soundManager:playSample(spec.samples.airBlower)
		g_animationManager:startAnimations(spec.animationNodes)
	end

	SowingMachine.updateAiParameters(self)
end

function SowingMachine:onTurnedOff()
	if self.isClient then
		local spec = self.spec_sowingMachine

		g_soundManager:stopSample(spec.samples.airBlower)
		g_animationManager:stopAnimations(spec.animationNodes)
	end

	SowingMachine.updateAiParameters(self)
end

function SowingMachine:onStartWorkAreaProcessing(dt)
	local spec = self.spec_sowingMachine
	spec.isWorking = false
	spec.isProcessing = false
	local seedsFruitType = spec.seeds[spec.currentSeed]
	local dx, _, dz = localDirectionToWorld(spec.directionNode, 0, 0, 1)
	local angleRad = MathUtil.getYRotationFromDirection(dx, dz)
	local desc = g_fruitTypeManager:getFruitTypeByIndex(seedsFruitType)

	if desc ~= nil and desc.directionSnapAngle ~= 0 then
		angleRad = math.floor(angleRad / desc.directionSnapAngle + 0.5) * desc.directionSnapAngle
	end

	local angle = FSDensityMapUtil.convertToDensityMapAngle(angleRad, g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
	local seedsVehicle, seedsVehicleFillUnitIndex, seedsVehicleUnloadInfoIndex = nil

	if self:getFillUnitFillLevel(spec.fillUnitIndex) > 0 then
		seedsVehicle = self
		seedsVehicleFillUnitIndex = spec.fillUnitIndex
		seedsVehicleUnloadInfoIndex = spec.unloadInfoIndex
	elseif spec.fillTypeSources[FillType.SEEDS] ~= nil then
		for _, src in ipairs(spec.fillTypeSources[FillType.SEEDS]) do
			local vehicle = src.vehicle

			if vehicle:getFillUnitFillLevel(src.fillUnitIndex) > 0 and vehicle:getFillUnitFillType(src.fillUnitIndex) == FillType.SEEDS then
				seedsVehicle = vehicle
				seedsVehicleFillUnitIndex = src.fillUnitIndex

				break
			end
		end
	end

	if seedsVehicle ~= nil and seedsVehicle ~= self then
		local fillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(seedsFruitType)

		seedsVehicle:setFillUnitFillTypeToDisplay(seedsVehicleFillUnitIndex, fillType)
	end

	local isTurnedOn = self:getIsTurnedOn()
	local canFruitBePlanted = false

	if desc.terrainDataPlaneId ~= nil then
		canFruitBePlanted = true
	end

	if spec.showWrongFruitForMissionWarning then
		spec.showWrongFruitForMissionWarning = false
	end

	local isPlantingSeason = true

	if not self:getCanPlantOutsideSeason() then
		isPlantingSeason = g_currentMission.growthSystem:canFruitBePlanted(seedsFruitType)
	end

	spec.showFruitCanNotBePlantedWarning = not canFruitBePlanted
	spec.showWrongPlantingTimeWarning = not isPlantingSeason and (isTurnedOn or not spec.needsActivation and self:getIsLowered())
	spec.workAreaParameters.isActive = not spec.needsActivation or isTurnedOn
	spec.workAreaParameters.canFruitBePlanted = canFruitBePlanted and isPlantingSeason
	spec.workAreaParameters.seedsFruitType = seedsFruitType
	spec.workAreaParameters.fieldGroundType = spec.fieldGroundType
	spec.workAreaParameters.angle = angle
	spec.workAreaParameters.seedsVehicle = seedsVehicle
	spec.workAreaParameters.seedsVehicleFillUnitIndex = seedsVehicleFillUnitIndex
	spec.workAreaParameters.seedsVehicleUnloadInfoIndex = seedsVehicleUnloadInfoIndex
	spec.workAreaParameters.lastTotalArea = 0
	spec.workAreaParameters.lastChangedArea = 0
	spec.workAreaParameters.lastStatsArea = 0
end

function SowingMachine:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self.spec_sowingMachine

	if self.isServer then
		local stats = g_farmManager:getFarmById(self:getLastTouchedFarmlandFarmId()).stats

		if spec.workAreaParameters.lastChangedArea > 0 then
			local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(spec.workAreaParameters.seedsFruitType)
			local lastHa = MathUtil.areaToHa(spec.workAreaParameters.lastChangedArea, g_currentMission:getFruitPixelsToSqm())
			local usage = fruitDesc.seedUsagePerSqm * lastHa * 10000
			local ha = MathUtil.areaToHa(spec.workAreaParameters.lastStatsArea, g_currentMission:getFruitPixelsToSqm())
			local damage = self:getVehicleDamage()

			if damage > 0 then
				usage = usage * (1 + damage * SowingMachine.DAMAGED_USAGE_INCREASE)
			end

			stats:updateStats("seedUsage", usage)
			stats:updateStats("sownHectares", ha)
			self:updateLastWorkedArea(spec.workAreaParameters.lastStatsArea)

			if not self:getIsAIActive() or not g_currentMission.missionInfo.helperBuySeeds then
				local vehicle = spec.workAreaParameters.seedsVehicle
				local fillUnitIndex = spec.workAreaParameters.seedsVehicleFillUnitIndex
				local unloadInfoIndex = spec.workAreaParameters.seedsVehicleUnloadInfoIndex
				local fillType = vehicle:getFillUnitFillType(fillUnitIndex)
				local unloadInfo = nil

				if vehicle.getFillVolumeUnloadInfo ~= nil then
					unloadInfo = vehicle:getFillVolumeUnloadInfo(unloadInfoIndex)
				end

				vehicle:addFillUnitFillLevel(self:getOwnerFarmId(), fillUnitIndex, -usage, fillType, ToolType.UNDEFINED, unloadInfo)
			else
				local price = usage * g_currentMission.economyManager:getCostPerLiter(FillType.SEEDS, false) * 1.5

				stats:updateStats("expenses", price)
				g_currentMission:addMoney(-price, self:getOwnerFarmId(), MoneyType.PURCHASE_SEEDS)
			end
		end

		self:updateLastWorkedArea(0)
		stats:updateStats("sownTime", dt / 60000)
	end

	if self.isClient then
		if spec.isWorking then
			if not spec.isWorkSamplePlaying then
				g_soundManager:playSample(spec.samples.work)

				spec.isWorkSamplePlaying = true
			end
		elseif spec.isWorkSamplePlaying then
			g_soundManager:stopSample(spec.samples.work)

			spec.isWorkSamplePlaying = false
		end
	end
end

function SowingMachine:onDeactivate()
	local spec = self.spec_sowingMachine

	if self.isClient then
		g_soundManager:stopSamples(spec.samples)

		spec.isWorkSamplePlaying = false
	end
end

function SowingMachine:onStateChange(state, data)
	if state == Vehicle.STATE_CHANGE_ATTACH or state == Vehicle.STATE_CHANGE_DETACH or Vehicle.STATE_CHANGE_FILLTYPE_CHANGE then
		local spec = self.spec_sowingMachine
		spec.fillTypeSources = {}

		if FillType.SEEDS ~= nil then
			spec.fillTypeSources[FillType.SEEDS] = {}
			local root = self.rootVehicle

			FillUnit.addFillTypeSources(spec.fillTypeSources, root, self, {
				FillType.SEEDS
			})

			local fillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.seeds[spec.currentSeed])

			self:setFillTypeSourceDisplayFillType(fillType)
		end
	end
end

function SowingMachine:onChangedFillType(fillUnitIndex, fillTypeIndex, oldFillTypeIndex)
	local spec = self.spec_sowingMachine

	if fillUnitIndex == spec.fillUnitIndex then
		g_animationManager:setFillType(spec.animationNodes, fillTypeIndex)
	end
end

function SowingMachine:updateAiParameters()
	local spec = self.spec_sowingMachine

	if self.addAITerrainDetailRequiredRange ~= nil then
		self:clearAITerrainDetailRequiredRange()
		self:clearAITerrainDetailProhibitedRange()
		self:clearAIFruitProhibitions()

		local isCultivatorAttached = false
		local isWeederAttached = false
		local isRollerAttached = false
		local vehicles = self.rootVehicle:getChildVehicles()

		for i = 1, #vehicles do
			if SpecializationUtil.hasSpecialization(Cultivator, vehicles[i].specializations) then
				isCultivatorAttached = true

				vehicles[i]:updateCultivatorAIRequirements()
			end

			if SpecializationUtil.hasSpecialization(Weeder, vehicles[i].specializations) then
				isWeederAttached = true

				vehicles[i]:updateWeederAIRequirements()
			end

			if SpecializationUtil.hasSpecialization(Roller, vehicles[i].specializations) then
				isRollerAttached = true

				vehicles[i]:updateRollerAIRequirements()
			end
		end

		if isCultivatorAttached then
			if self:getUseSowingMachineAIRequirements() then
				self:addAIGroundTypeRequirements(SowingMachine.AI_REQUIRED_GROUND_TYPES)
			end
		elseif isWeederAttached then
			if self:getUseSowingMachineAIRequirements() then
				self:clearAITerrainDetailRequiredRange()
				self:addAIGroundTypeRequirements(SowingMachine.AI_REQUIRED_GROUND_TYPES)
			end
		elseif isRollerAttached then
			if self:getUseSowingMachineAIRequirements() then
				self:clearAITerrainDetailRequiredRange()
				self:addAIGroundTypeRequirements(SowingMachine.AI_REQUIRED_GROUND_TYPES)
			end
		else
			self:addAIGroundTypeRequirements(SowingMachine.AI_REQUIRED_GROUND_TYPES)

			if spec.useDirectPlanting then
				self:addAIGroundTypeRequirements(SowingMachine.AI_OUTPUT_GROUND_TYPES)
			end
		end

		if self:getUseSowingMachineAIRequirements() then
			local fruitTypeIndex = spec.seeds[spec.currentSeed]
			local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)

			if fruitTypeDesc ~= nil then
				self:setAIFruitProhibitions(fruitTypeIndex, 0, fruitTypeDesc.maxHarvestingGrowthState)
			end
		end
	end
end

function SowingMachine.getDefaultSpeedLimit()
	return 15
end

function SowingMachine:actionEventToggleSeedType(actionName, inputValue, callbackState, isAnalog)
	if self:getIsSeedChangeAllowed() then
		self:changeSeedIndex(1)
	end
end

function SowingMachine:actionEventToggleSeedTypeBack(actionName, inputValue, callbackState, isAnalog)
	if self:getIsSeedChangeAllowed() then
		self:changeSeedIndex(-1)
	end
end

function SowingMachine.loadSpecValueSeedFillTypes(xmlFile, customEnvironment)
	local categories = Utils.getNoNil(xmlFile:getValue("vehicle.storeData.specs.seedFruitTypeCategories"), xmlFile:getValue("vehicle.sowingMachine.seedFruitTypeCategories"))
	local names = Utils.getNoNil(xmlFile:getValue("vehicle.storeData.specs.seedFruitTypes"), xmlFile:getValue("vehicle.sowingMachine.seedFruitTypes"))

	return {
		categories = categories,
		names = names
	}
end

function SowingMachine.getSpecValueSeedFillTypes(storeItem, realItem)
	local fruitTypes = nil

	if storeItem.specs.seedFillTypes ~= nil then
		local fruits = storeItem.specs.seedFillTypes

		if fruits.categories ~= nil and fruits.names == nil then
			fruitTypes = g_fruitTypeManager:getFillTypesByFruitTypeCategoryName(fruits.categories, nil)
		elseif fruits.categories == nil and fruits.names ~= nil then
			fruitTypes = g_fruitTypeManager:getFillTypesByFruitTypeNames(fruits.names, nil)
		end

		if fruitTypes ~= nil then
			return fruitTypes
		end
	end

	return nil
end
