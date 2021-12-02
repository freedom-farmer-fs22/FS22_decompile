TouchHandler = {}
local TouchHandler_mt = Class(TouchHandler)
TouchHandler.DRAW_DEBUG = false
TouchHandler.TRIGGER_DOWN = 1
TouchHandler.TRIGGER_ALWAYS = 2
TouchHandler.TRIGGER_UP = 3
TouchHandler.GESTURE_AXIS_X = 1
TouchHandler.GESTURE_AXIS_Y = 2
TouchHandler.GESTURE_DOUBLE_TAP = 3
TouchHandler.GESTURE_PINCH = 4
TouchHandler.DOUBLE_TAP_TIME = 250
TouchHandler.MOUSE_TOUCH_ID = -1

function TouchHandler.new()
	local self = setmetatable({}, TouchHandler_mt)
	self.areas = {}
	self.gestureListener = {}
	self.pinchGesture = {}
	self.toTrigger = {}
	self.lastDownTime = 0
	self.lastUpTime = 0
	self.debugLineWidth, self.debugLineHeight = getNormalizedScreenValues(1.5, 1.5)
	self.debugPointWidth, self.debugPointHeight = getNormalizedScreenValues(3, 3)
	self.debugPoints = {}

	return self
end

function TouchHandler:onTouchEvent(posX, posY, isDown, isUp, touchId)
	if TouchHandler.DRAW_DEBUG and isDown then
		self:addDebugPoint(posX, posY)
	end

	if g_gui:getIsGuiVisible() and touchId ~= TouchHandler.MOUSE_TOUCH_ID then
		mouseEvent(posX, posY, isDown, isUp, Input.MOUSE_BUTTON_LEFT)
	end

	local wasInsideAnyArea = false
	local toTrigger = self.toTrigger

	for i = 1, #self.areas do
		local area = self.areas[i]

		if area.lastTouchId == nil or area.lastTouchId == touchId then
			self:updateAreaPosition(area)

			local areaPosX, areaPosY, areaWidth, areaHeight = self:getAreaDimensions(area)
			local isInsideArea = areaPosX < posX and posX < areaPosX + areaWidth and areaPosY < posY and posY < areaPosY + areaHeight
			local isStart = false
			local isAlways = false
			local isEnd = false

			if isInsideArea and area.visibility and not g_gui:getIsGuiVisible() then
				if isUp then
					if area.isPressed then
						isEnd = true
						area.isPressed = false
						area.lastTouchId = nil
					end
				elseif isDown then
					isStart = true
					area.isPressed = true
					area.lastTouchId = touchId
				elseif area.isPressed then
					isAlways = true
				end

				wasInsideAnyArea = true
			elseif area.isPressed then
				isEnd = true
				area.isPressed = false
				area.lastTouchId = nil
				area.isCancel = true
			end

			if isStart and area.triggerType == TouchHandler.TRIGGER_DOWN or isAlways and area.triggerType == TouchHandler.TRIGGER_ALWAYS or isEnd and area.triggerType == TouchHandler.TRIGGER_UP then
				toTrigger[#toTrigger + 1] = area
			end
		end
	end

	for i = 1, #toTrigger do
		self:raiseCallback(toTrigger[i], posX, posY)

		toTrigger[i].isCancel = false
		toTrigger[i] = nil
	end

	if not wasInsideAnyArea and not g_gui:getIsGuiVisible() then
		if isDown then
			self.lastPositionX = posX
			self.lastPositionY = posY
			self.lastDownTime = g_time
		elseif isUp then
			self.lastPositionX = nil
			self.lastPositionY = nil

			if self.lastUpTime ~= nil and self.lastUpTime < self.lastDownTime and g_time - self.lastUpTime < TouchHandler.DOUBLE_TAP_TIME then
				self:raiseGestureEvent(TouchHandler.GESTURE_DOUBLE_TAP)
			end

			self.lastUpTime = g_time
			self.lastUpId = touchId
		end

		local isPinching = false

		if isDown then
			self:onPinchDownEvent(touchId)
		elseif isUp then
			self:onPinchUpEvent(touchId)
		else
			isPinching = self:onPinchUpdateEvent(posX, posY, touchId)
		end

		if not isPinching then
			if self.lastPositionX ~= nil then
				local diff = posX - self.lastPositionX

				self:raiseGestureEvent(TouchHandler.GESTURE_AXIS_X, diff)

				self.lastPositionX = posX
			end

			if self.lastPositionY ~= nil then
				local diff = posY - self.lastPositionY

				self:raiseGestureEvent(TouchHandler.GESTURE_AXIS_Y, diff)

				self.lastPositionY = posY
			end
		else
			self.lastPositionX = nil
			self.lastPositionY = nil
		end
	else
		self:onPinchUpEvent(touchId)
	end
end

function TouchHandler:onPinchDownEvent(touchId)
	if self.lastPositionId ~= nil and self.lastPositionId ~= touchId then
		self.pinchGesture[1] = {
			touchId = touchId
		}
		self.pinchGesture[2] = {
			touchId = self.lastPositionId
		}
	end

	self.lastPositionId = touchId
end

function TouchHandler:onPinchUpdateEvent(posX, posY, touchId)
	local pinch1 = self.pinchGesture[1]
	local pinch2 = self.pinchGesture[2]

	if pinch1 ~= nil and pinch2 ~= nil then
		if pinch1.touchId == touchId and pinch1.lastX ~= nil and pinch2.lastX ~= nil then
			local distance = MathUtil.vector2Length(pinch1.lastX - pinch2.lastX, pinch1.lastY - pinch2.lastY)
			local offset = (pinch1.lastDistance or distance) - distance

			self:raiseGestureEvent(TouchHandler.GESTURE_PINCH, offset)

			pinch1.lastDistance = distance
		end

		local curPinch = pinch1.touchId == touchId and pinch1 or pinch2
		curPinch.lastX = posX
		curPinch.lastY = posY

		return true
	end

	return false
end

function TouchHandler:onPinchUpEvent(touchId)
	for i = 1, 2 do
		if self.pinchGesture[i] ~= nil then
			if self.pinchGesture[i].touchId == touchId then
				if i == 1 then
					self.lastPositionId = self.pinchGesture[2].touchId
				else
					self.lastPositionId = self.pinchGesture[1].touchId
				end

				self.pinchGesture[1] = nil
				self.pinchGesture[2] = nil

				break
			end
		else
			self.lastPositionId = nil
		end
	end
end

function TouchHandler:registerGestureListener(gestureType, callback, callbackTarget)
	local listener = {
		gestureType = gestureType,
		callback = callback,
		callbackTarget = callbackTarget
	}

	table.insert(self.gestureListener, listener)

	return listener
end

function TouchHandler:removeGestureListener(listener)
	table.removeElement(self.gestureListener, listener)
end

function TouchHandler:raiseGestureEvent(gestureType, ...)
	for _, listener in ipairs(self.gestureListener) do
		if listener.gestureType == gestureType then
			listener.callback(listener.callbackTarget, ...)
		end
	end
end

function TouchHandler:registerTouchArea(posX, posY, sizeX, sizeY, areaOffsetX, areaOffsetY, triggerType, callback, callbackTarget, extraArguments)
	local area = {
		posX = posX,
		posY = posY,
		sizeX = sizeX,
		sizeY = sizeY,
		areaOffsetX = areaOffsetX
	}

	if type(areaOffsetX) == "number" then
		area.areaOffsetX = {
			areaOffsetX / 2,
			areaOffsetX / 2
		}
	end

	area.areaOffsetY = areaOffsetY

	if type(areaOffsetY) == "number" then
		area.areaOffsetY = {
			areaOffsetY / 2,
			areaOffsetY / 2
		}
	end

	area.isPressedSizeGain = 1
	area.isPressedSizeGained = area.isPressedSizeGain - 1
	area.absoluteDimensions = {
		0,
		0,
		0,
		0
	}
	area.absoluteDimensionsPressed = {
		0,
		0,
		0,
		0
	}

	self:updateDimensions(area)

	area.visibility = true
	area.isPressed = false
	area.triggerType = triggerType
	area.callback = callback
	area.callbackTarget = callbackTarget
	area.extraArguments = extraArguments or {}

	table.insert(self.areas, area)

	return area
end

function TouchHandler:registerTouchAreaOverlay(overlay, areaOffsetX, areaOffsetY, triggerType, callback, callbackTarget, extraArguments)
	local area = self:registerTouchArea(overlay.x, overlay.y, overlay.width, overlay.height, areaOffsetX, areaOffsetY, triggerType, callback, callbackTarget, extraArguments)
	area.overlay = overlay

	return area
end

function TouchHandler:removeTouchArea(area)
	table.removeElement(self.areas, area)
end

function TouchHandler:getAreaDimensions(area, pressed)
	if pressed == nil then
		pressed = area.isPressed
	end

	if pressed then
		return unpack(area.absoluteDimensionsPressed)
	end

	return unpack(area.absoluteDimensions)
end

function TouchHandler:removeAllTouchAreas()
	self.areas = {}
end

function TouchHandler:setAreaPosition(area, posX, posY, sizeX, sizeY)
	area.posX = posX
	area.posY = posY
	area.sizeX = sizeX
	area.sizeY = sizeY

	self:updateDimensions(area)
end

function TouchHandler:setAreaPressedSizeGain(area, gain)
	area.isPressedSizeGain = gain
	area.isPressedSizeGained = gain - 1

	self:updateDimensions(area)
end

function TouchHandler:updateDimensions(area)
	local x = area.posX - area.areaOffsetX[1] * area.sizeX
	local y = area.posY - area.areaOffsetY[1] * area.sizeY
	local w = area.sizeX + area.sizeX * area.areaOffsetX[1] + area.sizeX * area.areaOffsetX[2]
	local h = area.sizeY + area.sizeY * area.areaOffsetY[1] + area.sizeY * area.areaOffsetY[2]
	area.absoluteDimensions = {
		x,
		y,
		w,
		h
	}
	local gainPos = math.min(w * area.isPressedSizeGained * 0.5, h * area.isPressedSizeGained * 0.5 * g_screenAspectRatio)
	local gainSize = math.min(w * area.isPressedSizeGain - w, (h * area.isPressedSizeGain - h) * g_screenAspectRatio)
	area.absoluteDimensionsPressed = {
		x - gainPos / g_screenAspectRatio,
		y - gainPos,
		w + gainSize / g_screenAspectRatio,
		h + gainSize
	}
end

function TouchHandler:updateAreaPosition(area)
	if area.overlay ~= nil then
		local overlay = area.overlay

		self:setAreaPosition(area, overlay.x, overlay.y, overlay.width, overlay.height)
	end
end

function TouchHandler:setTouchAreaVisibility(area, visibility)
	area.visibility = visibility
end

function TouchHandler:raiseCallback(area, posX, posY)
	area.callback(area.callbackTarget, posX, posY, area.isCancel, unpack(area.extraArguments))
end

function TouchHandler:update(dt)
	if TouchHandler.DRAW_DEBUG then
		for i, point in pairs(self.debugPoints) do
			point.time = point.time - dt

			if point.time < 0 then
				table.remove(self.debugPoints, i)
			end
		end
	end
end

function TouchHandler:draw()
	if TouchHandler.DRAW_DEBUG then
		if not g_gui:getIsGuiVisible() then
			for i = 1, #self.areas do
				local area = self.areas[i]

				if area.visibility then
					local areaPosX, areaPosY, areaWidth, areaHeight = self:getAreaDimensions(area, false)

					drawOutlineRect(areaPosX, areaPosY, areaWidth, areaHeight, self.debugLineWidth, self.debugLineHeight, 1, 0, 0, 1)

					if area.isPressed then
						areaPosX, areaPosY, areaWidth, areaHeight = self:getAreaDimensions(area, true)

						drawOutlineRect(areaPosX, areaPosY, areaWidth, areaHeight, self.debugLineWidth, self.debugLineHeight, 0, 1, 0, 1)
					end
				end
			end
		end

		for _, point in pairs(self.debugPoints) do
			drawPoint(point.x, point.y, self.debugPointWidth, self.debugPointHeight, 0, 1, 0, 1)
		end
	end
end

function TouchHandler:addDebugPoint(x, y)
	table.insert(self.debugPoints, {
		time = 5000,
		x = x,
		y = y
	})
end
