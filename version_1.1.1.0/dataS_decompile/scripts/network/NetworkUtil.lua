NetworkUtil = {
	BIT_TYPE_TO_NUM_BITS = {
		11,
		16,
		20,
		32
	},
	getObject = function (id)
		if g_server ~= nil then
			return g_server:getObject(id)
		else
			return g_client:getObject(id)
		end
	end,
	getObjectId = function (object)
		if g_server ~= nil then
			return g_server:getObjectId(object)
		else
			return g_client:getObjectId(object)
		end
	end
}

function NetworkUtil.writeNodeObject(streamId, object)
	NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(object))
end

function NetworkUtil.readNodeObject(streamId)
	return NetworkUtil.getObject(NetworkUtil.readNodeObjectId(streamId))
end

function NetworkUtil.writeNodeObjectId(streamId, objectId)
	streamWriteUIntN(streamId, Utils.getNoNil(objectId, 0), NetworkNode.OBJECT_SEND_NUM_BITS)
end

function NetworkUtil.readNodeObjectId(streamId)
	return streamReadUIntN(streamId, NetworkNode.OBJECT_SEND_NUM_BITS)
end

function NetworkUtil.simWriteCompressed2DVectors(refX, refY, values, scale, addRefPoint)
	if scale == nil then
		scale = 0.01
	end

	local invScale = 1 / scale
	local numValues = table.getn(values)
	local bitType = 0

	for i = 1, numValues do
		local dx = values[i].x - refX
		local dy = values[i].y - refY
		local len = math.sqrt(dx * dx + dy * dy) * invScale

		if len < 1024 then
			bitType = math.max(bitType, 0)
		elseif len < 32768 then
			bitType = math.max(bitType, 1)
		elseif len < 524288 then
			bitType = math.max(bitType, 2)
		else
			bitType = math.max(bitType, 3)
		end
	end

	local ret = {}

	if addRefPoint then
		table.insert(ret, {
			x = refX,
			y = refY
		})
	end

	if bitType ~= 3 then
		for i = 1, numValues do
			local dx = values[i].x - refX
			local dy = values[i].y - refY
			local x = math.floor(dx * invScale)
			local y = math.floor(dy * invScale)
			x = refX + x * scale
			y = refY + y * scale

			table.insert(ret, {
				x = x,
				y = y
			})
		end
	else
		for i = 1, numValues do
			table.insert(ret, {
				x = values[i].x,
				y = values[i].y
			})
		end
	end

	return ret, bitType
end

function NetworkUtil.writeCompressed2DVectors(streamId, refX, refY, values, scale, bitType)
	if scale == nil then
		scale = 0.01
	end

	local invScale = 1 / scale
	local numValues = table.getn(values)

	if numValues > 0 then
		if bitType == nil then
			bitType = 0

			for i = 1, numValues do
				local dx = values[i].x - refX
				local dy = values[i].y - refY
				local len = math.sqrt(dx * dx + dy * dy) * invScale

				if len < 1024 then
					bitType = math.max(bitType, 0)
				elseif len < 32768 then
					bitType = math.max(bitType, 1)
				elseif len < 524288 then
					bitType = math.max(bitType, 2)
				else
					bitType = math.max(bitType, 3)
				end
			end
		end

		streamWriteUIntN(streamId, bitType, 2)

		if bitType ~= 3 then
			local numBits = Utils.BIT_TYPE_TO_NUM_BITS[bitType + 1]

			for i = 1, numValues do
				local dx = values[i].x - refX
				local dy = values[i].y - refY

				streamWriteIntN(streamId, math.floor(dx * invScale), numBits)
				streamWriteIntN(streamId, math.floor(dy * invScale), numBits)
			end
		else
			for i = 1, numValues do
				streamWriteFloat32(streamId, values[i].x)
				streamWriteFloat32(streamId, values[i].y)
			end
		end
	end
end

