IngameMapElement = {}
local IngameMapElement_mt = Class(IngameMapElement, GuiElement)
IngameMapElement.CURSOR_SPEED_FACTOR = 0.0006
IngameMapElement.ZOOM_SPEED_FACTOR = 0.1
IngameMapElement.BORDER_SCROLL_THRESHOLD = 0.03
IngameMapElement.MAP_ZOOM_SHOW_NAMES = GS_IS_MOBILE_VERSION and 0.5 or 0.8
IngameMapElement.DRAG_START_DISTANCE = 2

function IngameMapElement.new(target, custom_mt)
	local self = GuiElement.new(target, custom_mt or IngameMapElement_mt)
	self.ingameMap = nil
	self.cursorId = nil
	self.inputMode = GS_INPUT_HELP_MODE_GAMEPAD
	self.terrainSize = 0
	self.mapAlpha = 1
	self.zoomMin = 1
	self.zoomMax = 5
	self.zoomDefault = 2
	self.mapCenterX = 0.5
	self.mapCenterY = 0.5
	self.mapZoom = self.zoomDefault
	self.accumHorizontalInput = 0
	self.accumVerticalInput = 0
	self.accumZoomInput = 0
	self.useMouse = false
	self.resetMouseNextFrame = false
	self.cursorDeadzones = {}
	self.minDragDistanceX = IngameMapElement.DRAG_START_DISTANCE / g_screenWidth
	self.minDragDistanceY = IngameMapElement.DRAG_START_DISTANCE / g_screenHeight
	self.hasDragged = false
	self.minimalHotspotSize = getNormalizedScreenValues(9, 1)
	self.isHotspotSelectionActive = true
	self.isCursorAvailable = true

	return self
end

function IngameMapElement:delete()
	GuiOverlay.deleteOverlay(self.overlay)

	self.ingameMap = nil

	IngameMapElement:superClass().delete(self)
end

function IngameMapElement:loadFromXML(xmlFile, key)
	IngameMapElement:superClass().loadFromXML(self, xmlFile, key)

	self.cursorId = getXMLString(xmlFile, key .. "#cursorId")
	self.mapAlpha = getXMLFloat(xmlFile, key .. "#mapAlpha") or self.mapAlpha

	self:addCallback(xmlFile, key .. "#onDrawPreIngameMap", "onDrawPreIngameMapCallback")
	self:addCallback(xmlFile, key .. "#onDrawPostIngameMap", "onDrawPostIngameMapCallback")
	self:addCallback(xmlFile, key .. "#onDrawPostIngameMapHotspots", "onDrawPostIngameMapHotspotsCallback")
	self:addCallback(xmlFile, key .. "#onClickHotspot", "onClickHotspotCallback")
	self:addCallback(xmlFile, key .. "#onClickMap", "onClickMapCallback")
end

function IngameMapElement:loadProfile(profile, applyProfile)
	IngameMapElement:superClass().loadProfile(self, profile, applyProfile)

	self.mapAlpha = profile:getNumber("mapAlpha", self.mapAlpha)
end

function IngameMapElement:copyAttributes(src)
	IngameMapElement:superClass().copyAttributes(self, src)

	self.mapZoom = src.mapZoom
	self.mapAlpha = src.mapAlpha
	self.cursorId = src.cursorId
	self.onDrawPreIngameMapCallback = src.onDrawPreIngameMapCallback
	self.onDrawPostIngameMapCallback = src.onDrawPostIngameMapCallback
	self.onDrawPostIngameMapHotspotsCallback = src.onDrawPostIngameMapHotspotsCallback
	self.onClickHotspotCallback = src.onClickHotspotCallback
	self.onClickMapCallback = src.onClickMapCallback
end

function IngameMapElement:onGuiSetupFinished()
	IngameMapElement:superClass().onGuiSetupFinished(self)

	if self.cursorId ~= nil then
		if self.target[self.cursorId] ~= nil then
			self.cursorElement = self.target[self.cursorId]
		else
			print("Warning: CursorId '" .. self.cursorId .. "' not found for '" .. self.target.name .. "'!")
		end
	end
end

function IngameMapElement:addCursorDeadzone(screenX, screenY, width, height)
	table.insert(self.cursorDeadzones, {
		screenX,
		screenY,
		width,
		height
	})
end

function IngameMapElement:clearCursorDeadzones()
	self.cursorDeadzones = {}
end

