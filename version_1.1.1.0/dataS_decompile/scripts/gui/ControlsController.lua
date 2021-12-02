ControlsController = {
	MESSAGE_CANNOT_MAP_MOUSE = 2,
	MESSAGE_SELECT_ACTION = 8,
	MESSAGE_CANNOT_MAP_CONTROLLER = 3,
	AXIS_DIRECTION_POSITIVE = 1,
	MESSAGE_CONFLICT_KEY = 9,
	BINDING_TERTIARY = 3,
	MESSAGE_PROMPT_CONTROLLER = 6,
	MESSAGE_CONFLICT_BLOCKED_KEY = 15,
	MESSAGE_PROMPT_CANCEL_DELETE = 7,
	MODIFIER_BUTTON_CONCAT = " + ",
	MESSAGE_REMAPPED = 13,
	AXIS_DIRECTION_NEGATIVE = -1,
	AXIS_NAME_Y = "Y",
	AXIS_AFFIX_NEGATIVE = "(-)",
	BINDING_PRIMARY = 1,
	MESSAGE_CONFLICT_BUTTON = 11,
	AXIS_NAME_X = "X",
	MESSAGE_ENSURE_IN_NEUTRAL = 14,
	MESSAGE_CONFLICT_MOUSE = 10,
	MESSAGE_PROMPT_KEY = 4,
	BINDING_SECONDARY = 2,
	AXIS_AFFIX_POSITIVE = "(+)",
	MESSAGE_PROMPT_MOUSE = 5,
	MESSAGE_CANNOT_MAP_KEY = 1,
	MESSAGE_CONFLICT_AXIS = 12,
	MESSAGE_CLEAR = 0
}
ControlsController.LOCKED_BINDINGS = {
	[ControlsController.BINDING_PRIMARY] = {
		[InputAction.MENU] = true,
		[InputAction.MENU_CANCEL] = true,
		[InputAction.MENU_BACK] = true,
		[InputAction.MENU_ACCEPT] = true,
		[InputAction.MENU_ACTIVATE] = true,
		[InputAction.MENU_PAGE_PREV] = true,
		[InputAction.MENU_PAGE_NEXT] = true,
		[InputAction.MENU_AXIS_UP_DOWN] = true,
		[InputAction.MENU_AXIS_UP_DOWN_SECONDARY] = true,
		[InputAction.MENU_AXIS_LEFT_RIGHT] = true
	},
	[ControlsController.BINDING_SECONDARY] = {},
	[ControlsController.BINDING_TERTIARY] = {}
}
local ControlsController_mt = Class(ControlsController)
ControlsController.INPUT_DELAY = 500
ControlsController.MOUSE_MOVE_THRESHOLD = 10

local function NO_CALLBACK()
end

function ControlsController.new()
	local self = setmetatable({}, ControlsController_mt)
	self.messageCallback = NO_CALLBACK
	self.inputDoneCallback = NO_CALLBACK
	self.controlsActions = {}
	self.controlsAnalogActions = {}
	self.controlsDigitalActions = {}
	self.actionBindings = nil
	self.waitForInput = false
	self.gatheringDevice = nil
	self.gatheringBindingIndex = nil
	self.gatheringAction = nil
	self.gatheringActionIndex = 0
	self.mouseMoveThresholdX = ControlsController.MOUSE_MOVE_THRESHOLD / g_screenWidth
	self.mouseMoveThresholdY = ControlsController.MOUSE_MOVE_THRESHOLD / g_screenHeight

	self:loadBindings()

	return self
end

function ControlsController:setMessageCallback(messageCallback)
	self.messageCallback = messageCallback or NO_CALLBACK
end

function ControlsController:setInputDoneCallback(inputDoneCallback)
	self.inputDoneCallback = inputDoneCallback or NO_CALLBACK
end

