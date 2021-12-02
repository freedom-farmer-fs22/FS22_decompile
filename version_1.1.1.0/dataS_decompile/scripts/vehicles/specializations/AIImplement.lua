AIImplement = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function AIImplement.initSpecialization()
	g_configurationManager:addConfigurationType("ai", g_i18n:getText("configuration_design"), "ai", nil, , , ConfigurationUtil.SELECTOR_MULTIOPTION)

	local schema = Vehicle.xmlSchema

	schema:setXMLSpecializationType("AIImplement")
	AIImplement.registerAIImplementXMLPaths(schema, "vehicle.ai")
	AIImplement.registerAIImplementXMLPaths(schema, "vehicle.ai.aiConfigurations.aiConfiguration(?)")
	ObjectChangeUtil.registerObjectChangeXMLPaths(schema, "vehicle.ai.aiConfigurations.aiConfiguration(?)")
	schema:setXMLSpecializationType()
end

function AIImplement.registerAIImplementXMLPaths(schema, basePath)
	schema:register(XMLValueType.FLOAT, basePath .. ".minTurningRadius#value", "Min turning radius")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".areaMarkers#leftNode", "AI area left node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".areaMarkers#rightNode", "AI area right node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".areaMarkers#backNode", "AI area back node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".sizeMarkers#leftNode", "Size area left node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".sizeMarkers#rightNode", "Size area right node")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".sizeMarkers#backNode", "Size area back node")
	AIImplement.registerAICollisionTriggerXMLPaths(schema, basePath)
	schema:register(XMLValueType.BOOL, basePath .. ".needsLowering#value", "AI needs to lower this tool", true)
	schema:register(XMLValueType.BOOL, basePath .. ".needsLowering#lowerIfAnyIsLowered", "Lower tool of any attached ai tool is lowered", false)
	schema:register(XMLValueType.BOOL, basePath .. ".needsRootAlignment#value", "Tool needs to point in the same direction as the root while working", true)
	schema:register(XMLValueType.BOOL, basePath .. ".allowTurnBackward#value", "Worker is allowed the turn backward with this tool", true)
	schema:register(XMLValueType.BOOL, basePath .. ".blockTurnBackward#value", "Can be used for non ai tools to block ai from driving backward", false)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".toolReverserDirectionNode#node", "Reverser direction node, target node if driving backward")
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".turningRadiusLimitation#rotationJointNode", "Turn radius limitation joint node")
	schema:register(XMLValueType.VECTOR_N, basePath .. ".turningRadiusLimitation#wheelIndices", "Turn radius limitation wheel indices")
	schema:register(XMLValueType.FLOAT, basePath .. ".turningRadiusLimitation#radius", "Turn radius limitation radius")
	schema:register(XMLValueType.FLOAT, basePath .. ".turningRadiusLimitation#rotLimitFactor", "Changes the rot limit of attacher joint or component joint for turning radius calculation", 1)
	schema:register(XMLValueType.FLOAT, basePath .. ".lookAheadSize#value", "Look a head size to check ground in front of tool", 2)
	schema:register(XMLValueType.BOOL, basePath .. ".useAttributesOfAttachedImplement#value", "Use AI attributes (area & fruit/ground requirements) of first attached implement", false)
	schema:register(XMLValueType.BOOL, basePath .. ".hasNoFullCoverageArea#value", "Tool as a no full coverage area (e.g. plows)", false)
	schema:register(XMLValueType.FLOAT, basePath .. ".hasNoFullCoverageArea#offset", "Non full coverage area offset", 0)
	schema:register(XMLValueType.FLOAT, basePath .. ".overlap#value", "Defines the ai line to line overlap", AIVehicleUtil.AREA_OVERLAP)
end

function AIImplement.registerAICollisionTriggerXMLPaths(schema, basePath)
	schema:register(XMLValueType.NODE_INDEX, basePath .. ".collisionTrigger#node", "Collision trigger node")
	schema:register(XMLValueType.FLOAT, basePath .. ".collisionTrigger#width", "Width of ai collision trigger", 4)
	schema:register(XMLValueType.FLOAT, basePath .. ".collisionTrigger#height", "Width of ai collision trigger", 3)
	schema:register(XMLValueType.FLOAT, basePath .. ".collisionTrigger#length", "Max. length of ai collision trigger", 5)