function IngameMapElement:isCursorInDeadzones(cursorScreenX, cursorScreenY)
	for _, zone in pairs(self.cursorDeadzones) do
		if GuiUtils.checkOverlayOverlap(cursorScreenX, cursorScreenY, zone[1], zone[2], zone[3], zone[4]) then
			return true
		end
	end

	return false
end

function IngameMapElement:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self:getIsActive() then
		eventUsed = IngameMapElement:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)

		if not GS_IS_CONSOLE_VERSION and (isDown or isUp or posX ~= self.lastMousePosX or posY ~= self.lastMousePosY) then
			self.useMouse = true

			if self.cursorElement then
				self.cursorElement:setVisible(false)
			end

			self.isCursorActive = false
		end

		if GS_IS_MOBILE_VERSION and self.useMouse and isDown then
			self.lastMousePosY = posY
		end

		if not eventUsed and isDown and button == Input.MOUSE_BUTTON_LEFT and not self:isCursorInDeadzones(posX, posY) then
			eventUsed = true

			if not self.mouseDown then
				self.mouseDown = true
			end
		end

		if self.mouseDown and self.lastMousePosX ~= nil then
			local distX = self.lastMousePosX - posX
			local distY = posY - self.lastMousePosY

			if self.isFixedHorizontal then
				distX = 0
			end

			if self.minDragDistanceX < math.abs(distX) or self.minDragDistanceY < math.abs(distY) then
				local factorX = -distX
				local factorY = distY

				self:moveCenter(factorX, factorY)

				self.hasDragged = true
			end
		end

		if isUp and button == Input.MOUSE_BUTTON_LEFT then
			if not eventUsed and self.mouseDown and not self.hasDragged then
				local localX, localY = self:getLocalPosition(posX, posY)
				local isHotspotSelectionActive = self.isHotspotSelectionActive

				self:onClickMap(localX, localY)

				if isHotspotSelectionActive then
					self:selectHotspotAt(posX, posY)
				end

				eventUsed = true
			end

			self.mouseDown = false
			self.hasDragged = false
		end

		self.lastMousePosX = posX
		self.lastMousePosY = posY
	end

	return eventUsed
end

function IngameMapElement:moveCenter(x, y)
	local width, height = self.ingameMap.fullScreenLayout:getMapSize()
	local centerX = self.cursorElement.absPosition[1] + self.cursorElement.absSize[1] * 0.5
	local centerY = self.cursorElement.absPosition[2] + self.cursorElement.absSize[2] * 0.5
	self.mapCenterX = MathUtil.clamp(self.mapCenterX + x, width * -0.25 + centerX, width * 0.25 + centerX)
	self.mapCenterY = MathUtil.clamp(self.mapCenterY + y, height * -0.25 + centerY, height * 0.25 + centerY)

	self.ingameMap.fullScreenLayout:setMapCenter(self.mapCenterX, self.mapCenterY)
end

function IngameMapElement:copySettingsFromElement(element)
	local fullScreenLayout = self.ingameMap.fullScreenLayout
	self.mapZoom = element.mapZoom
	self.mapCenterY = element.mapCenterY
	self.mapCenterX = element.mapCenterX

	fullScreenLayout:setMapZoom(self.mapZoom)
	fullScreenLayout:setMapCenter(self.mapCenterX, self.mapCenterY)
end

function IngameMapElement:zoom(direction)
	if GS_IS_MOBILE_VERSION then
		return
	end

	local targetX, targetZ = self:localToWorldPos(self:getLocalPointerTarget())
	local width, height = self.ingameMap.fullScreenLayout:getMapSize()
	local oldZoom = self.mapZoom
	local speed = IngameMapElement.ZOOM_SPEED_FACTOR * direction * width
	self.mapZoom = MathUtil.clamp(self.mapZoom + speed, self.zoomMin, self.zoomMax)

	self.ingameMap.fullScreenLayout:setMapZoom(self.mapZoom)
	self:moveCenter(0, 0)

	if oldZoom ~= self.mapZoom then
		local newTargetX, newTargetZ = self:localToWorldPos(self:getLocalPointerTarget())
		local diffX = newTargetX - targetX
		local diffZ = newTargetZ - targetZ
		local dx = diffX / self.terrainSize * 0.5 * width
		local dy = -diffZ / self.terrainSize * 0.5 * height

		self:moveCenter(dx, dy)
	end
end

function IngameMapElement:setFixedHorizontal(width, offset)
end

function IngameMapElement:setLockedToBorder(yOffset, height)
	self.yOffset = yOffset
	self.height = height
	self.lockedToBorder = true
