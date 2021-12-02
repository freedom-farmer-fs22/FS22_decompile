DensityMapHeightUtil = {
	lastVehiclesInRange = {},
	terrainDetailHeightId = nil,
	typeFirstChannel = nil,
	typeNumChannels = nil,
	heightFirstChannel = nil,
	heightNumChannels = nil,
	modifiersCache = nil
}

function DensityMapHeightUtil.initTerrain(currentMission, detailId, detailHeightId)
	DensityMapHeightUtil.terrainDetailHeightId = detailHeightId
	DensityMapHeightUtil.typeFirstChannel = g_densityMapHeightManager.heightTypeFirstChannel
	DensityMapHeightUtil.typeNumChannels = g_densityMapHeightManager.heightTypeNumChannels
	DensityMapHeightUtil.heightFirstChannel = getDensityMapHeightFirstChannel(detailHeightId)
	DensityMapHeightUtil.heightNumChannels = getDensityMapHeightNumChannels(detailHeightId)
	DensityMapHeightUtil.modifiersCache = {}
end

function DensityMapHeightUtil.clearCache()
	DensityMapHeightUtil.lastVehiclesInRange = {}
	DensityMapHeightUtil.terrainDetailHeightId = nil
	DensityMapHeightUtil.typeFirstChannel = nil
	DensityMapHeightUtil.typeNumChannels = nil
	DensityMapHeightUtil.heightFirstChannel = nil
	DensityMapHeightUtil.heightNumChannels = nil
	DensityMapHeightUtil.modifiersCache = nil
end

function DensityMapHeightUtil.getCanTipToGround(fillTypeIndex)
	if not g_densityMapHeightManager:getIsValid() then
		return false
	end

	local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)

	if heightType == nil then
		return false
	end

	return true
end

function DensityMapHeightUtil.getFillTypeAtLine(sx, sy, sz, ex, ey, ez, radius)
	if g_densityMapHeightManager:getIsValid() then
		local heightTypeIndex = getDensityMapHeightTypeAtWorldLine(g_densityMapHeightManager:getTerrainDetailHeightUpdater(), sx, sy, sz, ex, ey, ez, radius)
		local fillTypeIndex = g_densityMapHeightManager:getFillTypeIndexByDensityHeightMapIndex(heightTypeIndex)

		if fillTypeIndex ~= nil then
			return fillTypeIndex
		end
	end

	return FillType.UNKNOWN
end

function DensityMapHeightUtil.getFillTypeAtArea(x0, z0, x1, z1, x2, z2)
	local modifiers = DensityMapHeightUtil.modifiersCache.getFillTypeAtArea

	if modifiers == nil then
		modifiers = {
			typeModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels),
			typeFilters = {}
		}
		local heightTypes = g_densityMapHeightManager:getDensityMapHeightTypes()

		if heightTypes ~= nil then
			for _, heightType in ipairs(heightTypes) do
				local typeFilter = DensityMapFilter.new(modifiers.typeModifier)

				typeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, heightType.index)

				modifiers.typeFilters[heightType] = typeFilter
			end
		end

		DensityMapHeightUtil.modifiersCache.getFillTypeAtArea = modifiers
	end

	if not g_densityMapHeightManager:getIsValid() then
		return FillType.UNKNOWN
	end

	local fillType = FillType.UNKNOWN
	local modifierType = modifiers.typeModifier

	modifierType:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)

	local density = modifierType:executeGet()

	if density > 0 then
		local typeFilters = modifiers.typeFilters

		for heightType, typeFilter in pairs(typeFilters) do
			local density2 = modifierType:executeGet(typeFilter)

			if density2 > 0 then
				fillType = heightType.fillTypeIndex

				break
			end
		end
	end

	return fillType
end

