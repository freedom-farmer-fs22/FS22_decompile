Cutter = {
	AUTO_TILT_COLLISION_MASK = 4287627263.0,
	CUTTER_TILT_XML_KEY = "vehicle.cutter.automaticTilt"
}

function Cutter.initSpecialization()
	g_workAreaTypeManager:addWorkAreaType("cutter", false)

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("Cutter")
	schema:register(XMLValueType.STRING, "vehicle.cutter#fruitTypes", "List with supported fruit types")
	schema:register(XMLValueType.STRING, "vehicle.cutter#fruitTypeCategories", "List with supported fruit types categories")
	schema:register(XMLValueType.STRING, "vehicle.cutter#fruitTypeConverter", "Name of fruit type converter")
	schema:register(XMLValueType.BOOL, "vehicle.cutter#useWindrowed", "Uses windrow types")
	AnimationManager.registerAnimationNodesXMLPaths(schema, "vehicle.cutter.animationNodes")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.cutter.fruitExtraObjects.fruitExtraObject(?)#node", "Name of fruit type converter")
	schema:register(XMLValueType.STRING, "vehicle.cutter.fruitExtraObjects.fruitExtraObject(?)#anim", "Change animation name")
	schema:register(XMLValueType.BOOL, "vehicle.cutter.fruitExtraObjects.fruitExtraObject(?)#isDefault", "Is default active")
	schema:register(XMLValueType.STRING, "vehicle.cutter.fruitExtraObjects.fruitExtraObject(?)#fruitType", "Name of fruit type")
	schema:register(XMLValueType.BOOL, "vehicle.cutter.fruitExtraObjects#hideOnDetach", "Hide extra objects on detach", false)
	EffectManager.registerEffectXMLPaths(schema, "vehicle.cutter.effect")
	EffectManager.registerEffectXMLPaths(schema, "vehicle.cutter.fillEffect")
	schema:register(XMLValueType.NODE_INDEX, Cutter.CUTTER_TILT_XML_KEY .. ".automaticTiltNode(?)#node", "Automatic tilt node")
	schema:register(XMLValueType.ANGLE, Cutter.CUTTER_TILT_XML_KEY .. ".automaticTiltNode(?)#minAngle", "Min. angle", -5)
	schema:register(XMLValueType.ANGLE, Cutter.CUTTER_TILT_XML_KEY .. ".automaticTiltNode(?)#maxAngle", "Max. angle", 5)
	schema:register(XMLValueType.ANGLE, Cutter.CUTTER_TILT_XML_KEY .. ".automaticTiltNode(?)#maxSpeed", "Max. angle change per second", 1)
	schema:register(XMLValueType.NODE_INDEX, Cutter.CUTTER_TILT_XML_KEY .. "#raycastNode1", "Raycast node 1")
	schema:register(XMLValueType.NODE_INDEX, Cutter.CUTTER_TILT_XML_KEY .. "#raycastNode2", "Raycast node 2")
	schema:register(XMLValueType.BOOL, "vehicle.cutter#allowsForageGrowthState", "Allows forage growth state", false)
	schema:register(XMLValueType.BOOL, "vehicle.cutter#allowCuttingWhileRaised", "Allow cutting while raised", false)
	schema:register(XMLValueType.INT, "vehicle.cutter#movingDirection", "Moving direction", 1)
	schema:register(XMLValueType.FLOAT, "vehicle.cutter#strawRatio", "Straw ratio", 1)
	schema:register(XMLValueType.NODE_INDEX, "vehicle.cutter.spikedDrums.spikedDrum(?)#node", "Spiked drum node (Needs to rotate on X axis)")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.cutter.spikedDrums.spikedDrum(?)#spline", "Reference spline")
	schema:register(XMLValueType.NODE_INDEX, "vehicle.cutter.spikedDrums.spikedDrum(?).spike(?)#node", "Spike that is translated on Y axis depending on spline")
	SoundManager.registerSampleXMLPaths(schema, "vehicle.cutter.sounds", "cut")
	schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_KEY .. ".chopperArea#index", "Chopper area index")
	schema:register(XMLValueType.INT, WorkArea.WORK_AREA_XML_CONFIG_KEY .. ".chopperArea#index", "Chopper area index")
	schema:register(XMLValueType.BOOL, RandomlyMovingParts.RANDOMLY_MOVING_PART_XML_KEY .. "#moveOnlyIfCut", "Move only if cutters cuts something", false)
	schema:register(XMLValueType.BOOL, SpeedRotatingParts.SPEED_ROTATING_PART_XML_KEY .. "#rotateIfTurnedOn", "Rotate only if turned on", false)
	schema:setXMLSpecializationType()
end

function Cutter.prerequisitesPresent(specializations)
	return SpecializationUtil.hasSpecialization(WorkArea, specializations) and SpecializationUtil.hasSpecialization(TestAreas, specializations)
end

function Cutter.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "readCutterFromStream", Cutter.readCutterFromStream)
	SpecializationUtil.registerFunction(vehicleType, "writeCutterToStream", Cutter.writeCutterToStream)
	SpecializationUtil.registerFunction(vehicleType, "getCombine", Cutter.getCombine)
	SpecializationUtil.registerFunction(vehicleType, "getAllowCutterAIFruitRequirements", Cutter.getAllowCutterAIFruitRequirements)
	SpecializationUtil.registerFunction(vehicleType, "processCutterArea", Cutter.processCutterArea)
	SpecializationUtil.registerFunction(vehicleType, "processPickupCutterArea", Cutter.processPickupCutterArea)
	SpecializationUtil.registerFunction(vehicleType, "getCutterLoad", Cutter.getCutterLoad)
	SpecializationUtil.registerFunction(vehicleType, "getCutterStoneMultiplier", Cutter.getCutterStoneMultiplier)
	SpecializationUtil.registerFunction(vehicleType, "loadCutterTiltFromXML", Cutter.loadCutterTiltFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getCutterTiltIsAvailable", Cutter.getCutterTiltIsAvailable)
	SpecializationUtil.registerFunction(vehicleType, "getCutterTiltIsActive", Cutter.getCutterTiltIsActive)
	SpecializationUtil.registerFunction(vehicleType, "getCutterTiltDelta", Cutter.getCutterTiltDelta)
	SpecializationUtil.registerFunction(vehicleType, "tiltRaycastDetectionCallback", Cutter.tiltRaycastDetectionCallback)
	SpecializationUtil.registerFunction(vehicleType, "setCutterCutHeight", Cutter.setCutterCutHeight)
end

function Cutter.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadSpeedRotatingPartFromXML", Cutter.loadSpeedRotatingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsSpeedRotatingPartActive", Cutter.getIsSpeedRotatingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadRandomlyMovingPartFromXML", Cutter.loadRandomlyMovingPartFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsRandomlyMovingPartActive", Cutter.getIsRandomlyMovingPartActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsWorkAreaActive", Cutter.getIsWorkAreaActive)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", Cutter.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadWorkAreaFromXML", Cutter.loadWorkAreaFromXML)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDirtMultiplier", Cutter.getDirtMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getWearMultiplier", Cutter.getWearMultiplier)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "isAttachAllowed", Cutter.isAttachAllowed)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getConsumingLoad", Cutter.getConsumingLoad)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsGroundReferenceNodeThreshold", Cutter.getIsGroundReferenceNodeThreshold)
end

