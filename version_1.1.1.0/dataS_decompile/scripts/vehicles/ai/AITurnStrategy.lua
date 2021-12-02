AITurnStrategy = {
	COLLISION_BOX_COLOR_OK = {
		0,
		1,
		0
	},
	COLLISION_BOX_COLOR_HIT = {
		1,
		0,
		0
	},
	SLOPE_DETECTION_THRESHOLD = math.rad(30),
	DENSITY_HEIGHT_THRESHOLD = 2
}
local AITurnStrategy_mt = Class(AITurnStrategy)

function AITurnStrategy.new(customMt)
	if customMt == nil then
		customMt = AITurnStrategy_mt
	end

	local self = {}

	setmetatable(self, customMt)

	self.isTurning = false
	self.turnLeft = nil
	self.collisionDetected = false
	self.usesExtraStraight = false
	self.distanceToCollision = 5
	self.maxTurningSizeBoxes = {}
	self.maxTurningSizeBoxes2 = {}
	self.turnSegments = {}
	self.requestToEndTurn = false
	self.lastValidTurnPositionOffset = 0
	self.corridorPositionOffset = 0
	self.strategyName = "AITurnStrategy"
	self.leftBox = self:createTurningSizeBox()
	self.rightBox = self:createTurningSizeBox()
	self.heightChecks = {}

	table.insert(self.heightChecks, {
		1,
		1
	})
	table.insert(self.heightChecks, {
		-1,
		1
	})
	table.insert(self.heightChecks, {
		1,
		-1
	})
	table.insert(self.heightChecks, {
		-1,
		-1
	})

	self.numHeightChecks = 4
	self.lastWaterY1 = -2000
	self.lastWaterY2 = -2000

	return self
end

function AITurnStrategy:delete()
	self:clearTurnSegments()
end

function AITurnStrategy:setAIVehicle(vehicle, parent)
	self.vehicle = vehicle
	self.vehicleDirectionNode = self.vehicle:getAIDirectionNode()
	self.vehicleAISteeringNode = self.vehicle:getAISteeringNode()
	self.vehicleAIReverserNode = self.vehicle:getAIReverserNode()
	self.reverserDirectionNode = AIVehicleUtil.getAIToolReverserDirectionNode(self.vehicle)
	self.parent = parent

	AIVehicleUtil.updateInvertLeftRightMarkers(self.vehicle, self.vehicle)

	for _, implement in pairs(self.vehicle:getAttachedAIImplements()) do
		AIVehicleUtil.updateInvertLeftRightMarkers(self.vehicle, implement.object)
	end
end

function AITurnStrategy:update(dt)
	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		AITurnStrategy.drawTurnSegments(self.turnSegments)

		if self.maxTurningSizeBoxes ~= nil then
			if table.getn(self.maxTurningSizeBoxes) > 0 then
				self.maxTurningSizeBoxes2 = {}

				for _, box in pairs(self.maxTurningSizeBoxes) do
					local box2 = {
						points = {},
						color = {
							unpack(box.color)
						}
					}
					local x = box.x
					local y = box.y
					local z = box.z
					local blx = box.xx * box.size[1] - box.zx * box.size[3]
					local blz = box.xz * box.size[1] - box.zz * box.size[3]
					local brx = -box.xx * box.size[1] - box.zx * box.size[3]
					local brz = -box.xz * box.size[1] - box.zz * box.size[3]
					local flx = box.xx * box.size[1] + box.zx * box.size[3]
					local flz = box.xz * box.size[1] + box.zz * box.size[3]
					local frx = -box.xx * box.size[1] + box.zx * box.size[3]
					local frz = -box.xz * box.size[1] + box.zz * box.size[3]

					table.insert(box2.points, {
						x + blx,
						y - box.size[2],
						z + blz
					})
					table.insert(box2.points, {
						x + brx,
						y - box.size[2],
						z + brz
					})
					table.insert(box2.points, {
						x + frx,
						y - box.size[2],
						z + frz
					})
					table.insert(box2.points, {
						x + flx,
						y - box.size[2],
						z + flz
					})
					table.insert(box2.points, {
						x + blx,
						y + box.size[2],
						z + blz
					})
					table.insert(box2.points, {
						x + brx,
						y + box.size[2],
						z + brz
					})
					table.insert(box2.points, {
						x + frx,
						y + box.size[2],
						z + frz
					})
					table.insert(box2.points, {
						x + flx,
						y + box.size[2],
						z + flz
					})
					table.insert(box2.points, {
						x,
						y,
						z
					})
					table.insert(self.maxTurningSizeBoxes2, box2)
				end

				self.maxTurningSizeBoxes = {}
			end

			if self.maxTurningSizeBoxes2 ~= nil then
				for _, box2 in pairs(self.maxTurningSizeBoxes2) do
					local p = box2.points
					local c = box2.color

					drawDebugLine(p[1][1], p[1][2], p[1][3], c[1], c[2], c[3], p[2][1], p[2][2], p[2][3], c[1], c[2], c[3])
					drawDebugLine(p[2][1], p[2][2], p[2][3], c[1], c[2], c[3], p[3][1], p[3][2], p[3][3], c[1], c[2], c[3])
					drawDebugLine(p[3][1], p[3][2], p[3][3], c[1], c[2], c[3], p[4][1], p[4][2], p[4][3], c[1], c[2], c[3])
					drawDebugLine(p[4][1], p[4][2], p[4][3], c[1], c[2], c[3], p[1][1], p[1][2], p[1][3], c[1], c[2], c[3])
					drawDebugLine(p[5][1], p[5][2], p[5][3], c[1], c[2], c[3], p[6][1], p[6][2], p[6][3], c[1], c[2], c[3])
					drawDebugLine(p[6][1], p[6][2], p[6][3], c[1], c[2], c[3], p[7][1], p[7][2], p[7][3], c[1], c[2], c[3])
					drawDebugLine(p[7][1], p[7][2], p[7][3], c[1], c[2], c[3], p[8][1], p[8][2], p[8][3], c[1], c[2], c[3])
					drawDebugLine(p[8][1], p[8][2], p[8][3], c[1], c[2], c[3], p[5][1], p[5][2], p[5][3], c[1], c[2], c[3])
					drawDebugLine(p[1][1], p[1][2], p[1][3], c[1], c[2], c[3], p[5][1], p[5][2], p[5][3], c[1], c[2], c[3])
					drawDebugLine(p[4][1], p[4][2], p[4][3], c[1], c[2], c[3], p[8][1], p[8][2], p[8][3], c[1], c[2], c[3])
					drawDebugLine(p[2][1], p[2][2], p[2][3], c[1], c[2], c[3], p[6][1], p[6][2], p[6][3], c[1], c[2], c[3])
					drawDebugLine(p[3][1], p[3][2], p[3][3], c[1], c[2], c[3], p[7][1], p[7][2], p[7][3], c[1], c[2], c[3])

					p[9][2] = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, p[9][1], p[9][2], p[9][3]) + 2

					drawDebugPoint(p[9][1], p[9][2], p[9][3], 1, 0, 0, 1)
					Utils.renderTextAtWorldPosition(p[9][1], p[9][2], p[9][3], self.strategyName, getCorrectTextSize(0.012), 0)
				end
			end
		end
	end
end