function DensityMapHeightUtil.getFillLevelAtArea(fillTypeIndex, x0, z0, x1, z1, x2, z2)
	if not g_densityMapHeightManager:getIsValid() then
		return 0, 0, 0
	end

	local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)

	if heightType == nil then
		return 0, 0, 0
	end

	local modifiers = DensityMapHeightUtil.modifiersCache.getFillLevelAtArea

	if modifiers == nil then
		modifiers = {
			heightModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels)
		}

		modifiers.heightModifier:setPolygonRoundingMode(DensityRoundingMode.NEAREST_EXPAND)

		modifiers.heightFilter = DensityMapFilter.new(modifiers.heightModifier)

		modifiers.heightFilter:setValueCompareParams(DensityValueCompareType.GREATER, 0)

		modifiers.typeFilters = {}
		DensityMapHeightUtil.modifiersCache.getFillLevelAtArea = modifiers
	end

	local modifierHeight = modifiers.heightModifier
	local heightFilter = modifiers.heightFilter
	local typeFilter = modifiers.typeFilters[fillTypeIndex]

	if typeFilter == nil then
		typeFilter = DensityMapFilter.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)

		typeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, heightType.index)

		modifiers.typeFilters[fillTypeIndex] = typeFilter
	end

	modifierHeight:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)

	local density, numPixels, totalNumPixels = modifierHeight:executeGet(heightFilter, typeFilter)

	return density * g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex), numPixels, totalNumPixels
end

function DensityMapHeightUtil.getValueAtArea(x0, z0, x1, z1, x2, z2, filterSnow)
	local modifiers = DensityMapHeightUtil.modifiersCache.getValueAtArea

	if modifiers == nil then
		modifiers = {
			heightModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels)
		}
		DensityMapHeightUtil.modifiersCache.getValueAtArea = modifiers
		modifiers.snowFilter = DensityMapFilter.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)

		modifiers.snowFilter:setValueCompareParams(DensityValueCompareType.NOTEQUAL, g_densityMapHeightManager:getDensityMapHeightTypeIndexByFillTypeIndex(FillType.SNOW))
	end

	local modifier = modifiers.heightModifier
	local snowFilter = nil

	if filterSnow then
		snowFilter = modifiers.snowFilter
	end

	modifier:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)

	return modifier:executeGet(snowFilter)
end

function DensityMapHeightUtil.getHeightAtWorldPos(x, y, z)
	return getDensityHeightAtWorldPos(DensityMapHeightUtil.terrainDetailHeightId, x, y, z)
end

function DensityMapHeightUtil.getCollisionHeightAtWorldPos(x, y, z)
	if g_densityMapHeightManager:getIsValid() then
		return getDensityMapCollisionHeightAtWorldPos(g_densityMapHeightManager:getTerrainDetailHeightUpdater(), x, y, z)
	end

	return 0, 0
end

function DensityMapHeightUtil.getVehiclesInRange(refVehicle, x, y, z, radiusSq)
	for i = #DensityMapHeightUtil.lastVehiclesInRange, 1, -1 do
		DensityMapHeightUtil.lastVehiclesInRange[i] = nil
	end

	for _, vehicle in pairs(g_currentMission.vehicles) do
		if vehicle ~= refVehicle and vehicle.components ~= nil then
			for _, component in pairs(vehicle.components) do
				local cx, cy, cz = getWorldTranslation(component.node)
				local distSq = MathUtil.vector3LengthSq(x - cx, y - cy, z - cz)

				if distSq < radiusSq then
					table.insert(DensityMapHeightUtil.lastVehiclesInRange, vehicle)

					break
				end
			end
		end
	end

	return DensityMapHeightUtil.lastVehiclesInRange
end

