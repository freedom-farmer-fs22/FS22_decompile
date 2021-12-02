EnvironmentAreaSystem = {
	WATER_THRESHOLD = 0.4
}
local EnvironmentAreaSystem_mt = Class(EnvironmentAreaSystem)

function EnvironmentAreaSystem.getName(index)
	for name, id in pairs(EnvironmentAreaSystem) do
		if index == id then
			return name
		end
	end

	return ""
end

function EnvironmentAreaSystem.new(mission, customMt)
	local self = setmetatable({}, customMt or EnvironmentAreaSystem_mt)
	self.mission = mission
	self.referenceNode = getCamera(0)
	self.currentAreaType = AreaType.OPEN_FIELD
	self.waterYRequests = {}
	self.raycastsXZMaxDistance = 30
	self.raycastsYMaxDistance = 30
	self.raycastsXZ = {
		{
			dir = {
				MathUtil.vector3Normalize(0, 0, 1)
			}
		},
		{
			dir = {
				MathUtil.vector3Normalize(1, 0, 0)
			}
		},
		{
			dir = {
				MathUtil.vector3Normalize(0, 0, -1)
			}
		},
		{
			dir = {
				MathUtil.vector3Normalize(-1, 0, 0)
			}
		},
		{
			dir = {
				MathUtil.vector3Normalize(1, 0, 1)
			}
		},
		{
			dir = {
				MathUtil.vector3Normalize(1, 0, -1)
			}
		},
		{
			dir = {
				MathUtil.vector3Normalize(-1, 0, -1)
			}
		},
		{
			dir = {
				MathUtil.vector3Normalize(-1, 0, 1)
			}
		}
	}
	self.raycastsY = {
		{
			isTopRaycast = true,
			dir = {
				MathUtil.vector3Normalize(0, 1, 0)
			}
		},
		{
			isTopRaycast = false,
			dir = {
				MathUtil.vector3Normalize(0, 1.5, 1)
			}
		},
		{
			isTopRaycast = false,
			dir = {
				MathUtil.vector3Normalize(1, 1.5, 0)
			}
		},
		{
			isTopRaycast = false,
			dir = {
				MathUtil.vector3Normalize(0, 1.5, -1)
			}
		},
		{
			isTopRaycast = false,
			dir = {
				MathUtil.vector3Normalize(-1, 1.5, 0)
			}
		},
		{
			isTopRaycast = true,
			dir = {
				MathUtil.vector3Normalize(0, 1, 0)
			}
		},
		{
			isTopRaycast = false,
			dir = {
				MathUtil.vector3Normalize(1, 1.5, 1)
			}
		},
		{
			isTopRaycast = false,
			dir = {
				MathUtil.vector3Normalize(1, 1.5, -1)
			}
		},
		{
			isTopRaycast = false,
			dir = {
				MathUtil.vector3Normalize(-1, 1.5, -1)
			}
		},
		{
			isTopRaycast = false,
			dir = {
				MathUtil.vector3Normalize(-1, 1.5, 1)
			}
		}
	}
	self.isDebugViewActive = false
	self.areaTypeWeights = {}

	for _, areaTypeIndex in pairs(AreaType.getAll()) do
		self.areaTypeWeights[areaTypeIndex] = 0
	end

	self.areaTypeWeights[AreaType.OPEN_FIELD] = 1
	self.lastPosition = {
		z = 0,
		x = 0,
		y = 0
	}
	self.tileSize = 4
	self.dataGrid = DynamicDataGrid.new(60, self.tileSize)
	self.treeCheckRadius = 15
	self.maxNumForestThreshold = 10
	self.minNumForestThreshold = 3
	self.minTopCollisionDistanceThreshold = 10
	self.maxTopCollisionDistanceThreshold = 20
	self.minWallCollisionDistanceThreshold = 5
	self.maxWallCollisionDistanceThreshold = 15
	self.raycastCollisionMask = CollisionFlag.STATIC_OBJECT
	local ambientSoundSystem = mission.ambientSoundSystem
	self.setIsInForest = ambientSoundSystem:registerModifier("inForest", nil)
	self.setIsNearWater = ambientSoundSystem:registerModifier("nearWater", nil)

	addConsoleCommand("gsEnvironmentAreaSystemToggleDebugView", "Toggles the environment checker debug view", "consoleCommandToggleDebugView", self)

	return self