end

function AIImplement.registerEvents(vehicleType)
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementStart")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementActive")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementEnd")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementStartLine")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementEndLine")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementStartTurn")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementTurnProgress")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementEndTurn")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementBlock")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementContinue")
	SpecializationUtil.registerEvent(vehicleType, "onAIImplementPrepare")
end

function AIImplement.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "loadAICollisionTriggerFromXML", AIImplement.loadAICollisionTriggerFromXML)
	SpecializationUtil.registerFunction(vehicleType, "getCanAIImplementContinueWork", AIImplement.getCanAIImplementContinueWork)
	SpecializationUtil.registerFunction(vehicleType, "getCanImplementBeUsedForAI", AIImplement.getCanImplementBeUsedForAI)
	SpecializationUtil.registerFunction(vehicleType, "getAIMinTurningRadius", AIImplement.getAIMinTurningRadius)
	SpecializationUtil.registerFunction(vehicleType, "getAIMarkers", AIImplement.getAIMarkers)
	SpecializationUtil.registerFunction(vehicleType, "setAIMarkersInverted", AIImplement.setAIMarkersInverted)
	SpecializationUtil.registerFunction(vehicleType, "getAIInvertMarkersOnTurn", AIImplement.getAIInvertMarkersOnTurn)
	SpecializationUtil.registerFunction(vehicleType, "getAISizeMarkers", AIImplement.getAISizeMarkers)
	SpecializationUtil.registerFunction(vehicleType, "getAILookAheadSize", AIImplement.getAILookAheadSize)
	SpecializationUtil.registerFunction(vehicleType, "getAIHasNoFullCoverageArea", AIImplement.getAIHasNoFullCoverageArea)
	SpecializationUtil.registerFunction(vehicleType, "getAIAreaOverlap", AIImplement.getAIAreaOverlap)
	SpecializationUtil.registerFunction(vehicleType, "getAIImplementCollisionTrigger", AIImplement.getAIImplementCollisionTrigger)
	SpecializationUtil.registerFunction(vehicleType, "getAIImplementCollisionTriggers", AIImplement.getAIImplementCollisionTriggers)
	SpecializationUtil.registerFunction(vehicleType, "getAINeedsLowering", AIImplement.getAINeedsLowering)
	SpecializationUtil.registerFunction(vehicleType, "getAILowerIfAnyIsLowered", AIImplement.getAILowerIfAnyIsLowered)
	SpecializationUtil.registerFunction(vehicleType, "getAINeedsRootAlignment", AIImplement.getAINeedsRootAlignment)
	SpecializationUtil.registerFunction(vehicleType, "getAIAllowTurnBackward", AIImplement.getAIAllowTurnBackward)
	SpecializationUtil.registerFunction(vehicleType, "getAIBlockTurnBackward", AIImplement.getAIBlockTurnBackward)
	SpecializationUtil.registerFunction(vehicleType, "getAIToolReverserDirectionNode", AIImplement.getAIToolReverserDirectionNode)
	SpecializationUtil.registerFunction(vehicleType, "getAITurnRadiusLimitation", AIImplement.getAITurnRadiusLimitation)
	SpecializationUtil.registerFunction(vehicleType, "setAIFruitProhibitions", AIImplement.setAIFruitProhibitions)
	SpecializationUtil.registerFunction(vehicleType, "addAIFruitProhibitions", AIImplement.addAIFruitProhibitions)
	SpecializationUtil.registerFunction(vehicleType, "clearAIFruitProhibitions", AIImplement.clearAIFruitProhibitions)
	SpecializationUtil.registerFunction(vehicleType, "getAIFruitProhibitions", AIImplement.getAIFruitProhibitions)
	SpecializationUtil.registerFunction(vehicleType, "setAIFruitRequirements", AIImplement.setAIFruitRequirements)
	SpecializationUtil.registerFunction(vehicleType, "addAIFruitRequirement", AIImplement.addAIFruitRequirement)
	SpecializationUtil.registerFunction(vehicleType, "clearAIFruitRequirements", AIImplement.clearAIFruitRequirements)
	SpecializationUtil.registerFunction(vehicleType, "getAIFruitRequirements", AIImplement.getAIFruitRequirements)
	SpecializationUtil.registerFunction(vehicleType, "setAIDensityHeightTypeRequirements", AIImplement.setAIDensityHeightTypeRequirements)
	SpecializationUtil.registerFunction(vehicleType, "addAIDensityHeightTypeRequirement", AIImplement.addAIDensityHeightTypeRequirement)
	SpecializationUtil.registerFunction(vehicleType, "clearAIDensityHeightTypeRequirements", AIImplement.clearAIDensityHeightTypeRequirements)
	SpecializationUtil.registerFunction(vehicleType, "getAIDensityHeightTypeRequirements", AIImplement.getAIDensityHeightTypeRequirements)
	SpecializationUtil.registerFunction(vehicleType, "addAITerrainDetailRequiredRange", AIImplement.addAITerrainDetailRequiredRange)
	SpecializationUtil.registerFunction(vehicleType, "addAIGroundTypeRequirements", AIImplement.addAIGroundTypeRequirements)
	SpecializationUtil.registerFunction(vehicleType, "clearAITerrainDetailRequiredRange", AIImplement.clearAITerrainDetailRequiredRange)
	SpecializationUtil.registerFunction(vehicleType, "getAITerrainDetailRequiredRange", AIImplement.getAITerrainDetailRequiredRange)
	SpecializationUtil.registerFunction(vehicleType, "addAITerrainDetailProhibitedRange", AIImplement.addAITerrainDetailProhibitedRange)
	SpecializationUtil.registerFunction(vehicleType, "clearAITerrainDetailProhibitedRange", AIImplement.clearAITerrainDetailProhibitedRange)
	SpecializationUtil.registerFunction(vehicleType, "getAITerrainDetailProhibitedRange", AIImplement.getAITerrainDetailProhibitedRange)
	SpecializationUtil.registerFunction(vehicleType, "getFieldCropsQuery", AIImplement.getFieldCropsQuery)
	SpecializationUtil.registerFunction(vehicleType, "updateFieldCropsQuery", AIImplement.updateFieldCropsQuery)
	SpecializationUtil.registerFunction(vehicleType, "createFieldCropsQuery", AIImplement.createFieldCropsQuery)
	SpecializationUtil.registerFunction(vehicleType, "getIsAIImplementInLine", AIImplement.getIsAIImplementInLine)
	SpecializationUtil.registerFunction(vehicleType, "aiImplementStartLine", AIImplement.aiImplementStartLine)
	SpecializationUtil.registerFunction(vehicleType, "aiImplementEndLine", AIImplement.aiImplementEndLine)