function ControlsController:createDisplayAction(deviceCategory, actionBinding, isAxisPositive)
	local action = actionBinding.action
	local bindings = actionBinding.bindings
	local displayActionBinding = DisplayActionBinding.new(action, action.displayNamePositive, isAxisPositive, bindings)

	if not isAxisPositive then
		displayActionBinding.displayName = action.displayNameNegative
	end

	local needKbMouse = deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE
	local needController = deviceCategory == InputDevice.CATEGORY.GAMEPAD
	local axisComponent = isAxisPositive and Binding.AXIS_COMPONENT.POSITIVE or Binding.AXIS_COMPONENT.NEGATIVE

	for _, binding in ipairs(bindings) do
		local isBindingKbMouse = binding.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
		local matchCategory = needKbMouse and isBindingKbMouse or needController and not isBindingKbMouse

		if matchCategory and binding.axisComponent == axisComponent then
			local inputText = self:getBindingInputDisplayText(binding)

			displayActionBinding:setBindingDisplay(binding, inputText, binding.index)
		end
	end

	return displayActionBinding
end

function ControlsController:getDeviceCategoryActionBindings(deviceCategory)
	self.numGamepads = getNumOfGamepads()
	local categories = {}
	local categoryMapping = {}

	for _, actionBinding in ipairs(self.actionBindings) do
		local bindingCategory = actionBinding.action.displayCategory

		if bindingCategory == nil then
			bindingCategory = "$l10n_inputCategory_OTHER"
		end

		local cat = nil

		if categoryMapping[bindingCategory] ~= nil then
			cat = categories[categoryMapping[bindingCategory]]
		else
			cat = {
				name = bindingCategory
			}

			table.insert(categories, cat)

			categoryMapping[bindingCategory] = #categories
		end

		table.insert(cat, self:createDisplayAction(deviceCategory, actionBinding, true))

		if actionBinding.action:isFullAxis() then
			table.insert(cat, self:createDisplayAction(deviceCategory, actionBinding, false))
		end
	end

	return categories
end

function ControlsController:getMouseAxisDisplayText(axis)
	local text = ""

	if InputBinding.MOUSE_AXES[axis] == Input.AXIS_X then
		text = ControlsController.AXIS_NAME_X
	elseif InputBinding.MOUSE_AXES[axis] == Input.AXIS_Y then
		text = ControlsController.AXIS_NAME_Y
	end

	if text ~= "" then
		local postFix = ControlsController.AXIS_AFFIX_POSITIVE

		if axis:sub(axis:len()) == "-" then
			postFix = ControlsController.AXIS_AFFIX_NEGATIVE
		end

		text = text .. postFix
	end

	return text
end

function ControlsController:getGamepadButtonDisplayText(buttonName, internalDeviceId)
	if internalDeviceId == nil or internalDeviceId < 0 then
		return string.format("%d", Input[buttonName] + 1)
	end

	return getGamepadButtonLabel(Input[buttonName], internalDeviceId)
end

function ControlsController:getGamepadAxisDisplayText(axisName, internalDeviceId)
	local axisLabel = nil

	if internalDeviceId == nil or internalDeviceId < 0 then
		axisLabel = string.format("Axis %d", Input[axisName] + 1)
	else
		axisLabel = getGamepadAxisLabel(Input[axisName], internalDeviceId)
	end

	local directionAffix = ControlsController.AXIS_AFFIX_POSITIVE

	if axisName:sub(axisName:len()) == "-" then
		directionAffix = ControlsController.AXIS_AFFIX_NEGATIVE
	end

	axisLabel = axisLabel .. directionAffix

	return axisLabel
end

function ControlsController:getBindingInputDisplayText(binding)
	if #binding.axisNames < 1 then
		return ""
	end

	local texts = {}
	local deviceLabel = ""
	local isKeyboard = binding.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT

	if isKeyboard then
		for _, axis in pairs(binding.axisNames) do
			if InputBinding.MOUSE_BUTTONS[axis] then
				table.insert(texts, getMouseButtonName(Input[axis]))
			elseif InputBinding.MOUSE_AXES[axis] then
				table.insert(texts, self:getMouseAxisDisplayText(axis))
			else
				table.insert(texts, KeyboardHelper.getDisplayKeyName(Input[axis]))
			end
		end
	else
		for _, axis in pairs(binding.axisNames) do
			if Input.buttonIdNameToId[axis] then
				table.insert(texts, self:getGamepadButtonDisplayText(axis, binding.internalDeviceId))
			elseif Input.axisIdNameToId[axis] then
				table.insert(texts, self:getGamepadAxisDisplayText(axis, binding.internalDeviceId))
			end
		end

		if self.numGamepads > 1 or g_inputBinding:getHasMissingDevices() then
			local device = g_inputBinding:getDeviceByInternalId(binding.internalDeviceId)

			if device == nil then
				device = g_inputBinding:getMissingDeviceById(binding.deviceId)
			end

			if device ~= nil then
				local gamepadName = device.deviceName

				if g_i18n:hasText(gamepadName) then
					gamepadName = g_i18n:getText(gamepadName)
				end

				deviceLabel = string.format(" [%s]", gamepadName)
			end
		end
	end

	return table.concat(texts, " + ") .. deviceLabel
