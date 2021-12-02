InputBinding = {}
local InputBinding_mt = Class(InputBinding)

source("dataS/scripts/input/InputAction.lua")
source("dataS/scripts/input/InputDevice.lua")
source("dataS/scripts/input/Binding.lua")
source("dataS/scripts/input/InputEvent.lua")

InputBinding.version = 4
InputBinding.currentBindingVersion = 1
InputBinding.PATHS = {
	DEFAULT_BINDINGS_KB_MOUSE = getAppBasePath() .. "profileTemplate/inputBindingDefault_KeyboardMouse.xml",
	DEFAULT_BINDINGS_KB_MOUSE_GGP = getAppBasePath() .. "profileTemplate/inputBindingDefault_KeyboardMouse_GGP.xml",
	DEFAULT_BINDINGS_GAMEPAD = getAppBasePath() .. "profileTemplate/inputBindingDefault_Gamepad.xml",
	DEFAULT_BINDINGS_JOYSTICK = getAppBasePath() .. "profileTemplate/inputBindingDefault_Joystick.xml",
	DEFAULT_BINDINGS_WHEEL = getAppBasePath() .. "profileTemplate/inputBindingDefault_Wheel.xml",
	DEFAULT_BINDINGS_WHEEL_AND_PANEL = getAppBasePath() .. "profileTemplate/inputBindingDefault_WheelAndPanel.xml",
	DEFAULT_BINDINGS_PS4 = getAppBasePath() .. "profileTemplate/inputBindingDefault_Gamepad.xml",
	DEFAULT_BINDINGS_XBOX = getAppBasePath() .. "profileTemplate/inputBindingDefault_Gamepad.xml",
	DEFAULT_BINDINGS_IOS = getAppBasePath() .. "profileTemplate/inputBindingDefault_Mobile.xml",
	DEFAULT_BINDINGS_ANDROID = getAppBasePath() .. "profileTemplate/inputBindingDefault_Mobile.xml",
	DEFAULT_BINDINGS_SWITCH = getAppBasePath() .. "profileTemplate/inputBindingDefault_Switch.xml",
	DEFAULT_BINDINGS_SAITEK_WHEEL_AND_PANEL = getAppBasePath() .. "profileTemplate/inputBindingDefault_SaitekWheelAndPanel.xml",
	DEFAULT_BINDINGS_SAITEK_WHEEL = getAppBasePath() .. "profileTemplate/inputBindingDefault_SaitekWheel.xml",
	DEFAULT_BINDINGS_SAITEK_PANEL = getAppBasePath() .. "profileTemplate/inputBindingDefault_SaitekPanel.xml",
	ACTION_DEFINITIONS = getAppBasePath() .. "dataS/inputActions.xml",
	USER_BINDINGS = getUserProfileAppPath() .. "inputBinding.xml"
}
InputBinding.DEVICE_CATEGORY_DEFAULTS_PATHS = {
	[InputDevice.CATEGORY.GAMEPAD] = InputBinding.PATHS.DEFAULT_BINDINGS_GAMEPAD,
	[InputDevice.CATEGORY.JOYSTICK] = InputBinding.PATHS.DEFAULT_BINDINGS_JOYSTICK,
	[InputDevice.CATEGORY.WHEEL] = InputBinding.PATHS.DEFAULT_BINDINGS_WHEEL,
	[InputDevice.CATEGORY.FARMWHEEL] = InputBinding.PATHS.DEFAULT_BINDINGS_SAITEK_WHEEL,
	[InputDevice.CATEGORY.FARMPANEL] = InputBinding.PATHS.DEFAULT_BINDINGS_SAITEK_PANEL,
	[InputDevice.CATEGORY.UNKNOWN] = InputBinding.PATHS.DEFAULT_BINDINGS_GAMEPAD,
	[InputDevice.CATEGORY.WHEEL_AND_PANEL] = InputBinding.PATHS.DEFAULT_BINDINGS_WHEEL_AND_PANEL,
	[InputDevice.CATEGORY.FARMWHEEL_AND_PANEL] = InputBinding.PATHS.DEFAULT_BINDINGS_SAITEK_WHEEL_AND_PANEL
}
InputBinding.DEVICE_CATEGORY_DEFAULT_LOAD_ORDER = {
	InputDevice.CATEGORY.FARMWHEEL_AND_PANEL,
	InputDevice.CATEGORY.WHEEL_AND_PANEL,
	InputDevice.CATEGORY.FARMWHEEL,
	InputDevice.CATEGORY.WHEEL,
	InputDevice.CATEGORY.GAMEPAD,
	InputDevice.CATEGORY.JOYSTICK,
	InputDevice.CATEGORY.FARMPANEL
}
InputBinding.INPUTTYPE_NONE = 0
InputBinding.INPUTTYPE_KEYBOARD = 1
InputBinding.INPUTTYPE_MOUSE_BUTTON = 2
InputBinding.INPUTTYPE_MOUSE_WHEEL = 3
InputBinding.INPUTTYPE_MOUSE_AXIS = 4
InputBinding.INPUTTYPE_GAMEPAD = 5
InputBinding.INPUTTYPE_GAMEPAD_AXIS = 6
InputBinding.MOUSE_AXIS_NONE = 0
InputBinding.MOUSE_AXIS_X = 1
InputBinding.MOUSE_AXIS_Y = 2
InputBinding.SYMBOL_AFFIX_POSITIVE = "_1"
InputBinding.SYMBOL_AFFIX_NEGATIVE = "_2"
InputBinding.NO_EVENT_TARGET = 0
InputBinding.MOUSE_AXES = {
	AXIS_X = Input.AXIS_X,
	AXIS_Y = Input.AXIS_Y,
	["AXIS_X+"] = Input.AXIS_X,
	["AXIS_Y+"] = Input.AXIS_Y,
	["AXIS_X-"] = Input.AXIS_X,
	["AXIS_Y-"] = Input.AXIS_Y
}
InputBinding.MOUSE_AXIS_NAMES = {
	[Input.AXIS_X] = "AXIS_X",
	[Input.AXIS_Y] = "AXIS_Y"
}
InputBinding.MOUSE_BUTTONS = {
	MOUSE_BUTTON_LEFT = Input.MOUSE_BUTTON_LEFT,
	MOUSE_BUTTON_RIGHT = Input.MOUSE_BUTTON_RIGHT,
	MOUSE_BUTTON_MIDDLE = Input.MOUSE_BUTTON_MIDDLE,
	MOUSE_BUTTON_WHEEL_UP = Input.MOUSE_BUTTON_WHEEL_UP,
	MOUSE_BUTTON_WHEEL_DOWN = Input.MOUSE_BUTTON_WHEEL_DOWN,
	MOUSE_BUTTON_X1 = Input.MOUSE_BUTTON_X1,
	MOUSE_BUTTON_X2 = Input.MOUSE_BUTTON_X2
}
InputBinding.MOUSE_WHEEL = {
	[Input.MOUSE_BUTTON_WHEEL_UP] = true,
	[Input.MOUSE_BUTTON_WHEEL_DOWN] = true
}
InputBinding.MOUSE_BUTTON_NAMES = {
	[Input.MOUSE_BUTTON_LEFT] = "MOUSE_BUTTON_LEFT",
	[Input.MOUSE_BUTTON_RIGHT] = "MOUSE_BUTTON_RIGHT",
	[Input.MOUSE_BUTTON_MIDDLE] = "MOUSE_BUTTON_MIDDLE",
	[Input.MOUSE_BUTTON_WHEEL_UP] = "MOUSE_BUTTON_WHEEL_UP",
	[Input.MOUSE_BUTTON_WHEEL_DOWN] = "MOUSE_BUTTON_WHEEL_DOWN",
	[Input.MOUSE_BUTTON_X1] = "MOUSE_BUTTON_X1",
	[Input.MOUSE_BUTTON_X2] = "MOUSE_BUTTON_X2"
}
InputBinding.GAMEPAD_DPAD = {
	[Input.BUTTON_16] = true,
	[Input.BUTTON_17] = true,
	[Input.BUTTON_18] = true,
	[Input.BUTTON_19] = true
}
InputBinding.COMBO_MASK_CONSOLE_COMMAND_1 = 1
InputBinding.COMBO_MASK_CONSOLE_COMMAND_2 = 2
InputBinding.COMBO_MASK_CONSOLE_COMMAND_3 = 4
InputBinding.COMBO_MASK_MOUSE_COMMAND_1 = 1
InputBinding.COMBO_MASK_MOUSE_COMMAND_2 = 2
InputBinding.COMBO_MASK_MOUSE_COMMAND_3 = 4
InputBinding.COMBO_MASK_MOUSE_COMMAND_4 = 8
InputBinding.GAMEPAD_COMBOS = {
	[InputAction.CONSOLE_ALT_COMMAND_BUTTON] = {
		mask = InputBinding.COMBO_MASK_CONSOLE_COMMAND_1,
		controls = InputAction.CONSOLE_ALT_COMMAND_BUTTON
	},
	[InputAction.CONSOLE_ALT_COMMAND2_BUTTON] = {
		mask = InputBinding.COMBO_MASK_CONSOLE_COMMAND_2,
		controls = InputAction.CONSOLE_ALT_COMMAND2_BUTTON
	},
	[InputAction.CONSOLE_ALT_COMMAND3_BUTTON] = {
		mask = InputBinding.COMBO_MASK_CONSOLE_COMMAND_3,
		controls = InputAction.CONSOLE_ALT_COMMAND3_BUTTON
	}
}
InputBinding.ORDERED_GAMEPAD_COMBOS = {
	InputBinding.GAMEPAD_COMBOS[InputAction.CONSOLE_ALT_COMMAND_BUTTON],
	InputBinding.GAMEPAD_COMBOS[InputAction.CONSOLE_ALT_COMMAND3_BUTTON],
	InputBinding.GAMEPAD_COMBOS[InputAction.CONSOLE_ALT_COMMAND2_BUTTON]
}
InputBinding.MOUSE_COMBOS = {
	[InputAction.MOUSE_ALT_COMMAND_BUTTON] = {
		mask = InputBinding.COMBO_MASK_MOUSE_COMMAND_1,
		controls = InputAction.MOUSE_ALT_COMMAND_BUTTON
	},
	[InputAction.MOUSE_ALT_COMMAND2_BUTTON] = {
		mask = InputBinding.COMBO_MASK_MOUSE_COMMAND_2,
		controls = InputAction.MOUSE_ALT_COMMAND2_BUTTON
	},
	[InputAction.MOUSE_ALT_COMMAND3_BUTTON] = {
		mask = InputBinding.COMBO_MASK_MOUSE_COMMAND_3,
		controls = InputAction.MOUSE_ALT_COMMAND3_BUTTON
	},
	[InputAction.MOUSE_ALT_COMMAND4_BUTTON] = {
		mask = InputBinding.COMBO_MASK_MOUSE_COMMAND_4,
		controls = InputAction.MOUSE_ALT_COMMAND4_BUTTON
	}
}
InputBinding.ORDERED_MOUSE_COMBOS = {
	InputBinding.MOUSE_COMBOS[InputAction.MOUSE_ALT_COMMAND_BUTTON],
	InputBinding.MOUSE_COMBOS[InputAction.MOUSE_ALT_COMMAND3_BUTTON],
	InputBinding.MOUSE_COMBOS[InputAction.MOUSE_ALT_COMMAND4_BUTTON],
	InputBinding.MOUSE_COMBOS[InputAction.MOUSE_ALT_COMMAND2_BUTTON]
}
InputBinding.ALL_COMBOS = {
	InputBinding.GAMEPAD_COMBOS,
	InputBinding.MOUSE_COMBOS
}
InputBinding.GAMEPAD_COMBO_BINDINGS = {
	[InputAction.CONSOLE_ALT_COMMAND_BUTTON] = {
		Input.buttonIdToIdName[Input.BUTTON_5]
	},
	[InputAction.CONSOLE_ALT_COMMAND2_BUTTON] = {
		Input.buttonIdToIdName[Input.BUTTON_6]
	},
	[InputAction.CONSOLE_ALT_COMMAND3_BUTTON] = {
		Input.buttonIdToIdName[Input.BUTTON_5],
		Input.buttonIdToIdName[Input.BUTTON_6]
	}
}
InputBinding.GAMEPAD_COMBO_AXIS_NAMES = {
	[Input.buttonIdToIdName[Input.BUTTON_5]] = true,
	[Input.buttonIdToIdName[Input.BUTTON_6]] = true
}
InputBinding.MOUSE_COMBO_BINDINGS = {
	[InputAction.MOUSE_ALT_COMMAND_BUTTON] = {
		InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_LEFT]
	},
	[InputAction.MOUSE_ALT_COMMAND2_BUTTON] = {
		InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_RIGHT]
	},
	[InputAction.MOUSE_ALT_COMMAND3_BUTTON] = {
		InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_MIDDLE]
	},
	[InputAction.MOUSE_ALT_COMMAND4_BUTTON] = {
		InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_LEFT],
		InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_RIGHT]
	}
}
InputBinding.MOUSE_COMBO_AXIS_NAMES = {
	[InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_LEFT]] = true,
	[InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_RIGHT]] = true,
	[InputBinding.MOUSE_BUTTON_NAMES[Input.MOUSE_BUTTON_MIDDLE]] = true
}
InputBinding.MOUSE_MOVE_BASE_FACTOR = 75
InputBinding.MOUSE_MOVE_LIMIT = 4
InputBinding.MOUSE_MOTION_SCALE_X_DEFAULT = 1
InputBinding.MOUSE_MOTION_SCALE_Y_DEFAULT = 1
InputBinding.MOUSE_WHEEL_INPUT_FACTOR = 3
InputBinding.INPUT_MODE_CHANGE_THRESHOLD = 0.2
InputBinding.INPUT_MODE_CHANGE_MIN_INTERVAL = (GS_PLATFORM_GGP or GS_IS_MOBILE_VERSION) and 0 or 5000
InputBinding.KB_MOUSE_INTERNAL_ID = 255
InputBinding.ROOT_CONTEXT_NAME = "ROOT"
InputBinding.NO_REGISTRATION_CONTEXT = {
	eventOrderCounter = 0,
	name = "",
	previousContextName = "",
	actionEvents = {}
}
InputBinding.NO_ACTION_EVENTS = {}
InputBinding.MESSAGE_PARAM_INPUT_MODE = {
	[GS_INPUT_HELP_MODE_KEYBOARD] = {
		GS_INPUT_HELP_MODE_KEYBOARD
	},
	[GS_INPUT_HELP_MODE_GAMEPAD] = {
		GS_INPUT_HELP_MODE_GAMEPAD
	},
	[GS_INPUT_HELP_MODE_TOUCH] = {
		GS_INPUT_HELP_MODE_TOUCH
	}
}