end

function AIImplement.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addVehicleToAIImplementList", AIImplement.addVehicleToAIImplementList)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addNodeObjectMapping", AIImplement.addNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeNodeObjectMapping", AIImplement.removeNodeObjectMapping)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getAllowTireTracks", AIImplement.getAllowTireTracks)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getDoConsumePtoPower", AIImplement.getDoConsumePtoPower)
end

function AIImplement.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIImplement)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", AIImplement)
end

function AIImplement:onLoad(savegame)
	local spec = self.spec_aiImplement
	local baseName = "vehicle.ai"

	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseName .. ".areaMarkers#leftIndex", baseName .. ".areaMarkers#leftNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseName .. ".areaMarkers#rightIndex", baseName .. ".areaMarkers#rightNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseName .. ".areaMarkers#backIndex", baseName .. ".areaMarkers#backNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseName .. ".sizeMarkers#leftIndex", baseName .. ".sizeMarkers#leftNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseName .. ".sizeMarkers#rightIndex", baseName .. ".sizeMarkers#rightNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseName .. ".sizeMarkers#backIndex", baseName .. ".sizeMarkers#backNode")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseName .. ".trafficCollisionTrigger#index", baseName .. ".collisionTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseName .. ".trafficCollisionTrigger#node", baseName .. ".collisionTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseName .. ".collisionTrigger#index", baseName .. ".collisionTrigger#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, "vehicle.aiLookAheadSize#value", baseName .. ".lookAheadSize#value")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseName .. ".toolReverserDirectionNode#index", baseName .. ".toolReverserDirectionNode#node")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseName .. ".turningRadiusLimiation", baseName .. ".turningRadiusLimitation")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseName .. ".forceTurnNoBackward#value", baseName .. ".allowTurnBackward#value (inverted)")
	XMLUtil.checkDeprecatedXMLElements(self.xmlFile, baseName .. ".needsLowering#lowerIfAnyIsLowerd", baseName .. ".allowTurnBackward#lowerIfAnyIsLowered")

	local aiConfigurationId = Utils.getNoNil(self.configurations.ai, 1)
	local configKey = string.format("vehicle.ai.aiConfigurations.aiConfiguration(%d)", aiConfigurationId - 1)

	ObjectChangeUtil.updateObjectChanges(self.xmlFile, "vehicle.ai.aiConfigurations.aiConfiguration", aiConfigurationId, self.components, self)

	if self.xmlFile:hasProperty(configKey) then
		baseName = configKey
	end

	spec.minTurningRadius = self.xmlFile:getValue(baseName .. ".minTurningRadius#value")
	spec.leftMarker = self.xmlFile:getValue(baseName .. ".areaMarkers#leftNode", nil, self.components, self.i3dMappings)
	spec.rightMarker = self.xmlFile:getValue(baseName .. ".areaMarkers#rightNode", nil, self.components, self.i3dMappings)
	spec.backMarker = self.xmlFile:getValue(baseName .. ".areaMarkers#backNode", nil, self.components, self.i3dMappings)
	spec.aiMarkersInverted = false
	spec.sizeLeftMarker = self.xmlFile:getValue(baseName .. ".sizeMarkers#leftNode", nil, self.components, self.i3dMappings)
	spec.sizeRightMarker = self.xmlFile:getValue(baseName .. ".sizeMarkers#rightNode", nil, self.components, self.i3dMappings)
	spec.sizeBackMarker = self.xmlFile:getValue(baseName .. ".sizeMarkers#backNode", nil, self.components, self.i3dMappings)
	spec.collisionTrigger = self:loadAICollisionTriggerFromXML(self.xmlFile, baseName)
	spec.needsLowering = self.xmlFile:getValue(baseName .. ".needsLowering#value", true)
	spec.lowerIfAnyIsLowered = self.xmlFile:getValue(baseName .. ".needsLowering#lowerIfAnyIsLowered", false)
	spec.needsRootAlignment = self.xmlFile:getValue(baseName .. ".needsRootAlignment#value", true)
	spec.allowTurnBackward = self.xmlFile:getValue(baseName .. ".allowTurnBackward#value", true)
	spec.blockTurnBackward = self.xmlFile:getValue(baseName .. ".blockTurnBackward#value", false)
	spec.toolReverserDirectionNode = self.xmlFile:getValue(baseName .. ".toolReverserDirectionNode#node", nil, self.components, self.i3dMappings)
	spec.turningRadiusLimitation = {
		rotationJoint = self.xmlFile:getValue(baseName .. ".turningRadiusLimitation#rotationJointNode", nil, self.components, self.i3dMappings)
	}

	if spec.turningRadiusLimitation.rotationJoint ~= nil then
		spec.turningRadiusLimitation.wheelIndices = self.xmlFile:getValue(baseName .. ".turningRadiusLimitation#wheelIndices", nil, true)
	end

	spec.turningRadiusLimitation.radius = self.xmlFile:getValue(baseName .. ".turningRadiusLimitation#radius")
	spec.turningRadiusLimitation.rotLimitFactor = self.xmlFile:getValue(baseName .. ".turningRadiusLimitation#rotLimitFactor", 1)
	spec.lookAheadSize = self.xmlFile:getValue(baseName .. ".lookAheadSize#value", 2)
	spec.useAttributesOfAttachedImplement = self.xmlFile:getValue(baseName .. ".useAttributesOfAttachedImplement#value", false)
	spec.hasNoFullCoverageArea = self.xmlFile:getValue(baseName .. ".hasNoFullCoverageArea#value", false)
	spec.hasNoFullCoverageAreaOffset = self.xmlFile:getValue(baseName .. ".hasNoFullCoverageArea#offset", 0)
	spec.overlap = self.xmlFile:getValue(baseName .. ".overlap#value", AIVehicleUtil.AREA_OVERLAP)
	spec.terrainDetailRequiredValueRanges = {}
	spec.terrainDetailProhibitedValueRanges = {}
	spec.requiredFruitTypes = {}
	spec.prohibitedFruitTypes = {}
	spec.requiredDensityHeightTypes = {}
	local _ = nil
	spec.fieldGroundSystem = g_currentMission.fieldGroundSystem
	_, spec.groundTypeFirstChannel, spec.groundTypeNumChannels = spec.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)
	spec.fieldCropyQuery = nil
	spec.fieldCropyQueryValid = false
	spec.isLineStarted = false
