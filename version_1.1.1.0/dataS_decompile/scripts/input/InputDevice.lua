InputDevice = {}
local InputDevice_mt = Class(InputDevice)
InputDevice.CATEGORY = {
	FARMWHEEL_AND_PANEL = 255,
	WHEEL_AND_PANEL = 254,
	KEYBOARD_MOUSE = 253,
	UNKNOWN = GamepadCategories.CATEGORY_UNKNOWN,
	GAMEPAD = GamepadCategories.CATEGORY_GAMEPAD,
	WHEEL = GamepadCategories.CATEGORY_WHEEL,
	JOYSTICK = GamepadCategories.CATEGORY_JOYSTICK,
	FARMWHEEL = GamepadCategories.CATEGORY_FARMWHEEL,
	FARMPANEL = GamepadCategories.CATEGORY_FARMSIDEPANEL
}
InputDevice.DEFAULT_DEVICE_NAMES = {
	JOYSTICK_DEFAULT = "JOYSTICK_DEFAULT",
	FARM_WHEEL_DEFAULT = "FARM_WHEEL_DEFAULT",
	PANEL_DEFAULT = "PANEL_DEFAULT",
	KB_MOUSE_DEFAULT = "KB_MOUSE_DEFAULT",
	GAMEPAD_DEFAULT = "GAMEPAD_DEFAULT",
	WHEEL_DEFAULT = "WHEEL_DEFAULT"
}
InputDevice.NAMES = {
	SWITCH_GAMEPAD = "Nintendo Controller",
	STADIA_GAMEPAD = "Stadia Controller",
	XBOX_GAMEPAD = "XBox Controller",
	XINPUT_GAMEPAD = "XINPUT_GAMEPAD",
	PS_GAMEPAD = "DUALSHOCK(R)4",
	SAITEK_WHEEL = "Saitek Heavy Eqpt. Wheel & Pedal",
	SAITEK_PANEL = "Saitek Side Panel Control Deck"
}
InputDevice.DEFAULT_DEVICE_CATEGORIES = {
	[InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT] = InputDevice.CATEGORY.KEYBOARD_MOUSE,
	[InputDevice.DEFAULT_DEVICE_NAMES.GAMEPAD_DEFAULT] = InputDevice.CATEGORY.GAMEPAD,
	[InputDevice.DEFAULT_DEVICE_NAMES.JOYSTICK_DEFAULT] = InputDevice.CATEGORY.JOYSTICK,
	[InputDevice.DEFAULT_DEVICE_NAMES.WHEEL_DEFAULT] = InputDevice.CATEGORY.WHEEL,
	[InputDevice.DEFAULT_DEVICE_NAMES.FARM_WHEEL_DEFAULT] = InputDevice.CATEGORY.FARMWHEEL,
	[InputDevice.DEFAULT_DEVICE_NAMES.PANEL_DEFAULT] = InputDevice.CATEGORY.FARMPANEL
}

function InputDevice.new(internalId, deviceId, deviceName, category)
	local self = setmetatable({}, InputDevice_mt)
	self.internalId = internalId
	self.deviceId = deviceId
	self.deviceName = deviceName
	self.category = category
	self.deadzones = {}
	self.sensitivities = {}
	self.isActive = false
	self.forceFeedbackState = {}

	for i = 0, Input.MAX_NUM_AXES do
		local state = {
			isSupported = nil,
			force = 0,
			position = 0
		}
		self.forceFeedbackState[i] = state
	end

	return self
end

function InputDevice:loadSettingsFromXML(xmlFile, deviceElement)
	self.deadzones = {}
	self.sensitivities = {}
	local attrIndex = 0

	while true do
		local attributeKey = string.format(deviceElement .. ".attributes(%d)", attrIndex)

		if not hasXMLProperty(xmlFile, attributeKey) then
			break
		end

		local axis = getXMLInt(xmlFile, attributeKey .. "#axis")

		if axis then
			local deadzone = getXMLFloat(xmlFile, attributeKey .. "#deadzone")
			self.deadzones[axis] = deadzone or getGamepadDefaultDeadzone()
			local sensitivity = getXMLFloat(xmlFile, attributeKey .. "#sensitivity")
			self.sensitivities[axis] = sensitivity or 1
		end

		attrIndex = attrIndex + 1
	end
end

