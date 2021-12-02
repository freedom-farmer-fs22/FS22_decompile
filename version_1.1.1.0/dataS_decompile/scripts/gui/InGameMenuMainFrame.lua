InGameMenuMainFrame = {}
local InGameMenuMainFrame_mt = Class(InGameMenuMainFrame, TabbedMenuFrameElement)
InGameMenuMainFrame.CONTROLS = {
	CONTAINER = "container"
}

function InGameMenuMainFrame.new(subclass_mt)
	local self = TabbedMenuFrameElement.new(nil, subclass_mt or InGameMenuMainFrame_mt)

	self:registerControls(InGameMenuMainFrame.CONTROLS)

	return self
end

function InGameMenuMainFrame:copyAttributes(src)
	InGameMenuMainFrame:superClass().copyAttributes(self, src)
end

function InGameMenuMainFrame:initialize()
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK
	}
end

function InGameMenuMainFrame:onFrameOpen(element)
	InGameMenuMainFrame:superClass().onFrameOpen(self)

	self.menuButtonInfo = {
		self.backButtonInfo
	}

	self:setMenuButtonInfoDirty()
end

function InGameMenuMainFrame:getMainElementSize()
	return self.container.size
end

function InGameMenuMainFrame:getMainElementPosition()
	return self.container.absPosition
end

function InGameMenuMainFrame:onClickPrices()
	g_currentMission.inGameMenu:goToPage(g_currentMission.inGameMenu.pagePrices, true)
end

function InGameMenuMainFrame:onClickVehicles()
	g_currentMission.inGameMenu:goToPage(g_currentMission.inGameMenu.pageGarageOverview, true)
end

function InGameMenuMainFrame:onClickFinances()
	g_currentMission.inGameMenu:goToPage(g_currentMission.inGameMenu.pageFinances, true)
end

function InGameMenuMainFrame:onClickSettings()
	g_currentMission.inGameMenu:goToPage(g_currentMission.inGameMenu.pageSettingsMobile, true)
end

function InGameMenuMainFrame:onClickAnimals()
	g_currentMission.inGameMenu:goToPage(g_currentMission.inGameMenu.pageAnimals, true)
end

function InGameMenuMainFrame:onClickStatistics()
	g_currentMission.inGameMenu:goToPage(g_currentMission.inGameMenu.pageStatistics, true)
end

function InGameMenuMainFrame:onClickHelp()
	g_currentMission.inGameMenu:goToPage(g_currentMission.inGameMenu.pageHelpLine, true)
end

function InGameMenuMainFrame:onClickQuitGame()
	local menu = g_currentMission.inGameMenu

	if not menu.isSaving then
		menu.quitAfterSave = true

		g_currentMission:startSaveCurrentGame(false)
	end
end