end

function AIImplement:onPostLoad(savegame)
	if self.getWheels ~= nil then
		local spec = self.spec_aiImplement

		if spec.turningRadiusLimitation.wheelIndices ~= nil then
			spec.turningRadiusLimitation.wheels = {}
			local wheels = self:getWheels()

			for _, index in ipairs(spec.turningRadiusLimitation.wheelIndices) do
				local wheel = wheels[index]

				if wheel ~= nil then
					table.insert(spec.turningRadiusLimitation.wheels, wheels[index])
				else
					Logging.xmlWarning(self.xmlFile, "Unknown wheel index '%s' defined in '%s'", index, "vehicle.ai.turningRadiusLimitation#wheelIndices")
				end
			end
		end
	end
end

function AIImplement:loadAICollisionTriggerFromXML(xmlFile, key)
	local collisionTrigger = {
		node = xmlFile:getValue(key .. ".collisionTrigger#node", nil, self.components, self.i3dMappings)
	}

	if collisionTrigger.node ~= nil then
		if getHasClassId(collisionTrigger.node, ClassIds.SHAPE) then
			Logging.xmlWarning(xmlFile, "Obsolete ai collision trigger ground. Please replace with empty transform group and add size attributes. '%s'", key .. ".collisionTrigger#node")
		end

		collisionTrigger.width = xmlFile:getValue(key .. ".collisionTrigger#width", 4)
		collisionTrigger.height = xmlFile:getValue(key .. ".collisionTrigger#height", 3)
		collisionTrigger.length = xmlFile:getValue(key .. ".collisionTrigger#length", 5)
	else
		return nil
	end

	return collisionTrigger