function DensityMapHeightUtil.tipToGroundAroundLine(vehicle, delta, fillTypeIndex, sx, sy, sz, ex, ey, ez, innerRadius, radius, lineOffset, limitToLineHeight, occlusionAreas, useOcclusionAreas, applyChanges)
	if not g_densityMapHeightManager:getIsValid() then
		return 0, 0
	end

	local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)

	if heightType == nil then
		return 0, 0
	end

	if occlusionAreas == nil and vehicle ~= nil and vehicle.getTipOcclusionAreas ~= nil then
		occlusionAreas = vehicle:getTipOcclusionAreas()
	end

	if radius == nil then
		radius = getDensityMapMaxHeight(DensityMapHeightUtil.terrainDetailHeightId) / math.tan(heightType.maxSurfaceAngle)
	end

	if innerRadius == nil then
		innerRadius = 0
	end

	if lineOffset == nil then
		lineOffset = 0
	end

	if limitToLineHeight == nil then
		limitToLineHeight = false
	end

	if applyChanges == nil then
		applyChanges = true
	end

	if delta < 0 then
		useOcclusionAreas = false
	end

	if delta > 0 then
		local fixedFillTypeAreas = g_densityMapHeightManager:getFixedFillTypesAreas()

		if fixedFillTypeAreas ~= nil then
			for area, fixedFillTypeArea in pairs(fixedFillTypeAreas) do
				if area ~= nil and fixedFillTypeArea ~= nil then
					local validFillType = false

					for availableFillType, _ in pairs(fixedFillTypeArea.fillTypes) do
						if availableFillType == fillTypeIndex then
							validFillType = true
						end
					end

					if area ~= nil and not validFillType then
						local x1, _, z1 = getWorldTranslation(area.start)
						local x2, _, z2 = getWorldTranslation(area.width)
						local x3, _, z3 = getWorldTranslation(area.height)

						if MathUtil.hasRectangleLineIntersection2D(x1, z1, x2 - x1, z2 - z1, x3 - x1, z3 - z1, sx, sz, ex - sx, ez - sz) then
							return 0, 0
						end
					end
				end
			end
		end

		local convertingFillTypesAreas = g_densityMapHeightManager:getConvertingFillTypesAreas()

		if convertingFillTypesAreas ~= nil then
			for area, convertingArea in pairs(convertingFillTypesAreas) do
				if area ~= nil and convertingArea ~= nil then
					local x1, _, z1 = getWorldTranslation(area.start)
					local x2, _, z2 = getWorldTranslation(area.width)
					local x3, _, z3 = getWorldTranslation(area.height)

					if MathUtil.hasRectangleLineIntersection2D(x1, z1, x2 - x1, z2 - z1, x3 - x1, z3 - z1, sx, sz, ex - sx, ez - sz) then
						if convertingArea.fillTypes[fillTypeIndex] == true then
							fillTypeIndex = convertingArea.fillTypeTarget
							heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)

							if heightType == nil then
								return 0, 0
							end
						else
							return 0, 0
						end
					end
				end
			end
		end
	end

	local fillToGroundScale = g_densityMapHeightManager.fillToGroundScale * heightType.fillToGroundScale

	if useOcclusionAreas ~= nil and useOcclusionAreas then
		if occlusionAreas ~= nil then
			local terrainUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()

			if terrainUpdater ~= nil then
				for _, area in pairs(occlusionAreas) do
					local xs, ys, zs = getWorldTranslation(area.start)
					local xw, yw, zw = getWorldTranslation(area.width)
					local xh, yh, zh = getWorldTranslation(area.height)
					local allowPropagation = area.allowPropagation

					if allowPropagation == nil then
						allowPropagation = false
					end

					addDensityMapHeightOcclusionArea(terrainUpdater, xs, ys, zs, xw - xs, yw - ys, zw - zs, xh - xs, yh - ys, zh - zs, allowPropagation)

					if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
						local x = xw + xh - xs
						local y = yw + yh - ys
						local z = zw + zh - zs

						drawDebugTriangle(xs, ys, zs, xw, yw, zw, xh, yh, zh, 1, 0, 0, 0.5, false)
						drawDebugTriangle(x, y, z, xh, yh, zh, xw, yw, zw, 1, 0, 0, 0.5, false)
						drawDebugTriangle(xh, yh, zh, xw, yw, zw, xs, ys, zs, 1, 0, 0, 0.5, false)
						drawDebugTriangle(xw, yw, zw, xh, yh, zh, x, y, z, 1, 0, 0, 0.5, false)
					end
				end
			end
		end

		local terrainUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()

		if terrainUpdater ~= nil then
			local lineLength = MathUtil.vector3Length(sx - ex, sy - ey, sz - ez)
			local maxDistSq = (20 + 0.5 * lineLength + radius)^2
			local x = 0.5 * (sx + ex)
			local y = 0.5 * (sy + ey)
			local z = 0.5 * (sz + ez)
			local vehiclesInRange = DensityMapHeightUtil.getVehiclesInRange(vehicle, x, y, z, maxDistSq)

			if vehiclesInRange ~= nil then
				for _, vehicleInRange in pairs(vehiclesInRange) do
					if vehicleInRange.getTipOcclusionAreas ~= nil then
						local tipOcclusionAreas = vehicleInRange:getTipOcclusionAreas()

						for _, area in pairs(tipOcclusionAreas) do
							local xs, ys, zs = getWorldTranslation(area.start)
							local xw, yw, zw = getWorldTranslation(area.width)
							local xh, yh, zh = getWorldTranslation(area.height)

							addDensityMapHeightOcclusionArea(terrainUpdater, xs, ys, zs, xw - xs, yw - ys, zw - zs, xh - xs, yh - ys, zh - zs, false)

							if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
								local xV = xw + xh - xs
								local yV = yw + yh - ys
								local zV = zw + zh - zs

								drawDebugTriangle(xs, ys, zs, xw, yw, zw, xh, yh, zh, 1, 0, 0, 0.5, false)
								drawDebugTriangle(xV, yV, zV, xh, yh, zh, xw, yw, zw, 1, 0, 0, 0.5, false)
								drawDebugTriangle(xh, yh, zh, xw, yw, zw, xs, ys, zs, 1, 0, 0, 0.5, false)
								drawDebugTriangle(xw, yw, zw, xh, yh, zh, xV, yV, zV, 1, 0, 0, 0.5, false)
							end
						end
					end
				end
			end
		end
	end

	if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
		drawDebugLine(sx, sy, sz, 0, 1, 1, ex, ey, ez, 0, 1, 1)
		drawDebugLine(sx, sy, sz, 0, 1, 1, sx, sy, sz, 0, 1, 1)
		drawDebugLine(ex, ey, ez, 0, 1, 1, ex, ey, ez, 0, 1, 1)
	end

	local dropped = 0
	local terrainUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()

	if terrainUpdater ~= nil then
		local litersToTip = delta * fillToGroundScale

		if not applyChanges then
			litersToTip = math.max(litersToTip, g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex))
		end

		dropped, lineOffset = addDensityMapHeightAtWorldLine(terrainUpdater, sx, sy, sz, ex, ey, ez, litersToTip, heightType.index, innerRadius, radius, limitToLineHeight, lineOffset, applyChanges)

		if not applyChanges then
			dropped = math.min(dropped, litersToTip)
		end
	end

	dropped = dropped / fillToGroundScale

	if math.abs(delta) - math.abs(dropped) < 0.001 then
		dropped = delta
	end

	return dropped, lineOffset
