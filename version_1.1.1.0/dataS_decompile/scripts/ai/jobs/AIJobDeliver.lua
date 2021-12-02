AIJobDeliver = {
	START_ERROR_LIMIT_REACHED = 1,
	START_ERROR_VEHICLE_DELETED = 2,
	START_ERROR_NO_PERMISSION = 3,
	START_ERROR_VEHICLE_IN_USE = 4
}
local AIJobDeliver_mt = Class(AIJobDeliver, AIJob)

function AIJobDeliver.new(isServer, customMt)
	local self = AIJob.new(isServer, customMt or AIJobDeliver_mt)
	self.dischargeNodeInfos = {}
	self.driveToLoadingTask = AITaskDriveTo.new(isServer, self)
	self.waitForFillingTask = AITaskWaitForFilling.new(isServer, self)
	self.driveToUnloadingTask = AITaskDriveTo.new(isServer, self)
	self.dischargeTask = AITaskDischarge.new(isServer, self)

	self:addTask(self.driveToLoadingTask)
	self:addTask(self.waitForFillingTask)
	self:addTask(self.driveToUnloadingTask)
	self:addTask(self.dischargeTask)

	self.vehicleParameter = AIParameterVehicle.new()
	self.unloadingStationParameter = AIParameterUnloadingStation.new()
	self.loopingParameter = AIParameterLooping.new()
	self.positionAngleParameter = AIParameterPositionAngle.new(math.rad(5))

	self:addNamedParameter("vehicle", self.vehicleParameter)
	self:addNamedParameter("unloadingStation", self.unloadingStationParameter)
	self:addNamedParameter("looping", self.loopingParameter)
	self:addNamedParameter("positionAngle", self.positionAngleParameter)

	local vehicleGroup = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleVehicle"))

	vehicleGroup:addParameter(self.vehicleParameter)

	local unloadTargetGroup = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleUnloadingStation"))

	unloadTargetGroup:addParameter(self.unloadingStationParameter)

	local positionGroup = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleLoadingPosition"))

	positionGroup:addParameter(self.positionAngleParameter)

	local loopingGroup = AIParameterGroup.new(g_i18n:getText("ai_parameterGroupTitleLooping"))

	loopingGroup:addParameter(self.loopingParameter)
	table.insert(self.groupedParameters, vehicleGroup)
	table.insert(self.groupedParameters, unloadTargetGroup)
	table.insert(self.groupedParameters, positionGroup)
	table.insert(self.groupedParameters, loopingGroup)

	return self
end

