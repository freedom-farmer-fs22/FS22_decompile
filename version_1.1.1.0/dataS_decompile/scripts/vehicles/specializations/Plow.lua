source("dataS/scripts/vehicles/specializations/events/PlowRotationEvent.lua")
source("dataS/scripts/vehicles/specializations/events/PlowLimitToFieldEvent.lua")

Plow = {
	AI_REQUIRED_GROUND_TYPES = {
		FieldGroundType.STUBBLE_TILLAGE,
		FieldGroundType.CULTIVATED,
		FieldGroundType.SEEDBED,
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
	},
	AI_OUTPUT_GROUND_TYPES = {
		FieldGroundType.PLOWED
	}
}

function Plow.initSpecialization()
	g_configurationManager:addConfigurationType("plow", g_i18n:getText("configuration_design"), "plow", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)
	g_workAreaTypeManager:addWorkAreaType("plow", true)

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Plow")
	Plow.registerXMLPaths(schema, "vehicle.plow")
	Plow.registerXMLPaths(schema, "vehicle.plow.plowConfigurations.plowConfiguration(?)")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.plow.plowConfigurations.plowConfiguration(?)")
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#disableOnTurn", "Disable while turning", true)
	schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#turnAnimLimit", "Turn animation limit", 0)
	schema:register(XMLValueType.FLOAT, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#turnAnimLimitSide", "Turn animation limit side", 0)
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#invertDirectionOnRotation", "Invert direction on rotation", true)
	schema:setXMLSpecializationType()

	local schemaSavegame = Vehicle.xmlSchemaSavegame

	schemaSavegame:register(XMLValueType.BOOL, "vehicles.vehicle(?).plow#rotationMax", "Rotation max.")
	schemaSavegame:register(XMLValueType.FLOAT, "vehicles.vehicle(?).plow#turnAnimTime", "Turn animation time")
end

function Plow.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.STRING, basePath .. ".rotationPart#turnAnimationName", "Turn animation name")
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#foldMinLimit", "Fold min. limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#foldMaxLimit", "Fold max. limit", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".rotationPart#limitFoldRotationMax", "Block folding if in max state")
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#foldRotationMinLimit", "Fold allow if inbetween this limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#foldRotationMaxLimit", "Fold allow if inbetween this limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#rotationFoldMinLimit", "Rotation allow if fold time inbetween this limit", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#rotationFoldMaxLimit", "Rotation allow if fold time inbetween this limit", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#detachMinLimit", "Detach is allowed if turn animation between these values", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".rotationPart#detachMaxLimit", "Detach is allowed if turn animation between these values", 1)
	schema:register(XMLValueType.BOOL, basePath .. ".rotationPart#rotationAllowedIfLowered", "Allow plow rotation if lowered", true)
	schema:register(XMLValueType.L10N_STRING, basePath .. ".rotationPart#detachWarning", "Warning to be displayed if not in correct turn state for detach", "warning_detachNotAllowedPlowTurn")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".directionNode#node", "Plow direction node")
	schema:register(XMLValueType.FLOAT, basePath .. ".ai#centerPosition", "Center position", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".ai#rotateToCenterHeadlandPos", "Rotate to center headland position", 0.5)
	schema:register(XMLValueType.FLOAT, basePath .. ".ai#rotateCompletelyHeadlandPos", "Rotate completely headland position", 0.5)
	schema:register(XMLValueType.BOOL, basePath .. ".rotateLeftToMax#value", "Rotate left to max", true)
	schema:register(XMLValueType.BOOL, basePath .. ".onlyActiveWhenLowered#value", "Only active when lowered", true)
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "turn")
	SoundManager.registerSampleXMLPaths(schema, basePath .. ".sounds", "work")
end

function Plow.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(WorkArea, specializations)
end

function Plow.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "processPlowArea", Plow.processPlowArea)
	SpecializationUtil.registerFunction(vehicleType, "setRotationMax", Plow.setRotationMax)
	SpecializationUtil.registerFunction(vehicleType, "setRotationCenter", Plow.setRotationCenter)
	SpecializationUtil.registerFunction(vehicleType, "setPlowLimitToField", Plow.setPlowLimitToField)
	SpecializationUtil.registerFunction(vehicleType, "getIsPlowRotationAllowed", Plow.getIsPlowRotationAllowed)
	SpecializationUtil.registerFunction(vehicleType, "getPlowLimitToField", Plow.getPlowLimitToField)
	SpecializationUtil.registerFunction(vehicleType, "getPlowForceLimitToField", Plow.getPlowForceLimitToField)
	SpecializationUtil.registerFunction(vehicleType, "setPlowAIRequirements", Plow.setPlowAIRequirements)
