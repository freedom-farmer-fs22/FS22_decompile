InGameMenuStatisticsFrame = {}
local InGameMenuStatisticsFrame_mt = Class(InGameMenuStatisticsFrame, TabbedMenuFrameElement)
InGameMenuStatisticsFrame.NUM_ROWS = 13
InGameMenuStatisticsFrame.STATISTICS_PER_BOX = GS_IS_MOBILE_VERSION and 6 or 19
InGameMenuStatisticsFrame.NUMBER_OF_BOXES = GS_IS_MOBILE_VERSION and 1 or 2
InGameMenuStatisticsFrame.CONTROLS = {
	TABLE_HEADER_BOXES = "tableHeaderBox",
	STATS_CONTAINER = "statsContainer",
	STATS_BOX_TEMPLATE = "statisticBoxElement",
	TABLES = "statisticsTable"
}

function InGameMenuStatisticsFrame.new(subclass_mt)
	local self = InGameMenuStatisticsFrame:superClass().new(nil, subclass_mt or InGameMenuStatisticsFrame_mt)

	self:registerControls(InGameMenuStatisticsFrame.CONTROLS)

	self.dataBindings = {}
	self.areTablesInitialized = false
	self.playerFarm = nil
	self.firstIndex = 1
	self.hasCustomMenuButtons = true
	self.menuButtonInfo = {
		{
			inputAction = InputAction.MENU_BACK
		}
	}

	return self
end

function InGameMenuStatisticsFrame:onFrameOpen(element)
	InGameMenuStatisticsFrame:superClass().onFrameOpen(self)

	if not self.areTablesInitialized then
		if InGameMenuStatisticsFrame.NUMBER_OF_BOXES > 1 then
			local placeholder = self.statisticsTable[2]
			local secondTable = self.statisticsTable[1]:clone(self.statisticsTable[1].parent)

			secondTable:setPosition(unpack(placeholder.position))
			placeholder:unlinkElement()
			placeholder:delete()

			self.statisticsTable[2] = secondTable

			self.statisticsTable[2]:initialize()
		end

		self.statisticsTable[1]:initialize()

		self.areTablesInitialized = true
	end

	for i, _ in ipairs(self.tableHeaderBox) do
		self.tableHeaderBox[i]:invalidateLayout()
	end

	self:updateStatistics()
end

function InGameMenuStatisticsFrame:getData()
	return self.playerFarm.stats:getStatisticData()
end

function InGameMenuStatisticsFrame:updateStatistics()
	for _, table in pairs(self.statisticsTable) do
		table:clearData()
	end

	local tableIndex = 1
	local currentTable = self.statisticsTable[tableIndex]
	local numStats = 0
	local statData = self:getData()

	if GS_IS_MOBILE_VERSION then
		self:setNumberOfPages(math.ceil(#statData / InGameMenuStatisticsFrame.STATISTICS_PER_BOX))
	end

	for i = self.firstIndex, #statData do
		local statAttribute = statData[i]

		if not GS_IS_MOBILE_VERSION and currentTable.maxNumItems <= numStats then
			numStats = 0
			tableIndex = tableIndex + 1
			currentTable = self.statisticsTable[tableIndex]

			if currentTable == nil then
				print("Warning: Number of statistics exceeds display space. Resize statistics tables or add another one.")

				break
			end
		end

		local dataRow = self:buildDataRow(statAttribute)

		currentTable:addRow(dataRow)

		numStats = numStats + 1
	end

	for _, table in pairs(self.statisticsTable) do
		table:updateView(false)
	end
end

function InGameMenuStatisticsFrame:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm
end

function InGameMenuStatisticsFrame:getMainElementSize()
	return self.statsContainer.size
end

function InGameMenuStatisticsFrame:getMainElementPosition()
	return self.statsContainer.absPosition
end

function InGameMenuStatisticsFrame:onPageChanged(page, fromPage)
	InGameMenuStatisticsFrame:superClass().onPageChanged(self, page, fromPage)

	local firstIndex = (page - 1) * InGameMenuStatisticsFrame.STATISTICS_PER_BOX + 1

	self.statisticsTable[1]:scrollTo(firstIndex)
end

InGameMenuStatisticsFrame.DATA_BINDING = {
	SESSION_VALUE = "session",
	STAT_TYPE = "stat",
	TOTAL_VALUE = "total"
}

function InGameMenuStatisticsFrame:onDataBindStat(element)
	self.dataBindings[InGameMenuStatisticsFrame.DATA_BINDING.STAT_TYPE] = element.name
end

function InGameMenuStatisticsFrame:onDataBindSessionValue(element)
	self.dataBindings[InGameMenuStatisticsFrame.DATA_BINDING.SESSION_VALUE] = element.name
end

function InGameMenuStatisticsFrame:onDataBindTotalValue(element)
	self.dataBindings[InGameMenuStatisticsFrame.DATA_BINDING.TOTAL_VALUE] = element.name
end

function InGameMenuStatisticsFrame:buildDataRow(statAttribute)
	local dataRow = TableElement.DataRow.new(statAttribute.name, self.dataBindings)
	local nameCell = dataRow.columnCells[self.dataBindings[InGameMenuStatisticsFrame.DATA_BINDING.STAT_TYPE]]
	local sessionValueCell = dataRow.columnCells[self.dataBindings[InGameMenuStatisticsFrame.DATA_BINDING.SESSION_VALUE]]
	local totalValueCell = dataRow.columnCells[self.dataBindings[InGameMenuStatisticsFrame.DATA_BINDING.TOTAL_VALUE]]
	nameCell.text = statAttribute.name
	sessionValueCell.text = statAttribute.valueSession
	totalValueCell.text = statAttribute.valueTotal

	return dataRow
end