function Cutter.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onReadStream", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteStream", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onReadUpdateStream", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onWriteUpdateStream", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdateTick", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onStartWorkAreaProcessing", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onEndWorkAreaProcessing", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onPreAttach", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onPostDetach", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOn", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", Cutter)
	SpecializationUtil.registerEventListener(vehicleType, "onAIImplementStart", Cutter)
end

function Cutter:onLoad(savegame)
	local spec = self.spec_cutter

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnRotationNodes.turnedOnRotationNode#type", "vehicle.cutter.animationNodes.animationNode", "cutter")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.turnedOnScrollers", "vehicle.cutter.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.turnedOnScrollers", "vehicle.cutter.animationNodes.animationNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.reelspikes", "vehicle.cutter.rotationNodes.rotationNode or vehicle.turnOnVehicle.turnedOnAnimation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.threshingParticleSystems.threshingParticleSystem", "vehicle.cutter.fillEffect.effectNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.threshingParticleSystems.emitterShape", "vehicle.cutter.fillEffect.effectNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter#convertedFillTypeCategories", "vehicle.cutter#fruitTypeConverter")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter#startAnimationName", "vehicle.turnOnVehicle.turnOnAnimation#name")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.cutter.testAreas", "vehicle.workAreas.workArea.testAreas")

	local fruitTypes = nil
	local fruitTypeNames = self.xmlFile:getValue("vehicle.cutter#fruitTypes")
	local fruitTypeCategories = self.xmlFile:getValue("vehicle.cutter#fruitTypeCategories")

	if fruitTypeCategories ~= nil and fruitTypeNames == nil then
		fruitTypes = g_fruitTypeManager:getFruitTypesByCategoryNames(fruitTypeCategories, "Warning: Cutter has invalid fruitTypeCategory '%s' in '" .. self.configFileName .. "'")
	elseif fruitTypeCategories == nil and fruitTypeNames ~= nil then
		fruitTypes = g_fruitTypeManager:getFruitTypesByNames(fruitTypeNames, "Warning: Cutter has invalid fruitType '%s' in '" .. self.configFileName .. "'")
	else
		Logging.xmlWarning(self.xmlFile, "Cutter needs either the 'fruitTypeCategories' or 'fruitTypes' attribute!")
	end

	spec.currentCutHeight = 0

	if fruitTypes ~= nil then
		spec.fruitTypes = {}

		for _, fruitType in pairs(fruitTypes) do
			table.insert(spec.fruitTypes, fruitType)

			if #spec.fruitTypes == 1 then
				local cutHeight = g_fruitTypeManager:getCutHeightByFruitTypeIndex(fruitType, spec.allowsForageGrowthState)

				self:setCutterCutHeight(cutHeight)
			end
		end
	end

	spec.fruitTypeConverters = {}
	local category = self.xmlFile:getValue("vehicle.cutter#fruitTypeConverter")

	if category ~= nil then
		local data = g_fruitTypeManager:getConverterDataByName(category)

		if data ~= nil then
			for input, converter in pairs(data) do
				spec.fruitTypeConverters[input] = converter
			end
		end
	end

	spec.fillTypes = {}

	for _, fruitType in ipairs(spec.fruitTypes) do
		if spec.fruitTypeConverters[fruitType] ~= nil then
			table.insert(spec.fillTypes, spec.fruitTypeConverters[fruitType].fillTypeIndex)
		else
			local fillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitType)

			if fillType ~= nil then
				table.insert(spec.fillTypes, fillType)
			end
		end
	end

	if self.isClient then
		spec.animationNodes = g_animationManager:loadAnimations(self.xmlFile, "vehicle.cutter.animationNodes", self.components, self, self.i3dMappings)
		spec.fruitExtraObjects = {}
		local i = 0

		while true do
			local key = string.format("vehicle.cutter.fruitExtraObjects.fruitExtraObject(%d)", i)

			XMLUtil.checkDeprecatedXMLElements(self.xmlFile, key .. "#index", key .. "#node")

			local node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
			local anim = self.xmlFile:getValue(key .. "#anim")
			local isDefault = self.xmlFile:getValue(key .. "#isDefault", false)
			local fruitType = g_fruitTypeManager:getFruitTypeByName(self.xmlFile:getValue(key .. "#fruitType"))

			if fruitType == nil or node == nil and anim == nil then
				break
			end

			if node ~= nil then
				setVisibility(node, false)
			end

			local extraObject = {
				node = node,
				anim = anim
			}
			spec.fruitExtraObjects[fruitType.index] = extraObject

			if isDefault then
				spec.fruitExtraObjects[FruitType.UNKNOWN] = extraObject
			end

			i = i + 1
		end

		spec.hideExtraObjectsOnDetach = self.xmlFile:getValue("vehicle.cutter.fruitExtraObjects#hideOnDetach", false)
		spec.spikedDrums = {}

		self.xmlFile:iterate("vehicle.cutter.spikedDrums.spikedDrum", function (index, key)
			local entry = {
				node = self.xmlFile:getValue(key .. "#node", nil, self.components, self.i3dMappings)
			}

			if entry.node ~= nil then
				entry.spline = self.xmlFile:getValue(key .. "#spline", nil, self.components, self.i3dMappings)

				if entry.spline ~= nil then
					setVisibility(entry.spline, false)

					entry.spikes = {}

					self.xmlFile:iterate(key .. ".spike", function (_, spikeKey)
						local spike = {
							node = self.xmlFile:getValue(spikeKey .. "#node", nil, self.components, self.i3dMappings)
						}

						if spike.node ~= nil then
							local parent = createTransformGroup(getName(spike.node) .. "Parent")

							link(getParent(spike.node), parent, getChildIndex(spike.node))
							setTranslation(parent, getTranslation(spike.node))
							setRotation(parent, getRotation(spike.node))
							link(parent, spike.node)
							setTranslation(spike.node, 0, 0, 0)
							setRotation(spike.node, 0, 0, 0)

							local _, y, z = localToLocal(spike.node, entry.node, 0, 0, 0)
							local angle = -MathUtil.getYRotationFromDirection(y, z)
							local initalTime = angle / (2 * math.pi)

							if initalTime < 0 then
								initalTime = initalTime + 1
							end

							spike.initalTime = initalTime

							table.insert(entry.spikes, spike)
						end
					end)

					local splineTimes = {}

					for t = 0, 1, 0.01 do
						local x, y, z = getSplinePosition(entry.spline, t)
						local _ = nil
						_, y, z = worldToLocal(entry.node, x, y, z)
						local angle = -MathUtil.getYRotationFromDirection(y, z)
						local alpha = angle / (2 * math.pi)

						if alpha < 0 then
							alpha = alpha + 1
						end

						table.insert(splineTimes, {
							alpha = alpha,
							time = t
						})
					end

					table.insert(splineTimes, {
						time = 1,
						alpha = splineTimes[1].alpha - 1e-06
					})
					table.sort(splineTimes, function (a, b)
						return a.alpha < b.alpha
					end)

					entry.splineCurve = AnimCurve.new(linearInterpolator1)

					for j = 1, #splineTimes do
						entry.splineCurve:addKeyframe({
							splineTimes[j].time,
							time = splineTimes[j].alpha
						})
					end

					for j = 1, #spec.animationNodes do
						local animationNode = spec.animationNodes[j]

						if animationNode.node == entry.node then
							entry.animationNode = animationNode
						end
					end

					if entry.animationNode ~= nil then
						table.insert(spec.spikedDrums, entry)
					else
						Logging.xmlWarning(self.xmlFile, "Could not find animation node for spikedDrum '%s'", getName(entry.node))
					end
				else
					Logging.xmlWarning(self.xmlFile, "No spline defined for spiked drum '%s'", key)
				end
			else
				Logging.xmlWarning(self.xmlFile, "No drum node defined for spiked drum '%s'", key)
			end
		end)

		spec.cutterEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.cutter.effect", self.components, self, self.i3dMappings)
		spec.fillEffects = g_effectManager:loadEffect(self.xmlFile, "vehicle.cutter.fillEffect", self.components, self, self.i3dMappings)
		spec.samples = {
			cut = g_soundManager:loadSampleFromXML(self.xmlFile, "vehicle.cutter.sounds", "cut", self.baseDirectory, self.components, 0, AudioGroup.VEHICLE, self.i3dMappings, self)
		}
	end

	spec.lastAutomaticTiltRaycastPosition = {
		0,
		0,
		0
	}
	spec.automaticTilt = {
		isAvailable = false,
		hasNodes = false
	}

	if self:loadCutterTiltFromXML(self.xmlFile, Cutter.CUTTER_TILT_XML_KEY, spec.automaticTilt) then
		spec.automaticTilt.currentDelta = 0
		spec.automaticTilt.lastHit = {
			0,
			0,
			0
		}
		spec.automaticTilt.raycastHit = true
		spec.automaticTilt.isAvailable = true
		spec.automaticTilt.hasNodes = #spec.automaticTilt.nodes > 0
	end

	spec.allowsForageGrowthState = self.xmlFile:getValue("vehicle.cutter#allowsForageGrowthState", false)
	spec.allowCuttingWhileRaised = self.xmlFile:getValue("vehicle.cutter#allowCuttingWhileRaised", false)
	spec.movingDirection = MathUtil.sign(self.xmlFile:getValue("vehicle.cutter#movingDirection", 1))
	spec.strawRatio = self.xmlFile:getValue("vehicle.cutter#strawRatio", 1)
	spec.useWindrow = false
	spec.currentInputFillType = FillType.UNKNOWN
	spec.currentInputFruitType = FruitType.UNKNOWN
	spec.currentInputFruitTypeAI = FruitType.UNKNOWN
	spec.lastValidInputFruitType = FruitType.UNKNOWN
	spec.currentInputFruitTypeSent = FruitType.UNKNOWN
	spec.currentOutputFillType = FillType.UNKNOWN
	spec.currentConversionFactor = 1
	spec.currentGrowthStateTime = 0
	spec.currentGrowthStateTimer = 0
	spec.currentGrowthState = 0
	spec.lastAreaBiggerZero = false
	spec.lastAreaBiggerZeroSent = false
	spec.lastAreaBiggerZeroTime = -1
	spec.workAreaParameters = {
		lastRealArea = 0,
		lastArea = 0,
		lastGrowthState = 0,
		lastGrowthStateArea = 0,
		fruitTypesToUse = {},
		lastFruitTypeToUse = {}
	}
	spec.lastOutputFillTypes = {}
	spec.lastPrioritizedOutputType = FillType.UNKNOWN
	spec.lastOutputTime = 0
	spec.cutterLoad = 0
	spec.isWorking = false
	spec.stoneLastState = 0
	spec.stoneWearMultiplierData = g_currentMission.stoneSystem:getWearMultiplierByType("CUTTER")
	spec.workAreaParameters.countArea = true
	spec.aiNoValidGroundTimer = 0
	spec.dirtyFlag = self:getNextDirtyFlag()
	spec.effectDirtyFlag = self:getNextDirtyFlag()
