ValueDelay = {}
local ValueDelay_mt = Class(ValueDelay)

function ValueDelay.new(duration, direction, customMt)
	local self = {}

	setmetatable(self, customMt or ValueDelay_mt)

	self.duration = duration
	self.direction = direction
	self.values = {}

	for _ = 1, math.floor(duration / 16.666666666666668) + 1 do
		table.insert(self.values, {
			value = 0,
			time = -1
		})
	end

	self.insertIndex = 0
	self.maxFrames = #self.values
	self.isReseted = true

	return self
end

function ValueDelay:add(value, dt)
	self.isReseted = false

	if self.maxFrames == 0 then
		return value
	end

	self.insertIndex = self.insertIndex + 1

	if self.maxFrames < self.insertIndex then
		self.insertIndex = 1
	end

	local valueData = self.values[self.insertIndex]
	valueData.value = value
	valueData.time = g_time
	local minTime = math.huge
	local minSlot = 0
	local minValue = 0
	local slotValid = false

	for i = 1, self.maxFrames - 1 do
		local readIndex = self.insertIndex - i

		if readIndex <= 0 then
			readIndex = readIndex + self.maxFrames
		end

		local slotTime = self.values[readIndex].time

		if slotTime ~= -1 then
			local difference = self.duration - (valueData.time - slotTime)

			if minTime > difference and difference > 0 then
				minTime = difference
				minSlot = readIndex
				minValue = self.values[readIndex].value
			elseif difference < 0 then
				slotValid = true

				break
			end
		else
			break
		end

		if i == self.maxFrames - 1 then
			slotValid = true
		end
	end

	local returnValue = 0

	if minSlot ~= 0 and slotValid then
		returnValue = minValue
	end

	if self.direction ~= nil then
		if self.direction == -1 then
			if returnValue < value then
				return value
			end
		elseif value < returnValue then
			return value
		end
	end

	return returnValue
end

function ValueDelay:reset()
	if not self.isReseted then
		for i = 1, self.maxFrames do
			self.values[i].value = 0
			self.values[i].time = -1
		end

		self.isReseted = true
	end
end
