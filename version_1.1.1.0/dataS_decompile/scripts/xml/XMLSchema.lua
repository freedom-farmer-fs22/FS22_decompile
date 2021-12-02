XMLSchema = {
	XML_SPECIALIZATION_NONE = "none",
	XML_SHARED_NONE = "none"
}
local XMLSchema_mt = Class(XMLSchema)

function XMLSchema.new(name)
	local self = setmetatable({}, XMLSchema_mt)
	self.name = name
	self.paths = {}
	self.orderedPaths = {}
	self.delayedRegistrationPaths = {}
	self.delayedRegistrationFuncs = {}
	self.delayedRegistrationSharedSchemas = {}
	self.xmlSpecializationType = XMLSchema.XML_SPECIALIZATION_NONE
	self.sharedRegistrationName = XMLSchema.XML_SHARED_NONE
	self.sharedRegistrationBase = ""
	self.subSchemas = {}
	self.hasSubSchemas = false
	self.subSchemaIdentifier = nil
	self.rootNodeName = nil

	g_xmlManager:addSchema(self)

	return self
end

function XMLSchema:register(valueTypeId, path, description, defaultValue, isRequired)
	if path ~= nil then
		if self.rootNodeName ~= nil then
			local start = path:find("%.")
			path = self.rootNodeName .. path:sub(start)
		end

		if self.paths[path] == nil then
			local pathData = {
				path = path,
				description = description,
				valueTypeId = valueTypeId
			}

			if valueTypeId == nil then
				Logging.error("Unable to register xml path '%s'. Unknown value type", path)
				printCallstack()

				return
			end

			pathData.defaultValue = defaultValue

			if isRequired == nil then
				isRequired = false
			end

			pathData.isRequired = isRequired
			pathData.specializations = {
				self.xmlSpecializationType
			}
			pathData.sharedName = self.sharedRegistrationName
			pathData.sharedBase = self.sharedRegistrationBase
			self.paths[path] = pathData

			table.insert(self.orderedPaths, pathData)
		else
			local pathData = self.paths[path]
			local newSpecializationType = true

			for i = 1, #pathData.specializations do
				if pathData.specializations[i] == self.xmlSpecializationType then
					newSpecializationType = false

					break
				end
			end

			if newSpecializationType then
				table.insert(pathData.specializations, self.xmlSpecializationType)
			end
		end

		if #self.orderedPaths == 1 then
			local rootName = path:split(".")[1]:split("#")[1]

			self:registerInheritancePaths(rootName)
		end

		self:updateSubSchemas(self.register, valueTypeId, path, description, defaultValue, isRequired)
	else
		Logging.error("Unable to register xml path. Unknown xml path '%s'", tostring(path))
		printCallstack()
	end
end

function XMLSchema:setRootNodeName(rootNodeName)
	self.rootNodeName = rootNodeName
end

function XMLSchema:replaceRootName(path)
	if self.rootNodeName ~= nil then
		local start = path:find("%.")

		return self.rootNodeName .. path:sub(start)
	end

	return path
end

function XMLSchema:setXMLSpecializationType(specializationType)
	self.xmlSpecializationType = specializationType or XMLSchema.XML_SPECIALIZATION_NONE

	self:updateSubSchemas(self.setXMLSpecializationType, specializationType)
end

function XMLSchema:setXMLSharedRegistration(sharedRegistrationName, sharedRegistrationBase)
	if sharedRegistrationBase ~= nil and self.rootNodeName ~= nil then
		local start = sharedRegistrationBase:find("%.")
		sharedRegistrationBase = self.rootNodeName .. sharedRegistrationBase:sub(start)
	end

	self.sharedRegistrationName = sharedRegistrationName or XMLSchema.XML_SHARED_NONE
	self.sharedRegistrationBase = sharedRegistrationBase or ""

	self:updateSubSchemas(self.setXMLSharedRegistration, sharedRegistrationName, sharedRegistrationBase)
end

