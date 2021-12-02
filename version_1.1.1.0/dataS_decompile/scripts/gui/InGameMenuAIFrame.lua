InGameMenuAIFrame = {}
local InGameMenuAIFrame_mt = Class(InGameMenuAIFrame, TabbedMenuFrameElement)
InGameMenuAIFrame.CONTROLS = {
	"mapOverviewSelector",
	"ingameMap",
	"mapCursor",
	"mapControls",
	"actionMessage",
	"errorMessage",
	"statusMessage",
	"mapZoomGlyph",
	"mapMoveGlyph",
	"mapBox",
	"mapMoveGlyphText",
	"mapZoomGlyphText",
	"buttonGotoJob",
	"buttonCreateJob",
	"buttonCancel",
	"buttonStartJob",
	"buttonSkipTask",
	"buttonBack",
	"buttonCancelJob",
	"limitReachedWarning",
	"contextBox",
	"contextImage",
	"contextText",
	"contextFarm",
	"contextBoxCorner",
	"activeWorkerList",
	"jobOverview",
	"jobMenu",
	"jobTypeElement",
	"jobMenuLayout",
	"createMultiOptionTemplate",
	"createTextTemplate",
	"createTitleTemplate",
	"createPositionTemplate",
	"createPositionRotationTemplate",
	"buttonSelectIngame"
}
InGameMenuAIFrame.MODE_OVERVIEW = 1
InGameMenuAIFrame.MODE_CREATE = 2
InGameMenuAIFrame.INPUT_CONTEXT_NAME = "MENU_AI"
InGameMenuAIFrame.CLEAR_INPUT_ACTIONS = {
	InputAction.MENU_ACTIVATE,
	InputAction.MENU_CANCEL,
	InputAction.MENU_EXTRA_1,
	InputAction.MENU_EXTRA_2,
	InputAction.SWITCH_VEHICLE,
	InputAction.SWITCH_VEHICLE_BACK,
	InputAction.CAMERA_ZOOM_IN,
	InputAction.CAMERA_ZOOM_OUT
}
InGameMenuAIFrame.CLEAR_CLOSE_INPUT_ACTIONS = {
	InputAction.SWITCH_VEHICLE,
	InputAction.SWITCH_VEHICLE_BACK,
	InputAction.CAMERA_ZOOM_IN,
	InputAction.CAMERA_ZOOM_OUT
}
InGameMenuAIFrame.BUTTON_FRAME_SIDE = GuiElement.FRAME_RIGHT

local function NO_CALLBACK()
end

function InGameMenuAIFrame.new(subclass_mt, messageCenter, l10n, inputManager, inputDisplayManager, fruitTypeManager, fillTypeManager, storeManager, shopController, farmlandManager, farmManager)
	local self = TabbedMenuFrameElement.new(nil, subclass_mt or InGameMenuAIFrame_mt)

	self:registerControls(InGameMenuAIFrame.CONTROLS)

	self.inputManager = inputManager
	self.fruitTypeManager = fruitTypeManager
	self.fillTypeManager = fillTypeManager
	self.farmManager = farmManager
	self.farmlandManager = farmlandManager
	self.onClickBackCallback = NO_CALLBACK
	self.hasFullScreenMap = true
	self.playerFarm = nil
	self.jobTypeInstances = {}
	self.statusMessages = {}
	self.mode = InGameMenuAIFrame.MODE_OVERVIEW
	self.mapOverlayGenerator = nil
	self.hotspotFilterState = {}
	self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
	self.isMapOverviewInitialized = false
	self.lastInputHelpMode = 0
	self.isInputContextActive = false
	self.currentHotspot = nil
	self.ingameMapBase = nil
	self.staticUIDeadzone = {
		0,
		0,
		0,
		0
	}
	self.needsSolidBackground = true
	self.lastMousePosX = 0
	self.lastMousePosY = 0
	self.updateTime = 0
	self.aiTargetMapHotspot = AITargetHotspot.new()

	return self
end

function InGameMenuAIFrame:copyAttributes(src)
	InGameMenuAIFrame:superClass().copyAttributes(self, src)

	self.inputManager = src.inputManager
	self.fruitTypeManager = src.fruitTypeManager
	self.fillTypeManager = src.fillTypeManager
	self.farmlandManager = src.farmlandManager
	self.farmManager = src.farmManager
	self.onClickBackCallback = src.onClickBackCallback or NO_CALLBACK
end

function InGameMenuAIFrame:onGuiSetupFinished()
	InGameMenuAIFrame:superClass().onGuiSetupFinished(self)

	local _ = nil
	_, self.glyphTextSize = getNormalizedScreenValues(0, InGameMenuAIFrame.GLYPH_TEXT_SIZE)
	self.zoomText = g_i18n:getText(InGameMenuAIFrame.L10N_SYMBOL.INPUT_ZOOM_MAP)
	self.moveCursorText = g_i18n:getText(InGameMenuAIFrame.L10N_SYMBOL.INPUT_MOVE_CURSOR)
	self.panMapText = g_i18n:getText(InGameMenuAIFrame.L10N_SYMBOL.INPUT_PAN_MAP)
end

function InGameMenuAIFrame:delete()
	g_messageCenter:unsubscribeAll(self)
	self.farmlandManager:removeStateChangeListener(self)
	self.createMultiOptionTemplate:delete()
	self.createTextTemplate:delete()
	self.createTitleTemplate:delete()
	self.createPositionTemplate:delete()
	self.createPositionRotationTemplate:delete()

	if self.aiTargetMapHotspot ~= nil then
		self.aiTargetMapHotspot:delete()

		self.aiTargetMapHotspot = nil
	end

	InGameMenuAIFrame:superClass().delete(self)
end

function InGameMenuAIFrame:initialize(onClickBackCallback)
	if not GS_IS_MOBILE_VERSION then
		self:updateInputGlyphs()
	end

	self.onClickBackCallback = onClickBackCallback or NO_CALLBACK

	if GS_IS_MOBILE_VERSION then
		self:setNumberOfPages(6)
	end

	self.createMultiOptionTemplate:unlinkElement()
	FocusManager:removeElement(self.createMultiOptionTemplate)
	self.createTextTemplate:unlinkElement()
	FocusManager:removeElement(self.createTextTemplate)
	self.createTitleTemplate:unlinkElement()
	FocusManager:removeElement(self.createTitleTemplate)
	self.createPositionTemplate:unlinkElement()
	FocusManager:removeElement(self.createPositionTemplate)
	self.createPositionRotationTemplate:unlinkElement()
	FocusManager:removeElement(self.createPositionRotationTemplate)
