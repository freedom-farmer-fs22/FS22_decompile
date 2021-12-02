MathUtil = {
	sign = function (x)
		if type(x) == "table" then
			printCallstack()
		end

		if x > 0 then
			return 1
		elseif x < 0 then
			return -1
		else
			return 0
		end
	end,
	isNan = function (value)
		return value ~= value
	end,
	round = function (value, precision)
		if value == nil then
			return nil
		end

		if precision then
			local exp = 10^precision

			return math.floor(value * exp + 0.5) / exp
		else
			return math.floor(value + 0.5)
		end
	end,
	degToRad = function (degValue)
		if degValue ~= nil then
			return math.rad(degValue)
		else
			return 0
		end
	end,
	lerp = function (v1, v2, alpha)
		return v1 + (v2 - v1) * alpha
	end
}

function MathUtil.lerp3(x1, y1, z1, x2, y2, z2, alpha)
	return MathUtil.lerp(x1, x2, alpha), MathUtil.lerp(y1, y2, alpha), MathUtil.lerp(z1, z2, alpha)
end

function MathUtil.inverseLerp(v1, v2, cv)
	if math.abs(v1 - v2) < 0.0001 then
		return 0
	end

	return MathUtil.clamp((cv - v1) / (v2 - v1), 0, 1)
end

function MathUtil.timeLerp(startTime, endTime, currentTime)
	if startTime == endTime then
		return 0
	end

	if endTime < startTime then
		local diff = 24 - startTime
		startTime = 0
		endTime = endTime + diff
		currentTime = (currentTime + diff) % 24
	end

	return (currentTime - startTime) / (endTime - startTime)
end

function MathUtil.clamp(value, minVal, maxVal)
	if value == nil then
		printCallstack()
	elseif minVal == nil then
		printCallstack()
	elseif maxVal == nil then
		printCallstack()
	end

	return math.min(math.max(value, minVal), maxVal)
end

function MathUtil.getIsOutOfBounds(value, limit1, limit2)
	if limit1 < limit2 then
		return value < limit1 or limit2 < value
	else
		return limit1 < value or value < limit2
	end
end

function MathUtil.getFlooredPercent(value, maxValue)
	local percent = 0

	if maxValue > 0 then
		percent = math.floor(value / maxValue * 100)

		if percent > 99 and value < maxValue then
			percent = 99
		elseif percent < 1 and value > 0 then
			percent = 1
		end
	end

	return percent
end

function MathUtil.getFlooredBounded(value, minValue, maxValue)
	if value == minValue then
		return minValue
	elseif value == maxValue then
		return maxValue
	else
		return math.min(math.max(math.floor(value), minValue + 1), maxValue - 1)
	end
end

function MathUtil.getValidLimit(limit)
	while limit < -math.pi do
		limit = limit + 2 * math.pi
	end

	while math.pi < limit do
		limit = limit - 2 * math.pi
	end

	return limit
end

function MathUtil.getAngleDifference(alpha, beta)
	local a = alpha - beta

	return MathUtil.getValidLimit(a)
end

function MathUtil.vector2Length(x, y)
	return math.sqrt(x * x + y * y)
end

function MathUtil.vector2LengthSq(x, y)
	return x * x + y * y
end

function MathUtil.vector2Normalize(x, y)
	local length = MathUtil.vector2Length(x, y)

	return x / length, y / length
end

function MathUtil.vector3Length(x, y, z)
	return math.sqrt(x * x + y * y + z * z)
end

function MathUtil.vector3LengthSq(x, y, z)
	return x * x + y * y + z * z
end

function MathUtil.vector3Normalize(x, y, z)
	local length = MathUtil.vector3Length(x, y, z)

	return x / length, y / length, z / length
end

function MathUtil.vector3SetLength(x, y, z, length)
	local vx, vy, vz = MathUtil.vector3Normalize(x, y, z)
	x = vx * length
	y = vy * length
	z = vz * length

	return x, y, z
end

function MathUtil.vector3Clamp(x, y, z, minVal, maxVal)
	local length = MathUtil.vector3Length(x, y, z)

	if length > 0 then
		length = MathUtil.clamp(length, minVal, maxVal)
		x, y, z = MathUtil.vector3SetLength(x, y, z, length)
	end

	return x, y, z
