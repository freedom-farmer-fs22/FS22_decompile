AITurnStrategyBulb3 = {}
local AITurnStrategyBulb3_mt = Class(AITurnStrategyBulb3, AITurnStrategy)

function AITurnStrategyBulb3.new(customMt)
	if customMt == nil then
		customMt = AITurnStrategyBulb3_mt
	end

	local self = AITurnStrategy.new(customMt)
	self.strategyName = "AITurnStrategyBulb3"

	return self
end

function AITurnStrategyBulb3:delete()
	AITurnStrategyBulb3:superClass().delete(self)

	self.maxTurningSizeBox = {}
	self.maxTurningSizeBox2 = {}
end

function AITurnStrategyBulb3:startTurn(driveStrategyStraight)
	if not AITurnStrategyBulb3:superClass().startTurn(self, driveStrategyStraight) then
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
		c1Z = 0
		c1Y = 0
		c1X = -turnData.radius
	else
		c1Z = 0
		c1Y = 0
		c1X = turnData.radius
	end

	local alpha = math.acos(math.abs(sideOffset) / turnData.radius)
	local c2X, c2Y, c2Z = nil

	if sideOffset >= 0 then
		c2X = 2 * sideOffset - turnData.radius
	else
		c2X = 2 * sideOffset + turnData.radius
	end

	c2Y = 0
	c2Z = math.sin(alpha) * 2 * turnData.radius
	c1Z = c1Z + turnData.zOffsetTurn
	c2Z = c2Z + turnData.zOffsetTurn
	local rvX, rvY, rvZ = getWorldRotation(self.vehicle:getAIDirectionNode())

	self:addNoFullCoverageSegment(self.turnSegments)

	local segment = {
		isCurve = false,
		moveForward = true,
		slowDown = true,
		startPoint = self:getVehicleToWorld(0, 0, 0, true),
		endPoint = self:getVehicleToWorld(0, 0, c1Z, true)
	}

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = true,
		moveForward = true,
		radius = turnData.radius,
		o = createTransformGroup("segment1")
	}

	link(getRootNode(), segment.o)
	setTranslation(segment.o, self:getVehicleToWorld(c1X, c1Y, c1Z))
	setRotation(segment.o, rvX, rvY, rvZ)

	if sideOffset >= 0 then
		segment.startAngle = 0
		segment.endAngle = alpha
	else
		segment.startAngle = math.pi
		segment.endAngle = math.pi - alpha
	end

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = true,
		moveForward = true,
		radius = turnData.radius,
		o = createTransformGroup("segment2")
	}

	link(getRootNode(), segment.o)
	setTranslation(segment.o, self:getVehicleToWorld(c2X, c2Y, c2Z))
	setRotation(segment.o, rvX, rvY, rvZ)

	if sideOffset >= 0 then
		segment.startAngle = math.pi + alpha
		segment.endAngle = 0
	else
		segment.startAngle = -alpha
		segment.endAngle = math.pi
	end

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = false,
		moveForward = true,
		slowDown = true
	}
	local x = 2 * sideOffset
	segment.startPoint = self:getVehicleToWorld(x, 0, c2Z, true)
	segment.endPoint = self:getVehicleToWorld(x, 0, math.min(turnData.zOffset, c2Z - 0.1), true)

	table.insert(self.turnSegments, segment)
	self:startTurnFinalization()

	return true
end

function AITurnStrategyBulb3:updateTurningSizeBox(box, turnLeft, turnData, lookAheadDistance)
	local sideOffset = nil

	if turnLeft then
		sideOffset = turnData.sideOffsetLeft
	else
		sideOffset = turnData.sideOffsetRight
	end

	local c1X, c1Y, c1Z = nil

	if sideOffset >= 0 then
		c1Z = 0
		c1Y = 0
		c1X = -turnData.radius
	else
		c1Z = 0
		c1Y = 0
		c1X = turnData.radius
	end

	local alpha = math.acos(math.abs(sideOffset) / turnData.radius)
	local c2X, c2Y, c2Z = nil

	if sideOffset >= 0 then
		c2X = 2 * sideOffset - turnData.radius
	else
		c2X = 2 * sideOffset + turnData.radius
	end

	c2Y = 0
	c2Z = math.sin(alpha) * 2 * turnData.radius
	c1Z = c1Z + turnData.zOffsetTurn
	c2Z = c2Z + turnData.zOffsetTurn
	local xb = math.max(turnData.toolOverhang.front.xb, turnData.toolOverhang.back.xb)
	local xt = math.max(turnData.toolOverhang.front.xt, turnData.toolOverhang.back.xt)
	local delta = math.max(xb, turnData.radius + xt)
	local maxX = c2X + delta
	local minX = c2X - delta
	local maxZ = c2Z + delta
	box.center[3] = maxZ / 2 + lookAheadDistance / 2
	box.center[2] = 0
	box.center[1] = maxX - (maxX - minX) / 2
	box.size[3] = maxZ / 2 + lookAheadDistance / 2
	box.size[2] = 5
	box.size[1] = (maxX - minX) / 2

	self:adjustHeightOfTurningSizeBox(box)

	return box
end
