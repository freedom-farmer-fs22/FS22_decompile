GuidedTour = {
	DISABLED_LANGUAGES = {}
}
GuidedTour.DISABLED_LANGUAGES.fi = true
GuidedTour.DISABLED_LANGUAGES.sv = true
GuidedTour.DISABLED_LANGUAGES.da = true
GuidedTour.DISABLED_LANGUAGES.no = true
local GuidedTour_mt = Class(GuidedTour)

function GuidedTour.new(mission, customMt)
	local self = setmetatable({}, customMt or GuidedTour_mt)
	self.mission = mission
	self.isLoaded = false
	self.isRunning = false
	self.vehicles = {}
	self.iconFilename = nil
	self.steps = {}

	return self
end

function GuidedTour:delete()
	g_messageCenter:unsubscribeAll(self)
	self:deleteIcon()
	self:deleteHotspot()
end

function GuidedTour:loadMapData(mapXmlFile, missionInfo, baseDirectory)
	self.missionInfo = missionInfo
	local filename = getXMLString(mapXmlFile, "map.guidedTour#filename")

	if filename == nil then
		self.missionInfo.guidedTourActive = false

		return
	end

	filename = Utils.getFilename(filename, baseDirectory)
	local xmlFile = XMLFile.load("guidedTour", filename)

	if xmlFile == nil then
		self.missionInfo.guidedTourActive = false

		return
	end

	local iconFilename = xmlFile:getString("guidedTour.icon#filename")

	if iconFilename ~= nil then
		self.iconFilename = Utils.getFilename(iconFilename, baseDirectory)
	end

	if xmlFile:hasProperty("guidedTour.redirect") then
		local redirectText = xmlFile:getString("guidedTour.redirect#text")

		if redirectText == nil then
			Logging.warning("Guided tour redirect configuration is missing text attribute.")
		else
			self.redirectText = g_i18n:convertText(redirectText)
		end
	end

	xmlFile:iterate("guidedTour.step", function (index, key)
		local step = {
			activation = {}
		}

		if xmlFile:hasProperty(key .. ".activation") then
			local iconPosition = xmlFile:getString(key .. ".activation.icon#position")

			if iconPosition ~= nil then
				local icon = {
					position = string.getVectorN(iconPosition, 2),
					targetIndicator = xmlFile:getBool(key .. ".activation.icon#targetIndicator", false)
				}
				step.activation.icon = icon
			end
		end

		if xmlFile:hasProperty(key .. ".dialog") then
			local dialog = {}
			step.dialog = dialog
			dialog.text = g_i18n:convertText(xmlFile:getString(key .. ".dialog#text"))
			dialog.inputs = {}

			xmlFile:iterate(key .. ".dialog.input", function (_, inputKey)
				local input = {
					action = xmlFile:getString(inputKey .. "#name"),
					action2 = xmlFile:getString(inputKey .. "#name2"),
					text = xmlFile:getString(inputKey .. "#text"),
					keyboardOnly = xmlFile:getBool(inputKey .. "#keyboardOnly", false),
					gamepadOnly = xmlFile:getBool(inputKey .. "#gamepadOnly", false)
				}

				table.insert(dialog.inputs, input)
			end)
		end

		if xmlFile:hasProperty(key .. ".mapHotspot") then
			step.mapHotspot = {
				vehicle = xmlFile:getString(key .. ".mapHotspot#vehicle"),
				targetIndicator = xmlFile:getBool(key .. ".mapHotspot#targetIndicator")
			}
			local position = xmlFile:getString(key .. ".mapHotspot#position")

			if position ~= nil then
				step.mapHotspot.position = string.getVectorN(position, 2)
			else
				step.mapHotspot.position = {
					0,
					0
				}
			end
		end

		if xmlFile:hasProperty(key .. ".goal") then
			local goal = {
				checks = {}
			}
			step.goal = goal

			xmlFile:iterate(key .. ".goal.check", function (_, checkKey)
				local check = {
					name = xmlFile:getString(checkKey .. "#name"),
					vehicle = xmlFile:getString(checkKey .. "#vehicle"),
					toVehicle = xmlFile:getString(checkKey .. "#toVehicle"),
					fillUnitIndex = xmlFile:getInt(checkKey .. "#fillUnit"),
					fillLevel = xmlFile:getInt(checkKey .. "#fillLevel")
				}

				table.insert(goal.checks, check)
			end)
		end

		table.insert(self.steps, step)
	end)

	self.isLoaded = true

	if self.mission.missionDynamicInfo.isMultiplayer then
		self.missionInfo.guidedTourActive = false
	end

	if not self.mission:getIsTourSupported() then
		self.missionInfo.guidedTourActive = false
	end

	if g_isPresentationVersion and not g_isPresentationVersionIsTourEnabled then
		self.missionInfo.guidedTourActive = false
	end

	if GuidedTour.DISABLED_LANGUAGES[g_languageShort] ~= nil then
		self.missionInfo.guidedTourActive = false
	end