end

function InGameMenuAIFrame:onFrameOpen()
	InGameMenuAIFrame:superClass().onFrameOpen(self)

	self.isOpen = true

	self:toggleMapInput(true)
	self.ingameMap:onOpen()
	self.ingameMap:registerActionEvents()
	self:setJobMenuVisible(false)

	for k, v in pairs(self.ingameMapBase.filter) do
		self.hotspotFilterState[k] = v

		self.ingameMapBase:setHotspotFilter(k, false)
	end

	self.ingameMapBase:setHotspotFilter(MapHotspot.CATEGORY_FIELD, true)
	self.ingameMapBase:setHotspotFilter(MapHotspot.CATEGORY_UNLOADING, true)
	self.ingameMapBase:setHotspotFilter(MapHotspot.CATEGORY_LOADING, true)
	self.ingameMapBase:setHotspotFilter(MapHotspot.CATEGORY_PRODUCTION, true)
	self.ingameMapBase:setHotspotFilter(MapHotspot.CATEGORY_AI, true)
	self.ingameMapBase:setHotspotFilter(MapHotspot.CATEGORY_COMBINE, true)
	self.ingameMapBase:setHotspotFilter(MapHotspot.CATEGORY_STEERABLE, true)
	self.ingameMapBase:setHotspotFilter(MapHotspot.CATEGORY_PLAYER, true)

	self.mapOverviewZoom = 1
	self.mapOverviewCenterX = 0.5
	self.mapOverviewCenterY = 0.5
	self.mode = InGameMenuAIFrame.MODE_OVERVIEW

	if self.visible and not self.isMapOverviewInitialized then
		self:setupMapOverview()
	else
		self:setMapSelectionItem(self.currentHotspot)
	end

	self:setMapSelectionItem(nil)
	self:setMapSelectionPosition(nil, )
	self:generateJobTypes()
	FocusManager:setFocus(self.mapOverviewSelector)
	self:updateInputGlyphs()
	self.activeWorkerList:reloadData()
	g_messageCenter:subscribe(MessageType.AI_VEHICLE_STATE_CHANGE, self.onAIVehicleStateChanged, self)
	g_messageCenter:subscribe(MessageType.AI_JOB_STARTED, self.onAIJobStarted, self)
	g_messageCenter:subscribe(MessageType.AI_JOB_STOPPED, self.onAIJobStopped, self)
	g_messageCenter:subscribe(MessageType.AI_JOB_REMOVED, self.onAIJobRemoved, self)

	local currentVehicle = g_currentMission.controlledVehicle

	if currentVehicle ~= nil then
		local hotspot = currentVehicle:getMapHotspot()

		self:setMapSelectionItem(hotspot)
	end
end

function InGameMenuAIFrame:onFrameClose()
	self.startJobPending = false

	if self:getIsPicking() then
		self:executePickingCallback(false)
		self:refreshContextInput()
	end

	g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)
	g_messageCenter:unsubscribe(AIJobStartRequestEvent, self)
	g_messageCenter:unsubscribe(MessageType.AI_VEHICLE_STATE_CHANGE, self)
	g_messageCenter:unsubscribe(MessageType.AI_JOB_STARTED, self)
	g_messageCenter:unsubscribe(MessageType.AI_JOB_STOPPED, self)
	g_messageCenter:unsubscribe(MessageType.AI_JOB_REMOVED, self)
	self.ingameMap:onClose()
	self:toggleMapInput(false)

	for k, v in pairs(self.ingameMapBase.filter) do
		self.ingameMapBase:setHotspotFilter(k, self.hotspotFilterState[k])
	end

	self.isOpen = false

	self:setJobMenuVisible(false)

	self.statusMessages = {}

	self:updateStatusMessages()
	InGameMenuAIFrame:superClass().onFrameClose(self)
end

function InGameMenuAIFrame:onLoadMapFinished()
	self.mapOverlayGenerator = MapOverlayGenerator.new(g_i18n, self.fruitTypeManager, self.fillTypeManager, self.farmlandManager, self.farmManager, g_currentMission.weedSystem)

	self.mapOverlayGenerator:setColorBlindMode(self.isColorBlindMode)
	self.mapOverlayGenerator:setFieldColor(g_currentMission.mapFieldColor, g_currentMission.mapGrassFieldColor)
end

function InGameMenuAIFrame:toggleMapInput(isActive)
	if self.isInputContextActive ~= isActive then
		self.isInputContextActive = isActive

		self:toggleCustomInputContext(isActive, InGameMenuAIFrame.INPUT_CONTEXT_NAME)

		if isActive then
			self:registerInput()
		else
			self:unregisterInput(true)
		end
	end
end

function InGameMenuAIFrame:reset()
	InGameMenuAIFrame:superClass().reset(self)

	if self.mapOverlayGenerator ~= nil then
		self.mapOverlayGenerator:delete()

		self.mapOverlayGenerator = nil
	end

	self.isMapOverviewInitialized = false
	self.isInputContextActive = false
	self.currentHotspot = nil

	InGameMenuMapUtil.hideContextBox(self.contextBox)
end

function InGameMenuAIFrame:mouseEvent(posX, posY, isDown, isUp, button, eventUsed)
	if self.isPickingRotation then
		local localX, localY = self.ingameMap:getLocalPosition(posX, posY)
		local worldX, worldZ = self.ingameMap:localToWorldPos(localX, localY)
		local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2])
		angle = angle + math.pi

		if self.pickingRotationSnapAngle > 0 then
			local numSteps = MathUtil.round(angle / self.pickingRotationSnapAngle, 0)
			angle = numSteps * self.pickingRotationSnapAngle
		end

		self.aiTargetMapHotspot:setWorldRotation(angle)
	end

	self.lastMousePoxY = posY
	self.lastMousePosX = posX

	if self.isPickingLocation then
		local localX, localY = self.ingameMap:getLocalPosition(self.lastMousePosX, self.lastMousePoxY)

		self:setTargetPointHotspotPosition(localX, localY)
	end

	return InGameMenuAIFrame:superClass().mouseEvent(self, posX, posY, isDown, isUp, button, eventUsed)
