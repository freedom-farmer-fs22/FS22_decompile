AITurnStrategyHalfCircle = {}
local AITurnStrategyHalfCircle_mt = Class(AITurnStrategyHalfCircle, AITurnStrategy)

function AITurnStrategyHalfCircle.new(customMt)
	if customMt == nil then
		customMt = AITurnStrategyHalfCircle_mt
	end

	local self = AITurnStrategy.new(customMt)
	self.strategyName = "AITurnStrategyHalfCircle"
	self.usesExtraStraight = true

	return self
end

function AITurnStrategyHalfCircle:startTurn(driveStrategyStraight)
	if not AITurnStrategyHalfCircle:superClass().startTurn(self, driveStrategyStraight) then
		return false
	end

	local turnData = driveStrategyStraight.turnData
	local sideOffset = nil

	if self.turnLeft then
		sideOffset = turnData.sideOffsetLeft
	else
		sideOffset = turnData.sideOffsetRight
	end

	local c1X, c1Y, c1Z = nil

	if sideOffset >= 0 then
		c1X, c1Y, c1Z = self:getVehicleToWorld(turnData.radius, 0, turnData.zOffsetTurn)
	else
		c1X, c1Y, c1Z = self:getVehicleToWorld(-turnData.radius, 0, turnData.zOffsetTurn)
	end

	local c2X, c2Y, c2Z = nil

	if sideOffset >= 0 then
		c2X, c2Y, c2Z = self:getVehicleToWorld(2 * turnData.sideOffsetLeft - turnData.radius, 0, turnData.zOffsetTurn)
	else
		c2X, c2Y, c2Z = self:getVehicleToWorld(2 * turnData.sideOffsetRight + turnData.radius, 0, turnData.zOffsetTurn)
	end

	local rvX, rvY, rvZ = getWorldRotation(self.vehicle:getAIDirectionNode(), 0, 0, 0)

	self:addNoFullCoverageSegment(self.turnSegments)

	local segment = {
		isCurve = false,
		moveForward = true,
		slowDown = true,
		startPoint = self:getVehicleToWorld(0, 0, 0, true),
		endPoint = self:getVehicleToWorld(0, 0, turnData.zOffsetTurn, true)
	}

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = true,
		moveForward = true,
		radius = turnData.radius,
		o = createTransformGroup("segment1")
	}

	link(getRootNode(), segment.o)
	setTranslation(segment.o, c1X, c1Y, c1Z)
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
		skipToNextSegmentDistanceThreshold = 3
	}
	local shiftX, shiftY, shiftZ = localDirectionToWorld(self.vehicle:getAIDirectionNode(), 0, 0, turnData.radius)
	segment.startPoint = {
		c1X + shiftX,
		c1Y + shiftY,
		c1Z + shiftZ
	}
	segment.endPoint = {
		c2X + shiftX,
		c2Y + shiftY,
		c2Z + shiftZ
	}

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = true,
		moveForward = true,
		radius = turnData.radius,
		o = createTransformGroup("segment3")
	}

	link(getRootNode(), segment.o)
	setTranslation(segment.o, c2X, c2Y, c2Z)
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
		moveForward = true,
		sowDown = true,
		startPoint = self:getVehicleToWorld(2 * sideOffset, 0, turnData.zOffsetTurn, true),
		endPoint = self:getVehicleToWorld(2 * sideOffset, 0, math.min(turnData.zOffset, turnData.zOffsetTurn - 0.1), true)
	}

	table.insert(self.turnSegments, segment)
	self:startTurnFinalization()

	return true
end

function AITurnStrategyHalfCircle:updateTurningSizeBox(box, turnLeft, turnData, lookAheadDistance)
	local sideOffset = nil

	if turnLeft then
		sideOffset = turnData.sideOffsetLeft
	else
		sideOffset = turnData.sideOffsetRight
	end

	local c1X, c1Z = nil

	if sideOffset >= 0 then
		c1Z = turnData.zOffsetTurn
		c1X = turnData.radius
	else
		c1Z = turnData.zOffsetTurn
		c1X = -turnData.radius
	end

	local c2X, c2Z = nil

	if sideOffset >= 0 then
		c2Z = turnData.zOffsetTurn
		c2X = 2 * sideOffset - turnData.radius
	else
		c2Z = turnData.zOffsetTurn
		c2X = 2 * sideOffset + turnData.radius
	end

	local xb = math.max(turnData.toolOverhang.front.xb, turnData.toolOverhang.back.xb)
	local zb = math.max(turnData.toolOverhang.front.zb, turnData.toolOverhang.back.zb)
	local xt = math.max(turnData.toolOverhang.front.xt, turnData.toolOverhang.back.xt)
	local maxX, minX = nil

	if sideOffset >= 0 then
		minX = math.min(-xb, -xt)
		maxX = math.max(c2X + xb, c2X + turnData.radius + xt)
	else
		maxX = math.max(xb, xt)
		minX = math.min(c2X - xb, c2X - turnData.radius - xt)
	end

	local maxZ = math.max(c1Z + zb, c1Z + turnData.radius + xt)
	box.center[3] = maxZ / 2 + lookAheadDistance / 2
	box.center[2] = 0
	box.center[1] = maxX - (maxX - minX) / 2
	box.size[3] = maxZ / 2 + lookAheadDistance / 2
	box.size[2] = 5
	box.size[1] = (maxX - minX) / 2

	self:adjustHeightOfTurningSizeBox(box)
end
