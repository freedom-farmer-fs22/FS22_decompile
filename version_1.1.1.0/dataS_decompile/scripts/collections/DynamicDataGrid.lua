DynamicDataGrid = {}
local DynamicDataGrid_mt = Class(DynamicDataGrid)

function DynamicDataGrid.new(size, tileSize, customMt)
	local self = setmetatable({}, customMt or DynamicDataGrid_mt)
	self.tileSize = tileSize or 1
	self.size = size or 20
	self.numRows = math.floor(self.size / self.tileSize) + 1
	self.grid = {}

	for _ = 1, self.numRows do
		local row = {}

		for _ = 1, self.numRows do
			table.insert(row, {})
		end

		table.insert(self.grid, row)
	end

	self.lastPosition = {
		x = 0,
		z = 0
	}
	self.lastIndices = nil
	self.yOffset = 0.05

	return self
end

function DynamicDataGrid:delete()
	self.grid = nil
end

function DynamicDataGrid:drawDebug(areaColorFunction, cellFunction)
	if self.lastIndices ~= nil then
		local startX = self.lastIndices.x - math.floor(self.numRows * 0.5) * self.tileSize
		local startZ = self.lastIndices.z - math.floor(self.numRows * 0.5) * self.tileSize

		for xIndex, row in ipairs(self.grid) do
			local posZ = startZ

			for zIndex, cell in ipairs(row) do
				local x = startX
				local z = posZ

				if areaColorFunction ~= nil then
					local x1 = startX + self.tileSize
					local z1 = posZ
					local x2 = startX
					local z2 = posZ + self.tileSize
					local x3 = x1
					local z3 = z2
					local r, g, b, a = areaColorFunction(cell)
					local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z) + self.yOffset
					local y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1) + self.yOffset
					local y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2) + self.yOffset
					local y3 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x3, 0, z3) + self.yOffset

					drawDebugTriangle(x, y, z, x2, y2, z2, x1, y1, z1, r, g, b, a, false)
					drawDebugTriangle(x1, y1, z1, x2, y2, z2, x3, y3, z3, r, g, b, a, false)
				end

				if cellFunction ~= nil then
					local cx = x + self.tileSize * 0.5
					local cz = z + self.tileSize * 0.5

					cellFunction(cell, cx, cz)
				end

				posZ = posZ + self.tileSize
			end

			startX = startX + self.tileSize
		end
	end
end

function DynamicDataGrid:getCellData(offsetX, offsetZ)
	offsetX = offsetX or 0
	offsetZ = offsetZ or 0
	local center = math.floor(self.numRows * 0.5) + 1
	local cell = self.grid[center + offsetX][center + offsetZ]
	local wx = self.lastIndices.x + self.tileSize * 0.5 + self.tileSize * offsetX
	local wz = self.lastIndices.z + self.tileSize * 0.5 + self.tileSize * offsetZ

	return cell, wx, wz
end

function DynamicDataGrid:getCellAtWorldPosition(worldX, worldZ)
	local xIndex, zIndex = self:getIndicesByWorldPosition(worldX, worldZ)
	local offsetX = (xIndex - self.lastIndices.x) / self.tileSize
	local offsetZ = (zIndex - self.lastIndices.z) / self.tileSize
	local center = math.floor(self.numRows * 0.5) + 1
	local xColumns = self.grid[center + offsetX]

	if xColumns ~= nil then
		return xColumns[center + offsetZ]
	end

	return nil
end

function DynamicDataGrid:setWorldPosition(x, z)
	local xIndex, zIndex = self:getIndicesByWorldPosition(x, z)

	if self.lastIndices == nil then
		self.lastIndices = {
			x = xIndex,
			z = zIndex
		}
	end

	self.lastPosition.x = x
	self.lastPosition.z = z
	local xChange = (xIndex - self.lastIndices.x) / self.tileSize
	local zChange = (zIndex - self.lastIndices.z) / self.tileSize

	if xChange ~= 0 then
		local direction = MathUtil.sign(xChange)

		for i = 1, math.min(math.abs(xChange), self.numRows) do
			local insertIndex = nil
			local removeIndex = 1

			if direction < 0 then
				removeIndex = self.numRows
				insertIndex = 1
			end

			local row = table.remove(self.grid, removeIndex)

			for _, data in ipairs(row) do
				for k, _ in pairs(data) do
					data[k] = nil
				end
			end

			if insertIndex == nil then
				table.insert(self.grid, row)
			else
				table.insert(self.grid, insertIndex, row)
			end
		end

		self.lastIndices.x = xIndex
	end

	if zChange ~= 0 then
		local direction = MathUtil.sign(zChange)

		for i = 1, math.min(math.abs(zChange), self.numRows) do
			for j = 1, self.numRows do
				local insertIndex = nil
				local removeIndex = 1

				if direction < 0 then
					removeIndex = self.numRows
					insertIndex = 1
				end

				local row = self.grid[j]
				local data = table.remove(row, removeIndex)

				for k, _ in pairs(data) do
					data[k] = nil
				end

				if insertIndex == nil then
					table.insert(row, data)
				else
					table.insert(row, insertIndex, data)
				end
			end
		end

		self.lastIndices.z = zIndex
	end
end

function DynamicDataGrid:getIndicesByWorldPosition(x, z)
	local xIndex = math.floor(x / self.tileSize) * self.tileSize
	local zIndex = math.floor(z / self.tileSize) * self.tileSize

	return xIndex, zIndex
end
