FocusManager = {
	RIGHT = "right",
	BOTTOM = "bottom",
	DELAY_TIME = 50,
	FIRST_LOCK = 250,
	TOP = "top",
	LEFT = "left",
	EPSILON = 1e-05,
	guiFocusData = {},
	currentFocusData = {}
}
FocusManager.currentFocusData.focusElement = nil
FocusManager.currentFocusData.highlightElement = nil
FocusManager.currentFocusData.initialFocusElement = nil
FocusManager.isFocusLocked = false
FocusManager.lastInput = {}
FocusManager.lockUntil = {}
FocusManager.autoIDcount = 0
FocusManager.OPPOSING_DIRECTIONS = {
	[FocusManager.TOP] = FocusManager.BOTTOM,
	[FocusManager.BOTTOM] = FocusManager.TOP,
	[FocusManager.LEFT] = FocusManager.RIGHT,
	[FocusManager.RIGHT] = FocusManager.LEFT
}
FocusManager.DIRECTION_VECTORS = {
	[FocusManager.TOP] = {
		0,
		1
	},
	[FocusManager.BOTTOM] = {
		0,
		-1
	},
	[FocusManager.LEFT] = {
		-1,
		0
	},
	[FocusManager.RIGHT] = {
		1,
		0
	}
}
FocusManager.DEBUG = false
FocusManager.allElements = {}
local allElements_mt = {}

setmetatable(FocusManager.allElements, allElements_mt)

allElements_mt.__mode = "k"

function FocusManager:setGui(gui)
	if self.currentFocusData then
		local focusElement = self.currentFocusData.focusElement

		if focusElement then
			self:unsetFocus(focusElement)
		end
	end

	self.currentGui = gui
	self.currentFocusData = self.guiFocusData[gui]

	if not self.currentFocusData then
		self.guiFocusData[gui] = {
			idToElementMapping = {}
		}
		self.currentFocusData = self.guiFocusData[gui]
	else
		local focusElement = self.currentFocusData.initialFocusElement or self.currentFocusData.focusElement

		if focusElement ~= nil then
			self:setFocus(focusElement)
		end
	end

	self:resetFocusInputLocks()
end

function FocusManager:setSoundPlayer(guiSoundPlayer)
	self.soundPlayer = guiSoundPlayer
end

function FocusManager:getElementById(id)
	return self.currentFocusData.idToElementMapping[id]
end

function FocusManager:getFocusedElement()
	return self.currentFocusData.focusElement
end

function FocusManager.serveAutoFocusId()
	local focusId = string.format("focusAuto_%d", FocusManager.autoIDcount)
	FocusManager.autoIDcount = FocusManager.autoIDcount + 1

	return focusId
end

function FocusManager:loadElementFromXML(xmlFile, xmlBaseNode, element)
	local focusId = getXMLString(xmlFile, xmlBaseNode .. "#focusId")
	focusId = focusId or FocusManager.serveAutoFocusId()
	element.focusId = focusId
	element.focusChangeData = {}

	if not element.focusChangeData[FocusManager.TOP] then
		element.focusChangeData[FocusManager.TOP] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeTop")
	end

	if not element.focusChangeData[FocusManager.BOTTOM] then
		element.focusChangeData[FocusManager.BOTTOM] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeBottom")
	end

	if not element.focusChangeData[FocusManager.LEFT] then
		element.focusChangeData[FocusManager.LEFT] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeLeft")
	end

	if not element.focusChangeData[FocusManager.RIGHT] then
		element.focusChangeData[FocusManager.RIGHT] = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeRight")
	end

	element.focusActive = getXMLString(xmlFile, xmlBaseNode .. "#focusInit") ~= nil
	local isAlwaysFocusedOnOpen = getXMLString(xmlFile, xmlBaseNode .. "#focusInit") == "onOpen"
	element.isAlwaysFocusedOnOpen = isAlwaysFocusedOnOpen
	local focusChangeOverride = getXMLString(xmlFile, xmlBaseNode .. "#focusChangeOverride")

	if focusChangeOverride then
		if element.target and element.target.focusChangeOverride then
			element.focusChangeOverride = element.target[focusChangeOverride]
		else
			self.focusChangeOverride = ClassUtil.getFunction(focusChangeOverride)
		end
	end

	if FocusManager.allElements[element] == nil then
		FocusManager.allElements[element] = {}
	end

	table.insert(FocusManager.allElements[element], self.currentGui)

	self.currentFocusData.idToElementMapping[focusId] = element

	if isAlwaysFocusedOnOpen then
		self.currentFocusData.initialFocusElement = element
		local old = element.soundDisabled
		element.soundDisabled = true

		self:setFocus(element)

		element.soundDisabled = old
	elseif not self.currentFocusData.focusElement then
		self.currentFocusData.focusElement = element
	end
