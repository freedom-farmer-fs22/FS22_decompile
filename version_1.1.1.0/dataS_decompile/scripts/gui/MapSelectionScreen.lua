MapSelectionScreen = {
	CONTROLS = {
		MAP_LIST = "mapList",
		SELECTOR_LEFT_GP = "selectorLeftGamepad",
		MAP_SELECTOR = "mapSelector",
		SELECTOR_RIGHT_GP = "selectorRightGamepad",
		SELECTION_STATE_BOX = "selectionStateBox"
	}
}
local MapSelectionScreen_mt = Class(MapSelectionScreen, ScreenElement)

function MapSelectionScreen.new(target, custom_mt, startMissionInfo)
	local self = ScreenElement.new(target, custom_mt or MapSelectionScreen_mt)

	self:registerControls(MapSelectionScreen.CONTROLS)

	self.startMissionInfo = startMissionInfo
	self.maps = {}

	return self
end

function MapSelectionScreen:onCreate()
	self.mapList:setDataSource(self)
end

function MapSelectionScreen:onOpen()
	MapSelectionScreen:superClass().onOpen(self)

	local missionMapIndex = self:loadAvailableMaps()

	self.mapList:reloadData()

	if missionMapIndex ~= nil then
		self.mapList:setSelectedIndex(missionMapIndex)
	end

	if Platform.isMobile then
		self:onClickOk()
	end
end

function MapSelectionScreen:loadAvailableMaps()
	self.maps = {}
	local currentSelection = nil

	for i = 1, g_mapManager:getNumOfMaps() do
		local map = g_mapManager:getMapDataByIndex(i)

		if not map.isModMap or not self.startMissionInfo.isMultiplayer or map.isMultiplayerSupported then
			table.insert(self.maps, map)

			if map.id == self.startMissionInfo.mapId then
				currentSelection = i
			end
		end
	end

	return currentSelection
end

function MapSelectionScreen:onClickMapSelection(state)
	self.mapList:setSelectedIndex(state)
end

function MapSelectionScreen:onListSelectionChanged(list, section, index)
	local map = self.maps[index]
	self.startMissionInfo.mapId = map.id

	self.mapSelector:setValue(index)
	self:updateSelectors()
end

function MapSelectionScreen:onClickOk()
	local mapModName = g_mapManager:getModNameFromMapId(self.startMissionInfo.mapId)

	if mapModName ~= nil and not PlatformPrivilegeUtil.checkModUse(self.onClickOk, self) then
		return
	end

	self.startMissionInfo.canStart = true

	if self.isMultiplayer and not self.startMissionInfo.createGame then
		self:changeScreen(MultiplayerScreen)
	else
		self:changeScreen(CareerScreen)
	end
end

function MapSelectionScreen:selectMapByNameAndFile(name, filename)
	local mapId = name

	if filename ~= "default" then
		local _ = nil
		filename, _ = Utils.getFilenameInfo(filename)
		mapId = filename .. "." .. name
	end

	local selectedMap = g_mapManager:getMapDataByIndex(1)

	for i = 1, g_mapManager:getNumOfMaps() do
		local map = g_mapManager:getMapDataByIndex(i)

		if (not map.isModMap or not self.startMissionInfo.isMultiplayer or map.isMultiplayerSupported) and map.id == mapId then
			selectedMap = map

			break
		end
	end

	self.startMissionInfo.mapId = selectedMap.id

	return selectedMap.id
end

function MapSelectionScreen:update(dt)
	MapSelectionScreen:superClass().update(self, dt)

	if g_dedicatedServer ~= nil then
		self:selectMapByNameAndFile(g_dedicatedServer.mapName, g_dedicatedServer.mapFileName)
		self:onClickOk()

		return
	end

	if self.startMissionInfo.isMultiplayer then
		Platform.verifyMultiplayerAvailabilityInMenu()
	end
end

function MapSelectionScreen:inputEvent(action, value, eventUsed)
	eventUsed = MapSelectionScreen:superClass().inputEvent(self, action, value, eventUsed)

	if not eventUsed and (action == InputAction.MENU_PAGE_PREV or action == InputAction.MENU_PAGE_NEXT) then
		local curIndex = self.mapList.selectedIndex

		if action == InputAction.MENU_PAGE_PREV then
			self.mapList:setSelectedIndex(math.max(curIndex - 1, 1))
		else
			self.mapList:setSelectedIndex(curIndex + 1)
		end

		self:updateSelectors()

		eventUsed = true
	end

	return eventUsed
end

function MapSelectionScreen:updateSelectors()
	self.selectorLeftGamepad:setVisible(self.mapList.selectedIndex ~= 1)
	self.selectorRightGamepad:setVisible(self.mapList.selectedIndex ~= #self.maps)
end

function MapSelectionScreen:getNumberOfItemsInSection(list, section)
	return #self.maps
end

function MapSelectionScreen:populateCellForItemInSection(list, section, index, cell)
	local map = self.maps[index]

	cell:getAttribute("image"):setImageFilename(map.iconFilename)
	cell:getAttribute("title"):setText(map.title)
	cell:getAttribute("text"):setText(map.description)
end