end

function AIImplement:getCanAIImplementContinueWork()
	return true, false, nil
end

function AIImplement:getCanImplementBeUsedForAI()
	local leftMarker, rightMarker, backMarker, _ = self:getAIMarkers()

	if leftMarker == nil or rightMarker == nil or backMarker == nil then
		return false
	end

	return true
end

function AIImplement:addVehicleToAIImplementList(superFunc, list)
	if self:getCanImplementBeUsedForAI() then
		table.insert(list, {
			object = self
		})
	end

	superFunc(self, list)
end

function AIImplement:addNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_aiImplement

	if spec.collisionTrigger ~= nil then
		list[spec.collisionTrigger] = self
	end
end

function AIImplement:removeNodeObjectMapping(superFunc, list)
	superFunc(self, list)

	local spec = self.spec_aiImplement

	if spec.collisionTrigger ~= nil then
		list[spec.collisionTrigger] = nil
	end
end

function AIImplement:getAllowTireTracks(superFunc)
	return superFunc(self) and not self:getIsAIActive()
end

function AIImplement:getDoConsumePtoPower(superFunc)
	local rootVehicle = self.rootVehicle

	if rootVehicle.getAIFieldWorkerIsTurning ~= nil and rootVehicle:getAIFieldWorkerIsTurning() then
		return false
	end

	return superFunc(self)
end

function AIImplement:getAIMinTurningRadius()
	return self.spec_aiImplement.minTurningRadius
end

function AIImplement:getAIMarkers()
	local spec = self.spec_aiImplement

	if spec.useAttributesOfAttachedImplement and self.getAttachedImplements ~= nil then
		for _, implement in ipairs(self:getAttachedImplements()) do
			if implement.object.getAIMarkers ~= nil then
				return implement.object:getAIMarkers()
			end
		end
	end

	if spec.aiMarkersInverted then
		return spec.rightMarker, spec.leftMarker, spec.backMarker, true
	else
		return spec.leftMarker, spec.rightMarker, spec.backMarker, false
	end
end

function AIImplement:setAIMarkersInverted(state)
	local spec = self.spec_aiImplement
	spec.aiMarkersInverted = not spec.aiMarkersInverted