end

function Cutter:onPostLoad(savegame)
	if self.addCutterToCombine ~= nil then
		self:addCutterToCombine(self)
	end

	if self.isClient then
		Cutter.updateExtraObjects(self)
	end
end

function Cutter:onDelete()
	local spec = self.spec_cutter

	g_effectManager:deleteEffects(spec.cutterEffects)
	g_effectManager:deleteEffects(spec.fillEffects)
	g_animationManager:deleteAnimations(spec.animationNodes)
	g_soundManager:deleteSamples(spec.samples)
end

function Cutter:onReadStream(streamId, connection)
	self:readCutterFromStream(streamId, connection)

	local spec = self.spec_cutter
	spec.lastAreaBiggerZero = streamReadBool(streamId)

	if spec.lastAreaBiggerZero then
		spec.lastAreaBiggerZeroTime = g_currentMission.time
	end

	self:setTestAreaRequirements(spec.currentInputFruitType, nil, spec.allowsForageGrowthState)
end

function Cutter:onWriteStream(streamId, connection)
	self:writeCutterToStream(streamId, connection)

	local spec = self.spec_cutter

	streamWriteBool(streamId, spec.lastAreaBiggerZeroSent)
end

function Cutter:onReadUpdateStream(streamId, timestamp, connection)
	if connection:getIsServer() then
		local spec = self.spec_cutter

		if streamReadBool(streamId) then
			self:readCutterFromStream(streamId, connection)
		end

		spec.lastAreaBiggerZero = streamReadBool(streamId)

		if spec.lastAreaBiggerZero then
			spec.lastAreaBiggerZeroTime = g_currentMission.time
		end

		self:setTestAreaRequirements(spec.currentInputFruitType, nil, spec.allowsForageGrowthState)
	end
end

function Cutter:onWriteUpdateStream(streamId, connection, dirtyMask)
	if not connection:getIsServer() then
		local spec = self.spec_cutter

		if streamWriteBool(streamId, bitAND(dirtyMask, spec.effectDirtyFlag) ~= 0) then
			self:writeCutterToStream(streamId, connection)
		end

		streamWriteBool(streamId, spec.lastAreaBiggerZeroSent)
	end
end

