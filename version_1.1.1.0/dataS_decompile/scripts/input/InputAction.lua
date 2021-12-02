InputAction = {}
local InputAction_mt = Class(InputAction)
InputAction.AXIS_TYPE = {
	HALF = "HALF",
	FULL = "FULL"
}
InputAction.CATEGORY = {
	SYSTEM = 1,
	ONFOOT = 2,
	VEHICLE = 3
}

function InputAction.new(name, categories, displayCategory, axisType, isLocked, ignoreComboMask, displayNamePositive, displayNameNegative, isBaseAction, isConsoleAction, isMobileAction)
	local self = setmetatable({}, InputAction_mt)
	self.name = name
	self.displayNamePositive = displayNamePositive
	self.displayNameNegative = displayNameNegative
	self.categories = categories
	self.axisType = axisType
	self.isLocked = isLocked
	self.ignoreComboMask = ignoreComboMask
	self.displayCategory = displayCategory
	self.isBaseAction = Utils.getNoNil(isBaseAction, true)
	self.isConsoleAction = Utils.getNoNil(isConsoleAction, true)
	self.isMobileAction = Utils.getNoNil(isMobileAction, true)
	self.bindingsKnown = false
	self.bindings = {}
	self.activeBindings = {}
	self.isConsumed = false
	self.comboMaskGamepad = 0
	self.comboMaskMouse = 0
	self.primaryKeyboardInput = nil

	return self
end

function InputAction.createFromXML(xmlFile, elementTag)
	local name = getXMLString(xmlFile, elementTag .. "#name")
	local categoryValue = getXMLString(xmlFile, elementTag .. "#category") or ""
	local categoryNames = categoryValue:split(" ")
	local categories = {}

	for _, categoryName in ipairs(categoryNames) do
		local cat = InputAction.CATEGORY[categoryName]

		if cat ~= nil then
			categories[cat] = cat
		end
	end

	local displayCategory = getXMLString(xmlFile, elementTag .. "#displayCategory")

	if displayCategory ~= nil then
		displayCategory = "$l10n_inputCategory_" .. displayCategory
	end

	local axisType = getXMLString(xmlFile, elementTag .. "#axisType")

	if axisType ~= InputAction.AXIS_TYPE.FULL and axisType ~= InputAction.AXIS_TYPE.HALF then
		axisType = InputAction.AXIS_TYPE.HALF
	end

	local isLocked = Utils.getNoNil(getXMLBool(xmlFile, elementTag .. "#locked"), false)
	local ignoreComboMask = Utils.getNoNil(getXMLBool(xmlFile, elementTag .. "#ignoreComboMask"), false)
	local isBaseAction = getXMLBool(xmlFile, elementTag .. "#isBaseAction")
	local isConsoleAction = getXMLBool(xmlFile, elementTag .. "#isConsoleAction")
	local isMobileAction = getXMLBool(xmlFile, elementTag .. "#isMobileAction")

	if table.hasElement(Platform.lockedInputActionNames, name) then
		isLocked = true
	end

	if name and not InputAction[name] then
		InputAction[name] = name
	end

	return InputAction.new(name, categories, displayCategory, axisType, isLocked, ignoreComboMask, nil, , isBaseAction, isConsoleAction, isMobileAction)
end

function InputAction:getIsSupportedOnCurrentPlatfrom()
	if not self.isBaseAction and GS_PLATFORM_PC or not self.isConsoleAction and GS_IS_CONSOLE_VERSION or not self.isMobileAction and GS_IS_MOBILE_VERSION then
		return false
	end

	return true
end

function InputAction:addBinding(binding)
	for _, existingBinding in pairs(self.bindings) do
		if existingBinding.id == binding.id then
			return
		end
	end

	table.insert(self.bindings, binding)
	self:resetActiveBindings()
end

function InputAction:removeBinding(binding)
	for i, existingBinding in ipairs(self.bindings) do
		if existingBinding.id == binding.id then
			table.remove(self.bindings, i)

			return
		end
	end

	self:resetActiveBindings()
end

function InputAction:disableBinding(binding)
	for i, existingBinding in ipairs(self.activeBindings) do
		if existingBinding.id == binding.id then
			table.remove(self.activeBindings, i)

			return
		end
	end
end

function InputAction:enableBinding(binding)
	for _, existingBinding in ipairs(self.bindings) do
		if existingBinding.id == binding.id then
			table.addElement(self.activeBindings, binding)
		end
	end
end

function InputAction:getBindings()
	return self.bindings
end

function InputAction:getActiveBindings()
	return self.activeBindings