end

function FocusManager:loadElementFromCustomValues(element, focusId, focusChangeData, focusActive, isAlwaysFocusedOnOpen)
	if focusId and self.currentFocusData.idToElementMapping[focusId] then
		return false
	end

	if not element.focusId then
		focusId = focusId or FocusManager.serveAutoFocusId()
		element.focusId = focusId
	end

	element.focusChangeData = element.focusChangeData or focusChangeData or {}
	element.focusActive = focusActive
	element.isAlwaysFocusedOnOpen = isAlwaysFocusedOnOpen

	if FocusManager.allElements[element] == nil then
		FocusManager.allElements[element] = {}
	end

	table.insert(FocusManager.allElements[element], self.currentGui)

	self.currentFocusData.idToElementMapping[element.focusId] = element

	if isAlwaysFocusedOnOpen then
		self.currentFocusData.initialFocusElement = element
	end

	if focusActive then
		self:setFocus(element)
	end

	local success = true

	for _, child in pairs(element.elements) do
		success = success and self:loadElementFromCustomValues(child, child.focusId, child.focusChangeData, child.focusActive, child.isAlwaysFocusedOnOpen)
	end

	return success
end

function FocusManager:removeElement(element)
	if not element.focusId then
		return
	end

	for _, child in pairs(element.elements) do
		self:removeElement(child)
	end

	if element.focusActive then
		element:onFocusLeave()
		FocusManager:unsetFocus(element)
	end

	if FocusManager.allElements[element] ~= nil then
		for _, guiItWasAddedTo in ipairs(FocusManager.allElements[element]) do
			local data = self.guiFocusData[guiItWasAddedTo]
			data.idToElementMapping[element.focusId] = nil

			if data.focusElement == element then
				data.focusElement = nil
			end
		end

		FocusManager.allElements[element] = nil
	end

	self.currentFocusData.idToElementMapping[element.focusId] = nil
	element.focusId = nil
	element.focusChangeData = {}

	if self.currentFocusData.focusElement == element then
		self.currentFocusData.focusElement = nil
	end
end

function FocusManager:linkElements(sourceElement, direction, targetElement)
	if targetElement == nil then
		sourceElement.focusChangeData[direction] = "nil"
	else
		sourceElement.focusChangeData[direction] = targetElement.focusId
	end
end

function FocusManager:inputEvent(action, value, eventUsed)
	local element = self.currentFocusData.focusElement
	local pressedAccept = false
	local pressedUp = action == InputAction.MENU_AXIS_UP_DOWN and g_analogStickVTolerance < value
	local pressedDown = action == InputAction.MENU_AXIS_UP_DOWN and value < -g_analogStickVTolerance
	local pressedLeft = action == InputAction.MENU_AXIS_LEFT_RIGHT and value < -g_analogStickHTolerance
	local pressedRight = action == InputAction.MENU_AXIS_LEFT_RIGHT and g_analogStickHTolerance < value

	if action == InputAction.MENU_AXIS_UP_DOWN then
		self:updateFocus(element, pressedUp, FocusManager.TOP, eventUsed)
		self:updateFocus(element, pressedDown, FocusManager.BOTTOM, eventUsed)
	elseif action == InputAction.MENU_AXIS_LEFT_RIGHT then
		self:updateFocus(element, pressedLeft, FocusManager.LEFT, eventUsed)
		self:updateFocus(element, pressedRight, FocusManager.RIGHT, eventUsed)
	end

	if not eventUsed and element ~= nil and not element.needExternalClick then
		pressedAccept = action == InputAction.MENU_ACCEPT

		if pressedAccept and not self:isFocusInputLocked(action) and element.focusActive and element:getIsVisible() then
			self.focusSystemMadeChanges = true

			element:onFocusActivate()

			self.focusSystemMadeChanges = false
		end
	end

	return eventUsed or pressedUp or pressedDown or pressedLeft or pressedRight or pressedAccept
