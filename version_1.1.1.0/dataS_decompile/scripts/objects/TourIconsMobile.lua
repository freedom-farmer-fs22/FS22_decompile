TourIconsMobile = {}
local TourIconsMobile_mt = Class(TourIconsMobile)

function TourIconsMobile:onCreate(id)
	local tourIcons = TourIconsMobile.new(id)

	g_currentMission:addUpdateable(tourIcons)

	g_currentMission.tourIconsBase = tourIcons
end

function TourIconsMobile.new(id)
	local self = {}

	setmetatable(self, TourIconsMobile_mt)

	self.me = id
	local num = getNumOfChildren(self.me)
	self.tourIcons = {}

	for i = 0, num - 1 do
		local tourIconTriggerId = getChildAt(self.me, i)
		local tourIconId = getChildAt(tourIconTriggerId, 0)

		addTrigger(tourIconTriggerId, "triggerCallback", self)
		setVisibility(tourIconId, false)

		local tourIcon = {
			tourIconTriggerId = tourIconTriggerId,
			tourIconId = tourIconId
		}

		table.insert(self.tourIcons, tourIcon)
	end

	self.visible = false
	self.mapHotspot = nil
	self.currentTourIconNumber = 1
	self.alpha = 0.25
	self.alphaDirection = 1
	self.startTourDialog = false
	self.startTourDialogDelay = 0
	self.permanentMessageDelay = 0
	self.isPaused = false
	self.pauseTime = 0
	self.soldStuffAtGrainElevator = false
	local plowLevelMaxValue = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.PLOW_LEVEL)
	local limeLevelMaxValue = g_currentMission.fieldGroundSystem:getMaxValue(FieldDensityMap.LIME_LEVEL)
	self.plowLevelMaxValue = plowLevelMaxValue
	self.limeLevelMaxValue = limeLevelMaxValue
	_, self.permanentTextSize = getNormalizedScreenValues(0, 28)

	return self
end

function TourIconsMobile:delete()
	g_currentMission:removeUpdateable(self)

	for _, tourIcon in pairs(self.tourIcons) do
		removeTrigger(tourIcon.tourIconTriggerId)
	end

	if self.me ~= 0 then
		delete(self.me)

		self.me = 0
	end
end

function TourIconsMobile:showTourDialog()
	g_gui:showYesNoDialog({
		title = "",
		text = g_i18n:getText("tour_text_start"),
		callback = self.reactToDialog,
		target = self
	})
end

function TourIconsMobile:reactToDialog(yes)
	if yes then
		self.visible = true

		self:activateNextIcon()

		if g_currentMission.helpIconsBase ~= nil then
			g_currentMission.helpIconsBase:showHelpIcons(false, true)
		end

		g_messageCenter:publish(MessageType.MISSION_TOUR_STARTED)
	else
		self.visible = false

		g_gui:showInfoDialog({
			title = "",
			text = g_i18n:getText("tour_mobile_abort")
		})
		self:delete()
	end
end

