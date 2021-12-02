InGameMenuCalendarFrame = {}
local InGameMenuCalendarFrame_mt = Class(InGameMenuCalendarFrame, TabbedMenuFrameElement)
InGameMenuCalendarFrame.CONTROLS = {
	CALENDAR = "calendar",
	CONTAINER = "container",
	SLIDER = "calendarSlider",
	HEADER = "calendarHeader",
	TODAY_BAR = "todayBar",
	LEGEND_PLANTING_SEASON = "legendPlantingSeason",
	LEGEND_HARVEST_SEASON = "legendHarvestSeason",
	TEMPLATE = "fruitRowTemplate"
}
InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE = 1
InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE = 2
InGameMenuCalendarFrame.BLOCK_COLORS = {
	[false] = {
		[InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE] = {
			0.1237,
			0.3979,
			0.0952,
			0.95
		},
		[InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE] = {
			0.7959,
			0.3128,
			0.0246,
			0.95
		}
	},
	[true] = {
		[InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE] = {
			0.2122,
			0.1779,
			0.0027,
			0.95
		},
		[InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE] = {
			0.3372,
			0.4397,
			0.9911,
			0.95
		}
	}
}

function InGameMenuCalendarFrame.new(i18n, messageCenter)
	local self = TabbedMenuFrameElement.new(nil, InGameMenuCalendarFrame_mt)
	self.i18n = i18n
	self.messageCenter = messageCenter

	self:registerControls(InGameMenuCalendarFrame.CONTROLS)

	self.isColorBlindMode = false
	self.scrollInputDelay = 0
	self.scrollInputDelayDir = 0
	self.fruitTypes = {}

	return self
end

function InGameMenuCalendarFrame:delete()
	if self.fruitRowTemplate ~= nil then
		self.fruitRowTemplate:delete()
	end

	InGameMenuCalendarFrame:superClass().delete(self)
end

function InGameMenuCalendarFrame:copyAttributes(src)
	InGameMenuCalendarFrame:superClass().copyAttributes(self, src)

	self.i18n = src.i18n
	self.messageCenter = src.messageCenter
end

function InGameMenuCalendarFrame:initialize()
end

function InGameMenuCalendarFrame:onGuiSetupFinished()
	InGameMenuCalendarFrame:superClass().onGuiSetupFinished(self)
	self.calendar:setDataSource(self)
end

function InGameMenuCalendarFrame:onFrameOpen()
	InGameMenuCalendarFrame:superClass().onFrameOpen(self)

	self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false

	self:rebuildTable()
	self:updateTodayBar()
	self:setPeriodTitles()
	self:updateLegend()
	self.messageCenter:subscribe(MessageType.DAY_CHANGED, self.onDayChanged, self)
	self.messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self.setColorBlindMode, self)
	self:setSoundSuppressed(true)
	FocusManager:setFocus(self.calendar)
	self:setSoundSuppressed(false)
end

function InGameMenuCalendarFrame:onFrameClose()
	self.messageCenter:unsubscribe(MessageType.DAY_CHANGED, self)
	self.messageCenter:unsubscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.USE_COLORBLIND_MODE], self)
	InGameMenuCalendarFrame:superClass().onFrameClose(self)
end

function InGameMenuCalendarFrame:updateTodayBar()
	local env = g_currentMission.environment
	local season = env.currentSeason
	local intoSeason = (env.currentDayInSeason - 1) / env:getDaysPerSeason()
	local percentage = season * 0.25 + intoSeason * 0.25
	local parentSize = self.todayBar.parent.size[1]

	self.todayBar:setPosition(parentSize * percentage + parentSize / (env:getDaysPerSeason() * 4) * 0.5, nil)
end

function InGameMenuCalendarFrame:setPeriodTitles()
	for i = 1, 12 do
		local element = self.calendarHeader[i]

		element:setText(g_i18n:formatPeriod(i, true))
	end
end

function InGameMenuCalendarFrame:updateLegend()
	self.legendPlantingSeason:setImageColor(nil, unpack(InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE]))
	self.legendHarvestSeason:setImageColor(nil, unpack(InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE]))
	self.legendHarvestSeason.parent:invalidateLayout()
end

function InGameMenuCalendarFrame:rebuildTable()
	self.fruitTypes = {}

	for _, fruitDesc in pairs(g_fruitTypeManager:getFruitTypes()) do
		if fruitDesc.shownOnMap then
			table.insert(self.fruitTypes, fruitDesc)
		end
	end

	self.calendar:reloadData()
end

function InGameMenuCalendarFrame:getNumberOfItemsInSection(list, section)
	return #self.fruitTypes
end

function InGameMenuCalendarFrame:populateCellForItemInSection(list, section, index, cell)
	local fruitDesc = self.fruitTypes[index]
	local fillType = g_fruitTypeManager:getFillTypeByFruitTypeIndex(fruitDesc.index)

	cell:getAttribute("fruitIcon"):setImageFilename(fillType.hudOverlayFilename)
	cell:getAttribute("fruitName"):setText(fillType.title)
	cell:getAttribute("germination"):setText("")

	local plantColor = InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_PLANTABLE]
	local harvestColor = InGameMenuCalendarFrame.BLOCK_COLORS[self.isColorBlindMode][InGameMenuCalendarFrame.BLOCK_TYPE_HARVESTABLE]

	for i = 1, 12 do
		local e = cell:getAttribute("period" .. i)
		local plantCell = e.elements[1]
		local harvestCell = e.elements[2]

		plantCell:setVisible(g_currentMission.growthSystem:canFruitBePlanted(fruitDesc.index, i))
		plantCell:setImageColor(nil, unpack(plantColor))
		harvestCell:setVisible(g_currentMission.growthSystem:canFruitBeHarvested(fruitDesc.index, i))
		harvestCell:setImageColor(nil, unpack(harvestColor))
	end

	cell.elements[1]:invalidateLayout()
end

function InGameMenuCalendarFrame:onDayChanged()
	self:updateTodayBar()
end

function InGameMenuCalendarFrame:setColorBlindMode(isActive)
	if self.isColorBlindMode ~= isActive then
		self.isColorBlindMode = isActive

		self:rebuildTable()
		self:updateLegend()
	end
end

function InGameMenuCalendarFrame:inputEvent(action, value, eventUsed)
	local pressedUp = action == InputAction.MENU_AXIS_UP_DOWN and g_analogStickVTolerance < value
	local pressedDown = action == InputAction.MENU_AXIS_UP_DOWN and value < -g_analogStickVTolerance

	if pressedUp or pressedDown then
		local dir = pressedUp and -1 or 1

		if dir ~= self.scrollInputDelayDir or g_time - self.scrollInputDelay > 250 then
			self.scrollInputDelayDir = dir
			self.scrollInputDelay = g_time

			self.calendarSlider:setValue(self.calendarSlider:getValue() + dir)
		end
	end

	return true
end
