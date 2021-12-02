Binding = {}
local Binding_mt = Class(Binding)
Binding.AXIS_COMPONENT = {
	NEGATIVE = "-",
	POSITIVE = "+"
}
Binding.INPUT_COMPONENT = {
	NEGATIVE = "-",
	POSITIVE = "+"
}
Binding.MAX_ALTERNATIVES_KB_MOUSE = 3
Binding.MAX_ALTERNATIVES_GAMEPAD = 2
Binding.PRESSED_MAGNITUDE_THRESHOLD = 0.1
Binding.PS_JAPAN_BUTTON_SWAP_MAP = {
	BUTTON_3 = "BUTTON_2",
	BUTTON_2 = "BUTTON_3"
}

function Binding.new(deviceId, axisNames, axisComponent, inputComponent, neutralInput, index)
	local self = setmetatable({}, Binding_mt)
	self.axisComponent = axisComponent
	self.index = index

	if self.axisComponent == Binding.AXIS_COMPONENT.POSITIVE then
		self.axisDirection = 1
	else
		self.axisDirection = -1
	end

	self.id = nil
	self.comboMask = 0
	self.deviceId = nil
	self.deviceCategory = InputDevice.CATEGORY.UNKNOWN
	self.internalDeviceId = nil
	self.axisNameSet = nil
	self.inputString = ""
	self.unmodifiedAxis = nil
	self.modifierAxisSet = nil
	self.axisNames = {}
	self.inputComponent = nil
	self.inputDirection = 0
	self.neutralInput = neutralInput
	self.isMouse = false
	self.isKeyboard = false
	self.isGamepad = false
	self.isPrimary = false

	self:updateData(deviceId, nil, axisNames, inputComponent, true)

	self.isAnalog = false
	self.inputValue = 0
	self.isInputActive = false
	self.isDown = false
	self.isUp = false
	self.wasUp = true
	self.wasDown = false
	self.isPressed = false
	self.isShadowed = false
	self.isActive = true
	self.hasFrameTriggered = false

	return self
end

function Binding.createFromXML(xmlFile, elementTag)
	local deviceId = getXMLString(xmlFile, elementTag .. "#device")
	local axisNamesText = getXMLString(xmlFile, elementTag .. "#input") or ""
	local axisNames = axisNamesText:split(" ")
	local axisComponent = getXMLString(xmlFile, elementTag .. "#axisComponent")

	if axisComponent ~= Binding.AXIS_COMPONENT.POSITIVE and axisComponent ~= Binding.AXIS_COMPONENT.NEGATIVE then
		axisComponent = Binding.AXIS_COMPONENT.POSITIVE
	end

	local inputComponent = getXMLString(xmlFile, elementTag .. "#inputComponent")

	if inputComponent ~= Binding.INPUT_COMPONENT.POSITIVE and inputComponent ~= Binding.INPUT_COMPONENT.NEGATIVE then
		inputComponent = Binding.INPUT_COMPONENT.POSITIVE

		if #axisNames > 0 and axisNames[#axisNames]:sub(axisNames[#axisNames]:len()) == "-" then
			inputComponent = Binding.INPUT_COMPONENT.NEGATIVE
		end
	end

	local neutralInput = getXMLInt(xmlFile, elementTag .. "#neutralInput") or 0
	local index = getXMLInt(xmlFile, elementTag .. "#index") or -1

	return Binding.new(deviceId, axisNames, axisComponent, inputComponent, neutralInput, index)
end

function Binding:saveToXMLFile(xmlFile, elementTag)
	setXMLString(xmlFile, elementTag .. "#device", self.deviceId)

	local inputValue = table.concat(self.axisNames, " ")

	setXMLString(xmlFile, elementTag .. "#input", inputValue)
	setXMLString(xmlFile, elementTag .. "#axisComponent", self.axisComponent)
	setXMLInt(xmlFile, elementTag .. "#neutralInput", self.neutralInput)
	setXMLInt(xmlFile, elementTag .. "#index", self.index)
