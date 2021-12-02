Landscaping = {}
local Landscaping_mt = Class(Landscaping)
Landscaping.BRUSH_SHAPE_NUM_SEND_BITS = 2
Landscaping.OPERATION_NUM_SEND_BITS = 3
Landscaping.BRUSH_SHAPE = {
	SQUARE = 1,
	CIRCLE = 2
}
Landscaping.OPERATION = {
	RAISE = 1,
	LOWER = 2,
	FLATTEN = 4,
	FOLIAGE = 6,
	SMOOTH = 3,
	SLOPE = 7,
	PAINT = 5
}
Landscaping.OPERATION_HEIGHT_CHANGE_FACTOR_MAP = {
	[Landscaping.OPERATION.RAISE] = 1,
	[Landscaping.OPERATION.LOWER] = -1,
	[Landscaping.OPERATION.SMOOTH] = 0,
	[Landscaping.OPERATION.FLATTEN] = 0,
	[Landscaping.OPERATION.PAINT] = 0,
	[Landscaping.OPERATION.FOLIAGE] = 0,
	[Landscaping.OPERATION.SLOPE] = 1
}
Landscaping.TERRAIN_UNIT = 2
Landscaping.SCULPT_BASE_COST_PER_M3 = 10
Landscaping.PAINT_BASE_COST_PER_M2 = 1
Landscaping.FOLIAGE_BASE_COST_PER_M2 = 0.2

local function NO_CALLBACK()
end

local SQRT_2_DIV_FACTOR = 1 / math.sqrt(2)

function Landscaping.new(terrainDeformationQueue, farmlandManager, terrainRootNode, placementCollisionMap, playerFarm, userId, isMasterUser, validateOnly, callbackFunction, callbackFunctionTarget)
	local self = setmetatable({}, Landscaping_mt)
	self.terrainDeformationQueue = terrainDeformationQueue
	self.farmlandManager = farmlandManager
	self.terrainRootNode = terrainRootNode
	self.placementCollisionMap = placementCollisionMap
	self.playerFarm = playerFarm
	self.currentUserId = userId
	self.isMasterUser = isMasterUser
	self.validateOnly = validateOnly
	self.callbackFunction = callbackFunction or NO_CALLBACK
	self.callbackFunctionTarget = callbackFunctionTarget
	self.terrainUnit = Landscaping.TERRAIN_UNIT
	self.halfTerrainUnit = Landscaping.TERRAIN_UNIT / 2
	self.targetPosition = nil
	self.radius = 0
	self.brushShape = Landscaping.BRUSH_SHAPE.SQUARE
	self.smoothingDistance = 0
	self.sculptingOperation = Landscaping.OPERATION.RAISE
	self.modifiedAreas = {}

	return self
end

function Landscaping:delete()
end

function Landscaping:hasObjectOverlapInModificationArea(x, y, z)
	local range = self.radius + self.terrainUnit * 2

	for _, player in pairs(g_currentMission.players) do
		if player.isControlled then
			local pX, _, pZ = getWorldTranslation(player.rootNode)
			local dX = pX - x
			local dZ = pZ - z

			if self.brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
				local sqrRange = range * range
				local sqrDistance = dX * dX + dZ * dZ

				if sqrRange >= sqrDistance then
					return true
				end
			elseif math.abs(dX) <= range and math.abs(dZ) <= range then
				return true
			end
		end
	end

	return false
end

function Landscaping:addModifiedCircleArea(x, z, radius)
	if radius < self.terrainUnit + self.halfTerrainUnit then
		local size = radius * 2 * SQRT_2_DIV_FACTOR

		self:addModifiedSquareArea(x, z, size)
	else
		for ox = -radius / self.terrainUnit, radius / self.terrainUnit - 1 do
			local xStart = ox * self.terrainUnit
			local xEnd = ox * self.terrainUnit + self.terrainUnit
			local zOffset1 = math.sin(math.acos(math.abs(xStart) / radius)) * radius
			local zOffset2 = math.sin(math.acos(math.abs(xEnd) / radius)) * radius
			local zOffset = math.min(zOffset1, zOffset2) - 0.02

			table.insert(self.modifiedAreas, {
				x + xStart,
				z - zOffset,
				x + xEnd,
				z - zOffset,
				x + xStart,
				z + zOffset
			})
		end
	end