end

function InputAction:getNumActiveBindings(ignoreDeviceState)
	local num = 0

	for i = 1, #self.activeBindings do
		local binding = self.activeBindings[i]

		if g_inputBinding.deviceIdToInternal[binding.deviceId] ~= nil or ignoreDeviceState then
			num = num + 1
		end
	end

	return num
end

function InputAction:resetActiveBindings()
	for k in pairs(self.activeBindings) do
		self.activeBindings[k] = nil
	end

	for _, binding in ipairs(self.bindings) do
		table.insert(self.activeBindings, binding)
	end
end

function InputAction:clearBindings()
	self.bindings = {}
	self.activeBindings = {}
end

function InputAction:getBindingAtSlot(axisComponent, isKbMouse, slotIndex)
	for _, binding in pairs(self.bindings) do
		if binding:isSameSlotWithParams(axisComponent, isKbMouse, slotIndex) then
			return binding
		end
	end

	return nil
end

function InputAction:setPrimaryKeyboardBinding(binding)
	self.primaryKeyboardInput = table.concat(binding.axisNames, " ")
end

function InputAction:isFullAxis()
	return self.axisType == InputAction.AXIS_TYPE.FULL
end

function InputAction:getIgnoreComboMask()
	return self.ignoreComboMask
end

function InputAction:clone()
	local clone = InputAction.new(self.name, self.categories, self.displayCategory, self.axisType, self.isLocked, self.ignoreComboMask, self.displayNamePositive, self.displayNameNegative)

	return clone
end

function InputAction:toString()
	local categories = ""

	for cat in pairs(self.categories) do
		categories = categories .. " " .. cat
	end

	return string.format("[%s: categories=%s, axisType=%s, isLocked=%s]", tostring(self.name), categories, tostring(self.axisType), tostring(self.isLocked))
end

