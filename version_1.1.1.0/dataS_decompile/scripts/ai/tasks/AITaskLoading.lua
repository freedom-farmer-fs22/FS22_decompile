AITaskLoading = {
	STATE_DRIVING = 0,
	STATE_LOADING = 1
}
local AITaskLoading_mt = Class(AITaskLoading, AITask)

function AITaskLoading.new(isServer, job, customMt)
	local self = AITask.new(isServer, job, customMt or AITaskLoading_mt)
	self.vehicle = nil
	self.loadTrigger = nil
	self.fillType = nil
	self.loadVehicle = nil
	self.fillUnitIndex = nil
	self.offsetZ = 0
	self.maxSpeed = 5

	return self
end

function AITaskLoading:reset()
	self.vehicle = nil
	self.loadTrigger = nil
	self.loadVehicle = nil
	self.fillType = nil

	AITaskLoading:superClass().reset(self)
end

function AITaskLoading:setVehicle(vehicle)
	self.vehicle = vehicle
end

function AITaskLoading:setLoadTrigger(loadTrigger)
	self.loadTrigger = loadTrigger
end

function AITaskLoading:setFillType(fillType)
	self.fillType = fillType
end

function AITaskLoading:setFillUnit(vehicle, fillUnitIndex, offsetZ)
	self.offsetZ = offsetZ
	self.loadVehicle = vehicle
	self.fillUnitIndex = fillUnitIndex
end

function AITaskLoading:start()
	if self.isServer then
		local x, z, xDir, zDir = self.loadTrigger:getAITargetPositionAndDirection()
		x = x + xDir * -self.offsetZ
		z = z + zDir * -self.offsetZ
		local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

		self.vehicle:setAITarget(self, x, y, z, xDir, 0, zDir, self.maxSpeed, true)

		self.state = AITaskLoading.STATE_DRIVING
	end

	AITaskLoading:superClass().start(self)
end

function AITaskLoading:finishedLoading()
	self.loadVehicle:aiFinishLoading(self.fillUnitIndex, self)

	self.isFinished = true
end

function AITaskLoading:onTargetReached()
	self.vehicle:unsetAITarget()

	self.state = AITaskLoading.STATE_LOADING

	self.loadVehicle:aiPrepareLoading(self.fillUnitIndex, self)
	self.loadVehicle:aiStartLoadingFromTrigger(self.loadTrigger, self.fillUnitIndex, self.fillType, self)
end

function AITaskLoading:onError(errorMessage)
end