end

function EnvironmentAreaSystem:delete()
	self.mission:removeDrawable(self)
	removeConsoleCommand("gsEnvironmentAreaSystemToggleDebugView")

	self.mission = nil
end

function EnvironmentAreaSystem:getAreaWeights()
	return self.areaTypeWeights
end

function EnvironmentAreaSystem:update(dt)
	local numCallbacks = #self.waterYRequests

	for i = 1, numCallbacks do
		local asyncData = table.remove(self.waterYRequests, 1)
		local y, _ = nil

		if g_currentMission ~= nil and g_currentMission.environment.water ~= nil then
			_, y, _ = getWorldTranslation(g_currentMission.environment.water)
		end

		asyncData.asyncCallbackFunc(asyncData.asyncCallbackTarget, y, asyncData.asyncCallbackArgs)
	end

	if self.currentCell ~= nil then
		self:updateCellType(self.currentCell)
		self:updateWeights()
	end

	self.setIsNearWater(self.areaTypeWeights[AreaType.WATER] > 0.1)
	self.setIsInForest(self.areaTypeWeights[AreaType.FOREST] > 0.25)

	local x, y, z = getWorldTranslation(self.referenceNode)

	self.dataGrid:setWorldPosition(x, z)

	local cell, wx, wz = self.dataGrid:getCellData(0, 0)
	self.currentCell = cell

	if cell.raycastIndexXZ == nil then
		self:setupCell(cell)
	else
		cell.raycastIndexXZ = cell.raycastIndexXZ + 2
	end

	if cell.raycastIndexXZ >= #self.raycastsXZ then
		cell.raycastIndexXZ = 0
	end

	local raycastXZ1 = self.raycastsXZ[cell.raycastIndexXZ + 1]

	raycastClosest(x, y, z, raycastXZ1.dir[1], raycastXZ1.dir[2], raycastXZ1.dir[3], "raycastXZCallback1", self.raycastsXZMaxDistance, self, self.raycastCollisionMask, false, true)

	local raycastXZ2 = self.raycastsXZ[cell.raycastIndexXZ + 2]

	raycastClosest(x, y, z, raycastXZ2.dir[1], raycastXZ2.dir[2], raycastXZ2.dir[3], "raycastXZCallback2", self.raycastsXZMaxDistance, self, self.raycastCollisionMask, false, true)

	if not cell.hasTopHit then
		raycastClosest(x, y, z, 0, 1, 0, "raycastYCallback", self.raycastsYMaxDistance, self, self.raycastCollisionMask, false, true)
	end

	if cell.treeCount == nil then
		cell.treeCount = 0

		overlapSphere(wx, y, wz, self.treeCheckRadius, "forestCheckCallback", self, CollisionFlag.TREE, false, true, false, true)
	end

	self:getWaterYAtWorldPositionAsync(x, y, z, EnvironmentAreaSystem.onCellWaterCallback, self, {
		x,
		z
	})

	self.lastPosition.x = x
	self.lastPosition.y = y
	self.lastPosition.z = z
end

function EnvironmentAreaSystem:setupCell(cell)
	cell.isValid = true
	cell.raycastIndexXZ = 0
	cell.hitDataXZ = {}
	cell.areaTypeWeights = {}
	cell.treeCount = nil

	for k, _ in pairs(self.areaTypeWeights) do
		cell.areaTypeWeights[k] = 0
	end
end