end

function IngameMapElement:update(dt)
	IngameMapElement:superClass().update(self, dt)

	self.inputMode = g_inputBinding:getLastInputMode()

	if not g_gui:getIsDialogVisible() and not self.alreadyClosed then
		local zoomFactor = MathUtil.clamp(self.accumZoomInput, -1, 1)

		if zoomFactor ~= 0 then
			self:zoom(zoomFactor * -0.015 * dt)
		end

		if self.cursorElement ~= nil then
			self.isCursorActive = self.inputMode == GS_INPUT_HELP_MODE_GAMEPAD and not GS_IS_MOBILE_VERSION

			self.cursorElement:setVisible(self.isCursorAvailable and self.isCursorActive)
			self:updateCursor(self.accumHorizontalInput, -self.accumVerticalInput, dt)

			self.useMouse = false
		end

		self:updateMap()
	end

	self:resetFrameInputState()
end

function IngameMapElement:updateMap()
end

function IngameMapElement:resetFrameInputState()
	self.accumZoomInput = 0
	self.accumHorizontalInput = 0
	self.accumVerticalInput = 0

	if self.resetMouseNextFrame then
		self.useMouse = false
		self.resetMouseNextFrame = false
	end
end

function IngameMapElement:draw(clipX1, clipY1, clipX2, clipY2)
	self:raiseCallback("onDrawPreIngameMapCallback", self, self.ingameMap)
	self.ingameMap:drawMapOnly()
	self:raiseCallback("onDrawPostIngameMapCallback", self, self.ingameMap)
	self.ingameMap:drawHotspotsOnly()
	self:raiseCallback("onDrawPostIngameMapHotspotsCallback", self, self.ingameMap)
end

function IngameMapElement:onOpen()
	IngameMapElement:superClass().onOpen(self)

	if self.cursorElement ~= nil then
		self.cursorElement:setVisible(false)
	end

	self.isCursorActive = false

	if self.largestSize == nil then
		self.largestSize = self.size
	end

	self.ingameMap:setFullscreen(true)
	self:zoom(0)
end

function IngameMapElement:onClose()
	IngameMapElement:superClass().onClose(self)
	self:removeActionEvents()
	self.ingameMap:setFullscreen(false)
end

function IngameMapElement:reset()
	IngameMapElement:superClass().reset(self)

	self.mapCenterX = 0.5
	self.mapCenterY = 0.5
	self.mapZoom = self.zoomDefault
end

function IngameMapElement:updateCursor(deltaX, deltaY, dt)
	if self.cursorElement ~= nil and (self.isCursorActive or GS_IS_MOBILE_VERSION) then
		local speed = IngameMapElement.CURSOR_SPEED_FACTOR
		local diffX = deltaX * speed * dt / g_screenAspectRatio
		local diffY = deltaY * speed * dt

		self:moveCenter(-diffX, -diffY)
	end
end

function IngameMapElement:selectHotspotAt(posX, posY)
	if self.isHotspotSelectionActive then
		if self.ingameMap.hotspotsSorted ~= nil then
			if not self:selectHotspotFrom(self.ingameMap.hotspotsSorted[true], posX, posY) then
				self:selectHotspotFrom(self.ingameMap.hotspotsSorted[false], posX, posY)
			end

			return
		end

		self:selectHotspotFrom(self.ingameMap.hotspots, posX, posY)
	end
end

function IngameMapElement:selectHotspotFrom(hotspots, posX, posY)
	for i = #hotspots, 1, -1 do
		local hotspot = hotspots[i]

		if self.ingameMap.filter[hotspot:getCategory()] and hotspot:getIsVisible() and hotspot:getCanBeAccessed() and hotspot:hasMouseOverlap(posX, posY) then
			self:raiseCallback("onClickHotspotCallback", self, hotspot)

			return true
		end
	end

	return false
end

function IngameMapElement:getLocalPosition(posX, posY)
	local width, height = self.ingameMap.fullScreenLayout:getMapSize()
	local offX, offY = self.ingameMap.fullScreenLayout:getMapPosition()
	local x = ((posX - offX) / width - 0.25) * 2
	local y = ((posY - offY) / height - 0.25) * 2

	return x, y
end

