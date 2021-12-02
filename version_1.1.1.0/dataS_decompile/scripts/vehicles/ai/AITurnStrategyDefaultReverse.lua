AITurnStrategyDefaultReverse = {}
local AITurnStrategyDefaultReverse_mt = Class(AITurnStrategyDefaultReverse, AITurnStrategy)

function AITurnStrategyDefaultReverse.new(customMt)
	if customMt == nil then
		customMt = AITurnStrategyDefaultReverse_mt
	end

	local self = AITurnStrategy.new(customMt)
	self.strategyName = "AITurnStrategyDefaultReverse"
	self.isReverseStrategy = true
	self.turnBox = self:createTurningSizeBox()

	return self
end

function AITurnStrategyDefaultReverse:startTurn(driveStrategyStraight)
	if not AITurnStrategyDefaultReverse:superClass().startTurn(self, driveStrategyStraight) then
		return false
	end

	local turnData = driveStrategyStraight.turnData
	local sideOffset = nil

	if self.turnLeft then
		sideOffset = turnData.sideOffsetLeft
	else
		sideOffset = turnData.sideOffsetRight
	end

	local radius = self:getTurnRadius(turnData.radius, sideOffset)
	local zOffset = self.distanceToCollision

	self:updateTurningSizeBox(self.turnBox, self.turnLeft, turnData, 0)

	zOffset = zOffset + 2 * self.turnBox.size[3]
	local c1X, c1Y, c1Z = nil

	if sideOffset >= 0 then
		c1Z = 0
		c1Y = 0
		c1X = radius
	else
		c1Z = 0
		c1Y = 0
		c1X = -radius
	end

	local c2X, c2Y, c2Z = nil
	local a = 2 * math.abs(sideOffset)
	local b = math.sqrt(2 * radius * 2 * radius - a * a)

	if sideOffset >= 0 then
		c2Z = -b
		c2Y = 0
		c2X = radius + a
	else
		c2Z = -b
		c2Y = 0
		c2X = -radius - a
	end

	local alpha = math.acos(a / (2 * radius))
	local rvX, rvY, rvZ = getWorldRotation(self.vehicle:getAIDirectionNode(), 0, 0, 0)

	self:addNoFullCoverageSegment(self.turnSegments)

	local segment = {
		isCurve = false,
		moveForward = true,
		slowDown = true,
		startPoint = self:getVehicleToWorld(0, 0, -1, true),
		endPoint = self:getVehicleToWorld(0, 0, 0, true)
	}

	table.insert(self.turnSegments, segment)

	segment = {
		isCurve = true,
		moveForward = false,
		slowDown = true,
		usePredictionToSkipToNextSegment = false,
		radius = radius,
		o = createTransformGroup("segment1")
	}

	link(getRootNode(), segment.o)
	setTranslation(segment.o, self:getVehicleToWorld(c1X, c1Y, c1Z))
	setRotation(segment.o, rvX, rvY, rvZ)

	if sideOffset >= 0 then
		segment.startAngle = math.rad(180)
		segment.endAngle = math.rad(360) - alpha
	else
		segment.startAngle = 0
		segment.endAngle = -math.rad(180) + alpha
	end

	table.insert(self.turnSegments, segment)

	segment = {
		isCurve = true,
		moveForward = true,
		slowDown = true,
		radius = radius,
		o = createTransformGroup("segment2")
	}

	link(getRootNode(), segment.o)
	setTranslation(segment.o, self:getVehicleToWorld(c2X, c2Y, c2Z))
	setRotation(segment.o, rvX, rvY, rvZ)

	if sideOffset >= 0 then
		segment.startAngle = math.rad(180) - alpha
		segment.endAngle = math.rad(180)
	else
		segment.startAngle = alpha
		segment.endAngle = 0
	end

	table.insert(self.turnSegments, segment)

	segment = {
		isCurve = false,
		moveForward = turnData.zOffset < c2Z
	}

	if not segment.moveForward then
		self.turnSegments[#self.turnSegments].usePredictionToSkipToNextSegment = false
	end

	segment.slowDown = true
	segment.skipToNextSegmentDistanceThreshold = 0.001
	local x = 2 * sideOffset
	segment.startPoint = self:getVehicleToWorld(x, 0, c2Z, true)
	segment.endPoint = self:getVehicleToWorld(x, 0, turnData.zOffset, true)

	table.insert(self.turnSegments, segment)
	self:startTurnFinalization()

	return true
end

function AITurnStrategyDefaultReverse:updateTurningSizeBox(box, turnLeft, turnData, lookAheadDistance)
	local sideOffset = nil

	if turnLeft then
		sideOffset = turnData.sideOffsetLeft
	else
		sideOffset = turnData.sideOffsetRight
	end

	local radius = self:getTurnRadius(turnData.radius, sideOffset)
	local c1X, c1Y, c1Z = nil

	if sideOffset >= 0 then
		c1Z = turnData.minZOffset
		c1Y = 0
		c1X = radius
	else
		c1Z = turnData.minZOffset
		c1Y = 0
		c1X = -radius
	end

	local c2X, c2Y, c2Z = nil
	c2Y = 0

	if sideOffset >= 0 then
		c2X = radius + 2 * sideOffset
		c2Z = -2 * radius + turnData.minZOffset
	else
		c2X = -radius + 2 * sideOffset
		c2Z = -2 * radius + turnData.minZOffset
	end

	local maxX, minX = nil

	if sideOffset >= 0 then
		local xt = -math.max(turnData.toolOverhang.front.xt, turnData.toolOverhang.back.xt)
		minX = math.min(xt, c1X - math.max(turnData.toolOverhang.front.zt, turnData.toolOverhang.front.xt, turnData.toolOverhang.front.xb, turnData.toolOverhang.front.zb))
		maxX = c2X + turnData.toolOverhang.back.zt
	else
		local xt = math.max(turnData.toolOverhang.front.xt, turnData.toolOverhang.back.xt)
		maxX = math.max(xt, c1X + math.max(turnData.toolOverhang.front.zt, turnData.toolOverhang.front.xt, turnData.toolOverhang.front.xb, turnData.toolOverhang.front.zb))
		minX = c2X - turnData.toolOverhang.back.zt
	end

	local maxZ = math.max(turnData.toolOverhang.front.zt, turnData.zOffset + turnData.toolOverhang.back.zt)
	box.center[3] = maxZ / 2 + lookAheadDistance / 2
	box.center[2] = 0
	box.center[1] = maxX - (maxX - minX) / 2
	box.size[3] = maxZ / 2 + lookAheadDistance / 2
	box.size[2] = 5
	box.size[1] = (maxX - minX) / 2

	self:adjustHeightOfTurningSizeBox(box)
end