function Cutter:readCutterFromStream(streamId, connection)
	local spec = self.spec_cutter
	spec.currentGrowthState = streamReadUIntN(streamId, 4)
	spec.currentInputFruitType = streamReadUIntN(streamId, FruitTypeManager.SEND_NUM_BITS)

	if streamReadBool(streamId) then
		spec.lastValidInputFruitType = spec.currentInputFruitType
	else
		spec.currentInputFruitType = FruitType.UNKNOWN
	end

	spec.currentOutputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.currentInputFruitType)

	if spec.fruitTypeConverters[spec.currentInputFruitType] ~= nil then
		spec.currentOutputFillType = spec.fruitTypeConverters[spec.currentInputFruitType].fillTypeIndex
		spec.currentConversionFactor = spec.fruitTypeConverters[spec.currentInputFruitType].conversionFactor
	end

	if streamReadBool(streamId) then
		spec.currentInputFillType = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(spec.currentInputFruitType)
	else
		spec.currentInputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.currentInputFruitType)
	end
end

function Cutter:writeCutterToStream(streamId, connection)
	local spec = self.spec_cutter

	streamWriteUIntN(streamId, spec.currentGrowthState, 4)
	streamWriteUIntN(streamId, spec.currentInputFruitType, FruitTypeManager.SEND_NUM_BITS)
	streamWriteBool(streamId, spec.currentInputFruitType == spec.lastValidInputFruitType)
	streamWriteBool(streamId, spec.useWindrow)
end

function Cutter:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_cutter

	if spec.automaticTilt.hasNodes then
		local currentDelta, isActive, doReset = self:getCutterTiltDelta()
		currentDelta = -currentDelta

		if self.isActive then
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

					if self.setMovingToolDirty ~= nil then
						self:setMovingToolDirty(automaticTiltNode.node)
					end
				end
			end
		end
	end

	if self.isClient then
		for i = 1, #spec.spikedDrums do
			local spikedDrum = spec.spikedDrums[i]

			if spikedDrum.animationNode.state ~= RotationAnimation.STATE_OFF then
				local rot, _, _ = getRotation(spikedDrum.node)

				if rot < 0 then
					rot = rot + 2 * math.pi
				end

				local alpha = rot / (2 * math.pi)
				local numSpikes = #spikedDrum.spikes

				for j = 1, numSpikes do
					local spike = spikedDrum.spikes[j]
					local splineTime = spikedDrum.splineCurve:get((alpha + spike.initalTime) % 1)
					local x, y, z = getSplinePosition(spikedDrum.spline, splineTime)
					local _, spikeY, _ = worldToLocal(getParent(spike.node), x, y, z)

					setTranslation(spike.node, 0, spikeY, 0)
				end
			end
		end
	end
end

