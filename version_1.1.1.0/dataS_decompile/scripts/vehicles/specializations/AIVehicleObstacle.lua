AIVehicleObstacle = {
	prerequisitesPresent = function (specializations)
		return true
	end
}

function AIVehicleObstacle.registerFunctions(vehicleType)
	SpecializationUtil.registerFunction(vehicleType, "createAIVehicleObstacle", AIVehicleObstacle.createAIVehicleObstacle)
	SpecializationUtil.registerFunction(vehicleType, "removeAIVehicleObstacle", AIVehicleObstacle.removeAIVehicleObstacle)
	SpecializationUtil.registerFunction(vehicleType, "updateAIVehicleObstacleState", AIVehicleObstacle.updateAIVehicleObstacleState)
	SpecializationUtil.registerFunction(vehicleType, "getCanHaveAIVehicleObstacle", AIVehicleObstacle.getCanHaveAIVehicleObstacle)
	SpecializationUtil.registerFunction(vehicleType, "getNeedAIVehicleObstacle", AIVehicleObstacle.getNeedAIVehicleObstacle)
	SpecializationUtil.registerFunction(vehicleType, "getAIVehicleObstacleMaxBrakeAcceleration", AIVehicleObstacle.getAIVehicleObstacleMaxBrakeAcceleration)
	SpecializationUtil.registerFunction(vehicleType, "setAIVehicleObstacleStateDirty", AIVehicleObstacle.setAIVehicleObstacleStateDirty)
	SpecializationUtil.registerFunction(vehicleType, "getAIVehicleObstacleIsPassable", AIVehicleObstacle.getAIVehicleObstacleIsPassable)
end

function AIVehicleObstacle.registerOverwrittenFunctions(vehicleType)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "addToPhysics", AIVehicleObstacle.addToPhysics)
	SpecializationUtil.registerOverwrittenFunction(vehicleType, "removeFromPhysics", AIVehicleObstacle.removeFromPhysics)
end

function AIVehicleObstacle.registerEventListeners(vehicleType)
	SpecializationUtil.registerEventListener(vehicleType, "onLoad", AIVehicleObstacle)
	SpecializationUtil.registerEventListener(vehicleType, "onDelete", AIVehicleObstacle)
	SpecializationUtil.registerEventListener(vehicleType, "onUpdate", AIVehicleObstacle)
	SpecializationUtil.registerEventListener(vehicleType, "onEnterVehicle", AIVehicleObstacle)
	SpecializationUtil.registerEventListener(vehicleType, "onLeaveVehicle", AIVehicleObstacle)
end

function AIVehicleObstacle:onLoad(savegame)
	local spec = self.spec_aiVehicleObstacle
	spec.needsUpdate = false
end

function AIVehicleObstacle:onDelete()
	self:removeAIVehicleObstacle()
end

function AIVehicleObstacle:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	local spec = self.spec_aiVehicleObstacle

	if self.isServer and spec.needsUpdate then
		self:updateAIVehicleObstacleState()

		spec.needsUpdate = false
	end
end

function AIVehicleObstacle:createAIVehicleObstacle()
	if self.isAddedToPhysics then
		local maxBrakeAcceleration = self:getAIVehicleObstacleMaxBrakeAcceleration()

		for _, component in ipairs(self.components) do
			if component.obstacleId == nil then
				g_currentMission.aiSystem:addObstacle(component.node, 0, 0, 0, 0, 0, 0, maxBrakeAcceleration)

				component.obstacleId = component.node
			end

			g_currentMission.aiSystem:setObstacleIsPassable(component.node, self:getAIVehicleObstacleIsPassable())
		end
	end
end

function AIVehicleObstacle:removeAIVehicleObstacle()
	for _, component in ipairs(self.components) do
		if component.obstacleId ~= nil then
			g_currentMission.aiSystem:removeObstacle(component.node)

			component.obstacleId = nil
		end
	end
end

function AIVehicleObstacle:updateAIVehicleObstacleState()
	if self.isServer then
		if self:getCanHaveAIVehicleObstacle() then
			if self:getNeedAIVehicleObstacle() then
				self:createAIVehicleObstacle()
			end
		else
			self:removeAIVehicleObstacle()
		end
	end
end

function AIVehicleObstacle:setAIVehicleObstacleStateDirty()
	self.spec_aiVehicleObstacle.needsUpdate = true

	self:raiseActive()
end

function AIVehicleObstacle:getCanHaveAIVehicleObstacle()
	if not self.isAddedToPhysics then
		return false
	end

	if self.propertyState == Vehicle.PROPERTY_STATE_SHOP_CONFIG then
		return false
	end

	if self.rootVehicle ~= self and self.rootVehicle.getCanHaveAIVehicleObstacle ~= nil and not self.rootVehicle:getCanHaveAIVehicleObstacle() then
		return false
	end

	return true
end

function AIVehicleObstacle:getNeedAIVehicleObstacle()
	return true
end

function AIVehicleObstacle:getAIVehicleObstacleIsPassable()
	return self.getIsControlled == nil or not self:getIsControlled()
end

function AIVehicleObstacle:getAIVehicleObstacleMaxBrakeAcceleration()
	return 5
end

function AIVehicleObstacle:onEnterVehicle(isControlling)
	self:setAIVehicleObstacleStateDirty()
end

function AIVehicleObstacle:onLeaveVehicle()
	self:setAIVehicleObstacleStateDirty()
end

function AIVehicleObstacle:addToPhysics(superFunc)
	if not superFunc(self) then
		return false
	end

	self:setAIVehicleObstacleStateDirty()

	return true
end

function AIVehicleObstacle:removeFromPhysics(superFunc)
	if not superFunc(self) then
		return false
	end

	self:setAIVehicleObstacleStateDirty()

	return true
end
