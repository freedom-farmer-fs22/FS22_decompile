Utils = {
	getNoNil = function (value, setTo)
		if value == nil then
			return setTo
		end

		return value
	end,
	getNoNilRad = function (valueDeg, defaultRad)
		if valueDeg == nil then
			return defaultRad
		end

		return math.rad(valueDeg)
	end,
	limitTextToWidth = function (text, textSize, width, trimFront, trimReplaceText)
		local replaceTextWidth = getTextWidth(textSize, trimReplaceText)
		local indexOfFirstCharacter = 1
		local indexOfLastCharacter = utf8Strlen(text)

		if width >= 0 then
			local totalWidth = getTextWidth(textSize, text)

			if width < totalWidth then
				if trimFront then
					indexOfFirstCharacter = getTextLineLength(textSize, text, totalWidth - width + replaceTextWidth)
					text = trimReplaceText .. utf8Substr(text, indexOfFirstCharacter)
				else
					indexOfLastCharacter = getTextLineLength(textSize, text, width - replaceTextWidth)
					text = utf8Substr(text, 0, indexOfLastCharacter) .. trimReplaceText
				end
			end
		end

		return text, indexOfFirstCharacter, indexOfLastCharacter
	end,
	getMovedLimitedValue = function (curVal, maxVal, minVal, speed, dt, inverted)
		local limitF = math.min
		local limitF2 = math.max

		if inverted then
			minVal = maxVal
			maxVal = minVal
		end

		if maxVal < minVal then
			limitF = math.max
			limitF2 = math.min
		end

		return limitF2(limitF(curVal + (maxVal - minVal) / speed * dt, maxVal), minVal)
	end
}

function Utils.getMovedLimitedValues(currentValues, maxValues, minValues, numValues, speed, dt, inverted)
	local ret = {}

	for i = 1, numValues do
		ret[i] = Utils.getMovedLimitedValue(currentValues[i], maxValues[i], minValues[i], speed, dt, inverted)
	end

	return ret
end

function Utils.setMovedLimitedValues(values, maxValues, minValues, numValues, speed, dt, inverted)
	local changed = false

	for i = 1, numValues do
		local newValue = Utils.getMovedLimitedValue(values[i], maxValues[i], minValues[i], speed, dt, inverted)

		if newValue ~= values[i] then
			changed = true
			values[i] = newValue
		end
	end

	return changed
end

function Utils.removeModDirectory(filename)
	local isMod = false
	local isDlc = false
	local dlcsDirectoryIndex = 0

	if filename == nil then
		printCallstack()
	end

	local filenameLower = filename:lower()

	if g_modsDirectory then
		local modsDirLen = g_modsDirectory:len()
		local modsDirLower = g_modsDirectory:lower()

		if filenameLower:sub(1, modsDirLen) == modsDirLower then
			filename = filename:sub(modsDirLen + 1)
			isMod = true
		end
	end

	if not isMod then
		for i = 1, #g_dlcsDirectories do
			local dlcsDir = g_dlcsDirectories[i].path:lower()
			local dlcsDirLen = dlcsDir:len()

			if filenameLower:sub(1, dlcsDirLen) == dlcsDir then
				filename = filename:sub(dlcsDirLen + 1)
				dlcsDirectoryIndex = i
				isDlc = true

				break
			end
		end
	end

	return filename, isMod, isDlc, dlcsDirectoryIndex
end

function Utils.getModNameAndBaseDirectory(filename)
	local modName = nil
	local baseDirectory = ""
	local modFilename, isMod, isDlc, dlcsDirectoryIndex = Utils.removeModDirectory(filename)

	if isMod or isDlc then
		local f, l = modFilename:find("/")

		if f ~= nil and l ~= nil and f > 1 then
			modName = modFilename:sub(1, f - 1)

			if isDlc then
				baseDirectory = g_dlcsDirectories[dlcsDirectoryIndex].path .. modName .. "/"

				if g_dlcModNameHasPrefix[modName] then
					modName = g_uniqueDlcNamePrefix .. modName
				end
			else
				baseDirectory = g_modsDirectory .. modName .. "/"
			end
		end
	end

	return modName, baseDirectory
end