end

function MathUtil.vector3Lerp(x1, y1, z1, x2, y2, z2, alpha)
	return x1 + (x2 - x1) * alpha, y1 + (y2 - y1) * alpha, z1 + (z2 - z1) * alpha
end

function MathUtil.inverseVector3Lerp(x1, y1, z1, x2, y2, z2, c1, c2, c3)
	local alpha1 = MathUtil.inverseLerp(x1, x2, c1)
	local alpha2 = MathUtil.inverseLerp(y1, y2, c2)
	local alpha3 = MathUtil.inverseLerp(z1, z2, c3)
	local value = 0

	if x1 ~= x2 then
		value = alpha1
	elseif y1 ~= y2 then
		value = alpha2
	elseif z1 ~= z2 then
		value = alpha3
	end

	return value
end

function MathUtil.vector3ArrayLerp(v1, v2, alpha)
	return v1[1] + (v2[1] - v1[1]) * alpha, v1[2] + (v2[2] - v1[2]) * alpha, v1[3] + (v2[3] - v1[3]) * alpha
end

function MathUtil.inverseVector3ArrayLerp(v1, v2, cv)
	local alpha1 = MathUtil.inverseLerp(v1[1], v2[1], cv[1])
	local alpha2 = MathUtil.inverseLerp(v1[2], v2[2], cv[2])
	local alpha3 = MathUtil.inverseLerp(v1[3], v2[3], cv[3])
	local value = 0

	if v1[1] ~= v2[1] then
		value = alpha1
	elseif v1[2] ~= v2[2] then
		value = alpha2
	elseif v1[3] ~= v2[3] then
		value = alpha3
	end

	return value
end

function MathUtil.vector3Transformation(x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33)
	return x * m11 + y * m21 + z * m31, x * m12 + y * m22 + z * m32, x * m13 + y * m23 + z * m33
end

function MathUtil.transform(x, y, z, dirX, dirY, dirZ, upX, upY, upZ, xOffset, yOffset, zOffset)
	local normX, normY, normZ = MathUtil.crossProduct(upX, upY, upZ, dirX, dirY, dirZ)
	x = x + normX * xOffset + upX * yOffset + dirX * zOffset
	y = y + normY * xOffset + upY * yOffset + dirY * zOffset
	z = z + normZ * xOffset + upZ * yOffset + dirZ * zOffset

	return x, y, z
end

function MathUtil.dotProduct(ax, ay, az, bx, by, bz)
	return ax * bx + ay * by + az * bz
end

function MathUtil.crossProduct(ax, ay, az, bx, by, bz)
	return ay * bz - az * by, az * bx - ax * bz, ax * by - ay * bx
end

function MathUtil.getVectorAngleDifference(dirX1, dirY1, dirZ1, dirX2, dirY2, dirZ2)
	local dot = dirX1 * dirX2 + dirY1 * dirY2 + dirZ1 * dirZ2
	local length1 = math.sqrt(dirX1 * dirX1 + dirY1 * dirY1 + dirZ1 * dirZ1)
	local length2 = math.sqrt(dirX2 * dirX2 + dirY2 * dirY2 + dirZ2 * dirZ2)

	return math.acos(dot / (length1 * length2))
end

function MathUtil.getYRotationFromDirection(dx, dz)
	return math.atan2(dx, dz)
end

function MathUtil.getDirectionFromYRotation(rotY)
	return math.sin(rotY), math.cos(rotY)
end

function MathUtil.getRotationLimitedVector2(x, y, minRot, maxRot)
	local rot = -math.atan2(y, x)

	if minRot > rot or maxRot < rot then
		if rot < minRot then
			rot = minRot
		else
			rot = maxRot
		end

		local len = math.sqrt(x * x + y * y)
		x = math.cos(-rot) * len
		y = math.sin(-rot) * len
	end

	return x, y
end

function MathUtil.projectOnLine(px, pz, lineX, lineZ, normlineDirX, normlineDirZ)
	local dx = px - lineX
	local dz = pz - lineZ
	local dot = dx * normlineDirX + dz * normlineDirZ

	return lineX + normlineDirX * dot, lineZ + normlineDirZ * dot
