ClassUtil = {
	getIsValidClassName = function (className)
		if className:find("[^%w_.]") ~= nil then
			return false
		end

		return true
	end,
	getIsValidIndexName = function (indexName)
		if type(indexName) ~= "string" then
			print(string.format("Error: ClassUtil.getIsValidIndexName: string expected, got %s", type(indexName)))
			printCallstack()
		end

		if indexName == nil or indexName == "" or indexName:find("[^%w_.]") then
			return false
		end

		return true
	end,
	getClassObject = function (className)
		local parts = string.split(className, ".")
		local currentTable = _G[parts[1]]

		if type(currentTable) ~= "table" then
			return nil
		end

		for i = 2, #parts do
			currentTable = currentTable[parts[i]]

			if type(currentTable) ~= "table" then
				return nil
			end
		end

		return currentTable
	end
}

function ClassUtil.getClassObjectByObject(object)
	local className = ClassUtil.getClassNameByObject(object)

	if className == nil then
		return nil
	end

	return ClassUtil.getClassObject(className)
end

function ClassUtil.getClassName(classObject)
	for k, v in pairs(_G) do
		if v == classObject then
			return k
		end
	end
end

function ClassUtil.getClassNameByObject(object)
	if object.class ~= nil then
		local classObject = object:class()

		return ClassUtil.getClassName(classObject)
	end

	return nil
end

function ClassUtil.getClassModName(className)
	local parts = string.split(className, ".")

	if #parts > 1 then
		return parts[1]
	end

	return nil
end

function ClassUtil.getFunction(functionName)
	local parts = string.split(functionName, ".")
	local numParts = #parts
	local currentTable = _G[parts[1]]

	if numParts > 1 then
		if type(currentTable) ~= "table" then
			return nil
		end

		for i = 2, numParts do
			currentTable = currentTable[parts[i]]

			if i ~= numParts and type(currentTable) ~= "table" then
				return nil
			end
		end
	end

	if type(currentTable) ~= "function" then
		return nil
	end

	return currentTable
end