end

function Binding:updateData(deviceId, deviceCategory, axisNames, inputComponent, isInit)
	if axisNames ~= nil then
		self.axisNames = {}

		for _, axisName in ipairs(axisNames) do
			table.insert(self.axisNames, axisName)
		end

		if isInit and Binding.needJapanesePlaystationButtonSwap() then
			Binding.swapJapanesePlaystationButtons(self.axisNames)
		end
	end

	inputComponent = inputComponent or self.inputComponent

	if not inputComponent or inputComponent == Binding.INPUT_COMPONENT.POSITIVE then
		self.inputComponent = Binding.INPUT_COMPONENT.POSITIVE
		self.inputDirection = 1
	else
		self.inputComponent = Binding.INPUT_COMPONENT.NEGATIVE
		self.inputDirection = -1
	end

	if #self.axisNames > 0 then
		local axisName = self.axisNames[#self.axisNames]
		local s = axisName:sub(axisName:len())

		if s == "-" or s == "+" then
			axisName = axisName:sub(1, axisName:len() - 1)
		end

		if self.inputComponent == Binding.INPUT_COMPONENT.NEGATIVE then
			axisName = axisName .. "-"
		elseif InputBinding.getIsPhysicalFullAxis(axisName) then
			axisName = axisName .. "+"
		end

		self.axisNames[#self.axisNames] = axisName
	end

	self.deviceId = deviceId or self.deviceId
	self.deviceCategory = deviceCategory or self.deviceCategory
	self.axisNameSet = table.toSet(self.axisNames)
	self.inputString = table.concat(self.axisNames, " ")
	self.unmodifiedAxis = self.axisNames[#self.axisNames]
	self.modifierAxisSet = {}

	for i = 1, #self.axisNames - 1 do
		local axis = self.axisNames[i]
		self.modifierAxisSet[axis] = axis
	end

	local isKbMouse = self.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
	self.isMouse = isKbMouse and self.index == Binding.MAX_ALTERNATIVES_KB_MOUSE
	self.isKeyboard = isKbMouse and not self.isMouse
	self.isGamepad = self.deviceId ~= nil and not isKbMouse
	self.isPrimary = self.index == 1
end

function Binding:updateInput(inputValue, allInputActive)
	local isPressed = nil

	if self.axisDirection >= 0 then
		self.inputValue = math.max(inputValue, 0)
		isPressed = Binding.PRESSED_MAGNITUDE_THRESHOLD <= inputValue
	else
		self.inputValue = math.min(inputValue, 0)
		isPressed = inputValue <= -Binding.PRESSED_MAGNITUDE_THRESHOLD
	end

	self.isShadowed = false
	self.hasFrameTriggered = false
	local downFlank = isPressed and not self.isPressed and self.wasUp
	local upFlank = not isPressed and self.isPressed
	self.isDown = downFlank
	self.isUp = upFlank
	self.isPressed = isPressed
	self.wasDown = (self.wasDown or downFlank) and not upFlank
	self.wasUp = (self.wasUp or upFlank) and not downFlank
	self.isInputActive = allInputActive or upFlank
end

function Binding:setIsAnalog(isAnalog)
	self.isAnalog = isAnalog
end

function Binding:setIndex(index)
	self.index = index
	self.isPrimary = index == 1
	local isKbMouse = self.deviceId == InputDevice.DEFAULT_DEVICE_NAMES.KB_MOUSE_DEFAULT
	self.isMouse = isKbMouse and self.index == Binding.MAX_ALTERNATIVES_KB_MOUSE
end

function Binding:setActive(isActive)
	self.isActive = isActive
end

function Binding:setFrameTriggered(hasTriggered)
	self.hasFrameTriggered = hasTriggered
end

function Binding:getFrameTriggered()
	return self.hasFrameTriggered
end

function Binding:setComboMask(comboMask)
	self.comboMask = comboMask
end

function Binding:getComboMask()
	return self.comboMask
end

function Binding:hasCollisionWith(otherBinding)
	if self == otherBinding then
		return false
	end

	local sameDevice = self.deviceId == otherBinding.deviceId
	local sameInput = table.equals(self.axisNames, otherBinding.axisNames, true)

	return sameDevice and sameInput
end

function Binding:hasEventCollision(otherBinding)
	if self == otherBinding then
		return true
	end

	local sameDevice = self.deviceId == otherBinding.deviceId
	local sameInput = table.equals(self.axisNames, otherBinding.axisNames, true)
	local sameInputComponent = self.inputComponent == otherBinding.inputComponent

	return sameDevice and sameInput and sameInputComponent
end

function Binding:clone()
	local clone = Binding.new(self.deviceId, self.axisNames, self.axisComponent, self.inputComponent, self.neutralInput, self.index)

	clone:updateData(self.deviceId, self.deviceCategory, self.axisNames, self.inputComponent, false)

	clone.internalDeviceId = self.internalDeviceId
	clone.isAnalog = self.isAnalog
	clone.comboMask = self.comboMask
	clone.isActive = self.isActive

	return clone
end

function Binding:copyInputStateFrom(src)
	self.isDown = src.isDown
	self.isUp = src.isUp
	self.isPressed = src.isPressed
	self.isInputActive = src.isInputActive
	self.wasDown = src.wasDown
	self.wasUp = src.wasUp
end

function Binding:isSameSlot(otherBinding)
	local sameComponent = self.axisComponent == otherBinding.axisComponent
	local sameCategory = self.isKeyboard and otherBinding.isKeyboard or self.isMouse and otherBinding.isMouse or self.isGamepad and otherBinding.isGamepad
	local sameIndex = self.index == otherBinding.index

	return sameComponent and sameCategory and sameIndex
end

function Binding:isSameSlotWithParams(axisComponent, isKbMouse, slotIndex)
	local sameComponent = self.axisComponent == axisComponent
	local sameCategory = (self.isKeyboard or self.isMouse) == isKbMouse
	local sameIndex = self.index == slotIndex

	return sameComponent and sameCategory and sameIndex
end

function Binding.getOppositeAxisComponent(axisComponent)
	if axisComponent == Binding.AXIS_COMPONENT.POSITIVE then
		return Binding.AXIS_COMPONENT.NEGATIVE
	elseif axisComponent == Binding.AXIS_COMPONENT.NEGATIVE then
		return Binding.AXIS_COMPONENT.POSITIVE
	end
end

function Binding.getOppositeInputComponent(inputComponent)
	if inputComponent == Binding.INPUT_COMPONENT.POSITIVE then
		return Binding.INPUT_COMPONENT.NEGATIVE
	elseif inputComponent == Binding.INPUT_COMPONENT.NEGATIVE then
		return Binding.INPUT_COMPONENT.POSITIVE
	end
end

function Binding:makeId()
	if self.id == nil then
		self.id = string.format("%s|%s|%s|%s|%s", self.deviceId, table.concat(self.axisNames, ";"), self.axisComponent, self.neutralInput, self.index)
	end
end

function Binding.needJapanesePlaystationButtonSwap()
	return Platform.isPlaystation and Platform.xoSwap
end

function Binding.swapJapanesePlaystationButtons(axisNames)
	for i, axisName in ipairs(axisNames) do
		local swapAxisName = Binding.PS_JAPAN_BUTTON_SWAP_MAP[axisName]

		if swapAxisName ~= nil then
			axisNames[i] = swapAxisName
		end
	end
end

function Binding:toString()
	return string.format("[(%s), deviceId: %s, axisComponent: %s, index: %s, isActive: %s, isShadowed: %s isInverted: %s, isDown: %s, isUp: %s, inputValue: %s]", table.concat(self.axisNames, ", "), self.deviceId, self.axisComponent, self.index, self.isActive, self.isShadowed, self.isInverted, self.isDown, self.isUp, self.inputValue)
end

Binding_mt.__tostring = Binding.toString
