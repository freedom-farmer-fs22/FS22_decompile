AIJobGoTo = {
	START_ERROR_LIMIT_REACHED = 1,
	START_ERROR_VEHICLE_DELETED = 2,
	START_ERROR_NO_PERMISSION = 3,
	START_ERROR_VEHICLE_IN_USE = 4
}
local AIJobGoTo_mt = Class(AIJobGoTo, AIJob)

function AIJobGoTo.new(isServer, customMt)
	local self = AIJob.new(isServer, customMt or AIJobGoTo_mt)
	self.driveToTask = AITaskDriveTo.new(isServer, self)

	self:addTask(self.driveToTask)

	self.vehicleParameter = AIParameterVehicle.new()
	self.positionAngleParameter = AIParameterPositionAngle.new(math.rad(0))

	self:addNamedParameter("vehicle", self.vehicleParameter)
	self:addNamedParameter("positionAngle", self.positionAngleParameter)

	local vehicleGroup = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleVehicle"))

	vehicleGroup:addParameter(self.vehicleParameter)

	local positionGroup = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitlePosition"))

	positionGroup:addParameter(self.positionAngleParameter)
	table.insert(self.groupedParameters, vehicleGroup)
	table.insert(self.groupedParameters, positionGroup)

	return self
end

function AIJobGoTo:start(farmId)
	AIJobGoTo:superClass().start(self, farmId)

	local vehicle = self.vehicleParameter:getVehicle()

	if vehicle ~= nil then
		if self.isServer then
			vehicle:createAgent(self.helperIndex)
		end

		vehicle:aiJobStarted(self, self.helperIndex, farmId)
	end
end

function AIJobGoTo:stop(aiMessage)
	local vehicle = self.vehicleParameter:getVehicle()

	if vehicle ~= nil then
		if self.isServer then
			vehicle:deleteAgent()
		end

		vehicle:aiJobFinished()
	end

	AIJobGoTo:superClass().stop(self, aiMessage)
end

function AIJobGoTo:getTarget()
	local angle = nil

	if self.driveToTask.dirX ~= nil then
		angle = MathUtil.getYRotationFromDirection(self.driveToTask.dirX, self.driveToTask.dirZ)
	end

	return self.driveToTask.x, self.driveToTask.z, angle
end

function AIJobGoTo:getIsAvailableForVehicle(vehicle)
	if vehicle.createAgent == nil or vehicle.setAITarget == nil or not vehicle:getCanStartAIVehicle() then
		return false
	end

	return true
end

function AIJobGoTo:getTitle()
	local vehicle = self.vehicleParameter:getVehicle()

	if vehicle ~= nil then
		return vehicle:getName()
	end

	return ""
end

function AIJobGoTo:applyCurrentState(vehicle, mission, farmId, isDirectStart)
	AIJobGoTo:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
	self.vehicleParameter:setVehicle(vehicle)

	local x, z, angle, _ = nil

	if vehicle.getLastJob ~= nil then
		local lastJob = vehicle:getLastJob()

		if not isDirectStart and lastJob ~= nil and lastJob:isa(AIJobGoTo) then
			x, z = lastJob.positionAngleParameter:getPosition()
			angle = lastJob.positionAngleParameter:getAngle()
		end
	end

	local snappingAngle = vehicle:getDirectionSnapAngle()
	local terrainAngle = math.pi / math.max(g_currentMission.fieldGroundSystem:getGroundAngleMaxValue() + 1, 4)
	snappingAngle = math.max(snappingAngle, terrainAngle)

	self.positionAngleParameter:setSnappingAngle(snappingAngle)

	if x == nil or z == nil then
		x, _, z = getWorldTranslation(vehicle.rootNode)
	end

	if angle == nil then
		local dirX, _, dirZ = localDirectionToWorld(vehicle.rootNode, 0, 0, 1)
		angle = MathUtil.getYRotationFromDirection(dirX, dirZ)
	end

	self.positionAngleParameter:setPosition(x, z)
	self.positionAngleParameter:setAngle(angle)
end

function AIJobGoTo:setValues()
	self:resetTasks()
	self.driveToTask:setVehicle(self.vehicleParameter:getVehicle())

	local angle = self.positionAngleParameter:getAngle()
	local x, z = self.positionAngleParameter:getPosition()
	local dirX, dirZ = MathUtil.getDirectionFromYRotation(angle)

	self.driveToTask:setTargetDirection(dirX, dirZ)
	self.driveToTask:setTargetPosition(x, z)
end

function AIJobGoTo:validate(farmId)
	self:setParamterValid(true)

	local isValid, errorMessage = self.vehicleParameter:validate()

	if not isValid then
		self.vehicleParameter:setIsValid(false)
	end

	return isValid, errorMessage
end

function AIJobGoTo:getDescription()
	local desc = AIJobGoTo:superClass().getDescription(self)
	local nextTask = self:getTaskByIndex(self.currentTaskIndex)

	if nextTask == self.driveToTask then
		desc = desc .. " - " .. g_i18n:getText("ai_taskDescriptionDriveToTarget")
	end

	return desc
end

function AIJobGoTo:getIsStartable(connection)
	if g_currentMission.aiSystem:getAILimitedReached() then
		return false, AIJobGoTo.START_ERROR_LIMIT_REACHED
	end

	local vehicle = self.vehicleParameter:getVehicle()

	if vehicle == nil then
		return false, AIJobGoTo.START_ERROR_VEHICLE_DELETED
	end

	if not g_currentMission:getHasPlayerPermission("hireAssistant", connection, vehicle:getOwnerFarmId()) then
		return false, AIJobGoTo.START_ERROR_NO_PERMISSION
	end

	if vehicle:getIsInUse(connection) then
		return false, AIJobGoTo.START_ERROR_VEHICLE_IN_USE
	end

	return true, AIJob.START_SUCCESS
end

function AIJobGoTo.getIsStartErrorText(state)
	if state == AIJobGoTo.START_ERROR_LIMIT_REACHED then
		return g_i18n:getText("ai_startStateLimitReached")
	elseif state == AIJobGoTo.START_ERROR_VEHICLE_DELETED then
		return g_i18n:getText("ai_startStateVehicleDeleted")
	elseif state == AIJobGoTo.START_ERROR_NO_PERMISSION then
		return g_i18n:getText("ai_startStateNoPermission")
	elseif state == AIJobGoTo.START_ERROR_VEHICLE_IN_USE then
		return g_i18n:getText("ai_startStateVehicleInUse")
	end

	return g_i18n:getText("ai_startStateSuccess")
end