function AITurnStrategy:getDriveData(dt, vX, vY, vZ, turnData)
	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		self.vehicle:addAIDebugText(string.format("strategy: %s", self.strategyName))
	end

	local tX, tY, tZ = nil
	local maxSpeed = self.vehicle:getSpeedLimit(true)
	maxSpeed = math.min(14, maxSpeed)
	local distanceToStop = nil
	local segment = self.turnSegments[self.activeTurnSegmentIndex]
	local segmentIsFinished = false
	local moveForwards = segment.moveForward

	if segment.isCurve then
		local angleDirSign = MathUtil.sign(segment.endAngle - segment.startAngle)
		local curAngle = nil

		if self.reverserDirectionNode ~= nil and not moveForwards then
			curAngle = AITurnStrategy.getAngleInSegment(self.reverserDirectionNode, segment)
		else
			curAngle = AITurnStrategy.getAngleInSegment(self.vehicleAISteeringNode, segment)
		end

		local nextAngleDistance = math.max(3, 0.33 * self.vehicle.maxTurningRadius)
		local nextAngle = curAngle + angleDirSign * nextAngleDistance / segment.radius

		if math.pi < nextAngle then
			nextAngle = nextAngle - 2 * math.pi
		elseif nextAngle < -math.pi then
			nextAngle = nextAngle + 2 * math.pi
		end

		local endAngle = segment.endAngle

		if math.pi < endAngle then
			endAngle = endAngle - 2 * math.pi
		elseif endAngle < -math.pi then
			endAngle = endAngle + 2 * math.pi
		end

		angleDirSign = MathUtil.sign(segment.endAngle - segment.startAngle)
		local curAngleDiff = angleDirSign * (curAngle - endAngle)

		if math.rad(10) < curAngleDiff then
			curAngleDiff = curAngleDiff - 2 * math.pi
		elseif curAngleDiff < -2 * math.pi + math.rad(10) then
			curAngleDiff = curAngleDiff + 2 * math.pi
		end

		local nextAngleDiff = angleDirSign * (nextAngle - endAngle)

		if math.rad(10) < nextAngleDiff then
			nextAngleDiff = nextAngleDiff - 2 * math.pi
		elseif nextAngleDiff < -2 * math.pi + math.rad(10) then
			nextAngleDiff = nextAngleDiff + 2 * math.pi
		end

		local pX = math.cos(nextAngle) * segment.radius
		local pZ = math.sin(nextAngle) * segment.radius
		tX, tY, tZ = localToWorld(segment.o, pX, 0, pZ)
		distanceToStop = -curAngleDiff * segment.radius

		if distanceToStop < 0.01 or segment.usePredictionToSkipToNextSegment ~= false and nextAngleDiff > 0 then
			segmentIsFinished = true
		end

		if segment.checkForSkipToNextSegment then
			local nextSegment = self.turnSegments[self.activeTurnSegmentIndex + 1]
			local dirX = nextSegment.endPoint[1] - nextSegment.startPoint[1]
			local dirZ = nextSegment.endPoint[3] - nextSegment.startPoint[3]
			local dirLength = MathUtil.vector2Length(dirX, dirZ)
			local dx, _ = nil

			if self.reverserDirectionNode ~= nil and not moveForwards then
				dx, _, _ = worldDirectionToLocal(self.reverserDirectionNode, dirX / dirLength, 0, dirZ / dirLength)
			else
				dx, _, _ = worldDirectionToLocal(self.vehicleAISteeringNode, dirX / dirLength, 0, dirZ / dirLength)
			end

			local l = MathUtil.vector2Length(dirX, dirZ)
			dirZ = dirZ / l
			dirX = dirX / l
			pX, pZ = MathUtil.projectOnLine(vX, vZ, nextSegment.startPoint[1], nextSegment.startPoint[3], dirX, dirZ)
			local dist = MathUtil.vector2Length(vX - pX, vZ - pZ)
			local distToStart = MathUtil.vector2Length(vX - nextSegment.startPoint[1], vZ - nextSegment.startPoint[3])

			if dist < 1.5 and math.abs(dx) < 0.15 and distToStart < self.vehicle.size.length / 2 then
				segmentIsFinished = true
			end
		end

		if not moveForwards and self.reverserDirectionNode ~= nil then
			local x, _, z = worldToLocal(self.reverserDirectionNode, tX, vY, tZ)
			local alpha = Utils.getYRotationBetweenNodes(self.vehicleAISteeringNode, self.reverserDirectionNode)
			local ltX = math.cos(alpha) * x - math.sin(alpha) * z
			local ltZ = math.sin(alpha) * x + math.cos(alpha) * z
			ltX = -ltX
			tX, _, tZ = localToWorld(self.vehicleAISteeringNode, ltX, 0, ltZ)
		end

		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			drawDebugLine(vX, vY + 2, vZ, 1, 1, 0, tX, tY + 2, tZ, 1, 1, 0)
		end
	else
		local toolX, _, toolZ = nil

		if self.reverserDirectionNode ~= nil then
			toolX, _, toolZ = getWorldTranslation(self.reverserDirectionNode)
		end

		local dirX = segment.endPoint[1] - segment.startPoint[1]
		local dirZ = segment.endPoint[3] - segment.startPoint[3]
		local l = MathUtil.vector2Length(dirX, dirZ)
		dirZ = dirZ / l
		dirX = dirX / l
		local pX, pZ = nil

		if self.reverserDirectionNode ~= nil and not moveForwards then
			pX, pZ = MathUtil.projectOnLine(toolX, toolZ, segment.startPoint[1], segment.startPoint[3], dirX, dirZ)
		elseif self.vehicleAIReverserNode ~= nil and not moveForwards then
			toolX, _, toolZ = getWorldTranslation(self.vehicleAIReverserNode)
			pX, pZ = MathUtil.projectOnLine(toolX, toolZ, segment.startPoint[1], segment.startPoint[3], dirX, dirZ)
		else
			pX, pZ = MathUtil.projectOnLine(vX, vZ, segment.startPoint[1], segment.startPoint[3], dirX, dirZ)
		end

		local factor = 1
		tX = pX + dirX * factor * self.vehicle.maxTurningRadius
		tZ = pZ + dirZ * factor * self.vehicle.maxTurningRadius

		if self.reverserDirectionNode ~= nil and not moveForwards then
			local x, _, z = worldToLocal(self.reverserDirectionNode, tX, vY, tZ)
			local alpha = Utils.getYRotationBetweenNodes(self.vehicleAISteeringNode, self.reverserDirectionNode)
			local articulatedAxisSpec = self.vehicle.spec_articulatedAxis

			if articulatedAxisSpec ~= nil and articulatedAxisSpec.componentJoint ~= nil then
				local node1 = self.vehicle.components[articulatedAxisSpec.componentJoint.componentIndices[1]].node
				local node2 = self.vehicle.components[articulatedAxisSpec.componentJoint.componentIndices[2]].node

				if articulatedAxisSpec.anchorActor == 1 then
					node2 = node1
					node1 = node2
				end

				local beta = Utils.getYRotationBetweenNodes(node1, node2)
				alpha = alpha - beta
			end

			local ltX = math.cos(alpha) * x - math.sin(alpha) * z
			local ltZ = math.sin(alpha) * x + math.cos(alpha) * z
			ltX = -ltX
			tX, _, tZ = localToWorld(self.vehicleAISteeringNode, ltX, 0, ltZ)
		end

		distanceToStop = MathUtil.vector3Length(segment.endPoint[1] - vX, segment.endPoint[2] - vY, segment.endPoint[3] - vZ)
		local _, _, lz = worldToLocal(self.vehicleAISteeringNode, segment.endPoint[1], segment.endPoint[2], segment.endPoint[3])

		if segment.moveForward and lz < 0 or not segment.moveForward and lz > 0 then
			segmentIsFinished = true
		end

		if segment.checkAlignmentToSkipSegment then
			local d1x, _, d1z = localDirectionToWorld(self.vehicleAISteeringNode, 0, 0, 1)
			local l1 = MathUtil.vector2Length(d1x, d1z)
			d1z = d1z / l1
			d1x = d1x / l1
			local a1 = math.acos(d1x * dirX + d1z * dirZ)
			local dist = MathUtil.vector2Length(vX - pX, vZ - pZ)
			local canSkip = math.deg(a1) < 8 and dist < 0.6

			if self.vehicle.spec_articulatedAxis ~= nil and self.vehicle.spec_articulatedAxis.componentJoint ~= nil then
				for i = 1, 2 do
					local node = self.vehicle.components[self.vehicle.spec_articulatedAxis.componentJoint.componentIndices[i]].node
					d1x, _, d1z = localDirectionToWorld(node, 0, 0, 1)
					l1 = MathUtil.vector2Length(d1x, d1z)
					d1z = d1z / l1
					d1x = d1x / l1
					local a = math.acos(d1x * dirX + d1z * dirZ)
					canSkip = canSkip and math.deg(a) < 8
				end
			end

			if self.reverserDirectionNode ~= nil then
				local d2x, _, d2z = localDirectionToWorld(self.reverserDirectionNode, 0, 0, 1)
				local l2 = MathUtil.vector2Length(d2x, d2z)
				d2z = d2z / l2
				d2x = d2x / l2
				local a2 = math.acos(d2x * dirX + d2z * dirZ)
				pX, pZ = MathUtil.projectOnLine(toolX, toolZ, segment.startPoint[1], segment.startPoint[3], dirX, dirZ)
				dist = MathUtil.vector2Length(toolX - pX, toolZ - pZ)
				canSkip = canSkip and math.deg(a2) < 6 and dist < 0.6
			end

			local nextSegment = self.turnSegments[self.activeTurnSegmentIndex + 1]
			local _, _, sz = worldToLocal(self.vehicleDirectionNode, nextSegment.startPoint[1], nextSegment.startPoint[2], nextSegment.startPoint[3])
			local _, _, ez = worldToLocal(self.vehicleDirectionNode, nextSegment.endPoint[1], nextSegment.endPoint[2], nextSegment.endPoint[3])
			canSkip = canSkip and (sz < 0 or ez < 0)

			if canSkip then
				segmentIsFinished = true
			end
		end

		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			local sY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, tX, vY, tZ)

			drawDebugLine(vX, vY + 2, vZ, 1, 1, 0, tX, sY + 2, tZ, 1, 1, 0)
		end
	end

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		self.vehicle:addAIDebugText(string.format("active segment: %d", self.activeTurnSegmentIndex))
	end

	if segment.checkForValidArea then
		local lookAheadDist = 0
		local lookAheadSize = 1

		if not moveForwards then
			lookAheadSize = -1
		end

		if AIVehicleUtil.checkImplementListForValidGround(self.vehicle, lookAheadDist, lookAheadSize) then
			segmentIsFinished = true
			self.activeTurnSegmentIndex = #self.turnSegments
		end
	end

	if segment.findEndOfField then
		local lookAheadDist = 0
		local lookAheadSize = 1

		if not moveForwards then
			lookAheadSize = -1
		end

		if not AIVehicleUtil.checkImplementListForValidGround(self.vehicle, lookAheadDist, lookAheadSize) then
			segmentIsFinished = true
		end
	end

	if segmentIsFinished or self.requestToEndTurn then
		self.activeTurnSegmentIndex = self.activeTurnSegmentIndex + 1

		if self.turnSegments[self.activeTurnSegmentIndex] == nil then
			self.isTurning = false
			self.requestToEndTurn = false

			return nil
		end
	end

	local totalSegmentLength = 0
	local usedSegmentDistance = 0

	for i, turnSegment in ipairs(self.turnSegments) do
		if turnSegment.checkAlignmentToSkipSegment then
			break
		end

		local segmentLength = nil

		if turnSegment.isCurve then
			segmentLength = math.abs(turnSegment.endAngle - turnSegment.startAngle) * turnSegment.radius
		else
			segmentLength = math.abs(MathUtil.vector3Length(turnSegment.endPoint[1] - turnSegment.startPoint[1], turnSegment.endPoint[2] - turnSegment.startPoint[2], turnSegment.endPoint[3] - turnSegment.startPoint[3]))
		end

		segmentLength = math.abs(segmentLength)
		totalSegmentLength = totalSegmentLength + segmentLength

		if i < self.activeTurnSegmentIndex then
			usedSegmentDistance = usedSegmentDistance + segmentLength
		elseif i == self.activeTurnSegmentIndex then
			usedSegmentDistance = usedSegmentDistance + segmentLength - distanceToStop
		end
	end

	local turnProgress = usedSegmentDistance / totalSegmentLength

	self.vehicle:aiFieldWorkerTurnProgress(turnProgress, self.turnLeft)

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		self.vehicle:addAIDebugText(string.format("turn progress: %.1f%%", turnProgress * 100))
	end

	if not segment.slowDown then
		distanceToStop = math.huge
	end

	return tX, tZ, moveForwards, maxSpeed, distanceToStop