end

function Landscaping:addModifiedSquareArea(x, z, side)
	local halfSide = side * 0.5

	table.insert(self.modifiedAreas, {
		x - halfSide,
		z - halfSide,
		x + halfSide,
		z - halfSide,
		x - halfSide,
		z + halfSide
	})
end

function Landscaping:assignSmoothingParameters(deform, x, z, radius, strength, brushShape)
	local hardness = 0.2

	deform:setAdditiveHeightChangeAmount(0.05)

	if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		deform:addSoftCircleBrush(x, z, radius, hardness, strength)
		self:addModifiedCircleArea(x, z, radius)
	else
		deform:addSoftSquareBrush(x, z, radius * 2, hardness, strength)
		self:addModifiedSquareArea(x, z, radius * 2)
	end

	deform:enableSmoothingMode()
end

function Landscaping:assignPaintingParameters(deform, x, z, radius, brushShape, layerIndex)
	if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
		deform:addSoftCircleBrush(x, z, radius, 1, 1, layerIndex)
		self:addModifiedCircleArea(x, z, radius)
	else
		deform:addSoftSquareBrush(x, z, radius * 2, 1, 1, layerIndex)
		self:addModifiedSquareArea(x, z, radius * 2)
	end

	deform:enablePaintingMode()
end

function Landscaping:assignSculptingParameters(deform, x, y, z, nx, ny, nz, d, minY, maxY, radius, strength, brushShape, operation, smoothingDistance)
	local hardness = 0.2

	if operation == Landscaping.OPERATION.FLATTEN then
		deform:setAdditiveHeightChangeAmount(0.75)
		deform:setHeightTarget(y, y, 0, 1, 0, -y)
		deform:enableSetDeformationMode()
	elseif operation == Landscaping.OPERATION.LOWER then
		deform:enableAdditiveDeformationMode()
		deform:setAdditiveHeightChangeAmount(-0.005)
	elseif operation == Landscaping.OPERATION.RAISE then
		deform:enableAdditiveDeformationMode()
		deform:setAdditiveHeightChangeAmount(0.005)
	elseif operation == Landscaping.OPERATION.SLOPE then
		deform:setAdditiveHeightChangeAmount(0.75)
		deform:setHeightTarget(minY, maxY, nx, ny, nz, d)
		deform:enableSetDeformationMode()
	end

	if brushShape == Landscaping.BRUSH_SHAPE.SQUARE then
		deform:addSoftSquareBrush(x, z, radius * 2, hardness, strength)
		self:addModifiedSquareArea(x, z, radius * 2)
	else
		deform:addSoftCircleBrush(x, z, radius, hardness, strength)
		self:addModifiedCircleArea(x, z, radius)
	end

	deform:setOutsideAreaConstraints(0, math.pi * 2, math.pi * 2)
end

function Landscaping:validateWaterLevel(positionY, strength, operation)
	if g_currentMission ~= nil and g_currentMission.environment ~= nil and g_currentMission.environment.water ~= nil then
		local heightChangeFactor = Landscaping.OPERATION_HEIGHT_CHANGE_FACTOR_MAP[operation]
		local heightChange = strength * heightChangeFactor
		local _, waterLevel, _ = getWorldTranslation(g_currentMission.environment.water)

		return positionY > waterLevel and waterLevel < positionY + heightChange
	else
		return true
	end
end