end

function Plow.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldAllowed", Plow.getIsFoldAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsFoldMiddleAllowed", Plow.getIsFoldMiddleAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Plow.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Plow.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Plow.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Plow.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getSpeedRotatingPartDirection", Plow.getSpeedRotatingPartDirection)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Plow.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Plow.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Plow.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanAIImplementContinueWork", Plow.getCanAIImplementContinueWork)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAIInvertMarkersOnTurn", Plow.getAIInvertMarkersOnTurn)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanBeSelected", Plow.getCanBeSelected)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isDetachAllowed", Plow.isDetachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowsLowering", Plow.getAllowsLowering)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIReadyToDrive", Plow.getIsAIReadyToDrive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsAIPreparingToDrive", Plow.getIsAIPreparingToDrive)
end

function Plow.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onRegisterActionEvents", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onPostAttach", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onPreDetach", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onDeactivate", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStartTurn", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementTurnProgress", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onStartAnimation", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onFinishAnimation", Plow)
	SpecializationUtil.registerEventListener(vehicleType, "onRootVehicleChanged", Plow)
end

function Plow:onLoad(savegame)
	if self:getGroundReferenceNodeFromIndex(1) == nil then
		print("Warning: No ground reference nodes in " .. self.configFileName)
	end

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.rotationPart", "vehicle.plow.rotationPart")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.ploughDirectionNode#index", "vehicle.plow.directionNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.rotateLeftToMax#value", "vehicle.plow.rotateLeftToMax#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.animTimeCenterPosition#value", "vehicle.plow.ai#centerPosition")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.aiPlough#rotateEarly", "vehicle.plow.ai#rotateCompletelyHeadlandPos")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.onlyActiveWhenLowered#value", "vehicle.plow.onlyActiveWhenLowered#value")

	local plowConfigurationId = self.configurations.plow or 1
	local configKey = string.format("vehicle.plow.plowConfigurations.plowConfiguration(%d)", plowConfigurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.plow.plowConfigurations.plowConfiguration", plowConfigurationId, self.components, self)

	if not self.xmlFile:hasProperty(configKey) then
		configKey = "vehicle.plow"
	end

	local spec = self.spec_plow
	spec.rotationPart = {
		turnAnimation = self.xmlFile:getValue(configKey .. ".rotationPart#turnAnimationName"),
		foldMinLimit = self.xmlFile:getValue(configKey .. ".rotationPart#foldMinLimit", 0),
		foldMaxLimit = self.xmlFile:getValue(configKey .. ".rotationPart#foldMaxLimit", 1),
		limitFoldRotationMax = self.xmlFile:getValue(configKey .. ".rotationPart#limitFoldRotationMax"),
		foldRotationMinLimit = self.xmlFile:getValue(configKey .. ".rotationPart#foldRotationMinLimit", 0),
		foldRotationMaxLimit = self.xmlFile:getValue(configKey .. ".rotationPart#foldRotationMaxLimit", 1),
		rotationFoldMinLimit = self.xmlFile:getValue(configKey .. ".rotationPart#rotationFoldMinLimit", 0),
		rotationFoldMaxLimit = self.xmlFile:getValue(configKey .. ".rotationPart#rotationFoldMaxLimit", 1),
		detachMinLimit = self.xmlFile:getValue(configKey .. ".rotationPart#detachMinLimit", 0),
		detachMaxLimit = self.xmlFile:getValue(configKey .. ".rotationPart#detachMaxLimit", 1),
		rotationAllowedIfLowered = self.xmlFile:getValue(configKey .. ".rotationPart#rotationAllowedIfLowered", true),
		detachWarning = string.format(self.xmlFile:getValue(configKey .. ".rotationPart#detachWarning", "warning_detachNotAllowedPlowTurn", self.customEnvironment, false))
	}
	spec.directionNode = self.xmlFile:getValue(configKey .. ".directionNode#node", self.components[1].node, self.components, self.i3dMappings)

	self:setPlowAIRequirements()

	spec.ai = {
		centerPosition = self.xmlFile:getValue(configKey .. ".ai#centerPosition", 0.5),
		rotateToCenterHeadlandPos = self.xmlFile:getValue(configKey .. ".ai#rotateToCenterHeadlandPos", 0.5),
		rotateCompletelyHeadlandPos = self.xmlFile:getValue(configKey .. ".ai#rotateCompletelyHeadlandPos", 0.5),
		lastHeadlandPosition = 0
	}
	spec.rotateLeftToMax = self.xmlFile:getValue(configKey .. ".rotateLeftToMax#value", true)
	spec.onlyActiveWhenLowered = self.xmlFile:getValue(configKey .. ".onlyActiveWhenLowered#value", true)
	spec.rotationMax = false
	spec.startActivationTimeout = 2000
	spec.startActivationTime = 0
	spec.lastPlowArea = 0
	spec.limitToField = true
	spec.forceLimitToField = false
	spec.wasTurnAnimationStopped = false
	spec.isWorking = false

	if self.isClient then
		spec.samples = {
			turn = g_soundManager:loadSampleFromXML(self.xmlFile, configKey .. ".sounds", "turn", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self),
			work = g_soundManager:loadSampleFromXML(self.xmlFile, configKey .. ".sounds", "work", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
		spec.isWorkSamplePlaying = false
	end

	spec.texts = {
		warningFoldingLowered = g_i18n:getText("warning_foldingNotWhileLowered"),
		warningFoldingPlowTurned = g_i18n:getText("warning_foldingNotWhilePlowTurned"),
		turnPlow = g_i18n:getText("action_turnPlow"),
		allowCreateFields = g_i18n:getText("action_allowCreateFields"),
		limitToFields = g_i18n:getText("action_limitToFields")
	}
	spec.workAreaParameters = {
		limitToField = self:getPlowLimitToField(),
		forceLimitToField = self:getPlowForceLimitToField(),
		angle = 0,
		lastChangedArea = 0,
		lastStatsArea = 0,
		lastTotalArea = 0
	}

	if not self.isClient then
		SpecializationUtil.removeEventListener(self, "onUpdate", Plow)
	end
end

function Plow:onPostLoad(savegame)
	if savegame ~= nil and not savegame.resetVehicles then
		local rotationMax = savegame.xmlFile:getValue(savegame.key .. ".plow#rotationMax")

		if rotationMax ~= nil and self:getIsPlowRotationAllowed() then
			local plowTurnAnimTime = savegame.xmlFile:getValue(savegame.key .. ".plow#turnAnimTime")

			self:setRotationMax(rotationMax, true, plowTurnAnimTime)

			if self.updateCylinderedInitial ~= nil then
				self:updateCylinderedInitial(false)
			end
		end
	end
end

function Plow:onDelete()
	local spec = self.spec_plow

	g_soundManager:deleteSamples(spec.samples)
end

function Plow:saveToXMLFile(xmlFile, key, usedModNames)
	local spec = self.spec_plow

	xmlFile:setValue(key .. "#rotationMax", spec.rotationMax)

	if spec.rotationPart.turnAnimation ~= nil and self.playAnimation ~= nil then
		local turnAnimTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		xmlFile:setValue(key .. "#turnAnimTime", turnAnimTime)
	end
end

function Plow:onReadStream(streamId, connection)
	local spec = self.spec_plow
	local rotationMax = streamReadBool(streamId)
	local turnAnimTime = nil

	if spec.rotationPart.turnAnimation ~= nil and self.playAnimation ~= nil then
		turnAnimTime = streamReadFloat32(streamId)
	end

	self:setRotationMax(rotationMax, true, turnAnimTime)

	if self.updateCylinderedInitial ~= nil then
		self:updateCylinderedInitial(false)
	end
end

function Plow:onWriteStream(streamId, connection)
	local spec = self.spec_plow

	streamWriteBool(streamId, spec.rotationMax)

	if spec.rotationPart.turnAnimation ~= nil and self.playAnimation ~= nil then
		local turnAnimTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		streamWriteFloat32(streamId, turnAnimTime)
	end
end

function Plow:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient then
		local spec = self.spec_plow
		local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]

		if actionEvent ~= nil then
			if not self:getPlowForceLimitToField() and g_currentMission:getHasPlayerPermission("createFields", self:getOwner()) then
				g_inputBinding:setActionEventActive(actionEvent.actionEventId, true)

				if self:getPlowLimitToField() then
					g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.allowCreateFields)
				else
					g_inputBinding:setActionEventText(actionEvent.actionEventId, spec.texts.limitToFields)
				end
			else
				g_inputBinding:setActionEventActive(actionEvent.actionEventId, false)
			end
		end

		if spec.rotationPart.turnAnimation ~= nil then
			actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA]

			if actionEvent ~= nil then
				g_inputBinding:setActionEventActive(actionEvent.actionEventId, self:getIsPlowRotationAllowed())
			end
		end
	end