function AIJobDeliver:setValues()
	self:resetTasks()

	local vehicle = self.vehicleParameter:getVehicle()

	if vehicle == nil then
		return
	end

	local unloadingStation = self.unloadingStationParameter:getUnloadingStation()

	if unloadingStation == nil then
		return
	end

	self.driveToUnloadingTask:setVehicle(vehicle)
	self.driveToLoadingTask:setVehicle(vehicle)
	self.dischargeTask:setVehicle(vehicle)
	self.waitForFillingTask:setVehicle(vehicle)

	self.dischargeNodeInfos = {}

	for fillType, _ in pairs(unloadingStation:getAISupportedFillTypes()) do
		self.waitForFillingTask:addAllowedFillType(fillType)
	end

	if vehicle.getAIDischargeNodes ~= nil then
		for _, dischargeNode in ipairs(vehicle:getAIDischargeNodes()) do
			local _, _, z = vehicle:getAIDischargeNodeZAlignedOffset(dischargeNode, vehicle)

			table.insert(self.dischargeNodeInfos, {
				dirty = true,
				vehicle = vehicle,
				dischargeNode = dischargeNode,
				offsetZ = z
			})
		end
	end

	local childVehicles = vehicle:getChildVehicles()

	for _, childVehicle in ipairs(childVehicles) do
		if childVehicle.getAIDischargeNodes ~= nil then
			for _, dischargeNode in ipairs(childVehicle:getAIDischargeNodes()) do
				local _, _, z = childVehicle:getAIDischargeNodeZAlignedOffset(dischargeNode, vehicle)

				table.insert(self.dischargeNodeInfos, {
					dirty = true,
					vehicle = childVehicle,
					dischargeNode = dischargeNode,
					offsetZ = z
				})
			end
		end
	end

	table.sort(self.dischargeNodeInfos, function (a, b)
		return b.offsetZ < a.offsetZ
	end)

	for _, dischargeNodeInfo in ipairs(self.dischargeNodeInfos) do
		self.waitForFillingTask:addFillUnits(dischargeNodeInfo.vehicle, dischargeNodeInfo.dischargeNode.fillUnitIndex)
	end

	local maxOffset = self.dischargeNodeInfos[#self.dischargeNodeInfos].offsetZ

	self.driveToLoadingTask:setTargetOffset(-maxOffset)
	self.driveToUnloadingTask:setTargetOffset(-maxOffset)

	local x, z = self.positionAngleParameter:getPosition()

	if x ~= nil then
		self.driveToLoadingTask:setTargetPosition(x, z)
	end

	local xDir, zDir = self.positionAngleParameter:getDirection()

	if xDir ~= nil then
		self.driveToLoadingTask:setTargetDirection(xDir, zDir)
	end
end

function AIJobDeliver:validate(farmId)
	self:setParamterValid(true)

	local isVehicleValid, vehicleErrorMessage = self.vehicleParameter:validate()

	if isVehicleValid and #self.dischargeNodeInfos == 0 then
		isVehicleValid = false
		vehicleErrorMessage = g_i18n:getText("ai_validationErrorNoAIDischargeNodesFound")
	end

	if not isVehicleValid then
		self.vehicleParameter:setIsValid(false)
	end

	local isUnloadingStationValid, unloadingStationErrorMessage = self.unloadingStationParameter:validate()

	if not isUnloadingStationValid then
		self.unloadingStationParameter:setIsValid(false)
	end

	local isPositionValid, positionErrorMessage = self.positionAngleParameter:validate()

	if not isPositionValid then
		positionErrorMessage = g_i18n:getText("ai_validationErrorNoLoadingPoint")

		self.positionAngleParameter:setIsValid(false)
	end

	local isValid = isVehicleValid and isUnloadingStationValid and isPositionValid
	local errorMessage = vehicleErrorMessage or unloadingStationErrorMessage or positionErrorMessage

	return isValid, errorMessage
end

function AIJobDeliver:applyCurrentState(vehicle, mission, farmId, isDirectStart)
	AIJobDeliver:superClass().applyCurrentState(self, vehicle, mission, farmId, isDirectStart)
	self.vehicleParameter:setVehicle(vehicle)
	self.loopingParameter:setIsLooping(true)

	local x, z, angle, _ = nil

	if vehicle.getLastJob ~= nil then
		local lastJob = vehicle:getLastJob()

		if lastJob ~= nil and lastJob:isa(AIJobDeliver) then
			self.unloadingStationParameter:setUnloadingStation(lastJob.unloadingStationParameter:getUnloadingStation())
			self.loopingParameter:setIsLooping(lastJob.loopingParameter:getIsLooping())

			x, z = lastJob.positionAngleParameter:getPosition()
			angle = lastJob.positionAngleParameter:getAngle()
		end
	end

	if x == nil or z == nil then
		x, _, z = getWorldTranslation(vehicle.rootNode)
	end

	if angle == nil then
		local dirX, _, dirZ = localDirectionToWorld(vehicle.rootNode, 0, 0, 1)
		angle = MathUtil.getYRotationFromDirection(dirX, dirZ)
	end

	self.positionAngleParameter:setPosition(x, z)
	self.positionAngleParameter:setAngle(angle)

	local unloadingStations = {}

	for _, unloadingStation in pairs(g_currentMission.storageSystem:getUnloadingStations()) do
		if g_currentMission.accessHandler:canPlayerAccess(unloadingStation) and unloadingStation:isa(UnloadingStation) then
			local fillTypes = unloadingStation:getAISupportedFillTypes()

			if next(fillTypes) ~= nil then
				table.insert(unloadingStations, unloadingStation)
			end
		end
	end

	self.unloadingStationParameter:setValidUnloadingStations(unloadingStations)
end

function AIJobDeliver:start(farmId)
	AIJobDeliver:superClass().start(self, farmId)

	if self.isServer then
		local vehicle = self.vehicleParameter:getVehicle()

		vehicle:createAgent(self.helperIndex)
		vehicle:aiJobStarted(self, self.helperIndex, farmId)
	end
end

function AIJobDeliver:stop(aiMessage)
	if self.isServer then
		local vehicle = self.vehicleParameter:getVehicle()

		vehicle:deleteAgent()
		vehicle:aiJobFinished()
	end

	AIJobDeliver:superClass().stop(self, aiMessage)

	self.dischargeNodeInfos = {}
end

function AIJobDeliver:startTask(task)
	if task == self.waitForFillingTask then
		for _, dischargeNodeInfo in ipairs(self.dischargeNodeInfos) do
			dischargeNodeInfo.dirty = true
		end
	end

	AIJobDeliver:superClass().startTask(self, task)
end

function AIJobDeliver:getStartTaskIndex()
	local hasOneEmptyFillUnit = false

	for _, dischargeNodeInfo in ipairs(self.dischargeNodeInfos) do
		local vehicle = dischargeNodeInfo.vehicle
		local fillUnitIndex = dischargeNodeInfo.dischargeNode.fillUnitIndex

		if vehicle:getFillUnitFillLevel(fillUnitIndex) == 0 then
			hasOneEmptyFillUnit = true

			break
		end
	end

	local vehicle = self.vehicleParameter:getVehicle()
	local x, _, z = getWorldTranslation(vehicle.rootNode)
	local tx, tz = self.positionAngleParameter:getPosition()
	local targetReached = math.abs(x - tx) < 1 and math.abs(z - tz) < 1

	if targetReached then
		if not hasOneEmptyFillUnit then
			self.waitForFillingTask:skip()
		end

		return self.waitForFillingTask.taskIndex
	end

	if not hasOneEmptyFillUnit then
		self.driveToLoadingTask:skip()
		self.waitForFillingTask:skip()
	end

	return self.driveToLoadingTask.taskIndex
end

function AIJobDeliver:getNextTaskIndex(isSkipTask)
	if self.currentTaskIndex == self.waitForFillingTask.taskIndex or self.currentTaskIndex == self.dischargeTask.taskIndex then
		local lastUnloadTrigger = nil

		if self.currentTaskIndex == self.dischargeTask.taskIndex then
			lastUnloadTrigger = self.dischargeTask.unloadTrigger
		end

		local nextFillType, nextDischargeNodeInfo = nil
		local unloadingStation = self.unloadingStationParameter:getUnloadingStation()

		for _, dischargeNodeInfo in ipairs(self.dischargeNodeInfos) do
			if dischargeNodeInfo.dirty then
				local vehicle = dischargeNodeInfo.vehicle
				local fillUnitIndex = dischargeNodeInfo.dischargeNode.fillUnitIndex

				if vehicle:getFillUnitFillLevel(fillUnitIndex) > 1 then
					local currentFillType = vehicle:getFillUnitFillType(fillUnitIndex)

					if lastUnloadTrigger ~= nil and lastUnloadTrigger:getIsFillTypeSupported(currentFillType) then
						self.dischargeTask:setDischargeNode(vehicle, dischargeNodeInfo.dischargeNode, dischargeNodeInfo.offsetZ)

						dischargeNodeInfo.dirty = false

						return self.currentTaskIndex
					elseif nextFillType == nil then
						local _, _, _, _, trigger = unloadingStation:getAITargetPositionAndDirection(currentFillType)

						if trigger ~= nil then
							nextFillType = currentFillType
							nextDischargeNodeInfo = dischargeNodeInfo
						else
							dischargeNodeInfo.dirty = false
						end
					end
				end
			end
		end

		if nextFillType ~= nil then
			local x, z, dirX, dirZ, trigger = unloadingStation:getAITargetPositionAndDirection(nextFillType)

			self.driveToUnloadingTask:setTargetPosition(x, z)
			self.driveToUnloadingTask:setTargetDirection(dirX, dirZ)
			self.dischargeTask:setUnloadTrigger(trigger)
			self.dischargeTask:setDischargeNode(nextDischargeNodeInfo.vehicle, nextDischargeNodeInfo.dischargeNode, nextDischargeNodeInfo.offsetZ)

			nextDischargeNodeInfo.dirty = false

			return self.driveToUnloadingTask.taskIndex
		end
	end

	local nextTaskIndex = AIJobDeliver:superClass().getNextTaskIndex(self, isSkipTask)

	return nextTaskIndex
end

function AIJobDeliver:canContinueWork()
	local vehicle = self.vehicleParameter:getVehicle()

	if vehicle == nil then
		return false, AIMessageErrorVehicleDeleted.new()
	end

	local unloadingStation = self.unloadingStationParameter:getUnloadingStation()

	if unloadingStation == nil then
		return false, AIMessageErrorUnloadingStationDeleted.new()
	end

	return true, nil
end

function AIJobDeliver:getHasLoadedValidFillType()
	local unloadingStation = self.unloadingStationParameter:getUnloadingStation()

	for _, dischargeNodeInfo in ipairs(self.dischargeNodeInfos) do
		local vehicle = dischargeNodeInfo.vehicle
		local fillUnitIndex = dischargeNodeInfo.dischargeNode.fillUnitIndex

		if vehicle:getFillUnitFillLevel(fillUnitIndex) > 1 then
			local fillType = vehicle:getFillUnitFillType(fillUnitIndex)

			if unloadingStation:getIsFillTypeAISupported(fillType) then
				return true
			end
		end
	end

	return false
end

function AIJobDeliver:getCanSkipTask()
	if self.currentTaskIndex == self.waitForFillingTask.taskIndex and self:getHasLoadedValidFillType() then
		return true
	end

	return false
end

function AIJobDeliver:skipCurrentTask()
	if self.currentTaskIndex == self.waitForFillingTask.taskIndex then
		self.waitForFillingTask:skip()
	end
end

function AIJobDeliver:getIsAvailableForVehicle(vehicle)
	if vehicle.createAgent == nil or vehicle.setAITarget == nil or not vehicle:getCanStartAIVehicle() then
		return false
	end

	if vehicle.getAIDischargeNodes ~= nil then
		local nodes = vehicle:getAIDischargeNodes()

		if next(nodes) ~= nil then
			return true
		end
	end

	local vehicles = vehicle:getChildVehicles()

	for _, childVehicle in ipairs(vehicles) do
		if childVehicle.getAIDischargeNodes ~= nil then
			local nodes = childVehicle:getAIDischargeNodes()

			if next(nodes) ~= nil then
				return true
			end
		end
	end
end

function AIJobDeliver:getTitle()
	local vehicle = self.vehicleParameter:getVehicle()

	if vehicle ~= nil then
		return vehicle:getName()
	end

	return ""
end

function AIJobDeliver:getIsLooping()
	return self.loopingParameter:getIsLooping()
end

function AIJobDeliver:getIsStartable(connection)
	if g_currentMission.aiSystem:getAILimitedReached() then
		return false, AIJobDeliver.START_ERROR_LIMIT_REACHED
	end

	local vehicle = self.vehicleParameter:getVehicle()

	if vehicle == nil then
		return false, AIJobDeliver.START_ERROR_VEHICLE_DELETED
	end

	if not g_currentMission:getHasPlayerPermission("hireAssistant", connection, vehicle:getOwnerFarmId()) then
		return false, AIJobDeliver.START_ERROR_NO_PERMISSION
	end

	if vehicle:getIsInUse(connection) then
		return false, AIJobDeliver.START_ERROR_VEHICLE_IN_USE
	end

	return true, AIJob.START_SUCCESS
end

function AIJobDeliver:getDescription()
	local desc = AIJobLoadAndDeliver:superClass().getDescription(self)
	local nextTask = self:getTaskByIndex(self.currentTaskIndex)

	if nextTask == self.driveToLoadingTask then
		desc = desc .. " - " .. g_i18n:getText("ai_taskDescriptionDriveToLoadingStation")
	elseif nextTask == self.waitForFillingTask then
		desc = desc .. " - " .. g_i18n:getText("ai_taskDescriptionWaitForFilling")
	elseif nextTask == self.driveToUnloadingTask then
		desc = desc .. " - " .. g_i18n:getText("ai_taskDescriptionDriveToUnloadingStation")
	elseif nextTask == self.dischargeTask then
		desc = desc .. " - " .. g_i18n:getText("ai_taskDescriptionUnloading")
	end

	return desc
end

function AIJobDeliver.getIsStartErrorText(state)
	if state == AIJobDeliver.START_ERROR_LIMIT_REACHED then
		return g_i18n:getText("ai_startStateLimitReached")
	elseif state == AIJobDeliver.START_ERROR_VEHICLE_DELETED then
		return g_i18n:getText("ai_startStateVehicleDeleted")
	elseif state == AIJobDeliver.START_ERROR_NO_PERMISSION then
		return g_i18n:getText("ai_startStateNoPermission")
	elseif state == AIJobDeliver.START_ERROR_VEHICLE_IN_USE then
		return g_i18n:getText("ai_startStateVehicleInUse")
	end

	return g_i18n:getText("ai_startStateSuccess")
end