end

function ControlsController:saveChanges()
	g_inputBinding:commitBindingChanges()
	g_inputBinding:saveToXMLFile()
end

function ControlsController:discardChanges()
	g_inputBinding:rollbackBindingChanges()
end

function ControlsController:loadBindings()
	self.actionBindings = g_inputBinding:getActionBindingsCopy(true)
end

function ControlsController:onClickInput(deviceCategory, bindingIndex, displayActionBinding)
	local startedListening = false

	if not self.waitForInput then
		if ControlsController.LOCKED_BINDINGS[bindingIndex][displayActionBinding.action.name] then
			if deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE then
				if bindingIndex == ControlsController.BINDING_TERTIARY then
					self.messageCallback(ControlsController.MESSAGE_CANNOT_MAP_MOUSE)
				else
					self.messageCallback(ControlsController.MESSAGE_CANNOT_MAP_KEY)
				end
			else
				self.messageCallback(ControlsController.MESSAGE_CANNOT_MAP_CONTROLLER)
			end
		else
			self:beginWaitForInput(deviceCategory, bindingIndex, displayActionBinding)

			startedListening = true
		end
	end

	return startedListening
end

function ControlsController:beginWaitForInput(deviceCategory, bindingIndex, displayActionBinding)
	g_inputBinding:startBindingChanges()

	self.waitForInput = true
	local gatheringState = {
		binding = displayActionBinding,
		bindingIndex = bindingIndex
	}

	if deviceCategory == InputDevice.CATEGORY.KEYBOARD_MOUSE then
		if bindingIndex == ControlsController.BINDING_TERTIARY then
			gatheringState.mouseState = {}

			g_inputBinding:startInputCapture(false, true, self, gatheringState, self.onCaptureMouseInput, self.onAbortInputGathering, self.onDeleteInputBinding)
		else
			gatheringState.keyState = {}

			g_inputBinding:startInputCapture(true, false, self, gatheringState, self.onCaptureKeyboardInput, self.onAbortInputGathering, self.onDeleteInputBinding)
		end
	else
		gatheringState.gamepadState = {}

		g_inputBinding:startInputCapture(false, false, self, gatheringState, self.onCaptureGamepadInput, self.onAbortInputGathering, self.onDeleteInputBinding)
	end
end

function ControlsController:onAbortInputGathering()
	self:endWaitForInput(false)
end

function ControlsController:onDeleteInputBinding(gatheringState)
	local hasDeleted = self:deleteBinding(gatheringState.binding, gatheringState.bindingIndex)

	self:endWaitForInput(hasDeleted)
end

function ControlsController:onCaptureKeyboardInput(_, keyName, inputValue, initInputValue, gatheringState)
	local keyState = gatheringState.keyState

	if inputValue > 0 then
		table.insert(keyState, keyName)
	else
		local displayActionBinding = gatheringState.binding
		local couldAssign = self:assignKeyboardBinding(displayActionBinding, gatheringState.bindingIndex, keyState)

		self:endWaitForInput(couldAssign)
	end
end

