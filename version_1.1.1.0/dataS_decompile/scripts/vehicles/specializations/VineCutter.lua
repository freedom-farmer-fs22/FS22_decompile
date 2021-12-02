VineCutter = {
	initSpecialization = function ()
		local schema = Vehicle.xmlSchema

		schema:setXMLSpecializationType("VineCutter")
		schema:register(XMLValueType.STRING, "vehicle.vineCutter#fruitType", "Fruit type")
		schema:setXMLSpecializationType()
	end,
	prerequisitesPresent = function (specializations)
		return SpecializationUtil.hasSpecialization(VineDetector, specializations)
	end
}

function VineCutter.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "getCombine", VineCutter.getCombine)
	SpecializationUtil.registerFunction(vehicleType, "harvestCallback", VineCutter.harvestCallback)
end

function VineCutter.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "doCheckSpeedLimit", VineCutter.doCheckSpeedLimit)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getCanStartVineDetection", VineCutter.getCanStartVineDetection)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "getIsValidVinePlaceable", VineCutter.getIsValidVinePlaceable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "handleVinePlaceable", VineCutter.handleVinePlaceable)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "clearCurrentVinePlaceable", VineCutter.clearCurrentVinePlaceable)
end

function VineCutter.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", VineCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", VineCutter)
	SpecializationUtil.registerEventListener(vehicleType, "onTurnedOff", VineCutter)
end

function VineCutter:onLoad(savegame)
	local spec = self.spec_vineCutter
	local fruitTypeName = self.xmlFile:getValue("vehicle.vineCutter#fruitType")
	local fruitType = g_fruitTypeManager:getFruitTypeByName(fruitTypeName)

	if fruitType ~= nil then
		spec.inputFruitTypeIndex = fruitType.index
	else
		spec.inputFruitTypeIndex = FruitType.GRAPE
	end

	spec.outputFillTypeIndex = g_fruitTypeManager:getFillTypeIndexByFruitTypeIndex(spec.inputFruitTypeIndex)
end

function VineCutter:onPostLoad(savegame)
	if self.addCutterToCombine ~= nil then
		self:addCutterToCombine(self)
	end
end

function VineCutter:onTurnedOff()
	self:cancelVineDetection()

	local spec = self.spec_vineCutter

	if spec.lastHarvestingPlaceable ~= nil and spec.lastHarvestingNode ~= nil then
		spec.lastHarvestingPlaceable:setShakingFactor(spec.lastHarvestingNode, 0, 0, 0, 0)
	end
end

function VineCutter:getCanStartVineDetection(superFunc)
	if not superFunc(self) then
		return false
	end

	local isTurnedOn = self:getIsTurnedOn()

	if not isTurnedOn then
		return false
	end

	if self.movingDirection < 0 then
		return false
	end

	return true
end

function VineCutter:getIsValidVinePlaceable(superFunc, placeable)
	if not superFunc(self, placeable) then
		return false
	end

	local spec = self.spec_vineCutter

	if placeable:getVineFruitType() ~= spec.inputFruitTypeIndex then
		return false
	end

	return true
end

function VineCutter:handleVinePlaceable(superFunc, node, placeable, x, y, z, distance)
	if not superFunc(self, node, placeable, x, y, z, distance) then
		return false
	end

	local combineVehicle, alternativeCombine, requiredFillType = self:getCombine()

	if combineVehicle == nil and requiredFillType ~= nil then
		combineVehicle = alternativeCombine
	end

	if combineVehicle == nil then
		return false
	end

	if placeable ~= nil then
		local spec = self.spec_vineCutter
		local startPosX, startPosY, startPosZ = self:getFirstVineHitPosition()
		local currentPosX, currentPosY, currentPosZ = self:getCurrentVineHitPosition()
		spec.currentCombineVehicle = combineVehicle

		placeable:harvestVine(node, startPosX, startPosY, startPosZ, currentPosX, currentPosY, currentPosZ, self.harvestCallback, self)
		placeable:setShakingFactor(node, currentPosX, currentPosY, currentPosZ, 1)

		if spec.lastHarvestingNode ~= nil and spec.lastHarvestingNode ~= node then
			spec.lastHarvestingPlaceable:setShakingFactor(spec.lastHarvestingNode, currentPosX, currentPosY, currentPosZ, 0)
		end

		spec.lastHarvestingNode = node
		spec.lastHarvestingPlaceable = placeable

		return true
	end

	return false
end

function VineCutter:clearCurrentVinePlaceable(superFunc)
	superFunc(self)

	local spec = self.spec_vineCutter

	if spec.lastHarvestingPlaceable ~= nil and spec.lastHarvestingNode ~= nil then
		spec.lastHarvestingPlaceable:setShakingFactor(spec.lastHarvestingNode, 0, 0, 0, 0)
	end

	spec.lastHarvestingPlaceable = nil
	spec.lastHarvestingNode = nil
end

function VineCutter:harvestCallback(placeable, area, totalArea, weedFactor, sprayFactor, plowFactor)
	local spec = self.spec_vineCutter
	local limeFactor = 1
	local stubbleTillageFactor = 1
	local rollerFactor = 1
	local beeYieldBonusPerc = 0
	local multiplier = g_currentMission:getHarvestScaleMultiplier(spec.inputFruitTypeIndex, sprayFactor, plowFactor, limeFactor, weedFactor, stubbleTillageFactor, rollerFactor, beeYieldBonusPerc)
	local realArea = area * multiplier
	local farmId = placeable:getOwnerFarmId()

	spec.currentCombineVehicle:addCutterArea(area, realArea, spec.inputFruitTypeIndex, spec.outputFillTypeIndex, 0, nil, farmId, 1)

	local ha = MathUtil.areaToHa(area, g_currentMission:getFruitPixelsToSqm())
	local stats = g_currentMission:farmStats(farmId)

	stats:updateStats("threshedHectares", ha)
	stats:updateStats("workedHectares", ha)
end

function VineCutter:doCheckSpeedLimit(superFunc)
	return superFunc(self) or self:getIsTurnedOn()
end

function VineCutter:getCombine()
	local spec = self.spec_vineCutter

	if self.verifyCombine ~= nil then
		return self:verifyCombine(spec.inputFruitTypeIndex, spec.outputFillTypeIndex)
	elseif self.getAttacherVehicle ~= nil then
		local attacherVehicle = self:getAttacherVehicle()

		if attacherVehicle ~= nil and attacherVehicle.verifyCombine ~= nil then
			return attacherVehicle:verifyCombine(spec.inputFruitTypeIndex, spec.outputFillTypeIndex)
		end
	end

	return nil
end

function VineCutter.getDefaultSpeedLimit()
	return 5
end
