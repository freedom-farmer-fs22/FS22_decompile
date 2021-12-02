AITaskConveyor = {}
local AITaskConveyor_mt = Class(AITaskConveyor, AITask)

function AITaskConveyor.new(isServer, job, customMt)
	local self = AITask.new(isServer, job, customMt or AITaskConveyor_mt)
	self.vehicle = nil

	return self
end

function AITaskConveyor:reset()
	self.vehicle = nil

	AITaskConveyor:superClass().reset(self)
end

function AITaskConveyor:setVehicle(vehicle)
	self.vehicle = vehicle
end

function AITaskConveyor:start()
	if self.isServer then
		self.vehicle:startFieldWorker()
	end

	AITaskConveyor:superClass().start(self)
end

function AITaskConveyor:stop()
	AITaskConveyor:superClass().stop(self)

	if self.isServer then
		self.vehicle:stopFieldWorker()
	end
end