end

function InGameMenuAIFrame:update(dt)
	InGameMenuAIFrame:superClass().update(self, dt)

	local currentInputHelpMode = self.inputManager:getInputHelpMode()

	if currentInputHelpMode ~= self.lastInputHelpMode then
		self.lastInputHelpMode = currentInputHelpMode

		if not GS_IS_MOBILE_VERSION then
			self:updateInputGlyphs()
		end
	end

	self:updateContextInputBarVisibility()

	if currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		local localX, localY = self.ingameMap:getLocalPointerTarget()

		if self.isPickingLocation then
			self:setTargetPointHotspotPosition(localX, localY)
		elseif self.isPickingRotation then
			local worldX, worldZ = self.ingameMap:localToWorldPos(localX, localY)
			local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2])
			angle = angle + math.pi

			if self.pickingRotationSnapAngle > 0 then
				local numSteps = MathUtil.round(angle / self.pickingRotationSnapAngle, 0)
				angle = numSteps * self.pickingRotationSnapAngle
			end

			self.aiTargetMapHotspot:setWorldRotation(angle)
		end
	end

	self.mapOverlayGenerator:update(dt)

	if self.updateTime < g_time then
		for i = 1, self.activeWorkerList:getItemCount() do
			local element = self.activeWorkerList:getElementAtSectionIndex(1, i)

			if element ~= nil then
				local job = g_currentMission.aiSystem:getJobByIndex(i)

				if job ~= nil then
					element:getAttribute("text"):setText(job:getDescription())
				end
			end
		end

		self.updateTime = g_time + 1000
	end

	local hasChanged = false

	for i = 1, #self.statusMessages do
		local removeTime = self.statusMessages[1].removeTime

		if removeTime < g_time then
			table.remove(self.statusMessages, 1)

			hasChanged = true
		end
	end

	if hasChanged then
		self:updateStatusMessages()
	end
end

function InGameMenuAIFrame:setTargetPointHotspotPosition(localX, localY)
	local worldX, worldZ = self.ingameMap:localToWorldPos(localX, localY)

	self.aiTargetMapHotspot:setWorldPosition(worldX, worldZ)
end

function InGameMenuAIFrame:getCanCancelJob()
	return self.mode == InGameMenuAIFrame.MODE_OVERVIEW and not self:getIsPicking() and self.canCancel
end

function InGameMenuAIFrame:getCanCreateJob()
	return self.mode == InGameMenuAIFrame.MODE_OVERVIEW and not self:getIsPicking() and self.canCreateJob
end

function InGameMenuAIFrame:getCanGoTo()
	return self.mode == InGameMenuAIFrame.MODE_OVERVIEW and not self:getIsPicking() and self.canGoTo
end

function InGameMenuAIFrame:getCanStartJob()
	return self.mode == InGameMenuAIFrame.MODE_CREATE and not self:getIsPicking()
end

function InGameMenuAIFrame:getCanSkipJobTask()
	return self.mode == InGameMenuAIFrame.MODE_OVERVIEW and not self:getIsPicking() and self.canSkipTask
end

function InGameMenuAIFrame:getCanGoBack()
	return self.mode == InGameMenuAIFrame.MODE_OVERVIEW and not self:getIsPicking()
end

function InGameMenuAIFrame:showContextInput(canGoTo, canCreateJob, canCancel, canSkipTask)
	self.canGoTo = canGoTo
	self.canCreateJob = canCreateJob
	self.canCancel = canCancel
	self.canSkipTask = canSkipTask
end

function InGameMenuAIFrame:refreshContextInput()
	local hotspot = self.currentHotspot
	local vehicle = InGameMenuMapUtil.getHotspotVehicle(hotspot)
	local canGoTo = false
	local canCreateJob = false
	local canCancel = false
	local canSkipTask = false

	if vehicle ~= nil and g_currentMission.accessHandler:canPlayerAccess(vehicle) and vehicle.spec_aiJobVehicle ~= nil then
		canCancel = vehicle:getIsAIActive()

		if not canCancel then
			canGoTo = self.jobTypeInstances[AIJobType.GOTO]:getIsAvailableForVehicle(vehicle)
			canCreateJob = false

			for typeIndex, instance in pairs(self.jobTypeInstances) do
				if instance:getIsAvailableForVehicle(vehicle) then
					canCreateJob = true

					break
				end
			end
		else
			local job = vehicle:getJob()

			if job ~= nil and job:getCanSkipTask() then
				canSkipTask = true
			end
		end
	end

	self.limitReachedWarning:setVisible(not canCreateJob and g_currentMission.aiSystem:getAILimitedReached())
	self:showContextInput(canGoTo, canCreateJob, canCancel, canSkipTask)
end

function InGameMenuAIFrame:updateContextInputBarVisibility()
	local currentInputHelpMode = self.inputManager:getInputHelpMode()
	local isSelectAvailable = currentInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD and not GS_IS_MOBILE_VERSION
	local isPicking = self:getIsPicking()

	self.buttonSelectIngame:setVisible(isSelectAvailable and (isPicking or self.mode == InGameMenuAIFrame.MODE_OVERVIEW))
	self.buttonCancelJob:setVisible(self:getCanCancelJob())
	self.buttonGotoJob:setVisible(self:getCanGoTo())
	self.buttonCreateJob:setVisible(self:getCanCreateJob())
	self.buttonStartJob:setVisible(self:getCanStartJob())
	self.buttonBack:setVisible(self:getCanGoBack())
	self.buttonSkipTask:setVisible(self:getCanSkipJobTask())
	self.buttonCancel:setVisible(isPicking or self.mode == InGameMenuAIFrame.MODE_CREATE)

	local isPaused = g_currentMission.paused

	self.buttonCancelJob:setDisabled(isPaused)
	self.buttonGotoJob:setDisabled(isPaused)
	self.buttonCreateJob:setDisabled(isPaused)
	self.buttonStartJob:setDisabled(isPaused)
	self.buttonSkipTask:setDisabled(isPaused)
	self.buttonCancel:setDisabled(isPaused)
	self.buttonGotoJob.parent:invalidateLayout()
end

