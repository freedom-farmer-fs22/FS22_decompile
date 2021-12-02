SplineUtil = {
	getValidSplineTime = function (t)
		return t % 1
	end
}

function SplineUtil.getSplineTimeAtWorldPos(spline, t, posX, posZ, checkDistance, maxSteps)
	local splineLength = getSplineLength(spline)
	local currentCheckDistance = checkDistance / splineLength
	local stepCounter = 0

	while true do
		local t1 = SplineUtil.getValidSplineTime(t + currentCheckDistance)
		local t2 = SplineUtil.getValidSplineTime(t - currentCheckDistance)
		local fX, _, fZ = getSplinePosition(spline, t1)
		local bX, _, bZ = getSplinePosition(spline, t2)
		local fDistance = MathUtil.vector2LengthSq(posX - fX, posZ - fZ)
		local bDistance = MathUtil.vector2LengthSq(posX - bX, posZ - bZ)
		currentCheckDistance = currentCheckDistance * 0.5

		if fDistance < bDistance then
			t = SplineUtil.getValidSplineTime(t + currentCheckDistance)
		else
			t = SplineUtil.getValidSplineTime(t - currentCheckDistance)
		end

		if maxSteps < stepCounter then
			break
		end

		stepCounter = stepCounter + 1
	end

	return t, stepCounter
end

function SplineUtil.getSplineTimeFromNode(spline, node, checkDistance)
	local closestDistance = math.huge
	local closestTime = 0

	if spline ~= nil and node ~= nil then
		local x, _, _ = getSplinePosition(spline, 0)

		if x == nil then
			Logging.error("Failed to get spline time for object '%s'", getName(spline))

			return 0
		end

		for i = 0, 1, checkDistance / getSplineLength(spline) do
			local sx, sy, sz = getSplinePosition(spline, i)

			if sx ~= nil then
				local nx, ny, nz = getWorldTranslation(node)
				local distance = MathUtil.vector3Length(sx - nx, sy - ny, sz - nz)

				if distance < closestDistance then
					closestDistance = distance
					closestTime = i
				end
			end
		end
	end

	return closestTime
end
