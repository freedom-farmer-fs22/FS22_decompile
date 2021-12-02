AIVehicleUtil = {
	VALID_AREA_THRESHOLD = 0.03,
	AREA_OVERLAP = 0.26,
	driveToPoint = function (self, dt, acceleration, allowedToDrive, moveForwards, tX, tZ, maxSpeed, doNotSteer)
		if self.finishedFirstUpdate then
			if allowedToDrive then
				local tX_2 = tX * 0.5
				local tZ_2 = tZ * 0.5
				local d1X = tZ_2
				local d1Z = -tX_2

				if tX > 0 then
					d1Z = tX_2
					d1X = -tZ_2
				end

				local hit, _, f2 = MathUtil.getLineLineIntersection2D(tX_2, tZ_2, d1X, d1Z, 0, 0, tX, 0)

				if doNotSteer == nil or not doNotSteer then
					local rotTime = 0

					if hit and math.abs(f2) < 100000 then
						local radius = tX * f2
						rotTime = self:getSteeringRotTimeByCurvature(1 / radius)
					end

					local targetRotTime = nil

					if rotTime >= 0 then
						targetRotTime = math.min(rotTime, self.maxRotTime)
					else
						targetRotTime = math.max(rotTime, self.minRotTime)
					end

					if self.rotatedTime < targetRotTime then
						self.rotatedTime = math.min(self.rotatedTime + dt * self:getAISteeringSpeed(), targetRotTime)
					else
						self.rotatedTime = math.max(self.rotatedTime - dt * self:getAISteeringSpeed(), targetRotTime)
					end

					local steerDiff = targetRotTime - self.rotatedTime
					local fac = math.abs(steerDiff) / math.max(self.maxRotTime, -self.minRotTime)
					local speedReduction = 1 - math.pow(fac, 0.25)

					if maxSpeed * speedReduction < 1 then
						acceleration = 0
						speedReduction = 1 / maxSpeed
					end

					maxSpeed = maxSpeed * speedReduction
				end
			end

			self:getMotor():setSpeedLimit(math.min(maxSpeed, self:getCruiseControlSpeed()))

			if self:getCruiseControlState() ~= Drivable.CRUISECONTROL_STATE_ACTIVE then
				self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
			end

			if not allowedToDrive then
				acceleration = 0
			end

			if not moveForwards then
				acceleration = -acceleration
			end

			WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeedReal * self.movingDirection, acceleration, not allowedToDrive, true)
		end
	end,
	driveAlongCurvature = function (self, dt, curvature, maxSpeed, acceleration)
		local targetRotTime = self:getSteeringRotTimeByCurvature(curvature)
		self.rotatedTime = -targetRotTime

		if self.finishedFirstUpdate then
			local acc = acceleration

			if maxSpeed ~= nil and maxSpeed > 0 then
				self:getMotor():setSpeedLimit(maxSpeed)

				if self:getCruiseControlState() ~= Drivable.CRUISECONTROL_STATE_ACTIVE then
					self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
				end
			else
				acc = 0
			end

			WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeedReal * self.movingDirection, acc, maxSpeed > 0, true)
		end
	end,
	driveInDirection = function (self, dt, steeringAngleLimit, acceleration, slowAcceleration, slowAngleLimit, allowedToDrive, moveForwards, lx, lz, maxSpeed, slowDownFactor)
		local angle = 0

		if lx ~= nil and lz ~= nil then
			local dot = lz
			angle = math.deg(math.acos(dot))

			if angle < 0 then
				angle = angle + 180
			end

			local turnLeft = lx > 1e-05

			if not moveForwards then
				turnLeft = not turnLeft
			end

			local targetRotTime = nil

			if turnLeft then
				targetRotTime = self.maxRotTime * math.min(angle / steeringAngleLimit, 1)
			else
				targetRotTime = self.minRotTime * math.min(angle / steeringAngleLimit, 1)
			end

			if self.rotatedTime < targetRotTime then
				self.rotatedTime = math.min(self.rotatedTime + dt * self:getAISteeringSpeed(), targetRotTime)
			else
				self.rotatedTime = math.max(self.rotatedTime - dt * self:getAISteeringSpeed(), targetRotTime)
			end
		end

		if self.finishedFirstUpdate then
			local acc = acceleration

			if maxSpeed ~= nil and maxSpeed ~= 0 then
				if slowAngleLimit <= math.abs(angle) then
					maxSpeed = maxSpeed * slowDownFactor
				end

				self.motor:setSpeedLimit(maxSpeed)

				if self.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_ACTIVE then
					self:setCruiseControlState(Drivable.CRUISECONTROL_STATE_ACTIVE)
				end
			elseif slowAngleLimit <= math.abs(angle) then
				acc = slowAcceleration
			end

			if not allowedToDrive then
				acc = 0
			end

			if not moveForwards then
				acc = -acc
			end

			WheelsUtil.updateWheelsPhysics(self, dt, self.lastSpeedReal * self.movingDirection, acc, not allowedToDrive, true)
		end
	end,
	getDriveDirection = function (refNode, x, y, z)
		local lx, _, lz = worldToLocal(refNode, x, y, z)
		local length = MathUtil.vector2Length(lx, lz)

		if length > 1e-05 then
			length = 1 / length
			lx = lx * length
			lz = lz * length
		end

		return lx, lz
	end,
	getAverageDriveDirection = function (refNode, x, y, z, x2, y2, z2)
		local lx, _, lz = worldToLocal(refNode, (x + x2) * 0.5, (y + y2) * 0.5, (z + z2) * 0.5)
		local length = MathUtil.vector2Length(lx, lz)

		if length > 1e-05 then
			lx = lx / length
			lz = lz / length
		end

		return lx, lz, length
	end
}