end

function AITurnStrategy:updateTurningSizeBox(box, turnLeft, turnData, distanceToTurn)
	box.center[3] = distanceToTurn / 2
	box.size[3] = distanceToTurn / 2
	box.size[2] = 5
	box.size[1] = 3
end

function AITurnStrategy:createTurningSizeBox()
	local box = {
		center = {
			0,
			0,
			0
		},
		rotation = {
			0,
			0,
			0
		},
		size = {
			0,
			0,
			0
		}
	}

	return box
end

function AITurnStrategy:getDistanceToCollision(dt, vX, vY, vZ, turnData, lookAheadDistance)
	local allowLeft = self.usesExtraStraight == turnData.useExtraStraightLeft
	local allowRight = self.usesExtraStraight == turnData.useExtraStraightRight
	local distanceToTurn = lookAheadDistance

	if not allowLeft and not allowRight then
		distanceToTurn = -1
	elseif self.turnLeft ~= nil then
		if self.turnLeft and not allowRight or not self.turnLeft and not allowLeft then
			distanceToTurn = -1
		end
	else
		local allowLeftWithCol = allowLeft and self.collisionEndPosLeft == nil
		local allowRightWithCol = allowRight and self.collisionEndPosRight == nil

		if not allowLeftWithCol or not allowRightWithCol then
			local leftAreaPercentage, rightAreaPercentage = AIVehicleUtil.getValidityOfTurnDirections(self.vehicle, turnData)

			if allowLeftWithCol and leftAreaPercentage <= 3 * AIVehicleUtil.VALID_AREA_THRESHOLD then
				distanceToTurn = -1
			end

			if allowRightWithCol and rightAreaPercentage <= 3 * AIVehicleUtil.VALID_AREA_THRESHOLD then
				distanceToTurn = -1
			end
		end
	end

	if self.collisionDetected then
		if self.collisionDetectedPosX ~= nil then
			local dist = MathUtil.vector3Length(vX - self.collisionDetectedPosX, vY - self.collisionDetectedPosY, vZ - self.collisionDetectedPosZ)
			distanceToTurn = math.min(distanceToTurn, lookAheadDistance - dist)
		else
			distanceToTurn = -1
		end
	end

	self.distanceToCollision = distanceToTurn
	local boxLookBackDistance = 0

	if self.parent ~= nil and self.parent.rowStartTranslation ~= nil then
		local x, _, z = getWorldTranslation(self.vehicle:getAIDirectionNode())
		boxLookBackDistance = math.min(MathUtil.vector2Length(x - self.parent.rowStartTranslation[1], z - self.parent.rowStartTranslation[3]) * 0.5, 5)
	end

	for i = #self.maxTurningSizeBoxes, 1, -1 do
		self.maxTurningSizeBoxes[i] = nil
	end

	local collisionHitLeft = false
	local collisionHitRight = false

	if (self.turnLeft == nil or self.turnLeft == false) and allowLeft then
		local turnLeft = true

		self:updateTurningSizeBox(self.leftBox, turnLeft, turnData, math.max(0, distanceToTurn))

		local box = self.leftBox
		box.center[3] = box.center[3] - boxLookBackDistance
		box.size[3] = box.size[3] + boxLookBackDistance

		if not self:validateCollisionBox(box) then
			self.vehicle:stopCurrentAIJob(AIMessageErrorUnknown.new())
			self:debugPrint("Stopping AIVehicle - collision box invalid")

			return distanceToTurn
		end

		collisionHitLeft = self:getIsBoxColliding(box)

		table.insert(self.maxTurningSizeBoxes, box)

		if collisionHitLeft and self.collisionEndPosLeft == nil then
			self.collisionEndPosLeft = {
				localToWorld(self.vehicleDirectionNode, 0, 0, box.size[3])
			}
		end
	end

	if (self.turnLeft == nil or self.turnLeft == true) and allowRight then
		local turnLeft = false

		self:updateTurningSizeBox(self.rightBox, turnLeft, turnData, math.max(0, distanceToTurn))

		local box = self.rightBox
		box.center[3] = box.center[3] - boxLookBackDistance
		box.size[3] = box.size[3] + boxLookBackDistance

		if not self:validateCollisionBox(box) then
			self.vehicle:stopCurrentAIJob(AIMessageErrorUnknown.new())
			self:debugPrint("Stopping AIVehicle - collision box invalid 2")

			return distanceToTurn
		end

		collisionHitRight = self:getIsBoxColliding(box)

		table.insert(self.maxTurningSizeBoxes, box)

		if collisionHitRight and self.collisionEndPosRight == nil then
			self.collisionEndPosRight = {
				localToWorld(self.vehicleDirectionNode, 0, 0, box.size[3])
			}
		end
	end

	self:evaluateCollisionHits(vX, vY, vZ, collisionHitLeft, collisionHitRight, turnData)

	return distanceToTurn