function EnvironmentAreaSystem:updateWeights()
	local sum = 0

	for k, _ in pairs(self.areaTypeWeights) do
		self.areaTypeWeights[k] = 0
	end

	local currentCell, _, _ = self.dataGrid:getCellData(0, 0)

	for i = 1, 3 do
		for j = 1, 3 do
			local cell, wx, wz = self.dataGrid:getCellData(i - 2, j - 2)
			local weights = cell.areaTypeWeights

			if weights == nil then
				weights = currentCell.areaTypeWeights
			end

			local distance = MathUtil.vector2Length(wx - self.lastPosition.x, wz - self.lastPosition.z)
			local weightFactor = MathUtil.clamp(1 - distance / self.tileSize, 0, 1)

			for areaTypeIndex, weight in pairs(weights) do
				local appliedWeight = weight * weightFactor
				self.areaTypeWeights[areaTypeIndex] = self.areaTypeWeights[areaTypeIndex] + appliedWeight
				sum = sum + appliedWeight
			end
		end
	end

	if sum > 0 then
		for typeIndex, weight in pairs(self.areaTypeWeights) do
			self.areaTypeWeights[typeIndex] = weight / sum
		end
	else
		self.areaTypeWeights[AreaType.OPEN_FIELD] = 1
	end
end

function EnvironmentAreaSystem:updateCellType(cell)
	local sum = 0

	for k, _ in pairs(cell.areaTypeWeights) do
		cell.areaTypeWeights[k] = 0
	end

	if self.maxNumForestThreshold < cell.treeCount then
		cell.areaTypeWeights[AreaType.FOREST] = 1

		return
	end

	if cell.hasTopHit then
		cell.areaTypeWeights[AreaType.HALL] = 1

		return
	end

	if cell.isNearWater then
		cell.areaTypeWeights[AreaType.WATER] = EnvironmentAreaSystem.WATER_THRESHOLD
	end

	if self.minNumForestThreshold < cell.treeCount then
		local forestWeight = MathUtil.inverseLerp(self.minNumForestThreshold, self.maxNumForestThreshold, cell.treeCount)
		cell.areaTypeWeights[AreaType.FOREST] = forestWeight
		sum = sum + forestWeight
	end

	local nearestWallDistance = math.huge

	for _, data in pairs(cell.hitDataXZ) do
		nearestWallDistance = math.min(nearestWallDistance, data.distance)
	end

	if nearestWallDistance < self.maxWallCollisionDistanceThreshold then
		local wallWeight = 1 - MathUtil.inverseLerp(self.minWallCollisionDistanceThreshold, self.maxWallCollisionDistanceThreshold, nearestWallDistance)
		cell.areaTypeWeights[AreaType.CITY] = wallWeight
		sum = sum + wallWeight
	end

	if sum > 0 then
		if sum > 1 then
			for k, weight in pairs(cell.areaTypeWeights) do
				if k ~= AreaType.OPEN_FIELD then
					cell.areaTypeWeights[k] = weight / sum
				end
			end
		else
			cell.areaTypeWeights[AreaType.OPEN_FIELD] = 1 - sum
		end
	else
		cell.areaTypeWeights[AreaType.OPEN_FIELD] = 1
	end
end

