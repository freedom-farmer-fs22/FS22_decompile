DataGrid = {}
local DataGrid_mt = Class(DataGrid)

function DataGrid.new(numRows, numColumns, customMt)
	local self = {}

	setmetatable(self, customMt or DataGrid_mt)

	self.grid = {}
	self.numRows = numRows
	self.numColumns = numColumns

	for _ = 1, numRows do
		table.insert(self.grid, {})
	end

	return self
end

function DataGrid:delete()
	self.grid = nil
end

function DataGrid:getValue(rowIndex, colIndex)
	if rowIndex < 1 or self.numRows < rowIndex then
		Logging.error("rowIndex out of bounds!")
		printCallstack()

		return nil
	end

	if colIndex < 1 or self.numColumns < colIndex then
		Logging.error("colIndex out of bounds!")
		printCallstack()

		return nil
	end

	return self.grid[rowIndex][colIndex]
end

function DataGrid:setValue(rowIndex, colIndex, value)
	if rowIndex < 1 or self.numRows < rowIndex then
		Logging.error("rowIndex out of bounds!")
		printCallstack()

		return false
	end

	if colIndex < 1 or self.numColumns < colIndex then
		Logging.error("colIndex out of bounds!")
		printCallstack()

		return false
	end

	self.grid[rowIndex][colIndex] = value

	return true
end