end

function DensityMapHeightUtil.getCanTipToGroundAroundLine(vehicle, delta, fillTypeIndex, sx, sy, sz, ex, ey, ez, innerRadius, radius, lineOffset, limitToLineHeight, occlusionAreas, useOcclusionAreas)
	local fillLevel, _ = DensityMapHeightUtil.tipToGroundAroundLine(vehicle, delta, fillTypeIndex, sx, sy, sz, ex, ey, ez, innerRadius, radius, lineOffset, limitToLineHeight, occlusionAreas, useOcclusionAreas, false)

	return fillLevel ~= 0
end

function DensityMapHeightUtil.removeFromGroundByArea(x0, z0, x1, z1, x2, z2, fillTypeIndex)
	if not g_densityMapHeightManager:getIsValid() then
		return 0
	end

	local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)

	if heightType == nil then
		return 0
	end

	local modifiers = DensityMapHeightUtil.modifiersCache.removeFromGroundByArea

	if modifiers == nil then
		modifiers = {
			heightModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels),
			typeModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels),
			typeFilters = {}
		}
		DensityMapHeightUtil.modifiersCache.removeFromGroundByArea = modifiers
	end

	local typeFilter = modifiers.typeFilters[heightType]

	if typeFilter == nil then
		typeFilter = DensityMapFilter.new(modifiers.typeModifier)

		typeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, heightType.index)

		modifiers.typeFilters[heightType] = typeFilter
	end

	local heightModifier = modifiers.heightModifier
	local typeModifier = modifiers.typeModifier

	heightModifier:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	typeModifier:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	typeModifier:executeSet(0, typeFilter)

	local density = heightModifier:executeSet(0, typeFilter)

	return density * g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)
end