function AIVehicleUtil.getAttachedImplementsAllowTurnBackward(vehicle)
	if vehicle.getAIAllowTurnBackward ~= nil and not vehicle:getAIAllowTurnBackward() then
		return false
	end

	if vehicle.getAttachedImplements ~= nil then
		for _, implement in pairs(vehicle:getAttachedImplements()) do
			local object = implement.object

			if object ~= nil then
				if object.getAIAllowTurnBackward ~= nil and not object:getAIAllowTurnBackward() then
					return false
				end

				if not AIVehicleUtil.getAttachedImplementsAllowTurnBackward(object) then
					return false
				end
			end
		end
	end

	return true
end

function AIVehicleUtil.getAttachedImplementsBlockTurnBackward(vehicle)
	if vehicle.getAIBlockTurnBackward ~= nil and vehicle:getAIBlockTurnBackward() then
		return true
	end

	if vehicle.getAttachedImplements ~= nil then
		for _, implement in pairs(vehicle:getAttachedImplements()) do
			local object = implement.object

			if object ~= nil then
				if object.getAIBlockTurnBackward ~= nil and object:getAIBlockTurnBackward() then
					return true
				end

				if AIVehicleUtil.getAttachedImplementsBlockTurnBackward(object) then
					return true
				end
			end
		end
	end

	return false
end

function AIVehicleUtil.getAttachedImplementsMaxTurnRadius(vehicle)
	local maxRadius = -1

	if vehicle.getAttachedImplements ~= nil then
		for _, implement in pairs(vehicle:getAttachedImplements()) do
			local object = implement.object

			if object ~= nil then
				if object.getAITurnRadiusLimitation ~= nil then
					local radius = object:getAITurnRadiusLimitation()

					if radius ~= nil and maxRadius < radius then
						maxRadius = radius
					end
				end

				local radius = AIVehicleUtil.getAttachedImplementsMaxTurnRadius(object)

				if maxRadius < radius then
					maxRadius = radius
				end
			end
		end
	end

	return maxRadius
end

function AIVehicleUtil.getAIToolReverserDirectionNode(vehicle)
	for _, implement in pairs(vehicle:getAttachedImplements()) do
		if implement.object ~= nil then
			local reverserNode = implement.object:getAIToolReverserDirectionNode()
			local attachedReverserNode = AIVehicleUtil.getAIToolReverserDirectionNode(implement.object)
			reverserNode = reverserNode or attachedReverserNode

			if reverserNode ~= nil then
				return reverserNode
			end
		end
	end
end