function InGameMenuAIFrame:setInGameMap(ingameMap)
	self.ingameMapBase = ingameMap

	self.ingameMap:setIngameMap(ingameMap)
end

function InGameMenuAIFrame:setTerrainSize(terrainSize)
	self.ingameMap:setTerrainSize(terrainSize)
end

function InGameMenuAIFrame:setMissionFruitTypes(missionFruitTypes)
	self.missionFruitTypes = missionFruitTypes
end

function InGameMenuAIFrame:setClient(client)
	self.client = client
end

function InGameMenuAIFrame:setPlayerFarm(playerFarm)
	self.playerFarm = playerFarm
end

function InGameMenuAIFrame:resetUIDeadzones()
	self.ingameMap:clearCursorDeadzones()
	self.ingameMap:addCursorDeadzone(unpack(self.staticUIDeadzone))
end

function InGameMenuAIFrame:setStaticUIDeadzone(screenX, screenY, width, height)
	self.staticUIDeadzone = {
		screenX,
		screenY,
		width,
		height
	}
end

function InGameMenuAIFrame:setupMapOverview()
	self.isMapOverviewInitialized = true
end

function InGameMenuAIFrame:setMapSelectionItem(hotspot)
	self.ingameMapBase:setSelectedHotspot(hotspot)

	local name, imageFilename, uvs, vehicle, farmId = nil
	local showContextBox = false

	g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)

	if hotspot ~= nil then
		vehicle = InGameMenuMapUtil.getHotspotVehicle(hotspot)

		if vehicle ~= nil then
			farmId = vehicle:getOwnerFarmId()
			name = vehicle:getName()
			imageFilename = vehicle:getImageFilename()
			uvs = Overlay.DEFAULT_UVS
			showContextBox = true
			self.currentHotspot = hotspot

			if vehicle.getJob ~= nil then
				local job = vehicle:getJob()

				if job ~= nil and job.getTarget ~= nil then
					local x, z, rot = job:getTarget()

					self.aiTargetMapHotspot:setWorldPosition(x, z)

					if rot ~= nil then
						self.aiTargetMapHotspot:setWorldRotation(rot + math.pi)
					end

					g_currentMission:addMapHotspot(self.aiTargetMapHotspot)
				end
			end
		elseif hotspot:isa(PlaceableHotspot) then
			name = hotspot:getName()

			if name ~= nil then
				local placeable = hotspot:getPlaceable()

				if placeable ~= nil then
					farmId = placeable:getOwnerFarmId()
					imageFilename = placeable:getImageFilename()
					uvs = Overlay.DEFAULT_UVS
				end

				showContextBox = true
				self.currentHotspot = hotspot

				self.ingameMap:setMapFocusToHotspot(hotspot)
			end
		end
	else
		self.currentHotspot = nil
	end

	if showContextBox then
		InGameMenuMapUtil.showContextBox(self.contextBox, hotspot, name, imageFilename, uvs, farmId)
	else
		InGameMenuMapUtil.hideContextBox(self.contextBox)
	end

	self:refreshContextInput()
end

function InGameMenuAIFrame:setMapSelectionPosition(worldX, worldZ)
	self:showContextInput(false, false, false, false)
end

function InGameMenuAIFrame:showActionMessage(text, locaKey)
	if text ~= nil then
		self.actionMessage:setVisible(true)
		self.actionMessage:setText(text)
	elseif locaKey ~= nil then
		self.actionMessage:setVisible(true)
		self.actionMessage:setLocaKey(locaKey)
	else
		self.actionMessage:setVisible(false)
	end
end

function InGameMenuAIFrame:generateJobTypes()
	for _, jobType in pairs(AIJobType) do
		self.jobTypeInstances[jobType] = g_currentMission.aiJobTypeManager:createJob(jobType)
	end
end

function InGameMenuAIFrame:startGoToJob(vehicle, destX, destZ, angle)
	local job = self.jobTypeInstances[AIJobType.GOTO]

	job.vehicleParameter:setVehicle(vehicle)
	job.positionAngleParameter:setPosition(destX, destZ)
	job.positionAngleParameter:setAngle(angle)
	job:setValues()

	local success, errorMessage = job:validate(g_currentMission.player.farmId)

	if success then
		local function callback(state)
			if state == AIJob.START_SUCCESS then
				self.jobTypeInstances[AIJobType.GOTO] = g_currentMission.aiJobTypeManager:createJob(AIJobType.GOTO)
			end
		end

		self:tryStartJob(job, g_currentMission.player.farmId, callback)

		return true
	else
		g_gui:showInfoDialog({
			dialogType = DialogElement.TYPE_ERROR,
			text = tostring(errorMessage)
		})

		return false
	end
end

function InGameMenuAIFrame:setActiveJobTypeSelection(jobTypeIndex)
	if self.currentJob == nil or jobTypeIndex ~= self.currentJob.jobTypeIndex then
		for i = #self.jobMenuLayout.elements, 1, -1 do
			self.jobMenuLayout.elements[i]:delete()
		end

		self.currentJob = g_currentMission.aiJobTypeManager:createJob(jobTypeIndex)
		local farmId = 1

		if g_currentMission.player ~= nil then
			farmId = g_currentMission.player.farmId
		end

		self.currentJob:applyCurrentState(self.currentJobVehicle, g_currentMission, farmId, false)

		self.currentJobElements = {}

		for _, group in ipairs(self.currentJob:getGroupedParameters()) do
			local titleElement = self.createTitleTemplate:clone(self.jobMenuLayout)

			titleElement:setText(group:getTitle())

			for _, item in ipairs(group:getParameters()) do
				local element = nil
				local parameterType = item:getType()

				if parameterType == AIParameterType.TEXT then
					element = self.createTextTemplate:clone(self.jobMenuLayout)
				elseif parameterType == AIParameterType.POSITION then
					element = self.createPositionTemplate:clone(self.jobMenuLayout)
				elseif parameterType == AIParameterType.POSITION_ANGLE then
					element = self.createPositionRotationTemplate:clone(self.jobMenuLayout)
				elseif parameterType == AIParameterType.SELECTOR or parameterType == AIParameterType.UNLOADING_STATION or parameterType == AIParameterType.LOADING_STATION or parameterType == AIParameterType.FILLTYPE then
					element = self.createMultiOptionTemplate:clone(self.jobMenuLayout)

					element:setDataSource(item)
				end

				FocusManager:loadElementFromCustomValues(element)

				element.aiParameter = item

				element:setDisabled(not item:getCanBeChanged())
				table.insert(self.currentJobElements, element)
			end
		end

		self:updateParameterValueTexts()
		self:validateParameters()
		self.jobMenuLayout:invalidateLayout()
		FocusManager:setFocus(self.jobTypeElement)
	end

	self:refreshContextInput()