function InputDevice:saveSettingsToXML(xmlFile, deviceElement)
	setXMLString(xmlFile, deviceElement .. "#id", self.deviceId)
	setXMLString(xmlFile, deviceElement .. "#name", self.deviceName)
	setXMLInt(xmlFile, deviceElement .. "#category", self.category)

	local firstAttributeKey = deviceElement .. ".attributes(0)"

	while hasXMLProperty(xmlFile, firstAttributeKey) do
		removeXMLProperty(xmlFile, firstAttributeKey)
	end

	local writtenIndex = 0

	for axisIndex = 0, Input.MAX_NUM_AXES - 1 do
		local hasAxis = nil
		hasAxis = (self.internalId < 0 or getHasGamepadAxis(axisIndex, self.internalId)) and (self.deadzones[axisIndex] ~= nil or self.sensitivities[axisIndex] ~= nil)

		if hasAxis then
			local attributeKey = string.format(deviceElement .. ".attributes(%d)", writtenIndex)

			setXMLInt(xmlFile, attributeKey .. "#axis", axisIndex)
			setXMLFloat(xmlFile, attributeKey .. "#deadzone", self:getDeadzone(axisIndex))
			setXMLFloat(xmlFile, attributeKey .. "#sensitivity", self:getSensitivity(axisIndex))

			writtenIndex = writtenIndex + 1
		end
	end
end

function InputDevice:isController()
	return self.category and self.category ~= InputDevice.CATEGORY.KEYBOARD_MOUSE
end

function InputDevice:setDeadzone(axisIndex, deadzone)
	self.deadzones[axisIndex] = deadzone
end

function InputDevice:getDeadzone(axisIndex)
	if self.deadzones[axisIndex] ~= nil then
		return self.deadzones[axisIndex]
	end

	return getGamepadDefaultDeadzone()
end

function InputDevice:setSensitivity(axisIndex, sensitivity)
	self.sensitivities[axisIndex] = sensitivity
end

function InputDevice:getSensitivity(axisIndex)
	if self.sensitivities[axisIndex] ~= nil then
		return self.sensitivities[axisIndex]
	end

	return 1
end

function InputDevice:updateForceFeedbackState(axisIndex)
	local axisState = self.forceFeedbackState[axisIndex]

	if axisState ~= nil and axisState.isSupported == nil then
		axisState.isSupported = getHasGamepadAxisForceFeedback(self.internalId, axisIndex)
	end

	return false
end

function InputDevice:getIsForceFeedbackSupported(axisIndex)
	local axisState = self.forceFeedbackState[axisIndex]

	if axisState ~= nil and axisState.isSupported ~= nil then
		return axisState.isSupported
	end

	return false
end

function InputDevice:setForceFeedback(axisIndex, force, position)
	local axisState = self.forceFeedbackState[axisIndex]

	if axisState ~= nil then
		axisState.force = force
		axisState.position = position

		setGamepadAxisForceFeedback(self.internalId, axisIndex, force, position)
	end
end

function InputDevice.loadIdFromXML(xmlFile, deviceElement)
	return getXMLString(xmlFile, deviceElement .. "#id") or ""
end

function InputDevice.loadNameFromXML(xmlFile, deviceElement)
	return getXMLString(xmlFile, deviceElement .. "#name") or ""
end

function InputDevice.loadCategoryFromXML(xmlFile, deviceElement)
	return getXMLInt(xmlFile, deviceElement .. "#category") or InputDevice.CATEGORY.UNKNOWN
end

function InputDevice.getDeviceIdPrefix(deviceId)
	local prefix, engineDeviceId = string.match(deviceId, "^(-?%d+)_(.+)$")
	local number = -1

	if prefix and tonumber(prefix) then
		number = tonumber(prefix)
	end

	return number, engineDeviceId
end

function InputDevice.getPrefixedDeviceId(deviceId, number)
	return string.format("%d_%s", number, deviceId)
end

function InputDevice.getIsDeviceSupported(engineDeviceId, deviceName)
	return true
end

function InputDevice:toString()
	return string.format("[%s (active: %s), internalId: %s, deviceId: %s, category: %s]", tostring(self.deviceName), tostring(self.isActive), tostring(self.internalId), tostring(self.deviceId), tostring(self.category))
end

InputDevice_mt.__tostring = InputDevice.toString
