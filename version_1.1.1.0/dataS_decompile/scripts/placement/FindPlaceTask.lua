FindPlaceTask = {}
local FindPlaceTask_mt = Class(FindPlaceTask)

function FindPlaceTask.new(places, size, callback, callbackTarget, filterFunction)
	local self = setmetatable({}, FindPlaceTask_mt)
	self.places = places
	self.size = size
	self.halfWidth = size.width / 2
	self.halfLength = size.length / 2
	self.halfHeight = size.height / 2
	self.callback = callback
	self.callbackTarget = callbackTarget
	self.filterFunction = filterFunction
	self.curPlaceIndex = 1
	self.currentPlace = nil
	self.currentPositionOffset = 0

	return self
end

function FindPlaceTask:getPlaceFulfillsSizeRequirements()
	if self.currentPlace.maxWidth < self.size.width or self.currentPlace.maxLength < self.size.length or self.currentPlace.maxHeight < self.size.height then
		return false
	end

	return true
end

function FindPlaceTask:getNextPosition()
	if not self.currentPlace and not self:nextPlace() then
		Logging.devWarning("FindPlaceTask: no place available for requested size w=%f:.2, l=%f:.2, h=%f:.2", self.size.width, self.size.length, self.size.height)

		return
	end

	if self.currentPositionOffset >= self.currentPlace.width - self.halfWidth and not self:nextPlace() then
		return
	end

	local location = {
		x = self.currentPlace.startX + (self.halfWidth + self.currentPositionOffset) * self.currentPlace.dirX,
		y = self.currentPlace.startY + (self.halfWidth + self.currentPositionOffset) * self.currentPlace.dirY,
		z = self.currentPlace.startZ + (self.halfWidth + self.currentPositionOffset) * self.currentPlace.dirZ,
		xRot = self.currentPlace.rotX,
		yRot = self.currentPlace.rotY,
		zRot = self.currentPlace.rotZ
	}
	self.currentPositionOffset = self.currentPositionOffset + math.max(self.halfWidth, PlacementUtil.TEST_STEP_SIZE)

	return location
end

function FindPlaceTask:nextPlace()
	self.currentPositionOffset = 0

	while true do
		self.currentPlace = self.places[self.curPlaceIndex]

		if not self.currentPlace then
			return false
		end

		if self:getPlaceFulfillsSizeRequirements() then
			self.curPlaceIndex = self.curPlaceIndex + 1

			return true
		end

		self.curPlaceIndex = self.curPlaceIndex + 1
	end
end