function TourIconsMobile:update(dt)
	if not g_currentMission.missionInfo.isValid and g_server ~= nil and self.initDone == nil and g_currentMission:getIsTourSupported() then
		self.initDone = true

		g_currentMission:fadeScreen(-1, 3000, function ()
			self.canStart = true
		end, self)

		local field = g_fieldManager:getFieldByIndex(2)
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.WHEAT)

		for i = 1, table.getn(field.maxFieldStatusPartitions) do
			g_fieldManager:setFieldPartitionStatus(field, field.maxFieldStatusPartitions, i, fruitDesc.index, FieldManager.FIELDSTATE_GROWING, fruitDesc.maxHarvestingGrowthState, 3, true, self.plowLevelMaxValue, 0, self.limeLevelMaxValue)
		end

		local field = g_fieldManager:getFieldByIndex(1)
		local fruitDesc = g_fruitTypeManager:getFruitTypeByIndex(FruitType.CANOLA)

		for i = 1, table.getn(field.maxFieldStatusPartitions) do
			g_fieldManager:setFieldPartitionStatus(field, field.maxFieldStatusPartitions, i, fruitDesc.index, FieldManager.FIELDSTATE_HARVESTED, 0, 0, false, self.plowLevelMaxValue, 0, self.limeLevelMaxValue)
		end

		local field = g_fieldManager:getFieldByIndex(3)

		for i = 1, table.getn(field.maxFieldStatusPartitions) do
			g_fieldManager:setFieldPartitionStatus(field, field.maxFieldStatusPartitions, i, nil, FieldManager.FIELDSTATE_CULTIVATED, 0, 0, false, self.plowLevelMaxValue, 0, self.limeLevelMaxValue)
		end
	end

	if self.startTourDialog and self.canStart then
		self.startTourDialogDelay = self.startTourDialogDelay - dt

		if self.startTourDialogDelay < 0 then
			self.startTourDialog = false

			self:showTourDialog()
		end
	end

	if g_gui:getIsGuiVisible() then
		return
	elseif self.queuedMessage ~= nil then
		g_currentMission.hud.ingameMap:toggleSize(IngameMapMobile.STATE_HIDDEN, true)
		g_gui:showInfoDialog(self.queuedMessage)

		self.queuedMessage = nil

		return
	end

	if self.isPaused then
		if self.pauseTime > 0 then
			self.pauseTime = self.pauseTime - dt
		else
			self.pauseTime = 0
			self.isPaused = false

			self:activateNextIcon()
		end
	end

	if self.visible and not self.isPaused then
		if self.currentTourIconNumber == 2 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourCombine and g_currentMission.tourVehicles.tourCombine:getActionControllerDirection() < 0 then
				self.pauseTime = 2000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber == 4 then
			if g_currentMission.tourVehicles.tourCombine:getIsTurnedOn() and g_currentMission.tourVehicles.tourCombine:getIsAIActive() then
				self.pauseTime = 1000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber == 5 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourTractor1 then
				self.pauseTime = 1000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber == 6 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourTractor1 and g_currentMission.tourVehicles.tourTractor1:getActionControllerDirection() < 0 then
				self.pauseTime = 1000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber == 8 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourTractor2 then
				self.pauseTime = 1000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber == 9 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourTractor2 and g_currentMission.tourVehicles.tourSowingMachine.rootVehicle == g_currentMission.tourVehicles.tourTractor2 then
				self.pauseTime = 1000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber == 11 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourTractor1 then
				self.pauseTime = 1000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber == 13 then
			if g_currentMission.tourVehicles.tourCultivator.rootVehicle == g_currentMission.tourVehicles.tourCultivator then
				self.pauseTime = 1000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber == 14 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourTractor1 and g_currentMission.tourVehicles.tourTrailer.rootVehicle == g_currentMission.tourVehicles.tourTractor1 then
				self.pauseTime = 1000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber == 15 then
			if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourTractor1 and g_currentMission.tourVehicles.tourTrailer:getFillUnitFillLevel(1) > 800 then
				self.pauseTime = 1000
				self.isPaused = true
			end
		elseif self.currentTourIconNumber == 17 and g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle == g_currentMission.tourVehicles.tourTractor1 and g_currentMission.tourVehicles.tourTrailer:getFillUnitFillLevel(1) <= 2 then
			self.pauseTime = 1000
			self.isPaused = true
		end
	end
end

function TourIconsMobile:makeIconVisible(tourIconId)
	setVisibility(tourIconId, true)

	local x, y, z = getWorldTranslation(tourIconId)

	if self.mapHotspot == nil then
		self.mapHotspot = TourHotspot.new()

		g_currentMission:addMapHotspot(self.mapHotspot)
	end

	self.mapHotspot:setWorldPosition(x, z)

	local h = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)

	if h < y then
		g_currentMission:setMapTargetHotspot(self.mapHotspot)

		g_currentMission.disableMapTargetHotspotHiding = true
	else
		g_currentMission:setMapTargetHotspot(nil)

		g_currentMission.disableMapTargetHotspotHiding = false
	end
end