function Utils.getVersatileRotation(repr, componentNode, dt, posX, posY, posZ, currentAngle, minAngle, maxAngle)
	local vx, vy, vz = getVelocityAtLocalPos(componentNode, posX, posY, posZ)
	local x, _, z = worldDirectionToLocal(getParent(repr), vx, vy, vz)
	local length = MathUtil.vector2Length(x, z)
	local steeringAngle = currentAngle

	if length > 0.15 then
		steeringAngle = math.atan2(x / length, z / length)

		if steeringAngle < -math.pi * 0.5 then
			steeringAngle = steeringAngle + 2 * math.pi
		end
	end

	if minAngle ~= nil and minAngle ~= 0 and maxAngle ~= nil and maxAngle ~= 0 then
		if maxAngle < steeringAngle then
			steeringAngle = maxAngle
		elseif steeringAngle < minAngle then
			steeringAngle = minAngle
		end
	end

	steeringAngle = MathUtil.normalizeRotationForShortestPath(steeringAngle, currentAngle)

	if currentAngle < steeringAngle then
		steeringAngle = math.min(currentAngle + 0.003 * dt, steeringAngle)
	else
		steeringAngle = math.max(currentAngle - 0.003 * dt, steeringAngle)
	end

	return steeringAngle
end

function Utils.getYRotationBetweenNodes(node1, node2, offset1, offset2)
	local dirX1 = 0
	local dirZ1 = 1
	local dirX2 = 0
	local dirZ2 = 1

	if offset1 ~= nil and offset1 ~= 0 then
		dirX1, dirZ1 = MathUtil.getDirectionFromYRotation(offset1)
	end

	if offset2 ~= nil and offset2 ~= 0 then
		dirX2, dirZ2 = MathUtil.getDirectionFromYRotation(offset2)
	end

	local wDirX1, _, wDirZ1 = localDirectionToWorld(node1, dirX1, 0, dirZ1)
	local wDirX2, _, wDirZ2 = localDirectionToWorld(node2, dirX2, 0, dirZ2)
	wDirX1, _, wDirZ1 = worldDirectionToLocal(node1, wDirX1, 0, wDirZ1)
	wDirX2, _, wDirZ2 = worldDirectionToLocal(node1, wDirX2, 0, wDirZ2)
	local dir = 1

	if wDirX1 - wDirX2 > 0 then
		dir = -dir
	end

	return MathUtil.getVectorAngleDifference(wDirX1, 0, wDirZ1, wDirX2, 0, wDirZ2) * dir
end

function Utils.getPerformanceClassIndex(profileClass)
	profileClass = profileClass:lower()
	local currentProfileIndex = GS_PROFILE_LOW

	if profileClass == "medium" then
		currentProfileIndex = GS_PROFILE_MEDIUM
	elseif profileClass == "high" then
		currentProfileIndex = GS_PROFILE_HIGH
	elseif profileClass == "very high" then
		currentProfileIndex = GS_PROFILE_VERY_HIGH
	end

	return currentProfileIndex
end

function Utils.getPerformanceClassFromIndex(profileClassIndex)
	local currentProfileClass = "Low"

	if profileClassIndex == GS_PROFILE_MEDIUM then
		currentProfileClass = "Medium"
	elseif profileClassIndex == GS_PROFILE_HIGH then
		currentProfileClass = "High"
	elseif profileClassIndex == GS_PROFILE_VERY_HIGH then
		currentProfileClass = "Very High"
	end

	return currentProfileClass
end

function Utils.getPerformanceClassId()
	return Utils.getPerformanceClassIndex(getPerformanceClass())
end

function Utils.getStateFromValues(values, steps, value)
	local state = #values

	for i = 1, #values do
		if value <= values[i] + steps * 0.5 then
			state = i

			break
		end
	end

	return state
end

function Utils.getValueIndex(targetValue, values)
	local index = 1
	local threshold = 0.0001

	for k, val in pairs(values) do
		if targetValue < val - threshold then
			break
		end

		index = k
	end

	return index
end

function Utils.getNumTimeScales()
	local timeScaleDevSettings = Platform.gameplay.timeScaleDevSettings
	local timeScaleSettings = Platform.gameplay.timeScaleSettings

	if g_addTestCommands and not g_isPresentationVersion then
		return #timeScaleSettings + #timeScaleDevSettings
	else
		return #timeScaleSettings
	end