end

function FocusManager.getDirectionForAxisValue(inputAction, value)
	if value == nil then
		return nil
	end

	local direction = nil

	if inputAction == InputAction.MENU_AXIS_UP_DOWN then
		if value < 0 then
			direction = FocusManager.BOTTOM
		elseif value > 0 then
			direction = FocusManager.TOP
		end
	elseif inputAction == InputAction.MENU_AXIS_LEFT_RIGHT then
		if value < 0 then
			direction = FocusManager.LEFT
		elseif value > 0 then
			direction = FocusManager.RIGHT
		end
	end

	return direction
end

function FocusManager:isFocusInputLocked(inputAxis, value)
	local key = FocusManager.getDirectionForAxisValue(inputAxis, value)

	if key == nil and inputAxis ~= InputAction.MENU_AXIS_UP_DOWN and inputAxis ~= InputAction.MENU_AXIS_LEFT_RIGHT then
		key = inputAxis
	end

	if self.lastInput[key] and g_time < self.lockUntil[key] then
		return true
	else
		return false
	end
end

function FocusManager:lockFocusInput(axisAction, delay, value)
	local key = FocusManager.getDirectionForAxisValue(axisAction, value)

	if not key and axisAction ~= InputAction.MENU_AXIS_UP_DOWN and axisAction ~= InputAction.MENU_AXIS_LEFT_RIGHT then
		key = axisAction
	end

	self.lastInput[key] = g_time
	self.lockUntil[key] = g_time + delay
end

function FocusManager:releaseMovementFocusInput(action)
	if action == InputAction.MENU_AXIS_LEFT_RIGHT then
		self.lastInput[FocusManager.LEFT] = nil
		self.lockUntil[FocusManager.LEFT] = nil
		self.lastInput[FocusManager.RIGHT] = nil
		self.lockUntil[FocusManager.RIGHT] = nil
	elseif action == InputAction.MENU_AXIS_UP_DOWN then
		self.lastInput[FocusManager.TOP] = nil
		self.lockUntil[FocusManager.TOP] = nil
		self.lastInput[FocusManager.BOTTOM] = nil
		self.lockUntil[FocusManager.BOTTOM] = nil
	end
end

function FocusManager:resetFocusInputLocks()
	for k, _ in pairs(self.lastInput) do
		self.lastInput[k] = nil
	end

	for k, _ in pairs(self.lockUntil) do
		self.lockUntil[k] = 0
	end
end

function FocusManager.getClosestPointOnBoundingBox(x, y, boxMinX, boxMinY, boxMaxX, boxMaxY)
	local px = x
	local py = y

	if x < boxMinX then
		px = boxMinX
	elseif boxMaxX < x then
		px = boxMaxX
	end

	if y < boxMinY then
		py = boxMinY
	elseif boxMaxY < y then
		py = boxMaxY
	end

	return px, py
end

function FocusManager.getShortestBoundingBoxVector(elementBox, otherBox, otherCenter)
	local ePointX, ePointY = FocusManager.getClosestPointOnBoundingBox(otherCenter[1], otherCenter[2], elementBox[1], elementBox[2], elementBox[3], elementBox[4])
	local oPointX, oPointY = FocusManager.getClosestPointOnBoundingBox(ePointX, ePointY, otherBox[1], otherBox[2], otherBox[3], otherBox[4])
	local elementDirX = oPointX - ePointX
	local elementDirY = oPointY - ePointY

	return elementDirX, elementDirY