function Cutter:onUpdateTick(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_cutter
	local isTurnedOn = self:getIsTurnedOn()
	local isEffectActive = isTurnedOn and self.movingDirection == spec.movingDirection and self:getLastSpeed() > 0.5 and (spec.allowCuttingWhileRaised or self:getIsLowered(true)) and spec.workAreaParameters.combineVehicle ~= nil

	if isEffectActive then
		local currentTestAreaMinX, currentTestAreaMaxX, testAreaMinX, testAreaMaxX = self:getTestAreaWidthByWorkAreaIndex(1)
		local testAreaCharge = self:getTestAreaChargeByWorkAreaIndex(1)

		if not spec.useWindrow then
			spec.cutterLoad = spec.cutterLoad * 0.95 + testAreaCharge * 0.05
		end

		local reset = false

		if currentTestAreaMinX == -math.huge and currentTestAreaMaxX == math.huge then
			currentTestAreaMinX = 0
			currentTestAreaMaxX = 0
			reset = true
		end

		if spec.movingDirection > 0 then
			currentTestAreaMinX = currentTestAreaMinX * -1
			currentTestAreaMaxX = currentTestAreaMaxX * -1

			if currentTestAreaMinX > currentTestAreaMaxX then
				local t = currentTestAreaMinX
				currentTestAreaMinX = currentTestAreaMaxX
				currentTestAreaMaxX = t
			end
		end

		local inputFruitType = spec.currentInputFruitType

		if inputFruitType ~= spec.lastValidInputFruitType then
			inputFruitType = nil
		end

		if inputFruitType ~= nil then
			Cutter.updateExtraObjects(self)
		end

		local isCollecting = g_currentMission.time < spec.lastAreaBiggerZeroTime + 300
		local fillType = spec.currentInputFillType

		if spec.useWindrow then
			if isCollecting then
				spec.cutterLoad = spec.cutterLoad * 0.95 + 0.05
			else
				spec.cutterLoad = spec.cutterLoad * 0.9
			end
		end

		if self.isClient then
			local cutSoundActive = false

			if fillType ~= FillType.UNKNOWN and isCollecting then
				g_effectManager:setFillType(spec.fillEffects, fillType)
				g_effectManager:setMinMaxWidth(spec.fillEffects, currentTestAreaMinX, currentTestAreaMaxX, currentTestAreaMinX / testAreaMinX, currentTestAreaMaxX / testAreaMaxX, reset)
				g_effectManager:startEffects(spec.fillEffects)

				cutSoundActive = true
			else
				g_effectManager:stopEffects(spec.fillEffects)
			end

			if inputFruitType ~= nil and not reset then
				g_effectManager:setFruitType(spec.cutterEffects, inputFruitType, spec.currentGrowthState)
				g_effectManager:setFillType(spec.cutterEffects, fillType)
				g_effectManager:setMinMaxWidth(spec.cutterEffects, currentTestAreaMinX, currentTestAreaMaxX, currentTestAreaMinX / testAreaMinX, currentTestAreaMaxX / testAreaMaxX, reset)
				g_effectManager:startEffects(spec.cutterEffects)

				cutSoundActive = true
			else
				g_effectManager:stopEffects(spec.cutterEffects)
			end

			if cutSoundActive then
				if not g_soundManager:getIsSamplePlaying(spec.samples.cut) then
					g_soundManager:playSample(spec.samples.cut)
				end
			elseif g_soundManager:getIsSamplePlaying(spec.samples.cut) then
				g_soundManager:stopSample(spec.samples.cut)
			end
		end
	else
		if self.isClient then
			g_effectManager:stopEffects(spec.cutterEffects)
			g_effectManager:stopEffects(spec.fillEffects)
			g_soundManager:stopSample(spec.samples.cut)
		end

		spec.cutterLoad = spec.cutterLoad * 0.9
	end

	spec.lastOutputTime = spec.lastOutputTime + dt

	if spec.lastOutputTime > 500 then
		spec.lastPrioritizedOutputType = FillType.UNKNOWN
		local max = 0

		for i, _ in pairs(spec.lastOutputFillTypes) do
			if max < spec.lastOutputFillTypes[i] then
				spec.lastPrioritizedOutputType = i
				max = spec.lastOutputFillTypes[i]
			end

			spec.lastOutputFillTypes[i] = 0
		end

		spec.lastOutputTime = 0
	end

	local automaticTilt = spec.automaticTilt
	local isActive, _ = self:getCutterTiltIsActive(automaticTilt)

	if isActive and automaticTilt ~= nil and automaticTilt.raycastNode1 ~= nil and automaticTilt.raycastNode2 ~= nil then
		automaticTilt.currentDelta = 0
		local rx, ry, rz = localToWorld(automaticTilt.raycastNode1, 0, 1, 0)
		local rDirX, rDirY, rDirZ = localDirectionToWorld(automaticTilt.raycastNode1, 0, -1, 0)
		automaticTilt.raycastHit = false

		raycastAll(rx, ry, rz, rDirX, rDirY, rDirZ, "tiltRaycastDetectionCallback", 2, self, Cutter.AUTO_TILT_COLLISION_MASK)

		local hit1X = automaticTilt.lastHit[1]
		local hit1Y = automaticTilt.lastHit[2]
		local hit1Z = automaticTilt.lastHit[3]
		local node1X, node1Y, node1Z = getWorldTranslation(automaticTilt.raycastNode1)

		if not automaticTilt.raycastHit then
			hit1X, hit1Y, hit1Z = localToWorld(automaticTilt.raycastNode1, 0, -1, 0)
		end

		rx, ry, rz = localToWorld(automaticTilt.raycastNode2, 0, 1, 0)
		rDirX, rDirY, rDirZ = localDirectionToWorld(automaticTilt.raycastNode2, 0, -1, 0)
		automaticTilt.raycastHit = false

		raycastAll(rx, ry, rz, rDirX, rDirY, rDirZ, "tiltRaycastDetectionCallback", 2, self, Cutter.AUTO_TILT_COLLISION_MASK)

		local hit2X = automaticTilt.lastHit[1]
		local hit2Y = automaticTilt.lastHit[2]
		local hit2Z = automaticTilt.lastHit[3]
		local node2X, node2Y, node2Z = getWorldTranslation(automaticTilt.raycastNode2)

		if not automaticTilt.raycastHit then
			hit2X, hit2Y, hit2Z = localToWorld(automaticTilt.raycastNode2, 0, -1, 0)
		end

		local gHeight = hit1Y - hit2Y
		local gRefX = hit2X + rDirX * gHeight
		local gRefY = hit2Y + rDirY * gHeight
		local gRefZ = hit2Z + rDirZ * gHeight
		local gDistance = MathUtil.vector3Length(hit1X - gRefX, hit1Y - gRefY, hit1Z - gRefZ)
		local gDirection = hit1Y < hit2Y and -1 or 1
		local gAngle = math.atan(math.abs(gHeight) / gDistance) * gDirection
		local cHeight = node2Y - node1Y
		local cDistance = MathUtil.vector3Length(node1X - node2X, node1Y - node2Y, node1Z - node2Z)
		local cDirection = node1Y < node2Y and -1 or 1
		local cAngle = math.atan(math.abs(cHeight) / cDistance) * cDirection

		if gAngle == gAngle and cAngle == cAngle then
			automaticTilt.currentDelta = gAngle - cAngle
		end
	end
end

function Cutter:getCombine()
	local spec = self.spec_cutter

	if self.verifyCombine ~= nil then
		return self:verifyCombine(spec.currentInputFruitType, spec.currentOutputFillType)
	elseif self.getAttacherVehicle ~= nil then
		local attacherVehicle = self:getAttacherVehicle()

		if attacherVehicle ~= nil and attacherVehicle.verifyCombine ~= nil then
			return attacherVehicle:verifyCombine(spec.currentInputFruitType, spec.currentOutputFillType)
		end
	end

	return nil
end

function Cutter:getAllowCutterAIFruitRequirements()
	return true
end

function Cutter:processCutterArea(workArea, dt)
	local spec = self.spec_cutter

	if spec.workAreaParameters.combineVehicle ~= nil then
		local xs, _, zs = getWorldTranslation(workArea.start)
		local xw, _, zw = getWorldTranslation(workArea.width)
		local xh, _, zh = getWorldTranslation(workArea.height)
		local lastRealArea = 0
		local lastThreshedArea = 0
		local lastArea = 0
		local fieldGroundSystem = g_currentMission.fieldGroundSystem

		for _, fruitTypeIndex in ipairs(spec.workAreaParameters.fruitTypesToUse) do
			local fruitTypeDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)
			local chopperValue = fieldGroundSystem:getChopperTypeValue(fruitTypeDesc.chopperTypeIndex)
			local realArea, area, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPerc, growthState, _, terrainDetailPixelsSum = FSDensityMapUtil.cutFruitArea(fruitTypeIndex, xs, zs, xw, zw, xh, zh, true, spec.allowsForageGrowthState, chopperValue)

			if realArea > 0 then
				if self.isServer then
					if growthState ~= spec.currentGrowthState then
						spec.currentGrowthStateTimer = spec.currentGrowthStateTimer + dt

						if spec.currentGrowthStateTimer > 500 or spec.currentGrowthStateTime + 1000 < g_time then
							spec.currentGrowthState = growthState
							spec.currentGrowthStateTimer = 0
						end
					else
						spec.currentGrowthStateTimer = 0
						spec.currentGrowthStateTime = g_time
					end

					if fruitTypeIndex ~= spec.currentInputFruitType then
						spec.currentInputFruitType = fruitTypeIndex
						spec.currentOutputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.currentInputFruitType)

						if spec.fruitTypeConverters[spec.currentInputFruitType] ~= nil then
							spec.currentOutputFillType = spec.fruitTypeConverters[spec.currentInputFruitType].fillTypeIndex
							spec.currentConversionFactor = spec.fruitTypeConverters[spec.currentInputFruitType].conversionFactor
						end

						local cutHeight = g_fruitTypeManager:getCutHeightByFruitTypeIndex(fruitTypeIndex, spec.allowsForageGrowthState)

						self:setCutterCutHeight(cutHeight)
					end

					self:setTestAreaRequirements(fruitTypeIndex, nil, spec.allowsForageGrowthState)

					if terrainDetailPixelsSum > 0 then
						spec.currentInputFruitTypeAI = fruitTypeIndex
					end

					spec.currentInputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(fruitTypeIndex)
					spec.useWindrow = false
				end

				local multiplier = g_currentMission:getHarvestScaleMultiplier(fruitTypeIndex, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleFactor, rollerFactor, beeYieldBonusPerc)
				lastRealArea = realArea * multiplier
				lastThreshedArea = realArea
				lastArea = area
				spec.workAreaParameters.lastFruitType = fruitTypeIndex
				spec.workAreaParameters.lastChopperValue = chopperValue

				break
			end
		end

		if lastArea > 0 then
			if workArea.chopperAreaIndex ~= nil and spec.workAreaParameters.lastChopperValue ~= nil then
				local chopperWorkArea = self:getWorkAreaByIndex(workArea.chopperAreaIndex)

				if chopperWorkArea ~= nil then
					xs, _, zs = getWorldTranslation(chopperWorkArea.start)
					xw, _, zw = getWorldTranslation(chopperWorkArea.width)
					xh, _, zh = getWorldTranslation(chopperWorkArea.height)

					FSDensityMapUtil.setGroundTypeLayerArea(xs, zs, xw, zw, xh, zh, spec.workAreaParameters.lastChopperValue)
				else
					workArea.chopperAreaIndex = nil

					Logging.xmlWarning(self.xmlFile, "Invalid chopperAreaIndex '%d' for workArea '%d'!", workArea.chopperAreaIndex, workArea.index)
				end
			end

			spec.stoneLastState = FSDensityMapUtil.getStoneArea(xs, zs, xw, zw, xh, zh)
			spec.isWorking = true
		end

		spec.workAreaParameters.lastRealArea = spec.workAreaParameters.lastRealArea + lastRealArea
		spec.workAreaParameters.lastThreshedArea = spec.workAreaParameters.lastThreshedArea + lastThreshedArea
		spec.workAreaParameters.lastStatsArea = spec.workAreaParameters.lastStatsArea + lastThreshedArea
		spec.workAreaParameters.lastArea = spec.workAreaParameters.lastArea + lastArea
	end

	return spec.workAreaParameters.lastRealArea, spec.workAreaParameters.lastArea
