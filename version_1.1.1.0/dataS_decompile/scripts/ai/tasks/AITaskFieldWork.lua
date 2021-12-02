AITaskFieldWork = {}
local AITaskFieldWork_mt = Class(AITaskFieldWork, AITask)

function AITaskFieldWork.new(isServer, job, customMt)
	local self = AITask.new(isServer, job, customMt or AITaskFieldWork_mt)
	self.vehicle = nil

	return self
end

function AITaskFieldWork:reset()
	self.vehicle = nil

	AITaskFieldWork:superClass().reset(self)
end

function AITaskFieldWork:update(dt)
end

function AITaskFieldWork:setVehicle(vehicle)
	self.vehicle = vehicle
end

function AITaskFieldWork:start()
	if self.isServer then
		self.vehicle:startFieldWorker()
	end

	AITaskFieldWork:superClass().start(self)
end

function AITaskFieldWork:stop()
	AITaskFieldWork:superClass().stop(self)

	if self.isServer then
		self.vehicle:stopFieldWorker()
	end
end