end

function Plow:processPlowArea(workArea, dt)
	local spec = self.spec_plow
	local xs, _, zs = getWorldTranslation(workArea.start)
	local xw, _, zw = getWorldTranslation(workArea.width)
	local xh, _, zh = getWorldTranslation(workArea.height)
	local params = spec.workAreaParameters
	local changedArea, totalArea = FSDensityMapUtil.updatePlowArea(xs, zs, xw, zw, xh, zh, not params.limitToField, params.limitFruitDestructionToField, params.angle)
	changedArea = changedArea + FSDensityMapUtil.updateVineCultivatorArea(xs, zs, xw, zw, xh, zh)
	params.lastChangedArea = params.lastChangedArea + changedArea
	params.lastStatsArea = params.lastStatsArea + changedArea
	params.lastTotalArea = params.lastTotalArea + totalArea

	FSDensityMapUtil.eraseTireTrack(xs, zs, xw, zw, xh, zh)

	spec.isWorking = self:getLastSpeed() > 0.5

	return changedArea, totalArea
end

function Plow:setRotationMax(rotationMax, noEventSend, turnAnimationTime)
	if noEventSend == nil or noEventSend == false then
		if g_server ~= nil then
			g_server:broadcastEvent(PlowRotationEvent.new(self, rotationMax), nil, , self)
		else
			g_client:getServerConnection():sendEvent(PlowRotationEvent.new(self, rotationMax))
		end
	end

	local spec = self.spec_plow
	spec.rotationMax = rotationMax

	if spec.rotationPart.turnAnimation ~= nil then
		if turnAnimationTime == nil then
			local animTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

			if spec.rotationMax then
				self:playAnimation(spec.rotationPart.turnAnimation, 1, animTime, true)
			else
				self:playAnimation(spec.rotationPart.turnAnimation, -1, animTime, true)
			end
		else
			self:setAnimationTime(spec.rotationPart.turnAnimation, turnAnimationTime, true)
		end
	end