function InputBinding.new(modManager, messageCenter, isConsoleVersion)
	local self = setmetatable({}, InputBinding_mt)
	self.debugEnabled = false
	self.debugContextEnabled = false
	self.modManager = modManager
	self.messageCenter = messageCenter
	self.isConsoleVersion = isConsoleVersion
	self.devicesByInternalId = {}
	self.devicesByCategory = {}
	self.deviceIdToInternal = {}
	self.internalToDeviceId = {}
	self.engineDeviceIdCounts = {}
	self.internalIdToEngineDeviceId = {}
	self.newlyConnectedDevices = {}
	self.missingDevices = {}
	self.actions = {}
	self.nameActions = {}
	self.originalActionBindings = nil
	self.activeDeviceBindingsBuffer = {}
	self.mouseMovementX = 0
	self.mouseMovementY = 0
	self.accumMouseMovementX = 0
	self.accumMouseMovementY = 0
	self.actionEvents = {}
	self.displayActionEvents = {}
	self.events = {}
	self.eventOrder = {}
	self.loadedBindings = {}
	self.activeBindings = {}
	self.eventBindings = {}
	self.linkedBindings = {}
	self.currentContextName = InputBinding.ROOT_CONTEXT_NAME
	self.contexts = {
		[InputBinding.ROOT_CONTEXT_NAME] = {
			previousContextName = "",
			actionEvents = {}
		}
	}
	self.registrationContext = InputBinding.NO_REGISTRATION_CONTEXT
	self.comboInputAxisMasks = {}
	self.comboInputActions = {}
	self.comboInputBindings = {}
	self.pressedMouseComboMask = 0
	self.pressedGamepadComboMask = 0
	self.needUpdateAbort = false
	self.eventChangeCallback = nil
	self.wrapMousePositionEnabled = false
	self.saveCursorX = 0.5
	self.saveCursorY = 0.5
	self.mouseMotionScaleX = 0.75
	self.mouseMotionScaleY = 0.75
	self.devicesToMigrateCategory = {}
	self.isInputCapturing = false
	self.gatherInputStoredMouseEvent = nil
	self.gatherInputStoredKeyEvent = nil
	self.gatherInputStoredUpdate = nil
	self.gamepadInputState = {}
	self.timeSinceLastInputHelpModeChange = InputBinding.INPUT_MODE_CHANGE_MIN_INTERVAL
	self.lastInputHelpMode = GS_INPUT_HELP_MODE_KEYBOARD

	if isConsoleVersion then
		self.lastInputHelpMode = GS_INPUT_HELP_MODE_GAMEPAD
	end

	self.lastInputMode = self.lastInputHelpMode
	self.inputHelpModeSetting = g_gameSettings:getValue(GameSettings.SETTING.INPUT_HELP_MODE)

	local function inputHelpModeSettingChangedCallback(newMode)
		self.inputHelpModeSetting = newMode
	end

	self.isGamepadEnabled = isConsoleVersion or g_gameSettings:getValue(GameSettings.SETTING.IS_GAMEPAD_ENABLED)

	local function gamepadEnabledSettingChangedCallback(isEnabled)
		self.isGamepadEnabled = isEnabled
	end

	messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.INPUT_HELP_MODE], inputHelpModeSettingChangedCallback)
	messageCenter:subscribe(MessageType.SETTING_CHANGED[GameSettings.SETTING.IS_GAMEPAD_ENABLED], gamepadEnabledSettingChangedCallback)

	self.settingsPath = nil

	self:assignPlatformBindingPaths()
	addConsoleCommand("gsInputDebug", "", "consoleCommandEnableInputDebug", self)
	addConsoleCommand("gsInputContextPrint", "", "consoleCommandPrintInputContext", self)
	addConsoleCommand("gsInputContextShow", "", "consoleCommandShowInputContext", self)

	return self
end

function InputBinding:load()
	self:clearState()

	local xmlFileActionDefinitions = loadXMLFile("ActionDefinitions", InputBinding.PATHS.ACTION_DEFINITIONS)

	self:loadActions(xmlFileActionDefinitions)
	delete(xmlFileActionDefinitions)
	self:loadModActions()

	local xmlFileInputBinding = loadXMLFile("InputBindings", self.settingsPath)
	self.version = Utils.getNoNil(getXMLFloat(xmlFileInputBinding, "inputBinding#version"), 0.1)
	self.mouseMotionScaleX = Utils.getNoNil(getXMLFloat(xmlFileInputBinding, "inputBinding#mouseSensitivityScaleX"), 1) * self.MOUSE_MOTION_SCALE_X_DEFAULT
	self.mouseMotionScaleY = Utils.getNoNil(getXMLFloat(xmlFileInputBinding, "inputBinding#mouseSensitivityScaleY"), 1) * self.MOUSE_MOTION_SCALE_Y_DEFAULT

	self:initializeGamepadMapping(xmlFileInputBinding)
	self:loadActionBindingsFromXML(xmlFileInputBinding, false, nil)
	self:upgradeBindingVersion(xmlFileInputBinding)
	self:resolveBindingDevices()
	self:migrateDevicesCategory()
	delete(xmlFileInputBinding)
	self:loadDefaultBindings()
	self:validateAndRepairComboActionBindings()
	self:storeComboInputMappings()
	self:assignComboMasks()
	self:assignActionPrimaryBindings()
	self:storeLinkedBindings()
	self:restoreInputContexts()
	self:notifyBindingChanges()
	self:refreshEventCollections()

	for k in pairs(self.newlyConnectedDevices) do
		self.newlyConnectedDevices[k] = nil
	end

	self:checkDefaultInputExclusiveActionBindings()
end

function InputBinding:loadDefaultBindings()
	if self.numGamepads > 0 then
		local requiredCategorySet = self:getRequiredDefaultBindingsCategories()

		for _, category in ipairs(InputBinding.DEVICE_CATEGORY_DEFAULT_LOAD_ORDER) do
			if requiredCategorySet[category] then
				local templatePath = InputBinding.DEVICE_CATEGORY_DEFAULTS_PATHS[category]
				local xmlFileControllerTemplate = loadXMLFile("ControllerTemplate", templatePath)
				local usedDevices = self:getAllDevicesWithBindings()

				self:loadActionBindingsFromXML(xmlFileControllerTemplate, true, nil, usedDevices)
				delete(xmlFileControllerTemplate)
			end
		end
	end

	self:loadModBindingDefaults()
end

function InputBinding:getRequiredDefaultBindingsCategories()
	local requiredCategorySet = {}
	local deviceId = 0
	local device = self.devicesByInternalId[deviceId]

	while device ~= nil do
		if not self:getDeviceHasAnyBindings(device) then
			requiredCategorySet[device.category] = true
		end

		deviceId = deviceId + 1
		device = self.devicesByInternalId[deviceId]
	end

	local hasWheel = requiredCategorySet[InputDevice.CATEGORY.WHEEL] ~= nil
	local hasFarmWheel = requiredCategorySet[InputDevice.CATEGORY.FARMWHEEL] ~= nil
	local hasPanel = requiredCategorySet[InputDevice.CATEGORY.FARMPANEL] ~= nil

	if (hasWheel or hasFarmWheel) and hasPanel then
		requiredCategorySet[InputDevice.CATEGORY.WHEEL] = nil
		requiredCategorySet[InputDevice.CATEGORY.FARMWHEEL] = nil
		requiredCategorySet[InputDevice.CATEGORY.FARMPANEL] = nil

		if hasFarmWheel then
			requiredCategorySet[InputDevice.CATEGORY.FARMWHEEL_AND_PANEL] = true
		else
			requiredCategorySet[InputDevice.CATEGORY.WHEEL_AND_PANEL] = true
		end
	end

	return requiredCategorySet
end

function InputBinding:getDeviceHasAnyBindings(device)
	for _, action in pairs(self.actions) do
		if InputBinding.GAMEPAD_COMBO_BINDINGS[action.name] == nil then
			for _, binding in pairs(action.bindings) do
				if binding.deviceId == device.deviceId then
					return true
				end
			end
		end
	end

	return false
end

function InputBinding:getAllDevicesWithBindings()
	local usedDevices = {}

	for _, action in pairs(self.actions) do
		if InputBinding.GAMEPAD_COMBO_BINDINGS[action.name] == nil then
			for _, binding in pairs(action.bindings) do
				usedDevices[binding.deviceId] = true
			end
		end
	end

	return usedDevices
end

function InputBinding:loadModActions()
	for _, modDesc in ipairs(self.modManager:getMods()) do
		local xmlFile = loadXMLFile("ModFile", modDesc.modFile)

		self:loadActions(xmlFile, modDesc.modName)
		delete(xmlFile)
	end
end

function InputBinding:loadModBindingDefaults()
	for _, modDesc in ipairs(self.modManager:getMods()) do
		local xmlFile = loadXMLFile("ModFile", modDesc.modFile)

		self:loadActionBindingsFromXML(xmlFile, true, modDesc.modName, nil, true)
		delete(xmlFile)
	end
end

function InputBinding:assignPlatformBindingPaths()
	if GS_PLATFORM_PLAYSTATION then
		self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS_PS4
	elseif GS_PLATFORM_XBOX then
		self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS_XBOX
	elseif GS_PLATFORM_ID == PlatformId.IOS then
		self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS_IOS
	elseif GS_PLATFORM_ID == PlatformId.ANDROID then
		self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS_ANDROID
	elseif GS_PLATFORM_SWITCH then
		self.settingsPath = InputBinding.PATHS.DEFAULT_BINDINGS_SWITCH
	else
		self.settingsPath = InputBinding.PATHS.USER_BINDINGS
		self.inputBindingPathTemplate = InputBinding.PATHS.DEFAULT_BINDINGS_KB_MOUSE

		if GS_PLATFORM_GGP then
			self.inputBindingPathTemplate = InputBinding.PATHS.DEFAULT_BINDINGS_KB_MOUSE_GGP
		end

		self:overwriteSettingsWithDefault(false)

		if not self:checkSettingsIntegrity(self.settingsPath, self.inputBindingPathTemplate) then
			self:overwriteSettingsWithDefault(true)
		end
	end
end

function InputBinding:overwriteSettingsWithDefault(forceOverwrite)
	copyFile(self.inputBindingPathTemplate, self.settingsPath, forceOverwrite)
end

function InputBinding:restoreInputContexts()
	for contextName, context in pairs(self.contexts) do
		local previousActionEvents = context.actionEvents
		local newActionEvents = {}

		for oldAction, eventList in pairs(previousActionEvents) do
			local newAction = self.nameActions[oldAction.name]
			newActionEvents[newAction] = eventList
		end

		if contextName == self.currentContextName then
			self.actionEvents = newActionEvents
		end

		context.actionEvents = newActionEvents
	end
end

function InputBinding:setShowMouseCursor(doShow, saveCursorPosition)
	self.saveCursorX = saveCursorPosition and self.mousePosXLast or 0.5
	self.saveCursorY = saveCursorPosition and self.mousePosYLast or 0.5
	self.mousePosXLast = nil
	self.mousePosYLast = nil

	setShowMouseCursor(doShow)

	self.wrapMousePositionEnabled = not doShow
end

function InputBinding:getShowMouseCursor()
	return not self.wrapMousePositionEnabled
end

function InputBinding:getInputHelpMode()
	local helpMode = GS_INPUT_HELP_MODE_GAMEPAD
	local nonGamepadMode = GS_IS_MOBILE_VERSION and GS_INPUT_HELP_MODE_TOUCH or GS_INPUT_HELP_MODE_KEYBOARD

	if not self.isConsoleVersion then
		if self.isGamepadEnabled then
			if self.inputHelpModeSetting == GS_INPUT_HELP_MODE_AUTO then
				helpMode = self.lastInputHelpMode
			elseif self.numGamepads > 0 and self.inputHelpModeSetting == GS_INPUT_HELP_MODE_GAMEPAD then
				helpMode = GS_INPUT_HELP_MODE_GAMEPAD
			else
				helpMode = nonGamepadMode
			end
		else
			helpMode = nonGamepadMode
		end
	end

	return helpMode
end

function InputBinding:getLastInputMode()
	if GS_PLATFORM_GGP and not getIsKeyboardAvailable() then
		return GS_INPUT_HELP_MODE_GAMEPAD
	end

	return self.lastInputMode
end

function InputBinding:validateActionEventParameters(actionName, targetObject, eventCallback, triggerUp, triggerDown, triggerAlways)
	local valid = true

	if InputAction[actionName] == nil then
		Logging.devWarning("Warning: Tried registering an event for an unknown action: %s", actionName)

		valid = false
	end

	if not targetObject then
		Logging.devWarning("Warning: Tried registering an action event without a target.")

		valid = false
	end

	if not eventCallback then
		Logging.devWarning("Warning: Tried registering an action event without an event callback.")

		valid = false
	end

	if not triggerUp and not triggerDown and not triggerAlways then
		Logging.devWarning("Warning: Tried registering an action event without any active trigger flags.")

		valid = false
	end

	local action = self.nameActions[actionName]

	if action ~= nil and not action:getIsSupportedOnCurrentPlatfrom() then
		return false
	end

	return valid
end

function InputBinding:registerActionEvent(actionName, targetObject, eventCallback, triggerUp, triggerDown, triggerAlways, startActive, callbackState, disableConflictingBindings, reportAnyDeviceCollision)
	local valid = self:validateActionEventParameters(actionName, targetObject, eventCallback, triggerUp, triggerDown, triggerAlways)
	local actionEvents = self.actionEvents
	local eventOrderCounter = self.contexts[self.currentContextName].eventOrderCounter

	if self.registrationContext ~= InputBinding.NO_REGISTRATION_CONTEXT then
		actionEvents = self.registrationContext.actionEvents
		eventOrderCounter = self.registrationContext.eventOrderCounter
	end

	if startActive then
		local eventCollision, collidingAction = self:checkEventCollision(actionName, disableConflictingBindings, reportAnyDeviceCollision)
		valid = valid and not eventCollision

		if eventCollision then
			return false, "", actionEvents[collidingAction]
		end
	end

	local eventId = ""

	if valid then
		local event = InputEvent.new(actionName, targetObject, eventCallback, triggerUp ~= nil and triggerUp, triggerDown ~= nil and triggerDown, triggerAlways ~= nil and triggerAlways, startActive ~= nil and startActive, callbackState, eventOrderCounter)
		local action = self.nameActions[actionName]
		local actionEventList = actionEvents[action]

		if actionEventList == nil then
			actionEventList = {}
			actionEvents[action] = actionEventList
		end

		local isFirstEventOnAction = #actionEventList == 0

		for _, regEvent in ipairs(actionEventList) do
			if regEvent.actionName == event.actionName and regEvent:getTriggerCode() == event:getTriggerCode() then
				return false, eventId, {
					regEvent
				}
			end
		end

		if valid then
			table.insert(actionEventList, event)

			self.events[event.id] = event
			eventId = event.id
			event.displayIsVisible = isFirstEventOnAction

			event:initializeDisplayText(action)
			event:setIgnoreComboMask(action:getIgnoreComboMask())

			if self.registrationContext == InputBinding.NO_REGISTRATION_CONTEXT then
				self:refreshEventCollections()

				self.contexts[self.currentContextName].eventOrderCounter = eventOrderCounter + 1
			else
				self.registrationContext.eventOrderCounter = eventOrderCounter + 1
			end
		end
	end

	return valid, eventId, nil