end

function InGameMenuAIFrame:onAIVehicleStateChanged(isActive, vehicle)
	if vehicle ~= nil and self.currentHotspot ~= nil then
		local selectedVehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)

		if selectedVehicle == vehicle then
			self:refreshContextInput()
		end
	end
end

function InGameMenuAIFrame:onDrawPostIngameMap(element, ingameMap)
	if self.hideContentOverlay then
		return
	end
end

function InGameMenuAIFrame:onDrawPostIngameMapHotspots()
	InGameMenuMapUtil.updateContextBoxPosition(self.contextBox, self.currentHotspot)

	if self.aiTargetMapHotspot ~= nil then
		local icon = self.aiTargetMapHotspot.icon

		self.actionMessage:setAbsolutePosition(icon.x + icon.width * 0.5, icon.y + icon.height * 0.5)
	end
end

function InGameMenuAIFrame:onClickHotspot(element, hotspot)
	local worldX = hotspot.worldX
	local worldZ = hotspot.worldZ

	if self.isPickingLocation then
		self:executePickingCallback(true, worldX, worldZ)
	elseif self.isPickingRotation then
		local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2])

		self:executePickingCallback(true, angle)
	elseif self.mode == InGameMenuAIFrame.MODE_OVERVIEW then
		local category = hotspot:getCategory()

		if self.currentHotspot ~= hotspot and InGameMenuAIFrame.HOTSPOT_VALID_CATEGORIES[category] and hotspot ~= self.anywhereHotspot then
			self:setMapSelectionPosition(nil)
			self:setMapSelectionItem(hotspot)
		end
	end

	self:refreshContextInput()
end

function InGameMenuAIFrame:onClickMap(element, worldX, worldZ)
	if self.isPickingLocation then
		self:executePickingCallback(true, worldX, worldZ)
	elseif self.isPickingRotation then
		local angle = math.atan2(worldX - self.pickingRotationOrigin[1], worldZ - self.pickingRotationOrigin[2])

		self:executePickingCallback(true, angle)
	elseif self.mode == InGameMenuAIFrame.MODE_OVERVIEW then
		self:setMapSelectionItem(nil)
		self:setMapSelectionPosition(worldX, worldZ)
	end

	self:refreshContextInput()
end

function InGameMenuAIFrame:onVehiclesChanged(vehicle, wasAdded, isExitingGame)
	self:selectFirstHotspot()
end

function InGameMenuAIFrame:notifyPause()
	self:setMapSelectionItem(self.currentHotspot)
end

function InGameMenuAIFrame:selectFirstHotspot(allowedHotspots)
	if allowedHotspots == nil then
		allowedHotspots = InGameMenuAIFrame.HOTSPOT_VALID_CATEGORIES
	end

	local firstHotspot = self.ingameMapBase:cycleVisibleHotspot(nil, allowedHotspots, 1)

	self:setMapSelectionItem(firstHotspot)
end

function InGameMenuAIFrame:updateInputGlyphs()
	local moveActions, moveText = nil

	if self.lastInputHelpMode == GS_INPUT_HELP_MODE_GAMEPAD then
		moveText = self.moveCursorText
		moveActions = {
			InputAction.AXIS_MAP_SCROLL_LEFT_RIGHT,
			InputAction.AXIS_MAP_SCROLL_UP_DOWN
		}
	else
		moveText = self.panMapText
		moveActions = {
			InputAction.AXIS_LOOK_LEFTRIGHT_DRAG,
			InputAction.AXIS_LOOK_UPDOWN_DRAG
		}
	end

	self.mapMoveGlyph:setActions(moveActions, nil, , true, true)
	self.mapZoomGlyph:setActions({
		InputAction.AXIS_MAP_ZOOM_IN,
		InputAction.AXIS_MAP_ZOOM_OUT
	}, nil, , false, true)
	self.mapMoveGlyphText:setText(moveText)
	self.mapZoomGlyphText:setText(self.zoomText)
end

function InGameMenuAIFrame:validateParameters()
	local isValid = true
	local errorText = ""

	if self.currentJob ~= nil then
		self.currentJob:setValues()

		isValid, errorText = self.currentJob:validate(g_currentMission.player.farmId)

		self:updateWarnings()
	end

	self.errorMessage:setText(errorText)
	self.errorMessage:setVisible(not isValid)
end

function InGameMenuAIFrame:updateWarnings()
	for _, element in ipairs(self.currentJobElements) do
		local param = element.aiParameter
		local invalidElement = element:getDescendantByName("invalid")

		if invalidElement ~= nil then
			invalidElement:setVisible(not param:getIsValid())
		end
	end
end

function InGameMenuAIFrame:addStatusMessage(message)
	table.insert(self.statusMessages, {
		removeTime = g_time + 5000,
		text = message
	})
	self:updateStatusMessages()
end

function InGameMenuAIFrame:updateStatusMessages()
	local text = ""

	for _, message in ipairs(self.statusMessages) do
		text = text .. message.text .. "\n"
	end

	self.statusMessage:setText(text)
end

function InGameMenuAIFrame:registerInput()
	self:unregisterInput()
	self.inputManager:registerActionEvent(InputAction.MENU_ACTIVATE, self, self.onStartCancelJob, false, true, false, true)
	self.inputManager:registerActionEvent(InputAction.MENU_CANCEL, self, self.onStartGoToJob, false, true, false, true)
	self.inputManager:registerActionEvent(InputAction.MENU_ACCEPT, self, self.onCreateJob, false, true, false, true)
	self.inputManager:registerActionEvent(InputAction.MENU_EXTRA_1, self, self.onSkipJobTask, false, true, false, true)

	local _, switchVehicleId = self.inputManager:registerActionEvent(InputAction.SWITCH_VEHICLE, self, self.onSwitchVehicle, false, true, false, true, 1)
	self.eventIdSwitchVehicle = switchVehicleId
	local _, switchVehicleBackId = self.inputManager:registerActionEvent(InputAction.SWITCH_VEHICLE_BACK, self, self.onSwitchVehicle, false, true, false, true, -1)
	self.eventIdSwitchVehicleBack = switchVehicleBackId