function Landscaping:sculpt(x, y, z, nx, ny, nz, d, minY, maxY, radius, strength, brushShape, operation, smoothingDistance, terrainPaintingLayer, terrainFoliageLayer, terrainFoliageValue)
	if not self:validateWaterLevel(y, strength, operation) then
		self:onSculptingApplied(TerrainDeformation.STATE_FAILED_BLOCKED, 0)

		return
	end

	self.isTerrainDeformationPending = true
	local deform = TerrainDeformation.new(self.terrainRootNode)
	self.currentTerrainDeformation = deform
	self.targetPosition = {
		x,
		y,
		z
	}
	self.radius = radius
	self.brushShape = brushShape
	self.smoothingDistance = math.max(smoothingDistance, self.terrainUnit)
	self.sculptingOperation = operation
	local displacedFoliageArea = 0

	if operation == Landscaping.OPERATION.SMOOTH then
		self:assignSmoothingParameters(deform, x, z, radius, strength, brushShape)
	elseif operation == Landscaping.OPERATION.PAINT then
		self:assignPaintingParameters(deform, x, z, radius, brushShape, terrainPaintingLayer)
	elseif operation == Landscaping.OPERATION.FOLIAGE then
		local foliageSystem = g_currentMission.foliageSystem

		if brushShape == Landscaping.BRUSH_SHAPE.CIRCLE then
			for ox = -radius / self.terrainUnit, radius / self.terrainUnit - 1 do
				local xStart = ox * self.terrainUnit
				local xEnd = ox * self.terrainUnit + self.terrainUnit
				local zOffset1 = math.sin(math.acos(math.abs(xStart) / radius)) * radius
				local zOffset2 = math.sin(math.acos(math.abs(xEnd) / radius)) * radius
				local zOffset = math.min(zOffset1, zOffset2) - 0.02
				displacedFoliageArea = displacedFoliageArea + foliageSystem:apply(foliageSystem:getFoliagePaint(terrainFoliageLayer), x + xStart, z - zOffset, x + xEnd, z - zOffset, x + xStart, z + zOffset, terrainFoliageValue)
			end
		else
			local x0 = x - radius
			local z0 = z - radius
			local x1 = x - radius
			local z1 = z + radius
			local x2 = x + radius
			local z2 = z - radius
			displacedFoliageArea = foliageSystem:apply(foliageSystem:getFoliagePaint(terrainFoliageLayer), x0, z0, x1, z1, x2, z2, terrainFoliageValue)
		end
	else
		self:assignSculptingParameters(deform, x, y, z, nx, ny, nz, d, minY, maxY, radius, strength, brushShape, operation, self.smoothingDistance)
	end

	if operation ~= Landscaping.OPERATION.PAINT and operation ~= Landscaping.OPERATION.FOLIAGE then
		deform:setBlockedAreaMaxDisplacement(0.01)
		deform:setDynamicObjectCollisionMask(CollisionMask.LANDSCAPING)
		deform:setDynamicObjectMaxDisplacement(0.03)

		if self.placementCollisionMap ~= nil then
			deform:setBlockedAreaMap(self.placementCollisionMap, 0)
		end
	end

	if operation == Landscaping.OPERATION.FOLIAGE then
		self:onSculptingValidated(TerrainDeformation.STATE_SUCCESS, displacedFoliageArea, false)
	elseif (operation == Landscaping.OPERATION.SMOOTH or operation == Landscaping.OPERATION.PAINT) and not self.validateOnly then
		deform:apply(true, "onSculptingValidated", self)
	else
		self.terrainDeformationQueue:queueJob(deform, true, "onSculptingValidated", self)
	end
end

