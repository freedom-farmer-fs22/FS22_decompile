openXMLFiles = {}
local oldOpen = loadXMLFile

function loadXMLFile(name, filename, ...)
	print("loadXMLFile " .. filename)

	local id = oldOpen(name, filename, ...)
	openXMLFiles[id] = {
		filename = filename
	}

	return id
end

local oldLoadFromMemory = loadXMLFileFromMemory

function loadXMLFileFromMemory(...)
	local id = oldLoadFromMemory(...)
	openXMLFiles[id] = {
		filename = "From Memory"
	}

	return id
end

local oldDelete = delete

function delete(id, ...)
	oldDelete(id, ...)

	openXMLFiles[id] = nil
end

local oldDoExit = doExit

function doExit()
	log("Open XML-Files")

	for id, data in pairs(openXMLFiles) do
		log(id, data.filename)
		log(data.trace)
	end

	oldDoExit()
end