end

function InputBinding:checkEventCollision(actionName, disableConflictingBindings, reportAnyDeviceCollision)
	local testAction = self.nameActions[actionName]
	local testBindings = testAction:getBindings()
	local actionEvents = self.actionEvents

	if self.registrationContext ~= InputBinding.NO_REGISTRATION_CONTEXT then
		actionEvents = self.registrationContext.actionEvents
	end

	local collidingAction = nil
	local disabledBindings = {}

	for otherAction, events in pairs(actionEvents) do
		local isSameCategory = table.hasSetIntersection(testAction.categories, otherAction.categories)
		local isSelf = testAction == otherAction
		local isEitherLocked = testAction.isLocked or otherAction.isLocked
		local canConflict = not isSelf and isSameCategory and not isEitherLocked
		local otherHasActiveEvents = false

		for _, event in pairs(events) do
			if event.isActive then
				otherHasActiveEvents = true

				break
			end
		end

		if canConflict and otherHasActiveEvents then
			local otherBindings = otherAction:getActiveBindings()

			for _, testBinding in pairs(testBindings) do
				for _, otherBinding in pairs(otherBindings) do
					if testBinding:hasEventCollision(otherBinding) then
						if disableConflictingBindings then
							collidingAction = otherAction

							testAction:disableBinding(testBinding)
							table.insert(disabledBindings, testBinding)
						else
							return true, otherAction
						end
					end
				end
			end
		end
	end

	local hasCollision = false

	if #disabledBindings > 0 then
		if reportAnyDeviceCollision == true then
			return true, collidingAction
		end

		hasCollision = #testAction:getBindings() > 0 and testAction:getNumActiveBindings() == 0

		if hasCollision then
			for _, binding in pairs(disabledBindings) do
				testAction:enableBinding(binding)
			end
		end
	end

	return hasCollision, collidingAction
end

function InputBinding:beginActionEventsModification(inContextName, createNew)
	if inContextName == nil or inContextName == InputBinding.NO_REGISTRATION_CONTEXT.name then
		Logging.devWarning("Cannot begin action event registration with an empty context name.")
		printCallstack()

		return
	end

	local context = self.contexts[inContextName]

	if context == nil or createNew then
		context = self:createContext(inContextName)
	end

	if self.debugEnabled then
		Logging.devInfo("[InputBinding] Beginning action events modification in context [%s]", inContextName)
	end

	self.registrationContext = context
end

function InputBinding:endActionEventsModification(ignoreCheck)
	if not ignoreCheck and self.registrationContext == InputBinding.NO_REGISTRATION_CONTEXT then
		Logging.devWarning("Called InputBinding:endActionEventsModification() when the registration context is already reset. Check call order.")
		printCallstack()

		return
	end

	if self.debugEnabled then
		Logging.devInfo("[InputBinding] Ended action events modification in context [%s]", self.registrationContext.name)
	end

	self.registrationContext = InputBinding.NO_REGISTRATION_CONTEXT

	self:refreshEventCollections()
end

function InputBinding:refreshEventCollections()
	self:storeEventBindings()
	self:storeDisplayActionEvents()
	self:notifyEventChanges()
end

function InputBinding:storeDisplayActionEvents()
	self.displayActionEvents = {}

	for action, events in pairs(self.actionEvents) do
		for _, event in ipairs(events) do
			local bindings = action:getActiveBindings()

			if event.isActive and event.displayIsVisible and #bindings > 0 then
				local firstControllerBindingIndex = Binding.MAX_ALTERNATIVES_GAMEPAD + 1
				local firstGamepadBindingIndex = Binding.MAX_ALTERNATIVES_GAMEPAD + 1

				for _, binding in pairs(bindings) do
					local device = self.devicesByInternalId[binding.internalDeviceId]

					if binding.isActive and device.category ~= InputDevice.CATEGORY.KEYBOARD_MOUSE then
						if device.category == InputDevice.CATEGORY.GAMEPAD and binding.index < firstGamepadBindingIndex then
							firstGamepadBindingIndex = binding.index
						elseif binding.index < firstControllerBindingIndex then
							firstControllerBindingIndex = binding.index
						end
					end
				end

				local inlineModifierButtons = firstControllerBindingIndex < firstGamepadBindingIndex

				table.insert(self.displayActionEvents, {
					action = action,
					event = event,
					inlineModifierButtons = inlineModifierButtons
				})

				break
			end
		end
	end
end

local function sortEventByOrderValue(event1, event2)
	if event1.orderValue == event2.orderValue then
		return event1.id < event2.id
	else
		return event1.orderValue < event2.orderValue
	end
end

function InputBinding:storeEventBindings()
	for k in pairs(self.activeBindings) do
		self.activeBindings[k] = nil
	end

	for k in pairs(self.eventBindings) do
		self.eventBindings[k] = nil
	end

	for k in pairs(self.eventOrder) do
		self.eventOrder[k] = nil
	end

	for action, eventList in pairs(self.actionEvents) do
		local bindings = action:getActiveBindings()

		for _, event in pairs(eventList) do
			if event.isActive then
				local activeEventBindings = self.eventBindings[event]

				if not activeEventBindings then
					activeEventBindings = {}
					self.eventBindings[event] = activeEventBindings
				end

				for _, binding in ipairs(bindings) do
					if binding.isActive then
						table.insert(activeEventBindings, binding)

						self.activeBindings[binding] = binding
					end
				end

				table.insert(self.eventOrder, event)
			end
		end
	end

	table.sort(self.eventOrder, sortEventByOrderValue)

	self.needUpdateAbort = true
end

function InputBinding:iterateEvents(processingFunction)
	local actionEvents = self.actionEvents

	if self.registrationContext ~= InputBinding.NO_REGISTRATION_CONTEXT then
		actionEvents = self.registrationContext.actionEvents
	end

	for action, eventList in pairs(actionEvents) do
		for i = #eventList, 1, -1 do
			local event = eventList[i]

			if processingFunction(event, action.name, eventList, i) then
				return
			end
		end
	end
end

function InputBinding:removeEventInternal(event, eventList, index)
	if event.triggerAlways then
		local eventBindings = self.eventBindings[event]

		if eventBindings ~= nil then
			for _, binding in pairs(eventBindings) do
				self:neutralizeEventBindingInput(event, binding)
			end
		end
	end

	self.events[event.id] = nil

	table.remove(eventList, index)
end

function InputBinding:removeActionEvent(eventId)
	local hasChange = false

	local function removeById(event, _, eventList, index)
		if event.id == eventId then
			self:removeEventInternal(event, eventList, index)

			hasChange = true

			return true
		end
	end

	self:iterateEvents(removeById)

	if hasChange then
		self:refreshEventCollections()
	end
end

function InputBinding:removeActionEventsByActionName(actionName)
	local hasChange = false

	local function removeByName(event, _, eventList, index)
		if event.actionName == actionName then
			self:removeEventInternal(event, eventList, index)

			hasChange = true
		end
	end

	self:iterateEvents(removeByName)

	if hasChange then
		self:refreshEventCollections()
	end
end

function InputBinding:removeActionEventsByTarget(targetObject)
	local hasChange = false

	local function removeByTarget(event, _, eventList, index)
		if event.targetObject == targetObject then
			self:removeEventInternal(event, eventList, index)

			hasChange = true
		end
	end

	self:iterateEvents(removeByTarget)

	if hasChange then
		self:refreshEventCollections()
	end
end

function InputBinding:getActionEventsHasBinding(actionEventId)
	local event = self.events[actionEventId]

	if self.events[actionEventId] ~= nil then
		local eventBinding = self.eventBindings[event]

		if eventBinding ~= nil then
			return #eventBinding > 0
		end
	end

	return false
end

function InputBinding:getDisplayActionEvents()
	return self.displayActionEvents
end

function InputBinding:setActionEventText(eventId, actionText)
	local event = self.events[eventId]
	local hasChange = false

	if event then
		hasChange = event.contextDisplayText ~= actionText
		event.contextDisplayText = actionText
	end

	if hasChange then
		self:refreshEventCollections()
	end
end

function InputBinding:setActionEventIcon(eventId, iconName)
	local event = self.events[eventId]
	local hasChange = false

	if event then
		hasChange = event.contextDisplayIconName ~= iconName
		event.contextDisplayIconName = iconName
	end

	if hasChange then
		self:refreshEventCollections()
	end
end

function InputBinding:setActionEventTextVisibility(eventId, isVisible)
	local event = self.events[eventId]
	local hasChange = false

	if event then
		hasChange = event.displayIsVisible ~= isVisible
		event.displayIsVisible = isVisible
	end

	if hasChange then
		self:refreshEventCollections()
	end
end

function InputBinding:setActionEventTextPriority(eventId, priority)
	local event = self.events[eventId]
	local hasChange = false

	if event and type(priority) == "number" then
		hasChange = event.displayPriority ~= priority
		event.displayPriority = priority
	end

	if hasChange then
		self:refreshEventCollections()
	end
end

function InputBinding:setActionEventActive(eventId, isActive)
	local event = self.events[eventId]
	local hasChange = false

	if event then
		hasChange = event.isActive ~= isActive
		event.isActive = isActive

		if hasChange then
			if isActive then
				self:checkEventCollision(event.actionName, true)
			else
				self.nameActions[event.actionName]:resetActiveBindings()
			end
		end
	end

	if hasChange then
		self:refreshEventCollections()
	end
end

function InputBinding:setActionEventsActiveByTarget(targetObject, isActive)
	local hasChange = false

	local function setActiveByTarget(event)
		if event.targetObject == targetObject then
			hasChange = event.isActive ~= isActive
			event.isActive = isActive

			if hasChange then
				if isActive then
					self:checkEventCollision(event.actionName, true)
				else
					self.nameActions[event.actionName]:resetActiveBindings()
				end
			end
		end
	end

	self:iterateEvents(setActiveByTarget)

	if hasChange then
		self:refreshEventCollections()
	end
end

function InputBinding:getComboCommandPressedMask()
	local comboMaskGamepad = 0
	local comboMaskMouse = 0

	if self.numGamepads > 0 then
		for actionName, maskControls in pairs(InputBinding.GAMEPAD_COMBOS) do
			local comboActionBinding = self.comboInputBindings[actionName]

			if comboActionBinding ~= nil and comboActionBinding.isPressed and comboMaskGamepad < maskControls.mask then
				comboMaskGamepad = maskControls.mask
			end
		end
	end

	if not self.isConsoleVersion then
		for actionName, maskControls in pairs(InputBinding.MOUSE_COMBOS) do
			if self.comboInputBindings[actionName].isPressed and comboMaskMouse < maskControls.mask then
				comboMaskMouse = maskControls.mask
			end
		end
	end

	return comboMaskGamepad, comboMaskMouse
end

function InputBinding:getComboActionNameForAxisSet(modifierAxisSet)
	for comboSet, comboActionName in pairs(self.comboInputActions) do
		if table.equalSets(comboSet, modifierAxisSet) then
			return comboActionName
		end
	end
end

function InputBinding:getInternalIdByDeviceId(deviceId)
	return self.deviceIdToInternal[deviceId]
end

function InputBinding:getDeviceByInternalId(internalDeviceId)
	return self.devicesByInternalId[internalDeviceId]
end

function InputBinding:getDeviceById(deviceId)
	local device = nil
	local internalId = self.deviceIdToInternal[deviceId]

	if internalId ~= nil then
		device = self.devicesByInternalId[internalId]
	end

	return device
end

function InputBinding:getMissingDeviceById(deviceId)
	return self.missingDevices[deviceId]
end

function InputBinding:getHasMissingDevices()
	return next(self.missingDevices) ~= nil
end

function InputBinding:assignLastInputHelpMode(inputHelpMode, force)
	local needCurrentInputModeNotification = self.lastInputMode ~= inputHelpMode or force
	self.lastInputMode = inputHelpMode

	if needCurrentInputModeNotification then
		self:notifyInputModeChange(inputHelpMode, false)
	end

	if inputHelpMode == GS_INPUT_HELP_MODE_KEYBOARD or InputBinding.INPUT_MODE_CHANGE_MIN_INTERVAL <= self.timeSinceLastInputHelpModeChange or GS_PLATFORM_GGP then
		local needInputHelpModeNotification = self.lastInputHelpMode ~= inputHelpMode or force
		self.lastInputHelpMode = inputHelpMode

		if needInputHelpModeNotification then
			self:notifyInputModeChange(inputHelpMode, true)
		end

		if needInputHelpModeNotification or inputHelpMode == GS_INPUT_HELP_MODE_KEYBOARD then
			self.timeSinceLastInputHelpModeChange = 0
		end
	end

	if GS_IS_MOBILE_VERSION and self.lastInputHelpMode == GS_INPUT_HELP_MODE_KEYBOARD then
		self.lastInputHelpMode = GS_INPUT_HELP_MODE_TOUCH
	end
end

function InputBinding:keyEvent(unicode, sym, modifier, isDown)
	if GS_PLATFORM_GGP and g_isStadiaSimulationActive and sym == Input.KEY_6 then
		return
	end

	self:assignLastInputHelpMode(GS_INPUT_HELP_MODE_KEYBOARD)
end

function InputBinding:mouseEvent(posX, posY, isDown, isUp, button)
	if isDown then
		self:assignLastInputHelpMode(GS_IS_MOBILE_VERSION and GS_INPUT_HELP_MODE_TOUCH or GS_INPUT_HELP_MODE_KEYBOARD)
	end

	if self.mousePosXLast == nil or self.mousePosYLast == nil then
		self.mousePosXLast = posX
		self.mousePosYLast = posY
	end

	self.mouseMovementX = self.mouseMotionScaleX * (posX - self.mousePosXLast)
	self.mouseMovementY = self.mouseMotionScaleY * (posY - self.mousePosYLast) / g_screenAspectRatio
	self.mousePosXLast = posX
	self.mousePosYLast = posY
	self.accumMouseMovementX = self.accumMouseMovementX + self.mouseMovementX
	self.accumMouseMovementY = self.accumMouseMovementY + self.mouseMovementY

	if isDown then
		self.mouseButtonLast = button
		self.mouseButtonStateLast = true
	elseif isUp then
		self.mouseButtonLast = Input.MOUSE_BUTTON_NONE
		self.mouseButtonStateLast = false
	end
end

function InputBinding:touchEvent(posX, posY, isDown, isUp, touchId)
	self:assignLastInputHelpMode(GS_INPUT_HELP_MODE_TOUCH)
end

function InputBinding:getMousePosition()
	return self.mousePosXLast or self.saveCursorX, self.mousePosYLast or self.saveCursorY
end

function InputBinding:getMouseButtonState()
	return self.mouseButtonLast, self.mouseButtonStateLast