end

function Plow:setRotationCenter()
	local spec = self.spec_plow

	if spec.rotationPart.turnAnimation ~= nil then
		self:setAnimationStopTime(spec.rotationPart.turnAnimation, spec.ai.centerPosition)

		local animTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		if animTime < spec.ai.centerPosition then
			self:playAnimation(spec.rotationPart.turnAnimation, 1, animTime, true)
		elseif spec.ai.centerPosition < animTime then
			self:playAnimation(spec.rotationPart.turnAnimation, -1, animTime, true)
		end
	end
end

function Plow:setPlowLimitToField(plowLimitToField, noEventSend)
	local spec = self.spec_plow

	if spec.limitToField ~= plowLimitToField then
		if noEventSend == nil or noEventSend == false then
			if g_server ~= nil then
				g_server:broadcastEvent(PlowLimitToFieldEvent.new(self, plowLimitToField), nil, , self)
			else
				g_client:getServerConnection():sendEvent(PlowLimitToFieldEvent.new(self, plowLimitToField))
			end
		end

		spec.limitToField = plowLimitToField
		local actionEvent = spec.actionEvents[InputAction.IMPLEMENT_EXTRA3]

		if actionEvent ~= nil then
			local text = nil

			if spec.limitToField then
				text = spec.texts.allowCreateFields
			else
				text = spec.texts.limitToFields
			end

			g_inputBinding:setActionEventText(actionEvent.actionEventId, text)
		end
	end
