Files = {}
local Files_mt = Class(Files)

function Files.new(path)
	local self = setmetatable({}, Files_mt)
	self.files = {}

	getFiles(path, "fileCallbackFunction", self)

	return self
end

function Files:fileCallbackFunction(filename, isDirectory)
	local file = {
		filename = filename,
		isDirectory = isDirectory
	}

	table.insert(self.files, file)
end