end

function InGameMenuAIFrame:unregisterInput(customOnly)
	local list = customOnly and InGameMenuAIFrame.CLEAR_CLOSE_INPUT_ACTIONS or InGameMenuAIFrame.CLEAR_INPUT_ACTIONS

	for _, actionName in pairs(list) do
		self.inputManager:removeActionEventsByActionName(actionName)
	end
end

function InGameMenuAIFrame:hasMouseOverlapInFrame()
	return GuiUtils.checkOverlayOverlap(g_lastMousePosX, g_lastMousePosY, self.absPosition[1], self.absPosition[2], self.absSize[1], self.absSize[2])
end

function InGameMenuAIFrame:onZoomIn()
	if self:hasMouseOverlapInFrame() then
		self.ingameMap:zoom(1)
	end
end

function InGameMenuAIFrame:onZoomOut()
	if self:hasMouseOverlapInFrame() then
		self.ingameMap:zoom(-1)
	end
end

function InGameMenuAIFrame:onSwitchVehicle(_, _, direction)
	local allowedHotspots = InGameMenuAIFrame.HOTSPOT_SWITCH_CATEGORIES
	allowedHotspots[MapHotspot.CATEGORY_PLAYER] = g_currentMission.controlledVehicle ~= nil
	local newHotspot = self.ingameMapBase:cycleVisibleHotspot(self.currentHotspot, allowedHotspots, direction)

	self:setMapSelectionItem(newHotspot)
end

function InGameMenuAIFrame:onClickBack()
	if self:getCanGoBack() then
		self:onClickBackCallback()
	elseif self:getIsPicking() then
		self:executePickingCallback(false)
		self:refreshContextInput()
	elseif self.mode == InGameMenuAIFrame.MODE_CREATE then
		self.mode = InGameMenuAIFrame.MODE_OVERVIEW

		self:setJobMenuVisible(false)
		self:refreshContextInput()
	end
end

function InGameMenuAIFrame:onStartGoToJob()
	if not g_currentMission.paused and self:getCanGoTo() then
		self:tryStartGoToJob()
	end
end

function InGameMenuAIFrame:onStartCancelJob()
	if not g_currentMission.paused then
		if self:getCanCancelJob() then
			self:cancelJob()
		elseif self:getCanStartJob() then
			self:startJob()
		end
	end
end

function InGameMenuAIFrame:onSkipJobTask()
	if not g_currentMission.paused and self:getCanSkipJobTask() then
		self:skipCurrentTask()
	end
end

function InGameMenuAIFrame:onCreateJob()
	if self:getCanCreateJob() and not g_currentMission.paused then
		self:createJob()
	end
end

function InGameMenuAIFrame:updateParameterValueTexts()
	g_currentMission:removeMapHotspot(self.aiTargetMapHotspot)

	local addedPositionHotspot = false

	for _, element in ipairs(self.currentJobElements) do
		local parameter = element.aiParameter
		local parameterType = parameter:getType()

		if parameterType == AIParameterType.TEXT then
			local title = element:getDescendantByName("title")

			title:setText(parameter:getString())
		elseif parameterType == AIParameterType.POSITION or parameterType == AIParameterType.POSITION_ANGLE then
			element:setText(parameter:getString())

			if not addedPositionHotspot then
				g_currentMission:addMapHotspot(self.aiTargetMapHotspot)

				local x, z = parameter:getPosition()

				self.aiTargetMapHotspot:setWorldPosition(x, z)

				if parameterType == AIParameterType.POSITION_ANGLE then
					local angle = parameter:getAngle() + math.pi

					self.aiTargetMapHotspot:setWorldRotation(angle)
				end
			end
		else
			element:updateTitle()
		end
	end
end

function InGameMenuAIFrame:onClickMultiTextOptionParameter(index, element)
	if self.currentJob ~= nil then
		local parameter = element.aiParameter

		self.currentJob:onParameterValueChanged(parameter)
		self:updateParameterValueTexts()
	end

	self:validateParameters()
end

function InGameMenuAIFrame:onClickPositionParameter(element)
	local parameter = element.aiParameter

	self:startPickPosition(parameter, function (success, x, z)
		if success then
			element:setText(parameter:getString())
		end
	end)
end

function InGameMenuAIFrame:onClickPositionRotationParameter(element)
	local parameter = element.aiParameter

	self:startPickPositionAndRotation(parameter, function (success, x, z, angle)
		if success then
			element:setText(parameter:getString())
		end
	end)
end

function InGameMenuAIFrame:getNumberOfItemsInSection(list, section)
	if not self.isOpen then
		return 0
	end

	if g_currentMission ~= nil then
		local farmId = 1

		if g_currentMission.player ~= nil then
			farmId = g_currentMission.player.farmId
		end

		local count = 0

		for _, job in ipairs(g_currentMission.aiSystem:getActiveJobs()) do
			if job.startedFarmId == farmId then
				count = count + 1
			end
		end

		return count
	end

	return 0
end

function InGameMenuAIFrame:populateCellForItemInSection(list, section, index, cell)
	local count = 0
	local currentJob = nil
	local farmId = 1

	if g_currentMission.player ~= nil then
		farmId = g_currentMission.player.farmId
	end

	for _, job in ipairs(g_currentMission.aiSystem:getActiveJobs()) do
		if job.startedFarmId == farmId then
			count = count + 1

			if count == index then
				currentJob = job

				break
			end
		end
	end

	if currentJob ~= nil then
		cell:getAttribute("text"):setText(currentJob:getDescription())
		cell:getAttribute("title"):setText(currentJob:getTitle())
		cell:getAttribute("helper"):setText(currentJob:getHelperName())
	end
end

function InGameMenuAIFrame:onListSelectionChanged(list, section, index)
	local job = g_currentMission.aiSystem:getJobByIndex(index)

	if job ~= nil and job.vehicleParameter then
		local vehicle = job.vehicleParameter:getVehicle()

		if vehicle ~= nil then
			local hotspot = vehicle:getMapHotspot()

			self:setMapSelectionItem(hotspot)
		end
	end