end

function InputBinding:startBindingChanges()
	self.originalActionBindings = {}

	for _, action in pairs(self.actions) do
		local bindings = action:getBindings()
		local clonedBindings = {}

		for _, binding in pairs(bindings) do
			table.insert(clonedBindings, binding:clone())
		end

		self.originalActionBindings[action] = clonedBindings
	end
end

function InputBinding:commitBindingChanges()
	self.originalActionBindings = nil

	self:assignComboMasks()
	self:assignActionPrimaryBindings()
	self:notifyBindingChanges()
	self:refreshEventCollections()
end

function InputBinding:rollbackBindingChanges()
	local newLoadedBindings = {}

	for _, bindings in pairs(self.originalActionBindings) do
		for _, binding in pairs(bindings) do
			binding:makeId()

			local loadedBinding = newLoadedBindings[binding.id]

			if loadedBinding == nil then
				newLoadedBindings[binding.id] = binding
			else
				binding = loadedBinding
			end

			local oldLoadedBinding = self.loadedBindings[binding.id]

			if oldLoadedBinding ~= nil then
				binding:copyInputStateFrom(oldLoadedBinding)
			end
		end
	end

	self.loadedBindings = newLoadedBindings

	for action, originalBindings in pairs(self.originalActionBindings) do
		action:clearBindings()

		for _, originalBinding in pairs(originalBindings) do
			local newBinding = self.loadedBindings[originalBinding.id]

			action:addBinding(newBinding)
		end
	end

	self:storeEventBindings()
end

function InputBinding:startInputCapture(isKeyboard, isMouse, callbackTarget, callbackState, inputCallback, abortCallback, deleteCallback)
	self.isInputCapturing = true
	self.gatherInputStoredMouseEvent = mouseEvent
	self.gatherInputStoredKeyEvent = keyEvent
	self.gatherInputStoredUpdate = update

	local function cbInput(deviceId, axisName, inputValue, initInputValue)
		if callbackTarget then
			inputCallback(callbackTarget, deviceId, axisName, inputValue, initInputValue, callbackState)
		else
			inputCallback(axisName, deviceId, inputValue, initInputValue, callbackState)
		end
	end

	local function cbAbort()
		if callbackTarget then
			abortCallback(callbackTarget)
		else
			abortCallback()
		end
	end

	local function cbDelete()
		if callbackTarget then
			deleteCallback(callbackTarget, callbackState)
		else
			deleteCallback(callbackState)
		end
	end

	if isKeyboard then
		self:captureKeyboardInput(cbAbort, cbDelete, cbInput)

		function mouseEvent()
		end

		function update()
		end
	elseif isMouse then
		self:captureKeyboardInput(cbAbort, cbDelete)
		self:captureMouseInput(cbInput)

		function update()
		end
	else
		self:captureKeyboardInput(cbAbort, cbDelete)
		self:captureGamepadInput(cbInput)

		function mouseEvent()
		end
	end
end

function InputBinding:captureKeyboardInput(abortCallback, deleteCallback, inputCallback)
	local device = InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT

	function keyEvent(unicode, sym, modifier, isDown)
		local keyName = Input.keyIdToIdName[sym]

		if abortCallback and sym == Input.KEY_esc then
			abortCallback()
		elseif deleteCallback and sym == Input.KEY_backspace then
			deleteCallback()
		elseif inputCallback and keyName then
			inputCallback(device, keyName, isDown and 1 or 0)
		end
	end
end

function InputBinding:captureMouseInput(callback)
	local dragStartX, dragStartY, draggingButton = nil
	local startX = self.mousePosXLast
	local startY = self.mousePosYLast
	local device = InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
	local axisNameX = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_X]
	local axisNameY = InputBinding.MOUSE_AXIS_NAMES[Input.AXIS_Y]

	callback(device, axisNameX, false, 0)
	callback(device, axisNameY, false, 0)

	function mouseEvent(posX, posY, isDown, isUp, button)
		local buttonName = Input.mouseButtonIdToIdName[button]

		if button ~= Input.MOUSE_BUTTON_WHEEL_UP and button ~= Input.MOUSE_BUTTON_WHEEL_DOWN then
			if isDown then
				if draggingButton == nil then
					draggingButton = button
					dragStartY = posY
					dragStartX = posX

					callback(device, axisNameX, 0)
					callback(device, axisNameY, 0)
				end

				callback(device, buttonName, 1)
			elseif isUp then
				local buttonIsDragging = button == draggingButton

				callback(device, buttonName, 0)

				if buttonIsDragging then
					draggingButton = nil
					dragStartX = nil
					dragStartY = nil
				end
			end
		else
			callback(device, buttonName, 1)
			callback(device, buttonName, 0)
		end

		if draggingButton ~= nil then
			startY = posY
			startX = posX
		end

		local origX = startX
		local origY = startY

		if draggingButton ~= nil then
			origY = dragStartY
			origX = dragStartX
		end

		local axisX = posX - origX
		local axisY = posY - origY

		callback(device, axisNameX, axisX)
		callback(device, axisNameY, axisY)
	end
end

function InputBinding:captureGamepadInput(callback)
	local gamepadInitStates = {}

	function update(dt)
		local numGamepads = getNumOfGamepads()

		if numGamepads ~= #gamepadInitStates then
			for k, _ in pairs(gamepadInitStates) do
				gamepadInitStates[k] = nil
			end

			for d = 1, numGamepads do
				local initState = {
					axes = {},
					buttons = {}
				}

				table.insert(gamepadInitStates, initState)

				for i = 1, Input.MAX_NUM_BUTTONS do
					local isDown = getInputButton(i - 1, d - 1) > 0

					if isDown then
						initState.buttons[i] = true
					end
				end

				for i = 1, Input.MAX_NUM_AXES do
					initState.axes[i] = getInputAxis(i - 1, d - 1)

					if Input.isHalfAxis(i - 1) then
						initState.axes[i] = (1 - initState.axes[i]) * 0.5
					end
				end
			end
		end

		for d = 1, numGamepads do
			local deviceId = self.internalToDeviceId[d - 1]
			local initState = gamepadInitStates[d]
			local axes = {}
			local buttons = {}

			for i = 1, Input.MAX_NUM_AXES do
				local input = getInputAxis(i - 1, d - 1)
				local axisInit = initState.axes[i]

				if Input.isHalfAxis(i - 1) then
					input = (1 - input) * 0.5
				end

				local axisName = Input.axisIdToIdName[i - 1]

				callback(deviceId, axisName, input, axisInit)
			end

			for i = 1, Input.MAX_NUM_BUTTONS do
				local buttonName = Input.buttonIdToIdName[i - 1]
				local isDown = getInputButton(i - 1, d - 1) > 0

				if isDown then
					if not initState.buttons[i] then
						buttons[i - 1] = true

						callback(deviceId, buttonName, 1, 0)
					end
				else
					initState.buttons[i] = nil

					callback(deviceId, buttonName, 0, 0)
				end
			end
		end
	end
end

function InputBinding:stopInputGathering()
	if self.isInputCapturing then
		mouseEvent = self.gatherInputStoredMouseEvent
		keyEvent = self.gatherInputStoredKeyEvent
		update = self.gatherInputStoredUpdate
		self.gatherInputCallbackFunction = nil
		self.gatherInputCallbackObject = nil
		self.gatherInputStoredMouseEvent = nil
		self.gatherInputStoredKeyEvent = nil
		self.gatherInputStoredUpdate = nil
		self.isInputCapturing = false
	end
end

function InputBinding:restoreDefaultBindings()
	copyFile(self.inputBindingPathTemplate, self.settingsPath, true)
	self:load()
end

function InputBinding:clearState()
	self.loadedBindings = {}
	self.eventBindings = {}
	self.nameActions = {}
	self.actions = {}
	self.missingDevices = {}
	self.gamepadInputState = {}
	local defaultInputMode = GS_INPUT_HELP_MODE_KEYBOARD

	if self.isConsoleVersion then
		defaultInputMode = GS_INPUT_HELP_MODE_GAMEPAD
	elseif GS_IS_MOBILE_VERSION then
		defaultInputMode = GS_INPUT_HELP_MODE_TOUCH
	end

	self.lastInputMode = defaultInputMode
	self.lastInputHelpMode = defaultInputMode
end

function InputBinding:loadActions(xmlFile, modName)
	local rootPath = "actions"
	local i18n = g_i18n

	if modName then
		rootPath = "modDesc.actions"
		i18n = _G[modName].g_i18n
	end

	local actionIndex = 0

	while true do
		local actionPath = rootPath .. string.format(".action(%d)", actionIndex)

		if not hasXMLProperty(xmlFile, actionPath) then
			break
		end

		local action = InputAction.createFromXML(xmlFile, actionPath)

		if action ~= nil then
			local inputSymbol = string.format("input_%s", action.name)
			local modPart = modName and string.format(" in mod '%s'", modName) or ""

			if modName ~= nil then
				action.displayCategory = g_modManager:getModByName(modName).title
			end

			action.displayNamePositive = action.name
			action.displayNameNegative = action.name
			local isComboAction = InputBinding.MOUSE_COMBOS[action.name] ~= nil and InputBinding.GAMEPAD_COMBOS[action.name] ~= nil
			local isLocked = action.isLocked
			local needLocalization = not isComboAction and not isLocked

			if action.axisType == InputAction.AXIS_TYPE.FULL then
				local symbolPositive = inputSymbol .. InputBinding.SYMBOL_AFFIX_POSITIVE
				local symbolNegative = inputSymbol .. InputBinding.SYMBOL_AFFIX_NEGATIVE

				if i18n:hasText(symbolPositive) then
					action.displayNamePositive = i18n:getText(symbolPositive)
				elseif needLocalization then
					Logging.warning("Missing l10n '%s'%s", symbolPositive, modPart)
				end

				if i18n:hasText(symbolNegative) then
					action.displayNameNegative = i18n:getText(symbolNegative)
				elseif needLocalization then
					Logging.warning("Missing l10n '%s'%s", symbolNegative, modPart)
				end
			elseif i18n:hasText(inputSymbol) then
				action.displayNamePositive = i18n:getText(inputSymbol)
			elseif needLocalization then
				Logging.warning("Missing l10n '%s'%s", inputSymbol, modPart)
			end

			table.insert(self.actions, action)

			self.nameActions[action.name] = action
		end

		actionIndex = actionIndex + 1
	end
end

function InputBinding:resetDeviceInformation()
	local previousDevices = self.devicesByInternalId
	self.devicesByInternalId = {}
	self.devicesByCategory = {}
	self.deviceIdToInternal = {}
	self.internalToDeviceId = {}

	return previousDevices
end

function InputBinding:createDefaultDevices()
	local kbMouseDevice = InputDevice.new(InputBinding.KB_MOUSE_INTERNAL_ID, InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT, InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT, InputDevice.CATEGORY.KEYBOARD_MOUSE)
	kbMouseDevice.isActive = not self.isConsoleVersion
	self.devicesByInternalId[InputBinding.KB_MOUSE_INTERNAL_ID] = kbMouseDevice
	self.devicesByCategory[InputDevice.CATEGORY.KEYBOARD_MOUSE] = {
		kbMouseDevice
	}
	self.deviceIdToInternal[kbMouseDevice.deviceId] = InputBinding.KB_MOUSE_INTERNAL_ID
end

function InputBinding:enumerateGamepadDevices(previousDevices)
	self.engineDeviceIdCounts = {}
	self.numGamepads = getNumOfGamepads()
	self.internalIdToEngineDeviceId = {}

	for internalId = 0, self.numGamepads - 1 do
		local engineDeviceId = getGamepadId(internalId)
		local deviceName = getGamepadName(internalId)
		self.internalIdToEngineDeviceId[internalId] = engineDeviceId

		if InputDevice.getIsDeviceSupported(engineDeviceId, deviceName) then
			local existingPrefix, baseDeviceId = InputDevice.getDeviceIdPrefix(engineDeviceId)

			if existingPrefix < 0 then
				baseDeviceId = engineDeviceId
			end

			local count = self.engineDeviceIdCounts[baseDeviceId]
			count = count or 0
			self.engineDeviceIdCounts[baseDeviceId] = count + 1
			local uniqueDeviceId = ""

			if existingPrefix >= 0 then
				uniqueDeviceId = engineDeviceId
			else
				uniqueDeviceId = InputDevice.getPrefixedDeviceId(baseDeviceId, count)
			end

			self.deviceIdToInternal[uniqueDeviceId] = internalId
			self.internalToDeviceId[internalId] = uniqueDeviceId
			local deviceCategory = InputBinding.getDeviceCategory(internalId)
			local device = InputDevice.new(internalId, uniqueDeviceId, deviceName, deviceCategory)
			self.devicesByInternalId[internalId] = device

			if not self.devicesByCategory[deviceCategory] then
				self.devicesByCategory[deviceCategory] = {}
			end

			table.insert(self.devicesByCategory[deviceCategory], device)
		end
	end

	for _, device in pairs(previousDevices) do
		if not self.deviceIdToInternal[device.deviceId] then
			device.internalId = -1
			self.missingDevices[device.deviceId] = device
		end
	end
end

function InputBinding:getGamepadDevices()
	local deviceList = {}

	for _, device in pairs(self.devicesByInternalId) do
		if device:isController() then
			table.insert(deviceList, {
				deviceId = device.deviceId,
				name = device.deviceName
			})
		end
	end

	return deviceList
end

function InputBinding:loadDeviceSettingsFromXML(xmlFile)
	local hasLoadedDevice = {}
	local elementIndex = 0

	while true do
		local deviceElement = string.format("inputBinding.devices.device(%d)", elementIndex)

		if not hasXMLProperty(xmlFile, deviceElement) then
			break
		end

		local deviceId = InputDevice.loadIdFromXML(xmlFile, deviceElement)
		hasLoadedDevice[deviceId] = true
		local deviceInternalId = self.deviceIdToInternal[deviceId]

		if deviceInternalId then
			local device = self.devicesByInternalId[deviceInternalId]

			device:loadSettingsFromXML(xmlFile, deviceElement)

			local xmlCategory = InputDevice.loadCategoryFromXML(xmlFile, deviceElement)

			if xmlCategory == InputDevice.CATEGORY.UNKNOWN and xmlCategory ~= device.category then
				self.devicesToMigrateCategory[deviceId] = device
			end
		elseif deviceId and deviceId ~= "" then
			local missingDeviceCategory = InputDevice.loadCategoryFromXML(xmlFile, deviceElement)
			local missingDeviceName = InputDevice.loadNameFromXML(xmlFile, deviceElement)
			local device = InputDevice.new(-1, deviceId, missingDeviceName, missingDeviceCategory)

			device:loadSettingsFromXML(xmlFile, deviceElement)

			self.missingDevices[deviceId] = device
		end

		elementIndex = elementIndex + 1
	end

	for deviceId in pairs(self.deviceIdToInternal) do
		if not hasLoadedDevice[deviceId] then
			self.newlyConnectedDevices[deviceId] = true
		end
	end
