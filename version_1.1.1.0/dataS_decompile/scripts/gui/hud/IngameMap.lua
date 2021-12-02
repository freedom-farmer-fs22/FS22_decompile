IngameMap = {}
local IngameMap_mt = Class(IngameMap, HUDElement)
IngameMap.alpha = 1
IngameMap.alphaInc = 0.005
IngameMap.maxIconZoom = 1.4
IngameMap.STATE_OFF = 1
IngameMap.STATE_MINIMAP_ROUND = 2
IngameMap.STATE_MINIMAP_SQUARE = 3
IngameMap.STATE_MAP = 4
IngameMap.STATE_FULLSCREEN = 5
IngameMap.STATE_SMALL = GS_IS_MOBILE_VERSION and 3 or 2
IngameMap.STATE_MEDIUM = GS_IS_MOBILE_VERSION and 3 or 0
IngameMap.STATE_LARGE = GS_IS_MOBILE_VERSION and 2 or 1
IngameMap.L10N_SYMBOL_TOGGLE_MAP = "input_TOGGLE_MAP_SIZE"
IngameMap.L10N_SYMBOL_SELECT_MAP = "input_INGAMEMAP_ACCEPT"
IngameMap.FIELD_REFRESH_INTERVAL = 60000

function IngameMap.new(hud, hudAtlasPath, inputDisplayManager, customMt)
	local self = IngameMap:superClass().new(nil, , customMt or IngameMap_mt)
	self.overlay = self:createBackground(hudAtlasPath)
	self.hud = hud
	self.hudAtlasPath = hudAtlasPath
	self.inputDisplayManager = inputDisplayManager
	self.uiScale = 1
	self.isVisible = true
	self.layouts = {
		IngameMapLayoutNone.new(),
		IngameMapLayoutCircle.new(),
		IngameMapLayoutSquare.new(),
		IngameMapLayoutSquareLarge.new(),
		IngameMapLayoutFullscreen.new()
	}
	self.fullScreenLayout = self.layouts[#self.layouts]
	self.state = 1
	self.layout = self.layouts[self.state]
	self.mapOverlay = Overlay.new(nil, 0, 0, 1, 1)
	self.mapElement = HUDElement.new(self.mapOverlay)

	self:createComponents(hudAtlasPath)

	for _, layout in ipairs(self.layouts) do
		layout:createComponents(self, hudAtlasPath)
	end

	self.filter = {
		[MapHotspot.CATEGORY_FIELD] = true,
		[MapHotspot.CATEGORY_ANIMAL] = true,
		[MapHotspot.CATEGORY_MISSION] = true,
		[MapHotspot.CATEGORY_TOUR] = true,
		[MapHotspot.CATEGORY_STEERABLE] = true,
		[MapHotspot.CATEGORY_COMBINE] = true,
		[MapHotspot.CATEGORY_TRAILER] = true,
		[MapHotspot.CATEGORY_TOOL] = true,
		[MapHotspot.CATEGORY_UNLOADING] = true,
		[MapHotspot.CATEGORY_LOADING] = true,
		[MapHotspot.CATEGORY_PRODUCTION] = true,
		[MapHotspot.CATEGORY_SHOP] = true,
		[MapHotspot.CATEGORY_OTHER] = true,
		[MapHotspot.CATEGORY_AI] = true,
		[MapHotspot.CATEGORY_PLAYER] = true
	}

	self:setWorldSize(2048, 2048)

	self.hotspots = {}
	self.selectedHotspot = nil
	self.allowToggle = true
	self.topDownCamera = nil

	return self
end

function IngameMap:delete()
	IngameMap:superClass().delete(self)
	g_inputBinding:removeActionEventsByTarget(self)
	self.mapElement:delete()
	self:setSelectedHotspot(nil)

	for _, layout in ipairs(self.layouts) do
		layout:delete()
	end

	if self.mapOverlayGenerator ~= nil then
		self.mapOverlayGenerator:delete()
	end
end

function IngameMap:setFullscreen(isFullscreen)
	if self.isFullscreen == isFullscreen then
		return
	end

	self.layout:deactivate()

	self.isFullscreen = isFullscreen

	if isFullscreen then
		self.layout = self.fullScreenLayout
	else
		self.layout = self.layouts[self.state]
	end

	self.layout:activate()
	g_inputBinding:setActionEventTextVisibility(self.toggleMapSizeEventId, self.layout:getShowsToggleActionText())
end

function IngameMap:toggleSize(state, force)
	self.layout:deactivate()

	if state ~= nil then
		self.state = math.max(math.min(state, #self.layouts - 1), 1)
	else
		self.state = self.state % (#self.layouts - 1) + 1
	end

	self.layout = self.layouts[self.state]

	self.layout:activate()
	g_inputBinding:setActionEventTextVisibility(self.toggleMapSizeEventId, self.layout:getShowsToggleActionText())
	g_gameSettings:setValue("ingameMapState", self.state, true)
end

function IngameMap:turnSmall()
	if self.state == IngameMap.STATE_MAP then
		self:toggleSize(IngameMap.STATE_MINIMAP_SQUARE, true)
	end
end

function IngameMap:setTopDownCamera(guiTopDownCamera)
	self.topDownCamera = guiTopDownCamera

	if guiTopDownCamera ~= nil then
		self.previousLayout = self.state

		if self.state ~= IngameMap.STATE_MINIMAP_ROUND then
			self:toggleSize(IngameMap.STATE_MINIMAP_ROUND, true)
		end
	elseif self.state ~= self.previousLayout then
		self:toggleSize(self.previousLayout, true)
	end
end

function IngameMap:resetSettings()
	if self.overlay == nil then
		return
	end

	self:setSelectedHotspot(nil)
end

function IngameMap:getHeight()
	return self.layout:getHeight()
end

function IngameMap:getRequiredHeight()
	return self:getHeight()
end

function IngameMap:getIsLarge()
	return self.state == IngameMap.STATE_MAP
end

function IngameMap:setAllowToggle(isAllowed)
	self.allowToggle = isAllowed
end

function IngameMap:setIsVisible(isVisible)
	self.isVisible = isVisible

	g_inputBinding:setActionEventActive(self.toggleMapSizeEventId, isVisible and self.layout:getShowsToggleActionText())
end

function IngameMap:onToggleMapSize()
	if self.allowToggle and (not g_gui:getIsGuiVisible() or g_gui:getIsOverlayGuiVisible()) then
		self:toggleSize()
	end
end

function IngameMap:loadMap(filename, worldSizeX, worldSizeZ, fieldColor, grassFieldColor)
	self.mapElement:delete()
	self:setWorldSize(worldSizeX, worldSizeZ)

	self.mapOverlay = Overlay.new(filename, 0, 0, 1, 1)
	self.mapElement = HUDElement.new(self.mapOverlay)

	self:addChild(self.mapElement)
	self:setScale(self.uiScale)

	self.mapOverlayGenerator = MapOverlayGenerator.new(g_i18n, g_fruitTypeManager, g_fillTypeManager, g_farmlandManager, g_farmManager, g_currentMission.weedSystem)

	self.mapOverlayGenerator:setColorBlindMode(false)
	self.mapOverlayGenerator:setFieldColor(fieldColor, grassFieldColor)

	self.fieldRefreshTimer = IngameMap.FIELD_REFRESH_INTERVAL
end

function IngameMap:registerInput()
	local _, eventId = g_inputBinding:registerActionEvent(InputAction.TOGGLE_MAP_SIZE, self, self.onToggleMapSize, false, true, false, true)
	self.toggleMapSizeEventId = eventId

	g_inputBinding:setActionEventText(self.toggleMapSizeEventId, g_i18n:getText(IngameMap.L10N_SYMBOL_TOGGLE_MAP))
	g_inputBinding:setActionEventTextVisibility(self.toggleMapSizeEventId, self.layout:getShowsToggleActionText())
	g_inputBinding:setActionEventTextPriority(self.toggleMapSizeEventId, GS_PRIO_VERY_LOW)
end

function IngameMap:setWorldSize(worldSizeX, worldSizeZ)
	self.worldSizeX = worldSizeX
	self.worldSizeZ = worldSizeZ
	self.worldCenterOffsetX = self.worldSizeX * 0.5
	self.worldCenterOffsetZ = self.worldSizeZ * 0.5

	for _, layout in ipairs(self.layouts) do
		layout:setWorldSize(worldSizeX, worldSizeZ)
	end
end

function IngameMap:setHasUnreadMessages(hasMessages)
	self.layout:setHasUnreadMessages(hasMessages)
end

function IngameMap:determinePlayerPosition(player)
	return player:getPositionData()
end

function IngameMap:determineVehiclePosition(enterable)
	local posX, posY, posZ = getTranslation(enterable.rootNode)
	local dx, _, dz = localDirectionToWorld(enterable.rootNode, 0, 0, 1)
	local yRot = nil

	if enterable.spec_drivable ~= nil and enterable.spec_drivable.reverserDirection == -1 then
		yRot = MathUtil.getYRotationFromDirection(dx, dz)
	else
		yRot = MathUtil.getYRotationFromDirection(dx, dz) + math.pi
	end

	local vel = enterable:getLastSpeed()

	return posX, posY, posZ, yRot, vel
end

function IngameMap:addMapHotspot(mapHotspot)
	table.insert(self.hotspots, mapHotspot)

	if GS_IS_MOBILE_VERSION then
		local mapSize = 1024

		table.sort(self.hotspots, function (v1, v2)
			local band1 = math.ceil((v1.worldZ + mapSize * 0.5) / (mapSize * 0.16666))
			local band2 = math.ceil((v2.worldZ + mapSize * 0.5) / (mapSize * 0.16666))

			if band1 == band2 then
				return v1.worldX < v2.worldX or v1.worldX == v2.worldX and v1.worldZ < v2.worldZ
			else
				return band1 - band2 < 0
			end
		end)
	else
		table.sort(self.hotspots, function (v1, v2)
			return v2:getCategory() < v1:getCategory()
		end)
	end

	self.hotspotsSorted = nil

	return mapHotspot
end

function IngameMap:removeMapHotspot(mapHotspot)
	if mapHotspot ~= nil then
		for i = 1, #self.hotspots do
			if self.hotspots[i] == mapHotspot then
				table.remove(self.hotspots, i)

				break
			end
		end

		if self.selectedHotspot == mapHotspot then
			self:setSelectedHotspot(nil)
		end

		if g_currentMission ~= nil and g_currentMission.currentMapTargetHotspot == mapHotspot then
			g_currentMission:setMapTargetHotspot(nil)
		end

		self.hotspotsSorted = nil
	end
end

function IngameMap:setSelectedHotspot(hotspot)
	if self.selectedHotspot ~= nil then
		self.selectedHotspot:setSelected(false)
	end

	self.selectedHotspot = hotspot

	if self.selectedHotspot ~= nil then
		self.selectedHotspot:setSelected(true)
	end
end

function IngameMap:getHotspotIndex(hotspot)
	for i, spot in ipairs(self.hotspots) do
		if spot == hotspot then
			return i
		end
	end

	return -1
end

function IngameMap:cycleVisibleHotspot(currentHotspot, categoriesHash, direction)
	local currentIndex = self:getHotspotIndex(currentHotspot) + direction

	if currentIndex < 1 or currentIndex > #self.hotspots then
		if direction > 0 then
			currentIndex = 1
		else
			currentIndex = #self.hotspots
		end
	end

	local visitedCount = 0
	local hotspot = self.hotspots[currentIndex]

	while visitedCount < #self.hotspots do
		local category = hotspot:getCategory()

		if hotspot:getIsVisible() and self.filter[category] and categoriesHash[category] then
			break
		end

		visitedCount = visitedCount + 1
		currentIndex = currentIndex + direction

		if currentIndex > #self.hotspots then
			currentIndex = 1
		elseif currentIndex < 1 then
			currentIndex = #self.hotspots
		end

		hotspot = self.hotspots[currentIndex]
	end

	if visitedCount < #self.hotspots then
		return hotspot
	else
		return nil
	end
end

function IngameMap:updateHotspotSorting(dt)
	if self.hotspotsSorted == nil then
		self.hotspotsSorted = {
			[true] = {},
			[false] = {}
		}

		for _, currentHotspot in pairs(self.hotspots) do
			if self.filter[currentHotspot:getCategory()] then
				table.insert(self.hotspotsSorted[currentHotspot:getRenderLast()], currentHotspot)
			end
		end
	end
end

function IngameMap:updateBlinkingHotspotAlpha(dt)
	IngameMap.alpha = math.abs(math.sin(g_time / 200))
end

function IngameMap:updateHotspotFilters()
	for category, _ in pairs(self.filter) do
		if category == MapHotspot.CATEGORY_SHOP then
			self:setHotspotFilter(category, not Utils.isBitSet(g_gameSettings:getValue("ingameMapFilter"), MapHotspot.CATEGORY_OTHER))
		else
			self:setHotspotFilter(category, not Utils.isBitSet(g_gameSettings:getValue("ingameMapFilter"), category))
		end
	end
end

function IngameMap:setHotspotFilter(category, isActive)
	if category ~= nil then
		if isActive then
			g_gameSettings:setValue("ingameMapFilter", Utils.clearBit(g_gameSettings:getValue("ingameMapFilter"), category))
		else
			g_gameSettings:setValue("ingameMapFilter", Utils.setBit(g_gameSettings:getValue("ingameMapFilter"), category))
		end

		self.filter[category] = isActive
		self.hotspotsSorted = nil
	end
end

function IngameMap:update(dt)
	if self.isVisible and self.state ~= IngameMap.STATE_OFF and self.layout:getShowsToggleAction() then
		self:updateInputGlyphs()
	end

	self:updateHotspotSorting(dt)
	self:updateBlinkingHotspotAlpha(dt)
	self:updatePlayerPosition()
	self.layout:setPlayerPosition(self.normalizedPlayerPosX, self.normalizedPlayerPosZ, self.playerRotation)
	self.layout:setPlayerVelocity(self.playerVelocity or 0)

	if self.mapOverlayGenerator ~= nil then
		self.fieldRefreshTimer = self.fieldRefreshTimer + dt

		if IngameMap.FIELD_REFRESH_INTERVAL < self.fieldRefreshTimer then
			self.fieldRefreshTimer = 0

			self.mapOverlayGenerator:generateMinimapOverlay(function (overlayId)
				self.fieldStateOverlay = overlayId
				self.fieldStateOverlayIsReady = true
			end, nil)
		end

		self.mapOverlayGenerator:update(dt)
	end
end

function IngameMap:updateInputGlyphs()
	self.toggleMapSizeGlyph:setAction(InputAction.TOGGLE_MAP_SIZE)
end

function IngameMap:updatePlayerPosition()
	local playerPosX = 0
	local playerPosY = 0
	local playerPosZ = 0

	if self.topDownCamera ~= nil then
		playerPosX, playerPosY, playerPosZ, self.playerRotation, self.playerVelocity = self.topDownCamera:determineMapPosition()
	elseif g_currentMission.controlPlayer then
		if g_currentMission.player ~= nil then
			playerPosX, playerPosY, playerPosZ, self.playerRotation, self.playerVelocity = self:determinePlayerPosition(g_currentMission.player)
		end
	elseif g_currentMission.controlledVehicle ~= nil then
		playerPosX, playerPosY, playerPosZ, self.playerRotation, self.playerVelocity = self:determineVehiclePosition(g_currentMission.controlledVehicle)
	end

	self.normalizedPlayerPosX = MathUtil.clamp((playerPosX + self.worldCenterOffsetX) / self.worldSizeX, 0, 1)
	self.normalizedPlayerPosZ = MathUtil.clamp((playerPosZ + self.worldCenterOffsetZ) / self.worldSizeZ, 0, 1)
end

function IngameMap:draw()
	if not self.isVisible then
		return
	end

	local width, height = self.layout:getMapSize()

	if width == 0 or height == 0 then
		return
	end

	self.mapElement:setDimension(width, height)
	self.mapElement:setAlpha(self.layout:getMapAlpha())
	self.mapElement:setPosition(self.layout:getMapPosition())
	self.mapElement:setRotationPivot(self.layout:getMapPivot())
	self.mapElement:setRotation(self.layout:getMapRotation())
	self.layout:drawBefore()
	self.mapElement:draw()
	self:drawFields()
	self:drawPointsOfInterest()
	self.layout:drawAfter()
	self:drawPersistentPointsOfInterest()

	if self.layout:getShowsToggleAction() then
		self.toggleMapSizeGlyph:draw()
	end

	self:drawPlayersCoordinates()
	self:drawLatencyToServer()
end

function IngameMap:drawFields()
	if self.fieldStateOverlayIsReady then
		local width, height = self.layout:getMapSize()
		local x, y = self.layout:getMapPosition()
		local px, py = self.layout:getMapPivot()
		px = px + x
		py = py + y
		x = x + width * 0.25
		y = y + height * 0.25
		px = px - x
		py = py - y

		setOverlayRotation(self.fieldStateOverlay, self.layout:getMapRotation(), px, py)
		setOverlayColor(self.fieldStateOverlay, 1, 1, 1, math.sqrt(self.layout:getMapAlpha()))
		renderOverlay(self.fieldStateOverlay, x, y, width * 0.5, height * 0.5)
	end
end

function IngameMap:drawMapOnly()
	local width, height = self.layout:getMapSize()

	self.mapElement:setDimension(width, height)
	self.mapElement:setAlpha(self.layout:getMapAlpha())
	self.mapElement:setPosition(self.layout:getMapPosition())
	self.mapElement:setRotationPivot(self.layout:getMapPivot())
	self.mapElement:setRotation(self.layout:getMapRotation())
	self.layout:drawBefore()
	self.mapElement:draw()
	self:drawFields()
	self.layout:drawAfter()
end

function IngameMap:drawHotspotsOnly()
	self:drawPointsOfInterest()
	self:drawPersistentPointsOfInterest()
end

function IngameMap:drawPlayersCoordinates()
	local renderString = string.format("%.1f°, %d, %d", math.deg(-self.playerRotation % (2 * math.pi)), self.normalizedPlayerPosX * self.worldSizeX, self.normalizedPlayerPosZ * self.worldSizeZ)

	self.layout:drawCoordinates(renderString)
end

function IngameMap:drawLatencyToServer()
	if g_client ~= nil and g_client.currentLatency ~= nil and g_currentMission.missionDynamicInfo.isMultiplayer and g_currentMission.missionDynamicInfo.isClient then
		local color = nil

		if g_client.currentLatency <= 50 then
			color = IngameMap.COLOR.LATENCY_GOOD
		elseif g_client.currentLatency < 100 then
			color = IngameMap.COLOR.LATENCY_MEDIUM
		else
			color = IngameMap.COLOR.LATENCY_BAD
		end

		self.layout:drawLatency(string.format("%dms", math.max(g_client.currentLatency, 10)), color)
	end
end

function IngameMap:drawPointsOfInterest()
	local smallIconVariation = self.layout:getShowSmallIconVariation()

	self:drawHotspots(false, false, smallIconVariation)
	self:drawHotspots(false, true, smallIconVariation)

	if self.selectedHotspot ~= nil then
		self:drawHotspot(self.selectedHotspot, smallIconVariation)
	end
end

function IngameMap:drawPersistentPointsOfInterest()
	local smallIconVariation = self.layout:getShowSmallIconVariation()

	self:drawHotspots(true, false, smallIconVariation)
	self:drawHotspots(true, true, smallIconVariation)
end

function IngameMap:drawHotspots(persistent, renderLast, smallVersion)
	if renderLast then
		new2DLayer()
	end

	if self.hotspotsSorted ~= nil then
		for _, hotspot in pairs(self.hotspotsSorted[renderLast]) do
			if hotspot:getIsPersistent() == persistent and hotspot ~= self.selectedHotspot and hotspot:getIsVisible() then
				self:drawHotspot(hotspot, smallVersion)
			end
		end
	end
end

function IngameMap:drawHotspot(hotspot, smallVersion)
	if hotspot == nil then
		return
	end

	local worldX, worldZ = hotspot:getWorldPosition()
	local rotation = hotspot:getWorldRotation()
	local objectX = (worldX + self.worldCenterOffsetX) / self.worldSizeX * 0.5 + 0.25
	local objectZ = (worldZ + self.worldCenterOffsetZ) / self.worldSizeZ * 0.5 + 0.25
	local zoom = self.layout:getIconZoom()

	hotspot:setScale(self.uiScale * zoom)

	local x, y, yRot, visible = self.layout:getMapObjectPosition(objectX, objectZ, hotspot:getWidth(), hotspot:getHeight(), rotation, hotspot:getIsPersistent())

	if visible then
		hotspot:setLastRenderInfo(x, y, yRot, self.layout)
		hotspot:render(x, y, yRot, smallVersion)
	end
end

function IngameMap:setScale(uiScale)
	IngameMap:superClass().setScale(self, uiScale, uiScale)

	self.uiScale = uiScale

	self:storeScaledValues(uiScale)
end

function IngameMap:storeScaledValues(uiScale)
	for _, layout in ipairs(self.layouts) do
		layout:storeScaledValues(self, uiScale)
	end
end

function IngameMap:getBackgroundPosition()
	return g_safeFrameOffsetX, g_safeFrameOffsetY
end

function IngameMap:createBackground(hudAtlasPath)
	local width, height = getNormalizedScreenValues(unpack(IngameMap.SIZE.SELF))
	local posX, posY = self:getBackgroundPosition()
	local overlay = Overlay.new(hudAtlasPath, posX, posY, width, height)

	overlay:setUVs(GuiUtils.getUVs(IngameMap.UV.BACKGROUND_ROUND))
	overlay:setColor(0, 0, 0, 0.75)

	return overlay
end

function IngameMap:createComponents(hudAtlasPath)
	local baseX, baseY = self:getPosition()
	local width = self:getWidth()
	local height = self:getHeight()

	self:createToggleMapSizeGlyph(hudAtlasPath, baseX, baseY, width, height)
end

function IngameMap:createToggleMapSizeGlyph(hudAtlasPath, baseX, baseY, baseWidth, baseHeight)
	local width, height = getNormalizedScreenValues(unpack(IngameMap.SIZE.INPUT_ICON))
	local offX, offY = getNormalizedScreenValues(unpack(IngameMap.POSITION.INPUT_ICON))
	local element = InputGlyphElement.new(self.inputDisplayManager, width, height)
	local posX = baseX + offX
	local posY = baseY + offY

	element:setPosition(posX, posY)
	element:setKeyboardGlyphColor(IngameMap.COLOR.INPUT_ICON)
	element:setAction(InputAction.TOGGLE_MAP_SIZE)

	self.toggleMapSizeGlyph = element

	self:addChild(element)
end

IngameMap.MIN_MAP_WIDTH = GS_IS_MOBILE_VERSION and 600 or 300
IngameMap.MIN_MAP_HEIGHT = IngameMap.MIN_MAP_WIDTH
IngameMap.SIZE = {
	MAP = {
		236,
		236
	},
	SELF = {
		256,
		256
	},
	INPUT_ICON = {
		35,
		35
	}
}
IngameMap.TEXT_SIZE = {
	GLYPH_TEXT = 16
}
IngameMap.POSITION = {
	MAP = {
		10,
		10
	},
	MAP_LABEL = {
		0,
		3
	},
	INFO_TEXT = {
		6,
		12
	},
	INPUT_ICON = {
		6,
		6
	}
}
IngameMap.UV = {
	BACKGROUND_ROUND = {
		48,
		288,
		256,
		256
	}
}
IngameMap.COLOR = {
	INPUT_ICON = {
		0.0003,
		0.5647,
		0.9822,
		0.8
	},
	COORDINATES_TEXT = {
		1,
		1,
		1,
		1
	},
	LATENCY_GOOD = {
		1,
		1,
		1,
		1
	},
	LATENCY_MEDIUM = {
		0.9301,
		0.2874,
		0.013,
		1
	},
	LATENCY_BAD = {
		0.8069,
		0.0097,
		0.0097,
		1
	}
}
