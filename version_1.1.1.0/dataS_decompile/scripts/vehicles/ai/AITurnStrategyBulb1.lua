AITurnStrategyBulb1 = {}
local AITurnStrategyBulb1_mt = Class(AITurnStrategyBulb1, AITurnStrategy)

function AITurnStrategyBulb1.new(customMt)
	if customMt == nil then
		customMt = AITurnStrategyBulb1_mt
	end

	local self = AITurnStrategy.new(customMt)
	self.strategyName = "AITurnStrategyBulb1"

	return self
end

function AITurnStrategyBulb1:delete()
	AITurnStrategyBulb1:superClass().delete(self)

	self.maxTurningSizeBox = {}
	self.maxTurningSizeBox2 = {}
end

function AITurnStrategyBulb1:startTurn(driveStrategyStraight)
	if not AITurnStrategyBulb1:superClass().startTurn(self, driveStrategyStraight) then
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
		c1X, c1Y, c1Z = self:getVehicleToWorld(-turnData.radius, 0, turnData.zOffsetTurn)
	else
		c1X, c1Y, c1Z = self:getVehicleToWorld(turnData.radius, 0, turnData.zOffsetTurn)
	end

	local a = turnData.radius + math.abs(sideOffset)
	local z = math.sqrt(2 * turnData.radius * 2 * turnData.radius - a * a)
	local c2X, c2Y, c2Z = self:getVehicleToWorld(sideOffset, 0, z + turnData.zOffsetTurn)
	local c3X, c3Y, c3Z = nil

	if sideOffset >= 0 then
		c3X, c3Y, c3Z = self:getVehicleToWorld(2 * sideOffset + turnData.radius, 0, turnData.zOffsetTurn)
	else
		c3X, c3Y, c3Z = self:getVehicleToWorld(2 * sideOffset - turnData.radius, 0, turnData.zOffsetTurn)
	end

	local alpha = math.atan(z / a)
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
		segment.startAngle = 0
		segment.endAngle = alpha
	else
		segment.startAngle = math.rad(180)
		segment.endAngle = math.rad(180) - alpha
	end

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = true,
		moveForward = true,
		radius = turnData.radius,
		o = createTransformGroup("segment2")
	}

	link(getRootNode(), segment.o)
	setTranslation(segment.o, c2X, c2Y, c2Z)
	setRotation(segment.o, rvX, rvY, rvZ)

	if sideOffset >= 0 then
		segment.startAngle = math.rad(180) + alpha
		segment.endAngle = -alpha
	else
		segment.startAngle = -alpha
		segment.endAngle = math.rad(180) + alpha
	end

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = true,
		moveForward = true,
		radius = turnData.radius,
		o = createTransformGroup("segment3")
	}

	link(getRootNode(), segment.o)
	setTranslation(segment.o, c3X, c3Y, c3Z)
	setRotation(segment.o, rvX, rvY, rvZ)

	if sideOffset >= 0 then
		segment.startAngle = math.rad(180) - alpha
		segment.endAngle = math.rad(180)
	else
		segment.startAngle = alpha
		segment.endAngle = 0
	end

	table.insert(self.turnSegments, segment)

	local segment = {
		isCurve = false,
		moveForward = true,
		slowDown = true
	}
	local x = 2 * sideOffset
	segment.startPoint = self:getVehicleToWorld(x, 0, turnData.zOffsetTurn, true)
	segment.endPoint = self:getVehicleToWorld(x, 0, math.min(turnData.zOffset, turnData.zOffsetTurn - 0.1), true)

	table.insert(self.turnSegments, segment)
	self:startTurnFinalization()

	return true
end

function AITurnStrategyBulb1:updateTurningSizeBox(box, turnLeft, turnData, lookAheadDistance)
	local sideOffset = nil

	if turnLeft then
		sideOffset = turnData.sideOffsetLeft
	else
		sideOffset = turnData.sideOffsetRight
	end

	local a = turnData.radius + math.abs(sideOffset)
	local z = math.sqrt(2 * turnData.radius * 2 * turnData.radius - a * a)
	local c2X = sideOffset
	local c2Y = 0
	local c2Z = z + turnData.zOffsetTurn
	local xb = math.max(turnData.toolOverhang.front.xb, turnData.toolOverhang.back.xb)
	local xt = math.max(turnData.toolOverhang.front.xt, turnData.toolOverhang.back.xt)
	local delta = math.max(xb, turnData.radius + xt)
	local maxX = c2X + xb
	local minX = c2X - xb
	local maxZ = c2Z + delta
	box.center[3] = maxZ / 2 + lookAheadDistance / 2
	box.center[2] = 0
	box.center[1] = maxX - (maxX - minX) / 2
	box.size[3] = maxZ / 2 + lookAheadDistance / 2
	box.size[2] = 5
	box.size[1] = (maxX - minX) / 2

	self:adjustHeightOfTurningSizeBox(box)
end