function IngameMapElement:getLocalPointerTarget()
	if self.useMouse then
		return self:getLocalPosition(self.lastMousePosX, self.lastMousePosY)
	elseif self.cursorElement then
		local posX = self.cursorElement.absPosition[1] + self.cursorElement.size[1] * 0.5
		local posY = self.cursorElement.absPosition[2] + self.cursorElement.size[2] * 0.5

		return self:getLocalPosition(posX, posY)
	end

	return 0, 0
end

function IngameMapElement:onClickMap(localPosX, localPosY)
	local worldPosX, worldPosZ = self:localToWorldPos(localPosX, localPosY)

	self:raiseCallback("onClickMapCallback", self, worldPosX, worldPosZ)
end

function IngameMapElement:localToWorldPos(localPosX, localPosY)
	local worldPosX = localPosX * self.terrainSize
	local worldPosZ = -localPosY * self.terrainSize
	worldPosX = worldPosX - self.terrainSize * 0.5
	worldPosZ = worldPosZ + self.terrainSize * 0.5

	return worldPosX, worldPosZ
end

function IngameMapElement:worldToLocalPos(worldPosX, worldPosZ)
	worldPosX = worldPosX + self.terrainSize * 0.5
	worldPosZ = worldPosZ + self.terrainSize * 0.5
	local localPosX = worldPosX / self.terrainSize
	local localPosY = worldPosZ / self.terrainSize

	return localPosX, localPosY
end

function IngameMapElement:setMapFocusToHotspot(hotspot)
end

function IngameMapElement:isPointVisible(x, z)
end

function IngameMapElement:setIngameMap(ingameMap)
	self.ingameMap = ingameMap
end

function IngameMapElement:setTerrainSize(terrainSize)
	self.terrainSize = terrainSize
end

function IngameMapElement:setIsCursorAvailable(available)
	self.isCursorAvailable = available
end

function IngameMapElement:registerActionEvents()
	g_inputBinding:registerActionEvent(InputAction.AXIS_MAP_SCROLL_LEFT_RIGHT, self, self.onHorizontalCursorInput, false, false, true, true)
	g_inputBinding:registerActionEvent(InputAction.AXIS_MAP_SCROLL_UP_DOWN, self, self.onVerticalCursorInput, false, false, true, true)
	g_inputBinding:registerActionEvent(InputAction.INGAMEMAP_ACCEPT, self, self.onAccept, false, true, false, true)
	g_inputBinding:registerActionEvent(InputAction.AXIS_MAP_ZOOM_OUT, self, self.onZoomInput, false, false, true, true, -1)
	g_inputBinding:registerActionEvent(InputAction.AXIS_MAP_ZOOM_IN, self, self.onZoomInput, false, false, true, true, 1)
end

function IngameMapElement:removeActionEvents()
	g_inputBinding:removeActionEventsByTarget(self)
end

function IngameMapElement:onHorizontalCursorInput(_, inputValue)
	if not self:checkAndResetMouse() and not self.isFixedHorizontal then
		self.accumHorizontalInput = self.accumHorizontalInput + inputValue
	end
end

function IngameMapElement:onVerticalCursorInput(_, inputValue)
	if not self:checkAndResetMouse() then
		self.accumVerticalInput = self.accumVerticalInput + inputValue
	end
end

function IngameMapElement:onAccept()
	if self.cursorElement then
		local cursorElement = self.cursorElement
		local posX = cursorElement.absPosition[1] + cursorElement.size[1] * 0.5
		local posY = cursorElement.absPosition[2] + cursorElement.size[2] * 0.5
		local localX, localY = self:getLocalPointerTarget()
		local isHotspotSelectionActive = self.isHotspotSelectionActive

		self:onClickMap(localX, localY)

		if isHotspotSelectionActive then
			self:selectHotspotAt(posX, posY)
		end
	end
end

function IngameMapElement:onZoomInput(_, inputValue, direction)
	if not self:hasMouseOverlapWithTabHeader() or not self.useMouse then
		self.accumZoomInput = self.accumZoomInput - direction * inputValue
	end
end

function IngameMapElement:checkAndResetMouse()
	local useMouse = self.useMouse

	if useMouse then
		self.resetMouseNextFrame = true
	end

	return useMouse
end

function IngameMapElement:setHotspotSelectionActive(isActive)
	self.isHotspotSelectionActive = isActive
end

function IngameMapElement:hasMouseOverlapWithTabHeader()
	local header = g_currentMission.inGameMenu.header

	return GuiUtils.checkOverlayOverlap(g_lastMousePosX, g_lastMousePosY, header.absPosition[1], header.absPosition[2], header.absSize[1], header.absSize[2])
end