end

function GuidedTour:addVehicle(vehicle, name)
	self.vehicles[name] = vehicle
end

function GuidedTour:removeVehicle(name)
	self.vehicles[name] = nil

	if self.isRunning then
		self:onFinished()
	end
end

function GuidedTour:onStarted()
	self.isRunning = true

	self:loadHotspot()

	if self.mission.helpIconsBase ~= nil then
		self.mission.helpIconsBase:showHelpIcons(false, true)
	end

	self:loadIcon()
end

function GuidedTour:onFinished()
	self.vehicles = {}

	self:deleteIcon()
	self:deleteHotspot()

	self.isRunning = false
	self.missionInfo.guidedTourActive = false

	if g_gameSettings:getValue("showHelpIcons") and self.mission.helpIconsBase ~= nil then
		self.mission.helpIconsBase:showHelpIcons(true, true)
	end

	g_messageCenter:publish(MessageType.MISSION_TOUR_FINISHED)
end

function GuidedTour:update(dt)
	if self.redirectText ~= nil then
		if self.missionInfo.guidedTourActive and not g_gui:getIsGuiVisible() and self.missionInfo.guidedTourStep == 0 then
			g_gui:showInfoDialog({
				title = "",
				text = self.redirectText
			})

			self.missionInfo.guidedTourStep = 1
		end

		return
	end

	if not self.isRunning and self.missionInfo.guidedTourActive and not g_gui:getIsGuiVisible() then
		if self.missionInfo.guidedTourStep == 0 then
			g_gui:showYesNoDialog({
				title = "",
				text = g_i18n:getText("tour_text_start"),
				callback = self.onReactToDialog,
				target = self
			})
		else
			self:onStarted()
		end
	end

	if self.isRunning and self.goalPredicate ~= nil then
		local goalAchieved = self.goalPredicate()

		if goalAchieved then
			self.goalAchievedCallback()
		end
	end
end

function GuidedTour:onReactToDialog(yes)
	if yes then
		self:onStarted()
	else
		self.missionInfo.guidedTourActive = false

		g_currentMission.hud:showInGameMessage("", g_i18n:getText("tour_text_abort"), -1)
	end
end

function GuidedTour:onIconTrigger(_, _, onEnter)
	if onEnter and self.iconTriggerCallback ~= nil then
		self.iconTriggerCallback()
	end
end

function GuidedTour:onMessageClosed()
	if self.messageClosedCallback ~= nil then
		self.messageClosedCallback()
	end
end

function GuidedTour:runStep(index, fromTrigger, fromDialog)
	if index == 0 then
		index = 1
	end

	if index < self.missionInfo.guidedTourStep then
		return
	end

	if index > #self.steps then
		self:onFinished()

		return
	end

	self.missionInfo.guidedTourStep = index
	local step = self.steps[index]

	if step.activation ~= nil and step.activation.icon ~= nil and not fromTrigger then
		local icon = step.activation.icon
		local x, z = unpack(icon.position)

		self:setIcon(true, x, z, step.activation.icon.targetIndicator)

		function self.iconTriggerCallback()
			self.iconTriggerCallback = nil

			self:runStep(index, true, false)
		end

		return
	else
		self:setIcon(false)
	end

	if step.mapHotspot ~= nil then
		local x, z = unpack(step.mapHotspot.position)

		self:setHotspot(true, step.mapHotspot.targetIndicator, x, z, step.mapHotspot.vehicle)
	else
		self:setTargetIndicator(false)
	end

	if step.dialog ~= nil and not fromDialog then
		local controls = {}
		local useGamepadButtons = g_inputBinding:getInputHelpMode() == GS_INPUT_HELP_MODE_GAMEPAD

		for _, input in ipairs(step.dialog.inputs) do
			local action1 = InputAction[input.action]
			local action2 = input.action2 ~= nil and InputAction[input.action2] or nil

			if (not input.keyboardOnly or not useGamepadButtons) and (not input.gamepadOnly or useGamepadButtons) then
				table.insert(controls, g_inputDisplayManager:getControllerSymbolOverlays(action1, action2, g_i18n:convertText(input.text)))
			end
		end

		if self.mission.controlledVehicle ~= nil and self.mission.controlledVehicle.setCruiseControlState ~= nil then
			self.mission.controlledVehicle:setCruiseControlState(Drivable.CRUISECONTROL_STATE_OFF)
		end

		function self.messageClosedCallback()
			self.messageClosedCallback = nil

			self:runStep(index, fromTrigger, true)
		end

		self.mission.hud:showInGameMessage(g_i18n:getText("ui_tour"), g_i18n:convertText(step.dialog.text), -1, controls, self.onMessageClosed, self)

		return
	end

	if step.goal ~= nil then
		function self.goalPredicate()
			for _, check in ipairs(step.goal.checks) do
				if not self:performCheck(check) then
					return false
				end
			end

			return true
		end

		function self.goalAchievedCallback()
			self.goalPredicate = nil

			self:runStep(index + 1, false, false)
		end

		return
	else
		self:runStep(index + 1, false, false)
	end
