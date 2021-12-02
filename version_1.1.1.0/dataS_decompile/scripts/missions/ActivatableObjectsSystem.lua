ActivatableObjectsSystem = {}
local ActivatableObjectsSystem_mt = Class(ActivatableObjectsSystem)

function ActivatableObjectsSystem.new(mission, customMt)
	local self = setmetatable({}, customMt or ActivatableObjectsSystem_mt)
	self.mission = mission
	self.objects = {}
	self.currentActivatableObject = nil
	self.inputContext = nil
	self.actionEventId = nil

	return self
end

function ActivatableObjectsSystem:activate(context)
	self.inputContext = context
	self.isActive = true

	self:updateObjects()
end

function ActivatableObjectsSystem:deactivate(context)
	self:removeInput(context)

	if self.currentActivatableObject ~= nil and self.currentActivatableObject.deactivate ~= nil then
		self.currentActivatableObject:deactivate()
	end

	self.currentActivatableObject = nil
	self.isActive = false
end

function ActivatableObjectsSystem:setPosition(x, y, z)
	self.posZ = z
	self.posY = y
	self.posX = x
end

function ActivatableObjectsSystem:update(dt)
	if self.isActive then
		self:updateObjects()
	end
end

function ActivatableObjectsSystem:updateObjects()
	local nearestObject = nil
	local nearestDistance = math.huge

	for _, object in pairs(self.objects) do
		if object.getIsActivatable == nil or object:getIsActivatable() then
			local distance = math.huge

			if object.getDistance ~= nil and self.posX ~= nil then
				distance = object:getDistance(self.posX, self.posY, self.posZ)
			end

			if nearestObject == nil or distance < nearestDistance then
				nearestObject = object
				nearestDistance = distance
			end
		end
	end

	if nearestObject ~= self.currentActivatableObject then
		self:removeInput(self.inputContext)

		if self.currentActivatableObject ~= nil and self.currentActivatableObject.deactivate ~= nil then
			self.currentActivatableObject:deactivate()
		end

		self.currentActivatableObject = nearestObject

		if nearestObject ~= nil then
			if nearestObject.activate ~= nil then
				nearestObject:activate()
			end

			self:registerInput(self.inputContext)
		end
	end

	if nearestObject ~= nil and self.actionEventId ~= nil then
		g_inputBinding:setActionEventText(self.actionEventId, nearestObject.activateText)
	end
end

function ActivatableObjectsSystem:removeInput(inputContext)
	if inputContext ~= nil then
		g_inputBinding:beginActionEventsModification(inputContext)
	end

	if self.currentActivatableObject ~= nil and self.currentActivatableObject.removeCustomInput ~= nil then
		self.currentActivatableObject:removeCustomInput()
	end

	if self.actionEventId ~= nil then
		g_inputBinding:removeActionEvent(self.actionEventId)

		self.actionEventId = nil
	end

	if inputContext ~= nil then
		g_inputBinding:endActionEventsModification()
	end
end

function ActivatableObjectsSystem:registerInput(inputContext)
	local currentObject = self.currentActivatableObject

	if currentObject ~= nil then
		if inputContext ~= nil then
			g_inputBinding:beginActionEventsModification(inputContext)
		end

		if currentObject.registerCustomInput ~= nil then
			currentObject:registerCustomInput(inputContext)
		else
			local _, actionEventId = g_inputBinding:registerActionEvent(InputAction.ACTIVATE_OBJECT, self, self.onActivateObjectInput, false, true, false, true)

			g_inputBinding:setActionEventText(actionEventId, currentObject.activateText)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_HIGH)
			g_inputBinding:setActionEventTextVisibility(actionEventId, true)

			self.actionEventId = actionEventId
		end

		if inputContext ~= nil then
			g_inputBinding:endActionEventsModification()
		end
	end
end

function ActivatableObjectsSystem:getActivatable()
	return self.currentActivatableObject
end

function ActivatableObjectsSystem:addActivatable(object)
	if object.activateText == nil then
		Logging.error("Given activatable object has no activateText")
		printCallstack()

		return
	end

	if self.objects[object] == nil then
		self.objects[object] = object
	end
end

function ActivatableObjectsSystem:removeActivatable(object)
	if object == nil then
		return
	end

	self.objects[object] = nil

	if object == self.currentActivatableObject then
		if object.deactivate ~= nil then
			object:deactivate()
		end

		self:removeInput(self.inputContext)

		self.currentActivatableObject = nil
	end
end

function ActivatableObjectsSystem:onActivateObjectInput(actionName, inputValue, callbackState, isAnalog)
	if self.currentActivatableObject ~= nil then
		self.currentActivatableObject:run()
	end
end
