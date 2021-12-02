XMLValueType = {
	BASE_TYPES = {},
	TYPES = {},
	getXMLLocalization = function (xmlFile, path, default, customEnvironment, showWarning)
		local lastDot = path:findLast("%.")
		local firstPart = path:sub(0, lastDot - 1)
		local secondPart = path:sub(lastDot + 1, string.len(path))

		return XMLUtil.getXMLI18NValue(xmlFile, firstPart, getXMLString, secondPart, default, customEnvironment, showWarning)
	end,
	getXMLAngle = function (xmlFile, path, default)
		local value = getXMLFloat(xmlFile, path)

		if value ~= nil then
			return math.rad(value)
		end

		if default == nil then
			return
		end

		return math.rad(default)
	end,
	getXMLTime = function (xmlFile, path, default)
		local value = getXMLFloat(xmlFile, path)

		if value ~= nil then
			return value * 1000
		end

		if default == nil then
			return
		end

		return default * 1000
	end,
	getXMLNode = function (xmlFile, path, default, components, i3dMappings)
		if components == nil then
			Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "No components given for '%s'.", path)
			printCallstack()

			return default
		end

		local defaultStr = nil

		if type(default) == "string" then
			defaultStr = default
			default = nil
		end

		local node, root = I3DUtil.indexToObject(components, getXMLString(xmlFile, path) or defaultStr, i3dMappings)

		return node or default, root
	end,
	getXMLNodes = function (xmlFile, path, default, components, i3dMappings, packed)
		local defaultType = type(default)
		local defaultStr = nil

		if defaultType == "number" or defaultType == "nil" then
			default = {
				default
			}
		elseif defaultType == "string" then
			defaultStr = default
			default = {}
		end

		if components == nil then
			Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "No components given for '%s'.", path)
			printCallstack()

			if packed then
				return default
			else
				return unpack(default)
			end
		end

		local nodes = {}
		local nodesStr = getXMLString(xmlFile, path) or defaultStr

		if nodesStr ~= nil then
			local nodeParts = nodesStr:split(" ")

			for i = 1, #nodeParts do
				local node = I3DUtil.indexToObject(components, nodeParts[i], i3dMappings)

				if node == nil then
					Logging.xmlWarning(xmlFile, "Unknown node '%s' in '%s'!", nodeParts[i], path)
				else
					table.insert(nodes, node)
				end
			end
		end

		if #nodes == 0 then
			nodes = nil
		end

		if packed then
			return nodes or default
		else
			return unpack(nodes or default)
		end
	end,
	getVectorFromXML = function (xmlFile, path, default)
		local valueStr = getXMLString(xmlFile, path)

		if valueStr == nil then
			if type(default) == "string" then
				valueStr = default
			elseif type(default) == "table" then
				return unpack(default)
			end
		end

		return string.getVector(valueStr)
	end
}

function XMLValueType.getXMLVector2(xmlFile, path, default, packed)
	local x, y, excess = XMLValueType.getVectorFromXML(xmlFile, path, default)

	if x ~= nil then
		if y == nil or excess ~= nil then
			Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 2 for '%s'.", path)
		elseif not packed then
			return x, y
		else
			return {
				x,
				y
			}
		end
	end
end

function XMLValueType.getXMLVector3(xmlFile, path, default, packed)
	local x, y, z, excess = XMLValueType.getVectorFromXML(xmlFile, path, default)

	if x ~= nil then
		if y == nil or z == nil or excess ~= nil then
			Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 3 for '%s'.", path)
		elseif not packed then
			return x, y, z
		else
			return {
				x,
				y,
				z
			}
		end
	end
end

function XMLValueType.getXMLVector4(xmlFile, path, default, packed)
	local x, y, z, w, excess = XMLValueType.getVectorFromXML(xmlFile, path, default)

	if x ~= nil then
		if y == nil or z == nil or w == nil or excess ~= nil then
			Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 4 for '%s'.", path)
		elseif not packed then
			return x, y, z, w
		else
			return {
				x,
				y,
				z,
				w
			}
		end
	end
end

function XMLValueType.getXMLVectorN(xmlFile, path, default, packed)
	if not packed then
		return XMLValueType.getVectorFromXML(xmlFile, path, default)
	else
		return {
			XMLValueType.getVectorFromXML(xmlFile, path, default)
		}
	end
end