end

function GuidedTour:loadIcon()
	if self.iconFilename ~= nil then
		g_i3DManager:loadI3DFileAsync(self.iconFilename, true, true, GuidedTour.onIconLoaded, self, nil)
	end
end

function GuidedTour:onIconLoaded(i3dNode, failedReason, args)
	if i3dNode ~= 0 then
		self.icon = i3dNode

		link(getRootNode(), self.icon)
		addTrigger(getChildAt(getChildAt(self.icon, 0), 0), "onIconTrigger", self)
		setWorldTranslation(self.icon, 0, -100, 0)
		g_messageCenter:publish(MessageType.MISSION_TOUR_STARTED)
		self:runStep(self.missionInfo.guidedTourStep, false, false)
	end
end

function GuidedTour:deleteIcon()
	if self.icon ~= nil then
		removeTrigger(getChildAt(getChildAt(self.icon, 0), 0))
		delete(self.icon)

		self.icon = nil
	end
end

function GuidedTour:setIcon(active, x, z, targetIndicator)
	setVisibility(self.icon, active)

	if active then
		local y = getTerrainHeightAtWorldPos(self.mission.terrainRootNode, x, 0, z)

		setWorldTranslation(self.icon, x, y, z)
	end

	self:setHotspot(active, targetIndicator, x, z)
end

function GuidedTour:loadHotspot()
	self.mapHotspot = TourHotspot.new()

	self.mission:addMapHotspot(self.mapHotspot)
end

function GuidedTour:deleteHotspot()
	if self.mapHotspot ~= nil then
		self.mission:removeMapHotspot(self.mapHotspot)
		self.mapHotspot:delete()

		self.mapHotspot = nil
	end
end

function GuidedTour:setHotspot(active, targetIndicator, x, z, vehicle)
	self.mapHotspot:setVisible(active)

	if active then
		if vehicle ~= nil then
			local _ = nil
			x, _, z = getWorldTranslation(self.vehicles[vehicle].rootNode)
		end

		self.mapHotspot:setWorldPosition(x, z)
	end

	self:setTargetIndicator(active and targetIndicator)
end

function GuidedTour:setTargetIndicator(active)
	if active then
		self.mission:setMapTargetHotspot(self.mapHotspot)
	else
		self.mission:setMapTargetHotspot(nil)
	end
end

function GuidedTour:performCheck(check)
	if check.name == "vehicleIsControlled" then
		return self.mission.controlledVehicle ~= nil and self.mission.controlledVehicle == self.vehicles[check.vehicle]
	elseif check.name == "vehicleIsMotorStarted" then
		local vehicle = self.vehicles[check.vehicle]

		if vehicle == nil or vehicle.getIsMotorStarted == nil then
			Logging.warning("Vehicle %s does not exist or has no motor", vehicle:getFullName())

			return false
		else
			return vehicle:getIsMotorStarted()
		end
	elseif check.name == "vehicleIsTurnedOn" then
		local vehicle = self.vehicles[check.vehicle]

		if vehicle == nil or vehicle.getIsTurnedOn == nil then
			Logging.warning("Vehicle %s does not exist or cannot be turned on", vehicle:getFullName())

			return false
		else
			return vehicle:getIsTurnedOn()
		end
	elseif check.name == "vehicleIsAIActive" then
		local vehicle = self.vehicles[check.vehicle]

		if vehicle == nil or vehicle.getIsAIActive == nil then
			Logging.warning("Vehicle %s does not exist or does not support AI", vehicle:getFullName())

			return false
		else
			return vehicle:getIsAIActive()
		end
	elseif check.name == "combineHasCutterAttached" then
		return self.vehicles[check.vehicle].spec_combine.numAttachedCutters > 0
	elseif check.name == "vehicleAttachedTo" then
		return self.vehicles[check.vehicle].rootVehicle == self.vehicles[check.toVehicle]
	elseif check.name == "playerIsWalking" then
		return self.mission.controlledVehicle == nil
	elseif check.name == "fillLevelAbove" then
		return check.fillLevel <= self.vehicles[check.vehicle]:getFillUnitFillLevel(check.fillUnitIndex)
	elseif check.name == "fillLevelBelow" then
		return self.vehicles[check.vehicle]:getFillUnitFillLevel(check.fillUnitIndex) <= check.fillLevel
	end

	return false
end
