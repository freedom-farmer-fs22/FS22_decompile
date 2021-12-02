VehicleActionControllerAction = {}
local VehicleActionControllerAction_mt = Class(VehicleActionControllerAction)

function VehicleActionControllerAction.new(parent, name, inputAction, priority, customMt)
	if customMt == nil then
		customMt = VehicleActionControllerAction_mt
	end

	local self = setmetatable({}, customMt)
	self.parent = parent
	self.name = name
	self.inputAction = inputAction
	self.priority = priority
	self.lastDirection = -1
	self.lastValidDirection = 0
	self.isSaved = false
	self.resetOnDeactivation = true
	self.identifier = ""
	self.aiEventListener = {}

	return self
end

function VehicleActionControllerAction:remove()
	self.parent:removeAction(self)
end

function VehicleActionControllerAction:updateParent(parent)
	if parent ~= self.parent then
		self.parent:removeAction(self)
		parent:addAction(self)
	end

	self.parent = parent
end

function VehicleActionControllerAction:setCallback(callbackTarget, inputCallback, inputCallbackRev)
	self.callbackTarget = callbackTarget
	self.inputCallback = inputCallback
	self.inputCallbackRev = inputCallbackRev
	self.identifier = callbackTarget.configFileName or ""
end

function VehicleActionControllerAction:setFinishedFunctions(finishedFunctionTarget, finishedFunc, finishedResult, finishedResultRev, finishedFuncRev)
	self.finishedFunctionTarget = finishedFunctionTarget
	self.finishedFunc = finishedFunc
	self.finishedFuncRev = finishedFuncRev
	self.finishedResult = finishedResult
	self.finishedResultRev = finishedResultRev
end

function VehicleActionControllerAction:setDeactivateFunction(deactivateFunctionTarget, deactivateFunc, inverseDeactivateFunc)
	self.deactivateFunctionTarget = deactivateFunctionTarget
	self.deactivateFunc = deactivateFunc
	self.inverseDeactivateFunc = Utils.getNoNil(inverseDeactivateFunc, false)
end

function VehicleActionControllerAction:setResetOnDeactivation(resetOnDeactivation)
	self.resetOnDeactivation = resetOnDeactivation
end

function VehicleActionControllerAction:setIsSaved(isSaved)
	self.isSaved = isSaved
end

function VehicleActionControllerAction:getIsSaved()
	return self.isSaved
end

function VehicleActionControllerAction:getLastDirection()
	return self.lastDirection
end

function VehicleActionControllerAction:getDoResetOnDeactivation()
	return self.resetOnDeactivation
end

function VehicleActionControllerAction:addAIEventListener(sourceVehicle, eventName, direction, forceUntilFinished)
	self.sourceVehicle = sourceVehicle
	local listener = {
		eventName = eventName,
		direction = direction,
		forceUntilFinished = forceUntilFinished
	}

	table.insert(self.aiEventListener, listener)
end

function VehicleActionControllerAction:registerActionEvents(target, vehicle, actionEvents, isActiveForInput, isActiveForInputIgnoreSelection)
end

function VehicleActionControllerAction:actionEvent(actionName, inputValue, actionIndex, isAnalog)
	self:doAction()
end

function VehicleActionControllerAction:doAction(direction)
	if direction == nil then
		direction = -self.lastDirection
	end

	self.lastDirection = direction
	local success = self.inputCallback(self.callbackTarget, direction)

	if success then
		self.lastValidDirection = self.lastDirection
	end

	return success
end

function VehicleActionControllerAction:getIsFinished(direction)
	if self.finishedFunc ~= nil then
		if direction > 0 then
			return self.finishedFunc(self.finishedFunctionTarget) == self.finishedResult
		else
			return self.finishedFunc(self.finishedFunctionTarget) == self.finishedResultRev
		end
	end

	return true
end

function VehicleActionControllerAction:getSourceVehicle()
	return self.sourceVehicle
end

function VehicleActionControllerAction:onAIEvent(eventName)
	for _, listener in ipairs(self.aiEventListener) do
		if listener.eventName == eventName then
			if not self:doAction(listener.direction) and listener.forceUntilFinished then
				self.forceDirectionUntilFinished = listener.direction
			else
				if self.forceDirectionUntilFinished ~= nil and listener.direction ~= self.forceDirectionUntilFinished then
					self.forceDirectionUntilFinished = nil
				end

				self.parent:stopActionSequence()
			end
		end
	end
end

function VehicleActionControllerAction:update(dt)
	if self.deactivateFunc ~= nil and self.lastDirection == 1 and self.deactivateFunc(self.deactivateFunctionTarget) == not self.inverseDeactivateFunc and self.parent.currentSequenceIndex == nil and self.forceDirectionUntilFinished == nil then
		self.parent:startActionSequence()
	end
end

function VehicleActionControllerAction:updateForAI(dt)
	if self.forceDirectionUntilFinished ~= nil and self:doAction(self.forceDirectionUntilFinished) then
		self.forceDirectionUntilFinished = nil

		self.parent:stopActionSequence()
	end
end

function VehicleActionControllerAction:getDebugText()
	local finishedResult = self.finishedFunc(self.finishedFunctionTarget)

	if type(finishedResult) == "number" then
		finishedResult = string.format("%.1f", finishedResult)
	end

	return string.format("Prio '%d' - Vehicle '%s' - Action '%s' (%s/%s)", self.priority, Utils.getFilenameInfo((self.callbackTarget or {}).configFileName or "Unknown Vehicle", true), self.name, finishedResult, self.lastDirection == 1 and self.finishedResult or self.finishedResultRev)
end