function AIVehicleUtil.getMaxToolRadius(implement)
	local radius = 0
	local _, rotationNode, wheels, rotLimitFactor = implement.object:getAITurnRadiusLimitation()
	local rootVehicle = implement.object.rootVehicle
	local retRadius = AIVehicleUtil.getAttachedImplementsMaxTurnRadius(rootVehicle)

	if retRadius ~= -1 then
		radius = retRadius
	end

	if rotationNode then
		local activeInputAttacherJoint = implement.object:getActiveInputAttacherJoint()
		local refNode = rotationNode

		for _, inputAttacherJoint in pairs(implement.object:getInputAttacherJoints()) do
			if refNode == inputAttacherJoint.node then
				refNode = activeInputAttacherJoint.node

				break
			end
		end

		local rx, _, rz = localToLocal(refNode, implement.object.components[1].node, 0, 0, 0)

		for _, wheel in pairs(wheels) do
			local nx, _, nz = localToLocal(wheel.repr, implement.object.components[1].node, 0, 0, 0)
			local x = nx - rx
			local z = nz - rz
			local cx = 0
			local cz = 0
			local rotMax = nil

			if refNode == activeInputAttacherJoint.node then
				local attacherVehicle = implement.object:getAttacherVehicle()
				local jointDesc = attacherVehicle:getAttacherJointDescFromObject(implement.object)
				rotMax = math.max(jointDesc.upperRotLimit[2], jointDesc.lowerRotLimit[2]) * activeInputAttacherJoint.lowerRotLimitScale[2]
			else
				for _, compJoint in pairs(implement.object.componentJoints) do
					if refNode == compJoint.jointNode then
						rotMax = compJoint.rotLimit[2]

						break
					end
				end
			end

			rotMax = rotMax * rotLimitFactor
			local x1 = x * math.cos(rotMax) - z * math.sin(rotMax)
			local z1 = x * math.sin(rotMax) + z * math.cos(rotMax)
			local dx = -z1
			local dz = x1

			if wheel.steeringAxleScale ~= 0 and wheel.steeringAxleRotMax ~= 0 then
				local tmpx = dx
				local tmpz = dz
				dx = tmpx * math.cos(wheel.steeringAxleRotMax) - tmpz * math.sin(wheel.steeringAxleRotMax)
				dz = tmpx * math.sin(wheel.steeringAxleRotMax) + tmpz * math.cos(wheel.steeringAxleRotMax)
			end

			local hit, f1, _ = MathUtil.getLineLineIntersection2D(cx, cz, 1, 0, x1, z1, dx, dz)

			if hit then
				radius = math.max(radius, math.abs(f1))
			end
		end
	end

	return radius
end

function AIVehicleUtil.updateInvertLeftRightMarkers(rootAttacherVehicle, vehicle)
	if vehicle.getAIMarkers ~= nil then
		local leftMarker, rightMarker, _ = vehicle:getAIMarkers()

		if leftMarker ~= nil and rightMarker ~= nil then
			local lX, _, _ = localToLocal(leftMarker, rootAttacherVehicle:getAIDirectionNode(), 0, 0, 0)
			local rX, _, _ = localToLocal(rightMarker, rootAttacherVehicle:getAIDirectionNode(), 0, 0, 0)

			if lX < rX then
				vehicle:setAIMarkersInverted()
			end
		end
	end
end

