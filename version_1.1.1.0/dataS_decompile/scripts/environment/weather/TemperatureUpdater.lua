TemperatureUpdater = {}
local TemperatureUpdater_mt = Class(TemperatureUpdater)

function TemperatureUpdater.new(customMt)
	local self = setmetatable({}, customMt or TemperatureUpdater_mt)
	self.dayLength = 1
	self.isDirty = false
	self.currentMin = 15
	self.currentMax = 20
	self.targetMin = 15
	self.targetMax = 20
	self.changeDuration = 3600000

	return self
end

function TemperatureUpdater:delete()
end

function TemperatureUpdater:update(dt)
	if self.isDirty then
		local change = dt / self.changeDuration

		if self.currentMax < self.targetMax then
			self.currentMax = math.min(self.currentMax + change, self.targetMax)
		else
			self.currentMax = math.max(self.currentMax - change, self.targetMax)
		end

		if self.currentMin < self.targetMin then
			self.currentMin = math.min(self.currentMin + change, self.targetMin)
		else
			self.currentMin = math.max(self.currentMin - change, self.targetMin)
		end

		self.isDirty = self.currentMin ~= self.targetMin or self.currentMax ~= self.targetMax
	end
end

function TemperatureUpdater:setDayLength(dayLength)
	self.dayLength = dayLength
end

function TemperatureUpdater:getCurrentValues()
	return self.currentMin, self.currentMax
end

function TemperatureUpdater:setTargetValues(targetMin, targetMax, immediate)
	self.isDirty = not immediate
	self.targetMin = targetMin
	self.targetMax = targetMax

	if immediate then
		self.currentMin = targetMin
		self.currentMax = targetMax
	end
end

function TemperatureUpdater:getTemperatureAtTime(dayTime)
	local normalizedDayTime = dayTime / self.dayLength
	local deltaTemperature = self.currentMax - self.currentMin
	local deltaTemperatureHalf = 0.5 * deltaTemperature
	local x = 2 * math.pi * normalizedDayTime
	local temperature = deltaTemperatureHalf * math.sin(x - 2.5) + self.currentMin + deltaTemperatureHalf

	return temperature
end