end

function FocusManager.checkElementDistance(curElement, other, dirX, dirY, curElementOffsetY, closestOther, closestDistanceSq)
	local retOther = closestOther
	local retDistSq = closestDistanceSq
	local elementBox = curElement:getBorders()
	elementBox[2] = elementBox[2] + curElementOffsetY
	elementBox[4] = elementBox[4] + curElementOffsetY
	local elementCenter = curElement:getCenter()
	elementCenter[2] = elementCenter[2] + curElementOffsetY

	if other ~= curElement and not other.disabled and other:getIsVisible() and other:canReceiveFocus() and not other:isChildOf(curElement) and not curElement:isChildOf(other) then
		local otherBox = other:getBorders()
		local otherCenter = other:getCenter()
		local elementDirX, elementDirY = FocusManager.getShortestBoundingBoxVector(elementBox, otherBox, otherCenter)
		local boxDistanceSq = MathUtil.vector2LengthSq(elementDirX, elementDirY)
		local dot = MathUtil.dotProduct(elementDirX, elementDirY, 0, dirX, dirY, 0)

		if boxDistanceSq < FocusManager.EPSILON then
			dot = MathUtil.dotProduct(otherCenter[1] - elementCenter[1], otherCenter[2] - elementCenter[2], 0, dirX, dirY, 0)
		end

		if dot > 0 then
			local useOther = false

			if closestOther and math.abs(closestDistanceSq - boxDistanceSq) < FocusManager.EPSILON then
				local closestBox = closestOther:getBorders()
				local closestCenter = closestOther:getCenter()
				local toClosestX, toClosestY = FocusManager.getShortestBoundingBoxVector(elementBox, closestBox, closestCenter)
				local closestDot = MathUtil.dotProduct(toClosestX, toClosestY, 0, dirX, dirY, 0)

				if math.abs(closestDot - dot) < FocusManager.EPSILON then
					if dirY > 0 then
						useOther = closestOther.absPosition[1] < other.absPosition[1]
					elseif dirY < 0 then
						useOther = other.absPosition[1] < closestOther.absPosition[1]
					elseif dirX > 0 then
						useOther = closestOther.absPosition[2] < other.absPosition[2]
					elseif dirX < 0 then
						useOther = other.absPosition[2] < closestOther.absPosition[2]
					end
				elseif closestDot < dot then
					useOther = true
				end
			elseif boxDistanceSq < closestDistanceSq then
				useOther = true
			end

			if useOther then
				retOther = other
				retDistSq = boxDistanceSq
			end
		end
	end

	return retOther, retDistSq
end

function FocusManager:getNextFocusElement(element, direction)
	local nextFocusId = element.focusChangeData[direction]

	if nextFocusId then
		return self.currentFocusData.idToElementMapping[nextFocusId], direction
	end

	local dirX, dirY = unpack(FocusManager.DIRECTION_VECTORS[direction])
	local closestOther = nil
	local closestDistance = math.huge

	for _, other in pairs(self.currentFocusData.idToElementMapping) do
		closestOther, closestDistance = FocusManager.checkElementDistance(element, other, dirX, dirY, 0, closestOther, closestDistance)
	end

	if closestOther == nil then
		if direction == FocusManager.LEFT then
			closestOther, direction = self:getNextFocusElement(element, FocusManager.TOP)
		elseif direction == FocusManager.RIGHT then
			closestOther, direction = self:getNextFocusElement(element, FocusManager.BOTTOM)
		else
			local validWrapElements = self.currentFocusData.idToElementMapping

			if element.parent and element.parent.wrapAround then
				validWrapElements = element.parent.elements
			end

			local wrapOffsetY = 0

			if direction == FocusManager.TOP then
				wrapOffsetY = -1.2 - element.size[2]
			elseif direction == FocusManager.BOTTOM then
				wrapOffsetY = 1.2 + element.size[2]
			end

			for _, other in pairs(validWrapElements) do
				closestOther, closestDistance = FocusManager.checkElementDistance(element, other, dirX, dirY, wrapOffsetY, closestOther, closestDistance)
			end
		end
	end

	return closestOther, direction