end

function Plow:getIsPlowRotationAllowed()
	local spec = self.spec_plow

	if self.getFoldAnimTime ~= nil then
		local foldAnimTime = self:getFoldAnimTime()

		if spec.rotationPart.rotationFoldMaxLimit < foldAnimTime or foldAnimTime < spec.rotationPart.rotationFoldMinLimit then
			return false
		end
	end

	if not spec.rotationPart.rotationAllowedIfLowered and self.getIsLowered ~= nil and self:getIsLowered() then
		return false
	end

	return true
end

function Plow:getPlowLimitToField()
	return self.spec_plow.limitToField
end

function Plow:getPlowForceLimitToField()
	return self.spec_plow.forceLimitToField
end

function Plow:setPlowAIRequirements(excludedGroundTypes)
	if self.clearAITerrainDetailRequiredRange ~= nil then
		self:clearAITerrainDetailRequiredRange()

		if excludedGroundTypes ~= nil then
			self:addAIGroundTypeRequirements(Plow.AI_REQUIRED_GROUND_TYPES, unpack(excludedGroundTypes))
		else
			self:addAIGroundTypeRequirements(Plow.AI_REQUIRED_GROUND_TYPES)
		end
	end
end

function Plow:getIsFoldAllowed(superFunc, direction, onAiTurnOn)
	local spec = self.spec_plow

	if spec.rotationPart.limitFoldRotationMax ~= nil and spec.rotationPart.limitFoldRotationMax == spec.rotationMax then
		return false, spec.texts.warningFoldingPlowTurned
	end

	if spec.rotationPart.turnAnimation ~= nil and self.getAnimationTime ~= nil then
		local rotationTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		if spec.rotationPart.foldRotationMaxLimit < rotationTime or rotationTime < spec.rotationPart.foldRotationMinLimit then
			return false, spec.texts.warningFoldingPlowTurned
		end
	end

	if not spec.rotationPart.rotationAllowedIfLowered and self.getIsLowered ~= nil and self:getIsLowered() then
		return false, spec.texts.warningFoldingLowered
	end

	return superFunc(self, direction, onAiTurnOn)
end

function Plow:getIsFoldMiddleAllowed(superFunc)
	local spec = self.spec_plow

	if spec.rotationPart.limitFoldRotationMax ~= nil and spec.rotationPart.limitFoldRotationMax == spec.rotationMax then
		return false
	end

	if spec.rotationPart.turnAnimation ~= nil and self.getAnimationTime ~= nil then
		local rotationTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		if spec.rotationPart.foldRotationMaxLimit < rotationTime or rotationTime < spec.rotationPart.foldRotationMinLimit then
			return false
		end
	end

	return superFunc(self)
end

function Plow:getDirtMultiplier(superFunc)
	local multiplier = superFunc(self)
	local spec = self.spec_plow

	if spec.isWorking then
		multiplier = multiplier + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return multiplier
end

function Plow:getWearMultiplier(superFunc)
	local multiplier = superFunc(self)
	local spec = self.spec_plow

	if spec.isWorking then
		multiplier = multiplier + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return multiplier
end

function Plow:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end

	speedRotatingPart.disableOnTurn = xmlFile:getValue(key .. "#disableOnTurn", true)
	speedRotatingPart.turnAnimLimit = xmlFile:getValue(key .. "#turnAnimLimit", 0)
	speedRotatingPart.turnAnimLimitSide = xmlFile:getValue(key .. "#turnAnimLimitSide", 0)
	speedRotatingPart.invertDirectionOnRotation = xmlFile:getValue(key .. "#invertDirectionOnRotation", true)

	return true
end

function Plow:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	local spec = self.spec_plow

	if spec.rotationPart.turnAnimation ~= nil and speedRotatingPart.disableOnTurn then
		local turnAnimTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		if turnAnimTime ~= nil then
			local enabled = nil

			if speedRotatingPart.turnAnimLimitSide < 0 then
				enabled = turnAnimTime <= speedRotatingPart.turnAnimLimit
			elseif speedRotatingPart.turnAnimLimitSide > 0 then
				enabled = 1 - turnAnimTime <= speedRotatingPart.turnAnimLimit
			else
				enabled = turnAnimTime <= speedRotatingPart.turnAnimLimit or 1 - turnAnimTime <= speedRotatingPart.turnAnimLimit
			end

			if not enabled then
				return false
			end
		end
	end

	return superFunc(self, speedRotatingPart)