function ControlsController:onCaptureMouseInput(_, inputAxisName, inputValue, initInputValue, gatheringState)
	if not self.waitForInput then
		return
	end

	local mouseState = gatheringState.mouseState
	local lastInput = mouseState[inputAxisName]
	mouseState[inputAxisName] = inputValue
	local xAxisName = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_X]
	local yAxisName = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_Y]
	local xValue = mouseState[xAxisName] or 0
	local yValue = mouseState[yAxisName] or 0
	local hasButtonInput = false

	for buttonName in pairs(InputBinding.MOUSE_BUTTONS) do
		if mouseState[buttonName] ~= nil then
			hasButtonInput = true

			break
		end
	end

	local inputDirection = 1
	local displayActionBinding = gatheringState.binding
	local isAxisAction = displayActionBinding.action:isFullAxis()
	local axisNames = {}

	if InputBinding.MOUSE_BUTTONS[inputAxisName] ~= nil and lastInput == 1 and inputValue == 0 then
		table.insert(axisNames, inputAxisName)

		for buttonName in pairs(InputBinding.MOUSE_BUTTONS) do
			if mouseState[buttonName] == 1 then
				table.insert(axisNames, buttonName)

				break
			end

			mouseState[buttonName] = nil
		end

		local inputValid = true

		if isAxisAction then
			inputValid = xValue ~= 0 or yValue ~= 0

			if inputValid then
				if math.abs(xValue) < math.abs(yValue) then
					table.insert(axisNames, yAxisName)

					inputDirection = yValue
				else
					table.insert(axisNames, xAxisName)

					inputDirection = xValue
				end
			end
		end

		if inputValid then
			local couldAssign = self:assignMouseBinding(displayActionBinding, axisNames, inputDirection)

			self:endWaitForInput(couldAssign)
		end
	elseif isAxisAction and not hasButtonInput then
		local absX = math.abs(xValue)
		local absY = math.abs(yValue)

		if self.mouseMoveThresholdX < absX and absY < absX then
			table.insert(axisNames, xAxisName)

			inputDirection = xValue
		elseif self.mouseMoveThresholdY < absY and absX < absY then
			table.insert(axisNames, yAxisName)

			inputDirection = yValue
		end

		if #axisNames > 0 then
			local couldAssign = self:assignMouseBinding(displayActionBinding, axisNames, inputDirection)

			self:endWaitForInput(couldAssign)
		end
	end
end

function ControlsController:onCaptureGamepadInput(deviceId, inputAxisName, inputValue, initInputValue, gatheringState)
	local deviceState = gatheringState.gamepadState[deviceId]

	if not deviceState then
		deviceState = {}
		gatheringState.gamepadState[deviceId] = deviceState
	end

	local lastInput = deviceState[inputAxisName]
	deviceState[inputAxisName] = {
		inputValue,
		initInputValue
	}

	if lastInput and math.abs(lastInput[1] - initInputValue) > 0.3 and math.abs(inputValue - initInputValue) <= 0.3 then
		local axisNames = {}

		for axisName, axisInput in pairs(deviceState) do
			local axisInputValue = axisInput[1]
			local axisIntInputValue = axisInput[2]
			local axisNeutralInput = 0

			if axisIntInputValue > 0.5 then
				axisNeutralInput = 1
			elseif axisIntInputValue < -0.5 then
				axisNeutralInput = -1
			end

			if axisName ~= inputAxisName and math.abs(axisInputValue) > 0.5 and (axisNeutralInput == 0 or math.abs(axisInputValue - axisNeutralInput) > 0.6 or Input.isHalfAxis(Input[axisName])) then
				if axisInputValue < 0 then
					table.insert(axisNames, axisName .. "-")
				else
					table.insert(axisNames, axisName)
				end
			end
		end

		table.sort(axisNames)
		table.insert(axisNames, inputAxisName)

		local neutralInput = 0

		if not Input.isHalfAxis(Input[inputAxisName]) then
			if initInputValue > 0.5 then
				neutralInput = 1
			elseif initInputValue < -0.5 then
				neutralInput = -1
			end
		end

		local inputDirection = lastInput[1] - initInputValue
		local couldAssign = self:assignGamepadBinding(gatheringState.binding, gatheringState.bindingIndex, deviceId, axisNames, inputDirection, neutralInput)

		self:endWaitForInput(couldAssign)
	end
end

function ControlsController:endWaitForInput(madeChange)
	self.waitForInput = false

	g_inputBinding:stopInputGathering()
	self.inputDoneCallback(madeChange)
	self:lockInput()
end

function ControlsController:lockInput()
	for _, actionName in pairs(Gui.NAV_ACTIONS) do
		FocusManager:lockFocusInput(actionName, ControlsController.INPUT_DELAY)
	end
end

