Roller = {
	AI_REQUIRED_GROUND_TYPES = {
		FieldGroundType.STUBBLE_TILLAGE,
		FieldGroundType.CULTIVATED,
		FieldGroundType.SEEDBED,
		FieldGroundType.PLOWED,
		FieldGroundType.SOWN,
		FieldGroundType.DIRECT_SOWN,
		FieldGroundType.PLANTED,
		FieldGroundType.RIDGE,
		FieldGroundType.CULTIVATED
	},
	AI_REQUIRED_GROUND_TYPES_GRASS = {
		FieldGroundType.GRASS,
		FieldGroundType.GRASS_CUT
	}
}

function Roller.initSpecialization()
	g_configurationManager:addConfigurationType("roller", g_i18n:getText("configuration_design"), "roller", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)
	g_workAreaTypeManager:addWorkAreaType("roller", false)

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Roller")
	Roller.registerRollerXMLPaths(schema, "vehicle.roller")
	Roller.registerRollerXMLPaths(schema, "vehicle.roller.rollerConfigurations.rollerConfiguration(?).roller")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.roller.rollerConfigurations.rollerConfiguration(?)")
	schema:setXMLSpecializationType()
end

function Roller.registerRollerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".directionNode#node", "Roller direction node")
	schema:register(XMLValueType.BOOL, basePath .. "#onlyActiveWhenLowered", "Only active when lowered", true)
	schema:register(XMLValueType.BOOL, basePath .. "#isSoilRoller", "If roller is for soil", true)
	schema:register(XMLValueType.BOOL, basePath .. "#isGrassRoller", "If roller is for grassland", false)
	schema:register(XMLValueType.BOOL, basePath .. "#usingAIRequirements", "Tool using roller ai requirements", true)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "work")
end

function Roller.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(WorkArea, specializations)
end

function Roller.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processRollerArea", Roller.processRollerArea)
	SpecializationUtil.registerFunction(vehicleType, "updateRollerAIRequirements", Roller.updateRollerAIRequirements)
end

function Roller.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Roller.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoGroundManipulation", Roller.getDoGroundManipulation)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Roller.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Roller.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Roller.getIsWorkAreaActive)
end

function Roller.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Roller)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Roller)
end