end

function AITurnStrategy:getIsBoxColliding(box)
	box.x, box.y, box.z = localToWorld(self.vehicleDirectionNode, box.center[1], box.center[2], box.center[3])
	box.zx, box.zy, box.zz = localDirectionToWorld(self.vehicleDirectionNode, 0, 0, 1)
	box.xx, box.xy, box.xz = localDirectionToWorld(self.vehicleDirectionNode, 1, 0, 0)
	box.ry = math.atan2(box.zx, box.zz)
	box.color = AITurnStrategy.COLLISION_BOX_COLOR_OK
	self.collisionHit = false

	overlapBox(box.x, box.y, box.z, 0, box.ry, 0, box.size[1], box.size[2], box.size[3], "collisionTestCallback", self, CollisionFlag.AI_BLOCKING, true, true, true)

	if self.collisionHit then
		box.color = AITurnStrategy.COLLISION_BOX_COLOR_HIT

		return true
	end

	local x1, _, z1 = localToWorld(self.vehicleDirectionNode, box.center[1] + box.size[1], 0, box.center[3] + box.size[3])
	local x2, _, z2 = localToWorld(self.vehicleDirectionNode, box.center[1] + box.size[1], 0, box.center[3] - box.size[3])
	local t1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1)
	local t2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2)

	raycastClosest(x1, t1, z1, 0, -1, 0, "onWaterRaycastCallback", 200, self, CollisionFlag.WATER, false, false, true)
	raycastClosest(x2, t2, z2, 0, -1, 0, "onWaterRaycastCallback2", 200, self, CollisionFlag.WATER, false, false, true)

	local waterY1 = self.lastWaterY1
	local waterY2 = self.lastWaterY2
	self.lastWaterY1 = -2000
	self.lastWaterY2 = -2000

	if t1 < waterY1 or t2 < waterY2 then
		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			self.vehicle:addAIDebugText(string.format(" hit water: b%.1f f%.1f w%.1f", t1, t2, waterY1))
		end

		box.color = AITurnStrategy.COLLISION_BOX_COLOR_HIT

		return true
	end

	local testLength = 3
	local angle1 = self:getCollisionBoxSlope(self.vehicleDirectionNode, box.center[1] + box.size[1], 0, box.center[3] + box.size[3], box.center[1] + box.size[1], 0, box.center[3] + box.size[3] - testLength)
	local angle2 = self:getCollisionBoxSlope(self.vehicleDirectionNode, box.center[1] - box.size[1], 0, box.center[3] + box.size[3], box.center[1] - box.size[1], 0, box.center[3] + box.size[3] - testLength)
	local angle3 = self:getCollisionBoxSlope(self.vehicleDirectionNode, 0, 0, box.center[3] + box.size[3], 0, 0, box.center[3] + box.size[3] - testLength)
	local angle4 = self:getCollisionBoxSlope(self.vehicleDirectionNode, box.center[1] + box.size[1] - testLength, 0, box.center[3] + box.size[3], box.center[1] + box.size[1], 0, box.center[3] + box.size[3])
	local angle5 = self:getCollisionBoxSlope(self.vehicleDirectionNode, box.center[1] - box.size[1] + testLength, 0, box.center[3] + box.size[3], box.center[1] - box.size[1], 0, box.center[3] + box.size[3])
	local angleBetween = math.max(angle1, angle2, angle3, angle4, angle5)

	if AITurnStrategy.SLOPE_DETECTION_THRESHOLD < angleBetween then
		box.color = AITurnStrategy.COLLISION_BOX_COLOR_HIT

		return true
	end

	x1, _, z1 = localToWorld(self.vehicleDirectionNode, box.center[1] + box.size[1], 0, box.center[3] + box.size[3])
	x2, _, z2 = localToWorld(self.vehicleDirectionNode, box.center[1] - box.size[1], 0, box.center[3] + box.size[3])
	local length = MathUtil.vector2Length(x1 - x2, z1 - z2)
	local steps = math.floor(length / 3)

	for i = 0, steps do
		local alpha = math.min(1 / (steps + 1) * (i + math.random()), 1)
		local x = MathUtil.lerp(x1, x2, alpha)
		local z = MathUtil.lerp(z1, z2, alpha)
		local _, densityHeight = DensityMapHeightUtil.getHeightAtWorldPos(x, 0, z)

		if AITurnStrategy.DENSITY_HEIGHT_THRESHOLD <= densityHeight then
			box.color = AITurnStrategy.COLLISION_BOX_COLOR_HIT

			return true
		end
	end

	return false