function AIVehicleUtil.getValidityOfTurnDirections(vehicle, turnData)
	local directionNode = vehicle:getAIDirectionNode()
	local attachedAIImplements = vehicle:getAttachedAIImplements()
	local checkFrontDistance = 5
	local leftAreaPercentage = 0
	local rightAreaPercentage = 0
	local minZ = math.huge
	local maxZ = -math.huge

	for _, implement in pairs(attachedAIImplements) do
		local leftMarker, rightMarker, backMarker = implement.object:getAIMarkers()
		local _, _, zl = localToLocal(leftMarker, directionNode, 0, 0, 0)
		local _, _, zr = localToLocal(rightMarker, directionNode, 0, 0, 0)
		local _, _, zb = localToLocal(backMarker, directionNode, 0, 0, 0)
		minZ = math.min(minZ, zl, zr, zb)
		maxZ = math.max(maxZ, zl, zr, zb)
	end

	local sideDistance = nil

	if turnData == nil then
		local minAreaWidth = math.huge

		for _, implement in pairs(attachedAIImplements) do
			local leftMarker, rightMarker, _ = implement.object:getAIMarkers()
			local lx, _, _ = localToLocal(leftMarker, directionNode, 0, 0, 0)
			local rx, _, _ = localToLocal(rightMarker, directionNode, 0, 0, 0)
			minAreaWidth = math.min(minAreaWidth, math.abs(lx - rx))
		end

		sideDistance = minAreaWidth
	else
		sideDistance = math.abs(turnData.sideOffsetRight - turnData.sideOffsetLeft)
	end

	local dx = vehicle.aiDriveDirection[1]
	local dz = vehicle.aiDriveDirection[2]
	local sx = -dz
	local sz = dx

	for _, implement in pairs(attachedAIImplements) do
		local leftMarker, rightMarker, _ = implement.object:getAIMarkers()
		local lx, ly, lz = localToLocal(leftMarker, directionNode, 0, 0, 0)
		local rx, ry, rz = localToLocal(rightMarker, directionNode, 0, 0, 0)
		local width = math.abs(lx - rx)
		local length = checkFrontDistance + maxZ - minZ + math.max(sideDistance * 1.3 + 2, checkFrontDistance)
		lx, _, lz = localToWorld(directionNode, lx, ly, maxZ + checkFrontDistance)
		rx, _, rz = localToWorld(directionNode, rx, ry, maxZ + checkFrontDistance)
		local lSX = lx
		local lSZ = lz
		local lWX = lSX - sx * width
		local lWZ = lSZ - sz * width
		local lHX = lSX - dx * length
		local lHZ = lSZ - dz * length
		local rSX = rx
		local rSZ = rz
		local rWX = rSX + sx * width
		local rWZ = rSZ + sz * width
		local rHX = rSX - dx * length
		local rHZ = rSZ - dz * length
		local lArea, lTotal = AIVehicleUtil.getAIAreaOfVehicle(implement.object, lSX, lSZ, lWX, lWZ, lHX, lHZ, false)
		local rArea, rTotal = AIVehicleUtil.getAIAreaOfVehicle(implement.object, rSX, rSZ, rWX, rWZ, rHX, rHZ, false)

		if lTotal > 0 then
			leftAreaPercentage = leftAreaPercentage + lArea / lTotal
		end

		if rTotal > 0 then
			rightAreaPercentage = rightAreaPercentage + rArea / rTotal
		end

		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			local lSY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, lSX, 0, lSZ) + 2
			local lWY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, lWX, 0, lWZ) + 2
			local lHY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, lHX, 0, lHZ) + 2
			local rSY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, rSX, 0, rSZ) + 2
			local rWY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, rWX, 0, rWZ) + 2
			local rHY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, rHX, 0, rHZ) + 2

			vehicle:addAIDebugLine({
				lSX,
				lSY,
				lSZ
			}, {
				lWX,
				lWY,
				lWZ
			}, {
				0.5,
				0.5,
				0.5
			})
			vehicle:addAIDebugLine({
				lSX,
				lSY,
				lSZ
			}, {
				lHX,
				lHY,
				lHZ
			}, {
				0.5,
				0.5,
				0.5
			})
			vehicle:addAIDebugLine({
				rSX,
				rSY,
				rSZ
			}, {
				rWX,
				rWY,
				rWZ
			}, {
				0.5,
				0.5,
				0.5
			})
			vehicle:addAIDebugLine({
				rSX,
				rSY,
				rSZ
			}, {
				rHX,
				rHY,
				rHZ
			}, {
				0.5,
				0.5,
				0.5
			})
		end
	end

	leftAreaPercentage = leftAreaPercentage / #attachedAIImplements
	rightAreaPercentage = rightAreaPercentage / #attachedAIImplements

	return leftAreaPercentage, rightAreaPercentage
end

