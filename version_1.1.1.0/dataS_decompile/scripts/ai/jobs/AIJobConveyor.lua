AIJobConveyor = {
	START_ERROR_LIMIT_REACHED = 1,
	START_ERROR_VEHICLE_DELETED = 2,
	START_ERROR_NO_PERMISSION = 3,
	START_ERROR_VEHICLE_IN_USE = 4
}
local AIJobConveyor_mt = Class(AIJobConveyor, AIJob)

function AIJobConveyor.new(isServer, customMt)
	local self = AIJob.new(isServer, customMt or AIJobConveyor_mt)
	self.conveyorTask = AITaskConveyor.new(isServer, self)

	self:addTask(self.conveyorTask)

	self.vehicleParameter = AIParameterVehicle.new()

	self:addNamedParameter("vehicle", self.vehicleParameter)

	local vehicleGroup = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleVehicle"))

	vehicleGroup:addParameter(self.vehicleParameter)
	table.insert(self.groupedParameters, vehicleGroup)

	return self
end

function AIJobConveyor:getPricePerMs()
	return 5e-05
end

function AIJobConveyor:start(farmId)
	AIJobConveyor:superClass().start(self, farmId)

	if self.isServer then
		local vehicle = self.vehicleParameter:getVehicle()

		vehicle:aiJobStarted(self, self.helperIndex, farmId)
	end
end

function AIJobConveyor:stop(aiMessage)
	if self.isServer then
		local vehicle = self.vehicleParameter:getVehicle()

		vehicle:aiJobFinished()
	end

	AIJobConveyor:superClass().stop(self, aiMessage)
end

function AIJobConveyor:applyCurrentState(vehicle, mission, farmId, isDirectStart)
	AIJobConveyor:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
	self.vehicleParameter:setVehicle(vehicle)
end

function AIJobConveyor:getIsAvailableForVehicle(vehicle)
	return vehicle.spec_aiConveyorBelt ~= nil and vehicle:getCanStartAIVehicle()
end

function AIJobConveyor:getTitle()
	local vehicle = self.vehicleParameter:getVehicle()

	if vehicle ~= nil then
		return vehicle:getName()
	end

	return ""
end

function AIJobConveyor:setValues()
	self:resetTasks()
	self.conveyorTask:setVehicle(self.vehicleParameter:getVehicle())
end

function AIJobConveyor:validate(farmId)
	self:setParamterValid(true)

	local isValid, errorMessage = self.vehicleParameter:validate(false)

	if not isValid then
		self.vehicleParameter:setIsValid(false)
	end

	return isValid, errorMessage
end

function AIJobConveyor:getIsStartable(connection)
	if g_currentMission.aiSystem:getAILimitedReached() then
		return false, AIJobConveyor.START_ERROR_LIMIT_REACHED
	end

	local vehicle = self.vehicleParameter:getVehicle()

	if vehicle == nil then
		return false, AIJobConveyor.START_ERROR_VEHICLE_DELETED
	end

	if not g_currentMission:getHasPlayerPermission("hireAssistant", connection, vehicle:getOwnerFarmId()) then
		return false, AIJobConveyor.START_ERROR_NO_PERMISSION
	end

	if vehicle:getIsInUse(connection) then
		return false, AIJobConveyor.START_ERROR_VEHICLE_IN_USE
	end

	return true, AIJob.START_SUCCESS
end

function AIJobConveyor.getIsStartErrorText(state)
	if state == AIJobConveyor.START_ERROR_LIMIT_REACHED then
		return g_i18n:getText("ai_startStateLimitReached")
	elseif state == AIJobConveyor.START_ERROR_VEHICLE_DELETED then
		return g_i18n:getText("ai_startStateVehicleDeleted")
	elseif state == AIJobConveyor.START_ERROR_NO_PERMISSION then
		return g_i18n:getText("ai_startStateNoPermission")
	elseif state == AIJobConveyor.START_ERROR_VEHICLE_IN_USE then
		return g_i18n:getText("ai_startStateVehicleInUse")
	end

	return g_i18n:getText("ai_startStateSuccess")
end
