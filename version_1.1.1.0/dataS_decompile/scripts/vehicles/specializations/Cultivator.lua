Cultivator = {
	AI_REQUIRED_GROUND_TYPES_FLAT = {
		FieldGroundType.CULTIVATED,
		FieldGroundType.PLOWED,
		FieldGroundType.ROLLED_SEEDBED,
		FieldGroundType.SOWN,
		FieldGroundType.PLANTED,
		FieldGroundType.RIDGE,
		FieldGroundType.ROLLER_LINES,
		FieldGroundType.HARVEST_READY,
		FieldGroundType.HARVEST_READY_OTHER,
		FieldGroundType.GRASS,
		FieldGroundType.GRASS_CUT
	},
	AI_REQUIRED_GROUND_TYPES_DEEP = {
		FieldGroundType.STUBBLE_TILLAGE,
		FieldGroundType.SEEDBED,
		FieldGroundType.PLOWED,
		FieldGroundType.ROLLED_SEEDBED,
		FieldGroundType.SOWN,
		FieldGroundType.PLANTED,
		FieldGroundType.RIDGE,
		FieldGroundType.ROLLER_LINES,
		FieldGroundType.HARVEST_READY,
		FieldGroundType.HARVEST_READY_OTHER,
		FieldGroundType.GRASS,
		FieldGroundType.GRASS_CUT
	},
	AI_OUTPUT_GROUND_TYPES = {
		FieldGroundType.STUBBLE_TILLAGE,
		FieldGroundType.CULTIVATED,
		FieldGroundType.SEEDBED,
		FieldGroundType.ROLLED_SEEDBED
	},
	initSpecialization = function ()
		g_workAreaTypeManager:addWorkAreaType("cultivator", true)

		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("Cultivator")
		schema:register(XMLValueType.NODE_INDEX, "vehicle.cultivator.directionNode#node", "Direction node")
		schema:register(XMLValueType.BOOL, "vehicle.cultivator.onlyActiveWhenLowered#value", "Only active when lowered", true)
		schema:register(XMLValueType.BOOL, "vehicle.cultivator#isSubsoiler", "Is subsoiler", false)
		schema:register(XMLValueType.BOOL, "vehicle.cultivator#useDeepMode", "If true the implement acts like a cultivator. If false it's a discharrow or seedbed combination", true)
		schema:register(XMLValueType.BOOL, "vehicle.cultivator#isPowerHarrow", "If this is set the cultivator works standalone like a cultivator, but as soon as a sowing machine is attached to it, it's only using the sowing machine", false)
		SoundManager.registerSampleXMLPaths(schema, "vehicle.cultivator.sounds", "work")
		schema:setXMLSpecializationType()
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(WorkArea, specializations)
	end
}

function Cultivator.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processCultivatorArea", Cultivator.processCultivatorArea)
	SpecializationUtil.registerFunction(vehicleType, "getCultivatorLimitToField", Cultivator.getCultivatorLimitToField)
	SpecializationUtil.registerFunction(vehicleType, "getUseCultivatorAIRequirements", Cultivator.getUseCultivatorAIRequirements)
	SpecializationUtil.registerFunction(vehicleType, "updateCultivatorAIRequirements", Cultivator.updateCultivatorAIRequirements)
	SpecializationUtil.registerFunction(vehicleType, "updateCultivatorEnabledState", Cultivator.updateCultivatorEnabledState)
	SpecializationUtil.registerFunction(vehicleType, "getIsCultivationEnabled", Cultivator.getIsCultivationEnabled)
end

function Cultivator.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Cultivator.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Cultivator.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Cultivator.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Cultivator.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Cultivator.getIsWorkAreaActive)
end

function Cultivator.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Cultivator)
	SpecializationUtil.registerEventListener(vehicleType, "onStateChange", Cultivator)
end