function NetworkUtil.readCompressed2DVectors(streamId, refX, refY, numValues, scale, addRefPoint)
	if scale == nil then
		scale = 0.01
	end

	local ret = {}

	if addRefPoint then
		table.insert(ret, {
			x = refX,
			y = refY
		})
	end

	if numValues > 0 then
		local bitType = streamReadUIntN(streamId, 2)

		if bitType ~= 3 then
			local numBits = Utils.BIT_TYPE_TO_NUM_BITS[bitType + 1]

			for i = 1, numValues do
				local x = streamReadIntN(streamId, numBits)
				local y = streamReadIntN(streamId, numBits)
				x = refX + x * scale
				y = refY + y * scale

				table.insert(ret, {
					x = x,
					y = y
				})
			end
		else
			for i = 1, numValues do
				local x = streamReadFloat32(streamId)
				local y = streamReadFloat32(streamId)

				table.insert(ret, {
					x = x,
					y = y
				})
			end
		end
	end

	return ret
end

function NetworkUtil.createWorldPositionCompressionParams(worldSize, worldOffset, scale)
	local params = {
		scale = scale,
		worldSize = worldSize,
		worldOffset = worldOffset
	}
	local maxValueScaled = worldSize / scale
	local numBits = 32
	local curMax = 2

	for i = 1, 32 do
		if maxValueScaled <= curMax then
			numBits = i

			break
		end

		curMax = curMax * 2
	end

	params.numBits = numBits

	return params
end

function NetworkUtil.simWriteCompressedWorldPosition(pos, params)
	local scaledPos = math.min(math.max(pos + params.worldOffset, 0), params.worldSize) / params.scale

	return math.floor(scaledPos) * params.scale - params.worldOffset
end

function NetworkUtil.writeCompressedWorldPosition(streamId, pos, params)
	local scaledPos = math.min(math.max(pos + params.worldOffset, 0), params.worldSize) / params.scale

	streamWriteUIntN(streamId, math.floor(scaledPos), params.numBits)
end

function NetworkUtil.getIsWorldPositionInCompressionRange(pos, params)
	return pos >= -params.worldOffset and pos <= params.worldSize - params.worldOffset
end

function NetworkUtil.readCompressedWorldPosition(streamId, params)
	return streamReadUIntN(streamId, params.numBits) * params.scale - params.worldOffset
end

function NetworkUtil.writeCompressedAngle(streamId, angle)
	angle = angle % (2 * math.pi)

	assert(angle >= 0 and angle <= 2 * math.pi)
	streamWriteUIntN(streamId, math.floor(angle * 2047.5 / math.pi), 12)
end

function NetworkUtil.readCompressedAngle(streamId)
	local angle = streamReadUIntN(streamId, 12) / 2047.5 * math.pi

	return angle
end

function NetworkUtil.writeCompressedRange(streamId, value, minValue, maxValue, numBits)
	local maxSendValue = 2^numBits - 1
	value = (math.min(math.max(value, minValue), maxValue) - minValue) / (maxValue - minValue)

	streamWriteUIntN(streamId, math.floor(value * maxSendValue), numBits)
end

function NetworkUtil.readCompressedRange(streamId, minValue, maxValue, numBits)
	local maxSendValue = 2^numBits - 1
	local value = streamReadUIntN(streamId, numBits) / maxSendValue * (maxValue - minValue) + minValue

	return value
end

function NetworkUtil.writeCompressedPercentages(streamId, floatValue, numBits)
	local maxBitValue = 2^numBits - 1
	local value = MathUtil.clamp(floatValue * maxBitValue, 0, maxBitValue)

	streamWriteUIntN(streamId, value, numBits)
end

function NetworkUtil.readCompressedPercentages(streamId, numBits)
	local value = streamReadUIntN(streamId, numBits)
	local maxBitValue = 2^numBits - 1

	return value / maxBitValue
end

function NetworkUtil.convertToNetworkFilename(filename)
	local modFilename, isMod, isDlc, _ = Utils.removeModDirectory(filename:trim())

	if isMod then
		filename = "$moddir$" .. modFilename
	elseif isDlc then
		filename = "$pdlcdir$" .. modFilename
	end

	return filename
end

