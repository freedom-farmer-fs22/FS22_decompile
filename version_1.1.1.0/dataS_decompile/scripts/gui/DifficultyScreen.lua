DifficultyScreen = {
	CONTROLS = {
		DIFFICULTY_LIST = "difficultyList"
	}
}
local DifficultyScreen_mt = Class(DifficultyScreen, ScreenElement)

function DifficultyScreen.new(target, custom_mt, startMissionInfo)
	local self = ScreenElement.new(target, custom_mt or DifficultyScreen_mt)

	self:registerControls(DifficultyScreen.CONTROLS)

	self.startMissionInfo = startMissionInfo

	return self
end

function DifficultyScreen:onOpen()
	DifficultyScreen:superClass().onOpen(self)
	self:setIsMultiplayer(self.startMissionInfo.isMultiplayer)
	self.difficultyList:reloadData()
	self.difficultyList:setSelectedIndex(self.startMissionInfo.difficulty)
	FocusManager:setFocus(self.difficultyList)

	if Platform.isMobile then
		self:onClickOk()
	end
end

function DifficultyScreen:setIsMultiplayer(isMultiplayer)
	self.difficultyList:reloadData()

	if isMultiplayer and self.startMissionInfo.difficulty == 1 then
		self.startMissionInfo.difficulty = 2

		if self.startMissionInfo.isMultiplayer then
			self.difficultyList:setSelectedIndex(1)
		else
			self.difficultyList:setSelectedIndex(2)
		end
	end
end

function DifficultyScreen:onClickOk(isMouseClick)
	self:changeScreen(MapSelectionScreen, DifficultyScreen)
end

function DifficultyScreen:update(dt)
	DifficultyScreen:superClass().update(self, dt)

	if g_dedicatedServer ~= nil then
		self.startMissionInfo.difficulty = g_dedicatedServer.difficulty

		self:onClickOk()

		return
	end

	if self.startMissionInfo.isMultiplayer then
		Platform.verifyMultiplayerAvailabilityInMenu()
	end
end

function DifficultyScreen:getNumberOfItemsInSection(list, section)
	if self.startMissionInfo.isMultiplayer then
		return 2
	else
		return 3
	end
end

function DifficultyScreen:populateCellForItemInSection(list, section, index, cell)
	if self.startMissionInfo.isMultiplayer then
		index = index + 1
	end

	local levels = {
		"easy",
		"normal",
		"hard"
	}
	local level = levels[index]

	cell:getAttribute("title"):setLocaKey("ui_difficulty" .. index)
	cell:getAttribute("subtitle"):setLocaKey("ui_difficulty" .. index .. "_subtitle")
	cell:getAttribute("description"):setLocaKey("ui_difficulty_" .. level .. "_description")

	local icon = cell:getAttribute("icon")

	icon:setImageFilename(string.format("dataS/menu/difficultyIcon_%s.png", level))
end

function DifficultyScreen:onListSelectionChanged(list, section, index)
	if self.startMissionInfo.isMultiplayer then
		index = index + 1
	end

	self.startMissionInfo.difficulty = index

	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
end
