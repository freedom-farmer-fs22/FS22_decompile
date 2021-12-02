function string.getVector(str)
	if str == nil then
		return nil
	end

	local vals = str:trim():split(" ")

	for i = 1, #vals do
		vals[i] = vals[i] == "-" and 0 or tonumber(vals[i])
	end

	return unpack(vals)
end

function string.getVectorN(str, num)
	if str == nil then
		return nil
	end

	local vals = str:trim():split(" ")
	num = num or #vals

	if num == 0 then
		return nil
	end

	if #vals ~= num then
		print("Error: Invalid " .. num .. "-vector '" .. str .. "'")

		return nil
	end

	local results = {}

	for i = 1, num do
		table.insert(results, vals[i] == "-" and 0 or tonumber(vals[i]))
	end

	return results
end

function string.getRadians(str, num)
	local results = str:getVectorN(num)

	if results ~= nil then
		for i = 1, #results do
			results[i] = math.rad(results[i] or 0)
		end
	end

	return results
end

function string.parseList(str, pattern, lambda)
	local results = str:split(pattern)

	if results ~= nil then
		for i = 1, #results do
			results[i] = lambda(results[i])
		end
	end

	return results
end

function string.split(str, pattern)
	local results = {}

	if str ~= nil and str ~= "" then
		local start = 1
		local splitStart, splitEnd = string.find(str, pattern, start, true)

		while splitStart ~= nil do
			table.insert(results, string.sub(str, start, splitStart - 1))

			start = splitEnd + 1
			splitStart, splitEnd = string.find(str, pattern, start, true)
		end

		table.insert(results, string.sub(str, start))
	end

	return results
end

function string.startsWith(str, find)
	return str:sub(1, find:len()) == find
end

function string.endsWith(str, find)
	return str:sub(str:len() - find:len() + 1) == find
end

function string.trim(str)
	local n = str:find("%S")

	return n and str:match(".*%S", n) or ""
end

function string.findLast(str, find)
	local strLength = string.len(str)
	local lastOccurrence = 0

	while strLength > lastOccurrence do
		local lastIndex = str:find(find, lastOccurrence + 1)

		if lastIndex == nil then
			break
		else
			lastOccurrence = lastIndex
		end
	end

	return lastOccurrence
end

function string.contains(str, pattern)
	return str:find(pattern) ~= nil
end

function string.combine(items, joinStr, skipStr)
	local result = ""

	for i = 1, #items do
		if items[i] ~= skipStr then
			if result ~= "" then
				result = result .. joinStr
			end

			result = result .. items[i]
		end
	end

	return result
end

function string.toList(str, pattern)
	local list = {}
	pattern = pattern or "."

	for c in str:gmatch(pattern) do
		table.insert(list, c)
	end

	return list
end

function string.maskToFormat(textMask)
	textMask = textMask:gsub("%%", "=")
	local textFormatStr = ""
	local textFormatPrecision = 0
	local isLeadingNumber = true
	local numDigits = 0

	for i = 1, textMask:len() do
		if textMask:sub(i, i) == "0" then
			numDigits = numDigits + 1
		else
			if numDigits > 0 then
				textFormatStr = textFormatStr .. string.format(isLeadingNumber and "%%%dd" or "%%0%dd", numDigits)
				textFormatPrecision = numDigits
				numDigits = 0
				isLeadingNumber = false
			end

			textFormatStr = textFormatStr .. textMask:sub(i, i)
		end
	end

	if numDigits > 0 then
		textFormatStr = textFormatStr .. string.format(isLeadingNumber and "%%%dd" or "%%0%dd", numDigits)
		textFormatPrecision = numDigits
	end

	textFormatStr = textFormatStr:gsub("=", "%%%%")

	return textFormatStr, textFormatPrecision
end

StringUtil = {}
local mt = {
	__index = function ()
		printCallstack()
		print("StringUtil is obsolete! (replaced by: string.getVector, string.getVectorN, string.getRadians, string.parseList, string.split, string.startsWith, string.endsWith, string.trim, string.findLast, string.contains)")
	end
}

setmetatable(StringUtil, mt)