function DensityMapHeightUtil.changeFillTypeAtArea(x0, z0, x1, z1, x2, z2, fillTypeIndex, newFillTypeIndex)
	if not g_densityMapHeightManager:getIsValid() then
		return 0
	end

	local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)
	local newHeightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(newFillTypeIndex)

	if heightType == nil or newHeightType == nil then
		return 0
	end

	local modifiers = DensityMapHeightUtil.modifiersCache.changeFillTypeAtArea

	if modifiers == nil then
		modifiers = {
			typeModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels),
			typeFilters = {}
		}
		DensityMapHeightUtil.modifiersCache.changeFillTypeAtArea = modifiers
	end

	local typeFilter = modifiers.typeFilters[heightType]

	if typeFilter == nil then
		typeFilter = DensityMapFilter.new(modifiers.typeModifier)

		typeFilter:setValueCompareParams(DensityValueCompareType.EQUAL, heightType.index)

		modifiers.typeFilters[heightType] = typeFilter
	end

	local typeModifier = modifiers.typeModifier

	typeModifier:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)

	local density = typeModifier:executeSet(newHeightType.index, typeFilter)

	return density * g_densityMapHeightManager:getMinValidLiterValue(fillTypeIndex)
end

function DensityMapHeightUtil.clearArea(x0, z0, x1, z1, x2, z2)
	local modifiers = DensityMapHeightUtil.modifiersCache.clearArea

	if modifiers == nil then
		modifiers = {
			heightModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.heightFirstChannel, DensityMapHeightUtil.heightNumChannels),
			typeModifier = DensityMapModifier.new(DensityMapHeightUtil.terrainDetailHeightId, DensityMapHeightUtil.typeFirstChannel, DensityMapHeightUtil.typeNumChannels)
		}
		DensityMapHeightUtil.modifiersCache.clearArea = modifiers
	end

	local heightModifier = modifiers.heightModifier
	local typeModifier = modifiers.typeModifier

	heightModifier:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	typeModifier:setParallelogramWorldCoords(x0, z0, x1, z1, x2, z2, DensityCoordType.POINT_POINT_POINT)
	heightModifier:executeSet(0)
	typeModifier:executeSet(0)
end

function DensityMapHeightUtil.getDefaultMaxRadius(fillTypeIndex)
	local heightType = g_densityMapHeightManager:getDensityMapHeightTypeByFillTypeIndex(fillTypeIndex)

	if heightType == nil then
		return 0
	end

	return getDensityMapMaxHeight(DensityMapHeightUtil.terrainDetailHeightId) / math.tan(heightType.maxSurfaceAngle)
end

function DensityMapHeightUtil.getRoundedHeightValue(height)
	if not g_densityMapHeightManager:getIsValid() then
		return height
	end

	return math.floor(height * g_densityMapHeightManager.heightToDensityValue) / g_densityMapHeightManager.heightToDensityValue
end

function DensityMapHeightUtil.getHeightTypeDescAtWorldPos(x, y, z, radius)
	local terrainUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()
	local heightTypeIndex = getDensityMapHeightTypeAtWorldPos(terrainUpdater, x, y, z, radius)

	if heightTypeIndex ~= nil then
		return g_densityMapHeightManager:getDensityMapHeightTypeByIndex(heightTypeIndex)
	else
		return nil
	end
end

function DensityMapHeightUtil.getLineByAreaDimensions(sx, sy, sz, wx, wy, wz, hx, hy, hz, radiusOverlap)
	local swDirX = wx - sx
	local swDirY = wy - sy
	local swDirZ = wz - sz
	local shDirX = hx - sx
	local shDirY = hy - sy
	local shDirZ = hz - sz
	local swLength = MathUtil.vector3Length(swDirX, swDirY, swDirZ)
	local shLength = MathUtil.vector3Length(shDirX, shDirY, shDirZ)
	shDirZ = shDirZ / shLength
	shDirY = shDirY / shLength
	shDirX = shDirX / shLength
	swDirZ = swDirZ / swLength
	swDirY = swDirY / swLength
	swDirX = swDirX / swLength
	local lsx, lsy, lsz, lex, ley, lez, radius = nil

	if shLength < swLength then
		radius = shLength * 0.5
		local shrink = radius

		if radiusOverlap ~= nil and radiusOverlap then
			shrink = 0
		end

		lsx = sx + shDirX * shLength * 0.5 + swDirX * shrink
		lsy = sy + shDirY * shLength * 0.5 + swDirY * shrink
		lsz = sz + shDirZ * shLength * 0.5 + swDirZ * shrink
		lex = wx + shDirX * shLength * 0.5 - swDirX * shrink
		ley = wy + shDirY * shLength * 0.5 - swDirY * shrink
		lez = wz + shDirZ * shLength * 0.5 - swDirZ * shrink
	else
		radius = swLength * 0.5
		local shrink = radius

		if radiusOverlap ~= nil and radiusOverlap then
			shrink = 0
		end

		lsx = sx + swDirX * swLength * 0.5 + shDirX * shrink
		lsy = sy + swDirY * swLength * 0.5 + shDirY * shrink
		lsz = sz + swDirZ * swLength * 0.5 + shDirZ * shrink
		lex = hx + swDirX * swLength * 0.5 - shDirX * shrink
		ley = hy + swDirY * swLength * 0.5 - shDirY * shrink
		lez = hz + swDirZ * swLength * 0.5 - shDirZ * shrink
	end

	return lsx, lsy, lsz, lex, ley, lez, radius