function ControlsController:deleteBinding(displayActionBinding, currentBindingIndex)
	local currentBinding = displayActionBinding.columnBindings[currentBindingIndex]

	for _, actionBinding in pairs(self.actionBindings) do
		if actionBinding.action == displayActionBinding.action then
			for _, binding in ipairs(actionBinding.bindings) do
				if currentBinding == binding then
					g_inputBinding:deleteBinding(binding.deviceId, displayActionBinding.action.name, binding.index, binding.axisComponent)

					local lastAxisName = currentBinding.axisNames[#currentBinding.axisNames]

					if InputBinding.getIsPhysicalFullAxis(lastAxisName) then
						g_inputBinding:deleteBinding(binding.deviceId, actionBinding.action.name, binding.index, Binding.getOppositeAxisComponent(binding.axisComponent))
					end

					self.messageCallback(ControlsController.MESSAGE_CLEAR)

					return true
				end
			end
		end
	end

	return false
end

function ControlsController:areKeyCombinationsBlocked(keyNames)
	local blockedCombos = Platform.blockedKeyboardCombos
	local numKeys = #keyNames

	for _, combo in ipairs(blockedCombos) do
		if #combo == numKeys then
			local areEqual = true

			for _, keyName in ipairs(keyNames) do
				local found = false

				for _, comboKey in ipairs(combo) do
					if keyName == comboKey then
						found = true

						break
					end
				end

				if not found then
					areEqual = false

					break
				end
			end

			if areEqual then
				return true
			end
		end
	end

	return false
end

function ControlsController:assignKeyboardBinding(displayActionBinding, bindingIndex, keyNames)
	if self:areKeyCombinationsBlocked(keyNames) then
		self.messageCallback(ControlsController.MESSAGE_CONFLICT_BLOCKED_KEY, {})

		return false
	end

	local success, collision = self:assignBinding(InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT, displayActionBinding.action, bindingIndex, keyNames, displayActionBinding.isPositive, 1, 0)

	if success then
		if collision and not collision.collisionAction.isLocked then
			local binding = collision.collisionBinding
			local action = collision.collisionAction
			local isPositiveAxisBinding = binding.axisComponent == Binding.AXIS_COMPONENT.POSITIVE
			local displayName = isPositiveAxisBinding and action.displayNamePositive or action.displayNameNegative

			self.messageCallback(ControlsController.MESSAGE_CONFLICT_KEY, {
				" (" .. displayName .. ")"
			})
		end

		self.messageCallback(ControlsController.MESSAGE_REMAPPED, {
			displayActionBinding.displayName,
			string.upper(KeyboardHelper.getInputDisplayText(keyNames))
		}, collision ~= nil)
	end

	return success
end

local function sortMouseAxisNames(axis1, axis2)
	local inputIndex1 = InputBinding.MOUSE_BUTTONS[axis1]
	local inputIndex2 = InputBinding.MOUSE_BUTTONS[axis2]

	if inputIndex1 == nil then
		return false
	elseif inputIndex2 == nil then
		return true
	else
		return inputIndex1 < inputIndex2
	end
end

function ControlsController:validateMouseCombo(inputAxisNames)
	if #inputAxisNames == 1 then
		return true
	end

	local modifierAxisList = {}

	for i = 1, #inputAxisNames - 1 do
		table.insert(modifierAxisList, inputAxisNames[i])
	end

	for _, buttonNames in pairs(InputBinding.MOUSE_COMBO_BINDINGS) do
		if table.equals(modifierAxisList, buttonNames) then
			return true
		end
	end

	return false
end

function ControlsController:assignMouseBinding(displayActionBinding, inputAxisNames, inputDirection)
	local bindingIndex = ControlsController.BINDING_TERTIARY
	local device = InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT

	table.sort(inputAxisNames, sortMouseAxisNames)

	if not self:validateMouseCombo(inputAxisNames) then
		return false
	end

	local success, collision = self:assignBinding(device, displayActionBinding.action, bindingIndex, inputAxisNames, displayActionBinding.isPositive, inputDirection, 0)

	if success then
		local lastAxisName = inputAxisNames[#inputAxisNames]

		if displayActionBinding.action:isFullAxis() and InputBinding.getIsPhysicalFullAxis(lastAxisName) then
			self:assignBinding(device, displayActionBinding.action, bindingIndex, inputAxisNames, not displayActionBinding.isPositive, -inputDirection, 0)
		end

		if collision and not collision.collisionAction.isLocked then
			local binding = collision.collisionBinding
			local action = collision.collisionAction
			local isPositiveAxisBinding = binding.axisComponent == Binding.AXIS_COMPONENT.POSITIVE
			local displayName = isPositiveAxisBinding and action.displayNamePositive or action.displayNameNegative

			self.messageCallback(ControlsController.MESSAGE_CONFLICT_MOUSE, {
				" (" .. displayName .. ")"
			})
		end

		self.messageCallback(ControlsController.MESSAGE_REMAPPED, {
			displayActionBinding.displayName,
			string.upper(MouseHelper.getInputDisplayText(inputAxisNames))
		}, collision ~= nil)
	end

	return success
end

function ControlsController:assignGamepadBinding(displayActionBinding, bindingIndex, deviceId, inputAxisNames, inputDirection, neutralInput)
	if self:areKeyCombinationsBlocked(inputAxisNames) then
		self.messageCallback(ControlsController.MESSAGE_CONFLICT_BLOCKED_KEY, {})

		return false
	end

	local previousBinding = displayActionBinding.columnBindings[bindingIndex]
	local previousDeviceId = deviceId

	if previousBinding then
		previousDeviceId = previousBinding.deviceId
	end

	local success, collision = self:assignBinding(deviceId, displayActionBinding.action, bindingIndex, inputAxisNames, displayActionBinding.isPositive, inputDirection, neutralInput, previousDeviceId)

	if success then
		local lastAxisName = inputAxisNames[#inputAxisNames]

		if displayActionBinding.action:isFullAxis() and InputBinding.getIsPhysicalFullAxis(lastAxisName) and neutralInput == 0 then
			self:assignBinding(deviceId, displayActionBinding.action, bindingIndex, inputAxisNames, not displayActionBinding.isPositive, -inputDirection, neutralInput)
		end

		if collision and not collision.collisionAction.isLocked then
			local binding = collision.collisionBinding
			local action = collision.collisionAction
			local messageId = ControlsController.MESSAGE_CONFLICT_BUTTON

			if displayActionBinding.action:isFullAxis() then
				messageId = ControlsController.MESSAGE_CONFLICT_AXIS
			end

			local isPositiveAxisBinding = binding.axisComponent == Binding.AXIS_COMPONENT.POSITIVE
			local displayName = isPositiveAxisBinding and action.displayNamePositive or action.displayNameNegative

			self.messageCallback(messageId, {
				" (" .. displayName .. ")"
			})
		end

		self.messageCallback(ControlsController.MESSAGE_REMAPPED, {
			displayActionBinding.displayName,
			string.upper(GamepadHelper.getInputDisplayText(inputAxisNames, g_inputBinding:getInternalIdByDeviceId(deviceId)))
		}, collision ~= nil)
	end

	return success
end

function ControlsController:assignBinding(deviceId, displayAction, bindingIndex, inputAxisNames, isPositiveAxis, inputDirection, neutralInput, previousDeviceId)
	local axisComponent = isPositiveAxis and Binding.AXIS_COMPONENT.POSITIVE or Binding.AXIS_COMPONENT.NEGATIVE
	local inputComponent = inputDirection >= 0 and Binding.INPUT_COMPONENT.POSITIVE or Binding.INPUT_COMPONENT.NEGATIVE
	previousDeviceId = previousDeviceId or deviceId
	local couldUpdate, collisionAction = g_inputBinding:updateBinding(previousDeviceId, displayAction.name, bindingIndex, axisComponent, deviceId, inputAxisNames, inputComponent, neutralInput)
	local couldAdd = true

	if not couldUpdate then
		local binding = Binding.new(deviceId, inputAxisNames, axisComponent, inputComponent, neutralInput, bindingIndex)
		local action = g_inputBinding:getActionByName(displayAction.name)
		couldAdd, collisionAction = g_inputBinding:addBinding(action, binding)
	end

	return couldUpdate or couldAdd, collisionAction
end

function ControlsController:loadDefaultSettings()
	g_inputBinding:restoreDefaultBindings()
	self:loadBindings()
end
