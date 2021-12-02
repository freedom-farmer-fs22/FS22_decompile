function table.addElement(t, newElement)
	if t ~= nil and newElement ~= nil then
		for k, element in ipairs(t) do
			if element == newElement then
				return false, k
			end
		end

		t[#t + 1] = newElement

		return true, #t
	end

	return false, -1
end

function table.removeElement(list, element)
	if list ~= nil and element ~= nil then
		for i, v in ipairs(list) do
			if v == element then
				table.remove(list, i)

				return true
			end
		end
	end

	return false
end

function table.clear(t)
	for index, _ in pairs(t) do
		t[index] = nil
	end
end

function table.copy(sourceTable, depth)
	if sourceTable == nil then
		return nil
	end

	depth = (depth or 1) - 1
	local newTable = {}

	for key, value in pairs(sourceTable) do
		if type(value) == "table" and depth > 0 then
			newTable[key] = table.copy(value, depth)
		else
			newTable[key] = value
		end
	end

	return setmetatable(newTable, getmetatable(sourceTable))
end

function table.copyIndex(sourceTable)
	if sourceTable == nil then
		return nil
	end

	local newTable = {}

	for i = 1, #sourceTable do
		newTable[i] = sourceTable[i]
	end

	return newTable
end

function table.getRandomElement(t)
	return t[math.random(#t)]
end

function table.ifilter(list, closure)
	local result = {}

	for index, element in ipairs(list) do
		if closure(element, index) then
			result[#result + 1] = element
		end
	end

	return result
end

function table.filter(list, closure)
	local result = {}

	for key, element in pairs(list) do
		if closure(element, key) then
			result[key] = element
		end
	end

	return result
end

function table.size(t)
	local count = 0

	for _ in pairs(t) do
		count = count + 1
	end

	return count
end

function table.getSetUnion(set1, set2)
	local result = {}

	for element, _ in pairs(set1) do
		result[element] = element
	end

	for element, _ in pairs(set2) do
		result[element] = element
	end

	return result
end

function table.getSetSubtraction(set1, set2)
	local result = {}

	for element, _ in pairs(set1) do
		if set2[element] == nil then
			result[element] = element
		end
	end

	return result
end

function table.getSetIntersection(set1, set2)
	local result = {}

	for element1, _ in pairs(set1) do
		if set2[element1] ~= nil then
			result[element1] = element1
		end
	end

	return result
end

function table.hasSetIntersection(set1, set2)
	for element1, _ in pairs(set1) do
		if set2[element1] ~= nil then
			return true
		end
	end

	return false
end

function table.hasElement(list, element)
	if list ~= nil and element ~= nil then
		for _, element1 in pairs(list) do
			if element1 == element then
				return true
			end
		end
	end

	return false
end

function table.findListElementFirstIndex(list, element, defaultReturn)
	if list ~= nil and element ~= nil then
		for key, value in ipairs(list) do
			if value == element then
				return key
			end
		end
	end

	return defaultReturn
end

function table.equals(list1, list2, orderIndependent)
	if #list1 ~= #list2 then
		return false
	end

	if orderIndependent then
		for _, element1 in ipairs(list1) do
			if not table.hasElement(list2, element1) then
				return false
			end
		end

		for _, element2 in ipairs(list2) do
			if not table.hasElement(list1, element2) then
				return false
			end
		end

		return true
	else
		for i, element1 in ipairs(list1) do
			if list2[i] ~= element1 then
				return false
			end
		end

		return true
	end
end

function table.toSet(list)
	local result = {}

	for _, element in ipairs(list) do
		result[element] = element
	end

	return result
end

function table.toList(set)
	local result = {}

	for element, _ in pairs(set) do
		result[#result + 1] = element
	end

	return result
end

function table.toHash(set)
	local result = {}

	for element, value in pairs(set) do
		result[element] = value
	end

	return result
end

function table.equalSets(set1, set2)
	for k, _ in pairs(set1) do
		if set2[k] == nil then
			return false
		end
	end

	for k, _ in pairs(set2) do
		if set1[k] == nil then
			return false
		end
	end

	return true
end

function table.isSubset(set1, set2)
	for k, _ in pairs(set1) do
		if set2[k] == nil then
			return false
		end
	end

	return true
end

function table.isRealSubset(set1, set2)
	for k, _ in pairs(set1) do
		if set2[k] == nil then
			return false
		end
	end

	for k, _ in pairs(set2) do
		if set1[k] ~= nil then
			return true
		end
	end

	return false
end

function table.push(t, v)
	t[#t + 1] = v
end

function table.pop(t)
	local v = t[#t]
	t[#t] = nil

	return v
end

function table.concatKeys(t, separator)
	local keys = {}

	for k, _ in pairs(t) do
		keys[#keys + 1] = tostring(k)
	end

	return table.concat(keys, separator)
end

function table.isArray(t)
	local i = 0

	for _ in pairs(t) do
		i = i + 1

		if t[i] == nil then
			return false
		end
	end

	return true
end