function NetworkUtil.convertFromNetworkFilename(filename)
	local filenameLower = filename:lower()
	local modPrefix = "$moddir$"
	local mapPrefix = "$mapdir$"

	if string.startsWith(filenameLower, modPrefix) then
		local startIndex = modPrefix:len() + 1
		local modName = filename
		local f, l = filename:find("/", startIndex)

		if f ~= nil and l ~= nil and startIndex < f - 1 then
			modName = filename:sub(startIndex, f - 1)
		end

		local modDir = g_modNameToDirectory[modName]

		if modDir ~= nil then
			filename = modDir .. filename:sub(f + 1)
		else
			filename = g_modsDirectory .. modName
		end
	elseif string.startsWith(filenameLower, mapPrefix) then
		local mapDir = g_currentMission.missionInfo.baseDirectory
		local startIndex = mapPrefix:len() + 1
		filename = Utils.getFilename(filename:sub(startIndex + 1), mapDir)
	else
		local pdlcPrefix = "$pdlcdir"

		if string.startsWith(filenameLower, pdlcPrefix) then
			local startIndex = nil
			local prefixIndex = pdlcPrefix:len() + 1

			if filenameLower:sub(prefixIndex, prefixIndex) == "$" then
				startIndex = prefixIndex + 1
			else
				prefixIndex = prefixIndex + 1

				if filenameLower:sub(prefixIndex, prefixIndex) == "$" then
					startIndex = prefixIndex + 1
				end
			end

			if startIndex ~= nil then
				local f, l = filename:find("/", startIndex)

				if f ~= nil and l ~= nil and startIndex < f - 1 then
					local modName = filename:sub(startIndex, f - 1)

					if g_dlcModNameHasPrefix[modName] then
						modName = g_uniqueDlcNamePrefix .. modName
					end

					local modDir = g_modNameToDirectory[modName]

					if modDir ~= nil then
						filename = modDir .. filename:sub(f + 1)
					end
				end
			end
		end
	end

	return filename
end

function NetworkUtil.packBits(...)
	local args = {
		...
	}
	local result = 0

	for i = 1, table.getn(args) do
		local currentBit = args[i]

		if currentBit then
			result = result + 2^(i - 1)
		end
	end

	return result
end

local function calculateBitVectorArity(number)
	assert(number >= 0)

	local n = 1
	local arity = 1

	while n <= number do
		n = 2 * n
		arity = arity + 1
	end

	arity = arity - 1

	return arity
end

function NetworkUtil.readBits(number, arity)
	if arity == nil then
		if number == 0 then
			return
		end

		arity = calculateBitVectorArity(number)
	end

	local result = {}

	for i = arity, 1, -1 do
		local value = 2^(i - 1)
		local isBitSet = number >= value
		result[i] = isBitSet

		if isBitSet then
			number = number - value
		end
	end

	return result
end

function NetworkUtil.readBit(number, bitPosition, arity)
	if arity == nil then
		if number == 0 then
			return
		end

		arity = calculateBitVectorArity(number)
	end

	for i = arity - 1, bitPosition + 1, -1 do
		local value = 2^i
		local isBitSet = number >= value

		if isBitSet then
			number = number - value
		end
	end

	local value = 2^bitPosition

	return number >= value
end

function NetworkUtil.writeBit(number, bitPosition, bitValue, arity)
	if arity == nil then
		if number == 0 then
			return
		end

		arity = calculateBitVectorArity(number)
	end

	local isBitSet = NetworkUtil.readBit(number, bitPosition, arity)
	local bitNumber = 2^bitPosition

	if isBitSet then
		number = number - bitNumber
	end

	if bitValue then
		number = number + bitNumber
	end

	return number
end

function NetworkUtil.writeCompressedColor(streamId, r, g, b)
	streamWriteUInt8(streamId, r * 255)
	streamWriteUInt8(streamId, g * 255)
	streamWriteUInt8(streamId, b * 255)
end

function NetworkUtil.readCompressedColor(streamId)
	local r = streamReadUInt8(streamId) / 255
	local g = streamReadUInt8(streamId) / 255
	local b = streamReadUInt8(streamId) / 255

	return r, g, b
end
