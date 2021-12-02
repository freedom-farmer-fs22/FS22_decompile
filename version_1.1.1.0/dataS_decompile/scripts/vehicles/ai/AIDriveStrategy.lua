AIDriveStrategy = {}
local AIDriveStrategy_mt = Class(AIDriveStrategy)

function AIDriveStrategy.new(customMt)
	if customMt == nil then
		customMt = AIDriveStrategy_mt
	end

	local self = {}

	setmetatable(self, customMt)

	self.lastValidGroundPosX = 0
	self.lastValidGroundPosY = 0
	self.lastValidGroundPosZ = 0
	self.lastHasNoField = false
	self.lookAheadDistanceField = 5

	return self
end

function AIDriveStrategy:delete()
end

function AIDriveStrategy:setAIVehicle(vehicle)
	self.vehicle = vehicle
	self.lastValidGroundPosX, self.lastValidGroundPosY, self.lastValidGroundPosZ = getWorldTranslation(self.vehicle:getAIDirectionNode())
	self.lastHasNoField = false
end

function AIDriveStrategy:update(dt)
end

function AIDriveStrategy:getDriveData(dt, vX, vY, vZ)
	return nil, , , , 
end

function AIDriveStrategy:updateDriving(dt)
end

function AIDriveStrategy:getDistanceToEndOfField(dt, vX, vY, vZ)
	if self.lastHasNoField then
		local dist = MathUtil.vector3Length(self.lastValidGroundPosX - vX, self.lastValidGroundPosY - vY, self.lastValidGroundPosZ - vZ)

		return self.distanceToEnd - dist, false, true
	end

	if self.fieldEndGabDetected or self.fieldEndGabDetectedByBits then
		return 0, false, true
	end

	local distanceToTurn = self.lookAheadDistanceField
	local attachedAIImplements = self.vehicle:getAttachedAIImplements()
	local hasField = false
	local ownedField = true
	local lookAheadDist = nil

	for i = 1, #attachedAIImplements do
		local implement = attachedAIImplements[i]
		local leftMarker, rightMarker, backMarker = implement.object:getAIMarkers()

		if i == 1 then
			lookAheadDist = self.lookAheadDistanceField
		else
			local implementPre = attachedAIImplements[i - 1]
			local leftMarker2, _, backMarker2 = implementPre.object:getAIMarkers()
			local _, _, zDiffArea = localToLocal(leftMarker2, backMarker2, 0, 0, 0)
			local _, _, zDiff = localToLocal(leftMarker2, leftMarker, 0, 0, 0)
			lookAheadDist = math.max(0, zDiff - zDiffArea - implement.object:getAILookAheadSize())

			if self.turnData ~= nil and self.turnData.allImplementsOfSameType == true then
				lookAheadDist = lookAheadDist + self.lookAheadDistanceField + zDiffArea + implement.object:getAILookAheadSize()
			end
		end

		local _ = 0
		local _ = 0
		local markerZOffset = 0
		local size = implement.object:getAILookAheadSize()

		if implement.object:getAIHasNoFullCoverageArea() then
			_, _, markerZOffset = localToLocal(backMarker, leftMarker, 0, 0, 0)
			lookAheadDist = 0
			size = size + math.abs(markerZOffset)
		end

		local lX0, _, lZ0 = localToWorld(leftMarker, 0, 0, markerZOffset)
		local rX0, _, rZ0 = localToWorld(rightMarker, 0, 0, markerZOffset)
		local lX = lX0 + self.vehicle.aiDriveDirection[1] * lookAheadDist
		local lZ = lZ0 + self.vehicle.aiDriveDirection[2] * lookAheadDist
		local rX = rX0 + self.vehicle.aiDriveDirection[1] * lookAheadDist
		local rZ = rZ0 + self.vehicle.aiDriveDirection[2] * lookAheadDist
		local hX = lX + self.vehicle.aiDriveDirection[1] * size
		local hZ = lZ + self.vehicle.aiDriveDirection[2] * size
		local area, areaTotal = AIVehicleUtil.getAIAreaOfVehicle(implement.object, lX, lZ, rX, rZ, hX, hZ, false)

		if VehicleDebug.state == VehicleDebug.DEBUG_AI then
			self.vehicle:addAIDebugText(string.format("tool %d: area=%.1f areaTotal=%.1f", i, area, areaTotal))

			local lY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, lX, 0, lZ) + 2
			local rY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, rX, 0, rZ) + 2
			local hY = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, hX, 0, hZ) + 2

			self.vehicle:addAIDebugLine({
				lX,
				lY,
				lZ
			}, {
				rX,
				rY,
				rZ
			}, {
				0,
				1,
				0
			})
			self.vehicle:addAIDebugLine({
				lX,
				lY,
				lZ
			}, {
				hX,
				hY,
				hZ
			}, {
				0,
				1,
				0
			})
		end

		if area > 0 then
			local farmId = self.vehicle:getAIJobFarmId()
			local posX = (rX + hX) * 0.5
			local posZ = (rZ + hZ) * 0.5

			if g_currentMission.accessHandler:canFarmAccessLand(farmId, posX, posZ) or g_missionManager:getIsMissionWorkAllowed(farmId, posX, posZ, nil) then
				hasField = true

				break
			else
				ownedField = false
			end
		end
	end

	self.lastHasNoField = not hasField

	if hasField then
		local distance = self.vehicle.lastMovedDistance
		local dirX, dirY, dirZ = localDirectionToWorld(self.vehicle:getAIDirectionNode(), 0, 0, distance + 0.75)
		self.lastValidGroundPosX = vX + dirX
		self.lastValidGroundPosY = vY + dirY
		self.lastValidGroundPosZ = vZ + dirZ
	else
		self.distanceToEnd = lookAheadDist
		local dist = MathUtil.vector3Length(self.lastValidGroundPosX - vX, self.lastValidGroundPosY - vY, self.lastValidGroundPosZ - vZ)
		distanceToTurn = self.distanceToEnd - dist
	end

	return distanceToTurn, hasField, ownedField
end

function AIDriveStrategy:debugPrint(text, ...)
	if VehicleDebug.state == VehicleDebug.DEBUG_AI then
		print(string.format("AI DEBUG: %s", string.format(text, ...)))
	end
end