end

function AIImplement:getAIInvertMarkersOnTurn(turnLeft)
	return false
end

function AIImplement:getAISizeMarkers()
	local spec = self.spec_aiImplement

	return spec.sizeLeftMarker, spec.sizeRightMarker, spec.sizeBackMarker
end

function AIImplement:getAILookAheadSize()
	return self.spec_aiImplement.lookAheadSize
end

function AIImplement:getAIHasNoFullCoverageArea()
	return self.spec_aiImplement.hasNoFullCoverageArea, self.spec_aiImplement.hasNoFullCoverageAreaOffset
end

function AIImplement:getAIAreaOverlap()
	return self.spec_aiImplement.overlap
end

function AIImplement:getAIImplementCollisionTrigger()
	return self.spec_aiImplement.collisionTrigger
end

function AIImplement:getAIImplementCollisionTriggers(collisionTriggers)
	local collisionTrigger = self:getAIImplementCollisionTrigger()

	if collisionTrigger ~= nil then
		collisionTriggers[self] = collisionTrigger
	end
end

function AIImplement:getAINeedsLowering()
	return self.spec_aiImplement.needsLowering
end

function AIImplement:getAILowerIfAnyIsLowered()
	return self.spec_aiImplement.lowerIfAnyIsLowered
end

function AIImplement:getAINeedsRootAlignment()
	return self.spec_aiImplement.needsRootAlignment
end

function AIImplement:getAIAllowTurnBackward()
	return self.spec_aiImplement.allowTurnBackward
end

function AIImplement:getAIBlockTurnBackward()
	return self.spec_aiImplement.blockTurnBackward
end

function AIImplement:getAIToolReverserDirectionNode()
	return self.spec_aiImplement.toolReverserDirectionNode
end

function AIImplement:getAITurnRadiusLimitation()
	local turningRadiusLimitation = self.spec_aiImplement.turningRadiusLimitation

	return turningRadiusLimitation.radius, turningRadiusLimitation.rotationJoint, turningRadiusLimitation.wheels, turningRadiusLimitation.rotLimitFactor
end

function AIImplement:setAIFruitRequirements(fruitType, minGrowthState, maxGrowthState)
	self:clearAIFruitRequirements()
	self:addAIFruitRequirement(fruitType, minGrowthState, maxGrowthState)
end

function AIImplement:addAIFruitRequirement(fruitType, minGrowthState, maxGrowthState, customMapId, customMapStartChannel, customMapNumChannels)
	local spec = self.spec_aiImplement

	table.insert(spec.requiredFruitTypes, {
		fruitType = fruitType or 0,
		minGrowthState = minGrowthState or 0,
		maxGrowthState = maxGrowthState or 0,
		customMapId = customMapId,
		customMapStartChannel = customMapStartChannel,
		customMapNumChannels = customMapNumChannels
	})
	self:updateFieldCropsQuery()
end

function AIImplement:clearAIFruitRequirements()
	local spec = self.spec_aiImplement

	if #spec.requiredFruitTypes > 0 then
		spec.requiredFruitTypes = {}
	end

	self:updateFieldCropsQuery()
end

function AIImplement:getAIFruitRequirements()
	return self.spec_aiImplement.requiredFruitTypes
end

function AIImplement:setAIDensityHeightTypeRequirements(fillType)
	self:clearAIDensityHeightTypeRequirements()
	self:addAIDensityHeightTypeRequirement(fillType)
end

function AIImplement:addAIDensityHeightTypeRequirement(fillType)
	local spec = self.spec_aiImplement

	table.insert(spec.requiredDensityHeightTypes, {
		fillType = fillType or 0
	})
	self:updateFieldCropsQuery()
end

function AIImplement:clearAIDensityHeightTypeRequirements()
	local spec = self.spec_aiImplement

	if #spec.requiredDensityHeightTypes > 0 then
		spec.requiredDensityHeightTypes = {}
	end

	self:updateFieldCropsQuery()
end

function AIImplement:getAIDensityHeightTypeRequirements()
	return self.spec_aiImplement.requiredDensityHeightTypes
end