function TourIconsMobile:triggerCallback(triggerId, otherId, onEnter, onLeave, onStay)
	local object = g_currentMission:getNodeObject(otherId)

	if object ~= nil and object:isa(Vehicle) and onEnter and self.tourIcons[self.currentTourIconNumber] ~= nil and self.tourIcons[self.currentTourIconNumber].tourIconTriggerId == triggerId and getVisibility(self.tourIcons[self.currentTourIconNumber].tourIconId) then
		self:activateNextIcon()
	end
end

function TourIconsMobile:activateNextIcon()
	for i = 1, self.currentTourIconNumber do
		local tourIcon = self.tourIcons[i]

		if getVisibility(tourIcon.tourIconId) then
			setVisibility(tourIcon.tourIconId, false)
			setCollisionMask(tourIcon.tourIconTriggerId, 0)
		end
	end

	if self.tourIcons[self.currentTourIconNumber + 1] ~= nil then
		self:makeIconVisible(self.tourIcons[self.currentTourIconNumber + 1].tourIconId)
	else
		if self.mapHotspot ~= nil then
			g_currentMission:removeMapHotspot(self.mapHotspot)
			self.mapHotspot:delete()

			self.mapHotspot = nil
		end

		if g_gameSettings:getValue("showHelpIcons") and g_currentMission.helpIconsBase ~= nil then
			g_currentMission.helpIconsBase:showHelpIcons(true, true)
		end

		self.visible = false

		g_messageCenter:publish(MessageType.MISSION_TOUR_FINISHED)
		self:delete()
	end

	local title = g_i18n:getText("ui_tour")
	local text = ""
	local controls = {}

	if self.currentTourIconNumber == 1 then
		text = g_i18n:getText("tour_mobile_part01_activate")
	elseif self.currentTourIconNumber == 2 then
		text = g_i18n:getText("tour_mobile_part01_drive")
	elseif self.currentTourIconNumber == 3 then
		text = g_i18n:getText("tour_mobile_part01_helper")
	elseif self.currentTourIconNumber == 4 then
		text = g_i18n:getText("tour_mobile_part01_finished")
	elseif self.currentTourIconNumber == 5 then
		text = g_i18n:getText("tour_mobile_part02_activate")
	elseif self.currentTourIconNumber == 6 then
		text = g_i18n:getText("tour_mobile_part02_drive")
	elseif self.currentTourIconNumber == 7 then
		text = g_i18n:getText("tour_mobile_part02_finished")
	elseif self.currentTourIconNumber == 8 then
		text = g_i18n:getText("tour_mobile_part03_attach")
	elseif self.currentTourIconNumber == 9 then
		text = g_i18n:getText("tour_mobile_part03_activateDrive")
	elseif self.currentTourIconNumber == 10 then
		text = g_i18n:getText("tour_mobile_part03_finished")
	elseif self.currentTourIconNumber == 11 then
		text = g_i18n:getText("tour_mobile_part04_driveToYard")
	elseif self.currentTourIconNumber == 12 then
		text = g_i18n:getText("tour_mobile_part04_detach")
	elseif self.currentTourIconNumber == 13 then
		text = g_i18n:getText("tour_mobile_part04_attachTrailer")
	elseif self.currentTourIconNumber == 14 then
		text = g_i18n:getText("tour_mobile_part04_driveToHarvester")
	elseif self.currentTourIconNumber == 15 then
		text = g_i18n:getText("tour_mobile_part04_driveToSellpoint")
	elseif self.currentTourIconNumber == 16 then
		text = g_i18n:getText("tour_mobile_part04_Unload")
	elseif self.currentTourIconNumber == 17 then
		text = g_i18n:getText("tour_mobile_end")
	end

	if g_currentMission.controlledVehicle ~= nil and g_currentMission.controlledVehicle.setCruiseControlState ~= nil then
		g_currentMission.controlledVehicle:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
	end

	if g_gui:getIsGuiVisible() then
		self.queuedMessage = {
			title = title,
			text = text
		}
	else
		g_currentMission.hud.ingameMap:toggleSize(IngameMapMobile.STATE_HIDDEN, true)
		g_gui:showInfoDialog({
			title = title,
			text = text
		})
	end

	self.currentTourIconNumber = self.currentTourIconNumber + 1
	self.permanentMessageDelay = 250
end
