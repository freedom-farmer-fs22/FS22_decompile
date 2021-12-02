AITaskDischarge = {
	STATE_DRIVING = 0,
	STATE_DISCHARGE = 1
}
local AITaskDischarge_mt = Class(AITaskDischarge, AITask)

function AITaskDischarge.new(isServer, job, customMt)
	local self = AITask.new(isServer, job, customMt or AITaskDischarge_mt)
	self.vehicle = nil
	self.unloadTrigger = nil
	self.dischargeVehicle = nil
	self.dischargeNode = nil
	self.offsetZ = 0
	self.maxSpeed = 5
	self.state = AITaskDischarge.STATE_DRIVING

	return self
end

function AITaskDischarge:reset()
	self.vehicle = nil
	self.unloadTrigger = nil
	self.dischargeVehicle = nil
	self.dischargeNode = nil
	self.offsetZ = 0
	self.state = AITaskDischarge.STATE_DRIVING

	AITaskDischarge:superClass().reset(self)
end

function AITaskDischarge:setVehicle(vehicle)
	self.vehicle = vehicle
end

function AITaskDischarge:setUnloadTrigger(unloadTrigger)
	self.unloadTrigger = unloadTrigger
end

function AITaskDischarge:setDischargeNode(vehicle, dischargeNode, offsetZ)
	if vehicle ~= nil then
		self.offsetZ = offsetZ

		vehicle:setCurrentDischargeNodeIndex(dischargeNode.index)
	end

	self.dischargeNode = dischargeNode
	self.dischargeVehicle = vehicle
end

function AITaskDischarge:start()
	if self.isServer then
		local x, z, xDir, zDir = self.unloadTrigger:getAITargetPositionAndDirection()
		x = x + xDir * -self.offsetZ
		z = z + zDir * -self.offsetZ
		local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

		self.vehicle:setAITarget(self, x, y, z, xDir, 0, zDir, self.maxSpeed, true)

		self.state = AITaskDischarge.STATE_DRIVING
	end

	AITaskDischarge:superClass().start(self)
end

function AITaskDischarge:stop()
	AITaskDischarge:superClass().stop(self)
end

function AITaskDischarge:onTargetReached()
	self.vehicle:unsetAITarget()

	if self.dischargeVehicle:getAICanStartDischarge(self.dischargeNode) then
		self.state = AITaskDischarge.STATE_DISCHARGE

		self.dischargeVehicle:startAIDischarge(self.dischargeNode, self)
	else
		g_currentMission.aiSystem:stopJob(self.job, AIMessageErrorUnloadingStationFull.new())
	end
end

function AITaskDischarge:onError(errorMessage)
end

function AITaskDischarge:finishedDischarge()
	self.isFinished = true
end
