AITaskDriveTo = {
	STATE_PREPARE_DRIVING = 1,
	STATE_DRIVE_TO_OFFSET_POS = 2,
	STATE_DRIVE_TO_FINAL_POS = 3,
	PREPARE_TIMEOUT = 2000
}
local AITaskDriveTo_mt = Class(AITaskDriveTo, AITask)

function AITaskDriveTo.new(isServer, job, customMt)
	local self = AITask.new(isServer, job, customMt or AITaskDriveTo_mt)
	self.x = nil
	self.z = nil
	self.dirX = nil
	self.dirZ = nil
	self.vehicle = nil
	self.state = AITaskDriveTo.STATE_DRIVE_TO_OFFSET_POS
	self.maxSpeed = 5
	self.offset = 0
	self.prepareTimeout = 0

	return self
end

function AITaskDriveTo:reset()
	self.vehicle = nil
	self.z = nil
	self.x = nil
	self.dirZ = nil
	self.dirX = nil
	self.state = AITaskDriveTo.STATE_DRIVE_TO_OFFSET_POS
	self.maxSpeed = 5
	self.offset = 0

	AITaskDriveTo:superClass().reset(self)
end

function AITaskDriveTo:setVehicle(vehicle)
	self.vehicle = vehicle
end

function AITaskDriveTo:setTargetOffset(offset)
	self.offset = offset
end

function AITaskDriveTo:setTargetPosition(x, z)
	self.x = x
	self.z = z

	if self.isActive then
		-- Nothing
	end
end

function AITaskDriveTo:setTargetDirection(dirX, dirZ)
	self.dirX = dirX
	self.dirZ = dirZ

	if self.isActive then
		-- Nothing
	end
end

function AITaskDriveTo:update(dt)
	if self.isServer and self.state == AITaskDriveTo.STATE_PREPARE_DRIVING then
		local isReadyToDrive, blockingVehicle = self.vehicle:getIsAIReadyToDrive()

		if isReadyToDrive then
			self:startDriving()
		elseif not self.vehicle:getIsAIPreparingToDrive() then
			self.prepareTimeout = self.prepareTimeout + dt

			if AITaskDriveTo.PREPARE_TIMEOUT < self.prepareTimeout then
				self.vehicle:stopCurrentAIJob(AIMessageErrorCouldNotPrepare.new(blockingVehicle or self.vehicle))
			end
		end
	end
end

function AITaskDriveTo:start()
	if self.isServer then
		self.state = AITaskDriveTo.STATE_PREPARE_DRIVING

		self.vehicle:prepareForAIDriving()

		self.isActive = true
	end

	AITaskDriveTo:superClass().start(self)
end

function AITaskDriveTo:stop()
	AITaskDriveTo:superClass().stop(self)

	if self.isServer then
		self.vehicle:unsetAITarget()

		self.isActive = false
	end
end

function AITaskDriveTo:startDriving()
	local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, self.x, 0, self.z)
	local dirY = 0
	self.state = AITaskDriveTo.STATE_DRIVE_TO_FINAL_POS
	local x = self.x
	local z = self.z

	if self.offset ~= 0 then
		self.state = AITaskDriveTo.STATE_DRIVE_TO_OFFSET_POS
		x = self.x + self.dirX * -self.offset
		z = self.z + self.dirZ * -self.offset
	end

	self.vehicle:setAITarget(self, x, y, z, self.dirX, dirY, self.dirZ)
end

function AITaskDriveTo:onTargetReached()
	if self.state == AITaskDriveTo.STATE_DRIVE_TO_OFFSET_POS then
		local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, self.x, 0, self.z)

		self.vehicle:setAITarget(self, self.x, y, self.z, self.dirX, 0, self.dirZ, self.maxSpeed, true)

		self.state = AITaskDriveTo.STATE_DRIVE_TO_FINAL_POS
	else
		self.isFinished = true
	end
end

function AITaskDriveTo:onError(errorMessage)
end