function XMLValueType.getXMLVector3Angle(xmlFile, path, default, packed)
	if type(default) == "table" then
		for i = 1, #default do
			default[i] = math.deg(default[i])
		end
	end

	local x, y, z = XMLValueType.getVectorFromXML(xmlFile, path, default)

	if x ~= nil then
		if y == nil or z == nil then
			Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 3 for '%s'.", path)
		elseif not packed then
			return math.rad(x), math.rad(y), math.rad(z)
		else
			return {
				math.rad(x),
				math.rad(y),
				math.rad(z)
			}
		end
	end
end

function XMLValueType.getXMLVector2Angle(xmlFile, path, default, packed)
	if type(default) == "table" then
		for i = 1, #default do
			default[i] = math.deg(default[i])
		end
	end

	local x, y = XMLValueType.getVectorFromXML(xmlFile, path, default)

	if x ~= nil then
		if y == nil then
			Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid vector 2 for '%s'.", path)
		elseif not packed then
			return math.rad(x), math.rad(y)
		else
			return {
				math.rad(x),
				math.rad(y)
			}
		end
	end
end

function XMLValueType.getXMLColor(xmlFile, path, default, packed)
	local colorStr = getXMLString(xmlFile, path)

	if colorStr == nil then
		if type(default) == "string" then
			colorStr = default
		else
			return default
		end
	end

	local color = g_brandColorManager:getBrandColorByName(colorStr)

	if color == nil then
		color = {
			string.getVector(colorStr)
		}

		if #color < 3 then
			if colorStr ~= nil then
				Logging.xmlWarning(g_xmlManager:getFileByHandle(xmlFile), "Invalid color value '%s' in '%s'.", colorStr, path)
			end

			return nil
		end

		if color[4] == nil then
			color[4] = 0
		end
	end

	if packed then
		return color
	else
		return unpack(packed)
	end
end

function XMLValueType.setXMLAngle(xmlFile, path, value)
	setXMLFloat(xmlFile, path, math.deg(value or 0))
end

function XMLValueType.setXMLTime(xmlFile, path, value)
	setXMLFloat(xmlFile, path, (value or 0) / 1000)
end

function XMLValueType.setXMLNode(xmlFile, path, value)
	if entityExists(value) then
		setXMLString(xmlFile, path, getName(value))
	end
end

function XMLValueType.setXMLNodes(xmlFile, path, ...)
	local str = ""

	for i, node in ipairs({
		...
	}) do
		if i > 1 then
			str = str + " "
		end

		if entityExists(node) then
			str = str + getName(node)
		end
	end

	setXMLString(xmlFile, path, str)
end

function XMLValueType.setVectorInXML(xmlFile, path, vector)
	setXMLString(xmlFile, path, table.concat(vector, " "))
end

function XMLValueType.setXMLVector2(xmlFile, path, ...)
	XMLValueType.setVectorInXML(xmlFile, path, {
		...
	})
end

function XMLValueType.setXMLVector3(xmlFile, path, ...)
	XMLValueType.setVectorInXML(xmlFile, path, {
		...
	})
end

function XMLValueType.setXMLVector4(xmlFile, path, ...)
	XMLValueType.setVectorInXML(xmlFile, path, {
		...
	})
end

function XMLValueType.setXMLVectorN(xmlFile, path, ...)
	XMLValueType.setVectorInXML(xmlFile, path, {
		...
	})
end

function XMLValueType.setXMLVector3Angle(xmlFile, path, ...)
	local values = {
		...
	}

	for i = 1, #values do
		values[i] = math.deg(values[i])
	end

	XMLValueType.setVectorInXML(xmlFile, path, values)
end

function XMLValueType.setXMLVector2Angle(xmlFile, path, ...)
	local values = {
		...
	}

	for i = 1, #values do
		values[i] = math.deg(values[i])
	end

	XMLValueType.setVectorInXML(xmlFile, path, values)
end

function XMLValueType.setXMLColor(xmlFile, path, ...)
	XMLValueType.setVectorInXML(xmlFile, path, {
		...
	})
end

