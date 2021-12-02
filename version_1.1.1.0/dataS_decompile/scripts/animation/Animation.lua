Animation = {}
local Animation_mt = Class(Animation)

function Animation.new(customMt)
	local self = setmetatable({}, customMt or Animation_mt)
	self.duplicates = {}

	return self
end

function Animation:delete()
	for i = #self.duplicates, 1, -1 do
		self.duplicates[i] = nil
	end
end

function Animation:update(dt)
end

function Animation:isRunning()
	return false
end

function Animation:start()
	return false
end

function Animation:stop()
	return false
end

function Animation:reset()
end

function Animation:setFillType(fillTypeIndex)
end

function Animation:isDuplicate(otherAnimation)
	return false
end

function Animation:addDuplicate(otherAnimation)
	table.insert(self.duplicates, otherAnimation)
end

function Animation:updateDuplicates()
	for i = 1, #self.duplicates do
		self:updateDuplicate(self.duplicates[i])
	end
end

function Animation:updateDuplicate(otherAnimation)
end

function Animation.calculateTurnOffFadeTime(currentSpeedFactor, currentSpeed, direction, position, targetPosition, originalFadeOut, wrapPosition, subDevisions)
	wrapPosition = wrapPosition / subDevisions
	local finalPos = position
	local speedChangePerMS = 1 / originalFadeOut

	for i = 1, originalFadeOut do
		currentSpeedFactor = math.max(currentSpeedFactor - speedChangePerMS, 0)
		finalPos = finalPos + currentSpeed * currentSpeedFactor
	end

	local int, fraction = math.modf((finalPos - targetPosition) / wrapPosition)
	local targetRad = int * wrapPosition

	if direction > 0 and math.abs(fraction) > 0.2 or direction < 0 and math.abs(fraction) < 0.2 or direction > 0 and targetRad < position or direction < 0 and position < targetRad then
		int = int + direction
	end

	local targetPos = int * wrapPosition + targetPosition

	return (position - targetPos) / (position - finalPos) * originalFadeOut
end