end

function MathUtil.getProjectOnLineParameter(px, pz, lineX, lineZ, normlineDirX, normlineDirZ)
	local dx = px - lineX
	local dz = pz - lineZ
	local dot = dx * normlineDirX + dz * normlineDirZ

	return dot
end

function MathUtil.quaternionMult(x, y, z, w, x1, y1, z1, w1)
	return y * z1 - z * y1 + w * x1 + x * w1, z * x1 - x * z1 + w * y1 + y * w1, x * y1 - y * x1 + w * z1 + z * w1, w * w1 - x * x1 - y * y1 - z * z1
end

function MathUtil.quaternionNormalized(x, y, z, w)
	local len = math.sqrt(x * x + y * y + z * z + w * w)

	if len > 0 then
		len = 1 / len
	end

	return x * len, y * len, z * len, w * len
end

function MathUtil.slerpQuaternion(x1, y1, z1, w1, x2, y2, z2, w2, t)
	local fCos = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
	local fAngle = math.acos(fCos)

	if math.abs(fAngle) < 0.01 then
		return x1, y1, z1, w1
	end

	local fSin = math.sin(fAngle)
	local fInvSin = 1 / fSin
	local fCoeff0 = math.sin((1 - t) * fAngle) * fInvSin
	local fCoeff1 = math.sin(t * fAngle) * fInvSin

	return x1 * fCoeff0 + x2 * fCoeff1, y1 * fCoeff0 + y2 * fCoeff1, z1 * fCoeff0 + z2 * fCoeff1, w1 * fCoeff0 + w2 * fCoeff1
end

function MathUtil.normalizeRotationForShortestPath(targetRotation, curRotation)
	while curRotation < targetRotation do
		targetRotation = targetRotation - 2 * math.pi
	end

	while targetRotation < curRotation do
		targetRotation = targetRotation + 2 * math.pi
	end

	if targetRotation - curRotation > curRotation + 2 * math.pi - targetRotation then
		targetRotation = targetRotation - 2 * math.pi
	end

	return targetRotation
end

function MathUtil.nlerpQuaternionShortestPath(x1, y1, z1, w1, x2, y2, z2, w2, t)
	local c = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
	local x, y, z, w = nil

	if c < 0 then
		w = w1 + (-w2 - w1) * t
		z = z1 + (-z2 - z1) * t
		y = y1 + (-y2 - y1) * t
		x = x1 + (-x2 - x1) * t
	else
		w = w1 + (w2 - w1) * t
		z = z1 + (z2 - z1) * t
		y = y1 + (y2 - y1) * t
		x = x1 + (x2 - x1) * t
	end

	local len = 1 / math.sqrt(x * x + y * y + z * z + w * w)

	return x * len, y * len, z * len, w * len
end

function MathUtil.slerpQuaternionShortestPath(x1, y1, z1, w1, x2, y2, z2, w2, t)
	local fCos = x1 * x2 + y1 * y2 + z1 * z2 + w1 * w2
	local fAngle = math.acos(MathUtil.clamp(fCos, -1, 1))

	if math.abs(fAngle) < 0.01 then
		return x1, y1, z1, w1
	end

	local fSin = math.sin(fAngle)
	local fInvSin = 1 / fSin
	local fCoeff0 = math.sin((1 - t) * fAngle) * fInvSin
	local fCoeff1 = math.sin(t * fAngle) * fInvSin

	if fCos < 0 then
		fCoeff0 = -fCoeff0
		local x = x1 * fCoeff0 + x2 * fCoeff1
		local y = y1 * fCoeff0 + y2 * fCoeff1
		local z = z1 * fCoeff0 + z2 * fCoeff1
		local w = w1 * fCoeff0 + w2 * fCoeff1
		local len = 1 / math.sqrt(x * x + y * y + z * z + w * w)

		return x * len, y * len, z * len, w * len
	else
		return x1 * fCoeff0 + x2 * fCoeff1, y1 * fCoeff0 + y2 * fCoeff1, z1 * fCoeff0 + z2 * fCoeff1, w1 * fCoeff0 + w2 * fCoeff1
	end
end