function XMLValueType.registerBaseType(name, content)
	local xmlBaseValueType = {
		name = name,
		content = content
	}
	XMLValueType.BASE_TYPES[#XMLValueType.BASE_TYPES + 1] = xmlBaseValueType
end

XMLValueType.registerBaseType("HYPHEN", "<xs:restriction base=\"xs:string\">\n            <xs:pattern value=\"-\"/>\n        </xs:restriction>")
XMLValueType.registerBaseType("FLOAT_OR_HYPHEN", "<xs:union memberTypes=\"xs:float g_hyphen\"/>")
XMLValueType.registerBaseType("VECTOR_FLOAT", "<xs:list itemType=\"g_float_or_hyphen\"/>")

function XMLValueType.register(name, description, get, set, isBasicFunction, luaType, defaultStr, xsdBase, xsdPattern, luaPattern)
	local xmlValueType = {
		name = name,
		description = description,
		get = get,
		set = set,
		isBasicFunction = isBasicFunction,
		luaType = luaType,
		defaultStr = defaultStr,
		xsdBase = xsdBase,
		xsdPattern = xsdPattern,
		luaPattern = luaPattern
	}
	XMLValueType.TYPES[#XMLValueType.TYPES + 1] = xmlValueType
	XMLValueType[name:upper()] = #XMLValueType.TYPES
end

XMLValueType.register("STRING", "String", getXMLString, setXMLString, true, "string", "string", "xs:string")
XMLValueType.register("L10N_STRING", "String or l10n key", XMLValueType.getXMLLocalization, setXMLString, false, "string", "string", "xs:string")
XMLValueType.register("FLOAT", "Float", getXMLFloat, setXMLFloat, true, "number", "float", "xs:float")
XMLValueType.register("ANGLE", "Angle", XMLValueType.getXMLAngle, XMLValueType.setXMLAngle, false, "number", "angle", "xs:float")
XMLValueType.register("TIME", "Time in seconds", XMLValueType.getXMLTime, XMLValueType.setXMLTime, false, "number", "time", "xs:float")
XMLValueType.register("INT", "Integer", getXMLInt, setXMLInt, true, "number", "integer", "xs:integer")
XMLValueType.register("BOOL", "Boolean", getXMLBool, setXMLBool, true, "boolean", "boolean", "xs:string", "true|false", {
	true,
	false
})
XMLValueType.register("NODE_INDEX", "Index to i3d node or i3d mapping identifier", XMLValueType.getXMLNode, XMLValueType.setXMLNode, false, "string", "node", "xs:string", nil, {})
XMLValueType.register("NODE_INDICES", "List of indices to i3d nodes or i3d mapping identifiers", XMLValueType.getXMLNodes, XMLValueType.setXMLNodes, false, "string", "node", "xs:string", nil, {})
XMLValueType.register("VECTOR_2", "Multiple values (x, y)", XMLValueType.getXMLVector2, XMLValueType.setXMLVector2, false, "string", "x y", "g_vector_float", "\\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.register("VECTOR_3", "Multiple values (x, y, z)", XMLValueType.getXMLVector3, XMLValueType.setXMLVector3, false, "string", "x y z", "g_vector_float", "\\S+ \\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.register("VECTOR_4", "Multiple values (x, y, z, w)", XMLValueType.getXMLVector4, XMLValueType.setXMLVector4, false, "string", "x y z w", "g_vector_float", "\\S+ \\S+ \\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.register("VECTOR_N", "Multiple values", XMLValueType.getXMLVectorN, XMLValueType.setXMLVectorN, false, "string", "1 2 .. n", "g_vector_float")
XMLValueType.register("VECTOR_TRANS", "Translation values (x, y, z)", XMLValueType.getXMLVector3, XMLValueType.setXMLVector3, false, "string", "x y z", "g_vector_float", "\\S+ \\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.register("VECTOR_ROT", "Rotation values (x, y, z)", XMLValueType.getXMLVector3Angle, XMLValueType.setXMLVector3Angle, false, "string", "x y z", "g_vector_float", "\\S+ \\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.register("VECTOR_ROT_2", "Rotation values (x, y)", XMLValueType.getXMLVector2Angle, XMLValueType.setXMLVector2Angle, false, "string", "x y", "g_vector_float", "\\S+ \\S+", "(%-?%d*%.?%d+%s%-?%d*%.?%d+)")
XMLValueType.register("VECTOR_SCALE", "Scale values (x, y, z)", XMLValueType.getXMLVector3, XMLValueType.setXMLVector3, false, "string", "x y z", "g_vector_float", "\\S+ \\S+ \\S+", "(%d*%.?%d+%s%d*%.?%d+%s%d*%.?%d+)")
XMLValueType.register("COLOR", "Color values (r, g, b) or brand color id", XMLValueType.getXMLColor, XMLValueType.setXMLColor, false, "string", "r g b", "xs:string")