end

function DensityMapHeightUtil.getLineByArea(start, width, height, radiusOverlap)
	local sx, sy, sz = getWorldTranslation(start)
	local wx, wy, wz = getWorldTranslation(width)
	local hx, hy, hz = getWorldTranslation(height)

	return DensityMapHeightUtil.getLineByAreaDimensions(sx, sy, sz, wx, wy, wz, hx, hy, hz, radiusOverlap)
end

function DensityMapHeightUtil.getAreaPartitions(start, width, height)
	local sx, sy, sz = getWorldTranslation(start)
	local wx, wy, wz = getWorldTranslation(width)
	local hx, hy, hz = getWorldTranslation(height)
	local areas = {}
	local MAX_AREA_SIZE = 4
	local distance = MathUtil.vector3Length(hx - sx, hy - sy, hz - sz)
	local dirX, dirY, dirZ = MathUtil.vector3Normalize(hx - sx, hy - sy, hz - sz)
	local areaSize = nil

	if MAX_AREA_SIZE < distance then
		local numSubareas = math.ceil(distance / MAX_AREA_SIZE)
		areaSize = distance / numSubareas

		for i = 1, numSubareas do
			local subStart = createTransformGroup("start" .. i)
			local subWidth = createTransformGroup("width" .. i)
			local subHeight = createTransformGroup("height" .. i)

			link(start, subStart)
			link(width, subWidth)
			link(height, subHeight)
			setWorldTranslation(subStart, sx + dirX * areaSize * (i - 1), sy + dirY * areaSize * (i - 1), sz + dirZ * areaSize * (i - 1))
			setWorldTranslation(subWidth, wx + dirX * areaSize * (i - 1), wy + dirY * areaSize * (i - 1), wz + dirZ * areaSize * (i - 1))
			setWorldTranslation(subHeight, sx + dirX * areaSize * i, sy + dirY * areaSize * i, sz + dirZ * areaSize * i)
			table.insert(areas, {
				start = subStart,
				width = subWidth,
				height = subHeight
			})
		end
	else
		table.insert(areas, {
			start = start,
			width = width,
			height = height
		})
	end

	return areas
end

function DensityMapHeightUtil.smoothAroundLine(node, width, radius, overlap, smoothAmount)
	local steps = math.ceil(width / (radius * 2 / overlap))
	local realRadius = width / steps * 0.5
	local heightType = nil

	for step = 1, steps do
		local r = realRadius
		local x, y, z = localToWorld(node, -(width * 0.5) + r * 2 * (step - 0.5), 0, 0)
		local smoothGroundRadius = r * overlap
		heightType = heightType or DensityMapHeightUtil.getHeightTypeDescAtWorldPos(x, y, z, smoothGroundRadius)

		if heightType ~= nil and heightType.allowsSmoothing then
			local terrainHeightUpdater = g_densityMapHeightManager:getTerrainDetailHeightUpdater()

			if terrainHeightUpdater ~= nil then
				local densityHeight = DensityMapHeightUtil.getHeightAtWorldPos(x, y, z)

				if y < densityHeight then
					smoothDensityMapHeightAtWorldPos(terrainHeightUpdater, x, densityHeight - heightType.collisionBaseOffset, z, smoothAmount, heightType.index, 0, smoothGroundRadius, smoothGroundRadius + 1.2)

					if VehicleDebug.state == VehicleDebug.DEBUG_ATTRIBUTES then
						DebugUtil.drawDebugGizmoAtWorldPos(x, y, z, 0, 0, 1, 0, 1, 0, "", false)
						DebugUtil.drawDebugCircle(x, densityHeight - heightType.collisionBaseOffset, z, smoothGroundRadius, 10)
					end
				end
			end
		end
	end
end
