VehicleActionController = {}
local VehicleActionController_mt = Class(VehicleActionController)

source("dataS/scripts/vehicles/VehicleActionControllerAction.lua")

function VehicleActionController.new(vehicle, customMt)
	if customMt == nil then
		customMt = VehicleActionController_mt
	end

	local self = setmetatable({}, customMt)
	self.vehicle = vehicle
	self.actions = {}
	self.actionsByPrio = {}
	self.sortedActions = {}
	self.sortedActionsRev = {}
	self.currentSequenceActions = {}
	self.actionEvents = {}
	self.lastDirection = -1

	return self
end

function VehicleActionController:saveToXMLFile(xmlFile, key, usedModNames)
	if #self.actions > 0 then
		xmlFile:setValue(key .. "#lastDirection", self.lastDirection)
		xmlFile:setValue(key .. "#numActions", #self.actions)

		local i = 0

		for _, action in ipairs(self.actions) do
			if action:getIsSaved() then
				local actionKey = string.format("%s.action(%d)", key, i)

				xmlFile:setValue(actionKey .. "#name", action.name)
				xmlFile:setValue(actionKey .. "#identifier", action.identifier)
				xmlFile:setValue(actionKey .. "#lastDirection", action:getLastDirection())

				i = i + 1
			end
		end
	end
end

function VehicleActionController:load(savegame)
	if savegame ~= nil then
		self.lastDirection = savegame.xmlFile:getValue(savegame.key .. ".actionController#lastDirection", self.lastDirection)
		self.loadedNumActions = savegame.xmlFile:getValue(savegame.key .. ".actionController#numActions", 0)
		self.loadTime = g_time
		local needsToApply = false
		self.loadedActions = {}
		local i = 0

		while true do
			local baseKey = string.format("%s.actionController.action(%d)", savegame.key, i)

			if not savegame.xmlFile:hasProperty(baseKey) then
				break
			end

			local action = {
				name = savegame.xmlFile:getValue(baseKey .. "#name"),
				identifier = savegame.xmlFile:getValue(baseKey .. "#identifier"),
				lastDirection = savegame.xmlFile:getValue(baseKey .. "#lastDirection")
			}

			if action.lastDirection > 0 then
				needsToApply = true
			end

			table.insert(self.loadedActions, action)

			i = i + 1
		end

		if not needsToApply then
			self.loadedNumActions = 0
			self.loadedActions = {}
		end
	end
end

function VehicleActionController:registerAction(name, inputAction, prio)
	local action = VehicleActionControllerAction.new(self, name, inputAction, prio)

	self:addAction(action)

	return action
end

function VehicleActionController:addAction(action)
	table.insert(self.actions, action)
	self:updateSortedActions()

	self.actionsDirty = true

	self.vehicle:requestActionEventUpdate()
end

function VehicleActionController:removeAction(action)
	if Platform.gameplay.automaticVehicleControl and action:getLastDirection() == 1 and action:getDoResetOnDeactivation() then
		action:doAction()
	end

	for i, v in ipairs(self.actions) do
		if v == action then
			table.remove(self.actions, i)

			break
		end
	end

	if #self.actions == 0 then
		self.lastDirection = -1
	end

	self:updateSortedActions()
end

function VehicleActionController:updateSortedActions()
	local prioToActionTable = {}
	self.actionsByPrio = {}

	for _, action in ipairs(self.actions) do
		if prioToActionTable[action.priority] == nil then
			local prioTable = {
				action
			}

			table.insert(self.actionsByPrio, prioTable)

			prioToActionTable[action.priority] = prioTable
		else
			table.insert(prioToActionTable[action.priority], action)
		end
	end

	local function sortFunc(a, b)
		return b[1].priority < a[1].priority
	end

	self.sortedActions = table.copy(self.actionsByPrio)

	table.sort(self.sortedActions, sortFunc)

	local function sortFuncRev(a, b)
		return a[1].priority < b[1].priority
	end

	self.sortedActionsRev = table.copy(self.actionsByPrio)

	table.sort(self.sortedActionsRev, sortFuncRev)
end

function VehicleActionController:registerActionEvents(isActiveForInput, isActiveForInputIgnoreSelection)
	if #self.actions > 0 and self.vehicle.rootVehicle == self.vehicle then
		self.vehicle:clearActionEventsTable(self.actionEvents)

		for _, action in ipairs(self.actions) do
			action:registerActionEvents(self, self.vehicle, self.actionEvents, isActiveForInput, isActiveForInputIgnoreSelection)
		end

		if self.actionEventId ~= nil then
			g_inputBinding:removeActionEvent(self.actionEventId)
		end

		local _, actionEventId, _ = g_inputBinding:registerActionEvent(InputAction.VEHICLE_ACTION_CONTROL, self, VehicleActionController.actionSequenceEvent, false, true, false, true)
		self.actionEventId = actionEventId
	end
end

function VehicleActionController:actionEvent(actionName, inputValue, actionIndex, isAnalog)
	self:doAction(actionIndex)
end

function VehicleActionController:doAction(actionIndex, customTable, direction)
	local actions = self:getActionsByIndex(actionIndex, customTable)

	if actions ~= nil then
		local retValue = false

		for _, action in ipairs(actions) do
			local success = action:doAction(direction)
			retValue = retValue or success
		end

		return retValue
	end

	return false
end

function VehicleActionController:actionSequenceEvent()
	if self.vehicle.getAreControlledActionsAllowed ~= nil then
		local allowed, warning = self.vehicle:getAreControlledActionsAllowed()

		if not allowed then
			g_currentMission:showBlinkingWarning(warning, 2500)

			return
		end
	end

	self:startActionSequence()
end

function VehicleActionController:startActionSequence(force)
	local direction = -self.lastDirection
	self.currentSequenceActions = self.sortedActionsRev

	if direction > 0 then
		self.currentSequenceActions = self.sortedActions
	end

	if not force then
		local alreadyFinished = true

		for _, actions in ipairs(self.currentSequenceActions) do
			for _, action in ipairs(actions) do
				local finished = action.lastValidDirection == direction
				alreadyFinished = alreadyFinished and finished
			end
		end

		if alreadyFinished then
			self.lastDirection = direction

			self:startActionSequence(true)

			return
		end
	end

	if self.currentSequenceIndex ~= nil then
		self.currentSequenceIndex = self.currentMaxSequenceIndex - (self.currentSequenceIndex - 1)
	else
		self.currentSequenceIndex = 1
		self.currentMaxSequenceIndex = #self.currentSequenceActions
	end

	self.lastDirection = direction

	if not self:doAction(self.currentSequenceIndex, self.currentSequenceActions, self.lastDirection) then
		self:continueActionSequence()
	end
end

function VehicleActionController:continueActionSequence()
	self.currentSequenceIndex = self.currentSequenceIndex + 1
	local success = self:doAction(self.currentSequenceIndex, self.currentSequenceActions, self.lastDirection)

	if self.currentMaxSequenceIndex <= self.currentSequenceIndex then
		self:stopActionSequence()
	elseif not success then
		self:continueActionSequence()
	end
end

function VehicleActionController:stopActionSequence()
	self.currentSequenceActions = nil
	self.currentSequenceIndex = nil
	self.currentMaxSequenceIndex = nil
end

function VehicleActionController:getActionsByIndex(actionIndex, customTable)
	if customTable ~= nil then
		return customTable[actionIndex]
	else
		return self.actionsByPrio[actionIndex]
	end
end

function VehicleActionController:getAreControlledActionsAvailable()
	return #self.actions > 0
end

function VehicleActionController:playControlledActions()
	self:startActionSequence()
end

function VehicleActionController:resetCurrentState()
	self.lastDirection = -1
end

function VehicleActionController:getActionControllerDirection()
	return -self.lastDirection
end

function VehicleActionController:update(dt)
	if self.currentSequenceIndex ~= nil and self.currentSequenceIndex <= self.currentMaxSequenceIndex then
		local actions = self:getActionsByIndex(self.currentSequenceIndex, self.currentSequenceActions)

		if actions ~= nil then
			local allFinished = true

			for _, action in ipairs(actions) do
				if not action:getIsFinished(self.lastDirection) then
					allFinished = false

					break
				end
			end

			if allFinished then
				if self.currentSequenceIndex < self.currentMaxSequenceIndex then
					self:continueActionSequence()
				else
					self:stopActionSequence()
				end
			end
		end
	end

	for _, action in ipairs(self.actions) do
		action:update(dt)
	end

	if self.loadedNumActions ~= 0 and self.loadedNumActions == #self.actions and self.loadTime + 500 < g_time then
		if self.vehicle.startMotor ~= nil and not self.vehicle:getIsMotorStarted() then
			self.vehicle:startMotor()
		end

		local isStarted = true

		if self.vehicle.startMotor ~= nil then
			isStarted = self.vehicle:getIsMotorStarted(true)
		end

		if isStarted then
			for _, loadedAction in ipairs(self.loadedActions) do
				for _, actionToCheck in ipairs(self.actions) do
					if actionToCheck.name == loadedAction.name and actionToCheck.identifier == loadedAction.identifier and actionToCheck:getLastDirection() ~= loadedAction.lastDirection then
						actionToCheck:doAction()
					end
				end
			end

			self.loadedNumActions = 0
		end
	end

	if self.actionsDirty and self.loadedNumActions == 0 then
		for _, action in ipairs(self.actions) do
			if action:getLastDirection() ~= self.lastDirection then
				action:doAction()
			end
		end

		self.actionsDirty = nil
	end
end

function VehicleActionController:updateForAI(dt)
	for _, action in ipairs(self.actions) do
		action:updateForAI(dt)
	end
end

function VehicleActionController:onAIEvent(sourceVehicle, eventName)
	for _, action in ipairs(self.actions) do
		if action:getSourceVehicle() == sourceVehicle then
			action:onAIEvent(eventName)
		end
	end
end

function VehicleActionController:drawDebugRendering()
	local function renderTextVAC(x, y, height, text, color)
		setTextColor(0, 0, 0, 0.75)
		renderText(x, y - 0.0015, height, text)

		color = color or {
			1,
			1,
			1,
			1
		}

		setTextColor(unpack(color))
		renderText(x, y, height, text)
	end

	local function drawActions(name, sequenceActions, highlightIndex, posX, posY)
		if sequenceActions ~= nil and #sequenceActions > 0 then
			setTextBold(false)
			setTextAlignment(RenderText.ALIGN_CENTER)

			local textHeight = 0.012
			local lineSpacing = 0.002
			local lineHeight = textHeight + lineSpacing
			local currentHeight = 0

			for i = #sequenceActions, 1, -1 do
				local actions = sequenceActions[i]

				setTextBold(highlightIndex == i)

				local color = nil

				if i < highlightIndex then
					color = {
						0,
						1,
						0,
						1
					}
				elseif i == highlightIndex then
					color = {
						1,
						0.5,
						0,
						1
					}
				end

				for _, action in ipairs(actions) do
					renderTextVAC(posX, posY + currentHeight, textHeight, action:getDebugText(), color)

					currentHeight = currentHeight + lineHeight
				end

				renderTextVAC(posX, posY + currentHeight + lineHeight * 0.5, textHeight, "__________________________")

				currentHeight = currentHeight + lineHeight
			end

			renderTextVAC(posX, posY + currentHeight + lineHeight * 0.5, textHeight * 1.5, name)
			setTextBold(false)
			setTextAlignment(RenderText.ALIGN_LEFT)
		end
	end

	drawActions("Controlled Actions", self.sortedActions, -1, 0.2, 0.3)

	local directionText = self.lastDirection == 1 and "TurnOn" or "TurnOff"

	drawActions(string.format("Current Action Sequence (%s)", directionText), self.currentSequenceActions, self.currentSequenceIndex, 0.4, 0.3)
end

function VehicleActionController.registerXMLPaths(schema, basePath)
	schema:register(XMLValueType.INT, basePath .. "#lastDirection", "Last action controller direction")
	schema:register(XMLValueType.INT, basePath .. "#numActions", "Action controller actions")
	schema:register(XMLValueType.STRING, basePath .. ".action(?)#name", "Action name")
	schema:register(XMLValueType.STRING, basePath .. ".action(?)#identifier", "Action identifier")
	schema:register(XMLValueType.INT, basePath .. ".action(?)#lastDirection", "Last action direction")
end