function AIImplement:setAIFruitProhibitions(fruitType, minGrowthState, maxGrowthState)
	self:clearAIFruitProhibitions()
	self:addAIFruitProhibitions(fruitType, minGrowthState, maxGrowthState)
	self:updateFieldCropsQuery()
end

function AIImplement:addAIFruitProhibitions(fruitType, minGrowthState, maxGrowthState, customMapId, customMapStartChannel, customMapNumChannels)
	local spec = self.spec_aiImplement

	table.insert(spec.prohibitedFruitTypes, {
		fruitType = fruitType or 0,
		minGrowthState = minGrowthState or 0,
		maxGrowthState = maxGrowthState or 0,
		customMapId = customMapId,
		customMapStartChannel = customMapStartChannel,
		customMapNumChannels = customMapNumChannels
	})
	self:updateFieldCropsQuery()
end

function AIImplement:clearAIFruitProhibitions()
	local spec = self.spec_aiImplement

	if #spec.prohibitedFruitTypes > 0 then
		spec.prohibitedFruitTypes = {}
	end

	self:updateFieldCropsQuery()
end

function AIImplement:getAIFruitProhibitions()
	return self.spec_aiImplement.prohibitedFruitTypes
end

function AIImplement:addAITerrainDetailRequiredRange(detailType1, detailType2, minState, maxState)
	local spec = self.spec_aiImplement

	table.insert(spec.terrainDetailRequiredValueRanges, {
		detailType1,
		detailType2,
		minState or spec.groundTypeFirstChannel,
		maxState or spec.groundTypeNumChannels
	})
	self:updateFieldCropsQuery()
end

function AIImplement:addAIGroundTypeRequirements(groundTypes, excludedType1, excludedType2, excludedType3, excludedType4, excludedType5, excludedType6)
	local spec = self.spec_aiImplement

	for i = 1, #groundTypes do
		local groundType = groundTypes[i]

		if groundType ~= excludedType1 and groundType ~= excludedType2 and groundType ~= excludedType3 and groundType ~= excludedType4 and groundType ~= excludedType5 and groundType ~= excludedType6 then
			local value = spec.fieldGroundSystem:getFieldGroundValue(groundType)

			table.insert(spec.terrainDetailRequiredValueRanges, {
				value,
				value,
				spec.groundTypeFirstChannel,
				spec.groundTypeNumChannels
			})
		end
	end

	self:updateFieldCropsQuery()
end

function AIImplement:clearAITerrainDetailRequiredRange()
	self.spec_aiImplement.terrainDetailRequiredValueRanges = {}

	self:updateFieldCropsQuery()
end

function AIImplement:getAITerrainDetailRequiredRange()
	local spec = self.spec_aiImplement

	if spec.useAttributesOfAttachedImplement and self.getAttachedImplements ~= nil then
		for _, implement in ipairs(self:getAttachedImplements()) do
			if implement.object.getAITerrainDetailRequiredRange ~= nil then
				return implement.object:getAITerrainDetailRequiredRange()
			end
		end
	end

	return spec.terrainDetailRequiredValueRanges
end

function AIImplement:addAITerrainDetailProhibitedRange(detailType1, detailType2, minState, maxState)
	table.insert(self.spec_aiImplement.terrainDetailProhibitedValueRanges, {
		detailType1,
		detailType2,
		minState,
		maxState
	})
	self:updateFieldCropsQuery()
end

function AIImplement:clearAITerrainDetailProhibitedRange()
	self.spec_aiImplement.terrainDetailProhibitedValueRanges = {}

	self:updateFieldCropsQuery()
end

function AIImplement:getAITerrainDetailProhibitedRange()
	local spec = self.spec_aiImplement

	if spec.useAttributesOfAttachedImplement and self.getAttachedImplements ~= nil then
		for _, implement in ipairs(self:getAttachedImplements()) do
			if implement.object.getAITerrainDetailProhibitedRange ~= nil then
				return implement.object:getAITerrainDetailProhibitedRange()
			end
		end
	end

	return spec.terrainDetailProhibitedValueRanges
end

function AIImplement:getFieldCropsQuery()
	local spec = self.spec_aiImplement

	if spec.fieldCropyQuery == nil then
		self:createFieldCropsQuery()
	end

	return spec.fieldCropyQuery, spec.fieldCropyQueryValid
end