end

function Plow:getSpeedRotatingPartDirection(superFunc, speedRotatingPart)
	local spec = self.spec_plow

	if spec.rotationPart.turnAnimation ~= nil then
		local turnAnimTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		if turnAnimTime > 0.5 and speedRotatingPart.invertDirectionOnRotation then
			return -1
		end
	end

	return superFunc(self, speedRotatingPart)
end

function Plow:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self.spec_plow.onlyActiveWhenLowered and self:getIsImplementChainLowered()
end

function Plow:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)

	if workArea.type == WorkAreaType.DEFAULT then
		workArea.type = WorkAreaType.PLOW
	end

	return retValue
end

function Plow.getDefaultSpeedLimit()
	return 15
end

function Plow:getIsWorkAreaActive(superFunc, workArea)
	if not superFunc(self, workArea) then
		return false
	end

	local spec = self.spec_plow

	if g_currentMission.time < spec.startActivationTime then
		return false
	end

	if spec.onlyActiveWhenLowered and self.getIsLowered ~= nil and not self:getIsLowered(false) then
		return false
	end

	return true
end

function Plow:getCanAIImplementContinueWork(superFunc)
	local canContinue, stopAI, stopReason = superFunc(self)

	if not canContinue then
		return false, stopAI, stopReason
	end

	return not self:getIsAnimationPlaying(self.spec_plow.rotationPart.turnAnimation)
end

function Plow:getAIInvertMarkersOnTurn(superFunc, turnLeft)
	local spec = self.spec_plow

	if spec.rotationPart.turnAnimation ~= nil then
		if turnLeft then
			return spec.rotationMax == spec.rotateLeftToMax
		else
			return spec.rotationMax ~= spec.rotateLeftToMax
		end
	end

	return false
end

function Plow:getCanBeSelected(superFunc)
	return true
end

function Plow:isDetachAllowed(superFunc)
	local spec = self.spec_plow

	if self:getIsAnimationPlaying(spec.rotationPart.turnAnimation) then
		return false
	end

	if spec.rotationPart.turnAnimation ~= nil then
		local animTime = self:getAnimationTime(spec.rotationPart.turnAnimation)

		if animTime < spec.rotationPart.detachMinLimit or spec.rotationPart.detachMaxLimit < animTime then
			return false, spec.rotationPart.detachWarning, true
		end
	end

	return superFunc(self)
end

function Plow:getAllowsLowering(superFunc)
	local spec = self.spec_plow

	if self:getIsAnimationPlaying(spec.rotationPart.turnAnimation) then
		return false
	end

	return superFunc(self)
end

function Plow:getIsAIReadyToDrive(superFunc)
	local spec = self.spec_plow

	if spec.rotationMax or self:getIsAnimationPlaying(spec.rotationPart.turnAnimation) then
		return false
	end

	return superFunc(self)
end

function Plow:getIsAIPreparingToDrive(superFunc)
	local spec = self.spec_plow

	if self:getIsAnimationPlaying(spec.rotationPart.turnAnimation) then
		return true
	end

	return superFunc(self)
end

function Plow:onRegisterActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if self.isClient then
		local spec = self.spec_plow

		self:clearActionEventsTable(spec.actionEvents)

		if isActiveForInputIgnoreSelection then
			if spec.rotationPart.turnAnimation ~= nil then
				local _, actionEventId = self:addPoweredActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA, self, Plow.actionEventTurn, false, true, false, true, nil)

				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
				g_inputBinding:setActionEventText(actionEventId, spec.texts.turnPlow)
			end

			local _, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.IMPLEMENT_EXTRA3, self, Plow.actionEventLimitToField, false, true, false, true, nil)

			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_NORMAL)
		end
	end
end

function Plow:onStartWorkAreaProcessing(dt)
	local spec = self.spec_plow
	spec.isWorking = false
	local limitToField = self:getPlowLimitToField()
	local limitFruitDestructionToField = limitToField

	if not g_currentMission:getHasPlayerPermission("createFields", self:getOwner(), nil, true) then
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