end

function InputBinding:applyGamepadDeadzones()
	if GS_PLATFORM_PC then
		for _, device in pairs(self.devicesByInternalId) do
			if device:isController() then
				for axis = 0, Input.MAX_NUM_AXES - 1 do
					setGamepadDeadzone(0, device.internalId, axis)
				end
			end
		end
	end
end

function InputBinding:initializeGamepadMapping(xmlFile)
	local previousDevices = self:resetDeviceInformation()

	self:createDefaultDevices()
	self:enumerateGamepadDevices(previousDevices)

	if xmlFile ~= nil then
		self:loadDeviceSettingsFromXML(xmlFile)
	end

	self:applyGamepadDeadzones()
end

function InputBinding:validateAndRepairComboActionBindings()
	for _, action in pairs(self.actions) do
		local bindings = action:getBindings()
		local comboAxisNames = nil
		local comboBindingIndex = 1
		local comboBindingDevice = nil
		local comboBindingDeviceCategory = InputDevice.CATEGORY.UNKNOWN

		if self.numGamepads > 0 and InputBinding.GAMEPAD_COMBO_BINDINGS[action.name] then
			comboAxisNames = InputBinding.GAMEPAD_COMBO_BINDINGS[action.name]
			comboBindingDevice = InputDevice.DEFAULT_DEVICE_NAMES.GAMEPAD_DEFAULT
		elseif not self.isConsoleVersion and InputBinding.MOUSE_COMBO_BINDINGS[action.name] then
			comboAxisNames = InputBinding.MOUSE_COMBO_BINDINGS[action.name]
			comboBindingIndex = Binding.MAX_ALTERNATIVES_KB_MOUSE
			comboBindingDevice = InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
		end

		if comboAxisNames then
			local axisNames = table.copy(comboAxisNames)

			for k in pairs(bindings) do
				bindings[k] = nil
			end

			local newBinding = Binding.new(comboBindingDevice, axisNames, Binding.AXIS_COMPONENT.POSITIVE, Binding.INPUT_COMPONENT.POSITIVE, 0, comboBindingIndex)

			table.insert(bindings, newBinding)

			local comboBinding = bindings[1]
			local internalDeviceId = self.deviceIdToInternal[comboBinding.deviceId]

			if internalDeviceId ~= nil then
				comboBindingDevice = comboBinding.deviceId
				comboBindingDeviceCategory = self.devicesByInternalId[internalDeviceId].category
			end

			comboBinding:setIndex(comboBindingIndex)
			comboBinding:updateData(comboBindingDevice, comboBindingDeviceCategory, axisNames, Binding.INPUT_COMPONENT.POSITIVE)

			local couldResolve = self:resolveBindingDefaultDevice(comboBinding, nil)

			comboBinding:setActive(couldResolve)
			comboBinding:makeId()
		end
	end
end

function InputBinding:loadActionBindingsFromXML(xmlFile, silentIgnoreDuplicates, modName, disallowedDeviceIds, requireUnknownBindings)
	local rootPath = "inputBinding"

	if modName then
		rootPath = "modDesc.inputBinding"
	end

	local actionIndex = 0

	while true do
		local actionPath = string.format("%s.actionBinding(%d)", rootPath, actionIndex)

		if not hasXMLProperty(xmlFile, actionPath) then
			break
		end

		local actionName = getXMLString(xmlFile, actionPath .. "#action")

		if actionName and actionName ~= "" then
			local action = self.nameActions[actionName]

			if action and (not action.bindingsKnown or not requireUnknownBindings) then
				action.bindingsKnown = true

				self:loadBindingsFromXML(xmlFile, actionPath, action, silentIgnoreDuplicates, disallowedDeviceIds)
			end
		end

		actionIndex = actionIndex + 1
	end
end

function InputBinding:loadBindingsFromXML(xmlFile, actionPath, action, silentIgnoreDuplicates, disallowedDeviceIds)
	local bindingIndex = 0

	while true do
		local bindingPath = actionPath .. string.format(".binding(%d)", bindingIndex)

		if not hasXMLProperty(xmlFile, bindingPath) then
			break
		end

		local binding = Binding.createFromXML(xmlFile, bindingPath)

		if self:resolveBindingDefaultDevice(binding, disallowedDeviceIds) then
			self:addBinding(action, binding, silentIgnoreDuplicates)
		end

		bindingIndex = bindingIndex + 1
	end
end

function InputBinding:storeComboInputMappings()
	self.comboInputAxisMasks = {}
	self.comboInputActions = {}
	self.comboInputBindings = {}
	local combos = {
		InputBinding.GAMEPAD_COMBOS
	}

	if not self.isConsoleVersion then
		combos = {
			InputBinding.GAMEPAD_COMBOS,
			InputBinding.MOUSE_COMBOS
		}
	end

	for _, deviceCombos in pairs(combos) do
		for comboActionName, combo in pairs(deviceCombos) do
			local comboAction = self.nameActions[comboActionName]

			if comboAction then
				local validComboBinding = nil

				for _, binding in ipairs(comboAction:getBindings()) do
					if binding.isActive then
						local device = self.devicesByInternalId[binding.internalDeviceId]

						if device.category == InputDevice.CATEGORY.GAMEPAD or binding.isMouse then
							validComboBinding = binding

							break
						end
					end
				end

				if validComboBinding ~= nil then
					self.comboInputAxisMasks[validComboBinding.axisNameSet] = combo.mask
					self.comboInputActions[validComboBinding.axisNameSet] = comboActionName
					self.comboInputBindings[comboActionName] = validComboBinding
				end
			end
		end
	end
end

function InputBinding:getBindingComboMask(binding)
	for comboSet, mask in pairs(self.comboInputAxisMasks) do
		if table.equalSets(comboSet, binding.modifierAxisSet) then
			return mask
		end
	end

	return 0
end

function InputBinding:assignComboMasks()
	for _, action in pairs(self.actions) do
		local bindings = action:getActiveBindings()
		action.comboMaskMouse = 0
		action.comboMaskGamepad = 0

		for _, binding in pairs(bindings) do
			local bindingComboMask = self:getBindingComboMask(binding)

			if binding.isMouse then
				if InputBinding.MOUSE_COMBOS[action.name] == nil then
					action.comboMaskMouse = bindingComboMask

					binding:setComboMask(bindingComboMask)
				end
			elseif binding.isActive then
				local device = self.devicesByInternalId[binding.internalDeviceId]
				local isPrimaryGamepadBinding = device.category == InputDevice.CATEGORY.GAMEPAD and binding.isGamepad
				local isNotComboAction = InputBinding.GAMEPAD_COMBOS[action.name] == nil

				if isPrimaryGamepadBinding and isNotComboAction then
					action.comboMaskGamepad = bindingComboMask

					binding:setComboMask(bindingComboMask)
				end
			end
		end
	end
end

function InputBinding:storeLinkedBindings()
	for _, action in pairs(self.actions) do
		local linkedActionName = InputAction.LINKED_ACTIONS[action.name]

		if linkedActionName ~= nil then
			local linkedAction = self.nameActions[linkedActionName]

			for _, binding in pairs(action:getBindings()) do
				local links = self.linkedBindings[binding]

				if links == nil then
					links = {}
					self.linkedBindings[binding] = links
				end

				local linkedBindings = linkedAction:getBindings()

				for _, linkedBinding in pairs(linkedBindings) do
					if linkedBinding.deviceId == binding.deviceId and linkedBinding.index == binding.index then
						table.insert(links, linkedBinding)
					end
				end
			end
		end
	end
end

function InputBinding:assignActionPrimaryBindings()
	for _, action in pairs(self.actions) do
		local bindings = action:getActiveBindings()

		for _, binding in pairs(bindings) do
			if binding.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT and binding.index == 1 then
				action:setPrimaryKeyboardBinding(binding)
			end
		end
	end
end

function InputBinding:adjustBindingSlotIndex(binding, action)
	if binding.index >= 1 then
		return true
	end

	local isKbMouse = binding.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT

	if isKbMouse and InputBinding.getIsMouseInput(binding.axisNames) then
		if action:getBindingAtSlot(binding.axisComponent, isKbMouse, Binding.MAX_ALTERNATIVES_KB_MOUSE) == nil then
			binding:setIndex(Binding.MAX_ALTERNATIVES_KB_MOUSE)

			return true
		end
	else
		local maxBindings = nil

		if isKbMouse then
			maxBindings = Binding.MAX_ALTERNATIVES_KB_MOUSE - 1
		else
			maxBindings = Binding.MAX_ALTERNATIVES_GAMEPAD
		end

		for i = 1, maxBindings do
			if action:getBindingAtSlot(binding.axisComponent, isKbMouse, i) == nil then
				binding:setIndex(i)

				return true
			end
		end
	end

	return false
end