function Roller:onLoad(savegame)
	local spec = self.spec_roller

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.rollerSound", "vehicle.roller.sounds.work")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.onlyActiveWhenLowered#value", "vehicle.roller#onlyActiveWhenLowered")

	local rollerConfigurationId = Utils.getNoNil(self.configurations.roller, 1)
	local configKey = string.format("vehicle.roller.rollerConfigurations.rollerConfiguration(%d).roller", rollerConfigurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.roller.rollerConfigurations.rollerConfiguration", rollerConfigurationId, self.components, self)

	if not self.xmlFile:hasProperty(configKey) then
		configKey = "vehicle.roller"
	end

	spec.directionNode = self.xmlFile:getValue(configKey .. ".directionNode#node", self.components[1].node, self.components, self.i3dMappings)

	if self.isClient then
		spec.samples = {}
		spec.isWorkSamplePlaying = false
		spec.samples.work = g_soundManager:loadSampleFromXML(self.xmlFile, configKey .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
	end

	spec.isSoilRoller = self.xmlFile:getValue(configKey .. "#isSoilRoller")
	spec.isGrassRoller = self.xmlFile:getValue(configKey .. "#isGrassRoller")

	if spec.isSoilRoller == nil and spec.isGrassRoller == nil then
		spec.isSoilRoller = true
		spec.isGrassRoller = false
	else
		if spec.isGrassRoller == nil then
			spec.isGrassRoller = false
		end

		if spec.isSoilRoller == nil then
			spec.isSoilRoller = false
		end
	end

	spec.usingAIRequirements = self.xmlFile:getValue(configKey .. "#usingAIRequirements", true)
	spec.onlyActiveWhenLowered = self.xmlFile:getValue(configKey .. "#onlyActiveWhenLowered", true)
	spec.startActivationTimeout = 2000
	spec.startActivationTime = 0
	spec.isWorking = false
	spec.angle = 0

	self:updateRollerAIRequirements()

	spec.dirtyFlag = self:getNextDirtyFlag()
end

function Roller:onDelete()
	local spec = self.spec_roller

	g_soundManager:deleteSamples(spec.samples)
end

function Roller:processRollerArea(workArea, dt)
	local spec = self.spec_roller
	local xs, _, zs = getWorldTranslation(workArea.start)
	local xw, _, zw = getWorldTranslation(workArea.width)
	local xh, _, zh = getWorldTranslation(workArea.height)
	local realArea = nil

	if spec.isGrassRoller then
		realArea, _ = FSDensityMapUtil.updateGrassRollerArea(xs, zs, xw, zw, xh, zh, not spec.isSoilRoller)
	end

	if spec.isSoilRoller then
		realArea, _ = FSDensityMapUtil.updateRollerArea(xs, zs, xw, zw, xh, zh, spec.angle)
	end

	FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)

	spec.isWorking = self:getLastSpeed() > 0.5

	return realArea
end

function Roller:updateRollerAIRequirements()
	if self.clearAITerrainDetailRequiredRange ~= nil then
		local spec = self.spec_roller

		if not spec.usingAIRequirements then
			return
		end

		local hasSowingMachine = false

		if SpecializationUtil.hasSpecialization(SowingMachine, self.specializations) and self:getUseSowingMachineAIRequirements() then
			hasSowingMachine = true
		end

		self:clearAIFruitRequirements()
		self:clearAIFruitProhibitions()
		self:clearAITerrainDetailRequiredRange()

		if not hasSowingMachine then
			if spec.isGrassRoller and not spec.isSoilRoller then
				self:addAIGroundTypeRequirements(Roller.AI_REQUIRED_GROUND_TYPES_GRASS)

				local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.GRASS)

				if fruitTypeDesc.terrainDataPlaneId ~= nil then
					self:setAIFruitRequirements(fruitTypeDesc.index, 2, fruitTypeDesc.cutState + 1)
				end
			end

			if spec.isSoilRoller then
				self:addAIGroundTypeRequirements(Roller.AI_REQUIRED_GROUND_TYPES)

				for fruitTypeIndex, fruitType in pairs(g_fruitTypeManager:getFruitTypes()) do
					if fruitType.terrainDataPlaneId ~= nil and (not spec.isGrassRoller or fruitTypeIndex ~= FruitType.GRASS) then
						self:addAIFruitProhibitions(fruitType.index, 2, 15)
					end
				end

				if spec.isGrassRoller then
					self:addAIGroundTypeRequirements(Roller.AI_REQUIRED_GROUND_TYPES_GRASS)

					local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.GRASS)

					if fruitTypeDesc.terrainDataPlaneId ~= nil then
						self:addAIFruitProhibitions(fruitTypeDesc.index, 1, 1)
					end
				end
			end
		end
	end
end

function Roller:doCheckSpeedLimit(superFunc)
	local spec = self.spec_roller

	return superFunc(self) or spec.isWorking
end

function Roller:getDoGroundManipulation(superFunc)
	local spec = self.spec_roller

	return superFunc(self) and spec.isWorking
end

function Roller:getDirtMultiplier(superFunc)
	local spec = self.spec_roller
	local multiplier = superFunc(self)

	if spec.isWorking then
		multiplier = multiplier + self:getWorkDirtMultiplier()
	end

	return multiplier
end

function Roller:getWearMultiplier(superFunc)
	local spec = self.spec_roller
	local multiplier = superFunc(self)

	if spec.isWorking then
		multiplier = multiplier + self:getWorkWearMultiplier()
	end

	return multiplier
end

function Roller:getIsWorkAreaActive(superFunc, workArea)
	if workArea.type == WorkAreaType.ROLLER then
		local spec = self.spec_roller

		if g_currentMission.time < spec.startActivationTime then
			return false
		end

		if spec.onlyActiveWhenLowered and not self:getIsLowered() then
			return false
		end
	end

	return superFunc(self, workArea)
end

function Roller:onStartWorkAreaProcessing(dt)
	local spec = self.spec_roller
	local dx, _, dz = localDirectionToWorld(spec.directionNode, 0, 0, 1)
	spec.angle = FSDensityMapUtil.convertToDensityMapAngle(MathUtil.getYRotationFromDirection(dx, dz), g_currentMission.fieldGroundSystem:getGroundAngleMaxValue())
	spec.isWorking = false
end

function Roller:onEndWorkAreaProcessing(dt, hasProcessed)
	local spec = self.spec_roller

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

function Roller:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_roller
	spec.startActivationTime = g_currentMission.time + spec.startActivationTimeout
end

function Roller:onDeactivate()
	local spec = self.spec_roller

	g_soundManager:stopSample(spec.samples.work)

	spec.isWorkSamplePlaying = false
end

function Roller.getDefaultSpeedLimit()
	return 15
end