end

function AITurnStrategy:onWaterRaycastCallback(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if hitObjectId ~= 0 then
		self.lastWaterY1 = y
	end
end

function AITurnStrategy:onWaterRaycastCallback2(hitObjectId, x, y, z, distance, nx, ny, nz, subShapeIndex, shapeId, isLast)
	if hitObjectId ~= 0 then
		self.lastWaterY2 = y
	end
end

function AITurnStrategy:getCollisionBoxSlope(rootNode, x1, y1, z1, x2, y2, z2)
	x1, y1, z1 = localToWorld(self.vehicleDirectionNode, x1, y1, z1)
	x2, y2, z2 = localToWorld(self.vehicleDirectionNode, x2, y2, z2)
	local terrain1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 0, z1)
	local terrain2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 0, z2)
	local length = MathUtil.vector3Length(x1 - x2, y1 - y2, z1 - z2)
	local angleBetween = math.atan(math.abs(terrain1 - terrain2) / length)

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		self.vehicle:addAIDebugLine({
			x1,
			terrain1 + 1,
			z1
		}, {
			x2,
			terrain2 + 1,
			z2
		}, {
			1,
			0,
			0
		})
		Utils.renderTextAtWorldPosition((x1 + x2) / 2, (terrain1 + 1 + terrain2 + 1) / 2, (z1 + z2) / 2, string.format("angle: %.1f", math.deg(angleBetween)), getCorrectTextSize(0.012), 0)
	end

	return angleBetween
end

function AITurnStrategy:validateCollisionBox(box)
	for i = 1, 3 do
		if box.center[i] ~= box.center[i] or box.rotation[i] ~= box.rotation[i] or box.size[i] ~= box.size[i] then
			return false
		end
	end

	return true
end

function AITurnStrategy:clearTurnSegments()
	for i = #self.turnSegments, 1, -1 do
		local segment = table.remove(self.turnSegments, i)

		if segment ~= nil and segment.o ~= nil then
			delete(segment.o)
		end
	end
end

function AITurnStrategy:startTurn(driveStrategyStraight)
	local turnData = driveStrategyStraight.turnData
	self.isTurning = true
	self.requestToEndTurn = false

	self:clearTurnSegments()

	self.turnSegmentsTotalLength = 0
	self.activeTurnSegmentIndex = 1
	local allowLeft = self.usesExtraStraight == turnData.useExtraStraightLeft and driveStrategyStraight.gabAllowTurnLeft
	local allowRight = self.usesExtraStraight == turnData.useExtraStraightRight and driveStrategyStraight.gabAllowTurnRight

	if not allowLeft and not allowRight then
		self:debugPrint("Stopping AI - not allowed in both directions (gabAllowTurnLeft: %s, gabAllowTurnRight: %s)", driveStrategyStraight.gabAllowTurnLeft, driveStrategyStraight.gabAllowTurnRight)

		return false
	end

	AIVehicleUtil.updateInvertLeftRightMarkers(self.vehicle, self.vehicle)

	for _, implement in pairs(self.vehicle:getAttachedAIImplements()) do
		AIVehicleUtil.updateInvertLeftRightMarkers(self.vehicle, implement.object)
	end

	local leftAreaPercentage, rightAreaPercentage = AIVehicleUtil.getValidityOfTurnDirections(self.vehicle, turnData)

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		log(" --(I)--> self.turnLeft:", self.turnLeft, "leftAreaPercentage:", leftAreaPercentage, "rightAreaPercentage:", rightAreaPercentage)
	end

	if driveStrategyStraight.corridorDistance ~= nil then
		self.corridorPositionOffset = -driveStrategyStraight.corridorDistance
	end

	local function checkForLastValidPosition(vehicleNode, turnLeft, threshold)
		if turnLeft and not allowLeft then
			return false
		end

		if not turnLeft and not allowRight then
			return false
		end

		local position = driveStrategyStraight.lastValidTurnLeftPosition

		if not turnLeft then
			position = driveStrategyStraight.lastValidTurnRightPosition
		end

		if position[1] ~= 0 and position[2] ~= 0 and position[3] ~= 0 then
			local x, y, z = unpack(driveStrategyStraight.lastValidTurnCheckPosition)
			local distance = MathUtil.vector3Length(position[1] - x, position[2] - y, position[3] - z)

			if threshold < distance then
				self.lastValidTurnPositionOffset = -distance

				return true
			end
		end
	end

	if self.turnLeft == nil then
		if leftAreaPercentage == rightAreaPercentage then
			if self.vehicle:getAIFieldWorkerLastTurnDirection() then
				rightAreaPercentage = rightAreaPercentage + 0.01
			else
				leftAreaPercentage = leftAreaPercentage + 0.01
			end
		end

		local forcePreferLeft = self.collisionEndPosLeft == nil and self.collisionEndPosRight ~= nil
		local forcePreferRight = self.collisionEndPosRight == nil and self.collisionEndPosLeft ~= nil and allowRight and AIVehicleUtil.VALID_AREA_THRESHOLD < rightAreaPercentage
		local preferLeft = (rightAreaPercentage < leftAreaPercentage or forcePreferLeft) and not forcePreferRight

		if allowLeft and AIVehicleUtil.VALID_AREA_THRESHOLD < leftAreaPercentage and (preferLeft or not allowRight) then
			self.turnLeft = true

			checkForLastValidPosition(self.vehicleDirectionNode, true, 5)
		elseif allowRight and AIVehicleUtil.VALID_AREA_THRESHOLD < rightAreaPercentage then
			self.turnLeft = false

			checkForLastValidPosition(self.vehicleDirectionNode, false, 5)
		elseif not checkForLastValidPosition(self.vehicleDirectionNode, true, 5) then
			if not checkForLastValidPosition(self.vehicleDirectionNode, false, 5) then
				self:debugPrint("Stopping AIVehicle - no valid ground (I)")

				return false
			else
				self.turnLeft = false
			end
		else
			self.turnLeft = true
		end
	else
		self.turnLeft = not self.turnLeft

		if self.turnLeft then
			if not allowLeft or leftAreaPercentage < AIVehicleUtil.VALID_AREA_THRESHOLD then
				if not checkForLastValidPosition(self.vehicleDirectionNode, true, 5) then
					self:debugPrint("Stopping AI - No ground left (%.3f)", leftAreaPercentage)

					return false
				end
			else
				checkForLastValidPosition(self.vehicleDirectionNode, true, 5)
			end
		elseif not allowRight or rightAreaPercentage < AIVehicleUtil.VALID_AREA_THRESHOLD then
			if not checkForLastValidPosition(self.vehicleDirectionNode, false, 5) then
				self:debugPrint("Stopping AI - No ground right (%.3f)", rightAreaPercentage)

				return false
			end
		else
			checkForLastValidPosition(self.vehicleDirectionNode, false, 5)
		end
	end

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		log(" --(II)--> self.turnLeft:", self.turnLeft, "leftAreaPercentage:", leftAreaPercentage, "rightAreaPercentage:", rightAreaPercentage)
	end

	driveStrategyStraight.turnLeft = not self.turnLeft

	driveStrategyStraight:updateTurnData()

	driveStrategyStraight.turnLeft = nil
	self.vehicle.aiDriveDirection[2] = -self.vehicle.aiDriveDirection[2]
	self.vehicle.aiDriveDirection[1] = -self.vehicle.aiDriveDirection[1]
	local sideOffset = nil

	if self.turnLeft then
		sideOffset = turnData.sideOffsetLeft
	else
		sideOffset = turnData.sideOffsetRight
	end

	local x = self.vehicle.aiDriveTarget[1]
	local z = self.vehicle.aiDriveTarget[2]
	local dirX = self.vehicle.aiDriveDirection[1]
	local dirZ = self.vehicle.aiDriveDirection[2]
	local sideDistance = 2 * sideOffset
	local sideDirX = -dirZ
	local sideDirY = dirX
	z = z + sideDirY * sideDistance
	x = x + sideDirX * sideDistance
	self.vehicle.aiDriveTarget[2] = z
	self.vehicle.aiDriveTarget[1] = x

	self.vehicle:aiFieldWorkerStartTurn(self.turnLeft, self)

	return true