end

function Cutter:processPickupCutterArea(workArea, dt)
	local spec = self.spec_cutter

	if spec.workAreaParameters.combineVehicle ~= nil then
		local sx, sy, sz = getWorldTranslation(workArea.start)
		local wx, wy, wz = getWorldTranslation(workArea.width)
		local hx, hy, hz = getWorldTranslation(workArea.height)
		local lsx, lsy, lsz, lex, ley, lez, lineRadius = DensityMapHeightUtil.getLineByAreaDimensions(sx, sy, sz, wx, wy, wz, hx, hy, hz)

		for _, fruitType in ipairs(spec.workAreaParameters.fruitTypesToUse) do
			local fillType = g_fruitTypeManager:getWindrowFillTypeIndexByFruitTypeIndex(fruitType)

			if fillType ~= nil then
				local pickedUpLiters = -DensityMapHeightUtil.tipToGroundAroundLine(self, -math.huge, fillType, lsx, lsy, lsz, lex, ley, lez, lineRadius, nil, , false, nil)

				if self.isServer and pickedUpLiters > 0 then
					local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(fruitType)
					local literPerSqm = fruitDesc.literPerSqm
					local lastCutterArea = pickedUpLiters / (g_currentMission:getFruitPixelsToSqm() * literPerSqm)

					if fruitType ~= spec.currentInputFruitType then
						spec.currentInputFruitType = fruitType
						spec.currentOutputFillType = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.currentInputFruitType)

						if spec.fruitTypeConverters[spec.currentInputFruitType] ~= nil then
							spec.currentOutputFillType = spec.fruitTypeConverters[spec.currentInputFruitType].fillTypeIndex
							spec.currentConversionFactor = spec.fruitTypeConverters[spec.currentInputFruitType].conversionFactor
						end
					end

					spec.useWindrow = true
					spec.currentInputFillType = fillType
					spec.workAreaParameters.lastFruitType = fruitType
					spec.workAreaParameters.lastRealArea = spec.workAreaParameters.lastRealArea + lastCutterArea
					spec.workAreaParameters.lastThreshedArea = spec.workAreaParameters.lastThreshedArea + lastCutterArea
					spec.workAreaParameters.lastStatsArea = spec.workAreaParameters.lastStatsArea + lastCutterArea
					spec.workAreaParameters.lastArea = spec.workAreaParameters.lastArea + lastCutterArea
					spec.stoneLastState = FSDensityMapUtil.getStoneArea(sx, sz, wx, wz, hx, hz)
					spec.isWorking = true

					break
				end
			end
		end
	end

	return spec.workAreaParameters.lastRealArea, spec.workAreaParameters.lastArea
end

function Cutter:onStartWorkAreaProcessing(dt)
	local spec = self.spec_cutter
	local combineVehicle, alternativeCombine, requiredFillType = self:getCombine()

	if combineVehicle == nil and requiredFillType ~= nil then
		combineVehicle = alternativeCombine
	end

	spec.workAreaParameters.combineVehicle = combineVehicle
	spec.workAreaParameters.lastRealArea = 0
	spec.workAreaParameters.lastThreshedArea = 0
	spec.workAreaParameters.lastStatsArea = 0
	spec.workAreaParameters.lastArea = 0
	spec.workAreaParameters.lastGrowthState = 0
	spec.workAreaParameters.lastGrowthStateArea = 0
	spec.workAreaParameters.lastChopperValue = nil

	if spec.workAreaParameters.lastFruitType == nil then
		spec.workAreaParameters.fruitTypesToUse = spec.fruitTypes
	else
		for i = 1, #spec.workAreaParameters.lastFruitTypeToUse do
			spec.workAreaParameters.lastFruitTypeToUse[i] = nil
		end

		spec.workAreaParameters.lastFruitTypeToUse[1] = spec.workAreaParameters.lastFruitType
		spec.workAreaParameters.fruitTypesToUse = spec.workAreaParameters.lastFruitTypeToUse
	end

	if requiredFillType ~= nil then
		for i = 1, #spec.workAreaParameters.lastFruitTypeToUse do
			spec.workAreaParameters.lastFruitTypeToUse[i] = nil
		end

		local fruitType = g_fruitTypeManager:getFruitTypeIndexByFillTypeIndex(requiredFillType)

		for inputFruitType, fruitTypeConverter in pairs(spec.fruitTypeConverters) do
			if fruitTypeConverter.fillTypeIndex == requiredFillType then
				table.insert(spec.workAreaParameters.lastFruitTypeToUse, inputFruitType)

				fruitType = nil
			end
		end

		if fruitType ~= nil then
			table.insert(spec.workAreaParameters.lastFruitTypeToUse, fruitType)
		end

		spec.workAreaParameters.fruitTypesToUse = spec.workAreaParameters.lastFruitTypeToUse
	end

	spec.workAreaParameters.lastFruitType = nil
	spec.isWorking = false
end