function EnvironmentAreaSystem:raycastXZCallback1(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	self:handleRaycast(1, hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
end

function EnvironmentAreaSystem:raycastXZCallback2(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	self:handleRaycast(2, hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
end

function EnvironmentAreaSystem:handleRaycast(indexOffset, hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	local cell = self.currentCell
	local raycastIndexXZ = cell.raycastIndexXZ + indexOffset

	if hitObjectId ~= 0 and (cell.hitDataXZ[raycastIndexXZ] == nil or distance < cell.hitDataXZ[raycastIndexXZ].distance) then
		cell.hitDataXZ[raycastIndexXZ] = {
			name = getName(hitObjectId),
			x = x,
			y = y,
			z = z,
			distance = distance
		}
	end
end

function EnvironmentAreaSystem:raycastYCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	local cell = self.currentCell

	if hitObjectId ~= 0 then
		cell.hasTopHit = true
	end
end

function EnvironmentAreaSystem:setReferenceNode(node)
	self.referenceNode = node
end

function EnvironmentAreaSystem:forestCheckCallback(transformId)
	if transformId ~= 0 and getHasClassId(transformId, ClassIds.SHAPE) and getSplitType(transformId) ~= 0 and not getIsSplitShapeSplit(transformId) then
		self.currentCell.treeCount = self.currentCell.treeCount + 1
	end

	return true
end

function EnvironmentAreaSystem:onCellWaterCallback(waterY, args)
	local cell = self.currentCell
	cell.isNearWater = false

	if waterY ~= nil and g_currentMission ~= nil then
		local x = args[1]
		local z = args[2]
		local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

		if waterY > y - 0.25 then
			cell.isNearWater = true
		end
	end
end

function EnvironmentAreaSystem:draw()
	self.dataGrid:drawDebug(function (cell)
		local alpha = 0.1

		if not cell.isValid then
			return 1, 0, 0, alpha
		end

		return 0, 1, 0, alpha
	end, function (cell, cx, cz)
		local text = nil

		if cell.treeCount ~= nil then
			text = string.format("%s\nTrees: %d", text or "", cell.treeCount)
		end

		if cell.areaTypeWeights ~= nil then
			for k, weight in pairs(cell.areaTypeWeights) do
				text = string.format("%s\n[%s] %.3f", text or "", AreaType.getName(k), weight)
			end
		end

		if text ~= nil then
			local cy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, cx, 0, cz) + 0.1

			DebugUtil.drawDebugGizmoAtWorldPos(cx, cy, cz, 0, 0, 1, 0, 1, 0, text, false, {
				1,
				1,
				1
			})
		end

		if cell == self.currentCell and cell.hitDataXZ ~= nil then
			for k, data in pairs(cell.hitDataXZ) do
				DebugUtil.drawDebugGizmoAtWorldPos(data.x, data.y, data.z, 0, 0, 1, 0, 1, 0, string.format("Raycast-XZ %d\n%.3f", k, data.distance), false)
			end
		end
	end)
	setTextColor(1, 1, 1, 1)

	local posY = 0.6
	local textSize = 0.014

	for areaTypeIndex, weight in ipairs(self.areaTypeWeights) do
		local typeName = AreaType.getName(areaTypeIndex)

		setTextAlignment(RenderText.ALIGN_RIGHT)
		renderText(0.3, posY, textSize, typeName .. ": ")
		setTextAlignment(RenderText.ALIGN_LEFT)
		renderText(0.3, posY, textSize, string.format("%.3f", weight))

		posY = posY - 0.015
	end
end

function EnvironmentAreaSystem:getWaterYAtWorldPosition(x, y, z)
	y = y or 100
	self.waterY = nil

	raycastClosest(x, y + 100, z, 0, -1, 0, "onWaterRaycastCallback", 200, self, CollisionFlag.WATER, false, false)

	return self.waterY
end

function EnvironmentAreaSystem:onWaterRaycastCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if hitObjectId ~= 0 then
		self.waterY = y
	end
end

function EnvironmentAreaSystem:getWaterYAtWorldPositionAsync(x, y, z, asyncCallbackFunc, asyncCallbackTarget, asyncCallbackArgs)
	table.insert(self.waterYRequests, {
		asyncCallbackFunc = asyncCallbackFunc,
		asyncCallbackTarget = asyncCallbackTarget,
		asyncCallbackArgs = asyncCallbackArgs
	})
end

function EnvironmentAreaSystem:consoleCommandToggleDebugView()
	self.isDebugViewActive = not self.isDebugViewActive

	if self.isDebugViewActive then
		self.mission:addDrawable(self)
	else
		self.mission:removeDrawable(self)
	end
end