function Plow:onEndWorkAreaProcessing(dt)
	local spec = self.spec_plow

	if self.isServer then
		local lastStatsArea = spec.workAreaParameters.lastStatsArea

		if lastStatsArea > 0 then
			local ha = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
			local stats = g_currentMission:farmStats(self:getLastTouchedFarmlandFarmId())

			stats:updateStats("plowedHectares", ha)
			stats:updateStats("plowedTime", dt / 60000)
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

function Plow:onPostAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	local spec = self.spec_plow
	spec.startActivationTime = g_currentMission.time + spec.startActivationTimeout

	if spec.wasTurnAnimationStopped then
		local dir = 1

		if not spec.rotationMax then
			dir = -1
		end

		self:playAnimation(spec.rotationPart.turnAnimation, dir, self:getAnimationTime(spec.rotationPart.turnAnimation), true)

		spec.wasTurnAnimationStopped = false
	end
end

function Plow:onPreDetach(attacherVehicle, implement)
	local spec = self.spec_plow
	spec.limitToField = true

	if self:getIsAnimationPlaying(spec.rotationPart.turnAnimation) then
		self:stopAnimation(spec.rotationPart.turnAnimation, true)

		spec.wasTurnAnimationStopped = true
	end
end

function Plow:onDeactivate()
	if self.isClient then
		local spec = self.spec_plow

		g_soundManager:stopSamples(spec.samples)

		spec.isWorkSamplePlaying = false
	end
end

function Plow:onAIImplementStartTurn()
	self.spec_plow.ai.lastHeadlandPosition = 0
end

function Plow:onAIImplementTurnProgress(progress, left)
	local spec = self.spec_plow

	if spec.ai.lastHeadlandPosition < spec.ai.rotateToCenterHeadlandPos and spec.ai.rotateToCenterHeadlandPos < progress and progress < spec.ai.rotateCompletelyHeadlandPos then
		self:setRotationCenter()
	elseif spec.ai.lastHeadlandPosition < spec.ai.rotateCompletelyHeadlandPos and spec.ai.rotateCompletelyHeadlandPos < progress then
		self:setRotationMax(left)
	end

	spec.ai.lastHeadlandPosition = progress
end

function Plow:onStartAnimation(animName)
	local spec = self.spec_plow

	if animName == spec.rotationPart.turnAnimation then
		g_soundManager:playSample(spec.samples.turn)
	end
end

function Plow:onFinishAnimation(animName)
	local spec = self.spec_plow

	if animName == spec.rotationPart.turnAnimation then
		g_soundManager:stopSample(spec.samples.turn)
	end
end

function Plow:onRootVehicleChanged(rootVehicle)
	local spec = self.spec_foldable

	if #spec.foldingParts > 0 then
		local actionController = rootVehicle.actionController

		if actionController ~= nil then
			if spec.controlledActionRotate ~= nil then
				spec.controlledActionRotate:updateParent(actionController)

				return
			end

			spec.controlledActionRotate = actionController:registerAction("rotatePlow", nil, 3)

			spec.controlledActionRotate:setCallback(self, Plow.actionControllerRotateEvent)
			spec.controlledActionRotate:setFinishedFunctions(self, function (vehicle)
				return vehicle.spec_foldable.rotationMax
			end, false, false)
			spec.controlledActionRotate:addAIEventListener(self, "onAIImplementPrepare", -1, true)
		elseif spec.controlledActionRotate ~= nil then
			spec.controlledActionRotate:remove()
		end
	end
end

function Plow:actionEventTurn(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_plow

	if spec.rotationPart.turnAnimation ~= nil and self:getIsPlowRotationAllowed() then
		self:setRotationMax(not spec.rotationMax)
	end
end

function Plow:actionEventLimitToField(actionName, inputValue, callbackState, isAnalog)
	local spec = self.spec_plow

	if not self:getPlowForceLimitToField() then
		self:setPlowLimitToField(not spec.limitToField)
	end
end

function Plow:actionControllerRotateEvent(direction)
	local spec = self.spec_plow

	if spec.rotationPart.turnAnimation ~= nil and self:getIsPlowRotationAllowed() and spec.rotationMax then
		self:setRotationMax(false)
	end
end