end

function FocusManager.getNestedFocusTarget(element, direction)
	local target = element
	local prevTarget = nil

	while target and prevTarget ~= target do
		prevTarget = target
		target = target:getFocusTarget(FocusManager.OPPOSING_DIRECTIONS[direction], direction)
	end

	return target
end

function FocusManager:updateFocus(element, isFocusMoving, direction, updateOnly)
	if element == nil then
		return
	end

	if isFocusMoving then
		if self.lastInput[direction] then
			if self.lockUntil[direction] <= g_time then
				self.lastInput[direction] = nil
				self.lockJustReleased = true
			end

			return
		end

		if updateOnly then
			return
		end

		self.lastInput[direction] = g_time

		if self.lockJustReleased then
			self.lockUntil[direction] = g_time + self.DELAY_TIME
		else
			self.lockUntil[direction] = g_time + self.FIRST_LOCK
		end

		self.lockJustReleased = false

		if self.currentFocusData.focusElement ~= element then
			return
		end

		if element:shouldFocusChange(direction) then
			local nextElement, nextElementIsSet = nil

			if element.focusChangeOverride then
				if element.target then
					nextElementIsSet, nextElement = element.focusChangeOverride(element.target, direction)
				else
					nextElementIsSet, nextElement = element:focusChangeOverride(direction)
				end
			end

			local actualDirection = direction

			if not nextElementIsSet then
				nextElement, actualDirection = self:getNextFocusElement(element, direction)
			end

			if nextElement and nextElement:canReceiveFocus() then
				self:setFocus(nextElement, actualDirection)

				return nextElement
			else
				local focusElement = element
				nextElement = element

				if not element.focusChangeOverride or not element:focusChangeOverride(direction) then
					local maxSteps = 30

					while maxSteps > 0 do
						if nextElement == nil then
							break
						end

						nextElement, actualDirection = self:getNextFocusElement(nextElement, direction)

						if nextElement ~= nil and nextElement:canReceiveFocus() then
							focusElement = nextElement

							break
						end

						maxSteps = maxSteps - 1
					end
				end

				self:setFocus(focusElement, actualDirection)
			end
		end
	end
end

function FocusManager:setHighlight(element)
	if self.currentFocusData.highlightElement and self.currentFocusData.highlightElement == element then
		return
	end

	self:unsetHighlight(self.currentFocusData.highlightElement)

	if not element.disallowFocusedHighlight or not self.currentFocusData.focusElement or self.currentFocusData.focusElement ~= element then
		self.currentFocusData.highlightElement = element

		element:storeOverlayState()
		element:setOverlayState(GuiOverlay.STATE_HIGHLIGHTED)
		element:onHighlight()

		if not element:getSoundSuppressed() and element:getIsVisible() and element.playHoverSoundOnFocus ~= false and not element.soundDisabled then
			self.soundPlayer:playSample(GuiSoundPlayer.SOUND_SAMPLES.HOVER)
		end
	end
end

function FocusManager:unsetHighlight(element)
	if self.currentFocusData.highlightElement and self.currentFocusData.highlightElement == element then
		local prevState = self.currentFocusData.highlightElement:getOverlayState()

		if prevState == GuiOverlay.STATE_HIGHLIGHTED then
			self.currentFocusData.highlightElement:setOverlayState(GuiOverlay.STATE_NORMAL)
			self.currentFocusData.highlightElement:restoreOverlayState()
		end

		self.currentFocusData.highlightElement:onHighlightRemove()

		self.currentFocusData.highlightElement = nil
	end
end

