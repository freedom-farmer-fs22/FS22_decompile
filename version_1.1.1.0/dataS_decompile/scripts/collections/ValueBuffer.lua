ValueBuffer = {}
local ValueBuffer_mt = Class(ValueBuffer)

function ValueBuffer.new(duration, customMt)
	local self = setmetatable({}, customMt or ValueBuffer_mt)
	self.duration = duration
	self.index = 1
	self.values = {}
	self.time = 0

	return self
end

function ValueBuffer:add(value)
	self.values[self.index] = value
	self.index = self.index + 1

	if self.duration < g_time - self.time then
		if self.index < #self.values then
			for i = #self.values, self.index, -1 do
				table.remove(self.values, i)
			end
		end

		self.time = g_time
		self.index = 1
	end
end

function ValueBuffer:get(duration)
	local value = 0

	for _, sValue in pairs(self.values) do
		value = value + sValue
	end

	duration = duration or self.duration

	return value * duration / self.duration
end

function ValueBuffer:getAverage()
	local value = 0

	for _, sValue in pairs(self.values) do
		value = value + sValue
	end

	return value / #self.values
end