function Cutter:onEndWorkAreaProcessing(dt, hasProcessed)
	if self.isServer then
		local spec = self.spec_cutter
		local lastRealArea = spec.workAreaParameters.lastRealArea
		local lastThreshedArea = spec.workAreaParameters.lastThreshedArea
		local lastStatsArea = spec.workAreaParameters.lastStatsArea
		local lastArea = spec.workAreaParameters.lastArea

		if lastRealArea > 0 then
			if spec.workAreaParameters.combineVehicle ~= nil then
				local inputFruitType = spec.workAreaParameters.lastFruitType

				if self:getIsAIActive() then
					local requirements = self:getAIFruitRequirements()
					local requirement = requirements[1]

					if #requirements == 1 and requirement ~= nil and requirement.fruitType ~= FruitType.UNKNOWN then
						inputFruitType = requirement.fruitType
					end
				end

				local conversionFactor = spec.currentConversionFactor or 1
				local outputFillType = spec.currentOutputFillType
				local targetOutputFillType = outputFillType

				if spec.lastOutputFillTypes[outputFillType] == nil then
					spec.lastOutputFillTypes[outputFillType] = lastRealArea
				else
					spec.lastOutputFillTypes[outputFillType] = spec.lastOutputFillTypes[outputFillType] + lastRealArea
				end

				if spec.lastPrioritizedOutputType ~= FillType.UNKNOWN then
					outputFillType = spec.lastPrioritizedOutputType
				end

				lastRealArea = lastRealArea * conversionFactor
				local farmId = self:getLastTouchedFarmlandFarmId()
				local strawGroundType = spec.workAreaParameters.lastChopperValue
				local appliedDelta = spec.workAreaParameters.combineVehicle:addCutterArea(lastArea, lastRealArea, inputFruitType, outputFillType, spec.strawRatio, strawGroundType, farmId, self:getCutterLoad())

				if appliedDelta > 0 and outputFillType == targetOutputFillType then
					spec.lastValidInputFruitType = inputFruitType
				end
			end

			local ha = MathUtil.areaToHa(lastStatsArea, g_currentMission:getFruitPixelsToSqm())
			local stats = g_currentMission:farmStats(self:getLastTouchedFarmlandFarmId())

			stats:updateStats("threshedHectares", ha)
			self:updateLastWorkedArea(lastStatsArea)

			spec.lastAreaBiggerZero = lastArea > 0

			if spec.lastAreaBiggerZero then
				spec.lastAreaBiggerZeroTime = g_currentMission.time
			end

			if spec.lastAreaBiggerZero ~= spec.lastAreaBiggerZeroSent then
				self:raiseDirtyFlags(spec.dirtyFlag)

				spec.lastAreaBiggerZeroSent = spec.lastAreaBiggerZero
			end

			if spec.currentInputFruitType ~= spec.currentInputFruitTypeSent then
				self:raiseDirtyFlags(spec.effectDirtyFlag)

				spec.currentInputFruitTypeSent = spec.currentInputFruitType
			end

			if self:getAllowCutterAIFruitRequirements() then
				if self.setAIFruitRequirements ~= nil then
					local requirements = self:getAIFruitRequirements()
					local requirement = requirements[1]

					if #requirements > 1 or requirement == nil or requirement.fruitType == FruitType.UNKNOWN then
						local fruitType = g_fruitTypeManager:getFruitTypeByIndex(spec.currentInputFruitTypeAI)

						if fruitType ~= nil then
							local minState = spec.allowsForageGrowthState and fruitType.minForageGrowthState or fruitType.minHarvestingGrowthState

							self:setAIFruitRequirements(spec.currentInputFruitTypeAI, minState, fruitType.maxHarvestingGrowthState)
						end
					end
				end

				spec.aiNoValidGroundTimer = 0
			end
		elseif self:getAllowCutterAIFruitRequirements() and hasProcessed then
			if self:getIsAIActive() and self:getLastSpeed() > 5 then
				spec.aiNoValidGroundTimer = spec.aiNoValidGroundTimer + dt

				if spec.aiNoValidGroundTimer > 5000 then
					local rootVehicle = self.rootVehicle

					if rootVehicle.stopCurrentAIJob ~= nil then
						rootVehicle:stopCurrentAIJob(AIMessageErrorUnknown.new())
					end
				end
			else
				spec.aiNoValidGroundTimer = 0
			end
		end
	end
end

function Cutter:getCutterLoad()
	local speedLimitFactor = MathUtil.clamp(self:getLastSpeed() / self.speedLimit, 0, 1) * 0.75 + 0.25

	return self.spec_cutter.cutterLoad * speedLimitFactor
end

function Cutter:getCutterStoneMultiplier()
	local spec = self.spec_cutter

	if spec.stoneLastState ~= 0 and spec.stoneWearMultiplierData ~= nil then
		return spec.stoneWearMultiplierData[spec.stoneLastState] or 1
	end

	return 1
end

function Cutter:loadCutterTiltFromXML(xmlFile, key, target)
	target.nodes = {}

	xmlFile:iterate(key .. ".automaticTiltNode", function (index, nodeKey)
		local entry = {
			node = xmlFile:getValue(nodeKey .. "#node", nil, self.components, self.i3dMappings)
		}

		if entry.node ~= nil then
			entry.minAngle = xmlFile:getValue(nodeKey .. "#minAngle", -5)
			entry.maxAngle = xmlFile:getValue(nodeKey .. "#maxAngle", 5)
			entry.maxSpeed = xmlFile:getValue(nodeKey .. "#maxSpeed", 2) / 1000

			table.insert(target.nodes, entry)
		end
	end)

	target.raycastNode1 = xmlFile:getValue(key .. "#raycastNode1", nil, self.components, self.i3dMappings)
	target.raycastNode2 = xmlFile:getValue(key .. "#raycastNode2", nil, self.components, self.i3dMappings)

	if target.raycastNode1 ~= nil and target.raycastNode2 ~= nil then
		local x1, _, _ = localToLocal(target.raycastNode1, self.rootNode, 0, 0, 0)
		local x2, _, _ = localToLocal(target.raycastNode2, self.rootNode, 0, 0, 0)

		if x1 < x2 then
			local raycastNode1 = target.raycastNode1
			target.raycastNode1 = target.raycastNode2
			target.raycastNode2 = raycastNode1
		end
	else
		return false
	end

	return true
end

function Cutter:getCutterTiltIsAvailable()
	return self.spec_cutter.automaticTilt.isAvailable
end

function Cutter:getCutterTiltIsActive(automaticTilt)
	if not automaticTilt.isAvailable or not self:getIsActive() then
		return false, false
	end

	if not self:getIsLowered(true) or self.getAttacherVehicle ~= nil and self:getAttacherVehicle() == nil then
		return false, true
	end

	return true, false
end

function Cutter:getCutterTiltDelta()
	local spec = self.spec_cutter

	return spec.automaticTilt.currentDelta, self:getCutterTiltIsActive(spec.automaticTilt)
end

function Cutter:tiltRaycastDetectionCallback(hitObjectId, x, y, z, distance)
	if getRigidBodyType(hitObjectId) ~= RigidBodyType.STATIC then
		return true
	end

	local automaticTilt = self.spec_cutter.automaticTilt
	automaticTilt.lastHit[1] = x
	automaticTilt.lastHit[2] = y
	automaticTilt.lastHit[3] = z
	automaticTilt.raycastHit = true

	return false
end

function Cutter:setCutterCutHeight(cutHeight)
	if cutHeight ~= nil then
		self.spec_cutter.currentCutHeight = cutHeight

		if self.spec_attachable ~= nil then
			local inputAttacherJoint = self:getActiveInputAttacherJoint()

			if inputAttacherJoint ~= nil then
				if inputAttacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTER or inputAttacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTERHARVESTER then
					inputAttacherJoint.lowerDistanceToGround = cutHeight
				end
			else
				local inputAttacherJoints = self:getInputAttacherJoints()

				for i = 1, #inputAttacherJoints do
					inputAttacherJoint = inputAttacherJoints[i]

					if inputAttacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTER or inputAttacherJoint.jointType == AttacherJoints.JOINTTYPE_CUTTERHARVESTER then
						inputAttacherJoint.lowerDistanceToGround = cutHeight
					end
				end
			end
		end
	end
end