function AIImplement:updateFieldCropsQuery()
	if self.spec_aiImplement.fieldCropyQuery ~= nil then
		self:createFieldCropsQuery()
	end
end

function AIImplement:createFieldCropsQuery()
	local mission = g_currentMission
	local groundTypeMapId, groundTypeFirstChannel, groundTypeNumChannels = mission.fieldGroundSystem:getDensityMapData(FieldDensityMap.GROUND_TYPE)

	if groundTypeMapId ~= nil then
		local spec = self.spec_aiImplement
		spec.fieldCropyQueryValid = false
		local query = FieldCropsQuery.new(groundTypeMapId)
		local fruitRequirements = self:getAIFruitRequirements()

		for i = 1, #fruitRequirements do
			local fruitRequirement = fruitRequirements[i]

			if fruitRequirement.customMapId == nil and fruitRequirement.fruitType ~= FruitType.UNKNOWN then
				local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitRequirement.fruitType)

				query:addRequiredCropType(desc.terrainDataPlaneId, fruitRequirement.minGrowthState, fruitRequirement.maxGrowthState, desc.startStateChannel, desc.numStateChannels, groundTypeFirstChannel, groundTypeNumChannels)
			elseif fruitRequirement.customMapId ~= nil then
				query:addRequiredCropType(fruitRequirement.customMapId, fruitRequirement.minGrowthState, fruitRequirement.maxGrowthState, fruitRequirement.customMapStartChannel, fruitRequirement.customMapNumChannels, groundTypeFirstChannel, groundTypeNumChannels)
			end

			spec.fieldCropyQueryValid = true
		end

		local fruitProhibitions = self:getAIFruitProhibitions()

		for i = 1, #fruitProhibitions do
			local fruitProhibition = fruitProhibitions[i]

			if fruitProhibition.customMapId == nil and fruitProhibition.fruitType ~= FruitType.UNKNOWN then
				local desc = g_fruitTypeManager:getFruitTypeByIndex(fruitProhibition.fruitType)

				query:addProhibitedCropType(desc.terrainDataPlaneId, fruitProhibition.minGrowthState, fruitProhibition.maxGrowthState, desc.startStateChannel, desc.numStateChannels, groundTypeFirstChannel, groundTypeNumChannels)
			elseif fruitProhibition.customMapId ~= nil then
				query:addProhibitedCropType(fruitProhibition.customMapId, fruitProhibition.minGrowthState, fruitProhibition.maxGrowthState, fruitProhibition.customMapStartChannel, fruitProhibition.customMapNumChannels, groundTypeFirstChannel, groundTypeNumChannels)
			end

			spec.fieldCropyQueryValid = true
		end

		local terrainDetailRequiredValueRanges = self:getAITerrainDetailRequiredRange()

		for i = 1, #terrainDetailRequiredValueRanges do
			local valueRange = terrainDetailRequiredValueRanges[i]

			query:addRequiredGroundValue(valueRange[1], valueRange[2], valueRange[3], valueRange[4])

			spec.fieldCropyQueryValid = true
		end

		local terrainDetailProhibitValueRanges = self:getAITerrainDetailProhibitedRange()

		for i = 1, #terrainDetailProhibitValueRanges do
			local valueRange = terrainDetailProhibitValueRanges[i]

			query:addProhibitedGroundValue(valueRange[1], valueRange[2], valueRange[3], valueRange[4])

			spec.fieldCropyQueryValid = true
		end

		spec.fieldCropyQuery = query
	end
end

function AIImplement:getIsAIImplementInLine()
	return self.spec_aiImplement.isLineStarted
end

function AIImplement:aiImplementStartLine()
	self.spec_aiImplement.isLineStarted = true

	SpecializationUtil.raiseEvent(self, "onAIImplementStartLine")

	local actionController = self.rootVehicle.actionController

	if actionController ~= nil then
		self.rootVehicle.actionController:onAIEvent(self, "onAIImplementStartLine")
	end
end

function AIImplement:aiImplementEndLine()
	self.spec_aiImplement.isLineStarted = false

	SpecializationUtil.raiseEvent(self, "onAIImplementEndLine")

	local actionController = self.rootVehicle.actionController

	if actionController ~= nil then
		self.rootVehicle.actionController:onAIEvent(self, "onAIImplementEndLine")
	end
end