end

function InGameMenuAIFrame:onJobTypeChanged(index)
	local jobTypeIndex = self.currentJobTypes[index]

	self:setActiveJobTypeSelection(jobTypeIndex)
end

function InGameMenuAIFrame:onAIJobStarted(job, farmId)
	self.activeWorkerList:reloadData()
end

function InGameMenuAIFrame:onAIJobRemoved(jobId)
	self.activeWorkerList:reloadData()
end

function InGameMenuAIFrame:onAIJobStopped(job, aiMessage)
	if aiMessage ~= nil and job ~= nil and g_currentMission.player ~= nil and job.startedFarmId == g_currentMission.player.farmId then
		local helperName = job:getHelperName()
		local text = aiMessage:getMessage()

		self:addStatusMessage(string.format(text, helperName or "Unknown"))
	end
end

function InGameMenuAIFrame:getIsPicking()
	return self.isPickingRotation or self.isPickingLocation
end

function InGameMenuAIFrame:executePickingCallback(...)
	self.ingameMap:setHotspotSelectionActive(true)

	self.isPickingLocation = false
	self.isPickingRotation = false
	local cb = self.pickingCallback
	self.pickingCallback = nil

	if cb ~= nil then
		cb(...)
	end
end

function InGameMenuAIFrame:startPickPosition(parameter, callback)
	self.ingameMap:setHotspotSelectionActive(false)
	self.ingameMap:setIsCursorAvailable(false)

	self.isPickingLocation = true

	self:showActionMessage(nil, "ui_ai_pickTargetLocation")
	g_currentMission:addMapHotspot(self.aiTargetMapHotspot)

	function self.pickingCallback(success, x, z)
		self:showActionMessage()
		self.ingameMap:setIsCursorAvailable(true)

		if success then
			parameter:setValue(x, z)
			self.aiTargetMapHotspot:setWorldPosition(x, z)
		end

		callback(success, x, z, parameter)
		self:validateParameters()
	end
end

function InGameMenuAIFrame:startPickPositionAndRotation(parameter, callback)
	self.isPickingLocation = true

	self.ingameMap:setHotspotSelectionActive(false)
	self.ingameMap:setIsCursorAvailable(false)
	self:showActionMessage(nil, "ui_ai_pickTargetLocation")
	g_currentMission:addMapHotspot(self.aiTargetMapHotspot)

	function self.pickingCallback(success, x, z)
		self:showActionMessage()
		self.ingameMap:setIsCursorAvailable(true)

		if success then
			self.ingameMap:setHotspotSelectionActive(false)
			self.ingameMap:setIsCursorAvailable(false)
			self.aiTargetMapHotspot:setWorldPosition(x, z)

			self.isPickingRotation = true
			self.pickingRotationOrigin = {
				x,
				z
			}
			self.pickingRotationSnapAngle = parameter:getSnappingAngle()

			self:showActionMessage(nil, "ui_ai_pickTargetRotation")

			function self.pickingCallback(successRotation, angle)
				self:showActionMessage()
				self.ingameMap:setIsCursorAvailable(true)

				if successRotation then
					parameter:setPosition(x, z)
					parameter:setAngle(angle)

					local convertedAngle = parameter:getAngle()

					self.aiTargetMapHotspot:setWorldRotation(convertedAngle + math.pi)
					callback(true, x, z, angle)
				else
					callback(false, x, z, nil)
				end

				self:validateParameters()
			end
		else
			callback(false, nil, , )
		end

		self:validateParameters()
	end
end

function InGameMenuAIFrame:setJobMenuVisible(isVisible)
	g_inputBinding:setActionEventActive(self.eventIdSwitchVehicle, not isVisible)
	g_inputBinding:setActionEventActive(self.eventIdSwitchVehicleBack, not isVisible)

	local eventIds = g_gui:getActionEventIds(InputAction.MENU_AXIS_LEFT_RIGHT)

	if eventIds ~= nil then
		for _, eventId in ipairs(eventIds) do
			g_inputBinding:setActionEventActive(eventId, isVisible)
		end
	end

	self.errorMessage:setText("")
	self.actionMessage:setText("")
	self.jobMenu:setVisible(isVisible)
	self.jobOverview:setVisible(not isVisible)
end

function InGameMenuAIFrame:createJob()
	local vehicle = self.currentHotspot:getVehicle()

	if vehicle ~= nil then
		self.currentJobTypes = {}
		local currentJobTypesTexts = {}
		local currentJobTypeIndex, currentIndex, lastJob = nil

		if vehicle.getLastJob ~= nil then
			lastJob = vehicle:getLastJob()
		end

		for name, index in pairs(AIJobType) do
			if self.jobTypeInstances[index]:getIsAvailableForVehicle(vehicle) then
				table.insert(self.currentJobTypes, index)
				table.insert(currentJobTypesTexts, g_currentMission.aiJobTypeManager:getJobTypeByIndex(index).title)

				if currentJobTypeIndex == nil or lastJob ~= nil and lastJob.class == self.jobTypeInstances[index].class then
					currentJobTypeIndex = index
					currentIndex = #self.currentJobTypes
				end
			end
		end

		if #self.currentJobTypes == 0 then
			log("Error: vehicle has no support for any jobs, so button should not have been shown!")

			return
		end

		self.jobTypeElement:setTexts(currentJobTypesTexts)
		self.jobTypeElement:setState(currentIndex or 1)

		self.mode = InGameMenuAIFrame.MODE_CREATE
		self.currentJobVehicle = vehicle
		self.currentJob = nil

		self:setJobMenuVisible(true)
		self:setActiveJobTypeSelection(currentJobTypeIndex)
	end
end

function InGameMenuAIFrame:tryStartGoToJob()
	if self.currentHotspot ~= nil then
		local vehicle = self.currentHotspot:getVehicle()

		if vehicle ~= nil then
			local job = self.jobTypeInstances[AIJobType.GOTO]

			self:startPickPositionAndRotation(job.positionAngleParameter, function (success, x, z, angle)
				if success then
					self:startGoToJob(vehicle, x, z, angle)
				end

				self:refreshContextInput()
			end)
		end
	end
end

