local exportFilename = "exportedGlobals.txt"
local maxLineLength = 180
local ignore = {
	string = true,
	math = true,
	table = true
}
local engineGlobals = {}

for global in pairs(_G) do
	if ignore[global] ~= true then
		engineGlobals[#engineGlobals + 1] = global
	end
end

table.sort(engineGlobals)
print(#engineGlobals .. " globals found")
print("saving to " .. exportFilename)

if fileExists(exportFilename) then
	deleteFile(exportFilename)
end

local file = createFile(exportFilename, FileAccess.WRITE)
local line = ""

for _, global in ipairs(engineGlobals) do
	if maxLineLength < line:len() then
		fileWrite(file, line .. "\n")

		line = ""
	end

	line = line .. string.format("\"%s\", ", global)
end

fileWrite(file, line .. "\n")
delete(file)
print("saved globals to " .. exportFilename)
print("exiting")
requestExit()