end

function AITurnStrategy:getZOffsetForTurn(box0)
	local box = {
		name = "ZoffsetForTurn",
		center = {
			box0.center[1],
			box0.center[2],
			box0.center[3]
		},
		size = {
			box0.size[1],
			box0.size[2],
			box0.size[3]
		}
	}
	local length = math.max(self.distanceToCollision + 2 * box0.size[3], 20)
	box.center[3] = length / 2
	box.size[3] = length / 2
	box.vFront = {
		localDirectionToWorld(self.vehicleDirectionNode, 0, 0, 1)
	}
	box.vLeft = {
		localDirectionToWorld(self.vehicleDirectionNode, 1, 0, 0)
	}
	local zOffset = self.distanceToCollision
	local i = 0

	while box.size[3] > 0.5 do
		self.collisionHit = self:getIsBoxColliding(box)

		if self.collisionHit then
			box.center[3] = box.center[3] - box.size[3] / 2
		else
			zOffset = box.center[3] + box.size[3]
			box.center[3] = box.center[3] + 3 * box.size[3] / 2
		end

		box.size[3] = box.size[3] / 2
		i = i + 1
	end

	return zOffset
end

function AITurnStrategy:startTurnFinalization()
	for _, segment in pairs(self.turnSegments) do
		if segment.startPoint ~= nil then
			segment.startPoint[2] = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, segment.startPoint[1], 0, segment.startPoint[3])
			segment.endPoint[2] = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, segment.endPoint[1], 0, segment.endPoint[3])
		elseif segment.o ~= nil then
			local x, y, z = getWorldTranslation(segment.o)
			y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, y, z)

			setTranslation(segment.o, x, y, z)
		end
	end

	for _, segment in pairs(self.turnSegments) do
		if segment.startPoint ~= nil then
			segment.length = MathUtil.vector3Length(segment.endPoint[1] - segment.startPoint[1], segment.endPoint[2] - segment.startPoint[2], segment.endPoint[3] - segment.startPoint[3])
			self.turnSegmentsTotalLength = self.turnSegmentsTotalLength + segment.length
		else
			segment.length = math.rad(segment.endAngle - segment.startAngle) * segment.radius
			self.turnSegmentsTotalLength = self.turnSegmentsTotalLength + segment.length
		end
	end
end

function AITurnStrategy:onEndTurn(turnLeft)
	if #self.turnSegments > 0 then
		self.vehicle:aiFieldWorkerEndTurn(self.turnLeft)
	end

	self.collisionDetected = false
	self.collisionEndPosLeft = nil
	self.collisionEndPosRight = nil
	self.collisionDetectedPosX = nil
	self.turnLeft = turnLeft
	self.maxTurningSizeBoxes = {}
	self.maxTurningSizeBoxes2 = {}

	self:clearTurnSegments()
	AIVehicleUtil.updateInvertLeftRightMarkers(self.vehicle, self.vehicle)

	for _, implement in pairs(self.vehicle:getAttachedAIImplements()) do
		AIVehicleUtil.updateInvertLeftRightMarkers(self.vehicle, implement.object)
	end
end

function AITurnStrategy.getAngleInSegment(node, segment, ox, oy, oz)
	oz = oz or 0
	oy = oy or 0
	ox = ox or 0
	local vX, _, vZ = localToLocal(node, segment.o, ox, oy, oz)

	return math.atan2(vZ, vX)
end

function AITurnStrategy.drawTurnSegments(segments)
	for i, segment in pairs(segments) do
		if segment.isCurve == true then
			local oX, oY, oZ = localToWorld(segment.o, 0, 2, 0)
			local xX, xY, xZ = localToWorld(segment.o, 2, 2, 0)
			local yX, yY, yZ = localToWorld(segment.o, 0, 4, 0)
			local zX, zY, zZ = localToWorld(segment.o, 0, 2, 2)

			drawDebugLine(oX, oY, oZ, 1, 0, 0, xX, xY, xZ, 1, 0, 0)
			drawDebugLine(oX, oY, oZ, 0, 1, 0, yX, yY, yZ, 0, 1, 0)
			drawDebugLine(oX, oY, oZ, 0, 0, 1, zX, zY, zZ, 0, 0, 1)
			Utils.renderTextAtWorldPosition(yX, yY, yZ, tostring(i), 0.02, 0)

			local ts = 20

			for i = 0, ts - 1 do
				local x1 = segment.radius * math.cos(segment.startAngle + i * (segment.endAngle - segment.startAngle) / ts)
				local z1 = segment.radius * math.sin(segment.startAngle + i * (segment.endAngle - segment.startAngle) / ts)
				local x2 = segment.radius * math.cos(segment.startAngle + (i + 1) * (segment.endAngle - segment.startAngle) / ts)
				local z2 = segment.radius * math.sin(segment.startAngle + (i + 1) * (segment.endAngle - segment.startAngle) / ts)
				local w1X, w1Y, w1Z = localToWorld(segment.o, x1, 0, z1)
				local w2X, w2Y, w2Z = localToWorld(segment.o, x2, 0, z2)
				local w1Y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, w1X, w1Y, w1Z) + 1
				local w2Y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, w2X, w2Y, w2Z) + 1

				drawDebugLine(w1X, w1Y, w1Z, (ts - i) / ts, i / ts, 0, w2X, w2Y, w2Z, (ts - i - 1) / ts, (i + 1) / ts, 0)
			end
		else
			local sY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, unpack(segment.startPoint)) + 1
			local eY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, unpack(segment.endPoint)) + 1

			drawDebugLine(segment.startPoint[1], sY, segment.startPoint[3], 1, 0, 0, segment.endPoint[1], eY, segment.endPoint[3], 0, 1, 0)
			drawDebugLine(segment.startPoint[1], sY, segment.startPoint[3], 1, 1, 1, segment.startPoint[1], sY + 2, segment.startPoint[3], 1, 1, 1)
			drawDebugLine(segment.endPoint[1], sY, segment.endPoint[3], 1, 1, 1, segment.endPoint[1], sY + 2, segment.endPoint[3], 1, 1, 1)
			Utils.renderTextAtWorldPosition((segment.startPoint[1] + segment.endPoint[1]) / 2, (sY + eY) / 2, (segment.startPoint[3] + segment.endPoint[3]) / 2, tostring(i), 0.02, 0)
		end
	end