InputAction_mt.__tostring = InputAction.toString
InputAction.JUMP = "JUMP"
InputAction.ACTIVATE_HANDTOOL = "ACTIVATE_HANDTOOL"
InputAction.INTERACT = "INTERACT"
InputAction.THROW_OBJECT = "THROW_OBJECT"
InputAction.ROTATE_OBJECT_LEFT_RIGHT = "ROTATE_OBJECT_LEFT_RIGHT"
InputAction.ROTATE_OBJECT_UP_DOWN = "ROTATE_OBJECT_UP_DOWN"
InputAction.ENTER = "ENTER"
InputAction.CROUCH = "CROUCH"
InputAction.TOGGLE_LIGHTS_FPS = "TOGGLE_LIGHTS_FPS"
InputAction.CAMERA_SWITCH = "CAMERA_SWITCH"
InputAction.ACTIVATE_OBJECT = "ACTIVATE_OBJECT"
InputAction.ANIMAL_PET = "ANIMAL_PET"
InputAction.PAUSE = "PAUSE"
InputAction.SKIP_MESSAGE_BOX = "SKIP_MESSAGE_BOX"
InputAction.CAMERA_ZOOM_IN = "CAMERA_ZOOM_IN"
InputAction.CAMERA_ZOOM_OUT = "CAMERA_ZOOM_OUT"
InputAction.SWITCH_VEHICLE = "SWITCH_VEHICLE"
InputAction.SWITCH_VEHICLE_BACK = "SWITCH_VEHICLE_BACK"
InputAction.MENU = "MENU"
InputAction.TOGGLE_STORE = "TOGGLE_STORE"
InputAction.TOGGLE_MAP = "TOGGLE_MAP"
InputAction.TOGGLE_CHARACTER_CREATION = "TOGGLE_CHARACTER_CREATION"
InputAction.TOGGLE_CONSTRUCTION = "TOGGLE_CONSTRUCTION"
InputAction.ATTACH = "ATTACH"
InputAction.SWITCH_IMPLEMENT = "SWITCH_IMPLEMENT"
InputAction.TOGGLE_AI = "TOGGLE_AI"
InputAction.HONK = "HONK"
InputAction.TOGGLE_MOTOR_STATE = "TOGGLE_MOTOR_STATE"
InputAction.SHIFT_GEAR_UP = "SHIFT_GEAR_UP"
InputAction.SHIFT_GEAR_DOWN = "SHIFT_GEAR_DOWN"
InputAction.TOGGLE_TIPSTATE = "TOGGLE_TIPSTATE"
InputAction.TOGGLE_LIGHTS = "TOGGLE_LIGHTS"
InputAction.TOGGLE_BEACON_LIGHTS = "TOGGLE_BEACON_LIGHTS"
InputAction.TOGGLE_TIPSIDE = "TOGGLE_TIPSIDE"
InputAction.TOGGLE_TURNLIGHT_LEFT = "TOGGLE_TURNLIGHT_LEFT"
InputAction.TOGGLE_TURNLIGHT_RIGHT = "TOGGLE_TURNLIGHT_RIGHT"
InputAction.TOGGLE_CRABSTEERING = "TOGGLE_CRABSTEERING"
InputAction.TOGGLE_TENSION_BELTS = "TOGGLE_TENSION_BELTS"
InputAction.LOWER_IMPLEMENT = "LOWER_IMPLEMENT"
InputAction.IMPLEMENT_EXTRA = "IMPLEMENT_EXTRA"
InputAction.IMPLEMENT_EXTRA2 = "IMPLEMENT_EXTRA2"
InputAction.IMPLEMENT_EXTRA3 = "IMPLEMENT_EXTRA3"
InputAction.IMPLEMENT_EXTRA4 = "IMPLEMENT_EXTRA4"
InputAction.TOGGLE_PIPE = "TOGGLE_PIPE"
InputAction.TOGGLE_COVER = "TOGGLE_COVER"
InputAction.TOGGLE_CHOPPER = "TOGGLE_CHOPPER"
InputAction.TOGGLE_MAP_SIZE = "TOGGLE_MAP_SIZE"
InputAction.CHANGE_DRIVING_DIRECTION = "CHANGE_DRIVING_DIRECTION"
InputAction.TOGGLE_TIPSTATE_GROUND = "TOGGLE_TIPSTATE_GROUND"
InputAction.TOGGLE_CRUISE_CONTROL = "TOGGLE_CRUISE_CONTROL"
InputAction.RADIO_TOGGLE = "RADIO_TOGGLE"
InputAction.RADIO_NEXT_CHANNEL = "RADIO_NEXT_CHANNEL"
InputAction.RADIO_PREVIOUS_CHANNEL = "RADIO_PREVIOUS_CHANNEL"
InputAction.RADIO_NEXT_ITEM = "RADIO_NEXT_ITEM"
InputAction.RADIO_PREVIOUS_ITEM = "RADIO_PREVIOUS_ITEM"
InputAction.INGAMEMAP_ACCEPT = "INGAMEMAP_ACCEPT"
InputAction.MENU_ACCEPT = "MENU_ACCEPT"
InputAction.MENU_ACTIVATE = "MENU_ACTIVATE"
InputAction.MENU_CANCEL = "MENU_CANCEL"
InputAction.MENU_BACK = "MENU_BACK"
InputAction.MENU_PAGE_PREV = "MENU_PAGE_PREV"
InputAction.MENU_PAGE_NEXT = "MENU_PAGE_NEXT"
InputAction.TAKE_SCREENSHOT = "TAKE_SCREENSHOT"
InputAction.CHAT = "CHAT"
InputAction.PUSH_TO_TALK = "PUSH_TO_TALK"
InputAction.TOGGLE_TURNLIGHT_HAZARD = "TOGGLE_TURNLIGHT_HAZARD"
InputAction.TOGGLE_WORK_LIGHT_BACK = "TOGGLE_WORK_LIGHT_BACK"
InputAction.TOGGLE_WORK_LIGHT_FRONT = "TOGGLE_WORK_LIGHT_FRONT"
InputAction.TOGGLE_HIGH_BEAM_LIGHT = "TOGGLE_HIGH_BEAM_LIGHT"
InputAction.TOGGLE_LIGHT_FRONT = "TOGGLE_LIGHT_FRONT"
InputAction.LOWER_ALL_IMPLEMENTS = "LOWER_ALL_IMPLEMENTS"
InputAction.TOGGLE_HELP_TEXT = "TOGGLE_HELP_TEXT"
InputAction.INCREASE_TIMESCALE = "INCREASE_TIMESCALE"
InputAction.DECREASE_TIMESCALE = "DECREASE_TIMESCALE"
InputAction.CRABSTEERING_ALLWHEEL = "CRABSTEERING_ALLWHEEL"
InputAction.CRABSTEERING_CRABLEFT = "CRABSTEERING_CRABLEFT"
InputAction.CRABSTEERING_CRABRIGHT = "CRABSTEERING_CRABRIGHT"
InputAction.RESET_HEAD_TRACKING = "RESET_HEAD_TRACKING"
InputAction.MENU_AXIS_UP_DOWN = "MENU_AXIS_UP_DOWN"
InputAction.MENU_AXIS_UP_DOWN_SECONDARY = "MENU_AXIS_UP_DOWN_SECONDARY"
InputAction.MENU_AXIS_LEFT_RIGHT = "MENU_AXIS_LEFT_RIGHT"
InputAction.AXIS_RUN = "AXIS_RUN"
InputAction.AXIS_MOVE_FORWARD_PLAYER = "AXIS_MOVE_FORWARD_PLAYER"
InputAction.AXIS_MOVE_SIDE_PLAYER = "AXIS_MOVE_SIDE_PLAYER"
InputAction.AXIS_LOOK_UPDOWN_PLAYER = "AXIS_LOOK_UPDOWN_PLAYER"
InputAction.AXIS_LOOK_LEFTRIGHT_PLAYER = "AXIS_LOOK_LEFTRIGHT_PLAYER"
InputAction.AXIS_ROTATE_HANDTOOL = "AXIS_ROTATE_HANDTOOL"
InputAction.AXIS_DOOR = "AXIS_DOOR"
InputAction.AXIS_MAP_SCROLL_LEFT_RIGHT = "AXIS_MAP_SCROLL_LEFT_RIGHT"
InputAction.AXIS_MAP_SCROLL_UP_DOWN = "AXIS_MAP_SCROLL_UP_DOWN"
InputAction.AXIS_MAP_ZOOM_OUT = "AXIS_MAP_ZOOM_OUT"
InputAction.AXIS_MAP_ZOOM_IN = "AXIS_MAP_ZOOM_IN"
InputAction.AXIS_CONSTRUCTION_CAMERA_ZOOM = "AXIS_CONSTRUCTION_CAMERA_ZOOM"
InputAction.AXIS_CONSTRUCTION_CAMERA_ROTATE = "AXIS_CONSTRUCTION_CAMERA_ROTATE"
InputAction.AXIS_CONSTRUCTION_CAMERA_TILT = "AXIS_CONSTRUCTION_CAMERA_TILT"
InputAction.CONSTRUCTION_ACTION_PRIMARY = "CONSTRUCTION_ACTION_PRIMARY"
InputAction.CONSTRUCTION_ACTION_SECONDARY = "CONSTRUCTION_ACTION_SECONDARY"
InputAction.CONSTRUCTION_ACTION_TERTIARY = "CONSTRUCTION_ACTION_TERTIARY"
InputAction.CONSTRUCTION_ACTION_FOURTH = "CONSTRUCTION_ACTION_FOURTH"
InputAction.AXIS_CONSTRUCTION_ACTION_PRIMARY = "AXIS_CONSTRUCTION_ACTION_PRIMARY"
InputAction.AXIS_CONSTRUCTION_ACTION_SECONDARY = "AXIS_CONSTRUCTION_ACTION_SECONDARY"
InputAction.AXIS_CONSTRUCTION_MENU_UP_DOWN = "AXIS_CONSTRUCTION_MENU_UP_DOWN"
InputAction.AXIS_CONSTRUCTION_MENU_LEFT_RIGHT = "AXIS_CONSTRUCTION_MENU_LEFT_RIGHT"
InputAction.AXIS_BRAKE_VEHICLE = "AXIS_BRAKE_VEHICLE"
InputAction.AXIS_ACCELERATE_VEHICLE = "AXIS_ACCELERATE_VEHICLE"
InputAction.AXIS_MOVE_SIDE_VEHICLE = "AXIS_MOVE_SIDE_VEHICLE"
InputAction.AXIS_LOOK_UPDOWN_VEHICLE = "AXIS_LOOK_UPDOWN_VEHICLE"
InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE = "AXIS_LOOK_LEFTRIGHT_VEHICLE"
InputAction.AXIS_HYDRAULICATTACHER1 = "AXIS_HYDRAULICATTACHER1"
InputAction.AXIS_HYDRAULICATTACHER2 = "AXIS_HYDRAULICATTACHER2"
InputAction.AXIS_FRONTLOADER_ARM = "AXIS_FRONTLOADER_ARM"
InputAction.AXIS_FRONTLOADER_ARM2 = "AXIS_FRONTLOADER_ARM2"
InputAction.AXIS_FRONTLOADER_TOOL = "AXIS_FRONTLOADER_TOOL"
InputAction.AXIS_FRONTLOADER_TOOL2 = "AXIS_FRONTLOADER_TOOL2"
InputAction.AXIS_FRONTLOADER_TOOL3 = "AXIS_FRONTLOADER_TOOL3"
InputAction.AXIS_FRONTLOADER_TOOL4 = "AXIS_FRONTLOADER_TOOL4"
InputAction.AXIS_FRONTLOADER_TOOL5 = "AXIS_FRONTLOADER_TOOL5"
InputAction.AXIS_CRANE_ARM = "AXIS_CRANE_ARM"
InputAction.AXIS_CRANE_ARM2 = "AXIS_CRANE_ARM2"
InputAction.AXIS_CRANE_ARM3 = "AXIS_CRANE_ARM3"
InputAction.AXIS_CRANE_ARM4 = "AXIS_CRANE_ARM4"
InputAction.AXIS_CRANE_TOOL = "AXIS_CRANE_TOOL"
InputAction.AXIS_CRANE_TOOL2 = "AXIS_CRANE_TOOL2"
InputAction.AXIS_CRANE_TOOL3 = "AXIS_CRANE_TOOL3"
InputAction.AXIS_CUTTER_REEL = "AXIS_CUTTER_REEL"
InputAction.AXIS_CUTTER_REEL2 = "AXIS_CUTTER_REEL2"
InputAction.AXIS_PIPE = "AXIS_PIPE"
InputAction.AXIS_PIPE2 = "AXIS_PIPE2"
InputAction.AXIS_DRAWBAR = "AXIS_DRAWBAR"
InputAction.AXIS_DRAWBAR2 = "AXIS_DRAWBAR2"
InputAction.AXIS_SPRAYER_ARM = "AXIS_SPRAYER_ARM"
InputAction.AXIS_WHEEL_BASE = "AXIS_WHEEL_BASE"
InputAction.AXIS_CRUISE_CONTROL = "AXIS_CRUISE_CONTROL"
InputAction.SWITCH_HANDTOOL = "SWITCH_HANDTOOL"
InputAction.AXIS_LOOK_LEFTRIGHT_DRAG = "AXIS_LOOK_LEFTRIGHT_DRAG"
InputAction.AXIS_LOOK_UPDOWN_DRAG = "AXIS_LOOK_UPDOWN_DRAG"
InputAction.MENU_EXTRA_1 = "MENU_EXTRA_1"
InputAction.MENU_EXTRA_2 = "MENU_EXTRA_2"
InputAction.CONSOLE_ALT_COMMAND_BUTTON = "CONSOLE_ALT_COMMAND_BUTTON"
InputAction.CONSOLE_ALT_COMMAND2_BUTTON = "CONSOLE_ALT_COMMAND2_BUTTON"
InputAction.CONSOLE_ALT_COMMAND3_BUTTON = "CONSOLE_ALT_COMMAND3_BUTTON"
InputAction.MOUSE_ALT_COMMAND_BUTTON = "MOUSE_ALT_COMMAND_BUTTON"
InputAction.MOUSE_ALT_COMMAND2_BUTTON = "MOUSE_ALT_COMMAND2_BUTTON"
InputAction.MOUSE_ALT_COMMAND3_BUTTON = "MOUSE_ALT_COMMAND3_BUTTON"
InputAction.MOUSE_ALT_COMMAND4_BUTTON = "MOUSE_ALT_COMMAND4_BUTTON"
InputAction.UNLOAD = "UNLOAD"
InputAction.LINKED_ACTIONS = {
	[InputAction.AXIS_LOOK_LEFTRIGHT_PLAYER] = InputAction.AXIS_LOOK_UPDOWN_PLAYER,
	[InputAction.AXIS_LOOK_UPDOWN_PLAYER] = InputAction.AXIS_LOOK_LEFTRIGHT_PLAYER,
	[InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE] = InputAction.AXIS_LOOK_UPDOWN_VEHICLE,
	[InputAction.AXIS_LOOK_UPDOWN_VEHICLE] = InputAction.AXIS_LOOK_LEFTRIGHT_VEHICLE,
	[InputAction.CAMERA_ZOOM_IN] = InputAction.CAMERA_ZOOM_OUT,
	[InputAction.CAMERA_ZOOM_OUT] = InputAction.CAMERA_ZOOM_IN
}
InputAction.EXCLUSIVE_ACTION_GROUPS = {
	MENU = {
		InputAction.MENU_ACCEPT,
		InputAction.MENU_ACTIVATE,
		InputAction.MENU_BACK,
		InputAction.MENU_CANCEL,
		InputAction.MENU_EXTRA_1,
		InputAction.MENU_EXTRA_2,
		InputAction.MENU_AXIS_LEFT_RIGHT,
		InputAction.MENU_AXIS_UP_DOWN
	}
}
