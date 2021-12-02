AITurnStrategyHalfCircleReverse = {}
local AITurnStrategyHalfCircleReverse_mt = Class(AITurnStrategyHalfCircleReverse, AITurnStrategy)

function AITurnStrategyHalfCircleReverse.new(customMt)
	if customMt == nil then
		customMt = AITurnStrategyHalfCircleReverse_mt
	end

	local self = AITurnStrategy.new(customMt)
	self.strategyName = "AITurnStrategyHalfCircleReverse"
	self.usesExtraStraight = true
	self.isReverseStrategy = true
	self.turnBox = self:createTurningSizeBox()

	return self
end

function AITurnStrategyHalfCircleReverse:startTurn(driveStrategyStraight)
	if not AITurnStrategyHalfCircleReverse:superClass().startTurn(self, driveStrategyStraight) then
		return false
	end

	local turnData = driveStrategyStraight.turnData
	local sideOffset = nil

	if self.turnLeft then
		sideOffset = turnData.sideOffsetLeft
	else
		sideOffset = turnData.sideOffsetRight
	end

	local zOffset = self.distanceToCollision

	self:updateTurningSizeBox(self.turnBox, self.turnLeft, turnData, 0)

	zOffset = zOffset + 2 * self.turnBox.size[3]
	local c1X, c1Y, c1Z = nil

	if sideOffset >= 0 then
		c1Z = turnData.zOffsetTurn
		c1Y = 0
		c1X = turnData.radius
	else
		c1Z = turnData.zOffsetTurn
		c1Y = 0
		c1X = -turnData.radius
	end

	local c2X, c2Y, c2Z = nil

	if sideOffset >= 0 then
		c2Z = turnData.zOffsetTurn
		c2Y = 0
		c2X = 2 * sideOffset - turnData.radius
	else
		c2Z = turnData.zOffsetTurn
		c2Y = 0
		c2X = 2 * sideOffset + turnData.radius
	end

	local rvX, rvY, rvZ = getWorldRotation(self.vehicle:getAIDirectionNode(), 0, 0, 0)
	local xb = math.max(turnData.toolOverhang.front.xb, turnData.toolOverhang.back.xb)
	local zb = math.max(turnData.toolOverhang.front.zb, turnData.toolOverhang.back.zb)
	local xt = math.max(turnData.toolOverhang.front.xt, turnData.toolOverhang.back.xt)
	local zt = math.max(turnData.toolOverhang.front.zt, turnData.toolOverhang.back.zt)
	local delta = math.max(xb, zb, turnData.radius + xt, turnData.radius + zt)
	local fullBulbLength = c1Z + delta
	local bulbLength = math.max(0, fullBulbLength - zOffset)

	self:addNoFullCoverageSegment(self.turnSegments)

	local segment = {
		isCurve = false,
		moveForward = c1Z - bulbLength > 0,
		slowDown = true
	}

	if segment.moveForward then
		segment.skipToNextSegmentDistanceThreshold = 3
	end

	segment.startPoint = self:getVehicleToWorld(0, 0, 0, true)
	segment.endPoint = self:getVehicleToWorld(0, 0, c1Z - bulbLength, true)

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = true,
		moveForward = true,
		radius = turnData.radius,
		o = createTransformGroup("segment1")
	}

	link(getRootNode(), segment.o)
	setTranslation(segment.o, self:getVehicleToWorld(c1X, c1Y, c1Z - bulbLength))
	setRotation(segment.o, rvX, rvY, rvZ)

	if sideOffset >= 0 then
		segment.startAngle = math.rad(180)
		segment.endAngle = math.rad(90)
	else
		segment.startAngle = math.rad(0)
		segment.endAngle = math.rad(90)
	end

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = false,
		moveForward = true,
		skipToNextSegmentDistanceThreshold = 3,
		startPoint = self:getVehicleToWorld(c1X, c1Y, c1Z + turnData.radius - bulbLength, true),
		endPoint = self:getVehicleToWorld(c2X, c2Y, c2Z + turnData.radius - bulbLength, true)
	}

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = true,
		moveForward = true,
		radius = turnData.radius,
		o = createTransformGroup("segment3")
	}

	link(getRootNode(), segment.o)
	setTranslation(segment.o, self:getVehicleToWorld(c2X, c2Y, c2Z - bulbLength))
	setRotation(segment.o, rvX, rvY, rvZ)

	if sideOffset >= 0 then
		segment.startAngle = math.rad(90)
		segment.endAngle = math.rad(0)
	else
		segment.startAngle = math.rad(90)
		segment.endAngle = math.rad(180)
	end

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = false,
		moveForward = c2Z - bulbLength > c2Z - 2 * fullBulbLength,
		slowDown = true,
		checkAlignmentToSkipSegment = true
	}
	local x = 2 * sideOffset
	segment.startPoint = self:getVehicleToWorld(x, 0, c2Z - bulbLength, true)
	segment.endPoint = self:getVehicleToWorld(x, 0, c2Z - 2 * fullBulbLength, true)

	table.insert(self.turnSegments, segment)

	local zFinal = turnData.zOffset
	local segment = {
		isCurve = false,
		moveForward = zFinal < c2Z - 2 * fullBulbLength,
		slowDown = true,
		findEndOfField = true,
		startPoint = self:getVehicleToWorld(x, 0, c2Z - 2 * fullBulbLength, true),
		endPoint = self:getVehicleToWorld(x, 0, zFinal, true)
	}

	table.insert(self.turnSegments, segment)
	self:startTurnFinalization()

	return true
end

function AITurnStrategyHalfCircleReverse:updateTurningSizeBox(box, turnLeft, turnData, lookAheadDistance)
	local sideOffset = nil

	if turnLeft then
		sideOffset = turnData.sideOffsetLeft
	else
		sideOffset = turnData.sideOffsetRight
	end

	local c1X, c1Y, c1Z = nil

	if sideOffset >= 0 then
		c1Z = turnData.zOffsetTurn
		c1Y = 0
		c1X = turnData.radius
	else
		c1Z = turnData.zOffsetTurn
		c1Y = 0
		c1X = -turnData.radius
	end

	local c2X, c2Y, c2Z = nil

	if sideOffset >= 0 then
		c2Z = turnData.zOffsetTurn
		c2Y = 0
		c2X = 2 * sideOffset - turnData.radius
	else
		c2Z = turnData.zOffsetTurn
		c2Y = 0
		c2X = 2 * sideOffset + turnData.radius
	end

	local xb = math.max(turnData.toolOverhang.front.xb, turnData.toolOverhang.back.xb)
	local xt = math.max(turnData.toolOverhang.front.xt, turnData.toolOverhang.back.xt)
	local maxX, minX = nil

	if sideOffset >= 0 then
		minX = math.min(c1X - xb, -xt)
		maxX = math.max(c2X + xb, c2X + turnData.radius + xt)
	else
		maxX = math.max(c1X + xb, xt)
		minX = math.min(c2X - xb, c2X - turnData.radius - xt)
	end

	local maxZ = turnData.toolOverhang.front.zt
	box.center[3] = maxZ / 2 + lookAheadDistance / 2
	box.center[2] = 0
	box.center[1] = maxX - (maxX - minX) / 2
	box.size[3] = maxZ / 2 + lookAheadDistance / 2
	box.size[2] = 5
	box.size[1] = (maxX - minX) / 2

	self:adjustHeightOfTurningSizeBox(box)
end