function Cultivator:onLoad(savegame)
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cultivator.directionNode#index", "vehicle.cultivator.directionNode#node")

	if self:getGroundReferenceNodeFromIndex(1) == nil then
		print("Warning: No ground reference nodes in  " .. self.configFileName)
	end

	local spec = self.spec_cultivator

	if self.isClient then
		spec.samples = {
			work = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.cultivator.sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.isWorkSamplePlaying = false
	end

	spec.directionNode = self.xmlFile:getValue("vehicle.cultivator.directionNode#node", self.components[1].node, self.components, self.i3dMappings)
	spec.onlyActiveWhenLowered = self.xmlFile:getValue("vehicle.cultivator.onlyActiveWhenLowered#value", true)
	spec.isSubsoiler = self.xmlFile:getValue("vehicle.cultivator#isSubsoiler", false)
	spec.isPowerHarrow = self.xmlFile:getValue("vehicle.cultivator#isPowerHarrow", false)
	spec.useDeepMode = self.xmlFile:getValue("vehicle.cultivator#useDeepMode", true)

	self:updateCultivatorAIRequirements()

	spec.isEnabled = true
	spec.startActivationTimeout = 2000
	spec.startActivationTime = 0
	spec.hasGroundContact = false
	spec.isWorking = false
	spec.limitToField = true
	spec.workAreaParameters = {
		limitToField = self:getCultivatorLimitToField(),
		angle = 0,
		lastChangedArea = 0,
		lastStatsArea = 0,
		lastTotalArea = 0
	}
end

function Cultivator:onDelete()
	local spec = self.spec_cultivator

	g_soundManager:deleteSamples(spec.samples)
end

function Cultivator:processCultivatorArea(workArea, dt)
	local spec = self.spec_cultivator
	local realArea = 0
	local area = 0

	if spec.isEnabled then
		local xs, _, zs = getWorldTranslation(workArea.start)
		local xw, _, zw = getWorldTranslation(workArea.width)
		local xh, _, zh = getWorldTranslation(workArea.height)
		local params = spec.workAreaParameters

		if spec.useDeepMode then
			realArea, area = FSDensityMapUtil.updateCultivatorArea(xs, zs, xw, zw, xh, zh, not params.limitToField, params.limitFruitDestructionToField, params.angle, nil)
			realArea = realArea + FSDensityMapUtil.updateVineCultivatorArea(xs, zs, xw, zw, xh, zh)
		else
			realArea, area = FSDensityMapUtil.updateDiscHarrowArea(xs, zs, xw, zw, xh, zh, not params.limitToField, params.limitFruitDestructionToField, params.angle, nil)
			realArea = realArea + FSDensityMapUtil.updateVineCultivatorArea(xs, zs, xw, zw, xh, zh)
		end

		params.lastChangedArea = params.lastChangedArea + realArea
		params.lastStatsArea = params.lastStatsArea + realArea
		params.lastTotalArea = params.lastTotalArea + area

		if spec.isSubsoiler then
			FSDensityMapUtil.updateSubsoilerArea(xs, zs, xw, zw, xh, zh)
		end

		FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)
	end

	spec.isWorking = self:getLastSpeed() > 0.5

	return realArea, area
end

function Cultivator:getCultivatorLimitToField()
	return self.spec_cultivator.limitToField
end

function Cultivator:getUseCultivatorAIRequirements()
	return true
end

function Cultivator:updateCultivatorAIRequirements()
	if self:getUseCultivatorAIRequirements() and self.addAITerrainDetailRequiredRange ~= nil then
		local hasSowingMachine = false
		local excludedType1, excludedType2 = nil
		local vehicles = self.rootVehicle:getChildVehicles()

		for i = 1, #vehicles do
			if SpecializationUtil.hasSpecialization(SowingMachine, vehicles[i].specializations) and (vehicles[i]:getAIRequiresTurnOn() or vehicles[i]:getUseSowingMachineAIRequirements()) then
				hasSowingMachine = true
			end

			if SpecializationUtil.hasSpecialization(Roller, vehicles[i].specializations) then
				excludedType1 = FieldGroundType.ROLLER_LINES
				excludedType2 = FieldGroundType.ROLLED_SEEDBED
			end
		end

		if not hasSowingMachine then
			if self.spec_cultivator.useDeepMode then
				self:addAIGroundTypeRequirements(Cultivator.AI_REQUIRED_GROUND_TYPES_DEEP, excludedType1, excludedType2)
			else
				self:addAIGroundTypeRequirements(Cultivator.AI_REQUIRED_GROUND_TYPES_FLAT, excludedType1, excludedType2)
			end
		else
			self:clearAITerrainDetailRequiredRange()
		end
	end
