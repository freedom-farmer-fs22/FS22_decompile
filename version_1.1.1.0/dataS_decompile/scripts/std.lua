GS_IS_EDITOR = getSelection ~= nil
GS_INPUT_HELP_MODE_AUTO = 1
GS_INPUT_HELP_MODE_KEYBOARD = 2
GS_INPUT_HELP_MODE_GAMEPAD = 3
GS_INPUT_HELP_MODE_TOUCH = 4
GS_PRIO_VERY_HIGH = 1
GS_PRIO_HIGH = 2
GS_PRIO_NORMAL = 3
GS_PRIO_LOW = 4
GS_PRIO_VERY_LOW = 5
GS_MONEY_EURO = 1
GS_MONEY_DOLLAR = 2
GS_MONEY_POUND = 3

function string.dump()
	return ""
end

function loadfile()
end

function load()
	return nil, "invalid function"
end

if setFileLogPrefixTimestamp == nil then
	print("Warning: 'setFileLogPrefixTimestamp' does not exist")

	function setFileLogPrefixTimestamp()
	end
end

local registeredConsoleCommands = {}

if addConsoleCommand ~= nil then
	local oldAddConsoleCommand = addConsoleCommand

	function addConsoleCommand(name, description, ...)
		if registeredConsoleCommands[name] == nil then
			oldAddConsoleCommand(name, description, ...)

			registeredConsoleCommands[name] = description
		else
			print(string.format("Error: Failed to register console command '%s. Command was already registered!", name))
		end
	end
end

if removeConsoleCommand ~= nil then
	local oldRemoveConsoleCommand = removeConsoleCommand

	function removeConsoleCommand(name, ...)
		oldRemoveConsoleCommand(name, ...)

		registeredConsoleCommands[name] = nil
	end
end

function consoleCommandListCommands()
	local sortedNames = {}
	local maxNameLength = 0

	for name in pairs(registeredConsoleCommands) do
		sortedNames[#sortedNames + 1] = name
		maxNameLength = math.max(maxNameLength, name:len())
	end

	table.sort(sortedNames)
	setFileLogPrefixTimestamp(false)

	for _, name in ipairs(sortedNames) do
		local paddedName = name .. string.rep(" ", maxNameLength - name:len())

		print(string.format("%s   %s", paddedName, registeredConsoleCommands[name]))
	end

	print(string.format("# Listied %d script-based console commands. Use 'help' to get all commands", #sortedNames))
	setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
end

if addConsoleCommand ~= nil then
	addConsoleCommand("gsScriptCommandsList", "Lists script-based console commands. Use 'help' to get all commands", "consoleCommandListCommands", nil)
end

function string.posixFormat(fmt, ...)
	local args = {
		...
	}
	local order = {}
	fmt = fmt:gsub("([%%]?)%%(%d+)%$", function (first, i)
		if first == "%" then
			return "%%" .. i .. "$"
		end

		table.insert(order, args[tonumber(i)])

		return "%"
	end)

	if #order == 0 then
		return string.format(fmt, ...)
	end

	return string.format(fmt, unpack(order))
end

function log(...)
	local str = ""

	for i = 1, select("#", ...) do
		str = str .. " " .. tostring(select(i, ...))
	end

	print(str)
end

local function printTableRecursively(inputTable, inputIndent, depth, maxDepth)
	inputIndent = inputIndent or "  "
	depth = depth or 0
	maxDepth = maxDepth or 3

	if depth > maxDepth then
		return
	end

	local debugString = ""

	for i, j in pairs(inputTable) do
		print(inputIndent .. tostring(i) .. " :: " .. tostring(j))

		if type(j) == "table" then
			printTableRecursively(j, inputIndent .. "    ", depth + 1, maxDepth)
		end
	end

	return debugString
end

function print_r(tbl, depth)
	if tbl == nil then
		print("table: nil")
	elseif type(tbl) ~= "table" then
		print("table: no such table")
	elseif next(tbl) == nil then
		print("table: empty")
	else
		setFileLogPrefixTimestamp(false)
		printTableRecursively(tbl, "  ", 0, depth or 5)
		setFileLogPrefixTimestamp(g_logFilePrefixTimestamp)
	end
end

function printf(formatText, ...)
	print(string.format(formatText, ...))
end

function assertWithCallstack(f, message)
	if not f then
		if message ~= nil and type(message) == "string" then
			print("Error: assertion failed: " .. message)
		else
			print("Error: assertion failed!")
		end

		printCallstack()
		error("Assertion failed")
	end
end

function registerObjectClassName(object, className)
	if g_currentMission ~= nil then
		g_currentMission.objectsToClassName[object] = className
	end
end

function unregisterObjectClassName(object)
	if g_currentMission ~= nil then
		g_currentMission.objectsToClassName[object] = nil
	end
end

function getNormalizedScreenValues(x, y)
	local values = GuiUtils.getNormalizedValues({
		x,
		y
	}, {
		g_referenceScreenWidth,
		g_referenceScreenHeight
	})

	if values[1] == nil or values[2] == nil then
		printCallstack()
	end

	local newX = values[1] * g_aspectScaleX
	local newY = values[2] * g_aspectScaleY

	return newX, newY
end

function getCorrectTextSize(size)
	if g_aspectScaleY == nil then
		return size
	else
		return size * g_aspectScaleY
	end
end

function calculateFovY(cameraNode)
	local fovY = getFovY(cameraNode)

	if GS_IS_EDITOR then
		return fovY
	end

	local maxAngle = fovY * g_fovYMax / g_fovYDefault
	local maxDelta = g_fovYMax - g_fovYDefault

	if g_fovYMax < maxAngle then
		maxDelta = g_fovYMax - fovY
	end

	local loadedFovY = g_gameSettings:getValue("fovY")

	if g_fovYDefault < loadedFovY then
		return fovY + maxDelta * (1 - (g_fovYMax - loadedFovY) / (g_fovYMax - g_fovYDefault))
	elseif loadedFovY < g_fovYDefault then
		return fovY - maxDelta * (1 - (loadedFovY - g_fovYMin) / (g_fovYDefault - g_fovYMin))
	else
		return fovY
	end
end

if GS_IS_EDITOR then
	function getUserName()
		return ""
	end

	function addConsoleCommand()
	end

	function removeConsoleCommand()
	end

	function getAppBasePath()
		return ""
	end

	function getUserProfileAppPath()
		return ""
	end

	function isHeadTrackingAvailable()
		return false
	end
end

if getHasGamepadAxisForceFeedback == nil then
	function getHasGamepadAxisForceFeedback()
		return false
	end
end

if setGamepadAxisForceFeedback == nil then
	function setGamepadAxisForceFeedback()
	end
end
