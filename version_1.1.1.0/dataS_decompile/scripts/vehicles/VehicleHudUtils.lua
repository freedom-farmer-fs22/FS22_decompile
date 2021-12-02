VehicleHudUtils = {}

function VehicleHudUtils.loadHud(vehicle, xmlFile, name, baseName, index)
	baseName = Utils.getNoNil(baseName, "vehicle.indoorHud")
	local i = Utils.getNoNil(index, 0)
	local huds = {}

	while true do
		local key = string.format(baseName .. "." .. name .. "(%d)", i)

		if not xmlFile:hasProperty(key) then
			break
		end

		local entry = {
			numbers = I3DUtil.indexToObject(vehicle.components, getXMLString(xmlFile, key .. "#numbers"), vehicle.i3dMappings)
		}
		colorStr = getXMLString(xmlFile, key .. "#numberColor")
		entry.numberColor = g_brandColorManager:getBrandColorByName(colorStr)

		if entry.numberColor == nil then
			entry.numberColor = string.getVectorN(colorStr, 4)
		end

		if entry.numbers ~= nil and entry.numberColor ~= nil then
			for node, _ in pairs(I3DUtil.getNodesByShaderParam(entry.numbers, "numberColor")) do
				setShaderParameter(node, "numberColor", entry.numberColor[1], entry.numberColor[2], entry.numberColor[3], 1, false)
			end
		end

		entry.animName = getXMLString(xmlFile, key .. "#animName")
		entry.visibleFunc = getXMLString(xmlFile, key .. "#visibleFunc")
		entry.inverseVisibleFunc = Utils.getNoNil(getXMLBool(xmlFile, key .. "#inverseVisibleFunc"), false)

		if entry.numbers ~= nil or entry.animName ~= nil then
			entry.minValueAnim = getXMLFloat(xmlFile, key .. "#minValueAnim")
			entry.maxValueAnim = getXMLFloat(xmlFile, key .. "#maxValueAnim")

			if entry.numbers ~= nil then
				entry.precision = Utils.getNoNil(getXMLInt(xmlFile, key .. "#precision"), 1)
				entry.numChilds = getNumOfChildren(entry.numbers)

				if entry.numChilds - entry.precision <= 0 then
					Logging.xmlWarning(xmlFile, "Not enough number meshes for vehicle hud '%s'", key)
				end

				entry.numChilds = entry.numChilds - entry.precision
				entry.maxValue = 10^entry.numChilds - 1 / 10^entry.precision
			end

			table.insert(huds, entry)
		end

		if index ~= nil then
			break
		end

		i = i + 1
	end

	if table.getn(huds) > 0 then
		VehicleHudUtils.setHudValue(vehicle, huds, 0, 1)

		return huds
	end

	return nil
end

function VehicleHudUtils.setHudValue(vehicle, huds, value, maxValue)
	for _, hud in ipairs(huds) do
		local showZero = true
		local newValue = value

		if vehicle[hud.visibleFunc] ~= nil then
			local ret = vehicle[hud.visibleFunc](vehicle)

			if ret == hud.inverseVisibleFunc then
				newValue = 0
				showZero = false
			end
		end

		if hud.numbers ~= nil then
			local displayedValue = math.min(hud.maxValue, math.max(0, newValue))
			local num = tonumber(string.format("%." .. hud.precision .. "f", displayedValue))

			I3DUtil.setNumberShaderByValue(hud.numbers, num, hud.precision, showZero)
		end

		if hud.animName ~= nil and vehicle.setAnimationTime ~= nil then
			if vehicle:getAnimationExists(hud.animName) then
				local normValue = 0

				if maxValue ~= 0 then
					if hud.minValueAnim ~= nil and hud.maxValueAnim ~= nil then
						newValue = MathUtil.clamp(newValue, hud.minValueAnim, hud.maxValueAnim)
						normValue = MathUtil.round((newValue - hud.minValueAnim) / (hud.maxValueAnim - hud.minValueAnim), 3)
					else
						normValue = MathUtil.round(newValue / maxValue, 3)
					end
				end

				vehicle:setAnimationTime(hud.animName, normValue, true)
			else
				Logging.xmlWarning(vehicle.xmlFile, "Unknown animation name '%s' for indoor hud!", hud.animName)
			end
		end
	end
end