function InGameMenuAIFrame:startJob()
	if self.startJobPending then
		return
	end

	self.currentJob:setValues()

	local success, errorMessage = self.currentJob:validate(g_currentMission.player.farmId)

	if success then
		local function callback(state)
			if state == AIJob.START_SUCCESS then
				self.mode = InGameMenuAIFrame.MODE_OVERVIEW
				self.currentJob = nil

				self:setJobMenuVisible(false)
				self:refreshContextInput()
			end
		end

		self:tryStartJob(self.currentJob, g_currentMission.player.farmId, callback)
	else
		g_gui:showInfoDialog({
			dialogType = DialogElement.TYPE_ERROR,
			text = tostring(errorMessage)
		})
		self:updateWarnings()
	end
end

function InGameMenuAIFrame:cancelJob()
	local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)

	if vehicle ~= nil and vehicle:getIsAIActive() then
		vehicle:stopCurrentAIJob(AIMessageSuccessStoppedByUser.new())
	end
end

function InGameMenuAIFrame:tryStartJob(job, farmId, callback)
	self.startJobPending = true

	g_messageCenter:subscribe(AIJobStartRequestEvent, self.onStartedJob, self, {
		callback
	})
	g_client:getServerConnection():sendEvent(AIJobStartRequestEvent.new(job, farmId))
end

function InGameMenuAIFrame:onStartedJob(args, state, jobTypeIndex)
	local callback = args[1]
	self.startJobPending = false

	g_messageCenter:unsubscribe(AIJobStartRequestEvent, self)

	if state ~= AIJob.START_SUCCESS then
		local jobType = g_currentMission.aiJobTypeManager:getJobTypeByIndex(jobTypeIndex)
		local text = jobType.classObject.getIsStartErrorText(state)

		g_gui:showInfoDialog({
			text = text,
			dialogType = DialogElement.TYPE_INFO
		})
	end

	callback(state)
end

function InGameMenuAIFrame:skipCurrentTask()
	local vehicle = InGameMenuMapUtil.getHotspotVehicle(self.currentHotspot)

	if vehicle ~= nil and vehicle:getIsAIActive() then
		local job = vehicle:getJob()

		if job ~= nil then
			if job:getCanSkipTask() then
				vehicle:skipCurrentTask()
			else
				self:refreshContextInput()
			end
		end
	end
end

InGameMenuAIFrame.HOTSPOT_VALID_CATEGORIES = {
	[MapHotspot.CATEGORY_STEERABLE] = true,
	[MapHotspot.CATEGORY_COMBINE] = true,
	[MapHotspot.CATEGORY_TRAILER] = true,
	[MapHotspot.CATEGORY_TOOL] = true,
	[MapHotspot.CATEGORY_OTHER] = false,
	[MapHotspot.CATEGORY_AI] = true,
	[MapHotspot.CATEGORY_PLAYER] = true
}
InGameMenuAIFrame.HOTSPOT_SWITCH_CATEGORIES = {
	[MapHotspot.CATEGORY_STEERABLE] = true,
	[MapHotspot.CATEGORY_COMBINE] = true,
	[MapHotspot.CATEGORY_TRAILER] = true,
	[MapHotspot.CATEGORY_TOOL] = true,
	[MapHotspot.CATEGORY_OTHER] = false,
	[MapHotspot.CATEGORY_AI] = true,
	[MapHotspot.CATEGORY_PLAYER] = true
}
InGameMenuAIFrame.GLYPH_SIZE = {
	36,
	36
}
InGameMenuAIFrame.GLYPH_TEXT_SIZE = 20
InGameMenuAIFrame.GLYPH_COLOR = {
	1,
	1,
	1,
	1
}
InGameMenuAIFrame.L10N_SYMBOL = {
	DIALOG_VEHICLE_RESET_DONE = "ui_vehicleResetDone",
	DIALOG_VEHICLE_IN_USE = "shop_messageReturnVehicleInUse",
	REMOVE_MARKER = "action_untag",
	SWITCH_FARMLANDS = "ui_ingameMenuMapFarmlands",
	VEHICLE_RESET = "button_reset",
	DIALOG_BUY_FARMLAND_TITLE = "shop_messageBuyFarmlandTitle",
	DIALOG_VEHICLE_RESET_CONFIRM = "ui_wantToResetVehicleText",
	MAP_SELECTOR_GROWTH_STATES = "ui_mapOverviewGrowth",
	SWITCH_OVERVIEW = "ui_ingameMenuMapOverview",
	DIALOG_SELL_FARMLAND_TITLE = "shop_messageSellFarmlandTitle",
	INPUT_ZOOM_MAP = "ui_ingameMenuMapZoom",
	MOBILE_BUY_FIELD_TEXT = "ui_mobile_buyFieldDialogText",
	INPUT_PAN_MAP = "ui_ingameMenuMapPan",
	SET_MARKER = "action_tag",
	BUY_FIELD_TITLE = "shop_messageBuyFieldTitle",
	DIALOG_BUY_FARMLAND = "shop_messageBuyFarmlandText",
	DIALOG_SELL_FARMLAND = "shop_messageSellFarmlandText",
	DIALOG_VEHICLE_NO_PERMISSION = "shop_messageNoPermissionGeneral",
	MAP_SELECTOR_FRUIT_TYPES = "ui_mapOverviewFruitTypes",
	MAP_SELECTOR_SOIL_STATES = "ui_mapOverviewSoil",
	DIALOG_CANNOT_SELL_WTIH_PLACEABLES = "shop_messageCannotSellFarmlandWithPlaceables",
	DIALOG_VEHICLE_RESET_FAILED = "ui_vehicleResetFailed",
	DIALOG_BUY_FARMLAND_NOT_ENOUGH_MONEY = "shop_messageNotEnoughMoneyToBuyFarmland",
	MOBILE_BUY_FIELD_TEXT_COINS = "ui_mobile_buyFieldDialogText_buyCoins",
	INPUT_MOVE_CURSOR = "ui_ingameMenuMapMoveCursor",
	MAP_PAGES = {
		"ui_map_crops",
		"ui_map_growth",
		"ui_map_soil"
	}
}
InGameMenuAIFrame.PROFILE = {
	MONEY_VALUE_NEGATIVE = "ingameMenuMapMoneyValueNegative",
	MONEY_VALUE_NEUTRAL = "ingameMenuMapMoneyValue"
}
