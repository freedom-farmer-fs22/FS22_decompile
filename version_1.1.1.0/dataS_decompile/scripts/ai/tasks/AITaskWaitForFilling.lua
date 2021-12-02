AITaskWaitForFilling = {}
local AITaskWaitForFilling_mt = Class(AITaskWaitForFilling, AITask)

function AITaskWaitForFilling.new(isServer, job, customMt)
	local self = AITask.new(isServer, job, customMt or AITaskWaitForFilling_mt)
	self.fillTypes = {}
	self.vehicle = nil
	self.fillUnitInfo = {}
	self.waitTime = 0
	self.waitDuration = 3000
	self.isFullyLoaded = false

	return self
end

function AITaskWaitForFilling:reset()
	self.vehicle = nil
	self.fillTypes = {}
	self.fillUnitInfo = {}
	self.waitTime = 0
	self.isFullyLoaded = false

	AITaskWaitForFilling:superClass().reset(self)
end

function AITaskWaitForFilling:addAllowedFillType(fillType)
	self.fillTypes[fillType] = true
end

function AITaskWaitForFilling:update(dt)
	if self.isServer then
		if not self.isFullyLoaded then
			local valid = false
			local isFullyLoaded = true

			for _, fillUnitInfo in ipairs(self.fillUnitInfo) do
				local vehicle = fillUnitInfo.vehicle
				local fillUnitIndex = fillUnitInfo.fillUnitIndex
				local fillType = vehicle:getFillUnitFillType(fillUnitIndex)
				local fillLevel = vehicle:getFillUnitFillLevel(fillUnitIndex)
				local freeCapacity = vehicle:getFillUnitFreeCapacity(fillUnitIndex)

				if freeCapacity > 0 then
					isFullyLoaded = false
				end

				if fillLevel > 0 and self.fillTypes[fillType] or fillLevel == 0 then
					valid = true
				end
			end

			if not valid then
				g_currentMission.aiSystem:stopJob(self.job, AIMessageErrorNoValidFillTypeLoaded.new())

				return
			end

			if isFullyLoaded then
				self.isFullyLoaded = true
				self.waitTime = g_time + self.waitDuration
			end
		elseif self.waitTime < g_time then
			self.isFinished = true
		end
	end
end

function AITaskWaitForFilling:start()
	AITaskWaitForFilling:superClass().start(self)

	if self.isServer then
		self.isFullyLoaded = false

		for _, fillUnitInfo in ipairs(self.fillUnitInfo) do
			fillUnitInfo.vehicle:aiPrepareLoading(fillUnitInfo.fillUnitIndex, self)
		end
	end
end

function AITaskWaitForFilling:stop()
	AITaskWaitForFilling:superClass().stop(self)

	if self.isServer then
		for _, fillUnitInfo in ipairs(self.fillUnitInfo) do
			fillUnitInfo.vehicle:aiFinishLoading(fillUnitInfo.fillUnitIndex, self)
		end
	end
end

function AITaskWaitForFilling:setVehicle(vehicle)
	self.vehicle = vehicle
end

function AITaskWaitForFilling:addFillUnits(vehicle, fillUnitIndex)
	table.insert(self.fillUnitInfo, {
		vehicle = vehicle,
		fillUnitIndex = fillUnitIndex
	})
end