end

function Utils.getTimeScaleString(timeScaleIndex)
	local timeScaleSettings = Platform.gameplay.timeScaleSettings
	local speed = Utils.getTimeScaleFromIndex(timeScaleIndex)

	if speed == 1 then
		return g_i18n:getText("ui_realTime")
	elseif timeScaleIndex > #timeScaleSettings then
		return string.format("%dx (dev only)", speed)
	elseif speed < 1 then
		return string.format("%0.2fx", speed)
	else
		return string.format("%dx", speed)
	end
end

function Utils.getTimeScaleIndex(timeScale)
	local timeScaleDevSettings = Platform.gameplay.timeScaleDevSettings
	local timeScaleSettings = Platform.gameplay.timeScaleSettings

	if g_addTestCommands and not g_isPresentationVersion then
		for i = #timeScaleDevSettings, 1, -1 do
			if timeScaleDevSettings[i] <= timeScale then
				return i + #timeScaleSettings
			end
		end
	end

	for i = #timeScaleSettings, 1, -1 do
		if timeScaleSettings[i] <= timeScale then
			return i
		end
	end

	return 3
end

function Utils.getTimeScaleFromIndex(timeScaleIndex)
	local timeScaleDevSettings = Platform.gameplay.timeScaleDevSettings
	local timeScaleSettings = Platform.gameplay.timeScaleSettings
	timeScaleIndex = math.max(timeScaleIndex, 1)

	if g_addTestCommands and not g_isPresentationVersion and timeScaleIndex > #timeScaleSettings then
		return timeScaleDevSettings[timeScaleIndex - #timeScaleSettings]
	end

	return timeScaleSettings[timeScaleIndex]
end

function Utils.getMasterVolumeIndex(masterVolume)
	masterVolume = masterVolume + 0.01
	local masterVolumeIndex = 1

	if masterVolume >= 1 then
		masterVolumeIndex = 11
	elseif masterVolume >= 0.9 then
		masterVolumeIndex = 10
	elseif masterVolume >= 0.8 then
		masterVolumeIndex = 9
	elseif masterVolume >= 0.7 then
		masterVolumeIndex = 8
	elseif masterVolume >= 0.6 then
		masterVolumeIndex = 7
	elseif masterVolume >= 0.5 then
		masterVolumeIndex = 6
	elseif masterVolume >= 0.4 then
		masterVolumeIndex = 5
	elseif masterVolume >= 0.3 then
		masterVolumeIndex = 4
	elseif masterVolume >= 0.2 then
		masterVolumeIndex = 3
	elseif masterVolume >= 0.1 then
		masterVolumeIndex = 2
	end

	return masterVolumeIndex
end

function Utils.getMasterVolumeFromIndex(masterVolumeIndex)
	if masterVolumeIndex >= 1 and masterVolumeIndex <= 10 then
		return (masterVolumeIndex - 1) * 0.1
	else
		return 1
	end
end

function Utils.getUIScaleIndex(uiScale)
	uiScale = uiScale + 0.01
	local uiScaleIndex = 1

	if uiScale >= 1.25 then
		uiScaleIndex = 16
	elseif uiScale >= 1.2 then
		uiScaleIndex = 15
	elseif uiScale >= 1.15 then
		uiScaleIndex = 14
	elseif uiScale >= 1.1 then
		uiScaleIndex = 13
	elseif uiScale >= 1.05 then
		uiScaleIndex = 12
	elseif uiScale >= 1 then
		uiScaleIndex = 11
	elseif uiScale >= 0.95 then
		uiScaleIndex = 10
	elseif uiScale >= 0.9 then
		uiScaleIndex = 9
	elseif uiScale >= 0.85 then
		uiScaleIndex = 8
	elseif uiScale >= 0.8 then
		uiScaleIndex = 7
	elseif uiScale >= 0.75 then
		uiScaleIndex = 6
	elseif uiScale >= 0.7 then
		uiScaleIndex = 5
	elseif uiScale >= 0.65 then
		uiScaleIndex = 4
	elseif uiScale >= 0.6 then
		uiScaleIndex = 3
	elseif uiScale >= 0.55 then
		uiScaleIndex = 2
	end

	return uiScaleIndex
end

function Utils.getUIScaleFromIndex(uiScaleIndex)
	if uiScaleIndex >= 1 and uiScaleIndex <= 16 then
		return (uiScaleIndex - 1) * 0.05 + 0.5
	else
		return 1
	end
end

function Utils.getRecordingVolumeIndex(volume)
	volume = volume + 0.01

	if volume >= 1.5 then
		return 12
	elseif volume >= 1.4 then
		return 11
	elseif volume >= 1.3 then
		return 10
	elseif volume >= 1.2 then
		return 9
	elseif volume >= 1.1 then
		return 8
	elseif volume >= 1 then
		return 7
	elseif volume >= 0.9 then
		return 6
	elseif volume >= 0.8 then
		return 5
	elseif volume >= 0.7 then
		return 4
	elseif volume >= 0.6 then
		return 3
	elseif volume > 0 then
		return 2
	else
		return 1
	end
end

function Utils.getRecordingVolumeFromIndex(index)
	if index == 1 then
		return -1
	else
		return (index - 2) * 0.1 + 0.5
	end
end

function Utils.getFilename(filename, baseDir)
	if filename == nil then
		printCallstack()

		return nil
	end

	if type(filename) == "boolean" then
		printCallstack()
	end

	if filename:sub(1, 1) == "$" then
		return filename:sub(2), false
	elseif baseDir == nil or baseDir == "" then
		return filename, false
	elseif filename == "" then
		return filename, true
	end

	return baseDir .. filename, true
end

function Utils.getFilenameFromPath(path)
	path = path:gsub("\\", "/")
	local elems = path:split("/")

	return elems[#elems]
end

function Utils.getMaxJointForceLimit(forceLimit1, forceLimit2)
	if forceLimit1 < 0 or forceLimit2 < 0 then
		return -1
	end

	return math.max(forceLimit1, forceLimit2)
end

function Utils.appendedFunction(oldFunc, newFunc)
	if oldFunc ~= nil then
		return function (...)
			oldFunc(...)
			newFunc(...)
		end
	else
		return newFunc
	end
end

function Utils.prependedFunction(oldFunc, newFunc)
	if oldFunc ~= nil then
		return function (...)
			newFunc(...)
			oldFunc(...)
		end
	else
		return newFunc
	end
end

function Utils.overwrittenFunction(oldFunc, newFunc)
	if oldFunc ~= nil then
		return function (self, ...)
			return newFunc(self, oldFunc, ...)
		end
	else
		return function (self, ...)
			return newFunc(self, nil, ...)
		end
	end
end

function Utils.shuffle(t)
	local n = #t

	while n > 2 do
		local k = math.random(n)
		t[k] = t[n]
		t[n] = t[k]
		n = n - 1
	end

	return t
end

function Utils.get2DArray(str)
	if str ~= nil then
		local parts = str:split(" ")
		local x, y = unpack(parts)

		if x ~= nil and y ~= nil then
			return {
				Utils.evaluateFormula(x),
				Utils.evaluateFormula(y)
			}
		end
	end

	return nil
end

function Utils.getFilenameInfo(filename, excludePath)
	local cleanFilename = filename
	local pos, _, extension = string.find(filename, "([^.]*)$")

	if pos == 1 then
		extension = nil
	else
		cleanFilename = string.sub(filename, 1, pos - 2)

		if excludePath ~= nil and excludePath then
			local lastSlash = cleanFilename:find("/[^/]*$")
			cleanFilename = string.sub(cleanFilename, lastSlash + 1)
		end
	end

	return cleanFilename, extension
end

function Utils.stringToBoolean(value)
	local ret = value ~= nil and value:lower() == "true"

	return ret
end

function Utils.getMinuteOfDayFromTime(value)
	if value ~= nil then
		local sepPos = string.find(value, ":")

		if sepPos ~= nil then
			local hours = tonumber(string.sub(value, 0, sepPos - 1))
			local minutes = tonumber(string.sub(value, sepPos + 1))

			if hours ~= nil and minutes ~= nil and hours <= 24 and minutes < 60 then
				return hours * 60 + minutes
			end
		end
	end

	return nil
end

function Utils.formatTime(timeInMinutes)
	local timeHoursF = timeInMinutes / 60 + 0.0001
	local timeHours = math.floor(timeHoursF)
	local timeMinutes = math.floor((timeHoursF - timeHours) * 60)

	return string.format("%02d:%02d", timeHours, timeMinutes)
end

function Utils.renderMultiColumnText(x, y, textSize, texts, spacingX, aligns)
	for i, text in ipairs(texts) do
		local align = aligns ~= nil and aligns[i] or RenderText.ALIGN_LEFT

		setTextAlignment(align)

		local w = getTextWidth(textSize, text)

		if align == RenderText.ALIGN_RIGHT then
			renderText(x + w, y, textSize, text)
		elseif align == RenderText.ALIGN_CENTER then
			renderText(x + w * 0.5, y, textSize, text)
		else
			renderText(x, y, textSize, text)
		end

		x = x + w + spacingX
	end

	setTextAlignment(RenderText.ALIGN_LEFT)
end

function Utils.getCoinToss()
	return math.random() >= 0.5
end

function Utils.getNormallyDistributedRandomVariables(mean, sigmaSq)
	local u, v = nil
	local q = -1

	while q >= 1 or q <= 0 do
		u = -1 + 2 * math.random()
		v = -1 + 2 * math.random()
		q = u^2 + v^2
	end

	local p = math.sqrt(-2 * math.log(q) / math.log(math.exp(1)) / q)
	local x1 = u * p
	local x2 = v * p
	local sigma = math.sqrt(sigmaSq)

	return mean + sigma * x1, mean + sigma * x2
end

function Utils.getIntersectionOfLinearMovementAndTerrain(node, speed)
	local cx, cy, cz = nil
	local x0, y0, z0 = getWorldTranslation(node)
	local dx, dy, dz = localDirectionToWorld(node, 0, -1, 0)
	local vx = dx * speed
	local vy = dy * speed
	local vz = dz * speed
	local stepT = 1 / speed
	local maxT = 50 / speed

	for t = 2 * stepT, maxT, stepT do
		local x = x0 + vx * t
		local z = z0 + vz * t
		local y = y0 + vy * t - 4.905 * t * t
		local h = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)

		if y <= h then
			cx = x
			cy = h
			cz = z

			break
		end

		if VehicleDebug.state == VehicleDebug.DEBUG then
			drawDebugPoint(x, y, z, 0, 0, 1, 1)
		end
	end

	return cx, cy, cz
end

function Utils.clearBit(bitMask, bit)
	local bitFlag = 2^bit

	return bitAND(bitMask, bitNOT(bitFlag))
end

function Utils.setBit(bitMask, bit)
	local bitFlag = 2^bit

	return bitOR(bitMask, bitFlag)
end

function Utils.isBitSet(bitMask, bit)
	local bitFlag = 2^bit

	return bitAND(bitMask, bitFlag) ~= 0
end

function Utils.evaluateFormula(str)
	if str == nil then
		printCallstack()
	end

	if str:find("[_%a]") == nil then
		local f = loadstring("g_asd_tempMathValue = " .. str)

		if f ~= nil then
			f()

			str = g_asd_tempMathValue
			g_asd_tempMathValue = nil
		end
	end

	return tonumber(str)
end

function Utils.randomFloat(lowerValue, upperValue)
	return lowerValue + math.random() * (upperValue - lowerValue)
end

function Utils.renderTextAtWorldPosition(x, y, z, text, textSize, textOffset, color)
	local sx, sy, sz = project(x, y, z)
	color = color or {
		0.5,
		1,
		0.5,
		1
	}

	if sx > -1 and sx < 2 and sy > -1 and sy < 2 and sz <= 1 then
		local r, g, b, a = unpack(color)

		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextBold(false)
		setTextColor(0, 0, 0, 0.75)
		renderText(sx, sy - 0.0015 + textOffset, textSize, text)
		setTextColor(r, g, b, a or 1)
		renderText(sx, sy + textOffset, textSize, text)
		setTextAlignment(RenderText.ALIGN_LEFT)
		setTextColor(1, 1, 1, 1)
	end
end

function Utils.getGreenRedBlendedColor(factor)
	local r = math.min(2 * factor, 1)
	local g = math.min(2 * (1 - factor), 1)

	return r, g, 0, 1
end