function InputBinding:upgradeBindingVersion(xmlFileInputBinding)
	local bindingVersion = Utils.getNoNil(getXMLInt(xmlFileInputBinding, "inputBinding#bindingVersion"), 0)

	if bindingVersion == 0 then
		for _, action in pairs(self.actions) do
			local bindingsCopy = {}

			for bindingI, binding in pairs(action.bindings) do
				bindingsCopy[bindingI] = binding
			end

			for _, binding in pairs(bindingsCopy) do
				if binding.isGamepad then
					local device = nil
					local internalId = self.deviceIdToInternal[binding.deviceId]

					if internalId then
						device = self.devicesByInternalId[internalId]
					end

					device = device or self.missingDevices[binding.deviceId]

					if device and device.category == InputDevice.CATEGORY.UNKNOWN then
						local newAxisNames = {}
						local changed = false

						for _, axisName in ipairs(binding.axisNames) do
							local newAxisName = axisName
							local axisNameNoSign = axisName
							local sign = axisName:sub(axisName:len())

							if sign == "+" or sign == "-" then
								axisNameNoSign = axisName:sub(1, axisName:len() - 1)
							else
								sign = ""
							end

							if axisNameNoSign == "HALF_AXIS_1" or axisNameNoSign == "AXIS_11" then
								newAxisName = "AXIS_2-"
								changed = true
							elseif axisNameNoSign == "HALF_AXIS_2" or axisNameNoSign == "AXIS_12" then
								newAxisName = "AXIS_2+"
								changed = true
							elseif axisNameNoSign == "AXIS_2" then
								newAxisName = "AXIS_7" .. sign
								changed = true
							elseif axisNameNoSign == "AXIS_7" then
								newAxisName = "AXIS_8" .. sign
								changed = true
							elseif axisNameNoSign == "BUTTON_21" then
								newAxisName = "BUTTON_25"
								changed = true
							elseif axisNameNoSign == "BUTTON_22" then
								newAxisName = "BUTTON_26"
								changed = true
							elseif axisNameNoSign == "BUTTON_23" then
								newAxisName = "BUTTON_27"
								changed = true
							elseif axisNameNoSign == "BUTTON_24" then
								newAxisName = "BUTTON_28"
								changed = true
							elseif axisNameNoSign == "BUTTON_25" then
								newAxisName = "BUTTON_29"
								changed = true
							elseif axisNameNoSign == "BUTTON_26" then
								newAxisName = "BUTTON_30"
								changed = true
							elseif axisNameNoSign == "BUTTON_27" then
								newAxisName = "BUTTON_31"
								changed = true
							elseif axisNameNoSign == "BUTTON_28" then
								newAxisName = "BUTTON_32"
								changed = true
							end

							table.insert(newAxisNames, newAxisName)
						end

						if changed and #newAxisNames > 0 then
							local lastAxisName = newAxisNames[#newAxisNames]
							local inputComponent = Binding.INPUT_COMPONENT.POSITIVE

							if lastAxisName:sub(lastAxisName:len()) == "-" then
								inputComponent = Binding.INPUT_COMPONENT.NEGATIVE
							end

							action:removeBinding(binding)

							local newBinding = Binding.new(binding.deviceId, newAxisNames, binding.axisComponent, inputComponent, binding.neutralInput, binding.index)

							self:addBinding(action, newBinding)
						end
					end
				end
			end
		end
	end
end

function InputBinding:resolveBindingDevice(oldDevice, newDevice)
	if oldDevice.category == InputDevice.CATEGORY.UNKNOWN and oldDevice.category ~= newDevice.category then
		self.devicesToMigrateCategory[newDevice.deviceId] = newDevice
	end

	for _, action in pairs(self.actions) do
		for _, binding in pairs(action.bindings) do
			if binding.deviceId == oldDevice.deviceId then
				binding.deviceId = newDevice.deviceId
				binding.internalDeviceId = newDevice.internalId

				binding:setActive(true)
				binding:makeId()
			end
		end
	end
end

function InputBinding:resolveBindingDevices()
	local usedDevices = self:getAllDevicesWithBindings()

	for missingDeviceId, missingDevice in pairs(self.missingDevices) do
		if usedDevices[missingDeviceId] then
			for _, device in pairs(self.devicesByInternalId) do
				if device.deviceName == missingDevice.deviceName and not usedDevices[device.deviceId] then
					self:resolveBindingDevice(missingDevice, device)

					usedDevices[device.deviceId] = true
					self.missingDevices[missingDeviceId] = nil

					break
				end
			end
		end
	end

	for missingDeviceId, missingDevice in pairs(self.missingDevices) do
		if usedDevices[missingDeviceId] and missingDevice.category ~= InputDevice.CATEGORY.UNKNOWN then
			for _, device in pairs(self.devicesByInternalId) do
				if device.category == missingDevice.category and not usedDevices[device.deviceId] then
					self:resolveBindingDevice(missingDevice, device)

					usedDevices[device.deviceId] = true
					self.missingDevices[missingDeviceId] = nil

					break
				end
			end
		end
	end

	for missingDeviceId in pairs(self.missingDevices) do
		if not usedDevices[missingDeviceId] then
			self.missingDevices[missingDeviceId] = nil
		end
	end
end

function InputBinding:resolveBindingDefaultDevice(binding, disallowedDeviceIds)
	local isDefaultBinding = InputDevice.DEFAULT_DEVICE_NAMES[binding.deviceId]

	if not isDefaultBinding then
		return true
	end

	local category = InputDevice.DEFAULT_DEVICE_CATEGORIES[binding.deviceId]

	for _, device in pairs(self.devicesByInternalId) do
		if device.category == category and (disallowedDeviceIds == nil or not disallowedDeviceIds[device.deviceId]) then
			binding.deviceId = device.deviceId
			binding.internalDeviceId = device.internalId

			return true
		end
	end

	return false
end

function InputBinding:migrateDevicesCategory()
	if not GS_PLATFORM_PC then
		if next(self.devicesToMigrateCategory) then
			self.devicesToMigrateCategory = {}
		end

		return
	end

	for id, device in pairs(self.devicesToMigrateCategory) do
		local gamepad = self.deviceIdToInternal[device.deviceId]

		if gamepad == nil or self.numGamepads <= gamepad then
			self.devicesToMigrateCategory[id] = nil
		elseif getIsGamepadMappingReliable(gamepad) then
			local newAxisMappingsPos = {}
			local newAxisMappingsNeg = {}

			for i = 0, Input.MAX_NUM_AXES - 1 do
				local mapping, inverted = getGamepadMappedUnknownAxis(i, gamepad, 1)
				newAxisMappingsPos[i] = {
					mapping,
					inverted
				}
				mapping, inverted = getGamepadMappedUnknownAxis(i, gamepad, -1)
				newAxisMappingsNeg[i] = {
					mapping,
					inverted
				}
			end

			local newButtonMappings = {}

			for i = 0, Input.MAX_NUM_BUTTONS - 1 do
				newButtonMappings[i] = getGamepadMappedUnknownButton(i, gamepad)
			end

			for _, action in pairs(self.actions) do
				local bindingsCopy = {}

				for bindingI, binding in pairs(action.bindings) do
					bindingsCopy[bindingI] = binding
				end

				for _, binding in pairs(bindingsCopy) do
					if binding.deviceId == device.deviceId then
						local newAxisNames = {}

						for axisNameI, axisName in ipairs(binding.axisNames) do
							local newAxisName = axisName
							local axisId = Input.axisIdNameToId[axisName]

							if axisId then
								local sign = axisName:sub(axisName:len())

								if axisNameI == #binding.axisNames and not Input.isHalfAxis(axisId) and binding.neutralInput ~= 0 then
									if binding.neutralInput == 1 then
										sign = "-"
									else
										sign = "+"
									end
								end

								local mappings = sign == "-" and newAxisMappingsNeg or newAxisMappingsPos
								local mapping = mappings[axisId]

								if mapping and mapping[1] < Input.MAX_NUM_AXES then
									local newSign = ""

									if not Input.isHalfAxis(mapping[1]) then
										if mapping[2] then
											if sign == "-" then
												newSign = "+"
											else
												newSign = "-"
											end
										else
											newSign = sign
										end
									end

									newAxisName = Input.axisIdToIdName[mapping[1]] .. newSign
								end
							else
								local buttonId = Input.buttonIdNameToId[axisName]

								if buttonId then
									local mapping = newButtonMappings[buttonId]

									if mapping and mapping < Input.MAX_NUM_BUTTONS then
										newAxisName = Input.buttonIdToIdName[mapping]
									end
								end
							end

							table.insert(newAxisNames, newAxisName)
						end

						if #newAxisNames > 0 then
							local lastAxisName = newAxisNames[#newAxisNames]
							local inputComponent = Binding.INPUT_COMPONENT.POSITIVE

							if lastAxisName:sub(lastAxisName:len()) == "-" then
								inputComponent = Binding.INPUT_COMPONENT.NEGATIVE
							end

							local neutralInput = binding.neutralInput

							if Input.axisIdNameToId[lastAxisName] and Input.isHalfAxis(Input.axisIdNameToId[lastAxisName]) then
								neutralInput = 0
							end

							action:removeBinding(binding)

							local newBinding = Binding.new(binding.deviceId, newAxisNames, binding.axisComponent, inputComponent, neutralInput, binding.index)

							self:addBinding(action, newBinding)
						end
					end
				end
			end

			self.devicesToMigrateCategory[id] = nil
		end
	end
end

function InputBinding:checkBindings(contextAction, checkFunctions)
	local functionResults = {}

	for _, otherAction in pairs(self.actions) do
		local bindings = otherAction:getBindings()

		for _, knownBinding in pairs(bindings) do
			for _, check in pairs(checkFunctions) do
				local hasResult, result = check(knownBinding, otherAction)

				if hasResult then
					functionResults[check] = result
				end
			end
		end
	end

	return functionResults
end

function InputBinding:validateBinding(binding, action)
	local shouldBeMouse = false
	local shouldBeKeyboard = false
	local numAlternatives = 0
	local maxAlternatives = Binding.MAX_ALTERNATIVES_GAMEPAD

	if binding.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT then
		maxAlternatives = Binding.MAX_ALTERNATIVES_KB_MOUSE

		if binding.index == maxAlternatives then
			shouldBeMouse = true
		else
			shouldBeKeyboard = true
		end
	end

	local hasValidIndex = false

	if shouldBeMouse then
		hasValidIndex = InputBinding.getIsMouseInput(binding.axisNames)
	elseif shouldBeKeyboard then
		if binding.index > 0 and binding.index <= maxAlternatives then
			hasValidIndex = InputBinding.getIsKeyboardInput(binding.axisNames)
		else
			hasValidIndex = false
		end
	else
		hasValidIndex = binding.index > 0 and binding.index <= maxAlternatives and InputBinding.getIsGamepadInput(binding.axisNames)
	end

	local function checkCollision(otherBinding, otherAction)
		if binding:hasCollisionWith(otherBinding) then
			return true, {
				collisionBinding = otherBinding,
				collisionAction = otherAction
			}
		else
			return false, nil
		end
	end

	local function checkDuplicate(otherBinding, otherAction)
		if action == otherAction and binding.id == otherBinding.id then
			return true, true
		else
			return false, nil
		end
	end

	local function checkSlotOccupied(otherBinding, otherAction)
		local isSameAction = otherAction == action

		if isSameAction and binding:isSameSlot(otherBinding) then
			return true, true
		else
			return false, nil
		end
	end

	local checkResults = self:checkBindings(action, {
		checkCollision,
		checkDuplicate,
		checkSlotOccupied
	})
	local hasDuplicate = not not checkResults[checkDuplicate]
	local slotOccupied = not not checkResults[checkSlotOccupied]
	local collision = checkResults[checkCollision]
	local hasCollision = not not collision

	return hasValidIndex, hasDuplicate, slotOccupied, hasCollision, collision
end

function InputBinding:addBinding(action, binding, silentIgnoreDuplicates)
	if not self:adjustBindingSlotIndex(binding, action) then
		if not silentIgnoreDuplicates then
			Logging.warning("Tried to add additional alternative binding %s to %s. The maximum alternative count has been reached. The new binding has been ignored.", tostring(binding), tostring(action.name))
		end

		return false, nil
	end

	local hasAddedBinding = false
	local collisionAction = nil
	local hasValidIndex, hasDuplicate, slotOccupied, hasCollision, collisionRef = self:validateBinding(binding, action)
	collisionAction = collisionRef
	local canAdd = hasValidIndex and not hasDuplicate and not slotOccupied

	if canAdd then
		local actionBindings = action:getBindings()
		binding.internalDeviceId = self.deviceIdToInternal[binding.deviceId]

		binding:setIsAnalog(InputBinding.getIsAnalogInput(binding.unmodifiedAxis))
		binding:setActive(binding.internalDeviceId ~= nil)

		local bindingDevice = self.devicesByInternalId[binding.internalDeviceId]

		if bindingDevice ~= nil then
			binding:updateData(nil, bindingDevice.category)
		end

		binding:makeId()

		local loadedBinding = self.loadedBindings[binding.id]

		if loadedBinding == nil or not loadedBinding.isActive then
			self.loadedBindings[binding.id] = binding
		else
			binding = loadedBinding
		end

		action:addBinding(binding)

		hasAddedBinding = true
	elseif hasDuplicate then
		if not silentIgnoreDuplicates then
			Logging.warning("Tried to add duplicate binding %s to %s. The new binding has been ignored.", tostring(binding), tostring(action.name))
		end
	elseif slotOccupied and not silentIgnoreDuplicates then
		Logging.warning("Tried assigning the binding %s to %s to an occupied slot. The new binding has been ignored", tostring(binding), tostring(action.name))
	end

	return hasAddedBinding, collisionAction
end

function InputBinding:updateBinding(findDeviceId, findActionName, findBindingIndex, findAxisComponent, deviceId, axisNames, inputComponent, neutralInput)
	local updateBinding = nil
	local action = self.nameActions[findActionName]

	if action ~= nil then
		local bindings = action:getBindings()

		for _, binding in pairs(bindings) do
			if binding.deviceId == findDeviceId and binding.index == findBindingIndex and binding.axisComponent == findAxisComponent then
				updateBinding = binding
			end
		end
	end

	local hasUpdated = false
	local collisionAction = nil

	if updateBinding ~= nil then
		action:removeBinding(updateBinding)

		local newBinding = Binding.new(deviceId, axisNames, findAxisComponent, inputComponent, neutralInput, findBindingIndex)
		hasUpdated, collisionAction = self:addBinding(action, newBinding, true)

		if not hasUpdated then
			self:addBinding(action, updateBinding, true)
		end
	end

	return hasUpdated, collisionAction
end

function InputBinding:deleteBinding(findDeviceId, findActionName, findBindingIndex, findAxisComponent)
	local action = self.nameActions[findActionName]

	if action ~= nil then
		local bindings = action:getBindings()

		for i, binding in pairs(bindings) do
			if binding.deviceId == findDeviceId and binding.index == findBindingIndex and binding.axisComponent == findAxisComponent then
				table.remove(bindings, i)

				return
			end
		end
	end
end

function InputBinding:getKeyboardMouseInputActiveAndValue(axes, axisDirection, inputDirection)
	if not next(axes) then
		return false, 0
	end

	local allActive = true
	local inputValue = 0

	for _, inputAxis in pairs(axes) do
		local inputId = Input[inputAxis]

		if not inputId then
			allActive = false

			break
		end

		if InputBinding.MOUSE_AXES[inputAxis] and inputId == Input.AXIS_X then
			inputValue = self.inputMouseXAxisValue

			if axisDirection ~= inputDirection then
				inputValue = -inputValue
			end
		elseif InputBinding.MOUSE_AXES[inputAxis] and inputId == Input.AXIS_Y then
			inputValue = self.inputMouseYAxisValue

			if axisDirection ~= inputDirection then
				inputValue = -inputValue
			end
		elseif InputBinding.MOUSE_BUTTONS[inputAxis] and Input.isMouseButtonPressed(inputId) or Input.isKeyPressed(inputId) then
			inputValue = axisDirection
		else
			inputValue = 0
			allActive = false

			break
		end
	end

	return allActive, inputValue
end

function InputBinding:getGamepadInputActiveAndValue(internalDeviceId, axisNames, neutralInput, axisDirection)
	local numAxes = #axisNames

	if numAxes == 0 then
		return false, 0
	end

	local allActive = true
	local inputValue = 0

	for i = 1, numAxes - 1 do
		local inputAxis = axisNames[i]
		local inputId = Input[inputAxis]
		local value = self:getGamepadAxisOrButtonValue(internalDeviceId, axisNames[i], neutralInput)

		if value < Binding.PRESSED_MAGNITUDE_THRESHOLD then
			return false, 0
		end
	end

	local inputValue, isAxis = self:getGamepadAxisOrButtonValue(internalDeviceId, axisNames[numAxes], neutralInput)

	if not isAxis and inputValue < Binding.PRESSED_MAGNITUDE_THRESHOLD then
		return false, 0
	end

	if axisDirection < 0 then
		inputValue = -inputValue
	end

	return true, inputValue
end

function InputBinding:getGamepadAxisOrButtonValue(internalDeviceId, axisName, neutralInput)
	local buttonId = Input.buttonIdNameToId[axisName]

	if buttonId ~= nil then
		return getInputButton(buttonId, internalDeviceId), false
	end

	local axisId = Input.axisIdNameToId[axisName]

	if axisId ~= nil then
		return self:getGamepadAxisValue(internalDeviceId, axisId, axisName, neutralInput), true
	end

	return 0, false
end

function InputBinding:getGamepadAxisValue(internalDeviceId, axisId, axisName, neutralInput)
	local value = nil

	if Input.isHalfAxis(axisId) then
		value = (1 - getInputAxis(axisId, internalDeviceId)) * 0.5
	else
		value = getInputAxis(axisId, internalDeviceId)

		if neutralInput ~= 0 then
			value = (value - neutralInput) * 0.5
		end

		if axisName:sub(axisName:len()) == "-" then
			value = -value
		end
	end

	local device = self.devicesByInternalId[internalDeviceId]

	if device then
		if value ~= 0 then
			device:updateForceFeedbackState(axisId)
		end

		if GS_PLATFORM_PC then
			local deadzone = device:getDeadzone(axisId)

			if deadzone > 0.999 or math.abs(value) < deadzone then
				value = 0
			elseif value > 0 then
				value = (value - deadzone) / (1 - deadzone)
			else
				value = (value + deadzone) / (1 - deadzone)
			end
		end
	end

	return value
end

function InputBinding:update(dt)
	self.needUpdateAbort = false
	self.timeSinceLastInputHelpModeChange = self.timeSinceLastInputHelpModeChange + dt

	self:checkGamepadsChanged()
	self:checkGamepadsCategoryChanged()
	self:checkGamepadActive(self.numGamepads)
	self:updateMouseInput()
	self:updateInput()
	self:finalizeMouseInput()

	if self.debugEnabled then
		self:updateDebugDisplay()
	end

	if self.debugContextEnabled then
		self:debugRenderInputContext()
	end
end

function InputBinding:checkGamepadsChanged()
	local numGamepads = getNumOfGamepads()
	local changed = numGamepads ~= self.numGamepads

	if not changed then
		for internalId = 0, numGamepads - 1 do
			local engineDeviceId = getGamepadId(internalId)

			if engineDeviceId ~= self.internalIdToEngineDeviceId[internalId] then
				changed = true

				break
			end
		end
	end

	if changed then
		self.numGamepads = numGamepads

		self:load()
		self.messageCenter:publish(MessageType.INPUT_DEVICES_CHANGED)

		if GS_PLATFORM_GGP then
			self:assignLastInputHelpMode(GS_INPUT_HELP_MODE_GAMEPAD, true)
		end
	end
end

function InputBinding:checkGamepadsCategoryChanged()
	if not GS_PLATFORM_PC then
		return
	end

	for gamepad = 0, self.numGamepads - 1 do
		local device = self.devicesByInternalId[gamepad]

		if device and device.category == InputDevice.CATEGORY.UNKNOWN then
			local newCategory = getGamepadCategory(gamepad)

			if newCategory ~= device.category then
				self.devicesToMigrateCategory[device.deviceId] = device
			end
		end
	end

	for id, device in pairs(self.devicesToMigrateCategory) do
		local internalId = self.deviceIdToInternal[device.deviceId]

		if internalId then
			if getIsGamepadMappingReliable(internalId) then
				self:load()

				break
			end
		else
			self.devicesToMigrateCategory[id] = nil
		end
	end
end

function InputBinding:checkGamepadActive(numGamepads)
	local isActive = false

	if numGamepads > 0 and self.lastInputHelpMode ~= GS_INPUT_HELP_MODE_GAMEPAD then
		local threshold = InputBinding.INPUT_MODE_CHANGE_THRESHOLD

		for d = 0, numGamepads - 1 do
			local gamepadState = self.gamepadInputState[d]

			if gamepadState == nil then
				gamepadState = {
					buttons = {},
					axes = {}
				}
				self.gamepadInputState[d] = gamepadState
			end

			local buttons = gamepadState.buttons
			local axes = gamepadState.axes

			for i = 0, Input.MAX_NUM_BUTTONS - 1 do
				local prevButtonState = buttons[i] or 0
				local buttonState = getInputButton(i, d)
				isActive = isActive or threshold < math.abs(buttonState - prevButtonState)
				buttons[i] = buttonState
			end

			for i = 0, Input.MAX_NUM_AXES - 1 do
				local defaultState = Input.isHalfAxis(i) and 1 or 0
				local prevAxisState = axes[i] or defaultState
				local axisState = getInputAxis(i, d)
				isActive = isActive or threshold < math.abs(axisState - prevAxisState)
				axes[i] = axisState
			end
		end
	end

	if isActive then
		self:assignLastInputHelpMode(GS_INPUT_HELP_MODE_GAMEPAD)
	end
end

function InputBinding:updateMouseInput()
	local mouseMovementX = self.accumMouseMovementX
	local mouseMovementY = -self.accumMouseMovementY
	self.inputMouseXAxisValue = 0
	self.inputMouseYAxisValue = 0

	if math.abs(mouseMovementX) > 0.0005 then
		self.inputMouseXAxisValue = MathUtil.clamp(mouseMovementX, -InputBinding.MOUSE_MOVE_LIMIT, InputBinding.MOUSE_MOVE_LIMIT) * InputBinding.MOUSE_MOVE_BASE_FACTOR
	end

	if math.abs(mouseMovementY) > 0.0005 then
		self.inputMouseYAxisValue = MathUtil.clamp(mouseMovementY, -InputBinding.MOUSE_MOVE_LIMIT, InputBinding.MOUSE_MOVE_LIMIT) * InputBinding.MOUSE_MOVE_BASE_FACTOR
	end

	if self.inputMouseXAxisValue ~= 0 or self.inputMouseYAxisValue ~= 0 then
		self:assignLastInputHelpMode(GS_INPUT_HELP_MODE_KEYBOARD)
	end
end

function InputBinding:finalizeMouseInput()
	if self.wrapMousePositionEnabled then
		wrapMousePosition(self.saveCursorX, self.saveCursorY)

		self.mousePosXLast = self.saveCursorX
		self.mousePosYLast = self.saveCursorY
	end

	self.accumMouseMovementX = 0
	self.accumMouseMovementY = 0
	self.inputMouseXAxisValue = 0
	self.inputMouseYAxisValue = 0
end

function InputBinding:clearActiveBindingBuffer(activeBindingsBuffer)
	for dId in pairs(self.devicesByInternalId) do
		local bindings = activeBindingsBuffer[dId]

		if bindings then
			for k in pairs(bindings) do
				bindings[k] = nil
			end
		else
			bindings = {}
			activeBindingsBuffer[dId] = bindings
		end
	end
end

function InputBinding:updateEventBindings(activeBindingsBuffer)
	for binding in pairs(self.activeBindings) do
		if binding.isActive then
			self:updateBindingInput(binding)

			local deviceBindings = activeBindingsBuffer[binding.internalDeviceId]
			local bindingActive = binding.isUp or binding.inputValue ~= 0

			for _, otherBinding in ipairs(deviceBindings) do
				if otherBinding ~= binding then
					local otherActive = otherBinding.isUp or otherBinding.inputValue ~= 0

					if table.isRealSubset(otherBinding.axisNameSet, binding.axisNameSet) then
						otherBinding.isShadowed = otherBinding.isShadowed or bindingActive
					elseif table.isRealSubset(binding.axisNameSet, otherBinding.axisNameSet) then
						binding.isShadowed = binding.isShadowed or otherActive
					end
				end
			end

			table.insert(deviceBindings, binding)
		end
	end
end

function InputBinding:hasBindingForPressedMouseComboMask(pressedMouseComboMask)
	for binding in pairs(self.activeBindings) do
		if binding.isMouse and binding:getComboMask() == pressedMouseComboMask then
			return true
		end
	end

	return false
end

function InputBinding:shadowLinkedBindings()
	for binding, linkedBindings in pairs(self.linkedBindings) do
		if binding.isShadowed then
			for _, linkedBinding in pairs(linkedBindings) do
				linkedBinding.isShadowed = true
			end
		end
	end
end

function InputBinding:updateComboBindings()
	for _, deviceCombos in pairs(InputBinding.ALL_COMBOS) do
		for actionName in pairs(deviceCombos) do
			local comboBinding = self.comboInputBindings[actionName]

			if comboBinding and comboBinding.isActive then
				self:updateBindingInput(comboBinding)
			end
		end
	end
end

function InputBinding:updateInput()
	self.needUpdateAbort = false
	local pressedGamepadComboMask, pressedMouseComboMask = self:getComboCommandPressedMask()

	if pressedGamepadComboMask ~= self.pressedGamepadComboMask or pressedMouseComboMask ~= self.pressedMouseComboMask then
		self:resetContinuousEventBindings(true, self.pressedGamepadComboMask, self.pressedMouseComboMask)
	end

	self.pressedGamepadComboMask = pressedGamepadComboMask
	self.pressedMouseComboMask = pressedMouseComboMask

	self:clearActiveBindingBuffer(self.activeDeviceBindingsBuffer)
	self:updateEventBindings(self.activeDeviceBindingsBuffer)
	self:shadowLinkedBindings()

	local forceMouseMask = self:hasBindingForPressedMouseComboMask(pressedMouseComboMask)

	for _, event in ipairs(self.eventOrder) do
		if self.needUpdateAbort then
			self.needUpdateAbort = false

			break
		end

		local bindings = self.eventBindings[event]
		local selectedBinding = nil
		local highestInputMagnitude = 0

		for _, binding in pairs(bindings) do
			local matchComboMask = true
			local forceMouseAxisMask = forceMouseMask and binding.isMouse and InputBinding.MOUSE_AXES[binding.unmodifiedAxis]

			if not event:getIgnoreComboMask() or forceMouseAxisMask then
				if binding.isMouse then
					if binding.comboMask ~= pressedMouseComboMask then
						matchComboMask = InputBinding.MOUSE_COMBO_AXIS_NAMES[binding.unmodifiedAxis]

						if InputBinding.MOUSE_COMBO_AXIS_NAMES[binding.unmodifiedAxis] then
							matchComboMask = false

							if false then
								matchComboMask = true
							end
						end
					end
				else
					matchComboMask = binding.comboMask == pressedGamepadComboMask or InputBinding.GAMEPAD_COMBO_AXIS_NAMES[binding.unmodifiedAxis]
				end
			end

			if matchComboMask and binding.isInputActive and not binding.isShadowed and not binding:getFrameTriggered() and (not selectedBinding or highestInputMagnitude < math.abs(binding.inputValue) or binding.isUp and highestInputMagnitude == 0) then
				selectedBinding = binding
				highestInputMagnitude = math.abs(binding.inputValue)
			end
		end

		if selectedBinding ~= nil then
			event:notifyInput(selectedBinding)
		end
	end

	self:updateComboBindings()

	for event, eventBindings in pairs(self.eventBindings) do
		event:frameReset()
	end
end

function InputBinding:updateBindingInput(binding)
	local device = self.devicesByInternalId[binding.internalDeviceId]

	if device == nil then
		return
	end

	local bindingInputActive = false
	local bindingInputValue = 0

	if device.category == InputDevice.CATEGORY.KEYBOARD_MOUSE then
		bindingInputActive, bindingInputValue = self:getKeyboardMouseInputActiveAndValue(binding.axisNames, binding.axisDirection, binding.inputDirection)
	elseif self.isGamepadEnabled then
		bindingInputActive, bindingInputValue = self:getGamepadInputActiveAndValue(binding.internalDeviceId, binding.axisNames, binding.neutralInput, binding.axisDirection)

		if bindingInputValue ~= 0 then
			bindingInputValue = bindingInputValue * (device.sensitivities[Input[binding.unmodifiedAxis]] or 1)
		end
	end

	binding:updateInput(bindingInputValue, bindingInputActive)
end

function InputBinding:resetContinuousEventBindings(checkComboMasks, gamepadComboMask, mouseComboMask)
	for event, bindings in pairs(self.eventBindings) do
		if event.triggerAlways and not event:getIgnoreComboMask() then
			for _, binding in pairs(bindings) do
				local matchMask = true

				if checkComboMasks then
					matchMask = binding.isGamepad and binding.comboMask == gamepadComboMask or binding.isMouse and binding.comboMask == mouseComboMask
				end

				if matchMask then
					self:neutralizeEventBindingInput(event, binding)
				end
			end
		end
	end
end

function InputBinding:neutralizeEventBindingInput(event, binding)
	binding:updateInput(0, true)
	event:frameReset()
	event:notifyInput(binding)
end

function InputBinding:updateDebugDisplay()
	local posX = 0.02
	local stepY = 0.015

	for d = 0, self.numGamepads - 1 do
		setTextColor(1, 1, 1, 1)

		local posY = 0.95

		setTextBold(true)
		renderText(posX, posY, getCorrectTextSize(0.012), getGamepadName(d))
		setTextBold(false)

		posY = posY - stepY

		for i = 0, Input.MAX_NUM_BUTTONS - 1 do
			renderText(posX, posY, getCorrectTextSize(0.012), "- " .. i)
			renderText(posX + 0.05, posY, getCorrectTextSize(0.012), getGamepadButtonLabel(i, d) or "n/a")
			renderText(posX + 0.1, posY, getCorrectTextSize(0.012), tostring(getInputButton(i, d) > 0))

			posY = posY - stepY
		end

		for i = 0, Input.MAX_NUM_AXES - 1 do
			renderText(posX, posY, getCorrectTextSize(0.012), "+ " .. i)
			renderText(posX + 0.05, posY, getCorrectTextSize(0.012), getGamepadAxisLabel(i, d) or "n/a")
			renderText(posX + 0.1, posY, getCorrectTextSize(0.012), string.format("%.4f", getInputAxis(i, d)))

			posY = posY - stepY
		end

		setTextColor(1, 0, 0, 1)

		posY = 0.95 + 0.5 / g_screenHeight
		posX = posX - 0.5 / g_screenWidth

		setTextBold(true)
		renderText(posX, posY, getCorrectTextSize(0.012), getGamepadName(d))
		setTextBold(false)

		posY = posY - stepY

		for i = 0, Input.MAX_NUM_BUTTONS - 1 do
			renderText(posX, posY, getCorrectTextSize(0.012), "- " .. i)
			renderText(posX + 0.05, posY, getCorrectTextSize(0.012), getGamepadButtonLabel(i, d) or "n/a")
			renderText(posX + 0.1, posY, getCorrectTextSize(0.012), tostring(getInputButton(i, d) > 0))

			posY = posY - stepY
		end

		for i = 0, Input.MAX_NUM_AXES - 1 do
			renderText(posX, posY, getCorrectTextSize(0.012), "+ " .. i)
			renderText(posX + 0.05, posY, getCorrectTextSize(0.012), getGamepadAxisLabel(i, d) or "n/a")
			renderText(posX + 0.1, posY, getCorrectTextSize(0.012), string.format("%.4f", getInputAxis(i, d)))

			posY = posY - stepY
		end

		posX = posX + 0.15
	end
end

function InputBinding:saveToXMLFile()
	if self.settingsPath ~= InputBinding.PATHS.USER_BINDINGS then
		return
	end

	local xmlFile = loadXMLFile("InputBindings", self.settingsPath)
	local i = 1
	local storedActions = {}

	while true do
		local actionBindingElement = string.format("inputBinding.actionBinding(%d)", i - 1)

		if not hasXMLProperty(xmlFile, actionBindingElement) then
			break
		else
			local actionName = getXMLString(xmlFile, actionBindingElement .. "#action")

			if actionName and InputAction[actionName] then
				local firstElement = string.format("%s.binding(0)", actionBindingElement)

				while hasXMLProperty(xmlFile, firstElement) do
					removeXMLProperty(xmlFile, firstElement)
				end

				local action = self.nameActions[actionName]

				if action == nil then
					log(actionName)
					printCallstack()
				end

				local bindings = action:getBindings()

				for j, binding in ipairs(bindings) do
					local bindingElement = string.format("%s.binding(%d)", actionBindingElement, j - 1)

					binding:saveToXMLFile(xmlFile, bindingElement)
				end

				storedActions[action] = true
			end
		end

		i = i + 1
	end

	for _, action in ipairs(self.actions) do
		if not storedActions[action] then
			local actionBindingElement = string.format("inputBinding.actionBinding(%d)", i - 1)

			setXMLString(xmlFile, actionBindingElement .. "#action", action.name)

			local bindings = action:getBindings()

			for j, binding in ipairs(bindings) do
				local bindingElement = string.format("%s.binding(%d)", actionBindingElement, j - 1)

				binding:saveToXMLFile(xmlFile, bindingElement)
			end

			i = i + 1
		end
	end

	self:saveDeviceSettings(xmlFile)
	setXMLFloat(xmlFile, "inputBinding#mouseSensitivityScaleX", self.mouseMotionScaleX)
	setXMLFloat(xmlFile, "inputBinding#mouseSensitivityScaleY", self.mouseMotionScaleY)
	setXMLInt(xmlFile, "inputBinding#bindingVersion", InputBinding.currentBindingVersion)
	saveXMLFile(xmlFile)
	delete(xmlFile)
	syncProfileFiles()
end

function InputBinding:saveDeviceSettings(xmlFile)
	local firstDeviceKey = "inputBinding.devices.device(0)"

	while hasXMLProperty(xmlFile, firstDeviceKey) do
		removeXMLProperty(xmlFile, firstDeviceKey)
	end

	local elementIndex = 0

	for _, device in pairs(self.devicesByInternalId) do
		if not InputDevice.DEFAULT_DEVICE_NAMES[device.deviceId] then
			local deviceElement = string.format("inputBinding.devices.device(%d)", elementIndex)

			device:saveSettingsToXML(xmlFile, deviceElement)

			elementIndex = elementIndex + 1
		end
	end

	for _, device in pairs(self.missingDevices) do
		if not InputDevice.DEFAULT_DEVICE_NAMES[device.deviceId] then
			local deviceElement = string.format("inputBinding.devices.device(%d)", elementIndex)

			device:saveSettingsToXML(xmlFile, deviceElement)

			elementIndex = elementIndex + 1
		end
	end
end

function InputBinding:getActionList()
	local tableCopy = {}

	for _, action in ipairs(self.actions) do
		local actionCopy = action:clone()

		table.insert(tableCopy, actionCopy)
	end

	return tableCopy
end

function InputBinding:getActionByName(actionName)
	return self.nameActions[actionName]
end

function InputBinding:disableAlternateBindingsForAction(actionName)
	local action = self.nameActions[actionName]
	local events = self.actionEvents[action]

	if events ~= nil then
		for _, event in pairs(events) do
			local bindings = self.eventBindings[event]

			if bindings ~= nil then
				for i = #bindings, 1, -1 do
					local binding = bindings[i]

					if binding.index > 1 then
						table.remove(bindings, i)
					end
				end
			end
		end
	end
end

function InputBinding:resetActiveActionBindings()
	for _, action in pairs(self.nameActions) do
		action:resetActiveBindings()
	end
end

function InputBinding:createContext(name)
	self:deleteContext(name)

	local context = {
		eventOrderCounter = 1,
		previousContextName = "",
		actionEvents = {},
		name = name
	}
	self.contexts[name] = context

	return context
end

function InputBinding:deleteContext(name)
	local oldContext = self.contexts[name]

	if oldContext ~= nil then
		for _, eventList in pairs(oldContext.actionEvents) do
			for i = #eventList, 1, -1 do
				local event = eventList[i]

				self:removeEventInternal(event, eventList, i)
			end
		end
	end

	self.contexts[name] = nil
end

function InputBinding:setContext(name, createNew, deletePrevious)
	local context = self.contexts[name]
	local hasCreatedNew = false

	if context == nil or createNew then
		context = self:createContext(name)
		hasCreatedNew = true
	end

	if deletePrevious and self.currentContextName ~= InputBinding.ROOT_CONTEXT_NAME then
		self:deleteContext(self.currentContextName)
	end

	if self.debugEnabled then
		Logging.devInfo("[InputBinding] Set input context from [%s] to [%s], createNew=%s, deletePrevious=%s", tostring(self.currentContextName), tostring(name), tostring(createNew or false), tostring(deletePrevious or false))
	end

	if name ~= self.currentContextName then
		context.previousContextName = self.currentContextName
		self.currentContextName = name
	end

	self:resetContinuousEventBindings(false)

	self.actionEvents = context.actionEvents

	if hasCreatedNew then
		registerGlobalActionEvents(self)
	end

	self:refreshEventCollections()
end

function InputBinding:revertContext(deleteCurrent)
	if self.currentContextName == InputBinding.ROOT_CONTEXT_NAME then
		Logging.devWarning("Tried reverting input context when at root level.")

		return
	end

	local currentContext = self.contexts[self.currentContextName]
	local prevContextName = currentContext.previousContextName
	local prevContext = self.contexts[prevContextName]

	if prevContext then
		if deleteCurrent then
			self:deleteContext(self.currentContextName)
		end

		if self.debugEnabled then
			Logging.devInfo("[InputBinding] Reverting input context from [%s] to [%s], deleteCurrent=%s", tostring(self.currentContextName), tostring(prevContextName), tostring(deleteCurrent or false))
		end

		self.currentContextName = prevContextName
		self.actionEvents = prevContext.actionEvents

		self:refreshEventCollections()
	else
		Logging.warning("Tried reverting to input context [%s] which is not defined.", tostring(prevContextName))
	end
end

function InputBinding:setPreviousContext(forContextName, previousContextName)
	local context = self.contexts[forContextName]

	if context ~= nil and self.contexts[previousContextName] ~= nil then
		context.previousContextName = previousContextName
	end
end

function InputBinding:clearAllContexts()
	for contextName in pairs(self.contexts) do
		if contextName ~= InputBinding.ROOT_CONTEXT_NAME then
			self:deleteContext(contextName)
		end
	end

	if self.debugEnabled then
		Logging.devInfo("[InputBinding] Cleared all contexts")
	end

	self:setContext(InputBinding.ROOT_CONTEXT_NAME, false, false)
end

function InputBinding:getContextName()
	return self.currentContextName
end

function InputBinding:getActionBindingsCopy(onlyAssignable)
	local tableCopy = {}

	for _, action in ipairs(self.actions) do
		if not onlyAssignable or onlyAssignable and not action.isLocked then
			local bindings = action:getBindings()
			local actionCopy = action:clone()
			local bindingsCopy = {}
			local entry = {
				action = actionCopy,
				bindings = bindingsCopy
			}

			table.insert(tableCopy, entry)

			for _, binding in ipairs(bindings) do
				table.insert(bindingsCopy, binding:clone())
			end
		end
	end

	return tableCopy
end

function InputBinding:getActionBindings()
	local actionBindings = {}

	for _, action in pairs(self.actions) do
		actionBindings[action] = action:getActiveBindings()
	end

	return actionBindings
end

function InputBinding:getEventsForActionName(actionName)
	local action = self.nameActions[actionName]

	if action ~= nil then
		local events = self.actionEvents[action]

		if events ~= nil then
			return {
				unpack(events)
			}
		end
	end

	return InputBinding.NO_ACTION_EVENTS
end

function InputBinding:getFirstActiveEventForActionName(actionName)
	local action = self.nameActions[actionName]

	if action ~= nil then
		local events = self.actionEvents[action]

		if events ~= nil then
			for _, event in ipairs(events) do
				if event.isActive then
					return event
				end
			end
		end
	end

	return InputEvent.NO_EVENT
end

function InputBinding:setMouseMotionScale(scale)
	self.mouseMotionScaleX = InputBinding.MOUSE_MOTION_SCALE_X_DEFAULT * scale
	self.mouseMotionScaleY = InputBinding.MOUSE_MOTION_SCALE_Y_DEFAULT * scale
end

function InputBinding:getMouseMotionScale()
	return self.mouseMotionScaleX, self.mouseMotionScaleY
end

function InputBinding:setEventChangeCallback(callback)
	self.eventChangeCallback = callback
end

function InputBinding:notifyBindingChanges()
	self.messageCenter:publish(MessageType.INPUT_BINDINGS_CHANGED, self:getActionBindings())
end

function InputBinding:notifyEventChanges()
	if self.eventChangeCallback then
		self.eventChangeCallback(self.displayActionEvents)
	end
end

function InputBinding:notifyInputModeChange(inputMode, isHelpModeUpdate)
	if not self.isConsoleVersion then
		local messageType = MessageType.INPUT_MODE_CHANGED

		if isHelpModeUpdate then
			messageType = MessageType.INPUT_HELP_MODE_CHANGED
		end

		self.messageCenter:publish(messageType, InputBinding.MESSAGE_PARAM_INPUT_MODE[inputMode])
	end
end

function InputBinding:checkSettingsIntegrity(inputBindingPath, inputBindingPathTemplate)
	local isCorrupted = false
	local xmlFile1 = loadXMLFile("InputBindings1", inputBindingPath)
	local rootName = getXMLRootName(xmlFile1)
	isCorrupted = not rootName or rootName == ""

	if isCorrupted then
		Logging.error("User input bindings corrupted. Replacing with defaults...")
	end

	local xmlFile2 = loadXMLFile("InputBindings2", inputBindingPathTemplate)
	local version1 = Utils.getNoNil(getXMLFloat(xmlFile1, "inputBinding#version"), 0.1)
	local version2 = Utils.getNoNil(getXMLFloat(xmlFile2, "inputBinding#version"), 0.1)

	delete(xmlFile1)
	delete(xmlFile2)

	return not isCorrupted and version1 == version2
end

function InputBinding:checkDefaultInputExclusiveActionBindings()
	for groupId, exclusiveActions in pairs(InputAction.EXCLUSIVE_ACTION_GROUPS) do
		for i, actionName1 in ipairs(exclusiveActions) do
			local action1 = self.nameActions[actionName1]

			for j = i + 1, #exclusiveActions do
				local action2 = self.nameActions[exclusiveActions[j]]

				for _, binding1 in ipairs(action1.bindings) do
					for _, binding2 in ipairs(action2.bindings) do
						local bothPrimary = binding1.index == 1 and binding2.index == 1
						local sameInput = binding1.inputString == binding2.inputString

						if bothPrimary and sameInput then
							Logging.devError("Currently loaded input bindings have conflicting primary bindings in action group '%s' for actions [%s] and [%s], both bound to [%s]", groupId, action1.name, action2.name, binding2.inputString)
						end
					end
				end
			end
		end
	end
end

function InputBinding:getBindingForceFeedbackInfo(binding)
	if binding == nil then
		return false, nil, 0
	end

	local device = g_inputBinding:getDeviceById(binding.deviceId)
	local axisIndex = nil

	for i = 1, #binding.axisNames do
		axisIndex = Input.axisIdNameToId[binding.axisNames[i]]
	end

	if device == nil or axisIndex == nil then
		return false, nil, 0
	end

	local isSupported = device:getIsForceFeedbackSupported(axisIndex)

	return isSupported, device, axisIndex
end

function InputBinding.getIsPhysicalFullAxis(inputAxisName)
	local isMouseAxis = InputBinding.MOUSE_AXES[inputAxisName] ~= nil
	local axisId = Input.axisIdNameToId[inputAxisName]

	return isMouseAxis or axisId ~= nil and not Input.isHalfAxis(axisId)
end

function InputBinding.getIsHalfAxis(inputAxisName)
	local gamepadAxisId = Input.axisIdNameToId[inputAxisName]

	return Input.isHalfAxis(gamepadAxisId)
end

function InputBinding.getIsAnalogInput(inputName)
	local isMouseAxis = not not InputBinding.MOUSE_AXES[inputName]
	local isGamepadAxis = not not Input.axisIdNameToId[inputName]

	return isMouseAxis or isGamepadAxis
end

function InputBinding.getIsKeyboardInput(inputAxisNames)
	if not inputAxisNames or #inputAxisNames == 0 then
		return false
	end

	local isKb = true

	for _, inputAxisName in pairs(inputAxisNames) do
		isKb = isKb and Input.keyIdToIdName[Input[inputAxisName]]
	end

	return isKb
end

function InputBinding.getIsMouseInput(inputAxisNames)
	if not inputAxisNames or #inputAxisNames == 0 then
		return false
	end

	local isMouse = true

	for _, inputAxisName in pairs(inputAxisNames) do
		isMouse = isMouse and (InputBinding.MOUSE_AXES[inputAxisName] or InputBinding.MOUSE_BUTTONS[inputAxisName])
	end

	return isMouse
end

function InputBinding.getIsMouseWheelInput(inputAxisNames)
	if not inputAxisNames or #inputAxisNames == 0 then
		return false
	end

	local buttonId = InputBinding.MOUSE_BUTTONS[inputAxisNames[1]] or ""

	return InputBinding.MOUSE_WHEEL[buttonId]
end

function InputBinding.getIsGamepadInput(inputAxisNames)
	if not inputAxisNames or #inputAxisNames == 0 then
		return false
	end

	local isGamepad = true

	for _, inputAxisName in pairs(inputAxisNames) do
		isGamepad = isGamepad and (Input.axisIdNameToId[inputAxisName] ~= nil or Input.buttonIdNameToId[inputAxisName] ~= nil)
	end

	return isGamepad
end

function InputBinding.getIsDPadInput(inputAxisNames)
	if not inputAxisNames or #inputAxisNames == 0 then
		return false
	end

	local buttonId = Input.buttonIdNameToId[inputAxisNames[1]]

	if buttonId ~= nil then
		return InputBinding.GAMEPAD_DPAD[buttonId]
	end

	return false
end

function InputBinding.isAxisZero(value)
	return value == nil or math.abs(value) < 0.0001
end

function InputBinding.getDeviceCategory(internalDeviceId)
	if internalDeviceId == InputBinding.KB_MOUSE_INTERNAL_ID then
		return InputDevice.CATEGORY.KEYBOARD_MOUSE
	else
		return getGamepadCategory(internalDeviceId)
	end
end

function InputBinding:printAll()
	for action, eventList in pairs(self.actionEvents) do
		for i = #eventList, 1, -1 do
			local event = eventList[i]

			log(nil, self.currentContextName, "EventTable:", self.actionEvents, event)
		end
	end

	for _, context in pairs(self.contexts) do
		for action, eventList in pairs(context.actionEvents) do
			for i = #eventList, 1, -1 do
				local event = eventList[i]

				log(context, context.name, "EventTable:", context.actionEvents, event)
			end
		end
	end
end

function InputBinding:debugPrintInputContext(contextName)
	contextName = contextName or self.currentContextName
	local context = self.contexts[contextName] or {}

	printf("Context [%s]: previousContextName=%s, eventOrderCounter=%s", contextName, context.previousContextName, context.eventOrderCounter)

	for action, events in pairs(context.actionEvents) do
		printf("  Action %s", action)
		printf("    Bindings:")

		for _, binding in ipairs(action:getBindings()) do
			printf("      %s", binding)
		end

		printf("    Events:")

		for _, event in ipairs(events) do
			printf("      %s", event)
		end
	end
end

function InputBinding:debugRenderInputContext(contextName)
	contextName = contextName or self.currentContextName
	local context = self.contexts[contextName] or {}

	renderText(0.01, 0.98, 0.015, string.format("Context [%s]: previousContextName=%s, eventOrderCounter=%s", contextName, context.previousContextName, context.eventOrderCounter))

	local posX = 0.01
	local posY = 0.96

	for action, events in pairs(context.actionEvents) do
		local neededLines = 1 + #action:getBindings() + #events

		if posY - neededLines * 0.013 < 0 then
			posY = 0.96
			posX = posX + 0.35
		end

		setTextColor(1, 1, 1, 1)
		renderText(posX, posY, 0.012, "Action " .. action.name)

		posY = posY - 0.013

		for _, binding in ipairs(action:getBindings()) do
			setTextColor(1, 1, 1, 1)

			if binding.isShadowed then
				setTextColor(1, 0, 0, 1)
			elseif binding.inputValue ~= 0 then
				setTextColor(0, 1, 0, 1)
			end

			renderText(posX + 0.005, posY, 0.012, "B: Active: " .. tostring(binding.isActive))
			renderText(posX + 0.05, posY, 0.012, "Shadowed: " .. tostring(binding.isShadowed))
			renderText(posX + 0.105, posY, 0.012, "Value: " .. string.format("%.4f", binding.inputValue))
			renderText(posX + 0.16, posY, 0.012, "[" .. table.concat(binding.axisNames, ", ") .. "] " .. tostring(binding.axisComponent) .. " | " .. tostring(binding.deviceId) .. " | " .. tostring(binding.index))

			posY = posY - 0.013
		end

		setTextColor(1, 1, 1, 1)

		for _, event in ipairs(events) do
			renderText(posX + 0.005, posY, 0.012, "E: Active: " .. tostring(event.isActive))
			renderText(posX + 0.05, posY, 0.012, "Visible: " .. tostring(event.displayIsVisible))
			renderText(posX + 0.105, posY, 0.012, "Triggered: " .. tostring(event.hasFrameTriggered))
			renderText(posX + 0.16, posY, 0.012, "Target: " .. tostring(event.targetObject))

			posY = posY - 0.013
		end

		posY = posY - 0.005
	end
end

function InputBinding:consoleCommandEnableInputDebug()
	self.debugEnabled = not self.debugEnabled
end

function InputBinding:consoleCommandPrintInputContext(enable)
	self:debugPrintInputContext()
end

function InputBinding:consoleCommandShowInputContext(enable)
	self.debugContextEnabled = not self.debugContextEnabled
end