end

function AITurnStrategy:collisionTestCallback(transformId)
	local object = g_currentMission:getNodeObject(transformId)

	if object == nil or object:isa(Placeable) then
		self.collisionHit = true

		return false
	end
end

function AITurnStrategy:evaluateCollisionHits(vX, vY, vZ, collisionHitLeft, collisionHitRight, turnData)
	if not collisionHitLeft and self.collisionEndPosLeft ~= nil then
		local _, _, z = worldToLocal(self.vehicleDirectionNode, self.collisionEndPosLeft[1], self.collisionEndPosLeft[2], self.collisionEndPosLeft[3])

		if z < -1 then
			self.collisionEndPosLeft = nil
			self.collisionDetected = false
			self.collisionDetectedPosX = nil
		end
	end

	if not collisionHitRight and self.collisionEndPosRight ~= nil then
		local _, _, z = worldToLocal(self.vehicleDirectionNode, self.collisionEndPosRight[1], self.collisionEndPosRight[2], self.collisionEndPosRight[3])

		if z < -1 then
			self.collisionEndPosRight = nil
			self.collisionDetected = false
			self.collisionDetectedPosX = nil
		end
	end

	if self.turnLeft == nil then
		if collisionHitLeft or collisionHitRight then
			local allowLeft = self.usesExtraStraight == turnData.useExtraStraightLeft
			local allowRight = self.usesExtraStraight == turnData.useExtraStraightRight

			if collisionHitLeft and collisionHitRight then
				self.collisionDetected = true
			else
				local leftAreaPercentage, rightAreaPercentage = AIVehicleUtil.getValidityOfTurnDirections(self.vehicle, turnData)
				allowRight = allowRight and leftAreaPercentage <= rightAreaPercentage
				allowLeft = allowLeft and rightAreaPercentage <= leftAreaPercentage

				if collisionHitLeft and not allowRight then
					self.collisionDetected = true
					self.turnLeft = false
				elseif collisionHitRight and not allowLeft then
					self.collisionDetected = true
					self.turnLeft = true
				else
					self.turnLeft = collisionHitLeft
				end
			end
		end
	elseif self.turnLeft then
		if collisionHitRight then
			self.collisionDetected = true
		end
	elseif collisionHitLeft then
		self.collisionDetected = true
	end

	if self.collisionDetected and self.collisionDetectedPosX == nil then
		self.collisionDetectedPosZ = vZ
		self.collisionDetectedPosY = vY
		self.collisionDetectedPosX = vX
	end
end

function AITurnStrategy:checkCollisionInFront(turnData, lookAheadDistance)
	lookAheadDistance = lookAheadDistance or 5
	local maxX = turnData.sideOffsetLeft
	local minX = turnData.sideOffsetRight
	local maxZ = math.max(4, turnData.toolOverhang.front.zt)
	local box = {
		name = "checkCollisionInFront",
		center = {
			maxX - (maxX - minX) / 2,
			0,
			maxZ / 2 + lookAheadDistance / 2
		},
		rotation = {
			0,
			0,
			0
		},
		size = {
			(maxX - minX) / 2,
			5,
			maxZ / 2 + lookAheadDistance / 2
		}
	}
	self.collisionHit = self:getIsBoxColliding(box)

	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		table.insert(self.maxTurningSizeBoxes, box)
	end

	return self.collisionHit
end

function AITurnStrategy:adjustHeightOfTurningSizeBox(box)
	local yMax = -math.huge
	local yMin = math.huge

	for i = 1, self.numHeightChecks do
		local check = self.heightChecks[i]
		local x, _, z = localToWorld(self.vehicleDirectionNode, box.center[1] + box.size[1] * check[1], 0, box.center[3] + box.size[3] * check[2])
		local h = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
		yMax = math.max(yMax, h)
		yMin = math.min(yMin, h)
	end

	local height = math.max(6, yMax - yMin + 2)
	box.size[2] = height
	box.center[2] = 0
end

function AITurnStrategy:getNoFullCoverageZOffset()
	local offset = 0

	if AIVehicleUtil.getAttachedImplementsBlockTurnBackward(self.vehicle) then
		return 0
	end

	local attachedAIImplements = self.vehicle:getAttachedAIImplements()

	for _, implement in pairs(attachedAIImplements) do
		if implement.object:getAIHasNoFullCoverageArea() then
			local leftMarker, _, backMarker = implement.object:getAIMarkers()
			local _, _, markerZOffset = localToLocal(backMarker, leftMarker, 0, 0, 0)
			offset = offset + markerZOffset
		end
	end

	offset = offset + self.corridorPositionOffset
	offset = offset + self.lastValidTurnPositionOffset

	return offset
end

function AITurnStrategy:getVehicleToWorld(x, y, z, returnTable)
	x, y, z = localToWorld(self.vehicleDirectionNode, x, y, z + self:getNoFullCoverageZOffset())

	if returnTable then
		return {
			x,
			y,
			z
		}
	end

	return x, y, z
end

function AITurnStrategy:addNoFullCoverageSegment(turnSegments)
	local offset = self:getNoFullCoverageZOffset()

	if offset ~= 0 then
		local segment = {
			isCurve = false,
			moveForward = false,
			slowDown = true,
			startPoint = self:getVehicleToWorld(0, 0, -offset, true),
			endPoint = self:getVehicleToWorld(0, 0, 0, true)
		}

		table.insert(turnSegments, segment)
	end
end

function AITurnStrategy:debugPrint(text, ...)
	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		print(string.format("AI DEBUG: %s", string.format(text, ...)))
	end
end

function AITurnStrategy:getTurnRadius(radius, sideOffset)
	if math.abs(math.abs(sideOffset) - radius) < 0.25 then
		radius = math.abs(sideOffset)
	end

	return radius
end

function AITurnStrategy:skipTurnSegment()
	if self.activeTurnSegmentIndex < #self.turnSegments then
		self.activeTurnSegmentIndex = self.activeTurnSegmentIndex + 1
	else
		self.requestToEndTurn = true
	end
end