end

function Cultivator:updateCultivatorEnabledState()
	local spec = self.spec_cultivator

	if spec.isPowerHarrow then
		local vehicles = self:getChildVehicles()

		for i = 1, #vehicles do
			if SpecializationUtil.hasSpecialization(SowingMachine, vehicles[i].specializations) then
				spec.isEnabled = false

				return
			end
		end
	end

	spec.isEnabled = true
end

function Cultivator:getIsCultivationEnabled()
	return self.spec_cultivator.isEnabled
end

function Cultivator:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsImplementChainLowered()
end

function Cultivator:getDirtMultiplier(superFunc)
	local spec = self.spec_cultivator
	local multiplier = superFunc(self)

	if spec.isWorking then
		multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / spec.speedLimit
	end

	return multiplier
end

function Cultivator:getWearMultiplier(superFunc)
	local spec = self.spec_cultivator
	local multiplier = superFunc(self)

	if spec.isWorking then
		multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / spec.speedLimit
	end

	return multiplier
end

function Cultivator:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)

	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.CULTIVATOR
	end

	return retValue
end

function Cultivator:getIsWorkAreaActive(superFunc, workArea)
	if workArea.type == WorkAreaType.CULTIVATOR then
		local spec = self.spec_cultivator

		if g_currentMission.time < spec.startActivationTime then
			return false
		end

		if spec.onlyActiveWhenLowered and self.getIsLowered ~= nil and not self:getIsLowered(false) then
			return false
		end
	end

	return superFunc(self, workArea)
end

function Cultivator:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_cultivator
	spec.startActivationTime = g_currentMission.time + spec.startActivationTimeout
end

function Cultivator:onDeactivate()
	if self.isClient then
		local spec = self.spec_cultivator

		g_soundManager:stopSamples(spec.samples)

		spec.isWorkSamplePlaying = false
	end
end

function Cultivator:onStartWorkAreaProcessing(dt)
	local spec = self.spec_cultivator
	spec.isWorking = false
	local limitToField = self:getCultivatorLimitToField()
	local limitFruitDestructionToField = limitToField

	if not g_currentMission:getHasPlayerPermission("createFields", self:getOwner()) then
		limitToField = true
		limitFruitDestructionToField = true
	end

	local dx, _, dz = localDirectionToWorld(spec.directionNode, 0, 0, 1)
	local angle = FSDensityMapUtil.convertToDensityMapAngle(MathUtil.getYRotationFromDirection(dx, dz), g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
	spec.workAreaParameters.limitToField = limitToField
	spec.workAreaParameters.limitFruitDestructionToField = limitFruitDestructionToField
	spec.workAreaParameters.angle = angle
	spec.workAreaParameters.lastChangedArea = 0
	spec.workAreaParameters.lastStatsArea = 0
	spec.workAreaParameters.lastTotalArea = 0
end

function Cultivator:onEndWorkAreaProcessing(dt)
	local spec = self.spec_cultivator

	if self.isServer then
		local lastStatsArea = spec.workAreaParameters.lastStatsArea

		if lastStatsArea > 0 then
			local ha = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
			local stats = g_currentMission:farmStats(self:getLastTouchedFarmlandFarmId())

			stats:updateStats("cultivatedHectares", ha)
			stats:updateStats("cultivatedTime", dt / 60000)
			self:updateLastWorkedArea(lastStatsArea)
		end
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

function Cultivator:onStateChange(state, data)
	if state == Vehicle.STATE_CHANGE_ATTACH or state == Vehicle.STATE_CHANGE_DETACH then
		self:updateCultivatorAIRequirements()
		self:updateCultivatorEnabledState()
	end
end

function Cultivator.getDefaultSpeedLimit()
	return 15
end