function AIVehicleUtil.checkImplementListForValidGround(vehicle, lookAheadDist, lookAheadSize)
	local validGroundFound = false

	for _, implement in pairs(vehicle:getAttachedAIImplements()) do
		local leftMarker, rightMarker, _ = implement.object:getAIMarkers()
		local lX, _, lZ = getWorldTranslation(leftMarker)
		local rX, _, rZ = getWorldTranslation(rightMarker)
		lX = lX + vehicle.aiDriveDirection[1] * lookAheadDist
		lZ = lZ + vehicle.aiDriveDirection[2] * lookAheadDist
		rX = rX + vehicle.aiDriveDirection[1] * lookAheadDist
		rZ = rZ + vehicle.aiDriveDirection[2] * lookAheadDist
		local hX = lX + vehicle.aiDriveDirection[1] * lookAheadSize
		local hZ = lZ + vehicle.aiDriveDirection[2] * lookAheadSize
		local area, areaTotal = AIVehicleUtil.getAIAreaOfVehicle(implement.object, lX, lZ, rX, rZ, hX, hZ)

		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			vehicle:addAIDebugText(string.format("area=%.1f areaTotal=%.1f", area, areaTotal))

			local lY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, lX, 0, lZ) + 2
			local rY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, rX, 0, rZ) + 2
			local hY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, hX, 0, hZ) + 2

			vehicle:addAIDebugLine({
				lX,
				lY,
				lZ
			}, {
				rX,
				rY,
				rZ
			}, {
				1,
				0,
				0
			})
			vehicle:addAIDebugLine({
				lX,
				lY,
				lZ
			}, {
				hX,
				hY,
				hZ
			}, {
				1,
				0,
				0
			})
		end

		validGroundFound = validGroundFound or area > 0
	end

	return validGroundFound
end

function AIVehicleUtil.getAreaDimensions(directionX, directionZ, leftNode, rightNode, xOffset, zOffset, areaSize, invertXOffset)
	local xOffsetLeft = xOffset
	local xOffsetRight = xOffset

	if invertXOffset == nil or invertXOffset then
		xOffsetLeft = -xOffsetLeft
	end

	local lX, _, lZ = localToWorld(leftNode, xOffsetLeft, 0, zOffset)
	local rX, _, rZ = localToWorld(rightNode, xOffsetRight, 0, zOffset)
	local sX = lX - 0.5 * directionX
	local sZ = lZ - 0.5 * directionZ
	local wX = rX - 0.5 * directionX
	local wZ = rZ - 0.5 * directionZ
	local hX = lX + areaSize * directionX
	local hZ = lZ + areaSize * directionZ

	return sX, sZ, wX, wZ, hX, hZ
end

function AIVehicleUtil.getIsAreaOwned(vehicle, sX, sZ, wX, wZ, hX, hZ)
	local farmId = vehicle:getAIJobFarmId()
	local centerX = (sX + wX) * 0.5
	local centerZ = (sZ + wZ) * 0.5

	if g_farmlandManager:getIsOwnedByFarmAtWorldPosition(farmId, centerX, centerZ) then
		return true
	end

	if g_missionManager:getIsMissionWorkAllowed(farmId, centerX, centerZ, nil) then
		return true
	end

	return false
end

function AIVehicleUtil.getAIAreaOfVehicle(vehicle, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local useDensityHeightMap = #vehicle:getAIDensityHeightTypeRequirements() > 0

	if not useDensityHeightMap then
		local query, isValid = vehicle:getFieldCropsQuery()

		if isValid then
			return AIVehicleUtil.getAIFruitArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, query)
		else
			return 0, 0
		end
	else
		local densityHeightTypeRequirements = vehicle:getAIDensityHeightTypeRequirements()

		return AIVehicleUtil.getAIDensityHeightArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, densityHeightTypeRequirements)
	end
end

function AIVehicleUtil.getAIFruitArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, query)
	local x, z, widthX, widthZ, heightX, heightZ = MathUtil.getXZWidthAndHeight(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	return query:getParallelogram(x, z, widthX, widthZ, heightX, heightZ, false)
end

function AIVehicleUtil.getAIDensityHeightArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, densityHeightTypeRequirements)
	local _, detailArea, _ = FSDensityMapUtil.getFieldDensity(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)

	if detailArea == 0 then
		return 0, 0
	end

	local retArea = 0
	local retTotalArea = 0

	for _, densityHeightTypeRequirement in pairs(densityHeightTypeRequirements) do
		if densityHeightTypeRequirement.fillType ~= FillType.UNKNOWN then
			local _, area, totalArea = DensityMapHeightUtil.getFillLevelAtArea(densityHeightTypeRequirement.fillType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			retTotalArea = totalArea
			retArea = retArea + area
		end
	end

	return retArea, retTotalArea
end