function MathUtil.quaternionMadShortestPath(x, y, z, w, x1, y1, z1, w1, t)
	local c = x * x1 + y * y1 + z * z1 + w * w1

	if c < 0 then
		return x - x1 * t, y - y1 * t, z - z1 * t, w - w1 * t
	else
		return x + x1 * t, y + y1 * t, z + z1 * t, w + w1 * t
	end
end

function MathUtil.getDistanceToRectangle2D(posX, posZ, sx, sz, dx, dz, length, widthHalf)
	local d2x = -dz
	local d2z = dx
	local x = posX - sx
	local z = posZ - sz
	local lx = x * dx + z * dz
	local lz = x * d2x + z * d2z
	local distance = nil

	if lx >= 0 and lx <= length then
		distance = math.max(math.abs(lz) - widthHalf, 0)
	else
		local tx = 0

		if length < lx then
			tx = length
		end

		if widthHalf < lz then
			distance = math.sqrt((lx - tx) * (lx - tx) + (lz - widthHalf) * (lz - widthHalf))
		elseif lz < -widthHalf then
			distance = math.sqrt((lx - tx) * (lx - tx) + (lz + widthHalf) * (lz + widthHalf))
		else
			distance = math.abs(lx - tx)
		end
	end

	return distance
end

function MathUtil.getSignedDistanceToLineSegment2D(x, z, sx, sz, dx, dz, length)
	local t = (x - sx) * dx + (z - sz) * dz
	local distance, case = nil

	if t >= 0 and t <= length then
		distance = (sz - z) * dx - (sx - x) * dz
		case = 0
	elseif t < 0 then
		distance = math.sqrt((sx - x) * (sx - x) + (sz - z) * (sz - z))
		case = 1
	else
		local ex = sx + length * dx
		local ez = sz + length * dz
		distance = math.sqrt((ex - x) * (ex - x) + (ez - z) * (ez - z))
		case = 2
	end

	return distance, case
end

function MathUtil.getLineLineIntersection2D(x1, z1, dirX1, dirZ1, x2, z2, dirX2, dirZ2)
	local div = dirX1 * dirZ2 - dirX2 * dirZ1

	if math.abs(div) < 1e-05 then
		return false
	end

	local t1 = (dirX2 * (z1 - z2) - dirZ2 * (x1 - x2)) / div
	local t2 = (dirX1 * (z1 - z2) - dirZ1 * (x1 - x2)) / div

	return true, t1, t2
end