function Landscaping:onSculptingValidated(errorCode, displacedVolumeOrArea, blocked)
	if errorCode == TerrainDeformation.STATE_SUCCESS then
		local additionalChecksPassed = true
		local updatedErrorCode = errorCode

		if self.playerFarm:getBalance() < self:getCost(displacedVolumeOrArea) then
			updatedErrorCode = TerrainDeformation.STATE_FAILED_NOT_ENOUGH_MONEY
			additionalChecksPassed = false
		end

		local ownsTargetLand = Landscaping.isModificationAreaOnOwnedLand(self.targetPosition[1], self.targetPosition[3], self.radius, self.smoothingDistance, self.farmlandManager, self.playerFarm.farmId)

		if not ownsTargetLand then
			updatedErrorCode = TerrainDeformation.STATE_FAILED_NOT_OWNED
			additionalChecksPassed = false
		end

		if self.sculptingOperation ~= Landscaping.OPERATION.PAINT and self.sculptingOperation ~= Landscaping.OPERATION.FOLIAGE then
			local dynamicObjectBlocking = self:hasObjectOverlapInModificationArea(unpack(self.targetPosition))

			if dynamicObjectBlocking then
				updatedErrorCode = TerrainDeformation.STATE_FAILED_COLLIDE_WITH_OBJECT
				additionalChecksPassed = false
			end
		end

		if self.sculptingOperation == Landscaping.OPERATION.FOLIAGE then
			self:onSculptingApplied(updatedErrorCode, displacedVolumeOrArea, nil)
		elseif additionalChecksPassed and not self.validateOnly then
			self.terrainDeformationQueue:queueJob(self.currentTerrainDeformation, false, "onSculptingApplied", self)
		else
			self:onSculptingApplied(updatedErrorCode, displacedVolumeOrArea, nil)
		end
	else
		self.currentTerrainDeformation:cancel()
		self:onSculptingApplied(errorCode, 0, nil)
	end
end

function Landscaping:onSculptingApplied(errorCode, displacedVolumeOrArea, _)
	if errorCode == TerrainDeformation.STATE_SUCCESS and not self.validateOnly then
		local cost = self:getCost(displacedVolumeOrArea)

		self.playerFarm:changeBalance(-cost, MoneyType.SHOP_PROPERTY_BUY)

		if self.sculptingOperation ~= Landscaping.OPERATION.FOLIAGE then
			for _, area in pairs(self.modifiedAreas) do
				local x, z, x1, z1, x2, z2 = unpack(area)

				if self.sculptingOperation ~= Landscaping.OPERATION.SMOOTH then
					FSDensityMapUtil.removeFieldArea(x, z, x1, z1, x2, z2, false)
					FSDensityMapUtil.removeWeedArea(x, z, x1, z1, x2, z2)
				end

				FSDensityMapUtil.eraseTireTrack(x, z, x1, z1, x2, z2)
				DensityMapHeightUtil.clearArea(x, z, x1, z1, x2, z2)

				if self.sculptingOperation == Landscaping.OPERATION.PAINT then
					FSDensityMapUtil.clearDecoArea(x, z, x1, z1, x2, z2)
				end

				local minX = math.min(x, x1, x2, x2 + x1 - x)
				local maxX = math.max(x, x1, x2, x2 + x1 - x)
				local minZ = math.min(z, z1, z2, z2 + z1 - z)
				local maxZ = math.max(z, z1, z2, z2 + z1 - z)

				g_currentMission.aiSystem:setAreaDirty(minX, maxX, minZ, maxZ)
			end
		end
	end

	if self.callbackFunctionTarget ~= nil then
		self.callbackFunction(self.callbackFunctionTarget, errorCode, displacedVolumeOrArea)
	else
		self.callbackFunction(errorCode, displacedVolumeOrArea)
	end

	if self.currentTerrainDeformation ~= nil then
		self.currentTerrainDeformation:delete()

		self.currentTerrainDeformation = nil
	end
end

function Landscaping:getCost(displacedVolumeOrArea)
	local cost = 0

	if self.sculptingOperation == Landscaping.OPERATION.PAINT then
		cost = displacedVolumeOrArea * Landscaping.PAINT_BASE_COST_PER_M2
	elseif self.sculptingOperation == Landscaping.OPERATION.PAINT then
		cost = displacedVolumeOrArea * Landscaping.FOLIAGE_BASE_COST_PER_M2
	else
		cost = displacedVolumeOrArea * Landscaping.SCULPT_BASE_COST_PER_M3
	end

	return cost
end

function Landscaping.isModificationAreaOnOwnedLand(x, z, radius, smoothingDistance, farmlandManager, farmId)
	local halfSize = radius + smoothingDistance

	return farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x - halfSize, z - halfSize) and farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x - halfSize, z + halfSize) and farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x + halfSize, z - halfSize) and farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, x + halfSize, z + halfSize)
end
