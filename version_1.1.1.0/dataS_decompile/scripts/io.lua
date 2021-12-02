io = {}
local io_mt = Class(io)

function io.open(filename, options)
	if options ~= "w" then
		print("Warning: io.open, only write mode ('w') is allowed")
	end

	local fileId = createFile(filename, FileAccess.WRITE)

	if fileId ~= 0 then
		local self = {}

		setmetatable(self, io_mt)

		self.fileId = fileId

		return self
	end
end

function io:close()
	delete(self.fileId)

	self.fileId = 0
end

function io:write(...)
	for _, v in ipairs({
		...
	}) do
		fileWrite(self.fileId, tostring(v))
	end
end

function io:flush()
end