function MathUtil.getLineBoundingVolumeIntersect(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
	return math.min(ax1, ax2) <= math.max(bx1, bx2) and math.min(bx1, bx2) <= math.max(ax1, ax2) and math.min(ay1, ay2) <= math.max(by1, by2) and math.min(by1, by2) <= math.max(ay1, ay2)
end

function MathUtil.hasRectangleLineIntersection2D(x1, z1, dirX1, dirZ1, dirX2, dirZ2, x3, z3, dirX3, dirZ3)
	local dir1Length = MathUtil.vector2Length(dirX1, dirZ1)
	local dir2Length = MathUtil.vector2Length(dirX2, dirZ2)
	local dir3Length = MathUtil.vector2Length(dirX3, dirZ3)
	local dirX1_norm = dirX1 / dir1Length
	local dirZ1_norm = dirZ1 / dir1Length
	local dirX2_norm = dirX2 / dir2Length
	local dirZ2_norm = dirZ2 / dir2Length
	local dirX3_norm = dirX3 / dir3Length
	local dirZ3_norm = dirZ3 / dir3Length
	local intersects, t1, t2 = MathUtil.getLineLineIntersection2D(x3, z3, dirX3_norm, dirZ3_norm, x1, z1, dirX1_norm, dirZ1_norm)

	if intersects and t1 > 0 and t1 < dir3Length and t2 > 0 and t2 < dir1Length then
		return true
	end

	intersects, t1, t2 = MathUtil.getLineLineIntersection2D(x3, z3, dirX3_norm, dirZ3_norm, x1, z1, dirX2_norm, dirZ2_norm)

	if intersects and t1 > 0 and t1 < dir3Length and t2 > 0 and t2 < dir2Length then
		return true
	end

	intersects, t1, t2 = MathUtil.getLineLineIntersection2D(x3, z3, dirX3_norm, dirZ3_norm, x1 + dirX1, z1 + dirZ1, dirX2_norm, dirZ2_norm)

	if intersects and t1 > 0 and t1 < dir3Length and t2 > 0 and t2 < dir2Length then
		return true
	end

	intersects, t1, t2 = MathUtil.getLineLineIntersection2D(x3, z3, dirX3_norm, dirZ3_norm, x1 + dirX2, z1 + dirZ2, dirX1_norm, dirZ1_norm)

	if intersects and t1 > 0 and t1 < dir3Length and t2 > 0 and t2 < dir1Length then
		return true
	end

	local p1 = MathUtil.getProjectOnLineParameter(x3, z3, x1, z1, dirX1_norm, dirZ1_norm)
	local p2 = MathUtil.getProjectOnLineParameter(x3, z3, x1, z1, dirX2_norm, dirZ2_norm)

	if p1 > 0 and p1 < dir1Length and p2 > 0 and p2 < dir2Length then
		p1 = MathUtil.getProjectOnLineParameter(x3 + dirX3, z3 + dirZ3, x1, z1, dirX1_norm, dirZ1_norm)
		p2 = MathUtil.getProjectOnLineParameter(x3 + dirX3, z3 + dirZ3, x1, z1, dirX2_norm, dirZ2_norm)

		if p1 > 0 and p1 < dir1Length and p2 > 0 and p2 < dir2Length then
			return true
		end
	end

	return false
end

function MathUtil.getCircleCircleIntersection(x1, y1, r1, x2, y2, r2)
	local dx = x2 - x1
	local dy = y2 - y1
	local dist = MathUtil.vector2Length(dx, dy)

	if dist == 0 and x1 == x2 and y1 == y2 then
		return nil
	end

	if dist > r1 + r2 then
		return nil
	end

	if dist < math.abs(r1 - r2) then
		return nil
	end

	if dist == r1 + r2 then
		local x = (x1 - x2) / (r1 + r2) * r1 + x2
		local y = (y1 - y2) / (r1 + r2) * r1 + y2

		return x, y
	end

	local a = (r1 * r1 - r2 * r2 + dist * dist) / (2 * dist)
	local v2x = x1 + dx * a / dist
	local v2y = y1 + dy * a / dist
	local h = math.sqrt(r1 * r1 - a * a)
	local rx = -dy * h / dist
	local ry = dx * h / dist

	return v2x + rx, v2y + ry, v2x - rx, v2y - ry
end

function MathUtil.hasSphereSphereIntersection(x1, y1, z1, r1, x2, y2, z2, r2)
	local dx = x2 - x1
	local dy = y2 - y1
	local dz = z2 - z1
	local rsum = r1 + r2

	return dx * dx + dy * dy + dz * dz <= rsum * rsum
end

function MathUtil.getHasCircleLineIntersection(circleX, circleZ, radius, lineStartX, lineStartZ, lineEndX, lineEndZ)
	local n = math.abs((lineEndX - lineStartX) * (lineStartZ - circleZ) - (lineStartX - circleX) * (lineEndZ - lineStartZ))
	local d = math.sqrt((lineEndX - lineStartX) * (lineEndX - lineStartX) + (lineEndZ - lineStartZ) * (lineEndZ - lineStartZ))
	local dist = n / d

	if radius < dist then
		return false
	end

	local d1 = math.sqrt((circleX - lineStartX) * (circleX - lineStartX) + (circleZ - lineStartZ) * (circleZ - lineStartZ))

	if d < d1 - radius then
		return false
	end

	local d2 = math.sqrt((circleX - lineEndX) * (circleX - lineEndX) + (circleZ - lineEndZ) * (circleZ - lineEndZ))

	if d < d2 - radius then
		return false
	end

	return true
end

function MathUtil.getCircleLineIntersection(circleX, circleZ, radius, lineStartX, lineStartZ, lineEndX, lineEndZ)
	local p3x = lineStartX - circleX
	local p3z = lineStartZ - circleZ
	local p4x = lineEndX - circleX
	local p4z = lineEndZ - circleZ
	local m = (p4z - p3z) / (p4x - p3x)
	local b = p3z - m * p3x
	local dis = math.pow(radius, 2) * math.pow(m, 2) + math.pow(radius, 2) - math.pow(b, 2)

	if dis < 0 then
		return false
	else
		local t1 = (-m * b + math.sqrt(dis)) / (math.pow(m, 2) + 1)
		local t2 = (-m * b - math.sqrt(dis)) / (math.pow(m, 2) + 1)
		local intersect1X = t1 + circleX
		local intersect1Z = m * t1 + b + circleZ
		local intersect2X = t2 + circleX
		local intersect2Z = m * t2 + b + circleZ

		return true, intersect1X, intersect1Z, intersect2X, intersect2Z
	end
end

function MathUtil.getClosestPointOnLineSegment(startX, startY, startZ, endX, endY, endZ, targetX, targetY, targetZ)
	local dirTargetX = targetX - startX
	local dirTargetY = targetY - startY
	local dirTargetZ = targetZ - startZ
	local dirLineX = endX - startX
	local dirLineY = endY - startY
	local dirLineZ = endZ - startZ
	local lengthSq = MathUtil.vector3LengthSq(dirLineX, dirLineY, dirLineZ)
	local dot = MathUtil.dotProduct(dirTargetX, dirTargetY, dirTargetZ, dirLineX, dirLineY, dirLineZ)
	local distance = dot / lengthSq

	if distance < 0 then
		return startX, startY, startZ, 0
	elseif distance > 1 then
		return endX, endY, endZ, 1
	else
		return startX + dirLineX * distance, startY + dirLineY * distance, startZ + dirLineZ * distance, distance
	end
end

function MathUtil.getHaveLineSegementsIntersection2D(startX1, start1Z, endX1, endZ1, startX2, start2Z, endX2, endZ2)
	local denominator = (endZ2 - start2Z) * (endX1 - startX1) - (endX2 - startX2) * (endZ1 - start1Z)

	if denominator ~= 0 then
		local u_a = ((endX2 - startX2) * (start1Z - start2Z) - (endZ2 - start2Z) * (startX1 - startX2)) / denominator
		local u_b = ((endX1 - startX1) * (start1Z - start2Z) - (endZ1 - start1Z) * (startX1 - startX2)) / denominator

		if u_a >= 0 and u_a <= 1 and u_b >= 0 and u_b <= 1 then
			return true
		end
	end

	return false
end

function MathUtil.isPointInParallelogram(x, z, startX, startZ, widthX, widthZ, heightX, heightZ)
	local dirX = x - startX
	local dirZ = z - startZ
	local detA = widthX * heightZ - heightX * widthZ
	local detB = dirX * widthZ - widthX * dirZ
	local detC = dirX * heightZ - heightX * dirZ
	local n = -detB / detA

	if n >= 0 and n <= 1 then
		local m = detC / detA

		if m >= 0 and m <= 1 then
			return true
		end
	end

	return false
end

function MathUtil.getPointPointDistance(x1, y1, x2, y2)
	local dx = x1 - x2
	local dy = y1 - y2

	return math.sqrt(dx * dx + dy * dy)
end

function MathUtil.getPointPointDistanceSquared(x1, y1, x2, y2)
	local dx = x1 - x2
	local dy = y1 - y2

	return dx * dx + dy * dy
end

function MathUtil.areaToHa(area, pixelToSqm)
	return area * pixelToSqm / 10000
end

function MathUtil.inchToM(inchValue)
	return inchValue * 0.0254
end

function MathUtil.mToInch(mValue)
	return mValue / 0.0254
end

function MathUtil.msToMinutes(ms)
	return ms / 60000
end

function MathUtil.msToHours(ms)
	return ms / 3600000
end

function MathUtil.msToDays(ms)
	return ms / 86400000
end

function MathUtil.minutesToMs(minutes)
	return minutes * 60 * 1000
end

function MathUtil.hoursToMs(hours)
	return hours * 60 * 60 * 1000
end

function MathUtil.daysToMs(days)
	return days * 24 * 60 * 60 * 1000
end

function MathUtil.mpsToKmh(mps)
	return mps * 3.6
end

function MathUtil.kmhToMps(kmh)
	return kmh / 3.6
end

function MathUtil.rpmToMps(rpm, radius)
	return rpm * radius * 0.00377 / 36
end

function MathUtil.getXZWidthAndHeight(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	return startWorldX, startWorldZ, widthWorldX - startWorldX, widthWorldZ - startWorldZ, heightWorldX - startWorldX, heightWorldZ - startWorldZ
end

function MathUtil.getNumOfSetBits(bitmask)
	bitmask = bitmask - bitAND(bitShiftRight(bitmask, 1), 1431655765)
	bitmask = bitAND(bitmask, 858993459) + bitAND(bitShiftRight(bitmask, 2), 858993459)
	bitmask = bitAND(bitmask + bitShiftRight(bitmask, 4), 252645135) * 16843009

	return bitShiftRight(bitmask, 24)
end

function MathUtil.bitsToMask(...)
	local mask = 0

	for _, bit in ipairs({
		...
	}) do
		mask = bitOR(mask, math.pow(2, bit))
	end

	return mask
end

function MathUtil.getBinary(number)
	local bits = {}

	while number > 0 do
		local rest = number % 2

		table.insert(bits, rest)

		number = (number - rest) / 2
	end

	return bits
end

function MathUtil.numberToSetBits(number)
	local bits = MathUtil.getBinary(number)
	local setBits = {}

	for i, bit in ipairs(bits) do
		if bit == 1 then
			table.insert(setBits, i - 1)
		end
	end

	return setBits
end

function MathUtil.numberToSetBitsStr(number)
	local setBits = MathUtil.numberToSetBits(number)
	local returnStr = ""

	for i, bit in ipairs(setBits) do
		if i > 1 then
			returnStr = returnStr .. ", "
		end

		returnStr = returnStr .. bit
	end

	return returnStr
end

function MathUtil.getNumRequiredBits(number)
	assert(number >= 0)

	local numBits = 0

	while number > 0 do
		numBits = numBits + 1
		number = bitShiftRight(number, 1)
	end

	return math.max(1, numBits)
end

function MathUtil.getBrightnessFromColor(r, g, b)
	return r * 0.2125 + g * 0.7154 + b * 0.0721
end

function MathUtil.getHorizontalRotationFromDeviceGravity(x, y, z)
	if x == 0 and y == 0 and z == 0 then
		return 0
	end

	local angle = 0

	if x <= 0 then
		local maxAngle = 0.43633222222222223
		angle = math.atan2(y, x)

		if angle < 0 then
			angle = angle + math.pi
		else
			angle = angle - math.pi
		end

		angle = MathUtil.clamp(angle, -maxAngle, maxAngle)
		local zScale0 = 0.9
		local zScale1 = 0.65
		angle = angle * MathUtil.clamp((zScale0 - math.abs(z)) / (zScale0 - zScale1), 0, 1)
	end

	return angle
end

function MathUtil.getSteeringAngleFromDeviceGravity(x, y, z)
	if x == 0 and y == 0 and z == 0 then
		return 0
	end

	local STEER_DEADZONE = 0.06981315555555556
	local MAX_STEER_ANGLE = 0.43633222222222223
	local angle = -math.asin(MathUtil.clamp(y, -1, 1))

	if STEER_DEADZONE < angle then
		angle = math.min(angle, MAX_STEER_ANGLE) - STEER_DEADZONE
	elseif angle < -STEER_DEADZONE then
		angle = math.max(angle, -MAX_STEER_ANGLE) + STEER_DEADZONE
	else
		angle = 0
	end

	angle = angle / (MAX_STEER_ANGLE - STEER_DEADZONE)

	return angle
end

function MathUtil.catmullRom(p0, p1, p2, p3, t)
	return 0.5 * (2 * p1 + -p0 * p2 * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t)
end

function MathUtil.equalEpsilon(a, b, epsilon)
	if a == nil or b == nil then
		return false
	end

	return math.abs(a - b) < epsilon
end

function MathUtil.smoothstep(min, max, x)
	local t = MathUtil.clamp((x - min) / (max - min), 0, 1)

	return t * t * (3 - 2 * t)
end