function AITurnStrategy:getActiveTurnSegmentByNode(referenceNode, originX, originY, originZ)
	local activeSegmentIndex = nil
	local activeSegmentProgress = 0
	local minSegmentDistance = math.huge
	local activeSegment = self.turnSegments[self.activeTurnSegmentIndex]

	for i = self.activeTurnSegmentIndex, #self.turnSegments do
		local segment = self.turnSegments[i]

		if segment.moveForward and activeSegment.moveForward then
			if self.activeTurnSegmentIndex <= i and i <= self.activeTurnSegmentIndex + 2 then
				if segment.isCurve then
					local curAngle = AITurnStrategy.getAngleInSegment(referenceNode, segment, worldToLocal(referenceNode, originX, originY, originZ))
					local x1, _, z1 = localToWorld(segment.o, segment.radius * math.cos(curAngle), 0, segment.radius * math.sin(curAngle))
					local distanceToSegment = MathUtil.vector2Length(x1 - originX, z1 - originZ)
					local prevAngle = curAngle - 2 * math.pi
					local nextAngle = curAngle + 2 * math.pi
					local outOfBoundsCur = MathUtil.getIsOutOfBounds(curAngle, segment.startAngle, segment.endAngle)
					local outOfBoundsPrev = MathUtil.getIsOutOfBounds(prevAngle, segment.startAngle, segment.endAngle)
					local outOfBoundsNext = MathUtil.getIsOutOfBounds(nextAngle, segment.startAngle, segment.endAngle)

					if not outOfBoundsCur or not outOfBoundsPrev or not outOfBoundsNext then
						if distanceToSegment < minSegmentDistance then
							activeSegmentIndex = i
							minSegmentDistance = distanceToSegment

							if not outOfBoundsPrev then
								curAngle = prevAngle
							end

							if not outOfBoundsNext then
								curAngle = nextAngle
							end

							activeSegmentProgress = (curAngle - segment.startAngle) / (segment.endAngle - segment.startAngle)
						end
					else
						x1, _, z1 = localToWorld(segment.o, segment.radius * math.cos(segment.startAngle), 0, segment.radius * math.sin(segment.startAngle))
						distanceToSegment = MathUtil.vector2Length(x1 - originX, z1 - originZ)

						if distanceToSegment < minSegmentDistance then
							activeSegmentIndex = i
							minSegmentDistance = distanceToSegment
							activeSegmentProgress = 0
						end

						x1, _, z1 = localToWorld(segment.o, segment.radius * math.cos(segment.endAngle), 0, segment.radius * math.sin(segment.endAngle))
						distanceToSegment = MathUtil.vector2Length(x1 - originX, z1 - originZ)

						if distanceToSegment < minSegmentDistance then
							activeSegmentIndex = i
							minSegmentDistance = distanceToSegment
							activeSegmentProgress = 1
						end
					end
				else
					local x1, _, z1, pos = MathUtil.getClosestPointOnLineSegment(segment.startPoint[1], 0, segment.startPoint[3], segment.endPoint[1], 0, segment.endPoint[3], originX, 0, originZ)
					local distanceToSegment = MathUtil.vector2Length(x1 - originX, z1 - originZ)

					if distanceToSegment < minSegmentDistance then
						activeSegmentIndex = i
						minSegmentDistance = distanceToSegment
						activeSegmentProgress = pos
					end
				end
			end
		else
			break
		end
	end

	return activeSegmentIndex, activeSegmentProgress
end

function AITurnStrategy:createPointsForSegment(segmentIndex, segmentProgress, positions, posIndex, pointToPointDistance, remainingDistance, remainingPoints)
	local segment = self.turnSegments[segmentIndex]
	local curAngle = 0

	if segment.isCurve then
		curAngle = segmentProgress * (segment.endAngle - segment.startAngle) + segment.startAngle
		local segmentCircleLength = 2 * math.pi * segment.radius

		while remainingPoints > 0 and remainingDistance > 0 do
			local nextAngle = curAngle + pointToPointDistance / segmentCircleLength * 2 * math.pi * MathUtil.sign(segment.endAngle - curAngle)

			if segment.startAngle < segment.endAngle then
				if segment.endAngle <= nextAngle or nextAngle <= segment.startAngle then
					break
				end
			elseif nextAngle <= segment.endAngle or segment.startAngle <= nextAngle then
				break
			end

			local x1 = segment.radius * math.cos(nextAngle)
			local z1 = segment.radius * math.sin(nextAngle)
			positions[posIndex + 1], positions[posIndex + 2], positions[posIndex + 3] = localToWorld(segment.o, x1, 0, z1)
			positions[posIndex + 2] = positions[2]
			posIndex = posIndex + 3
			remainingPoints = remainingPoints - 1
			remainingDistance = remainingDistance - pointToPointDistance
			curAngle = nextAngle
		end
	else
		local segmentLength = MathUtil.vector2Length(segment.startPoint[1] - segment.endPoint[1], segment.startPoint[3] - segment.endPoint[3])
		local curAlpha = segmentProgress

		while remainingPoints > 0 and remainingDistance > 0 do
			local nextAlpha = curAlpha + pointToPointDistance / segmentLength

			if nextAlpha < 0 or nextAlpha > 1 then
				break
			end

			local x1, _, z1 = MathUtil.lerp3(segment.startPoint[1], segment.startPoint[2], segment.startPoint[3], segment.endPoint[1], segment.endPoint[2], segment.endPoint[3], nextAlpha)
			positions[posIndex + 3] = z1
			positions[posIndex + 2] = positions[2]
			positions[posIndex + 1] = x1
			posIndex = posIndex + 3
			remainingPoints = remainingPoints - 1
			remainingDistance = remainingDistance - pointToPointDistance
			curAlpha = nextAlpha
		end
	end

	if remainingDistance > 0 then
		segmentIndex = segmentIndex + 1

		if self.turnSegments[segmentIndex] ~= nil and self.turnSegments[segmentIndex].moveForward then
			self:createPointsForSegment(segmentIndex, 0, positions, posIndex, pointToPointDistance, remainingDistance, remainingPoints)
		elseif posIndex >= 3 then
			local dirX, dirY, dirZ = nil

			if segment.isCurve then
				local dir = MathUtil.sign(segment.endAngle - segment.startAngle)
				local preAngle = curAngle + math.rad(10) * -dir
				local nextAngle = curAngle + math.rad(10) * dir
				local x1, y1, z1 = localToWorld(segment.o, segment.radius * math.cos(preAngle), 0, segment.radius * math.sin(preAngle))
				local x2, y2, z2 = localToWorld(segment.o, segment.radius * math.cos(nextAngle), 0, segment.radius * math.sin(nextAngle))
				dirX, dirY, dirZ = MathUtil.vector3Normalize(x1 - x2, y1 - y2, z1 - z2)
			else
				dirX, dirY, dirZ = MathUtil.vector3Normalize(segment.startPoint[1] - segment.endPoint[1], 0, segment.startPoint[3] - segment.endPoint[3])
			end

			local lx1 = positions[posIndex - 2]
			local ly1 = positions[posIndex - 1]
			local lz1 = positions[posIndex - 0]
			local distance = 0

			for i = 0, remainingPoints - 1 do
				distance = distance + pointToPointDistance
				positions[posIndex + 3] = lz1 - dirZ * distance
				positions[posIndex + 2] = ly1 - dirY * distance
				positions[posIndex + 1] = lx1 - dirX * distance
				posIndex = posIndex + 3
			end
		end
	end
end

function AITurnStrategy:calculatePathPrediction(positions, referenceNode, originX, originY, originZ, posIndex, pointToPointDistance, remainingDistance, remainingPoints)
	local activeSegmentIndex, activeSegmentProgress = self:getActiveTurnSegmentByNode(referenceNode, originX, originY, originZ)

	if activeSegmentIndex ~= nil then
		self:createPointsForSegment(activeSegmentIndex, activeSegmentProgress, positions, posIndex, pointToPointDistance, remainingDistance, remainingPoints)
	end

	return activeSegmentIndex ~= nil
end