function XMLSchema:addDelayedRegistrationPath(basePath, name)
	table.insert(self.delayedRegistrationPaths, {
		basePath = basePath,
		name = name,
		sharedName = self.sharedRegistrationName,
		sharedBase = self.sharedRegistrationBase
	})

	for _, func in ipairs(self.delayedRegistrationFuncs) do
		if func.name == name then
			func.func(self, basePath)
		end
	end

	self:updateSubSchemas(self.addDelayedRegistrationPath, basePath, name)
end

function XMLSchema:addDelayedRegistrationFunc(name, func, isSub)
	for _, path in ipairs(self.delayedRegistrationPaths) do
		if path.name == name then
			local startSharedName = self.sharedRegistrationName
			local startSharedBase = self.sharedRegistrationBase

			self:setXMLSharedRegistration(path.sharedName, path.sharedBase)
			func(self, path.basePath)
			self:setXMLSharedRegistration(startSharedName, startSharedBase)
		end
	end

	if not isSub then
		table.insert(self.delayedRegistrationFuncs, {
			name = name,
			func = func
		})
	end

	self:updateSubSchemas(self.addDelayedRegistrationFunc, name, func)

	for i = 1, #self.delayedRegistrationSharedSchemas do
		local subSchema = self.delayedRegistrationSharedSchemas[i]

		subSchema:addDelayedRegistrationFunc(name, func, true)
	end
end

function XMLSchema:shareDelayedRegistrationFuncs(parentSchema)
	self.delayedRegistrationFuncs = parentSchema.delayedRegistrationFuncs

	table.insert(parentSchema.delayedRegistrationSharedSchemas, self)
	self:updateSubSchemas(self.shareDelayedRegistrationFuncs, parentSchema)
end

function XMLSchema:addSubSchema(xmlSchema, identifier)
	if xmlSchema ~= nil and identifier ~= nil then
		table.insert(self.subSchemas, {
			identifier = identifier,
			xmlSchema = xmlSchema
		})

		self.hasSubSchemas = true
	end
end

function XMLSchema:setSubSchemaIdentifier(identifier)
	self.subSchemaIdentifier = identifier
end

function XMLSchema:updateSubSchemas(func, ...)
	if self.hasSubSchemas then
		for i = 1, #self.subSchemas do
			local subSchema = self.subSchemas[i]

			if subSchema.identifier == self.subSchemaIdentifier then
				func(subSchema.xmlSchema, ...)
			end
		end
	end
end

function XMLSchema:registerInheritancePaths(rootName)
	self:register(XMLValueType.STRING, rootName .. ".parentFile#xmlFilename", "Remove vehicle if unit empty")
	self:register(XMLValueType.STRING, rootName .. ".parentFile.attributes.remove(?)#path", "Path to remove from parent xml")
	self:register(XMLValueType.STRING, rootName .. ".parentFile.attributes.set(?)#path", "Path change in parent xml")
	self:register(XMLValueType.STRING, rootName .. ".parentFile.attributes.set(?)#value", "Target value to set in parent file")
	self:register(XMLValueType.STRING, rootName .. ".parentFile.attributes.clearList(?)#path", "List to clear but keep one item")
	self:register(XMLValueType.INT, rootName .. ".parentFile.attributes.clearList(?)#keepIndex", "Index of list to keep")
end

