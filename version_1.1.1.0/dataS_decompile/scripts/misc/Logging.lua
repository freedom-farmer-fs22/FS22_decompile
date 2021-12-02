Logging = {}

local function getFilename(obj)
	local objType = type(obj)

	if objType == "number" then
		return getXMLFilename(obj)
	elseif objType == "table" and obj.isa ~= nil and obj:isa(XMLFile) then
		return obj:getFilename()
	end

	return nil
end

function Logging.xmlWarning(xmlFile, warningMessage, ...)
	local filename = getFilename(xmlFile)

	print(string.format("  Warning (%s): " .. warningMessage, filename, ...))
end

function Logging.xmlError(xmlFile, errorMessage, ...)
	local filename = getFilename(xmlFile)

	print(string.format("  Error (%s): " .. errorMessage, filename, ...))
end

function Logging.xmlInfo(xmlFile, infoMessage, ...)
	local filename = getFilename(xmlFile)

	print(string.format("  Info (%s): " .. infoMessage, filename, ...))
end

function Logging.xmlDevWarning(xmlFile, warningMessage, ...)
	if g_isDevelopmentVersion then
		local filename = getFilename(xmlFile)

		print(string.format("  DevWarning (%s): " .. warningMessage, filename, ...))
	end
end

function Logging.xmlDevError(xmlFile, errorMessage, ...)
	if g_isDevelopmentVersion then
		local filename = getFilename(xmlFile)

		print(string.format("  DevError (%s): " .. errorMessage, filename, ...))
	end
end

function Logging.xmlDevInfo(xmlFile, infoMessage, ...)
	if g_showDevelopmentWarnings then
		local filename = getFilename(xmlFile)

		print(string.format("  DevInfo (%s): " .. infoMessage, filename, ...))
	end
end

function Logging.warning(warningMessage, ...)
	print(string.format("  Warning: " .. warningMessage, ...))
end

function Logging.error(errorMessage, ...)
	print(string.format("  Error: " .. errorMessage, ...))
end

function Logging.info(infoMessage, ...)
	print(string.format("  Info: " .. infoMessage, ...))
end

function Logging.fatal(fatalMessage, ...)
	print(string.format("  Fatal Error: " .. fatalMessage, ...))
	requestExit()
	error()
end

function Logging.devWarning(warningMessage, ...)
	if g_showDevelopmentWarnings then
		print(string.format("  DevWarning: " .. warningMessage, ...))
	end
end

function Logging.devError(errorMessage, ...)
	if g_showDevelopmentWarnings then
		print(string.format("  DevError: " .. errorMessage, ...))
	end
end

function Logging.devInfo(infoMessage, ...)
	if g_showDevelopmentWarnings then
		print(string.format("  DevInfo: " .. infoMessage, ...))
	end
end
