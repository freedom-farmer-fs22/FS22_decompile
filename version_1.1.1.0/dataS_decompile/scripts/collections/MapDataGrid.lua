MapDataGrid = {}
local MapDataGrid_mt = Class(MapDataGrid, DataGrid)

function MapDataGrid.new(mapSize, blocksPerRowColumn, customMt)
	local self = DataGrid.new(blocksPerRowColumn, blocksPerRowColumn, customMt or MapDataGrid_mt)
	self.blocksPerRowColumn = blocksPerRowColumn
	self.mapSize = mapSize
	self.blockSize = self.mapSize / self.blocksPerRowColumn

	return self
end

function MapDataGrid:getValueAtWorldPos(worldX, worldZ)
	local rowIndex, colIndex = self:getRowColumnFromWorldPos(worldX, worldZ)

	return self:getValue(rowIndex, colIndex), rowIndex, colIndex
end

function MapDataGrid:setValueAtWorldPos(worldX, worldZ, value)
	local rowIndex, colIndex = self:getRowColumnFromWorldPos(worldX, worldZ)

	self:setValue(rowIndex, colIndex, value)
end

function MapDataGrid:getRowColumnFromWorldPos(worldX, worldZ)
	local mapSize = self.mapSize
	local blocksPerRowColumn = self.blocksPerRowColumn
	local x = (worldX + mapSize * 0.5) / mapSize
	local z = (worldZ + mapSize * 0.5) / mapSize
	local row = MathUtil.clamp(math.ceil(blocksPerRowColumn * z), 1, blocksPerRowColumn)
	local column = MathUtil.clamp(math.ceil(blocksPerRowColumn * x), 1, blocksPerRowColumn)

	return row, column
end

function MapDataGrid:getBoundaries(row, column)
	local minX = (column - 1) * self.blockSize - self.mapSize * 0.5
	local maxX = column * self.blockSize - self.mapSize * 0.5
	local minZ = (row - 1) * self.blockSize - self.mapSize * 0.5
	local maxZ = row * self.blockSize - self.mapSize * 0.5

	return minX, maxX, minZ, maxZ
end
