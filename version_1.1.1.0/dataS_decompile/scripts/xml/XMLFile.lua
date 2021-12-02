XMLFile = {}
local XMLFile_mt = Class(XMLFile)

function XMLFile.load(objectName, filename, schema)
	local handle = loadXMLFile(objectName, filename)

	if handle == 0 then
		return nil
	end

	return XMLFile.new(objectName, filename, handle, schema)
end

function XMLFile.loadIfExists(objectName, filename, schema)
	if filename == nil or not fileExists(filename) then
		return nil
	end

	return XMLFile.load(objectName, filename, schema)
end

function XMLFile.create(objectName, filename, rootNodeName, schema)
	local handle = createXMLFile(objectName, filename, rootNodeName)

	if handle == 0 then
		return nil
	end

	return XMLFile.new(objectName, filename, handle, schema)
end

function XMLFile.new(objectName, filename, handle, schema)
	local self = setmetatable({}, XMLFile_mt)
	self.objectName = objectName
	self.filename = filename
	self.schema = schema
	self.handle = handle

	self:initInheritance()
	g_xmlManager:addFile(self)

	return self
end

function XMLFile.wrap(handle, schema)
	local self = XMLFile.new("<unknown>", getXMLFilename(handle), handle, schema)
	self.noDeletion = true

	return self
end

function XMLFile:delete()
	if not self.noDeletion then
		delete(self.handle)
	end

	g_xmlManager:removeFile(self)
end

function XMLFile:getHandle()
	return self.handle
end

function XMLFile:getFilename()
	return self.filename
end

function XMLFile:hasProperty(property)
	return hasXMLProperty(self.handle, property)
end

function XMLFile:save()
	saveXMLFile(self.handle)
end

function XMLFile:removeProperty(path)
	removeXMLProperty(self.handle, path)
end

function XMLFile:setString(path, value)
	setXMLString(self.handle, path, value)
end

function XMLFile:setFloat(path, value)
	setXMLFloat(self.handle, path, value)
end

function XMLFile:setInt(path, value)
	setXMLInt(self.handle, path, value)
end

function XMLFile:setBool(path, value)
	setXMLBool(self.handle, path, value)
end

function XMLFile:getString(path, default)
	local v = getXMLString(self.handle, path)

	if v == nil then
		return default
	else
		return v
	end
end

function XMLFile:getFloat(path, default)
	local v = getXMLFloat(self.handle, path)

	if v == nil then
		return default
	else
		return v
	end
end

function XMLFile:getInt(path, default)
	local v = getXMLInt(self.handle, path)

	if v == nil then
		return default
	else
		return v
	end
end

function XMLFile:getBool(path, default)
	local v = getXMLBool(self.handle, path)

	if v == nil then
		return default
	else
		return v
	end
end

function XMLFile:getRootName()
	return getXMLRootName(self.handle)
end

function XMLFile:getValue(path, default, ...)
	local valueType = XMLFile.getValueType(self, path)

	if valueType ~= nil then
		if valueType.isBasicFunction then
			local value = valueType.get(self.handle, path)

			if value == nil then
				return default
			end

			return value
		else
			return valueType.get(self.handle, path, default, ...)
		end
	end
end

function XMLFile:setValue(path, ...)
	local valueType = XMLFile.getValueType(self, path)

	if valueType ~= nil then
		valueType.set(self.handle, path, ...)
	end
end

function XMLFile:iterate(path, closure)
	local prefixedPath = path .. "("
	local i = 0

	while true do
		local key = prefixedPath .. i .. ")"

		if not hasXMLProperty(self.handle, key) then
			break
		end

		if closure(i + 1, key) == false then
			break
		end

		i = i + 1
	end
end

function XMLFile:setTable(path, tbl, closure)
	local prefixedPath = path .. "("
	local i = 0

	for key, value in pairs(tbl) do
		local valuePath = prefixedPath .. i .. ")"
		local res = closure(valuePath, value, key)

		if res == false then
			break
		end

		if res ~= 0 then
			i = i + 1
		end
	end
end

function XMLFile:setSortedTable(path, tbl, closure)
	local prefixedPath = path .. "("
	local i = 0

	for key, value in ipairs(tbl) do
		local valuePath = prefixedPath .. i .. ")"
		local res = closure(valuePath, value, key)

		if res == false then
			break
		end

		if res ~= 0 then
			i = i + 1
		end
	end
end

function XMLFile:getValueType(path)
	local schema = self.schema

	if schema == nil then
		Logging.xmlError(self, "Unable to get schema for xml file.")
		printCallstack()

		return
	end

	if path == nil then
		Logging.xmlError(self, "Unable to get value from unknown path.")
		printCallstack()

		return
	end

	local normalizedPath = path:gsub("%(%d*%)", "%(?%)")
	local pathData = schema.paths[normalizedPath]

	if pathData == nil then
		normalizedPath = normalizedPath:gsub("%d+%.", "%?%."):gsub("%d+#", "%?#"):gsub("%d+$", "%?")
		pathData = schema.paths[normalizedPath]
	end

	if pathData == nil then
		Logging.xmlError(self, "Failed to validate xml path '%s' for '%s'. Path not registered.", path, schema.name)
		printCallstack()

		return
	end

	return XMLValueType.TYPES[pathData.valueTypeId]
end

function XMLFile:setVector(path, vector)
	setXMLString(self.handle, path, table.concat(vector, " "))
end

function XMLFile:getVector(path, default, maxSize)
	local vector = getXMLString(self.handle, path)

	if vector == nil then
		return default
	end

	return string.getVectorN(vector, maxSize)
end

function XMLFile:getI18NValue(path, default, customEnvironment, showWarning)
	return XMLUtil.getXMLI18NValue(self.handle, path, getXMLString, nil, default, customEnvironment, showWarning)
end

function XMLFile:initInheritance()
	local rootName = self:getRootName()
	local parentFilename = self:getString(rootName .. ".parentFile#xmlFilename")

	if parentFilename ~= nil then
		local _, baseDirectory = Utils.getModNameAndBaseDirectory(self.filename)
		parentFilename = Utils.getFilename(parentFilename, baseDirectory)
		local parentHandle = loadXMLFile(self.objectName, parentFilename)

		if parentHandle ~= 0 then
			self:iterate(rootName .. ".parentFile.attributes.remove", function (_, key)
				local attributePath = self:getString(key .. "#path")

				removeXMLProperty(parentHandle, attributePath)
			end)
			self:iterate(rootName .. ".parentFile.attributes.set", function (_, key)
				local attributePath = self:getString(key .. "#path")
				local attributeValue = self:getString(key .. "#value")

				setXMLString(parentHandle, attributePath, attributeValue)
			end)
			self:iterate(rootName .. ".parentFile.attributes.clearList", function (_, key)
				local attributePath = self:getString(key .. "#path")
				local keepIndex = self:getInt(key .. "#keepIndex")
				local numItems = 0

				while true do
					if hasXMLProperty(parentHandle, string.format(attributePath .. "(%d)", numItems)) then
						numItems = numItems + 1
					else
						break
					end
				end

				for i = numItems, 1, -1 do
					if i ~= keepIndex then
						removeXMLProperty(parentHandle, string.format(attributePath .. "(%d)", i - 1))
					end
				end
			end)
			delete(self.handle)

			self.handle = parentHandle
		else
			Logging.warning("Failed to load parent xml file '%s'", parentFilename)
		end
	end
end