function FocusManager:setFocus(element, direction, ...)
	if FocusManager.isFocusLocked or element == nil or not element:canReceiveFocus() then
		return false
	end

	local targetElement = FocusManager.getNestedFocusTarget(element, direction)

	if targetElement.targetName ~= self.currentGui then
		return false
	end

	if self.currentFocusData.focusElement and self.currentFocusData.focusElement == targetElement and self.currentFocusData.focusElement.focusActive then
		return false
	end

	if self.currentFocusData.focusElement ~= nil then
		self:unsetFocus(self.currentFocusData.focusElement)
		self:unsetHighlight(self.currentFocusData.highlightElement)
	end

	targetElement.focusActive = true
	self.currentFocusData.focusElement = targetElement

	targetElement:onFocusEnter(...)

	if FocusManager.DEBUG then
		log("focus changed to element", targetElement, "; ID:", targetElement.id, "; profile:", targetElement.profile, "; type:", targetElement.typeName)
	end

	self:setElementFocusOverlayState(targetElement, true)

	if not element:getSoundSuppressed() and element:getIsVisible() and element.playHoverSoundOnFocus ~= false and not element.soundDisabled then
		self.soundPlayer:playSample(targetElement.customFocusSample or GuiSoundPlayer.SOUND_SAMPLES.HOVER)
	end

	return true
end

function FocusManager:unsetFocus(element, ...)
	local prevFocusElement = self.currentFocusData.focusElement

	if prevFocusElement ~= element or prevFocusElement == nil then
		return
	end

	if not element.focusActive then
		return
	end

	prevFocusElement.focusActive = false

	self:setElementFocusOverlayState(prevFocusElement, false)
	prevFocusElement:onFocusLeave(...)
end

function FocusManager:setElementFocusOverlayState(element, isFocused, handlePreviousState)
	if handlePreviousState == nil then
		handlePreviousState = true
	end

	if isFocused then
		if handlePreviousState and element:getOverlayState() ~= GuiOverlay.STATE_NORMAL then
			element:storeOverlayState()
		end

		element:setOverlayState(GuiOverlay.STATE_FOCUSED)
	else
		if handlePreviousState then
			element:restoreOverlayState()
		end

		if element:getOverlayState() == GuiOverlay.STATE_FOCUSED then
			element:setOverlayState(GuiOverlay.STATE_NORMAL)
		end
	end
end

function FocusManager:requireLock()
	FocusManager.isFocusLocked = true
end

function FocusManager:releaseLock()
	FocusManager.isFocusLocked = false
end

function FocusManager:isLocked()
	return FocusManager.isFocusLocked
end

function FocusManager:isDirectionLocked(direction)
	return self.lastInput[direction] ~= nil
end

function FocusManager:hasFocus(element)
	return self.currentFocusData.focusElement == element and element.focusActive
end

function FocusManager:getFocusOverrideFunction(forDirections, substitute, useSubstituteForFocus)
	if forDirections == nil or #forDirections < 1 then
		return function (elementSelf, dir)
			return false, nil
		end
	end

	local function f(elementSelf, dir)
		for _, overrideDirection in pairs(forDirections) do
			if dir == overrideDirection then
				if useSubstituteForFocus then
					local next = self:getNextFocusElement(substitute, dir)

					if next then
						return true, next
					end
				else
					return true, substitute
				end
			end
		end

		return false, nil
	end

	return f
end

function FocusManager:drawDebug()
	if self.currentFocusData.focusElement ~= nil then
		local element = self.currentFocusData.focusElement

		if element.focusActive then
			local overlay = Overlay.new(g_baseUIFilename, element.absPosition[1], element.absPosition[2], element.size[1], element.size[2])

			overlay:setColor(1, 0, 0, 0.5)
			overlay:setUVs(g_colorBgUVs)
			overlay:setAlignment(Overlay.ALIGN_VERTICAL_BOTTOM, Overlay.ALIGN_HORIZONTAL_LEFT)
			overlay:render()
		end
	end
end