function Cutter:loadSpeedRotatingPartFromXML(superFunc, speedRotatingPart, xmlFile, key)
	if not superFunc(self, speedRotatingPart, xmlFile, key) then
		return false
	end

	speedRotatingPart.rotateIfTurnedOn = xmlFile:getValue(key .. "#rotateIfTurnedOn", false)

	return true
end

function Cutter:getIsSpeedRotatingPartActive(superFunc, speedRotatingPart)
	if speedRotatingPart.rotateIfTurnedOn and not self:getIsTurnedOn() then
		return false
	end

	return superFunc(self, speedRotatingPart)
end

function Cutter:loadRandomlyMovingPartFromXML(superFunc, part, xmlFile, key)
	local retValue = superFunc(self, part, xmlFile, key)
	part.moveOnlyIfCut = xmlFile:getValue(key .. "#moveOnlyIfCut", false)

	return retValue
end

function Cutter:getIsRandomlyMovingPartActive(superFunc, part)
	local retValue = superFunc(self, part)

	if part.moveOnlyIfCut then
		retValue = retValue and self.spec_cutter.lastAreaBiggerZeroTime >= g_currentMission.time - 150
	end

	return retValue
end

function Cutter:getIsWorkAreaActive(superFunc, workArea)
	local spec = self.spec_cutter

	if (self.getAllowsLowering == nil or self:getAllowsLowering()) and not spec.allowCuttingWhileRaised and not self:getIsLowered(true) then
		return false
	end

	return superFunc(self, workArea)
end

function Cutter:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsTurnedOn() and (self.getIsLowered == nil or self:getIsLowered())
end

function Cutter:loadWorkAreaFromXML(superFunc, workArea, xmlFile, key)
	local retValue = superFunc(self, workArea, xmlFile, key)
	workArea.chopperAreaIndex = xmlFile:getValue(key .. ".chopperArea#index")

	return retValue
end

function Cutter:getDirtMultiplier(superFunc)
	local spec = self.spec_cutter

	if spec.isWorking then
		return superFunc(self) + self:getWorkDirtMultiplier() * self:getLastSpeed() / self.speedLimit
	end

	return superFunc(self)
end

function Cutter:getWearMultiplier(superFunc)
	local spec = self.spec_cutter

	if spec.isWorking then
		local stoneMultiplier = 1

		if spec.stoneLastState ~= 0 and spec.stoneWearMultiplierData ~= nil then
			stoneMultiplier = spec.stoneWearMultiplierData[spec.stoneLastState] or 1
		end

		return superFunc(self) + self:getWorkWearMultiplier() * self:getLastSpeed() / self.speedLimit * stoneMultiplier
	end

	return superFunc(self)
end

function Cutter:isAttachAllowed(superFunc, farmId, attacherVehicle)
	local spec = self.spec_cutter

	if attacherVehicle.spec_combine ~= nil and not attacherVehicle:getIsCutterCompatible(spec.fillTypes) then
		return false, g_i18n:getText("info_attach_not_allowed")
	end

	return superFunc(self, farmId, attacherVehicle)
end

function Cutter:getConsumingLoad(superFunc)
	local value, count = superFunc(self)
	local loadPercentage = self:getCutterLoad()

	return value + loadPercentage, count + 1
end

function Cutter:getIsGroundReferenceNodeThreshold(superFunc, groundReferenceNode)
	local threshold = superFunc(self, groundReferenceNode)
	threshold = threshold + self.spec_cutter.currentCutHeight

	return threshold
end

function Cutter:onPreAttach(attacherVehicle, inputJointDescIndex, jointDescIndex)
	if self.isClient then
		Cutter.updateExtraObjects(self)
	end
end

function Cutter:onPostDetach(attacherVehicle, implement)
	if self.isClient then
		Cutter.updateExtraObjects(self)
	end
end

function Cutter:onTurnedOn()
	if self.isClient then
		local spec = self.spec_cutter

		g_animationManager:startAnimations(spec.animationNodes)
	end
end

function Cutter:onTurnedOff()
	local spec = self.spec_cutter

	if self.isClient then
		g_animationManager:stopAnimations(spec.animationNodes)
		g_effectManager:resetEffects(spec.currentCutterEffect)
	end

	spec.currentInputFruitType = FruitType.UNKNOWN
	spec.currentInputFruitTypeSent = FruitType.UNKNOWN
	spec.currentInputFruitTypeAI = FruitType.UNKNOWN
	spec.currentInputFillType = FillType.UNKNOWN
	spec.currentOutputFillType = FillType.UNKNOWN
end

function Cutter:onAIImplementStart()
	if self:getAllowCutterAIFruitRequirements() then
		self:clearAIFruitRequirements()

		local spec = self.spec_cutter

		for _, fruitTypeIndex in ipairs(spec.fruitTypes) do
			local fruitType = g_fruitTypeManager:getFruitTypeByIndex(fruitTypeIndex)

			if fruitType ~= nil then
				local minState = spec.allowsForageGrowthState and fruitType.minForageGrowthState or fruitType.minHarvestingGrowthState

				self:addAIFruitRequirement(fruitType.index, minState, fruitType.maxHarvestingGrowthState)
			end
		end
	end
end

function Cutter:updateExtraObjects()
	local spec = self.spec_cutter

	if spec.lastValidInputFruitType ~= nil then
		local extraObject = spec.fruitExtraObjects[spec.lastValidInputFruitType]

		if spec.hideExtraObjectsOnDetach and (self.getAttacherVehicle == nil or self:getAttacherVehicle() == nil) then
			extraObject = nil
		end

		if extraObject ~= spec.currentExtraObject then
			if spec.currentExtraObject ~= nil then
				if spec.currentExtraObject.node ~= nil then
					setVisibility(spec.currentExtraObject.node, false)
				end

				if spec.currentExtraObject.anim ~= nil and self.playAnimation ~= nil then
					self:playAnimation(spec.currentExtraObject.anim, -1, self:getAnimationTime(spec.currentExtraObject.anim), true)
				end

				spec.currentExtraObject = nil
			end

			if extraObject ~= nil then
				if extraObject.node ~= nil then
					setVisibility(extraObject.node, true)
				end

				if extraObject.anim ~= nil and self.playAnimation ~= nil then
					self:playAnimation(extraObject.anim, 1, self:getAnimationTime(extraObject.anim), true)
				end

				spec.currentExtraObject = extraObject
			end
		end
	end
end

function Cutter.getDefaultSpeedLimit()
	return 10
end

function Cutter:updateDebugValues(values)
	local spec = self.spec_cutter

	table.insert(values, {
		name = "lastPrioritizedOutputType",
		value = string.format("%s", g_fillTypeManager:getFillTypeNameByIndex(spec.lastPrioritizedOutputType))
	})

	local sum = 0

	for fillType, value in pairs(spec.lastOutputFillTypes) do
		sum = sum + value
	end

	for fillType, value in pairs(spec.lastOutputFillTypes) do
		table.insert(values, {
			name = string.format("buffer (%s)", g_fillTypeManager:getFillTypeNameByIndex(fillType)),
			value = string.format("%.0f%%", value / sum * 100)
		})
	end
end