function XMLSchema:generateSchema()
	log(string.format("Generating Schema for '%s'. Num. paths: %d", self.name, #self.orderedPaths))

	local root = {
		children = {}
	}

	for _, data in ipairs(self.orderedPaths) do
		local path = data.path
		local parentElement = root.children
		local pathParts = path:split(".")
		local allowSubElements = true

		if pathParts[#pathParts]:find("#") ~= nil then
			local subParts = pathParts[#pathParts]:split("#")

			if #subParts == 2 then
				pathParts[#pathParts] = subParts[1]

				table.insert(pathParts, subParts[2])
			end

			allowSubElements = false
		end

		for i = 1, #pathParts do
			local oldTag = pathParts[i]
			local tag = oldTag:gsub("%(%?%)", "")
			local partAllowSubElements = allowSubElements or i < #pathParts
			local hasMultipleElements = false

			if oldTag ~= tag then
				hasMultipleElements = true
			end

			local added = false
			local addedElement = nil

			for _, otherChild in ipairs(parentElement) do
				if otherChild.tag == tag and otherChild.allowSubElements then
					addedElement = otherChild
					added = true

					break
				end
			end

			if not added then
				local sharedName = data.sharedName

				if sharedName ~= XMLSchema.XML_SHARED_NONE then
					local parts = data.sharedBase:split(".")

					for j = 1, #parts do
						if parts[j]:gsub("%(%?%)", "") == tag then
							sharedName = XMLSchema.XML_SHARED_NONE

							break
						end
					end
				end

				addedElement = {
					tag = tag,
					children = {},
					allowSubElements = partAllowSubElements,
					hasMultipleElements = hasMultipleElements,
					sharedName = sharedName
				}

				table.insert(parentElement, addedElement)
			end

			if i == #pathParts then
				addedElement.data = data
			end

			parentElement = addedElement.children
		end
	end

	local TAB = "    "
	local lastInsert = 0
	local schema = {}

	local function add(str, i, indent)
		indent = indent or ""

		if i ~= nil then
			table.insert(schema, i, indent .. str)

			lastInsert = i
		else
			table.insert(schema, indent .. str)

			lastInsert = #schema
		end

		return lastInsert
	end

	add("<?xml version=\"1.0\" encoding=\"UTF-8\" ?>")
	add("<xs:schema xmlns:xs=\"http://www.w3.org/2001/XMLSchema\">")

	local currentLine = add("</xs:schema>")
	local currentIndent = TAB

	local function formatTypeName(name)
		return "g_" .. name:lower()
	end

	local function addSimpleType(line, indent, name, isBaseType, base, pattern, content)
		line = add(string.format("<xs:simpleType name=\"%s\">", formatTypeName(name)), line, indent) + 1

		if not isBaseType then
			line = add(string.format("<xs:restriction base=\"%s\"%s>", base, pattern ~= nil and "" or "/"), line, indent .. TAB) + 1

			if pattern ~= nil then
				line = add(string.format("<xs:pattern value=\"%s\"/>", pattern), line, indent .. TAB .. TAB) + 1
				line = add("</xs:restriction>", line, indent .. TAB) + 1
			end
		else
			line = add(content, line, indent .. TAB) + 1
		end

		line = add("</xs:simpleType>", line, indent) + 1
		line = add("", line, "") + 1

		return line, indent
	end

	for _, xmlBaseValueType in ipairs(XMLValueType.BASE_TYPES) do
		currentLine, currentIndent = addSimpleType(currentLine, currentIndent, xmlBaseValueType.name, true, nil, , xmlBaseValueType.content)
	end

	for _, xmlValueType in ipairs(XMLValueType.TYPES) do
		currentLine, currentIndent = addSimpleType(currentLine, currentIndent, xmlValueType.name, false, xmlValueType.xsdBase, xmlValueType.xsdPattern)
	end

	function self.checkForSharedNames(data, isSub)
		if (data.sharedName ~= XMLSchema.XML_SHARED_NONE or isSub) and #data.children > 0 then
			for _, subData in ipairs(data.children) do
				if subData.sharedName == XMLSchema.XML_SHARED_NONE or not self.checkForSharedNames(subData, true) then
					return false
				end
			end
		end

		return true
	end

	local function createAttribute(data)
		local valueType = XMLValueType.TYPES[data.data.valueTypeId]
		local valueTypeName = formatTypeName(valueType.name)
		local additional = ""

		if data.data.isRequired then
			additional = additional .. " use=\"required\""
		end

		local defaultValue = data.data.defaultValue

		if defaultValue ~= nil and type(defaultValue) == valueType.luaType then
			local allowed = true

			if valueType.luaPattern ~= nil then
				if type(valueType.luaPattern) == "string" then
					if string.match(defaultValue, valueType.luaPattern) ~= defaultValue then
						allowed = false
					end
				elseif type(valueType.luaPattern) == "table" then
					allowed = false

					for i = 1, #valueType.luaPattern do
						if defaultValue == valueType.luaPattern[i] then
							allowed = true
						end
					end
				end
			end

			if allowed then
				additional = additional .. string.format(" default=\"%s\"", defaultValue)
			end
		end

		return string.format("<xs:attribute name=\"%s\" type=\"%s\"%s/>", data.tag, valueTypeName, additional)
	end

	function self.addElement(line, indent, name, data, isRoot, onlyChildren, additionalAttributes, printSharedAttributes)
		if not onlyChildren then
			local printShared = false

			if data.sharedName ~= XMLSchema.XML_SHARED_NONE and not printSharedAttributes then
				if self.checkForSharedNames(data) then
					printShared = true
				else
					printSharedAttributes = true
				end
			end

			if not printShared then
				if #data.children > 0 then
					local minOccurs = " minOccurs=\"0\""
					local maxOccurs = " maxOccurs=\"1\""

					if data.hasMultipleElements then
						maxOccurs = " maxOccurs=\"unbounded\""
					end

					if isRoot then
						minOccurs = ""
						maxOccurs = ""
					end

					line = add(string.format("<xs:element name=\"%s\"%s%s>", name, minOccurs, maxOccurs), line, indent) + 1
				else
					local valueType = XMLValueType.TYPES[data.data.valueTypeId]

					if valueType == nil then
						log(data.data.valueTypeId)
					end

					local valueTypeName = formatTypeName(valueType.name)
					local additional = ""

					if data.data.isRequired then
						additional = additional .. "use=\"required\""
					end

					line = add(string.format("<xs:element name=\"%s\" type=\"%s\" %s/>", name, valueTypeName, additional), line, indent) + 1
				end
			else
				local maxOccurs = " maxOccurs=\"1\""

				if data.hasMultipleElements then
					maxOccurs = " maxOccurs=\"unbounded\""
				end

				line = add(string.format("<xs:element name=\"%s\" type=\"%s\" minOccurs=\"0\"%s/>", name, data.sharedName, maxOccurs), line, indent) + 1

				return line
			end
		end

		if #data.children > 0 then
			line = add(string.format("<xs:complexType%s>", additionalAttributes or ""), line, indent .. TAB) + 1
		end

		local hasSubElements = false

		for _, subData in ipairs(data.children) do
			if subData.data == nil or subData.data.path:find("#") == nil then
				hasSubElements = true
			end
		end

		if hasSubElements then
			local indicator = "xs:all"
			local indicatorAtt = ""

			for _, subData in ipairs(data.children) do
				if subData.hasMultipleElements then
					indicator = "xs:choice"
					indicatorAtt = " maxOccurs=\"unbounded\""
				end
			end

			line = add(string.format("<%s%s>", indicator, indicatorAtt), line, indent .. TAB .. TAB) + 1

			for _, subData in ipairs(data.children) do
				if subData.data == nil then
					line = self.addElement(line, indent .. TAB .. TAB .. TAB, subData.tag, subData, nil, , , printSharedAttributes)
				elseif subData.data.path:find("#") == nil then
					local valueType = XMLValueType.TYPES[subData.data.valueTypeId]
					local valueTypeName = formatTypeName(valueType.name)
					local minOccurs = 0

					if subData.data.isRequired then
						minOccurs = 1
					end

					if #subData.children == 0 then
						line = add(string.format("<xs:element name=\"%s\" type=\"%s\" minOccurs=\"%d\"/>", subData.tag, valueTypeName, minOccurs), line, indent .. TAB .. TAB .. TAB) + 1
					else
						local baseIndent = indent .. TAB .. TAB .. TAB
						line = add(string.format("<xs:element name=\"%s\" minOccurs=\"%d\">", subData.tag, minOccurs), line, baseIndent) + 1
						line = add("<xs:complexType>", line, baseIndent .. TAB) + 1
						line = add("<xs:simpleContent>", line, baseIndent .. TAB .. TAB) + 1
						line = add(string.format("<xs:extension base=\"%s\">", valueTypeName), line, baseIndent .. TAB .. TAB .. TAB) + 1

						for _, attData in ipairs(subData.children) do
							if attData.data ~= nil and attData.data.path:find("#") ~= nil then
								line = add(createAttribute(attData), line, baseIndent .. TAB .. TAB .. TAB .. TAB) + 1
							end
						end

						line = add("</xs:extension>", line, baseIndent .. TAB .. TAB .. TAB) + 1
						line = add("</xs:simpleContent>", line, baseIndent .. TAB .. TAB) + 1
						line = add("</xs:complexType>", line, baseIndent .. TAB) + 1
						line = add(string.format("</xs:element>"), line, baseIndent) + 1
					end
				end
			end

			line = add(string.format("</%s>", indicator), line, indent .. TAB .. TAB) + 1
		end

		for _, subData in ipairs(data.children) do
			if subData.data ~= nil and subData.data.path:find("#") ~= nil then
				line = add(createAttribute(subData), line, indent .. TAB .. TAB) + 1
			end
		end

		if #data.children > 0 then
			line = add(string.format("</xs:complexType>", name), line, indent .. TAB) + 1
		end

		if #data.children > 0 and not onlyChildren then
			line = add("</xs:element>", line, indent) + 1
		end

		return line
	end

	local addedSharedNames = {}

	function self.addSharedElement(line, name, data)
		if data.sharedName ~= XMLSchema.XML_SHARED_NONE and addedSharedNames[data.sharedName] == nil then
			if self.checkForSharedNames(data) then
				line = self.addElement(line, "", name, data, false, true, string.format(" name=\"%s\"", data.sharedName), true)
				line = add("", line, "") + 1
				addedSharedNames[data.sharedName] = true
			else
				return line
			end
		end

		for _, subData in ipairs(data.children) do
			line = self.addSharedElement(line, subData.tag, subData)
		end

		return line
	end

	for _, element in ipairs(root.children) do
		currentLine = self.addSharedElement(currentLine, element.tag, element)
	end

	for _, element in ipairs(root.children) do
		currentLine = self.addElement(currentLine, currentIndent, element.tag, element, true)
	end

	local schemaPath = string.format("shared/xml/schema/%s.xsd", self.name)
	local file = io.open(schemaPath, "w")

	for _, v in pairs(schema) do
		file:write(v .. "\n")
	end

	file:close()
	log("Saved XML Schema to: ", schemaPath)
end

function XMLSchema:generateHTML()
	log(string.format("Generating HTML for '%s'. Num. paths: %d", self.name, #self.orderedPaths))

	local root = {
		children = {}
	}

	for _, data in ipairs(self.orderedPaths) do
		local path = data.path
		local parentElement = root.children
		local pathParts = path:split(".")
		local allowSubElements = true

		if pathParts[#pathParts]:find("#") ~= nil then
			local subParts = pathParts[#pathParts]:split("#")

			if #subParts == 2 then
				pathParts[#pathParts] = subParts[1]

				table.insert(pathParts, subParts[2])
			end

			allowSubElements = false
		end

		for i = 1, #pathParts do
			local oldTag = pathParts[i]
			local tag = oldTag:gsub("%(%?%)", "")
			local partAllowSubElements = allowSubElements or i < #pathParts
			local hasMultipleElements = false

			if oldTag ~= tag then
				hasMultipleElements = true
			end

			local added = false
			local addedElement = nil

			for _, otherChild in ipairs(parentElement) do
				if otherChild.tag == tag and otherChild.allowSubElements then
					addedElement = otherChild
					added = true

					break
				end
			end

			if not added then
				addedElement = {
					tag = tag,
					children = {},
					allowSubElements = partAllowSubElements,
					hasMultipleElements = hasMultipleElements
				}

				table.insert(parentElement, addedElement)
			end

			if i == #pathParts then
				addedElement.data = data
			end

			parentElement = addedElement.children
		end
	end

	local TAB = " "
	local lastInsert = 0
	local schema = {}

	local function add(str, i, indent, lineBreak)
		local prefix = ""
		local postfix = ""
		local tabLength = (indent or prefix):len()

		if tabLength > 0 then
			prefix = string.format("<span style=\"margin-left:%dem\">", tabLength * 2)
			postfix = "</span>"
		end

		if lineBreak == true then
			postfix = postfix .. "<br>"
		end

		if i ~= nil then
			table.insert(schema, i, prefix .. str .. postfix)

			lastInsert = i
		else
			table.insert(schema, prefix .. str .. postfix)

			lastInsert = #schema
		end

		return lastInsert
	end

	local OPEN = "&lt;"
	local OPEN_END = "&lt;/"
	local CLOSE = "&gt;"
	local CLOSE_END = "/&gt;"
	local TYPE_TAG = 1
	local TYPE_ATTRIBUTE = 2
	local TYPE_ATTRIBUTE_VALUE = 3
	local TYPE_VALUE = 4

	add("<!DOCTYPE html>")
	add("<head>")
	add(string.format("  <title>XML Doc: %s</title>", self.name))
	add("</head>")

	local currentLine = nil
	local currentIndent = ""

	add("<style>")
	add("body {")
	add("  font-family: \"Courier New\";")
	add("  overflow-x: scroll;")
	add("}")
	add("#tag {")
	add("  color: rgb(0, 0, 255);")
	add("}")
	add("#attribute {")
	add("  color: rgb(255, 0, 0);")
	add("}")
	add("#attribute_value {")
	add("  color: rgb(0, 0, 0);")
	add("}")
	add("#value {")
	add("  color: rgb(128, 0, 255);")
	add("}")
	add(".attribute {")
	add("  position: relative;")
	add("  display: inline-block;")
	add("  font-weight: normal;")
	add("}")
	add(".attribute .attributeInfo {")
	add("  visibility: hidden;")
	add("  width: 350px;")
	add("  top: 100%;")
	add("  left: 50%;")
	add("  margin-left: -175px;")
	add("  background-color: white;")
	add("  text-align: left;")
	add("  padding: 5px 0;")
	add("  border-radius: 6px;")
	add("  border-style: solid;")
	add("  border-color: black;")
	add("  color: black;")
	add("  position: absolute;")
	add("  z-index: 1;")
	add("}")
	add(".attribute:hover .attributeInfo {")
	add("  visibility: visible;")
	add("}")
	add(".attribute:hover{")
	add("  font-weight: bold;")
	add("}")

	currentLine = add("</style>") + 1

	local function format(str, type)
		if type == TYPE_TAG then
			str = string.format("<span id=\"tag\">%s</span>", str)
		elseif type == TYPE_ATTRIBUTE then
			str = string.format("<span id=\"attribute\">%s</span>", str)
		elseif type == TYPE_ATTRIBUTE_VALUE then
			str = string.format("<span id=\"attribute_value\">%s</span>", str)
		elseif type == TYPE_VALUE then
			str = string.format("<span id=\"value\">%s</span>", str)
		end

		return str
	end

	local function getAttributeInfo(data)
		local valueType = XMLValueType.TYPES[data.valueTypeId]
		local desc = string.format("Description: %s<br>", data.description or "missing")
		local type = string.format("Type: %s<br>", valueType.description)
		local default = ""

		if data.defaultValue ~= nil then
			default = string.format("Default: %s<br>", data.defaultValue)
		end

		local required = string.format("Required: %s<br>", data.isRequired and "yes" or "no")

		return desc .. type .. default .. required
	end

	local function buildAttribute(data, attributeType, spacing, useAllTypes, isDirect)
		if data.data ~= nil and (data.data.path:find("#") ~= nil or useAllTypes) then
			local valueType = XMLValueType.TYPES[data.data.valueTypeId]
			local valueStr = valueType.defaultStr

			if data.data.defaultValue ~= nil and type(data.data.defaultValue) == valueType.luaType then
				if valueType.luaPattern ~= nil then
					if type(valueType.luaPattern) == "string" then
						if string.match(data.data.defaultValue, valueType.luaPattern) == data.data.defaultValue then
							valueStr = data.data.defaultValue
						end
					elseif type(valueType.luaPattern) == "table" then
						for i = 1, #valueType.luaPattern do
							if data.data.defaultValue == valueType.luaPattern[i] then
								valueStr = data.data.defaultValue
							end
						end
					end
				else
					valueStr = data.data.defaultValue
				end
			end

			local attributeRaw = nil

			if isDirect then
				attributeRaw = format(valueStr, attributeType or TYPE_VALUE)
			else
				attributeRaw = string.format("%s=\"%s\"", format(data.tag, TYPE_ATTRIBUTE), format(valueStr, attributeType or TYPE_VALUE))
			end

			local attributeInfo = getAttributeInfo(data.data)
			local attribute = string.format("<div class=\"attribute\">%s<span class=\"attributeInfo\">%s</span></div>", attributeRaw, attributeInfo)

			return (spacing or " ") .. attribute
		end

		return ""
	end

	function self.addElement(line, indent, name, data, isRoot)
		if indent:len() == 1 then
			line = add("", line, indent, true) + 1
		end

		local hasOnlyAttributeChildren = true

		for _, subData in ipairs(data.children) do
			if subData.data == nil then
				hasOnlyAttributeChildren = false

				break
			elseif subData.data.path:find("#") == nil then
				hasOnlyAttributeChildren = false

				break
			end
		end

		local attributes = ""

		for _, subData in ipairs(data.children) do
			attributes = attributes .. buildAttribute(subData)
		end

		if hasOnlyAttributeChildren then
			line = add(string.format("%s%s%s", format(OPEN .. name, TYPE_TAG), format(attributes, TYPE_ATTRIBUTE), format(CLOSE_END, TYPE_TAG)), line, indent, true) + 1
		else
			line = add(string.format("%s%s%s", format(OPEN .. name, TYPE_TAG), format(attributes, TYPE_ATTRIBUTE), format(CLOSE, TYPE_TAG)), line, indent, true) + 1
		end

		for _, subData in ipairs(data.children) do
			if subData.data == nil then
				line = self.addElement(line, indent .. TAB, subData.tag, subData)
			elseif subData.data.path:find("#") == nil then
				if (indent .. TAB):len() == 1 then
					line = add("", line, indent, true) + 1
				end

				local subAttributes = ""

				for _, subSubData in ipairs(subData.children) do
					subAttributes = subAttributes .. buildAttribute(subSubData)
				end

				local attribute = buildAttribute(subData, TYPE_ATTRIBUTE_VALUE, "", true, true)
				line = add(string.format("%s%s%s%s%s%s", format(OPEN .. subData.tag, TYPE_TAG), subAttributes, format(CLOSE, TYPE_TAG), attribute, format(OPEN_END .. subData.tag, TYPE_TAG), format(CLOSE, TYPE_TAG)), line, indent .. TAB, true) + 1
			end
		end

		if not hasOnlyAttributeChildren then
			line = add(format(OPEN_END .. name .. CLOSE, TYPE_TAG), line, indent, true) + 1
		end

		return line
	end

	for _, element in ipairs(root.children) do
		currentLine = self.addElement(currentLine, currentIndent, element.tag, element, true)
	end

	local htmlPath = string.format("shared/xml/documentation/%s.html", self.name)
	local file = io.open(htmlPath, "w")

	for _, v in pairs(schema) do
		file:write(v .. "\n")
	end

	file:close()
	log("Saved XML HTML to: ", htmlPath)
end
