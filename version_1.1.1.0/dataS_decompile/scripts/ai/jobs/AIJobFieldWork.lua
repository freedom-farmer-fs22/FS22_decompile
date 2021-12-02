AIJobFieldWork = {
	START_ERROR_LIMIT_REACHED = 1,
	START_ERROR_VEHICLE_DELETED = 2,
	START_ERROR_NO_PERMISSION = 3,
	START_ERROR_VEHICLE_IN_USE = 4
}
local AIJobFieldWork_mt = Class(AIJobFieldWork, AIJob)

function AIJobFieldWork.new(isServer, customMt)
	local self = AIJob.new(isServer, customMt or AIJobFieldWork_mt)
	self.driveToTask = AITaskDriveTo.new(isServer, self)
	self.fieldWorkTask = AITaskFieldWork.new(isServer, self)

	self:addTask(self.driveToTask)
	self:addTask(self.fieldWorkTask)

	self.isDirectStart = false
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

function AIJobFieldWork:getStartTaskIndex()
	if self.isDirectStart then
		return 2
	end

	local vehicle = self.vehicleParameter:getVehicle()
	local x, _, z = getWorldTranslation(vehicle.rootNode)
	local tx, tz = self.positionAngleParameter:getPosition()
	local targetReached = MathUtil.vector2Length(x - tx, z - tz) < 3

	if targetReached then
		return 2
	end

	return 1
end

function AIJobFieldWork:start(farmId)
	AIJobFieldWork:superClass().start(self, farmId)

	if self.isServer then
		local vehicle = self.vehicleParameter:getVehicle()

		vehicle:createAgent(self.helperIndex)
		vehicle:aiJobStarted(self, self.helperIndex, farmId)
	end
end

function AIJobFieldWork:stop(aiMessage)
	if self.isServer then
		local vehicle = self.vehicleParameter:getVehicle()

		vehicle:deleteAgent()
		vehicle:aiJobFinished()
	end

	AIJobFieldWork:superClass().stop(self, aiMessage)
end

function AIJobFieldWork:applyCurrentState(vehicle, mission, farmId, isDirectStart)
	AIJobFieldWork:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
	self.vehicleParameter:setVehicle(vehicle)

	local x, z, angle, _ = nil

	if vehicle.getLastJob ~= nil then
		local lastJob = vehicle:getLastJob()

		if not isDirectStart and lastJob ~= nil and lastJob:isa(AIJobFieldWork) then
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

function AIJobFieldWork:getIsAvailableForVehicle(vehicle)
	return vehicle.getCanStartFieldWork and vehicle:getCanStartFieldWork()
end

function AIJobFieldWork:getTarget()
	local angle = 0

	if self.driveToTask.dirX ~= nil then
		angle = MathUtil.getYRotationFromDirection(self.driveToTask.dirX, self.driveToTask.dirZ)
	end

	return self.driveToTask.x, self.driveToTask.z, angle
end

function AIJobFieldWork:getTitle()
	local vehicle = self.vehicleParameter:getVehicle()

	if vehicle ~= nil then
		return vehicle:getName()
	end

	return ""
end

function AIJobFieldWork:setValues()
	self:resetTasks()

	local vehicle = self.vehicleParameter:getVehicle()

	self.driveToTask:setVehicle(vehicle)
	self.fieldWorkTask:setVehicle(vehicle)

	local angle = self.positionAngleParameter:getAngle()
	local x, z = self.positionAngleParameter:getPosition()
	local dirX, dirZ = MathUtil.getDirectionFromYRotation(angle)

	self.driveToTask:setTargetDirection(dirX, dirZ)
	self.driveToTask:setTargetPosition(x, z)
end

function AIJobFieldWork:validate(farmId)
	self:setParamterValid(true)

	local isValid, errorMessage = self.vehicleParameter:validate()

	if not isValid then
		self.vehicleParameter:setIsValid(false)
	end

	return isValid, errorMessage
end

function AIJobFieldWork:getDescription()
	local desc = AIJobFieldWork:superClass().getDescription(self)
	local nextTask = self:getTaskByIndex(self.currentTaskIndex)

	if nextTask == self.driveToTask then
		desc = desc .. " - " .. g_i18n:getText("ai_taskDescriptionDriveToField")
	elseif nextTask == self.fieldWorkTask then
		desc = desc .. " - " .. g_i18n:getText("ai_taskDescriptionFieldWork")
	end

	return desc
end

function AIJobFieldWork:getIsStartable(connection)
	if g_currentMission.aiSystem:getAILimitedReached() then
		return false, AIJobFieldWork.START_ERROR_LIMIT_REACHED
	end

	local vehicle = self.vehicleParameter:getVehicle()

	if vehicle == nil then
		return false, AIJobFieldWork.START_ERROR_VEHICLE_DELETED
	end

	if not g_currentMission:getHasPlayerPermission("hireAssistant", connection, vehicle:getOwnerFarmId()) then
		return false, AIJobFieldWork.START_ERROR_NO_PERMISSION
	end

	if vehicle:getIsInUse(connection) then
		return false, AIJobFieldWork.START_ERROR_VEHICLE_IN_USE
	end

	return true, AIJob.START_SUCCESS
end

function AIJobFieldWork.getIsStartErrorText(state)
	if state == AIJobFieldWork.START_ERROR_LIMIT_REACHED then
		return g_i18n:getText("ai_startStateLimitReached")
	elseif state == AIJobFieldWork.START_ERROR_VEHICLE_DELETED then
		return g_i18n:getText("ai_startStateVehicleDeleted")
	elseif state == AIJobFieldWork.START_ERROR_NO_PERMISSION then
		return g_i18n:getText("ai_startStateNoPermission")
	elseif state == AIJobFieldWork.START_ERROR_VEHICLE_IN_USE then
		return g_i18n:getText("ai_startStateVehicleInUse")
	end

	return g_i18n:getText("ai_startStateSuccess")
end
